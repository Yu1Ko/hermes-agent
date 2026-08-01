-- ---------------------------------------------------------------------------------
-- Author: zengzipeng
-- Name: EmotionData
-- Date: 2023-05-11 15:40:39
-- Desc: 表情管理
-- ---------------------------------------------------------------------------------

EmotionData = EmotionData or {className = "EmotionData"}
local self = EmotionData
-------------------------------------------------------------------------
-- 表情动作
-------------------------------------------------------------------------
local SINGLE_ATCTION_TYPE 	= 0
local TYPE_COMMON 			= 1
local _tEmotionActionMap 	= {} --id为索引 EMOTIONACTION表
local _tEmotionActionAdd 	= {} --id为索引 EMOTIONACTIONADD表
local _tMyEmotionActions 	= {}
local _tAllEmotionActions 	= {} --type为索引
local nMaxFaviEmotionNum = 5
local SELFIE_FILE_PATH_NAME = "selfiedata"

function EmotionData.Init()
	if not self.bInit then
		_tEmotionActionMap 	= {}
		_tEmotionActionAdd 	= {}
		_tMyEmotionActions 	= {}
		_tAllEmotionActions = {}

		for i, tLine in ilines(g_tTable.EmotionActionAdd) do
			if not _tEmotionActionAdd[tLine.dwID] then
				_tEmotionActionAdd[tLine.dwID] = {}
			end
			_tEmotionActionAdd[tLine.dwID][tLine.nRoleType] = tLine
		end

		for i, tLine in ilines(g_tTable.EmotionAction) do
			_tEmotionActionMap[tLine.dwID] = tLine
			if not _tAllEmotionActions[tLine.nActionType] then
				_tAllEmotionActions[tLine.nActionType] = {}
			end
			if tLine.bShow then
				tLine.szName = tLine.szCommand:sub(2)
				table.insert(_tAllEmotionActions[tLine.nActionType], tLine)
			end
		end

		self:InitFaceMotions()

		self:RegEvent()
		self.bInit = true
	end
end

function EmotionData.UnInit()
    self.bInit = false
end

function EmotionData.OnLogin()

end

function EmotionData.RegEvent()
	Event.Reg(self, "ON_ADD_EMOTION_ACTION_NOTIFY", function ()
		self:OnEmotionActionUpdate()
	end)
	Event.Reg(self, "ON_DEL_EMOTION_ACTION_NOTIFY", function ()
		self:OnEmotionActionUpdate()
	end)
end

function EmotionData.QuickLoad()
	if not self.quickLoad then
		self.quickLoad = true
		self:OnFirstLoadEnd()
	end
end

function EmotionData.UnQuickLoad()
	self.quickLoad = false
end

function EmotionData.OnFirstLoadEnd()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

	local nRoleType = hPlayer.nRoleType
	for k, tLine in pairs(_tEmotionActionMap) do
		local tAdd = self.GetEmotionActionAddData(tLine.dwID, nRoleType)
		if tAdd then
			if tAdd.szCommand ~= "" then
				tLine.szCommand = tAdd.szCommand
			end
			if tAdd.nIconID ~= 0 then
				tLine.nIconID 	= tAdd.nIconID
			end
			tLine.szTip 	= tAdd.szTip
			tLine.szPath 	= tAdd.szPath
			tLine.nFrame 	= tAdd.nFrame
		end
		tLine.szName = tLine.szCommand:sub(2)
	end
	self:OnEmotionActionUpdate()
end

--get function
function EmotionData.GetEmotionAction(szKey)
	if szKey then
		return _tEmotionActionMap[szKey]
	else
		return  _tAllEmotionActions
	end
end

function EmotionData.GetEmotionActionPackage(nType)
	if nType then
		return _tAllEmotionActions[nType]
	else
		return _tAllEmotionActions
	end
end


function EmotionData.GetEmotionActionAddData(nID, nRoleType)
	if nID and nRoleType and _tEmotionActionAdd[nID] then
		return _tEmotionActionAdd[nID][nRoleType]
	end
end

function EmotionData.GetEmotionCommonType()
	return TYPE_COMMON
end

function EmotionData.IsEmotionActionCollected(dwID)
	if not _tMyEmotionActions then
		return
	end
	if dwID and _tMyEmotionActions[dwID] then
		return true
	else
		return false
	end
end

