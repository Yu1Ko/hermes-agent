-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopGoodsView
-- Date: 2023-02-23 20:47:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

local PAGE_EXTERIOR_COUNT = 6
local PAGE_PROP_COUNT = 6

local function MakeTitleKey(tbTitle, nSubClass)
    local szKey = string.format("%d_%d", tbTitle.nType, tbTitle.nRewardsClass)
    if nSubClass then
        szKey = string.format("%s_%d", szKey, nSubClass)
    end
    return szKey
end

local UICoinShopGoodsView = class("UICoinShopGoodsView")

function UICoinShopGoodsView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    -- 使用池子
    self:InitPool()

    self.tPageCache = {}
    self.m = {}
    self.bExteriorSimpleMode = false
    self.bAdornmentSimpleMode = false
    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)
    UIHelper.SetScrollViewCombinedBatchEnabled(self.ScrollViewExteriorPropList, false)

    Timer.AddCycle(self, 0.1, function()
        self:CheckUntimelyList()
    end)
end

function UICoinShopGoodsView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)

    self:UnInitPool()
end

function UICoinShopGoodsView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function ()
        local nPage = self.m.nPage-1
        self:UpdateCurPageList(nPage)
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function ()
        local nPage = self.m.nPage+1
        self:UpdateCurPageList(nPage)
    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditPaginate, function ()
            local szPage = UIHelper.GetString(self.EditPaginate)
            local nPage = tonumber(szPage) or 1
            self:UpdateCurPageList(nPage)
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditPaginate, function ()
            local szPage = UIHelper.GetString(self.EditPaginate)
            local nPage = tonumber(szPage) or 1
            self:UpdateCurPageList(nPage)
        end)
    end

    UIHelper.BindUIEvent(self.TogFilter, EventType.OnClick, function ()
        local bFurnitrue = self.m.tbTitle and self.m.tbTitle.nType == COIN_SHOP_GOODS_TYPE.ITEM and self.m.tbTitle.nRewardsClass == REWARDS_CLASS.FURNITURE
        if not bFurnitrue then
            return
        end

        local fnCheckedCallback = function (tMenu)
            if tMenu then
                self.m.tbFilter.nCatg1Index = tMenu.UserData[1]
                self.m.tbFilter.nCatg2Index = tMenu.UserData[2]
                self.m.tbShowList = nil
                self:UpdateRewardsItemList(self.m.tbGoodsList, 1)
            end
        end

        local tFilter = {}
        local tMenu = {}
        tMenu.szOption = "家具类型"
        table.insert(tMenu, { szOption = "全部", UserData = { 0, 0 }})
        local nCount = g_tTable.RewardFurnitureCatg:GetRowCount()
        for i = 2, nCount do
            local tLine = g_tTable.RewardFurnitureCatg:GetRow(i)
            local nCatg1Index = tLine.nCatg1Index
            local nCatg2Index = tLine.nCatg2Index
            if nCatg2Index == 0 then
                local tCate1 = {}
                tCate1 = {}
                tCate1.szOption = UIHelper.GBKToUTF8(tLine.szName)
                tFilter[nCatg1Index] = tCate1
                table.insert(tCate1, { szOption = "全部", UserData = { nCatg1Index, 0 }})
                table.insert(tMenu, tCate1)
            else
                local tCate2 = {}
                tCate2.szOption = UIHelper.GBKToUTF8(tLine.szName)
                tCate2.UserData = { nCatg1Index, nCatg2Index }
                table.insert(tFilter[nCatg1Index], tCate2)
            end
        end

        local fnPlayShow = function ()

        end

        local fnPlayHide = function ()

        end

        local script = UIMgr.Open(VIEW_ID.PanelExteriorFilter)
        script:OnInit(PREFAB_ID.WidgetBreadNaviCell, PREFAB_ID.WidgetFilterItemCell, fnCheckedCallback, fnPlayShow, fnPlayHide)
        script:SetChecked(tMenu)
        script:SetCloseCallback(function() UIHelper.SetSelected(self.TogFilter, false) end)
    end)

    UIHelper.BindUIEvent(self.TogFilter, EventType.OnSelectChanged, function (_, bSelected)
        self:OnSelectedFilter(bSelected)
    end)

    UIHelper.BindUIEvent(self.TogParticulars, EventType.OnSelectChanged, function (_, bSelected)
        UIHelper.SetVisible(self.particularsTips._rootNode, bSelected)
    end)

    UIHelper.BindUIEvent(self.BtnContent, EventType.OnClick, function ()
        if self.m.tbTitle.nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
            self.bExteriorSimpleMode = not self.bExteriorSimpleMode
            self.m.tbFilter.nType = CoinShopExterior.FILTER_ALL
            self.m.tbFilter.nStatus = CoinShopExterior.FILTER_ALL
            self:InitExteriorFilter()
            self:UpdateExteriorSetList(self.m.tbGoodsList.tSetList, 1, true)
        elseif self.m.tbTitle.nType == COIN_SHOP_GOODS_TYPE.ITEM then
            self.bAdornmentSimpleMode = not self.bAdornmentSimpleMode
            self.m.nPage = 1
            self.m.tbFilter.nType = CoinShopRewards.FILTER_ALL
            self:UpdateGoodList(self.m.tbTitle, self.m.nSubClass)
        end
    end)

    UIHelper.BindUIEvent(self.BtnHarnessTitle, EventType.OnClick, function ()
        UIHelper.SetSelected(self.BtnContent, false, false)
        self.bAdornmentSimpleMode = false
        self.m.nPage = 1
        self:UpdateGoodList(self.m.tbTitle, self.m.nSubClass)
    end)

    UIHelper.BindUIEvent(self.TogHair, EventType.OnSelectChanged, function (_, bSelected)
        TipsHelper.ShowNormalTip((bSelected and "已显示" or "已关闭") .. "预览配套发型")
        Storage.CoinShop.bPreviewMatchHair = bSelected
        Storage.CoinShop.Dirty()
    end)

    UIHelper.BindUIEvent(self.TogRecommend, EventType.OnSelectChanged, function(_, bSelected)
        Event.Dispatch(EventType.OnCoinShopRecommendOpenClose, bSelected)
    end)

    UIHelper.BindUIEvent(self.TogRecommend_Hair, EventType.OnSelectChanged, function(_, bSelected)
        Event.Dispatch(EventType.OnCoinShopRecommendOpenClose, bSelected)
    end)
end

