HomelandInput = HomelandInput or {className = "HomelandInput"}
local self = HomelandInput



local nDragFactor = Platform.IsMobile() and 1.95 or 3.5  --家园建造模式下的镜头左右旋转和上下翻转速度（移动端 0r PC端）
local nS2R_X, nS2R_Y = UIHelper.GetScreenToDesignScale()
local tbIngoreMouseWheelPage = {
    VIEW_ID.PanelPlacedItemsList
}
Event.Reg(self, EventType.OnWindowsSizeChanged, function()
    nS2R_X, nS2R_Y = UIHelper.GetScreenToDesignScale()
end)



function HomelandInput.Bind(drawNodeParent)
    self.UnBind()

    self.bEnable = true
    self.nLastPinchDist = 0
    self.drawNodeParent = drawNodeParent
    self.nInputType = HomelandBuildData.GetInputType()

    self.bRDown = false

    -- 键盘
    Event.Reg(self, EventType.OnKeyboardDown, function(nKeyCode, szKeyName)
        if nKeyCode == cc.KeyCode.KEY_E then
            self.StartCameraOffset(1)
        elseif nKeyCode == cc.KeyCode.KEY_Q then
            self.StartCameraOffset(-1)
        elseif nKeyCode == cc.KeyCode.MButton then
            self.StartMButtonDrag()
        end
    end)

    Event.Reg(self, EventType.OnKeyboardUp, function(nKeyCode, szKeyName)
        if nKeyCode == cc.KeyCode.KEY_E then
            self.StopCameraOffset()
        elseif nKeyCode == cc.KeyCode.KEY_Q then
            self.StopCameraOffset()
        elseif nKeyCode == cc.KeyCode.MButton then
            self.StopMButtonDrag()
        end
    end)

    -- 鼠标滚轮
    Event.Reg(self, EventType.OnWindowsMouseWheel, function(nDelta, bHandled)
        if nDelta == 0 then return end
        if bHandled then return end
        if UIMgr.GetView(VIEW_ID.PanelPlacedItemsList) then
            return
        end
        HLBOp_Camera.OnMouseWheel(nDelta)
        HLBOp_Other.ResetCameraMode()
    end)

    -- 单指
    Event.Reg(self, EventType.OnSceneTouchBegan, function(nX1, nY1)
        if not self.bEnable then
            return
        end

        self.bLDown = SceneMgr.GetMouseButton(cc.MouseButton.BUTTON_LEFT)
        self.bRDown = SceneMgr.GetMouseButton(cc.MouseButton.BUTTON_RIGHT)
        self.nLastX = nX1
        self.nLastY = nY1
        self.bRotateYaw = nil

        local tConfig = Homeland_GetModeConfig(HLBOp_Main.GetBuildMode())
        if tConfig.bDesign then
            local nSceneID = HLBOp_Enter.GetSceneID()
            self.nBeginDragX, self.nBeginDragY = Camera_BeginDrag(1, 2)
        end
        HLBOp_Camera.SetDragFlag(5, false)

        if self.nInputType == HLB_INPUT_TYPE.MAK and self.bLDown then
            return
        end

        self.MultiChooseDrawBegan(nX1, nY1)
    end)

    Event.Reg(self, EventType.OnSceneTouchMoved, function(nX1, nY1)
        HLBOp_Camera.SetDragFlag(5, false)

        if not self.bEnable then
            return
        end

        if not self.nLastX or not self.nLastY then
            return
        end

        local nDeltaX, nDeltaY = nX1 - self.nLastX, nY1 - self.nLastY

        self.bLDown = SceneMgr.GetMouseButton(cc.MouseButton.BUTTON_LEFT)
        self.bRDown = SceneMgr.GetMouseButton(cc.MouseButton.BUTTON_RIGHT)

        -- VK-PC 多选相关
        if self.nInputType == HLB_INPUT_TYPE.MAK and self.bLDown then
            if HLBOp_Place.IsMoveObj() or HLBOp_MultiItemOp.IsMoveObj() or HLBOp_Blueprint.IsMoveBlueprint() then
                return
            end
            if nDeltaX ~= 0 or nDeltaY ~= 0 then
                if not self.bMultiChooseMode then
                    Event.Dispatch("LUA_HOMELAND_ENTER_MULTI_CHOOSE_MODE")
                    self.EnterMultiChooseMode() -- 在拖动时才进入多选模式，避免单选失败
                end

                if not self.bOnMultiChoose then -- bOnMultiChoose代表是否已经记录过拖拽起始点
                    self.MultiChooseDrawBegan(self.nLastX, self.nLastY)
                end

                if self.bMultiChooseMode and self.bOnMultiChoose then
                    self.MultiChooseDrawUpdate(nX1, nY1)
                end
            end
            return
        end

        self.MultiChooseDrawUpdate(nX1, nY1)

        if not self.bMultiChooseMode or (self.bMultiChooseMode and self.bRDown) then
            if self.bRotateYaw ~= nil and math.abs(math.abs(nDeltaX) - math.abs(nDeltaY)) > 5 then
                self.bRotateYaw = nil
            end

            if not HLBOp_Camera.GetCameraLock() and (math.abs(nDeltaX) > 0 or math.abs(nDeltaY) > 0) then
                if self.bRotateYaw or (self.bRotateYaw == nil and math.abs(nDeltaX) > math.abs(nDeltaY)) then
                    HLBOp_Camera.OnCameraRotateYaw(nDeltaX * nDragFactor * nS2R_X)
                    self.bRotateYaw = true
                    HLBOp_Camera.SetDragFlag(5, true)
                else
                    HLBOp_Camera.OnCameraRotatePitch(nDeltaY * nDragFactor * nS2R_Y)
                    self.bRotateYaw = false
                    HLBOp_Camera.SetDragFlag(5, true)
                end
            end

            HLBOp_Other.ResetCameraMode()
        end

        self.nLastX = nX1
        self.nLastY = nY1
    end)

    Event.Reg(self, EventType.OnSceneTouchEnded, function(nX1, nY1)
        if not self.bEnable then
            return
        end

        if self.nInputType == HLB_INPUT_TYPE.MAK then
            if self.bMultiChooseMode and self.bOnMultiChoose then
                self.MultiChooseDrawEnd(nX1, nY1)
            end
            self.ExitMultiChooseMode()
            return
        end

        self.MultiChooseDrawEnd(nX1, nY1)
        self.bRotateYaw = nil
        local tConfig = Homeland_GetModeConfig(HLBOp_Main.GetBuildMode())
        if tConfig.bDesign then
            if self.nBeginDragX and self.nBeginDragY then
                Camera_EndDrag(self.nBeginDragX, self.nBeginDragY, 2)
            end
        end

        HLBOp_Camera.SetDragFlag(5, false)
    end)

    Event.Reg(self, EventType.OnSceneTouchCancelled, function(nX1, nY1)
        if not self.bEnable then
            return
        end

        if self.nInputType == HLB_INPUT_TYPE.MAK then
            if self.bOnMultiChoose then
                self.MultiChooseDrawEnd(nX1, nY1)
            end
            self.ExitMultiChooseMode()
            return
        end

        self.MultiChooseDrawEnd(nX1, nY1)

        local tConfig = Homeland_GetModeConfig(HLBOp_Main.GetBuildMode())
        if tConfig.bDesign then
            if self.nBeginDragX and self.nBeginDragY then
                Camera_EndDrag(self.nBeginDragX, self.nBeginDragY, 2)
            end
        end

        HLBOp_Camera.SetDragFlag(5, false)
    end)

    Event.Reg(self, EventType.OnSceneTouchsBegan, function(nX1, nY1, nX2, nY2)
        if not self.bEnable then
            return
        end

        self.nLastPinchDist = kmath.len2(nX1, nY1, nX2, nY2)
    end)

    Event.Reg(self, EventType.OnSceneTouchsMoved, function(nX1, nY1, nX2, nY2)
        if not self.bEnable then
            return
        end

        local nDist = kmath.len2(nX1, nY1, nX2, nY2)
        local nDelta = nDist - self.nLastPinchDist
        if math.abs(nDelta) <= 10 then
            return
        end


        HLBOp_Camera.OnMouseWheel(nDelta)
        HLBOp_Other.ResetCameraMode()

        self.nLastPinchDist = nDist
    end)
