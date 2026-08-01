-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetAthletics
-- Date: 2023-12-15 14:47:01
-- Desc: ?
-- ---------------------------------------------------------------------------------
local tbType = {
    [1] = CLASS_TYPE.JJC,
    [2] = CLASS_TYPE.BATTLEFIELD,
    [3] = CLASS_TYPE.DESERTSTORM,
}
local UIWidgetAthletics = class("UIWidgetAthletics")

function UIWidgetAthletics:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bOpen = false
end

function UIWidgetAthletics:Open()
    if not self.bOpen then
        self.bOpen = true
        self:Init()
        self:UpdateRedPoint()
        if self.FuncLink then self.FuncLink() end
    end
end

function UIWidgetAthletics:OnExit()
    self.bInit = false
    self:UnRegEvent()

    if self.cellPool then self.cellPool:Dispose() end
    self.cellPool = nil
    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
    end
end

function UIWidgetAthletics:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnPageUp, EventType.OnClick, function()
        UIHelper.ScrollToLeft(self.ScrollViewAthletics)
    end)

    UIHelper.BindUIEvent(self.BtnPageDown, EventType.OnClick, function()
        UIHelper.ScrollToRight(self.ScrollViewAthletics)
    end)

    UIHelper.BindUIEvent(self.BtnSeasonChallage, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelSeasonChallenge, HONOR_CHALLENGE_PAGE.ATHLETICS)
    end)
end

function UIWidgetAthletics:RegEvent()
end

function UIWidgetAthletics:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetAthletics:Init()
    self:InitData()
    self.cellPool = self.cellPool or PrefabPool.New(PREFAB_ID.WidgetRoafCardAndSeasonLayout)
    self:UpdateInfo()
    self.nTimer = Timer.AddFrameCycle(self, 2, function()
        self:UpdateArrow()
    end)
end

function UIWidgetAthletics:UpdateArrow()
    local nPercent = UIHelper.GetScrollPercent(self.ScrollViewAthletics)
    local bShowLeft = nPercent >= 10
    local bShowRight = nPercent <= 90

    local nWidth = UIHelper.GetWidth(self.ScrollViewAthletics)
    local tbSize = self.ScrollViewAthletics:getInnerContainerSize()
    UIHelper.SetVisible(self.WidgetArrowLeft, bShowLeft and tbSize.width > nWidth)
    UIHelper.SetVisible(self.WidgetArrowRight, bShowRight and tbSize.width > nWidth)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetAthletics:RemoveAllChildren()
    if self.tbNodes then
        for index, node in ipairs(self.tbNodes) do
            self.cellPool:Recycle(node)
        end
    end
    self.tbNodes = {}
end

function UIWidgetAthletics:BuildGroupedCardList()
    local tbGroupMap = {}
    local tbGroupList = {}

    for _, tBcardInfo in ipairs(self.tbCardList or {}) do
        local nClass2 = tBcardInfo.nClass2
        if not tbGroupMap[nClass2] then
            tbGroupMap[nClass2] = {
                nClass2 = nClass2,
                tbCardList = {},
            }
            table.insert(tbGroupList, tbGroupMap[nClass2])
        end
        table.insert(tbGroupMap[nClass2].tbCardList, tBcardInfo)
    end

    return tbGroupList
end

function UIWidgetAthletics:UpdateInfo()
    self:RemoveAllChildren()

    local tbGroupedList = self:BuildGroupedCardList()
    for _, tbGroup in ipairs(tbGroupedList) do
        local node, scriptView = self.cellPool:Allocate(
            self.ScrollViewAthletics,
            tbGroup.tbCardList,
            tbGroup.nClass2
        )
        table.insert(self.tbNodes, node)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewAthletics)
    UIHelper.ScrollToLeft(self.ScrollViewAthletics)
end

function UIWidgetAthletics:GetPageType()
    return 0
end

function UIWidgetAthletics:UpdateRedPoint()
    if Storage.Arena.bFirstOpen and Storage.Arena.bHaveRedPoint then
        Storage.Arena.bFirstOpen = false
        Storage.Arena.bHaveRedPoint = false
        Storage.Arena.bLocked = false
        Storage.Arena.Flush()
    end
end

function UIWidgetAthletics:InitData()
    self.tbCardList = {}
    for i, v in ipairs(tbType) do
        local tbList = CollectionData.GetInfoList(CLASS_MODE.CONTEST, v)
        for _, info in ipairs(tbList) do
            table.insert(self.tbCardList, info)
        end
    end
end

function UIWidgetAthletics:GetIndexByID(nID)
    local tbCardList = self.tbCardList
    for nIndex, tbInfo in ipairs(tbCardList) do
        if tbInfo.dwID == nID then
            return nIndex
        end
    end
    return nil
end

function UIWidgetAthletics:GetTotalCount()
    local tbCardList = self.tbCardList
    return tbCardList and #tbCardList or 0
end

function UIWidgetAthletics:LinkToCard(nPageType, nID)
    local func = function()
        if not nID then return end
        local nIndex = self:GetIndexByID(nID)
        local nTotal = self:GetTotalCount()
        if nIndex then
            local nPercent = Lib.SafeDivision(nIndex, nTotal) * 100
            Timer.DelTimer(self, self.nScrollTimerID)
            self.nScrollTimerID = Timer.AddFrame(self, 3, function()
                UIHelper.ScrollToPercent(self.ScrollViewAthletics, nPercent)
            end)
        end
    end

    if self.bInit then
        func()
    else
        self.FuncLink = func
    end
end

return UIWidgetAthletics