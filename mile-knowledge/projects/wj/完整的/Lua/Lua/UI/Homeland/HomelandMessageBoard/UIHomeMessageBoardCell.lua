-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeMessageBoardCell
-- Date: 2024-01-10 14:30:01
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeMessageBoardCell = class("UIHomeMessageBoardCell")

function UIHomeMessageBoardCell:OnEnter(tbMessageInfo, bIshouseOwner)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bDeleteMode = false
    self.bIshouseOwner = bIshouseOwner
    self.tbMessageInfo = tbMessageInfo
    self.bLike = self.tbMessageInfo.bClickLike
    self:UpdateInfo()
end

function UIHomeMessageBoardCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomeMessageBoardCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnLike, EventType.OnClick, function ()
        if self.bLike or not self.tbMessageInfo then
            return
        end
        if self.tbMessageInfo.szLandID and self.tbMessageInfo.uSequenceID then
            --GetChatManager().RemoteCallToChatServer("LikeBulletinMessage", BULLETIN_MESSAGE_TYPE.HOMELAND_BOARD, self.tbMessageInfo.szLandID, self.tbMessageInfo.uSequenceID)
            RemoteCallToServer("On_HomeLand_LikeMessage", self.tbMessageInfo.szLandID, BULLETIN_MESSAGE_TYPE.HOMELAND_BOARD, self.tbMessageInfo.uSequenceID)
            self.bLike = true
            self.tbMessageInfo.bClickLike = true
            local szPraise = self.GetPraiseNum(self.tbMessageInfo.uLikeCount + 1)
            UIHelper.SetString(self.LabelNum, szPraise)
            UIHelper.SetVisible(self.ImgBgLiked, self.bLike)

            OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_MESSAGEBOARD_LIKESUC)
        end
    end)

    UIHelper.BindUIEvent(self.BtnMore, EventType.OnClick, function ()
        self:OnHeadClick()
    end)

    UIHelper.BindUIEvent(self.TogChoose, EventType.OnClick, function ()
        Event.Dispatch(EventType.OnHomeMessageBoardChooseMsg)
    end)
end

function UIHomeMessageBoardCell:RegEvent()
    Event.Reg(self, EventType.OnHomeMessageBoardDeleteMsg, function (bEnterDeleteMode)
        UIHelper.SetVisible(self.TogChoose, bEnterDeleteMode)
        UIHelper.SetVisible(self.BtnMore, not bEnterDeleteMode)
    end)

    Event.Reg(self, EventType.OnHomeMessageBoardSelectAllMsg, function (bSelected)
        UIHelper.SetSelected(self.TogChoose, bSelected)
    end)
end

function UIHomeMessageBoardCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomeMessageBoardCell:UpdateInfo()
    local tbMsg = self.tbMessageInfo
    self.bLike = self.tbMessageInfo.bClickLike
    local szName = UIHelper.GBKToUTF8(tbMsg.szName)
    local szTime = UIHelper.GBKToUTF8(self.GetTimeToDate(tbMsg.dwTime))
    local szContent = self.OnMessageBoardInput(tbMsg.tMessageInfo)
    local szPraise = self.GetPraiseNum(tbMsg.uLikeCount)

    UIHelper.SetString(self.LabelName, szName)
    UIHelper.SetString(self.LabelTime, szTime)
    UIHelper.SetString(self.LabelNum, szPraise)
    UIHelper.SetRichText(self.LabelContent, szContent)

    if not self.scriptHead then
        UIHelper.RemoveAllChildren(self.WidgetHead)
        self.scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead, tbMsg.dwSenderID)
    end
    self.scriptHead:SetHeadInfo(tbMsg.dwSenderID, tbMsg.player.dwMiniAvatarID, tbMsg.player.nRoleType, tbMsg.player.dwForceID)
    self.scriptHead:SetTouchEnabled(false)
    UIHelper.SetSelected(self.TogChoose, false)
    UIHelper.SetVisible(self.TogChoose, false)
    UIHelper.SetVisible(self.BtnMore, true)
    UIHelper.SetVisible(self.BtnLike, true)
    UIHelper.SetVisible(self.ImgBgLiked, self.bLike)
    UIHelper.SetVisible(self.ImgOwnerIcon, tbMsg.bIsHouseOwner)
end

