MonopolyData = MonopolyData or {className = "MonopolyData"}
local self = MonopolyData

-----------------------------常量定义------------------------------

-- 界面模式（名字对应 Scheme/Case/showmode.txt 的 NAME 列）
local PANEL_MODE = {
    MAIN       = "MonoPolyMain",           -- 主界面模式
    CARD_CLEAR = "MonoPolyClearObstacles", -- 清除障碍卡模式
    MINIGAME   = "MonoPolyGames",          -- 小游戏模式
    SETTLEMENT = "MonoPolyFinal",          -- 结算模式
}

-- VK tSubPanels 名字转换为VIEW_ID
local PANEL_CONVERT = {
    -- ["MonopolyReadyArea"] = 0,
    -- ["MonopolySelectDirection"] = 0,
    -- ["MonopolyDice"] = 0,
    -- ["CardEvent"] = 0,
    -- ["MonopolyAuctionInfoPanel"] = 0,
    -- ["FateEvents"] = 0,
    -- ["MonopolyChooseCard"] = 0,
    -- ["BuildGrid"] = 0,
    ["MonopolyCardShop"] = VIEW_ID.PanelRichMan_Store,
    ["MonopolyDaLeTouPanel"] = VIEW_ID.PanelRichMan_Lotto,
    -- ["Settlement"] = 0,
    -- ["EndGame"] = 0,
}

-- 右侧面板显示类型 string对应DX的面板名称
MonopolyRightEventType =
{
    SelectDirection = "MonopolySelectDirection", -- 选择方向
    CardCast = "MonopolyCardCast", -- 手牌使用[无目标]
    LandPurchase = "MonopolyLandPurchaseDlg", -- 购买空地
    TargetSelect = "MonopolyTargetSelectPanel", -- 选择玩家
    AuctionInfo = "MonopolyAuctionInfoPanel", -- 拍卖卡
    LandExchange = "MonopolyLandExchangeRequest", -- 换地卡
}

-- 拍卖面板在出价、等待、旁观和结果四种状态间切换。
MONOPOLY_AUCTION_STATE = {
    MY_BID  = 1,
    WAITING = 2,
    WATCH   = 3,
    RESULT  = 4,
}

-- 操作表：存储通过 RegisterMonopolyActionTable 注册的操作函数
-- 结构: {[nActionID] = {fnAction1, fnAction2, ...}}
-- key 为操作ID，value 为该操作ID对应的函数列表数组
local g_tMonopolyActionTable = {}

-- 玩法入口配置：后续复用该界面时只需在这里追加配置
MonopolyData.tQueuePlayConfig =
{
    [801] =
    {
        nPriority = 1,
        bEnableSingle = true,
        bEnableTeam = true,
        bEnableRoom = true,
    },
}

-- copy from DX Revision: 1838694
-----------------------------DataModel------------------------------
--分几种模式
--主界面上的东西永久打开，事件更新状态切换小界面显示
--切换小游戏等，就切换模式
--有主界面模式、清除障碍卡模式、小游戏模式、结算模式
local DataModel = {
    bOpen        = false,                      -- 是否已打开
    szPanelMode  = nil,                        -- 当前界面模式
    tSubPanels   = {},                         -- 当前打开的子面板集合 {[szName] = true}
    nTimeStamp   = 0,                          -- 倒计时
}

function DataModel.Init()
    DataModel.bOpen       = true
    DataModel.szPanelMode = nil
    DataModel.tSubPanels  = {}
    DataModel.nTimeStamp  = 0
    DataModel.GetClientPlayerIndex()
end

function DataModel.GetClientPlayerIndex()
    local nPlayerID = UI_GetClientPlayerID()
    for nIndex = 1, DFW_PLAYERNUM do
        local nID = DFW_GetPlayerDWID(nIndex)
        if nID == nPlayerID then
            DataModel.nClientPlayerIndex = nIndex
            return
        end
    end
end

function DataModel.UnInit()
    for i, v in pairs(DataModel) do
        if type(v) ~= "function" then
            DataModel[i] = nil
        end
    end
end

function DataModel.GetPanelMode()
    return DataModel.szPanelMode
end

function DataModel.GetMiniGameMgr()
    if not DataModel.MiniGameMgr then
        DataModel.MiniGameMgr = GetMiniGameMgr()
    end
    return DataModel.MiniGameMgr
end

--获取游戏阶段，对应DFW_CONST_TABLE_STATE_INIT等
function DataModel.GetGameState()
    local nTableState = DFW_GetTableState()
    DataModel.nTableState = nTableState
end

--获取当前行动玩家
function DataModel.GetCurrentPlayer()
    local nCurrentPlayerIndex = DFW_GetTableNow()
    if type(nCurrentPlayerIndex) ~= "number" then
        DataModel.nCurrentPlayerIndex = nil
        return nil
    end
    if nCurrentPlayerIndex <= 0 or nCurrentPlayerIndex > DFW_PLAYERNUM then
        DataModel.nCurrentPlayerIndex = nil
        return nil
    end
    DataModel.nCurrentPlayerIndex = nCurrentPlayerIndex
    return nCurrentPlayerIndex
end

--获取是否是我的回合
function DataModel.IsMyRound()
    local nClientPlayerIndex = DataModel.nClientPlayerIndex
    if not nClientPlayerIndex then
        DataModel.GetClientPlayerIndex()
        nClientPlayerIndex = DataModel.nClientPlayerIndex
    end

    if not nClientPlayerIndex then
        return false
    end

    local nCurrentPlayerIndex = DataModel.GetCurrentPlayer()
    if not nCurrentPlayerIndex then
        return false
    end

    return nCurrentPlayerIndex == nClientPlayerIndex
end

---------------------------MonopolyData-------------------------------
-- NOTE: 部分大富翁相关全局变量和全局函数塞在这里以下路径："scripts/MiniGame/DaFuWeng/IdentityCustomValueName.lua"
-- NOTE: 由于初始化时序问题，这里MonopolyData改成由MonopolyInitializer来在Game.Init()阶段require
function MonopolyData.Init()
    self.RegEvent()

    DataModel.Init()
    -- VK_TODO: 是否需要进801地图再切换界面
    self.SwitchPanelMode(PANEL_MODE.MAIN)
end

function MonopolyData.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)

    DataModel.UnInit()
end

function MonopolyData.RegEvent()
    -- VK_TODO: 是否需要进801地图再注册事件，离开再反注册？
    Event.Reg(self, "MINIGAME_OPERATE", function()
        self.OnServerMessage()
    end)
end

-----------------------------界面模式切换------------------------------
function MonopolyData.SwitchPanelMode(szMode)
    if DataModel.szPanelMode == szMode then
        return
    end
    if DataModel.szPanelMode then
        -- VK_TODO:
        -- Station.BackOrExitShowMode(DataModel.szPanelMode)
    end
    -- VK_TODO:
    -- Station.EnterShowMode(szMode)
    DataModel.szPanelMode = szMode
    FireUIEvent("DFW_PANEL_MODE_CHANGED", szMode)
end

function MonopolyData.SwitchPanelModeMain()
    self.SwitchPanelMode(PANEL_MODE.MAIN)
end

