-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UITeachView
-- Date: 2023-01-04 20:03:09
-- Desc: 教学面板
-- ---------------------------------------------------------------------------------

local UITeachView = class("UITeachView")

local TEACH_SKIP_SHOW_DELAY = 10

local tbCoverView = { VIEW_ID.PanelVideoPlayer }

local function _safe_check(node)
    return node and IsUserData(node) and safe_check(node)
end

function UITeachView:OnEnter(nTeachID)
    self.nTeachID = nTeachID assert(nTeachID)
    self.config = TeachEvent.GetTeachingConfig(nTeachID)

    if self.nodeClick then
        self.nodeClick._nTeachID = nil
        self.nodeClick = nil
    end

    if _safe_check(self.parentScrollView) then
        UIHelper.SetScrollEnabled(self.parentScrollView, true)
        self.parentScrollView = nil
    end

    if self.config then
        self.tbMaskData = self.config.tbMaskData                --遮罩
        self.tbFingerData = self.config.tbFingerData            --手指点击提示
        self.tbTipsData = self.config.tbTipsData                --文字提示
        self.tbEffectData = self.config.tbEffectData            --光圈特效
        self.tbScreenTipsData = self.config.tbScreenTipsData    --横条提示
        self.tbButtonData = self.config.tbButtonData            --跳过按钮偏移
        self.tbShortcutData = self.config.tbShortcutData        --可操作快捷键
        self.tbGamepadData = self.config.tbGamepadData          --可操作手柄键位
        self.tbCoverView = self.config.tbCoverView              --界面覆盖处理
        self.szBindInfoType = self.config.szBindInfoType        --教学界面冲突处理

        self.tbIgnoreShortcutOnDisable = {}                     --允许点击的快捷键
        self.tbIgnoreOnDisable = {}                             --允许点击的单键
        self.tbIgnoreGamepadOnDisable = {}                      --允许点击的手柄组合键

        for _, szName in ipairs(self.tbShortcutData or {}) do
            local tShortcutInfo = ShortcutInteractionData.GetShortcutInfoByDef(szName)
            local szKey = tShortcutInfo and tShortcutInfo.VKey or szName
            local tbKeyCodes, tbKeyNames = ShortcutInteractionData._getKeyInfo(szKey)
            for _, nKeyCode in pairs(tbKeyCodes) do
                if not table.contain_value(self.tbIgnoreOnDisable, nKeyCode) then
                    table.insert(self.tbIgnoreOnDisable, nKeyCode)
                end
            end
            table.insert(self.tbIgnoreShortcutOnDisable, tbKeyNames)
        end

        for _, szName in ipairs(self.tbGamepadData or {}) do
            local tGamepadInfo = ShortcutInteractionData.GetGamepadInfoByDef(szName)
            local szKey = tGamepadInfo and tGamepadInfo.VKey or szName
            if not table.contain_value(self.tbIgnoreGamepadOnDisable, szKey) then
                table.insert(self.tbIgnoreGamepadOnDisable, szKey)
            end
        end
    else
        --print("[Teach] Get Teaching Config Error", tostring(nTeachID))
    end

    self.nUpdateCloseCount = 0
    self.bTeachStart = false
    UIHelper.SetVisible(self.WidgetContainer, false)
    UIHelper.SetVisible(self.WidgetTouchBlock, false)
    UIHelper.SetVisible(self.WidgetTeach, false)

    UIHelper.SetTouchEnabled(self.WidgetTouchBlock, true)
    UIHelper.SetSwallowTouches(self.WidgetTouchBlock, false)
    UIHelper.SetTouchDownHideTips(self.WidgetTouchBlock, false)
    UIHelper.SetMultiTouch(self.WidgetTouchBlock, true) --阻挡多指，防止穿透

    Timer.DelAllTimer(self)
    Timer.AddFrameCycle(self, 1, function()
        self:OnUpdate()
    end)
    if self.config then
        if not self.bInit then
            self:RegEvent()
            self:BindUIEvent()
            self.bInit = true
            TeachEvent.OnTeachViewOpen(self)
        end

        --使教学下一帧才显示
        if not self.bCanUpdateInfo then
            Timer.AddFrame(self, 1, function()
                self.bCanUpdateInfo = true
                self:UpdateInfo()
            end)
        else
            self:UpdateInfo()
        end
    else
        Timer.AddFrameCycle(self, 1, function()
            UIMgr.Close(self)
        end)
    end
end

function UITeachView:OnExit()
    self.bInit = false
    self:UnBindUIEvent()
    self:UnRegEvent()

    TeachEvent.OnTeachViewClose(self)

    if self.nodeClick and self.nTeachID and self.nodeClick._nTeachID == self.nTeachID then
        self.nodeClick._nTeachID = nil
    end

    Event.Dispatch(EventType.SetShortcutEnable, true, {})
    Event.Dispatch(EventType.SetKeyBoardEnable, true, {})
    Event.Dispatch(EventType.SetGamepadEnable, true, {})
    InputHelper.TeachLockMove(false)
    InputHelper.TeachLockCamera(false)

    if _safe_check(self.parentScrollView) then
        UIHelper.SetScrollEnabled(self.parentScrollView, true)
    end
end

