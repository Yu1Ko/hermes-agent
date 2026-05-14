---@class UITouchHelper
UITouchHelper = UITouchHelper or {}
local self = UITouchHelper

-- 模型相关
self._model = nil
self._camera = nil
self._tbFrame = nil
self._bindModelListener = nil

-- UI相关
self._bindUIZoomlListener = nil
self._onUIZoomCallback = nil

-- 编辑
self._bEditMode = false

if Platform.IsMobile() or Channel.Is_WLColud() then
    self.kDragFactorX   = Const.MiniSceneMobileDragFactorX
    self.kZoomFactor    = Const.MiniSceneMobileZoomFactor
else
    self.kDragFactorX   = Const.MiniSceneDragFactorX
    self.kZoomFactor    = Const.MiniSceneZoomFactor
end

self.tbTouchDispatchByPriority =
{
    [VIEW_ID.PanelExteriorMain] = true,
    [VIEW_ID.PanelPetMap] = true,
    [VIEW_ID.PanelSaddleHorse] = true,
    [VIEW_ID.PanelPartnerDetails] = true,
    [VIEW_ID.PanelPartnerAccessory] = true,
    [VIEW_ID.PanelCampMap] = true,
    [VIEW_ID.PanelWorldMap] = true,
    [VIEW_ID.PanelMiddleMap] = true,
    [VIEW_ID.PanelAwardGather] = true,
    [VIEW_ID.PanelRenownRewordList] = true,
    [VIEW_ID.PanelOtherPlayer] = true,
    [VIEW_ID.PanelDungeonInfo] = true,
    [VIEW_ID.PanelHome] = true,
    [VIEW_ID.PanelCollectionDungeon] = true,
    [VIEW_ID.PanelPersonalCardCropping] = true,
    [VIEW_ID.PanelOutfitPreview] = true,
    [VIEW_ID.PanelBenefitBPRewardDetail] = true,
    [VIEW_ID.PanelChangeCloak] = true,
    [VIEW_ID.PanelLifePage] = true,
    [VIEW_ID.PanelToyJingBianTu] = true,
    [VIEW_ID.PanelFaceCoverCropping] = true,
}


--[[
    是否按照优先级派发Touch事件
    TRUE : 按照优先级派发，这样多指就不会被吞掉. by qinghu
    FALSE: 先派发单指事件，再派发多指，单指成功后，多指会被吞掉. by cocos

    做这个的目的是：像商城、宠物等有模型的界面要支持双指缩放，但是由于界面
                   比较复杂，另外UIWidget又不支持多指，原有的事件派发机制
                   会先处理单指，剩下的再多指，这样多指的消息就会被挡在前面
                   的界面给吃掉，因此，设计另外一种模式按照优先级来处理多指
]]
function UITouchHelper.SetTouchDispatchByPriority(nViewID, bFlag)
    if not self.nTouchDispatchCount then
        self.nTouchDispatchCount = 0
    end

    if not self.tbTouchDispatchByPriority[nViewID] then
        return
    end

    if bFlag then
        self.nTouchDispatchCount = self.nTouchDispatchCount + 1
    else
        self.nTouchDispatchCount = self.nTouchDispatchCount - 1
    end

    if self._hasMultiTouch() then
        cc.Director:getInstance():getEventDispatcher():SetTouchDispatchByPriority(self.nTouchDispatchCount > 0)
    end

    if self.nTouchDispatchCount <= 0 then
        self.UnBindModel()
        self.UnBindUIZoom()
    end
end



