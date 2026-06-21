-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIChatSettingToggle
-- Date: 2022-12-13 19:37:24
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIChatSettingToggle = class("UIChatSettingToggle")

function UIChatSettingToggle:OnEnter(nIndex, szName, bSelect, tbSettingConf, callback)
    self.nIndex = nIndex
    self.szName = szName
    self.bSelect = bSelect
    self.tbSettingConf = tbSettingConf
    self.szUIChannel = tbSettingConf and tbSettingConf.szUIChannel
    self.callback = callback

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChatSettingToggle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChatSettingToggle:BindUIEvent()
    UIHelper.BindUIEvent(self.WidgetChatSettingLeftTogCell, EventType.OnSelectChanged, function(btn, bSelected)
        if bSelected then
            if IsFunction(self.callback) then
                self.callback()
            end
        end
    end)
end

function UIChatSettingToggle:RegEvent()
    Event.Reg(self, EventType.OnChatUIChannelNicknameChanged, function(szUIChannel, szName)
        if szUIChannel == self.szUIChannel then
            self:UpdateInfo_Name()
        end
    end)
end

function UIChatSettingToggle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatSettingToggle:UpdateInfo()
    self:UpdateInfo_Name()

    if self.bSelect then
        UIHelper.SetSelected(self.WidgetChatSettingLeftTogCell, true)
    end
end

function UIChatSettingToggle:UpdateInfo_Name()
    local szName = self.szUIChannel and ChatData.GetUIChannelNickName(self.szUIChannel) or ""
    if string.is_nil(szName) then szName = self.szName end

    UIHelper.SetString(self.LabelNormalAll, szName)
    UIHelper.SetString(self.LabelUpAll, szName)
end




return UIChatSettingToggle