function UITeachView:BindUIEvent()
    --self.WidgetTouch上的touchListener用于处理点击事件，并区分不同手指
    --self.WidgetTouchBlock用于阻挡点击事件
    --self.WidgetContainer用于显示遮罩
    if not self.touchListener then
        local function _touchHandler(touch, event)
            local tPos = touch:getLocation()
            local nID = touch:getId()
            local nEvent = event:getEventCode()
            if nEvent == cc.EventCode.BEGAN then
                if self.onTouchBegan then
                    self.onTouchBegan(tPos.x, tPos.y, nID)
                end
            elseif nEvent == cc.EventCode.MOVED then
                if self.onTouchMoved then
                    self.onTouchMoved(tPos.x, tPos.y, nID)
                end
            elseif nEvent == cc.EventCode.ENDED then
                if self.onTouchEnded then
                    self.onTouchEnded(tPos.x, tPos.y, nID)
                end
            elseif nEvent == cc.EventCode.CANCELLED then
                if self.onTouchCancelled then
                    self.onTouchCancelled(tPos.x, tPos.y, nID)
                end
            end
            return true
        end

        assert(self.WidgetTouch)

        local touchListener = cc.EventListenerTouchOneByOne:create()
        touchListener:registerScriptHandler(_touchHandler, cc.Handler.EVENT_TOUCH_BEGAN)
        touchListener:registerScriptHandler(_touchHandler, cc.Handler.EVENT_TOUCH_MOVED)
        touchListener:registerScriptHandler(_touchHandler, cc.Handler.EVENT_TOUCH_ENDED)
        touchListener:registerScriptHandler(_touchHandler, cc.Handler.EVENT_TOUCH_CANCELLED)

        local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
        eventDispatcher:addEventListenerWithSceneGraphPriority(touchListener, self.WidgetTouch)

        self.touchListener = touchListener
    end
end

function UITeachView:RegEvent()
    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if TeachEvent.IsDebugView(nViewID) or TeachEvent.IsTeachView(nViewID) then
            return
        end
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if TeachEvent.IsDebugView(nViewID) or TeachEvent.IsTeachView(nViewID) then
            return
        end
        if self.nodeClick then
            self:UpdateClose()
        end
        if not self.bClosed then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.OnTeachAction, function(nTeachID)
        if nTeachID == self.nTeachID then
            self:UpdateInfo_Debug()
        end
    end)

    --设置了可操作快捷键的情况下，点击了对应的快捷键也算点击屏幕任意区域
    Event.Reg(self, EventType.OnShortcutInteractionSingleKeyDown, function(szKeyName)
        for _, tbKeyNames in pairs(self.tbIgnoreShortcutOnDisable or {}) do
            if #tbKeyNames == 1 and table.contain_value(tbKeyNames, szKeyName) then
                if _safe_check(self.nodeClick) and UIHelper.GetHierarchyVisible(self.nodeClick, true) then
                    Event.Dispatch(EventType.OnTeachNodeClicked)
                end
                Event.Dispatch(EventType.OnTeachAnyClicked)
                break
            end
        end
    end)
    Event.Reg(self, EventType.OnShortcutInteractionMultiKeyDown, function(tbCurKeyNames, nKeybordLen)
        for _, tbKeyNames in pairs(self.tbIgnoreShortcutOnDisable or {}) do
            if #tbKeyNames == nKeybordLen then
                local bMatch = true
                for _, szKeyName in pairs(tbCurKeyNames) do
                    if not table.contain_value(tbKeyNames, szKeyName) then
                        bMatch = false
                        break
                    end
                end
                if bMatch then
                    if _safe_check(self.nodeClick) and UIHelper.GetHierarchyVisible(self.nodeClick, true) then
                        Event.Dispatch(EventType.OnTeachNodeClicked)
                    end
                    Event.Dispatch(EventType.OnTeachAnyClicked)
                    break
                end
            end
        end
    end)
    Event.Reg(self, EventType.OnGamepadKeyExecute, function(szKey)
        if GamepadData.GetCurMoveMode() ~= GamepadMoveMode.Normal then
            return
        end

        if table.contain_value(self.tbIgnoreGamepadOnDisable or {}, szKey) then
            if _safe_check(self.nodeClick) and UIHelper.GetHierarchyVisible(self.nodeClick, true) then
                Event.Dispatch(EventType.OnTeachNodeClicked)
            end
            Event.Dispatch(EventType.OnTeachAnyClicked)
        end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        Timer.AddFrame(self, 1, function()
            if UIHelper.GetVisible(self.WidgetTeach) then
                self:UpdateInfo()
            end
        end)
    end)

    Event.Reg(self, EventType.OnCloseTeachView, function(nTeachID)
        if not nTeachID or nTeachID == self.nTeachID then
            UIMgr.Close(self)
        end
    end)

    Event.Reg(self, EventType.OnHideTeachView, function(nTeachID)
        if not nTeachID or nTeachID == self.nTeachID then
            self.bHideView = true
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.OnShowTeachView, function(nTeachID)
        if not nTeachID or nTeachID == self.nTeachID then
            self.bHideView = false
            self:UpdateInfo()
        end
    end)
end

function UITeachView:UnBindUIEvent()
    if self.touchListener then
        local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
        eventDispatcher:removeEventListener(self.touchListener)
        self.touchListener = nil
    end
