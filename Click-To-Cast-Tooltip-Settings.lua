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
    width = "half",
    args = {
        showTooltip = {
            type = "toggle",
            name = "Show on Blizzard tooltip",
            desc = "Show the click to cast binding when hovering over a unit frame.",
            get = function() return ClickToCastTooltip.db.global.showTooltip end,
            set = function(_, val) ClickToCastTooltip.db.global.showTooltip = val end,
            order = 1,
        },
        showCustomTooltip = {
            type = "toggle",
            name = "Show custom tooltip at mouse",
            desc = "Show the custom tooltip at the mouse cursor when hovering over a unit frame.",
            get = function() return ClickToCastTooltip.db.global.showCustomTooltip end,
            set = function(_, val) ClickToCastTooltip.db.global.showCustomTooltip = val end,
            order = 2,
        },
        showHeader = {
            type = "toggle",
            name = "Show dashed header above the tooltip.",
            desc = "Show the dashed line header on the tooltip.",
            get = function() return ClickToCastTooltip.db.global.showHeader end,
            set = function(_, val) ClickToCastTooltip.db.global.showHeader = val end,
            order = 3,
        },
        showFooter = {
            type = "toggle",
            name = "Show dashed footer below the tooltip.",
            desc = "Show the dashed line footer on the tooltip.",
            get = function() return ClickToCastTooltip.db.global.showFooter end,
            set = function(_, val) ClickToCastTooltip.db.global.showFooter = val end,
            order = 4,
        },
        showNewLineTop = {
            type = "toggle",
            name = "Show new line above the tooltip.",
            desc = "Show a new line at the top of the tooltip.",
            get = function() return ClickToCastTooltip.db.global.showNewLineTop end,
            set = function(_, val) ClickToCastTooltip.db.global.showNewLineTop = val end,
            order = 5,
        },
        showNewLineBottom = {
            type = "toggle",
            name = "Show new line below the tooltip.",
            desc = "Show a new line at the bottom of the tooltip.",
            get = function() return ClickToCastTooltip.db.global.showNewLineBottom end,
            set = function(_, val) ClickToCastTooltip.db.global.showNewLineBottom = val end,
            order = 6,
        },
        tooltipTransparency = {
            type = "range",
            name = "Custom Tooltip Transparency",
            desc = "Set the transparency of the custom tooltip (0 = fully transparent, 1 = fully opaque).",
            min = 0, max = 1, step = 0.01,
            get = function() return ClickToCastTooltip.db.global.tooltipTransparency end,
            set = function(_, val) ClickToCastTooltip.db.global.tooltipTransparency = val end,
            order = 7,
        },
        tooltipAnchor = {
            type = "select",
            name = "Custom Tooltip Anchor",
            desc = "Choose where the custom tooltip is anchored.",
            values = {
                [1] = "TOPLEFT", [2] = "TOP", [3] = "TOPRIGHT",
                [4] = "LEFT", [5] = "CENTER", [6] = "RIGHT",
                [7] = "BOTTOMLEFT", [8] = "BOTTOM", [9] = "BOTTOMRIGHT", [10] = "SCREEN"
            },
            get = function() return ClickToCastTooltip.db.global.tooltipAnchor end,
            set = function(_, val) ClickToCastTooltip.db.global.tooltipAnchor = val end,
            order = 8,
        },
        specs = {
            type = "group",
            name = "Mouse Cursor Tooltip Allow For Classes",
            inline = true,
            order = 20,
            args = {} -- will be filled dynamically
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
end

SLASH_CLICKTOCASTTT1 = "/clicktocasttooltip"
SLASH_CLICKTOCASTTT2 = "/ctctt"
SlashCmdList["CLICKTOCASTTT"] = function()
    Settings.OpenToCategory(addonName)
end