function MonopolyData.SwitchPanelModeCard()
    self.SwitchPanelMode(PANEL_MODE.CARD_CLEAR)
end

-- 切换子面板显示（差异更新）
-- tNewPanels: 新阶段需要打开的面板列表
-- 关闭不再需要的面板，保留重复的，打开新增的
function MonopolyData.SwitchSubPanels(tNewPanels)
    local tNewSet = {}
    for _, szName in ipairs(tNewPanels) do
        tNewSet[szName] = true
    end
    -- 关闭旧面板中不在新列表里的
    for szName, _ in pairs(DataModel.tSubPanels) do
        if not tNewSet[szName] then
            local nViewID = PANEL_CONVERT[szName]
            if nViewID then
                UIMgr.Close(nViewID)
            end
            if table.contain_value(MonopolyRightEventType, szName) then
                Event.Dispatch(EventType.OnMonopolyRightEventClose, szName)
            end
            DataModel.tSubPanels[szName] = nil
            -- FireUIEvent("DFW_SUB_PANEL_CLOSE", szName)
        end
    end
    -- 打开新列表中不在旧面板里的
    for _, szName in ipairs(tNewPanels) do
        local nViewID = PANEL_CONVERT[szName]
        if not DataModel.tSubPanels[szName] then
            DataModel.tSubPanels[szName] = true
            if nViewID and not UIMgr.IsViewOpened(nViewID) then
                local scriptView = UIMgr.Open(nViewID)
                if scriptView then
                    scriptView:OnEnter() -- 保证同帧初始化
                end
            end
            if table.contain_value(MonopolyRightEventType, szName) then
                Event.Dispatch(EventType.OnMonopolyRightEventOpen, szName)
            end
            -- FireUIEvent("DFW_SUB_PANEL_OPEN", szName)
        end
    end

    Event.Dispatch(EventType.OnMonopolySwitchSubPanels, tNewPanels)
end

