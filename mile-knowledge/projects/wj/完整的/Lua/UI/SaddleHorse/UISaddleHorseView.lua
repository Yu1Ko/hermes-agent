-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISaddleHorseView
-- Date: 2022-12-06 10:23:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISaddleHorseView = class("UISaddleHorseView")
local dwHorseEquipType = ITEM_TABLE_TYPE.CUST_TRINKET
local HORSE_EXTERIOR_INDEX = "HORSE_STYLE"
local HORSE_EXTERIOR_UI_INDEX = 5

local tLogicIndexToUIIndex = {
    [HORSE_EXTERIOR_INDEX] = HORSE_EXTERIOR_UI_INDEX,
    [HORSE_ENCHANT_DETAIL_TYPE.HEAD] = 1,
    [HORSE_ENCHANT_DETAIL_TYPE.CHEST] = 2,
    [HORSE_ENCHANT_DETAIL_TYPE.FOOT] = 3,
    [HORSE_ENCHANT_DETAIL_TYPE.HANT_ITEM] = 4,
}

local tUIIndexToLogicIndex = {
    [HORSE_EXTERIOR_UI_INDEX] = HORSE_EXTERIOR_INDEX,
    [1] = HORSE_ENCHANT_DETAIL_TYPE.HEAD,
    [2] = HORSE_ENCHANT_DETAIL_TYPE.CHEST,
    [3] = HORSE_ENCHANT_DETAIL_TYPE.FOOT,
    [4] = HORSE_ENCHANT_DETAIL_TYPE.HANT_ITEM,
}

local tEquipIndex =
{
    [1] = EQUIPMENT_INVENTORY.HEAD_HORSE_EQUIP,
    [2] = EQUIPMENT_INVENTORY.CHEST_HORSE_EQUIP,
    [3] = EQUIPMENT_INVENTORY.FOOT_HORSE_EQUIP,
    [4] = EQUIPMENT_INVENTORY.HANG_ITEM_HORSE_EQUIP,
}

local tPresetIndexToEquipIndex =
{
    [HORSE_ENCHANT_DETAIL_TYPE.HEAD] = EQUIPMENT_INVENTORY.HEAD_HORSE_EQUIP,
    [HORSE_ENCHANT_DETAIL_TYPE.CHEST] = EQUIPMENT_INVENTORY.CHEST_HORSE_EQUIP,
    [HORSE_ENCHANT_DETAIL_TYPE.FOOT] = EQUIPMENT_INVENTORY.FOOT_HORSE_EQUIP,
    [HORSE_ENCHANT_DETAIL_TYPE.HANT_ITEM] = EQUIPMENT_INVENTORY.HANG_ITEM_HORSE_EQUIP,
}

local tHorseDetailToRe = 
{
	["HORSE_STYLE"] = EQUIPMENT_REPRESENT.HORSE_STYLE,
    [HORSE_ENCHANT_DETAIL_TYPE.HEAD] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT1,
    [HORSE_ENCHANT_DETAIL_TYPE.CHEST] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT2,
    [HORSE_ENCHANT_DETAIL_TYPE.FOOT] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT3,
    [HORSE_ENCHANT_DETAIL_TYPE.HANT_ITEM] = EQUIPMENT_REPRESENT.HORSE_ADORNMENT4,
}

local m_bShowHorseExterior = false

local function RequestGrowInfo(nItemID)
    RemoteCallToServer("On_Recharge_GetCurrentGrowInfo", nItemID)
end

local function EnableHorseExterior()
	local hPlayer = GetClientPlayer()
	local horse 		= hPlayer.GetEquippedHorse()
	local dwBox, dwX 	= hPlayer.GetEquippedHorsePos()
	if not dwBox then
		return false
	end
	if horse and horse.IsRareHorse() then
		return false
	end
	return true
end

local function UpdateExteriorRepresentID(tRepresentID, tExterior)
	if tRepresentID[EQUIPMENT_REPRESENT.HORSE_STYLE] == 0 then
		return
	end
	local hMgr = GetHorseExteriorManager()
	for k, v in pairs(tHorseDetailToRe) do
        local tExteriorInfo = RideExteriorData.GetRideExteriorInfo(tExterior[k], k ~= HORSE_EXTERIOR_INDEX)
		if tExteriorInfo then
			tRepresentID[v] = tExteriorInfo.dwRepresentID
		end
	end
end

local function SaveHorseExterior()
	local tBuyList = {}
	local tSetList = {}

	for k, v in pairs(RideExteriorData.tHorseDetailToRe) do
		local dwExteriorID = RideExteriorData.tPreviewExterior[k]
        local tExteriorinfo = RideExteriorData.GetRideExteriorInfo(dwExteriorID, k ~= RideExteriorData.HORSE_EXTERIOR_INDEX)
	    local tWear = RideExteriorData.GetWearRideExterior()
        if tExteriorinfo then
            if tExteriorinfo.bHave and tWear[k].dwExteriorID ~= dwExteriorID then
                table.insert(tSetList, {dwExteriorID = dwExteriorID, bEquip = (k ~= RideExteriorData.HORSE_EXTERIOR_INDEX), nExteriorSlot = k})
            elseif tExteriorinfo.bCollected and (not tExteriorinfo.bHave) then
                table.insert(tBuyList, {dwExteriorID = dwExteriorID, bEquip = (k ~= RideExteriorData.HORSE_EXTERIOR_INDEX), nExteriorSlot = k})
            end
        else
			if tWear[k].dwExteriorID ~= dwExteriorID then 
				table.insert(tSetList, {dwExteriorID = 0, bEquip = (k ~= RideExteriorData.HORSE_EXTERIOR_INDEX), nExteriorSlot = k})
			end
        end
	end

    if #tBuyList > 0 then
        UIMgr.Open(VIEW_ID.PanelRideExteriorCheckOut, tBuyList, tSetList)
	else
		RideExteriorData.SetExterior(tSetList)
	end
end

--------------奇趣坐骑远程收藏数据-----------------
local PREFER_RAREHORSE_SET_CD   = 500
local REMOTE_PREFER_RAREHORSE = 1215 -- 玩家收藏的奇趣坐骑远程数据索引
local MAX_PREFER_RAREHORSE_NUM = 6 -- 最多收藏6个
local m_tPendingDelHorseSet = {} -- 已发起清理的幽灵占位，防止重复触发

local function GetRemotePreferRareHorse()
    local tList = {}
    local pPlayer = GetClientPlayer()
	if not pPlayer then
		return tList
	end

    local nCount = pPlayer.GetRemoteSetSize(REMOTE_PREFER_RAREHORSE)
    return nCount
end

local function InitRemoteData()
    local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end

    if not pPlayer.HaveRemoteData(REMOTE_PREFER_RAREHORSE) then
        pPlayer.ApplyRemoteData(REMOTE_PREFER_RAREHORSE)
    end
end

local function IsPreferRareHorse(nHorseIndex)
    local pPlayer = GetClientPlayer()
	if not pPlayer then
		return false
	end

	return pPlayer.HaveRemoteSet(REMOTE_PREFER_RAREHORSE, nHorseIndex)
end

local m_nLastSetTime = 0
local function SetPreferRareHorse(nHorseIndex)
    local pPlayer = GetClientPlayer()
	if not pPlayer then
		return false
	end

	local dwPlayerID = pPlayer.dwID
	if IsRemotePlayer(dwPlayerID) then
		TipsHelper.ShowNormalTip(g_tStrings.STR_REMOTE_NOT_TIP)
		return
	end

	if GetTickCount() - m_nLastSetTime < PREFER_RAREHORSE_SET_CD then
		TipsHelper.ShowSystemTips(g_tStrings.STR_HAVE_CD)
		return
	end

	local bPrefer = IsPreferRareHorse(nHorseIndex)
	if not bPrefer then
		RemoteCallToServer("On_PreferRareHorse_AddPrefer", nHorseIndex)
	else
		RemoteCallToServer("On_PreferRareHorse_DelPrefer", nHorseIndex)
	end
	m_nLastSetTime = GetTickCount()
end

--------------奇趣坐骑远程收藏数据-----------------END

