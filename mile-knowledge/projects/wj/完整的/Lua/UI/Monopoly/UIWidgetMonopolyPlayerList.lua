local UIWidgetMonopolyPlayerList = class("UIWidgetMonopolyPlayerList")

--------------------------------------------------------------
-- [1] 常量与配置
--------------------------------------------------------------

-- 交换功能 CD 常量
local EXCHANGE_CD_TIME = 15000 -- 交换按钮 CD 时间 15 秒（毫秒）
local m_nLastExchangeLaunchTime = 0 -- 上次发起交换的时间

-------------------------------------------------------------
-- [2] 工具函数
-------------------------------------------------------------

-- 校验大富翁座位索引是否合法
-- nDfwIndex: 待校验的索引值
-- 返回: 原始索引值（仅 number 合法），或 nil（如果不合法）
local function CheckDfwIndex(nDfwIndex)
    if nDfwIndex <= 0 or nDfwIndex > DFW_PLAYERNUM then
        return nil
    end
    return true
end

-------------------------------------------------------------
-- [3] 工具函数
-------------------------------------------------------------

function UIWidgetMonopolyPlayerList:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()

    self.nTimerID = self.nTimerID or Timer.AddFrameCycle(self, 15, function ()
        self:OnFrameBreathe()
    end)
end

function UIWidgetMonopolyPlayerList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonopolyPlayerList:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSelect, EventType.OnClick, function ()
        
    end)
end

function UIWidgetMonopolyPlayerList:RegEvent()
    self:Refresh()

    -- 注册金币变更事件
    MonopolyData.RegisterMonopolyActionTable(DFW_OPERATE_DOWM_PLAYER_MONEY, self.OnPlayerMoneyChange, self)

    -- 注册准备状态变更事件
    MonopolyData.RegisterMonopolyActionTable(DFW_OPERATE_DOWM_PREPARE_READY, self.OnPlayerReadyChange, self)

    -- 注册Buff状态变更事件（6个）
    MonopolyData.RegisterMonopolyActionTable(DFW_OPERATE_DOWM_PLAYER_GOD_STATUS, self.OnPlayerGodStatusChange, self)
    MonopolyData.RegisterMonopolyActionTable(DFW_OPERATE_DOWM_PLAYER_GOD_LEFTTIME, self.OnPlayerGodLeftTimeChange, self)
    MonopolyData.RegisterMonopolyActionTable(DFW_OPERATE_DOWM_PLAYER_HOSPITAL_STATUS, self.OnPlayerHospitalStatusChange, self)
    MonopolyData.RegisterMonopolyActionTable(DFW_OPERATE_DOWM_PLAYER_HOSPITAL_LEFTTIME, self.OnPlayerHospitalLeftTimeChange, self)
    MonopolyData.RegisterMonopolyActionTable(DFW_OPERATE_DOWM_PLAYER_MOVE_STATUS, self.OnPlayerMoveStatusChange, self)
    MonopolyData.RegisterMonopolyActionTable(DFW_OPERATE_DOWM_PLAYER_MOVE_LEFTTIME, self.OnPlayerMoveLeftTimeChange, self)

    -- 注册游戏阶段变更事件
    MonopolyData.RegisterMonopolyActionTable(DFW_OPERATE_DOWM_TABLE_STATE, self.OnTableStateChange, self)

    Event.Reg(self, EventType.OnMonopolyPlayerListOnChangeBuff, function()
        self:OnChangeBuff()
    end)
end