-----------------------------下发消息表------------------------------
-- 每个下发消息视为一次阶段变化，描述：
--   nState     : 对应流程阶段（用于断线重连时恢复界面）
--   tPanels    : 切换到的子面板列表（nil 表示不切换面板 不包括主界面上的面板）
--   szMode     : 切换到的界面模式（nil 表示主界面模式PANEL_MODE.MAIN）
--   fnAction   : 收到消息后执行的具体操作（可选）
--   bOnlyAction: 仅执行 fnAction，不切换模式/阶段/子面板（可选）
local DOWN_EVENT_MAP = {
    [DFW_OPERATE_DOWM_INIT_GAME] = {
        -- 初始化流程同步
        nState = DFW_CONST_TABLE_STATE_INIT, -- 初始化阶段
        szMode  = PANEL_MODE.MAIN,
        fnAction = function()
        end,
    },
    [DFW_OPERATE_DOWM_PREPARE_BEGIN] = {
        -- 开启准备阶段
        nState = DFW_CONST_TABLE_STATE_PREPARE, -- 准备阶段
        tPanels = {"MonopolyReadyArea"},
        fnAction = function()
            -- TODO: 开启准备阶段，显示准备界面
        end,
    },
    [DFW_OPERATE_DOWM_PREPARE_READY] = {
        -- 同步准备结果
        fnAction = function()
            local nReadyDfwIndex = arg3
            local bReady = arg4 and arg4 ~= 0

            -- 仅处理本地玩家已准备的消息(非本地玩家的准备广播在这里忽略)
            if nReadyDfwIndex == DataModel.nClientPlayerIndex and bReady then
                -- 自己准备,更新准备按钮
                Event.Dispatch(EventType.OnMonopolyOperateDownprepareReady, nReadyDfwIndex, bReady)

                -- 自己准备,关闭交换申请Buff弹窗
                -- VK_TODO:
                -- MonopolyChangeBuffRequest.Close()
            end
        end,
        bOnlyAction = true, -- 仅执行操作，不切换面板（因为准备阶段只有一个面板）
    },
    [DFW_OPERATE_DOWM_DIRECTION_BEGIN] = {
        -- 开启前进方向选择
        tPanels = {"MonopolySelectDirection"},
        fnAction = function()

        end,
    },
    [DFW_OPERATE_DOWM_PLAYER_DIRECTION] = {
        -- 设置前进方向同步
        fnAction = function()
            local nPlayerIndex = arg3
            if nPlayerIndex == DataModel.nClientPlayerIndex then
                Event.Dispatch(EventType.OnMonopolyRightEventClose, MonopolyRightEventType.SelectDirection)
            end
        end,
        bOnlyAction = true,
    },
    [DFW_OPERATE_DOWN_EXCHANGE_LAUNCH] = {
        -- 交换能力启动下发
        fnAction = function()
            -- 打开交换能力申请弹窗
            -- Output('交换：发起者=' .. arg3 .. '，接收者=' .. arg4)
            local nSrcDfwIndex = arg3 -- 发起者
            local nDstDfwIndex = arg4 -- 接收者
            if nDstDfwIndex == DataModel.nClientPlayerIndex then
                -- VK_TODO:
                -- MonopolyChangeBuffRequest.Open(nSrcDfwIndex, nDstDfwIndex)
            end
        end,
        bOnlyAction = true,
    },
    [DFW_OPERATE_DOWN_EXCHANGE_CONFIRM] = {
        -- 交换能力确认下发
        fnAction = function()
            -- VK_TODO:
            -- MonopolyChangeBuffRequest.Close()

            Event.Dispatch(EventType.OnMonopolyPlayerListOnChangeBuff)
        end,
        bOnlyAction = true,
    },
    [DFW_OPERATE_DOWN_EXCHANGE_CANCEL] = {
        -- 取消交换能力下发（其实是拒绝）
        fnAction = function()
            -- VK_TODO:
            -- MonopolyChangeBuffRequest.Close()
        end,
        bOnlyAction = true,
    },
    [DFW_OPERATE_DOWM_ACTION_BEGIN] = {
        -- 开启行动阶段
        nState = DFW_CONST_TABLE_STATE_ACTION, -- 行动阶段
        tPanels = {"MonopolyDice"},
        fnAction = function()
            -- TODO: 开启行动阶段，显示手牌和操作按钮
        end,
    },
    [DFW_OPERATE_DOWM_ACTION_SELECTCARD] = {
        -- 选中牌同步
        fnAction = function()
            if arg3 == DataModel.nClientPlayerIndex then
                Event.Dispatch(EventType.OnMonopolyCardListUpdateSelectCard, arg4)
            end
        end,
        bOnlyAction = true,
    },
    [DFW_OPERATE_DOWM_ACTION_CARDTOGRID] = {
        -- 卡牌选中地块（对地块使用）
        fnAction = function()
            if not self.IsMyRound() then
                return
            end

            local nCardID = arg3

            Event.Dispatch(EventType.OnMonopolyRightEventClose, MonopolyRightEventType.TargetSelect)
            -- VK_TODO:
            -- Monopoly_GridHighlight.ShowHighlight(nCardID) -- 显示地块高亮
        end,
        bOnlyAction = true,
    },
    [DFW_OPERATE_DOWM_ACTION_CARDTOPLAYER] = {
        -- 卡牌选中玩家（对玩家使用）
        fnAction = function()
            if not self.IsMyRound() then
                return
            end

            local nCardID = arg3
            Event.Dispatch(EventType.OnMonopolyRightEventOpen, MonopolyRightEventType.TargetSelect, nCardID)
        end,
        bOnlyAction = true,
    },
    [DFW_OPERATE_DOWM_ACTION_CARDNOTARGET] = {
        -- 卡牌不指定目标（无目标使用）
        fnAction = function()
            if not self.IsMyRound() then
                return
            end

            local nCardID = arg3
            -- Output("[大富翁-主逻辑] 卡牌无目标 卡牌ID=" .. tostring(nCardID))

            Event.Dispatch(EventType.OnMonopolyRightEventClose, MonopolyRightEventType.TargetSelect)
            -- VK_TODO:
            -- MonopolyCardUseConfirm.Open(nCardID)
        end,
        bOnlyAction = true,
    },
    [DFW_OPERATE_DOWM_ACTION_PLAYCARD] = {
        -- 卡牌打出完成(统一下行,广播给所有人)
        -- 参数:arg3=出牌者DfwIndex  arg4=nCardID  arg5=nCardSlot  arg6=nTargetParam(GridID/DfwIndex)  arg7=nTargetType
        fnAction = function()
            local nSrcPlayerIndex = arg3
            local nCardID         = arg4
            -- Output("[大富翁-主逻辑] 卡牌打出完成 PlayerIndex=" .. tostring(nSrcPlayerIndex) .. " CardID=" .. tostring(nCardID))

            -- 仅出牌者自己需要收掉本地选牌相关 UI(广播 -1,非本方不处理)
            if nSrcPlayerIndex == DataModel.nClientPlayerIndex then
                -- VK_TODO:
                -- Monopoly_GridHighlight.HideHighlight()   -- 取消地块高亮
                -- MonopolyCardUseConfirm.Close()           -- 关闭无目标使用弹窗
                Event.Dispatch(EventType.OnMonopolyRightEventClose, MonopolyRightEventType.TargetSelect)  -- 关闭对玩家选择面板
            end

            -- TODO: 无论谁出牌,后续可在此接入卡牌动画/特效/飘字
        end,
        bOnlyAction = true,
    },
    [DFW_OPERATE_DOWM_ACTION_CANCELCARD] = {
        -- 取消选中同步
        fnAction = function()
            if not self.IsMyRound() then
                return
            end
            -- VK_TODO:
            -- Monopoly_GridHighlight.HideHighlight()   -- 取消地块高亮
            Event.Dispatch(EventType.OnMonopolyRightEventClose, MonopolyRightEventType.TargetSelect)   -- 关闭对玩家选择面板
            -- VK_TODO:
            -- MonopolyCardUseConfirm.Close()            -- 关闭无目标使用弹窗
            Event.Dispatch(EventType.OnMonopolyCardListUpdateSelectCard, 0)      -- 清手牌选中态
        end,
        bOnlyAction = true,
    },
    [DFW_OPERATE_DOWM_ACTION_OBTAINCARD] = {
        -- 获得牌同步
        fnAction = function()
            -- TODO: 获得牌同步

            Event.Dispatch(EventType.OnMonopolyCardListUpdateCardList)
        end,
        bOnlyAction = true,
    },
    [DFW_OPERATE_DOWM_ACTION_ROLLDICE] = {
        -- 骰子点数同步
        tPanels = {"MonopolyDice"},
        fnAction = function()
            if arg3 == DataModel.nClientPlayerIndex then
                Event.Dispatch(EventType.OnMonopolyBeginDiceShow)
            end
        end,
    },
    [DFW_OPERATE_DOWM_CARDEVENT_BEGIN] = {
        -- 卡牌事件开始
        nState = DFW_CONST_TABLE_STATE_CARDEVENT, -- 卡牌事件阶段
        tPanels = {"CardEvent"},
        fnAction = function()
            -- TODO: 卡牌事件开始，显示发起的卡牌和目标对象
        end,
    },
    [DFW_OPERATE_DOWM_CARDEVENT_COUNTET] = {
        -- 卡牌事件反制同步
        fnAction = function()
            -- TODO: 卡牌事件反制，显示反制卡牌
        end,
    },
    [DFW_OPERATE_DOWM_CARDEVENT_END] = {
        -- 卡牌事件结束同步
        fnAction = function()
            -- TODO: 卡牌事件结束，关闭卡牌事件面板
        end,
    },
    [DFW_OPERATE_DOWM_CARDSHOW] = {
        -- 卡牌展示阶段动画展示
        -- nState = DFW_CONST_TABLE_STATE_CARDSHOW, -- 卡牌展示阶段
        fnAction = function()
            -- TODO: 播放卡牌动画展示
            if arg3 == DataModel.nClientPlayerIndex then
                Event.Dispatch(EventType.OnMonopolyRightEventOpen, MonopolyRightEventType.CardCast, arg4)
            end
        end,
    },
    [DFW_OPERATE_DOWM_AUCTION_GRID] = {
        -- 拍卖地块下发
        nState = DFW_CONST_TABLE_STATE_AUCTION, -- 拍卖阶段
        tPanels = {"MonopolyAuctionInfoPanel"},
        fnAction = function()
            -- TODO: 拍卖阶段开始，显示拍卖界面
        end,
    },
    [DFW_OPERATE_DOWM_AUCTION_BID] = {
        -- 拍卖出价同步
        fnAction = function()
            -- TODO: 拍卖出价，更新当前出价显示
            Event.Dispatch(EventType.OnMonopolySetAuctionState, MONOPOLY_AUCTION_STATE.WATCH)
        end,
        bOnlyAction = true,
    },
    [DFW_OPERATE_DOWM_AUCTION_FALL] = {
        -- 拍卖出价同步
        fnAction = function()
            -- TODO: 拍卖出价，更新当前出价显示
            Event.Dispatch(EventType.OnMonopolySetAuctionState, MONOPOLY_AUCTION_STATE.WAITING)
        end,
        bOnlyAction = true,
    },
    [DFW_OPERATE_DOWM_AUCTION_END] = {
        -- 拍卖结束
        fnAction = function()
            -- TODO: 拍卖结束，显示结果
            Event.Dispatch(EventType.OnMonopolySetAuctionState, MONOPOLY_AUCTION_STATE.RESULT)
        end,
        bOnlyAction = true,
    },
    [DFW_OPERATE_DOWM_MOVE_BEGIN] = {
        -- 移动阶段开始
        nState = DFW_CONST_TABLE_STATE_MOVE, -- 移动阶段
        fnAction = function()
            -- TODO: 移动阶段开始
        end,
    },
    [DFW_OPERATE_DOWM_MOVE_NEXT] = {
        -- 向前移动一格
        fnAction = function()
            -- TODO: 向前移动一格，播放移动动画
        end,
    },
    [DFW_OPERATE_DOWM_ROUNDEND_BEGIN] = {
        -- 回合结束阶段开始
        nState = DFW_CONST_TABLE_STATE_ROUNDEND, -- 回合结束阶段
        fnAction = function()
            -- TODO: 回合结束处理
            Event.Dispatch(EventType.OnMonopolyRightEventClose, MonopolyRightEventType.LandPurchase) -- 关闭购买空地弹窗

            -- 命运事件
            local nFateEventID = DFW_GetTableFateGlobalID()
            if nFateEventID > 0 then
                -- VK_TODO:
                -- MonopolyFateEvent.Open()
            end
        end,
    },
    [DFW_OPERATE_DOWM_FATEEVENTS_BEGIN] = {
        -- 命运事件开始
        fnAction = function()
            -- VK_TODO:
            -- MonopolyFateEvent.Open()
        end,
        bOnlyAction = true,
    },
    [DFW_OPERATE_DOWM_FATEEVENTS_CHOOSEN] = {
        -- 命运事件选择同步
        fnAction = function()
            -- 参数顺序：事件ID、触发玩家ID、结果ID
            -- VK_TODO:
            -- MonopolyFateEvent.RefreshChoose(arg3, arg4, arg5)
        end,
        bOnlyAction = true,
    },
    [DFW_OPERATE_DOWM_FATEEVENTS_CLOSE] = {
        -- 命运事件关闭同步
        fnAction = function()
            -- VK_TODO:
            -- MonopolyFateEvent.Close()
        end,
        bOnlyAction = true,
    },
    -- DX 1837624版本把这里注释掉了，VK这边也先跟着注释一下
    -- [DFW_OPERATE_DOWM_DISCARD_CHOOSE] = {
    --     -- 丢弃卡牌开始
    --     nState = DFW_CONST_TABLE_STATE_DISCARD, -- 丢弃卡牌阶段
    --     tPanels = {"MonopolyChooseCard"},
    --     fnAction = function()
    --         -- TODO: 丢弃卡牌开始，显示当前手牌让玩家选择丢弃
    --     end,
    -- },
    -- [DFW_OPERATE_DOWM_DISCARD_CONFIRM] = {
    --     -- 丢弃卡牌确认同步
    --     fnAction = function()
    --         -- TODO: 丢弃卡牌确认，更新手牌数据
    --         -- VK_TODO:
    --         -- MonopolyChooseCard.Close(true)

    --         Event.Dispatch(EventType.OnMonopolyCardListUpdateCardList)
    --     end,
    -- },
    [DFW_OPERATE_DOWM_PLAYER_GOD_STATUS] = {
        -- 神仙时间开始（纯表现）
        fnAction = function()
            -- VK_TODO:
            -- MonopolyGodNotify.Open(arg0, arg1)
        end,
    },
    [DFW_OPERATE_DOWM_BUILDGRID_BEGIN] = {
        -- 购买空地阶段开始
        nState = DFW_CONST_TABLE_STATE_BUILDGRID, -- 购买地块阶段
        tPanels = {"BuildGrid"},
        -- arg3=nType（0/1=购买，2=升级），目标地块是本地玩家当前位置
        fnAction = function()
            local nType = arg3
            local nClientIdx = DataModel.nClientPlayerIndex
            if not nClientIdx or nClientIdx <= 0 then
                return
            end
            local nGridIndex = DFW_GetPlayerGridIndex(nClientIdx) or 0

            -- 打开购买或升级地的界面
            Event.Dispatch(EventType.OnMonopolyRightEventOpen, MonopolyRightEventType.LandPurchase, nGridIndex, nType)
        end,
    },
    [DFW_OPERATE_DOWM_BUILDGRID_CONFIRM] = {
        -- 购买确认同步
        fnAction = function()
            Event.Dispatch(EventType.OnMonopolyRightEventClose, MonopolyRightEventType.LandPurchase) -- 关闭购买空地弹窗
        end,
    },
    [DFW_OPERATE_DOWM_BUILDGRID_CANCEL] = {
        -- 取消购买同步
        fnAction = function()
            Event.Dispatch(EventType.OnMonopolyRightEventClose, MonopolyRightEventType.LandPurchase) -- 关闭购买空地弹窗
        end,
    },
    [DFW_OPERATE_DOWM_GRID_DATA] = {
        -- 地图格子数据同步（买地、升级、换主人、破产、叠加物变更等统一下发）
        -- arg3=nGridID  arg4=nOwnerPlayerIndex  arg5=nLevel  arg6=nOverlayLayerID
        -- 统一通知 dummy 场景脚本刷新两项表现：建筑等级、主人高亮色框、叠加物
        fnAction = function()
            local nGridID  = arg3
            local nOwner   = arg4 or 0
            local nLevel   = arg5 or 0
            local nOverlay = arg6 or 0
            if not nGridID or nGridID <= 0 then
                return
            end
            local szNickName = self.GridToDummyNickName(nGridID)
            if szNickName == "" then
                return
            end
            self.NotifyDummyScriptByNickName(szNickName, "OnGridRefresh", nOwner, nLevel, nOverlay)
        end,
        bOnlyAction = true,
    },
    [DFW_OPERATE_DOWM_STROE_BEGIN] = {
        -- 商店阶段开始
        nState = DFW_CONST_TABLE_STATE_STROE, -- 商店阶段
        tPanels = {"MonopolyCardShop"},
        fnAction = function()
            -- TODO: 商店阶段开始，从服务器获取商店数据
        end,
    },
    [DFW_OPERATE_DOWM_STROE_BUY] = {
        -- 购买卡牌同步
        fnAction = function()
            Event.Dispatch(EventType.OnMonopolyShopRefreshAfterBuy)
        end,
    },
    [DFW_OPERATE_DOWM_STROE_SELL] = {
        -- 卖出卡牌同步
        fnAction = function()
            Event.Dispatch(EventType.OnMonopolyShopRefreshAfterSell)
        end,
    },
    [DFW_OPERATE_DOWM_STROE_CLOSE] = {
        -- 关闭商店同步
        fnAction = function()

        end,
    },
    [DFW_OPERATE_DOWM_LOTTERYBET_BEGIN] = {
        -- 大乐透阶段开始
        nState = DFW_CONST_TABLE_STATE_LOTTERYBET, -- 大乐透阶段
        tPanels = {"MonopolyDaLeTouPanel"},
        fnAction = function()
            Event.Dispatch(EventType.OnMonopolyLotteryBegin)
            -- TODO: 大乐透阶段，从服务器获取大乐透数据
        end,
    },
    [DFW_OPERATE_DOWM_PLAYER_LOTTERY_CHOOSEN] = {
        -- 押注选择同步
        fnAction = function()
            Event.Dispatch(EventType.OnMonopolyLotteryUpdataPlayerChoosen, arg3)
        end,
        bOnlyAction = true,
    },
    [DFW_OPERATE_DOWM_LOTTERYBET_CLOSE] = {
        -- 大乐透关闭同步
        fnAction = function()
            -- TODO: 大乐透关闭
        end,
    },
    [DFW_OPERATE_DOWM_LOTTERYDRAW_BEGIN] = {
        -- 大乐透开奖（中奖号在参数里）
        nState = DFW_CONST_TABLE_STATE_LOTTERYDRAW, -- 大乐透开奖阶段
        tPanels = {"MonopolyDaLeTouPanel"},
        fnAction = function()
            Event.Dispatch(EventType.OnMonopolyLotterySwitchToResultStage)
        end,
    },
    [DFW_OPERATE_DOWM_MINIGAME_BEGIN] = {
        -- 小游戏开始
        nState = DFW_CONST_TABLE_STATE_MINIGAME, -- 小游戏阶段
        szMode  = PANEL_MODE.MINIGAME,
        fnAction = function()
            -- TODO: 小游戏开始，根据 nMiniGameID 加载对应小游戏
        end,
    },
    [DFW_OPERATE_DOWM_MINIGAME_END] = {
        -- 小游戏结束
        szMode  = PANEL_MODE.MAIN,
        fnAction = function()
            -- TODO: 小游戏结束，回到主界面
        end,
    },
    [DFW_OPERATE_DOWM_SETTLEMENT_MINIGAME] = {
        -- 小游戏结算
        nState = DFW_CONST_TABLE_STATE_SETTLEMENT, -- 结算阶段
        szMode  = PANEL_MODE.SETTLEMENT,
        tPanels = {"Settlement"},
        fnAction = function()
            -- TODO: 小游戏结算界面
        end,
    },
    [DFW_OPERATE_DOWM_ENDGAME] = {
        -- 大富翁结束
        nState = DFW_CONST_TABLE_STATE_ENDGAME, -- 游戏结束阶段
        szMode  = PANEL_MODE.SETTLEMENT,
        tPanels = {"EndGame"},
        fnAction = function()
            -- TODO: 大富翁结算界面
        end,
    },
    [DFW_OPERATE_DOWM_OPERATE_TIME] = {
        -- 通用倒计时同步
        fnAction = function()
            --if DataModel.IsMyRound() then
                Event.Dispatch(EventType.OnMonopolyOperateDownCountDown)
            --end
        end,
        bOnlyAction = true,
    },
    [DFW_OPERATE_DOWM_OPERATE_TIPS_MSG] = {
        -- 提示信息tips
        fnAction = function()
            -- VK_TODO:
            -- MonopolyNotify.ShowNotify(arg3, arg4, arg5, arg6)
        end,
        bOnlyAction = true,
    },

    --- 数据变化事件 ---
    [DFW_OPERATE_DOWM_TABLE_STATE] = {
        -- 游戏阶段同步
        fnAction = function()
            DataModel.GetGameState()
        end,
        bOnlyAction = true,
    },

    [DFW_OPERATE_DOWM_TABLE_NOW] = {
        -- 当前行动玩家同步
        fnAction = function()
            local nCurDfwIndex = DataModel.GetCurrentPlayer()
            local bIsMyRound = DataModel.IsMyRound()

            Event.Dispatch(EventType.OnMonopolyCurrentPlayerChanged, nCurDfwIndex, bIsMyRound)
        end,
        bOnlyAction = true,
    },
    [DFW_OPERATE_DOWM_TABLE_ROUND] = {
        -- 当前回合同步
        fnAction = function()
            Event.Dispatch(EventType.OnMonopolyInfoRoundChanged)
        end,
        bOnlyAction = true,
    },
    [DFW_OPERATE_DOWM_TABLE_PRICE_MULI] = {
        -- 物价指数同步
        fnAction = function()
            Event.Dispatch(EventType.OnMonopolyInfoRoundChanged)
        end,
        bOnlyAction = true,
    },
    [DFW_OPERATE_DOWM_PLAYER_POINT_NUM] = {
        -- 玩家点数变化同步
        fnAction = function()
            Event.Dispatch(EventType.OnMonopolyUpdatePlayerPointNum)
        end,
        bOnlyAction = true,
    },
    [DFW_OPERATE_DOWM_PLAYER_MONEY] = {
        fnAction = function()
            Event.Dispatch(EventType.OnMonopolyUpdatePlayerMoney)
        end,
        bOnlyAction = true,
    },
}

