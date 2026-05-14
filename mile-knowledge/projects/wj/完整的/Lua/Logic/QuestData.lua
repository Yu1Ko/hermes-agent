
-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: QuestData
-- Date: 2022-11-14 14:54:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local MONEY_BULLION_TO_COPPER_RATE = 100000000
local MONEY_GOlD_TO_COPPER_RATE = 10000
local MONEY_SLIVER_TO_COPPER_RATE = 100
local MONEY_GOLD_TO_SLIVER_RATE = 100
local HIDE_TRACE_DISTANCE   = 2 * 64        -- 多少米之内隐藏箭头的
local szColorFinish = "#95FF95"
local szColorUnFinish = "#D7F6FF"
local IdentityOpenQuestID = 15459

local nTypeList = {
	[QuestType.All] = {1,6,4,7,8,9,2,3,0,5},
	[QuestType.Course] = {1},
	[QuestType.Activity] = {4,7,8,9},
	[QuestType.Daily] = {2,3},
	[QuestType.Branch] = {0},
	[QuestType.Other] = {5},
	[QuestType.Top] = {6},--置顶任务
}

local tbTopQuestClassID = {3719, 3720, 3721, 3686, 3806}

-- 任务追踪的一些特殊处理
local tbQuestTrackerSpecialHadler = {
	[11864] = function() return AutoNav.StartNavPlan_Trading() end,
	[11991] = function() return AutoNav.StartNavPlan_Trading() end,
	[15459] = function() return QuestData.CheckShowOpenIdentity() end,
	[21751] = function() return AutoNav.StartNav_RemotePoint("jy_songxin") end,
	[25223] = function() return AutoNav.StartNav_RemotePoint("25223") end,
	[27669] = function() return AutoNav.StartNav_RemotePoint("27669") end,
	[28871] = function() return AutoNav.StartNav_RemotePoint("28871") end,
	[28991] = function() return AutoNav.StartNav_RemotePoint("28991") end,
	[28992] = function() return AutoNav.StartNav_RemotePoint("28992") end,
	[28997] = function() return AutoNav.StartNav_RemotePoint("28997") end,
	[28998] = function() return AutoNav.StartNav_RemotePoint("28998") end,
	[29003] = function() return AutoNav.StartNav_RemotePoint("29003") end,
	[29007] = function() return AutoNav.StartNav_RemotePoint("29007") end,
}

local TRACING_QUEST_ID = "TRACING_QUEST_ID"

QuestData = QuestData or {className = "QuestData"}
local self = QuestData
-------------------------------- 消息定义 --------------------------------

function QuestData.Init()
	self.Event = {}
	self.Event.XXX = "QuestData.Msg.XXX"
	self.tCompleted = {}

	self.tbQuestTypeMap = {}
	self.nCheckTimer = {}
	self.registerEvents()
end

function QuestData.UnInit()

end

function QuestData.OnLogin()
end

function QuestData.OnFirstLoadEnd()
end

function QuestData.OnReload()
	self.tCompleted = {}
	Event.UnRegAll(self)
	self.registerEvents()
end

local function GetItemNameByItem(item)
	if item.nGenre == ITEM_GENRE.BOOK then
		local nBookID, nSegID = GlobelRecipeID2BookID(item.nBookID)
		return Table_GetSegmentName(nBookID, nSegID) or g_tStrings.BOOK
	else
		return Table_GetItemName(item.nUiId)
	end
end

--[[
{
	szClassName = "主线·稻香村",
	tbQuestList = {
		tbQuestInfo,
		tbQuestInfo,
	}
	szClassName = "主线·XXXX",
	tbQuestList = {
		tbQuestInfo,
		tbQuestInfo,
	}
}
]]--
function QuestData.GetOneTypeQuestList(nQuestType)

	local szTypeName = QuestTypeName[nQuestType]
	local tbResQuestList = {}
	local tbClassList = {}
	local tbNormalList = {}--没有class的任务

	local player = g_pClientPlayer
	local tbQuestIDList = player.GetQuestList()

	for nIndex, nQuestID in ipairs(tbQuestIDList) do
		local tbQuestInfo = Table_GetQuestStringInfo(nQuestID)
		local tbQuestConfig = GetQuestInfo(nQuestID)
		if tbQuestInfo and table.contain_value(nTypeList[nQuestType],tbQuestInfo.nType) and tbQuestInfo.IsAdventure ~= 1 then--IsAdventure奇遇任务不可见
			local nClassID = tbQuestConfig.dwQuestClassID
			if nClassID then
				local szClassName = szTypeName .. "·" .. UIHelper.GBKToUTF8(Table_GetQuestClass(nClassID))
				if not tbClassList[szClassName] then
					tbClassList[szClassName] = {szClassName = szClassName, tbQuestList = {}}
					table.insert(tbResQuestList, tbClassList[szClassName])
				end
				table.insert(tbClassList[szClassName].tbQuestList, tbQuestInfo)
			else
				table.insert(tbNormalList, tbQuestInfo)
			end
		end
	end
	if #tbNormalList > 0 then
		table.insert(tbResQuestList, {szClassName = szTypeName, tbQuestList = tbNormalList})
	end
	return tbResQuestList
end


function QuestData.GetQuestList(nQuestType)

	local tbResQuestList = {}
	if nQuestType == QuestType.All then
		table.insert_tab(tbResQuestList, self.GetOneTypeQuestList(QuestType.Course))
		table.insert_tab(tbResQuestList, self.GetOneTypeQuestList(QuestType.Activity))
		table.insert_tab(tbResQuestList, self.GetOneTypeQuestList(QuestType.Daily))
		table.insert_tab(tbResQuestList, self.GetOneTypeQuestList(QuestType.Branch))
		table.insert_tab(tbResQuestList, self.GetOneTypeQuestList(QuestType.Other))
		table.insert_tab(tbResQuestList, self.GetOneTypeQuestList(QuestType.Top))
	else
		table.insert_tab(tbResQuestList, self.GetOneTypeQuestList(nQuestType))
	end

	return tbResQuestList
end



function QuestData.GetQuestIdList(nQuestType)
	local tbRetQuestList = {}

	local player = g_pClientPlayer
	local tbQuestIDList = player.GetQuestList()
	for nIndex, nQuestID in ipairs(tbQuestIDList) do
		local tbQuestInfo = Table_GetQuestStringInfo(nQuestID)
		if tbQuestInfo then
			if table.contain_value(nTypeList[nQuestType],tbQuestInfo.nType) then
				table.insert(tbRetQuestList,nQuestID)
			end
		end
	end
	return tbRetQuestList
end


function QuestData.GetMaxQuestIdInCourse()
	return QuestData.GetMaxQuestIdByType(QuestType.Course, QUEST_PHASE.DONE) or QuestData.GetMaxQuestIdByType(QuestType.Course, QUEST_PHASE.ACCEPT)
end

--获得当前最合适追踪的置顶任务
--根据任务class由小到大排序；class相同时根据任务id由大到小排序
function QuestData.GetTraceQuestIdInTop()
	local player = g_pClientPlayer
	if not player then return end

	local tbAllTopQuest = {}
	local tbQuest = player.GetQuestTree()
	for dwClassID, v in pairs(tbQuest) do
		if table.contain_value(tbTopQuestClassID, dwClassID) then
			for key, nQuestIndex in pairs(v) do
				local dwQuestID = player.GetQuestID(nQuestIndex)
				table.insert(tbAllTopQuest, {["nClassID"] = dwClassID, ["nQuestID"] = dwQuestID})
			end
		end
	end

	if #tbAllTopQuest == 0 then return 0 end

	table.sort(tbAllTopQuest, function(l, r)
		if l.nClassID ~= r.nClassID then
			return l.nClassID < r.nClassID
		else
			return l.nQuestID > r.nQuestID
		end
	end)
	return tbAllTopQuest[1].nQuestID
end

function QuestData.GetMaxQuestIdInCurMapByType(nType, nQuestState)

	local tbQuestConfition = {
		[QUEST_PHASE.ERROR] = function(nQuestID) return self.IsError(nQuestID) end,
		[QUEST_PHASE.UNACCEPT] = function(nQuestID) return self.IsUnAccept(nQuestID) end,
		[QUEST_PHASE.ACCEPT] = function(nQuestID) return self.IsProgressing(nQuestID) end,
		[QUEST_PHASE.DONE] = function(nQuestID) return self.IsDone(nQuestID) end,
		[QUEST_PHASE.FINISH] = function(nQuestID) return self.IsFinished(nQuestID) end,

	}
	local fnCondition = tbQuestConfition[nQuestState]

	local tbQuestIDList = self.GetQuestIdList(nType)
	local nMaxQuestID = 0
	for nIndex, nQuestID in ipairs(tbQuestIDList) do
		if fnCondition(nQuestID) and self.IsInCurrentMap(nQuestID) and not self.IsQuestIDProhibit(nQuestID) then
			nMaxQuestID = math.max(nMaxQuestID, nQuestID)
		end
	end
	return nMaxQuestID
end

function QuestData.GetMaxQuestIdByType(nType, nQuestState)

	local tbQuestConfition = {
		[QUEST_PHASE.ERROR] = function(nQuestID) return self.IsError(nQuestID) end,
		[QUEST_PHASE.UNACCEPT] = function(nQuestID) return self.IsUnAccept(nQuestID) end,
		[QUEST_PHASE.ACCEPT] = function(nQuestID) return self.IsProgressing(nQuestID) end,
		[QUEST_PHASE.DONE] = function(nQuestID) return self.IsDone(nQuestID) end,
		[QUEST_PHASE.FINISH] = function(nQuestID) return self.IsFinished(nQuestID) end,
	}
	local fnCondition = tbQuestConfition[nQuestState]

	local tbQuestIDList = self.GetQuestIdList(nType)
	local nMaxQuestID = 0
	for nIndex, nQuestID in ipairs(tbQuestIDList) do
		if fnCondition(nQuestID) and not self.IsQuestIDProhibit(nQuestID) then
			nMaxQuestID = math.max(nMaxQuestID, nQuestID)
		end
	end
	return nMaxQuestID
end


function QuestData.IsMaxQuestIdInCourse(nQuestID)
	return self.GetMaxQuestIdInCourse() == nQuestID
end

function QuestData.CanUnTraceQuest(nQuestID)
	local bCourse = self.IsCourseQuest(nQuestID)
	if bCourse then
		local nCount = self.GetQuestCountByType(QuestType.Course)
		if nCount == 1 and g_pClientPlayer.nLevel < 120 then
			return false
		end
	end
	return true
end

function QuestData.GetQuestCountByType(nType)
	local nCount = 0
	local tbCourseList = self.GetQuestList(nType)
	for szName, tbInfo in pairs(tbCourseList) do
		if tbInfo.tbQuestList then
			nCount = nCount + #tbInfo.tbQuestList
		end
	end
	return nCount
end

function QuestData.IsCourseQuest(nQuestID)
	local bCourseQuest = false
	local tbQuestInfo = Table_GetQuestStringInfo(nQuestID)
	if tbQuestInfo then
		bCourseQuest = table.contain_value(nTypeList[QuestType.Course], tbQuestInfo.nType)
	end
	return bCourseQuest
end

function QuestData.IsDoubleExpQuest(nQuestID)
	local hPlayer = g_pClientPlayer
	local tbQuestInfo = Table_GetQuestStringInfo(nQuestID)
	if tbQuestInfo then
		local dwBuffId = tbQuestInfo.dwQuestBuffID
		if dwBuffId and dwBuffId ~= 0 then
			return Player_IsBuffExist(dwBuffId, hPlayer)
		end
	end
	return false
end

function QuestData.GetDoubleExpQuestTip(nQuestID)
	local szText = g_tStrings.STR_REMIND_2EXP
	local nExp, nP1, nP2 = g_pClientPlayer.GetQuestExpAttenuation(nQuestID)
	if nP1 ~= 100 then
		szText = g_tStrings.QUEST_EXHAUST_MSG1 .. (100 - nP1) .. "%"..g_tStrings.STR_FULL_STOP.."\n"
	end
	if nP2 ~= 100 then
		szText = szText .. g_tStrings.QUEST_EXHAUST_MSG2 .. (100 - nP2) .. "%" ..g_tStrings.STR_FULL_STOP.."\n"
	end
	return szText
end

function QuestData.GetQuestStateAndLevel(dwQuestID, dwTargetType, dwTargetID)
	local player = g_pClientPlayer
	local eState = player.GetQuestState(dwQuestID)
	local eCanAccept = player.CanAcceptQuest(dwQuestID, dwTargetType, dwTargetID)
	local questInfo = GetQuestInfo(dwQuestID)
	local nQuestLevel = questInfo.nLevel
	local nPlayerLevel = player.nLevel
	local eCanFinish = player.CanFinishQuest(dwQuestID, dwTargetType, dwTargetID)

	if (eCanAccept == QUEST_RESULT.SUCCESS) then
		if ((nPlayerLevel - nQuestLevel) > QUEST_HIDE_LEVEL) then
			return QUEST_STATE_HIDE, nQuestLevel
		else
			return QUEST_STATE_YELLOW_EXCLAMATION, nQuestLevel
		end
	elseif (eCanFinish == QUEST_RESULT.SUCCESS) then
		return QUEST_STATE_YELLOW_QUESTION, nQuestLevel
	else
		if (eCanFinish == QUEST_RESULT.ERROR_END_NPC_TARGET
				or eCanFinish == QUEST_RESULT.ERROR_END_DOODAD_TARGET) then
			return QUEST_STATE_DUN_DIA, nQuestLevel
		elseif (eCanAccept == QUEST_RESULT.TOO_LOW_LEVEL and ((questInfo.nMinLevel - nPlayerLevel) < QUEST_WHITE_LEVEL)) then
			return QUEST_STATE_WHITE_EXCLAMATION, nQuestLevel
		else
			if (eCanAccept == QUEST_RESULT.ALREADY_ACCEPTED) then
				return QUEST_STATE_WHITE_QUESTION, nQuestLevel
			elseif eCanAccept == QUEST_RESULT.NO_NEED_ACCEPT then
				if eCanFinish == QUEST_RESULT.TOO_LOW_LEVEL or eCanFinish == QUEST_RESULT.PREQUEST_UNFINISHED or
				eCanFinish == QUEST_RESULT.ERROR_REPUTE or eCanFinish == QUEST_RESULT.ERROR_CAMP or eCanFinish == QUEST_RESULT.ERROR_GENDER or
				eCanFinish == QUEST_RESULT.ERROR_ROLETYPE or eCanFinish == QUEST_RESULT.ERROR_FORCE_ID or eCanFinish == QUEST_RESULT.COOLDOWN or
				eCanFinish == QUEST_RESULT.ERROR_REPUTE  then
					return QUEST_STATE_NO_MARK, nQuestLevel
				else
					if not questInfo.bRepeat and eState == QUEST_STATE.FINISHED then
						return QUEST_STATE_NO_MARK, nQuestLevel
					else
						return QUEST_STATE_WHITE_QUESTION, nQuestLevel
					end
				end
			end
		end
	end

	return QUEST_STATE_NO_MARK, nQuestLevel
