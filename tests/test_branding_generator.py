import os
import sys
import unittest
from PIL import Image

# Add tools directory to path
TOOLS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "tools"))
if TOOLS_DIR not in sys.path:
    sys.path.insert(0, TOOLS_DIR)

from generate_branding import (
    THEMES,
    find_system_font,
    generate_icon,
    generate_poster,
    parse_color,
    parse_mod_info,
    split_title_lines,
)


class TestMinimalBrandingGenerator(unittest.TestCase):
    def test_split_title_lines(self):
        l = split_title_lines("Item Sorting Improved")
        self.assertEqual(l, ["ITEM SORTING", "IMPROVED"])

        l = split_title_lines("Hydrocraft")
        self.assertEqual(l, ["HYDROCRAFT"])

    def test_parse_mod_info(self):
        mod_info_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "mod.info"))
        meta = parse_mod_info(mod_info_path)
        self.assertIn("name", meta)
        self.assertEqual(meta["name"], "Item Sorting Improved")

    def test_parse_color(self):
        self.assertEqual(parse_color("#000000"), (0, 0, 0))
        self.assertEqual(parse_color("#FFFFFF"), (255, 255, 255))
        self.assertEqual(parse_color("white"), (255, 255, 255))

    def test_generate_poster_dimensions_and_mode(self):
        for theme_name, theme_data in THEMES.items():
            img = generate_poster(
                title="Item Sorting Improved",
                bg_color=theme_data["bg"],
                border_color=theme_data["border"],
                text_color=theme_data["text"],
                width=256,
                height=256,
            )
            self.assertEqual(img.size, (256, 256))
            self.assertEqual(img.mode, "RGBA")
            # Verify background pixel (center or margin corner) is solid bg
            pixels = img.load()
            self.assertEqual(pixels[0, 0][:3], parse_color(theme_data["bg"]))

    def test_generate_icon(self):
        img = generate_icon(
            text="SORT",
            bg_color="#000000",
            border_color="#FFFFFF",
            text_color="#FFFFFF",
            width=64,
            height=64,
        )
        self.assertEqual(img.size, (64, 64))
        self.assertEqual(img.mode, "RGBA")
        pixels = img.load()
        self.assertEqual(pixels[0, 0][:3], (0, 0, 0))

    def test_font_fallback(self):
        font = find_system_font(14, bold=True)
        self.assertIsNotNone(font)


if __name__ == "__main__":
    unittest.main()
