-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: AdventureData
-- Date: 2023-05-08 17:13:14
-- Desc: ?
-- ---------------------------------------------------------------------------------

AdventureData = AdventureData or {className = "AdventureData"}
local self = AdventureData
-------------------------------- 消息定义 --------------------------------
AdventureData.Event = {}
AdventureData.Event.XXX = "AdventureData.Msg.XXX"

function AdventureData.Init()
	Event.Reg(self, EventType.OnRoleLogin, function ()
		self.bForbidAdventureBar = false
	end)

	-- todo：账号第一次登陆设置一个一次性标记，用来判断登陆后奇遇是否显示BubbleBar
	-- todo2：登陆后会在AdventureData.OnGetCurrentTaskID被设为true
	Event.Reg(self, "LOADING_END", function ()
		if DungeonData.IsInDungeon() then
			-- 第一次登陆后在副本中，不显示
			self.bForbidAdventureBar = true
		elseif IsRemotePlayer(UI_GetClientPlayerID()) and not PVPFieldData.IsInPVPField() then
			self.bForbidAdventureBar = true
		end
		RemoteCallToServer("On_QiYu_GetCurrentTaskID")
	end)

    Event.Reg(self, "QUEST_DATA_UPDATE", function ()
        local dwQuestID 		= GetClientPlayer().GetQuestID(arg0)
		local tQuestStringInfo 	= Table_GetQuestStringInfo(dwQuestID)
        if tQuestStringInfo and tQuestStringInfo.IsAdventure == 1 then
			self.OpenTrace(dwQuestID)
		end
    end)

    Event.Reg(self, "ON_ADVENTURE_DATA_CHANGED", function ()
        if arg2 == 1 then
            return
        end
        if arg1 then
            self.OpenTrace(arg0, true)
        end
        self.IsCloseTrace(arg0)
    end)

    Event.Reg(self, "QUEST_ACCEPTED", function ()
        if arg1 then
			local tQuestStringInfo = Table_GetQuestStringInfo(arg1)
			if tQuestStringInfo and tQuestStringInfo.IsAdventure == 1 then
				self.OpenTrace(arg1, true)
			end
		end
    end)

    Event.Reg(self, "QUEST_FINISHED", function ()
        if arg0 then
			self.IsCloseTrace(arg0)
		end
    end)

    Event.Reg(self, "SET_QUEST_STATE", function ()
        if arg0 and arg1 == 1 then
            self.IsCloseTrace(arg0)
        end
    end)

	Event.Reg(self, "UI_LUA_RESET", function ()
		FilterDef.AdventureTryBook.Reset()
	end)

	Event.Reg(self, "PLAYER_LEAVE_GAME", function ()
		self.CloseTrace()
	end)
end

function AdventureData.UnInit()
end

function AdventureData.OnLogin()
end

function AdventureData.OnFirstLoadEnd()
end

function AdventureData.OpenTrace(nCurrID, bNew)
    self.nCurrentID = nCurrID or 0
	if self.nCurrentID == 0 then
		self:CloseTrace()
		return
	end

    self.tAdvTask 	= Table_GetAdventureTask()
	self.tAdv 		= Table_GetAdventure()
	self.dwAdvID 	= Table_GetTaskToAdvID(self.nCurrentID)
	self.bNew = bNew or false
    self.UpdateTaskMsg()
end

