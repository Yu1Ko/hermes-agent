-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSkillConfigurationCell
-- Date: 2022-11-23 10:01:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIPanelSkillVK
local UIPanelSkillVK = class("UIPanelSkillVK")

SPRINT_ENABLE_LEVEL = 105
SZ_UNLOCKED_BIG_SKILL_BG_PATH = "UIAtlas2_Skill_SkillNew_Skill3.png"

local tSlotIndex = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
local tSprintSlots = { 7, 8, 9, 10 }
local tNotConfigurableSlot = { [UI_SKILL_UNIQUE_SLOT_ID] = true , [UI_SKILL_DOUQI_SLOT_ID] = true}

function UIPanelSkillVK:OnEnter(nKungFuID)
    self:RegEvent()
    self:BindUIEvent()

    if not self.bInit then
        self.bInit = true
        self.tAcupointCellScripts = {}
        self.tSetButtonScripts = {}
        self.tXinFaToggles = {}

        self.nCurrentKungFuID = nKungFuID or g_pClientPlayer.GetActualKungfuMountID()
        self.nCurrentSetID = g_pClientPlayer.GetTalentCurrentSet(g_pClientPlayer.dwForceID, self.nCurrentKungFuID)
        self.skillAutoSettingScript = UIHelper.GetBindScript(self.WidgetSkillAutoSettingAni)

        for i = 1, #self.skillSetWidgets do
            local script = UIHelper.GetBindScript(self.skillSetWidgets[i]) ---@type UIWidgetSkillSetButton
            table.insert(self.tSetButtonScripts, script)
        end

        for i = 1, 4 do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetConfigurationAcupointDX, self.ScrollViewAcupoint, i) ---@type UIWidgetAcupointCell
            table.insert(self.tAcupointCellScripts, script)
        end
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAcupoint)

        self.tSlotScripts = {}
        for i, tParent in ipairs(self.skillSlotParents) do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, tParent)
            if i == 1 then
                UIHelper.SetScale(script._rootNode, 1.33, 1.33)
            elseif i == 9 then
                UIHelper.SetScale(script._rootNode, 0.64, 0.64)
            end
            script:UpdateLabelSize()
            self.tSlotScripts[i] = script
        end

        if g_pClientPlayer and g_pClientPlayer.nLevel >= SKILL_RESTRICTION_LEVEL then
            UIHelper.SetSpriteFrame(self.ImgSkillBg, SZ_UNLOCKED_BIG_SKILL_BG_PATH)  -- 解锁奇穴时触发技背景变更
            UIHelper.SetSpriteFrame(self.ImgSkillBg1, SZ_UNLOCKED_BIG_SKILL_BG_PATH) -- 解锁奇穴时触发技背景变更
        end

        self:InitXinFaInfo()
    end
    
    self:UpdateInfo()
end

function UIPanelSkillVK:OnExit()
    self:UnRegEvent()
end

function UIPanelSkillVK:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnIntroduce, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelIntroduce, self.nCurrentKungFuID, self.nCurrentSetID)
    end)
    
    UIHelper.BindUIEvent(self.BtnEquipSetting, EventType.OnClick, function()
        if g_pClientPlayer and g_pClientPlayer.bFightState then
            return TipsHelper.ShowNormalTip("战斗中无法进行分页绑定")
        end
        UIMgr.Open(VIEW_ID.PanelSkillEquipSettingPop, self.nCurrentKungFuID)
    end)

    UIHelper.BindUIEvent(self.BtnAutoSetting, EventType.OnClick, function()
        if g_pClientPlayer and g_pClientPlayer.bFightState then
            return TipsHelper.ShowNormalTip("战斗中无法进行武学助手配置")
        end
        self.skillAutoSettingScript:Show(self.nCurrentKungFuID, self.nCurrentSetID)
    end)

    UIHelper.BindUIEvent(self.BtnRecommend, EventType.OnClick, function()
        if g_pClientPlayer and g_pClientPlayer.bFightState then
            TipsHelper.ShowNormalTip("战斗中无法进行技能配置")
        else
            UIMgr.Open(VIEW_ID.PanelSkillRecommend, self.nCurrentKungFuID, self.nCurrentSetID)
        end
    end)

    UIHelper.BindUIEvent(self.BtnSkillSetClose, EventType.OnClick, function()
        UIHelper.SetSelected(self.TogSkillConfigurationGroup, false)
    end)

    UIHelper.BindUIEvent(self.BtnSkillConfiguration, EventType.OnClick, function()
        self:GotoConfiguration()
    end)

    UIHelper.BindUIEvent(self.BtnSwitchXinFa, EventType.OnClick, function()
        self:ChangeKungFu()
    end)
