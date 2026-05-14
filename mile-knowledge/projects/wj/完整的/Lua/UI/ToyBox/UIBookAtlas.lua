-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBookAtlas
-- Date: 2024-04-15 15:21:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBookAtlas = class("UIBookAtlas")

function UIBookAtlas:OnEnter(szPlotKey, nSeasonID, nChapterID)
	self.szPlotKey = szPlotKey
	if not nSeasonID then
		nSeasonID = 1
	end
	self.nSeasonID = nSeasonID
	if not nChapterID then
		nChapterID = 1
	end
	self.nChapterID = nChapterID
	self.tSection, self.tLayer = Table_GetAPSectionLayer(szPlotKey)
	--self.nCurChapter = 1
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end

	self:UpdateInfo(nSeasonID, nChapterID)
end

function UIBookAtlas:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIBookAtlas:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(VIEW_ID.PanelYushutuce)
    end)

	for i, tog in ipairs(self.tbLeftTogList) do
		UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function (_, bSelected)
			if bSelected then
				self.nSeasonID = i
				self:UpdateLeftTog()
			end
		end)
	end

end

function UIBookAtlas:RegEvent()
	--Event.Reg(self, EventType.XXX, func)
end

function UIBookAtlas:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIBookAtlas:UpdateInfo()
	self:UpdateLeftTog(self.nCurChapter)
	UIHelper.SetVisible(self.WidgetContentRight, false)
	UIHelper.SetVisible(self.ImgEmpty, true)
end

function UIBookAtlas:GetChapterInfo(nChapterID, szKey)
    local tLine, nIndex, nTotal = Table_GetAPSectionLayerInfo(self.szPlotKey, nChapterID, "Chapter")
    if szKey then
        return tLine[szKey] or ""
    else
        return tLine or {}, nIndex, nTotal
    end
end

function UIBookAtlas:IsChapterLock(nChapterID)
	local bLock = true
    local tSectionList = self:GetSectionList(nil, nChapterID)
    for _, tInfo in ipairs(tSectionList) do
        local _, bSectionLock = self:IsSectionFinished(tInfo)
        if not bSectionLock then
            bLock = false
            break
        end
    end

    if bLock then
        local tFirstSection = tSectionList[1]
        local dwQuestID = tFirstSection.dwBeginQuestID
        local pPlayer = GetClientPlayer()
        if pPlayer then
            if pPlayer.GetQuestPhase(dwQuestID) >= QUEST_PHASE.ACCEPT then
                bLock = false
            end
        end
    end
    return bLock
end

function UIBookAtlas:GetSectionList(nSeasonID, nChapterID)
	local tSectionList = {}
    if not nSeasonID and nChapterID then
        if not self.tSection then
            self.tSection, self.tLayer = Table_GetAPSectionLayer(self.szPlotKey)
        end
        for nSeason, tChapter in pairs(self.tSection) do
            if tChapter[nChapterID] then
                nSeasonID = nSeason
            end
        end
    end
    if nSeasonID and nChapterID then
        tSectionList = self.tSection[nSeasonID][nChapterID] or {}
    end
    return tSectionList, nSeasonID
end

function UIBookAtlas:IsSectionFinished(tInfo)
	local nState = 0
    local pPlayer = GetClientPlayer()
    if pPlayer and tInfo then
        local dwBeginQuestID = tInfo.dwBeginQuestID
        local dwEndQuestID = tInfo.dwEndQuestID
        if dwBeginQuestID == 0 or dwEndQuestID == 0 then
            nState = 2
        elseif pPlayer.GetQuestState(dwBeginQuestID) == QUEST_STATE.FINISHED then
            nState = 1
            if pPlayer.GetQuestState(dwEndQuestID) == QUEST_STATE.FINISHED then
                nState = 2
            end
        end
    end
    local bFinished = nState == 2
    local bLock = nState == 0
    return bFinished, bLock
end

