--[[
    Item Sorting Improved - Fluid Dynamic Categorization
    Build 42 Compatible
    
    Dynamically updates fluid container categories based on contents:
      - Water / Soda / Milk -> FoodB (Food - Beverage)
      - Beer / Wine / Bourbon -> FoodA (Food - Alcohol)
      - Bleach / Cleaning Liquid -> Clean (Cleaning)
      - Gasoline / Petrol -> Fuel (Fuel)
      - Hair Dye -> Appear (Appearance)
      - Paint -> BuildP (Building - Paint)
      - Empty container -> ContL (Container - Liquid)
]]

ItemSortingImproved = ItemSortingImproved or {}

function ItemSortingImproved.GetFluidCategory(item)
    if not item then return nil end
    
    -- Check if item is a fluid container
    local container = item.getFluidContainer and item:getFluidContainer()
    if not container or container:isEmpty() then
        return "ContL"
    end
    
    local fluid = container:getPrimaryFluid()
    if not fluid then
        return "ContL"
    end
    
    -- Use FluidCategory enum if available in Build 42
    if FluidCategory then
        if fluid:isCategory(FluidCategory.Alcoholic) then
            return "FoodA"
        elseif fluid:isCategory(FluidCategory.Beverage) or fluid:isCategory(FluidCategory.Water) then
            return "FoodB"
        elseif fluid:isCategory(FluidCategory.Fuel) then
            return "Fuel"
        elseif fluid:isCategory(FluidCategory.HairDyes) then
            return "Appear"
        elseif fluid:isCategory(FluidCategory.Paint) then
            return "BuildP"
        elseif fluid:isCategory(FluidCategory.Medical) then
            return "Med"
        end
    end
    
    -- Fallback by fluid type string
    local fType = fluid.getFluidTypeString and fluid:getFluidTypeString()
    if fType then
        if fType == "Bleach" or fType == "CleaningLiquid" then
            return "Clean"
        elseif fType == "Petrol" or fType == "Gasoline" then
            return "Fuel"
        elseif fType == "HairDye" then
            return "Appear"
        elseif fType == "Water" then
            return "FoodB"
        elseif fType == "Beer" or fType == "Wine" or fType == "Bourbon" or fType == "Whiskey" then
            return "FoodA"
        end
    end
    
    return "ContL"
end

function ItemSortingImproved.UpdateFluidItem(item)
    if not item or not item.setDisplayCategory then return end
    if item.isFluidContainer and item:isFluidContainer() then
        local newCat = ItemSortingImproved.GetFluidCategory(item)
        if newCat then
            item:setDisplayCategory(newCat)
        end
    end
end

function ItemSortingImproved.UpdateContainerFluids(container)
    if not container then return end
    local items = container:getAllEvalRecurse(function(it)
        return it.isFluidContainer and it:isFluidContainer()
    end)
    if items then
        for i = 0, items:size() - 1 do
            ItemSortingImproved.UpdateFluidItem(items:get(i))
        end
    end
end

