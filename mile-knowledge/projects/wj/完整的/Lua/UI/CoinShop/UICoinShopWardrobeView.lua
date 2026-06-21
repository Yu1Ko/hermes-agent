-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopWardrobeView
-- Date: 2023-02-23 17:39:59
-- Desc: ?
-- ---------------------------------------------------------------------------------

local PAGE_EXTERIOR_COUNT = 6
local PAGE_PROP_COUNT = 6
local PAGE_NEW_FACE_COUNT = 7
local PAGE_BOX_COUNT = 28
local PAGE_POSTURE_COUNT = 9

local function MakeTitleKey(tbTitle, nSubClass)
    if tbTitle.bOutfit then
        return "bOutfit"
    end
    local szKey = string.format("%d_%d", tbTitle.nType, tbTitle.nRewardsClass)
    if nSubClass then
        szKey = string.format("%s_%d", szKey, nSubClass)
    end
    return szKey
end

local UICoinShopWardrobeView = class("UICoinShopWardrobeView")

function UICoinShopWardrobeView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tPageCache = {}
    self.m = {}
    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)
    UIHelper.SetScrollViewCombinedBatchEnabled(self.ScrollViewWardrobeCardList, false)
end

function UICoinShopWardrobeView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)

    CoinShopMyBodyData.UnInit()
    CoinShopMyNewFaceData.UnInit()
    CoinShopMyFaceData.UnInit()
    FilterDef.CoinShopWardrobeEffect.Reset()
end

function UICoinShopWardrobeView:BindUIEvent()
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

    UIHelper.BindUIEvent(self.TogFilter, EventType.OnSelectChanged, function (_, bSelected)
        self:OnSelectedFilter(bSelected)
    end)

    UIHelper.BindUIEvent(self.TogHairFilter, EventType.OnClick, function (_, bSelected)
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogHairFilter, TipsLayoutDir.BOTTOM_RIGHT, FilterDef.CoinShowHairType)
    end)

    UIHelper.BindUIEvent(self.TogHairDyeing, EventType.OnClick, function ()
        local tHair = ExteriorCharacter.GetPreviewHair() or {}
        local dwID = tHair.nHairID
        Event.Dispatch(EventType.OnCoinShopStartBuildHairDye, dwID)
    end)

    UIHelper.BindUIEvent(self.TogParticulars, EventType.OnSelectChanged, function (_, bSelected)
        UIHelper.SetVisible(self.particularsTips._rootNode, bSelected)
    end)

    UIHelper.BindUIEvent(self.BtnRenameCloud, EventType.OnClick, function ()
        self:StorageOutfitToServer()
    end)

    UIHelper.BindUIEvent(self.BtnCompletelyDelete01, EventType.OnClick, function ()
        self:DeleteOutfit()
    end)

    UIHelper.BindUIEvent(self.BtnCloudCancel, EventType.OnClick, function ()
        self:StorageOutfitToLocal()
    end)

    UIHelper.BindUIEvent(self.TogDIY, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            -- 打开自定义面板时关闭推荐面板，避免重叠
            Event.Dispatch(EventType.OnCoinShopRecommendOpenClose, false)
            if self.m.tbTitle and self.m.tbTitle.nType == COIN_SHOP_GOODS_TYPE.ITEM then
                if self.m.tbTitle.nRewardsClass == REWARDS_CLASS.EFFECT then
                    self.scriptCustomPendant:EffectOpen()
                else
                    local nEquipSub = CoinShop_RewardsClassToSub(self.m.tbTitle.nRewardsClass)
                    local nType = Exterior_SubToRepresentSub(nEquipSub)
                    self.scriptCustomPendant:Open(nType)
                end

            end
        else
            self.scriptCustomPendant:Close(false)
        end
    end)

    UIHelper.BindUIEvent(self.TogRecommend, EventType.OnSelectChanged, function(_, bSelected)
        Event.Dispatch(EventType.OnCoinShopRecommendOpenClose, bSelected)
    end)
end