function UICoinShopGoodsView:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        self:ClearSelect()
    end)

    Event.Reg(self, "WEAPON_EXTERIOR_COLLECT_RESULT", function ()
        if arg1 == EXTERIOR_COLLECT_RESULT_CODE.SUCCESS then
            self:UpdateCurPageList()
        end
    end)

    Event.Reg(self, "EXTERIOR_COLLECT_RESULT", function ()
        if arg1 == EXTERIOR_COLLECT_RESULT_CODE.SUCCESS then
            self:UpdateCurPageList()
        end
    end)

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

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        if editbox ~= self.EditPaginate then return end

        local szPage = UIHelper.GetString(self.EditPaginate)
        local nPage = tonumber(szPage) or 1
        self:UpdateCurPageList(nPage)
    end)

    Event.Reg(self, EventType.OnCoinShopLayoutPetUpdate, function()
        UIHelper.LayoutDoLayout(self.LayoutPet)
    end)

    Event.Reg(self, EventType.OnCoinShopListSizeChanged, function(bShop)
        if bShop then
            self:OnListSizeChanged()
        end
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.CoinShopGoodsExterior.Key then
            for i, tbData in ipairs(tbSelected) do
                if FilterDef.CoinShopGoodsExterior[i].bGenre then
                    local tGenreList = CoinShopData.GetGenreList(self.m.tbTitle.nRewardsClass)
                    self.m.tbFilter.nGenre = tGenreList[tbData[1]]
                elseif FilterDef.CoinShopGoodsExterior[i].bType then
                    self.m.tbFilter.nType = CoinShopExterior.tFilterType[tbData[1]]
                elseif FilterDef.CoinShopGoodsExterior[i].bStatus then
                    self.m.tbFilter.nStatus = CoinShopExterior.tSubStatus[tbData[1]]
                end
            end
            self.m.tbShowList = nil
            self:UpdateCurPageList(1)
            UIHelper.SetVisible(self.BtnContent, self.m.tbFilter.nType == CoinShopExterior.FILTER_ALL)
            UIHelper.LayoutDoLayout(self.LayoutTipsBotton)
        elseif szKey == FilterDef.CoinShopGoodsWeapon.Key then
            for i, tbData in ipairs(tbSelected) do
                if FilterDef.CoinShopGoodsWeapon[i].bStatus then
                    self.m.tbFilter.nStatus = CoinShopWeapon.tStatus[tbData[1]]
                elseif FilterDef.CoinShopGoodsWeapon[i].bType then
                    local tFilterType = CoinShopData.GetWeaponFilter()
                    self.m.tbFilter.nType = tFilterType[tbData[1]]
                end
            end
            self.m.tbShowList = nil
            self:UpdateCurPageList(1)
        elseif szKey == FilterDef.CoinShopGoodsHorse.Key then
            self.m.tbFilter.nType = CoinShopRewards.tAdornmentFilter[tbSelected[1][1]]
            self.m.tbShowList = nil
            self:UpdateCurPageList(1)
        elseif szKey == FilterDef.CoinShopGoodsItem.Key then
            self.m.tbFilter.nType = self.m.tbFilter.tItemType[tbSelected[1][1]]
            self.m.tbShowList = nil
            self:UpdateCurPageList(1)
        end
    end)
end

function UICoinShopGoodsView:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

local function ShouldShowRecommend(tbTitle)
    if not tbTitle then
        return false
    end
    local nType  = tbTitle.nType
    local nClass = tbTitle.nRewardsClass or 0
    if nType == COIN_SHOP_GOODS_TYPE.EXTERIOR
        or nType == COIN_SHOP_GOODS_TYPE.HAIR
        or nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        return true
    elseif nType == COIN_SHOP_GOODS_TYPE.ITEM then
        if nClass == REWARDS_CLASS.EFFECT
            or nClass == REWARDS_CLASS.CLOTH_PENDANT_PET then
            return true
        end
        local nEquipSub = CoinShop_RewardsClassToSub(nClass)
        if nEquipSub and GetPendantTypeByEquipSub(nEquipSub) then
            return true
        end
    end
    return false
end

function UICoinShopGoodsView:UpdateInfo()

end

function UICoinShopGoodsView:UpdateCurPageList(nPage)
    if not nPage then
        nPage = self.m.nPage
    end

    if self.m.tbTitle then
        if self.m.tbTitle.nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
            if self.m.tbFilter.nType == CoinShopExterior.FILTER_ALL then
                self:UpdateExteriorSetList(self.m.tbGoodsList.tSetList, nPage)
            else
                self:UpdateExteriorSubList(self.m.tbGoodsList.tSubList, nPage)
            end
        elseif self.m.tbTitle.nType == COIN_SHOP_GOODS_TYPE.ITEM then
            if self.m.tbTitle.bImageMode then
                self:UpdateImageItemList(self.m.tbGoodsList)
            -- elseif self.m.tbTitle.nRewardsClass == REWARDS_CLASS.PET then
            --     self:UpdatePetList(self.m.tbGoodsList)
            else
                self:UpdateRewardsItemList(self.m.tbGoodsList, nPage)
            end
        elseif self.m.tbTitle.nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
            self:UpdateWeaponList(self.m.tbGoodsList, nPage)
        end
    end
end

function UICoinShopGoodsView:UpdateGoodList(tbTitle, nSubClass, bInLinkGoods)
    -- 切换分页时重置推荐面板缓存，避免旧数据残留
    Event.Dispatch("COINSHOP_RESET_RECOMMEND_CACHE")

    -- 记录上次页面缓存的数据
    if self.m.tbTitle then
        local szKey = MakeTitleKey(self.m.tbTitle, self.m.nSubClass)
        self.tPageCache[szKey] = {
            nPage = self.m.nPage,
            tbFilter = clone(self.m.tbFilter),
        }
    end

    local szViewType = tbTitle.szViewType or "Role"

    local bShowWeapon = tbTitle.nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR
    FireUIEvent("COINSHOP_SHOW_VIEW", szViewType, bShowWeapon)

    self:Recycle(PREFAB_ID.WidgetPropItemCell)

    self.m = {}
    self.m.tbTitle = tbTitle
    self.m.nSubClass = nSubClass
    self.m.tbFilter = {}
    self.m.tbScriptList = {}
    self.m.bInLinkGoods = bInLinkGoods

    -- 恢复本次页面缓存的数据
    local szKey = MakeTitleKey(self.m.tbTitle, self.m.nSubClass)
    local tPageCache = self.tPageCache[szKey]
    if tPageCache then
        for k, v in pairs(tPageCache.tbFilter) do
            self.m.tbFilter[k] = v
        end
        self.m.nPage = tPageCache.nPage
    end

    UIHelper.SetVisible(self.TogFilter, false)
    UIHelper.SetVisible(self.BtnContent, false)

    local bShowRecommend = ShouldShowRecommend(tbTitle)
    UIHelper.SetVisible(self.TogRecommend, bShowRecommend)
    UIHelper.SetVisible(self.TogRecommend_Hair, bShowRecommend)

    if bShowRecommend then
        if tbTitle.nType == COIN_SHOP_GOODS_TYPE.HAIR and TeachEvent.CheckCondition(51) then
            TeachEvent.TeachStart(51)
        elseif TeachEvent.CheckCondition(50) then
            TeachEvent.TeachStart(50)
        end
    end

     local bNeedShowTog = false

    if not bShowRecommend then
        Event.Dispatch(EventType.OnCoinShopRecommendOpenClose, false)
    end
    -- local scriptColor = UIHelper.GetBindScript(self.TogAccept)
    -- scriptColor:SetVisible(false)
    UIHelper.SetVisible(self.TogParticulars, false)
    UIHelper.SetVisible(self.ScrollViewExteriorPropList, false)
    UIHelper.RemoveAllChildren(self.ScrollViewExteriorPropList)
    UIHelper.SetVisible(self.ScrollViewPetList, false)
    UIHelper.RemoveAllChildren(self.ScrollViewPetList)
    UIHelper.SetVisible(self.WidgetHarnessList, false)
    UIHelper.RemoveAllChildren(self.ScrollViewHarnessList)
    UIHelper.SetVisible(self.TogHair, false)
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetVisible(self.WidgetAnchorHair, false)

    if tbTitle.nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
        local tbGoodsList = CoinShopData.GetExteriorList(tbTitle.nRewardsClass)
        self.m.tbGoodsList = tbGoodsList
        self:InitExteriorPage()
    elseif tbTitle.nType == COIN_SHOP_GOODS_TYPE.ITEM then
        local tbGoodsList = CoinShopData.GetRewardsList(tbTitle.nRewardsClass, tbTitle.bRewardSet)
        if nSubClass then
            self.m.tbFilter.nSubClass = nSubClass
            self.m.tbFilter.bHideSubClass = true
        else
            self.m.tbFilter.nSubClass = self.m.tbFilter.nSubClass or tbGoodsList[1].nSubClass
            if #tbGoodsList <= 1 then
                self.m.tbFilter.bHideSubClass = true
            end
        end
        self.m.tbGoodsList = tbGoodsList
        self:InitRewardsItemPage()
    elseif tbTitle.nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        self.m.tbGoodsList = CoinShopData.GetShopWeapon()
        self:InitWeaponPage()
    elseif tbTitle.nType == COIN_SHOP_GOODS_TYPE.HAIR then
        self.m.tbFilter.nSubClass = nSubClass
        self.m.tbGoodsList = tbTitle
        self:InitHairPage()
    end

    -- local bShowTips = self.m.tbScriptList and not table_is_empty(self.m.tbScriptList)
    -- UIHelper.SetVisible(self.LayoutTipsBotton, bShowTips)
    UIHelper.LayoutDoLayout(self.LayoutTipsBotton)