function UIWidgetMonopolyPlayerList:UnRegEvent()
    Event.UnRegAll(self)

    -- 注销金币变更事件
    MonopolyData.UnRegisterMonopolyActionTable(DFW_OPERATE_DOWM_PLAYER_MONEY, self.OnPlayerMoneyChange)

    -- 注销准备状态变更事件
    MonopolyData.UnRegisterMonopolyActionTable(DFW_OPERATE_DOWM_PREPARE_READY, self.OnPlayerReadyChange)

    -- 注销Buff状态变更事件（6个）
    MonopolyData.UnRegisterMonopolyActionTable(DFW_OPERATE_DOWM_PLAYER_GOD_STATUS, self.OnPlayerGodStatusChange)
    MonopolyData.UnRegisterMonopolyActionTable(DFW_OPERATE_DOWM_PLAYER_GOD_LEFTTIME, self.OnPlayerGodLeftTimeChange)
    MonopolyData.UnRegisterMonopolyActionTable(DFW_OPERATE_DOWM_PLAYER_HOSPITAL_STATUS, self.OnPlayerHospitalStatusChange)
    MonopolyData.UnRegisterMonopolyActionTable(DFW_OPERATE_DOWM_PLAYER_HOSPITAL_LEFTTIME, self.OnPlayerHospitalLeftTimeChange)
    MonopolyData.UnRegisterMonopolyActionTable(DFW_OPERATE_DOWM_PLAYER_MOVE_STATUS, self.OnPlayerMoveStatusChange)
    MonopolyData.UnRegisterMonopolyActionTable(DFW_OPERATE_DOWM_PLAYER_MOVE_LEFTTIME, self.OnPlayerMoveLeftTimeChange)

    -- 注销游戏阶段变更事件
    MonopolyData.UnRegisterMonopolyActionTable(DFW_OPERATE_DOWM_TABLE_STATE, self.OnTableStateChange)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIWidgetMonopolyPlayerList:UpdateInfo()
    
end

function UIWidgetMonopolyPlayerList:OnFrameBreathe()
    for _, item in pairs(self.tPlayerViewList) do
        if item and item.OnFrameBreathe then
            item:OnFrameBreathe()
        end
    end
end

function UIWidgetMonopolyPlayerList:EnsurePlayerViewList()
    self.scriptMine = self.scriptMine or UIHelper.AddPrefab(PREFAB_ID.WidgetRichman_Player, self.WidgetMine)
    
    local nClientPlayerIndex = MonopolyData.GetClientPlayerIndex()

    self.tPlayerViewList = {
        [nClientPlayerIndex] = self.scriptMine
    }
    UIHelper.RemoveAllChildren(self.LayoutTeammate)
    for i = 1, DFW_PLAYERNUM do
        if i ~= nClientPlayerIndex then
            local scriptPlayer = UIHelper.AddPrefab(PREFAB_ID.WidgetRichman_Player, self.LayoutTeammate)
            self.tPlayerViewList[i] = scriptPlayer
        end
        self.tPlayerViewList[i].nDfwIndex = i
    end

    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
    return true
end

function UIWidgetMonopolyPlayerList:UpdateViewMap()
    local tLogicToView = {}
    local tViewToLogic = {}
    
    local dwMyID = 0
    local pPlayer = GetClientPlayer()
    if pPlayer then
        dwMyID = pPlayer.dwID
    end

    local nMyLogicIndex = MonopolyData.GetClientPlayerIndex()
    -- if not nMyLogicIndex or nMyLogicIndex <= 0 or nMyLogicIndex > DFW_PLAYERNUM then
    --     nMyLogicIndex = 1
    -- end

    -- -- 自己固定在视图 1
    -- tLogicToView[nMyLogicIndex] = 1
    -- tViewToLogic[1] = nMyLogicIndex

    -- -- 剩下的按顺序排到视图 2-4
    -- local nNextViewIndex = 2
    -- for i = 1, DFW_PLAYERNUM do
    --     if i ~= nMyLogicIndex then
    --         tLogicToView[i] = nNextViewIndex
    --         tViewToLogic[nNextViewIndex] = i
    --         nNextViewIndex = nNextViewIndex + 1
    --     end
    -- end

    -- vk不管这些
    for i = 1, DFW_PLAYERNUM do
        tLogicToView[i] = i
        tViewToLogic[i] = i
    end

    return tLogicToView, tViewToLogic
end

-- 对外接口：显示金币变化飘字
-- nDfwIndex: 大富翁座位索引(1-4)
-- nChangeAmount: 变化的金币数(正数为获得，负数为失去)
function UIWidgetMonopolyPlayerList:ShowMoneyChange(nDfwIndex, nChangeAmount)
    if not nChangeAmount or nChangeAmount == 0 then
        return
    end

    -- TODO:跟交互商量接入金币变化飘字方案Tips
end

