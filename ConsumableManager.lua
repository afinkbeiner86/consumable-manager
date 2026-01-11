--------------------------------------------------------------------------------
-- ConsumableManager
-- Version: 2.8.0
-- Purpose: Automatically identifies and buttons the best Food, Drink, and Potions in bags.
-- Author: Achim Finkbeiner
--
-- Technical Note: This addon uses "Secure Action Buttons." These frames cannot
-- be modified (shown/hidden/moved/re-attributed) while the player is in combat.
--------------------------------------------------------------------------------

local addonName, AddonNamespace = ...
local KNOWN_CONSUMABLES = AddonNamespace.KNOWN_CONSUMABLES
local EventFrame = CreateFrame("Frame", addonName)

-- Cache frequently used API calls for performance
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local GetContainerNumSlots = GetContainerNumSlots
local GetContainerItemLink = GetContainerItemLink
local GetContainerItemInfo = GetContainerItemInfo
local GetItemInfo = GetItemInfo
local GetItemCooldown = GetItemCooldown
local UnitLevel = UnitLevel
local GetBindingKey = GetBindingKey

-- Configuration constants
local SCAN_THROTTLE = 0.5
local CACHE_MAX_SIZE = 500
local INIT_DELAY = 0.1

--[[ Global Binding Strings
     These allow the WoW Keybindings menu to display readable names for our actions.
     Format: BINDING_NAME_CLICK [ButtonName]:[MouseButton]
]]
_G["BINDING_HEADER_CONSUMABLEMANAGER"] = "Consumable Manager"
_G["BINDING_NAME_CLICK CMFoodButton:LeftButton"] = "Eat Food"
_G["BINDING_NAME_CLICK CMDrinkButton:LeftButton"] = "Drink Water"
_G["BINDING_NAME_CLICK CMHealthButton:LeftButton"] = "Health Potion"
_G["BINDING_NAME_CLICK CMManaButton:LeftButton"] = "Mana Potion"

--[[ Consumable Definitions
     pattern: The string to look for in the item tooltip.
     exclude: A string that, if found, invalidates the match (e.g., Potion 'Restores health' but we exclude 'over' to avoid bandages).
     sortOrder: Horizontal placement in the group (0 to 3).
]]
local CONSUMABLE_TYPES = {
    Food   = { pattern = "Restores.*health.*over", icon = "INV_Misc_Food_59", sortOrder = 0 },
    Drink  = { pattern = "Restores.*mana.*over", icon = "INV_Drink_07", sortOrder = 1 },
    Health = { pattern = "Restores.*health", exclude = "over", icon = "INV_Potion_54", sortOrder = 2 },
    Mana   = { pattern = "Restores.*mana", exclude = "over", icon = "INV_Potion_76", sortOrder = 3 }
}

-- Cache item IDs so we don't re-scan tooltips for every bag update.
local ItemTypeCache = {}
local lastScanTime, isUpdatePending = 0, false
local combatQueue = {}

-- Hidden Tooltip used to "read" item descriptions programmatically.
local TooltipScanner = CreateFrame("GameTooltip", "CMScanner", nil, "GameTooltipTemplate")
TooltipScanner:SetOwner(UIParent, "ANCHOR_NONE")

-- The Parent Anchor: Used to move all buttons as a single unit when Grouped.
local MainAnchorFrame = CreateFrame("Frame", "CMAnchorFrame", UIParent)
MainAnchorFrame:SetSize(160, 40)
MainAnchorFrame:SetClampedToScreen(true)

-- Keybind abbreviation lookup table
local BIND_ABBREV = {
    ["SHIFT%-"] = "s-",
    ["CTRL%-"] = "c-",
    ["ALT%-"] = "a-",
    ["BUTTON"] = "B",
    ["NUMPAD"] = "N"
}

--------------------------------------------------------------------------------
-- Forward Declarations
--------------------------------------------------------------------------------
local RefreshLockState
local RefreshButtonPositions
local UpdateConsumableDisplay
local CreateConfigMenu
local InitializeButtons
local DisplayAddonStatus

--------------------------------------------------------------------------------
-- Movement & Locking Helpers
--------------------------------------------------------------------------------

--- Updates the interactivity of frames based on the current Lock status.
RefreshLockState = function()
    if not ConsumableManagerDB then return end

    local isLocked = ConsumableManagerDB.isLocked
    local canMove = not isLocked

    -- Enable/Disable mouse dragging on the main anchor
    MainAnchorFrame:SetMovable(canMove)
    MainAnchorFrame:EnableMouse(canMove)

    -- Apply movement settings to individual buttons
    for _, typeData in pairs(CONSUMABLE_TYPES) do
        if typeData.button then
            typeData.button:SetMovable(canMove)
            -- Only allow Left-Click dragging if the UI is unlocked
            typeData.button:RegisterForDrag(canMove and "LeftButton" or nil)
        end
    end
