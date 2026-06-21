-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetHintSfx
-- Date: 2024-03-25 14:44:55
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetHintSfx = class("UIWidgetHintSfx")

function UIWidgetHintSfx:OnEnter(dwID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwID = dwID
    self:UpdateInfo()
end

function UIWidgetHintSfx:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetHintSfx:BindUIEvent()
    
end

function UIWidgetHintSfx:RegEvent()
    
    Event.Reg(self, EventType.OnShieldTip, function(szEvent, tbData)
        local bClose = tbData.bClose
        if bClose then
            -- self[string.format("Close", ...)]()--关闭
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
end

function UIWidgetHintSfx:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetHintSfx:UpdateInfo()
    local tbInfo = Table_GetPopupRemindInfo(self.dwID)
    local szSfx = tbInfo.szSfxPath
    UIHelper.SetSFXPath(self.SfxNormal, szSfx)
    
    self.bShowSFX = true
    self:UpdateShowHintSFXVis()

    if self.nTimer then 
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end

    self.nTimer = Timer.Add(self, tbInfo.nTime, function()
        self.bShowSFX = false
        self:UpdateShowHintSFXVis()
    end)
end

function UIWidgetHintSfx:UpdateShowHintSFXVis()
    local bVis = not TipsHelper.IsTipShield(EventType.ShowHintSFX) and self.bShowSFX
    UIHelper.SetVisible(self._rootNode, bVis)
end

return UIWidgetHintSfx