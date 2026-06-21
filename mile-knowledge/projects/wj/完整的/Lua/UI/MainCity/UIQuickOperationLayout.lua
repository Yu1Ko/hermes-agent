-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIQuickOperationLayout
-- Date: 2023-03-20 15:14:08
-- Desc: ?
-- ---------------------------------------------------------------------------------

local ACTION_ID = {
    --- 打开 szAction 指定的界面，不附带任何参数
    OpenPanel = 1,
    --- 施放 szAction 指定的技能
    CastSkill = 2,
    --- 摆擂或取消摆擂，取决于 bSetClose 的状态
    BaiLei = 3,
    --- 关闭阵营模式
    OpenCloseCamp = 5,
    --- 寻宝
    TreasureHunting = 6,
    --- 触发 szAction 指定的事件，不附带任何参数。可以在Global或者指定界面去监听该事件，从而实现一些非通用的逻辑，避免每次新加一个action id
    DispatchEvent = 7,
    -- 执行Lua
    LoadString = 8,
    --- 宠物 呼出宠物界面/快捷召回
    PetAction = 9,
    --- 宠物 是否显示交互 配置存本地
    QuickPetAction = 10,
    --- 侠客 是否显示交互 配置存本地
    QuickPartnerAction = 11,
}

--- 一些需要特殊判定的菜单项的ID枚举，需要确保ID不会被修改
local CUSTOM_RULE_MENU_ID = {
    --- 召唤侠客
    SummonPartner = 8,
    --- 收回侠客# 已废弃
    RecallPartner = 9,
    --- 侠客跟随
    PartnerFollow = 10,
    --- 侠客攻击
    PartnerAttack = 11,
    --- 侠客停留
    PartnerStop = 12,
    --- 显示共鸣
    ShowPartnerMorph = 13,
    --- 隐藏共鸣
    HidePartnerMorph = 14,
    --- 战斗数据
    DamageStatistic = 15,
    --- 焦点列表
    FocusList = 16,
    --- 谁在看我
    WhoSeeMe = 17,
    --- 套马
    LassoHorse = 19,
    --- 场景标记
    StartEndWorldMark = 22,
    --- 标记管理
    ManageWorldMark = 23,
    --- 切换走路
    ToggleRun = 27,
    --- 屏蔽NPC
    HideNpc = 28,
    --- 屏蔽NPC
    TeamVoice = 29,
    --- 一键标记
    AutoTeamMark = 30,
    --- 同模
    CampUniform = 31,
    --- 轻功模式
    QingGongMode = 32,
    --- 万灵复活技能
    WanLingReviveSkill = 38,
    --- 隐藏/显示宠物交互
    HidePetAction = 40,
    --- 侠客开战
    PartnerTankAttack = 41,
    --- 隐藏/显示侠客交互
    HidePartnerAction = 42,
    --- 重载按键
    ResetSkillAndJoyStick = 43,
}

local ID2STAT_TYPE = {
    [15] = STAT_TYPE.HATRED,
    [16] = STAT_TYPE.DAMAGE,
    [17] = STAT_TYPE.THERAPY,
    [18] = STAT_TYPE.BE_DAMAGE,
    [19] = STAT_TYPE.BE_THERAPY,
}

local MAP_TYPE = {
	COMMON = 1,
	ATHLETICS = 2,
	SECRETAREA = 3,
    PARTNER = 4
}

local UIQuickOperationLayout = class("UIQuickOperationLayout")

function UIQuickOperationLayout:OnEnter(nGroupID, nType, tAction)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nGroupID = nGroupID
    self.nType = nType
    self.tAction = tAction or {}
    self.bInModifyState = false
    self.tCellScript = {}
    self.nMapType = nil
    if not self.bCustomUpdate then
        if nGroupID then
            self:GetMapType()
            self:UpdateQuickInfo()
        else
            self:UpdateActionInfo()
        end
    end
end

function UIQuickOperationLayout:OnExit()
    self.bInit = false
    self:UnRegEvent()

    for k, v in ipairs(self.tbRedPointNode or {}) do
        RedpointMgr.UnRegisterRedpoint(v)
    end
