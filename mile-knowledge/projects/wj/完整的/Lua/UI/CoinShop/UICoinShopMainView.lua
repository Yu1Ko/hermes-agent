-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopMainView
-- Date: 2022-12-14 20:06:01
-- Desc: ?
-- ---------------------------------------------------------------------------------


-- 主分页=1
-- 2忘了
-- 搜索 = 4
-- 结算=6
-- 左侧导航=8


local UICoinShopMainView = class("UICoinShopMainView")

local bOpenSchoolSplit = false
local SCHOOL_EXTERIOR = 927

local PREVIEW_COOLDOWN = 10

local CHANGE_HAIR_GOODS = 5088
local tbBoxIndex2PreviewBtn = {
    [COINSHOP_BOX_INDEX.BACK_CLOAK_EXTEND] = 1,
    [COINSHOP_BOX_INDEX.CHEST] = 2,
    [COINSHOP_BOX_INDEX.FACE_EXTEND] = 3,
    [COINSHOP_BOX_INDEX.WAIST_EXTEND] = 4,
    [COINSHOP_BOX_INDEX.BACK_EXTEND] = 5,
    [COINSHOP_BOX_INDEX.ITEM] = 6,
}
local SHOW_LIMIT_TIME_FIRST = false

function UICoinShopMainView:OnEnter(fnOpenLink)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        if ActivityData.IsActivityOn(SCHOOL_EXTERIOR) or UI_IsActivityOn(SCHOOL_EXTERIOR) then
			bOpenSchoolSplit = true
		end
        if bOpenSchoolSplit then
            UIHelper.SetVisible(self.TogActivity, true)
            UIHelper.SetVisible(self.ImgLine_Activity, true)
            UIHelper.SetVisible(self.ImgTip, true)
            -- local node = UIHelper.GetChildByName(self.tbTogNewTab[3], "ImgRedPoint")
            -- RedpointMgr.RegisterRedpoint(node, nil, { 2006 })
        end
    end

    rlcmd("switch coin shop 1")

    self.fnOpenLink = fnOpenLink
    self.tTitleCache = {}

    self:RegisterView()

    local bShowRecharge = Platform.IsWindows() or (Platform.IsAndroid() and not Channel.Is_dylianyunyun())
    UIMgr.AddPrefab(PREFAB_ID.WidgetCoin, self.LayoutTongBao, CurrencyType.Coin, false, nil, bShowRecharge)
    -- self.RewardsScript = UIMgr.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.LayoutTongBao)
    -- self.RewardsScript:SetCurrencyType(CurrencyType.StorePoint)

    self:UpdateCurreny()

    self:InitHideShowData()

    UIHelper.SetVisible(self.WidgetAnchorExteriorContent, false)
    UIHelper.SetVisible(self.WidgetAnchorWardrobeContent, false)
    UIHelper.SetVisible(self.WidgetAnchorNewContent, false)
    UIHelper.SetVisible(self.WidgetAnchorHair, false)
    UIHelper.SetVisible(self.WidgetActivityRulePage, false)
    self.shopView = UIHelper.GetBindScript(self.WidgetAnchorExteriorContent)
    self.wardrobeView = UIHelper.GetBindScript(self.WidgetAnchorWardrobeContent)
    self.homeView = UIHelper.GetBindScript(self.WidgetAnchorNewContent)
    self.homeView:SetSchoolClikFunc(function()
        if not bOpenSchoolSplit then
            TipsHelper.ShowNormalTip("2024年6月6日7点后开启“千套校服 免费任选”活动，敬请期待")
        end
        self:OnSelectedActivity()
    end)
    self.schoolRuleView = UIHelper.AddPrefab(PREFAB_ID.WidgetLieBianActivity, self.WidgetActivityRulePage)

    local scriptCustomPendant = UIHelper.GetBindScript(self.WidgetDIYDecoration)
    self.wardrobeView:SetScriptCustomPendant(scriptCustomPendant)

    local scriptHairDyeCase = UIHelper.GetBindScript(self.WidgetDyeingCase)
    self.wardrobeView:SetScriptHairDyeCase(scriptHairDyeCase)

    -- 推荐穿搭
    self.scriptRecommend = UIHelper.GetBindScript(self.WidgetRecommend)
    UIHelper.SetVisible(self.WidgetRecommend, false)

    -- 筛选
    local filterTips = UIHelper.GetBindScript(self.WidgetCategoryTips)
    self.shopView.filterTips = filterTips
    self.wardrobeView.filterTips = filterTips
    -- 详情
    local particularsTips = UIHelper.GetBindScript(self.WidgetParticularsContent)
    self.shopView.particularsTips = particularsTips
    self.wardrobeView.particularsTips = particularsTips
    UIHelper.SetVisible(self.TogLight, false)

    -- 初始化场景
    self.m_scene = self.m_scene or SceneHelper.Create(Const.SHOP_SCENE, false, true, true)

    self:UpdateInfo()
    Event.Dispatch("COINSHOP_ON_OPEN")

    -- Timer.Add(self, 1, function()
    --     UIHelper.SetVisible(self.WidgetDIYDecoration, true)
    --     UIHelper.GetBindScript(self.WidgetDIYDecoration):OnInitWithType(EQUIPMENT_REPRESENT.BACK_EXTEND)
    -- end)

    if AppReviewMgr.IsReview() then
        UIHelper.SetVisible(self.BtnIntegral, false)
        UIHelper.SetVisible(self.BtnBenefits, false)
        UIHelper.SetVisible(self.BtnShareStation, false)
    end

    Timer.AddCycle(self, 0.1, function()
        self:UpdateViewBtnState(self.m_szViewPage or "")
    end)

    ShareCodeData.Init(false)
end

function UICoinShopMainView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)

    BuildFaceData.UnInit()
    BuildBodyData.UnInit()
    CoinShopEffectCustom.UnInit()

    rlcmd("switch coin shop 0")

    UITouchHelper.UnBindModel()

    self:ResetByHideShowData()

    -- 恢复镜头光
    ExteriorCharacter.RestoreCameraLight("CoinShop_View", "CoinShop")

    self:UnRegisterView()

    SceneHelper.Delete(self.m_scene)

    RemoteCallToServer("On_CoinShop_Close")

    if self.nDownloadDynamicID then
        PakDownloadMgr.ReleaseDynamicPakInfo(self.nDownloadDynamicID)
        self.nDownloadDynamicID = nil
    end

    -- local node = UIHelper.GetChildByName(self.tbTogNewTab[3], "ImgRedPoint")
    -- RedpointMgr.UnRegisterRedpoint(node, { 2006 })
end

function UICoinShopMainView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        -- UITouchHelper.ShowModel(false)
        -- UITouchHelper.SetCameraCenterR(300, 25)
        -- UIHelper.SetVisible(self.ItemMiniScene, false)
        -- UIHelper.SetVisible(self.WardrobeMiniScene, false)
         UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogNew, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self:OnSelectedHome()
        end
    end)

    UIHelper.BindUIEvent(self.TogShopping, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self:OnSelectedShop()
        end
    end)

    UIHelper.BindUIEvent(self.TogWardrobe, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self:OnSelectedWardrobe()
        end
    end)

    UIHelper.BindUIEvent(self.TogDecorate, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self:OnSelectedBuildFace()
        end
    end)

    UIHelper.BindUIEvent(self.TogActivity, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            if CoinShopData.GetClickSchoolActivityState() == false then
                CoinShopData.SetClickSchoolActivityState(true)
                Event.Dispatch("SchoolActivityRedUpdate")
            end
            self:OnSelectedActivity()
        end
    end)

    UIHelper.BindUIEvent(self.TogSide, EventType.OnClick, function()
        BuildFaceData.SetMeanwhileSwitch(self.nCurMeanwhile, UIHelper.GetSelected(self.TogSide))
    end)

    UIHelper.BindUIEvent(self.BtnNew, EventType.OnClick, function ()
        if Config.bIsCEVer then
            TipsHelper.ShowNormalTip(g_tStrings.WAIT_FOR_OPEN_TIPS)
            return
        end

        UIMgr.Open(VIEW_ID.PanelActivityBanner, 1)
    end)

    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function ()
        Event.Dispatch(EventType.OnCoinShopClickBuyBtn)
    end)

    UIHelper.BindUIEvent(self.BtnPreserve, EventType.OnClick, function ()
        self:SaveRole()
    end)

    UIHelper.BindUIEvent(self.BtnPresets, EventType.OnClick, function ()
        local tbOutfitList = CoinShopData.GetOutfitList()
        if not tbOutfitList or table.is_empty(tbOutfitList) then
            self:SaveOutfit()
        else
            local szContent = g_tStrings.STR_PRESET_CONFIRM
            local fnConfirm = function ()
                self:SaveOutfit()
            end
            local fnCancel = function ()
                self:StartReplaceOutfit()
            end
            UIMgr.Open(VIEW_ID.PanelReplaceTipsItem, fnCancel, fnConfirm)
            -- local confirmView = UIHelper.ShowConfirm(szContent, fnConfirm, fnCancel, false)
            -- if confirmView then
            --     confirmView:SetButtonContent("Confirm", g_tStrings.STR_PRESET_NEW_CREAT)
            --     confirmView:SetButtonContent("Cancel", g_tStrings.STR_PRESET_REPLACE)
            --     confirmView:SetTouchMaskCloseEnabled(true)
            -- end
        end
    end)

    UIHelper.BindUIEvent(self.BtnReplace, EventType.OnClick, function ()
        self:ReplaceOutfit()
    end)

    UIHelper.BindUIEvent(self.BtnAbandon, EventType.OnClick, function ()
        Event.Dispatch(EventType.OnCoinShopCancelReplaceOutfit)
    end)

    UIHelper.BindUIEvent(self.BtnReturn, EventType.OnClick, function()
        UIHelper.SetSelected(self.TogEye, true)
    end)

    UIHelper.BindUIEvent(self.BtnChange, EventType.OnClick, function ()
        if self.bExteriorChangeColor then
            self:ExteriorChangeColor()
        else
            self:ExteriorChangeHair()
        end
    end)

    UIHelper.BindUIEvent(self.BtnCanel, EventType.OnClick, function ()
        if self.bExteriorChangeColor then
            Event.Dispatch(EventType.OnCoinShopCancelExteriorChangeColor)
        end
        if self.bExteriorChangeHair then
            Event.Dispatch(EventType.OnCoinShopCancelExteriorChangeHair)
        end
    end)

    UIHelper.BindUIEvent(self.BtnRoleReset, EventType.OnClick, function ()
        if self.m_szViewPage == "Role" then
            FireUIEvent("COINSHOP_INIT_ROLE", true, true)
            FireUIEvent("COINSHOP_INIT_RIDE", false)
        elseif self.m_szViewPage == "Ride" then
            FireUIEvent("COINSHOP_INIT_RIDE", true)
        elseif self.m_szViewPage == "Pet" then
            FireUIEvent("COINSHOP_INIT_PET", true)
        elseif self.m_szViewPage == "Furniture" then
            FireUIEvent("COINSHOP_INIT_FURNITURE", true)
        end
    end)

    UIHelper.BindUIEvent(self.BtnSearch, EventType.OnClick, function ()
        if self.curView then
            UIHelper.PlayAni(self, self.AniAll, "AniLeftHide")
        end
        UIMgr.Open(VIEW_ID.PanelExteriorSearch, self.nCoinShopType, function()
            if self.curView then
                UIHelper.PlayAni(self, self.AniAll, "AniLeftShow")
            end
        end)
    end)

    UIHelper.BindUIEvent(self.TogEye, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            ExteriorCharacter.RestoreCameraCenter()
        else
            ExteriorCharacter.CameraToCenter()
        end
    end)

    UIHelper.BindUIEvent(self.BtnTopUp, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelTopUpMain)
    end)

    UIHelper.BindUIEvent(self.BtnIntegral, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelIntegrallottery)
    end)

    UIHelper.BindUIEvent(self.BtnDeal, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelTradingCenterPop)
    end)

    UIHelper.BindUIEvent(self.TogCoupon, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            UIMgr.Open(VIEW_ID.PanelCouponsPop)
        end
    end)

    UIHelper.BindUIEvent(self.ToggleCamera, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            if self.m_szViewPage == "Role" then
                FireUIEvent("EXTERIOR_CHARACTER_SET_CAMERA_RADIUS", "CoinShop_View", "CoinShop", "Max", nil)
            elseif self.m_szViewPage == "Ride" then
                FireUIEvent("RIDES_MODEL_SET_CAMERA_ZOOM", "CoinShop_View", "CoinShop", "Max")
            elseif self.m_szViewPage == "Pet" then
                FireUIEvent("NPC_MODEL_SET_CAMERA_ZOOM", "CoinShop_View", "CoinShop", "Max")
            elseif self.m_szViewPage == "Furniture" then
                FireUIEvent("FURNITURE_MODEL_SET_CAMERA_ZOOM", "CoinShop_View", "CoinShop", "Max")
            end
        else
            if self.m_szViewPage == "Role" then
                if ExteriorCharacter.szCameraMode == "BuildFace" then
                    FireUIEvent("EXTERIOR_CHARACTER_SET_CAMERA_RADIUS", "CoinShop_View", "CoinShop", "BuildFaceMin", nil)
                else
                    FireUIEvent("EXTERIOR_CHARACTER_SET_CAMERA_RADIUS", "CoinShop_View", "CoinShop", "Min", nil)
                end
            elseif self.m_szViewPage == "Ride" then
                FireUIEvent("RIDES_MODEL_SET_CAMERA_ZOOM", "CoinShop_View", "CoinShop", "Min")
            elseif self.m_szViewPage == "Pet" then
                FireUIEvent("NPC_MODEL_SET_CAMERA_ZOOM", "CoinShop_View", "CoinShop", "Min")
            elseif self.m_szViewPage == "Furniture" then
                FireUIEvent("FURNITURE_MODEL_SET_CAMERA_ZOOM", "CoinShop_View", "CoinShop", "Min")
            end
        end
    end)

    --LabelMoney_Tong
    UIHelper.BindUIEvent(self.WidgetMoney4, EventType.OnClick, function()
        CurrencyData.ShowCurrencyHoverTips(self.WidgetMoney4, CurrencyType.Coin)
    end)
    UIHelper.SetTouchEnabled(self.WidgetMoney4, true)

    --LabelMoney_Yin
    UIHelper.BindUIEvent(self.WidgetMoney3, EventType.OnClick, function()
        CurrencyData.ShowCurrencyHoverTips(self.WidgetMoney3, CurrencyType.StorePoint)
    end)
    UIHelper.SetTouchEnabled(self.WidgetMoney3, true)
    --LabelMoney_Jin
    UIHelper.BindUIEvent(self.WidgetMoney2, EventType.OnClick, function()
        CurrencyData.ShowCurrencyHoverTips(self.WidgetMoney2, CurrencyType.StorePoint)
    end)
    UIHelper.SetTouchEnabled(self.WidgetMoney2, true)

    for i, toggle in ipairs(self.tbTogNewTab) do
        UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function (_, bSelected)
            if bSelected then
                local tbTitle = self.tbHomeTitleList[i]
                self:OnSelectTitle(tbTitle.nType, tbTitle.nRewardsClass)
                -- if i == 3 then
                --     CoinShopData.SetClickSchoolActivityState(true)
                --     Event.Dispatch("SchoolActivityRedUpdate")
                -- end
            end
        end)
    end

    UIHelper.BindUIEvent(self.TogHat, EventType.OnSelectChanged, function (_, bSelected)
        self:HideHat(not bSelected)
        local szMsg = (bSelected and "已显示" or "已隐藏") .. "帽子"
        TipsHelper.ShowNormalTip(szMsg)
    end)

    UIHelper.BindUIEvent(self.TogFacePendant, EventType.OnSelectChanged, function (_, bSelected)
        g_pClientPlayer.SetFacePendentHideFlag(not bSelected)
        local szMsg = (bSelected and "已显示" or "已隐藏") .. "面部挂件"
        TipsHelper.ShowNormalTip(szMsg)
    end)

    UIHelper.BindUIEvent(self.TogFace, EventType.OnSelectChanged, function (_, bSelected)
        GetFaceLiftManager().SetDecorationShowFlag(bSelected)
        local szMsg = (bSelected and "已显示" or "已隐藏") .. "面部装饰物"
        TipsHelper.ShowNormalTip(szMsg)
    end)

    UIHelper.BindUIEvent(self.TogHideHair, EventType.OnSelectChanged, function(_, bSelected)
        g_pClientPlayer.HideHair(bSelected)
        local szMsg = (not bSelected and "已显示" or "已隐藏") .. "发型"
        TipsHelper.ShowNormalTip(szMsg)
    end)

    UIHelper.BindUIEvent(self.TogCloak, EventType.OnSelectChanged, function(_, bSelected)
        g_pClientPlayer.SetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL, not bSelected)
        local szMsg = (bSelected and "已显示" or "已隐藏") .. "披风"
        TipsHelper.ShowNormalTip(szMsg)
    end)

    UIHelper.BindUIEvent(self.BtnBenefits, EventType.OnClick, function ()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.COIN, "") then
            return
        end
        UIMgr.Open(VIEW_ID.PanelWelfareReturnPop)
    end)

    UIHelper.BindUIEvent(self.TogBag, EventType.OnSelectChanged, function(_, bSelected)
		if bSelected then
            ExteriorCharacter.RestoreCameraCenter()
        else
            ExteriorCharacter.CameraToCenter()
            UIMgr.Open(VIEW_ID.PanelHalfBag)
        end
	end)

    for i, tog in ipairs(self.tbTogEmotion) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function ()
            self:OnSelectedEmotion(i)
            UIHelper.SetSelected(tog, false)
        end)
    end

    for i, img in ipairs(self.tbImgEmotion1) do
        UIHelper.SetTexture(img, BuildFaceAniImg[i])
    end
    for i, img in ipairs(self.tbImgEmotion2) do
        UIHelper.SetTexture(img, BuildFaceAniImg[i])
    end

    UIHelper.BindUIEvent(self.BtnBodyCodeCloud, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelBodyCodeList, false)
    end)

    UIHelper.BindUIEvent(self.BtnCommitBodyCode, EventType.OnClick, function ()
        Event.Dispatch(EventType.OnStartDoUploadShareData, false, SHARE_DATA_TYPE.BODY)
        -- UIMgr.Open(VIEW_ID.PanelPrintFaceToCloud, nil, true)
    end)

    UIHelper.BindUIEvent(self.BtnEnterBodyCode, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelEnterFaceCode, SHARE_DATA_TYPE.BODY)
    end)

    UIHelper.BindUIEvent(self.BtnFaceCodeCloud, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelCoinFaceCodeList, false)
    end)

    UIHelper.BindUIEvent(self.BtnCommitFaceCode, EventType.OnClick, function ()
        Event.Dispatch(EventType.OnStartDoUploadShareData, false, SHARE_DATA_TYPE.FACE)
    end)

    UIHelper.BindUIEvent(self.BtnUploadDressup, EventType.OnClick, function ()
        Event.Dispatch(EventType.OnStartDoUploadShareData, false, SHARE_DATA_TYPE.EXTERIOR)
    end)

    UIHelper.BindUIEvent(self.BtnEnterFaceCode, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelEnterFaceCode, SHARE_DATA_TYPE.FACE)
    end)

    UIHelper.BindUIEvent(self.BtnDressupEnterCode, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelEnterFaceCode, SHARE_DATA_TYPE.EXTERIOR)
    end)

    UIHelper.BindUIEvent(self.BtnShareStation, EventType.OnClick, function ()
        -- if not ShareStationData.GetOpenState() then
        --     TipsHelper.ShowNormalTip("部分功能升级维护中，商城设计站暂未开放")
        --     return
        -- end
        self.buildFaceView = self.buildFaceView or UIHelper.AddPrefab(PREFAB_ID.WidgetCoinShopBuildFace, self.WidgetAnchorFace)
        self:OnSelectedBuildFace()
        ShareStationData.OpenShareStation(SHARE_DATA_TYPE.EXTERIOR)
    end)

    UIHelper.BindUIEvent(self.BtnInputFace, EventType.OnClick, function ()
        self.buildFaceView = self.buildFaceView or UIHelper.AddPrefab(PREFAB_ID.WidgetCoinShopBuildFace, self.WidgetAnchorFace)
        if not self.buildFaceView then return end

        if Platform.IsWindows() and GetOpenFileName then
            local szFile
            local tFace = BuildFaceData.tNowFaceData
            if tFace.bNewFace then
                szFile = GetOpenFileName(g_tStrings.STR_NEW_FACE_LIFT_CHOOSE_FILE, g_tStrings.STR_FACE_LIFT_CHOOSE_INI .. "(*.ini)\0*.ini\0\0")
            elseif tFace.tFaceData and not tFace.tFaceData.bNewFace then
                szFile = GetOpenFileName(g_tStrings.FACE_LIFT_CHOOSE_FILE, g_tStrings.STR_FACE_LIFT_CHOOSE_DAT .. "(*.dat)\0*.dat\0\0")
            end

            Timer.AddFrame(self, 1, function ()
                if not string.is_nil(szFile) then
                    self.buildFaceView:LoadFaceData(szFile)
                end
            end)
        else
            UIMgr.Open(VIEW_ID.PanelFacePrintLocal, function (szFile)
                if not Platform.IsWindows() then
                    szFile = UIHelper.UTF8ToGBK(GetFullPath(szFile))
                end
                self.buildFaceView:LoadFaceData(szFile)
            end)
        end
    end)

    UIHelper.BindUIEvent(self.BtnOutputFace, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelEditFolderName, function (szFileName)
            local tFace = BuildFaceData.tNowFaceData
            local bSucc, szMsg
            if tFace.bNewFace then
                bSucc, szMsg = NewFaceData.ExportData(szFileName, tFace, BuildFaceData.nRoleType, not BuildFaceData.bPrice)
            elseif tFace.tFaceData and not tFace.tFaceData.bNewFace then
                bSucc, szMsg = NewFaceData.ExportOldData(szFileName, tFace.tFaceData, BuildFaceData.nRoleType, not BuildFaceData.bPrice)
            end
            if not bSucc and szMsg then
                TipsHelper.ShowNormalTip(szMsg)
            end
        end)
    end)

    UIHelper.BindUIEvent(self.TogTaozhuang, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            -- ExteriorCharacter.SetRepresentReplace(bSelected)
            UIHelper.SetSelected(self.TogMenu, false)
            CoinShopData.InitCoinShopSubSetData()
            local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogTaozhuang, TipsLayoutDir.LEFT_CENTER, FilterDef.CoinShopSubSet)
            script:SetBtnConfirmFunc(function()
                CoinShopData.SaveSubSetFlag(self.nChestFlag, self.nHairFlag)
            end, "保存形象")
            script:SetBtnResetVis(false)
            self.scriptFilter = script
            self:UpdateFilterSaveBtnState()
        else
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetFiltrateTip)
        end
    end)

    UIHelper.BindUIEvent(self.TogMenu, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetFiltrateTip)
        end
    end)
    -- UIHelper.SetVisible(self.BtnInputFace, Platform.IsWindows())
    -- UIHelper.SetVisible(self.BtnOutputFace, Platform.IsWindows())
    -- UIHelper.LayoutDoLayout(self.LayoutFaceCodeMenu)
end