function EmotionData.GetFaviEmotionActions()
	return GetClientPlayer().GetMobileEmotionActionDIYList() or {}
end

--judge function
function EmotionData.IsFaviEmotionAction(dwID)
	local bFavi = false
	local tFaviEmotionActions = GetClientPlayer().GetMobileEmotionActionDIYList() or {}
	if dwID then
		for _, id in ipairs(tFaviEmotionActions) do
			if dwID == id then
				bFavi = true
				break
			end
		end
	end
	return bFavi
end

function EmotionData.IsFaviEmotionActionbFull()
	local tFaviEmotionActions = GetClientPlayer().GetMobileEmotionActionDIYList() or {}
	if #tFaviEmotionActions < nMaxFaviEmotionNum then
		return false
	else
		return true
	end
end

---

function EmotionData.OnEmotionActionUpdate()
	_tMyEmotionActions = {}
	_tAllEmotionActions[TYPE_COMMON] = {}

	for _, tLine in pairs(_tEmotionActionMap) do
		tLine.bLearned = false
	end

	for _, tAction in ipairs(GetClientPlayer().GetEmotionActionList()) do
		local tLine = _tEmotionActionMap[tAction.dwID]
		if tLine then
			if tLine.bShow then
				_tMyEmotionActions[tLine.dwID] = tLine
				_tMyEmotionActions[tLine.szCommand] = tLine

				tLine.bLearned = true
				if tLine.nActionType == TYPE_COMMON then
					if tLine.bInteract then
						table.insert(_tAllEmotionActions[TYPE_COMMON], 1, tLine)
					else
						table.insert(_tAllEmotionActions[TYPE_COMMON], tLine)
					end
				end
			end
			tLine.bInteract = tAction.dwType ~= SINGLE_ATCTION_TYPE
		end
	end

	local function fnADegree(a, b)
		if a.bInteract and b.bInteract then
			return a.dwID < b.dwID
		elseif a.bInteract then
			return true
		elseif b.bInteract then
			return false
		else
			return a.dwID < b.dwID
		end
	end

	local function fnBDegree(a, b)
		local bIsNewA = RedpointHelper.Emotion_IsNew(a.dwID)
		local bIsNewB = RedpointHelper.Emotion_IsNew(b.dwID)
		if bIsNewA ~= bIsNewB then
			return bIsNewA
		end

		if a.bLearned and b.bLearned then
			return a.dwID < b.dwID
		elseif a.bLearned then
			return true
		elseif b.bLearned then
			return false
		else
			return a.dwID < b.dwID
		end
	end

	local function fnCDegree(a, b)
		local nA, nB
		for _, tLine in pairs(a) do
			nA = tLine.nActionType
			break
		end
		for _, tLine in pairs(b) do
			nB = tLine.nActionType
			break
		end
		return nA < nB
	end

	table.sort(_tAllEmotionActions, fnCDegree)
	for k, Actions in pairs(_tAllEmotionActions) do
		if k ~= TYPE_COMMON then
			for _, tLine in pairs(Actions) do
				if _tMyEmotionActions[tLine.dwID] then
					tLine.bLearned = true
				else
					tLine.bLearned = false
				end
			end
		end

		if k == TYPE_COMMON then
			table.sort(Actions, fnADegree)
		else
			table.sort(Actions, fnBDegree)
		end
	end
end

function EmotionData.ProcessEmotionAction(szKey, bTalk, bSilent)
	local me = GetClientPlayer()
	local ea = _tEmotionActionMap[szKey]
	if ea then
		if not  _tMyEmotionActions[szKey] then
			OutputMessage("MSG_SYS", g_tStrings.EMOTION_SPECIAL.STR_EMOTION_NOT_LEARN)
			return false
		end
		if me.dwEmotionActionID > 0 then
			if me.dwEmotionActionID == ea.dwID then
				self.StopCurrentEmotionAction(ea.dwID)
			else
				OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_ERROR_IN_OTACTION)
				return false
			end
			return
		end
		local nType = ea.nActionType or TYPE_COMMON
		if bTalk then
			if nType == 1 or nType == 2 then
				Event.Dispatch("EmotionActionOpenChat", ea)
			end
		end
		local nType, dwID = me.GetTarget()
		FireUIEvent("ON_USE_EMOTION", nType, dwID, ea.szCommand)
		RemoteCallToServer("On_EmotionAction_DoAction", ea.dwID, nil, SelfieOneClickModeData.bOpenOneMode)
	else
		OutputMessage("MSG_SYS", g_tStrings.EMOTION_SPECIAL.STR_EMOTION_COMMAND_ERROR)
		return false
	end
	return true
