-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeMessageBoardView
-- Date: 2024-01-09 10:09:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeMessageBoardView = class("UIHomeMessageBoardView")

local MAX_MESSAGE_NUM = 32
local FACE_ONCE_SEND_MAX_COUNT = 10

local dwSenderIndex = 1 --发送消息的位置，1表示留言，2表示签名
local dwMessageNum = 0
local dwLastTime = 0
local dwLastSendTime = 0
local bIsHouseOwner = false
local uPermission = 0 -- 留言权限
local bInit = false
local bEmpty = false
local bSendTime = false
local szLandID = nil
local tPlayer = nil
local tHomelandInfo = {}
local tMessage = {}
local nLastBulletinTime = 0

local DataModel = {}
local View  = {}

local function GetHomelandMgrObj()
	if not pHomelandMgr then
		pHomelandMgr = GetHomelandMgr()
	end
	return pHomelandMgr
end

local function IsGMOption()
	local buff = Player_GetBuff(1459)
	local bGM = false
	if buff then
		bGM = true
	end
	return bGM
end

function DataModel.Init(nMapID, nCopyIndex, nLandIndex)
	bInit = false
	local pHlMgr = GetHomelandMgrObj()
	if not pHlMgr then
		return
	end
	pHlMgr.ApplyLandInfo(nMapID, nCopyIndex, nLandIndex)
	pHlMgr.ApplyHLLandInfo(nLandIndex)
	DataModel.UpdateHomeInfo(nMapID, nCopyIndex, nLandIndex)
end

function DataModel.UpdateOwnerName(nMapID, nCopyIndex, nLandIndex)
	local pHlMgr = GetHomelandMgrObj()
	--通过地取户主名
	local tInfo =  pHlMgr.GetLandInfo(nMapID, nCopyIndex, nLandIndex)
	if tInfo then
		tHomelandInfo.szName = tInfo.szName
	end
end

function DataModel.UpdateHomeInfo(nMapID, nCopyIndex, nLandIndex)
	local pHlMgr = GetHomelandMgrObj()
	tHomelandInfo.nMapID = nMapID
	tHomelandInfo.nCopyIndex = nCopyIndex
	tHomelandInfo.nLandIndex = nLandIndex

	szLandID = pHlMgr.GetLandID(nMapID, nCopyIndex, nLandIndex)

	--判断开放权限
	local tInfo = pHlMgr.GetHLLandInfo(nLandIndex)
	uPermission = tInfo.uPermission

	--判断是否户主
	local bMyHome = pHlMgr.IsMyLand(nMapID, nCopyIndex, nLandIndex)
	if  bMyHome then
		local aAllMyLandInfos = pHlMgr.GetAllMyLand()
		local t = FindTableValueByKey(aAllMyLandInfos, "uLandID", szLandID)
		if t and not t.bAllied then
			bIsHouseOwner = true
		end
	end

	local player = GetClientPlayer()
	if not player then
		return
	end
	tPlayer = player

	--初始化完成
	bInit = true
end

--客户端远程调用聊天服务器同步消息
function DataModel.SyncBulletinMessage()
	--GetChatManager().RemoteCallToChatServer("SyncBulletinMessage", BULLETIN_MESSAGE_TYPE.HOMELAND_OWNER, szLandID, 1, 1)
	--GetChatManager().RemoteCallToChatServer("SyncBulletinMessage", BULLETIN_MESSAGE_TYPE.HOMELAND_BOARD, szLandID, 1, 32)
	GetHomelandMgr().SyncBulletinData(szLandID)
end

