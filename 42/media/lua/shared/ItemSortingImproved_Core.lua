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

-- Helper to extract all tags from an item into a fast lookup table
local function getItemTags(item)
    local tagMap = {}
    if not item or not item.getTags then return tagMap end
    local tags = item:getTags()
    if not tags or tags:isEmpty() then return tagMap end
    
    local it = tags:iterator()
    while it:hasNext() do
        local tagObj = it:next()
        if tagObj then
            local str = strLower(tostring(tagObj))
            tagMap[str] = true
            -- Also index unnamespaced tag if prefixed (e.g. "base:ammo" -> "ammo")
            local colonPos = strFind(str, ":", 1, true)
            if colonPos then
                tagMap[string.sub(str, colonPos + 1)] = true
            end
        end
    end
    return tagMap
end

-- Helper to check if item (or pre-extracted tag table) has any tag in a list
local function hasAnyTag(itemOrTags, tagList)
    if not itemOrTags or not tagList then return false end
    local tagMap = type(itemOrTags) == "table" and itemOrTags or getItemTags(itemOrTags)
    for i = 1, #tagList do
        if tagMap[strLower(tagList[i])] then
            return true
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

-- Helper to get normalized lowercase item type string (Build 42 ItemType or Build 41 getTypeString)
local function getItemTypeString(item)
    if not item then return "" end
    -- Check Build 42 itemType / getItemType()
    local itemTypeObj = (item.getItemType and item:getItemType()) or item.itemType
    if itemTypeObj then
        local str = strLower(tostring(itemTypeObj))
        local colonPos = strFind(str, ":", 1, true)
        if colonPos then
            return string.sub(str, colonPos + 1)
        end
        return str
    end
    -- Fallback to Build 41 getTypeString()
    if item.getTypeString then
        local ts = item:getTypeString()
        if ts then return strLower(ts) end
    end
    return ""
end