function UISaddleHorseView:OnEnter(nTabType, nTabID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self:InitModelView()
        self.bInit = true
    end
    if nTabType and nTabID then
        self.nShowTabType = IsString(nTabType) and tonumber(nTabType) or nTabType
        self.nShowTabID = IsString(nTabID) and tonumber(nTabID) or nTabID
    end

    InitRemoteData()
    self:InitViewInfo()
    if (not self.dwCurEquipBox or self.dwCurEquipBox == INVENTORY_INDEX.HORSE) and not self.nShowTabType then
        UIHelper.SetSelected(self.TogNormal, true)
    else
        UIHelper.SetSelected(self.TogSpecial, true)
    end

    RideExteriorData.UpdateHorseExteriorData()
end

function UISaddleHorseView:OnExit()
    if self.hModelView then
        if self.hModelView.m_scene then
            self.hModelView.m_scene:RestoreCameraLight()
        end

        self.hModelView:release()
        self.hModelView = nil
    end

    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
    TipsHelper.DeleteAllHoverTips()
    UITouchHelper.UnBindModel()
    if self.tScrollListHorse then
        self.tScrollListHorse:Destroy()
        self.tScrollListHorse = nil
    end
end

function UISaddleHorseView:BindUIEvent()
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupSaddleHouseList, self.TogSaddleHouse)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupSaddleHouseList, self.TogAppearance)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupSaddleHouseList, self.TogAllHorse)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupSaddleHouseList, self.TogCollectedHorse)
    UIHelper.SetToggleGroupAllowedNoSelection(self.ToggleGroupSaddleHouseList, false)
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogNormal, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self.szFilter = "Ride"
            self.bExterior = false
            self.bPreferRareHorse = false
            UIHelper.SetString(self.EditBoxSearch, "")
            self:UpdateAllHorseList()
        end
    end)

    UIHelper.BindUIEvent(self.TogAllHorse, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self.szFilter = "Qiqu"
            self.bExterior = false
            self.bPreferRareHorse = false
            UIHelper.SetString(self.EditBoxSearch, "")
            self:UpdateAllHorseList()
        end
    end)

    UIHelper.BindUIEvent(self.TogCollectedHorse, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self.szFilter = "Qiqu"
            self.bExterior = false
            self.bPreferRareHorse = true
            UIHelper.SetString(self.EditBoxSearch, "")
            self:UpdatePreferNum()
            self:UpdateAllHorseList()
        end
    end)

    UIHelper.BindUIEvent(self.TogSpecial, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self.szFilter = "Qiqu"
            self.bExterior = false
            self.bPreferRareHorse = false
            UIHelper.SetString(self.EditBoxSearch, "")
            self:UpdateAllHorseList()
        end
    end)

    UIHelper.BindUIEvent(self.TogSaddleHouse, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected and self.szFilter == "Ride" then
            self.szFilter = "Ride"
            self.bExterior = false
            UIHelper.SetString(self.EditBoxSearch, "")
            self:UpdateAllHorseList()
        end
    end)

    UIHelper.BindUIEvent(self.TogAppearance, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected and self.szFilter == "Ride" then
            self.szFilter = "Ride"
            self.bExterior = true
            UIHelper.SetString(self.EditBoxSearch, "")
            self:UpdateAllHorseList()
        end
    end)

    UIHelper.BindUIEvent(self.BtnSet, EventType.OnClick, function ()
        --设为当前坐骑
        self:OnClickEquipHorse()
    end)

    UIHelper.BindUIEvent(self.BtnRemove, EventType.OnClick, function ()
        if PropsSort.IsBagInSort() then
            TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
            return
        end

        --卸下，放回背包
        local dwSrcBox, dwSrcX
        if self.szFilter == "Ride" then
            dwSrcBox = INVENTORY_INDEX.HORSE
            dwSrcX = self.nIndex
        else
            -- 奇趣坐骑卸下
            if not self.nQiQuBox or not self.nQiQuIndex then
                return
            end
            dwSrcBox = self.nQiQuBox
            dwSrcX = self.nQiQuIndex
        end

        for _, tbItemInfo in ipairs(ItemData.GetItemList(ItemData.BoxSet.Bag)) do
            if not tbItemInfo.hItem then
                local nCanExchange = g_pClientPlayer.CanExchange(dwSrcBox, dwSrcX, tbItemInfo.nBox, tbItemInfo.nIndex)

                if nCanExchange == ITEM_RESULT_CODE.SUCCESS then
                    g_pClientPlayer.ExchangeItem(dwSrcBox, dwSrcX, tbItemInfo.nBox, tbItemInfo.nIndex, 1)
                 return
                else
                    TipsHelper.ShowNormalTip( g_tStrings.STR_UNDRESS..g_tStrings.STR_MOUNT_RESULT_CODE[ENCHANT_RESULT_CODE.FAILED])
                    return
                end
            end
        end
        TipsHelper.ShowNormalTip(g_tStrings.STR_MOUNT_RESULT_CODE[ENCHANT_RESULT_CODE.PACKAGE_IS_FULL])
    end)

    UIHelper.BindUIEvent(self.BtnPut, EventType.OnClick, function ()
        self:OpenHorseRightBag()
        UIHelper.SetVisible(self.WidgetAnchorRight, false)
    end)

    UIHelper.BindUIEvent(self.BtnAppreanceRule, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnAppreanceRule,
        g_tStrings.STR_HORSE_EXTERIOR_APPREANCE_RULE)
    end)

    for _, btn in ipairs(self.tBtnAddEquip) do
        UIHelper.BindUIEvent(btn, EventType.OnClick, function ()
            UIMgr.Open(VIEW_ID.PanelHarnessBag, self.nIndex)
        end)
    end

    for k, btn in ipairs(self.tReplaceExterior) do
        UIHelper.BindUIEvent(btn, EventType.OnClick, function ()
            local nLogicIndex = tUIIndexToLogicIndex[k]
            if nLogicIndex ~= HORSE_EXTERIOR_INDEX then
                UIMgr.Open(VIEW_ID.PanelHorseEquipExterior, nLogicIndex)
            else
                self:ShowHorseExteriorChoose()
            end
        end)
    end

    for k, btn in ipairs(self.tRecall) do
        UIHelper.BindUIEvent(btn, EventType.OnClick, function ()
            RideExteriorData.SetExteriorPreview(0, false, tUIIndexToLogicIndex[k])
            self:UpdateRideExterior()
            self:UpdateSaveState()
            self:UpdateExteriorHorseModel()
        end)
    end

    UIHelper.BindUIEvent(self.BtnPresets, EventType.OnClick, function ()
        SaveHorseExterior()
    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function ()
        RideExteriorData.UpdateHorseExteriorData()
        self:UpdateRideExterior()
        self:UpdateSaveState()
        self:UpdateExteriorHorseModel()
    end)

    UIHelper.BindUIEvent(self.BtnUnfoldIcon, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelHarnessBag, self.nIndex)
    end)

    UIHelper.BindUIEvent(self.BtnUnfoldIcon2, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelHarnessBag, self.nIndex)
    end)

    UIHelper.BindUIEvent(self.BtnAddIcon, EventType.OnClick, function ()
        --点击出现草料
        if PropsSort.IsBagInSort() then
            TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_FEED_ITEM_INSORT)
            return
        end
        UIHelper.SetVisible(self.WidgetClickFeeding,true)
        self:UpdateClickFeed()
    end)

    UIHelper.BindUIEvent(self.BtnHelpIcon, EventType.OnClick, function ()
        if not UIMgr.GetView(VIEW_ID.PanelAttributeAtlas) then
            UIMgr.Open(VIEW_ID.PanelAttributeAtlas, self.tAllAttr)
        end
    end)

    UIHelper.BindUIEvent(self.BtnSetQiQu, EventType.OnClick, function ()
        self:OnClickEquipHorse()
    end)

    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function ()
        if self.dwItemTabType and self.dwItemTabIndex then
            local bEnableBuy = _G.CoinShop_HorseIsInShop(self.dwItemTabType,self.dwItemTabIndex)
            if bEnableBuy then
                local itemInfo = ItemData.GetItemInfo(self.dwItemTabType,self.dwItemTabIndex)
                local szMsg = FormatString(g_tStrings.STR_GO_TO_HORSE_SHOP, UIHelper.GBKToUTF8(Table_GetItemName(itemInfo.nUiId)))
                UIHelper.ShowConfirm(szMsg, function ()
                    local dwLogicID = Table_GetRewardsGoodID(self.dwItemTabType,self.dwItemTabIndex)
                    local szLink = "Exterior/4/" .. dwLogicID
                    Event.Dispatch("EVENT_LINK_NOTIFY", szLink)
                    UIHelper.TempHideMiniSceneUntilNewViewClose(self, self.MiniScene, nil, VIEW_ID.PanelExteriorMain,nil)
                end)
            end
        end
    end)

    self.tScrollListHorse = UIScrollList.Create({
        listNode = self.LayoutHorseIcon,
        fnGetCellType = function(nIndex)
            return PREFAB_ID.WidgetHorseSlot
        end,
        fnUpdateCell = function(cell, nIndex) --每个slot里加载两个坐骑 1加载12 2加载34 3加载56
            local tbSelectCell1, tbSelectCell2
            if self.szFilter == "Ride" then
                tbSelectCell1 = self.tRideHorse[nIndex*2-1]
                tbSelectCell2 = self.tRideHorse[nIndex*2]
            else
                tbSelectCell1 = self.tQiQuHorse[nIndex*2-1]
                tbSelectCell2 = self.tQiQuHorse[nIndex*2]
            end
            if tbSelectCell1 then
                cell:OnEnter({tbSelectCell1, tbSelectCell2})
            end
            if self.szFilter ~= "Ride" and not self.bPreferRareHorse then
                local tbCells = {tbSelectCell1, tbSelectCell2}
                for k, v in ipairs(tbCells) do
                    UIHelper.SetVisible(cell.tbImgLike[k], v and IsPreferRareHorse(v.dwItemTabIndex) or false)
                end
            end
        end,
    })

    UIHelper.BindUIEvent(self.BtnStageStore, EventType.OnClick, function ()
        ShopData.OpenSystemShopGroup(1, 60)
    end)

    UIHelper.BindUIEvent(self.ToggleBase, EventType.OnClick, function ()
        UIHelper.LayoutDoLayout(self.LayoutContent)
        UIHelper.ScrollViewDoLayout(self.ScrollViewAtrributeNew)
        UIHelper.ScrollLocateToPreviewItem(self.ScrollViewAtrributeNew, self.ToggleBase, Locate.TO_CENTER)
    end)

    UIHelper.BindUIEvent(self.ToggleSpecial, EventType.OnClick, function ()
        UIHelper.LayoutDoLayout(self.LayoutContent)
        UIHelper.ScrollViewDoLayout(self.ScrollViewAtrributeNew)
        UIHelper.ScrollLocateToPreviewItem(self.ScrollViewAtrributeNew, self.ToggleSpecial, Locate.TO_CENTER)
    end)

    UIHelper.BindUIEvent(self.ScrollViewAtrributeNew, EventType.OnTouchEnded, function()
        local nPercent = UIHelper.GetScrollPercent(self.ScrollViewAtrributeNew)
        if nPercent >= 100 then
            UIHelper.SetVisible(self.WidgetArrowDown, false)
            -- UIHelper.UnBindUIEvent(self.ScrollViewToggle, EventType.OnTouchEnded)
        end
    end)

    UIHelper.BindUIEvent(self.BtnDes, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnAddIcon, TipsLayoutDir.LEFT_CENTER, self.szGrowTip)
    end)

    UIHelper.BindUIEvent(self.BtnUp, EventType.OnClick, function()
        local dwBox, dwIndex
        if self.szFilter == "Ride" then
            dwBox, dwIndex = INVENTORY_INDEX.HORSE, self.nIndex
        else
            dwBox, dwIndex = self.nQiQuBox, self.nQiQuIndex
        end

        local item = nil
        if dwBox then
            item = ItemData.GetPlayerItem(g_pClientPlayer, dwBox, dwIndex)
        end

        if item then
            RemoteCallToServer("On_Recharge_GetGrowedID", item.dwIndex)
        end
    end)

    UIHelper.BindUIEvent(self.BtnAutoFeed, EventType.OnClick, function()
        if not UIMgr.GetView(VIEW_ID.PanelAutoFeed) then
            UIMgr.Open(VIEW_ID.PanelAutoFeed)
        end
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxSearch, function ()
        self:UpdateAllHorseList()
    end)

    UIHelper.BindUIEvent(self.BtnLike, EventType.OnClick, function ()
        local player = GetClientPlayer()
        local dwBox, dwIndex
        if self.szFilter == "Ride" then
            return
        end
        if not self.nQiQuBox or not self.nQiQuIndex then
            return
        end

        dwBox = self.nQiQuBox
        dwIndex = self.nQiQuIndex
        local item = nil
        if dwBox then
            item = ItemData.GetPlayerItem(player, dwBox, dwIndex)
        end

        if item then
            local bCurrentlyPrefer = IsPreferRareHorse(item.dwIndex)
            if not bCurrentlyPrefer then -- 仅在尝试收藏时检查限时条件
                local itemInfo = ItemData.GetItemInfo(item.dwTabType, item.dwIndex)
                if itemInfo and itemInfo.nExistType ~= ITEM_EXIST_TYPE.PERMANENT and item.GetLeftExistTime() > 0 then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_PREFER_QIQUHORSE_TIME_LIMIT)
                    return
                end
            end
            SetPreferRareHorse(item.dwIndex)
        end
    end)
end