--- 绑定模型
--- 需要确保对应 ViewID 在 tbTouchDispatchByPriority 中注册了，否则可能无法正常转动
--- @see UITouchHelper#tbTouchDispatchByPriority
function UITouchHelper.BindModel(node, model, camera, tbParam, bIsCoinShopMainView)
    self.UnBindModel()

    if not node then
        return
    end

    if not model then
        return
    end

    self._model = model
    self._camera = camera

    self._tTouching = {}
    self._tTouchEvent = {}
    self._tTouchesMap = {}
    self._nTouchingCount = 0

    -- 解析参数
    self._parseCameraParams(tbParam)

    -- 多指触摸
    if self._hasMultiTouch() then
        self._bindModelListener = cc.EventListenerTouchAllAtOnce:create()
        self._bindModelListener:registerScriptHandler(self._touchesHandler, cc.Handler.EVENT_TOUCHES_BEGAN)
        self._bindModelListener:registerScriptHandler(self._touchesHandler, cc.Handler.EVENT_TOUCHES_MOVED)
        self._bindModelListener:registerScriptHandler(self._touchesHandler, cc.Handler.EVENT_TOUCHES_ENDED)
        self._bindModelListener:registerScriptHandler(self._touchesHandler, cc.Handler.EVENT_TOUCHES_CANCELLED)

        if node.setSwallowTouches then
            node:setSwallowTouches(false)
        end

        local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
        eventDispatcher:addEventListenerWithSceneGraphPriority(self._bindModelListener, node)
    else
        self._bindModelListener = cc.EventListenerTouchOneByOne:create()
        self._bindModelListener:registerScriptHandler(self._touchHandler, cc.Handler.EVENT_TOUCH_BEGAN)
        self._bindModelListener:registerScriptHandler(self._touchHandler, cc.Handler.EVENT_TOUCH_MOVED)
        self._bindModelListener:registerScriptHandler(self._touchHandler, cc.Handler.EVENT_TOUCH_ENDED)
        self._bindModelListener:registerScriptHandler(self._touchHandler, cc.Handler.EVENT_TOUCH_CANCELLED)

        if node.setSwallowTouches then
            node:setSwallowTouches(false)
        end

        local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
        eventDispatcher:addEventListenerWithSceneGraphPriority(self._bindModelListener, node)
    end

    -- PC监听滚轮
    Event.Reg(self, EventType.OnWindowsMouseWheel, function(nDelta, bHandled)
        if bHandled then return end

        self._onZoom(nDelta)
    end)
end

function UITouchHelper.UnBindModel()
    if self._bindModelListener then
        local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
        eventDispatcher:removeEventListener(self._bindModelListener)
        self._bindModelListener = nil
    end

    Event.UnReg(self, EventType.OnWindowsMouseWheel)

    if self._model then
        self._model = nil
    end

    if self._camera then
        self._camera = nil
    end
end

function UITouchHelper.ShowModel(bShow)
    if self._model and self._model.Show then
        self._model:Show(bShow)
    end
end



-- 绑定缩放
function UITouchHelper.BindUIZoom(touchNode, callback)
    self.UnBindUIZoom()

    if not touchNode then
        return
    end

    if not callback then
        return
    end

    --警告，已经绑定过
    if self._onUIZoomCallback or self._bindUIZoomlListener then
        LOG.WARN("[UITouchHelper] UIZoom is Already Bind.")
    end

    self._onUIZoomCallback = callback
    self.bCanZoom = true

    self._tTouching = {}
    self._tTouchEvent = {}
    self._tTouchesMap = {}
    self._nTouchingCount = 0

    -- 多指触摸
    if self._hasMultiTouch() then
        self._bindUIZoomlListener = cc.EventListenerTouchAllAtOnce:create()
        self._bindUIZoomlListener:registerScriptHandler(self._touchesHandler, cc.Handler.EVENT_TOUCHES_BEGAN)
        self._bindUIZoomlListener:registerScriptHandler(self._touchesHandler, cc.Handler.EVENT_TOUCHES_MOVED)
        self._bindUIZoomlListener:registerScriptHandler(self._touchesHandler, cc.Handler.EVENT_TOUCHES_ENDED)
        self._bindUIZoomlListener:registerScriptHandler(self._touchesHandler, cc.Handler.EVENT_TOUCHES_CANCELLED)

        if touchNode.setSwallowTouches then
            touchNode:setSwallowTouches(false)
        end

        local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
        eventDispatcher:addEventListenerWithSceneGraphPriority(self._bindUIZoomlListener, touchNode)
    else
        self._bindUIZoomlListener = cc.EventListenerTouchOneByOne:create()
        self._bindUIZoomlListener:registerScriptHandler(self._touchHandler, cc.Handler.EVENT_TOUCH_BEGAN)
        self._bindUIZoomlListener:registerScriptHandler(self._touchHandler, cc.Handler.EVENT_TOUCH_MOVED)
        self._bindUIZoomlListener:registerScriptHandler(self._touchHandler, cc.Handler.EVENT_TOUCH_ENDED)
        self._bindUIZoomlListener:registerScriptHandler(self._touchHandler, cc.Handler.EVENT_TOUCH_CANCELLED)

        local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
        eventDispatcher:addEventListenerWithSceneGraphPriority(self._bindUIZoomlListener, touchNode)
    end

    -- PC监听滚轮
    Event.Reg(self, EventType.OnWindowsMouseWheel, function(nDelta, bHandled)
        if bHandled then return end

        self._onZoom(nDelta)
    end)
