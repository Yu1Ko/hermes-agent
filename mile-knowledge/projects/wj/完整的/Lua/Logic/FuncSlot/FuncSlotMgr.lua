FuncSlotMgr = {className = "FuncSlotMgr"}
local self = FuncSlotMgr

FuncSlotMgr.bDebug = false
FuncSlotMgr.bInit = false

COMMON_SPRINT_SCHOOL_ID = 999 

local m_szSprintMode = GameSettingType.SprintMode.Classic.szDec

local m_tbCondition = {}
local m_tbSzKey = {}
local m_tbActionDatas = {}
local m_tC = {}
local m_tMatch = {}

--性能优化：使用树存Condition配置
local m_tbConditionRoot = {}

local m_tbSlotBtnDatas = {}
local m_tbSprintMaxPhase = {}
local m_aActionList = nil
local m_tbAction = nil
local m_tbCheckForceUpdate = nil

local tbVirtualDirKey = {}

-------------------------------- Public --------------------------------

function FuncSlotMgr.Init()
    if self.bInit then
        return
    end

    for _, v in pairs(FUNCSLOT_DEFAULT_ACTION) do
        for k, tAction in pairs(v) do
            local szName = k
            setmetatable(tAction, {__tostring = function() return szName end}) --打印用
        end
    end

    m_szSprintMode = GameSettingData.GetNewValue(UISettingKey.SprintMode).szDec
    self.tbCommands = require("Lua/Logic/FuncSlot/FuncSlotCommands.lua")

    --加载槽位按钮数据
    self._loadSlotBtnDatas()

    --LOG.TABLE(m_tbActionDatas, "m_tbActionDatas")
    self._registerEvent()

    --加载所有条件
    self._loadSprintCondition()

    --初始化
    self._updateSlotByActionList(nil, true)
    self.tbCommands.Init()

    --开始条件检测
    Timer.AddFrameCycle(self, 1, self._checkCondition)

    self.bInit = true
end

function FuncSlotMgr.UnInit()
    m_tbCondition = {}
    m_tbSzKey = {}
    m_tbActionDatas = {}
    m_tbConditionRoot = {}
    m_tbSlotBtnDatas = {}
    m_tbSprintMaxPhase = {}
    m_aActionList = nil
    m_tbAction = nil
    m_tbCheckForceUpdate = nil
    tbVirtualDirKey = {}

    self.tbCommands.UnInit()
    self.tbCommands = nil
    Timer.DelAllTimer(self)

    self.bInit = false
end

function FuncSlotMgr.GetBtnDataBySlotIndex(nSlotIndex)
    return m_tbSlotBtnDatas[nSlotIndex]
end

--表里一行有多个tbBtnData，可根据nSlotIndex获得
function FuncSlotMgr.GetBtnData(nActionID, nSlotIndex)
    local tbActionData = m_tbActionDatas[nActionID]
    if tbActionData then
        for nCurSlotIndex, tbBtnData in pairs(tbActionData) do
            if not nSlotIndex or nCurSlotIndex == nSlotIndex then
                return tbBtnData
            end
        end
    end
end

function FuncSlotMgr.ExecuteCommand(szCommand, ...)
    FuncSlotMgr.bExecutingCommand = true
    if self.tbCommands and szCommand and szCommand ~= "" then
        local fnCommand = self.tbCommands[szCommand]
        if fnCommand then
            fnCommand(...)
        elseif not self.tbCommands.KeyCommand(szCommand) then
            LOG.ERROR("Can't find FuncSlot Command: %s", szCommand)
        end
    end
    FuncSlotMgr.bExecutingCommand = false
end

function FuncSlotMgr.SetVirtualDirKey(bForward, bBackWard, bLeft, bRight)
    if bForward ~= nil then tbVirtualDirKey["MOVEFORWARD"] = bForward end
    if bBackWard ~= nil then tbVirtualDirKey["MOVEBACKWARD"] = bBackWard end
    if bLeft ~= nil then tbVirtualDirKey["TURNLEFT"] = bLeft end
    if bRight ~= nil then tbVirtualDirKey["TURNRIGHT"] = bRight end
end

function FuncSlotMgr.InvokeFuncSlotChanged()
    Event.Dispatch(EventType.OnFuncSlotChanged, m_tbAction, 0) --第二个参数占位用，否则Event0个参数的时候会有bug
end

-------------------------------- Private --------------------------------

