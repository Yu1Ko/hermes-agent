SprintData = SprintData or {className = "SprintData"}
local self = SprintData

local UI_IDLE_AUTO_SWITCH_CD = 3
local MAX_PRE_HOLD_W_TIME = 1

local m_nFightTimerID

local m_tSpTimerID = {}
local m_nSpExitTimerID

local m_bExpectSprint = false --期望轻功状态
local m_bExpectSprintAchieved = false -- 是否到达期望轻功状态
local m_bAutoForward = false --自动向前
local m_nExitSprintTime = 0 --退出轻功时间 GetTickCount()
local m_bDropFlag = false --急降标记

local m_bInSwim = false --是否游泳
local m_bUnderWater = false --是否在水下
local m_bHasFightBtn = false --当前界面是否存在攻击按钮


local m_bSprintView --主界面右下角轻功/技能面板显示状态，true则为显示轻功面板，false则为显示技能面板

local m_nSprintTimer

SprintData.nSprintTipsShowTime = 5

SPRINT_SPEICAL_STATE = {
    Dash = 1,               --连冲
    MingJiao_Float = 2,     --明教-前飘
}

local tSprintSpecialStateName = {
    [SPRINT_SPEICAL_STATE.Dash] = "连冲",
    [SPRINT_SPEICAL_STATE.MingJiao_Float] = "前飘",
}

local m_nSpecialState = nil --当前特殊轻功状态


---骑马状态下进入战斗时会自动切换到技能面板的心法ID
local tbKungFuIDSwitchToFightSkillOnHorse = {
    [100406] = 1,
    [10026] = 1,
    [10062] = 1
}

function SprintData.Init()
    self.RegEvent()
    self._InitServerSprintSetting()
end

function SprintData.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)
    Timer.DelAllTimer(m_tSpTimerID)
    m_tSpTimerID = {}
end

function SprintData.RegEvent()
    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        self._onEnterScene()
    end)

    Event.Reg(self, EventType.OnClientPlayerLeave, function()
        self._onExitScene()
    end)

    -- Event.Reg(self, "SYNC_USER_PREFERENCES_END", function()
    --     SprintData.SyncServerSprintSetting() --进游戏后同步服务器数据
    -- end)

    --进入/离开战斗状态
    Event.Reg(self, "FIGHT_HINT", function(bFight)
        --print("[Sprint] FIGHT_HINT", bFight)
        self._onFightStateChanged(bFight)
    end)

    --死亡清除轻功状态
    Event.Reg(self, "PLAYER_DEATH", function()
        self.EndSprint()
    end)

    Event.Reg(self, "PLAYER_MOUNT_HORSE", function(dwPlayerID, bMount, dwParam, bHoldHorse)
        local player = GetClientPlayer()
        if not player or player.dwID ~= dwPlayerID then
            return
        end

        --下马时若为战斗状态则切换至战斗面板
        local bSprint, bFight, bOnHorse = self._getPlayerState()
        if not bSprint and bFight and not bOnHorse then
            self.SetViewState(false)
        end
    end)

    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID == VIEW_ID.PanelMainCity then
            local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
            self.scriptJoyStick = scriptView and scriptView.scriptJoyStick
        end
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelMainCity then
            self.scriptJoyStick = nil
        end
    end)

    Event.Reg(self, EventType.OnSkillPressDown, function()
        Timer.DelTimer(self, m_nFightTimerID)
    end)

    -- 游泳呼吸条
    Event.Reg(self, "SHOW_SWIMMING_PROGRESS", function()
        LOG.INFO("SHOW_SWIMMING_PROGRESS")
        TipsHelper:Init(false)
        Event.Dispatch(EventType.OnShowSwimmingProgress)
    end)

    Event.Reg(self, "HIDE_SWIMMING_PROGRESS", function()
        LOG.INFO("HIDE_SWIMMING_PROGRESS")
        TipsHelper:Init(false)
        Event.Dispatch(EventType.OnHideSwimmingProgress)
    end)

    Event.Reg(self, EventType.OnQuickMenuSprintChange, function(imgNode, labelNode)
        local szImgPath
        local szSprintMode = GameSettingData.GetNewValue(UISettingKey.SprintMode).szDec
        if szSprintMode == GameSettingType.SprintMode.Classic.szDec then
            szImgPath = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_QuickBtn27"
        elseif szSprintMode == GameSettingType.SprintMode.Simple.szDec then
            szImgPath = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_QuickBtn27_1"
        elseif szSprintMode == GameSettingType.SprintMode.Common.szDec then
            szImgPath = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_QuickBtn27_2"
        end
        UIHelper.SetSpriteFrame(imgNode, szImgPath)
        UIHelper.SetString(labelNode, szSprintMode)
    end)
    Event.Reg(self, EventType.OnLeftBottomSprintChange, function(imgNode, labelNode)
        local szImgPath
        local szSprintMode = GameSettingData.GetNewValue(UISettingKey.SprintMode).szDec
        if szSprintMode == GameSettingType.SprintMode.Classic.szDec then
            szImgPath = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_Mqinggong"
        elseif szSprintMode == GameSettingType.SprintMode.Simple.szDec then
            szImgPath = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_Mqinggong1"
        elseif szSprintMode == GameSettingType.SprintMode.Common.szDec then
            szImgPath = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_Mqinggong2"
        end
        UIHelper.SetSpriteFrame(imgNode, szImgPath)
    end)
