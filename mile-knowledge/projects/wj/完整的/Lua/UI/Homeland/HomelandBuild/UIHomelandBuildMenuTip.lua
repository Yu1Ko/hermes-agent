-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildMenuTip
-- Date: 2023-04-27 10:50:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildMenuTip = class("UIHomelandBuildMenuTip")

local SCALE_TYPE = {
    NORMAL = 0,
    X = 1,
    Y = 2,
    Z = 3,
    MULTI = 4,
}

local ROTATE_TYPE = {
    PITCH = 1,
    YAW = 2,
    ROLL = 3,
}

function UIHomelandBuildMenuTip:OnEnter(tObjIDs, bMultiMode)
    self.tObjIDs = tObjIDs
    self.bMultiMode = bMultiMode or false
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        Timer.AddFrameCycle(self, 1, function ()
            self:UpdatePos()
        end)
    end

    self.bInitPos = false
    if HLBOp_Place.GetBlueprintObjID() > 0 then
        local sizeDesign = UIHelper.GetCurResolutionSize()
        local tPos = cc.Director:getInstance():convertToGL({x = sizeDesign.width / 2, y = sizeDesign.height / 2})
        self._rootNode:setPosition(tPos.x, tPos.y)
        self.bInitPos = true
    end

    self.nRotateType = ROTATE_TYPE.YAW
    self.nScaleType = SCALE_TYPE.NORMAL

    self.bInitData = false
    self:UpdateInfo()
    self:ShowBtn(true)
    self:UpdateMultMoveInfo(bMultiMode)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutContent, true, true)
end

function UIHomelandBuildMenuTip:OnExit()
    self.bInit = false
end