end

function UICoinShopGoodsView:UpdatePaginate(nPage, nTotalPage)
    UIHelper.SetString(self.EditPaginate, nPage)
    UIHelper.SetString(self.LabelPaginate, "/" .. nTotalPage)
    UIHelper.SetVisible(self.WidgetPaginate, nTotalPage >= 1)

    -- if nPage <= 1 then
    --     UIHelper.SetButtonState(self.BtnLeft, BTN_STATE.Disable)
    -- else
    --     UIHelper.SetButtonState(self.BtnLeft, BTN_STATE.Normal)
    -- end

    -- if nPage >= nTotalPage then
    --     UIHelper.SetButtonState(self.BtnRight, BTN_STATE.Disable)
    -- else
    --     UIHelper.SetButtonState(self.BtnRight, BTN_STATE.Normal)
    -- end
end

function UICoinShopGoodsView:InitExteriorPage()
    UIHelper.SetVisible(self.ScrollViewExteriorPropList, true)

    ExteriorCharacter.SetCameraMode("Normal")
    ExteriorCharacter.ScaleToCamera("Max")

    self.m.tbFilter.nType = self.m.tbFilter.nType or CoinShopExterior.FILTER_ALL
    self.m.tbFilter.nGenre = self.m.tbFilter.nGenre or CoinShopExterior.FILTER_ALL
    self.m.tbFilter.nStatus = self.m.tbFilter.nStatus or CoinShopExterior.FILTER_ALL
    self:InitExteriorFilter()
    UIHelper.SetVisible(self.TogFilter, true)

    if not self.m.bInLinkGoods then
        if self.m.tbFilter.nType == CoinShopExterior.FILTER_ALL then
            self:UpdateExteriorSetList(self.m.tbGoodsList.tSetList, self.m.nPage or 1)
        else
            self:UpdateExteriorSubList(self.m.tbGoodsList.tSubList, self.m.nPage or 1)
        end
    end
end

function UICoinShopGoodsView:InitExteriorFilter()
    local nFilterIndex = 1
    local temp = {}

    local tGenreList = CoinShopData.GetGenreList(self.m.tbTitle.nRewardsClass)
    if #tGenreList > 2 then
        local conf = {
            szType = FilterType.RadioButton,
            szSubType = FilterSubType.Small,
            szTitle = "类型",
            tbList = {},
            tbDefault = {1},
            bGenre = true,
        }
        for i, nValue in ipairs(tGenreList) do
            local szOption = g_tStrings.tGenreString2[nValue]
            table.insert(conf.tbList, szOption)
            if self.m.tbFilter.nGenre == nValue then
                temp[nFilterIndex] = {i}
            end
        end
        FilterDef.CoinShopGoodsExterior[nFilterIndex] = conf
        nFilterIndex = nFilterIndex + 1
    end

    local conf = {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        szTitle = "部位",
        tbList = {},
        tbDefault = {1},
        bType = true,
    }
    for i, nType in ipairs(CoinShopExterior.tFilterType) do
        local szOption = g_tStrings.tExteriorSub[nType]
        table.insert(conf.tbList, szOption)
        if self.m.tbFilter.nType == nType then
            temp[nFilterIndex] = {i}
        end
    end
    FilterDef.CoinShopGoodsExterior[nFilterIndex] = conf
    nFilterIndex = nFilterIndex + 1

    if self.m.tbTitle.bCollect then
        local conf = {
            szType = FilterType.RadioButton,
            szSubType = FilterSubType.Small,
            szTitle = "收集",
            tbList = {},
            tbDefault = {1},
            bStatus = true,
        }
        for i, nStatus in ipairs(CoinShopExterior.tSubStatus) do
            local szOption = g_tStrings.tCoinshopGet[nStatus]
            table.insert(conf.tbList, szOption)
            if self.m.tbFilter.nStatus == nStatus then
                temp[nFilterIndex] = {i}
            end
        end
        FilterDef.CoinShopGoodsExterior[nFilterIndex] = conf
        nFilterIndex = nFilterIndex +  1
    end

    FilterDef.CoinShopGoodsExterior.SetRunTime(temp)
    FilterDef.CoinShopGoodsExterior[nFilterIndex] = nil

    UIHelper.SetVisible(self.BtnContent, self.m.tbFilter.nType == CoinShopExterior.FILTER_ALL)
    UIHelper.SetSelected(self.BtnContent, self.bExteriorSimpleMode, false)
    UIHelper.LayoutDoLayout(self.LayoutTipsBotton)

    self.m.tbShowList = nil
end

function UICoinShopGoodsView:UpdateExteriorSetList(tbList, nPage, bPlayAni)
    if not self.m.tbShowList then
        self.m.tbShowList, self.m.tbSubGenreMap = CoinShopExterior.FilterSetList(tbList, self.m.tbFilter.nGenre, self.m.tbFilter.nStatus, CoinShopExterior.FILTER_ALL, self.bExteriorSimpleMode)
    end
    self:UpdateFilterTexture(CoinShopExterior.IsOnSetFilter(self.m.tbFilter.nGenre, self.m.tbFilter.nStatus, CoinShopExterior.FILTER_ALL))

    local tbShowList, tbSubGenreMap = self.m.tbShowList, self.m.tbSubGenreMap
    local nCount = #tbShowList
    local nTotalPage = math.ceil(nCount / PAGE_EXTERIOR_COUNT)
    nPage = math.min(nPage, nTotalPage)
    nPage = math.max(nPage, 1)
    local nStart = (nPage - 1) * PAGE_EXTERIOR_COUNT + 1
    local nEnd = nPage * PAGE_EXTERIOR_COUNT
    nEnd = math.min(nEnd, nCount)

    self:Recycle(PREFAB_ID.WidgetPropItemCell)
    for i = nStart, nEnd do
        local tbSet = tbShowList[i]
        local tbSubGenre = tbSubGenreMap[tbSet.nSubGenre] or {}
        local suitItem = self:Allocate(PREFAB_ID.WidgetPropItemCell, self.ScrollViewExteriorPropList)
        suitItem:OnInitWithSet(tbSet, true, tbSubGenre)
        if bPlayAni and IsFunction(suitItem.PlayAni) then
            suitItem:PlayAni()
        end
        table.insert(self.m.tbScriptList, suitItem)
    end
    UIHelper.SetVisible(self.ScrollViewExteriorPropList, nCount > 0)
    UIHelper.ScrollViewDoLayout(self.ScrollViewExteriorPropList)
    UIHelper.ScrollToTop(self.ScrollViewExteriorPropList, 0)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewExteriorPropList, self.WidgetArrow)

    self.m.nPage = nPage
    self:UpdatePaginate(nPage, nTotalPage)

    UIHelper.SetVisible(self.WidgetEmpty_Exterior, nCount <= 0)

    local nSetCount = #self.m.tbGoodsList.tSetList
    local nSubCount = #self.m.tbGoodsList.tSubList
    local nSetHave = CoinShopExterior.GetSetHaveInfo(self.m.tbTitle.bCollect)
    local nSubHave = CoinShopExterior.GetSubHaveInfo(self.m.tbTitle.bCollect)
    local szText = FormatString(g_tStrings.COINSHOP_SET_TIP_SHOP, nSetHave, nSetCount, nSubHave, nSubCount)
    local tResult = string.split(szText, "\n")


    UIHelper.SetVisible(self.TogHair, true)
    UIHelper.SetSelected(self.TogHair, Storage.CoinShop.bPreviewMatchHair, false)
    -- if self.m.tbTitle.bCollect then
    --     self.particularsTips:OnInitCollectTips(tResult[1], tResult[2])
    -- else
    --     self.particularsTips:OnInitSmallTips(tResult[1], tResult[2])
    -- end
    -- UIHelper.SetVisible(self.TogParticulars, true)
    UIHelper.LayoutDoLayout(self.LayoutTipsBotton)