-- 对外接口：显示获得状态(Buff)提示
-- nDfwIndex: 大富翁座位索引(1-4)
-- nStatusType: 状态类型(1神仙 2行动 3入院或入狱)
-- nStatusID: 状态配置表(MonopolyStatusConfig.tab)中对应的 nID
function UIWidgetMonopolyPlayerList:ShowGetBuff(nDfwIndex, nStatusType, nStatusID)
    -- TODO：接入获取状态提示方案
end

function UIWidgetMonopolyPlayerList:Refresh()
    if not self:EnsurePlayerViewList() then
        return
    end
    
    -- 当全局刷新时，必须重新映射并全刷一遍，避免部分刷新错乱
    for nViewIndex = 1, DFW_PLAYERNUM do
        local item = self.tPlayerViewList[nViewIndex]
        if item then
            item.nDfwIndex = nViewIndex
            item:Refresh()
        end
    end
end

function UIWidgetMonopolyPlayerList:OnChangeBuff()
    self:Refresh()
end

-- 通过大富翁座位索引获取 PlayerView item
-- nDfwIndex: 大富翁座位索引(1-4)
-- 返回: PlayerView item 或 nil
function UIWidgetMonopolyPlayerList:GetItemByIndex(nDfwIndex)
    if not CheckDfwIndex(nDfwIndex) then
        return nil
    end

    return self.tPlayerViewList[nDfwIndex]
end

--------------------------事件/回调-------------------------------
-- 金币变更事件回调
-- arg3 = nDfwIndex(玩家索引), arg4 = nNewGold(新金币), arg5 = nOldGold(旧金币)
-- 若协议为 arg4=旧、arg5=新，请与服务器对齐后交换下面两行赋值
function UIWidgetMonopolyPlayerList:OnPlayerMoneyChange(nDfwIndex, nNewGold, nOldGold)
    if not CheckDfwIndex(nDfwIndex) then
        return
    end
    nNewGold = tonumber(nNewGold)
    nOldGold = tonumber(nOldGold) or 0

    local nChange = nNewGold - nOldGold

    -- 显示金币变化飘字
    if nChange ~= 0 then
        self:ShowMoneyChange(nDfwIndex, nChange)
    end

    -- 刷新所有玩家金币和排名
    for i = 1, DFW_PLAYERNUM do
        local item = self:GetItemByIndex(i)
        if item then
            item:RefreshMoneyAndRank()
        end
    end
end

-- 准备状态变更事件回调
-- arg3 = nPlayerIndex(玩家索引), arg4 = nReadyState(准备状态,1=已准备)
function UIWidgetMonopolyPlayerList:OnPlayerReadyChange(nPlayerIndex, nReadyState)
    if not CheckDfwIndex(nPlayerIndex) then
        return
    end

    local nMyDfwIndex = MonopolyData.GetClientPlayerIndex()

    if nMyDfwIndex == nPlayerIndex then
        -- 如果是自己准备状态改变，会影响所有人的交换按钮显示，因此刷新所有人
        for i = 1, DFW_PLAYERNUM do
            local item = self:GetItemByIndex(i)
            local tIdentityInfo = MonopolyData.GetIdentityInfoByDfwIndex(i)
            if item and tIdentityInfo then
                item:SetGameState(tIdentityInfo)
            end
        end
    else
        -- 如果是别人准备状态改变，只需刷新该玩家的状态
        local item = self:GetItemByIndex(nPlayerIndex)
        local tIdentityInfo = MonopolyData.GetIdentityInfoByDfwIndex(nPlayerIndex)
        if item and tIdentityInfo then
            item:SetGameState(tIdentityInfo)
        end
    end
end

-- 神仙状态变更回调
-- arg3 = nPlayerIndex, arg4 = nGodStatus（0=失去，非0=获得）
function UIWidgetMonopolyPlayerList:OnPlayerGodStatusChange(nPlayerIndex, nGodStatus)
    if not CheckDfwIndex(nPlayerIndex) then
        return
    end
    nGodStatus = tonumber(nGodStatus) or 0

    local item = self:GetItemByIndex(nPlayerIndex)
    if not item then
        return
    end

    -- 刷新该玩家的Buff显示
    item:RefreshNormalBuffs()

    -- 获得状态（非0）时，显示获得Buff提示
    if nGodStatus > 0 then
        self:ShowGetBuff(nPlayerIndex, 1, nGodStatus)
    end
