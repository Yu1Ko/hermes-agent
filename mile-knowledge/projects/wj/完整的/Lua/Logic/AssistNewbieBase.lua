AssistNewbieBase = AssistNewbieBase or {className = "AssistNewbieBase"}

AssistNewbieBase.RELEASE_CD_ID	= 1273
AssistNewbieBase.RELEASE_BUFF_ID	= 12437
AssistNewbieBase.RELEASE_MAX_COUNT = 5
AssistNewbieBase.MapID2QuestID = {}

function AssistNewbieBase.Init()

end

function AssistNewbieBase.UnInit()

end

function AssistNewbieBase.CanSubscribe()
	local hPlayer 	= GetClientPlayer()

	return hPlayer.nLevel == GetMaxPlayerLevel()
end

function AssistNewbieBase.CanShowAssistButton(dwMapID)
	local tMapLevel = tHelpMapData.tMap[dwMapID]
	local player 	= GetClientPlayer()

	return tMapLevel and player.nLevel >= tMapLevel[1] and player.nLevel <= tMapLevel[2]
end

function AssistNewbieBase.DoModifySubscribe(nType)
	AssistNewbieBase.SetSubscribeType(nType)
	RemoteCallToServer("On_Help_UpdateType", nType)
end

function AssistNewbieBase.SetSubscribeType(nType)
	AssistNewbieBase.nSubscribeType = nType
	GameSettingData.StoreNewValue(UISettingKey.NewbieAssist, ASSIST_NEWBIE_SUBSCRIBE_TYPE[nType])
end

function AssistNewbieBase.SetSubscribeTypeEx() --客户端获取到的居然和服务端不一样！坑爹！这个不能用
	local player = GetClientPlayer()
	if not player then
		return
	end
	AssistNewbieBase.nSubscribeType = player.dwAssistNewbieFavorLevel
end

function AssistNewbieBase.GetSubscribeType()
	return AssistNewbieBase.nSubscribeType
end

function AssistNewbieBase.CanReleaseQuest(dwQuestID)
	local tQuestInfo = GetQuestInfo(dwQuestID)
	if not tQuestInfo or not tQuestInfo.bAssistNewbie then return false end

	local hPlayer 	= GetClientPlayer()
	local bFinish	= false
	if not hPlayer then
		return false
	end	
	bFinish = hPlayer.IsAchievementAcquired(tClientData.GetNewbierAchID())


	return hPlayer.nLevel < GetMaxPlayerLevel() or not bFinish
end

function AssistNewbieBase.CanReleaseDungeon(dwMapID)
	local player = GetClientPlayer()
	local tMapLevel	= tHelpMapData.tMap[dwMapID]
	if tMapLevel and player.nLevel >= tMapLevel[1] and player.nLevel <= tMapLevel[2] then
		return true
	end
	return false
end

function AssistNewbieBase.GetReleaseCount()
	local buff = Player_GetBuff(AssistNewbieBase.RELEASE_BUFF_ID)
	local nCount = 0
	if buff then
		return buff.nStackNum
	end
	return 0
end

function AssistNewbieBase.CheckReleaseCondition()
	local player = GetClientPlayer()
	local nCDLeft = player.GetCDLeft(AssistNewbieBase.RELEASE_CD_ID)
	if nCDLeft > 0 then
		return false, g_tStrings.ASSIST_ERROR_MSG.IN_CD
	end
	
	local relation = GetRelationshipAssistNewbie()
	if relation.dwNewbieID > 0 then
		return false, g_tStrings.ASSIST_ERROR_MSG.BE_ASSISTED
	end
	
	if player.IsInParty() and player.IsPartyFull() then
		return false, g_tStrings.ASSIST_ERROR_MSG.PARTY_IS_FULL
	end
	if AssistNewbieBase.GetReleaseCount() >= AssistNewbieBase.RELEASE_MAX_COUNT then
		return false, g_tStrings.Dungeon.STR_ASSIST_RELEASE_LIMIT
	end

	return true
end