end

function UICoinShopGoodsView:UpdateExteriorSubList(tbList, nPage)
    if not self.m.tbShowList then
        self.m.tbShowList = CoinShopExterior.FilterSubList(tbList, self.m.tbFilter.nGenre, self.m.tbFilter.nType, self.m.tbFilter.nStatus)
    end
    self:UpdateFilterTexture(CoinShopExterior.IsOnSubFilter(self.m.tbFilter.nGenre, self.m.tbFilter.nType, self.m.tbFilter.nStatus))

    -- local scriptColor = UIHelper.GetBindScript(self.TogAccept)
    -- scriptColor:SetVisible(false)

    local tbShowList = self.m.tbShowList
    local nCount = #tbShowList
    local nTotalPage = math.ceil(nCount / PAGE_EXTERIOR_COUNT)
    nPage = math.min(nPage, nTotalPage)
    nPage = math.max(nPage, 1)
    local nStart = (nPage - 1) * PAGE_EXTERIOR_COUNT + 1
    local nEnd = nPage * PAGE_EXTERIOR_COUNT
    nEnd = math.min(nEnd, nCount)

    self:Recycle(PREFAB_ID.WidgetPropItemCell)
    for i = nStart, nEnd do
        local tbSub = tbShowList[i]
        local suitItem = self:Allocate(PREFAB_ID.WidgetPropItemCell, self.ScrollViewExteriorPropList)
        suitItem:OnInitWithSub(tbSub, true)
        table.insert(self.m.tbScriptList, suitItem)
    end

    UIHelper.SetVisible(self.ScrollViewExteriorPropList, nCount > 0)
    UIHelper.ScrollViewDoLayout(self.ScrollViewExteriorPropList)
    UIHelper.ScrollToTop(self.ScrollViewExteriorPropList, 0)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewExteriorPropList, self.WidgetArrow)

    self.m.nPage = nPage
    self:UpdatePaginate(nPage, nTotalPage)

    UIHelper.SetVisible(self.WidgetEmpty_Exterior, nCount <= 0)

    local nSetCount = #self.m.tbGoodsList.tSetList
    local nSubCount = #self.m.tbGoodsList.tSubList
    local nSetHave = CoinShopExterior.GetSetHaveInfo(self.m.tbTitle.bCollect)
    local nSubHave = CoinShopExterior.GetSubHaveInfo(self.m.tbTitle.bCollect)
    local szText = FormatString(g_tStrings.COINSHOP_SET_TIP_SHOP, nSetHave, nSetCount, nSubHave, nSubCount)
    local tResult = string.split(szText, "\n")

    UIHelper.SetVisible(self.TogHair, false)
    -- if self.m.tbTitle.bCollect then
    --     self.particularsTips:OnInitCollectTips(tResult[1], tResult[2])
    -- else
    --     self.particularsTips:OnInitSmallTips(tResult[1], tResult[2])
    -- end
    -- UIHelper.SetVisible(self.TogParticulars, true)
    UIHelper.LayoutDoLayout(self.LayoutTipsBotton)
end

function UICoinShopGoodsView:LinkExterior(dwID)
    local hExterior = GetExterior()
    if not hExterior then
        return
    end
    local hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end
    local tbInfo = hExterior.GetExteriorInfo(dwID)

    self.m.tbFilter.nGenre = CoinShopExterior.FILTER_ALL
    self.m.tbFilter.nType = tbInfo.nSubType
    self.m.tbFilter.nStatus = CoinShopExterior.FILTER_ALL
    self.m.tbFilter.nHide = CoinShopExterior.FILTER_SHOW
    self.bExteriorSimpleMode = false
    self:InitExteriorFilter()

    local tbShowList = CoinShopExterior.FilterSubList(self.m.tbGoodsList.tSubList, self.m.tbFilter.nGenre, self.m.tbFilter.nType, self.m.tbFilter.nStatus)
    self.m.tbShowList = tbShowList
    local bFound = false
    for i, tbSub in ipairs(tbShowList) do
        local dwSubID = tbSub[1]
        if dwSubID == dwID then
            local nPage = math.floor((i + PAGE_EXTERIOR_COUNT - 1) / PAGE_EXTERIOR_COUNT)
            self:UpdateExteriorSubList(self.m.tbGoodsList.tSubList, nPage)
            for _, script in ipairs(self.m.tbScriptList) do
                if script.tbSub[1] == dwID then
                    bFound = true
                    CoinShopPreview.LocatePreviewItem(self.ScrollViewExteriorPropList, script._rootNode)
                    break
                end
            end
            FireUIEvent("PREVIEW_SUB", dwID, nil, true, false)
            break
        end
    end

    if not bFound then
        self:UpdateCurPageList(1)
    end
end

function UICoinShopGoodsView:LinkExteriorSet(nSet)
    self.m.tbFilter.nGenre = CoinShopExterior.FILTER_ALL
    self.m.tbFilter.nType = CoinShopExterior.FILTER_ALL
    self.m.tbFilter.nStatus = CoinShopExterior.FILTER_ALL
    self:InitExteriorFilter()

    local tLine = Table_GetExteriorSet(nSet)
    local tSub = tLine.tSub
    local bFound = false
    for i, tSet in ipairs(self.m.tbGoodsList.tSetList) do
        if tSet.nSet == nSet then
            local nPage = math.floor((i + PAGE_EXTERIOR_COUNT - 1) / PAGE_EXTERIOR_COUNT)
            self:UpdateExteriorSetList(self.m.tbGoodsList.tSetList, nPage)
            for _, script in ipairs(self.m.tbScriptList) do
                if script.tbSet.nSet == nSet then
                    bFound = true
                    CoinShopPreview.LocatePreviewItem(self.ScrollViewExteriorPropList, script._rootNode)
                    break
                end
            end
            FireUIEvent("PREVIEW_SET", tSub)
            break
        end
    end

    if not bFound then
        self:UpdateCurPageList(1)
    end
end

