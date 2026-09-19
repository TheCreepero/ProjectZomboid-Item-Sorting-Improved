#!/usr/bin/env python3
"""
Unit test to verify that README.md does not contain any emojis.
Protects documentation style integrity across updates and releases.
"""

import os
import sys
import unittest
import unicodedata

README_PATH = os.path.join(os.path.dirname(__file__), "..", "README.md")

def is_emoji_or_symbol(char: str) -> bool:
    """
    Checks if a character is an emoji or emoji pictograph.
    Permits standard Markdown typography and box drawing characters (e.g. tree diagrams).
    """
    cp = ord(char)
    # Box drawings (e.g. tree diagrams: 0x2500 - 0x257F) are allowed
    if 0x2500 <= cp <= 0x257F:
        return False
    # Standard ASCII and Latin-1 supplement typography are allowed
    if cp < 0x2000:
        return False
    # General punctuation like em dash (0x2014) is allowed
    if 0x2000 <= cp <= 0x206F:
        return False

    # Emoji, Pictographs, Emoticons, Dingbats, and Variation Selectors
    if (
        (0x1F000 <= cp <= 0x1FAFF)  # Supplemental symbols, pictographs, transport, emoticons
        or (0x2600 <= cp <= 0x27BF) # Miscellaneous symbols & dingbats
        or (0xFE00 <= cp <= 0xFE0F) # Variation selectors
        or (0x1F900 <= cp <= 0x1F9FF)
        or (0x1F600 <= cp <= 0x1F64F)
        or (0x1F300 <= cp <= 0x1F5FF)
        or (0x1F680 <= cp <= 0x1F6FF)
    ):
        return True

    return False

def find_readme_emojis(readme_path: str = README_PATH):
    if not os.path.exists(readme_path):
        raise FileNotFoundError(f"README file not found at: {readme_path}")

    with open(readme_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    detected = []
    for line_idx, line in enumerate(lines, start=1):
        for col_idx, char in enumerate(line, start=1):
            if is_emoji_or_symbol(char):
                name = unicodedata.name(char, "UNKNOWN")
                detected.append({
                    "line": line_idx,
                    "column": col_idx,
                    "char": char,
                    "codepoint": f"U+{ord(char):04X}",
                    "name": name,
                    "context": line.strip()
                })
    return detected

class TestReadmeEmojis(unittest.TestCase):
    def test_readme_contains_no_emojis(self):
        detected = find_readme_emojis()
        if detected:
            msg_lines = [f"Found {len(detected)} emoji(s) in README.md:"]
            for d in detected:
                msg_lines.append(
                    f"  Line {d['line']}, Col {d['column']}: {d['codepoint']} ({d['name']}) in '{d['context']}'"
                )
            self.fail("\n".join(msg_lines))

if __name__ == "__main__":
    unittest.main()