function AdventureData.UpdateTaskMsg()
    local hPlayer = GetClientPlayer()
    self.tTraceData  = {}
	self.tTraceData.szTitle = ""
	self.tTraceData.szText = ""
	for k, v in pairs(self.tAdv) do
		if v.dwID == self.dwAdvID then
			self.tTraceData.szTitle = "奇遇·" .. UIHelper.GBKToUTF8(v.szName)
			break
		end
	end

	for k, v in pairs(self.tAdvTask) do
		if v.nQuestID ~= 0 then
			if v.nQuestID == self.nCurrentID then
				local tQuestTrace = hPlayer.GetQuestTraceInfo(v.nQuestID)
				local tQuestStringInfo = Table_GetQuestStringInfo(v.nQuestID)
				self.UpdateQuestCount(tQuestTrace)
				if self.tTraceData.bState then
					self.UpdateQuestState(tQuestTrace.quest_state[self.tTraceData.i], tQuestStringInfo, v.nQuestID)
				elseif self.tTraceData.bNpc then
					self.UpdateQuestNpc(tQuestTrace.kill_npc[self.tTraceData.i], tQuestStringInfo)
				elseif self.tTraceData.bItem then
					self.UpdateQuestItem(tQuestTrace.need_item[self.tTraceData.i], tQuestStringInfo)
				elseif self.tTraceData.bFinishedObjective then
					self.UpdateQuestFinishedObjective(tQuestStringInfo.nID, tQuestStringInfo.szQuestFinishedObjective)
				end
				-- if hFrame.bNew then
				-- 	hFrame.bNew = false
				-- 	PlaySfx(hFrame)
				-- 	PlaySound(SOUND.UI_SOUND, g_sound.AdventureTrace)
				-- end
				-- break
				if self.bNew then
					self.bNew = false
					SoundMgr.PlaySound(SOUND.UI_SOUND, "jiemian_refresh")
				end
				break
			end
		elseif v.dwAcceptID == self.nCurrentID or v.dwFinishID == self.nCurrentID then
			if v.szGoalMsg ~= "" then
				self.tTraceData.szText = UIHelper.GBKToUTF8(SimpleDecode(v.szGoalMsg))

				-- szMsg = StrDecode(v.szGoalMsg)
				-- hTextTrace:SetText(szMsg)

				-- PlaySfx(hFrame)
				-- PlaySound(SOUND.UI_SOUND, g_sound.AdventureTrace)
				SoundMgr.PlaySound(SOUND.UI_SOUND, "jiemian_refresh")
			end
			break
		end
	end

	if self.nShowAdventureTipsTimerID then
		Timer.DelTimer(AdventureData, self.nShowAdventureTipsTimerID)
		self.nShowAdventureTipsTimerID = nil
	end

	self.nShowAdventureTipsTimerID = Timer.Add(AdventureData, 3, function ()
		BubbleMsgData.PushMsgWithType("AdventureTips",{
			szTitle = self.tTraceData.szTitle, 	-- 显示在信息列表项中的标题, 支持回调函数(返回相应文本)
			szBarTitle = self.tTraceData.szTitle, 			-- 显示在小地图旁边的气泡栏的短标题(若与szTitle一样, 可以不填)
			nBarTime = 0, 			-- 显示在气泡栏的时长, 单位为秒
			szContent = self.tTraceData.szText, 		-- 显示在信息列表项中的内容
			bShowAdventureBar = true,
			szAction = function ()
				UIMgr.Open(VIEW_ID.PanelQiYu, self.nCurrentID)
			end,
		})
	end)
end

function AdventureData.UpdateQuestCount(tQuestTrace)
	self.tTraceData.bNpc = false
	self.tTraceData.bItem = false
	self.tTraceData.bState = false
	self.tTraceData.bFinishedObjective = false

	if tQuestTrace.finish then
		self.tTraceData.bFinishedObjective = true
		self.tTraceData.bTimerQuest = tQuestTrace.time
	else
		for k, v in pairs(tQuestTrace.quest_state) do
	        self.tTraceData.bState = true
	        self.tTraceData.bTimerQuest = tQuestTrace.time
	        self.tTraceData.i = k
	    end

		for k, v in pairs(tQuestTrace.kill_npc) do
	        self.tTraceData.bNpc = true
	        self.tTraceData.bTimerQuest = tQuestTrace.time
	        self.tTraceData.i = k
		end

		for k, v in pairs(tQuestTrace.need_item) do
	        self.tTraceData.bItem = true
	        self.tTraceData.bTimerQuest = tQuestTrace.time
            self.tTraceData.i = k
	    end
	end
end

