local addonName, addonTable = ...

-- ============================================================================
-- Core Initialization
-- Sets up shared tables, constants, and utility functions used across the addon
-- ============================================================================

-- Shared state tables
addonTable.hookedFrames = setmetatable({}, {__mode = "k"})  -- Weak table for hooked frames
addonTable.frameHandlers = {}  -- Registered frame handlers
addonTable.lastHoveredFrame = nil  -- Currently hovered frame reference
addonTable.clickBindingHandlers = addonTable.clickBindingHandlers or {}

-- Anchor position mapping for tooltip placement
addonTable.anchorMap = {
    [1] = "TOPLEFT",    [2] = "TOP",    [3] = "TOPRIGHT",
    [4] = "LEFT",       [5] = "CENTER", [6] = "RIGHT",
    [7] = "BOTTOMLEFT", [8] = "BOTTOM", [9] = "BOTTOMRIGHT",
    [10] = "SCREEN"
}

-- Create the Blizzard tooltip reference
addonTable.blizzardToolTip = GameTooltip

-- Create the custom floating tooltip with BackdropTemplate for texture support
addonTable.clickCastingTooltip = CreateFrame("GameTooltip", "ClickToCastCustomTooltip", UIParent, "GameTooltipTemplate,BackdropTemplate")

-- ============================================================================
-- Tooltip Theme Application
-- ============================================================================

--- Parses a hex color string (AARRGGBB format) into RGBA values
-- @param hexColor string: The hex color string (e.g., "ff1a1a2e")
-- @return number, number, number, number: r, g, b, a values (0-1 range)
local function parseHexColor(hexColor)
    if not hexColor or #hexColor < 8 then
        return 0, 0, 0, 1
    end
    local a = tonumber("0x" .. hexColor:sub(1, 2)) / 255
    local r = tonumber("0x" .. hexColor:sub(3, 4)) / 255
    local g = tonumber("0x" .. hexColor:sub(5, 6)) / 255
    local b = tonumber("0x" .. hexColor:sub(7, 8)) / 255
    return r, g, b, a
end

