-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopBuildFacePage
-- Date: 2023-09-07 14:35:25
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopBuildFacePage = class("UICoinShopBuildFacePage")

local PageListType = {
    ["FaceOld"] = 1,
    ["Face"]    = 2,
}

local PageType = {
    ["Face"]        = 1,
    ["Makeup"]      = 2,
    ["Hair"]        = 3,
    ["Body"]        = 4,
    ["Prefab"]      = 5,
    ["FaceOld"]     = 6,
    ["MakeupOld"]   = 7,
    ["Recommend"]   = 8,
}

local PageTogConfig = {
    {
        {szName = "发现", szIcon = "UIAtlas2_NieLian_CoinFace_FaceTab1_IconFaceRecommend", nPageType = PageType.Recommend, },
        {szName = "面容", szIcon = "UIAtlas2_NieLian_CoinFace_FaceTab1_IconFace", nPageType = PageType.FaceOld, },
        {szName = "妆容", szIcon = "UIAtlas2_NieLian_CoinFace_FaceTab1_IconMakeUp", nPageType = PageType.MakeupOld, },
        -- {szName = "发型", szIcon = "UIAtlas2_NieLian_CoinFace_FaceTab1_IconFace", nPageType = PageType.Hair, },
        {szName = "体型", szIcon = "UIAtlas2_NieLian_CoinFace_FaceTab1_IconBody", nPageType = PageType.Body, },
    },
    {
        {szName = "发现", szIcon = "UIAtlas2_NieLian_CoinFace_FaceTab1_IconFaceRecommend", nPageType = PageType.Recommend, },
        {szName = "预设", szIcon = "UIAtlas2_NieLian_CoinFace_FaceTab1_IconDefault", nPageType = PageType.Prefab, },
        {szName = "面容", szIcon = "UIAtlas2_NieLian_CoinFace_FaceTab1_IconFace", nPageType = PageType.Face, },
        {szName = "妆容", szIcon = "UIAtlas2_NieLian_CoinFace_FaceTab1_IconMakeUp", nPageType = PageType.Makeup, },
        -- {szName = "发型", szIcon = "UIAtlas2_NieLian_CoinFace_FaceTab1_IconFace", nPageType = PageType.Hair, },
        {szName = "体型", szIcon = "UIAtlas2_NieLian_CoinFace_FaceTab1_IconBody", nPageType = PageType.Body, },
    },
}

local DECORATION_ARENA_ID = 5
function UICoinShopBuildFacePage:OnEnter(nRoleType, nKungfuID, bPrice)
    if not self.bInit then
        self.nCurSelectPageListIndex = PageListType.Face
        self.nCurSelectPageIndex = PageType.Recommend
        local bIsNewFace = ExteriorCharacter.IsNewFace()
        local bIsUseLiftedFace = ExteriorCharacter.IsUseLiftedFace()
        if not bIsNewFace and bIsUseLiftedFace then
            self.nCurSelectPageListIndex = PageListType.FaceOld
            self.nCurSelectPageIndex = PageType.FaceOld
        elseif not bIsUseLiftedFace then
            self.nCurSelectPageIndex = PageType.Prefab
        end

        self.nCurSelectClass1Index = 1
        self.nCurSelectClass2Index = 1
        self.nCurSelectClass3Index = 1
        self.nCurSelectClass4Index = 1

        if self.nCurSelectPageIndex == PageType.FaceOld then
            self.nCurSelectClass1Index = 0
        end

        if self.nCurSelectPageIndex == PageType.Face then
            self.nCurSelectClass2Index = 0
        end

        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        UIHelper.WidgetFoceDoAlign(self)

        self:InitCurrency()
        self:InitPageTogList()
    end

    local bChange = false
    if self.bUseNew == nil then
        self.bUseNew = false
    end

    if self.nKungfuID == nil or self.nKungfuID ~= nKungfuID then
        self.nKungfuID = nKungfuID
        bChange = true
    end

    if self.nRoleType == nil or self.nRoleType ~= nRoleType then
        self.nRoleType = nRoleType
        bChange = true
    end

    if bChange then
        self:UpdateInfo()
    end

    self:UpdateBtnState()
    self:UpdateCameraState()
end

function UICoinShopBuildFacePage:OnExit()
    self.bInit = false

    local ModleView = ExteriorCharacter.GetModel("CoinShop_View", "CoinShop")
    if ModleView then
        ModleView:EndReshape()
        ModleView:EndFaceHighlightMgr()
    end
end

function UICoinShopBuildFacePage:BindUIEvent()
    self.scriptScrollViewTab2 = UIHelper.GetBindScript(self.WidgetList2)
    self.scriptScrollViewTab3 = UIHelper.GetBindScript(self.WidgetList3)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(VIEW_ID.PanelExteriorMain)
    end)

    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function(btn)
        Event.Dispatch(EventType.OnCoinShopClickBuyBtn)
    end)

    UIHelper.BindUIEvent(self.BtnTopUp, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelTopUpMain)
    end)

    UIHelper.BindUIEvent(self.BtnPrint, EventType.OnClick, function ()
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

    UIHelper.BindUIEvent(self.BtnInput, EventType.OnClick, function ()
        if Platform.IsWindows() and GetOpenFileName then
            local szFile = GetOpenFileName(g_tStrings.STR_NEW_FACE_LIFT_CHOOSE_FILE, g_tStrings.STR_FACE_LIFT_CHOOSE_INI .. "(*.ini)\0*.ini\0\0")
            Timer.AddFrame(self, 1, function ()
                if not string.is_nil(szFile) then
                    self:LoadFaceData(szFile)
                end
            end)
        else
            UIMgr.Open(VIEW_ID.PanelFacePrintLocal, function (szFile)
                if not Platform.IsWindows() then
                    szFile = UIHelper.UTF8ToGBK(GetFullPath(szFile))
                end
                self:LoadFaceData(szFile)
            end)
        end
    end)

    UIHelper.BindUIEvent(self.BtnAddBuildBodyTimes, EventType.OnClick, function ()
        local tLine = CoinShopData.GetBuyBodyCountItem()
        if tLine then
            local tInfo = CoinShop_GetPriceInfo(tLine.dwGoodsID, COIN_SHOP_GOODS_TYPE.ITEM)
            local bDis, szDisCount = CoinShop_GetDisInfo(tInfo)
            local nPrice, nOriginalPrice = CoinShop_GetShowPrice(tInfo)
            local szName = CoinShop_GetGoodsName(eGoodsType, dwGoodsID)
            local szMsg = FormatString(g_tStrings.COINSHOP_BODY_BUY_COUNT, nPrice, szName, tLine.nCount)

            szMsg = ParseTextHelper.ParseNormalText(szMsg, false)
            UIHelper.ShowConfirm(szMsg, function ()
                CoinShop_BuyItem(tLine.dwGoodsID, COIN_SHOP_GOODS_TYPE.ITEM, 1)
            end, nil, true)

            return true
        else
            OutputMessage("MSG_ANNOUNCE_NORMAL", "暂无法购买体型次数")
        end
    end)

    UIHelper.BindUIEvent(self.BtnRevert, EventType.OnClick, function ()
        if self.nCurSelectPageIndex == PageType.Face then
            if not self.tbClassConfig then
                return
            end

            local tbConfig1 = self.tbClassConfig[self.nCurSelectClass1Index]
            if not tbConfig1 then
                return
            end

            local tbConfig2 = tbConfig1[self.nCurSelectClass2Index]
            if not tbConfig2 then
                return
            end

            local szMessage = FormatString(g_tStrings.STR_NEW_FACE_RESET_SKE_MSG, UIHelper.GBKToUTF8(tbConfig2.szClassName))
            UIHelper.ShowConfirm(szMessage, function ()
                BuildFaceData.InitBoneClass(tbConfig2)
                self:UpdateInfo()
            end)
        elseif self.nCurSelectPageIndex == PageType.Makeup then
            local tData         = BuildFaceData.GetDefaultFaceData()
            if self.bDecoration then
                BuildFaceData.tNowFaceData.tDecoration = clone(tData.tDecoration)
            else
                if not self.tbClassConfig then
                    return
                end

                local tbConfig1 = self.tbClassConfig[self.nCurSelectClass1Index]
                if not tbConfig1 then
                    return
                end

                local tbConfig2 = tbConfig1[self.nCurSelectClass2Index]
                if not tbConfig2 then
                    return
                end

                for _, tInfo in ipairs(tbConfig2) do
                    local nDecalsType = tInfo.nDecalsType
                    BuildFaceData.tNowFaceData.tDecal[nDecalsType] = tData.tDecal[nDecalsType]
                    BuildFaceData.CopyRightType(nDecalsType)
                end
            end

            self:UpdateInfo()
        end
    end)

    UIHelper.BindUIEvent(self.BtnRevertAll, EventType.OnClick, function ()
        if self.nCurSelectPageIndex == PageType.Face or
            self.nCurSelectPageIndex == PageType.Makeup or
            self.nCurSelectPageIndex == PageType.Prefab or
            self.nCurSelectPageIndex == PageType.Recommend then
            UIHelper.ShowConfirm(g_tStrings.STR_NEW_FACE_RESET_MSG, function ()
                ExteriorCharacter.InitFace(true)
                BuildFaceData.ReInitDefaultData()
                FireUIEvent("RESET_NEW_FACE")
                FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
                self:OnChangePageList(PageListType.Face)
                self:UpdateInfo()
            end)
        elseif self.nCurSelectPageIndex == PageType.FaceOld or
            self.nCurSelectPageIndex == PageType.MakeupOld then
            UIHelper.ShowConfirm(g_tStrings.FACE_RESET_MSG, function ()
                ExteriorCharacter.InitFace(true)
                BuildFaceData.ReInitDefaultData()
                FireUIEvent("RESET_FACE")
                FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
                self:OnChangePageList(PageListType.FaceOld)
                self:UpdateInfo()
            end)
        elseif self.nCurSelectPageIndex == PageType.Body then
            UIHelper.ShowConfirm(g_tStrings.STR_BODY_RESET_MSG, function ()
                BuildBodyData.ResetBodyData()
                self:UpdateInfo()
            end)
        end
    end)

    UIHelper.BindUIEvent(self.BtnPriceChange, EventType.OnClick, function(btn)
        self.bUseNew = not self.bUseNew
        self:UpdatePriceInfo()
    end)

    UIHelper.BindUIEvent(self.TogList3LeftRight, EventType.OnClick, function()
        BuildFaceData.SetMeanwhileSwitch(self.nCurMeanwhile, UIHelper.GetSelected(self.TogList3LeftRight))
    end)

    UIHelper.BindUIEvent(self.TogNieLianCoin_Vision, EventType.OnClick, function(btn)
        local nPageType = PageListType.Face
        if not UIHelper.GetSelected(self.TogNieLianCoin_Vision) then
            nPageType = PageListType.FaceOld
        end
        self:OnChangePageList(nPageType)
    end)

    UIHelper.BindUIEvent(self.BtnFreeFaceShowTips, EventType.OnClick, function(btn)
        local hPlayer = GetClientPlayer()
        local nCount, nLimitCount, nFreeChanceEndTime = hPlayer.GetFaceLiftFreeChanceV2()
        if self.nCurSelectPageListIndex == PageListType.FaceOld then
            nCount, nLimitCount, nFreeChanceEndTime = hPlayer.GetFaceLiftFreeChance()
        end
        local tData = TimeToDate(nFreeChanceEndTime)
        local szHour = string.format("%02d", tData.hour)
        local szMinute = string.format("%02d", tData.minute)
        local szTips = string.format("限时时间:%s", FormatString(g_tStrings.STR_TIME_4, tData.year, tData.month, tData.day, szHour, szMinute))
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetRichTextTips, self.BtnFreeFaceShowTips, TipsLayoutDir.BOTTOM_CENTER, szTips)
    end)
    UIHelper.SetTouchDownHideTips(self.BtnFreeFaceShowTips, false)

    UIHelper.BindUIEvent(self.BtnFreeBodyShowTips, EventType.OnClick, function(btn)
        local hPlayer = GetClientPlayer()
        local nFreeCount, nTimeLimitFreeChance, nTimeLimitFreeChanceEndTime = hPlayer.GetBodyReshapingFreeChance()

        local tData = TimeToDate(nTimeLimitFreeChanceEndTime)
        local szHour = string.format("%02d", tData.hour)
        local szMinute = string.format("%02d", tData.minute)
        local szTips = string.format("限时时间:%s", FormatString(g_tStrings.STR_TIME_4, tData.year, tData.month, tData.day, szHour, szMinute))
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetRichTextTips, self.BtnFreeBodyShowTips, TipsLayoutDir.BOTTOM_CENTER, szTips)
    end)
    UIHelper.SetTouchDownHideTips(self.BtnFreeBodyShowTips, false)

    UIHelper.BindUIEvent(self.BtnChangeSide, EventType.OnClick, function(btn)
        if self.nCurSelectPageIndex ~= PageType.MakeupOld then
            return
        end

        local bChangeSide = not BuildFaceData.GetChangeSide()
        BuildFaceData.SetChangeSide(bChangeSide)

        local tbConfig1 = self.tbClassConfig[self.nCurSelectClass1Index]
        if not tbConfig1 then
            return
        end

        local nType = tbConfig1.dwClassID
        local tDecal = BuildFaceData.tNowFaceData.tFaceData.tDecal[nType]
        local nShowID = tDecal.nShowID
        if not bChangeSide then
            nShowID = Table_BeFliped(BuildFaceData.nRoleType, nType, nShowID)
        end
        if bChangeSide then
            local tUIInfo = Table_GetDecal(BuildFaceData.nRoleType, nType, nShowID)
            nShowID = tUIInfo.nFlipID
        end

        BuildFaceData.UpdateNowOldFaceDecal(nType, nShowID)
        Event.Dispatch(EventType.OnChangeBuildOldMakeupPrefab)
    end)

    UIHelper.BindUIEvent(self.BtnFaceStation, EventType.OnClick, function ()
        -- if not ShareStationData.GetOpenState() then
        --     TipsHelper.ShowNormalTip("部分功能升级维护中，商城设计站暂未开放")
        --     return
        -- end
        local nDataType = self.nCurSelectPageIndex == PageType.Body and SHARE_DATA_TYPE.BODY or SHARE_DATA_TYPE.FACE
        Event.Dispatch(EventType.OnOpenShareStation, nDataType)
    end)
