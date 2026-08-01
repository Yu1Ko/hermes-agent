-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSettingsVolume
-- Date: 2022-12-20 14:55:04
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetSettingsSlider = class("UIWidgetSettingsSlider")

function UIWidgetSettingsSlider:OnEnter(tbSettingsCell, nCurrentValue, fnEndCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    --local fSliderValue = nCurrentSliderValue or 1

    self.tbSettingsCell = tbSettingsCell
    self.nMinVal = tbSettingsCell.nMinVal or 0
    self.nMaxWidth = UIHelper.GetWidth(self.SliderAdjustment)
    self.nMaxVal = GetGameSettingMaxVal(tbSettingsCell) or 100
    self.nCurrentValue = nCurrentValue
    self.fnValueFormat = tbSettingsCell.fnFormat or function(nVal)
        return nVal
    end
    self.fnEndCallback = fnEndCallback
    self.fnEnable = tbSettingsCell.fnEnable
    self.bShouldCeil = true
    if tbSettingsCell.bShouldCeil ~= nil then
        self.bShouldCeil = tbSettingsCell.bShouldCeil
    end

    self:UpdateProgress()
end

function UIWidgetSettingsSlider:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSettingsSlider:BindUIEvent()
    UIHelper.BindUIEvent(self.SliderAdjustment, EventType.OnChangeSliderPercent, function(SliderEventType, nSliderEvent)
        if nSliderEvent == ccui.SliderEventType.slideBallDown then
            self.bSliding = true
        elseif nSliderEvent == ccui.SliderEventType.slideBallUp then
            self.bSliding = false
            -- 强制修正滑块进度
            local nPercent = (self.nCurrentValue - self.nMinVal) / (self.nMaxVal - self.nMinVal) * 100
            UIHelper.SetProgressBarPercent(self.SliderAdjustment, nPercent)
            UIHelper.SetWidth(self.ImgVolumeAdjustment, nPercent * self.nMaxWidth / 100)
            if self.fnEndCallback then
                self.fnEndCallback(self.nCurrentValue, self.nMaxVal, self.nMinVal)
            end

            LOG.WARN("OnChangeSliderPercent %d", UIHelper.GetProgressBarPercent(self.SliderAdjustment))
        end

        if self.bSliding then
            local nPercent = UIHelper.GetProgressBarPercent(self.SliderAdjustment)
            self.nCurrentValue = nPercent / 100 * (self.nMaxVal - self.nMinVal) + self.nMinVal
            self.nCurrentValue = math.min(self.nCurrentValue, self.nMaxVal)
            self.nCurrentValue = math.max(self.nCurrentValue, self.nMinVal)
            self.nCurrentValue = self.bShouldCeil and math.ceil(self.nCurrentValue) or self.nCurrentValue
            UIHelper.SetString(self.LabelNum, self.fnValueFormat(self.nCurrentValue))
            UIHelper.SetWidth(self.ImgVolumeAdjustment, nPercent * self.nMaxWidth / 100)
        end
    end)

    Event.Reg(self, EventType.OnChangeToCustomQuality, function()
        self.nMaxVal = GetGameSettingMaxVal(self.tbSettingsCell) or 100 -- 进入自定义状态时滑动条最大值可能发生变化，重新获取最大值
        self:UpdateProgress()
    end)
end

function UIWidgetSettingsSlider:RegEvent()

end

function UIWidgetSettingsSlider:UnRegEvent()
    Event.UnRegAll(self)
end

function UIWidgetSettingsSlider:SetName(szName)
    UIHelper.SetString(self.LabelName, szName)
end

function UIWidgetSettingsSlider:UpdateProgress()
    UIHelper.SetString(self.LabelNum, self.fnValueFormat(self.nCurrentValue))
    local nPercent = (self.nCurrentValue - self.nMinVal) / (self.nMaxVal - self.nMinVal) * 100
    UIHelper.SetProgressBarPercent(self.SliderAdjustment, nPercent)
    UIHelper.SetWidth(self.ImgVolumeAdjustment, nPercent * self.nMaxWidth / 100)


    local bEnable = true
    if IsFunction(self.fnEnable) then
        bEnable = self.fnEnable()
    end

    UIHelper.SetEnable(self.SliderAdjustment, bEnable)
    UIHelper.SetNodeGray(self._rootNode, not bEnable, true)
end

return UIWidgetSettingsSlider