function FuncSlotMgr._updateSlotByActionList(tbAction, bForce)
    local player = GetClientPlayer()
    if not player then
        return
    end

    local aActionList = tbAction and tbAction.tAction
    if not aActionList then
        if TravellingBagData.IsInTravelingMap() then
            aActionList = FUNCSLOT_DEFAULT_ACTION[m_szSprintMode].DEFAULT_ACTIONS_LKX
        elseif BattleFieldData.IsInTongWarFieldMap() then
            aActionList = FUNCSLOT_DEFAULT_ACTION[m_szSprintMode].DEFAULT_ACTIONS_TONG_WAR
        else
            aActionList = FUNCSLOT_DEFAULT_ACTION[m_szSprintMode].DEFAULT_ACTIONS
        end
    end

    if m_tbCheckForceUpdate then
        --检测某些特定条件满足时，强制触发右下按钮刷新，如跳跃时某些按钮的置灰状态刷新
        if (m_tbCheckForceUpdate.nJumpCount > 0) ~= (player.nJumpCount > 0) then
            bForce = true
        end
    end

    if aActionList == m_aActionList and not bForce then
        return
    end
    m_aActionList = aActionList
    m_tbAction = tbAction
    m_tbCheckForceUpdate = {
        nJumpCount = player.nJumpCount,
    }

    if tbAction then
        LOG.INFO("[FuncSlotMgr] Condition Matched: %d, %s", tbAction.nIndex, tbAction.szComment or "")
        --print_table(m_tMatch)
    else
        LOG.INFO("[FuncSlotMgr] Condition Not Matched, Default Action: %s", tostring(aActionList))
        --print_table(m_tC)
    end

    -- 测试用打印
    -- local tC = self._getPlayerInfo(GetClientPlayer())
    -- print_table(tC)

    m_tbSlotBtnDatas = {}
    for i = 1, #aActionList do
        self._setSlotByActionID(aActionList[i])
    end

    self.InvokeFuncSlotChanged()
end

function FuncSlotMgr._setSlotByActionID(nActionID)
    local tbActionData = m_tbActionDatas[nActionID]
    if tbActionData then
        for nSlotIndex, tbBtnData in pairs(tbActionData) do
            m_tbSlotBtnDatas[nSlotIndex] = tbBtnData
        end
    end
end

function FuncSlotMgr._checkCondition()
    local player = g_pClientPlayer
    if not player then
        return
    end

    local tC = self._getPlayerInfo(player)
    local dwBitOPSchoolID = player.dwBitOPSchoolID

    --通用轻功
    if GameSettingData.GetNewValue(UISettingKey.SprintMode).szDec == GameSettingType.SprintMode.Common.szDec then
        dwBitOPSchoolID = COMMON_SPRINT_SCHOOL_ID
    end

    --if Config.bOptickLuaSample then BeginSample("FuncSlotMgr._getAction()") end
    local tbAction = self._getAction(dwBitOPSchoolID, tC)
    --if Config.bOptickLuaSample then EndSample() end

    self._updateSlotByActionList(tbAction)
end

function FuncSlotMgr._getAction(dwBitOPSchoolID, tC)
    local tbAction
    if self.bDebug then
        --以下为性能优化前原代码，速度较慢但条件不满足时可以打印
        tbAction = self._getFitAction(dwBitOPSchoolID, tC)
        if not tbAction then
            tbAction = self._getFitAction(0, tC)
        end
    else
        --使用性能优化后的新算法
        tbAction = self._fastGetFitAction(dwBitOPSchoolID, tC)
        if not tbAction then
            tbAction = self._fastGetFitAction(0, tC)
        end
    end
    return tbAction
end

--匹配条件（端游原版）
function FuncSlotMgr._getFitAction(dwBitOPSchoolID, tC)
    local tCondition = m_tbCondition[dwBitOPSchoolID]
    if not tCondition then
        return
    end

    if not tC then
        return
    end

    for i, tLine in ipairs(tCondition) do
        local tCheck = self._getAllConditionCheck(tLine, tC)
        local bFit = true
        for szKey, bResult in pairs(tCheck) do
            if not bResult then
                bFit = false
                LOG.INFO("[Sprint Condition] [%d]条件不满足：%s", tLine.nIndex, szKey)
                break
            end
        end
        if bFit then
            LOG.INFO("当前满足条件: %d", tLine.nIndex)
            return tLine
        end
    end
end

--匹配条件（性能优化版）
function FuncSlotMgr._fastGetFitAction(dwBitOPSchoolID, tC)
    local tConditionRoot = m_tbConditionRoot[dwBitOPSchoolID]
    if not tConditionRoot then
        return
    end

    if not tC then
        return
    end

    -- --[弃用] 短路返回的TreeMatch，这种最快，但是跟端游逻辑不同，端游会按ipairs遍历顺序取第一个满足条件的tLine，
    -- return self._treeMatchShort(tConditionRoot, tC, 1)

    m_tMatch = {}
    self._treeMatch(tConditionRoot, tC, 1) --按条件树匹配收集所有满足的tLine

    --找到满足条件的nIndex最小的tLine，使逻辑与端游一致
    local nMinIndex, tMatchLine = 0xffffffff, nil
    for nIndex, tLine in pairs(m_tMatch) do
        if nIndex < nMinIndex then
            nMinIndex = nIndex
            tMatchLine = tLine
        end
    end

    return tMatchLine
end

