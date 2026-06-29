-- WoWLegends_GM/UI/ToggleButton.lua
-- Draggable launcher button. Click → toggle panel. SHIFT-drag → reposition.

local addonName, WLGM = ...

local SIZE = 32

function WLGM.Toggle()
    local f = WoWLegendsGM_MainFrame
    if not f then
        WLGM.Warn("main frame not created — run /wlgm debug.")
        return
    end
    if f:IsShown() then f:Hide() else f:Show(); f:Raise() end
end

local function createToggleButton()
    local b = CreateFrame("Button", "WoWLegendsGM_ToggleButton", UIParent)
    b:SetSize(SIZE, SIZE)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    b:SetMovable(true)
    b:SetClampedToScreen(true)
    b:EnableMouse(true)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")

    local icon = b:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_03")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", b, "CENTER", 0, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    if icon.SetMask then icon:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask") end

    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("CENTER", b, "CENTER", 11, -11)

    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")

    b:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() then self:StartMoving(); self.isMoving = true end
    end)
    b:SetScript("OnDragStop", function(self)
        if self.isMoving then
            self:StopMovingOrSizing(); self.isMoving = false
            WLGM.SaveFramePoint(self, "button")
        end
    end)
    b:SetScript("OnClick", function() WLGM.Toggle() end)

    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("WoW Legends GM", 1, 0.79, 0.30)
        GameTooltip:AddLine("Click to toggle the GM panel.", 1, 1, 1)
        GameTooltip:AddLine("SHIFT-drag to move this button.", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("/wlgm reset to recenter everything.", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    b:Show()
    return b
end

function WLGM.RestoreButtonPosition()
    if WoWLegendsGM_ToggleButton then
        WLGM.RestoreFramePoint(WoWLegendsGM_ToggleButton, "button", WLGM.defaults.button)
    end
end

WLGM.AddLogin(function()
    if not WoWLegendsGM_ToggleButton then createToggleButton() end
    WLGM.RestoreButtonPosition()
    if WLGM.db and WLGM.db.minimap and WLGM.db.minimap.hide then
        WoWLegendsGM_ToggleButton:Hide()
    end
end)