end

function QuestData.IsTopQuest(nQuestID)
	local bCourseQuest = false
	local tbQuestInfo = Table_GetQuestStringInfo(nQuestID)
	if tbQuestInfo then
		bCourseQuest = table.contain_value(nTypeList[QuestType.Top], tbQuestInfo.nType)
	end
	return bCourseQuest
end

function QuestData.IsSystemQuest(dwQuestID)
	local questInfo = GetQuestInfo(dwQuestID)
	if not questInfo then
		return false
	end
	return questInfo.bSystemQuest
end

--QuestData自己定义的类型, 如QuestType.Course
function QuestData.GetQuestNewType(nQuestID)
	local tbQuestInfo = Table_GetQuestStringInfo(nQuestID)
	if table.contain_value(nTypeList[QuestType.Course], tbQuestInfo.nType) then
		return QuestType.Course
	end

	if table.contain_value(nTypeList[QuestType.Activity], tbQuestInfo.nType) then
		return QuestType.Activity
	end

	if table.contain_value(nTypeList[QuestType.Daily], tbQuestInfo.nType) then
		return QuestType.Daily
	end

	if table.contain_value(nTypeList[QuestType.Branch], tbQuestInfo.nType) then
		return QuestType.Branch
	end

	if table.contain_value(nTypeList[QuestType.Other], tbQuestInfo.nType) then
		return QuestType.Other
	end

	if table.contain_value(nTypeList[QuestType.Top], tbQuestInfo.nType) then
		return QuestType.Top
	end
end


--------------------------------------------------------------------------------获取当前任务目标相关数据----------------------------------
function QuestData.GetQuestTargetValueList(nQuestID, tbTargetList)

	local tQuestStringInfo 	= Table_GetQuestStringInfo(nQuestID)
	local questTrace = g_pClientPlayer.GetQuestTraceInfo(nQuestID)
	local nFinishedCount = 0
	for k, v in pairs(questTrace.quest_state) do

		local bFinished = false
		v.have = math.min(v.have, v.need)
		if v.have == v.need then
			nFinishedCount = nFinishedCount + 1
			bFinished = true
		end

		if tQuestStringInfo.tProgressBar[k] then
			table.insert(tbTargetList, {nHave = v.have, nNeed = v.need, szName = tQuestStringInfo["szQuestValueStr" .. (v.i + 1)]})
		else
			local szName = tQuestStringInfo["szQuestValueStr" .. (v.i + 1)]
			local szHead = string.format("<color=%s><img src='%s' width='34' height='30'/>", bFinished and szColorFinish or szColorUnFinish, bFinished and "UIAtlas2_Task_Task1_img_finished" or "UIAtlas2_Task_Task1_img_ongoing")
			local szTail = "</color>"
			local szTarget = szHead..UIHelper.GBKToUTF8(szName).."："..UIHelper.GBKToUTF8(v.have.."/"..v.need)..szTail
			table.insert(tbTargetList, szTarget)
		end
	end
	return nFinishedCount == table.get_len(questTrace.quest_state)
end

----获取当前任务目标的需要QuestValue
function QuestData.GetQuestTargetValueStr(dwQuestID)
	local tQuestStringInfo 	= Table_GetQuestStringInfo(dwQuestID)
	local player = g_pClientPlayer
	local questTrace = player.GetQuestTraceInfo(dwQuestID)
	local tbQuestValueStrList = {}
	local nFinishedCount = 0
	local bIsAllFinished = false
	local szText = ""
	for k, v in pairs(questTrace.quest_state) do
		local szName = tQuestStringInfo["szQuestValueStr" .. (v.i + 1)]
		v.have = math.min(v.have, v.need)
		local bFinished = false
		if v.have == v.need then
			nFinishedCount = nFinishedCount + 1
			bFinished = true
		end
		local szHead = string.format("<color=%s><img src='%s' width='34' height='30'/>", bFinished and szColorFinish or szColorUnFinish, bFinished and "UIAtlas2_Task_Task1_img_finished" or "UIAtlas2_Task_Task1_img_ongoing")
		local szTail = "</color>"
		szText = szText..szHead..UIHelper.GBKToUTF8(szName).."："..UIHelper.GBKToUTF8(v.have.."/"..v.need)..szTail
		szText = szText..(k == table.get_len(questTrace.quest_state) and "" or "\n")
	end

	bIsAllFinished = nFinishedCount == table.get_len(questTrace.quest_state)
	return szText, bIsAllFinished
end

function QuestData.GetQuestTargetKillNpcList(nQuestID, tbTargetList)

	local questTrace = g_pClientPlayer.GetQuestTraceInfo(nQuestID)
	local nFinishedCount = 0
	for k, v in pairs(questTrace.kill_npc) do
		v.have = math.min(v.have, v.need)
		local szName = Table_GetNpcTemplateName(v.template_id)
		if not szName or szName == "" then
			szName = "Unknown Npc"
		end
		local bFinished = false
		if v.have == v.need then
			nFinishedCount = nFinishedCount + 1
			bFinished = true
		end
		local szHead = string.format("<color=%s><img src='%s' width='34' height='30'/>", bFinished and szColorFinish or szColorUnFinish, bFinished and "UIAtlas2_Task_Task1_img_finished" or "UIAtlas2_Task_Task1_img_ongoing")
		local szTail = "</color>"
		local szTarget = szHead..UIHelper.GBKToUTF8(szName).."："..UIHelper.GBKToUTF8(v.have.."/"..v.need)..szTail
		table.insert(tbTargetList, szTarget)
	end

	return nFinishedCount == table.get_len(questTrace.kill_npc)
end

----获取当前任务需要杀死的npc列表
function QuestData.GetQuestTargetKillNpcStr(dwQuestID)
	local player = g_pClientPlayer
	local questTrace = player.GetQuestTraceInfo(dwQuestID)
	local nFinishedCount = 0
	local bIsAllFinished = false
	local szText = ""
	for k, v in pairs(questTrace.kill_npc) do
		v.have = math.min(v.have, v.need)
		local szName = Table_GetNpcTemplateName(v.template_id)
		if not szName or szName == "" then
			szName = "Unknown Npc"
		end
		local bFinished = false
		if v.have == v.need then
			nFinishedCount = nFinishedCount + 1
			bFinished = true
		end
		local szHead = string.format("<color=%s><img src='%s' width='34' height='30'/>", bFinished and szColorFinish or szColorUnFinish, bFinished and "UIAtlas2_Task_Task1_img_finished" or "UIAtlas2_Task_Task1_img_ongoing")
		local szTail = "</color>"
		szText = szText..szHead..UIHelper.GBKToUTF8(szName).."："..UIHelper.GBKToUTF8(v.have.."/"..v.need)..szTail
		szText = szText..(k == table.get_len(questTrace.kill_npc) and "" or "\n")
	end
	bIsAllFinished = nFinishedCount == table.get_len(questTrace.kill_npc)
	return szText, bIsAllFinished
end

function QuestData.GetQuestTargetNeedItemList(nQuestID, tbTargetList)

	local player = g_pClientPlayer
	local questTrace = player.GetQuestTraceInfo(nQuestID)
	local nFinishedCount = 0
	local szText = ""
	for k, v in pairs(questTrace.need_item) do
		local itemInfo = GetItemInfo(v.type, v.index)
		local nBookID = v.need
		if itemInfo.nGenre == ITEM_GENRE.BOOK then
			v.need = 1
		end
		v.have = math.min(v.have, v.need)
		local szName = "Unknown Item"
		if itemInfo then
			szName = ItemData.GetItemNameByItemInfo(itemInfo, nBookID)
		end

		local bFinished = false
		if v.have == v.need then
			nFinishedCount = nFinishedCount + 1
			bFinished = true
		end
		local szHead = string.format("<color=%s><img src='%s' width='34' height='30'/>", bFinished and szColorFinish or szColorUnFinish, bFinished and "UIAtlas2_Task_Task1_img_finished" or "UIAtlas2_Task_Task1_img_ongoing")
		local szTail = "</color>"
	 	local szTarget = szHead..UIHelper.GBKToUTF8(szName).."："..UIHelper.GBKToUTF8(v.have.."/"..v.need)..szTail
		table.insert(tbTargetList, szTarget)
	end
	return nFinishedCount == table.get_len(questTrace.need_item)
end

---获取当前任务需要获取的道具
function  QuestData.GetQuestTargetNeedItemStr(dwQuestID)
	local player = g_pClientPlayer
	local questTrace = player.GetQuestTraceInfo(dwQuestID)
	local nFinishedCount = 0
	local bIsAllFinished = false
	local szText = ""
	for k, v in pairs(questTrace.need_item) do
		local itemInfo = GetItemInfo(v.type, v.index)
		local nBookID = v.need
		if itemInfo.nGenre == ITEM_GENRE.BOOK then
			v.need = 1
		end
		v.have = math.min(v.have, v.need)
		local szName = "Unknown Item"
		if itemInfo then
			szName = ItemData.GetItemNameByItemInfo(itemInfo, nBookID)
		end

		local bFinished = false
		if v.have == v.need then
			nFinishedCount = nFinishedCount + 1
			bFinished = true
		end
		local szHead = string.format("<color=%s><img src='%s' width='34' height='30'/>", bFinished and szColorFinish or szColorUnFinish, bFinished and "UIAtlas2_Task_Task1_img_finished" or "UIAtlas2_Task_Task1_img_ongoing")
		local szTail = "</color>"
	 	szText = szText..szHead..UIHelper.GBKToUTF8(szName).."："..UIHelper.GBKToUTF8(v.have.."/"..v.need)..szTail
		szText = szText..(k == table.get_len(questTrace.need_item) and "" or "\n")
	end
	bIsAllFinished = nFinishedCount == table.get_len(questTrace.need_item)
	return szText, bIsAllFinished
end

-------------------------------------------------------------获取当前任务奖励---------------------------------