end

function UIPanelSkillVK:RegEvent()
    Event.Reg(self, "ON_UPDATE_TALENT", function()
        LOG.WARN("UIPanelSkill UIPanelSkill ON_UPDATE_TALENT")
        local hPlayer = g_pClientPlayer
        Timer.AddFrame(self, 2, function()
            local nNewSkillSet = hPlayer and hPlayer.GetTalentCurrentSet(hPlayer.dwForceID, self.nCurrentKungFuID)
            if hPlayer and nNewSkillSet ~= self.nCurrentSetID then
                self.tSlotToSkillID_Old = clone(self.tSlotToSkillID) -- 在技能配置的切换成功回调里处理相关逻辑
                self.nCurrentSetID = nNewSkillSet
                self:UpdateInfo()

                self:UpdateEquipPreset() -- 依赖 self.nCurrentSetID = nSetID
                self:PlayEffectAfterSetChange()
            else
                self:UpdateInfo()
            end
        end)
    end)

    Event.Reg(self, "ON_SKILL_REPLACE", function(arg0, arg1, arg2)
        --LOG.WARN("UIPanelSkillNew ON_SKILL_REPLACE")
        self:OnSkillReplace(arg0, arg1)
    end)

    Event.Reg(self, "UPDATE_TALENT_SET_SLOT_SKILL", function()
        --print("UPDATE_TALENT_SET_SLOT_SKILL")
        self:UpdateInfo()
    end)

    Event.Reg(self, "MYSTIQUE_ACTIVE_UPDATE", function(dwSkillID)
        self:RefreshRedPoints()
    end)

    Event.Reg(self, "FIGHT_HINT", function(bFight)
        if self.nKungFuScript and bFight then
            self.nKungFuScript:StopProgressBar()
        end
    end)

    Event.Reg(self, "On_Liupai_UnLockFinished", function()
        self:UpdateNonSchoolBtn(true)
    end)
end

function UIPanelSkillVK:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelSkillVK:UpdateInfo()
    self.skillAutoSettingScript:UpdateInvalid(self.nCurrentKungFuID, self.nCurrentSetID) -- 第一次打开界面时显示自定义提示
    self:UpdatePlayerSkillData()
    self:UpdateSkillConfiguration()
    self:UpdateSkillSetToggles()
    self:UpdateBtnConfiguration()
    self:UpdateSetName()
    self:UpdateNonSchoolBtn()
end

--------------------------心法相关--------------------------------

function UIPanelSkillVK:InitXinFaInfo()
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupXinFa)
    UIHelper.RemoveAllChildren(self.LayoutSkillNewLeftXinFa)

    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return
    end
    local dwForceID = hPlayer.dwForceID
    local playerKungFuList = NewSkillPanel_GetKungFuList(false)

    for i = 1, #playerKungFuList do
        local nSkillID = playerKungFuList[i] and playerKungFuList[i][1]
        if nSkillID then
            local t = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillNewLeftXinFa, self.LayoutSkillNewLeftXinFa, nSkillID)
            table.insert(self.tXinFaToggles, t)
        end
    end

    local fnCallback = function(index)
        self.nCurrentKungFuID = playerKungFuList[index][1]
        self.nCurrentSetID = hPlayer.GetTalentCurrentSet(dwForceID, self.nCurrentKungFuID)
        self:UpdateInfo()
    end

    local nFirstSelectedIndex = 0
    for index, script in ipairs(self.tXinFaToggles) do
        local tog = script:GetToggle()
        local bLiup = IsNoneSchoolKungfu(playerKungFuList[index][1])
        if bLiup then
            RedpointMgr.RegisterRedpoint(script.ImgRedPoint, nil, { 1905 })
        end

        UIHelper.ToggleGroupAddToggle(self.ToggleGroupXinFa, tog)
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(toggle, bState)
            if bState then
                fnCallback(index)
                if bLiup then
                    RedpointHelper.PanelSkill_OnClickLiuPaiKungFu()
                end
            end
        end)

        if self.nCurrentKungFuID == playerKungFuList[index][1] then
            nFirstSelectedIndex = index - 1
        end
    end
    UIHelper.SetToggleGroupSelected(self.ToggleGroupXinFa, nFirstSelectedIndex)
    fnCallback(nFirstSelectedIndex + 1)
