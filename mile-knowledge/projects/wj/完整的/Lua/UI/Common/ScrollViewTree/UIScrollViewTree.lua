-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetScrollViewTree
-- Date: 2023-03-07 10:29:55
-- Desc: ScrollView结构树，规则一：至多展开一项；规则2：栏目展开后，标题栏顶部吸附
-- ---------------------------------------------------------------------------------

---@class UIWidgetScrollViewTree
local UIWidgetScrollViewTree = class("UIWidgetScrollViewTree")

local PERCENT_THRESHOLD = 0.6

--[[

Require Lua Bind:
self.ScrollViewContent
self.WidgetTopContainer

--]]

--UIHelper里提供了快捷用法：UIHelper.SetupScrollViewTree(script, nContainerPrefabID, nItemPrefabID, fnInitContainer, tData, bDelayLoad)
--用法示例见UIPvPCampRewardView:Test()

function UIWidgetScrollViewTree:OnInit(nContainerPrefabID, fnInitContainer, nItemPrefabID)
    self:OnEnter() --有些预制上的ScrollViewTree脚本不知道为啥没勾FirstOnEnter，这里手动调一次
    self.nContainerPrefabID = nContainerPrefabID
    self.fnInitContainer = fnInitContainer --self.fnInitContainer(scriptContainer, tArgs)，可空
    self.nItemPrefabID = nItemPrefabID --可空

    UIHelper.RemoveAllChildren(self.WidgetTopContainer)

    Timer.DelTimer(self, self.nTimerID)
    self.nTimerID = Timer.AddFrameCycle(self, 1, function()
        if not self or not self.OnUpdate then
            Timer.DelAllTimer(self)
            LOG.ERROR("ScrollViewTree Error. nContainerPrefabID = %s, nItemPrefabID = %s", tostring(nContainerPrefabID), tostring(nItemPrefabID))
            return
        end

        self:OnUpdate()
    end)

    if not self.tContainerList then
        self.tContainerList = {}
    end

    self.scriptTopContainer = UIMgr.AddPrefab(nContainerPrefabID, self.WidgetTopContainer)
    UIHelper.SetSwallowTouches(self.scriptTopContainer.ToggleSelect, true)

    --若出现LayoutMask裁剪区域异常，可能是动画之类的问题导致裁剪区域计算不正确，这里延后几帧重新调一下InitLayoutMask即可
    Timer.AddFrame(self, 1, function()
        UIHelper.ScrollViewDoLayoutAndToTop(self.WidgetTopContainer)
        self:InitLayoutMask()
    end)

    self:InitLayoutMask()
    self:SetClippingEnabled(false)
    UIHelper.SetVisible(self.WidgetTopContainer, false)
    UIHelper.SetSwallowTouches(self.WidgetTopContainer, false)

    self:UpdateInfo()
end

function UIWidgetScrollViewTree:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetScrollViewTree:OnExit()
    self.bInit = false
    self:UnRegEvent()

    Timer.DelAllTimer(self.tDelayTimer)

    if self.stencil then
        self.stencil:release()
    end
end

function UIWidgetScrollViewTree:OnUpdate()
    self:OnScrollViewTouchMoved()
end

function UIWidgetScrollViewTree:BindUIEvent()
    UIHelper.BindUIEvent(self.ScrollViewContent, EventType.OnScrollingScrollView, function (_, eventType)
        if self.fnScrollViewMovedCallback then
            self.fnScrollViewMovedCallback(eventType)
        end
	end)
end

function UIWidgetScrollViewTree:RegEvent()
    --NOTE: ScrollViewContent的父节点在第一次InitLayoutMask的时候会变成LayoutMask，
    --如果ScrollViewContent的Widget上的Target为空，这里最小化或窗口大小改变刷新时就会以LayoutMask为目标来DoWidget
    --可能会到导致ScrollView显示异常，只需要在预制中将ScrollViewContent的Widget上的Target设为原先的父节点即可
    Event.Reg(self, EventType.OnWindowsSizeChanged, function(szName)
        Timer.AddFrame(self, 5, function()
            UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewContent, true, true)
            UIHelper.ScrollViewDoLayoutAndToTop(self.WidgetTopContainer)
            --UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
            --if not self.bForbiScrollViewToTop then
            --    UIHelper.ScrollToTop(self.ScrollViewContent, 0)
            --end
            self:InitLayoutMask()
        end)
    end)
end

function UIWidgetScrollViewTree:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-------------------------------- Public --------------------------------

