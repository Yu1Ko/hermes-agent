-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelSkillDX
-- Date: 2025-07-08 10:01:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

PanelSkillDX = {
    nLocalSelected = nil
}

---@class UIPanelSkillDX
local UIPanelSkillDX = class("UIPanelSkillDX")

function UIPanelSkillDX:OnEnter(nKungFuID)
    if not self.bInit then
        self:BindUIEvent()
        self.bInit = true
        self.bShowFirstPage = true

        self.nCurrentKungFuID = nKungFuID or g_pClientPlayer.GetActualKungfuMountID()
        self.nCurrentSetID = g_pClientPlayer.GetTalentCurrentSet(g_pClientPlayer.dwForceID, self.nCurrentKungFuID)
        self.nDXSkillBarIndex = SkillData.GetCurrentDxSkillBarIndex()

        SkillData.GetCurrentPlayerSkillList(self.nCurrentKungFuID)
        self.tAcupointCellScripts = {}

        self.tSetButtonScripts = {}
        for i = 1, 5 do
            local script = UIHelper.GetBindScript(self.skillSetWidgets[i]) ---@type UIWidgetSkillSetButton
            table.insert(self.tSetButtonScripts, script)
        end

        self:InitSlotScript()
        self:InitQiXue()
        self:InitXinFaInfo() -- 在最后执行，因为里面包含一次self:UpdateInfo()的调用
    end

    UIHelper.BindUIEvent(self.BtnIntroduce, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelIntroduce, self.nCurrentKungFuID, self.nCurrentSetID)
    end)

    self:RegEvent()
    self:UpdateBtnConfiguration()
    -- self:UpdateInfo()
end

function UIPanelSkillDX:OnExit()
    PanelSkillDX = {}
    self:UnRegEvent()

    if self.QianJiScript and UIHelper.GetVisible(self.QianJiScript._rootNode) then
        self.QianJiScript:Close()
    end
end

function UIPanelSkillDX:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSwitchXinFa, EventType.OnClick, function()
        self:SwitchKungFu()
    end)

    UIHelper.BindUIEvent(self.BtnPreviewQiXue, EventType.OnClick, function()
        self:ShowQiXuePreview()
        UIHelper.SetVisible(self.WidgetDXAttributePreview, true)
    end)

    UIHelper.BindUIEvent(self.BtnClosePreview, EventType.OnClick, function()
        UIHelper.SetVisible(self.WidgetDXAttributePreview, false)
    end)

    UIHelper.BindUIEvent(self.BtnSkillConfiguration, EventType.OnClick, function()
        self:GotoConfiguration()
    end)

    UIHelper.BindUIEvent(self.BtnSkillSetClose, EventType.OnClick, function()
        UIHelper.SetSelected(self.TogSkillConfigurationGroup, false)
    end)

    UIHelper.BindUIEvent(self.BtnSwitchPage, EventType.OnClick, function()
        self.bShowFirstPage = not self.bShowFirstPage
        self:UpdatePageState()
    end)

    UIHelper.BindUIEvent(self.BtnRecommend, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelSkillRecommendDX)
    end)

    UIHelper.BindUIEvent(self.BtnMacro, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelHongSetting, self.nCurrentKungFuID)
    end)

    UIHelper.BindUIEvent(self.BtnEquipSetting, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelSkillEquipSettingPop, self.nCurrentKungFuID)
    end)

    UIHelper.BindUIEvent(self.BtnQianJiXia, EventType.OnClick, function()
        if self.QianJiScript and UIHelper.GetVisible(self.QianJiScript._rootNode) then
            self.QianJiScript:Close()
        else
            local nX = UIHelper.GetWorldPositionX(self.BtnQianJiXia)
            local nY = UIHelper.GetWorldPositionY(self.BtnQianJiXia)

            self.QianJiScript = self.QianJiScript or UIHelper.AddPrefab(PREFAB_ID.WidgetQianJiXiaTip, self._rootNode)
            local tips = HoverTips.New(self.QianJiScript._rootNode)
            tips:SetDisplayLayoutDir(TipsLayoutDir.TOP_LEFT)
            tips:Show(nX, nY)
            UIHelper.SetVisible(self.QianJiScript._rootNode, true)
        end
    end)