-- PresentExp                                // 交任务时奖励的经验
-- PresentMoney                              // 交任务时奖励的金钱数量
-- PresentAssistThew                         // 协助任务奖励体力
-- PresentAssistStamina                      // 协助任务奖励精力
-- PresentAssistFriendship                   // 协助任务奖励好感度
-- PresentPrestige                           // 任务奖励威望
-- PresentContribution                       // 任务奖励贡献值
-- PresentExp2Contribution                   // 交任务时若玩家满级,则奖励经验转换成奖励贡献值(数目由此值给出)
-- PresentTrain                              // 任务奖励修为
-- PresentJustice                            // 任务奖励侠义值
-- PresentExamPrint                          // 任务奖励监本印文
-- PresentArenaAward                         // 任务奖励名剑点
-- PresentActivityAward                      // 任务奖励活动奖励
-- PresentVigor                              // 任务奖励活力值
-- PresentArchitecture                       // 任务奖励家园货币
-- AddTongDevelopmentPoint                   // 交任务时奖励的帮会扩展点
-- AddTongFund                               // 交任务时奖励的帮会资金
-- AddTongResource                           // 交任务时奖励的帮会资源
-- PlayerIdentityExp                         // 任务奖励身份经验
function  QuestData.GetCurQuestAwardList(dwQuestID, bCanSelect)
	local tbCurQuestAwardList = {}
	local tbQuestInfo = GetQuestInfo(dwQuestID)
	local tbQuestInfoHortation = tbQuestInfo.GetHortation()
    local value = 0

	if tbQuestInfoHortation then
		if tbQuestInfoHortation.money then
			table.insert(tbCurQuestAwardList, {g_tStrings.Quest.STR_QUEST_CAN_GET_MONEY, tbQuestInfoHortation.money})
		end

        value = tbQuestInfo.GetPresentValue(CURRENCY_TYPE.EXAMPRINT)
		if value ~= 0 then --监本印文
			table.insert(tbCurQuestAwardList, {g_tStrings.Quest.STR_CURRENT_EXAMPRINT, value})
		end

        value = tbQuestInfo.GetPresentValue(CURRENCY_TYPE.JUSTICE)
		if value ~= 0 then --侠义值
			table.insert(tbCurQuestAwardList, {g_tStrings.Quest.STR_CURRENT_XIAYI, value})
		end
        
        value = tbQuestInfo.GetPresentValue(CURRENCY_TYPE.PRESTIGE)
		if value ~= 0 then --威望
			table.insert(tbCurQuestAwardList, {g_tStrings.Quest.STR_CURRENT_PRESTIGE, value})
		end
	end


	if tbQuestInfo and tbQuestInfo.nTitlePoint and tbQuestInfo.nTitlePoint > 0 then --战阶积分
		table.insert(tbCurQuestAwardList, {g_tStrings.Quest.STR_CURRENT_ZHANJIE, tbQuestInfo.nTitlePoint})
	end

	if tbQuestInfoHortation then
        value = tbQuestInfo.GetPresentValue(CURRENCY_TYPE.CONTRIBUTION)
		if value ~= 0 then --帮贡
			table.insert(tbCurQuestAwardList, {g_tStrings.Quest.STR_CURRENT_CONTRIBUTION, value})
		end

		if tbQuestInfoHortation.presenttrain then -- 修为
			table.insert(tbCurQuestAwardList, {g_tStrings.Quest.STR_XIUWEI, tbQuestInfoHortation.presenttrain})
		end

		if tbQuestInfoHortation.tongfund then--帮会资金
			table.insert(tbCurQuestAwardList, {g_tStrings.Quest.STR_TONG_FUND, tbQuestInfoHortation.tongfund})
		end

		if tbQuestInfoHortation.tongresource then	--帮会载具资源
			table.insert(tbCurQuestAwardList, {g_tStrings.Quest.STR_GUILD_RESOURCE, tbQuestInfoHortation.tongresource})
		end
        
        value = tbQuestInfo.GetPresentValue(CURRENCY_TYPE.ARENAAWARD)
		if value ~= 0 then --名剑币
			table.insert(tbCurQuestAwardList, {g_tStrings.Quest.STR_CURRENT_ARENA_AWARD, value})
		end
        
        value = tbQuestInfo.GetPresentValue(CURRENCY_TYPE.ARCHITECTURE)
		if value ~= 0 then --园宅币
			table.insert(tbCurQuestAwardList, {g_tStrings.Quest.STR_HOMELAND_ARCHITECTURE_POINTS, value})
		end

		if tbQuestInfoHortation.playeridentitytype and tbQuestInfoHortation.playeridentityexp then
			-- OldQuestAcceptPanel.AppendIdentityExp(handle, h.playeridentitytype, h.playeridentityexp)
			local tbInfo = Table_GetQuestIdentityExp(tbQuestInfoHortation.playeridentitytype)
			table.insert(tbCurQuestAwardList, {g_tStrings.Quest.STR_PLAYER_IDENTITY_TYPE, tbQuestInfoHortation.playeridentityexp, nil, nil, nil, tbInfo.nIconID})
		end

		if tbQuestInfoHortation.reputation then --声望
			local szText = g_tStrings.Quest.STR_QUEST_CAN_GET_REPUTATION
			local bFirst = true
			for k, v in pairs(tbQuestInfoHortation.reputation) do
				-- local szText = ""
				-- if not bFirst then
				-- 	szText = g_tStrings.Quest.STR_PAUSE
				-- end
				local szForceName = Table_GetReputationForceInfo(v.force).szName
				-- if v.value >= 0 then
				-- 	szText = szText .. szForceName .."(+"..v.value..")"
				-- else
				-- 	szText = szText .. szForceName .."("..v.value..")"
				-- end
				-- bFirst = false
				table.insert(tbCurQuestAwardList, {UIHelper.GBKToUTF8(szForceName).."声望", v.value, nil, nil, true})
			end
		end

		if tbQuestInfoHortation.skill then
			local nSkillID = tbQuestInfoHortation.skill
			if TabHelper.GetUISkill(nSkillID) then
				-- 只显示移动端技能奖励
				local nSkillLevel = 1--奖励技能等级默认为1级
				local szText = g_tStrings.Quest.STR_QUEST_CAN_GET_SKILL..UIHelper.GBKToUTF8(Table_GetSkillName(nSkillID, nSkillLevel))
				table.insert(tbCurQuestAwardList, {szText, nSkillLevel})
			end
		end

		for i = 1, 2, 1 do
			local itemgroup = tbQuestInfoHortation["itemgroup"..i]
			if itemgroup then
				for k, v in ipairs(itemgroup) do
					local szText = ""
					local ItemInfo = GetItemInfo(v.type, v.index)
					local hPlayer = g_pClientPlayer
					if not hPlayer then return  end
					local dwForceID  = hPlayer.GetEffectForceID()

					if (not itemgroup.accord2force or v.selectindex == TransformPlayerForceToPresentIndex(dwForceID) - 1) and ItemInfo ~= nil then
						local bCanSelect = bCanSelect
						if itemgroup.all then
							bCanSelect = false
						end
						if bCanSelect == nil then bCanSelect = true end
						local szItemName = ItemData.GetItemNameByItemInfo(ItemInfo, v.count)
						szItemName = UIHelper.GBKToUTF8(szItemName)
						table.insert(tbCurQuestAwardList, {szItemName, v.count, v.type, v.index, dwID = ItemInfo.dwID, bBook = ItemInfo.nGenre == ITEM_GENRE.BOOK,
						bCanSelect = bCanSelect, selectindex = v.selectindex, selectgroup = i})
					end
				end
			end
		end
	end

	return tbCurQuestAwardList
end


function QuestData.GetQuestFinishAwardList(dwQuestID)
	local tbQuestInfo = GetQuestInfo(dwQuestID)
	local tbQuestInfoHortation = tbQuestInfo.GetHortation()
	local tbCurQuestAwardList = {}
	local nGroupCount = 0
	for i = 1, 2, 1 do
		local itemgroup = tbQuestInfoHortation["itemgroup"..i]
		if itemgroup and not itemgroup.all then
			for k, v in ipairs(itemgroup) do
				local szText = ""
				local ItemInfo = GetItemInfo(v.type, v.index)
				local hPlayer = g_pClientPlayer
				if not hPlayer then return  end
				local dwForceID  = hPlayer.GetEffectForceID()
				local szItemName = ItemData.GetItemNameByItemInfo(ItemInfo, v.count)
				szItemName = UIHelper.GBKToUTF8(szItemName)
				if (not itemgroup.accord2force or v.selectindex == TransformPlayerForceToPresentIndex(dwForceID) - 1) and ItemInfo ~= nil then
					if not tbCurQuestAwardList[i] then tbCurQuestAwardList[i] = {} end
					table.insert(tbCurQuestAwardList[i], {szItemName = szItemName, nGroup = i, nSelectIndex = v.selectindex, nStackNum = v.count, dwTabType = v.type, dwIndex = v.index,
					bMail = false, bReputation = false, bBook = ItemInfo.nGenre == ITEM_GENRE.BOOK, nIconID = nil})
				end
			end
			nGroupCount = nGroupCount + 1
		end
	end
	return tbCurQuestAwardList, nGroupCount
end

function QuestData.MoneyToBullionGoldSilverAndCopper(nMoney)
	nMoney = nMoney > 0 and nMoney or - nMoney
	local nGold = 0
	local nSilver = 0
	local nCopper = 0
	local nBullion = 0


	nBullion = nMoney / MONEY_BULLION_TO_COPPER_RATE
	nBullion = math.floor(nBullion)
	nGold = (nMoney % MONEY_BULLION_TO_COPPER_RATE) / MONEY_GOlD_TO_COPPER_RATE
	nGold = math.floor(nGold)
	nSilver = (nMoney % MONEY_GOlD_TO_COPPER_RATE) / MONEY_SLIVER_TO_COPPER_RATE
	nSilver = math.floor(nSilver)
	nCopper = nMoney % MONEY_SLIVER_TO_COPPER_RATE
	nCopper = math.floor(nCopper)

	if nMoney < 0 then
		nGold 	= -nGold
		nSilver = -nSilver
		nCopper = -nCopper
	end


	return nBullion, nGold, nSilver, nCopper
end

function QuestData.CanCelQuest(dwQuestID)
	local hPlayer = g_pClientPlayer
	if not hPlayer then return  end
	local nQuestIndex = hPlayer.GetQuestIndex(dwQuestID)
	if nQuestIndex then
		hPlayer.CancelQuest(nQuestIndex)
	end
end


function QuestData.GetQuestID(dwQuestIndex)
	local hPlayer = g_pClientPlayer
	if not hPlayer then return  end
	local dwQuestID = hPlayer.GetQuestID(dwQuestIndex)
	return dwQuestID
end

function QuestData.GetQuestTargetStringList(nQuestID)

	local szTarget = ""
	local bAllFinished = false

	local szQuestValueStr, bValueFinished = QuestData.GetQuestTargetValueStr(nQuestID)
	if szQuestValueStr ~="" then
		szTarget = szTarget..szQuestValueStr
	end

	local szCurQuestKillNpc, bKillNpcFinished = QuestData.GetQuestTargetKillNpcStr(nQuestID)
	if szCurQuestKillNpc ~= "" then
		local szHead = szTarget == "" and "" or "\n"
		szTarget = szTarget..szHead..szCurQuestKillNpc
	end

	local szCurQuestNeedItem, bNeedItemFinished = QuestData.GetQuestTargetNeedItemStr(nQuestID)
	if szCurQuestNeedItem ~= "" then
		local szHead = szTarget == "" and "" or "\n"
		szTarget = szTarget..szHead..szCurQuestNeedItem
	end

	bAllFinished = bValueFinished and bKillNpcFinished and bNeedItemFinished

	return szTarget, bAllFinished
end

function QuestData.GetQuestTargetList(nQuestID)
	local tbTargetList = {}
	local bValueFinished = self.GetQuestTargetValueList(nQuestID, tbTargetList)
	local bKillNpcFinished = self.GetQuestTargetKillNpcList(nQuestID, tbTargetList)
	local bNeedItemFinished = self.GetQuestTargetNeedItemList(nQuestID, tbTargetList)
	return tbTargetList, bValueFinished and bKillNpcFinished and bNeedItemFinished
end

function QuestData.GetQuestTargetString(nQuestID)

	if nQuestID == 0 then return "" end

	local tbTargetList, bAllFinished = QuestData.GetQuestTargetList(nQuestID)
	local tbQuestTrace = g_pClientPlayer.GetQuestTraceInfo(nQuestID)

	if bAllFinished then--任务完成

		local tbConfig = QuestData.GetQuestConfig(nQuestID)
		local szTarget = UIHelper.GBKToUTF8(tbConfig and tbConfig.szQuestFinishedObjective or "")

		--szQuestFinishedObjective为nil，则显示找到【交任务NPC/doodad】交任务
		if string.is_nil(szTarget) then
			local tbQuestInfo = self.GetQuestInfo(nQuestID)
			local szNpcName = ""
			if tbQuestInfo.dwEndNpcTemplateID ~= 0 then
				szNpcName = UIHelper.GBKToUTF8(Table_GetNpcTemplateName(tbQuestInfo.dwEndNpcTemplateID))
			elseif tbQuestInfo.dwEndDoodadTemplateID ~= 0 then
				szNpcName = UIHelper.GBKToUTF8(Table_GetDoodadTemplateName(tbQuestInfo.dwEndDoodadTemplateID))
			end
			szTarget = string.format(g_tStrings.STR_FINISH_QUEST_TIP, szNpcName)
		end

		if string.is_nil(szTarget) then
			szTarget = tbConfig and ParseTextHelper.ParseQuestObjective(UIHelper.GBKToUTF8(tbConfig.szObjective)) or ""
		end
		szTarget = string.format("<color=%s>", szColorUnFinish)..szTarget.."</color>"
		tbTargetList = {}
		table.insert(tbTargetList, szTarget)

	elseif tbQuestTrace.fail then--任务失败

		local tbConfig = QuestData.GetQuestConfig(nQuestID)
		local szTarget = tbConfig and ParseTextHelper.ParseQuestObjective(UIHelper.GBKToUTF8(tbConfig.szQuestFailedObjective)) or ""

		--szQuestFailedObjective为nil，则显示找到【接任务NPC】重新接取任务
		if string.is_nil(szTarget) then
			local tbQuestInfo = self.GetQuestInfo(nQuestID)
			local szNpcName = Table_GetNpcTemplateName(tbQuestInfo.dwStartNpcTemplateID)
			if szNpcName ~= "" then
				szTarget = FormatString(g_tStrings.QUEST_FAILED_BOJECTIVE_FOR_NPC, UIHelper.GBKToUTF8(szNpcName))
			else
				szTarget = g_tStrings.QUEST_FAILED_BOJECTIVE_FOR_NOT_NPC
			end
		end

		szTarget = string.format("<color=%s>", szColorUnFinish)..szTarget.."</color>"
		tbTargetList = {}
		table.insert(tbTargetList, szTarget)

	elseif tbQuestTrace.hungup then--任务已失效
		tbTargetList = {}
		table.insert(tbTargetList, string.format("<color=%s>", szColorUnFinish)..g_tStrings.STR_QUEST_INVALID .."</color>")

	elseif GetQuestInfo(nQuestID).nTeamRequireMode == QUEST_TEAM_REQUIRE_MODE.REQUIRE_NOT_RAID
	and not tbQuestTrace.finish and g_pClientPlayer.IsInRaid() then--此任务不能在团队队伍中完成
		tbTargetList = {}
		table.insert(tbTargetList, string.format("<color=#ff7676>", FontColorID.ImportantRed)..g_tStrings.STR_QUEST_QUEST_LIMITINRAID .."</color>")

	else--任务目标

		for nIndex, tbTargetInfo in ipairs(tbTargetList) do
			if IsString(tbTargetInfo) then
				local tbText = string.split(tbTargetInfo, "：")
				local szTarget = tbText[1].."："

				local szText1 = string.gsub(tbText[1].."：", "<(.+)>", "")
				local szText2 = string.gsub(tbText[2], "<(.+)>", "")

				local nLength1 = UIHelper.GetUtf8Width(szText1, 24)
				local nLength2 = UIHelper.GetUtf8Width(szText2, 24)

				local nRemain = nLength1 - 266--第一行图标占34个宽度

				if nRemain >= 0 then
					nRemain = 300 - (nRemain % 300)
				else
					nRemain = -nRemain
				end

				szTarget = szTarget..(nRemain < nLength2 and "\n" or "")..szText2
				tbTargetList[nIndex] = szTarget
			end
		end
	end

	return tbTargetList
