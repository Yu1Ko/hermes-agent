-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMyHomePageBranchList
-- Date: 2023-04-12 16:59:54
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandMyHomePageBranchList = class("UIHomelandMyHomePageBranchList")
local DataModel = nil
local MaxPageCount = 50
function UIHomelandMyHomePageBranchList:OnEnter(tbDataModel)
    DataModel = tbDataModel
    DataModel.nCurrentRankType = COMMUNITY_RANK_TYPE.LEVEL

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if not DataModel.tRecommendList then
        GetHomelandMgr().ApplyCommunityDigest(DataModel.nCurrentMapID, DataModel.nCenterID)
    else
        self:UpdateInfo()
    end
end

function UIHomelandMyHomePageBranchList:OnExit()
    self.bInit = false
end

local TogIndex2RankType = {
    COMMUNITY_RANK_TYPE.NORMAL,
    COMMUNITY_RANK_TYPE.LEVEL,
    COMMUNITY_RANK_TYPE.ACTIVENESS,
}
function UIHomelandMyHomePageBranchList:BindUIEvent()
    for i, tog in ipairs(self.tbTogType) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function ()
            DataModel.UpdateRankList(TogIndex2RankType[i])
            UIHelper.SetSelected(self.TogRankChoose, false)
        end)

        UIHelper.ToggleGroupAddToggle(self.TogGroupRankType, tog)
    end

    UIHelper.SetToggleGroupSelected(self.TogGroupRankType, 1)

    UIHelper.BindUIEvent(self.TogRankChoose, EventType.OnClick, function ()
        for i, tog in ipairs(self.tbTogType) do
            UIHelper.SetSelected(tog, DataModel.nCurrentRankType == TogIndex2RankType[i])
        end
    end)
end

function UIHomelandMyHomePageBranchList:RegEvent()
    Event.Reg(self, EventType.OnUpdateHomelandMyHomeRankList, function ()
        if self.nUpdateInfoTimerID then
            Timer.DelTimer(self, self.nUpdateInfoTimerID)
            self.nUpdateInfoTimerID = nil
        end

        self.nUpdateInfoTimerID = Timer.Add(self, 0.5, function ()
            self:UpdateInfo()
        end)

    end)

    Event.Reg(self, EventType.OnClickHomelandMyHomeRankListIndex, function (nIndex)
        DataModel.ApplyCommunityInfo(DataModel.tRecommendList.nMapID, nil, DataModel.tRecommendList.nCenterID, nIndex, true)
    end)

    Event.Reg(self, EventType.OnViewClose, function (nViewID)
        if nViewID == VIEW_ID.PanelHome then
            UIMgr.Close(self)
        end
    end)
end

function UIHomelandMyHomePageBranchList:UpdateInfo()
    if DataModel.nCurrentRankType == COMMUNITY_RANK_TYPE.NORMAL then
        self:UpdateAllRankInfo()
    elseif DataModel.nCurrentRankType == COMMUNITY_RANK_TYPE.LEVEL then
        self:UpdateLevelRankInfo()
    elseif DataModel.nCurrentRankType == COMMUNITY_RANK_TYPE.ACTIVENESS then
        self:UpdateActivenessRankInfo()
    end

    UIHelper.SetString(self.LabelTilte, g_tStrings.STR_COMMUNITY_RANK_TYPE_TEXT[DataModel.nCurrentRankType])
    UIHelper.SetString(self.LabelTilte01, g_tStrings.STR_COMMUNITY_RANK_TYPE_TEXT[DataModel.nCurrentRankType])
end

function UIHomelandMyHomePageBranchList:UpdateAllRankInfo()
    UIHelper.SetVisible(self.WidgetAllList, true)
    UIHelper.SetVisible(self.WidgetOthersList, false)

    if not self.scriptAllScrollList then
        self.scriptAllScrollList = UIHelper.GetBindScript(self.WidgetAllList)
    end

    local tRecommendList = DataModel.tRecommendList
	local tCopyIndexList = tRecommendList.tCopyIndex
	local tCommunityInfo = DataModel.tCommunityInfo

    local tbData = {}
    local tItemList = {}

    local nPageCount = 0
    for i, tbInfo in ipairs(tCopyIndexList) do
        local fPercentage = (tCommunityInfo.nLandCount - tbInfo.nSurplusCount) / tCommunityInfo.nLandCount
        tbInfo.bRecommend = fPercentage >= 0.5 and fPercentage < 1
        tbInfo.nCurrentRankType = DataModel.nCurrentRankType
        tbInfo.szMapName = UIHelper.GBKToUTF8(Table_GetMapName(DataModel.nCurrentMapID))
        table.insert(tItemList, {
            tArgs = tbInfo
        })

        if #tItemList >= 50 then
            table.insert(tbData, {
                tArgs = { szTitle = string.format("%d-%d", (nPageCount * MaxPageCount + 1), (nPageCount + 1) * MaxPageCount) },
                tItemList = tItemList,
                fnSelectedCallback = function(bSelected)  end,
            })
            nPageCount = nPageCount + 1
            tItemList = {}
        end
    end

    if #tItemList > 0 then
        table.insert(tbData, {
            tArgs = { szTitle = string.format("%d-%d", (nPageCount * MaxPageCount + 1), (nPageCount + 1) * MaxPageCount) },
            tItemList = tItemList,
            fnSelectedCallback = function(bSelected)  end,
        })
        nPageCount = nPageCount + 1
        tItemList = {}
    end

    local func = function(scriptContainer, tArgs)
        UIHelper.SetString(scriptContainer.LabelTitle, tArgs.szTitle)
        UIHelper.SetString(scriptContainer.LabelSelect, tArgs.szTitle)

        Timer.AddFrame(self, 1, function()
            local tbScriptCell = scriptContainer:GetItemScript()
            for _, scriptCell in ipairs(tbScriptCell) do
                scriptCell:SetSelected(DataModel.tCommunityInfo.nIndex)
            end
        end)
    end


    self.scriptAllScrollList:ClearContainer()
    UIHelper.SetupScrollViewTree(self.scriptAllScrollList,
        PREFAB_ID.WidgetHomeLandLeftListBranching,
        PREFAB_ID.WidgetHomeLandLeftListCell,
        func, tbData, true)

    Timer.AddFrame(self, 1, function()
        local scriptContainer = self.scriptAllScrollList.tContainerList[1].scriptContainer
        scriptContainer:SetSelected(true)
    end)