function UICoinShopMainView:RegEvent()

    Event.Reg(self, "ON_HAIR_SUBSET_HIDE_FLAG_UPDATE", function()
        CoinShopData.InitSelect()
        CoinShopData.UpdateHairHideFlag()
        if self.scriptFilter then
            self.scriptFilter:OnEnter(FilterDef.CoinShopSubSet)
            self:UpdateFilterSaveBtnState()
        end
    end)

    Event.Reg(self, "ON_EXTERIOR_SUBSET_HIDE_FLAG_UPDATE", function()
        CoinShopData.InitSelect()
        CoinShopData.UpdateExteriorHideFlag()
        if self.scriptFilter then
            self.scriptFilter:OnEnter(FilterDef.CoinShopSubSet)
            self:UpdateFilterSaveBtnState()
        end
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbInfo)
        if szKey ~= FilterDef.CoinShopSubSet.Key then
            return
        end
        local bReplace = false
        if tbInfo and tbInfo[1] and tbInfo[1][1] == 1 then
            bReplace = true
        end
        ExteriorCharacter.SetRepresentReplace(bReplace)

        local nChestFlag = CoinShopData.GetSubSetFlag(tbInfo[2], #FilterDef.CoinShopSubSet[2].tbList)
        if not self.nChestFlag or self.nChestFlag ~= nChestFlag then
            self.nChestFlag = nChestFlag
            FireUIEvent("SET_SUBSET_HIDE_FLAG", EQUIPMENT_REPRESENT.CHEST_SUBSET_HIDE_MASK, nChestFlag)
        end

        local nHairFlag = CoinShopData.GetSubSetFlag(tbInfo[3], #FilterDef.CoinShopSubSet[3].tbList)
        if not self.nHairFlag or self.nHairFlag ~= nHairFlag then
            self.nHairFlag = nHairFlag
            FireUIEvent("SET_SUBSET_HIDE_FLAG", EQUIPMENT_REPRESENT.HAIR_SUBSET_HIDE_MASK, nHairFlag)
        end

        self:UpdateFilterSaveBtnState(nHairFlag, nChestFlag)
    end)

    Event.Reg(self, EventType.OnCoinShopSearch, function (tbInfo, bShop)
        if bShop == nil then
            bShop = self.nCoinShopType == UI_COINSHOP_GENERAL.SHOP
        end
        self:OnSearchLink(bShop, tbInfo)
    end)

    Event.Reg(self, EventType.OnCoinShopLink, function (szLink, bShop)
        if bShop == nil then
            bShop = self.nCoinShopType == UI_COINSHOP_GENERAL.SHOP
        end
        local nType, dwID = CoinShopData.ExtractLink(szLink)
        self:OnLink(bShop, nType, dwID)
    end)

    Event.Reg(self, EventType.OnCoinShopLinkFace, function (szLink, bShop)
        UIHelper.SetSelected(self.TogDecorate, true)
        Event.Dispatch(EventType.OnFinishLinkToFace)
    end)

    Event.Reg(self, EventType.OnCoinShopLinkHair, function (szLink)
        self:OnSelectedShop()
        self:LinkTitle(true, 1, 0, 1, false, false)
    end)

    Event.Reg(self, EventType.OnCoinShopLinkPendant, function(szLink, bOpenCustom)
        local numbers = {}
        for number in string.gmatch(szLink, "%d+") do
            table.insert(numbers, tonumber(number))
        end
        local dwID, nColor1, nColor2, nColor3 = numbers[1], numbers[2], numbers[3], numbers[4]
        local tInfo = {
            dwTabType = ITEM_TABLE_TYPE.CUST_TRINKET,
            dwIndex = dwID,
        }
        if nColor1 and nColor2 and nColor3 then
            tInfo.tColorID = {nColor1, nColor2, nColor3}
        end
        local tItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwID)
        local nClass
        if tItemInfo then
            nClass = CoinShop_SubToRewardsClass(tItemInfo.nSub)
        end
        self.bInLinkGoods = true
        if nClass and self:LinkTitle(false, COIN_SHOP_GOODS_TYPE.ITEM, nClass) then
            self:LinkPendant(tInfo, bOpenCustom)
        end
        self.bInLinkGoods = false
    end)

    Event.Reg(self, EventType.OnCoinShopLinkTitle, function (szLink, bShop)
        if bShop == nil then
            bShop = self.nCoinShopType == UI_COINSHOP_GENERAL.SHOP
        end
        local res = string.split(szLink, ",")
        for _, v in ipairs(res) do
            if v == "Outfit" then
                if self:LinkTitle(bShop, nil, nil, nil, true) then
                    break
                end
            else
                local nType, nClass = CoinShopData.ExtractLinkTitle(v)
                if self:LinkTitle(bShop, nType, nClass) then
                    break
                end
            end
        end
    end)

    Event.Reg(self, EventType.OnCoinShopPreviewBoxLinkTitle, function (szLink)
        local bShop = false
        if self.curView == self.shopView then
            bShop = true
        elseif self.curView == self.wardrobeView then
            bShop = false
        else
            return
        end
        Event.Dispatch(EventType.OnCoinShopLinkTitle, szLink, bShop)
    end)

    Event.Reg(self, EventType.OnShowFaceCodeBtn, function (bShow, nCoinShopType)
        if nCoinShopType and nCoinShopType ~= self.nCoinShopType then return end

        UIHelper.SetVisible(self.TogCloudFace, bShow)
        UIHelper.LayoutDoLayout(self.WidgetAnchorRightLine)
    end)

    Event.Reg(self, EventType.OnShowBodyCodeBtn, function (bShow, nCoinShopType)
        if nCoinShopType and nCoinShopType ~= self.nCoinShopType then return end

        UIHelper.SetVisible(self.TogCloudBody, bShow)
        UIHelper.LayoutDoLayout(self.WidgetAnchorRightLine)
    end)

    Event.Reg(self, "COINSHOPVIEW_ROLE_DATA_UPDATE", function ()
        self:OnRoleViewDataUpdate()
    end)

    Event.Reg(self, "COINSHOPVIEW_RIDE_DATA_UPDATE", function ()
        self:OnRideViewDataUpdate()
    end)

    Event.Reg(self, "COINSHOPVIEW_PET_DATA_UPDATE", function ()
        self:OnPetViewDataUpdate()
    end)

    Event.Reg(self, "COINSHOPVIEW_FURNITURE_DATA_UPDATE", function ()
        self:OnFurnitureViewDataUpdate()
    end)

    Event.Reg(self, "COINSHOP_SHOW_VIEW", function (szViewPage, bShowWeapon)
        if self.bReplaceOutfit then
            Event.Dispatch(EventType.OnCoinShopCancelReplaceOutfit)
        end
        if self.bExteriorChangeColor then
            Event.Dispatch(EventType.OnCoinShopCancelExteriorChangeColor)
        end
        if self.bExteriorChangeHair then
            Event.Dispatch(EventType.OnCoinShopCancelExteriorChangeHair)
        end

        szViewPage = szViewPage or "Role"
        local bSamePage = szViewPage == self.m_szViewPage
        if bSamePage then
            ExteriorCharacter.SetWeaponShow(bShowWeapon, szViewPage == "Role")
        else
            ExteriorCharacter.SetWeaponShow(bShowWeapon, false)
            self:UpdateViewData(szViewPage)
        end
    end)

    Event.Reg(self, "COIN_SHOP_SAVE_RESPOND", function ()
        self:UpdateCurViewPageList()
        FireUIEvent("COINSHOP_INIT_ROLE", true, true)
    end)

    Event.Reg(self, "COIN_SHOP_BUY_RESPOND", function ()
        self:UpdateCurViewPageList()
        self:UpdateViewData(self.m_szViewPage)
        -- self:SaveRole()
    end)

    Event.Reg(self, "ON_SELECT_PENDANT", function ()
        self:UpdateCurViewPageList()
        self:UpdateViewData(self.m_szViewPage)
    end)

    Event.Reg(self, "ON_EQUIP_PENDENT_PET_NOTIFY", function ()
        self:UpdateCurViewPageList()
        self:UpdateViewData(self.m_szViewPage)
    end)

    Event.Reg(self, "ON_CHANGE_PENDENT_PET_POS_NOTIFY", function ()
        self:UpdateCurViewPageList()
        self:UpdateViewData(self.m_szViewPage)
    end)

    Event.Reg(self, "SYNC_REWARDS", function ()
        self:UpdateCurreny()
    end)

    Event.Reg(self, "FACE_LIFT_VOUCHERS_CHANGE", function ()
        self:UpdateCurreny()
    end)

    Event.Reg(self, "ON_COIN_SHOP_VOUCHER_CHANGED", function ()
        self:UpdateCurreny()
    end)

    Event.Reg(self,  "COINSHOP_UPDATE_ROLE", function ()
        self:OnRoleViewDataUpdate()
    end)

    Event.Reg(self, "ADD_STORAGE_GOODS", function ()
        FireUIEvent("TRADE_CENTER_COUNT_UPDATE")
    end)

    Event.Reg(self, "DEL_STORAGE_GOODS", function ()
        FireUIEvent("TRADE_CENTER_COUNT_UPDATE")
    end)

    -- Event.Reg(self, "COINSHOP_PUSHINFO_UPDATE", function ()
    --     self:UpdateWelfareNotify()
    -- end)

    Event.Reg(self, "ON_EXTERIOR_CHARACTER_SET_CAMERA_RADIUS", function (szFrame, szName, szRadius)
        if szRadius == "Max" then
            UIHelper.SetSelected(self.ToggleCamera, true, false)
        else
            UIHelper.SetSelected(self.ToggleCamera, false, false)
        end
    end)

    Event.Reg(self, "DIS_COUPON_CHANGED", function()
        self:RefreshTitleListRed()
         -- 校服券拥有数量刷新
        self:UpdateCouponNum()
        self:RefreshSchoolTitleListRed()
    end)

    Event.Reg(self, EventType.ON_ADD_PENDANT, function()
        Timer.AddFrame(self, 1, function()
            self:RefreshTitleListRed()
        end)
    end)

    Event.Reg(self, EventType.ON_UPDATE_PENDANT_NEW, function()
        self:RefreshTitleListRed()
    end)

    Event.Reg(self, EventType.ON_UPDATE_EXTERIOR_NEW, function()
        self:RefreshTitleListRed()
    end)

    Event.Reg(self, EventType.ON_UPDATE_WEAPON_EXTERIOR_NEW, function()
        self:RefreshTitleListRed()
    end)

    Event.Reg(self, EventType.ON_UPDATE_PENDANT_PET_NEW, function()
        self:RefreshTitleListRed()
    end)

    Event.Reg(self, EventType.ON_UPDATE_HAIR_NEW, function()
        self:RefreshTitleListRed()
    end)

    Event.Reg(self, EventType.ON_UPDATE_FACE_NEW, function()
        self:RefreshTitleListRed()
    end)

    Event.Reg(self, EventType.ON_UPDATE_BODY_NEW, function()
        self:RefreshTitleListRed()
    end)

    Event.Reg(self, EventType.ON_UPDATE_IDLEACTION_NEW, function()
        self:RefreshTitleListRed()
    end)

    Event.Reg(self, EventType.OnCoinShopClickBuyBtn, function ()
        local function DoBuy(bNewFace, bNewBody)
            if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EXTERIOR, "CoinShop") then
                return
            end

            local tbBuySaveList
            if self.m_szViewPage == "Role" then
                tbBuySaveList = CoinShopPreview.GetBuySaveList(bNewFace, bNewBody)
            elseif self.m_szViewPage == "Ride" then
                tbBuySaveList = CoinShopPreview.GetChangeRideItem()
            elseif self.m_szViewPage == "Pet" then
                tbBuySaveList = CoinShopPreview.GetChangePetItem()
            elseif self.m_szViewPage == "Furniture" then
                tbBuySaveList = CoinShopPreview.GetChangeFurnitureItem()
            end
            local tbBuyList = {}
            for _, tbItem in ipairs(tbBuySaveList) do
                if not tbItem.bHave then
                    table.insert(tbBuyList, tbItem)
                end
            end
            if #tbBuyList > 0 then
                local bFromLimit = false
                if self.curView == self.homeView and self.tHomeCacheTitleParams then
                    if CoinShopData.IsHomeLimitTitle(self.tHomeCacheTitleParams.nType, self.tHomeCacheTitleParams.nClass) then
                        bFromLimit = true
                    end
                end
                UIMgr.Open(VIEW_ID.PanelSettleAccounts, tbBuyList, true, bFromLimit)
            end
        end

        local nFaceIndex
        local bNewFace = ExteriorCharacter.IsNewFace()
        local bFaceHave = true
        if bNewFace then
            bFaceHave = ExteriorCharacter.IsAlreadyHaveNewFace()
            _, nFaceIndex = ExteriorCharacter.GetPreviewNewFace()
        else
            local tFace = ExteriorCharacter.GetPreviewFace()
            if tFace and tFace.UserData then
                nFaceIndex = tFace.UserData.nIndex
                bFaceHave = ExteriorCharacter.IsAlreadyHaveFace()
            end
        end

        local bBodyHave = ExteriorCharacter.IsAlreadyHaveBody()
        local nBodyIndex
        if not bBodyHave then
            _, nBodyIndex = ExteriorCharacter.GetPreviewBody()
        end
        if (not bFaceHave) or nBodyIndex then
            local bUseNewFace = false
            if self.buildFaceView then
                bUseNewFace = self.buildFaceView:IsBuyNew()
            end
            UIMgr.Open(VIEW_ID.PanelBulidFaceDetail, nFaceIndex, nBodyIndex, bNewFace, bFaceHave, bUseNewFace, DoBuy)
        else
            DoBuy(false)
        end
    end)

    Event.Reg(self,  EventType.OnCoinShopEnterReplaceOutfit, function ()
        self:OnEnterReplaceOutfit()
    end)

    Event.Reg(self, EventType.OnCoinShopCancelReplaceOutfit, function ()
        self:OnCancelReplaceOutfit()
    end)

    Event.Reg(self, EventType.OnCoinShopSelectedReplaceOutfit, function (tbOutfit, bSelected)
        if bSelected then
            self.tbSelectedReplaceOutfit = tbOutfit
        elseif self.tbSelectedReplaceOutfit == tbOutfit then
            self.tbSelectedReplaceOutfit = nil
        else
            return
        end
        if self.tbSelectedReplaceOutfit then
            local tRepresentID = CoinShopData.GetOutfitRepresent(self.tbSelectedReplaceOutfit)
            FireUIEvent("EXTERIOR_CHARACTER_UPDATE", "CoinShop_View", "CoinShop", tRepresentID, false, nil, nil)
            UIHelper.SetButtonState(self.BtnReplace, BTN_STATE.Normal)
        else
            self:UpdateRole()
            UIHelper.SetButtonState(self.BtnReplace, BTN_STATE.Disable)
        end
    end)

    Event.Reg(self, EventType.OnCoinShopEnterExteriorChangeColor, function (dwSrcID, dwDstID)
        self:OnEnterExteriorChangeColor(dwSrcID, dwDstID)
    end)

    Event.Reg(self, EventType.OnCoinShopCancelExteriorChangeColor, function ()
        self:OnCancelExteriorChangeColor()
    end)

    Event.Reg(self, EventType.OnCoinShopEnterExteriorChangeHair, function (dwID, nDyeingID, tSub)
        self:OnEnterExteriorChangeHair(dwID, nDyeingID, tSub)
    end)

    Event.Reg(self, EventType.OnCoinShopCancelExteriorChangeHair, function ()
        self:OnCancelExteriorChangeHair()
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        self:ClearSelect()
    end)

    Event.Reg(self, EventType.OnCoinShopShowItemTips, function (tbGoods, tbCleanBtnInfo)
        self:ShowItemTips(tbGoods, tbCleanBtnInfo)
    end)

    Event.Reg(self, EventType.OnCoinShopShowItemDetail, function (dwID)
        self:ShowItemDetail(dwID)
    end)

    Event.Reg(self, "COINSHOP_OPEN_RECOMMEND_BY_GOODS", function(eGoodsType, dwGoodsID)
        self.eLastRecommendGoodsType = eGoodsType
        self.dwLastRecommendGoodsID = dwGoodsID
        self:OpenRecommendByGoods(eGoodsType, dwGoodsID)
        if self.curView and self.curView.RefreshRecommendIfOpen then
            self.curView:RefreshRecommendIfOpen(eGoodsType, dwGoodsID)
        end
    end)

    Event.Reg(self, "COINSHOP_REFRESH_RECOMMEND_SHOP", function(eGoodsType, dwGoodsID)
        if not self.scriptRecommend or not UIHelper.GetVisible(self.WidgetRecommend) then
            return
        end
        if self.curView and self.curView.RefreshShareStationRecommend then
            self.curView:RefreshShareStationRecommend(eGoodsType, dwGoodsID)
        end
    end)

    Event.Reg(self, "ON_PREVIEW_HAIR", function (nHairID, _, bHideHat)
        if not bHideHat then
            return
        end
        if not ExteriorCharacter.IsInitRole() then
            self:HideHat(bHideHat)
        end

        self.eLastRecommendGoodsType = COIN_SHOP_GOODS_TYPE.HAIR
        self.dwLastRecommendGoodsID = nHairID
        if self.curView and self.curView.RefreshRecommendIfOpen then
            self.curView:RefreshRecommendIfOpen(self.eLastRecommendGoodsType, self.dwLastRecommendGoodsID)
        end
    end)

    Event.Reg(self, "ON_PREVIEW_SUB", function (dwID)
        if dwID and dwID > 0 then
            local tExteriorInfo = GetExterior().GetExteriorInfo(dwID)
            if tExteriorInfo.nSubType == EQUIPMENT_SUB.HELM and not ExteriorCharacter.IsInitRole() then
                self:HideHat(false)
            end
            self.eLastRecommendGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR
            self.dwLastRecommendGoodsID = dwID
            if self.curView and self.curView.RefreshRecommendIfOpen then
                self.curView:RefreshRecommendIfOpen(COIN_SHOP_GOODS_TYPE.EXTERIOR, dwID)
            end
        end
    end)

    Event.Reg(self, "PREVIEW_WEAPON", function (dwID)
        if dwID and dwID > 0 then
            self.eLastRecommendGoodsType = COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR
            self.dwLastRecommendGoodsID = dwID
            if self.curView and self.curView.RefreshRecommendIfOpen then
                self.curView:RefreshRecommendIfOpen(COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR, dwID)
            end
        end
    end)

    Event.Reg(self, "PREVIEW_HAIR", function (nHairID)
        if nHairID and nHairID > 0 then
            self.eLastRecommendGoodsType = COIN_SHOP_GOODS_TYPE.HAIR
            self.dwLastRecommendGoodsID = nHairID
            if self.curView and self.curView.RefreshRecommendIfOpen then
                self.curView:RefreshRecommendIfOpen(COIN_SHOP_GOODS_TYPE.HAIR, nHairID)
            end
        end
    end)

    Event.Reg(self, "PREVIEW_PENDANT", function (tItem)
        if tItem and tItem.dwIndex and tItem.dwIndex > 0 then
            self.eLastRecommendGoodsType = COIN_SHOP_GOODS_TYPE.ITEM
            self.dwLastRecommendGoodsID = tItem.dwIndex
            local curView = self.curView
            if curView and curView.m and curView.m.tbTitle then
                self:OpenRecommendByCurrentPreview(curView.m.tbTitle.nType, curView.m.tbTitle.nRewardsClass or 0, false, tItem.dwIndex)
            end
        end
    end)

    Event.Reg(self, "PREVIEW_PENDANT_PET", function (tItem)
        if tItem then
            local dwID = tItem.dwIndex or tItem.dwLogicID
            if dwID and dwID > 0 then
                self.eLastRecommendGoodsType = COIN_SHOP_GOODS_TYPE.ITEM
                self.dwLastRecommendGoodsID = dwID
                if self.curView and self.curView.RefreshRecommendIfOpen then
                    self.curView:RefreshRecommendIfOpen(COIN_SHOP_GOODS_TYPE.ITEM, dwID)
                end
            end
        end
    end)

    Event.Reg(self, "PREVIEW_PENDANT_EFFECT_SFX", function (nSfxType, nEffectID)
        -- 特效类型：需要按 nSfxType 筛选，不走通用 OpenRecommendByCurrentPreview
        if nEffectID and nEffectID > 0 and self.scriptRecommend and UIHelper.GetVisible(self.WidgetRecommend) then
            local szEffectType = ShareExteriorData.GetEffectTypeBySub(nSfxType)
            if szEffectType then
                local tExteriorList = { [szEffectType] = { nEffectID } }
                local tInfo = Table_GetPendantEffectInfo(nEffectID)
                local szTitleName = (tInfo and tInfo.szName) or ""
                self.scriptRecommend:Open(tExteriorList, szTitleName)
            end
        end
    end)

    Event.Reg(self, "PREVIEW_ITEM", function (tItem)
        if tItem and tItem.dwIndex and tItem.dwIndex > 0 then
            self.eLastRecommendGoodsType = COIN_SHOP_GOODS_TYPE.ITEM
            self.dwLastRecommendGoodsID = tItem.dwIndex
            if self.curView and self.curView.RefreshRecommendIfOpen then
                self.curView:RefreshRecommendIfOpen(COIN_SHOP_GOODS_TYPE.ITEM, tItem.dwIndex)
            end
        end
    end)

    Event.Reg(self, "PREVIEW_SET", function()
        self:RefreshRecommendByCurrentTitle()
    end)

    -- Cancel 事件：预览数据已清除，用当前标题类型重新构建推荐
    Event.Reg(self, "CANCEL_PREVIEW_SUB", function()
        self:RefreshRecommendByCurrentTitle()
    end)

    Event.Reg(self, "CANCEL_PREVIEW_WEAPON", function()
        self:RefreshRecommendByCurrentTitle()
    end)

    Event.Reg(self, "RESET_HAIR", function()
        self:RefreshRecommendByCurrentTitle()
    end)

    Event.Reg(self, "CANCEL_PREVIEW_PENDANT", function()
        self:RefreshRecommendByCurrentTitle()
    end)

    Event.Reg(self, "CANCEL_PREVIEW_PENDANT_PET", function()
        self:RefreshRecommendByCurrentTitle()
    end)

    Event.Reg(self, "RESET_ONE_EFFECT_SFX", function()
        self:RefreshRecommendByCurrentTitle()
    end)

    Event.Reg(self, "RESET_EFFECT_SFX", function()
        self:RefreshRecommendByCurrentTitle()
    end)

    Event.Reg(self, "CANCEL_PREVIEW_ITEM", function()
        self:RefreshRecommendByCurrentTitle()
    end)

    Event.Reg(self, "CANCEL_PREVIEW_SET", function()
        self:RefreshRecommendByCurrentTitle()
    end)

    Event.Reg(self, "COINSHOP_HIDE_HAT", function (bHideHat)
        self:HideHat(bHideHat)
    end)

    Event.Reg(self, "UPDATE_HIDE_FACE_PENDENT", function ()
        UIHelper.SetSelected(self.TogFacePendant, not g_pClientPlayer.bHideFacePendent, false)
        FireUIEvent("COINSHOP_UPDATE_ROLE")
    end)

    Event.Reg(self, "UPDATE_DECORATION_SHOW", function()
        UIHelper.SetSelected(self.TogFace, GetFaceLiftManager().GetDecorationShowFlag(), false)
        FireUIEvent("COINSHOP_UPDATE_ROLE")
    end)

    Event.Reg(self, "ON_HIDE_HAIR_FLAG_CHANGED", function()
        self:UpdateHideHairCheck()
        FireUIEvent("COINSHOP_UPDATE_ROLE")
    end)

    Event.Reg(self, "ON_CHANGE_BODY_BONE_NOTIFY", function (nBodyIndex, nMethod)
        if nMethod == BODY_RESHAPING_OPERATE_METHOD.ADD or nMethod == BODY_RESHAPING_OPERATE_METHOD.REPLACE then
            self:UpdateCurViewPageList()
        end
    end)

    Event.Reg(self, "FACE_LIFT_NOTIFY", function (nErrorCode)
		if nErrorCode == FACE_LIFT_ERROR_CODE.BUY_SUCCESS then
            self:UpdateCurViewPageList()
        end
    end)

    Event.Reg(self, EventType.OnCoinShopWardrobeUpdateFaceList, function ()
        self:OnRoleViewDataUpdate()
    end)

    Event.Reg(self, EventType.OnCoinShopWardrobeUpdateNewFaceList, function ()
        self:OnRoleViewDataUpdate()
    end)

    Event.Reg(self, EventType.OnCoinShopWardrobeUpdateBodyList, function ()
        self:OnRoleViewDataUpdate()
    end)

    Event.Reg(self, EventType.OnCoinShopWardrobeUpdateHairList, function ()
        self:OnRoleViewDataUpdate()
    end)

    Event.Reg(self, EventType.OnCoinShopStartBuildHairDye, function (dwID, tDyeingData)
        if self.nCoinShopType ~= UI_COINSHOP_GENERAL.MY_ROLE then
            UIHelper.SetSelected(self.TogWardrobe, true)
        end
        self:StartBuildHairDye(dwID, tDyeingData)
    end)

    Event.Reg(self, EventType.OnShareStationChangeHelmDye, function (dwID, nDyeingID)
        self.dwExteriorChangeHairID = dwID
        self.dwExteriorChangeHairDyeingID = nDyeingID
        self:ExteriorChangeHair()
    end)

    Event.Reg(self, EventType.OnViewOpen, function (nViewID)
        if nViewID == VIEW_ID.PanelBulidFaceDetail or nViewID == VIEW_ID.PanelCoinBuildFace_DetailAdjust then
            UIHelper.PlayAni(self, self._rootNode, "AniExteriorMainHide")
        end
        if nViewID == VIEW_ID.PanelChangeCloak or nViewID == VIEW_ID.PanelOutfitPreview or nViewID == VIEW_ID.PanelPetMap or nViewID == VIEW_ID.PanelSaddleHorse then
            UIHelper.SetVisible(self.MiniScene, false)
        end
        if nViewID == VIEW_ID.PanelShareStation then
            UIHelper.PlayAni(self, self._rootNode, "AniExteriorMainHide")
        end
        if nViewID == VIEW_ID.PanelCoinShopBuildDyeing then
            UIHelper.PlayAni(self, self._rootNode, "AniExteriorMainHide")
        end
    end)

    Event.Reg(self, EventType.OnViewClose, function (nViewID)
        if nViewID == VIEW_ID.PanelBulidFaceDetail or nViewID == VIEW_ID.PanelCoinBuildFace_DetailAdjust then
            UIHelper.PlayAni(self, self._rootNode, "AniExteriorMainShow")
        end
        if nViewID == VIEW_ID.PanelChangeCloak or nViewID == VIEW_ID.PanelOutfitPreview or nViewID == VIEW_ID.PanelPetMap or nViewID == VIEW_ID.PanelSaddleHorse then
            self:UpdateViewData(self.m_szViewPage)
            UIHelper.SetVisible(self.MiniScene, true)
        end
        if nViewID == VIEW_ID.PanelHalfBag then
            UIHelper.SetSelected(self.TogBag, true)
        end
        if nViewID == VIEW_ID.PanelShareStation and not UIMgr.IsViewOpened(VIEW_ID.PanelBulidFaceDetail, true) then
            UIHelper.PlayAni(self, self._rootNode, "AniExteriorMainShow")
        end
        if nViewID == VIEW_ID.PanelCoinShopBuildDyeing then
            if not UIMgr.IsViewOpened(VIEW_ID.PanelShareStation, true) then
                UIHelper.PlayAni(self, self._rootNode, "AniExteriorMainShow")
            end
        end
    end)

    Event.Reg(self, EventType.OnEquipPakResourceDownload, function()
        if self.m_szViewPage == "Role" then
            self:UpdateRole()
        end
    end)

    Event.Reg(self, EventType.OnMiniSceneLoadProgress, function(nProcess)
        if nProcess >= 100 then
            Event.UnReg(self, EventType.OnMiniSceneLoadProgress)
            -- 开启镜头光
            ExteriorCharacter.OpenCameraLight("CoinShop_View", "CoinShop")
        end
    end)

    Event.Reg(self, EventType.OnBlackMaskEnterFinish, function ()
        self:UpdateActiveOpenBanner()
    end)

    Event.Reg(self, EventType.OnCoinShopCustomPendantOpenClose, function (bOpen)
        UIHelper.SetVisible(self.WidgetPreviewContainer, not bOpen)
        UIHelper.SetVisible(self.LayoutBotton, not bOpen)
        UIHelper.SetVisible(self.WidgetAnchorRightLine, not bOpen)
        if bOpen then
            ExteriorCharacter.SetCameraMode("CustomPendant")
            ExteriorCharacter.ScaleToCamera("Max")
        elseif self.curView == self.wardrobeView then
            ExteriorCharacter.SetCameraMode("Wardrobe")
            ExteriorCharacter.ScaleToCamera("Max")
        end
    end)

    Event.Reg(self, EventType.OnCoinShopHairDyeCaseOpenClose, function (bOpen)
        UIHelper.SetVisible(self.WidgetPreviewContainer, not bOpen)
        UIHelper.SetVisible(self.LayoutBotton, not bOpen)
        UIHelper.SetVisible(self.WidgetAnchorRightLine, not bOpen)
    end)

    Event.Reg(self, EventType.OnCoinShopOpenRecommend, function(tExteriorList, szTitleName)
        if self.scriptRecommend and UIHelper.GetVisible(self.WidgetRecommend) then
            if tExteriorList and not table.is_empty(tExteriorList) then
                self.scriptRecommend:Open(tExteriorList, szTitleName)
            else
                self.scriptRecommend:ShowEmpty()
            end
        end
    end)

    Event.Reg(self, "COINSHOP_CLEAR_RECOMMEND", function()
        if not self.scriptRecommend or not UIHelper.GetVisible(self.WidgetRecommend) then
            return
        end
        self.scriptRecommend:ShowEmpty()
    end)

    Event.Reg(self, "COINSHOP_RESET_RECOMMEND_CACHE", function()
        if self.scriptRecommend then
            self.scriptRecommend.m_szExteriorKey = nil
        end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function (szName)
        if self.nCoinShopType == UI_COINSHOP_GENERAL.BUILD_FACE then
            UIHelper.PlayAni(self, self.AniAll, "AniRightLineToLeft")
        end
    end)

    Event.Reg(self, "ON_EXTERIOR_DYEING_ID_UPDATE", function(dwID, nDyeingID)
        local nIndex = Exterior_GetSubIndex(dwID)
        if ExteriorCharacter.IsSubPreview(dwID) then
            ExteriorCharacter.ResUpdate_Exterior(dwID, nIndex)
            FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
        end
    end)

    Event.Reg(self, "ON_EQUIP_HAIR_CUSTOM_DYEING_NOTIFY", function(dwPlayerID, dwHairID, nIndex)
        if dwPlayerID ~= UI_GetClientPlayerID() then
            return
        end

        -- local hPlayer       = GetClientPlayer()
        -- if not hPlayer then
        --     return
        -- end
        -- local tHairDyeingData = hPlayer.GetEquippedHairCustomDyeingData(dwHairID)
        -- ExteriorCharacter.SetHairDyeingData(dwHairID, tHairDyeingData)
        ExteriorCharacter.ResetHairDyeingData()
    end)

    Event.Reg(self, "ON_CHANGE_HAIR_CUSTOM_DYEING_NOTIFY", function(dwHairID, nIndex, nMethod)
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
        local szMsg = ""
        local nCode = HAIR_CUSTOM_DYEING_ERROR_CODE.SUCCESS

        if nMethod == HAIR_CUSTOM_DYEING_OPERATE_METHOD.REPLACE then
            -- local tHairDyeingData = hPlayer.GetEquippedHairCustomDyeingData(dwHairID)
            -- ExteriorCharacter.SetHairDyeingData(dwHairID, tHairDyeingData)
            ExteriorCharacter.ResetHairDyeingData()
            szMsg = g_tStrings.tHairDyeingReplaceNotify[nCode]
        elseif nMethod == HAIR_CUSTOM_DYEING_OPERATE_METHOD.DELETE then
            szMsg = g_tStrings.tHairDyeingDelNotify[nCode]
        end
        TipsHelper.ShowNormalTip(szMsg)
    end)

    Event.Reg(self, "SET_HAIR_DYEING_INDEX", function()
        ExteriorCharacter.SetHairDyeingIndex(arg0, arg1)
    end)

    Event.Reg(self, "SchoolActivityRedUpdate", function()
        self:RefreshSchoolTitleListRed()
    end)

    Event.Reg(self, "ON_UPDATE_REPRESENT_HIDE_FLAG_NOTIFY", function (dwPlayerID, nType)
        if dwPlayerID == UI_GetClientPlayerID() and nType == PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL then
            self:UpdateRoleCloak()
            self:UpdateHideCloakCheck()
        end
    end)

    Event.Reg(self, "COINSHOP_HIDE_CLOAK", function (bHide)
        self:HideCloak(bHide)
    end)

    Event.Reg(self, "KG3D_PLAY_ANIMAION_FINISHED", function ()
        self.bPlayingPreviewAni = false
    end)

    Event.Reg(self, EventType.OnCoinShopRecommendOpenClose, function(bOpen)
        if bOpen then
            if not UIHelper.GetVisible(self.WidgetRecommend) then
                self:OpenRecommendPanel()
            end
            if self.eLastRecommendGoodsType and self.dwLastRecommendGoodsID then
                self:OpenRecommendByGoods(self.eLastRecommendGoodsType, self.dwLastRecommendGoodsID)
            else

                -- 切页后根据当前预览数据刷新推荐面板
                self.eLastRecommendGoodsType = nil
                self.dwLastRecommendGoodsID = nil
                self:RefreshRecommendByCurrentTitle()
            end
        else
            self:CloseRecommendPanel()
        end
    end)

    Event.Reg(self, EventType.OnOpenShareStation, function (nDataType)
        self.buildFaceView = self.buildFaceView or UIHelper.AddPrefab(PREFAB_ID.WidgetCoinShopBuildFace, self.WidgetAnchorFace)
        self:OnSelectedBuildFace()

        if g_pClientPlayer then
            local nRoleType = g_pClientPlayer.nRoleType
            local nSuffix = self.buildFaceView.nCurSelectPageListIndex == 1 and 2 or 1
            UIMgr.OpenSingle(false, VIEW_ID.PanelShareStation, nDataType, nRoleType, nSuffix, false)
            Timer.Add(self, 0.3, function ()
                ExteriorCharacter.SetCameraMode("ShareStation")
                ExteriorCharacter.ScaleToCamera(nDataType == SHARE_DATA_TYPE.FACE and "Min" or "Max")
            end)
        end
    end)

    Event.Reg(self, EventType.OnCloseShareStation, function (nDataType)
        UIHelper.SetVisible(self.TogGroupLeftBotton, true)
        UIHelper.SetVisible(self.TogCloudFace, true)
        UIHelper.SetVisible(self.BtnRoleReset, true)
        UIHelper.LayoutDoLayout(self.WidgetAnchorRightLine)
        if self.buildFaceView and self.nCoinShopType == UI_COINSHOP_GENERAL.BUILD_FACE then
            UIHelper.PlayAni(self, self.AniAll, "AniRightLineToLeft")
            UIHelper.SetVisible(self.buildFaceView._rootNode, true)
        end

        UIMgr.Close(VIEW_ID.PanelShareStation)

        if nDataType == SHARE_DATA_TYPE.FACE or nDataType == SHARE_DATA_TYPE.BODY then
            UIHelper.SetSelected(self.TogDecorate, true)
        else
            UIHelper.SetSelected(self.TogNew, true)
        end
    end)

    Event.Reg(self, EventType.OnGetShareStationUploadConfig, function (nDataType)
        if self.tbWaitForUploadData and self.tbWaitForUploadData.nDataType == nDataType then
            local bIsLogin = self.tbWaitForUploadData.bIsLogin
            local nPhotoSizeType = self.tbWaitForUploadData.nPhotoSizeType
            Event.Dispatch(EventType.OnStartDoUploadShareData, bIsLogin, nDataType, nPhotoSizeType)
            self.tbWaitForUploadData = nil
        end
    end)

    Event.Reg(self, EventType.OnStartDoUploadShareData, function (bIsLogin, nDataType, nPhotoSizeType)
        local pPlayer = GetClientPlayer()
        if not pPlayer then
            return
        end

        local tConfig = ShareCodeData.GetAccountConfig(nDataType)
        if not tConfig then
            self.tbWaitForUploadData = {bIsLogin = bIsLogin, nDataType = nDataType, nPhotoSizeType = nPhotoSizeType}
            ShareCodeData.ApplyAccountConfig(bIsLogin, nDataType)
            return
        elseif tConfig.nCount >= tConfig.nUploadLimit then
            ShareCodeData.ShowUploadLimitMsg(nDataType, pPlayer.nRoleType)
            return
        end

        if nDataType == SHARE_DATA_TYPE.FACE then
            ExteriorCharacter.SetCameraMode("ShareStation_Face")
            ExteriorCharacter.ScaleToCamera("Min")
        else
            ExteriorCharacter.SetCameraMode("ShareStation_Body")
            ExteriorCharacter.ScaleToCamera("Max")
        end
        UIHelper.SetVisible(self.AniAll, false)

        Timer.Add(self, 0.3, function ()
            local tPreviewData = {}
            if nDataType == SHARE_DATA_TYPE.FACE then
                tPreviewData = BuildFaceData.tNowFaceData
                --处理装了面部装饰物但隐藏的情况
               ShareExteriorData.SyncUploadFaceDecoration(tPreviewData)
            elseif nDataType == SHARE_DATA_TYPE.BODY then
                tPreviewData = BuildBodyData.tNowBodyData
            elseif nDataType == SHARE_DATA_TYPE.EXTERIOR then
                tPreviewData = self:GetViewExteriorData()
            end

            ShareStationData.DoUploadByType(nDataType, nPhotoSizeType, tPreviewData, {}, function ()
                UIHelper.SetVisible(self.AniAll, true)
                if self.nCoinShopType == UI_COINSHOP_GENERAL.BUILD_FACE then
                    ExteriorCharacter.SetCameraMode("BuildFace")
                    ExteriorCharacter.ScaleToCamera("BuildFaceMin")
                elseif self.nCoinShopType == UI_COINSHOP_GENERAL.MY_ROLE then
                    ExteriorCharacter.SetCameraMode("Wardrobe")
                    ExteriorCharacter.ScaleToCamera("Max")
                end
            end)
        end)
    end)

    Event.Reg(self, EventType.OnStartDoUpdateShareData, function (bIsLogin, nDataType, tbData)
        if nDataType == SHARE_DATA_TYPE.FACE then
            ExteriorCharacter.SetCameraMode("ShareStation_Face")
            ExteriorCharacter.ScaleToCamera("Min")
        else
            ExteriorCharacter.SetCameraMode("ShareStation_Body")
            ExteriorCharacter.ScaleToCamera("Max")
        end
        UIMgr.HideView(VIEW_ID.PanelShareStation)
        UIHelper.SetVisible(self.AniAll, false)

        Timer.Add(self, 0.3, function ()
            ShareStationData.DoUploadByType(nDataType, nil, nil, tbData, function ()
                if not ShareStationData.bOpening then
                    UIHelper.SetVisible(self.AniAll, true)
                else
                    UIMgr.ShowView(VIEW_ID.PanelShareStation)
                end
                if self.nCoinShopType == UI_COINSHOP_GENERAL.BUILD_FACE then
                    ExteriorCharacter.SetCameraMode("BuildFace")
                    ExteriorCharacter.ScaleToCamera("BuildFaceMin")
                elseif self.nCoinShopType == UI_COINSHOP_GENERAL.MY_ROLE then
                    ExteriorCharacter.SetCameraMode("Wardrobe")
                    ExteriorCharacter.ScaleToCamera("Max")
                end
            end)
        end)
    end)

    Event.Reg(self, EventType.OnKeyboardDown, function(nKeyCode, szKey)
        if nKeyCode == cc.KeyCode.KEY_ESCAPE then
            local nTopViewID = UIMgr.GetLayerTopViewID(UILayer.Page, {VIEW_ID.PanelTeach_UIPageLayer})
            local bPlayingFadeInVideo = UIMgr.IsViewOpened(VIEW_ID.PanelExteriorFadeInVideo, true)
            if not UIMgr.IsOpening() and not bPlayingFadeInVideo and nTopViewID == VIEW_ID.PanelExteriorMain then
                if self.nOpenLinkTimer then
                    Timer.DelTimer(self, self.nOpenLinkTimer)
                    self.nOpenLinkTimer = nil
                end
                UIMgr.Close(self)
            end
        end
    end)

    Event.Reg(self, "ON_EFFECT_CHANGED", function ()
        -- self:UpdateEffectTogType()
    end)

    -- Event.Reg(self, EventType.OnCoinShopSetEffectTogSelected, function(bSelected)
    --     UIHelper.SetVisible(self.TogSpecialEffect, bSelected)
    --     UIHelper.LayoutDoLayout(self.WidgetAnchorRightLine)
    --     UIHelper.SetSelected(self.TogSpecialEffect, bSelected)
    -- end)
