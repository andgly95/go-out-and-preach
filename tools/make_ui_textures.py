#!/usr/bin/env python3
"""Draws the UI's frame and button textures (nine-slice PNGs) into ui/themes/.

The look follows Andrew's territory-map concept: slate-blue panels with a
double gold rule and corner brackets, chamfered header plates, a gold
bevelled button. Colors live in scripts/ui/ui_style.gd as well; keep the two
in step. Requires Pillow:  python3 tools/make_ui_textures.py
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parent.parent / "ui" / "themes"
BACKDROP_SRC = Path(__file__).resolve().parent.parent / "assets" / "sprites" / "territory" / "background.png"
BACKDROP_OUT = Path(__file__).resolve().parent.parent / "assets" / "sprites" / "territory" / "background_soft.png"

SLATE = (40, 54, 72)
SLATE_DARK = (25, 33, 45)
BANNER = (20, 27, 37)
GOLD = (190, 154, 88)
GOLD_LIGHT = (236, 206, 138)
GOLD_DARK = (112, 84, 40)


def rgba(color, alpha):
    return (*color[:3], alpha)


def inner_shade(img, depth, strength):
    """Darkens toward the edges, so the panel reads as a recessed plate."""
    w, h = img.size
    shade = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(shade)
    for i in range(depth):
        a = int(strength * (1 - i / depth) ** 2)
        d.rectangle([i, i, w - 1 - i, h - 1 - i], outline=a)
    dark = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    dark.putalpha(shade)
    return Image.alpha_composite(img, dark)


def brackets(d, inset, length, width, color, w, h):
    for (x, y, sx, sy) in [(inset, inset, 1, 1), (w - 1 - inset, inset, -1, 1),
                           (inset, h - 1 - inset, 1, -1), (w - 1 - inset, h - 1 - inset, -1, -1)]:
        for t in range(width):
            d.line([(x, y + sy * t), (x + sx * length, y + sy * t)], fill=color)
            d.line([(x + sx * t, y), (x + sx * t, y + sy * length)], fill=color)


def panel_frame():
    w = h = 96
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, w - 1, h - 1], radius=6, fill=rgba(SLATE, 242))
    img = inner_shade(img, 10, 70)
    # inner_shade darkened the transparent corners too; re-cut them.
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, w - 1, h - 1], radius=6, fill=255)
    img.putalpha(Image.composite(img.getchannel("A"), mask, mask))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, w - 1, h - 1], radius=6, outline=rgba(GOLD, 210), width=1)
    d.rectangle([5, 5, w - 6, h - 6], outline=rgba(GOLD, 80), width=1)
    brackets(d, 5, 13, 2, rgba(GOLD, 235), w, h)
    img.save(OUT / "panel_frame.png")


def board_frame():
    w = h = 128
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, w - 1, h - 1], outline=rgba(SLATE_DARK, 230), width=3)
    d.rectangle([3, 3, w - 4, h - 4], outline=rgba((214, 196, 158), 235), width=3)
    d.rectangle([6, 6, w - 7, h - 7], outline=rgba(GOLD_DARK, 220), width=1)
    d.rectangle([7, 7, w - 8, h - 8], outline=rgba((0, 0, 0), 60), width=2)
    brackets(d, 10, 16, 2, rgba(GOLD_LIGHT, 210), w, h)
    img.save(OUT / "board_frame.png")


def plate():
    w, h = 64, 40
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = 7
    shape = [(c, 0), (w - 1 - c, 0), (w - 1, c), (w - 1, h - 1 - c), (w - 1 - c, h - 1), (c, h - 1), (0, h - 1 - c), (0, c)]
    d.polygon(shape, fill=rgba(SLATE_DARK, 246), outline=rgba(GOLD, 225))
    c2 = 4
    inner = [(c + c2 - 1, 3), (w - c - c2, 3), (w - 4, c + c2 - 1), (w - 4, h - c - c2), (w - c - c2, h - 4),
             (c + c2 - 1, h - 4), (3, h - c - c2), (3, c + c2 - 1)]
    d.polygon(inner, outline=rgba(GOLD, 85))
    img.save(OUT / "plate.png")


def button(name, top, bottom, border, inner_alpha):
    w, h = 64, 56
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    grad = Image.new("RGBA", (w, h))
    gd = ImageDraw.Draw(grad)
    for y in range(h):
        t = y / (h - 1)
        gd.line([(0, y), (w, y)], fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,))
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, w - 1, h - 1], radius=4, fill=255)
    img.paste(grad, (0, 0), mask)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, w - 1, h - 1], radius=4, outline=rgba(border, 255), width=1)
    d.rectangle([3, 3, w - 4, h - 4], outline=rgba((255, 236, 180), inner_alpha), width=1)
    d.line([(4, 1), (w - 5, 1)], fill=(255, 240, 200, 120))
    img.save(OUT / name)


def slate_button(name, fill, border_alpha):
    w, h = 48, 40
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, w - 1, h - 1], radius=4, fill=rgba(fill, 245), outline=rgba(GOLD, border_alpha), width=1)
    d.line([(4, 1), (w - 5, 1)], fill=(255, 255, 255, 22))
    img.save(OUT / name)


def inset():
    w = h = 32
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, w - 1, h - 1], radius=4, fill=(18, 25, 35, 190), outline=(255, 255, 255, 20), width=1)
    d.line([(3, 1), (w - 4, 1)], fill=(0, 0, 0, 90))
    img.save(OUT / "inset.png")


def banner():
    w, h = 64, 96
    img = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / (h - 1)
        c = tuple(int(BANNER[i] * (1.12 - 0.2 * t)) for i in range(3))
        d.line([(0, y), (w, y)], fill=c + (252,))
    d.line([(0, h - 7), (w, h - 7)], fill=rgba(GOLD, 230))
    d.line([(0, h - 4), (w, h - 4)], fill=rgba(GOLD, 90))
    d.line([(0, 0), (w, 0)], fill=(255, 255, 255, 18))
    img.save(OUT / "banner.png")


def backdrop():
    """A soft, dimmed copy of the street for behind the map's panels."""
    src = Image.open(BACKDROP_SRC).convert("RGB")
    small = src.resize((src.width // 2, src.height // 2), Image.LANCZOS)
    small.filter(ImageFilter.GaussianBlur(5)).save(BACKDROP_OUT, optimize=True)


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    panel_frame()
    board_frame()
    plate()
    button("button_gold.png", (226, 190, 116), (158, 119, 56), GOLD_DARK, 110)
    button("button_gold_hover.png", (240, 208, 138), (178, 138, 70), GOLD_DARK, 150)
    slate_button("button_slate.png", (44, 59, 79), 150)
    slate_button("button_slate_hover.png", (58, 76, 100), 230)
    inset()
    banner()
    backdrop()
    print("wrote", sorted(p.name for p in OUT.glob("*.png")))
