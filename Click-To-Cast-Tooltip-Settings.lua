local addonName, addonTable = ...
ClickToCastTooltip = LibStub("AceAddon-3.0"):NewAddon(addonName)
addonTable.ClickToCastTooltip = ClickToCastTooltip

local defaults = {
    global = {
        buttonColor = "ffff0000",
        actionColor = "ff00ff00",
        dividerColor = "ffffffff",
        showHeader = false,
        showFooter = false,
        showTooltip = true,
        showNewLineTop = false,
        showNewLineBottom = false,
        showCustomTooltip = true,
        tooltipTransparency = 0.7,
        tooltipAnchor = 9,
        showBlizzardBindings = true,
        showCliqueBindings = true,
        hasShownCliquePopup = false,
        -- Theme settings
        tooltipBackgroundColor = "ff1a1a2e",
        tooltipBorderColor = "ff4a4a6a",
        tooltipFontSize = 12,
        tooltipScale = 1.0,
        tooltipPadding = 8,
        tooltipSquareCorners = false,
        tooltipBackgroundTexture = 1,
        tooltipBorderTexture = 1,
        useElvUITheme = true,
        -- Unit frame type toggles
        unitFramePlayer = true,
        unitFrameTarget = true,
        unitFrameFocus = true,
        unitFrameParty = true,
        unitFrameRaid = true,
        unitFrameBoss = true,
        unitFrameArena = true,
        unitFramePet = true,
        unitFrameTargetOfTarget = true,
        unitFrameNPC = true,
    }
}

-- Dynamically add all the specs to the defaults.global
for classID = 1, 13 do
    local numSpecs = C_SpecializationInfo.GetNumSpecializationsForClassID(classID)
    for i = 1, numSpecs do
        local specID, name = GetSpecializationInfoForClassID(classID, i)
        local key = "specToggle_" .. specID
        defaults.global[key] = true
    end
end

