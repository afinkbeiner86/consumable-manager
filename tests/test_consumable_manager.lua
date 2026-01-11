-- luacheck: globals LoadAddonFile describe it setup before_each
require("tests.spec_helper")

describe("ConsumableManager Addon", function()
    local addonName = "ConsumableManager"
    local ns = {}

    setup(function()
        LoadAddonFile("Data.lua", addonName, ns)
        LoadAddonFile("ConsumableManager.lua", addonName, ns)
    end)

    before_each(function()
        -- Reset state to ensure tests are isolated
        _G.ConsumableManagerDB = {
            isLocked = false,
            isGrouped = true,
            isVisible = true,
            version = 1
        }
    end)

    describe("Static Data Integrity", function()
        it("should have the database loaded into the namespace", function()
            assert(ns.KNOWN_CONSUMABLES ~= nil, "Database missing")
        end)

        it("should only contain valid categories in Data.lua", function()
            local validTypes = { Food = true, Drink = true, Health = true, Mana = true }
            for id, category in pairs(ns.KNOWN_CONSUMABLES) do
                assert(validTypes[category], "Invalid category for ID: " .. id)
            end
        end)
    end)

    describe("Slash Commands", function()
        it("toggles the 'isLocked' state via /cm lock", function()
            _G.SlashCmdList.CM("lock")
            assert(_G.ConsumableManagerDB.isLocked == true, "Lock failed")
            _G.SlashCmdList.CM("lock")
            assert(_G.ConsumableManagerDB.isLocked == false, "Unlock failed")
        end)

        it("toggles the 'isGrouped' state via /cm group", function()
            _G.SlashCmdList.CM("group")
            assert(_G.ConsumableManagerDB.isGrouped == false, "Ungroup failed")
        end)

        it("updates visibility via show/hide commands", function()
            _G.SlashCmdList.CM("hide")
            assert(_G.ConsumableManagerDB.isVisible == false, "Hide failed")
            _G.SlashCmdList.CM("show")
            assert(_G.ConsumableManagerDB.isVisible == true, "Show failed")
        end)
    end)

    describe("Pattern Matching", function()
        it("matches the Food pattern against a standard WoW tooltip", function()
            local foodPattern = "Restores.*health.*over"
            local sample = "Restores 500 health over 20 sec."
            assert(sample:match(foodPattern) ~= nil, "Pattern mismatch")
        end)
    end)
end)
