-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: AutoBattle
-- Date: 2023-12-11 22:36:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

AutoBattle = AutoBattle or { className = "AutoBattle" }
AutoBattle.bAuto = false
AutoBattle.bUseInitialQueue = false -- 进入战斗时仅执行1次的技能序列
AutoBattle.nMaxCustomizeNum = 13
AutoBattle.szMacroText = nil
AutoBattle.tInitialQueue = nil
AutoBattle.nLastIndex = nil
AutoBattle.bInFight = false
AutoBattle.bIsVKRecommend = false
AutoBattle.bIsHD = false

local self = AutoBattle
local nFuYaoBuffID = 70215
local nIntervalTime_normal = 1 / 8
local nIntervalTime_Special = 1.5
local nIntervalTime = nIntervalTime_normal

local tTotalBattleSlotIndexes = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }
local tBattleSlotIndexes = { 1, 2, 3, 4, 5, 6 }

-- 奶秀、奶歌选中重伤目标时，武学助手不自动释放普攻
local tNoCastCommonSkillWithDeadTarget = {
    [100409] = true, -- 奶秀
    [101125] = true, -- 奶歌
}

function AutoBattle.Init()
    local szPath = "ui/String/SkillMacro.lua"
    LoadScriptFile(szPath, AutoBattle)
end

function AutoBattle.UnInit()

end

function AutoBattle.IsInAutoBattle()
    return AutoBattle.bAuto
end

function AutoBattle.Start()
    if not g_pClientPlayer or g_pClientPlayer.nLevel < 120 then
        return
    end

    if PublicQuestData.IsInCampPQ() then
        TipsHelper.ShowImportantBlueTip("当前区域内无法使用武学助手")
        return
    end

    if ArenaData.IsInArena() or MapHelper.IsInBattleField() then
        TipsHelper.ShowImportantBlueTip("本地图无法开启武学助手")
        return
    end

    local bIsSpecialMap = MapHelper.GetMapID() == 580 or MapHelper.IsRemotePvpMap() -- 特殊地图ID
    nIntervalTime = bIsSpecialMap and nIntervalTime_Special or nIntervalTime_normal

    if not self.bAuto then
        if not self.bIsHD and not g_pClientPlayer.bFightState and RedpointHelper.PanelSkill_ShowApplyButtonRedPoint() then
            local script = UIMgr.Open(VIEW_ID.PanelSkillRecommend, g_pClientPlayer.GetActualKungfuMountID())
            script:PopPveApplyTip()
        end

        if not DungeonData.IsInDungeon() then
            StopFollow()
        end

        AutoBattle.nKungFuID = g_pClientPlayer.GetActualKungfuMountID()
        AutoBattle.bIsHD = SkillData.IsUsingHDKungFu(AutoBattle.nKungFuID)
        AutoBattle.bAuto = true
        AutoBattle.ResetCustomData()
        SprintData.SetViewState(false)
        TipsHelper.ShowImportantBlueTip("进入武学助手状态")
        Event.Dispatch(EventType.OnAutoBattleStateChanged)
        ReportAutoBattle(true)
        Timer.DelAllTimer(self)
        self.nBattleTimer = Timer.AddCycle(self, nIntervalTime, self.CastSkillCycle)
    end
end

function AutoBattle.GetSlotSkill(i)
    if self.bIsHD then
        if SkillData.CacheSlotInfo and SkillData.CacheSlotInfo.nSkillID then
            return SkillData.CacheSlotInfo.nSkillID -- SimpleSkill 只能用这个方式获取技能ID
        end
        local tData = SkillData.GetDxSlotData(i)
        if tData.nType == DX_ACTIONBAR_TYPE.SKILL then
            return tData.data1
        end
        return
    end

    local nSkillID = UIBattleSkillSlot.GetShowUI_Ver2(i)
    if nSkillID then
        self.tSkillIDToSlotIndex[nSkillID] = i

        if TabHelper.GetUISkill(nSkillID).nAutoPriority ~= nil then
            table.insert(self.tSkillInSlot, nSkillID) -- 没有配置nAutoPriority的不参与自动战斗顺序
        end
        return nSkillID
    end