end

function UICoinShopBuildFacePage:RegEvent()
    Event.Reg(self, EventType.OnUpdateBuildFaceModle, function ()
        local bIsNewFace = ExteriorCharacter.IsNewFace()
        local ModleView = ExteriorCharacter.GetModel("CoinShop_View", "CoinShop")
        if bIsNewFace then
            ModleView:SetFaceDefinition(BuildFaceData.tNowFaceData.tBone, self.nRoleType, BuildFaceData.tNowFaceData.tDecal, BuildFaceData.tNowFaceData.tDecoration, true)
            ExteriorCharacter.PreviewNewFace(nil, BuildFaceData.tNowFaceData, false)
        else
            ModleView:SetFaceDefinition(BuildFaceData.tNowFaceData.tFaceData.tBone, self.nRoleType, BuildFaceData.tNowFaceData.tFaceData.tDecal, BuildFaceData.tNowFaceData.tFaceData.nDecorationID, false)
            local tRepresentID = ExteriorCharacter.GetRoleRes()
            -- local nFaceID = tRepresentID[EQUIPMENT_REPRESENT.FACE_STYLE]
            ExteriorCharacter.PreviewFace(nil, true, BuildFaceData.tNowFaceData, true, false)
        end

        self:UpdateBuyBtnState()
        self:UpdatePriceInfo()
    end)

    Event.Reg(self, EventType.OnUpdateBuildBodyModle, function (nBodyPage)
        local ModleView = ExteriorCharacter.GetModel("CoinShop_View", "CoinShop")
        ModleView:SetBodyReshapingParams(BuildBodyData.tNowBodyData)
        ExteriorCharacter.PreviewBody(nil, BuildBodyData.tNowBodyData, true)
        if nBodyPage then
            self:OnClickPageTog(nBodyPage)
        end
        self:UpdateBuyBtnState()
        self:UpdatePriceInfo()
    end)

    Event.Reg(self, EventType.OnUpdateBuildHairModle, function ()
        local nHairID = BuildHairData.GetSelectedHairStyle()
        ExteriorCharacter.PreviewHair(nHairID, nil, true, true, false)
        self:UpdateBuyBtnState()
        self:UpdatePriceInfo()
    end)

    Event.Reg(self, EventType.OnChangeBuildFaceDefault, function (bChangeNewFace)
        if self.nCurSelectPageIndex == PageType.Face then
            self:UpdateModleInfo()
        elseif self.nCurSelectPageIndex == PageType.Prefab then
            self:UpdatePrefabRightInfo(true)
            self:UpdateModleInfo()
        elseif self.nCurSelectPageIndex == PageType.FaceOld then
            self:UpdateModleInfo()
        end

        if bChangeNewFace then
            self:UpdateRoleModel()
        end
    end)

    Event.Reg(self, EventType.OnChangeBuildFaceSubPrefab, function ()
        if self.nCurSelectPageIndex == PageType.Face then
            self:UpdateFaceDefaultRightInfo(true)
            self:UpdateModleInfo()
        end
    end)

    Event.Reg(self, EventType.OnChangeBuildFaceAttribSliderValueBegin, function (tbInfo, nValue)
        if self.nCurSelectPageIndex == PageType.Face then
            self:EnableFaceHighlight(true, tbInfo.nBoneType)
        elseif self.nCurSelectPageIndex == PageType.Body then
            self:EnableBodyHighlight(true, tbInfo.nBodyType)
        end
    end)

    Event.Reg(self, EventType.OnChangeBuildFaceAttribSliderValueEnd, function (tbInfo, nValue)
        if self.nCurSelectPageIndex == PageType.Face then
            self:EnableFaceHighlight(false, tbInfo.nBoneType)
        elseif self.nCurSelectPageIndex == PageType.Body then
            self:EnableBodyHighlight(false, tbInfo.nBodyType)
        end
    end)

    Event.Reg(self, EventType.OnChangeBuildFaceAttribSliderValue, function (tbInfo, nValue)
        if self.nCurSelectPageIndex == PageType.Face then
            BuildFaceData.tNowFaceData.tBone[tbInfo.nBoneType] = nValue
            self:UpdateModleInfo()
        elseif self.nCurSelectPageIndex == PageType.FaceOld then
            BuildFaceData.tNowFaceData.tFaceData.tBone[tbInfo[1]] = nValue
            self:UpdateModleInfo()
        elseif self.nCurSelectPageIndex == PageType.Body then
            BuildBodyData.tNowBodyData[tbInfo.nBodyType] = nValue
            self:UpdateModleInfo()
        end
    end)

    Event.Reg(self, EventType.OnChangeBuildMakeupPrefab, function ()
        if self.nCurSelectPageIndex == PageType.Makeup then
            self:UpdateMakeupRightInfo(true)
            self:UpdateDetailBtnState()
            self:UpdateModleInfo()
        end
    end)

    Event.Reg(self, EventType.OnChangeBuildOldMakeupPrefab, function ()
        if self.nCurSelectPageIndex == PageType.MakeupOld then
            self:UpdateOldMakeupRightInfo(true)
            self:UpdateOldDetailBtnState()
            self:UpdateModleInfo()
        end
    end)

    Event.Reg(self, EventType.OnChangeBuildOldMakeupDecoration, function ()
        if self.nCurSelectPageIndex == PageType.MakeupOld then
            self:UpdateOldMakeupDecorationRightInfo(true)
            self:OpenOldDetailAdjustView(false)

            if GetFaceLiftManager() then
                local nDecorationShow = BuildFaceData.tNowFaceData.tFaceData.nDecorationID
                local bShowFlag = GetFaceLiftManager().GetDecorationShowFlag()
                if not bShowFlag then
                    nDecorationShow = 0
                    TipsHelper.ShowNormalTip(g_tStrings.FACE_LIFT_DECORATION_HIDE)
                end

                local ModleView = ExteriorCharacter.GetModel("CoinShop_View", "CoinShop")
                ModleView:SetFacePartID(nDecorationShow, false, self.nRoleType)
            end

            self:UpdateModleInfo()
        end
    end)

    Event.Reg(self, EventType.OnChangeBuildMakeupValue, function ()
        if self.nCurSelectPageIndex == PageType.Makeup then
            self:UpdateMakeupRightInfo(true)
            self:UpdateModleInfo()
        end
    end)

    Event.Reg(self, EventType.OnChangeBuildOldMakeupValue, function ()
        if self.nCurSelectPageIndex == PageType.MakeupOld then
            self:UpdateOldMakeupRightInfo(true)
            self:UpdateModleInfo()
        end
    end)

    Event.Reg(self, EventType.OnChangeBuildMakeupColor, function (nType, nShowID, nColorID)
        if self.nCurSelectPageIndex == PageType.Makeup then
            self:UpdateModleInfo()
        end
    end)

    Event.Reg(self, EventType.OnChangeBuildOldMakeupColor, function (nType, nShowID, nColorID)
        if self.nCurSelectPageIndex == PageType.MakeupOld then
            self:UpdateModleInfo()
        end
    end)

    Event.Reg(self, EventType.OnChangeBuildHairValue, function (nClassIndex)
        if self.nCurSelectPageIndex == PageType.Hair then
            self:UpdateModleInfo()
            if nClassIndex == 1 then
                self:UpdateClass1Info()
            end
        end
    end)

    Event.Reg(self, EventType.OnChangeBuildBodyDefault, function ()
        if self.nCurSelectPageIndex == PageType.Body then
            self:UpdateModleInfo()
        end
    end)

    Event.Reg(self, EventType.OnCoinShopShowBuildFaceSideTog, function(bShow, nMeanwhile)
        self:ShowBuildFaceSyncSideTog(bShow, nMeanwhile)
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

    Event.Reg(self, "RESET_BODY", function ()
        BuildBodyData.ResetBodyData()
        ExteriorCharacter.InitBody()
    end)

    Event.Reg(self, "COINSHOP_INIT_ROLE", function ()
        self.nCurSelectPageIndex = PageType.Face
        local tData = ExteriorCharacter.GetPreviewNewFace() or {}
        if table.is_empty(tData) then
            self.nCurSelectPageIndex = PageType.Prefab
        end

        self.nCurSelectClass1Index = 1
        self.nCurSelectClass2Index = 1
        self.nCurSelectClass3Index = 1
        UIHelper.SetToggleGroupSelected(self.TogGroupPage, self.nCurSelectPageIndex - 1)

        BuildFaceData.InitDefaultData()
        BuildBodyData.GetNowBodyData()
        BuildBodyData.UpdateMybodyData()
        BuildHairData.ReloadSelectedHair()

        self:OnChangePageList(self.nCurSelectPageListIndex)
        self:UpdateInfo()
    end)

    Event.Reg(self, "FACE_LIFT_NOTIFY", function ()
        if arg0 == FACE_LIFT_ERROR_CODE.BUY_SUCCESS then
            local hPlayer = GetClientPlayer()
            if not hPlayer then
                return
            end
            local tFace = hPlayer.GetEquipLiftedFaceData()
            if tFace and tFace.bNewFace then
                self:RefeshNewFace()
            else
                -- CoinShop_HairShop.RefeshLiftFace(this)
            end

            self:UpdateBuyBtnState()
            self:UpdatePriceInfo()
        end
    end)

    Event.Reg(self, "MATCH_HAIR_PREVIEW_CHANGE", function ()
        self:OnMatchHairPreviewChange()
    end)

    Event.Reg(self, "ON_CHANGE_BODY_BONE_NOTIFY", function ()
        local nMethod = arg1
        if nMethod == BODY_RESHAPING_OPERATE_METHOD.ADD or
            nMethod == BODY_RESHAPING_OPERATE_METHOD.REPLACE then
            self:RefeshBody()
            self:UpdateBuyBtnState()
            self:UpdatePriceInfo()
            self:UpdateBtnState()
        end
    end)

    Event.Reg(self, "ON_EQUIP_BODY_BONE_NOTIFY", function ()
        self:RefeshBody()
        self:UpdateBuyBtnState()
        self:UpdatePriceInfo()
    end)

    Event.Reg(self, "COIN_SHOP_BUY_RESPOND", function (nErrorCode)
        if nErrorCode == COIN_SHOP_ERROR_CODE.SUCCESS then
            self:UpdateBtnState()
            self:UpdateBuyBtnState()
        end
    end)

    Event.Reg(self, "FACE_LIFT_FREE_CHANCE_CHANGE", function ()
        self:UpdateBtnState()
    end)

    Event.Reg(self, "ON_INIT_BODY", function (tBody)
        BuildBodyData.UpdateNowBodyData(tBody)
        self:UpdateBtnState()
        self:UpdateBuyBtnState()
    end)

    Event.Reg(self, EventType.OnDownloadShareCodeData, function (bSuccess, szShareCode, szFilePath, nDataType)
        if UIMgr.IsViewOpened(VIEW_ID.PanelCoinShopBuildDyeing) then
            return
        end

        if bSuccess and ShareCodeData.szCurGetShareCode == szShareCode then
            if nDataType == SHARE_DATA_TYPE.FACE then
                self:LoadFaceData(szFilePath)
            elseif nDataType == SHARE_DATA_TYPE.BODY then
                self:LoadBodyData(szFilePath)
            elseif nDataType == SHARE_DATA_TYPE.EXTERIOR then
                self:LoadExteriorData(szShareCode)
            end
        end
    end)

    Event.Reg(self, EventType.OnDownloadBodyCodeData, function (bSuccess, szCode, szFilePath)
        if bSuccess and BodyCodeData.szCurGetBodyCode == szCode then
            self:LoadBodyData(szFilePath)
        end
    end)
end

function UICoinShopBuildFacePage:InitCurrency()
    UIMgr.AddPrefab(PREFAB_ID.WidgetCoin, self.LayoutCurrency, CurrencyType.Coin, false, nil, true)
    self.RewardsScript = UIMgr.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.LayoutCurrency)
    self.RewardsScript:SetCurrencyType(CurrencyType.FaceVouchers)
    self:UpdateCurreny()
