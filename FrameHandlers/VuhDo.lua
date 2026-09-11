local _, addonTable = ...

-- ============================================================================
-- VuhDo Frame Handler
-- Hooks VuhDo unit frames when the addon is loaded
-- ============================================================================

local FrameHooker = addonTable.FrameHooker

local VuhDoHandler = {
    name = "VuhDo"
}

--- Checks if VuhDo is loaded and available
-- @return boolean: True if VuhDo is detected
function VuhDoHandler:IsEnabled()
    if type(_G["VuhDo"]) == "table" then
        return true
    end

    if type(_G["VUHDO_CONFIG"]) == "table" then
        return true
    end

    if type(_G["VUHDO_PANEL_SETUP"]) == "table" then
        return true
    end

    return _G["Vd1H1"] ~= nil
end

--- Scans and hooks all VuhDo unit frames
-- VuhDo creates globals of the form Vd<PANEL>H<HEADER>, plus target/target-of-target variants.
-- @param tooltipBuilder function: Called on OnEnter
-- @param tooltipDestroyer function: Called on OnLeave
function VuhDoHandler:ScanAndHook(tooltipBuilder, tooltipDestroyer)
    if not self:IsEnabled() then return end

    for frameName in pairs(_G) do
        if type(frameName) == "string" then
            if frameName:match("^Vd%d+H%d+$")
                or frameName:match("^Vd%d+H%d+Tg$")
                or frameName:match("^Vd%d+H%d+Tot$") then
                FrameHooker:HookFrame(frameName, tooltipBuilder, tooltipDestroyer, false)
            end
        end
    end
end

-- Register with the handler registry
addonTable.HandlerRegistry:Register(VuhDoHandler)
