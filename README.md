# Item Sorting Improved (Project Zomboid Build 42)

![Project Zomboid Build 42 Compatible](https://img.shields.io/badge/Project%20Zomboid-Build%2042-blue.svg)
![Zero Hardcoded Items](https://img.shields.io/badge/Algorithm-Zero--Hardcoding-brightgreen.svg)
![Multiplayer Compatible](https://img.shields.io/badge/Multiplayer-Dedicated%20Server%20Safe-success.svg)
![License](https://img.shields.io/badge/License-MIT-orange.svg)

**Item Sorting Improved** is a lightweight, zero-maintenance sorting and categorization engine designed specifically for **Project Zomboid Build 42**. 

It eliminates cluttered inventory panes and arbitrary vanilla categorization by dynamically classifying every item—vanilla, modded, and newly introduced—into a clean, intuitive, and alphabetically prefix-aligned taxonomy upon game boot.

---

## Key Features

- **Zero-Maintenance Mod Compatibility**: No hardcoded item lists to update. The classification engine evaluates item properties, tags, components, and attributes dynamically at runtime. Any weapon, tool, clothing item, food, or material added by any mod is automatically recognized and sorted.
- **Alphabetical Prefix-Aligned Taxonomy**: Category names use consistent prefix groupings (e.g. `Cloth*`, `Food*`, `Lit*`, `Sur*`, `Wep*`), keeping related goods grouped together naturally when sorting inventory or containers by category.
- **Build 42 Fluid System Integration**: Dynamically reacts to Build 42's liquid system. As you fill, drink, siphon, or empty fluid containers (canteens, buckets, gas cans, bottles), their category updates in real time (e.g., Water & Soda -> `Food - Beverage`, Gasoline -> `Fuel`, Bleach -> `Cleaning`, Empty -> `Container - Liquid`).
- **Dedicated Server & Loot Table Safe**: Preserves internal vanilla loot table flags (such as `Medical`, `MechanicsItem`, `SurvivalGear`, `FARMING_LOOT`, and `IS_MEMENTO`) before modifying display parameters. Dedicated servers safely bypass client UI categorization modifications, ensuring zero interference with `ItemPickerJava`.
- **Cosmetic & Wound Layer Filtering**: Automatically filters internal damage layers, cosmetic wounds, and hidden items (`ZedDmg`, `Wound`) into `Misc` to prevent inventory clutter.
- **Modder & Player Override Hook**: Includes a clean, decoupled override table allowing mod authors or players to define custom category assignments for specific item IDs with single-line declarations.
- **Comprehensive English Localization**: Full translation mapping with clean UI naming (`IGUI_ItemCat_*`) ready for localization into other languages.

---

## Category Taxonomy

The mod reorganizes items into 54 structured categories:

| Prefix / Group | Category Key | In-Game Display Name | Examples & Description |
| :--- | :--- | :--- | :--- |
| **Appear** | `Appear` | Appearance | Cosmetics, makeup, hair dye, hair gel, combs, razors |
| **Build** | `Build` | Building | Plaster, cement, bricks, gravel bags, hinges, doorknobs |
| | `BuildP` | Building - Paint | Paint cans, wallpaper, paint brushes |
| **Clean** | `Clean` | Cleaning | Bleach, soap, cleaning liquid, towels, mops, sponges |
| **Cloth** | `ClothAcc` | Clothing - Accessory | Belts, holsters, scarves, ties, badges, glasses |
| | `ClothArm` | Clothing - Arms/Hands | Gloves, forearm guards, handwear |
| | `ClothBack` | Clothing - Backpack | Backpacks, duffle bags, hiking bags, ALICE packs |
| | `ClothBag` | Clothing - Bag | Fanny packs, satchels, purses, pouches |
| | `ClothBody` | Clothing - Body | Shirts, jackets, coats, sweaters, dresses, vests |
| | `ClothFeet` | Clothing - Feet | Shoes, boots, socks, slippers |
| | `ClothHead` | Clothing - Head | Hats, helmets, masks, bandanas, glasses |
| | `ClothJew` | Clothing - Jewelry | Rings, necklaces, bracelets, earrings |
| | `ClothLeg` | Clothing - Legs | Pants, shorts, skirts |
| | `ClothUnder` | Clothing - Underwear | Underwear, bras, boxers, briefs |
| | `ClothMisc` | Clothing - Misc | Miscellaneous wearables |
| **Collect** | `Collect` | Collectable | Money, credit cards, plushies, Spiffo dolls, trophies |
| **Cont** | `Cont` | Container | Empty boxes, crates, sacks, storage bins |
| | `ContL` | Container - Liquid | Empty bottles, buckets, canteens, flasks, empty gas cans |
| **Cook** | `Cook` | Cooking | Frying pans, cooking pots, baking pans, spatulas, whisks |
| | `CookIng` | Cooking - Ingredient | Flour, sugar, salt, pepper, olive oil, yeast, spices |
| **Craft** | `Craft` | Crafting | Nails, screws, duct tape, glue, thread, wire, metal sheets |
| **Drugs** | `Drugs` | Drugs | Cigarettes, cigars, tobacco, joints, rolling papers, matches |
| **Elec** | `Elec` | Electronics | Radios, walkie-talkies, flashlights, batteries, timers |
| **Food** | `FoodA` | Food - Alcohol | Beer, wine, bourbon, whiskey, cider |
| | `FoodB` | Food - Beverage | Water bottles, soda cans, juices, milk, coffee, tea |
| | `FoodN` | Food - Non-Perishable | Canned food, dry rations, chips, candy, crackers |
| | `FoodP` | Food - Perishable | Fresh meat, fruits, vegetables, cooked meals, dairy |
| **Fuel** | `Fuel` | Fuel | Charcoal, propane tanks, firewood, kindling, lighter fluid |
| **Furn** | `Furn` | Furniture | Moveables, chairs, tables, beds, lamps, decorative items |
| **Junk** | `Junk` | Junk | Empty tin cans, trash, broken glass, scrap, dirt |
| **Key** | `Key` | Key | Door keys, vehicle keys, padlocks, keyrings |
| **Lit** | `LitC` | Literature - Cartography | Town maps, annotated maps, trail maps |
| | `LitE` | Literature - Entertainment | Comic books, novels, leisure magazines |
| | `LitR` | Literature - Recipe | Crafting recipes, cooking magazines, mechanics manuals |
| | `LitS` | Literature - Skill | Skill learning books (Carpentry, Metalworking, etc.) |
| | `LitW` | Literature - Writing | Notebooks, journals, blank sheets, pencils, pens |
| **Mech** | `Mech` | Mechanics | Car batteries, tires, mufflers, carburetors, brakes, engine parts |
| **Media** | `MediaA` | Media - Audio | Cassette tapes, vinyl records, CD-ROMs |
| | `MediaG` | Media - Game | Board games, chess, playing cards, dice, video games |
| | `MediaV` | Media - Video | VHS videotapes, recorded movies |
| **Med** | `Med` | Medical | Bandages, antibiotics, painkillers, disinfectants, splints |
| **Sur** | `SurCamp` | Survival - Camping | Tents, sleeping bags, campfires, tent pegs |
| | `SurFarm` | Survival - Farming | Seeds, seed packets, fertilizer, watering cans, compost |
| | `SurFish` | Survival - Fishing | Fishing rods, lures, fishing lines, tackle boxes |
| | `SurTrap` | Survival - Trapping | Cage traps, snare traps, mousetraps |
| **Tool** | `Tool` | Tool | Axes, hammers, saws, screwdrivers, crowbars, shovels |
| **Wep** | `WepAmmo` | Weapon - Ammunition | Bullets, shotgun shells, loose rounds, ammo boxes |
| | `WepAmmoMag` | Weapon - Magazine | Gun magazines, firearm clips, drum mags |
| | `WepBomb` | Weapon - Bomb | Pipe bombs, Molotov cocktails, smoke grenades |
| | `WepBow` | Weapon - Bow | Bows, crossbows, arrows, bolts |
| | `WepFire` | Weapon - Firearm | Handguns, rifles, shotguns, assault rifles, submachine guns |
| | `WepMelee` | Weapon - Melee | Baseball bats, knives, swords, spears, crowbars |
| | `WepPart` | Weapon - Part | Gun scopes, silencers, recoil pads, chokes, laser sights |
| **Misc** | `Misc` | Misc | Uncategorized items and internal system items |

---

## Architecture & Implementation

### File Structure
```
pz-auto-sort/
├── mod.info                                      # Mod metadata for PZ launcher / Workshop
├── poster.png                                    # Mod poster artwork (256x256)
├── icon.png                                      # Mod icon (64x64)
├── preview.png                                   # Steam Workshop preview image (512x512)
├── workshop.txt                                  # Workshop descriptor metadata
├── workshop_description.txt                      # Steam BBCode store page description
├── LICENSE                                       # MIT License
├── 42/                                           # Build 42 root directory
│   ├── mod.info                                  # B42-specific manifest
│   ├── poster.png
│   ├── icon.png
│   └── media/
│       └── lua/
│           ├── client/
│           │   └── ItemSortingImproved_Client.lua          # Action hooks & fluid update triggers
│           └── shared/
│               ├── ItemSortingImproved_Taxonomy.lua        # Category definitions & constants
│               ├── ItemSortingImproved_Overrides.lua       # Manual overrides for specific item IDs
│               ├── ItemSortingImproved_FluidCategories.lua # Dynamic fluid container classifier
│               ├── ItemSortingImproved_Core.lua            # Main classification engine & boot hook
│               └── Translate/
│                   └── EN/
│                       └── IG_UI.json                      # UI display translations (54 categories)
├── tests/
│   ├── run_offline_test.py                       # Automated verification test suite (5,100+ items)
│   ├── test_branding_generator.py                # Branding & preview generation tests
│   ├── test_readme_no_emojis.py                  # Documentation emoji integrity tests
│   └── test_stage_workshop.py                    # Workshop staging automation tests
└── tools/
    ├── generate_branding.py                      # Programmatic thumbnail & preview generator
    └── stage_workshop.py                         # Production Workshop packaging & staging tool
```

### Categorization Flow
1. **Boot Initialization (`OnGameBoot`)**:
   - Executes after all vanilla and modded script files are parsed by the game engine.
   - Iterates through `ScriptManager.instance:getAllItems()`.
   - Protects server integrity: bypasses execution if running on a dedicated server (`isServer() == true`).
2. **Prioritized Evaluation Tiers**:
   - **Tier 1 (Explicit Overrides)**: Checks `ItemSortingImproved.Overrides[fullName]`.
   - **Tier 1.5 (Damage & Hidden Filters)**: Checks for `ZedDmg`, `Wound`, cosmetic clothing layers, and hidden dev items.
   - **Tier 2 (Functional Heuristics & Signatures)**:
     1. *Drugs & Tobacco* (intercepts smokables before food classification)
     2. *Medical & First Aid* (intercepts medicinal herbs, ingestible pills, bandages)
     3. *Farming & Seeds* (intercepts seed packets, watering cans, fertilizer)
     4. *Cooking Ingredients* (intercepts spices, oils, flour, sugar, salt)
     5. *Food & Drink* (detects perishables, non-perishables, beverages, and alcoholic drinks)
     6. *Fuel & Combustion* (charcoal, propane, firewood)
     7. *Literature* (categorizes by skill, recipe, cartography, writing, or entertainment)
     8. *Weapons, Ammo & Explosives* (firearms, melee, parts, ammo, magazines, bows, bombs)
     9. *Clothing & Wearables* (inspects `BodyLocation` to sort into head, body, legs, feet, jewelry, etc.)
     10. *Containers* (backpacks, bags, storage containers, liquid vessels)
     11. *Cleaning, Appearance, Tools, Building, Crafting, Mechanics, Electronics, Survival, Furniture, Media, Collectables, Junk, and Misc*.
3. **Loot Table Protection**:
   - Automatically injects required item parameters (`Medical = "true"`, `MechanicsItem = "true"`, `SurvivalGear = "true"`, tags `FARMING_LOOT`, `IS_MEMENTO`) to ensure vanilla loot spawning distributions remain 100% intact.
4. **Dynamic Fluid Tracking (Client)**:
   - Hooks into `ISFluidEmptyAction`, `ISDrinkFluidAction`, `ISDrinkFromBottle`, `ISFluidTransferAction`, `ISTakeFuel`, and `ISTakeWaterAction`.
   - Listens to `OnRefreshInventoryWindowContainers` and `OnGameStart`.
   - When a fluid container's volume or fluid type changes, its `DisplayCategory` is recalculated on the fly.

---

## Adding Custom Overrides

If you are a modder creating custom items or a player wanting to customize your sorting, you can override any item's category without touching the core engine:

```lua
-- In 42/media/lua/shared/ItemSortingImproved_Overrides.lua
-- (or in your own mod's shared Lua script)

ItemSortingImproved = ItemSortingImproved or {}
ItemSortingImproved.Overrides = ItemSortingImproved.Overrides or {}

-- Format: ItemSortingImproved.Overrides["FullModule.ItemName"] = "CategoryKey"
ItemSortingImproved.Overrides["MyMod.PlasmaRifle"]     = "WepFire"
ItemSortingImproved.Overrides["MyMod.TacticalBandage"] = "Med"
ItemSortingImproved.Overrides["Base.CustomJournal"]    = "LitW"
```

---

## Testing & Quality Assurance

The mod includes an automated offline Python test suite that validates the classification logic against all **5,100+ vanilla Build 42 item definitions**:

```bash
python tests/run_offline_test.py
```

### Test Guarantees:
- **100% Valid Translation Keys**: Ensures every categorized item maps to an existing translation key in `IG_UI.json`.
- **Zero Missing Categories**: Validates all active categories against registered UI keys.
- **Regression Benchmarks**: Validates critical items (e.g. `Base.Axe` -> `Tool`, `Base.Pistol` -> `WepFire`, `Base.BookCarpentry1` -> `LitS`, `Base.PetrolCan` -> `ContL`) to ensure deterministic classification.

---

## Installation

### For Players
1. Subscribe to the mod on the Steam Workshop (or download the release and place the folder into `%UserProfile%\Zomboid\mods\`).
2. Launch Project Zomboid (Build 42+).
3. Enable **Item Sorting Improved** in the **Mods** menu.
4. Start a new game or load an existing save.

### For Dedicated Servers
Add `ItemSortingImproved` to the `Mods=` line in your server's `.ini` file:
```ini
Mods=ItemSortingImproved
```

---

## Steam Workshop Deployment

To stage the mod for Project Zomboid's built-in Workshop uploader:

1. Run the staging tool:
```bash
python tools/stage_workshop.py
```
This automatically packages the clean mod files into `%USERPROFILE%\Zomboid\Workshop\ItemSortingImproved\`, complete with `preview.png`, `workshop.txt`, and `workshop_description.txt` (while preserving your assigned Workshop ID on updates).

2. Launch Project Zomboid (Build 42).
3. Select **Workshop** on the main menu.
4. Select **Item Sorting Improved** and verify the preview image and description.
5. Click **Publish** (or Update).

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) or source code headers for details.