function UIBookAtlas:UpdateLeftTog()
	UIHelper.RemoveAllChildren(self.LayoutChapter)
	local tChapter = self.tLayer[self.nSeasonID].tChapterID
	local nSeasonID = self.tLayer[self.nSeasonID].nSeasonID
	for i, nChapterID in pairs(tChapter) do
		local tChapterInfo = self:GetChapterInfo(nChapterID)
		local bChapterLock = self:IsChapterLock(nChapterID)
		local szTitle = tChapterInfo.szTitle
		if bChapterLock then
			szTitle = "????"
		end
		local tbChapterInfo = {nID = nChapterID, bLock = not (tChapterInfo.bHideLock or not bChapterLock), szTitle = szTitle}
		local tbChapterScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSwordMemoriesChapterTog, self.LayoutChapter, tbChapterInfo, self, false, true)
		UIHelper.SetSelected(tbChapterScript.TogChapter, tbChapterInfo.nID == self.nChapterID and not bChapterLock)
		UIHelper.SetEnable(tbChapterScript.TogChapter, not bChapterLock)
	end
end

function UIBookAtlas:SetCurChapter(tChapterInfo)
    self.nChapterID = tChapterInfo.nID
	UIHelper.SetVisible(self.WidgetContentRight, true)
    self:UpdateChapterInfo()
end

function UIBookAtlas:UpdateChapterInfo()
	local tSectionList, nSeasonID = self:GetSectionList(self.nSeasonID, self.nChapterID)
	local tChapterInfo = self:GetChapterInfo(self.nChapterID)
	UIHelper.SetSpriteFrame(self.ImgChapterBg, ACTIVITY_PLOT[tChapterInfo.nImageFrame + 1])
	UIHelper.UpdateMask(self.MaskBg)
	UIHelper.SetString(self.LabelChapterTitle, UIHelper.GBKToUTF8(tChapterInfo.szTitle))
	UIHelper.SetString(self.LabeTime, UIHelper.GBKToUTF8(tChapterInfo.szTime))
	UIHelper.SetVisible(self.imgDone, self:IsChapterFinished(self.nChapterID))
	UIHelper.SetVisible(self.ImgEmpty, false)

	for nIndex, tInfo in ipairs(tSectionList) do
		local bFinished, bLock = self:IsSectionFinished(tInfo)
		if not bLock then
			UIHelper.SetString(self.LabelContentTitle, UIHelper.GBKToUTF8(tInfo.szTitle))
			UIHelper.SetVisible(self.LabelContent, true)
			if bFinished then
				local szConcat = self:StringConcat("\n", tInfo.szPrimer, tInfo.szDetail)
				local szContent = self:GetPureString(szConcat)
				UIHelper.SetString(self.LabelContent, szContent)
            else
                UIHelper.SetString(self.LabelContent, UIHelper.GBKToUTF8(tInfo.szPrimer))
            end
			UIHelper.SetVisible(self.WidgetSwordMemoriesPartCell, true)
			Timer.AddFrame(self, 1,function ()
				UIHelper.LayoutDoLayout(self.WidgetSwordMemoriesPartCell)
				UIHelper.LayoutDoLayout(self.LayoutChapterContent)
				UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewChapterContent)
			end)


		else
			local szTitle = UIHelper.GBKToUTF8(tInfo.szTitle) .. g_tStrings.STR_SPLIT_DOT .. g_tStrings.STR_ARENA_LOCK
			UIHelper.SetString(self.LabelContentTitle, szTitle)
			UIHelper.SetVisible(self.LabelContent, false)
		end
	end
end

function UIBookAtlas:IsChapterFinished(nChapterID)
	local bFinished = true
    local tSectionList = self:GetSectionList(nil, nChapterID)
    for _, tInfo in ipairs(tSectionList) do
        if not self:IsSectionFinished(tInfo) then
            bFinished = false
            break
        end
    end
    return bFinished
end

function UIBookAtlas:GetPureString(szInfo)
    local szText = ""
    local _, aInfo = GWTextEncoder_Encode(szInfo)

	local function GetEncodeName(tInfo)
		local szName = ""
		local nID = tonumber(tInfo.context)
		if nID then
			szName = Table_GetNpcCallMe(nID)
		else
			szName = GetClientPlayer().szName
		end
		return szName
	end
    if aInfo then
        for k, v in pairs(aInfo) do
            if v.name == "text" then
                szText = szText .. UIHelper.GBKToUTF8(v.context)
            elseif v.name == "G" then -- 两个中文空格
                szText = szText .. g_tStrings.STR_TWO_CHINESE_SPACE
            elseif v.name == "N" then -- 自定义称呼
                local szName = GetEncodeName(v)
                szText = szText .. szName
            end
        end
    end
    return szText
end

function UIBookAtlas:StringConcat(szSep, ...)
	local argv = {...}
	local szResult = table.concat(argv, szSep)
	return szResult
end

return UIBookAtlas