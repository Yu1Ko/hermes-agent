-- ---------------------------------------------------------------------------------
-- Name: WidgetSkillPanelDX
-- Desc: 主界面技能面板
-- Prefab: WidgetSkillPanelDX
-- ---------------------------------------------------------------------------------

SkillPanelDXHelper = {}

function SkillPanelDXHelper.AddSkillCombine()
    return UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCombine, SkillPanelDXHelper.SkillCombineParent)
end

---@class UIWidgetSkillPanelDX
local UIWidgetSkillPanelDX = class("UIWidgetSkillPanelDX")

--注意保证DYNAMIC_TO_UI_SLOT_FIRST和DYNAMIC_TO_UI_SLOT_SECOND数量一致
local DYNAMIC_TO_UI_SLOT_FIRST = {
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 23, 24, 25, 26, 27, 28, 29
}
local DYNAMIC_TO_UI_SLOT_SECOND = {
    12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29
}
local UI_SLOT_TO_DYNAMIC_FIRST = {}
local UI_SLOT_TO_DYNAMIC_SECOND = {}
for nSlot, nUISlot in ipairs(DYNAMIC_TO_UI_SLOT_FIRST) do
    UI_SLOT_TO_DYNAMIC_FIRST[nUISlot] = nSlot
end
for nSlot, nUISlot in ipairs(DYNAMIC_TO_UI_SLOT_SECOND) do
    UI_SLOT_TO_DYNAMIC_SECOND[nUISlot] = nSlot
end

local tChangeBtnState = {
    Sprint = 1,
    Fight = 2,
    QiXiu = 3,
    ExitDynamicSkill = 4,
}

local tChangeBtnImgPath = {
    [tChangeBtnState.Sprint] = "UIAtlas2_MainCity_MainCitySkill1_img_zhejiemian_jn01_01.png",
    [tChangeBtnState.Fight] = "UIAtlas2_MainCity_MainCitySkill1_img_skill_Switch.png",
    [tChangeBtnState.QiXiu] = "UIAtlas2_MainCity_MainCitySkill1_img_skill_shanzi.png",
    [tChangeBtnState.ExitDynamicSkill] = "UIAtlas2_MainCity_MainCitySkill1_img_skill_Esc.png",
}

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIWidgetSkillPanelDX:_LuaBindList()
    self.WidgetSkillAuto = self.WidgetSkillAuto --- 武学助手组件

    -- moba
    self.WidgetMobaShop = self.WidgetMobaShop --- moba推荐购买组件
    self.BtnMobaShop = self.BtnMobaShop --- 打开moba商店
    self.LabelMobaShopMoney = self.LabelMobaShopMoney --- moba星露数目
    self.WidgetMobaEquipItem = self.WidgetMobaEquipItem --- 推荐购买装备组件
end

function UIWidgetSkillPanelDX:OnEnter(bCustom, skillCancelFromParent)
    if self.bInit then
        return
    end

    if bCustom then
        self:UpdateCustomSkillInfo()
    else
        self.bInit = true
        self.bWidgetQuickUseVisible = true
        self.bShowFirstPage = true

        self.widgetSkillCancel = skillCancelFromParent or self.WidgetSkillCancel
        self:RegEvent()
        self:BindUIEvent()
        self:InitSkillSlots()
        self:UpdateBackgroundLine()
        self:UpdateUIState()
        self:UpdatePageSwitchState()

        Timer.AddFrameCycle(self, 2, function()
            self:OnUpdate()
        end)

        --self:UpdateBarState()
        self:UpdateAutoBattleState()
        self:UpdateDynamicSkillState()
        self:UpdateMobaMoney()
    end
end