function UIHomelandBuildMenuTip:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnMove, EventType.OnTouchBegan, function (_, x, y)
        self.nStartX, self.nStartY = x, y

        HLBOp_Camera.SetCameraLock(true)
        if self.bMultiMode then
            HLBOp_MultiItemOp.StartMove()
        elseif self.tObjIDs.bSingle then
            HLBOp_Place.StartMoveItem(self.tObjIDs[1])
        end

        self:ShowBtn(false)
    end)

    UIHelper.BindUIEvent(self.BtnMove, EventType.OnTouchMoved, function (_, x, y)
        if self.nStartX and self.nStartY and (math.abs(self.nStartX - x) > 1 or math.abs(self.nStartY - y) > 1) then
            if not self.tObjIDs or #self.tObjIDs < 1 then
                return
            end

            if HLBOp_MultiItemOp.IsMoveObj() and HLBOp_Main.GetMoveObjEnabled() then
                HLBOp_MultiItemOp.Move(x,y)
            end
            HLBOp_Main.SetMoveObjEnabled(true)

            self.bMove = true
        end
    end)

    UIHelper.BindUIEvent(self.BtnMove, EventType.OnTouchEnded, function (_, x, y)
        HLBOp_Main.SetMoveObjEnabled(false)
        self.bMove = false
        self:ShowBtn(true)
        HLBOp_Camera.SetCameraLock(false)
    end)

    UIHelper.BindUIEvent(self.BtnMove, EventType.OnTouchCanceled, function (_, x, y)
        HLBOp_Main.SetMoveObjEnabled(false)
        self.bMove = false
        self:ShowBtn(true)
        HLBOp_Camera.SetCameraLock(false)
    end)

    UIHelper.SetSwallowTouches(self.BtnMove, false)

    UIHelper.BindUIEvent(self.BtnRotateClockwise, EventType.OnClick, function ()
        local nAngles = -Homeland_GetKeyZCAngles()
        if self.nRotateType == ROTATE_TYPE.PITCH then
            HLBOp_Rotate.Rotate(nAngles, 0, 0)
        elseif self.nRotateType == ROTATE_TYPE.YAW then
            HLBOp_Rotate.Rotate(0, nAngles, 0)
        elseif self.nRotateType == ROTATE_TYPE.ROLL then
            HLBOp_Rotate.Rotate(0, 0, nAngles)
        end
    end)

    UIHelper.BindUIEvent(self.BtnRotateAntiwise, EventType.OnClick, function ()
        local nAngles = Homeland_GetKeyZCAngles()
        if self.nRotateType == ROTATE_TYPE.PITCH then
            HLBOp_Rotate.Rotate(nAngles, 0, 0)
        elseif self.nRotateType == ROTATE_TYPE.YAW then
            HLBOp_Rotate.Rotate(0, nAngles, 0)
        elseif self.nRotateType == ROTATE_TYPE.ROLL then
            HLBOp_Rotate.Rotate(0, 0, nAngles)
        end
    end)

    -- UIHelper.BindUIEvent(self.BtnFreeRotate, EventType.OnTouchBegan, function ()
    --     UIHelper.SetVisible(self.WidgetFreeRotateHandle, true)
    --     UIHelper.SetVisible(self.BtnRotateClockwise, false)
    --     UIHelper.SetVisible(self.BtnRotateAntiwise, false)
    --     UIHelper.SetPosition(self.ImgJoystick, 0, 0)
    -- end)

    -- UIHelper.BindUIEvent(self.BtnFreeRotate, EventType.OnTouchMoved, function (btn, nX, nY)
    --     local x, y = UIHelper.ConvertToNodeSpace(self.BtnFreeRotateHandle, nX, nY)

    --     local nDistance = kmath.len2(x, y, 0, 0)
    --     local nNormalizeX, nNormalizeY = kmath.normalize2(x, y)

    --     local nRadius = 80
    --     if nDistance < nRadius then
    --         UIHelper.SetPosition(self.ImgJoystick, x, y)
    --     else
    --         local nX = nNormalizeX * nRadius
    --         local nY = nNormalizeY * nRadius
    --         UIHelper.SetPosition(self.ImgJoystick, nX, nY)
    --     end

    --     local nRadian = math.atan2(x, y) -- 弧度
    --     local nAngle = nRadian * 180 / math.pi -- 角度
    --     UIHelper.SetRotation(self.WidgetLight, nAngle)

    --     if x > 0 then
    --         self:AutoRatate(-2)
    --     else
    --         self:AutoRatate(2)
    --     end
    -- end)

    -- UIHelper.BindUIEvent(self.BtnFreeRotate, EventType.OnTouchEnded, function ()
    --     UIHelper.SetVisible(self.WidgetFreeRotateHandle, false)
    --     UIHelper.SetVisible(self.BtnRotateClockwise, true)
    --     UIHelper.SetVisible(self.BtnRotateAntiwise, true)
    --     self:AutoRatate(0)
    -- end)

    -- UIHelper.BindUIEvent(self.BtnFreeRotate, EventType.OnTouchCanceled, function ()
    --     UIHelper.SetVisible(self.WidgetFreeRotateHandle, false)
    --     UIHelper.SetVisible(self.BtnRotateClockwise, true)
    --     UIHelper.SetVisible(self.BtnRotateAntiwise, true)
    --     self:AutoRatate(0)
    -- end)

    for i, tog in ipairs(self.tbTogAxis) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function(btn)
            self.nRotateType = i
            self:UpdateRotateInfo()
        end)

        UIHelper.ToggleGroupAddToggle(self.TogGroupAxis, tog)
    end

    for i, tog in ipairs(self.tbTogScaleAxis) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function(btn)
            self.nScaleType = i
            self:InitScaleInfo()
        end)

        UIHelper.ToggleGroupAddToggle(self.TogGroupScaleAxis, tog)
    end

    UIHelper.BindUIEvent(self.SliderScaleAngle, EventType.OnChangeSliderPercent, function(SliderEventType, nSliderEvent)
        if nSliderEvent == ccui.SliderEventType.slideBallDown then
            self.bSliding = true

        elseif nSliderEvent == ccui.SliderEventType.slideBallUp then
            self.bSliding = false
            -- 强制修正滑块进度
            local fPerc = (self.fCurScaleCount - self.fMinScaleCount) / self.fTotalScaleCount * 100
            UIHelper.SetProgressBarPercent(self.SliderScaleAngle, fPerc)
            fPerc = fPerc / 100.0

            self:UpdateScaleInfo(fPerc)
        end

        if self.bSliding then
            local fPerc = UIHelper.GetProgressBarPercent(self.SliderScaleAngle) / 100
            self.fCurScaleCount = fPerc * self.fTotalScaleCount + self.fMinScaleCount
            if self.fCurScaleCount <= self.fMinScaleCount then
                self.fCurScaleCount = self.fMinScaleCount
            elseif self.fCurScaleCount >= self.fMaxScaleCount then
                self.fCurScaleCount = self.fMaxScaleCount
            end

            self:UpdateScaleInfo(fPerc)
        end
    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditBoxScale, function()
			local szScale = UIHelper.GetText(self.EditBoxScale)
			local fScale = tonumber(szScale)
            if fScale then
                self.fCurScaleCount = math.min(self.fMaxScaleCount, fScale)
                self.fCurScaleCount = math.max(self.fMinScaleCount, self.fCurScaleCount)
            end
            UIHelper.SetText(self.EditBoxScale, self.fCurScaleCount)

            local fPerc = (self.fCurScaleCount - self.fMinScaleCount) / self.fTotalScaleCount * 100
            UIHelper.SetProgressBarPercent(self.SliderScaleAngle, fPerc)
            fPerc = fPerc / 100.0
            self:UpdateScaleInfo(fPerc)
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditBoxScale, function()
			local szScale = UIHelper.GetText(self.EditBoxScale)
			local fScale = tonumber(szScale)
            if fScale then
                self.fCurScaleCount = math.min(self.fMaxScaleCount, fScale)
                self.fCurScaleCount = math.max(self.fMinScaleCount, self.fCurScaleCount)
            end
            UIHelper.SetText(self.EditBoxScale, self.fCurScaleCount)

            local fPerc = (self.fCurScaleCount - self.fMinScaleCount) / self.fTotalScaleCount * 100
            UIHelper.SetProgressBarPercent(self.SliderScaleAngle, fPerc)
            fPerc = fPerc / 100.0
            self:UpdateScaleInfo(fPerc)
        end)
    end
    UIHelper.SetEditboxTextHorizontalAlign(self.EditBoxScale, TextHAlignment.CENTER)

    UIHelper.BindUIEvent(self.BtnScalePlus, EventType.OnClick, function(btn)
        local fScale = self.fCurScaleCount + 0.1
        self.fCurScaleCount = math.min(self.fMaxScaleCount, fScale)
        self.fCurScaleCount = math.max(self.fMinScaleCount, self.fCurScaleCount)

        local fPerc = (self.fCurScaleCount - self.fMinScaleCount) / self.fTotalScaleCount * 100
        UIHelper.SetProgressBarPercent(self.SliderScaleAngle, fPerc)
        fPerc = fPerc / 100.0

        self:UpdateScaleInfo(fPerc)
    end)

    UIHelper.BindUIEvent(self.BtnScaleMinus, EventType.OnClick, function(btn)
        local fScale = self.fCurScaleCount - 0.1
        self.fCurScaleCount = math.min(self.fMaxScaleCount, fScale)
        self.fCurScaleCount = math.max(self.fMinScaleCount, self.fCurScaleCount)

        local fPerc = (self.fCurScaleCount - self.fMinScaleCount) / self.fTotalScaleCount * 100
        UIHelper.SetProgressBarPercent(self.SliderScaleAngle, fPerc)
        fPerc = fPerc / 100.0

        self:UpdateScaleInfo(fPerc)
    end)

    UIHelper.BindUIEvent(self.BtnScaleReset, EventType.OnClick, function(btn)
        self.fCurScaleCount = 1

        local fPerc = (self.fCurScaleCount - self.fMinScaleCount) / self.fTotalScaleCount * 100
        UIHelper.SetProgressBarPercent(self.SliderScaleAngle, fPerc)
        fPerc = fPerc / 100.0

        self:UpdateScaleInfo(fPerc)
    end)
