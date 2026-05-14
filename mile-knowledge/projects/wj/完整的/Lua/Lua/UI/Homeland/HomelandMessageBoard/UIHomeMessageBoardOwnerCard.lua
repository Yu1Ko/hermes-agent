-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeMessageBoardOwnerCard
-- Date: 2024-01-09 10:35:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeMessageBoardOwnerCard = class("UIHomeMessageBoardOwnerCard")

function UIHomeMessageBoardOwnerCard:OnEnter(bIsHouseOwner)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bLike = false
    self.bEditMode = false
    self.tHomelandInfo = {}
    self.bIsHouseOwner = bIsHouseOwner
    self:InitOwnerCard()
end

function UIHomeMessageBoardOwnerCard:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomeMessageBoardOwnerCard:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnChat, EventType.OnClick, function ()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "player talk") then
            return
        end
        ChatHelper.WhisperTo(UIHelper.GBKToUTF8(self.tHomelandInfo.szName), {})
    end)

    UIHelper.BindUIEvent(self.BtnAddFriend, EventType.OnClick, function ()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "player talk") then
            return
        end
        GetSocialManagerClient().AddFellowship(self.tHomelandInfo.szName)
    end)

    UIHelper.BindUIEvent(self.BtnLike, EventType.OnClick, function ()
        if self.bLike or not self.tHomelandInfo then
            return
        end
        if self.tHomelandInfo.szLandID and self.tHomelandInfo.uSequenceID then
            --GetChatManager().RemoteCallToChatServer("LikeBulletinMessage", BULLETIN_MESSAGE_TYPE.HOMELAND_OWNER, self.tHomelandInfo.szLandID, self.tHomelandInfo.uSequenceID)
            RemoteCallToServer("On_HomeLand_LikeMessage", self.tHomelandInfo.szLandID, BULLETIN_MESSAGE_TYPE.HOMELAND_OWNER, self.tHomelandInfo.uSequenceID)
            self.bLike = true

            -- 本地+1，刷新一下显示
            self.tHomelandInfo.uLikeCount = self.tHomelandInfo.uLikeCount + 1
            UIHelper.SetString(self.LabelNum, self.GetPraiseNum(self.tHomelandInfo.uLikeCount))

            OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_MESSAGEBOARD_LIKESUC)
        end
    end)

    UIHelper.BindUIEvent(self.BtnEdit, EventType.OnClick, function ()
        self.bEditMode = true
        self:InitOwnerCard()

        if not self.tHomelandInfo.InitOwner then
            return
        end
        local szMessage = UIHelper.GetString(self.LabelContent)
        local nLen = string.getCharLen(szMessage)
        UIHelper.SetText(self.EditBox03, szMessage)
        UIHelper.SetString(self.LabelLimit, string.format("%d/%d", nLen, 32))
    end)

    UIHelper.RegisterEditBoxChanged(self.EditBox03, function()
        local nLen = string.getCharLen(UIHelper.GetText(self.EditBox03))
        UIHelper.SetString(self.LabelLimit, string.format("%d/%d", nLen, 32))
    end)

    UIHelper.BindUIEvent(self.BtnSave, EventType.OnClick, function ()
        self:OnSave()
    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function ()
        UIHelper.SetText(self.EditBox03, "")
    end)

    UIHelper.RegisterEditBoxChanged(self.EditBox03, function()
        local nLen = string.getCharLen(UIHelper.GetText(self.EditBox03))
        UIHelper.SetString(self.LabelLimit, string.format("%d/%d", nLen, 32))
    end)
end

function UIHomeMessageBoardOwnerCard:RegEvent()

end