function UIWidgetSkillPanelDX:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIWidgetSkillPanelDX:RegEvent()
    --进入/退出轻功
    Event.Reg(self, EventType.OnSprintFightStateChanged, function(bSprint)
        if g_pClientPlayer.bSprintFlag and not bSprint then
            self.bExitSprintWhenFight = true -- 轻功状态时不立刻切换至战斗状态，等待OnPlayerSprintStateChanged事件
            return
        elseif bSprint then
            self.bExitSprintWhenFight = false --切回轻功面板时清除标记
        end
        --LOG.WARN("OnSprintFightStateChanged")
        self:UpdateUIState(bSprint)
    end)

    Event.Reg(self, EventType.OnPlayerSprintStateChanged, function(bSprint)
        if not g_pClientPlayer.bSprintFlag and not bSprint and self.bExitSprintWhenFight then
            self.bExitSprintWhenFight = false
            self:UpdateUIState(bSprint)
        end
    end)

    -- 搜索目标改变
    Event.Reg(self, EventType.OnSearchTargetChanged, function()
        self:UpdateTargetLockButtonState()
    end)

    Event.Reg(self, "SKILL_UPDATE", function(arg0, arg1)
        self:UpdateBarState()
    end)

    Event.Reg(self, "MYSTIQUE_ACTIVE_UPDATE", function(arg0, arg1)
        self:UpdateBarState()
    end)

    Event.Reg(self, "ON_QUICKUSEITEM_STATE_CHANGE", function(isGray, bEquipment)
        UIHelper.SetVisible(self.WidgetUseHint, not isGray and not bEquipment)
        UIHelper.SetVisible(self.Eff_UI_TiShiQuan, not isGray and bEquipment)
    end)

    Event.Reg(self, EventType.OnShortcutTargetSelect, function()
        self:OnClickTargetSelect()
    end)

    Event.Reg(self, EventType.OnShortcutSwitchSkill, function()
        self:OnClickSkillSwitch(true)
    end)

    Event.Reg(self, EventType.OnShortcutSkillAuto, function()
        self:OnClickSkillAuto()
    end)

    Event.Reg(self, EventType.OnShortcutAttention, function()
        self:OnClickAttention(true)
    end)

    Event.Reg(self, EventType.ON_CHANGE_DYNAMIC_SKILL_GROUP, function(bEnter, nGroupID)
        -- self:SwitchDynamicSkills(bEnter, nGroupID)
        print(bEnter, nGroupID)
        self:UpdateDynamicSkillState()
    end)

    Event.Reg(self, "ON_START_SHAPE_SHIFT", function()
        self:UpdateBarState()
    end)

    Event.Reg(self, "ON_END_SHAPE_SHIFT", function()
        self:UpdateBarState()
    end)

    Event.Reg(self, "ON_HIDEORSHOW_MAINCITYSKILL", function(bIsShow)
        JiangHuData.bHideSkill = bIsShow
        self:UpdateUIState()
        self:UpdateExtraUIState()
    end)

    Event.Reg(self, EventType.OnAutoBattleStateChanged, function()
        self:UpdateAutoBattleState()
    end)

    Event.Reg(self, EventType.OnEnterBahuangDynamic, function()
        SprintData.SetViewState(false, true)--进入八荒切换为技能面板
        self:UpdateUIState()
    end)

    Event.Reg(self, EventType.OnLeaveBahuangDynamic, function()
        self:UpdateUIState()
    end)

    Event.Reg(self, EventType.OnFuncSlotChanged, function(tbAction)
        local player = g_pClientPlayer
        if not player then
            return
        end
        UIHelper.SetVisible(self.BoxNon1, player.nMoveState ~= MOVE_STATE.ON_SIT)
    end)

    Event.Reg(self, "Moba_OnShowAffordableEquip", function(dwID1, nCost1, dwID2, nCost2)
        self:Moba_OnShowAffordableEquip(dwID1, nCost1, dwID2, nCost2)
    end)

    Event.Reg(self, "UPDATE_ACTIVITYAWARD", function(nOldMoney)
        self:UpdateMobaMoney()
    end)

    Event.Reg(self, EventType.EnterSelfieMode, function(bEnter)
        --进入幻境云图，自动解锁镜头
        if bEnter and TargetMgr.IsAttention() then
            self:OnClickAttention(false)
        end
    end)

    Event.Reg(self, EventType.OnShortcutSwitchPageSkill, function()
        self.bShowFirstPage = not self.bShowFirstPage
        self:UpdatePageSwitchState()
    end)

    Event.Reg(self, "SKILL_MOUNT_KUNG_FU", function(dwKungFuID)
        self:UpdateSpecialSkill()
    end)

    Event.Reg(self, EventType.OnDXSkillSlotChanged, function()
        self:UpdateBackgroundLine()
    end)

    Event.Reg(self, EventType.OnDxSkillBarIndexChange, function()
        Timer.AddFrame(self, 1, function()
            self:UpdateBackgroundLine()
        end)
    end)
end

function UIWidgetSkillPanelDX:InitSkillSlots()
    local slotParents = {}
    table.insert_tab(slotParents, self.skillBar1SlotParents)
    table.insert_tab(slotParents, self.skillBar2SlotParents)
    table.insert_tab(slotParents, self.remainingSlotParents)
    self.tSlotScriptList = {}
    for nSlotIndex = 1, #slotParents do
        local parent = slotParents[nSlotIndex]
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetNormalSkill, parent, nSlotIndex) ---@type UIWidgetNormalSkill
        table.insert(self.tSlotScriptList, script)

        if nSlotIndex == 1 or nSlotIndex == 12 then
            UIHelper.SetScale(script._rootNode, 124 / 94, 124 / 94) -- 特殊放大右下角主要技能槽位
        end

        if nSlotIndex == 26 or nSlotIndex == 27 or nSlotIndex == 28 or nSlotIndex == 29 then
            script:HideSkillBg()
            UIHelper.SetScale(script.MaskSkillIcon, 0.8, 0.8) -- 缩小右下角轻功槽位
            UIHelper.SetScale(script.imgSkillCd, 0.8, 0.8) -- 缩小右下角轻功槽位
        end
    end

    self.cancelScript = UIHelper.GetBindScript(self.widgetSkillCancel)
    self.directionScript = UIHelper.GetBindScript(self.SkillDirection)
    self.directionScript:SetSkillCancelCtrl(self.cancelScript)
    self.skillQuickUseScript = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickUseItem, self.SkillSlotQuickUse, 34) -- 道具槽

    SkillPanelDXHelper.SkillCombineParent = self.SkillCombineParent
    SkillPanelDXHelper.SkillCancelScript = self.cancelScript
    SkillPanelDXHelper.SkillDirectionScript = self.directionScript

    local lst = { self.skillQuickUseScript }
    table.insert_tab(lst, self.tSlotScriptList)

    for _, script in ipairs(lst) do
        local parent = UIHelper.GetParent(script._rootNode)
        local keyboardWidget = UIHelper.FindChildByName(parent, "WidgetKeyBoardKey")
        if keyboardWidget then
            UIHelper.SetLocalZOrder(keyboardWidget, 10) --使按钮显示在按键映射标签下
        end
        
        script:SetSkillCancelCtrl(self.cancelScript)
        script:SetSkillDirectionCtrl(self.directionScript)
    end

    UIHelper.SetCombinedBatchEnabled(self.WidgetSkill, true)
    self:UpdateSpecialSkill()