end

function QuestData.GetQuestTime(nQuestID)
	local tbQuestTrace = g_pClientPlayer.GetQuestTraceInfo(nQuestID)
	local szTime = ""
	if tbQuestTrace.time and tbQuestTrace.time ~= 0 then
		local h, m, s = TimeLib.GetTimeToHourMinuteSecond(tbQuestTrace.time)
		if tbQuestTrace.fail then
			h, m, s = 0, 0, 0
		end
		if h > 0 then
			szTime = szTime..h..g_tStrings.STR_BUFF_H_TIME_H
		end
		if h > 0 or m > 0 then
			szTime = szTime..m..g_tStrings.STR_BUFF_H_TIME_M_SHORT
		end
		szTime = g_tStrings.STR_QUEST_TIME_LIMIT..szTime..s..g_tStrings.STR_BUFF_H_TIME_S
	end
	return szTime
end

function QuestData.GetQuestItemTip(nQuestID)
	if not g_pClientPlayer then return "" end
	local szItemTip = ""
	local questTrace = g_pClientPlayer.GetQuestTraceInfo(nQuestID)
	for k, v in pairs(questTrace.need_item) do
		local itemInfo = GetItemInfo(v.type, v.index)
		local nBookID = v.need
		if itemInfo.nGenre == ITEM_GENRE.BOOK then
			v.need = 1
		end
		v.have = math.min(v.have, v.need)		--逻辑在need_item上增加了v.bank v.equip
		local szName = "Unknown Item"
		if itemInfo then
			szName = ItemData.GetItemNameByItemInfo(itemInfo, nBookID)
		end

		if v.have >= v.need then
			if not questTrace.finish then
				if v.bank > 0 or v.equip > 0 then
					szItemTip = szItemTip .. "[" .. UIHelper.GBKToUTF8(szName) .. "] "
				end
			end

		end

	end
	local nTipFont = 172
	if szItemTip ~= "" then
		szItemTip = g_tStrings.STR_TWO_CHINESE_SPACE .. FormatString(g_tStrings.STR_QUEST_ITEM_IN_BANK_EQUIP, szItemTip)
		szItemTip = szItemTip .. "\n" .. g_tStrings.STR_TWO_CHINESE_SPACE .. g_tStrings.STR_QUEST_FINISH_QUEST_TIP
		szItemTip = string.format("<color=%s>", UIDialogueColorTab[nTipFont].Color) .. szItemTip .. "</c>"
	end
	return szItemTip
end

function QuestData.GetQuestConfig(nQuestID)
	return Table_GetQuestStringInfo(nQuestID)
end


function QuestData.GetQuestName(nQuestID)
	local tbQuestConf = QuestData.GetQuestConfig(nQuestID)
	return tbQuestConf and UIHelper.GBKToUTF8(tbQuestConf.szName) or ""
end

function QuestData.GetQuestInfo(nQuestID)
	return GetQuestInfo(nQuestID)
end

function QuestData.GetQuestMinLevel(nQuestID)
	local tbQuestInfo = self.GetQuestInfo(nQuestID)
	return tbQuestInfo.nMinLevel
end

function QuestData.GetQuestStartNpcOrItemName(nQuestID)
	local tbQuestInfo = self.GetQuestInfo(nQuestID)
	local szName = ""
	if tbQuestInfo.dwStartNpcTemplateID ~= 0 then
		szName = Table_GetNpcTemplateName(tbQuestInfo.dwStartNpcTemplateID)
	elseif tbQuestInfo.dwStartItemType ~= 0 and tbQuestInfo.dwStartItemIndex ~= 0 then
		local tbItemInfo = ItemData.GetItemInfo(tbQuestInfo.dwStartItemType, tbQuestInfo.dwStartItemIndex)
		if tbItemInfo then
			szName = ItemData.GetItemNameByItemInfo(tbItemInfo).. UIHelper.UTF8ToGBK(g_tStrings.TIP_ITEM)
		end
	end
	return szName
end

function QuestData.GetQuestEndNpcOrItemName(nQuestID)
	local tbQuestInfo = self.GetQuestInfo(nQuestID)
	local szName = ""
	if tbQuestInfo.dwEndNpcTemplateID ~= 0 then
		szName = Table_GetNpcTemplateName(tbQuestInfo.dwEndNpcTemplateID)
	end
	return szName
end


function QuestData.GetPreQuestNameAndTitle(nQuestID)
	local szPrev = ""
	local szTitle = ""
	local nCount = 0
	local tbQuestInfo = self.GetQuestInfo(nQuestID)
	for nIndex = 1, 4, 1 do
		local dwPrequestID = tbQuestInfo["dwPrequestID"..nIndex]
		if dwPrequestID ~= 0 then
			local tbInfo = self.GetQuestInfo(dwPrequestID)
			if not tbInfo.bHungUp and tbInfo.nLevel < 255 then
				local tbPrevQuestStringInfo = Table_GetQuestStringInfo(dwPrequestID)
				if tbPrevQuestStringInfo then
					szPrev = szPrev.."["..tbPrevQuestStringInfo.szName.."]"
					nCount = nCount + 1
				end
			end
		end
	end

	if nCount > 0 then
		local szTitle = g_tStrings.TIP_PREQUEST
		if nCount > 1 then
			if tbQuestInfo.bPrequestLogic then
				szTitle = g_tStrings.TIP_PREQUEST_ALL_FINISHED
			else
				szTitle = g_tStrings.TIP_PREQUEST_ONE_OF
			end
		end
	end

	return szTitle, szPrev
end

function QuestData.IsAdventureQuest(nQuestID)
	local tbQuestString = QuestData.GetQuestConfig(nQuestID)
	if tbQuestString then
		return tbQuestString.IsAdventure == 1
	end
	return false
end


function QuestData.GetDetailTargetList(nQuestID)

	local tbList = {}
	local tbQuestInfo = self.GetQuestInfo(nQuestID)
	local tbQuestStringInfo = self.GetQuestConfig(nQuestID)

	for nIndex = 1, 8, 1 do
		if tbQuestInfo["nQuestValue"..nIndex] ~= 0 then
			local szName = UIHelper.GBKToUTF8(tbQuestStringInfo["szQuestValueStr" .. nIndex])
			local nMapId, tbPoints = QuestData.GetQuestMarkPoints(nQuestID, "quest_state", nIndex - 1)
			local tbInfo = {}
			tbInfo.szText = g_tStrings.STR_TWO_CHINESE_SPACE .. szName .. ": " .. UIHelper.GBKToUTF8(tbQuestInfo["nQuestValue"..nIndex])
			tbInfo.bHasMap = nMapId ~= nil
			tbInfo.callBack = function()
				self.OpenQuestMap(nQuestID, nMapId, tbPoints)
			end
			table.insert(tbList, tbInfo)
		end
	end

	for nIndex = 1, 4, 1 do
		if tbQuestInfo["dwKillNpcTemplateID"..nIndex] ~= 0 then
			local nMapId, tbPoints = QuestData.GetQuestMarkPoints(nQuestID, "kill_npc", nIndex - 1)
			local tbInfo = {}
			tbInfo.szText = g_tStrings.STR_TWO_CHINESE_SPACE..UIHelper.GBKToUTF8(Table_GetNpcTemplateName(tbQuestInfo["dwKillNpcTemplateID"..nIndex]))
			..": "..UIHelper.GBKToUTF8(tbQuestInfo["dwKillNpcAmount"..nIndex])
			tbInfo.bHasMap = nMapId ~= nil
			tbInfo.callBack = function()
				self.OpenQuestMap(nQuestID, nMapId, tbPoints)
			end
			table.insert(tbList, tbInfo)
		end
	end

	for nIndex = 1, QUEST_COUNT.QUEST_END_ITEM_COUNT, 1 do
		local dwTab, dwIndex = tbQuestInfo["dwEndRequireItemType"..nIndex], tbQuestInfo["dwEndRequireItemIndex"..nIndex]
		if dwTab ~= 0 and dwIndex ~= 0 then
			local bHave = false
			for j = 1, nIndex - 1, 1 do
				if tbQuestInfo["dwEndRequireItemType"..j] == dwTab and tbQuestInfo["dwEndRequireItemIndex"..j] == dwIndex then
					bHave = true
					break
				end
			end
			if not bHave then
				local itemInfo = GetItemInfo(dwTab, dwIndex)
				local nMapId, tbPoints = QuestData.GetQuestMarkPoints(nQuestID, "need_item", nIndex - 1)
				local tbInfo = {}
				tbInfo.szText = g_tStrings.STR_TWO_CHINESE_SPACE..UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(itemInfo))..": "
				..UIHelper.GBKToUTF8(tbQuestInfo["dwEndRequireItemAmount"..nIndex])
				tbInfo.bHasMap = nMapId ~= nil
				tbInfo.callBack = function()
					self.OpenQuestMap(nQuestID, nMapId, tbPoints)
				end
				table.insert(tbList, tbInfo)
			end
		end
	end
	return tbList
end

function QuestData.OpenQuestMap(nQuestID, nMapId, tbPoints)
	local _, nMapType = GetMapParams(nMapId)
	if nMapType and nMapType ~= 1 then
		MapMgr.SetTracePoint(QuestData.GetQuestName(nQuestID), nMapId, tbPoints)
		UIMgr.Open(VIEW_ID.PanelMiddleMap, nMapId, 0)
	else
		MapMgr.OpenWorldMapTransportPanel(nMapId, true)
	end
end

--更新正在追踪的任务（将状态不对的任务剔除掉）
function QuestData.UpdateTracingQuestIDList()
	local tbAllTracingQuest = Storage.Quest.tbTracingQuestID
	for nIndex, nQuestID in ipairs(tbAllTracingQuest) do
		local nQuestState = QuestData.GetQuestPhase(nQuestID)
		if nQuestState == QUEST_PHASE.UNACCEPT or nQuestState == QUEST_PHASE.FINISH or nQuestState == QUEST_PHASE.ERROR then
			table.remove(tbAllTracingQuest, nIndex)
		end
	end
	Storage.Quest.Flush()
end

-- 获取正在追踪的任务ID
function QuestData.GetTracingQuestIDList()
	local tbAllTracingQuest = Storage.Quest.tbTracingQuestID
	local tbQuestID = {}
	for nIndex, nQuestID in ipairs(tbAllTracingQuest) do
		local nQuestState = QuestData.GetQuestPhase(nQuestID)
		if nQuestState == QUEST_PHASE.ACCEPT or nQuestState == QUEST_PHASE.DONE then --防止DX端完成的任务还在追踪
			table.insert(tbQuestID, nQuestID)
		end
	end
	return tbQuestID
end

function QuestData.SetTracingQuestID(nQuestID)

	if self.IsAdventureQuest(nQuestID) then return end --奇遇任务不追踪

	if self.IsTracingQuestID(nQuestID) then return end

	local tbQuestID = Storage.Quest.tbTracingQuestID
	table.insert(tbQuestID, 1, nQuestID)
	if #tbQuestID > MAX_TRACE_QUEST_NUM then
		table.remove(tbQuestID)
	end

	Storage.Quest.Dirty()

	Event.Dispatch(EventType.OnQuestTracingTargetChanged, nQuestID)
end

--取消追踪某任务
function QuestData.UnTraceQuestID(nQuestID)
	local tbQuestID = Storage.Quest.tbTracingQuestID
	for nIndex, nTraceQuestID in ipairs(tbQuestID) do
		if nTraceQuestID == nQuestID then
			table.remove(tbQuestID, nIndex)
			break
		end
	end
	Storage.Quest.Dirty()
	Event.Dispatch(EventType.OnQuestTracingTargetChanged)
end

function QuestData.IsTracingQuestID(nQuestID)
	local tbQuestID = Storage.Quest.tbTracingQuestID
	for nIndex, nTraceQuestID in ipairs(tbQuestID) do
		if nQuestID == nTraceQuestID then
			return true
		end
	end
	return false
end

function QuestData.AddProhibitTraceQuestID(nQuestID)
	if not self.IsCourseQuest(nQuestID) then--主线任务不禁止追踪
		Storage.Quest.tbProhibitTraceQuestID[nQuestID] = true
		Storage.Quest.Dirty()
	end
end

function QuestData.RemoveProhibitTraceQuestID(nQuestID)
	if self.IsQuestIDProhibit(nQuestID) then
		Storage.Quest.tbProhibitTraceQuestID[nQuestID] = false
		Storage.Quest.Dirty()
	end
end

function QuestData.IsQuestIDProhibit(nQuestID)
	local tbQuest = Storage.Quest.tbProhibitTraceQuestID
	return tbQuest[nQuestID] and tbQuest[nQuestID] == true
end

function QuestData.GetNpcQuestID(dwTargetID)
	local npc = GetNpc(dwTargetID)
	if npc then
		local tbQuestList = npc.GetNpcQuest()
		return tbQuestList
	end
	return {}
end

function QuestData.CanFinishQuest(dwQuestID, dwTargetType, dwTargetID)
	local hPlayer = g_pClientPlayer
	if not hPlayer then
		return
	end
	return hPlayer.CanFinishQuest(dwQuestID, dwTargetType, dwTargetID) == QUEST_RESULT.SUCCESS
end

function QuestData.CanAcceptQuest(dwQuestID, dwTargetType, dwTargetID)
	local hPlayer = g_pClientPlayer
	if not hPlayer then
		return
	end
	return hPlayer.CanAcceptQuest(dwQuestID, dwTargetType, dwTargetID) == QUEST_RESULT.SUCCESS
