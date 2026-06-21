-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIReadView
-- Date: 2022-12-06 11:00:56
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIReadView = class("UIReadView")


TogLeft = {
    {
        ID = 3,
        szName = "杂集"
    },
    {
        ID = 2,
        szName = "道学"
    },
    {
        ID = 1,
        szName = "佛学"
    }
}

local FilterType = {
    Classify = 1,
    State = 2,
    Collect = 3,
    Achievement = 4,
    Channel = 5,
}

local FilterStateType = {
    NoBindAndCanSell = 1,
    NoBindWithoutSell = 2,
    BindAndCanSell = 3,
    BindWithoutSell = 4
}
local FilterCollectType = {
    HasRead = 1,
    NoRead = 2,
}

local FilterAchievementType = {
    Finished = 1,
    Unfinish = 2,
}

local CopyErrorCode = {
    Success = 1,
    OutOfMaterial = 2,
    OutOfVigor = 3,
    SkillLevelTooLow = 4,
    PlayerLevelTooLow = 5,
    HasNoReadBook = 6
}

local MAX_MAKE_COUNT = 99
local MIN_MAKE_COUNT = 1

function UIReadView:OnEnter(nPlayerID)
    self.nPlayerID = UI_GetClientPlayerID()
    self.player = GetClientPlayer()
    self.bAnother = false
    if nPlayerID then
        self.nPlayerID = nPlayerID
        self.player = GetPlayer(nPlayerID)
        self.bAnother = nPlayerID ~= UI_GetClientPlayerID()
    end
    if not self.bInit then        self:RegEvent()
        self:BindUIEvent()

        self.bInit = true
    end
    self:Init()
    self:UpdateInfo()
    Timer.AddFrameCycle(self, 5, function ()
        self:OnFrameBreathe()
    end)
end

function UIReadView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    CraftData.szLastReadSearchKey = self.szSearchKey
end

function UIReadView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        if not self.bCopying then
            UIMgr.Close(VIEW_ID.PanelReadMain)
        else
            self:OnExitCopyState()
        end
    end)

    UIHelper.BindUIEvent(self.BtnCancelCopy, EventType.OnClick, function ()
        self:OnExitCopyState()
    end)

    UIHelper.BindUIEvent(self.TogSift, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogSift, TipsLayoutDir.BOTTOM_RIGHT, FilterDef.SelfRead)
    end)

    UIHelper.BindUIEvent(self.BtnAchievement, EventType.OnClick, function()
        self:OnClickAchievementButton()
    end)

    UIHelper.BindUIEvent(self.BtnCopy, EventType.OnClick, function()
        self:OnEnterCopyState()
    end)

    UIHelper.BindUIEvent(self.BtnDoCopy, EventType.OnClick, function ()
        self:StartCopyProccess()
    end)

    UIHelper.BindUIEvent(self.ButtonAdd, EventType.OnClick, function ()
        self:TryAddMakeCount()
    end)

    UIHelper.BindUIEvent(self.ButtonDecrease, EventType.OnClick, function ()
        self:TrySubMakeCount()
    end)

    UIHelper.BindUIEvent(self.ToggleSelectAll, EventType.OnSelectChanged, function (_, bSelected)
        for nSegmentID, _ in pairs(self.tCheckCopyBook) do
            local scriptCell = self.tbCurBookCellScripts[nSegmentID]
            self.tCheckCopyBook[nSegmentID] = bSelected
            UIHelper.SetSelected(scriptCell.ToggleMultiSelect, bSelected, false)
        end
        self:OnUpdateCopyState()
    end)

    for index, tog in ipairs(self.tbTogLeft) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function ()
            self.tSortID2DefaultBookID[self.nSortID] = self.dwSelectBookID
            UIHelper.SetToggleGroupSelected(self.WidgetAnchorLeft, index - 1)
            self.nSortID = TogLeft[index].ID
            self.szLeftName = TogLeft[index].szName
            self:UpdateInfo()
            self:RedirectToCurBook()
        end)
    end

    UIHelper.RegisterEditBoxEnded(self.EditBookSearch, function()
        self.szSearchKey = UIHelper.GetText(self.EditBookSearch)
        self:UpdateInfo()
    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditBoxPaginate, function()
            self:OnEditBoxChanged()
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditBoxPaginate, function()
            self:OnEditBoxChanged()
        end)
    end

    UIHelper.TableView_addCellAtIndexCallback(self.TableViewRight, function(tableView, nIndex, script, node, cell)
        local tbSelectCell = self.tbShowBook[nIndex]
        if script and tbSelectCell then
            script:OnEnter(tbSelectCell)
            UIHelper.SetSelected(script.TogBookName, self.dwSelectBookID == tbSelectCell.nBookID)
        end
    end)
end

