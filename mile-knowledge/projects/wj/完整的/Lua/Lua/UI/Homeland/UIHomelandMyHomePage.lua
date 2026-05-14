-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMyHomePage
-- Date: 2023-03-27 16:52:17
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandMyHomePage = class("UIHomelandMyHomePage")
local DataModel = DataModel

local MapID2PrefabID = {
    [455] = PREFAB_ID.WidgetHomeLandMapWYZ,
    [462] = PREFAB_ID.WidgetHomeLandMapJZGJH,
    [471] = PREFAB_ID.WidgetHomeLandMapYLY,
    [486] = PREFAB_ID.WidgetHomeLandMapNTY,
    [565] = PREFAB_ID.WidgetHomeLandMapIndividual,
    [674] = PREFAB_ID.WidgetHomeLandMapHHSX,
}

function UIHomelandMyHomePage:OnEnter(nMapID, nCopyIndex, nLandIndex, dwSkinID, tbCommunityInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nMapID = nMapID or 565
    self.nCopyIndex = nCopyIndex
    self.nLandIndex = nLandIndex or 0
    self.dwSkinID = dwSkinID or 0
    self.tbCommunityInfo = tbCommunityInfo

    self.bIsGroupBuyMap = HomelandData.IsGroupBuy(self.nMapID) -- 家园定制相关
    self.bInitRightHomeInfo = false

    self:InitView()

    self:UpdateInfo()
end

function UIHomelandMyHomePage:InitDataModel(tbDataModel)
    DataModel = tbDataModel
end

function UIHomelandMyHomePage:OnExit()
    self.bInit = false
end

function UIHomelandMyHomePage:BindUIEvent()
    UIHelper.BindUIEvent(self.TogHomeTilte, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetCommunityTips, self.WidgetCutMap, TipsLayoutDir.MIDDLE, DataModel.nCenterID, self.nMapID)
    end)

    UIHelper.BindUIEvent(self.BtnPreview, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelPreviewHome, self.nMapID, self.nCopyIndex, self.dwSkinID)
    end)

    UIHelper.SetTouchDownHideTips(self.EditKindSearch, false)

    UIHelper.BindUIEvent(self.BtnBranching, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelHomeLandRank, DataModel)
    end)

    UIHelper.BindUIEvent(self.BtnDesign, EventType.OnClick, function ()
        local player = GetClientPlayer()
        if not player then
            return
        end
        local nType, dwID, dwLevel, fP = player.GetSkillOTActionState()
        if nType ~= CHARACTER_OTACTION_TYPE.ACTION_IDLE then
            TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_DESIGN_ERROR_STATR)
            return
        end

        UIMgr.Open(VIEW_ID.PanelDesignField)
    end)
    -- UIHelper.SetVisible(self.BtnDesign, false)

    UIHelper.BindUIEvent(self.BtnSift, EventType.OnClick, function ()
        if self.tbCommunityInfo and self.tbCommunityInfo.nLevel then
            UIMgr.Open(VIEW_ID.PanelHomeLandPop, self.tbCommunityInfo.nLevel)
        else
            TipsHelper.ShowNormalTip("数据异常，请稍后重试")
        end
    end)

    UIHelper.BindUIEvent(self.BtnIdentity, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelHomeIdentity)
    end)

    UIHelper.BindUIEvent(self.BtnCustomization, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelCustomBuyPop, self.nMapID)
    end)

    UIHelper.SetTouchDownHideTips(self.BtnQuestion, false)
    UIHelper.BindUIEvent(self.BtnQuestion, EventType.OnClick, function ()
        if not DataModel.tRecommendList or DataModel.tRecommendList.nTotalSize <= 0 then
            TipsHelper.ShowNormalTip("暂无开放的分线")
            return
        else
            UIHelper.SetPlaceHolder(self.EditKindSearch, string.format("已开放1-%d分线", DataModel.tRecommendList.nTotalSize))
        end
        UIHelper.SetVisible(self.WidgetEdit, true)
        UIHelper.SetVisible(self.WidgetExit, true)
    end)

    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function ()
        UIMgr.OpenSingle(false, VIEW_ID.PanelBuyQuicklyPop, nil, nil, DataModel)
    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditKindSearch, function()
            self:OnEditFinsih()
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditKindSearch, function()
            self:OnEditFinsih()
        end)
    end