end

function QuestData.HaveChooseItem(dwQuestID)
	local questInfo = GetQuestInfo(dwQuestID)

	local h 		= questInfo.GetHortation()
	if not h then
		return false
	end
	local bChoose 	= false
	local tbAwardGorup = {}
	local nGroupCount = 0
	for i = 1, 2, 1 do
		local itemgroup = h["itemgroup"..i]
		if itemgroup and not itemgroup.all then
			bChoose = true
			if not tbAwardGorup[i] then
				tbAwardGorup[i] = true
				nGroupCount = nGroupCount + 1
			end
		end
	end
	return bChoose, tbAwardGorup
end


function QuestData.GetAllAcceptedQuestID()
	local player = g_pClientPlayer
	if not player then return {} end
	return player.GetQuestList()
end


function QuestData.AcceptQuest(dwTargetType, dwTargetID, dwQuestID)
	local hPlayer = g_pClientPlayer
	if not hPlayer then return  end
	hPlayer.AcceptQuest(dwTargetType, dwTargetID, dwQuestID)
	SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.Invite)
end

function QuestData.FinishQuest(dwQuestID, dwTargetType, dwTargetID, nSelect1, nSelect2)
	local hPlayer = g_pClientPlayer
	if not hPlayer then return  end
	nSelect1 = nSelect1 or 1
	nSelect2 = nSelect2 or 1
	hPlayer.FinishQuest(dwQuestID, dwTargetType, dwTargetID, nSelect1, nSelect2)
	SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.Complete)
end

function QuestData.TryFinishQuest(dwQuestID, dwTargetType, dwTargetID, nSelect1, nSelect2)
	local bHasReward = false
	local szOverflow = QuestData.HasOverFlowReward(dwQuestID)
	if szOverflow then
		UIHelper.ShowConfirm(szOverflow, function()
			QuestData.FinishQuest(dwQuestID, dwTargetType, dwTargetID, nSelect1, nSelect2)
		end)
		bHasReward = true
	else
		QuestData.FinishQuest(dwQuestID, dwTargetType, dwTargetID, nSelect1, nSelect2)
	end

	return bHasReward
end

function QuestData.HasOverFlowReward(dwQuestId)
	local player = g_pClientPlayer
	if not player then return end
	local tbInfo = GetQuestInfo(dwQuestId).GetHortation()
	if (dwQuestId == 11991 or dwQuestId == 11864) and (not tbInfo or not tbInfo.prestige) then
		tbInfo = tbInfo or {}
		tbInfo.prestige = 1500
	end

	if tbInfo then
		local tOverflowRewardNames = {}
		-- 监本印文
		if tbInfo.nPresentExamPrint and (
			player.GetExamPrintRemainSpace() < tbInfo.nPresentExamPrint or          -- 周上限
			player.GetMaxExamPrint() - player.nExamPrint < tbInfo.nPresentExamPrint -- 总上限
		) then
			table.insert(tOverflowRewardNames, g_tStrings.STR_CURRENT_EXAMPRINT)
		end
		-- 侠义值
		if tbInfo.nPresentJustice and (
			player.GetJusticeRemainSpace() < tbInfo.nPresentJustice or          -- 周上限
			player.GetMaxJustice() - player.nJustice < tbInfo.nPresentJustice   -- 总上限
		) then
			table.insert(tOverflowRewardNames, g_tStrings.STR_CURRENT_XIAYI)
		end
		-- 威望
		if tbInfo.nPresentPrestige and (
			player.GetPrestigeRemainSpace() < tbInfo.nPresentPrestige or                -- 周上限
			player.GetMaxPrestige() - player.nCurrentPrestige < tbInfo.nPresentPrestige -- 总上限
		) then
			table.insert(tOverflowRewardNames, g_tStrings.STR_CURRENT_PRESTIGE)
		end
		-- 休闲点
		if tbInfo.nPresentContribution and (
			player.GetContributionRemainSpace() < tbInfo.nPresentContribution or             -- 周上限
			player.GetMaxContribution() - player.nContribution < tbInfo.nPresentContribution -- 总上限
		) then
			table.insert(tOverflowRewardNames, g_tStrings.STR_CURRENT_CONTRIBUTION)
		end
		-- 修为
		-- if tbInfo.presenttrain and (
		-- 	player.nMaxTrainValue - player.nCurrentTrainValue < tbInfo.presenttrain -- 总上限
		-- ) then
		-- 	table.insert(tOverflowRewardNames, g_tStrings.STR_XIUWEI)
		-- end

		-- 名剑币
		if tbInfo.nPresentArenaAward and (
			player.GetArenaAwardRemainSpace() < tbInfo.nPresentArenaAward or           -- 周上限
			player.GetMaxArenaAward() - player.nArenaAward < tbInfo.nPresentArenaAward -- 总上限
		) then
			table.insert(tOverflowRewardNames, g_tStrings.STR_CURRENT_ARENA_AWARD)
		end

		-- 园宅币
		if tbInfo.nPresentArchitecture and (
			player.GetArchitectureRemainSpace() < tbInfo.nPresentArchitecture or           -- 周上限
			player.GetMaxArchitecture() - player.nArchitecture < tbInfo.nPresentArchitecture -- 总上限
		) then
			table.insert(tOverflowRewardNames, g_tStrings.STR_HOMELAND_ARCHITECTURE_POINTS)
		end
		-- 判断是否有到达上限的警告
		if #tOverflowRewardNames > 0 then
			return FormatString(g_tStrings.STR_QUEST_REACH_MAX_VALUE_WARNING, table.concat(tOverflowRewardNames, g_tStrings.STR_PAUSE))
		end
	end
	return nil
end

function QuestData.GetCanFinishQuestID(dwTargetType, dwTargetID)
	local dwQuestID = -1
	local tbQuestIDList = self.GetAllAcceptedQuestID()
	for nIndex,nQuestID in ipairs(tbQuestIDList) do
		if QuestData.CanFinishQuest(nQuestID, dwTargetType, dwTargetID) then
			dwQuestID = nQuestID
			break
		end
	end
	return dwQuestID
end

function QuestData.GetCanAcceptQuestID(dwTargetType, dwTargetID)
	local dwQuestID = -1
	tbQuestIDList = self.GetNpcQuestID(dwTargetID)
	for nIndex,nQuestID in ipairs(tbQuestIDList) do
		if QuestData.CanAcceptQuest(nQuestID, dwTargetType, dwTargetID)then
			dwQuestID = nQuestID
			break
		end
	end
	return dwQuestID
end

function QuestData.GetUnfinishedQuestID(dwTargetID)
	local dwQuestID = -1
	tbQuestIDList = self.GetNpcQuestID(dwTargetID)
	for nIndex,nQuestID in ipairs(tbQuestIDList) do
		if QuestData.GetQuestPhase(nQuestID) == QUEST_PHASE.ACCEPT then
			dwQuestID = nQuestID
			break
		end
	end
	return dwQuestID
end


function QuestData.GetAllCanAcceptQuestID(dwTargetType, dwTargetID)
	local tbQuestID = {}
	tbQuestIDList = self.GetNpcQuestID(dwTargetID)
	for nIndex,nQuestID in ipairs(tbQuestIDList) do
		if QuestData.CanAcceptQuest(nQuestID, dwTargetType, dwTargetID)then
			table.insert(tbQuestID, nQuestID)
		end
	end
	return tbQuestID
end



-- function QuestData.GetDialogueByQuestID(dwQuestID, dwTargetType, dwTargetID, dwOperation)
-- 	local tbQuestDialogueList = {}
-- 	local tbQuestRpg = Table_GetQuestRpg(dwQuestID, dwTargetType, dwTargetID, dwOperation)
-- 	if tbQuestRpg then
-- 		for i = 1,15 do
-- 			local szText = tbQuestRpg["szText"..i]
-- 			if szText and szText ~= "" then
-- 				-- local _, tbInfoList = GWTextEncoder_Encode(szText)
-- 				table.insert(tbQuestDialogueList, szText)
-- 			end
-- 		end
-- 	end

-- 	if dwOperation == 0 then --已接任务
-- 		local tQuestStringInfo = Table_GetQuestStringInfo(dwQuestID)
-- 		local player = g_pClientPlayer
-- 		local questInfo = GetQuestInfo(dwQuestID)
-- 		local dwTID, target = nil, nil
-- 		if dwTargetType == TARGET.NPC then
-- 			dwTID, target = questInfo.dwEndNpcTemplateID, GetNpc(dwTargetID)
-- 		elseif dwTargetType == TARGET.DOODAD then
-- 			dwTID, target = questInfo.dwEndDoodadTemplateID, GetDoodad(dwTargetID)
-- 		end
-- 		if not target or target.dwTemplateID ~= dwTID then
-- 			table.insert(tbQuestDialogueList, tQuestStringInfo.szDunningDialogue)
-- 		elseif player.CanFinishQuest(dwQuestID) ~= QUEST_RESULT.SUCCESS then
-- 			table.insert(tbQuestDialogueList, tQuestStringInfo.szUnfinishedDialogue)
-- 		end
-- 		if #tbQuestDialogueList == 0 then
-- 			table.insert(tbQuestDialogueList, tQuestStringInfo.szFinishedDialogue)
-- 		end
-- 	end

-- 	return tbQuestDialogueList
-- end

function QuestData.GetAcceptDes(nQuestID, dwTargetType, dwTargetID, dwOperation)
	local tbQuestRpg = Table_GetQuestRpg(nQuestID, dwTargetType, dwTargetID, dwOperation)
	return tbQuestRpg.szAcceptDes
end

function QuestData.GetQuestType(dwQuestID)
	local nType = 0

	if self.tbQuestTypeMap[dwQuestID] then
		nType = self.tbQuestTypeMap[dwQuestID]
	else
		local tQuestStringInfo = Table_GetQuestStringInfo(dwQuestID)
		if tQuestStringInfo then
			nType = tQuestStringInfo.nType
		end
		self.tbQuestTypeMap[dwQuestID] = nType
	end

	return nType
end

function QuestData.GetQuestWeight(dwQuestID, bOrder)
	local nType = QuestData.GetQuestType(dwQuestID)
	local tTypeInfo = Table_GetQuestTypeInfo(nType) or {}
	local nWeight = tTypeInfo.nWeight or 0
	if bOrder then
		return 999 - nWeight, nType
	else
		return nWeight, nType
	end
end

function QuestData.IsMainPlotQuest(dwQuestID)
	return QuestData.GetQuestType(dwQuestID) == 1
end

--[[
	获取任务所在阶段
	QUEST_PHASE =
	{
		ERROR = -1,
		UNACCEPT = 0,
		ACCEPT = 1,--未完成
		DONE = 2,--完成但没交
		FINISH = 3,--已交
	}
]]
function QuestData.GetQuestPhase(nQuestID)
	local player = g_pClientPlayer
	if not player then return {} end
	return player.GetQuestPhase(nQuestID)
end

-- 错误的任务
function QuestData.IsError(nQuestID)
	local nState = QuestData.GetQuestPhase(nQuestID)
	return nState == QUEST_PHASE.ERROR
end

-- 未接受
function QuestData.IsUnAccept(nQuestID)
	local nState = QuestData.GetQuestPhase(nQuestID)
	return nState == QUEST_PHASE.UNACCEPT
end

-- 进行中 接了未完成
function QuestData.IsProgressing(nQuestID)
	local nState = QuestData.GetQuestPhase(nQuestID)
	return nState == QUEST_PHASE.ACCEPT
end

-- 完成了没提交
function QuestData.IsDone(nQuestID)
	local nState = QuestData.GetQuestPhase(nQuestID)
	return nState == QUEST_PHASE.DONE
end

-- 完成了已提交
function QuestData.IsFinished(nQuestID)
	local nState = QuestData.GetQuestPhase(nQuestID)
	return nState == QUEST_PHASE.FINISH
end

-- 完成 包括 完成了没提交和已提交完成的
function QuestData.IsCompleted(nQuestID)
	local nState = QuestData.GetQuestPhase(nQuestID)
	return (nState == QUEST_PHASE.DONE or nState == QUEST_PHASE.FINISH)
end

function QuestData.IsFailed(nQuestID)
	if not g_pClientPlayer then return end
	local tbQuestTrace = g_pClientPlayer.GetQuestTraceInfo(nQuestID)
	return tbQuestTrace.fail == true
end

function QuestData.GetProgressingQuestID()
	local tbQuestID = self.GetAllAcceptedQuestID()
	for nIndex, nQuestID in ipairs(tbQuestID) do
		if self.IsProgressing(nQuestID) then
			return nQuestID
		end
	end
	return -1
end