end

function UIPanelSkillVK:UpdatePlayerSkillData()
    local currentKungFuID = self.nCurrentKungFuID
    local tSkillInfo = TabHelper.GetUISkill(currentKungFuID)

    if tSkillInfo then
        self:UpdateSkillList()
        self:UpdateQiXue()
    end
end

function UIPanelSkillVK:UpdateSkillList()
    local currentKungFuID = self.nCurrentKungFuID
    self.tSlotToSkillID = {}
    self.tEquippedSkillIds = {}
    for i = 1, #tSlotIndex do
        local slotIndex = tSlotIndex[i]
        local nSkillID = SkillData.GetSlotSkillID(slotIndex, currentKungFuID, self.nCurrentSetID)
        self.tSlotToSkillID[slotIndex] = nSkillID
        table.insert(self.tEquippedSkillIds, nSkillID)
    end
end

--------------------------武学配置相关--------------------------------

function UIPanelSkillVK:OnChildPanelClose()
    local nIndex = UIHelper.GetToggleGroupSelectedIndex(self.ToggleGroupSkillConf)
    if nIndex >= 0 then
        local button = self.ToggleGroupSkillConf:getRadioButtonByIndex(nIndex)
        UIHelper.SetSelected(button, false)
    end
end

function UIPanelSkillVK:UpdateSkillConfiguration()
    self:RefreshSkillSlots()
end

function UIPanelSkillVK:RefreshSkillSlots()
    if not g_pClientPlayer then
        return
    end
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupSkillConf)

    for i, script in ipairs(self.tSlotScripts) do
        local slotIndex = tSlotIndex[i]
        local skillID = self:GetShowSkill(slotIndex)
        local nSkillLevel = g_pClientPlayer.GetSkillLevel(skillID)
        local bNotShowSkill = nSkillLevel == 0 and table.contain_value(tSprintSlots, slotIndex) and
                g_pClientPlayer.nLevel < SPRINT_ENABLE_LEVEL

        UIHelper.SetVisible(script.ImgAdd, not tNotConfigurableSlot[slotIndex] and skillID == nil) -- 空槽位 显示+号
        UIHelper.SetVisible(script.ImgSkillIcon, skillID ~= nil)
        if skillID then
            script:UpdateInfo(skillID)
            script:ShowShortcutAndType(slotIndex)
        else
            script:HideLabel()
        end

        self:SetConfigurationToggle(script.TogSkill, skillID, slotIndex)
        UIHelper.SetVisible(script._rootNode, not bNotShowSkill)
    end

    self:RefreshRedPoints()
end

function UIPanelSkillVK:RefreshRedPoints()
    local nPlayerKungFuID = g_pClientPlayer.GetActualKungfuMountID()
    local bNotCurrentKungFu = nPlayerKungFuID ~= self.nCurrentKungFuID

    for i = 1, 5 do
        local script = self.tSlotScripts[i]
        if script then
            local nSkillID = self:GetShowSkill(i)
            if bNotCurrentKungFu or not nSkillID then
                script:SetRedPoint(false)
            else
                local _, bActive = SkillData.GetFinalRecipeList(nSkillID)
                script:SetRedPoint(not bActive)
            end
        end
    end
end

function UIPanelSkillVK:ResetConfiguration()
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupSkillConf)
end