function DataModel.UpdateAllMessage(dwMapID, nCopyIndex, nLandIndex)
	local nCount = GetHomelandMgr().GetBulletinCount(szLandID, BULLETIN_MESSAGE_TYPE.HOMELAND_BOARD)
	local uSelfGlobalID = UI_GetClientPlayerGlobalID()
	tMessage = {}
	nLastBulletinTime = 0
	dwMessageNum = nCount
	for i = nCount, 1, -1 do
		local tChatContent,uSequenceID,nCreateTime,uLikeCount,bClickLike,tChatOther = GetHomelandMgr().GetBulletinMessage(szLandID, BULLETIN_MESSAGE_TYPE.HOMELAND_BOARD, i)
        local tbLandInfo = GetHomelandMgr().GetLandInfo(dwMapID, nCopyIndex, nLandIndex)

		local tMessageItem = {}
		local player = {}
		player.dwForceID          = tChatOther.byForceID
		player.dwMiniAvatarID     = tChatOther.dwAvatarID
		player.nRoleType          = tChatOther.byType
		tMessageItem.szName       = tChatOther.szName
		tMessageItem.dwSenderID   = tChatOther.dwSenderID
		tMessageItem.uSenderID    = tChatOther.uSenderID
		tMessageItem.player       = player
		tMessageItem.tMessageInfo = tChatContent
		tMessageItem.uLikeCount   = uLikeCount
		tMessageItem.bClickLike   = bClickLike
		tMessageItem.dwTime       = nCreateTime
		tMessageItem.uSequenceID  = uSequenceID
		tMessageItem.szLandID     = szLandID

		if tChatOther.uSenderID == uSelfGlobalID and nCreateTime > nLastBulletinTime then
			nLastBulletinTime = nCreateTime
		end

        tMessageItem.bIsHouseOwner = false
        if tbLandInfo and tbLandInfo.szOwnerID == tChatOther.uSenderID then
            tMessageItem.bIsHouseOwner = true
        end
		table.insert(tMessage, nCount - i + 1, tMessageItem)
	end
end

function DataModel.UpdateOwnerMessage()
	local nCount = GetHomelandMgr().GetBulletinCount(szLandID, BULLETIN_MESSAGE_TYPE.HOMELAND_OWNER)
	if nCount == 1 then
		local tChatContent,uSequenceID,nCreateTime,uLikeCount,bClickLike,tOnwerInfo = GetHomelandMgr().GetBulletinMessage(szLandID, BULLETIN_MESSAGE_TYPE.HOMELAND_OWNER, 1)
		local player = {}
		player.dwForceID          = tOnwerInfo.byForceID
		player.dwMiniAvatarID     = tOnwerInfo.dwAvatarID
		player.nRoleType          = tOnwerInfo.byType
		tHomelandInfo.player = player
		tHomelandInfo.szName = tOnwerInfo.szName
		tHomelandInfo.tMessageItem = tChatContent
		tHomelandInfo.uLikeCount = uLikeCount
		tHomelandInfo.bClickLike = bClickLike
		tHomelandInfo.uSequenceID  = uSequenceID
		tHomelandInfo.dwOwnerID = tOnwerInfo.dwOwnerID
        tHomelandInfo.szLandID     = szLandID

		--实际上只在消息为空时有用
		tHomelandInfo.InitOwner = true
	else
		tHomelandInfo.InitOwner = false
		tHomelandInfo.tMessageItem = {}
		--户主第一次打开自动上传空留言
		if bIsHouseOwner then
			--保存留言
			-- GetChatManager().SetCustomDataAndSync("Bulletin", {""})
			dwSenderIndex = 2
		end

	end
end

function DataModel.GetTimeToDate(Time)
	local tTodayDate = TimeToDate(Time)
	return string.format(g_tStrings.STR_MESSAGEBOARD_TIME, tTodayDate.year, tTodayDate.month, tTodayDate.day, tTodayDate.hour, tTodayDate.minute, tTodayDate.second)
end

function DataModel.DealWithEmotion(t)
	for k, v in ipairs(t) do    --简化表情内容
    	if v.type == "emotion" then
			t[k] ={id = v.id, type = v.type, text = v.text}
		end
	end
	return t
end

function DataModel.ReportComments(t)
	local szContent = ""
	for k, v in ipairs(t) do
		if v.text then
			szContent = szContent .. v.text
		end
	end
	return szContent
end

function DataModel.GetPraiseNum(uLikeCount)
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