function QuestData.registerEvents()
	Event.Reg(self, "SET_MAIN_PLAYER", function(nPlayerID)
		if nPlayerID == 0 then
			self.tCompleted = {}
		end
	end)

	Event.Reg(self, "QUEST_ACCEPTED", function(nQuestIndex, nQuestID)
		self.OnAcceptOrShareQuest(nQuestID)
	end)

	Event.Reg(self, "SHARE_QUEST", function(nResultCode, nQuestID, dwDestPlayerID)
		-- self.OnAcceptOrShareQuest(nQuestID)
		self.DelayAcceptQuest(nQuestID)--延迟一帧，否则GetQuestPhase状态不对会出一些问题
	end)

	Event.Reg(self, "QUEST_FINISHED", function(nQuestID, bForceFinish, bAssist, nAddStamina, nAddThew)
			self.OnFinishQuest(nQuestID, bForceFinish, bAssist)
	end)

	Event.Reg(self, "SUCCESSIVE_QUEST_FINISHED", function(nQuestID, nNextQuestID)
		self.OnFinishQuest(nQuestID, 0)
	end)

	Event.Reg(self, "SET_QUEST_STATE", function(nQuestID, nQuestState)
		if nQuestState == 1 then--任务完成
			self.OnFinishQuest(nQuestID, 0)
		elseif nQuestState == 0 then--任务取消
			self.UpdateMapQuest(nQuestID, false)
			if self.IsTracingQuestID(nQuestID) then
				self.UnTraceQuestID(nQuestID)
			end
			self.tCompleted[nQuestID] = nil
		end
	end)


	Event.Reg(self, "QUEST_CANCELED", function(nQuestID)
		self.UpdateMapQuest(nQuestID, false)
		if self.IsTracingQuestID(nQuestID) then
			self.UnTraceQuestID(nQuestID)
		end
		self.tCompleted[nQuestID] = nil
	end)


	Event.Reg(self, "QUEST_DATA_UPDATE", function(nQuestIndex, eEventType, nValue1, nValue2, nValue3)
		--当最后一个主线任务状态从1变为2时，判断一下哪个主线任务的ID最大，则自动追踪最大的那个

		if nQuestIndex >= 0 then
			self.OutPutQuestDataUpdateMessage(nQuestIndex, eEventType, nValue1, nValue2, nValue3)
		end

		local nQuestID = self.GetQuestID(nQuestIndex)
		if not nQuestID then
			return
		end

		self.checkRemoteFinish(nQuestIndex, nQuestID)

		-- local nMaxCourseID = self.GetMaxQuestIdInCurMapByType(QuestType.Course,QUEST_PHASE.DONE)
		-- if self.IsTracingQuestID(nQuestID) and self.IsCompleted(nQuestID) and self.IsCourseQuest(nQuestID) and nMaxCourseID ~= 0 then
		-- 	self.SetTracingQuestID(nMaxCourseID)
		-- end

		self.OnQuestDataUpdate(nQuestID)
	end)

	Event.Reg(self, "SKILL_UPDATE", function(dwSkillID, dwSkillLevel)
		if dwSkillLevel > 1 then
			self.ExcuteFinishQuestByType("SkillLevelUp", dwSkillID)
		end
	end)

	Event.Reg(self, EventType.OnClientPlayerEnter, function()
		self.UpdateTracingQuestIDList()
    end)

	Event.Reg(self, "UPDATE_REGION_INFO", function(nArea)
		self.nAreaID = nArea
	end)

	Event.Reg(self, "SUCCESSIVE_QUEST_FINISHED", function(nQuestID, nNextQuestID)--连续任务
		-- if self.IsTracingQuestID(nQuestID)
		self.OnFinishQuest(nQuestID, 0)
		self.OnAcceptOrShareQuest(nNextQuestID)
	end)

	Event.Reg(self, EventType.OnQuestNearTarget, function(nQuestID)
		self.OnQuestArriveTarget(nQuestID)
	end)

	Event.Reg(self, EventType.OnRoleLogin, function()
		self.tbMapQuestID = nil
	end)
end

local function fnFiltPBValue(nHave, nNeed, bProgressBar)
    if bProgressBar and nHave == nNeed then
        return true
    elseif not bProgressBar and nHave < nNeed then
        return true
    else
        return false
    end
end




function QuestData.OutPutQuestDataUpdateMessage(nQuestIndex, eEventType, nValue1, nValue2, nValue3)
	local player = g_pClientPlayer
	local dwQuestID = player.GetQuestID(nQuestIndex)
	local questTrace = player.GetQuestTraceInfo(dwQuestID)
	local tQuestStringInfo = Table_GetQuestStringInfo(dwQuestID)
	if eEventType == QUEST_EVENT_TYPE.KILL_NPC then
		for k, v in pairs(questTrace.kill_npc) do
			if v.i == nValue1 and v.have <= v.need then
				v.have = math.min(v.have, v.need)
				local szName = UIHelper.GBKToUTF8(Table_GetNpcTemplateName(v.template_id))
				if not szName or szName == "" then
					szName = "Unknown Npc"
				end
				local szText = szName ..": "..v.have.."/"..v.need
				if v.have == v.need then
					szText = szText..g_tStrings.STR_QUEST_QUEST_WAS_FINISHED
				end
				szText = szText.."\n"
				TipsHelper.ShowNormalTip(szText)
				break
			end
		end
	elseif eEventType == QUEST_EVENT_TYPE.GET_ITEM then -- nValue3 = nBookRecipeID
		for k, v in pairs(questTrace.need_item) do
			if v.type == nValue1 and v.index == nValue2 and v.have <= v.need and (nValue3 == 0 or v.need == nValue3) then
				local itemInfo = GetItemInfo(v.type, v.index)
				local nBookID = v.need
				if itemInfo.nGenre == ITEM_GENRE.BOOK then
					v.need = 1
				end
				v.have = math.min(v.have, v.need)
				local szName = "Unknown Item"
				if itemInfo then
					szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(itemInfo, nBookID))
				end
				local szText = szName..": "..v.have.."/"..v.need
				if v.have == v.need then
					szText = szText..g_tStrings.STR_QUEST_QUEST_WAS_FINISHED
				end
				szText = szText
				TipsHelper.ShowNormalTip(szText)
				break
			end
		end
	elseif eEventType == QUEST_EVENT_TYPE.SET_QUEST_VALUE then
		for k, v in pairs(questTrace.quest_state) do
			if v.i == nValue1 and fnFiltPBValue(v.have, v.need, tQuestStringInfo.tProgressBar[k]) then
				local szName = UIHelper.GBKToUTF8(tQuestStringInfo["szQuestValueStr" .. (v.i + 1)])
				v.have = math.min(v.have, v.need)
				local szText = szName..": "..v.have.."/"..v.need
				if v.have == v.need then
					szText = szText..g_tStrings.STR_QUEST_QUEST_WAS_FINISHED
				end
				szText = szText
				TipsHelper.ShowNormalTip(szText)
				break
			end
		end
	end
end

function QuestData.GetUnFinishedTraceQuestID(bInCurMap, nQuestState)
	--①、未满级追踪优先级：主线>置顶>支线>活动>日常>其它
	local tbQuestType1 = {QuestType.Course, QuestType.Top, QuestType.Branch, QuestType.Activity, QuestType.Daily, QuestType.Other}
	--②、已满级追踪优先级：置顶>主线>支线>活动>日常>其它
	local tbQuestType2 = {QuestType.Top, QuestType.Course, QuestType.Branch, QuestType.Activity, QuestType.Daily, QuestType.Other}

	local tbQuestType = (g_pClientPlayer and g_pClientPlayer.nLevel == 120) and tbQuestType2 or tbQuestType1

	for nIndex, nQuestType in ipairs(tbQuestType) do
		local nQuestID = bInCurMap and self.GetMaxQuestIdInCurMapByType(nQuestType, nQuestState) or self.GetMaxQuestIdByType(nQuestType, nQuestState)
		if nQuestID ~= 0 then
			return nQuestID
		end
	end
	return 0
end

function QuestData.FindNextTraceQuestID()
	--本地图未提交任务
	local nTraceID = self.GetUnFinishedTraceQuestID(true, QUEST_PHASE.DONE)

	--本地图已接受任务
	if nTraceID == 0 then
		nTraceID = self.GetUnFinishedTraceQuestID(true, QUEST_PHASE.ACCEPT)
	end

	--其它地图未提交任务
	if nTraceID == 0 then
		nTraceID = self.GetUnFinishedTraceQuestID(false, QUEST_PHASE.DONE)
	end

	--其它地图已接受任务
	if nTraceID == 0 then
		nTraceID = self.GetUnFinishedTraceQuestID(false, QUEST_PHASE.ACCEPT)
	end

	if nTraceID ~= 0 then
		self.SetTracingQuestID(nTraceID)
	end
end

function QuestData.OnFinishQuest(nQuestID, bForceFinish, bAssist)

	self.UpdateMapQuest(nQuestID, false)
	if QuestData.IsTracingQuestID(nQuestID) then
		self.UnTraceQuestID(nQuestID)
		self.FindNextTraceQuestID()
	end

	self.tCompleted[nQuestID] = nil

	local tQuestStringInfo = Table_GetQuestStringInfo(nQuestID)
	local eRepresentSfx
	if bAssist then
		eRepresentSfx = 10 --REPRESENT_SFX.REPRESENT_SFX_FINISH_ASSIST_QUEST
	else
		eRepresentSfx = 9 --REPRESENT_SFX.REPRESENT_SFX_FINISH_QUEST
	end
	local bShowComplete = (not tQuestStringInfo or tQuestStringInfo.IsAdventure ~= 1)
		and (not tQuestStringInfo or not tQuestStringInfo.bShieldFinishEffect)
		and bForceFinish == 0
	if bShowComplete then
		PlayLevelUpSFX(eRepresentSfx)
		TipsHelper.ShowQuestComplete(nQuestID)
	end
end

function QuestData.DelayAcceptQuest(nQuestID)
	if self.nAcceptTimer then
		Timer.DelTimer(self, self.nAcceptTimer)
		self.nAcceptTimer = nil
	end
	self.nAcceptTimer = Timer.AddFrame(self, 1, function()
		self.OnAcceptOrShareQuest(nQuestID)
	end)
end

function QuestData.OnAcceptOrShareQuest(nQuestID)
	self.UpdateMapQuest(nQuestID, true)

	local player = g_pClientPlayer
	local tbQuestIDList = player.GetQuestList()
	self.SetTracingQuestID(nQuestID)--接到新任务直接追踪

	--接到置顶任务，直接追踪
	-- if QuestData.IsTopQuest(nQuestID) then
	-- 	self.SetTracingQuestID(nQuestID)
	-- 	return
	-- end

	-- 当接到新任务后，如果任务列表只有一个任务时，直接追踪该任务，不用做新任务提示
	-- if #tbQuestIDList == 1 then
	-- 	self.SetTracingQuestID(nQuestID)
	-- 	return
	-- end

	-- 当接到新任务后，如果该任务为非主线任务，如果我当前追的不是主线任务，则直接追踪该任务,否则不做处理
	-- if (not self.IsCourseQuest(nQuestID))  then
	-- 	local nCurTracingQuestID = self.GetTracingQuestIDList()
	-- 	if not self.IsCourseQuest(nCurTracingQuestID) then
	-- 		self.SetTracingQuestID(nQuestID)
	-- 	end
	-- 	return
	-- end


	-- 当接到新任务后，如果该任务为主线任务，也直接追踪
	-- if self.IsCourseQuest(nQuestID) then
	-- 	self.SetTracingQuestID(nQuestID)
	-- 	return
	-- end

	-- -- 否则就显示新任务可接
	-- Event.Dispatch(EventType.OnNewQuestCanTracing, nQuestID)
end

function QuestData.checkRemoteFinish(nQuestIndex, nQuestID)
	if not nQuestIndex or nQuestIndex < 0 then
		return
	end

	if self.tCompleted[nQuestID] then
		return
	end

	local pPlayer = g_pClientPlayer
	if not pPlayer then
		return
	end

	local questTrace = pPlayer.GetQuestTraceInfo(nQuestID)
	if questTrace == nil then
		LOG.ERROR("QuestData.checkRemoteFinish error, nQuestID = "..tostring(nQuestID))
		return
	end

	if not questTrace.finish then
		return
	end

	local hQuestInfo = GetQuestInfo(nQuestID)
	if hQuestInfo then
		if hQuestInfo.dwNextQuestID and hQuestInfo.dwNextQuestID > 0 then
			pPlayer.RemoteCompleteQuest(nQuestID)
			self.tCompleted[nQuestID] = true
		elseif hQuestInfo.bRemoteComplete then
			pPlayer.RemoteCompleteQuest(nQuestID)
		end
	end
end

function QuestData.GetAreaID()
	return self.nAreaID
end

function QuestData.GetTracePoint(nQuestID)
	local player = g_pClientPlayer

	if not player or nQuestID == 0 then
		return
	end

	local nAreaID = self.nAreaID
	local tbQuestTrace = player.GetQuestTraceInfo(nQuestID)

	local tbPoint = {}

	if tbQuestTrace.fail then
		tbPoint = self.GetQuestFirstPoint("Failed", nQuestID, "accept", 0, nAreaID)
		--m_questvalue = updatequest_name(tQuestTrace, tQuestStringInfo)
	elseif self.IsDone(nQuestID) or (tbQuestTrace and tbQuestTrace.finish) then
		tbPoint = self.GetQuestFirstPoint("Finish", nQuestID, "finish", 0, nAreaID)
		--m_questvalue = updatequest_name(tQuestTrace, tQuestStringInfo)
	else
		for k, v in pairs(tbQuestTrace.quest_state) do
			if v.have < v.need then
				tbPoint = self.GetQuestFirstPoint("UnFinish", nQuestID, "quest_state", v.i, nAreaID)
				--m_questvalue = updatequest_state(v, tQuestStringInfo, k)
				--m_multipoint = (v.need > 1)
				break
			end
		end

		for k, v in pairs(tbQuestTrace.kill_npc) do
			if v.have < v.need then
				tbPoint = self.GetQuestFirstPoint("UnFinish", nQuestID, "kill_npc", v.i, nAreaID)
				--m_questvalue = updatequest_npc(v, k)
				--m_multipoint = (v.need > 1)
				break
			end
		end

		for k, v in pairs(tbQuestTrace.need_item) do
			if v.have < v.need then
				tbPoint = self.GetQuestFirstPoint("UnFinish", nQuestID, "need_item", v.i, nAreaID)
				--m_questvalue = updatequest_item(v, k)
				--m_multipoint = (v.need > 1)
				break
			end
		end
	end

	return tbPoint
end


