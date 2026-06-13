#!/usr/bin/env python3
"""
Shamba Smart — Mkulima AI Retraining Script
============================================
Run this in Google Colab (GPU runtime) to retrain MobileNetV2 on new
farmer-labelled photos from the training_submissions table, then export
the result as a .tflite file and upload it to Supabase Storage.

Workflow:
  1. Pull images from Supabase (training_submissions + leaf-photos bucket)
  2. Build class list from the images you have (merges old + new classes)
  3. Fine-tune MobileNetV2 with transfer learning
  4. Export to TFLite (float32, no quantisation — keep accuracy)
  5. Upload to Supabase Storage → mkulima-models bucket
  6. Insert a new row in model_versions table

Usage in Colab:
    !pip install supabase Pillow tensorflow numpy
    # Copy this file into Colab, fill in SUPABASE_URL / SUPABASE_SERVICE_KEY
    # (use service_role key — script needs storage + DB write access)
    # Set NEW_VERSION and DESCRIPTION, then Run All.

Author: Shamba Smart dev team
"""

import os
import io
import json
import tempfile
import pathlib
import numpy as np
from PIL import Image

# ── Colab / environment ────────────────────────────────────────────────────────
SUPABASE_URL = os.environ.get("SUPABASE_URL", "YOUR_SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.environ.get("SUPABASE_SERVICE_KEY", "YOUR_SERVICE_KEY")
NEW_VERSION = "v3"          # bump this on every release
DESCRIPTION = "Retrained on Tanzanian farmer photos from training_submissions"

# Training hyperparameters
IMG_SIZE = 224
BATCH_SIZE = 32
FINE_TUNE_EPOCHS = 10
FINE_TUNE_LR = 1e-4
TOP_LAYER_EPOCHS = 5
TOP_LAYER_LR = 1e-3
MIN_SAMPLES_PER_CLASS = 5   # skip classes with fewer images

# ── Step 1: Pull training data from Supabase ───────────────────────────────────
print("Step 1: Downloading training submissions from Supabase …")

from supabase import create_client, Client  # type: ignore
import requests

sb: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

# Fetch all submissions where farmer confirmed the label is correct
rows = (
    sb.table("training_submissions")
    .select("disease_key, photo_url, is_correct, crop_name")
    .eq("is_correct", True)
    .not_.is_("photo_url", "null")
    .execute()
    .data
)

print(f"  Found {len(rows)} confirmed submissions")

# Build dataset: {class_key: [PIL.Image, ...]}
dataset: dict[str, list[Image.Image]] = {}
errors = 0

for row in rows:
    key = row["disease_key"]
    url = row["photo_url"]
    try:
        r = requests.get(url, timeout=15)
        r.raise_for_status()
        img = Image.open(io.BytesIO(r.content)).convert("RGB")
        dataset.setdefault(key, []).append(img)
    except Exception as e:
        errors += 1
        print(f"  ⚠ Could not download {url}: {e}")

print(f"  Downloaded {sum(len(v) for v in dataset.values())} images across "
      f"{len(dataset)} classes ({errors} errors)")

# Remove classes with too few samples
dataset = {k: v for k, v in dataset.items() if len(v) >= MIN_SAMPLES_PER_CLASS}
print(f"  Classes with >= {MIN_SAMPLES_PER_CLASS} samples: {list(dataset.keys())}")

# ── Step 2: Load the existing class list and merge ────────────────────────────
print("\nStep 2: Loading existing class list …")

# If running from the repo, use the bundled JSON; otherwise fetch from Supabase.
ASSETS_DIR = pathlib.Path("../assets")
CLASS_JSON = ASSETS_DIR / "class_names_v2.json"

if CLASS_JSON.exists():
    with open(CLASS_JSON) as f:
        existing_classes: list[str] = json.load(f)
else:
    # Fetch from Supabase Storage as a fallback
    response = sb.storage.from_("mkulima-models").download("class_names_v2.json")
    existing_classes = json.loads(response.decode())

# Merge: keep all existing classes, append new ones
all_classes = list(existing_classes)
for key in dataset:
    if key not in all_classes:
        print(f"  + New class: {key}")
        all_classes.append(key)

print(f"  Total classes: {len(all_classes)}")

# ── Step 3: Build tf.data pipeline ────────────────────────────────────────────
print("\nStep 3: Building training pipeline …")

import tensorflow as tf  # type: ignore

def preprocess(img: Image.Image) -> np.ndarray:
    """Resize to 224×224, normalise to [-1, 1] (MobileNetV2 standard)."""
    img = img.resize((IMG_SIZE, IMG_SIZE), Image.BILINEAR)
    arr = np.array(img, dtype=np.float32)
    return arr / 127.5 - 1.0

images, labels = [], []
for key, imgs in dataset.items():
    label_idx = all_classes.index(key)
    for img in imgs:
        images.append(preprocess(img))
        labels.append(label_idx)

images = np.stack(images)  # (N, 224, 224, 3)
labels = np.array(labels, dtype=np.int32)

print(f"  Dataset shape: {images.shape}, labels: {labels.shape}")

# Shuffle and split 80/20
rng = np.random.default_rng(42)
indices = rng.permutation(len(images))
split = int(len(indices) * 0.8)
train_idx, val_idx = indices[:split], indices[split:]

train_ds = (
    tf.data.Dataset.from_tensor_slices((images[train_idx], labels[train_idx]))
    .shuffle(1000)
    .batch(BATCH_SIZE)
    .prefetch(tf.data.AUTOTUNE)
)
val_ds = (
    tf.data.Dataset.from_tensor_slices((images[val_idx], labels[val_idx]))
    .batch(BATCH_SIZE)
    .prefetch(tf.data.AUTOTUNE)
)

# ── Step 4: Transfer learning with MobileNetV2 ────────────────────────────────
print("\nStep 4: Building model …")

n_classes = len(all_classes)
base = tf.keras.applications.MobileNetV2(
    input_shape=(IMG_SIZE, IMG_SIZE, 3),
    include_top=False,
    weights="imagenet",
)
base.trainable = False  # freeze base for Phase 1

model = tf.keras.Sequential([
    base,
    tf.keras.layers.GlobalAveragePooling2D(),
    tf.keras.layers.Dropout(0.3),
    tf.keras.layers.Dense(n_classes),  # logits — no softmax (tflite handles it)
])

# Phase 1: train only the new top layers
print("  Phase 1: top-layer warm-up …")
model.compile(
    optimizer=tf.keras.optimizers.Adam(TOP_LAYER_LR),
    loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True),
    metrics=["accuracy"],
)
model.fit(train_ds, validation_data=val_ds, epochs=TOP_LAYER_EPOCHS)