end

function UITeachView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeachView:OnUpdate()
    if not _safe_check(self.nodeClick) then
        return
    end

    if UIHelper.GetVisible(self.WidgetTeach) then
        --每帧检测一下目标按钮位置是否有变化，有则刷新
        local nX, nY = self.nodeClick:getPosition()
        local nW, nH = UIHelper.GetScaledContentSize(self.nodeClick)
        local nAnchorX, nAnchorY = UIHelper.GetAnchorPoint(self.nodeClick)
        local nWorldX, nWorldY = UIHelper.ConvertToWorldSpace(UIHelper.GetParent(self.nodeClick), nX, nY)
        nWorldX = nWorldX + (0.5 - nAnchorX) * nW
        nWorldY = nWorldY + (0.5 - nAnchorY) * nH
        if nX ~= self.nX or nY ~= self.nY or nW ~= self.nW or nH ~= self.nH or nWorldX ~= self.nWorldX or nWorldY ~= self.nWorldY then
            self:UpdateInfo()
        end

    end

    --若存在ScrollView且目标按钮位置超出ScrollView范围，则隐藏教学
    local bNodeOutOfBound = false
    if _safe_check(self.parentScrollView) then
        local nXMin, nXMax, nYMin, nYMax = UIHelper.GetNodeEdgeXY(self.nodeClick)
        local nBoundXMin, nBoundXMax, nBoundYMin, nBoundYMax = UIHelper.GetNodeEdgeXY(self.parentScrollView)
        if nXMin > nBoundXMax or nXMax < nBoundXMin or nYMin > nBoundYMax or nYMax < nBoundYMin then
            bNodeOutOfBound = true
        end
    end

    if bNodeOutOfBound ~= (self.bNodeOutOfBound or false) then
        self.bNodeOutOfBound = bNodeOutOfBound
        self:UpdateInfo()
    end
end

function UITeachView:UpdateInfo()
    if not self.config then
        return
    end

    self:UpdateInfo_ScreenTips()
    self:UpdateInfo_Debug()

    Timer.DelTimer(self, self.nTimerID)
    local szClickNodePath = self.config.szClickNodePath
    local clickNode = self.config.clickNode

    if not string.is_nil(szClickNodePath) or clickNode then
        self.nodeClick = clickNode or TeachEvent.GetTeachBindNode(szClickNodePath)
        self:UpdateBindInfo()
        if _safe_check(self.nodeClick) and UIHelper.GetHierarchyVisible(self.nodeClick, true) then
            self.nX, self.nY = self.nodeClick:getPosition()
            self.nW, self.nH = UIHelper.GetScaledContentSize(self.nodeClick)
            local nAnchorX, nAnchorY = UIHelper.GetAnchorPoint(self.nodeClick)
            self.nWorldX, self.nWorldY = UIHelper.ConvertToWorldSpace(UIHelper.GetParent(self.nodeClick), self.nX, self.nY)
            self.nWorldX = self.nWorldX + (0.5 - nAnchorX) * self.nW
            self.nWorldY = self.nWorldY + (0.5 - nAnchorY) * self.nH
        else
            self.nTimerID = Timer.Add(self, 0.2, function()
                self:UpdateInfo()
            end)
            return
        end
    else
        self.nW, self.nH = 0, 0
        local screenSize = UIHelper.GetCurResolutionSize()
        self.nWorldX, self.nWorldY = screenSize.width * 0.5, screenSize.height * 0.5
    end

    self.bTeachStart = true
    self:UpdateInfo_Visble()
    self:UpdateInfo_Mask()
    self:UpdateInfo_Finger()
    self:UpdateInfo_Tips()
    self:UpdateInfo_Effect()
    self:UpdateInfo_Button()

    if self.nodeClick then
        self.nodeClick._nTeachID = self.nTeachID

        --如果锁了操作，则禁用键盘和ScrollView滚动
        local bLockInput = self.tbMaskData and not self.tbMaskData.bEnableClickOther
        if bLockInput and not TeachEvent.bDebugMode then
            --bDebugMode除外
            Event.Dispatch(EventType.SetShortcutEnable, false, self.tbIgnoreShortcutOnDisable)
            Event.Dispatch(EventType.SetKeyBoardEnable, false, self.tbIgnoreOnDisable)
            Event.Dispatch(EventType.SetGamepadEnable, false, self.tbIgnoreGamepadOnDisable)
        end

        local function _setParentScrollDisable(node)
            if not node then
                return
            end

            if node.setScrollEnabled then
                --还原上个
                if _safe_check(self.parentScrollView) then
                    UIHelper.SetScrollEnabled(self.parentScrollView, true)
                end
                self.parentScrollView = node
                if bLockInput then
                    UIHelper.SetScrollEnabled(node, false)
                end
                return
            else
                _setParentScrollDisable(node:getParent())
            end
        end

        _setParentScrollDisable(self.nodeClick)

        --若按钮消失，则关闭教学
        Timer.DelTimer(self, self.nCloseTimerID)
        self.nCloseTimerID = Timer.AddFrameCycle(self, 1, function()
            self:UpdateClose()
        end)
    end
end

