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

-- Cache string lower and find functions for speed
local strLower = string.lower
local strFind  = string.find

-------------------------------------------------------------------------------
-- Static Lookup Tables & Keyword Sets (Zero-Garbage Boot Allocation)
-------------------------------------------------------------------------------
local TAGS_DRUGS             = { "smoke", "tobacco", "smokable" }
local WORDS_DRUGS            = { "cigarette", "cigar", "tobacco", "joint", "rollingpaper", "lighter", "matches" }

local TAGS_MEDICAL           = { "medical", "firstaid", "bandage", "pill", "disinfectant" }
local WORDS_MEDICAL          = { "bandage", "bandaid", "pill", "antibiotic", "painkiller", "antidepressant", "splint", "suture", "disinfectant", "scalpel" }

local TAGS_FARMING           = { "farming", "seed", "gardening", "farming_loot" }
local WORDS_FARMING          = { "wateringcan", "fertilizer", "compost", "plantgrowth" }

local TAGS_COOK_ING          = { "minoringredient", "sugar", "salt", "flour", "yeast", "bakingfat", "bakingpowder" }
local WORDS_COOK_ING         = { "flour", "sugar", "salt", "pepper", "oilolive", "oilvegetable", "vegetableoil", "oliveoil", "cookingoil", "vinegar", "yeast", "cornmeal", "bakingsoda", "cocoapowder", "marinara", "ketchup", "mustard", "mayonnaise", "syrup", "honey" }

local TAGS_ALCOHOL           = { "alcohol", "beer", "wine", "liquor" }
local TAGS_DRINK             = { "drink", "water", "wetbeverageingredient" }
local WORDS_DRINK            = { "water", "soda", "juice", "milk", "coffee", "tea", "beverage", "popcan" }
local WORDS_NOT_DRINK        = { "soup", "stew", "cereal", "oatmeal", "pasta", "chili", "chowder", "broth" }

local TAGS_FUEL              = { "takefuel", "charcoal", "lighterfluid" }
local WORDS_FUEL             = { "propanetank", "charcoal", "firewood", "kindling", "lighterfluid", "coalbag" }

local TAGS_WRITE             = { "write", "drawing" }
local WORDS_WRITE            = { "pencil", "penspiffo", "penfancy", "penmulticolor", "bluepen", "greenpen", "redpen", "notebook", "journal", "crayon", "eraser", "sheetpaper" }

local TAGS_BOMB              = { "explosive", "bomb", "trap" }
local WORDS_BOMB             = { "pipebomb", "molotov", "grenade", "aerosolbomb", "smokebomb" }

local TAGS_BOW               = { "bow", "crossbow" }
local WORDS_BOW              = { "crossbow", "woodenbow", "compoundbow", "recurvebow" }

local TAGS_TOOL              = { "tool", "hammer", "saw", "screwdriver", "wrench", "pipewrench", "sledgehammer", "shovel", "blowtorch", "weldingmask", "crowbar", "pliers", "scissors", "trowel", "chisel", "needle" }
local WORDS_TOOL             = { "hammer", "saw", "screwdriver", "wrench", "pipewrench", "sledgehammer", "shovel", "blowtorch", "weldingmask", "crowbar", "pliers", "scissors", "trowel" }

local TAGS_AMMO              = { "ammo", "bullet", "shell" }
local WORDS_AMMO             = { "bullets", "shells", "rounds", "cartridge", "ammo", "arrow", "bolt" }
local WORDS_MAGAZINE         = { "magazine", "clip", "drummag" }
local WORDS_MAGAZINE_EXCLUDE = { "paperclip", "clipboard", "recipeclipping" }