function UICoinShopWardrobeView:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        self:ClearSelect()
        self.scriptFilter = nil
    end)

    Event.Reg(self, EventType.OnCoinShopEnterReplaceOutfit, function ()
        self:OnEnterReplaceOutfit()
    end)

    Event.Reg(self, EventType.OnCoinShopCancelReplaceOutfit, function ()
        self:OnCancelReplaceOutfit()
    end)

    Event.Reg(self, EventType.OnCoinShopWardrobeUpdateFaceList, function ()
        self:UpdateCurPageList()
    end)

    Event.Reg(self, EventType.OnCoinShopWardrobeUpdateNewFaceList, function ()
        self:UpdateCurPageList()
    end)

    Event.Reg(self, EventType.OnCoinShopWardrobeUpdateBodyList, function ()
        self:UpdateCurPageList()
    end)

    Event.Reg(self, EventType.OnCoinShopWardrobeUpdateHairList, function ()
        self:UpdateCurPageList()
    end)

    Event.Reg(self, "REPLACE_OUTFIT_SUCCESS", function ()
        if self.m.tbTitle and self.m.tbTitle.bOutfit then
            self:RefreshOutfitList()
        end
    end)

    Event.Reg(self, "SAVE_OUTFIT_SUCCESS", function ()
        if self.m.tbTitle and self.m.tbTitle.bOutfit then
            self:RefreshOutfitList()
        end
    end)

    Event.Reg(self, "DELETE_OUTFIT_SUCCESS", function ()
        if self.m.tbTitle and self.m.tbTitle.bOutfit then
            self:RefreshOutfitList()
        end
    end)

    Event.Reg(self, "COIN_SHOP_PRESET_INFO_CHANGED", function (dwIndex, nParam, nMode)
        if self.m.tbTitle and self.m.tbTitle.bOutfit then
            self:UpdateOutfitServerNum()
            if nMode == COIN_SHOP_PRESET_NOTIFY_MODE.ADD then
                local tbOutfit = self.m.tbGoodsList[nParam]
                tbOutfit.dwIndex = dwIndex
            elseif nParam == -1 or nMode == COIN_SHOP_PRESET_NOTIFY_MODE.REPLACE then
                self:RefreshOutfitList()
            end
        end
    end)

    Event.Reg(self, "COINSHOPVIEW_ROLE_DATA_UPDATE", function ()
        if self.m.tbTitle and self.m.tbTitle.nType == COIN_SHOP_GOODS_TYPE.HAIR then
            self:UpdateCurPageList()
            return
        end

        self:UpdateListItemState()

        self:CheckCustomPendantToggle()
        self:CheckCustomEffectToggle()
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

    Event.Reg(self, "BAG_ITEM_UPDATE", function ()
        if self.m.tbTitle then
            self:RefreshGoodsList()
        end
    end)

    Event.Reg(self, "BANK_ITEM_UPDATE", function ()
        if self.m.tbTitle then
            self:RefreshGoodsList()
        end
    end)

    Event.Reg(self, "DESTROY_ITEM", function ()
        if self.m.tbTitle then
            self:RefreshGoodsList()
        end
    end)

    Event.Reg(self, "CUB_ITEM_UPDATE", function ()
        if self.m.tbTitle then
            self:RefreshGoodsList()
        end
    end)

    Event.Reg(self, "ON_EXTERIOR_HIDE_FLAG_UPDATE", function()
        if self.m.tbTitle then
            self:RefreshGoodsList()
        end
    end)

    Event.Reg(self, "COIN_SHOP_BUY_RESPOND", function ()
        if self.m.tbTitle then
            if self.m.tbTitle.nType ==  COIN_SHOP_GOODS_TYPE.HAIR then
                self:InitHairPage()
            end
            self:RefreshGoodsList()
        end
    end)

    Event.Reg(self, "LIFTED_FACE_CHANGE", function ()
        if self.m.tbTitle and self.m.tbTitle.nType == COIN_SHOP_GOODS_TYPE.FACE then
            self:InitFacePage()
            self:RefreshGoodsList()
        end
    end)

    Event.Reg(self, "LIFTED_FACE_ADD", function ()
        if self.m.tbTitle and self.m.tbTitle.nType == COIN_SHOP_GOODS_TYPE.FACE then
            self:InitFacePage()
            self:RefreshGoodsList()
        end
    end)

    Event.Reg(self, "LIFTED_FACE_CHANGE_V2", function ()
        if self.m.tbTitle and CoinShop_IsNewFaceType(self.m.tbTitle.nType, self.m.tbTitle.nRewardsClass) then
            self:InitNewFacePage()
            self:RefreshGoodsList()
        end
    end)

    Event.Reg(self, "LIFTED_FACE_ADD_V2", function ()
        if self.m.tbTitle and CoinShop_IsNewFaceType(self.m.tbTitle.nType, self.m.tbTitle.nRewardsClass) then
            self:InitNewFacePage()
            self:RefreshGoodsList()
        end
    end)

    Event.Reg(self, "ON_CHANGE_BODY_BONE_NOTIFY", function ()
        if self.m.tbTitle and CoinShop_IsBodyType(self.m.tbTitle.nType, self.m.tbTitle.nRewardsClass) then
            self:InitBodyPage()
            self:RefreshGoodsList()
        end
    end)

    Event.Reg(self, "ON_EQUIP_BODY_BONE_NOTIFY", function ()
        if self.m.tbTitle and CoinShop_IsBodyType(self.m.tbTitle.nType, self.m.tbTitle.nRewardsClass) then
            self:InitBodyPage()
            self:RefreshGoodsList()
        end
    end)

    Event.Reg(self, "ON_CHANGE_PLAYER_IDLE_ACTION_NOTIFY", function()
        if self.m.tbTitle and self.m.tbTitle.nType == COIN_SHOP_GOODS_TYPE.IDLE_ACTION then
            self:RefreshGoodsList()
        end
    end)

    Event.Reg(self, EventType.OnCoinShopCustomPendantOpenClose, function (bOpen)
        UIHelper.SetSelected(self.TogDIY, bOpen, false)
    end)

    Event.Reg(self, EventType.OnCoinShopLayoutPetUpdate, function()
        UIHelper.LayoutDoLayout(self.LayoutPet)
    end)

    Event.Reg(self, EventType.OnCoinShopListSizeChanged, function(bShop)
        if not bShop then
            self:OnListSizeChanged()
        end
    end)

    Event.Reg(self, EventType.OnFilterSelectChanged, function(szKey, tbSelected)
        if szKey == FilterDef.CoinShopWardrobeExterior.Key then
            self:UpdateExteriorFilterMutex(tbSelected)
            if self.scriptFilter then
                self.scriptFilter:Refresh()
            end
        end
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.CoinShowHairType.Key then
            if self.m.tbTitle then
                if self.m.tbTitle.nType ==  COIN_SHOP_GOODS_TYPE.HAIR then
                    self:InitHairPage()
                end
                self:RefreshGoodsList()
            end
        elseif szKey == FilterDef.CoinShopWardrobeExterior.Key then
            for i, tbData in ipairs(tbSelected) do
                if FilterDef.CoinShopWardrobeExterior[i].bHide then
                    self.m.tbFilter.nHide = CoinShopExterior.tFilterHide[tbData[1]]
                elseif FilterDef.CoinShopWardrobeExterior[i].bGenre then
                    local tGenreList = CoinShopData.GetMyGenreList(self.m.tbTitle.nRewardsClass)
                    self.m.tbFilter.nGenre = tGenreList[tbData[1]]
                elseif FilterDef.CoinShopWardrobeExterior[i].bType then
                    self.m.tbFilter.nType = CoinShopExterior.tFilterType[tbData[1]]
                end
            end
            self:UpdateCurPageList(1)
        elseif szKey == FilterDef.CoinShopWardrobeWeapon.Key then
            for i, tbData in ipairs(tbSelected) do
                if FilterDef.CoinShopWardrobeWeapon[i].bType then
                    local tFilterType = CoinShopData.GetWeaponFilter()
                    self.m.tbFilter.nType = tFilterType[tbData[1]]
                end
            end
            self:UpdateCurPageList(1)
        elseif szKey == FilterDef.CoinShopWardrobeEffect.Key then
            if self.m.tbTitle then
                self:RefreshGoodsList(1)
                self.scriptCustomPendant:Close(false)
            end
        end
    end)

    Event.Reg(self, "PLAYER_SFX_CHANGE", function ()
        self:UpdateCurPageList()
    end)

    --"ON_PENDANT_LIST_CHANGED"   "ADD_EXTERIOR"
end

function UICoinShopWardrobeView:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopWardrobeView:UpdateInfo()
end

function UICoinShopWardrobeView:UpdateCurPageList(nPage)
    if not nPage then
        nPage = self.m.nPage
    end
    if self.m.tbTitle.bOutfit then
        self:UpdateOutfitList(self.m.tbGoodsList, nPage)
    elseif self.m.tbTitle.nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
        if self.m.tbFilter.nType == CoinShopExterior.FILTER_ALL or self.m.tbFilter.nHide == CoinShopExterior.FILTER_HIDE then
            self:UpdateExteriorSetList(self.m.tbGoodsList.tSetList, nPage)
        else
            self:UpdateExteriorSubList(self.m.tbGoodsList.tSubList, nPage)
        end
    elseif self.m.tbTitle.nType == COIN_SHOP_GOODS_TYPE.ITEM then
        local nEquipSub = CoinShop_RewardsClassToSub(self.m.tbTitle.nRewardsClass)
        local nPendantType = GetPendantTypeByEquipSub(nEquipSub)
        if nPendantType then
            self:UpdatePendantList(self.m.tbGoodsList, nPage)
        elseif self.m.tbTitle.nRewardsClass == REWARDS_CLASS.CLOTH_PENDANT_PET then
            self:UpdatePendantPetList(self.m.tbGoodsList, nPage)
        elseif self.m.tbTitle.nRewardsClass == REWARDS_CLASS.EFFECT then
            self:UpdateEffectList(self.m.tbGoodsList, nPage)
        end
    elseif self.m.tbTitle.nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        self:UpdateWeaponList(self.m.tbGoodsList, nPage)
    elseif self.m.tbTitle.nType == COIN_SHOP_GOODS_TYPE.IDLE_ACTION then
        self:UpdatePostureList(self.m.tbGoodsList, nPage)
    elseif self.m.tbTitle.nType == COIN_SHOP_GOODS_TYPE.HAIR then
        self:UpdateHairList(self.m.tbGoodsList, nPage)
    elseif self.m.tbTitle.nType == COIN_SHOP_GOODS_TYPE.FACE then
        self:UpdateFaceList(self.m.tbGoodsList, nPage)
    elseif CoinShop_IsNewFaceType(self.m.tbTitle.nType, self.m.tbTitle.nRewardsClass) then
        self:UpdateNewFaceList(self.m.tbGoodsList, nPage)
    elseif CoinShop_IsBodyType(self.m.tbTitle.nType, self.m.tbTitle.nRewardsClass) then
        self:UpdateBodyList(self.m.tbGoodsList, nPage)
    end
end


local function ShouldShowRecommend(tbTitle)
    if not tbTitle or (tbTitle.nTitleClass ~= 8 and tbTitle.nTitleClass ~= 12) then
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

function UICoinShopWardrobeView:UpdateGoodList(tbTitle)
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
    ExteriorCharacter.ScaleToCamera("Max")

    self.m = {}
    self.m.tbTitle = tbTitle
    self.m.tbFilter = {}

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
    UIHelper.SetVisible(self.TogHairFilter, false)
    UIHelper.SetVisible(self.TogHairDyeing, false)
    UIHelper.SetVisible(self.ImgCloud, false)
    UIHelper.SetVisible(self.TogParticulars, false)
    UIHelper.SetVisible(self.WidgetReplaceList, false)
    UIHelper.ToggleGroupRemoveAllToggle(self.WidgetReplaceList)
    UIHelper.RemoveAllChildren(self.ScrollViewReplaceList)
    UIHelper.SetVisible(self.ScrollViewWardrobeCardList, false)
    UIHelper.SetVisible(self.WidgetFacePage, false)
    UIHelper.RemoveAllChildren(self.ScrollViewWardrobeCardList)
    UIHelper.SetVisible(self.ScrollViewPropList, false)
    UIHelper.RemoveAllChildren(self.ScrollViewPropList)
    UIHelper.SetVisible(self.ScrollViewStandbyList, false)
    UIHelper.RemoveAllChildren(self.ScrollViewStandbyList)
    UIHelper.SetVisible(self.WidgetPreinstall, false)
    UIHelper.SetSelected(self.TogDIY, false)
    UIHelper.SetVisible(self.TogDIY, false)
    UIHelper.SetVisible(self.BtnFaceDes, false)
    UIHelper.SetVisible(self.ScrollViewSpecialEffectList, false)
    Event.Dispatch(EventType.OnShowFaceCodeBtn, false, UI_COINSHOP_GENERAL.MY_ROLE)
    Event.Dispatch(EventType.OnShowBodyCodeBtn, false, UI_COINSHOP_GENERAL.MY_ROLE)

    local bShowRecommend = ShouldShowRecommend(tbTitle)
    UIHelper.SetVisible(self.TogRecommend, bShowRecommend)
    if not bShowRecommend then
        Event.Dispatch(EventType.OnCoinShopRecommendOpenClose, false)
    end

    if bShowRecommend then
        if TeachEvent.CheckCondition(52) then
            TeachEvent.TeachStart(52)
        end
    end

    self.m.tbGoodsList = self:GetGoodList(tbTitle)
    if tbTitle.bOutfit then
        self:InitOutfitPage()
    elseif tbTitle.nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
        self:InitExteriorPage()
    elseif tbTitle.nType == COIN_SHOP_GOODS_TYPE.ITEM then
        local nEquipSub = CoinShop_RewardsClassToSub(tbTitle.nRewardsClass)
        local nPendantType = GetPendantTypeByEquipSub(nEquipSub)
        if nPendantType then
            self:InitPendantPage()
        elseif tbTitle.nRewardsClass == REWARDS_CLASS.CLOTH_PENDANT_PET then
            self:InitPendantPetPage()
        elseif tbTitle.nRewardsClass == REWARDS_CLASS.EFFECT then
            self:InitEffectPage()
        end
    elseif tbTitle.nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        self:InitWeaponPage()
    elseif tbTitle.nType == COIN_SHOP_GOODS_TYPE.IDLE_ACTION then
        self:InitPosturePage()
    elseif tbTitle.nType ==  COIN_SHOP_GOODS_TYPE.FACE then
        self:InitFacePage()
    elseif tbTitle.nType ==  COIN_SHOP_GOODS_TYPE.HAIR then
        self:InitHairPage()
    elseif CoinShop_IsNewFaceType(tbTitle.nType, tbTitle.nRewardsClass) then
        self:InitNewFacePage()
    elseif CoinShop_IsBodyType(tbTitle.nType, tbTitle.nRewardsClass) then
        self:InitBodyPage()
    end

    -- local bShowTips = self.m.tbScriptList and not table_is_empty(self.m.tbScriptList)
    -- UIHelper.SetVisible(self.LayoutWardrobeTipsBotton, bShowTips)
    UIHelper.LayoutDoLayout(self.LayoutPet)
    UIHelper.LayoutDoLayout(self.LayoutWardrobeTipsBotton)

    self:CheckCustomPendantToggle()
    self:CheckCustomEffectToggle()
end

function UICoinShopWardrobeView:GetGoodList(tbTitle)
    local tbGoodsList = {}
    if tbTitle.bOutfit then
        tbGoodsList = CoinShopData.GetOutfitList()
    elseif tbTitle.nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
        tbGoodsList = CoinShopData.GetMyExterior(not tbTitle.bCollect, nil, tbTitle)
    elseif tbTitle.nType == COIN_SHOP_GOODS_TYPE.ITEM then
        local nEquipSub = CoinShop_RewardsClassToSub(tbTitle.nRewardsClass)
        local nPendantType = GetPendantTypeByEquipSub(nEquipSub)
        if nPendantType then
            local player = GetClientPlayer()
            if not player then
                return
            end
            local tList = player.GetAllPendent(nPendantType) or {}
            tbGoodsList.tList = Lib.ReverseTable(tList)
            tbGoodsList.nSize = player.GetPendentBoxSize(nPendantType)
            tbGoodsList.nMaxSize = player.GetPendentBoxMaxSize(nPendantType)
            tbGoodsList.szDisableTip = g_tStrings.tPendantDisableTip[nPendantType]
        elseif tbTitle.nRewardsClass == REWARDS_CLASS.CLOTH_PENDANT_PET then
            local player = GetClientPlayer()
            if not player then
                return
            end
            tbGoodsList.tList = player.GetAllPendentPetData()or {}
            tbGoodsList.nSize = player.GetPendentPetBoxSize()
            tbGoodsList.nMaxSize = player.GetPendentPetBoxSize()
            tbGoodsList.szDisableTip = ""
        elseif tbTitle.nRewardsClass == REWARDS_CLASS.EFFECT then
            local tbFilterDefSelected = FilterDef.CoinShopWardrobeEffect.tbRuntime
            local nType = EFFECT_FILTER_TYPE.FOOT
            if tbFilterDefSelected then
                nType = tbFilterDefSelected[1][1]
            end
            tbGoodsList = CharacterEffectData.GetPendantEffectListByType(nType)
        end
    elseif tbTitle.nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        tbGoodsList = CoinShopData.GetMyWeaponList()
    elseif tbTitle.nType == COIN_SHOP_GOODS_TYPE.IDLE_ACTION then
        local player = GetClientPlayer()
        if not player then
            return
        end
        local tList = player.GetAllIdleAction()
        tList = Lib.ReverseTable(tList)
        tbGoodsList = tList
    elseif tbTitle.nType ==  COIN_SHOP_GOODS_TYPE.HAIR then
        CoinShopHair.GetMyHairList(true)
        tbGoodsList = CoinShopHair.GetMyHairList()
    elseif tbTitle.nType ==  COIN_SHOP_GOODS_TYPE.FACE then
        CoinShopMyFaceData.Init()
        tbGoodsList = CoinShopMyFaceData.GetMyFaceList()
    elseif CoinShop_IsNewFaceType(tbTitle.nType, tbTitle.nRewardsClass) then
        CoinShopMyNewFaceData.Init()
        tbGoodsList = CoinShopMyNewFaceData.GetMyFaceList()
    elseif CoinShop_IsBodyType(tbTitle.nType, tbTitle.nRewardsClass) then
        CoinShopMyBodyData.Init()
        tbGoodsList = CoinShopMyBodyData.GetMyBodyList()
    end
    return tbGoodsList or {}
end

function UICoinShopWardrobeView:RefreshGoodsList(nPage)
    if self.m.tbTitle.bOutfit then
        self:RefreshOutfitList()
        return
    end
    local tbTitle = self.m.tbTitle
    self.m.tbGoodsList = self:GetGoodList(tbTitle)
    self:UpdateCurPageList(nPage)
end

function UICoinShopWardrobeView:UpdatePaginate(nPage, nTotalPage)
    UIHelper.SetString(self.EditPaginate, nPage)
    UIHelper.SetString(self.LabelPaginate, "/" .. nTotalPage)
    UIHelper.SetVisible(self.WidgetWardrobePaginate, nTotalPage >= 1)

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

function UICoinShopWardrobeView:InitOutfitPage()
    UIHelper.SetVisible(self.ScrollViewWardrobeCardList, true)
    self:UpdateOutfitServerNum()
    self:UpdateOutfitList(self.m.tbGoodsList, self.m.nPage or 1)
    local bShowTips = self.m.tbScriptList and not table_is_empty(self.m.tbScriptList)
    UIHelper.SetVisible(self.ImgCloud, bShowTips)
end

function UICoinShopWardrobeView:UpdateOutfitServerNum()
    local tList = g_pClientPlayer.GetAllCoinShopPresetData()
    local nMax = GetCoinShopPresetDataMaxCount()
    UIHelper.SetString(self.LabelCloudNum, #tList .. "/" .. nMax)
end

function UICoinShopWardrobeView:RefreshOutfitList()
    local tbList = CoinShopData.GetOutfitList()
    self.m.tbGoodsList = tbList
    self:UpdateCurPageList(self.m.nPage)
    local bShowTips = self.m.tbScriptList and not table_is_empty(self.m.tbScriptList)
    UIHelper.SetVisible(self.ImgCloud, bShowTips)
end

function UICoinShopWardrobeView:UpdateOutfitList(tbList, nPage)
    self.m.scriptCurOutfit = nil
    self:UpdateOutfitStorageState()

    local nCount = #tbList
    local nTotalPage = math.ceil(nCount / PAGE_EXTERIOR_COUNT)
    nPage = math.min(nPage, nTotalPage)
    nPage = math.max(nPage, 1)
    local nStart = (nPage - 1) * PAGE_EXTERIOR_COUNT + 1
    local nEnd = nPage * PAGE_EXTERIOR_COUNT
    nEnd = math.min(nEnd, nCount)
    local fnSelected = function (scriptOutfit, bSelected)
        self:OnSelectedOutfit(scriptOutfit, bSelected)
    end
    self.ScrollViewWardrobeCardList:removeAllChildren()
    self.m.tbScriptList = {}
    for i = nStart, nEnd do
        local tbOutfit = tbList[i]
        local suitItem = UIHelper.AddPrefab(PREFAB_ID.WidgetSuitItem, self.ScrollViewWardrobeCardList)
        suitItem:OnInitWithOutfit(tbOutfit, i, fnSelected)
        table.insert(self.m.tbScriptList, suitItem)
    end
    UIHelper.SetVisible(self.ScrollViewWardrobeCardList, nCount > 0)
    UIHelper.ScrollViewDoLayout(self.ScrollViewWardrobeCardList)
    UIHelper.ScrollToTop(self.ScrollViewWardrobeCardList, 0)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewWardrobeCardList, self.WidgetArrow)

    self.m.nPage = nPage
    self:UpdatePaginate(nPage, nTotalPage)

    UIHelper.SetVisible(self.WidgetEmpty, nCount <= 0)
end

function UICoinShopWardrobeView:OnSelectedOutfit(scriptOutfit, bSelected)
    if bSelected then
        self.m.scriptCurOutfit = scriptOutfit
    elseif scriptOutfit == self.m.scriptCurOutfit then
        self.m.scriptCurOutfit = nil
    else
        return
    end
    self:UpdateOutfitStorageState()
end

function UICoinShopWardrobeView:UpdateOutfitStorageState()
    if self.m.scriptCurOutfit ~= nil then
        UIHelper.SetVisible(self.WidgetPreinstall, true)
        local tbOutfit = self.m.scriptCurOutfit.tbOutfit
        UIHelper.SetVisible(self.BtnCloudCancel, tbOutfit.bServer)
        UIHelper.SetVisible(self.BtnRenameCloud, not tbOutfit.bServer)
        self.m.scriptCurOutfit:UpdateOutfitStorageState()
    else
        UIHelper.SetVisible(self.WidgetPreinstall, false)
    end
    UIHelper.LayoutDoLayout(self.LayoutPet)
end

function UICoinShopWardrobeView:StorageOutfitToServer()
    local tbOutfit = self.m.scriptCurOutfit.tbOutfit
    local tPreset, bUseLiftedFace = CoinShopData.DataToServer(tbOutfit.tData)
    local nRetCode = g_pClientPlayer.AddCoinShopPreset(UIHelper.UTF8ToGBK(tbOutfit.szName), bUseLiftedFace, tbOutfit.bHideHat, self.m.scriptCurOutfit.nIndex, tPreset)

    if nRetCode == COIN_SHOP_PRESET_ERROR_CODE.SUCCESS then
        tbOutfit.bServer = true
        self:UpdateOutfitStorageState()
        local _, nIndex = CoinShop_OutfitCheckRepeat(tbOutfit)
        CoinShop_DeleteOutfitList(nIndex, false)
        return
    end
    if nRetCode then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tCoinShopPresetNotify[nRetCode])
        OutputMessage("MSG_SYS", g_tStrings.tCoinShopPresetNotify[nRetCode])
    end
