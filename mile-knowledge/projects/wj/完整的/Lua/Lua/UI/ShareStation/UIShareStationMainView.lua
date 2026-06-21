-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIShareStationMainView
-- Date: 2025-07-19 17:04:52
-- Desc: ?
-- ---------------------------------------------------------------------------------
local NEW_FACE_SUFFIX = "ini"
local OLD_FACE_SUFFIX = "dat"
local CREATOR_SEARCH_CACHE_TIME = 30 --作者搜索缓存时间(s)
local MAX_COLLECT_COUNT = 50 --最多收藏捏脸的个数

local TYPE_TO_SUFFIX = {
    [1] = NEW_FACE_SUFFIX,
    [2] = OLD_FACE_SUFFIX,
}
local PAGE_TYPE = {
    [1] = "Rank",
    [2] = "Like",
    [3] = "Self",
}
local SEARCH_TYPE_TO_NAME = {
    [SHARE_SEARCH_TYPE.NAME] = "作品名",
    [SHARE_SEARCH_TYPE.CODE] = "分享码",
    [SHARE_SEARCH_TYPE.USER] = "作者",
}
local SEARCH_TYPE_TO_PLACEHOLDER = {
    [SHARE_SEARCH_TYPE.NAME] = "输入作品名",
    [SHARE_SEARCH_TYPE.CODE] = "输入分享码",
    [SHARE_SEARCH_TYPE.USER] = "输入认证作者",
}
local Index2RoleType = {
    [0] = -1,
    [1] = ROLE_TYPE.STANDARD_MALE,
    [2] = ROLE_TYPE.STANDARD_FEMALE,
    [3] = ROLE_TYPE.LITTLE_GIRL,
    [4] = ROLE_TYPE.LITTLE_BOY,
}

local Index2OpenState = {
    [0] = -1,
    [1] = SHARE_OPEN_STATUS.PUBLIC,
    [2] = SHARE_OPEN_STATUS.PRIVATE,
}

local PageTogConfig = {
    [SHARE_DATA_TYPE.FACE] = {szName = "脸型", szIcon = "UIAtlas2_NieLian_CoinFace_FaceTab1_IconDefault", bShowInLogin = true},
    [SHARE_DATA_TYPE.BODY] = {szName = "体型", szIcon = "UIAtlas2_NieLian_CoinFace_FaceTab1_IconBody", bShowInLogin = true},
    [SHARE_DATA_TYPE.EXTERIOR] = {szName = "穿搭", szIcon = "UIAtlas2_NieLian_CoinFace_FaceTab1_IconOutfit", bShowInLogin = false},
    [SHARE_DATA_TYPE.PHOTO] = {szName = "拍照", szIcon = "UIAtlas2_NieLian_CoinFace_FaceTab1_IconPhotograph", bShowInLogin = false},
}

local RoleType2Index = {}
for nIndex, nRoleType in ipairs(Index2RoleType) do
    RoleType2Index[nRoleType] = nIndex
end

local UIShareStationMainView = class("UIShareStationMainView")

function UIShareStationMainView:OnEnter(nDataType, nRoleType, nSuffix, bIsLogin)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szPageType = ShareStationData.bEnterMySelf and PAGE_TYPE[3] or PAGE_TYPE[1]
    self.nDataType = nDataType or SHARE_DATA_TYPE.FACE
    ShareStationData.nPhotoSizeType = SHARE_PHOTO_SIZE_TYPE.CARD
    self:ResetFilter()

    local szSuffix = TYPE_TO_SUFFIX[nSuffix] or NEW_FACE_SUFFIX
    ShareCodeData.Init(bIsLogin)
    ShareStationData.Init(nDataType, nRoleType, szSuffix, bIsLogin)
    ShareExteriorData.Init()
    self:Init()

    if ShareStationData.tbEventLinkInfo then
        Timer.AddFrame(self, 1, function ()
            self:OnLink2Share()

            if ShareStationData.tbEventLinkInfo.tFilterExterior then
                ShareStationData.tFilterExterior = ShareStationData.tbEventLinkInfo.tFilterExterior
            end
        end)
    end

    UIHelper.SetSelected(self.Tog_Vision, szSuffix == NEW_FACE_SUFFIX, false)
    UIHelper.SetSelected(self.tbPageTypeToggle[ShareStationData.bEnterMySelf and 3 or 1], true, false)
    for index, tog in ipairs(self.tbPhotoTypeToggle) do
        UIHelper.SetSelected(tog, index == nSuffix, false)
    end

    ShareStationData.CheckShowRuleTip()
    ShareStationData.bEnterMySelf = nil
    RemoteCallToServer("On_Daily_FinishCourse", 1)
end

function UIShareStationMainView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    ShareCodeData.UnInit()
    ShareStationData.UnInit()
    ShareExteriorData.UnInit()
    ExteriorCharacter.ResetExterior()
    ExteriorCharacter.UpdeteModelVisable("CoinShop_View", "CoinShop", true)

    if self.nDownloadDynamicID then
        PakDownloadMgr.ReleaseDynamicPakInfo(self.nDownloadDynamicID)
        self.nDownloadDynamicID = nil
    end
end