end

function UITouchHelper.UnBindUIZoom()
    if self._bindUIZoomlListener then
        local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
        eventDispatcher:removeEventListener(self._bindUIZoomlListener)
        self._bindUIZoomlListener = nil
    end

    self._onUIZoomCallback = nil

    Event.UnReg(self, EventType.OnWindowsMouseWheel)
end

function UITouchHelper.GetFrames()
    return self._tbFrame
end

function UITouchHelper.GetCamera()
    return self._camera
end

function UITouchHelper.GetScene()
    return self._scene
end

function UITouchHelper.GetModel()
    return self._model
end

function UITouchHelper.EnterEditMode()
    self._bEditMode = true
end

function UITouchHelper.ExitEditMode()
    self._bEditMode = false
end

function UITouchHelper.SetRadiusRange(nMinRadius, nMaxRadius)
    self.nMinRadius = nMinRadius
    self.nMaxRadius = nMaxRadius
end

function UITouchHelper.SetCameraCenterR(nCenterR, nFrameNum)
    if not self._camera then return end
    if not nCenterR then return end
    self._camera:set_center_r(nCenterR, nFrameNum)
end

function UITouchHelper.GetCameraCenterR()
    if not self._camera then return end
    return self._camera:get_center_r()
end

function UITouchHelper.SetYaw(nYaw)
    self.nYaw = nYaw
end







function UITouchHelper._parseCameraParams(tbParam)
    self.nMinRadius = 0
    self.nMaxRadius = 0
    self.bIsExterior = false
    self.nYaw = nil
    self._tbFrame = nil

    if tbParam then
        if tbParam.nMinRadius then
            self.nMinRadius = tbParam.nMinRadius
        end

        if tbParam.nMaxRadius then
            self.nMaxRadius = tbParam.nMaxRadius
        end

        -- 是否是外装显示
        self.bIsExterior = tbParam.bIsExterior

        -- 是否可放大
        if tbParam.bCanZoom == false then
            self.bCanZoom = false
        else
            self.bCanZoom = true
        end

        if tbParam.tbFrame then
            self._tbFrame = tbParam.tbFrame

            if tbParam.tbFrame.tRadius then
                if self.bIsExterior then
                    local nRoleType = g_pClientPlayer and Player_GetRoleType(g_pClientPlayer) or 1
                    local tbRadius = tbParam.tbFrame.tWheelRadius[nRoleType] or tbParam.tbFrame.tRadius[nRoleType]
                    self.nMinRadius = tbRadius[1]
                    self.nMaxRadius = tbRadius[2]
                else
                    self.nMinRadius = tbParam.tbFrame.tRadius[1]
                    self.nMaxRadius = tbParam.tbFrame.tRadius[2]
                end
            end

            self.nYaw = tbParam.tbFrame.fRoleYaw or tbParam.tbFrame.fNpcYaw or tbParam.tbFrame.fRidesYaw
        end
    end
end


function UITouchHelper._touchesHandler(touches, event)
    local nFingers = #touches
    local nEventCode = event:getEventCode()

    if not touches then return end
    self._tTouchEvent = {}

    for i = 1, #touches, 1 do
        local nX = touches[i] and touches[i]:getLocation().x or 0
        local nY = touches[i] and touches[i]:getLocation().y or 0
        local nID = touches[i] and touches[i]:getId() or 0
        local nMouseButton = touches[i] and touches[i]:getMouseButton() or cc.MouseButton.BUTTON_LEFT
        if nEventCode == cc.EventCode.BEGAN then
            if not table.contain_value(self._tTouching, nID) and #self._tTouching < 2 and nMouseButton == cc.MouseButton.BUTTON_LEFT then
                table.insert(self._tTouching, nID)
                table.insert(self._tTouchEvent, i)
                self._tTouchesMap[nID] = {nX = nX, nY = nY}
            end
        elseif nEventCode == cc.EventCode.MOVED then
            if table.contain_value(self._tTouching, nID) then
                table.insert(self._tTouchEvent, i)
                self._tTouchesMap[nID] = {nX = nX, nY = nY}
            end
        elseif nEventCode == cc.EventCode.ENDED or nEventCode == cc.EventCode.CANCELLED then
            local bContain, nIndex = table.contain_value(self._tTouching, nID)
            if bContain then
                table.remove(self._tTouching, nIndex)
                table.insert(self._tTouchEvent, i)
                self._tTouchesMap[nID] = nil
            end
        end
    end
    self._nTouchingCount = #self._tTouching
    self._onTouchEvent(touches, nEventCode)