end

function UICoinShopBuildFacePage:UpdateCurreny()
    local nVouchars = GetFaceLiftManager().GetVouchers()
    if nVouchars > 0 then
        self.RewardsScript:SetLableCount(nVouchars)
        UIHelper.SetVisible(self.RewardsScript._rootNode, true)
    else
        UIHelper.SetVisible(self.RewardsScript._rootNode, false)
    end

    UIHelper.LayoutDoLayout(self.LayoutCurrency)
end

function UICoinShopBuildFacePage:InitPageTogList()
    local tbConfigs = PageTogConfig[self.nCurSelectPageListIndex]
    self.tbPageCells = self.tbPageCells or {}
    self.tbPageIndex2PageType = self.tbPageIndex2PageType or {}
    UIHelper.HideAllChildren(self.ScrollViewTab1)
    for i, tbConfig in ipairs(tbConfigs) do
        if not self.tbPageCells[i] then
            self.tbPageCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetTogNieLianCoin_Part, self.ScrollViewTab1)
        end

        self.tbPageCells[i]:OnEnter(tbConfig)
        self.tbPageIndex2PageType[i] = tbConfig.nPageType
        UIHelper.SetVisible(self.tbPageCells[i]._rootNode, true)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTab1)

    self:RegPageTog()
    UIHelper.SetSelected(self.TogNieLianCoin_Vision, self.nCurSelectPageListIndex == 2)
end

function UICoinShopBuildFacePage:RegPageTog()
    UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupPage)

    local tbConfigs = PageTogConfig[self.nCurSelectPageListIndex]
    for nIndex, tbConfig in ipairs(tbConfigs) do
        local tog = self.tbPageCells[nIndex].TogSelect
        UIHelper.BindUIEvent(tog, EventType.OnClick, function ()
            self:OnClickPageTog(tbConfig.nPageType)
        end)

        UIHelper.ToggleGroupAddToggle(self.TogGroupPage, tog)
        UIHelper.SetSwallowTouches(tog, false)
    end

    local nSelectIndex = table.get_key(self.tbPageIndex2PageType, self.nCurSelectPageIndex) or 1
    UIHelper.SetToggleGroupSelected(self.TogGroupPage, nSelectIndex - 1)
end

function UICoinShopBuildFacePage:UpdateInfo()
    self:UpdatePageTogInfo()
    self:UpdatePageInfo()
    self:UpdateClass1Info()
    self:UpdateClass2Info()
    self:UpdateRightInfo()

    self:UpdateModleInfo()
    self:UpdateBtnState()
    self:UpdateBuyBtnState()
    self:UpdatePriceInfo()
end

function UICoinShopBuildFacePage:UpdateModleInfo()
    local ModleView = ExteriorCharacter.GetModel("CoinShop_View", "CoinShop")
    if not ModleView then
        return
    end

    local bIsNewFace = ExteriorCharacter.IsNewFace()
    if self.nCurSelectPageIndex == PageType.Face or self.nCurSelectPageIndex == PageType.Prefab then
        if bIsNewFace then
            ModleView:SetFaceDefinition(BuildFaceData.tNowFaceData.tBone, self.nRoleType, BuildFaceData.tNowFaceData.tDecal, BuildFaceData.tNowFaceData.tDecoration, true)
            ExteriorCharacter.PreviewNewFace(nil, BuildFaceData.tNowFaceData, false)
        end
    elseif self.nCurSelectPageIndex == PageType.Makeup then
        if bIsNewFace then
            ModleView:SetFaceDecals(BuildFaceData.nRoleType, BuildFaceData.tNowFaceData.tDecal, true)
            ModleView:SetFacePartID(BuildFaceData.tNowFaceData.tDecoration, true, BuildFaceData.nRoleType)
            ExteriorCharacter.PreviewNewFace(nil, BuildFaceData.tNowFaceData, false)
        end
    elseif self.nCurSelectPageIndex == PageType.FaceOld then
        if not bIsNewFace then
            local tRepresentID = ExteriorCharacter.GetRoleRes()
            local nFaceID = tRepresentID[EQUIPMENT_REPRESENT.FACE_STYLE]
            local UserData = nil
            if tRepresentID.bUseLiftedFace and BuildFaceData.tNowFaceData then
                UserData = {}
                UserData.tFaceData = BuildFaceData.tNowFaceData.tFaceData
                UserData.nIndex = tRepresentID.nEquipIndex
                ModleView:SetFaceDefinition(BuildFaceData.tNowFaceData.tFaceData.tBone, self.nRoleType, BuildFaceData.tNowFaceData.tFaceData.tDecal, BuildFaceData.tNowFaceData.tFaceData.nDecorationID, false)
            end

            if tRepresentID.bUseLiftedFace then
                nFaceID = nil
            end

            ExteriorCharacter.PreviewFace(nFaceID, tRepresentID.bUseLiftedFace, UserData, true, false)
        end
    elseif self.nCurSelectPageIndex == PageType.MakeupOld then
        if not bIsNewFace then
            ModleView:SetFaceDecals(BuildFaceData.nRoleType, BuildFaceData.tNowFaceData.tFaceData.tDecal)
            local tRepresentID = ExteriorCharacter.GetRoleRes()
            -- local nFaceID = tRepresentID[EQUIPMENT_REPRESENT.FACE_STYLE]
            ExteriorCharacter.PreviewFace(nil, true, BuildFaceData.tNowFaceData, true, false)
        end
    elseif self.nCurSelectPageIndex == PageType.Hair then
        local nHairID = BuildHairData.GetSelectedHairStyle()
        ExteriorCharacter.PreviewHair(nHairID, nil, true, true, false)
    elseif self.nCurSelectPageIndex == PageType.Body then
        ModleView:SetBodyReshapingParams(BuildBodyData.tNowBodyData)
        ExteriorCharacter.PreviewBody(nil, BuildBodyData.tNowBodyData, true)
    elseif self.nCurSelectPageIndex == PageType.Recommend then
        if bIsNewFace then
            ModleView:SetFaceDefinition(BuildFaceData.tNowFaceData.tBone, self.nRoleType, BuildFaceData.tNowFaceData.tDecal, BuildFaceData.tNowFaceData.tDecoration, true)
            ExteriorCharacter.PreviewNewFace(nil, BuildFaceData.tNowFaceData, false)
        else
            local tRepresentID = ExteriorCharacter.GetRoleRes()
            local nFaceID = tRepresentID[EQUIPMENT_REPRESENT.FACE_STYLE]
            local UserData = nil
            if tRepresentID.bUseLiftedFace and BuildFaceData.tNowFaceData then
                UserData = {}
                UserData.tFaceData = BuildFaceData.tNowFaceData.tFaceData
                UserData.nIndex = tRepresentID.nEquipIndex
                ModleView:SetFaceDefinition(BuildFaceData.tNowFaceData.tFaceData.tBone, self.nRoleType, BuildFaceData.tNowFaceData.tFaceData.tDecal, BuildFaceData.tNowFaceData.tFaceData.nDecorationID, false)
            end

            if tRepresentID.bUseLiftedFace then
                nFaceID = nil
            end

            ExteriorCharacter.PreviewFace(nFaceID, tRepresentID.bUseLiftedFace, UserData, true, false)
        end
    end

    self:UpdateBuyBtnState()
    self:UpdatePriceInfo()
end

function UICoinShopBuildFacePage:UpdateRoleModel()
    ExteriorCharacter.SetViewPage("Role")
    local tRepresentID = clone(ExteriorCharacter.GetRoleRes())
    local bShowWeapon = ExteriorCharacter.IsWeaponShow()
    if not bShowWeapon then
        tRepresentID = clone(tRepresentID)
        tRepresentID[EQUIPMENT_REPRESENT.WEAPON_STYLE] = 0
        tRepresentID[EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] = 0
    end

    local player = GetClientPlayer()
    if player then
        if ShareStationData.bOpening then
            tRepresentID.tCustomRepresentData = tRepresentID.tCustomRepresentData or GetEquipCustomRepresentData(player)
        else
            local tCustomData = GetEquipCustomRepresentData(player)
            if tCustomData then
                tRepresentID.tCustomRepresentData = tCustomData
            end
        end
    end
    FireUIEvent("EXTERIOR_CHARACTER_UPDATE", "CoinShop_View", "CoinShop", tRepresentID, false, nil, nil)
end

function UICoinShopBuildFacePage:UpdatePageTogInfo()
    if not self.tbTogPage then return end

    if not CoinShop_CanChangeHair() then
        UIHelper.SetButtonState(self.tbTogPage[PageType.Hair], BTN_STATE.Disable, function ()
            TipsHelper.ShowNormalTip(g_tStrings.COINSHOP_HAIRSHOP_CAN_NOT_CHANGE)
            UIHelper.SetToggleGroupSelected(self.TogGroupPage, self.nCurSelectPageIndex - 1)
        end)
        if self.nCurSelectPageIndex == PageType.Hair then
            self.nCurSelectPageIndex = PageType.Face
            self.nCurSelectClass1Index = 1
            self.nCurSelectClass2Index = 1
            self.nCurSelectClass3Index = 1
        end
    else
        UIHelper.SetButtonState(self.tbTogPage[PageType.Hair], BTN_STATE.Normal)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTab1)
end

function UICoinShopBuildFacePage:UpdatePageInfo()
    self.tbClassConfig = nil
    if self.nCurSelectPageIndex == PageType.Face then
        local tFaceBoneList = BuildFaceData.tFaceBoneList
        self.tbClassConfig = Lib.copyTab(tFaceBoneList)
    elseif self.nCurSelectPageIndex == PageType.Makeup then
        local tFaceDecalList = BuildFaceData.tDecalClassList
        self.tbClassConfig = Lib.copyTab(tFaceDecalList)
    elseif self.nCurSelectPageIndex == PageType.FaceOld then
        local tFaceDecalList = BuildFaceData.tOldFaceBoneList
        self.tbClassConfig = Lib.copyTab(tFaceDecalList)
    elseif self.nCurSelectPageIndex == PageType.MakeupOld then
        local tFaceDecalList = BuildFaceData.tOldDecalClassList
        self.tbClassConfig = Lib.copyTab(tFaceDecalList)

        local tDecalList = Table_GetDecorationList(self.nRoleType)
        if tDecalList and #tDecalList > 0 then
            table.insert(self.tbClassConfig, {
                szName = UIHelper.UTF8ToGBK("装饰物"),
                dwClassID = -1,
            })
        end
    elseif self.nCurSelectPageIndex == PageType.Hair then
        local tHairClass = BuildHairData.GetCoinShopHairClass()
        self.tbClassConfig = Lib.copyTab(tHairClass)
    elseif self.nCurSelectPageIndex == PageType.Body then
        local tBodyList = Table_GetBodyBoneList(self.nRoleType)
        self.tbClassConfig = Lib.copyTab(tBodyList)
    elseif self.nCurSelectPageIndex == PageType.Prefab then
        local tFaceList = BuildFaceData.tFaceList
        self.tbClassConfig = Lib.copyTab(tFaceList)
    end
end