function UISaddleHorseView:RegEvent()
    Event.Reg(self,EventType.HorseSlotSelectItem,function (nBox, nIndex, dwItemTabType, dwItemTabIndex)
        self:UpdateHorseSlotSelected(nBox, nIndex, dwItemTabType, dwItemTabIndex)
        UIHelper.SetVisible(self.WidgetClickFeeding, false)
    end)

    Event.Reg(self,"HORSE_ITEM_UPDATE",function (dwBoxIndex, dwX)
        if self.szFilter == "Ride" and dwBoxIndex == INVENTORY_INDEX.HORSE and dwX == self.nIndex or
        self.szFilter ~= "Ride" and dwBoxIndex == self.nQiQuBox and dwX == self.nQiQuIndex then
            if self.dwCurEquipBox == dwBoxIndex and self.dwCurEquipX == dwX and g_pClientPlayer.bOnHorse then
                local item = ItemData.GetPlayerItem(g_pClientPlayer, dwBoxIndex, dwX)
                self:UpdateHungryPercentage(item)
            elseif self.bFeedUpdateHorse or self.szFilter ~= "Ride" then
                self.bFeedUpdateHorse = false
                self:UpdateHorseInfo()
            else
                self:UpdateAllHorseList()
            end
        end
    end)

    Event.Reg(self, "REMOTE_PREFER_RAREHORSE_EVENT", function()
        if self.szFilter ~= "Qiqu" then
            return
        end

        if not self.bPreferRareHorse then
            self:UpdateHorseInfo()
            if self.tScrollListHorse then
                self.tScrollListHorse:UpdateAllCell()
            end
            return
        end

        Timer.AddFrame(self, 3, function ()
            self:UpdatePreferNum()
            self:UpdateAllHorseList()
        end)
    end)

    Event.Reg(self, "ADD_HORSE_EQUIP", function()
        -- self:UpdateHorseBag()
    end)

    Event.Reg(self,"EQUIP_HORSE_EQUIP",function ()
        self:SubCurEquipCount()
        if self.nCurSetEquipCount and self.nCurSetEquipCount == 0 then
            self:UpdateHorseEquip()
            self:UpdateHorseInfo()
            Event.Dispatch(EventType.UpdateHorseEquipBag)
        end
    end)

    Event.Reg(self,"UNEQUIP_HORSE_EQUIP",function ()
        self:SubCurEquipCount()
        if self.nCurSetEquipCount and self.nCurSetEquipCount == 0 then
            self:UpdateHorseEquip()
            self:UpdateHorseInfo()
            Event.Dispatch(EventType.UpdateHorseEquipBag)
        end
    end)

    Event.Reg(self,"UNEQUIP_HORSE",function ()
        self.dwCurEquipBox, self.dwCurEquipX = g_pClientPlayer.GetEquippedHorsePos()
        self:UpdateAllHorseList()
    end)

    Event.Reg(self,"EQUIP_HORSE",function ()
        self.dwCurEquipBox, self.dwCurEquipX = g_pClientPlayer.GetEquippedHorsePos()
        self:UpdateAllHorseList()
    end)

    Event.Reg(self,"SET_HORSE_EQUIP_PRESET_DATA_NOTIFY",function ()
        self:SubOtherEquipCount()
        if self.nSetEquipCount and self.nSetEquipCount == 0 then
            self:UpdateHorseEquip()
            self:UpdateHorseInfo()
            Event.Dispatch(EventType.UpdateHorseEquipBag)
        end
    end)

    Event.Reg(self, EventType.ShowHorseEquipTips, function (nTabType, nTabID, bHave)
        self:ShowHorseEquipTips(nTabType, nTabID, bHave)
    end)

    Event.Reg(self, EventType.EquipHorseEquipBySetID, function (tSetList, bSelected)
        if bSelected then
            for k, dwItemIndex in ipairs(tSetList) do
                self:SelectedHorseEquip(dwItemIndex)
            end
        else
            self:UnEquipHorseEquipBySetID(tSetList)
        end
    end)

    Event.Reg(self, EventType.OnMiniSceneLoadProgress, function(nProcess)
        if nProcess >= 100 and self.hModelView.m_scene and not QualityMgr.bDisableCameraLight then
            self.hModelView.m_scene:OpenCameraLight(QualityMgr.szCameraLightForUI)
        end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        if self.szFilter == "Ride" then
            self.nShowIndex = self.nIndex
            local item = ItemData.GetPlayerItem(g_pClientPlayer, INVENTORY_INDEX.HORSE, self.nIndex)
            if item then
                self.nShowTabType = item.dwTabType
                self.nShowTabID = self.dwTabIndex
            end
        else
            self.nShowTabType = self.dwItemTabType
            self.nShowTabID = self.dwItemTabIndex
        end

        self:UpdateAllHorseList()
    end)

    Event.Reg(self, EventType.OnViewClose, function (nViewID)
        if nViewID == VIEW_ID.PanelRightBag then
            UIHelper.SetVisible(self.WidgetAnchorRight, true)
        end
    end)

    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID == VIEW_ID.PanelExteriorMain then
            UIHelper.TempHideMiniSceneUntilNewViewClose(self, self.MiniScene, nil, VIEW_ID.PanelExteriorMain,nil)
        end
    end)

    Event.Reg(self, EventType.OnWindowsMouseWheel, function()
        local nPercent = UIHelper.GetScrollPercent(self.ScrollViewAtrributeNew)
        if nPercent >= 100 then
            UIHelper.SetVisible(self.WidgetArrowDown, false)
            -- Event.UnReg(self, EventType.OnWindowsMouseWheel)
        end
    end)

    Event.Reg(self, "BAG_ITEM_UPDATE", function(nBox, nIndex)
        self:UpdateClickFeed()
    end)

    Event.Reg(self, "UPDATE_GROW_VALUE", function (nItemNewID, nMaxValue, nCurrentValue)
        local dwBox, dwIndex, tHorse
        if self.szFilter == "Ride" then
            dwBox, dwIndex, tHorse = INVENTORY_INDEX.HORSE, self.nIndex, self.tRideHorse
        else
            dwBox, dwIndex, tHorse = self.nQiQuBox, self.nQiQuIndex, self.tQiQuHorse
        end

        local item = nil
        if dwBox then
            item = ItemData.GetPlayerItem(g_pClientPlayer, dwBox, dwIndex)
        end

        for k, v in ipairs(tHorse) do
            if v.dwX == dwIndex and v.dwBox == dwBox and item and item.dwIndex == nItemNewID then
                v.nMaxValue = nMaxValue
				v.nCurrentValue = nCurrentValue

                self:UpdateHorseInfo()
                break
            end
        end
    end)

    Event.Reg(self, "UPDATE_GROWED_INFO", function(nItemNewID)
        local tTrolltechList = Table_GetTrolltechHorse() or {}

        for k, v in pairs(tTrolltechList) do
            if v.nItemTabIndex == nItemNewID then
                OutputMessage("MSG_ANNOUNCE_YELLOW", v.szGrowedMsg)
                break
            end
        end

        self:InitQiQuHorse()
        self:UpdateAllHorseList()
    end)

    Event.Reg(self, "ON_SET_HORSE_EXTERIOR", function()
        RideExteriorData.UpdateHorseExteriorData()
        self:UpdateRideExterior()
        self:UpdateSaveState()
        self:UpdateExteriorHorseModel()
        if UIMgr.IsViewOpened(VIEW_ID.PanelLeftBag) then
            self:ShowHorseExteriorChoose()
        end
    end)

    Event.Reg(self, "ON_SET_HORSE_EQUIP_EXTERIOR", function()
        RideExteriorData.UpdateHorseExteriorData()
        self:UpdateRideExterior()
        self:UpdateSaveState()
        self:UpdateExteriorHorseModel()
    end)

    Event.Reg(self, "ON_ADD_HORSE_EXTERIOR", function()
        if UIMgr.IsViewOpened(VIEW_ID.PanelLeftBag) then
            self:ShowHorseExteriorChoose()
        end
    end)

    Event.Reg(self, "ON_ADD_HORSE_EQUIP_EXTERIOR", function()
        local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelHorseEquipExterior)
        if scriptView then
            scriptView:UpdateHorseEquipExterior()
        end
    end)

    Event.Reg(self, "PLAYER_MOUNT_HORSE", function()
        self:UpdateSaveState()
    end)
end

function UISaddleHorseView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISaddleHorseView:InitViewInfo()
    self.szFilter = "Ride"
    self.nIndex = 0
    self.dwCurEquipBox, self.dwCurEquipX = g_pClientPlayer.GetEquippedHorsePos()

    self:InitQiQuHorse()
    UIHelper.SetButtonState(self.BtnAlreadly, BTN_STATE.Disable)
end

function UISaddleHorseView:InitQiQuHorse()
    local tRereHorseList = GetRareHorseInfoList()
    local tTrolltechList = Table_GetTrolltechHorse()
    local tNewQiqu = {}

    for _, v in pairs(tRereHorseList) do
        local item = ItemData.GetPlayerItem(g_pClientPlayer, v.dwBox, v.dwX)
        if not item then
            local nNoneHide = self:IsShowQiqu(tTrolltechList, v.dwItemTabIndex)
            if nNoneHide ~= 1 then
                table.insert(tNewQiqu, v)
            end
        else
            table.insert(tNewQiqu, v)
        end
    end

    for _, v in pairs(tNewQiqu) do
        local item = ItemData.GetPlayerItem(g_pClientPlayer, v.dwBox, v.dwX)
        v.nHave = item and 1 or 0
    end

    local fnSort = function(tLeft, tRight)
        local bIsNewL = RedpointHelper.Horse_Qiqu_IsNew(tLeft.dwBox, tLeft.dwX) or false
        local bIsNewR = RedpointHelper.Horse_Qiqu_IsNew(tRight.dwBox, tRight.dwX) or false
        if bIsNewL == bIsNewR then
            if tLeft.nHave == tRight.nHave then
                return tLeft.dwID > tRight.dwID
            end
            return tLeft.nHave > tRight.nHave
        elseif bIsNewL then
            return true
        else
            return false
        end
    end
    table.sort(tNewQiqu, fnSort)

    for k, v in pairs(tNewQiqu) do
        local tLine = Table_GetGrowInfo(v.dwItemTabIndex)
        if tLine then
            v.nShowGrow = tLine.nShowGrow
        end
        local item = ItemData.GetItemInfo(v.dwItemTabType, v.dwItemTabIndex)
        v.szName = UIHelper.GBKToUTF8(Table_GetItemName(item.nUiId))
        local playerItem = ItemData.GetPlayerItem(g_pClientPlayer, v.dwBox, v.dwX)
        v.bLimitTime = item.nExistType ~= ITEM_EXIST_TYPE.PERMANENT and (playerItem ~= nil and playerItem.GetLeftExistTime() > 0 or false)
    end

    self.tQiQuHorse = tNewQiqu
    self.tAllQiQuHorse = self.tQiQuHorse
end

function UISaddleHorseView:IsShowQiqu(tTrolltechList, nItemIndex)
    for _, v in pairs(tTrolltechList) do
        if v.nItemTabIndex == nItemIndex then
            return v.nNoneHide
        end
    end
    return nil
end

function UISaddleHorseView:InitModelView()
    self.hModelView = RidesModelView.CreateInstance(RidesModelView)
    self.hModelView:ctor()
    self.hModelView:init(nil, Const.COMMON_SCENE, "SaddleHorse")

    local tbCamera = UICameraTab["Ride"]["default"]
    self.hModelView:SetCameraPos(unpack(tbCamera.tbCameraPos))
    self.hModelView:SetCameraLookPos(unpack(tbCamera.tbCameraLookPos))
    self.hModelView:SetCameraPerspective(unpack(tbCamera.tbCameraPerspective))

    self.MiniScene:SetScene(self.hModelView.m_scene)
    RidesModelPreview.RegisterHorse(self.MiniScene, self.hModelView, "SaddleHorse_view", "SaddleHorse")

    UITouchHelper.BindModel(self.TouchContainer, self.hModelView)
end

function UISaddleHorseView:UpdatePreferNum()
    local szNum = "已收藏：%d/%d"
    local nPreferNum = GetRemotePreferRareHorse()

    szNum = string.format(szNum, nPreferNum, MAX_PREFER_RAREHORSE_NUM)
    UIHelper.SetString(self.LabelPreferHorseNum, szNum)
    UIHelper.LayoutDoLayout(self.LayoutGetNum)
end

function UISaddleHorseView:UpdateAllHorseList()
    UIHelper.SetVisible(self.WidgetHorseAppearance, false)
    UIHelper.SetVisible(self.WidgetHorseAppearanceCell, false)
    UIHelper.SetVisible(self.ScrollListHorse, true)
    UIHelper.SetVisible(self.WidgetButton, true)
    UIHelper.SetVisible(self.WidgetEdit, true)
    UIHelper.SetVisible(self.WidgetDawn, true)
    UIHelper.SetVisible(self.LayoutGetNum, self.szFilter == "Qiqu" and self.bPreferRareHorse)

    UIHelper.SetVisible(self.WidgetLeftBottomSpecial, self.szFilter == "Qiqu")
    UIHelper.SetVisible(self.WidgetLeftBottom, self.szFilter == "Ride")

    if self.szFilter == "Ride" then
        m_bShowHorseExterior = true
        self:UpdateRideHorseList()
    else
        m_bShowHorseExterior = false
        self:UpdateQiquHorseList()
    end

    if self.szFilter == "Ride" then
        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupSaddleHouseList, self.TogSaddleHouse)
    else
        if self.bPreferRareHorse then
            UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupSaddleHouseList, self.TogCollectedHorse)
        else
            UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupSaddleHouseList, self.TogAllHorse)
        end
    end

    self:SetHorseSlotSelected(self.nShowTabType, self.nShowTabID)
    if self.nShowTabType and self.nShowTabID then
        self.nShowTabType = nil
        self.nShowTabID = nil
    end
    self.nShowIndex = nil
end

function UISaddleHorseView:UpdateRideHorseList()
    self.tRideHorse = {}
    local dwEquipBox, dwEquipX = self.dwCurEquipBox,self.dwCurEquipX
    for nIndex = 0, GLOBAL.HORSE_PACKAGE_SIZE - 1, 1 do
        table.insert(self.tRideHorse,{["dwBox"] = INVENTORY_INDEX.HORSE, ["dwX"] = nIndex, ["szName"] = ""})
        if dwEquipBox == INVENTORY_INDEX.HORSE and nIndex == dwEquipX then
            self.nIndex = nIndex
        end
    end

    for k, v in ipairs(self.tRideHorse) do
        local item = ItemData.GetPlayerItem(g_pClientPlayer, v.dwBox, v.dwX)
        if item then
            local szName = UIHelper.GBKToUTF8(Table_GetItemName(item.nUiId))
            local tLine = Table_GetGrowInfo(item.dwIndex)
            if tLine then
                v.nShowGrow = tLine.nShowGrow
            end
            v.szName = szName
        end
    end

    UIHelper.SetCanSelect(self.TogAppearance, EnableHorseExterior(), "当前未装备普通坐骑,无法对普通坐骑外观进行切换")
    UIHelper.SetCanSelect(self.TogSaddleHouse, true)
    UIHelper.SetVisible(self.WidgetClickFeeding, false)
    UIHelper.SetVisible(self.WidgetDawn, not self.bExterior)
    UIHelper.SetVisible(self.WidgetHorseAppearance, self.bExterior)
    UIHelper.SetVisible(self.WidgetButton, not self.bExterior)
    UIHelper.SetVisible(self.WidgetHorseAppearanceCell, not self.bExterior)
    UIHelper.SetVisible(self.ScrollListHorse, not self.bExterior)
    UIHelper.SetVisible(self.WidgetEdit, not self.bExterior)
    RideExteriorData.UpdateHorseExteriorData()

    if self.bExterior then
        self:UpdateExterior()
    else
        self:UpdateHorse()
    end
end