end

function UICoinShopWardrobeView:StorageOutfitToLocal()
    local tbOutfit = self.m.scriptCurOutfit.tbOutfit
    local bRepeat, nIndex = CoinShop_OutfitCheckRepeat(tbOutfit)
    if bRepeat then
        local tbRepeatOutfit = CoinShop_GetOutfitByIndex(nIndex)
        local szMsg = FormatString(g_tStrings.COIN_SHOP_PRESET_TO_LOCAL_FAILED, tbRepeatOutfit.szName)
        UIHelper.ShowConfirm(szMsg)
        return
    end
    local nRetCode = g_pClientPlayer.DeleteCoinShopPreset(tbOutfit.dwIndex, self.m.scriptCurOutfit.nIndex)
    if nRetCode then
        tbOutfit.bServer = false
        tbOutfit.dwIndex = nil
        self:UpdateOutfitStorageState()
        CoinShop_SaveOutfitList(tbOutfit, false)
    end
end

function UICoinShopWardrobeView:DeleteOutfit()
    local tbOutfit = self.m.scriptCurOutfit.tbOutfit
    local fnConfirm = function ()
        if tbOutfit.bServer then
            g_pClientPlayer.DeleteCoinShopPreset(tbOutfit.dwIndex, -1)
        else
            local _, nIndex = CoinShop_OutfitCheckRepeat(tbOutfit)
            CoinShop_DeleteOutfitList(nIndex, true)
        end
    end
    local szMsg = g_tStrings.COINSHOP_OUTFIT_SURE_DELETE
    UIHelper.ShowConfirm(szMsg, fnConfirm)