function UICoinShopGoodsView:InitRewardsItemPage()
    local bFurniture = self.m.tbTitle.nRewardsClass == REWARDS_CLASS.FURNITURE
    local bHomelandSkin = self.m.tbTitle.nRewardsClass == REWARDS_CLASS.HOMELAND_SKIN
    local bHorse = self.m.tbTitle.nRewardsClass == REWARDS_CLASS.HORSE
    local bHorseRare = self.m.tbTitle.nRewardsClass == REWARDS_CLASS.HORSE_RARE
    local bPet = self.m.tbTitle.nRewardsClass == REWARDS_CLASS.PET
    local bHorseAdornment = self.m.tbTitle.nRewardsClass == REWARDS_CLASS.HORSE_ADORNMENT
    local bRewardSet = self.m.tbTitle.bRewardSet
    if bFurniture then
        self.m.tbFilter.nCatg1Index = self.m.tbFilter.nCatg1Index or 0
        self.m.tbFilter.nCatg2Index = self.m.tbFilter.nCatg2Index or 0
        self:InitFurnitureFilter()
        UIHelper.SetVisible(self.TogFilter, true)
    elseif bHorseAdornment then
        if not self.bAdornmentSimpleMode then
            self.m.tbFilter.nType = self.m.tbFilter.nType or CoinShopRewards.FILTER_ALL
            self:InitHorseAdornmentFilter()
            UIHelper.SetVisible(self.TogFilter, true)
            UIHelper.SetVisible(self.BtnContent, true)
            UIHelper.SetSelected(self.BtnContent, self.bAdornmentSimpleMode, false)
        end
    elseif not self.m.tbFilter.bHideSubClass then
        self:InitRewardsTabFilter()
        -- UIHelper.SetVisible(self.TogFilter, true)
    elseif bRewardSet then
         self.m.tbFilter.nType = CoinShopRewards.FILTER_ALL
        self:InitItemFilter()
        UIHelper.SetVisible(self.TogFilter, true)
    end

    if not bFurniture and not bHomelandSkin and not bHorse and not bPet and not bHorseRare then
        ExteriorCharacter.SetCameraMode("Normal")
        ExteriorCharacter.ScaleToCamera("Max")
    end

    if not self.m.bInLinkGoods then
        self:UpdateRewardsItemList(self.m.tbGoodsList, self.m.nPage or 1)
    end
end

function UICoinShopGoodsView:InitRewardsTabFilter()
    local nIndex = 1
    for nSubClass, tTab in pairs(self.m.tbGoodsList) do
        if nIndex <= #self.tWidgetTypeList then
            local szName = UIHelper.GBKToUTF8(tTab.szName)
            local toggle = UIHelper.GetChildByName(self.tWidgetTypeList[nIndex], "TogType" .. nIndex)
            local label = UIHelper.GetChildByPath(toggle, "ImgBg/LabelType" .. nIndex)
            local labelCheck = UIHelper.GetChildByPath(toggle, "ImgCheck/LabelType" .. nIndex .. "_Check")
            UIHelper.SetString(label, szName)
            UIHelper.SetString(labelCheck, szName)
            UIHelper.SetVisible(self.tWidgetTypeList[nIndex], true)
            UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function(_, bSelected)
                if bSelected then
                    self.m.tbFilter.nSubClass = nSubClass
                    self.m.tbShowList = nil
                    self:UpdateCurPageList(1)
                end
            end)
            UIHelper.SetSelected(toggle, self.m.tbFilter.nSubClass == nSubClass, false)
        else
            UIHelper.SetVisible(self.tWidgetTypeList[nIndex], false)
        end
        nIndex = nIndex + 1
    end
    for i = nIndex, #self.tWidgetTypeList do
        UIHelper.SetVisible(self.tWidgetTypeList[i], false)
    end
    UIHelper.LayoutDoLayout(self.LayoutTypeList)

    self.m.tbShowList = nil
end

function UICoinShopGoodsView:InitFurnitureFilter()

end

function UICoinShopGoodsView:InitHorseAdornmentFilter()
    local temp = {}
    local conf = {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        szTitle = "部位",
        tbList = {},
        tbDefault = {1},
    }
    for i, nType in ipairs(CoinShopRewards.tAdornmentFilter) do
        local szOption = g_tStrings.tHorseEnchantType[nType]
        table.insert(conf.tbList, szOption)
        if self.m.tbFilter.nType == nType then
            temp[1] = {i}
        end
    end
    FilterDef.CoinShopGoodsHorse.SetRunTime(temp)
    FilterDef.CoinShopGoodsHorse[1] = conf

    self.m.tbShowList = nil
end

function UICoinShopGoodsView:GetFilterRewardsItemList(tbList)
    local bFurniture = self.m.tbTitle.nRewardsClass == REWARDS_CLASS.FURNITURE
    local bHorseAdornment = self.m.tbTitle.nRewardsClass == REWARDS_CLASS.HORSE_ADORNMENT
    local bRewardSet = self.m.tbTitle.bRewardSet
    local tbShowList = CoinShopRewards.GetRewardsTabList(tbList, self.m.tbFilter.nSubClass)
    if bFurniture then
        tbShowList = CoinShopRewards.FilterFurnitureList(tbShowList, self.m.tbFilter.nCatg1Index, self.m.tbFilter.nCatg2Index)
    elseif bHorseAdornment then
        tbShowList = CoinShopRewards.FilterHorseAdornmentList(tbShowList, self.m.tbFilter.nType)
    elseif bRewardSet then
        tbShowList = CoinShopRewards.FilterItemList(tbShowList, self.m.tbTitle.nRewardsClass, self.m.tbFilter.nType)
    end
    return tbShowList
end

function UICoinShopGoodsView:UpdateRewardsItemList(tbList, nPage)
    local bPet = self.m.tbTitle.nRewardsClass == REWARDS_CLASS.PET
    local bFurniture = self.m.tbTitle.nRewardsClass == REWARDS_CLASS.FURNITURE
    local bHorseAdornment = self.m.tbTitle.nRewardsClass == REWARDS_CLASS.HORSE_ADORNMENT
    local bRewardSet = self.m.tbTitle.bRewardSet

    if bHorseAdornment and self.bAdornmentSimpleMode then
        self:UpdateHorseAdormentSetList(nPage)
        return
    end

    if not self.m.tbShowList then
        self.m.tbShowList = self:GetFilterRewardsItemList(tbList)
    end
    local tbShowList = self.m.tbShowList
    local tbFilterList, tbUntimelyList = CoinShopRewards.FilterTimeRewardsList(tbShowList)
    if not IsTableEmpty(tbUntimelyList) then
        self.m.tbUntimelyList = tbUntimelyList
    else
        self.m.tbUntimelyList = nil
    end

    if bFurniture then
        self:UpdateFilterTexture(CoinShopRewards.IsOnFurnitureFilter(self.m.tbFilter.nCatg1Index, self.m.tbFilter.nCatg2Index))
    elseif bHorseAdornment then
        self:UpdateFilterTexture(CoinShopRewards.IsOnHorseAdornmentFilter(self.m.tbFilter.nType))
    elseif bRewardSet then
        self:UpdateFilterTexture(CoinShopRewards.IsOnItemFilter(self.m.tbFilter.nType))
    else
        self:UpdateFilterTexture(true)
    end

    local nCount = #tbFilterList
    local nTotalPage = math.ceil(nCount / PAGE_PROP_COUNT)
    nPage = math.min(nPage, nTotalPage)
    nPage = math.max(nPage, 1)
    local nStart = (nPage - 1) * PAGE_PROP_COUNT + 1
    local nEnd = nPage * PAGE_PROP_COUNT
    nEnd = math.min(nEnd, nCount)

    local bHideSubClass = self.m.tbFilter.bHideSubClass
    local scrollView
    if self.m.tbFilter.bHideSubClass then
        scrollView = self.ScrollViewExteriorPropList
    else
        scrollView = self.ScrollViewHarnessList
        UIHelper.SetVisible(self.WidgetHarnessList, true)
        UIHelper.SetVisible(self.BtnHarnessTitle, false)
        UIHelper.SetVisible(self.LayoutTypeList, true)
    end

    self:Recycle(PREFAB_ID.WidgetPropItemCell)
    for i = nStart, nEnd do
        local tbRewardsItem = tbFilterList[i]
        local propItem = self:Allocate(PREFAB_ID.WidgetPropItemCell, scrollView)
        propItem:OnInitWithRewardsItem(tbRewardsItem, true)
        table.insert(self.m.tbScriptList, propItem)
    end
    UIHelper.SetVisible(scrollView, nCount > 0)
    UIHelper.ScrollViewDoLayout(scrollView)
    UIHelper.ScrollToTop(scrollView, 0)
    UIHelper.ScrollViewSetupArrow(scrollView, self.WidgetArrow)

    self.m.nPage = nPage
    self:UpdatePaginate(nPage, nTotalPage)

    UIHelper.SetVisible(self.WidgetEmpty_Exterior, nCount <= 0)

    if nCount > 0 and bPet then
        local tbData = ExteriorCharacter.GetPetData()
        if tbData then
            if not tbData.tItem then
                ExteriorCharacter.PreviewRewardsItem(tbFilterList[1])
            end
        end
    end

    if nCount > 0 and bFurniture then
        local tbData = ExteriorCharacter.GetFurnitureData()
        if tbData then
            if not tbData.tItem then
                ExteriorCharacter.PreviewRewardsItem(tbFilterList[1])
            end
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutTipsBotton)
end