end

function UICoinShopMainView:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopMainView:UpdateInfo()
    UIHelper.SetTouchDownHideTips(self.TogTaozhuang, false)
    UIHelper.SetTouchDownHideTips(self.BtnIntegral, false)
    UIHelper.SetTouchDownHideTips(self.TogCoupon, false)
    UIHelper.SetTouchDownHideTips(self.BtnDeal, false)

    ExteriorCharacter.SetRepresentReplace(true)
    self:UpdatePreview()
    self:UpdateLottery()
    UIHelper.SetVisible(self.BtnNew, true)

    local tbList = CoinShopData.GetHomeList()
    local nTime = GetGSCurrentTime()
    local bHasNew = #tbList > 0 and CoinShopData.IsStartTimeOK(tbList[1].nStartTime, nTime) and not Config.bIsCEVer and not AppReviewMgr.IsReview()
    UIHelper.SetVisible(self.TogNew, bHasNew)
    UIHelper.SetVisible(self.ImgLine01, bHasNew)
    UIHelper.LayoutDoLayout(self.TogGroupLeftBotton)

    Timer.AddFrame(self, 1, function ()
        if not self.fnOpenLink then
            if bHasNew then
                self:OnSelectedHome()
            else
                self:OnSelectedShop()
            end
        else
            self.nOpenLinkTimer = Timer.AddFrame(self, 3, function()
                self.fnOpenLink()
                self.nOpenLinkTimer = nil
            end)
        end
    end)
end

function UICoinShopMainView:UpdateTitleList(tbList)
    CoinShop_UpdateNoticeTitleMap()
    local bShop = self.nCoinShopType == UI_COINSHOP_GENERAL.SHOP
    local tData = {}
    local script = UIHelper.GetBindScript(self.WidgetShoppingLeft)
    local fnContainerSelectedCallback = function (bSelected, scriptContainer)
        if not bSelected then
            self:UpdateLeftTreeNode(scriptContainer, scriptContainer.tArgs, false)
            return
        end
        if scriptContainer.tArgs.bOutfit then
            self:OnSelectTitle(nil, nil, nil, true)
        else
            if not self.bInLinkTitle then
                local tItemArgs = scriptContainer.tItemList[1].tArgs
                self:LinkTitle(self.nCoinShopType == UI_COINSHOP_GENERAL.SHOP,  tItemArgs.nType, tItemArgs.nRewardsClass, tItemArgs.nSubClass, nil, true)
            end
        end

        self:UpdateLeftTreeNode(scriptContainer, scriptContainer.tArgs, true)
    end
    local fnItemSelectedCallback = function (tArgs)
        self:OnSelectTitle(tArgs.nType, tArgs.nRewardsClass, tArgs.nSubClass)
    end
    local nTime = GetGSCurrentTime()
    for _, tbClass in ipairs(tbList) do
        if tbClass.bOutfit or CoinShopData.IsStartTimeOK(tbClass.nStartTime, nTime) then
            local tContainerData = {}
            local szTitleName
            if tbClass.bOutfit then
                szTitleName = g_tStrings.COINSHOP_OUTFIT_TITLE
            elseif tbClass.bRewardsTab then
                szTitleName = UIHelper.GBKToUTF8(tbClass.szName)
            else
                szTitleName = UIHelper.GBKToUTF8(tbClass.szTitleName)
            end
            -- 标题标签
            local nClassLabel = bShop and CoinShopData.IsShowTitleLabel(tbClass) and tbClass.nLabel or 0
            local tItemList = {}
            if tbClass.tList and #tbClass.tList > 0 then
                local nPassLabel = 0
                for _, tbTitle in ipairs(tbClass.tList) do
                    if not tbTitle.nStartTime or CoinShopData.IsStartTimeOK(tbTitle.nStartTime, nTime) then
                        local nTitleLabel = 0
                        if tbClass.bRewardsTab then
                            nTitleLabel = bShop and tbTitle.nLabel or 0
                        else
                            nTitleLabel = bShop and CoinShopData.IsShowTitleLabel(tbTitle) and tbTitle.nLabel or 0
                        end
                        local tArgs = {
                            nTitleClass = tbTitle.nTitleClass,
                            nTitleSub = tbTitle.nTitleSub,
                            szName = tbTitle.szName,
                            nType = tbTitle.nType,
                            nRewardsClass = tbTitle.nRewardsClass,
                            nSubClass = tbTitle.nSubClass,
                            nLabel = nTitleLabel,
                            fnSelectedCallback = fnItemSelectedCallback,
                            bDisable = tbTitle.bDisable,
                            bShop = bShop,
                        }
                        table.insert(tItemList, { tArgs = tArgs })
                        if nTitleLabel == EXTERIOR_LABEL.DISCOUNT then
                            nPassLabel = EXTERIOR_LABEL.DISCOUNT
                        elseif nTitleLabel == EXTERIOR_LABEL.TIME_LIMIT and nPassLabel ~= EXTERIOR_LABEL.DISCOUNT then
                            nPassLabel = EXTERIOR_LABEL.TIME_LIMIT
                        elseif nTitleLabel == EXTERIOR_LABEL.NEW and nPassLabel ~= EXTERIOR_LABEL.DISCOUNT and nPassLabel ~= EXTERIOR_LABEL.TIME_LIMIT then
                            nPassLabel = EXTERIOR_LABEL.NEW
                        end
                    end
                end
                if nClassLabel == 0 then
                    nClassLabel = nPassLabel
                end
            end
            tContainerData.tArgs = {
                nTitleClass = tbClass.nTitleClass,
                nTitleSub = tbClass.nTitleSub,
                szName = szTitleName,
                nType = tbClass.nType,
                nRewardsClass = tbClass.nRewardsClass,
                bOutfit = tbClass.bOutfit,
                nLabel = nClassLabel,
                bDisable = tbClass.bDisable,
                bShop = bShop,
                tItemList = tItemList,
            }
            tContainerData.tItemList = tItemList
            tContainerData.fnSelectedCallback = fnContainerSelectedCallback
            table.insert(tData, tContainerData)
        end
    end
    local fnInitContainer = function (scriptContainer, tArgs, bIsSelected)
        UIHelper.SetCanSelect(scriptContainer.ToggleSelect, not tArgs.bDisable, g_tStrings.COINSHOP_HAIRSHOP_CAN_NOT_CHANGE)
        self:UpdateLeftTreeNode(scriptContainer, tArgs, bIsSelected)
    end
    script:ClearContainer()
    script:SetOuterInitSelect(true)
    script:SetScrollViewMovedCallback(function(eventType)
        if eventType == ccui.ScrollviewEventType.containerMoved then
            self:UpdateTitleListRedPointArrow()
        end
    end)
    UIHelper.SetupScrollViewTree(script, PREFAB_ID.WidgetShoppingTabList, PREFAB_ID.WidgetSecondNav, fnInitContainer, tData, true)