local function ApplyDownEventConfig(tConfig, nFallbackState)
    if not tConfig then
        return
    end

    if not tConfig.bOnlyAction then
        Event.Dispatch(EventType.OnMonopolyRightEventClose, MonopolyRightEventType.TargetSelect)

        local szMode = tConfig.szMode or PANEL_MODE.MAIN
        if szMode then
            self.SwitchPanelMode(szMode)
        end
        if tConfig.tPanels then
            self.SwitchSubPanels(tConfig.tPanels)
        end
    end

    if tConfig.fnAction then
        tConfig.fnAction()
    end
end

-----------------------------统一下发消息分发------------------------------
function MonopolyData.OnServerMessage()
    local nGameType, nPlayerID, nOperationType = arg0, arg1, arg2
    if nGameType ~= 3 or not nOperationType then
        return
    end

    LOG.INFO("[MonopolyData] OnServerMessage, nPlayerID: %s, nOperationType: %s; Args: %s, %s, %s, %s, %s", 
    tostring(arg1), tostring(arg2), tostring(arg3), tostring(arg4), tostring(arg5), tostring(arg6), tostring(arg7))

    local tConfig = DOWN_EVENT_MAP[nOperationType]

    -- 如果在DOWN_EVENT_MAP中有配置，先应用配置（切换界面模式/面板等）
    if tConfig then
        ApplyDownEventConfig(tConfig, nOperationType)
    end

    -- 执行注册的操作表中的函数（即使不在DOWN_EVENT_MAP中定义的事件也会触发）
    if g_tMonopolyActionTable and g_tMonopolyActionTable[nOperationType] then
        local tActionList = g_tMonopolyActionTable[nOperationType]
        for _, tInfo in ipairs(tActionList) do
            local fnAction = tInfo.fnAction
            local script = tInfo.script
            if type(fnAction) == "function" then
                local bSuccess, szError
                if script then
                    bSuccess, szError = pcall(fnAction, script, arg3, arg4, arg5, arg6, arg7) -- self:XXX()
                else
                    bSuccess, szError = pcall(fnAction, arg3, arg4, arg5, arg6, arg7)
                end
                if not bSuccess then
                    LOG.INFO("[MonopolyData] ActionTable 执行错误, 错误: " .. tostring(szError))
                end
            end
        end
    end