function UIReadView:RegEvent()
    Event.Reg(self, EventType.OnBookItemSelect, function (nBookID, bSelected)
        if bSelected then
            self.dwSelectBookID = nBookID
            self:UpdateBookSegList()
        end
    end)
    Event.Reg(self, EventType.OnBookItemCellSelect, function (TogBookSkip, nSegmentID)
        if UIMgr.bIsOpening then -- 动画没播完不能开新界面
            return
        end

        self.SelectSegment = nSegmentID

        local bHasBook = self.tbSelfHasReadBook[nSegmentID] ~= nil
        local scriptView = UIMgr.Open(VIEW_ID.PanelBookInfo)
        if scriptView then
            if not bHasBook then
                scriptView:OnEnterUnreadBook(self.dwSelectBookID, nSegmentID, self:Craft_GetBookSource(self.dwSelectBookID, nSegmentID), function ()
                    UIHelper.SetSelected(TogBookSkip, false)
                end)
            else
                scriptView:OnEnter(self.dwSelectBookID, nSegmentID)
            end
        end
    end)
    Event.Reg(self, "SYS_MSG", function()
        if arg0 == "UI_OME_CRAFT_RESPOND" then
            if arg1 == CRAFT_RESULT_CODE.SUCCESS then
               self:MakeRecipe()
            end
        end
    end)
    Event.Reg(self, "DO_RECIPE_PREPARE_PROGRESS", function()
        if not self.tCurCopyBook then return end
        local tCopyBook = self.tCurCopyBook
        local nType = 5
        local nID	= Table_GetBookItemIndex(tCopyBook.nBookID, tCopyBook.nSegmentID)
        local szSegmentName = Table_GetSegmentName(tCopyBook.nBookID, tCopyBook.nSegmentID)
        szSegmentName = UIHelper.GBKToUTF8(szSegmentName)
        local tParam = {
            szType = "Normal",
            szTitle = "抄录中",
            szFormat = szSegmentName,
            nStartTime = Timer.RealtimeSinceStartup(),
            nDuration = arg0 / GLOBAL.GAME_FPS,
            dwTabType = nType,
            dwIndex = nID,
            bTouchClose = true,
            fnCancel = function ()
                self.tCurCopyBook = nil
                self.tCopyBookList = nil
                GetClientPlayer().StopCurrentAction()
            end
        }

        table.insert(self.tProgressBarParamList, tParam)
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.SelfRead.Key then
            self.tbSelected = {}
            for nIndex, tbDef in ipairs(tbSelected) do
                self.tbSelected[nIndex] = {}
                for _, nEnableIndex in ipairs(tbDef) do
                    self.tbSelected[nIndex][nEnableIndex] = true
                end
            end

            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "PLAYER_LEAVE_SCENE", function (nPlayerID)
        if not self.bAnother or nPlayerID ~= self.nPlayerID then
            return
        end
        UIMgr.Close(VIEW_ID.PanelBookInfo)
        UIMgr.Close(VIEW_ID.PanelReadMain)
        TipsHelper.ShowNormalTip("对方已离开可交互范围")
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        if self.bCopying then
            Timer.AddFrame(self, 2, function ()
                local nPosX = UIHelper.GetWorldPositionX(self.LabelTitle)
                local nPosY = UIHelper.GetWorldPositionY(self.WidgetAnchorRight)
                UIHelper.SetWorldPosition(self.ScrollViewBookList, nPosX, nPosY)
            end)
        end
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        UIHelper.SetVisible(self.WidgetItemTipsShell, false)
        UIHelper.SetVisible(self.WidgetAnchorLeaveFor, false)
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardOpen, function(editbox)
        if editbox ~= self.EditBoxPaginate then return end
        UIHelper.SetEditBoxGameKeyboardRange(self.EditBoxPaginate, 1, self.nMakeCount)
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        if editbox ~= self.EditBoxPaginate then return end
        self:OnEditBoxChanged()
    end)

    Event.Reg(self, "UPDATE_VIGOR", function()
        self:UpdateExperience()
    end)

    Event.Reg(self, "BAG_ITEM_UPDATE", function()
        self:OnUpdateCopyState()
    end)

    Event.Reg(self, EventType.OnRichTextOpenUrl, function(szUrl, node)
        if string.is_nil(szUrl) then return end

        szUrl = Base64_Decode(szUrl)

        if szUrl then
            local tbLinkData = JsonDecode(szUrl)
            if not tbLinkData then return end

            local szType = tbLinkData.type or ""
            if szType == "HandInBookNpcLink" then
                self:OnClickHandInLink()
            end
        end
    end)

    Event.Reg(self, EventType.OnSelectLeaveForBtn,function(tbInfo)
        if HomelandData.CheckIsHomelandMapTeleportGo(tbInfo.nLinkID, tbInfo.dwMapID) then
            UIHelper.SetVisible(self.WidgetAnchorLeaveFor, false)
            UIMgr.Close(self)
            UIMgr.Close(VIEW_ID.PanelSystemMenu)
            return
        end

        local bCD, _ = MapMgr.GetTransferSkillInfo()
        if bCD then
            UIHelper.ShowSwitchMapConfirm(g_tStrings.USE_RESET_ITEM, function()
                MapMgr.UseResetItem()
                Timer.Add(MapMgr, 0.2, function()
                    RemoteCallToServer("On_Teleport_Go", tbInfo.nLinkID, tbInfo.dwMapID)
                end)
            end)
        else
            RemoteCallToServer("On_Teleport_Go", tbInfo.nLinkID, tbInfo.dwMapID)
        end
        UIHelper.SetVisible(self.WidgetAnchorLeaveFor, false)
        UIMgr.Close(self)
        UIMgr.Close(VIEW_ID.PanelSystemMenu)
    end)
end

function UIReadView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIReadView:Init()
    self.dwSelectBookID = nil
    self.nSortID = 3
    self.szLeftName = TogLeft[1].szName
    self.tbHasReadBook = {}
    self.tbSelfHasReadBook = {}
    self.tbShowBook = {}
    self.tbSelected = {}
    self.tProgressBarParamList = {}
    self.tSortID2DefaultBookID = {}
    self.szSearchKey = self.szSearchKey or CraftData.szLastReadSearchKey
    if self.szSearchKey then
        UIHelper.SetText(self.EditBookSearch, self.szSearchKey)
    end    
    local tbSelected = FilterDef.SelfRead.GetRunTime()
    if tbSelected and #tbSelected > 0 then
        for nIndex, tbDef in ipairs(tbSelected) do
            self.tbSelected[nIndex] = {}
            for _, nEnableIndex in ipairs(tbDef) do
                self.tbSelected[nIndex][nEnableIndex] = true
            end
        end
    else
        for nIndex, tbDef in ipairs(FilterDef.SelfRead) do
            if type(tbDef) == "table" then
                self.tbSelected[nIndex] = {}
                for _, nEnableIndex in ipairs(tbDef.tbDefault) do
                    self.tbSelected[nIndex][nEnableIndex] = true
                end
            end
        end
    end
    if self.bAnother then
        local playerName = UIHelper.GBKToUTF8(self.player.szName)
        local szTitle = playerName .. "拥有"
        UIHelper.SetString(self.LabelOthersOwn, szTitle)
    end

    UIHelper.SetSelected(self.TogSelectedAll, true)
    UIHelper.SetSelected(self.TogSelectedAll2, true)
