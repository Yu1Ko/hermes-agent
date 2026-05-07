-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIVoiceSettingWidget
-- Date: 2023-03-28 14:47:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIVoiceSettingWidget = class("UIVoiceSettingWidget")

function UIVoiceSettingWidget:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIVoiceSettingWidget:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIVoiceSettingWidget:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnVoiceSetting, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelChooseVoice)
    end)
end

function UIVoiceSettingWidget:RegEvent()
    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelChooseVoice then
            self:UpdateInfo()
        end
    end)
end

function UIVoiceSettingWidget:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIVoiceSettingWidget:UpdateInfo()
    local nVoiceType = GVoiceMgr.GetVoiceType()
    UIHelper.SetString(self.LabelVoiceType, GVoiceMgr.GetVoiceNameByType(nVoiceType))
end


return UIVoiceSettingWidget