end

function UIHomelandMyHomePage:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        self.nCurSelectAreaIndex = nil
        self:UpdateRightInfo()

        UIHelper.SetSelected(self.BtnQuestion, false)
        UIHelper.SetSelected(self.TogHomeTilte, false)
    end)

    Event.Reg(self, EventType.OnSelectHomelandMyHomeArea, function (nIndex)
        self.nCurSelectAreaIndex = nIndex
        self:UpdateRightInfo()
    end)

    Event.Reg(self, EventType.OnClickHomelandMyHomeRankListIndex, function (nIndex)
        self.nCurSelectAreaIndex = nil
        self:UpdateRightInfo()
    end)

    Event.Reg(self, EventType.OnViewOpen, function (nViewID)
        if nViewID == VIEW_ID.PanelHomeLandRank or nViewID == VIEW_ID.PanelBuyQuicklyPop then
            UIHelper.SetPositionX(self.WidgetHomeLandMap, 280)
        end
    end)

    Event.Reg(self, EventType.OnViewClose, function (nViewID)
        if nViewID == VIEW_ID.PanelHomeLandRank or nViewID == VIEW_ID.PanelBuyQuicklyPop then
            UIHelper.SetPositionX(self.WidgetHomeLandMap, 0)
        end
    end)

    Event.Reg(self, EventType.OnShowPageBottomBar, function(callback, bIsRightSidePage)
        if bIsRightSidePage then
            UIHelper.PlayAni(self, self.AniAll, "AniRightShow")
        else
            UIHelper.PlayAni(self, self.AniAll, "AniLeftShow")
        end
    end)

    Event.Reg(self, EventType.OnHidePageBottomBar, function(callback, bIsRightSidePage)
        if bIsRightSidePage then
            UIHelper.PlayAni(self, self.AniAll, "AniRightHide")
        else
            UIHelper.PlayAni(self, self.AniAll, "AniLeftHide")
        end
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardConfirmed, function (editBox, nCurNum)
        if editBox == self.EditKindSearch then
            self:OnEditFinsih()
        end
    end)
end

function UIHomelandMyHomePage:InitView()
    if not self.scriptRightHomeInfo then
        self.scriptRightHomeInfo = UIHelper.GetBindScript(self.WidgetRightHomeInfo)
    end

    if not self.scriptRightHomeAreaInfo then
        self.scriptRightHomeAreaInfo = UIHelper.GetBindScript(self.WidgetRightHomeModelInfo)
    end
end

function UIHomelandMyHomePage:UpdateInfo()
    self:UpdateMapInfo()
    self:UpdateRightInfo()
    self:ApplyGroupBuyData()
    UIHelper.LayoutDoLayout(self.WidgetAnchorRightTop)
end

