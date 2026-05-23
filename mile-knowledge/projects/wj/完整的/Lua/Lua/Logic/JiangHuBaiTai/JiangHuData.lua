-- ---------------------------------------------------------------------------------
-- Author: liu yu min
-- Name: JiangHuData
-- Date: 2023-08-04 15:22:34
-- Desc: 江湖百态
-- ---------------------------------------------------------------------------------

JiangHuData = JiangHuData or {className = "JiangHuData"}
--local JiangHuData = JiangHuData
-------------------------------- 消息定义 --------------------------------
JiangHuData.Event = {}
JiangHuData.Event.XXX = "JiangHuData.Msg.XXX"

JiangHuData.MAX_LEVLE     				= 5
JiangHuData.MAX_SKILLS_COUNT 			= 10
JiangHuData.MAX_ARTIST_SKILL_COUNT 	= 10
JiangHuData.SET_ARTIST_BOX_USERDATA   	= -6
JiangHuData.nPageIndex 				= nil
JiangHuData.nTimeSlot 					= nil
JiangHuData.nStartTime 				= nil
JiangHuData.nLeftTime 					= nil
JiangHuData.nCurActID 					= nil
JiangHuData.nPlayID 					= nil
JiangHuData.nType           			= nil
JiangHuData.nTypeNext       			= nil
JiangHuData.nDisIndex					= nil
JiangHuData.nShowIndex	    			= nil
JiangHuData.nRecordIndex    			= nil
JiangHuData.nRecordCheck    			= nil
JiangHuData.tIdeInfo   				= nil
JiangHuData.tIdeOtherInfo				= nil
JiangHuData.tSkills 					= nil
JiangHuData.tNextSkills 				= nil
JiangHuData.tArtistSkill    			= nil
JiangHuData.tSelSkill					= nil
JiangHuData.bShowTime 					= nil
JiangHuData.bShowArtistSkill 			= nil

JiangHuData.tSaveSkill        = {}

JiangHuData.tbDwID = {
	[1] = 5,
	[2] = 1,
	[3] = 3,
	[4] = 4,
	[5] = 2,
}

JiangHuData.tbShowID = {
	[5] = 1,
	[1] = 2,
	[3] = 3,
	[4] = 4,
	[2] = 5,
}

JiangHuData.tItem = {
	[1] = {nIdentityID = nil, tOneInfo = nil, bActivate = nil, nLevel = nil, tExperience = nil, tOtherOneInfo = nil},
	[2] = {nIdentityID = nil, tOneInfo = nil, bActivate = nil, nLevel = nil, tExperience = nil, tOtherOneInfo = nil},
	[3] = {nIdentityID = nil, tOneInfo = nil, bActivate = nil, nLevel = nil, tExperience = nil, tOtherOneInfo = nil},
	[4] = {nIdentityID = nil, tOneInfo = nil, bActivate = nil, nLevel = nil, tExperience = nil, tOtherOneInfo = nil},
	[5] = {nIdentityID = nil, tOneInfo = nil, bActivate = nil, nLevel = nil, tExperience = nil, tOtherOneInfo = nil}
}
JiangHuData.tSItem = {
	[1] = {nIdentityIDS = nil, tOneInfo = nil, bActivate = nil, nLevel = nil, tExperience = nil, tOtherOneInfo = nil},
	[2] = {nIdentityIDS = nil, tOneInfo = nil, bActivate = nil, nLevel = nil, tExperience = nil, tOtherOneInfo = nil},
	[3] = {nIdentityIDS = nil, tOneInfo = nil, bActivate = nil, nLevel = nil, tExperience = nil, tOtherOneInfo = nil},
	[4] = {nIdentityIDS = nil, tOneInfo = nil, bActivate = nil, nLevel = nil, tExperience = nil, tOtherOneInfo = nil},
	[5] = {nIdentityIDS = nil, tOneInfo = nil, bActivate = nil, nLevel = nil, tExperience = nil, tOtherOneInfo = nil}
}


JiangHuData.NpcTraceData = {}

JiangHuData.tbIdentitySkills = {}

JiangHuData.tbNpcGuideID = {
	966,967,965,964,968,969
}

JiangHuData.tSendFellowRank = nil

JiangHuData.nArtistTimeSlot = 0
JiangHuData.nArtistStartTime = 0
JiangHuData.nArtistLeftTime = 0
JiangHuData.bFirstOpen = true
JiangHuData.bFirstListOpen = true