end

function UIPanelSkillDX:RegEvent()
    Event.Reg(self, "ON_UPDATE_TALENT", function()
        local hPlayer = g_pClientPlayer
        Timer.DelTimer(self, self.nUpdateTalent)
        self.nUpdateTalent = Timer.AddFrame(self, 1, function()
            local nNewSkillSet = hPlayer and hPlayer.GetTalentCurrentSet(hPlayer.dwForceID, self.nCurrentKungFuID)
            if hPlayer and nNewSkillSet ~= self.nCurrentSetID then
                self.nCurrentSetID = nNewSkillSet
                self:UpdateInfo()
                self:UpdateEquipPreset() -- 依赖 self.nCurrentSetID = nSetID
            else
                self:UpdateInfo()
            end
            --UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAcupointListDX)
        end)
    end)

    Event.Reg(self, "FIGHT_HINT", function(bFight)
        if self.nKungFuScript and bFight then
            self.nKungFuScript:StopProgressBar()
        end
    end)

    Event.Reg(self, "UPDATE_TALENT_SET_SLOT_SKILL", function()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnDXMacroUpdate, function()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnDxSkillBarIndexChange, function()
        Timer.AddFrame(self, 1, function()
            self.nDXSkillBarIndex = SkillData.GetCurrentDxSkillBarIndex() -- 等待SkillReplace事件完成替换后再Update
            self:UpdateInfo()
        end)
    end)

    Event.Reg(self, EventType.OnPoseChange, function(nIndex)
        self.nDXSkillBarIndex = nIndex
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_SKILL_REPLACE_DX", function()
        Timer.DelTimer(self, self.nUpdateReplace)
        self.nUpdateReplace = Timer.AddFrame(self, 1, function()
            self:UpdateSkillSlots()
            self.nUpdateReplace = nil
        end)
    end)

    Event.Reg(self, "On_Liupai_UnLockFinished", function()
        self:UpdateNonSchoolBtn(true)
    end)

    Event.Reg(self, "BULLETBACKUP_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
        self:UpdateTangMenBullet()
    end)
end

function UIPanelSkillDX:UnRegEvent()
    Event.UnRegAll(self)
end

function UIPanelSkillDX:UpdateInfo()
    self:UpdateQiXue()
    self:UpdateSkillSlots()
    self:UpdateBtnConfiguration()
    self:UpdatePageState()
    self:UpdateSetName()
    self:UpdateNonSchoolBtn()
    self:UpdateTangMenBullet()
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelSkillDX:InitSlotScript()
    self.tSlotScripts = {}

    local listScript1 = UIHelper.AddPrefab(PREFAB_ID.WidgetSkilSwitchListDX, self.WidgetSkillSwitchListDX)
    local listScript2 = UIHelper.AddPrefab(PREFAB_ID.WidgetSkilSwitchListDX, self.WidgetSkillSwitchListDXSecond)
    local twoPageScripts = { listScript1, listScript2 }

    ---------------------------初始化前22个槽位----------------------------
    for _, listScript in ipairs(twoPageScripts) do
        for nIndex, tParent in ipairs(listScript.tSlots) do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, tParent)
            table.insert(self.tSlotScripts, script)
            if nIndex == 1 then
                UIHelper.SetScale(script.LabelSkillName, 0.7, 0.7)
            end
        end
    end

    local tWidgets = {
        self.WidgetSkill12DX,
        self.WidgetSkill13DX,
        self.WidgetSkill14DX, -- 左侧固定三槽

        self.WidgetSkillQingGong2,
        self.WidgetSkillJump, -- 左侧固定三槽
        self.WidgetSkillQingGong1,

        self.WidgetSkillQingGongCombine, -- 29
    }

    for nIndex, tParent in ipairs(tWidgets) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, tParent)
        table.insert(self.tSlotScripts, script)

        if nIndex == 4 or nIndex == 5 or nIndex == 6 then
            script:HideSkillBg()
        end
    end

    for nIndex, script in ipairs(self.tSlotScripts) do
        local parent = UIHelper.GetParent(script._rootNode)
        local nScale = UIHelper.GetScaleX(parent)
        if nScale == 1 then
            UIHelper.SetScale(script.LabelSkillName, 0.7, 0.7) -- 对大图标设置文字大小缩放
        end
    end