end

function UIWidgetSkillPanelDX:BindUIEvent()
    UIHelper.SetButtonClickSound(self.BtnTargetSelect, "")
    UIHelper.SetButtonClickSound(self.BtnChange, "")

    -- 搜索目标
    UIHelper.BindUIEvent(self.BtnTargetSelect, EventType.OnClick, function()
        self:OnClickTargetSelect()
    end)

    -- 注视目标
    UIHelper.BindUIEvent(self.BtnTargetLock, EventType.OnClick, function()
        self:OnClickAttention(true)
    end)

    UIHelper.BindUIEvent(self.BtnChange, EventType.OnClick, function()
        self:OnClickSkillSwitch()
    end)

    UIHelper.BindUIEvent(self.BtnSwitchPage, EventType.OnClick, function()
        self.bShowFirstPage = not self.bShowFirstPage
        self:UpdatePageSwitchState()
    end)

    UIHelper.BindUIEvent(self.BtnSkillAuto, EventType.OnClick, function()
        self:OnClickSkillAuto()
    end)

    UIHelper.BindUIEvent(self.BtnMobaShop, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelEquipSetInterior, true)  ---@type UIEquipSetView
    end)
end

function UIWidgetSkillPanelDX:OnUpdate()
    if not g_pClientPlayer then
        return
    end

    self:UpdateChangeBtnState()
    self:UpdateExtraUIState()
    --self:UpdateRageBar()
    --
    --if self.SkillProgressMingJiaoScript and UIHelper.GetVisible(self.SkillProgressMingJiaoParent) then
    --    self.SkillProgressMingJiaoScript:OnUpdate()
    --end
    --
    --if self.SkillProgressYaoZongScript and UIHelper.GetVisible(self.SkillProgressYaoZongParent) then
    --    self.SkillProgressYaoZongScript:OnUpdate()
    --end
    --
    --if self.SkillProgressPartnerNormalScript and UIHelper.GetVisible(self.SkillProgressPartnerNormalParent) then
    --    self.SkillProgressPartnerNormalScript:OnUpdate()
    --end
    --
    --if self.SkillProgressPartnerDouScript and UIHelper.GetVisible(self.SkillProgressPartnerDouParent) then
    --    self.SkillProgressPartnerDouScript:OnUpdate()
    --end
    --
    --if self.SkillProgressVehicleScript and UIHelper.GetVisible(self.SkillProgressVehicleParent) then
    --    self.SkillProgressVehicleScript:OnUpdate()
    --end
end

function UIWidgetSkillPanelDX:UnRegEvent()
    Event.UnRegAll(self)
end

function UIWidgetSkillPanelDX:UpdateUIState(bSprint)
    local player = GetClientPlayer()
    if not player then
        return
    end

    if bSprint == nil then
        bSprint = SprintData.GetViewState()
    end

    local bShowSkill = not bSprint
    if QTEMgr.IsInDynamicSkillStateBySkills() then
        bShowSkill = true
    end

    -- 使用挂件动作的技能 不播七秀剑舞
    if bShowSkill ~= self.bShowSkill and bShowSkill and not APIHelper.IsUsePendantAction() then
        local bAutoQiXiu = GameSettingData.GetNewValue(UISettingKey.QiXiuAutoSwordDance)
        if (not bShowSkill) or (g_pClientPlayer and g_pClientPlayer.dwForceID ~= FORCE_TYPE.QI_XIU or bAutoQiXiu) then
            self:PerformSkill(bShowSkill)
        end
    end

    --战斗显示技能相关按钮
    self.bShowSkill = bShowSkill
    local bCanCastSkill = QTEMgr.CanCastSkill() or QTEMgr.IsHorseDynamic()
    local bShowSkill = self.bShowSkill and bCanCastSkill and JiangHuData.bHideSkill--在战斗状态且动态技能可以和普通技能共存
    local bInBahuangDynamic = BahuangData.IsInBahuangDynamic()----是否在八荒动态技能

    local function _getDynamicSlot(nIndex)
        return self:UISlotToDynamicSlot(nIndex)
    end
    for nSlotIndex, script in ipairs(self.tSlotScriptList) do
        if not table.contain_value(SkillData.tDXSprintSlots, nSlotIndex) then
            script:UpdateSkillNotInDynamic()
            local bVisible = bShowSkill or (not bCanCastSkill and (table.contain_value(self.tbDynamicSlot, _getDynamicSlot(nSlotIndex))) and JiangHuData.bHideSkill)
            if (nSlotIndex >= 1 and nSlotIndex <= 5) or nSlotIndex == 10 then
                bVisible = bVisible or bInBahuangDynamic -- 八荒槽位显示逻辑
            end
            script:SetSkillVisible(bVisible)
        end
    end

    -- 使用挂件动作的技能 不切亮剑
    -- 在马上时 不切亮剑动作
    if (not APIHelper.IsUsePendantAction()) and (not QTEMgr.IsHorseDynamic()) then
        if bShowSkill then
            player.SetSheath(0)
        else
            player.SetSheath(1)
        end

        if GetPlayerWeaponType(player) == WEAPON_DETAIL.HEPTA_CHORD then
            rlcmd("force update sheath " .. player.dwID .. " 0")
        end
    end

    UIHelper.SetVisible(self.WidgetSpecialSkillParent, not bSprint)
    UIHelper.SetVisible(self.SliderParent, not bSprint)
    UIHelper.SetVisible(self.BtnSwitchPage, not bSprint)
    UIHelper.SetVisible(self.WidgetAutoBattleEnable, AutoBattle.bAuto)
    UIHelper.SetVisible(self.WidgetAutoBattleDisable, not AutoBattle.bAuto)

    self:UpdateBackgroundLine()
