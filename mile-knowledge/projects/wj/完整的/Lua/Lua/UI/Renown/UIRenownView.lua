local UIRenownView = class("UIRenownView")

local DEFAULT_DLC_ID = 0

function UIRenownView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if not self.ScrollDlcList then
        return
    end
    -- 由于包含了MiniScene，所以先关闭所有MiniScene。
    UIMgr.CloseAllMiniSceneView(VIEW_ID.PanelRenownRewordList)

    self:Init()
    RepuData.TryInitingRepuStats()
    RepuData.TryInitingAllRepuRewards()
    RepuData.TryInitingNpcRewards()
    RepuData.InitReceivedRepuRewards()  -- 要经常更新
    RemoteCallToServer("On_Rank_GetReputationRank")
    self.bNeedInitDlcList = true
    self:UpdateInfo()
    self:ApplyFilter()
end

function UIRenownView:OnExit()
    self.bInit = false
    ReputationData.szLastKeyWord = self.szKeyWord
end

function UIRenownView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(VIEW_ID.PanelRenownList)
    end)

    UIHelper.BindUIEvent(self.BtnProp, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelRenownUseItemPop, self.dwCurForceID)
    end)

    UIHelper.BindUIEvent(self.BtnForceClear, EventType.OnClick, function ()
        UIHelper.SetText(self.EditBoxForceSearch, "")
        self.szKeyWord = nil
        self:RefreshForceList()
    end)

    UIHelper.BindUIEvent(self.BtnExamine, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelRenowReputationRule, self.dwCurForceID)
    end)

    UIHelper.BindUIEvent(self.BtnWrite, EventType.OnClick, function ()
        if not UIMgr.IsViewOpened(VIEW_ID.PanelRenownRewordList, true) then
            UIMgr.Open(VIEW_ID.PanelRenownRewordList)
        else
            Homeland_SendMessage(HOMELAND_FURNITURE.EXIT)
            Timer.AddFrame(self, 1, function ()
                UIMgr.CloseWithCallBack(VIEW_ID.PanelRenownRewordList, function ()
                    UIMgr.Open(VIEW_ID.PanelRenownRewordList)
                end)
            end)
        end
    end)

    UIHelper.BindUIEvent(self.BtnServantHeadPartner, EventType.OnClick, function ()
        if not UIMgr.IsViewOpened(VIEW_ID.PanelRenownRewordList, true) then
            UIMgr.Open(VIEW_ID.PanelRenownRewordList, {dwForceID = self.dwCurForceID})
        else
            Homeland_SendMessage(HOMELAND_FURNITURE.EXIT)
            Timer.AddFrame(self, 1, function ()
                UIMgr.CloseWithCallBack(VIEW_ID.PanelRenownRewordList, function ()
                    UIMgr.Open(VIEW_ID.PanelRenownRewordList, {dwForceID = self.dwCurForceID})
                end)
            end)
        end
    end)

    UIHelper.BindUIEvent(self.BtnScreen, EventType.OnClick, function ()
        self.tbIndexToLevelMap, self.tbIndexToGroupMap = ReputationData.InitFilter(self.nSelectDlcID)
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnScreen, TipsLayoutDir.BOTTOM_RIGHT, FilterDef.Reputation)
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxForceSearch, function ()
        self.szKeyWord = UIHelper.GetText(self.EditBoxForceSearch)
        self:RefreshForceList()
    end)

    UIHelper.TableView_addCellAtIndexCallback(self.TableViewForce, function(tableView, nIndex, script, node, cell)
        local tForceInfo = self.tCurForceInfoList[nIndex]
        if tForceInfo and script then
            self.tScriptForceMap[tForceInfo.dwForceID] = script
            script:OnEnter(tForceInfo.nDlcID, tForceInfo.dwForceID, tForceInfo.szGroupName, tForceInfo.fCallBack)
            if not script.bAddToggle then
                script.bAddToggle = true
            end
            if not self.dwCurForceID then
                self.dwCurForceID = tForceInfo.dwForceID
                self:UpdateForceRepuDetail()
                UIHelper.SetSelected(script.ToggleSelect, true)
            end
            local bSelected = UIHelper.GetSelected(script.ToggleSelect)
            if script.dwForceID ~= self.dwCurForceID and bSelected then
                UIHelper.SetSelected(script.ToggleSelect, false)
            elseif script.dwForceID == self.dwCurForceID and not bSelected then
                UIHelper.SetSelected(script.ToggleSelect, true, false)
                script.fCallBack()
            end
            Timer.AddFrame(self, 1, function ()
                script:Resize()
            end)
        end
    end)
