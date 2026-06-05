"""Generate the CricLive Play Store feature graphic (1024x500).
Composites the real neon app icon onto a dark premium gradient with the
CricLive wordmark + tagline. Run: python store/make_feature_graphic.py
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os

W, H = 1024, 500
HERE = os.path.dirname(os.path.abspath(__file__))

# ---- background: diagonal dark gradient (navy -> near black), matching the icon ----
top = (10, 22, 40)      # deep navy
bot = (4, 8, 16)        # near black
bg = Image.new("RGB", (W, H))
px = bg.load()
for y in range(H):
    for x in range(W):
        t = (x / W * 0.45) + (y / H * 0.55)
        r = int(top[0] + (bot[0] - top[0]) * t)
        g = int(top[1] + (bot[1] - top[1]) * t)
        b = int(top[2] + (bot[2] - top[2]) * t)
        px[x, y] = (r, g, b)
img = bg.convert("RGBA")

# ---- soft neon glow blobs for depth ----
glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
gd.ellipse([640, 60, 1060, 470], fill=(35, 120, 200, 70))   # cyan glow behind icon
gd.ellipse([720, 180, 1000, 460], fill=(230, 110, 30, 45))  # warm orange glow
glow = glow.filter(ImageFilter.GaussianBlur(90))
img = Image.alpha_composite(img, glow)

# ---- place the neon icon on the right ----
icon = Image.open(os.path.join(HERE, "icon_512.png")).convert("RGBA")
isz = 300
icon = icon.resize((isz, isz), Image.LANCZOS)
# glow halo around the icon
halo = Image.new("RGBA", (W, H), (0, 0, 0, 0))
hd = ImageDraw.Draw(halo)
ix, iy = 690, (H - isz) // 2
hd.rounded_rectangle([ix - 18, iy - 18, ix + isz + 18, iy + isz + 18],
                     radius=70, fill=(60, 160, 240, 90))
halo = halo.filter(ImageFilter.GaussianBlur(40))
img = Image.alpha_composite(img, halo)
img.alpha_composite(icon, (ix, iy))

draw = ImageDraw.Draw(img)
f_black = lambda s: ImageFont.truetype("C:/Windows/Fonts/seguibl.ttf", s)   # Segoe UI Black
f_semi = lambda s: ImageFont.truetype("C:/Windows/Fonts/seguisb.ttf", s)    # Segoe UI Semibold

# ---- wordmark: "Cric" white + "Live" cyan ----
wm_size = 118
fw = f_black(wm_size)
x = 70
y = 150
cyan = (54, 209, 255)
draw.text((x, y), "Cric", font=fw, fill=(245, 248, 255))
w_cric = draw.textlength("Cric", font=fw)
draw.text((x + w_cric, y), "Live", font=fw, fill=cyan)

# ---- tagline with neon bullet separators ----
tag_size = 38
ft = f_semi(tag_size)
ty = y + wm_size + 18
parts = ["Score", "Share Live", "Tournaments"]
tx = x + 4
sep = "  •  "
for i, part in enumerate(parts):
    draw.text((tx, ty), part, font=ft, fill=(214, 224, 238))
    tx += draw.textlength(part, font=ft)
    if i < len(parts) - 1:
        draw.text((tx, ty), sep, font=ft, fill=(255, 150, 40))  # orange bullets
        tx += draw.textlength(sep, font=ft)

out = os.path.join(HERE, "feature_graphic_1024x500.png")
img.convert("RGB").save(out, "PNG")
print("Saved", out)