end

--跳跃/闪避/切换技能面板按钮显示状态
function UIWidgetSkillPanelDX:UpdateExtraUIState()
    local player = GetClientPlayer()
    if not player then
        return
    end

    local bSit = player.nMoveState == MOVE_STATE.ON_SIT
    local bSprint = SprintData.GetSprintState() -- and SprintData.GetExpectSprint()
    local bOnHorse = player.bOnHorse or player.bHoldHorse or player.nFollowType == FOLLOW_TYPE.RIDE or player.nFollowType == FOLLOW_TYPE.HOLDHORSE
    local bAutoFly = player.nMoveState == MOVE_STATE.ON_AUTO_FLY or player.nMoveState == MOVE_STATE.ON_START_AUTO_FLY
    local bSpecialState = SprintData.GetSpecialState() ~= nil
    local bCanCastSkill = QTEMgr.CanCastSkill()
    local bInVehicle = self:IsPlayerInVehicle()

    local bInBahuangDynamic = BahuangData.IsInBahuangDynamic() --是否在八荒动态技能
    local bInTreasureBFDynamic = TreasureBattleFieldSkillData.IsInDynamic()
    local bNormalState = not bSit and not bSprint and not bAutoFly and not bSpecialState and JiangHuData.bHideSkill and not bInBahuangDynamic
    local bRideTogetherOrHold = player.nFollowType == FOLLOW_TYPE.RIDE or player.nFollowType == FOLLOW_TYPE.HOLDHORSE or player.bHoldHorse

    local bChangeVisible = bNormalState and not bRideTogetherOrHold and (bCanCastSkill or QTEMgr.IsHorseDynamic() or self:CanUserExitDynamicSkill()) and --一般状态且可切换
            (not SprintData.GetHasFightBtn() or self.nChangeBtnState ~= tChangeBtnState.Sprint) --不存在攻击按钮或切换按钮处于可切换状态

    local bJumpVisible = (bNormalState and (not bRideTogetherOrHold or (player.nFollowType == FOLLOW_TYPE.RIDE and player.IsFollowController())) and not bInVehicle and QTEMgr.CanJump()) or bInBahuangDynamic or bInTreasureBFDynamic
    local bSprintVisible = bJumpVisible and not bOnHorse and bCanCastSkill or bInTreasureBFDynamic
    local bFuYaoVisible = bJumpVisible and bCanCastSkill or bInTreasureBFDynamic

    local bInMoba = BattleFieldData.IsInMobaBattleFieldMap()

    -- 2025.12.3 补充需求 动态技能不能跳的时候不显示跳跃按钮（QTEMgr.CanJump()判不了的情况）by策划chenpengyu
    if QTEMgr.IsInDynamicSkillState() and player.nMaxJumpCount <= 0 then
        bJumpVisible = false
    end

    UIHelper.SetVisible(self.WidgetChange, bChangeVisible)
    UIHelper.SetVisible(self.WidgetTargetSelect, bNormalState)
    UIHelper.SetVisible(self.WidgetSkillAuto, bNormalState and player.nLevel >= 120 and not bInMoba and bCanCastSkill)
    UIHelper.SetVisible(self.WidgetMobaShop, bInMoba)

    self.bWidgetQuickUseVisible = (bNormalState or bAutoFly) and player.nLevel >= 101
    if self.skillQuickUseScript then
        self.skillQuickUseScript:UpdateNodeVisible()
    end

    local function _getDynamicSlot(nIndex)
        return self:UISlotToDynamicSlot(nIndex)
    end

    local function _skillSlotVisible(nIndex)
        if bInTreasureBFDynamic then
            return TreasureBattleFieldSkillData.GetSkillInfoByIndex(nIndex) ~= nil
        end
        return bSprintVisible or (not bCanCastSkill and table.contain_value(self.tbDynamicSlot, _getDynamicSlot(nIndex)) and JiangHuData.bHideSkill) or
                (nIndex == 10 and bInBahuangDynamic)
    end

    for _, nSprintSlotId in ipairs(SkillData.tDXSprintSlots) do
        local nSlotIndex = nSprintSlotId
        local script = self.tSlotScriptList[nSprintSlotId]
        if script:IsJumpSkill() then
            script:SetSkillVisible(bJumpVisible)
        elseif script:IsFuYaoSkill() then
            script:SetSkillVisible(bFuYaoVisible)
        else
            script:SetSkillVisible(_skillSlotVisible(nSlotIndex))
        end
    end

    if not bChangeVisible and bCanCastSkill and not player.bFightState then
        SprintData.SetViewState(true)
    end