end

function UITouchHelper._onTouchEvent(touches, nEventCode)
    local nIndex = self._tTouchEvent[1]
    if nIndex then
        local nX = touches[nIndex] and touches[nIndex]:getLocation().x or 0
        local nY = touches[nIndex] and touches[nIndex]:getLocation().y or 0
        if #self._tTouchEvent == 1 then
            if nEventCode == cc.EventCode.BEGAN then
                self._onTouchBegan(nX, nY)
            elseif nEventCode == cc.EventCode.MOVED then
                self._onTouchMoved(nX, nY)
            elseif nEventCode == cc.EventCode.ENDED then
                self._onTouchEnded()
            elseif nEventCode == cc.EventCode.CANCELLED then
                self._onTouchCancelled()
            end
        end
    end

    local nID1, nID2 = self._tTouching[1], self._tTouching[2]
    local tbPos1 = self._tTouchesMap[nID1] or {}
    local tbPos2 = self._tTouchesMap[nID2] or {}
    if nEventCode == cc.EventCode.BEGAN or nEventCode == cc.EventCode.MOVED then
        if tbPos1.nX and tbPos1.nY and tbPos2.nX and tbPos2.nY then
            if nEventCode == cc.EventCode.BEGAN then
                self._onTouchsBegan(tbPos1.nX, tbPos1.nY, tbPos2.nX, tbPos2.nY)
            elseif nEventCode == cc.EventCode.MOVED then
                self._onTouchsMoved(tbPos1.nX, tbPos1.nY, tbPos2.nX, tbPos2.nY)
            end
            self.szLastTouchsEvent = nEventCode
        end
    elseif nEventCode == cc.EventCode.ENDED or nEventCode == cc.EventCode.CANCELLED then
        if #self._tTouching <= 0 and (self.szLastTouchsEvent == cc.EventCode.BEGAN or self.szLastTouchsEvent == cc.EventCode.MOVED) then
            if nEventCode == cc.EventCode.ENDED then
                self._onTouchsEnded()
            elseif nEventCode == cc.EventCode.CANCELLED then
                self._onTouchsCancelled()
            end
            self.szLastTouchsEvent = nEventCode
        end
    end
end


-- ---------------------------------------------------
-- 单指
-- ---------------------------------------------------
function UITouchHelper._onTouchBegan(nX, nY)
    if self._nTouchingCount > 1 then
        return
    end

    self.nLastX = nX
    self.nLastY = nY
end

function UITouchHelper._onTouchMoved(nX, nY)
    if self._nTouchingCount > 1 then
        return
    end

    local size = UIHelper.GetScreenSize()
    local cx, cy = size.width, size.height
    local dx = -(nX - self.nLastX) / cx * math.pi
    local dy = -(nY - self.nLastY) / cy * math.pi
    local nRealDeltaY = math.abs(nY - self.nLastY)

    dx = math.max(dx, -0.35)
    dx = math.min(dx, 0.35)
    dy = math.max(dy, -0.2)
    dy = math.min(dy, 0.2)

    if self._model then
        self.nYaw = self.nYaw or self._model:GetYaw()
        local nSpecialFactor = self._model.IsPendant and 50 or 1
        self._model:SetYaw(self.nYaw + dx * 2 * self.kDragFactorX * nSpecialFactor)
        self.nYaw = self.nYaw + dx * 2 * self.kDragFactorX * nSpecialFactor

        -- 特殊处理转动角色模式时oit表现不正常的问题
        local scene = self._model.m_scene
        if scene then
            scene:OnRotatePlayer(dx * 2 * self.kDragFactorX)
        end
    end

    if self._camera and nRealDeltaY > -0.05 then
        -- self._camera:rotate(dy, 0, -0.05, 0.05)
    end

    self.nLastX = nX
    self.nLastY = nY