end

function UICoinShopWardrobeView:OnEnterReplaceOutfit()
    if not self.m.tbTitle.bOutfit then
        return
    end
    UIHelper.SetVisible(self.ScrollViewWardrobeCardList, false)
    UIHelper.SetVisible(self.WidgetPreinstall, false)
    UIHelper.SetVisible(self.WidgetWardrobePaginate, false)
    UIHelper.SetVisible(self.WidgetReplaceList, true)
    UIHelper.RemoveAllChildren(self.ScrollViewReplaceList)
    UIHelper.ToggleGroupRemoveAllToggle(self.WidgetReplaceList)
    for i, tbOutfit in ipairs(self.m.tbGoodsList) do
        local suitItem = UIHelper.AddPrefab(PREFAB_ID.WidgetSuitItem, self.ScrollViewReplaceList)
        suitItem:OnInitWithReplaceOutfit(tbOutfit)
        UIHelper.ToggleGroupAddToggle(self.WidgetReplaceList, suitItem.TogPetList)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewReplaceList)
    UIHelper.ScrollToTop(self.ScrollViewReplaceList, 0)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewReplaceList, self.WidgetArrow)
    UIHelper.LayoutDoLayout(self.LayoutPet)
end

function UICoinShopWardrobeView:OnCancelReplaceOutfit()
    self:UpdateGoodList(self.m.tbTitle)
end

function UICoinShopWardrobeView:InitExteriorPage()
    UIHelper.SetVisible(self.ScrollViewWardrobeCardList, true)

    self.m.tbFilter.nGenre = self.m.tbFilter.nGenre or CoinShopExterior.FILTER_ALL
    self.m.tbFilter.nType = self.m.tbFilter.nType or CoinShopExterior.FILTER_ALL
    self.m.tbFilter.nHide = self.m.tbFilter.nHide or CoinShopExterior.FILTER_SHOW
    self:InitExteriorFilter()
    UIHelper.SetVisible(self.TogFilter, true)

    if self.m.tbFilter.nType == CoinShopExterior.FILTER_ALL or self.m.tbFilter.nHide == CoinShopExterior.FILTER_HIDE then
        self:UpdateExteriorSetList(self.m.tbGoodsList.tSetList, self.m.nPage or 1)
    else
        self:UpdateExteriorSubList(self.m.tbGoodsList.tSubList, self.m.nPage or 1)
    end
end

function UICoinShopWardrobeView:InitExteriorFilter()
    local nFilterIndex = 1
    local temp = {}

    local conf = {
        szType = FilterType.RadioButton,
        szSubType = FilterSubType.Small,
        szTitle = "外观分类",
        tbList = {},
        tbDefault = {1},
        bHide = true,
        bDispatchChangedEvent = true,
    }
    for i, nHide in ipairs(CoinShopExterior.tFilterHide) do
        local szOption = g_tStrings.tExteriorShowName[nHide]
        table.insert(conf.tbList, szOption)
        if self.m.tbFilter.nHide == nHide then
            temp[nFilterIndex] = {i}
        end
    end
    FilterDef.CoinShopWardrobeExterior[nFilterIndex] = conf
    nFilterIndex = nFilterIndex + 1

    local tGenreList = CoinShopData.GetMyGenreList(self.m.tbTitle.nRewardsClass)
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
        FilterDef.CoinShopWardrobeExterior[nFilterIndex] = conf
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
    FilterDef.CoinShopWardrobeExterior[nFilterIndex] = conf
    nFilterIndex = nFilterIndex + 1

    FilterDef.CoinShopWardrobeExterior.SetRunTime(temp)
    FilterDef.CoinShopWardrobeExterior[nFilterIndex] = nil

    self:UpdateExteriorFilterMutex(temp)
end

function UICoinShopWardrobeView:UpdateExteriorFilterMutex(tbRunTime)
    for _, conf in ipairs(FilterDef.CoinShopWardrobeExterior) do
        if conf.bType then
            conf.tbDisableList = {}
            for i, nType in ipairs(CoinShopExterior.tFilterType) do
                local disable = tbRunTime[1][1] == CoinShopExterior.FILTER_HIDE and nType ~= CoinShopExterior.FILTER_ALL
                conf.tbDisableList[i] = disable
            end
        end
    end
end

function UICoinShopWardrobeView:UpdateExteriorSetList(tbList, nPage)
    local tbShowList = CoinShopExterior.FilterSetList(tbList, self.m.tbFilter.nGenre, CoinShopExterior.FILTER_ALL, self.m.tbFilter.nHide, false)
    self:UpdateFilterTexture(CoinShopExterior.IsOnSetFilter(self.m.tbFilter.nGenre, CoinShopExterior.FILTER_ALL, self.m.tbFilter.nHide))

    local nCount = #tbShowList
    local nTotalPage = math.ceil(nCount / PAGE_EXTERIOR_COUNT)
    nPage = math.min(nPage, nTotalPage)
    nPage = math.max(nPage, 1)
    local nStart = (nPage - 1) * PAGE_EXTERIOR_COUNT + 1
    local nEnd = nPage * PAGE_EXTERIOR_COUNT
    nEnd = math.min(nEnd, nCount)

    self.ScrollViewWardrobeCardList:removeAllChildren()
    self.m.tbScriptList = {}
    for i = nStart, nEnd do
        local tbSet = tbShowList[i]
        local suitItem = UIHelper.AddPrefab(PREFAB_ID.WidgetPropItemCell, self.ScrollViewWardrobeCardList)
        suitItem:OnInitWithSet(tbSet, false, nil)
        table.insert(self.m.tbScriptList, suitItem)
    end
    UIHelper.SetVisible(self.ScrollViewWardrobeCardList, nCount > 0)
    UIHelper.ScrollViewDoLayout(self.ScrollViewWardrobeCardList)
    UIHelper.ScrollToTop(self.ScrollViewWardrobeCardList, 0)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewWardrobeCardList, self.WidgetArrow)

    self.m.nPage = nPage
    self:UpdatePaginate(nPage, nTotalPage)

    UIHelper.SetVisible(self.WidgetEmpty, nCount <= 0)

    -- local nSetHave = CoinShopExterior.GetSetHaveInfo(self.m.tbTitle.bCollect)
    -- local nSubHave = CoinShopExterior.GetSubHaveInfo(self.m.tbTitle.bCollect)
    -- local szText = FormatString(g_tStrings.COINSHOP_SET_TIP, nSetHave, nSubHave)
    -- local tResult = string.split(szText, "\n")
    -- self.particularsTips:OnInitSmallTips(tResult[1], tResult[2])
    -- UIHelper.SetVisible(self.TogParticulars, true)
end

function UICoinShopWardrobeView:UpdateExteriorSubList(tbList, nPage)
    local tbShowList = CoinShopExterior.FilterSubList(tbList, self.m.tbFilter.nGenre, self.m.tbFilter.nType, CoinShopExterior.FILTER_ALL)
    self:UpdateFilterTexture(CoinShopExterior.IsOnSubFilter(self.m.tbFilter.nGenre, self.m.tbFilter.nType, CoinShopExterior.FILTER_ALL))

    local nCount = #tbShowList
    local nTotalPage = math.ceil(nCount / PAGE_EXTERIOR_COUNT)
    nPage = math.min(nPage, nTotalPage)
    nPage = math.max(nPage, 1)
    local nStart = (nPage - 1) * PAGE_EXTERIOR_COUNT + 1
    local nEnd = nPage * PAGE_EXTERIOR_COUNT
    nEnd = math.min(nEnd, nCount)

    self.ScrollViewWardrobeCardList:removeAllChildren()
    self.m.tbScriptList = {}
    for i = nStart, nEnd do
        local tbSub = tbShowList[i]
        local suitItem = UIHelper.AddPrefab(PREFAB_ID.WidgetPropItemCell, self.ScrollViewWardrobeCardList)
        suitItem:OnInitWithSub(tbSub, false)
        table.insert(self.m.tbScriptList, suitItem)
    end
    UIHelper.SetVisible(self.ScrollViewWardrobeCardList, nCount > 0)
    UIHelper.ScrollViewDoLayout(self.ScrollViewWardrobeCardList)
    UIHelper.ScrollToTop(self.ScrollViewWardrobeCardList, 0)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewWardrobeCardList, self.WidgetArrow)

    self.m.nPage = nPage
    self:UpdatePaginate(nPage, nTotalPage)

    UIHelper.SetVisible(self.WidgetEmpty, nCount <= 0)

    -- local nSetHave = CoinShopExterior.GetSetHaveInfo(self.m.tbTitle.bCollect)
    -- local nSubHave = CoinShopExterior.GetSubHaveInfo(self.m.tbTitle.bCollect)
    -- local szText = FormatString(g_tStrings.COINSHOP_SET_TIP, nSetHave, nSubHave)
    -- local tResult = string.split(szText, "\n")
    -- self.particularsTips:OnInitSmallTips(tResult[1], tResult[2])
    -- UIHelper.SetVisible(self.TogParticulars, true)