end

function UIReadView:OnFrameBreathe()
    if #self.tProgressBarParamList > 0 then
        local uiView = UIMgr.GetView(VIEW_ID.PanelCycleProgressBar)
        local scriptView = uiView and uiView.scriptView
        local tParam = table.remove(self.tProgressBarParamList, 1)
        if not scriptView then
            local nMakeCount = 1
            for _, tCopyBook in ipairs(self.tCopyBookList) do
                nMakeCount = nMakeCount + tCopyBook.nMakeCount
            end
            scriptView = UIMgr.Open(VIEW_ID.PanelCycleProgressBar, tParam, nMakeCount)
        else
            scriptView:OnEnter(tParam)
        end
    end
end

function UIReadView:UpdateInfo()
    self:UpdateBookList()
    self:UpdateBookSegList()
    self:UpdateExperience()
    self:UpdateHandInInfo()
    local bAllSame = self:CheckDefaultFilter()
    if bAllSame then
        UIHelper.SetSpriteFrame(self.ImgSiftBg, ShopData.szScreenImgDefault)
    else
        UIHelper.SetSpriteFrame(self.ImgSiftBg, ShopData.szScreenImgActiving)
    end
    if self.bAnother then
        UIHelper.SetString(self.LabelTitle, "查看他人阅读")
    else
        UIHelper.SetString(self.LabelTitle, "阅读")
    end
end

function UIReadView:UpdateBookList()
    self.dwSelectBookID = nil
    self.tbShowBook = {}
    local tbBookMark = {}
    local nNewBookID = self.tSortID2DefaultBookID[self.nSortID]
    UIHelper.RemoveAllChildren(self.ScrollViewFileList)
    local nCount = g_tTable.BookSegment:GetRowCount()
    local nIndex = 1
    for i = 2, nCount do
        local item = g_tTable.BookSegment:GetRow(i)
        local nSortID = item.nSort
        local nBookID = item.dwBookID
        local nSegmentID = item.dwSegmentID

        if not tbBookMark[nBookID] then
            local tBookSegment = g_tTable.BookSegment:Search(nBookID, nSegmentID)
            local nSubSortID = tBookSegment and tBookSegment.nSubSort or -1
            local nBookNum = tBookSegment and tBookSegment.dwBookNumber or 0
            local szBookName = tBookSegment and tBookSegment.szBookName or ""
            local szName = tBookSegment and tBookSegment.szSegmentName or ""
            local bShow = false

            if self:MatchString(szName, self.szSearchKey) or self:MatchString(szBookName, self.szSearchKey) then
                local recipe   = GetRecipe(12, nBookID, nSegmentID)
                if recipe then
                    local bHasReadBook = self:HasReadBook(self.nPlayerID, nBookID, nSegmentID)
                    local bSelfHasReadBook = self:HasReadBook(UI_GetClientPlayerID(), nBookID, nSegmentID)
                    local itemInfo = GetItemInfo(recipe.dwCreateItemType, recipe.dwCreateItemIndex)
                    local bReadFilter = self.tbSelected[FilterType.Collect][FilterCollectType.HasRead] and bHasReadBook
                    bReadFilter = bReadFilter or (self.tbSelected[FilterType.Collect][FilterCollectType.NoRead] and not bHasReadBook)
                    local bSourceFilter = self:CheckSource(nBookID, nSegmentID)
                    local bAchievementFilter = self:FilterSegmentBookByAchievement(nBookID, nSegmentID)
                    local bCompareFilter = not self.bAnother or bHasReadBook or bSelfHasReadBook
                    if self:CanShowWithBindAndTrade(itemInfo) and bReadFilter and bSourceFilter and bAchievementFilter and bCompareFilter then
                        bShow = true
                    end
                end
            end
            if nSortID == self.nSortID and self.tbSelected[FilterType.Classify][nSubSortID] and bShow then
                local tSegmentBook = self.player.GetBookSegmentList(nBookID)
                tbBookMark[nBookID] = {}
                self.tbShowBook[nIndex] = {
                    nBookID = nBookID,
                    szName = UIHelper.GBKToUTF8(szBookName),
                    szBookNum = #tSegmentBook.."/"..nBookNum,
                    nReadNum = #tSegmentBook,
                    nBookNum = nBookNum
                }
                nIndex = nIndex + 1
                if not self.dwSelectBookID then
                    self.dwSelectBookID = nBookID
                end
                if nNewBookID and nNewBookID == nBookID then
                    self.dwSelectBookID = nNewBookID
                end
            end
        end
    end
    UIHelper.TableView_init(self.TableViewRight, #self.tbShowBook, PREFAB_ID.WidgetBookName)
    UIHelper.TableView_reloadData(self.TableViewRight)
    local bIsEmpty = not self.dwSelectBookID
    UIHelper.SetVisible(self.WidgetEmpty, bIsEmpty)
    UIHelper.SetVisible(self.ScrollViewFileList, not bIsEmpty)
    UIHelper.SetVisible(self.BtnAchievement, not bIsEmpty)
    UIHelper.SetVisible(self.BtnCopy, not bIsEmpty)

    UIHelper.ScrollViewDoLayout(self.ScrollViewFileList)
    UIHelper.ScrollToTop(self.ScrollViewFileList, 0)
end

function UIReadView:UpdateBookSegList()
    self.tbHasReadBook = {}
    self.tbSelfHasReadBook = {}
    self.tbCurBookCellScripts = {}
    self.bCurBookHasRead = false
    UIHelper.ToggleGroupRemoveAllToggle(self.WidgetAnchorRight)
    UIHelper.RemoveAllChildren(self.ScrollViewBookList)
    if not self.dwSelectBookID then
        return
    end
    local nBookID = self.dwSelectBookID
    local nBookNum = Table_GetBookNumber(nBookID, 1)
    local tSegmentBook = self.player.GetBookSegmentList(nBookID)
    for _, nID in pairs(tSegmentBook) do
        self.tbHasReadBook[nID] = true
    end
    local player = GetClientPlayer()
    tSegmentBook = player.GetBookSegmentList(nBookID)
    for _, nID in pairs(tSegmentBook) do
        self.tbSelfHasReadBook[nID] = true
    end

    for nSegmentID = 1, nBookNum, 1 do
        local szBookName = Table_GetBookName(nBookID, nSegmentID)
        local szName = Table_GetSegmentName(nBookID, nSegmentID)
        if szName and szName ~= "" and (self:MatchString(szName, self.szSearchKey or "") or self:MatchString(szBookName, self.szSearchKey or ""))then
            local recipe   = GetRecipe(12, nBookID, nSegmentID)
            if recipe then
                local nReLevel = recipe.dwRequireProfessionLevel
                local itemInfo = GetItemInfo(recipe.dwCreateItemType, recipe.dwCreateItemIndex)

                if self:CanShowWithBindAndTrade(itemInfo) then
                    local script = UIHelper.AddPrefab(PREFAB_ID.WIdgetBookNameItem, self.ScrollViewBookList, nSegmentID, function (toggle)
                        local _, scriptItemTips = TipsHelper.ShowItemTips(toggle, recipe.dwCreateItemType, recipe.dwCreateItemIndex, false)
                        local dwRecipeID = BookID2GlobelRecipeID(nBookID, nSegmentID)
                        scriptItemTips:SetBookID(dwRecipeID)
                        scriptItemTips:OnInitWithTabID(recipe.dwCreateItemType, recipe.dwCreateItemIndex)
                        scriptItemTips:SetBtnState({})
                    end)
                    UIHelper.ToggleGroupAddToggle(self.WidgetAnchorRight, script.TogBookSkip)
                    if self.tbHasReadBook[nSegmentID] then
                        self.bCurBookHasRead = true
                        script:SetBookReadState(true)
                        script:SetTitleName(UIHelper.GBKToUTF8(szName), cc.c3b(78, 92, 104))
                    else
                        script:SetBookReadState(false)
                        script:SetTitleName(UIHelper.GBKToUTF8(szName), cc.c3b(136,140,150))
                    end
                    self.tbCurBookCellScripts[nSegmentID] = script
                    UIHelper.SetVisible(script.ImgOwn, self.bAnother and self.tbSelfHasReadBook[nSegmentID] ~= nil)
                    UIHelper.SetVisible(script.ImgOtherOwn, self.bAnother and self.tbHasReadBook[nSegmentID] ~= nil)
                end
            end
        end
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewBookList)
    UIHelper.ScrollToLeft(self.ScrollViewBookList, 0)

    local tAchievements = self:GetBookAllAchievement(self.dwSelectBookID)
    self.bCurBookHasAchievement = #tAchievements > 0
    UIHelper.SetVisible(self.BtnAchievement, self.bCurBookHasAchievement and not self.bAnother)
    UIHelper.SetVisible(self.BtnCopy, true)
    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.BtnCopy))
    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.BtnAchievement))
