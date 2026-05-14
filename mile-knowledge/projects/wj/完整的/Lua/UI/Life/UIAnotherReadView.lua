-- ---------------------------------------------------------------------------------
-- Name: UIAnotherReadView
-- PanelAnotherReadMain
-- ---------------------------------------------------------------------------------

local UIAnotherReadView = class("UIAnotherReadView")


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

local tbBookSource = {}

function UIAnotherReadView:OnEnter(nPlayerID)
    self.nPlayerID = nPlayerID
    self.player = GetClientPlayer()
    if self.nPlayerID then
        self.player = GetPlayer(nPlayerID)
    end
    if not self.bInit then
        self:Init()
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIAnotherReadView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAnotherReadView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(VIEW_ID.PanelAnotherReadMain)
    end)

    for index, tog in ipairs(self.tbTogLeft) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function()
            UIHelper.SetToggleGroupSelected(self.ToggleGroupLeft, index - 1)
            self.nSortID = TogLeft[index].ID
            self.szSortName = TogLeft[index].szName
            self:UpdateInfo()
        end)
    end

    UIHelper.RegisterEditBoxEnded(self.EditKindSearch, function()
        self.szSearchKey = UIHelper.GetString(self.EditKindSearch)
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnSift, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnSift, TipsLayoutDir.BOTTOM_RIGHT,
            FilterDef.AnotherRead)
    end)
end

function UIAnotherReadView:RegEvent()
    Event.Reg(self, EventType.OnBookItemSelect, function(nBookID, bSelected)
        if bSelected then
            self.SelectBookID = nBookID
            self:UpdateBookSegList()
        end
    end)

    Event.Reg(self, EventType.OnBookItemCellSelect, function(TogBookSkip, nSegmentID)
        self.SelectSegment = nSegmentID
        if not self.bBookInit then
            self:BookInit()
        end

        if self.tbMyHasReadBook[nSegmentID] then
            UIMgr.Open(VIEW_ID.PanelBookInfo, self.SelectBookID, nSegmentID, tbBookSource[BookID2GlobelRecipeID(self.SelectBookID, nSegmentID)], function ()
                UIHelper.SetSelected(TogBookSkip, false)
            end)
        else
            local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelBookInfo)
            if scriptView == nil then
                scriptView = UIMgr.Open(VIEW_ID.PanelBookInfo)
            end
            scriptView:OnEnterUnreadBook(self.SelectBookID, nSegmentID, tbBookSource[BookID2GlobelRecipeID(self.SelectBookID, nSegmentID)], function ()
                UIHelper.SetSelected(TogBookSkip, false)
            end)
        end
    end)

    Event.Reg(self, "DO_RECIPE_PREPARE_PROGRESS", function()
        local tParam = {
            szType = "Normal",                                           -- 类型: Normal/Skill
            szFormat = Table_GetRecipeName(arg1, arg2) .. "(%.2f/%.2f)", -- 格式化显示文本
            nDuration = arg0 / GLOBAL.GAME_FPS,                          -- 持续时长, 单位为秒
            --  fnStop = function(bCompleted)  -- 停止回调, bCompleted为是否完成读条
        }
        TipsHelper.PlayProgressBar(tParam)
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.AnotherRead.Key then
            self:UpdateSelectedData(tbSelected)
            self:UpdateInfo()
        end
    end)
end

function UIAnotherReadView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIAnotherReadView:Init()
    self.nSortID = 3
    self.szSortName = TogLeft[1].szName
    self.tbFilteTog = { true, true, true, true, true, true, true, true, true, true }
    self.SelectBookID = nil
    self.tbShowBook = {}
    for _, tog in ipairs(self.tbTogLeft) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupLeft, tog)
    end
end

function UIAnotherReadView:UpdateSelectedData(tbSelected)
    self.tbFilteTog = { false, false, false, false, false, false, false, false, false, false }

    for _, nIndex in ipairs(tbSelected[1]) do
        self.tbFilteTog[nIndex] = true
    end

    for _, nIndex in ipairs(tbSelected[2]) do
        self.tbFilteTog[nIndex + 5] = true
    end
end

function UIAnotherReadView:UpdateInfo()
    self:UpdateBookData()
    self:UpdateBookList()
    self:UpdateBookSegList()

    local playerName = UIHelper.GBKToUTF8(self.player.szName)
    local szTitle = playerName .. "拥有"
    UIHelper.SetString(self.LabelOthersOwn, szTitle)
end

