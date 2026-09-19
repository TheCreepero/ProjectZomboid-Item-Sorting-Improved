--[[
    Item Sorting Improved - Category Taxonomy
    Build 42 Compatible
    
    Defines the standard sorting categories used across the game.
    Prefix conventions group related items together alphabetically in inventory panes:
      - Appear: Appearance & cosmetics
      - Build: Building & construction materials
      - Clean: Cleaning supplies
      - Cloth*: Wearables grouped by body slot
      - Collect: Collectables & valuables
      - Cont*: Storage & liquid containers
      - Cook*: Cooking implements & ingredients
      - Craft: Crafting materials & fasteners
      - Drugs: Cigarettes, tobacco & recreational items
      - Elec: Electronics, radios & communication
      - Food*: Food items divided by perishability & beverage type
      - Fuel: Gas, fuel & combustible materials
      - Furn: Moveable furniture & decorative objects
      - Junk: Empty trash, scrap & useless items
      - Key: Keys, locks & key rings
      - Lit*: Literature split by skill, recipe, map, writing & entertainment
      - Mech: Vehicle parts & maintenance components
      - Media*: Audio, video & game media
      - Med: Medical supplies & treatment
      - Misc: General uncategorized utilities
      - Sur*: Survival disciplines (camping, farming, fishing, trapping)
      - Tool: Hand tools & work equipment
      - Wep*: Weapons split into firearm, melee, ammo, magazine, bow, bomb, part
]]

ItemSortingImproved = ItemSortingImproved or {}

ItemSortingImproved.Categories = {
    -- Appearance
    Appear      = "Appear",       -- Appearance & Cosmetics

    -- Building
    Build       = "Build",        -- Building / Construction
    BuildP      = "BuildP",       -- Building - Paint & Wallpaper

    -- Cleaning
    Clean       = "Clean",        -- Cleaning supplies

    -- Clothing (grouped by body slot)
    ClothAcc    = "ClothAcc",     -- Clothing - Accessory (glasses, scarves, ties, belts, holsters)
    ClothArm    = "ClothArm",     -- Clothing - Arms/Hands (gloves, forearm guards)
    ClothBack   = "ClothBack",    -- Clothing - Backpack / Back-worn bags
    ClothBag    = "ClothBag",     -- Clothing - Bag (satchels, fanny packs, purses)
    ClothBody   = "ClothBody",    -- Clothing - Body (shirts, jackets, sweaters, dresses, vests)
    ClothFeet   = "ClothFeet",    -- Clothing - Feet (shoes, boots, socks)
    ClothHead   = "ClothHead",    -- Clothing - Head (hats, helmets, masks, bandanas)
    ClothJew    = "ClothJew",     -- Clothing - Jewelry (rings, necklaces, bracelets, earrings)
    ClothLeg    = "ClothLeg",     -- Clothing - Legs (pants, shorts, skirts)
    ClothUnder  = "ClothUnder",   -- Clothing - Underwear (boxers, briefs, bras)
    ClothMisc   = "ClothMisc",    -- Clothing - Misc

    -- Collectable
    Collect     = "Collect",      -- Collectable / Valuables (cash, cards, toys)

    -- Container
    Cont        = "Cont",         -- Container - General storage (boxes, sacks, crates)
    ContL       = "ContL",        -- Container - Liquid (bottles, flasks, buckets, gas cans)

    -- Cooking
    Cook        = "Cook",         -- Cooking - Cookware & Utensils
    CookIng     = "CookIng",      -- Cooking - Ingredient (spices, flour, sugar, salt, oil)

    -- Crafting
    Craft       = "Craft",        -- Crafting - Materials & Fasteners (nails, glue, tape, thread, wire, metal)

    -- Drugs
    Drugs       = "Drugs",        -- Drugs & Tobacco (cigarettes, cigars, rolling paper)

    -- Electronics
    Elec        = "Elec",         -- Electronics (radios, walkie-talkies, flashlights, batteries)

    -- Food
    FoodA       = "FoodA",        -- Food - Alcohol (beer, wine, liquor)
    FoodB       = "FoodB",        -- Food - Beverage (water, soda, juice, milk, coffee, tea)
    FoodN       = "FoodN",        -- Food - Non-Perishable (canned, dried rations, chips, candy)
    FoodP       = "FoodP",        -- Food - Perishable (fresh meat, fruit, vegetables, dairy, cooked meals)

    -- Fuel
    Fuel        = "Fuel",         -- Fuel (gasoline, propane, charcoal, firewood)

    -- Furniture
    Furn        = "Furn",         -- Furniture / Moveables

    -- Junk
    Junk        = "Junk",         -- Junk / Trash (empty cans, broken glass, scrap)

    -- Key
    Key         = "Key",          -- Key (door keys, car keys, keyrings, padlocks)

    -- Literature
    LitC        = "LitC",         -- Literature - Cartography (maps)
    LitE        = "LitE",         -- Literature - Entertainment (novels, comics, magazines)
    LitR        = "LitR",         -- Literature - Recipe (crafting & cooking magazines)
    LitS        = "LitS",         -- Literature - Skill (skill training books)
    LitW        = "LitW",         -- Literature - Writing (notebooks, journals, pens, pencils)

    -- Mechanics
    Mech        = "Mech",         -- Mechanics (car parts, tires, engines, brakes, mufflers)

    -- Media
    MediaA      = "MediaA",       -- Media - Audio (cassettes, vinyl records, CDs)
    MediaG      = "MediaG",       -- Media - Game (board games, cards, video games)
    MediaV      = "MediaV",       -- Media - Video (VHS tapes, films)

    -- Medical
    Med         = "Med",          -- Medical (bandages, pills, disinfectants, first aid)

    -- Misc
    Misc        = "Misc",         -- Misc (general uncategorized items)

    -- Survival
    SurCamp     = "SurCamp",      -- Survival - Camping (tents, sleeping bags, campfire)
    SurFarm     = "SurFarm",      -- Survival - Farming (seeds, watering cans, fertilizer)
    SurFish     = "SurFish",      -- Survival - Fishing (rods, lures, line, tackle)
    SurTrap     = "SurTrap",      -- Survival - Trapping (cages, snares, animal traps)

    -- Tools
    Tool        = "Tool",         -- Tool (hammers, saws, screwdrivers, wrenches, axes, shovels)

    -- Weapons & Ammo
    WepAmmo     = "WepAmmo",      -- Weapon - Ammunition (bullets, shotgun shells, ammo boxes)
    WepAmmoMag  = "WepAmmoMag",   -- Weapon - Magazine (gun magazines, clips)
    WepBomb     = "WepBomb",      -- Weapon - Bomb / Explosive (pipe bombs, molotovs, smoke bombs)
    WepBow      = "WepBow",       -- Weapon - Bow / Crossbow (bows, crossbows, arrows, bolts)
    WepFire     = "WepFire",      -- Weapon - Firearm (pistols, rifles, shotguns, SMGs)
    WepMelee    = "WepMelee",     -- Weapon - Melee (blades, blunts, spears, clubs)
    WepPart     = "WepPart",      -- Weapon - Part (scopes, chokes, silencers, recoil pads)
}

