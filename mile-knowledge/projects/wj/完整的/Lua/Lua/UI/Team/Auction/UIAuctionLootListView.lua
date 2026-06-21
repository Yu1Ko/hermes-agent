-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAuctionLootListView
-- Date: 2023-02-20 20:09:19
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIAuctionLootListView = class("UIAuctionLootListView")

local MIDDLE_TIPS_MODE = {
    NONE = 0,
    OPER = 1,
    ITEM = 2,
    DIST = 3,
}

function UIAuctionLootListView:IsNeedDoodad(tLootInfo)
    local tNeedConfig = Table_GetGoldTeamNeed(tLootInfo.dwItemTabType, tLootInfo.dwItemIndex)
    local bMatch = PlayerData.CheckMatchKungfus(tLootInfo.tKungfuMap)
    AuctionData.tBiddingRecordMap[tLootInfo.dwDoodadID] = AuctionData.tBiddingRecordMap[tLootInfo.dwDoodadID] or {}
    if AuctionData.tBiddingRecordMap[tLootInfo.dwDoodadID][tLootInfo.nItemLootIndex] ~= nil then
        return true
    elseif AuctionData.bFilterForce and bMatch then
        return true
    elseif tNeedConfig and self:CheckGoldTeamNeed(tNeedConfig)  then
        return true
    end
    return false
end

function UIAuctionLootListView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.scriptRollPoint = UIHelper.GetBindScript(self.WidgetContentRollPoint)
    self.scriptDistribute = UIHelper.GetBindScript(self.WidgetContentDistribute)
    self.scriptAuction = UIHelper.GetBindScript(self.WidgetContentAuction)
    self.scriptOnAuction = UIHelper.GetBindScript(self.WidgetContentAuctionOnGoing)
    self.scriptFreeLoot = UIHelper.GetBindScript(self.WidgetContentFreeLoot)
    if not self.WidgetDistributionRecord then
        local scriptWidget = UIHelper.AddPrefab(PREFAB_ID.WidgetDistributionRecord, self.WidgetAniLeft)
        self.WidgetDistributionRecord = scriptWidget._rootNode
    end

    UIHelper.SetVisible(self.WidgetDistributionRecord, false)
    UIHelper.SetVisible(self.WidgetZeroGoldItemList, false)
    UIHelper.SetSwallowTouches(self.BtnRightMask, true)
    UIHelper.SetTouchDownHideTips(self.BtnRightMask, false)
    self:OnFrameBreathe()
    Timer.AddFrameCycle(self, 5, function ()
        if self.scriptItemOnAuction then self.scriptItemOnAuction:OnUpdateTime() end
        self:OnUpdateTime()
    end)
end

function UIAuctionLootListView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIAuctionLootListView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCloseTip, EventType.OnClick, function ()
        self:ShowMiddleTips(MIDDLE_TIPS_MODE.NONE)
    end)

    UIHelper.BindUIEvent(self.BtnAllClose, EventType.OnClick, function ()
        UIMgr.Close(VIEW_ID.PanelTeamAuction)
        UIMgr.Close(VIEW_ID.PanelChatSocial)
    end)

    UIHelper.BindUIEvent(self.BtnCloseFilter, EventType.OnClick, function ()
        TipsHelper.DeleteAllHoverTips()
        self:ShowMiddleTips(MIDDLE_TIPS_MODE.NONE)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function ()
        self:ShowMiddleTips(MIDDLE_TIPS_MODE.NONE)
    end)

    UIHelper.BindUIEvent(self.BtnRecord, EventType.OnClick, function ()
        if OBDungeonData.IsPlayerInOBDungeon() then
            TipsHelper.ShowNormalTip("观战状态无法打开分配记录")
            return
        end

        if GetClientTeam().nLootMode ~= PARTY_LOOT_MODE.BIDDING then
            TipsHelper.ShowImportantYellowTip(g_tStrings.GOLD_TEAM_CAN_ONLY_OPEN_IN_BIDDING_MODE)
            return
        end
        UIMgr.Open(VIEW_ID.PanelAuctionRecord)
    end)

    UIHelper.SetVisible(self.BtnRefresh, false) -- 屏蔽中
    UIHelper.BindUIEvent(self.BtnRefresh, EventType.OnClick, function ()
        if not AuctionData.bIsDirty then return end
        self.bInitDoodadList = false
    end)

    UIHelper.BindUIEvent(self.BtnAuctionPreset, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelAuctionPresetPop)
    end)

    UIHelper.BindUIEvent(self.TogFilter, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogFilter, TipsLayoutDir.BOTTOM_LEFT, FilterDef.AuctionLootList)
    end)

    UIHelper.BindUIEvent(self.TogRollPoint, EventType.OnSelectChanged, function (_, bSelected)
        UIHelper.SetVisible(self.WidgetContentRollPoint, bSelected)
        self:ShowMiddleTips(MIDDLE_TIPS_MODE.NONE)
        if bSelected and AuctionData.nLastestLootMode ~= PARTY_LOOT_MODE.GROUP_LOOT and self.tNeedRollDoodads and #self.tNeedRollDoodads > 0 then
            local tDoodadInfo = self.tNeedRollDoodads[1]
            AuctionData.nLastestLootMode = tDoodadInfo.nLootMode
            AuctionData.nLastestDoodadID = tDoodadInfo.nDoodadID
            self.nLastLootIndex = nil
        end
    end)

    UIHelper.BindUIEvent(self.TogDistribute, EventType.OnSelectChanged, function (_, bSelected)
        UIHelper.SetVisible(self.WidgetContentDistribute, bSelected)
        self:ShowMiddleTips(MIDDLE_TIPS_MODE.NONE)
        if bSelected and AuctionData.nLastestLootMode ~= PARTY_LOOT_MODE.DISTRIBUTE and self.tNeedDistributeDoodads and #self.tNeedDistributeDoodads > 0 then
            local tDoodadInfo = self.tNeedDistributeDoodads[1]
            AuctionData.nLastestLootMode = tDoodadInfo.nLootMode
            AuctionData.nLastestDoodadID = tDoodadInfo.nDoodadID
            self.nLastLootIndex = nil
        end
    end)

    UIHelper.BindUIEvent(self.TogFreeLoot, EventType.OnSelectChanged, function (_, bSelected)
        UIHelper.SetVisible(self.WidgetContentFreeLoot, bSelected)
        self:ShowMiddleTips(MIDDLE_TIPS_MODE.NONE)
        if bSelected and AuctionData.nLastestLootMode ~= PARTY_LOOT_MODE.FREE_FOR_ALL and self.tCanFreeLootDoodads and #self.tCanFreeLootDoodads > 0 then
            local tDoodadInfo = self.tCanFreeLootDoodads[1]
            AuctionData.nLastestLootMode = tDoodadInfo.nLootMode
            AuctionData.nLastestDoodadID = tDoodadInfo.nDoodadID
            self.nLastLootIndex = nil
        end
    end)

    UIHelper.BindUIEvent(self.TogAuction, EventType.OnSelectChanged, function (_, bSelected)
        UIHelper.SetVisible(self.WidgetContentAuction, false)
        UIHelper.SetVisible(self.WidgetContentAuctionOnGoing, bSelected)
        self:ShowMiddleTips(MIDDLE_TIPS_MODE.NONE)
        if bSelected and AuctionData.nLastestLootMode ~= PARTY_LOOT_MODE.BIDDING and self.tNeedAuctionDoodads and #self.tNeedAuctionDoodads > 0 then
            local tDoodadInfo = self.tNeedAuctionDoodads[1]
            AuctionData.nLastestLootMode = tDoodadInfo.nLootMode
            AuctionData.nLastestDoodadID = tDoodadInfo.nDoodadID
            self.nLastLootIndex = nil
        end
    end)
end

