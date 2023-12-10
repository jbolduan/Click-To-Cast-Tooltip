local addonName, addonTable = ...

local f = CreateFrame("Frame")

-- These are the default settings for new installs of the addon.
local defaults = {
    buttonColor = {
        r = 1,
        g = 0,
        b = 0,
        a = 1
    },
    actionColor = {
        r = 0,
        g = 1,
        b = 0,
        a = 1
    },
    showHeader = true
}

-- Check to see if the SavedVariables are already set, if not, set them to the defaults.
function f:OnEvent(event, addOnName)
    if addOnName == "Click-To-Cast-Tooltip" then
        ClickToCastTooltipDB = ClickToCastTooltipDB or CopyTable(defaults)
        addonTable.db = ClickToCastTooltipDB

        -- If any of the default settings are missing, copy them over.
        if (addonTable.db.buttonColor == nil) then
            addonTable.db.buttonColor = CopyTable(defaults.buttonColor)
        end
        if (addonTable.db.actionColor == nil) then
            addonTable.db.actionColor = CopyTable(defaults.actionColor)
        end
        if (addonTable.db.showHeader ~= true and addonTable.db.showHeader ~= false) then
            addonTable.db.showHeader = defaults.showHeader
        end

        self:InitializeOptions()
    end
end

-- Register the event to check for the addon being loaded.
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", f.OnEvent)

-- Create the options panel for the addon.
function f:InitializeOptions()
    self.panel = CreateFrame("Frame")
    self.panel.name = "Click-To-Cast-Tooltip"

    -- Create a checkbox which will allow the user to toggle the header on the tooltip.
    local showHeader = CreateFrame("CheckButton", nil, self.panel, "InterfaceOptionsCheckButtonTemplate")
    showHeader:SetPoint("TOPLEFT", 20, -20)
    showHeader.Text:SetText("Show header with divider")
    showHeader:HookScript("OnClick", function(_, btn, down)
        addonTable.db.showHeader = showHeader:GetChecked()
    end)
    showHeader:SetChecked(addonTable.db.showHeader)

    -- Create a button which will allow the user to change the color of the button text.
    local buttonColorPicker = CreateFrame("Button", nil, self.panel, "UIPanelButtonTemplate")
    buttonColorPicker:SetPoint("TopLeft", showHeader, "TopLeft", 20, -30)
    buttonColorPicker:SetSize(100, 25)
    buttonColorPicker:SetText("Button Text Color")
    buttonColorPicker:SetScript("OnClick", function()
        ShowColorPicker(addonTable.db.buttonColor.r, addonTable.db.buttonColor.g, addonTable.db.buttonColor.b,
            addonTable.db.buttonColor.a, ColorCallback)
    end)

    -- Create a button which will allow the user to change the color of the action text.
    local actionColorPicker = CreateFrame("Button", nil, self.panel, "UIPanelButtonTemplate")
    actionColorPicker:SetPoint("TopLeft", buttonColorPicker, "TopLeft", 0, -30)
    actionColorPicker:SetSize(100, 25)
    actionColorPicker:SetText("Action Text Color")
    actionColorPicker:SetScript("OnClick", function()
        ShowColorPicker(addonTable.db.actionColor.r, addonTable.db.actionColor.g, addonTable.db.actionColor.b,
            addonTable.db.actionColor.a, ColorCallback)
    end)

    -- Create a button which will allow the user to reset the settings to the default values.
    local resetSettings = CreateFrame("Button", nil, self.panel, "UIPanelButtonTemplate")
    resetSettings:SetPoint("TopLeft", actionColorPicker, "TopLeft", 0, -30)
    resetSettings:SetSize(100, 25)
    resetSettings:SetText("Reset Settings")
    resetSettings:SetScript("OnClick", function()
        addonTable.db = CopyTable(defaults)
    end)

    InterfaceOptions_AddCategory(self.panel)
end

-- Shows the color picker with the callback function
function ShowColorPicker(r, g, b, a, changedCallback)
    ColorPickerFrame.hasOpacity, ColorPickerFrame.opacity = (a ~= nil), a
    ColorPickerFrame.previousValues = {r, g, b, a}
    ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = changedCallback, changedCallback,
        changedCallback
    ColorPickerFrame:SetColorRGB(r, g, b)
    ColorPickerFrame:Hide() -- Need to run the OnShow handler.
    ColorPickerFrame:Show()
end

-- Callback function to protect the color picker from no selection being made
function ColorCallback(restore)
    local newR, newG, newB, newA
    if restore then
        -- The user bailed , we extreact the old color from the table created by ShowColorPicker.
        newR, newG, newB, newA = unpack(restore)
    else
        -- Something changed
        newA, newR, newG, newB = OpacitySliderFrame:GetValue(), ColorPickerFrame:GetColorRGB()
    end

    addonTable.db.buttonColor.r, addonTable.db.buttonColor.g, addonTable.db.buttonColor.b, addonTable.db.buttonColor.a =
        newR, newG, newB, newA
    -- Update UI elements
end

-- Add the supported slash commands
SLASH_CLICKTOCASTTT1 = "/clicktocasttooltip"
SLASH_CLICKTOCASTTT2 = "/ctctt"

-- Handle the slash commands
SlashCmdList["CLICKTOCASTTT"] = function(msg)
    if msg == "buttonColor" then
        ShowColorPicker(addonTable.db.buttonColor.r, addonTable.db.buttonColor.g, addonTable.db.buttonColor.b,
            addonTable.db.buttonColor.a, ColorCallback)
    elseif msg == "currentButtonColor" then
        print("Current Color: " .. addonTable.db.buttonColor.r .. ", " .. addonTable.db.buttonColor.g .. ", " ..
                  addonTable.db.buttonColor.b .. ", " .. addonTable.db.buttonColor.a)
    elseif msg == "actionColor" then
        ShowColorPicker(addonTable.db.actionColor.r, addonTable.db.actionColor.g, addonTable.db.actionColor.b,
            addonTable.db.actionColor.a, ColorCallback)
    elseif msg == "currentActionColor" then
        print("Current Color: " .. addonTable.db.actionColor.r .. ", " .. addonTable.db.actionColor.g .. ", " ..
                  addonTable.db.actionColor.b .. ", " .. addonTable.db.actionColor.a)
    elseif msg == "help" then
        print("Click-To-Cast-Tooltip")
        print("/ctctt buttonColor - Opens the color picker for the button text color")
        print("/ctctt currentButtonColor - Prints the current button text color")
        print("/ctctt actionColor - Opens the color picker for the action text color")
        print("/ctctt currentActionColor - Prints the current action text color")
    else
        InterfaceOptionsFrame_OpenToCategory(f.panel)
    end
end