function UITeachView:UpdateClose()
    if not _safe_check(self.nodeClick) then
        TeachEvent.TeachClose(self.nTeachID)
        self.bClosed = true
        return
    end

    --控件连续隐藏几帧后关闭教学
    if not UIHelper.GetHierarchyVisible(self.nodeClick, true) then
        self.nUpdateCloseCount = self.nUpdateCloseCount + 1
        if self.nUpdateCloseCount >= 3 then
            TeachEvent.TeachClose(self.nTeachID)
            self.bClosed = true
        end
    else
        self.nUpdateCloseCount = 0
    end
end

function UITeachView:UpdateBindInfo()
    if not self.nodeClick or self.szBindNode then
        return
    end

    --记录当前教学绑定到的节点/界面/层级的信息，当其它教学在同一节点/界面/层级执行时，可配置互斥或关闭等
    self.szBindNode = UIHelper.GetNodePath(self.nodeClick)
    self.szBindLayer, self.szBindPanel = string.match(self.szBindNode, "(UI.+Layer)/(Panel.-)/.+")

    --print("[Teach] UpdateBindInfo", self.szBindLayer, self.szBindPanel, self.szBindNode)

    local szBindInfo = self.szBindInfoType and self[self.szBindInfoType]
    if szBindInfo then
        TeachEvent.CloseTeachByViewBindInfo(self.nTeachID, szBindInfo)
    end
end

function UITeachView:GetBindInfo()
    return self.szBindLayer, self.szBindPanel, self.szBindNode
end

function UITeachView:UpdateInfo_Visble()
    local bVisible = self.bTeachStart or false

    if bVisible and (self.bHideView or self.bNodeOutOfBound) then
        bVisible = false
    end

    if bVisible and self.tbMaskData == nil and self.tbScreenTipsData ~= nil then
        local nPageCount = UIMgr.GetLayerStackLength(UILayer.Page, IGNORE_TEACH_VIEW_IDS)
        local nPopCount = UIMgr.GetLayerStackLength(UILayer.Popup, IGNORE_TEACH_VIEW_IDS)

        if nPageCount > 0 or nPopCount > 0 then
            bVisible = false
        end
    end

    if bVisible then
        for _, nViewID in ipairs(self.tbCoverView or {}) do
            if UIMgr.IsViewOpened(nViewID) then
                bVisible = false
            end
        end
        for _, nViewID in ipairs(tbCoverView or {}) do
            if UIMgr.IsViewOpened(nViewID) then
                bVisible = false
            end
        end
    end

    UIHelper.SetVisible(self.WidgetContainer, bVisible)
    UIHelper.SetVisible(self.WidgetTouchBlock, bVisible)
    UIHelper.SetVisible(self.WidgetTeach, bVisible)
end