end

-- 神仙剩余回合同步回调（只刷新显示，不触发获得提示）
-- arg3 = nPlayerIndex, arg4 = nLeftTime
function UIWidgetMonopolyPlayerList:OnPlayerGodLeftTimeChange(nPlayerIndex, nLeftTime)
    if not CheckDfwIndex(nPlayerIndex) then
        return
    end

    local item = self:GetItemByIndex(nPlayerIndex)
    if not item then
        return
    end

    -- 仅刷新Buff显示
    item:RefreshNormalBuffs()
end

-- 入院/入狱状态变更回调
-- arg3 = nPlayerIndex, arg4 = nHospitalStatus（0=失去，非0=获得）
function UIWidgetMonopolyPlayerList:OnPlayerHospitalStatusChange(nPlayerIndex, nHospitalStatus)
    if not CheckDfwIndex(nPlayerIndex) then
        return
    end
    nHospitalStatus = tonumber(nHospitalStatus) or 0

    local item = self:GetItemByIndex(nPlayerIndex)
    if not item then
        return
    end

    -- 刷新该玩家的Buff显示
    item:RefreshNormalBuffs()

    -- 获得状态（非0）时，显示获得Buff提示
    if nHospitalStatus > 0 then
        self:ShowGetBuff(nPlayerIndex, 3, nHospitalStatus)
    end
end

-- 入院/入狱剩余回合同步回调（只刷新显示，不触发获得提示）
-- arg3 = nPlayerIndex, arg4 = nLeftTime
function UIWidgetMonopolyPlayerList:OnPlayerHospitalLeftTimeChange(nPlayerIndex, nLeftTime)
    if not CheckDfwIndex(nPlayerIndex) then
        return
    end

    local item = self:GetItemByIndex(nPlayerIndex)
    if not item then
        return
    end

    -- 仅刷新Buff显示
    item:RefreshNormalBuffs()
end

-- 行动状态变更回调
-- arg3 = nPlayerIndex, arg4 = nMoveStatus（0=失去，非0=获得）
function UIWidgetMonopolyPlayerList:OnPlayerMoveStatusChange(nPlayerIndex, nMoveStatus)
    if not CheckDfwIndex(nPlayerIndex) then
        return
    end
    nMoveStatus = tonumber(nMoveStatus) or 0

    local item = self:GetItemByIndex(nPlayerIndex)
    if not item then
        return
    end

    -- 刷新该玩家的Buff显示
    item:RefreshNormalBuffs()

    -- 获得状态（非0）时，显示获得Buff提示
    if nMoveStatus > 0 then
        self:ShowGetBuff(nPlayerIndex, 2, nMoveStatus)
    end
end

-- 行动剩余回合同步回调（只刷新显示，不触发获得提示）
-- arg3 = nPlayerIndex, arg4 = nLeftTime
function UIWidgetMonopolyPlayerList:OnPlayerMoveLeftTimeChange(nPlayerIndex, nLeftTime)
    if not CheckDfwIndex(nPlayerIndex) then
        return
    end

    local item = self:GetItemByIndex(nPlayerIndex)
    if not item then
        return
    end

    -- 仅刷新Buff显示
    item:RefreshNormalBuffs()
end

-- 游戏阶段变更回调
-- arg3 = nTableState(新的游戏阶段)
function UIWidgetMonopolyPlayerList:OnTableStateChange(nTableState)
    nTableState = tonumber(nTableState)
    if not nTableState then
        return
    end

    -- 阶段变更时，刷新所有玩家的游戏状态显示（准备阶段/游戏阶段切换）
    for i = 1, DFW_PLAYERNUM do
        local item = self:GetItemByIndex(i)
        if item then
            local tIdentityInfo = MonopolyData.GetIdentityInfoByDfwIndex(i)
            if tIdentityInfo then
                item:SetGameState(tIdentityInfo)
            end
        end
    end
end


return UIWidgetMonopolyPlayerList