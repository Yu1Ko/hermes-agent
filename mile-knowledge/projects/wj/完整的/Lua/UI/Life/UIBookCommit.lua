-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBookCommit
-- Date: 2022-12-02 14:55:45
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBookCommit = class("UIBookCommit")

local FilterType = {
    Classify = 1,
    Reward = 2,
    Collect = 3,
}

local FilterRewardType = {
    -- Equipment = 1,
    -- Renown = 2,
    -- Weapon = 3,
    Pandant = 1,
    Item = 2,
    Train = 3,
}

local FilterCollectType = {
    HasRead = 1,
    NoRead = 2,
}

local tBookReward = {
    -- [FilterRewardType.Equipment] = ITEM_TABLE_TYPE.CUST_ARMOR,
    -- [FilterRewardType.Renown] = 0,
    -- [FilterRewardType.Weapon] = ITEM_TABLE_TYPE.CUST_WEAPON,
    [FilterRewardType.Pandant] = ITEM_TABLE_TYPE.CUST_TRINKET,
    [FilterRewardType.Item] = ITEM_TABLE_TYPE.OTHER,
    [FilterRewardType.Train] = 0,
}

function UIBookCommit:OnEnter(szInfo, dwTargetType, dwTargetID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
	self.szInfo       = szInfo
	self.dwTargetType = dwTargetType
	self.dwTargetID   = dwTargetID

    AuctionData.MarkStartTime()
    self:InitBookCommitView()
    self:UpdateInfo()

    Timer.AddFrameCycle(self, 10, function ()
        self:OnFrameBreathe()
    end)
end

function UIBookCommit:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIBookCommit:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function ()
        self:OnCommit()
    end)

    UIHelper.BindUIEvent(self.TogSift, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogSift, TipsLayoutDir.BOTTOM_RIGHT, FilterDef.BookCommit)
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxSearch, function()
        self.szSearchKey = UIHelper.GetText(self.EditBoxSearch)
        self:UpdateInfo()
    end)
end

function UIBookCommit:RegEvent()
    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.BookCommit.Key then
            self.tbSelected = {}
            for nIndex, tbDef in ipairs(tbSelected) do
                self.tbSelected[nIndex] = {}
                for _, nEnableIndex in ipairs(tbDef) do
                    self.tbSelected[nIndex][nEnableIndex] = true
                end
            end

            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "QUEST_FINISHED", function ()
        self:UpdateInfo()
    end)
    Event.Reg(self, "BAG_ITEM_UPDATE", function ()
        self:UpdateInfo()
    end)
    Event.Reg(self, "QUEST_DATA_UPDATE", function ()
        self:UpdateInfo()
    end)
    Event.Reg(self, "SET_QUEST_STATE", function ()
        self:UpdateInfo()
    end)
end

function UIBookCommit:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIBookCommit:InitBookCommitView()
    self.tExpand  = {}
	self.nSelQuestID = -1
	self.nSelHorID1  = -1
	self.nSelHorID2  = -1
	self.bIsSearch = false

    local _, aInfo = GWTextEncoder_Encode(self.szInfo)
	local player = GetClientPlayer()
	self.tQuestID = {}
	for k, v in pairs(aInfo) do
		if v.name == "Q" then --任务
			local questInfo = GetQuestInfo(v.attribute.questid)
			local _, dwRecipeID = self:GetRequireItemInfo(questInfo, 1)
			local nBookID, nSegmentID = GlobelRecipeID2BookID(dwRecipeID)
			local recipe = GetRecipe(8, nBookID, nSegmentID)
				
	        table.insert(self.tQuestID, {v.attribute.questid,  recipe.dwRequireProfessionLevel, dwRecipeID})
	    end
    end
    function Cmp(a, b)
    	if a[2] ~= b[2] then
    		return a[2] < b[2]
    	else
    		return a[3] < b[3]
    	end
    end
    table.sort(self.tQuestID, Cmp)
    
    local npc = GetNpc(self.dwTargetID)
    local szTilte = ""
    if npc then
    	if npc.dwTemplateID == 494 or npc.dwTemplateID == 5926 then
    		szTilte = g_tStrings.STR_CRAFT_READ_BOOK_SORT_NAME_TABLE[3]
    	elseif npc.dwTemplateID == 495 then
    		szTilte = g_tStrings.STR_CRAFT_READ_BOOK_SORT_NAME_TABLE[2]
    	elseif npc.dwTemplateID == 496 then
    		szTilte = g_tStrings.STR_CRAFT_READ_BOOK_SORT_NAME_TABLE[1]
    	end
    end
    szTilte = szTilte .. "收书人"
    UIHelper.SetString(self.LabelTitle, szTilte)

    self.tbSelected = {}
    local tbSelected = FilterDef.BookCommit.GetRunTime()
    if tbSelected and #tbSelected > 0 then
        for nIndex, tbDef in ipairs(tbSelected) do
            self.tbSelected[nIndex] = {}
            for _, nEnableIndex in ipairs(tbDef) do
                self.tbSelected[nIndex][nEnableIndex] = true
            end
        end
    else
        for nIndex, tbDef in ipairs(FilterDef.BookCommit) do
            if type(tbDef) == "table" then
                self.tbSelected[nIndex] = {}
                for _, nEnableIndex in ipairs(tbDef.tbDefault) do
                    self.tbSelected[nIndex][nEnableIndex] = true
                end
            end
        end
    end

    self.scriptContentBook = UIHelper.GetBindScript(self.WidgetContentContainter)