function UICoinShopGoodsView:UpdateHorseAdormentSetList(nPage)
    local tbSetList = CoinShopData.GetShopAdornmentSet()
    local nCount = #tbSetList
    local nTotalPage = math.ceil(nCount / PAGE_PROP_COUNT)
    nPage = math.min(nPage, nTotalPage)
    nPage = math.max(nPage, 1)
    local nStart = (nPage - 1) * PAGE_PROP_COUNT + 1
    local nEnd = nPage * PAGE_PROP_COUNT
    nEnd = math.min(nEnd, nCount)

    self:Recycle(PREFAB_ID.WidgetPropItemCell)
    for i = nStart, nEnd do
        local tbSet = tbSetList[i]
        local propItem = self:Allocate(PREFAB_ID.WidgetPropItemCell, self.ScrollViewHarnessList)
        propItem:OnInitWithAdornmentSet(tbSet)
        table.insert(self.m.tbScriptList, propItem)
    end
    UIHelper.SetVisible(self.WidgetHarnessList, true)
    UIHelper.SetVisible(self.BtnHarnessTitle, true)
    UIHelper.SetVisible(self.LayoutTypeList, false)
    UIHelper.SetVisible(self.ScrollViewHarnessList, nCount > 0)
    UIHelper.ScrollViewDoLayout(self.ScrollViewHarnessList)
    UIHelper.ScrollToTop(self.ScrollViewHarnessList, 0)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewHarnessList, self.WidgetArrow)

    self.m.nPage = nPage
    self:UpdatePaginate(nPage, nTotalPage)

    UIHelper.SetVisible(self.WidgetEmpty_Exterior, nCount <= 0)

    UIHelper.LayoutDoLayout(self.LayoutTipsBotton)
end

function UICoinShopGoodsView:LinkRewardsItem(dwID)
    local tbItem = Table_GetRewardsItem(dwID)

    self.m.tbFilter.nSubClass = tbItem.nSubClass
    self:InitRewardsTabFilter()
    self.m.tbShowList = self:GetFilterRewardsItemList(self.m.tbGoodsList)
    local bFound = false
    for i, tbRewardsItem in ipairs(self.m.tbShowList) do
        if tbRewardsItem.dwLogicID == dwID then
            local nPage = math.floor((i + PAGE_PROP_COUNT - 1) / PAGE_PROP_COUNT)
            self:UpdateRewardsItemList(self.m.tbGoodsList, nPage)
            for _, script in ipairs(self.m.tbScriptList) do
                if script.tbRewardsItem.dwLogicID == dwID then
                    bFound = true
                    CoinShopPreview.LocatePreviewItem(self.ScrollViewExteriorPropList, script._rootNode)
                    break
                end
            end
            ExteriorCharacter.PreviewRewardsItem(tbRewardsItem)
            break
        end
    end
    if not bFound then
        self:UpdateCurPageList(1)
    end
end

function UICoinShopGoodsView:InitHairPage()
    UIHelper.SetVisible(self._rootNode, false)
    UIHelper.SetVisible(self.WidgetAnchorHair, true)
    self:UpdateHairList(self.m.tbGoodsList, self.m.nPage or 1)
    ExteriorCharacter.SetCameraMode("BuildHair")
    ExteriorCharacter.UpdateMDLScale()
    ExteriorCharacter.ScaleToCamera("BuildFaceMin")
    FireUIEvent("EXTERIOR_CHARACTER_SET_CAMERA_RADIUS", "CoinShop_View", "CoinShop", "BuildFaceMin", nil)
end

function UICoinShopGoodsView:UpdateHairList(tbList, nPage)
    self.scriptHairPage = self.scriptHairPage or UIHelper.GetBindScript(self.WidgetAnchorHair)
    self.scriptHairPage:OnEnter(self.m.tbFilter.nSubClass, 1, nPage)
end

function UICoinShopGoodsView:LinkHair(nHairID)
    -- DX也只是抛了个事件
    if nHairID == 0 then
        return
    end
    FireUIEvent("PREVIEW_HAIR", nHairID, nil, true, true, false)
end

function UICoinShopGoodsView:InitWeaponPage()
    self.m.tbFilter.nStatus = self.m.tbFilter.nStatus or CoinShopWeapon.FILTER_ALL
    self.m.tbFilter.nType = self.m.tbFilter.nType or CoinShopWeapon.FILTER_ALL
    if not self.m.tbFilter.nSubType then
        for nSubType in pairs(self.m.tbGoodsList) do
            self.m.tbFilter.nSubType = nSubType
            break
        end
    end
    self:InitWeaponFilter()
    UIHelper.SetVisible(self.TogFilter, true)

    if not self.m.bInLinkGoods then
        self:UpdateWeaponList(self.m.tbGoodsList, self.m.nPage or 1)
    end

    ExteriorCharacter.SetCameraMode("Normal")
    ExteriorCharacter.ScaleToCamera("Max")
end