end

function EmotionData.StopCurrentEmotionAction(dwActionID)
	GetClientPlayer().StopCurrentEmotionAction()
	RemoteCallToServer("On_StopAction_ByID", dwActionID)
end

function EmotionData.ForceStopCurAction()
	local player = GetClientPlayer()
	if not player then
		return
	end
	player.StopCurrentEmotionAction()
	if player.dwEmotionActionID > 0 then
		RemoteCallToServer("On_StopAction_ByID", player.dwEmotionActionID )
	end
end

function EmotionData.ProcessEmotionActionTemp(szKey, bTalk, bSilent)
	local me = GetClientPlayer()
	local ea = _tEmotionActionMap[szKey]
	if ea then
		if not  _tMyEmotionActions[szKey] then
			OutputMessage("MSG_SYS", g_tStrings.EMOTION_SPECIAL.STR_EMOTION_NOT_LEARN)
			return false
		end
		if me.dwEmotionActionID > 0 then
			if me.dwEmotionActionID == ea.dwID then
				self.StopCurrentEmotionAction(ea.dwID)
			else
				OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_ERROR_IN_OTACTION)
				return false
			end
			return false
		end
		local nType = ea.nActionType or TYPE_COMMON
		if bTalk then
			if nType == 1 or nType == 2 then
				self.TalkEmotionData(ea)
			end
		end
		local nType, dwID = me.GetTarget()
		FireUIEvent("ON_USE_EMOTION", nType, dwID, ea.szCommand)
		EmotionData.OnUseEmotionForRemote(ea.szCommand)
		RemoteCallToServer("On_EmotionAction_DoAction", ea.dwID)
	else
		OutputMessage("MSG_SYS", g_tStrings.EMOTION_SPECIAL.STR_EMOTION_COMMAND_ERROR)
		return false
	end
	return true
end

function EmotionData.TalkEmotionData(tEmotionAction)
	local player = GetClientPlayer()
	if not player then
	  return
	end

    local szWhisperName = nil
    local dwTargetType, dwTargetID
    local szName, szText

    -- 要求统一发近聊
    local nChannelID = ChatData.GetSendChannelID()

    if not szWhisperName then
		szWhisperName = ""
		dwTargetType, dwTargetID = player.GetTarget()
	end

	if szWhisperName ~= "" then
		szName = szWhisperName
		szText = tEmotionAction.szTarget
        szText = string.gsub(szText, "$n", szName)
    elseif dwTargetType == TARGET.PLAYER then
		local playerT = GetPlayer(dwTargetID)
		if playerT then
			szName = playerT.szName
			szText = tEmotionAction.szTarget
            szText = string.gsub(szText, "$n", szName)
		end
	elseif dwTargetType == TARGET.NPC then
		local npcT = GetNpc(dwTargetID)
		if npcT then
			szName = npcT.szName
			szText = tEmotionAction.szTarget
            szText = string.gsub(szText, "$n", szName)
		end
    else
        szText = tEmotionAction.szNoTarget
    end

    szText = string.gsub(szText, "$N", player.szName)

    local tWord =
	{
		{type = "text", text = szText},
    }

	if nChannelID == PLAYER_TALK_CHANNEL.WHISPER then
		local tbPlayerIDList = ChatData.GetWhisperPlayerIDList() or {}
		if table.contain_value(tbPlayerIDList, UIHelper.GBKToUTF8(szName)) then
			szWhisperName = szName
		else
			nChannelID = PLAYER_TALK_CHANNEL.NEARBY
		end
	end

    Player_Talk(player, nChannelID, szWhisperName, tWord, false)
end

-- 邀请
local aInviteActionQueue = {}
function EmotionData.RefuseInviteAction(dwInviterID)
	for i, dwID in ipairs_r(aInviteActionQueue) do
		if dwID == dwInviterID then
			table.remove(aInviteActionQueue, i)
		end
	end
	GetClientPlayer().InviteEmotionActionRespond(dwInviterID, false)
end