end

function UICoinShopMainView:OnSelectTitle(nType, nClass, nSubClass, bOutfit)
    local tbTitle
    if bOutfit then
        tbTitle = { bOutfit = true }
    else
        tbTitle = CoinShop_GetTitleInfo(nType, nClass)
    end

    if self.curView and self.curView.UpdateGoodList then
        self.curView:UpdateGoodList(tbTitle, nSubClass, self.bInLinkGoods)
    end

    -- 切页后根据当前预览数据刷新推荐面板
    self.eLastRecommendGoodsType = nil
    self.dwLastRecommendGoodsID = nil
    self:RefreshRecommendByCurrentTitle()
end

function UICoinShopMainView:UpdateCurreny()
    -- local nRewards = CoinShopData.GetRewards()
    -- self.RewardsScript:SetLableCount(nRewards)

    -- local tbCurrentVoucher = CoinShopData.GetCurrentCoinShopVoucher()
    -- local nCurrentVoucher = tbCurrentVoucher and tbCurrentVoucher.nCount or 0
    -- if nCurrentVoucher > 0 and not self.VoucherScript then
    --     self.VoucherScript = UIMgr.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.LayoutTongBao)
    --     self.VoucherScript:SetCurrencyType(CurrencyType.CoinShopVoucher)
    -- end
    -- if self.VoucherScript then
    --     self.VoucherScript:SetLableCount(nCurrentVoucher)
    --     UIHelper.SetVisible(self.VoucherScript._rootNode, nCurrentVoucher > 0)
    -- end

    UIHelper.LayoutDoLayout(self.LayoutTongBao)
    UIHelper.LayoutDoLayout(self.LayoutRightTop)
end

function UICoinShopMainView:RegisterView()
    ExteriorCharacter.InitView()
    BuildFaceData.UnInit()
    BuildBodyData.UnInit()

    local player = PlayerData.GetClientPlayer()
    if player then
        local nRoleType = player.nRoleType
        local playerKungFuID = player.GetActualKungfuMountID()
        BuildFaceData.Init({
            nRoleType = nRoleType,
            bPrice = true,
            nMaxDecalCount = 24,
            nMaxDefaultCount = 15,
            nMaxBoneDefaultCount = 24,
        })

        BuildHairData.Init({
            nRoleType = nRoleType,
            nKungfuID = playerKungFuID,
            bPrice = true,
        })

        BuildBodyData.Init({
            nRoleType = nRoleType,
            bPrice = true,
            aRepresent = {},
        })
    end
end

function UICoinShopMainView:UnRegisterView()
    ExteriorCharacter.UnRegisterExteriorCharacter("CoinShop_View", "CoinShop")
    UnRegisterNpcModel("CoinShop_View", "CoinShop")
    UnRegisterRidesModel("CoinShop_View", "CoinShop")
    UnRegisterFurnitureModel("CoinShop_View", "CoinShop")
end

function UICoinShopMainView:DoLayoutMiniScene(MiniSceneNode, LayoutNode)
    local width, height = UIHelper.GetContentSize(LayoutNode)
    UIHelper.SetContentSize(MiniSceneNode, width, height)

    local x, y = UIHelper.GetPosition(LayoutNode)
    UIHelper.SetPosition(MiniSceneNode, x, y)
end

function UICoinShopMainView:UpdateRole()
    local szDefaultAni = CharacterIdleActionData.GetDefaultAni(PLAYER_IDLE_ACTION_DISPLAY_TYPE.COIN_SHOP)
    local nLogicAniID = ExteriorCharacter.GetPreviewAniID()
    local nActionRepresentID = GetActionRepresentID(nLogicAniID)
    local bShowWeapon = ExteriorCharacter.IsWeaponShow()
    if bShowWeapon then
        szDefaultAni = nil
        nActionRepresentID = nil
    end
    if ExteriorCharacter.OnPreviewAni() then
        if szDefaultAni and nActionRepresentID then
            FireUIEvent("EXTERIOR_CHARACTER_PLAY_LOGIC_ANI", "CoinShop_View", "CoinShop",  nActionRepresentID, szDefaultAni)
        end
        return
    end

    local tRepresentID = clone(ExteriorCharacter.GetRoleRes())
    DealWithDecorationShowFlag(tRepresentID.tFaceData)
    self:UpdateDownloadEquipRes(tRepresentID)

    ExteriorCharacter.SetViewPage("Role")
    self.bPlayingPreviewAni = false

    if not bShowWeapon then
        tRepresentID[EQUIPMENT_REPRESENT.WEAPON_STYLE] = 0
        tRepresentID[EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] = 0
    end
    tRepresentID.tCustomRepresentData = self:GetRoleCustomPendant(tRepresentID)
    tRepresentID.tEffect = ExteriorCharacter.SetAllPreviewEffectCustomPos()
    local bIngoreReplace = not ExteriorCharacter.GetRepresentReplace()
    FireUIEvent("EXTERIOR_CHARACTER_UPDATE", "CoinShop_View", "CoinShop", tRepresentID, bIngoreReplace, nActionRepresentID, szDefaultAni)
    CoinShopPreview.RecordPreviewPakResource(g_pClientPlayer.nRoleType, tRepresentID)
end

function UICoinShopMainView:GetRoleCustomPendant(tRepresentID)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tCustomRepresentData = {}
    local tType = GetAllCustomPendantType()
    local scriptCustomPendant = UIHelper.GetBindScript(self.WidgetDIYDecoration)
    for nIndex, v in pairs(tType) do
        if tRepresentID[nIndex] ~= 0 then
            local tData = scriptCustomPendant:GetData(nIndex)
            if not tData then
                local nRepresentID = tRepresentID[nIndex]
                tData = CoinShopData.GetLocalCustomPendantData(nIndex, nRepresentID)
            end
            tCustomRepresentData[nIndex] = tData
        end
    end
    return tCustomRepresentData
end

-- function UICoinShopMainView:RegisterModelView()
--     ModelHelper.SetViewer3DModel(self.ItemMiniScene, g_pClientPlayer.nRoleType)
--     ModelHelper.SetViewer3DModel(self.WardrobeMiniScene, g_pClientPlayer.nRoleType)
-- end

function UICoinShopMainView:OnSelectedHome(tTitleParams)
    self:CloseRecommendPanel()
    self:SetActivityButton(true)
    self:UpdateCouponShow(true)
    UIHelper.SetString(self.LabelTitle, "外观商城")
    if self.nCoinShopType == UI_COINSHOP_GENERAL.BUILD_FACE then
        UIHelper.PlayAni(self, self.AniAll, "AniRightLineToRight")
    end
    self.nCoinShopType = UI_COINSHOP_GENERAL.SHOP
    self.curView = self.homeView
    self:OnRoleViewDataUpdate()
    ExteriorCharacter.SetCameraMode("New")
    ExteriorCharacter.ScaleToCamera("Max")

    UIHelper.SetVisible(self.WidgetAnchorExteriorContent, false)
    UIHelper.SetVisible(self.WidgetAnchorWardrobeContent, false)
    UIHelper.SetVisible(self.WidgetAnchorNewContent, true)
    UIHelper.SetVisible(self.WidgetAnchorHair, false)
    UIHelper.SetVisible(self.ImgBuyingPriceBg, false)
    UIHelper.SetVisible(self.WidgetNewLeft, true)
    UIHelper.SetVisible(self.WidgetShoppingLeft, false)
    UIHelper.SetVisible(self.TogEmotion, false)
    UIHelper.SetVisible(self.TogCloudFace, false)
    UIHelper.SetVisible(self.TogCloudBody, false)
    UIHelper.SetVisible(self.BtnUploadDressup, true)
    UIHelper.SetSelected(self.TogNew, true, false)
    UIHelper.SetSelected(self.TogActivity, false, false)
    UIHelper.SetSelected(self.TogShopping, false, false)
    UIHelper.SetSelected(self.TogWardrobe, false, false)
    UIHelper.SetVisible(self.TogEye, true)
    UIHelper.LayoutDoLayout(self.LayoutMenu)

    local tbList = CoinShopData.GetHomeList()
    local nTime = GetGSCurrentTime()
    self.tbHomeTitleList = {}
    if #tbList > 0 and CoinShopData.IsStartTimeOK(tbList[1].nStartTime, nTime) then
        for _, tbTitle in ipairs(tbList[1].tList) do
            if CoinShopData.IsStartTimeOK(tbTitle.nStartTime, nTime) then
                table.insert(self.tbHomeTitleList, tbTitle)
            end
        end
        if bOpenSchoolSplit then
            table.insert(self.tbHomeTitleList, {
                szName = UIHelper.UTF8ToGBK("活动"),
                nType = 3,
                nRewardsClass = 6
            })
        end
    end
    for i, toggle in ipairs(self.tbTogNewTab) do
        if i <= #self.tbHomeTitleList then
            local szName = UIHelper.GetUtf8SubString(UIHelper.GBKToUTF8(self.tbHomeTitleList[i].szName), 1, 2)
            UIHelper.SetString(self.tbLabelNewUsual[i], szName)
            UIHelper.SetString(self.tbLabelNewUp[i], szName)
            UIHelper.SetVisible(toggle, true)
        else
            UIHelper.SetVisible(toggle, false)
        end
    end

    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.tbTogNewTab[1]))

    FireUIEvent("RESET_ACTION")

    local bFound = false
    tTitleParams = tTitleParams or self.tHomeCacheTitleParams
    if tTitleParams then
        bFound = self:LinkTitle(true, tTitleParams.nType, tTitleParams.nClass, tTitleParams.nSubClass, tTitleParams.bOutfit)
    end
    if #self.tbHomeTitleList > 0 and not bFound then
        if SHOW_LIMIT_TIME_FIRST then
            for _, tTitle in ipairs(self.tbHomeTitleList) do
                if tTitle.nType == 6 and tTitle.nRewardsClass == 1 then
                    bFound = self:LinkTitle(true, tTitle.nType, tTitle.nRewardsClass)
                    break
                end
            end
        end
        if not bFound then
            self:LinkTitle(true, self.tbHomeTitleList[1].nType, self.tbHomeTitleList[1].nRewardsClass)
        end
    end
end

function UICoinShopMainView:OnSelectedShop(tTitleParams)
    self:CloseRecommendPanel()
    self:SetActivityButton(true)
    self:UpdateCouponShow(true)
    UIHelper.SetString(self.LabelTitle, "外观商城")
    if self.nCoinShopType == UI_COINSHOP_GENERAL.BUILD_FACE then
        UIHelper.PlayAni(self, self.AniAll, "AniRightLineToRight")
    end
    self.nCoinShopType = UI_COINSHOP_GENERAL.SHOP
    self.curView = self.shopView
    self:OnRoleViewDataUpdate()
    ExteriorCharacter.SetCameraMode("Normal")
    -- ExteriorCharacter.ScaleToCamera("Max")

    UIHelper.SetVisible(self.WidgetAnchorExteriorContent, true)
    UIHelper.SetVisible(self.WidgetAnchorWardrobeContent, false)
    UIHelper.SetVisible(self.WidgetAnchorNewContent, false)
    UIHelper.SetVisible(self.WidgetAnchorHair, false)
    UIHelper.SetVisible(self.ImgBuyingPriceBg, false)
    UIHelper.SetVisible(self.WidgetNewLeft, false)
    UIHelper.SetVisible(self.WidgetShoppingLeft, true)
    UIHelper.SetVisible(self.TogEmotion, false)
    UIHelper.SetVisible(self.TogCloudFace, false)
    UIHelper.SetVisible(self.TogCloudBody, false)
    UIHelper.SetVisible(self.BtnUploadDressup, true)
    UIHelper.SetSelected(self.TogNew, false, false)
    UIHelper.SetSelected(self.TogActivity, false, false)
    UIHelper.SetSelected(self.TogShopping, true, false)
    UIHelper.SetSelected(self.TogWardrobe, false, false)
    UIHelper.SetVisible(self.TogEye, true)
    UIHelper.LayoutDoLayout(self.LayoutMenu)

    local tbList = CoinShopData.GetList()
    if #tbList > 0 then
        local tbFirst = tbList[1]
        if UIHelper.GBKToUTF8(tbFirst.szTitleName) == "免费领校服" then
            table.remove(tbList, 1)
        end
    end
    self:UpdateTitleList(tbList)

    FireUIEvent("RESET_ACTION")

    local bFound = false
    tTitleParams = tTitleParams or self.tShopCacheTitleParams
    if tTitleParams then
        bFound = self:LinkTitle(true, tTitleParams.nType, tTitleParams.nClass, tTitleParams.nSubClass, tTitleParams.bOutfit)
    end
    if #tbList > 0 and not bFound then
        local tbFirst = tbList[1]
        if tbFirst.tList and #tbFirst.tList > 0 then
            local tbFirstSub = tbFirst.tList[1]
            self:LinkTitle(true, tbFirstSub.nType, tbFirstSub.nRewardsClass)
        end
    end
end

function UICoinShopMainView:OnSelectedWardrobe(tTitleParams)
    self:CloseRecommendPanel()
    self:SetActivityButton(true)
    self:UpdateCouponShow(true)
    UIHelper.SetString(self.LabelTitle, "我的外观")
    if self.nCoinShopType == UI_COINSHOP_GENERAL.BUILD_FACE then
        UIHelper.PlayAni(self, self.AniAll, "AniRightLineToRight")
    end
    self.nCoinShopType = UI_COINSHOP_GENERAL.MY_ROLE
    self.curView = self.wardrobeView
    self:OnRoleViewDataUpdate()
    ExteriorCharacter.SetCameraMode("Wardrobe")
    -- ExteriorCharacter.ScaleToCamera("Max")

    if not self.buildFaceView then
        self.buildFaceView = UIHelper.AddPrefab(PREFAB_ID.WidgetCoinShopBuildFace, self.WidgetAnchorFace)
        if g_pClientPlayer then
            local nRoleType = g_pClientPlayer.nRoleType
            local playerKungFuID = g_pClientPlayer.GetActualKungfuMountID()
            self.buildFaceView:OnEnter(nRoleType, playerKungFuID, true)
        end
    end

    UIHelper.SetVisible(self.WidgetAnchorWardrobeContent, true)
    UIHelper.SetVisible(self.WidgetAnchorExteriorContent, false)
    UIHelper.SetVisible(self.WidgetAnchorNewContent, false)
    UIHelper.SetVisible(self.WidgetAnchorHair, false)
    UIHelper.SetVisible(self.ImgBuyingPriceBg, false)
    UIHelper.SetVisible(self.WidgetNewLeft, false)
    UIHelper.SetVisible(self.WidgetShoppingLeft, true)
    UIHelper.SetVisible(self.TogEmotion, false)
    UIHelper.SetVisible(self.TogCloudFace, false)
    UIHelper.SetVisible(self.TogCloudBody, false)
    UIHelper.SetVisible(self.BtnFaceCodeCloud, false)
    UIHelper.SetVisible(self.BtnBodyCodeCloud, true)
    UIHelper.SetVisible(self.BtnUploadDressup, true)
    UIHelper.SetSelected(self.TogNew, false, false)
    UIHelper.SetSelected(self.TogActivity, false, false)
    UIHelper.SetSelected(self.TogShopping, false, false)
    UIHelper.SetSelected(self.TogWardrobe, true, false)
    UIHelper.LayoutDoLayout(self.LayoutFaceCodeMenu)
    UIHelper.LayoutDoLayout(self.LayoutBodyCodeMenu)
    UIHelper.LayoutDoLayout(self.WidgetAnchorRightLine)
    UIHelper.SetVisible(self.TogEye, true)
    UIHelper.LayoutDoLayout(self.LayoutMenu)

    local tbList = CoinShopData.GetMyRoleList()
    self:UpdateTitleList(tbList)

    FireUIEvent("RESET_ACTION")

    local bFound = false
    tTitleParams = tTitleParams or self.tWardrobeCacheTitleParams
    if tTitleParams then
        bFound = self:LinkTitle(false, tTitleParams.nType, tTitleParams.nClass, tTitleParams.nSubClass, tTitleParams.bOutfit)
    end
    if not bFound then
        self:LinkTitle(false, 3, 1)
    end
end

function UICoinShopMainView:OnSelectedBuildFace(tTitleParams)
    UIHelper.SetString(self.LabelTitle, "外观商城")
    if self.nCoinShopType ~= UI_COINSHOP_GENERAL.BUILD_FACE then
        UIHelper.PlayAni(self, self.AniAll, "AniRightLineToLeft")
    end
    self.nCoinShopType = UI_COINSHOP_GENERAL.BUILD_FACE
    self.buildFaceView = self.buildFaceView or UIHelper.AddPrefab(PREFAB_ID.WidgetCoinShopBuildFace, self.WidgetAnchorFace)
    self.curView = self.buildFaceView
    self:OnRoleViewDataUpdate()
    ExteriorCharacter.SetCameraMode("BuildFace")

    local nRoleType = g_pClientPlayer.nRoleType
    local playerKungFuID = g_pClientPlayer.GetActualKungfuMountID()

    UIHelper.SetVisible(self.TogEmotion, true)
    UIHelper.SetVisible(self.TogCloudFace, true)
    UIHelper.SetVisible(self.TogCloudBody, true)
    UIHelper.SetVisible(self.BtnFaceCodeCloud, false)
    UIHelper.SetVisible(self.BtnBodyCodeCloud, false)
    UIHelper.SetVisible(self.BtnUploadDressup, true)
    UIHelper.LayoutDoLayout(self.LayoutFaceCodeMenu)
    UIHelper.LayoutDoLayout(self.LayoutBodyCodeMenu)
    UIHelper.LayoutDoLayout(self.WidgetAnchorRightLine)
    UIHelper.SetVisible(self.TogEye, false)
    UIHelper.LayoutDoLayout(self.LayoutMenu)

    self.buildFaceView:OnEnter(nRoleType, playerKungFuID, true)
    self.buildFaceView:UpdateCameraState()
    FireUIEvent("RESET_ACTION")
end

function UICoinShopMainView:UpdateCurViewPageList()
    if self.curView and self.curView.UpdateCurPageList then
        self.curView:UpdateCurPageList()
    end
end

----------------------------跳转----------------------------
function UICoinShopMainView:LinkTitle(bShop, nType, nClass, nSubClass, bOutfit, bRelocate)
    local tTitleParams = {nType=nType, nClass=nClass, nSubClass=nSubClass, bOutfit=bOutfit}
    if bShop then
        if CoinShopData.IsHomeTitle(nType, nClass) or (nType == 3 and nClass == 6 and bOpenSchoolSplit) then
            -- 第二项为裂变活动特殊项
            if not UIHelper.GetVisible(self.TogNew) then
                return true
            end
            if self.curView ~= self.homeView then
                self:OnSelectedHome(tTitleParams)
                return true
            end
        else
            if self.curView ~= self.shopView then
                self:OnSelectedShop(tTitleParams)
                return true
            end
        end
    else
        if nType == 3 and nClass == 6 and bOpenSchoolSplit then
            self:OnSelectedActivity()
            return true
        elseif self.curView ~= self.wardrobeView then
            self:OnSelectedWardrobe(tTitleParams)
            return true
        end
    end

    local bFound = false
    self.bInLinkTitle = true
    if self.curView == self.homeView then
        for i, tInfo in ipairs(self.tbHomeTitleList) do
            if tInfo.nType == nType and tInfo.nRewardsClass == nClass then
                UIHelper.SetSelected(self.tbTogNewTab[i], true)
                bFound = true
            else
                UIHelper.SetSelected(self.tbTogNewTab[i], false)
            end
        end
    else
        local script = UIHelper.GetBindScript(self.WidgetShoppingLeft)
        for _, tContainer in ipairs(script.tContainerList) do
            local scriptContainer = tContainer.scriptContainer
            if bOutfit and scriptContainer.tArgs.bOutfit then
                scriptContainer:SetSelected(true)
                bFound = true
                self:UpdateLeftTreeNode(scriptContainer, scriptContainer.tArgs, true)
            else
                for i, tItem in ipairs(scriptContainer.tItemList) do
                    if tItem.tArgs.nType == nType and tItem.tArgs.nRewardsClass == nClass and (tItem.tArgs.nSubClass == nSubClass or not nSubClass) then
                        if not scriptContainer:GetSelected() then
                            scriptContainer:SetSelected(true)
                        end
                        local scriptItem = scriptContainer.tItemScripts[i]
                        scriptItem:SetSelected(true)
                        if not bRelocate then
                            Timer.Add(self, 0.35, function ()
                                CoinShopPreview.LocatePreviewItem(script.ScrollViewContent, scriptItem._rootNode)
                            end)
                        end
                        self:UpdateLeftTreeNode(scriptContainer, scriptContainer.tArgs, true)
                        bFound = true
                        break
                    end
                end
            end
        end
    end
    self.bInLinkTitle = false
    return bFound
end

function UICoinShopMainView:LinkTitleByID(bShop, nType, dwID)
    local nClass = 0
    local nSubClass
    if nType == COIN_SHOP_GOODS_TYPE.ITEM then
        local tInfo = Table_GetRewardsItem(dwID)
        nClass = tInfo.nClass
        if CoinShopData.IsRewardsTabTitle(nType, nClass) then
            nSubClass = tInfo.nSubClass
        end
    elseif nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
        local tExteriorInfo = GetExterior().GetExteriorInfo(dwID)
        local tSetInfo = Table_GetExteriorSet(tExteriorInfo.nSet)
        nClass = tSetInfo.nClass
    elseif nType == COIN_SHOP_GOODS_TYPE.HAIR then
        if bShop then
            nSubClass = 1
        end
    end
    self:LinkTitle(bShop, nType, nClass, nSubClass)
end

function UICoinShopMainView:OnLink(bShop, nHomeType, dwID)
    local tbLinkFun =
    {
        [HOME_TYPE.EXTERIOR] = self.LinkExterior,
        [HOME_TYPE.REWARDS] = self.LinkRewardsItem,
        [HOME_TYPE.EXTERIOR_WEAPON] = self.LinkWeapon,
    }
    self.bInLinkGoods = true
    if dwID then
        local eGoodsType = CoinShop_HomeTypeToGoods(nHomeType)
        self:LinkTitleByID(bShop, eGoodsType, dwID)
        tbLinkFun[nHomeType](self, dwID)
    end
    self.bInLinkGoods = false
end

function UICoinShopMainView:LinkExterior(dwID)
    if self.curView and self.curView.LinkExterior then
        self.curView:LinkExterior(dwID)
    end
end

function UICoinShopMainView:LinkRewardsItem(dwID)
    if self.curView and self.curView.LinkRewardsItem then
        self.curView:LinkRewardsItem(dwID)
    end
end

function UICoinShopMainView:LinkWeapon(dwID)
    if self.curView and self.curView.LinkWeapon then
        self.curView:LinkWeapon(dwID)
    end
end

function UICoinShopMainView:LinkExteriorSet(nSet)
    if self.curView and self.curView.LinkExteriorSet then
        self.curView:LinkExteriorSet(nSet)
    end
