
NewModule("HLBOp_Step")

local UNDO_TYPE = {
    NORMAL = 1,
    BOTTOM = 2,
    CLEAR = 3,
    WITHOUT_REFRESH = 4
}

local OP_UNDOABLE_TYPE = {
    UNDO = 1,
    REDO = 2,
}

function StartOneStep(szInfo)
    Homeland_SendMessage(HOMELAND_BUILD_OP.START_GROUP, szInfo, 0)
end

function EndOneStep()
    Homeland_SendMessage(HOMELAND_BUILD_OP.END_GROUP, 0)
end

function ClearCurStep()
    Homeland_Log("ClearCurStep")
    EndOneStep()
    Homeland_SendMessage(HOMELAND_BUILD_OP.UNDO, UNDO_TYPE.CLEAR)
	Homeland_SendMessage(HOMELAND_BUILD_OP.REMOVE_OPERATION, 2, 0)
end

function ClearStep()
    Homeland_Log("ClearStep")
	Homeland_SendMessage(HOMELAND_BUILD_OP.REMOVE_OPERATION, 1, 0)
end

function ClearBottomStep(nCount)
    Homeland_Log("ClearBottomStep")
    for i = 1, nCount - 1 do
        Homeland_SendMessage(HOMELAND_BUILD_OP.UNDO, UNDO_TYPE.BOTTOM)
        Homeland_SendMessage(HOMELAND_BUILD_OP.REMOVE_OPERATION, 2, 0)
    end
    --最后一次要更新数量
    Homeland_SendMessage(HOMELAND_BUILD_OP.UNDO, UNDO_TYPE.CLEAR)
    Homeland_SendMessage(HOMELAND_BUILD_OP.REMOVE_OPERATION, 2, 0)
end

function ClearCurStepWithoutRefreshData()
    Homeland_Log("ClearCurStepWithoutRefreshData")
    EndOneStep()
    Homeland_SendMessage(HOMELAND_BUILD_OP.UNDO, UNDO_TYPE.WITHOUT_REFRESH)
	Homeland_SendMessage(HOMELAND_BUILD_OP.REMOVE_OPERATION, 2, 0)
end

function Undo()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.OP_UNDOABLE, OP_UNDOABLE_TYPE.UNDO)
    Homeland_Log("发送HOMELAND_BUILD_OP.OP_UNDOABLE", bResult)
end

function Redo()
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.OP_UNDOABLE, OP_UNDOABLE_TYPE.REDO)
    Homeland_Log("发送HOMELAND_BUILD_OP.OP_UNDOABLE", bResult)
end

function RealUndo()
    HLBOp_Main.SetModified(true)
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.UNDO, UNDO_TYPE.NORMAL)
    Homeland_Log("发送HOMELAND_BUILD_OP.UNDO", bResult)
end

function RealRedo()
    HLBOp_Main.SetModified(true)
    local bResult = Homeland_SendMessage(HOMELAND_BUILD_OP.REDO, 0)
    Homeland_Log("发送HOMELAND_BUILD_OP.REDO", bResult)
end

function OnEvent(szEvent)
	if szEvent == "HOMELAND_CALL_RESULT" then
		local eOperationType = arg0
		if eOperationType == HOMELAND_BUILD_OP.UNDO then
            local nUserData = arg1
            if nUserData == UNDO_TYPE.NORMAL or nUserData == UNDO_TYPE.CLEAR then
                local nResult = arg2
                local bResult = Homeland_ToBoolean(nResult)
                if bResult then
                    HLBOp_Amount.RefreshLandData()
                    HLBOp_Group.RequestAllGroupIDs()
                    if nUserData == UNDO_TYPE.NORMAL then
                        HLBView_Message.Show(g_tStrings.STR_HOMELAND_ROLLBACK_SUCCESS, 1)
                    end
                else
                    if nUserData == UNDO_TYPE.NORMAL then
                        HLBView_Message.Show(g_tStrings.STR_HOMELAND_ROLLBACK_FAILED, 1)
                    end
                end
            end
        elseif eOperationType == HOMELAND_BUILD_OP.REDO then
            local nResult = arg2
            local bResult = Homeland_ToBoolean(nResult)
            if bResult then
                HLBOp_Amount.RefreshLandData()
                HLBOp_Group.RequestAllGroupIDs()
                HLBView_Message.Show(g_tStrings.STR_HOMELAND_UNROLLBACK_SUCCESS, 1)
            else
                HLBView_Message.Show(g_tStrings.STR_HOMELAND_UNROLLBACK_FAILED, 1)
            end
        elseif eOperationType == HOMELAND_BUILD_OP.OP_UNDOABLE then
            local nUserData = arg1
            local nCanUndoCount = arg2
            local nCanRedoCount = arg3
            Homeland_Log("收到HOMELAND_BUILD_OP.OP_UNDOABLE", nUserData, nCanUndoCount, nCanRedoCount)
            if nUserData == OP_UNDOABLE_TYPE.UNDO then
                if nCanUndoCount > 0 then
                    RealUndo()
                else
                    HLBView_Message.Show(g_tStrings.STR_HOMELAND_CANT_ROLLBACK_REASON_AT_FIRST, 1)
                end
            elseif nUserData == OP_UNDOABLE_TYPE.REDO then
                if nCanRedoCount > 0 then
                    RealRedo()
                else
                    HLBView_Message.Show(g_tStrings.STR_HOMELAND_CANT_UNROLLBACK_REASON_AT_LAST, 1)
                end
            end
		end
	end
end
