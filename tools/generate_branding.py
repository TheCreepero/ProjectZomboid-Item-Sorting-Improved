#!/usr/bin/env python3
"""
Mod Branding & Thumbnail Generator
==================================
A self-contained, minimal utility to generate clean, high-contrast mod thumbnails
(poster.png) and icons (icon.png) for Project Zomboid and other modding projects.

Design Philosophy:
- Completely authentic and minimalist: solid background, single crisp border, bold typography.
- Zero AI-style tropes: no gradients, no artificial vignettes, no sci-fi HUDs or glows.
- Maximum readability at all Steam Workshop and in-game menu scales.
"""

import argparse
import os
import re
import sys
from typing import Dict, List, Optional, Tuple

try:
    from PIL import Image, ImageColor, ImageDraw, ImageFont
except ImportError:
    print("Error: Pillow is required. Install with: pip install Pillow", file=sys.stderr)
    sys.exit(1)


# Preset color themes (Solid Background + Single Border/Text Color)
THEMES: Dict[str, Dict[str, str]] = {
    "white": {
        "bg": "#000000",
        "border": "#FFFFFF",
        "text": "#FFFFFF",
    },
    "amber": {
        "bg": "#000000",
        "border": "#E5A93C",
        "text": "#FFFFFF",
        "accent": "#E5A93C",
    },
    "olive": {
        "bg": "#000000",
        "border": "#8FA382",
        "text": "#FFFFFF",
        "accent": "#8FA382",
    },
    "cyan": {
        "bg": "#000000",
        "border": "#63B3ED",
        "text": "#FFFFFF",
        "accent": "#63B3ED",
    },
}


def parse_color(c: str) -> Tuple[int, int, int]:
    """Parses hex (#FFFFFF) or standard color name into RGB tuple."""
    try:
        return ImageColor.getrgb(c)[:3]
    except Exception:
        return (255, 255, 255)


def find_system_font(size: int, bold: bool = True) -> ImageFont.ImageFont:
    """Locates the best available TrueType font across operating systems."""
    font_candidates: List[str] = [
        # Windows
        "C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf",
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
        "C:/Windows/Fonts/calibrib.ttf" if bold else "C:/Windows/Fonts/calibri.ttf",
        "C:/Windows/Fonts/impact.ttf",
        # Linux
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
        # macOS
        "/System/Library/Fonts/Helvetica.ttc",
        "/Library/Fonts/Arial Bold.ttf",
    ]
    for path in font_candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue
    return ImageFont.load_default()