end

function HomelandInput.UnBind()
    Event.UnReg(self, EventType.OnHotkeyCameraZoom)
    Event.UnReg(self, EventType.OnSceneTouchBegan)
    Event.UnReg(self, EventType.OnSceneTouchMoved)
    Event.UnReg(self, EventType.OnSceneTouchEnded)
    Event.UnReg(self, EventType.OnSceneTouchCancelled)

    self.ExitMultiChooseMode()
end


function HomelandInput.StartCameraOffset(nDelta)
    self.StopCameraOffset()

    if not nDelta then
        return
    end

    self.nCameraOffsetTimerID = Timer.AddFrameCycle(self, 1, function()
        HLBOp_Camera.OnCameraOffset(nDelta)
    end)
end

function HomelandInput.StopCameraOffset()
    Timer.DelTimer(self, self.nCameraOffsetTimerID)
end

function HomelandInput.StartMButtonDrag()
    HLBOp_Camera.OnMButtonDrag()
end

function HomelandInput.StopMButtonDrag()
    HLBOp_Camera.OnMButtonUp()
end

function HomelandInput.EnterMultiChooseMode()
    if self.bMultiChooseMode then
        return
    end

    self.bMultiChooseMode = true
end

function HomelandInput.ExitMultiChooseMode()
    if not self.bMultiChooseMode then
        return
    end

    self.bMultiChooseMode = false