end

-------------------------------- Public --------------------------------

function SprintData.CanSprint(bShowTips)
    local player = GetClientPlayer()
    if not player then
        return
    end

    --锁操作时无法使用轻功
    if InputHelper.IsLockMove() then
        if bShowTips then
            LOG.INFO("SprintData.CanSprint() == false -> InputHelper.IsLockMove() == true")
        end
        return false
    end

    --Buff锁操作
    if player.nDisableMoveCtrlCounter > 0 then
        return false
    end

    --刹车的时候不能开始下一次轻功
    if player.nMoveState == MOVE_STATE.ON_SPRINT_BREAK then
        return
    end

    -- 观战模式时无法使用轻功
    if player.bOBFlag == true then
        return false
    end

    --水下游泳时无法使用轻功
    if m_bUnderWater then
        return false
    end

    --没有气力值
    if (not player.bOnHorse and player.nSprintPower <= 0 ) or (player.bOnHorse and player.nHorseSprintPower <= 0) then
        return false
    end

    --玩家禁用轻功flag
    if player.nDisableSprintFlag > 0 then
        if bShowTips then
            TipsHelper.ShowNormalTip("当前状态无法使用轻功")
        end
        return false
    end

    --部分地图无法使用轻功
    local tbMapParams = MapHelper.GetMapParams()
    if not tbMapParams.bCanSprint then
        if bShowTips then
            TipsHelper.ShowNormalTip("当前场景无法使用轻功")
        end
        return false
    end

    --动态技能栏无法使用轻功
    if not QTEMgr.CanCastSkill() then
        if bShowTips then
            TipsHelper.ShowNormalTip("当前状态无法使用轻功")
        end
        return false
    end

    return true
end

function SprintData.GetSprintState()
    local player = GetClientPlayer()
    if not player then
        return
    end

    return (player.bSprintFlag or player.bOnTowerFlag) and player.nMoveState ~= MOVE_STATE.ON_SPRINT_BREAK
end

function SprintData.GetExpectSprint()
    return m_bExpectSprint
end

function SprintData.GetAutoForward()
    return m_bAutoForward
end

function SprintData.GetExitSprintTime()
    return m_nExitSprintTime
end

--- @param boolean bSprintView 主界面右下角轻功/技能面板显示状态，true则为显示轻功面板，false则为显示技能面板
--- @param boolean bForceUpdate 是否强制刷新
function SprintData.SetViewState(bSprintView, bForceUpdate)
    if m_bSprintView ~= bSprintView or bForceUpdate then
        LOG.INFO("[Sprint] SetViewState, %s", tostring(bSprintView))

        m_bSprintView = bSprintView
        Event.Dispatch(EventType.OnSprintFightStateChanged, bSprintView)
    end
end