end

function UIRenownView:RegEvent()
    Event.Reg(self, EventType.OnUpdateReputationRank, function ()
        self:UpdateReputationAheadRate()
    end)

    Event.Reg(self, "ON_UPDATE_REPUTATION_RANK", function ()
        self:UpdateReputationAheadRate()
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        UIHelper.WidgetFoceDoAlign(self)

        local nCurIndex = 1
        for nIndex, tForceInfo in ipairs(self.tAllForceInfoList) do
            if tForceInfo.dwForceID == self.dwCurForceID then
                nCurIndex = nIndex
                break
            end
        end

        UIHelper.TableView_scrollToCell(self.TableViewForce, #self.tAllForceInfoList, nCurIndex, 0)
        Timer.AddFrame(self, 1, function ()
            for _, scriptForce in pairs(self.tScriptForceMap) do
                scriptForce:Resize()
            end
        end)
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.Reputation.Key then
            self:ApplyFilter(tbSelected)
        end
    end)
end

function UIRenownView:Init()
    self.szKeyWord = self.szKeyWord or ReputationData.szLastKeyWord
    if self.szKeyWord then
        UIHelper.SetText(self.EditBoxForceSearch, self.szKeyWord)
    end
    UIHelper.SetSwallowTouches(self.TableViewForce, false)
end

function UIRenownView:UpdateInfo()
    self:InitOrUpdateDlcList(self.bNeedInitDlcList)
    self.bNeedInitDlcList = false

    self:UpdateReputationAheadRate()
    self:UpdateAllForceListInDlc()
end

function UIRenownView:InitOrUpdateDlcList(bInit)
	local aDlcList = Table_GetSortedDlcList()
	local nDlcCount = #aDlcList + 1  --- 加上一个总览
	if bInit then
        self.scriptDlcList = {}
		UIHelper.RemoveAllChildren(self.ScrollDlcList)
	end
	for nDlcIndex = 1, nDlcCount do
		nDlcIndex = nDlcIndex - 1
		local tStat
		if nDlcIndex == 0 then
			tStat = {RepuData.GetTopRepuCount(), RepuData.GetVisibleForces()}
		else
			tStat = RepuData.GetRepuDlcStats()[nDlcIndex]
		end

		local nDlcID = aDlcList[nDlcIndex] or DEFAULT_DLC_ID
        if self.scriptDlcList[nDlcID] then
            self.scriptDlcList[nDlcID]:UpdateInfo(nDlcID, tStat)
        else
            local scriptDlc = UIHelper.AddPrefab(PREFAB_ID.WidgetRenownList, self.ScrollDlcList, nDlcID, tStat, function ()
                Timer.DelTimer(self, self.nUpdateListTimerID)
                self.nUpdateListTimerID = Timer.AddFrame(self, 5, function()
                    self.nSelectDlcID = nDlcID
                    self:UpdateAllForceListInDlc()
                end)
            end)
            self.scriptDlcList[nDlcID] = scriptDlc
            if not self.nSelectDlcID and scriptDlc then
                self.nSelectDlcID = nDlcID
                UIHelper.SetSelected(scriptDlc.ToggleSelect, true)
            end
        end
	end
    UIHelper.ScrollViewDoLayout(self.ScrollDlcList)
    UIHelper.ScrollToTop(self.ScrollDlcList, 0)
end

function UIRenownView:UpdateReputationAheadRate()
    local player = GetClientPlayer()
    if not player then
        return
    end
    UIHelper.SetVisible(self.LabelRepuPoints, false)
    if player.GetTotalReputation then
        local szRepuPoints = tostring(player.GetTotalReputation()).."点"
        UIHelper.SetRichText(self.LabelRepuPoints, szRepuPoints)
        UIHelper.SetVisible(self.LabelRepuPoints, true)
    end

    local szAheadDesc = string.format("你已经超过<color=#ffd778>%d%%</color>的玩家", GetRoundedNumber(100 * Reputation_GetSelfRepuRank()))
    UIHelper.SetRichText(self.LabelAheadRate, szAheadDesc)
end

function UIRenownView:UpdateAllForceListInDlc(dwDefaultForceID)
    local tSortForceList = ReputationData.GetSortForceList(self.nSelectDlcID)
	local nForceCount = #tSortForceList

    self.dwCurForceID = dwDefaultForceID
    self.tAllForceInfoList = {}
    self.tCurForceInfoList = {}
    self.tScriptForceMap = {}
	for i = 1, nForceCount do
        local tForceInfo = {}
		local tSortInfo = tSortForceList[i]
		tForceInfo.dwForceID, tForceInfo.szGroupName, tForceInfo.nDlcID = tSortInfo[1], tSortInfo[2], tSortInfo[3]
        tForceInfo.szGroupName = UIHelper.GBKToUTF8(tForceInfo.szGroupName)
        tForceInfo.fCallBack = function ()
            Timer.DelTimer(self, self.nUpdateRightTimerID)
            self.nUpdateRightTimerID = Timer.AddFrame(self, 5, function()
                self.dwCurForceID = tForceInfo.dwForceID
                self:UpdateForceRepuDetail()
            end)
        end
        local tForceUIInfo = Table_GetReputationForceInfo(tForceInfo.dwForceID)
        if tForceInfo then
            tForceInfo.szName = UIHelper.GBKToUTF8(tForceUIInfo.szName)
        end
        table.insert(self.tAllForceInfoList, tForceInfo)
        table.insert(self.tCurForceInfoList, tForceInfo)
	end

    UIHelper.TableView_init(self.TableViewForce, #self.tCurForceInfoList, PREFAB_ID.WidgetRenownMessageList)
    UIHelper.TableView_reloadData(self.TableViewForce)
end

function UIRenownView:UpdateForceRepuDetail()
    local player = GetClientPlayer()
    if not player then
        return
    end
    local bHasSelectedForceID = self.dwCurForceID ~= nil
    UIHelper.SetVisible(self.ScrollViewDetail, bHasSelectedForceID)
    if not bHasSelectedForceID then
        return
    end
    local dwForceID = self.dwCurForceID
	local tForceUIInfo = Table_GetReputationForceInfo(dwForceID)
	if not tForceUIInfo then
		LOG.ERROR("ERROR!找不到ID == " .. tostring(dwForceID) .. "的声望势力信息！")
		return
	end

    local szName = UIHelper.GBKToUTF8(tForceUIInfo.szName)
    local szDesc = UIHelper.GBKToUTF8(tForceUIInfo.szDesc)
    local szDescList = string.split(szDesc, "※")
    szDesc = szDescList[1]
    local szTitle = ""
    if #szDescList > 1 then
        szTitle = szDescList[2]
        local szTitleList = string.split(szTitle, "：")
        if #szTitleList > 1 then
            szTitle = string.format("<color=#b6d4dc>%s：</c><color=#e2f6fb>%s</c>", szTitleList[1], szTitleList[2])
        end
    end
    UIHelper.SetString(self.LabelDetailName, szName)
    UIHelper.SetString(self.LabelDetailBrief, szDesc)
    UIHelper.SetRichText(self.LabelDetailTitle, szTitle)
    UIHelper.SetVisible(self.BtnProp, false)--ReputationData.CanUseReputationItem(dwForceID))
    local scriptStoreDescribe = UIHelper.GetBindScript(self.WidgetRenownStoreDescribe)
    if scriptStoreDescribe then
        scriptStoreDescribe:OnEnter(tForceUIInfo.dwNpcLinkID)
    end

    if not self.scriptDetailUnlockItemList then
        self.scriptDetailUnlockItemList = {}
    end

    for _, scriptItem in ipairs(self.scriptDetailUnlockItemList) do
        UIHelper.SetVisible(scriptItem._rootNode, false)
    end

    local nCount = 0
    local nCurRepuLevel = player.GetReputeLevel(dwForceID)
    local tItems = Table_GetReputationRewardItemInfoByForceID(dwForceID)
    if tItems then
        local aItemInfoList = tItems[nCurRepuLevel+1] or {}
        local aFiltedItemList = RepuData.TryFliterItems(aItemInfoList)
        if #aFiltedItemList > 0 then
            aItemInfoList = aFiltedItemList
        end
        for nIndex, tItemInfo in ipairs(aItemInfoList) do
            local dwItemTabType, dwItemTabIndex = tItemInfo.dwItemTabType, tItemInfo.dwItemTabIndex
            local scriptItem = self.scriptDetailUnlockItemList[nIndex]
            if not scriptItem then
                scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.LayoutRenownStoreUnlockItem)
                table.insert(self.scriptDetailUnlockItemList, scriptItem)
            end
            scriptItem.dwItemTabType = dwItemTabType
            scriptItem.dwItemTabIndex = dwItemTabIndex
            scriptItem:OnInitWithTabID(dwItemTabType, dwItemTabIndex)
            scriptItem:SetSelectMode(false)
            scriptItem:SetClearSeletedOnCloseAllHoverTips(true)
            scriptItem:SetToggleGroupIndex(ToggleGroupIndex.ReputationRewardItem)
            scriptItem:SetClickCallback(function(nTabType, nTabID)
                TipsHelper.ShowItemTips(scriptItem._rootNode, dwItemTabType, dwItemTabIndex)
            end)
            UIHelper.SetSwallowTouches(scriptItem.ToggleSelect, false)
            UIHelper.SetVisible(scriptItem._rootNode, true)

            nCount = nCount + 1
        end
    end
    UIHelper.SetVisible(self.WidgetEmptyUnlockItem, nCount == 0)
    UIHelper.SetVisible(self.LayoutRenownStoreUnlockItem, true)
    local tGainDescs = Table_GetReputationGainDescByForceID(dwForceID)
    if tGainDescs then
		--- 找到下一等级的获取描述信息
		local nDescCount = #tGainDescs
		local tDescToShow
		for i = nDescCount, 1, -1 do
			local tDesc = tGainDescs[i]
			if i == nDescCount and tDesc.dwToLevel <= nCurRepuLevel then
				break
			end

			if (i == 1 or tDesc.dwFromLevel <= nCurRepuLevel) and tDesc.dwToLevel > nCurRepuLevel then
				tDescToShow = tDesc
				break
			end

			if tDesc.dwFromLevel <= nCurRepuLevel and tDesc.dwToLevel > nCurRepuLevel then
				tDescToShow = tDesc
				break
			end
		end
        UIHelper.SetVisible(self.WidgetRenownAccess, tDescToShow ~= nil)
        if tDescToShow then
			local tFromLevelInfo = Table_GetReputationLevelInfo(tDescToShow.dwFromLevel)
			local tToLevelInfo = Table_GetReputationLevelInfo(tDescToShow.dwToLevel)
            local szFromName = UIHelper.GBKToUTF8(tFromLevelInfo.szName)
            local szToName = UIHelper.GBKToUTF8(tToLevelInfo.szName)
			local szTitle = g_tStrings.STR_BRACKET_LEFT .. szFromName .. "-" .. szToName .. g_tStrings.STR_BRACKET_RIGHT
            local szAccessDesc = szTitle .. "\n" .. UIHelper.GBKToUTF8(tDescToShow.szDesc)
			UIHelper.SetString(self.LabelRenownAccessDescribe, szAccessDesc)
		end
    end

	local tServantInfo, bSuccess = RepuData.GetServantInfoByForceID(dwForceID)
    UIHelper.SetVisible(self.WidgetRenownFriend, bSuccess)
    if bSuccess then
        local szFriendName = UIHelper.GBKToUTF8(tServantInfo.szNpcName)
        local szDescBrief = UIHelper.GBKToUTF8(tServantInfo.szDescBrief)
        local szBuffName = UIHelper.GBKToUTF8(tServantInfo.szBuffName)
        szBuffName = g_tStrings.STR_REPUTATION_NPC_BUFF_TITLE .. szBuffName
        local szBuffDesc = UIHelper.GBKToUTF8(tServantInfo.szBuffDesc)
        local nRequiredRepuLevel = tServantInfo.nRequiredRepuLevel
        local tRequiredRepuLevelInfo = Table_GetReputationLevelInfo(nRequiredRepuLevel)
        local szReputName = UIHelper.GBKToUTF8(tRequiredRepuLevelInfo.szName)
        local szRequiredRepuLevel = szReputName or g_tStrings.STR_REPUTATION_LEVEL_INVALID
        szRequiredRepuLevel = FormatString(g_tStrings.STR_REPUTATION_NPC_GAIN_DESC, szRequiredRepuLevel)

        UIHelper.SetString(self.LabelFriendName, szFriendName)
        UIHelper.SetString(self.LabelFriendDesc, szDescBrief)
        UIHelper.SetString(self.LabelFriendBuffName, szBuffName)
        UIHelper.SetString(self.LabelFriendBuffMessage, szBuffDesc)
        UIHelper.SetString(self.LabelFriendRequire, szRequiredRepuLevel)

        local tbConfig = Table_GetServantInfo(tServantInfo.dwNpcIndex)
        if tbConfig then
            UIHelper.SetTexture(self.ImgServantHeadPartner, tbConfig.szImagePath)
        end
    end
    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewDetail, true, true)
    UIHelper.ScrollViewDoLayout(self.ScrollViewDetail)
    UIHelper.ScrollToTop(self.ScrollViewDetail, 0)