end

function UIQuickOperationLayout:BindUIEvent()

end

function UIQuickOperationLayout:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "SKILL_UPDATE", function(arg0, arg1)
        if self.nGroupID then
            self:UpdateQuickInfo()
        else
            self:UpdateActionInfo()
        end
    end)

    Event.Reg(self, "OpenPlayerDisplayModeList", function(btn)
        local tBtnInfoList = {}
        local tCellInfo = { GameSettingType.PlayDisplay.All,
                            GameSettingType.PlayDisplay.OnlyPartyPlay,
                            GameSettingType.PlayDisplay.HideAll }
        for _, v in ipairs(tCellInfo) do
            local tInfo = { szName = v.szDec, func = function()
                APIHelper.SetPlayDisplay(v, true)
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetSettingsMultipleChoicePop)
            end, fnSelected = function()
                local tbPlayDisplay = APIHelper.GetPlayDisplay()
                if not tbPlayDisplay then
                    return false
                end
                return v.szDec == tbPlayDisplay.szDec
            end }
            table.insert(tBtnInfoList, tInfo)
        end

        -- local tCursor = GetCursorPoint()
        -- local tip, script = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetSettingsMultipleChoicePop, tCursor.x, tCursor.y, tBtnInfoList)
        local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSettingsMultipleChoicePop, btn, TipsLayoutDir.LEFT_CENTER, tBtnInfoList)
        script:UpdateSingleChoice(tBtnInfoList)
        --tip:SetSize(UIHelper.GetContentSize(script.LayoutMultipleChoice))
        tip:SetOffset(nil, 0)
        tip:Update()
    end)

    Event.Reg(self, "OpenVoiceDisplayModeList", function(btn)
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetVoiceTips)
        local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetVoiceTips, btn, TipsLayoutDir.LEFT_CENTER)
        tip:SetOffset(nil, 0)
        tip:Update()
    end)

    Event.Reg(self, "OpenSprintModeList", function(btn)
        local tBtnInfoList = {}
        local tCellInfo = {
            GameSettingType.SprintMode.Classic,
            GameSettingType.SprintMode.Simple,
            GameSettingType.SprintMode.Common,
        }
        for _, v in ipairs(tCellInfo) do
            local tInfo = { szName = v.szDec, func = function()
                APIHelper.SetSprintMode(v, true)
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetSettingsMultipleChoicePop)
            end, fnSelected = function()
                local tSprintModeSetting = APIHelper.GetSprintMode()
                if not tSprintModeSetting then
                    return false
                end
                return v.szDec == tSprintModeSetting.szDec
            end }
            table.insert(tBtnInfoList, tInfo)
        end

        -- local tCursor = GetCursorPoint()
        -- local tip, script = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetSettingsMultipleChoicePop, tCursor.x, tCursor.y, tBtnInfoList)
        local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSettingsMultipleChoicePop, btn, TipsLayoutDir.LEFT_CENTER, tBtnInfoList)
        script:UpdateSingleChoice(tBtnInfoList)
        --tip:SetSize(UIHelper.GetContentSize(script.LayoutMultipleChoice))
        tip:SetOffset(nil, 0)
        tip:Update()
    end)

    Event.Reg(self, "ON_STARTMODIFY_OPERATIONBTN", function(bOpen, nType)   --编辑模式
        self.bInModifyState = bOpen
        self.tbRedPointNode = {}
       self:UpdateQuickInfo()
       Event.Dispatch("ON_QUICKMENU_SCROLLVIEW_DOLAYOUT")
        if nType then
            self.nMapType = nType
        else
            self:GetMapType()
        end
        for i, v in ipairs(self.tCellScript) do
            self:UpdateQuickCell(v.tScript, v.tCellInfo, v.tLockCfg)
        end
    end)

end