end

function UIHomelandBuildMenuTip:RegEvent()
    Event.Reg(self, "LUA_HOMELAND_UPDATE_ITEMOP_INFO", function ()
        if not self.bInitData then
            self.bInitData = true
            self:ShowBtn(self.bShowBtn)
        end
        self:UpdateRotateInfo()
    end)

    Event.Reg(self, EventType.OnHomeLandBuildResponseKey, function (szKeyName, ...)
        if szKeyName == "Z" or szKeyName == "C" then
            self:ResponseKey(...)
        elseif szKeyName == "X" then
            local nAngles = ...
            if self.nRotateType == ROTATE_TYPE.PITCH then
                HLBOp_Rotate.Rotate(nAngles, 0, 0)
            elseif self.nRotateType == ROTATE_TYPE.YAW then
                HLBOp_Rotate.Rotate(0, nAngles, 0)
            elseif self.nRotateType == ROTATE_TYPE.ROLL then
                HLBOp_Rotate.Rotate(0, 0, nAngles)
            end
        elseif szKeyName == "V" then
            self.bMove = true
            HLBOp_MultiItemOp.SetMoveObj(true)
        end
    end)
end

function UIHomelandBuildMenuTip:UpdateInfo()
    if not self.tObjIDs or #self.tObjIDs < 1 then
        return
    end

