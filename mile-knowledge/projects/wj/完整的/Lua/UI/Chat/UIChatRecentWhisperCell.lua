-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIChatRecentWhisperCell
-- Date: 2024-09-12 20:16:35
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIChatRecentWhisperCell = class("UIChatRecentWhisperCell")

function UIChatRecentWhisperCell:OnEnter(tbPlayerInfo, bSelected)
	self.bSelected = bSelected
	self.tbPlayerInfo = tbPlayerInfo
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end

	self:UpdateInfo()
end

function UIChatRecentWhisperCell:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIChatRecentWhisperCell:BindUIEvent()
	UIHelper.BindUIEvent(self.TogWhisperPlayer, EventType.OnSelectChanged, function (_, bSelected)
		if bSelected then
			Event.Dispatch("ON_UDPATE_RECENT_WHISPER_INFO", self.tbPlayerInfo)
			Event.Dispatch(EventType.OnChatWhisperSelected, UIHelper.GBKToUTF8(self.tbPlayerInfo.szName))
		end
    end)
end

function UIChatRecentWhisperCell:RegEvent()
	Event.Reg(self, EventType.OnChatRecentWhisperUnreadAdd, function (szGlobal)
		self:UpdateInfo_Redpoint()
    end)

	Event.Reg(self, EventType.OnChatRecentWhisperUnreadRemove, function (szGlobal)
		self:UpdateInfo_Redpoint()
    end)
end

function UIChatRecentWhisperCell:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatRecentWhisperCell:UpdateInfo()
	self:UpdatePlayerInfo(self.tbPlayerInfo)
	UIHelper.SetSelected(self.TogWhisperPlayer, self.bSelected)

	self:UpdateInfo_Redpoint()
end

function UIChatRecentWhisperCell:UpdatePlayerInfo(tbPlayerInfo, bSelectedPlayer)
	self.tbPlayerInfo = tbPlayerInfo
	UIHelper.RemoveAllChildren(self.WidgetHead)
    local scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead)
	scriptHead:SetHeadInfo(nil, tbPlayerInfo.dwMiniAvatarID or 0, tbPlayerInfo.byRoleType or nil, tbPlayerInfo.byForceID)
	scriptHead:SetOfflineState(false)
	UIHelper.SetNodeSwallowTouches(self.WidgetHead, false, true)

	UIHelper.SetString(self.LabelPlayerName, UIHelper.GBKToUTF8(tbPlayerInfo.szName), 6)

    local tbFriendList = FellowshipData.GetFellowshipInfoList() or {}
    for i, v in ipairs(tbFriendList) do
        if v.id == self.tbPlayerInfo.szGlobalID and v.remark then
			UIHelper.SetString(self.LabelPlayerName, UIHelper.GBKToUTF8(v.remark), 6)
            break
        end
    end

	UIHelper.SetSpriteFrame(self.ImgForceID, PlayerForceID2SchoolImg2[tbPlayerInfo.byForceID])

	local bFriend = FellowshipData.IsFriend(tbPlayerInfo.szGlobalID)
	UIHelper.SetVisible(self.ImgRecentContacts1, not bFriend)
	UIHelper.SetVisible(self.ImgRecentContacts2, bFriend)

	self:UpdateInfo_Redpoint()

	UIHelper.SetSelected(self.TogWhisperPlayer, bSelectedPlayer, false)
end

function UIChatRecentWhisperCell:UpdateInfo_Redpoint()
	UIHelper.SetVisible(self.imgRedPoint, ChatRecentMgr.HasWhisperUnread(self.tbPlayerInfo.szGlobalID))
end


return UIChatRecentWhisperCell