local options = {
    type = "group",
    name = addonName,
    childGroups = "tab",
    args = {
        general = {
            type = "group",
            name = "General Settings",
            order = 0,
            desc = "General settings for Click-To-Cast-Tooltip.",
            args = {
                showTooltip = {
                    type = "toggle",
                    width = "full",
                    descStyle = "inline",
                    name = "Show on Blizzard tooltip",
                    desc = "Show the click to cast binding when hovering over a unit frame.",
                    get = function() return ClickToCastTooltip.db.global.showTooltip end,
                    set = function(_, val) ClickToCastTooltip.db.global.showTooltip = val end,
                    order = 1,
                },
                showCustomTooltip = {
                    type = "toggle",
                    width = "full",
                    descStyle = "inline",
                    name = "Show custom tooltip at mouse",
                    desc = "Show the custom tooltip at the mouse cursor when hovering over a unit frame.",
                    get = function() return ClickToCastTooltip.db.global.showCustomTooltip end,
                    set = function(_, val) ClickToCastTooltip.db.global.showCustomTooltip = val end,
                    order = 2,
                },
                showHeader = {
                    type = "toggle",
                    width = "full",
                    descStyle = "inline",
                    name = "Show dashed header above the tooltip.",
                    desc = "Show the dashed line header on the tooltip.",
                    get = function() return ClickToCastTooltip.db.global.showHeader end,
                    set = function(_, val) ClickToCastTooltip.db.global.showHeader = val end,
                    order = 3,
                },
                showFooter = {
                    type = "toggle",
                    width = "full",
                    descStyle = "inline",
                    name = "Show dashed footer below the tooltip.",
                    desc = "Show the dashed line footer on the tooltip.",
                    get = function() return ClickToCastTooltip.db.global.showFooter end,
                    set = function(_, val) ClickToCastTooltip.db.global.showFooter = val end,
                    order = 4,
                },
                showNewLineTop = {
                    type = "toggle",
                    width = "full",
                    descStyle = "inline",
                    name = "Show new line above the tooltip.",
                    desc = "Show a new line at the top of the tooltip.",
                    get = function() return ClickToCastTooltip.db.global.showNewLineTop end,
                    set = function(_, val) ClickToCastTooltip.db.global.showNewLineTop = val end,
                    order = 5,
                },
                showNewLineBottom = {
                    type = "toggle",
                    width = "full",
                    descStyle = "inline",
                    name = "Show new line below the tooltip.",
                    desc = "Show a new line at the bottom of the tooltip.",
                    get = function() return ClickToCastTooltip.db.global.showNewLineBottom end,
                    set = function(_, val) ClickToCastTooltip.db.global.showNewLineBottom = val end,
                    order = 6,
                },
                showBlizzardBindings = {
                    type = "toggle",
                    width = "full",
                    descStyle = "inline",
                    name = "Show Blizzard click-to-cast bindings",
                    desc = "Show WoW's native click-to-cast bindings in the tooltip.",
                    get = function() return ClickToCastTooltip.db.global.showBlizzardBindings end,
                    set = function(_, val) ClickToCastTooltip.db.global.showBlizzardBindings = val end,
                    order = 7,
                },
                showCliqueBindings = {
                    type = "toggle",
                    width = "full",
                    descStyle = "inline",
                    name = "Show Clique addon bindings",
                    desc = "Show Clique addon bindings in the tooltip (requires Clique addon).",
                    get = function() return ClickToCastTooltip.db.global.showCliqueBindings end,
                    set = function(_, val) ClickToCastTooltip.db.global.showCliqueBindings = val end,
                    order = 8,
                },
                tooltipTransparency = {
                    type = "range",
                    width = "double",
                    --descStyle = "inline",
                    name = "Custom Tooltip Transparency",
                    desc = "Set the transparency of the custom tooltip (0 = fully transparent, 1 = fully opaque).",
                    min = 0, max = 1, step = 0.01,
                    get = function() return ClickToCastTooltip.db.global.tooltipTransparency end,
                    set = function(_, val) ClickToCastTooltip.db.global.tooltipTransparency = val end,
                    order = 9,
                },
                tooltipAnchor = {
                    type = "select",
                    --width = "normal",
                    --descStyle = "inline",
                    name = "Custom Tooltip Anchor",
                    desc = "Choose where the custom tooltip is anchored.",
                    values = {
                        [1] = "TOPLEFT", [2] = "TOP", [3] = "TOPRIGHT",
                        [4] = "LEFT", [5] = "CENTER", [6] = "RIGHT",
                        [7] = "BOTTOMLEFT", [8] = "BOTTOM", [9] = "BOTTOMRIGHT", [10] = "SCREEN"
                    },
                    get = function() return ClickToCastTooltip.db.global.tooltipAnchor end,
                    set = function(_, val) ClickToCastTooltip.db.global.tooltipAnchor = val end,
                    order = 10,
                },
                buttonColor = {
                    type = "color",
                    name = "Button Text Color",
                    desc = "Color for button text.",
                    hasAlpha = false,
                    get = function()
                        local c = ClickToCastTooltip.db.global.buttonColor
                        local r, g, b = tonumber("0x"..c:sub(3,4))/255, tonumber("0x"..c:sub(5,6))/255, tonumber("0x"..c:sub(7,8))/255
                        return r, g, b
                    end,
                    set = function(_, r, g, b)
                        ClickToCastTooltip.db.global.buttonColor = string.format("ff%02x%02x%02x", r*255, g*255, b*255)
                    end,
                    order = 30,
                },
                actionColor = {
                    type = "color",
                    name = "Action Text Color",
                    desc = "Color for action text.",
                    hasAlpha = false,
                    get = function()
                        local c = ClickToCastTooltip.db.global.actionColor
                        local r, g, b = tonumber("0x"..c:sub(3,4))/255, tonumber("0x"..c:sub(5,6))/255, tonumber("0x"..c:sub(7,8))/255
                        return r, g, b
                    end,
                    set = function(_, r, g, b)
                        ClickToCastTooltip.db.global.actionColor = string.format("ff%02x%02x%02x", r*255, g*255, b*255)
                    end,
                    order = 31,
                },
                dividerColor = {
                    type = "color",
                    name = "Divider Color",
                    desc = "Color for divider.",
                    hasAlpha = false,
                    get = function()
                        local c = ClickToCastTooltip.db.global.dividerColor
                        local r, g, b = tonumber("0x"..c:sub(3,4))/255, tonumber("0x"..c:sub(5,6))/255, tonumber("0x"..c:sub(7,8))/255
                        return r, g, b
                    end,
                    set = function(_, r, g, b)
                        ClickToCastTooltip.db.global.dividerColor = string.format("ff%02x%02x%02x", r*255, g*255, b*255)
                    end,
                    order = 32,
                }
            }
        },
        specs = {
            type = "group",
            name = "Classes",
            order = 1,
            desc = "Toggle which class specializations the custom tooltip should appear for.",
            args = {} -- will be filled dynamically
        },
        unitFrames = {
            type = "group",
            name = "Unit Frames",
            order = 2,
            desc = "Toggle which unit frame types should show the tooltip.",
            args = {
                unitFramesHeader = {
                    type = "header",
                    name = "Unit Frame Type Toggles",
                    order = 0,
                },
                unitFramesDescription = {
                    type = "description",
                    name = "Enable or disable the click-to-cast tooltip for specific unit frame types. This works for both Blizzard frames and addon frames.",
                    order = 1,
                },
                unitFramePlayer = {
                    type = "toggle",
                    width = "full",
                    name = "Player Frame",
                    desc = "Show tooltip when hovering over player frames.",
                    get = function() return ClickToCastTooltip.db.global.unitFramePlayer end,
                    set = function(_, val) ClickToCastTooltip.db.global.unitFramePlayer = val end,
                    order = 10,
                },
                unitFrameTarget = {
                    type = "toggle",
                    width = "full",
                    name = "Target Frame",
                    desc = "Show tooltip when hovering over target frames.",
                    get = function() return ClickToCastTooltip.db.global.unitFrameTarget end,
                    set = function(_, val) ClickToCastTooltip.db.global.unitFrameTarget = val end,
                    order = 11,
                },
                unitFrameFocus = {
                    type = "toggle",
                    width = "full",
                    name = "Focus Frame",
                    desc = "Show tooltip when hovering over focus frames.",
                    get = function() return ClickToCastTooltip.db.global.unitFrameFocus end,
                    set = function(_, val) ClickToCastTooltip.db.global.unitFrameFocus = val end,
                    order = 12,
                },
                unitFrameParty = {
                    type = "toggle",
                    width = "full",
                    name = "Party Frames",
                    desc = "Show tooltip when hovering over party member frames.",
                    get = function() return ClickToCastTooltip.db.global.unitFrameParty end,
                    set = function(_, val) ClickToCastTooltip.db.global.unitFrameParty = val end,
                    order = 13,
                },
                unitFrameRaid = {
                    type = "toggle",
                    width = "full",
                    name = "Raid Frames",
                    desc = "Show tooltip when hovering over raid member frames.",
                    get = function() return ClickToCastTooltip.db.global.unitFrameRaid end,
                    set = function(_, val) ClickToCastTooltip.db.global.unitFrameRaid = val end,
                    order = 14,
                },
                unitFrameBoss = {
                    type = "toggle",
                    width = "full",
                    name = "Boss Frames",
                    desc = "Show tooltip when hovering over boss frames.",
                    get = function() return ClickToCastTooltip.db.global.unitFrameBoss end,
                    set = function(_, val) ClickToCastTooltip.db.global.unitFrameBoss = val end,
                    order = 15,
                },
                unitFrameArena = {
                    type = "toggle",
                    width = "full",
                    name = "Arena Frames",
                    desc = "Show tooltip when hovering over arena enemy frames.",
                    get = function() return ClickToCastTooltip.db.global.unitFrameArena end,
                    set = function(_, val) ClickToCastTooltip.db.global.unitFrameArena = val end,
                    order = 16,
                },
                unitFramePet = {
                    type = "toggle",
                    width = "full",
                    name = "Pet Frames",
                    desc = "Show tooltip when hovering over pet frames (including party/raid pets).",
                    get = function() return ClickToCastTooltip.db.global.unitFramePet end,
                    set = function(_, val) ClickToCastTooltip.db.global.unitFramePet = val end,
                    order = 17,
                },
                unitFrameTargetOfTarget = {
                    type = "toggle",
                    width = "full",
                    name = "Target of Target Frames",
                    desc = "Show tooltip when hovering over target-of-target or focus-target frames.",
                    get = function() return ClickToCastTooltip.db.global.unitFrameTargetOfTarget end,
                    set = function(_, val) ClickToCastTooltip.db.global.unitFrameTargetOfTarget = val end,
                    order = 18,
                },
                unitFrameNPC = {
                    type = "toggle",
                    width = "full",
                    name = "NPC Frames",
                    desc = "Show tooltip when hovering over NPC unit frames (Cell addon).",
                    get = function() return ClickToCastTooltip.db.global.unitFrameNPC end,
                    set = function(_, val) ClickToCastTooltip.db.global.unitFrameNPC = val end,
                    order = 19,
                },
                resetUnitFrames = {
                    type = "execute",
                    name = "Enable All",
                    desc = "Enable tooltips for all unit frame types.",
                    func = function()
                        ClickToCastTooltip.db.global.unitFramePlayer = true
                        ClickToCastTooltip.db.global.unitFrameTarget = true
                        ClickToCastTooltip.db.global.unitFrameFocus = true
                        ClickToCastTooltip.db.global.unitFrameParty = true
                        ClickToCastTooltip.db.global.unitFrameRaid = true
                        ClickToCastTooltip.db.global.unitFrameBoss = true
                        ClickToCastTooltip.db.global.unitFrameArena = true
                        ClickToCastTooltip.db.global.unitFramePet = true
                        ClickToCastTooltip.db.global.unitFrameTargetOfTarget = true
                        ClickToCastTooltip.db.global.unitFrameNPC = true
                    end,
                    order = 30,
                },
            }
        },
        theme = {
            type = "group",
            name = "Theme",
            order = 3,
            desc = "Customize the appearance of the custom tooltip.",
            args = {
                themeHeader = {
                    type = "header",
                    name = "Custom Tooltip Theme",
                    order = 0,
                },
                themeDescription = {
                    type = "description",
                    name = "Customize the visual appearance of the custom floating tooltip. These settings only affect the custom tooltip shown at your mouse cursor, not the Blizzard tooltip.",
                    order = 1,
                },
                useElvUITheme = {
                    type = "toggle",
                    width = "full",
                    name = "Use ElvUI Theme (if detected)",
                    desc = "When ElvUI is installed, use its built-in tooltip styling instead of the custom theme settings below.",
                    get = function() return ClickToCastTooltip.db.global.useElvUITheme end,
                    set = function(_, val)
                        ClickToCastTooltip.db.global.useElvUITheme = val
                        if addonTable.applyTooltipTheme then
                            addonTable.applyTooltipTheme()
                        end
                    end,
                    hidden = function() return not (ElvUI and ElvUI[1]) end,
                    order = 2,
                },
                tooltipBackgroundColor = {
                    type = "color",
                    name = "Background Color",
                    desc = "Set the background color of the custom tooltip.",
                    hasAlpha = true,
                    get = function()
                        local c = ClickToCastTooltip.db.global.tooltipBackgroundColor
                        local a = tonumber("0x"..c:sub(1,2))/255
                        local r = tonumber("0x"..c:sub(3,4))/255
                        local g = tonumber("0x"..c:sub(5,6))/255
                        local b = tonumber("0x"..c:sub(7,8))/255
                        return r, g, b, a
                    end,
                    set = function(_, r, g, b, a)
                        ClickToCastTooltip.db.global.tooltipBackgroundColor = string.format("%02x%02x%02x%02x", a*255, r*255, g*255, b*255)
                        if addonTable.applyTooltipTheme then
                            addonTable.applyTooltipTheme()
                        end
                    end,
                    order = 10,
                },
                tooltipBorderColor = {
                    type = "color",
                    name = "Border Color",
                    desc = "Set the border color of the custom tooltip.",
                    hasAlpha = true,
                    get = function()
                        local c = ClickToCastTooltip.db.global.tooltipBorderColor
                        local a = tonumber("0x"..c:sub(1,2))/255
                        local r = tonumber("0x"..c:sub(3,4))/255
                        local g = tonumber("0x"..c:sub(5,6))/255
                        local b = tonumber("0x"..c:sub(7,8))/255
                        return r, g, b, a
                    end,
                    set = function(_, r, g, b, a)
                        ClickToCastTooltip.db.global.tooltipBorderColor = string.format("%02x%02x%02x%02x", a*255, r*255, g*255, b*255)
                        if addonTable.applyTooltipTheme then
                            addonTable.applyTooltipTheme()
                        end
                    end,
                    order = 11,
                },
                tooltipFontSize = {
                    type = "range",
                    name = "Font Size",
                    desc = "Set the font size for tooltip text.",
                    min = 8, max = 24, step = 1,
                    get = function() return ClickToCastTooltip.db.global.tooltipFontSize end,
                    set = function(_, val)
                        ClickToCastTooltip.db.global.tooltipFontSize = val
                        if addonTable.applyTooltipTheme then
                            addonTable.applyTooltipTheme()
                        end
                    end,
                    order = 20,
                },
                tooltipScale = {
                    type = "range",
                    name = "Tooltip Scale",
                    desc = "Set the overall scale of the custom tooltip.",
                    min = 0.5, max = 2.0, step = 0.05,
                    get = function() return ClickToCastTooltip.db.global.tooltipScale end,
                    set = function(_, val)
                        ClickToCastTooltip.db.global.tooltipScale = val
                        if addonTable.applyTooltipTheme then
                            addonTable.applyTooltipTheme()
                        end
                    end,
                    order = 21,
                },
                tooltipPadding = {
                    type = "range",
                    name = "Padding",
                    desc = "Set the internal padding of the tooltip.",
                    min = 0, max = 20, step = 1,
                    get = function() return ClickToCastTooltip.db.global.tooltipPadding end,
                    set = function(_, val)
                        ClickToCastTooltip.db.global.tooltipPadding = val
                        if addonTable.applyTooltipTheme then
                            addonTable.applyTooltipTheme()
                        end
                    end,
                    order = 22,
                },
                tooltipSquareCorners = {
                    type = "toggle",
                    name = "Square Corners",
                    desc = "Use square corners instead of rounded corners on the tooltip.",
                    get = function() return ClickToCastTooltip.db.global.tooltipSquareCorners end,
                    set = function(_, val)
                        ClickToCastTooltip.db.global.tooltipSquareCorners = val
                        if addonTable.applyTooltipTheme then
                            addonTable.applyTooltipTheme()
                        end
                    end,
                    order = 23,
                },
                tooltipBackgroundTexture = {
                    type = "select",
                    name = "Background Texture",
                    desc = "Choose the background texture for the tooltip.",
                    values = {
                        [1] = "Default Tooltip",
                        [2] = "Solid",
                        [3] = "Blizzard Dialog",
                        [4] = "Parchment",
                        [5] = "Dark Stone",
                    },
                    get = function() return ClickToCastTooltip.db.global.tooltipBackgroundTexture end,
                    set = function(_, val)
                        ClickToCastTooltip.db.global.tooltipBackgroundTexture = val
                        if addonTable.applyTooltipTheme then
                            addonTable.applyTooltipTheme()
                        end
                    end,
                    order = 24,
                },
                tooltipBorderTexture = {
                    type = "select",
                    name = "Border Texture",
                    desc = "Choose the border texture for the tooltip.",
                    values = {
                        [1] = "Default Tooltip",
                        [2] = "Solid (1px)",
                        [3] = "Blizzard Dialog",
                        [4] = "Gold",
                        [5] = "None",
                    },
                    get = function() return ClickToCastTooltip.db.global.tooltipBorderTexture end,
                    set = function(_, val)
                        ClickToCastTooltip.db.global.tooltipBorderTexture = val
                        if addonTable.applyTooltipTheme then
                            addonTable.applyTooltipTheme()
                        end
                    end,
                    order = 25,
                },
                resetTheme = {
                    type = "execute",
                    name = "Reset Theme",
                    desc = "Reset all theme settings to their default values.",
                    func = function()
                        ClickToCastTooltip.db.global.tooltipBackgroundColor = defaults.global.tooltipBackgroundColor
                        ClickToCastTooltip.db.global.tooltipBorderColor = defaults.global.tooltipBorderColor
                        ClickToCastTooltip.db.global.tooltipFontSize = defaults.global.tooltipFontSize
                        ClickToCastTooltip.db.global.tooltipScale = defaults.global.tooltipScale
                        ClickToCastTooltip.db.global.tooltipPadding = defaults.global.tooltipPadding
                        ClickToCastTooltip.db.global.tooltipSquareCorners = defaults.global.tooltipSquareCorners
                        ClickToCastTooltip.db.global.tooltipBackgroundTexture = defaults.global.tooltipBackgroundTexture
                        ClickToCastTooltip.db.global.tooltipBorderTexture = defaults.global.tooltipBorderTexture
                        ClickToCastTooltip.db.global.useElvUITheme = defaults.global.useElvUITheme
                        if addonTable.applyTooltipTheme then
                            addonTable.applyTooltipTheme()
                        end
                    end,
                    order = 30,
                },
            }
        },
        resetColors = {
            type = "execute",
            name = "Reset Colors",
            desc = "Reset the colors to their default values.",
            func = function()
                ClickToCastTooltip.db.global.buttonColor = defaults.global.buttonColor
                ClickToCastTooltip.db.global.actionColor = defaults.global.actionColor
                ClickToCastTooltip.db.global.dividerColor = defaults.global.dividerColor
            end,
            order = 33,
        },
            resetCheckboxes = {
                type = "execute",
                name = "Reset All Checkboxes",
                desc = "Reset all checkboxes to their default values, including all specs.",
                func = function()
                    -- Reset main checkboxes
                    ClickToCastTooltip.db.global.showTooltip = true
                    ClickToCastTooltip.db.global.showCustomTooltip = true
                    ClickToCastTooltip.db.global.showHeader = false
                    ClickToCastTooltip.db.global.showFooter = false
                    ClickToCastTooltip.db.global.showNewLineTop = false
                    ClickToCastTooltip.db.global.showNewLineBottom = false
                    -- Reset all spec toggles to true
                    for classID = 1, 13 do
                        local numSpecs = C_SpecializationInfo.GetNumSpecializationsForClassID(classID)
                        for i = 1, numSpecs do
                            local specID = select(1, GetSpecializationInfoForClassID(classID, i))
                            ClickToCastTooltip.db.global["specToggle_" .. specID] = true
                        end
                    end
                end,
                order = 34,
            },
    }
}