--JiangHuData.szArtistInteractive = "艺人花篮"

JiangHuData.tbQuickSkills = {}
JiangHuData.bHideSkill = true

JiangHuData.dwBiaoShiID = nil
JiangHuData.szBiaoShiName = nil
JiangHuData.nBiaoShiCount = nil
JiangHuData.nBiaoShiCurValue = nil
JiangHuData.nBiaoShiMaxValue = nil
JiangHuData.tGuradList = nil

JiangHuData.scriptHuBiao = nil
JiangHuData.scriptBiaoShi = nil

JiangHuData.bIsArtist = false

JiangHuData.bPeFirstCall = false

local tLevelToValue 	= {
	[1] = {nMax = 8000, nSlot = 8000},
	[2] = {nMax = 20000, nSlot = 12000},
	[3] = {nMax = 42000, nSlot = 22000},
	[4] = {nMax = 77000, nSlot = 35000},
	[5] = {nMax = nil,   nSlot = nil},
}

local tHunterLevelToValue = {
	[1] = {nMax = 7000, nSlot = 7000},
	[2] = {nMax = 18000, nSlot = 11000},
	[3] = {nMax = 40000, nSlot = 22000},
	[4] = {nMax = 75000, nSlot = 35000},
	[5] = {nMax = nil,   nSlot = nil},
}

JiangHuData.bOpenPet = false

local FANGSHICOMPASSBUFFID = 11444


function JiangHuData.Init()
	JiangHuData.RegEvent()
end

function JiangHuData.InitInfo()
	RemoteCallToServer("On_Identity_SkillChose")
	JiangHuData.nPageIndex = 1
	JiangHuData.bShowArtistSkill = false
	JiangHuData.tSaveSkill = Storage.ArtistSkills.tbSkillList
	if table_is_empty(JiangHuData.tSaveSkill) then
        JiangHuData.tSaveSkill = {}
    end
	JiangHuData.tSelSkill = JiangHuData.tSaveSkill

	JiangHuData.UpdateIdentityClass()
	JiangHuData.UpdateIdentitySystemCD()
	--JiangHuData.UpdateInitInfo()
	JiangHuData.InitTraceNpcInfo()
	JiangHuData.UpdateCurIdentityIcon()

end

function JiangHuData.UnInit()
	JiangHuData:UnRegEvent()
end

function JiangHuData.OnLogin()

end

function JiangHuData.OnFirstLoadEnd()

end

function JiangHuData.RegEvent()
   -- Event.Reg(JiangHuData, "UPDATE_IDENTITY_ARTIST_SKILL", function(tArtistSkill)
	--	JiangHuData.tArtistSkill = tArtistSkill
   -- end)
   	Event.Reg(JiangHuData, EventType.OnAccountLogin, function ()
		JiangHuData.tbIdentitySkills = {}
	end)

	Event.Reg(JiangHuData, EventType.OnRoleLogin, function ()
		JiangHuData.bFirstListOpen = true
		JiangHuData.bFirstOpen = true
		JiangHuData.scriptHuBiao = nil
		JiangHuData.scriptBiaoShi = nil
	end)

	Event.Reg(JiangHuData, "QUEST_ACCEPTED", function(nQuestIndex, nQuestID)
		if nQuestID == 15459 then
			UIHelper.ShowConfirm("是否前往开启江湖百态身份？", function()
				JiangHuData.InitInfo()
				UIMgr.Open(VIEW_ID.PanelJiangHuBaiTai, 3)
			end)
		end
	end)

	Event.Reg(JiangHuData, "BUFF_UPDATE", function()
        local owner, bdelete, index, cancancel, id, stacknum, endframe, binit, level, srcid, isvalid, leftframe = arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11
		if id == FANGSHICOMPASSBUFFID and level == 1 and IsInLishijie() and not bdelete then	--再里世界发现藏宝点
			Event.Dispatch(EventType.OnTogCompass, true)
			RemoteCallToServer("OnHoroSysUpdateLocRequest")
        end
		if id == 10827 and level == 1 and bdelete then	--归魂
			local bHaveFangshiPoint = JiangHuData.IsHavaFangshiPoint()
			if bHaveFangshiPoint then
				Event.Dispatch(EventType.OnTogCompass, true)
			end
		end
    end)