function AssistNewbieBase.Release(dwID, dwType)
	local player = GetClientPlayer()
	local nCDLeft = player.GetCDLeft(AssistNewbieBase.RELEASE_CD_ID)
	if nCDLeft > 0 then
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.ASSIST_ERROR_MSG.IN_CD)
		return
	end
	
	local relation = GetRelationshipAssistNewbie()
	if relation.dwNewbieID > 0 then
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.ASSIST_ERROR_MSG.BE_ASSISTED)
		return
	end
	
	if player.IsInParty() and player.IsPartyFull() then
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.ASSIST_ERROR_MSG.PARTY_IS_FULL)
		return
	end
	
	RemoteCallToServer("On_Help_AskForHelp", {nType = dwType, nID = dwID})
end

function AssistNewbieBase.GetDeathAssistInfo()
	local player 	= GetClientPlayer()
	if player.IsInParty() then return end
	
	local relation = GetRelationshipAssistNewbie()
	if relation.dwHelperID > 0 then return end
	
	if AssistNewbieBase.GetReleaseCount() >= AssistNewbieBase.RELEASE_MAX_COUNT then return end
	
	local scene = player.GetScene()
	if scene.nType == MAP_TYPE.DUNGEON then
		if AssistNewbieBase.CanReleaseDungeon(scene.dwMapID) then
			return scene.dwMapID, ASSIST_NEWBIE_TYPE.DUNGEON
		end
	end
end

function AssistNewbieBase.GetNewbieQuest(dwMapID)
	return AssistNewbieBase.MapID2QuestID[dwMapID]
end

function AssistNewbieBase.ShowQuestAssistComfirm(dwQuestID)
	local tQuestInfo = GetQuestInfo(dwQuestID)
	if not tQuestInfo then
		return
	end
	
	UIHelper.ShowConfirm("此番一人前往万分凶险，建议少侠发布新手援助，将会有侠士前来与你一同前往。", function ()
		--2是浩气，4是恶人，6是浩气+恶人，神仙数的具体含义问系统策划
		if tQuestInfo.nRequireCampMask == 2 or tQuestInfo.nRequireCampMask == 4 or tQuestInfo.nRequireCampMask == 6 then
			AssistNewbieBase.Release(dwQuestID, ASSIST_NEWBIE_TYPE.CAMP)
		else
			AssistNewbieBase.Release(dwQuestID, ASSIST_NEWBIE_TYPE.QUEST)
		end
	end)
end

-----------------对应dx的AssistNewbieInvite内容--------------------------


Event.Reg(AssistNewbieBase, EventType.OnClientPlayerEnter, function()
    AssistNewbieBase.MapID2QuestID = {}
    local tQuestList = g_pClientPlayer.GetQuestList()
	for _, dwQuestID in pairs(tQuestList) do
		local tQuestInfo = GetQuestInfo(dwQuestID)
        if tQuestInfo.bAssistNewbie then
            local dwMapID = QuestData.GetQuestMapIDAndPoints(dwQuestID)
			if dwMapID then
				AssistNewbieBase.MapID2QuestID[dwMapID] = dwQuestID
			end            
        end
    end

	AssistNewbieBase.bNeverShowHelpTip = nil
end)

-- Event.Reg(AssistNewbieBase, EventType.OnViewClose, function(nViewID)
--     if nViewID ~= VIEW_ID.PanelLoading then return end
	
-- 	AssistNewbieBase.DoModifySubscribe(ASSIST_NEWBIE_FAVOR_LEVEL_TYPE.NO_MATTER)
-- end)

Event.Reg(AssistNewbieBase, "QUEST_ACCEPTED", function(_, dwQuestID)
    local tQuestInfo = GetQuestInfo(dwQuestID)
    if tQuestInfo.bAssistNewbie then
        local dwMapID = QuestData.GetQuestMapIDAndPoints(dwQuestID)
		if dwMapID then
			AssistNewbieBase.MapID2QuestID[dwMapID] = dwQuestID
		end
    end
end)