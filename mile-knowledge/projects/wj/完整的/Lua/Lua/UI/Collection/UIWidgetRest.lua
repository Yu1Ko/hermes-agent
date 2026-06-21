-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetRest
-- Date: 2024-02-01 16:22:27
-- Desc: ?
-- ---------------------------------------------------------------------------------
local tbType = {
    [1] = CLASS_TYPE.HOME,
    [2] = CLASS_TYPE.REST,
}
local UIWidgetRest = class("UIWidgetRest")

function UIWidgetRest:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bOpen = false
end

function UIWidgetRest:Open()
    if not self.bOpen then
        self.bOpen = true
        self:Init()
    end
end

function UIWidgetRest:OnExit()
    self.bInit = false
    self:UnRegEvent()
    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
    end
end

function UIWidgetRest:OnShow()
end

function UIWidgetRest:BindUIEvent()

    UIHelper.BindUIEvent(self.BtnType03, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelLifeMain)
    end)

    UIHelper.BindUIEvent(self.BtnType04, EventType.OnClick, function()
        JiangHuData.OnClickEntrance()
    end)

    UIHelper.BindUIEvent(self.BtnType05, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelWuLinTongJian)
    end)

    UIHelper.BindUIEvent(self.BtnType06, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelFame)
    end)

    UIHelper.BindUIEvent(self.BtnCatalpaTrip, EventType.OnClick, function()
        if HomelandEventHandler.IsFurnitureCollectLocked() then
            UIMgr.Open(VIEW_ID.PanelHome,4)
        else
            local view = UIMgr.Open(VIEW_ID.PanelFurnitureReward)
		    view:UpdateFurnitureRewardInfo(CollectionData)
        end
    end)

    UIHelper.BindUIEvent(self.ButtonFurniture, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelFurnitureCollectLevelPop)
    end)

    UIHelper.BindUIEvent(self.BtnPageUp, EventType.OnClick, function()
        UIHelper.ScrollToLeft(self.ScrollViewRest)
    end)

    UIHelper.BindUIEvent(self.BtnPageDown, EventType.OnClick, function()
        UIHelper.ScrollToRight(self.ScrollViewRest)
    end)

    UIHelper.BindUIEvent(self.BtnSeasonChallage, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelSeasonChallenge, HONOR_CHALLENGE_PAGE.REST)
    end)
end

function UIWidgetRest:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnTouchViewBackGround, function(scriptView)
        UIMgr.Close(VIEW_ID.PanelFurnitureCollectLevelPop)
    end)
end

function UIWidgetRest:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetRest:Init()
    self:InitData()
    self:UpdateCardList()
    if self.FuncLink then self.FuncLink() end
    self.nTimer = Timer.AddFrameCycle(self, 2, function()
        self:UpdateArrow()
    end)
end





-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIWidgetRest:UpdateCardList()
    UIHelper.RemoveAllChildren(self.ScrollViewRest)
    local tbCardList = self.tbCardList
    local tbHomeCardList = {}
    local tbRestCardList = {}
    local nHomeClass = CLASS_TYPE.HOME
    local nRestClass = CLASS_TYPE.REST
    for nIndex, tbcardInfo in ipairs(tbCardList) do
        if tbcardInfo.nClass2 == CLASS_TYPE.HOME then
            table.insert(tbHomeCardList, tbcardInfo)
        else
            table.insert(tbRestCardList, tbcardInfo)
        end
    end
    UIHelper.AddPrefab(PREFAB_ID.WidgetRoafCardAndSeasonLayout, self.ScrollViewRest, tbHomeCardList, nHomeClass)
    UIHelper.AddPrefab(PREFAB_ID.WidgetRoafCardAndSeasonLayout, self.ScrollViewRest, tbRestCardList, nRestClass)
    Timer.AddFrame(self, 2, function()
        UIHelper.ScrollViewDoLayout(self.ScrollViewRest)
        UIHelper.ScrollToLeft(self.ScrollViewRest)
    end)
end

function UIWidgetRest:GetPageType()
    return 0
end

function UIWidgetRest:InitData()
    self.tbCardList = {}

    for i, v in ipairs(tbType) do
        local tbList = CollectionData.GetInfoList(CLASS_MODE.RELAXATION, v)
        for _, info in ipairs(tbList) do
            table.insert(self.tbCardList, info)
        end
    end
end

function UIWidgetRest:GetIndexByID(nID)
    local tbCardList = self.tbCardList
    for nIndex, tbInfo in ipairs(tbCardList) do
        if tbInfo.dwID == nID then
            return nIndex
        end
    end
    return nil
end

function UIWidgetRest:GetTotalCount()
    local tbCardList = self.tbCardList
    return tbCardList and #tbCardList or 0
end

function UIWidgetRest:LinkToCard(nPageType, nID)
    local func = function()
        if not nID then return end
        local nIndex = self:GetIndexByID(nID)
        local nTotal = self:GetTotalCount()
        if nIndex then
            local nPercent = Lib.SafeDivision(nIndex, nTotal) * 100
            Timer.DelTimer(self, self.nScrollTimerID)
            self.nScrollTimerID = Timer.AddFrame(self, 3, function()
                UIHelper.ScrollToPercent(self.ScrollViewRest, nPercent)
            end)
        end
    end

    if self.bInit then
        func()
    else
        self.FuncLink = func
    end
end

function UIWidgetRest:UpdateArrow()

    local nPercent = UIHelper.GetScrollPercent(self.ScrollViewRest)
    local bShowLeft = nPercent >= 1
    local bShowRight = nPercent <= 99

    local nWidth = UIHelper.GetWidth(self.ScrollViewRest)
    local tbSize = self.ScrollViewRest:getInnerContainerSize()
    UIHelper.SetVisible(self.WidgetArrowLeft, bShowLeft and tbSize.width > nWidth)
    UIHelper.SetVisible(self.WidgetArrowRight, bShowRight and tbSize.width > nWidth)
end

return UIWidgetRest