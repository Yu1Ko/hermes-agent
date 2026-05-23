-- ---------------------------------------------------------------------------------
-- Name: UIMainCitySkill
-- Desc: 主界面技能面板
-- Prefab: WidgetSkillPanel
-- ---------------------------------------------------------------------------------

---@class UIWidgetSkillPanel
local UIWidgetSkillPanel = class("UIWidgetSkillPanel")

local DYNAMIC_TO_UI_SLOT = {
    1, 2, 3, 4, 5, 6, 7, 10, 11, 12
}

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

local QUICK_USE_TIP_STATE = {
    DYNAMICSTATE = 1,
    ITEMUSESTATE = 2,
    IDENTITYSTATE = 3
}

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIWidgetSkillPanel:_LuaBindList()
    self.WidgetSkillAuto = self.WidgetSkillAuto --- 武学助手组件

    -- moba
    self.WidgetMobaShop = self.WidgetMobaShop --- moba推荐购买组件
    self.BtnMobaShop = self.BtnMobaShop --- 打开moba商店
    self.LabelMobaShopMoney = self.LabelMobaShopMoney --- moba星露数目
    self.WidgetMobaEquipItem = self.WidgetMobaEquipItem --- 推荐购买装备组件
end

function UIWidgetSkillPanel:OnEnter(bCustom, skillCancelFromParent)
    if self.bInit then
        return
    end

    if bCustom then
        self:UpdateCustomSkillInfo()
    else
        --assert(widgetSkillCancel)
        self.bInit = true
        self.widgetSkillCancel = skillCancelFromParent or self.WidgetSkillCancel
        self:RegEvent()
        self:BindUIEvent()
        self:InitSkillSlots()
        self:UpdateUIState()
        -- self:SwitchDynamicSkills(QTEMgr.IsInDynamicSkillState())

        self.bHasFuYao = false

        Timer.AddFrameCycle(self, 2, function()
            self:OnUpdate()
        end)

        self:UpdateBarState()

        UIHelper.SetTexture(self.ImgFuYaoIcon, "Resource/icon/skill/JiangHu/skill_jianghu04.png")
        self:UpdateAutoBattleState()

        self:UpdateDynamicSkillState()

        self:UpdateMobaMoney()
    end


end

function UIWidgetSkillPanel:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIWidgetSkillPanel:RegEvent()
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

    Event.Reg(self, "SKILL_MOUNT_KUNG_FU", function()
        self:UpdateBarState()
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
        self:UpdateDynamicSkillState()
    end)

    --Event.Reg(self, "PLAYER_STATE_UPDATE", function(arg0)
    --    if self.bShowSkill then
    --        UIHelper.SetVisible(self.BtnSkillHorse, g_pClientPlayer.bOnHorse)
    --    end
    --end)

    Event.Reg(self, EventType.OnQuickUseSuccess, function()
        self:TryCloseQuickUseTip()
    end)

    Event.Reg(self, "ON_NPC_ASSISTED_RESULT_CODE", function(nResultCode, nArg0, nArg1, nArg2)
        if nResultCode == NPC_ASSISTED_RESULT_CODE.ASSISTED_POWER_INFO_CHANGE
                or nResultCode == NPC_ASSISTED_RESULT_CODE.MORPH_BEGIN
                or nResultCode == NPC_ASSISTED_RESULT_CODE.SWITCH_MORPH_SUCCESS
        then
            self:UpdateMorphNpcPower()
        end
    end)

    Event.Reg(self, "ON_START_SHAPE_SHIFT", function()
        self:UpdateBarState()
    end)

    Event.Reg(self, "ON_END_SHAPE_SHIFT", function()
        self:UpdateBarState()
    end)

    -- Event.Reg(self, "ON_CHANGE_IDENTITY_SKILL", function(bEnter)
    --     self.bEnterIdentitySkills = bEnter
    --     self:SwitchIdentitySkills(bEnter)
    -- end)

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

    Event.Reg(self, EventType.OnEnterTreasureBattleFieldDynamic, function()
        SprintData.SetViewState(false, true)
        self:DelayUpdateUIState()
    end)

    Event.Reg(self, EventType.OnUpdateTreasureBattleFieldSkill, function(bSinge, nSlotID)
        if not bSinge then
            self:DelayUpdateUIState()
        end
    end)

    Event.Reg(self, EventType.OnLeaveBahuangDynamic, function()
        self:UpdateUIState()
    end)

    Event.Reg(self, EventType.OnLeaveTreasureBattleFieldDynamic, function()
        self:DelayUpdateUIState()
    end)

    Event.Reg(self, EventType.OnFuncSlotChanged, function(tbAction)
        local player = g_pClientPlayer
        if not player then
            return
        end
        UIHelper.SetVisible(self.BoxNon1, player.nMoveState ~= MOVE_STATE.ON_SIT)
    end)

    Event.Reg(self, "ON_QUICKUSEITEM_STATE_CHANGE", function(isGray, bEquipment)
        UIHelper.SetVisible(self.WidgetUseHint, not isGray and not bEquipment)
        UIHelper.SetVisible(self.Eff_UI_TiShiQuan, not isGray and bEquipment)
    end)

    Event.Reg(self, "Moba_OnShowAffordableEquip", function(dwID1, nCost1, dwID2, nCost2)
        self:Moba_OnShowAffordableEquip(dwID1, nCost1, dwID2, nCost2)
    end)

    Event.Reg(self, "UPDATE_ACTIVITYAWARD", function(nOldMoney)
        self:UpdateMobaMoney()
    end)

    Event.Reg(self, "ON_SKILL_REPLACE", function(nOldSkillID, nNewSkillID)
        Timer.AddFrame(self, 1, function()
            if g_pClientPlayer then
                local nCurrentKungFuID = g_pClientPlayer.GetActualKungfuMountID()
                local nSkillLevel = g_pClientPlayer.GetSkillLevel(nNewSkillID) -- 在切换配置时，奇穴会先遗忘奇穴，然后再重新学习。这会导致奇穴替换技能的ON_SKILL_REPLACE事件被发送多次，并且无法正确获取与事件关联的nSet，因此此处根据技能学习状态进行初筛
                --print("OnSkillReplace", nOldSkillID, nNewSkillID,nSkillLevel)
                if nSkillLevel > 0 and nCurrentKungFuID then
                    local nCurrentSetID = g_pClientPlayer.GetTalentCurrentSet(g_pClientPlayer.dwForceID, nCurrentKungFuID)
                    for nSlotIndex = 1, 5 do
                        local nSkillID = SkillData.GetSlotSkillID(nSlotIndex, nCurrentKungFuID, nCurrentSetID)
                        if nSkillID == nOldSkillID then
                            SkillData.ChangeSkill({ [nSlotIndex] = nNewSkillID }, nCurrentKungFuID, nCurrentSetID)
                            break
                        end
                    end
                end
            end
        end)
    end)

    Event.Reg(self, EventType.EnterSelfieMode, function(bEnter)
        --进入幻境云图，自动解锁镜头
        if bEnter and TargetMgr.IsAttention() then
            self:OnClickAttention(false)
        end
    end)