function UIAuctionLootListView:RegEvent()
    -- Event.Reg(self, "BAG_ITEM_UPDATE", function ()
    --     AuctionData.SetDirty(true)
    -- end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        Timer.AddFrame(self, 1, function ()
            if self.bFarPoint then
                local nPosX = UIHelper.GetWorldPositionX(self.WidgetItemTipsFarPoint)
                local nPosY = UIHelper.GetWorldPositionY(self.WidgetItemTipsFarPoint)
                UIHelper.SetWorldPosition(self.WidgetItemTipsShell, nPosX, nPosY)
            else
                local nPosX = UIHelper.GetWorldPositionX(self.WidgetItemTipsNearPoint)
                local nPosY = UIHelper.GetWorldPositionY(self.WidgetItemTipsNearPoint)
                UIHelper.SetWorldPosition(self.WidgetItemTipsShell, nPosX, nPosY)
            end
        end)
    end)

    Event.Reg(self, EventType.OnViewOpen, function (nViewID)
        if nViewID == VIEW_ID.PanelHoverTips then
            if self.scriptItemtip then UIHelper.SetVisible(self.scriptItemtip._rootNode, false) end
        end
    end)

    Event.Reg(self, EventType.OnViewClose, function ()
        Timer.AddFrame(self, 1, function ()
            if self.bFarPoint then
                local nPosX = UIHelper.GetWorldPositionX(self.WidgetItemTipsFarPoint)
                local nPosY = UIHelper.GetWorldPositionY(self.WidgetItemTipsFarPoint)
                UIHelper.SetWorldPosition(self.WidgetItemTipsShell, nPosX, nPosY)
            else
                local nPosX = UIHelper.GetWorldPositionX(self.WidgetItemTipsNearPoint)
                local nPosY = UIHelper.GetWorldPositionY(self.WidgetItemTipsNearPoint)
                UIHelper.SetWorldPosition(self.WidgetItemTipsShell, nPosX, nPosY)
            end
        end)
    end)

    Event.Reg(self, EventType.OnLootInfoChanged, function (tNewLootInfo)
        if (self.tOnAuctionLootInfo and self.tOnAuctionLootInfo.dwDoodadID == tNewLootInfo.dwDoodadID and self.tOnAuctionLootInfo.nItemLootIndex == tNewLootInfo.nItemLootIndex)
             or tNewLootInfo.eState == AuctionState.CountDown then
            self:TryUpdateOnAuctionItem(tNewLootInfo)
        end
        if self.dwCurItemID and self.dwCurItemID > 0 and tNewLootInfo.dwItemID == self.dwCurItemID then
            self:RefreshItemTipButtons(tNewLootInfo, self.dwCurItemIsNeedList)
        end
    end)

    Event.Reg(self, EventType.OnAuctionLootListRedPointChanged, function ()
        self:UpdateContentSubTitleRedPoint()
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tSelected)
        if szKey ~= FilterDef.AuctionLootList.Key then
            return
        end

        AuctionData.ApplyFilter(tSelected[1], tSelected[2])
    end)
end

function UIAuctionLootListView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIAuctionLootListView:OnFrameBreathe()
    local clientTeam = GetClientTeam()
    if clientTeam then
        UIHelper.SetString(self.LabelMode, g_tStrings.Auction.MODE_NAME[clientTeam.nLootMode])
    end

    self:UpdateDoodadInfo()

    Timer.AddFrame(self, 5, function ()
        self:OnFrameBreathe()
    end)
end

function UIAuctionLootListView:OnUpdateTime()
    local nTopPosY = UIHelper.GetWorldPositionY(self.WidgetRedPointArrowTop)
    local nBottomPosY = UIHelper.GetWorldPositionY(self.WidgetRedPointArrowBottom)
    local bShowTop, bShowBottom
    for _, scriptItem in ipairs(self.tCurItemScript or {}) do
        scriptItem:OnUpdateTime()
        if scriptItem.bHasRedPoint and UIHelper.GetVisible(scriptItem._rootNode) then
            local nMaxPosY = UIHelper.GetWorldPositionY(scriptItem._rootNode)
            local nMinPosY = nMaxPosY - UIHelper.GetHeight(scriptItem._rootNode)
            bShowTop = bShowTop or nMinPosY >= nTopPosY
            bShowBottom = bShowBottom or nMaxPosY <= nBottomPosY
        end
    end

    local scriptAuction = self.scriptOnAuction
    if scriptAuction then
        local scriptCurContainer = scriptAuction.scriptCurContainer
        local scriptTopContainer = scriptAuction.scriptTopContainer
        if scriptCurContainer and scriptTopContainer then
            local bRedPoint = false
            if scriptCurContainer.dwDoodadID then   
                bRedPoint = RedpointHelper.AuctionLootList_HasRedPoint(scriptCurContainer.dwDoodadID)
            else
                bRedPoint = RedpointHelper.AuctionLootList_HasRedPointWithoutNoPromot()
            end
            UIHelper.SetVisible(scriptTopContainer.ImgRedPoint, bRedPoint)
        end
        for _, tContainer in ipairs(scriptAuction.tContainerList) do
            local scriptContainer = tContainer.scriptContainer
            if scriptContainer.bHasRedPoint then
                local nMaxPosY = UIHelper.GetWorldPositionY(scriptContainer._rootNode)
                local nMinPosY = nMaxPosY - UIHelper.GetHeight(scriptContainer._rootNode)
                bShowTop = bShowTop or nMinPosY >= nTopPosY
                bShowBottom = bShowBottom or nMaxPosY <= nBottomPosY
            end
        end
    end

    UIHelper.SetVisible(self.WidgetRedPointArrowTop, bShowTop)
    UIHelper.SetVisible(self.WidgetRedPointArrowBottom, bShowBottom)
end

function UIAuctionLootListView:UpdateDoodadInfo()
    if self.bInitDoodadList and not AuctionData.bNeedRefresh then
        return
    end
    self.bInitDoodadList = true
    self:ShowMiddleTips(MIDDLE_TIPS_MODE.NONE)

    local clientTeam = GetClientTeam()
    local dwDistributerID = clientTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE)
    local bDistributer = dwDistributerID == UI_GetClientPlayerID()
    UIHelper.SetVisible(self.BtnAuctionPreset, bDistributer)

    local tSortedPickedDoodads = AuctionData.SortedPickedDoodads() or {}
    local bNoAnyDoodad = table.GetCount(tSortedPickedDoodads) == 0
    if bNoAnyDoodad and not AuctionData.NeedResidentLootList() then
        if self.scriptItemtip then UIHelper.SetVisible(self.scriptItemtip._rootNode, false) end
        UIMgr.Close(VIEW_ID.PanelTeamAuction)
        UIMgr.Close(VIEW_ID.PanelChatSocial)
    end
    UIHelper.SetVisible(self.WidgetEmpty, bNoAnyDoodad)

    if self.scriptItemtip then
        self.bItemTipVisibleBeforeRefresh = UIHelper.GetVisible(self.WidgetItemTipsShell)
    end

    local tNeedRollDoodads = {}
    local tNeedDistributeDoodads = {}
    local tNeedAuctionDoodads = {}
    local tCanFreeLootDoodads = {}
    local MAX_DOODAD_LIMIT = 15
    for _, tDoodadInfo in pairs(tSortedPickedDoodads) do
        local nCount = #tDoodadInfo.tLootItemInfoList
        if nCount > 0 then
            if tDoodadInfo.nLootMode == PARTY_LOOT_MODE.GROUP_LOOT then
                if #tNeedRollDoodads < MAX_DOODAD_LIMIT then table.insert(tNeedRollDoodads, tDoodadInfo) end
            elseif tDoodadInfo.nLootMode == PARTY_LOOT_MODE.DISTRIBUTE then
                if #tNeedDistributeDoodads < MAX_DOODAD_LIMIT then table.insert(tNeedDistributeDoodads, tDoodadInfo) end
            elseif tDoodadInfo.nLootMode == PARTY_LOOT_MODE.BIDDING then
                if #tNeedAuctionDoodads < MAX_DOODAD_LIMIT then table.insert(tNeedAuctionDoodads, tDoodadInfo) end
            else
                if #tCanFreeLootDoodads < MAX_DOODAD_LIMIT then table.insert(tCanFreeLootDoodads, tDoodadInfo) end
            end
        end
    end
    local fCmpTime = function (tDoodad1, tDoodad2)
        local nSortIndex1 = AuctionData.tPickDooodadSortIndex[tDoodad1.nDoodadID] or 0
        local nSortIndex2 = AuctionData.tPickDooodadSortIndex[tDoodad2.nDoodadID] or 0
        return nSortIndex1 < nSortIndex2
    end

    table.sort(tNeedRollDoodads, fCmpTime)
    table.sort(tNeedDistributeDoodads, fCmpTime)
    table.sort(tNeedAuctionDoodads, fCmpTime)
    table.sort(tCanFreeLootDoodads, fCmpTime)

    self:UpdateRollPointInfo(tNeedRollDoodads)
    self:UpdateDistributeInfo(tNeedDistributeDoodads)
    self:UpdateAuctionInfo(tNeedAuctionDoodads)
    self:UpdateFreeLootInfo(tCanFreeLootDoodads)

    self.tNeedRollDoodads = tNeedRollDoodads
    self.tNeedDistributeDoodads = tNeedDistributeDoodads
    self.tNeedAuctionDoodads = tNeedAuctionDoodads
    self.tCanFreeLootDoodads = tCanFreeLootDoodads

    local nKind = 0
    local bHasRollPoint = #tNeedRollDoodads > 0
    local bHasDistribute = #tNeedDistributeDoodads > 0
    local bHasAuction = #tNeedAuctionDoodads > 0
    local bHasFreeLoot = #tCanFreeLootDoodads > 0
    if bHasRollPoint then nKind = nKind + 1 end
    if bHasDistribute then nKind = nKind + 1 end
    if bHasAuction then nKind = nKind + 1 end
    if bHasFreeLoot then nKind = nKind + 1 end
    local bMultMode = nKind > 1

    local bRollPoint = UIHelper.GetSelected(self.TogRollPoint)
    local bDistribute = UIHelper.GetSelected(self.TogDistribute)
    local bFreeLoot = UIHelper.GetSelected(self.TogFreeLoot)
    local bAuction = UIHelper.GetSelected(self.TogAuction)

    UIHelper.SetVisible(self.WidgetTogRollPoint, bHasRollPoint)
    UIHelper.SetVisible(self.WidgetTogDistribute, bHasDistribute)
    UIHelper.SetVisible(self.WidgetTogFreeLoot, bHasFreeLoot)
    UIHelper.SetVisible(self.WidgetTogAuction, bHasAuction)

    UIHelper.SetVisible(self.WidgetContentRollPoint, (bRollPoint and bHasRollPoint) or not bMultMode)
    UIHelper.SetVisible(self.WidgetContentDistribute, (bDistribute and bHasDistribute) or not bMultMode)
    UIHelper.SetVisible(self.WidgetContentFreeLoot, (bFreeLoot and bHasFreeLoot) or not bMultMode)
    UIHelper.SetVisible(self.WidgetContentAuction, false)
    UIHelper.SetVisible(self.WidgetContentAuctionOnGoing, (bAuction or not bMultMode) and bHasAuction)

    UIHelper.LayoutDoLayout(self.LayoutTypeContent)
    UIHelper.LayoutDoLayout(self.LayoutTogGroup)

    if AuctionData.nLastestLootMode then
        if bHasRollPoint and AuctionData.nLastestLootMode == PARTY_LOOT_MODE.GROUP_LOOT then
            UIHelper.SetSelected(self.TogRollPoint, true, true)
        elseif bHasDistribute and AuctionData.nLastestLootMode == PARTY_LOOT_MODE.DISTRIBUTE then
            UIHelper.SetSelected(self.TogDistribute, true, true)
        elseif bHasAuction and AuctionData.nLastestLootMode == PARTY_LOOT_MODE.BIDDING then
            UIHelper.SetSelected(self.TogAuction, true, true)
        elseif bHasFreeLoot and AuctionData.nLastestLootMode == PARTY_LOOT_MODE.FREE_FOR_ALL then
            UIHelper.SetSelected(self.TogFreeLoot, true, true)
        else
            AuctionData.nLastestLootMode = nil
            AuctionData.nLastestDoodadID = nil
        end
    end
    if not AuctionData.nLastestLootMode then
        if not bMultMode then
            UIHelper.SetSelected(self.TogRollPoint, bHasRollPoint, true)
            UIHelper.SetSelected(self.TogDistribute, bHasDistribute, true)
            UIHelper.SetSelected(self.TogAuction, bHasAuction, true)
            UIHelper.SetSelected(self.TogFreeLoot, bHasFreeLoot, true)
        elseif bHasRollPoint then
            UIHelper.SetSelected(self.TogRollPoint, true, true)
        elseif bHasDistribute then
            UIHelper.SetSelected(self.TogDistribute, true, true)
        elseif bHasFreeLoot then
            UIHelper.SetSelected(self.TogFreeLoot, true, true)
        elseif bHasAuction then
            UIHelper.SetSelected(self.TogAuction, true, true)
        end
    end

    AuctionData.bIsDirty = false
    AuctionData.SetNeedRefresh(false)