end

--- Handles the visual arrangement of buttons (Grouped or Individual).
RefreshButtonPositions = function()
    if not ConsumableManagerDB or not CONSUMABLE_TYPES.Food.button then return end

    local buttonSize, padding = 36, 6
    local totalWidth = (buttonSize * 4) + (padding * 3)
    -- Calculate start position so the group is perfectly centered on the anchor
    local startOffset = -(totalWidth / 2) + (buttonSize / 2)

    for key, typeData in pairs(CONSUMABLE_TYPES) do
        local button = typeData.button
        if button then
            button:ClearAllPoints()

            if ConsumableManagerDB.isGrouped then
                -- Attach button to the MainAnchorFrame
                button:SetParent(MainAnchorFrame)
                button:SetPoint("CENTER", MainAnchorFrame, "CENTER",
                    startOffset + (buttonSize + padding) * typeData.sortOrder, 0)
            else
                -- Attach button directly to UIParent for individual placement
                button:SetParent(UIParent)
                local savedPos = ConsumableManagerDB[key]
                if savedPos and savedPos.point then
                    button:SetPoint(savedPos.point, UIParent, savedPos.relativePoint, savedPos.x, savedPos.y)
                else
                    -- Default position if no individual data exists
                    button:SetPoint("CENTER", UIParent, "CENTER",
                        startOffset + (buttonSize + padding) * typeData.sortOrder, 0)
                end
            end
        end
    end
    RefreshLockState()
end

--------------------------------------------------------------------------------
-- Inventory Scanning Logic
--------------------------------------------------------------------------------

--- Scans bags for the highest-level consumables and updates button attributes.
UpdateConsumableDisplay = function()
    -- Combat Guard: Secure attributes cannot be changed while in combat
    if not CONSUMABLE_TYPES.Food.button or InCombatLockdown() then
        if InCombatLockdown() then
            isUpdatePending = true
        end
        return
    end

    -- Throttle updates
    local currentTime = GetTime()
    if (currentTime - lastScanTime) < SCAN_THROTTLE then
        isUpdatePending = true
        return
    end

    lastScanTime, isUpdatePending = currentTime, false

    -- Initialize best items tracking
    local bestItemsFound = {}
    for typeKey in pairs(CONSUMABLE_TYPES) do
        bestItemsFound[typeKey] = { level = -1, id = 0, count = 0 }
    end

    -- Track items found in bags for cache pruning
    local foundItems = {}
    local playerLevel = UnitLevel("player")
    local cacheSize = 0

    -- Single pass through all bags (0-4) and slots
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local itemId = tonumber(itemLink:match("item:(%d+)"))

                -- Safety check for itemId extraction
                if itemId then
                    foundItems[itemId] = true

                    -- Check known consumables database first (fastest path)
                    local assignedType = KNOWN_CONSUMABLES[itemId]

                    -- If not in known database, check cache
                    if not assignedType then
                        assignedType = ItemTypeCache[itemId]
                    end

                    -- If still unknown, scan tooltip
                    if not assignedType then
                        TooltipScanner:ClearLines()
                        TooltipScanner:SetBagItem(bag, slot)

                        local foundMatch = false
                        for i = 1, TooltipScanner:NumLines() do
                            local lineText = _G["CMScannerTextLeft" .. i]:GetText()
                            if lineText then
                                for typeKey, typeData in pairs(CONSUMABLE_TYPES) do
                                    -- Check pattern match first (most common case)
                                    if lineText:match(typeData.pattern) then
                                        -- Only check exclusion if pattern matched
                                        if not typeData.exclude or not lineText:match(typeData.exclude) then
                                            ItemTypeCache[itemId] = typeKey
                                            assignedType = typeKey
                                            foundMatch = true
                                            break
                                        end
                                    end
                                end
                                if foundMatch then break end
                            end
                        end

                        -- Mark as scanned even if no match found
                        if not foundMatch then
                            ItemTypeCache[itemId] = "NONE"
                        end
                    end

                    -- Compare this item against the "Best" found so far for its category
                    if assignedType and assignedType ~= "NONE" then
                        local _, itemCount = GetContainerItemInfo(bag, slot)

                        -- Single GetItemInfo call - get everything we need at once
                        local itemName, _, _, itemLvl, itemMinLevel, _, _, _, _, itemTexture = GetItemInfo(itemLink)

                        -- Safety checks
                        itemLvl = itemLvl or 0
                        itemMinLevel = itemMinLevel or 0
                        itemCount = itemCount or 1

                        -- Proceed if player level meets item requirement
                        if playerLevel >= itemMinLevel then
                            local currentBest = bestItemsFound[assignedType]

                            if itemLvl > currentBest.level then
                                -- New best item found
                                currentBest.level = itemLvl
                                currentBest.id = itemId
                                currentBest.name = itemName
                                currentBest.texture = itemTexture
                                currentBest.bag = bag
                                currentBest.slot = slot
                                currentBest.count = itemCount
                            elseif itemLvl == currentBest.level and itemId == currentBest.id then
                                -- Same item in different stack - add to count
                                currentBest.count = currentBest.count + itemCount
                            end
                        end
                    end
                end
            end
        end
    end

    -- Prune cache of items no longer in bags
    for itemId in pairs(ItemTypeCache) do
        if not foundItems[itemId] then
            ItemTypeCache[itemId] = nil
        else
            cacheSize = cacheSize + 1
        end
    end

    -- Emergency cache cleanup if it grows too large
    if cacheSize > CACHE_MAX_SIZE then
        ItemTypeCache = {}
    end

    -- Update Secure Attributes and Visuals
    for typeKey, typeData in pairs(CONSUMABLE_TYPES) do
        local btn = typeData.button
        if btn then
            local itemData = bestItemsFound[typeKey]

            if itemData.name then
                -- Apply the actual item usage logic
                btn.icon:SetTexture(itemData.texture)
                btn.countText:SetText(itemData.count > 1 and itemData.count or "")
                btn:SetAttribute("type", "item")
                btn:SetAttribute("item", itemData.name)

                -- Store itemId for tooltip
                btn.itemId = itemData.id

                -- Update Cooldown UI using item ID (more reliable than bag/slot)
                local start, duration = GetItemCooldown(itemData.id)
                if start and duration and duration > 0 then
                    btn.cooldown:SetCooldown(start, duration)
                else
                    btn.cooldown:Hide()
                end
            else
                -- Visual indicator for "No Items Found"
                btn.icon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
                btn.countText:SetText("")
                btn:SetAttribute("type", nil)

                -- Clear itemId so tooltip doesn't show
                btn.itemId = nil
            end
            btn:SetShown(ConsumableManagerDB.isVisible)

            -- Keybind Formatting using lookup table
            local bind = GetBindingKey("CLICK " .. btn:GetName() .. ":LeftButton")
            if bind then
                for pattern, replacement in pairs(BIND_ABBREV) do
                    bind = bind:gsub(pattern, replacement)
                end
                btn.hotkeyText:SetText(bind)
            else
                btn.hotkeyText:SetText("")
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Configuration Panel (GUI)
--------------------------------------------------------------------------------