end

local fnCastSkill = function(player, nSkillID, nSlotIndex)
    if nSlotIndex and nSkillID then
        local _, nLeft, nTotal, nCount, nMaxCount, bIsRecharge, bPublicCD = SkillData.GetSkillCDProcess(player, nSkillID)
        local bCanCast = SkillData.CanCastSkill(player, nSkillID)
        --print("AutoBattle.CustomStrategy CD", nSkillID, bPublicCD, nLeft, nTotal, bCanCast, player.GetOTActionState(), CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL)
        local tSkillConfig = TabHelper.GetUISkill(nSkillID)
        if tSkillConfig and tSkillConfig.nType == UISkillType.Append then
            local pSkill = SkillData.GetSkill(player, nSkillID)
            local dwPublicCDID = pSkill and pSkill.GetPublicCoolDown()
            if dwPublicCDID == 0 then
                bPublicCD = true -- 特殊情况如丐帮普攻二段使用的衔接CD，没有配置公共CD，因此将其视为公共CD状态，让队列在此技能处等待
            end
        end

        -- 奶秀、奶歌选中重伤目标时，武学助手不自动释放普攻
        if AutoBattle.nKungFuID and tSkillConfig and tSkillConfig.nType == UISkillType.Common and tNoCastCommonSkillWithDeadTarget[AutoBattle.nKungFuID] then
            local nTarType, nTarID = player.GetTarget()
            local playerData = Global.GetCharacter(nTarID)
            local bTargetDead = playerData and playerData.nMoveState == MOVE_STATE.ON_DEATH
            if bTargetDead then
                return false, false
            end
        end

        --print(nSkillID, nLeft, nTotal, nCount)
        if bCanCast then
            nLeft = nLeft or 0
            nTotal = nTotal or 1

            local bChargeAvailable = nMaxCount > 1 and nCount >= 1 -- 为充能透支激活 且 有剩余次数
            local bCool = nLeft > 0 or nTotal > 0
            if not bCool or (not bPublicCD and bChargeAvailable) then
                Event.Dispatch(EventType.OnShortcutUseSkillSelect, nSlotIndex, 1, true)
                Event.Dispatch(EventType.OnShortcutUseSkillSelect, nSlotIndex, 3, true)
                return true, bPublicCD --找到可释放的技能时，释放技能并停止循环
            end
        end
        return false, bPublicCD
    end
    return false, false
end

AutoBattle.TryCastSkill = fnCastSkill

function AutoBattle.CastSkillCycle()
    local player = g_pClientPlayer
    if not player then
        return
    end

    local bNewFightState = player.bFightState
    if AutoBattle.bInFight ~= bNewFightState and bNewFightState then
        self.ResetCustomData()

        if Storage.PanelSkill.bCheckTeach and self.bIsHD then
            CheckQixueAndRecipe()
        end
    end
    AutoBattle.bInFight = bNewFightState

    local nOTState = player.GetOTActionState()
    local bInFight = bNewFightState -- 只有战斗状态中可使用武学助手
    local bUsingMacro = not self.bUseInitialQueue and self.szMacroText and self.szMacroText ~= "" -- 使用宏时可无视读条判断
    local bInOTAction = nOTState == CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL or nOTState == CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE -- 玩家正在释放读条技能时不打断读条
    if not bInFight or (not bUsingMacro and bInOTAction) then
        return
    end

    if player.IsHaveBuff(70353, 1) then
        return -- 根据buff特判保护 vk霸刀 普攻 项王击鼎的第三放前摇
    end

    self.tSkillIDToSlotIndex = {}
    self.tSkillInSlot = {}

    local nCachedSlotID = SkillData.GetCacheSlotID()
    if nCachedSlotID then
        local nCachedSkillID = AutoBattle.GetSlotSkill(nCachedSlotID)
        fnCastSkill(player, nCachedSkillID, nCachedSlotID) -- 优先处理玩家手动缓存的技能
        return
    else
        if self.bIsHD then
            AutoBattle.DefaultStrategy()
        else
            for _, nSlotIndex in ipairs(AutoBattle.IsCustomized() and tTotalBattleSlotIndexes or tBattleSlotIndexes) do
                AutoBattle.GetSlotSkill(nSlotIndex)
            end

            if AutoBattle.IsCustomized() then
                AutoBattle.CustomStrategy()
            else
                AutoBattle.DefaultStrategy()
            end
        end
    end