end

function UICoinShopWardrobeView:LinkExteriorSet(nSet)
    self.m.tbFilter.nGenre = CoinShopExterior.FILTER_ALL
    self.m.tbFilter.nType = CoinShopExterior.FILTER_ALL
    self.m.tbFilter.nHide = CoinShopExterior.FILTER_SHOW
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
                    CoinShopPreview.LocatePreviewItem(self.ScrollViewWardrobeCardList, script._rootNode)
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

function UICoinShopWardrobeView:InitWeaponPage()
    UIHelper.SetVisible(self.ScrollViewWardrobeCardList, true)

    self.m.tbFilter.nStatus = self.m.tbFilter.nStatus or CoinShopWeapon.FILTER_ALL
    self.m.tbFilter.nType = self.m.tbFilter.nType or CoinShopWeapon.FILTER_ALL
    self:InitWeaponFilter()

    self:UpdateWeaponList(self.m.tbGoodsList, self.m.nPage or 1)
end

function UICoinShopWardrobeView:InitWeaponFilter()
    local nFilterIndex = 1
    local temp = {}

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
        FilterDef.CoinShopWardrobeWeapon[nFilterIndex] = conf
        nFilterIndex = nFilterIndex + 1
    end

    FilterDef.CoinShopWardrobeWeapon.SetRunTime(temp)
    FilterDef.CoinShopWardrobeWeapon[nFilterIndex] = nil

    if nFilterIndex == 1 then
        UIHelper.SetVisible(self.TogFilter, false)
    else
        UIHelper.SetVisible(self.TogFilter, true)
    end
end

function UICoinShopWardrobeView:UpdateWeaponList(tbList, nPage)
    local tbShowList = CoinShopWeapon.FilterList(tbList, false, self.m.tbFilter.nStatus, self.m.tbFilter.nType)
    self:UpdateFilterTexture(CoinShopWeapon.IsOnFilter(self.m.tbFilter.nStatus, self.m.tbFilter.nType))

    local nCount = #tbShowList
    local nTotalPage = math.ceil(nCount / PAGE_PROP_COUNT)
    nPage = math.min(nPage, nTotalPage)
    nPage = math.max(nPage, 1)
    local nStart = (nPage - 1) * PAGE_PROP_COUNT + 1
    local nEnd = nPage * PAGE_PROP_COUNT
    nEnd = math.min(nEnd, nCount)

    self.ScrollViewWardrobeCardList:removeAllChildren()
    self.m.tbScriptList = {}
    for i = nStart, nEnd do
        local dwWeaponID = tbShowList[i]
        local propItem = UIHelper.AddPrefab(PREFAB_ID.WidgetPropItemCell, self.ScrollViewWardrobeCardList)
        propItem:OnInitWithWeapon(dwWeaponID, false)
        table.insert(self.m.tbScriptList, propItem)
    end
    UIHelper.SetVisible(self.ScrollViewWardrobeCardList, nCount > 0)
    UIHelper.ScrollViewDoLayout(self.ScrollViewWardrobeCardList)
    UIHelper.ScrollToTop(self.ScrollViewWardrobeCardList, 0)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewWardrobeCardList, self.WidgetArrow)

    self.m.nPage = nPage
    self:UpdatePaginate(nPage, nTotalPage)

    UIHelper.SetVisible(self.WidgetEmpty, nCount <= 0)

    -- local szTips = FormatString(g_tStrings.COINSHOP_BOX_MOD_TIP, #self.m.tbGoodsList)
    -- self.particularsTips:OnInitSmallTips(szTips, "")
    -- UIHelper.SetVisible(self.TogParticulars, true)
end

function UICoinShopWardrobeView:InitPosturePage()
    UIHelper.SetVisible(self.ScrollViewStandbyList, true)
    self:UpdatePostureList(self.m.tbGoodsList, self.m.nPage or 1)
end

function UICoinShopWardrobeView:UpdatePostureList(tbList, nPage)
    local nCount = #tbList
    local nTotalPage = math.ceil(nCount / PAGE_POSTURE_COUNT)
    nPage = math.min(nPage, nTotalPage)
    nPage = math.max(nPage, 1)
    local nStart = (nPage - 1) * PAGE_POSTURE_COUNT + 1
    local nEnd = nPage * PAGE_POSTURE_COUNT
    nEnd = math.min(nEnd, nCount)

    UIHelper.RemoveAllChildren(self.ScrollViewStandbyList)
    self.m.tbScriptList = {}
    for i = nStart, nEnd do
        local posItem = UIHelper.AddPrefab(PREFAB_ID.WidgetShoppingStandby, self.ScrollViewStandbyList)
        posItem:OnEnter(tbList[i])
        table.insert(self.m.tbScriptList, posItem)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewStandbyList)

    self.m.nPage = nPage
    self:UpdatePaginate(nPage, nTotalPage)
    UIHelper.SetVisible(self.WidgetEmpty, nCount <= 0)
end

function UICoinShopWardrobeView:InitPendantPage()
    UIHelper.SetVisible(self.ScrollViewPropList, true)
    self:UpdatePendantList(self.m.tbGoodsList, self.m.nPage or 1)
end

function UICoinShopWardrobeView:UpdatePendantList(tbList, nPage)
    local nCount = tbList.nMaxSize
    local nTotalPage = math.ceil(nCount / PAGE_BOX_COUNT)
    nPage = math.min(nPage, nTotalPage)
    nPage = math.max(nPage, 1)
    local nStart = (nPage - 1) * PAGE_BOX_COUNT + 1
    local nEnd = nPage * PAGE_BOX_COUNT
    nEnd = math.min(nEnd, nCount)

    self.ScrollViewPropList:removeAllChildren()
    self.m.tbScriptList = {}
    for i = nStart, nEnd do
        local boxItem = UIHelper.AddPrefab(PREFAB_ID.WidgetWardrobePetBottom, self.ScrollViewPropList)
        if i <= #tbList.tList then
            boxItem:OnInitWithPendant(tbList.tList[i])
        elseif i <= tbList.nSize then
            boxItem:OnInitWithEmpty()
        elseif i <= tbList.nMaxSize then
            boxItem:OnInitWithLock(tbList.szDisableTip)
        end
        table.insert(self.m.tbScriptList, boxItem)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewPropList)
    UIHelper.ScrollToTop(self.ScrollViewPropList, 0)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewPropList, self.WidgetArrow)

    self.m.nPage = nPage
    self:UpdatePaginate(nPage, nTotalPage)

    UIHelper.SetVisible(self.WidgetEmpty, nCount <= 0)

    -- local szTips = FormatString(g_tStrings.COINSHOP_BOX_MOD_TIP, #self.m.tbGoodsList.tList)
    -- self.particularsTips:OnInitSmallTips(szTips, "")
    -- UIHelper.SetVisible(self.TogParticulars, true)
end

function UICoinShopWardrobeView:LinkPendant(tbInfo, bOpenCustom)
    local bFound = false
    for i, tbPendant in ipairs(self.m.tbGoodsList.tList) do
        local tColorID = {tbPendant.nColorID1, tbPendant.nColorID2, tbPendant.nColorID3}
        if tbPendant.dwItemIndex == tbInfo.dwIndex and ExteriorCharacter.IsColorSame(tColorID, tbInfo.tColorID) then
            local nPage = math.floor((i + PAGE_BOX_COUNT - 1) / PAGE_BOX_COUNT)
            self:UpdatePendantList(self.m.tbGoodsList, nPage)
            FireUIEvent("PREVIEW_PENDANT", tbInfo, false, false)
            bFound = true
            break
        end
    end
    if bOpenCustom and bFound then
        if UIHelper.GetVisible(self.TogDIY) then
            UIHelper.SetSelected(self.TogDIY, true)
        end
    end
    if not bFound then
        self:UpdateCurPageList(1)
    end
end

function UICoinShopWardrobeView:InitPendantPetPage()
    UIHelper.SetVisible(self.ScrollViewPropList, true)
    self:UpdatePendantPetList(self.m.tbGoodsList, self.m.nPage or 1)
end

function UICoinShopWardrobeView:UpdatePendantPetList(tbList, nPage)
    local nCount = tbList.nMaxSize
    local nTotalPage = math.ceil(nCount / PAGE_BOX_COUNT)
    nPage = math.min(nPage, nTotalPage)
    nPage = math.max(nPage, 1)
    local nStart = (nPage - 1) * PAGE_BOX_COUNT + 1
    local nEnd = nPage * PAGE_BOX_COUNT
    nEnd = math.min(nEnd, nCount)

    self.ScrollViewPropList:removeAllChildren()
    self.m.tbScriptList = {}
    for i = nStart, nEnd do
        local boxItem = UIHelper.AddPrefab(PREFAB_ID.WidgetWardrobePetBottom, self.ScrollViewPropList)
        if i <= #tbList.tList then
            boxItem:OnInitWithPendantPet(tbList.tList[i])
        elseif i <= tbList.nSize then
            boxItem:OnInitWithEmpty()
        elseif i <= tbList.nMaxSize then
            boxItem:OnInitWithLock(tbList.szDisableTip)
        end
        table.insert(self.m.tbScriptList, boxItem)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewPropList)
    UIHelper.ScrollToTop(self.ScrollViewPropList, 0)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewPropList, self.WidgetArrow)

    self.m.nPage = nPage
    self:UpdatePaginate(nPage, nTotalPage)

    UIHelper.SetVisible(self.WidgetEmpty, nCount <= 0)

    -- local szTips = FormatString(g_tStrings.COINSHOP_BOX_MOD_TIP, #self.m.tbGoodsList.tList)
    -- self.particularsTips:OnInitSmallTips(szTips, "")
    -- UIHelper.SetVisible(self.TogParticulars, true)
end

function UICoinShopWardrobeView:InitBodyPage()
    CoinShopMyBodyData.Init()
    UIHelper.SetVisible(self.WidgetFacePage, true)
    UIHelper.SetVisible(self.BtnFaceDes, true)

    UIHelper.BindUIEvent(self.BtnFaceDes, EventType.OnClick, function(btn)
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetRichTextTips, self.BtnFaceDes, TipsLayoutDir.BOTTOM_CENTER, "已有体型数/体型数上限")
    end)

    self:UpdateBodyList(self.m.tbGoodsList, self.m.nPage or 1)
    Event.Dispatch(EventType.OnShowFaceCodeBtn, false, UI_COINSHOP_GENERAL.MY_ROLE)
    Event.Dispatch(EventType.OnShowBodyCodeBtn, true, UI_COINSHOP_GENERAL.MY_ROLE)