end

function UIWidgetSkillPanel:InitSkillSlots()
    self.skillSlot1Script = UIHelper.AddPrefab(PREFAB_ID.WidgetBigSkill, self.SkillSlot1, SKILL_SLOT_ENUM.SkillSlot1) ---@type UIWidgetNormalSkill
    self.skillSlot2Script = UIHelper.AddPrefab(PREFAB_ID.WidgetNormalSkill, self.SkillSlot2, SKILL_SLOT_ENUM.SkillSlot2) ---@type UIWidgetNormalSkill
    self.skillSlot3Script = UIHelper.AddPrefab(PREFAB_ID.WidgetNormalSkill, self.SkillSlot3, SKILL_SLOT_ENUM.SkillSlot3) ---@type UIWidgetNormalSkill
    self.skillSlot4Script = UIHelper.AddPrefab(PREFAB_ID.WidgetNormalSkill, self.SkillSlot4, SKILL_SLOT_ENUM.SkillSlot4) ---@type UIWidgetNormalSkill
    self.skillSlot5Script = UIHelper.AddPrefab(PREFAB_ID.WidgetNormalSkill, self.SkillSlot5, SKILL_SLOT_ENUM.SkillSlot5) ---@type UIWidgetNormalSkill
    self.skillSlot6Script = UIHelper.AddPrefab(PREFAB_ID.WidgetNormalSkill, self.SkillSlot6, SKILL_SLOT_ENUM.SkillSlot6) ---@type UIWidgetNormalSkill
    self.skillSlot7Script = UIHelper.AddPrefab(PREFAB_ID.WidgetNormalSkill, self.SkillSlot7, SKILL_SLOT_ENUM.SkillSlot7) ---@type UIWidgetNormalSkill
    self.skillSlot8Script = UIHelper.AddPrefab(PREFAB_ID.WidgetNormalSkill, self.SkillSlot8, SKILL_SLOT_ENUM.SkillSlot8) ---@type UIWidgetNormalSkill
    self.skillSlot9Script = UIHelper.AddPrefab(PREFAB_ID.WidgetSmallSkill, self.SkillSlot9, SKILL_SLOT_ENUM.SkillSlot9) ---@type UIWidgetNormalSkill
    self.skillSlot10Script = UIHelper.AddPrefab(PREFAB_ID.WidgetNormalSkill, self.WidgetSkillRoll, SKILL_SLOT_ENUM.SkillSlot10) ---@type UIWidgetNormalSkill
    self.skillSlot11Script = UIHelper.AddPrefab(PREFAB_ID.WidgetNormalSkill, self.SkillSlot11, SKILL_SLOT_ENUM.SkillSlot11) ---@type UIWidgetNormalSkill
    self.skillSlot12Script = UIHelper.AddPrefab(PREFAB_ID.WidgetNormalSkill, self.SkillSlot12, SKILL_SLOT_ENUM.SkillSlot12) ---@type UIWidgetNormalSkill

    self.skillSlot6Script:SetSkillVisible(true)
    self.skillSlot7Script:SetSkillVisible(true)
    self.skillSlot8Script:SetSkillVisible(true)
    self.skillSlot9Script:SetSkillVisible(true)
    self.skillSlot10Script:SetSkillVisible(true)
    self.skillSlot11Script:SetSkillVisible(true)
    self.skillSlot12Script:SetSkillVisible(true)

    local compLuaBind = self.widgetSkillCancel:getComponent("LuaBind")
    self.cancelScript = compLuaBind and compLuaBind:getScriptObject()

    compLuaBind = self.SkillDirection:getComponent("LuaBind")
    self.directionScript = compLuaBind and compLuaBind:getScriptObject()
    self.directionScript:SetSkillCancelCtrl(self.cancelScript)

    self.skillQuickUseScript = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickUseItem, self.SkillSlotQuickUse, 8) -- 道具槽

    local lst = { self.skillSlot1Script, self.skillSlot2Script, self.skillSlot3Script,
                  self.skillSlot4Script, self.skillSlot5Script, self.skillSlot6Script,
                  self.skillSlot7Script, self.skillSlot8Script, self.skillSlot9Script,
                  self.skillSlot10Script, self.skillQuickUseScript,
                  self.skillSlot11Script, self.skillSlot12Script}

    for _, script in ipairs(lst) do
        UIHelper.SetLocalZOrder(script._rootNode, -1) --使按钮显示在按键映射标签下
        script:SetSkillCancelCtrl(self.cancelScript)
        script:SetSkillDirectionCtrl(self.directionScript)
    end

    UIHelper.SetCombinedBatchEnabled(UIHelper.GetParent(self.SkillSlot1), true)