-- 遮罩 tbMaskData = {nLayerAlpha = 180, bEnableClickOther = false, }
function UITeachView:UpdateInfo_Mask()
    UIHelper.RemoveAllChildren(self.WidgetContainer)
    if not self.tbMaskData then return end
    if not UIHelper.GetVisible(self.WidgetTeach) then return end

    local nLayerAlpha = self.tbMaskData.nLayerAlpha or 0
    local bEnableClickOther = self.tbMaskData.bEnableClickOther
    local bDrawCycle = self.tbMaskData.bDrawCycle
    local nOffsetX = self.tbMaskData.nOffsetX or 0
    local nOffsetY = self.tbMaskData.nOffsetY or 0

    local nX, nY = self.nWorldX + nOffsetX, self.nWorldY + nOffsetY

    local containsPoint

    -- 挖空的区域，并创建模板
    local stencil = cc.DrawNode:create()
    if bDrawCycle then
        local center = cc.p(nX, nY)
        local radius = self.tbMaskData.nRadius or self.nW/2
        local angle = 360
        local segments = self.tbMaskData.nSegments or 100
        local color = Color.Transparent
        stencil:drawSolidCircle(center, radius, angle, segments, color)

        local radiusSQ = radius * radius
        containsPoint = function(pos)
            return cc.pDistanceSQ(center, pos) <= radiusSQ
        end
    else
        local rectangle = {
            cc.p(nX - self.nW/2, nY - self.nH/2),
            cc.p(nX + self.nW/2, nY - self.nH/2),
            cc.p(nX + self.nW/2, nY + self.nH/2),
            cc.p(nX - self.nW/2, nY + self.nH/2),
        }
        local nCount = 4
        local fillColor = Color.Transparent
        local nBorderWidth = 1
        local borderColor = Color.Transparent
        stencil:drawPolygon(rectangle, nCount, fillColor, nBorderWidth, borderColor)

        local rect = cc.rect(nX - self.nW/2, nY - self.nH/2, self.nW, self.nH)
        containsPoint = function(pos)
            return cc.rectContainsPoint(rect, pos)
        end
    end

    -- 遮挡 考虑了移动端多指的情况，nID为TouchID
    self.onTouchBegan = function(nX, nY, nID)
        if self.nTouchID and self.nTouchID ~= nID then
            if not bEnableClickOther then
                UIHelper.SetSwallowTouches(self.WidgetTouchBlock, true)
            end
            return
        end

        local bSwallow = false
        local pos = cc.p(nX, nY)
        if containsPoint(pos) then
            self.nTouchID = nID
        elseif not bEnableClickOther then
            self.nTouchID = nil
            bSwallow = true
        end
        UIHelper.SetSwallowTouches(self.WidgetTouchBlock, bSwallow)
	end

    self.onTouchMoved = function(nX, nY, nID)
        if not self.nTouchID then
            return
        end

        if self.nTouchID == nID then
            UIHelper.SetSwallowTouches(self.WidgetTouchBlock, false)
        else
            if not bEnableClickOther then
                UIHelper.SetSwallowTouches(self.WidgetTouchBlock, true)
            end
        end
    end

	self.onTouchEnded = function(nX, nY, nID)
        if self.nTouchID then
            if self.nTouchID == nID then
                self.nTouchID = nil
                UIHelper.SetSwallowTouches(self.WidgetTouchBlock, false)
                local pos = cc.p(nX, nY)
                if containsPoint(pos) then
                    Event.Dispatch(EventType.OnTeachNodeClicked)
                end
            else
                if not bEnableClickOther then
                    UIHelper.SetSwallowTouches(self.WidgetTouchBlock, true)
                end
            end
        end

        Event.Dispatch(EventType.OnTeachAnyClicked)
    end

    self.onTouchCancelled = function(nX, nY, nID)
        if not self.nTouchID then
            return
        end

        if self.nTouchID == nID then
            self.nTouchID = nil
            UIHelper.SetSwallowTouches(self.WidgetTouchBlock, false)
        else
            if not bEnableClickOther then
                UIHelper.SetSwallowTouches(self.WidgetTouchBlock, true)
            end
        end
    end

    local layerTouch = cc.LayerColor:create(Color.Transparent)
    layerTouch:setName("LayerTouch")
    self.WidgetContainer:addChild(layerTouch, 10)

    --适配
    local tScreenSize = UIHelper.GetCurResolutionSize()
    local nSizeX, nSizeY = UIHelper.GetContentSize(self._rootNode)
    local nViewPosX, nViewPosY = UIHelper.GetPosition(self._rootNode)

    if Platform.IsMobile() or Channel.Is_WLColud() then
        local nNotchHeight = GetNotchHeight()
        local nHomeIndicatorHeight = GetHomeIndicatorHeight()
        local nScaleX, nScaleY = UIHelper.GetScreenToDeviceScale()
        local nDeltaX = (nNotchHeight > 0) and (nNotchHeight - 30) or nNotchHeight
        local nDeltaY = (nHomeIndicatorHeight > 0) and (nHomeIndicatorHeight - 20) or nHomeIndicatorHeight
        local nX = -tScreenSize.width/2 ---(tScreenSize.width + nDeltaX*nScaleX)/2
        local nY = -(tScreenSize.height + nDeltaY*nScaleY) / 2 -- -tScreenSize.height/2---(tScreenSize.height + nDeltaY*nScaleY) / 2
        UIHelper.SetPosition(layerTouch, nX, nY)
    end

    local clippingNode = cc.ClippingNode:create()
    clippingNode:setInverted(true)
    clippingNode:setStencil(stencil)
    clippingNode:setAlphaThreshold(0)
    clippingNode:setName("ClippingNode")
    clippingNode:setCascadeOpacityEnabled(false)

    local layerColor = cc.LayerColor:create(cc.c4b(0, 0, 0, nLayerAlpha))
    layerColor:setName("LayerColor")
    layerColor:setCascadeOpacityEnabled(false)

    clippingNode:addChild(layerColor, 1)
    layerTouch:addChild(clippingNode, 10)
end

-- 手指 tbFingerData = {nPrefabID = PREFAB_ID.XXX, nAlign = Align.Right_Bottom, nOffsetX = 0, nOffsetY = 0}
function UITeachView:UpdateInfo_Finger()
    self.tbScriptFinger = self.tbScriptFinger or {}
    for _, scriptView in pairs(self.tbScriptFinger) do
        UIHelper.SetVisible(scriptView._rootNode, false)
    end

    if not self.tbFingerData then return end
    if not UIHelper.GetVisible(self.WidgetTeach) then return end

    local nPrefabID = self.tbFingerData.nPrefabID
    local szAnim = self.tbFingerData.szAnim
    local nOffsetX = self.tbFingerData.nOffsetX or 0
    local nOffsetY = self.tbFingerData.nOffsetY or 0
    local szWidgetAniName = self.tbFingerData.szWidgetAniName
    local nAlign = self.tbFingerData.nAlign

    if not self.tbScriptFinger[nPrefabID] then
        self.tbScriptFinger[nPrefabID] = UIHelper.AddPrefab(nPrefabID, self.WidgetTeach)
    end

    local scriptFinger = self.tbScriptFinger[nPrefabID]
    local widgetFinger = scriptFinger._rootNode
    local widgetAni = scriptFinger[szWidgetAniName]

    local nScaleX, nScaleY = 1, 1
    if nAlign == Align.Right_Bottom then
        nScaleX, nScaleY = 1, 1
    elseif nAlign == Align.Right_Top then
        nScaleX, nScaleY = 1, -1
    elseif nAlign == Align.Left_Top then
        nScaleX, nScaleY = -1, -1
    elseif nAlign == Align.Left_Bottom then
        nScaleX, nScaleY = -1, 1
    end

    local nX, nY = UIHelper.ConvertToNodeSpace(self.WidgetTeach, self.nWorldX, self.nWorldY)
    UIHelper.SetPosition(widgetFinger, nX + nOffsetX, nY + nOffsetY)
    UIHelper.SetScale(widgetFinger, nScaleX, nScaleY)
    UIHelper.SetVisible(widgetFinger, true)
    UIHelper.SetVisible(widgetAni, true)

    if not string.is_nil(szAnim) then
        UIHelper.PlayAni(scriptFinger, widgetAni, szAnim)
    end
