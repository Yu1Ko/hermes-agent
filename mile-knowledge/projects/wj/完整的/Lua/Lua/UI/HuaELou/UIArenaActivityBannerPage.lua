-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaActivityBannerPage
-- Date: 2026-03-17 00:00:00
-- Desc: 竞技群英赛宣传图分页器（参考 UICoinShopNewBannerPage）
-- ---------------------------------------------------------------------------------

local UIArenaActivityBannerPage = class("UIArenaActivityBannerPage")

function UIArenaActivityBannerPage:OnEnter(tData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tData = tData
    self.nCurIndex = -1
    self:UpdateInfo()

    Timer.AddFrameCycle(self, 1, function()
        self:UpdateCellScale()
    end)
end

function UIArenaActivityBannerPage:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIArenaActivityBannerPage:BindUIEvent()
    UIHelper.BindUIEvent(self.PageViewBanner, EventType.OnTurningPageView, function()
        local nCurIndex = UIHelper.GetPageIndex(self.PageViewBanner) + 1
        if nCurIndex ~= self.nCurIndex then
            self.nCurIndex = nCurIndex
            self:OnSwitch()
        end
    end)

    UIHelper.BindUIEvent(self.BtnSwitchLeft, EventType.OnClick, function()
        self:TurnTo(self.nCurIndex - 1)
    end)

    UIHelper.BindUIEvent(self.BtnSwitchRight, EventType.OnClick, function()
        self:TurnTo(self.nCurIndex + 1)
    end)

    for i, tog in ipairs(self.tbTogItem) do
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(_, bSelected)
            if bSelected then
                self:TurnTo(i)
            end
        end)
    end
end

function UIArenaActivityBannerPage:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        UIHelper.ScrollViewDoLayout(self.PageViewBanner)
        Timer.AddFrame(self, 1, function()
            if self.nCurIndex then
                UIHelper.SetPageIndex(self.PageViewBanner, self.nCurIndex - 1)
            end
        end)
    end)
end

function UIArenaActivityBannerPage:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIArenaActivityBannerPage:TurnTo(nIndex)
    nIndex = (nIndex + #self.tScriptList - 1) % #self.tScriptList + 1
    if nIndex ~= self.nCurIndex then
        self.nCurIndex = nIndex
        UIHelper.SetPageIndex(self.PageViewBanner, self.nCurIndex - 1)
        self:OnSwitch()
    end
end

function UIArenaActivityBannerPage:UpdateInfo()
    self.tScriptList = {}
    for i, tRowData in ipairs(self.tData) do
        local script = UIHelper.PageViewAddPage(self.PageViewBanner, PREFAB_ID.WidgetArenaActivityBannerCell)
        script:OnEnter(tRowData, i)
        table.insert(self.tScriptList, script)
    end
    UIHelper.SetTouchEnabled(self.PageViewBanner, false)

    -- 优先跳到第 1 页
    local nDefaultIndex = 1
    -- local nPlayerForceID = PlayerData.GetPlayerForceID()
    -- if nPlayerForceID then
    --     for i, tRowData in ipairs(self.tData) do
    --         if tRowData.nForceID == nPlayerForceID then
    --             nDefaultIndex = i
    --             break
    --         end
    --     end
    -- end
    Timer.AddFrame(self, 2, function()
        self:TurnTo(nDefaultIndex)
    end)

    for i, tog in ipairs(self.tbTogItem) do
        local bVisible = i <= #self.tData
        UIHelper.SetVisible(tog, bVisible)
        if bVisible then
            UIHelper.ToggleGroupAddToggle(self.TogGroupItem, tog)
            UIHelper.SetTouchDownHideTips(tog, false)
        end
    end

    UIHelper.ScrollViewDoLayout(self.PageViewBanner)
    UIHelper.LayoutDoLayout(self.LayoutBannerPage)
end

local ScaleSize = 0.2
function UIArenaActivityBannerPage:UpdateCellScale()
    local sceneSize = UIHelper.GetCurResolutionSize()
    local nCenterX = sceneSize.width / 2
    for i, cell in ipairs(self.tScriptList) do
        local x, y = UIHelper.GetWorldPosition(cell._rootNode)
        local width, height = UIHelper.GetContentSize(cell._rootNode)
        local aX, aY = UIHelper.GetAnchorPoint(cell._rootNode)

        local fRealX = x + width * UIHelper.GetScaleX(cell._rootNode) * (0.5 - aX)
        local fScale = math.abs(nCenterX - fRealX) / nCenterX
        fScale = math.min(1, fScale)
        local nFixX, nFixY = width * fScale * ScaleSize / 2, height * fScale * ScaleSize / 2

        fScale = (1 - fScale * ScaleSize)
        UIHelper.SetScale(cell._rootNode, fScale, fScale)
        UIHelper.SetPosition(cell._rootNode, nFixX, nFixY)
    end
end

function UIArenaActivityBannerPage:OnSwitch()
    if UIHelper.GetToggleGroupSelectedIndex(self.TogGroupItem) ~= self.nCurIndex - 1 then
        UIHelper.SetToggleGroupSelected(self.TogGroupItem, self.nCurIndex - 1)
    end
end

return UIArenaActivityBannerPage