end

function UIReadView:UpdateExperience()
    UIHelper.SetVisible(self.WidgetReadProgress, not self.bAnother)
    UIHelper.SetVisible(self.WidgetMiscellanyProgress, not self.bAnother)
    if self.bAnother then
        return
    end
    local nLevel     = self.player.GetProfessionLevel(8)
	local nExp       = self.player.GetProfessionProficiency(8)
	local nMaxExp    = GetProfession(8).GetLevelProficiency(nLevel)

    UIHelper.SetString(self.LabslLevelNum, "阅读"..nLevel .. "级")
    UIHelper.SetString(self.LabelNum, nExp.."/"..nMaxExp)
    UIHelper.SetProgressBarPercent(self.ProgressBarRead, 100 * nExp / nMaxExp)

    nLevel 	   = self.player.GetProfessionLevel(8 + self.nSortID)
	nExp 	   = self.player.GetProfessionProficiency(8 + self.nSortID)
	nMaxExp    = GetProfession(8 + self.nSortID).GetLevelProficiency(nLevel)

    UIHelper.SetString(self.LabslLevelNum2, self.szLeftName..nLevel .. "级")
    UIHelper.SetString(self.LabelNum2, nExp.."/"..nMaxExp)
    UIHelper.SetProgressBarPercent(self.ProgressBarMiscellany, 100 * nExp / nMaxExp)

    self.VigorScript = self.VigorScript or UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.WidgetJingLi)
    self.VigorScript:SetCurrencyType(CurrencyType.Vigor)

    local nCurrentVigor = g_pClientPlayer.nVigor + g_pClientPlayer.nCurrentStamina
	local nMaxVigor = g_pClientPlayer.GetMaxVigor() + g_pClientPlayer.nMaxStamina
    self.VigorScript:SetLableCount(nCurrentVigor..'/'..nMaxVigor)
    UIHelper.CascadeDoLayoutDoWidget(UIHelper.GetParent(self.WidgetJingLi), true)
end

function UIReadView:UpdateHandInInfo()
    self.tNpcLinkIDList = {2644,2645,2646,2647}
    local tbLinkData = {type = "HandInBookNpcLink"}
    local szLink = JsonEncode(tbLinkData)
    szLink = Base64_Encode(szLink)
    local szMsg = "<href=%s><color=#ffffff>可前往</c><color=#00ff00>[套书收书人]</c><img src='UIAtlas2_Public_PublicButton_PublicButton1_btn_Trace02' width='40' height='40'/><color=#ffffff>处上交抄套书获得奖励</c></href>"
    szMsg = string.format(szMsg, szLink)
    UIHelper.SetRichText(self.RichTextReward1, szMsg)
    UIHelper.LayoutDoLayout(self.LayoutHandInReward)
end