end

-----------------------------公共接口------------------------------

-- 获取本地玩家对应的小游戏Index
function MonopolyData.GetClientPlayerIndex()
    return DataModel.nClientPlayerIndex
end

-- 获取当前行动玩家的小游戏Index
function MonopolyData.GetCurrentPlayer()
    return DataModel.GetCurrentPlayer()
end

-- 判断当前是否为本地玩家回合
function MonopolyData.IsMyRound()
    return DataModel.IsMyRound()
end

-- 通过 ullTemplateID 解析大富翁实际的地块 ID
-- Dummy的ullTemplateID为64位整型：高32位表示地图ID(mapID)，低32位表示地块ID(tableID)
function MonopolyData.GetDummyGridID(ullTemplateID)
    if not ullTemplateID then
        return nil
    end
    -- 获取高32位 (mapID)
    local mapID = math.floor(ullTemplateID / 4294967296)
    -- 获取低32位 (tableID)
    local tableID = ullTemplateID % 4294967296

    if mapID == 801 then
        return tableID
    end

    return nil
end

-- 通过地块 ID 获取 Dummy 的别名（例如：1 -> DFW_Road1）
function MonopolyData.GridToDummyNickName(nGridID)
    if not nGridID then
        return ""
    end
    local tGridConfig = Table_GetMonopolyGridConfigByID(nGridID)
    if tGridConfig and tGridConfig.szDummyName then
        return tGridConfig.szDummyName
    end
    return ""