local function AddSpecToggles()
    local classNames = {
        [1] = "Warrior", [2] = "Paladin", [3] = "Hunter", [4] = "Rogue", [5] = "Priest", [6] = "Death Knight",
        [7] = "Shaman", [8] = "Mage", [9] = "Warlock", [10] = "Monk", [11] = "Druid", [12] = "Demon Hunter", [13] = "Evoker"
    }
    for classID = 1, 13 do
        local className = classNames[classID] or ("Class " .. classID)
        local numSpecs = C_SpecializationInfo.GetNumSpecializationsForClassID(classID)
        for i = 1, numSpecs do
            local specID, specName, _, icon = GetSpecializationInfoForClassID(classID, i)
            local key = "specToggle_" .. specID
            options.args.specs.args[key] = {
                type = "toggle",
                name = className .. ": " .. specName,
                icon = "Interface\\ICONS\\" .. icon,
                get = function() return ClickToCastTooltip.db.global[key] end,
                set = function(_, val) ClickToCastTooltip.db.global[key] = val end,
                order = specID,
            }
            if ClickToCastTooltip.db.global[key] == nil then
                ClickToCastTooltip.db.global[key] = true
            end
        end
    end
end

function ClickToCastTooltip:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("ClickToCastTooltipDB", defaults, true)
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options)
    ClickToCastTooltip.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addonName)
    local CURRENT_VERSION = "2.0"
    local savedVersion = self.db.global.addonVersion or "0"
    if tonumber(savedVersion) == nil or tonumber(savedVersion) < 2.0 then
        self.db:ResetDB("Default")
        self.db.global.addonVersion = CURRENT_VERSION
        print("Click-To-Cast-Tooltip settings have been reset for version 2.0+.")
    end
    AddSpecToggles()