CreateConfigMenu = function()
    -- Create a panel for the Interface Options
    local panel = CreateFrame("Frame", "ConsumableManagerConfigPanel", UIParent)
    panel.name = "Consumable Manager"

    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Consumable Manager Settings")

    -- Description
    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText("Configure display, layout, and behavior options.")

    -- Helper to create checkboxes with unique names
    local function CreateCheckbox(name, label, key, tooltipText, relativeTo, x, y, onClickFunc)
        local cb = CreateFrame("CheckButton", name, panel, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", relativeTo, "BOTTOMLEFT", x, y)

        local text = _G[cb:GetName() .. "Text"]
        if text then text:SetText(label) end

        cb.tooltipText = tooltipText

        -- OnShow: Set the checked state based on DB
        cb:SetScript("OnShow", function(self)
            if ConsumableManagerDB then
                self:SetChecked(ConsumableManagerDB[key])
            end
        end)

        -- OnClick: Update DB and run any callback
        cb:SetScript("OnClick", function(self)
            local isChecked = self:GetChecked()
            if ConsumableManagerDB then
                ConsumableManagerDB[key] = isChecked
            end
            if onClickFunc then onClickFunc(isChecked) end
        end)

        return cb
    end

    -- 1. Visibility Checkbox
    local showCb = CreateCheckbox(
        "CMConfigCheckShow",
        "Show Buttons",
        "isVisible",
        "Toggle the visibility of all consumable buttons.",
        desc, 0, -20,
        function() UpdateConsumableDisplay() end
    )

    -- 2. Lock Checkbox
    local lockCb = CreateCheckbox(
        "CMConfigCheckLock",
        "Lock Buttons",
        "isLocked",
        "Prevent buttons from being dragged.",
        showCb, 0, -10,
        function() RefreshLockState() end
    )

    -- 3. Group Mode Checkbox
    local groupCb = CreateCheckbox(
        "CMConfigCheckGroup",
        "Group Buttons",
        "isGrouped",
        "If checked, buttons move as a single unit.\nIf unchecked, you can move them individually (requires Unlock).",
        lockCb, 0, -10,
        function() RefreshButtonPositions() end
    )

    -- Reset Button
    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 25)
    resetBtn:SetPoint("TOPLEFT", groupCb, "BOTTOMLEFT", 0, -30)
    resetBtn:SetText("Reset Defaults")
    resetBtn:SetScript("OnClick", function()
        ConsumableManagerDB = nil
        ReloadUI()
    end)

    -- Register the panel with the WoW Interface Options
    InterfaceOptions_AddCategory(panel)

    return panel