# Phase 2: unfreeze last 30 layers and fine-tune
print("  Phase 2: fine-tuning top 30 base layers …")
base.trainable = True
for layer in base.layers[:-30]:
    layer.trainable = False

model.compile(
    optimizer=tf.keras.optimizers.Adam(FINE_TUNE_LR),
    loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True),
    metrics=["accuracy"],
)
model.fit(train_ds, validation_data=val_ds, epochs=FINE_TUNE_EPOCHS)

print("  Training complete.")

# ── Step 5: Export to TFLite ─────────────────────────────────────────────────
print("\nStep 5: Exporting to TFLite …")

converter = tf.lite.TFLiteConverter.from_keras_model(model)
# No quantisation — keep float32 to match the existing inference pipeline
# (the app normalises to [-1, 1] and reads raw logits)
tflite_bytes = converter.convert()

tflite_path = f"/tmp/mkulima_{NEW_VERSION}.tflite"
class_json_path = f"/tmp/class_names_{NEW_VERSION}.json"

with open(tflite_path, "wb") as f:
    f.write(tflite_bytes)

with open(class_json_path, "w") as f:
    json.dump(all_classes, f)

print(f"  Saved: {tflite_path} ({len(tflite_bytes) / 1e6:.1f} MB)")
print(f"  Saved: {class_json_path} ({len(all_classes)} classes)")

# Verify the exported model on a sample from the val set
print("  Verifying exported model …")
interpreter = tf.lite.Interpreter(model_path=tflite_path)
interpreter.allocate_tensors()
inp = interpreter.get_input_details()[0]
out = interpreter.get_output_details()[0]
sample = images[val_idx[0]][np.newaxis]
interpreter.set_tensor(inp["index"], sample)
interpreter.invoke()
logits = interpreter.get_tensor(out["index"])[0]
predicted_class = all_classes[np.argmax(logits)]
true_class = all_classes[labels[val_idx[0]]]
print(f"  Sample: true={true_class}, predicted={predicted_class} "
      f"({'✅' if predicted_class == true_class else '❌'})")

# ── Step 6: Upload to Supabase Storage ────────────────────────────────────────
print("\nStep 6: Uploading to Supabase Storage …")

BUCKET = "mkulima-models"

with open(tflite_path, "rb") as f:
    sb.storage.from_(BUCKET).upload(
        f"mkulima_{NEW_VERSION}.tflite",
        f.read(),
        file_options={"content-type": "application/octet-stream"},
    )

tflite_url = sb.storage.from_(BUCKET).get_public_url(
    f"mkulima_{NEW_VERSION}.tflite"
)

with open(class_json_path, "rb") as f:
    sb.storage.from_(BUCKET).upload(
        f"class_names_{NEW_VERSION}.json",
        f.read(),
        file_options={"content-type": "application/json"},
    )

print(f"  Uploaded model: {tflite_url}")

# ── Step 7: Register new version in model_versions table ─────────────────────
print("\nStep 7: Registering new version in Supabase …")

# Deactivate any currently active version
sb.table("model_versions").update({"is_active": False}).eq("is_active", True).execute()

# Insert the new version
sb.table("model_versions").insert({
    "version": NEW_VERSION,
    "download_url": tflite_url,
    "is_active": True,
    "description": DESCRIPTION,
    "class_count": n_classes,
}).execute()

print(f"\n✅ Done! Model {NEW_VERSION} is now active.")
print(f"   The app will download it automatically on next launch.")
print(f"   Update assets/class_names_v2.json in the repo if the class list changed.")
print(f"   New class list saved at: {class_json_path}")