--- @return boolean 主界面右下角轻功/技能面板显示状态，true则为显示轻功面板，false则为显示技能面板
function SprintData.GetViewState()
    if m_bSprintView == nil then
        m_bSprintView = true

        local player = GetClientPlayer()
        if player then
            m_bSprintView = self.GetSprintState() or not player.bFightState
        end
    end
    return m_bSprintView
end

--点击切换战斗/生活技能展示
function SprintData.ToggleViewState()
    if not (QTEMgr.CanCastSkill() or QTEMgr.IsHorseDynamic()) and not m_bSprintView then return end--动态技能不能切轻功
    self.SetViewState(not m_bSprintView)
end

function SprintData.StartSprint(bImmediately)
    if not g_pClientPlayer then
        return
    end

    if not self.CanSprint(true) then
        return
    end

    if g_pClientPlayer.bFightState then
        TipsHelper.ShowNormalTip("战斗状态下无法使用轻功")
        return
    end

    -- --在地面上时只有拖拽着摇杆才能进入轻功
    -- if g_pClientPlayer.nJumpCount == 0 and not self.IsDragging() then
    --     TipsHelper.ShowNormalTip("请先按住移动摇杆，方可进入轻功")
    --     return
    -- end

    if g_pClientPlayer.GetOTActionState() == CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL then
        g_pClientPlayer.StopChannelSkill()
    end

    --print("[Sprint] StartSprint")
    m_bAutoForward = false --进入轻功，取消自动行走
    self._setExpectSprint(true)

    if bImmediately then
        StartSprint()
        self._updateViewState()
    else
        self._updateSprint()
    end
end

function SprintData.EndSprint(bForce, bImmediately)
    --TODO 结束轻功后延迟一段时间才能再次进入轻功？

    --print("[Sprint] EndSprint", bForce)
    self._clearExpectSprint()

    if bForce or bImmediately then
        CheckEndSprint(bForce)
        self._updateViewState()
    else
        self._updateSprint()
    end
    self.ExitSpecialState()
end

function SprintData.SetAutoForward(bAutoForward)
    if bAutoForward and InputHelper.IsLockMove() then
        return
    end

    local player = GetClientPlayer()
    local bChanged = m_bAutoForward ~= bAutoForward
    if bChanged and player and player.nJumpCount == 0 then
        local szText = bAutoForward and "已开启自动前进" or "已关闭自动前进"
        TipsHelper.ShowNormalTip(szText)
    end
    m_bAutoForward = bAutoForward
    if bChanged then
        FuncSlotMgr.InvokeFuncSlotChanged()
    end
end

--通用急降
function SprintData.Drop()
    local player = GetClientPlayer()
    if not player then
        return
    end

    --非进战状态才能急降
    if player.bFightState then
        TipsHelper.ShowNormalTip("已进入战斗状态，急降无法使用")
        return
    end

    Event.Dispatch(EventType.OnSetBottomRightAnchorVisible, false) --隐藏UI
    self.EndSprint() --结束轻功
    Timer.Add(self, 0.4, Jump)
    Timer.Add(self, 0.9, function()
        self.StartSprint()
        if m_bExpectSprint then
            m_bDropFlag = true
        end
    end)
    Timer.Add(self, 1.4, function()
        if player.nMoveState ~= MOVE_STATE.ON_DEATH then
            Event.Dispatch(EventType.OnSetBottomRightAnchorVisible, true)
        end
    end)
end

--续飞
function SprintData.ReFly()
    local player = GetClientPlayer()
    if not player then
        return
    end

    --非进战状态才能急降
    if player.bFightState then
        TipsHelper.ShowNormalTip("已进入战斗状态，续飞无法使用")
        return
    end

    self.EndSprint()
    Timer.Add(self, 0.5, self.StartSprint)
end

