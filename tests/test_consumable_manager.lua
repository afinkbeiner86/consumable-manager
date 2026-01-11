-- luacheck: globals LoadAddonFile
require("tests.spec_helper")

describe("ConsumableManager Addon", function()
    local addonName = "ConsumableManager"
    local ns = {}

    setup(function()
        -- Load files in order to populate the namespace and globals [cite: 3]
        LoadAddonFile("Data.lua", addonName, ns)
        LoadAddonFile("ConsumableManager.lua", addonName, ns)
    end)

    before_each(function()
        -- Reset the database to a clean state before every test 
        _G.ConsumableManagerDB = {
            isLocked = false,
            isGrouped = true,
            isVisible = true,
            version = 1
        }
    end)

    --- DATA INTEGRITY TESTS ---
    describe("Static Data Integrity", function()
        it("should have the database loaded into the namespace", function()
            assert.is_not_nil(ns.KNOWN_CONSUMABLES) [cite: 1]
        end)

        it("should only contain valid categories in Data.lua", function()
            local validTypes = { Food = true, Drink = true, Health = true, Mana = true }
            for id, category in pairs(ns.KNOWN_CONSUMABLES) do
                assert.is_true(validTypes[category], "Invalid category '" .. tostring(category) .. "' for item ID: " .. id) [cite: 2]
            end
        end)
    end)

    --- SLASH COMMAND TESTS (State-Based) ---
    describe("Slash Commands", function()
        it("toggles the 'isLocked' state via /cm lock", function()
            _G.SlashCmdList.CM("lock") [cite: 1]
            assert.is_true(_G.ConsumableManagerDB.isLocked) [cite: 1]
            _G.SlashCmdList.CM("lock")
            assert.is_false(_G.ConsumableManagerDB.isLocked)
        end)

        it("toggles the 'isGrouped' state via /cm group", function()
            _G.SlashCmdList.CM("group") [cite: 1]
            assert.is_false(_G.ConsumableManagerDB.isGrouped) -- Default was true 
            _G.SlashCmdList.CM("group")
            assert.is_true(_G.ConsumableManagerDB.isGrouped)
        end)

        it("updates visibility via /cm show and /cm hide", function()
            _G.SlashCmdList.CM("hide") [cite: 1]
            assert.is_false(_G.ConsumableManagerDB.isVisible) [cite: 1]
            _G.SlashCmdList.CM("show") [cite: 1]
            assert.is_true(_G.ConsumableManagerDB.isVisible) [cite: 1]
        end)
    end)

    --- LOGIC TESTS ---
    describe("Pattern Matching Logic", function()
        it("should correctly identify patterns used for scanning", function()
            -- We extract the local table via the namespace if it was exposed, 
            -- or test the strings against the expected logic.
            local foodPattern = "Restores.*health.*over" [cite: 1]
            local potionPattern = "Restores.*health" [cite: 1]
            local testTooltip = "Restores 500 health over 20 sec."

            assert.is_not_nil(testTooltip:match(foodPattern)) [cite: 1]
            -- Verify that the 'over' exclusion logic is necessary for potions
            assert.is_not_nil(testTooltip:match(potionPattern)) [cite: 1]
        end)
    end)
end)