--- Applies the theme settings to the custom tooltip
function addonTable.applyTooltipTheme()
    local db = ClickToCastTooltip and ClickToCastTooltip.db and ClickToCastTooltip.db.global
    if not db then return end
    
    local tooltip = addonTable.clickCastingTooltip
    if not tooltip then return end
    
    -- Check if ElvUI theme should be used
    if db.useElvUITheme and ElvUI and ElvUI[1] then
        local E = ElvUI[1]
        -- Show NineSlice if it was hidden
        if tooltip.NineSlice then
            tooltip.NineSlice:Show()
        end
        -- Apply ElvUI template if available
        if tooltip.SetTemplate then
            tooltip:SetTemplate("Transparent")
        elseif E.Skins and E.Skins.HandleTooltip then
            E.Skins:HandleTooltip(tooltip)
        end
        -- Apply scale
        local scale = db.tooltipScale or 1.0
        tooltip:SetScale(scale)
        return
    end
    
    -- Apply scale
    local scale = db.tooltipScale or 1.0
    tooltip:SetScale(scale)
    
    -- Apply background and border colors
    local bgR, bgG, bgB, bgA = parseHexColor(db.tooltipBackgroundColor or "ff1a1a2e")
    local borderR, borderG, borderB, borderA = parseHexColor(db.tooltipBorderColor or "ff4a4a6a")
    
    -- Background texture mapping
    local backgroundTextures = {
        [1] = "Interface\\Tooltips\\UI-Tooltip-Background",
        [2] = "Interface\\Buttons\\WHITE8X8",
        [3] = "Interface\\DialogFrame\\UI-DialogBox-Background",
        [4] = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal",
        [5] = "Interface\\FrameGeneral\\UI-Background-Rock",
    }
    
    -- Border texture mapping
    local borderTextures = {
        [1] = "Interface\\Tooltips\\UI-Tooltip-Border",
        [2] = "Interface\\Buttons\\WHITE8X8",
        [3] = "Interface\\DialogFrame\\UI-DialogBox-Border",
        [4] = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        [5] = nil, -- No border
    }
    
    -- Determine textures based on settings
    local squareCorners = db.tooltipSquareCorners or false
    local bgTextureIndex = db.tooltipBackgroundTexture or 1
    local borderTextureIndex = db.tooltipBorderTexture or 1
    
    local bgFile = backgroundTextures[bgTextureIndex] or backgroundTextures[1]
    local edgeFile = borderTextures[borderTextureIndex]
    
    -- Override edge file for square corners if using default border
    if squareCorners and borderTextureIndex == 1 then
        edgeFile = "Interface\\Buttons\\WHITE8X8"
    end
    
    local edgeSize = 16
    if borderTextureIndex == 2 or (squareCorners and borderTextureIndex == 1) then
        edgeSize = 1
    elseif borderTextureIndex == 5 then
        edgeSize = 0
    end
    
    -- Set backdrop if available (modern WoW uses NineSlice)
    if tooltip.SetBackdrop then
        -- Hide the default NineSlice if it exists
        if tooltip.NineSlice then
            tooltip.NineSlice:Hide()
        end
        
        tooltip:SetBackdrop({
            bgFile = bgFile,
            edgeFile = edgeFile,
            tile = true,
            tileSize = 16,
            edgeSize = edgeSize,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        tooltip:SetBackdropColor(bgR, bgG, bgB, bgA)
        tooltip:SetBackdropBorderColor(borderR, borderG, borderB, borderA)
    elseif tooltip.NineSlice then
        -- Fallback: Try to apply to NineSlice (if SetBackdrop not available)
        if tooltip.NineSlice.SetCenterColor then
            tooltip.NineSlice:SetCenterColor(bgR, bgG, bgB, bgA)
        end
        if tooltip.NineSlice.SetBorderColor then
            tooltip.NineSlice:SetBorderColor(borderR, borderG, borderB, borderA)
        end
    end
    
    -- Apply font size to tooltip text regions
    local fontSize = db.tooltipFontSize or 12
    local tooltipName = tooltip:GetName()
    if tooltipName then
        -- Apply to all text lines
        for i = 1, 30 do
            local leftText = _G[tooltipName .. "TextLeft" .. i]
            local rightText = _G[tooltipName .. "TextRight" .. i]
            if leftText and leftText.GetFont and leftText.SetFont then
                local path = leftText:GetFont()
                if path then
                    leftText:SetFont(path, fontSize, "")
                end
            end
            if rightText and rightText.GetFont and rightText.SetFont then
                local path = rightText:GetFont()
                if path then
                    rightText:SetFont(path, fontSize, "")
                end
            end
        end
    end
end

-- Timer reference for frame clear scheduling
local clearTimer = nil

--- Schedules clearing the last hovered frame reference after mouse leaves
-- @param frame Frame: The frame that was just left
function addonTable.scheduleFrameClear(frame)
    if clearTimer then
        clearTimer:Cancel()
    end
    clearTimer = C_Timer.NewTimer(0.1, function()
        -- Only clear if the frame being left is still the tracked frame
        -- This prevents clearing when we've already moved to a different frame
        if frame and frame == addonTable.lastHoveredFrame and not frame:IsMouseOver() then
            addonTable.lastHoveredFrame = nil
        end
    end)
end

-- ============================================================================
-- Unit Frame Type Detection
-- Determines the type of unit frame for filtering purposes
-- ============================================================================

--- Determines the unit frame type category for a given frame
-- @param frame Frame: The unit frame to check
-- @return string: The unit frame type category (player, target, focus, party, raid, boss, arena, pet, targettarget, npc, or unknown)
function addonTable.getUnitFrameType(frame)
    if not frame then return "unknown" end
    
    local frameName = frame:GetName() or ""
    local unit = frame.unit
    
    -- Try to extract unit from the frame name if not directly available
    if not unit and frame.GetAttribute then
        unit = frame:GetAttribute("unit")
    end
    
    local lowerName = frameName:lower()
    local lowerUnit = unit and unit:lower() or ""
    
    -- Check frame name patterns first (more reliable for addon frames)
    -- NPC frames (Cell addon)
    if lowerName:find("npc") then
        return "npc"
    end
    
    -- Pet frames
    if lowerName:find("pet") or lowerUnit:find("pet") then
        return "pet"
    end
    
    -- Arena frames
    if lowerName:find("arena") or lowerUnit:find("arena") then
        return "arena"
    end
    
    -- Boss frames
    if lowerName:find("boss") or lowerUnit:find("boss") then
        return "boss"
    end
    
    -- Target of Target / Focus Target frames
    if lowerName:find("tot") or lowerName:find("targettarget") or lowerName:find("focustarget")
       or lowerUnit == "targettarget" or lowerUnit == "focustarget" then
        return "targettarget"
    end
    
    -- Raid frames (check before party since some raid frames might contain "party" in name)
    if lowerName:find("raid") or lowerName:find("compactraidgroup")
       or (unit and unit:match("^raid%d+$")) then
        return "raid"
    end
    
    -- Party frames
    if lowerName:find("party") or lowerName:find("compactparty")
       or (unit and unit:match("^party%d+$")) then
        return "party"
    end
    
    -- Focus frame
    if lowerName:find("focus") or lowerUnit == "focus" then
        return "focus"
    end
    
    -- Target frame
    if lowerName:find("target") or lowerUnit == "target" then
        return "target"
    end
    
    -- Player frame
    if lowerName:find("player") or lowerUnit == "player" then
        return "player"
    end
    
    -- If we have a unit, try to determine type from it
    if unit then
        if unit:match("^raid%d+$") then return "raid" end
        if unit:match("^party%d+$") then return "party" end
        if unit:match("pet") then return "pet" end
        if unit:match("boss") then return "boss" end
        if unit:match("arena") then return "arena" end
    end
    
    return "unknown"
end

--- Checks if tooltip should be shown for a given frame based on unit frame type settings
-- @param frame Frame: The unit frame to check
-- @return boolean: True if tooltip should be shown, false otherwise
function addonTable.shouldShowForUnitFrameType(frame)
    local db = ClickToCastTooltip and ClickToCastTooltip.db and ClickToCastTooltip.db.global
    if not db then return true end -- Default to showing if no settings
    
    local frameType = addonTable.getUnitFrameType(frame)
    
    -- Map frame types to settings keys
    local typeToSetting = {
        player = "unitFramePlayer",
        target = "unitFrameTarget",
        focus = "unitFrameFocus",
        party = "unitFrameParty",
        raid = "unitFrameRaid",
        boss = "unitFrameBoss",
        arena = "unitFrameArena",
        pet = "unitFramePet",
        targettarget = "unitFrameTargetOfTarget",
        npc = "unitFrameNPC",
        unknown = nil, -- Always show for unknown types
    }
    
    local settingKey = typeToSetting[frameType]
    if not settingKey then return true end -- No setting for this type, show by default
    
    local settingValue = db[settingKey]
    if settingValue == nil then return true end -- Setting not configured, show by default
    
    return settingValue
end

-- Frame handler initialization (placeholder for backward compatibility)
addonTable.frameHandler = {
    init = function()
        -- This can be used for any initialization logic
    end
}

--- Updates tooltip with click binding information
-- This function is called by both the Blizzard tooltip and custom tooltip
-- @param db table: Database settings
-- @param clickBindings table: Click binding profile info
-- @param tooltip GameTooltip: The tooltip frame to update
-- @param nonBlankLineCount table: Counter object with .value property
function addonTable.updateTooltip(db, clickBindings, tooltip, nonBlankLineCount)
    -- Guard against nil tooltip
    if not tooltip then
        return
    end
    
    local buttonColor = CreateColorFromHexString(db.buttonColor or "ffff0000")
    local actionColor = CreateColorFromHexString(db.actionColor or "ff00ff00")
    local gridMode = db.tooltipGridLayout == true
    local useMouseButtonIcons = db.tooltipUseMouseButtonIcons == true
    local useSpellIcons = db.tooltipUseSpellIcons == true
    local baseFontSize = db.tooltipFontSize or 12
    local iconSize = math.max(10, math.min(24, baseFontSize + 2))
    local useGridFrame = gridMode and tooltip == addonTable.clickCastingTooltip

    local gridBuckets = {
        left = {},
        middle = {},
        right = {},
        wheelup = {},
        wheeldown = {},
    }

    local gridSeen = {
        left = {},
        middle = {},
        right = {},
        wheelup = {},
        wheeldown = {},
    }

    local function classifyMouseButton(buttonText)
        if not buttonText then return nil end
        local lower = tostring(buttonText):lower()

        if lower:find("button1") or lower:find("leftbutton") or lower:find("left click") or lower:find("leftclick") then
            return "left"
        elseif lower:find("button2") or lower:find("rightbutton") or lower:find("right click") or lower:find("rightclick") then
            return "right"
        elseif lower:find("button3") or lower:find("middlebutton") or lower:find("middle click") or lower:find("middleclick") then
            return "middle"
        elseif lower:find("mousewheelup") or lower:find("mouse wheel up") or lower:find("scrollup") or lower:find("scroll up") then
            return "wheelup"
        elseif lower:find("mousewheeldown") or lower:find("mouse wheel down") or lower:find("scrolldown") or lower:find("scroll down") then
            return "wheeldown"
        end

        return nil
    end

    local function addGridAction(buttonText, actionName, dedupeKey)
        local slot = classifyMouseButton(buttonText)
        if not slot then return false end
        if not actionName or actionName == "" then return true end

        local uniqueKey = dedupeKey or actionName

        if not gridSeen[slot][uniqueKey] then
            gridSeen[slot][uniqueKey] = true
            table.insert(gridBuckets[slot], actionName)
        end

        return true
    end

    local function iconForSlot(slot, size)
        if slot == "left" then
            return "|TInterface\\Icons\\misc_arrowleft:" .. size .. ":" .. size .. ":0:0|t"
        elseif slot == "middle" then
            return "|TInterface\\Buttons\\UI-Panel-MinimizeButton-Up:" .. size .. ":" .. size .. ":0:0|t"
        elseif slot == "right" then
            return "|TInterface\\Icons\\misc_arrowright:" .. size .. ":" .. size .. ":0:0|t"
        elseif slot == "wheelup" then
            return "|TInterface\\Icons\\misc_arrowlup:" .. size .. ":" .. size .. ":0:0|t"
        elseif slot == "wheeldown" then
            return "|TInterface\\Icons\\misc_arrowdown:" .. size .. ":" .. size .. ":0:0|t"
        end

        return nil
    end

    local function displayButtonText(buttonText)
        if not useMouseButtonIcons then
            local lower = tostring(buttonText or ""):lower()
            if lower:find("mousewheelup") or lower:find("scrollup") then
                return "Wheel Up"
            elseif lower:find("mousewheeldown") or lower:find("scrolldown") then
                return "Wheel Down"
            end
            return tostring(buttonText)
        end

        local slot = classifyMouseButton(buttonText)
        return iconForSlot(slot, iconSize) or tostring(buttonText)
    end

    local function normalizeBindingButtonText(buttonText)
        local text = tostring(buttonText or "")
        local upper = text:upper()

        upper = upper:gsub("^SHIFT%-", "")
        upper = upper:gsub("^CTRL%-", "")
        upper = upper:gsub("^CONTROL%-", "")
        upper = upper:gsub("^ALT%-", "")
        upper = upper:gsub("^META%-", "")

        upper = upper:gsub("BUTTON1", "LEFTBUTTON")
        upper = upper:gsub("BUTTON2", "RIGHTBUTTON")
        upper = upper:gsub("BUTTON3", "MIDDLEBUTTON")

        if upper == "LEFT CLICK" or upper == "LEFTCLICK" then
            return "LeftButton"
        elseif upper == "RIGHT CLICK" or upper == "RIGHTCLICK" then
            return "RightButton"
        elseif upper == "MIDDLE CLICK" or upper == "MIDDLECLICK" then
            return "MiddleButton"
        elseif upper == "LEFTBUTTON" then
            return "LeftButton"
        elseif upper == "RIGHTBUTTON" then
            return "RightButton"
        elseif upper == "MIDDLEBUTTON" then
            return "MiddleButton"
        elseif upper == "SCROLLUP" or upper == "MOUSEWHEELUP" or upper == "MOUSE WHEEL UP" then
            return "MouseWheelUp"
        elseif upper == "SCROLLDOWN" or upper == "MOUSEWHEELDOWN" or upper == "MOUSE WHEEL DOWN" then
            return "MouseWheelDown"
        end

        local buttonNumber = upper:match("^BUTTON(%d+)$")
        if buttonNumber then
            return "Button" .. buttonNumber
        end

        return text
    end

    local function displayHeaderText(slot, text)
        if not useMouseButtonIcons then
            return text
        end

        return iconForSlot(slot, iconSize) or text
    end

    local function spellIconText(spellIdentifier)
        if not spellIdentifier then
            return nil
        end

        local spellTexture = nil
        if C_Spell and C_Spell.GetSpellTexture then
            spellTexture = C_Spell.GetSpellTexture(spellIdentifier)
        end

        if not spellTexture and C_Spell and C_Spell.GetSpellInfo then
            local spellInfo = C_Spell.GetSpellInfo(spellIdentifier)
            spellTexture = spellInfo and spellInfo.iconID or nil
        end

        if spellTexture then
            return "|T" .. tostring(spellTexture) .. ":" .. iconSize .. ":" .. iconSize .. ":0:0|t"
        end

        return nil
    end

    local function displayActionText(actionName, bindingType, spellIdentifier, forGrid)
        local textValue = tostring(actionName or "")

        if useSpellIcons and bindingType == "spell" then
            local iconMarkup = spellIconText(spellIdentifier or textValue)
            if iconMarkup then
                return iconMarkup
            end
        end

        if forGrid then
            return textValue
        end

        return actionColor:WrapTextInColorCode(textValue)
    end

    local function emitStandardLine(buttonText, actionName, bindingType, spellIdentifier)
        local lineText = buttonColor:WrapTextInColorCode(displayButtonText(buttonText)) .. " - " .. displayActionText(actionName, bindingType, spellIdentifier, false)
        if lineText:match("%S") then
            nonBlankLineCount.value = nonBlankLineCount.value + 1
            tooltip:AddLine(lineText)
        end
    end

    local function emitBinding(buttonText, actionName, bindingType, spellIdentifier)
        local normalizedButton = normalizeBindingButtonText(buttonText)
        if gridMode then
            -- Column layout should only show keys that have an actual spell bound.
            if bindingType == "spell" and actionName and actionName ~= "" then
                if addGridAction(normalizedButton, displayActionText(actionName, bindingType, spellIdentifier, true), tostring(actionName or "")) then
                    return
                end
            else
                return
            end
        end
        emitStandardLine(normalizedButton, actionName, bindingType, spellIdentifier)
    end

    local function ensureCustomGridFrame(ownerTooltip)
        addonTable.gridLayoutFrames = addonTable.gridLayoutFrames or {}

        if addonTable.gridLayoutFrames[ownerTooltip] then
            return addonTable.gridLayoutFrames[ownerTooltip]
        end

        local frame = CreateFrame("Frame", nil, ownerTooltip)
        frame:SetPoint("TOPLEFT", ownerTooltip, "TOPLEFT", 8, -8)

        frame.leftHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        frame.leftHeader:SetJustifyH("CENTER")
        frame.leftHeader:SetText("Left")

        frame.middleHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        frame.middleHeader:SetJustifyH("CENTER")
        frame.middleHeader:SetText("Middle")

        frame.rightHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        frame.rightHeader:SetJustifyH("CENTER")
        frame.rightHeader:SetText("Right")

        frame.wheelUpHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        frame.wheelUpHeader:SetJustifyH("CENTER")
        frame.wheelUpHeader:SetText("Wheel Up")

        frame.wheelDownHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        frame.wheelDownHeader:SetJustifyH("CENTER")
        frame.wheelDownHeader:SetText("Wheel Down")

        frame.separator = frame:CreateTexture(nil, "BORDER")
        frame.separator:SetColorTexture(0.75, 0.66, 0.32, 0.45)
        frame.separator:SetHeight(1)
        frame.separator:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -22)
        frame.separator:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -22)

        frame.colSeparator1 = frame:CreateTexture(nil, "BORDER")
        frame.colSeparator1:SetColorTexture(0.70, 0.62, 0.30, 0.20)
        frame.colSeparator1:SetWidth(1)

        frame.colSeparator2 = frame:CreateTexture(nil, "BORDER")
        frame.colSeparator2:SetColorTexture(0.70, 0.62, 0.30, 0.20)
        frame.colSeparator2:SetWidth(1)

        frame.colSeparator3 = frame:CreateTexture(nil, "BORDER")
        frame.colSeparator3:SetColorTexture(0.70, 0.62, 0.30, 0.20)
        frame.colSeparator3:SetWidth(1)

        frame.colSeparator4 = frame:CreateTexture(nil, "BORDER")
        frame.colSeparator4:SetColorTexture(0.70, 0.62, 0.30, 0.20)
        frame.colSeparator4:SetWidth(1)

        frame.leftBody = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        frame.leftBody:SetJustifyH("CENTER")
        frame.leftBody:SetJustifyV("TOP")

        frame.middleBody = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        frame.middleBody:SetJustifyH("CENTER")
        frame.middleBody:SetJustifyV("TOP")

        frame.rightBody = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        frame.rightBody:SetJustifyH("CENTER")
        frame.rightBody:SetJustifyV("TOP")

        frame.wheelUpBody = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        frame.wheelUpBody:SetJustifyH("CENTER")
        frame.wheelUpBody:SetJustifyV("TOP")

        frame.wheelDownBody = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        frame.wheelDownBody:SetJustifyH("CENTER")
        frame.wheelDownBody:SetJustifyV("TOP")

        addonTable.gridLayoutFrames[ownerTooltip] = frame
        return frame
    end

    local function emitCustomGridFrame()
        local hasAny = (#gridBuckets.left + #gridBuckets.middle + #gridBuckets.right + #gridBuckets.wheelup + #gridBuckets.wheeldown) > 0
        if not hasAny then
            if addonTable.gridLayoutFrames and addonTable.gridLayoutFrames[tooltip] then
                addonTable.gridLayoutFrames[tooltip]:Hide()
            end
            if tooltip == addonTable.clickCastingTooltip then
                addonTable.customGridTooltipWidth = nil
                addonTable.customGridTooltipHeight = nil
            end
            return
        end

        local frame = ensureCustomGridFrame(tooltip)
        local frameInset = math.max(4, math.floor((db.tooltipPadding or 8) * 0.75))
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", tooltip, "TOPLEFT", frameInset, -frameInset)

        local rB, gB, bB = buttonColor:GetRGB()
        local rA, gA, bA = actionColor:GetRGB()
        local dividerHex = db.dividerColor or "ffffffff"
        local borderHex = db.tooltipBorderColor or "ff4a4a6a"
        local dividerColor = CreateColorFromHexString(dividerHex)
        local borderColor = CreateColorFromHexString(borderHex)

        local dividerR, dividerG, dividerB = dividerColor:GetRGB()
        local borderR, borderG, borderB = borderColor:GetRGB()

        local function applyFontSize(fontString, size)
            if not fontString or not fontString.GetFont or not fontString.SetFont then return end
            local path, _, flags = fontString:GetFont()
            if path then
                fontString:SetFont(path, size, flags or "")
            end
        end

        local headerFontSize = math.max(10, baseFontSize)
        local bodyFontSize = math.max(10, baseFontSize)

        applyFontSize(frame.leftHeader, headerFontSize)
        applyFontSize(frame.middleHeader, headerFontSize)
        applyFontSize(frame.rightHeader, headerFontSize)
        applyFontSize(frame.wheelUpHeader, headerFontSize)
        applyFontSize(frame.wheelDownHeader, headerFontSize)
        applyFontSize(frame.leftBody, bodyFontSize)
        applyFontSize(frame.middleBody, bodyFontSize)
        applyFontSize(frame.rightBody, bodyFontSize)
        applyFontSize(frame.wheelUpBody, bodyFontSize)
        applyFontSize(frame.wheelDownBody, bodyFontSize)

        frame.leftHeader:SetTextColor(rB, gB, bB)
        frame.middleHeader:SetTextColor(rB, gB, bB)
        frame.rightHeader:SetTextColor(rB, gB, bB)
        frame.wheelUpHeader:SetTextColor(rB, gB, bB)
        frame.wheelDownHeader:SetTextColor(rB, gB, bB)

        frame.leftHeader:SetText(displayHeaderText("left", "Left"))
        frame.middleHeader:SetText(displayHeaderText("middle", "Middle"))
        frame.rightHeader:SetText(displayHeaderText("right", "Right"))
        frame.wheelUpHeader:SetText(displayHeaderText("wheelup", "Wheel Up"))
        frame.wheelDownHeader:SetText(displayHeaderText("wheeldown", "Wheel Down"))

        frame.leftBody:SetTextColor(rA, gA, bA)
        frame.middleBody:SetTextColor(rA, gA, bA)
        frame.rightBody:SetTextColor(rA, gA, bA)
        frame.wheelUpBody:SetTextColor(rA, gA, bA)
        frame.wheelDownBody:SetTextColor(rA, gA, bA)

        frame.separator:SetColorTexture(dividerR, dividerG, dividerB, 0.50)
        frame.colSeparator1:SetColorTexture(borderR, borderG, borderB, 0.42)
        frame.colSeparator2:SetColorTexture(borderR, borderG, borderB, 0.42)
        frame.colSeparator3:SetColorTexture(borderR, borderG, borderB, 0.42)
        frame.colSeparator4:SetColorTexture(borderR, borderG, borderB, 0.42)

        local function bucketBodyText(bucket)
            if #bucket == 0 then
                return ""
            end
            return table.concat(bucket, "\n")
        end

        frame.leftBody:SetText(bucketBodyText(gridBuckets.left))
        frame.middleBody:SetText(bucketBodyText(gridBuckets.middle))
        frame.rightBody:SetText(bucketBodyText(gridBuckets.right))
        frame.wheelUpBody:SetText(bucketBodyText(gridBuckets.wheelup))
        frame.wheelDownBody:SetText(bucketBodyText(gridBuckets.wheeldown))

        -- Clear any previous width constraints so size calculations reflect true content width.
        frame.leftHeader:SetWidth(0)
        frame.middleHeader:SetWidth(0)
        frame.rightHeader:SetWidth(0)
        frame.wheelUpHeader:SetWidth(0)
        frame.wheelDownHeader:SetWidth(0)
        frame.leftBody:SetWidth(0)
        frame.middleBody:SetWidth(0)
        frame.rightBody:SetWidth(0)
        frame.wheelUpBody:SetWidth(0)
        frame.wheelDownBody:SetWidth(0)

        local leftHasContent = #gridBuckets.left > 0
        local middleHasContent = #gridBuckets.middle > 0
        local rightHasContent = #gridBuckets.right > 0
        local wheelUpHasContent = #gridBuckets.wheelup > 0
        local wheelDownHasContent = #gridBuckets.wheeldown > 0

        local screenWidth = (UIParent and UIParent.GetWidth and UIParent:GetWidth()) or 1920
        local maxColumnWidth = math.max(170, math.floor(screenWidth * 0.28))

        local function calcColumnWidth(headerFs, bodyFs, hasContent)
            local headerWidth = (headerFs:GetStringWidth() or 0) + 6
            local bodyWidth = hasContent and ((bodyFs:GetStringWidth() or 0) + 6) or 0
            local minWidth = hasContent and 86 or 58
            local maxWidth = maxColumnWidth
            return math.max(minWidth, math.min(maxWidth, math.max(headerWidth, bodyWidth)))
        end

        local leftW = calcColumnWidth(frame.leftHeader, frame.leftBody, leftHasContent)
        local middleW = calcColumnWidth(frame.middleHeader, frame.middleBody, middleHasContent)
        local rightW = calcColumnWidth(frame.rightHeader, frame.rightBody, rightHasContent)
        local wheelUpW = calcColumnWidth(frame.wheelUpHeader, frame.wheelUpBody, wheelUpHasContent)
        local wheelDownW = calcColumnWidth(frame.wheelDownHeader, frame.wheelDownBody, wheelDownHasContent)

        local headerRowHeight = math.max(
            headerFontSize + 2,
            frame.leftHeader:GetStringHeight() or 0,
            frame.middleHeader:GetStringHeight() or 0,
            frame.rightHeader:GetStringHeight() or 0,
            frame.wheelUpHeader:GetStringHeight() or 0,
            frame.wheelDownHeader:GetStringHeight() or 0,
            useMouseButtonIcons and iconSize or 0
        )
        local headerTopPad = 3
        local headerBottomPad = 3
        local separatorY = -(headerTopPad + headerRowHeight + headerBottomPad)
        local bodyTopPad = 4
        local bodyStartY = separatorY - bodyTopPad

        local colGap = 4
        local innerPad = 5
        local leftX = innerPad
        local middleX = leftX + leftW + colGap
        local rightX = middleX + middleW + colGap
        local wheelUpX = rightX + rightW + colGap
        local wheelDownX = wheelUpX + wheelUpW + colGap
        local width = (innerPad * 2) + leftW + middleW + rightW + wheelUpW + wheelDownW + (colGap * 4)

        frame.leftHeader:ClearAllPoints()
        frame.leftHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", leftX, -headerTopPad)
        frame.leftHeader:SetWidth(leftW)
        frame.middleHeader:ClearAllPoints()
        frame.middleHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", middleX, -headerTopPad)
        frame.middleHeader:SetWidth(middleW)
        frame.rightHeader:ClearAllPoints()
        frame.rightHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", rightX, -headerTopPad)
        frame.rightHeader:SetWidth(rightW)
        frame.wheelUpHeader:ClearAllPoints()
        frame.wheelUpHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", wheelUpX, -headerTopPad)
        frame.wheelUpHeader:SetWidth(wheelUpW)
        frame.wheelDownHeader:ClearAllPoints()
        frame.wheelDownHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", wheelDownX, -headerTopPad)
        frame.wheelDownHeader:SetWidth(wheelDownW)

        frame.separator:ClearAllPoints()
        frame.separator:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, separatorY)
        frame.separator:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, separatorY)

        frame.middleBody:ClearAllPoints()
        frame.middleBody:SetPoint("TOPLEFT", frame, "TOPLEFT", middleX, bodyStartY)
        frame.rightBody:ClearAllPoints()
        frame.rightBody:SetPoint("TOPLEFT", frame, "TOPLEFT", rightX, bodyStartY)
        frame.wheelUpBody:ClearAllPoints()
        frame.wheelUpBody:SetPoint("TOPLEFT", frame, "TOPLEFT", wheelUpX, bodyStartY)
        frame.wheelDownBody:ClearAllPoints()
        frame.wheelDownBody:SetPoint("TOPLEFT", frame, "TOPLEFT", wheelDownX, bodyStartY)

        frame.leftBody:ClearAllPoints()
        frame.leftBody:SetPoint("TOPLEFT", frame, "TOPLEFT", leftX, bodyStartY)

        frame.leftBody:SetWidth(leftW)
        frame.middleBody:SetWidth(middleW)
        frame.rightBody:SetWidth(rightW)
        frame.wheelUpBody:SetWidth(wheelUpW)
        frame.wheelDownBody:SetWidth(wheelDownW)

        frame.colSeparator1:ClearAllPoints()
        frame.colSeparator1:SetPoint("TOP", frame, "TOPLEFT", middleX - (colGap / 2), -3)
        frame.colSeparator1:SetPoint("BOTTOM", frame, "BOTTOMLEFT", middleX - (colGap / 2), 3)

        frame.colSeparator2:ClearAllPoints()
        frame.colSeparator2:SetPoint("TOP", frame, "TOPLEFT", rightX - (colGap / 2), -3)
        frame.colSeparator2:SetPoint("BOTTOM", frame, "BOTTOMLEFT", rightX - (colGap / 2), 3)

        frame.colSeparator3:ClearAllPoints()
        frame.colSeparator3:SetPoint("TOP", frame, "TOPLEFT", wheelUpX - (colGap / 2), -3)
        frame.colSeparator3:SetPoint("BOTTOM", frame, "BOTTOMLEFT", wheelUpX - (colGap / 2), 3)

        frame.colSeparator4:ClearAllPoints()
        frame.colSeparator4:SetPoint("TOP", frame, "TOPLEFT", wheelDownX - (colGap / 2), -3)
        frame.colSeparator4:SetPoint("BOTTOM", frame, "BOTTOMLEFT", wheelDownX - (colGap / 2), 3)

        local bodyHeight = math.max(
            bodyFontSize + 2,
            frame.leftBody:GetStringHeight() or 14,
            frame.middleBody:GetStringHeight() or 14,
            frame.rightBody:GetStringHeight() or 14,
            frame.wheelUpBody:GetStringHeight() or 14,
            frame.wheelDownBody:GetStringHeight() or 14
        )

        local topSectionHeight = (headerTopPad + headerRowHeight + headerBottomPad + bodyTopPad)
        local bottomPadding = 4
        local height = topSectionHeight + bodyHeight + bottomPadding
        frame:SetSize(width, height)
        frame:Show()

        -- Keep one real tooltip line so the GameTooltip frame always lays out/shows reliably.
        tooltip:AddLine(" ")

        -- Use frame content instead of text rows for body content.
        if tooltip == addonTable.clickCastingTooltip and addonTable.clickCastingTooltip.SetMinimumWidth then
            addonTable.clickCastingTooltip:SetMinimumWidth(width + (frameInset * 2))
        elseif tooltip ~= addonTable.clickCastingTooltip and tooltip.SetMinimumWidth then
            tooltip:SetMinimumWidth(width + (frameInset * 2))
        end

        if tooltip == addonTable.clickCastingTooltip then
            addonTable.customGridTooltipWidth = width + (frameInset * 2)
            addonTable.customGridTooltipHeight = height + (frameInset * 2)
            addonTable.clickCastingTooltip:SetSize(addonTable.customGridTooltipWidth, addonTable.customGridTooltipHeight)
        end
        nonBlankLineCount.value = nonBlankLineCount.value + 1
    end
    
    if not useGridFrame and addonTable.gridLayoutFrames and addonTable.gridLayoutFrames[tooltip] then
        addonTable.gridLayoutFrames[tooltip]:Hide()
        if tooltip == addonTable.clickCastingTooltip then
            addonTable.customGridTooltipWidth = nil
            addonTable.customGridTooltipHeight = nil
        end
    end

    local handlerContext = {
        db = db,
        clickBindings = clickBindings,
        shownBindings = {},
        emitBinding = emitBinding,
        isShiftKeyDown = IsShiftKeyDown(),
        isAltKeyDown = IsAltKeyDown(),
        isControlKeyDown = IsControlKeyDown(),
    }

    local handlers = addonTable.clickBindingHandlers
    if handlers then
        if handlers.ProcessBlizzardBindings then
            handlers.ProcessBlizzardBindings(handlerContext)
        end
        if handlers.ProcessCliqueBindings then
            handlers.ProcessCliqueBindings(handlerContext)
        end
        if handlers.ProcessCellBindings then
            handlers.ProcessCellBindings(handlerContext)
        end
    end

    if gridMode then
        if useGridFrame then
            emitCustomGridFrame()
        end
    end
end
