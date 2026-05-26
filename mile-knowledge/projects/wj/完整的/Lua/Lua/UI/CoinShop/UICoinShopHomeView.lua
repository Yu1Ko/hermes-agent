-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopHomeView
-- Date: 2023-03-03 14:35:13
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopHomeView = class("UICoinShopHomeView")

function UICoinShopHomeView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    Timer.AddCycle(self, 0.1, function()
        self:CheckUntimelyList()
    end)
end

function UICoinShopHomeView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UICoinShopHomeView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnGo, EventType.OnClick, function()
        if self.funcClikSchool then
            self.funcClikSchool()
        end
    end)

    UIHelper.BindUIEvent(self.BtnStackTitle, EventType.OnClick, function()
        self:SetFoldID(nil)
    end)

    UIHelper.BindUIEvent(self.BtnWeapons, EventType.OnClick, function()
        local nWeapon = Table_GetWeaponJump()
        if nWeapon then
            UIHelper.ShowConfirm(g_tStrings.COINSHOP_WEAPON_PREVIEW_JUMP_TIP, function()
                local szLink = HOME_TYPE.EXTERIOR_WEAPON .. "/" .. nWeapon
                Event.Dispatch(EventType.OnCoinShopLink, szLink, true)
            end)
        end
    end)

    UIHelper.BindUIEvent(self.TogRecommend, EventType.OnSelectChanged, function(_, bSelected)
        Event.Dispatch(EventType.OnCoinShopRecommendOpenClose, bSelected)
    end)
end

function UICoinShopHomeView:RegEvent()
    Event.Reg(self, "COINSHOPVIEW_ROLE_DATA_UPDATE", function ()
        self:UpdateListItemState()
    end)

    Event.Reg(self, "COINSHOPVIEW_PET_DATA_UPDATE", function ()
        self:UpdateListItemState()
    end)

    Event.Reg(self, "COINSHOPVIEW_FURNITURE_DATA_UPDATE", function ()
        self:UpdateListItemState()
    end)

    Event.Reg(self, "COINSHOPVIEW_RIDE_DATA_UPDATE", function ()
        self:UpdateListItemState()
    end)

    Event.Reg(self, "PLAYER_HIDE_HAT_CHANGE", function ()
        self:UpdateListItemState()
    end)

    Event.Reg(self, "GLOBAL_COUNTER_VALUE_UPDATE", function ()
        self:RefreshLimitItemCounter()
    end)

    Event.Reg(self, "SYNC_GLOBAL_COUNTER", function ()
        self:RefreshLimitItemCounter()
    end)

    Event.Reg(self, "DIS_COUPON_CHANGED", function ()
        self:UpdateListItem()
    end)
end

function UICoinShopHomeView:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

local function ShouldShowRecommend(eGoodsType, nClass)
    if not eGoodsType or not nClass then
        return false
    end
    local nType  = eGoodsType
    local nClass = nClass or 0
    if nType == COIN_SHOP_GOODS_TYPE.EXTERIOR
        or nType == COIN_SHOP_GOODS_TYPE.HAIR
        or nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        return true
    elseif nType == COIN_SHOP_GOODS_TYPE.ITEM then
        if nClass == REWARDS_CLASS.EFFECT
            or nClass == REWARDS_CLASS.CLOTH_PENDANT_PET
            or nClass == REWARDS_CLASS.PET then
            return true
        end
        local nEquipSub = CoinShop_RewardsClassToSub(nClass)
        if nEquipSub and GetPendantTypeByEquipSub(nEquipSub) then
            return true
        end
    end
    return false
end

function UICoinShopHomeView:UpdateInfo()
end

function UICoinShopHomeView:UpdateCurPageList(nPage)
    if not nPage then
        nPage = self.m.nPage
    end
    if self.m and self.m.bSchool then
        self:UpdateImageSchoolList(self.m.tbGoodsList)
    else
        self:UpdateImageItemList(self.m.tbGoodsList)
    end
end