end

function UIPanelSkillDX:InitXinFaInfo()
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupXinFa)
    UIHelper.RemoveAllChildren(self.LayoutSkillNewLeftXinFa)

    self.tXinFaToggles = {}
    local playerKungFuList = NewSkillPanel_GetKungFuList(true)

    for i = 1, #playerKungFuList do
        local nSkillID = playerKungFuList[i] and playerKungFuList[i][1]
        if nSkillID then
            local t = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillNewLeftXinFa, self.LayoutSkillNewLeftXinFa, nSkillID)
            t.nSkillID = nSkillID
            table.insert(self.tXinFaToggles, t)
        end
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
                self:SelectKungFu(playerKungFuList[index][1])
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
    self:SelectKungFu(playerKungFuList[nFirstSelectedIndex + 1][1])
end

function UIPanelSkillDX:SelectKungFu(nKungFuID, bOperateTog)
    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return
    end

    local dwForceID = hPlayer.dwForceID
    self.nCurrentKungFuID = nKungFuID
    self.nCurrentSetID = hPlayer.GetTalentCurrentSet(dwForceID, self.nCurrentKungFuID)
    self.bShowFirstPage = true
    self.nDXSkillBarIndex = SkillData.GetPreviewSkillBarIndex(GetSkill(self.nCurrentKungFuID, 1))
    UIHelper.ScrollToPercent(self.ScrollViewAcupointListDX, 0)
    self:UpdateInfo()
end

function UIPanelSkillDX:InitQiXue()
    -- DX奇穴：1核心奇穴，2~7常规奇穴，8~10混选奇穴, VK奇穴默认老奇穴规则
    for i = 1, 6 do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetConfigurationAcupointDX, self.ScrollViewAcupointListDX, i) ---@type UIWidgetAcupointCell
        table.insert(self.tAcupointCellScripts, script)
    end
    self.tMixedAcupointScript = UIHelper.AddPrefab(PREFAB_ID.WidgetConfigurationAcupointDX, self.ScrollViewAcupointListDX) ---@type UIWidgetAcupointCell
    --self.tDouQiAcupointScript = UIHelper.AddPrefab(PREFAB_ID.WidgetConfigurationAcupointDX, self.ScrollViewAcupointListDX) ---@type UIWidgetAcupointCell
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAcupointListDX)
end