end

--------------------------------------------------------------------------------
-- Frame Construction
--------------------------------------------------------------------------------

--- Creates the Secure Buttons and sets up their appearance/scripts.
InitializeButtons = function()
    -- Ensure SavedVariables table exists with defaults
    if not ConsumableManagerDB or type(ConsumableManagerDB) ~= "table" or next(ConsumableManagerDB) == nil then
        ConsumableManagerDB = {
            version = 1,
            isVisible = true,
            isLocked = false,
            isGrouped = true,
            Anchor = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0 }
        }
    end

    -- Version migration (for future use)
    if not ConsumableManagerDB.version then
        ConsumableManagerDB.version = 1
    end

    -- Build the Config Menu
    CreateConfigMenu()

    -- Position the Main Anchor based on saved coordinates
    local anchorPos = ConsumableManagerDB.Anchor or { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0 }
    MainAnchorFrame:ClearAllPoints()
    MainAnchorFrame:SetPoint(anchorPos.point, UIParent, anchorPos.relativePoint, anchorPos.x, anchorPos.y)

    for typeKey, typeData in pairs(CONSUMABLE_TYPES) do
        local buttonName = "CM" .. typeKey .. "Button"
        -- Use SecureActionButtonTemplate to allow item usage during combat
        local btn = CreateFrame("Button", buttonName, UIParent, "SecureActionButtonTemplate")
        btn:SetSize(36, 36)
        btn:EnableMouse(true)
        btn:RegisterForClicks("AnyUp")

        -- Icon Texture
        btn.icon = btn:CreateTexture(nil, "BACKGROUND")
        btn.icon:SetAllPoints()

        -- Cooldown Spiral
        btn.cooldown = CreateFrame("Cooldown", buttonName .. "Cooldown", btn, "CooldownFrameTemplate")
        btn.cooldown:SetAllPoints()

        -- Stack Count Text
        btn.countText = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        btn.countText:SetPoint("BOTTOMRIGHT", -2, 2)

        -- Hotkey Indicator
        btn.hotkeyText = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray")
        btn.hotkeyText:SetPoint("TOPRIGHT", -1, -2)

        -- Tooltip on hover
        btn:SetScript("OnEnter", function(self)
            if self.itemId then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink("item:" .. self.itemId)
                GameTooltip:Show()
            end
        end)

        btn:SetScript("OnLeave", function(_)
            GameTooltip:Hide()
        end)

        -- Frame Dragging Scripts
        btn:SetScript("OnDragStart", function(self)
            if ConsumableManagerDB.isLocked then return end
            if ConsumableManagerDB.isGrouped then
                MainAnchorFrame:StartMoving()
            elseif IsAltKeyDown() then
                self:StartMoving()
            end
        end)

        btn:SetScript("OnDragStop", function(self)
            MainAnchorFrame:StopMovingOrSizing()
            self:StopMovingOrSizing()

            -- Save coordinates immediately upon releasing the mouse
            if ConsumableManagerDB.isGrouped then
                local point, _, relPoint, x, y = MainAnchorFrame:GetPoint()
                ConsumableManagerDB.Anchor = { point = point, relativePoint = relPoint, x = x, y = y }
            else
                local point, _, relPoint, x, y = self:GetPoint()
                ConsumableManagerDB[typeKey] = { point = point, relativePoint = relPoint, x = x, y = y }
            end
        end)

        typeData.button = btn
    end

    RefreshButtonPositions()
end

--------------------------------------------------------------------------------
-- Help, Status & Commands
--------------------------------------------------------------------------------