function UIHomeMessageBoardCell.GetTimeToDate(Time)
	local tTodayDate = TimeToDate(Time)
	return string.format(g_tStrings.STR_MESSAGEBOARD_TIME, tTodayDate.year, tTodayDate.month, tTodayDate.day, tTodayDate.hour, tTodayDate.minute, tTodayDate.second)
end

function UIHomeMessageBoardCell:OnHeadClick()
	if not self.scriptHead then return end

    local tbMsg = self.tbMessageInfo
    local tbBtnInfo = {}
    if self.bIshouseOwner then  -- 房主可删除留言
        table.insert(tbBtnInfo, {
            szName = g_tStrings.STR_MESSAGEBOARD_DELONE,
            OnClick = function()
                Event.Dispatch(EventType.HideAllHoverTips)
                UIHelper.ShowConfirm(g_tStrings.STR_MESSAGEBOARD_DELETE, function ()
                    -- GetChatManager().RemoteCallToChatServer("DelBulletinMessage", BULLETIN_MESSAGE_TYPE.HOMELAND_BOARD, tbMsg.szLandID, tbMsg.uSequenceID)
                    RemoteCallToServer("On_HomeLand_DelMessage", tbMsg.szLandID, BULLETIN_MESSAGE_TYPE.HOMELAND_BOARD, tbMsg.uSequenceID)
                end)
            end
        })
    else
        table.insert(tbBtnInfo, {
            szName = g_tStrings.STR_MESSAGEBOARD_REPORT,--举报留言
            OnClick = function()
                Event.Dispatch(EventType.HideAllHoverTips)
                self:ReportComments()
            end
        })
    end

    if tbMsg.dwSenderID ~= g_pClientPlayer.dwID then
        -- 留言的不是自己可交互
        table.insert(tbBtnInfo, {
            szName = "密聊",
            OnClick = function()
                if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "player talk") then
                    return
                end
                local tbData = {szName = UIHelper.GBKToUTF8(tbMsg.szName), dwTalkerID = tbMsg.dwSenderID, szGlobalID = tbMsg.szGlobalID}
                ChatHelper.WhisperTo(UIHelper.GBKToUTF8(tbMsg.szName), tbData)
                Event.Dispatch(EventType.HideAllHoverTips)
            end
        })
        table.insert(tbBtnInfo, {
            szName = "加为好友",
            OnClick = function()
                if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "player talk") then
                    return
                end
                GetSocialManagerClient().AddFellowship(tbMsg.szName)
                Event.Dispatch(EventType.HideAllHoverTips)
            end
        })
    end

    if not table.is_empty(tbBtnInfo) then
        local nX,nY = UIHelper.GetWorldPosition(self.BtnMore)
        local nSizeW,nSizeH = UIHelper.GetContentSize(self.BtnMore)
        local _, scriptTips = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetTipMoreOper,nX-nSizeW+50,nY+nSizeH-30*(#tbBtnInfo-3))
        scriptTips:OnEnter(tbBtnInfo)
    end
end

function UIHomeMessageBoardCell:GetSelected()
    return UIHelper.GetSelected(self.TogChoose)
end

function UIHomeMessageBoardCell:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogChoose, bSelected)
end

function UIHomeMessageBoardCell:ReportComments()
	local szContent = ""
	for k, v in ipairs(self.tbMessageInfo) do
		if v.text then
			szContent = szContent .. v.text
		end
	end
    local szText = self.tbMessageInfo.szName
    local reportView = UIMgr.Open(VIEW_ID.PanelReportPop)
    reportView:UpdateReportInfo(UIHelper.GBKToUTF8(szText), szContent )
	return szContent
end

function UIHomeMessageBoardCell.GetPraiseNum(uLikeCount)
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

function UIHomeMessageBoardCell.OnMessageBoardInput(t)
	local szContent = ""
	for k, v in ipairs(t) do    --处理格式化文本
		if v.type == "text" then
            szContent = szContent .. UIHelper.GBKToUTF8(v.text)
		elseif v.type == "emotion" then
			if v.id == 0 then
                -- szLeft = g_tStrings.STR_FACE .. g_tStrings.STR_COLON
            elseif v.id ~= -1 then
                local szEmoji = string.format("<img emojiid='%d' src='' width='30' height='30'/>", v.id)
                szContent = szContent .. szEmoji
            end
		end
	end
	return szContent
end

return UIHomeMessageBoardCell