function UIPanelSkillVK:SetConfigurationToggle(tog, nSkillID, nSlotIndex)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupSkillConf, tog)
    UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(toggle, bSelected)
        local fnExit = function()
            Timer.AddFrame(self, 1, function()
                UIHelper.SetSelected(tog, false)
            end)
        end
        if bSelected then
            if not nSkillID then
                if nSlotIndex == UI_SKILL_UNIQUE_SLOT_ID then
                    local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetConfigurationAcupointTip, tog
                    , TipsLayoutDir.LEFT_CENTER, self.nCurrentKungFuID, self.nCurrentSetID)
                    script:BindExitFunc(fnExit)
                else
                    self:GotoConfiguration()
                    fnExit()
                end
            else
                local tips, tipsScriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSkillInfoTips, tog,
                        TipsLayoutDir.LEFT_CENTER,
                        nSkillID, self.nCurrentKungFuID, self.nCurrentSetID)
                tipsScriptView:BindExitFunc(fnExit)
            end
        end
    end)
end

--------------------------奇穴相关--------------------------------

function UIPanelSkillVK:UpdateQiXue()
    local tList = SkillData.GetQixueList(true, self.nCurrentKungFuID, self.nCurrentSetID)

    --初始化奇穴列表内容
    for nIndex, script in ipairs(self.tAcupointCellScripts) do
        if tList[nIndex] then
            local nSelectIndex = tList[nIndex].nSelectIndex
            local dwPointID = tList[nIndex].dwPointID

            local fnClose = function()
                script:UnSelectAll()
            end

            -- 屏蔽斗气奇穴逻辑
            if tList[nIndex].nType ~= SkillData.DouqiQixueType then
                script:SetTitle(tList[nIndex].nType == SkillData.DouqiQixueType and "内劲天赋" or QixueTitleList[nIndex])
                script:UpdateInfo(tList[nIndex], nIndex)
                script:BindClickEvent(function(nSubIndex)
                    local fnChangeQiXue = function()
                        return SkillData.ChangeQiXue(dwPointID, nSubIndex, self.nCurrentKungFuID, self.nCurrentSetID)
                    end

                    local tSkill = tList[nIndex].SkillArray[nSubIndex]
                    local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetAcupointTip,
                            self.WidgetAcupointTipParent, TipsLayoutDir.MIDDLE)
                    script:Init(tSkill, nSelectIndex == nSubIndex, fnChangeQiXue, fnClose, self.tEquippedSkillIds,
                            self.nCurrentKungFuID)
                    if self.nCurrentKungFuID ~= g_pClientPlayer.GetActualKungfuMountID() then
                        script:HideButton()
                    end
                end)
            end
        end
        UIHelper.SetVisible(script._rootNode, tList[nIndex] ~= nil)
    end

    local nPercent = UIHelper.GetScrollPercent(self.ScrollViewAcupoint)
    UIHelper.ScrollViewDoLayout(self.ScrollViewAcupoint)
    UIHelper.ScrollToPercent(self.ScrollViewAcupoint, nPercent)
    if nPercent < 99 then
        UIHelper.ScrollViewSetupArrow(self.ScrollViewAcupoint, self.WidgetArrowParent)
    end
end

--------------------------槽位配置相关--------------------------------

function UIPanelSkillVK:OnSkillReplace()
    Timer.AddFrame(self, 1, function()
        self:ResetConfiguration()
        self:UpdatePlayerSkillData()
        self:UpdateSkillConfiguration()
    end)
end

--------------------------套路配置相关--------------------------------

function UIPanelSkillVK:UpdateSkillSetToggles()
    UIHelper.SetToggleGroupSelected(self.ToggleGroupSkillSet, self.nCurrentSetID)
end