end

function UICoinShopMainView:LinkHair(dwID)
    if self.curView and self.curView.LinkExteriorSet then
        self.curView:LinkHair(dwID)
    end
end

function UICoinShopMainView:LinkSfx(nType, nSfxId)
    if self.curView and self.curView.LinkExteriorSet then
        self.curView:LinkSfx(nType, nSfxId)
    end
end

function UICoinShopMainView:LinkPendant(dwID, bOpenCustom)
    if self.curView and self.curView.LinkPendant then
        self.curView:LinkPendant(dwID, bOpenCustom)
    end
end

function UICoinShopMainView:OnSearchLink(bShop, tbInfo)
    if tbInfo[2] == "Pendant" then
        local nItemIndex, nColor1, nColor2, nColor3 = tbInfo[3], tbInfo[4], tbInfo[5], tbInfo[6]
        CoinShopData.LinkPendant(string.format("%d/%d/%d/%d", nItemIndex, nColor1, nColor2, nColor3), false)
        return
    end

    local tbLinkFun =
    {
        [HOME_TYPE.EXTERIOR] = self.OnSearchExterior,
        [HOME_TYPE.REWARDS] = self.OnSearchRewards,
        [HOME_TYPE.EXTERIOR_SET] = self.OnSearchExteriorSet,
        [HOME_TYPE.EXTERIOR_WEAPON] = self.OnSearchWeapon,
        [HOME_TYPE.HAIR] = self.OnSearchHair,
        [HOME_TYPE.EFFECT_SFX] = self.OnSearchSfx,
    }
    self.bInLinkGoods = true
    local nHomeType = tbInfo[2]
    local eGoodsType = CoinShop_HomeTypeToGoods(nHomeType)
    if nHomeType == HOME_TYPE.EXTERIOR_SET then
        local tLine = Table_GetExteriorSet(tbInfo[3])
        local nClass = tLine.nClass
        self:LinkTitle(bShop, eGoodsType, nClass)
    elseif nHomeType == HOME_TYPE.EFFECT_SFX then
        self:LinkTitle(bShop, eGoodsType, REWARDS_CLASS.EFFECT)
    else
        self:LinkTitleByID(bShop, eGoodsType, tbInfo[3])
    end
    tbLinkFun[nHomeType](self, tbInfo)
    self.bInLinkGoods = false
end

function UICoinShopMainView:OnSearchExterior(tbInfo)
    local dwID = tbInfo[3]
    self:LinkExterior(dwID)
end

function UICoinShopMainView:OnSearchRewards(tbInfo)
    self:LinkRewardsItem(tbInfo[3])
end

function UICoinShopMainView:OnSearchWeapon(tbInfo)
    self:LinkWeapon(tbInfo[3])
end

function UICoinShopMainView:OnSearchExteriorSet(tbInfo)
    local nSet =  tbInfo[3]
    self:LinkExteriorSet(nSet)
end

function UICoinShopMainView:OnSearchHair(tbInfo)
    local dwID = tbInfo[3]
    self:LinkHair(dwID)
end

function UICoinShopMainView:OnSearchSfx(tbInfo)
    local nType = tbInfo[3]
    local nSfxId = tbInfo[4]
    self:LinkSfx(nType, nSfxId)
end

----------------------------预览----------------------------
function UICoinShopMainView:SaveOutfit()
    local tbOutfit = ExteriorCharacter.GetCurrentOutfit()

    local bRepeat = CoinShop_OutfitCheckRepeat(tbOutfit) --只排重了本地的，没有判服务器的
    if bRepeat then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.COINSHOP_OUTFIT_SAVE_ERROR)
        return
    end

    if CoinShop_IsCountLimit() then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.COINSHOP_OUTFIT_SAVE_ERROR_COUNT_LIMIT)
        return
    end

    local fnInput = function (szName)
        if szName == "" then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.COINSHOP_OUTFIT_SAVE_NAME_ERROR1)
            return
        end
        -- local nPos = StringFindW(szName, " ")
        -- if nPos then
        --     OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.COINSHOP_OUTFIT_SAVE_NAME_ERROR2)
        --     return
        -- end
        if not TextFilterCheck(UIHelper.UTF8ToGBK(szName)) then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.COINSHOP_OUTFIT_SAVE_NAME_ERROR3)
            return
        end
        tbOutfit.szName = szName
        local bRepeat = CoinShop_OutfitNameRepeat(szName)
        if bRepeat then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.COINSHOP_OUTFIT_SAVE_NAME_ERROR)
            return
        end
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.COINSHOP_OUTFIT_SAVE_SUCCESS)
        CoinShop_SaveOutfitList(tbOutfit, true)
    end

    local editBox = UIMgr.Open(VIEW_ID.PanelPromptPop, "", g_tStrings.COINSHOP_OUTFIT_INPUT_NAME, function (szText)
        fnInput(szText)
    end)
    if editBox then
        editBox:SetPlaceHolder("")
        editBox:SetMaxLength(5)
        editBox:SetTitle("存为预设")
    end
end

function UICoinShopMainView:StartReplaceOutfit()
    local tbOutfit = ExteriorCharacter.GetCurrentOutfit()

    local bRepeat = CoinShop_OutfitCheckRepeat(tbOutfit) --只排重了本地的，没有判服务器的
    if bRepeat then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.COINSHOP_OUTFIT_REPLACE_ERROR)
        return
    end

    self:LinkTitle(false, nil, nil, nil, true)
    Event.Dispatch(EventType.OnCoinShopEnterReplaceOutfit)
end

function UICoinShopMainView:OnEnterReplaceOutfit()
    self.bReplaceOutfit = true
    self.tbSelectedReplaceOutfit = nil
    UIHelper.SetVisible(self.BtnBuy, false)
    UIHelper.SetVisible(self.BtnPreserve, false)
    UIHelper.SetVisible(self.BtnPresets, false)
    UIHelper.SetVisible(self.BtnReplace, true)
    UIHelper.SetButtonState(self.BtnReplace, BTN_STATE.Disable)
    UIHelper.SetVisible(self.BtnAbandon, true)
    UIHelper.LayoutDoLayout(self.LayoutBotton)
end

function UICoinShopMainView:OnCancelReplaceOutfit()
    self.bReplaceOutfit = false
    self.tbSelectedReplaceOutfit = nil
    self:UpdateViewData(self.m_szViewPage)
end

function UICoinShopMainView:ReplaceOutfit()
    if self.tbSelectedReplaceOutfit.bServer then
        self:StorageReplaceServer()
    else
        local tbOutfit = ExteriorCharacter.GetCurrentOutfit()
        local nIndex = self.tbSelectedReplaceOutfit.nLocalIndex
        local bRepeat = CoinShop_OutfitCheckRepeat(tbOutfit)
        if bRepeat then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.COINSHOP_OUTFIT_REPLACE_ERROR)
            return
        end

        CoinShop_ReplaceOutfitList(tbOutfit, nIndex, true)
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.COINSHOP_OUTFIT_REPLACE_SUCCESS)
    end
    Event.Dispatch(EventType.OnCoinShopCancelReplaceOutfit)
end

function UICoinShopMainView:StorageReplaceServer()
    local tOutfit = ExteriorCharacter.GetCurrentOutfit()
    local tReplaceOutfit = self.tbSelectedReplaceOutfit
    local tPreset, bUseLiftedFace = CoinShopData.DataToServer(tOutfit.tData)
    local nRetCode = g_pClientPlayer.ReplaceCoinShopPreset(tReplaceOutfit.dwIndex, UIHelper.UTF8ToGBK(tReplaceOutfit.szName), bUseLiftedFace, tReplaceOutfit.bHideHat, 0, tPreset)
    if nRetCode == COIN_SHOP_PRESET_ERROR_CODE.SUCCESS then
        FireUIEvent("REPLACE_OUTFIT_SUCCESS")
        return
    end

    if nRetCode then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tCoinShopPresetNotify[nRetCode])
        OutputMessage("MSG_SYS", g_tStrings.tCoinShopPresetNotify[nRetCode])
    end
end

function UICoinShopMainView:SaveRole()
    local tbBuySaveList = CoinShopPreview.GetBuySaveList()
    local bAllHave = CoinShopData.UpdateBuyItemState(tbBuySaveList, true)
    if not bAllHave then
        return
    end

	local bEnd = CoinShopData.DealBodySave()
	if bEnd then
		return
	end
	CoinShopData.DealFaceLift()
	CoinShopData.DecalOtherSave()
	CoinShopData.DecalHairDyeingIndex()

    local tbSave = {}
    for _, tBuyItem in ipairs(tbBuySaveList) do
        if not tBuyItem.bLiftedFace and not tBuyItem.bOtherSave and not tBuyItem.bBody and not tBuyItem.bNewFace then
			table.insert(tbSave, tBuyItem)
		end
    end
    if #tbSave > 0 then
        local nRetCode = GetCoinShopClient().Save(tbSave)
        if nRetCode == COIN_SHOP_ERROR_CODE.SUCCESS then
            for _, tbInfo in ipairs(tbSave) do
                if tbInfo.eGoodsType == 1 then
                    -- 发型需要隐藏帽子
                    self.bInitHideHat = true
                    PlayerData.HideHat(true)
                end
            end
            --应用本地的挂件自定义数据
            for _, tbItem in pairs(tbSave) do
                if tbItem.bHave and tbItem.dwTabType == ITEM_TABLE_TYPE.CUST_TRINKET then
                    local nType = Exterior_SubToRepresentSub(tbItem.nSubType)
                    if nType and IsCustomPendantType(nType) then
                        local hItemInfo = GetItemInfo(tbItem.dwTabType, tbItem.dwTabIndex)
                        if hItemInfo then
                            local nRepresentID = hItemInfo.nRepresentID
                            if tbItem.nSelectedPos then
						        nType = CoinShop_PendantTypeToRepresentSub(tbItem.nSelectedPos)
					        end
                            CoinShopData.CustomPendantSetLocalDataToPlayer(nType, nRepresentID)
                        end
                    end
                end
            end
            OutputMessage("MSG_SYS", g_tStrings.tCoinShopSaveNotify[nRetCode])
        elseif nRetCode == COIN_SHOP_ERROR_CODE.NOT_HAVE_PREORDER_COUPON then
            OnPerorderError(tbSave)
        else
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tCoinShopSaveNotify[nRetCode])
            OutputMessage("MSG_SYS", g_tStrings.tCoinShopSaveNotify[nRetCode])
        end
    end

    self:InitHideShowData()
end

function UICoinShopMainView:OnRoleViewDataUpdate()
    if self.m_szViewPage ~= "Role" then
        self:UnRegisterView()
    end

    local fnAction = function ()
        if self.m_szViewPage ~= "Role" then
            ExteriorCharacter.RegisterRole(self.MiniScene, self:GetScene())
            UIHelper.SetSelected(self.ToggleCamera, true, false)
        end
        self.m_szViewPage = "Role"
        ExteriorCharacter.SetViewPage("Role")
        self:UpdateRole()
        UIHelper.SetVisible(self.BtnBuy, self.nCoinShopType == UI_COINSHOP_GENERAL.SHOP)
        UIHelper.SetVisible(self.BtnPreserve, true)
        UIHelper.SetVisible(self.BtnPresets, self.nCoinShopType == UI_COINSHOP_GENERAL.MY_ROLE)
        UIHelper.SetVisible(self.BtnReplace, false)
        UIHelper.SetVisible(self.BtnAbandon, false)
        UIHelper.LayoutDoLayout(self.LayoutBotton)
        UIHelper.SetVisible(self.BtnRoleReset, true)
        UIHelper.SetVisible(self.TogMenu, true)
        UIHelper.SetVisible(self.LayoutFurnitureColor, false)
        -- self:UpdateEffectTogType()

        self:UpdateSetState()
        self:UpdateHideHairCheck()
        self:UpdateRoleViewBtnState()
        self:UpdatePreviewBtn()

        if self.nCoinShopType ~= UI_COINSHOP_GENERAL.MY_ROLE then
            local scriptCustomPendant = UIHelper.GetBindScript(self.WidgetDIYDecoration)
            scriptCustomPendant:Close()
        end

        if self.bReplaceOutfit then
            Event.Dispatch(EventType.OnCoinShopCancelReplaceOutfit)
        end
        if self.bExteriorChangeColor then
            Event.Dispatch(EventType.OnCoinShopCancelExteriorChangeColor)
        end
        if self.bExteriorChangeHair then
            Event.Dispatch(EventType.OnCoinShopCancelExteriorChangeHair)
        end

        local tbFrame = ExteriorCharacter.tResisterFrame["CoinShop_View"]["CoinShop"]
        local model = tbFrame.hModelView
        local camera = tbFrame.hCamera
        UITouchHelper.BindModel(self.TouchContainer, model, camera, {tbFrame = tbFrame, bIsExterior = true}, true)
        Timer.Add(self, 0.1, function ()
            UITouchHelper.SetYaw(model:GetYaw())
        end)
    end

    Timer.DelTimer(self, self.nModelUpdateTimerID)
    if not self.m_szViewPage then   -- 如果没有ViewPage则说明是首次打开界面
        self.nModelUpdateTimerID = Timer.AddFrame(self, 3, fnAction)
    elseif self.m_szViewPage == "Furniture" then
        self.nModelUpdateTimerID = Timer.Add(self, 0.5, fnAction)
    else
        fnAction()
    end
end

function UICoinShopMainView:StartBuildHairDye(dwID, tDyeingData)
    UIMgr.OpenSingle(false, VIEW_ID.PanelCoinShopBuildDyeing, dwID, tDyeingData)
end

function UICoinShopMainView:UpdateSetState()
    local bCanHideChest, bCanHideHair =  ExteriorCharacter.GetCanHideSubsetFlag()
    local bCanReplace = CoinShopData.GetCanReplace()
    UIHelper.SetVisible(self.TogTaozhuang, bCanHideChest or bCanHideHair or bCanReplace)
    -- local bReplace = ExteriorCharacter.GetRepresentReplace()
    -- UIHelper.SetSelected(self.TogTaozhuang, bReplace, false)
    UIHelper.SetString(self.LabelTaozhuang, "切换")
    UIHelper.LayoutDoLayout(self.WidgetAnchorRightLine)
end

function UICoinShopMainView:UpdateHideHairCheck()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    -- local bShow = self:IsShowHideHairCheck()
    -- UIHelper.SetSelected(self.TogHideHair, hPlayer.bHideHair, false)
    -- UIHelper.SetTouchEnabled(self.TogHideHair, bShow)
    -- UIHelper.SetNodeGray(self.TogHideHair, not bShow, true)
    UIHelper.SetVisible(self.TogHideHair, false)
    UIHelper.LayoutDoLayout(self.LayoutMenu)
end

function UICoinShopMainView:UpdateHideCloakCheck()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    UIHelper.SetSelected(self.TogCloak, not hPlayer.GetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL), false)
    UIHelper.LayoutDoLayout(self.LayoutMenu)
end

function UICoinShopMainView:IsShowHideHairCheck()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tRepresentID = ExteriorCharacter.GetRoleRes()
    local nRes = tRepresentID[EQUIPMENT_REPRESENT.HELM_STYLE]
    local nCount = Player_GetEquipStyleCount(hPlayer.nRoleType, "HAT", nRes)
    return nCount > 1
end

function UICoinShopMainView:UpdateRoleViewBtnState()
    local tbBuySaveList = CoinShopPreview.GetBuySaveList()
    local bAllHave = CoinShopData.UpdateBuyItemState(tbBuySaveList, true)  -- 根据nHaveType更精确判断是否“拥有”
    local nBuyCount = 0
    for _, tbItem in ipairs(tbBuySaveList) do
        if not tbItem.bHave then
            nBuyCount = nBuyCount + 1
        end
    end

    local bCanOutfit = CoinShopPreview.CanSaveOutfit()

    if nBuyCount > 0 and #tbBuySaveList > 0 then
        UIHelper.SetString(self.LabelBuy, "购买（" .. nBuyCount .."）")
        UIHelper.SetButtonState(self.BtnBuy, BTN_STATE.Normal)
    else
        UIHelper.SetString(self.LabelBuy, "购买")
        UIHelper.SetButtonState(self.BtnBuy, BTN_STATE.Disable)
    end

    local bSaveHideShow = self:CanSaveHideShowData()
    if nBuyCount == 0 and (#tbBuySaveList > 0 or bSaveHideShow) and bAllHave then
        UIHelper.SetButtonState(self.BtnPreserve, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnPreserve, BTN_STATE.Disable)
    end

    if bCanOutfit and bAllHave then
        UIHelper.SetButtonState(self.BtnPresets, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnPresets, BTN_STATE.Disable)
    end
    UIHelper.SetButtonState(self.BtnUploadDressup, bAllHave and BTN_STATE.Normal or BTN_STATE.Disable, g_tStrings.STR_SHARE_STATION_EXPORT_EXTERIOR_DISABLE)
end

function UICoinShopMainView:InitHideShowData()
    self.bInitHideHat = g_pClientPlayer.bHideHat
    self.bInitHideFacePendent = g_pClientPlayer.bHideFacePendent
    self.bInitDecorationShow = GetFaceLiftManager().GetDecorationShowFlag()
    self.bInitHideHair = g_pClientPlayer.bHideHair
    self.bInitHideCloak = g_pClientPlayer.GetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL)
end

function UICoinShopMainView:CanSaveHideShowData()
     local bSave = false
     bSave = bSave or g_pClientPlayer.bHideHat ~= self.bInitHideHat
     bSave = bSave or g_pClientPlayer.bHideFacePendent ~= self.bInitHideFacePendent
     bSave = bSave or GetFaceLiftManager().GetDecorationShowFlag() ~= self.bInitDecorationShow
     bSave = bSave or g_pClientPlayer.bHideHair ~= self.bInitHideHair
     return bSave
end

function UICoinShopMainView:ResetByHideShowData()
    PlayerData.HideHat(self.bInitHideHat)
    g_pClientPlayer.SetFacePendentHideFlag(self.bInitHideFacePendent)
    GetFaceLiftManager().SetDecorationShowFlag(self.bInitDecorationShow)
    g_pClientPlayer.HideHair(self.bInitHideHair)
    g_pClientPlayer.SetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL, self.bInitHideCloak)
end

function UICoinShopMainView:HideHat(bHideHat)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    if bHideHat == hPlayer.bHideHat then
        return
    end
    PlayerData.HideHat(bHideHat)
    FireUIEvent("PLAYER_HIDE_HAT_CHANGE")
    UIHelper.SetSelected(self.TogHat, not hPlayer.bHideHat, false)
    self:UpdateRoleHat()
    self:UpdateHideHairCheck()
end

function UICoinShopMainView:UpdateRoleHat()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hExteriorClient = GetExterior()
    if not hExteriorClient then
        return
    end

    local tRepresentID = ExteriorCharacter.GetRoleRes()
    if not tRepresentID then
        return
    end

    local bHide = hPlayer.bHideHat
    if bHide then
        tRepresentID[EQUIPMENT_REPRESENT.HELM_STYLE] = 0
        tRepresentID[EQUIPMENT_REPRESENT.HELM_COLOR] = 0
        tRepresentID[EQUIPMENT_REPRESENT.HEAD_DYEING] = 0
    else
        local nIndex = Exterior_RepresentToBoxIndex(EQUIPMENT_REPRESENT.HELM_STYLE)
        local tRoleData = ExteriorCharacter.GetRoleData()
        local dwExteriorID = tRoleData[nIndex] and tRoleData[nIndex].dwID
        local nEquipSub = Exterior_RepresentSubToEquipSub(EQUIPMENT_REPRESENT.HELM_STYLE)
        local hItem = PlayerData.GetPlayerItem(hPlayer, INVENTORY_INDEX.EQUIP, nEquipSub)
        if dwExteriorID and dwExteriorID > 0 then
            local tExteriorInfo = hExteriorClient.GetExteriorInfo(dwExteriorID)
            tRepresentID[EQUIPMENT_REPRESENT.HELM_STYLE] = tExteriorInfo.nRepresentID
            tRepresentID[EQUIPMENT_REPRESENT.HELM_COLOR] = tExteriorInfo.nColorID
            tRepresentID[EQUIPMENT_REPRESENT.HEAD_DYEING] = hPlayer.GetExteriorDyeingID(dwExteriorID)

        elseif hItem then
            tRepresentID[EQUIPMENT_REPRESENT.HELM_STYLE] = hItem.nRepresentID
            tRepresentID[EQUIPMENT_REPRESENT.HELM_COLOR] = hItem.nColorID
            tRepresentID[EQUIPMENT_REPRESENT.HEAD_DYEING] = 0
        end
    end
    FireUIEvent("COINSHOP_UPDATE_ROLE")
end

function OnPreviewPendant(hFrame, dwID)
    if dwID and dwID > 0 then
        local tExteriorInfo = GetExterior().GetExteriorInfo(dwID)
        if tExteriorInfo.nSubType == EQUIPMENT_SUB.HELM and not CoinShopView.IsInitRole()
        then
            self:HideHat(false)
        end
    end
end

function UICoinShopMainView:HideCloak(bHide)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    hPlayer.SetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL, bHide)
end

function UICoinShopMainView:UpdateRoleCloak()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hExteriorClient = GetExterior()
    if not hExteriorClient then
        return
    end

    local tRepresentID = ExteriorCharacter.GetRoleRes()
    if not tRepresentID then
        return
    end

    local bHide = hPlayer.GetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL)
    tRepresentID.bHideBackCloakModel = bHide
    -- if bHide then
    --     tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND] = 0
    --     tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR1] = 0
    --     tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR2] = 0
    --     tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR3] = 0
    -- else
        local nIndex = Exterior_RepresentToBoxIndex(EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND)
        local tRoleData = ExteriorCharacter.GetRoleData()
        local tData = tRoleData[nIndex]
        if tData and tData.tItem then
            local tItem = tData.tItem
            if tItem.nRepresentID then
                tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND] = tItem.nRepresentID
            end
            local tColorID = tItem.tColorID
            if tColorID then
                tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR1] = tColorID[1]
                tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR2] = tColorID[2]
                tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR3] = tColorID[3]
            end
        end
    --end
    FireUIEvent("COINSHOP_UPDATE_ROLE")
end

function UICoinShopMainView:OnRideViewDataUpdate()
    if self.m_szViewPage ~= "Ride" then
        self:UnRegisterView()
    end

    local fnAction = function()
        if self.m_szViewPage ~= "Ride" then
            ExteriorCharacter.RegisterRide(self.MiniScene, self:GetScene())
            UIHelper.SetSelected(self.ToggleCamera, true, false)
        end
        self.m_szViewPage = "Ride"
        ExteriorCharacter.SetViewPage("Ride")

        local tRepresentID = ExteriorCharacter.GetRoleRes()
        FireUIEvent("RIDES_MODEL_PREVIEW_UPDATE", "CoinShop_View", "CoinShop", tRepresentID, nil)

        UIHelper.SetVisible(self.WidgetDownloadBtnShell, false)
        UIHelper.SetVisible(self.BtnBuy, self.nCoinShopType == UI_COINSHOP_GENERAL.SHOP)
        UIHelper.SetVisible(self.BtnPreserve, false)
        UIHelper.SetVisible(self.BtnPresets, false)
        UIHelper.SetVisible(self.BtnReplace, false)
        UIHelper.SetVisible(self.BtnAbandon, false)
        UIHelper.LayoutDoLayout(self.LayoutBotton)
        UIHelper.SetVisible(self.BtnRoleReset, true)
        UIHelper.SetVisible(self.TogMenu, false)
        UIHelper.SetVisible(self.TogAnimationPreview, false)
        UIHelper.SetVisible(self.LayoutFurnitureColor, false)
        UIHelper.SetVisible(self.TogSpecialEffect, false)

        self:UpdateRideViewBtnState()

        local tbFrame = RidesModelPreview.tResisterFrame["CoinShop_View"]["CoinShop"]
        local model = tbFrame.hRidesModelView
        local camera = tbFrame.camera
        UITouchHelper.BindModel(self.TouchContainer, model, camera, {tbFrame = tbFrame}, true)
    end

    Timer.DelTimer(self, self.nModelUpdateTimerID)
    if self.m_szViewPage == "Furniture" then
        self.nModelUpdateTimerID = Timer.Add(self, 0.5, fnAction)
    else
        self.nModelUpdateTimerID = Timer.AddFrame(self, 3, fnAction)
    end
