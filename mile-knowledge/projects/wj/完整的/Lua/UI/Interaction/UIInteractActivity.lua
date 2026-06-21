-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIInteractActivity
-- Date: 2023-02-10 17:27:41
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIInteractActivity = class("UIInteractActivity")

local nType = {[7] = 1,[8] = 2,[9] = 3}  --对应师父徒弟同门

function UIInteractActivity:OnEnter(dwActiveID,szName,nIconFrame,nStar,nRelationType,szPlayerName, tbPlayerInfo,MiniAvatarID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwActiveID = dwActiveID
    self.szName = szName
    self.nIconFrame = nIconFrame or "UIAtlas2_Interaction_Apprentice_icon_activity01"
    self.nStar = nStar
    self.nMode = nType[nRelationType]
    self.szPlayerName = szPlayerName
    self.tbPlayerInfo = tbPlayerInfo
    self.MiniAvatarID = MiniAvatarID
    self:UpdateInfo()
end

function UIInteractActivity:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIInteractActivity:BindUIEvent()
    --详情
    UIHelper.BindUIEvent(self.BtnDetail,EventType.OnClick,function ()
        ActivityData.LinkToActiveByID(self.dwActiveID)
        Event.Dispatch(EventType.MentorActivityDetail,self.dwActiveID)
    end)
    --邀约
    UIHelper.BindUIEvent(self.BtnInvite,EventType.OnClick,function ()
        if self.dwActiveID then
			local szTxt 	= self:GetMentorPanelInfoByActivityID(self.dwActiveID, self.nMode)
			if not szTxt then
				return
			end
			szTxt = FormatString(szTxt, UIHelper.UTF8ToGBK(self.szPlayerName))
			Player_Talk(g_pClientPlayer, PLAYER_TALK_CHANNEL.WHISPER, UIHelper.UTF8ToGBK(self.szPlayerName), {{ type = "text", text = szTxt .. "\n"}})

            if self.tbPlayerInfo then
                local szName = UIHelper.GBKToUTF8(self.tbPlayerInfo.szName)
                local dwTalkerID = self.tbPlayerInfo.dwID
                local dwForceID = self.tbPlayerInfo.dwForceID
                local dwMiniAvatarID = self.MiniAvatarID
                local nRoleType = self.tbPlayerInfo.nRoleType
                local nLevel = self.tbPlayerInfo.nLevel
                local tbData = {szName = szName, dwTalkerID = dwTalkerID, dwForceID = dwForceID, dwMiniAvatarID = dwMiniAvatarID, nRoleType = nRoleType, nLevel = nLevel}

                ChatHelper.WhisperTo(szName, tbData)
            else
                UIMgr.Open(VIEW_ID.PanelChatSocial)
            end

            UIMgr.Close(VIEW_ID.PanelInteractActivityPop)
		end
    end)
end

function UIInteractActivity:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIInteractActivity:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIInteractActivity:UpdateInfo()
    for i = 1,self.nStar,1 do
        UIHelper.SetVisible(self.tbImgStar[i],true)
    end
    UIHelper.SetString(self.LabelActivity,UIHelper.GBKToUTF8(self.szName))
    UIHelper.SetSpriteFrame(self.ImgActivity, self.nIconFrame)
end

function UIInteractActivity:GetMentorPanelInfoByActivityID(nActivityID, nType)
	if not self.tMentorActivityInfo then
		local tMentorPanelInfo = Table_GetMentorPanelInfo()
		self.tMentorActivityInfo = tMentorPanelInfo.tActivityMsg
	end
	return self.tMentorActivityInfo[nActivityID][nType]
end

return UIInteractActivity