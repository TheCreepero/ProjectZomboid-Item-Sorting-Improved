#!/usr/bin/env python3
"""
Steam Workshop Staging Tool for Item Sorting Improved
=====================================================
Packages and stages the mod into the Project Zomboid Workshop directory:
  %USERPROFILE%/Zomboid/Workshop/ItemSortingImproved/

Ensures only production mod files are deployed, excluding tests, tools, git history,
and scratch files, while preserving assigned Workshop IDs across updates.
"""

import argparse
import os
import re
import shutil
import sys
from typing import Dict, List, Optional


DEFAULT_TARGET_DIR = os.path.join(os.path.expanduser("~"), "Zomboid", "Workshop", "ItemSortingImproved")
REPO_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


def parse_workshop_txt(path: str) -> Dict[str, str]:
    """Parses key-value pairs from a PZ workshop.txt file."""
    data = {}
    if not os.path.isfile(path):
        return data
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            line = line.strip()
            if "=" in line and not line.startswith("#"):
                k, v = line.split("=", 1)
                data[k.strip()] = v.strip()
    return data


def write_workshop_txt(path: str, data: Dict[str, str], dry_run: bool = False):
    """Writes key-value pairs into a PZ workshop.txt file."""
    lines = []
    # Standard order
    order = ["version", "id", "title", "description", "tags", "visibility"]
    for k in order:
        if k in data and data[k]:
            lines.append(f"{k}={data[k]}\n")
    for k, v in data.items():
        if k not in order and v:
            lines.append(f"{k}={v}\n")

    content = "".join(lines)
    if dry_run:
        print(f"[DRY-RUN] Would write {path}:\n{content}")
    else:
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)