function UIQuickOperationLayout:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIQuickOperationLayout:UpdateQuickInfo()
    self.tCellScript = {}
    UIHelper.RemoveAllChildren(self.WidgetQuickOperationLayout)
    local tbQuickMenu = {}
    for i, v in pairs(UIQuickMenuTab) do
        if v.bIsDisplay and v.nGroupID == self.nGroupID then
            --- 一些通用的显示规则，如等级、成就、任务等
            local bShouldShowByCommonOpenCfg = self:IsOpen(v)
            --- 一些与特定模块强绑定的特殊判断条件，根据 nID/nActionID 等信息来特殊判定
            local bShouldShowByCustomRule = self:ShouldShowMenuByCustomRule(v)

            if bShouldShowByCommonOpenCfg and bShouldShowByCustomRule then
                v.bSetClose = v.bHavaCloseState and self:IsOpenState(v)
                v.bMetexState = v.bHavaMutexState and self:IsOpenState(v)
                table.insert(tbQuickMenu, v)
            end
        end
    end
    table.sort(tbQuickMenu, function(left, right)
        return left.nGroupIndex < right.nGroupIndex
    end)
    for k, v in ipairs(tbQuickMenu) do
        local tScript = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationBtn, self.WidgetQuickOperationLayout)
        assert(tScript)
        local tLockCfg = v.nSystemOpenID > 0 and SystemOpen.GetSystemOpenCfg(v.nSystemOpenID) or nil
        self:UpdateQuickCell(tScript, v, tLockCfg)
        table.insert(self.tCellScript, k, {["tScript"] = tScript, ["tCellInfo"] = v, ["tLockCfg"] = tLockCfg})
    end
end

function UIQuickOperationLayout:IsOpenState(v)
    local bOpen
    if v.nActionID == ACTION_ID.TreasureHunting then
        local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
        bOpen = scriptView:HasWidgetItem(TraceInfoType.Compass)
    elseif v.nActionID == ACTION_ID.BaiLei then
        bOpen = Player_IsBuffExist(ChallengeData.LEI_TAI_BUFF_ID)
    elseif v.nActionID == ACTION_ID.OpenCloseCamp then
        bOpen = g_pClientPlayer.bCampFlag
    elseif v.nID == CUSTOM_RULE_MENU_ID.StartEndWorldMark then
        bOpen = TeamData.GetWorldMarkOpen()
    elseif v.nActionID == ACTION_ID.PetAction then
        local tPet = g_pClientPlayer.GetFellowPet()
        if tPet then
            local hPetIndex = GetFellowPetIndexByNpcTemplateID(tPet.dwTemplateID)
            if hPetIndex and hPetIndex ~= 0 then
                bOpen = true
            end
        end
    elseif v.nID == CUSTOM_RULE_MENU_ID.DamageStatistic then
        bOpen = Storage.HurtStatisticSettings["IsStatisticOpen"] or false
    elseif v.nID == CUSTOM_RULE_MENU_ID.FocusList then
        bOpen = JX_TargetList.IsShow()
    elseif v.nID == CUSTOM_RULE_MENU_ID.WhoSeeMe then
        bOpen = Storage.HurtStatisticSettings["IsSeeMeOpen"] or false
    elseif v.nID == CUSTOM_RULE_MENU_ID.HideNpc then
        bOpen = APIHelper.NpcDisplayCheck()
    elseif v.nID == CUSTOM_RULE_MENU_ID.ToggleRun then
        bOpen = g_pClientPlayer.bWalk
    elseif v.nID == CUSTOM_RULE_MENU_ID.CampUniform then
        bOpen = QualityMgr.IsCampUniform()
    -- elseif v.nID == CUSTOM_RULE_MENU_ID.QingGongMode then
    --     bOpen = GetGameSetting(SettingCategory.Operate, OPERATE.SPRINT,"轻功模式").szDec == GameSettingType.SprintMode.Classic.szDec
    elseif v.nID == CUSTOM_RULE_MENU_ID.HidePetAction then
        bOpen = not Storage.QuickPetAction.bPetShieldAction
    elseif v.nID == CUSTOM_RULE_MENU_ID.HidePartnerAction then
        bOpen = not Storage.QuickPetAction.bPartnerShieldAction
    end
    return bOpen
end

