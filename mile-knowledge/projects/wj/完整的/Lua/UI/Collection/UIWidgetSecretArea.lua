-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSecretArea
-- Date: 2023-12-18 10:40:19
-- Desc: ?
-- ---------------------------------------------------------------------------------
local UIWidgetSecretArea = class("UIWidgetSecretArea")

function UIWidgetSecretArea:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bOpen = false
end

function UIWidgetSecretArea:Open()
    if not self.bOpen then
        self.bOpen = true
        self:Init()
    end
end

function UIWidgetSecretArea:OnExit()
    self.bInit = false
    self:UnRegEvent()

    if self.cellPool then self.cellPool:Dispose() end
    self.cellPool = nil
    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
    end
end

function UIWidgetSecretArea:OnShow()

end

function UIWidgetSecretArea:BindUIEvent()

    UIHelper.BindUIEvent(self.BtnSecretAreaSkip, EventType.OnClick, function(btn)
        local dwTargetMapID = nil
        if DungeonData.IsInDungeon() then dwTargetMapID = g_pClientPlayer.GetMapID() end
        local tbInfo = {bRecommendOnly = false, bNeedChooseFirst = true, dwTargetMapID = dwTargetMapID}
        if not DungeonData.CheckDungeonCondition(tbInfo) then tbInfo.dwTargetMapID = nil end
        UIMgr.Open(VIEW_ID.PanelDungeonEntrance, tbInfo)
    end)

    UIHelper.BindUIEvent(self.BtnSecretAreaBoss, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelQianLiFaZhu, true)
        if not APIHelper.IsDid("TeachWorldBoss") then
            TeachBoxData.OpenTutorialPanel(61)
            APIHelper.Do("TeachWorldBoss")
        end
    end)

    UIHelper.BindUIEvent(self.BtnPageUp, EventType.OnClick, function()
        UIHelper.ScrollToLeft(self.ScrollViewSecretArea)
    end)

    UIHelper.BindUIEvent(self.BtnPageDown, EventType.OnClick, function()
        UIHelper.ScrollToRight(self.ScrollViewSecretArea)
    end)

    UIHelper.BindUIEvent(self.BtnSeasonChallage, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelSeasonChallenge, HONOR_CHALLENGE_PAGE.SECRET)
    end)
end

function UIWidgetSecretArea:RegEvent()
end

function UIWidgetSecretArea:UnRegEvent()
    
end



function UIWidgetSecretArea:Init()

    self:InitData()

    self.cellPool = self.cellPool or PrefabPool.New(PREFAB_ID.WidgetRoafCardCell)
    self:UpdateInfo()

    if self.FuncLink then
        self.FuncLink()
    end
    self.nTimer = Timer.AddFrameCycle(self, 2, function()
        self:UpdateArrow()
    end)
end

function UIWidgetSecretArea:UpdateArrow()
    local nPercent = UIHelper.GetScrollPercent(self.ScrollViewSecretArea)
    local nWidth = UIHelper.GetWidth(self.ScrollViewSecretArea)
    local bShowLeft = nPercent >= 10
    local bShowRight = nPercent <= 90
    local tbSize = self.ScrollViewSecretArea:getInnerContainerSize()
    UIHelper.SetVisible(self.WidgetArrowLeft, bShowLeft and tbSize.width > nWidth)
    UIHelper.SetVisible(self.WidgetArrowRight, bShowRight and tbSize.width > nWidth)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSecretArea:RemoveAllChildren()
    if self.tbNodes then
        for index, node in ipairs(self.tbNodes) do
            self.cellPool:Recycle(node)
        end
    end
    self.tbNodes = {}
end

function UIWidgetSecretArea:UpdateInfo()
    self:RemoveAllChildren()
    for nIndex, tBcardInfo in ipairs(self.tbCardList) do
        local node, scriptView = self.cellPool:Allocate(self.ScrollViewSecretArea, tBcardInfo)
        table.insert(self.tbNodes, node)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewSecretArea)
    UIHelper.ScrollToLeft(self.ScrollViewSecretArea)

    self:UpdateSeasonLevelInfo()
end

function UIWidgetSecretArea:UpdateSeasonLevelInfo()
    local nClass = CLASS_MODE.FB
    local nRankLv, _, _, _, nTotalScores = GDAPI_SA_GetRankBaseInfo(nClass)
    local tRankInfo = Table_GetRankInfoByLevel(nRankLv)
    UIHelper.RemoveAllChildren(self.WidgetAnchorSeasonLevelTitle)
    UIHelper.AddPrefab(PREFAB_ID.WidgetSeasonLevelTitle, self.WidgetAnchorSeasonLevelTitle, nClass, tRankInfo, nTotalScores)
end

function UIWidgetSecretArea:GetPageType()
    return 0
end

function UIWidgetSecretArea:InitData()
    self.tbCardList = {}
    local tbNormalList = CollectionData.GetInfoList(CLASS_MODE.FB, CLASS_TYPE.NORMAL)
    local tbSpecialList = CollectionData.GetInfoList(CLASS_MODE.FB, CLASS_TYPE.SPECIAL)
    for i, v in ipairs(tbNormalList) do
        table.insert(self.tbCardList, v)
    end

    for i, v in ipairs(tbSpecialList) do
        table.insert(self.tbCardList, v)
    end
end

function UIWidgetSecretArea:GetIndexByID(nID)
    local tbCardList = self.tbCardList
    for nIndex, tbInfo in ipairs(tbCardList) do
        if tbInfo.dwID == nID then
            return nIndex
        end
    end
    return nil
end

function UIWidgetSecretArea:GetTotalCount()
    local tbCardList = self.tbCardList
    return tbCardList and #tbCardList or 0
end

function UIWidgetSecretArea:LinkToCard(nPageType, nID)
    local func = function()
        if not nID then return end
        local nIndex = self:GetIndexByID(nID)
        local nTotal = self:GetTotalCount()
        if nIndex then
            local nPercent = Lib.SafeDivision(nIndex, nTotal) * 100
            Timer.DelTimer(self, self.nScrollTimerID)
            self.nScrollTimerID = Timer.AddFrame(self, 3, function()
                UIHelper.ScrollToPercent(self.ScrollViewSecretArea, nPercent)
            end)
        end
    end

    if self.bInit then
        func()
    else
        self.FuncLink = func
    end
end
return UIWidgetSecretArea