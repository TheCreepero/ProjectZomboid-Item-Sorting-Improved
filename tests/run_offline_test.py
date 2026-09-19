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
README_FILE = os.path.join(os.path.dirname(__file__), "..", "README.md")

try:
    from test_readme_no_emojis import find_readme_emojis
except ImportError:
    from tests.test_readme_no_emojis import find_readme_emojis


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

def has_any_tag(tag_set, tags):
    return any(t in tag_set for t in tags)

def contains_any(haystack, words):
    return any(w in haystack for w in words)

def classify_item(props):
    fn = props.get("fullname", "")
    name = props.get("name", "")
    name_lower = name.lower()
    disp_cat = props.get("DisplayCategory", "")
    raw_tags = props.get("Tags", "").split(";")
    tags = set()
    for t in raw_tags:
        t = t.strip().lower()
        if t:
            tags.add(t)
            if ":" in t:
                tags.add(t.split(":", 1)[1])
    itype = props.get("ItemType", "").replace("base:", "").lower()
    body_loc = props.get("BodyLocation", "").replace("base:", "").lower()
    can_equip = props.get("CanBeEquipped", "").replace("base:", "").lower()
    hidden = props.get("hidden", "").lower() == "true"

    # Tier 1: Overrides
    overrides = {
        "Base.Wallet": "ClothAcc",
        "Base.Wallet2": "ClothAcc",
        "Base.Wallet3": "ClothAcc",
        "Base.Wallet4": "ClothAcc",
        "Base.CreditCard": "Collect",
        "Base.Money": "Collect",
        "Base.Yoyo": "MediaG",
        "Base.Dice": "MediaG",
        "Base.Cards": "MediaG",
        "Base.Spiffo": "Collect",
        "Base.FluffyBfc": "Collect",
        "Base.FreddyFox": "Collect",
        "Base.JacquesBeaver": "Collect",
        "Base.MoleyMole": "Collect",
        "Base.PancakeHedgehog": "Collect",
    }
    if fn in overrides:
        return overrides[fn]

    # Tier 1.5: Exclude internal zombie wound & cosmetic damage layers
    if hidden or disp_cat in ["ZedDmg", "Wound"] or body_loc in ["zeddmg", "wound"] or "zeddmg_" in name_lower or "wound_" in name_lower:
        return "Misc"

    # 1. DRUGS & TOBACCO (before Food)
    if has_any_tag(tags, ["smoke", "tobacco", "smokable"]) or contains_any(name_lower, ["cigarette", "cigar", "tobacco", "joint", "rollingpaper", "lighter", "matches"]):
        return "Drugs"

    # 2. MEDICAL & FIRST AID (before Food)
    if disp_cat in ["FirstAid", "FirstAidWeapon", "Bandage"] or has_any_tag(tags, ["medical", "firstaid", "bandage", "pill", "disinfectant"]) or props.get("CanBandage", "").lower() == "true" or contains_any(name_lower, ["bandage", "bandaid", "pill", "antibiotic", "painkiller", "antidepressant", "splint", "suture", "disinfectant", "scalpel"]):
        return "Med"

    # 3. FARMING & SEEDS (before Literature)
    if disp_cat in ["Gardening", "GardeningWeapon"] or has_any_tag(tags, ["farming", "seed", "gardening", "farming_loot"]) or "seed" in name_lower or contains_any(name_lower, ["wateringcan", "fertilizer", "compost", "plantgrowth"]):
        return "SurFarm"

    # 4. COOKING INGREDIENTS (before Food)
    if has_any_tag(tags, ["minoringredient", "sugar", "salt", "flour", "yeast", "bakingfat", "bakingpowder"]) or contains_any(name_lower, ["flour", "sugar", "salt", "pepper", "oilolive", "oilvegetable", "vegetableoil", "oliveoil", "cookingoil", "vinegar", "yeast", "cornmeal", "bakingsoda", "cocoapowder", "marinara", "ketchup", "mustard", "mayonnaise", "syrup", "honey"]):
        return "CookIng"

    # 5. FOOD & DRINK
    if itype == "food" or disp_cat == "Food" or "food" in props.get("file", ""):
        if props.get("Alcoholic", "").lower() == "true" or has_any_tag(tags, ["alcohol", "beer", "wine", "liquor"]):
            return "FoodA"
        is_soup_or_meal = contains_any(name_lower, ["soup", "stew", "cereal", "oatmeal", "pasta", "chili", "chowder", "broth"])
        if not is_soup_or_meal:
            if props.get("CanStoreWater", "").lower() == "true" or disp_cat == "Water" or has_any_tag(tags, ["drink", "water", "wetbeverageingredient"]) or contains_any(name_lower, ["water", "soda", "juice", "milk", "coffee", "tea", "beverage", "popcan"]):
                return "FoodB"
        canned = props.get("CannedFood", "").lower() == "true" or "canned" in name_lower
        cant_freeze = props.get("CantBeFrozen", "").lower() == "true"
        days_rotten = float(props.get("DaysTotallyRotten", 0)) if props.get("DaysTotallyRotten") else 0
        if canned or cant_freeze or days_rotten <= 0 or days_rotten >= 1000000:
            return "FoodN"
        return "FoodP"

    # 6. FUEL & COMBUSTION (before Weapons & Craft)
    if (has_any_tag(tags, ["takefuel", "charcoal", "lighterfluid"]) or contains_any(name_lower, ["propanetank", "charcoal", "firewood", "kindling", "lighterfluid", "coalbag"])) and "nails" not in name_lower:
        return "Fuel"

    # 7. LITERATURE
    if itype == "literature" or "literature" in props.get("file", ""):
        if props.get("SkillTrained"):
            return "LitS"
        if props.get("TeachedRecipes") or props.get("LearnedRecipes"):
            return "LitR"
        if itype == "map" or disp_cat == "Cartography" or "map" in name_lower:
            return "LitC"
        if props.get("CanWrite", "").lower() == "true" or has_any_tag(tags, ["write", "drawing"]) or contains_any(name_lower, ["pencil", "penspiffo", "penfancy", "penmulticolor", "bluepen", "greenpen", "redpen", "notebook", "journal", "crayon", "eraser", "sheetpaper"]) or name_lower == "pen":
            return "LitW"
        return "LitE"

    if itype == "map" or disp_cat == "Cartography" or "map" in name_lower:
        return "LitC"

    # 8. WEAPONS, AMMO & EXPLOSIVES
    if itype == "weapon" or "weapon" in props.get("file", ""):
        if disp_cat in ["Explosives", "Devices"] or has_any_tag(tags, ["explosive", "bomb", "trap"]) or contains_any(name_lower, ["pipebomb", "molotov", "grenade", "aerosolbomb", "smokebomb"]):
            return "WepBomb"
        if has_any_tag(tags, ["bow", "crossbow"]) or contains_any(name_lower, ["crossbow", "woodenbow", "compoundbow", "recurvebow"]) or name_lower == "bow":
            return "WepBow"
        if props.get("Ranged", "").lower() == "true" or props.get("IsAimedFirearm", "").lower() == "true" or props.get("GunType"):
            return "WepFire"
        if disp_cat in ["Fishing", "FishingWeapon"] or has_any_tag(tags, ["fishing", "lure", "rod"]) or "fishingrod" in name_lower:
            return "SurFish"
        if disp_cat in ["Gardening", "GardeningWeapon"] or has_any_tag(tags, ["farming", "seed", "gardening"]):
            return "SurFarm"
        if disp_cat in ["Tool", "ToolWeapon"] or has_any_tag(tags, ["hammer", "saw", "screwdriver", "wrench", "crowbar", "welding", "pipewrench", "sledgehammer", "shovel", "pliers", "scissors", "trowel", "chisel", "needle"]):
            return "Tool"
        return "WepMelee"

    if itype in ["weapon_part", "weaponpart"] or "weaponpart" in props.get("file", "") or disp_cat == "WeaponPart":
        return "WepPart"

    if disp_cat == "Ammo" or has_any_tag(tags, ["ammo", "bullet", "shell"]) or contains_any(name_lower, ["bullets", "shells", "rounds", "cartridge", "ammo", "arrow", "bolt"]):
        if contains_any(name_lower, ["magazine", "clip", "drummag"]) and not contains_any(name_lower, ["paperclip", "clipboard", "recipeclipping"]):
            return "WepAmmoMag"
        return "WepAmmo"

    if contains_any(name_lower, ["magazine", "clip", "drummag"]) and not contains_any(name_lower, ["paperclip", "clipboard", "recipeclipping"]) and itype != "literature":
        return "WepAmmoMag"

    # 9. CLOTHING & WEARABLES
    if itype in ["clothing", "alarm_clock_clothing", "alarmclockclothing"] or "clothing" in props.get("file", "") or body_loc:
        if contains_any(body_loc, ["hat", "mask", "eyes", "ears", "nose", "fullhat", "full_hat", "maskeyes", "mask_eyes", "maskfull", "mask_full", "eartop", "ear_top", "lefteye", "left_eye", "righteye", "right_eye"]):
            return "ClothHead"
        if contains_any(body_loc, ["hands", "handsleft", "handsright", "rightarm", "leftarm", "forearm_right", "forearm_left", "fore_arm_right", "fore_arm_left"]):
            return "ClothArm"
        if contains_any(body_loc, ["shoes", "socks", "calf_right", "calf_left", "gaiter_left", "gaiter_right"]):
            return "ClothFeet"
        if contains_any(body_loc, ["pants", "shortpants", "short_pants", "shortsshort", "shorts_short", "legs1", "skirt", "longskirt", "long_skirt", "thigh_right", "thigh_left", "pantsextra", "pants_extra", "pants_skinny", "groin"]):
            return "ClothLeg"
        if contains_any(body_loc, ["underwear", "underwearbottom", "underwear_bottom", "underweartop", "underwear_top", "underwearextra1", "underwear_extra1", "underwearextra2", "underwear_extra2"]):
            return "ClothUnder"
        if contains_any(body_loc, ["necklace", "necklace_long", "bellybutton", "right_middlefinger", "left_middlefinger", "right_middle_finger", "left_middle_finger", "right_ringfinger", "left_ringfinger", "right_ring_finger", "left_ring_finger", "rightwrist", "leftwrist", "right_wrist", "left_wrist", "ears_piercing"]):
            return "ClothJew"
        if contains_any(body_loc, ["back", "satchel"]) or has_any_tag(tags, ["backpack"]) or ("bag" in name_lower and can_equip == "back"):
            return "ClothBack"
        if contains_any(body_loc, ["belt", "holster", "ankleholster", "shoulder_holster", "beltextra", "scarf", "tie", "tail", "badge"]):
            return "ClothAcc"
        return "ClothBody"

    # 10. CONTAINERS
    is_fluid_cont = "fluidcontainer" in props.get("Component", "").lower() or disp_cat == "WaterContainer"
    if itype == "container" or "container" in props.get("file", "") or is_fluid_cont or contains_any(name_lower, ["gascan", "petrolcan"]):
        if "back" in can_equip or contains_any(name_lower, ["backpack", "dufflebag", "hikingbag", "alice", "schoolbag"]):
            return "ClothBack"
        if contains_any(can_equip, ["belt", "fannypack"]) or contains_any(name_lower, ["fannypack", "satchel", "purse", "pouch", "holster"]):
            return "ClothBag"
        if props.get("CanStoreWater", "").lower() == "true" or disp_cat in ["WaterContainer", "Water"] or is_fluid_cont or contains_any(name_lower, ["bottle", "canteen", "flask", "bucket", "kettle", "gascan", "petrolcan", "dispenserbottle"]):
            return "ContL"
        return "Cont"

    # 11. CLEANING SUPPLIES
    if has_any_tag(tags, ["bleach", "soap", "cleaning", "towel", "clean"]) or contains_any(name_lower, ["bleach", "soap", "mop", "dishcloth", "bathtowel", "sponge", "broom", "cleaningliquid"]):
        return "Clean"

    # 12. APPEARANCE & COSMETICS
    if disp_cat == "Appearance" or props.get("MakeUpType") or contains_any(name_lower, ["makeup", "lipstick", "hairdye", "hairgel", "eyeshadow", "perfume", "cologne", "hairspray", "comb", "razor"]):
        return "Appear"

    # 13. TOOLS
    if disp_cat in ["Tool", "ToolWeapon"] or has_any_tag(tags, ["tool", "hammer", "saw", "screwdriver", "wrench", "pipewrench", "sledgehammer", "shovel", "blowtorch", "weldingmask", "crowbar", "pliers", "scissors", "trowel", "chisel", "needle"]) or contains_any(name_lower, ["hammer", "saw", "screwdriver", "wrench", "pipewrench", "sledgehammer", "shovel", "blowtorch", "weldingmask", "crowbar", "pliers", "scissors", "trowel"]):
        return "Tool"

    # 14. BUILDING & CONSTRUCTION
    if disp_cat == "Paint" or has_any_tag(tags, ["paint", "wallpaper"]) or contains_any(name_lower, ["paint", "wallpaper"]):
        return "BuildP"
    if (name_lower == "log" or "logstacks" in name_lower or "treelog" in name_lower or "woodenlog" in name_lower) or contains_any(name_lower, ["brick", "gravelbag", "concrete", "plaster", "hinge", "doorknob", "anvil", "sandbag", "barbedwire", "cement"]):
        return "Build"

    # 15. CRAFTING MATERIALS
    if disp_cat in ["Material", "RecipeResource"] or has_any_tag(tags, ["carpentry", "metalworking", "masonry", "tailoring", "crafting"]) or contains_any(name_lower, ["nails", "screws", "ducttape", "glue", "thread", "wire", "metalsheet", "scrapmetal", "leatherstrip", "denimstrip", "sheetmetal", "twine", "rope", "woodglue", "superglue"]):
        return "Craft"

    # 16. MECHANICS & VEHICLES
    if disp_cat in ["VehicleMaintenance", "VehicleMaintenanceWeapon"] or has_any_tag(tags, ["mechanic", "vehiclepart"]) or contains_any(name_lower, ["tire", "muffler", "carburetor", "carengine", "carbattery", "brakes", "suspension", "gaspump", "windshield"]):
        return "Mech"

    # 17. ELECTRONICS & COMMUNICATION
    if itype in ["radio", "alarmclock", "alarm_clock"] or disp_cat in ["Electronics", "Communications", "LightSource"] or has_any_tag(tags, ["electronics", "radio", "battery", "lightsource", "flashlight"]) or contains_any(name_lower, ["radio", "walkietalkie", "battery", "flashlight", "lamp", "lightbulb", "hamradio", "generator", "timer", "motiondetector"]):
        return "Elec"

    # 18. SURVIVAL DISCIPLINES
    if disp_cat in ["Fishing", "FishingWeapon"] or has_any_tag(tags, ["fishing", "lure", "rod"]) or contains_any(name_lower, ["fishingrod", "fishingline", "fishinglure", "fishhook", "fishingtackle", "fishingnet"]):
        return "SurFish"
    if disp_cat in ["Trapping"] or has_any_tag(tags, ["trapping", "trap"]) or contains_any(name_lower, ["trap", "mousetrap", "cagetrap", "snaretrap"]):
        return "SurTrap"
    if disp_cat in ["Camping"] or has_any_tag(tags, ["camping", "tent"]) or contains_any(name_lower, ["tent", "sleepingbag", "campfire", "tentpeg"]):
        return "SurCamp"

    # 19. KEYS & LOCKS
    if itype in ["key", "key_ring", "keyring"] or contains_any(name_lower, ["key", "padlock", "combinationlock", "keyring"]):
        return "Key"

    # 20. FURNITURE & MOVEABLES
    if itype == "moveable" or disp_cat == "Furniture" or contains_any(name_lower, ["chair", "table", "bed", "shelf", "sofa", "couch", "cabinet", "drawer", "desk", "wardrobe"]):
        return "Furn"

    # 21. RECORDED MEDIA & ENTERTAINMENT
    if contains_any(name_lower, ["cassette", "vinyl", "cdrom", "compactdisc", "audiobook"]):
        return "MediaA"
    if contains_any(name_lower, ["vhs", "videotape", "movie", "film"]):
        return "MediaV"
    if contains_any(name_lower, ["boardgame", "chess", "checkers", "carddeck", "dice", "yoyo", "gameboy", "videogame"]):
        return "MediaG"

    # 22. COLLECTABLES & VALUABLES
    if disp_cat == "Memento" or has_any_tag(tags, ["is_memento"]) or contains_any(name_lower, ["money", "creditcard", "plush", "spiffo", "doll", "trophy", "wallet"]):
        return "Collect"

    # 23. COOKING UTENSILS
    if disp_cat == "Cooking" or contains_any(name_lower, ["fryingpan", "saucepan", "cookingpot", "roastingpan", "bakingpan", "skillet", "bowl", "rollingpin", "whisk", "grater", "kettle"]) or name_lower in ["pan", "pot"]:
        return "Cook"

    # 24. JUNK & TRASH
    if disp_cat == "Junk" or contains_any(name_lower, ["empty", "tin", "canempty", "trash", "scrap", "debris", "dirt", "broken"]):
        return "Junk"

    return "Misc"