function UIReadView:OnClickHandInLink()
    if not self.tNpcLinkIDList then return end
    local tNpcID2Index = {
        [5926] = 3,
        [494] = 3,
        [495] = 2,
        [496] = 1
    }

    local tTravelList = {}
    for _, dwNpcLinkID in ipairs(self.tNpcLinkIDList) do
        local tAllLinkInfo = Table_GetCareerGuideAllLink(dwNpcLinkID) or {}
        for _, tbInfo in ipairs(tAllLinkInfo) do
            local nSortID = tNpcID2Index[tbInfo.dwNpcID]
            if nSortID == self.nSortID then
                table.insert(tTravelList, 1, tbInfo)
            end

            if nSortID == nil then
                table.insert(tTravelList, tbInfo)
            end
        end
    end

    local scriptTravelView = UIHelper.GetBindScript(self.WidgetAnchorLeaveFor)
    if scriptTravelView then
        scriptTravelView:OnEnter(tTravelList, 8)
    end

    local bVisable = UIHelper.GetVisible(self.WidgetAnchorLeaveFor)
    UIHelper.SetVisible(self.WidgetAnchorLeaveFor, not bVisable)
end

function UIReadView:OnEditBoxChanged()
    local szMakeCount = UIHelper.GetText(self.EditBoxPaginate)
    self.nMakeCount = tonumber(szMakeCount) or MIN_MAKE_COUNT
    if self.nMakeCount > MAX_MAKE_COUNT then self.nMakeCount = MAX_MAKE_COUNT end
    if self.nMakeCount < MIN_MAKE_COUNT then self.nMakeCount = MIN_MAKE_COUNT end
    UIHelper.SetText(self.EditBoxPaginate, tostring(self.nMakeCount))
    self:OnUpdateCopyState()
end

function UIReadView:CanShowWithBindAndTrade(itemInfo)
    local bShow = false
    local bNoBind = itemInfo.nBindType == ITEM_BIND.NEVER_BIND

    bShow = bShow or (bNoBind and itemInfo.bCanTrade and self.tbSelected[FilterType.State][FilterStateType.NoBindAndCanSell])
    bShow = bShow or (bNoBind and not itemInfo.bCanTrade and self.tbSelected[FilterType.State][FilterStateType.NoBindWithoutSell])
    bShow = bShow or (not bNoBind and itemInfo.bCanTrade and self.tbSelected[FilterType.State][FilterStateType.BindAndCanSell])
    bShow = bShow or (not bNoBind and not itemInfo.bCanTrade and self.tbSelected[FilterType.State][FilterStateType.BindWithoutSell])

    return bShow
end

function UIReadView:GetAchiState(tAchievement)
	if not self.player then
		return
	end


	local bAllFinish = true
	for _, dwID in ipairs(tAchievement) do
		local bFinish = self.player.IsAchievementAcquired(dwID)
        if not bFinish then
			bAllFinish = false
			break
		end
	end
	return bAllFinish
end

function UIReadView:GetBookAllAchievement(dwBookID)
    local nCount = g_tTable.BookSegment:GetRowCount()
    local tAchievementMap = {}
    local tAchievements = {}
    for i = 2, nCount do
        local item = g_tTable.BookSegment:GetRow(i)
        if item.dwBookID == dwBookID then
            local tBookSource = self:Craft_GetBookSource(item.dwBookID, item.dwSegmentID)
            if tBookSource and tBookSource.tAchievement and #tBookSource.tAchievement > 0 then
                for _, dwID in pairs(tBookSource.tAchievement) do
                    tAchievementMap[dwID] = true
                end
            end
        end
    end
    for dwID, _ in pairs(tAchievementMap) do
        table.insert(tAchievements, dwID)
    end
    table.sort(tAchievements, function (a, b) return a > b end)
    return tAchievements
end

function UIReadView:OnClickAchievementButton()
    local tAchievements = self:GetBookAllAchievement(self.dwSelectBookID)
    if #tAchievements > 0 then
        local _, scriptTips = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetReadAchievementListTip, self.BtnAchievement, tAchievements)
        local nHeight = UIHelper.GetHeight(scriptTips._rootNode)
        local nWidth = UIHelper.GetWidth(self.BtnAchievement)
        local nPosX = UIHelper.GetWorldPositionX(scriptTips._rootNode) + 25
        local nPosY = UIHelper.GetWorldPositionY(self.BtnAchievement) - nHeight/2
        UIHelper.SetWorldPosition(scriptTips._rootNode, nPosX, nPosY)
    end
end

function UIReadView:OnEnterCopyState()
    self.bCopying = true
    self.nMakeCount = 1
    UIHelper.SetText(self.EditBoxPaginate, "1")
    UIHelper.PlayAni(self, self.AniAll, "Ani_FullScreen_Show")

    UIHelper.SetVisible(self.WidgetAniLeft, false)
    UIHelper.SetVisible(self.WidgetMaterial, true)
    UIHelper.SetVisible(self.WidgetAniCopyBottom, true)
    UIHelper.SetVisible(self.BtnAchievement, false)
    UIHelper.SetVisible(self.BtnCopy, false)
    UIHelper.LayoutDoLayout(self.LayoutOperBtn)

    self.nBookListPosX = self.nBookListPosX or UIHelper.GetWorldPositionX(self.ScrollViewBookList)
    self.nBookListPosY = self.nBookListPosY or UIHelper.GetWorldPositionY(self.ScrollViewBookList)
    local nPosX = UIHelper.GetWorldPositionX(self.LabelTitle)
    UIHelper.SetWorldPosition(self.ScrollViewBookList, nPosX, self.nBookListPosY)

    self.tCheckCopyBook = {}
    for nSegmentID, scriptCell in pairs(self.tbCurBookCellScripts) do
        UIHelper.SetSelected(scriptCell.ToggleMultiSelect, false, false)
        self.tCheckCopyBook[nSegmentID] = false
        scriptCell:SetMultiSelectEnable(true)
        scriptCell:SetMultiSelectCallBack(function (bSelected)
            self.tCheckCopyBook[nSegmentID] = bSelected
            self:OnUpdateCopyState()
        end)
    end
    self:OnUpdateCopyState()
    UIHelper.ScrollViewDoLayout(self.ScrollViewBookList)
    UIHelper.ScrollToLeft(self.ScrollViewBookList, 0)

    UIHelper.SetString(self.LabelTitle, "抄录")
end