local LOCS_HEAD              = { "hat", "mask", "eyes", "ears", "nose", "fullhat", "full_hat", "maskeyes", "mask_eyes", "maskfull", "mask_full", "eartop", "ear_top", "lefteye", "left_eye", "righteye", "right_eye" }
local LOCS_ARM               = { "hands", "handsleft", "handsright", "rightarm", "leftarm", "forearm_right", "forearm_left", "fore_arm_right", "fore_arm_left" }
local LOCS_FEET              = { "shoes", "socks", "calf_right", "calf_left", "gaiter_left", "gaiter_right" }
local LOCS_LEG               = { "pants", "shortpants", "short_pants", "shortsshort", "shorts_short", "legs1", "skirt", "longskirt", "long_skirt", "thigh_right", "thigh_left", "pantsextra", "pants_extra", "pants_skinny", "groin" }
local LOCS_UNDER             = { "underwear", "underwearbottom", "underwear_bottom", "underweartop", "underwear_top", "underwearextra1", "underwear_extra1", "underwearextra2", "underwear_extra2" }
local LOCS_JEW               = { "necklace", "necklace_long", "bellybutton", "right_middlefinger", "left_middlefinger", "right_middle_finger", "left_middle_finger", "right_ringfinger", "left_ringfinger", "right_ring_finger", "left_ring_finger", "rightwrist", "leftwrist", "right_wrist", "left_wrist", "ears_piercing" }
local LOCS_BACK              = { "back", "satchel" }
local LOCS_ACC               = { "belt", "holster", "ankleholster", "shoulder_holster", "beltextra", "scarf", "tie", "tail", "badge" }

local WORDS_BACKPACK         = { "backpack", "dufflebag", "hikingbag", "alice", "schoolbag" }
local WORDS_BAG              = { "fannypack", "satchel", "purse", "pouch" }
local WORDS_LIQUID_CONT      = { "bottle", "canteen", "flask", "bucket", "kettle", "gascan", "petrolcan", "dispenserbottle" }

local TAGS_CLEAN             = { "bleach", "soap", "cleaning", "towel", "clean" }
local WORDS_CLEAN            = { "bleach", "soap", "mop", "dishcloth", "bathtowel", "sponge", "broom", "cleaningliquid" }

local WORDS_APPEAR           = { "makeup", "lipstick", "hairdye", "hairgel", "eyeshadow", "perfume", "cologne", "hairspray", "comb", "razor" }

local TAGS_BUILD_P           = { "paint", "wallpaper" }
local WORDS_BUILD_P          = { "paint", "wallpaper" }
local WORDS_BUILD            = { "brick", "gravelbag", "concrete", "plaster", "hinge", "doorknob", "anvil", "sandbag", "barbedwire", "cement" }

local TAGS_CRAFT             = { "carpentry", "metalworking", "masonry", "tailoring", "crafting" }
local WORDS_CRAFT            = { "nails", "screws", "ducttape", "glue", "thread", "wire", "metalsheet", "scrapmetal", "leatherstrip", "denimstrip", "sheetmetal", "twine", "rope", "woodglue", "superglue" }

local TAGS_MECH              = { "mechanic", "vehiclepart" }
local WORDS_MECH             = { "tire", "muffler", "carburetor", "carengine", "carbattery", "brakes", "suspension", "gaspump", "windshield" }

local TAGS_ELEC              = { "electronics", "radio", "battery", "lightsource", "flashlight" }
local WORDS_ELEC             = { "radio", "walkietalkie", "battery", "flashlight", "lamp", "lightbulb", "hamradio", "generator", "timer", "motiondetector" }

local TAGS_FISHING           = { "fishing", "lure", "rod" }
local WORDS_FISHING          = { "fishingrod", "fishingline", "fishinglure", "fishhook", "fishingtackle", "fishingnet" }

local TAGS_TRAPPING          = { "trapping", "trap" }
local WORDS_TRAPPING         = { "trap", "mousetrap", "cagetrap", "snaretrap" }

local TAGS_CAMPING           = { "camping", "tent" }
local WORDS_CAMPING          = { "tent", "sleepingbag", "campfire", "tentpeg" }

local WORDS_KEY              = { "key", "padlock", "combinationlock", "keyring" }
local WORDS_FURN             = { "chair", "table", "bed", "shelf", "sofa", "couch", "cabinet", "drawer", "desk", "wardrobe" }

local WORDS_MEDIA_A          = { "cassette", "vinyl", "cdrom", "compactdisc", "audiobook" }
local WORDS_MEDIA_V          = { "vhs", "videotape", "movie", "film" }
local WORDS_MEDIA_G          = { "boardgame", "chess", "checkers", "carddeck", "dice", "yoyo", "gameboy", "videogame" }

local TAGS_COLLECT           = { "is_memento" }
local WORDS_COLLECT          = { "money", "creditcard", "plush", "spiffo", "doll", "trophy", "wallet" }

local WORDS_COOK_UTENSIL     = { "fryingpan", "saucepan", "cookingpot", "roastingpan", "bakingpan", "skillet", "bowl", "rollingpin", "whisk", "grater", "kettle" }
local WORDS_JUNK             = { "empty", "tin", "canempty", "trash", "scrap", "debris", "dirt", "broken" }

