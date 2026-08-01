-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAdventureView
-- Date: 2023-05-05 14:24:10
-- Desc: ?
-- ---------------------------------------------------------------------------------

local REMOTE_TRYBOOK = 1140

local ONE_PAGE_ADVENTURES = 7
local ONE_PAGE_TRYBOOK = 7

local TRADE_LINK_LIST = {2069, 2070, 2071, 2471}

local TYPE_TRIGGER		= 1
local TYPE_CATALOGUE	= 2
local TYPE_REWARD 		= 3


local function UpdateSortLevel(v)
	local nLevel = v.nChanceState
	if v.bHasTryMax then
		nLevel = ADVENTURE_CHANCE_STATE.MAX + 1
	elseif v.bTrigger then
		nLevel = ADVENTURE_CHANCE_STATE.MAX + 2
	end
	v.nSortLevel = nLevel
end

local function GetFilterClass()
	return Storage.Adventure.nFilterClass
end

local function SetFilterClass(nClass)
	Storage.Adventure.nFilterClass = nClass
end

local UIAdventureView = class("UIAdventureView")

function UIAdventureView:OnEnter(nOpenCurrID, dwTryAdvID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        UIMgr.Open(VIEW_ID.PanelUID)
        self.bInit = true
    end

	self.tCustomData = CustomData.GetData(CustomDataType.Role, "AdventureCustomData")
	if not self.tCustomData then
		self.tCustomData = {}
	end

	self:SetQiYuBtnState()

	AdventureData.InitLuckyTable(true)

    self.nOpenCurrID = nOpenCurrID
	self.dwTryAdvID = dwTryAdvID
    RemoteCallToServer("On_QiYu_GetCurrentAdvInfo")

	UIHelper.SetSwallowTouches(self.TogAll, true)
	UIHelper.SetSwallowTouches(self.TogJiYuanChengShu, true)
	UIHelper.SetSwallowTouches(self.TogJiYuanWeiDao, true)
	UIHelper.SetSwallowTouches(self.TogDengDaiTanSuo, true)
	UIHelper.SetTouchDownHideTips(self.TogAll, false)
    UIHelper.SetTouchDownHideTips(self.TogJiYuanChengShu, false)
    UIHelper.SetTouchDownHideTips(self.TogJiYuanWeiDao, false)
	UIHelper.SetTouchDownHideTips(self.TogDengDaiTanSuo, false)
	UIHelper.SetTouchDownHideTips(self.LayoutWaysList, false)
end

function UIAdventureView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
    UIMgr.Close(VIEW_ID.PanelUID)

	if self.tCustomData then
		CustomData.Register(CustomDataType.Role, "AdventureCustomData", self.tCustomData)
	end
end

function UIAdventureView:BindUIEvent()
    UIHelper.BindUIEvent(self.TogCatalog, EventType.OnClick, function ()
        self:UpdateGetAdventure()
    end)

    UIHelper.BindUIEvent(self.TogCatalog, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self:UpdateGetAdventure()
        end
    end)

    UIHelper.BindUIEvent(self.TogAward, EventType.OnClick, function ()
        self:UpdateNoneAdventure()
    end)

    UIHelper.BindUIEvent(self.TogAward, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self:UpdateNoneAdventure()
        end
    end)

	UIHelper.BindUIEvent(self.TogNotes, EventType.OnClick, function ()
		self:UpdateTryBook()
	end)

	UIHelper.BindUIEvent(self.TogNotes, EventType.OnSelectChanged, function (_, bSelected)
		if bSelected then
			self:UpdateTryBook()
		end
	end)

    UIHelper.BindUIEvent(self.TogZhenQi, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
           self:OnSelectedZhenQi()
        end
    end)

    UIHelper.BindUIEvent(self.TogQiYu, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self:OnSelectedQiYu()
        end
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnReturn, EventType.OnClick, function ()
        -- UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupL, self.TogCatalog)
        -- self:UpdateGetAdventure()
		UIHelper.SetVisible(self.WidgetBtn, true)
		UIHelper.SetVisible(self.BtnReturn, false)
		self:ClearBookPage()
		UIHelper.SetVisible(self.scriptCatalogueLeft._rootNode, true)
		UIHelper.SetVisible(self.scriptCatalogueRight._rootNode, true)
    end)

	UIHelper.BindUIEvent(self.TogAll, EventType.OnSelectChanged, function (_, bSelected)
		if bSelected then
			self:UpdateTryBookFilter(1)
		end
	end)

	UIHelper.BindUIEvent(self.TogJiYuanChengShu, EventType.OnSelectChanged, function(_, bSelected)
		if bSelected then
			self:UpdateTryBookFilter(2)
		end
	end)

	UIHelper.BindUIEvent(self.TogJiYuanWeiDao, EventType.OnSelectChanged, function (_, bSelected)
		if bSelected then
			self:UpdateTryBookFilter(3)
		end
	end)

	UIHelper.BindUIEvent(self.TogDengDaiTanSuo, EventType.OnSelectChanged, function (_, bSelected)
		if bSelected then
			self:UpdateTryBookFilter(4)
		end
	end)

    UIHelper.BindUIEvent(self.BtnTrade, EventType.OnClick, function ()
        local tbTargetList = {}
        for _, nLinkID in pairs(TRADE_LINK_LIST) do
            local tAllLinkInfo = Table_GetCareerGuideAllLink(nLinkID)
            for _, tInfo in pairs(tAllLinkInfo) do
                table.insert(tbTargetList, tInfo)
            end
        end
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetNPCGuideTips, self.BtnTrade, TipsLayoutDir.BOTTOM_CENTER, tbTargetList)
    end)

	-- UIHelper.BindUIEvent(self.TogSift, EventType.OnClick, function ()
	-- 	TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogSift, TipsLayoutDir.BOTTOM_CENTER, FilterDef.AdventureTryBook)
	-- end)

	if Platform.IsWindows() or Platform.IsMac() then
		UIHelper.RegisterEditBoxEnded(self.WidgetEdit, function()
			local szSearchText = UIHelper.GetString(self.WidgetEdit)
			self.szSearchText = szSearchText
			self.nTryBookPage = 1
			if self.nTryBookClass == 1 then
				self:UpdateZhenQiTryBook()
			else
				self:UpdateXiYouTryBook()
			end
		end)
	else
		UIHelper.RegisterEditBoxReturn(self.WidgetEdit, function()
			local szSearchText = UIHelper.GetString(self.WidgetEdit)
			self.szSearchText = szSearchText
			self.nTryBookPage = 1
			if self.nTryBookClass == 1 then
				self:UpdateZhenQiTryBook()
			else
				self:UpdateXiYouTryBook()
			end
		end)
	end

    UIHelper.RegisterEditBoxChanged(self.WidgetEdit, function()
        local szSearchText = UIHelper.GetString(self.WidgetEdit)
        self.szSearchText = szSearchText
		self.nTryBookPage = 1
		if self.nTryBookClass == 1 then
			self:UpdateZhenQiTryBook()
		else
			self:UpdateXiYouTryBook()
		end
    end)

	UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function ()
		if self.szSearchText == "" then
			return
		end
		self.szSearchText = ""
		UIHelper.SetString(self.WidgetEdit, "")
		self.nTryBookPage = 1
		if self.nTryBookClass == 1 then
			self:UpdateZhenQiTryBook()
		else
			self:UpdateXiYouTryBook()
		end
	end)

	UIHelper.BindUIEvent(self.BtnTrace, EventType.OnClick, function()
		if not self.tCurrentAdv or self.tCurrentAdv.nAdID == 0 then
			return
		end
		self.nOpenCurrID = self.tCurrentAdv.nAcceptID
		if self.scriptCatalogueLeft then
			self.scriptCatalogueLeft:SetOpenCurrID(self.nOpenCurrID)
		end
		if self.scriptCatalogueRight then
			self.scriptCatalogueRight:SetOpenCurrID(self.nOpenCurrID)
		end
		local tAdv = Table_GetAdventureByID(self.tCurrentAdv.nAdID)
		self.nCurrClassify = tAdv.nClassify
		UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupL, self.TogCatalog)
		self:UpdateGetAdventure()
	end)

	UIHelper.BindUIEvent(self.BtnSpecialItemUse, EventType.OnClick, function()
		UIMgr.Open(VIEW_ID.PanelQiYuTreasureBox, nil)
	end)