function UICoinShopBuildFacePage:UpdateClass1Info()
    if self.nCurSelectPageIndex == PageType.Prefab then
        return
    end

    if self.nCurSelectPageIndex == PageType.Recommend then
        return
    end

    if not self.tbClassConfig then
        return
    end

    local tbData = {}
    local nPrefabID1 = PREFAB_ID.WidgetCoinLeftTabCell
    local nPrefabID2 = PREFAB_ID.WidgetLeftTabCell_Tree_Coin

    if self.nCurSelectPageIndex == PageType.FaceOld
        or self.nCurSelectPageIndex == PageType.MakeupOld
        or self.nCurSelectPageIndex == PageType.Body then
        nPrefabID1 = PREFAB_ID.WidgetCoinTabCell_OldVision
    end

    -- 体型推荐，暂时先不上
    -- if self.nCurSelectPageIndex == PageType.Body then
    --     local tbClassConfig = {}
    --     if self.nCurSelectPageIndex == PageType.Body then
    --         tbClassConfig.szAreaName = UIHelper.UTF8ToGBK("发现")
    --     end

    --     table.insert(tbData, {
    --         tArgs = tbClassConfig,
    --         tItemList = {},
    --         fnSelectedCallback = function (bSelected)
    --             if bSelected then
    --                 self.nCurSelectClass1Index = -1
    --                 self.nCurSelectClass2Index = 1
    --                 self.nCurSelectClass3Index = 1
    --                 self:UpdateRightInfo()
    --                 self:UpdateBtnState()
    --             end
    --         end
    --     })
    -- end

    if self.nCurSelectPageIndex == PageType.Body or
        self.nCurSelectPageIndex == PageType.FaceOld  then
        local tbClassConfig = {}
        if self.nCurSelectPageIndex == PageType.Body then
            tbClassConfig.szAreaName = UIHelper.UTF8ToGBK("预设")
        elseif self.nCurSelectPageIndex == PageType.FaceOld then
            tbClassConfig.szName = UIHelper.UTF8ToGBK("写意脸型")
        end

        table.insert(tbData, {
            tArgs = tbClassConfig,
            tItemList = {},
            fnSelectedCallback = function (bSelected)
                if bSelected then
                    self.nCurSelectClass1Index = 0
                    self.nCurSelectClass2Index = 1
                    self.nCurSelectClass3Index = 1
                    self:UpdateRightInfo()
                    self:UpdateBtnState()
                end
            end
        })
    end

    for i, tbConfig in ipairs(self.tbClassConfig) do
        local bShow = true
        if bShow then
            local tbItemList = {}
            if self.nCurSelectPageIndex ~= PageType.Body and
                self.nCurSelectPageIndex ~= PageType.FaceOld and
                self.nCurSelectPageIndex ~= PageType.MakeupOld then
                if self.nCurSelectPageIndex == PageType.Face then
                    if not string.is_nil(tbConfig.szAreaDefault) then
                        local tbClass2Config = {}
                        tbClass2Config.szClassName = tbConfig.szDefaultName

                        local tbTempConfig = { tArgs = {tbClassConfig = tbClass2Config} }
                        tbTempConfig.tArgs.funcClickCallback = function (tbInfo, bIsClass1)
                            self.nCurSelectClass2Index = 0
                            self.nCurSelectClass3Index = 1
                            self:UpdateRightInfo()
                            self:UpdateBtnState()
                        end

                        table.insert(tbItemList, tbTempConfig)
                    end
                end

                local tbConfig2 = tbConfig
                if self.nCurSelectPageIndex == PageType.Hair then
                    tbConfig2 = BuildHairData.GetHairClass() or {}
                end
                for j, tbClass2Config in ipairs(tbConfig2) do
                    local bShow = true
                    if self.nCurSelectPageIndex == PageType.Hair then
                        local tbTempConfig = BuildHairData.GetHairConfigWithClassIndex(i, j)
                        if not tbTempConfig or #tbTempConfig <= 0 then
                            bShow = false
                        end
                    end

                    if bShow then
                        local tbTempConfig =  { tArgs = {tbClassConfig = tbClass2Config} }
                        tbTempConfig.tArgs.funcClickCallback = function (tbInfo, bIsClass1)
                            self.nCurSelectClass2Index = j
                            self.nCurSelectClass3Index = 1
                            self:UpdateRightInfo()
                            self:UpdateBtnState()
                        end
                        table.insert(tbItemList, tbTempConfig)
                    end
                end
            end

            tbConfig.bShowArrow = #tbItemList > 0
            table.insert(tbData, {
                tArgs = tbConfig,
                tItemList = tbItemList,
                fnSelectedCallback = function (bSelected)
                    if bSelected then
                        local bIsNewFace = ExteriorCharacter.IsNewFace()
                        local bIsUseLiftedFace = ExteriorCharacter.IsUseLiftedFace()
                        if (bIsNewFace or not bIsUseLiftedFace) and self.nCurSelectPageIndex == PageType.FaceOld then
                            self:OnClickPageTog(PageType.MakeupOld)
                            return
                        end

                        if self.nCurSelectPageIndex == PageType.Face then
                            BuildFaceData.GetAreaDefault(tbConfig.szAreaDefault)
                        end

                        UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupClass1)
                        local tbCells = self.scriptScrollViewTab2.tContainerList[i].scriptContainer:GetItemScript()
                        for nIndex, cell in ipairs(tbCells) do
                            cell:AddTogGroup(self.TogGroupClass1)
                        end
                        if self.nCurSelectPageIndex == PageType.Face then
                            self.nCurSelectClass2Index = 0
                        else
                            self.nCurSelectClass2Index = 1
                        end
                        UIHelper.SetToggleGroupSelected(self.TogGroupClass1, self.nCurSelectClass2Index - 1)
                        self.nCurSelectClass1Index = i
                        self.nCurSelectClass3Index = 1
                        self:UpdateClass2Info()
                        self:UpdateRightInfo()
                        self:UpdateBtnState()
                    end
                end
            })
        end
    end


    local func = function(scriptContainer, tArgs)
        local szName = UIHelper.GBKToUTF8(tArgs.szAreaName or tArgs.szName)

        local bDis = false
        local bNew = false
        if self.nCurSelectPageIndex ~= PageType.FaceOld and self.nCurSelectPageIndex ~= PageType.MakeupOld then
            local szImg = BuildFaceClassImg[szName]
            UIHelper.SetSpriteFrame(scriptContainer.ImgType, string.format("%s2.png", szImg))
            UIHelper.SetSpriteFrame(scriptContainer.ImgTypeSelected, string.format("%s1.png", szImg))
            UIHelper.SetVisible(scriptContainer.ImgArrow1, not not tArgs.bShowArrow)
            UIHelper.SetVisible(scriptContainer.ImgArrow2, not not tArgs.bShowArrow)

            local nLabel = tArgs.nLabel
            if tArgs.nAreaID == DECORATION_ARENA_ID  then
                nLabel = BuildFaceData.GetDecorationLabel()
            end
            if nLabel then
                if kmath.andOperator(nLabel, NEWFACE_LABEL.DISCOUNT) ~= 0 then
                    bDis = true
                elseif kmath.andOperator(nLabel, NEWFACE_LABEL.NEW) ~= 0 then
                    bNew = true
                end
            end
        elseif self.nCurSelectPageIndex == PageType.MakeupOld then
            if tArgs.dwClassID == -1 then
                local tDecalList = Table_GetDecorationList(self.nRoleType)
                if tDecalList then
                    local nLabel = BuildFaceData.GetOldDecorationLabel(tDecalList)
                    if nLabel == EXTERIOR_LABEL.NEW then
                        bNew = true
                    end
                end
            else
                local _, nLabel = BuildFaceData.GetOldDecalList(self.nRoleType, tArgs.dwClassID)
                if nLabel == EXTERIOR_LABEL.NEW then
                    bNew = true
                end
            end
        end

        local szPath = "UIAtlas2_Shopping_ShoppingIcon_img_new"
        if bDis then
            szPath = "UIAtlas2_Shopping_ShoppingIcon_img_discount"
        end
        UIHelper.SetString(scriptContainer.LabelTitle, szName)
        UIHelper.SetString(scriptContainer.LabelSelect, szName)
        UIHelper.SetVisible(scriptContainer.ImgNew, bNew or bDis)
        UIHelper.SetSpriteFrame(scriptContainer.ImgNew, szPath)

        if not scriptContainer.bAddToggleGroup then
            scriptContainer.bAddToggleGroup = true
            if self.nCurSelectPageIndex == PageType.FaceOld or
                self.nCurSelectPageIndex == PageType.MakeupOld or
                self.nCurSelectPageIndex == PageType.Body then

                UIHelper.ToggleGroupAddToggle(self.TogGroupClass2, scriptContainer.ToggleSelect)
            end
        end
    end

    UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupClass2)
    self.scriptScrollViewTab2:ClearContainer()
    self.scriptScrollViewTab2:SetOuterInitSelect()
    UIHelper.SetupScrollViewTree(self.scriptScrollViewTab2,
        nPrefabID1,
        nPrefabID2,
        func, tbData, true)

    local nCurSelectIndex1 = self.nCurSelectClass1Index
    if self.nCurSelectPageIndex == PageType.Body or
        self.nCurSelectPageIndex == PageType.FaceOld then
        nCurSelectIndex1 = nCurSelectIndex1 + 1
    end

    Timer.AddFrame(self, 1, function()
        local scriptContainer = self.scriptScrollViewTab2.tContainerList[nCurSelectIndex1].scriptContainer
        if scriptContainer and scriptContainer.SetSelected then
            scriptContainer:SetSelected(true)
        end

        if self.nCurSelectPageIndex == PageType.FaceOld or
            self.nCurSelectPageIndex == PageType.MakeupOld or
            self.nCurSelectPageIndex == PageType.Body then

            UIHelper.SetToggleGroupSelected(self.TogGroupClass2, nCurSelectIndex1 - 1)
        end
    end)
end

function UICoinShopBuildFacePage:UpdateClass2Info()
    -- UIHelper.HideAllChildren(self.ScrollViewTab3)

    -- if self.nCurSelectPageIndex == PageType.Body or self.nCurSelectPageIndex == PageType.Prefab then
    --     return
    -- end

    -- if not self.tbClassConfig then
    --     return
    -- end

    -- local tbConfig = self.tbClassConfig[self.nCurSelectClass1Index]

    -- if self.nCurSelectPageIndex == PageType.Hair then
    --     tbConfig = BuildHairData.GetHairClass()
    -- end

    -- if not tbConfig then
    --     return
    -- end

    -- self.tbClass2Cell = self.tbClass2Cell or {}
    -- if self.nCurSelectPageIndex == PageType.Face then
    --     if not string.is_nil(tbConfig.szAreaDefault) then
    --         BuildFaceData.GetAreaDefault(tbConfig.szAreaDefault)
    --         local tbClassConfig = Lib.copyTab(BuildFaceData.tBoneAreaDefault)
    --         tbClassConfig.szClassName = tbConfig.szDefaultName

    --         if not self.tbClass2Cell[0] then
    --             self.tbClass2Cell[0] = UIHelper.AddPrefab(PREFAB_ID.WidgetCoinLeftTabCell2, self.ScrollViewTab3)
    --             self.tbClass2Cell[0]:AddTogGroup(self.TogGroupClass2)
    --             self.tbClass2Cell[0]:SetClickCallback(function (tbInfo, bIsClass1)
    --                 self.nCurSelectClass2Index = 0
    --                 self.nCurSelectClass3Index = 1
    --                 self:UpdateRightInfo()
    --                 self:UpdateBtnState()
    --             end)
    --         end

    --         UIHelper.SetVisible(self.tbClass2Cell[0]._rootNode, true)
    --         self.tbClass2Cell[0]:OnEnter(tbClassConfig, false)
    --     end
    -- end

    -- for i, tbClass2Config in ipairs(tbConfig) do
    --     if not self.tbClass2Cell[i] then
    --         self.tbClass2Cell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetCoinLeftTabCell2, self.ScrollViewTab3)
    --         self.tbClass2Cell[i]:AddTogGroup(self.TogGroupClass2)
    --         self.tbClass2Cell[i]:SetClickCallback(function (tbInfo, bIsClass1)
    --             self.nCurSelectClass2Index = i
    --             self.nCurSelectClass3Index = 1
    --             self:UpdateRightInfo()
    --             self:UpdateBtnState()
    --         end)
    --     end

    --     local bShow = true
    --     if self.nCurSelectPageIndex == PageType.Hair then
    --         local tbConfig = BuildHairData.GetHairConfigWithClassIndex(self.nCurSelectClass1Index, i)
    --         if not tbConfig or #tbConfig <= 0 then
    --             bShow = false
    --         end
    --     end
    --     UIHelper.SetVisible(self.tbClass2Cell[i]._rootNode, bShow)
    --     self.tbClass2Cell[i]:OnEnter(tbClass2Config, false)
    -- end

    -- UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTab3)
    -- UIHelper.SetToggleGroupSelected(self.TogGroupClass2, self.nCurSelectClass2Index)
end