end

function UIWidgetSkillPanel:BindUIEvent()
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

    UIHelper.BindUIEvent(self.BtnQuickUse, EventType.OnClick, function()
        self:SwitchQuickUseTip()
    end)

    UIHelper.BindUIEvent(self.BtnQuickUseBg, EventType.OnTouchBegan, function()
        self:TryCloseQuickUseTip()
    end)

    UIHelper.BindUIEvent(self.BtnSkillAuto, EventType.OnClick, function()
        self:OnClickSkillAuto()
    end)

    UIHelper.BindUIEvent(self.BtnMobaShop, EventType.OnClick, function()
        ---@type UIEquipSetView
        UIMgr.Open(VIEW_ID.PanelEquipSetInterior, true)
    end)
end

function UIWidgetSkillPanel:OnUpdate()
    if not g_pClientPlayer then
        return
    end

    self:UpdateChangeBtnState()
    self:UpdateExtraUIState()
    self:UpdateRageBar()

    if self.SkillProgressMingJiaoScript and UIHelper.GetVisible(self.SkillProgressMingJiaoParent) then
        self.SkillProgressMingJiaoScript:OnUpdate()
    end

    if self.SkillProgressYaoZongScript and UIHelper.GetVisible(self.SkillProgressYaoZongParent) then
        self.SkillProgressYaoZongScript:OnUpdate()
    end

    if self.SkillProgressPartnerNormalScript and UIHelper.GetVisible(self.SkillProgressPartnerNormalParent) then
        self.SkillProgressPartnerNormalScript:OnUpdate()
    end

    if self.SkillProgressPartnerDouScript and UIHelper.GetVisible(self.SkillProgressPartnerDouParent) then
        self.SkillProgressPartnerDouScript:OnUpdate()
    end

    if self.SkillProgressVehicleScript and UIHelper.GetVisible(self.SkillProgressVehicleParent) then
        self.SkillProgressVehicleScript:OnUpdate()
    end
end

function UIWidgetSkillPanel:UnRegEvent()
    Event.UnRegAll(self)
end

function UIWidgetSkillPanel:UpdateAutoBattleState()
    local bInAutoBattle = AutoBattle.IsInAutoBattle()
    UIHelper.SetVisible(self.WidgetAutoBattleEnable, bInAutoBattle)
    UIHelper.SetVisible(self.WidgetAutoBattleDisable, not bInAutoBattle)
end