--特殊轻功状态，由一系列循环操作组成的快捷功能
function SprintData.EnterSpecialState(nSpecialState)
    local player = GetClientPlayer()
    if not player then
        return
    end

    if m_nSpecialState or m_nSpExitTimerID then
        return
    end

    print("[Sprint] EnterSpecialState", nSpecialState)
    Timer.DelAllTimer(m_tSpTimerID)
    Timer.DelTimer(self, m_nSpExitTimerID)
    m_tSpTimerID = {}
    m_nSpExitTimerID = nil

    --TODO 优化为操作序列？

    if nSpecialState == SPRINT_SPEICAL_STATE.Dash then

        local fnAction = function()
            CheckEndSprint()
            Timer.Add(m_tSpTimerID, 0.15, function()
                StartSprint()
            end)
        end
        fnAction()
        Timer.AddCycle(m_tSpTimerID, 0.3, fnAction)

    elseif nSpecialState == SPRINT_SPEICAL_STATE.MingJiao_Float then

        local fnAction
        fnAction = function(bFlag)
            if player.nJumpCount == 0 then
                Jump()
                Timer.Add(m_tSpTimerID, 0.15, function()
                    FuncSlotMgr.ExecuteCommand("MingJiaoJumpUp")
                    Timer.Add(m_tSpTimerID, 1.3, function()
                        CheckEndSprint()
                        Timer.Add(m_tSpTimerID, 0.15, function()
                            StartSprint()
                            Timer.Add(m_tSpTimerID, 0.15, function()
                                fnAction(true)
                            end)
                        end)
                    end)
                end)
            else
                if not bFlag then
                    CheckEndSprint()
                    Timer.Add(m_tSpTimerID, 0.15, function()
                        StartSprint()
                        Timer.Add(m_tSpTimerID, 0.3, function()
                            Jump()
                            Timer.Add(m_tSpTimerID, 1.3, function()
                                fnAction()
                            end)
                        end)
                    end)
                else
                    Timer.Add(m_tSpTimerID, 0.15, function()
                        Jump()
                        Timer.Add(m_tSpTimerID, 1.3, function()
                            CheckEndSprint()
                            Timer.Add(m_tSpTimerID, 0.15, function()
                                StartSprint()
                                Timer.Add(m_tSpTimerID, 0.15, function()
                                    fnAction(true)
                                end)
                            end)
                        end)
                    end)
                end
            end
        end
        fnAction()

    end

    m_nSpecialState = nSpecialState
end

function SprintData.ExitSpecialState(bImmediately)
    Timer.DelAllTimer(m_tSpTimerID)
    m_tSpTimerID = {}

    if not m_nSpecialState then
        return
    end

    print("[Sprint] ExitSpecialState", bImmediately)
    if bImmediately then
        Timer.DelTimer(self, m_nSpExitTimerID)
        m_nSpExitTimerID = nil
        m_nSpecialState = nil
    elseif not m_nSpExitTimerID then
        m_nSpExitTimerID = Timer.Add(self, 0.4, function() --加个延时恢复，避免闪烁
            m_nSpExitTimerID = nil
            m_nSpecialState = nil
        end)
    end

    local _, bFight, _ = self._getPlayerState()
    if bFight then
        self._clearExpectSprint()
        self._updateSprint()
    else
        StartSprint()
    end
end

function SprintData.GetSpecialState()
    return m_nSpecialState
end

function SprintData.UpdateSwimState(nMoveState)
    local bInSwim = nMoveState == MOVE_STATE.ON_SWIM_JUMP or nMoveState == MOVE_STATE.ON_SWIM or nMoveState == MOVE_STATE.ON_FLOAT
    if m_bInSwim ~= bInSwim then
        m_bInSwim = bInSwim
        --教学 玩家游泳状态改变
        FireHelpEvent("OnSwimStateChanged", m_bInSwim, m_bUnderWater)
    end
end

function SprintData.SetUnderWater(bUnderWater)
    if m_bUnderWater ~= bUnderWater then
        m_bUnderWater = bUnderWater
        --教学 玩家游泳状态改变
        FireHelpEvent("OnSwimStateChanged", m_bInSwim, m_bUnderWater)
    end
end

function SprintData.SetHasFightBtn(bHasFightBtn)
    m_bHasFightBtn = bHasFightBtn
end

function SprintData.GetHasFightBtn()
    return m_bHasFightBtn
end