end

function UICoinShopWardrobeView:UpdateBodyList(tbList, nPage)
    local nCount = #tbList
    local nTotalPage = math.ceil(nCount / PAGE_NEW_FACE_COUNT)
    nPage = math.min(nPage, nTotalPage)
    nPage = math.max(nPage, 1)
    local nStart = (nPage - 1) * PAGE_NEW_FACE_COUNT + 1
    local nEnd = nPage * PAGE_NEW_FACE_COUNT
    nEnd = math.min(nEnd, nCount)

    self.ScrollViewFacePage:removeAllChildren()
    self.m.tbScriptList = {}

    local _, nEquippedIndex = ExteriorCharacter.GetPreviewBody()

    for i = nStart, nEnd do
        local tbInfo = tbList[i]
        tbInfo.szName = CoinShopMyBodyData.GetBodyName(tbInfo.nIndex)
        tbInfo.bCanEditName = tbInfo.nIndex and tbInfo.nIndex > 1
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetMyFaceCell, self.ScrollViewFacePage)
        scriptCell:OnEnter(tbInfo)
        scriptCell:SetClickCallback(function ()
            local tBody = tbInfo
            local nIndex = tbInfo.nIndex
            if RedpointHelper.Body_IsNew(nIndex) then
                RedpointHelper.Body_SetNew(nIndex, false)
            end
            FireUIEvent("PREVIEW_BODY", nIndex, tBody, true)
            Event.Dispatch(EventType.OnCoinShopWardrobeUpdateBodyList)
        end)

        scriptCell:SetClickEditNameCallback(function ()
            local editBox = UIMgr.Open(VIEW_ID.PanelPromptPop, tbInfo.szName, g_tStrings.STR_BODY_RENAME, function (szText)
                CoinShopMyBodyData.SetRename(tbInfo.nIndex, szText)
                Event.Dispatch(EventType.OnCoinShopWardrobeUpdateBodyList)
            end)

            editBox:SetTitle("修改备注")
            editBox:SetMaxLength(8)
        end)

        scriptCell:SetSelected(nEquippedIndex == tbInfo.nIndex)
        scriptCell:SetRedPointVisible(RedpointHelper.Body_IsNew(tbInfo.nIndex))
        table.insert(self.m.tbScriptList, scriptCell)
    end
    UIHelper.SetVisible(self.ScrollViewFacePage, nCount > 0)
    UIHelper.ScrollViewDoLayout(self.ScrollViewFacePage)
    UIHelper.ScrollToTop(self.ScrollViewFacePage, 0)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewFacePage, self.WidgetArrow)

    UIHelper.SetString(self.LabelFaceCount, string.format("%d/%d", CoinShopMyBodyData.nMyBodyCount, CoinShopMyBodyData.nMyBodyBoxCount))

    self.m.nPage = nPage
    self:UpdatePaginate(nPage, nTotalPage)

    UIHelper.SetVisible(self.WidgetEmpty, nCount <= 0)
end

function UICoinShopWardrobeView:InitNewFacePage()
    CoinShopMyNewFaceData.Init()
    UIHelper.SetVisible(self.WidgetFacePage, true)
    self:UpdateNewFaceList(self.m.tbGoodsList, self.m.nPage or 1)
    Event.Dispatch(EventType.OnShowFaceCodeBtn, true, UI_COINSHOP_GENERAL.MY_ROLE)
    Event.Dispatch(EventType.OnShowBodyCodeBtn, false, UI_COINSHOP_GENERAL.MY_ROLE)
end

function UICoinShopWardrobeView:UpdateNewFaceList(tbList, nPage)
    local nCount = #tbList
    local nTotalPage = math.ceil(nCount / PAGE_NEW_FACE_COUNT)
    nPage = math.min(nPage, nTotalPage)
    nPage = math.max(nPage, 1)
    local nStart = (nPage - 1) * PAGE_NEW_FACE_COUNT + 1
    local nEnd = nPage * PAGE_NEW_FACE_COUNT
    nEnd = math.min(nEnd, nCount)

    self.ScrollViewFacePage:removeAllChildren()
    self.m.tbScriptList = {}

    local _, nEquippedIndex = ExteriorCharacter.GetPreviewNewFace()

    for i = nStart, nEnd do
        local tbInfo = tbList[i]
        tbInfo.szName = CoinShopMyNewFaceData.GetFaceNameByIndex(tbInfo.nIndex, tbInfo.nUIIndex)
        tbInfo.bCanEditName = true
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetMyFaceCell, self.ScrollViewFacePage)
        scriptCell:OnEnter(tbInfo)
        scriptCell:SetClickCallback(function ()
            local tFace = tbInfo.tFaceData
            local nIndex = tbInfo.nIndex
            ExteriorCharacter.ChangeFaceType(true)
            if RedpointHelper.Face_IsNew(nIndex) then
                RedpointHelper.Face_SetNew(nIndex, false)
            end
            FireUIEvent("PREVIEW_NEW_FACE", nIndex, tFace, true)
            BuildFaceData.NowFaceCloneData(tFace, true)
            Event.Dispatch(EventType.OnCoinShopWardrobeUpdateNewFaceList)
        end)

        scriptCell:SetClickEditNameCallback(function ()
            local editBox = UIMgr.Open(VIEW_ID.PanelPromptPop, tbInfo.szName, g_tStrings.STR_FACE_RENAME, function (szText)
                CoinShopMyNewFaceData.SetRename(tbInfo.nUIIndex, szText)
                Event.Dispatch(EventType.OnCoinShopWardrobeUpdateNewFaceList)
            end)

            editBox:SetTitle("修改备注")
            editBox:SetMaxLength(8)
        end)

        scriptCell:SetSelected(nEquippedIndex == tbInfo.nIndex)
        scriptCell:SetRedPointVisible(RedpointHelper.Face_IsNew(tbInfo.nIndex))
        table.insert(self.m.tbScriptList, scriptCell)
    end
    UIHelper.SetVisible(self.ScrollViewFacePage, nCount > 0)
    UIHelper.ScrollViewDoLayout(self.ScrollViewFacePage)
    UIHelper.ScrollToTop(self.ScrollViewFacePage, 0)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewFacePage, self.WidgetArrow)

    UIHelper.SetString(self.LabelFaceCount, string.format("%d", nCount))

    self.m.nPage = nPage
    self:UpdatePaginate(nPage, nTotalPage)

    UIHelper.SetVisible(self.WidgetEmpty, nCount <= 0)
end

function UICoinShopWardrobeView:InitFacePage()
    CoinShopMyFaceData.Init()
    UIHelper.SetVisible(self.WidgetFacePage, true)
    self:UpdateFaceList(self.m.tbGoodsList, self.m.nPage or 1)
    Event.Dispatch(EventType.OnShowFaceCodeBtn, true, UI_COINSHOP_GENERAL.MY_ROLE)
    Event.Dispatch(EventType.OnShowBodyCodeBtn, false, UI_COINSHOP_GENERAL.MY_ROLE)
end