def parse_mod_info(mod_info_path: str) -> Dict[str, str]:
    """Extracts key metadata from a Project Zomboid mod.info file."""
    metadata = {}
    if not os.path.isfile(mod_info_path):
        return metadata
    try:
        with open(mod_info_path, "r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                line = line.strip()
                if "=" in line and not line.startswith("#"):
                    key, val = line.split("=", 1)
                    metadata[key.strip()] = val.strip()
    except Exception as e:
        print(f"Warning: Could not parse {mod_info_path}: {e}", file=sys.stderr)
    return metadata


def split_title_lines(title: str) -> List[str]:
    """Splits title into balanced, punchy lines for poster presentation."""
    if "\n" in title:
        return [l.strip().upper() for l in title.split("\n") if l.strip()]

    words = title.strip().split()
    if len(words) <= 1:
        return [title.upper()]
    if len(words) == 2:
        return [words[0].upper(), words[1].upper()]
    if len(words) == 3:
        # e.g., "Item Sorting Improved" -> "ITEM SORTING", "IMPROVED"
        return [f"{words[0]} {words[1]}".upper(), words[2].upper()]
    mid = len(words) // 2
    return [" ".join(words[:mid]).upper(), " ".join(words[mid:]).upper()]


def generate_poster(
    title: str,
    subtitle: Optional[str] = None,
    bg_color: str = "#000000",
    border_color: str = "#FFFFFF",
    text_color: str = "#FFFFFF",
    width: int = 256,
    height: int = 256,
    border_width: int = 2,
    border_margin: int = 14,
) -> Image.Image:
    """Generates a minimal 256x256 mod poster with solid background and single border."""
    bg_rgb = parse_color(bg_color)
    border_rgb = parse_color(border_color)
    text_rgb = parse_color(text_color)

    img = Image.new("RGBA", (width, height), (*bg_rgb, 255))
    draw = ImageDraw.Draw(img)

    # 1. Single clean rectangular border
    draw.rectangle(
        [
            border_margin,
            border_margin,
            width - border_margin - 1,
            height - border_margin - 1,
        ],
        outline=border_rgb,
        width=border_width,
    )

    # 2. Text layout & sizing
    lines = split_title_lines(title)
    max_available_width = width - (border_margin * 2) - 24

    # Determine optimal font size so all lines fit comfortably
    font_size = 26
    while font_size > 14:
        fits = True
        test_font = find_system_font(font_size, bold=True)
        for line in lines:
            bbox = draw.textbbox((0, 0), line, font=test_font)
            if (bbox[2] - bbox[0]) > max_available_width:
                fits = False
                break
        if fits:
            break
        font_size -= 1

    font = find_system_font(font_size, bold=True)

    # Measure total text height
    line_metrics = []
    total_text_h = 0
    line_gap = max(4, font_size // 4)

    for line in lines:
        bbox = draw.textbbox((0, 0), line, font=font)
        lw = bbox[2] - bbox[0]
        lh = bbox[3] - bbox[1]
        line_metrics.append((line, lw, lh))
        total_text_h += lh

    total_text_h += line_gap * (len(lines) - 1)

    # Subtitle measurement (if specified)
    sub_w, sub_h, sub_font = 0, 0, None
    sub_gap = 12
    if subtitle and subtitle.strip():
        sub_font = find_system_font(max(11, font_size // 2), bold=True)
        s_bbox = draw.textbbox((0, 0), subtitle.strip().upper(), font=sub_font)
        sub_w = s_bbox[2] - s_bbox[0]
        sub_h = s_bbox[3] - s_bbox[1]
        total_text_h += sub_gap + sub_h

    # Optical vertical centering
    start_y = (height - total_text_h) // 2
    curr_y = start_y

    for line, lw, lh in line_metrics:
        x = (width - lw) // 2
        draw.text((x, curr_y), line, font=font, fill=text_rgb)
        curr_y += lh + line_gap

    if subtitle and subtitle.strip() and sub_font:
        curr_y += sub_gap - line_gap
        x = (width - sub_w) // 2
        draw.text((x, curr_y), subtitle.strip().upper(), font=sub_font, fill=text_rgb)

    return img


def generate_icon(
    text: str = "SORT",
    bg_color: str = "#000000",
    border_color: str = "#FFFFFF",
    text_color: str = "#FFFFFF",
    width: int = 64,
    height: int = 64,
    border_width: int = 1,
    border_margin: int = 4,
) -> Image.Image:
    """Generates a minimal 64x64 mod icon with solid background and single border."""
    bg_rgb = parse_color(bg_color)
    border_rgb = parse_color(border_color)
    text_rgb = parse_color(text_color)

    img = Image.new("RGBA", (width, height), (*bg_rgb, 255))
    draw = ImageDraw.Draw(img)

    # 1. Single clean square border
    draw.rectangle(
        [
            border_margin,
            border_margin,
            width - border_margin - 1,
            height - border_margin - 1,
        ],
        outline=border_rgb,
        width=border_width,
    )

    # 2. Text layout & sizing
    word = text.strip().upper()
    max_w = width - (border_margin * 2) - 8

    # Find largest font size that fits inside border
    font_size = 22
    while font_size > 10:
        test_font = find_system_font(font_size, bold=True)
        bbox = draw.textbbox((0, 0), word, font=test_font)
        if (bbox[2] - bbox[0]) <= max_w and (bbox[3] - bbox[1]) <= (height - border_margin * 2 - 8):
            break
        font_size -= 1

    font = find_system_font(font_size, bold=True)
    bbox = draw.textbbox((0, 0), word, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]

    # Center text
    x = (width - tw) // 2
    # Adjust y taking font baseline into account
    y = (height - th) // 2 - bbox[1]

    draw.text((x, y), word, font=font, fill=text_rgb)

    return img


def main():
    parser = argparse.ArgumentParser(
        description="Minimalist Mod Thumbnail & Icon Generator for Project Zomboid."
    )
    parser.add_argument("--title", type=str, help="Mod title (overrides mod.info)")
    parser.add_argument("--subtitle", type=str, default=None, help="Optional subtitle text")
    parser.add_argument(
        "--theme",
        type=str,
        choices=list(THEMES.keys()),
        default="white",
        help="Color theme preset (default: white)",
    )
    parser.add_argument("--icon-text", type=str, default="SORT", help="Text for 64x64 icon (default: SORT)")
    parser.add_argument("--border-color", type=str, help="Custom border color (#RRGGBB)")
    parser.add_argument("--text-color", type=str, help="Custom text color (#RRGGBB)")
    parser.add_argument("--bg-color", type=str, default="#000000", help="Canvas background color (default: #000000)")
    parser.add_argument("--border-width", type=int, default=2, help="Poster border stroke width in px (default: 2)")
    parser.add_argument("--icon-border-width", type=int, default=1, help="Icon border stroke width in px (default: 1)")
    parser.add_argument("--border-margin", type=int, default=14, help="Poster border margin in px (default: 14)")
    parser.add_argument("--icon-border-margin", type=int, default=4, help="Icon border margin in px (default: 4)")
    parser.add_argument("--mod-info", type=str, default="mod.info", help="Path to mod.info file")
    parser.add_argument("--poster-size", type=str, default="256x256", help="Poster dimensions (default: 256x256)")
    parser.add_argument("--icon-size", type=str, default="64x64", help="Icon dimensions (default: 64x64)")
    parser.add_argument(
        "--out-dirs",
        type=str,
        default=".",
        help="Comma-separated target output directories (default: '.')",
    )
    parser.add_argument("--poster-filename", type=str, default="poster.png", help="Poster file name")
    parser.add_argument("--icon-filename", type=str, default="icon.png", help="Icon file name")

    args = parser.parse_args()

    # Parse mod.info if available
    mod_meta = {}
    if os.path.isfile(args.mod_info):
        mod_meta = parse_mod_info(args.mod_info)

    title = args.title or mod_meta.get("name") or "Mod Title"
    theme = THEMES.get(args.theme, THEMES["white"])

    bg_color = args.bg_color or theme.get("bg", "#000000")
    border_color = args.border_color or theme.get("border", "#FFFFFF")
    text_color = args.text_color or theme.get("text", "#FFFFFF")

    # Dimensions
    pw, ph = [int(x) for x in args.poster_size.lower().split("x")]
    iw, ih = [int(x) for x in args.icon_size.lower().split("x")]

    print(f"[*] Title: '{title}'")
    print(f"[*] Icon Text: '{args.icon_text}'")
    print(f"[*] Style: Solid {bg_color} bg, {border_color} border, {text_color} text")

    poster_img = generate_poster(
        title=title,
        subtitle=args.subtitle,
        bg_color=bg_color,
        border_color=border_color,
        text_color=text_color,
        width=pw,
        height=ph,
        border_width=args.border_width,
        border_margin=args.border_margin,
    )

    icon_img = generate_icon(
        text=args.icon_text,
        bg_color=bg_color,
        border_color=border_color,
        text_color=text_color,
        width=iw,
        height=ih,
        border_width=args.icon_border_width,
        border_margin=args.icon_border_margin,
    )

    out_dirs = [d.strip() for d in args.out_dirs.split(",") if d.strip()]
    for out_dir in out_dirs:
        os.makedirs(out_dir, exist_ok=True)
        poster_path = os.path.join(out_dir, args.poster_filename)
        icon_path = os.path.join(out_dir, args.icon_filename)

        poster_img.save(poster_path, format="PNG")
        icon_img.save(icon_path, format="PNG")
        print(f"[+] Saved: {poster_path} ({pw}x{ph})")
        print(f"[+] Saved: {icon_path} ({iw}x{ih})")

    print("[OK] Branding assets successfully generated!")


if __name__ == "__main__":
    main()