end

---@param tSkillQueue table 技能队列
---@param bCastingInitialQueue boolean 是否在释放初始队列
---@return boolean 队列是否遍历完成
local function CastSkillInQueue(tSkillQueue, bCastingInitialQueue)
    local player = g_pClientPlayer
    if not tSkillQueue or IsTableEmpty(tSkillQueue) or not player then
        return true
    end

    --print("---start---")
    for i = 1, #tSkillQueue do
        local nCurrentIndex = AutoBattle.nSkillIndex
        local nSkillID = tSkillQueue[nCurrentIndex] -- 从当前nSkillIndex开始按顺序遍历整个列表，找到可释放的技能
        local nSlotIndex = AutoBattle.tSkillIDToSlotIndex[nSkillID]
        local bHasCast, bPublicCD = fnCastSkill(player, nSkillID, nSlotIndex)
        --print("Checking custom skill ", nCurrentIndex, nSkillID, bHasCast, bPublicCD)

        if not bPublicCD and not bHasCast and bCastingInitialQueue and AutoBattle.nLastIndex ~= nCurrentIndex then
            AutoBattle.nLastIndex = nCurrentIndex
            return false -- 在Default策略下 ，行剑千风等大招的特殊限制buff可能导致技能状态不正确，给第二次释放机会
        end

        if not bPublicCD then
            AutoBattle.nSkillIndex = nCurrentIndex + 1 <= #tSkillQueue and nCurrentIndex + 1 or 1 -- 公共CD时等待CD结束
        end

        if bPublicCD or bHasCast then
            return (nCurrentIndex == #tSkillQueue and not bPublicCD) --找到可释放的技能时，释放技能并停止循环
        end

        if bCastingInitialQueue and nCurrentIndex == #tSkillQueue then
            return true -- 队列遍历结束
        end
    end
    --return true -- 队列遍历结束
end

function AutoBattle.DefaultStrategy()
    local player = g_pClientPlayer

    if AutoBattle.bUseInitialQueue and AutoBattle.tInitialQueue then
        local bQueueFinished = CastSkillInQueue(AutoBattle.tInitialQueue, true)
        if bQueueFinished then
            AutoBattle.bUseInitialQueue = false
        end
        return
    end

    if self.bIsHD then
        UseMacroSkill(AutoBattle.szMacroText) --DX武学助手
        return
    end

    if AutoBattle.bIsVKRecommend and AutoBattle.szMacroText then
        UseMacroSkill(AutoBattle.szMacroText) --武学助手推荐增加宏的配置，宏>优先级
        return
    end

    table.sort(self.tSkillInSlot, function(a, b)
        local tbOrderA = TabHelper.GetUISkill(a).nAutoPriority or 0
        local tbOrderB = TabHelper.GetUISkill(b).nAutoPriority or 0
        return tbOrderA > tbOrderB  --根据技能优先级进行相应的排序
    end)

    for _, nSkillID in ipairs(self.tSkillInSlot) do
        local nSlotIndex = self.tSkillIDToSlotIndex[nSkillID]
        if fnCastSkill(player, nSkillID, nSlotIndex) then
            return --找到可释放的技能时，释放技能并停止循环
        end
    end
end

function AutoBattle.CustomStrategy()
    local lst = AutoBattle.GetCustomizeSkillList()
    local tSkillIDs = {}
    for i = 1, AutoBattle.nMaxCustomizeNum do
        if lst[i] then
            table.insert(tSkillIDs, lst[i])
        end
    end

    CastSkillInQueue(tSkillIDs)
end

function AutoBattle.Stop()
    if AutoBattle.bAuto then
        TipsHelper.ShowImportantBlueTip("退出武学助手状态")
        AutoBattle.bAuto = false
        AutoBattle.bInFight = false
        Event.Dispatch(EventType.OnAutoBattleStateChanged)
        ReportAutoBattle(false)
        Timer.DelAllTimer(self)
        if AutoBattle.IsAutoStopChannelSkill() then
            local player = g_pClientPlayer
            if not player then
                return
            end
            player.StopCurrentAction()
        end
    end
end

Event.Reg(AutoBattle, "LOADING_END", function(szEvent, ...)
    if ArenaData.IsInArena() or MapHelper.IsInBattleField() then
        AutoBattle.Stop()
    end

    Event.Dispatch(EventType.OnAutoBattleStateChanged)
end)

Event.Reg(AutoBattle, EventType.OnClientCastSkill, function(dwID)
    if AutoBattle.IsAutoClosedAfterSprint() and AutoBattle.IsInAutoBattle() then
        if dwID == UI_SKILL_DASH_ID then
            AutoBattle.Stop()  -- 聂云释放时时关闭自动战斗
        end

        if dwID == UI_SKILL_JUMP_ID and Player_IsBuffExist(nFuYaoBuffID) then
            AutoBattle.Stop()  -- 拥有扶摇buff时跳跃则关闭自动战斗
        end
    end
end)

Event.Reg(AutoBattle, EventType.OnClientPlayerLeave, function()
    AutoBattle.Stop()
end)

Event.Reg(AutoBattle, EventType.On_PQ_RequestDataReturn, function()
    if PublicQuestData.IsInCampPQ() then
        AutoBattle.Stop()
    end
end)

Event.Reg(AutoBattle, "SKILL_MOUNT_KUNG_FU", function(nKungfuMountID)
    AutoBattle.bIsHD = SkillData.IsUsingHDKungFu()
    AutoBattle.UpdateMacroText()  -- DX藏剑需要监听该事件以切换宏
end)

Event.Reg(AutoBattle, EventType.OnClientPlayerEnter, function()
    AutoBattle.bIsHD = SkillData.IsUsingHDKungFu()
end)

---------------------武学助手自定义---------------------------

function AutoBattle.IsAutoClosedAfterSprint()
    return Storage.SkillAutoCustomize.bIsAutoClosedAfterSprint
end

function AutoBattle.SetAutoClosedAfterSprint(bVal)
    Storage.SkillAutoCustomize.bIsAutoClosedAfterSprint = bVal
    CustomData.Dirty(CustomDataType.Role)
end

function AutoBattle.IsCustomized(nKungFuID)
    local tKungFuCustomize = Storage.SkillAutoCustomize.tKungFuCustomize
    if g_pClientPlayer then
        local nTargetKungFuID = nKungFuID or g_pClientPlayer.GetActualKungfuMountID()
        local nSetID = g_pClientPlayer.GetTalentCurrentSet(g_pClientPlayer.dwForceID, nTargetKungFuID)
        tKungFuCustomize[nTargetKungFuID] = tKungFuCustomize[nTargetKungFuID] or {}
        return tKungFuCustomize[nTargetKungFuID][nSetID] or false
    end
end

function AutoBattle.SetCustomized(bVal, nKungFuID)
    local tKungFuCustomize = Storage.SkillAutoCustomize.tKungFuCustomize
    if g_pClientPlayer then
        local nTargetKungFuID = nKungFuID or g_pClientPlayer.GetActualKungfuMountID()
        local nSetID = g_pClientPlayer.GetTalentCurrentSet(g_pClientPlayer.dwForceID, nTargetKungFuID)

        tKungFuCustomize[nTargetKungFuID] = tKungFuCustomize[nTargetKungFuID] or {}
        tKungFuCustomize[nTargetKungFuID][nSetID] = bVal
        CustomData.Dirty(CustomDataType.Role)
    end
end

function AutoBattle.ResetCustomData()
    local nKungFuID = g_pClientPlayer.GetActualKungfuMountID()
    local nSetID = g_pClientPlayer.GetTalentCurrentSet(g_pClientPlayer.dwForceID, nKungFuID)
    
    self.nSkillIndex = 1
    self.szMacroText = nil
    self.nLastIndex = nil
    
    self.bUseInitialQueue = self.tInitialQueue ~= nil
    self.nKungFuID = nKungFuID
    self.bIsVKRecommend = not self.bIsHD and SkillData.IsRecommendActivated(nKungFuID, nSetID)

    AutoBattle.UpdateMacroText()
end

function AutoBattle.UpdateMacroText()
    local nKungFuID = g_pClientPlayer.GetActualKungfuMountID()
    self.tInitialQueue = nil
    
    if self.bIsHD then
        self.szMacroText = UIHelper.GBKToUTF8(self.g_MacroStrings[nKungFuID] or "")
    else
        if UISkillRecommendTab[nKungFuID] and UISkillRecommendTab[nKungFuID].PVE and self.bIsVKRecommend then
            self.szMacroText = UISkillRecommendTab[nKungFuID].PVE.Macro
            self.tInitialQueue = UISkillRecommendTab[nKungFuID].PVE.InitialQueue

            if self.szMacroText == "" then
                self.szMacroText = nil
            end
        end
    end
end

function AutoBattle.SaveCustomizeSkill(nIndex, nSkillID, nKungFuID, nSetID)
    if nIndex < 1 or nIndex > AutoBattle.nMaxCustomizeNum or not nSkillID then
        return LOG.ERROR("SaveCustomizeSkill error")
    end
    local szKey = AutoBattle._GetKey(nKungFuID, nSetID)
    local list = Storage.SkillAutoCustomize[szKey]
    if not list then
        list = {}
        Storage.SkillAutoCustomize[szKey] = list
    end

    list[nIndex] = nSkillID
    CustomData.Dirty(CustomDataType.Role)
end

function AutoBattle.ClearCustomizeSkill(nIndex, nKungFuID, nSetID)
    if nIndex < 1 or nIndex > AutoBattle.nMaxCustomizeNum then
        return LOG.ERROR("SaveCustomizeSkill error")
    end
    local szKey = AutoBattle._GetKey(nKungFuID, nSetID)
    local list = Storage.SkillAutoCustomize[szKey]
    if list then
        list[nIndex] = nil
        CustomData.Dirty(CustomDataType.Role)
    end
end

function AutoBattle.GetCustomizeSkillList(nKungFuID, nSetID)
    nKungFuID = nKungFuID or g_pClientPlayer.GetActualKungfuMountID()
    nSetID = nSetID or g_pClientPlayer.GetTalentCurrentSet(g_pClientPlayer.dwForceID, nKungFuID)

    local szKey = AutoBattle._GetKey(nKungFuID, nSetID)
    local list = Storage.SkillAutoCustomize[szKey] or {}
    return clone(list)
end

function AutoBattle.IsAutoStopChannelSkill()
    return GameSettingData.GetNewValue(UISettingKey.AutoStopChannelSkill)
end

function AutoBattle._GetKey(nKungFuID, nSetID)
    return nKungFuID .. "_" .. nSetID
end

function AutoBattle.OnReload()

end