function UICoinShopGoodsView:InitWeaponFilter()
    local nFilterIndex = 1
    local temp = {}

    local conf = {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        szTitle = "收集",
        tbList = {},
        tbDefault = {1},
        bStatus = true,
    }
    for i, nStatus in ipairs(CoinShopWeapon.tStatus) do
        local szOption = g_tStrings.tCoinshopGet[nStatus]
        table.insert(conf.tbList, szOption)
        if self.m.tbFilter.nStatus == nStatus then
            temp[nFilterIndex] = {i}
        end
    end
    FilterDef.CoinShopGoodsWeapon[nFilterIndex] = conf
    nFilterIndex = nFilterIndex + 1

    local tFilterType = CoinShopData.GetWeaponFilter()
    if #tFilterType > 2 then
        local conf = {
            szType = FilterType.RadioButton,
            szSubType = FilterSubType.Small,
            szTitle = "分类",
            tbList = {},
            tbDefault = {1},
            bType = true,
        }
        for i, nType in ipairs(tFilterType) do
            local szOption = CoinShopWeapon.GetTypeFilterString(nType)
            table.insert(conf.tbList, szOption)
            if self.m.tbFilter.nType == nType then
                temp[nFilterIndex] = {i}
            end
        end
        FilterDef.CoinShopGoodsWeapon[nFilterIndex] = conf
        nFilterIndex = nFilterIndex + 1
    end

    FilterDef.CoinShopGoodsWeapon.SetRunTime(temp)
    FilterDef.CoinShopGoodsWeapon[nFilterIndex] = nil

    local nIndex = 1
    for nSubType, tTab in pairs(self.m.tbGoodsList) do
        if nIndex <= #self.tWidgetTypeList then
            local szName = UIHelper.GBKToUTF8(tTab[1].szSubName)
            local toggle = UIHelper.GetChildByName(self.tWidgetTypeList[nIndex], "TogType" .. nIndex)
            local label = UIHelper.GetChildByPath(toggle, "ImgBg/LabelType" .. nIndex)
            local labelCheck = UIHelper.GetChildByPath(toggle, "ImgCheck/LabelType" .. nIndex .. "_Check")
            UIHelper.SetString(label, szName)
            UIHelper.SetString(labelCheck, szName)
            UIHelper.SetVisible(self.tWidgetTypeList[nIndex], true)
            UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function(_, bSelected)
                if bSelected then
                    self.m.tbFilter.nSubType = nSubType
                    self.m.tbShowList = nil
                    self:UpdateCurPageList(1)
                end
            end)
            UIHelper.SetSelected(toggle, self.m.tbFilter.nSubType == nSubType, false)
        else
            UIHelper.SetVisible(self.tWidgetTypeList[nIndex], false)
        end
        nIndex = nIndex + 1
    end
    for i = nIndex, #self.tWidgetTypeList do
        UIHelper.SetVisible(self.tWidgetTypeList[i], false)
    end
    UIHelper.LayoutDoLayout(self.LayoutTypeList)

    self.m.tbShowList = nil
end

function UICoinShopGoodsView:InitItemFilter()
    local temp = {}
    local conf = {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        szTitle = UIHelper.GBKToUTF8(self.m.tbTitle.szName) .. "列表",
        tbList = {},
        tbDefault = {1},
        bStatus = true,
    }
    local nIndex = 1
    self.m.tbFilter.tItemType = {}
    self.m.tbFilter.tItemType[nIndex] = CoinShopRewards.FILTER_ALL
    table.insert(conf.tbList, "全部")
    if self.m.tbFilter.nType == CoinShopRewards.FILTER_ALL then
        temp[1] = {nIndex}
    end

    local tSetList = CoinShopData.GetShopRewardSet(self.m.tbTitle.nRewardsClass)
    for nSetID, tLine in ipairs(tSetList) do
        local nSetID = tLine.nSetID
        local szOption = tLine.szSetName
        table.insert(conf.tbList, szOption)
        nIndex = nIndex + 1
        self.m.tbFilter.tItemType[nIndex] = nSetID
        if self.m.tbFilter.nType == nSetID then
            temp[1] = {nSetID}
        end
    end
    FilterDef.CoinShopGoodsItem.SetRunTime(temp)
    FilterDef.CoinShopGoodsItem[1] = conf

    self.m.tbShowList = nil
end

function UICoinShopGoodsView:UpdateWeaponList(tbList, nPage)
    if not self.m.tbShowList then
        local tbSubTypeList = tbList[self.m.tbFilter.nSubType] or {}
        self.m.tbShowList = CoinShopWeapon.FilterList(tbSubTypeList, true, self.m.tbFilter.nStatus, self.m.tbFilter.nType)
    end
    self:UpdateFilterTexture(CoinShopWeapon.IsOnFilter(self.m.tbFilter.nStatus, self.m.tbFilter.nType))

    local tbShowList = self.m.tbShowList
    local nCount = #tbShowList
    local nTotalPage = math.ceil(nCount / PAGE_PROP_COUNT)
    nPage = math.min(nPage, nTotalPage)
    nPage = math.max(nPage, 1)
    local nStart = (nPage - 1) * PAGE_PROP_COUNT + 1
    local nEnd = nPage * PAGE_PROP_COUNT
    nEnd = math.min(nEnd, nCount)

    self:Recycle(PREFAB_ID.WidgetPropItemCell)
    for i = nStart, nEnd do
        local t = tbShowList[i]
        local propItem = self:Allocate(PREFAB_ID.WidgetPropItemCell, self.ScrollViewHarnessList)
        propItem:OnInitWithWeapon(t.dwID, true)
        table.insert(self.m.tbScriptList, propItem)
    end
    UIHelper.SetVisible(self.WidgetHarnessList, true)
    UIHelper.SetVisible(self.BtnHarnessTitle, false)
    UIHelper.SetVisible(self.LayoutTypeList, true)
    UIHelper.SetVisible(self.ScrollViewHarnessList, nCount > 0)
    UIHelper.ScrollViewDoLayout(self.ScrollViewHarnessList)
    UIHelper.ScrollToTop(self.ScrollViewHarnessList, 0)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewHarnessList, self.WidgetArrow)

    self.m.nPage = nPage
    self:UpdatePaginate(nPage, nTotalPage)

    UIHelper.SetVisible(self.WidgetEmpty_Exterior, nCount <= 0)

    -- local nHave = CoinShopWeapon.GetHaveInfo(self.m.tbGoodsList)
    -- local szTips = FormatString(g_tStrings.COINSHOP_SET_TIP2, nHave, #self.m.tbGoodsList)
    -- self.particularsTips:OnInitCollectTips(szTips, "")
    -- UIHelper.SetVisible(self.TogParticulars, true)
    UIHelper.LayoutDoLayout(self.LayoutTipsBotton)
end

function UICoinShopGoodsView:LinkWeapon(dwID)
    local hExterior = GetExterior()
    if not hExterior then
        return
    end

    local hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end

    local tInfo = CoinShop_GetWeaponInfo(dwID)

    self.m.tbFilter.nStatus = CoinShopWeapon.FILTER_ALL
    self.m.tbFilter.nType = CoinShopWeapon.FILTER_ALL
    self.m.tbFilter.nSubType = tInfo.nSubType
    self:InitWeaponFilter()

    local bFound = false
    local tbSubTypeList = self.m.tbGoodsList[tInfo.nSubType] or {}
    for i, tbWeapon in ipairs(tbSubTypeList) do
        if tbWeapon.dwID == dwID then
            local nPage = math.floor((i + PAGE_PROP_COUNT - 1)/ PAGE_PROP_COUNT)
            self:UpdateWeaponList(self.m.tbGoodsList, nPage)
            for _, script in ipairs(self.m.tbScriptList) do
                if script.dwWeaponID == dwID then
                    bFound = true
                    CoinShopPreview.LocatePreviewItem(self.ScrollViewExteriorPropList, script._rootNode)
                    break
                end
            end
            FireUIEvent("PREVIEW_WEAPON", dwID, true)
            break
        end
    end

    if not bFound then
        self:UpdateCurPageList(1)
    end
end

function UICoinShopGoodsView:UpdateListItemState()
    if self.m and self.m.tbScriptList then
        for _, script in ipairs(self.m.tbScriptList) do
            if script.UpdateItemState then
                script:UpdateItemState()
            end
        end
    end
end

function UICoinShopGoodsView:ClearSelect()
    UIHelper.SetSelected(self.TogParticulars, false)
    UIHelper.SetSelected(self.TogFilter, false)

    if self.m and self.m.tbScriptList then
        for _, script in ipairs(self.m.tbScriptList) do
            if script.itemIcon then
                script.itemIcon:SetSelected(false)
            end
        end
    end
end

function UICoinShopGoodsView:OnSelectedFilter(bSelected)
    local bFurnitrue = self.m.tbTitle and self.m.tbTitle.nType == COIN_SHOP_GOODS_TYPE.ITEM and self.m.tbTitle.nRewardsClass == REWARDS_CLASS.FURNITURE
    local bNavigationFilterSelected = bSelected and bFurnitrue

    local bFilterTipsSelected = bSelected and not bNavigationFilterSelected
    if bFilterTipsSelected and self.m.tbTitle then
        if self.m.tbTitle.nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogFilter, TipsLayoutDir.BOTTOM_RIGHT, FilterDef.CoinShopGoodsExterior)
        elseif self.m.tbTitle.nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogFilter, TipsLayoutDir.BOTTOM_RIGHT, FilterDef.CoinShopGoodsWeapon)
        elseif self.m.tbTitle.nType == COIN_SHOP_GOODS_TYPE.ITEM then
            local bHorseAdornment = self.m.tbTitle.nRewardsClass == REWARDS_CLASS.HORSE_ADORNMENT
            if bHorseAdornment then
                TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogFilter, TipsLayoutDir.BOTTOM_RIGHT, FilterDef.CoinShopGoodsHorse)
            elseif self.m.tbTitle.bRewardSet then
                TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogFilter, TipsLayoutDir.BOTTOM_RIGHT, FilterDef.CoinShopGoodsItem)
            end
        end
    end
    -- UIHelper.SetVisible(self.filterTips._rootNode, bFilterTipsSelected)
    -- if bFilterTipsSelected then
    --     self.filterTips:Refresh()
    -- end