function UIReadView:OnExitCopyState()
    self.bCopying = false
    UIHelper.PlayAni(self, self.AniAll, "Ani_FullScreen_Show")

    UIHelper.SetVisible(self.WidgetAniLeft, true)
    UIHelper.SetVisible(self.WidgetMaterial, false)
    UIHelper.SetVisible(self.WidgetAniCopyBottom, false)
    UIHelper.SetVisible(self.BtnAchievement, self.bCurBookHasAchievement)
    UIHelper.SetVisible(self.BtnCopy, true)
    UIHelper.LayoutDoLayout(self.LayoutOperBtn)

    UIHelper.SetWorldPosition(self.ScrollViewBookList, self.nBookListPosX, self.nBookListPosY)

    for nSegmentID, scriptCell in pairs(self.tbCurBookCellScripts) do
        UIHelper.SetVisible(scriptCell._rootNode, true)
        scriptCell:SetMultiSelectEnable(false)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewBookList)
    UIHelper.ScrollToLeft(self.ScrollViewBookList, 0)

    if self.bAnother then
        UIHelper.SetString(self.LabelTitle, "查看他人阅读")
    else
        UIHelper.SetString(self.LabelTitle, "阅读")
    end
end

function UIReadView:OnUpdateCopyState()
    if not self.bCopying then return end
    -- 更新底部面板
    local nTotalCount = 0
    local nSelectCount = 0
    for nSegmentID, bSelected in pairs(self.tCheckCopyBook) do
        if bSelected then nSelectCount = nSelectCount + 1 end
        nTotalCount = nTotalCount + 1
    end
    local bSelectAll = nTotalCount == nSelectCount
    local szSelect = string.format("%d/%d", nSelectCount, nTotalCount)

    UIHelper.SetSelected(self.ToggleSelectAll, bSelectAll, false)
    UIHelper.SetString(self.LabelCopyNum, szSelect)
    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.LabelCopyNum))
    UIHelper.SetVisible(self.WidgetMaterialDetail, nSelectCount > 0)
    UIHelper.SetVisible(self.WidgetMaterialEmpty, nSelectCount == 0)
    -- 更新右侧材料面板
    UIHelper.SetScrollViewCombinedBatchEnabled(self.ScrollViewMaterialList, false)
    UIHelper.RemoveAllChildren(self.LayoutMaterialList)
    local dwMaxRequireProfessionLevel = 0
    local dwMaxProfessionIDExt = 0
    local dwMaxRequireProfessionLevelExt = 0
    local nMaxRequirePlayerLevel = 0
    local nTotalVirgor = 0
    local nErrorCode = CopyErrorCode.Success
    local ItemCountMap = {}
    local tMaterialLsit = {}
    local bHasNoReadBook = false
    for nSegmentID, bSelected in pairs(self.tCheckCopyBook) do
        if bSelected then
            local recipe = GetRecipe(12, self.dwSelectBookID, nSegmentID)
            if recipe then
                if dwMaxRequireProfessionLevel < recipe.dwRequireProfessionLevel then dwMaxRequireProfessionLevel = recipe.dwRequireProfessionLevel end
                if dwMaxRequireProfessionLevelExt < recipe.dwRequireProfessionLevelExt then
                    dwMaxProfessionIDExt = recipe.dwProfessionIDExt
                    dwMaxRequireProfessionLevelExt = recipe.dwRequireProfessionLevelExt
                end
                if recipe.nRequirePlayerLevel and nMaxRequirePlayerLevel < recipe.nRequirePlayerLevel then nMaxRequirePlayerLevel = recipe.nRequirePlayerLevel end
                nTotalVirgor = nTotalVirgor + self.nMakeCount * (recipe.nVigor or 0)
                for nIndex = 1, 4, 1 do
                    local nType  = recipe["dwRequireItemType"..nIndex]
                    local nID	 = recipe["dwRequireItemIndex"..nIndex]
                    local nNeed  = recipe["dwRequireItemCount"..nIndex]
                    nNeed = nNeed * self.nMakeCount
                    if not ItemCountMap[nType] then ItemCountMap[nType] = {} end
                    ItemCountMap[nType][nID] = ItemCountMap[nType][nID] or 0
                    ItemCountMap[nType][nID] = ItemCountMap[nType][nID] + nNeed
                end
                local scriptCell = self.tbCurBookCellScripts[nSegmentID]
                if scriptCell and not scriptCell.bRead then bHasNoReadBook = true end
            end
        end
    end
    if bHasNoReadBook then nErrorCode = CopyErrorCode.HasNoReadBook end
    for nType, Id2Count in pairs(ItemCountMap) do
        for nID, nNeed in pairs(Id2Count) do
            table.insert(tMaterialLsit, {
                nType = nType,
                nID = nID,
                nNeed = nNeed
            })
        end
    end
    table.sort(tMaterialLsit, function (leftMaterial, rightMaterial)
        if leftMaterial.nType ~= rightMaterial.nType then return leftMaterial.nType > rightMaterial.nType end
        return leftMaterial.nID > rightMaterial.nID
    end)
    for _, tMaterial in ipairs(tMaterialLsit) do
        local nType, nID, nNeed = tMaterial.nType, tMaterial.nID, tMaterial.nNeed
        if nNeed > 0 then
            local ItemRequire = GetItemInfo(nType, nID)
            local szItemName = ItemData.GetItemNameByItemInfo(ItemRequire)
            local nCount = g_pClientPlayer.GetItemAmount(nType, nID)
            local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItemWithName, self.ScrollViewMaterialList)
            if scriptItem then
                scriptItem:RegisterSelectEvent(function (bSelected)
                    UIHelper.SetVisible(self.WidgetItemTipsShell, true)
                    self.scriptMaterialTips = self.scriptMaterialTips or UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTipsShell)
                    self.scriptMaterialTips:OnInitWithTabID(nType, nID)
                    self.scriptMaterialTips:SetBtnState({})
                end)

                scriptItem:SetLabelItemName(UIHelper.GBKToUTF8(szItemName))
                scriptItem:SetImgIcon(UIHelper.GetIconPathByItemInfo(ItemRequire))
                scriptItem:SetItemQualityBg(ItemRequire.nQuality)
                scriptItem:SetLableCount(nCount.."/"..nNeed)

                if nNeed > nCount then
                    nErrorCode = CopyErrorCode.OutOfMaterial
                    scriptItem:SetTextColor(cc.c3b(0xff,0x76,0x76))
                    scriptItem:SetLabelCountColor(cc.c3b(0xff,0x76,0x76))
                else
                    scriptItem:SetTextColor(cc.c3b(0xff,0xff,0xff))
                    scriptItem:SetLabelCountColor(cc.c3b(0xff,0xff,0xff))
                end
                UIHelper.SetTouchDownHideTips(scriptItem.ToggleSelect, false)
                UIHelper.RemoveAllChildren(scriptItem.ToggleSelect) -- 交互要求，手动移除光圈
            end
        end
    end

    local nLevel = g_pClientPlayer.GetProfessionLevel(8)
    local szContent = ""
    if nLevel < dwMaxRequireProfessionLevel then
        nErrorCode = CopyErrorCode.SkillLevelTooLow
        szContent = "<color=#FF7676>".."阅读".. dwMaxRequireProfessionLevel .. "级 </c>"
    else
        szContent = "<color=#FFFFFF>".."阅读".. dwMaxRequireProfessionLevel .. "级 </c>"
    end
    if dwMaxProfessionIDExt ~= 0 then
        local ProfessionExt = GetProfession(dwMaxProfessionIDExt);
        if ProfessionExt then
            local nExtLevel = g_pClientPlayer.GetProfessionLevel(dwMaxProfessionIDExt)
            local content = Table_GetProfessionName(dwMaxProfessionIDExt).. dwMaxRequireProfessionLevelExt.."级"
            if nExtLevel < dwMaxRequireProfessionLevelExt then
                nErrorCode = CopyErrorCode.SkillLevelTooLow
                szContent = szContent.." ".."<color=#FF7676>"..content.."</c>"
            else
                szContent = szContent.." ".."<color=#FFFFFF>"..content.."</c>"
            end
        end
    end
    if nMaxRequirePlayerLevel and nMaxRequirePlayerLevel ~= 0 then
        local content = " 角色"..nMaxRequirePlayerLevel.."级"
        if g_pClientPlayer.nLevel < nMaxRequirePlayerLevel then
            nErrorCode = CopyErrorCode.PlayerLevelTooLow
            szContent = szContent.."<color=#FF7676>"..content.."</c>"
        else
            szContent = szContent.."<color=#FFFFFF>"..content.."</c>"
        end
    end

    UIHelper.SetRichText(self.RichTextAcquisitionsTips,  szContent)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewMaterialList)

    local szVigor = "<color=#FFFFFF>%d</c>"
    if not g_pClientPlayer.IsVigorAndStaminaEnough(nTotalVirgor) then
        szVigor = "<color=#FF7676>%d</c>"
        nErrorCode = CopyErrorCode.OutOfVigor
    end
    UIHelper.SetRichText(self.LabelConsumeNum, string.format(szVigor, nTotalVirgor))
    UIHelper.LayoutDoLayout(self.WidgetConsumeNum)

    UIHelper.SetButtonState(self.BtnDoCopy, BTN_STATE.Normal)
    if nErrorCode == CopyErrorCode.OutOfMaterial then
        UIHelper.SetButtonState(self.BtnDoCopy, BTN_STATE.Disable, "材料不足")
    elseif nErrorCode == CopyErrorCode.OutOfVigor then
        UIHelper.SetButtonState(self.BtnDoCopy, BTN_STATE.Disable, "精力不足")
    elseif nErrorCode == CopyErrorCode.SkillLevelTooLow then
        UIHelper.SetButtonState(self.BtnDoCopy, BTN_STATE.Disable, "技能等级太低")
    elseif nErrorCode == CopyErrorCode.PlayerLevelTooLow then
        UIHelper.SetButtonState(self.BtnDoCopy, BTN_STATE.Disable, "角色等级太低")
    elseif nErrorCode == CopyErrorCode.HasNoReadBook then
        UIHelper.SetButtonState(self.BtnDoCopy, BTN_STATE.Disable, "仅可抄录已阅读书籍")
    elseif nErrorCode == CopyErrorCode.Success then
        if nSelectCount == 0 then
            UIHelper.SetButtonState(self.BtnDoCopy, BTN_STATE.Disable, "请先选择至少一本书籍")
        end
    end

    UIHelper.SetButtonState(self.ButtonAdd, BTN_STATE.Normal)
    UIHelper.SetButtonState(self.ButtonDecrease, BTN_STATE.Normal)
    if self.nMakeCount >= MAX_MAKE_COUNT then UIHelper.SetButtonState(self.ButtonAdd, BTN_STATE.Disable, "已达到最大抄录批次") end
    if self.nMakeCount <= MIN_MAKE_COUNT then UIHelper.SetButtonState(self.ButtonDecrease, BTN_STATE.Disable, "已达到最小抄录批次") end
