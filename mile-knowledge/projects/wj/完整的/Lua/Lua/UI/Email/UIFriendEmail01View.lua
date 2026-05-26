-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIFriendEmail02View
-- Date: 2022-11-16 23:43:41
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIFriendEmail02View = class("UIFriendEmail02View")

function UIFriendEmail02View:OnEnter(nIndex, szSelectedName, szLabelEmailTitle, tbPlayerInfo,tbPlayerCard)
    self.nIndex = nIndex
    self.szSelectedName = szSelectedName
    self.szLabelEmailTitle = szLabelEmailTitle
    self.tbPlayerInfo = tbPlayerInfo
    self.tbPlayerCard = tbPlayerCard or {}
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIFriendEmail02View:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFriendEmail02View:BindUIEvent()
    UIHelper.BindUIEvent(self.TogFriendEmail01, EventType.OnSelectChanged, function(toggle, bSelected)
        if bSelected then
            self.szSelectedName = self.szLabelEmailTitle
            Event.Dispatch(EventType.EmailFriendSelectChanged, self.szLabelEmailTitle, bSelected)
        end
    end)
end

function UIFriendEmail02View:RegEvent()
    Event.Reg(self, "SEND_MAIL_RESULT", function(nIndex, nCode)
        self:UpdateToggleState()
    end)

    Event.Reg(self, EventType.OnEditSendName, function(szSelectedName)
        if szSelectedName == self.szLabelEmailTitle then
            self.szSelectedName = self.szLabelEmailTitle
            UIHelper.SetSelected(self.TogFriendEmail01, true)
        elseif UIHelper.GetVisible(self.TogFriendEmail01) then
            UIHelper.SetSelected(self.TogFriendEmail01, false)
        end
    end)
    --Event.Reg(self, EventType.XXX, func)
end

function UIFriendEmail02View:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFriendEmail02View:UpdateInfo()
    if self.szSelectedName and self.szSelectedName == self.szLabelEmailTitle then
        UIHelper.SetSelected(self.TogFriendEmail01, true)
    else
        UIHelper.SetSelected(self.TogFriendEmail01, false)
    end
    for i = 1, 2 do
        local LabelEmailTitle = self.tbLabelEmailTitle[i]
        UIHelper.SetString(LabelEmailTitle, self.szLabelEmailTitle)
    end
    if self.tbPlayerInfo and not table_is_empty(self.tbPlayerInfo) then
        self.headScript = self.headScript or UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead)
        if self.headScript then
            self.headScript:SetHeadInfo(nil, self.tbPlayerInfo.dwMiniAvatarID or 0, self.tbPlayerInfo.nRoleType, self.tbPlayerInfo.nForceID)
        end
    else
        UIHelper.SetTexture(self.ImgHead, "Resource/PlayerAvatar/jianghu.png")
    end
end

function UIFriendEmail02View:UpdateToggleState()
    if UIHelper.GetVisible(self.TogFriendEmail01) then
        UIHelper.SetSelected(self.TogFriendEmail01, false)
    end
end

return UIFriendEmail02View