function FuncSlotMgr._getPlayerInfo(player)
    if not player then
        return
    end

    local tC = m_tC or {}

    local nMoveState = player.nMoveState
    local bSprintFlag = player.bSprintFlag
    if nMoveState ~= tC.nMoveState then
        SprintData.UpdateSwimState(nMoveState)
    end
    if bSprintFlag ~= tC.bSprintFlag then
        Event.Dispatch(EventType.OnPlayerSprintStateChanged, bSprintFlag)
    end

    tC.bJumping = nMoveState ~= MOVE_STATE.ON_RUN
    tC.nJumpCount = player.nJumpCount
    tC.bWeapon = GetPlayerWeaponType(player) == GetBitOPSchoolIDWeaponType(player.dwBitOPSchoolID)
    tC.bFighting = player.bFightState
    tC.bSprintFlag = bSprintFlag
    tC.nTargetType = player.GetTarget()
    tC.bFollowController = player.IsFollowController()
    tC.bFollower = player.IsFollower()
    tC.bRunOnWater = player.IsRunOnWater() == 1
    tC.bOnHorse = player.bOnHorse
    tC.bIgnoreGravity = player.bIgnoreGravity
    tC.nDirection8 = player.nDirection8
    tC.bSlideSprintFlag = player.bSlideSprintFlag
    tC.bHangFlag = player.bHangFlag --IsPlayerInHang()
    tC.bOnTowerFlag = player.bOnTowerFlag
    tC.bParkourFlag = player.bParkourFlag
    tC.bIsHasValidTrack = SprintEx_HasValidTrack()
    tC.bCanTowerFlag = MapMgr.SprintGetSummitID() > 0 and GameSettingData.GetNewValue(UISettingKey.AutoClimb) --是否可登顶
    tC.bInProgress = TipsHelper.IsProgressBarShow()
    tC.bInStickCamera = true --IsInStickCamera() --端游是只有在攀爬的时候判断是否在按右键拖视角用的，现在视角默认就是这种状态

    --以下为新增
    tC.bHoldHorse = player.bHoldHorse
    tC.nFollowType = player.nFollowType
    tC.nMoveState = nMoveState
    tC.bCanForceEndRoadTrack = player.nCurrentTrack ~= 0 and CanForceEndRoadTrack() --C++那边nCurrentTrack==0的话会一直刷日志，这里加个判断
    tC.nSpecialState = SprintData.GetSpecialState() or 0
    return tC
end



-------------------------------- 条件检测相关 --------------------------------

--性能优化：

--检测类型，将下面原版检测算法中各项检测函数分类
local tCheckType = {
    n = 1, --数字
    b = 2, --布尔
    fn = 3 --函数
}

--定义：配置表key、实时玩家数据表的key、检测类型、默认值、检测函数
local tCheckInfos = {
    { szCfgKey = "nJumpCount",                  szDataKey = "nJumpCount",               nCheckType = tCheckType.n,  default = -1 },
    { szCfgKey = "nTeammate",                   szDataKey = nil,                        nCheckType = tCheckType.fn, default = -1, fnCheck = function(cfg, data) return self._checkTeammate(cfg) end },
    { szCfgKey = "dwBuffID",                    szDataKey = nil,                        nCheckType = tCheckType.fn, default = -1, fnCheck = function(cfg, data) return self._checkBuff(cfg) end },
    { szCfgKey = "szKeyState",                  szDataKey = nil,                        nCheckType = tCheckType.fn, default = "", fnCheck = function(cfg, data) return self._checkKeyState(self._getSzKeyTable("szKeyState", cfg)) end },
    { szCfgKey = "szMoveState",                 szDataKey = nil,                        nCheckType = tCheckType.fn, default = "", fnCheck = function(cfg, data) return self._checkMoveState(self._getSzKeyTable("szMoveState", cfg)) end },
    { szCfgKey = "szHangVelocityAndDirection",  szDataKey = nil,                        nCheckType = tCheckType.fn, default = "", fnCheck = function(cfg, data) return self._checkVelocityAndDirection(self._getSzKeyTable("szHangVelocityAndDirection", cfg)) end },
    { szCfgKey = "nJumping",                    szDataKey = "bJumping",                 nCheckType = tCheckType.b,  default = -1 },
    { szCfgKey = "nWeaponCheck",                szDataKey = "bWeapon",                  nCheckType = tCheckType.b,  default = -1 },
    { szCfgKey = "nSprintFlag",                 szDataKey = "bSprintFlag",              nCheckType = tCheckType.b,  default = -1 },
    { szCfgKey = "nFollowController",           szDataKey = "bFollowController",        nCheckType = tCheckType.b,  default = -1 },
    { szCfgKey = "szTargetType",                szDataKey = "nTargetType",              nCheckType = tCheckType.fn, default = "", fnCheck = function(cfg, data) return (cfg == "" or (string.byte(cfg) == 33 and TARGET[cfg:sub(2)] ~= data) or TARGET[cfg] == data) end },
    { szCfgKey = "nFollower",                   szDataKey = "bFollower",                nCheckType = tCheckType.b,  default = -1 },
    { szCfgKey = "nFighting",                   szDataKey = "bFighting",                nCheckType = tCheckType.b,  default = -1 },
    { szCfgKey = "nRunOnWater",                 szDataKey = "bRunOnWater",              nCheckType = tCheckType.b,  default = -1 },
    { szCfgKey = "nIgnoreGravity",              szDataKey = "bIgnoreGravity",           nCheckType = tCheckType.b,  default = -1 },
    { szCfgKey = "nDirection8",                 szDataKey = "nDirection8",              nCheckType = tCheckType.n,  default = -1 },
    { szCfgKey = "nHangFlag",                   szDataKey = "bHangFlag",                nCheckType = tCheckType.b,  default = -1 },
    { szCfgKey = "nOnTowerFlag",                szDataKey = "bOnTowerFlag",             nCheckType = tCheckType.b,  default = -1 },
    { szCfgKey = "nCanTowerFlag",               szDataKey = "bCanTowerFlag",            nCheckType = tCheckType.b,  default = -1 },
    { szCfgKey = "nInProgress",                 szDataKey = "bInProgress",              nCheckType = tCheckType.b,  default = -1 },
    { szCfgKey = "nInStickCamera",              szDataKey = "bInStickCamera",           nCheckType = tCheckType.b,  default = -1 },
    { szCfgKey = "nOnHorse",                    szDataKey = "bOnHorse",                 nCheckType = tCheckType.b,  default = -1 },
    { szCfgKey = "nParkourFlag",                szDataKey = "bParkourFlag",             nCheckType = tCheckType.b,  default = -1 },
    { szCfgKey = "nIsHasValidTrack",            szDataKey = "bIsHasValidTrack",         nCheckType = tCheckType.b,  default = -1 },
    { szCfgKey = "bSlideSprintFlag",            szDataKey = "bSlideSprintFlag",         nCheckType = tCheckType.b,  default = -1 },

    --以下为新增
    { szCfgKey = "bHoldHorse",                  szDataKey = "bHoldHorse",               nCheckType = tCheckType.b,  default = -1 },
    { szCfgKey = "szFollowType",                szDataKey = "nFollowType",              nCheckType = tCheckType.fn, default = "" , fnCheck = function(cfg, data) return (cfg == "" or (string.byte(cfg) == 33 and FOLLOW_TYPE[cfg:sub(2)] ~= data) or FOLLOW_TYPE[cfg] == data) end },
    { szCfgKey = "nMoveState",                  szDataKey = "nMoveState",               nCheckType = tCheckType.n,  default = -1 },
    { szCfgKey = "bCanForceEndRoadTrack",       szDataKey = "bCanForceEndRoadTrack",    nCheckType = tCheckType.b,  default = -1 },
    { szCfgKey = "nSpecialState",               szDataKey = "nSpecialState",            nCheckType = tCheckType.n,  default = -1 },
}