DisplayAddonStatus = function()
    local function HexColor(text, hex) return "|cff" .. hex .. text .. "|r" end
    local title = HexColor("Consumable Manager", "00ff00")
    local version = HexColor("v2.8.0", "888888")

    print("--------------------------------------------------")
    print(title .. " " .. version)

    -- 1. Settings Section
    print(HexColor(" [Settings]", "ffff00"))
    local groupMode = ConsumableManagerDB.isGrouped and HexColor("Grouped", "00ffff") or HexColor("Individual", "ffaa00")
    local lockState = ConsumableManagerDB.isLocked and HexColor("Locked", "ff0000") or HexColor("Unlocked", "00ff00")
    local visState  = ConsumableManagerDB.isVisible and HexColor("Visible", "00ff00") or HexColor("Hidden", "777777")

    print("   Mode: " .. groupMode .. "  |  Lock: " .. lockState .. "  |  Visiblity: " .. visState)

    -- 2. Keybinds Section
    print(HexColor(" [Keybinds]", "ffff00"))
    local bindLine = "   "
    local keys = { "Food", "Drink", "Health", "Mana" }
    for i, key in ipairs(keys) do
        local bind = GetBindingKey("CLICK CM" .. key .. "Button:LeftButton")
        local bindText = bind and HexColor(bind, "ffffff") or HexColor("None", "555555")
        bindLine = bindLine .. key .. ": " .. bindText .. (i < #keys and "  |  " or "")
    end
    print(bindLine)

    -- 3. Commands Section
    print(HexColor(" [Commands]", "ffff00"))
    local cmdC = "cccccc" -- Command color
    print("   /cm " .. HexColor("conf", cmdC) .. "    - Open configuration menu")
    print("   /cm " .. HexColor("lock", cmdC) .. "    - Toggle button locking")
    print("   /cm " .. HexColor("group", cmdC) .. "   - Switch layout to Grouped/Individual")
    print("   /cm " .. HexColor("show", cmdC) .. "    - Show buttons")
    print("   /cm " .. HexColor("hide", cmdC) .. "    - Hide buttons")
    print("   /cm " .. HexColor("reset", "ff4444") .. "   - Factory reset addon")
    print("--------------------------------------------------")
end

-- Slash Command Handler
SLASH_CM1 = "/cm"
SlashCmdList.CM = function(input)
    local command = input:lower():trim()

    if command == "conf" or command == "config" or command == "menu" then
        InterfaceOptionsFrame_OpenToCategory("Consumable Manager")
    elseif command == "reset" then
        ConsumableManagerDB = nil
        print("|cffff0000CM: Settings wiped. Reloading...|r")
        ReloadUI()
    elseif command == "group" then
        ConsumableManagerDB.isGrouped = not ConsumableManagerDB.isGrouped
        RefreshButtonPositions()
        if ConsumableManagerDB.isGrouped then
            ConsumableManagerDB.isGrouped = true
            print("|cff00ffffCM: Mode set to Grouped (LMB Drag).|r")
        else
            ConsumableManagerDB.isGrouped = false
            print("|cffffaa00CM: Mode set to Individual (Alt+LMB Drag).|r")
        end
    elseif command == "lock" then
        ConsumableManagerDB.isLocked = not ConsumableManagerDB.isLocked
        RefreshLockState()
        if ConsumableManagerDB.isLocked then
            print("|cff00ff00CM: Buttons Locked.|r")
        else
            print("|cffffff00CM: Buttons Unlocked.|r")
        end
    elseif command == "show" then
        ConsumableManagerDB.isVisible = true
        UpdateConsumableDisplay()
        print("|cff00ff00CM: Buttons Visible.|r")
    elseif command == "hide" then
        ConsumableManagerDB.isVisible = false
        UpdateConsumableDisplay()
        print("|cffffff00CM: Buttons Hidden.|r")
    else
        DisplayAddonStatus()
    end
end

--------------------------------------------------------------------------------
-- Event Handling & Update Dispatcher
--------------------------------------------------------------------------------

EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:RegisterEvent("BAG_UPDATE")
EventFrame:RegisterEvent("UPDATE_BINDINGS")
EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
EventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

EventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Slight delay to ensure SavedVariables are fully loaded
        C_Timer.After(INIT_DELAY, function()
            InitializeButtons()
            UpdateConsumableDisplay()
        end)
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Process queued updates after leaving combat
        if isUpdatePending then
            UpdateConsumableDisplay()
        end
        for _, queuedUpdate in ipairs(combatQueue) do
            queuedUpdate()
        end
        wipe(combatQueue)
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entering combat
        isUpdatePending = false
    else
        -- Respond to bag changes or keybind changes
        UpdateConsumableDisplay()
    end
end)

-- OnUpdate: Ensures that if an update was requested during combat, it runs immediately after.
EventFrame:SetScript("OnUpdate", function()
    if isUpdatePending and not InCombatLockdown() then
        UpdateConsumableDisplay()
    end
end)
