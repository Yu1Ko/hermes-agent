-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIShieldPopView
-- Date: 2022-11-30 15:12:44
-- Desc: 勿扰选项
-- Prefab: PanelShieldPop
-- ---------------------------------------------------------------------------------

---@class UIShieldPopView
local UIShieldPopView = class("UIShieldPopView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIShieldPopView:_LuaBindList()
    self.BtnClose = self.BtnClose --- 关闭界面

    self.TogAllCheck = self.TogAllCheck --- 全部屏蔽/取消

    self.TogOtherCheck = self.TogOtherCheck --- 禁止别人组我
    self.TogTeamCheck = self.TogTeamCheck --- 屏蔽组队申请
    self.TogJoinTeamCheck = self.TogJoinTeamCheck --- 屏蔽入队申请
    self.TogFriendCheck = self.TogFriendCheck --- 屏蔽好友申请
    self.TogTeacherCheck = self.TogTeacherCheck --- 屏蔽拜师申请
    self.TogStudentCheck = self.TogStudentCheck --- 屏蔽收徒申请
    self.TogMutuallyCheck = self.TogMutuallyCheck --- 屏蔽交互申请
    self.TogDoubleCheck = self.TogDoubleCheck --- 屏蔽双骑申请
    self.TogTradeCheck = self.TogTradeCheck --- 屏蔽交易申请
    self.TogCampCheck = self.TogCampCheck --- 屏蔽入帮申请
    self.TogFightCheck = self.TogFightCheck --- 屏蔽切磋申请
    self.TogArenaCheck = self.TogArenaCheck --- 屏蔽名剑申请
end

function UIShieldPopView:OnEnter()
    self.tShieldEventList = {
        {szName="屏蔽组队申请", szKey="PARTY_INVITE_REQUEST", tToggle=self.TogTeamCheck},
        {szName="屏蔽入队申请", szKey="PARTY_APPLY_REQUEST", tToggle=self.TogJoinTeamCheck},
        {szName="屏蔽好友申请", szKey="PLAYER_BE_ADD_FELLOWSHIP", tToggle=self.TogFriendCheck},
        --- todo: 等后续交互功能实现后再接入
        {szName="屏蔽交互申请", szKey="EMOTION_ACTION_REQUEST", tToggle=self.TogMutuallyCheck},
        {szName="屏蔽双骑申请", szKey="FOLLOW_INVITE", tToggle=self.TogDoubleCheck},
        {szName="屏蔽交易申请", szKey="TRADING_INVITE", tToggle=self.TogTradeCheck},
        {szName="屏蔽帮会申请", szKey="INVITE_JOIN_TONG_REQUEST", tToggle=self.TogCampCheck},
        {szName="屏蔽切磋申请", szKey="APPLY_DUEL", tToggle=self.TogFightCheck},
    }

    self.tFilterOperateList = {
        {szName="屏蔽拜师申请", szGetKey="OnQueryMentor", tSetKeys={"OnQueryMentor", "OnQueryDirectMentor"}, tToggle=self.TogTeacherCheck},
        {szName="屏蔽收徒申请", szGetKey="OnQueryApprentice", tSetKeys={"OnQueryApprentice", "OnQueryDirectApprentice"}, tToggle=self.TogStudentCheck},
        {szName="屏蔽名剑申请", szGetKey="INVITE_ARENA_CORPS", tSetKeys={"INVITE_ARENA_CORPS"}, tToggle=self.TogArenaCheck},
    }

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitToggleList()
end

function UIShieldPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

-- 屏蔽某个交互功能, 勾选时表示屏蔽
-- eg. ENABLE_XXX
local fnShieldEvent = function(szEventName, bCheck)
    local bEnable = not bCheck

    Event.Dispatch(szEventName, bEnable)
end

-- eg. XXX
local fnHasShieldEvent = function(szEventKey)
    local bEnable = IsRegisterEvent(szEventKey)
    return not bEnable
end

function UIShieldPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(VIEW_ID.PanelShieldPop)
    end)
    
    -- hack: 这里不能用 OnSelectChanged，有可能会导致循环触发事件，尽量用 OnClick
    UIHelper.BindUIEvent(self.TogAllCheck, EventType.OnClick, function()
        local bSelected = UIHelper.GetSelected(self.TogAllCheck) 
        
        self:ShowTargetModuleNotImplementTip("全部屏蔽/取消", bSelected)

        -- 调整ui按钮的状态和对应开关的逻辑状态
        UIHelper.SetSelected(self.TogOtherCheck, bSelected)
        RemoteCallToServer("OnSetRefuseTeamInvite", bSelected)

        for _, tEvent in ipairs(self.tShieldEventList) do
            UIHelper.SetSelected(tEvent.tToggle, bSelected)

            local szEventName = "ENABLE_" .. tEvent.szKey
            fnShieldEvent(szEventName, bSelected)
        end

        for _, tFilterOperate in ipairs(self.tFilterOperateList) do
            UIHelper.SetSelected(tFilterOperate.tToggle, bSelected)

            for _, szKey in pairs(tFilterOperate.tSetKeys) do
                EnableFilterOperate(szKey, bSelected)
            end
        end
    end)

    local fnUpdateFilterAllStatus = function()
        UIHelper.SetSelected(self.TogAllCheck, self:IsFilterAll(), false)
    end

    UIHelper.BindUIEvent(self.TogOtherCheck, EventType.OnSelectChanged, function(_, bSelected)
        self:ShowTargetModuleNotImplementTip("禁止别人组我", bSelected)

        RemoteCallToServer("OnSetRefuseTeamInvite", bSelected)
    end)
    -- 由于这个禁止别人组我的开关需要修改服务器状态后再同步回来，所以这里监听下对应的事件，在这里同步更新 全部屏蔽 按钮的状态
    Event.Reg(self, "CHANGE_REFUSE_TEAM_INVITE_FLAG_NOTIFY", function(bIsRefuse)
        UIHelper.SetSelected(self.TogAllCheck, self:IsFilterAll())
    end)


    for _, tEvent in ipairs(self.tShieldEventList) do
        UIHelper.BindUIEvent(tEvent.tToggle, EventType.OnSelectChanged, function(_, bSelected)
            self:ShowTargetModuleNotImplementTip(tEvent.szName, bSelected)

            local szEventName = "ENABLE_" .. tEvent.szKey
            fnShieldEvent(szEventName, bSelected)

            fnUpdateFilterAllStatus()
        end)
    end

    for _, tFilterOperate in ipairs(self.tFilterOperateList) do
        UIHelper.BindUIEvent(tFilterOperate.tToggle, EventType.OnSelectChanged, function(_, bSelected)
            self:ShowTargetModuleNotImplementTip(tFilterOperate.szName, bSelected)

            for _, szKey in pairs(tFilterOperate.tSetKeys) do
                EnableFilterOperate(szKey, bSelected)
            end

            fnUpdateFilterAllStatus()
        end)
    end