--原版：
function FuncSlotMgr._getAllConditionCheck(tLine, tC)
    local tCheck = {}
    --这些key是纯作打印用的
    tCheck["nJumpCount"] = tLine.nJumpCount == -1 or tLine.nJumpCount == tC.nJumpCount
    tCheck["nTeammate"] = self._checkTeammate(tLine.nTeammate)
    tCheck["dwBuffID"] = self._checkBuff(tLine.dwBuffID)
    tCheck["tKeyState"] = self._checkKeyState(tLine.tKeyState)
    tCheck["tMoveState"] = self._checkMoveState(tLine.tMoveState)
    tCheck["tVelocityDirection"] = self._checkVelocityAndDirection(tLine.tVelocityDirection)
    tCheck["nJumping"] = tLine.nJumping == -1 or (tLine.nJumping == 1) == tC.bJumping
    tCheck["nWeaponCheck"] = tLine.nWeaponCheck == -1 or (tLine.nWeaponCheck == 1) == tC.bWeapon
    tCheck["nSprintFlag"] = tLine.nSprintFlag == -1 or (tLine.nSprintFlag == 1) == tC.bSprintFlag
    tCheck["nFollowController"] = tLine.nFollowController == -1 or (tLine.nFollowController == 1) == tC.bFollowController
    tCheck["nFollower"] = tLine.nFollower == -1 or (tLine.nFollower == 1) == tC.bFollower
    tCheck["szTargetType"] = (tLine.szTargetType == "" or (string.byte(tLine.szTargetType) == 33 and TARGET[tLine.szTargetType:sub(2)] ~= tC.nTargetType) or TARGET[tLine.szTargetType] == tC.nTargetType)
    tCheck["nFighting"] = tLine.nFighting == -1 or (tLine.nFighting == 1) == tC.bFighting
    tCheck["nRunOnWater"] = tLine.nRunOnWater == -1 or (tLine.nRunOnWater == 1) == tC.bRunOnWater
    tCheck["nIgnoreGravity"] = tLine.nIgnoreGravity == -1 or (tLine.nIgnoreGravity == 1) == tC.bIgnoreGravity
    tCheck["nDirection8"] = tLine.nDirection8 == -1 or tLine.nDirection8 == tC.nDirection8
    tCheck["nHangFlag"] = tLine.nHangFlag == -1 or (tLine.nHangFlag == 1) == tC.bHangFlag
    tCheck["nOnTowerFlag"] = tLine.nOnTowerFlag == -1 or (tLine.nOnTowerFlag == 1) == tC.bOnTowerFlag
    tCheck["nCanTowerFlag"] = tLine.nCanTowerFlag == -1 or (tLine.nCanTowerFlag == 1) == tC.bCanTowerFlag
    tCheck["nInProgress"] = tLine.nInProgress == -1 or (tLine.nInProgress == 1) == tC.bInProgress
    tCheck["nInStickCamera"] = tLine.nInStickCamera == -1 or (tLine.nInStickCamera == 1) == tC.bInStickCamera
    tCheck["nOnHorse"] = tLine.nOnHorse == -1 or (tLine.nOnHorse == 1) == tC.bOnHorse
    tCheck["nParkourFlag"] = tLine.nParkourFlag == -1 or (tLine.nParkourFlag == 1) == tC.bParkourFlag
    tCheck["nIsHasValidTrack"] = tLine.nIsHasValidTrack == -1 or (tLine.nIsHasValidTrack == 1) == tC.bIsHasValidTrack
    tCheck["bSlideSprintFlag"] = tLine.bSlideSprintFlag == -1 or (tLine.bSlideSprintFlag == 1) == tC.bSlideSprintFlag

    --新增
    tCheck["bHoldHorse"] = tLine.bHoldHorse == -1 or (tLine.bHoldHorse == 1) == tC.bHoldHorse
    tCheck["szFollowType"] = (tLine.szFollowType == "" or (string.byte(tLine.szFollowType) == 33 and FOLLOW_TYPE[tLine.szFollowType:sub(2)] ~= tC.nFollowType) or FOLLOW_TYPE[tLine.szFollowType] == tC.nFollowType)
    tCheck["nMoveState"] = tLine.nMoveState == -1 or tLine.nMoveState == tC.nMoveState
    tCheck["bCanForceEndRoadTrack"] = tLine.bCanForceEndRoadTrack == -1 or (tLine.bCanForceEndRoadTrack == 1) == tC.bCanForceEndRoadTrack
    tCheck["nSpecialState"] = tLine.nSpecialState == -1 or tLine.nSpecialState == tC.nSpecialState
    return tCheck
