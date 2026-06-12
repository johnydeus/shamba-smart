"""Step 2 — Auto-detect green icon boundaries and crop to 1024×1024."""
from PIL import Image
import numpy as np

SRC = 'assets/icon/app_icon_enhanced.png'
DST = 'assets/icon/app_icon_final.png'

img = Image.open(SRC).convert('RGBA')
arr = np.array(img)
w, h = img.size

# White/near-white threshold — background is ~(240-255, 240-255, 240-255)
# A pixel is "content" if it is NOT near-white and is sufficiently opaque
WHITE_THRESH = 230
ALPHA_THRESH = 30

r, g, b, a = arr[:,:,0], arr[:,:,1], arr[:,:,2], arr[:,:,3]
content_mask = ~(
    (r > WHITE_THRESH) & (g > WHITE_THRESH) & (b > WHITE_THRESH)
) & (a > ALPHA_THRESH)

# Only scan the top 80 % of the image height to exclude the "SHAMBA SMART"
# wordmark text that sits below the icon
search_h = int(h * 0.80)
content_mask[search_h:, :] = False

# Find tight bounding box of content pixels
rows = np.any(content_mask, axis=1)
cols = np.any(content_mask, axis=0)
top    = int(np.argmax(rows))
bottom = int(len(rows) - np.argmax(rows[::-1]) - 1)
left   = int(np.argmax(cols))
right  = int(len(cols) - np.argmax(cols[::-1]) - 1)

# Add a small padding (1.5 % of image size) so rounded corners aren't clipped
pad = int(min(w, h) * 0.015)
top    = max(0, top    - pad)
left   = max(0, left   - pad)
bottom = min(h, bottom + pad)
right  = min(w, right  + pad)

print(f"Detected icon region: left={left} top={top} right={right} bottom={bottom}")
print(f"Crop size: {right-left} × {bottom-top}")

cropped = img.crop((left, top, right, bottom))
cw, ch  = cropped.size

# Make perfectly square (centre on transparent canvas)
size   = max(cw, ch)
square = Image.new('RGBA', (size, size), (0, 0, 0, 0))
square.paste(cropped, ((size - cw) // 2, (size - ch) // 2))

# Resize to 1024×1024 for flutter_launcher_icons
final = square.resize((1024, 1024), Image.LANCZOS)
final.save(DST)
print(f"Final 1024×1024 icon saved → {DST}")
