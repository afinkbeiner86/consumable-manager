-- Global options
local_by_default = false
max_line_length = false

-- 1. Standard WoW Globals & Your Addon Globals
globals = {
    -- WoW API
    "UIParent", "GameTooltip", "DEFAULT_CHAT_FRAME", "SlashCmdList", "SLASH_CM1",
    "CreateFrame", "UIFrameFadeIn", "UIFrameFadeOut", "GetTime", "InCombatLockdown",
    "UnitLevel", "GetContainerNumSlots", "GetContainerItemLink", "GetContainerItemInfo",
    "GetItemInfo", "GetItemCooldown", "GetBindingKey", "IsAltKeyDown", "ReloadUI",
    "InterfaceOptions_AddCategory", "InterfaceOptionsFrame_OpenToCategory",
    "C_Timer", "wipe",

    -- Your Addon Globals
    "ConsumableManagerDB", "CM", "CMAnchorFrame", "CMFoodButton",

    -- Test Environment Globals
    "LoadAddonFile", "string.trim"
}

-- 2. Ignore specific mutation warnings for the string table
-- 113: Accessing undefined field (trim)
-- 143: Mutating a standard library table (string)
ignore = {
    "113/string",
    "143/string",
}

-- 3. Busted Globals for the tests directory
files["tests/*.lua"] = {
    globals = {
        "describe", "it", "setup", "teardown", "before_each", "after_each", "assert"
    }
}