end

function UIHomelandBuildMenuTip:UpdatePos()
    if not UIHelper.GetVisible(self._rootNode) then
        return
    end

    if not self.tObjIDs or #self.tObjIDs < 1 then
        return
    end

    if HLBOp_Camera.IsInDrag() then
        UIHelper.SetVisible(self.WidgetItemArea, false)
        return
    else
        UIHelper.SetVisible(self.WidgetItemArea, true)
    end

    -- if self.tObjIDs.bSingle then
        if not self.bInitPos then
            HLBOp_Other.GetModelPostion(self.tObjIDs[1])
            local nX, nY = HLBOp_Other.GetOneObjectScreenPos(self.tObjIDs[1])

            if nX then
                local nScaleX, nScaleY = UIHelper.GetScreenToResolutionScale()

                nX = nX / nScaleX
                nY = nY / nScaleY

                if nX and nY then
                    local tPos = cc.Director:getInstance():convertToUI({x = nX, y = nY})
                    self._rootNode:setPosition(tPos.x, tPos.y)
                    -- self.bInitPos = true
                end
            end
        else
            if self.bMove then
                local tCursor = GetViewCursorPoint()
                self._rootNode:setPosition(tCursor.x, tCursor.y)
            end
        end
    -- else

    -- end

end

function UIHomelandBuildMenuTip:ShowBtn(bShow)
    local bCanScale = false
    local bFreelyRotate = false

    self.bShowBtn = bShow

    local dwModelID
    if self.tObjIDs.bSingle or #self.tObjIDs == 1 then
        dwModelID = HLBOp_Amount.GetModelIDByObjID(self.tObjIDs[1])
        self.nScaleType = SCALE_TYPE.NORMAL
    else
        self.nScaleType = SCALE_TYPE.MULTI
    end

    self.tRange = nil

    if dwModelID then
        local tLine = FurnitureData.GetFurnInfoByModelID(dwModelID)
		if tLine then
            local tRange = Homeland_GetRange(tLine.szScaleRange)
            if tLine.tXRange then
                tRange = tLine.tXRange
                self.nScaleType = SCALE_TYPE.X
            elseif tRange then
                self.nScaleType = SCALE_TYPE.NORMAL
            end

			if tRange then
                self.tRange = tRange
                bCanScale = true
            end

            if tLine.bFreelyRotate then
                bFreelyRotate = true
            end
        end
    end

    if bShow then
        UIHelper.SetVisible(self.WidgetRotateHandle, true)
        UIHelper.SetVisible(self.WidgetScaleHandle, bCanScale)
        UIHelper.SetVisible(self.tbTogAxis[1], bFreelyRotate)
        UIHelper.SetVisible(self.tbTogAxis[3], bFreelyRotate)
        UIHelper.LayoutDoLayout(self.LayoutTogAxisChoose)
        UIHelper.SetVisible(self.LayoutTogScaleAxisChoose, self.nScaleType ~= SCALE_TYPE.NORMAL)
        UIHelper.LayoutDoLayout(self.WidgetScaleAxisChoose)
        UIHelper.LayoutDoLayout(self.LayoutContentScale)

        UIHelper.SetToggleGroupSelected(self.TogGroupAxis, self.nRotateType - 1)
        UIHelper.SetToggleGroupSelected(self.TogGroupScaleAxis, self.nScaleType - 1)

        if bCanScale then
            self:InitScaleInfo()
        end
        self:UpdateRotateInfo()
    else
        UIHelper.SetVisible(self.WidgetRotateHandle, false)
        UIHelper.SetVisible(self.WidgetScaleHandle, false)
    end
end

function UIHomelandBuildMenuTip:UpdateMultMoveInfo(bMultiMode)
    UIHelper.SetSwallowTouches(self.BtnMove, bMultiMode)
end