def main():
    print("==================================================")
    print("Item Sorting Improved - Automated Offline Tests")
    print("==================================================")

    valid_categories = load_valid_categories()
    print(f"[OK] Loaded {len(valid_categories)} valid categories from IG_UI.json")

    # Documentation formatting assertion: Ensure zero emojis in README.md
    emojis = find_readme_emojis(README_FILE)
    assert len(emojis) == 0, f"Found {len(emojis)} emojis in README.md: {emojis}"
    print("[PASS] Documentation check: README.md contains 0 emojis.")

    items = parse_items()
    print(f"[OK] Parsed {len(items)} items from vanilla PZ scripts")

    counts = Counter()
    invalid_categories = []
    items_by_fullname = {}

    # Comprehensive Build 42 Verified Benchmarks & Regression Cases
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
        "Base.Tshirt_ArmyGreen": "ClothBody",
        "Base.Trousers": "ClothLeg",
        "Base.Shoes_TrainerTINT": "ClothFeet",
        "Base.Gloves_LeatherGloves": "ClothArm",
        "Base.Bag_Schoolbag": "ClothBack",
        "Base.Ring_Left_RingFinger_Gold": "ClothJew",
        "Base.Boxers_Hearts": "ClothUnder",
        "Base.FishingRod": "SurFish",
        "Base.TomatoBagSeed2": "SurFarm",
        "Base.TrapCage": "SurTrap",
        "Base.CarBattery1": "Mech",
        "Base.RadioBlack": "Elec",
        "Base.Key1": "Key",
        "Base.Money": "Collect",
        "Base.CigaretteSingle": "Drugs",
        "Base.Flour2": "CookIng",
        "Base.Charcoal": "Fuel",
        "Base.PropaneTank": "Fuel",
        "Base.Firewood": "Fuel",
        "Base.Antibiotics": "Med",
        "Base.BowlingPin": "WepMelee",
        "Base.Paperclip": "Craft",
        "Base.CannedBolognese_Box": "FoodN",
    }

    benchmark_failures = []
    benchmarks_found = set()

    for it in items:
        fn = it["fullname"]
        items_by_fullname[fn] = it
        cat = classify_item(it)
        counts[cat] += 1
        if cat not in valid_categories:
            invalid_categories.append((fn, cat))

        if fn in benchmarks:
            benchmarks_found.add(fn)
            expected = benchmarks[fn]
            if cat != expected:
                benchmark_failures.append((fn, expected, cat))

    # Assertions
    assert len(invalid_categories) == 0, f"Found {len(invalid_categories)} items with invalid categories: {invalid_categories[:5]}"
    print(f"[PASS] 100% of {len(items)} items received valid categories registered in translations.")

    missing_benchmarks = set(benchmarks.keys()) - benchmarks_found
    assert len(missing_benchmarks) == 0, f"Missing benchmark items in game scripts: {missing_benchmarks}"

    if benchmark_failures:
        print(f"[FAIL] Benchmark mismatches ({len(benchmark_failures)}):")
        for fn, exp, got in benchmark_failures:
            print(f"   {fn}: expected '{exp}', got '{got}'")
        sys.exit(1)
    else:
        print(f"[PASS] All {len(benchmarks)} core benchmark & regression items matched exact expected categories.")

    print(f"\nCategory Distribution Summary ({len(counts)} active categories):")
    for cat, count in counts.most_common():
        pct = (count / len(items)) * 100
        print(f"  {cat:14}: {count:4} items ({pct:4.1f}%)")

    print("\n==================================================")
    print("ALL TESTS PASSED SUCCESSFULLY!")
    print("==================================================")

if __name__ == "__main__":
    main()
