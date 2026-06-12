"""Step 1 — Enhance contrast/saturation/sharpness of source icon."""
from PIL import Image, ImageEnhance

SRC = 'assets/icon/app_icon.png/shamba smart-image_i8rat9i8rat9i8ra.png'
DST = 'assets/icon/app_icon_enhanced.png'

img = Image.open(SRC)
img = ImageEnhance.Contrast(img).enhance(1.15)
img = ImageEnhance.Color(img).enhance(1.10)
img = ImageEnhance.Sharpness(img).enhance(1.1)
img.save(DST)
print(f"Enhanced icon saved → {DST}  {img.size}")