function UISaddleHorseView:UpdateHorse()
    UIHelper.SetCanSelect(self.TogSpecial, true)
    self:UpdateWearExterior()
    self:UpdateSearchRideHorseList()
    self:UpdateSerachEmptyState(#self.tRideHorse == 0)

    Timer.AddFrame(self, 1, function ()
        if self.tScrollListHorse then
            self.tScrollListHorse:Reset(math.ceil((#self.tRideHorse)/2))
        end
    end)

    RedpointHelper.Horse_SetNew(nil, nil, false)
end

function UISaddleHorseView:UpdateExterior()
    UIHelper.SetCanSelect(self.TogSpecial, false, nil, false)
    self:UpdateRideExterior()
    self:UpdateSaveState()
end

function UISaddleHorseView:UpdateWearExterior()
    local tInfo = RideExteriorData.GetWearRideExterior()
    for k, v in pairs(tInfo) do
        local nIndex = tLogicIndexToUIIndex[k]
        UIHelper.RemoveAllChildren(self.tWearExterior[nIndex])
        local tExteriorInfo = RideExteriorData.GetRideExteriorInfo(v.dwExteriorID, not (k == HORSE_EXTERIOR_INDEX))
        if tExteriorInfo then
            local ItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.tWearExterior[nIndex])
            if ItemIcon then
                ItemIcon:OnInitWithRideExterior(v.dwExteriorID,  k ~= HORSE_EXTERIOR_INDEX)
            end
            ItemIcon:SetClickCallback(function(dwExteriorID, bEquip)
                local tips, scriptTips = TipsHelper.ShowItemTips(ItemIcon._rootNode)
                scriptTips:OnInitRideExterior(dwExteriorID, bEquip)
                scriptTips:SetBtnState({})
                if UIHelper.GetSelected(ItemIcon.ToggleSelect) then
                    UIHelper.SetSelected(ItemIcon.ToggleSelect, false)
                end
            end)
        end
    end
end

function UISaddleHorseView:UpdateSearchRideHorseList()
    local szSearch = UIHelper.GetString(self.EditBoxSearch)

    local tSearchPets = {}
    for _, v in ipairs(self.tRideHorse) do
        if szSearch ~= "" then
            if string.find(v.szName, szSearch) then
                table.insert(tSearchPets, v)
            end
        else
            table.insert(tSearchPets, v)
        end
    end

    self.nIndex = szSearch ~= "" and 0 or self.nIndex
    self.tRideHorse = tSearchPets
end

function UISaddleHorseView:UpdateQiquHorseList()
    self:UpdateSerachQiquHorseList()
    self:UpdateSerachEmptyState(#self.tQiQuHorse == 0)

    Timer.AddFrame(self, 1, function ()
        if self.tScrollListHorse then
            self.tScrollListHorse:Reset(math.ceil((#self.tQiQuHorse)/2))
        end
    end)

    RedpointHelper.Horse_Qiqu_ClearAll()
    UIHelper.SetCanSelect(self.TogAppearance, false, "奇趣坐骑无法应用外观易容")
    UIHelper.SetCanSelect(self.TogSaddleHouse, false, nil, false)
end

function UISaddleHorseView:UpdateSerachQiquHorseList()
    local szSearch = UIHelper.GetString(self.EditBoxSearch)

    local tSearchPets = {}
    if szSearch ~= "" then
        for _, v in ipairs(self.tAllQiQuHorse) do
            if szSearch ~= "" then
                if string.find(v.szName, szSearch) then
                    table.insert(tSearchPets, v)
                end
            else
                table.insert(tSearchPets, v)
            end
        end

        self.nIndex = 0
        self.tQiQuHorse = tSearchPets
    else
        self.tQiQuHorse = self.tAllQiQuHorse
    end

    -- 始终构建收藏列表，用于幽灵占位检查（防止已不可见的坐骑占用收藏栏位）
    local tPreferList = {}
    for _, v in ipairs(self.tQiQuHorse) do
        if IsPreferRareHorse(v.dwItemTabIndex) then
            table.insert(tPreferList, v)
        end
    end
    self:CheckPreferListWithAllHorse(self.tAllQiQuHorse)

    if self.bPreferRareHorse then
        self.tQiQuHorse = tPreferList
    end
end

-- 检查远程收藏中是否存在当前界面不可见的幽灵占位，若有则延时发远调清除
function UISaddleHorseView:CheckPreferListWithAllHorse(tCollectList)
    if not tCollectList then
        return
    end

    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    -- 构建当前可见的收藏坐骑集合
    local tShowSet = {}
    for _, v in ipairs(tCollectList) do
        tShowSet[v.dwItemTabIndex] = v.nHave and v.nHave > 0 or false
    end

    -- 按索引枚举远程收藏数据，找出已收藏但界面不可见的幽灵占位
    local nCount = pPlayer.GetRemoteSetSize(REMOTE_PREFER_RAREHORSE)
    for k = 1, nCount do
        local nHorseIndex = pPlayer.GetRemoteDWordArray(REMOTE_PREFER_RAREHORSE, k - 1)
        if nHorseIndex and nHorseIndex ~= 0 and not tShowSet[nHorseIndex] and not m_tPendingDelHorseSet[nHorseIndex] then
            m_tPendingDelHorseSet[nHorseIndex] = true
            local nIndex = nHorseIndex
            Timer.Add(self, PREFER_RAREHORSE_SET_CD / 1000, function()
                RemoteCallToServer("On_PreferRareHorse_DelPrefer", nIndex)
                m_nLastSetTime = GetTickCount()
                m_tPendingDelHorseSet[nIndex] = nil
            end)
        end
    end
end

function UISaddleHorseView:UpdateSerachEmptyState(bEmpty)
    self:UpdateHorseModel()
    UIHelper.SetVisible(self.WidgetEmptySearch, bEmpty)
    UIHelper.SetVisible(self.WidgetEmptyModel, false)
    UIHelper.SetVisible(self.WidgetAnchorRight, not bEmpty)
end

function UISaddleHorseView:SetHorseSlotSelected(nShowTabType, nShowTabID)
    local dwBox, dwX, dwItemTabType, dwItemTabIndex, nIndex
    if nShowTabType and nShowTabID then
        for k,v in ipairs(self.tQiQuHorse) do
            if v.dwItemTabType == nShowTabType and v.dwItemTabIndex == nShowTabID then
                dwItemTabType, dwItemTabIndex = nShowTabType, nShowTabID
                dwBox, dwX = v.dwBox, v.dwX
                nIndex = k
                break
            end
        end
    else
        if self.szFilter == "Ride" then
            dwBox, dwX = self.tRideHorse[1].dwBox,self.tRideHorse[1].dwX
            if self.nShowIndex then
                dwX = self.tRideHorse[self.nShowIndex + 1].dwX
                nIndex = self.nIndex
            else
                for k,v in ipairs(self.tRideHorse) do
                    if v.dwBox == self.dwCurEquipBox and v.dwX == self.dwCurEquipX then
                        dwBox, dwX = self.dwCurEquipBox, self.dwCurEquipX
                        nIndex = k
                        break
                    end
                end
            end
        else
            dwBox, dwX, dwItemTabType, dwItemTabIndex = self.tQiQuHorse[1].dwBox,self.tQiQuHorse[1].dwX, self.tQiQuHorse[1].dwItemTabType, self.tQiQuHorse[1].dwItemTabIndex
            for k,v in ipairs(self.tQiQuHorse) do
                if self.bPreferRareHorse then
                    if v.dwBox == self.dwCurEquipBox and v.dwX == self.dwCurEquipX and IsPreferRareHorse(v.dwItemTabIndex) then
                        dwBox, dwX = self.dwCurEquipBox, self.dwCurEquipX
                        dwItemTabType, dwItemTabIndex = v.dwItemTabType, v.dwItemTabIndex
                        nIndex = k
                        break
                    end
                else
                    if v.dwBox == self.dwCurEquipBox and v.dwX == self.dwCurEquipX then
                        dwBox, dwX = self.dwCurEquipBox, self.dwCurEquipX
                        dwItemTabType, dwItemTabIndex = v.dwItemTabType, v.dwItemTabIndex
                        nIndex = k
                        break
                    end
                end
            end
        end
    end

    if nIndex then
        Timer.AddFrame(self, 2, function ()
            if self.tScrollListHorse then
                self.tScrollListHorse:ScrollToIndexImmediately(math.ceil(nIndex/2))
            end
        end)
    end

    Timer.AddFrame(self, 5, function ()
        Event.Dispatch(EventType.HorseSlotSelectItem, dwBox, dwX, dwItemTabType, dwItemTabIndex)
    end)
end

function UISaddleHorseView:UpdateHorseSlotSelected(nBox, nIndex, dwItemTabType, dwItemTabIndex)
    if self.szFilter == "Ride" then
        self.nIndex = nIndex
    else
        self.nQiQuBox = nBox
        self.nQiQuIndex = nIndex
        self.dwItemTabType = dwItemTabType
        self.dwItemTabIndex = dwItemTabIndex

        local item = ItemData.GetPlayerItem(g_pClientPlayer, nBox, nIndex)
        if not item then
            local itemInfo = ItemData.GetItemInfo(dwItemTabType,dwItemTabIndex)
            self:UpdateHorseInfo(nil,nil,itemInfo)
            return
        end
    end
    self:UpdateHorseInfo(nBox, nIndex)
end

function UISaddleHorseView:UpdateHorseInfo(dwBox, dwIndex, itemInfo)
    local player = g_pClientPlayer
    if self.szFilter == "Ride" then
        dwBox = INVENTORY_INDEX.HORSE
        dwIndex = self.nIndex
    else
        dwBox = self.nQiQuBox
        dwIndex = self.nQiQuIndex
    end

    local item = nil
    if dwBox then
        item = ItemData.GetPlayerItem(player, dwBox, dwIndex)
    end

    UIHelper.SetVisible(self.ScrollViewAtrributeNew, (item or itemInfo) and true )
    UIHelper.SetVisible(self.WidgetTroughHarness_Empty, (not item and not itemInfo) and true or false)
    UIHelper.SetVisible(self.WidgetArrowDown, (item or itemInfo) and true)

    UIHelper.SetVisible(self.BtnLike, self.szFilter == "Qiqu" and (item or itemInfo) and true or false)
    UIHelper.SetVisible(self.Imglike, false)

    if not item and not itemInfo then
        self:SetNullHorseInfo()
    elseif item then
        self:SetBagHorseInfo(item, dwBox, dwIndex)
    else
        self:SetNullQiQuHorseInfo(itemInfo, dwBox, dwIndex)
    end

    Timer.AddFrame(self, 1, function ()
        UIHelper.LayoutDoLayout(self.LayoutContent)
        UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewAtrributeNew, true, true)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAtrributeNew)
    end)

    self:UpdateHorseModel(item or itemInfo)
    self:UpdateClickFeed()
end

function UISaddleHorseView:UpdateHorseModel(itemInfo)
    local player = g_pClientPlayer
    local tbRepresentID = player.GetRepresentID()

    self.itemInfo = itemInfo

    if itemInfo and itemInfo.nGenre == ITEM_GENRE.EQUIPMENT and itemInfo.nSub == EQUIPMENT_SUB.HORSE then
        tbRepresentID[EQUIPMENT_REPRESENT.HORSE_STYLE] = itemInfo.nRepresentID
    else
        tbRepresentID[EQUIPMENT_REPRESENT.HORSE_STYLE] = 0
    end

    for i = 1,HORSE_ADORNMENT_COUNT do
        local nRepresentID = EQUIPMENT_REPRESENT["HORSE_ADORNMENT" .. i]
        if itemInfo and itemInfo.nDetail == 0 then
            local dwIndex = self:GetEquipItemIndex(i)
            if dwIndex and dwIndex ~= 0 then
                local itemEquip = ItemData.GetItemInfo(dwHorseEquipType, dwIndex)
                tbRepresentID[nRepresentID] = itemEquip.nRepresentID
            else
                tbRepresentID[nRepresentID] = 0
            end
        else
            tbRepresentID[nRepresentID] = 0
        end
    end

    if m_bShowHorseExterior then
		local tExterior = RideExteriorData.tOriginalExterior
		if m_bShowHorseExterior then
			tExterior = RideExteriorData.tPreviewExterior
		end
		UpdateExteriorRepresentID(tbRepresentID, tExterior)
	end

    self.hModelView:UnloadRidesModel()
    UIHelper.SetVisible(self.WidgetEmptyModel, true)
    if tbRepresentID[EQUIPMENT_REPRESENT.HORSE_STYLE] == 0 then
        return
    end

    local tbCamera = UICameraTab["Ride"][itemInfo.nUiId] or UICameraTab["Ride"]["default"]

    UIHelper.SetVisible(self.WidgetEmptyModel, false)
    self.hModelView:LoadResByRepresent(tbRepresentID, false)
    self.hModelView:LoadRidesModel()
    self.hModelView:PlayRidesAnimation("Idle", "loop")
    self.hModelView:SetCameraPos(unpack(tbCamera.tbCameraPos))
    self.hModelView:SetCameraLookPos(unpack(tbCamera.tbCameraLookPos))
    self.hModelView:SetCameraPerspective(unpack(tbCamera.tbCameraPerspective))
    self.hModelView:SetTranslation(unpack(tbCamera.tbModelTranslation))

    local fScale = Const.MiniScene.RideScale
    self.hModelView:SetScaling(fScale, fScale, fScale)
    self.hModelView:SetYaw(tbCamera.nModelYaw)
    self.hModelView:SetMainFlag(true)   -- 接收光照、阴影等

    -- 设置镜头光正确的坐标
    self.hModelView.m_scene:SetMainPlayerPosition(unpack(tbCamera.tbModelTranslation))
    UITouchHelper.BindModel(self.TouchContainer, self.hModelView)
end

function UISaddleHorseView:UpdateExteriorHorseModel()
	local hPlayer = GetClientPlayer()
	local dwBox, dwX = hPlayer.GetEquippedHorsePos()

    if dwBox == self.dwCurEquipBox and dwX == self.dwCurEquipX then
        local player = g_pClientPlayer
        local item = ItemData.GetPlayerItem(player, dwBox, dwX)
        self:UpdateHorseModel(item)
    end
end

--普通坐骑里的空位
function UISaddleHorseView:SetNullHorseInfo()
    self.scriptQualityBar = self.scriptQualityBar or UIHelper.AddPrefab(PREFAB_ID.WidgetQualityBar, self.WidgetTittle, 2)
    if self.scriptQualityBar then
        self.scriptQualityBar:OnEnter(2)
    end
    UIHelper.SetSpriteFrame(self.ImgDawnTitle1, HorseTitleQualityBGColor[0])

    UIHelper.SetString(self.LabelDawn, g_tStrings.STR_HORSE_EMPTY_BOX)
    UIHelper.SetString(self.LabelDescibe01,g_tStrings.STR_HORSE_EMPTY_BOX_DES)
    UIHelper.SetVisible(self.BtnSendToChat, false)
    UIHelper.SetVisible(self.WidgetTraceDesTitle, false)
    UIHelper.SetVisible(self.LayoutTrace, false)

    for _,widget in ipairs(self.tWidgetGoods) do
        UIHelper.RemoveAllChildren(widget)
    end

    self:UpdateHorseEquip()

    -- UIHelper.LayoutDoLayout(self.LayoutContent)

    self:UpdateBtnState(false)
end

--背包里有的坐骑
function UISaddleHorseView:SetBagHorseInfo(item,dwBox,dwIndex)
    self.scriptQualityBar = self.scriptQualityBar or UIHelper.AddPrefab(PREFAB_ID.WidgetQualityBar, self.WidgetTittle, (item.nQuality or 1) + 1)
    if self.scriptQualityBar then
        self.scriptQualityBar:OnEnter((item.nQuality or 1) + 1)
    end

    local szName = UIHelper.GBKToUTF8(Table_GetItemName(item.nUiId))
    UIHelper.SetString(self.LabelDawn, szName)
    UIHelper.SetVisible(self.BtnSendToChat, true)
    -- 发送到聊天频道
    UIHelper.BindUIEvent(self.BtnSendToChat, EventType.OnClick, function()
        ChatHelper.SendItemToChat(item.dwID)
    end)

    self:UpdateHungryPercentage(item)
    self:UpdateGrowInfo(item)
    UIHelper.SetVisible(self.WidgetTroughHarness, self.szFilter == "Ride")
    if self.szFilter == "Ride" then
        self:UpdateHorseEquip()
    end

    -- UIHelper.LayoutDoLayout(self.LayoutContent)

    self:UpdateHorseAttribute(item)
    self:UpdateHorseSource(item.dwTabType, item.dwIndex)

    if self.dwCurEquipBox == dwBox and self.dwCurEquipX == dwIndex then
        self:UpdateBtnState(true,true, nil, nil, item)
    else
        self:UpdateBtnState(true,false, nil, nil, item)
    end

    local bPrefer = IsPreferRareHorse(item.dwIndex)
    UIHelper.SetVisible(self.Imglike, bPrefer)
end

--未拥有的奇趣坐骑
function UISaddleHorseView:SetNullQiQuHorseInfo(itemInfo, dwBox, dwIndex)
    self.scriptQualityBar = self.scriptQualityBar or UIHelper.AddPrefab(PREFAB_ID.WidgetQualityBar, self.WidgetTittle, (itemInfo.nQuality or 1) + 1)
    if self.scriptQualityBar then
        self.scriptQualityBar:OnEnter((itemInfo.nQuality or 1) + 1)
    end

    local szName = UIHelper.GBKToUTF8(Table_GetItemName(itemInfo.nUiId))
    UIHelper.SetString(self.LabelDawn,szName)
    UIHelper.SetVisible(self.BtnSendToChat, true)
    -- 发送到聊天频道
    UIHelper.BindUIEvent(self.BtnSendToChat, EventType.OnClick, function()
        ChatHelper.SendItemInfoToChat(nil, self.dwItemTabType, self.dwItemTabIndex)
    end)

    UIHelper.SetVisible(self.WidgetProgressBar, false)
    UIHelper.SetVisible(self.WidgetTroughHarness, false)
    UIHelper.SetVisible(self.WidgetProgressBar2, false)
    -- UIHelper.LayoutDoLayout(self.LayoutContent)

    self:UpdateHorseAttribute(itemInfo,true)
    self:UpdateHorseSource()

    local bEnableBuy = _G.CoinShop_HorseIsInShop(self.dwItemTabType,self.dwItemTabIndex)
    self:UpdateBtnState(false,false,true,bEnableBuy)
end

function UISaddleHorseView:UpdateBtnState(bItem, bSet, bNilHorse, bCanBuy, hItem)
    if self.szFilter == "Ride" then
        if bItem == true then
            UIHelper.SetVisible(self.BtnSet,not bSet)
            UIHelper.SetVisible(self.BtnAlreadly,bSet)
        else
            UIHelper.SetVisible(self.BtnSet,bItem)
            UIHelper.SetVisible(self.BtnAlreadly,bItem)
        end
        UIHelper.SetVisible(self.BtnSetQiQu,false)
        UIHelper.SetVisible(self.BtnQiQuAlreadly,false)
        UIHelper.SetVisible(self.BtnRemove,bItem)
        UIHelper.SetVisible(self.BtnPut,not bItem)
        UIHelper.SetVisible(self.BtnBuy,false)
    else
        -- 奇趣坐骑：判断是否可以卸下
        local bCanUnequip = hItem and hItem.CheckIgnoreBindMask and hItem.CheckIgnoreBindMask(ITEM_IGNORE_BIND_TYPE.TONG) or false

        UIHelper.SetVisible(self.BtnPut,false)
        UIHelper.SetVisible(self.BtnBuy,bCanBuy and true or false)

        if bCanUnequip then
            -- 可卸下的奇趣坐骑：使用普通坐骑的按钮布局
            UIHelper.SetVisible(self.BtnSetQiQu,false)
            UIHelper.SetVisible(self.BtnQiQuAlreadly,false)
            UIHelper.SetVisible(self.BtnRemove, bItem)
            if bItem then
                if bSet then
                    UIHelper.SetVisible(self.BtnSet,false)
                    UIHelper.SetVisible(self.BtnAlreadly,true)
                else
                    UIHelper.SetVisible(self.BtnSet,true)
                    UIHelper.SetVisible(self.BtnAlreadly,false)
                end
            else
                UIHelper.SetVisible(self.BtnSet,false)
                UIHelper.SetVisible(self.BtnAlreadly,false)
            end
        else
            -- 不可卸下的奇趣坐骑：保持原有逻辑
            UIHelper.SetVisible(self.BtnSet,false)
            UIHelper.SetVisible(self.BtnAlreadly,false)
            UIHelper.SetVisible(self.BtnRemove,false)
            if bSet then
                UIHelper.SetVisible(self.BtnSetQiQu,false)
                UIHelper.SetVisible(self.BtnQiQuAlreadly,true)
            elseif not bNilHorse then
                UIHelper.SetVisible(self.BtnSetQiQu,bItem)
                UIHelper.SetVisible(self.BtnQiQuAlreadly,not bItem)
            else
                UIHelper.SetVisible(self.BtnSetQiQu,false)
                UIHelper.SetVisible(self.BtnQiQuAlreadly,false)
            end
        end
    end
end

function UISaddleHorseView:UpdateHungryPercentage(item)
    if not item then
        return
    end

    UIHelper.SetVisible(self.WidgetProgressBar,true)

    local nFullLevel = item.GetHorseFullLevel()
    local itemInfo = ItemData.GetItemInfo(item.dwTabType, item.dwIndex)
    local tDisplay = Table_GetRideSubDisplay(itemInfo.nDetail)
    local szHungry = UIHelper.GBKToUTF8(tDisplay["szFullMeasure" .. (nFullLevel + 1)])

    if nFullLevel == FULL_LEVEL.FULL then
        UIHelper.SetRichText(self.LabelPercent, "<color=#d7f6ff>" .. szHungry .."</color>")
    elseif nFullLevel == FULL_LEVEL.HALF_HUNGRY then
        UIHelper.SetRichText(self.LabelPercent, "<color=#ffe26e>" .. szHungry .."</color>")
    elseif nFullLevel == FULL_LEVEL.HUNGRY then
        UIHelper.SetRichText(self.LabelPercent, "<color=#ff7676>" .. szHungry .."</color>")
    end

    local fCurFullMeasure = item.GetHorseFullMeasure()
    local fMaxFullMeasure = item.GetHorseMaxFullMeasure()
    UIHelper.SetString(self.LabelNum1,fCurFullMeasure)
    UIHelper.SetString(self.LabelNum2,"/"..fMaxFullMeasure)
    UIHelper.SetProgressBarPercent(self.ProgressBar, 100 * fCurFullMeasure / fMaxFullMeasure)
    UIHelper.SetString(self.LabelEnough, "(".. string.format("%.0f", math.ceil(fCurFullMeasure / fMaxFullMeasure * 100)) .. "%)")
end

function UISaddleHorseView:UpdateGrowInfo(item)
    local dwBox, dwIndex, tHorse
    if self.szFilter == "Ride" then
        dwBox, dwIndex, tHorse = INVENTORY_INDEX.HORSE, self.nIndex, self.tRideHorse
    else
        dwBox, dwIndex, tHorse = self.nQiQuBox, self.nQiQuIndex, self.tQiQuHorse
    end

    for k, v in ipairs(tHorse) do
        if v.dwX == dwIndex and v.dwBox == dwBox then
            if v.nShowGrow == 1 and not v.nMaxValue then
                RequestGrowInfo(item.dwIndex)
            elseif v.nShowGrow == 1 and v.nMaxValue and v.nCurrentValue then
                local tLine = Table_GetGrowInfo(item.dwIndex)

                self.szGrowTip = UIHelper.GBKToUTF8(tLine.szTip)

                UIHelper.SetVisible(self.BtnUp, v.nMaxValue == v.nCurrentValue)
                UIHelper.SetVisible(self.BtnDes, v.nMaxValue ~= v.nCurrentValue)

                UIHelper.SetString(self.LabelGrowth1, v.nCurrentValue)
                UIHelper.SetString(self.LabelGrowth2,"/"..v.nMaxValue)
                UIHelper.SetProgressBarPercent(self.ProgressBar_Growth, 100 * v.nCurrentValue / v.nMaxValue)
                -- UIHelper.SetString(self.LabelEnough, "(".. string.format("%.0f", fCurFullMeasure / fMaxFullMeasure * 100) .. "%)")
            end

            UIHelper.SetVisible(self.WidgetProgressBar2, v.nShowGrow == 1)
        end
    end
end

function UISaddleHorseView:GetCurHorseShowGrow()
    local dwBox, dwIndex, tHorse
    if self.szFilter == "Ride" then
        dwBox, dwIndex, tHorse = INVENTORY_INDEX.HORSE, self.nIndex, self.tRideHorse
    else
        dwBox, dwIndex, tHorse = self.nQiQuBox, self.nQiQuIndex, self.tQiQuHorse
    end

    for k, v in ipairs(tHorse) do
        if v.dwX == dwIndex and v.dwBox == nMaxValue then
            return v.nShowGrow == 1
        end
    end

    return false
end

function UISaddleHorseView:UpdateClickFeed()
    self.scriptFeeding = self.scriptFeeding or UIHelper.AddPrefab(PREFAB_ID.WidgetClickFeeding, self.WidgetClickFeeding)
    if self.scriptFeeding then
        local GetFeedList = self:GetFeedList()

        local parent = self.scriptFeeding.ScrollViewList
        if #GetFeedList <= 4 then
            parent = self.scriptFeeding.LayoutItemListSigleLine
        end

        UIHelper.RemoveAllChildren(parent)

        for k, tInfo in ipairs(GetFeedList) do
            local tbItemInfo = ItemData.GetItemInfo(tInfo.dwTabType, tInfo.dwIndex)
            local szName = UIHelper.GBKToUTF8(Table_GetItemName(tbItemInfo.nUiId))
            local nStackNum = 0
            if tInfo.dwBox and tInfo.dwX then
                local hItem = g_pClientPlayer.GetItem(tInfo.dwBox, tInfo.dwX)
                nStackNum = ItemData.GetItemStackNum(hItem)
            end
            local itemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetAwardItem1, parent, szName, "+"..tbItemInfo.nDetail, tInfo.dwTabType, tInfo.dwIndex, false)
            if itemIcon then
                if nStackNum > 0 then
                    itemIcon:SetIconCount(nStackNum)
                end

                itemIcon:SetClickCallback(function (dwTabType, dwIndex)
                    if nStackNum > 0 then
                        self:Feed(tInfo.dwBox, tInfo.dwX)
                    else
                        local tips, scriptItemTip = TipsHelper.ShowItemTips(itemIcon._rootNode, dwTabType, dwIndex, false)
                        local tInfo = Table_GetFeedItemInfo(dwTabType, dwIndex)
                        local tbBtnState = {{
                            szName = g_tStrings.STR_BUY_FEED_BTN,
                            OnClick = function ()
                                ShopData.OpenSystemShopGroup(tInfo.dwGroup, tInfo.dwShopID, tInfo.dwTabType, tInfo.dwIndex)
                                TipsHelper.DeleteAllHoverTips()
                            end
                        }}

                        scriptItemTip:SetBtnState(tInfo.bShop and tbBtnState or {})

                        if not tInfo.bShop then
                            TipsHelper.ShowNormalTip(g_tStrings.STR_NOT_BUY_FEED_TIPS)
                        end
                    end
                end)

                itemIcon:ClearItemClickCallback()
                itemIcon:ShowBindIcon(tInfo.bBind)
                itemIcon:SetIconGray(nStackNum == 0 and true or false)
                itemIcon:SetIconOpacity(nStackNum == 0 and 120 or 255)
            end
        end

        UIHelper.SetVisible(self.scriptFeeding.WidgetScroll, #GetFeedList > 4)
        UIHelper.SetVisible(self.scriptFeeding.WidgetSigleLine, #GetFeedList <= 4)
        UIHelper.SetVisible(self.scriptFeeding.WidgetGoAutoFeed, true)

        if #GetFeedList > 4 then
            UIHelper.ScrollViewDoLayoutAndToTop(self.scriptFeeding.ScrollViewList)
        else
            UIHelper.LayoutDoLayout(self.scriptFeeding.LayoutItemListSigleLine)
        end

        UIHelper.BindUIEvent(self.scriptFeeding.ButtonClose, EventType.OnClick, function ()
            UIHelper.SetVisible(self.WidgetClickFeeding, false)
        end)

        UIHelper.BindUIEvent(self.scriptFeeding.BtnGoAuto, EventType.OnClick, function ()
            if not UIMgr.GetView(VIEW_ID.PanelAutoFeed) then
                UIMgr.Open(VIEW_ID.PanelAutoFeed)
            end
        end)
    end
end

function UISaddleHorseView:GetFeedList()
    local tInfo = Table_GetFeedItemList()
    local tFlag = {}
    local tFeedList = {}

    local pPlayer = PlayerData.GetClientPlayer()

    for _, dwBox in pairs(GetPackageIndex()) do
        local nSize = pPlayer.GetBoxSize(dwBox)
        for dwX = 0, nSize - 1 do
            local pItem = ItemData.GetPlayerItem(pPlayer, dwBox, dwX)
            if pItem and self:fnHouseBagFilter(pItem) then
                local tIndex = {dwBox = dwBox, dwX = dwX, dwTabType = pItem.dwTabType, dwIndex = pItem.dwIndex, bBind = pItem.bBind}
                tFlag[pItem.dwIndex] = true

                local bHave = false
                for k, tFeed in ipairs(tFeedList) do
                    if tFeed.dwIndex == tIndex.dwIndex and tFeed.dwTabType == tIndex.dwTabType then
                        bHave = true
                    end
                end
                if not bHave then
                    table.insert(tFeedList, tIndex)
                end
            end
        end
    end

    table.sort(tFeedList, function (tA, tB)
        if tA.bBind == tB.bBind then
            return false
        elseif tA.bBind then
            return true
        end
        return false
    end)

    local tTemp = {}
    for i = 1, #tInfo do
        if not tFlag[tInfo[i].dwIndex] then
            local KItemInfo = ItemData.GetItemInfo(tInfo[i].dwTabType, tInfo[i].dwIndex)
            if self:fnHouseBagFilter(KItemInfo) then
                table.insert(tTemp, tInfo[i])
            end
        end
    end

    table.sort(tTemp, function (tA, tB)
        return tA.nPriority < tB.nPriority
    end)

    for i = 1, #tTemp do
        table.insert(tFeedList, tTemp[i])
    end

    return tFeedList
end

function UISaddleHorseView:fnHouseBagFilter(pItem)
    local hItem
    if self.szFilter == "Ride" then
        hItem = ItemData.GetItemByPos(INVENTORY_INDEX.HORSE,self.nIndex)
    else
        hItem = ItemData.GetItemByPos(self.nQiQuBox,self.nQiQuIndex)
    end

    if hItem then
        return hItem.nDetail and pItem.nGenre == ITEM_GENRE.FODDER and IsHorseFodderMatch(hItem.nDetail, pItem.nSub)
    end
end

function UISaddleHorseView:UpdateHorseEquip()
    self.HorseEquipItem = {}

    for i = 1, HORSE_ADORNMENT_COUNT do
        local dwIndex = self:GetEquipItemIndex(i)
        UIHelper.RemoveAllChildren(self.tWidgetGoods[i])
        UIHelper.RemoveAllChildren(self.tWidgetGoods[i + HORSE_ADORNMENT_COUNT])
        if dwIndex and dwIndex ~= 0 then
            local item = ItemData.GetPlayerItem(g_pClientPlayer, INVENTORY_INDEX.HORSE, self.nIndex)
            local ItemIcon
            if item then
                ItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80,self.tWidgetGoods[i])
            else
                ItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80,self.tWidgetGoods[i + HORSE_ADORNMENT_COUNT])
            end

            if ItemIcon then
                ItemIcon:OnInitWithTabID(dwHorseEquipType, dwIndex)
                ItemIcon:SetClickCallback(function (nTabType,nTabID)
                    self:ShowHorseEquipTips(nTabType, nTabID, true)
                    if UIHelper.GetSelected(ItemIcon.ToggleSelect) then
                        UIHelper.SetSelected(ItemIcon.ToggleSelect, false)
                    end
                end)

                self.HorseEquipItem[i] = ItemIcon
            end
        end
    end
end

function UISaddleHorseView:UpdateRideExterior()
    local tInfo = RideExteriorData.tPreviewExterior
    for k, v in pairs(tInfo) do
        local nIndex = tLogicIndexToUIIndex[k]
        UIHelper.RemoveAllChildren(self.tWidgetExterior[nIndex])
        local tExteriorInfo = RideExteriorData.GetRideExteriorInfo(v, k ~= HORSE_EXTERIOR_INDEX)
        if tExteriorInfo then
            local ItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.tWidgetExterior[nIndex])
            if ItemIcon then
                ItemIcon:OnInitWithRideExterior(v, k ~= HORSE_EXTERIOR_INDEX)
            end
            ItemIcon:SetClickCallback(function(dwExteriorID, bEquip)
                LOG.TABLE({dwExteriorID, bEquip})
                local tips, scriptTips = TipsHelper.ShowItemTips(ItemIcon._rootNode)
                scriptTips:OnInitRideExterior(dwExteriorID, bEquip)
                scriptTips:SetBtnState({})
                if UIHelper.GetSelected(ItemIcon.ToggleSelect) then
                    UIHelper.SetSelected(ItemIcon.ToggleSelect, false)
                end
            end)
        end
        UIHelper.SetVisible(self.tRecall[nIndex], v ~= 0)
    end
    self:UpdateRideExteriorInfo()
end

function UISaddleHorseView:UpdateRideExteriorInfo()
    local tInfo = RideExteriorData.tPreviewExterior
    for k, v in pairs(tInfo) do
        local nIndex = tLogicIndexToUIIndex[k]
        local tExteriorInfo = RideExteriorData.GetRideExteriorInfo(v, k ~= HORSE_EXTERIOR_INDEX)
        local LayoutItem = self.tExteriorInfo[nIndex]
        local szSuffix = nIndex
        if k == HORSE_EXTERIOR_INDEX then
            szSuffix = ""
        end
        local LabelName = UIHelper.GetChildByName(LayoutItem, "LabelAppearanceName" .. szSuffix)
        local LableState = UIHelper.GetChildByName(LayoutItem, "LabelAppearanceState" .. szSuffix)
        local LablePart = UIHelper.GetChildByName(LayoutItem, "LabelAppearancePart" .. szSuffix)
        UIHelper.SetVisible(LabelName, tExteriorInfo ~= nil)
        UIHelper.SetVisible(LableState, tExteriorInfo ~= nil)
        UIHelper.SetVisible(LablePart, tExteriorInfo == nil)
        if tExteriorInfo then
            UIHelper.SetString(LabelName, tExteriorInfo.szName, 5)
            local szState = g_tStrings.STR_HORSE_EXTERIOR_FILTER[4]
            if tExteriorInfo.bHave then
                szState = g_tStrings.STR_HORSE_EXTERIOR_FILTER[2]
            elseif tExteriorInfo.bCollected then
                szState = g_tStrings.STR_HORSE_EXTERIOR_FILTER[3]
            end
            UIHelper.SetString(LableState, szState, 7)
        end
        UIHelper.LayoutDoLayout(LayoutItem)
    end
end

function UISaddleHorseView:UpdateSaveState()
    local pPlayer = GetClientPlayer()
	local bReset = not IsTableEqual(RideExteriorData.tPreviewExterior, RideExteriorData.tOriginalExterior)
	local bCanSave = not IsTableEqual(RideExteriorData.tPreviewExterior, RideExteriorData.tOriginalExterior)
    local bAllHave = true
	for k, v in pairs(RideExteriorData.tPreviewExterior) do
		local bIsHave = true
		local bIsCollected = true
        local tExteriorInfo = RideExteriorData.GetRideExteriorInfo(v, k ~= RideExteriorData.HORSE_EXTERIOR_INDEX)
        if tExteriorInfo then
            bIsHave = tExteriorInfo.bHave
            bIsCollected = tExteriorInfo.bCollected
        end
        if not bIsHave then
			bAllHave = false
		end
		if (not bIsHave) and (not bIsCollected) then
			bCanSave = false
			break
		end
	end
    local bNormal = bCanSave and (not pPlayer.bOnHorse)
    local szTip = ""
    if pPlayer.bOnHorse then
		szTip = g_tStrings.STR_CAN_NOT_OPERATE_IN_RIDE
	else
		szTip = g_tStrings.STR_NO_SAVE_HORSE_EXTERIOR_TIP
	end 
    UIHelper.SetButtonState(self.BtnPresets, bNormal and BTN_STATE.Normal or BTN_STATE.Disable, szTip)
    UIHelper.SetButtonState(self.BtnReset, bReset and BTN_STATE.Normal or BTN_STATE.Disable)
    local szBtnText = bAllHave and g_tStrings.STR_RIDE_EXTERIOR_SAVE or g_tStrings.STR_RIDE_EXTERIOR_BUY_AND_SAVE
    UIHelper.SetString(self.LabelPresets, szBtnText)
end

function UISaddleHorseView:GetEquipItemIndex(nIndex)
    local bCurrent = false
    local dwEquipBox, dwEquipX = self.dwCurEquipBox, self.dwCurEquipX
    if INVENTORY_INDEX.HORSE == dwEquipBox and self.nIndex == dwEquipX then
        bCurrent = true
    end

    if bCurrent then
        local nEquipX = tEquipIndex[nIndex]
        local hAdornment = g_pClientPlayer.GetEquippedHorseEquip(nEquipX)
        if hAdornment then
            return hAdornment.dwIndex
        end
    else
        local tHorseEquip = g_pClientPlayer.GetHorseEquipPresetData(self.nIndex)
        local dwIndex = 0
        if tHorseEquip then
            dwIndex = tHorseEquip[nIndex - 1]
        end
        return dwIndex
    end
end

function UISaddleHorseView:UpdateHorseAttribute(item, bNotHave) --第二个参数，背包里没有的奇趣
    if not item then
        return
    end

    self:UpdateTimeLimit(item, bNotHave)
    self:GetHorseAttribute(item, bNotHave)
    self:UpdateBaseAndMagicAttribute(item, bNotHave)
    self:UpdateHorseLevel(item)

    Timer.AddFrame(self, 1, function ()
        UIHelper.LayoutDoLayout(self.LayoutAtrribute_Base)
        UIHelper.LayoutDoLayout(self.LayoutAtrribute_Special)
        UIHelper.LayoutDoLayout(self.LayoutContent)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAtrributeNew)
    end)
end

function UISaddleHorseView:UpdateTimeLimit(item, bNotHave)
    local szTimeLimit = nil
    local nLeftTime = 0

    if not bNotHave then
        local itemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
        nLeftTime = item.GetLeftExistTime()

        if itemInfo.nExistType == ITEM_EXIST_TYPE.OFFLINE then
            if nLeftTime > 0 then
                local szTime = UIHelper.GetDeltaTimeText(nLeftTime)
                szTimeLimit = string.format(g_tStrings.STR_ITEM_OFF_LINE_TIME_OVER, szTime)
            else
                szTimeLimit = g_tStrings.STR_ITEM_TIME_TYPE1
            end
        elseif itemInfo.nExistType == ITEM_EXIST_TYPE.ONLINE then
            if nLeftTime > 0 then
                local szTime = UIHelper.GetDeltaTimeText(nLeftTime)
                szTimeLimit = string.format(g_tStrings.STR_ITEM_ON_LINE_TIME_OVER, szTime)
            else
                szTimeLimit = g_tStrings.STR_ITEM_TIME_TYPE2
            end
        elseif itemInfo.nExistType == ITEM_EXIST_TYPE.ONLINEANDOFFLINE or itemInfo.nExistType == ITEM_EXIST_TYPE.TIMESTAMP then
            if nLeftTime > 0 then
                if not self.bIsPlayStore then
                    local szTime = UIHelper.GetDeltaTimeText(nLeftTime)
                    szTimeLimit = string.format(g_tStrings.STR_ITEM_TIME_OVER, szTime)
                else
                    local nFullTime = math.ceil(nLeftTime / 86400) * 86400
                    local szTime = UIHelper.GetDeltaTimeText(nFullTime)
                    szTimeLimit = string.format("<color=#FF857D>限时道具，购买%s后删除</c>", szTime)
                end
            else
                szTimeLimit = g_tStrings.STR_ITEM_TIME_TYPE3
            end
        end

        UIHelper.SetRichText(self.RichTimeLimit, szTimeLimit)
    end

    UIHelper.SetVisible(self.RichTimeLimit, szTimeLimit and true or false)

    if szTimeLimit then
        self.nTimeLimitTimerID = self.nTimeLimitTimerID or Timer.AddCountDown(self, nLeftTime, function()
            self:UpdateTimeLimit(item, bNotHave)
        end, function()
            self.nTimeLimitTimerID = nil
        end)
    else
        Timer.DelTimer(self, self.nTimeLimitTimerID)
        self.nTimeLimitTimerID = nil
    end
end

function UISaddleHorseView:GetHorseAttribute(item, bNotHave)
    self.tAllAttr = {}
    local baseAttib = item.GetBaseAttrib()
    local nRepresentID = item.nRepresentID
    for _, v in pairs(baseAttib) do
        local nID = v.nID
        local nValue1 = v.nValue1 or v.nMin
        local nValue2 = v.nValue2 or v.nMax
        local dwID, dwLevel, nValue = FromHMagicInfo_To_HSkill_ID_lv(nID, nValue1, nValue2,nRepresentID)
        table.insert(self.tAllAttr, {dwID, dwLevel, nValue})
    end

    local magicAttib
    if not bNotHave then
        magicAttib = item.GetMagicAttrib()
    else
        magicAttib = GetItemMagicAttrib(item.GetMagicAttribIndexList())
    end

    for _, v in pairs(magicAttib) do
        local nID = v.nID
        local nValue1 = v.nValue1 or v.Param0
        local nValue2 = v.nValue2 or v.Param2
        local dwID, dwLevel, nValue = FromHMagicInfo_To_HSkill_ID_lv(nID, nValue1, nValue2,nRepresentID)
        table.insert(self.tAllAttr, {dwID, dwLevel, nValue})
    end
end

function UISaddleHorseView:UpdateBaseAndMagicAttribute(item, bNotHave)
    self.tbBaseAttributeCells = self.tbBaseAttributeCells or {}
    self.tbAttributeCells = self.tbAttributeCells or {}
    UIHelper.HideAllChildren(self.LayoutSkill_Base)
    UIHelper.HideAllChildren(self.LayoutSkill_Specail)

    local szName, szBaseAttrTips, szAttrTips = "", "", ""
    for i, tab in ipairs(self.tAllAttr) do
        local dwID, nLevel, nValue = tab[1], tab[2], tab[3]
        local tAttr = clone(Table_GetHorseChildAttr(dwID, nLevel))
        local tAttrCells, parent = {}, nil

        if tAttr then
            tAttr.nValue = nValue
            tAttr.nLevel = nLevel
            szName, szAttrTips = self:OutputHorseChildAttrTip(tAttr)

            if tAttr.nType == 0 then
                szBaseAttrTips = szBaseAttrTips == "" and szAttrTips or szBaseAttrTips.."\n"..szAttrTips
                tAttrCells = self.tbBaseAttributeCells
                parent = self.LayoutSkill_Base
            elseif tAttr.nType == 1 then
                tAttrCells = self.tbAttributeCells
                parent = self.LayoutSkill_Specail
            end

            if not bNotHave then
                local nCurrentFullMeasure = item.GetHorseFullMeasure()
                if tAttr.bRelateFeed and nCurrentFullMeasure == 0 then
                    tAttr.bHurry = true
                end
            end

            local szFeedTip = ""
            if tAttr.bHurry and not tAttr.bIgnoreHungry then
                szFeedTip = tAttr.szFeedTip
                szFeedTip = ParseTextHelper.ConvertRichTextFormat(UIHelper.GBKToUTF8(szFeedTip))
                UIHelper.SetRichText(self.RichHungryWarning, "<color=#ff7676> 坐骑属性衰减, 通过喂食可以提高饱食度 </color>" )
            end
            UIHelper.SetVisible(self.RichHungryWarning, szFeedTip ~= "")

            if not tAttrCells[i] then
                tAttrCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetLevelContent, parent, szName, szAttrTips, tAttr.nIconID, szFeedTip)
            else
                tAttrCells[i]:OnEnter(szName, szAttrTips, tAttr.nIconID, szFeedTip)
                UIHelper.SetVisible(tAttrCells[i]._rootNode, true)
            end
        end
    end

    UIHelper.SetVisible(self.RichTextBasicAttrib, szBaseAttrTips ~= "")
    UIHelper.SetRichText(self.RichTextBasicAttrib, "<color=#d7f6ff>" .. szBaseAttrTips .. "</color>")

    UIHelper.LayoutDoLayout(self.LayoutSkill_Base)
    UIHelper.LayoutDoLayout(self.LayoutSkill_Specail)
end

function UISaddleHorseView:OutputHorseChildAttrTip(tAttr, bMagic)
    if tAttr then
        local szChildTip = UIHelper.GBKToUTF8(FormatString(tAttr.szTip, tAttr.nValue)) or ""
        szChildTip = ParseTextHelper.ParseNormalText(szChildTip, true)
        if tAttr.nLevel == 0 then
            return UIHelper.GBKToUTF8(tAttr.szName), szChildTip
        else
            return UIHelper.GBKToUTF8(tAttr.szName).."  "..tAttr.nLevel.."级", szChildTip
        end
    end
end

function UISaddleHorseView:UpdateHorseLevel(item)
    local requireAttrib = item.GetRequireAttrib()
    local needLevel = 1
    for _,v in ipairs(requireAttrib) do
        if v.nID == 5 then
            needLevel = v.nValue1 or v.nValue
        end
    end

    if self.szFilter == "Qiqu" then
        local szDesc = UIHelper.GBKToUTF8(Table_GetItemDesc(item.nUiId))
        szDesc = ParseTextHelper.ParseNormalText(szDesc, true)
        UIHelper.SetString(self.LabelBackgroundStory, szDesc)
    end

    UIHelper.SetVisible(self.LabelBackgroundStory, self.szFilter == "Qiqu")
    UIHelper.SetString(self.LabelNeedLevel, FormatString(g_tStrings.STR_NPC_EQUIPMENT_NEED_LEVEL, needLevel))
    UIHelper.SetString(self.LabelQualityLevel, FormatString(g_tStrings.STR_ITEM_H_ITEM_LEVEL, item.nLevel))

    UIHelper.LayoutDoLayout(self.LayoutAtrribute)
end

function UISaddleHorseView:UpdateHorseSource(nTabType, nTabIndex)
    nTabType = nTabType or self.dwItemTabType
    nTabIndex = nTabIndex or self.dwItemTabIndex

    local tSource = ItemData.GetItemSourceList(nTabType, nTabIndex)
    if tSource then
        self:UpdateItemSource(tSource, nTabType, nTabIndex, tInfo)
    else
        UIHelper.SetVisible(self.LayoutTrace, false)
        UIHelper.SetVisible(self.WidgetTraceDesTitle, false)
    end
end

function UISaddleHorseView:UpdateItemSource(tSource, dwItemType, dwItemIndex, tInfo)
    local bIsActivityOn = false
	if tSource.tActivity and tSource.tActivity[1] then
		local dwActivityID = tSource.tActivity[1]
		bIsActivityOn = UI_IsActivityOn(dwActivityID) or ActivityData.IsActivityOn(dwActivityID)
	else
		bIsActivityOn = true
	end

    local tbInfo = {}
    tbInfo[1] = {}

    ItemData.GetItemSourceActivity(tSource.tActivity, tbInfo)
    if bIsActivityOn then
		ItemData.GetItemSourceShop(tSource.tShop, tbInfo, dwItemType, dwItemIndex)
		if not tSource.tShop or #tSource.tShop == 0 then
			ItemData.GetSourceShopNpcTip(tSource.tSourceNpc, tbInfo)
		end
		ItemData.GetSourceQuestTip(tSource.tQuests, tbInfo, g_pClientPlayer)
	end

    if tSource.bTrades then
		if tSource.tLinkItem and #tSource.tLinkItem > 0 then
			local tLinkItemInfo = tSource.tLinkItem[1]
			if tLinkItemInfo then
                ItemData.GetSourceTradeTip(tSource.bTrades, tbInfo, tLinkItemInfo[1], tLinkItemInfo[2])
			end
		else
            ItemData.GetSourceTradeTip(tSource.bTrades, tbInfo, dwItemType, dwItemIndex)
		end
	end

    ItemData.GetSourceProduceTip(tSource.tSourceProduce, tbInfo)
    ItemData.GetSourceCollectD(tSource.tSourceCollectD, tbInfo)
    ItemData.GetSourceCollectN(tSource.tSourceCollectN, tbInfo)
    ItemData.GetSourceBossTip(tSource.tBoss, tbInfo)
    ItemData.GetSourceFromItemTip(tSource.tItems, tbInfo)
	ItemData.GetItemSourceCoinShop(tSource.tCoinShop, tbInfo)
    ItemData.GetItemSourceReputation(tSource.tReputation, tbInfo)
	ItemData.GetItemSourceAchievement(tSource.tAchievement, tbInfo)
	ItemData.GetItemSourceAdventure(tSource.tAdventure, tbInfo)
	ItemData.GetSourceOpenPanelTip(tSource.tFunction, tSource.tEventLink, tbInfo)

    UIHelper.RemoveAllChildren(self.LayoutTrace)
    if tbInfo[1] then
        for k, v in ipairs(tbInfo[1]) do
            local scriptItemSourceInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent10TraceCell, self.LayoutTrace)
            if scriptItemSourceInfo then
                scriptItemSourceInfo:OnEnter(v)
            end
        end
    end

    UIHelper.SetVisible(self.LayoutTrace, (tbInfo[1] and tbInfo[1][1]) and true or false)
    UIHelper.SetVisible(self.WidgetTraceDesTitle, (tbInfo[1] and tbInfo[1][1]) and true or false)