function UIWidgetSkillPanel:UpdateBarState()
    local player = g_pClientPlayer
    local bInVehicle = self:IsPlayerInVehicle()
    local bDouble = self:IsShowDoubleRageBar()
    local bYaoZong = self:IsPlayerYaoZong()
    local bNormalBar = self:IsShowNormalRageBar() and not bInVehicle
    local bInDynamic = not QTEMgr.CanCastSkill()
    local bPartner = player and player.dwMorphID > 0

    local bShowVehicle = bInVehicle and not bInDynamic
    local bShowDoubleRageBar = bDouble and not bInVehicle and not bInDynamic
    local bShowYaoZong = bYaoZong and not bInVehicle and not bInDynamic

    if bShowDoubleRageBar and self.SkillProgressMingJiaoScript == nil then
        self.SkillProgressMingJiaoScript = UIHelper.AddPrefab(PREFAB_ID.SkillProgress_MingJiao, self.SkillProgressMingJiaoParent)
    end

    if bShowYaoZong and self.SkillProgressYaoZongScript == nil then
        self.SkillProgressYaoZongScript = UIHelper.AddPrefab(PREFAB_ID.SkillProgress_YaoZong, self.SkillProgressYaoZongParent)
    end

    if bShowVehicle and self.SkillProgressVehicleScript == nil then
        self.SkillProgressVehicleScript = UIHelper.AddPrefab(PREFAB_ID.SkillProgress_Vehicle, self.SkillProgressVehicleParent)
    end

    UIHelper.SetVisible(self.SkillProgressMingJiaoParent, bShowDoubleRageBar)
    UIHelper.SetVisible(self.SkillProgressYaoZongParent, bShowYaoZong)
    UIHelper.SetVisible(self.SkillProgressVehicleParent, bShowVehicle)
    UIHelper.SetVisible(self.SkillProgress, bNormalBar)
    --UIHelper.SetVisible(self.ImgSkillProgressLine, bNormalBar and FORCE_TYPE.DAO_ZONG == g_pClientPlayer.dwForceID) -- 刀总显示刻度条

    local _, nMaxBuff = PartnerData.GetBuffCount()
    local bShowPartnerDou = bPartner and nMaxBuff and (nMaxBuff % 5 == 0 or nMaxBuff == 3) --在 nMaxBuff 为 10 5 3 时展示资源豆
    local bShowPartnerNormal = bPartner and not bShowPartnerDou and nMaxBuff > 0 --不展示资源豆且nMaxBuff大于0时展示资源条

    if bShowPartnerNormal and self.SkillProgressPartnerNormalScript == nil then
        self.SkillProgressPartnerNormalScript = UIHelper.AddPrefab(PREFAB_ID.SkillProgressPartnerNormal, self.SkillProgressPartnerNormalParent)
    end

    if bShowPartnerDou and self.SkillProgressPartnerDouScript == nil then
        self.SkillProgressPartnerDouScript = UIHelper.AddPrefab(PREFAB_ID.SkillProgressPartnerDou, self.SkillProgressPartnerDouParent)
    end

    UIHelper.SetVisible(self.SkillProgressPartnerNormalParent, bShowPartnerNormal)
    UIHelper.SetVisible(self.SkillProgressPartnerDouParent, bShowPartnerDou)

    self:OnUpdate()
end

function UIWidgetSkillPanel:UpdateUIState(bSprint)
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
    -- local nDynamicCount = QTEMgr.GetDynamicSkillCount()
    self.bShowSkill = bShowSkill
    local bCanCastSkill = QTEMgr.CanCastSkill() or QTEMgr.IsHorseDynamic()
    local bShowSkill = self.bShowSkill and bCanCastSkill and JiangHuData.bHideSkill--在战斗状态且动态技能可以和普通技能共存
    local bInBahuangDynamic = BahuangData.IsInBahuangDynamic()----是否在八荒动态技能
    local bInTreasureBattle = TreasureBattleFieldSkillData.IsInDynamic()----是否在吃鸡动态技能
    self.skillSlot1Script:UpdateSkillNotInDynamic()
    self.skillSlot2Script:UpdateSkillNotInDynamic()
    self.skillSlot3Script:UpdateSkillNotInDynamic()
    self.skillSlot4Script:UpdateSkillNotInDynamic()
    self.skillSlot5Script:UpdateSkillNotInDynamic()
    self.skillSlot6Script:UpdateSkillNotInDynamic()
    self.skillSlot11Script:UpdateSkillNotInDynamic()
    self.skillSlot12Script:UpdateSkillNotInDynamic()

    self.skillSlot1Script:SetSkillVisible(bShowSkill or (not bCanCastSkill and (table.contain_value(self.tbDynamicSlot, 1)) and JiangHuData.bHideSkill) or bInBahuangDynamic or bInTreasureBattle)
    self.skillSlot2Script:SetSkillVisible(bShowSkill or (not bCanCastSkill and (table.contain_value(self.tbDynamicSlot, 2)) and JiangHuData.bHideSkill) or bInBahuangDynamic or bInTreasureBattle)
    self.skillSlot3Script:SetSkillVisible(bShowSkill or (not bCanCastSkill and (table.contain_value(self.tbDynamicSlot, 3)) and JiangHuData.bHideSkill) or bInBahuangDynamic or bInTreasureBattle)
    self.skillSlot4Script:SetSkillVisible(bShowSkill or (not bCanCastSkill and (table.contain_value(self.tbDynamicSlot, 4)) and JiangHuData.bHideSkill) or bInBahuangDynamic or bInTreasureBattle)
    self.skillSlot5Script:SetSkillVisible(bShowSkill or (not bCanCastSkill and (table.contain_value(self.tbDynamicSlot, 5)) and JiangHuData.bHideSkill) or bInBahuangDynamic or bInTreasureBattle)
    self.skillSlot6Script:SetSkillVisible(bShowSkill or (not bCanCastSkill and (table.contain_value(self.tbDynamicSlot, 6)) and JiangHuData.bHideSkill) or bInTreasureBattle)
    self.skillSlot11Script:SetSkillVisible(bShowSkill or (not bCanCastSkill and (table.contain_value(self.tbDynamicSlot, 9)) and JiangHuData.bHideSkill) or bInTreasureBattle)
    self.skillSlot12Script:SetSkillVisible(bShowSkill or (not bCanCastSkill and (table.contain_value(self.tbDynamicSlot, 10)) and JiangHuData.bHideSkill) or bInTreasureBattle)

    -- 使用挂件动作的技能 不切亮剑
    -- 在马上时 不切亮剑动作
    if (not APIHelper.IsUsePendantAction()) and (not QTEMgr.IsHorseDynamic()) and
            (not g_pClientPlayer or g_pClientPlayer.dwEmotionActionID == 0) then
        if bShowSkill then
            player.SetSheath(0)
        else
            player.SetSheath(1)
        end

        if GetPlayerWeaponType(player) == WEAPON_DETAIL.HEPTA_CHORD then
            rlcmd("force update sheath " .. player.dwID .. " 0")
        end
    end

    -- 开/关自动索敌
    -- TargetMgr.EnableMainSearch(true)
    -- UIHelper.SetVisible(self.BtnTargetSelect, bShowSkill)
    --UIHelper.SetVisible(self.ImgTargetSelectLock, false)
    --UIHelper.SetVisible(self.BtnTargetLock, false)

    UIHelper.SetVisible(self.WidgetAutoBattleEnable, AutoBattle.bAuto)
    UIHelper.SetVisible(self.WidgetAutoBattleDisable, not AutoBattle.bAuto)