end

function UIWidgetSkillPanelDX:OnClickTargetSelect()
    TargetMgr.SearchNextTarget()
end

function UIWidgetSkillPanelDX:UpdateAutoBattleState()
    local bInAutoBattle = AutoBattle.IsInAutoBattle()
    UIHelper.SetVisible(self.WidgetAutoBattleEnable, bInAutoBattle)
    UIHelper.SetVisible(self.WidgetAutoBattleDisable, not bInAutoBattle)
end

-----------------------------动态技能相关-----------------------------------------

function UIWidgetSkillPanelDX:UpdateDynamicSkillState()
    local bInDynamic = QTEMgr.IsInDynamicSkillState()
    local bExit = false
    if bInDynamic then
        local nGroupID = QTEMgr.GetCurGroupID()
        local bCanCastSkill = QTEMgr.CanCastSkill()
        local bHorseDynamic = QTEMgr.IsHorseDynamic(nGroupID)
        if not bCanCastSkill and not bHorseDynamic then
            self:SwitchNormalDynamicSKill(true, nGroupID)
        else
            bExit = true
        end
    else
        bExit = true
    end

    if bExit and self.bIsInNormalDynamicSkillState then
        self:SwitchNormalDynamicSKill(false)
    end
end

function UIWidgetSkillPanelDX:CanUserExitDynamicSkill()
    return QTEMgr.CanUserChange() and not QTEMgr.CanCastSkill()
end

function UIWidgetSkillPanelDX:UpdateJumpSlot(bEnterDynamicSkills)
    local script = self:GetDynamicScriptView(27)
    if bEnterDynamicSkills and QTEMgr.CanJump() then
        script:OnSwitchSkill(UI_SKILL_JUMP_ID)
        script:SetLockUpdateSkill(true)
    end

    if not bEnterDynamicSkills then
        script:SetLockUpdateSkill(false)
        script:UpdateSkill()
    end
end

function UIWidgetSkillPanelDX:UpdateNormalDynamicSkill()
    if self.bIsInNormalDynamicSkillState then
        self:SwitchNormalDynamicSKill(false)
    end
    local nGroupID = QTEMgr.GetCurGroupID()
    local bCanCastSkill = QTEMgr.CanCastSkill()
    local bHorseDynamic = QTEMgr.IsHorseDynamic(nGroupID)
    if nGroupID ~= 0 and not bCanCastSkill and not bHorseDynamic then
        self:SwitchNormalDynamicSKill(true, nGroupID)
    end
end