function UIShareStationMainView:BindUIEvent()
    for nIndex, toggle in ipairs(self.tbPageTypeToggle) do
        UIHelper.SetToggleGroupIndex(toggle, ToggleGroupIndex.PreviewBagItem)
        UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function (_, bSelected)
            if not bSelected then
                return
            end
            self.szPageType = PAGE_TYPE[nIndex]
            self.scriptCardList.nCurPage = 1
            ShareStationData.SetViewPage(self.scriptCardList.nCurPage)
            self:ResetFilter()
            self:UpdateInfo()
        end)
    end

    for nIndex, toggle in ipairs(self.tbPhotoTypeToggle) do
        UIHelper.SetToggleGroupIndex(toggle, ToggleGroupIndex.FlowerFertilizerItem)
        UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function (_, bSelected)
            if not bSelected then
                return
            end
            self.scriptCardList.nCurPage = 1
            ShareStationData.SetViewPage(self.scriptCardList.nCurPage)
            self:ResetFilter()

            ShareStationData.nPhotoSizeType = nIndex
            ShareStationData.nSubType = nIndex
            self:UpdateInfo()
        end)
    end

    UIHelper.BindUIEvent(self.Tog_Vision, EventType.OnSelectChanged, function (_, bSelected)
        ShareStationData.szAllSuffix = bSelected and NEW_FACE_SUFFIX or OLD_FACE_SUFFIX
        if ShareStationData.szAllSuffix == NEW_FACE_SUFFIX then
            ShareStationData.nSubType = FACE_TYPE.NEW
        else
            ShareStationData.nSubType = FACE_TYPE.OLD
        end

        if not self.scriptCardList then
            self.scriptCardList = UIHelper.GetBindScript(self.WidgetList)
            self.scriptCardList:OnEnter()
        end
        self.scriptCardList.nCurPage = 1
        ShareStationData.SetViewPage(self.scriptCardList.nCurPage)
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function(btn)
        if not self.tbCurSelectShare then
            return
        end

        local szShareCode = self.tbCurSelectShare.szShareCode
        ShareCodeData.AddDataHeat(ShareStationData.bIsLogin, self.nDataType, szShareCode)
        Event.Dispatch(EventType.OnCloseShareStation, self.nDataType)
        Event.Dispatch(EventType.OnCoinShopClickBuyBtn)
        if self.nDataType == SHARE_DATA_TYPE.FACE then
             RemoteCallToServer("On_SA_SJZ", 3)
        end
    end)

    UIHelper.BindUIEvent(self.BtnApply, EventType.OnClick, function(btn)
        if not self.tbCurSelectShare then
            return
        end

        local szShareCode = self.tbCurSelectShare.szShareCode
        ShareCodeData.AddDataHeat(ShareStationData.bIsLogin, self.nDataType, szShareCode)
        Event.Dispatch(EventType.OnCloseShareStation, self.nDataType)
        if self.nDataType == SHARE_DATA_TYPE.FACE then
            RemoteCallToServer("On_SA_SJZ", 3)
        end
    end)

    UIHelper.BindUIEvent(self.BtnImport, EventType.OnClick, function(btn)
        if not self.tbCurSelectShare then
            return
        end

        if not self.scriptRightCard then
            self.scriptRightCard = UIHelper.GetBindScript(self.WidgetAnchorRightContent)
            self.scriptRightCard:OnEnter()
        end

        local szShareCode = self.tbCurSelectShare.szShareCode
        local tbExterior = self.scriptRightCard:GetSelectExterior()
        local scriptTips = UIHelper.ShowConfirm(g_tStrings.STR_SHARE_STATION_IMPORT_CONFIRM, function ()
            FireUIEvent("COINSHOP_INIT_ROLE", true, true)
            ShareCodeData.CollectData(ShareStationData.bIsLogin, self.nDataType, szShareCode)
            ShareCodeData.AddDataHeat(ShareStationData.bIsLogin, self.nDataType, szShareCode)
            UIMgr.Open(VIEW_ID.PaneShareStationImportPop, tbExterior)
            Event.Dispatch(EventType.OnCloseShareStation, self.nDataType)
            RemoteCallToServer("On_SA_SJZ", 2)
        end)

        scriptTips:ShowButton("Other")
        scriptTips:SetOtherButtonClickedCallback(function ()
            FireUIEvent("COINSHOP_INIT_ROLE", true, true)
            ShareCodeData.AddDataHeat(ShareStationData.bIsLogin, self.nDataType, szShareCode)
            UIMgr.Open(VIEW_ID.PaneShareStationImportPop, tbExterior)
            Event.Dispatch(EventType.OnCloseShareStation, self.nDataType)
            RemoteCallToServer("On_SA_SJZ", 2)
        end)

        scriptTips:SetConfirmButtonContent(g_tStrings.STR_SHARE_STATION_CONFIRM_BTN_TEXT1)
        scriptTips:SetOtherButtonContent(g_tStrings.STR_SHARE_STATION_CONFIRM_BTN_TEXT2)
    end)

    UIHelper.BindUIEvent(self.BtnUpdate, EventType.OnClick, function()
        if not self.tbCurSelectShare then
            return
        end

        Event.Dispatch(EventType.OnStartDoUpdateShareData, ShareStationData.bIsLogin, self.nDataType, self.tbCurSelectShare)
    end)

    UIHelper.BindUIEvent(self.BtnRule, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelShareStationRulePop)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        Event.Dispatch(EventType.OnCloseShareStation, self.nDataType)
        BuildFaceData.ReInitDefaultData()
        BuildBodyData.ResetBodyData()
        FireUIEvent("COINSHOP_INIT_ROLE", true, true)
        FireUIEvent("RESET_BODY")
        FireUIEvent("RESET_NEW_FACE")
        Event.Dispatch(EventType.OnChangeBuildFaceDefault, true)
    end)

    UIHelper.BindUIEvent(self.BtnCollectNumTips, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSingleTextTips, self.BtnCollectNumTips,
            TipsLayoutDir.BOTTOM_RIGHT, g_tStrings.STR_SHARE_STATION_LIKE_NUM_TIPS)
    end)

    UIHelper.BindUIEvent(self.BtnUploadNumTips, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSingleTextTips, self.BtnUploadNumTips,
            TipsLayoutDir.BOTTOM_RIGHT, g_tStrings.STR_SHARE_STATION_UPLOAD_NUM_TIPS)
    end)

    UIHelper.BindUIEvent(self.TogScreen, EventType.OnClick, function(btn)
        if not self.tbMainFilter then
            return
        end
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogScreen, TipsLayoutDir.BOTTOM_RIGHT, self.tbMainFilter)
    end)

    UIHelper.BindUIEvent(self.TogScreen_Exterior, EventType.OnClick, function(btn)
        UIMgr.OpenSingle(false, VIEW_ID.PanelShareStationFilter, self.nDataType)
    end)

    UIHelper.BindUIEvent(self.TogSort, EventType.OnClick, function(btn)
        if ShareStationData.szFilterAccount then
            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogSort, TipsLayoutDir.BOTTOM_RIGHT, FilterDef.ShareStationTimeRange_Author)
            return
        end
        if not self.tbSortFilter then
            return
        end
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogSort, TipsLayoutDir.BOTTOM_RIGHT, self.tbSortFilter)
    end)

    UIHelper.BindUIEvent(self.TogManage, EventType.OnSelectChanged, function(tog, bSelected)
        if not ShareStationData.bDelMode and bSelected then
            Event.Dispatch(EventType.OnStartBatchDelShareCode)
        else
            if ShareStationData.bDelMode then
                self.scriptCardList:EndBatchDel()
            end
        end
    end)

    UIHelper.BindUIEvent(self.BtnLocatePhoto, EventType.OnClick, function ()
        if not self.tbCurSelectShare then
            return
        end
        local tbShareData = ShareCodeData.GetShareCodeData(self.tbCurSelectShare.szShareCode)
        if not tbShareData then
            return
        end
        -- 关掉商城、设计站(?)
        local tPlace = clone(tbShareData.tPlayerParam.tPlace)
        if SelfieTemplateBase.IsHomelandMap(tPlace.dwMapID) then
            OutputMessage("MSG_ANNOUNCE_RED", "家园地图拍摄地点不可追踪")
            return
        end
        SelfieTemplateBase.SavePhotoDataByCloud(clone(tbShareData)) -- 存一次数据到Base
        if not SelfieData.IsStudioMap(tPlace.dwMapID) then  -- 大世界
            SelfieTemplateBase.SetPlaceGuild(tPlace)
        else 
            SelfieTemplateBase.GuildToStudio(tPlace, nil, true)  -- 摄影棚
        end
        -- ShareStationData.OnApplyPhoto(self.tbCurSelectShare, true)
    end)

    UIHelper.BindUIEvent(self.BtnApplyPhoto, EventType.OnClick, function ()
        if not self.tbCurSelectShare then
            return
        end

        local tips, scriptTips = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetTipMoreOper, self.BtnApplyPhoto)
        local nWorldPosX, nWorldPosY = UIHelper.GetWorldPosition(scriptTips._rootNode)
        UIHelper.SetWorldPosition(scriptTips._rootNode, nWorldPosX + 12, nWorldPosY)

        scriptTips:OnEnter({ -- 正式服屏蔽
        {
            szName = "前往名片拍摄",
            OnClick = function ()
                ShareStationData.OnApplyPhoto(self.tbCurSelectShare, true, false)
            end
        },
        {
            szName = "前往幻境云图",
            OnClick = function ()
                ShareStationData.OnApplyPhoto(self.tbCurSelectShare, false, false)
            end
        }, })
    end)

    for _, btn in ipairs(self.tbPreviewPhotoScanBtn) do
        UIHelper.BindUIEvent(btn, EventType.OnClick, function ()
            if not self.tbCurSelectShare then
                return
            end
            UIMgr.Open(VIEW_ID.PanelImgScanPop, self.tbCurSelectShare)
        end)
    end

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditKindSearch, function ()
            local szSearch = UIHelper.GetText(self.EditKindSearch)
            self:OnSearch(szSearch)
        end)

        UIHelper.RegisterEditBoxEnded(self.EditKindSearch_Long, function ()
            local szSearch = UIHelper.GetText(self.EditKindSearch_Long)
            self:OnSearch(szSearch)
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditKindSearch, function ()
            local szSearch = UIHelper.GetText(self.EditKindSearch)
            self:OnSearch(szSearch)
        end)

        UIHelper.RegisterEditBoxReturn(self.EditKindSearch_Long, function ()
            local szSearch = UIHelper.GetText(self.EditKindSearch_Long)
            self:OnSearch(szSearch)
        end)
    end