function QuestData.GetQuestFirstPoint(szFinishState, m_quest_id, szType, nIndex, nAreaID)
	local hPlayer = g_pClientPlayer
	if not hPlayer then
		return
	end
	local hScene = hPlayer.GetScene()
	local dwMapID = hScene.dwMapID
	local m_tracestate = ""

	local m_tPoint, m_tRegion = TableQuest_GetFirstPoint(m_quest_id, szType, nIndex, dwMapID, nAreaID)

	if m_tPoint then
		m_tracestate = szFinishState .. "_Target"
	end

	--if m_tracestate == "UnFinish_Target" or m_tracestate == "Finish_Target" or m_tracestate == "Failed_Target" then
	if m_tracestate == "Failed_Target" then
		return
	end

	local tMapID = TableQuest_GetMapIDs(m_quest_id, szType, nIndex)
	if not tMapID then
		return
	end

	local bInDungeon = true
	for _, k in pairs(tMapID) do
		local _, nMapType = GetMapParams(k[1])
		if nMapType ~= 1 then
			bInDungeon = false
		end
	end

	if not bInDungeon then
		m_tracestate = szFinishState .. "_Carriage"
	end

	--if m_tracestate == "UnFinish_Carriage" or m_tracestate == "Finish_Carriage" or m_tracestate == "Failed_Carriage" then
	if m_tracestate == "Failed_Carriage" then
		return
	end

	return m_tPoint
end

function QuestData.GetQuestDistance(nQuestID)
	local player = g_pClientPlayer
	local tbTracePoint = self.GetTracePoint(nQuestID)
	if not tbTracePoint or #tbTracePoint == 0 then return end
	local nTargetX, nTargetY, nTargetZ = tbTracePoint[1], tbTracePoint[2], tbTracePoint[3]
	local nPlayerX, nPlayerY, nPlayerZ = player.nX, player.nY, player.nZ
	local n2DDistance = kmath.len2(nPlayerX, nPlayerY, nTargetX, nTargetY)
	return math.floor(n2DDistance / 64)
end

--优先取当前地图目标点
function QuestData.GetMapIDAndPointsByTypeAndIndex(dwQuestID, szType, nIndex, bShowLog)
	local hPlayer = g_pClientPlayer
	if not hPlayer then
		return
	end
	local hScene = hPlayer.GetScene()
	local dwSceneMapID = hScene.dwMapID
	local bContinue = true
	local nAreaID = self.nAreaID

	local function SetFollowTemplate(tPoint, dwTargetMapID)
		if not tPoint then return tPoint end
		local dwTemplateID = TableQuest_GetFirstFollowTemplate(dwQuestID, szType, nIndex, dwTargetMapID, nAreaID)
		if dwTemplateID then
			tPoint.dwTemplateID = dwTemplateID
		end
		return tPoint
	end

	local tPointList = TableQuest_GetFirstPoint(dwQuestID, szType, nIndex, dwSceneMapID, nAreaID)
	if bShowLog then
		local szPosInfo = Table_GetQuestPosInfo(dwQuestID, szType, nIndex)
		LOG.INFO("===GetMapIDAndPointsByTypeAndIndex Start  nQuestID:%s szType:%s nIndex:%s dwSceneMapID:%s nAreaID:%s tPointList:%s szPosInfo:%s===", tostring(dwQuestID),
	tostring(szType), tostring(nIndex), tostring(dwSceneMapID), tostring(nAreaID), tostring(tPointList), tostring(szPosInfo))

	end
	local dwMapID = nil
	if tPointList then
		dwMapID = dwSceneMapID
		bContinue = false
		tPointList = SetFollowTemplate(tPointList, dwSceneMapID)
	else
		local tOrderMapID = TableQuest_GetMapIDs(dwQuestID, szType, nIndex)
		if tOrderMapID and not table.is_empty(tOrderMapID) then
			dwMapID = tOrderMapID[1][1]
		end
		if dwMapID then
			tPointList = SetFollowTemplate(TableQuest_GetFirstPoint(dwQuestID, szType, nIndex, dwMapID, nAreaID), dwMapID)
		end
	end
	if bShowLog then
		LOG.INFO("===GetMapIDAndPointsByTypeAndIndex End  dwMapID:%s tPointList:%s bContinue:%s===", tostring(dwMapID),
		tostring(tPointList), tostring(bContinue))
	end

	return dwMapID, tPointList, bContinue
end

--遍历任务目标，首先取得当前地图的目标点
--若当前地图没有目标点，则取第一个未完成目标的目标点
function QuestData.GetQuestMapIDAndPoints(dwQuestID, bShowLog)
	if not dwQuestID then
		return
	end
	local hPlayer = g_pClientPlayer
	if not hPlayer then
		return
	end

	local nResMapID = nil
	local tbResPoint = nil

	local tQuestTrace = hPlayer.GetQuestTraceInfo(dwQuestID)

	if tQuestTrace.fail or self.IsUnAccept(dwQuestID) then
		return self.GetMapIDAndPointsByTypeAndIndex(dwQuestID, "accept", 0, bShowLog)
	end

	if tQuestTrace.finish or self.IsDone(dwQuestID) then
		return self.GetMapIDAndPointsByTypeAndIndex(dwQuestID, "finish", 0, bShowLog)
	end

	for k, v in pairs(tQuestTrace.quest_state) do
		if v.have < v.need then
			local dwMapID, tPointList, bContinue = self.GetMapIDAndPointsByTypeAndIndex(dwQuestID, "quest_state", v.i, bShowLog)
			if dwMapID and not bContinue then
				return dwMapID, tPointList
			end
			if nResMapID == nil then
				nResMapID = dwMapID
				tbResPoint = tPointList
			end
		end
	end

	for k, v in pairs(tQuestTrace.kill_npc) do
		if v.have < v.need then
			local dwMapID, tPointList, bContinue = self.GetMapIDAndPointsByTypeAndIndex(dwQuestID, "kill_npc", v.i, bShowLog)
			if dwMapID and not bContinue then
				return dwMapID, tPointList
			end
			if nResMapID == nil then
				nResMapID = dwMapID
				tbResPoint = tPointList
			end
		end
	end

	for k, v in pairs(tQuestTrace.need_item) do
		local itemInfo = GetItemInfo(v.type, v.index)
		local nBookID = v.need
		if itemInfo.nGenre == ITEM_GENRE.BOOK then
			v.need = 1
		end
		if v.have < v.need then
			local dwMapID, tPointList, bContinue = self.GetMapIDAndPointsByTypeAndIndex(dwQuestID, "need_item", v.i, bShowLog)
			if dwMapID and not bContinue then
				return dwMapID, tPointList
			end
			if nResMapID == nil then
				nResMapID = dwMapID
				tbResPoint = tPointList
			end
		end
	end


	return nResMapID, tbResPoint
end

function QuestData.GetQuestImg(nQuestID)
	local nQuestType = self.GetQuestNewType(nQuestID)
    local tbSprintFrame
    if nQuestType == QuestType.Branch then
        local tbQuestInfo = self.GetQuestInfo(nQuestID)
        local nLevel = tbQuestInfo and tbQuestInfo.nLevel or 1
        if nLevel < 5 then
            tbSprintFrame = QuestTypeImg[nQuestType][1]
        elseif nLevel >= 5 and nLevel <= 10 then
            tbSprintFrame = QuestTypeImg[nQuestType][2]
        else
            tbSprintFrame = QuestTypeImg[nQuestType][3]
        end
    else
        tbSprintFrame = QuestTypeImg[nQuestType]
    end

    if tbSprintFrame then
        local szSprintFrame = self.IsFinished(nQuestID) and tbSprintFrame[2] or tbSprintFrame[1]
		return szSprintFrame
	end
end


function QuestData.GetQuestMarkMapID(nQuestID, szQuestTrace, nIndex)
	local tbMapID = TableQuest_GetMapIDs(nQuestID, szQuestTrace, nIndex)
	local hPlayer = g_pClientPlayer

	for _, v in pairs(tbMapID) do
		local dwMapID = v[1]
		if dwMapID == hPlayer.GetMapID() then
			return dwMapID
		end
	end

	local dwLastUnvisitedMap = nil
	for _, v in pairs(tbMapID) do
		local dwMapID = v[1]
		if hPlayer.GetMapVisitFlag(dwMapID) then
			return dwMapID
		end
		dwLastUnvisitedMap = dwMapID
	end
	return dwLastUnvisitedMap
end


function QuestData.GetQuestMarkPoints(nQuestID, szQuestTrace, nIndex)
	local nMarkMapID = self.GetQuestMarkMapID(nQuestID, szQuestTrace, nIndex)
	local tbPoints = {}
	if nMarkMapID then tbPoints = TableQuest_GetFirstPoint(nQuestID, szQuestTrace, nIndex, nMarkMapID, self.nAreaID) end
	if #tbPoints > 0 then
		return nMarkMapID, {tbPoints[1], tbPoints[2], tbPoints[3]}
	else
		return nMarkMapID, {}
	end
end



function QuestData.GetQuestState(szType, nQuestID)
	local player = g_pClientPlayer
	if not player then
		return
	end
	local Info = GetQuestInfo(nQuestID)
	local bMain = QuestData.IsMainPlotQuest(nQuestID)

	local nState = 0
	local nType = 0
	if szType == "accept" then
		nState = 1
	elseif szType == "finish" then
		nState = 2
	else
		return
	end

	if QuestData.IsMainPlotQuest(nQuestID) then
		nType = 1
	else
		local Info = GetQuestInfo(nQuestID)
		if Info.bActivity then
			nType = 2
		elseif Info.bRepeat then
			nType = 3
		else
			local nDifficult = player.GetQuestDiffcultyLevel(nQuestID)
			if nDifficult == QUEST_DIFFICULTY_LEVEL.LOWER_LEVEL then
				nType = 4
			else
				nType = 5
			end
		end
	end
	return nType, nState
end

function QuestData.OnQuestDataUpdate(nQuestID)
	local hPlayer = g_pClientPlayer
	if not hPlayer then
		return
	end

	local tQuestTrace = hPlayer.GetQuestTraceInfo(nQuestID)
	local tStateList = tQuestTrace and tQuestTrace.quest_state
	if not tStateList then
		return
	end

	for _, tState in pairs(tStateList) do
		if tState.have >= tState.need then
			--教学 完成任务的某个变量
			FireHelpEvent("OnCommentToQuestVariable", nQuestID, tState.i)
		end
	end
end

function QuestData.IsInCurrentMap(nQuestID)
	local hPlayer = g_pClientPlayer
	if not hPlayer then
		return false, false
	end
	local hScene = hPlayer.GetScene()
	local dwMapID = hScene.dwMapID

	local nMapId, tbPoints = QuestData.GetQuestMapIDAndPoints(nQuestID)
	if nMapId ~= nil then
		return dwMapID == nMapId, true
	end
	return false, false
end

function QuestData.GetQuestVerifyList(nType)
	if self.tbVerifyQuest and self.tbVerifyQuest[nType] then
		return self.tbVerifyQuest[nType]
	end
	if not self.tbVerifyQuest then self.tbVerifyQuest = {} end

	local tab = g_tTable.UIVerifyQuest
	local row = tab:GetRowCount()
	local tline
	for i = 2, row do
		tline = tab:GetRow(i)
		self.tbVerifyQuest[tline.key] = SplitString(tline.questids, "|")
	end
	return self.tbVerifyQuest[nType]
end

function QuestData.GetAcceptedQuestID(tbQuestID)
	local player = g_pClientPlayer
	for _, id in pairs(tbQuestID) do
		if player.GetQuestIndex( tonumber(id) ) then
			return tonumber(id)
		end
	end
end

--对应端游quest_uiverify.excute
function QuestData.ExcuteFinishQuestByType(quest_type, dwSKillID)

	local tbQuestID = self.GetQuestVerifyList(quest_type)
	if not tbQuestID then
		return
	end
	local id = self.GetAcceptedQuestID(tbQuestID)
	if id then
		RemoteCallToServer("On_Quest_Finished", id, dwSKillID)
	end
end

function QuestData.InitMapQuest()
	self.tbMapQuestID = {}
	for nIndex, nQuestID in ipairs(g_pClientPlayer.GetQuestList()) do
		self.tbMapQuestID[nQuestID] = true
	end
end
function QuestData.UpdateMapQuest(nQuestID, bExist)
	if not self.tbMapQuestID then
		QuestData.InitMapQuest()
	end
	self.tbMapQuestID[nQuestID] = bExist

end

function QuestData.IsQuestExist(nQuestID)
	if not self.tbMapQuestID then
		QuestData.InitMapQuest()
	end
	return self.tbMapQuestID[nQuestID] == true
end

function QuestData.IsTargetFinished(nQuestID, nIndex)
	local questTrace = g_pClientPlayer.GetQuestTraceInfo(nQuestID)
	for k, v in pairs(questTrace.quest_state) do
		if (v.i + 1) == nIndex then
			return v.have == v.need
		end
	end
	return false
end

function QuestData.IsNpcBindQuest(dwTemplateID)
	local tbQuestList = Table_GetBindNpcQuestList(dwTemplateID)
	if tbQuestList == nil then return false end
	local bBindNpc = false
	for nIndex, tbInfo in ipairs(tbQuestList) do
		if self.IsQuestExist(tbInfo.nQuestID) and not self.IsFailed(tbInfo.nQuestID) then
			if not self.IsTargetFinished(tbInfo.nQuestID, tbInfo.nIndex) then
				bBindNpc = true
			end
		end
	end
	return bBindNpc
end

function QuestData.GetQuestStateAndIndex(nQuestID, nMapID)
	local fX, fY, fZ, szType, nIndex = self.GetQuestFinishPoint(nQuestID, nMapID)
	if fX then
		return szType, nIndex -- 已完成的的任务
	else
		fX, fY, fZ, szType, nIndex  = self.GetQuestTargetPoint(nQuestID, nMapID)
		if fX then
			return szType, nIndex
		end
	end
end