function SprintData.SetDropFlag(bDropFlag)
    m_bDropFlag = bDropFlag
end

-------------------------------- ServerSync --------------------------------

-- 注意 新类型只能往后添加 不能随意更改顺序
local tSprintSettingDef = {
    UISettingKey.SprintMode,
    UISettingKey.SpecialSprint,
    UISettingKey.SprintDrop,
    UISettingKey.DoubleTapToSprint,
    UISettingKey.ReleaseJoystickToExitSprint,
    UISettingKey.SprintCamera,
    UISettingKey.AutoClimb,
    UISettingKey.WallClimb,
    UISettingKey.CrossTerrain,
    UISettingKey.Gliding,
    UISettingKey.SprintCloakEffect,
}

-- 注意 新类型只能往后添加 不能随意更改顺序
local tSprintSettingTypeDef = {
    [UISettingKey.SprintMode] = {
        GameSettingType.SprintMode.Classic,
        GameSettingType.SprintMode.Simple,
        GameSettingType.SprintMode.Common,
    },
    [UISettingKey.SpecialSprint] = {
        GameSettingType.SpecialSprint.None,
        GameSettingType.SpecialSprint.ReFly,
        GameSettingType.SpecialSprint.Dash,
    },
    [UISettingKey.SprintDrop] = {
        GameSettingType.SprintDrop.School,
        GameSettingType.SprintDrop.Common,
    },
}

local tSprintSetting2Index, tIndex2SprintSetting = {}, {}
local tSprintSettingType2Index, tIndex2SprintSettingType = {}, {}
local bIsSync = false

function SprintData._InitServerSprintSetting()

    local function GetIndexConvertMap(tList)
        local t, r = {}, {}
        for i, v in ipairs(tList or {}) do
            t[v] = i
            r[i] = v
        end
        return t, r
    end

    tSprintSetting2Index, tIndex2SprintSetting = GetIndexConvertMap(tSprintSettingDef)

    for szSprintSettingKey, tSettingTypeList in pairs(tSprintSettingTypeDef) do
        local tList = {}
        for _, tSettingType in ipairs(tSettingTypeList) do
            table.insert(tList, tSettingType.szDec)
        end
        local tType2Index, tIndex2Type = GetIndexConvertMap(tList)
        tSprintSettingType2Index[szSprintSettingKey] = tType2Index
        tIndex2SprintSettingType[szSprintSettingKey] = tIndex2Type
    end

    Event.Reg(self, EventType.OnBeforeStoreNewSetting, function(szConfigKey, value)
        if not tSprintSetting2Index[szConfigKey] then return end
        if GameSettingData.bShouldInitSetting then return end
        if bIsSync then return end
        if not GameSettingData.GetNewValue(UISettingKey.SyncSprintSetting) then return end
        if self.IsServerSprintSettingNeedUpdate() then return end

        --同步服务器设置
        SprintData.SetServerSprintSetting(szConfigKey, value)
    end)
end

--value传入bool或szDec
function SprintData.SetServerSprintSetting(szSprintSettingKey, value)
    if not szSprintSettingKey or value == nil then
        return
    end

    local nSettingIndex = tSprintSetting2Index[szSprintSettingKey]
    if not nSettingIndex then
        LOG.ERROR("SprintData.GetServerSprintSetting Error, Invalid Key: %s", tostring(szSprintSettingKey))
        return
    end

    value = IsTable(value) and value.szDec or value

    if tSprintSettingType2Index[szSprintSettingKey] then
        if not tSprintSettingType2Index[szSprintSettingKey][value] then
            LOG.ERROR("SprintData.SetServerSprintSetting Error, Invalid Value: %s %s", tostring(value), tostring(szSprintSettingKey))
            return
        end
        value = tSprintSettingType2Index[szSprintSettingKey][value] --若设置项为枚举类型，则将szDec转为数字索引
    else
        value = value and 1 or 0 --Boolean转为1/0
    end

    LOG.INFO("SprintData.SetServerSprintSetting %s %s", tostring(szSprintSettingKey), tostring(value))
    Storage_Server.SetData("SprintSetting", nSettingIndex, value)