end

function UIShareStationMainView:RegEvent()
    Event.Reg(self, EventType.OnShareCodeRsp, function (szKey, tInfo)
        if szKey == "DEL_BATCH_FACE" then
            if tInfo and tInfo.code and tInfo.code == 1 then
                ShareCodeData.ApplyAccountConfig(ShareStationData.bIsLogin, true)
            end
        end
    end)

    Event.Reg(self, EventType.OnGetShareStationUploadConfig, function (nDataType)
        if self.bNeedUpdateInfo then
            Timer.Add(self, 0.1, function ()
                ShareCodeData.ApplyCollectList(ShareStationData.bIsLogin, ShareStationData.nDataType)
                self:UpdateInfo()
            end)
        end
    end)

    Event.Reg(self, EventType.OnGetShareStationList, function (nDataType, nTotalCount, tRankList)
        if nDataType ~= self.nDataType then
            return
        end
        ShareStationData.tAllShareList = tRankList
        ShareStationData.nTotalShareCount = nTotalCount
        ShareStationData.nFilterShareCount = nTotalCount
        if self.szPageType == "Rank" then
            self:UpdateShareList("Rank", nTotalCount, tRankList)
        end
    end)

    Event.Reg(self, EventType.OnGetShareStationCreatorList, function (nDataType, tRankList)
        if nDataType ~= self.nDataType then
            return
        end

        local nTotalCount = #tRankList
        if nTotalCount >= 0 then
            local nCurTime = ShareCodeData.GetCurrentTime(ShareStationData.bIsLogin)
            tRankList.nGetTime = tRankList.nGetTime or nCurTime
            self.tbCreatorCache = self.tbCreatorCache or {}
            self.tbCreatorCache[nDataType] = self.tbCreatorCache[nDataType] or {}
            self.tbCreatorCache[nDataType][ShareStationData.szSearch] = tRankList
        end

        ShareStationData.szFilterAccount = nil
        FilterDef.ShareStationTimeRange_Author.Reset()

        ShareStationData.tAllShareList = tRankList
        ShareStationData.nTotalShareCount = nTotalCount
        ShareStationData.nFilterShareCount = nTotalCount
        if self.szPageType == "Rank" then
            self:UpdateShareList("Author", nTotalCount, tRankList)
        end
    end)

    Event.Reg(self, EventType.OnUpdateCollectShareCodeList, function (nDataType, tCollectData, tDelayLoadCover)
        if nDataType ~= self.nDataType then
            return
        end
        ShareStationData.SetLikeShareData(tCollectData)
        if self.szPageType == "Like" then
            local nSubType = ShareStationData.nSubType
            local tFilterCollectData = ShareStationData.GetLikeShareData(nSubType) or {}
            self:UpdateShareList("Like", #tFilterCollectData, tFilterCollectData)
        end
        self:UpdateLikeInfo()
    end)

    Event.Reg(self, EventType.OnUpdateSelfShareCodeList, function (nDataType, tbSelfShareList)
        if nDataType ~= self.nDataType then
            return
        end
        ShareStationData.SetSelfShareData(tbSelfShareList)
        if self.szPageType == "Self" then
            local nSubType = ShareStationData.nSubType
            local tbSelfShareList = ShareStationData.GetSelfShareData(nSubType)
            self:UpdateShareList("Self", #tbSelfShareList, tbSelfShareList)
        end
        self:UpdateSelfInfo()
    end)

    Event.Reg(self, EventType.OnDownloadShareCodeCover, function (bSuccess, szShareCode, szFilePath)
        if not self.tbCurSelectShare or self.nDataType ~= SHARE_DATA_TYPE.PHOTO then
            return
        end

        if bSuccess and szShareCode == self.tbCurSelectShare.szShareCode then
            self:UpdatePhotoPreview()
        end
    end)

    Event.Reg(self, EventType.OnDeleteShareCodeData, function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnFilterShareStationExterior, function (tExterior)
        self.scriptCardList.nCurPage = 1
        ShareStationData.tTag = {}
        ShareStationData.nRangeType = 1 -- 需要帮玩家手动切到全部日期
        ShareStationData.SetViewPage(self.scriptCardList.nCurPage)
        ShareStationData.tFilterExterior = tExterior
        self:UpdateInfo()
        if not table.is_empty(tExterior) then
            local tbRuntime = FilterDef.ShareStationFilter_Exterior.GetRunTime() or {}
            local tbRuntime_NoneTime = FilterDef.ShareStationFilter_NoneTime_Exterior.GetRunTime() or {}

            tbRuntime[2] = tbRuntime[2] or {} -- 发布日期
            tbRuntime[2][1] = 1

            tbRuntime[5] = {}   -- 标签
            tbRuntime_NoneTime[4] = {}
        end

        if tExterior and tExterior["Color" .. EQUIPMENT_REPRESENT.HAIR_STYLE] == 1 then
            local tbRuntime = FilterDef.ShareStationFilter_Exterior.GetRunTime() or {}
            local tbRuntime_NoneTime = FilterDef.ShareStationFilter_NoneTime_Exterior.GetRunTime() or {}
            tbRuntime[4] = tbRuntime[4] or {}
            tbRuntime[4][1] = 1

            tbRuntime_NoneTime[3] = tbRuntime[3] or {}
            tbRuntime_NoneTime[3][1] = 1
        end
    end)

    Event.Reg(self, EventType.OnFilterShareStationMap, function (nPhotoMapType, dwPhotoMapID)
        self.scriptCardList.nCurPage = 1
        ShareStationData.SetViewPage(self.scriptCardList.nCurPage)
        ShareStationData.nPhotoMapType = nPhotoMapType
        ShareStationData.dwPhotoMapID = dwPhotoMapID
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnFilter, function (szKey, tbSelected)
        if ShareStationData.bSortCD then
            local tbRuntime = FilterDef.ShareStationHeatRank.GetRunTime()
            tbRuntime[1][1] = ShareStationData.nSortType
            TipsHelper.ShowNormalTip(g_tStrings.STR_SHARE_STATION_SORT_CD)
            return
        end

        local tbFilter = tbSelected[1]
        local tbFilter_2 = tbSelected[2]
        local tbFilter_3 = tbSelected[3]
        local tbFilter_4 = tbSelected[4]
        local tbFilter_5 = tbSelected[5]

        self.scriptCardList.nCurPage = 1
        ShareStationData.SetViewPage(self.scriptCardList.nCurPage)

        if szKey == FilterDef.ShareStationHeatRank.Key then
            ShareStationData.bSortCD = true
            ShareStationData.nSortType = tbFilter[1]
            Timer.Add(ShareStationData, 3, function ()
                ShareStationData.bSortCD = false
            end)
            self:UpdateInfo()
        elseif szKey == FilterDef.ShareStationTimeRange.Key then
            ShareStationData.nSortType = tbFilter[1]
            self:UpdateInfo()
        elseif szKey == FilterDef.ShareStationFilter.Key then
            local nRoleTypeIndex = tbFilter[1] - 1
            local nRangeTypeIndex = tbFilter_2[1]
            local nSourceTypeIndex = tbFilter_3[1]
            local tbTag = {}
            for _, nIndex in ipairs(tbFilter_4) do
                local tag = self.tbTagList[nIndex]
                if tag then
                    table.insert(tbTag, tag.nTagID)
                end
            end
            ShareStationData.nFilterRoleType = Index2RoleType[nRoleTypeIndex] or ShareStationData.nRoleType
            ShareStationData.nRangeType = nRangeTypeIndex
            ShareStationData.nSourceType = nSourceTypeIndex
            ShareStationData.SetFilterTag(tbTag)

            if not self.scriptCardList then
                self.scriptCardList = UIHelper.GetBindScript(self.WidgetList)
                self.scriptCardList:OnEnter()
            end
            self.scriptCardList.nCurPage = 1
            ShareStationData.SetViewPage(1)
            self:UpdateInfo()
        elseif szKey == FilterDef.ShareStationFilter_Exterior.Key then
            local nRoleTypeIndex = tbFilter[1] - 1
            local nRangeTypeIndex = tbFilter_2[1]
            local nSourceTypeIndex = tbFilter_3[1]
            local bHairDyeing = tbFilter_4[1] and true or false
            local tbTag = {}
            for _, nIndex in ipairs(tbFilter_5) do
                local tag = self.tbTagList[nIndex]
                if tag then
                    table.insert(tbTag, tag.nTagID)
                end
            end
            ShareStationData.nFilterRoleType = Index2RoleType[nRoleTypeIndex] or ShareStationData.nRoleType
            ShareStationData.nRangeType = nRangeTypeIndex
            ShareStationData.nSourceType = nSourceTypeIndex
            ShareStationData.bHairDyeing = bHairDyeing
            ShareStationData.SetFilterTag(tbTag)

            if not self.scriptCardList then
                self.scriptCardList = UIHelper.GetBindScript(self.WidgetList)
                self.scriptCardList:OnEnter()
            end
            self.scriptCardList.nCurPage = 1
            ShareStationData.SetViewPage(1)
            self:UpdateInfo()
        elseif szKey == FilterDef.ShareStationFilter_NoneTime.Key then
            local nRoleTypeIndex = tbFilter[1] - 1
            local nSourceTypeIndex = tbFilter_2[1]
            local tbTag = {}
            for _, nIndex in ipairs(tbFilter_3) do
                local tag = self.tbTagList[nIndex]
                if tag then
                    table.insert(tbTag, tag.nTagID)
                end
            end
            ShareStationData.nFilterRoleType = Index2RoleType[nRoleTypeIndex] or ShareStationData.nRoleType
            ShareStationData.nSourceType = nSourceTypeIndex
            ShareStationData.SetFilterTag(tbTag)

            if not self.scriptCardList then
                self.scriptCardList = UIHelper.GetBindScript(self.WidgetList)
                self.scriptCardList:OnEnter()
            end
            self.scriptCardList.nCurPage = 1
            ShareStationData.SetViewPage(1)
            self:UpdateInfo()
        elseif szKey == FilterDef.ShareStationFilter_NoneTime_Exterior.Key then
            local nRoleTypeIndex = tbFilter[1] - 1
            local nSourceTypeIndex = tbFilter_2[1]
            local bHairDyeing = tbFilter_3[1] and true or false
            local tbTag = {}
            for _, nIndex in ipairs(tbFilter_4) do
                local tag = self.tbTagList[nIndex]
                if tag then
                    table.insert(tbTag, tag.nTagID)
                end
            end
            ShareStationData.nFilterRoleType = Index2RoleType[nRoleTypeIndex] or ShareStationData.nRoleType
            ShareStationData.nSourceType = nSourceTypeIndex
            ShareStationData.bHairDyeing = bHairDyeing
            ShareStationData.SetFilterTag(tbTag)

            if not self.scriptCardList then
                self.scriptCardList = UIHelper.GetBindScript(self.WidgetList)
                self.scriptCardList:OnEnter()
            end
            self.scriptCardList.nCurPage = 1
            ShareStationData.SetViewPage(1)
            self:UpdateInfo()
        elseif szKey == FilterDef.ShareStationTimeRange_Author.Key then
            ShareStationData.nSortType = tbFilter[1] == 1 and tbFilter[1] or 4
            ShareStationData.ApplySearchUser()
        end
    end)

    Event.Reg(self, EventType.OnClickShareStationAuthorCell, function (nDataType, tbData)
        if nDataType ~= self.nDataType then
            return
        end
        ShareStationData.szFilterAccount = tbData.szAccount
        ShareStationData.ApplySearchUser()
    end)

    Event.Reg(self, EventType.OnSelectShareStationCell, function (tbData, bSelected)
        UIHelper.SetVisible(self.WidgetDownloadBtnShell, false)
        if not tbData or not bSelected then
            local nDataType = ShareStationData.nDataType
            if self.tbCurSelectShare and tbData and tbData.szShareCode == self.tbCurSelectShare.szShareCode and nDataType then
                local nSubType = self.tbCurSelectShare.nSubType
                if nDataType == SHARE_DATA_TYPE.FACE then
                    ExteriorCharacter.InitFace(true)
                    BuildFaceData.ResetFaceData()
                    BuildFaceData.InitDefaultData()
                    if nSubType == FACE_TYPE.NEW then
                        FireUIEvent("RESET_NEW_FACE")
                    elseif nSubType == FACE_TYPE.OLD then
                        FireUIEvent("RESET_FACE")
                    end
                    if ShareStationData.bIsLogin then
                        Event.Dispatch(EventType.OnChangeBuildFaceDefault, true)
                    else
                        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
                    end
                elseif nDataType == SHARE_DATA_TYPE.BODY then
                    BuildBodyData.ResetBodyData()
                    FireUIEvent("RESET_BODY")
                    if ShareStationData.bIsLogin then
                        Event.Dispatch(EventType.OnChangeBuildFaceDefault, true)
                    else
                        FireUIEvent("COINSHOPVIEW_ROLE_DATA_UPDATE")
                    end
                elseif nDataType == SHARE_DATA_TYPE.EXTERIOR then
                    ExteriorCharacter.ResetExterior()
                end
            end
            if self.tbCurSelectShare and nDataType == SHARE_DATA_TYPE.PHOTO then
                self:UpdatePhotoPreview()
            end
            self:UpdateShareInfo()
            return
        end

        local szTips = ""
        local bJustUpdate = false
        local nOpenStatus = tbData.nOpenStatus
        if nOpenStatus == SHARE_OPEN_STATUS.COVER_ILLEGAL then
            bJustUpdate = self.szPageType ~= "Self"
            szTips = g_tStrings.STR_SHARE_STATION_COVER_ILLEGAL_TIP
            TipsHelper.ShowNormalTip(szTips)
        elseif nOpenStatus == SHARE_OPEN_STATUS.FILE_ILLEGAL then
            bJustUpdate = true
            szTips = g_tStrings.STR_SHARE_STATION_FILE_ILLEGAL_TIP
            TipsHelper.ShowNormalTip(szTips)
        elseif nOpenStatus == SHARE_OPEN_STATUS.CHECKING_TO_PRIVATE or nOpenStatus == SHARE_OPEN_STATUS.CHECKING_TO_PUBLIC then
            bJustUpdate = true
            szTips = g_tStrings.STR_SHARE_STATION_CHECKING_TIP
            TipsHelper.ShowNormalTip(szTips)
        elseif nOpenStatus == SHARE_OPEN_STATUS.INVISIBLE then
            bJustUpdate = true
            szTips = g_tStrings.STR_SHARE_STATION_REPORTED_TIP
            TipsHelper.ShowNormalTip(szTips)
        elseif nOpenStatus == SHARE_OPEN_STATUS.DELETE then
            bJustUpdate = true
            szTips = g_tStrings.STR_SHARE_STATION_INVISIBLE_TIP
            TipsHelper.ShowNormalTip(szTips)
        elseif nOpenStatus ~= SHARE_OPEN_STATUS.PUBLIC and self.szPageType ~= "Self" then
            bJustUpdate = true
        end

        Timer.AddFrame(self, 1, function()
            if bJustUpdate then
                self:UpdateShareInfo(tbData)
                return
            end

            if self.szPageType == "Self" and string.is_nil(tbData.szFileLink) then
                self:UpdateShareInfo(tbData)
                return
            end

            if nOpenStatus == SHARE_OPEN_STATUS.PUBLIC or self.szPageType == "Self" then
                --只下载公开的脸型，自己上传的脸在获取列表时就会下载所有数据
                self.fnOnUpdateModel = function ()
                    self:UpdateShareInfo(tbData)
                end
                ShareCodeData.DownloadData(self.nDataType, tbData.szShareCode, tbData.szFileLink)
            end
        end)
    end)

    Event.Reg(self, EventType.OnDownloadShareCodeData, function ()
        if self.fnOnUpdateModel then
            self.fnOnUpdateModel()
            self.fnOnUpdateModel = nil
        end
    end)

    Event.Reg(self, EventType.OnStartBatchDelShareCode, function ()
        UIHelper.SetVisible(self.ImgManageSelect, true)
        UIHelper.SetVisible(self.Tog_Vision, false)
        UIHelper.SetVisible(self.WidgetPhotograph, false)
    end)

    Event.Reg(self, EventType.OnEndBatchDelShareCode, function ()
        UIHelper.SetVisible(self.ImgManageSelect, false)
        UIHelper.SetVisible(self.Tog_Vision, true)
        UIHelper.SetVisible(self.WidgetPhotograph, self.nDataType == SHARE_DATA_TYPE.PHOTO)
        UIHelper.SetSelected(self.TogManage, false, true)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        UIHelper.SetSelected(self.TogTypeFilter, false)
    end)

    Event.Reg(self, EventType.OnViewOpen, function (nViewID)
        if nViewID == VIEW_ID.PanelCoinShopBuildDyeing then
            UIMgr.HideView(VIEW_ID.PanelShareStation)
        end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        Timer.Add(self, 0.1, function ()
            UIHelper.LayoutDoLayout(self.LayoutBtn)
        end)
    end)

    Event.Reg(self, EventType.OnViewClose, function (nViewID)
        if nViewID == VIEW_ID.PanelCoinShopBuildDyeing then
            UIMgr.ShowView(VIEW_ID.PanelShareStation)
        elseif nViewID == VIEW_ID.PanelExteriorMain then
            UIMgr.Close(self)
        end
    end)
end

function UIShareStationMainView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIShareStationMainView:Init()
    self:InitSearchTypeToggle()
    self:InitShareTypeToggle()
    GiftHelper.RegGiftEffect(self, self.WidgeGiftHint, self.GiftSFX)

    if not self.scriptCardList then
        self.scriptCardList = UIHelper.GetBindScript(self.WidgetList)
        self.scriptCardList:OnEnter()
    end

    if not self.scriptRightCard then
        self.scriptRightCard = UIHelper.GetBindScript(self.WidgetAnchorRightContent)
        self.scriptRightCard:OnEnter()
    end
end

function UIShareStationMainView:InitSearchTypeToggle()
    ShareStationData.szSearch = ""
    ShareStationData.SetSearchType(SHARE_SEARCH_TYPE.NAME)
    UIHelper.RemoveAllChildren(self.LayoutTypeFilter)
    for nIndex, szName in ipairs(SEARCH_TYPE_TO_NAME) do
        if nIndex == SHARE_SEARCH_TYPE.USER and self.szPageType ~= "Rank" then
            break
        end
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetTradeTypeFilter, self.LayoutTypeFilter, {szName = szName})
        UIHelper.SetToggleGroupIndex(script._rootNode, ToggleGroupIndex.Contacts)
        UIHelper.SetSelected(script._rootNode, nIndex == ShareStationData.nSearchType, false)
        UIHelper.UnBindUIEvent(script._rootNode, EventType.OnClick)
        UIHelper.BindUIEvent(script._rootNode, EventType.OnClick, function()
            ShareStationData.SetSearchType(nIndex)
            UIHelper.SetString(self.LabelTypeFilter, szName)
            UIHelper.SetPlaceHolder(self.EditKindSearch, SEARCH_TYPE_TO_PLACEHOLDER[nIndex])
            UIHelper.SetSelected(self.TogTypeFilter, false)
        end)
    end
    UIHelper.SetString(self.LabelTypeFilter, SEARCH_TYPE_TO_NAME[ShareStationData.nSearchType])
    UIHelper.SetPlaceHolder(self.EditKindSearch, SEARCH_TYPE_TO_PLACEHOLDER[ShareStationData.nSearchType])
end

function UIShareStationMainView:InitShareTypeToggle()
    UIHelper.RemoveAllChildren(self.ScrollViewTypeTab)
    self.tbShareTypeToggle = {}
    for nIndex, tbTog in ipairs(PageTogConfig) do
        local bShow = true
        if not tbTog.bShowInLogin and ShareStationData.bIsLogin then
            bShow = false
        end

        if bShow then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetTogNieLianCoin_Part, self.ScrollViewTypeTab)
            script:OnEnter(tbTog)
            self.tbShareTypeToggle[nIndex] = script

            local toggle = script.TogSelect
            UIHelper.SetSelected(toggle, false)
            UIHelper.SetToggleGroupIndex(toggle, ToggleGroupIndex.BagItem)
            UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function (_, bSelected)
                if not bSelected then
                    return
                end

                self.nDataType = nIndex
                self:ResetFilter()

                local moduleCamera = LoginMgr.GetModule(LoginModule.LOGIN_CAMERA)
                if moduleCamera and ShareStationData.bIsLogin then
                    local nCameraStatus = self.nDataType == SHARE_DATA_TYPE.FACE and LoginCameraStatus.BUILD_FACE_STEP2_FACE
                       or LoginCameraStatus.BUILD_FACE_STEP2_BODY
                    moduleCamera.SetCameraStatus(nCameraStatus, ShareStationData.nRoleType)
                    Event.Dispatch(EventType.OnChangeBuildFaceDefault, true)
                end

                ExteriorCharacter.ScaleToCamera(self.nDataType == SHARE_DATA_TYPE.FACE and "BuildFaceMin" or "Max")
                ShareStationData.SetViewPage(1)
                ShareStationData.SetDataType(nIndex)
                ShareStationData.InitSubType()
                ShareCodeData.ApplyAccountConfig(ShareStationData.bIsLogin, ShareStationData.nDataType, true)
                if self.nDataType == SHARE_DATA_TYPE.FACE then
                    local nSubType = ShareStationData.nSubType
                    local szSuffix = TYPE_TO_SUFFIX[nSubType] or NEW_FACE_SUFFIX
                    UIHelper.SetSelected(self.Tog_Vision, szSuffix == NEW_FACE_SUFFIX)
                elseif self.nDataType == SHARE_DATA_TYPE.PHOTO then
                    ExteriorCharacter.UpdeteModelVisable("CoinShop_View", "CoinShop", false)
                end
                self.bNeedUpdateInfo = true
            end)
        end
    end

    if self.nDataType then
        UIHelper.SetSelected(self.tbShareTypeToggle[self.nDataType].TogSelect, true)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTypeTab)