function AdventureData.UpdateQuestState(state, tQuestStringInfo, dwQuestID)
    local szName = UIHelper.GBKToUTF8(tQuestStringInfo["szQuestValueStr" .. (state.i + 1)])
	local szMsg = UIHelper.GBKToUTF8(tQuestStringInfo.szObjective)
	self.tTraceData.szTipName = szName
	state.have = math.min(state.have, state.need)

	local szState = state.have.."/"..state.need
	local szText, nFont = szMsg .. g_tStrings.STR_CHINESE_MAOHAO .. szState, 44
	if state.have >= state.need then
		--教学 完成任务的某个变量
		--FireHelpEvent("OnCommentToQuestVariable", dwQuestID, state.i)
		szText, nFont = szText..g_tStrings.STR_QUEST_QUEST_WAS_FINISHED, 44
	end

    self.tTraceData.szText = szText
end

function AdventureData.UpdateQuestNpc(state, tQuestStringInfo)
	local szMsg = UIHelper.GBKToUTF8(tQuestStringInfo.szObjective)
	state.have = math.min(state.have, state.need)
	local szName = UIHelper.GBKToUTF8(Table_GetNpcTemplateName(state.template_id))
	if not szName or szName == "" then
		szName = "Unknown Npc"
	end
	self.tTraceData.szTipName = szName

	local szState = state.have.."/"..state.need
	local szText, nFont = szMsg .. g_tStrings.STR_CHINESE_MAOHAO .. szState, 44
	if state.have >= state.need then
		szText, nFont = szText..g_tStrings.STR_QUEST_QUEST_WAS_FINISHED, 44
	end

    self.tTraceData.szText = szText
	-- SetTextEx(hTextTrace, szText)
	-- hTextTrace:SetFontScheme(nFont)
end

function AdventureData.UpdateQuestItem(state, tQuestStringInfo)
	local szMsg = UIHelper.GBKToUTF8(tQuestStringInfo.szObjective)
	local itemInfo = GetItemInfo(state.type, state.index)
	local nBookID = state.need
	if itemInfo.nGenre == ITEM_GENRE.BOOK then
		state.need = 1
	end
	state.have = math.min(state.have, state.need)
	local szName = "Unknown Item"
	if itemInfo then
		szName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(itemInfo, nBookID))
	end
	self.tTraceData.szTipName = szName

    local nFont = 44
    local szText = szMsg
    if self.tTraceData.i == 0 then
	    local szState = state.have.."/"..state.need
        szText = szMsg .. g_tStrings.STR_CHINESE_MAOHAO .. szState
    end

    self.tTraceData.szText = szText
	-- SetTextEx(hTextTrace, szText)
	-- hTextTrace:SetFontScheme(nFont)
end

function AdventureData.UpdateQuestFinishedObjective(dwQuestID, szFinishedObjective)
	local szText = ""
    if szFinishedObjective ~= "" then
        szText =  UIHelper.GBKToUTF8(szFinishedObjective)
    else
        local hQuestInfo = GetQuestInfo(dwQuestID)
        local szName = UIHelper.GBKToUTF8(Table_GetNpcTemplateName(hQuestInfo.dwEndNpcTemplateID))
		if szName == "" then
			if hQuestInfo.dwEndDoodadTemplateID ~= 0 then
				szName = UIHelper.GBKToUTF8(Table_GetDoodadTemplateName(hQuestInfo.dwEndDoodadTemplateID))
			end
		end
		if szName ~= "" then
            szText = FormatString(g_tStrings.QUEST_QIYU_SUCCESS_BOJECT_FOR_NPC, szName)
        else
            szText = g_tStrings.QUEST_SUCCESS_BOJECTIVE_FOR_NOT_NPC
        end
    end

    self.tTraceData.szText = szText
	-- SetTextEx(hTextTrace, szText)
	-- hTextTrace:SetFontScheme(44)
end

