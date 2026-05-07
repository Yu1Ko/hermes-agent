-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandPVPPage
-- Date: 2023-04-04 17:08:17
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandPVPPage = class("UIHomelandPVPPage")
local LAST_WEEK = 0
local THIS_WEEK = 1

function UIHomelandPVPPage:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    HomelandPVPData.Init()
    self:Init()
end

function UIHomelandPVPPage:OnExit()
    self.bInit = false
    HomelandPVPData.UnInit()
end

function UIHomelandPVPPage:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnSwitchoverL, EventType.OnClick, function ()
		self.bShowNextWeekInfo = false
		self:UpdateWeekInfo()
	end)

	UIHelper.BindUIEvent(self.BtnSwitchoverR, EventType.OnClick, function ()
		self.bShowNextWeekInfo = true
		self:UpdateWeekInfo()
	end)

	UIHelper.BindUIEvent(self.BtnView, EventType.OnClick, function ()
		UIMgr.Open(VIEW_ID.PanelItemViewPop)
	end)

	UIHelper.BindUIEvent(self.BtnReward, EventType.OnClick, function ()
		UIMgr.Open(VIEW_ID.PanelRewardExplainPop)
	end)

	UIHelper.BindUIEvent(self.BtnRanking, EventType.OnClick, function ()
		TipsHelper.ShowNormalTip("暂未开放")
		-- UIMgr.Open(VIEW_ID.PanelHomeMatchRightPop)
	end)

	UIHelper.BindUIEvent(self.BtnGuideSkip, EventType.OnClick, function ()
		local tAllLinkInfo = Table_GetCareerGuideAllLink(2233)
		if #tAllLinkInfo > 0 then
			local tbTravel = tAllLinkInfo[1]
			MapMgr.SetTracePoint("阿壶", tbTravel.dwMapID, {tbTravel.fX, tbTravel.fY, tbTravel.fZ})
			UIMgr.Open(VIEW_ID.PanelMiddleMap, tbTravel.dwMapID, 0)
		end
	end)
end

function UIHomelandPVPPage:RegEvent()
    Event.Reg(self, "HOME_LAND_RESULT_CODE_INT", function(nRetCode, ...)
		if nRetCode == HOMELAND_RESULT_CODE.APPLY_HL_RANK_INFO_RESPOND then
			local nType, nIndex, nInfo, nTotalScore = ...
			if nType == LAST_WEEK then
				self:UpdateMyRankInfo(nIndex, nInfo, nTotalScore)
			end
		end
	end)

	Event.Reg(self, EventType.HideAllHoverTips, function()
		self:ClearSelect()
	end)
end

function UIHomelandPVPPage:Init()
    self:UpdateSuit()
	self:UpdateBaseInfo()
	self:UpdateWeekInfo()
	self:UpdateTitleFrameInfo()
end

function UIHomelandPVPPage:UpdateBaseInfo()
	local nHaveItem 	= GetClientPlayer().GetItemAmountInPackage(5, 48833)
	UIHelper.SetString(self.LabelCurrency, tostring(nHaveItem))
	-- UIHelper.SetTexture(self.ImgCurrency, "Resource/icon/xxx")
end