end

function UISaddleHorseView:OpenHorseRightBag()
    local tItemBoxAndIndexList = {}
    for _, tbItemInfo in ipairs(ItemData.GetItemList(ItemData.BoxSet.Bag)) do
        if tbItemInfo.hItem and tbItemInfo.hItem.nGenre == ITEM_GENRE.EQUIPMENT and tbItemInfo.hItem.nSub == EQUIPMENT_SUB.HORSE and not tbItemInfo.hItem.IsRareHorse() then
            table.insert(tItemBoxAndIndexList,{nBox = tbItemInfo.nBox, nIndex = tbItemInfo.nIndex, nSelectedQuantity = 0, hItem = tbItemInfo.hItem})
        end
    end

    local tbFilterInfo = {}
    tbFilterInfo.Def = FilterDef.HorseLeftBag
    tbFilterInfo.tbfuncFilter = {{
        function(_) return true end,
        function(item) return item.nQuality == 2 end,
        function(item) return item.nQuality == 3 end,
        function(item) return item.nQuality == 4 end,
        function(item) return item.nQuality == 5 end,
    }}

    local scriptView = UIMgr.Open(VIEW_ID.PanelRightBag)
    if scriptView then
        scriptView:OnInitWithBox(tItemBoxAndIndexList,tbFilterInfo)
        scriptView:SetClickCallback(function(_, dwBox, dwIndex)
            self:SelectedHorseBagItem(dwBox, dwIndex)
            UIMgr.Close(VIEW_ID.PanelRightBag)
        end)
    end