function UIWidgetSkillPanelDX:SwitchNormalDynamicSKill(bEnterDynamicSkills, nGroupID)
    self.tbDynamicSlot = {}--现存动态技能占用的槽位(1~10)

    if bEnterDynamicSkills then
        local tbSlot = DYNAMIC_SKILL_SLOT[nGroupID]
        local nSkillCount = QTEMgr.GetDynamicSkillCount()
        for nIndex = 1, nSkillCount do
            local nSlot = tbSlot and tbSlot[nIndex] or nIndex
            local scriptView = self:GetDynamicScriptView(nSlot)
            local tbSkillInfo = QTEMgr.GetDynamicSkillData(nIndex)
            if scriptView and scriptView.SwitchDynamicSkills then
                scriptView:SwitchDynamicSkills(bEnterDynamicSkills, tbSkillInfo)
            end
        end
        self.bDyFirstPage = self.bShowFirstPage

        if not self.bIsInNormalDynamicSkillState then
            Event.Dispatch(EventType.FIRST_ENTER_NORMAL_DYNAMIC)
        end
        self.bIsInNormalDynamicSkillState = true
    else

        self.bIsInNormalDynamicSkillState = false
    end
    self:ExitDynamicSkill(1, #DYNAMIC_TO_UI_SLOT_FIRST)

    self:DelayUpdateUIState()
    Event.Dispatch(EventType.OnShortcutInteractionChange)
end

function UIWidgetSkillPanelDX:DelayUpdateUIState()
    if self.nUpdateUIStateTimer then
        Timer.DelTimer(self, self.nUpdateUIStateTimer)
        self.nUpdateUIStateTimer = nil
    end
    self.nUpdateUIStateTimer = Timer.AddFrameCycle(self, 1, function()
        local player = GetClientPlayer()
        if not player then
            return
        end
        self:UpdateUIState()
        self:UpdateBarState()
        Timer.DelTimer(self, self.nUpdateUIStateTimer)
        self.nUpdateUIStateTimer = nil
    end)
end

function UIWidgetSkillPanelDX:UISlotToDynamicSlot(nUISlot)
    if self.bShowFirstPage then
        return UI_SLOT_TO_DYNAMIC_FIRST[nUISlot]
    end
    return UI_SLOT_TO_DYNAMIC_SECOND[nUISlot]
end

function UIWidgetSkillPanelDX:DynamicSlotToUISlot(nSlotIndex, bFirstPage)
    if bFirstPage == nil then
        bFirstPage = self.bShowFirstPage
    end
    if bFirstPage then
        return DYNAMIC_TO_UI_SLOT_FIRST[nSlotIndex]
    end
    return DYNAMIC_TO_UI_SLOT_SECOND[nSlotIndex]
end

function UIWidgetSkillPanelDX:GetDynamicScriptView(nSlotIndex)
    if not table.contain_value(self.tbDynamicSlot, nSlotIndex) then
        table.insert(self.tbDynamicSlot, nSlotIndex)
    end

    local scriptView = nil
    local nSlotID = self:DynamicSlotToUISlot(nSlotIndex)
    if nSlotID then
        scriptView = self.tSlotScriptList[nSlotID]
    end

    return scriptView
end

function UIWidgetSkillPanelDX:ExitDynamicSkill(nStartSlot, nEndSlot)
    for nSlotIndex = nEndSlot, nStartSlot, -1 do
        local scriptView = self.tSlotScriptList[self:DynamicSlotToUISlot(nSlotIndex, self.bDyFirstPage)]
        local bNotExit = table.contain_value(self.tbDynamicSlot, nSlotIndex)

        if not bNotExit and scriptView then
            scriptView:SwitchDynamicSkills(false)
        end
    end
end

function UIWidgetSkillPanelDX:SwitchBattleState(bForce)
    --防止按钮被隐藏后才松开按钮
    if not UIHelper.GetVisible(self.WidgetChange) and not bForce then
        return
    end
    if self:CanUserExitDynamicSkill() then
        --显示在屏幕右下角且可以主动退出的动态技能才点击切换键退出
        if self:IsPlayerInVehicle() then
            UIHelper.ShowConfirm("是否离开载具？", function()
                QTEMgr.ExitDynamicSkillState(false)
            end)
        else
            if QTEMgr.IsInDynamicSkillStateBySkills() then
                QTEMgr.OnSwitchDynamicSkillStateBySkills()
            else
                QTEMgr.ExitDynamicSkillState()
            end
        end
    else
        SprintData.ToggleViewState()
    end
end

-----------------------------特殊操作----------------------------------------

function UIWidgetSkillPanelDX:UpdateBarState()

end

function UIWidgetSkillPanelDX:UpdatePageSwitchState()
    UIHelper.SetVisible(self.SkillBar1, self.bShowFirstPage)
    UIHelper.SetVisible(self.SkillBar2, not self.bShowFirstPage)
    UIHelper.SetOpacity(self.ImgPage1, self.bShowFirstPage and 255 or 70)
    UIHelper.SetOpacity(self.ImgPage2, not self.bShowFirstPage and 255 or 70)
    self:UpdateNormalDynamicSkill()
    self:UpdateBackgroundLine()
end

function UIWidgetSkillPanelDX:UpdateBackgroundLine()
    local bShowLine1 = false
    local bShowLine2 = false
    if self.bShowSkill then
        local nOffset = self.bShowFirstPage and 0 or 11
        local nBarIndex = SkillData.GetCurrentDxSkillBarIndex()

        for i = 2, 5 do
            local tSlotInfo = SkillData.GetDxSlotData(i + nOffset, nBarIndex)
            if not SkillData.IsDXSlotEmpty(tSlotInfo) then
                bShowLine1 = true
                break
            end
        end

        for i = 6, 11 do
            local tSlotInfo = SkillData.GetDxSlotData(i + nOffset, nBarIndex)
            if not SkillData.IsDXSlotEmpty(tSlotInfo) then
                bShowLine2 = true
                break
            end
        end
    else
        bShowLine1 = true
        bShowLine2 = false
    end

    UIHelper.SetActiveAndCache(self, self.ImgBgLine1, bShowLine1)
    UIHelper.SetActiveAndCache(self, self.ImgBgLine2, bShowLine2)
end

function UIWidgetSkillPanelDX:IsPlayerInVehicle()
    return (g_pClientPlayer and g_pClientPlayer.dwShapeShiftID > 0)
end

--- 七秀关闭剑舞特殊按钮逻辑
local nQiXiuSwordBuff = 409
function UIWidgetSkillPanelDX:UpdateChangeBtnState()
    if g_pClientPlayer then
        local nChangeBtnState = self.bShowSkill and tChangeBtnState.Fight or tChangeBtnState.Sprint
        local bShouldShowQiXiuBtn = g_pClientPlayer.IsHaveBuff(nQiXiuSwordBuff, 0) and not g_pClientPlayer.bFightState and not self.bShowSkill
        local bCanExitDynamicSkill = QTEMgr.CanUserChange()
        local bCanCastSkill = QTEMgr.CanCastSkill()
        if bShouldShowQiXiuBtn then
            nChangeBtnState = tChangeBtnState.QiXiu
        end

        if not bCanCastSkill and bCanExitDynamicSkill then
            nChangeBtnState = tChangeBtnState.ExitDynamicSkill
        end

        if self.nChangeBtnState ~= nChangeBtnState then
            self.nChangeBtnState = nChangeBtnState
            local szImgPath = tChangeBtnImgPath[nChangeBtnState]
            UIHelper.SetSpriteFrame(self.ImgChange, szImgPath)
        end
    end
end

function UIWidgetSkillPanelDX:OnClickSkillSwitch(bForce)
    if self.nChangeBtnState == tChangeBtnState.QiXiu then
        self:PerformSkill(false)
    else
        self:SwitchBattleState(bForce)
    end
end

function UIWidgetSkillPanelDX:OnClickSkillAuto()
    local bInAutoBattle = AutoBattle.IsInAutoBattle()
    if not bInAutoBattle then
        AutoBattle.Start()
    else
        AutoBattle.Stop()
    end
    self:UpdateAutoBattleState()
end

function UIWidgetSkillPanelDX:OnClickAttention(bManual)
    if not UIHelper.GetVisible(self.BtnTargetLock) then
        return
    end

    if PublicQuestData.IsInCampPQ() then
        if bManual then
            TipsHelper.ShowNormalTip("当前区域内无法使用目标锁定")
        end
        return
    end

    TargetMgr.Attention(not TargetMgr.IsAttention())
    UIHelper.SetVisible(self.ImgTargetSelectLock, TargetMgr.IsAttention())
end

function UIWidgetSkillPanelDX:UpdateTargetLockButtonState()
    local bHasTarget = TargetMgr.GetSelect() ~= 0
    local bShowButton = GameSettingData.GetNewValue(UISettingKey.ShowTargetLockButton)
    if bHasTarget and bShowButton then
        UIHelper.SetVisible(self.BtnTargetLock, true)
        UIHelper.SetVisible(self.ImgTargetSelectLock, TargetMgr.IsAttention())
    else
        UIHelper.SetVisible(self.BtnTargetLock, false)
        UIHelper.SetVisible(self.ImgTargetSelectLock, false)
    end
end

function UIWidgetSkillPanelDX:UpdateSpecialSkill()
    UIHelper.RemoveAllChildren(self.WidgetSpecialSkillParent)
    UIHelper.AddPrefab(PREFAB_ID.WidgetSpecialRelevanceSkillGrid, self.WidgetSpecialSkillParent) -- 特殊技能
end

-- 在两种操作盘状态相互切换时，开放一个可由策划配置的调用技能的接口
function UIWidgetSkillPanelDX:PerformSkill(bFight)
    local nCurrentKungFuID = g_pClientPlayer.GetActualKungfuMountID()
    for _, tInfo in ipairs(UIPerformSkillOnSwitchFightStateTab) do
        if nCurrentKungFuID == tInfo.nKungFuID and g_pClientPlayer.dwForceID == tInfo.dwForceID then
            if bFight and tInfo.nInBattleSkillID then
                if not g_pClientPlayer.IsHaveBuff(nQiXiuSwordBuff, 0) then
                    local nSkillLevel = g_pClientPlayer.GetSkillLevel(tInfo.nInBattleSkillID)
                    CastSkill(tInfo.nInBattleSkillID, nSkillLevel)
                end
            end

            if not bFight and tInfo.nOutBattleSkillID then
                local nSkillLevel = g_pClientPlayer.GetSkillLevel(tInfo.nOutBattleSkillID)
                CastSkill(tInfo.nOutBattleSkillID, nSkillLevel)
            end
        end
    end
end

function UIWidgetSkillPanelDX:GetSkillCanCelScript()
    return self.cancelScript
end

function UIWidgetSkillPanelDX:GetSKillDirectionScript()
    return self.directionScript
end

function UIWidgetSkillPanelDX:Moba_OnShowAffordableEquip(dwID1, nCost1, dwID2, nCost2)
    -- 未传参数时，表示没有推荐装备，此时隐藏推荐组件
    local bShow = dwID1 ~= nil
    UIHelper.SetVisible(self.WidgetMobaEquipItem, bShow)
    if not bShow then
        return
    end

    local tInfo = Table_GetMobaShopItemUIInfoByID(dwID1)

    UIHelper.RemoveAllChildren(self.WidgetMobaEquipItem)
    ---@type UIEuipSetItem
    local scriptEuipSetItem = UIHelper.AddPrefab(PREFAB_ID.WidgetEuipSetItem, self.WidgetMobaEquipItem)
    scriptEuipSetItem:OnEnter(tInfo)

    scriptEuipSetItem:UpdatePrice(nCost1)

    scriptEuipSetItem:SetPrePurchase(false)
    scriptEuipSetItem:UpdateSell(false)
    --scriptEuipSetItem:UpdateCanBuy(true)

    UIHelper.SetVisible(scriptEuipSetItem.ImgItemBgBlack, true)
    UIHelper.SetVisible(scriptEuipSetItem.Eff_lingQuJiangLi, true)

    UIHelper.SetTextColor(scriptEuipSetItem.LabelName, cc.c3b(255, 255, 255))

    scriptEuipSetItem.scriptItem:SetToggleSwallowTouches(false)

    UIHelper.BindUIEvent(scriptEuipSetItem.ToggleSelect, EventType.OnClick, function()
        local player = g_pClientPlayer
        if not player or player.bFightState then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_MOBA_CANT_BUY_EQUIP_IN_FIGHT)
            return
        end

        local nEquipPos = tInfo.nEquipmentSub
        RemoteCallToServer("On_Moba_EquipShopBuy", nEquipPos, dwID1)

        UIHelper.SetVisible(self.WidgetMobaEquipItem, false)
    end)
