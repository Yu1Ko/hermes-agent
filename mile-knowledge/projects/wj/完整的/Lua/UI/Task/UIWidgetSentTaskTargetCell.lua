-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSentTaskTargetCell
-- Date: 2023-10-19 17:21:08
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetSentTaskTargetCell = class("UIWidgetSentTaskTargetCell")

function UIWidgetSentTaskTargetCell:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UIWidgetSentTaskTargetCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSentTaskTargetCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnChase, EventType.OnClick, function()
        self.tbInfo.callBack()
    end)
end

function UIWidgetSentTaskTargetCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetSentTaskTargetCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSentTaskTargetCell:UpdateInfo()
    local szText = self.tbInfo.szText 
    szText = string.gsub(szText, "^[　　]+", "")
    UIHelper.SetString(self.LabelTarget, szText)

    UIHelper.SetVisible(self.BtnChase, self.tbInfo.bHasMap)
end


return UIWidgetSentTaskTargetCell