end

function UIAdventureView:RegEvent()
    Event.Reg(self, EventType.OnGetCurrentAdventureInfo, function (tAdvInfo)
        LOG.TABLE(tAdvInfo)
        self.tCurrentAdv = tAdvInfo or {}
		if not self.dwTryAdvID and not self.nOpenCurrID then
			if self.tCurrentAdv.nAdID and self.tCurrentAdv.nAdID ~= 0 then
				self.nOpenCurrID = self.tCurrentAdv.nAcceptID
			end
		end
        self:UpdateInfo()
    end)

	Event.Reg(self, EventType.OnGetAdventurePetTryBook, function (tPetTryMap)
		local tAdv = self.tZhenqiTry
		for _, v in ipairs(tAdv) do
			if tPetTryMap[v.dwID] then
				local tTryBook = v.tTryBook
				local tShowTry = tTryBook[1]
				tShowTry.nHasTry = tPetTryMap[v.dwID]
				if tShowTry.nTryMax <= tShowTry.nHasTry then
					v.nHasFTry = 1
				end
				if v.nHasFTry == #v.tTryBook then
					v.bHasTryMax = true
				end
				v.tTryBook[1] = tShowTry
				UpdateSortLevel(v)
			end
		end

		if self.nCheckType == TYPE_TRIGGER and self.nTryBookClass == 1 then
			self:UpdateZhenQiTryBook()
		end
	end)

	Event.Reg(self, EventType.HideAllHoverTips, function ()
        UIHelper.SetSelected(self.TogSift, false)
    end)

	-- Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
    --     if szKey == FilterDef.AdventureTryBook.Key then
	-- 		self:UpdateTryBookFilter(tbSelected)
    --     end
    -- end)
	Event.Reg(self, EventType.OnSelectLeaveForBtn, function(tbInfo)
		local tbPoint = tbInfo.tPoint or { tbInfo.fX, tbInfo.fY, tbInfo.fZ }
		MapMgr.SetTracePoint(UIHelper.GBKToUTF8(tbInfo.szNpcName), tbInfo.dwMapID, tbPoint)
		UIMgr.Open(VIEW_ID.PanelMiddleMap, tbInfo.dwMapID, 0)
		Event.Dispatch(EventType.HideAllHoverTips)
	end)
end