end

function UICoinShopMainView:UpdateRideViewBtnState()
    local tbBuySaveList = CoinShopPreview.GetChangeRideItem()
    local nBuyCount = 0
    for _, tbItem in ipairs(tbBuySaveList) do
        if not tbItem.bHave then
            nBuyCount = nBuyCount + 1
        end
    end

    if nBuyCount > 0 then
        UIHelper.SetString(self.LabelBuy, "购买（" .. nBuyCount .."）")
        UIHelper.SetButtonState(self.BtnBuy, BTN_STATE.Normal)
    else
        UIHelper.SetString(self.LabelBuy, "购买")
        UIHelper.SetButtonState(self.BtnBuy, BTN_STATE.Disable)
    end
end

function UICoinShopMainView:OnPetViewDataUpdate()
    if self.m_szViewPage ~= "Pet" then
        self:UnRegisterView()
    end

    local fnAction = function()
        if self.m_szViewPage ~= "Pet" then
            ExteriorCharacter.RegisterNpc(self.MiniScene, self:GetScene())
            UIHelper.SetSelected(self.ToggleCamera, true, false)
        end
        self.m_szViewPage = "Pet"
        ExteriorCharacter.SetViewPage("Pet")
        APIHelper.SetNpcLODLvl(0)
        ExteriorCharacter.UpdatePetModel()
        APIHelper.SetNpcLODLvl()

        UIHelper.SetVisible(self.WidgetDownloadBtnShell, false)
        UIHelper.SetVisible(self.BtnBuy, self.nCoinShopType == UI_COINSHOP_GENERAL.SHOP)
        UIHelper.SetVisible(self.BtnPreserve, false)
        UIHelper.SetVisible(self.BtnPresets, false)
        UIHelper.SetVisible(self.BtnReplace, false)
        UIHelper.SetVisible(self.BtnAbandon, false)
        UIHelper.LayoutDoLayout(self.LayoutBotton)
        UIHelper.SetVisible(self.BtnRoleReset, false)
        UIHelper.SetVisible(self.TogMenu, false)
        UIHelper.SetVisible(self.TogAnimationPreview, false)
        UIHelper.SetVisible(self.LayoutFurnitureColor, false)
        UIHelper.SetVisible(self.TogSpecialEffect, false)

        self:UpdatePetViewBtnState()

        local tbFrame = NpcModelPreview.tResisterFrame["CoinShop_View"]["CoinShop"]
        local model = tbFrame.hNpcModelView
        local camera = tbFrame.camera
        UITouchHelper.BindModel(self.TouchContainer, model, camera, {tbFrame = tbFrame}, true)
    end

    Timer.DelTimer(self, self.nModelUpdateTimerID)
    if self.m_szViewPage == "Furniture" then
        self.nModelUpdateTimerID = Timer.Add(self, 0.5, fnAction)
    else
        self.nModelUpdateTimerID = Timer.Add(self, 0.21, fnAction)
    end
end

function UICoinShopMainView:UpdatePetViewBtnState()
    local tbBuySaveList = CoinShopPreview.GetChangePetItem()
    local nBuyCount = 0
    for _, tbItem in ipairs(tbBuySaveList) do
        if not tbItem.bHave then
            nBuyCount = nBuyCount + 1
        end
    end

    if nBuyCount > 0 then
        UIHelper.SetString(self.LabelBuy, "购买（" .. nBuyCount .."）")
        UIHelper.SetButtonState(self.BtnBuy, BTN_STATE.Normal)
    else
        UIHelper.SetString(self.LabelBuy, "购买")
        UIHelper.SetButtonState(self.BtnBuy, BTN_STATE.Disable)
    end
end

function UICoinShopMainView:OnFurnitureViewDataUpdate()
    Timer.DelTimer(self, self.nModelUpdateTimerID)
    self.nModelUpdateTimerID = Timer.AddFrame(self, 3, function()
        if self.m_szViewPage ~= "Furniture" then
            self:UnRegisterView()
            ExteriorCharacter.RegisteFurniture(self.MiniScene, self:GetScene())
            UIHelper.SetSelected(self.ToggleCamera, true, false)
        end
        self.m_szViewPage = "Furniture"
        ExteriorCharacter.SetViewPage("Furniture")
        ExteriorCharacter.UpdateFurnitureModel()

        UIHelper.SetVisible(self.WidgetDownloadBtnShell, false)
        UIHelper.SetVisible(self.BtnBuy, self.nCoinShopType == UI_COINSHOP_GENERAL.SHOP)
        UIHelper.SetVisible(self.BtnPreserve, false)
        UIHelper.SetVisible(self.BtnPresets, false)
        UIHelper.SetVisible(self.BtnReplace, false)
        UIHelper.SetVisible(self.BtnAbandon, false)
        UIHelper.LayoutDoLayout(self.LayoutBotton)
        UIHelper.SetVisible(self.BtnRoleReset, false)
        UIHelper.SetVisible(self.TogMenu, false)
        UIHelper.SetVisible(self.TogAnimationPreview, false)
        UIHelper.SetVisible(self.LayoutFurnitureColor, false)
        UIHelper.SetVisible(self.TogSpecialEffect, false)

        self:InitFurnitureColor()
        self:UpdateFurnitureViewBtnState()

        Timer.DelTimer(self, self.nFurnitureTouchTimerID)
        self.nFurnitureTouchTimerID = Timer.AddFrame(self, 3, function ()
            local tbFrame = FurnitureModelPreview.tResisterFrame["CoinShop_View"]["CoinShop"]
            local model = tbFrame.hFurnitureModelView
            local camera = tbFrame.camera
            UITouchHelper.BindModel(self.TouchContainer, model, camera, {tbFrame = tbFrame}, true)
        end)
    end)
end

function UICoinShopMainView:UpdateFurnitureViewBtnState()
    local tbBuySaveList = CoinShopPreview.GetChangeFurnitureItem()
    local nBuyCount = 0
    for _, tbItem in ipairs(tbBuySaveList) do
        if not tbItem.bHave then
            nBuyCount = nBuyCount + 1
        end
    end

    if nBuyCount > 0 then
        UIHelper.SetString(self.LabelBuy, "购买（" .. nBuyCount .."）")
        UIHelper.SetButtonState(self.BtnBuy, BTN_STATE.Normal)
    else
        UIHelper.SetString(self.LabelBuy, "购买")
        UIHelper.SetButtonState(self.BtnBuy, BTN_STATE.Disable)
    end
end

function UICoinShopMainView:InitFurnitureColor()
    local tData = ExteriorCharacter.GetFurnitureData()
    local tItem = tData.tItem
    if not tItem then
        return
    end
    local dwRepresentID = tItem.dwRepresentID
    if not dwRepresentID then
        return
    end
    local bCanDye = FurnitureData.FurnCanDye(dwRepresentID)
    if not bCanDye then
        return
    end
    local tColorInfos = FurnitureData.GetFurnColorInfos(dwRepresentID)
    local script = UIHelper.GetBindScript(self.LayoutFurnitureColor)
    script:UpdateInfo(tColorInfos)
    UIHelper.SetVisible(self.LayoutFurnitureColor, true)
end

function UICoinShopMainView:UpdateViewData(szViewPage)
    if szViewPage == "Role" then
        self:OnRoleViewDataUpdate()
    elseif szViewPage == "Ride" then
        self:OnRideViewDataUpdate()
    elseif szViewPage == "Pet" then
        self:OnPetViewDataUpdate()
    elseif szViewPage == "Furniture" then
        self:OnFurnitureViewDataUpdate()
    end
end

function UICoinShopMainView:UpdateViewBtnState(szViewPage)
    if szViewPage == "Role" then
        self:UpdateRoleViewBtnState()
    elseif szViewPage == "Ride" then
        self:UpdateRideViewBtnState()
    elseif szViewPage == "Pet" then
        self:UpdatePetViewBtnState()
    elseif szViewPage == "Furniture" then
        self:UpdateFurnitureViewBtnState()
    end
end

function UICoinShopMainView:UpdateActiveOpenBanner()
    if AppReviewMgr.IsReview() then
        return
    end
    -- if Config.bIsCEVer then
    --     return
    -- end
    -- if not CoinShop_IsActiveOpenNews() then
	-- 	return
	-- end
    -- local nCurrentTime = GetGSCurrentTime()
    -- local tTodayDate = TimeToDate(nCurrentTime)
	-- if CoinShopData.nLastOpenBannerTime then
	-- 	local tLastDate = TimeToDate(CoinShopData.nLastOpenBannerTime)
	-- 	if tTodayDate.year == tLastDate.year and tTodayDate.month == tLastDate.month and tTodayDate.day == tLastDate.day then
	-- 		return
	-- 	end
	-- end
    -- CoinShopData.nLastOpenBannerTime = nCurrentTime
    -- UIMgr.Open(VIEW_ID.PanelActivityBanner, 1)
end

-- 预览
function UICoinShopMainView:UpdatePreview()
    Timer.DelTimer(self, self.nUpdatePreviewTimerID)
    self.nUpdatePreviewTimerID = Timer.Add(self, 0.2, function()
        self.scriptPreview = self.scriptPreview or UIHelper.AddPrefab(PREFAB_ID.WidgetExteriorPreview, self.WidgetPreviewContainer)
    end)

    UIHelper.SetTouchDownHideTips(self.TogHat, false)
    UIHelper.SetTouchDownHideTips(self.TogFacePendant, false)
    UIHelper.SetTouchDownHideTips(self.TogFace, false)
    UIHelper.SetTouchDownHideTips(self.TogHideHair, false)
    UIHelper.SetTouchDownHideTips(self.TogCloak, false)
    UIHelper.SetTouchEnabled(self.LayoutMenu, true)
    UIHelper.SetTouchDownHideTips(self.LayoutMenu, false)
    UIHelper.SetSelected(self.TogHat, not g_pClientPlayer.bHideHat, false)
    UIHelper.SetSelected(self.TogFacePendant, not g_pClientPlayer.bHideFacePendent, false)
    UIHelper.SetSelected(self.TogFace, GetFaceLiftManager().GetDecorationShowFlag(), false)
    UIHelper.SetSelected(self.TogCloak, not g_pClientPlayer.GetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL), false)
    self:UpdateHideHairCheck()
end

function UICoinShopMainView:UpdateLottery()
    local bResult = false
    local tAllPool = Table_GetPointsDrawAllPoolInfo()
    for i, tLine in ipairs(tAllPool) do
        local nIndex = tLine.nIndex
        local bOnTime = CoinShopData.IsDrawPoolOnTime(nIndex)
        if bOnTime then
           bResult = true
           break
        end
    end
    UIHelper.SetVisible(self.BtnIntegral, bResult)
end

function UICoinShopMainView:UpdateLeftTreeNode(scriptNode, tArgs, bSelected)
    local szName = tArgs.szName
    local bHasChildren = not tArgs.bOutfit
    local nLabel = tArgs.nLabel

    local szLabelImgPath
    if nLabel == EXTERIOR_LABEL.NEW then
        szLabelImgPath = "UIAtlas2_Shopping_ShoppingIcon_img_new"
    elseif nLabel == EXTERIOR_LABEL.HOT then
        szLabelImgPath = "UIAtlas2_Shopping_ShoppingIcon_img_hot"
    elseif nLabel == EXTERIOR_LABEL.DISCOUNT then
        szLabelImgPath = "UIAtlas2_Shopping_ShoppingIcon_img_discount"
    elseif nLabel == EXTERIOR_LABEL.TIME_LIMIT then
        szLabelImgPath = "UIAtlas2_Shopping_ShoppingIcon_img_xian"
    end
    if szLabelImgPath then
        UIHelper.SetVisible(scriptNode.ImgIcon, true)
        UIHelper.SetSpriteFrame(scriptNode.ImgIcon, szLabelImgPath)
    else
        UIHelper.SetVisible(scriptNode.ImgIcon, false)
    end

    UIHelper.SetVisible(scriptNode.ImgLine, bHasChildren and bSelected)
    UIHelper.SetVisible(scriptNode.ImgFront, true)
    UIHelper.SetVisible(scriptNode.AniLoop, false)
    UIHelper.SetString(scriptNode.LabelName, szName)
    UIHelper.SetVisible(scriptNode.LayoutNameSelect, bSelected)
    UIHelper.SetString(scriptNode.LabelNameNormal, szName)
    UIHelper.SetVisible(scriptNode.LayoutNameNormal, not bSelected)
    self:UpdateTitleRed(scriptNode, tArgs)
    self:UpdateSchoolTitleRed(scriptNode, tArgs)

    if bSelected then
        local szBackName = "UIAtlas2_Shopping_ShoppingButton_Img_Shopping_ChosenFrame"
        local szFrontName = bHasChildren and "UIAtlas2_Shopping_ShoppingButton_Img_Shopping_FatherExpanded" or "UIAtlas2_Shopping_ShoppingButton_Img_Shopping_NaviChosenFrame"
        UIHelper.SetSpriteFrame(scriptNode.ImgBack, szBackName)
        UIHelper.SetSpriteFrame(scriptNode.ImgFront, szFrontName)
        UIHelper.SetVisible(scriptNode.ImgFront, true)
        UIHelper.SetVisible(scriptNode.ImgFront, not bHasChildren)
        UIHelper.SetVisible(scriptNode.AniLoop, bHasChildren)

        UIHelper.SetVisible(scriptNode.LayoutContent, false)
        UIHelper.SetVisible(scriptNode.LayoutContent, true)
    else
        local szBackName = bHasChildren and "UIAtlas2_Public_PublicButton_PublicNavigation_Img_FatherFolded" or "UIAtlas2_Public_PublicButton_PublicNavigation_Img_NaviNormal"
        UIHelper.SetSpriteFrame(scriptNode.ImgBack, szBackName)
        UIHelper.SetVisible(scriptNode.ImgFront, false)
    end
end

function UICoinShopMainView:RefreshTitleListRed()
    CoinShop_UpdateNoticeTitleMap()
    local script = UIHelper.GetBindScript(self.WidgetShoppingLeft)
    for _, tContainer in ipairs(script.tContainerList) do
        local scriptContainer = tContainer.scriptContainer
        self:UpdateTitleRed(scriptContainer, scriptContainer.tArgs)
        for _, itemScript in ipairs(scriptContainer.tItemScripts) do
            itemScript:UpdateTitleRed()
        end
    end
    if script.scriptTopContainer and script.scriptCurContainer then
        self:UpdateTitleRed(script.scriptTopContainer, script.scriptCurContainer.tArgs)
    end
    self:UpdateTitleListRedPointArrow()
end

function UICoinShopMainView:UpdateTitleRed(script, tArgs)
    local bRed = false
    bRed = bRed or self:IsTitleNotify(script, tArgs)
    bRed = bRed or self:IsMyTitleNew(script, tArgs)
    UIHelper.SetVisible(script.ImgRedDot, bRed)
    UIHelper.SetVisible(script.ImgRedDotSelect, bRed)
    UIHelper.LayoutDoLayout(script.LayoutNameNormal)
    UIHelper.LayoutDoLayout(script.LayoutNameSelect)
end

function UICoinShopMainView:IsTitleNotify(script, tArgs)
    if not tArgs.bShop then
        return false
    end
    local bNotice = false
    if tArgs.tItemList then
        for _, v in ipairs(tArgs.tItemList) do
            local tItemArgs = v.tArgs
            if tItemArgs.nTitleClass and tItemArgs.nTitleSub and not tItemArgs.nSubClass then
                bNotice = CoinShop_IsNoticeTitle(tItemArgs.nTitleClass, tItemArgs.nTitleSub)
                if bNotice then
                   break
                end
            end
        end
    end
    if not bNotice then
        if tArgs.nTitleClass and tArgs.nTitleSub then
            bNotice = CoinShop_IsNoticeTitle(tArgs.nTitleClass, tArgs.nTitleSub)
        end
    end
    return bNotice
end

function UICoinShopMainView:IsMyTitleNew(script, tArgs)
    if tArgs.bShop then
        return
    end
    local bNew = false
    if tArgs.tItemList then
        for _, v in ipairs(tArgs.tItemList) do
            local tItemArgs = v.tArgs
            if tItemArgs.nType and tItemArgs.nRewardsClass then
                bNew = CoinShopData.IsMyTitleHasNew(tItemArgs.nType, tItemArgs.nRewardsClass)
                if bNew then
                   break
                end
            end
        end
    end
    if not bNew then
        if tArgs.nType and tArgs.nRewardsClass then
            bNew = CoinShopData.IsMyTitleHasNew(tArgs.nType, tArgs.nRewardsClass)
        end
    end
    return bNew
end

function UICoinShopMainView:UpdateTitleListRedPointArrow()
	local bHasRedPointBelow, nRedPointCount = self:TitleListHasRedPointBelow()
    UIHelper.SetVisible(self.WidgetRedPointArrow, bHasRedPointBelow)
    UIHelper.SetString(self.LabelRedPointArrow, nRedPointCount)
end

function UICoinShopMainView:TitleListHasRedPointBelow()
	local bHasRedPointBelow = false
    local nRedPointCount = 0

    local script = UIHelper.GetBindScript(self.WidgetShoppingLeft)
    local _, nScrollViewWorldY = UIHelper.ConvertToWorldSpace(script.ScrollViewContent, 0, 0)
    local fnUpdate = function(ImgRedDot)
        if UIHelper.GetVisible(ImgRedDot) then
			local nHeight = UIHelper.GetHeight(ImgRedDot)
			local _nWorldX, _nWorldY = UIHelper.ConvertToWorldSpace(ImgRedDot, 0, nHeight)
			if _nWorldY < nScrollViewWorldY then
				bHasRedPointBelow = true
                nRedPointCount = nRedPointCount + 1
			end
		end
    end
    for _, tContainer in ipairs(script.tContainerList) do
        local scriptContainer = tContainer.scriptContainer
        fnUpdate(scriptContainer.ImgRedDot)
        for _, itemScript in ipairs(scriptContainer.tItemScripts) do
            fnUpdate(itemScript.ImgRedDot)
        end
    end
	return bHasRedPointBelow, nRedPointCount
end


function UICoinShopMainView:ShowItemTips(tbGoods, tbCleanBtnInfo)
    self.itemTip = nil
    UIHelper.RemoveAllChildren(self.WidgetPropItemTips)
    if not self.itemTip then
        self.itemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetPropItemTips)
        self.itemTip:HidePreviewBtn(true)
        self.itemTip:OnInit()
        UIHelper.SetVisible(self.WidgetPropItemTips, true)
    end
    CoinShopPreview.InitItemTips(tbGoods, self.itemTip, nil, tbCleanBtnInfo)
end

function UICoinShopMainView:ShowItemDetail(dwID)
    if not self.itemDetail then
        self.itemDetail = UIHelper.AddPrefab(PREFAB_ID.WidgetSpecialItemTips, self.WidgetSpecialItemTips, dwID)
        UIHelper.SetVisible(self.WidgetSpecialItemTips, true)
    end
    UIHelper.SetAnchorPoint(self.itemDetail._rootNode, 0.5, 0.5)
end

function UICoinShopMainView:ClearSelect()
    self.scriptFilter = nil
    UIHelper.SetSelected(self.TogTaozhuang, false, false)
    UIHelper.SetSelected(self.TogFeatureEntry, false)
    UIHelper.SetSelected(self.TogCoupon, false)
    UIHelper.SetSelected(self.TogMenu, false)
    UIHelper.SetSelected(self.TogEmotion, false)
    UIHelper.SetSelected(self.TogCloudFace, false)
    UIHelper.SetSelected(self.TogCloudBody, false)
    UIHelper.SetSelected(self.TogCloudDressup, false)
    UIHelper.SetSelected(self.TogAnimationPreview, false)
    UIHelper.SetSelected(self.TogSpecialEffect, false)

    if self.itemTip then
        self.itemTip:OnInit()
    end
    if self.itemDetail then
        UIHelper.RemoveFromParent(self.itemDetail._rootNode, true)
        self.itemDetail = nil
    end
end

function UICoinShopMainView:OnSelectedEmotion(nIndex)
    if not ExteriorCharacter.IsNewFace() then
        TipsHelper.ShowNormalTip("非写实脸型暂不支持表情")
        return
    end

	local tAni 	= Table_GetFaceAniList(g_pClientPlayer.nRoleType)
    local tbInfo = tAni[nIndex]
    if not tbInfo then
        return
    end

    local ModleView = ExteriorCharacter.GetModel("CoinShop_View", "CoinShop")
    if not ModleView then
        return
    end
    local mdl = ModleView:GetFaceModel()
    if not mdl then
        return
    end

    ModleView:PlayAni(mdl, {id = tbInfo.szAniPath, type = "once", usepath = true})
end

function UICoinShopMainView:UpdateDownloadEquipRes(tRepresentID)
    if not PakDownloadMgr.IsEnabled() then
        return
    end

    local nRoleType = g_pClientPlayer.nRoleType
    local tEquipList, tEquipSfxList = Player_GetPakEquipResource(nRoleType, tRepresentID.nHatStyle, tRepresentID)

    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownloadBtnShell)
    local tConfig = {}
    tConfig.bLong = true
    local bRemoteNotExist
    self.nDownloadDynamicID, bRemoteNotExist = PakDownloadMgr.UserCheckDownloadEquipRes(nRoleType, tEquipList, tEquipSfxList, self.nDownloadDynamicID)
    CoinShopPreview.UpdateSimpleDownloadBtn(scriptDownload, self.nDownloadDynamicID, bRemoteNotExist, tConfig)
end

