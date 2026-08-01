BaseState = BaseState or {}

function BaseState:New(stateName)
    self.__index = self
    o = setmetatable({}, self)
    o.stateName = stateName
    return o
end

-- 进入状态
function BaseState:OnEnter()
end

-- 更新状态
function BaseState:OnUpdate()
end

-- 离开状态
function BaseState:OnLeave()
end


FsmMachine = FsmMachine or {}

function FsmMachine:New()
    self.__index = self
    o = setmetatable({}, self)
    o.states = {}
    o.curState = nil
    return o
end

-- 添加状态
function FsmMachine:AddState(baseState)
    self.states[baseState.stateName] = baseState
    LOG.INFO("AddState :"..baseState.stateName)
end

-- 初始化默认状态
function FsmMachine:AddInitState(baseState)
    LOG.INFO("test-----------------")
    self.curState = baseState
end

-- 更新当前状态
function FsmMachine:Update()
    self.curState:OnUpdate()
end

-- 切换状态
function FsmMachine:Switch(stateName)
    LOG.INFO("Switch Last: "..self.curState.stateName)
    self.curState:OnLeave()
    LOG.INFO("Switch Cur: "..stateName)
    self.curState = self.states[stateName]
    self.curState:OnEnter()

    --[[
    if self.curState.stateName ~= stateName then
    end]]
end
