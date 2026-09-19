--[[
    Item Sorting Improved - Client Actions & Inventory Hooks
    Build 42 Compatible
    
    Listens for container refresh and fluid transfer/consumption timed actions
    to ensure fluid container display categories reflect their live contents.
]]

require("ItemSortingImproved_FluidCategories")

local function hookTimedActions()
    if ItemSortingImproved._hooksInstalled then return end
    ItemSortingImproved._hooksInstalled = true

    -- 1. Fluid Empty Action
    if ISFluidEmptyAction then
        local original_complete = ISFluidEmptyAction.complete
        function ISFluidEmptyAction:complete()
            local res = original_complete(self)
            if self.container and self.container.getOwner then
                ItemSortingImproved.UpdateFluidItem(self.container:getOwner())
            end
            return res
        end
    end

    -- 2. Drink Fluid Action
    if ISDrinkFluidAction then
        local original_complete = ISDrinkFluidAction.complete
        function ISDrinkFluidAction:complete()
            local res = original_complete(self)
            if self.item then
                ItemSortingImproved.UpdateFluidItem(self.item)
            end
            return res
        end
    end

    -- 3. Drink From Bottle
    if ISDrinkFromBottle then
        local original_complete = ISDrinkFromBottle.complete
        function ISDrinkFromBottle:complete()
            local res = original_complete(self)
            if self.item then
                ItemSortingImproved.UpdateFluidItem(self.item)
            end
            return res
        end
    end

    -- 4. Fluid Transfer Action
    if ISFluidTransferAction then
        local original_complete = ISFluidTransferAction.complete
        function ISFluidTransferAction:complete()
            local res = original_complete(self)
            if self.sourceOwner then
                ItemSortingImproved.UpdateFluidItem(self.sourceOwner)
            end
            if self.targetOwner then
                ItemSortingImproved.UpdateFluidItem(self.targetOwner)
            end
            return res
        end
    end

    -- 5. Take Fuel Action
    if ISTakeFuel then
        local original_complete = ISTakeFuel.complete
        function ISTakeFuel:complete()
            local res = original_complete(self)
            if self.petrolCan then
                ItemSortingImproved.UpdateFluidItem(self.petrolCan)
            end
            return res
        end
    end

    -- 6. Take Water Action
    if ISTakeWaterAction then
        local original_complete = ISTakeWaterAction.complete
        function ISTakeWaterAction:complete()
            local res = original_complete(self)
            if self.item then
                ItemSortingImproved.UpdateFluidItem(self.item)
            end
            return res
        end
    end
end

-- Hook inventory window container refresh
Events.OnRefreshInventoryWindowContainers.Add(function(inventoryPage, reason)
    if reason ~= "end" or not inventoryPage or not inventoryPage.backpacks then return end
    for _, button in ipairs(inventoryPage.backpacks) do
        if button.inventory then
            ItemSortingImproved.UpdateContainerFluids(button.inventory)
        end
    end
end)

-- Hook initial player inventory load and timed action patches
Events.OnGameStart.Add(function()
    hookTimedActions()
    local player = getPlayer()
    if player and player:getInventory() then
        ItemSortingImproved.UpdateContainerFluids(player:getInventory())
    end
end)