function EmotionData.AcceptInviteAction(dwInviterID)
	local me = GetClientPlayer()
	for i, dwID in ipairs_r(aInviteActionQueue) do
		if dwInviterID ~= dwID then
			me.InviteEmotionActionRespond(dwID, false)
		end
		table.remove(aInviteActionQueue, i)
	end
	me.InviteEmotionActionRespond(dwInviterID, true)
end

function EmotionData.OnActionInvited(dwInviterID)
	for i, dwID in ipairs(aInviteActionQueue) do
		if dwID == dwInviterID then
			return true
		end
	end
	table.insert(aInviteActionQueue, dwInviterID)
end

-- 远程调用
function EmotionData.OnUseEmotionForRemote(szEmotion)
	local UTF8szEmotion = UIHelper.GBKToUTF8(szEmotion)
	local player = GetClientPlayer()
	if not player then
		return
	end
	local dwTargetType, dwTargetID = player.GetTarget()
	local npc = GetNpc(dwTargetID)
	-- 师徒系统的表情任务, 任务ID一次为	:
	local tMasterSysQuestID = {4676, 4687, 4688, 4689, 4690, 5336, 7152, 7910, 9832,11349}
	if dwTargetType == 4 and dwTargetID ~= player.dwID and UTF8szEmotion == g_tStrings.EMOTION_SPECIAL.EMOTION_REMOTE_ZUOYI then
		for i = 1, #tMasterSysQuestID do
			if player.GetQuestPhase(tMasterSysQuestID[i]) == 1 or player.GetQuestPhase(tMasterSysQuestID[i]) == 2 then
				RemoteCallToServer("OnClientUseEmotionForRemote", tMasterSysQuestID[i], dwTargetID, szEmotion)
				break;
			end
		end
	end

	if UTF8szEmotion ==  g_tStrings.EMOTION_SPECIAL.EMOTION_REMOTE_SHANGXIANG then
		if (player.GetQuestPhase(5099) == 1 and player.nFaceDirection > 40 and player.nFaceDirection < 80)
			or player.GetQuestPhase(5164) == 1 then
			RemoteCallToServer("EmotionForQuest", szEmotion)
		end
		if player.GetQuestPhase(11053) == 1 then--丐帮任务
			RemoteCallToServer("EmotionForQuest", szEmotion)
		end
		if player.GetScene().dwMapID == 647 then--银霜口_场景探索_上香
			RemoteCallToServer("EmotionForQuest", szEmotion)
		end
	end

	if UTF8szEmotion ==  "/演奏" then
			if player.GetQuestPhase(12250) == 1 then--重阳演奏任务
				if npc.dwTemplateID == 37154 then
						RemoteCallToServer("EmotionForQuest", szEmotion)
				end
			end
	end

	if UTF8szEmotion == g_tStrings.EMOTION_SPECIAL.EMOTION_REMOTE_ZUOYI then

		if player.GetQuestPhase(8338) == 1 then
			if npc.dwTemplateID == 9455 or npc.dwTemplateID == 9479 or npc.dwTemplateID == 9458 or npc.dwTemplateID == 9462 then
				RemoteCallToServer("EmotionForQuest", szEmotion)
			end
		end
		if player.GetQuestPhase(7052) == 1 and dwTargetType == 3 then
			RemoteCallToServer("EmotionForQuest", szEmotion)
		end
		if player.GetQuestPhase(6524) == 1 then
			RemoteCallToServer("EmotionForQuest", szEmotion)
		end
		if player.GetQuestPhase(9280) == 1 then
			RemoteCallToServer("EmotionForQuest", szEmotion)
		end
		if player.GetQuestPhase(9792) == 1 then--门派随机任务 “明教·参拜明尊”任务
			RemoteCallToServer("EmotionForQuest", szEmotion)
		end
		if ActivityData.IsActivityOn(33) then --家园拜年
			RemoteCallToServer("EmotionForQuest", szEmotion)
		end
	end

	if dwTargetType == 4 and player.GetQuestPhase(7837) == 1 then
		local tEmotion = {
			["/笑"] = {}, ["/睡觉"] = {}, ["/神掌"] = {}, ["/踢"] = {}, ["/圈圈"] = {},
			["/表白"] = {}, ["/调戏"] = {}, ["/高兴"] = {}, ["/害羞"] = {}, ["/口哨"] = {},
			["/亲吻"] = {},["/撒娇"] = {},["/上香"] = {},["/被推"] = {},
		}
		if tEmotion[UTF8szEmotion] then
			RemoteCallToServer("EmotionForQuest", szEmotion)
		end
	end

	if dwTargetType == 3 and (UTF8szEmotion == "/喝" or UTF8szEmotion == "/喝酒") then
		local npc = GetNpc(dwTargetID)
		if not npc or npc.dwTemplateID ~= 16615 then
			return
		end
		RemoteCallToServer("EmotionForQuest", szEmotion)
	end

	--穿戴时装去找主城的节日大使
	if dwTargetType==3 and npc.dwTemplateID==7572 then
		local tEmotion = {
			["/笑"] = {},
			["/作揖"] = {},
		}
		if tEmotion[UTF8szEmotion] then
			RemoteCallToServer("EmotionForFengce", szEmotion)
		end
	end

	--花朝节小花交互阶段1
	if dwTargetType == 3 and npc.dwTemplateID==59401 then
		--local npcFlower = GetNpc(dwTargetID)
		local tEmotion = {
			["/说话"] = {}, ["/鼓掌"] = {}, ["/作揖"] = {}, ["/笑"] = {},
			["/哭"] = {}, ["/吃"] = {}, ["/喝"] = {}, ["/坐"] = {}, ["/跪"] = {},
			["/点头"] = {}, ["/摇头"] = {}, ["/支持"] = {}, ["/苦恼"] = {}, ["/猜拳"] = {},
			["/石头"] = {}, ["/剪刀"] = {}, ["/布"] = {}, ["/睡觉"] = {}, ["/神掌"] = {},
			["/演奏"] = {}, ["/踢"] = {}, ["/圈圈"] = {}, ["/惩罚"] = {}, ["/甩手"] = {},
			["/表白"] = {}, ["/调戏"] = {}, ["/高兴"] = {}, ["/害羞"] = {}, ["/口哨"] = {},
			["/亲吻"] = {}, ["/撒娇"] = {}, ["/生气"] = {}, ["/思考"] = {}, ["/挑衅"] = {},
			["/上香"] = {}, ["/推"] = {},["/被推"] = {},
		}

		if tEmotion[UTF8szEmotion] then
			RemoteCallToServer("EmotionForQuest", szEmotion)
		end
	end
	--花朝节小花交互阶段2
	if dwTargetType == 3 and npc.dwTemplateID==59402 then
		--local npcFlower = GetNpc(dwTargetID)
		local tEmotion = {
			["/说话"] = {}, ["/鼓掌"] = {}, ["/作揖"] = {}, ["/笑"] = {},
			["/哭"] = {}, ["/吃"] = {}, ["/喝"] = {}, ["/坐"] = {}, ["/跪"] = {},
			["/点头"] = {}, ["/摇头"] = {}, ["/支持"] = {}, ["/苦恼"] = {}, ["/猜拳"] = {},
			["/石头"] = {}, ["/剪刀"] = {}, ["/布"] = {}, ["/睡觉"] = {}, ["/神掌"] = {},
			["/演奏"] = {}, ["/踢"] = {}, ["/圈圈"] = {}, ["/惩罚"] = {}, ["/甩手"] = {},
			["/表白"] = {}, ["/调戏"] = {}, ["/高兴"] = {}, ["/害羞"] = {}, ["/口哨"] = {},
			["/亲吻"] = {}, ["/撒娇"] = {}, ["/生气"] = {}, ["/思考"] = {}, ["/挑衅"] = {},
			["/上香"] = {}, ["/推"] = {},["/被推"] = {},
		}

		if tEmotion[UTF8szEmotion] then
			RemoteCallToServer("EmotionForQuest", szEmotion)
		end
	end
	--花朝节小花交互阶段3
	if dwTargetType == 3 and npc.dwTemplateID==59403 then
		--local npcFlower = GetNpc(dwTargetID)
		local tEmotion = {
			["/说话"] = {}, ["/鼓掌"] = {}, ["/作揖"] = {}, ["/笑"] = {},
			["/哭"] = {}, ["/吃"] = {}, ["/喝"] = {}, ["/坐"] = {}, ["/跪"] = {},
			["/点头"] = {}, ["/摇头"] = {}, ["/支持"] = {}, ["/苦恼"] = {}, ["/猜拳"] = {},
			["/石头"] = {}, ["/剪刀"] = {}, ["/布"] = {}, ["/睡觉"] = {}, ["/神掌"] = {},
			["/演奏"] = {}, ["/踢"] = {}, ["/圈圈"] = {}, ["/惩罚"] = {}, ["/甩手"] = {},
			["/表白"] = {}, ["/调戏"] = {}, ["/高兴"] = {}, ["/害羞"] = {}, ["/口哨"] = {},
			["/亲吻"] = {}, ["/撒娇"] = {}, ["/生气"] = {}, ["/思考"] = {}, ["/挑衅"] = {},
			["/上香"] = {}, ["/推"] = {},["/被推"] = {},
		}

		if tEmotion[UTF8szEmotion] then
			RemoteCallToServer("EmotionForQuest", szEmotion)
		end
	end
	--花朝节小花交互阶段4
	if dwTargetType == 3 and npc.dwTemplateID==59407 then
		--local npcFlower = GetNpc(dwTargetID)
		local tEmotion = {
			["/说话"] = {}, ["/鼓掌"] = {}, ["/作揖"] = {}, ["/笑"] = {},
			["/哭"] = {}, ["/吃"] = {}, ["/喝"] = {}, ["/坐"] = {}, ["/跪"] = {},
			["/点头"] = {}, ["/摇头"] = {}, ["/支持"] = {}, ["/苦恼"] = {}, ["/猜拳"] = {},
			["/石头"] = {}, ["/剪刀"] = {}, ["/布"] = {}, ["/睡觉"] = {}, ["/神掌"] = {},
			["/演奏"] = {}, ["/踢"] = {}, ["/圈圈"] = {}, ["/惩罚"] = {}, ["/甩手"] = {},
			["/表白"] = {}, ["/调戏"] = {}, ["/高兴"] = {}, ["/害羞"] = {}, ["/口哨"] = {},
			["/亲吻"] = {}, ["/撒娇"] = {}, ["/生气"] = {}, ["/思考"] = {}, ["/挑衅"] = {},
			["/上香"] = {}, ["/推"] = {},["/被推"] = {},
		}

		if tEmotion[UTF8szEmotion] then
			RemoteCallToServer("EmotionForQuest", szEmotion)
		end
	end

	--刀宗跟宠任务
	if dwTargetType ==3 and UTF8szEmotion ==  "/挑衅" then
		if player.GetQuestPhase(25464) == 1 then
			if npc.dwTemplateID == 112869 then
				RemoteCallToServer("EmotionForQuest", szEmotion)
			end
		end
	end