function UIHomelandMyHomePage:UpdateMapInfo()
    UIHelper.RemoveAllChildren(self.WidgetHomeLandMap)
    self.scriptMap = UIHelper.AddPrefab(MapID2PrefabID[self.nMapID],
        self.WidgetHomeLandMap,
        self.nMapID,
        self.nCopyIndex,
        self.nLandIndex,
        self.dwSkinID,
        self.tbCommunityInfo)

    if HomelandData.IsPrivateHome(self.nMapID) then
        self.tbSkinInfo = Table_GetPrivateHomeSkin(self.nMapID, self.dwSkinID)
        self.tbLandInfo = Table_GetMapLandInfo(self.nMapID, self.nLandIndex)

        UIHelper.SetVisible(self.LayoutSkinText, true)
        UIHelper.SetVisible(self.LabelCommunityInfo, false)
        UIHelper.SetVisible(self.WidgetResidue, false)
        UIHelper.SetVisible(self.WidgetNewCommunity, false)
        UIHelper.SetString(self.LabelHomeName, UIHelper.GBKToUTF8(self.tbSkinInfo.szLandName))
        UIHelper.SetString(self.LabelSkin, string.format("皮肤：%s", UIHelper.GBKToUTF8(self.tbSkinInfo.szSkinName)))
    else
        UIHelper.SetVisible(self.LayoutSkinText, false)
        UIHelper.SetVisible(self.LabelCommunityInfo, true)
        UIHelper.SetVisible(self.WidgetResidue, self.bIsGroupBuyMap and HomelandData.IsJustCanGroupBuy(self.nMapID))
        UIHelper.SetVisible(self.WidgetNewCommunity, false)

        UIHelper.SetString(self.LabelHomeName, string.format("%s-%s",  UIHelper.GBKToUTF8(Table_GetMapName(self.nMapID)), tostring(self.tbCommunityInfo.nIndex)))

        local szText = "入住率："..tostring(math.floor(self.tbCommunityInfo.nSoldNum / self.tbCommunityInfo.nLandCount * 100)) ..
			'%(' .. tostring(self.tbCommunityInfo.nSoldNum) .. '/' .. tostring(self.tbCommunityInfo.nLandCount) .. ')'.. '\n'

        szText = szText .. "社区等级：" .. tostring(self.tbCommunityInfo.nLevel) .. "\n"
        szText = szText .. "活跃值：" .. tostring(self.tbCommunityInfo.nActiveValue)

        UIHelper.SetRichText(self.LabelCommunityInfo, szText)
    end
    UIHelper.CascadeDoLayoutDoWidget(self.WidgetHomeInfo, true, true)
end

function UIHomelandMyHomePage:UpdateRightInfo()
    if HomelandData.IsPrivateHome(self.nMapID) then
        UIHelper.SetVisible(self.BtnSift, false)
        UIHelper.SetVisible(self.BtnBuy, false)
        UIHelper.SetVisible(self.BtnQuestion, false)
        UIHelper.SetVisible(self.ImgBgTitleLine, false)
        UIHelper.SetVisible(self.WidgetCustomization, false)
        if self.nCurSelectAreaIndex then
            UIHelper.SetVisible(self.scriptRightHomeAreaInfo._rootNode, true)
            UIHelper.SetVisible(self.scriptRightHomeInfo._rootNode, false)
            self.scriptRightHomeAreaInfo:OnEnter(self.nMapID, self.nCopyIndex, self.dwSkinID, self.nLandIndex, self.nCurSelectAreaIndex)
        elseif not UIHelper.GetVisible(self.scriptRightHomeInfo._rootNode) or not self.bInitRightHomeInfo then
            self.bInitRightHomeInfo = true
            UIHelper.SetVisible(self.scriptRightHomeAreaInfo._rootNode, false)
            UIHelper.SetVisible(self.scriptRightHomeInfo._rootNode, true)
            self.scriptRightHomeInfo:OnEnter(self.nMapID, self.nCopyIndex, self.dwSkinID, self.nLandIndex)
        end
    else
        if self.nCurSelectAreaIndex then
            UIHelper.SetVisible(self.scriptRightHomeAreaInfo._rootNode, false)
            UIHelper.SetVisible(self.scriptRightHomeInfo._rootNode, true)
            UIHelper.SetVisible(self.WidgetCustomization, false)

            self.scriptRightHomeInfo:OnEnter(self.nMapID, self.nCopyIndex, 0, self.nCurSelectAreaIndex, self.tbCommunityInfo.nIndex)
        else
            UIHelper.SetVisible(self.scriptRightHomeAreaInfo._rootNode, false)
            UIHelper.SetVisible(self.scriptRightHomeInfo._rootNode, false)
            UIHelper.SetVisible(self.WidgetCustomization, self.bIsGroupBuyMap)
            UIHelper.SetVisible(self.LabelNewCustomization, not HomelandData.IsJustCanGroupBuy(self.nMapID))
            UIHelper.LayoutDoLayout(self.ImgResidueBg)
        end
        UIHelper.SetVisible(self.BtnSift, true)
        UIHelper.SetVisible(self.BtnBuy, true)
        UIHelper.SetVisible(self.BtnQuestion, true)
        UIHelper.SetVisible(self.ImgBgTitleLine, true)

        if DataModel.tRecommendList then
            UIHelper.SetPlaceHolder(self.EditKindSearch, string.format("已开放1-%d分线", DataModel.tRecommendList.nTotalSize))
        end
    end

    UIHelper.SetVisible(self.BtnBranching, not HomelandData.IsPrivateHome(self.nMapID))
