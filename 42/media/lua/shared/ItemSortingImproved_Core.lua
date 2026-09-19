--[[
    Item Sorting Improved - Core Auto-Categorization Engine
    Build 42 Compatible
    
    Dynamically categorizes all items in the game (both vanilla and modded)
    at game boot, eliminating the need for hardcoded item lists.
]]

require("ItemSortingImproved_Taxonomy")
require("ItemSortingImproved_Overrides")
require("ItemSortingImproved_FluidCategories")

ItemSortingImproved = ItemSortingImproved or {}

-- Cache string lower functions for speed
local strLower = string.lower
local strFind  = string.find

-- Helper to check if item has any tag in a list
local function hasAnyTag(item, tagList)
    if not item then return false end
    
    -- Check via item:hasTag if available
    if item.hasTag then
        for i = 1, #tagList do
            if item:hasTag(tagList[i]) then
                return true
            end
        end
    end
    
    -- Check tags collection if available
    local tags = item.getTags and item:getTags()
    if tags and not tags:isEmpty() then
        for i = 1, #tagList do
            local searchTag = strLower(tagList[i])
            local it = tags:iterator()
            while it:hasNext() do
                local tagObj = it:next()
                if tagObj and strLower(tostring(tagObj)) == searchTag then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Helper to check if any needle substring is present in haystack string
local function containsAny(haystack, needles)
    if not haystack then return false end
    haystack = strLower(haystack)
    for i = 1, #needles do
        if strFind(haystack, needles[i], 1, true) then
            return true
        end
    end
    return false
end

-- Safely get body location string
local function getBodyLocationStr(item)
    if not item then return "" end
    local loc = item.getBodyLocation and item:getBodyLocation()
    if loc then
        return strLower(tostring(loc))
    end
    return ""
end