def stage_workshop(
    repo_dir: str = REPO_DIR,
    target_dir: str = DEFAULT_TARGET_DIR,
    clean: bool = False,
    dry_run: bool = False,
) -> bool:
    """Stages clean mod files into the target Workshop folder."""
    print(f"[*] Staging from: {repo_dir}")
    print(f"[*] Target Workshop dir: {target_dir}")

    # Validate essential source files
    required_sources = [
        "mod.info",
        "poster.png",
        "icon.png",
        "preview.png",
        "workshop.txt",
        os.path.join("42", "mod.info"),
        os.path.join("42", "poster.png"),
        os.path.join("42", "icon.png"),
        os.path.join("42", "media", "lua", "client", "ItemSortingImproved_Client.lua"),
        os.path.join("42", "media", "lua", "shared", "ItemSortingImproved_Core.lua"),
        os.path.join("42", "media", "lua", "shared", "ItemSortingImproved_FluidCategories.lua"),
        os.path.join("42", "media", "lua", "shared", "ItemSortingImproved_Overrides.lua"),
        os.path.join("42", "media", "lua", "shared", "ItemSortingImproved_Taxonomy.lua"),
        os.path.join("42", "media", "lua", "shared", "Translate", "EN", "IG_UI.json"),
    ]

    for rel_path in required_sources:
        full = os.path.join(repo_dir, rel_path)
        if not os.path.exists(full):
            print(f"[ERROR] Missing required file: {full}", file=sys.stderr)
            return False

    # Check if target already exists and has an assigned Workshop ID
    target_workshop_txt = os.path.join(target_dir, "workshop.txt")
    existing_id = None
    if os.path.isfile(target_workshop_txt):
        existing_meta = parse_workshop_txt(target_workshop_txt)
        existing_id = existing_meta.get("id")
        if existing_id and existing_id != "0":
            print(f"[*] Preserving existing Workshop ID: {existing_id}")

    # Clean target mod directory if requested
    mod_payload_dir = os.path.join(target_dir, "Contents", "mods", "ItemSortingImproved")
    if clean and os.path.exists(mod_payload_dir) and not dry_run:
        print(f"[*] Cleaning old payload in: {mod_payload_dir}")
        shutil.rmtree(mod_payload_dir)

    # 1. Stage Workshop metadata at target root
    if not dry_run:
        os.makedirs(target_dir, exist_ok=True)

    # Copy preview.png
    src_preview = os.path.join(repo_dir, "preview.png")
    dst_preview = os.path.join(target_dir, "preview.png")
    if not dry_run:
        shutil.copy2(src_preview, dst_preview)
    print(f"[+] Staged: preview.png -> {dst_preview}")

    # Copy workshop_description.txt (if present)
    src_desc = os.path.join(repo_dir, "workshop_description.txt")
    if os.path.isfile(src_desc):
        dst_desc = os.path.join(target_dir, "workshop_description.txt")
        if not dry_run:
            shutil.copy2(src_desc, dst_desc)
        print(f"[+] Staged: workshop_description.txt -> {dst_desc}")

    # Prepare and write workshop.txt
    repo_workshop_txt = os.path.join(repo_dir, "workshop.txt")
    workshop_data = parse_workshop_txt(repo_workshop_txt)
    if existing_id and existing_id != "0":
        workshop_data["id"] = existing_id
    write_workshop_txt(target_workshop_txt, workshop_data, dry_run=dry_run)
    print(f"[+] Staged: workshop.txt -> {target_workshop_txt}")

    # 2. Stage Mod Payload into Contents/mods/ItemSortingImproved
    files_to_copy = [
        # Root mod metadata
        ("mod.info", os.path.join(mod_payload_dir, "mod.info")),
        ("poster.png", os.path.join(mod_payload_dir, "poster.png")),
        ("icon.png", os.path.join(mod_payload_dir, "icon.png")),
        # 42 overlay metadata
        (os.path.join("42", "mod.info"), os.path.join(mod_payload_dir, "42", "mod.info")),
        (os.path.join("42", "poster.png"), os.path.join(mod_payload_dir, "42", "poster.png")),
        (os.path.join("42", "icon.png"), os.path.join(mod_payload_dir, "42", "icon.png")),
    ]

    for rel_src, dst_path in files_to_copy:
        src_path = os.path.join(repo_dir, rel_src)
        if not dry_run:
            os.makedirs(os.path.dirname(dst_path), exist_ok=True)
            shutil.copy2(src_path, dst_path)
        print(f"[+] Staged: {rel_src} -> {dst_path}")

    # Copy entire 42/media directory tree cleanly (ignoring caches)
    src_media = os.path.join(repo_dir, "42", "media")
    dst_media = os.path.join(mod_payload_dir, "42", "media")

    def ignore_patterns(folder, contents):
        return [c for c in contents if c.endswith(".pyc") or c == "__pycache__" or c.startswith(".")]

    if not dry_run:
        if os.path.exists(dst_media):
            shutil.rmtree(dst_media)
        shutil.copytree(src_media, dst_media, ignore=ignore_patterns)
    print(f"[+] Staged directory: 42/media -> {dst_media}")

    print("\n[OK] Staging completed successfully!")
    print(f"[OK] You can now open Project Zomboid -> Workshop -> 'Item Sorting Improved' to publish or update.")
    return True


def main():
    parser = argparse.ArgumentParser(
        description="Stage Item Sorting Improved mod into Project Zomboid Workshop directory."
    )
    parser.add_argument(
        "--target-dir",
        type=str,
        default=DEFAULT_TARGET_DIR,
        help=f"Target workshop directory (default: {DEFAULT_TARGET_DIR})",
    )
    parser.add_argument(
        "--repo-dir",
        type=str,
        default=REPO_DIR,
        help=f"Source repository directory (default: {REPO_DIR})",
    )
    parser.add_argument(
        "--clean",
        action="store_true",
        help="Clean target payload directory before copying",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Simulate staging without copying files",
    )

    args = parser.parse_args()
    success = stage_workshop(
        repo_dir=args.repo_dir,
        target_dir=args.target_dir,
        clean=args.clean,
        dry_run=args.dry_run,
    )
    if not success:
        sys.exit(1)


if __name__ == "__main__":
    main()

