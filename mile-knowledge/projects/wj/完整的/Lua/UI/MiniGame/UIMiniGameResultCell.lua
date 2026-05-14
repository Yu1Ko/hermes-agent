-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMiniGameResultCell
-- Date: 2025-09-25 19:37:59
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIMiniGameResultCell = class("UIMiniGameResultCell")

function UIMiniGameResultCell:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szText = tInfo.szText or ""
    self.szValue = tInfo.szValue or ""
    self.bFinish = tInfo.bFinish or false
    self:UpdateInfo()
end

function UIMiniGameResultCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMiniGameResultCell:BindUIEvent()
    
end

function UIMiniGameResultCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIMiniGameResultCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMiniGameResultCell:UpdateInfo()
    UIHelper.SetString(self.LabelSettlementContent, UIHelper.GBKToUTF8(self.szText))
    UIHelper.SetString(self.LabelScore, UIHelper.GBKToUTF8(self.szValue))
    UIHelper.SetVisible(self.WidgetDone, self.bFinish)
    UIHelper.SetVisible(self.WidgetLose, not self.bFinish)
    UIHelper.LayoutDoLayout(self.LayoutContentScore)
end


return UIMiniGameResultCell