end

function UIRenownView:RefreshForceList(dwCurForceID)
    local player = GetClientPlayer()
    if not player then
        return
    end
    self.dwCurForceID = dwCurForceID
    self.tCurForceInfoList = {}
    self.tScriptForceMap = {}
    for _, tForceInfo in ipairs(self.tAllForceInfoList) do
        local bVisable = true
        local dwReputationLevel = player.GetReputeLevel(tForceInfo.dwForceID)
        local aMapIDs = Table_GetReputationForceMaps(tForceInfo.dwForceID)
        bVisable = bVisable and (self.nFliterLevel == nil or dwReputationLevel == self.nFliterLevel)
        bVisable = bVisable and (self.szFliterGroupName == nil or tForceInfo.szGroupName == self.szFliterGroupName)
        if bVisable then
            if self.dwFliterMapID then
                bVisable = CheckIsInTable(aMapIDs, self.dwFliterMapID)
            elseif self.dwFliterRegionID then
                local tMaps = ReputationData.GetMapsInCurDlcAndRegion(self.dwFliterRegionID)
                for _, dwMapID in ipairs(tMaps) do
                    if CheckIsInTable(aMapIDs, dwMapID) then
                        bVisable = true
                        break
                    end
                end
            end
        end
        if self.szKeyWord and self.szKeyWord ~= "" then
            local nStart,_,_ = string.find(tForceInfo.szName, self.szKeyWord)
            local bFindGains = self:OnFilterGain(tForceInfo.dwForceID)
            bVisable = bVisable and (nStart ~= nil or bFindGains)
        end
        if bVisable then
            table.insert(self.tCurForceInfoList, tForceInfo)
        end
    end

    UIHelper.TableView_init(self.TableViewForce, #self.tCurForceInfoList, PREFAB_ID.WidgetRenownMessageList)
    UIHelper.TableView_reloadData(self.TableViewForce)

    UIHelper.SetVisible(self.WidgetEmpty, #self.tCurForceInfoList == 0)
end

function UIRenownView:OnFilterGain(dwForceID)
	local tGainDescs = Table_GetReputationGainDescByForceID(dwForceID)
	if #tGainDescs <= 0 then
		return false
	end
	local szDesc = UIHelper.GBKToUTF8(tGainDescs[1].szDesc)
	if not szDesc or szDesc == "" then
		return false
	end
    local nStart,_,_ = string.find(szDesc, self.szKeyWord)
	return nStart ~= nil
end

function UIRenownView:IsDefaultFilter(tbSelected)
    for nIndex, tbFilter in ipairs(tbSelected) do
        if tbFilter[1] ~= 1 then return false end
    end
    return true
end

function UIRenownView:ApplyFilter(tbSelected)
    tbSelected = tbSelected or FilterDef.Reputation.GetRunTime()
    if not tbSelected then
        tbSelected = {
            [1] = {1},
            [2] = {1},
            [3] = {1},
        }
    end

    if self:IsDefaultFilter(tbSelected) then
        UIHelper.SetSpriteFrame(self.ImgScreen, ShopData.szScreenImgDefault)
    else
        UIHelper.SetSpriteFrame(self.ImgScreen, ShopData.szScreenImgActiving)
    end

    self.tbIndexToLevelMap, self.tbIndexToGroupMap = ReputationData.InitFilter(self.nSelectDlcID)
    -- 地图
    self.dwFliterMapID = nil
    self.dwFliterRegionID = nil


    if tbSelected[1][1] ~= 1 then
        local nCurMapID = g_pClientPlayer and g_pClientPlayer.GetMapID() or 0
        self.dwFliterMapID = nCurMapID
        self.dwFliterRegionID = Table_GetMap(nCurMapID).dwRegionID
    end

    -- 等级
    local nLevelIndex = tbSelected[2][1]
    self.nFliterLevel = (nLevelIndex ~= 1) and self.tbIndexToLevelMap[nLevelIndex] or nil

    -- 势力
    local nGroupIndex = tbSelected[3][1]
    self.szFliterGroupName = (nGroupIndex ~= 1) and self.tbIndexToGroupMap[nGroupIndex] or nil

    self:RefreshForceList()
end

function UIRenownView:RedirectForceView(dwRewardForceID)
    -- 切换DLC到总览
    self.nSelectDlcID = DEFAULT_DLC_ID
    self.szKeyWord = nil
    ReputationData.ClearFilterState()
    UIHelper.SetText(self.EditBoxForceSearch, "")
    self:ApplyFilter()
    self:UpdateAllForceListInDlc(dwRewardForceID)

    -- 选中势力
    for nIndex, tForceInfo in ipairs(self.tCurForceInfoList) do
        if tForceInfo.dwForceID == dwRewardForceID then
            self.dwCurForceID = dwRewardForceID
            UIHelper.TableView_scrollToCell(self.TableViewForce, #self.tCurForceInfoList, nIndex, 0)
            local scriptForce = self.tScriptForceMap[self.dwCurForceID]
            if scriptForce then
                UIHelper.SetSelected(scriptForce.ToggleSelect, true, false)
                Timer.AddFrame(self, 1, function ()
                    scriptForce.fCallBack()
                end)
            end
            break
        end
    end
end

return UIRenownView