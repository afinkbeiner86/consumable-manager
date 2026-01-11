-- luacheck: globals LoadAddonFile
require("tests.spec_helper")

describe("ConsumableManager Addon", function()
    local addonName = "ConsumableManager"
    local ns = {}

    setup(function()
        LoadAddonFile("Data.lua", addonName, ns)
        LoadAddonFile("ConsumableManager.lua", addonName, ns)
    end)

    it("should load the database into the namespace", function()
        assert.is_not_nil(ns.KNOWN_CONSUMABLES)
    end)

    it("should handle slash commands without crashing", function()
        _G.ConsumableManagerDB = { isLocked = false }
        _G.SlashCmdList.CM("lock")
        assert.is_true(_G.ConsumableManagerDB.isLocked)
    end)
end)