function UICoinShopWardrobeView:UpdateFaceList(tbList, nPage)
    local nCount = #tbList
    local nTotalPage = math.ceil(nCount / PAGE_NEW_FACE_COUNT)
    nPage = math.min(nPage, nTotalPage)
    nPage = math.max(nPage, 1)
    local nStart = (nPage - 1) * PAGE_NEW_FACE_COUNT + 1
    local nEnd = nPage * PAGE_NEW_FACE_COUNT
    nEnd = math.min(nEnd, nCount)

    self.ScrollViewFacePage:removeAllChildren()
    self.m.tbScriptList = {}

    local _, nEquippedIndex = ExteriorCharacter.GetPreviewFace()

    for i = nStart, nEnd do
        local tbInfo = tbList[i]
        if type(tbInfo) == "table" then
            tbInfo.szName = CoinShopMyFaceData.GetUseLifeFaceNameByIndex(tbInfo.nIndex, tbInfo.nUIIndex)
            tbInfo.bCanEditName = true
            local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetMyFaceCell, self.ScrollViewFacePage)
            scriptCell:OnEnter(tbInfo)
            scriptCell:SetClickCallback(function ()
                local nIndex = tbInfo.nIndex
                local tFaceData = tbInfo.tFaceData
                ExteriorCharacter.ChangeFaceType(false)

                local tRepresentID = ExteriorCharacter.m_tRepresentID
                local nFaceID = tRepresentID[EQUIPMENT_REPRESENT.FACE_STYLE]
                local UserData = nil
                if tFaceData then
                    UserData = {}
                    UserData.tFaceData = tFaceData
                    UserData.nIndex = nIndex
                    nFaceID = nil
                end
                if RedpointHelper.Face_IsNew(nIndex) then
                    RedpointHelper.Face_SetNew(nIndex, false)
                end
                FireUIEvent("PREVIEW_FACE", nFaceID, true, UserData, true, true)
                BuildFaceData.NowFaceCloneData(tFaceData, false)
                Event.Dispatch(EventType.OnCoinShopWardrobeUpdateFaceList)
            end)

            scriptCell:SetClickEditNameCallback(function ()
                local editBox = UIMgr.Open(VIEW_ID.PanelPromptPop, tbInfo.szName, g_tStrings.STR_FACE_RENAME, function (szText)
                    CoinShopMyFaceData.SetUseLifeRename(tbInfo.nUIIndex, szText)
                    Event.Dispatch(EventType.OnCoinShopWardrobeUpdateFaceList)
                end)

                editBox:SetTitle("修改备注")
                editBox:SetMaxLength(8)
            end)

            scriptCell:SetSelected(nEquippedIndex == tbInfo.nIndex)
            scriptCell:SetRedPointVisible(RedpointHelper.Face_IsNew(tbInfo.nIndex))
            table.insert(self.m.tbScriptList, scriptCell)
        else
            local nFaceID = tbInfo
            local tbInfo = {nIndex = nFaceID}
            tbInfo.szName = CoinShopMyFaceData.GetFaceNameByIndex(nFaceID)
            tbInfo.bCanEditName = true
            local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetMyFaceCell, self.ScrollViewFacePage)
            scriptCell:OnEnter(tbInfo)
            scriptCell:SetClickCallback(function ()
                ExteriorCharacter.ChangeFaceType(false)

                local tRepresentID = ExteriorCharacter.m_tRepresentID
                tRepresentID[EQUIPMENT_REPRESENT.FACE_STYLE] = nFaceID

                FireUIEvent("PREVIEW_FACE", nFaceID, false, nil, true, true)
                Event.Dispatch(EventType.OnCoinShopWardrobeUpdateFaceList)
            end)

            scriptCell:SetClickEditNameCallback(function ()
                local editBox = UIMgr.Open(VIEW_ID.PanelPromptPop, tbInfo.szName, g_tStrings.STR_FACE_RENAME, function (szText)
                    CoinShopMyFaceData.SetRename(nFaceID, szText)
                    Event.Dispatch(EventType.OnCoinShopWardrobeUpdateFaceList)
                end)

                editBox:SetTitle("修改备注")
                editBox:SetMaxLength(8)
            end)

            local tRepresentID = ExteriorCharacter.m_tRepresentID
            local nEquippedFaceID = tRepresentID[EQUIPMENT_REPRESENT.FACE_STYLE]
            local bUseLiftedFace = tRepresentID.bUseLiftedFace
            scriptCell:SetSelected(not bUseLiftedFace and nEquippedFaceID == nFaceID)
            table.insert(self.m.tbScriptList, scriptCell)
        end
    end
    UIHelper.SetVisible(self.ScrollViewFacePage, nCount > 0)
    UIHelper.ScrollViewDoLayout(self.ScrollViewFacePage)
    UIHelper.ScrollToTop(self.ScrollViewFacePage, 0)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewFacePage, self.WidgetArrow)

    UIHelper.SetString(self.LabelFaceCount, string.format("%d", nCount))

    self.m.nPage = nPage
    self:UpdatePaginate(nPage, nTotalPage)

    UIHelper.SetVisible(self.WidgetEmpty, nCount <= 0)
end

function UICoinShopWardrobeView:InitHairPage()
    CoinShopHair.GetMyHairList(true)
    UIHelper.SetVisible(self.TogHairFilter, true)
    UIHelper.SetVisible(self.TogHairDyeing, false)
    UIHelper.SetVisible(self.WidgetFacePage, true)
    self:UpdateHairList(self.m.tbGoodsList, self.m.nPage or 1)
    Event.Dispatch(EventType.OnShowFaceCodeBtn, false, UI_COINSHOP_GENERAL.MY_ROLE)
    Event.Dispatch(EventType.OnShowBodyCodeBtn, false, UI_COINSHOP_GENERAL.MY_ROLE)
end

function UICoinShopWardrobeView:UpdateHairList(tbList, nPage)
    local nCount = #tbList
    local nTotalPage = math.ceil(nCount / PAGE_NEW_FACE_COUNT)
    nPage = math.min(nPage, nTotalPage)
    nPage = math.max(nPage, 1)
    local nStart = (nPage - 1) * PAGE_NEW_FACE_COUNT + 1
    local nEnd = nPage * PAGE_NEW_FACE_COUNT
    nEnd = math.min(nEnd, nCount)

    self.ScrollViewFacePage:removeAllChildren()
    self.m.tbScriptList = {}

    local tHair = ExteriorCharacter.GetPreviewHair() or {}
    local nEquippedIndex = tHair.nHairID
    local tInfo = GetHairShop().GetHairPrice(BuildFaceData.nRoleType, HAIR_STYLE.HAIR, tHair.nHairID)
    local bCanDyeing = tInfo.bCanDyeing
    UIHelper.SetVisible(self.TogHairDyeing, bCanDyeing)

    for i = nStart, nEnd do
        local dwID = tbList[i]
        local tbInfo = {}
        tbInfo.dwID = dwID

        local szDefaultName = CoinShopHair.GetHairText(dwID)
        tbInfo.szName = CoinShopHair.GetHairName(dwID) or UIHelper.GBKToUTF8(szDefaultName)
        tbInfo.bCanEditName = true
        tbInfo.bWardrobeHair = true
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetMyFaceCell, self.ScrollViewFacePage)
        scriptCell:OnEnter(tbInfo)
        scriptCell:SetClickCallback(function ()
            if RedpointHelper.Hair_IsNew(dwID) then
                RedpointHelper.Hair_SetNew(dwID, false)
            end
            FireUIEvent("PREVIEW_HAIR", dwID, nil, true, true, false)
            Event.Dispatch(EventType.OnCoinShopWardrobeUpdateHairList)
        end)

        scriptCell:SetClickEditNameCallback(function ()
            local editBox = UIMgr.Open(VIEW_ID.PanelPromptPop, tbInfo.szName, g_tStrings.STR_FACE_RENAME, function (szText)
                CoinShopHair.SetRename(dwID, szText)
                Event.Dispatch(EventType.OnCoinShopWardrobeUpdateHairList)
            end)

            editBox:SetTitle("修改备注")
            editBox:SetMaxLength(8)
        end)

        scriptCell:SetClickCheckCaseCallback(function ()
            if self.scriptHairDyeCase then
                Event.Dispatch(EventType.OnCoinShopRecommendOpenClose, false)
                self.scriptHairDyeCase:Open(dwID)
            end
        end)

        scriptCell:UpdateDownloadEquipRes(dwID)

        scriptCell:SetSelected(nEquippedIndex == dwID)
        scriptCell:SetRedPointVisible(RedpointHelper.Hair_IsNew(dwID))
        table.insert(self.m.tbScriptList, scriptCell)
    end
    UIHelper.SetVisible(self.ScrollViewFacePage, nCount > 0)
    UIHelper.ScrollViewDoLayout(self.ScrollViewFacePage)
    UIHelper.ScrollToTop(self.ScrollViewFacePage, 0)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewFacePage, self.WidgetArrow)

    UIHelper.SetString(self.LabelFaceCount, string.format("%d", nCount))

    self.m.nPage = nPage
    self:UpdatePaginate(nPage, nTotalPage)

    UIHelper.SetVisible(self.WidgetEmpty, nCount <= 0)
end

function UICoinShopWardrobeView:LinkHair(nHairID)
    local bFound = false
    for i, dwID in ipairs(self.m.tbGoodsList) do
        if dwID == nHairID then
            local nPage = math.floor((i + PAGE_NEW_FACE_COUNT - 1) / PAGE_NEW_FACE_COUNT)
            self:UpdateHairList(self.m.tbGoodsList, nPage)
            FireUIEvent("PREVIEW_HAIR", nHairID, nil, true, true, false)
            bFound = true
            break
        end
    end

    if not bFound then
        self:UpdateCurPageList(1)
    end
end

function UICoinShopWardrobeView:LinkSfx(nType, nEffect)
    local bFound = false

    local nFilterType = EffectTypeToFilterType[nType]
    if FilterDef.CoinShopWardrobeEffect.GetRunTime() == nil then
        local tbRuntime = { [1] = {nType},}
        FilterDef.CoinShopWardrobeEffect.SetRunTime(tbRuntime)
    end
    local tbFilterDefSelected = FilterDef.CoinShopWardrobeEffect.tbRuntime
    tbFilterDefSelected[1][1] = nType

    local tbTitle = self.m.tbTitle
    self.m.tbGoodsList = self:GetGoodList(tbTitle)

    for i, tbInfo in ipairs(self.m.tbGoodsList) do
        local dwEffectID = tbInfo.dwEffectID
        if dwEffectID == nEffect then
            local nPage = math.floor((i + PAGE_PROP_COUNT - 1) / PAGE_PROP_COUNT)
            self:UpdateEffectList(self.m.tbGoodsList, nPage)
            FireUIEvent("PREVIEW_PENDANT_EFFECT_SFX", nFilterType, nEffect)
            bFound = true
            break
        end
    end

    if not bFound then
        self:UpdateCurPageList(1)
    end
end