function AdventureData.IsCloseTrace(nCurrentAccID)
    if not self.tAdv then
        return
    end
    local player = GetClientPlayer()
	for k, v in pairs(self.tAdv) do
		if nCurrentAccID and v.dwFinishID ~= 0 and nCurrentAccID == v.dwFinishID then
			local bFlag = player.GetAdventureFlag(v.dwFinishID)
			if bFlag then
				-- LuckyMeetingGet.Open(v.dwID)
				self.CloseTrace()
			end
		elseif nCurrentAccID and v.nFinishQuestID ~= 0 and nCurrentAccID == v.nFinishQuestID then
			local nAccQuest = player.GetQuestPhase(v.nFinishQuestID)
			if nAccQuest == 3 then
				-- LuckyMeetingGet.Open(v.dwID)
				self.CloseTrace()
			end
		end
	end
end

function AdventureData.CloseTrace()
    self.nCurrentID = nil
    self.tAdvTask 	= {}
	self.tAdv 		= {}
	self.dwAdvID 	= nil
    self.tTraceData = {}

	if self.nShowAdventureTipsTimerID then
		Timer.DelTimer(AdventureData, self.nShowAdventureTipsTimerID)
		self.nShowAdventureTipsTimerID = nil
	end
	BubbleMsgData.RemoveMsg("AdventureTips")
end

function AdventureData.OnGetCurrentTaskID(nCurrID)
    local tAdv = Table_GetAdventure()
	local player = GetClientPlayer()
	for _, v in pairs(tAdv) do
		if nCurrID and v.dwFinishID ~= 0 and nCurrID == v.dwFinishID then
			local bFlag = player.GetAdventureFlag(v.dwFinishID)
			if bFlag then
				self.CloseTrace()
				return
			end
		elseif nCurrID and v.nFinishQuestID ~= 0 and nCurrID == v.nFinishQuestID then
			local nAccQuest = player.GetQuestPhase(v.nFinishQuestID)
			if nAccQuest == QUEST_PHASE.FINISH then
				self.CloseTrace()
				return
			end
		end
	end
	self.OpenTrace(nCurrID)
	-- self.bForbidAdventureBar = true
end

function AdventureData.GetOpenRewardPath(tAdv)
	local nSchool = g_pClientPlayer.dwForceID
    local nCamp = g_pClientPlayer.nCamp
	local szType = tAdv.szRewardType
    local szPath = tAdv.szOpenRewardPath
    if szType ~= "" then
        local bHasSlash = string.sub(szPath, -1) == "/" or string.sub(szPath, -1) == "\\"
        if not bHasSlash then
            szPath = szPath .. "/"
        end
    end
    if szType == "school" then
        szPath = szPath .. szType .. "_" .. nSchool .. "_Open" .. ".tga"
    elseif szType == "camp" then
        szPath = szPath .. szType .. "_" .. nCamp .. "_Open" .. ".tga"
    end
    szPath = string.gsub(szPath, "ui\\Image", "Resource/Adventure")
    szPath = string.gsub(szPath, "ui/Image", "Resource/Adventure")
    szPath = string.gsub(szPath, ".tga", ".png")
	return szPath
end

function AdventureData.GetRewardPath(tAdv)
	local v = tAdv
	if v.szRewardType == "" then
		local szBgPath = v.szRewardPath
		szBgPath = string.gsub(szBgPath, "ui\\Image", "Resource/Adventure")
		szBgPath = string.gsub(szBgPath, "ui/Image", "Resource/Adventure")
		szBgPath = string.gsub(szBgPath, ".tga", ".png")
		return szBgPath
	else
		local nSchool = g_pClientPlayer.dwForceID
		local nCamp = g_pClientPlayer.nCamp
		local szBgPath = v.szRewardPath
		local bHasSlash = string.sub(szBgPath, -1) == "/" or string.sub(szBgPath, -1) == "\\"
		if not bHasSlash then
			szBgPath = szBgPath .. "/"
		end
		if v.szRewardType == "school" then
			szBgPath = szBgPath .. v.szRewardType .. "_" .. nSchool .. ".png"
		elseif v.szRewardType == "camp" then
			szBgPath = szBgPath .. v.szRewardType .. "_" .. nCamp .. ".png"
		end
		szBgPath = string.gsub(szBgPath, "ui\\Image", "Resource/Adventure")
		szBgPath = string.gsub(szBgPath, "ui/Image", "Resource/Adventure")
		return szBgPath
	end