function UIHomeMessageBoardView:OnEnter(dwMapID, nCopyIndex, nLandIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwMapID = dwMapID
    self.nCopyIndex = nCopyIndex
    self.nLandIndex = nLandIndex
    self:Init()
end

function UIHomeMessageBoardView:OnExit()
    dwMessageNum = 0
	bIsHouseOwner = false
	tHomelandInfo = {}
	tMessage = {}
	nLastBulletinTime = 0
    self.bInit = false
    self:UnRegEvent()
end

function UIHomeMessageBoardView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
end

function UIHomeMessageBoardView:RegEvent()
	Event.Reg(self, "HOME_LAND_RESULT_CODE_INT", function()
		local nRetCode = arg0
		if nRetCode == HOMELAND_RESULT_CODE.APPLY_HLLAND_INFO or nRetCode == HOMELAND_RESULT_CODE.APPLY_LAND_INFO then  --申请某块地详情
			local pHlMgr = GetHomelandMgrObj()
			local tInfo = pHlMgr.GetHLLandInfo(self.nLandIndex)
			uPermission = tInfo.uPermission
			self.scriptBottom:OnEnter(bIsHouseOwner, uPermission)
		end
	end)

    Event.Reg(self, EventType.OnHomeMessageBoardDeleteMsg, function (bEnterDeleteMode)
        --当退出时删除勾选的留言
        if bEnterDeleteMode or not self.scriptMessagesList then
            return
        end

        local tbSelectedMsg = self.scriptMessagesList:GetAllSelectedMsg()
        if #tbSelectedMsg > 0 then
            UIHelper.ShowConfirm(g_tStrings.STR_MESSAGEBOARD_CLEAR, function ()
                for _, tMessage in ipairs(tbSelectedMsg) do
                    --GetChatManager().RemoteCallToChatServer("DelBulletinMessage", BULLETIN_MESSAGE_TYPE.HOMELAND_BOARD, szLandID, tMessage.uSequenceID)
					RemoteCallToServer("On_HomeLand_DelMessage", szLandID, BULLETIN_MESSAGE_TYPE.HOMELAND_BOARD, tMessage.uSequenceID)
                end
            end)
        end
    end)

	Event.Reg(self, EventType.OnHomeMessageBoardChooseMsg, function ()
        --当退出时删除勾选的留言
        if not self.scriptMessagesList then
            return
        end

        local tbSelectedMsg = self.scriptMessagesList:GetAllSelectedMsg()
        if #tbSelectedMsg == #tMessage then
            UIHelper.SetSelected(self.scriptBottom.TogChooseAll, true, false)
		else
            UIHelper.SetSelected(self.scriptBottom.TogChooseAll, false, false)
        end
    end)

    Event.Reg(self, EventType.OnHomeMessageBoardSendMsg, function (szContent, dwMessageType)
        local tSrcData = ChatParser.Parse(szContent)
        if not tSrcData or #tSrcData == 0 then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_MESSAGEBOARD_EMPTY)
            return
        end

        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "player talk") then
            return
        end

        if dwMessageType == 1 then
            tSrcData = DataModel.DealWithEmotion(tSrcData)

			-- 一天只能发一条
			if nLastBulletinTime ~= 0 then
				local tOldBulletinTime = TimeToDate(nLastBulletinTime)
				local tNewBulletinTime = TimeToDate(GetCurrentTime())

				if tOldBulletinTime.year == tNewBulletinTime.year and tOldBulletinTime.month == tNewBulletinTime.month and tOldBulletinTime.day == tNewBulletinTime.day then
					OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_MESSAGEBOARD_UPPER)
					return
				end
			end
        end
        dwSenderIndex = dwMessageType
        --GetChatManager().SetCustomDataAndSync("Bulletin", tSrcData)

		if dwMessageType == 1 then
			RemoteCallToServer("On_HomeLand_MessageBoxCommit", tHomelandInfo.nLandIndex, tSrcData)
		elseif dwSenderIndex == 2 and bIsHouseOwner then
			RemoteCallToServer("On_HomeLand_MessageBoxOwner", tHomelandInfo.nLandIndex, tSrcData)
		end
    end)

    Event.Reg(self, "HOME_LAND_RESULT_CODE_INT", function ()
        local nResultType = arg0
		if nResultType == HOMELAND_RESULT_CODE.APPLY_LAND_INFO then --申请某块地详情
			local nMapID, nCopyIndex, nLandIndex = arg1, arg2, arg3
			if nMapID == tHomelandInfo.nMapID and nCopyIndex == tHomelandInfo.nCopyIndex and nLandIndex == tHomelandInfo.nLandIndex then
				DataModel.UpdateOwnerName(nMapID, nCopyIndex, nLandIndex)
                self.scriptOwnerCard:UpdateOwnerCardInfo(tHomelandInfo)
			end
		elseif nResultType == HOMELAND_RESULT_CODE.APPLY_HLLAND_INFO then  --申请某块地详情
			local pHlMgr = GetHomelandMgrObj()
			local tInfo = pHlMgr.GetHLLandInfo(self.nLandIndex)
			uPermission = tInfo.uPermission
			self.scriptBottom:OnEnter(bIsHouseOwner, uPermission)
		elseif nResultType ==  HOMELAND_RESULT_CODE.DEL_BULLETIN_SUCCESS then
            GetHomelandMgr().SyncBulletinData(szLandID)
		elseif nResultType == HOMELAND_RESULT_CODE.ADD_BULLETIN_FILTER_CHAT then
			OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_MESSAGEBOARD_FILTER)
		end
    end)

	Event.Reg(self, "HOME_LAND_RESULT_CODE", function ()
		local nResultType = arg0
        if nResultType == HOMELAND_RESULT_CODE.ADD_BULLETIN_SUCCESS then
			OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_MESSAGEBOARD_ADDSUCCESS)
            GetHomelandMgr().SyncBulletinData(szLandID)
        elseif nResultType == HOMELAND_RESULT_CODE.SYNC_BULLETIN_SUCCESS then
            DataModel.UpdateAllMessage()
			self.scriptMessagesList:UpdateMessageList(tMessage)
            DataModel.UpdateOwnerMessage()
            self.scriptOwnerCard:UpdateOwnerCardInfo(tHomelandInfo)
        end
	end)

    Event.Reg(self, "ON_CHAT_EVENT_NOTIFY", function ()
        if arg0 == CHAT_SERVER_NOTIFY_EVENT_CODE_TYPE.CUSTOM_DATA then
			local dwReason = arg1
			if dwReason == CHAT_SERVER_NOTIFY_EVENT_REASON_TYPE.SET_CHAT_CONTENT_SUCCESS and arg5 == "Bulletin" then
				if dwSenderIndex == 1 then
					RemoteCallToServer("On_HomeLand_MessageBoxCommit", tHomelandInfo.nLandIndex)
				elseif dwSenderIndex == 2 and bIsHouseOwner then
					RemoteCallToServer("On_HomeLand_MessageBoxOwner", tHomelandInfo.nLandIndex)
				end
			end
		elseif arg0 == CHAT_SERVER_NOTIFY_EVENT_CODE_TYPE.BULLETIN then
			local dwReason = arg1
			if dwReason == CHAT_SERVER_NOTIFY_EVENT_REASON_TYPE.SYNC_MESSAGE then --同步所有消息
				if arg2 == BULLETIN_MESSAGE_TYPE.HOMELAND_BOARD then
					DataModel.UpdateAllMessage(self.dwMapID, self.nCopyIndex, self.nLandIndex)
					self.scriptMessagesList:UpdateMessageList(tMessage)
				elseif arg2 == BULLETIN_MESSAGE_TYPE.HOMELAND_OWNER then
					DataModel.UpdateOwnerMessage()
                    self.scriptOwnerCard:UpdateOwnerCardInfo(tHomelandInfo)
				end
			elseif dwReason == CHAT_SERVER_NOTIFY_EVENT_REASON_TYPE.DAY_LIMIT then --一天一条
				OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_MESSAGEBOARD_UPPER)
			elseif dwReason == CHAT_SERVER_NOTIFY_EVENT_REASON_TYPE.ADD_MSG_SUCCESS then --添加成功，再次SYNC
				if arg2 == BULLETIN_MESSAGE_TYPE.HOMELAND_BOARD then
					OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_MESSAGEBOARD_ADDSUCCESS)
					GetChatManager().RemoteCallToChatServer("SyncBulletinMessage", BULLETIN_MESSAGE_TYPE.HOMELAND_BOARD, szLandID, 1, 32)
				elseif arg2 == BULLETIN_MESSAGE_TYPE.HOMELAND_OWNER then
					GetChatManager().RemoteCallToChatServer("SyncBulletinMessage", BULLETIN_MESSAGE_TYPE.HOMELAND_OWNER, szLandID, 1, 1)
				end
			elseif dwReason == CHAT_SERVER_NOTIFY_EVENT_REASON_TYPE.DEL_MSG_SUCCESS then --删除成功
				if not bEmpty then
					OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_MESSAGEBOARD_DELSUCCESS)
					DataModel.UpdateAllMessage(self.dwMapID, self.nCopyIndex, self.nLandIndex)
					self.scriptMessagesList:UpdateMessageList(tMessage)
				end
			elseif dwReason == CHAT_SERVER_NOTIFY_EVENT_REASON_TYPE.LIKE_MSG_SUCCESS then --点赞成功
				OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_MESSAGEBOARD_LIKESUC)
				if arg2 == BULLETIN_MESSAGE_TYPE.HOMELAND_BOARD then
					--由于点赞不影响消息数目，本地对应修改
					-- View.UpdateMessageLike(hFrame, arg3, true)
				elseif arg2 == BULLETIN_MESSAGE_TYPE.HOMELAND_OWNER then
					GetChatManager().RemoteCallToChatServer("SyncBulletinMessage", BULLETIN_MESSAGE_TYPE.HOMELAND_OWNER, szLandID, 1, 1)
				end
			elseif dwReason == CHAT_SERVER_NOTIFY_EVENT_REASON_TYPE.LIKE_MSG_REPEAT then --点赞重复
				OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_MESSAGEBOARD_LIKEFAL)
				-- View.UpdateMessageLike(hFrame, arg3, false)
			elseif dwReason == CHAT_SERVER_NOTIFY_EVENT_REASON_TYPE.COOL_DOWN then --操作冷却
				OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_MESSAGEBOARD_COOLDOWN)
                self.scriptMessagesList:UpdateMessageList(tMessage)
                self.scriptOwnerCard:UpdateOwnerCardInfo(tHomelandInfo)
			elseif dwReason == CHAT_SERVER_NOTIFY_EVENT_REASON_TYPE.BAN_TALK then --禁言
				OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_MESSAGEBOARD_MUTE)
			elseif dwReason == CHAT_SERVER_NOTIFY_EVENT_REASON_TYPE.FILTER_TALK then --过滤
				OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_MESSAGEBOARD_FILTER)
			end
		end
    end)

end

function UIHomeMessageBoardView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomeMessageBoardView:Init()
    self:UpdateLastOpenTime()
    DataModel.Init(self.dwMapID, self.nCopyIndex, self.nLandIndex)
    DataModel.SyncBulletinMessage()

    self.scriptOwnerCard = UIHelper.GetBindScript(self.WidgetOwner)
    self.scriptMessagesList = UIHelper.GetBindScript(self.WidgetMessages)
    self.scriptBottom = UIHelper.GetBindScript(self.WidgetBottom)

    self.scriptOwnerCard:OnEnter(bIsHouseOwner)
    self.scriptMessagesList:OnEnter(bIsHouseOwner)
    self.scriptBottom:OnEnter(bIsHouseOwner, uPermission)
end

function UIHomeMessageBoardView:UpdateLastOpenTime()
    --目前好像没作用
    if bIsHouseOwner then
		local dwLastTime = Storage.HomeLand.dwLastOpenTime
		local nowTime = GetCurrentTime()
		Storage.HomeLand.dwLastOpenTime = nowTime
        Storage.HomeLand.Dirty()
	end
end

return UIHomeMessageBoardView