end

-- 通过地块 ID 获取该格子绑定的建筑 Dummy 别名（如果没有建筑则为空）
function MonopolyData.GridToBuildingDummyNickName(nGridID)
    if not nGridID then
        return ""
    end
    local tGridConfig = Table_GetMonopolyGridConfigByID(nGridID)
    if tGridConfig and tGridConfig.szBuildingDummyName then
        return tGridConfig.szBuildingDummyName
    end
    return ""
end

-- 获取身份信息
function MonopolyData.GetIdentityInfoByDfwIndex(nDfwIndex)
    if not nDfwIndex then
        nDfwIndex = self.GetClientPlayerIndex()
    end
    if not nDfwIndex or nDfwIndex <= 0 or nDfwIndex > DFW_PLAYERNUM then
        return nil
    end

    local nIdentityID = DFW_GetPlayerStatusIndex(nDfwIndex)
    if not nIdentityID or nIdentityID == 0 then
        return nil
    end
    return Table_GetMonopolyInitIdentityConfigByID(nIdentityID)
end

-- 获取玩家名称
function MonopolyData.GetNameByDfwIndex(nDfwIndex)
    local szName = ""
    local dwPlayerID = DFW_GetPlayerDWID(nDfwIndex)
    if dwPlayerID and dwPlayerID > 0 then
        local tTeamInfo = GetClientTeam().GetMemberInfo(dwPlayerID)
        if tTeamInfo then
            szName = tTeamInfo.szName or ""
        end
    end
    return szName
end

-- VK_TODO:
-- 通知 Dummy 的表现脚本
function MonopolyData.NotifyDummyScript(dwDummyID, szEventName, nParam1, nParam2, nParam3)
    if not dwDummyID or not szEventName then 
        return 
    end

    local szCommand = string.format(
        "CallDummyScriptByLocalID(%u,'OnUINotify','%s', %d, %d, %d)", 
        dwDummyID, 
        szEventName, 
        nParam1 or 0, 
        nParam2 or 0, 
        nParam3 or 0
    )
    ExecuteRepresentLua(szCommand)
end

-- 通过别名通知 Dummy 的表现脚本（无需 dwDummyID）
function MonopolyData.NotifyDummyScriptByNickName(szNickName, szEventName, nParam1, nParam2, nParam3)
    if not szNickName or szNickName == "" or not szEventName then
        return
    end
    local szCommand = string.format(
        "CallDummyScriptByNickName('%s','OnUINotify','%s',%d,%d,%d)",
        szNickName, szEventName,
        nParam1 or 0, nParam2 or 0, nParam3 or 0
    )
    ExecuteRepresentLua(szCommand)
end

-- 大富翁场景 Dummy 鼠标进入（仅地图 801）
function MonopolyData.OnMouseEnterDummy(dwDummyID, ullTemplateID)
    -- LOG.INFO("OnMouseEnterDummy: " .. dwDummyID)

    -- 显示高亮
    local argb = {160, 150,  255, 180}
    Dummy_SetOutline(dwDummyID, 5, argb[1], argb[2], argb[3], argb[4], false)

    -- 显示大富翁 tip
    local nGridID = self.GetDummyGridID(ullTemplateID)
    -- 悬停在"卡牌选地块态"下的可用格子 → 切黄色
    -- VK_TODO:
    -- if nGridID and nGridID > 0 and Monopoly_GridHighlight.IsShowing() and Monopoly_GridHighlight.IsPlayableGrid(nGridID) then
    --     self.SetGridHighlight(nGridID, 1) -- 黄
    -- end
    if nGridID and nGridID > 0 then
        local tGridData = DFW_GetGridData(nGridID)
        if tGridData then
            local nOwnerIndex       = tGridData[1] -- 玩家索引
            local nLevel            = tGridData[2] -- 建筑等级
            local nOverlayLayerID   = tGridData[3] -- 叠加层ID

            -- VK_TODO:
            -- local x, y = Cursor.GetPos(false)
            -- local tRect = {x, y, 50, 50}
            -- local nPosType = ALW.RIGHT_LEFT_AND_BOTTOM_TOP

            -- 叠加物信息
            local tOverlayInfo = nil
            if nOverlayLayerID and nOverlayLayerID > 0 then
                local tGridLayerConfig = Table_GetMonopolyGridLayerConfigByID(nOverlayLayerID)
                if tGridLayerConfig then
                    tOverlayInfo = {
                        szTitle = tGridLayerConfig.szName or "",
                        szDesc  = tGridLayerConfig.szDesc or "",
                    }
                end
            end

            -- 地块本体信息
            local szTitle = ""
            local szDesc = ""
            local nGridType = 1
            local tGridConfig = Table_GetMonopolyGridConfigByID(nGridID)
            if tGridConfig then
                szTitle = tGridConfig.szName
                szDesc = tGridConfig.szDesc
                nGridType = tGridConfig.nGridType or 1
            end

            local tGridInfo = nil
            if nGridType == 1 then
                if nOwnerIndex > 0 then
                    local szOwnerName = self.GetNameByDfwIndex(nOwnerIndex)
                    local szLevelText = nLevel .. "级房屋"
                    tGridInfo = {
                        nType = 2,
                        szTitle = szTitle,
                        szOwnerName = szOwnerName,
                        szMessage = szLevelText,
                        szPriceTitle = g_tStrings.STR_MONOPOLY_RENT,
                        nPrice = 0,
                        bShowOwner = true,
                        bShowPrice = true,
                    }
                else
                    tGridInfo = {
                        nType = 1,
                        szTitle = szTitle,
                        szOwnerName = "",
                        szMessage = g_tStrings.STR_MONOPOLY_EMPTY_LAND,
                        szPriceTitle = g_tStrings.STR_MONOPOLY_SALE_PRICE,
                        nPrice = 0,
                        bShowOwner = false,
                        bShowPrice = true,
                    }
                end
            elseif nGridType == 2 then
                tGridInfo = {
                    nType = 3,
                    szTitle = szTitle,
                    szOwnerName = "",
                    szMessage = szDesc,
                    szPriceTitle = "",
                    nPrice = 0,
                    bShowOwner = false,
                    bShowPrice = false,
                }
            end

            -- 同时存在叠加物 + 地块本体 → 合显
            if tGridInfo and tOverlayInfo then
                -- VK_TODO:
                -- MonopolyTip.ShowGridTipWithOverlay(tGridInfo, tOverlayInfo, tRect, nPosType)
            elseif tOverlayInfo then
                -- 仅叠加物
                -- VK_TODO:
                -- MonopolyTip.ShowEventTip(tOverlayInfo.szTitle, tOverlayInfo.szDesc, tRect, nPosType)
            elseif tGridInfo then
                -- 仅地块本体（走原入口保持旧表现）
                if tGridInfo.nType == 2 then
                    -- VK_TODO:
                    -- MonopolyTip.ShowOwnedBuildingTip(tGridInfo.szTitle, tGridInfo.szOwnerName, tGridInfo.nPrice, tGridInfo.szMessage, tRect, nPosType)
                elseif tGridInfo.nType == 1 then
                    -- VK_TODO:
                    -- MonopolyTip.ShowEmptyLandTip(tGridInfo.szTitle, tGridInfo.nPrice, tRect, nPosType)
                else
                    -- VK_TODO:
                    -- MonopolyTip.ShowEventTip(tGridInfo.szTitle, tGridInfo.szMessage, tRect, nPosType)
                end
            end
        end
    end

    -- 通知dummy的表现脚本
    self.NotifyDummyScript(dwDummyID, "OnMouseEnter")
