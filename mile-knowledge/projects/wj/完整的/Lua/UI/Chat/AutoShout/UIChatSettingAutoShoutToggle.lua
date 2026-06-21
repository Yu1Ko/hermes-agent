-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIChatSettingAutoShoutToggle
-- Date: 2022-12-13 19:37:24
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIChatSettingAutoShoutToggle = class("UIChatSettingAutoShoutToggle")

function UIChatSettingAutoShoutToggle:OnEnter(szType, szName, bSelect, callback)
    self.szType = szType
    self.szName = szName
    self.bSelect = bSelect
    self.callback = callback

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChatSettingAutoShoutToggle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChatSettingAutoShoutToggle:BindUIEvent()
    UIHelper.BindUIEvent(self.WidgetChatSettingLeftTogCell, EventType.OnSelectChanged, function(btn, bSelected)
        if bSelected then
            if IsFunction(self.callback) then
                self.callback()
            end
        end
    end)
end

function UIChatSettingAutoShoutToggle:RegEvent()
    -- Event.Reg(self, EventType.OnChatUIChannelNicknameChanged, function(szUIChannel, szName)
    --     if szUIChannel == self.szUIChannel then
    --         self:UpdateInfo_Name()
    --     end
    -- end)
end

function UIChatSettingAutoShoutToggle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatSettingAutoShoutToggle:UpdateInfo()
    self:UpdateInfo_Name()

    if self.bSelect then
        UIHelper.SetSelected(self.WidgetChatSettingLeftTogCell, true)
    end
end

function UIChatSettingAutoShoutToggle:UpdateInfo_Name()
    local szName = self.szName

    UIHelper.SetString(self.LabelNormalAll, szName)
    UIHelper.SetString(self.LabelUpAll, szName)
end

function UIChatSettingAutoShoutToggle:SetNew(bNew)
    UIHelper.SetVisible(self.ImgRedpoint, bNew)
end

return UIChatSettingAutoShoutToggle