function UIPanelSkillDX:UpdateQiXue()
    local bIsKungFuMatched = self.nCurrentKungFuID == g_pClientPlayer.GetActualKungfuMountID()
    local tList = SkillData.GetQixueList(true, self.nCurrentKungFuID, self.nCurrentSetID)
    local dwCoreColor = 0
    local tDouqiQixue = nil
    local bHasQiXue = #tList > 0
    for nIndex, tQixue in ipairs(tList) do
        if tQixue.nType == TALENT_SELECTION_TYPE.CORE then
            if tQixue.nSelectIndex ~= 0 then
                local tSkill = tQixue.SkillArray[tQixue.nSelectIndex]
                dwCoreColor = tSkill.dwSkillColor
            end
        end
        if tQixue.nType == SkillData.DouqiQixueType then
            tDouqiQixue = tQixue
        end
    end
    if tDouqiQixue then
        table.remove_value(tList, tDouqiQixue) -- 延后删除 防止遍历顺序错误
    end

    if bHasQiXue then
        for nIndex, script in ipairs(self.tAcupointCellScripts) do
            if tList[nIndex] then
                local nSelectIndex = tList[nIndex].nSelectIndex
                local dwPointID = tList[nIndex].dwPointID

                script:SetTitle(QixueTitleList[nIndex])
                script:SetCoreColor(dwCoreColor)
                script:UpdateInfoDX(tList[nIndex], self.WidgetAcupointTipParentDX, not bIsKungFuMatched)
            end
        end

        self.tMixedAcupointScript:SetCoreColor(dwCoreColor)
        self.tMixedAcupointScript:UpdateInfoDXMixed(tList, bIsKungFuMatched, self.WidgetAcupointTipParentDX)

        --if tDouqiQixue then
        --    self.tDouQiAcupointScript:SetCoreColor(dwCoreColor)
        --    self.tDouQiAcupointScript:SetTitle("内劲天赋")
        --    self.tDouQiAcupointScript:UpdateInfoDX(tDouqiQixue, self.WidgetAcupointTipParentDX, not bIsKungFuMatched)
        --end
    end

    for nIndex, script in ipairs(self.tAcupointCellScripts) do
        UIHelper.SetActiveAndCache(self, script._rootNode, bHasQiXue)
    end
    UIHelper.SetActiveAndCache(self, self.tMixedAcupointScript._rootNode, bHasQiXue)
    local nPercent = UIHelper.GetScrollPercent(self.ScrollViewAcupointListDX)
    UIHelper.ScrollViewDoLayout(self.ScrollViewAcupointListDX)
    UIHelper.ScrollToPercent(self.ScrollViewAcupointListDX, nPercent)
    if nPercent < 99 then
        UIHelper.ScrollViewSetupArrow(self.ScrollViewAcupointListDX, self.WidgetArrowParentDX)
    end
end

function UIPanelSkillDX:UpdateBtnConfiguration()
    local nPlayerKungFuID = g_pClientPlayer.GetActualKungfuMountID()
    local bChangeKungFu = nPlayerKungFuID ~= self.nCurrentKungFuID
    local bDead = g_pClientPlayer.nMoveState == MOVE_STATE.ON_DEATH or
            g_pClientPlayer.nMoveState == MOVE_STATE.ON_AUTO_FLY
    local bSwim = g_pClientPlayer.nMoveState == MOVE_STATE.ON_FLOAT or
            g_pClientPlayer.nMoveState == MOVE_STATE.ON_SWIM_JUMP or g_pClientPlayer.nMoveState == MOVE_STATE.ON_SWIM
    local bMapLimit = ArenaData.IsInArena() or BattleFieldData.IsInTreasureBattleFieldMap() or
            CrossingData.IsInCrossing() or ArenaTowerData.IsInArenaTowerMap()
    local szDeath = g_tStrings.STR_DEAD_OR_AUTO_FLY

    local bRecommendLevelEnough = g_pClientPlayer.nLevel >= SKILL_RESTRICTION_LEVEL
    local bCanUseRecommend = not bDead and not bMapLimit and bRecommendLevelEnough

    local bLearned = g_pClientPlayer.GetSkillLevel(self.nCurrentKungFuID) > 0

    UIHelper.SetButtonState(self.BtnRecommend, bCanUseRecommend and BTN_STATE.Normal or BTN_STATE.Disable, function()
        local szMsg = "侠士达到106级后方可使用技能推荐"
        if bMapLimit then
            szMsg = "当前地图不可使用技能推荐"
        elseif bDead then
            szMsg = szDeath
        end
        TipsHelper.ShowImportantBlueTip(szMsg)
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

    UIHelper.SetVisible(self.BtnSwitchXinFa, bChangeKungFu and bLearned)
    UIHelper.SetVisible(self.BtnSkillConfiguration, not bChangeKungFu)
    UIHelper.SetVisible(self.LayoutTogNavSpecialPage, not bChangeKungFu)
    UIHelper.SetVisible(self.BtnEquipSetting, not bChangeKungFu)
    UIHelper.SetVisible(self.BtnXinFaLock, not bLearned)
    UIHelper.SetVisible(self.BtnQianJiXia, ItemData.CanWeaponBagOpen())
    UIHelper.LayoutDoLayout(self.LayoutBtn)

    UIHelper.SetVisible(UIHelper.GetParent(self.TogSkillConfigurationGroup), not bChangeKungFu)
end

function UIPanelSkillDX:UpdateSkillSlots()
    local hPlayer = g_pClientPlayer
    if not g_pClientPlayer then
        return
    end
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupAction)

    for i, script in ipairs(self.tSlotScripts) do
        local slotIndex = i
        local tSlotData = SkillData.GetDxSlotData(slotIndex, self.nDXSkillBarIndex)
        local bHaveData = not IsTableEmpty(tSlotData)
        if tSlotData.nType == DX_ACTIONBAR_TYPE.MACRO and IsMacroRemoved(tSlotData.data1) then
            bHaveData = false
            tSlotData = {}
        end

        UIHelper.SetVisible(script.ImgAdd, not bHaveData) -- 空槽位 显示+号
        UIHelper.SetVisible(script.ImgSkillIcon, bHaveData)
        if bHaveData then
            script:UpdateInfoDX(tSlotData)
            script:ShowShortcutDX(slotIndex)
        else
            script:HideLabel()
            script:UpdateMijiDot(false)
        end

        self:ConfigureToggle(script.TogSkill, tSlotData)
    end