end

function UIWidgetSkillPanelDX:UpdateMobaMoney()
    if not g_pClientPlayer then
        return
    end
    if not BattleFieldData.IsInMobaBattleFieldMap() then
        return
    end

    UIHelper.SetString(self.LabelMobaShopMoney, g_pClientPlayer.nActivityAward)
end
-----------------------自定义相关-----------------------------------

function UIWidgetSkillPanelDX:UpdatePrepareState(nMode, bStart)
    self:UpdateCustomNodeState(bStart and CUSTOM_BTNSTATE.ENTER or CUSTOM_BTNSTATE.COMMON)
    self.nMode = nMode
end

function UIWidgetSkillPanelDX:UpdateCustomState()
    self:UpdateCustomNodeState(CUSTOM_BTNSTATE.EDIT)

end

function UIWidgetSkillPanelDX:UpdateCustomNodeState(nState)
    local szFrame = nState == CUSTOM_BTNSTATE.CONFLICT and "UIAtlas2_MainCity_MainCity1_maincitykuang3" or "UIAtlas2_MainCity_MainCity1_maincitykuang4"
    UIHelper.SetSpriteFrame(self.ImgSelectZone, szFrame)
    UIHelper.SetVisible(self.ImgSelectZone, nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.EDIT)
    UIHelper.SetVisible(self.BtnSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER or nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.OTHER)
    UIHelper.SetVisible(self.ImgSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER)
    self.nState = nState
