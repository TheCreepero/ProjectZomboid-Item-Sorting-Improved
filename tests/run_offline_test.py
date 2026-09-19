#!/usr/bin/env python3
"""
Item Sorting Improved - Offline Verification Test Suite
Tests the categorization logic against all 5,000+ vanilla items from Project Zomboid Build 42.
"""

import glob
import json
import os
import re
import sys
from collections import Counter

SCRIPTS_DIR = r"H:\SteamLibrary\steamapps\common\ProjectZomboid\media\scripts\generated\items"
TRANSLATE_FILE = os.path.join(os.path.dirname(__file__), "..", "42", "media", "lua", "shared", "Translate", "EN", "IG_UI.json")

def load_valid_categories():
    with open(TRANSLATE_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)
    categories = {k.replace("IGUI_ItemCat_", "") for k in data.keys()}
    return categories

def parse_items():
    items = []
    for f in glob.glob(os.path.join(SCRIPTS_DIR, "*.txt")):
        with open(f, "r", encoding="utf-8", errors="ignore") as fp:
            content = fp.read()
        blocks = re.findall(r"item\s+([A-Za-z0-9_]+)\s*\{([^}]+)\}", content)
        for name, body in blocks:
            props = {}
            for line in body.split("\n"):
                line = line.strip()
                if "=" in line:
                    k, v = line.split("=", 1)
                    props[k.strip()] = v.strip().rstrip(",")
            props["name"] = name
            props["fullname"] = "Base." + name
            props["file"] = os.path.basename(f)
            items.append(props)
    return items

