local UIMapZoomConponent = class("UIMapZoomConponent")
local self = UIMapZoomConponent

-- 绑定缩放
--- @param function callback(nDelta, bWheel)
function UIMapZoomConponent:BindUIZoom(touchNode, callback)
    if not touchNode then
        return
    end

    if not callback then
        return
    end
    

    --警告，已经绑定过
    if self._onUIZoomCallback or self._bindUIZoomListener then
        LOG.WARN("[UIMapZoomConponent] UIZoom is Already Bind.")
    end

    self._onUIZoomCallback = callback

    self._tTouching = {}
    self._tTouchEvent = {}
    self._tTouchesMap = {}
    self._nTouchingCount = 0

    local _touchesHandler = function(touches, event)
        self:_touchesHandler(touches, event)
    end

    -- 多指触摸
    self._bindUIZoomListener = cc.EventListenerTouchAllAtOnce:create()
    self._bindUIZoomListener:registerScriptHandler(_touchesHandler, cc.Handler.EVENT_TOUCHES_BEGAN)
    self._bindUIZoomListener:registerScriptHandler(_touchesHandler, cc.Handler.EVENT_TOUCHES_MOVED)
    self._bindUIZoomListener:registerScriptHandler(_touchesHandler, cc.Handler.EVENT_TOUCHES_ENDED)
    self._bindUIZoomListener:registerScriptHandler(_touchesHandler, cc.Handler.EVENT_TOUCHES_CANCELLED)

    if touchNode.setSwallowTouches then
        touchNode:setSwallowTouches(false)
    end

    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(self._bindUIZoomListener, touchNode)

    -- PC监听滚轮
    Event.Reg(self, EventType.OnWindowsMouseWheelForScrollList, function(nDelta, bHandled)
        if bHandled then return end

        self:_onZoom(nDelta, true)
    end)
end

function UIMapZoomConponent:UnBindUIZoom()
    if self._bindUIZoomListener then
        local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
        eventDispatcher:removeEventListener(self._bindUIZoomListener)
        self._bindUIZoomListener = nil
    end

    self._onUIZoomCallback = nil

    Event.UnReg(self, EventType.OnWindowsMouseWheelForScrollList)
end

function UIMapZoomConponent:_touchesHandler(touches, event)
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
    self:_onTouchEvent(touches, nEventCode)
end

function UIMapZoomConponent:_onTouchEvent(touches, nEventCode)
    -- local nIndex = self._tTouchEvent[1]
    -- if nIndex then
    --     local nX = touches[nIndex] and touches[nIndex]:getLocation().x or 0
    --     local nY = touches[nIndex] and touches[nIndex]:getLocation().y or 0
    --     if #self._tTouchEvent == 1 then
    --         if nEventCode == cc.EventCode.BEGAN then
    --             self:_onTouchBegan(nX, nY)
    --         elseif nEventCode == cc.EventCode.MOVED then
    --             self:_onTouchMoved(nX, nY)
    --         elseif nEventCode == cc.EventCode.ENDED then
    --             self:_onTouchEnded()
    --         elseif nEventCode == cc.EventCode.CANCELLED then
    --             self:_onTouchCancelled()
    --         end
    --     end
    -- end

    local nID1, nID2 = self._tTouching[1], self._tTouching[2]
    local tbPos1 = self._tTouchesMap[nID1] or {}
    local tbPos2 = self._tTouchesMap[nID2] or {}
    if nEventCode == cc.EventCode.BEGAN or nEventCode == cc.EventCode.MOVED then
        if tbPos1.nX and tbPos1.nY and tbPos2.nX and tbPos2.nY then
            if nEventCode == cc.EventCode.BEGAN then
                self:_onTouchsBegan(tbPos1.nX, tbPos1.nY, tbPos2.nX, tbPos2.nY)
            elseif nEventCode == cc.EventCode.MOVED then
                self:_onTouchsMoved(tbPos1.nX, tbPos1.nY, tbPos2.nX, tbPos2.nY)
            end
            self.szLastTouchsEvent = nEventCode
        end
    -- elseif nEventCode == cc.EventCode.ENDED or nEventCode == cc.EventCode.CANCELLED then
    --     if #self._tTouching <= 0 and (self.szLastTouchsEvent == cc.EventCode.BEGAN or self.szLastTouchsEvent == cc.EventCode.MOVED) then
    --         if nEventCode == cc.EventCode.ENDED then
    --             self:_onTouchsEnded()
    --         elseif nEventCode == cc.EventCode.CANCELLED then
    --             self:_onTouchsCancelled()
    --         end
    --         self.szLastTouchsEvent = nEventCode
    --     end
    end
end


-- ---------------------------------------------------
-- 单指
-- ---------------------------------------------------
-- function UIMapZoomConponent:_onTouchBegan(nX, nY)
--     if self._nTouchingCount > 1 then
--         return
--     end

--     self.nLastX = nX
--     self.nLastY = nY
-- end

-- function UIMapZoomConponent:_onTouchMoved(nX, nY)
--     if self._nTouchingCount > 1 then
--         return
--     end

--     local size = UIHelper.GetScreenSize()
--     local cx, cy = size.width, size.height
--     local dx = -(nX - self.nLastX) / cx * math.pi
--     local dy = -(nY - self.nLastY) / cy * math.pi
--     local nRealDeltaY = math.abs(nY - self.nLastY)

--     dx = math.max(dx, -0.35)
--     dx = math.min(dx, 0.35)
--     dy = math.max(dy, -0.2)
--     dy = math.min(dy, 0.2)

--     self.nLastX = nX
--     self.nLastY = nY
-- end

-- function UIMapZoomConponent:_onTouchEnded(nX, nY)
--     if self._nTouchingCount == 1 then
--         local nID = next(self._tTouchesMap)
--         if nID then
--             local pos = self._tTouchesMap[nID]
--             self:_onTouchBegan(pos.nX, pos.nY)
--         end
--         return
--     end
-- end

-- function UIMapZoomConponent:_onTouchCancelled(nX, nY)
--     if self._nTouchingCount == 1 then
--         local nID = next(self._tTouchesMap)
--         if nID then
--             local pos = self._tTouchesMap[nID]
--             self:_onTouchBegan(pos.nX, pos.nY)
--         end
--         return
--     end
-- end



-- ---------------------------------------------------
-- 双指
-- ---------------------------------------------------
function UIMapZoomConponent:_onTouchsBegan(nX1, nY1, nX2, nY2)
    self.nLastPinchDist = kmath.len2(nX1, nY1, nX2, nY2)
end

function UIMapZoomConponent:_onTouchsMoved(nX1, nY1, nX2, nY2)
    local nDist = kmath.len2(nX1, nY1, nX2, nY2)
    local nDelta = nDist - (self.nLastPinchDist or nDist)
    local nZoomDelta = nDelta * 5
    self:_onZoom(nZoomDelta, false)

    self.nLastPinchDist = nDist
end

-- function UIMapZoomConponent:_onTouchsEnded(nX1, nY1, nX2, nY2)

-- end

-- function UIMapZoomConponent:_onTouchsCancelled(nX1, nY1, nX2, nY2)

-- end



-- ---------------------------------------------------
-- 缩放
-- ---------------------------------------------------
function UIMapZoomConponent:_onZoom(nDelta, bWheel)
    if nDelta == 0 then
        return
    end
    
    -- UI缩放
    if IsFunction(self._onUIZoomCallback) then
        self._onUIZoomCallback(nDelta, bWheel)
    end
end

return UIMapZoomConponent