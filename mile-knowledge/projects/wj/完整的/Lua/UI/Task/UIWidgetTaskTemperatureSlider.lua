-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetTaskTemperatureSlider
-- Date: 2023-02-24 14:29:16
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetTaskTemperatureSlider = class("UIWidgetTaskTemperatureSlider")

function UIWidgetTaskTemperatureSlider:OnEnter(szTitle, szValue, nPercent, nWordLimit)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    UIHelper.SetTouchEnabled(self.SliderTarget, false)
    self:UpdateInfo(szTitle, szValue, nPercent, nWordLimit)
end

function UIWidgetTaskTemperatureSlider:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetTaskTemperatureSlider:BindUIEvent()
    
end

function UIWidgetTaskTemperatureSlider:RegEvent()

end

function UIWidgetTaskTemperatureSlider:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTaskTemperatureSlider:UpdateInfo(szTitle, szValue, nPercent, nWordLimit)
    UIHelper.SetString(self.LabelOtherTarget, UIHelper.GBKToUTF8(szTitle), nWordLimit)
    UIHelper.SetProgressBarPercent(self.SliderTarget, nPercent)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end


return UIWidgetTaskTemperatureSlider