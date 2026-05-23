-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSliderOtherDescribe
-- Date: 2023-02-24 14:29:16
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetSliderOtherDescribe = class("UIWidgetSliderOtherDescribe")

function UIWidgetSliderOtherDescribe:OnEnter(szTitle, szValue, nPercent, nWordLimit, bShowProgress)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(szTitle, szValue, nPercent, nWordLimit, bShowProgress)
end

function UIWidgetSliderOtherDescribe:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSliderOtherDescribe:BindUIEvent()
    
end

function UIWidgetSliderOtherDescribe:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetSliderOtherDescribe:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSliderOtherDescribe:UpdateInfo(szTitle, szValue, nPercent, nWordLimit, bShowProgress)
    local nLimit = nWordLimit or 9
    if bShowProgress == nil then bShowProgress = true end
    UIHelper.SetString(self.LabelOtherTarget, UIHelper.GBKToUTF8(szTitle), nLimit)
    UIHelper.SetString(self.LabelOtherTargetProgress, szValue)

    UIHelper.SetVisible(self.LabelOtherTargetProgress, bShowProgress)
    if nPercent then
        UIHelper.SetVisible(self.SliderTarget, true)
        UIHelper.SetVisible(self.TargetBarBG, true)
        UIHelper.SetProgressBarPercent(self.SliderTarget, nPercent)
    else
        UIHelper.SetVisible(self.SliderTarget, false)
        UIHelper.SetVisible(self.TargetBarBG, false)
    end
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function UIWidgetSliderOtherDescribe:SetTitleFontSize(nFontSize)
    UIHelper.SetFontSize(self.LabelOtherTarget, nFontSize)
end

function UIWidgetSliderOtherDescribe:SetValueFontSize(nFontSize)
    UIHelper.SetFontSize(self.LabelOtherTargetProgress, nFontSize)
end

return UIWidgetSliderOtherDescribe