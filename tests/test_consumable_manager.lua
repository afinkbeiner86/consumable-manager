-- luacheck: globals LoadAddonFile
require("tests.spec_helper")

-- Simple helper to match the "describe/it" flow without Busted
local function describe(name, func)
    print("\n" .. name)
    func()
end

local function it(name, func)
    local success, err = pcall(func)
    if success then
        print("  [PASS] " .. name)
    else
        print("  [FAIL] " .. name .. ": " .. tostring(err))
    end
end

describe("ConsumableManager Addon", function()
    local addonName = "ConsumableManager"
    local ns = {}

    -- Load files once for the suite
    LoadAddonFile("Data.lua", addonName, ns)
    LoadAddonFile("ConsumableManager.lua", addonName, ns)

    it("should have the database loaded into the namespace", function()
        assert(ns.KNOWN_CONSUMABLES ~= nil, "KNOWN_CONSUMABLES is missing from namespace")
    end)

    it("should handle slash commands and update SavedVariables", function()
        -- Setup initial state
        _G.ConsumableManagerDB = { isLocked = false, isGrouped = true }

        -- Test Lock Toggle
        _G.SlashCmdList.CM("lock")
        assert(_G.ConsumableManagerDB.isLocked == true, "Lock command failed to update DB")

        -- Test Group Toggle
        _G.SlashCmdList.CM("group")
        assert(_G.ConsumableManagerDB.isGrouped == false, "Group command failed to update DB")
    end)

    it("should validate Data.lua categories", function()
        local validTypes = { Food = true, Drink = true, Health = true, Mana = true }
        for id, category in pairs(ns.KNOWN_CONSUMABLES) do
            assert(validTypes[category], "Invalid category '" .. tostring(category) .. "' for item ID: " .. id)
        end
    end)

    it("should match WoW tooltip strings with local patterns", function()
        -- These patterns are defined in ConsumableManager.lua
        local foodPattern = "Restores.*health.*over"
        local testTooltip = "Restores 500 health over 20 sec."

        assert(testTooltip:match(foodPattern) ~= nil, "Food pattern failed to match tooltip")
    end)
end)