function UICoinShopWardrobeView:UpdateListItemState()
    if self.m and self.m.tbScriptList then
        for _, script in ipairs(self.m.tbScriptList) do
            if script.UpdateItemState then
                script:UpdateItemState()
            end
        end
    end
end

function UICoinShopWardrobeView:ClearSelect()
    UIHelper.SetSelected(self.TogFilter, false)
    UIHelper.SetSelected(self.TogHairFilter, false)
    UIHelper.SetSelected(self.TogParticulars, false)

    if self.m and self.m.tbScriptList then
        for _, script in ipairs(self.m.tbScriptList) do
            if script.itemIcon and script._nPrefabID ~= PREFAB_ID.WidgetWardrobePetBottom then
                script.itemIcon:SetSelected(false)
            end
        end
    end
end

function UICoinShopWardrobeView:OnSelectedFilter(bSelected)
    -- UIHelper.SetVisible(self.filterTips._rootNode, bSelected)
    -- if bSelected then
    --     self.filterTips:Refresh()
    -- end
    if bSelected then
        if self.m.tbTitle.nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
            _, self.scriptFilter = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogFilter, TipsLayoutDir.BOTTOM_RIGHT, FilterDef.CoinShopWardrobeExterior)
        elseif self.m.tbTitle.nType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogFilter, TipsLayoutDir.BOTTOM_RIGHT, FilterDef.CoinShopWardrobeWeapon)
        elseif self.m.tbTitle.nType == COIN_SHOP_GOODS_TYPE.ITEM and self.m.tbTitle.nRewardsClass == REWARDS_CLASS.EFFECT then
            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogFilter, TipsLayoutDir.BOTTOM_RIGHT, FilterDef.CoinShopWardrobeEffect)
        end
    end
end

function UICoinShopWardrobeView:UpdateFilterTexture(bFilter)
    UIHelper.SetVisible(self.ImgScreen, not bFilter)
    UIHelper.SetVisible(self.ImgScreenSelect, bFilter)
end

function UICoinShopWardrobeView:SetScriptCustomPendant(script)
    self.scriptCustomPendant = script
end

function UICoinShopWardrobeView:SetScriptHairDyeCase(script)
    self.scriptHairDyeCase = script
end

--- 设置推荐外观浮窗脚本引用（由MainView传入）
function UICoinShopWardrobeView:SetShareStationWidget(script)
    self.shareStationWidget = script
end

--- 根据当前选中的标题类型刷新推荐浮窗显示
function UICoinShopWardrobeView:RefreshShareStationRecommend(eGoodsType, dwGoodsID)
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
-- @return table { [nSub] = { dwID, ... }, ... }
function UICoinShopWardrobeView:BuildExteriorListFromPreview(nType, nClass)
    local tExteriorList = {}
    local tRoleViewData = ExteriorCharacter.GetRoleData()
    if not tRoleViewData then
        return tExteriorList
    end

    if nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
        -- 收集所有正在预览的外观部件
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
            -- 取当前筛选的特效类型，映射到 PLAYER_SFX_REPRESENT
            local tbFilterDefSelected = FilterDef.CoinShopWardrobeEffect.tbRuntime
            local nFilterType = EFFECT_FILTER_TYPE.FOOT
            if tbFilterDefSelected then
                nFilterType = tbFilterDefSelected[1][1]
            end
            local nSub = EffectTypeToFilterType[nFilterType]
            if nSub then
                local tAllEffectData = tRoleViewData[COINSHOP_BOX_INDEX.EFFECT_SFX]
                local tEffectData = tAllEffectData and tAllEffectData[nSub]
                if tEffectData and tEffectData.nEffectID and tEffectData.nEffectID > 0 then
                    local szEffectType = ShareExteriorData.GetEffectTypeBySub(nSub)
                    local szKey = szEffectType or nSub
                    tExteriorList[szKey] = { tEffectData.nEffectID }
                end
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

function UICoinShopWardrobeView:GetCustomPendantCanSet(nIndex, hPlayer)
    local bCanSet
    local tData = ExteriorCharacter.GetPreviewPendant(nIndex)
    if tData and tData.dwTabType and tData.dwIndex then
        local bHave
        if tData.tColorID then
            local tColorID = tData.tColorID
            bHave = hPlayer.IsColorPendentExist(tData.dwIndex, tColorID[1], tColorID[2], tColorID[3])
        else
            bHave = hPlayer.IsPendentExist(tData.dwIndex)
        end
        if bHave then
            local hItemInfo = GetItemInfo(tData.dwTabType, tData.dwIndex)
            local nType = Exterior_BoxIndexToRepresentSub(nIndex)
            bCanSet = IsCustomPendantRepresentID(nType, hItemInfo.nRepresentID, hPlayer.nRoleType)
        end
    end
    return bCanSet
end

function UICoinShopWardrobeView:CheckCustomPendantToggle()
    if not self.m.tbTitle then
        return
    end
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local bCanSet = false
    if self.m.tbTitle.nType == COIN_SHOP_GOODS_TYPE.ITEM then
        local nEquipSub = CoinShop_RewardsClassToSub(self.m.tbTitle.nRewardsClass)
        if nEquipSub == EQUIPMENT_SUB.HEAD_EXTEND then
            for k, nPos in ipairs(PENDENT_HEAD_TYPE) do
                local nIndex  = CoinShop_PendantTypeToBoxIndex(nPos)
                bCanSet = bCanSet or self:GetCustomPendantCanSet(nIndex, hPlayer)
            end
        elseif self.m.tbTitle.nRewardsClass == REWARDS_CLASS.EFFECT then
            local tbFilterDefSelected = FilterDef.CoinShopWardrobeEffect.tbRuntime
            local nType = EFFECT_FILTER_TYPE.FOOT
            if tbFilterDefSelected then
                nType = tbFilterDefSelected[1][1]
            end
            bCanSet = self:GetCustomEffectCanSet(nType)
        else
            local nIndex =  Exterior_SubToBoxIndex(nEquipSub)
            bCanSet = self:GetCustomPendantCanSet(nIndex, hPlayer)
        end
    end
    UIHelper.SetVisible(self.TogDIY, bCanSet)
    UIHelper.LayoutDoLayout(self.LayoutWardrobeTipsBotton)
    local bOpen = UIHelper.GetVisible(self.scriptCustomPendant._rootNode)
    UIHelper.SetSelected(self.TogDIY, bOpen, false)
end

function UICoinShopWardrobeView:CheckCustomEffectToggle()
    
end

function UICoinShopWardrobeView:GetCustomEffectCanSet(nType)
    local bCanSet = false
    local nEffectType = EffectTypeToFilterType[nType]
    local tData = ExteriorCharacter.GetPreviewEffect(nEffectType)
    if tData and nEffectType == PLAYER_SFX_REPRESENT.SURROUND_BODY then
        bCanSet = true
    end
    return bCanSet
end

function UICoinShopWardrobeView:OnListSizeChanged()
    local _, screenHeight = UIHelper.GetContentSize(self.ScrollViewWardrobeCardList)
    local oldPercent = UIHelper.GetScrollPercent(self.ScrollViewWardrobeCardList)
    local _, oldHeight = UIHelper.GetInnerContainerSize(self.ScrollViewWardrobeCardList)
    local pos = oldPercent * (oldHeight - screenHeight)
    UIHelper.ScrollViewDoLayout(self.ScrollViewWardrobeCardList)
    local _, newHeight = UIHelper.GetInnerContainerSize(self.ScrollViewWardrobeCardList)
    local newPercent = pos / (newHeight - screenHeight)
    UIHelper.ScrollToPercent(self.ScrollViewWardrobeCardList, newPercent, 0)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewWardrobeCardList, self.WidgetArrow)
end

function UICoinShopWardrobeView:InitEffectPage()
    UIHelper.SetVisible(self.TogFilter, true)
    self:UpdateEffectList(self.m.tbGoodsList, self.m.nPage or 1)
end

function UICoinShopWardrobeView:UpdateEffectList(tbList, nPage)
    local nCount = #tbList
    local nTotalPage = math.ceil(nCount / PAGE_POSTURE_COUNT)
    nPage = math.min(nPage, nTotalPage)
    nPage = math.max(nPage, 1)
    local nStart = (nPage - 1) * PAGE_POSTURE_COUNT + 1
    local nEnd = nPage * PAGE_POSTURE_COUNT
    nEnd = math.min(nEnd, nCount)

    self.ScrollViewSpecialEffectList:removeAllChildren()
    self.m.tbScriptList = {}

    for i = nStart, nEnd do
        local tbInfo = tbList[i]
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetExteriorSpecialEffect, self.ScrollViewSpecialEffectList)
        scriptCell:OnEnter(tbInfo)
        table.insert(self.m.tbScriptList, scriptCell)
    end

    UIHelper.SetVisible(self.ScrollViewSpecialEffectList, nCount > 0)
    UIHelper.ScrollViewDoLayout(self.ScrollViewSpecialEffectList)
    UIHelper.ScrollToTop(self.ScrollViewSpecialEffectList, 0)

    self.m.nPage = nPage
    self:UpdatePaginate(nPage, nTotalPage)
    UIHelper.SetVisible(self.WidgetEmpty, nCount <= 0)
    self:CheckCustomPendantToggle()
end

--- 当推荐面板已打开时，随预览数据变化刷新推荐内容
function UICoinShopWardrobeView:RefreshRecommendIfOpen(eGoodsType, dwGoodsID)
    if self.TogRecommend and UIHelper.GetSelected(self.TogRecommend) then
        self:RefreshShareStationRecommend(eGoodsType, dwGoodsID)
    end
end


return UICoinShopWardrobeView