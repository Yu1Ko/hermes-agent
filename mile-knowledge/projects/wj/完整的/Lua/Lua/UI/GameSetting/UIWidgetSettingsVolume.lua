-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSettingsVolume
-- Date: 2022-12-20 14:55:04
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIWidgetSettingVolume
local UIWidgetSettingsVolume = class("UIWidgetSettingsVolume")

function UIWidgetSettingsVolume:OnEnter(tbSettingsCell, nType, szStorageKey)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    nType = nType or -1

    self.szEvent = EventType.OnGameSettingsSliderChange
    self.szStorageKey = szStorageKey
    local fSliderValue = 1
    local bTogSelect = false
    if IsNumber(tbSettingsCell) then
        self.szEvent = EventType.OnActorTypeVolumeSliderChange
        fSliderValue = tbSettingsCell
        UIHelper.SetVisible(self.TogVolumeIcon, false)
    else
        fSliderValue = tbSettingsCell.Slider or 1
        bTogSelect = tbSettingsCell.TogSelect
    end

    self.nSoundType = nType
    self.nCurrentValue = fSliderValue * 100
    
    UIHelper.SetSelected(self.TogVolumeIcon, bTogSelect)
    self:UpdateToggleSelect(bTogSelect)
end

function UIWidgetSettingsVolume:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSettingsVolume:BindUIEvent()
    UIHelper.BindUIEvent(self.SliderVolumeAdjustment, EventType.OnChangeSliderPercent, function(SliderEventType, nSliderEvent)
        if nSliderEvent == ccui.SliderEventType.slideBallDown then
            self.bSliding = true
        elseif nSliderEvent == ccui.SliderEventType.slideBallUp then
            self.bSliding = false
            -- 强制修正滑块进度
            UIHelper.SetProgressBarPercent(self.SliderVolumeAdjustment, self.nCurrentValue)
            UIHelper.SetProgressBarPercent(self.BarVolumeAdjustment, self.nCurrentValue)
        end

        if self.bSliding then
            local nPercent = UIHelper.GetProgressBarPercent(self.SliderVolumeAdjustment)
            self.nCurrentValue = nPercent
            self.nCurrentValue = math.min(self.nCurrentValue, 100)
            self.nCurrentValue = math.max(self.nCurrentValue, 0)
            UIHelper.SetString(self.LabelVolumeNum, self.nCurrentValue)
            UIHelper.SetProgressBarPercent(self.BarVolumeAdjustment, nPercent)
            Event.Dispatch(self.szEvent, self.nSoundType, self.nCurrentValue / 100, self.szStorageKey)
        end
    end)
    UIHelper.BindUIEvent(self.TogVolumeIcon, EventType.OnClick, function()
        local bSelected = UIHelper.GetSelected(self.TogVolumeIcon)
        Event.Dispatch(EventType.OnGameSettingsTogSelectChange, self.nSoundType, bSelected, self.nCurrentValue / 100)
    end)
end

function UIWidgetSettingsVolume:RegEvent()
    Event.Reg(self, EventType.OnGameSettingsSliderChange, function(nType, fValue)
        if self.nSoundType == nType and self.szEvent == EventType.OnGameSettingsSliderChange then
            if fValue > 0 then
                UIHelper.SetSelected(self.TogVolumeIcon, false)
                Event.Dispatch(EventType.OnGameSettingsTogSelectChange, nType, false)
            else
                UIHelper.SetSelected(self.TogVolumeIcon, true)
                Event.Dispatch(EventType.OnGameSettingsTogSelectChange, nType, true)
            end
        end
    end)
    Event.Reg(self, EventType.OnGameSettingsTogSelectChange, function(nType, bSelected)
        if self.nSoundType == nType and self.szEvent == EventType.OnGameSettingsSliderChange then
            self:UpdateToggleSelect(bSelected)
        end
    end)
end

function UIWidgetSettingsVolume:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetSettingsVolume:UpdateInfo()

end

function UIWidgetSettingsVolume:UpdateToggleSelect(bSelected)
    if bSelected then
        UIHelper.SetProgressBarPercent(self.SliderVolumeAdjustment, 0)
        UIHelper.SetProgressBarPercent(self.BarVolumeAdjustment, 0)
        UIHelper.SetString(self.LabelVolumeNum, 0)
    else
        UIHelper.SetProgressBarPercent(self.BarVolumeAdjustment, self.nCurrentValue)
        UIHelper.SetProgressBarPercent(self.SliderVolumeAdjustment, self.nCurrentValue)
        UIHelper.SetString(self.LabelVolumeNum, self.nCurrentValue)
    end
end

function UIWidgetSettingsVolume:SetName(szName)
    UIHelper.SetString(self.LabelVolume, szName)
end

return UIWidgetSettingsVolume