end

function UIWidgetSkillPanelDX:UpdateCustomSkillInfo()
    UIHelper.BindUIEvent(self.BtnSelectZoneLight, EventType.OnClick, function()
        --进入黑框,maincity加载新的
        Event.Dispatch("ON_ENTER_SINGLENODE_CUSTOM", CUSTOM_RANGE.RIGHT, CUSTOM_TYPE.SKILL, self.nMode)
    end)

    local BtnSelectZone = UIHelper.GetChildByName(UIHelper.GetParent(self._rootNode), "BtnSelectZone")
    local nWidth, nHeight = UIHelper.GetContentSize(self.ImgSelectZone)
    UIHelper.SetContentSize(BtnSelectZone, nWidth, nHeight)

    local slotParents = {}
    table.insert_tab(slotParents, self.skillBar1SlotParents)
    table.insert_tab(slotParents, self.skillBar2SlotParents)
    table.insert_tab(slotParents, self.remainingSlotParents)
    self.tSlotScriptList = {}
    for nSlotIndex = 1, #slotParents do
        local parent = slotParents[nSlotIndex]
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetNormalSkill, parent, nSlotIndex) ---@type UIWidgetNormalSkill
        table.insert(self.tSlotScriptList, script)
    end

    UIHelper.SetVisible(self.SkillBar1, true)
    UIHelper.SetVisible(self.SkillBar2, false)

    self.cancelScript = UIHelper.GetBindScript(self.widgetSkillCancel)
    self.directionScript = UIHelper.GetBindScript(self.SkillDirection)
    self.directionScript:SetSkillCancelCtrl(self.cancelScript)

    local lst = {}
    table.insert_tab(lst, self.tSlotScriptList)

    for nSlotIndex, script in ipairs(lst) do
        UIHelper.SetLocalZOrder(script._rootNode, -1) --使按钮显示在按键映射标签下
        script:SetSkillCancelCtrl(self.cancelScript)
        script:SetSkillDirectionCtrl(self.directionScript)
        script:SetSkillVisible(true)
        script:SetCustomState(true)

        if nSlotIndex == 1 or nSlotIndex == 12 then
            UIHelper.SetScale(script._rootNode, 124 / 94, 124 / 94) -- 特殊放大右下角主要技能槽位
        end
        if nSlotIndex == 26 or nSlotIndex == 27 or nSlotIndex == 28 or nSlotIndex == 29 then
            script:HideSkillBg()
            UIHelper.SetScale(script.MaskSkillIcon, 0.8, 0.8) -- 缩小右下角轻功槽位
            UIHelper.SetScale(script.imgSkillCd, 0.8, 0.8) -- 缩小右下角轻功槽位
        end
    end

    UIHelper.SetCombinedBatchEnabled(self.WidgetSkill, true)

    Timer.AddFrame(self, 1, function()
        SprintData.SetViewState(false, true)
    end)
end

return UIWidgetSkillPanelDX