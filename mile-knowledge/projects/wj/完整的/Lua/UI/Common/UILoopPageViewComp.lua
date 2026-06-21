-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UILoopPageViewComp
-- Date: 2023-06-25 09:54:36
-- Desc: ?
-- ---------------------------------------------------------------------------------
local ScaleSize = 0.3
local UILoopPageViewComp = class("UILoopPageViewComp")

--nSelectIndex:默认选中第几个Page，1 ~ #tbDataList
function UILoopPageViewComp:OnEnter(nPrefabID, tbDataList, nSelectIndex, bSameSize)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbDataList = tbDataList
    self.nPrefabID = nPrefabID
    self.bSameSize = bSameSize
    self.nFirstItemIndex = 1--第一张page的数据在数组哪个位置
    self.nLastItemIndex = #self.tbDataList --最后一张page的数据在数组哪个位置
    self.nDataListLen = #self.tbDataList
    self.tbTogIndexToPageIndex = {} --下面的点的Index映射到上面页面的Index

    self.nSelectIndex = nSelectIndex <= self.nDataListLen and nSelectIndex or self.nDataListLen

    self:UpdateInfo()
end

function UILoopPageViewComp:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UILoopPageViewComp:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSwitchLeft, EventType.OnClick, function()
        local nSelectIndex = self.nSelectIndex == 1 and self.nDataListLen or self.nSelectIndex - 1
        self.bProhibitUpdate = true
        self.nSelectIndex = nSelectIndex
        UIHelper.SetToggleGroupSelectedToggle(self.TogGroupItem, self.TogItem[self.nSelectIndex])
        self:CheckAddPage()
        UIHelper.ScrollToPage(self.PageViewBanner, self.tbTogIndexToPageIndex[self.nSelectIndex] - 1, 0.5)--从0开始计数
    end)

    UIHelper.BindUIEvent(self.BtnSwitchRight, EventType.OnClick, function()
        local nSelectIndex = self.nSelectIndex == self.nDataListLen and 1 or self.nSelectIndex + 1
        self.bProhibitUpdate = true
        self.nSelectIndex = nSelectIndex
        UIHelper.SetToggleGroupSelectedToggle(self.TogGroupItem, self.TogItem[self.nSelectIndex])
        self:CheckAddPage()
        UIHelper.ScrollToPage(self.PageViewBanner, self.tbTogIndexToPageIndex[self.nSelectIndex] - 1, 0.5)--从0开始计数
    end)

    for nIndex, toggle in ipairs(self.TogItem) do
        UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function(toggle, bSelected)
            if bSelected then
                self.nSelectIndex = nIndex
                self:CheckAddPage()
                UIHelper.ScrollToPage(self.PageViewBanner, self.tbTogIndexToPageIndex[self.nSelectIndex] - 1, 0)--从0开始计数
            end
        end)
    end

    UIHelper.BindUIEvent(self.PageViewBanner, EventType.OnTurningPageView, function()
        UIHelper.SetToggleGroupSelectedToggle(self.TogGroupItem, self.TogItem[self.nSelectIndex])
        self.bProhibitUpdate = false
    end)
end

function UILoopPageViewComp:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UILoopPageViewComp:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UILoopPageViewComp:StartUpdate()
    if not self.nTimer then
        self.nTimer = Timer.AddFrameCycle(self, 1, function()
            self:Update()
        end)
    end
end

function UILoopPageViewComp:Update()

    if not self.bProhibitUpdate then
        local nCurrentPage = UIHelper.GetPageIndex(self.PageViewBanner) + 1
        local nTopIndex = 0
        for key, nPageIndex in pairs(self.tbTogIndexToPageIndex) do
            if nPageIndex == nCurrentPage then
                nTogIndex = key
                break
            end
        end

        self.nSelectIndex = nTogIndex

    end

    if self:CheckAddPage() then
        UIHelper.ScrollToPage(self.PageViewBanner, self.tbTogIndexToPageIndex[self.nSelectIndex] - 1, 0.5)
    end

    self:UpdateCellScale()
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UILoopPageViewComp:UpdateInfo()


    UIHelper.RemoveAllChildren(self.PageViewBanner)

    self.tbCells = {}
    for nIndex, tbData in ipairs(self.tbDataList) do
        local scriptView = UIHelper.PageViewAddPage(self.PageViewBanner, self.nPrefabID, tbData)
        table.insert(self.tbCells, scriptView)
        self.tbTogIndexToPageIndex[nIndex] = nIndex
    end

    UIHelper.ScrollViewDoLayout(self.PageViewBanner)

    for nIndex, toggle in ipairs(self.TogItem) do
        UIHelper.SetVisible(toggle,  nIndex <= self.nDataListLen)
        UIHelper.ToggleGroupAddToggle(self.TogGroupItem, toggle)
    end

    local nCount = #self.tbDataList
    UIHelper.SetVisible(self.BtnSwitchLeft, nCount >= 2)
    UIHelper.SetVisible(self.BtnSwitchRight, nCount >= 2)

    UIHelper.SetVisible(self.LayoutBannerPage, nCount >= 2)
    UIHelper.LayoutDoLayout(self.LayoutBannerPage)

    UIHelper.SetPageIndex(self.PageViewBanner, self.nSelectIndex - 1)
    UIHelper.SetToggleGroupSelectedToggle(self.TogGroupItem, self.TogItem[self.nSelectIndex])

    local nPageViewWidth = UIHelper.GetWidth(self.PageViewBanner)
    local nInnerWidth = self.PageViewBanner:getInnerContainerSize().width
    local nChildWidth = UIHelper.GetWidth(self.PageViewBanner:getCenterItemInCurrentView()) or 0
    self.nChildPercent = nChildWidth / (nInnerWidth - nPageViewWidth)

    if self.nInitTimer then
        Timer.DelTimer(self, self.nInitTimer)
    end
    self.nInitTimer = Timer.AddFrame(self, 1, function()
        UIHelper.SetPageIndex(self.PageViewBanner, self.nSelectIndex - 1)
        UIHelper.SetToggleGroupSelectedToggle(self.TogGroupItem, self.TogItem[self.nSelectIndex])
        self:StartUpdate()
    end)