function UIPanelSkillVK:ChangeQixueSet(nSetID)
    local hPlayer = g_pClientPlayer
    local dwForceID = hPlayer.dwForceID
    local bNotCurrentKungFu = g_pClientPlayer.GetActualKungfuMountID() ~= self.nCurrentKungFuID
    local bOnHorse = g_pClientPlayer.bOnHorse
    local bInArena = ArenaData.IsInArena()
    local bCanCastSkill = QTEMgr.CanCastSkill()

    if not hPlayer or hPlayer.bFightState or not nSetID or nSetID < 0 or bNotCurrentKungFu or bOnHorse or bInArena or not bCanCastSkill then
        if hPlayer.bFightState then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tChangeTalentSetResult[SELECT_TALENT_RESULT.IN_FIGHT])
            return
        end
        if bNotCurrentKungFu then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tChangeTalentSetResult[SELECT_TALENT_RESULT.KUNG_FU_ERROR])
            return
        end
        if bOnHorse then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tChangeTalentSetResult
            [SELECT_TALENT_RESULT                          .MOVE_STATE_ERROR])
            return
        end
        if bInArena then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tChangeTalentSetResult[SELECT_TALENT_RESULT.MAP_LIMIT])
            return
        end
        if not bCanCastSkill then
            OutputMessage("MSG_ANNOUNCE_NORMAL", "动态技能状态下，无法进行该操作")
            return
        end
    end

    local currentSetID = hPlayer.GetTalentCurrentSet(dwForceID, self.nCurrentKungFuID)
    if currentSetID ~= nSetID then
        local nRetCode = hPlayer.CanChangeNewTalentSet(nSetID)
        if nRetCode == SELECT_TALENT_RESULT.SUCCESS then
            hPlayer.ChangeNewTalentSet(nSetID)
        else
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tChangeTalentSetResult[nRetCode])
        end
    end
end

function UIPanelSkillVK:UpdateBtnConfiguration()
    local nPlayerKungFuID = g_pClientPlayer.GetActualKungfuMountID()
    local bChangeKungFu = nPlayerKungFuID ~= self.nCurrentKungFuID
    local bDead = g_pClientPlayer.nMoveState == MOVE_STATE.ON_DEATH or
            g_pClientPlayer.nMoveState == MOVE_STATE.ON_AUTO_FLY
    local bSwim = g_pClientPlayer.nMoveState == MOVE_STATE.ON_FLOAT or
            g_pClientPlayer.nMoveState == MOVE_STATE.ON_SWIM_JUMP or g_pClientPlayer.nMoveState == MOVE_STATE.ON_SWIM
    local bMapLimit = ArenaData.IsInArena() or BattleFieldData.IsInTreasureBattleFieldMap() or
            CrossingData.IsInCrossing() or ArenaTowerData.IsInArenaTowerMap()
    local szDeath = g_tStrings.STR_DEAD_OR_AUTO_FLY

    local bAutoLevelEnough = g_pClientPlayer.nLevel >= 120
    local szAutoLevel = "侠士达到120级后方可开启武学助手"

    local bRecommendLevelEnough = g_pClientPlayer.nLevel >= SKILL_RESTRICTION_LEVEL
    local bLearnAllSkill = self:IsLearnedAllSkills()
    local bCanUseRecommend = not bDead and not bMapLimit and bRecommendLevelEnough and bLearnAllSkill

    local bKungfuLearned = g_pClientPlayer.GetSkillLevel(self.nCurrentKungFuID) > 0

    UIHelper.SetButtonState(self.BtnRecommend, bCanUseRecommend and BTN_STATE.Normal or BTN_STATE.Disable, function()
        local szMsg = "侠士达到106级后方可使用技能推荐"
        if not bLearnAllSkill then
            szMsg = "当前心法技能还未全部学习, 暂不支持推荐配置"
        elseif bMapLimit then
            szMsg = "当前地图不可使用技能推荐"
        elseif bDead then
            szMsg = szDeath
        end
        TipsHelper.ShowImportantBlueTip(szMsg)
    end)

    UIHelper.SetButtonState(self.BtnAutoSetting,
            (not bDead and bAutoLevelEnough) and BTN_STATE.Normal or BTN_STATE.Disable, function()
                TipsHelper.ShowImportantBlueTip(bDead and szDeath or szAutoLevel)
            end)

    UIHelper.SetButtonState(self.BtnSkillConfiguration, not bDead and BTN_STATE.Normal or BTN_STATE.Disable, function()
        TipsHelper.ShowImportantBlueTip(szDeath)
    end)

    UIHelper.SetButtonState(self.BtnSwitchXinFa,
            (bChangeKungFu and not bDead and not bMapLimit and not bSwim) and BTN_STATE.Normal or BTN_STATE.Disable,
            function()
                if bDead then
                    TipsHelper.ShowImportantBlueTip(szDeath)
                elseif bMapLimit then
                    TipsHelper.ShowImportantBlueTip("当前地图不可切换心法")
                elseif bSwim then
                    TipsHelper.ShowImportantBlueTip("水中不可切换心法")
                end
            end)

    UIHelper.SetButtonState(self.BtnEquipSetting, (not bDead and not bMapLimit) and BTN_STATE.Normal or BTN_STATE
            .Disable, function()
        local szMsg = "当前地图不可使用分页绑定"
        if bDead then
            szMsg = szDeath
        end
        TipsHelper.ShowImportantBlueTip(szMsg)
    end)

    UIHelper.SetVisible(self.BtnSwitchXinFa, bChangeKungFu and bKungfuLearned)
    UIHelper.SetVisible(self.BtnSkillConfiguration, not bChangeKungFu)
    UIHelper.SetVisible(self.BtnXinFaLock, not bKungfuLearned)
    UIHelper.LayoutDoLayout(self.LayoutBtn)

    UIHelper.SetVisible(UIHelper.GetParent(self.TogSkillConfigurationGroup), not bChangeKungFu)