function UIQuickOperationLayout:UpdateActionInfo()
    UIHelper.RemoveAllChildren(self.WidgetQuickOperationLayout)
    for i, _ in ipairs(self.tAction) do
        local tScript = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationBtn, self.WidgetQuickOperationLayout)
        assert(tScript)
        self:UpdateActionCell(tScript, i)
    end
    UIHelper.LayoutDoLayout(self.WidgetQuickOperationLayout)
end

function UIQuickOperationLayout:UpdateQuickCell(tScritp, tCell, tLockCfg)
    UIHelper.BindUIEvent(tScritp.BtnQuickOperation, EventType.OnClick, function()
        if tLockCfg and not SystemOpen.IsSystemOpen(tLockCfg.nID, true) then
			return
		end

        if self.bInModifyState then
            if tCell.nLeftBtnID > 0 then    --可编辑
                if table.contain_value(Storage.CustomBtn.tbBtnDataList[self.nMapType], tCell.nLeftBtnID) then   --已勾选点击
                    table.remove_value(Storage.CustomBtn.tbBtnDataList[self.nMapType], tCell.nLeftBtnID)
                    Storage.CustomBtn.Dirty()
                    UIHelper.SetVisible(tScritp.ImgChooseBg, false)
                    Event.Dispatch(EventType.OnUpdateMainCityLeftBottom, self.nMapType)
                else    --未勾选点击
                    if table.get_len(Storage.CustomBtn.tbBtnDataList[self.nMapType]) >= 3 then
                        TipsHelper.ShowNormalTip("超过上限")
                    else
                        table.insert(Storage.CustomBtn.tbBtnDataList[self.nMapType], tCell.nLeftBtnID)
                        Storage.CustomBtn.Dirty()
                        UIHelper.SetVisible(tScritp.ImgChooseBg, true)
                        Event.Dispatch(EventType.OnUpdateMainCityLeftBottom, self.nMapType)
                    end
                end
            end
            return
        end

        if not table.is_empty(tCell.tbCheckFunc) then
            for k, szCondition in ipairs(tCell.tbCheckFunc) do
                if not string.is_nil(szCondition) then
                    if not string.execute(szCondition) then
                        return
                    end
                end
            end
        end

        if tCell.nActionID == ACTION_ID.OpenPanel then
            --1是界面
            self:PanelAction(tCell.szAction)
        elseif tCell.nActionID == ACTION_ID.CastSkill then
            --2是技能
            local nSkillID = tonumber(tCell.szAction)
            local skillLevel = g_pClientPlayer.GetSkillLevel(nSkillID)
            if tCell.nID ~= CUSTOM_RULE_MENU_ID.LassoHorse or skillLevel > 0 then
                SkillData.CastSkill(PlayerData.GetClientPlayer(), nSkillID, nil, 1)
            elseif tCell.nID == CUSTOM_RULE_MENU_ID.LassoHorse then
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.LEARN_SKILL_BEFORE_LASSO)
                Event.Dispatch("EVENT_LINK_NOTIFY", "SourceShop/1/394/5/17098")--打开套马索商店
                if TeachEvent.CheckCondition(24) then
                    TeachEvent.TeachStart(24)
                end
            end

        elseif tCell.nActionID == ACTION_ID.BaiLei then
            --摆擂
            if tCell.bSetClose or tCell.bMetexState then
                if Player_IsBuffExist(ChallengeData.PK_BUFF_ID) then
                    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.CAN_NOT_RETRACT)
                else
                    RemoteCallToServer("On_PK_PackUp")
                end
            else
                local player = GetClientPlayer()
                local nCDLeft = player.GetCDLeft(ChallengeData.BAI_LEI_ID)
                if nCDLeft > 0 then
                    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.PK_CD_MSG)
                else
                    RemoteCallToServer("On_PK_TryBaiTan")
                end
            end
        elseif tCell.nActionID == ACTION_ID.OpenCloseCamp then
            APIHelper.OpenCloseCamp()
        elseif tCell.nActionID == ACTION_ID.TreasureHunting then
            --寻宝需要判断地图
            self:UpdateTogCompass(tCell)

        elseif tCell.nActionID == ACTION_ID.DispatchEvent then
            --- note: 触发特定事件，在其他地方（如Global）去监听并实现特定逻辑即可
            local szEvent = tCell.szAction
            Event.Dispatch(szEvent, tScritp.BtnQuickOperation)
        elseif tCell.nActionID == ACTION_ID.LoadString then
            string.execute(tCell.szAction)
        elseif tCell.nActionID == ACTION_ID.PetAction then
            if self:IsOpenState(tCell) and tCell.bMetexState then
                RemoteCallToServer("On_FellowPet_Dissolution")
                JiangHuData.bOpenPet = false
                --UIHelper.SetString(tScritp.LabelName, tCell.szTitle)
            else
                tCell.bSetClose = true
                tCell.bMetexState = true
                UIMgr.Open(VIEW_ID.PanelQuickOperationBagNormal, true)
            end
        elseif tCell.nActionID == ACTION_ID.QuickPetAction then
            Storage.QuickPetAction.bPetShieldAction = not Storage.QuickPetAction.bPetShieldAction
            Storage.QuickPetAction.Dirty()
        elseif tCell.nActionID == ACTION_ID.QuickPartnerAction then
            Storage.QuickPetAction.bPartnerShieldAction = not Storage.QuickPetAction.bPartnerShieldAction
            Storage.QuickPetAction.Dirty()
        end

        if tCell.bCloseOnClick then
            UIMgr.Close(VIEW_ID.PanelQuickOperation)
        end

        if tCell.bHavaCloseState then
            tCell.bSetClose = not tCell.bSetClose
            UIHelper.SetVisible(tScritp.ImgClose, not tCell.bSetClose)
            UIHelper.SetVisible(tScritp.ImgOpenLight, tCell.bSetClose)
        end

        if tCell.bHavaMutexState then
            tCell.bMetexState = not tCell.bMetexState
            if tCell.bMetexState then
                UIHelper.SetString(tScritp.LabelName, tCell.szMutexTitle)
                UIHelper.SetSpriteFrame(tScritp.ImgIcon, tCell.szsMutexIcon)
            else
                UIHelper.SetString(tScritp.LabelName, tCell.szTitle)
                UIHelper.SetSpriteFrame(tScritp.ImgIcon, tCell.szIcon)
            end
        end

        if not string.is_nil(tCell.szActionEvent) then
            Event.Dispatch(tCell.szActionEvent, tScritp.ImgIcon, tScritp.LabelName)
        end
    end)

    --如果有技能，判断一下cd情况
    if tCell.nActionID == ACTION_ID.CastSkill and not self.bInModifyState then
        self:UpdateSkillCoolDown(tScritp, tCell.szAction)
    end

    -- label
    if tCell.bMetexState  then
        UIHelper.SetString(tScritp.LabelName, tCell.szMutexTitle)
    else
        UIHelper.SetString(tScritp.LabelName, tCell.szTitle)
    end


    -- icon
    if tCell.bMetexState  then
        UIHelper.SetSpriteFrame(tScritp.ImgIcon, tCell.szsMutexIcon)
    else
        UIHelper.SetSpriteFrame(tScritp.ImgIcon, tCell.szIcon)
    end

    if not string.is_nil(tCell.szActionEvent) then
        Event.Dispatch(tCell.szActionEvent, tScritp.ImgIcon, tScritp.LabelName)
    end

    if tCell.bHavaCloseState then
        UIHelper.SetVisible(tScritp.ImgClose, not tCell.bSetClose)
        UIHelper.SetVisible(tScritp.ImgOpenLight, tCell.bSetClose)
    end

    --编辑模式
    if table.contain_value(Storage.CustomBtn.tbBtnDataList[self.nMapType], tCell.nLeftBtnID) then
        UIHelper.SetVisible(tScritp.ImgChooseBg, self.bInModifyState)
    else
        UIHelper.SetVisible(tScritp.ImgChooseBg, false)
    end

    UIHelper.SetVisible(tScritp.ImgNoSetting, self.bInModifyState and tCell.nLeftBtnID == 0)



    if tCell.nID == CUSTOM_RULE_MENU_ID.HidePartnerMorph then
        -- 隐藏共鸣功能使用单独的按钮实现，也显示下X的图标
        UIHelper.SetVisible(tScritp.ImgClose, true)
    end

    if tCell.nID == CUSTOM_RULE_MENU_ID.QingGongMode then
        -- 轻功模式改变，刷新
        Event.Reg(tScritp, "OnQingGongModeChanged", function() self:UpdateQuickCell(tScritp, tCell, tLockCfg) end)
    end

    -- 红点
    if tCell.tbRedPoint and not table.is_empty(tCell.tbRedPoint) then
        RedpointMgr.RegisterRedpoint(tScritp.ImgRedPoint, nil, tCell.tbRedPoint)
        if not self.tbRedPointNode then
            self.tbRedPointNode = {}
        end
        table.insert(self.tbRedPointNode, tScritp.ImgRedPoint)
    end

    --locked
    if tLockCfg then
        local bIsSystemOpen = SystemOpen.IsSystemOpen(tLockCfg.nID)
        local szTitle = SystemOpen.GetSystemOpenTitle(tLockCfg.nID)
        UIHelper.SetVisible(tScritp.Locked, not bIsSystemOpen)
        if UIHelper.GetVisible(tScritp.Locked) then
            UIHelper.SetString(tScritp.LabelLevel, szTitle)
        end

        -- 未开放就监听消息
        Event.Reg(tScritp, "NEW_ACHIEVEMENT")
        Event.Reg(tScritp, "PLAYER_LEVEL_UP")
        Event.Reg(tScritp, "QUEST_FINISHED")
		if not bIsSystemOpen then
			Event.Reg(tScritp, "NEW_ACHIEVEMENT", function() self:UpdateQuickCell(tScritp, tCell, tLockCfg) end)
			Event.Reg(tScritp, "PLAYER_LEVEL_UP", function() self:UpdateQuickCell(tScritp, tCell, tLockCfg) end)
			Event.Reg(tScritp, "QUEST_FINISHED", function() self:UpdateQuickCell(tScritp, tCell, tLockCfg) end)
		end
    else
        UIHelper.SetVisible(tScritp.Locked, false)
    end