function UICoinShopBuildFacePage:UpdateRightInfo()
    UIHelper.SetVisible(self.WidgetDefault, false)
    UIHelper.SetVisible(self.WidgetAdjust, false)
    UIHelper.SetVisible(self.WidgetHairPart, false)
    UIHelper.SetVisible(self.WidgetBodyPart, false)
    UIHelper.SetVisible(self.WidgetDetailAdjust, false)
    UIHelper.SetVisible(self.WidgetRecommend, false)
    UIHelper.SetVisible(self.WidgetList2, true)
    UIHelper.SetVisible(self.LayoutList3, false)
    UIHelper.SetVisible(self.BtnChangeSide, false)
    Event.Dispatch(EventType.OnCoinShopShowBuildFaceSideTog, false)

    self:OpenDetailAdjustView(false)

    if self.nCurSelectPageIndex == PageType.Face then
        if self.nCurSelectClass2Index == 0 then
            self:UpdateFaceDefaultRightInfo()
        else
            self:UpdateFaceRightInfo()
        end
    elseif self.nCurSelectPageIndex == PageType.Makeup then
        self:UpdateMakeupRightInfo()
        self:UpdateDetailBtnState()
    elseif self.nCurSelectPageIndex == PageType.FaceOld then
        if self.nCurSelectClass1Index == 0 then
            self:UpdateOldFaceDefaultRightInfo()
        else
            self:UpdateOldFaceRightInfo()
        end
    elseif self.nCurSelectPageIndex == PageType.MakeupOld then
        if self.nCurSelectClass1Index == 0 then
            self:UpdateOldMakeupDefaultRightInfo()
        else
            self:UpdateOldMakeupRightInfo()
        end
        self:UpdateOldDetailBtnState()
    elseif self.nCurSelectPageIndex == PageType.Hair then
        self:UpdateHairRightInfo()
    elseif self.nCurSelectPageIndex == PageType.Body then
        if self.nCurSelectClass1Index == 0 then
            self:UpdateBodyDefaultRightInfo()
        elseif self.nCurSelectClass1Index == -1 then
            self:UpdateRecommendRightInfo()
        else
            self:UpdateBodyRightInfo()
        end
    elseif self.nCurSelectPageIndex == PageType.Prefab then
        self:UpdatePrefabRightInfo()
    elseif self.nCurSelectPageIndex == PageType.Recommend then
        self:UpdateRecommendRightInfo()
    end

    UIHelper.LayoutDoLayout(self.LayoutTabList)
end

function UICoinShopBuildFacePage:UpdateFaceDefaultRightInfo(bJustUpdateState)
    UIHelper.SetVisible(self.WidgetDefault, true)
    if not bJustUpdateState then
        UIHelper.HideAllChildren(self.ScrollViewDefault)
    end

    local tbClassConfig = Lib.copyTab(BuildFaceData.tBoneAreaDefault)
    for i, nBoneDefault in ipairs(tbClassConfig) do
        self.tbDefaultCell = self.tbDefaultCell or {}
        if not self.tbDefaultCell[i] then
            self.tbDefaultCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetBulidFaceItem_80, self.ScrollViewDefault)
            UIHelper.ToggleGroupAddToggle(self.TogGroupDefault, self.tbDefaultCell[i].ToggleSelect)
        end
        local tInfo = Table_GetFaceBoneDefault(nBoneDefault, BuildFaceData.nRoleType)

        if not bJustUpdateState then
            UIHelper.SetVisible(self.tbDefaultCell[i]._rootNode, true)
        end
        self.tbDefaultCell[i]:OnEnter(4, tInfo)
    end

    if not bJustUpdateState then
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDefault)
    end
end

function UICoinShopBuildFacePage:UpdateFaceRightInfo()
    UIHelper.SetVisible(self.WidgetAdjust, true)
    UIHelper.RemoveAllChildren(self.ScrollViewAdjust)
    self.tbAdjustCell = {}
    self.tbAdjustTitleCell = {}

    if not self.tbClassConfig then
        return
    end

    local tbConfig1 = self.tbClassConfig[self.nCurSelectClass1Index]
    if not tbConfig1 then
        return
    end

    local tbConfig2 = tbConfig1[self.nCurSelectClass2Index]
    if not tbConfig2 then
        return
    end

    for i, tbAdjustConfig in ipairs(tbConfig2) do
        if tbAdjustConfig.szDivideName ~= "" then
            if not self.tbAdjustTitleCell[i] then
                self.tbAdjustTitleCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetFaceAdjustTittleCell, self.ScrollViewAdjust)
            end

            UIHelper.SetVisible(self.tbAdjustTitleCell[i]._rootNode, true)
            self.tbAdjustTitleCell[i]:OnEnter(UIHelper.GBKToUTF8(tbAdjustConfig.szDivideName))
        end

        if not self.tbAdjustCell[i] then
            self.tbAdjustCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetCoinAdjustCell, self.ScrollViewAdjust)
        end

        UIHelper.SetVisible(self.tbAdjustCell[i]._rootNode, true)
        self.tbAdjustCell[i]:OnEnter(self.nCurSelectPageIndex, tbAdjustConfig, BuildFaceData.tNowFaceData.tBone[tbAdjustConfig.nBoneType])
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAdjust)
end

function UICoinShopBuildFacePage:UpdateOldFaceDefaultRightInfo(bJustUpdateState)
    UIHelper.SetVisible(self.WidgetDefault, true)
    if not bJustUpdateState then
        UIHelper.HideAllChildren(self.ScrollViewDefault)
    end

    local tbClassConfig = Lib.copyTab(BuildFaceData.tOldFaceList)
    for i, tInfo in ipairs(tbClassConfig) do
        self.tbDefaultCell = self.tbDefaultCell or {}
        if not self.tbDefaultCell[i] then
            self.tbDefaultCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetBulidFaceItem_80, self.ScrollViewDefault)
            UIHelper.ToggleGroupAddToggle(self.TogGroupDefault, self.tbDefaultCell[i].ToggleSelect)
        end

        if not bJustUpdateState then
            UIHelper.SetVisible(self.tbDefaultCell[i]._rootNode, true)
        end
        self.tbDefaultCell[i]:OnEnter(6, tInfo)
    end

    if not bJustUpdateState then
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDefault)
    end
end

function UICoinShopBuildFacePage:UpdateOldFaceRightInfo(bJustUpdateState)
    local bIsNewFace = ExteriorCharacter.IsNewFace()
    if bIsNewFace then
        return
    end

    UIHelper.SetVisible(self.WidgetAdjust, true)
    UIHelper.RemoveAllChildren(self.ScrollViewAdjust)
    self.tbAdjustCell = {}
    self.tbAdjustTitleCell = {}

    if not self.tbClassConfig then
        return
    end

    local tbConfig1 = self.tbClassConfig[self.nCurSelectClass1Index]
    if not tbConfig1 then
        return
    end

    for i, tbAdjustConfig in ipairs(tbConfig1) do
        if not self.tbAdjustCell[i] then
            self.tbAdjustCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetCoinAdjustCell, self.ScrollViewAdjust)
        end

        UIHelper.SetVisible(self.tbAdjustCell[i]._rootNode, true)
        self.tbAdjustCell[i]:OnEnter(self.nCurSelectPageIndex, tbAdjustConfig, BuildFaceData.tNowFaceData.tFaceData.tBone[tbAdjustConfig[1]])
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAdjust)
end

function UICoinShopBuildFacePage:UpdateMakeupRightInfo(bJustUpdateState)
    UIHelper.SetVisible(self.WidgetDetailAdjust, true)
    UIHelper.SetVisible(self.LayoutList3, false)
    UIHelper.LayoutDoLayout(self.LayoutTabList)
    if not bJustUpdateState then
        UIHelper.HideAllChildren(self.ScrollViewDetailAdjust)
    end

    if not self.tbClassConfig then
        return
    end

    local tbConfig1 = self.tbClassConfig[self.nCurSelectClass1Index]
    if not tbConfig1 then
        return
    end

    local tbConfig2 = tbConfig1[self.nCurSelectClass2Index]
    if not tbConfig2 then
        return
    end

    local bMeanwhile, nMeanwhile = BuildFaceData.UpdateMeanwhile(self.nCurSelectClass1Index, self.nCurSelectClass2Index)
    Event.Dispatch(EventType.OnCoinShopShowBuildFaceSideTog, bMeanwhile, nMeanwhile)

    local hFaceLiftManager = GetFaceLiftManager()
    if not hFaceLiftManager then
        return
    end

    if #tbConfig2 > 1 then
        UIHelper.SetVisible(self.WidgetDetailAdjust, false)
        UIHelper.SetVisible(self.LayoutList3, true)
        UIHelper.LayoutDoLayout(self.LayoutList3)
        UIHelper.LayoutDoLayout(self.LayoutTabList)

        if bJustUpdateState then
            return
        end

        local tbData = {}
        for i, tbConfig3 in ipairs(tbConfig2) do
            if not tbConfig2.bIsDecoration then
                self:GetDecalsList(tbData, tbConfig3, i)
            else
                self:GetDecorationSubList(tbData, tbConfig3, i)
            end
        end

        local func = function(scriptContainer, tArgs)
            local szName = UIHelper.GBKToUTF8(tArgs.szSubClassName)

            if string.find(szName, "·") then
                local tbName = string.split(szName, "·")
                if #tbName > 1 then
                    szName = tbName[#tbName]
                end
            end

            UIHelper.SetString(scriptContainer.LabelTitle, szName)
            UIHelper.SetString(scriptContainer.LabelSelect, szName)

            local bNew = false
            local bIsDecoration = tbConfig2.bIsDecoration
            local nType         = bIsDecoration and tArgs.nDecorationType or tArgs.nDecalsType
            if bIsDecoration then
                local tDecalList = BuildFaceData.GetDecorationSub(nType)
                for i, nShowID in ipairs(tDecalList) do
                    local tUIInfo = BuildFaceData.GetDecoration(nType, nShowID)
                    local nLabel = tUIInfo.nLabel
                    if nLabel then
                        if kmath.andOperator(nLabel, NEWFACE_LABEL.DISCOUNT) ~= 0 then

                        elseif kmath.andOperator(nLabel, NEWFACE_LABEL.NEW) ~= 0 then
                            bNew = true
                            break
                        end
                    end
                end
            else
                local tDecalList    = BuildFaceData.GetDecalList(self.nRoleType, nType)
                for i, nShowID in ipairs(tDecalList) do
                    local tUIInfo = BuildFaceData.GetDecal(self.nRoleType, nType, nShowID)
                    local nLabel = tUIInfo.nLabel
                    if nLabel then
                        if kmath.andOperator(nLabel, NEWFACE_LABEL.DISCOUNT) ~= 0 then
    
                        elseif kmath.andOperator(nLabel, NEWFACE_LABEL.NEW) ~= 0 then
                            bNew = true
                            break
                        end
                    end
                end
            end
            UIHelper.SetVisible(scriptContainer.ImgNew, bNew)
        end

        self.scriptScrollViewTab3:ClearContainer()
        self.scriptScrollViewTab3:SetOuterInitSelect()
        UIHelper.SetupScrollViewTree(self.scriptScrollViewTab3,
            PREFAB_ID.WidgetLeftTabCell2,
            PREFAB_ID.WidgetBulidFaceItem_80,
            func, tbData, true)

        local nCurSelectIndex3 = self.nCurSelectClass3Index

        local scriptContainer = self.scriptScrollViewTab3.tContainerList[nCurSelectIndex3].scriptContainer
        Timer.AddFrame(self, 1, function()
            scriptContainer:SetSelected(true)
        end)
        return
    end

    local bIsDecoration     = tbConfig2.bIsDecoration
    local nType             = tbConfig2[self.nCurSelectClass3Index].nDecalsType
    local tLogicDecal       = bIsDecoration and hFaceLiftManager.GetDecorationInfoV2(self.nRoleType, nType)
                                or hFaceLiftManager.GetDecalInfoV2(self.nRoleType, nType)
    local tDecalList        = bIsDecoration and BuildFaceData.GetDecorationList(self.nRoleType, nType)
                                or BuildFaceData.GetDecalList(self.nRoleType, nType)

    UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupDetailAdjust)
    for i, nShowID in ipairs(tDecalList) do
        self.tbDetailAdjustCell = self.tbDetailAdjustCell or {}
        local tDecalInfo = tLogicDecal[nShowID]
        local tUIInfo = BuildFaceData.GetDecal(self.nRoleType, nType, nShowID)
        if not self.tbDetailAdjustCell[i] then
            self.tbDetailAdjustCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetBulidFaceItem_80, self.ScrollViewDetailAdjust)
        end
        UIHelper.ToggleGroupAddToggle(self.TogGroupDetailAdjust, self.tbDetailAdjustCell[i].ToggleSelect)

        if not bJustUpdateState then
            UIHelper.SetVisible(self.tbDetailAdjustCell[i]._rootNode, true)
        end
        self.tbDetailAdjustCell[i]:OnEnter(1, tUIInfo, tDecalInfo)
    end

    if not bJustUpdateState then
        self:UpdateDetailBtnState()
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDetailAdjust)
    end
end