end

function UIWidgetSkillPanel:UpdateRageBar()
    local player = g_pClientPlayer
    if player and UIHelper.GetVisible(self.SkillProgress) then
        local nMaxLen = 46.2
        if player.nMaxRage > 0 then
            UIHelper.SetProgressBarPercent(self.ImgSkillProgress, nMaxLen * player.nCurrentRage / player.nMaxRage)
        elseif player.nMaxEnergy > 0 then
            UIHelper.SetProgressBarPercent(self.ImgSkillProgress, nMaxLen * player.nCurrentEnergy / player.nMaxEnergy)
        end
    end
end

function UIWidgetSkillPanel:UpdateMorphNpcPower()
    local player = g_pClientPlayer
    if player.IsInMorph() then
        local tNpcMorphList = PartnerData.GetMorphList()
        for _, dwAssistedID in ipairs(tNpcMorphList) do
            if dwAssistedID == player.dwMorphID then
                local dwCurPower, dwMaxPower = player.GetAssistedPower(dwAssistedID)
                if dwCurPower and dwMaxPower then
                    UIHelper.SetProgressBarPercent(self.ProgressBarRage, 100 * dwCurPower / dwMaxPower)
                end
            end
        end
    end
end

--跳跃/闪避/切换技能面板按钮显示状态
function UIWidgetSkillPanel:UpdateExtraUIState()
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
    local bCanUserExitDynamicSkill = self:CanUserExitDynamicSkill()

    local bChangeVisible = bNormalState and (not bRideTogetherOrHold or bCanUserExitDynamicSkill) and (bCanCastSkill or QTEMgr.IsHorseDynamic() or bCanUserExitDynamicSkill) and --一般状态且可切换
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
    self.bWidgetQuickUseVisible = (bNormalState or bAutoFly) and player.nLevel >= 101
    UIHelper.SetVisible(self.WidgetSkillAuto, bNormalState and player.nLevel >= 120 and not bInMoba and bCanCastSkill)

    UIHelper.SetVisible(self.WidgetMobaShop, bInMoba)

    if self.skillQuickUseScript then
        self.skillQuickUseScript:UpdateNodeVisible()
    end

    local function _getDynamicSlot(nIndex)
        for nSlot, nUISlot in ipairs(DYNAMIC_TO_UI_SLOT) do
            if nUISlot == nIndex then return nSlot end
        end
        return -1
    end

    local function _skillSlotVisible(nIndex)
        if bInTreasureBFDynamic then
            return TreasureBattleFieldSkillData.GetSkillInfoByIndex(nIndex) ~= nil
        end
        return bSprintVisible or (not bCanCastSkill and table.contain_value(self.tbDynamicSlot, _getDynamicSlot(nIndex)) and JiangHuData.bHideSkill) or
                (nIndex == 10 and bInBahuangDynamic)
    end

    local fnCanShow = function ()
        if QTEMgr.CanCastSkill() then
            return true
        else
            return QTEMgr.CanJump()
        end
    end

    local tMovementSkillSlots = { self.skillSlot7Script, self.skillSlot8Script, self.skillSlot9Script, self.skillSlot10Script }
    for i = 1, 4 do
        local nSlotIndex = i + 6
        local script = tMovementSkillSlots[i]
        if script:IsJumpSkill() then
            script:SetSkillVisible(bJumpVisible and fnCanShow())
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

