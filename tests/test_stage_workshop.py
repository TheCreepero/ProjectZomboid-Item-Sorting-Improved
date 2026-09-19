#!/usr/bin/env python3
import os
import shutil
import sys
import tempfile
import unittest

TOOLS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "tools"))
if TOOLS_DIR not in sys.path:
    sys.path.insert(0, TOOLS_DIR)

from stage_workshop import parse_workshop_txt, stage_workshop, write_workshop_txt


class TestStageWorkshop(unittest.TestCase):
    def setUp(self):
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_parse_and_write_workshop_txt(self):
        txt_path = os.path.join(self.test_dir, "workshop.txt")
        data = {
            "version": "1",
            "id": "1234567890",
            "title": "Item Sorting Improved",
            "description": "Clean sorting",
            "tags": "Build 42;Interface",
            "visibility": "unlisted",
        }
        write_workshop_txt(txt_path, data)
        parsed = parse_workshop_txt(txt_path)
        self.assertEqual(parsed["id"], "1234567890")
        self.assertEqual(parsed["title"], "Item Sorting Improved")
        self.assertEqual(parsed["tags"], "Build 42;Interface")

    def test_stage_workshop_to_temp_dir(self):
        repo_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        target_dir = os.path.join(self.test_dir, "StagedWorkshop")

        # 1. Initial stage
        success = stage_workshop(repo_dir=repo_dir, target_dir=target_dir)
        self.assertTrue(success)

        # Check workshop root files
        self.assertTrue(os.path.isfile(os.path.join(target_dir, "preview.png")))
        self.assertTrue(os.path.isfile(os.path.join(target_dir, "workshop.txt")))
        self.assertTrue(os.path.isfile(os.path.join(target_dir, "workshop_description.txt")))

        # Check mod payload files
        mod_dir = os.path.join(target_dir, "Contents", "mods", "ItemSortingImproved")
        self.assertTrue(os.path.isfile(os.path.join(mod_dir, "mod.info")))
        self.assertTrue(os.path.isfile(os.path.join(mod_dir, "poster.png")))
        self.assertTrue(os.path.isfile(os.path.join(mod_dir, "icon.png")))
        self.assertTrue(os.path.isfile(os.path.join(mod_dir, "42", "mod.info")))
        self.assertTrue(os.path.isfile(os.path.join(mod_dir, "42", "poster.png")))
        self.assertTrue(os.path.isfile(os.path.join(mod_dir, "42", "icon.png")))
        self.assertTrue(os.path.isfile(os.path.join(mod_dir, "42", "media", "lua", "shared", "ItemSortingImproved_Core.lua")))

        # Check dev files are NOT in mod payload
        self.assertFalse(os.path.exists(os.path.join(mod_dir, "tests")))
        self.assertFalse(os.path.exists(os.path.join(mod_dir, "tools")))
        self.assertFalse(os.path.exists(os.path.join(mod_dir, ".git")))
        self.assertFalse(os.path.exists(os.path.join(mod_dir, "README.md")))

        # 2. Simulate Steam assigning an ID to workshop.txt
        workshop_txt_path = os.path.join(target_dir, "workshop.txt")
        current_data = parse_workshop_txt(workshop_txt_path)
        current_data["id"] = "9876543210"
        write_workshop_txt(workshop_txt_path, current_data)

        # Re-stage and ensure existing ID is preserved!
        success = stage_workshop(repo_dir=repo_dir, target_dir=target_dir)
        self.assertTrue(success)
        reparsed = parse_workshop_txt(workshop_txt_path)
        self.assertEqual(reparsed["id"], "9876543210")


if __name__ == "__main__":
    unittest.main()