end

function HomelandInput.IsMultiChooseMode()
    return self.bMultiChooseMode
end

function HomelandInput.MultiChooseDrawBegan(nX1, nY1)
    if HLBOp_Blueprint.IsMoveBlueprint() then
        return  -- 移动蓝图中，不能触发多选
    end

    if not self.bMultiChooseMode and self.nInputType ~= HLB_INPUT_TYPE.MAK then
        return
    end

    HLBOp_MultiItemOp.ConfirmPlace()    -- 点击除BtnMove外的区域都默认确定应用
    if self.bRDown then
        return
    end

    self.nDrawBeganX, self.nDrawBeganY = nX1, nY1
    self.nMultiBeganX, self.nMultiBeganY = Homeland_GetTouchingPosInPixels()
    self.bOnMultiChoose = true    -- 用于判断是否在进行多选操作
end

function HomelandInput.MultiChooseDrawUpdate(nX1, nY1)
    if HLBOp_Blueprint.IsMoveBlueprint() then
        return  -- 移动蓝图中，不能触发多选
    end

    if not self.bMultiChooseMode and self.nInputType ~= HLB_INPUT_TYPE.MAK then
        return
    end

    if not safe_check(self.drawNodeParent) then
        return
    end

    if self.bRDown then
        HomelandInput.MultiChooseDrawEnd()
        return
    end

    if not self.drawNode then
        self.drawNode = cc.DrawNode:create()
        self.drawNodeParent:addChild(self.drawNode, 1)
        UIHelper.SetPosition(self.drawNode, 0, 0)

        local nW, nH = UIHelper.GetContentSize(self.drawNodeParent)
        UIHelper.SetContentSize(self.drawNode, nW, nH)
        UIHelper.SetName(self.drawNode, "drawNode")
    end

    local nStartX, nStartY = UIHelper.ConvertToNodeSpace(self.drawNodeParent, self.nDrawBeganX, self.nDrawBeganY)
    local nEndX, nEndY = UIHelper.ConvertToNodeSpace(self.drawNodeParent, nX1, nY1)
    local fillColor = cc.c4f(0, 1, 0, 0.5)
    local lineColor = cc.c4f(0, 1, 0, 1)

    self.drawNode:clear()
    self.drawNode:drawSolidRect(cc.p(nStartX, nStartY), cc.p(nEndX, nEndY), fillColor)
    self.drawNode:drawRect(cc.p(nStartX, nStartY), cc.p(nEndX, nEndY), lineColor)
end

function HomelandInput.MultiChooseDrawEnd(nX1, nY1)
    UIHelper.RemoveFromParent(self.drawNode)
    self.drawNode = nil

    if HLBOp_Blueprint.IsMoveBlueprint() then
        return  -- 移动蓝图中，不能触发多选
    end

    if not self.bMultiChooseMode and self.nInputType ~= HLB_INPUT_TYPE.MAK then
        return
    end

    if self.bRDown then
        return
    end

    self.nMultiEndX, self.nMultiEndY = Homeland_GetCursorPosInPixels()

    Event.Dispatch(EventType.OnHomelandMultiSelectEnd, self.nDrawBeganX, self.nDrawBeganY, nX1, nY1)
    HLBOp_Select.SelectRec(self.nMultiBeganX, self.nMultiBeganY, self.nMultiEndX, self.nMultiEndY)
    self.bOnMultiChoose = false    -- 用于判断是否在进行多选操作
end

function HomelandInput.SetTouchEnabled(bEnable)
    self.bEnable = bEnable
end