def classify_item(props):
    name = props.get("name", "")
    name_lower = name.lower()
    itype = props.get("ItemType", "").replace("base:", "").capitalize()
    disp_cat = props.get("DisplayCategory", "")
    tags = [t.strip().lower() for t in props.get("Tags", "").split(";") if t.strip()]
    body_loc = props.get("BodyLocation", "").replace("base:", "").lower()
    can_equip = props.get("CanBeEquipped", "").lower()

    # Explicit overrides test
    overrides = {
        "Base.Wallet": "ClothAcc",
        "Base.Wallet2": "ClothAcc",
        "Base.CreditCard": "Collect",
        "Base.Money": "Collect",
        "Base.Cards": "MediaG",
        "Base.Dice": "MediaG",
        "Base.Spiffo": "Collect",
    }
    if props.get("fullname") in overrides:
        return overrides[props.get("fullname")]

    # 1. Food
    if itype == "Food" or "food" in props.get("file", ""):
        if props.get("Alcoholic", "").lower() == "true" or "alcohol" in tags:
            return "FoodA"
        if props.get("CanStoreWater", "").lower() == "true" or disp_cat == "Water" or "drink" in tags or props.get("PourType") or props.get("EatType") == "drink":
            return "FoodB"
        days_rotten = float(props.get("DaysTotallyRotten", 0)) if props.get("DaysTotallyRotten") else 0
        cant_freeze = props.get("CantBeFrozen", "").lower() == "true"
        canned = props.get("CannedFood", "").lower() == "true"
        if canned or cant_freeze or days_rotten <= 0 or days_rotten >= 1000000:
            return "FoodN"
        return "FoodP"

    # 2. Literature
    if itype == "Literature" or "literature" in props.get("file", ""):
        if props.get("SkillTrained"):
            return "LitS"
        if props.get("TeachedRecipes"):
            return "LitR"
        if itype == "Map" or disp_cat == "Cartography" or "map" in name_lower:
            return "LitC"
        if props.get("CanWrite", "").lower() == "true" or "write" in tags or any(w in name_lower for w in ["pencil", "pen", "notebook", "journal", "crayon", "eraser", "sheetpaper"]):
            return "LitW"
        return "LitE"

    if itype == "Map" or "map" in props.get("file", ""):
        return "LitC"

    # 3. Weapons & Ammo
    if itype == "Weapon" or "weapon" in props.get("file", ""):
        if disp_cat in ["Explosives", "Devices"] or any(t in tags for t in ["explosive", "bomb", "trap"]) or any(w in name_lower for w in ["pipebomb", "molotov", "grenade"]):
            return "WepBomb"
        if any(t in tags for t in ["bow", "crossbow"]) or "bow" in name_lower or "crossbow" in name_lower:
            return "WepBow"
        if props.get("Ranged", "").lower() == "true" or props.get("IsAimedFirearm", "").lower() == "true" or props.get("GunType"):
            return "WepFire"
        if disp_cat == "Fishing" or disp_cat == "FishingWeapon" or any(t in tags for t in ["fishing", "lure", "rod"]) or "fishingrod" in name_lower:
            return "SurFish"
        if disp_cat == "Gardening" or disp_cat == "GardeningWeapon" or any(t in tags for t in ["farming", "seed", "gardening"]):
            return "SurFarm"
        if disp_cat in ["Tool", "ToolWeapon"] or any(t in tags for t in ["hammer", "saw", "screwdriver", "wrench", "crowbar", "welding", "pipewrench", "sledgehammer", "shovel"]):
            return "Tool"
        return "WepMelee"

    if itype == "Weaponpart" or "weaponpart" in props.get("file", "") or disp_cat == "WeaponPart":
        return "WepPart"

    if disp_cat == "Ammo" or "ammo" in tags or "bullet" in tags or any(w in name_lower for w in ["bullets", "shells", "rounds", "cartridge", "ammo", "arrow", "bolt"]):
        if any(w in name_lower for w in ["magazine", "clip"]):
            return "WepAmmoMag"
        return "WepAmmo"

    if any(w in name_lower for w in ["magazine", "clip", "drum"]):
        return "WepAmmoMag"

    # 4. Clothing & Wearables
    if itype in ["Clothing", "Alarmclockclothing"] or "clothing" in props.get("file", "") or body_loc:
        if body_loc in ["hat", "mask", "eyes", "ears", "nose", "fullhat", "maskeyes", "maskfull", "eartop", "lefteye", "righteye"]:
            return "ClothHead"
        if body_loc in ["hands", "handsleft", "handsright", "rightarm", "leftarm", "forearm_right", "forearm_left"]:
            return "ClothArm"
        if body_loc in ["shoes", "socks", "calf_right", "calf_left", "gaiter_left", "gaiter_right"]:
            return "ClothFeet"
        if body_loc in ["pants", "shortpants", "shortsshort", "legs1", "skirt", "longskirt", "thigh_right", "thigh_left", "pantsextra", "pants_skinny"]:
            return "ClothLeg"
        if body_loc in ["underwear", "underwearbottom", "underweartop", "underwearextra1", "underwearextra2"]:
            return "ClothUnder"
        if body_loc in ["necklace", "necklace_long", "bellybutton", "right_middlefinger", "left_middlefinger", "right_ringfinger", "left_ringfinger", "rightwrist", "leftwrist"]:
            return "ClothJew"
        if body_loc in ["back", "satchel"] or "backpack" in tags or ("bag" in name_lower and "back" in can_equip):
            return "ClothBack"
        if body_loc in ["belt", "holster", "ankleholster", "beltextra", "scarf", "tie", "tail"]:
            return "ClothAcc"
        return "ClothBody"

    # 5. Containers
    if itype == "Container" or "container" in props.get("file", "") or any(w in name_lower for w in ["gascan", "petrolcan"]):
        if "back" in can_equip or any(w in name_lower for w in ["backpack", "dufflebag", "hikingbag", "alice", "schoolbag"]):
            return "ClothBack"
        if any(w in can_equip for w in ["belt", "fannypack"]) or any(w in name_lower for w in ["fannypack", "satchel", "purse", "pouch"]):
            return "ClothBag"
        if props.get("CanStoreWater", "").lower() == "true" or disp_cat in ["WaterContainer", "Water"] or any(w in name_lower for w in ["bottle", "canteen", "flask", "bucket", "pot", "kettle", "gascan", "petrolcan"]):
            return "ContL"
        return "Cont"

    # 6. Medical
    if disp_cat in ["FirstAid", "FirstAidWeapon", "Bandage"] or any(t in tags for t in ["medical", "firstaid", "bandage", "pill", "disinfectant"]) or props.get("CanBandage", "").lower() == "true":
        return "Med"

    # 7. Cleaning
    if any(t in tags for t in ["bleach", "soap", "cleaning", "towel", "clean"]) or any(w in name_lower for w in ["bleach", "soap", "mop", "dishcloth", "bathtowel", "sponge", "broom"]):
        return "Clean"

    # 8. Appearance & Cosmetics
    if disp_cat == "Appearance" or props.get("MakeUpType") or any(w in name_lower for w in ["makeup", "lipstick", "hairdye", "hairgel", "eyeshadow", "perfume", "cologne"]):
        return "Appear"

    # 9. Tools
    if disp_cat == "Tool" or any(t in tags for t in ["tool", "hammer", "saw", "screwdriver", "wrench", "pipewrench", "sledgehammer", "shovel", "blowtorch", "weldingmask", "crowbar", "scissors", "trowel"]):
        return "Tool"

    # 10. Building & Construction
    if disp_cat == "Paint" or "paint" in tags or "paint" in name_lower:
        return "BuildP"
    if any(w in name_lower for w in ["log", "brick", "gravel", "concrete", "plaster", "hinge", "doorknob", "anvil", "sandbag", "cement"]):
        return "Build"
    if disp_cat in ["Material", "RecipeResource"] or any(t in tags for t in ["carpentry", "metalworking", "masonry", "tailoring", "crafting"]):
        return "Craft"

    # 11. Electronics & Communications
    if itype in ["Radio", "Alarmclock"] or disp_cat in ["Electronics", "Communications"] or any(t in tags for t in ["electronics", "radio", "battery", "lightsource", "flashlight"]):
        return "Elec"

    # 12. Survival
    if disp_cat in ["Fishing", "FishingWeapon"] or any(t in tags for t in ["fishing", "lure", "rod"]):
        return "SurFish"
    if disp_cat in ["Gardening", "GardeningWeapon"] or any(t in tags for t in ["farming", "seed", "gardening"]):
        return "SurFarm"
    if disp_cat == "Trapping" or any(t in tags for t in ["trapping", "trap"]):
        return "SurTrap"
    if disp_cat == "Camping" or any(t in tags for t in ["camping", "tent"]):
        return "SurCamp"

    # 13. Mechanics
    if disp_cat in ["VehicleMaintenance", "VehicleMaintenanceWeapon"] or any(t in tags for t in ["mechanic", "vehiclepart"]) or any(w in name_lower for w in ["tire", "muffler", "carburetor", "carengine", "brakes", "suspension", "gaspump"]):
        return "Mech"

    # 14. Key
    if itype in ["Key", "Key_ring"] or "key" in props.get("file", "") or "key" in name_lower or "padlock" in name_lower:
        return "Key"

    # 15. Moveables / Furniture
    if itype == "Moveable" or disp_cat == "Furniture" or any(w in name_lower for w in ["chair", "table", "bed", "shelf", "sofa", "couch", "cabinet"]):
        return "Furn"

    # 16. Media
    if any(w in name_lower for w in ["cassette", "vinyl", "cdrom", "compactdisc"]):
        return "MediaA"
    if any(w in name_lower for w in ["vhs", "movie", "film", "videotape"]):
        return "MediaV"
    if any(w in name_lower for w in ["boardgame", "chess", "checker", "cards", "dice", "yoyo"]):
        return "MediaG"

    # 17. Fuel
    if any(w in name_lower for w in ["petrol", "gasoline", "gascan", "propanetank", "charcoal", "firewood", "kindling"]):
        return "Fuel"

    # 18. Drugs & Tobacco
    if any(w in name_lower for w in ["cigarette", "cigar", "tobacco", "joint", "rollingpaper"]):
        return "Drugs"

    # 19. Collectables
    if any(w in name_lower for w in ["money", "creditcard", "plush", "spiffo", "doll", "toy"]):
        return "Collect"

    # 20. Cooking implements & ingredients
    if disp_cat == "Cooking" or any(w in name_lower for w in ["pan", "pot", "roasting", "baking", "skillet", "bowl", "spoon", "fork", "kettle"]):
        return "Cook"
    if any(w in name_lower for w in ["flour", "sugar", "salt", "pepper", "oil", "vinegar", "yeast"]):
        return "CookIng"

    # Fallback to Junk / Misc
    if disp_cat == "Junk" or any(w in name_lower for w in ["empty", "trash", "scrap", "debris"]):
        return "Junk"
    return "Misc"