end

function UITouchHelper._onTouchEnded(nX, nY)
    if self._nTouchingCount == 1 then
        local nID = next(self._tTouchesMap)
        if nID then
            local pos = self._tTouchesMap[nID]
            self._onTouchBegan(pos.nX, pos.nY)
        end
        return
    end
end

function UITouchHelper._onTouchCancelled(nX, nY)
    if self._nTouchingCount == 1 then
        local nID = next(self._tTouchesMap)
        if nID then
            local pos = self._tTouchesMap[nID]
            self._onTouchBegan(pos.nX, pos.nY)
        end
        return
    end
end



-- ---------------------------------------------------
-- 双指
-- ---------------------------------------------------
function UITouchHelper._onTouchsBegan(nX1, nY1, nX2, nY2)
    self.nLastPinchDist = kmath.len2(nX1, nY1, nX2, nY2)

    if self.bCanZoom then
        if self._camera and self._camera.OnTouchsBegan then
            self._camera:OnTouchsBegan(nX1, nY1, nX2, nY2)
        end
    end
end

function UITouchHelper._onTouchsMoved(nX1, nY1, nX2, nY2)
    local nDist = kmath.len2(nX1, nY1, nX2, nY2)
    local nDelta = nDist - (self.nLastPinchDist or nDist)
    local nZoomDelta = nDelta * 5
    self._onZoom(nZoomDelta)

    if self.bCanZoom then
        if self._camera and self._camera.OnTouchsMoved then
            self._camera:OnTouchsMoved(nX1, nY1, nX2, nY2)
        end
    end

    self.nLastPinchDist = nDist
end

function UITouchHelper._onTouchsEnded(nX1, nY1, nX2, nY2)
    if self.bCanZoom then
        if self._camera and self._camera.OnTouchsEnded then
            self._camera:OnTouchsEnded(nX1, nY1, nX2, nY2)
        end
    end
end

function UITouchHelper._onTouchsCancelled(nX1, nY1, nX2, nY2)
    if self.bCanZoom then
        if self._camera and self._camera.OnTouchsCancelled then
            self._camera:OnTouchsCancelled(nX1, nY1, nX2, nY2)
        end
    end
end



-- ---------------------------------------------------
-- 缩放
-- ---------------------------------------------------
function UITouchHelper._onZoom(nDelta)
    if nDelta == 0 then
        return
    end

    if not self.bCanZoom then
        return
    end

    -- UI缩放
    if IsFunction(self._onUIZoomCallback) then
        self._onUIZoomCallback(nDelta)
        cc.utils:setMouseWheelHandled(true)
    end

    -- 模型镜头缩放
    if self._camera then
        if self._camera.Zoom then
            if (Platform.IsWindows() and not Channel.Is_WLColud()) or Platform.IsMac() or KeyBoard.MobileSupportKeyboard() then
                local nZoomValue = (nDelta > 0) and -30 or 30
                if self._camera:Zoom(nZoomValue * self.kZoomFactor) then
                    cc.utils:setMouseWheelHandled(true)
                    return
                end
            end
        end

        if self.nMinRadius and self.nMinRadius > 0 and
            self.nMaxRadius and self.nMaxRadius > 0 then

            local nZoomValue = (nDelta > 0) and -20 or 20
            self._camera:zoom(nZoomValue * self.kZoomFactor, self.nMinRadius, self.nMaxRadius)

            cc.utils:setMouseWheelHandled(true)
        end
    end
end





function UITouchHelper._hasMultiTouch()
    return Platform.IsMobile() or Channel.Is_WLColud()
end

function UITouchHelper._touchHandler(touch, event)
    local tPos = touch:getLocation()
    local nID = touch:getId()
    local nEvent = event:getEventCode()

    self._nTouchingCount = 1

    if nEvent == cc.EventCode.BEGAN then
        self._onTouchBegan(tPos.x, tPos.y)
    elseif nEvent == cc.EventCode.MOVED then
        self._onTouchMoved(tPos.x, tPos.y)
    elseif nEvent == cc.EventCode.ENDED then
        self._onTouchEnded(tPos.x, tPos.y)
    elseif nEvent == cc.EventCode.CANCELLED then
        self._onTouchCancelled(tPos.x, tPos.y)
    end
    return true
end