function UIHomeMessageBoardOwnerCard:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomeMessageBoardOwnerCard:InitOwnerCard()
    local bIsHouseOwner = self.bIsHouseOwner
    UIHelper.SetVisible(self.WidgetView, true)
    UIHelper.SetVisible(self.WidgetOwnerEdit, false)
    UIHelper.SetVisible(self.BtnLike, false)
    UIHelper.SetVisible(self.BtnEdit, false)
    UIHelper.SetVisible(self.BtnAddFriend, false)
    UIHelper.SetVisible(self.BtnChat, false)

    if bIsHouseOwner then
        UIHelper.SetVisible(self.BtnEdit, true)
        UIHelper.SetVisible(self.ImgEditBg03, true)
    elseif self.tHomelandInfo and not string.is_nil(self.tHomelandInfo.szName) then
        UIHelper.SetVisible(self.BtnAddFriend, true)
        UIHelper.SetVisible(self.BtnChat, true)
    end

    if self.bEditMode and bIsHouseOwner then
        UIHelper.SetVisible(self.WidgetOwnerEdit, true)
        UIHelper.SetVisible(self.WidgetView, false)
    end
end

function UIHomeMessageBoardOwnerCard:UpdateOwnerCardInfo(tHomelandInfo)
    assert(tHomelandInfo)
    self.tHomelandInfo = tHomelandInfo
    local tPlayerInfo = tHomelandInfo.player
    local szMessage = ""
    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(tHomelandInfo.szName))
	if not tHomelandInfo.InitOwner then
        szMessage = "该屋主什么都没说~"
        UIHelper.SetString(self.LabelContent, szMessage)
		return
	end
    if not self.scriptHead then
        UIHelper.RemoveAllChildren(self.WidgetHead)
        self.scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead_108, self.WidgetHead, tHomelandInfo.dwOwnerID)
        self.scriptHead:SetTouchEnabled(false)
    end
    self.scriptHead:SetHeadInfo(tHomelandInfo.dwOwnerID, tPlayerInfo.dwMiniAvatarID, tPlayerInfo.nRoleType, tPlayerInfo.dwForceID)

    -- 初始化户主信息后功能正常
    szMessage = UIHelper.GBKToUTF8(tHomelandInfo.tMessageItem[1].text)
    self.bLike = self.tHomelandInfo.bClickLike
    UIHelper.SetVisible(self.BtnLike, true)
    UIHelper.SetVisible(self.BtnAddFriend, not not tPlayerInfo)
    UIHelper.SetVisible(self.BtnChat, not not tPlayerInfo)
    UIHelper.SetVisible(self.WidgetHeadEmpty, not tPlayerInfo)
    UIHelper.SetVisible(self.ImgBgLiked, self.bLike)
    UIHelper.SetString(self.LabelContent, szMessage)
    UIHelper.SetString(self.LabelNum, self.GetPraiseNum(tHomelandInfo.uLikeCount))
end

function UIHomeMessageBoardOwnerCard.GetPraiseNum(uLikeCount)
	local szRet = ""
	if uLikeCount < 10000 then
		szRet = tostring(uLikeCount)
	else
		local dwNumK = math.modf( uLikeCount / 1000 )
		local dwLine = math.modf( dwNumK / 10 )
		local dwMod = math.fmod( dwNumK, 3 )
		szRet = FormatString(g_tStrings.STR_MESSAGEBOARD_ZAN, dwLine, dwMod)
	end
	return szRet
end

function UIHomeMessageBoardOwnerCard:OnSave()
    local bInitOwner = self.tHomelandInfo and self.tHomelandInfo.InitOwner
	local szMessage = UIHelper.GetString(self.LabelContent)
    local szNewMsg = UIHelper.GetText(self.EditBox03)
    self.bEditMode = false
    self:InitOwnerCard()    --不管有没有改动都先退出编辑状态

    if szMessage == szNewMsg or BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "player talk") then
        return
    end
    if bInitOwner and not string.is_nil(szNewMsg) then
        UIHelper.SetString(self.LabelContent, szNewMsg)
    end
    Event.Dispatch(EventType.OnHomeMessageBoardSendMsg, szNewMsg, 2)
end

return UIHomeMessageBoardOwnerCard