end

function UIBookCommit:OnFrameBreathe()
    local player = GetClientPlayer()
	if not player or player.nMoveState == MOVE_STATE.ON_DEATH then
		UIMgr.Close(VIEW_ID.PanelCopyCommit)
		return
	end
	
    if self.dwTargetType == TARGET.NPC then
		local npc = GetNpc(self.dwTargetID)
		if not npc or not npc.CanDialog(player) then
			UIMgr.Close(VIEW_ID.PanelCopyCommit)
			return
		end
	end
end

function UIBookCommit:UpdateInfo()
    self:UpdateBagBookInfo()
    self:UpdateBookList()
    self:UpdateBookPrefab()
end

function UIBookCommit:UpdateBookList()
    self.tQuestInfoList = {}
    for k, v in pairs(self.tQuestID) do
        local nQuestID = tonumber(v[1])        
        local bSuccess, dwItemType, dwItemID = self:CheckReward(nQuestID)
		if bSuccess then
			local questInfo = GetQuestInfo(nQuestID)
			local tQuestStringInfo = Table_GetQuestStringInfo(nQuestID) or {}
			local bFinishPreQuest = true
			local bSelfFinish = true
			
			if questInfo.dwPrequestID1 ~= 0 then
				if g_pClientPlayer.GetQuestPhase(questInfo.dwPrequestID1) ~= 3 then
					bFinishPreQuest = false
				end
			end
			
			if questInfo.dwPrequestID2 ~= 0 then
				if g_pClientPlayer.GetQuestPhase(questInfo.dwPrequestID2) ~= 3 then
					bFinishPreQuest = false
				end
			end
			
			if questInfo.dwPrequestID3 ~= 0 then
				if g_pClientPlayer.GetQuestPhase(questInfo.dwPrequestID3) ~= 3 then
					bFinishPreQuest = false
				end
			end
			
			if questInfo.dwPrequestID4 ~= 0 then
				if g_pClientPlayer.GetQuestPhase(questInfo.dwPrequestID4) ~= 3 then
					bFinishPreQuest = false
				end
			end
			
			if g_pClientPlayer.GetQuestPhase(nQuestID) ~= 3 then
				bSelfFinish = false
			end
			
            local szQuestName = UIHelper.GBKToUTF8(tQuestStringInfo.szName)
			if self:MatchString(szQuestName, self.szSearchKey) and bFinishPreQuest and not bSelfFinish then
				local nHave, nTotal = 0, 0
                local tBookInfoList = {}
				for i=1, 8, 1 do
					local ItemInfo, dwRecipeID = self:GetRequireItemInfo(questInfo, i)
                    local nBookID, nSegmentID = GlobelRecipeID2BookID(dwRecipeID)
                    local nSubSort = Table_GetBookSubSort(nBookID, nSegmentID)
                    if not self.tbSelected[FilterType.Classify][nSubSort] then break end
					if ItemInfo then
                        local recipe = GetRecipe(12, nBookID, nSegmentID)
                        local tBookItem = GetItemInfo(recipe.dwCreateItemType, recipe.dwCreateItemIndex)
						local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(tBookItem.nQuality, false)
                        
                        local szBookName = Table_GetSegmentName(nBookID, nSegmentID)
                        szBookName = UIHelper.GBKToUTF8(szBookName)
                        szBookName = GetFormatText(szBookName, nil, nDiamondR, nDiamondG, nDiamondB)

						if self.tBagBook[dwRecipeID] then nHave = nHave + 1 end
						nTotal = nTotal + 1
                        table.insert(tBookInfoList, {
                            szBookName = szBookName,
                            dwTabType = recipe.dwCreateItemType,
                            dwIndex = recipe.dwCreateItemIndex,
                            bHasRead = self:HasReadBook(UI_GetClientPlayerID(), nBookID, nSegmentID),
                            fCallBack = function (node)
                                TipsHelper.DeleteAllHoverTips(true)
                                local _, scriptTips = TipsHelper.ShowItemTips(node, recipe.dwCreateItemType, recipe.dwCreateItemIndex, false)
                                scriptTips:SetBookID(dwRecipeID)
                                scriptTips:OnInitWithTabID(recipe.dwCreateItemType, recipe.dwCreateItemIndex)
                                scriptTips:SetBtnState({})
                            end
                        })
					end
				end
                if #tBookInfoList > 0 then
                    table.insert(self.tQuestInfoList, {
                        nHave = nHave,
                        nTotal = nTotal,
                        dwTabType = dwItemType, 
                        dwIndex = dwItemID,
                        nQuestID = nQuestID,
                        szQuestName = string.format("%s(%d/%d)", szQuestName, nHave, nTotal),
                        tBookInfoList = tBookInfoList,
                    })
                end
			end
		end
	end