function UICoinShopHomeView:UpdateGoodList(tbTitle, nSubClass)
    -- 切换分页时重置推荐面板缓存，避免旧数据残留
    Event.Dispatch("COINSHOP_RESET_RECOMMEND_CACHE")

    local szViewType = tbTitle.szViewType or "Role"
    FireUIEvent("COINSHOP_SHOW_VIEW", szViewType, false)

    self.m = {}
    self.m.tbTitle = tbTitle
    self.m.tbFilter = {}

    UIHelper.SetVisible(self.ScrollViewNewList, false)
    UIHelper.RemoveAllChildren(self.ScrollViewNewList)

    local tbGoodsList
    self.m.bSchool = false
    if tbTitle.nRewardsClass == 6 and tbTitle.nType then
        tbGoodsList = CoinShop_GetHomeList(92)
        self.m.bSchool = true
    else
        tbGoodsList = CoinShopData.GetRewardsList(tbTitle.nRewardsClass, tbTitle.bRewardSet)
    end
    self.m.tbFilter.nSubClass = tbGoodsList[1].nSubClass
    if #tbGoodsList <= 1 then
        self.m.tbFilter.bHideSubClass = true
    end
    self.m.tbGoodsList = tbGoodsList
    UIHelper.SetVisible(self.BtnWeapons, tbTitle.nTitleClass == 1 and tbTitle.nTitleSub == 3)
    UIHelper.LayoutDoLayout(self.LayoutNewContentBotton)
    self:InitImageItemPage()
end

function UICoinShopHomeView:InitImageItemPage()
    if self.m.bSchool then
        UIHelper.SetVisible(self.ScrollViewNewList, false)
        UIHelper.SetVisible(self.WidgetNewStack, false)
        UIHelper.SetVisible(self.WidgetActivityContent, true)
        self:UpdateSchoolLeftChance()
        self:UpdateImageSchoolList(self.m.tbGoodsList)
    elseif self.m.nFoldID and self.m.nFoldID > 0 then
        UIHelper.SetVisible(self.ScrollViewNewList, false)
        UIHelper.SetVisible(self.WidgetNewStack, true)
        UIHelper.SetVisible(self.WidgetActivityContent, false)
        self:UpdateImageItemList(self.m.tbGoodsList, 1)

        local tbFoldInfo = CoinShop_GetHomeFoldInfoByID(self.m.nFoldID)
        local szName = UIHelper.GBKToUTF8(tbFoldInfo.szName)
        UIHelper.SetString(self.LabelStackTitle, szName)
    else
        UIHelper.SetVisible(self.ScrollViewNewList, true)
        UIHelper.SetVisible(self.WidgetNewStack, false)
        UIHelper.SetVisible(self.WidgetActivityContent, false)
        self:UpdateImageItemList(self.m.tbGoodsList, 1)
    end
end

function UICoinShopHomeView:SetFoldID(nFoldID)
    if self.m.nFoldID == nFoldID then
        return
    end
    self.m.nFoldID = nFoldID
    if nFoldID and nFoldID > 0 then
        self.m.nCacheScrollPercent = UIHelper.GetScrollPercent(self.ScrollViewNewList)
    end
    self:InitImageItemPage()
end