function UICoinShopBuildFacePage:UpdateOldMakeupDefaultRightInfo(bJustUpdateState)
    UIHelper.SetVisible(self.WidgetDetailAdjust, true)
    UIHelper.SetVisible(self.LayoutList3, false)
    UIHelper.LayoutDoLayout(self.LayoutTabList)
    if not bJustUpdateState then
        UIHelper.HideAllChildren(self.ScrollViewDetailAdjust)
    end

    if not self.tbClassConfig then
        return
    end

    local tbConfig1 = self.tbClassConfig[self.nCurSelectClass1Index]
    if not tbConfig1 then
        return
    end

    local hFaceLiftManager = GetFaceLiftManager()
    if not hFaceLiftManager then
        return
    end

    local tLogicDecal = GetFaceLiftManager().GetDecalInfo(self.nRoleType, tbConfig1.dwClassID)
    local tDecalList = BuildFaceData.GetOldDecalList(self.nRoleType, tbConfig1.dwClassID)

    UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupDetailAdjust)
    for i, nShowID in ipairs(tDecalList) do
        self.tbDetailAdjustCell = self.tbDetailAdjustCell or {}
        local tDecalInfo = tLogicDecal[nShowID]
        local tUIInfo = Table_GetDecal(self.nRoleType, tbConfig1.dwClassID, nShowID)
        if not self.tbDetailAdjustCell[i] then
            self.tbDetailAdjustCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetBulidFaceItem_80, self.ScrollViewDetailAdjust)
        end
        UIHelper.ToggleGroupAddToggle(self.TogGroupDetailAdjust, self.tbDetailAdjustCell[i].ToggleSelect)

        if not bJustUpdateState then
            UIHelper.SetVisible(self.tbDetailAdjustCell[i]._rootNode, true)
        end
        self.tbDetailAdjustCell[i]:OnEnter(7, tUIInfo, tDecalInfo)
    end

    if not bJustUpdateState then
        self:UpdateDetailBtnState()
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDetailAdjust)
    end
end

function UICoinShopBuildFacePage:UpdateOldMakeupRightInfo(bJustUpdateState)
    UIHelper.SetVisible(self.WidgetDetailAdjust, true)
    UIHelper.SetVisible(self.LayoutList3, false)
    UIHelper.LayoutDoLayout(self.LayoutTabList)
    if not bJustUpdateState then
        UIHelper.HideAllChildren(self.ScrollViewDetailAdjust)
    end

    if not self.tbClassConfig then
        return
    end

    local tbConfig1 = self.tbClassConfig[self.nCurSelectClass1Index]
    if not tbConfig1 then
        return
    end

    local hFaceLiftManager = GetFaceLiftManager()
    if not hFaceLiftManager then
        return
    end

    if tbConfig1.dwClassID == -1 then
        -- 装饰物
        self:UpdateOldMakeupDecorationRightInfo(bJustUpdateState)
        return
    end

    local tLogicDecal = hFaceLiftManager.GetDecalInfo(self.nRoleType, tbConfig1.dwClassID)
    local tDecalList = BuildFaceData.GetOldDecalList(self.nRoleType, tbConfig1.dwClassID)

    UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupDetailAdjust)
    for i, nShowID in ipairs(tDecalList) do
        self.tbDetailAdjustCell = self.tbDetailAdjustCell or {}
        local tDecalInfo = tLogicDecal[nShowID]
        local tUIInfo = Table_GetDecal(self.nRoleType, tbConfig1.dwClassID, nShowID)
        if not self.tbDetailAdjustCell[i] then
            self.tbDetailAdjustCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetBulidFaceItem_80, self.ScrollViewDetailAdjust)
        end
        UIHelper.ToggleGroupAddToggle(self.TogGroupDetailAdjust, self.tbDetailAdjustCell[i].ToggleSelect)

        if not bJustUpdateState then
            UIHelper.SetVisible(self.tbDetailAdjustCell[i]._rootNode, true)
        end
        self.tbDetailAdjustCell[i]:OnEnter(7, tUIInfo, tDecalInfo)
    end

    if not bJustUpdateState then
        self:UpdateDetailBtnState()
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDetailAdjust)
    end
end

function UICoinShopBuildFacePage:UpdateOldMakeupDecorationRightInfo(bJustUpdateState)
    UIHelper.SetVisible(self.WidgetDetailAdjust, true)
    UIHelper.SetVisible(self.LayoutList3, false)
    UIHelper.LayoutDoLayout(self.LayoutTabList)
    if not bJustUpdateState then
        UIHelper.HideAllChildren(self.ScrollViewDetailAdjust)
    end

    if not self.tbClassConfig then
        return
    end

    local tbConfig1 = self.tbClassConfig[self.nCurSelectClass1Index]
    if not tbConfig1 then
        return
    end

    local hFaceLiftManager = GetFaceLiftManager()
    if not hFaceLiftManager then
        return
    end

    if tbConfig1.dwClassID ~= -1 then
        return
    end

    local tLogicDecal = hFaceLiftManager.GetDecorationInfo(self.nRoleType)
    local tDecalList = Table_GetDecorationList(self.nRoleType)

    UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupDetailAdjust)
    for i, nDecoration in ipairs(tDecalList) do
        self.tbDetailAdjustCell = self.tbDetailAdjustCell or {}
        local tDecalInfo = tLogicDecal[nDecoration]
        local tUIInfo = Table_GettDecoration(self.nRoleType, nDecoration)
        if not self.tbDetailAdjustCell[i] then
            self.tbDetailAdjustCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetBulidFaceItem_80, self.ScrollViewDetailAdjust)
        end
        UIHelper.ToggleGroupAddToggle(self.TogGroupDetailAdjust, self.tbDetailAdjustCell[i].ToggleSelect)

        if not bJustUpdateState then
            UIHelper.SetVisible(self.tbDetailAdjustCell[i]._rootNode, true)
        end
        self.tbDetailAdjustCell[i]:OnEnter(9, tUIInfo, tDecalInfo)
    end

    if not bJustUpdateState then
        self:UpdateDetailBtnState()
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDetailAdjust)
    end
end

function UICoinShopBuildFacePage:UpdateHairRightInfo()
    UIHelper.SetVisible(self.WidgetHairPart, true)
    self.scriptHairPart = self.scriptHairPart or UIHelper.GetBindScript(self.WidgetHairPart)
    self.scriptHairPart:OnEnter(self.nCurSelectClass1Index, self.nCurSelectClass2Index)
end


function UICoinShopBuildFacePage:UpdateBodyDefaultRightInfo()
    UIHelper.SetVisible(self.WidgetBodyPart, true)
    self.scriptBodyPart = self.scriptBodyPart or UIHelper.GetBindScript(self.WidgetBodyPart)
    self.scriptBodyPart:OnEnter()
end

function UICoinShopBuildFacePage:UpdateBodyRightInfo()
    UIHelper.SetVisible(self.WidgetAdjust, true)
    UIHelper.RemoveAllChildren(self.ScrollViewAdjust)
    self.tbAdjustCell = {}

    if not self.tbClassConfig then
        return
    end

    local tbConfig = self.tbClassConfig[self.nCurSelectClass1Index]
    if not tbConfig then
        return
    end

    for i, tbAdjustConfig in ipairs(tbConfig) do
       if not self.tbAdjustCell[i] then
            self.tbAdjustCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetCoinAdjustCell, self.ScrollViewAdjust)
        end

        UIHelper.SetVisible(self.tbAdjustCell[i]._rootNode, true)
        self.tbAdjustCell[i]:OnEnter(self.nCurSelectPageIndex, tbAdjustConfig, BuildBodyData.tNowBodyData[tbAdjustConfig.nBodyType])
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAdjust)
end

function UICoinShopBuildFacePage:UpdatePrefabRightInfo(bJustUpdateState)
    UIHelper.SetVisible(self.WidgetDefault, true)
    UIHelper.SetVisible(self.WidgetList2, false)
    UIHelper.LayoutDoLayout(self.LayoutTabList)
    if not bJustUpdateState then
        UIHelper.HideAllChildren(self.ScrollViewDefault)
    end

    self.tbDefaultCell = self.tbDefaultCell or {}
    for i, tbData in ipairs(self.tbClassConfig) do
        if not self.tbDefaultCell[i] then
            self.tbDefaultCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetBulidFaceItem_80, self.ScrollViewDefault)
            UIHelper.ToggleGroupAddToggle(self.TogGroupDefault, self.tbDefaultCell[i].ToggleSelect)
        end

        if not bJustUpdateState then
            UIHelper.SetVisible(self.tbDefaultCell[i]._rootNode, true)
        end
        self.tbDefaultCell[i]:OnEnter(3, tbData)
    end

    if not bJustUpdateState then
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDefault)
    end
end

function UICoinShopBuildFacePage:UpdateRecommendRightInfo()
    UIHelper.SetVisible(self.WidgetList2, self.nCurSelectPageIndex == PageType.Body)
    UIHelper.SetVisible(self.WidgetRecommend, true)
    UIHelper.LayoutDoLayout(self.LayoutTabList)

    local tFilter = {}
    local bOldFace = self.nCurSelectPageListIndex == PageListType.FaceOld
    local bBody = self.nCurSelectPageIndex == PageType.Body

    local nDataType = bBody and SHARE_DATA_TYPE.BODY or SHARE_DATA_TYPE.FACE
    tFilter.nRoleType = self.nRoleType
    if nDataType == SHARE_DATA_TYPE.FACE then
        tFilter.nFaceType = bOldFace and FACE_TYPE.OLD or FACE_TYPE.NEW
    end

    self.scriptRecommend = self.scriptRecommend or UIHelper.GetBindScript(self.WidgetRecommend)
    self.scriptRecommend:OnEnter(false, nDataType, tFilter)
end

function UICoinShopBuildFacePage:UpdateBtnState()
    if self.nCurSelectPageIndex == PageType.Face then
        UIHelper.SetVisible(self.BtnRevertAll, true)
        UIHelper.SetVisible(self.BtnRevert, self.nCurSelectClass2Index > 0)
    elseif self.nCurSelectPageIndex == PageType.Makeup then
        UIHelper.SetVisible(self.BtnRevertAll, true)
        UIHelper.SetVisible(self.BtnRevert, true)
    elseif self.nCurSelectPageIndex == PageType.Hair then
        UIHelper.SetVisible(self.BtnRevertAll, false)
        UIHelper.SetVisible(self.BtnRevert, false)
    elseif self.nCurSelectPageIndex == PageType.Body then
        UIHelper.SetVisible(self.BtnRevertAll, true)
        UIHelper.SetVisible(self.BtnRevert, false)
    elseif self.nCurSelectPageIndex == PageType.Prefab then
        UIHelper.SetVisible(self.BtnRevertAll, true)
        UIHelper.SetVisible(self.BtnRevert, false)
    elseif self.nCurSelectPageIndex == PageType.Recommend then
        UIHelper.SetVisible(self.BtnRevertAll, false)
        UIHelper.SetVisible(self.BtnRevert, false)
    end

    if self.nCurSelectPageIndex == PageType.Body then
        Event.Dispatch(EventType.OnShowFaceCodeBtn, false, UI_COINSHOP_GENERAL.BUILD_FACE)
        Event.Dispatch(EventType.OnShowBodyCodeBtn, true, UI_COINSHOP_GENERAL.BUILD_FACE)
    else
        Event.Dispatch(EventType.OnShowFaceCodeBtn, true, UI_COINSHOP_GENERAL.BUILD_FACE)
        Event.Dispatch(EventType.OnShowBodyCodeBtn, false, UI_COINSHOP_GENERAL.BUILD_FACE)
    end

    local hPlayer = GetClientPlayer()
    local nCount, nLimitCount, nFreeChanceEndTime = hPlayer.GetFaceLiftFreeChanceV2()
    if self.nCurSelectPageListIndex == PageListType.FaceOld then
        nCount, nLimitCount, nFreeChanceEndTime = hPlayer.GetFaceLiftFreeChance()
    end

    UIHelper.SetVisible(self.BtnFreeFaceShowTips, nLimitCount and nLimitCount > 0)
    UIHelper.SetString(self.LabelFreeFace, string.format("%d(永久)+%d(限时)", nCount or 0, nLimitCount or 0))
    UIHelper.LayoutDoLayout(self.LayoutFreeFace)

    local nFreeCount, nTimeLimitFreeChance, nTimeLimitFreeChanceEndTime = hPlayer.GetBodyReshapingFreeChance()
    UIHelper.SetVisible(self.BtnFreeBodyShowTips, nTimeLimitFreeChance and nTimeLimitFreeChance > 0)
    UIHelper.SetString(self.LabelFreeBody, string.format("%d(永久)+%d(限时)", nFreeCount or 0, nTimeLimitFreeChance or 0))
    UIHelper.LayoutDoLayout(self.LayoutFreeBody)

    UIHelper.LayoutDoLayout(self.LayoutBtn)
    UIHelper.LayoutDoLayout(self.LayoutRightTop)
end