end

function FuncSlotMgr._checkTeammate(nTeammate)
    if nTeammate == -1 then
        return true
    end

    local hTeam = GetClientTeam()
    local hPlayer = GetClientPlayer()
    if not hPlayer or not hTeam then
        return false
    end
    local nTargetType, dwTargetID = hPlayer.GetTarget()
    if nTargetType ~= TARGET.PLAYER then
        return false
    end
    local bInTeam = hTeam.IsPlayerInTeam(dwTargetID)
    return (nTeammate == 1) == bInTeam
end

function FuncSlotMgr._checkBuff(dwBuffID)
    if dwBuffID == -1 then
        return true
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return false
    end

    local bHave = hPlayer.IsHaveBuff(dwBuffID, 0) --Buff_Have(hPlayer, dwBuffID, 0)
    return bHave
end

--按键检测转换为摇杆
function FuncSlotMgr._isKeyStateFit(szKey, nValue)
    if nValue == -1 then
        return true
    end

    if nValue == 0 then
        return not tbVirtualDirKey[szKey]
    else
        return tbVirtualDirKey[szKey]
    end

    if szKey == "SHIFT" then
        return IsShiftKeyDown()
    elseif szKey == "ALT" then
        return IsAltKeyDown()
    elseif szKey == "CTRL" then
        return IsCtrlKeyDown()
    else
        return IsKeyDown(szKey)
    end
end

function FuncSlotMgr._checkKeyState(tKeyState)
    if #tKeyState == 0 then
        return true
    end
    for _, v in ipairs(tKeyState) do
        local szKey = v[1]
        local nValue = v[2]
        local bFit = self._isKeyStateFit(szKey, nValue)
        if not bFit then
            return false
        end
    end
    return true
end

function FuncSlotMgr._checkMoveState(tMoveState)
    if #tMoveState == 0 then
        return true
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return false
    end

    for _, v in ipairs(tMoveState) do
        local szKey = v[1]
        local nValue = v[2]
        local bInState = hPlayer.nMoveState == MOVE_STATE[szKey]
        if ((nValue == 1) == bInState) then
            return true
        end
    end

    return false
end

function FuncSlotMgr._checkVelocityAndDirection(tVelocityDirection)
    if #tVelocityDirection == 0 then
        return true
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return false
    end

    for _, v in ipairs(tVelocityDirection) do
        local nV1 = v[1]
        local nV2 = v[2]
        local nD1 = v[3]
        local nD2 = v[4]
        if
            hPlayer.nHangVelocityXY >= nV1 and hPlayer.nHangVelocityXY <= nV1 and hPlayer.nHangDirectionXY >= nD1 and
                hPlayer.nHangDirectionXY <= nD2
         then
            return true
        end
    end

    return false
end

-------------------------------- 读取配置相关 --------------------------------