end
-------------------------------------------------------------------------
-- 捏脸表情
-------------------------------------------------------------------------
local _tFaceMotionMap = {} --id为索引
local _tAllFaceMotions = {}

function EmotionData.InitFaceMotions()
    _tFaceMotionMap = {}
	_tAllFaceMotions = {}

	for i, tLine in ilines(g_tTable.FaceMotion) do
		_tFaceMotionMap[tLine.dwID] = tLine
		table.insert(_tAllFaceMotions, tLine.dwID)
	end
end

function EmotionData.GetFaceMotions()
	return _tAllFaceMotions
end

function EmotionData.GetFaceMotion(dwID)
	return _tFaceMotionMap[dwID]
end

function EmotionData.ProcessFaceMotion(dwID)
	local player = GetClientPlayer()
	if not player then
		return false
	end

	if player.nMoveState == MOVE_STATE.ON_DEATH or player.nMoveState == MOVE_STATE.ON_SIT then
		OutputMessage("MSG_ANNOUNCE_RED", "当前状态无法播放面部表情")
		return false
	end


	if type(dwID) == "number" then
		local tFaceMotion = _tFaceMotionMap[dwID]
		if not tFaceMotion then
			return false
		end
	
		rlcmd(string.format("play face motion %d %d", player.dwID, tFaceMotion.dwFaceActionID))
		FireUIEvent("ON_PLAY_FACE_MOTION", tFaceMotion.dwFaceActionID)
    elseif type(dwID) == "string" then
        local bEnable = 1
        local startPos = dwID:find(SELFIE_FILE_PATH_NAME, 1, true) 
        local newPath = startPos and dwID:sub(startPos) or dwID
        rlcmd(string.format("play ai face motion %d %d %s", player.dwID, bEnable, newPath))
        FireUIEvent("ON_PLAY_FACE_MOTION")
    end
	return true
end
