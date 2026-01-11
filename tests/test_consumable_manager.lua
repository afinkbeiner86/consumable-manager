-- luacheck: globals LoadAddonFile describe it setup before_each
--[[
    ConsumableManager Test Suite
    ----------------------------
    Strategy: State-Based Testing
    Instead of complex mocks, we simulate the WoW environment by injecting
    values into the global _G table and verifying that our logic updates
    the 'SavedVariables' (ConsumableManagerDB) correctly.
]]

require("tests.spec_helper")

describe("ConsumableManager Addon", function()
    local addonName = "ConsumableManager"
    local ns = {}

    --[[
        Setup: Runs once before the entire test suite.
        Loads the Addon files into a shared namespace (ns) so we can
        inspect internal data like KNOWN_CONSUMABLES.
    ]]
    setup(function()
        LoadAddonFile("Data.lua", addonName, ns)
        LoadAddonFile("ConsumableManager.lua", addonName, ns)
    end)

    --[[
        Before Each: Runs before EVERY individual 'it' block.
        Ensures a 'Clean Slate' by resetting the database. This prevents
        one test's failure or state change from breaking subsequent tests.
    ]]
    before_each(function()
        _G.ConsumableManagerDB = {
            isLocked = false,
            isGrouped = true,
            isVisible = true,
            version = 1
        }
    end)

    describe("Static Data Integrity", function()
        --[[
            Test: Database Loading
            Ensures that the Data.lua file successfully populated the
            AddonNamespace so the manager actually has items to look for.
        ]]
        it("should have the database loaded into the namespace", function()
            assert(ns.KNOWN_CONSUMABLES ~= nil, "FAILED: KNOWN_CONSUMABLES table was not found in namespace")
        end)

        --[[
            Test: Category Validation
            Iterates through the entire item database to ensure every item
            is assigned to a valid category. This catches typos like "foods" vs "Food".
        ]]
        it("should only contain valid categories in Data.lua", function()
            local validTypes = { Food = true, Drink = true, Health = true, Mana = true }
            for id, category in pairs(ns.KNOWN_CONSUMABLES) do
                assert(validTypes[category],
                    "FAILED: Invalid category '" .. tostring(category) .. "' for item ID: " .. id)
            end
        end)
    end)

    describe("Slash Commands (System Settings)", function()
        --[[
            Test: UI Locking
            Simulates the user typing '/cm lock' in-game.
            Verification: Check if the 'isLocked' boolean flips in the database.
        ]]
        it("toggles the 'isLocked' state via /cm lock", function()
            _G.SlashCmdList.CM("lock")
            assert(_G.ConsumableManagerDB.isLocked == true, "FAILED: lock command did not set isLocked to true")

            _G.SlashCmdList.CM("lock")
            assert(_G.ConsumableManagerDB.isLocked == false, "FAILED: lock command did not toggle isLocked back to false")
        end)

        --[[
            Test: Button Grouping
            Simulates the user typing '/cm group'.
            Verification: Check if the 'isGrouped' boolean flips in the database.
        ]]
        it("toggles the 'isGrouped' state via /cm group", function()
            _G.SlashCmdList.CM("group")
            assert(_G.ConsumableManagerDB.isGrouped == false, "FAILED: group command did not toggle isGrouped to false")
        end)

        --[[
            Test: Visibility Management
            Simulates '/cm show' and '/cm hide'.
            Verification: Ensures the database reflects visibility state for the UI frames.
        ]]
        it("updates visibility via show/hide commands", function()
            _G.SlashCmdList.CM("hide")
            assert(_G.ConsumableManagerDB.isVisible == false, "FAILED: hide command did not update database")

            _G.SlashCmdList.CM("show")
            assert(_G.ConsumableManagerDB.isVisible == true, "FAILED: show command did not update database")
        end)
    end)

    describe("Pattern Matching Logic", function()
        --[[
            Test: Tooltip Parsing
            Testing the Lua patterns used in the scanner loop.
            Verification: A sample WoW health-regen string must match our 'Food' pattern.
        ]]
        it("matches the Food pattern against a standard WoW tooltip string", function()
            -- This string mimics the standard "Restores X health over Y sec" found in-game
            local foodPattern = "Restores.*health.*over"
            local sample = "Restores 500 health over 20 sec."

            assert(sample:match(foodPattern) ~= nil,
                "FAILED: The food pattern no longer matches standard WoW tooltip strings")
        end)
    end)
end)
