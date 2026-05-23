
NewModule("HLBOp_Rotate")

local ROTATE_TYPE = {
    PICK_UP = 1, --拾取
    ON_FLOOR = 2, --在地上
}

m_tBackAngle = {} --{[dwObjID] = nAngle}
m_bInRotating = false

m_bBackAngleInfoAfterReceiveEvent = false

function Rotate(nAnglesPitch, nAnglesYaw, nAnglesRoll)
    if nAnglesYaw == nil and nAnglesRoll == nil then --仅传一个参数
        nAnglesPitch, nAnglesYaw, nAnglesRoll = 0, nAnglesPitch, 0
    end
    local tSelectObjs = HLBOp_Select.GetSelectInfo()
    if #tSelectObjs == 1 then
        local bIsMoveObj = HLBOp_Place.IsMoveObj()
        if bIsMoveObj then
            SingleRotateInPickUp(tSelectObjs[1], nAnglesPitch, nAnglesYaw, nAnglesRoll)
        else
            SingleRotateInOnFloor(tSelectObjs[1], nAnglesPitch, nAnglesYaw, nAnglesRoll)
        end
    elseif #tSelectObjs > 1 then
        if HLBOp_MultiItemOp.IsMoveObj() then
            MultiRotate(-nAnglesYaw)
        end
    end
end

function SingleRotateInOnFloor(dwObjID, nAnglesPitch, nAnglesYaw, nAnglesRoll)
    if m_bInRotating then
        return
    end
    HLBOp_Main.SetModified(true)
    m_bInRotating = true
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.ROTATE, dwObjID, nAnglesPitch, nAnglesYaw, nAnglesRoll, ROTATE_TYPE.ON_FLOOR)
    Homeland_Log("发送HOMELAND_BUILD_OP.ROTATE", dwObjID, nAnglesPitch, nAnglesYaw, nAnglesRoll, bResult)
end

function SingleRotateInPickUp(dwObjID, nAnglesPitch, nAnglesYaw, nAnglesRoll)
    if m_bInRotating then
        return
    end
    HLBOp_Main.SetModified(true)
    m_bInRotating = true
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.ROTATE, dwObjID, nAnglesPitch, nAnglesYaw, nAnglesRoll, ROTATE_TYPE.PICK_UP)
    Homeland_Log("发送HOMELAND_BUILD_OP.ROTATE", dwObjID, nAnglesPitch, nAnglesYaw, nAnglesRoll, bResult)
end

function MultiRotate(nAngles)
    if m_bInRotating then
        return
    end
    HLBOp_Main.SetModified(true)
    m_bInRotating = true
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.MULTI_ROTATE, nAngles, 0)
    Homeland_Log("发送HOMELAND_BUILD_OP.MULTI_ROTATE", nAngles, bResult)
end

function OnEvent(szEvent)
	if szEvent == "HOMELAND_CALL_RESULT" then
		local eOperationType = arg0
        if eOperationType == HOMELAND_BUILD_OP.ROTATE then
            OnRotateResult()
        elseif eOperationType == HOMELAND_BUILD_OP.MULTI_ROTATE then
            OnMultiRotateResult()
		end
	end
end

function OnRotateResult()
    local nUserData = arg1
    local nRotateResCode = arg2
    local bResult = (nRotateResCode == 0)
    local nRotatePitchAngle = arg3
    local nRotateYawAngle = arg4
    local nRotateRollAngle = arg5
    local dwObjID = arg6
    nRotatePitchAngle = nRotatePitchAngle * 180 / math.pi
    nRotateYawAngle = nRotateYawAngle * 180 / math.pi
    nRotateRollAngle = nRotateRollAngle * 180 / math.pi
    Homeland_Log("收到HOMELAND_BUILD_OP.ROTATE", bResult, nRotateResCode, nRotatePitchAngle, nRotateYawAngle, nRotateRollAngle)
    m_bInRotating = false

    if (nRotatePitchAngle ~= 0 or nRotateRollAngle ~= 0) and (not bResult) then
        local szErrorMsg = g_tStrings.tHomelandRotateErrorString[nRotateResCode]
        HLBView_Message.Show(szErrorMsg, 1)
        return
    end

    if not (nRotateResCode == 0 or nRotateResCode == 1) then
        local szErrorMsg = g_tStrings.tHomelandRotateErrorString[nRotateResCode]
        if szErrorMsg and nRotateResCode == 3 then
            HLBView_Message.Show(szErrorMsg, 1)
        end
        return
    end

    if nUserData == ROTATE_TYPE.ON_FLOOR then
        if nRotateResCode == 1 then
            HLBOp_Step.ClearStep()
            if not m_tBackAngle[dwObjID] then
                m_tBackAngle[dwObjID] = 0
            end
            m_tBackAngle[dwObjID] = m_tBackAngle[dwObjID] + nRotateYawAngle
            if m_bBackAngleInfoAfterReceiveEvent then
                BackObjAngle(dwObjID)
                m_bBackAngleInfoAfterReceiveEvent = false
            end
        elseif nRotateResCode == 0 then
            if m_tBackAngle[dwObjID] then
                HLBOp_Step.ClearStep()
            end
            m_tBackAngle[dwObjID] = nil
        end
    end

    HLBOp_Other.GetObjectInfo(dwObjID)
end

function OnMultiRotateResult()
    local nUserData = arg1
	local nRotateResCode = arg2 -- 0 为成功； 1 为不可旋转， 3为旋转失败
    local bResult = nRotateResCode == 0
    Homeland_Log("收到HOMELAND_BUILD_OP.MULTI_ROTATE", bResult)
    m_bInRotating = false
    if not bResult then

    end
end

function BackObjAngle(dwObjID)
    if m_tBackAngle[dwObjID] then
        if not m_bInRotating then
            local nBackAngle = -m_tBackAngle[dwObjID]
            m_tBackAngle[dwObjID] = nil
            SingleRotateInOnFloor(dwObjID, 0, nBackAngle, 0)
            HLBOp_Step.ClearStep()
        else
            m_bBackAngleInfoAfterReceiveEvent = true
        end
    end
end

function Init()
    m_tBackAngle = {}
    m_bInRotating = false
    m_bBackAngleInfoAfterReceiveEvent = false
end

function UnInit()
    m_tBackAngle = nil
    m_bInRotating = nil
    m_bBackAngleInfoAfterReceiveEvent = nil
end