function UIAdventureView:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIAdventureView:UpdateInfo()
    self.tAdventureList = Table_GetAdventure()
    self.tAdventureKinds = self:GetShowReward(self.tAdventureList)
    self.tTaskInfo = Table_GetAdventureTask()
    self.tAdventure, self.tFinishAdventure, self.tTriggerAdv = self:GetShowAdv(self.tAdventureList)
    self.tAdvClassify = self:GetClassifyAdv(self.tAdventure)
	self.tZhenqiTry, self.tXiyouTry = self:GetAllAdvTryBook()

    self.scriptAwardLeft = self.scriptAwardLeft or UIHelper.AddPrefab(PREFAB_ID.WidgetAwardCell, self.WidgetPage_L, function ()
        self.nPrePage = self.nPrePage - 2
        self.nNextPage = self.nPrePage + 1
        self:UpdateNoneAdvPageL(self.nPrePage)
        self:UpdateNoneAdvPageR(self.nNextPage)
    end)

    self.scriptAwardRight = self.scriptAwardRight or UIHelper.AddPrefab(PREFAB_ID.WidgetAwardCell, self.WidgetPage_R, function ()
        self.nNextPage = self.nNextPage + 2
        self.nPrePage = self.nNextPage - 1
        self:UpdateNoneAdvPageL(self.nPrePage)
        self:UpdateNoneAdvPageR(self.nNextPage)
    end)

    self.scriptFirstPage = self.scriptFirstPage or UIHelper.AddPrefab(PREFAB_ID.WidgetPartTypeCell, self.WidgetPage_L)
    UIHelper.SetVisible(self.scriptFirstPage.ImgTittle, false)
	self.scriptLastPage = self.scriptLastPage or UIHelper.AddPrefab(PREFAB_ID.WidgetPartTypeCell, self.WidgetPage_R)
	UIHelper.SetTexture(self.scriptLastPage.ImgPart, "Resource/Adventure/Adventure/catalogue/over.png")
	UIHelper.SetVisible(self.scriptLastPage.ImgTittle, false)

    -- self.scriptPoem = self.scriptPoem or UIHelper.AddPrefab(PREFAB_ID.WidgetPartTypeCell, self.WidgetPage_L)

    self.scriptCatalogueLeft = self.scriptCatalogueLeft or UIHelper.AddPrefab(PREFAB_ID.WidgetCatalogue, self.WidgetPage_L, self.tAdventureList, self.tFinishAdventure, self.nOpenCurrID, self.tCurrentAdv, function (dwAdvID)
        self:UpdateAdvTask(dwAdvID)
    end, 0, nil)

	self.scriptCatalogueRight = self.scriptCatalogueRight or UIHelper.AddPrefab(PREFAB_ID.WidgetCatalogue, self.WidgetPage_R, self.tAdventureList, self.tFinishAdventure, self.nOpenCurrID, self.tCurrentAdv, function (dwAdvID)
		self:UpdateAdvTask(dwAdvID)
	end, 1, function (nPage)
		if nPage then
			self.scriptCatalogueLeft:UpdateInfo(nPage)
			self.scriptCatalogueRight:UpdateInfo(nPage)
		end
	end)


    self.scriptAdvLeft = self.scriptAdvLeft or UIHelper.AddPrefab(PREFAB_ID.WidgetContentCell_L, self.WidgetPage_L, function ()
        self.nPreTaskPage = self.nPreTaskPage - 2
        self.nNextTaskPage = self.nPreTaskPage + 1
        self:UpdateAdvPageL(self.nPreTaskPage)
        self:UpdateAdvPageR(self.nNextTaskPage)
    end)

    self.scriptAdvRight = self.scriptAdvRight or UIHelper.AddPrefab(PREFAB_ID.WidgetContentCell_R, self.WidgetPage_R, function ()
        self.nNextTaskPage = self.nNextTaskPage + 2
        self.nPreTaskPage = self.nNextTaskPage - 1
        self:UpdateAdvPageL(self.nPreTaskPage)
        self:UpdateAdvPageR(self.nNextTaskPage)
    end)

	self.scriptTryBookRight = self.scriptTryBookRight or UIHelper.AddPrefab(PREFAB_ID.WidgetNote_R, self.WidgetPage_R)
	self.scriptTryBookLeft = self.scriptTryBookLeft or UIHelper.AddPrefab(PREFAB_ID.WidgetNotes, self.WidgetPage_L)

    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupL)
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupR)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupL, self.TogCatalog)
    -- UIHelper.ToggleGroupAddToggle(self.ToggleGroupL, self.TogAward)
	UIHelper.ToggleGroupAddToggle(self.ToggleGroupL, self.TogNotes)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupR, self.TogZhenQi)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupR, self.TogQiYu)
    -- UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupL, self.TogAward)

	UIHelper.SetCanSelect(self.TogNotes, not CrossMgr.IsCrossing(), g_tStrings.STR_REMOTE_NOT_TIP)

	local bReDirect = false
	if self.dwTryAdvID then
		local tInfo = g_tTable.Adventure:Search(self.dwTryAdvID)
		if tInfo then
			SetFilterClass(1)
			self.nTryBookClass = tInfo.nClassify
			self.szSearchText = UIHelper.GBKToUTF8(tInfo.szName)
			UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupL, self.TogNotes)
			self:UpdateTryBook(false)
			bReDirect = true
		end
	end
	if not bReDirect then
		if not self.tCurrentAdv.nAdID or self.tCurrentAdv.nAdID == 0 then
			UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupL, self.TogNotes)
			self:UpdateTryBook()
		else
			UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupL, self.TogCatalog)
			self:UpdateGetAdventure()
		end
	end

	UIHelper.SetVisible(self.TogCatalog, #self.tAdventure ~= 0)
	UIHelper.SetVisible(self.TogAward, false)
	UIHelper.SetVisible(self.TogNotes, #self.tAdventure ~= 0)
	-- if not UIHelper.GetVisible(self.TogCatalog) then
	-- 	UIHelper.SetPositionX(self.TogNotes, UIHelper.GetPositionX(self.TogCatalog))
	-- end
	UIHelper.LayoutDoLayout(self.LayoutTabL)

	Timer.AddFrame(self, 1, function()
		local szTitle = AdventureData.tTraceData and AdventureData.tTraceData.szTitle or ""
		local szText = AdventureData.tTraceData and AdventureData.tTraceData.szText or ""
		UIHelper.SetVisible(self.WidgetQiYuDoing, szTitle ~= "")

		if szTitle ~= "" then
			UIHelper.SetString(self.LabelTItle, szTitle)
			local t = SplitString(szText, g_tStrings.STR_CHINESE_MAOHAO)
			local szTask = t[1] or ""
			local szState = t[2] or ""
			UIHelper.SetVisible(self.LabelQiYuTask, szTask ~= "")
			if szTask ~= "" then
				UIHelper.SetString(self.LabelQiYuTask, szTask)
			end
			UIHelper.SetVisible(self.LabelContent, szState ~= "")
			if szState ~= "" then
				UIHelper.SetString(self.LabelContent , szState)
			end
			UIHelper.LayoutDoLayout(self.LayoutContent)
		end
	end)
end

function UIAdventureView:ClearBookPage()
	UIHelper.SetVisible(self.scriptAdvLeft._rootNode, false)
    UIHelper.SetVisible(self.scriptAdvRight._rootNode, false)
    UIHelper.SetVisible(self.scriptAwardLeft._rootNode, false)
    UIHelper.SetVisible(self.scriptAwardRight._rootNode, false)
    UIHelper.SetVisible(self.scriptCatalogueLeft._rootNode, false)
	UIHelper.SetVisible(self.scriptCatalogueRight._rootNode, false)
    UIHelper.SetVisible(self.scriptFirstPage._rootNode, false)
	UIHelper.SetVisible(self.scriptLastPage._rootNode, false)
    -- UIHelper.SetVisible(self.scriptPoem._rootNode, false)
	UIHelper.SetVisible(self.scriptTryBookLeft._rootNode, false)
	UIHelper.SetVisible(self.scriptTryBookRight._rootNode, false)
end

function UIAdventureView:GetShowReward(tAdvList)
	local tAdv = {}
	for k, v in pairs(tAdvList) do
		if v.bHide == 0 then
			table.insert(tAdv, v)
		end
	end

	return tAdv
end

function UIAdventureView:GetShowAdv(tAdv)
	self.nCurrClassify = 1
	self.nTryBookClass = 1
	local player = GetClientPlayer()
	local tList = {}
	local tFinishList = {}
    local tTriggerList = {}
	for k, v in pairs(tAdv) do
		if self.tCurrentAdv.nAdID == v.dwID and self.tCurrentAdv.nAdID ~= 0 then
			table.insert(tList, v.dwID)
			if v.nClassify == 2 then
				self.nCurrClassify = v.nClassify
			end
		elseif v.dwFinishID ~= 0 then
			local bFinFlag = player.GetAdventureFlag(v.dwFinishID)
			if bFinFlag then
				table.insert(tList,	v.dwID)
				tFinishList[v.dwID] = true
			end
		elseif v.nFinishQuestID ~= 0 then
			local nAccQuest = player.GetQuestPhase(v.nFinishQuestID)
			if nAccQuest == 3 then
				table.insert(tList,	v.dwID)
				tFinishList[v.dwID] = true
			end
		end

        if v.dwStartID ~= 0 then
            local bTriFlag = player.GetAdventureFlag(v.dwStartID)
            if bTriFlag then
                tTriggerList[v.dwID] = true
            end
        elseif v.nStartQuestID ~= 0 then
            local nAccQuest = player.GetQuestPhase(v.nStartQuestID)
            if nAccQuest > 0 then
                tTriggerList[v.dwID] = true
            end
        end
	end

	return tList, tFinishList, tTriggerList
end

function UIAdventureView:GetClassifyAdv(tAdv)
	local tList = {}
	for k, v in pairs(tAdv) do
		local tLine = self:GetOneKindAdvLine(v) or {}
		if not tList[tLine.nClassify] then
			tList[tLine.nClassify] = {}
			table.insert(tList[tLine.nClassify], tLine.dwID)
		else
			table.insert(tList[tLine.nClassify], tLine.dwID)
		end
	end

	return tList
end

function UIAdventureView:GetOneKindAdvLine(nID)
	for k, v in pairs(self.tAdventureList) do
		if v.dwID == nID then
			return v
		end
	end

	return nil
end

function UIAdventureView:UpdateGetAdventure()
	self.nCheckType = TYPE_CATALOGUE
    self.bAdv = true

	UIHelper.SetVisible(self.WidgetBtn, true)
    -- UIHelper.SetVisible(self.TogQiYu, true)
    -- UIHelper.SetVisible(self.TogZhenQi, true)
    UIHelper.SetVisible(self.BtnReturn, false)
	UIHelper.SetVisible(self.WidgetNotes, false)
	self:ClearBookPage()

    if self.nCurrClassify == 1 and (not self.tAdvClassify[self.nCurrClassify] or table_is_empty(self.tAdvClassify[self.nCurrClassify])) then
        self.nCurrClassify = 2
    end

    if self.nCurrClassify == 1 then
        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupR, self.TogZhenQi)
        self:OnSelectedZhenQi()
    elseif self.nCurrClassify == 2 then
        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupR, self.TogQiYu)
        self:OnSelectedQiYu()
    end
