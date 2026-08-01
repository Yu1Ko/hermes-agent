-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetBattlePassQuest
-- Date: 2022-12-23 10:55:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetBattlePassQuest = class("UIWidgetBattlePassQuest")
function UIWidgetBattlePassQuest:OnEnter(WidgetRewardView)
    if not WidgetRewardView then
        return
    end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:Init(WidgetRewardView)
    self:UpdateInfo()
end

function UIWidgetBattlePassQuest:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetBattlePassQuest:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIHelper.SetVisible(self.WidgetRewardView, true)
        UIHelper.SetVisible(self._rootNode, false)
        local scriptRewardView = UIHelper.GetBindScript(self.WidgetRewardView)
        scriptRewardView:TryScrollToNextRewardGroup()
    end)

    UIHelper.BindUIEvent(self.BtnPray, EventType.OnClick, function ()
        UIMgr.OpenSingle(true, VIEW_ID.PanelPrayerPlatform)
    end)

    for nIndex, toggle in ipairs(self.tToggleQuestNavigations) do
        UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function (_, bSelected)
            if bSelected then
                self.szSelectedQuestType = HuaELouData.QuestType[nIndex]
                self:RefreshQuestInfo()
            end
        end)
    end

    for nIndex, toggle in ipairs(self.tToggleQuestFiliter) do
        UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function (_, bSelected)
            self:OnSelectActivityType(nIndex, bSelected)
            self:RefreshQuestInfo()
        end)
    end
end

function UIWidgetBattlePassQuest:RegEvent()
    Event.Reg(self, "REMOTE_BATTLEPASS", function ()
        self:UpdateExpLevelInfo()
    end)

    Event.Reg(self, "UPDATE_WISH_ITEM", function()
        self:UpdateWishItemInfo()
    end)

    Event.Reg(self, EventType.OnExitBattlePassQuestPanel, function ()
        UIHelper.SetVisible(self.WidgetRewardView, true)
        UIHelper.SetVisible(self._rootNode, false)
        local scriptRewardView = UIHelper.GetBindScript(self.WidgetRewardView)
        scriptRewardView:TryScrollToNextRewardGroup()
    end)
end

function UIWidgetBattlePassQuest:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetBattlePassQuest:Init(WidgetRewardView)
    self.WidgetRewardView = WidgetRewardView
    self.szSelectedQuestType = HuaELouData.QuestType[1]
    UIHelper.SetVisible(WidgetRewardView, false)

    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupNavigationType)
    for nIndex, toggle in ipairs(self.tToggleQuestNavigations) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupNavigationType, toggle)
    end

    for nIndex, tClassInfo in ipairs(HuaELouData.tCheckBoxClass) do
        tClassInfo.bCheck = true
        UIHelper.SetSelected(self.tToggleQuestFiliter[nIndex+1], tClassInfo.bCheck)
    end
end

function UIWidgetBattlePassQuest:OnSelectActivityType(nIndex, bSelected)
    HuaELouData.tCheckBoxClass[nIndex-1].bCheck = bSelected
    local bAllSelected = true
    if nIndex-1 == 0 then
        for idx, toggle in ipairs(self.tToggleQuestFiliter) do
            if idx > 1 then
                UIHelper.SetSelected(toggle, bSelected)
                HuaELouData.tCheckBoxClass[idx-1].bCheck = bSelected
            end
        end
    elseif nIndex-1 ~= 0 and not bSelected then        
        for idx = 2, #HuaELouData.tCheckBoxClass, 1 do
            bAllSelected = bAllSelected and HuaELouData.tCheckBoxClass[idx].bCheck
        end
        if not bAllSelected and UIHelper.GetSelected(self.tToggleQuestFiliter[1]) then
            UIHelper.SetSelected(self.tToggleQuestFiliter[1], false, false)
            HuaELouData.tCheckBoxClass[0].bCheck = false
        end
    end
    UIHelper.SetVisible(self.ImgActivityTypeBg, bAllSelected)
    UIHelper.SetVisible(self.ImgFiltered, not bAllSelected)
end

function UIWidgetBattlePassQuest:UpdateInfo()
    UIHelper.SetVisible(self._rootNode, true)
    self:UpdateQuestInfo()
    self:UpdateWishItemInfo()
end