function UIWidgetSkillPanel:OnClickTargetSelect()
    TargetMgr.SearchNextTarget()
end

function UIWidgetSkillPanel:SwitchQuickUseTip()
    if self.QuickUseScript and UIHelper.GetVisible(self.QuickUseScript._rootNode) then
        self:TryCloseQuickUseTip()
    else
        self:OpenQuickUseTip()
    end
end

function UIWidgetSkillPanel:OpenQuickUseTip()
    UIHelper.SetVisible(self.BtnQuickUseBg, true)
    self.QuickUseScript = self.QuickUseScript or UIHelper.AddPrefab(PREFAB_ID.WidgetQuickUsedTip, self.WidgetQuickTips)
    self.QuickUseScript:TrySetVisible(true)
end

function UIWidgetSkillPanel:TryCloseQuickUseTip()
    if self.QuickUseScript and self.QuickUseScript:TrySetVisible(false) then
        UIHelper.SetVisible(self.BtnQuickUseBg, false)
    end
end

function UIWidgetSkillPanel:UpdateDynamicSkillState()
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

function UIWidgetSkillPanel:CanUserExitDynamicSkill()
    return QTEMgr.CanUserChange() and not QTEMgr.CanCastSkill()
end

function UIWidgetSkillPanel:UpdateJumpSlot(bEnterDynamicSkills)
    if bEnterDynamicSkills and QTEMgr.CanJump() then
        local nJumpSlotID = SkillData.GetJumpSlot()
        local nSkillID = UIBattleSkillSlot.GetShowUI_Ver2(8)
        if nJumpSlotID and nJumpSlotID ~= 8 then
            self.skillSlot8Script:OnSwitchSkill(nSkillID, UI_SKILL_JUMP_ID)
            self[string.format("skillSlot%sScript", nJumpSlotID)]:OnSwitchSkill(UI_SKILL_JUMP_ID, nSkillID)
            self.nJumpSlotID = nJumpSlotID
        end
        self.skillSlot8Script:SetLockUpdateSkill(true)
    end

    if not bEnterDynamicSkills then
        self.skillSlot8Script:SetLockUpdateSkill(false)
        self.skillSlot8Script:CheckSkill()
        if self.nJumpSlotID then
            self[string.format("skillSlot%sScript", self.nJumpSlotID)]:CheckSkill()
            self.nJumpSlotID = nil
        end
    end
end