end

function UIAdventureView:OnSelectedZhenQi()
	if self.nCheckType == TYPE_CATALOGUE then
		self.nCurrClassify = 1
    	self:AppendAdventure()
	else
		self.nTryBookClass = 1
		self.nTryBookPage = 1
		self:UpdateZhenQiTryBook()
	end
end

function UIAdventureView:OnSelectedQiYu()
	if self.nCheckType == TYPE_CATALOGUE then
		self.nCurrClassify = 2
    	self:AppendAdventure()
	else
		self.nTryBookClass = 2
		self.nTryBookPage = 1
		self:UpdateXiYouTryBook()
	end
end

function UIAdventureView:AppendAdventure()
	self:ClearBookPage()
	-- UIHelper.SetVisible(self.scriptPoem._rootNode, true)
	UIHelper.SetVisible(self.scriptCatalogueLeft._rootNode, true)
	UIHelper.SetVisible(self.scriptCatalogueRight._rootNode, true)

    local tAdvList = self.tAdvClassify[self.nCurrClassify] or {}
    self.scriptCatalogueLeft:UpdateAllList(tAdvList, 1)
	self.scriptCatalogueRight:UpdateAllList(tAdvList, 1)
end

function UIAdventureView:UpdateAdvTask(dwAdvID)
	UIHelper.SetVisible(self.WidgetBtn, false)
	-- UIHelper.SetVisible(self.TogQiYu, false)
    -- UIHelper.SetVisible(self.TogZhenQi, false)
    UIHelper.SetVisible(self.BtnReturn, true)
	self:ClearBookPage()
    UIHelper.SetVisible(self.scriptAdvLeft._rootNode, true)
    UIHelper.SetVisible(self.scriptAdvRight._rootNode, true)
	UIHelper.SetVisible(self.scriptFirstPage._rootNode, true)

    self.dwAdvID = dwAdvID
    self.tOneKndsAdv = Table_GetOneKindAdventure(dwAdvID)
    self.tTaskClassify, self.tAccToLine, self.tTaskState = self:GetTaskToState(self.tOneKndsAdv)
    self.nShowCount = self:GetAllShowCount()

    if self.dwAdvID == self.tCurrentAdv.nAdID then
        local nPage = self:GetCurrentTaskPage(self.tCurrentAdv.nAcceptID)
        if nPage % 2 == 0 then
            self.nPreTaskPage = nPage
            self.nNextTaskPage = nPage + 1
        else
            self.nPreTaskPage = nPage - 1
            self.nNextTaskPage = nPage
        end
    else
        self.nPreTaskPage = 0
        self.nNextTaskPage = 1
    end

    local tOneKind = self:GetOneKindAdvLine(dwAdvID)
    local szBgPath = tOneKind.szFirstPagePath
    if szBgPath then
        szBgPath = string.gsub(szBgPath, "ui\\Image", "Resource/Adventure")
        szBgPath = string.gsub(szBgPath, "ui/Image", "Resource/Adventure")
        szBgPath = string.gsub(szBgPath, ".tga", ".png")
        UIHelper.SetTexture(self.scriptFirstPage.ImgPart, szBgPath)
    end
    self:UpdateAdvPageL(self.nPreTaskPage)
    self:UpdateAdvPageR(self.nNextTaskPage)