function FuncSlotMgr._loadSlotBtnDatas()
    m_tbActionDatas = {}

    local tTabConfig
    if m_szSprintMode == GameSettingType.SprintMode.Classic.szDec then
        tTabConfig = UIFuncSlotBtnTab
    elseif m_szSprintMode == GameSettingType.SprintMode.Simple.szDec or m_szSprintMode == GameSettingType.SprintMode.Common.szDec then
        tTabConfig = UIFuncSlotBtnTab_Simple
    end

    for nBtnID, tbConfig in pairs(tTabConfig or {}) do
        local tbActionData = {}

        local nIndex = 1
        local nSlotIndex = tbConfig.nSlotIndex1
        while (nSlotIndex and nSlotIndex > 0) do
            local szDesc = tbConfig["szBtnDesc" .. nIndex]
            if not szDesc or szDesc == "" then
                szDesc = tbConfig.szDesc
            end

            local tbBtnData = {
                nEventType = tbConfig["nEventType" .. nIndex],
                tbCommand = string.split(tbConfig["szCommands" .. nIndex], ";"),
                szImgPath = tbConfig["szImgPath" .. nIndex],
                nClickCD = tbConfig["nClickCD" .. nIndex],
                szDesc = szDesc,
                nBtnID = nBtnID,
            }
            tbActionData[nSlotIndex] = tbBtnData

            local szKey = tbConfig["szKey" .. nIndex]
            local szKeyName, szKeyState = string.match(szKey, "<(.+);(.+)>")
            tbBtnData.tbKeyInfo = {
                szKeyDesc = tbConfig["szKeyDesc" .. nIndex],
                szKeyName = szKeyName or szKey, --DX Binding
                nKeyState = tonumber(szKeyState) or -1, --0: Down, 1: Up, 2:Double down, 3: Double Up, -1: Other
            }

            nIndex = nIndex + 1
            nSlotIndex = tbConfig["nSlotIndex" .. nIndex]
        end
        m_tbActionDatas[nBtnID] = tbActionData
    end
end

function FuncSlotMgr._loadSprintCondition()
    self._optimizeCheckInfoOrder()

    --g_tTable.SprintCondition为端游用Condition表
    --考虑到端游表格以后可能会修改，所以手游相关的额外需求不在这个表上改动
    --引入一个新表UIFuncSlotConditionTab来实现一些额外条件、条件Action覆盖的功能
    local nCount = g_tTable.SprintCondition:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.SprintCondition:GetRow(i)
        self._insertSprintCondition(clone(tLine), true)
    end

    for nIndex, tLine in pairs(UIFuncSlotConditionTab) do
        --self._insertSprintCondition(clone(tLine))
        local tCloneLine = {}
        for i, v in ipairs(tCheckInfos) do
            tCloneLine[v.szCfgKey] = tLine[v.szCfgKey]
        end
        tCloneLine.nIndex = tLine.nIndex
        tCloneLine.dwBitOPSchoolID = tLine.dwBitOPSchoolID
        tCloneLine.szAction = tLine.szAction
        tCloneLine.szDesc = tLine.szDesc
        tCloneLine.szComment = tLine.szComment
        self._insertSprintCondition(tCloneLine)
    end

    --轻功段数相关处理
    for dwBitOPSchoolID, tSchoolLine in pairs(m_tbCondition) do
        for nIndex, tLine in pairs(tSchoolLine) do
            if tLine.szSprintName and tLine.szSprintType then
                local szFullName = tLine.szSprintName .. tLine.szSprintType
                tLine.nSprintMaxPhase = m_tbSprintMaxPhase[szFullName]
            end
        end
    end

    --print_table_utf8(m_tbConditionRoot)
    --print_table_utf8(m_tbSprintMaxPhase)
end

function FuncSlotMgr._insertSprintCondition(tLine, bBaseConfig)
    --tAction转int table
    local tAction = {}

    local szAction = tLine.szAction
    if bBaseConfig then
        --额外功能：若新表中有相同ID，则仅使用新表中的Action列覆盖旧表，前面几列是不会覆盖的
        local tOverrideLine = UIFuncSlotConditionTab[tLine.nIndex]
        if tOverrideLine then
            szAction = tOverrideLine.szAction
        end
    else
        local baseLine = g_tTable.SprintCondition:Search(tLine.nIndex)
        if baseLine then
            return
        end
    end

    local tStrAction = string.split(szAction, ";")
    for i = 1, #tStrAction do
        local szActionID = tStrAction[i]
        if szActionID ~= "" then
            tAction[i] = tonumber(szActionID)
        end
    end

    tLine.tAction = tAction
    tLine.tDisplay = string.split(tLine.szDisplay, ";")
    tLine.tKeyState = self._parseKey(tLine.szKeyState)
    tLine.tMoveState = self._parseKey(tLine.szMoveState)
    if tLine.szOTActionBar ~= "" then
        tLine.tOTActionBar = self._parseOTActionBar(tLine.szOTActionBar)
    end
    tLine.tVelocityDirection = self._parseVelocityDirection(tLine.szHangVelocityAndDirection)

    --新增
    tLine.bHoldHorse = tLine.bHoldHorse or -1
    tLine.szFollowType = tLine.szFollowType or ""
    tLine.nMoveState = tLine.nMoveState or -1
    tLine.bCanForceEndRoadTrack = tLine.bCanForceEndRoadTrack or -1
    tLine.nSpecialState = tLine.nSpecialState or 0

    local dwBitOPSchoolID = tLine.dwBitOPSchoolID
    if not m_tbCondition[dwBitOPSchoolID] then
        m_tbCondition[dwBitOPSchoolID] = {}
    end

    if bBaseConfig then
        tLine.szDesc = UIHelper.GBKToUTF8(tLine.szDesc)
        tLine.szComment = UIHelper.GBKToUTF8(tLine.szComment)
    end

    --原版：将config存到数组中
    table.insert(m_tbCondition[dwBitOPSchoolID], tLine)

    --性能优化：用树存储Condition配置，优化搜索速度
    if not m_tbConditionRoot[dwBitOPSchoolID] then
        m_tbConditionRoot[dwBitOPSchoolID] = {}
    end

    self._insertTree(m_tbConditionRoot[dwBitOPSchoolID], tLine, 1)

    --为了用string作为tree的key而不为table，先将每种sz的parse结果存到另外的地方
    self._parseSzKey("szKeyState", tLine)
    self._parseSzKey("szMoveState", tLine)
    self._parseSzKey("szHangVelocityAndDirection", tLine)

    --根据描述文本解析出轻功的当前段数和最大段数
    self._parseSprintPhaseInfo(tLine)