end


function UILoopPageViewComp:InsertPageToTail()
    local nPerent = self.PageViewBanner:getScrolledPercentHorizontal()
    local tbData = self.tbDataList[self.nFirstItemIndex]

    UIHelper.RemovePageAtIndex(self.PageViewBanner, 0)
    table.remove(self.tbCells, 1)

    local scriptView = UIHelper.InsertPage(self.PageViewBanner, self.nPrefabID, self.nDataListLen - 1, tbData)
    table.insert(self.tbCells, scriptView)

    self.nFirstItemIndex = self.nFirstItemIndex == self.nDataListLen and 1 or self.nFirstItemIndex + 1
    self.nLastItemIndex = self.nLastItemIndex == self.nDataListLen and 1 or self.nLastItemIndex + 1

    for nTogIndex, nPageIndex in pairs(self.tbTogIndexToPageIndex) do
        self.tbTogIndexToPageIndex[nTogIndex] = nPageIndex == 1 and self.nDataListLen or nPageIndex - 1
    end

    --加3好像更顺滑
    self.PageViewBanner:jumpToPercentHorizontal(nPerent - (self.nChildPercent * 100 + 3))
end

function UILoopPageViewComp:InsertPageToHead()
    local nPerent = self.PageViewBanner:getScrolledPercentHorizontal()
    local tbData = self.tbDataList[self.nLastItemIndex]

    UIHelper.RemovePageAtIndex(self.PageViewBanner, self.nDataListLen -1)
    table.remove(self.tbCells, self.nDataListLen)

    local scriptView = UIHelper.InsertPage(self.PageViewBanner, self.nPrefabID, 0, tbData)
    table.insert(self.tbCells, 1, scriptView)

    self.nFirstItemIndex = self.nFirstItemIndex == 1 and self.nDataListLen or self.nFirstItemIndex - 1
    self.nLastItemIndex = self.nLastItemIndex == 1 and self.nDataListLen or self.nLastItemIndex - 1

    for nTogIndex, nPageIndex in pairs(self.tbTogIndexToPageIndex) do
        self.tbTogIndexToPageIndex[nTogIndex] = nPageIndex == self.nDataListLen and 1 or nPageIndex + 1
    end

    --加3好像更顺滑
    self.PageViewBanner:jumpToPercentHorizontal(nPerent + (self.nChildPercent * 100 + 3))
end


function UILoopPageViewComp:CheckAddPage()
    if self.nDataListLen <= 2 then return false end
    if self.nDataListLen == self.tbTogIndexToPageIndex[self.nSelectIndex] then--到最后一页了
        self:InsertPageToTail()
        return true
    elseif self.tbTogIndexToPageIndex[self.nSelectIndex] == 1 then--到第一页了
        self:InsertPageToHead()
        return true
    end
    return false
end


function UILoopPageViewComp:UpdateCellScale()
    if self.bSameSize then return end
	local sceneSize = UIHelper.GetCurResolutionSize()
	local nCenterX = sceneSize.width / 2
	for i, cell in ipairs(self.tbCells) do
		local x, y = UIHelper.GetWorldPosition(cell._rootNode)
		local width, height = UIHelper.GetContentSize(cell._rootNode)
		local aX, aY = UIHelper.GetAnchorPoint(cell._rootNode)

		local fRealX = x + width * (0.5 - aX)
		local fScale = math.abs(nCenterX - fRealX) / nCenterX
		fScale = math.min(1, fScale)
		local nFixX, nFixY = width * fScale * ScaleSize / 2, height * fScale * ScaleSize / 2

		fScale = (1 - fScale * ScaleSize)
		UIHelper.SetScale(cell._rootNode, fScale, fScale)
		UIHelper.SetPosition(cell._rootNode, nFixX, nFixY)
	end
end


return UILoopPageViewComp