function UIHomelandPVPPage:UpdateMyRankInfo(nIndex, nInfo, nTotalScore)
	local szRank = ""
    if nInfo == 0 then
		szRank = "-"
	elseif nIndex ~= 0 then
		szRank = FormatString(g_tStrings.STR_HOMELAND_PVP_RANK, nIndex)
	else
		szRank = FormatString(g_tStrings.STR_HOMELAND_PVP_RANK_PERCENTAGE, nInfo)
	end
    UIHelper.SetString(self.LabelRanking, string.format("本周排名：%s", szRank))
    UIHelper.SetString(self.LabelRanking01, string.format("总评分：%s", tostring(nTotalScore)))

	local tbConfig = nil
	if nIndex ~= 0 then
		tbConfig = g_tTable.HomelandRewardLevel:Search(1)
	end
	if nInfo == 0 then
		tbConfig = g_tTable.HomelandRewardLevel:Search(0)
	end
	for k, v in pairs(HomelandPVPData.tRewardLevel) do
		if nInfo > v.nMinPercentage and nInfo <= v.nMaxPercentage then
			tbConfig = v
		end
	end

	UIHelper.RemoveAllChildren(self.ScrollViewWidgetItem_80)
	self.tbRewardCells = {}
	local nAwardIconIndex = 0
	if tbConfig then
		nAwardIconIndex = #HomeLandPvpAwardIcon - tbConfig.dwLevel
		UIHelper.SetString(self.LabelTag, string.format("%s  %s", UIHelper.GBKToUTF8(tbConfig.szName), UIHelper.GBKToUTF8(tbConfig.szIntroduction)))

		if tbConfig.szReward ~= "" then
			UIHelper.SetVisible(self.ScrollViewWidgetItem_80, true)

			local tReward = SplitString(tbConfig.szReward, ";")
			for k, String in pairs(tReward) do
				local t = SplitString(String, ":")
				local scriptItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.ScrollViewWidgetItem_80)
				UIHelper.SetAnchorPoint(scriptItemIcon._rootNode, 0, 0)
				scriptItemIcon:OnInitWithTabID(tonumber(t[1]), tonumber(t[2]))
				scriptItemIcon:SetLabelCount(tonumber(t[3]))
				scriptItemIcon:SetClickCallback(function ()
					TipsHelper.ShowItemTips(scriptItemIcon._rootNode, tonumber(t[1]), tonumber(t[2]), false)
				end)

				table.insert(self.tbRewardCells, scriptItemIcon)
				UIHelper.ToggleGroupAddToggle(self.TogGroupRewardItem, scriptItemIcon.ToggleSelect)
			end

			UIHelper.ScrollViewDoLayout(self.ScrollViewWidgetItem_80)
			UIHelper.ScrollToLeft(self.ScrollViewWidgetItem_80, 0)
		else
			UIHelper.SetVisible(self.ScrollViewWidgetItem_80, false)
		end
	end

	UIHelper.SetSpriteFrame(self.ImgTagIcon, HomeLandPvpAwardIcon[nAwardIconIndex])
	UIHelper.LayoutDoLayout(self.ImgRankingRewardBg)
	self:ClearSelect()
end

function UIHomelandPVPPage:UpdateSuit()
	local nCurrentSuit 	= HomelandPVPData.nCurrentSuit
	local tSuitInfo 	= HomelandPVPData.tSuit[nCurrentSuit]

	if not tSuitInfo then
		LOG.ERROR("UIHomelandPVPPage:UpdateSuit() Error!tSuitInfo is nil!")
		return
	end

    UIHelper.SetString(self.LabelTitle, UIHelper.GBKToUTF8(tSuitInfo.szTimeText))
    UIHelper.SetString(self.LabelTitleType, UIHelper.GBKToUTF8(tSuitInfo.szName))
    -- UIHelper.SetString(self.LabelTitleType, UIHelper.GBKToUTF8(tSuitInfo.szIntroduce))

	self.tbScriptItems = self.tbScriptItems or {}

	for _, scriptItem in pairs(self.tbScriptItems) do
		UIHelper.SetVisible(scriptItem._rootNode, false)
	end

	for k, dwRewardID in pairs(tSuitInfo.tRewardList) do
		local tRewardInfo = HomelandPVPData.tReward[dwRewardID]
		if tRewardInfo then
			local scriptItem = self.tbScriptItems[k]
			if not scriptItem then
				scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetHomeMatchItem, self.ScrollViewHomeMatchRight)
				self.tbScriptItems[k] = scriptItem
				UIHelper.ToggleGroupAddToggle(self.ToggleGroupItem, scriptItem.TogHomeMatch)
			end

			UIHelper.SetVisible(scriptItem._rootNode, true)
			scriptItem:OnEnter(tRewardInfo)
			scriptItem:SetSelectCallback(function()
				TipsHelper.ShowItemTips(scriptItem._rootNode, ITEM_TABLE_TYPE.HOMELAND, tRewardInfo.dwFurniturenIndex, false)
			end)
			self.tbScriptItems[k] = scriptItem
		end
	end

	UIHelper.ScrollViewDoLayout(self.ScrollViewHomeMatchRight)
	UIHelper.ScrollToTop(self.ScrollViewHomeMatchRight, 0)

	self:ClearSelect()
end