end

-- Tips tbTipsData = {nAlign = Align.Right_Bottom, nOffsetX = 0, nOffsetY = 0, szContent = ""}
function UITeachView:UpdateInfo_Tips()
    UIHelper.SetVisible(self.WidgetTips, false)
    if not self.tbTipsData then return end
    if not UIHelper.GetVisible(self.WidgetTeach) then return end

    if not self.WidgetTips then
        local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetTeach_Tips, self.WidgetTeach)
        self.ScriptTips = scriptView
        self.WidgetTips = scriptView._rootNode
        self.WidgetTip = scriptView.WidgetTip
        self.RichTextTip = scriptView.RichTextTip
        self.WidgetHint = scriptView.WidgetHint
        self.RichTextHint = scriptView.RichTextHint
        self.tWidgetArrow = scriptView.tWidgetArrow
    end

    local nAlign = self.tbTipsData.nAlign
    local nOffsetX = self.tbTipsData.nOffsetX or 0
    local nOffsetY = self.tbTipsData.nOffsetY or 0
    local szContent = self.tbTipsData.szContent or ""
    local bHideArrow = self.tbTipsData.bHideArrow or false
    local szHint = self.tbTipsData.szHint

    --nAlign为Tips的方位，如若想在左侧显示，则将其锚点置于右侧
    local nAnchorX, nAnchorY = 0.5, 0.5
    local nExtraX, nExtraY = 0, 0
    local nWidgetIndex = 0
    if nAlign == Align.Right_Bottom then
        nAnchorX, nAnchorY = 0, 1
        nExtraX, nExtraY = self.nW/2, -self.nH/2
        nWidgetIndex = 1
    elseif nAlign == Align.Right_Top then
        nAnchorX, nAnchorY = 0, 0
        nExtraX, nExtraY = self.nW/2, self.nH/2
        nWidgetIndex = 4
    elseif nAlign == Align.Left_Top then
        nAnchorX, nAnchorY = 1, 0
        nExtraX, nExtraY = -self.nW/2, self.nH/2
        nWidgetIndex = 3
    elseif nAlign == Align.Left_Bottom then
        nAnchorX, nAnchorY = 1, 1
        nExtraX, nExtraY = -self.nW/2, -self.nH/2
        nWidgetIndex = 2
    elseif nAlign == Align.Left then
        nAnchorX, nAnchorY = 1, 0.5
        nExtraX, nExtraY = -self.nW/2, 0
        nWidgetIndex = 8
    elseif nAlign == Align.Right then
        nAnchorX, nAnchorY = 0, 0.5
        nExtraX, nExtraY = self.nW/2, 0
        nWidgetIndex = 7
    elseif nAlign == Align.Top then
        nAnchorX, nAnchorY = 0.5, 0
        nExtraX, nExtraY = 0, self.nH/2
        nWidgetIndex = 6
    elseif nAlign == Align.Bottom then
        nAnchorX, nAnchorY = 0.5, 1
        nExtraX, nExtraY = 0, -self.nH/2
        nWidgetIndex = 5
    elseif nAlign == Align.Middle then
        nAnchorX, nAnchorY = 0.5, 0.5
        nExtraX, nExtraY = 0, 0
        nWidgetIndex = 0
    end

    UIHelper.SetAnchorPoint(self.WidgetTips, nAnchorX, nAnchorY)

    UIHelper.SetRichText(self.RichTextTip, szContent)

    --获取文字宽度，并考虑多行短文本的情况
    --local nTextWidth = UIHelper.GetUtf8RichTextWidth(szContent, 24)
    local nTextWidth = 0
    local tContentLine = string.split(szContent, "\n")
    for _, szLine in ipairs(tContentLine) do
        local nLineTextWidth = UIHelper.GetUtf8RichTextWidth(szLine, 24)
        if nLineTextWidth > nTextWidth then
            nTextWidth = nLineTextWidth
        end
    end

    local nRichTextWidth = math.max(nTextWidth + 40, 300)
    if nRichTextWidth < UIHelper.GetWidth(self.RichTextTip) then
        UIHelper.SetWidth(self.WidgetTip, nRichTextWidth)
    else
        UIHelper.LayoutDoLayout(self.WidgetTip)
    end

    local nX, nY = UIHelper.ConvertToNodeSpace(self.WidgetTeach, self.nWorldX, self.nWorldY)

    self.nTipsX = nX + nOffsetX + nExtraX
    self.nTipsY = nY + nOffsetY + nExtraY
    self.nTipsWidth, self.nTipsHeight = UIHelper.GetContentSize(self.WidgetTip)

    UIHelper.SetContentSize(self.WidgetTips, self.nTipsWidth, self.nTipsHeight)
    UIHelper.SetPosition(self.WidgetTips, self.nTipsX, self.nTipsY)
    UIHelper.WidgetFoceDoAlign(self.ScriptTips)
    UIHelper.SetVisible(self.WidgetTips, true)

    for nIndex, widgetArrow in ipairs(self.tWidgetArrow) do
        UIHelper.SetVisible(widgetArrow, not bHideArrow and nIndex == nWidgetIndex)
    end

    if not string.is_nil(szHint) then
        UIHelper.SetRichText(self.RichTextHint, UIHelper.AttachTextColor(szHint, FontColorID.Text_Level1))
        UIHelper.LayoutDoLayout(self.WidgetHint)
        UIHelper.SetVisible(self.WidgetHint, true)
    else
        UIHelper.SetVisible(self.WidgetHint, false)
    end