def main():
    print("==================================================")
    print("Item Sorting Improved - Automated Offline Tests")
    print("==================================================")

    valid_categories = load_valid_categories()
    print(f"[OK] Loaded {len(valid_categories)} valid categories from IG_UI.json")

    items = parse_items()
    print(f"[OK] Parsed {len(items)} items from vanilla PZ scripts")

    counts = Counter()
    invalid_categories = []

    # Benchmark assertions
    benchmarks = {
        "Base.Axe": "Tool",
        "Base.Pistol": "WepFire",
        "Base.Apple": "FoodP",
        "Base.CannedBolognese": "FoodN",
        "Base.BookCarpentry1": "LitS",
        "Base.Bandage": "Med",
        "Base.Bleach": "Clean",
        "Base.Hammer": "Tool",
        "Base.Nails": "Craft",
        "Base.Log": "Build",
        "Base.PaintRed": "BuildP",
        "Base.PetrolCan": "ContL",
        "Base.Hat_BaseballCap": "ClothHead",
        "Base.Tshirt_White": "ClothBody",
        "Base.Jeans": "ClothLeg",
        "Base.Shoes_Sneakers": "ClothFeet",
        "Base.Gloves_LeatherGloves": "ClothArm",
        "Base.Bag_Schoolbag": "ClothBack",
        "Base.Ring_Gold": "ClothJew",
        "Base.Underwear_Boxers": "ClothUnder",
        "Base.FishingRod": "SurFish",
        "Base.TomatoSeeds": "SurFarm",
        "Base.TrapCage": "SurTrap",
        "Base.CarBattery1": "Mech",
        "Base.RadioBlack": "Elec",
        "Base.Key1": "Key",
        "Base.Money": "Collect",
        "Base.Cigarettes": "Drugs",
    }

    benchmark_failures = []

    for it in items:
        cat = classify_item(it)
        counts[cat] += 1
        if cat not in valid_categories:
            invalid_categories.append((it["fullname"], cat))

        fn = it["fullname"]
        if fn in benchmarks:
            expected = benchmarks[fn]
            if cat != expected:
                benchmark_failures.append((fn, expected, cat))

    # Assertions
    assert len(invalid_categories) == 0, f"Found {len(invalid_categories)} items with invalid categories: {invalid_categories[:5]}"
    print(f"[PASS] 100% of {len(items)} items received valid categories registered in translations.")

    if benchmark_failures:
        print(f"[FAIL] Benchmark mismatches ({len(benchmark_failures)}):")
        for fn, exp, got in benchmark_failures:
            print(f"   {fn}: expected '{exp}', got '{got}'")
        sys.exit(1)
    else:
        print(f"[PASS] All {len(benchmarks)} core benchmark items matched exact expected categories.")

    print("\nCategory Distribution Summary:")
    for cat, count in counts.most_common():
        pct = (count / len(items)) * 100
        print(f"  {cat:14}: {count:4} items ({pct:4.1f}%)")

    print("\n==================================================")
    print("ALL TESTS PASSED SUCCESSFULLY!")
    print("==================================================")

if __name__ == "__main__":
    main()