-- Core categorization function for a single script Item
function ItemSortingImproved.CategorizeItem(item)
    if not item then return nil end
    
    local fullName = item:getFullName() or ""
    
    -- Tier 1: User / Modder Explicit Overrides
    if ItemSortingImproved.Overrides[fullName] then
        return ItemSortingImproved.Overrides[fullName]
    end
    
    local name = item:getName() or ""
    local nameLower = strLower(name)
    local typeStr = item.getTypeString and item:getTypeString() or ""
    local dispCat = item.getDisplayCategory and item:getDisplayCategory() or ""
    local bodyLoc = getBodyLocationStr(item)
    local canEquip = item.getCanBeEquipped and strLower(tostring(item:getCanBeEquipped())) or ""
    
    -- Tier 2: Classification by Item Type & Functional Properties
    
    -- 1. FOOD & DRINK
    if typeStr == "Food" then
        if (item.isAlcoholic and item:isAlcoholic()) or hasAnyTag(item, {"Alcohol", "Beer", "Wine", "Liquor"}) then
            return ItemSortingImproved.Categories.FoodA
        end
        if (item.getCanStoreWater and item:getCanStoreWater()) or dispCat == "Water" or 
           hasAnyTag(item, {"Drink", "Water"}) or containsAny(nameLower, {"water", "soda", "juice", "milk", "coffee", "tea", "beverage"}) then
            return ItemSortingImproved.Categories.FoodB
        end
        
        local isCanned = (item.isCannedFood and item:isCannedFood()) or (item.cannedFood == true) or strFind(nameLower, "canned", 1, true)
        local cantFreeze = (item.isCantBeFrozen and item:isCantBeFrozen()) or (item.cantBeFrozen == true)
        local daysRotten = item.getDaysTotallyRotten and item:getDaysTotallyRotten() or 0
        
        -- Non-perishables: canned goods, dry rations, spices, or foods that never rot
        if isCanned or cantFreeze or daysRotten <= 0 or daysRotten >= 1000000000 then
            return ItemSortingImproved.Categories.FoodN
        end
        return ItemSortingImproved.Categories.FoodP
    end
    
    -- 2. LITERATURE
    if typeStr == "Literature" then
        local skill = item.getSkillTrained and item:getSkillTrained()
        if skill and #skill > 0 then
            return ItemSortingImproved.Categories.LitS
        end
        local recipes = item.getTeachedRecipes and item:getTeachedRecipes()
        if recipes and not recipes:isEmpty() then
            return ItemSortingImproved.Categories.LitR
        end
        if dispCat == "Cartography" or strFind(nameLower, "map", 1, true) then
            return ItemSortingImproved.Categories.LitC
        end
        if (item.canWrite and item:canWrite()) or hasAnyTag(item, {"Write", "Drawing"}) or 
           containsAny(nameLower, {"pencil", "pen", "notebook", "journal", "crayon", "eraser", "sheetpaper"}) then
            return ItemSortingImproved.Categories.LitW
        end
        return ItemSortingImproved.Categories.LitE
    end
    
    if typeStr == "Map" or dispCat == "Cartography" or strFind(nameLower, "map", 1, true) then
        return ItemSortingImproved.Categories.LitC
    end
    
    -- 3. WEAPONS, AMMO & EXPLOSIVES
    if typeStr == "Weapon" then
        if dispCat == "Explosives" or dispCat == "Devices" or hasAnyTag(item, {"Explosive", "Bomb", "Trap"}) or 
           containsAny(nameLower, {"pipebomb", "molotov", "grenade", "aerosolbomb", "smokebomb"}) then
            return ItemSortingImproved.Categories.WepBomb
        end
        if hasAnyTag(item, {"Bow", "Crossbow"}) or containsAny(nameLower, {"bow", "crossbow"}) then
            return ItemSortingImproved.Categories.WepBow
        end
        if (item.isRanged and item:isRanged()) or (item.isAimedFirearm and item:isAimedFirearm()) or 
           (item.gunType and not item.gunType:isEmpty()) then
            return ItemSortingImproved.Categories.WepFire
        end
        -- Tools and survival gear that function as improvised weapons
        if dispCat == "Fishing" or dispCat == "FishingWeapon" or hasAnyTag(item, {"Fishing", "Lure", "Rod"}) or strFind(nameLower, "fishingrod", 1, true) then
            return ItemSortingImproved.Categories.SurFish
        end
        if dispCat == "Gardening" or dispCat == "GardeningWeapon" or hasAnyTag(item, {"Farming", "Seed", "Gardening"}) then
            return ItemSortingImproved.Categories.SurFarm
        end
        if dispCat == "Tool" or dispCat == "ToolWeapon" or 
           hasAnyTag(item, {"Hammer", "Saw", "Screwdriver", "Wrench", "Crowbar", "Welding", "PipeWrench", "Sledgehammer", "Shovel"}) then
            return ItemSortingImproved.Categories.Tool
        end
        return ItemSortingImproved.Categories.WepMelee
    end
    
    if typeStr == "WeaponPart" or dispCat == "WeaponPart" then
        return ItemSortingImproved.Categories.WepPart
    end
    
    if dispCat == "Ammo" or hasAnyTag(item, {"Ammo", "Bullet", "Shell"}) or 
       containsAny(nameLower, {"bullets", "shells", "rounds", "cartridge", "ammo", "arrow", "bolt"}) then
        if containsAny(nameLower, {"magazine", "clip", "drum"}) then
            return ItemSortingImproved.Categories.WepAmmoMag
        end
        return ItemSortingImproved.Categories.WepAmmo
    end
    
    if containsAny(nameLower, {"magazine", "clip", "drummag"}) and typeStr ~= "Literature" then
        return ItemSortingImproved.Categories.WepAmmoMag
    end
    
    -- 4. CLOTHING & WEARABLES (Grouped by Body Location)
    if typeStr == "Clothing" or typeStr == "AlarmClockClothing" or #bodyLoc > 0 then
        -- Head & Face
        if containsAny(bodyLoc, {"hat", "mask", "eyes", "ears", "nose", "fullhat", "maskeyes", "maskfull", "eartop", "lefteye", "righteye"}) then
            return ItemSortingImproved.Categories.ClothHead
        end
        -- Arms & Hands
        if containsAny(bodyLoc, {"hands", "handsleft", "handsright", "rightarm", "leftarm", "forearm_right", "forearm_left"}) then
            return ItemSortingImproved.Categories.ClothArm
        end
        -- Feet & Shoes
        if containsAny(bodyLoc, {"shoes", "socks", "calf_right", "calf_left", "gaiter_left", "gaiter_right"}) then
            return ItemSortingImproved.Categories.ClothFeet
        end
        -- Legs & Lower Body
        if containsAny(bodyLoc, {"pants", "shortpants", "shortsshort", "legs1", "skirt", "longskirt", "thigh_right", "thigh_left", "pantsextra", "pants_skinny"}) then
            return ItemSortingImproved.Categories.ClothLeg
        end
        -- Underwear
        if containsAny(bodyLoc, {"underwear", "underwearbottom", "underweartop", "underwearextra1", "underwearextra2"}) then
            return ItemSortingImproved.Categories.ClothUnder
        end
        -- Jewelry
        if containsAny(bodyLoc, {"necklace", "necklace_long", "bellybutton", "right_middlefinger", "left_middlefinger", "right_ringfinger", "left_ringfinger", "rightwrist", "leftwrist"}) then
            return ItemSortingImproved.Categories.ClothJew
        end
        -- Back / Backpack
        if containsAny(bodyLoc, {"back", "satchel"}) or hasAnyTag(item, {"Backpack"}) or (containsAny(nameLower, {"bag", "backpack", "duffle"}) and canEquip == "back") then
            return ItemSortingImproved.Categories.ClothBack
        end
        -- Accessories (belts, holsters, scarves, ties)
        if containsAny(bodyLoc, {"belt", "holster", "ankleholster", "beltextra", "scarf", "tie", "tail"}) then
            return ItemSortingImproved.Categories.ClothAcc
        end
        -- Body (Shirts, jackets, vests, coats, sweaters, dresses, suits, armor)
        return ItemSortingImproved.Categories.ClothBody
    end
    
    -- 5. CONTAINERS
    if typeStr == "Container" or (item.isFluidContainer and item:isFluidContainer()) or containsAny(nameLower, {"gascan", "petrolcan"}) then
        if strFind(canEquip, "back", 1, true) or containsAny(nameLower, {"backpack", "dufflebag", "hikingbag", "alice", "schoolbag"}) then
            return ItemSortingImproved.Categories.ClothBack
        end
        if containsAny(canEquip, {"belt", "fannypack"}) or containsAny(nameLower, {"fannypack", "satchel", "purse", "pouch", "holster"}) then
            return ItemSortingImproved.Categories.ClothBag
        end
        if (item.getCanStoreWater and item:getCanStoreWater()) or dispCat == "WaterContainer" or dispCat == "Water" or 
           (item.isFluidContainer and item:isFluidContainer()) or
           containsAny(nameLower, {"bottle", "canteen", "flask", "bucket", "pot", "kettle", "gascan", "petrolcan"}) then
            return ItemSortingImproved.Categories.ContL
        end
        return ItemSortingImproved.Categories.Cont
    end
    
    -- 6. MEDICAL & FIRST AID
    if dispCat == "FirstAid" or dispCat == "FirstAidWeapon" or dispCat == "Bandage" or 
       hasAnyTag(item, {"Medical", "FirstAid", "Bandage", "Pill", "Disinfectant"}) or 
       (item.isCanBandage and item:isCanBandage()) or 
       containsAny(nameLower, {"bandage", "bandaid", "pill", "antibiotic", "painkiller", "antidepressant", "splint", "suture", "disinfectant", "scalpel"}) then
        return ItemSortingImproved.Categories.Med
    end
    
    -- 7. CLEANING SUPPLIES
    if hasAnyTag(item, {"Bleach", "Soap", "Cleaning", "Towel", "Clean"}) or 
       containsAny(nameLower, {"bleach", "soap", "mop", "dishcloth", "bathtowel", "sponge", "broom", "cleaningliquid"}) then
        return ItemSortingImproved.Categories.Clean
    end
    
    -- 8. APPEARANCE & COSMETICS
    if dispCat == "Appearance" or (item.makeUpType and #item.makeUpType > 0) or 
       containsAny(nameLower, {"makeup", "lipstick", "hairdye", "hairgel", "eyeshadow", "perfume", "cologne", "hairspray", "comb", "razor"}) then
        return ItemSortingImproved.Categories.Appear
    end
    
    -- 9. TOOLS
    if dispCat == "Tool" or dispCat == "ToolWeapon" or 
       hasAnyTag(item, {"Tool", "Hammer", "Saw", "Screwdriver", "Wrench", "PipeWrench", "Sledgehammer", "Shovel", "BlowTorch", "WeldingMask", "Crowbar"}) or
       containsAny(nameLower, {"hammer", "saw", "screwdriver", "wrench", "pipewrench", "sledgehammer", "shovel", "blowtorch", "weldingmask", "crowbar", "pliers", "scissors", "trowel"}) then
        return ItemSortingImproved.Categories.Tool
    end
    
    -- 10. BUILDING & CONSTRUCTION
    if dispCat == "Paint" or hasAnyTag(item, {"Paint"}) or containsAny(nameLower, {"paint", "wallpaper"}) then
        return ItemSortingImproved.Categories.BuildP
    end
    if containsAny(nameLower, {"log", "brick", "gravelbag", "concrete", "plaster", "hinge", "doorknob", "anvil", "sandbag", "barbedwire", "cement"}) then
        return ItemSortingImproved.Categories.Build
    end
    
    -- 11. CRAFTING MATERIALS
    if dispCat == "Material" or dispCat == "RecipeResource" or 
       hasAnyTag(item, {"Carpentry", "Metalworking", "Masonry", "Tailoring", "Crafting"}) or
       containsAny(nameLower, {"nails", "screws", "ducttape", "glue", "thread", "wire", "metalsheet", "scrapmetal", "leatherstrip", "denimstrip", "sheetmetal", "twine", "rope", "woodglue", "superglue"}) then
        return ItemSortingImproved.Categories.Craft
    end
    
    -- 12. ELECTRONICS & COMMUNICATION
    if typeStr == "Radio" or typeStr == "AlarmClock" or dispCat == "Electronics" or dispCat == "Communications" or 
       hasAnyTag(item, {"Electronics", "Radio", "Battery", "LightSource", "Flashlight"}) or
       containsAny(nameLower, {"radio", "walkietalkie", "battery", "flashlight", "lamp", "lightbulb", "hamradio", "generator", "timer", "motiondetector"}) then
        return ItemSortingImproved.Categories.Elec
    end
    
    -- 13. SURVIVAL DISCIPLINES
    if dispCat == "Fishing" or dispCat == "FishingWeapon" or hasAnyTag(item, {"Fishing", "Lure", "Rod"}) or 
       containsAny(nameLower, {"fishingrod", "fishingline", "fishinglure", "fishhook", "fishingtackle", "fishingnet"}) then
        return ItemSortingImproved.Categories.SurFish
    end
    if dispCat == "Gardening" or dispCat == "GardeningWeapon" or hasAnyTag(item, {"Farming", "Seed", "Gardening"}) or 
       containsAny(nameLower, {"seed", "wateringcan", "fertilizer", "compost", "plantgrowth"}) then
        return ItemSortingImproved.Categories.SurFarm
    end
    if dispCat == "Trapping" or hasAnyTag(item, {"Trapping", "Trap"}) or 
       containsAny(nameLower, {"trap", "mousetrap", "cagetrap", "snaretrap"}) then
        return ItemSortingImproved.Categories.SurTrap
    end
    if dispCat == "Camping" or hasAnyTag(item, {"Camping", "Tent"}) or 
       containsAny(nameLower, {"tent", "sleepingbag", "campfire", "tentpeg"}) then
        return ItemSortingImproved.Categories.SurCamp
    end
    
    -- 14. MECHANICS & VEHICLES
    if dispCat == "VehicleMaintenance" or dispCat == "VehicleMaintenanceWeapon" or hasAnyTag(item, {"Mechanic", "VehiclePart"}) or 
       containsAny(nameLower, {"tire", "muffler", "carburetor", "carengine", "carbattery", "brakes", "suspension", "gaspump", "windshield"}) then
        return ItemSortingImproved.Categories.Mech
    end
    
    -- 15. KEYS & LOCKS
    if typeStr == "Key" or typeStr == "Key_Ring" or containsAny(nameLower, {"key", "padlock", "combinationlock", "keyring"}) then
        return ItemSortingImproved.Categories.Key
    end
    
    -- 16. FURNITURE & MOVEABLES
    if typeStr == "Moveable" or dispCat == "Furniture" or containsAny(nameLower, {"chair", "table", "bed", "shelf", "sofa", "couch", "cabinet", "drawer"}) then
        return ItemSortingImproved.Categories.Furn
    end
    
    -- 17. RECORDED MEDIA & ENTERTAINMENT
    if containsAny(nameLower, {"cassette", "vinyl", "cdrom", "compactdisc", "audiobook"}) then
        return ItemSortingImproved.Categories.MediaA
    end
    if containsAny(nameLower, {"vhs", "videotape", "movie", "film"}) then
        return ItemSortingImproved.Categories.MediaV
    end
    if containsAny(nameLower, {"boardgame", "chess", "checkers", "cards", "carddeck", "dice", "yoyo", "gameboy", "videogame"}) then
        return ItemSortingImproved.Categories.MediaG
    end
    
    -- 18. FUEL & COMBUSTION
    if hasAnyTag(item, {"TakeFuel", "Fuel"}) or 
       containsAny(nameLower, {"petrol", "gasoline", "gascan", "propanetank", "charcoal", "firewood", "kindling", "lighterfluid"}) then
        return ItemSortingImproved.Categories.Fuel
    end
    
    -- 19. DRUGS & TOBACCO
    if hasAnyTag(item, {"Smoke", "Tobacco"}) or 
       containsAny(nameLower, {"cigarette", "cigar", "tobacco", "joint", "rollingpaper", "lighter", "matches"}) then
        return ItemSortingImproved.Categories.Drugs
    end
    
    -- 20. COLLECTABLES & VALUABLES
    if containsAny(nameLower, {"money", "creditcard", "plush", "spiffo", "doll", "toy", "trophy", "wallet"}) then
        return ItemSortingImproved.Categories.Collect
    end
    
    -- 21. COOKING UTENSILS & INGREDIENTS
    if dispCat == "Cooking" or containsAny(nameLower, {"pan", "pot", "roastingpan", "bakingpan", "skillet", "bowl", "rollingpin", "whisk", "grater", "kettle"}) then
        return ItemSortingImproved.Categories.Cook
    end
    if containsAny(nameLower, {"flour", "sugar", "salt", "pepper", "oil", "vinegar", "yeast", "marinara", "ketchup", "mustard", "mayonnaise"}) then
        return ItemSortingImproved.Categories.CookIng
    end
    
    -- 22. JUNK & TRASH
    if dispCat == "Junk" or containsAny(nameLower, {"empty", "tin", "canempty", "trash", "scrap", "debris", "dirt", "broken"}) then
        return ItemSortingImproved.Categories.Junk
    end
    
    -- Default fallback
    return ItemSortingImproved.Categories.Misc
end

-- Process and categorize all items loaded in ScriptManager
function ItemSortingImproved.CategorizeAllItems()
    print("[ItemSortingImproved] Categorizing all items...")
    local startTime = getTimestampMs and getTimestampMs() or 0
    
    local count = 0
    local items = ScriptManager.instance:getAllItems()
    if not items then
        print("[ItemSortingImproved] Error: ScriptManager returned nil item list!")
        return
    end
    
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            local success, err = pcall(function()
                local newCat = ItemSortingImproved.CategorizeItem(item)
                if newCat and #newCat > 0 then
                    item:DoParam("DisplayCategory", newCat)
                    count = count + 1
                end
            end)
            if not success then
                print("[ItemSortingImproved] Error processing item: " .. tostring(err))
            end
        end
    end
    
    local elapsed = (getTimestampMs and getTimestampMs() or 0) - startTime
    print(string.format("[ItemSortingImproved] Successfully categorized %d items in %d ms.", count, elapsed))
end

-- Hook into OnGameBoot to run after all vanilla and mod scripts are registered
Events.OnGameBoot.Add(ItemSortingImproved.CategorizeAllItems)
