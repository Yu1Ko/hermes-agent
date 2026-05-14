-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMyHomeAttributeInfo
-- Date: 2023-03-29 19:16:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandMyHomeAttributeInfo = class("UIHomelandMyHomeAttributeInfo")

function UIHomelandMyHomeAttributeInfo:OnEnter(nMapID, nCopyIndex, dwSkinID, nLandIndex)
    self.nMapID = nMapID
    self.nCopyIndex = nCopyIndex
    self.dwSkinID = dwSkinID
    self.nLandIndex = nLandIndex

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
    RedpointMgr.RegisterRedpoint(self.ImgLogRedDot, nil, {3805}) -- 日志红点
end

function UIHomelandMyHomeAttributeInfo:OnExit()
    self.bInit = false
    RedpointMgr.UnRegisterRedpoint(self.ImgLogRedDot, {3805}) -- 日志红点
end

function UIHomelandMyHomeAttributeInfo:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnHome, EventType.OnClick, function ()
        local nMapID = self.nMapID
        local nCopyIndex = self.nCopyIndex
        local dwSkinID = self.dwSkinID
        local nLandIndex = self.nLandIndex

        local function _goPrivateLand()
            if HomelandData.IsPrivateHome(nMapID) then
	            HomelandData.GoPrivateLand(nMapID, nCopyIndex, dwSkinID, 1)
            else
                HomelandData.BackToLand(nMapID, nCopyIndex, nLandIndex)
            end
            UIMgr.Close(VIEW_ID.PanelHome)
            UIMgr.Close(VIEW_ID.PanelSystemMenu)
            Event.Dispatch(EventType.HideAllHoverTips)
        end
        if PakDownloadMgr.UserCheckDownloadHomelandRes(nMapID, dwSkinID, _goPrivateLand) then
            _goPrivateLand()
        end
    end)

    UIHelper.BindUIEvent(self.BtnVisiting, EventType.OnClick, function ()
        local nMapID = self.nMapID
        local nCopyIndex = self.nCopyIndex
        local dwSkinID = self.dwSkinID
        local nLandIndex = self.nLandIndex

        local function _goPrivateLand()
            HomelandData.BackToLand(nMapID, nCopyIndex, nLandIndex)
            UIMgr.Close(VIEW_ID.PanelHome)
            UIMgr.Close(VIEW_ID.PanelSystemMenu)
            Event.Dispatch(EventType.HideAllHoverTips)
        end
        if PakDownloadMgr.UserCheckDownloadHomelandRes(nMapID, dwSkinID, _goPrivateLand) then
            _goPrivateLand()
        end
    end)

    UIHelper.BindUIEvent(self.BtnHomeAttributeIcon, EventType.OnClick, function ()
        UIHelper.SetVisible(self.WidgetHomeAttributeTips, not UIHelper.GetVisible(self.WidgetHomeAttributeTips))
    end)
    UIHelper.SetSwallowTouches(self.BtnHomeAttributeIcon, false)

    UIHelper.BindUIEvent(self.BtnLog, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelHomeJournalPop, self.nMapID)
    end)

    UIHelper.SetTouchDownHideTips(self.BtnHome, false)
    UIHelper.SetTouchDownHideTips(self.BtnLog, false)
    UIHelper.SetTouchDownHideTips(self.BtnHomeAttributeIcon, false)
    UIHelper.SetTouchDownHideTips(self.BtnVisiting, false)
    UIHelper.SetTouchDownHideTips(self.ScrollViewHomeAttributeIcon, false)
    UIHelper.SetTouchDownHideTips(self.ScrollViewHomePlot, false)
end

function UIHomelandMyHomeAttributeInfo:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        UIHelper.SetVisible(self.WidgetHomeAttributeTips, false)
    end)

    Event.Reg(self, EventType.OnViewOpen, function ()
        UIHelper.SetVisible(self.WidgetHomeAttributeTips, false)
    end)
end

function UIHomelandMyHomeAttributeInfo:UpdateInfo()
    local tbConfig = Table_GetHomelandGameplayInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewHomeAttributeIcon)
	for i = 1, 8 do
		local tbInfo = tbConfig[i]
		if tbInfo then
			local bUnlocked = GetHomelandMgr().GetLandSeasonData(self.nMapID, self.nCopyIndex, self.nLandIndex, i - 1, 1) == 1
            local scriptIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetRightHomeAttributeIcon, self.ScrollViewHomeAttributeIcon)
            scriptIcon:OnEnter(tbInfo.nBit, not bUnlocked)
		end
	end

    UIHelper.ScrollViewDoLayout(self.ScrollViewHomeAttributeIcon)
    UIHelper.ScrollToLeft(self.ScrollViewHomeAttributeIcon, 0)

    local tbInfo = GetHomelandMgr().GetLandInfo(self.nMapID, self.nCopyIndex, self.nLandIndex) or {}
    local scriptCell = UIHelper.GetBindScript(self.WidgetRightHomeAttributeInfo)
    scriptCell:OnEnter(6, tbInfo.dwRecordInfo or 0)

    local szText = ""

    if not HomelandData.IsPrivateHome(self.nMapID) then
        local bIsSelling, bPrepareToSale, bIsOpen, nLevel, nAllyCount, eMarketType1, eMarketType2 = GetHomelandMgr().GetLandState(self.nMapID, self.nCopyIndex, self.nLandIndex)
        if not bIsOpen then
            szText = szText .. "房主设置了家具交互权限"
        end

        if nAllyCount > 0 then
            if not string.is_nil(szText) then
                szText = szText .. "\n"
            end

            szText = szText .. string.format("共居人数：%d", nAllyCount)
        end
    end

    if not string.is_nil(szText) then
        UIHelper.SetString(self.LabelLimit, szText)
        UIHelper.SetVisible(self.LabelLimit, true)
    else
        UIHelper.SetVisible(self.LabelLimit, false)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewHomePlot)
    UIHelper.ScrollToTop(self.ScrollViewHomePlot, 0)

    local bIsMyHome = GetHomelandMgr().IsMyLand(self.nMapID, self.nCopyIndex, self.nLandIndex)
    if not HomelandData.IsPrivateHome(self.nMapID) and not bIsMyHome then
        UIHelper.SetVisible(self.BtnHome, false)
        UIHelper.SetVisible(self.BtnLog, false)
        UIHelper.SetVisible(self.BtnVisiting, true)
    else
        UIHelper.SetVisible(self.BtnHome, true)
        UIHelper.SetVisible(self.BtnLog, true)
        UIHelper.SetVisible(self.BtnVisiting, false)
    end

    UIHelper.LayoutDoLayout(self.LayoutButton)

    self:UpdateIconTipInfo()
end

function UIHomelandMyHomeAttributeInfo:UpdateIconTipInfo()
    local tbConfig = Table_GetHomelandGameplayInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewAttribute)
    UIHelper.SetTouchDownHideTips(self.ScrollViewAttribute, false)
    for i = 1, 8 do
		local tbInfo = tbConfig[i]
		if tbInfo then
			local bUnlocked = GetHomelandMgr().GetLandSeasonData(self.nMapID, self.nCopyIndex, self.nLandIndex, i - 1, 1) == 1
            local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetAttributeTipsCell, self.ScrollViewAttribute)
            scriptCell:OnEnter(tbInfo.nBit, not bUnlocked)
		end
	end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAttribute)
end


return UIHomelandMyHomeAttributeInfo