end

function UIPanelSkillDX:ShowQiXuePreview()
    UIHelper.RemoveAllChildren(self.LayoutDXAttributePreview)
    local tList = SkillData.GetQixueList(true, self.nCurrentKungFuID, self.nCurrentSetID)
    local fnSortByLevel = function(tLeft, tRight)
        local nLeft = tLeft.nRequireLevel + (tLeft.nType == SkillData.DouqiQixueType and 1000 or 0)
        local nRight = tRight.nRequireLevel + (tRight.nType == SkillData.DouqiQixueType and 1000 or 0)
        if nLeft == nRight then
            return tLeft.dwPointID < tRight.dwPointID
        end
        return nLeft < nRight
    end
    table.sort(tList, fnSortByLevel) -- 把内劲奇穴排到最后
    
    for nIndex, data in ipairs(tList) do
        if tList[nIndex] then
            local nSelectIndex = data.nSelectIndex
            local tSkillArray = data.SkillArray

            if nSelectIndex > 0 then
                local nSkillID = tSkillArray[nSelectIndex].dwSkillID
                local nSkillLevel = tSkillArray[nSelectIndex].dwSkillLevel
                local tSkill = nSkillID > 0 and GetSkill(nSkillID, nSkillLevel)

                if nSkillID > 0 and tSkill then
                    local nPrefabID = tSkill.bIsPassiveSkill and PREFAB_ID.WidgetSkillPassiveCell or
                            PREFAB_ID.WidgetSkillCell1
                    local cellScript = UIHelper.AddPrefab(nPrefabID, self.LayoutDXAttributePreview, nSkillID)
                    local fnClose = function()
                        cellScript:SetSelected(false)
                    end
                    cellScript:ShowName(true)
                    cellScript:BindSelectFunction(function()
                        local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetAcupointTip,
                                self.WidgetAcupointTipParentDX, TipsLayoutDir.MIDDLE)
                        script:Init(tSkillArray[nSelectIndex], true, nil, fnClose)
                        script:HideButton()
                    end)
                end
            else
                local cellScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillPassiveCell, self.LayoutDXAttributePreview)
                cellScript:SetSelectEnable(false)
            end
        end
    end
end