function UIWidgetScrollViewTree:UpdateInfo()
    if not self.tContainerList or not self.nContainerPrefabID then
        return
    end

    self.tDelayTimer = self.tDelayTimer or {}
    Timer.DelAllTimer(self.tDelayTimer)
    UIHelper.RemoveAllChildren(self.ScrollViewContent)
    self.scriptCurContainer = nil   --当前处于选中状态的Container，取消选中后会变为空
    self.lastClickedContainer = nil --上一个点击的Container，不为空，用于显示特效

    for i, tContainerInfo in ipairs(self.tContainerList) do
        local scriptContainer = UIMgr.AddPrefab(self.nContainerPrefabID, self.ScrollViewContent, tContainerInfo.tArgs, tContainerInfo.tItemList, tContainerInfo.bDelayLoad)
        self.tContainerList[i].scriptContainer = scriptContainer
        if not self.lastClickedContainer then
            self.lastClickedContainer = scriptContainer
        end
        if self.fnInitContainer then
            self.fnInitContainer(scriptContainer, tContainerInfo.tArgs)
        end
        local nIndex = i
        scriptContainer:SetBeforeSelectedCallBack(function(bSelected)
            if bSelected then
                self.nCurScriptContainerLastPosY = UIHelper.GetWorldPositionY(scriptContainer.ToggleSelect)
            end
        end)
        scriptContainer:SetSelectedCallBack(function(bSelected)
            self:OnContainerSelected(nIndex, bSelected)

            local fnSelectedCallback = self.tContainerList[nIndex].fnSelectedCallback
            if fnSelectedCallback then
                fnSelectedCallback(bSelected, scriptContainer)
            end

            self:UpdateContainerEffect()
            self:OnScrollViewTouchMoved()
        end)
        scriptContainer:SetOnClickCallBack(function(bSelected)
            local fnOnClickCallBack = self.tContainerList[nIndex].fnOnClickCallBack
            if fnOnClickCallBack then
                fnOnClickCallBack(bSelected, scriptContainer)
            end
        end)
        if self.bOuterInitSelect ~= true then
            Timer.AddFrame(self.tDelayTimer, 1, function()
                scriptContainer:SetSelected(nIndex == 1)
            end)
        end
    end
    self:UpdateContainerEffect()
    Timer.AddFrame(self.tDelayTimer, 1, function()
        UIHelper.ScrollViewDoLayout(self.ScrollViewContent)

        if self.bForbiScrollViewToTop then return end
        UIHelper.ScrollToTop(self.ScrollViewContent, 0)
    end)
end

--[[

@ tArgs: 自定义参数，在初始化Container调用fnInitContainer时传入
@ tItemList = {
    { nPrefabID = XXX, tArgs = {...} },
    { nPrefabID = XXX, tArgs = {...} },
    { nPrefabID = XXX, tArgs = {...} },
    ...
}
若tItemList为空，则表示无次级导航

--]]
function UIWidgetScrollViewTree:AddContainer(tArgs, tItemList, fnSelectedCallback, fnOnClickCallBack, bDelayLoad)
    if not self.tContainerList then
        self.tContainerList = {}
    end

    tArgs = tArgs or {}

    if tItemList then
        for i, v in ipairs(tItemList) do
            v.nPrefabID = v.nPrefabID or self.nItemPrefabID
        end
    end

    local tContainerInfo = {
        tArgs = tArgs,
        tItemList = tItemList,
        fnSelectedCallback = fnSelectedCallback,
        fnOnClickCallBack = fnOnClickCallBack,
        bDelayLoad = bDelayLoad,
    }
    table.insert(self.tContainerList, tContainerInfo)
end

function UIWidgetScrollViewTree:AddItemToContainer(nContainerIndex, nItemPrefabID, tArgs)
    local tContainerInfo = self.tContainerList and self.tContainerList[nContainerIndex]
    if tContainerInfo then
        tContainerInfo.tItemList = tContainerInfo.tItemList or {}
        table.insert(tContainerInfo.tItemList, {
            nPrefabID = nItemPrefabID,
            tArgs = tArgs
        })
    end
end

function UIWidgetScrollViewTree:SetContainerCallback(nContainerIndex, fnSelectedCallback, fnOnClickCallBack)
    local tContainerInfo = self.tContainerList and self.tContainerList[nContainerIndex]
    if tContainerInfo then
        tContainerInfo.fnSelectedCallback = fnSelectedCallback --fnSelectedCallback(bSelected, scriptContainer)
        tContainerInfo.fnOnClickCallBack = fnOnClickCallBack --fnOnClickCallBack(bSelected, scriptContainer)
    end
end