function QuestData.GetQuestFinishPoint(dwQuestID, dwMapID)
	local hPlayer = g_pClientPlayer
	if not hPlayer then
		return
	end

	local tQuestTrace = hPlayer.GetQuestTraceInfo(dwQuestID)
	if not tQuestTrace.finish then
		return
	end
	local nAreaID = self.nAreaID
	local tPoint = TableQuest_GetFirstPoint(dwQuestID, "finish", 0, dwMapID, nAreaID)

	if not tPoint then
		return
	end

	local dwActivityID = tPoint[8]
	local bMatch = true
	if dwActivityID and dwActivityID > 0 then
		bMatch = ActivityData.MatchActivity(dwActivityID)
	end

	if not bMatch then
		return
	end

	return tPoint[1], tPoint[2], tPoint[3], "finish"
end

function QuestData.IsPointShow(tPoint)
	local hPlayer = g_pClientPlayer
	if not hPlayer then
		return
	end

	local dwActivityID = tPoint[8]
	local bMatch = true
	if dwActivityID and dwActivityID > 0 then
		bMatch = ActivityData.MatchActivity(dwActivityID)
	end
	if not bMatch then
		return false
	end

	local bIdentity = true
	local dwIdentityVisiableID = tPoint[7]
	if dwIdentityVisiableID then
		if not hPlayer.IsQuestIdentityVisiable(hPlayer.dwIdentityVisiableID, dwIdentityVisiableID) then
			bIdentity = false
		end
	end
	return bIdentity
end

function QuestData.GetQuestTargetPoint(dwQuestID, dwMapID)
	local hPlayer = g_pClientPlayer
	if not hPlayer then
		return
	end
	local nAreaID = self.nAreaID
	local tQuestTrace = hPlayer.GetQuestTraceInfo(dwQuestID)
	for k, v in pairs(tQuestTrace.quest_state) do
		if v.have < v.need then
			local tPoint = TableQuest_GetFirstPoint(dwQuestID, "quest_state", v.i, dwMapID, nAreaID)
			if tPoint and self.IsPointShow(tPoint) then
				return tPoint[1], tPoint[2], tPoint[3], "quest_state", v.i
			end
		end
	end

	for k, v in pairs(tQuestTrace.kill_npc) do
		if v.have < v.need then
			local tPoint = TableQuest_GetFirstPoint(dwQuestID, "kill_npc", v.i, dwMapID, nAreaID)
			if tPoint and self.IsPointShow(tPoint) then
				return tPoint[1], tPoint[2], tPoint[3], "kill_npc", v.i
			end
		end
	end

	for k, v in pairs(tQuestTrace.need_item) do
		local itemInfo = GetItemInfo(v.type, v.index)
		local nBookID = v.need
		if itemInfo.nGenre == ITEM_GENRE.BOOK then
			v.need = 1
		end
		if v.have < v.need then
			local tPoint = TableQuest_GetFirstPoint(dwQuestID, "need_item", v.i, dwMapID, nAreaID)
			if tPoint and self.IsPointShow(tPoint) then
				return tPoint[1], tPoint[2], tPoint[3], "need_item", v.i
			end
		end
	end
end

function QuestData.GetAllQuestIDByMapID(nMapID)

	local tbRes = {}
	local player = g_pClientPlayer
	if not player then return tbRes end

	for nIndex, nQuestID in ipairs(player.GetQuestList()) do
		local fX, fY, fZ, szType, nIndex = self.GetQuestFinishPoint(nQuestID, nMapID)
		if fX then
			table.insert(tbRes, {nQuestID, {fX, fY, fZ}, true, szType, nIndex}) -- 已完成的的任务
		else
			fX, fY, fZ, szType, nIndex  = self.GetQuestTargetPoint(nQuestID, nMapID)
			if fX then
				table.insert(tbRes, {nQuestID, {fX, fY, fZ}, false, szType, nIndex}) -- 未完成的任务
			end
		end
	end

	return tbRes
end

function QuestData.GetMiddleMapMyQuestTip(nQuestID)

	local hPlayer = g_pClientPlayer
	if not hPlayer then
		return ""
	end

	local tbQuestTrace = hPlayer.GetQuestTraceInfo(nQuestID)
	local tbQuestStringInfo = Table_GetQuestStringInfo(nQuestID)

	local szText = "[" .. UIHelper.GBKToUTF8(tbQuestStringInfo.szName) .. "]"

	local szState = ""
	if tbQuestTrace.finish then
		szState = g_tStrings.STR_QUEST_QUEST_CAN_FINISH
	elseif tbQuestTrace.fail then
		szState = g_tStrings.STR_QUEST_QUEST_WAS_FAILED
	elseif tbQuestStringInfo.szQuestDiff then
		local szDifficulty = UIHelper.GBKToUTF8(tbQuestStringInfo.szQuestDiff)
		if szDifficulty ~= "" then
			szDifficulty = g_tStrings.STR_BRACKET_LEFT..szDifficulty..g_tStrings.STR_BRACKET_RIGHT
		end
		szState = szDifficulty
	end

	szText = szText..szState.."\n"

	if tbQuestTrace.finish then
		return szText
	end

	if tbQuestTrace.time then
		local nTime = tbQuestTrace.time
		if tbQuestTrace.fail then
			nTime = 0
		end
		local szTime = Timer.FormatInChinese4(nTime)
		szText = szText .. g_tStrings.STR_TWO_CHINESE_SPACE .. g_tStrings.STR_QUEST_TIME_LIMIT .. szTime .. "\n"
	end

	local szTarget , bFinished = self.GetQuestTargetStringList(nQuestID)
	szText = szText..szTarget
	return szText
end

--如果当前身上没有追踪任务的话，会自动判断主线任务是否完成，导向下一个接受主线任务的NPC
--与端游函数名保持一致
function QuestData.CheckToNextPoint()
	local player = g_pClientPlayer
	if not player then return nil end

	local tbQuest = QuestData.GetTracingQuestIDList()
	if #tbQuest > 0 then return nil end

	local nMapID = player.GetMapID()
	if not nMapID then
		return nil
	end

	local nQuestID, nMapID, tbPoints = SwordMemoriesData.GetCurrentMapQuest(nMapID)
	if nQuestID and nMapID and tbPoints then
		return {nQuestID = nQuestID, tbPoints = tbPoints}
	end

	return nil
end

function QuestData.IsShowQuestTraceInfo(dwQuestID)
	local hPlayer = g_pClientPlayer
	if not hPlayer then
		return
	end
	local tQuestTrace = hPlayer.GetQuestTraceInfo(dwQuestID)
	local hQuestInfo = GetQuestInfo(dwQuestID)
	for k, v in pairs(tQuestTrace.kill_npc) do
		if v.have < v.need then
			local dwKillNpcID = hQuestInfo["dwKillNpcTemplateID"..(v.i + 1)]
			local npc = GetNpcTemplate(dwKillNpcID)
			if not hPlayer.IsQuestIdentityVisiable(hPlayer.dwIdentityVisiableID, npc.dwIdentityVisiableID) then
				return false
			end
		end
	end

	return true
end

function QuestData.GetIdentityDesc(nQuestID)
	local szDesc = ""
	if self.IsIdentityQuest(nQuestID) then
		szDesc = "<color=#FFE26E>		当前位面世界无法完成此任务，需要在【江湖百态】中开启【方士】身份，使用身份技能前往完成。</color>"
	end
	return szDesc
end

function QuestData.OnQuestArriveTarget(nQuestID)
	if nQuestID == IdentityOpenQuestID then
		if not self.nCheckTimer[nQuestID] then--5秒CD
			self.CheckShowOpenIdentity(true)
			self.nCheckTimer[nQuestID] = Timer.Add(self, 5, function()
				self.nCheckTimer[nQuestID] = nil
			end)
		end
	end

	if self.IsIdentityQuest(nQuestID) then--里世界任务
		if not self.nCheckTimer[nQuestID] then--5秒CD
			self.CheckIdentityQuestShowConfirm(nQuestID, true)
			self.nCheckTimer[nQuestID] = Timer.Add(self, 5, function()
				self.nCheckTimer[nQuestID] = nil
			end)
		end
	end
end

function QuestData.CheckShowOpenIdentity(bNotCheckDistance)
	if bNotCheckDistance or self.GetQuestDistance(IdentityOpenQuestID) <= HIDE_TRACE_DISTANCE then
		if g_pClientPlayer and not (g_pClientPlayer.GetPlayerIdentityManager().dwCurrentIdentityType	== 3) then--未开启方式身份
			UIHelper.ShowConfirm("是否开启方士身份？", function()
				if JiangHuData.nLeftTime == nil then--不在冷却中
					g_pClientPlayer.GetPlayerIdentityManager().OpenIdentity(3)
				else
					JiangHuData.InitInfo()
					UIMgr.Open(VIEW_ID.PanelJiangHuBaiTai, 3)
					TipsHelper.ShowNormalTip("冷却中，当前无法开启江湖百态身份")
				end
			end)
		else
			TipsHelper.ShowNormalTip("需要释放江湖百态身份技能")
		end
		return true
	end
	return false
end

function QuestData.CheckIdentityQuestShowConfirm(nQuestID, bNotCheckDistance)
	if bNotCheckDistance or self.GetQuestDistance(nQuestID) <= HIDE_TRACE_DISTANCE then
		local bOpenIdentidy = g_pClientPlayer and g_pClientPlayer.GetPlayerIdentityManager().dwCurrentIdentityType	== 3
		local bInState = Player_GetBuff(10827) ~= nil
		local szText = bInState and "当前任务需要退出出魂入定之态，是否退出？" or "当前任务需要进入出魂入定之态，是否开启方士身份，并进入出魂入定之态？"

		UIHelper.ShowConfirm(szText, function()
			if not bOpenIdentidy then
				if JiangHuData.nLeftTime == nil then--不在冷却中
					g_pClientPlayer.GetPlayerIdentityManager().OpenIdentity(3)
				else
					JiangHuData.InitInfo()
					UIMgr.Open(VIEW_ID.PanelJiangHuBaiTai, 3)
					TipsHelper.ShowNormalTip("冷却中，当前无法开启江湖百态身份")
				end
			end
			IdentitySkillData.CastFirstSkill()
		end)
		return true
	end
	return false
end

function QuestData.CheckIdentityQuestByType(szFinishState, dwQuestID, szType, nIndex, nAreaID)
	if not g_pClientPlayer then return end
	local hPlayer = g_pClientPlayer
	local dwMapID = hPlayer.GetMapID()
	local tFirstPoint, tRegions, szPointType = TableQuest_GetFirstPoint(dwQuestID, szType, nIndex, dwMapID, nAreaID)

	local hQuestInfo = GetQuestInfo(dwQuestID)
	local bIdentity = false
	if tFirstPoint and ActivityData.MatchActivity(tFirstPoint[8]) then --任务目标是否在本场景中，并且本场景不是副本,优先级最高
		if szType == "finish" then
			local npc = GetNpcTemplate(hQuestInfo.dwEndNpcTemplateID)
			if not hPlayer.IsQuestIdentityVisiable(hPlayer.dwIdentityVisiableID, npc.dwIdentityVisiableID) then
				bIdentity = true
			end
		elseif szType == "quest_state" then
			local dwIdentityVisiableID = tFirstPoint[7]
	    	if dwIdentityVisiableID then
		    	if not hPlayer.IsQuestIdentityVisiable(hPlayer.dwIdentityVisiableID, dwIdentityVisiableID) then
					bIdentity = true
				end
			end
		elseif szType == "kill_npc" then
			local dwKillNpcID = hQuestInfo["dwKillNpcTemplateID"..(nIndex + 1)]
			local npc = GetNpcTemplate(dwKillNpcID)
			if not hPlayer.IsQuestIdentityVisiable(hPlayer.dwIdentityVisiableID, npc.dwIdentityVisiableID) then
				bIdentity = true
			end
		elseif szType == "need_item" then
	    	local dwIdentityVisiableID = tFirstPoint[7]
	    	if dwIdentityVisiableID then
		    	if not hPlayer.IsQuestIdentityVisiable(hPlayer.dwIdentityVisiableID, dwIdentityVisiableID) then
					bIdentity = true
				end
			end
		end
	end
	return bIdentity
end

function QuestData.IsIdentityQuest(nQuestID)
	local player = g_pClientPlayer
	if not player or nQuestID == 0 then
		return
	end

	local nAreaID = self.nAreaID
	local tbQuestTrace = player.GetQuestTraceInfo(nQuestID)


	local bIdentity = false

	if tbQuestTrace.fail then
		return self.CheckIdentityQuestByType("Failed", nQuestID, "accept", 0, nAreaID)
	elseif self.IsDone(nQuestID) or (tbQuestTrace and tbQuestTrace.finish) then
		return self.CheckIdentityQuestByType("Finish", nQuestID, "finish", 0, nAreaID)
		--m_questvalue = updatequest_name(tQuestTrace, tQuestStringInfo)
	else
		for k, v in pairs(tbQuestTrace.quest_state) do
			if v.have < v.need then
				bIdentity = self.CheckIdentityQuestByType("UnFinish", nQuestID, "quest_state", v.i, nAreaID)
			end
		end

		for k, v in pairs(tbQuestTrace.kill_npc) do
			if v.have < v.need then
				bIdentity = self.CheckIdentityQuestByType("UnFinish", nQuestID, "kill_npc", v.i, nAreaID)
			end
		end

		for k, v in pairs(tbQuestTrace.need_item) do
			if v.have < v.need then
				bIdentity = self.CheckIdentityQuestByType("UnFinish", nQuestID, "need_item", v.i, nAreaID)
			end
		end
	end

	return bIdentity
end

function QuestData.GetSpecialQuestHandler(nQuestID)
	return tbQuestTrackerSpecialHadler[nQuestID]
end