function UICoinShopBuildFacePage:UpdateDetailBtnState()
    if self.nCurSelectPageIndex ~= PageType.Makeup then
        return
    end

    if not self.tbClassConfig then
        return
    end

    local tbConfig1 = self.tbClassConfig[self.nCurSelectClass1Index]
    if not tbConfig1 then
        return
    end

    local tbConfig2 = tbConfig1[self.nCurSelectClass2Index]
    if not tbConfig2 then
        return
    end

    local hFaceLiftManager = GetFaceLiftManager()
    if not hFaceLiftManager then
        return
    end

    local bIsDecoration     = tbConfig2.bIsDecoration
    local tbConfig3         = tbConfig2[self.nCurSelectClass3Index]
    local nType             = bIsDecoration and tbConfig3.nDecorationType or tbConfig3.nDecalsType
    local tLogicDecal       = bIsDecoration and hFaceLiftManager.GetDecorationInfoV2(self.nRoleType, nType)
                                or hFaceLiftManager.GetDecalInfoV2(self.nRoleType, nType)
    local tNowSetting       = BuildFaceData.tNowFaceData[bIsDecoration and "tDecoration" or "tDecal"][nType]
    if not tNowSetting then
        return
    end

    local nShowID = tNowSetting.nShowID
    local tDecalInfo = tLogicDecal[nShowID]

    if tDecalInfo and #tDecalInfo.tColorID > 1 then
        self:OpenDetailAdjustView(true)
    else
        self:OpenDetailAdjustView(false)
    end
end

function UICoinShopBuildFacePage:UpdateOldDetailBtnState()
    if self.nCurSelectPageIndex ~= PageType.MakeupOld then
        return
    end

    if not self.tbClassConfig then
        return
    end

    local tbConfig1 = self.tbClassConfig[self.nCurSelectClass1Index]
    if not tbConfig1 then
        return
    end

    local hFaceLiftManager = GetFaceLiftManager()
    if not hFaceLiftManager then
        return
    end

    if tbConfig1.dwClassID == -1 then
        return
    end

    local nType             = tbConfig1.dwClassID
    local tLogicDecal = GetFaceLiftManager().GetDecalInfo(self.nRoleType, nType)
    local tDecalList = BuildFaceData.GetOldDecalList(self.nRoleType, nType)

    local tNowSetting = BuildFaceData.tNowFaceData.tFaceData.tDecal[nType]
    local nShowID = tNowSetting.nShowID

    if Table_BeFliped(self.nRoleType, nType, nShowID) then
        nShowID = Table_BeFliped(self.nRoleType, nType, nShowID)
        BuildFaceData.SetChangeSide(true)
    end

    local tUIInfo = Table_GetDecal(self.nRoleType, nType, nShowID)
    local tDecalInfo = tLogicDecal[nShowID]

    UIHelper.SetVisible(self.BtnChangeSide, tUIInfo.nFlipID > 0)
    UIHelper.LayoutDoLayout(self.LayoutTabList)

    if tDecalInfo and #tDecalInfo.tColorID > 1 then
        self:OpenOldDetailAdjustView(true)
    else
        self:OpenOldDetailAdjustView(false)
    end
end

function UICoinShopBuildFacePage:UpdatePriceInfo()
    local tbBuySaveList = CoinShopPreview.GetBuySaveList(self.bUseNew, self.bUseNew)
    local nTotalPrice, nTaxPrice = self:ParsePriceData(tbBuySaveList) or 0, 0

    UIHelper.SetString(self.LabelPriceMoney, math.max(0, nTotalPrice - nTaxPrice))
    UIHelper.SetString(self.LabelPriceExtraMoney, nTaxPrice)

    if self.bUseNew then
        UIHelper.SetString(self.LabelPriceTittle, "预估(新增)：")
    else
        UIHelper.SetString(self.LabelPriceTittle, "预估(修改)：")
    end

    local hPlayer = GetClientPlayer()
    local nCount, nLimitCount, nFreeChanceEndTime = hPlayer.GetFaceLiftFreeChanceV2()
    local bNewFace = ExteriorCharacter.IsNewFace()
    if not bNewFace then
        nCount, nLimitCount, nFreeChanceEndTime = hPlayer.GetFaceLiftFreeChance()
    end
    UIHelper.SetVisible(self.LabelFreeChange, (nCount + nLimitCount) > 0 and nTotalPrice > 0)

    UIHelper.SetVisible(self.LabelPriceExtra, nTaxPrice > 0)
    UIHelper.SetVisible(self.LabelPriceExtraMoney, nTaxPrice > 0)
    UIHelper.SetVisible(self.ImgPriceExtraTongBao, nTaxPrice > 0)

    UIHelper.LayoutDoLayout(self.LayoutPrice)
end

function UICoinShopBuildFacePage:UpdateBuyBtnState()
    local tbBuySaveList = CoinShopPreview.GetBuySaveList()
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
end

function UICoinShopBuildFacePage:UpdateCameraState()
    if self.nCurSelectPageIndex == PageType.Prefab or
        self.nCurSelectPageIndex == PageType.Face or
        self.nCurSelectPageIndex == PageType.Makeup or
        self.nCurSelectPageIndex == PageType.FaceOld or
        self.nCurSelectPageIndex == PageType.MakeupOld or
        self.nCurSelectPageIndex == PageType.Hair or
        self.nCurSelectPageIndex == PageType.Recommend then
        ExteriorCharacter.UpdateMDLScale()
        ExteriorCharacter.ScaleToCamera("BuildFaceMin")
        FireUIEvent("EXTERIOR_CHARACTER_SET_CAMERA_RADIUS", "CoinShop_View", "CoinShop", "BuildFaceMin", nil)
    else
        ExteriorCharacter.ResetMDLScale()
        ExteriorCharacter.ScaleToCamera("Max")
        FireUIEvent("EXTERIOR_CHARACTER_SET_CAMERA_RADIUS", "CoinShop_View", "CoinShop", "Max", nil)
    end
end

function UICoinShopBuildFacePage:OnChangePageList(nType)
    self.nCurSelectPageListIndex = nType
    self:InitPageTogList()
    if self.nCurSelectPageListIndex == PageListType.Face then
        self:OnClickPageTog(PageType.Face)
    elseif self.nCurSelectPageListIndex == PageListType.FaceOld then
        self:OnClickPageTog(PageType.FaceOld)
    end
    UIHelper.SetSelected(self.TogNieLianCoin_Vision, self.nCurSelectPageListIndex == 2)
end

function UICoinShopBuildFacePage:OnClickPageTog(nType)
    if self.nCurSelectPageIndex == nType then
        return
    end

    local bIsNewFace = ExteriorCharacter.IsNewFace()
    local bIsUseLiftedFace = ExteriorCharacter.IsUseLiftedFace()
    if not bIsNewFace and (nType == PageType.Face or nType == PageType.Makeup) then
        self.nCurSelectPageIndex = PageType.Prefab
        local nSelectIndex = table.get_key(self.tbPageIndex2PageType, self.nCurSelectPageIndex) or 1
        UIHelper.SetToggleGroupSelected(self.TogGroupPage, nSelectIndex - 1)
        TipsHelper.ShowNormalTip("请先选择脸型预设")
    elseif (bIsNewFace or not bIsUseLiftedFace) and nType == PageType.MakeupOld then
        self.nCurSelectPageIndex = PageType.FaceOld
        local nSelectIndex = table.get_key(self.tbPageIndex2PageType, self.nCurSelectPageIndex) or 1
        UIHelper.SetToggleGroupSelected(self.TogGroupPage, nSelectIndex - 1)
        TipsHelper.ShowNormalTip("请先选择易容脸型")
    elseif nType == PageType.Hair and not CoinShop_CanChangeHair() then
        local nSelectIndex = table.get_key(self.tbPageIndex2PageType, self.nCurSelectPageIndex) or 1
        UIHelper.SetToggleGroupSelected(self.TogGroupPage, nSelectIndex - 1)
    elseif nType == PageType.Recommend then
        self.nCurSelectPageIndex = nType
        local nSelectIndex = table.get_key(self.tbPageIndex2PageType, self.nCurSelectPageIndex) or 1
        UIHelper.SetToggleGroupSelected(self.TogGroupPage, nSelectIndex - 1)
    else
        self.nCurSelectPageIndex = nType
        local nSelectIndex = table.get_key(self.tbPageIndex2PageType, self.nCurSelectPageIndex) or 1
        UIHelper.SetToggleGroupSelected(self.TogGroupPage, nSelectIndex - 1)
    end

    self.nCurSelectClass1Index = 1
    if self.nCurSelectPageIndex == PageType.Body or self.nCurSelectPageIndex == PageType.FaceOld then
        self.nCurSelectClass1Index = 0
    end
    self.nCurSelectClass2Index = 1
    if self.nCurSelectPageIndex == PageType.Face then
        self.nCurSelectClass2Index = 0
    end
    self.nCurSelectClass3Index = 1

    self:UpdateInfo()
    self:UpdateCameraState()
end

function UICoinShopBuildFacePage:EnableFaceHighlight(bEnabled, nBoneType)
    local ModleView = ExteriorCharacter.GetModel("CoinShop_View", "CoinShop")

    if bEnabled then
        ModleView:EnableFaceHighlight(nBoneType)
        self.nLastHighlightFaceType = nBoneType
    elseif self.nLastHighlightFaceType then
        ModleView:DisableFaceHighlight(self.nLastHighlightFaceType)
        self.nLastHighlightFaceType = nil
    end
end

function UICoinShopBuildFacePage:EnableBodyHighlight(bEnabled, nBodyType)
    local ModleView = ExteriorCharacter.GetModel("CoinShop_View", "CoinShop")

    if bEnabled then
        ModleView:EnableHighlight(nBodyType)
        self.nLastHighlightBodyType = nBodyType
    elseif self.nLastHighlightBodyType then
        ModleView:DisableHighlight(self.nLastHighlightBodyType)
        self.nLastHighlightBodyType = nil
    end
end

function UICoinShopBuildFacePage:ShowBuildFaceSyncSideTog(bShow, nMeanwhile)
    UIHelper.SetVisible(self.WidgetList3LeftRight, bShow)
    self.nCurMeanwhile = nMeanwhile
    if bShow then
        BuildFaceData.SetMeanwhileSwitch(self.nCurMeanwhile, UIHelper.GetSelected(self.TogList3LeftRight))
    end
    UIHelper.LayoutDoLayout(self.LayoutList3)
end

function UICoinShopBuildFacePage:OpenDetailAdjustView(bOpen)
    if not self.scriptDetailAdjust then
        self.scriptDetailAdjust = UIHelper.GetBindScript(self.WidgetColorAdjust)
    end

    UIHelper.SetVisible(self.WidgetColorAdjust, bOpen)

    if not bOpen then
        return
    end

    if self.nCurSelectPageIndex ~= PageType.Makeup then
        return
    end

    if not self.tbClassConfig then
        return
    end

    local tbConfig1 = self.tbClassConfig[self.nCurSelectClass1Index]
    if not tbConfig1 then
        return
    end

    local tbConfig2 = tbConfig1[self.nCurSelectClass2Index]
    if not tbConfig2 then
        return
    end

    local hFaceLiftManager = GetFaceLiftManager()
    if not hFaceLiftManager then
        return
    end

    local bIsDecoration     = tbConfig2.bIsDecoration
    local tbConfig3         = tbConfig2[self.nCurSelectClass3Index]
    local nType             = bIsDecoration and tbConfig3.nDecorationType or tbConfig3.nDecalsType
    local tLogicDecal       = hFaceLiftManager.GetDecalInfoV2(self.nRoleType, nType)
    local tNowSetting       = BuildFaceData.tNowFaceData[bIsDecoration and "tDecoration" or "tDecal"][nType]
    if not tNowSetting then
        return
    end

    local nShowID = tNowSetting.nShowID
    local tUIInfo = bIsDecoration and BuildFaceData.GetDecoration(nType, nShowID) or BuildFaceData.GetDecal(self.nRoleType, nType, nShowID)
    local tDecalInfo = tLogicDecal[nShowID]

    self.scriptDetailAdjust:OnEnter(tbConfig2.szClassName, tDecalInfo, tUIInfo, Lib.copyTab(tNowSetting))
end