end

function UIAdventureView:UpdateAdvPageL(nPage)
    if nPage == 0 then
        UIHelper.SetVisible(self.scriptFirstPage._rootNode, true)
        UIHelper.SetVisible(self.scriptAdvLeft._rootNode, false)
        return
    end
	UIHelper.SetVisible(self.scriptAdvLeft.BtnMoHe, nPage == self.nShowCount)
    UIHelper.SetVisible(self.scriptFirstPage._rootNode, false)
    UIHelper.SetVisible(self.scriptAdvLeft._rootNode, true)
    local tStates = self:GetTaskKindInfo(nPage)
    self:UpdateTaskInfo(tStates, self.scriptAdvLeft)
	self:UpdateIsShowEnd(tStates)
end

function UIAdventureView:UpdateIsShowEnd(tStates)
	local nAdvID = nil
	for _, v in pairs(tStates) do
		local tLine = self.tAccToLine[v]
		nAdvID = tLine.dwAdventureID
		break
	end

	local player = GetClientPlayer()
	local bFins = nil
	for _, v in pairs(self.tAdventureList) do
		if v.dwID == nAdvID then
			if v.nFinishQuestID ~= 0 then
				local nAccQuest = player.GetQuestPhase(v.nFinishQuestID)
				if nAccQuest == 3 then
					bFins = true
				end
			elseif v.dwFinishID ~= 0 then
				bFins = self.tTaskState[v.dwFinishID]
			end
			break
		end
	end

	if bFins then
		self.bShowEnd = true
	end
end

function UIAdventureView:UpdateAdvPageR(nPage)
    if nPage > self.nShowCount then
		if self.bShowEnd then
        	UIHelper.SetVisible(self.scriptAdvRight._rootNode, false)
			UIHelper.SetVisible(self.scriptLastPage._rootNode, true)
			self.bShowEnd = nil
		else
			UIHelper.SetVisible(self.scriptAdvRight._rootNode, false)
			UIHelper.SetVisible(self.scriptLastPage._rootNode, false)
		end
        return
    end
	UIHelper.SetVisible(self.scriptLastPage._rootNode, false)
    UIHelper.SetVisible(self.scriptAdvRight._rootNode, true)
    UIHelper.SetVisible(self.scriptAdvRight.BtnPage, nPage < self.nShowCount)
    local tStates = self:GetTaskKindInfo(nPage)
    self:UpdateTaskInfo(tStates, self.scriptAdvRight)
end

function UIAdventureView:UpdateTaskInfo(tStates, script)
    local szContent = ""
	local szDescribe = ""
	local szFinishDescribe = ""
	local tLine = {}
	local player = GetClientPlayer()
	for k, v in pairs(tStates) do
		tLine = self.tAccToLine[v]
		local bAcc = false
		local bFins = false
		if tLine.nQuestID ~= 0 then
			local nAccQuest = player.CanAcceptQuest(tLine.nQuestID)
			local nFinQuest = player.CanFinishQuest(tLine.nQuestID)
			if nAccQuest == QUEST_RESULT.ALREADY_FINISHED then
				bFins = true
			end

			if nAccQuest == QUEST_RESULT.ALREADY_ACCEPTED then
				bAcc = true
			end
		else
			bAcc 	= self.tTaskState[tLine.dwAcceptID]
			bFins 	= self.tTaskState[tLine.dwFinishID]
		end

        szDescribe = ""
		szFinishDescribe = ""
		if tLine.szDescribe ~= "" then
			szDescribe = UIHelper.GBKToUTF8(SimpleDecode(tLine.szDescribe, true))
            szDescribe = self:TripSlashes(szDescribe)
		end

		if tLine.szFinishDescribe ~= "" then
			szFinishDescribe = UIHelper.GBKToUTF8(SimpleDecode(tLine.szFinishDescribe, true))
            szFinishDescribe = self:TripSlashes(szFinishDescribe)
		end

        if bFins then
			if szContent ~= "" then
				if szDescribe ~= "" and szFinishDescribe ~= "" then
					szContent = szContent .. GetFormatText("\n") .. szDescribe .. GetFormatText("\n") .. szFinishDescribe
				elseif szDescribe ~= "" then
					szContent = szContent .. GetFormatText("\n") .. szDescribe
				elseif szFinishDescribe ~= "" then
					szContent = szContent .. GetFormatText("\n") .. szFinishDescribe
				end
			else
				if szDescribe ~= "" and szFinishDescribe ~= "" then
					szContent = szContent .. szDescribe .. GetFormatText("\n") .. szFinishDescribe
				elseif szDescribe ~= "" then
					szContent = szContent .. szDescribe
				elseif szFinishDescribe ~= "" then
					szContent = szContent .. szFinishDescribe
				end
			end
		elseif bAcc then
			if szContent ~= "" then
				szContent = szContent .. GetFormatText("\n") .. szDescribe
			else
				szContent = szContent .. szDescribe
			end
		end
	end

    local szTitle = ""
	if tLine.szTitle ~= "" then
		szTitle = UIHelper.GBKToUTF8(SimpleDecode(tLine.szTitle, true))
	end

    UIHelper.SetVisible(script.LabelContent, szContent ~= "")
    script:SetContentText(szContent)
    UIHelper.SetVisible(script.LabelPartTitle, szTitle ~= "")
    UIHelper.SetString(script.LabelPartTitle, szTitle)
    local szBgPath = tLine.szFramePath
    UIHelper.SetVisible(script.ImgAward, szBgPath and szBgPath ~= "")
    if szBgPath and szBgPath ~= "" then
        szBgPath = string.gsub(szBgPath, "ui\\Image", "Resource/Adventure")
        szBgPath = string.gsub(szBgPath, "ui/Image", "Resource/Adventure")
        szBgPath = string.gsub(szBgPath, ".tga", ".png")
        UIHelper.SetTexture(script.ImgAward, szBgPath, false)
    end
	script:SetClickMoHeCallback(function()
		if self.dwAdvID then
			UIHelper.OpenWeb("https://www.jx3box.com/adventure/" .. self.dwAdvID)
		end
	end)