end

function UIPanelSkillVK:ChangeKungFu()
    local nPlayerKungFuID = g_pClientPlayer.GetActualKungfuMountID()
    local bShouldChangeKungFu = false

    if self.nCurrentKungFuID and self.nCurrentKungFuID ~= nPlayerKungFuID then
        if g_pClientPlayer.nMoveState == MOVE_STATE.ON_SIT or g_pClientPlayer.bFightState == true then
            local szMessage = g_pClientPlayer.nMoveState == MOVE_STATE.ON_SIT
                    and g_tStrings.STR_CANNOT_CHANGE_KUNGFU_SIT or g_tStrings.STR_CANNOT_CHANGE_KUNGFU_FIGHT
            return OutputMessage("MSG_ANNOUNCE_NORMAL", szMessage)
        end
        bShouldChangeKungFu = true
    end

    local funcConfirm = function()
        if bShouldChangeKungFu then
            if not QTEMgr.CanCastSkill() then
                TipsHelper.ShowNormalTip("动态技能状态下，无法进行该操作")
                return
            end
            if g_pClientPlayer and g_pClientPlayer.nLevel < 109 then
                TipsHelper.ShowNormalTip("侠士达到109级后方可切换心法")
                return
            end

            local tParam = {
                szType = "Normal",
                szFormat = "切换心法",
                bNotShowDescribe = true,
                szIconPath = "UIAtlas2_MainCity_SystemMenu_IconSysteam15.png",
                nDuration = 64 / GLOBAL.GAME_FPS,
                nSize = 128,
                bShowCancel = false,
                fnStop = function()
                    RemoteCallToServer("On_MountKungfu_1", self.nCurrentKungFuID)
                    self:UpdateEquipPreset() -- 切换心法Tog时已更新nCurrentSetID为该心法Set
                    self.nKungFuScript = nil
                end
            }
            self.nKungFuScript = UIMgr.Open(VIEW_ID.PanelSystemPrograssBar, tParam)
        end
    end

    UIHelper.ShowConfirm("是否确认要切换心法", funcConfirm)
end

function UIPanelSkillVK:UpdateSetName()
    for i = 1, #self.tSetButtonScripts do
        local script = self.tSetButtonScripts[i]
        script:Init(i, self.nCurrentKungFuID, function()
            self:ChangeQixueSet(i - 1)
            UIHelper.SetSelected(self.TogSkillConfigurationGroup, false)
        end)

        script:BindRenameCallback(function()
            self:UpdateSetName()
        end)
    end

    local szSetName = SkillData.GetSkillSetName(self.nCurrentKungFuID, self.nCurrentSetID)
    UIHelper.SetString(self.LabelSkillConfigurationGroup, szSetName)
