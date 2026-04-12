local addonName, addonTable = ...

-- ============================================================================
-- Core Initialization
-- Sets up shared tables, constants, and utility functions used across the addon
-- ============================================================================

-- Shared state tables
addonTable.hookedFrames = setmetatable({}, {__mode = "k"})  -- Weak table for hooked frames
addonTable.frameHandlers = {}  -- Registered frame handlers
addonTable.lastHoveredFrame = nil  -- Currently hovered frame reference

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
    }

    local gridSeen = {
        left = {},
        middle = {},
        right = {},
    }

    local function classifyMouseButton(buttonText)
        if not buttonText then return nil end
        local lower = tostring(buttonText):lower()

        if lower:find("button1") or lower:find("leftbutton") or lower:find("left click") then
            return "left"
        elseif lower:find("button2") or lower:find("rightbutton") or lower:find("right click") then
            return "right"
        elseif lower:find("button3") or lower:find("middlebutton") or lower:find("middle click") then
            return "middle"
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
            return "|TInterface\\Buttons\\UI-SpellbookIcon-PrevPage-Up:" .. size .. ":" .. size .. ":0:0|t"
        elseif slot == "middle" then
            return "|TInterface\\Buttons\\UI-Panel-MinimizeButton-Up:" .. size .. ":" .. size .. ":0:0|t"
        elseif slot == "right" then
            return "|TInterface\\Buttons\\UI-SpellbookIcon-NextPage-Up:" .. size .. ":" .. size .. ":0:0|t"
        end

        return nil
    end

    local function displayButtonText(buttonText)
        if not useMouseButtonIcons then
            return tostring(buttonText)
        end

        local slot = classifyMouseButton(buttonText)
        return iconForSlot(slot, iconSize) or tostring(buttonText)
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
        if gridMode and addGridAction(buttonText, displayActionText(actionName, bindingType, spellIdentifier, true), tostring(actionName or "")) then
            return
        end
        emitStandardLine(buttonText, actionName, bindingType, spellIdentifier)
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

        frame.leftBody = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        frame.leftBody:SetJustifyH("CENTER")
        frame.leftBody:SetJustifyV("TOP")

        frame.middleBody = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        frame.middleBody:SetJustifyH("CENTER")
        frame.middleBody:SetJustifyV("TOP")

        frame.rightBody = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        frame.rightBody:SetJustifyH("CENTER")
        frame.rightBody:SetJustifyV("TOP")

        addonTable.gridLayoutFrames[ownerTooltip] = frame
        return frame
    end

    local function emitCustomGridFrame()
        local hasAny = (#gridBuckets.left + #gridBuckets.middle + #gridBuckets.right) > 0
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
        applyFontSize(frame.leftBody, bodyFontSize)
        applyFontSize(frame.middleBody, bodyFontSize)
        applyFontSize(frame.rightBody, bodyFontSize)

        frame.leftHeader:SetTextColor(rB, gB, bB)
        frame.middleHeader:SetTextColor(rB, gB, bB)
        frame.rightHeader:SetTextColor(rB, gB, bB)

        frame.leftHeader:SetText(displayHeaderText("left", "Left"))
        frame.middleHeader:SetText(displayHeaderText("middle", "Middle"))
        frame.rightHeader:SetText(displayHeaderText("right", "Right"))

        frame.leftBody:SetTextColor(rA, gA, bA)
        frame.middleBody:SetTextColor(rA, gA, bA)
        frame.rightBody:SetTextColor(rA, gA, bA)

        frame.separator:SetColorTexture(dividerR, dividerG, dividerB, 0.50)
        frame.colSeparator1:SetColorTexture(borderR, borderG, borderB, 0.42)
        frame.colSeparator2:SetColorTexture(borderR, borderG, borderB, 0.42)

        local function bucketBodyText(bucket)
            if #bucket == 0 then
                return ""
            end
            return table.concat(bucket, "\n")
        end

        frame.leftBody:SetText(bucketBodyText(gridBuckets.left))
        frame.middleBody:SetText(bucketBodyText(gridBuckets.middle))
        frame.rightBody:SetText(bucketBodyText(gridBuckets.right))

        -- Clear any previous width constraints so size calculations reflect true content width.
        frame.leftHeader:SetWidth(0)
        frame.middleHeader:SetWidth(0)
        frame.rightHeader:SetWidth(0)
        frame.leftBody:SetWidth(0)
        frame.middleBody:SetWidth(0)
        frame.rightBody:SetWidth(0)

        local leftHasContent = #gridBuckets.left > 0
        local middleHasContent = #gridBuckets.middle > 0
        local rightHasContent = #gridBuckets.right > 0

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

        local headerRowHeight = math.max(
            headerFontSize + 2,
            frame.leftHeader:GetStringHeight() or 0,
            frame.middleHeader:GetStringHeight() or 0,
            frame.rightHeader:GetStringHeight() or 0,
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
        local width = (innerPad * 2) + leftW + middleW + rightW + (colGap * 2)

        frame.leftHeader:ClearAllPoints()
        frame.leftHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", leftX, -headerTopPad)
        frame.leftHeader:SetWidth(leftW)
        frame.middleHeader:ClearAllPoints()
        frame.middleHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", middleX, -headerTopPad)
        frame.middleHeader:SetWidth(middleW)
        frame.rightHeader:ClearAllPoints()
        frame.rightHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", rightX, -headerTopPad)
        frame.rightHeader:SetWidth(rightW)

        frame.separator:ClearAllPoints()
        frame.separator:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, separatorY)
        frame.separator:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, separatorY)

        frame.middleBody:ClearAllPoints()
        frame.middleBody:SetPoint("TOPLEFT", frame, "TOPLEFT", middleX, bodyStartY)
        frame.rightBody:ClearAllPoints()
        frame.rightBody:SetPoint("TOPLEFT", frame, "TOPLEFT", rightX, bodyStartY)

        frame.leftBody:ClearAllPoints()
        frame.leftBody:SetPoint("TOPLEFT", frame, "TOPLEFT", leftX, bodyStartY)

        frame.leftBody:SetWidth(leftW)
        frame.middleBody:SetWidth(middleW)
        frame.rightBody:SetWidth(rightW)

        frame.colSeparator1:ClearAllPoints()
        frame.colSeparator1:SetPoint("TOP", frame, "TOPLEFT", middleX - (colGap / 2), -3)
        frame.colSeparator1:SetPoint("BOTTOM", frame, "BOTTOMLEFT", middleX - (colGap / 2), 3)

        frame.colSeparator2:ClearAllPoints()
        frame.colSeparator2:SetPoint("TOP", frame, "TOPLEFT", rightX - (colGap / 2), -3)
        frame.colSeparator2:SetPoint("BOTTOM", frame, "BOTTOMLEFT", rightX - (colGap / 2), 3)

        local bodyHeight = math.max(
            bodyFontSize + 2,
            frame.leftBody:GetStringHeight() or 14,
            frame.middleBody:GetStringHeight() or 14,
            frame.rightBody:GetStringHeight() or 14
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

    -- Track shown bindings to prevent duplicates
    local shownBindings = {}
    
    -- Get current modifier key state
    local isShiftKeyDown = IsShiftKeyDown()
    local isAltKeyDown = IsAltKeyDown()
    local isControlKeyDown = IsControlKeyDown()
    
    -- Show Blizzard bindings if enabled
    if db.showBlizzardBindings ~= false and clickBindings then
        for _, binding in ipairs(clickBindings) do
            -- Get modifier string from binding
            local modifier = C_ClickBindings.GetStringFromModifiers(binding.modifiers)
            
            -- Get action name based on binding type
            local actionName = tostring(binding.actionID)
            local actionBindingType = nil
            local spellIdentifier = nil
            if binding.type == Enum.ClickBindingType.Interaction then
                if binding.actionID == Enum.ClickBindingInteraction.Target then
                    actionName = "Target"
                elseif binding.actionID == Enum.ClickBindingInteraction.OpenContextMenu then
                    actionName = "Open Context Menu"
                end
            elseif binding.type == Enum.ClickBindingType.Spell then
                actionBindingType = "spell"
                -- Resolve spec-specific overrides
                local overrideID = binding.actionID
                if C_SpellBook and C_SpellBook.FindSpellOverrideByID then
                    overrideID = C_SpellBook.FindSpellOverrideByID(binding.actionID) or binding.actionID
                end
                spellIdentifier = overrideID
                
                if C_Spell and C_Spell.GetSpellInfo then
                    local spellInfo = C_Spell.GetSpellInfo(overrideID)
                    actionName = spellInfo and spellInfo.name or actionName
                end
                
                if actionName == tostring(binding.actionID) and C_Spell and C_Spell.GetSpellName then
                    actionName = C_Spell.GetSpellName(overrideID)
                end
            elseif binding.type == Enum.ClickBindingType.Macro then
                actionName = GetMacroInfo(binding.actionID) or "Macro"
            end
            
            -- Check if this binding should show based on current modifiers
            local show = false
            if (isShiftKeyDown and not isAltKeyDown and not isControlKeyDown) and (modifier == "SHIFT") then show = true
            elseif (not isShiftKeyDown and isAltKeyDown and not isControlKeyDown) and (modifier == "ALT") then show = true
            elseif (not isShiftKeyDown and not isAltKeyDown and isControlKeyDown) and (modifier == "CTRL") then show = true
            elseif (isShiftKeyDown and isAltKeyDown and not isControlKeyDown) and (modifier == "SHIFT-ALT" or modifier == "ALT-SHIFT") then show = true
            elseif (isShiftKeyDown and not isAltKeyDown and isControlKeyDown) and (modifier == "SHIFT-CTRL" or modifier == "CTRL-SHIFT") then show = true
            elseif (not isShiftKeyDown and isAltKeyDown and isControlKeyDown) and (modifier == "ALT-CTRL" or modifier == "CTRL-ALT") then show = true
            elseif (isShiftKeyDown and isAltKeyDown and isControlKeyDown) and (modifier == "SHIFT-ALT-CTRL" or modifier == "SHIFT-CTRL-ALT" or modifier == "ALT-SHIFT-CTRL" or modifier == "ALT-CTRL-SHIFT" or modifier == "CTRL-SHIFT-ALT" or modifier == "CTRL-ALT-SHIFT") then show = true
            elseif (not isAltKeyDown and not isControlKeyDown and not isShiftKeyDown) and (modifier == "") then show = true
            end
            
            if show then
                -- Create unique key for deduplication
                local bindingKey = binding.button .. "|" .. modifier .. "|" .. tostring(binding.actionID)
                if not shownBindings[bindingKey] then
                    shownBindings[bindingKey] = true
                    
                        emitBinding(binding.button, actionName, actionBindingType, spellIdentifier)
                end
            end
        end
    end
    
    -- Show Clique bindings if enabled and Clique is loaded
    ---@diagnostic disable-next-line: undefined-global
    if db.showCliqueBindings ~= false and Clique and Clique.db and Clique.db.profile and Clique.db.profile.bindings then
        ---@diagnostic disable-next-line: undefined-global
        local profile = Clique.db.profile
        
        for key, binding in pairs(profile.bindings) do
            if binding and binding.sets then
                local shouldShow = false
                local inCombat = InCombatLockdown()
                
                for setName, _ in pairs(binding.sets) do
                    if setName == "default" or setName == "hovercast" or setName == "global" then
                        shouldShow = true
                    elseif setName == "ooc" and not inCombat then
                        shouldShow = true
                    end
                end
                
                if shouldShow then
                    local actionName = binding.spell or binding.macro or binding.action or "Action"
                    local actionBindingType = nil
                    local spellIdentifier = nil
                    if binding.type == "target" then
                        actionName = "Target"
                    elseif binding.type == "menu" then
                        actionName = "Open Menu"
                    elseif binding.spell then
                        actionBindingType = "spell"
                        spellIdentifier = binding.spell
                    end
                    
                    local buttonText = binding.key
                    if buttonText and type(buttonText) == "string" then
                        -- Check modifiers match current state
                        local lowerKey = buttonText:lower()
                        local hasShift = lowerKey:find("shift") ~= nil
                        local hasCtrl = lowerKey:find("ctrl") ~= nil or lowerKey:find("control") ~= nil
                        local hasAlt = lowerKey:find("alt") ~= nil
                        
                        local modifiersMatch = (hasShift == isShiftKeyDown) and 
                                              (hasCtrl == isControlKeyDown) and 
                                              (hasAlt == isAltKeyDown)
                        
                        if modifiersMatch then
                            local bindingKey = "clique|" .. buttonText .. "|" .. actionName
                            if not shownBindings[bindingKey] then
                                shownBindings[bindingKey] = true
                                
                                -- Format display text
                                local displayText = buttonText:gsub("BUTTON1", "Left Click")
                                displayText = displayText:gsub("BUTTON2", "Right Click")
                                displayText = displayText:gsub("BUTTON3", "Middle Click")
                                displayText = displayText:gsub("shift%-", "Shift-")
                                displayText = displayText:gsub("ctrl%-", "Ctrl-")
                                displayText = displayText:gsub("alt%-", "Alt-")
                                
                                emitBinding(displayText, actionName, actionBindingType, spellIdentifier)
                            end
                        end
                    end
                end
            end
        end
    end

    if gridMode then
        if useGridFrame then
            emitCustomGridFrame()
        end
    end
end
