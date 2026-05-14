-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetSkillConfiguration
-- Date: 2024-07-26 16:02:01
-- Desc: WidgetSkillConfiguration 武学选择
-- ---------------------------------------------------------------------------------

local UIWidgetSkillConfiguration = class("UIWidgetSkillConfiguration")

function UIWidgetSkillConfiguration:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.tSetButtonScripts = {}

        for i = 1, #self.skillSetWidgets do
            local script = UIHelper.GetBindScript(self.skillSetWidgets[i]) ---@type UIWidgetSkillSetButton
            table.insert(self.tSetButtonScripts, script)

            UIHelper.SetTouchDownHideTips(script.BtnGroup, false)
        end

        UIHelper.SetTouchDownHideTips(self.TogSkillConfigurationGroup, false)
        UIHelper.SetTouchDownHideTips(self.BtnWuXue, false)
        UIHelper.SetTouchDownHideTips(self.BtnSkillSetClose, false)
        UIHelper.SetTouchDownHideTips(self.ScrollViewGroupTip, false)
    end

    self.nCurrentKungFuID = g_pClientPlayer.GetActualKungfuMount().dwSkillID
    self.nCurrentSetID = g_pClientPlayer.GetTalentCurrentSet(g_pClientPlayer.dwForceID, self.nCurrentKungFuID)
    self:UpdateInfo()
end

function UIWidgetSkillConfiguration:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSkillConfiguration:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnWuXue, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelSkillNew)
        UIHelper.SetSelected(self.TogSkillConfigurationGroup, false)

        --切心法教学
        if TeachEvent.CheckCondition(43) then
            TeachEvent.TeachStart(43)
        end
    end)
    UIHelper.BindUIEvent(self.BtnSkillSetClose, EventType.OnClick, function()
        UIHelper.SetSelected(self.TogSkillConfigurationGroup, false)
    end)

    UIHelper.BindUIEvent(self.TogSkillConfigurationGroup, EventType.OnClick, function(btn)
        self:UpdateInfo()
    end)
end

function UIWidgetSkillConfiguration:RegEvent()
    Event.Reg(self, "DO_SKILL_PREPARE_PROGRESS", function(nTotalFrame, dwSkillID, dwSkillLevel, dwCasterID)
        if not UIHelper.GetHierarchyVisible(self._rootNode) then
            return
        end

        local hPlayer = g_pClientPlayer
        local nChangeSkillID = 101164
        local nChangeSkillDXID = 9092
        if not (hPlayer and nTotalFrame > 0) or hPlayer.dwID ~= dwCasterID or (dwSkillID ~= nChangeSkillID and dwSkillID ~= nChangeSkillDXID) then
            return
        end

        local tParam = {
            szType = "Normal",
            szFormat = "切换配置",
            nDuration = nTotalFrame / GLOBAL.GAME_FPS,
            bNotShowDescribe = true,
            szIconPath = "UIAtlas2_MainCity_SystemMenu_IconSysteam15.png",
            fnCancel = function()
                GetClientPlayer().StopCurrentAction()
            end,
            fnStop = function(bCompleted)
                if bCompleted then
                    Event.Dispatch(EventType.OnSkillConfigurationCompleted)
                end
            end,
        }
        UIMgr.Open(VIEW_ID.PanelSystemPrograssBar, tParam)
    end)

    Event.Reg(self, EventType.OnSkillConfigurationCompleted, function()
        local hPlayer = g_pClientPlayer
        if not hPlayer then
            return
        end

        self.nCurrentSetID = hPlayer.GetTalentCurrentSet(hPlayer.dwForceID, self.nCurrentKungFuID)
        self:UpdateInfo()

        self:UpdateEquipPreset()
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelSkillNew then
            self.nCurrentKungFuID = g_pClientPlayer.GetActualKungfuMount().dwSkillID
            self.nCurrentSetID = g_pClientPlayer.GetTalentCurrentSet(g_pClientPlayer.dwForceID, self.nCurrentKungFuID)
            self:UpdateInfo()
        end
    end)
    Event.Reg(self, EventType.HideAllHoverTips, function()
        UIHelper.SetSelected(self.TogSkillConfigurationGroup, false)
    end)
end

function UIWidgetSkillConfiguration:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSkillConfiguration:UpdateInfo()
    self:UpdateSetName()
end

function UIWidgetSkillConfiguration:UpdateSetName()
    local nMaxSetNum = SkillData.IsUsingHDKungFu() and 5 or 3
    for i = 1, #self.tSetButtonScripts do
        local nIndex = i
        local script = self.tSetButtonScripts[nIndex]
        script:InitToggle(nIndex, self.nCurrentKungFuID, function()
            self:ChangeQixueSet(nIndex - 1)
            UIHelper.SetSelected(self.TogSkillConfigurationGroup, false)
        end)

        script:BindRenameCallback(function()
            self:UpdateSetName()
        end)

        UIHelper.SetVisible(script._rootNode, i <= nMaxSetNum)
    end

    local szSetName = SkillData.GetSkillSetName(self.nCurrentKungFuID, self.nCurrentSetID)
    UIHelper.SetString(self.LabelSkillConfigurationGroup, szSetName)

    --心法
    local nSkillID = g_pClientPlayer.GetActualKungfuMountID()
    UIHelper.SetSpriteFrame(self.ImgSkillIcon, PlayerKungfuImg[nSkillID], true,true)

    local nHDKungFuID = TabHelper.GetHDKungfuID(nSkillID)
    local nPosType = PlayerKungfuPosition[nHDKungFuID] or KUNGFU_POSITION.DPS
    local szXinFaImg = SkillKungFuTypeImg[nPosType]
    UIHelper.SetSpriteFrame(self.ImgXinFaType, szXinFaImg)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewGroupTip)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewGroupTip, self.WidgetArrowParrent)
end

function UIWidgetSkillConfiguration:ChangeQixueSet(nSetID)
    local hPlayer = g_pClientPlayer
    local dwForceID = hPlayer.dwForceID
    local bNotCurrentKungFu = g_pClientPlayer.GetActualKungfuMount().dwSkillID ~= self.nCurrentKungFuID
    local bOnHorse = g_pClientPlayer.bOnHorse
    local bInArena = ArenaData.IsInArena() or ArenaTowerData.IsInArenaTowerMap()
    local bCanCastSkill = QTEMgr.CanCastSkill()

    if not hPlayer or hPlayer.bFightState or not nSetID or nSetID < 0 or bNotCurrentKungFu or bOnHorse or bInArena then
        if hPlayer.bFightState then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tChangeTalentSetResult[SELECT_TALENT_RESULT.IN_FIGHT])
            return
        end
        if bNotCurrentKungFu then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tChangeTalentSetResult[SELECT_TALENT_RESULT.KUNG_FU_ERROR])
            return
        end
        if bOnHorse then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tChangeTalentSetResult[SELECT_TALENT_RESULT.MOVE_STATE_ERROR])
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

function UIWidgetSkillConfiguration:UpdateEquipPreset()
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

return UIWidgetSkillConfiguration