end

function ClickToCastTooltip:OnEnable()
    -- Load defaults if not already set
    for k, v in pairs(defaults.global) do
        if self.db.global[k] == nil then
            self.db.global[k] = v
        end
    end
    
    -- Check for Clique and show popup if needed
    self:CheckForCliqueAndShowPopup()
end

function ClickToCastTooltip:CheckForCliqueAndShowPopup()
    -- Only show popup once and only if Clique is installed
    ---@diagnostic disable-next-line: undefined-global
    if not self.db.global.hasShownCliquePopup and Clique then
        -- Delay popup to ensure UI is ready
        C_Timer.After(2, function()
            self:ShowCliquePopup()
        end)
    end
end

-- Define the StaticPopup for Clique detection
StaticPopupDialogs["CLICK_TO_CAST_TOOLTIP_CLIQUE_DETECTED"] = {
    text = "Clique addon detected! Since you're using Clique for click-to-cast, would you like to disable the display of Blizzard's native click-to-cast bindings?\n\nThis will show only your Clique bindings in the tooltip, avoiding duplicate information.",
    button1 = "Yes, disable Blizzard bindings",
    button2 = "No, keep both",
    OnAccept = function()
        ClickToCastTooltip.db.global.showBlizzardBindings = false
        ClickToCastTooltip.db.global.hasShownCliquePopup = true
        print("|cff00ff00Click-To-Cast-Tooltip:|r Blizzard bindings disabled. You can re-enable them in the addon settings if needed.")
    end,
    OnCancel = function()
        ClickToCastTooltip.db.global.hasShownCliquePopup = true
        print("|cff00ff00Click-To-Cast-Tooltip:|r Keeping both Blizzard and Clique bindings enabled.")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function ClickToCastTooltip:ShowCliquePopup()
    StaticPopup_Show("CLICK_TO_CAST_TOOLTIP_CLIQUE_DETECTED")
end

SLASH_CLICKTOCASTTT1 = "/clicktocasttooltip"
SLASH_CLICKTOCASTTT2 = "/ctctt"
SlashCmdList["CLICKTOCASTTT"] = function()
    LibStub("AceConfigDialog-3.0"):Open(addonName)
end