end

function UIQuickOperationLayout:PanelAction(szAction)
    local nViewID = VIEW_ID[szAction]
    if nViewID then
        UIMgr.Open(nViewID)
    end
end

function UIQuickOperationLayout:SkillAction(nQuickOpenID)
end

function UIQuickOperationLayout:IsOpen(tbCfg)
    local bResult = false

    if tbCfg then
        local nOpenType = tbCfg.nOpenType
        if nOpenType == 1 then
            local nLevel = g_pClientPlayer and g_pClientPlayer.nLevel or 1
            bResult = nLevel >= tonumber(tbCfg.szOpenParam)
        elseif nOpenType == 2 then
            local dwActivityID = tonumber(tbCfg.szOpenParam)
            local bOn = ActivityData.IsActivityOn(dwActivityID) or UI_IsActivityOn(dwActivityID)
            bResult = bOn or false
        else -- nOpenType == 0
            bResult = true
        end
    end

    return bResult
end

function UIQuickOperationLayout:ShouldShowMenuByCustomRule(tQuickMenu)
    local nID = tQuickMenu.nID
    local nActionID = tQuickMenu.nActionID

    local bShow = true

    if nID == CUSTOM_RULE_MENU_ID.SummonPartner then
        --- 侠客召请永远显示
        return true
    elseif nID == CUSTOM_RULE_MENU_ID.RecallPartner then
        --- 侠客召回整合到召请页面中了，不需要单独显示了
        return false
    elseif nID == CUSTOM_RULE_MENU_ID.ShowPartnerMorph then
        bShow = not PartnerData.bShowMorphInMainCity
    elseif nID == CUSTOM_RULE_MENU_ID.HidePartnerMorph then
        bShow = PartnerData.bShowMorphInMainCity
    elseif nID == CUSTOM_RULE_MENU_ID.PartnerFollow
            or nID == CUSTOM_RULE_MENU_ID.PartnerAttack
            or nID == CUSTOM_RULE_MENU_ID.PartnerStop
            or nID == CUSTOM_RULE_MENU_ID.PartnerTankAttack then
        local tSummonedList = PartnerData.GetSummonedList()

        -- 只有召请侠客后，才显示侠客跟随、侠客攻击、侠客停留按钮出来
        bShow = tSummonedList and #tSummonedList > 0 or self.bInModifyState
    elseif nID == CUSTOM_RULE_MENU_ID.StartEndWorldMark or nID == CUSTOM_RULE_MENU_ID.ManageWorldMark then
        bShow = TeamData.IsTeamLeader() and DungeonData.IsInDungeon()
    elseif nID == CUSTOM_RULE_MENU_ID.TeamVoice then
        bShow = TeamData.IsPlayerInTeam()
    elseif nID == CUSTOM_RULE_MENU_ID.AutoTeamMark then
        bShow = TeamData.IsPlayerInTeam() and not TeamMarkData.IsAddonBanMap()
    elseif nID == CUSTOM_RULE_MENU_ID.WanLingReviveSkill then
        local nSkillID = tonumber(tQuickMenu.szAction)
        local skillLevel = g_pClientPlayer.GetSkillLevel(nSkillID)

        bShow = skillLevel > 0
    elseif nID == CUSTOM_RULE_MENU_ID.ResetSkillAndJoyStick then
        bShow = Platform.IsMobile()
    end

    return bShow