end

function UIAdventureView:GetAllShowCount()
	local nCount = 0
	for k, v in pairs(self.tTaskClassify) do
		nCount = nCount + 1
	end

	return nCount
end

function UIAdventureView:GetTaskToState(tOneAdvList)
	local player = GetClientPlayer()
	local tAcc = {}
	local tAccFihState = {}
	for k, v in pairs(tOneAdvList) do
		if v.dwAcceptID ~= 0 and v.dwFinishID ~= 0 then
			local bAccFlag = player.GetAdventureFlag(v.dwAcceptID)
			local bFinFlag = player.GetAdventureFlag(v.dwFinishID)
			if bAccFlag then
				table.insert(tAcc, v)
			end

			tAccFihState[v.dwAcceptID] = bAccFlag
			tAccFihState[v.dwFinishID] = bFinFlag
		elseif v.nQuestID ~= 0 then
			local nAccQuest = player.CanAcceptQuest(v.nQuestID)
			local nFinQuest = player.CanFinishQuest(v.nQuestID)
			if (nAccQuest == QUEST_RESULT.ALREADY_ACCEPTED and nFinQuest ~= QUEST_RESULT.SUCCESS) 		--已接（未完成)
				or (nAccQuest == QUEST_RESULT.ALREADY_ACCEPTED and nFinQuest == QUEST_RESULT.SUCCESS) 	--已接（完成）
				or nAccQuest == QUEST_RESULT.ALREADY_FINISHED then 										--已交
				table.insert(tAcc, v)
			end
		end
	end

	local tPageToAcc = {}
	local tAccToLine = {}
	for k, v in pairs(tAcc) do
		local dwTaskID = 0
		if v.nQuestID ~= 0 then
			dwTaskID = v.nQuestID
		else
			dwTaskID = v.dwAcceptID
		end

		tAccToLine[dwTaskID] = v
		if tPageToAcc[v.dwPage] then
			table.insert(tPageToAcc[v.dwPage], dwTaskID)
		else
			tPageToAcc[v.dwPage] = {}
			table.insert(tPageToAcc[v.dwPage], dwTaskID)
		end
	end

	return tPageToAcc, tAccToLine, tAccFihState
end

function UIAdventureView:GetCurrentTaskPage(nAcceptID)
	local tList = {}
	local nCurPage = 0
	local nCount = 0
	for k, v in pairs(self.tTaskClassify) do
		nCount = nCount + 1
		for n, m in pairs(v) do
			if m == nAcceptID then
				nCurPage = nCount
				break
			end
		end
	end

	return nCurPage
end

function UIAdventureView:GetTaskKindInfo(nPage)
	local tStates = {}
	local nCount = 0
	for k, v in pairs(self.tTaskClassify) do
		nCount = nCount + 1
		if nPage == nCount then
			tStates = v
			break
		end
	end

	return tStates
end

function UIAdventureView:UpdateNoneAdventure()
	self.nCheckType = TYPE_REWARD
    self.bAdv = false

	UIHelper.SetVisible(self.WidgetBtn, false)
    -- UIHelper.SetVisible(self.TogQiYu, false)
    -- UIHelper.SetVisible(self.TogZhenQi, false)
    UIHelper.SetVisible(self.BtnReturn, false)
	UIHelper.SetVisible(self.WidgetNotes, false)
	self:ClearBookPage()
    UIHelper.SetVisible(self.scriptAwardLeft._rootNode, true)
    UIHelper.SetVisible(self.scriptAwardRight._rootNode, true)

    self.nPrePage = 1
    self.nNextPage = 2
    self:UpdateNoneAdvPageL(self.nPrePage)
	self:UpdateNoneAdvPageR(self.nNextPage)
end

function UIAdventureView:UpdateNoneAdvPageL(nPageL)
    UIHelper.SetVisible(self.scriptAwardLeft._rootNode, true)
    UIHelper.SetVisible(self.scriptAwardLeft.BtnLeft, nPageL > 1)
    UIHelper.SetVisible(self.scriptAwardLeft.BtnRight, false)
    self:UpdateNoneAdvInfo(nPageL, self.scriptAwardLeft.LabelTitle, self.scriptAwardLeft.ImgAward)
end

function UIAdventureView:UpdateNoneAdvPageR(nPageR)
    local nCount = #self.tAdventureKinds or 0
    if nPageR > nCount then
        UIHelper.SetVisible(self.scriptAwardRight._rootNode, false)
        return
    end
    UIHelper.SetVisible(self.scriptAwardRight._rootNode, true)
    UIHelper.SetVisible(self.scriptAwardRight.BtnLeft, false)
    UIHelper.SetVisible(self.scriptAwardRight.BtnRight, nPageR < nCount)
    self:UpdateNoneAdvInfo(nPageR, self.scriptAwardRight.LabelTitle, self.scriptAwardRight.ImgAward)
end