end

function AdventureData.TeleportGoPet(tPet)
    if not tPet then
        return
    end
    if not PakDownloadMgr.UserCheckDownloadMapRes(tPet.nMapID, nil, nil, true) then
        return
    end
    if HomelandData.CheckIsHomelandMapTeleportGo(tPet.nLinkID, tPet.nMapID, nil, nil, function ()
            UIMgr.Close(VIEW_ID.PanelQiYu)
            UIMgr.Close(VIEW_ID.PanelPetMap)
        end) then
        return
    end
    MapMgr.CheckTransferCDExecute(function()
        RemoteCallToServer("On_Teleport_Go", tPet.nLinkID, tPet.nMapID)
        UIMgr.Close(VIEW_ID.PanelQiYu)
        UIMgr.Close(VIEW_ID.PanelPetMap)
        UIMgr.Close(VIEW_ID.PanelPartnerTravelSetting)
        UIMgr.Close(VIEW_ID.PanelPartner)
		UIMgr.Close(VIEW_ID.PanelGongZhanSide)
		UIMgr.Close(VIEW_ID.PanelOperationCenter)
    end)
end

function AdventureData.InitLuckyTable(bForceInit)
	if self.tLuckyScore == nil or bForceInit then
		self.tLuckyScore = {}
		local tTime = TimeLib.GetTodayTime()
		local szMonth = tTime.month
		local szDay = string.format("%02d", tTime.day)
		local szDate = szMonth .. szDay
		local tLuckyPet = GetLuckyFellowPet(szDate)
		for _, dwLuckyPetIndex in pairs(tLuckyPet) do
			self.tLuckyScore[dwLuckyPetIndex] = true
		end
	end
end

function AdventureData.IsLuckyPet(dwPetIndex)
	AdventureData.InitLuckyTable()

	if self.tLuckyScore[dwPetIndex] then
		return true
	else
		return false
	end
end

function AdventureData.GoToAcquirePet(tPet)
    local tSource = SplitString(tPet.szSourceList, ";")
    for _, v in pairs(tSource) do
        local nSource = tonumber(v)
        if nSource == 5 then -- WORLD_ADVENTURE
            local nMapID = tPet.nMapID
            if nMapID == 0 then
                TipsHelper.ShowNormalTip(g_tStrings.STR_FIND_PET_FAILED)
            else
                local nMapX = tPet.nMapX
                local nMapY = tPet.nMapY
                local nMapZ = tPet.nMapZ
                local szTip = tPet.szTip
                local nMarkType = 1
                MapMgr.SetTracePoint(szTip and UIHelper.GBKToUTF8(szTip), nMapID, {nMapX, nMapY, nMapZ}, nil, "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_qiyu")
                UIMgr.Open(VIEW_ID.PanelMiddleMap, nMapID, 0)
            end
        elseif nSource == 6 or nSource == 11 then -- POINT_REWARD or OPERATION_ACTIVITY
            local bEnableBuy = _G.CoinShop_PetIsInShop(tPet.dwPetIndex)
            if bEnableBuy then
                local szMsg = FormatString(g_tStrings.STR_GO_TO_PET_SHOP, UIHelper.GBKToUTF8(tPet.szName))
                UIHelper.ShowConfirm(szMsg,function ()
                    local dwLogicID = Table_GetRewardsPetGoodID(tPet.dwPetIndex)
                    local szLink = "Exterior/4/" .. dwLogicID
                    Event.Dispatch("EVENT_LINK_NOTIFY", szLink)
                end)
                break
            else
                TipsHelper.ShowNormalTip(g_tStrings.STR_BUY_PET_UNABLE)
            end
        end
    end
end