end

function UICoinShopGoodsView:UpdateFilterTexture(bFilter)
    UIHelper.SetVisible(self.ImgScreen, not bFilter)
    UIHelper.SetVisible(self.ImgScreenSelect, bFilter)
end

function UICoinShopGoodsView:OnListSizeChanged()
    local _, screenHeight = UIHelper.GetContentSize(self.ScrollViewExteriorPropList)
    local oldPercent = UIHelper.GetScrollPercent(self.ScrollViewExteriorPropList)
    local _, oldHeight = UIHelper.GetInnerContainerSize(self.ScrollViewExteriorPropList)
    local pos = oldPercent * (oldHeight - screenHeight)
    UIHelper.ScrollViewDoLayout(self.ScrollViewExteriorPropList)
    local _, newHeight = UIHelper.GetInnerContainerSize(self.ScrollViewExteriorPropList)
    local newPercent = pos / (newHeight - screenHeight)
    UIHelper.ScrollToPercent(self.ScrollViewExteriorPropList, newPercent, 0)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewExteriorPropList, self.WidgetArrow)
end

function UICoinShopGoodsView:CheckUntimelyList()
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

function UICoinShopGoodsView:InitPool()
    if not self.tbPoolMap then
        self.tbPoolMap = {}
    end

    self.tbPoolMap[PREFAB_ID.WidgetPropItemCell] = PrefabPool.New(PREFAB_ID.WidgetPropItemCell)
end

function UICoinShopGoodsView:UnInitPool()
    if not self.tbPoolMap then
        return
    end

    for _, pool in pairs(self.tbPoolMap) do
        pool:Dispose()
    end

    self.tbPoolMap = nil
end

function UICoinShopGoodsView:Allocate(nPrefabID, parent)
    if not self.tbPoolMap then
        return
    end

    local pool = self.tbPoolMap[nPrefabID]
    if not pool then
        return
    end

    if not safe_check(parent) then
        return
    end

    local node, script = pool:Allocate(parent)
    return script
end

function UICoinShopGoodsView:Recycle(nPrefabID)
    if not self.tbPoolMap then
        return
    end

    local pool = self.tbPoolMap[nPrefabID]
    if not pool then
        return
    end

    for k, v in ipairs(self.m.tbScriptList or {}) do
        pool:Recycle(v._rootNode)
    end

    self.m.tbScriptList = {}
end

--- 根据当前选中的标题类型刷新推荐浮窗显示
-- @param eGoodsType 选中物品的类型（可选，用于区分同类型不同物品）
-- @param dwGoodsID  选中物品的ID（可选）
function UICoinShopGoodsView:RefreshShareStationRecommend(eGoodsType, dwGoodsID)
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
    -- 调用方计算标题：特效 key 为 string，需用 Table_GetPendantEffectInfo 取名
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

--- 从当前预览数据构建推荐请求用的 tExteriorList
-- EXTERIOR 分支含筛选器感知：套装视图取全槽位，单件筛选视图只取对应槽位
function UICoinShopGoodsView:BuildExteriorListFromPreview(nType, nClass)
    local tExteriorList = {}
    local tRoleViewData = ExteriorCharacter.GetRoleData()
    if not tRoleViewData then
        return tExteriorList
    end

    if nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
        -- 根据筛选器状态决定参与推荐的外装槽位
        local nFilterType = self.m.tbFilter and self.m.tbFilter.nType
        local bSetView = (not nFilterType) or (nFilterType == CoinShopExterior.FILTER_ALL)

        local tBoxIndices = {}
        if bSetView then
            for nBoxIndex = 1, EXTERIOR_SUB_NUMBER do
                table.insert(tBoxIndices, nBoxIndex)
            end
        elseif nFilterType ~= CoinShopExterior.FILTER_ALL then
            local nBox = Exterior_SubToBoxIndex(nFilterType)
            if nBox then
                table.insert(tBoxIndices, nBox)
            end
        end

        if #tBoxIndices == 0 then
            -- 未判定出明确部位时回退为全槽位，避免界面状态异常时推荐空白
            for nBoxIndex = 1, EXTERIOR_SUB_NUMBER do
                table.insert(tBoxIndices, nBoxIndex)
            end
        end

        local bFilterByClass = nClass and nClass > 0
        for _, nIndex in ipairs(tBoxIndices) do
            local tData = tRoleViewData[nIndex]
            if tData and tData.dwID and tData.dwID > 0 then
                local nSub = Exterior_BoxIndexToRepresentSub(nIndex)
                if nSub then
                    if bFilterByClass then
                        local nPreviewClass = ShareExteriorData.GetExteriorClass(tData.dwID)
                        if nPreviewClass == nClass then
                            tExteriorList[nSub] = { tData.dwID }
                        end
                    else
                        tExteriorList[nSub] = { tData.dwID }
                    end
                end
            end
        end
    elseif nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
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

--- 当推荐面板已打开时，随预览数据变化刷新推荐内容
-- 修复：面板可见但 toggle 未选中时也应刷新（切页后 toggle 状态可能未同步）
function UICoinShopGoodsView:RefreshRecommendIfOpen(eGoodsType, dwGoodsID)
    local bTogSelected = false
    if self.TogRecommend and UIHelper.GetVisible(self.TogRecommend) and UIHelper.GetSelected(self.TogRecommend) then
        bTogSelected = true
    end
    if self.TogRecommend_Hair and UIHelper.GetVisible(self.TogRecommend_Hair) and UIHelper.GetSelected(self.TogRecommend_Hair) then
        bTogSelected = true
    end

    if bTogSelected then
        self:RefreshShareStationRecommend(eGoodsType, dwGoodsID)
    end
end

return UICoinShopGoodsView