-------------------------------------------------------------------------------
-- Helper Functions
-------------------------------------------------------------------------------

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

-- Helper to check if tag lookup table has any tag in a list
local function hasAnyTag(tagMap, tagList)
    if not tagMap or not tagList then return false end
    for i = 1, #tagList do
        if tagMap[tagList[i]] then
            return true
        end
    end
    return false
end

-- Helper to check if any needle substring is present in haystack string
local function containsAny(haystack, needles)
    if not haystack or not needles then return false end
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
    local itemTypeObj = (item.getItemType and item:getItemType()) or item.itemType
    if itemTypeObj then
        local str = strLower(tostring(itemTypeObj))
        local colonPos = strFind(str, ":", 1, true)
        if colonPos then
            return string.sub(str, colonPos + 1)
        end
        return str
    end
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

-------------------------------------------------------------------------------
-- Core Categorization Engine
-------------------------------------------------------------------------------
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
    local isHidden = (item.isHidden and item:isHidden()) or (item.hidden == true)
    
    -- Tier 1.5: Exclude internal zombie wound & cosmetic damage layers
    if isHidden or dispCat == "ZedDmg" or dispCat == "Wound" or bodyLoc == "zeddmg" or bodyLoc == "wound" or
       strFind(nameLower, "zeddmg_", 1, true) or strFind(nameLower, "wound_", 1, true) then
        return ItemSortingImproved.Categories.Misc
    end
    
    -- Tier 2: Classification by Functional Priority
    
    -- 1. DRUGS & TOBACCO (Evaluated before generic Food to intercept cigars/cigarettes/tobacco)
    if hasAnyTag(itemTags, TAGS_DRUGS) or containsAny(nameLower, WORDS_DRUGS) then
        return ItemSortingImproved.Categories.Drugs
    end
    
    -- 2. MEDICAL & FIRST AID (Evaluated before Food to intercept medicinal herbs & ingestible medicine)
    if dispCat == "FirstAid" or dispCat == "FirstAidWeapon" or dispCat == "Bandage" or 
       hasAnyTag(itemTags, TAGS_MEDICAL) or 
       (item.isCanBandage and item:isCanBandage()) or 
       containsAny(nameLower, WORDS_MEDICAL) then
        return ItemSortingImproved.Categories.Med
    end
    
    -- 3. FARMING & SEEDS (Evaluated before Literature & Food to intercept seed packets)
    if dispCat == "Gardening" or dispCat == "GardeningWeapon" or 
       hasAnyTag(itemTags, TAGS_FARMING) or 
       strFind(nameLower, "seed", 1, true) or 
       containsAny(nameLower, WORDS_FARMING) then
        return ItemSortingImproved.Categories.SurFarm
    end
    
    -- 4. COOKING INGREDIENTS (Evaluated before generic Food to intercept spices, flour, sugar, oils)
    if hasAnyTag(itemTags, TAGS_COOK_ING) or containsAny(nameLower, WORDS_COOK_ING) then
        return ItemSortingImproved.Categories.CookIng
    end
    
    -- 5. FOOD & DRINK
    if typeStr == "food" or dispCat == "Food" then
        if (item.isAlcoholic and item:isAlcoholic()) or hasAnyTag(itemTags, TAGS_ALCOHOL) then
            return ItemSortingImproved.Categories.FoodA
        end
        local isSoupOrMeal = containsAny(nameLower, WORDS_NOT_DRINK)
        if not isSoupOrMeal then
            if (item.canStoreWater == true) or (item.getCanStoreWater and item:getCanStoreWater()) or dispCat == "Water" or 
               hasAnyTag(itemTags, TAGS_DRINK) or containsAny(nameLower, WORDS_DRINK) then
                return ItemSortingImproved.Categories.FoodB
            end
        end
        
        local isCanned = (item.cannedFood == true) or (item.isCannedFood and item:isCannedFood()) or strFind(nameLower, "canned", 1, true)
        local cantFreeze = (item.cantBeFrozen == true) or (item.isCantBeFrozen and item:isCantBeFrozen())
        local daysRotten = item.getDaysTotallyRotten and item:getDaysTotallyRotten() or 0
        
        -- Non-perishables: canned goods, dry rations, or foods that never rot
        if isCanned or cantFreeze or daysRotten <= 0 or daysRotten >= 1000000000 then
            return ItemSortingImproved.Categories.FoodN
        end
        return ItemSortingImproved.Categories.FoodP
    end
    
    -- 6. FUEL & COMBUSTION (Evaluated before Crafting & Weapons to intercept charcoal, firewood, propane tanks)
    if (hasAnyTag(itemTags, TAGS_FUEL) or containsAny(nameLower, WORDS_FUEL)) and not strFind(nameLower, "nails", 1, true) then
        return ItemSortingImproved.Categories.Fuel
    end
    
    -- 7. LITERATURE
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
        if (item.canBeWrite == true) or (item.canWrite and item:canWrite()) or hasAnyTag(itemTags, TAGS_WRITE) or 
           containsAny(nameLower, WORDS_WRITE) or nameLower == "pen" then
            return ItemSortingImproved.Categories.LitW
        end
        return ItemSortingImproved.Categories.LitE
    end
    
    if typeStr == "map" or dispCat == "Cartography" or strFind(nameLower, "map", 1, true) then
        return ItemSortingImproved.Categories.LitC
    end
    
    -- 8. WEAPONS, AMMO & EXPLOSIVES
    if typeStr == "weapon" then
        if dispCat == "Explosives" or dispCat == "Devices" or hasAnyTag(itemTags, TAGS_BOMB) or 
           containsAny(nameLower, WORDS_BOMB) then
            return ItemSortingImproved.Categories.WepBomb
        end
        if hasAnyTag(itemTags, TAGS_BOW) or containsAny(nameLower, WORDS_BOW) or nameLower == "bow" then
            return ItemSortingImproved.Categories.WepBow
        end
        local isAimed = (item.isAimedFirearm == true) or (type(item.isAimedFirearm) == "function" and item:isAimedFirearm())
        local isRangedWep = (item.isRanged and item:isRanged())
        local hasGunType = item.gunType and not item.gunType:isEmpty()
        if isRangedWep or isAimed or hasGunType then
            return ItemSortingImproved.Categories.WepFire
        end
        -- Improvised tools and survival gear functioning as weapons
        if dispCat == "Fishing" or dispCat == "FishingWeapon" or hasAnyTag(itemTags, TAGS_FISHING) or strFind(nameLower, "fishingrod", 1, true) then
            return ItemSortingImproved.Categories.SurFish
        end
        if dispCat == "Gardening" or dispCat == "GardeningWeapon" or hasAnyTag(itemTags, TAGS_FARMING) then
            return ItemSortingImproved.Categories.SurFarm
        end
        if dispCat == "Tool" or dispCat == "ToolWeapon" or hasAnyTag(itemTags, TAGS_TOOL) then
            return ItemSortingImproved.Categories.Tool
        end
        return ItemSortingImproved.Categories.WepMelee
    end
    
    if typeStr == "weapon_part" or typeStr == "weaponpart" or dispCat == "WeaponPart" then
        return ItemSortingImproved.Categories.WepPart
    end
    
    if dispCat == "Ammo" or hasAnyTag(itemTags, TAGS_AMMO) or containsAny(nameLower, WORDS_AMMO) then
        if containsAny(nameLower, WORDS_MAGAZINE) and not containsAny(nameLower, WORDS_MAGAZINE_EXCLUDE) then
            return ItemSortingImproved.Categories.WepAmmoMag
        end
        return ItemSortingImproved.Categories.WepAmmo
    end
    
    if containsAny(nameLower, WORDS_MAGAZINE) and not containsAny(nameLower, WORDS_MAGAZINE_EXCLUDE) and typeStr ~= "literature" then
        return ItemSortingImproved.Categories.WepAmmoMag
    end
    
    -- 9. CLOTHING & WEARABLES (Grouped by Body Location)
    if typeStr == "clothing" or typeStr == "alarm_clock_clothing" or typeStr == "alarmclockclothing" or #bodyLoc > 0 then
        if containsAny(bodyLoc, LOCS_HEAD) then
            return ItemSortingImproved.Categories.ClothHead
        end
        if containsAny(bodyLoc, LOCS_ARM) then
            return ItemSortingImproved.Categories.ClothArm
        end
        if containsAny(bodyLoc, LOCS_FEET) then
            return ItemSortingImproved.Categories.ClothFeet
        end
        if containsAny(bodyLoc, LOCS_LEG) then
            return ItemSortingImproved.Categories.ClothLeg
        end
        if containsAny(bodyLoc, LOCS_UNDER) then
            return ItemSortingImproved.Categories.ClothUnder
        end
        if containsAny(bodyLoc, LOCS_JEW) then
            return ItemSortingImproved.Categories.ClothJew
        end
        if containsAny(bodyLoc, LOCS_BACK) or hasAnyTag(itemTags, {"backpack"}) or (strFind(nameLower, "bag", 1, true) and canEquip == "back") then
            return ItemSortingImproved.Categories.ClothBack
        end
        if containsAny(bodyLoc, LOCS_ACC) then
            return ItemSortingImproved.Categories.ClothAcc
        end
        return ItemSortingImproved.Categories.ClothBody
    end
    
    -- 10. CONTAINERS
    local isFluidCont = (ComponentType and ComponentType.FluidContainer and item.containsComponent and item:containsComponent(ComponentType.FluidContainer)) or
                        (item.isFluidContainer and item:isFluidContainer()) or (dispCat == "WaterContainer")
    if typeStr == "container" or dispCat == "WaterContainer" or dispCat == "Container" or isFluidCont or containsAny(nameLower, {"gascan", "petrolcan"}) then
        if strFind(canEquip, "back", 1, true) or containsAny(nameLower, WORDS_BACKPACK) then
            return ItemSortingImproved.Categories.ClothBack
        end
        if containsAny(canEquip, {"belt", "fannypack"}) or containsAny(nameLower, WORDS_BAG) then
            return ItemSortingImproved.Categories.ClothBag
        end
        if (item.canStoreWater == true) or (item.getCanStoreWater and item:getCanStoreWater()) or dispCat == "WaterContainer" or dispCat == "Water" or 
           isFluidCont or containsAny(nameLower, WORDS_LIQUID_CONT) then
            return ItemSortingImproved.Categories.ContL
        end
        return ItemSortingImproved.Categories.Cont
    end
    
    -- 11. CLEANING SUPPLIES
    if hasAnyTag(itemTags, TAGS_CLEAN) or containsAny(nameLower, WORDS_CLEAN) then
        return ItemSortingImproved.Categories.Clean
    end
    
    -- 12. APPEARANCE & COSMETICS
    if dispCat == "Appearance" or (item.makeUpType and #item.makeUpType > 0) or containsAny(nameLower, WORDS_APPEAR) then
        return ItemSortingImproved.Categories.Appear
    end
    
    -- 13. TOOLS
    if dispCat == "Tool" or dispCat == "ToolWeapon" or hasAnyTag(itemTags, TAGS_TOOL) or containsAny(nameLower, WORDS_TOOL) then
        return ItemSortingImproved.Categories.Tool
    end
    
    -- 14. BUILDING & CONSTRUCTION
    if dispCat == "Paint" or hasAnyTag(itemTags, TAGS_BUILD_P) or containsAny(nameLower, WORDS_BUILD_P) then
        return ItemSortingImproved.Categories.BuildP
    end
    if nameLower == "log" or strFind(nameLower, "logstacks", 1, true) or strFind(nameLower, "treelog", 1, true) or strFind(nameLower, "woodenlog", 1, true) or 
       containsAny(nameLower, WORDS_BUILD) then
        return ItemSortingImproved.Categories.Build
    end
    
    -- 15. CRAFTING MATERIALS
    if dispCat == "Material" or dispCat == "RecipeResource" or hasAnyTag(itemTags, TAGS_CRAFT) or containsAny(nameLower, WORDS_CRAFT) then
        return ItemSortingImproved.Categories.Craft
    end
    
    -- 16. MECHANICS & VEHICLES (Evaluated before Electronics so car batteries belong to Mech)
    if dispCat == "VehicleMaintenance" or dispCat == "VehicleMaintenanceWeapon" or hasAnyTag(itemTags, TAGS_MECH) or containsAny(nameLower, WORDS_MECH) then
        return ItemSortingImproved.Categories.Mech
    end
    
    -- 17. ELECTRONICS & COMMUNICATION
    if typeStr == "radio" or typeStr == "alarmclock" or typeStr == "alarm_clock" or dispCat == "Electronics" or dispCat == "Communications" or dispCat == "LightSource" or 
       hasAnyTag(itemTags, TAGS_ELEC) or containsAny(nameLower, WORDS_ELEC) then
        return ItemSortingImproved.Categories.Elec
    end
    
    -- 18. SURVIVAL DISCIPLINES
    if dispCat == "Fishing" or dispCat == "FishingWeapon" or hasAnyTag(itemTags, TAGS_FISHING) or containsAny(nameLower, WORDS_FISHING) then
        return ItemSortingImproved.Categories.SurFish
    end
    if dispCat == "Trapping" or hasAnyTag(itemTags, TAGS_TRAPPING) or containsAny(nameLower, WORDS_TRAPPING) then
        return ItemSortingImproved.Categories.SurTrap
    end
    if dispCat == "Camping" or hasAnyTag(itemTags, TAGS_CAMPING) or containsAny(nameLower, WORDS_CAMPING) then
        return ItemSortingImproved.Categories.SurCamp
    end
    
    -- 19. KEYS & LOCKS
    if typeStr == "key" or typeStr == "key_ring" or typeStr == "keyring" or containsAny(nameLower, WORDS_KEY) then
        return ItemSortingImproved.Categories.Key
    end
    
    -- 20. FURNITURE & MOVEABLES
    if typeStr == "moveable" or dispCat == "Furniture" or containsAny(nameLower, WORDS_FURN) then
        return ItemSortingImproved.Categories.Furn
    end
    
    -- 21. RECORDED MEDIA & ENTERTAINMENT
    if containsAny(nameLower, WORDS_MEDIA_A) then
        return ItemSortingImproved.Categories.MediaA
    end
    if containsAny(nameLower, WORDS_MEDIA_V) then
        return ItemSortingImproved.Categories.MediaV
    end
    if containsAny(nameLower, WORDS_MEDIA_G) then
        return ItemSortingImproved.Categories.MediaG
    end
    
    -- 22. COLLECTABLES & VALUABLES
    if dispCat == "Memento" or hasAnyTag(itemTags, TAGS_COLLECT) or containsAny(nameLower, WORDS_COLLECT) then
        return ItemSortingImproved.Categories.Collect
    end
    
    -- 23. COOKING UTENSILS
    if dispCat == "Cooking" or containsAny(nameLower, WORDS_COOK_UTENSIL) or nameLower == "pan" or nameLower == "pot" then
        return ItemSortingImproved.Categories.Cook
    end
    
    -- 24. JUNK & TRASH
    if dispCat == "Junk" or containsAny(nameLower, WORDS_JUNK) then
        return ItemSortingImproved.Categories.Junk
    end
    
    -- Default fallback
    return ItemSortingImproved.Categories.Misc
end

-------------------------------------------------------------------------------
-- Engine Execution & Safe Boot Hook
-------------------------------------------------------------------------------

-- Process and categorize all items loaded in ScriptManager
function ItemSortingImproved.CategorizeAllItems()
    -- Guard: Dedicated servers must not modify displayCategory to preserve ItemPickerJava loot tables
    if isServer and isServer() then
        print("[ItemSortingImproved] Running on dedicated server; skipping displayCategory modification to preserve ItemPickerJava loot tables.")
        return
    end

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
                    -- Preserve vanilla loot-table categories before altering DisplayCategory
                    local oldDispCat = item.getDisplayCategory and item:getDisplayCategory() or ""
                    if oldDispCat == "FirstAid" or oldDispCat == "FirstAidWeapon" then
                        item:DoParam("Medical", "true")
                    end
                    if oldDispCat == "VehicleMaintenance" or oldDispCat == "VehicleMaintenanceWeapon" then
                        item:DoParam("MechanicsItem", "true")
                    end
                    if oldDispCat == "Fishing" or oldDispCat == "FishingWeapon" or oldDispCat == "Trapping" or oldDispCat == "Camping" or oldDispCat == "FireSource" then
                        item:DoParam("SurvivalGear", "true")
                    end
                    if oldDispCat == "Gardening" or oldDispCat == "GardeningWeapon" then
                        if ItemTag and ItemTag.FARMING_LOOT and item.getTags then
                            pcall(function() item:getTags():add(ItemTag.FARMING_LOOT) end)
                        end
                    end
                    if oldDispCat == "Memento" then
                        if ItemTag and ItemTag.IS_MEMENTO and item.getTags then
                            pcall(function() item:getTags():add(ItemTag.IS_MEMENTO) end)
                        end
                    end

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