function UIAnotherReadView:UpdateBookData()
    self.SelectBookID = nil
    self.tbShowBook = {}
    local tbBookMark = {}
    local nCount = g_tTable.BookSegment:GetRowCount()
    local nIndex = 1
    for i = 2, nCount do
        local item = g_tTable.BookSegment:GetRow(i)
        local nSortID = item.nSort
        local nBookID = item.dwBookID
        if not tbBookMark[nBookID] then
            tbBookMark[nBookID] = {}
            local nSubSortID = Table_GetBookSubSort(nBookID, 1)
            local nSegmentID = item.dwSegmentID
            local bShow = false
            if not self.szSearchKey or self:MatchString(szName, self.szSearchKey) then
                local recipe = GetRecipe(12, nBookID, nSegmentID)
                if recipe then
                    local itemInfo = GetItemInfo(recipe.dwCreateItemType, recipe.dwCreateItemIndex)
                    if self:CanShowWithBindAndTrade(itemInfo) then
                        bShow = true
                    end
                end
            end

            if nSortID == self.nSortID and self.tbFilteTog[nSubSortID] and bShow then
                local tSegmentBook = self.player.GetBookSegmentList(nBookID)
                local nBookNum = Table_GetBookNumber(nBookID, 1)
                local szBookName = Table_GetBookName(nBookID, 1)
                local szName = Table_GetSegmentName(nBookID, nSegmentID)
                self.tbShowBook[nIndex] = {
                    nBookID = nBookID,
                    szName = UIHelper.GBKToUTF8(szBookName),
                    szBookNum = #tSegmentBook .. "/" .. nBookNum,
                    nReadNum = #tSegmentBook,
                    nBookNum = nBookNum
                }

                nIndex = nIndex + 1

                if not self.SelectBookID then
                    self.SelectBookID = nBookID
                end
            end
        end
    end
end

function UIAnotherReadView:UpdateBookList()
    UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupEquipment)
    UIHelper.RemoveAllChildren(self.ScrollViewEquipment)

    local loadIndex = 0
    local loadCount = #self.tbShowBook

    if self.SelectBookID and #self.tbShowBook > 0 then
        if self.nBookListID then
            Timer.DelTimer(self, self.nBookListID)
        end

        self.nBookListID = Timer.AddFrameCycle(self, 1, function()
            for i = 1, 4, 1 do
                loadIndex = loadIndex + 1
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBookName, self.ScrollViewEquipment)
                assert(script)
                UIHelper.ToggleGroupAddToggle(self.TogGroupEquipment, script.TogBookName)
                script:OnEnter(self.tbShowBook[loadIndex])
                if loadIndex == loadCount then
                    Timer.DelTimer(self, self.nBookListID)
                    break
                end
            end
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewEquipment)
        end)
    end
end

function UIAnotherReadView:UpdateBookSegList()
    UIHelper.ToggleGroupRemoveAllToggle(self.tgBookSegList)
    UIHelper.RemoveAllChildren(self.ScrollViewBookList)
    if not self.SelectBookID then
        return
    end
    local nBookID = self.SelectBookID
    local tbOtherHasReadBook = {}
    local tOtherSegmentBook = self.player.GetBookSegmentList(nBookID)
    self.tbMyHasReadBook = {}
    local tMySegmentBook = GetClientPlayer().GetBookSegmentList(nBookID)
    for _, nID in pairs(tOtherSegmentBook) do
        tbOtherHasReadBook[nID] = true
    end
    for _, nID in pairs(tMySegmentBook) do
        self.tbMyHasReadBook[nID] = true
    end

    local nBookNum = Table_GetBookNumber(nBookID, 1)
    for nSegmentID = 1, nBookNum, 1 do
        local szName = Table_GetSegmentName(nBookID, nSegmentID)
        if szName and szName ~= "" and self:MatchString(szName, self.szSearchKey or "") then
            local recipe = GetRecipe(12, nBookID, nSegmentID)
            if recipe then
                local itemInfo = GetItemInfo(recipe.dwCreateItemType, recipe.dwCreateItemIndex)
                if self:CanShowWithBindAndTrade(itemInfo) then
                    local script = UIHelper.AddPrefab(PREFAB_ID.WIdgetBookNameItem, self.ScrollViewBookList, nSegmentID)
                    assert(script)
                    UIHelper.ToggleGroupAddToggle(self.WidgetAnchorRight, script.TogBookSkip)

                    if self.tbMyHasReadBook[nSegmentID] then
                        script:SetImgOwn()
                        script:SetBookReadState(true)
                        script:SetTitleName(UIHelper.GBKToUTF8(szName), cc.c3b(78, 92, 104))
                    else
                        script:SetBookReadState(false)
                        script:SetTitleName(UIHelper.GBKToUTF8(szName), cc.c3b(136, 140, 150))
                    end

                    if tbOtherHasReadBook[nSegmentID] then
                        script:SetImgOtherOwn()
                    end
                end
            end
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewBookList)
end