end

-- ScreenTips tbScreenTipsData = {nOffsetX = 0, nOffsetY = 0, szContent = ""}
function UITeachView:UpdateInfo_ScreenTips()
    UIHelper.SetVisible(self.WidgetRichText, false)
    --UIHelper.SetVisible(self.WidgetCloseTips, false)
    if not self.tbScreenTipsData then return end
    if self.bHideView then return end

    if not self.WidgetRichText then
        local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetTeach_RichText, self.WidgetTeach)
        self.ScriptRichText = scriptView
        self.WidgetRichText = scriptView._rootNode
        self.RichText = scriptView.RichText
        self.AniRichText = scriptView.AniRichText
        self.BtnCloseTips = scriptView.BtnClose
        self.WidgetCloseTips = scriptView.WidgetClose
        UIHelper.SetVisible(self.WidgetRichText, false)
        UIHelper.SetVisible(self.WidgetCloseTips, false)
        UIHelper.BindUIEvent(self.BtnCloseTips, EventType.OnClick, function()
            TeachEvent.TeachClose(self.nTeachID)
        end)
    end

    local nOffsetX = self.tbScreenTipsData.nOffsetX or 0
    local nOffsetY = self.tbScreenTipsData.nOffsetY or 0
    local szContent = self.tbScreenTipsData.szContent or ""
    local nTime = TEACH_SKIP_SHOW_DELAY

    if not self.nRichTextPosX or not self.nRichTextPosY then
        self.nRichTextPosX, self.nRichTextPosY = UIHelper.GetPosition(self.WidgetRichText)
    end

    UIHelper.SetPosition(self.WidgetRichText, self.nRichTextPosX + nOffsetX, self.nRichTextPosY + nOffsetY)

    UIHelper.SetRichText(self.RichText, szContent)
    UIHelper.LayoutDoLayout(self.WidgetRichText)

    if TeachEvent.bDebugMode then
        self:ShowCloseTipsBtn()
    else
        self.nCloseTipsBtnTimerID = Timer.Add(self, nTime, function()
            self:ShowCloseTipsBtn()
        end)
    end

    if not self.bShowScreenTips then
        self.bShowScreenTips = true
        UIHelper.PlayAni(self.ScriptRichText, self.AniRichText, "AniRichText")
        Timer.AddFrame(self, 1, function()
            UIHelper.SetVisible(self.WidgetRichText, true)
        end)

        --路引飞行效果
        local tbQuestTrace = self.tbScreenTipsData.tbQuestTrace
        if tbQuestTrace and tbQuestTrace.dwNPCTemplateID then
            local nFlyTime = tbQuestTrace.nFlyTime or 1
            local nOffsetX = tbQuestTrace.nOffsetX or 0
            local nOffsetY = tbQuestTrace.nOffsetY or 0
            local nWorldPosX, nWorldPosY = UIHelper.GetWorldPosition(self.WidgetRichText)
            local tStartPos = {
                nX = nWorldPosX + nOffsetX,
                nY = nWorldPosY + nOffsetY,
            }
            --print("[Teach] QuestTraceFlyTo", tbQuestTrace.dwNPCTemplateID, nFlyTime, tStartPos.nX, tStartPos.nY)
            APIHelper.QuestTraceFlyTo(nFlyTime, tStartPos, tbQuestTrace.dwNPCTemplateID)
        end
    else
        UIHelper.SetVisible(self.WidgetRichText, true)
    end

    self:UpdateInfo_Button()
end