end

function FuncSlotMgr._parseSzKey(szCfgKey, tLine)
    local szKey = tLine[szCfgKey]
    if m_tbSzKey[szCfgKey] and m_tbSzKey[szCfgKey][szKey] then
        return
    end

    local t
    if szCfgKey == "szKeyState" or szCfgKey == "szMoveState" then
        t = self._parseKey(szKey)
    elseif szCfgKey == "szHangVelocityAndDirection" then
        t = self._parseVelocityDirection(szKey)
    end

    if not t then
        return
    end

    if not m_tbSzKey[szCfgKey] then
        m_tbSzKey[szCfgKey] = {}
    end
    m_tbSzKey[szCfgKey][szKey] = t
end

function FuncSlotMgr._getSzKeyTable(szCfgKey, szKey)
    return m_tbSzKey[szCfgKey] and m_tbSzKey[szCfgKey][szKey] or {}
end

--"<a;-1;1><b;0;0>"
function FuncSlotMgr._parseKey(szKey)
    local tList = {}
    for v in string.gmatch(szKey, "<([%w;-_]+)>") do
        local t = string.split(v, ";") --SplitString(v, ";")
        t[2] = tonumber(t[2])
        table.insert(tList, t)
    end
    return tList
end

function FuncSlotMgr._parseVelocityDirection(szKey)
    local tList = {}
    for v in string.gmatch(szKey, "<([%w;-~]+)>") do
        local t = string.split(v, ";") --SplitString(v, ";")
        local nV1, nV2 = string.match(t[1], "([%d-]+)~([%d-])")
        local nD1, nD2 = string.match(t[2], "([%d-]+)~([%d-])")
        t = {nV1, nV2, nD1, nD2}
        table.insert(tList, t)
    end
    return tList
end

function FuncSlotMgr._parseOTActionBar(szKey)
    local t = string.split(szKey, ";")
    t[1] = tonumber(t[1])
    t[2] = tonumber(t[2])
    return t
end

-- 一苇渡江·一段        -> szSprintName = "一苇渡江", nSprintPhase = 1, szSprintType = ""
-- 一苇渡江·莲台二段    -> szSprintName = "一苇渡江", nSprintPhase = 2, szSprintType = "莲台"
function FuncSlotMgr._parseSprintPhaseByDesc(szDesc)
    for nNum, szNum in pairs(g_tStrings.STR_NUMBER) do
        --中文好像不能用[]匹配？
        local szPrefix = string.match(szDesc, "(.+)" .. szNum .. "段")
        if szPrefix then
            local szName, szType = string.match(szPrefix, "(.*)·(.*)")
            return szPrefix, szType, nNum
        end
    end
end

function FuncSlotMgr._parseSprintPhaseInfo(tLine)
    local nIndex = tLine.nIndex
    local szDesc = tLine.szDesc

    local szSprintName, szSprintType, nSprintPhase = self._parseSprintPhaseByDesc(szDesc)
    if not szSprintName or not nSprintPhase then
        return
    end

    tLine.szSprintName = szSprintName
    tLine.nSprintPhase = nSprintPhase   --当前轻功段数
    tLine.szSprintType = szSprintType
    local szFullName = szSprintName .. szSprintType
    if not m_tbSprintMaxPhase[szFullName] or nSprintPhase > m_tbSprintMaxPhase[szFullName] then
        m_tbSprintMaxPhase[szFullName] = nSprintPhase
    end
end

function FuncSlotMgr._optimizeCheckInfoOrder()
    --统计值种类最多的szCfgKey
    local tStatistics = {}
    local nCount = g_tTable.SprintCondition:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.SprintCondition:GetRow(i)
        for j = 1, #tCheckInfos do
            local szKey = tCheckInfos[j].szCfgKey
            local val = tLine[szKey]
            if not val then
                val = tCheckInfos[j].default
            end

            if not tStatistics[szKey] then
                tStatistics[szKey] = {}
            end
            if not tStatistics[szKey][val] then
                tStatistics[szKey][val] = 0
            end
            tStatistics[szKey][val] = tStatistics[szKey][val] + 1
        end
    end
    --print_table(tStatistics)

    local tValueType = {}
    for szCfgKey, tValue in pairs(tStatistics) do
        if not tValueType[szCfgKey] then
            tValueType[szCfgKey] = 0
        end
        for k, v in pairs(tValue) do
            tValueType[szCfgKey] = tValueType[szCfgKey] + 1
        end
    end
    --print_table(tValueType)

    --按值种类升序排列，减少搜索时遍历次数
    table.sort(tCheckInfos, function(a, b)
        if tValueType[a.szCfgKey] then
            return tValueType[a.szCfgKey] < tValueType[b.szCfgKey]
        end
        return false
    end)
    --print_table(tCheckInfos)