end

function JiangHuData.UnRegEvent()
	Event.UnReg(JiangHuData, EventType.OnAccountLogin)
	Event.UnReg(JiangHuData, EventType.OnRoleLogin)
end

function JiangHuData.UpdateIdentityClass()
	local player = GetClientPlayer()
	if not player then return end
	JiangHuData.tIdeInfo = Table_GetIdentityInfo()
	JiangHuData.tIdeOtherInfo = Table_GetIdentityOtherInfo()
	for i = 1, 5, 1 do
		local dwID = JiangHuData.tbDwID[i]
		local tInfo = Table_GetOneIdentityInfo(dwID)
		local bActivate = player.GetPlayerIdentityManager().IsIdentityGained(tInfo.dwID)
		local nExp 		= player.GetPlayerIdentityManager().GetIdentityExp(tInfo.dwID) or 0
		JiangHuData.tItem[i].nIdentityID 		= tInfo.dwID
		JiangHuData.tItem[i].tOneInfo          = tInfo
		JiangHuData.tItem[i].bActivate         = bActivate
		JiangHuData.tItem[i].nLevel			= JiangHuData.GetIdentityLevel(tInfo.dwID, nExp)
		JiangHuData.tItem[i].tExperience	  	= JiangHuData.GetExperienceValue(tInfo.dwID, JiangHuData.tItem[i].nLevel, nExp)
		JiangHuData.tItem[i].tOtherOneInfo		= JiangHuData.GetOneIdentityOtherInfo(tInfo.dwID, JiangHuData.tItem[i].nLevel)

		JiangHuData.tSItem[i].nIdentityIDS = tInfo.dwID
		JiangHuData.tSItem[i].tOneInfo = JiangHuData.tItem[i].tOneInfo
		JiangHuData.tSItem[i].bActivate = bActivate
		JiangHuData.tSItem[i].nLevel = JiangHuData.tItem[i].nLevel
		JiangHuData.tSItem[i].tExperience = JiangHuData.tItem[i].tExperience
		JiangHuData.tSItem[i].tOtherOneInfo = JiangHuData.tItem[i].tOtherOneInfo

		Timer.AddFrame(JiangHuData, 1, function ()
			FireHelpEvent("OnCommontToIdentity", JiangHuData.tItem[i], tInfo.dwID)
		end)
	end


end

function JiangHuData.GetIdentityLevel(nIdentity,nExp)
	if nIdentity == PLAYER_IDENTITY_TYPE.HUNTER then
		if nExp >= 75000 then
			return 5
		elseif nExp >= 40000 then
			return 4
		elseif nExp >= 18000 then
			return 3
		elseif nExp >= 7000 then
			return 2
		elseif nExp >= 0 then
			return 1
		end
		return 0
	end

	local nLevel = 0

	if nExp >= 77000 then
		nLevel = 5
	elseif nExp >= 42000 then
		nLevel = 4
	elseif nExp >= 20000 then
		nLevel = 3
	elseif nExp >= 8000 then
		nLevel = 2
	elseif nExp >= 0 then
		nLevel = 1
	end

	return nLevel
end

function JiangHuData.GetExperienceValue(nIdentity, nLevel, nExp)
	local tValue = {}
	local nCurValue, nSlotValue = 0, 0

	if nIdentity == PLAYER_IDENTITY_TYPE.HUNTER then
		if tHunterLevelToValue[nLevel] then
			nSlotValue = tHunterLevelToValue[nLevel].nSlot
		end

		if nLevel > 1 and nLevel < JiangHuData.MAX_LEVLE  then
			nCurValue = nExp - tHunterLevelToValue[nLevel - 1].nMax
		elseif nLevel == 1 then
			nCurValue = nExp
		end

		tValue = {nCurValue = nCurValue, nSlotValue = nSlotValue}

		return tValue
	end

	if tLevelToValue[nLevel] then
		nSlotValue = tLevelToValue[nLevel].nSlot
	end

	if nLevel > 1 and nLevel < JiangHuData.MAX_LEVLE  then
		nCurValue = nExp - tLevelToValue[nLevel - 1].nMax
	elseif nLevel == 1 then
		nCurValue = nExp
	end

	tValue = {nCurValue = nCurValue, nSlotValue = nSlotValue}

	return tValue
end