end

-- 大富翁场景 Dummy 鼠标离开（仅地图 801）
function MonopolyData.OnMouseLeaveDummy(dwDummyID, ullTemplateID)
    -- Output("OnMouseLeaveDummy: " .. dwDummyID)

    -- 隐藏轮廓
    Dummy_SetOutline(dwDummyID, 0, 0, 0, 0, 0)

    -- 关闭Tip
    -- VK_TODO:
    -- MonopolyTip.Hide()

    -- 离开时若仍处于"卡牌选地块态"，把可用格子回滚到蓝色
    local nGridID = self.GetDummyGridID(ullTemplateID)
    -- VK_TODO:
    -- if nGridID and nGridID > 0 and Monopoly_GridHighlight.IsShowing() and Monopoly_GridHighlight.IsPlayableGrid(nGridID) then
    --     self.SetGridHighlight(nGridID, 2) -- 蓝
    -- end

    -- 通知dummy的表现脚本
    self.NotifyDummyScript(dwDummyID, "OnMouseLeave")
end

function MonopolyData.OnMouseClickDummy(dwDummyID, ullTemplateID, bLButtonUp)
    -- LOG.INFO("OnMouseClickDummy: " .. dwDummyID)

    -- 左键抬起时,若当前处于"对地块选牌态"且点中的是服务端下发的高亮可选地块,
    -- 则上行 PLAYCARDTOGRID(nCardID, nGridID) 把卡牌打在该地块上。
    -- 注意:校验失败不 return,继续走场景 Dummy 表现脚本的 OnMouseClick(如选中轮廓)。
    if bLButtonUp and self.IsMyRound() and self.GetGameState() == DFW_CONST_TABLE_STATE_ACTION then
        local nGridID = self.GetDummyGridID(ullTemplateID)
        -- VK_TODO:
        local nCardID = MonopolyData.MonopolyCardList_GetSelectedCardID() or 0
        -- if nGridID and nGridID > 0 and nCardID ~= 0
        --     and Monopoly_GridHighlight.IsShowing()
        --     and Monopoly_GridHighlight.IsPlayableGrid(nGridID)
        -- then
        --     -- LOG.INFO("[大富翁-出牌对地块] 上行 CardID=" .. nCardID .. " GridID=" .. nGridID)
        --     self.SendServerOperate(MINI_GAME_OPERATE_TYPE.SERVER_OPERATE, DFW_OPERATE_UP_ACTION_PLAYCARDTOGRID, nCardID, nGridID)
        -- end
    end

    -- 通知dummy的表现脚本
    self.NotifyDummyScript(dwDummyID, "OnMouseClick", bLButtonUp and 1 or 0)
end

-- 获取指定玩家当前手牌数量
function MonopolyData.GetPlayerHandCardCount(nPlayerIndex)
    if not nPlayerIndex or nPlayerIndex <= 0 or nPlayerIndex > DFW_PLAYERNUM then
        return 0
    end

    local tHandCards = DFW_GetPlayerHandCard(nPlayerIndex) or {}
    local nCardCount = 0
    for _, nCardID in ipairs(tHandCards) do
        if nCardID ~= 0 then
            nCardCount = nCardCount + 1
        end
    end

    return nCardCount
end

-- 获取排名：金币多者优先；金币相同比点券；金币与点券均相同则并列名次（1、1、3、4）
function MonopolyData.GetPlayerMoneyRankByDfwIndex(nDfwIndex)
    local tList = {}
    for i = 1, DFW_PLAYERNUM do
        local nMoney = 0
        local nPoints = 0
        local dwPlayerID = DFW_GetPlayerDWID(i)
        if dwPlayerID and dwPlayerID ~= 0 then
            local nVal = DFW_GetPlayerMoney(i)
            if type(nVal) == "number" then
                nMoney = nVal
            end
            local nPt = DFW_GetPlayerPointNum(i)
            if type(nPt) == "number" then
                nPoints = nPt
            end
        end
        table.insert(tList, { nIndex = i, nMoney = nMoney, nPoints = nPoints })
    end
    table.sort(tList, function(a, b)
        if a.nMoney ~= b.nMoney then
            return a.nMoney > b.nMoney
        end
        if a.nPoints ~= b.nPoints then
            return a.nPoints > b.nPoints
        end
        return a.nIndex < b.nIndex
    end)
    -- 并列：仅当金币、点券均与上一位相同；否则下一名取当前位次（竞赛排名）
    local tRankAtPos = {}
    for k = 1, #tList do
        if k == 1 then
            tRankAtPos[k] = 1
        elseif tList[k].nMoney == tList[k - 1].nMoney and tList[k].nPoints == tList[k - 1].nPoints then
            tRankAtPos[k] = tRankAtPos[k - 1]
        else
            tRankAtPos[k] = k
        end
    end
    for k = 1, #tList do
        if tList[k].nIndex == nDfwIndex then
            return tRankAtPos[k]
        end
    end
    if type(nDfwIndex) == "number" and nDfwIndex > 0 then
        return nDfwIndex
    end
    return 1
end