function UIAdventureView:UpdateNoneAdvInfo(nPage, label, image)
    for k, v in pairs(self.tAdventureKinds) do
        if k == nPage then
            UIHelper.SetString(label, UIHelper.GBKToUTF8(v.szName))
            if v.szRewardType == "" then
                local szBgPath = v.szRewardPath
                szBgPath = string.gsub(szBgPath, "ui\\Image", "Resource/Adventure")
                szBgPath = string.gsub(szBgPath, "ui/Image", "Resource/Adventure")
                szBgPath = string.gsub(szBgPath, ".tga", ".png")
                UIHelper.SetTexture(image, szBgPath, false)
            else
                local nSchool = g_pClientPlayer.dwForceID
	            local nCamp = g_pClientPlayer.nCamp
                local szBgPath = v.szRewardPath
                local bHasSlash = string.sub(szBgPath, -1) == "/" or string.sub(szBgPath, -1) == "\\"
                if not bHasSlash then
                    szBgPath = szBgPath .. "/"
                end
                if v.szRewardType == "school" then
                    szBgPath = szBgPath .. v.szRewardType .. "_" .. nSchool .. ".png"
                elseif v.szRewardType == "camp" then
                    szBgPath = szBgPath .. v.szRewardType .. "_" .. nCamp .. ".png"
                end
                szBgPath = string.gsub(szBgPath, "ui\\Image", "Resource/Adventure")
                szBgPath = string.gsub(szBgPath, "ui/Image", "Resource/Adventure")
                UIHelper.SetTexture(image, szBgPath, false)
            end
        end
    end
end

function UIAdventureView:GetOneAdvTryBook(player, dwID, bPet)
    local tTryBook = Table_GetAdventureTryBook(dwID)
	local nHasFTry = 0
	local bHaveData = true
	if (not player) or (not player.HaveRemoteData(REMOTE_TRYBOOK)) then
		bHaveData = false
	end

	local bTryLess = false
	for _, v in ipairs(tTryBook) do
		local nTryTimes = 0
		if bHaveData and not bPet then
			nTryTimes = player.GetRemoteArrayUInt(REMOTE_TRYBOOK, v.nOffset, v.nLength)
		end
		v.nHasTry = nTryTimes

		if v.nTryMax == -1 then
			bTryLess = true
		elseif v.nTryMax <= nTryTimes then
			nHasFTry = nHasFTry + 1
		end
	end
	return tTryBook, nHasFTry, bTryLess
end

function UIAdventureView:GetChanceTab(dwID, eType)
	local nChanceState, tChance = GDAPI_IfAdvenCanTry(dwID, eType)
	if nChanceState == ADVENTURE_CHANCE_STATE.NO_CHANCE then
		return false, nChanceState, tChance
	else
		return nChanceState == ADVENTURE_CHANCE_STATE.OK, nChanceState
	end
end

function UIAdventureView:GetAllAdvTryBook()
    local tZhenqi = {}
	local tXiyou = {}
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return {}, {}
	end
    local nCamp = hPlayer.nCamp
	local tPetTryList = {}
	for _, v in ipairs(self.tAdventureList) do
		v.bCanSee = false
		if kmath.bit_and(2^nCamp, v.nCampCanSee) ~= 0 then
			v.bCanSee = true
		end

		local eType = 0
		if v.nClassify == 2 then
			if v.bPerfect then
				eType = 2
			else
				eType = 1
			end
		end
		local bHasChance, nChanceState, tHasChance = self:GetChanceTab(v.dwID, eType)
		v.bHasChance = bHasChance or false
		v.tHasChance = tHasChance or {}
		v.bNoChance = not bHasChance
		v.nChanceState = nChanceState

		v.bTrigger = false
		if self.tTriggerAdv[v.dwID] or (v.nRelation ~= 0 and self.tTriggerAdv[v.nRelation]) then
			v.bTrigger = true
			v.bHasChance = true
			v.bNoChance = false
			v.nChanceState = ADVENTURE_CHANCE_STATE.OK
		end
		local tBuffList = v.tBuffList or {}
		local bUpBuff = false
		for _, tBuff in ipairs(tBuffList) do
			local bHave = Buff_Have(hPlayer, tBuff[1], tBuff[2])
			if bHave then
				bUpBuff = true
				break
			end
		end
		v.bUpBuff = bUpBuff

		if v.nClassify == 1 then
			local tTryBook, nHasFTry, bTryLess = self:GetOneAdvTryBook(hPlayer, v.dwID, true)
			if tTryBook and #tTryBook ~= 0 and v.bCanSee then
				table.insert(tPetTryList, v.dwID)
				v.tTryBook = tTryBook
				v.nHasFTry = nHasFTry
				v.bTryLess = bTryLess
				v.bHasTryMax = false
				if v.nHasFTry == #v.tTryBook and (not bTryLess) then
					v.bHasTryMax = true
				end

				local tShowTry = tTryBook[1] --珍奇只有一条
				local tPet = Table_GetFellowPet(tShowTry.dwPetID)
				v.szPetName = tPet.szName
				v.nMapID = tPet.nMapID
				v.tPet = tPet
				if AdventureData.IsLuckyPet(tShowTry.dwPetID) then
					v.bUpBuff = true
				end
				table.insert(tZhenqi, v)
			end
		else
			local tTryBook, nHasFTry, bTryLess = self:GetOneAdvTryBook(hPlayer, v.dwID, false)
			if tTryBook and #tTryBook ~= 0 and v.bCanSee then
				v.tTryBook = tTryBook
				v.nHasFTry = nHasFTry
				v.bTryLess = bTryLess
				v.bHasTryMax = false
				if v.nHasFTry == #v.tTryBook and (not bTryLess) then
					v.bHasTryMax = true
				end
				table.insert(tXiyou, v)
			end
		end
		UpdateSortLevel(v)
	end

	RemoteCallToServer("On_QiYu_PetTryList", tPetTryList)
	return tZhenqi, tXiyou
end

function UIAdventureView:GetSortTryBook(tAdv)
	local nCurrClassify = self.nTryBookClass

	local function fnCmpBase(a, b) --sort 已尝试/已触发/机缘未到置底
		if a.nSortLevel == b.nSortLevel then
			return a.dwID > b.dwID
		else
			return a.nSortLevel < b.nSortLevel
		end
	end

	local function fnCmpNoraml(a, b)
		if a.bUpBuff and b.bUpBuff then
			return fnCmpBase(a, b)
		elseif a.bUpBuff then
			return true
		elseif b.bUpBuff then
			return false
		else
			return fnCmpBase(a, b)
		end
	end

	local function fnCmpMapBase(a, b)
		if a.nSortLevel == b.nSortLevel then
			return a.nMapID > b.nMapID
		else
			return a.nSortLevel < b.nSortLevel
		end
	end

	local function fnCmpMap(a, b)
		if a.bUpBuff and b.bUpBuff then
			return fnCmpMapBase(a, b)
		elseif a.bUpBuff then
			return true
		elseif b.bUpBuff then
			return false
		else
			return fnCmpMapBase(a, b)
		end
	end

	if nCurrClassify == 1 then
		-- if _nSortClass == 1 then
		-- 	table.sort(tAdv, fnCmpNoraml)
		-- else
		-- 	table.sort(tAdv, fnCmpMap)
		-- end
		table.sort(tAdv, fnCmpMap)
	else
		table.sort(tAdv, fnCmpNoraml)
	end
	return tAdv