function UIWidgetScrollViewTree:SetContainerSelected(nContainerIndex, bSelected, bIgnoreCallback)
    if bSelected == nil then
        bSelected = true
    end

    local tContainerInfo = self.tContainerList and self.tContainerList[nContainerIndex]
    if tContainerInfo and tContainerInfo.scriptContainer then
        tContainerInfo.scriptContainer:SetSelected(bSelected, bIgnoreCallback)

        if bIgnoreCallback then
            self:OnContainerSelected(nContainerIndex, bSelected, bIgnoreCallback)
            self:UpdateContainerEffect()
            self:OnScrollViewTouchMoved()
        end
    end
end

function UIWidgetScrollViewTree:ClearContainer()
    self.tContainerList = {}
    self.scriptCurContainer = nil
    self.lastClickedContainer = nil
end

----------------------------------------------------------------

function UIWidgetScrollViewTree:OnScrollViewTouchMoved()
    if not self.scriptCurContainer or not self.scriptCurContainer.tItemList then
        self:SetClippingEnabled(false)
        UIHelper.SetVisible(self.WidgetTopContainer, false)
        return
    end

    local nTopY = UIHelper.GetWorldPositionY(self.scriptTopContainer.ToggleSelect)
    local nSelectY = UIHelper.GetWorldPositionY(self.scriptCurContainer.ToggleSelect)
    local bAutoToping = UIHelper.GetVisible(self.WidgetTopContainer)

    if bAutoToping and nTopY >= nSelectY + 0.01 then
        self:SetClippingEnabled(false)
        UIHelper.SetVisible(self.WidgetTopContainer, false)
        --UIHelper.SetVisible(self.scriptCurContainer.ToggleSelect, true)
    end

    if not bAutoToping and nTopY < nSelectY + 0.01 then
        self:SetClippingEnabled(true)
        UIHelper.SetVisible(self.WidgetTopContainer, true)
        --UIHelper.SetVisible(self.scriptCurContainer.ToggleSelect, false)

        self.scriptTopContainer:SetSelectedCallBack()
        self.scriptTopContainer:SetSelected(true)
        self.scriptTopContainer:SetSelectedCallBack(function(bSelected)
            self:SetClippingEnabled(false)
            UIHelper.SetVisible(self.WidgetTopContainer, false)
            --UIHelper.SetVisible(self.scriptCurContainer.ToggleSelect, true)
            self.scriptCurContainer:CallOnClickCallBack(false)
            self.scriptCurContainer:SetSelected(false)
        end)
    end
end

function UIWidgetScrollViewTree:OnContainerSelected(nContainerIndex, bSelected, bIgnoreCallback)
    local tContainerInfo = self.tContainerList and self.tContainerList[nContainerIndex]
    local scriptContainer = tContainerInfo and tContainerInfo.scriptContainer

    if not scriptContainer then
        return
    end

    if bSelected then
        if self.scriptCurContainer and self.scriptCurContainer ~= scriptContainer then
            --复原上个Container的状态
            Timer.DelTimer(self, self.nSetCanSelectTimerID)
            self.scriptCurContainer:SetCanSelect(true)
            self.scriptCurContainer:SetSelected(false, bIgnoreCallback)
        end

        self.scriptCurContainer = scriptContainer
        self.lastClickedContainer = scriptContainer

        if self.fnInitContainer then
            self.fnInitContainer(self.scriptTopContainer, self.scriptCurContainer.tArgs, bSelected)
        end

        if not tContainerInfo.tItemList then
            self.nSetCanSelectTimerID = Timer.AddFrame(self, 1, function()
                scriptContainer:SetCanSelect(false)
            end)
        end
    elseif self.scriptCurContainer == scriptContainer then
        self.scriptCurContainer = nil
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
    UIHelper.ScrollToTop(self.ScrollViewContent, 0)

    if self.scriptCurContainer then
        local _, nSizeY = UIHelper.GetContentSize(self.ScrollViewContent)
        local _, nInnerSizeY = UIHelper.GetInnerContainerSize(self.ScrollViewContent)
        if nInnerSizeY >= nSizeY then
            local nPosY = UIHelper.GetWorldPositionY(self.scriptCurContainer.ToggleSelect)
            local nTitleY = UIHelper.GetWorldPositionY(self.scriptTopContainer.ToggleSelect)
            local nScrolledX, nScrolledY = UIHelper.GetScrolledPosition(self.ScrollViewContent)

            local nPercent = (nPosY - (nTitleY - nSizeY)) / nSizeY
            local nLastPercent = (self.nCurScriptContainerLastPosY - (nTitleY - nSizeY)) / nSizeY

            --若当前标题栏位置太低（处于ScrollView的下半部分）或标题栏原位置太高，则将当前标题栏与顶部边缘对齐，否则则移动到原位置
            local bTop = nPercent < (1 - PERCENT_THRESHOLD) or nLastPercent > 1 + 0.01
            local nTargetPosY = bTop and nTitleY or self.nCurScriptContainerLastPosY
            local nTargetScrolledY = nScrolledY + (nTargetPosY - nPosY)

            --Clamp
            if nTargetScrolledY >= nSizeY - nInnerSizeY - 0.01 and nTargetScrolledY <= 0.01 then
                UIHelper.SetScrolledPosition(self.ScrollViewContent, nScrolledX, nTargetScrolledY)
            elseif nTargetScrolledY > 0.01 then
                UIHelper.ScrollToBottom(self.ScrollViewContent, 0)
            else
                UIHelper.ScrollToTop(self.ScrollViewContent, 0)
            end
        end
    end