end

--点击马包里的马匹，出现二次确认弹窗，放入
function UISaddleHorseView:SelectedHorseBagItem(dwBox, dwIndex)
    if PropsSort.IsBagInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
        return
    end
    
    if dwBox and  dwIndex then
        local view = UIMgr.GetView(VIEW_ID.PanelNormalConfirmation)
        if not view then
            UIHelper.ShowConfirm(g_tStrings.STR_PUT_HORSE_BOX,function ()
                local nCanExchange = g_pClientPlayer.CanExchange(dwBox, dwIndex, INVENTORY_INDEX.HORSE, self.nIndex)
                if nCanExchange == ITEM_RESULT_CODE.SUCCESS then

                    g_pClientPlayer.ExchangeItem(dwBox, dwIndex, INVENTORY_INDEX.HORSE, self.nIndex, 1)
                else
                    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tItem_Msg[nCanExchange])
                end
            end)
        end
        for _,v in ipairs(self.tbHorseBag) do
            v:SetSelected(false)
        end
    end
end

function UISaddleHorseView:ShowHorseEquipTips(nTabType, nTabID, bHave)
    if nTabType and nTabID then
        local _, scriptItemTip = TipsHelper.ShowItemTips(nil, dwHorseEquipType,nTabID)
        if scriptItemTip and bHave then
            local bEquip = false
            for i = 1, HORSE_ADORNMENT_COUNT do
                local dwIndex = self:GetEquipItemIndex(i)
                if dwIndex and nTabID == dwIndex then
                    self.nEquipIndex = i
                    bEquip = true
                end
            end

            local tbBtnInfo = {{
                szName = bEquip and g_tStrings.STR_BTN_DES_UNDRESS or g_tStrings.STR_BTN_DES_EQUIP,
                OnClick = function()
                    if bEquip then
                        self:UnEquipHorseEquip()
                    else
                        self:SelectedHorseEquip(nTabID)
                    end
                    TipsHelper.DeleteAllHoverTips(self)
                end,
                bNormalBtn = false,
                bFobidCheckBtnType = true,
            }}
            scriptItemTip:SetBtnState(tbBtnInfo)
        end
    end