end

function UIQuickOperationLayout:UpdateTogCompass(tCell)
    if not tCell.bSetClose then
        local scene = GetClientScene()
        local dwCurrentMapID = scene.dwMapID
        local bOutScene = not Table_DoesMapHaveTreasure(dwCurrentMapID)
        if bOutScene then
            -- OutputMessage("MSG_SYS", Craft_GetCantOpenCompassInSceneMsg())
            TipsHelper.ShowNormalTip("当前场景不能感应到宝藏点")
        else
            Event.Dispatch(EventType.OnTogCompass, true)
            RemoteCallToServer("OnHoroSysDataRequest")
        end
    else
        Event.Dispatch(EventType.OnTogCompass, false)
    end
end

function UIQuickOperationLayout:UpdateActionCell(tScript, i)
    UIHelper.BindUIEvent(tScript.BtnQuickOperation, EventType.OnClick, function()
        --点击
    end)
    -- label
    UIHelper.SetString(tScript.LabelName, UIHelper.GBKToUTF8(self.tAction[i].szCommand))
    -- icon
    UIHelper.SetItemIconByIconID(tScript.ImgIcon, self.tAction[i].nIconID)
end

function UIQuickOperationLayout:UpdateSkillCoolDown(tScritp, nSkillID)
    local _, nLeft, nTotal = SkillData.GetSkillCDProcess(g_pClientPlayer, nSkillID)
    nLeft = nLeft or 0
    nTotal = nTotal or 1
    nLeft = math.ceil(nLeft / GLOBAL.GAME_FPS)
    nTotal = math.ceil(nTotal / GLOBAL.GAME_FPS)
    if nLeft ~= 0 then
        tScritp.nCDTimer = tScritp.nCDTimer or Timer.AddCycle(self, 1, function()
            self:UpdateSkillCoolDown(tScritp, nSkillID)
        end)
        UIHelper.SetString(tScritp.CdLabel, nLeft)
        UIHelper.SetProgressBarPercent(tScritp.SliderSkillCd, nLeft * 100 / nTotal)
    else
        if tScritp.nCDTimer then
            Timer.DelTimer(self, tScritp.nCDTimer)
            tScritp.nCDTimer = nil
        end
    end
    UIHelper.SetVisible(tScritp.SliderSkillCd, nLeft ~= 0)
    UIHelper.SetVisible(tScritp.CdLabel, nLeft ~= 0)
end

function UIQuickOperationLayout:SetCustomUpdateInfo(bCustomUpdate)
    self.bCustomUpdate = bCustomUpdate
end

function UIQuickOperationLayout:GetMapType()
    self.nMapType = clone(Storage.CustomBtn.nCurType) or MAP_TYPE.COMMON
end

return UIQuickOperationLayout