function UIWidgetSkillPanel:SwitchNormalDynamicSKill(bEnterDynamicSkills, nGroupID)
    self:UpdateJumpSlot(bEnterDynamicSkills)
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

        if not self.bIsInNormalDynamicSkillState then
            Event.Dispatch(EventType.FIRST_ENTER_NORMAL_DYNAMIC)
        end
        self.bIsInNormalDynamicSkillState = true
    else

        self.bIsInNormalDynamicSkillState = false
    end
    self:ExitDynamicSkill(1, #DYNAMIC_TO_UI_SLOT)

    self:DelayUpdateUIState()
    Event.Dispatch(EventType.OnShortcutInteractionChange)
end

function UIWidgetSkillPanel:DelayUpdateUIState()
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

function UIWidgetSkillPanel:GetDynamicScriptView(nSlotIndex)

    table.insert(self.tbDynamicSlot, nSlotIndex)
    local scriptView = nil
    local nSlotID = DYNAMIC_TO_UI_SLOT[nSlotIndex]
    if nSlotID then
        scriptView = self[string.format("skillSlot%dScript", nSlotID)]
    end

    return scriptView
end

function UIWidgetSkillPanel:ExitDynamicSkill(nStartSlot, nEndSlot)
    for nSlotIndex = nEndSlot, nStartSlot, -1 do

        local scriptView = self[string.format("skillSlot%dScript", DYNAMIC_TO_UI_SLOT[nSlotIndex])]
        local bNotExit = table.contain_value(self.tbDynamicSlot, nSlotIndex)

        if not bNotExit and scriptView then
            scriptView:SwitchDynamicSkills(false)
        end
    end
end

function UIWidgetSkillPanel:IsShowDoubleRageBar()
    return (g_pClientPlayer and (g_pClientPlayer.dwSchoolID == SCHOOL_TYPE.MING_JIAO or g_pClientPlayer.dwSchoolID == SCHOOL_TYPE.DAO_ZONG or g_pClientPlayer.dwSchoolID == SCHOOL_TYPE.DUAN_SHI))
end

function UIWidgetSkillPanel:IsShowNormalRageBar()
    if g_pClientPlayer and g_pClientPlayer.dwSchoolID == SCHOOL_TYPE.CHUN_YANG then
        return false -- 纯阳强制不显示怒气槽
    end
    local bSpecialBar = self:IsShowDoubleRageBar() or self:IsPlayerYaoZong()
    return not bSpecialBar and g_pClientPlayer and (g_pClientPlayer.nMaxRage > 0 or g_pClientPlayer.nMaxEnergy > 0)
end

function UIWidgetSkillPanel:IsPlayerYaoZong()
    return (g_pClientPlayer and g_pClientPlayer.dwSchoolID == SCHOOL_TYPE.YAO_ZONG)
end

function UIWidgetSkillPanel:IsPlayerInVehicle()
    return (g_pClientPlayer and g_pClientPlayer.dwShapeShiftID > 0)
end

local nQiXiuSwordBuff = 70012

function UIWidgetSkillPanel:SwitchBattleState(bForce)
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

--- 七秀关闭剑舞特殊按钮逻辑
function UIWidgetSkillPanel:UpdateChangeBtnState()
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

function UIWidgetSkillPanel:OnClickSkillSwitch(bForce)
    if self.nChangeBtnState == tChangeBtnState.QiXiu then
        self:PerformSkill(false)
    else
        self:SwitchBattleState(bForce)
    end
end

function UIWidgetSkillPanel:OnClickSkillAuto()
    local bInAutoBattle = AutoBattle.IsInAutoBattle()
    if not bInAutoBattle then
        AutoBattle.Start()
    else
        AutoBattle.Stop()
    end
    self:UpdateAutoBattleState()
end

function UIWidgetSkillPanel:OnClickAttention(bManual)
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

function UIWidgetSkillPanel:UpdateTargetLockButtonState()
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

-- 在两种操作盘状态相互切换时，开放一个可由策划配置的调用技能的接口
function UIWidgetSkillPanel:PerformSkill(bFight)
    local nCurrentKungFuID = g_pClientPlayer.GetActualKungfuMountID()
    for _, tInfo in ipairs(UIPerformSkillOnSwitchFightStateTab) do
        if nCurrentKungFuID == tInfo.nKungFuID and g_pClientPlayer.dwForceID == tInfo.dwForceID then
            if bFight and tInfo.nInBattleSkillID and tInfo.nInBattleSkillLevel then
                if not g_pClientPlayer.IsHaveBuff(nQiXiuSwordBuff, 0) then
                    CastSkill(tInfo.nInBattleSkillID, tInfo.nInBattleSkillLevel)
                end
            end

            if not bFight and tInfo.nOutBattleSkillID and tInfo.nOutBattleSkillLevel then
                CastSkill(tInfo.nOutBattleSkillID, tInfo.nOutBattleSkillLevel)
            end
        end
    end
end

function UIWidgetSkillPanel:SwitchIdentitySkills(bEnter)
    local szImage = bEnter and "UIAtlas2_MainCity_MainCitySkill1_icon_qinggong_toptop" or self.bEnterCanCastDynamicSKill and "UIAtlas2_MainCity_MainCitySkill1_icon_qinggong_toptop" or "UIAtlas2_MainCity_MainCitySkill1_img_skill_Bag"
    UIHelper.SetSpriteFrame(self.ImgQuickUse1, szImage)
    if bEnter then
        self:OpenQuickUseTip()
        self.QuickUseScript:SwitchState(QUICK_USE_TIP_STATE.IDENTITYSTATE)
        self.QuickUseScript:StartAutoCloseTimer()
    else
        self:TryCloseQuickUseTip()
    end
end

function UIWidgetSkillPanel:GetSkillCanCelScript()
    return self.cancelScript
end

function UIWidgetSkillPanel:GetSKillDirectionScript()
    return self.directionScript
end

function UIWidgetSkillPanel:Moba_OnShowAffordableEquip(dwID1, nCost1, dwID2, nCost2)
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

function UIWidgetSkillPanel:UpdateMobaMoney()
    if not g_pClientPlayer then
        return
    end
    if not BattleFieldData.IsInMobaBattleFieldMap() then
        return
    end

    UIHelper.SetString(self.LabelMobaShopMoney, g_pClientPlayer.nActivityAward)
end

function UIWidgetSkillPanel:UpdatePrepareState(nMode, bStart)
    self:UpdateCustomNodeState(bStart and CUSTOM_BTNSTATE.ENTER or CUSTOM_BTNSTATE.COMMON)
    self.nMode = nMode
end

function UIWidgetSkillPanel:UpdateCustomState()
    self:UpdateCustomNodeState(CUSTOM_BTNSTATE.EDIT)

end

function UIWidgetSkillPanel:UpdateCustomNodeState(nState)
    local szFrame = nState == CUSTOM_BTNSTATE.CONFLICT and "UIAtlas2_MainCity_MainCity1_maincitykuang3" or "UIAtlas2_MainCity_MainCity1_maincitykuang4"
    UIHelper.SetSpriteFrame(self.ImgSelectZone, szFrame)
    UIHelper.SetVisible(self.ImgSelectZone, nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.EDIT)
    UIHelper.SetVisible(self.BtnSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER or nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.OTHER)
    UIHelper.SetVisible(self.ImgSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER)
    self.nState = nState
end

function UIWidgetSkillPanel:UpdateCustomSkillInfo()
    UIHelper.BindUIEvent(self.BtnSelectZoneLight, EventType.OnClick, function()
        --进入黑框,maincity加载新的
        Event.Dispatch("ON_ENTER_SINGLENODE_CUSTOM", CUSTOM_RANGE.RIGHT, CUSTOM_TYPE.SKILL, self.nMode)
    end)

    local BtnSelectZone = UIHelper.GetChildByName(UIHelper.GetParent(self._rootNode), "BtnSelectZone")
    local nWidth, nHeight = UIHelper.GetContentSize(self.ImgSelectZone)
    UIHelper.SetContentSize(BtnSelectZone, nWidth, nHeight)

    self.skillSlot1Script = UIHelper.AddPrefab(PREFAB_ID.WidgetBigSkill, self.SkillSlot1, SKILL_SLOT_ENUM.SkillSlot1) ---@type UIWidgetNormalSkill
    self.skillSlot2Script = UIHelper.AddPrefab(PREFAB_ID.WidgetNormalSkill, self.SkillSlot2, SKILL_SLOT_ENUM.SkillSlot2) ---@type UIWidgetNormalSkill
    self.skillSlot3Script = UIHelper.AddPrefab(PREFAB_ID.WidgetNormalSkill, self.SkillSlot3, SKILL_SLOT_ENUM.SkillSlot3) ---@type UIWidgetNormalSkill
    self.skillSlot4Script = UIHelper.AddPrefab(PREFAB_ID.WidgetNormalSkill, self.SkillSlot4, SKILL_SLOT_ENUM.SkillSlot4) ---@type UIWidgetNormalSkill
    self.skillSlot5Script = UIHelper.AddPrefab(PREFAB_ID.WidgetNormalSkill, self.SkillSlot5, SKILL_SLOT_ENUM.SkillSlot5) ---@type UIWidgetNormalSkill
    self.skillSlot6Script = UIHelper.AddPrefab(PREFAB_ID.WidgetNormalSkill, self.SkillSlot6, SKILL_SLOT_ENUM.SkillSlot6) ---@type UIWidgetNormalSkill
    self.skillSlot7Script = UIHelper.AddPrefab(PREFAB_ID.WidgetNormalSkill, self.SkillSlot7, SKILL_SLOT_ENUM.SkillSlot7) ---@type UIWidgetNormalSkill
    self.skillSlot8Script = UIHelper.AddPrefab(PREFAB_ID.WidgetNormalSkill, self.SkillSlot8, SKILL_SLOT_ENUM.SkillSlot8) ---@type UIWidgetNormalSkill
    self.skillSlot9Script = UIHelper.AddPrefab(PREFAB_ID.WidgetSmallSkill, self.SkillSlot9, SKILL_SLOT_ENUM.SkillSlot9) ---@type UIWidgetNormalSkill
    self.skillSlot10Script = UIHelper.AddPrefab(PREFAB_ID.WidgetNormalSkill, self.WidgetSkillRoll, SKILL_SLOT_ENUM.SkillSlot10) ---@type UIWidgetNormalSkill
    self.skillSlot11Script = UIHelper.AddPrefab(PREFAB_ID.WidgetNormalSkill, self.SkillSlot11, SKILL_SLOT_ENUM.SkillSlot11) ---@type UIWidgetNormalSkill
    self.skillSlot12Script = UIHelper.AddPrefab(PREFAB_ID.WidgetNormalSkill, self.SkillSlot12, SKILL_SLOT_ENUM.SkillSlot12) ---@type UIWidgetNormalSkill
    self.skillQuickUseScript = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickUseItem, self.SkillSlotQuickUse, 8) -- 道具槽

    self.skillSlot1Script:SetSkillVisible(true)
    self.skillSlot2Script:SetSkillVisible(true)
    self.skillSlot3Script:SetSkillVisible(true)
    self.skillSlot4Script:SetSkillVisible(true)
    self.skillSlot5Script:SetSkillVisible(true)
    self.skillSlot6Script:SetSkillVisible(true)
    self.skillSlot7Script:SetSkillVisible(true)
    self.skillSlot8Script:SetSkillVisible(true)
    self.skillSlot9Script:SetSkillVisible(true)
    self.skillSlot10Script:SetSkillVisible(true)
    self.skillSlot11Script:SetSkillVisible(true)
    self.skillSlot12Script:SetSkillVisible(true)
    UIHelper.SetVisible(self.SkillSlotQuickMark, false)

    local lst = { self.skillSlot1Script, self.skillSlot2Script, self.skillSlot3Script,
                  self.skillSlot4Script, self.skillSlot5Script, self.skillSlot6Script,
                  self.skillSlot7Script, self.skillSlot8Script, self.skillSlot9Script,
                  self.skillSlot10Script }

    for _, script in ipairs(lst) do
        UIHelper.SetLocalZOrder(script._rootNode, -1) --使按钮显示在按键映射标签下
    end

    Timer.AddFrame(self, 1, function()
        SprintData.SetViewState(false, true)
    end)
end

return UIWidgetSkillPanel