end

--返回bool或szDec
function SprintData.GetServerSprintSetting(szSprintSettingKey)
    if not szSprintSettingKey then
        return
    end

    local nSettingIndex = tSprintSetting2Index[szSprintSettingKey]
    if not nSettingIndex then
        LOG.ERROR("SprintData.GetServerSprintSetting Error, Invalid Key: %s", tostring(szSprintSettingKey))
        return
    end

    local value = Storage_Server.GetData("SprintSetting", nSettingIndex)
    if tIndex2SprintSettingType[szSprintSettingKey] then
        if not tIndex2SprintSettingType[szSprintSettingKey][value] then
            LOG.ERROR("SprintData.GetServerSprintSetting Error, Invalid Value: %s, %s", tostring(value), tostring(szSprintSettingKey))
            return
        end
        value = tIndex2SprintSettingType[szSprintSettingKey][value] --若设置项为枚举类型，则将数字索引转为szDec
    else
        value = value ~= 0 --1/0转为Boolean类型 
    end

    return value
end

function SprintData.IsServerSprintSettingNeedUpdate()
    for _, szSprintSettingKey in pairs(tSprintSettingDef) do
        local serverValue = self.GetServerSprintSetting(szSprintSettingKey)
        local localValue = GameSettingData.GetNewValue(szSprintSettingKey)
        localValue = IsTable(localValue) and localValue.szDec or localValue
        if serverValue ~= localValue then
            --LOG.INFO("SprintData.IsServerSprintSettingNeedUpdate %s %s", tostring(serverValue), tostring(localValue))
            return true
        end
    end
    return false
end

function SprintData.SyncServerSprintSetting()
    if not GameSettingData.GetNewValue(UISettingKey.SyncSprintSetting) then
        return
    end

    local nServerMaxIndex = Storage_Server.GetData("SprintSettingMaxIndex")
    local nLocalMaxIndex = #tSprintSettingDef
    LOG.INFO("SprintData.SyncServerSprintSetting %s %s", tostring(nServerMaxIndex), tostring(nLocalMaxIndex))

    --若有新增轻功设置，则直接上传到服务器
    if nServerMaxIndex < nLocalMaxIndex then
        for i = nServerMaxIndex, nLocalMaxIndex do
            local szSprintSettingKey = tSprintSettingDef[i]
            local value = GameSettingData.GetNewValue(szSprintSettingKey)
            self.SetServerSprintSetting(szSprintSettingKey, value)
        end
        Storage_Server.SetData("SprintSettingMaxIndex", nLocalMaxIndex)
    end

    if not self.IsServerSprintSettingNeedUpdate() then
        return
    end

    local dialog = UIHelper.ShowSystemConfirm("本地轻功配置与服务器存在差异，是否使用服务器配置覆盖本地配置或保留本地配置并上传到服务器？", function()
        bIsSync = true
        for _, szSprintSettingKey in pairs(tSprintSettingDef) do
            local serverValue = self.GetServerSprintSetting(szSprintSettingKey)
            local localValue = GameSettingData.GetNewValue(szSprintSettingKey)
            localValue = IsTable(localValue) and localValue.szDec or localValue
            if serverValue ~= localValue then
                if tSprintSettingTypeDef[szSprintSettingKey] then
                    for _, tSettingType in pairs(tSprintSettingTypeDef[szSprintSettingKey]) do
                        if tSettingType.szDec == serverValue then
                            serverValue = tSettingType
                            break
                        end
                    end
                end
                GameSettingData.ApplyNewValue(szSprintSettingKey, serverValue)
            end
        end
        bIsSync = false
        UISettingNewStorageTab.Flush()
        Event.Dispatch(EventType.OnGameSettingViewUpdate)
    end, function()
        -- GameSettingData.ApplyNewValue(UISettingKey.SyncSprintSetting, false)
        -- Event.Dispatch(EventType.OnGameSettingViewUpdate)
    end)

    dialog:ShowOtherButton()
    dialog:SetOtherButtonClickedCallback(function()
        for _, szSprintSettingKey in pairs(tSprintSettingDef) do
            local value = GameSettingData.GetNewValue(szSprintSettingKey)
            self.SetServerSprintSetting(szSprintSettingKey, value)
        end
    end)

    dialog:SetConfirmButtonContent("使用服务器配置")
    dialog:SetCancelButtonContent("取消")
    dialog:SetOtherButtonContent("上传本地配置")