end

function UISaddleHorseView:SelectedHorseEquip(dwItemID)
    local bCurrent = false
    local dwEquipBox, dwEquipX = self.dwCurEquipBox, self.dwCurEquipX
    if dwEquipBox == INVENTORY_INDEX.HORSE and dwEquipX == self.nIndex then
        bCurrent = true
    end

    local hItemInfo = ItemData.GetItemInfo(dwHorseEquipType, dwItemID)
    local nEquipPos = hItemInfo.nDetail

    if bCurrent then
        local nIndex = tPresetIndexToEquipIndex[nEquipPos]
        local hAdornment =  g_pClientPlayer.GetEquippedHorseEquip(nIndex)
        if hAdornment and dwItemID == hAdornment.dwIndex then
            return
        elseif hAdornment and hAdornment.dwIndex ~= 0 then
            self:SetCurEquipCount()
        end

        local nRet = g_pClientPlayer.EquipHorseEquip(dwItemID)
        if nRet ~= ITEM_RESULT_CODE.SUCCESS then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tItem_Msg[nRet])
        end
        self:SetCurEquipCount()
    else
        local tHorseEquip = g_pClientPlayer.GetHorseEquipPresetData(self.nIndex)

        if tHorseEquip and tHorseEquip[nEquipPos] == dwItemID then
            return
        end
        g_pClientPlayer.SetHorseEquipPresetData(self.nIndex,nEquipPos,dwItemID)
        self:SetOtherEquipCount()
    end