end

function UIReadView:TryAddMakeCount()
    if self.nMakeCount >= MAX_MAKE_COUNT then return end
    self.nMakeCount = self.nMakeCount + 1

    UIHelper.SetText(self.EditBoxPaginate, tostring(self.nMakeCount))
    self:OnUpdateCopyState()
end

function UIReadView:TrySubMakeCount()
    if self.nMakeCount <= MIN_MAKE_COUNT then return end
    self.nMakeCount = self.nMakeCount - 1

    UIHelper.SetText(self.EditBoxPaginate, tostring(self.nMakeCount))
    self:OnUpdateCopyState()
end

function UIReadView:StartCopyProccess()
    self.tCopyBookList = {}
    for nSegmentID, bSelected in pairs(self.tCheckCopyBook) do
        if bSelected then
            table.insert(self.tCopyBookList, {
                nBookID = self.dwSelectBookID,
                nSegmentID = nSegmentID,
                nMakeCount = self.nMakeCount,
            })
        end
    end
    self:MakeRecipe()
end

function UIReadView:MakeRecipe()
    local nFreeSize = ItemData.GetBagFreeCellSize()
    if nFreeSize <= 0 then
        self.tCurCopyBook = nil
        self.tCopyBookList = nil
        GetClientPlayer().StopCurrentAction()
        UIMgr.Close(VIEW_ID.PanelCycleProgressBar)
        TipsHelper.ShowImportantRedTip("背包容量不足")
    end
    if not self.tCopyBookList or table.is_empty(self.tCopyBookList) then return end
    local tCopyBook = self.tCopyBookList[1]
    self.tCurCopyBook = tCopyBook
    GetClientPlayer().CastProfessionSkill(12, tCopyBook.nBookID, tCopyBook.nSegmentID)

    tCopyBook.nMakeCount = tCopyBook.nMakeCount - 1
    if tCopyBook.nMakeCount <= 0 then table.remove(self.tCopyBookList, 1) end