end

function UIShieldPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIShieldPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIShieldPopView:InitToggleList()
    local player = GetClientPlayer()

    -- 一键开关依赖于其他开关的状态
    UIHelper.SetSelected(self.TogAllCheck, self:IsFilterAll())

    -- 这个状态是存在服务器的内存中，特殊处理
    UIHelper.SetSelected(self.TogOtherCheck, player.bRefuseTeamInvite)

    -- 通过 global 中的一个 table 来维护的状态
    for _, tEvent in ipairs(self.tShieldEventList) do
        UIHelper.SetSelected(tEvent.tToggle, fnHasShieldEvent(tEvent.szKey))
        local label = UIHelper.GetChildByName(tEvent.tToggle, "LabelCheck")
        if label then UIHelper.SetString(label, tEvent.szName) end
    end

    -- 通过 m_tFilter 来维护的状态
    for _, tFilterOperate in ipairs(self.tFilterOperateList) do
        UIHelper.SetSelected(tFilterOperate.tToggle, IsFilterOperateEnable(tFilterOperate.szGetKey))
        local label = UIHelper.GetChildByName(tFilterOperate.tToggle, "LabelCheck")
        if label then UIHelper.SetString(label, tFilterOperate.szName) end
    end
end

function UIShieldPopView:IsFilterAll()
    local player = GetClientPlayer()

    local tAllFilterStatus = {}

    table.insert(tAllFilterStatus, player.bRefuseTeamInvite)

    for _, tEvent in ipairs(self.tShieldEventList) do
        table.insert(tAllFilterStatus, fnHasShieldEvent(tEvent.szKey))
    end

    for _, tFilterOperate in ipairs(self.tFilterOperateList) do
        table.insert(tAllFilterStatus, IsFilterOperateEnable(tFilterOperate.szGetKey))
    end

    -- 有任何一个开关未勾选，则表示没有全部屏蔽
    for _, bFiltered in ipairs(tAllFilterStatus) do
        if not bFiltered then
            return false
        end
    end

    return true
end

function UIShieldPopView:ShowTargetModuleNotImplementTip(szButtonName, bSelected)
    -- re: 这个用于提示这个开关对应模块还没接入，实际没有地方使用，方便后续对应模块接入时，记得使用这个开关的状态
    -- re: 当所有对应模块都已接入后，再删除这个函数以及所有调用的地方
    -- local msg = string.format("TODO: %s 设置为 %s，但目标模块的UI尚未接入", szButtonName, tostring(bSelected))
    -- TipsHelper.ShowPlaceRedTip(msg)
    -- LOG.DEBUG(msg)
end

function UIShieldPopView:UpdateInfo()
    
end


return UIShieldPopView