function UICoinShopBuildFacePage:OpenOldDetailAdjustView(bOpen)
    if not self.scriptDetailAdjust then
        self.scriptDetailAdjust = UIHelper.GetBindScript(self.WidgetColorAdjust)
    end

    UIHelper.SetVisible(self.WidgetColorAdjust, bOpen)

    if not bOpen then
        return
    end

    if self.nCurSelectPageIndex ~= PageType.MakeupOld then
        return
    end

    if not self.tbClassConfig then
        return
    end

    local tbConfig1 = self.tbClassConfig[self.nCurSelectClass1Index]
    if not tbConfig1 then
        return
    end

    local hFaceLiftManager = GetFaceLiftManager()
    if not hFaceLiftManager then
        return
    end

    local nType             = tbConfig1.dwClassID
    local tLogicDecal = GetFaceLiftManager().GetDecalInfo(self.nRoleType, nType)
    local tDecalList = BuildFaceData.GetOldDecalList(self.nRoleType, nType)

    local tNowSetting = BuildFaceData.tNowFaceData.tFaceData.tDecal[nType]
    local nShowID = tNowSetting.nShowID

    if Table_BeFliped(self.nRoleType, nType, nShowID) then
        nShowID = Table_BeFliped(self.nRoleType, nType, nShowID)
    end

    local tUIInfo = Table_GetDecal(self.nRoleType, nType, nShowID)
    local tDecalInfo = tLogicDecal[nShowID]

    self.scriptDetailAdjust:OnEnter(tbConfig1.szName, tDecalInfo, tUIInfo, Lib.copyTab(tNowSetting), true)
end

function UICoinShopBuildFacePage:LoadExteriorData(szShareCode)
    local tData = ShareCodeData.GetShareCodeData(szShareCode)
    if not tData then
        return
    end

    local tExterior = tData.tExterior
    if not tExterior then
        return
    end

    ExteriorCharacter.PreviewExteriorInShareStation(tExterior)
end

function UICoinShopBuildFacePage:LoadBodyData(szFile)
    local tBodyData, szError = BuildBodyData.LoadBodyData(szFile)
    if not tBodyData then
        TipsHelper.ShowNormalTip(g_tStrings.STR_BODY_DATA_VAILD)
        return
    end

    if tBodyData.nRoleType ~= BuildBodyData.nRoleType then
        local szName = g_tStrings.tRoleTypeFormalName[tBodyData.nRoleType]
        local szMsg = FormatString( g_tStrings.STR_BODY_TYPE_VAILD, szName)
        TipsHelper.ShowNormalTip(szMsg)
        return
    end

    local nResult = BuildBodyData.ImportData(tBodyData)
    if nResult then
        if not ShareStationData.bOpening then
            TipsHelper.ShowNormalTip(g_tStrings.STR_BODY_DATA_IMPROT)
        end

        if not UIHelper.GetVisible(self.WidgetRecommend) then
            self:UpdateInfo()
        else
            self:UpdateModleInfo()
            self:UpdateBtnState()
            self:UpdateBuyBtnState()
            self:UpdatePriceInfo()
        end

        local ModleView = ExteriorCharacter.GetModel("CoinShop_View", "CoinShop")
        ModleView:SetBodyReshapingParams(BuildBodyData.tNowBodyData)
        ExteriorCharacter.PreviewBody(nil, BuildBodyData.tNowBodyData, true)
    end
end

function UICoinShopBuildFacePage:LoadFaceData(szFile)
    local bIsNewFace = true
    local tFaceData, szError = NewFaceData.LoadFaceData(szFile)
    if szError == g_tStrings.STR_NEW_LOAD_FACEDATA_ERROR then
        tFaceData, szError = NewFaceData.LoadOldFaceData(szFile)

        if szError then
            TipsHelper.ShowNormalTip(szError)
            return
        end

        bIsNewFace = false
    end

    if bIsNewFace then
        if not tFaceData then
            TipsHelper.ShowNormalTip(g_tStrings.STR_NEW_FACE_LIFT_DATA_VAILD)
            return
        end

        if tFaceData.nRoleType ~= BuildFaceData.nRoleType then
            local szName = g_tStrings.tRoleTypeFormalName[tFaceData.nRoleType]
            local szMsg = FormatString( g_tStrings.FACE_LIFT_TYPE_VAILD, szName)
            TipsHelper.ShowNormalTip(szMsg)
            return
        end

        local nResult = BuildFaceData.ImportData(tFaceData)
        if nResult then
            if not ShareStationData.bOpening then
                TipsHelper.ShowNormalTip(g_tStrings.STR_NEW_FACE_DATA_IMPROT)
            end

            if not UIHelper.GetVisible(self.WidgetRecommend) then
                self:OnChangePageList(PageListType.Face)
                self:UpdateInfo()
            else
                self:UpdateModleInfo()
                self:UpdateBtnState()
                self:UpdateBuyBtnState()
                self:UpdatePriceInfo()
            end
        end
    else
        if not tFaceData then
            TipsHelper.ShowNormalTip(g_tStrings.FACE_LIFT_DATA_VAILD)
            return
        end

        if tFaceData.nRoleType ~= BuildFaceData.nRoleType then
            local szName = g_tStrings.tRoleTypeFormalName[tFaceData.nRoleType]
            local szMsg = FormatString( g_tStrings.FACE_LIFT_TYPE_VAILD, szName)
            TipsHelper.ShowNormalTip(szMsg)
            return
        end

        local nResult = BuildFaceData.ImportOldData(tFaceData)
        if nResult then
            if not ShareStationData.bOpening then
                TipsHelper.ShowNormalTip(g_tStrings.FACE_DATA_IMPROT)
            end

            if not UIHelper.GetVisible(self.WidgetRecommend) then
                self:OnChangePageList(PageListType.FaceOld)
                self:UpdateInfo()
            else
                self:UpdateModleInfo()
                self:UpdateBtnState()
                self:UpdateBuyBtnState()
                self:UpdatePriceInfo()
            end
        end
    end

    if tFaceData then
        ShareExteriorData.SetFaceDecalShowFlagByData(tFaceData)
    end
end

function UICoinShopBuildFacePage:OnMatchHairPreviewChange()
    LOG.INFO("TODO OnMatchHairPreviewChange")
end

function UICoinShopBuildFacePage:RefeshNewFace()
    LOG.INFO("TODO RefeshNewFace")
end

function UICoinShopBuildFacePage:RefeshBody()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local nIndex = hPlayer.GetEquippedBodyBoneIndex()
    local tBody = hPlayer.GetEquippedBodyBoneData()

    BuildBodyData.UpdateMybodyData()
    FireUIEvent("PREVIEW_BODY", nIndex, tBody, true)
end

function UICoinShopBuildFacePage:ParsePriceData(tbBuySaveList)
    local hFaceManager = GetFaceLiftManager()
    if not hFaceManager then
        return
    end

    local nTotalPrice = 0
    local nTaxPrice = 0
    for _, tbInfo in ipairs(tbBuySaveList) do

        local nVouchars = 0
        local bCanUseVouchers = hFaceManager.CanUseVouchers()
        if bCanUseVouchers then
            nVouchars = hFaceManager.GetVouchers()
        end

        if tbInfo.bNewFace then
            local tNewPrice = hFaceManager.GetFacePrice(BuildFaceData.tNowFaceData)
            local _, nFaceIndex = ExteriorCharacter.GetPreviewNewFace()
            if not self.bUseNew and nFaceIndex then
                tNewPrice = hFaceManager.GetFacePrice(BuildFaceData.tNowFaceData, nFaceIndex)
            end
            if not tNewPrice then
                LOG.ERROR("UICoinShopBuildFaceBuyDetailView:ParseData ERROR! tNewPrice is nil!")
                return
            end

            nTotalPrice = nTotalPrice + tNewPrice.nTotalPrice - nVouchars
            nTaxPrice = nTaxPrice + tNewPrice.nTaxPrice
        elseif tbInfo.eGoodsType == COIN_SHOP_GOODS_TYPE.FACE then
            local tFaceData = BuildFaceData.tNowFaceData.tFaceData
            tFaceData.tDecoration = nil
            local tNewPrice = hFaceManager.GetFacePrice(tFaceData)
            local _, nFaceIndex = ExteriorCharacter.GetPreviewFace()
            if not self.bUseNew and nFaceIndex then
                tNewPrice = hFaceManager.GetFacePrice(tFaceData, nFaceIndex)
            end
            if not tNewPrice then
                LOG.ERROR("UICoinShopBuildFaceBuyDetailView:ParseData ERROR! tNewPrice is nil!")
                return
            end

            nTotalPrice = nTotalPrice + tNewPrice.nTotalPrice - nVouchars
            nTaxPrice = nTaxPrice + tNewPrice.nTaxPrice
        elseif tbInfo.bBody then

        elseif tbInfo.dwGoodsID then

        end
    end

    return nTotalPrice, nTaxPrice
end

function UICoinShopBuildFacePage:IsBuyNew()
    return self.bUseNew
end

function UICoinShopBuildFacePage:GetDecalsList(tbData, tbConfig, nIndex)
    local hFaceLiftManager = GetFaceLiftManager()
    if not hFaceLiftManager then
        return
    end

    local tItemList         = {}
    local nType             = tbConfig.nDecalsType
    local tLogicDecal       = hFaceLiftManager.GetDecalInfoV2(self.nRoleType, nType)
    local tDecalList        = BuildFaceData.GetDecalList(self.nRoleType, nType)

    for i, nShowID in ipairs(tDecalList) do
        local tDecalInfo = tLogicDecal[nShowID]
        local tUIInfo = BuildFaceData.GetDecal(self.nRoleType, nType, nShowID)
        local tbTempConfig =  { tArgs = {nIconType = 1, tUIInfo = tUIInfo, tDecalInfo = tDecalInfo} }
        table.insert(tItemList, tbTempConfig)
    end

    table.insert(tbData, {
        tArgs = tbConfig,
        tItemList = tItemList,
        fnSelectedCallback = function (bSelected, scriptContainer)
            if bSelected then
                self.nCurSelectClass3Index = nIndex
                UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupDetailAdjust)
                local tbCells = scriptContainer:GetItemScript()
                local nSelectIndex = 0
                for j, scriptCell in ipairs(tbCells) do
                    local tbInfo = tItemList[j].tArgs
                    local tDecal = BuildFaceData.tNowFaceData.tDecal[tbInfo.tUIInfo.nType]
                    scriptCell:OnEnter(tbInfo.nIconType, tbInfo.tUIInfo, tbInfo.tDecalInfo)
                    UIHelper.SetSwallowTouches(scriptCell.ToggleSelect, false)
                    UIHelper.ToggleGroupAddToggle(self.TogGroupDetailAdjust, scriptCell.ToggleSelect)

                    if tDecal.nShowID == tbInfo.tUIInfo.nShowID then
                        nSelectIndex = j - 1
                    end
                end

                UIHelper.SetToggleGroupSelected(self.TogGroupDetailAdjust, nSelectIndex)
                self:UpdateDetailBtnState()
            end
        end
    })
end

function UICoinShopBuildFacePage:GetDecorationSubList(tbData, tbConfig, nIndex)
    local hFaceLiftManager = GetFaceLiftManager()
    if not hFaceLiftManager then
        return
    end

    local tItemList         = {}
    local nType             = tbConfig.nDecorationType
    local tLogicDecal       = hFaceLiftManager.GetDecorationInfoV2(self.nRoleType, nType)
    local tDecalList        = BuildFaceData.GetDecorationSub(nType)

    local bEmpty = true
    for i, nShowID in ipairs(tDecalList) do
        local tDecalInfo = tLogicDecal[nShowID]
        local tUIInfo = BuildFaceData.GetDecoration(nType, nShowID)
        local tbTempConfig =  { tArgs = {nIconType = 1, tUIInfo = tUIInfo, tDecalInfo = tDecalInfo} }
        if nShowID ~= 0 then
            bEmpty = false
        end
        table.insert(tItemList, tbTempConfig)
    end

    if not bEmpty then
        table.insert(tbData, {
            tArgs = tbConfig,
            tItemList = tItemList,
            fnSelectedCallback = function (bSelected, scriptContainer)
                if bSelected then
                    self.nCurSelectClass3Index = nIndex
                    UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupDetailAdjust)
                    local tbCells = scriptContainer:GetItemScript()
                    local nSelectIndex = 0
                    for j, scriptCell in ipairs(tbCells) do
                        local tbInfo = tItemList[j].tArgs
                        local tDecal = BuildFaceData.tNowFaceData.tDecoration[tbInfo.tUIInfo.nDecorationType]
                        scriptCell:OnEnter(tbInfo.nIconType, tbInfo.tUIInfo, tbInfo.tDecalInfo)
                        UIHelper.SetSwallowTouches(scriptCell.ToggleSelect, false)
                        UIHelper.ToggleGroupAddToggle(self.TogGroupDetailAdjust, scriptCell.ToggleSelect)
                        if tDecal.nShowID == tbInfo.tUIInfo.nShowID then
                            nSelectIndex = j - 1
                        end
                    end
                    
                    UIHelper.SetToggleGroupSelected(self.TogGroupDetailAdjust, nSelectIndex)
                    self:UpdateDetailBtnState()
                end
            end
        })
    end
end

return UICoinShopBuildFacePage