function UICoinShopHomeView:UpdateImageItemList(tbList, nPage)
    local tbShowList = CoinShopRewards.GetRewardsTabList(tbList, self.m.tbFilter.nSubClass)
    local tbFilterList, tbUntimelyList = CoinShopRewards.FilterTimeRewardsList(tbShowList)
    if not IsTableEmpty(tbUntimelyList) then
        self.m.tbUntimelyList = tbUntimelyList
    else
        self.m.tbUntimelyList = nil
    end

    tbShowList = {}
    local tbFoldIdxMap ={}
    for i, tbRewardsItem in ipairs(tbFilterList) do
        local tbGoods = {
            dwGoodsID = tbRewardsItem.dwLogicID,
            eGoodsType = COIN_SHOP_GOODS_TYPE.ITEM,
        }
        if tbRewardsItem.nFoldID and tbRewardsItem.nFoldID > 0 then
            if not tbFoldIdxMap[tbRewardsItem.nFoldID] then
                local tbFoldInfo = {}
                tbFoldInfo.nFoldID = tbRewardsItem.nFoldID
                table.insert(tbShowList, tbFoldInfo)
                tbFoldIdxMap[tbRewardsItem.nFoldID] = #tbShowList
            end
            local idx = tbFoldIdxMap[tbRewardsItem.nFoldID]
            table.insert(tbShowList[idx], tbGoods)
        else
            table.insert(tbShowList, tbGoods)
        end
    end

    local tbFinalList
    local scrollView
    if self.m.nFoldID and self.m.nFoldID > 0 then
        local idx = tbFoldIdxMap[self.m.nFoldID]
        tbFinalList = tbShowList[idx] or {}
        scrollView = self.ScrollViewNewStack
    else
        tbFinalList = tbShowList
        scrollView = self.ScrollViewNewList
    end

    self.ScrollViewNewList:removeAllChildren()
    self.ScrollViewList_Activity:removeAllChildren()
    self.ScrollViewNewStack:removeAllChildren()
    self.m.tbScriptList = {}
    for i, tbItem in ipairs(tbFinalList) do
        local homeItem
        if tbItem.nFoldID and tbItem.nFoldID > 0 then
            homeItem = UIHelper.AddPrefab(PREFAB_ID.WidgetOutfitItem, scrollView)
            homeItem:OnInitWithFold(tbItem, function()
                self:SetFoldID(tbItem.nFoldID)
            end)
        else
            homeItem = UIHelper.AddPrefab(PREFAB_ID.WidgetOutfitItem, scrollView)
            homeItem:OnInitWithGoods(tbItem)
        end
        table.insert(self.m.tbScriptList, homeItem)
    end
    UIHelper.ScrollViewDoLayout(scrollView)

    if self.m.nFoldID and self.m.nFoldID > 0 then
        UIHelper.ScrollToTop(scrollView, 0)
    elseif self.m.nCacheScrollPercent then
        UIHelper.ScrollToPercent(scrollView, self.m.nCacheScrollPercent)
        self.m.nCacheScrollPercent = nil
    else
        UIHelper.ScrollToTop(scrollView, 0)
    end
end

function UICoinShopHomeView:UpdateSchoolLeftChance()
    local nChance = CoinShopData.GetSchoolCanGetChance()
    UIHelper.SetString(self.LabelCanGet, nChance)
end

function UICoinShopHomeView:UpdateImageSchoolList(tbList)
    self.ScrollViewNewList:removeAllChildren()
    self.ScrollViewList_Activity:removeAllChildren()
    self.ScrollViewNewStack:removeAllChildren()
    self.m.tbScriptList = {}
    for i = 1, #tbList do
        local tbRewardsItem = tbList[i]
        local tbGoods = {}
        tbGoods.dwGoodsID = tbRewardsItem.dwGoodsID
        tbGoods.eGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR
        tbGoods.bSet = tbRewardsItem.bSet
        local homeItem = UIHelper.AddPrefab(PREFAB_ID.WidgetOutfitItem, self.ScrollViewList_Activity)
        homeItem:OnInitWithGoods(tbGoods)
        table.insert(self.m.tbScriptList, homeItem)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewList_Activity)
    UIHelper.ScrollToTop(self.ScrollViewList_Activity, 0)
end

function UICoinShopHomeView:LinkRewardsItem(dwID)
    local tbFoldInfo = CoinShop_GetHomeFoldInfoByGoods(COIN_SHOP_GOODS_TYPE.ITEM, dwID)
    if tbFoldInfo and tbFoldInfo.nFoldID > 0 then
        self:SetFoldID(tbFoldInfo.nFoldID)
    end
    for _, script in ipairs(self.m.tbScriptList) do
        if script.tbGoods and script.tbGoods.dwGoodsID == dwID then
            CoinShopPreview.LocatePreviewItem(self.ScrollViewNewList, script._rootNode)
            CoinShop_PreviewGoods(script.tbGoods.eGoodsType, script.tbGoods.dwGoodsID, true)
            break
        end
    end
end

function UICoinShopHomeView:UpdateListItemState()
    if self.m and self.m.tbScriptList then
        for _, script in ipairs(self.m.tbScriptList) do
            if script.UpdateItemState then
                script:UpdateItemState()
            end
        end
    end
end

function UICoinShopHomeView:UpdateListItem()
    if self.m and self.m.tbScriptList then
        for _, script in ipairs(self.m.tbScriptList) do
            if script.Update then
                script:Update()
            end
        end
    end
end