function UIHomelandBuildMenuTip:AutoRatate(nAngle)
    if self.nAutoRatateTimerID then
        Timer.DelTimer(self, self.nAutoRatateTimerID)
        self.nAutoRatateTimerID = nil
    end

    if nAngle ~= 0 then
        self.nAutoRatateTimerID = Timer.AddFrameCycle(self, 1, function ()
            HLBOp_Rotate.Rotate(nAngle)
        end)
    end
end

function UIHomelandBuildMenuTip:InitScaleInfo()
    if not self.tRange then
        return
    end

    local fCurScale
    if self.tObjIDs.bSingle then
        local tObjectInfo = HLBOp_Other.GetOneObjectInfo(self.tObjIDs[1])
        local fRealCurScale = -1
        if tObjectInfo then
            if self.nScaleType == SCALE_TYPE.X then
                fRealCurScale = tObjectInfo.fXScale
            elseif self.nScaleType == SCALE_TYPE.Y then
                fRealCurScale = tObjectInfo.fYScale
            elseif self.nScaleType == SCALE_TYPE.Z then
                fRealCurScale = tObjectInfo.fZScale
            else
                fRealCurScale = tObjectInfo.fXScale
            end
        end
        fCurScale = fRealCurScale >= 0 and fRealCurScale or 1.0
    else
        fCurScale = 1.0
    end

    self.fCurScaleCount = fCurScale
    self.fMinScaleCount = self.tRange[1]
    self.fMaxScaleCount = self.tRange[2]
    self.fTotalScaleCount = self.tRange[2] - self.tRange[1]

    local fPerc = (self.fCurScaleCount - self.fMinScaleCount) / self.fTotalScaleCount * 100
    UIHelper.SetProgressBarPercent(self.SliderScaleAngle, fPerc)
    fPerc = fPerc / 100.0

    self:UpdateScaleInfo(fPerc)
end

function UIHomelandBuildMenuTip:UpdateScaleInfo(fPerc)
    UIHelper.SetProgressBarPercent(self.ImgScaleFg, fPerc * 100)
    UIHelper.SetText(self.EditBoxScale, string.format("%.1f", self.fCurScaleCount))

    if self.nScaleType == SCALE_TYPE.MULTI then
        HLBOp_MultiItemOp.Scale(self.fCurScaleCount)
    elseif self.nScaleType == SCALE_TYPE.NORMAL then
        HLBOp_SingleItemOp.Scale(self.fCurScaleCount)
    else
        HLBOp_SingleItemOp.Scale(self.fCurScaleCount, self.nScaleType)
    end
end

function UIHomelandBuildMenuTip:UpdateRotateInfo()
    local fAngle = self:GetSelectAngle()
    UIHelper.SetString(self.LabelAngle, string.format("%.1f°", fAngle))
end

function UIHomelandBuildMenuTip:GetSelectAngle()
    local tSelectObjs = HLBOp_Select.GetSelectInfo()
    local tObjectInfo = HLBOp_Other.GetOneObjectInfo(tSelectObjs[1])
    if not tObjectInfo then return 0 end

    local fRadians
    if self.nRotateType == ROTATE_TYPE.PITCH then
        fRadians = tObjectInfo.fPitch
    elseif self.nRotateType == ROTATE_TYPE.YAW then
        fRadians = tObjectInfo.fYaw
    elseif self.nRotateType == ROTATE_TYPE.ROLL then
        fRadians = tObjectInfo.fRoll
    end

    local fAngle = fRadians * 180 / math.pi
    local nAngle = math.floor(fAngle * 10) / 10
    return nAngle
end

function UIHomelandBuildMenuTip:ResponseKey(nAngles)
    if self.nAutoRotateTimerID then
        Timer.DelTimer(self, self.nAutoRotateTimerID)
        self.nAutoRotateTimerID = nil
    end
    if nAngles == 0 then
        return
    end

    self.nAutoRotateTimerID = Timer.AddFrameCycle(self, 1, function ()
        if self.nRotateType == ROTATE_TYPE.PITCH then
            HLBOp_Rotate.Rotate(nAngles, 0, 0)
        elseif self.nRotateType == ROTATE_TYPE.YAW then
            HLBOp_Rotate.Rotate(0, nAngles, 0)
        elseif self.nRotateType == ROTATE_TYPE.ROLL then
            HLBOp_Rotate.Rotate(0, 0, nAngles)
        end
    end)
end

return UIHomelandBuildMenuTip