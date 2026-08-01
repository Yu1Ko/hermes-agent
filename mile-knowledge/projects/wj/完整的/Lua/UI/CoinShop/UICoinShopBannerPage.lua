-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopBannerPage
-- Date: 2023-03-22 11:04:45
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopBannerPage = class("UICoinShopBannerPage")

function UICoinShopBannerPage:OnEnter(tData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tData = tData
    self.nCurIndex = -1
    self:UpdateInfo()

    -- Timer.AddFrameCycle(self, 1, function ()
	-- 	self:UpdateCellScale()
	-- end)
end

function UICoinShopBannerPage:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UICoinShopBannerPage:BindUIEvent()
    UIHelper.BindUIEvent(self.PageViewBanner, EventType.OnTurningPageView, function ()
        local nCurIndex = UIHelper.GetPageIndex(self.PageViewBanner) + 1
        if nCurIndex ~= self.nCurIndex then
            self.nCurIndex = nCurIndex
            self:UpdateSwitchButton()
        end
    end)

    UIHelper.BindUIEvent(self.BtnSwitchLeft, EventType.OnClick, function()
        self:TurnTo(self.nCurIndex - 1)
    end)

    UIHelper.BindUIEvent(self.BtnSwitchRight, EventType.OnClick, function()
        self:TurnTo(self.nCurIndex + 1)
    end)

    for i, tog in ipairs(self.tbTogItem) do
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function (_, bSelected)
            if bSelected then
                self:TurnTo(i)
            end
        end)
    end
end

function UICoinShopBannerPage:RegEvent()
end

function UICoinShopBannerPage:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UICoinShopBannerPage:TurnTo(nIndex)
    nIndex = (nIndex + #self.tScriptList - 1) % #self.tScriptList + 1
    if nIndex ~= self.nCurIndex then
        self.nCurIndex = nIndex
        UIHelper.SetPageIndex(self.PageViewBanner, self.nCurIndex - 1)
        self:UpdateSwitchButton()
    end
end

function UICoinShopBannerPage:UpdateInfo()
    self.tScriptList = {}
    local nIndex = self.tData
    local nCurDrawCount = On_DrawCardGetCount(g_pClientPlayer, nIndex)
    local tExtraGift = Table_GetPointsDrawPreviewGift(nIndex)
    for _, tGift in ipairs(tExtraGift) do
        local script = UIHelper.PageViewAddPage(self.PageViewBanner, PREFAB_ID.WidgetActivityBanner, tGift)
        script:SetGet(nCurDrawCount >= tGift.nDrawCount)
        table.insert(self.tScriptList, script)
    end
    UIHelper.ScrollViewDoLayout(self.PageViewBanner)
    Timer.Add(self, 0.05, function()
        self:TurnTo(1)
    end)

    for i, tog in ipairs(self.tbTogItem) do
        UIHelper.SetVisible(tog, i <= #tExtraGift)
        UIHelper.ToggleGroupAddToggle(self.TogGroupItem, tog)
        UIHelper.SetTouchDownHideTips(tog, false)
    end
    UIHelper.LayoutDoLayout(self.LayoutBannerPage)
end

local ScaleSize = 0.3
function UICoinShopBannerPage:UpdateCellScale()
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

function UICoinShopBannerPage:UpdateSwitchButton()
    if UIHelper.GetToggleGroupSelectedIndex(self.TogGroupItem) ~= self.nCurIndex-1 then
        UIHelper.SetToggleGroupSelected(self.TogGroupItem, self.nCurIndex-1)
    end
    -- UIHelper.SetVisible(self.BtnSwitchLeft, self.nCurIndex > 1)
    -- UIHelper.SetVisible(self.BtnSwitchRight, self.nCurIndex < #self.tScriptList)
end

return UICoinShopBannerPage