end

function UIReadView:FilterSegmentBookByAchievement(dwBookID, dwSegmentID)
    local tBookSource = self:Craft_GetBookSource(dwBookID, dwSegmentID)
	if not tBookSource then
		return false
	end

    local bNeedFinished = self.tbSelected[FilterType.Achievement][FilterAchievementType.Finished]
    local bNeedUnfinished = self.tbSelected[FilterType.Achievement][FilterAchievementType.Unfinish]
	if bNeedFinished and bNeedUnfinished then
		return true
	end

	if #tBookSource.tAchievement <= 0 then
		return false
	end

	local bAllFinish = self:GetAchiState(tBookSource.tAchievement)
	return (bNeedFinished and bAllFinish) or (bNeedUnfinished and not bAllFinish)
end

function UIReadView:MatchString(szSrc, szDst)
    if not szDst then
        return true
    end
    szSrc = UIHelper.GBKToUTF8(szSrc)
	local nPos = string.match(szSrc, szDst)
	if not nPos then
	   return false;
	end

	return true
end

local tSourceKey = {"tQuests", "tSourceNpc", "tSourceMap", "tBoss", "tDoodad"}
function UIReadView:CheckSource(dwBookID, dwSegmentID)
	local tFilterSource = self.tbSelected[FilterType.Channel]
	if not tFilterSource or #tFilterSource >= #tSourceKey then -- 全选可以不检查途径，选了途径就必须有途径才显示
		return  true
	end

	local tBookSource = self:Craft_GetBookSource(dwBookID, dwSegmentID)
	if not tBookSource then
		return false
	end

	for k, v in ipairs(tSourceKey) do
		if tFilterSource[k] and tBookSource[v] and #tBookSource[v] > 0 then
			return true
		end
	end

	return false
end

function UIReadView:Craft_GetBookSource(nBookID, nSegmentID)
    local tbBookSource = ItemData.GetAllBookInfo()
	local tBook = tbBookSource[BookID2GlobelRecipeID(nBookID, nSegmentID)]
	return tBook
end

function UIReadView:CheckDefaultFilter()
    local bAllSame = true
    for nIndex, subIndexList in ipairs(self.tbSelected) do
        local oneDef = FilterDef.SelfRead[nIndex]
        if oneDef then
            local tbDefaultMap = {}
            for subIndex,_ in ipairs(oneDef.tbDefault) do
                tbDefaultMap[subIndex] = true
            end
            for subIndex, bSelected in ipairs(subIndexList) do
                bAllSame = bAllSame and tbDefaultMap[subIndex] == bSelected
            end
            for subIndex, bSelected in ipairs(tbDefaultMap) do
                bAllSame = bAllSame and subIndexList[subIndex] == bSelected
            end
        end
    end

    return bAllSame
end

function UIReadView:HasReadBook(nPlayerID, nBookID, nSegmentID)
    local player = GetPlayer(nPlayerID)
    if not player then
        return false
    end
    local tSegmentBook = player.GetBookSegmentList(nBookID)
    for _, nID in pairs(tSegmentBook) do
        if nID == nSegmentID then
            return true
        end
    end
    return false
end

local function TableView_scrollToCell(tableView, nCellCount, nIndex, nDuration)
    if not safe_check(tableView) then
        return
    end
    local tableViewMask = UIHelper.GetParent(tableView)
    -- 整个table view的最外层组件，可能跨越一个屏幕，基于这个计算每个cell的高度
    local uiWholeTable = UIHelper.GetChildren(tableView)[1]
    -- 单个cell的高度
    local nCellHeight = UIHelper.GetHeight(uiWholeTable) / nCellCount
    -- 实际显示在屏幕中的table的部分的高度
    local nPageHeight = UIHelper.GetHeight(tableViewMask)

    -- 单个屏幕中显示的cell数目
    local nCellCountPerPage = nPageHeight / nCellHeight
    local nOffsetCellCount = nCellCount - nCellCountPerPage - nIndex + 1
    if nOffsetCellCount < 0 then nOffsetCellCount = 0 end
    if nOffsetCellCount > nCellCount - nCellCountPerPage then nOffsetCellCount = nCellCount - nCellCountPerPage end

    -- table view默认会在最下方，offset是y轴移动距离，负值时表示整个table view在屏幕中往下拖动，效果就是上面的cell会慢慢显示在屏幕中
    -- 往下拖动 nCellCount - nCellCountPerPage 后，第一个cell会显示在屏幕最上方
    -- 如果想要第 nIndex 个cell显示在屏幕最上方，需要减少拖动 nIndex - 1 个cell的距离
    UIHelper.TableView_scrollTo(tableView, -nOffsetCellCount * nCellHeight, nDuration)
end

function UIReadView:RedirectToCurBook()
    local nBookID = self.dwSelectBookID
    if not nBookID then return end

    local nTargetIndex = 1
    for nIndex, tParam in ipairs(self.tbShowBook) do
        if tParam.nBookID == nBookID then
            nTargetIndex = nIndex
            break
        end
    end

    local nTotalCount = #self.tbShowBook
    TableView_scrollToCell(self.TableViewRight, nTotalCount, nTargetIndex, 0)
end

return UIReadView