end

function UIPanelSkillVK:UpdateEquipPreset()
    --大师赛玩法里切武学配置时，只切武学分页，不切装备分页
    local dwMapID = MapHelper.GetMapID()
    local bIsMasterEquipMap = IsMasterEquipMap(dwMapID)
    if bIsMasterEquipMap then
        TipsHelper.ShowNormalTip("仅切换武学，该地图无法切换装备页")
        return
    end

    local nEquipBindIndex = SkillData.GetSkillEquipBinding(self.nCurrentKungFuID, self.nCurrentSetID + 1)
    if nEquipBindIndex then
        EquipData.SwitchEquip(nEquipBindIndex)
    end
end

--------------------------Utils--------------------------------

function UIPanelSkillVK:UpdateNonSchoolBtn(bInvokeTrace)
    local nHDKungfuID = TabHelper.GetHDKungfuID(self.nCurrentKungFuID)
    local szQuestList = Table_GetSkillQuestList(nHDKungfuID)
    local dwQuestID, bPreQuest
    if szQuestList and szQuestList ~= "" then
        dwQuestID, bPreQuest = GetQuestTrackID(szQuestList)
        if dwQuestID then
            UIHelper.SetLabel(self.LabelXinFaLock, bPreQuest and "解锁心法" or "追踪任务")
        end
    end

    if bInvokeTrace and dwQuestID then
        MapMgr.TransferToNearestCity(dwQuestID) -- 解锁后自动追踪任务
    end

    UIHelper.BindUIEvent(self.BtnXinFaLock, EventType.OnClick, function()
        NewSkillPanel_UnLockLiuPai(dwQuestID, bPreQuest, nHDKungfuID)
    end)
end

function UIPanelSkillVK:PlayEffectAfterSetChange()
    if self.tSlotToSkillID_Old and self.tSlotScripts then
        for i, script in ipairs(self.tSlotScripts) do
            local slotIndex = tSlotIndex[i]
            local nSkillID = self:GetShowSkill(slotIndex)

            local nOldSkillID = self.tSlotToSkillID_Old[i]
            if nSkillID and nOldSkillID ~= nSkillID then
                script:ShowEffect()
            end
        end
    end
end

function UIPanelSkillVK:GetShowSkill(nSlotIndex)
    return self.tSlotToSkillID[nSlotIndex]
end

function UIPanelSkillVK:GotoConfiguration()
    local nPlayerKungFuID = g_pClientPlayer.GetActualKungfuMountID()
    if self.nCurrentKungFuID and self.nCurrentKungFuID ~= nPlayerKungFuID then
        return TipsHelper.ShowNormalTip("应用本心法后可配置")
    end

    if g_pClientPlayer.bFightState then
        TipsHelper.ShowNormalTip("战斗中无法进行技能配置")
    elseif not QTEMgr.CanCastSkill() then
        TipsHelper.ShowNormalTip("动态技能状态下，无法进行该操作")
    else
        UIMgr.Open(VIEW_ID.PanelSkillConfiguration, self.nCurrentKungFuID, self.nCurrentSetID)
    end
end

-- 无相楼需要技能全部学齐之后再显示武学推荐
function UIPanelSkillVK:IsLearnedAllSkills()
    local skillInfoList = SkillData.GetCurrentPlayerSkillList(self.nCurrentKungFuID)

    local commonSkillList = {}
    local secSprintSkillList = {}
    local normalSkillList = {}

    for _, tSkill in ipairs(skillInfoList) do
        local nSkillID = tSkill.nID
        local skillInfo = tSkill.tInfo
        if skillInfo.nType == UISkillType.Common then
            table.insert(commonSkillList, nSkillID)
        elseif skillInfo.nType == UISkillType.Skill then
            table.insert(normalSkillList, nSkillID)
        elseif skillInfo.nType == UISkillType.SecSprint then
            table.insert(secSprintSkillList, nSkillID)
        end
    end
    return #commonSkillList >= 2 and #normalSkillList >= 8
end

return UIPanelSkillVK
