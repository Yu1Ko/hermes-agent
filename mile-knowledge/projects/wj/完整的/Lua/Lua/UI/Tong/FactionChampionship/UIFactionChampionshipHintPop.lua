-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: PanelFactionChampionshipHintPop
-- Date: 2025-07-25 10:58:02
-- Desc: ?
-- ---------------------------------------------------------------------------------

local PanelFactionChampionshipHintPop = class("PanelFactionChampionshipHintPop")

function PanelFactionChampionshipHintPop:OnEnter(dwID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwID = dwID
    self:UpdateInfo()
    UIHelper.PlayAni(self, self.AniAll, "AniFactionChampionshipHintPopShow")
end

function PanelFactionChampionshipHintPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function PanelFactionChampionshipHintPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnGo, EventType.OnClick, function()
        if self.szLink and self.szLink ~= "" then
            Event.Dispatch("EVENT_LINK_NOTIFY", self.szLink)
            UIMgr.Close(self)
        end
    end)
end

function PanelFactionChampionshipHintPop:RegEvent()
    Event.Reg(self, EventType.OnShieldTip, function(szEvent, tbData)
        local bClose = tbData.bClose
        if bClose then
            -- self[string.format("Close", ...)]()--??
        else
            local func = self[string.format("Update%sVis", szEvent)]
            if func then func(self) end
        end
    end)

    Event.Reg(self, EventType.OnUnShieldTip, function(szEvent, bClose)
        if not bClose then
            local func = self[string.format("Update%sVis", szEvent)]
            if func then func(self) end
        end
    end)
    --Event.Reg(self, EventType.XXX, func)
end

function PanelFactionChampionshipHintPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ¡ý¡ý¡ý
-- ----------------------------------------------------------

function PanelFactionChampionshipHintPop:UpdateInfo()
    local tInfo = Table_GetPopupRemindInfo(self.dwID)
    local szSfx  = tInfo.szSfxPath
    local szLink = tInfo.szLink

    self.szLink = szLink
    UIHelper.SetSFXPath(self.Widget_Eff, szSfx)
    self.bShowSFX = true
    self:UpdateShowHintSFXVis()
    self.nCloseTime = GetCurrentTime() + tInfo.nTime
    if self.nTimer then 
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end

    self.nTimer = Timer.AddCycle(self, 1, function ()
        self:UpdateLeftTime()
        local nLeftTime = self.nCloseTime - GetCurrentTime()
        if nLeftTime < 0 then
            UIMgr.Close(self)
        end
    end)
end

function PanelFactionChampionshipHintPop:UpdateLeftTime()
    local nLeftTime = self.nCloseTime - GetCurrentTime()
    if nLeftTime <= 0 then
        nLeftTime = 0
    end

    if not self.szLabelText then
        self.szLabelText = UIHelper.GetString(self.LabelContentGo)
    end
    UIHelper.SetString(self.LabelContentGo, string.format("%s(%d)", self.szLabelText, nLeftTime))
end

function PanelFactionChampionshipHintPop:UpdateShowHintSFXVis()
    local bVis = not TipsHelper.IsTipShield(EventType.ShowHintSFX) and self.bShowSFX
    UIHelper.SetVisible(self._rootNode, bVis)
end

return PanelFactionChampionshipHintPop