end

-------------------------------- Private --------------------------------

function SprintData._onEnterScene()
    Timer.AddFrameCycle(self, 1, self._onUpdate)

    m_nSprintTimer = 0
    m_nExitSprintTime = 0
    self._setExpectSprint(self.GetSprintState())
    m_bAutoForward = false
    m_bDropFlag = false
    self.ExitSpecialState(true)

    Timer.AddFrame(self, 2, function()
        local bSprint, bFight, bOnHorse = self._getPlayerState()
        --轻功/非战斗/骑马 自动切换到轻功界面，否则切换到战斗界面
        self.SetViewState(bSprint or not bFight or bOnHorse)
    end)

    --游泳呼吸条
    if g_pClientPlayer and g_pClientPlayer.nDivingCount > 0 then
        TipsHelper:Init(false)
        Event.Dispatch(EventType.OnShowSwimmingProgress)
    end
end

function SprintData._onExitScene()
    Timer.DelAllTimer(self)
    Timer.DelAllTimer(m_tSpTimerID)
    m_tSpTimerID = {}
    m_bUnderWater = false
    m_bInSwim = false
    m_bHasFightBtn = false
end

function SprintData._onFightStateChanged(bFight)
    Timer.DelTimer(self, m_nFightTimerID)

    if bFight then
        if m_nSpecialState then
            local szName = tSprintSpecialStateName[m_nSpecialState] or "轻功特殊状态"
            TipsHelper.ShowNormalTip("进入战斗，" .. szName .. "已取消")
            self.ExitSpecialState(true)
        end

        local bSprint, _, _ = self._getPlayerState()

        --进战时若还未开始轻功，清除当前的期望轻功状态
        if not bSprint then
            self._clearExpectSprint()
        end

        if QTEMgr.IsInDynamicSkillStateBySkills() and not SpecialDXSkillData.bOpenControlActionBar then
            QTEMgr.OnSwitchDynamicSkillStateBySkills()
        end

        local bShowFight = true
        if g_pClientPlayer and g_pClientPlayer.bOnHorse then
            local currentKungFuID = g_pClientPlayer.GetActualKungfuMount().dwSkillID
            bShowFight = tbKungFuIDSwitchToFightSkillOnHorse[currentKungFuID] == 1
        end
        if QTEMgr.CanCastSkill() and not bSprint then
            --动态技能、或玩家正处于轻功状态，不因为战斗刷新UI显示
            self.SetViewState(not bShowFight)
        end
    else
        --离开战斗状态2s后切换回去
        m_nFightTimerID = Timer.Add(self, UI_IDLE_AUTO_SWITCH_CD, function()
            if QTEMgr.CanCastSkill() then
                --self.SetViewState(true) --2023.11.15 zhouyixiao说不用切回去
            end
        end)
    end
end