function UIPanelSkillDX:UpdatePageState()
    UIHelper.SetVisible(self.WidgetSkillSwitchListDX, self.bShowFirstPage)
    UIHelper.SetVisible(self.WidgetSkillSwitchListDXSecond, not self.bShowFirstPage)
    UIHelper.SetOpacity(self.ImgPage1, self.bShowFirstPage and 255 or 70)
    UIHelper.SetOpacity(self.ImgPage2, not self.bShowFirstPage and 255 or 70)
end

function UIPanelSkillDX:ConfigureToggle(tog, tSlotData)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupSkillConf, tog)
    UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(toggle, bSelected)
        local fnExit = function()
            Timer.AddFrame(self, 1, function()
                UIHelper.SetSelected(tog, false)
            end)
        end
        if bSelected then
            if IsTableEmpty(tSlotData) then
                self:GotoConfiguration()
                fnExit()
            else
                SkillData.ShowDxSlotTips(tSlotData, self.WidgetActionDX, fnExit, TipsLayoutDir.LEFT_CENTER)
            end
        end
    end)
end

function UIPanelSkillDX:SwitchKungFu()
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

function UIPanelSkillDX:GotoConfiguration()
    local nPlayerKungFuID = g_pClientPlayer.GetActualKungfuMountID()
    if self.nCurrentKungFuID and self.nCurrentKungFuID ~= nPlayerKungFuID then
        return TipsHelper.ShowNormalTip("应用本心法后可配置")
    elseif not QTEMgr.CanCastSkill() then
        return TipsHelper.ShowNormalTip("动态技能状态下，无法进行该操作")
    end

    UIMgr.Open(VIEW_ID.PanelSkillConfiguration, self.nCurrentKungFuID, self.nCurrentSetID, self.bShowFirstPage, self.nDXSkillBarIndex)
end

--------------------------套路配置相关--------------------------------

function UIPanelSkillDX:UpdateSkillSetToggles()
    UIHelper.SetToggleGroupSelected(self.ToggleGroupSkillSet, self.nCurrentSetID)
end

function UIPanelSkillDX:ChangeQixueSet(nSetID)
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

function UIPanelSkillDX:UpdateSetName()
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

function UIPanelSkillDX:UpdateEquipPreset()
    ----大师赛玩法里切武学配置时，只切武学分页，不切装备分页
    local dwMapID = MapHelper.GetMapID()
    local bIsMasterEquipMap = IsMasterEquipMap(dwMapID)
    if bIsMasterEquipMap then
        TipsHelper.ShowNormalTip("仅切换武学，该地图无法切换装备页")
        return
    end

    local nEquipBindIndex = SkillData.GetSkillEquipBindingDX(self.nCurrentKungFuID, self.nCurrentSetID + 1)
    if nEquipBindIndex then
        EquipData.SwitchEquip(nEquipBindIndex)
    end
end

function UIPanelSkillDX:OnChangeKungFu(nMountKungFuID)
    Timer.AddFrame(self, 2, function()
        if nMountKungFuID ~= self.nCurrentKungFuID and TabHelper.IsHDKungfuID(nMountKungFuID) then
            for index, script in ipairs(self.tXinFaToggles) do
                if script.nSkillID == nMountKungFuID then
                    UIHelper.SetToggleGroupSelected(self.ToggleGroupXinFa, index - 1)
                    self:SelectKungFu(nMountKungFuID)
                    break
                end
            end
        end
    end)
end

----------------------------------------------------------

function UIPanelSkillDX:UpdateNonSchoolBtn(bInvokeTrace)
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

function UIPanelSkillDX:UpdateTangMenBullet()
    if UIHelper.GetVisible(self.BtnQianJiXia) then
        local nArrow, nJiGuan = ItemData.GetTangMenBulletCount()
        UIHelper.SetLabel(self.LabelQianJiXia1, string.format("弩箭：%d\n机关：%d", nArrow, nJiGuan))
    end
end

return UIPanelSkillDX