function UIAnotherReadView:CanShowWithBindAndTrade(itemInfo)
    local bShow = false
    if itemInfo.nBindType == ITEM_BIND.NEVER_BIND then
        if itemInfo.bCanTrade and self.tbFilteTog[6] then
            bShow = true
        end
    else
        if (itemInfo.bCanTrade and self.tbFilteTog[7]) or ((not itemInfo.bCanTrade) and self.tbFilteTog[8]) then
            bShow = true
        end
    end
    return bShow
end

function UIAnotherReadView:BookInit()
    if self.bBookInit then
        return
    end
    self.bBookInit = true
    for i = 1, g_tTable.BookSegment:GetRowCount() do
        local row = g_tTable.BookSegment:GetRow(i)
        if row then
            local dwRecipeID = BookID2GlobelRecipeID(row.dwBookID, row.dwSegmentID)
            local szNpcInfo = row.szNpcInfo
            local tNpcInfoText = SplitString(szNpcInfo, ";")
            local tNpcInfo = {}
            for _, szInfo in ipairs(tNpcInfoText) do
                local t = SplitString(szInfo, "-")
                local dwMapID = tonumber(t[1] or "")
                if dwMapID then
                    local dwNPCID = tonumber(t[2] or "")
                    local szEventLink = t[3] or ""
                    table.insert(tNpcInfo, { dwMapID = dwMapID, dwNPCID = dwNPCID, szEventLink = szEventLink })
                end
            end

            tbBookSource[dwRecipeID] = {
                tQuests  = {},
                tDoodad  = {},
                tNpcInfo = tNpcInfo,
            }
            tbBookSource[UIHelper.GBKToUTF8(row.szSegmentName)] = tbBookSource[dwRecipeID]
        end
    end

    local GetQuestInfo = GetQuestInfo
    for i, tLine in ilines(g_tTable.Quest) do
        local hQuest = GetQuestInfo(tLine.dwQuestID)
        if hQuest and (not hQuest.bHungUp) then
            local tHortation = hQuest.GetHortation()
            if tHortation then
                for j = 1, 2 do
                    local itemgroup = tHortation["itemgroup" .. j]
                    if itemgroup then
                        for k, v in ipairs(itemgroup) do
                            if v.type and v.index then
                                local item = GetItemInfo(v.type, v.index)
                                if item and item.nGenre == ITEM_GENRE.BOOK and tbBookSource[v.count] then
                                    table.insert(tbBookSource[v.count].tQuests, tLine.dwQuestID)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    -- 获取碑铭
    local tDoodadTitle = {
        { f = "i", t = "id" },
        { f = "i", t = "doodadid" },
        { f = "i", t = "middlemap" },
        { f = "s", t = "kind" },
        { f = "i", t = "type" },
        { f = "s", t = "position" },
        { f = "i", t = "defaultcheck" },
        { f = "i", t = "doodadtype" },
    }
    local function ParsePosition(szPosition)
        local tPoint = {}
        for szX, szY, szZ in string.gmatch(szPosition, "([%d]+),([%d]+),([%d]+);?") do
            local nX = tonumber(szX)
            local nY = tonumber(szY)
            local nZ = tonumber(szZ)
            table.insert(tPoint, { nX, nY })
        end
        return tPoint
    end
    for k, v in ipairs(GetMapList()) do
        local szPath = GetMapParams(v)
        if szPath then
            local szFile = szPath .. "minimap_mb\\doodad.tab"
            if Lib.IsFileExist(szFile) then
                local tDoodad = KG_Table.Load(szFile, tDoodadTitle, TABLE_FILE_OPEN_MODE.NORMAL)
                if tDoodad then
                    local t = {}
                    local nRowCount = tDoodad:GetRowCount()
                    local tIDMap = {}
                    for nRow = 2, nRowCount do
                        local tRow = tDoodad:GetRow(nRow)
                        local szKind = UIHelper.GBKToUTF8(tRow.kind)
                        local tPoint = ParsePosition(tRow.position)
                        if nDoodadID ~= 0 then
                            local tBook = tbBookSource
                                [string.gsub(szKind, g_tStrings.STR_BOOK_TIP_INSCRIPTIONS .. "·", "")]
                            if tBook then
                                table.insert(tBook.tDoodad, {
                                    szName  = szKind,
                                    tPoint  = tPoint,
                                    dwMapID = v
                                })
                            end
                        end
                    end
                    tDoodad = nil
                end
            end
        end
    end
end

function UIAnotherReadView:MatchString(szSrc, szDst)
    if not szDst then
        return true
    end
    local nPos = string.match(UIHelper.GBKToUTF8(szSrc), szDst)
    if not nPos then
        return false;
    end

    return true
end

return UIAnotherReadView