end

function UIShareStationMainView:UpdateInfo()
    UIHelper.SetVisible(self.LayoutCollectNum, false)
    UIHelper.SetVisible(self.LayoutUploadNum, false)
    UIHelper.SetVisible(self.WidgetBtnManage, false)
    UIHelper.SetNodeGray(self.WidgetBtnManage, true, true)
    UIHelper.SetVisible(self.ImgManageSelect, ShareStationData.bDelMode)
    UIHelper.SetVisible(self.WidgetTog_Vision, not ShareStationData.bIsLogin and self.nDataType == SHARE_DATA_TYPE.FACE and not ShareStationData.bDelMode)
    UIHelper.SetVisible(self.WidgetPhotograph, not ShareStationData.bIsLogin and self.nDataType == SHARE_DATA_TYPE.PHOTO and not ShareStationData.bDelMode)

    if ShareStationData.tbEventLinkInfo then
        local tbLinkInfo = ShareStationData.tbEventLinkInfo
        if tbLinkInfo.szShareCode and tbLinkInfo.szShareCode ~= "" then
            ShareStationData.SetSearchType(SHARE_SEARCH_TYPE.CODE)
            ShareStationData.szSearch = tbLinkInfo.szShareCode
            UIHelper.SetText(self.EditKindSearch, tbLinkInfo.szShareCode)
            UIHelper.SetString(self.LabelTypeFilter, SEARCH_TYPE_TO_NAME[ShareStationData.nSearchType])
            ShareStationData.nRangeType = SHARE_TIME_RANGE.All
        end

        local tbRuntime = {}
        tbRuntime[2] = {ShareStationData.nRangeType}
        self.tbMainFilter.SetRunTime(tbRuntime)
    end

    if self.szPageType == "Rank" then
        ShareStationData.ApplyShareStationData()
    elseif self.szPageType == "Like" then
        local nSubType = ShareStationData.nSubType
        ShareCodeData.ApplyCollectList(ShareStationData.bIsLogin, ShareStationData.nDataType)
        UIHelper.SetVisible(self.LayoutCollectNum, true)
        UIHelper.LayoutDoLayout(self.LayoutRightTop)
        local tFilterCollectData = ShareStationData.GetLikeShareData(nSubType) or {}
        if tFilterCollectData then
            self:UpdateShareList("Like", #tFilterCollectData, tFilterCollectData)
        end
    elseif self.szPageType == "Self" then
        local nSubType = ShareStationData.nSubType
        ShareCodeData.ApplySelfDataList(ShareStationData.bIsLogin, ShareStationData.nDataType)
        UIHelper.SetVisible(self.LayoutUploadNum, true)
        UIHelper.SetVisible(self.WidgetBtnManage, not ShareStationData.bIsLogin)
        UIHelper.LayoutDoLayout(self.LayoutRightTop)
        local tbSelfShareList = ShareStationData.GetSelfShareData(nSubType)
        if tbSelfShareList then
            self:UpdateShareList("Self", #tbSelfShareList, tbSelfShareList)
        end
    end

    for index, widget in ipairs(self["tbLeftWidget_"..self.szPageType]) do
        UIHelper.SetVisible(widget, true)
    end

    ShareStationData.tbEventLinkInfo = nil
end

function UIShareStationMainView:UpdateShareList(szPageType, nTotalCount, tRankList)
    if not self.scriptCardList then
        self.scriptCardList = UIHelper.GetBindScript(self.WidgetList)
        self.scriptCardList:OnEnter()
    end

    local bShowFilter = true
    if ShareStationData.nSearchType == SHARE_SEARCH_TYPE.USER and not string.is_nil(ShareStationData.szSearch) then
        bShowFilter = false
    end

    UIHelper.SetVisible(self.WidgetBenScreen, bShowFilter)
    UIHelper.SetVisible(self.WidgetBtnSort, bShowFilter or not not ShareStationData.szFilterAccount)
    UIHelper.SetVisible(self.WidgetExteriorScreen, bShowFilter and (ShareStationData.nDataType == SHARE_DATA_TYPE.EXTERIOR or ShareStationData.nDataType == SHARE_DATA_TYPE.PHOTO))
    if ShareStationData.nSearchType == SHARE_SEARCH_TYPE.CODE and not string.is_nil(ShareStationData.szSearch) then
        UIHelper.SetVisible(self.WidgetExteriorScreen, false) -- 这种情况是一定会隐藏的
        UIHelper.SetVisible(self.WidgetBtnSort, false)
        UIHelper.SetVisible(self.WidgetBenScreen, false)
    end

    UIHelper.SetString(self.LabelScreen_Exterior, ShareStationData.nDataType == SHARE_DATA_TYPE.EXTERIOR and "外观筛选" or "地图筛选")
    UIHelper.LayoutDoLayout(self.LayoutBtn)

    self.scriptCardList:UpdateInfo(szPageType, nTotalCount, tRankList)
    UIHelper.SetVisible(self.ImgScreenSelect, ShareStationData.IsInFilter(szPageType))
    UIHelper.SetVisible(self.ImgScreenSelect_Exterior, ShareStationData.IsInExteriorFilter())
end

function UIShareStationMainView:UpdateShareInfo(tbData)
    if not self.scriptRightCard then
        self.scriptRightCard = UIHelper.GetBindScript(self.WidgetAnchorRightContent)
        self.scriptRightCard:OnEnter()
    end

    local bEmpty = not tbData or table.is_empty(tbData)
    UIHelper.SetVisible(self.WidgetAnchorRightContent, not bEmpty)
    UIHelper.SetVisible(self.BtnBuy, not bEmpty)
    UIHelper.SetVisible(self.BtnApply, not bEmpty)
    UIHelper.SetVisible(self.BtnImport, not bEmpty)
    UIHelper.SetVisible(self.BtnUpdate, not bEmpty)
    UIHelper.SetVisible(self.BtnApplyPhoto, not bEmpty)
    UIHelper.SetVisible(self.BtnLocatePhoto, not bEmpty)
    UIHelper.SetVisible(self.LabelNotice, not bEmpty)
    UIHelper.SetVisible(self.WidgetImage, false)
    if bEmpty then
        return
    end

    self.tbCurSelectShare = tbData
    self.scriptRightCard:UpdateInfo(self.nDataType, tbData)
    if self.nDataType == SHARE_DATA_TYPE.PHOTO then
        UIHelper.SetVisible(self.WidgetImage, true)
        self:UpdatePhotoPreview()
    end

    local bEnablePreview = self.scriptRightCard:UpdateInvisible(self.szPageType)
    local bHaveData = false
    local tShareData = ShareCodeData.GetShareCodeData(tbData.szShareCode)
    local bIsOwner = ShareStationData.IsSelfShare(tbData.szShareCode)
    local bCanApply = tbData.nRoleType == ShareStationData.nRoleType
    local nOpenStatus = tbData.nOpenStatus

    if self.nDataType == SHARE_DATA_TYPE.FACE then
        local hManager = GetFaceLiftManager()
        if hManager and tShareData then
            bHaveData = hManager.IsAlreadyHave(tShareData)
        end
    elseif self.nDataType == SHARE_DATA_TYPE.BODY then
        -- local hManager = GetBodyReshapingManager()
        -- if hManager and tShareData then
        --     bHaveData = hManager.IsAlreadyHave(tShareData)
        -- end
    end

    local bShowPhotoBtn = self.nDataType == SHARE_DATA_TYPE.PHOTO and bEnablePreview

    if not ShareStationData.bIsLogin then
        UIHelper.SetVisible(self.BtnBuy, bCanApply and not bHaveData and self.nDataType ~= SHARE_DATA_TYPE.EXTERIOR and bEnablePreview and not bShowPhotoBtn)
        UIHelper.SetVisible(self.BtnApply, bCanApply and bHaveData and self.nDataType ~= SHARE_DATA_TYPE.EXTERIOR and bEnablePreview and not bShowPhotoBtn)
        UIHelper.SetVisible(self.BtnApplyPhoto, bShowPhotoBtn)
        UIHelper.SetVisible(self.BtnLocatePhoto, bShowPhotoBtn)
        UIHelper.SetVisible(self.BtnImport, self.nDataType == SHARE_DATA_TYPE.EXTERIOR and bEnablePreview and not bShowPhotoBtn)
    else
        UIHelper.SetVisible(self.BtnBuy, false)
        UIHelper.SetVisible(self.BtnImport, false)
        UIHelper.SetVisible(self.BtnApplyPhoto, false)
        UIHelper.SetVisible(self.BtnLocatePhoto, false)
        UIHelper.SetVisible(self.BtnApply, bCanApply and bEnablePreview and not bShowPhotoBtn)
    end

    UIHelper.SetVisible(self.BtnUpdate, bIsOwner and not ShareStationData.bIsLogin and
        (nOpenStatus == SHARE_OPEN_STATUS.COVER_ILLEGAL
            or string.is_nil(tbData.szCoverFileLink)))
    UIHelper.SetVisible(self.LabelNotice, not bCanApply and bEnablePreview and self.nDataType ~= SHARE_DATA_TYPE.EXTERIOR and not bShowPhotoBtn)
    self:UpdateDownloadEquipRes()
end

function UIShareStationMainView:UpdatePhotoPreview()
    local tbData = self.tbCurSelectShare
    if not tbData then
        return
    end
    local szCoverPath = tbData.szCoverPath --封面路径
    local bHaveCover = szCoverPath and szCoverPath ~= "" and Lib.IsFileExist(szCoverPath, false)
    local bShowCover = true
    local bEnablePreview = true
    local nOpenStatus = tbData.nOpenStatus

    if self.szPageType == "Rank" then
        bShowCover = nOpenStatus == SHARE_OPEN_STATUS.PUBLIC
        bEnablePreview = nOpenStatus == SHARE_OPEN_STATUS.PUBLIC
    elseif self.szPageType == "Like" then
        bShowCover = nOpenStatus == SHARE_OPEN_STATUS.PUBLIC
        bEnablePreview = nOpenStatus == SHARE_OPEN_STATUS.PUBLIC
    elseif self.szPageType == "Self" then
        bEnablePreview = nOpenStatus == SHARE_OPEN_STATUS.PUBLIC
            or nOpenStatus == SHARE_OPEN_STATUS.PRIVATE
            or nOpenStatus == SHARE_OPEN_STATUS.COVER_ILLEGAL
    end

    for nType, label in ipairs(self.tbPreviewPhotoLabelHint) do
        UIHelper.SetVisible(label, not bEnablePreview)
    end

    for nType, widget in ipairs(self.tbPreviewPhotoWidget) do
        UIHelper.SetVisible(widget, nType == tbData.nPhotoSizeType)
    end

    local img = self.tbPreviewPhotoImg[tbData.nPhotoSizeType]
    UIHelper.ClearTexture(img)
    UIHelper.ReloadTexture(szCoverPath)

    if bHaveCover and bShowCover and bEnablePreview then
        UIHelper.SetTexture(img, szCoverPath, false)
    end

    UIHelper.SetVisible(self.ImgEmpty, not bHaveCover or not bShowCover or not bEnablePreview)
    for _, btn in ipairs(self.tbPreviewPhotoScanBtn) do
        UIHelper.SetVisible(btn, bHaveCover and bShowCover and bEnablePreview)
    end
end

function UIShareStationMainView:UpdateLikeInfo()
    local nMaxNum = MAX_COLLECT_COUNT
    local nSubType = ShareStationData.nSubType
    local nCount = ShareStationData.GetLikeShareCount()
    UIHelper.SetString(self.LabelCollectNum, nCount)
    UIHelper.SetString(self.LabelCollectMax, "/"..nMaxNum)
    UIHelper.LayoutDoLayout(self.LayoutCollectNum)
    UIHelper.LayoutDoLayout(self.LayoutRightTop)
end

function UIShareStationMainView:UpdateSelfInfo()
    local tConfig = ShareCodeData.GetAccountConfig(self.nDataType)
    if not tConfig then
        return
    end

    local nCount = tConfig.nCount
    local nMaxNum = tConfig.nUploadLimit or 0
    UIHelper.SetString(self.LabelUploadNum, nCount)
    UIHelper.SetString(self.LabelUploadMax, "/"..nMaxNum)
    -- UIHelper.SetString(self.LabelUploadNumTittle, "上传数：")

    UIHelper.SetEnable(self.TogManage, nCount > 0)
    UIHelper.SetNodeGray(self.WidgetBtnManage, nCount <= 0, true)
    UIHelper.LayoutDoLayout(self.LayoutBtn)

    UIHelper.LayoutDoLayout(self.LayoutUploadNum)
    UIHelper.LayoutDoLayout(self.LayoutRightTop)
end

function UIShareStationMainView:OnSearch(szSearch)
    local nDataType = self.nDataType
    ShareStationData.szSearch = szSearch
    if self.szPageType == "Rank" then
        if ShareStationData.nSearchType == SHARE_SEARCH_TYPE.USER then
            self.tbCreatorCache = self.tbCreatorCache or {}
            self.tbCreatorCache[nDataType] = self.tbCreatorCache[nDataType] or {}
            local nCurTime = ShareCodeData.GetCurrentTime(ShareStationData.bIsLogin)
            local tCreatorList = self.tbCreatorCache[nDataType][szSearch]
            if tCreatorList and tCreatorList.nGetTime - nCurTime < CREATOR_SEARCH_CACHE_TIME then
                Event.Dispatch(EventType.OnGetShareStationCreatorList, nDataType, tCreatorList)
                return
            else
                self.tbCreatorCache[nDataType][szSearch] = nil
            end
        end

        ShareStationData.ApplyShareStationData()
    else
        self:UpdateShareList(self.szPageType)
    end
end

function UIShareStationMainView:ResetFilter()
    local tbTagFilter = nil
    self.tbMainFilter = nil
    self.tbSortFilter = nil

    ShareStationData.nSortType = 1
    ShareStationData.nSourceType = 1
    ShareStationData.nRangeType = 3
    ShareStationData.nFilterRoleType = ShareStationData.nRoleType
    ShareStationData.nFilterOpenState = -1
    ShareStationData.bHairDyeing = false
    ShareStationData.szFilterAccount = nil
    ShareStationData.tFilterExterior = {}
    ShareStationData.nPhotoMapType = -1
    ShareStationData.dwPhotoMapID = -1
    ShareStationData.SetFilterTag({})

    if self.szPageType and (self.szPageType == "Like" or self.szPageType == "Self") then
        ShareStationData.nRangeType = 1
        ShareStationData.nFilterRoleType = -1
        self.tbSortFilter = FilterDef.ShareStationTimeRange
        self.tbMainFilter = FilterDef.ShareStationFilter_NoneTime
        tbTagFilter = FilterDef.ShareStationFilter_NoneTime[3]
        self.tbSortFilter[1].szTitle = self.szPageType == "Like" and "收藏时间" or "上传时间"
    else
        self.tbSortFilter = FilterDef.ShareStationHeatRank
        self.tbMainFilter = FilterDef.ShareStationFilter
        tbTagFilter = FilterDef.ShareStationFilter[4]
    end

    if self.nDataType == SHARE_DATA_TYPE.EXTERIOR then -- 外观多了个自定义数据，不好加在一起
        self.tbMainFilter = FilterDef.ShareStationFilter_Exterior
        tbTagFilter = FilterDef.ShareStationFilter_Exterior[5]

        if self.szPageType == "Like" or self.szPageType == "Self" then
            self.tbMainFilter = FilterDef.ShareStationFilter_NoneTime_Exterior
            tbTagFilter = FilterDef.ShareStationFilter_NoneTime_Exterior[4]
        end
    end

    if self.tbMainFilter and tbTagFilter then
        self.tbTagList = {}
        tbTagFilter.tbList = {}
        local tbTagList = Table_GetShareStationTagList(self.nDataType)
        for nIndex, v in ipairs(tbTagList) do
            local szName = UIHelper.GBKToUTF8(v.szName)
            table.insert(tbTagFilter.tbList, szName)
            self.tbTagList[nIndex] = v
        end
    end

    self:InitSearchTypeToggle()
    UIHelper.SetText(self.EditKindSearch, "")

    local nRoleFilterIndex = RoleType2Index[ShareStationData.nFilterRoleType] or 0
    if self.nDataType == SHARE_DATA_TYPE.PHOTO then
        nRoleFilterIndex = 0
    end

    if self.tbMainFilter and self.tbMainFilter.Reset then
        local tbRuntime = {}
        if self.szPageType == "Rank" then
            tbRuntime[1] = {nRoleFilterIndex + 1}
            ShareStationData.nFilterRoleType = Index2RoleType[nRoleFilterIndex]
        end

        tbRuntime[2] = {ShareStationData.nRangeType} -- 策划需求：默认选一周内，但是需要重置后是全部
        if self.nDataType == SHARE_DATA_TYPE.PHOTO then
            if self.szPageType == "Rank"then
                ShareStationData.nSourceType = 3 -- 拍照站默认选当前端
                tbRuntime[3] = {3}
            end
        end
        self.tbMainFilter.Reset()
        self.tbMainFilter.SetRunTime(tbRuntime)
    end

    if self.tbSortFilter and self.tbSortFilter.Reset then
        self.tbSortFilter.Reset()
    end

    if self.nDataType == SHARE_DATA_TYPE.EXTERIOR then
        nRoleFilterIndex = 0 -- 搭配默认选全部
    end
    self.tbMainFilter[1].tbDefault = {nRoleFilterIndex + 1}
end

function UIShareStationMainView:OnLink2Share()
    if not ShareStationData.tbEventLinkInfo then
        return
    end

    self:ResetFilter()

    local nDataType = ShareStationData.tbEventLinkInfo.nDataType
    local nSubType = ShareStationData.tbEventLinkInfo.nSubType
    for nIndex, v in ipairs(self.tbPageTypeToggle) do
        UIHelper.SetSelected(v, nIndex == 1, false)
    end
    self.szPageType = PAGE_TYPE[1]
    self.scriptCardList.nCurPage = 1
    ShareStationData.SetViewPage(self.scriptCardList.nCurPage)

    if ShareStationData.tbEventLinkInfo.szShareCode and ShareStationData.tbEventLinkInfo.szShareCode ~= "" then
        ShareStationData.SetSearchType(SHARE_SEARCH_TYPE.CODE)
    end

    self.tbShareTypeToggle = self.tbShareTypeToggle or {}
    for index, script in ipairs(self.tbShareTypeToggle) do
        UIHelper.SetSelected(script.TogSelect, index == nDataType)
    end

    if nDataType == SHARE_DATA_TYPE.FACE then
        local szSuffix = TYPE_TO_SUFFIX[nSubType] or NEW_FACE_SUFFIX
        UIHelper.SetSelected(self.Tog_Vision, szSuffix == NEW_FACE_SUFFIX, false)
    elseif nDataType == SHARE_DATA_TYPE.PHOTO then
        ShareStationData.nPhotoSizeType = nSubType
        for index, tog in ipairs(self.tbPhotoTypeToggle) do
            UIHelper.SetSelected(tog, index == nSubType, false)
        end
    end
end

function UIShareStationMainView:UpdateDownloadEquipRes()
    if not PakDownloadMgr.IsEnabled() then
        return
    end

    local tRepresentID = clone(ExteriorCharacter.GetRoleRes())
    DealWithDecorationShowFlag(tRepresentID.tFaceData)

    local nRoleType = g_pClientPlayer.nRoleType
    local tEquipList, tEquipSfxList = Player_GetPakEquipResource(nRoleType, tRepresentID.nHatStyle, tRepresentID)

    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownloadBtnShell)
    local tConfig = {}
    tConfig.bLong = true
    local bRemoteNotExist
    self.nDownloadDynamicID, bRemoteNotExist = PakDownloadMgr.UserCheckDownloadEquipRes(nRoleType, tEquipList, tEquipSfxList, self.nDownloadDynamicID)
    CoinShopPreview.UpdateSimpleDownloadBtn(scriptDownload, self.nDownloadDynamicID, bRemoteNotExist, tConfig)
end

return UIShareStationMainView