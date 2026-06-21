-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIVoiceSettingView
-- Date: 2023-03-27 18:41:27
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIVoiceSettingView = class("UIVoiceSettingView")

function UIVoiceSettingView:OnEnter()
    self.nVoiceType = GVoiceMgr.GetVoiceType()

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIVoiceSettingView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIVoiceSettingView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function()
        GetGameSoundSetting(SOUND.MIC_VOLUME).VoiceType = self.nVoiceType
        CustomData.Dirty(CustomDataType.Global)

        GVoiceMgr.SetVoiceType(self.nVoiceType)

        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIVoiceSettingView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIVoiceSettingView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIVoiceSettingView:UpdateInfo()
    UIHelper.SetTabVisible(self.tbToggleList, false)

    local tbConfig = GVoiceMgr.GetVoiceConfig()
    for k = 0, 11 do
        local conf = tbConfig[k]
        local szName = conf.szName
        local nID = conf.dwID
        local cell = self.tbToggleList[k + 1]
        if cell then
            UIHelper.SetVisible(cell, true)
            local tog = cell:getChildByName("ToggleVoice")
            local label = cell:getChildByName("ToggleVoice/LabelVoice")
            UIHelper.SetString(label, GBKToUTF8(szName))
            UIHelper.SetSelected(tog, self.nVoiceType == nID)
            UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(_, bSelected)
                if bSelected then
                    self.nVoiceType = nID
                end
            end)
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewVoice)
end


return UIVoiceSettingView