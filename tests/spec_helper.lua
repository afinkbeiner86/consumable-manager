string.trim = function(s) return s:match("^%s*(.-)%s*$") end

-- Create Recursive Ghost Mock
-- This creates a table that returns a function for ANY key accessed.
-- That function returns the table itself, allowing for infinite chaining.
local function CreateGhost()
    local obj = {}
    local mt = {
        __index = function()
            return function() return obj end
        end
    }
    return setmetatable(obj, mt)
end

-- Define bare minimum WoW Globals
_G.UIParent = CreateGhost()
_G.SlashCmdList = {}
_G.InCombatLockdown = function() return false end
_G.GetTime = function() return 0 end
_G.UnitLevel = function() return 80 end

_G.CreateFrame = function(_, name)
    local f = CreateGhost()
    f.GetName = function() return name end
    -- Tooltip scanner loop needs a real number to not crash
    f.NumLines = function() return 0 end
    if name then _G[name] = f end
    return f
end

-- Addon Loader helper
_G.LoadAddonFile = function(path, addonName, ns)
    local chunk = assert(loadfile(path))
    return chunk(addonName, ns)
end