end

function UIHomelandMyHomePageBranchList:UpdateLevelRankInfo()
    UIHelper.SetVisible(self.WidgetAllList, false)
    UIHelper.SetVisible(self.WidgetOthersList, true)
    UIHelper.SetVisible(self.WidgetTilteBranching, false)
    UIHelper.SetVisible(self.WidgetTilteGrade, true)

    local tRecommendList = DataModel.tRecommendList
	local tCopyIndexList = tRecommendList.tCopyIndex
	local tCommunityInfo = DataModel.tCommunityInfo

    self.tbOtherListCells = self.tbOtherListCells or {}

    UIHelper.HideAllChildren(self.ScrollViewLeftBranching)
    for i, tbInfo in ipairs(tCopyIndexList) do
        local fPercentage = (tCommunityInfo.nLandCount - tbInfo.nSurplusCount) / tCommunityInfo.nLandCount
        tbInfo.bRecommend = fPercentage >= 0.5 and fPercentage < 1
        tbInfo.nCurrentRankType = DataModel.nCurrentRankType
        tbInfo.szMapName = UIHelper.GBKToUTF8(Table_GetMapName(DataModel.nCurrentMapID))

        if not self.tbOtherListCells[i] then
            self.tbOtherListCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetHomeLandLeftListCell, self.ScrollViewLeftBranching, tbInfo)
        else
            UIHelper.SetVisible(self.tbOtherListCells[i]._rootNode, true)
            self.tbOtherListCells[i]:OnEnter(tbInfo)
        end
    end

    Timer.AddFrame(self, 1, function ()
        for _, scriptCell in ipairs(self.tbOtherListCells) do
            scriptCell:SetSelected(DataModel.tCommunityInfo.nIndex)
        end
    end)

    UIHelper.ScrollViewDoLayout(self.ScrollViewLeftBranching)
    UIHelper.ScrollToTop(self.ScrollViewLeftBranching, 0)
end

function UIHomelandMyHomePageBranchList:UpdateActivenessRankInfo()
    UIHelper.SetVisible(self.WidgetAllList, false)
    UIHelper.SetVisible(self.WidgetOthersList, true)
    UIHelper.SetVisible(self.WidgetTilteBranching, true)
    UIHelper.SetVisible(self.WidgetTilteGrade, false)

    local tRecommendList = DataModel.tRecommendList
	local tCopyIndexList = tRecommendList.tCopyIndex
	local tCommunityInfo = DataModel.tCommunityInfo

    self.tbOtherListCells = self.tbOtherListCells or {}

    UIHelper.HideAllChildren(self.ScrollViewLeftBranching)
    for i, tbInfo in ipairs(tCopyIndexList) do
		local fPercentage = (tCommunityInfo.nLandCount - tbInfo.nSurplusCount) / tCommunityInfo.nLandCount
        tbInfo.bRecommend = fPercentage >= 0.5 and fPercentage < 1
        tbInfo.nCurrentRankType = DataModel.nCurrentRankType
        tbInfo.szMapName = UIHelper.GBKToUTF8(Table_GetMapName(DataModel.nCurrentMapID))

        if not self.tbOtherListCells[i] then
            self.tbOtherListCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetHomeLandLeftListCell, self.ScrollViewLeftBranching, tbInfo)
        else
            UIHelper.SetVisible(self.tbOtherListCells[i]._rootNode, true)
            self.tbOtherListCells[i]:OnEnter(tbInfo)
        end
    end

    Timer.AddFrame(self, 1, function ()
        for _, scriptCell in ipairs(self.tbOtherListCells) do
            scriptCell:SetSelected(DataModel.tCommunityInfo.nIndex)
        end
    end)

    UIHelper.ScrollViewDoLayout(self.ScrollViewLeftBranching)
    UIHelper.ScrollToTop(self.ScrollViewLeftBranching, 0)
end

return UIHomelandMyHomePageBranchList