end

function UISaddleHorseView:UnEquipHorseEquip()
    local bCurrent = false
    local dwEquipBox, dwEquipX = self.dwCurEquipBox, self.dwCurEquipX
    if dwEquipBox == INVENTORY_INDEX.HORSE and dwEquipX == self.nIndex then
        bCurrent = true
    end

    if bCurrent then
        local dwX = tEquipIndex[self.nEquipIndex]
        local nRet = g_pClientPlayer.UnEquipHorseEquip(dwX)
        if nRet ~= ITEM_RESULT_CODE.SUCCESS then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tItem_Msg[nRet])
        end
        self:SetCurEquipCount()
else
        self:SetOtherEquipCount()
        g_pClientPlayer.SetHorseEquipPresetData(self.nIndex, self.nEquipIndex-1, 0)
    end
end

function UISaddleHorseView:UnEquipHorseEquipBySetID(tSetList)
    local bCurrent = false
    local dwEquipBox, dwEquipX = self.dwCurEquipBox, self.dwCurEquipX
    if dwEquipBox == INVENTORY_INDEX.HORSE and dwEquipX == self.nIndex then
        bCurrent = true
    end

    for _, dwItemIndex in ipairs(tSetList) do
        local hItemInfo = ItemData.GetItemInfo(dwHorseEquipType, dwItemIndex)
        local nEquipPos = hItemInfo.nDetail

        if bCurrent then
            local dwX = tPresetIndexToEquipIndex[nEquipPos]
            local nRet = g_pClientPlayer.UnEquipHorseEquip(dwX)
            if nRet ~= ITEM_RESULT_CODE.SUCCESS then
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tItem_Msg[nRet])
            else
                self:SetCurEquipCount()
            end
        else
            g_pClientPlayer.SetHorseEquipPresetData(self.nIndex, nEquipPos, 0)
            self:SetOtherEquipCount()
        end
    end
end

function UISaddleHorseView:SetCurEquipCount()
    self.nCurSetEquipCount = self.nCurSetEquipCount or 0
    self.nCurSetEquipCount = self.nCurSetEquipCount + 1
end

function UISaddleHorseView:SetOtherEquipCount()
    self.nSetEquipCount = self.nSetEquipCount or 0
    self.nSetEquipCount = self.nSetEquipCount + 1
end

function UISaddleHorseView:SubCurEquipCount()
    if self.nCurSetEquipCount and self.nCurSetEquipCount > 0 then
        self.nCurSetEquipCount = self.nCurSetEquipCount - 1
    end
end

function UISaddleHorseView:SubOtherEquipCount()
    if self.nSetEquipCount and self.nSetEquipCount > 0 then
        self.nSetEquipCount = self.nSetEquipCount - 1
    end
end

function UISaddleHorseView:ShowHorseExteriorChoose()
    UIMgr.Close(VIEW_ID.PanelHorseEquipExterior)
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelLeftBag)
    if not scriptView then
        scriptView = UIMgr.Open(VIEW_ID.PanelLeftBag)
    end
    if scriptView then
        local tList = RideExteriorData.GetHorseExteriorList()
        local tbFilterInfo = {}
        tbFilterInfo.Def = FilterDef.RideExterior
        tbFilterInfo.tbfuncFilter = RideExteriorData.CommonFilter
        scriptView:OnInitWithRideExterior(tList, tbFilterInfo)
        scriptView:SetTitle(g_tStrings.STR_HORSE_EXTERIOR)
        scriptView:SetEmptyDes(g_tStrings.STR_HORSE_EXTERIOR_EMPTY)
    end
end


function UISaddleHorseView:Feed(dwBox, dwIndex)
    if dwBox and dwIndex then

        local dwHorseBox = INVENTORY_INDEX.HORSE
        local dwHorseX = self.nIndex
        if self.szFilter ~= "Ride" then
            dwHorseBox = self.nQiQuBox
            dwHorseX = self.nQiQuIndex
        end

        local nResult = g_pClientPlayer.FeedHorse(dwHorseBox, dwHorseX, dwBox, dwIndex)

        if nResult ~= DOMESTICATE_OPERATION_RESULT_CODE.SUCCESS then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tDometicateError[nResult])
        else
            self.bFeedUpdateHorse = true
        end
    end
end

function UISaddleHorseView:OnClickEquipHorse()
    if g_pClientPlayer.bOnHorse then
        UIHelper.ShowConfirm("您当前正在骑乘状态，是否下马并设此坐骑为当前坐骑并上马？", function ()
            RideHorse()

            local dwBox, dwIndex
            if self.szFilter == "Ride" then
                dwBox, dwIndex = INVENTORY_INDEX.HORSE, self.nIndex
            else
                dwBox, dwIndex = self.nQiQuBox, self.nQiQuIndex
            end
            HorseMgr.EquipHorseAndRideHorse(dwBox, dwIndex)

            UIMgr.Close(self)
        end)
    else
        self:EquipHorse()
    end
end

function UISaddleHorseView:EquipHorse()
    local dwBox, dwIndex
    if self.szFilter == "Ride" then
        dwBox, dwIndex = INVENTORY_INDEX.HORSE, self.nIndex
    else
        dwBox, dwIndex = self.nQiQuBox, self.nQiQuIndex
    end

    local nRet = g_pClientPlayer.EquipHorse(dwBox, dwIndex)
    if nRet ~= ITEM_RESULT_CODE.SUCCESS then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tItem_Msg[nRet])
    else
        TipsHelper.ShowNormalTip(g_tStrings.STR_EQUIP_HORSE_SUCCESS)
        if self.szFilter == "Ride" then
            UIHelper.SetVisible(self.BtnSet,false)
        else
            -- 判断奇趣坐骑是否可卸下
            local hItem = ItemData.GetPlayerItem(g_pClientPlayer, dwBox, dwIndex)
            local bCanUnequip = hItem and hItem.CheckIgnoreBindMask and hItem.CheckIgnoreBindMask(ITEM_IGNORE_BIND_TYPE.TONG) or false

            if bCanUnequip then
                UIHelper.SetVisible(self.BtnSet,false)
                UIHelper.SetVisible(self.BtnAlreadly,true)
            else
                UIHelper.SetVisible(self.BtnSetQiQu,false)
                UIHelper.SetVisible(self.BtnQiQuAlreadly,true)
            end
        end
    end
end

function UISaddleHorseView:SetExteriorPreview(dwExteriorID, bEquip, nExteriorSlot)
    RideExteriorData.SetExteriorPreview(dwExteriorID, bEquip, nExteriorSlot)
    
    if not bEquip then
        if UIMgr.IsViewOpened(VIEW_ID.PanelLeftBag) then
            self:ShowHorseExteriorChoose()
        end
    else
        local HorseEquipExteriorView = UIMgr.GetViewScript(VIEW_ID.PanelHorseEquipExterior)
        HorseEquipExteriorView:UpdateHorseEquipExterior()
    end

	self:UpdateExteriorHorseModel()
    self:UpdateRideExterior()
    self:UpdateSaveState()
end

return UISaddleHorseView