-- 设置玩家基础信息(名字、背景、头像)，通过小游戏Index获取
function MonopolyData.SetPlayerBaseInfo(scriptPlayer, nDfwIndex)
    if not scriptPlayer then
        return
    end

    if not nDfwIndex then
        nDfwIndex = self.GetClientPlayerIndex()
    end

    local dwPlayerID = DFW_GetPlayerDWID(nDfwIndex)
    if not dwPlayerID or dwPlayerID == 0 then
        return
    end

    -- 1. 大富翁身份背景色
    local nBgID = 1
    local tIdentityInfo = self.GetIdentityInfoByDfwIndex(nDfwIndex)
    if tIdentityInfo then
        nBgID = tIdentityInfo.nBgID
    end

    -- 2. 获取团队/社交/场景玩家基础信息
    local szName = ""
    local dwForceID = 0
    local nRoleType = 0
    local dwMiniAvatarID = 0

    local tTeamInfo = GetClientTeam().GetMemberInfo(dwPlayerID)
    if tTeamInfo then
        szName = UIHelper.GBKToUTF8(tTeamInfo.szName)
        dwForceID = tTeamInfo.dwForceID
        nRoleType = tTeamInfo.nRoleType
        dwMiniAvatarID = tTeamInfo.dwMiniAvatarID
    end

    -- 3. 名字、背景、头像（与 DFW/团队数据合并在一处）
    if IsFunction(scriptPlayer.SetName) then
        scriptPlayer:SetName(szName or "")
    end

    local tBgPathMap = {
        -- [1] = "ui/Image/RichMan/CommonPanel/Hong.tga",
        -- [2] = "ui/Image/RichMan/CommonPanel/Huang.tga",
        -- [3] = "ui/Image/RichMan/CommonPanel/Lan.tga",
        -- [4] = "ui/Image/RichMan/CommonPanel/Lv.tga",
        [1] = "ui/Image/RichMan/CommonPanel/Hong.tga",
        [2] = "UIAtlas2_Public_PublicButton_PublicButton1_Btn_Spcial_Gold",
        [3] = "ui/Image/RichMan/CommonPanel/Lan.tga",
        [4] = "ui/Image/RichMan/CommonPanel/Lv.tga",
    }
    local szBgPath = tBgPathMap[nBgID]
    if szBgPath then
        if IsFunction(scriptPlayer.SetColorBg) then
            scriptPlayer:SetColorBg(szBgPath)
        end
    end

    if scriptPlayer.WidgetHead then
        UIHelper.RemoveAllChildren(scriptPlayer.WidgetHead)
        local scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, scriptPlayer.WidgetHead, dwPlayerID)
        scriptHead:SetHeadInfo(dwPlayerID, dwMiniAvatarID, nRoleType, dwForceID)
    end

    if scriptPlayer.WidgetHead_108 then
        UIHelper.RemoveAllChildren(scriptPlayer.WidgetHead_108)
        local scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead_108, scriptPlayer.WidgetHead_108, dwPlayerID)
        scriptHead:SetHeadInfo(dwPlayerID, dwMiniAvatarID, nRoleType, dwForceID)
    end
end

-- 获取大富翁小游戏管理器
function MonopolyData.GetGameMgr()
    return DataModel.GetMiniGameMgr()
end

-- 向服务端发送大富翁操作消息
function MonopolyData.SendServerOperate(nOperateType, nValue1, nValue2, nValue3, nValue4, nValue5, nValue6)
    -- MINI_GAME_OPERATE_TYPE.SERVER_OPERATE         正常的操作
    -- MINI_GAME_OPERATE_TYPE.NO_COST_OPERATE        不扣计数的操作
    -- MINI_GAME_OPERATE_TYPE.NO_CHECK_OPERATE       不校验数据也不扣计数的操作--[[  ]]
    self.GetGameMgr().Operate(nOperateType, 
            nValue1 or 0, nValue2 or 0, nValue3 or 0, nValue4 or 0, nValue5 or 0, nValue6 or 0)
end

-- 获取当前大富翁流程阶段
function MonopolyData.GetGameState()
    return DataModel.nTableState
end

-- 按当前阶段恢复界面显示状态
function MonopolyData.Reconnect()
    DataModel.GetGameState()
    local nTableState = DataModel.nTableState
    if not nTableState then
        return
    end

    local tMatchedConfig = nil
    for _, tConfig in pairs(DOWN_EVENT_MAP) do
        if tConfig.nState == nTableState then
            tMatchedConfig = tConfig
            break
        end
    end

    if not tMatchedConfig then
        return
    end
    ApplyDownEventConfig(tMatchedConfig, nTableState)
end

-- 注册操作表中的函数
-- nActionID: 操作ID
-- fnAction: 操作函数，签名为 function(arg3, arg4, arg5, arg6)
-- script: self:XXX()中的self参数
function MonopolyData.RegisterMonopolyActionTable(nActionID, fnAction, script)
    if not nActionID or not fnAction or type(fnAction) ~= "function" then
        return
    end
    if not g_tMonopolyActionTable[nActionID] then
        g_tMonopolyActionTable[nActionID] = {}
    end
    local tInfo = {
        fnAction = fnAction,
        script = script,
    }
    table.insert(g_tMonopolyActionTable[nActionID], tInfo)
end

-- 注销操作表中的函数
-- nActionID: 操作ID
-- fnAction: 操作函数（可选，为空则删除整个操作ID下的所有函数）
function MonopolyData.UnRegisterMonopolyActionTable(nActionID, fnAction)
    if not nActionID then
        return
    end

    if not g_tMonopolyActionTable[nActionID] then
        return
    end

    -- 如果指定了函数，则只删除该函数
    if fnAction and type(fnAction) == "function" then
        for i = #g_tMonopolyActionTable[nActionID], 1, -1 do
            if g_tMonopolyActionTable[nActionID][i].fnAction == fnAction then
                table.remove(g_tMonopolyActionTable[nActionID], i)
                break
            end
        end
        -- 如果数组为空，则删除该操作ID
        if #g_tMonopolyActionTable[nActionID] == 0 then
            g_tMonopolyActionTable[nActionID] = nil
        end
    else
        -- 删除整个操作ID下的所有函数
        g_tMonopolyActionTable[nActionID] = nil
    end
end

-- 获取已注册的操作表
function MonopolyData.GetMonopolyActionTable()
    return g_tMonopolyActionTable
end

-----------------------------地块高亮接口------------------------------
-- 场景 dummy 的 OnHighlight 契约：
--   nState=0 原色
--   nState=1 黄色（鼠标悬停在可选地块上）
--   nState=2 蓝色（卡牌启用时的可选地块）

-- 设置指定地块高亮
-- nGridID: 地块ID
-- nState : 0=原色 1=黄 2=蓝；兼容旧调用（true→蓝 / false→原色）
function MonopolyData.SetGridHighlight(nGridID, nState)
    if not nGridID then
        LOG.INFO("[DFW_HL] nGridID is nil")
        return
    end
    if nState == true then
        nState = 2 -- 蓝
    elseif nState == false or nState == nil then
        nState = 0 -- 原色
    end
    local szNickName = self.GridToDummyNickName(nGridID)
    if szNickName == "" then
        LOG.INFO("[DFW_HL] GridID=" .. nGridID .. " has no DummyNickName, skip")
        return
    end
    -- LOG.INFO("[DFW_HL] GridID=" .. nGridID .. " NickName=" .. szNickName .. " highlight=" .. tostring(bHighlight))
    self.NotifyDummyScriptByNickName(szNickName, "OnHighlight", nState, 0, 0)
end

-- 批量设置地块高亮
-- tGridIDs: 地块ID数组
-- nState  : 0=原色 1=蓝 2=黄（兼容 true/false）
function MonopolyData.SetGridsHighlight(tGridIDs, nState)
    if not tGridIDs then
        return
    end
    for _, nGridID in ipairs(tGridIDs) do
        self.SetGridHighlight(nGridID, nState)
    end
end

-- 清除指定地块高亮
-- tGridIDs: 需要清除高亮的地块ID数组，由调用方维护
function MonopolyData.ClearGridHighlights(tGridIDs)
    if not tGridIDs then
        return
    end
    for _, nGridID in ipairs(tGridIDs) do
        self.SetGridHighlight(nGridID, 0) -- 原色
    end
end

function MonopolyData.MonopolyCardList_GetSelectedCardID()
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelRichMan)
    if not scriptView then return 0 end
    if not scriptView.WidgetCardList then return 0 end

    local scriptCardList = UIHelper.GetBindScript(scriptView.WidgetCardList)
    if not scriptCardList then return 0 end

    return scriptCardList:GetSelectedCardID()
end