end

function UIAuctionLootListView:UpdateRollPointInfo(tSortedPickedDoodads)
    UIHelper.SetVisible(self.scriptRollPoint.ScrollViewContent, #tSortedPickedDoodads > 0)
    self.tCurRollLootInfo = nil
    self.scriptRollPoint:ClearContainer()
    self.scriptRollPoint:OnInit(PREFAB_ID.WidgetContentSubTitle, function (scriptContainer, tDoodadInfo) -- 初始化标题
        local szDoodadName = AuctionData.GetDropItemSourceName(tDoodadInfo, "待分配物品")
        UIHelper.SetString(scriptContainer.LabelTitleDown, szDoodadName)
        UIHelper.SetString(scriptContainer.LabelTitleUp, szDoodadName)

        local scriptRollPoint = UIHelper.GetBindScript(scriptContainer.WidgetRollPoint)
        if scriptRollPoint and not scriptRollPoint.fNeedAll then
            scriptRollPoint:SetNeedAllCallBack(function ()
                self:OnClickNeedAllButton(scriptRollPoint, tDoodadInfo.nDoodadID)
            end)

            scriptRollPoint:SetCancelAllCallBack(function ()
                self:OnClickCancelAllButton(scriptRollPoint, tDoodadInfo.nDoodadID)
            end)

            scriptRollPoint:SetNeedAllEnableFunc(function ()
                return self:QuickNeedAllButtonEnable(tDoodadInfo.nDoodadID)
            end)

            scriptRollPoint:SetCancelAllEnableFunc(function ()
                return self:QuickCancelAllButtonEnable(tDoodadInfo.nDoodadID)
            end)
        end
    end)

    local nDefaultSelectedIndex = 1
    for nIndex, tDoodadInfo in ipairs(tSortedPickedDoodads) do
        if tDoodadInfo.nDoodadID == AuctionData.nLastestDoodadID then
            nDefaultSelectedIndex = nIndex
        end
        local tDropItemInfoList = {}
        for nLootIndex, tLootInfo in ipairs(tDoodadInfo.tLootItemInfoList) do
            local tDropItemInfo = {
                nPrefabID = PREFAB_ID.WidgetRollPointItem,
                tArgs = {
                    tLootInfo = tLootInfo,
                    fCallBack = function (bInit, tNewLootInfo)
                        tLootInfo = tNewLootInfo or tLootInfo
                        self.nLastLootIndex = nLootIndex
                        self.dwCurItemID = tLootInfo.dwItemID
                        self.dwCurItemIsNeedList = false
                        self:RefreshItemTipButtons(tLootInfo)

                        if bInit then self:RefreshItemScriptList(self.scriptRollPoint) end
                        if not tLootInfo.bHasDistributed and tLootInfo.bCanFreeLoot and not bInit then
                            if tLootInfo.dwItemID == 0 then
                                LootMoney(tLootInfo.dwDoodadID)
                            else
                                LootItem(tLootInfo.dwDoodadID, tLootInfo.dwItemID)
                            end
                        end
                    end
                }
            }
            table.insert(tDropItemInfoList, tDropItemInfo)
        end
        self.scriptRollPoint:AddContainer(tDoodadInfo, tDropItemInfoList, function (bSelected, scriptContainer) -- 标题选中事件
            self.tCurItemScript = scriptContainer.tItemScripts
            UIHelper.SetVisible(scriptContainer.WidgetRollPoint, bSelected)
            UIHelper.LayoutDoLayout(scriptContainer._rootNode)
            UIHelper.ScrollViewDoLayoutAndToTop(self.scriptRollPoint.ScrollViewContent)
        end,function () -- 标题点击事件
            AuctionData.nLastestLootMode = tDoodadInfo.nLootMode
            AuctionData.nLastestDoodadID = tDoodadInfo.nDoodadID
        end, Platform.IsIos())
        tDoodadInfo.nScriptIndex = #self.scriptRollPoint.tContainerList
    end
    self.scriptRollPoint:UpdateInfo()

    if #self.scriptRollPoint.tContainerList > 0 then
        Timer.AddFrame(self, 2, function ()
            local scriptContainer = self.scriptRollPoint.tContainerList[nDefaultSelectedIndex].scriptContainer
            scriptContainer:SetSelected(true)

            if UIHelper.GetSelected(self.TogRollPoint) then
                local nDefaultLootIndex = self.nLastLootIndex or 1
                if nDefaultLootIndex > #scriptContainer.tItemScripts then nDefaultLootIndex = #scriptContainer.tItemScripts end
                local scriptCell = scriptContainer.tItemScripts[nDefaultLootIndex]
                if AuctionData.bChoosedOnAuction and self.bRealHasAuction then scriptCell = UIHelper.GetBindScript(self.WidgetItemOnAuction) or scriptCell end
                UIHelper.SetSelected(scriptCell.ToggleSelect, true, false)
                scriptCell.fCallBack(true)
            end
        end)
    end
end

function UIAuctionLootListView:UpdateDistributeInfo(tSortedPickedDoodads)
    local clientTeam = GetClientTeam()
    UIHelper.SetVisible(self.scriptDistribute.ScrollViewContent, #tSortedPickedDoodads > 0)
    self.tCurDistributeLootInfo = nil
    self.scriptDistribute:ClearContainer()
    self.scriptDistribute:OnInit(PREFAB_ID.WidgetContentSubTitle, function (scriptContainer, tDoodadInfo) -- 初始化标题
        local szDoodadName = AuctionData.GetDropItemSourceName(tDoodadInfo, "待分配物品")
        UIHelper.SetString(scriptContainer.LabelTitleDown, szDoodadName)
        UIHelper.SetString(scriptContainer.LabelTitleUp, szDoodadName)
    end)

    local nDefaultSelectedIndex = 1
    for nIndex, tDoodadInfo in ipairs(tSortedPickedDoodads) do
        if tDoodadInfo.nDoodadID == AuctionData.nLastestDoodadID then
            nDefaultSelectedIndex = nIndex
        end
        local tDropItemInfoList = {}
        for nLootIndex, tLootInfo in ipairs(tDoodadInfo.tLootItemInfoList) do
            local tDropItemInfo = {
                nPrefabID = PREFAB_ID.WidgetRollPointItem,
                tArgs = {
                    tLootInfo = tLootInfo,
                    fCallBack = function (bInit, tNewLootInfo)
                        tLootInfo = tNewLootInfo or tLootInfo
                        self.nLastLootIndex = nLootIndex
                        self.dwCurItemID = tLootInfo.dwItemID
                        self:RefreshItemTipButtons(tLootInfo)

                        if bInit then self:RefreshItemScriptList(self.scriptDistribute) end
                        if not tLootInfo.bHasDistributed and tLootInfo.bCanFreeLoot and not bInit then
                            if tLootInfo.dwItemID == 0 then
                                LootMoney(tLootInfo.dwDoodadID)
                            else
                                LootItem(tLootInfo.dwDoodadID, tLootInfo.dwItemID)
                            end
                        end
                    end
                }
            }
            table.insert(tDropItemInfoList, tDropItemInfo)
        end
        self.scriptDistribute:AddContainer(tDoodadInfo, tDropItemInfoList, function (bSelected, scriptContainer) -- 标题选中事件

        end,function () -- 标题点击事件
            AuctionData.nLastestLootMode = tDoodadInfo.nLootMode
            AuctionData.nLastestDoodadID = tDoodadInfo.nDoodadID
        end, Platform.IsIos())
        tDoodadInfo.nScriptIndex = #self.scriptDistribute.tContainerList
    end
    self.scriptDistribute:UpdateInfo()

    if #self.scriptDistribute.tContainerList > 0 then
        Timer.AddFrame(self, 2, function ()
            local scriptContainer = self.scriptDistribute.tContainerList[nDefaultSelectedIndex].scriptContainer
            scriptContainer:SetSelected(true)
            if UIHelper.GetSelected(self.TogDistribute) then
                local nDefaultLootIndex = self.nLastLootIndex or 1
                if nDefaultLootIndex > #scriptContainer.tItemScripts then nDefaultLootIndex = #scriptContainer.tItemScripts end
                local scriptCell = scriptContainer.tItemScripts[nDefaultLootIndex]
                if AuctionData.bChoosedOnAuction and self.bRealHasAuction then scriptCell = UIHelper.GetBindScript(self.WidgetItemOnAuction) or scriptCell end
                UIHelper.SetSelected(scriptCell.ToggleSelect, true, false)
                scriptCell.fCallBack(true)
            end
        end)
    end
end

function UIAuctionLootListView:GetLootSortWeight(tLootInfo)
    local nVal = 0
    if AuctionData.tBiddingRecordMap[tLootInfo.dwDoodadID][tLootInfo.nItemLootIndex] ~= nil then
        nVal = nVal + 100
    end

    if Table_GetGoldTeamNeed(tLootInfo.dwItemTabType, tLootInfo.dwItemIndex) then
        nVal = nVal + 10
    end

    if AuctionData.bFilterForce and PlayerData.CheckMatchKungfus(tLootInfo.tKungfuMap) then
        nVal = nVal + 1
    end

    return nVal
end

function UIAuctionLootListView:UpdateAuctionInfo(tSortedPickedDoodads)
    local scriptAuction = self.scriptOnAuction -- self.scriptAuction
    local bOnAuction = false
    local bHasAuction = #tSortedPickedDoodads > 0
    local tCurLootInfo = nil
    local tCurDoodadInfo = nil
    self.bRealHasAuction = false

    local tAuctionFakeDoodadInfo = {
        nLootMode = PARTY_LOOT_MODE.BIDDING,
        szDoodadName = "我需要的",
        tLootItemInfoList = {},
    }
    for _, tDoodadInfo in ipairs(tSortedPickedDoodads) do
        for _, tLootInfo in ipairs(tDoodadInfo.tLootItemInfoList) do
            if tLootInfo.eState == AuctionState.CountDown or tLootInfo.eState == AuctionState.CountFinished then
                self:TryUpdateOnAuctionItem(tLootInfo)
            end
            if self:IsNeedDoodad(tLootInfo) and not CheckIsInTable(Storage.Auction.tNoPromotDoodadList, {tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex}) then
                table.insert(tAuctionFakeDoodadInfo.tLootItemInfoList, tLootInfo)
            end
        end
    end
    table.sort(tAuctionFakeDoodadInfo.tLootItemInfoList, function (tLootInfo1, tLootInfo2)
        local nTime1 = AuctionData.tBiddingTimeMap[tLootInfo1.dwDoodadID] and 
                        AuctionData.tBiddingTimeMap[tLootInfo1.dwDoodadID][tLootInfo1.nItemLootIndex] or 0
        local nTime2 = AuctionData.tBiddingTimeMap[tLootInfo2.dwDoodadID] and 
                        AuctionData.tBiddingTimeMap[tLootInfo2.dwDoodadID][tLootInfo2.nItemLootIndex] or 0
        
        if nTime1 == nTime2 then
            local nVal1, nVal2 = self:GetLootSortWeight(tLootInfo1), self:GetLootSortWeight(tLootInfo2)
            return nVal1 > nVal2
        end
        
        return nTime1 > nTime2
    end)
    tAuctionFakeDoodadInfo.bIsNeedList = true
    if #tAuctionFakeDoodadInfo.tLootItemInfoList > 0 then table.insert(tSortedPickedDoodads, 1, tAuctionFakeDoodadInfo) end

    if not self.bRealHasAuction then self:TryUpdateOnAuctionItem(nil) end

    UIHelper.SetVisible(self.WidgetContentAuction, false)
    UIHelper.SetVisible(self.WidgetContentAuctionOnGoing, bHasAuction)
    UIHelper.SetVisible(self.scriptAuction.ScrollViewContent, bHasAuction)
    UIHelper.SetVisible(self.scriptOnAuction.ScrollViewContent, bHasAuction)    

    if not scriptAuction then return end
    scriptAuction:ClearContainer()
    scriptAuction:OnInit(PREFAB_ID.WidgetContentSubTitle, function (scriptContainer, tDoodadInfo) -- 初始化标题
        local szDoodadName = AuctionData.GetDropItemSourceName(tDoodadInfo, "待分配物品")
        UIHelper.SetString(scriptContainer.LabelTitleDown, szDoodadName)
        UIHelper.SetString(scriptContainer.LabelTitleUp, szDoodadName)

        scriptContainer.dwDoodadID = tDoodadInfo.nDoodadID
        local scriptDistribute = UIHelper.GetBindScript(scriptContainer.WidgetDistribute)
        if scriptDistribute and not scriptDistribute.fDistribute then
            scriptDistribute:SetDistributeCallBack(function ()
                self:OnClickQuickDistributeButton(scriptDistribute, tDoodadInfo.nDoodadID)
            end)

            scriptDistribute:SetStartAuctionCallBack(function ()
                self:OnClickQuickAuctionButton(scriptDistribute, tDoodadInfo.nDoodadID)
            end)

            scriptDistribute:SetStartAuctionEnableFunc(function ()
                return self:QuickAuctionButtonEnable(tDoodadInfo.nDoodadID)
            end)
        end

        local scriptNeed = UIHelper.GetBindScript(scriptContainer.WidgetNeed)
        if scriptNeed and not scriptNeed.fOnFilter then
            scriptNeed:SetOnFilterCallBack(function (bSelected)
                self:OnClickQuickFilterButton(scriptNeed, bSelected)
            end)
        end

        if tDoodadInfo.nDoodadID == nil and scriptDistribute then
            UIHelper.SetSelected(scriptNeed.TogShow, AuctionData.bFilterForce == true, false)
            UIHelper.SetVisible(scriptContainer.WidgetNeeded, true)
            UIHelper.SetVisible(UIHelper.GetParent(scriptDistribute.BtnStartAuction), false)
            self:UpdateTopContentBackground(scriptContainer, tDoodadInfo.nDoodadID == nil)
        end
    end)

    local nDefaultSelectedIndex = 1
    for nIndex, tDoodadInfo in ipairs(tSortedPickedDoodads) do
        if tDoodadInfo.nDoodadID == AuctionData.nLastestDoodadID then
            nDefaultSelectedIndex = nIndex
        end
        local tDropItemInfoList = {}
        for nLootIndex, tLootInfo in ipairs(tDoodadInfo.tLootItemInfoList) do
            local bIsNeedList = tDoodadInfo.bIsNeedList
            local tDropItemInfo = {
                nPrefabID = PREFAB_ID.WidgetRollPointItem,
                tArgs = {
                    tLootInfo = tLootInfo,
                    fCallBack = function (bInit, tNewLootInfo)
                        tLootInfo = tNewLootInfo or tLootInfo                        
                        self.nLastLootIndex = nLootIndex
                        self.dwCurItemID = tLootInfo.dwItemID
                        self.dwCurItemIsNeedList = bIsNeedList
                        self:RefreshItemTipButtons(tLootInfo, bIsNeedList)

                        if bInit then self:RefreshItemScriptList(self.scriptAuction) end
                        if not tLootInfo.bHasDistributed and tLootInfo.bCanFreeLoot and not bInit then
                            if tLootInfo.dwItemID == 0 then
                                LootMoney(tLootInfo.dwDoodadID)
                            else
                                LootItem(tLootInfo.dwDoodadID, tLootInfo.dwItemID)
                            end
                        end
                        if not bInit then
                            RedpointHelper.AuctionLootList_Clear(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
                        end
                    end
                }
            }
            table.insert(tDropItemInfoList, tDropItemInfo)
        end
        scriptAuction:AddContainer(tDoodadInfo, tDropItemInfoList, function (bSelected, scriptContainer) -- 标题选中事件
            self.tCurItemScript = scriptContainer.tItemScripts
            UIHelper.SetVisible(scriptContainer.WidgetDistribute, bSelected and AuctionData.IsDistributeMan())
            UIHelper.SetVisible(scriptContainer.WidgetNeed, bSelected and tDoodadInfo.nDoodadID == nil)
            UIHelper.LayoutDoLayout(scriptContainer._rootNode)
            UIHelper.ScrollViewDoLayoutAndToTop(scriptAuction.ScrollViewContent)
            local scriptTopContainer = scriptAuction.scriptTopContainer
            self:UpdateTopContentBackground(scriptTopContainer, tDoodadInfo.nDoodadID == nil)
        end,function () -- 标题点击事件
            AuctionData.nLastestLootMode = tDoodadInfo.nLootMode
            AuctionData.nLastestDoodadID = tDoodadInfo.nDoodadID
        end, Platform.IsIos())
        tDoodadInfo.nScriptIndex = #scriptAuction.tContainerList
    end

    scriptAuction:UpdateInfo()
    if #scriptAuction.tContainerList > 0 then
        Timer.AddFrame(self, 2, function ()
            local scriptContainer = scriptAuction.tContainerList[nDefaultSelectedIndex].scriptContainer
            scriptContainer:SetSelected(true)
            if UIHelper.GetSelected(self.TogAuction) then
                local nDefaultLootIndex = self.nLastLootIndex or 1
                if nDefaultLootIndex > #scriptContainer.tItemScripts then nDefaultLootIndex = #scriptContainer.tItemScripts end
                local scriptCell = scriptContainer.tItemScripts[nDefaultLootIndex]
                if AuctionData.bChoosedOnAuction and self.bRealHasAuction then scriptCell = UIHelper.GetBindScript(self.WidgetItemOnAuction) or scriptCell end
                UIHelper.SetSelected(scriptCell.ToggleSelect, true, false)
                scriptCell.fCallBack(true)
            end
        end)
        self:UpdateContentSubTitleRedPoint()
    end
end

function UIAuctionLootListView:UpdateFreeLootInfo(tSortedPickedDoodads)
    local clientTeam = GetClientTeam()
    UIHelper.SetVisible(self.scriptFreeLoot.ScrollViewContent, #tSortedPickedDoodads > 0)
    self.tCurDistributeLootInfo = nil
    self.scriptFreeLoot:ClearContainer()
    self.scriptFreeLoot:OnInit(PREFAB_ID.WidgetContentSubTitle, function (scriptContainer, tDoodadInfo) -- 初始化标题
        local szDoodadName = AuctionData.GetDropItemSourceName(tDoodadInfo, "待分配物品")
        UIHelper.SetString(scriptContainer.LabelTitleDown, szDoodadName)
        UIHelper.SetString(scriptContainer.LabelTitleUp, szDoodadName)
    end)

    local nDefaultSelectedIndex = 1
    for nIndex, tDoodadInfo in ipairs(tSortedPickedDoodads) do
        if tDoodadInfo.nDoodadID == AuctionData.nLastestDoodadID then
            nDefaultSelectedIndex = nIndex
        end
        local tDropItemInfoList = {}
        for nLootIndex, tLootInfo in ipairs(tDoodadInfo.tLootItemInfoList) do
            local tDropItemInfo = {
                nPrefabID = PREFAB_ID.WidgetRollPointItem,
                tArgs = {
                    tLootInfo = tLootInfo,
                    fCallBack = function (bInit, tNewLootInfo)
                        tLootInfo = tNewLootInfo or tLootInfo
                        self.nLastLootIndex = nLootIndex
                        self.dwCurItemID = tLootInfo.dwItemID
                        self.dwCurItemIsNeedList = false
                        self:RefreshItemTipButtons(tLootInfo)
                        if bInit then self:RefreshItemScriptList(self.scriptFreeLoot) end
                        if not tLootInfo.bHasDistributed and tLootInfo.bCanFreeLoot and not bInit then
                            if tLootInfo.dwItemID == 0 then
                                LootMoney(tLootInfo.dwDoodadID)
                            else
                                if g_pClientPlayer.GetFreeRoomSize() <= 0 then
                                    TipsHelper.ShowNormalTip("背包已满")
                                    return
                                end
                                LootItem(tLootInfo.dwDoodadID, tLootInfo.dwItemID)
                            end
                        end
                    end
                }
            }
            table.insert(tDropItemInfoList, tDropItemInfo)
        end
        self.scriptFreeLoot:AddContainer(tDoodadInfo, tDropItemInfoList, function (bSelected, scriptContainer) -- 标题选中事件

        end,function () -- 标题点击事件
            AuctionData.nLastestLootMode = tDoodadInfo.nLootMode
            AuctionData.nLastestDoodadID = tDoodadInfo.nDoodadID
        end, Platform.IsIos())
        tDoodadInfo.nScriptIndex = #self.scriptFreeLoot.tContainerList
    end
    self.scriptFreeLoot:UpdateInfo()

    if #self.scriptFreeLoot.tContainerList > 0 then
        Timer.AddFrame(self, 2, function ()
            local scriptContainer = self.scriptFreeLoot.tContainerList[nDefaultSelectedIndex].scriptContainer
            scriptContainer:SetSelected(true)
            if UIHelper.GetSelected(self.TogFreeLoot) then
                local nDefaultLootIndex = self.nLastLootIndex or 1
                if nDefaultLootIndex > #scriptContainer.tItemScripts then nDefaultLootIndex = #scriptContainer.tItemScripts end
                local scriptCell = scriptContainer.tItemScripts[nDefaultLootIndex]
                if AuctionData.bChoosedOnAuction and self.bRealHasAuction then scriptCell = UIHelper.GetBindScript(self.WidgetItemOnAuction) or scriptCell end
                UIHelper.SetSelected(scriptCell.ToggleSelect, true, false)
                scriptCell.fCallBack(true)
            end
        end)
    end
end

function UIAuctionLootListView:RefreshItemScriptList(scriptScrollViewTree)
    if not scriptScrollViewTree.scriptCurContainer then return end
    for _, scriptItem in ipairs(scriptScrollViewTree.scriptCurContainer.tItemScripts) do
        UIHelper.SetSelected(scriptItem.ToggleSelect, self.dwCurItemID == scriptItem.tLootInfo.dwItemID, false)
    end
end

function UIAuctionLootListView:UpdateContentSubTitleRedPoint()
    local scriptAuction = self.scriptOnAuction
    if not scriptAuction then return end
    
    for _, tContainer in ipairs(scriptAuction.tContainerList) do
        local scriptContainer = tContainer.scriptContainer
        if scriptContainer.dwDoodadID == nil then -- 只有已出价物品栏才显示红点
            local bRedPoint = RedpointHelper.AuctionLootList_HasRedPointWithoutNoPromot()
            scriptContainer.bHasRedPoint = bRedPoint
            UIHelper.SetVisible(scriptContainer.ImgRedPoint, bRedPoint)
        end
    end
end

function UIAuctionLootListView:UpdateTopContentBackground(scriptContainer, bGold)
    if bGold then
        UIHelper.SetTextColor(scriptContainer.LabelTitleDown, cc.c3b(0xD8, 0xCD, 0xA8))
        UIHelper.SetTextColor(scriptContainer.LabelTitleUp, cc.c3b(0xFF, 0xFF, 0xFF))
        UIHelper.SetSpriteFrame(scriptContainer.ImgArrowNormal, "UIAtlas2_Public_PublicButton_PublicButton1_Btn_Down_Gold")
        UIHelper.SetSpriteFrame(scriptContainer.ImgArrowUp, "UIAtlas2_Public_PublicButton_PublicButton1_Btn_Down_Gold")
        UIHelper.SetSpriteFrame(scriptContainer.ImgBgNormal, "UIAtlas2_Public_PublicButton_PublicNavigation_Tree_Bg_Gold")
        UIHelper.SetSpriteFrame(scriptContainer.ImgBgUp, "UIAtlas2_Public_PublicButton_PublicNavigation_Tree_Selected_Gold")
        UIHelper.SetSpriteFrame(scriptContainer.ImgFrameNormal, "UIAtlas2_Public_PublicButton_PublicNavigation_Tree_Small_Normal_Gold")
        UIHelper.SetSpriteFrame(scriptContainer.ImgFrameUp, "UIAtlas2_Public_PublicButton_PublicNavigation_Tree_Small_Selected_Gold")
    else
        UIHelper.SetTextColor(scriptContainer.LabelTitleDown, cc.c3b(0xAE, 0xD9, 0xE0))
        UIHelper.SetTextColor(scriptContainer.LabelTitleUp, cc.c3b(0xFF, 0xFF, 0xFF))
        UIHelper.SetSpriteFrame(scriptContainer.ImgArrowNormal, "UIAtlas2_Public_PublicButton_PublicButton1_Btn_Down")
        UIHelper.SetSpriteFrame(scriptContainer.ImgArrowUp, "UIAtlas2_Public_PublicButton_PublicButton1_Btn_Down")
        UIHelper.SetSpriteFrame(scriptContainer.ImgBgNormal, "UIAtlas2_Public_PublicButton_PublicNavigation_Tree_Bg")
        UIHelper.SetSpriteFrame(scriptContainer.ImgBgUp, "UIAtlas2_Public_PublicButton_PublicNavigation_Tree_Selected")
        UIHelper.SetSpriteFrame(scriptContainer.ImgFrameNormal, "UIAtlas2_Public_PublicButton_PublicNavigation_Tree_Small_Normal")
        UIHelper.SetSpriteFrame(scriptContainer.ImgFrameUp, "UIAtlas2_Public_PublicButton_PublicNavigation_Tree_Small_Selected")
    end
end

function UIAuctionLootListView:TryUpdateOnAuctionItem(tLootInfo)
    self.tOnAuctionLootInfo = tLootInfo
    local bOnAuction = tLootInfo and tLootInfo.eState == AuctionState.CountDown
    self.bRealHasAuction = bOnAuction
    self.scriptItemOnAuction = self.scriptItemOnAuction or UIHelper.GetBindScript(self.WidgetItemOnAuction)
    if bOnAuction then        
        self.scriptItemOnAuction:OnEnter({
            tLootInfo = tLootInfo,
            fCallBack = function (node)
                self:RefreshItemTipButtons(tLootInfo)
            end
        })
    end
    
    UIHelper.SetVisible(self.WidgetItemEmpty, not bOnAuction)
    UIHelper.SetVisible(self.WidgetItemShell, bOnAuction)
end

function UIAuctionLootListView:RefreshItemTipButtons(tLootInfo, bIsNeedList)
    local tDoodadInfo = AuctionData.tPickedDoodads[tLootInfo.dwDoodadID]
    if not tDoodadInfo then return end

    local tbButtonList = self:BuildButtons(tDoodadInfo, tLootInfo, bIsNeedList)
    self.scriptItemtip = self.scriptItemtip or UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTipsShell)
    self.scriptItemtip:SetFunctionButtons(tbButtonList)
    self.scriptItemtip:SetBookID(tLootInfo.nBookID)
    self.scriptItemtip:OnInitWithTabID(tLootInfo.dwItemTabType, tLootInfo.dwItemIndex)
    self:ShowMiddleTips(MIDDLE_TIPS_MODE.ITEM)
    if #tbButtonList > 0 then
        self.bFarPoint = true
        local nPosX = UIHelper.GetWorldPositionX(self.WidgetItemTipsFarPoint)
        local nPosY = UIHelper.GetWorldPositionY(self.WidgetItemTipsFarPoint)
        UIHelper.SetWorldPosition(self.WidgetItemTipsShell, nPosX, nPosY)
    else
        self.bFarPoint = false
        local nPosX = UIHelper.GetWorldPositionX(self.WidgetItemTipsNearPoint)
        local nPosY = UIHelper.GetWorldPositionY(self.WidgetItemTipsNearPoint)
        UIHelper.SetWorldPosition(self.WidgetItemTipsShell, nPosX, nPosY)
    end
end

function UIAuctionLootListView:OnSelectLootItem(tDoodadInfo, tLootInfo)
    local player = GetClientPlayer()
    if not player then return end
    local scene = player.GetScene()
    if not scene then return end

    UIHelper.SetVisible(self.WidgetDistributionRecord, AuctionData.IsDistributeMan())

    if tDoodadInfo.nLootMode == PARTY_LOOT_MODE.DISTRIBUTE or
        (tDoodadInfo.nLootMode == PARTY_LOOT_MODE.BIDDING) then
        self.scriptDistribution = self.scriptDistribution or UIHelper.GetBindScript(self.WidgetDistributionRecord)
        local bHasDetail = tDoodadInfo.nLootMode == PARTY_LOOT_MODE.BIDDING
        self.scriptDistribution:OnEnter(tLootInfo, bHasDetail, function (tData)
            if tDoodadInfo.nLootMode == PARTY_LOOT_MODE.DISTRIBUTE then
                scene.DistributeItem(tLootInfo.dwDoodadID, tLootInfo.dwItemID, tData.dwPlayerID)
                AuctionData.OnItemHandleOver(tLootInfo)
            elseif tDoodadInfo.nLootMode == PARTY_LOOT_MODE.BIDDING then
                local szMoney, szItemName, szPlayerName = AuctionData.GetLootItemConfirmContent(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex, tData)
                local szContent = string.format("你确认以%s将[%s]分配给[%s]吗？", szMoney, szItemName, szPlayerName)
                UIHelper.ShowConfirm(szContent, function ()
                    AuctionData.StartBidding(tLootInfo, tData.nBrick, tData.nGold, tData.szComment, tData.dwPlayerID)
                end, nil, true)
            end
            UIHelper.SetVisible(self.WidgetDistributionRecord, false)
            UIHelper.SetVisible(self.WidgetZeroGoldItemList, false)
        end)
    end
end

function UIAuctionLootListView:OnClickQuickDistributeButton(scriptDistribute, nDoodadID)
    local tDoodadInfo = AuctionData.tPickedDoodads[nDoodadID]
    if not tDoodadInfo then return end

    local rPosX = UIHelper.GetWorldPositionX(scriptDistribute._rootNode)
    local rPosY = UIHelper.GetWorldPositionY(scriptDistribute._rootNode)
    local rWidth = UIHelper.GetWidth(scriptDistribute._rootNode)
    local lPosX = rPosX - rWidth/2

    local nNodeHeight = UIHelper.GetHeight(self.WidgetItemOperTips)
    if rPosY < nNodeHeight then rPosY = nNodeHeight end

    UIHelper.SetWorldPosition(self.WidgetItemOperTips, lPosX, rPosY)
    self:ShowMiddleTips(MIDDLE_TIPS_MODE.OPER)

    local scriptTips = UIHelper.GetBindScript(self.WidgetItemOperTips)
    if scriptTips then
        scriptTips:OnEnter(tDoodadInfo, function (nType)
            self:OnQuickDistribute(tDoodadInfo, nType)
        end)
    end
end

function UIAuctionLootListView:OnClickQuickAuctionButton(scriptDistribute, nDoodadID)
    local tDoodadInfo = AuctionData.tPickedDoodads[nDoodadID]
    if not tDoodadInfo then return end

    for _, tLootInfo in ipairs(tDoodadInfo.tLootItemInfoList) do
        local item = AuctionData.GetItem(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
        if item and tLootInfo.eState == AuctionState.WaitAuction then
            local nDefaultPrice, nDefaultStepPrice = AuctionData.GetDefaultPriceInfo(item)
            if nDefaultPrice > 0 then
                local teamBidMgr = GetTeamBiddingMgr()
                local nCode = teamBidMgr.CanBeginBidding(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex, nDefaultPrice, nDefaultStepPrice, false)
                if nCode ~= TEAM_BIDDING_START_RESULT.SUCCESS then
                    TipsHelper.ShowNormalTip(g_tStrings.tTeamBiddingStartError[nCode])
                    return
                end
                teamBidMgr.BeginBidding(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex, nDefaultPrice, nDefaultStepPrice, false)
            end
        end
    end
end

function UIAuctionLootListView:QuickAuctionButtonEnable(nDoodadID)
    local tDoodadInfo = AuctionData.tPickedDoodads[nDoodadID]
    if not tDoodadInfo then return false end
    if not DungeonData.IsInDungeon() then return false end

    for _, tLootInfo in ipairs(tDoodadInfo.tLootItemInfoList) do
        local item = AuctionData.GetItem(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
        if item and tLootInfo.eState == AuctionState.WaitAuction then
            local nDefaultPrice, nDefaultStepPrice = AuctionData.GetDefaultPriceInfo(item)
            if nDefaultPrice > 0 then
                local teamBidMgr = GetTeamBiddingMgr()
                local nCode = teamBidMgr.CanBeginBidding(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex, nDefaultPrice, nDefaultStepPrice, false)
                if nCode == TEAM_BIDDING_START_RESULT.SUCCESS then return true end
            end
        end
    end

    return false
end

function UIAuctionLootListView:OnQuickDistribute(tDoodadInfo, nType)
    self:ShowMiddleTips(MIDDLE_TIPS_MODE.DIST)

    local scriptTips = UIHelper.GetBindScript(self.WidgetItemOperTips)
    self.scriptDistribution = self.scriptDistribution or UIHelper.GetBindScript(self.WidgetDistributionRecord)
    local tLootInfo = tDoodadInfo.tLootItemInfoList[1]

    local tLootItemList = {}
    if nType == AuctionQuickDistributeType.Material then
        tLootItemList = scriptTips.tMaterialItems
    elseif nType == AuctionQuickDistributeType.SanJian then
        tLootItemList = scriptTips.tSanjianItems
    else
        tLootItemList = scriptTips.tGeneralItems
    end

    self.scriptDistribution:OnEnter(tLootInfo, false, function (tData)
        for _, tLootInfo in ipairs(tLootItemList) do
            AuctionData.StartBidding(tLootInfo, 0, 0, "", tData.dwPlayerID)
        end
        UIHelper.SetVisible(self.WidgetDistributionRecord, false)
        UIHelper.SetVisible(self.WidgetZeroGoldItemList, false)
    end)

    UIHelper.SetVisible(self.WidgetZeroGoldItemList, true)
    UIHelper.RemoveAllChildren(self.ScrollViewZeroGoldItemList)

    for _, tLootInfo in ipairs(tLootItemList) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetZeroGoldItemCell, self.ScrollViewZeroGoldItemList, tLootInfo)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewZeroGoldItemList)
end

function UIAuctionLootListView:OnClickNeedAllButton(scriptRollPoint, nDoodadID)
    local tDoodadInfo = AuctionData.tPickedDoodads[nDoodadID]
    if not tDoodadInfo then return end
    if not DungeonData.IsInDungeon() then return end

    for _, tLootInfo in ipairs(tDoodadInfo.tLootItemInfoList) do
        local bHasRoll = tLootInfo.szRollPoint and #tLootInfo.szRollPoint > 0
        local bCancel = tLootInfo.bAbstainMap[UI_GetClientPlayerID()]
        if not bHasRoll and not bCancel and tLootInfo.bNeedRoll then
            local bCanRollNeed	= g_pClientPlayer.IsBelongForceItem(tLootInfo.dwItemID)
            if bCanRollNeed then 
                self:TryRollItem(tLootInfo, ROLL_ITEM_CHOICE.NEED)
            else
                self:TryRollItem(tLootInfo, ROLL_ITEM_CHOICE.GREED)
            end
        end
    end
end

function UIAuctionLootListView:OnClickCancelAllButton(scriptRollPoint, nDoodadID)
    local tDoodadInfo = AuctionData.tPickedDoodads[nDoodadID]
    if not tDoodadInfo then return end
    if not DungeonData.IsInDungeon() then return end

    for _, tLootInfo in ipairs(tDoodadInfo.tLootItemInfoList) do
        local bHasRoll = tLootInfo.szRollPoint and #tLootInfo.szRollPoint > 0
        local bCancel = tLootInfo.bAbstainMap[UI_GetClientPlayerID()]
        if not bHasRoll and not bCancel and tLootInfo.bNeedRoll then
            self:TryRollItem(tLootInfo, ROLL_ITEM_CHOICE.CANCEL)
        end
    end
end

function UIAuctionLootListView:QuickNeedAllButtonEnable(nDoodadID)
    local tDoodadInfo = AuctionData.tPickedDoodads[nDoodadID]
    if not tDoodadInfo then return false end
    if not DungeonData.IsInDungeon() then return false end

    for _, tLootInfo in ipairs(tDoodadInfo.tLootItemInfoList) do
        local bHasRoll = tLootInfo.szRollPoint and #tLootInfo.szRollPoint > 0
        local bCancel = tLootInfo.bAbstainMap[UI_GetClientPlayerID()]
        if not bHasRoll and not bCancel and tLootInfo.bNeedRoll then
            return true
        end
    end

    return false
end

function UIAuctionLootListView:QuickCancelAllButtonEnable(nDoodadID)
    return self:QuickNeedAllButtonEnable(nDoodadID)
end

function UIAuctionLootListView:OnClickQuickFilterButton(scriptNeed, bSelected)
    AuctionData.bFilterForce = bSelected
    AuctionData.SetNeedRefresh(true)
end

function UIAuctionLootListView:CheckGoldTeamNeed(tNeedConfig)
    if tNeedConfig.szKungfuIDs == "" then
         return true 
    end
    for _, dwKungfuID in ipairs(tNeedConfig.tKungfuIDs) do
        if PlayerData.CheckForceOrNoneSchool(dwKungfuID) then
            return true
        end
    end
end


function UIAuctionLootListView:BuildButtons(tDoodadInfo, tLootInfo, bIsNeedList)
    local player = GetClientPlayer()
    local clientTeam = GetClientTeam()
    local dwDistributerID = clientTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE)
    local bDistributer = dwDistributerID == player.dwID
    local tBidInfo = AuctionData.GetBiddingInfo(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
    -- 过滤按钮
    for _, btn in ipairs(self.tbButtons) do
        UIHelper.SetVisible(btn, false)
    end

    local bHasBidder = tBidInfo and tBidInfo.dwDestPlayerID > 0
    local bHasChoice = tLootInfo.nChoice ~= nil
    local bPayer = tBidInfo and tBidInfo.dwDestPlayerID == player.dwID

    local tButtonList = {}
    if tLootInfo.bHasDistributed then return tButtonList end

    local tBtnNeed = {
        szName = "需求", OnClick = function ()
            self:TryRollItem(tLootInfo, ROLL_ITEM_CHOICE.NEED)
            UIHelper.SetVisible(self.scriptItemtip._rootNode, false)
        end
    }
    local bCanRollNeed	= player.IsBelongForceItem(tLootInfo.dwItemID)
    tBtnNeed.bDisabled = not bCanRollNeed
    tBtnNeed.szDisableTip = "该物品并不适合您的门派"
    local tBtnGreed = {
        szName = "捡漏", OnClick = function ()
            self:TryRollItem(tLootInfo, ROLL_ITEM_CHOICE.GREED)
            UIHelper.SetVisible(self.scriptItemtip._rootNode, false)
        end
    }
    local tBtnExitRoll = {
        szName = "放弃", OnClick = function ()
            self:RollItem(tLootInfo, ROLL_ITEM_CHOICE.CANCEL)
            UIHelper.SetVisible(self.scriptItemtip._rootNode, false)
        end
    }
    local tBtnAuction = {
        szName = "开始拍卖", OnClick = function ()
            self:TryStartAuction(tLootInfo)
            UIHelper.SetVisible(self.scriptItemtip._rootNode, false)
        end
    }
    local tBtnDistribute = {
        szName = "直接分配", OnClick = function ()
            self:OnSelectLootItem(tDoodadInfo, tLootInfo)
            UIHelper.SetVisible(self.scriptItemtip._rootNode, false)
        end
    }
    local tBtnBid = {
        szName = "出价", OnClick = function ()
            self:TryOfferPrice(tLootInfo)
            local nIndex = FindTableValue(Storage.Auction.tNoPromotDoodadList, {tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex})
            if nIndex then
                table.remove(Storage.Auction.tNoPromotDoodadList, nIndex)
                AuctionData.SetNeedRefresh(true)
            end
            UIHelper.SetVisible(self.scriptItemtip._rootNode, false)
        end
    }
    local tBtnDeal = {
        szName = "成交", OnClick = function ()
            self:TryFinishBidding(tLootInfo)
            UIHelper.SetVisible(self.scriptItemtip._rootNode, false)
        end
    }
    local tBtnRedistribute = {
        szName = "分配", OnClick = function ()
            self:OnSelectLootItem(tDoodadInfo, tLootInfo)
            UIHelper.SetVisible(self.scriptItemtip._rootNode, false)
        end
    }
    local tBtnReAuction = {
        szName = "重拍", OnClick = function ()
            self:TryStartAuction(tLootInfo)
            UIHelper.SetVisible(self.scriptItemtip._rootNode, false)
        end
    }
    local tBtnExitAuction = {
        szName = "撤销", OnClick = function ()
            self:TryEndBidding(tLootInfo)
            UIHelper.SetVisible(self.scriptItemtip._rootNode, false)
        end
    }
    local tBtnPay = {
        szName = "支付", OnClick = function ()
            self:TryPay(tLootInfo)
            UIHelper.SetVisible(self.scriptItemtip._rootNode, false)
        end
    }
    local tBtnPayFor = {
        szName = "代付", OnClick = function ()
            self:TryPay(tLootInfo)
            UIHelper.SetVisible(self.scriptItemtip._rootNode, false)
        end
    }
    local tBtnComplete = {
        szName = "结算", OnClick = function ()
            AuctionData.TryBidCountDown(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
            UIHelper.SetVisible(self.scriptItemtip._rootNode, false)
        end
    }

    local tBtnNoPromot = {
        szName = "不再关注", OnClick = function ()
            table.insert(Storage.Auction.tNoPromotDoodadList, {tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex})
            AuctionData.SetNeedRefresh(true)
            UIHelper.SetVisible(self.scriptItemtip._rootNode, false)
        end
    }
    tBtnComplete.bDisabled = self.bRealHasAuction
    tBtnComplete.szDisableTip = "当前已有物品正在结算"
    if tLootInfo.bNeedRoll then
        local bNotChoice = not tLootInfo.nChoice
        if bNotChoice then table.insert(tButtonList, tBtnNeed) end
        if bNotChoice then table.insert(tButtonList, tBtnGreed) end
        if bNotChoice then table.insert(tButtonList, tBtnExitRoll) end
    elseif tLootInfo.bNeedBidding then
        if tLootInfo.eState == AuctionState.WaitAuction then
            if bDistributer and DungeonData.IsInDungeon() then table.insert(tButtonList, 1, tBtnAuction) end
            if bDistributer then table.insert(tButtonList, 1, tBtnDistribute) end
        elseif tLootInfo.eState == AuctionState.OnAuction then
            table.insert(tButtonList, 1, tBtnBid)            
            if bDistributer then table.insert(tButtonList, 1, tBtnRedistribute) end
            if bDistributer then table.insert(tButtonList, 1, tBtnReAuction) end
            if bDistributer and bHasBidder then table.insert(tButtonList, 1, tBtnComplete) end
        elseif tLootInfo.eState == AuctionState.CountDown then
            table.insert(tButtonList, 1, tBtnBid)
        elseif tLootInfo.eState == AuctionState.CountFinished then
            if bDistributer then table.insert(tButtonList, 1, tBtnRedistribute) end
            if bDistributer then table.insert(tButtonList, 1, tBtnReAuction) end
        elseif tLootInfo.eState == AuctionState.WaitPay then
            if bDistributer then table.insert(tButtonList, 1, tBtnExitAuction) end
            if bPayer then table.insert(tButtonList, 1, tBtnPay) end
            if not bPayer then table.insert(tButtonList, 1, tBtnPayFor) end
        end
        if bIsNeedList and self:IsNeedDoodad(tLootInfo) and not CheckIsInTable(Storage.Auction.tNoPromotDoodadList, {tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex}) then 
            table.insert(tButtonList, tBtnNoPromot)
        end
    elseif tLootInfo.bNeedDistribute then
        if bDistributer then table.insert(tButtonList, 1, tBtnDistribute) end
    end

    return tButtonList
end

function UIAuctionLootListView:RollItem(tLootInfo, nChoice)
    RollItem(tLootInfo.dwDoodadID, tLootInfo.dwItemID, nChoice)
    tLootInfo.nChoice = nChoice
    AuctionData.CheckAbstainMap(UI_GetClientPlayerID(), tLootInfo.dwItemID)
    Event.Dispatch(EventType.OnLootInfoChanged, tLootInfo)
end

function UIAuctionLootListView:TryRollItem(tLootInfo, nChoice)
    local item = AuctionData.GetItem(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
    if item and item.nBindType == ITEM_BIND.BIND_ON_PICKED then
        local itemName = ItemData.GetItemNameByItem(item)
        itemName = UIHelper.GBKToUTF8(itemName)
        local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(item.nQuality)
        itemName = GetFormatText(itemName, nil, nDiamondR, nDiamondG, nDiamondB)
        local msg = string.format(g_tStrings.Auction.ROLL_ITEM_SURE, itemName)
        if nChoice == ROLL_ITEM_CHOICE.CANCEL then msg = string.format(g_tStrings.Auction.ROLL_ITEM_CANCEL, itemName) end
        
        UIHelper.ShowConfirm(msg, function ()
            self:RollItem(tLootInfo, nChoice)
        end, function ()

        end,true)
    else
        self:RollItem(tLootInfo, nChoice)
    end
end

function UIAuctionLootListView:TryPay(tLootInfo)
    local tBidInfo = AuctionData.GetBiddingInfo(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
    if not tBidInfo then
        return
    end

    local nPrice = tBidInfo.nPrice - tBidInfo.nPaidMoney
    local tData = {
        nBrick = math.floor(nPrice / 10000),
        nGold  = nPrice % 10000,
        dwPlayerID = tBidInfo.dwDestPlayerID,
    }
    local szMoney, szItemName, szDestPlayerName = AuctionData.GetStartBiddingConfirmContent(tBidInfo.dwItemID, tData)
    local szMsg = ""
    if tData.nBrick == 0 and tData.nGold == 0 then
        szMsg = string.format("你确认获取[%s]吗？", szItemName)
    elseif tBidInfo.dwItemID and tBidInfo.dwItemID > 0 then
        szMsg = string.format("你确认以%s购买[%s]吗？", szMoney, szItemName)
    else
        szMsg = string.format("你确认缴纳[%s]吗？", szMoney)
    end
    if tBidInfo.dwDestPlayerID ~= UI_GetClientPlayerID() then
        if tBidInfo.dwItemID and tBidInfo.dwItemID > 0 then
            szMsg = string.format("你确认以%s为[%s]购买[%s]吗？", szMoney, szDestPlayerName, szItemName)
        else
            szMsg = string.format("你确认为[%s]缴纳[%s]吗？", szDestPlayerName, szMoney)
        end
    end
    UIHelper.ShowConfirm(szMsg, function ()
        AuctionData.TryPay(tBidInfo)
    end, nil, true)
end

-- 撤销分配/拍卖
function UIAuctionLootListView:TryEndBidding(tLootInfo)
    local teamBidMgr = GetTeamBiddingMgr()
    if not teamBidMgr then
        return
    end

    local tBidInfo = AuctionData.GetBiddingInfo(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
    if not tBidInfo then
        return
    end

    local eRetCode = teamBidMgr.CanEndBidding(tBidInfo.nBiddingInfoIndex)
    if eRetCode == TEAM_BIDDING_START_RESULT.SUCCESS then
        if tBidInfo.nType == BIDDING_INFO_TYPE.ITEM then
            GoldTeam_SaveEditedBiddingInfo(tBidInfo)
        end
        teamBidMgr.EndBidding(tBidInfo.nBiddingInfoIndex)
    else
        TipsHelper.ShowNormalTip(g_tStrings.GOLD_END_BID_FAIL, false)
    end
end

-- 进行分配
function UIAuctionLootListView:TryFinishBidding(tLootInfo, dwDestPlayerID)
    local teamBidMgr = GetTeamBiddingMgr()
    if not teamBidMgr then
        return
    end

    local tBidInfo = AuctionData.GetBiddingInfo(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
    if not tBidInfo then
        return
    end

    dwDestPlayerID = dwDestPlayerID or tBidInfo.dwDestPlayerID

    local eRetCode = teamBidMgr.CanFinishBidding(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex, tBidInfo.nPrice, dwDestPlayerID)
    if eRetCode == TEAM_BIDDING_START_RESULT.SUCCESS then
        if tBidInfo.nType == BIDDING_INFO_TYPE.ITEM then
            GoldTeam_SaveEditedBiddingInfo(tBidInfo)
        end
        teamBidMgr.FinishBidding(tLootInfo.dwDoodadID, dwDestPlayerID, tBidInfo.nPrice, tLootInfo.nItemLootIndex, "")
    else
        local msg = g_tStrings.tTeamBiddingStartError[eRetCode] or "价格错误"
        TipsHelper.ShowNormalTip(msg, false)
    end
end

function UIAuctionLootListView:TryStartAuction(tLootInfo)
    local scriptView = UIMgr.GetView(VIEW_ID.PanelAuctionPreparationPop)
    if not scriptView then
        scriptView = UIMgr.Open(VIEW_ID.PanelAuctionPreparationPop, tLootInfo)
    end
end

function UIAuctionLootListView:TryOfferPrice(tLootInfo)
    local scriptView = UIMgr.GetView(VIEW_ID.PanelAuctionBidPop)
    if not scriptView then
        scriptView = UIMgr.Open(VIEW_ID.PanelAuctionBidPop, tLootInfo)
    end
end

function UIAuctionLootListView:TryShared(tLootInfo)
    local item = AuctionData.GetItem(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
    if item then
        ChatHelper.SendItemInfoToChat(nil, item.dwTabType, item.dwIndex)
    end
end

function UIAuctionLootListView:TryBackGroundTouchClose()
    return false
end

function UIAuctionLootListView:ShowMiddleTips(nMode)
    UIHelper.SetVisible(self.WidgetItemOperTips, nMode == MIDDLE_TIPS_MODE.OPER)
    UIHelper.SetVisible(self.WidgetItemTipsShell, nMode == MIDDLE_TIPS_MODE.ITEM)
    UIHelper.SetVisible(self.WidgetDistributionRecord, nMode == MIDDLE_TIPS_MODE.DIST)
    if nMode ~= MIDDLE_TIPS_MODE.DIST then
        UIHelper.SetVisible(self.WidgetZeroGoldItemList, false)
    end   

    UIHelper.SetVisible(self.BtnCloseTip, nMode ~= MIDDLE_TIPS_MODE.NONE)
    UIHelper.SetVisible(self.BtnAllClose, nMode == MIDDLE_TIPS_MODE.NONE)

    if self.bItemTipVisibleBeforeRefresh == false and nMode == MIDDLE_TIPS_MODE.ITEM then -- 如果刷新前没有tips，那么刷新后的首次tips不显示
        self.bItemTipVisibleBeforeRefresh = nil
        UIHelper.SetVisible(self.WidgetItemTipsShell, false)
    end    
end

return UIAuctionLootListView