function JiangHuData.GetOneIdentityOtherInfo(nIdentity, nLevel)
	local tList = Table_GetIdentityOtherInfo()

	for k, v in pairs(tList) do
		if v.nIdentity == nIdentity and v.nLevel == nLevel then
			return v
		end
	end

	return nil
end

function JiangHuData.UpdateIdentitySystemCD()
	local player = GetClientPlayer()
	if not player then
		return
	end

	JiangHuData.nCurActID = player.GetPlayerIdentityManager().dwCurrentIdentityType
	JiangHuData.nStartTime = player.GetPlayerIdentityManager().nLatestOpenTime
	JiangHuData.nTimeSlot = GetPlayerIdentitySystemCD()

	if JiangHuData.nStartTime and JiangHuData.nStartTime ~= 0 then
		local nPoor = math.max(0, GetCurrentTime() - JiangHuData.nStartTime)
		if nPoor < JiangHuData.nTimeSlot then
			JiangHuData.nLeftTime = math.floor(JiangHuData.nTimeSlot - nPoor)
		else
			JiangHuData.nLeftTime = nil
		end
	else
		JiangHuData.nLeftTime = nil
	end
	if JiangHuData.nLeftTime then --冷却中
		return true
	else
		return false
	end
end

function JiangHuData.UpdateInitInfo()
	for i = 1, 5, 1 do
		if JiangHuData.nCurActID and JiangHuData.tSItem[i].nIdentityIDS == JiangHuData.nCurActID then
			JiangHuData.nRecordIndex = JiangHuData.tSItem[i].nIdentityIDS
			JiangHuData.nDisIndex = JiangHuData.tSItem[i].nIdentityIDS
			JiangHuData.tSItem[i].bSelect = true
			JiangHuData.UpdateAllSmallItemState()
		end
	end
end

function JiangHuData.UpdateAllSmallItemState()
	for i = 1, 5, 1 do
		local tSuffix = SplitString(JiangHuData.tSItem[i]:GetName(),"_")
		if tSuffix then
			JiangHuData.tSItem[i].bSelect = false
		end
	end
end

function JiangHuData.UpdateCurIdentityIcon()
	for i = 1, 5, 1 do
		if JiangHuData.nCurActID and JiangHuData.tItem[i].nIdentityID == JiangHuData.nCurActID then--选中显示icon
			return i
		else--未选中隐藏icon
			return 0
		end
	end
end

function JiangHuData.UpdateCurIdentitySkill(dwID)
	JiangHuData.tbQuickSkills = {}
	--将技能加入快捷菜单
	local tInfo = g_tTable.IdentityDynSkill:Search(dwID) or {}
	local tSkills = JiangHuData.GetIdentityDynSkill(tInfo) or {}
	local nCount = #tSkills
	local szSkill, tSkill
	for i = 1, nCount, 1 do
		szSkill = tSkills[i]
		tSkill = string.split(szSkill, "_")
		if tSkill and tSkill[1] and tSkill[2] then
			table.insert(JiangHuData.tbQuickSkills, {id = tSkill[2], level = tSkill[1]})
		end
	end
	local tbSkills = {CanCastSkill = true, canuserchange = false, tbSkilllist = JiangHuData.tbQuickSkills}
	IdentitySkillData.OnSwitchDynamicSkillStateBySkills(tbSkills)
end

function JiangHuData.GetSkills(index) --获取当前技能
	local tSItem = JiangHuData.tSItem[index]
	local nIdentity = tSItem.nIdentityID or tSItem.nIdentityIDS
	local szSkill = ""
	local nType = nil
	local tSkill = nil

	for k, v in pairs(JiangHuData.tIdeOtherInfo) do
		if v.nIdentity == nIdentity and v.nLevel <= tSItem.nLevel then
			if v.szSkill ~= "" and szSkill ~= "" then
				szSkill = szSkill .. ";"
			end

			if v.szSkill ~= "" then
				szSkill = szSkill .. v.szSkill
			end

			if not nType then
				nType = v.nType
			end
		end
	end

	if szSkill ~= "" then
		tSkill = string.split(szSkill, ";") or {}
	end

	return tSkill, nType or 0

end