function UIWidgetBattlePassQuest:UpdateWishItemInfo()
    local tInfo = GDAPI_GetSpecialWishInfo()
    DungeonData.tWishInfo = tInfo
    
    local nPercent = tInfo.nWishCoin/tInfo.nMaxWishCoinLimit
    local szText = tostring(tInfo.nWishCoin)
    if tInfo.nWishIndex ~= 0 then
        nPercent = (DungeonData.MAX_WISH_ITEM_RETRY_COUNT - tInfo.nRemainTryCount) / DungeonData.MAX_WISH_ITEM_RETRY_COUNT
        szText = string.format("%d次内必出", tInfo.nRemainTryCount)
    end
    UIHelper.SetProgressBarPercent(self.ImgSliderWishCoin, nPercent * 100)
    UIHelper.SetString(self.LabelWishCoin, szText)
    UIHelper.SetVisible(self.ImgPrayRedDot, tInfo.nWishIndex == 0 and tInfo.nWishCoin == tInfo.nMaxWishCoinLimit)
    UIHelper.SetVisible(self.ImgPrayUp, tInfo.nWishIndex ~= 0 and tInfo.nRemainTryCount == 1)
    UIHelper.SetVisible(self.WidgetPrayEff, DungeonData.CanWishItemFlash())
end

function UIWidgetBattlePassQuest:IsQuestFinished(tQuestInfo)
	if not tQuestInfo then
		return
	end

	local nFinishCount = 0
	local nBuffFinish  = 0
	local nQuestFinish = 0
	local nMaxCount = tQuestInfo.nMaxFinishTimes
	local szQuestID = tQuestInfo.szQuestID
	local nBuffID = tQuestInfo.nBuffID

	if nBuffID == 0 and szQuestID == "" then
		return
	end

	if nBuffID ~= 0 then
		local buff = Player_GetBuff(nBuffID)
		if buff then
			nBuffFinish = buff.nStackNum
		end
	end

	if szQuestID ~= "" then
		local tQuestIDs = SplitString(szQuestID, ";")
		local nQuestState 	=  QUEST_PHASE.ERROR
		for _, szQuest in ipairs(tQuestIDs) do
			local pPlayer = GetClientPlayer()
			local dwQuestID = tonumber(szQuest)
			local nFinishedCount, nTotalCount = pPlayer.GetRandomDailyQuestFinishedCount(dwQuestID)
			if nFinishedCount == nTotalCount then
				nQuestFinish = nQuestFinish + 1
			end
		end
	end

	nFinishCount = math.max(nBuffFinish, nQuestFinish)
	return nFinishCount >= nMaxCount
end

function UIWidgetBattlePassQuest:UpdateQuestInfo()
    self.scriptQuestList = {}
    UIHelper.RemoveAllChildren(self.ScrollViewBattlePassTaskType)
    local tFiltedQuest, nMaxCount = HuaELouData.GetQuestList()

    for _, tQuests in pairs(tFiltedQuest) do
        for _, tInfo in pairs(tQuests) do
            tInfo.nSortIndex = 0
            if Storage.HuaELou.tQuestLikeMap[tInfo.dwID] and not self:IsQuestFinished(tInfo) then
                tInfo.nSortIndex = 1
            elseif Storage.HuaELou.tQuestLikeMap[tInfo.dwID] then
                tInfo.nSortIndex = 2
            elseif not self:IsQuestFinished(tInfo) then
                tInfo.nSortIndex = 3
            else
                tInfo.nSortIndex = 4
            end
        end
    end

    for _, tQuests in pairs(tFiltedQuest) do
        table.sort(tQuests,  function (a, b)
            if a.nSortIndex == b.nSortIndex then
                return a.dwID < b.dwID
            end
            return a.nSortIndex < b.nSortIndex
        end)
    end

    local nLevel = g_pClientPlayer.nLevel
    for _, tQuests in pairs(tFiltedQuest) do
        for _, tInfo in pairs(tQuests) do
            if nLevel <= tInfo.nHideLevel then
                local scriptQuest = UIHelper.AddPrefab(PREFAB_ID.WidgetBPTaskListCell, self.ScrollViewBattlePassTaskType, tInfo)
                if scriptQuest then
                    scriptQuest.tQuest = tInfo
                    scriptQuest:SetOnLikeCallBack(function ()
                        self:UpdateInfo()
                    end)
                    table.insert(self.scriptQuestList, scriptQuest)
                end
            end
        end
    end

    self:RefreshQuestInfo()
end

function UIWidgetBattlePassQuest:RefreshQuestInfo()
    for _, scriptQuest in ipairs(self.scriptQuestList) do
        local tQuest = scriptQuest.tQuest
        local bVisabel = self.szSelectedQuestType == tQuest.szModuleName
        bVisabel = bVisabel and HuaELouData.tCheckBoxClass[tQuest.nClass].bCheck

        UIHelper.SetVisible(scriptQuest._rootNode, bVisabel)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewBattlePassTaskType)
    UIHelper.ScrollToTop(self.ScrollViewBattlePassTaskType, 0)
end

return UIWidgetBattlePassQuest