end

function UIHomelandMyHomePage:UpdateHomeList(tbHomeInfo, nCurSelectMapID)
    UIHelper.HideAllChildren(self.LayoutHousehold)

    self.tbHomeCells = self.tbHomeCells or {}
    local lastCell
    for i, tbInfo in ipairs(tbHomeInfo) do
        if not self.tbHomeCells[i] then
            self.tbHomeCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetHomeLandHousehold, self.LayoutHousehold)
            UIHelper.ToggleGroupAddToggle(self.TogGroupHouse, self.tbHomeCells[i].TogHome)
            UIHelper.ToggleGroupAddToggle(self.TogGroupHouse, self.tbHomeCells[i].TogCustom)
        end
        self.tbHomeCells[i]:OnEnter(tbInfo)
        UIHelper.SetVisible(self.tbHomeCells[i]._rootNode, true)
        lastCell = self.tbHomeCells[i]
    end

    if lastCell then
        UIHelper.SetVisible(lastCell.ImgLine, false)
    end
    UIHelper.LayoutDoLayout(self.LayoutHousehold)
end

function UIHomelandMyHomePage:ApplyGroupBuyData()
	if not self.bIsGroupBuyMap then
        return
    end
	GetHomelandMgr().ApplyCommunityCount(self.nMapID)
end

function UIHomelandMyHomePage:UpdateGroupBuyInfo()
	if not self.bIsGroupBuyMap then
        return
    end
	local nCommunityCount = GetHomelandMgr().GetCommunityCount(self.nMapID)
	local nAllGrouponCount
	local tTable = GetHomelandMgr().GetHomelandMapList()
	for k, v in pairs(tTable) do
		if v.MapID == self.nMapID and v.IsGroupon == 1 then
			nAllGrouponCount = v.GrouponCount
			break
		end
	end
	if not nAllGrouponCount then
		return
	end
	local nGroupBuyLeftNum = math.max(0, nAllGrouponCount - nCommunityCount)
	UIHelper.SetString(self.LabelResidue, string.format("余：%s", tostring(nGroupBuyLeftNum)))
end

function UIHomelandMyHomePage:UpdatePlayerHomeTog(nMapID, nCopyIndex, nLandIndex)
    for _, cell in ipairs(self.tbHomeCells or {}) do
        cell:UpdatePlayerHomeTog(nMapID, nCopyIndex, nLandIndex)
    end
end

function UIHomelandMyHomePage:ClearCurSelectAreaIndex()
    self.nCurSelectAreaIndex = nil
end

function UIHomelandMyHomePage:OnEditFinsih()
    local szIndex = UIHelper.GetString(self.EditKindSearch)
    if not szIndex or szIndex == "" then
        UIHelper.SetSelected(self.BtnQuestion, false)
        return
    end
    local nIndex = tonumber(szIndex)
    if nIndex then
        if nIndex < 1 or nIndex > DataModel.tRecommendList.nTotalSize then
            TipsHelper.ShowNormalTip("暂无该分线")
        else
            DataModel.ApplyCommunityInfo(DataModel.tRecommendList.nMapID, nil, DataModel.tRecommendList.nCenterID, nIndex, true)
        end
    else
        TipsHelper.ShowNormalTip("暂无该分线")
    end
    UIHelper.SetString(self.EditKindSearch, "")
    UIHelper.SetSelected(self.BtnQuestion, false)
end

return UIHomelandMyHomePage