function JiangHuData.GetNextSkills(index) --获取下一级技能
	local tSItem = JiangHuData.tSItem[index]
	local nIdentity = tSItem.nIdentityID or tSItem.nIdentityIDS
	local szNextSkill = ""
	local nTypeNext = 0
	local tNextSkill = nil

	local tInfoNext = JiangHuData.GetOneIdentityOtherInfo(nIdentity, tSItem.nLevel + 1)
	if tInfoNext then
		szNextSkill = tInfoNext.szSkill
		nTypeNext 	= tInfoNext.nType
	end

	if szNextSkill ~= "" then
		tNextSkill = string.split(szNextSkill, ";") or {}
	end

	return tNextSkill, nTypeNext

end

--身份等级称号title
function JiangHuData.UpdateLevelTitle(index)
	local tOtherOneInfo = JiangHuData.tSItem[index].tOtherOneInfo
	if tOtherOneInfo then
		return tOtherOneInfo.szTitle
	else
		return false
	end
end

--npc追踪
function JiangHuData.InitTraceNpcInfo()
	local player = GetClientPlayer()
	for i = 1, 5, 1 do
		if i == 5 and player.nCamp == 2 then
			local tAllLinkInfo = Table_GetCareerGuideAllLink(JiangHuData.tbNpcGuideID[i+1])
			local tLink  = tAllLinkInfo[1]
			local tPoint = { tLink.fX, tLink.fY, tLink.fZ }
			table.insert(JiangHuData.NpcTraceData, i, {UIHelper.GBKToUTF8(tLink.szNpcName), tLink.dwMapID, tPoint})
		else
			local tAllLinkInfo = Table_GetCareerGuideAllLink(JiangHuData.tbNpcGuideID[i])
			local tLink  = tAllLinkInfo[1]
			local tPoint = { tLink.fX, tLink.fY, tLink.fZ }
			table.insert(JiangHuData.NpcTraceData, i, {UIHelper.GBKToUTF8(tLink.szNpcName), tLink.dwMapID, tPoint})
		end
	end
end

function JiangHuData.GetIdentityDynSkill(tInfo)
	local szSkill = tInfo.szSkill
    if not szSkill or szSkill == "" then
        return
    end

	return string.split(szSkill, ";")
end

--艺人打赏气泡
function JiangHuData.UpdateBubbleMsgData(nFellowNum)
	BubbleMsgData.PushMsgWithType("ArtistGiftTips",{
		nBarTime = 5, 							-- 显示在气泡栏的时长, 单位为秒
		szContent = string.format("你收到的%d份鲜花，点击可查看详细信息", nFellowNum),
		szAction = function ()
			Event.Dispatch("ON_SHOW_WIDGETGIFTPOP", nFellowNum, JiangHuData.nArtistTimeSlot)
		end,
	})
end

--护镖信息气泡
function JiangHuData.UpdateBiaoShiInfoBubble()
	local szTitleContent = nil
	if not JiangHuData.szBiaoShiName then
		szTitleContent = g_tStrings.STR_JH_GUARD_FAR_TIP
	else
		szTitleContent = JiangHuData.szBiaoShiName
	end
	BubbleMsgData.PushMsgWithType("BiaoShiInfoTips",{
		nBarTime = 5, 							-- 显示在气泡栏的时长, 单位为秒
		szContent = string.format("当前雇主%s",szTitleContent),
		szAction = function ()
			TipsHelper.ShowHuBiaoTip(JiangHuData.dwBiaoShiID, JiangHuData.szBiaoShiName, JiangHuData.nBiaoShiCount, JiangHuData.nBiaoShiCurValue, JiangHuData.nBiaoShiMaxValue)
			-- Event.Dispatch("ON_SHOW_WIDGETHUBIAOPOP", JiangHuData.dwBiaoShiID, JiangHuData.szBiaoShiName, JiangHuData.nBiaoShiCount, JiangHuData.nBiaoShiCurValue, JiangHuData.nBiaoShiMaxValue)
		end,
	})
end