-- Effect tbEffectData = {nPrefabID = PREFAB_ID.XXX, nOffsetX = 0, nOffsetY = 0, nScale = 1}
function UITeachView:UpdateInfo_Effect()
    self.tbScriptEffect = self.tbScriptEffect or {}
    for _, scriptView in pairs(self.tbScriptEffect) do
        UIHelper.SetVisible(scriptView._rootNode, false)
    end

    if not self.tbEffectData then return end
    if not UIHelper.GetVisible(self.WidgetTeach) then return end

    local nPrefabID = self.tbEffectData.nPrefabID
    local nOffsetX = self.tbEffectData.nOffsetX or 0
    local nOffsetY = self.tbEffectData.nOffsetY or 0
    local nScale = self.tbEffectData.nScale
    local szSpriteName = self.tbEffectData.szSpriteName
    local bShowSfx = self.tbEffectData.bShowSfx or false

    if not self.tbScriptEffect[nPrefabID] then
        self.tbScriptEffect[nPrefabID] = UIHelper.AddPrefab(nPrefabID, self.WidgetTeach)
    end

    local scriptEffect = self.tbScriptEffect[nPrefabID]
    local widgetEffect = scriptEffect._rootNode
    local widgetAni = scriptEffect.WidgetAni
    local widgetImg = scriptEffect.WidgetImg
    local widgetSfx = scriptEffect.WidgetSfx

    local nX, nY = UIHelper.ConvertToNodeSpace(self.WidgetTeach, self.nWorldX, self.nWorldY)
    UIHelper.SetPosition(widgetEffect, nX + nOffsetX, nY + nOffsetY)

    if not string.is_nil(szSpriteName) then
        UIHelper.SetSpriteFrame(widgetImg, szSpriteName, false)
    end

    if nScale then
        UIHelper.SetScale(widgetImg, nScale, nScale)
    else
        UIHelper.SetScale(widgetImg, 1, 1)
        if nPrefabID == PREFAB_ID.WidgetTeach_Highlight then
            local nRatio = 1.2
            --圆形
            UIHelper.SetContentSize(widgetImg, self.nW * nRatio, self.nH * nRatio)
        elseif nPrefabID == PREFAB_ID.WidgetTeach_HighlightSquare then
            --方形
            UIHelper.SetContentSize(widgetImg, self.nW + 20, self.nH + 25)
        end
    end

    UIHelper.SetVisible(widgetEffect, true)
    UIHelper.PlayAni(scriptEffect, widgetAni, "AniRing")

    UIHelper.SetVisible(widgetSfx, bShowSfx)
    if bShowSfx then
        if not self.bSfxPlayed then
            self.bSfxPlayed = true
            UIHelper.PlaySFX(widgetSfx)
        end
    else
        self.bSfxPlayed = false
    end
end

-- 跳过按钮 tbButtonData = {nOffsetX = 0, nOffsetY = 0}
function UITeachView:UpdateInfo_Button()
    --UIHelper.SetVisible(self.WidgetClose, false)
    if not self.tbButtonData then return end
    if not UIHelper.GetVisible(self.WidgetTeach) then return end

    if not self.WidgetClose then
        local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetTeach_Close, self.WidgetTeach)
        self.WidgetClose = scriptView._rootNode
        self.BtnClose = scriptView.BtnClose
        UIHelper.SetVisible(self.WidgetClose, false)
        UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
            Event.Dispatch(EventType.OnSkipCurTeach)
        end)
    end

    local nSpace = 15
    local nBtnHeight = UIHelper.GetHeight(self.BtnClose)

    local nOffsetX = self.tbButtonData.nOffsetX or 0
    local nOffsetY = self.tbButtonData.nOffsetY or 0
    local nTime = self.tbButtonData.nTime or TEACH_SKIP_SHOW_DELAY

    if self.tbScreenTipsData then
        local nX, nY = UIHelper.GetPosition(self.WidgetRichText)
        local nRichTextH = UIHelper.GetHeight(self.WidgetRichText)
        UIHelper.SetPosition(self.WidgetClose, nX + nOffsetX, nY + nRichTextH/2 + nSpace + nBtnHeight/2 + nOffsetY)
    elseif self.tbTipsData then
        local nAnchorX, nAnchorY = UIHelper.GetAnchorPoint(self.WidgetTips)
        local nX = self.nTipsX + self.nTipsWidth * (0.5 - nAnchorX)
        local nY = self.nTipsY + self.nTipsHeight * (1 - nAnchorY) + nSpace + nBtnHeight/2
        UIHelper.SetPosition(self.WidgetClose, nX + nOffsetX, nY + nOffsetY)
    end

    if TeachEvent.bDebugMode then
        self:ShowSkipBtn()
    else
        self.nSkipBtnTimerID = Timer.Add(self, nTime, function()
            self:ShowSkipBtn()
        end)
    end
end

function UITeachView:ShowSkipBtn()
    Timer.DelTimer(self, self.nSkipBtnTimerID)
    UIHelper.SetVisible(self.WidgetClose, true)
end

function UITeachView:ShowCloseTipsBtn()
    Timer.DelTimer(self, self.nCloseTipsBtnTimerID)
    UIHelper.SetVisible(self.WidgetCloseTips, true)
end

function UITeachView:UpdateInfo_Debug()
    UIHelper.SetVisible(self.LabelDebug, TeachEvent.bDebugMode)

    if not TeachEvent.bDebugMode then return end
    if not UIHelper.GetVisible(self.WidgetTeach) then return end

    if not self.WidgetDebug then
        local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetTeach_Debug, self.WidgetTeach)
        self.WidgetDebug = scriptView._rootNode
        self.LabelDebug = scriptView.LabelDebug
    end

    local tTeachData = TeachEvent.GetTeachData(self.nTeachID) or {}
    local szAction = TeachEvent.GetTeachingAction(self.nTeachID) or ""
    local szDebugInfo = "当前教学: " .. (tTeachData.szName or "")
    szDebugInfo = szDebugInfo .. "\n" .. "nTeachID: " .. self.nTeachID
    szDebugInfo = szDebugInfo .. "\n" .. "Action: " .. szAction
    UIHelper.SetString(self.LabelDebug, szDebugInfo)
end

return UITeachView