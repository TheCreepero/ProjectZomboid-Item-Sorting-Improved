--[[
    Item Sorting Improved - Custom Overrides Table
    Build 42 Compatible
    
    This table allows modders and players to explicitly override the auto-categorization
    for any specific item full type (e.g., "Base.Axe", "MyMod.SpecialWidget").
    
    Usage:
        ItemSortingImproved.Overrides["Module.ItemType"] = "CategoryKey"
        
    Example:
        ItemSortingImproved.Overrides["Base.Apple"] = "FoodP"
        ItemSortingImproved.Overrides["MyMod.PlasmaRifle"] = "WepFire"
]]

ItemSortingImproved = ItemSortingImproved or {}
ItemSortingImproved.Overrides = ItemSortingImproved.Overrides or {}

-- Pre-configured specific edge-case overrides if needed
-- (Most items are automatically handled by ItemSortingImproved_Core.lua)
ItemSortingImproved.Overrides["Base.Wallet"] = "ClothAcc"
ItemSortingImproved.Overrides["Base.Wallet2"] = "ClothAcc"
ItemSortingImproved.Overrides["Base.Wallet3"] = "ClothAcc"
ItemSortingImproved.Overrides["Base.Wallet4"] = "ClothAcc"
ItemSortingImproved.Overrides["Base.CreditCard"] = "Collect"
ItemSortingImproved.Overrides["Base.Money"] = "Collect"
ItemSortingImproved.Overrides["Base.Yoyo"] = "MediaG"
ItemSortingImproved.Overrides["Base.Dice"] = "MediaG"
ItemSortingImproved.Overrides["Base.Cards"] = "MediaG"
ItemSortingImproved.Overrides["Base.Spiffo"] = "Collect"
ItemSortingImproved.Overrides["Base.FluffyBfc"] = "Collect"
ItemSortingImproved.Overrides["Base.FreddyFox"] = "Collect"
ItemSortingImproved.Overrides["Base.JacquesBeaver"] = "Collect"
ItemSortingImproved.Overrides["Base.MoleyMole"] = "Collect"
ItemSortingImproved.Overrides["Base.PancakeHedgehog"] = "Collect"