function UICoinShopMainView:OnEnterExteriorChangeColor(dwSrcID, dwDstID)
    self.bExteriorChangeColor = true
    self.dwExteriorChangeColorSrcID = dwSrcID
    self.dwExteriorChangeColorDstID = dwDstID
    UIHelper.SetVisible(self.BtnBuy, false)
    UIHelper.SetVisible(self.BtnPreserve, false)
    UIHelper.SetVisible(self.BtnPresets, false)
    UIHelper.SetVisible(self.BtnReplace, false)
    UIHelper.SetVisible(self.BtnAbandon, false)
    UIHelper.SetVisible(self.WidgetChangeColor, true)
    UIHelper.LayoutDoLayout(self.LayoutBotton)

    local dwTabType, dwIndex, nItemNum = GetExterior().GetChangeExteriorColorItem()
    local hItemInfo = GetItemInfo(dwTabType, dwIndex)
    local szItemName = ItemData.GetItemNameByItem(hItemInfo)
    local nHaveItem = g_pClientPlayer.GetItemAmountInPackage(dwTabType, dwIndex)
    local szTips = ""
    if nHaveItem < nItemNum then
        szTips = string.format("<color=#AED9E0>消耗道具%s</c><color=#ff7676>x1</color>", UIHelper.GBKToUTF8(szItemName))
    else
        szTips = string.format("<color=#AED9E0>消耗道具%s</c><color=#ffffff>x1</color>", UIHelper.GBKToUTF8(szItemName))
    end
    UIHelper.SetRichText(self.LabelChangeColorTip, szTips)
    UIHelper.SetButtonState(self.BtnChange, BTN_STATE.Normal)

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hExterior = GetExterior()
    if not hExterior then
        return
    end

    local tRepresentID = Role_GetRepresentID(hPlayer)

    local tRepresentSub =
    {
        EQUIPMENT_REPRESENT.HELM_STYLE,
        EQUIPMENT_REPRESENT.CHEST_STYLE,
        EQUIPMENT_REPRESENT.BANGLE_STYLE,
        EQUIPMENT_REPRESENT.WAIST_STYLE,
        EQUIPMENT_REPRESENT.BOOTS_STYLE,
        EQUIPMENT_REPRESENT.FACE_EXTEND,
        EQUIPMENT_REPRESENT.BACK_EXTEND,
        EQUIPMENT_REPRESENT.WAIST_EXTEND,

        EQUIPMENT_REPRESENT.WEAPON_STYLE,
        EQUIPMENT_REPRESENT.BIG_SWORD_STYLE,
    }

    for _, nRepresentSub in ipairs(tRepresentSub) do
        tRepresentID[nRepresentSub] = 0
    end

    local tExteriorInfo = hExterior.GetExteriorInfo(dwDstID)
    local nRepresentSub = Exterior_SubToRepresentSub(tExteriorInfo.nSubType)
    local nRepresentColor = Exterior_RepresentSubToColor(nRepresentSub)
    local nRepresentDyeing = Exterior_RepresentSubToDyeing(nRepresentSub)
    tRepresentID[nRepresentSub] = tExteriorInfo.nRepresentID
    tRepresentID[nRepresentColor] = tExteriorInfo.nColorID
    if nRepresentDyeing then
        tRepresentID[nRepresentDyeing] = g_pClientPlayer.GetExteriorDyeingID(dwDstID)
    end

    FireUIEvent("EXTERIOR_CHARACTER_UPDATE", "CoinShop_View", "CoinShop", tRepresentID, false, nil, nil)
end

function UICoinShopMainView:OnCancelExteriorChangeColor()
    self.bExteriorChangeColor = false
    self.dwExteriorChangeColorSrcID = nil
    self.dwExteriorChangeColorDstID = nil
    UIHelper.SetVisible(self.WidgetChangeColor, false)
    self:UpdateViewData(self.m_szViewPage)
end

function UICoinShopMainView:ExteriorChangeColor()
    local dwSrcID = self.dwExteriorChangeColorSrcID
    local dwDstID = self.dwExteriorChangeColorDstID
    if not dwSrcID or not dwDstID then
        return
    end
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local bHaveTime = false
    local nTimeType, nTime = hPlayer.GetExteriorTimeLimitInfo(dwDstID)
    local nOwnType = GetCoinShopClient().CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.EXTERIOR, dwDstID)
    if nTimeType and nTimeType == COIN_SHOP_TIME_LIMIT_TYPE.SEVEN_DAYS_LIMIT then
        bHaveTime = true
    end

    local tExteriorInfo = GetExterior().GetExteriorInfo(dwDstID)
    local tSetInfo = Table_GetExteriorSet(tExteriorInfo.nSet)
    local szSetName = tSetInfo.szSetName

    local dwTabType, dwIndex, nItemNum = GetExterior().GetChangeExteriorColorItem()
    local hItemInfo = GetItemInfo(dwTabType, dwIndex)
    local szItemName = ItemData.GetItemNameByItem(hItemInfo)

    local szMsg = ""
    if bHaveTime then
        szMsg = FormatString(g_tStrings.EXTERIOR_CHANGE_COLOR_MSG_TIME_1, UIHelper.GBKToUTF8(szSetName))
    else
        szMsg = FormatString(g_tStrings.EXTERIOR_CHANGE_COLOR_MSG1, UIHelper.GBKToUTF8(szSetName))
    end
    szMsg = szMsg .. UIHelper.GBKToUTF8(szItemName)
    szMsg = szMsg .. GetFormatText(FormatString(g_tStrings.EXTERIOR_CHANGE_COLOR_MSG2, nItemNum))
    UIHelper.ShowConfirm(szMsg, function()
        local nHaveItem = hPlayer.GetItemAmountInPackage(dwTabType, dwIndex)
        if nHaveItem < nItemNum then
            local dwGoodsID = Table_GetRewardsGoodID(dwTabType, dwIndex)
            local nPrice = CoinShop_GetPrice(dwGoodsID, COIN_SHOP_GOODS_TYPE.ITEM)
            local szBuyMsg = UIHelper.GBKToUTF8(szItemName) .. g_tStrings.EXTERIOR_CHANGE_COLOR_LESS_ITEM
            szBuyMsg = szBuyMsg .. FormatString(g_tStrings.EXTERIOR_GET_FROM_ITEM_TIP2_3, nPrice * (nItemNum - nHaveItem))
            UIHelper.ShowConfirm(szBuyMsg, function()
                CoinShop_BuyItem(dwGoodsID, COIN_SHOP_GOODS_TYPE.ITEM, nItemNum - nHaveItem)
            end)
        else
            local nRet = GetCoinShopClient().CheckCanChangeExteriorColor(dwSrcID, dwDstID)
            if nRet == COIN_SHOP_ERROR_CODE.SUCCESS then
                GetCoinShopClient().ChangeExteriorColor(dwSrcID, dwDstID)
                Event.Dispatch(EventType.OnCoinShopCancelExteriorChangeColor)
            else
                OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tCoinShopNotify[nRet])
            end
        end
    end)
end

function UICoinShopMainView:OnEnterExteriorChangeHair(dwID, nDyeingID, tSub)
    self.bExteriorChangeHair = true
    self.dwExteriorChangeHairID = dwID
    self.dwExteriorChangeHairDyeingID = nDyeingID
    UIHelper.SetVisible(self.BtnBuy, false)
    UIHelper.SetVisible(self.BtnPreserve, false)
    UIHelper.SetVisible(self.BtnPresets, false)
    UIHelper.SetVisible(self.BtnReplace, false)
    UIHelper.SetVisible(self.BtnAbandon, false)
    UIHelper.SetVisible(self.WidgetChangeColor, true)
    UIHelper.LayoutDoLayout(self.LayoutBotton)

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hExterior = GetExterior()
    if not hExterior then
        return
    end

    local tRewardsItem  = Table_GetRewardsItem(CHANGE_HAIR_GOODS)
    if not tRewardsItem then
        return
    end
    local nCurDyeingID = g_pClientPlayer.GetExteriorDyeingID(dwID)
    local szGoodNameGBK = CoinShop_GetGoodsName(COIN_SHOP_GOODS_TYPE.ITEM, CHANGE_HAIR_GOODS)
    local nHaveItem = hPlayer.GetItemAmountInPackage(tRewardsItem.dwTabType, tRewardsItem.dwIndex)
    local szTips = ""
    if nHaveItem == 0 then
        szTips = string.format("<color=#AED9E0>消耗道具%s</c><color=#ff7676>x1</color>", UIHelper.GBKToUTF8(szGoodNameGBK))
    else
        szTips = string.format("<color=#AED9E0>消耗道具%s</c><color=#ffffff>x1</color>", UIHelper.GBKToUTF8(szGoodNameGBK))
    end
    UIHelper.SetRichText(self.LabelChangeColorTip, szTips)
    UIHelper.SetButtonState(self.BtnChange, (nCurDyeingID == nDyeingID or nHaveItem == 0) and BTN_STATE.Disable or BTN_STATE.Normal)

    local tRepresentID = clone(ExteriorCharacter.GetRoleRes())
    local bShowWeapon = ExteriorCharacter.IsWeaponShow()
    if not bShowWeapon then
        tRepresentID[EQUIPMENT_REPRESENT.WEAPON_STYLE] = 0
        tRepresentID[EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] = 0
    end
    tRepresentID.tCustomRepresentData = self:GetRoleCustomPendant(tRepresentID)

    local fnModify = function(dwSubID)
        local tExteriorInfo = hExterior.GetExteriorInfo(dwSubID)
        local nRepresentSub = Exterior_SubToRepresentSub(tExteriorInfo.nSubType)
        local nRepresentColor = Exterior_RepresentSubToColor(nRepresentSub)
        local nRepresentDyeing = Exterior_RepresentSubToDyeing(nRepresentSub)
        tRepresentID[nRepresentSub] = tExteriorInfo.nRepresentID
        tRepresentID[nRepresentColor] = tExteriorInfo.nColorID
        if nRepresentDyeing then
            if dwID ~= dwSubID then
                tRepresentID[nRepresentDyeing] = g_pClientPlayer.GetExteriorDyeingID(dwSubID)
            else
                tRepresentID[nRepresentDyeing] = nDyeingID
            end
        end
    end
    if tSub then
        for _, dwSubID in ipairs(tSub) do
            fnModify(dwSubID)
        end
    else
        fnModify(dwID)
    end
    FireUIEvent("EXTERIOR_CHARACTER_UPDATE", "CoinShop_View", "CoinShop", tRepresentID, false, nil, nil)
end

function UICoinShopMainView:OnCancelExteriorChangeHair()
    self.bExteriorChangeHair = false
    self.dwExteriorChangeHairID = nil
    self.dwExteriorChangeHairDyeingID = nil
    UIHelper.SetVisible(self.WidgetChangeColor, false)
    self:UpdateViewData(self.m_szViewPage)
end

function UICoinShopMainView:ExteriorChangeHair()
    local dwID = self.dwExteriorChangeHairID
    local nDyeingID = self.dwExteriorChangeHairDyeingID
    if not dwID or not nDyeingID then
        return
    end
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local tRewardsItem  = Table_GetRewardsItem(CHANGE_HAIR_GOODS)
    if not tRewardsItem then
        return
    end

    local szGoodNameGBK = CoinShop_GetGoodsName(COIN_SHOP_GOODS_TYPE.ITEM, CHANGE_HAIR_GOODS)
    local szGoodName = UIHelper.GBKToUTF8(szGoodNameGBK)
    local nPrice = CoinShop_GetPrice(CHANGE_HAIR_GOODS, COIN_SHOP_GOODS_TYPE.ITEM)
    local nHaveItem = hPlayer.GetItemAmountInPackage(tRewardsItem.dwTabType, tRewardsItem.dwIndex)
    if nHaveItem == 0 then
        if UIMgr.GetView(VIEW_ID.PanelShareStation) then
            TipsHelper.ShowNormalTip("所需"..szGoodName.."不足，无法染色")
            return
        end
        -- local szMsg = FormatString(g_tStrings.STR_BUY_CHANGE_HAIR_ITEM_MSG, szGoodName, nPrice)
        -- UIHelper.ShowConfirm(szMsg, function()
        --     CoinShop_BuyItem(CHANGE_HAIR_GOODS, COIN_SHOP_GOODS_TYPE.ITEM, 1)
        -- end)
    else
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP, "CoinShop_ChangeHairColor") then
            return
        end
        local tExteriorInfo = GetExterior().GetExteriorInfo(dwID)
        local tSet = Table_GetExteriorSet(tExteriorInfo.nSet)
        local szSub = g_tStrings.tExteriorSubNameGBK[tExteriorInfo.nSubType]
        local szName = UIHelper.GBKToUTF8(tSet.szSetName .. g_tStrings.STR_CONNECT_GBK .. szSub)
        local szMsg = FormatString(g_tStrings.STR_CHANGE_COLOR_TEXT, szName, g_tStrings.STR_HAIR_COLOR[nDyeingID], szGoodName, nHaveItem)
        UIHelper.ShowConfirm(szMsg, function()
            RemoteCallToServer("On_ExteriorDyeing_Hat", dwID, nDyeingID)
            Event.Dispatch(EventType.OnCoinShopCancelExteriorChangeHair)
        end)
    end
end

-- =============================== 免费领校服 begin =====================
function UICoinShopMainView:OnSelectedActivity()
    self:SetActivityButton(false)
    UIHelper.SetString(self.LabelTitle, "外观商城")
    if self.nCoinShopType == UI_COINSHOP_GENERAL.BUILD_FACE then
        UIHelper.PlayAni(self, self.AniAll, "AniRightLineToRight")
    end
    self.nCoinShopType = UI_COINSHOP_GENERAL.SHOP
    self.curView = "fakeactivity"
    ExteriorCharacter.SetCameraMode("Normal")
    -- ExteriorCharacter.ScaleToCamera("Max")

    UIHelper.SetVisible(self.WidgetAnchorExteriorContent, true)
    UIHelper.SetVisible(self.WidgetAnchorWardrobeContent, false)
    UIHelper.SetVisible(self.WidgetAnchorNewContent, false)
    UIHelper.SetVisible(self.WidgetAnchorHair, false)
    UIHelper.SetVisible(self.ImgBuyingPriceBg, false)
    UIHelper.SetVisible(self.WidgetNewLeft, false)
    UIHelper.SetVisible(self.WidgetShoppingLeft, true)
    UIHelper.SetVisible(self.TogEmotion, false)
    UIHelper.SetVisible(self.TogCloudFace, false)
    UIHelper.SetVisible(self.TogCloudBody, false)
    UIHelper.SetVisible(self.BtnUploadDressup, true)

    UIHelper.SetSelected(self.TogNew, false, false)
    UIHelper.SetSelected(self.TogActivity, true, false)
    UIHelper.SetSelected(self.TogShopping, false, false)
    UIHelper.SetSelected(self.TogWardrobe, false, false)

    UIHelper.SetVisible(self.TogEye, true)
    UIHelper.LayoutDoLayout(self.LayoutMenu)

    self:UpdateActivityList()
    FireUIEvent("RESET_ACTION")
end

function UICoinShopMainView:UpdateActivityList()
    local script = UIHelper.GetBindScript(self.WidgetShoppingLeft)
    assert(script)
    local tData = {
        tArgs = {bSchoolRule = true, szName = "免费领校服",},
        tItemList = {},
        fnSelectedCallback = function(bSelected, scriptContainer)
            self:UpdateLeftTreeNode(scriptContainer, scriptContainer.tArgs, bSelected)
        end,
    }
    if bOpenSchoolSplit then
        tData.tItemList[1] = {
            tArgs = {
                bSchoolRule = true,
                szName = UIHelper.UTF8ToGBK("领取资格"),
                fnSelectedCallback = function()
                    self.m_szViewPage = "Activity"
                    ExteriorCharacter.SetViewPage("Activity")
                    self:UnRegisterView()
                    self:SetActivityButton(false)
                    self:UpdateCouponShow(false)
                    UIHelper.SetVisible(self.WidgetAnchorExteriorContent, false)
                    self.schoolRuleView:Update()
                    Timer.AddFrame(self, 3, function()
                        self.m_szViewPage = "Activity"
                        ExteriorCharacter.SetViewPage("Activity")
                        self:UnRegisterView()
                    end)
                end,
            }
        }
        tData.tItemList[2] = {
            tArgs = {
                szName = UIHelper.UTF8ToGBK("免费领校服"),
                fnSelectedCallback = function()
                    self:OnRoleViewDataUpdate()
                    self:SetActivityButton(true)
                    self:UpdateCouponShow(false)
                    UIHelper.SetVisible(self.WidgetAnchorExteriorContent, true)
                    self:UpdateActivityShop(3, 6)
                end,
            }
        }
    else
        tData.tItemList[1] = {
            tArgs = {
                szName = UIHelper.UTF8ToGBK("免费领校服"),
                fnSelectedCallback = function()
                    self:OnRoleViewDataUpdate()
                    self:SetActivityButton(true)
                    self:UpdateCouponShow(false)
                    UIHelper.SetVisible(self.WidgetAnchorExteriorContent, true)
                    self:UpdateActivityShop(3, 6)
                end,
            }
        }
    end
    script:ClearContainer()
    local fnInitContainer = function (scriptContainer, tArgs, bIsSelected)
        self:UpdateLeftTreeNode(scriptContainer, tArgs, bIsSelected)
    end
    UIHelper.SetupScrollViewTree(script, PREFAB_ID.WidgetShoppingTabList, PREFAB_ID.WidgetSecondNav, fnInitContainer, {tData}, true)

    local scriptContainer = script.tContainerList[1].scriptContainer
    scriptContainer:SetSelected(true)
    local scriptItem = scriptContainer.tItemScripts[1]
    scriptItem:SetSelected(true)
end

function UICoinShopMainView:UpdateSchoolTitleRed(script, tArgs)
    if not tArgs.bSchoolRule then
        return false
    end
    local bRed = RedpointHelper.CoinShopSchool_HasRedPoint()
    UIHelper.SetVisible(script.ImgRedDot, bRed)
    UIHelper.SetVisible(script.ImgRedDotSelect, bRed)
end

function UICoinShopMainView:RefreshSchoolTitleListRed()
    local script = UIHelper.GetBindScript(self.WidgetShoppingLeft)
    assert(script)
    for _, tContainer in ipairs(script.tContainerList) do
        local scriptContainer = tContainer.scriptContainer
        self:UpdateSchoolTitleRed(scriptContainer, scriptContainer.tArgs)
        for _, itemScript in ipairs(scriptContainer.tItemScripts) do
            itemScript:UpdateSchoolTitleRed()
        end
    end
    if script.scriptTopContainer and script.scriptCurContainer then
        self:UpdateSchoolTitleRed(script.scriptTopContainer, script.scriptCurContainer.tArgs)
    end
end

function UICoinShopMainView:UpdateActivityShop(nType, nClass)
    -- 山寨OnSelectTitle 因为activity暂共用self.shopView 但不能直接赋值self.shopView
    local tbTitle = CoinShop_GetTitleInfo(nType, nClass)
    self.shopView:UpdateGoodList(tbTitle, nSubClass, self.bInLinkGoods)

    local tParams = {nType=nType, nClass=nClass, nSubClass=nil, bOutfit=nil}
    self.tSchoolCacheTitleParams = tParams
end

function UICoinShopMainView:SetActivityButton(bShow)
    UIHelper.SetVisible(self.WidgetAnchorRightLine, bShow)
    UIHelper.SetVisible(self.WidgetAniRight, bShow)
    UIHelper.SetVisible(self.WidgetActivityRulePage, not bShow)
end

function UICoinShopMainView:UpdateCouponShow(bShow)
    UIHelper.SetVisible(self.BtnSearch, bShow)
    UIHelper.SetVisible(self.TogAll, bShow)
    UIHelper.SetVisible(self.ImgLieBianTime, not bShow)
    if not bShow then
        self:UpdateCouponNum()
    end
    UIHelper.LayoutDoLayout(self.LayoutRightTop1)
end

function UICoinShopMainView:UpdateCouponNum()
    local WELFATE_ID = 180
    local tInfo = CoinShopData.GetWelfare(WELFATE_ID)
    local nCount = tInfo and tInfo.nCount or 0
    local szCount = "<color=#D4BF8A>当前拥有校服券</c><color=#fff8d1>" .. nCount .. "</color><color=#D4BF8A>张</c>"
    UIHelper.SetRichText(self.LabelLieBianTime, szCount)
end

-- =============================== 免费领校服 end =====================