end


function UIAdventureView:GetFilterTryBook(tAdv)
	local tRes = {}
	local function fnCheckFilter(t)
		local bMatchClass = false
		local bMatchSearch = false
		local nFilterClass = GetFilterClass()
		if nFilterClass == 1 then
			bMatchClass = true
		else
			bMatchClass = nFilterClass == t.nChanceState + 1
		end

		local szSearchText = self.szSearchText
		if not szSearchText or szSearchText == "" then
			bMatchSearch = true
		elseif string.find(UIHelper.GBKToUTF8(t.szName), szSearchText) then
			bMatchSearch = true
		elseif t.szPetName and string.find(UIHelper.GBKToUTF8(t.szPetName), szSearchText) then
			bMatchSearch = true
		elseif t.nMapID and string.find(UIHelper.GBKToUTF8(Table_GetMapName(t.nMapID)), szSearchText) then
			bMatchSearch = true
		end

		return bMatchClass and bMatchSearch
	end

	for _, v in ipairs(tAdv) do
		if fnCheckFilter(v) then
			table.insert(tRes, v)
		end
	end

	tRes = self:GetSortTryBook(tRes)
	return tRes
end

function UIAdventureView:UpdateTryBookFilter(nFilterClass)
	SetFilterClass(nFilterClass)
	UIHelper.SetString(self.LabelWays, g_tStrings.STR_LUCKY_FILTER_CLASS[nFilterClass])
	if self.nCheckType ~= TYPE_TRIGGER then
		return
	end
	self.nTryBookPage = 1
	if self.nTryBookClass == 1 then
		self:UpdateZhenQiTryBook()
	else
		self:UpdateXiYouTryBook()
	end
end

function UIAdventureView:UpdateTryBook(bClearSearch)
	local nFilterClass = GetFilterClass()
	if not nFilterClass then
		nFilterClass = 1
		SetFilterClass(nFilterClass)
	end

	if nFilterClass == 1 then
		UIHelper.SetSelected(self.TogAll, true)
	elseif nFilterClass == 2 then
		UIHelper.SetSelected(self.TogJiYuanChengShu, true)
	elseif nFilterClass == 3 then
		UIHelper.SetSelected(self.TogJiYuanWeiDao, true)
	elseif nFilterClass == 4 then
		UIHelper.SetSelected(self.TogDengDaiTanSuo, true)
	end

	self.nCheckType = TYPE_TRIGGER

	if bClearSearch == nil then
		bClearSearch = true
	end
	if bClearSearch then
		self.szSearchText = ""
	end
	self.szSearchText = self.szSearchText or ""
	UIHelper.SetString(self.WidgetEdit, self.szSearchText)

	UIHelper.SetVisible(self.WidgetBtn, true)
	-- UIHelper.SetVisible(self.TogQiYu, true)
    -- UIHelper.SetVisible(self.TogZhenQi, true)
    UIHelper.SetVisible(self.BtnReturn, false)
	UIHelper.SetVisible(self.WidgetNotes, true)
	self:ClearBookPage()
	UIHelper.SetVisible(self.scriptTryBookLeft._rootNode, true)
	UIHelper.SetVisible(self.scriptTryBookRight._rootNode, true)

	if self.nTryBookClass == 1 then
        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupR, self.TogZhenQi)
        self:OnSelectedZhenQi()
    elseif self.nTryBookClass == 2 then
        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupR, self.TogQiYu)
        self:OnSelectedQiYu()
    end
end

function UIAdventureView:UpdateZhenQiTryBook()
	local tSelectAdv = self:GetFilterTryBook(self.tZhenqiTry)
	self.scriptTryBookLeft:UpdateZhenQiTryBook(tSelectAdv, self.nTryBookPage)
	-- self.scriptTryBookRight:UpdateZhenQiTryBook(tSelectAdv, self.nTryBookPage)
end

function UIAdventureView:UpdateXiYouTryBook()
	local tSelectAdv = self:GetFilterTryBook(self.tXiyouTry)
	self.scriptTryBookLeft:UpdateXiYouTryBook(tSelectAdv, self.nTryBookPage)
	-- self.scriptTryBookRight:UpdateXiYouTryBook(tSelectAdv, self.nTryBookPage)
end

function UIAdventureView:TripSlashes(szText)
    szText = string.gsub(szText, "\\\\", "\\")
    szText = string.gsub(szText, "\\n", "\n")
    szText = string.gsub(szText, "\\t", "\t")
    szText = string.gsub(szText, '\\\"', '\"')
    szText = string.pure_text(szText)

    szText = string.gsub(szText, "[ \t]+", function (match)
        local len = #match
        if len > 4 then
            len = 4
        end
        return string.rep(" ", len)
    end)

    -- szText = string.gsub(szText, '<color=([^>]+)>', '<color=#5f4e3a>')

    return szText
end

function UIAdventureView:SetQiYuBtnState()
	UIHelper.SetVisible(self.BtnSpecialItemUse, false)
	TreasureBoxData.InitQiYuBox()
    local tQiYuList = TreasureBoxData.GetQiYuBox()
	local bShow = false
	for index, tInfo in ipairs(tQiYuList) do
		if tInfo.bOwnToShow == false then
			bShow = true
			break
		else
			local BoxItem = ItemData.GetItemInfo(tInfo.dwType, tInfo.dwIndex)
			local _, nBagNum, _, _ = ItemData.GetItemAllStackNum(BoxItem, false)
			if nBagNum and nBagNum > 0 then
				bShow = true
				break
			end
		end
	end
	UIHelper.SetVisible(self.BtnSpecialItemUse, bShow)
end

return UIAdventureView