-- Safely get body location string (unnamespaced)
local function getBodyLocationStr(item)
    if not item then return "" end
    local loc = (item.getBodyLocation and item:getBodyLocation()) or item.bodyLocation
    if loc then
        local str = strLower(tostring(loc))
        local colonPos = strFind(str, ":", 1, true)
        if colonPos then
            return string.sub(str, colonPos + 1)
        end
        return str
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
    local typeStr = getItemTypeString(item)
    local dispCat = item.getDisplayCategory and item:getDisplayCategory() or ""
    local bodyLoc = getBodyLocationStr(item)
    local canEquipObj = (item.getCanBeEquipped and item:getCanBeEquipped()) or item.canBeEquipped
    local canEquip = ""
    if canEquipObj then
        local ceStr = strLower(tostring(canEquipObj))
        local colonPos = strFind(ceStr, ":", 1, true)
        canEquip = colonPos and string.sub(ceStr, colonPos + 1) or ceStr
    end
    local itemTags = getItemTags(item)
    
    -- Tier 2: Classification by Item Type & Functional Properties
    
    -- 1. FOOD & DRINK
    if typeStr == "food" then
        if (item.isAlcoholic and item:isAlcoholic()) or hasAnyTag(itemTags, {"Alcohol", "Beer", "Wine", "Liquor"}) then
            return ItemSortingImproved.Categories.FoodA
        end
        if (item.canStoreWater == true) or (item.getCanStoreWater and item:getCanStoreWater()) or dispCat == "Water" or 
           hasAnyTag(itemTags, {"Drink", "Water"}) or containsAny(nameLower, {"water", "soda", "juice", "milk", "coffee", "tea", "beverage"}) then
            return ItemSortingImproved.Categories.FoodB
        end
        
        local isCanned = (item.cannedFood == true) or (item.isCannedFood and item:isCannedFood()) or strFind(nameLower, "canned", 1, true)
        local cantFreeze = (item.cantBeFrozen == true) or (item.isCantBeFrozen and item:isCantBeFrozen())
        local daysRotten = item.getDaysTotallyRotten and item:getDaysTotallyRotten() or 0
        
        -- Non-perishables: canned goods, dry rations, spices, or foods that never rot
        if isCanned or cantFreeze or daysRotten <= 0 or daysRotten >= 1000000000 then
            return ItemSortingImproved.Categories.FoodN
        end
        return ItemSortingImproved.Categories.FoodP
    end
    
    -- 2. LITERATURE
    if typeStr == "literature" then
        local skill = item.getSkillTrained and item:getSkillTrained()
        if skill and #skill > 0 then
            return ItemSortingImproved.Categories.LitS
        end
        local recipes = (item.getLearnedRecipes and item:getLearnedRecipes()) or (item.getTeachedRecipes and item:getTeachedRecipes())
        if recipes and not recipes:isEmpty() then
            return ItemSortingImproved.Categories.LitR
        end
        if dispCat == "Cartography" or strFind(nameLower, "map", 1, true) then
            return ItemSortingImproved.Categories.LitC
        end
        if (item.canBeWrite == true) or (item.canWrite and item:canWrite()) or hasAnyTag(itemTags, {"Write", "Drawing"}) or 
           containsAny(nameLower, {"pencil", "pen", "notebook", "journal", "crayon", "eraser", "sheetpaper"}) then
            return ItemSortingImproved.Categories.LitW
        end
        return ItemSortingImproved.Categories.LitE
    end
    
    if typeStr == "map" or dispCat == "Cartography" or strFind(nameLower, "map", 1, true) then
        return ItemSortingImproved.Categories.LitC
    end
    
    -- 3. WEAPONS, AMMO & EXPLOSIVES
    if typeStr == "weapon" then
        if dispCat == "Explosives" or dispCat == "Devices" or hasAnyTag(itemTags, {"Explosive", "Bomb", "Trap"}) or 
           containsAny(nameLower, {"pipebomb", "molotov", "grenade", "aerosolbomb", "smokebomb"}) then
            return ItemSortingImproved.Categories.WepBomb
        end
        if hasAnyTag(itemTags, {"Bow", "Crossbow"}) or containsAny(nameLower, {"bow", "crossbow"}) then
            return ItemSortingImproved.Categories.WepBow
        end
        local isAimed = (item.isAimedFirearm == true) or (type(item.isAimedFirearm) == "function" and item:isAimedFirearm())
        local isRangedWep = (item.isRanged and item:isRanged())
        local hasGunType = item.gunType and not item.gunType:isEmpty()
        if isRangedWep or isAimed or hasGunType then
            return ItemSortingImproved.Categories.WepFire
        end
        -- Tools and survival gear that function as improvised weapons
        if dispCat == "Fishing" or dispCat == "FishingWeapon" or hasAnyTag(itemTags, {"Fishing", "Lure", "Rod"}) or strFind(nameLower, "fishingrod", 1, true) then
            return ItemSortingImproved.Categories.SurFish
        end
        if dispCat == "Gardening" or dispCat == "GardeningWeapon" or hasAnyTag(itemTags, {"Farming", "Seed", "Gardening"}) then
            return ItemSortingImproved.Categories.SurFarm
        end
        if dispCat == "Tool" or dispCat == "ToolWeapon" or 
           hasAnyTag(itemTags, {"Hammer", "Saw", "Screwdriver", "Wrench", "Crowbar", "Welding", "PipeWrench", "Sledgehammer", "Shovel"}) then
            return ItemSortingImproved.Categories.Tool
        end
        return ItemSortingImproved.Categories.WepMelee
    end
    
    if typeStr == "weapon_part" or typeStr == "weaponpart" or dispCat == "WeaponPart" then
        return ItemSortingImproved.Categories.WepPart
    end
    
    if dispCat == "Ammo" or hasAnyTag(itemTags, {"Ammo", "Bullet", "Shell"}) or 
       containsAny(nameLower, {"bullets", "shells", "rounds", "cartridge", "ammo", "arrow", "bolt"}) then
        if containsAny(nameLower, {"magazine", "clip", "drum"}) then
            return ItemSortingImproved.Categories.WepAmmoMag
        end
        return ItemSortingImproved.Categories.WepAmmo
    end
    
    if containsAny(nameLower, {"magazine", "clip", "drummag"}) and typeStr ~= "literature" then
        return ItemSortingImproved.Categories.WepAmmoMag
    end
    
    -- 4. CLOTHING & WEARABLES (Grouped by Body Location)
    if typeStr == "clothing" or typeStr == "alarm_clock_clothing" or typeStr == "alarmclockclothing" or #bodyLoc > 0 then
        -- Head & Face
        if containsAny(bodyLoc, {"hat", "mask", "eyes", "ears", "nose", "fullhat", "full_hat", "maskeyes", "mask_eyes", "maskfull", "mask_full", "eartop", "ear_top", "lefteye", "left_eye", "righteye", "right_eye"}) then
            return ItemSortingImproved.Categories.ClothHead
        end
        -- Arms & Hands
        if containsAny(bodyLoc, {"hands", "handsleft", "handsright", "rightarm", "leftarm", "forearm_right", "forearm_left", "fore_arm_right", "fore_arm_left"}) then
            return ItemSortingImproved.Categories.ClothArm
        end
        -- Feet & Shoes
        if containsAny(bodyLoc, {"shoes", "socks", "calf_right", "calf_left", "gaiter_left", "gaiter_right"}) then
            return ItemSortingImproved.Categories.ClothFeet
        end
        -- Legs & Lower Body
        if containsAny(bodyLoc, {"pants", "shortpants", "short_pants", "shortsshort", "shorts_short", "legs1", "skirt", "longskirt", "long_skirt", "thigh_right", "thigh_left", "pantsextra", "pants_extra", "pants_skinny"}) then
            return ItemSortingImproved.Categories.ClothLeg
        end
        -- Underwear
        if containsAny(bodyLoc, {"underwear", "underwearbottom", "underwear_bottom", "underweartop", "underwear_top", "underwearextra1", "underwear_extra1", "underwearextra2", "underwear_extra2"}) then
            return ItemSortingImproved.Categories.ClothUnder
        end
        -- Jewelry
        if containsAny(bodyLoc, {"necklace", "necklace_long", "bellybutton", "right_middlefinger", "left_middlefinger", "right_middle_finger", "left_middle_finger", "right_ringfinger", "left_ringfinger", "right_ring_finger", "left_ring_finger", "rightwrist", "leftwrist", "right_wrist", "left_wrist"}) then
            return ItemSortingImproved.Categories.ClothJew
        end
        -- Back / Backpack
        if containsAny(bodyLoc, {"back", "satchel"}) or hasAnyTag(itemTags, {"Backpack"}) or (containsAny(nameLower, {"bag", "backpack", "duffle"}) and canEquip == "back") then
            return ItemSortingImproved.Categories.ClothBack
        end
        -- Accessories (belts, holsters, scarves, ties)
        if containsAny(bodyLoc, {"belt", "holster", "ankleholster", "shoulder_holster", "beltextra", "scarf", "tie", "tail"}) then
            return ItemSortingImproved.Categories.ClothAcc
        end
        -- Body (Shirts, jackets, vests, coats, sweaters, dresses, suits, armor)
        return ItemSortingImproved.Categories.ClothBody
    end
    
    -- 5. CONTAINERS
    local isFluidCont = (ComponentType and ComponentType.FluidContainer and item.containsComponent and item:containsComponent(ComponentType.FluidContainer)) or
                        (item.isFluidContainer and item:isFluidContainer())
    if typeStr == "container" or isFluidCont or containsAny(nameLower, {"gascan", "petrolcan"}) then
        if strFind(canEquip, "back", 1, true) or containsAny(nameLower, {"backpack", "dufflebag", "hikingbag", "alice", "schoolbag"}) then
            return ItemSortingImproved.Categories.ClothBack
        end
        if containsAny(canEquip, {"belt", "fannypack"}) or containsAny(nameLower, {"fannypack", "satchel", "purse", "pouch", "holster"}) then
            return ItemSortingImproved.Categories.ClothBag
        end
        if (item.canStoreWater == true) or (item.getCanStoreWater and item:getCanStoreWater()) or dispCat == "WaterContainer" or dispCat == "Water" or 
           isFluidCont or
           containsAny(nameLower, {"bottle", "canteen", "flask", "bucket", "pot", "kettle", "gascan", "petrolcan"}) then
            return ItemSortingImproved.Categories.ContL
        end
        return ItemSortingImproved.Categories.Cont
    end
    
    -- 6. MEDICAL & FIRST AID
    if dispCat == "FirstAid" or dispCat == "FirstAidWeapon" or dispCat == "Bandage" or 
       hasAnyTag(itemTags, {"Medical", "FirstAid", "Bandage", "Pill", "Disinfectant"}) or 
       (item.isCanBandage and item:isCanBandage()) or 
       containsAny(nameLower, {"bandage", "bandaid", "pill", "antibiotic", "painkiller", "antidepressant", "splint", "suture", "disinfectant", "scalpel"}) then
        return ItemSortingImproved.Categories.Med
    end
    
    -- 7. CLEANING SUPPLIES
    if hasAnyTag(itemTags, {"Bleach", "Soap", "Cleaning", "Towel", "Clean"}) or 
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
       hasAnyTag(itemTags, {"Tool", "Hammer", "Saw", "Screwdriver", "Wrench", "PipeWrench", "Sledgehammer", "Shovel", "BlowTorch", "WeldingMask", "Crowbar"}) or
       containsAny(nameLower, {"hammer", "saw", "screwdriver", "wrench", "pipewrench", "sledgehammer", "shovel", "blowtorch", "weldingmask", "crowbar", "pliers", "scissors", "trowel"}) then
        return ItemSortingImproved.Categories.Tool
    end
    
    -- 10. BUILDING & CONSTRUCTION
    if dispCat == "Paint" or hasAnyTag(itemTags, {"Paint"}) or containsAny(nameLower, {"paint", "wallpaper"}) then
        return ItemSortingImproved.Categories.BuildP
    end
    if containsAny(nameLower, {"log", "brick", "gravelbag", "concrete", "plaster", "hinge", "doorknob", "anvil", "sandbag", "barbedwire", "cement"}) then
        return ItemSortingImproved.Categories.Build
    end
    
    -- 11. CRAFTING MATERIALS
    if dispCat == "Material" or dispCat == "RecipeResource" or 
       hasAnyTag(itemTags, {"Carpentry", "Metalworking", "Masonry", "Tailoring", "Crafting"}) or
       containsAny(nameLower, {"nails", "screws", "ducttape", "glue", "thread", "wire", "metalsheet", "scrapmetal", "leatherstrip", "denimstrip", "sheetmetal", "twine", "rope", "woodglue", "superglue"}) then
        return ItemSortingImproved.Categories.Craft
    end
    
    -- 12. ELECTRONICS & COMMUNICATION
    if typeStr == "radio" or typeStr == "alarmclock" or typeStr == "alarm_clock" or dispCat == "Electronics" or dispCat == "Communications" or 
       hasAnyTag(itemTags, {"Electronics", "Radio", "Battery", "LightSource", "Flashlight"}) or
       containsAny(nameLower, {"radio", "walkietalkie", "battery", "flashlight", "lamp", "lightbulb", "hamradio", "generator", "timer", "motiondetector"}) then
        return ItemSortingImproved.Categories.Elec
    end
    
    -- 13. SURVIVAL DISCIPLINES
    if dispCat == "Fishing" or dispCat == "FishingWeapon" or hasAnyTag(itemTags, {"Fishing", "Lure", "Rod"}) or 
       containsAny(nameLower, {"fishingrod", "fishingline", "fishinglure", "fishhook", "fishingtackle", "fishingnet"}) then
        return ItemSortingImproved.Categories.SurFish
    end
    if dispCat == "Gardening" or dispCat == "GardeningWeapon" or hasAnyTag(itemTags, {"Farming", "Seed", "Gardening"}) or 
       containsAny(nameLower, {"seed", "wateringcan", "fertilizer", "compost", "plantgrowth"}) then
        return ItemSortingImproved.Categories.SurFarm
    end
    if dispCat == "Trapping" or hasAnyTag(itemTags, {"Trapping", "Trap"}) or 
       containsAny(nameLower, {"trap", "mousetrap", "cagetrap", "snaretrap"}) then
        return ItemSortingImproved.Categories.SurTrap
    end
    if dispCat == "Camping" or hasAnyTag(itemTags, {"Camping", "Tent"}) or 
       containsAny(nameLower, {"tent", "sleepingbag", "campfire", "tentpeg"}) then
        return ItemSortingImproved.Categories.SurCamp
    end
    
    -- 14. MECHANICS & VEHICLES
    if dispCat == "VehicleMaintenance" or dispCat == "VehicleMaintenanceWeapon" or hasAnyTag(itemTags, {"Mechanic", "VehiclePart"}) or 
       containsAny(nameLower, {"tire", "muffler", "carburetor", "carengine", "carbattery", "brakes", "suspension", "gaspump", "windshield"}) then
        return ItemSortingImproved.Categories.Mech
    end
    
    -- 15. KEYS & LOCKS
    if typeStr == "key" or typeStr == "key_ring" or typeStr == "keyring" or containsAny(nameLower, {"key", "padlock", "combinationlock", "keyring"}) then
        return ItemSortingImproved.Categories.Key
    end
    
    -- 16. FURNITURE & MOVEABLES
    if typeStr == "moveable" or dispCat == "Furniture" or containsAny(nameLower, {"chair", "table", "bed", "shelf", "sofa", "couch", "cabinet", "drawer"}) then
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
    if hasAnyTag(itemTags, {"TakeFuel", "Fuel"}) or 
       containsAny(nameLower, {"petrol", "gasoline", "gascan", "propanetank", "charcoal", "firewood", "kindling", "lighterfluid"}) then
        return ItemSortingImproved.Categories.Fuel
    end
    
    -- 19. DRUGS & TOBACCO
    if hasAnyTag(itemTags, {"Smoke", "Tobacco"}) or 
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