function UICoinShopHomeView:RefreshLimitItemCounter()
    if self.m and self.m.tbScriptList then
        for _, script in ipairs(self.m.tbScriptList) do
            if script.UpdateCounterNum then
                script:UpdateCounterNum()
            end
        end
    end
end

function UICoinShopHomeView:SetSchoolClikFunc(func)
    self.funcClikSchool = func
end

function UICoinShopHomeView:CheckUntimelyList()
    if self.m and self.m.tbUntimelyList then
        local nTime = GetGSCurrentTime()
        for _, tItem in pairs(self.m.tbUntimelyList) do
            if CoinShopData.IsStartTimeOK(tItem.nStartTime, nTime) then
                self.m.tbUntimelyList = {}
                self:UpdateCurPageList()
                return
            end
        end
    end
end

--- 从当前预览数据构建推荐请求用的 tExteriorList                
function UICoinShopHomeView:BuildExteriorListFromPreview(nType, nClass)
    local tExteriorList = {}
    local tRoleViewData = ExteriorCharacter.GetRoleData()
    if not tRoleViewData then
        return tExteriorList
    end

    if nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        local tWeaponData = tRoleViewData[COINSHOP_BOX_INDEX.WEAPON]
        if tWeaponData and tWeaponData.dwID and tWeaponData.dwID > 0 then
            local nSub = Exterior_BoxIndexToRepresentSub(COINSHOP_BOX_INDEX.WEAPON)
            if nSub then
                tExteriorList[nSub] = { tWeaponData.dwID }
            end
        end
        local tBigSwordData = tRoleViewData[COINSHOP_BOX_INDEX.BIG_SWORD]
        if tBigSwordData and tBigSwordData.dwID and tBigSwordData.dwID > 0 then
            local nSub = Exterior_BoxIndexToRepresentSub(COINSHOP_BOX_INDEX.BIG_SWORD)
            if nSub then
                tExteriorList[nSub] = { tBigSwordData.dwID }
            end
        end
    elseif nType == COIN_SHOP_GOODS_TYPE.HAIR then
        local tHairData = tRoleViewData[COINSHOP_BOX_INDEX.HAIR]
        if tHairData and tHairData.nHairID and tHairData.nHairID > 0 then
            local nSub = Exterior_BoxIndexToRepresentSub(COINSHOP_BOX_INDEX.HAIR)
            if nSub then
                tExteriorList[nSub] = { tHairData.nHairID }
            end
        end
    elseif nType == COIN_SHOP_GOODS_TYPE.ITEM then
        if nClass == REWARDS_CLASS.EFFECT then
            -- 特效使用字符串 key
            local tEffectData = tRoleViewData[COINSHOP_BOX_INDEX.EFFECT_SFX]
            if tEffectData and tEffectData.dwID and tEffectData.dwID > 0 then
                local nSub = Exterior_BoxIndexToRepresentSub(COINSHOP_BOX_INDEX.EFFECT_SFX)
                local szEffectType = ShareExteriorData.GetEffectTypeBySub(nSub)
                local szKey = szEffectType or nSub
                tExteriorList[szKey] = { tEffectData.dwID }
            end
        else
            if nClass == REWARDS_CLASS.CLOTH_PENDANT_PET then
                local tPendantPet = tRoleViewData[COINSHOP_BOX_INDEX.PENDANT_PET] and tRoleViewData[COINSHOP_BOX_INDEX.PENDANT_PET].tItem
                local dwPetID = tPendantPet and (tPendantPet.dwIndex or tPendantPet.dwPendantIndex)
                if dwPetID and dwPetID > 0 then
                    local nRepresentSub = EQUIPMENT_REPRESENT.PENDENT_PET_STYLE
                    tExteriorList[nRepresentSub] = { dwPetID }
                end
            end

            -- 挂件类型
            local nEquipSub = CoinShop_RewardsClassToSub(nClass)
            if nEquipSub then
                local nIndex = Exterior_SubToBoxIndex(nEquipSub)
                if nIndex then
                    local nSub = Exterior_BoxIndexToRepresentSub(nIndex)
                    local tData = tRoleViewData[nIndex] and tRoleViewData[nIndex].tItem or tRoleViewData[nIndex]
                    if tData and (tData.dwID or tData.dwPendantIndex) then
                        tExteriorList[nSub] = { tData.dwID or tData.dwPendantIndex }
                    end
                end
            end
        end
    end

    return tExteriorList
