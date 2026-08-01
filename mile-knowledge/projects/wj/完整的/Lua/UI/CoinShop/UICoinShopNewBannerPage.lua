-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopNewBannerPage
-- Date: 2023-03-22 11:04:45
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopNewBannerPage = class("UICoinShopNewBannerPage")

function UICoinShopNewBannerPage:OnEnter(tData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tData = tData
    self.nCurIndex = -1
    self:UpdateInfo()

    Timer.AddFrameCycle(self, 1, function ()
		self:UpdateCellScale()
	end)
end

function UICoinShopNewBannerPage:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UICoinShopNewBannerPage:BindUIEvent()
    UIHelper.BindUIEvent(self.PageViewBanner, EventType.OnTurningPageView, function ()
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
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function (_, bSelected)
            if bSelected then
                self:TurnTo(i)
            end
        end)
    end
end

function UICoinShopNewBannerPage:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        UIHelper.ScrollViewDoLayout(self.PageViewBanner)
        Timer.AddFrame(self, 1, function()
            if self.nCurIndex then
                UIHelper.SetPageIndex(self.PageViewBanner, self.nCurIndex - 1)
            end
        end)
    end)
end

function UICoinShopNewBannerPage:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UICoinShopNewBannerPage:TurnTo(nIndex)
    nIndex = (nIndex + #self.tScriptList - 1) % #self.tScriptList + 1
    if nIndex ~= self.nCurIndex then
        self.nCurIndex = nIndex
        UIHelper.SetPageIndex(self.PageViewBanner, self.nCurIndex - 1)
        self:OnSwitch()
    end
end

function UICoinShopNewBannerPage:UpdateInfo()
    -- 视频节点
    self.WidgetVideo = UIHelper.AddPrefab(PREFAB_ID.WidgetNewVideo, self._rootNode)

    self.tScriptList = {}
    local tbList = CoinShop_GetNewsList()
    for i, tbInfo in ipairs(tbList) do
        local script = UIHelper.PageViewAddPage(self.PageViewBanner, PREFAB_ID.WidgetNewBannerCell)
        script:OnEnter(tbInfo, i, function(szUrl)
            self:PlayVideo(szUrl)
        end, function()
            self:TurnTo(self.nCurIndex + 1)
        end)
        table.insert(self.tScriptList, script)
    end
    UIHelper.SetTouchEnabled(self.PageViewBanner, false)
    Timer.Add(self, 0.05, function()
        self:TurnTo(1)
    end)

    for i, tog in ipairs(self.tbTogItem) do
        UIHelper.SetVisible(tog, i <= #tbList)
        UIHelper.ToggleGroupAddToggle(self.TogGroupItem, tog)
        UIHelper.SetTouchDownHideTips(tog, false)
    end

    UIHelper.ScrollViewDoLayout(self.PageViewBanner)
    UIHelper.LayoutDoLayout(self.LayoutBannerPage)
end

local ScaleSize = 0.2
function UICoinShopNewBannerPage:UpdateCellScale()
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

function UICoinShopNewBannerPage:OnSwitch()
    Timer.Add(self , 0.2 , function ()
        if self.WidgetVideo then
            self.WidgetVideo:StopVideo()
            UIHelper.RemoveFromParent(self.WidgetVideo._rootNode, true)
            self.WidgetVideo = nil
        end
    end)
    for _, script in ipairs(self.tScriptList) do
        script:OnFocus(self.nCurIndex)
    end
    if UIHelper.GetToggleGroupSelectedIndex(self.TogGroupItem) ~= self.nCurIndex-1 then
        UIHelper.SetToggleGroupSelected(self.TogGroupItem, self.nCurIndex-1)
    end
    LOG.INFO("[UICoinShopNewBannerPage] OnSwitch=%d", self.nCurIndex)
end

function UICoinShopNewBannerPage:PlayVideo(szUrl)
    local script = self.tScriptList[self.nCurIndex]
    if not self.WidgetVideo then
        self.WidgetVideo = UIHelper.AddPrefab(PREFAB_ID.WidgetNewVideo, script.WidgetVideo)
        self.WidgetVideo:OnEnter()
        UIHelper.SetPosition(self.WidgetVideo._rootNode, 0, 0, script.WidgetVideo)
    end
    self.WidgetVideo:PlayVideo(szUrl, function ()
        self:TurnTo(self.nCurIndex+1)
    end)
end

return UICoinShopNewBannerPage