--护镖列表气泡
function JiangHuData.UpdateBiaoShiListBubble()
	BubbleMsgData.PushMsgWithType("BiaoShiListTips",{
		nBarTime = 5, 							-- 显示在气泡栏的时长, 单位为秒
		szContent = string.format("当前镖师%d人",#JiangHuData.tGuradList),
		szAction = function ()
			TipsHelper.ShowBiaoShiTip(JiangHuData.tGuradList)
			--Event.Dispatch("ON_SHOW_WIDGETBIAOSHIPOP", JiangHuData.tGuradList)
		end,
	})
end

function JiangHuData.ShowSendFellowTip(tRank)
	for k, v in pairs(tRank) do
		OutputMessage("MSG_SYS", string.format("[%s]向你赠送了%d束鲜花",UIHelper.GBKToUTF8(v.szName), v.nNum))
	end
end

function JiangHuData.UpdateSortPlayers(tRank)
	local tRecordList 	= JiangHuData.tSendFellowRank or {}
	local tList 		= tRecordList
	local bFlag 		= false
	for k, v in pairs(tRank) do
		bFlag = false
		for i, j in pairs(tRecordList) do
			if v.dwID == j.dwID then
				bFlag = true
				tList[i].nNum = tList[i].nNum + v.nNum
			end
		end
		if not bFlag then
			table.insert(tList, v)
		end
	end

	table.sort(tList, function(a, b) return a.nNum >= b.nNum end)
	JiangHuData.tSendFellowRank = tList
end

function JiangHuData.UpdateArtistCD()
	local player = GetClientPlayer()
	if not player then
		return
	end

	if JiangHuData.nArtistStartTime and JiangHuData.nArtistStartTime ~= 0 then
		local nPoor = math.max(0, GetCurrentTime() - JiangHuData.nArtistStartTime)
		if nPoor < JiangHuData.nArtistTimeSlot then
			JiangHuData.nArtistLeftTime = math.floor(JiangHuData.nArtistTimeSlot - nPoor)
		else
			JiangHuData.nArtistLeftTime = nil
		end
	end
end


function JiangHuData.SafeDefaultFilter()
	JiangHuData.tbDefaultColorGradeParams = KG3DEngine.GetColorGradeParams()
end

function JiangHuData.GetIdentityNextLevel(nIdentityID)
	local player = GetClientPlayer()
    if not player then
        return
    end

    local tExp      = player.GetPlayerIdentityManager().GetIdentityInfo(nIdentityID) or {}
    local nExp      = tExp.nExperience or 0
    local nLevel    = 0

    if nExp >= 85000 then
        nLevel = 5
    elseif nExp >= 50000 then
        nLevel = 4
    elseif nExp >= 26000 then
        nLevel = 3
    elseif nExp >= 10000 then
        nLevel = 2
    elseif nExp >= 0 then
        nLevel = 1
    end

    return nLevel
end

function JiangHuData.GetIdentityOtherInfo(nIdentity, nLevel)
    local tList = Table_GetIdentityOtherInfo()

    for k, v in pairs(tList) do
        if v.nIdentity == nIdentity and v.nLevel == nLevel then
            return v
        end
    end

    return nil
end

function JiangHuData.UpdateIdentityUpGrade(nIdentityID)
	local tInfo = Table_GetOneIdentityInfo(nIdentityID)
	local nLevel = JiangHuData.GetIdentityNextLevel(nIdentityID)
	local tLine = JiangHuData.GetIdentityOtherInfo(nIdentityID, nLevel)

	local szNewDesUp = UIHelper.GBKToUTF8(tLine.szDesUp):gsub("！", "")
	OutputMessage("MSG_ANNOUNCE_NORMAL", szNewDesUp.."为"..UIHelper.GBKToUTF8(tLine.szTitle).."！" )
end


function JiangHuData.OnClickEntrance()
	JiangHuData.InitInfo()
	local nIndex = JiangHuData.nCurActID ~= 0 and JiangHuData.tbShowID[JiangHuData.nCurActID] or 1

	UIMgr.Open(VIEW_ID.PanelJiangHuBaiTai, nIndex)
end


-- 当点赞弹窗打开时，不应弹出镖师页面
JiangHuData.bConflictPageExist = false
function JiangHuData.SetConflictPageType(bExist)
	JiangHuData.bConflictPageExist = bExist
end

function JiangHuData.IsHavaFangshiPoint()
	local player = g_pClientPlayer
    local tbData = player and player.GetMapMark() or {}
    for i = 1, #tbData do
        local tMarkD = tbData[i]
        if tMarkD.nType == 318 then
			return true
        end
    end

	return false
end

function JiangHuData.SetArtistState(bArtist)
	JiangHuData.bIsArtist = bArtist
end

function JiangHuData.GetArtistState()
	return JiangHuData.bIsArtist
end