end

function UIWidgetScrollViewTree:UpdateContainerEffect()
    for _, tContainerInfo in ipairs(self.tContainerList) do
        local bShowEffect = (not tContainerInfo.tItemList or self.scriptCurContainer == nil) and tContainerInfo.scriptContainer == self.lastClickedContainer
        tContainerInfo.scriptContainer:SetEffectVisible(bShowEffect)
    end
end

--若标题栏是透明的，这里会裁剪掉下面内容穿透于标题栏的部分
function UIWidgetScrollViewTree:InitLayoutMask()
    if not self.scriptTopContainer then
        return
    end

    local nAnchX, nAnchY = UIHelper.GetAnchorPoint(self.ScrollViewContent)
    local nWidth, nHeight = UIHelper.GetContentSize(self.ScrollViewContent)
    local nPosX, nPosY = UIHelper.GetWorldPosition(self.ScrollViewContent)

    local _, nTitleAnchY = UIHelper.GetAnchorPoint(self.scriptTopContainer.ToggleSelect)
    local nTitleHeight = UIHelper.GetHeight(self.scriptTopContainer.ToggleSelect)
    local nTitlePosY = UIHelper.GetWorldPositionY(self.scriptTopContainer.ToggleSelect)

    --计算出ScrollView的顶部位置和标题栏的底部位置
    local nScrollViewTop = nPosY + nHeight * (1 - nAnchY)
    local nTitleBottom = nTitlePosY - nTitleHeight * nTitleAnchY

    --相减得到需要裁剪的部分
    local nClipDelta = self.nClipDelta or nTitleBottom - nScrollViewTop

    if self.layoutMask then
        UIHelper.SetAnchorPoint(self.layoutMask, nAnchX, nAnchY)
        UIHelper.SetContentSize(self.layoutMask, nWidth, nHeight + nClipDelta)
        UIHelper.SetWorldPosition(self.layoutMask, nPosX, nPosY + nClipDelta * nAnchY)
        UIHelper.SetWorldPosition(self.ScrollViewContent, nPosX, nPosY)
        return
    end

    local layout = ccui.Layout:create()
    layout:setName("LayoutMask")
    layout:setCascadeOpacityEnabled(true)

    local parent = UIHelper.GetParent(self.ScrollViewContent)
    UIHelper.SetParent(layout, parent)
    UIHelper.SetAnchorPoint(layout, nAnchX, nAnchY)
    UIHelper.SetContentSize(layout, nWidth, nHeight - nClipDelta)
    UIHelper.SetWorldPosition(layout, nPosX, nPosY - nClipDelta * nAnchY)

    UIHelper.SetParent(self.ScrollViewContent, layout) --重设ScrollView的Parent会重刷下面东西的状态
    UIHelper.SetWorldPosition(self.ScrollViewContent, nPosX, nPosY)
    UIHelper.SetLocalZOrder(layout, -1)

    self.layoutMask = layout
end

--启用/禁用裁剪
function UIWidgetScrollViewTree:SetClippingEnabled(bEnabled)
    if self.layoutMask then
        self.layoutMask:setClippingEnabled(bEnabled)
    end
end

function UIWidgetScrollViewTree:ForbiOnUpdateScrollToTop(bForbiScrollViewToTop)
    self.bForbiScrollViewToTop = bForbiScrollViewToTop
end

function UIWidgetScrollViewTree:SetOuterInitSelect()
    self.bOuterInitSelect = true
end

function UIWidgetScrollViewTree:SetScrollViewMovedCallback(callback)
    self.fnScrollViewMovedCallback = callback
end

return UIWidgetScrollViewTree