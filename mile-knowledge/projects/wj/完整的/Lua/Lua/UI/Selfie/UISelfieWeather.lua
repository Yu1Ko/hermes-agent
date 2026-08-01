-- ---------------------------------------------------------------------------------
-- Author: zengzipeng
-- Name: UISelfieWeather
-- Date: 2023-05-25 14:59:28
-- Desc: 环境云图--天气
-- ---------------------------------------------------------------------------------

local UISelfieWeather = class("UISelfieWeather")
local _DAY_TIME_PRIORITY = TIME_PRIORITY.HIGH
local _SECONDS_IN_ONE_DAY = 24 * 60 * 60
local _SUN_MOON_INTERVAL = 5 * 60  --- 日夜循环的间隔时间（单位为秒）
function UISelfieWeather:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UISelfieWeather:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISelfieWeather:BindUIEvent()
    UIHelper.BindUIEvent(self.SliderTime , EventType.OnChangeSliderPercent , function (SliderEventType, nSliderEvent)
        if nSliderEvent == ccui.SliderEventType.percentChanged then
            self.sliderValue = UIHelper.GetProgressBarPercent(self.SliderTime)
            Scene_SetTimeOfDay(math.min(self.sliderValue * _SUN_MOON_INTERVAL, _SECONDS_IN_ONE_DAY - 1), _DAY_TIME_PRIORITY)
        end
    end)
end

function UISelfieWeather:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISelfieWeather:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UISelfieWeather:Open()
    
end
function UISelfieWeather:Hide()
    
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISelfieWeather:UpdateInfo()
    PostThreadCall(function (nCanSet)
        local bShow = nCanSet > 0
        UIHelper.SetVisible(self.WidgetTimeSettingTitle , bShow)
        UIHelper.SetVisible(self.LayoutTimeSetting , bShow)
        if bShow then
            PostThreadCall(function (nTimeOfDay, bSuccess)
                self:OnGetTimeOfDay(nTimeOfDay, bSuccess)
            end, nil, "Scene_GetTimeOfDay")
        end
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollWeatherSetting)
    end, nil, "Scene_IsDynamicWeatherEnabled")
    UIHelper.SetVisible(self.WidgetFunctionSettingTitle , false)
    UIHelper.SetVisible(self.LayoutFunctionSetting , false)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollWeatherSetting)
end

function UISelfieWeather:OnGetTimeOfDay(nTimeOfDay, bSuccess)
	if bSuccess then
        UIHelper.SetMaxPercent(self.SliderTime , math.floor(_SECONDS_IN_ONE_DAY / _SUN_MOON_INTERVAL)) 
		Scene_SetTimeOfDay(nTimeOfDay, _DAY_TIME_PRIORITY)
        UIHelper.SetProgressBarPercent(self ,  math.floor((nTimeOfDay) / _SUN_MOON_INTERVAL))
	end
end


return UISelfieWeather