end

function FuncSlotMgr._insertTree(node, tLine, nIndex)
    local tbCheck = tCheckInfos[nIndex]
    if tbCheck then
        local cfg = tLine[tbCheck.szCfgKey]
        if not node[cfg] then
            node[cfg] = {}
        end
        self._insertTree(node[cfg], tLine, nIndex + 1)
    else
        --同条件的tLine取第一个，与端游逻辑保持一致
        if not node.tLine then
            node.tLine = tLine
        else
            --LOG.INFO("Condition insert Warning, same condition: %d, %d", node.tLine.nIndex, tLine.nIndex)
        end
    end
end

function FuncSlotMgr._treeMatch(node, tC, nIndex)
    if not node then
        return
    end

    local tbCheck = tCheckInfos[nIndex]
    if tbCheck then
        local data = tC[tbCheck.szDataKey]
        local fnCheck = tbCheck.fnCheck
        local nCheckType = tbCheck.nCheckType
        local default = tbCheck.default

        -- tCheckType.n => cfg == -1 or cfg == data
        -- tCheckType.b => cfg == -1 or (cfg == 1) == data
        -- tCheckType.fn => fnCheck(cfg, data)

        if nCheckType == tCheckType.n or nCheckType == tCheckType.b then

            --优先判断是否为默认值
            self._treeMatch(node[default], tC, nIndex + 1)

            local key = nCheckType == tCheckType.n and data or (data and 1 or 0)
            self._treeMatch(node[key], tC, nIndex + 1)
        else
            --优先判断是否为默认值
            if node[default] then
                if fnCheck(default, data) then
                    self._treeMatch(node[default], tC, nIndex + 1)
                end
            end

            for cfg, nextNode in pairs(node) do
                if cfg ~= default then
                    if fnCheck(cfg, data) then
                        self._treeMatch(nextNode, tC, nIndex + 1)
                    end
                end
            end
        end
    else
        --收集所有符合条件的tLine，若有多个，则之后再按优先级决定用哪条
        local nIndex = node.tLine.nIndex
        if not m_tMatch[nIndex] then
            m_tMatch[nIndex] = node.tLine
        end
    end
end

--[弃用] 短路返回的TreeMatch，这种最快，但是跟端游逻辑不同，端游会按ipairs遍历顺序取第一个满足条件的tLine，所以改成用上面那种收集的形式
function FuncSlotMgr._treeMatchShort(node, tC, nIndex)
    if not node then
        return
    end

    local tbCheck = tCheckInfos[nIndex]
    if tbCheck then
        local data = tC[tbCheck.szDataKey]
        local fnCheck = tbCheck.fnCheck
        local nCheckType = tbCheck.nCheckType
        local default = tbCheck.default

        -- tCheckType.n => cfg == -1 or cfg == data
        -- tCheckType.b => cfg == -1 or (cfg == 1) == data
        -- tCheckType.fn => fnCheck(cfg, data)

        if nCheckType == tCheckType.n or nCheckType == tCheckType.b then

            --优先判断是否为默认值
            local result = self._treeMatchShort(node[default], tC, nIndex + 1)
            if result then
                return result
            end

            local key = nCheckType == tCheckType.n and data or (data and 1 or 0)
            local result = self._treeMatchShort(node[key], tC, nIndex + 1)
            if result then
                return result
            end
        else
            --优先判断是否为默认值
            if node[default] then
                if fnCheck(default, data) then
                    local result = self._treeMatchShort(node[default], tC, nIndex + 1)
                    if result then
                        return result
                    end
                end
            end

            for cfg, nextNode in pairs(node) do
                if cfg ~= default then
                    if fnCheck(cfg, data) then
                        local result = self._treeMatchShort(nextNode, tC, nIndex + 1)
                        if result then
                            return result
                        end
                    end
                end
            end
        end
    else
        return node.tLine
    end
end

function FuncSlotMgr._registerEvent()
    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        self._updateSlotByActionList(nil, true)
    end)
    Event.Reg(self, "FIGHT_HINT", function(bFight)
        self.InvokeFuncSlotChanged()
    end)
    Event.Reg(self, "UPDATE_SELECT_TARGET", function()
        for nSlotIndex, tbBtnData in pairs(m_tbSlotBtnDatas) do
            --性能优化：只有存在UIWIdgetRightBottonFunction中需要用到player.GetTarget()接口的按钮才需要触发刷新
            --10032传功，10040双人同骑
            if tbBtnData.nBtnID == 10032 or tbBtnData.nBtnID == 10040 then
                self.InvokeFuncSlotChanged() --用于刷新选中目标时刷新显隐/置灰状态的按钮
                return
            end
        end
    end)
    Event.Reg(self, EventType.OnSprintSettingChange, function()
        m_szSprintMode = GameSettingData.GetNewValue(UISettingKey.SprintMode).szDec
        self._loadSlotBtnDatas()
        self._updateSlotByActionList(m_tbAction, true)
    end)
end