function UIHomelandPVPPage:UpdateWeekInfo()
	local pHomelandMgr = GetHomelandMgr()
	if not pHomelandMgr then
        return
    end
	local nTime 		= GetCurrentTime()
	local tNow 			= pHomelandMgr.GetNowActivate(nTime)
	UIHelper.SetString(self.LabelAttribute, self:GetAttributeDes(tNow))
	UIHelper.SetString(self.LabelType, self:GetClassifyDes(nTime))

	local tNowTime		= TimeToDate(nTime)
	local nNextWeekTime = DateToTime(tNowTime.year, tNowTime.month, tNowTime.day + 7, tNowTime.hour, tNowTime.minute, tNowTime.second)
	local tNext 		= pHomelandMgr.GetNowActivate(nNextWeekTime)

	if self.bShowNextWeekInfo then
		UIHelper.SetString(self.LabelAttribute, self:GetAttributeDes(tNext))
		UIHelper.SetString(self.LabelType, self:GetClassifyDes(nNextWeekTime))
		UIHelper.SetString(self.LabelAfficheSwitchover, "下期收场评鉴公告")

		UIHelper.SetVisible(self.BtnSwitchoverL, true)
		UIHelper.SetVisible(self.BtnSwitchoverR, false)
		UIHelper.SetVisible(self.ImgRankingBg, false)
	else
		UIHelper.SetString(self.LabelAfficheSwitchover, "本期收场评鉴公告")
		UIHelper.SetVisible(self.BtnSwitchoverR, true)
		UIHelper.SetVisible(self.BtnSwitchoverL, false)
		UIHelper.SetVisible(self.ImgRankingBg, true)
	end
end

function UIHomelandPVPPage:ToggleRankCheckBox()

end

function UIHomelandPVPPage:GetAttributeDes(t)
	local szText 	= ""
	for i = 1, 5 do
		local nMultiple = t["Attribute" .. i]
		if nMultiple > 1 then
			if szText ~= "" then
				szText = szText .. "、 "
			end
			szText = szText .. g_tStrings["STR_HOMELAND_FURNITURE_SORT_TYPE_ATTRIBUTE" .. i] .. FormatString(g_tStrings.STR_HOMELAND_PVP_MULTIPLE, nMultiple)
		end
	end
	return szText
end

function UIHomelandPVPPage:GetClassifyDes(nTime)
	local szText 	= ""
	for nCategory1 = 1, UI_MAX_FURNITURE_CATEGORY_LIMIT do
		for nCategory2 = 1, UI_MAX_FURNITURE_CATEGORY_LIMIT do
			local nResult = GetHomelandMgr().GetRankActivateLimit(nTime, nCategory1, nCategory2)
			if nResult > 0 then
				local szName = UIHelper.GBKToUTF8(HomelandPVPData.tFurnitureCatgList[nCategory1][nCategory2].szName) .. FormatString(g_tStrings.STR_HOMELAND_PVP_QUANTITY, nResult)
				if szText ~= "" then
					szText = szText .. "、 "
				end
				szText = szText .. szName
			end
		end
	end
	return szText
end

function UIHomelandPVPPage:ClearSelect()
	for i, cell in ipairs(self.tbRewardCells) do
		UIHelper.SetSelected(cell.ToggleSelect, false)
	end

	for i, cell in pairs(self.tbScriptItems) do
		UIHelper.SetSelected(cell.TogHomeMatch, false)
	end
end

function UIHomelandPVPPage:UpdateTitleFrameInfo()
	local bIndoor = true
    local tSuitInfo 	= HomelandPVPData.tSuit[HomelandPVPData.nCurrentSuit]
	local szPath, nFrame
	if bIndoor then
		szPath 			= tSuitInfo.szIndoorPath
		nFrame			= tSuitInfo.nIndoorFrame
	else
		szPath 			= tSuitInfo.szOutdoorPath
		nFrame			= tSuitInfo.nOutdoorFrame
	end

    if nFrame == -1 then
        szPath = string.gsub(szPath, "ui/Image", "mui/Resource")
        szPath = string.gsub(szPath, ".tga", ".png")
        szPath = string.gsub(szPath, ".Tga", ".png")
        UIHelper.SetTexture(self.ImgTitle, szPath)
    end
	UIHelper.UpdateMask(self.MaskTitle)
end

return UIHomelandPVPPage