function SprintData._onUpdate()
    local nDeltaTime = Timer.FixedDeltaTime()

    local player = GetClientPlayer()
    if not player then
        return
    end

    local bSprint, _, _ = self._getPlayerState()
    if bSprint and (not player.bOnHorse and player.nSprintPower <= 0) or (player.bOnHorse and player.nHorseSprintPower <= 0) then
        if m_nSpecialState ~= SPRINT_SPEICAL_STATE.MingJiao_Float then
            print("[Sprint] nSprintPower <= 0, EndSprint")
            self._clearExpectSprint()
            self.ExitSpecialState()
        end
    end

    --锁输入 自动停止轻功和自动行走
    if player.nDisableMoveCtrlCounter > 0 then
        self._clearExpectSprint()
        m_bAutoForward = false
        self.ExitSpecialState()
    end

    --落地自动停止连冲
    if m_nSpecialState == SPRINT_SPEICAL_STATE.Dash and player.nJumpCount == 0 then
        self.ExitSpecialState()
    end

    --急降落地且未按前进则自动停止轻功
    if m_bDropFlag and player.nJumpCount == 0 and not self.IsDraggingForward() then
        self._clearExpectSprint()
        self.ExitSpecialState()
    end

    --水中或爬墙自动停止明教前飘
    if m_nSpecialState == SPRINT_SPEICAL_STATE.MingJiao_Float and (player.bIgnoreGravity or player.IsRunOnWater() == 1) then
        TipsHelper.ShowNormalTip("当前状态无法使用前飘，已自动退出")
        self.ExitSpecialState()
    end

    --自动按前
    local nHoldW = 0
    local bLDown = SceneMgr.GetMouseButton(cc.MouseButton.BUTTON_LEFT)
    local bRDown = SceneMgr.GetMouseButton(cc.MouseButton.BUTTON_RIGHT)
    if not InputHelper.IsLockMove() and (m_bExpectSprint or m_bAutoForward or m_nSpecialState == SPRINT_SPEICAL_STATE.Dash or (bLDown and bRDown)) then
        nHoldW = 1
    end

    --若太长时间没切，先打断
    if m_bExpectSprint ~= bSprint and not m_bAutoForward and not player.bIgnoreGravity then
        m_nSprintTimer = m_nSprintTimer + nDeltaTime
        if m_nSprintTimer >= MAX_PRE_HOLD_W_TIME then
            self._setExpectSprint(bSprint)
            nHoldW = nHoldW == 1 and 0 or 1
        end
    else
        m_nSprintTimer = 0
    end

    if player.bInNav then
        nHoldW = 0
    end

    local bHoldW = nHoldW == 1
    FuncSlotMgr.SetVirtualDirKey(bHoldW or player.bInNav)
    player.HoldW(nHoldW)
    Camera_EnableControl(ControlDef.CONTROL_AUTO_RUN, bHoldW)


    self._updateSprint()
end

function SprintData._updateSprint()
    if not self.CanSprint() then
        self._clearExpectSprint()
        self.ExitSpecialState()
    end

    local player = GetClientPlayer()
    if not player then
        return
    end

    local bSprint, _, _ = self._getPlayerState()
    if m_bExpectSprint ~= bSprint then
        if not m_bExpectSprintAchieved then
            if m_bExpectSprint then
                StartSprint()
            else
                CheckEndSprint()
            end
            self._updateViewState()
        else
            -- 到达期望轻功状态后，状态又变为不一致，则表示服务器改变了轻功状态，这里接受服务器的修改
            self._setExpectSprint(bSprint)
        end
    else
        m_bExpectSprintAchieved = true
    end
end

function SprintData._updateViewState()
    local _, bFight, bOnHorse = self._getPlayerState()
    local bCanCastSkill = QTEMgr.CanCastSkill()
    if m_bExpectSprint and not bFight and bCanCastSkill then
        self.SetViewState(true)
    elseif not m_bExpectSprint and bFight and not bOnHorse then
        self.SetViewState(false)
    end
end

function SprintData._setExpectSprint(bExpectSprint)
    m_bExpectSprint = bExpectSprint
    m_bExpectSprintAchieved = false
end

function SprintData._clearExpectSprint()
    if m_bExpectSprint then
        m_nExitSprintTime = GetTickCount()
    end
    self._setExpectSprint(false)
    m_bDropFlag = false
end

function SprintData._getPlayerState()
    local player = GetClientPlayer()
    local bSprint = m_bExpectSprint
    local bFight = false
    local bOnHorse = false
    if player then
        bSprint = self.GetSprintState()
        bFight = player.bFightState
        bOnHorse = player.bOnHorse
    end
    return bSprint, bFight, bOnHorse
end

function SprintData.IsDragging()
    local scriptJoyStick = self.scriptJoyStick
    return scriptJoyStick and scriptJoyStick:IsDragging() or false
end

function SprintData.IsDraggingForward()
    local scriptJoyStick = self.scriptJoyStick
    return scriptJoyStick and scriptJoyStick:IsDraggingForward() or false
end
