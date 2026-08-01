-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetBahuangSettingTogView
-- Date: 2024-01-26 17:26:02
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetBahuangSettingTogView = class("UIWidgetBahuangSettingTogView")

function UIWidgetBahuangSettingTogView:OnEnter(tbSettingInfo, nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbSettingInfo = tbSettingInfo
    self.nIndex = nIndex
    self:UpdateInfo()
end

function UIWidgetBahuangSettingTogView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetBahuangSettingTogView:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSelectBg, EventType.OnSelectChanged, function(_, bSelect)
        self.tbSettingInfo.funcSetting(self.nIndex, bSelect)
    end)
end

function UIWidgetBahuangSettingTogView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetBahuangSettingTogView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetBahuangSettingTogView:UpdateInfo()
    local szName = self.tbSettingInfo.szName
    UIHelper.SetString(self.LabelTogOpcion, szName)
    UIHelper.SetSelected(self.TogSelectBg, BahuangData.IsAutoCast(self.nIndex), false)
end


return UIWidgetBahuangSettingTogView