end

-- --- 根据当前选中的标题类型刷新推荐浮窗显示
function UICoinShopHomeView:RefreshShareStationRecommend(eGoodsType, dwGoodsID)
    local tbTitle = self.m and self.m.tbTitle
    if not tbTitle then
        return
    end

    local nType = tbTitle.nType
    local nClass = tbTitle.nRewardsClass or 0
    local bSupported = false
    if nType == COIN_SHOP_GOODS_TYPE.EXTERIOR
        or nType == COIN_SHOP_GOODS_TYPE.HAIR
        or nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        bSupported = true
    elseif nType == COIN_SHOP_GOODS_TYPE.ITEM then
        if nClass == REWARDS_CLASS.EFFECT
            or nClass == REWARDS_CLASS.CLOTH_PENDANT_PET
            or nClass == REWARDS_CLASS.PET then
            bSupported = true
        else
            local nEquipSub = CoinShop_RewardsClassToSub(nClass)
            if nEquipSub and GetPendantTypeByEquipSub(nEquipSub) then
                bSupported = true
            end
        end
    end

    if not bSupported then
        return
    end

    local tExteriorList = self:BuildExteriorListFromPreview(nType, nClass)
    local szTitleName = ""
    if eGoodsType and dwGoodsID and dwGoodsID > 0 then
        -- 检测外观列表中是否有特效类型（string key）
        local bEffectType
        for nKey, tIds in pairs(tExteriorList) do
            if type(nKey) == "string" and type(tIds) == "table" and tIds[1] and tIds[1] > 0 then
                bEffectType = true
                break
            end
        end
        if bEffectType then
            local tInfo = Table_GetPendantEffectInfo(dwGoodsID)
            szTitleName = (tInfo and tInfo.szName) or ""
        else
            szTitleName = ShareExteriorData.GetExteriorName(eGoodsType, dwGoodsID) or ""
        end
    end
    Event.Dispatch(EventType.OnCoinShopOpenRecommend, tExteriorList, szTitleName)
end

--- 当推荐面板已打开时，随预览数据变化刷新推荐内容
function UICoinShopHomeView:RefreshRecommendIfOpen(eGoodsType, dwGoodsID)
    if self.nCloseRecommendDelayTimer then
        Timer.DelTimer(self, self.nCloseRecommendDelayTimer)
        self.nCloseRecommendDelayTimer = nil
    end

    if self.TogRecommend and UIHelper.GetSelected(self.TogRecommend) then
        self:RefreshShareStationRecommend(eGoodsType, dwGoodsID)
    end

    local bNeedShowTog = false
    if eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then
        local tRewardsLine = Table_GetRewardsItem(dwGoodsID)
        if tRewardsLine then
            local hItemInfo = GetItemInfo(tRewardsLine.dwTabType, tRewardsLine.dwIndex)
            bNeedShowTog = hItemInfo.nGenre ~= ITEM_GENRE.HOMELAND
                and not (hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and hItemInfo.nSub == EQUIPMENT_SUB.HORSE)
                and not (hItemInfo.nGenre == ITEM_GENRE.COIN_SHOP_QUANTITY_LIMIT_ITEM and hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HORSE)
        end
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
        local nClass = ShareExteriorData.GetExteriorClass(dwGoodsID)
        if nClass and ShouldShowRecommend(eGoodsType, nClass) then
            bNeedShowTog = true
        end
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR
        or eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR
    then
        if ShouldShowRecommend(eGoodsType, 0) then
            bNeedShowTog = true
        end
    end
    UIHelper.SetVisible(self.TogRecommend, bNeedShowTog)
    if not bNeedShowTog then
        self.nCloseRecommendDelayTimer = Timer.AddFrame(self, 1, function()
            if self.TogRecommend then
                UIHelper.SetSelected(self.TogRecommend, false)
            end
        end)
    end
    UIHelper.LayoutDoLayout(self.LayoutNewContentBotton)

    if bNeedShowTog and TeachEvent.CheckCondition(49) then
        TeachEvent.TeachStart(49)
    end
end

return UICoinShopHomeView