function UICoinShopMainView:UpdateFilterSaveBtnState(nHairHideFlag, nExteriorHideFlag)
    if self.scriptFilter then
        local tbInfo = self.scriptFilter:GetSelectedMap()
        if not nHairHideFlag then
            nHairHideFlag = CoinShopData.GetSubSetFlag(tbInfo[3], #FilterDef.CoinShopSubSet[3].tbList)
        end
        if not nExteriorHideFlag then
            nExteriorHideFlag = CoinShopData.GetSubSetFlag(tbInfo[2], #FilterDef.CoinShopSubSet[2].tbList)
        end

        local bCanHideChest, bCanHideHair =  ExteriorCharacter.GetCanHideSubsetFlag()
        local bHaveHair = CoinShopData.IsHaveHair()
        local bHaveChest = CoinShopData.IsHaveChest()
        local bShowChest = false
        local bShowHair = false
        if bHaveHair and bCanHideHair then
            bShowHair = CoinShopData.IsHairDataChange(nHairHideFlag)
        end

        if bHaveChest and bCanHideChest then
            bShowChest = CoinShopData.IsChestDataChange(nExteriorHideFlag)
        end

        local nState = (bShowHair or bShowChest) and BTN_STATE.Normal or BTN_STATE.Disable
        self.scriptFilter:SetBtnConfirmState(nState)
    end
end

local function GetRewardsItem(tItem)
    if not tItem then
        return
    end
    local dwLogicID = tItem.dwLogicID
    if not dwLogicID or dwLogicID <= 0 then
        return
    end
    local tRewardsItem = Table_GetRewardsItem(dwLogicID)
    if not tRewardsItem then
        return
    end

    return tRewardsItem
end

function UICoinShopMainView:UpdatePreviewBtn()
    for index, btn in ipairs(self.tbPreviewBtn) do
        UIHelper.SetVisible(btn, false)
        UIHelper.UnBindUIEvent(btn, EventType.OnClick)
        UIHelper.SetTouchDownHideTips(btn, false)
    end

    local player = GetClientPlayer()
    if not player then
        return
    end

    local bShowToggle = false
    local tRoleData = ExteriorCharacter.GetRoleData()
    for nIndex, tData in pairs(tRoleData) do
        local nBtnIndex = tbBoxIndex2PreviewBtn[nIndex] or 0
        local btn = self.tbPreviewBtn[nBtnIndex]
        local tItem = IsTable(tData) and tData.tItem or nil
        local tRewardsItem = GetRewardsItem(tItem)
        local szAnimation = nil
        local bSheath = false
        if tRewardsItem and btn then
            local szKey = "szAnimation" .. tRoleFileSuffix[player.nRoleType]
            szAnimation = tRewardsItem[szKey]
            bSheath = tRewardsItem.bWeaponSheath
            if szAnimation and szAnimation ~= "" then
                bShowToggle = true
                UIHelper.SetVisible(btn, true)
                UIHelper.BindUIEvent(btn, EventType.OnClick, function()
                    if self.bPlayingPreviewAni then
                        TipsHelper.ShowNormalTip("预览冷却中，请稍后再试")
                        return
                    end
                    self.bPlayingPreviewAni = true
                    local nWeaponType = ExteriorCharacter.GetWeaponType()
                    FireUIEvent("EXTERIOR_CHARACTER_UPDATE_WEAPON_POS", "CoinShop_View", "CoinShop", bSheath, nWeaponType)
                    FireUIEvent("EXTERIOR_CHARACTER_PLAY_ANIMATION", "CoinShop_View", "CoinShop", "once", szAnimation)
                end)
            else
                UIHelper.SetVisible(btn, false)
            end
        end
    end

    UIHelper.SetVisible(self.TogAnimationPreview, bShowToggle)
    UIHelper.LayoutDoLayout(self.WidgetAnchorRightLine)
    UIHelper.CascadeDoLayoutDoWidget(self.TogAnimationPreview, true, true)
end

function UICoinShopMainView:GetViewExteriorData()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local tExteriorData = {}
    local tExteriorID = {}
    local tDetail = {}
    -- local bCanHideChest, bCanHideHair =  ExteriorCharacter.GetCanHideSubsetFlag()
    local bCanReplace = CoinShopData.GetCanReplace()
    local tRepresentID = ExteriorCharacter.GetRoleRes()
    if not ExteriorCharacter.IsWeaponShow() then --WeaponShow仅仅只用来控制待机动作，如果待机动作是拿武器的，才会把武器显示出来；如果是默认待机则不显示武器，但是此时武器的表现ID是有的
        tRepresentID = clone(tRepresentID)
        tRepresentID[EQUIPMENT_REPRESENT.WEAPON_STYLE] = 0
        tRepresentID[EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] = 0
    end

    local tVisibleResID = Player_GetEquipHideParam( --实际展示出来的部位对应的表现ID
        pPlayer.nRoleType,
        EQUIPMENT_REPRESENT.TOTAL,
        tRepresentID,
        pPlayer.bHideHat
    )

    local tRoleData = ExteriorCharacter.GetRoleData()
    for nIndex, tData in pairs(tRoleData) do
        local nSub
        if nIndex == COINSHOP_BOX_INDEX.HAIR then
            nSub = EQUIPMENT_REPRESENT.HAIR_STYLE
        else
            nSub = Exterior_BoxIndexToRepresentSub(nIndex)  -- 该接口不包括发型和称号特效，需要单独处理
        end
        if nSub then
            local bSubVisible = tVisibleResID[nSub] and tVisibleResID[nSub] > 0
            if nSub == EQUIPMENT_REPRESENT.HAIR_STYLE then -- 发型
                if bSubVisible then
                    tExteriorID[nSub] = tData.nExterior
                    if tData.nExterior > 0 then
                        tDetail[nSub] = {}

                        -- 发饰隐藏
                        local nType = EQUIPMENT_REPRESENT.HAIR_SUBSET_HIDE_MASK
                        local nHairHideFlag = tRepresentID[EQUIPMENT_REPRESENT.HAIR_SUBSET_HIDE_MASK] or 0
                        tDetail[nSub]["nFlag"] = nHairHideFlag

                        -- 染色数据
                        tDetail[nSub]["tDyeingData"] = pPlayer.GetEquippedHairCustomDyeingData(tData.nExterior)
                    end
                else
                    tExteriorID[nSub] = 0
                end
            elseif nSub == EQUIPMENT_REPRESENT.CHEST_STYLE then -- 【成衣】或【外装收集-上衣】
                if bSubVisible then
                    tExteriorID[nSub] = tData.nExterior
                    if tData.nExterior > 0 then
                        tDetail[nSub] = {}

                        -- 外装裁剪
                        local nChestHideFlag = tRepresentID[EQUIPMENT_REPRESENT.CHEST_SUBSET_HIDE_MASK] or 0
                        tDetail[nSub]["nFlag"] = nChestHideFlag

                        -- 包身状态
                        local bReplace = false
                        if bCanReplace then
                            bReplace = ExteriorCharacter.GetRepresentReplace()
                        end
                        tDetail[nSub]["bViewReplace"] = bReplace

                        -- 明教兜帽状态
                        tDetail[nSub]["bMingJiaoCap"] = false --商城无法预览
                    end
                else
                    tExteriorID[nSub] = 0
                end
            elseif nSub == EQUIPMENT_REPRESENT.HELM_STYLE then -- 外装收集-帽子
                if bSubVisible then
                    tExteriorID[nSub] = tData.nExterior
                    if tData.nExterior > 0 then
                        tDetail[nSub] = {}

                        -- 染色标记
                        tDetail[nSub]["nNowDyeingID"] = pPlayer.GetExteriorDyeingID(tData.nExterior)
                    end
                else
                    tExteriorID[nSub] = 0
                end
            elseif nSub == EQUIPMENT_REPRESENT.WAIST_STYLE -- 外装收集-腰带
            or nSub == EQUIPMENT_REPRESENT.BANGLE_STYLE -- 外装收集-护腕
            or nSub == EQUIPMENT_REPRESENT.BOOTS_STYLE -- 外装收集-鞋子
            then
                if bSubVisible then
                    tExteriorID[nSub] = tData.nExterior
                else
                    tExteriorID[nSub] = 0
                end
            elseif nSub == EQUIPMENT_REPRESENT.WEAPON_STYLE or nSub == EQUIPMENT_REPRESENT.BIG_SWORD_STYLE then -- 武器
                if bSubVisible then
                    tExteriorID[nSub] = tData.nExterior
                else
                    tExteriorID[nSub] = 0
                end
            elseif nSub == EQUIPMENT_REPRESENT.BACK_EXTEND -- 背部挂件
                or nSub == EQUIPMENT_REPRESENT.WAIST_EXTEND -- 腰部挂件
                or nSub == EQUIPMENT_REPRESENT.FACE_EXTEND -- 面部挂件
                or nSub == EQUIPMENT_REPRESENT.L_SHOULDER_EXTEND -- 左肩饰
                or nSub == EQUIPMENT_REPRESENT.R_SHOULDER_EXTEND -- 右肩饰
                or nSub == EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND -- 披风
                or nSub == EQUIPMENT_REPRESENT.BAG_EXTEND -- 佩囊
                or nSub == EQUIPMENT_REPRESENT.PENDENT_PET_STYLE -- 挂宠
                or nSub == EQUIPMENT_REPRESENT.GLASSES_EXTEND -- 眼饰
                or nSub == EQUIPMENT_REPRESENT.L_GLOVE_EXTEND -- 左手饰
                or nSub == EQUIPMENT_REPRESENT.R_GLOVE_EXTEND -- 右手饰
                or nSub == EQUIPMENT_REPRESENT.HEAD_EXTEND -- 1号头饰
                or nSub == EQUIPMENT_REPRESENT.HEAD_EXTEND1 -- 2号头饰
                or nSub == EQUIPMENT_REPRESENT.HEAD_EXTEND2 -- 3号头饰
            then
                if nSub == EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND then -- 披风需要特殊处理，即便看不见也要传上去，因为可能只需要用到披风特效
                    bSubVisible = true
                end
                if bSubVisible then
                    local tItem = tData.tItem
                    local dwPendantIndex = tItem.dwPendantIndex or tItem.dwIndex
                    if nSub == EQUIPMENT_REPRESENT.FACE_EXTEND and pPlayer.bHideFacePendent then
                        dwPendantIndex = 0
                    end
                    tExteriorID[nSub] = dwPendantIndex
                    if dwPendantIndex > 0 then
                        tDetail[nSub] = {}

                        -- 自定义挂件数据
                        local iteminfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwPendantIndex)
                        if iteminfo and IsCustomPendantRepresentID(nSub, iteminfo.nRepresentID, pPlayer.nRoleType) then
                            tDetail[nSub]["tCustomData"] = CoinShopData.GetLocalCustomPendantData(nSub, iteminfo.nRepresentID) or pPlayer.GetEquipCustomRepresentData(nSub)
                        end

                        if nSub == EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND then
                            -- 披风显示开关
                            tDetail[nSub]["bVisible"] = not pPlayer.GetRepresentHideFlag(PLAYER_REPRESENT_HIDE_TYPE.BACK_CLOAK_MODEL)

                            -- 披风染色
                            tDetail[nSub]["tColorID"] = tItem.tColorID
                        elseif nSub == EQUIPMENT_REPRESENT.PENDENT_PET_STYLE then
                            -- 挂宠挂载位置
                            tDetail[nSub]["nPetPos"] = tItem.nPos
                        end
                    end
                else
                    tExteriorID[nSub] = 0
                end
            end
        end
    end

    --单独处理称号特效
    local tEffectType = CharacterEffectData.GetAllEffectType()
    for szType, _ in pairs(tEffectType) do
        tExteriorID[szType] = 0
    end

    local tRoleEffect = tRoleData[COINSHOP_BOX_INDEX.EFFECT_SFX]
    if tRoleEffect then
        for nEffectType, v in pairs(tRoleEffect) do
            local szSub = CharacterEffectData.GetEffectTypeByLogicType(nEffectType)
            tExteriorID[szSub] = v.nEffectID
            -- 补充特效自定义位置信息
            if v.nEffectID and v.nEffectID > 0 then
                tDetail[szSub] = tDetail[szSub] or {}
                local tCustomPos = CoinShopEffectCustom.GetData(nEffectType) or CharacterEffectData.GetLocalCustomEffectDataEx(nEffectType, v.nEffectID)
                tDetail[szSub]["tCustomData"] = tCustomPos
            end
        end
    end

    tExteriorData.tExteriorID = tExteriorID
    tExteriorData.tDetail = tDetail
    return tExteriorData
end

local tbEffectType2TogInfo = {
    [PLAYER_SFX_REPRESENT.FOOTPRINT] = {"tbEffectFootTogList", ToggleGroupIndex.CoinShopEffectFoot, EFFECT_FILTER_TYPE.FOOT},
    [PLAYER_SFX_REPRESENT.SURROUND_BODY] = {"tbEffectBodyTogList", ToggleGroupIndex.CoinShopEffectBody, EFFECT_FILTER_TYPE.BODY},
    [PLAYER_SFX_REPRESENT.LEFT_HAND] = {"tbEffectLHandTogList", ToggleGroupIndex.CoinShopEffectLHand, EFFECT_FILTER_TYPE.LHAND},
    [PLAYER_SFX_REPRESENT.RIGHT_HAND] = {"tbEffectRHandTogList", ToggleGroupIndex.CoinShopEffectRHand, EFFECT_FILTER_TYPE.RHAND},
}

function UICoinShopMainView:UpdateEffectTogType()
    local bHaveEffect = false
    for nType = 0, PLAYER_SFX_REPRESENT.COUNT - 1 do
        local tSfxInfo = ExteriorCharacter.GetPreviewEffect(nType)
        local szNodeList, nToggleGroup, nIndex = unpack(tbEffectType2TogInfo[nType])
        if tSfxInfo and tSfxInfo.nEffectID ~= 0 then
            bHaveEffect = true
            UIHelper.SetVisible(self.tbEffectLayoutList[nIndex], true)
            for i, tog in ipairs(self[szNodeList]) do
                local bVisible = i <= tSfxInfo.nStateCount or tSfxInfo.bHaveIdle and i == 4
                UIHelper.SetVisible(tog, bVisible)
                UIHelper.SetTouchDownHideTips(tog, false)
                UIHelper.SetToggleGroupIndex(tog, nToggleGroup)
                if bVisible then
                    local bSelect = i == tSfxInfo.nState or i == 4 and tSfxInfo.nState == 0
                    local nState = i <= 3 and i or 0
                    UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function (_, bSelected)
                        if bSelected then
                            ExteriorCharacter.SetEffectSfxState(nType, nState, true)
                        end
                    end)
                    UIHelper.SetSelected(tog, bSelect, false)
                end
            end
        else
            UIHelper.SetVisible(self.tbEffectLayoutList[nIndex], false)
        end
        UIHelper.LayoutDoLayout(self.tbEffectLayoutList[nIndex])
    end

    UIHelper.LayoutDoLayout(self.WidgetEffectMoreOper)
    UIHelper.SetVisible(self.TogSpecialEffect, false)
end


--- 打开推荐穿搭面板
function UICoinShopMainView:OpenRecommendPanel()
    local scriptCustomPendant = UIHelper.GetBindScript(self.WidgetDIYDecoration)
    scriptCustomPendant:Close()

    UIHelper.SetVisible(self.WidgetRecommend, true)
    UIHelper.SetVisible(self.WidgetPreviewContainer, false)
    UIHelper.SetVisible(self.LayoutBotton, false)
    UIHelper.SetVisible(self.WidgetAnchorRightLine, false)
    if self.scriptRecommend then
        self.scriptRecommend:ShowEmpty()
    end
    self:SyncRecommendToggle(true)
end

--- 关闭推荐穿搭面板
function UICoinShopMainView:CloseRecommendPanel()
    if not self.WidgetRecommend then
        return
    end

    UIHelper.SetVisible(self.WidgetRecommend, false)
    UIHelper.SetVisible(self.WidgetPreviewContainer, true)
    UIHelper.SetVisible(self.LayoutBotton, true)
    UIHelper.SetVisible(self.WidgetAnchorRightLine, true)
    if self.scriptRecommend then
        self.scriptRecommend:Close()
    end
    self:SyncRecommendToggle(false)
end

--- 同步三个 TogRecommend 的选中状态（第三参数 false 抑制回调防止死循环）
function UICoinShopMainView:SyncRecommendToggle(bSelected)
    local tbViewScripts = {self.shopView, self.wardrobeView, self.homeView}
    for _, view in ipairs(tbViewScripts) do
        if view and view.TogRecommend then
            UIHelper.SetSelected(view.TogRecommend, bSelected, false)
        end

        if view and view.TogRecommend_Hair then
            UIHelper.SetSelected(view.TogRecommend_Hair, bSelected, false)
        end
    end
end

--- 所有 PREVIEW/CANCEL_PREVIEW 事件的统一处理：根据当前标题类型刷新推荐
function UICoinShopMainView:RefreshRecommendByCurrentTitle()
    local curView = self.curView
    if curView and curView.m and curView.m.tbTitle then
        self:OpenRecommendByCurrentPreview(curView.m.tbTitle.nType, curView.m.tbTitle.nRewardsClass or 0)
    end
end

--- 根据当前预览数据刷新推荐面板（切页后调用）
-- @param nType    当前标题的类型
-- @param nClass   当前标题的分类
-- @param bOpen    是否强制打开（空列表时不关闭）
-- @param overridePendantID  挂件类型时用此 ID 替换预览数据（解决头饰多槽位问题）
function UICoinShopMainView:OpenRecommendByCurrentPreview(nType, nClass, bOpen, overridePendantID)
    if not self.scriptRecommend or not UIHelper.GetVisible(self.WidgetRecommend) then
        return
    end
    if not self.curView or not self.curView.BuildExteriorListFromPreview then
        return
    end
    if not nType then
        return
    end

    local tExteriorList = self.curView:BuildExteriorListFromPreview(nType, nClass or 0)

    if overridePendantID and overridePendantID > 0 and nType == COIN_SHOP_GOODS_TYPE.ITEM then
        local nEquipSub = CoinShop_RewardsClassToSub(nClass or 0)
        if nEquipSub then
            local tbSubs = { Exterior_SubToRepresentSub(nEquipSub) }
            if nEquipSub == EQUIPMENT_SUB.HEAD_EXTEND then
                local nSub1 = Exterior_BoxIndexToRepresentSub(COINSHOP_BOX_INDEX.HEAD_EXTEND1)
                local nSub2 = Exterior_BoxIndexToRepresentSub(COINSHOP_BOX_INDEX.HEAD_EXTEND2)
                if nSub1 then table.insert(tbSubs, nSub1) end
                if nSub2 then table.insert(tbSubs, nSub2) end
            end
            for _, nSub in ipairs(tbSubs) do
                if nSub then
                    tExteriorList[nSub] = { overridePendantID }
                end
            end
        end
    end

    -- 从外观列表取第一个有效 ID 和 key 类型，用于获取标题
    -- 特效类型 key 为 string（如 "Footprint"），非特效为 number
    local dwGoodsID, bEffectType
    for nKey, tIds in pairs(tExteriorList) do
        if type(tIds) == "table" and tIds[1] and tIds[1] > 0 then
            dwGoodsID = tIds[1]
            bEffectType = (type(nKey) == "string")
            break
        end
    end

    if (not dwGoodsID or dwGoodsID <= 0) then
        self.scriptRecommend:ShowEmpty()
        if self.scriptRecommend.LabelDescibe01 then
            UIHelper.SetString(self.scriptRecommend.LabelDescibe01, "请先在左侧列表选择外观")
        end
        return
    end

    local szTitleName = ""
    if dwGoodsID then
        if bEffectType then
            local tInfo = Table_GetPendantEffectInfo(dwGoodsID)
            szTitleName = (tInfo and tInfo.szName) or ""
        else
            szTitleName = ShareExteriorData.GetExteriorName(nType, dwGoodsID) or ""
        end
    end
    if not table.is_empty(tExteriorList) then
        self.scriptRecommend:Open(tExteriorList, szTitleName)
    else
        self.scriptRecommend:ShowEmpty()
    end
end

function UICoinShopMainView:OpenRecommendByGoods(eGoodsType, dwGoodsID)
    if not self.scriptRecommend or not UIHelper.GetVisible(self.WidgetRecommend) then
        return
    end

    local szTitleName = ShareExteriorData.GetExteriorName(eGoodsType, dwGoodsID) or ""
    if eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then
        local tRewardsLine = Table_GetRewardsItem(dwGoodsID)
        if tRewardsLine then
            self:OpenRecommendByItem(tRewardsLine.dwTabType, tRewardsLine.dwIndex, szTitleName)
            return
        else
            self:RefreshRecommendByCurrentTitle()
            return
        end
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
        local nClass = ShareExteriorData.GetExteriorClass(dwGoodsID)
        if nClass then
            local tExteriorList = self:BuildExteriorListByClass(nClass)
            if not table.is_empty(tExteriorList) then
                self.scriptRecommend:Open(tExteriorList, szTitleName)
            else
                self.scriptRecommend:ShowEmpty()
            end
            return
        end
    elseif eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR
        or eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR then
        -- 发型和武器外观：委托给当前 View 的通用刷新
        if self.curView and self.curView.RefreshShareStationRecommend then
            self.curView:RefreshShareStationRecommend(eGoodsType, dwGoodsID)
        end
        return
    end
    self.scriptRecommend:ShowEmpty()
end

function UICoinShopMainView:OpenRecommendByItem(dwTabType, dwIndex, szTitleName)
    if not self.scriptRecommend or not UIHelper.GetVisible(self.WidgetRecommend) then
        return
    end

    local hItemInfo = GetItemInfo(dwTabType, dwIndex)
    if not hItemInfo then
        self.scriptRecommend:ShowEmpty()
        return
    end

    local nType, nClass

    -- 特效类型：通过称号前缀/后缀获取特效 ID 和类型
    local nEffectID
    if hItemInfo.nPrefix and hItemInfo.nPrefix ~= 0 then
        local tPrefix = GetDesignationPrefixInfo(hItemInfo.nPrefix)
        nEffectID = tPrefix and tPrefix.dwSFXID
    elseif hItemInfo.nPostfix and hItemInfo.nPostfix ~= 0 then
        local tPostfix = GetDesignationPostfixInfo(hItemInfo.nPostfix)
        nEffectID = tPostfix and tPostfix.dwSFXID
    end
    if nEffectID and nEffectID > 0 then
        local tEffectInfo = Table_GetPendantEffectInfo(nEffectID)
        if tEffectInfo and tEffectInfo.szType then
            local nSfxType = CharacterEffectData.GetLogicTypeByEffectType(tEffectInfo.szType)
            local szEffectType = ShareExteriorData.GetEffectTypeBySub(nSfxType)
            if szEffectType then
                local tExteriorList = { [szEffectType] = { nEffectID } }
                local szName = tEffectInfo.szName or szTitleName or ""
                self.scriptRecommend:Open(tExteriorList, szName)
                return
            end
        end
    end

    -- 挂件类型：通过 EquipSub 反查 RewardsClass
    local nPendantType = GetPendantTypeByEquipSub(hItemInfo.nSub)
    if nPendantType then
        nClass = CoinShop_SubToRewardsClass(hItemInfo.nSub)
        if nClass then
            nType = COIN_SHOP_GOODS_TYPE.ITEM
        end
    end

    if not nType and hItemInfo.nGenre == ITEM_GENRE.COIN_SHOP_QUANTITY_LIMIT_ITEM then
        if hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HAIR then
            szTitleName = hItemInfo.szName
            nType = COIN_SHOP_GOODS_TYPE.HAIR
            nClass = 0
        elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.EXTERIOR then
            local dwExteriorID = hItemInfo.nDetail
            if dwExteriorID and dwExteriorID > 0 then
                nClass = ShareExteriorData.GetExteriorClass(dwExteriorID)
                if nClass then
                    nType = COIN_SHOP_GOODS_TYPE.EXTERIOR
                end
            end
            szTitleName = hItemInfo.szName
        elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PENDENT then
            local dwDetail = hItemInfo.nDetail
            local hPendant = (dwDetail and dwDetail > 0) and GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwDetail)
            local nRepresentSub = hPendant and ExteriorView_GetRepresentSub(hPendant.nSub, hPendant.nDetail)
            local nBoxIndex = nRepresentSub and Exterior_RepresentToBoxIndex(nRepresentSub)
            local nEquipSub = nBoxIndex and Exterior_BoxIndexToSub(nBoxIndex)
            if not nEquipSub and nRepresentSub and (nRepresentSub == EQUIPMENT_REPRESENT.HEAD_EXTEND1 or nRepresentSub == EQUIPMENT_REPRESENT.HEAD_EXTEND2) then
                nEquipSub = EQUIPMENT_SUB.HEAD_EXTEND
            end
            nClass = nEquipSub and CoinShop_SubToRewardsClass(nEquipSub)
            if nClass then
                nType = COIN_SHOP_GOODS_TYPE.ITEM
            end
            szTitleName = hItemInfo.szName
        elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PENDENT_PET then
            nType = COIN_SHOP_GOODS_TYPE.ITEM
            nClass = REWARDS_CLASS.CLOTH_PENDANT_PET
            szTitleName = hItemInfo.szName
        elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PACK then
            local tExteriorList = self:BuildPackExteriorList(hItemInfo.nDetail)
            if tExteriorList and not table.is_empty(tExteriorList) then
                self.scriptRecommend:Open(tExteriorList, hItemInfo.szName)
            else
                self.scriptRecommend:ShowEmpty()
            end
            return
        end
    end

    if not nType then
        local dwExteriorID = CoinShop_GetExteriorIDByItemInfo(hItemInfo)
        if dwExteriorID and dwExteriorID > 0 then
            nClass = ShareExteriorData.GetExteriorClass(dwExteriorID)
            if nClass then
                nType = COIN_SHOP_GOODS_TYPE.EXTERIOR
            end
        end
    end

    if nType and nClass then
        local tExteriorList
        if nType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
            tExteriorList = self:BuildExteriorListByClass(nClass)
        elseif self.curView and self.curView.BuildExteriorListFromPreview then
            tExteriorList = self.curView:BuildExteriorListFromPreview(nType, nClass)
        end
        if tExteriorList and not table.is_empty(tExteriorList) then
            self.scriptRecommend:Open(tExteriorList, szTitleName or hItemInfo.szName or "")
        else
            self.scriptRecommend:ShowEmpty()
        end
    else
        self.scriptRecommend:ShowEmpty()
    end
end

function UICoinShopMainView:BuildExteriorListByClass(nClass)
    local tExteriorList = {}
    local tRoleViewData = ExteriorCharacter.GetRoleData()
    if not tRoleViewData then
        return tExteriorList
    end

    local tbAllBoxIndices = {
        COINSHOP_BOX_INDEX.HELM, COINSHOP_BOX_INDEX.CHEST,
        COINSHOP_BOX_INDEX.BANGLE, COINSHOP_BOX_INDEX.WAIST,
        COINSHOP_BOX_INDEX.BOOTS, COINSHOP_BOX_INDEX.CHEST_EX,
        COINSHOP_BOX_INDEX.BOOTS_EX, COINSHOP_BOX_INDEX.PANTS_EX,
    }

    for _, nIndex in ipairs(tbAllBoxIndices) do
        local tData = tRoleViewData[nIndex]
        if tData and tData.dwID and tData.dwID > 0 then
            local nPreviewClass = ShareExteriorData.GetExteriorClass(tData.dwID)
            if nPreviewClass == nClass then
                local nSub = Exterior_BoxIndexToRepresentSub(nIndex)
                if nSub then
                    tExteriorList[nSub] = { tData.dwID }
                end
            end
        end
    end
    return tExteriorList
end

function UICoinShopMainView:BuildPackExteriorList(nPackID)
    return ShareExteriorData.BuildPackExteriorList(nPackID)
end

function UICoinShopMainView:GetScene()
    return self.m_scene
end


return UICoinShopMainView