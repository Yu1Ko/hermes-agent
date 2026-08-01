-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: FSM
-- Date: 2022-11-21 10:02:46
-- Desc: 轻量级状态机
-- ---------------------------------------------------------------------------------

FSM = class("FSM")

function FSM.New()
    local fsm = FSM.CreateInstance(FSM)
    fsm.m_tbStates = {}

    fsm.m_nLastState = nil
    fsm.m_nCurrentState = nil

    return fsm
end

function FSM:AddState(nState, fnOnEnter, fnOnExit)
    if not nState then return end

    if not self.m_tbStates[nState] then
        self.m_tbStates[nState] = {
            fnOnEnter = fnOnEnter,
            fnOnExit = fnOnExit,
        }
    else
        LOG.ERROR("State %d is already exist: ", nState)
    end
end

function FSM:AddTransition(nPrevState, nNextState, nCondition)
    if not self.m_tbStates[nPrevState] then return end
    if not self.m_tbStates[nNextState] then return end
    if not nCondition then return end

    local tbState = self.m_tbStates[nPrevState]
    if not tbState[nCondition] then
        tbState[nCondition] = nNextState
    else
        LOG.ERROR("Transition is already exist, StatePrev: %d, StateNext: %d, Condition: %d", 
        nPrevState, nNextState, nCondition)
    end
end

function FSM:TriggerCondition(nCondition)
    local tbCurState = self.m_tbStates[self.m_nCurrentState]
    local nNextState = tbCurState and tbCurState[nCondition]
    if nNextState then
        self:_changeState(nNextState)
    end
end

function FSM:StartFSM(nFirstState)
    self:_changeState(nFirstState)
end

function FSM:GetCurrentState()
    return self.m_nCurrentState
end

function FSM:_changeState(nState)
    self.m_nLastState = self.m_nCurrentState
    self.m_nCurrentState = nState
    self:_invokeChangeStateCallback()
end

function FSM:_invokeChangeStateCallback()
    local tbLastState = self.m_tbStates[self.m_nLastState]
    local tbCurState = self.m_tbStates[self.m_nCurrentState]
    if tbLastState and tbLastState.fnOnExit then
        tbLastState.fnOnExit(self.m_nCurrentState)
    end
    if tbCurState and tbCurState.fnOnEnter then
        tbCurState.fnOnEnter(self.m_nLastState)
    end
end


return FSM