end

function UIBookCommit:UpdateBookPrefab()
    self.scriptContentBook:ClearContainer()
    self.scriptContentBook:OnInit(PREFAB_ID.WidgetBookListSubTitle, function (scriptContainer, tQuestInfo) -- 初始化标题
        UIHelper.SetString(scriptContainer.LabelTitleDown, tQuestInfo.szQuestName)
        UIHelper.SetString(scriptContainer.LabelTitleUp, tQuestInfo.szQuestName)
        local bIsTrain = not tQuestInfo.dwTabType
        if tQuestInfo.dwTabType then
            local tItemInfo = ItemData.GetItemInfo(tQuestInfo.dwTabType, tQuestInfo.dwIndex)
            local szName = ItemData.GetItemNameByItemInfo(tItemInfo)
            szName = UIHelper.GBKToUTF8(szName)
            local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, scriptContainer.WidgetItemIcon)
            scriptItem:OnInitWithTabID(tQuestInfo.dwTabType, tQuestInfo.dwIndex)
            scriptItem:SetClickCallback(function (dwTabType, dwIndex)
				TipsHelper.ShowItemTips(scriptItem._rootNode, dwTabType, dwIndex, false)
			end)
        else
            local nTrain = self:GetRewardValue(tQuestInfo.nQuestID)            
            local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, scriptContainer.WidgetItemIcon)
            scriptItem:OnInitCurrency(CurrencyType.Train, nTrain)
            scriptItem:SetClickCallback(function (dwTabType, dwIndex)
            TipsHelper.ShowCurrencyTips(scriptItem._rootNode, CurrencyType.Train, nTrain)
        end)
        end
        UIHelper.SetVisible(scriptContainer.WidgetItemIcon, true)
        UIHelper.SetVisible(scriptContainer.LabelTrain, false)
    end)

    for _, tQuestInfo in ipairs(self.tQuestInfoList) do
        local tCellInfoList = {}
        for _, tBookInfo in ipairs(tQuestInfo.tBookInfoList) do
            table.insert(tCellInfoList, {
                nPrefabID = PREFAB_ID.WidgetCopyBookCell,
                tArgs = {
                    tBookInfo = tBookInfo
                }
            })
        end
        self.scriptContentBook:AddContainer(tQuestInfo, tCellInfoList, function (scriptContainer, bSelected) -- 标题选中事件
            if bSelected then self.nSelQuestID = tQuestInfo.nQuestID end
        end,function () -- 标题点击事件
    
        end, true)
    end

    self.scriptContentBook:UpdateInfo()

    if #self.scriptContentBook.tContainerList > 0 then
        Timer.AddFrame(self, 1, function ()
            UIHelper.SetSelected(self.scriptContentBook.tContainerList[1].ToggleSelect, true)
        end)
    end

    UIHelper.SetVisible(self.WidgetEmpty, #self.tQuestInfoList == 0)
end

function UIBookCommit:UpdateBagBookInfo()
	self.tBagBook = {}
	
	local player = GetClientPlayer()
	local tIndex = GetPackageIndex() or {}
	for _, dwBox in pairs(tIndex) do
		local nSize = player.GetBoxSize(dwBox) - 1
		for dwX = 0, nSize, 1 do
			local Item = ItemData.GetPlayerItem(player, dwBox, dwX)
			if Item and Item.nGenre == ITEM_GENRE.BOOK then
				local nRecipeID = Item.nBookID
				self.tBagBook[nRecipeID] = true
			end
		end
	end
	
end

function UIBookCommit:OnCommit()
    local npcType = self.dwTargetType
	local npcID   = self.dwTargetID
	local nChoice1, nChoice2 = 1, 5

    g_pClientPlayer.FinishQuest(self.nSelQuestID, npcType, npcID, nChoice1 - 1, nChoice2 - 1)
end

function UIBookCommit:GetRequireItemInfo(questInfo, nIndex)
	local nType, nID, dwRecipeID = 0, 0, 0
	if nIndex == 1 then
		nType  = questInfo.dwEndRequireItemType1 
		nID	 = questInfo.dwEndRequireItemIndex1 
		dwRecipeID  = questInfo.dwEndRequireItemAmount1 
	elseif nIndex == 2 then
		nType  = questInfo.dwEndRequireItemType2 
		nID	 = questInfo.dwEndRequireItemIndex2 
		dwRecipeID  = questInfo.dwEndRequireItemAmount2 
	elseif nIndex == 3 then
		nType  = questInfo.dwEndRequireItemType3 
		nID	 = questInfo.dwEndRequireItemIndex3 
		dwRecipeID  = questInfo.dwEndRequireItemAmount3 
	elseif nIndex == 4 then
		nType  = questInfo.dwEndRequireItemType4 
		nID	 = questInfo.dwEndRequireItemIndex4 
		dwRecipeID  = questInfo.dwEndRequireItemAmount4 
	elseif nIndex == 5 then
		nType  = questInfo.dwEndRequireItemType5 
		nID	 = questInfo.dwEndRequireItemIndex5 
		dwRecipeID  = questInfo.dwEndRequireItemAmount5 
	elseif nIndex == 6 then
		nType  = questInfo.dwEndRequireItemType6 
		nID	 = questInfo.dwEndRequireItemIndex6 
		dwRecipeID  = questInfo.dwEndRequireItemAmount6 
	elseif nIndex == 7 then
		nType  = questInfo.dwEndRequireItemType7 
		nID	 = questInfo.dwEndRequireItemIndex7 
		dwRecipeID  = questInfo.dwEndRequireItemAmount7
	elseif nIndex == 8 then
		nType  = questInfo.dwEndRequireItemType8 
		nID	 = questInfo.dwEndRequireItemIndex8 
		dwRecipeID  = questInfo.dwEndRequireItemAmount8 
	end
	if nType == 0 or nID == 0 then
		return nil, nil,nil,nil
	end
    local itemInfo  = GetItemInfo(nType, nID)
    if not itemInfo then
        Log(string.format("questInfo Require%s nItemType=%d nIndex=%d dwRecipeID=%d GetItemInfo is nil", nIndex, nType, nID, dwRecipeID))
    end
	return itemInfo, dwRecipeID, nType, nID
end

function UIBookCommit:HasReadBook(nPlayerID, nBookID, nSegmentID)
    local player = GetPlayer(nPlayerID)
    if not player then
        return false
    end
    local tSegmentBook = player.GetBookSegmentList(nBookID)
    for _, nID in pairs(tSegmentBook) do
        if nID == nSegmentID then
            return true
        end
    end
    return false
end

function UIBookCommit:CheckReward(nQuestID)
    local questInfo = GetQuestInfo(nQuestID)
	local tFlag = {}
	
	if questInfo.dwAffectForceID1 ~=0 or questInfo.dwAffectForceID2 ~=0 or 
	   questInfo.dwAffectForceID3 ~=0 or questInfo.dwAffectForceID4 ~=0 then
		tFlag[0] = true
	end

    local bHasAwardItem = false
    local tHortation = questInfo.GetHortation() or  {}    
    local dwItemType, dwItemID
    for i = 1, 2 do
        local itemgroup = tHortation["itemgroup"..i]
        if itemgroup then
            for _, v in ipairs(itemgroup) do 
                local ItemInfo = GetItemInfo(v.type, v.index)
                if ItemInfo then
                    dwItemType = v.type
                    dwItemID = v.index
                    tFlag[v.type] = true
                    bHasAwardItem = true
                end
            end
         end
    end
    if not bHasAwardItem then tFlag[0] = true end
    
    local bSuccess = false
    for nIndex, bSelected in pairs(self.tbSelected[FilterType.Reward]) do
        local nBonus = tBookReward[nIndex]
        bSuccess = bSuccess or (bSelected and tFlag[nBonus])
    end
    
    return bSuccess, dwItemType, dwItemID
end

function UIBookCommit:MatchString(szSrc, szDst)
    if not szDst then
        return true
    end
	local nPos = string.match(szSrc, szDst)
	if not nPos then
	   return false;
	end

	return true
end

function UIBookCommit:GetRewardText(nQuestID)
    local questInfo = GetQuestInfo(nQuestID)
    local tHortation = questInfo.GetHortation() or {}
    local szText = ""
    for i = 1, 4, 1 do
        local dwForceID = questInfo["dwAffectForceID" .. i]
        local value = questInfo["nAffectForceValue" .. i]
        if dwForceID ~= 0 then
            local tRepuForceInfo = Table_GetReputationForceInfo(dwForceID)
            if tRepuForceInfo then
                local szName = tRepuForceInfo.szName
                szText = szText .. szName .. "(" .. value .. ") "
            end
        end
    end

    if szText ~= "" then
        szText = g_tStrings.STR_QUEST_CAN_GET_REPUTATION .. szText
    end

    if tHortation.nPresentExamPrint and tHortation.nPresentExamPrint ~= 0 then --监本印文
        szText = FormatString(g_tStrings.STR_QUEST_CAN_GET_PRESENTEXAMPRINT, tHortation.nPresentExamPrint)
    end

    if tHortation.nPresentJustice and tHortation.nPresentJustice ~= 0 then --侠义值
        szText = FormatString(g_tStrings.STR_QUEST_CAN_GET_PRESENTJUSTICE, tHortation.nPresentJustice)
    end

    if questInfo.nTitlePoint and questInfo.nTitlePoint ~= 0 then --战阶积分
        szText = FormatString(g_tStrings.STR_QUEST_CAN_GET_TITLE_POINT, questInfo.nTitlePoint)
    end

    if tHortation.presenttrain and tHortation.presenttrain ~= 0 then --修为
        szText = FormatString(g_tStrings.STR_QUEST_CAN_GET_PRESENTTRAIN, tHortation.presenttrain)
    end

    if tHortation.nPresentContribution and tHortation.nPresentContribution ~= 0 then --休闲点
        szText = FormatString(g_tStrings.STR_QUEST_CAN_GET_CONTRIBUTION, tHortation.nPresentContribution)
    end

    if tHortation.tongfund and tHortation.tongfund ~= 0 then --帮会资金
        szText = FormatString(g_tStrings.STR_QUEST_CAN_GET_GUILD_MONEY, tHortation.tongfund)
    end

    return szText
end

function UIBookCommit:GetRewardValue(nQuestID)
    local questInfo = GetQuestInfo(nQuestID)
    local tHortation = questInfo.GetHortation() or {}

    return tHortation.presenttrain
end

return UIBookCommit