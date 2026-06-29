-- WoWLegends_GM/UI/ConfirmDialog.lua
-- One confirm popup shared by every danger=true command.

local addonName, WLGM = ...

StaticPopupDialogs["WLGM_CONFIRM_CMD"] = {
    text = "|cffffc94dWoW Legends GM|r\n\nRun this command?\n\n|cffffd100%s|r",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self)
        local line = self.data
        if line and line ~= "" then WLGM._ExecuteRaw(line) end
    end,
    OnShow = function(self) end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,   -- avoid UIParent taint on 3.3.5a
    showAlert = true,
}
