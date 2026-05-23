--**********************************************************************************
-- 脚本名称: WidgetNormalSkill
-- 创建时间: 2022年11月8日
-- 功能概述: 战斗技能槽位
--**********************************************************************************
local Timer = Timer
local GetTickCount = GetTickCount
local nTryCastSkillInterval = 100 -- 0.1秒
local AUTO_LONG_PRESS_TIME = 3000

---@class UIWidgetNormalSkill
---@field skillBtn
---@field cdLabel
---@field imgSkillIcon
local UIWidgetNormalSkill = class("UIWidgetNormalSkill")

local bDecimalPoint = true
local kWarningBox = Const.kWarningBox
local kWarningBoxMinDuration = 0.2              -- 警告框最少持续时间
local kHeightOffset = 0.05 / Const.kMetreHeight -- 警告框特效离地高端偏移，避免插入地下

local tSlotIDFuncName = {
    [1] = "心决",
    [2] = "秘技1",
    [3] = "秘技2",
    [4] = "秘技3",
    [5] = "秘技4",
    [10] = "绝学",
}

local tSkillID2FightIndex = {
    [UI_SKILL_DASH_ID] = 18,
    [UI_SKILL_FUYAO_ID] = 24,
    [UI_SKILL_JUMP_ID] = 17,
}

local nSpecialSprintShortcutSlot = 22

local tDXSlotID2FunctionName = {
    [26] = DX_SKILL_SHORTCUT_EVENT .. 26,
    [27] = DX_SKILL_SHORTCUT_EVENT .. 27,
    [28] = DX_SKILL_SHORTCUT_EVENT .. 28,
    [29] = DX_SKILL_SHORTCUT_EVENT .. 29,
}

local tKungFuID2ReviveIcon = {
    [100409] = 100463, -- 奶秀
    [100411] = 101971, -- 奶花
    [100655] = 101978, -- 奶毒
    [101125] = 102198, -- 奶歌
    [101374] = 102199, -- 奶药
}

local tKungFuID2ReviveCDID = {
    [100409] = 10291, -- 奶秀
    [101125] = 10510, -- 奶歌
}

local SpecialDXSkillData = SpecialDXSkillData

local function GetUpSkillEffect(dwSkillID)
    local player = GetClientPlayer()
    if not player then
        return
    end

    local tSkillInfo
    local nLevel = player.GetSkillLevel(dwSkillID)
    local tRecipeKey = player.GetSkillRecipeKey(dwSkillID, nLevel)
    if player.dwID == GetControlPlayerID() then
        tSkillInfo = GetSkillInfoByProxy(tRecipeKey)
    else
        tSkillInfo = GetSkillInfo(tRecipeKey)
    end
    local nMaxRadius = 0
    if tSkillInfo then
        nMaxRadius = tSkillInfo.MaxRadius
    end

    local tLine = Table_GetUpSkillEffect(dwSkillID, nMaxRadius)
    if not tLine then
        return
    end

    local dwLevel = player.GetSkillLevel(tLine.dwConditionSkill)
    local bSkillRecipeActive = player.IsSkillRecipeActive(tLine.dwMiJiID, 1)
    if dwLevel > 0 and bSkillRecipeActive then
        return tLine.dwQiXueAndMiJiEffectID
    elseif dwLevel > 0 then
        return tLine.dwReplaceEffectID
    elseif bSkillRecipeActive then
        return tLine.dwMiJiEffectID
    end
    return tLine.dwEffectID, tLine.bIsShowSFX
end

local function GetDistance(tNpc, tTarget)
    if tNpc and tTarget then
        local targetPos = {}
        targetPos.x, targetPos.y, targetPos.z = tNpc.nX / 64 or 0, tNpc.nY / 64 or 0, tNpc.nZ / 512 or 0
        local selfPos = {}
        selfPos.x, selfPos.y, selfPos.z = tTarget.nX / 64 or 0, tTarget.nY / 64 or 0, tTarget.nZ / 512 or 0

        local distance = math.sqrt((targetPos.x - selfPos.x) ^ 2 + (targetPos.y - selfPos.y) ^ 2 + (targetPos.z - selfPos.z) ^ 2)
        distance = math.ceil(distance)
        return distance
    end
end

local function IsChannelSkill(nCastType)
    return nCastType == UISkillCastType.Repeat
end

function UIWidgetNormalSkill:OnEnter(nSlotID)
    -- 数据初始化
    self.nSlotID = nSlotID
    self.bInCoolDown = false
    self.nLeftTime = 0
    self.bCanCastSkill = false
    self.bEnterBahuangState = false
    self.nWarningBoxTimer = nil ---@note number 警告框更新定时器
    self.pWarningBoxModel = nil ---@note K3DEngineModel 3d引擎模型
    self.nForceType = g_pClientPlayer and Kungfu_GetPlayerMountType(g_pClientPlayer)
    self.bHaveSkill = true
    self.bIsHD = SkillData.IsUsingHDKungFu()
    self.tDXSlotData = {}

    if not self.bInit then
        self:BindUIEventListener() -- 绑定组件消息
        self.bInit = true
        self.nLastBarIndex = SkillData.GetCurrentDxSkillBarIndex(self.nForceType)
    end

    local keyBoardNode = UIHelper.FindChildByName(UIHelper.GetParent(self._rootNode), "WidgetKeyBoardKey")
    self.keyBoardScript = keyBoardNode and UIHelper.GetBindScript(keyBoardNode) ---@type UIShortcutInteraction

    self:RegEvents()
    self:InitMember()
    self:UpdateSkill()

    self:CheckSwitchSwitchDynamicSkills()
    self:ShowQingGongCombine()

    self.bFirstTime = true
end

function UIWidgetNormalSkill:OnExit()
    --print("--------------------WidgetNormalSkill:onExit--------------------")
    self:HideUpSkillEffect()
    self.funcSwitchDynamicSkills = nil
    self.nSlotID = nil
    self:InitMember()
    Timer.DelAllTimer(self)
end

function UIWidgetNormalSkill:BindUIEventListener()
    UIHelper.BindUIEvent(self.skillBtn, EventType.OnTouchBegan, function(_, x, y)
        self:OnPressDown(x, y)
        return not self.bInCoolDown
    end)

    UIHelper.SetLongPressDelay(self.skillBtn, SHOW_TIP_PRESS_TIME)
    UIHelper.SetLongPressDistThreshold(self.skillBtn, 5)
    UIHelper.BindUIEvent(self.skillBtn, EventType.OnLongPress, function(_)
        if self.skillCombineScript then
            SkillData.ClearSkillCache()
            self.skillCombineScript:OnDragStart()
            self:OnPressUp(true)
            return
        end

        if self.tDXSlotData.nType == DX_ACTIONBAR_TYPE.MACRO or self.bLongPressCastingSkill then
            return -- 宏 或者 长按状态 不显示Tips
        end

        if self.nCurrentSkillID then
            local nSkillLevel = g_pClientPlayer.GetSkillLevel(self.nCurrentSkillID)
            if nSkillLevel == 0 then
                nSkillLevel = self.bEnterDynamicSkills and self.nDynamicSkillLevel or 1
            end

            local szType = Skill_GetOptType(self.nCurrentSkillID, nSkillLevel)
            if (not IsChannelSkill(self.tCurrentSkillConfig.nCastType) or not TipsHelper.IsProgressBarShow()) and szType ~= "hoard"
                    and not self:IsJumpSkill() then
                self:ShowSkillTip()
                self:OnPressUp(true)
            end
        end
    end)

    UIHelper.BindUIEvent(self.skillBtn, EventType.OnTouchMoved, function(_, x, y)
        if self.skillCombineScript then
            self.skillCombineScript:OnJoystickDrag(x, y)
        end

        if self.bInPress and self.lbSkillDirection then
            self.lbSkillDirection:OnJoystickDrag(x, y)
        end

        if self.bSHowSkillCancelCtrl and self.scriptSkillCancelCtrl then
            self.scriptSkillCancelCtrl:Tick(x, y)
        end
    end)

    local fnTouchEnd = function()
        self:OnPressUp()
        if self.skillCombineScript then
            self.skillCombineScript:OnDragEnd()
            return
        end
    end
    UIHelper.BindUIEvent(self.skillBtn, EventType.OnTouchEnded, fnTouchEnd)
    UIHelper.BindUIEvent(self.skillBtn, EventType.OnTouchCanceled, fnTouchEnd)

    UIHelper.SetButtonClickSound(self.skillBtn, "")
end

function UIWidgetNormalSkill:RegEvents()
    Event.Reg(self, "MYSTIQUE_ACTIVE_UPDATE", function(dwSkillID)
        if dwSkillID == self.nCurrentSkillID then
            self:UpdateTag()
        end
    end)

    Event.Reg(self, "ON_UPDATE_TALENT", function()
        Timer.AddFrame(self, 1, function()
            self:CheckSkill() -- 监听武学配置切换事件刷新技能
        end)
    end)

    Event.Reg(self, "UPDATE_TALENT_SET_SLOT_SKILL", function()
        if not self.bIsHD then
            self.nHighlightedSkillID = nil
            self:UpdateSkill()
            self:UpdateTiShiQuan(false)
        end
    end)

    Event.Reg(self, EventType.OnDXSkillSlotChanged, function(nSlotID)
        if self.bIsHD and nSlotID == self.nSlotID then
            self.nHighlightedSkillID = nil
            self:UpdateSkill()
            self:UpdateTiShiQuan(false)
        end
    end)

    Event.Reg(self, EventType.OnDXMacroUpdate, function(nMacroID)
        if self.tDXSlotData.nType == DX_ACTIONBAR_TYPE.MACRO and self.tDXSlotData.data1 == nMacroID then
            self:UpdateSkill()
        end
    end)

    Event.Reg(self, EventType.OnClientPlayerLeave, function()
        self:HideUpSkillEffect()
    end)

    Event.Reg(self, "SYNC_ROLE_DATA_END", function()
        self:UpdateSkill()
    end)

    Event.Reg(self, "SKILL_MOUNT_KUNG_FU", function()
        self.bIsHD = SkillData.IsUsingHDKungFu()
    end)

    Event.Reg(self, "SKILL_UPDATE", function()
        if not self.bIsHD then
            self:UpdateSkill()
        end
    end)

    local fnChangeSkill = function(nOldSkillID, nSkillID)
        if BahuangData.IsInBahuangDynamic() then
            return
        end

        if not self.bEnterDynamicSkills then
            if self.bIsHD then
                if self.nCurrentSkillID == nOldSkillID then
                    self:OnSwitchSkill(nSkillID)
                end
            else
                Timer.DelTimer(self, self.nUpdateSkillIconTimer)
                self.nUpdateSkillIconTimer = Timer.AddFrame(self, 1, function()
                    self:CheckSkill()
                end)
            end
        end
    end
    Event.Reg(self, "ON_SKILL_REPLACE", function(nOldSkillID, nSkillID, arg2)
        fnChangeSkill(nOldSkillID, nSkillID)
    end)

    Event.Reg(self, "CHANGE_SKILL_ICON", function(nOldSkillID, nSkillID, arg2, arg3)
        fnChangeSkill(nOldSkillID, nSkillID)
    end)

    Event.Reg(self, "ON_ACTIONBAR_SKILL_REPLACE", function(nOldSkillID, nSkillID, arg2, arg3)
        fnChangeSkill(nOldSkillID, nSkillID)
    end)

    Event.Reg(self, "RL_LIMITED_CHANGE_SKILL_START", function(bShow, nCharacterID, nOld, nNew)
        if g_pClientPlayer and bShow and g_pClientPlayer.dwID == nCharacterID and self.nCurrentSkillID == nOld then
            self:OnTimeProtectingSwitchSkill(nNew)
            self.bTimeProtectingSwitchSkill = true
            --print("RL_LIMITED_CHANGE_SKILL_START", bShow, nOld, nNew)
        end
    end)

    Event.Reg(self, "RL_LIMITED_CHANGE_SKILL_END", function(bShow, nCharacterID, nOld, nNew)
        if g_pClientPlayer and bShow and g_pClientPlayer.dwID == nCharacterID and self.nCurrentSkillID == nOld then
            self.bTimeProtectingSwitchSkill = false
            self:CheckSkill()
            --print("RL_LIMITED_CHANGE_SKILL_END", bShow, nOld, nNew)
        end
    end)

    Event.Reg(self, "PLAYER_DEATH", function()
        self.bTimeProtectingSwitchSkill = false
    end)

    Event.Reg(self, EventType.OnShortcutUseSkillSelect, function(nSlotId, nPressType, bFromAutoBattle)
        if self.nSlotID == nSlotId then
            if nPressType == 1 then
                if bFromAutoBattle then
                    self:UpdateCanCastState(GetControlPlayer())
                    self:UpdateCD(GetControlPlayer())
                end

                self.bFromAutoBattle = bFromAutoBattle
                self:OnPressDown()
                self.bFromAutoBattle = false
                return not self.bInCoolDown
            elseif nPressType == 2 then
                if self.bInPress and self.lbSkillDirection then
                    self.lbSkillDirection:OnJoystickDrag()
                end
            elseif nPressType == 3 then
                self:OnPressUp()
            elseif nPressType == 4 then
                self:OnPressUp()
            end
        end
    end)

    Event.Reg(self, EventType.OnShortcutSkillQuick, function(nPressType)
        if self.nSlotID == 12 then
            --槽位12和快捷使用道具用同一个快捷键
            if nPressType == 1 then
                self:OnPressDown()
                return not self.bInCoolDown
            elseif nPressType == 2 then
                if self.bInPress and self.lbSkillDirection then
                    self.lbSkillDirection:OnJoystickDrag()
                end
            elseif nPressType == 3 then
                self:OnPressUp()
            elseif nPressType == 4 then
                self:OnPressUp()
            end
        end
    end)

    Event.Reg(self, "DO_SKILL_CHANNEL_PROGRESS_END", function(arg0, arg1)
        local dwSkillID = arg1
        if not self.bIsHD and dwSkillID == self.nCurrentSkillID then
            self:OnPressUp()
            self:StopSkill(self.tCasting)
            self.tCasting = nil
        end
    end)

    Event.Reg(self, "RL_HIGHT_LIGHT_SKILL", function(bShow, nCharacterID, arg0, arg1, arg2)
        if g_pClientPlayer then
            local bCurrent = g_pClientPlayer.dwID == nCharacterID
                    and ((bShow and arg0 == self.nCurrentSkillID) or (not bShow and arg0 == self.nHighlightedSkillID)) and
                    not self.bEnterBahuangState
            if bCurrent then
                --print("RL_HIGHT_LIGHT_SKILL", bShow, nCharacterID, arg0)
                if bShow then
                    self.nHighlightedSkillID = self.nCurrentSkillID
                end
                self:UpdateTiShiQuan(bShow)
            end
        end
    end)

    if self.nSlotID == 1 and not self.bIsHD then
        Event.Reg(self, "SYS_MSG", function(arg0, arg1, arg2, arg3, arg4, arg5)
            if g_pClientPlayer and arg0 == "UI_OME_DEATH_NOTIFY" then
                local nTarType, nTarID = g_pClientPlayer.GetTarget()
                if arg1 and arg2 and arg1 == nTarID and arg2 ~= arg1 then
                    self:UpdateTargetState(nTarType, nTarID)
                end
            end
        end)

        Event.Reg(self, EventType.OnOtherPlayerRevive, function(dwPlayerID)
            if g_pClientPlayer then
                local nTarType, nTarID = g_pClientPlayer.GetTarget()
                if nTarID == dwPlayerID then
                    self:UpdateTargetState(nTarType, nTarID)
                end
            end
        end)

        Event.Reg(self, "PLAYER_REVIVE", function()
            if g_pClientPlayer then
                local nTarType, nTarID = g_pClientPlayer.GetTarget()
                if nTarID == g_pClientPlayer.dwID then
                    self:UpdateTargetState(nTarType, nTarID)
                end
            end
        end)

        Event.Reg(self, "UPDATE_SELECT_TARGET", function()
            if g_pClientPlayer then
                self:UpdateTargetState()
            end
        end)
    end

    Event.Reg(self, EventType.OnEnterBahuangDynamic, function()
        --进入八荒
        self:UpdateBahuangSkill()
        self:UpdateFuncName()
        Event.Dispatch(EventType.OnShortcutInteractionChange)
    end)

    Event.Reg(self, EventType.OnGetSkillList, function()
        --八荒获得技能
        self:UpdateBahuangSkill()
    end)

    Event.Reg(self, EventType.OnExChangeBahuangSkill, function()
        --八荒获得技能
        self:UpdateBahuangSkill()
    end)

    Event.Reg(self, EventType.OnChangeMultiStageSkill, function(nOldSkillID, tbSkillInfo)
        if nOldSkillID == self.nCurrentSkillID then
            local tbInfo = {}
            tbInfo.id = tbSkillInfo.dwSkillID
            tbInfo.level = tbSkillInfo.nSkillLevel
            self:SwitchDynamicSkills(true, tbInfo)
        end
    end)

    Event.Reg(self, EventType.OnLeaveBahuangDynamic, function()
        --退出八荒
        if self.nSlotID > 5 and self.nSlotID ~= 10 then
            return
        end
        if self.bEnterDynamicSkills then
            self:SwitchDynamicSkills(false)
        end
        UIHelper.SetVisible(self.AniAll, true)
        UIHelper.SetVisible(self.ImgSkillBahuangBg, false)
        self.bEnterBahuangState = false
        self:UpdateFuncName()
        Event.Dispatch(EventType.OnShortcutInteractionChange)
    end)

    Event.Reg(self, EventType.OnEnterTreasureBattleFieldDynamic, function()
        if not TreasureBattleFieldSkillData.IsDefaultSkillIndex(self.nSlotID)
                and not TreasureBattleFieldSkillData.IsDynamicSkillIndex(self.nSlotID) then
            return
        end
        self:UpdateTreasureBattleFieldSkill()
        Event.Dispatch(EventType.OnShortcutInteractionChange)
    end)

    Event.Reg(self, EventType.OnLeaveTreasureBattleFieldDynamic, function()
        if not TreasureBattleFieldSkillData.IsDefaultSkillIndex(self.nSlotID)
                and not TreasureBattleFieldSkillData.IsDynamicSkillIndex(self.nSlotID) then
            return
        end
        if self.bEnterDynamicSkills then
            self:SwitchDynamicSkills(false)
        end
        Event.Dispatch(EventType.OnShortcutInteractionChange)
    end)

    Event.Reg(self, EventType.OnUpdateTreasureBattleFieldSkill, function(bSinge, nSlotID)
        if not TreasureBattleFieldSkillData.IsDefaultSkillIndex(self.nSlotID)
                and not TreasureBattleFieldSkillData.IsDynamicSkillIndex(self.nSlotID) then
            return
        end
        if not bSinge or self.nSlotID == nSlotID then
            self:UpdateTreasureBattleFieldSkill()
        end
    end)

    Event.Reg(self, EventType.ON_DYNAMIC_BUTTON_HIGHLIGHT, function(nSkillID, bHighlight)
        if self.nCurrentSkillID == nSkillID then
            self:UpdateTiShiQuan(bHighlight)
        end
    end)

    Event.Reg(self, EventType.ON_DYNAMIC_SKILL_CHANGE, function(nOldSkillID, nSkillIndex)
        if self.bEnterDynamicSkills and self.nCurrentSkillID == nOldSkillID then
            self:SwitchDynamicSkills(true, QTEMgr.GetDynamicSkillData(nSkillIndex))
        end
    end)

    Event.Reg(self, EventType.OnMonsterBookSkillSurfaceNumChanged, function(nSKillID, nNum)
        if self.nCurrentSkillID == nSKillID then
            self:UpdateBaiZhanNum(nNum)
        end
    end)

    Event.Reg(self, EventType.OnWindowsLostFocus, function()
        self:OnPressUp(true)
    end)

    Event.Reg(self, EventType.OnApplicationDidEnterBackground, function()
        self:OnPressUp(true)
    end)

    Event.Reg(self, "DO_SKILL_CHANNEL_PROGRESS", function(nTotalFrame, dwSkillID, dwSkillLevel, dwCasterID)
        local hPlayer = g_pClientPlayer
        if not (hPlayer and nTotalFrame > 0) or (hPlayer.dwID ~= dwCasterID and GetControlPlayer().dwID ~= dwCasterID) then
            return
        end

        if self.tCasting and dwSkillID == self.tCasting.nSkillID then
            self:OnChannelSkillRespond()
        end
    end)

    Event.Reg(self, EventType.OnDxSkillBarIndexChange, function()
        if self.bIsHD then
            local nNewBarIndex = SkillData.GetCurrentDxSkillBarIndex(self.nForceType)
            if self.nLastBarIndex ~= nNewBarIndex then
                self:UpdateSkill()
                self.nLastBarIndex = nNewBarIndex
            end
        end
    end)

    Event.Reg(self, EventType.OnSkillAutoCastDisabled, function()
        self.bAutoPress = false -- 自动连放关闭
    end)

    Event.Reg(self, "FIGHT_HINT", function(arg0)
        if not arg0 and not GameSettingData.GetNewValue(UISettingKey.KeepAutoCastWithoutFight) then
            self.bAutoPress = false
        end
    end)
end

function UIWidgetNormalSkill:UnRegEvents()
    Event.UnRegAll(self)
end

function UIWidgetNormalSkill:InitMember()
    self.nCurrentSkillID = nil
    self.tCurrentSkillConfig = nil
    self.nCastingSkillID = nil
    self.tDXSlotData = {}

    self.bInCoolDown = false
    self.nLeftTime = 0
end

---------------------------------------------------------

function UIWidgetNormalSkill:UpdateTiShiQuan(bShow)
    UIHelper.SetActiveAndCache(self, self.Eff_UI_TiShiQuan, bShow)
    --if bShow then
    --    UIHelper.PlaySFX(self.Eff_UI_TiShiQuan, 1)
    --end
end

function UIWidgetNormalSkill:ShowSkillTip()
    if not g_pClientPlayer or g_pClientPlayer.nLevel < 102 then
        return
    end

    if self.bPetAction then
        if self.tCasting then
            local nSkillID, nSkillLevel = self.tCasting.nSkillID, self.tCasting.nSkillLevel
            SkillData.ShowPetSkillTips(self._rootNode, nSkillID, nSkillLevel)
        end
        return
    end

    if self.tDXSlotData.nType then
        local tTipsSlotData = self.tDXSlotData
        if self.tDXSlotData.nType == DX_ACTIONBAR_TYPE.SKILL then
            tTipsSlotData = {
                nType = DX_ACTIONBAR_TYPE.SKILL,
                data1 = self.nCurrentSkillID -- 兼容技能替换
            }
        end
        SkillData.ShowDxSlotTips(tTipsSlotData, self.skillBtn)
        return
    end

    local tCursor = GetCursorPoint()
    local nSkillLevel = g_pClientPlayer.GetSkillLevel(self.nCurrentSkillID)
    if nSkillLevel then
        nSkillLevel = self.bEnterDynamicSkills and self.nDynamicSkillLevel or 1
    end

    local tips, tipsScriptView = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetSkillInfoTips, tCursor.x,
            tCursor.y, self.nCurrentSkillID, nil, nil, nSkillLevel)
    tipsScriptView:SetBtnVisible(false)
end

function UIWidgetNormalSkill:ShowSkillCancel()
    if self.scriptSkillCancelCtrl then
        self.scriptSkillCancelCtrl:Reset()

        local tCasting = self.tCasting
        if tCasting and tCasting.tSkillConfig.nCastType == UISkillCastType.Normal and
                SkillData.IsUseSkillDirectionCancel() then
            if self.scriptSkillCancelCtrl then
                self.scriptSkillCancelCtrl:Show()
                self.bSHowSkillCancelCtrl = true
            end
        end
    end
end

function UIWidgetNormalSkill:HideSkillCancel()
    if self.scriptSkillCancelCtrl then
        self.scriptSkillCancelCtrl:Hide()
        self.bSHowSkillCancelCtrl = false
    end
end

---------------------------------------------------------

function UIWidgetNormalSkill:IsCastSkillImmediately(pPlayer)
    pPlayer = pPlayer or GetControlPlayer()

    local bCastToMe = IsSkillCastToMe(self.nCurrentSkillID)
    if self.bIsHD and not bCastToMe and SkillData.UsePCSkillReleaseMode() then
        local nTargetID, nTargetType = TargetMgr.GetSelect()
        local tTargetInfo = nTargetType == TARGET.PLAYER and GetPlayer(nTargetID) or GetNpc(nTargetID)
        local nSkillLevel = pPlayer.GetSkillLevel(self.nCurrentSkillID)
        local pSkill = GetPlayerSkill(self.nCurrentSkillID, nSkillLevel, pPlayer.dwID)
        if nTargetID ~= 0 and tTargetInfo and pSkill then
            local distance = GetDistance(pPlayer, tTargetInfo)
            local nMaxSkillDistance = pSkill.nMaxRadius / 64
            if distance and distance <= nMaxSkillDistance then
                return true, tTargetInfo
            end
        end
    end

    return false, nil
end

function UIWidgetNormalSkill:BeginDirectionSkill(nTouchX, nTouchY)
    local tSkill
    local pPlayer = GetControlPlayer()
    local tCasting = self.tCasting
    if not pPlayer then
        return
    end

    local bIsItem = false
    if self.bIsHD then
        bIsItem = self.tDXSlotData.nType == DX_ACTIONBAR_TYPE.ITEM_INFO
        tSkill = bIsItem and GetSkill(tCasting.nSkillID, tCasting.nSkillLevel)
    end

    local fnCastXYZ = function(x, y, z)
        local nSkillID = tCasting.nSkillID
        if IsQiChangSkill(nSkillID) then
            local nTargetID, nTargetType = TargetMgr.GetSelect()
            local bToSelf = IsSkillCastToMe(nSkillID) -- 气场技能特殊处理
            if (nTargetID > 0 or bToSelf) then
                local mask = (nSkillID * (nSkillID % 10 + 1))
                -- print(nSkillID, tCasting.nSkillLevel, bToSelf, mask)
                CastSkill(nSkillID, tCasting.nSkillLevel, bToSelf, mask)
                return
            end
        end

        if not bIsItem then
            SkillData.CastSkillXYZ(pPlayer, tCasting.nSkillID, tCasting.nSkillLevel, x, y, z)
        elseif bIsItem and tSkill then
            local dwTabType = self.tDXSlotData.data1
            local dwIndex = self.tDXSlotData.data2
            local tEquipPos = { EQUIPMENT_INVENTORY.PENDANT, EQUIPMENT_INVENTORY.MELEE_WEAPON, EQUIPMENT_INVENTORY.BIG_SWORD }
            for _, nEquip in ipairs(tEquipPos) do
                local item = ItemData.GetItemByPos(INVENTORY_INDEX.EQUIP, nEquip)
                if item and item.dwTabType == dwTabType and item.dwIndex == dwIndex then
                    UseItem(INVENTORY_INDEX.EQUIP, nEquip, tSkill.nCastMode, x, y, z)
                    break
                end
            end
        end
    end

    local bCastImmediate, tTargetInfo = self:IsCastSkillImmediately(pPlayer)
    if bCastImmediate then
        fnCastXYZ(tTargetInfo.nX, tTargetInfo.nY, tTargetInfo.nZ) -- DX技能在有目标且距离合法时直接释放
        self:HideSkillCancel()
        return
    end

    self.lbSkillDirection:OnPressDown(
            nTouchX, nTouchY, self.nSlotID, tCasting.nSkillID, tCasting.tSkillConfig, tCasting.tTarget, fnCastXYZ,
            function(x, y, z)
                return SkillData.CanCastSkillXYZ(pPlayer, tCasting.nSkillID, tCasting.nSkillLevel, x, y, z, bIsItem)
            end
    )
end

function UIWidgetNormalSkill:CastCommonSkill(tCasting)
    local pPlayer = GetControlPlayer()
    if self.tDXSlotData.nType == DX_ACTIONBAR_TYPE.MACRO then
        if CanUseMacro(self.tDXSlotData.data1) then
            ExcuteMacroByID(self.tDXSlotData.data1)
        end
        return
    end

    if tCasting.tSkillConfig.bJoystick then
        if self.lbSkillDirection then
            self.lbSkillDirection:OnPressUp(self.nSlotID)
        end
    else
        local bValidPosition = true
        if SkillData.IsUseSkillDirectionCancel() and self.scriptSkillCancelCtrl and not self.bLongPressCastingSkill then
            bValidPosition = not self.scriptSkillCancelCtrl:IsDragIn()
        end

        if bValidPosition then
            if self.tDXSlotData.nType == DX_ACTIONBAR_TYPE.ITEM_INFO then
                ItemData.QuickUseItem(self.tDXSlotData.data1, self.tDXSlotData.data2)
                return
            end

            if self.bPetAction then
                local hBox = {}
                hBox.nSkillLevel = tCasting.nSkillLevel
                OnUseSkill(tCasting.nSkillID, (tCasting.nSkillID * (tCasting.nSkillID % 10 + 1)), hBox)
            else
                SkillData.CastSkill(pPlayer, tCasting.nSkillID)
            end
            SkillData.AddLastCast(self.nSlotID, Timer.GetPassTime())
        elseif self.bHorseDynamicSkill then
            SkillData.CastSkill(pPlayer, tCasting.nSkillID)
            SkillData.AddLastCast(self.nSlotID, Timer.GetPassTime())
        end

        if self.bEnterDynamicSkills then
            APIHelper.SetUsePendantAction(3)
        end
    end
end

function UIWidgetNormalSkill:StopCommonSkill(tCasting)
    assert(tCasting.tSkillConfig.nCastType == UISkillCastType.Normal)

    if self.lbSkillDirection then
        self.lbSkillDirection:OnPressUp(self.nSlotID)
    end
end

function UIWidgetNormalSkill:BeginChannelSkill(tCasting, nX, nY)
    local pPlayer = g_pClientPlayer
    local tSkillConfig = tCasting and tCasting.tSkillConfig
    if tSkillConfig and tSkillConfig.bJoystick and self.lbSkillDirection then
        self.lbSkillDirection:SetCastPoint(tCasting.nSkillID, tSkillConfig, tCasting.tTarget)
    else
        SkillData.SetCastPointToTargetPos()
    end
    SkillData.CastSkill(pPlayer, tCasting.nSkillID)

    self.bWaitForChannelRespond = true
    self.nChannelX = nX
    self.nChannelY = nY

    Timer.DelTimer(self, tCasting.nWaitForResponse)
    tCasting.bChannelSkillGuarding = true
    tCasting.nWaitForResponse = Timer.Add(self, 0.4, function()
        tCasting.bChannelSkillGuarding = false

        self.nChannelX = nil
        self.nChannelY = nil
        self.bWaitForChannelRespond = false
    end) -- 等待服务器通道技释放成功回调
end

function UIWidgetNormalSkill:OnChannelSkillRespond()
    local pPlayer = g_pClientPlayer
    local tCasting = self.tCasting
    local tSkillConfig = self.tCasting and self.tCasting.tSkillConfig
    if tCasting and self.bWaitForChannelRespond then
        if tCasting.nWaitForResponse then
            Timer.DelTimer(self, tCasting.nWaitForResponse)
            tCasting.nWaitForResponse = nil
        end

        if self:IsHideWhenCasting() then
            UIHelper.SetVisible(self._rootNode, false)
        end

        if tSkillConfig and tSkillConfig.bJoystick and self.lbSkillDirection then
            self.lbSkillDirection:OnPressDown(self.nChannelX, self.nChannelY, self.nSlotID, tCasting.nSkillID,
                    tSkillConfig, tCasting.tTarget)
        end

        if tSkillConfig.fPressGuardTime > 0 then
            tCasting.bChannelSkillGuarding = true
            local nSecond = tSkillConfig.fPressGuardTime / 1000 * 1024 / (1024 + pPlayer.nCurrentHasteRate)
            Timer.DelTimer(self, tCasting.nChannelSkillTimerID)
            tCasting.nChannelSkillTimerID = Timer.Add(self, nSecond, function()
                tCasting.bChannelSkillGuarding = nil
                tCasting.nChannelSkillTimerID = nil
                -- 保护时间结束, 技能没有按下且当前释放的技能是保护的通道技，则结束该通道技
                if not self.bInPress and tCasting == self.tCasting then
                    self.tCasting = nil
                    self:StopSkill(tCasting, true)
                end

                -- 如果切换后续技能
                if tCasting.nNextSkillID then
                    self:OnSwitchSkill(tCasting.nNextSkillID)
                end
            end)
        end
        if tSkillConfig.nCastType == UISkillCastType.Repeat then
            Timer.DelTimer(self, tCasting.nUpdateTimerID)
            tCasting.nUpdateTimerID = Timer.AddCycle(self, 0.2, function()
                local pos = SkillData.GetCastPoint()
                g_pClientPlayer.SetSubSkillPosition(tCasting.nSkillID, tCasting.nSkillLevel, pos.x, pos.y, pos.z)
            end)
        end

        self.bWaitForChannelRespond = false
    end
end

function UIWidgetNormalSkill:StopChannelSkill(tCasting, bStopSkillToServer)
    if self.lbSkillDirection and tCasting.tSkillConfig.bJoystick then
        self.lbSkillDirection:OnPressUp(self.nSlotID)
    end

    if self:IsHideWhenCasting() then
        UIHelper.SetVisible(self._rootNode, true)
    end

    if tCasting.nWaitForResponse then
        Timer.DelTimer(self, tCasting.nWaitForResponse)
        tCasting.nWaitForResponse = nil
    end

    if tCasting.nChannelSkillTimerID then
        Timer.DelTimer(self, tCasting.nChannelSkillTimerID)
        tCasting.nChannelSkillTimerID = nil
    end

    if tCasting.nUpdateTimerID then
        Timer.DelTimer(self, tCasting.nUpdateTimerID)
        tCasting.nUpdateTimerID = nil
    end

    local pPlayer = g_pClientPlayer
    if pPlayer and bStopSkillToServer then
        pPlayer.StopChannelSkill(tCasting.nSkillID)
    end
end

function UIWidgetNormalSkill:StopSkill(tCasting, bStopSkillToServer)
    local nCastType = nil

    if tCasting and tCasting.tSkillConfig then
        nCastType = tCasting.tSkillConfig.nCastType
    end

    if nCastType == UISkillCastType.Normal then
        self:StopCommonSkill(tCasting)
    elseif IsChannelSkill(nCastType) then
        self:StopChannelSkill(tCasting, bStopSkillToServer)
        --elseif nCastType == UISkillCastType.Target then
        --    self:StopTargetSkill(tCasting)
    end
end

---------------------------------------------------------

function UIWidgetNormalSkill:UpdateSkillNotInDynamic()
    local bInDynamincSkill = self.bEnterDynamicSkills
    if not bInDynamincSkill then
        self:CheckSkill() --防止动态技能中按R切换成普通技能
    end
end

function UIWidgetNormalSkill:UpdateSkill()
    if self.bLockUpdateSkill then
        return --防止某些时候动态技能被冲掉
    end
    self:ResetSkill()

    UIHelper.SetActiveAndCache(self, self.Eff_UIskillRefresh_UIskillChuFa, false)
    UIHelper.SetActiveAndCache(self, self.SliderBigCharge, false)
    UIHelper.SetActiveAndCache(self, self.Eff_BigChongNeng, false)
    UIHelper.SetActiveAndCache(self, self.imgSkillCd, false)

    local pPlayer = g_pClientPlayer
    if not pPlayer then
        return
    end

    self.nCurrentSkillID = nil
    self.tCurrentSkillConfig = nil
    self.bReviveState = false
    self.bTimeProtectingSwitchSkill = false

    ---刷新技能置灰状态
    self._IsSkillIconGreyCache = nil
    if not self:IsUniqueSkillSlot() then
        self:SetSkillGreyAndCache(false)
    end

    if SkillData.GetCacheSlotID() == self.nSlotID then
        SkillData.ClearSkillCache()
    end

    self:CheckSkill(true)                             --查找技能
    self.bHaveSkill = self.nCurrentSkillID ~= nil --技能状态，如果找不到可以显示的，就隐藏
    self:UpdateTargetState()
    self:UpdateVisibility()
end

function UIWidgetNormalSkill:OnUpdate()
    local pPlayer = SpecialDXSkillData.bOpenControlActionBar and GetControlPlayer() or g_pClientPlayer
    if not pPlayer then
        return
    end

    self:UpdateCanCastState(pPlayer)
    self:UpdateCD(pPlayer)
    self:UpdateCacheSlot(pPlayer)
    if self.bIsHD then
        self:UpdateSkillSurfaceNum()
        self:UpdateSkillLightEffect(pPlayer)
    end
    self:PerformAutoCastSkill(pPlayer)
end

function UIWidgetNormalSkill:UpdateCacheSlot(pPlayer)
    if not (SkillData.CacheSlotInfo and SkillData.CacheSlotInfo.StartTime)
            or SkillData.GetCacheSlotID() ~= self.nSlotID or self.bLongPressCastingSkill then
        return
    end

    local nTickCount = GetTickCount()
    local nTime = nTickCount / 1000
    if (self.tCurrentSkillConfig and IsChannelSkill(self.tCurrentSkillConfig.nCastType)) or SkillData.CacheSlotInfo.StartTime + SkillData.SkillCacheTime < nTime then
        SkillData.ClearSkillCache() -- zyx说通道技能不参与技能缓存
        return
    end

    if AutoBattle.IsInAutoBattle() and pPlayer and pPlayer.bFightState then
        return
    end

    if self.tCurrentSkillConfig.nCastType == SkillData.CacheSlotInfo.CastType and not self.bInCoolDown then
        if pPlayer.GetOTActionState() ~= 0 or (self.nLastCacheCastTick and nTickCount - self.nLastCacheCastTick < nTryCastSkillInterval) then
            return -- 玩家正在释放读条技能时不打断读条; 因为有些玩家状态和服务器可能不同步 因此客户端释放缓存槽位后不清空 允许继续尝试释放 给0.1秒缓冲
        end
        self:OnPressDown()
        self:OnPressUp()
        self.nLastCacheCastTick = nTickCount
        --SkillData.ClearSkillCache()
    end
end

function UIWidgetNormalSkill:UpdateTargetState(nTarType, nTarID)
    if self.nSlotID == 1 and g_pClientPlayer then
        local dwKungFuID = g_pClientPlayer.GetActualKungfuMountID()
        local nReviveIconID = tKungFuID2ReviveIcon[dwKungFuID]
        if nReviveIconID then
            if not nTarID then
                nTarType, nTarID = g_pClientPlayer.GetTarget()
            end

            local playerData = Global.GetCharacter(nTarID)
            local bTargetDead = playerData and playerData.nMoveState == MOVE_STATE.ON_DEATH
            if self.bReviveState ~= bTargetDead then
                self:UpdateSkillIconAndName(bTargetDead, nReviveIconID)
                self.bReviveState = bTargetDead
                Event.Dispatch(EventType.OnShortcutInteractionChange)
            end
        end
    end
end

--更新是否可以释放
function UIWidgetNormalSkill:UpdateCanCastState(pPlayer)
    if not self.nCurrentSkillID then
        return
    end

    local bCanCast = false

    if self.tDXSlotData.nType == DX_ACTIONBAR_TYPE.MACRO then
        bCanCast = true
    else
        bCanCast = SkillData.CanCastSkill(pPlayer, self.nCurrentSkillID)
        if self.tDXSlotData.nType == DX_ACTIONBAR_TYPE.ITEM_INFO then
            if self.tDXSlotData.tbItemInfo.nGenre == ITEM_GENRE.EQUIPMENT then
                local bEquipped = ItemData.HasItemInBox(INVENTORY_INDEX.EQUIP, self.tDXSlotData.data1, self.tDXSlotData.data2)
                bCanCast = bEquipped
            end
        end
    end

    self.bCanCastSkill = bCanCast
    if self.bInCoolDown then
        return
    end

    local bGray = (not bCanCast) and (not self.bIsPassiveSkill or self.bArenaTowerSkill) --被动技能不置灰，除非是扬刀大会的被动技能
    self:SetSkillGreyAndCache(bGray)
end

local tShowChargePointIndexList = {
    [1] = { 2 },
    [2] = { 2, 3 },
    [3] = { 1, 2, 3 },
    [4] = { 1, 2, 3, 4 },
    [4] = { 1, 2, 3, 4 },
    [5] = { 1, 2, 3, 4, 5 },
    [6] = { 1, 2, 3, 4, 5, 6 },
}

function UIWidgetNormalSkill:UpdateRechargeCD(bCool, nLeft, nTotal, nCount, nMaxCount, bIsRecharge, bPublicCD)
    if nMaxCount and nMaxCount > 1 then
        if not self.bIsRechargeSkill then
            UIHelper.SetProgressBarPercent(self.imgSkillCd, 100)
        end
        if bIsRecharge then
            self:UpdateChongNeng(nCount)
        else
            self:UpdateTouZhi(nCount)
        end
        self.bIsRechargeSkill = true -- 是否为充能或透支技能
    else
        if self.bIsRechargeSkill ~= false then
            UIHelper.SetActiveAndCache(self, self.imgSkillCd, false)
            UIHelper.SetActiveAndCache(self, self.SliderCharge, false)
            UIHelper.SetActiveAndCache(self, self.Eff_ChongNeng, false)
            UIHelper.SetActiveAndCache(self, self.ImgEnergyBg, false)

            for _, node in ipairs(self.tRechargePoints) do
                UIHelper.SetActiveAndCache(self, node, false)
            end

            self.bIsRechargeSkill = false
        end

        return false
    end

    self.nLastRechargeCount = nCount
    self.bPublicCD = bPublicCD

    if bCool and (nCount <= 0 or bPublicCD) then
        self.bInCoolDown = true
    else
        self.bInCoolDown = false
    end

    if bCool then
        local fPercent = 0 --数字倒计时
        if nTotal > 0 then
            fPercent = nLeft / nTotal
        end

        if self:SetCountDownAndCache(nLeft) then
            UIHelper.SetProgressBarPercent(self.SliderCharge, (1 - fPercent) * 100)
            UIHelper.SetPositionY(self.Eff_ChongNeng, (1 - fPercent) * 100 - 55)
        end
    end

    UIHelper.SetActiveAndCache(self, self.imgSkillCd, nCount == 0)
    if self.bRechargeHasCD ~= bCool then
        self.bRechargeHasCD = bCool
        UIHelper.SetActiveAndCache(self, self.cdLabel, bCool)
        UIHelper.SetActiveAndCache(self, self.SliderCharge, bCool)
        UIHelper.SetActiveAndCache(self, self.Eff_ChongNeng, bCool)
    end

    return true
end

function UIWidgetNormalSkill:UpdateTouZhi(nCount)
    if not self.nLastRechargeCount or nCount ~= self.nLastRechargeCount then
        local tIndexList = tShowChargePointIndexList[nCount]
        UIHelper.SetRotation(self.WidgetSkillChargePont4, nCount % 2 == 0 and 90 or 103.5)
        for index, node in ipairs(self.tRechargePoints) do
            UIHelper.SetActiveAndCache(self, node, table.contain_value(tIndexList, index)) --通过旋转实现透支技能的豆豆展示
        end
    end
end

function UIWidgetNormalSkill:UpdateChongNeng(nCount)
    UIHelper.SetActiveAndCache(self, self.ImgEnergyBg, true)
    if nCount ~= self.nLastRechargeCount then
        UIHelper.SetString(self.LabelEnergy, nCount)
        if self.nLastRechargeCount and nCount > self.nLastRechargeCount and self.Eff_UIskillEnergy then
            self.Eff_UIskillEnergy:Play(0)
        end
    end
end

function UIWidgetNormalSkill:UpdateCD(pPlayer)
    if not self.nCurrentSkillID then
        return
    end

    local bShouldShow = false
    if self.tCurrentSkillConfig and self.tCurrentSkillConfig.nType == UISkillType.Append then
        local bShowSecondSlider, nEndFrame, nTotalFrame = pPlayer.CanUIShowSkill(self.nCurrentSkillID)
        nEndFrame = nEndFrame or 0
        local leftFrame = nEndFrame - Timer.GetLogicFrameCount()
        if leftFrame > 0 then
            bShouldShow = true
            UIHelper.SetProgressBarPercent(self.SliderSkillSecond, (leftFrame / nTotalFrame) * 100)
        end
    end

    local dwExtID = self.bIsHD and Table_GetSkillExtCDID(self.nCurrentSkillID) -- DX附加CD逻辑
    if dwExtID then
        local _, nLeft, nTotal, nCDCount, nMaxCount, bIsRecharge, bPublicCD = SkillData.GetSkillCDProcess(pPlayer, dwExtID)
        if nMaxCount <= 1 then
            if nLeft > 0 and not bPublicCD then
                bShouldShow = true
                UIHelper.SetProgressBarPercent(self.SliderSkillSecond, ((nTotal - nLeft) / nTotal) * 100)
            end
        elseif bIsRecharge then
            self:UpdateChongNeng(nCDCount)
        else
            self:UpdateTouZhi(nCDCount)
        end
    end
    UIHelper.SetActiveAndCache(self, self.SliderSkillSecond, bShouldShow)

    local _, nLeft, nTotal, nCDCount, nMaxCount, bIsRecharge, bPublicCD
    if self.tDXSlotData.nType == DX_ACTIONBAR_TYPE.MACRO then
        nLeft, nTotal = GetMacroCDProgress(self.nCurrentSkillID)
        if nLeft == 0 then
            nTotal = 0
        end
        bPublicCD = false
    elseif self.tDXSlotData.nType == DX_ACTIONBAR_TYPE.ITEM_INFO then
        _, nLeft, nTotal = ItemData.GetItemCDProgressByTab(self.tDXSlotData.data1, self.tDXSlotData.data2)
        if nLeft == 0 then
            nTotal = 0
        end
        bPublicCD = false
    else
        _, nLeft, nTotal, nCDCount, nMaxCount, bIsRecharge, bPublicCD = SkillData.GetSkillCDProcess(pPlayer, self.nCurrentSkillID)
    end

    if self.bReviveState and pPlayer.bFightState then
        local dwKungFuID = pPlayer.GetActualKungfuMountID()
        local nCDID = tKungFuID2ReviveCDID[dwKungFuID]
        if nCDID then
            nLeft, nCDCount = pPlayer.GetCDLeft(nCDID)
            if nLeft > 0 then
                nTotal = pPlayer.GetCDInterval(nCDID) -- 技能处于CD状态才查询总CD时长
            end
        end
    end

    nLeft = nLeft or 0
    nTotal = nTotal or 1

    nLeft = nLeft / GLOBAL.GAME_FPS
    nTotal = nTotal / GLOBAL.GAME_FPS

    local bCool = nLeft > 0 or nTotal > 0

    if self:UpdateRechargeCD(bCool, nLeft, nTotal, nCDCount, nMaxCount, bIsRecharge, bPublicCD) then
        return
    end

    if self:IsUniqueSkillSlot() then
        if self.bEnterDynamicSkills then
            local nPercentage, nMaxPercentage = pPlayer.GetAssistedPower(pPlayer.dwMorphID)
            local bCool = true
            if nMaxPercentage ~= 0 then
                bCool = nPercentage < nMaxPercentage
            end
            self:UpdateUniqueSkillCD(bCool, nPercentage, nMaxPercentage, false, true)
        else
            self:UpdateUniqueSkillCD(bCool, nLeft, nTotal, bPublicCD, false)
        end
        return
    end

    local bCanCastSkill = QTEMgr.CanCastSkill()
    local bShowSFX = (not bCanCastSkill) or (bCanCastSkill and self.nSlotID ~= 1)
    if self.bInCoolDown ~= nil and self.bInCoolDown ~= (bCool) and self.Eff_UIskillRefresh_IndependentCD and not bCool then
        if not bPublicCD and bShowSFX then
            self.Eff_UIskillRefresh_IndependentCD:Play(0)  ---在技能cd结束时播放特效
        end
    end

    self.bInCoolDown = bCool
    self.nLeftTime = nLeft
    self.bPublicCD = bPublicCD

    if bCool then
        local fPercent = 0 --数字倒计时
        if nTotal > 0 then
            fPercent = nLeft / nTotal
        end

        self:SetCountDownAndCache(nLeft)
        UIHelper.SetProgressBarPercent(self.imgSkillCd, fPercent * 100)
    end

    UIHelper.SetActiveAndCache(self, self.cdLabel, bCool and nLeft >= 0.01)
    UIHelper.SetActiveAndCache(self, self.imgSkillCd, bCool and nLeft >= 0.01)
end

function UIWidgetNormalSkill:UpdateUniqueSkillCD(bCool, nLeft, nTotal, bPublicCD, bDynamic)
    if self.bHaveSkill then
        if self.bInCoolDown ~= nil and self.bInCoolDown ~= (bCool) and self.Eff_UIskillRefresh_IndependentCD then
            if not bCool and not bPublicCD then
                self.Eff_UIskillRefresh_IndependentCD:Play(0) ---在技能cd结束时播放特效
            end
        end
        self.bInCoolDown = bCool

        if bCool then
            local fPercent = 0 --数字倒计时
            if nTotal > 0 then
                fPercent = nLeft / nTotal
            end
            if bDynamic then
                fPercent = 1 - fPercent
            end

            self:SetCountDownAndCache(nLeft)
            UIHelper.SetProgressBarPercent(self.SliderBigCharge, (1 - fPercent) * 100)
            UIHelper.SetPositionY(self.Eff_BigChongNeng, (1 - fPercent) * 100 - 55)
        end

        UIHelper.SetActiveAndCache(self, self.cdLabel, bCool and not bDynamic)
        UIHelper.SetActiveAndCache(self, self.imgSkillCd, bCool)
        if bCool and UIHelper.GetProgressBarPercent(self.imgSkillCd) ~= 100 then
            UIHelper.SetProgressBarPercent(self.imgSkillCd, 100) -- 防止cd背景无法正确显示
        end

        local bShowCDAppearance = bCool
        if not bDynamic then
            bShowCDAppearance = bCool and nLeft >= 0.01 and not bPublicCD
        end
        UIHelper.SetActiveAndCache(self, self.SliderBigCharge, bShowCDAppearance)
        UIHelper.SetActiveAndCache(self, self.Eff_BigChongNeng, bShowCDAppearance)
        UIHelper.SetActiveAndCache(self, self.Eff_UIskillRefresh_UIskillChuFa, not bShowCDAppearance)
    end
end

--只有天生养息法用。
function UIWidgetNormalSkill:UpdateBaiZhanNum(nSurfaceNum)
    local nPercent = MonsterBookData.ConvertSurfaceNumToPercent(nSurfaceNum)

    UIHelper.SetActiveAndCache(self, self.SliderCharge, true)
    UIHelper.SetProgressBarPercent(self.SliderCharge, nPercent)
    UIHelper.SetPositionY(self.Eff_ChongNeng, nPercent - 55)
    UIHelper.SetActiveAndCache(self, self.Eff_ChongNeng, true)
end

function UIWidgetNormalSkill:UpdateTag()
    if not self.nCurrentSkillID then
        return
    end
    local nTagType, bActive = SkillData.GetSpecialTag(self.nCurrentSkillID)
    local szPath = SkillTagInfo[nTagType] and SkillTagInfo[nTagType][bActive]
    if szPath then
        UIHelper.SetSpriteFrame(self.ImgQushan, szPath)
    end
    UIHelper.SetVisible(self.ImgQushan, szPath ~= nil)
end

function UIWidgetNormalSkill:UpdateSkillSurfaceNum()
    local nSurfaceNum = SkillData.GetSurfaceNum(self.nCurrentSkillID)
    if nSurfaceNum == 0 then
        nSurfaceNum = nil
        self.nCachedSurfaceNum = nil
    end
    if nSurfaceNum and self.nCachedSurfaceNum ~= nSurfaceNum then
        self.nCachedSurfaceNum = nSurfaceNum
        UIHelper.SetLabel(self.LabelSurfaceNum, nSurfaceNum)
    end
    UIHelper.SetActiveAndCache(self, self.WidgetSurfaceNum, nSurfaceNum ~= nil)
end

-- 指定BUFF存在时技能显示特定特效的需求
function UIWidgetNormalSkill:UpdateSkillLightEffect(pPlayer)
    if self.bEnterBahuangState or self.bEnterDynamicSkills then
        return -- 动态技能状态下直接返回
    end

    local bShow = SkillTipPanel.tActionBarInUse[self.nCurrentSkillID]
    if not bShow and self.bIsHD then
        local tLine = self.nCurrentSkillID and Table_GetSkillEffectBySkill(self.nCurrentSkillID)
        if tLine then
            bShow = not not pPlayer.GetBuff(tLine.dwBuffID, 0)
        end
    end
    UIHelper.SetActiveAndCache(self, self.Eff_UI_TiShiQuan, bShow or self.bAutoPress)
end

---------------------------------------------------------

-- 检查技能是否需要更换
function UIWidgetNormalSkill:CheckSkill(bForceInit)
    if self.bTimeProtectingSwitchSkill or self.bLockUpdateSkill then
        return --防止某些时候动态技能被冲掉
    end
    if not self.bIsHD then
        local nSkillID = UIBattleSkillSlot.GetShowUI_Ver2(self.nSlotID) -- 查找可以显示的技能
        self:OnSwitchSkill(nSkillID)
    end
    if self.bIsHD and bForceInit and self.nSlotID then
        local nSkillID = nil
        self.tDXSlotData = SkillData.GetDxSlotData(self.nSlotID, SkillData.GetCurrentDxSkillBarIndex(self.nForceType))

        if self.tDXSlotData.nType == DX_ACTIONBAR_TYPE.MACRO then
            nSkillID = self.tDXSlotData.data1
            if IsMacroRemoved(nSkillID) then
                nSkillID = nil
            end
        elseif self.tDXSlotData.nType == DX_ACTIONBAR_TYPE.ITEM_INFO then
            local tbItemInfo = ItemData.GetItemInfo(self.tDXSlotData.data1, self.tDXSlotData.data2)
            nSkillID = tbItemInfo and tbItemInfo.dwSkillID
            self.tDXSlotData.tbItemInfo = tbItemInfo
        elseif self.tDXSlotData.nType == DX_ACTIONBAR_TYPE.SKILL then
            nSkillID = self.tDXSlotData.data1
            nSkillID = SkillData.CheckDXSkillReplace(nSkillID)
        end
        self:OnSwitchSkill(nSkillID)
    end
end

function UIWidgetNormalSkill:UpdateSkillIconAndName(bRevive, nReviveIconID)
    if not self.nCurrentSkillID or not self.tCurrentSkillConfig then
        return
    end

    if self.tDXSlotData.nType == DX_ACTIONBAR_TYPE.ITEM_INFO then
        local bResult = UIHelper.SetItemIconByItemInfo(self.imgSkillIcon, self.tDXSlotData.tbItemInfo, nil, true,
                function()
                    UIHelper.UpdateMask(self.MaskSkillIcon)
                end)
        if not bResult then
            UIHelper.ClearTexture(self.imgSkillIcon)
        end
    elseif self.tDXSlotData.nType == DX_ACTIONBAR_TYPE.MACRO then
        local bResult = UIHelper.SetItemIconByIconID(self.imgSkillIcon, GetMacroIcon(self.tDXSlotData.data1), true,
                function()
                    UIHelper.UpdateMask(self.MaskSkillIcon)
                end)
        if not bResult then
            UIHelper.ClearTexture(self.imgSkillIcon)
        end
    else
        if self.nCurrentSkillID > 0 then
            local nSkillID = self.nCurrentSkillID
            local nSkillLevel = g_pClientPlayer.GetSkillLevel(nSkillID)
            if nSkillLevel == 0 then
                nSkillLevel = self.bEnterDynamicSkills and self.nDynamicSkillLevel or 1
            end
            local szImgPath = TabHelper.GetSkillIconPath(nSkillID) or
                    TabHelper.GetSkillIconPathByIDAndLevel(nSkillID, nSkillLevel)
            if nReviveIconID and bRevive then
                szImgPath = Table_GetItemIconInfo(nReviveIconID).FileName
            end

            if szImgPath then
                if not string.find(szImgPath, "Resource/icon/") then
                    szImgPath = "Resource/icon/" .. szImgPath
                end

                UIHelper.SetTexture(self.imgSkillIcon, szImgPath, true, function()
                    UIHelper.UpdateMask(self.MaskSkillIcon)
                end)
            end

            UIHelper.SetVisible(self.ImgSkillChufaBg, self:IsUniqueSkillSlot())
            self:UpdateTag()
        end
    end

    self:UpdateFuncName(bRevive)
end

function UIWidgetNormalSkill:GetDynamicSkillName(nSkillID)
    local szName = ""
    local tbFuncName = UIDynamicSkillInfoTab[nSkillID]
    if tbFuncName then
        szName = UIHelper.LimitUtf8Len(tbFuncName.szFuncName, 4)
    else
        szName = UIHelper.LimitUtf8Len(SkillData.GetSkillName(nSkillID, self.nDynamicSkillLevel), 4)
    end
    return szName
end

function UIWidgetNormalSkill:UpdateFuncName(bRevive)
    local szName = ""
    local nIndex = SkillData.tSlotId2FightIndex[self.nSlotID]
    local bHDKungFu = self.bIsHD
    if bHDKungFu then
        nIndex = SkillData.tDXSlotID2FightIndex[self.nSlotID]
    end
    local bSprint = false

    -- nIndex为空则当前槽位为轻功槽位
    if nIndex == nil and (bHDKungFu and tDXSlotID2FunctionName[self.nSlotID] or VK_SPRINT_SHORTCUT_FUNC_NAME[self.nSlotID]) then
        nIndex = (bHDKungFu and SkillData.tDXSkillID2FightIndex[self.nCurrentSkillID] or (tSkillID2FightIndex[self.nCurrentSkillID] or nSpecialSprintShortcutSlot))
        if self.bEnterDynamicSkills and self.nIndex then
            nIndex = self.nIndex --动态技能快捷键用当前普通技能的
        end
        if self.keyBoardScript then
            self.nIndex = nIndex
            self.keyBoardScript:SetID(nIndex, nil, true)
        end --更新快捷键
        bSprint = true
    end

    if bRevive then
        szName = "复活"
    else
        szName = self.tCurrentSkillConfig and self.tCurrentSkillConfig.szSkillDefinition or ""
        if bHDKungFu and szName == "" then
            if self.tDXSlotData.nType == DX_ACTIONBAR_TYPE.MACRO then
                szName = GetMacroName(self.tDXSlotData.data1)
            elseif self.tDXSlotData.nType == DX_ACTIONBAR_TYPE.ITEM_INFO and self.tDXSlotData.tbItemInfo then
                szName = UIHelper.GBKToUTF8(self.tDXSlotData.tbItemInfo.szName)
            elseif self.tDXSlotData.nType == DX_ACTIONBAR_TYPE.SKILL then
                local nSkillID = self.nCurrentSkillID
                local nSkillLevel = math.max(1, g_pClientPlayer.GetSkillLevel(nSkillID))
                szName = UIHelper.LimitUtf8Len(SkillData.GetSkillName(nSkillID, nSkillLevel), 4)
            end
        end
    end

    if self.bEnterDynamicSkills then
        szName = self:GetDynamicSkillName(self.nCurrentSkillID)
    end

    if BahuangData.IsInBahuangDynamic() and tSlotIDFuncName[self.nSlotID] then
        szName = tSlotIDFuncName[self.nSlotID] --在八荒中，技能默认为心决等
        if self.nSlotID == 6 then
            nIndex = tSkillID2FightIndex[UI_SKILL_DASH_ID]
        end
    end

    if TreasureBattleFieldSkillData.IsInDynamic() then
        if self.nSlotID == 9 then
            nIndex = tSkillID2FightIndex[UI_SKILL_FUYAO_ID]
            if self.keyBoardScript then
                self.keyBoardScript:SetID(nIndex, nil, true)
            end --更新快捷键
        elseif self.nSlotID == 8 then
            nIndex = tSkillID2FightIndex[UI_SKILL_JUMP_ID]
            if self.keyBoardScript then
                self.keyBoardScript:SetID(nIndex, nil, true)
            end--更新快捷键
        end
        if szName == "" then
            szName = self.tCurrentSkillConfig and self.tCurrentSkillConfig.szSkillDefinition or ""
            if szName == "踏云·悟" then
                szName = "跳跃"
            end
        end
    end

    local szFunctionName = bHDKungFu and tDXSlotID2FunctionName[self.nSlotID] or VK_SPRINT_SHORTCUT_FUNC_NAME[self.nSlotID]
    if not self.bHaveSkill then
        szFunctionName = nil --技能不存在时不修改快捷键的szFunctionName
    end
    ShortcutInteractionData.ChangeSkillShortcutInfo(nIndex, szName, szFunctionName)

    if self.keyBoardScript then
        self.keyBoardScript:UpdateInfo()
    end

    --更新手柄键位
    if nIndex == tSkillID2FightIndex[UI_SKILL_DASH_ID] then
        GamepadData.NieYunIndex = self.nSlotID --蹑云
    elseif nIndex == nSpecialSprintShortcutSlot then
        GamepadData.QingGongIndex = self.nSlotID --门派轻功
    end
end

---多段技能切换逻辑
function UIWidgetNormalSkill:OnSwitchSkill(dwSkillID2)
    self.bRechargeHasCD = nil
    self.bIsRechargeSkill = nil
    self.nLastRechargeCount = nil

    local nNextSlotID, nNextSkillID = self.nSlotID, dwSkillID2
    if not nNextSkillID then
        self.bHaveSkill = false
        self.nCurrentSkillID = nil
        self.tCurrentSkillConfig = nil
        self:UpdateFuncName()
        return -- 当前槽位无技能
    end

    self.bHaveSkill = true

    if self.nCurrentSkillID and nNextSkillID == self.nCurrentSkillID then
        return -- 如果找到的技能跟原先的一样或当前无法切换，保持原有的
    end

    -- 如果技能发生切换，但是技能还没结束，则立即结束
    local tCasting = self.tCasting
    if tCasting and tCasting.bChannelSkillGuarding then
        tCasting.nNextSkillID = nNextSkillID
        return -- 处于通道技保护时间，等通道技结束以后再切换
    end

    self.nCurrentSkillID = nNextSkillID
    self.nSkillLevel = GetControlPlayer().GetSkillLevel(nNextSkillID)
    if self.nSkillLevel == 0 then
        self.nSkillLevel = self.bEnterDynamicSkills and self.nDynamicSkillLevel or 1
    end

    -- 如果有技能UI配置，则走UI配置
    -- 如果是动态技能栏技能，则走技能配置适配
    self.tCurrentSkillConfig = TabHelper.GetUISkillMap(nNextSkillID)
    if not self.tCurrentSkillConfig then
        self.tCurrentSkillConfig = SkillData.GetUIDynamicSkillMap(nNextSkillID, self.nSkillLevel)
        if self.tDXSlotData.nType == DX_ACTIONBAR_TYPE.MACRO then
            self.tCurrentSkillConfig.nCastType = UISkillCastType.Down -- 特殊设置宏的释放方式
        end
        if self.tDXSlotData.nType == DX_ACTIONBAR_TYPE.SKILL then
            if self.tCurrentSkillConfig.nCastType ~= UISkillCastType.Down or self.skillCombineScript then
                self.tCurrentSkillConfig.nCastType = UISkillCastType.Normal -- DX技能只有蓄力技能需要持续长按 所以除了Down类型都认为是normal
            end
        end
    end
    assert(self.tCurrentSkillConfig)

    if self.bReviveState then
        return -- 处于复活状态下，忽略技能图标替换
    end

    self:UpdateSkillIconAndName()

    local bInDynamincSkill = self.bEnterDynamicSkills
    if bInDynamincSkill then
        --切换到动态技能，不播放切换技能动画，播放进入技能特效
        UIHelper.PlaySFX(self.Eff_UIskillRefresh_PublicCD)
    else
        UIHelper.PlayAni(self, self.AniAll, "AniSwitchShow", nil)
    end

    --如果技能发生切换，且新技能是通道技能，直接释放
    if tCasting and IsChannelSkill(self.tCurrentSkillConfig.nCastType) and self.bInPress then
        self:StopChannelSkill(tCasting, true) -- 结束旧通道技

        tCasting.nSkillID = nNextSkillID
        tCasting.tSkillConfig = self.tCurrentSkillConfig
        self.tCasting = tCasting
        self:BeginChannelSkill(tCasting)  -- 释放新通道技
    end
end

--- 特殊二段处理，接受事件后在一定时间内维持二段状态不改变
function UIWidgetNormalSkill:OnTimeProtectingSwitchSkill(nNextSkillID)
    self.bRechargeHasCD = nil
    self.bIsRechargeSkill = nil
    self.nLastRechargeCount = nil

    self.bHaveSkill = true

    self.nCurrentSkillID = nNextSkillID
    local nSkillLevel = g_pClientPlayer.GetSkillLevel(nNextSkillID)
    if nSkillLevel == 0 then
        nSkillLevel = self.bEnterDynamicSkills and self.nDynamicSkillLevel or 1
    end

    -- 如果有技能UI配置，则走UI配置

    self.tCurrentSkillConfig = TabHelper.GetUISkillMap(nNextSkillID)
    assert(self.tCurrentSkillConfig)

    self:UpdateSkillIconAndName()

    UIHelper.PlayAni(self, self.AniAll, "AniSwitchShow", nil)
end

--还原技能按键的状态
function UIWidgetNormalSkill:ResetSkill()
    if self.tCasting and not self.bLongPressCastingSkill then
        local tCasting = self.tCasting
        self.tCasting = nil
        self:StopSkill(tCasting) -- 非自动连放状态下清除
    end

    self:HideUpSkillEffect()
    self:InitMember()
end

---------------------------------------------------------

-- 技能键按下
function UIWidgetNormalSkill:OnPressDown(nX, nY)
    local pPlayer = GetControlPlayer()
    local nSkillID = self.nCurrentSkillID
    local tSkillConfig = self.tCurrentSkillConfig

    if self.bIsPassiveSkill then
        TipsHelper.ShowNormalTip(g_tStrings.STR_PASSIVESKILL_TIP)
        return
    end

    if self.bFromAutoBattle ~= true and self.bInCoolDown
            and not self.bAutoPress and (self.nLeftTime and self.nLeftTime <= SkillData.SkillCacheTime) then
        SkillData.AddSkillCache(self.nSlotID, self.tCurrentSkillConfig.nCastType, Timer.GetPassTime()) -- 当剩余冷却时间不大于缓存时间 且不在自动连放状态 时缓存技能
    end

    self.bAutoPress = false -- 清除自动连放
    if not pPlayer or self.bInPress or (self.tCasting and self.tCasting.bChannelSkillGuarding) then
        return -- 已经被按住或处于通道技保护时间
    end

    if not self:IsJumpSkill() and not self:IsFuYaoSkill()
            and pPlayer.dwSchoolID ~= SCHOOL_TYPE.TIAN_CE and pPlayer.bOnHorse and not self.bEnterDynamicSkills then
        RideHorse() -- 非天策职业若在马上的情况下帮他下马 26.3.16 马上可以使用扶摇
        self:UpdateCanCastState(pPlayer)
        return
    end

    if self:IsJumpSkill() or (self.tDXSlotData.nType ~= DX_ACTIONBAR_TYPE.MACRO and TargetMgr.TrySelectOneTarget(self.nCurrentSkillID)) then
        self:UpdateCanCastState(pPlayer) -- 每次释放技能前帮玩家默认选一个目标
    end

    UIHelper.PlayAni(self, self.AniAll, "AnicLick", nil)
    if not self.bCanCastSkill then
        if self.bHaveSkill then
            self:ShowCannotCastTip()
        end
        return -- 无法释放
    end

    if self:IsJumpSkill() then
        return Jump()
    end

    if (pPlayer.GetOTActionState() == CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE and IsChannelSkill(tSkillConfig.nCastType)) then
        return TipsHelper.ShowImportantBlueTip(g_tStrings.STR_ERROR_IN_OTACTION) -- 持续释放（倒读条）无法打断正在释放的吟唱（正读条）技能，在此处打断释放，避免在当前技能未释放的状态下进入通道技保护时间
    end

    if not tSkillConfig then
        return
    end

    local nSkillLevel = pPlayer.GetSkillLevel(nSkillID)
    if nSkillLevel == 0 then
        nSkillLevel = self.bEnterDynamicSkills and self.nDynamicSkillLevel or 1
    end

    -- 索敌
    local tTarget
    local nNowTime = Timer.GetPassTime()

    local nTargetID, nTargetType = TargetMgr.GetSelect()
    if nTargetID ~= 0 and not tSkillConfig.bForbidSelectTarget then
        local pTarget = Global.GetCharacter(nTargetID)
        if pTarget then
            local nX, nY, nZ = pTarget.GetAbsoluteCoordinate()
            tTarget = { dwID = nTargetID, nType = nTargetType, nX = nX, nY = nY, nZ = nZ }
        end
    end

    -- 记录释放中的技能
    self.tCasting = {
        nSkillID = nSkillID,
        nSkillLevel = nSkillLevel,
        tSkillConfig = tSkillConfig,
        nTime = nNowTime,
        tTarget = tTarget,
    }

    self.nPressStartTime = Timer.GetPassTime()
    self.bInPress = true
    self.nX, self.nY = nX, nY

    if self:StartAutoCastSkill(pPlayer) then
        Event.Dispatch(EventType.OnSkillPressDown)
        return
    end

    if self.bInCoolDown then
        self.tCasting = nil
        return
    end

    Event.Dispatch(EventType.OnSkillPressDown)
    self:CastSkillDown(pPlayer)
end

-- 技能键抬起
function UIWidgetNormalSkill:OnPressUp(bForceCancel)
    if self:IsJumpSkill() then
        EndJump()
        return
    end

    if not self.bInPress then
        return
    end

    bForceCancel = bForceCancel or false
    local tCasting = self.tCasting
    local nDurationTime = Timer.GetPassTime() - self.nPressStartTime
    self.bInPress = false

    if not tCasting then
        return
    end

    self:HideSkillCancel()

    if nDurationTime < kWarningBoxMinDuration then
        Timer.DelTimer(self, self.nWarningBoxTimerID)
        self.nWarningBoxTimerID = Timer.Add(self, kWarningBoxMinDuration - nDurationTime, function()
            self:HideUpSkillEffect()
        end)
    else
        self:HideUpSkillEffect()
    end

    local bHoard = Skill_GetOptType(tCasting.nSkillID, tCasting.nSkillLevel) == "hoard"  --蓄力抬起逻辑不放在CastSkillUp中 因为蓄力技能在抬起时需要释放蓄力结束技能

    if self.bLongPressCastingSkill then
        if not self.bAutoPress then
            self:StopAutoCastSkill() -- 非自动连放状态下需要停止长按连放
        end
    elseif not tCasting.bChannelSkillGuarding and not bHoard then
        if self.lbSkillDirection and bForceCancel then
            self.lbSkillDirection:OnDirectionSkillEnd(self.nSlotID)
        end
        self:CastSkillUp(bForceCancel, GetControlPlayer())
        self.tCasting = nil
    end

    if bHoard and not self.bAutoPress then
        LOG.INFO("----------------szType hoard up----------------------") -- 非自动连放状态下抬起时释放蓄力
        OnUseSkill(tCasting.nSkillID, tCasting.nSkillID * (tCasting.nSkillID % 10 + 1), nil)
        return
    end
end

function UIWidgetNormalSkill:CastSkillDown(pPlayer)
    local tSkillConfig = self.tCurrentSkillConfig
    local nSkillLevel = self.tCasting.nSkillLevel
    local nSkillID = self.tCasting.nSkillID

    if not tSkillConfig then
        return
    end

    if self.scriptSkillCancelCtrl then
        self.scriptSkillCancelCtrl:Reset()
    end

    --蓄力技能逻辑
    local szType = Skill_GetOptType(self.nCurrentSkillID, nSkillLevel)
    if szType == "hoard" and pPlayer.GetOTActionState() ~= CHARACTER_OTACTION_TYPE.ACTION_SKILL_HOARD then
        LOG.INFO("----------------szType hoard----------------------")
        OnUseSkill(nSkillID, nSkillID * (nSkillID % 10 + 1), nil, true)
        self.bCastingHoard = true
        return
    end

    if not self.bLongPressCastingSkill and self.tDXSlotData.nType ~= DX_ACTIONBAR_TYPE.MACRO then
        self:ShowSkillCancel()
    end

    local nCastType = tSkillConfig.nCastType
    if nCastType == UISkillCastType.Down then
        self:CastCommonSkill(self.tCasting)
    elseif IsChannelSkill(nCastType) then
        self:BeginChannelSkill(self.tCasting, self.nX, self.nY)
    elseif nCastType == UISkillCastType.Normal or self.tDXSlotData.nType == DX_ACTIONBAR_TYPE.SKILL then
        if tSkillConfig.bJoystick and self.lbSkillDirection then
            self:BeginDirectionSkill(self.nX, self.nY)
        end
    end

    self:ShowUpSkillEffect()
end

-- 技能键抬起
function UIWidgetNormalSkill:CastSkillUp(bForceCancel, pPlayer)
    local tCasting = self.tCasting
    if not tCasting then
        return -- 当前未释放技能
    end

    local nCastType = tCasting.tSkillConfig.nCastType
    if nCastType == UISkillCastType.Normal and not bForceCancel then
        if self.bCanCastSkill then
            self:CastCommonSkill(self.tCasting)
        else
            self:StopSkill(tCasting, true)  --抬手的时候 不符合释放条件，清掉圆盘
        end
    elseif IsChannelSkill(nCastType) then
        self:StopSkill(tCasting, true)
    end
end

---------------------------------------------------------

function UIWidgetNormalSkill:SetSkillBg(szImagePath)
    if self.ImgSkillBg then
        UIHelper.SetVisible(self.ImgSkillBg, false)
    end
    if self.ImgBaiZhanColor then
        UIHelper.SetVisible(self.ImgBaiZhanColor, true)
        UIHelper.ClearTexture(self.ImgBaiZhanColor)
        UIHelper.SetSpriteFrame(self.ImgBaiZhanColor, szImagePath, true)
    end
end

function UIWidgetNormalSkill:HideSkillBg()
    UIHelper.SetVisible(self.ImgSkillBg, false)
    UIHelper.SetVisible(self.ImgBaiZhanColor, false)
end

function UIWidgetNormalSkill:SetHorseDynamicSkill()
    self.bHorseDynamicSkill = true
end

function UIWidgetNormalSkill:SetLockUpdateSkill(bLock)
    self.bLockUpdateSkill = bLock
end

function UIWidgetNormalSkill:SwitchDynamicSkills(bEnterDynamicSkills, tbDynamicSkillInfo)
    local funcSwitchDynamicSkills = function()
        if bEnterDynamicSkills then
            --正常进入动态技能
            self:SetLockUpdateSkill(true)
            self.bEnterDynamicSkills = true
            self.nDynamicSkillLevel = tbDynamicSkillInfo.level
            self.bArenaTowerSkill = tbDynamicSkillInfo.bArenaTowerSkill
            self.bPetAction = tbDynamicSkillInfo.bPetAction or nil
            self.bIsPassiveSkill = tbDynamicSkillInfo.id and
                    SkillData.IsPassiveSkill(tbDynamicSkillInfo.id, self.nDynamicSkillLevel)

            LOG.INFO("----------SwitchDynamicSkills OnEnter %s %s %s %s-----------", tostring(self.nSlotID),
                    tostring(self.nCurrentSkillID), tostring(tbDynamicSkillInfo.id), tostring(tbDynamicSkillInfo.level))

            self.tDXSlotData = { nType = DX_ACTIONBAR_TYPE.SKILL, data1 = tbDynamicSkillInfo.id }
            self:OnSwitchSkill(tbDynamicSkillInfo.id)

            local szImgBaiZhanBg = tbDynamicSkillInfo.szImgFramePath
            if szImgBaiZhanBg then
                --百战设置背景
                self:SetSkillBg(szImgBaiZhanBg)
            end

            local nSkillSurfaceNum = tbDynamicSkillInfo.nSkillSurfaceNum
            if nSkillSurfaceNum and nSkillSurfaceNum ~= 0 then
                --天生养息法
                self:UpdateBaiZhanNum(nSkillSurfaceNum)
            end

            self:PlayEnterDynamicAnim()
        end

        if (not bEnterDynamicSkills) and self.bEnterDynamicSkills then
            --正常退出动态技能
            -- if self.lbSkillDirection then
            --     self.lbSkillDirection:OnPressUp(self.nSlotID)
            -- end --退出时释放选点动态技能，防止卡在选点状态
            self.bPetAction = nil
            self.bArenaTowerSkill = nil
            self.bEnterDynamicSkills = false
            self.bIsPassiveSkill = false
            self:SetLockUpdateSkill(false)
            self:UpdateSkill()
            LOG.INFO("---------SwitchDynamicSkills OnExit %s------------", tostring(self.nSlotID))
        end
        self:OnPressUp(true)

        if QTEMgr.CanCastSkill() then
            self:SetSkillVisible(true) --动态技能球中的技能直接显示
        end

        self:UpdateTiShiQuan(false)
        -- self:UpdateFuncName()
        self:UpdateImgCost()
    end

    if self.nSlotID then
        funcSwitchDynamicSkills()
    else
        self.funcSwitchDynamicSkills = funcSwitchDynamicSkills --按钮还未初始化(OnEnter还未进入)，等到初始化再执行切换
    end


    -- self.nOriginSkillID = self.nCurrentSkillID
    -- self:OnSwitchSkill(self.nCurrentSkillID, tbDynamicSkillInfo.id)
    -- self.tbDynamicSkillInfo = tbDynamicSkillInfo

    -- self:UpdateCanCastState()
    -- self:UpdateCD()
end

--是否应该进入动态技能，主要用于按钮刚初始化的时候做切换
function UIWidgetNormalSkill:CheckSwitchSwitchDynamicSkills()
    if self.funcSwitchDynamicSkills then
        self.funcSwitchDynamicSkills()
    end
end

function UIWidgetNormalSkill:PlayEnterDynamicAnim()
    UIHelper.PlayAni(self, self.AniAll, "AniSwitchShow2")
end

function UIWidgetNormalSkill:UpdateImgCost()
    local szCost = ""
    local tbSkill = UIDynamicSkillInfoTab[self.nCurrentSkillID]
    if tbSkill then
        szCost = tbSkill.szDetail
    end
    if szCost ~= "" then
        UIHelper.SetString(self.LabelCost, szCost)
    end
    UIHelper.SetVisible(self.ImgCost, szCost ~= "")
end

function UIWidgetNormalSkill:UpdateBahuangSkill()
    local tbSkillData = nil
    if self.nSlotID == 1 then
        --心决
        tbSkillData = BahuangData.GetSkillByTypeAndIndex(1, 1)
    elseif self.nSlotID >= 2 and self.nSlotID <= 5 then
        --秘技
        tbSkillData = BahuangData.GetSkillByTypeAndIndex(2, self.nSlotID - 1)
    elseif self.nSlotID == 10 then
        --绝学
        tbSkillData = BahuangData.GetSkillByTypeAndIndex(3, 1)
    else
        return --非八荒技能按钮
    end

    if tbSkillData then
        --八荒有此技能
        local tbSkillInfo = {}
        tbSkillInfo.id = tbSkillData.dwSkillID
        tbSkillInfo.level = tbSkillData.nSkillLevel
        self:SwitchDynamicSkills(true, tbSkillInfo)
        self.bHasBahuangSkill = true
    elseif not tbSkillData and self.bHasBahuangSkill then
        self:SwitchDynamicSkills(false)
        self.bHasBahuangSkill = false
    end
    UIHelper.SetVisible(self.AniAll, tbSkillData ~= nil)
    UIHelper.SetVisible(self.ImgSkillBahuangBg, tbSkillData == nil)
    self.bEnterBahuangState = true
    self:UpdateTiShiQuan(false)
    self:UpdateVisibility()
end

function UIWidgetNormalSkill:UpdateTreasureBattleFieldSkill()
    if not TreasureBattleFieldSkillData.IsDefaultSkillIndex(self.nSlotID)
            and not TreasureBattleFieldSkillData.IsDynamicSkillIndex(self.nSlotID) then
        return
    end
    if not TreasureBattleFieldSkillData.IsInDynamic() then
        return
    end
    local tbSkillData = TreasureBattleFieldSkillData.GetSkillInfoByIndex(self.nSlotID)
    if tbSkillData then
        local tbSkillInfo = {}
        tbSkillInfo.id = tbSkillData.nSkillID
        tbSkillInfo.level = tbSkillData.nSkillLevel
        self:SwitchDynamicSkills(true, tbSkillInfo)
    elseif not tbSkillData then
        local tbSkillInfo = {}
        tbSkillInfo.id = nil
        tbSkillInfo.level = 1
        self:SwitchDynamicSkills(true, tbSkillInfo)
    end
end

function UIWidgetNormalSkill:ShowUpSkillEffect()
    if self.bIsHD then
        if GameSettingData.GetNewValue(UISettingKey.ShowSkillRangeHint) then
            local dwEffectID, bIsShowSFX = GetUpSkillEffect(self.nCurrentSkillID)
            if not dwEffectID then
                return false
            end

            if bIsShowSFX then
                Selection_ShowSFX(self.nCurrentSkillID, self.nSkillLevel)
            end

            rlcmd("play local origin sfx " .. dwEffectID)
        end
    else
        local tSkillConfig = self.tCurrentSkillConfig
        if not tSkillConfig.bJoystick and tSkillConfig.nWarningBoxType and tSkillConfig.nWarningBoxType > 0 then
            self:createWarningBoxVK(self.nCurrentSkillID, self.nSkillLevel, tSkillConfig.nWarningBoxType, tSkillConfig.bAreaBoxHeightFollow)
        end
    end
end

function UIWidgetNormalSkill:HideUpSkillEffect()
    if self.bIsHD then
        if GameSettingData.GetNewValue(UISettingKey.ShowSkillRangeHint) then
            Selection_HideSFX()
            rlcmd("stop local origin sfx")
        end
    else
        self:destroyWarningBoxVK()
    end
end

function UIWidgetNormalSkill:createWarningBoxVK(nSkillID, nSkillLevel, nType, bAreaBoxHeightFollow)
    local szEffect = kWarningBox.tSfxs[nType]
    if not szEffect then
        return
    end
    local pSkill = GetPlayerSkill(nSkillID, nSkillLevel, g_pClientPlayer.dwID)
    if not pSkill then
        return
    end

    self:HideUpSkillEffect()

    --local nRotation, nOffset = 0, 0
    local nScaleX, nScaleZ
    if nType == 1 or nType == 6 then
        -- 方形
        --nRotation = -2 * math.pi * pSkill.nRectRotation / GLOBAL.DIRECTION_COUNT
        --nOffset = -pSkill.nRectOffset * 100 / Const.kMetreLength
        nScaleX = pSkill.nRectWidth / kWarningBox.nBoxSfxWidth  -- 全宽
        nScaleZ = pSkill.nAreaRadius / kWarningBox.nBoxSfxWidth -- 半长
    else
        nScaleX = pSkill.nAreaRadius / kWarningBox.nCircleSfxRadius
        nScaleZ = nScaleX
    end

    local pEffect = SceneMgr.CreateModel(szEffect)
    if not pEffect then
        return
    end

    pEffect:SetScaling(nScaleX, 1.0, nScaleZ)
    SceneMgr.GetGameScene():AddRenderEntity(pEffect)

    local bInCancelArea = false
    local fnTimer = function()
        local nPlayerX, nPlayerY, nPlayerZ = g_pClientPlayer.GetAbsoluteCoordinate()
        local nX, nY, nZ, nFaceDir = Player_GetLocalRTParam()
        if bAreaBoxHeightFollow then
            -- 是否跟随玩家
            nY = nY + kHeightOffset * Const.kMetreHeight
        else
            nPlayerZ = g_pClientPlayer.GetScene().GetFloor(nPlayerX, nPlayerY, nPlayerZ)
                    or nPlayerZ
            _, nY = SceneMgr.LogicPosToScenePos(nPlayerX, nPlayerY, nPlayerZ + kHeightOffset) -- 贴地
        end
        pEffect:SetTranslation(nX, nY, nZ)

        if nType ~= 2 then
            -- 圆形不用旋转
            local tQua = kmath.fromEuler(0, nFaceDir + math.pi, 0)
            pEffect:SetRotation(tQua.x, tQua.y, tQua.z, tQua.w)
        end

        if self.scriptSkillCancelCtrl and bInCancelArea ~= self.scriptSkillCancelCtrl:IsDragIn() then
            bInCancelArea = self.scriptSkillCancelCtrl:IsDragIn()
            if bInCancelArea then
                pEffect:SetSFXColor(1.0, 0, 0, true)      -- 红色
            else
                pEffect:SetSFXColor(1.0, 1.0, 1.0, false) -- 还原
            end
        end
    end

    Timer.DelTimer(self, self.nWarningBoxTimer)
    self.pWarningBoxModel = pEffect
    self.nWarningBoxTimer = Timer.AddFrameCycle(self, 1, fnTimer)
    fnTimer()
end

function UIWidgetNormalSkill:destroyWarningBoxVK()
    if self.pWarningBoxModel then
        self.pWarningBoxModel:SetSFXColor(1.0, 1.0, 1.0, false)
        SceneMgr.DestoryModel(self.pWarningBoxModel, true)
        self.pWarningBoxModel = nil
    end

    if self.nWarningBoxTimer then
        Timer.DelTimer(self, self.nWarningBoxTimer)
        self.nWarningBoxTimer = nil
    end
end

function UIWidgetNormalSkill:SetSkillVisible(bValue)
    self.bShouldSkillShow = bValue
    self:UpdateVisibility()
end

function UIWidgetNormalSkill:SetCDVisible(bShow)
    UIHelper.SetActiveAndCache(self, self.cdLabel, bShow)
end

function UIWidgetNormalSkill:UpdateVisibility()
    if self.bHaveSkill == nil then
        self.bHaveSkill = false
    end

    local bValue = (self.bHaveSkill or self.bEnterBahuangState) and self.bShouldSkillShow -- 八荒状态改下需要强制显示特定槽位
    if bValue ~= self._isShown or self._isShown == nil then
        self._IsSkillIconGreyCache = nil
        local node = UIHelper.GetParent(self._rootNode) or self._rootNode
        UIHelper.SetVisible(node, bValue)

        if bValue == true then
            self:OnUpdate()
            Timer.DelTimer(self, self.nVisibleTimerID)
            self.nVisibleTimerID = Timer.AddFrameCycle(self, 2, function()
                self:OnUpdate()
            end)

            if not self.bIsHD then
                Timer.DelTimer(self, self.nRefreshIconTimer)
                self.nRefreshIconTimer = Timer.AddCycle(self, 0.5, function()
                    if not self.bEnterDynamicSkills and not self.bEnterBahuangState and g_pClientPlayer and self.bHaveSkill then
                        self:CheckSkill() -- 保护vk技能特殊情况 明教在满灵的情况下，被封内会导致傍身招式从正常的破变为普通的日月轮，致使无法使用傍身招式，会直接黑掉
                    end
                end)
            end
        else
            if self.tCasting then
                self:StopSkill(self.tCasting, true) -- 技能隐藏时无视bChannelSkillGuarding状态 停止技能
            end
            self:OnPressUp(true)
            self:HideUpSkillEffect()
            Timer.DelAllTimer(self)
        end

        self._isShown = bValue
    end
end

function UIWidgetNormalSkill:SetSkillDirectionCtrl(ctrl)
    self.lbSkillDirection = ctrl ---@type UISkillDirection
end

function UIWidgetNormalSkill:SetSkillCancelCtrl(ctrl)
    self.scriptSkillCancelCtrl = ctrl ---@type UISkillCancel
end

function UIWidgetNormalSkill:SetSkillGreyAndCache(isGrey)
    local isCurIconGrey = self._IsSkillIconGreyCache
    if isGrey ~= isCurIconGrey then
        --LOG.WARN("SetSkillGreyAndCache %d %s",self.nSlotID,isGrey and "true" or "false")
        UIHelper.SetNodeGray(self.imgSkillIcon, isGrey)
        UIHelper.SetColor(self.imgSkillIcon, isGrey and cc.c3b(155, 155, 155) or cc.c3b(255, 255, 255))
        UIHelper.SetButtonState(self.skillBtn, isGrey and BTN_STATE.Disable or BTN_STATE.Normal, nil, false, false)
        self._IsSkillIconGreyCache = isGrey

        if not isGrey and self.bEnterDynamicSkills then
            self.Eff_UIskillRefresh_IndependentCD:Play(0)
        end
    end
end

function UIWidgetNormalSkill:SetCountDownAndCache(fTime)
    local cacheTime = self._CountDownCache
    if fTime ~= cacheTime then
        UIHelper.SetString(self.cdLabel, UIHelper.GetSkillCDText(fTime, bDecimalPoint))
        self._CountDownCache = fTime
        return true
    end
    return false
end

function UIWidgetNormalSkill:IsUniqueSkillSlot()
    if self.bEnterDynamicSkills then
        return self.nSlotID == 2 and g_pClientPlayer.dwMorphID > 0
    else
        return self.nSlotID == UI_SKILL_UNIQUE_SLOT_ID and not self.bIsHD
    end
end

function UIWidgetNormalSkill:IsJumpSkill()
    return self.nCurrentSkillID == UI_SKILL_JUMP_ID
end

function UIWidgetNormalSkill:IsFuYaoSkill()
    return self.nCurrentSkillID == UI_SKILL_FUYAO_ID or self.nCurrentSkillID == UI_DXSKILL_FUYAO_ID
end

-- 像龙般若功 释放时隐藏技能图标
function UIWidgetNormalSkill:IsHideWhenCasting()
    return self.nCurrentSkillID == 102352
end

function UIWidgetNormalSkill:GetCurrentSkill()
    return self.nCurrentSkillID
end

function UIWidgetNormalSkill:ShowQingGongCombine()
    if self.nSlotID == 29 and not self.skillCombineScript and not self.bCustom then
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCombineSlider, self._rootNode)
        self.skillCombineScript = SkillPanelDXHelper.AddSkillCombine()
        self.skillCombineScript:InitQingGong()
        self.skillCombineScript:BindCDSlider(script)
        self.skillCombineScript:SetVisible(false)
        UIHelper.SetLongPressDelay(self.skillBtn, SHOW_COMBO_PRESS_TIME)
    end
end

function UIWidgetNormalSkill:SetShortcutID(nIndex)
    if self.keyBoardScript then
        self.keyBoardScript:SetID(nIndex, nil, true)
        self.keyBoardScript:UpdateInfo()
    end
end

function UIWidgetNormalSkill:ShowCannotCastTip()
    if self.bInCoolDown or self.bIsPassiveSkill then
        return
    end

    local player = GetControlPlayer()
    local nRespondCode = SkillData.GetCastSkillResult(player, self.nCurrentSkillID)
    local szMsg = FightLog.GetSkillRespondText(nRespondCode)
    if not self:IsJumpSkill() and not (player.dwForceID ~= FORCE_TYPE.TIAN_CE and player.bOnHorse) then
        if self.tDXSlotData.tbItemInfo and self.tDXSlotData.tbItemInfo.nGenre == ITEM_GENRE.EQUIPMENT then
            if not ItemData.HasItemInBox(INVENTORY_INDEX.EQUIP, self.tDXSlotData.data1, self.tDXSlotData.data2) then
                return TipsHelper.ShowNormalTip(g_tStrings.STR_USE_FAILED_NOT_EQUIPED)
            end
        end
        if (not self.bEnterBahuangState and not self.bEnterDynamicSkills) and player.GetSkillLevel(self.nCurrentSkillID) == 0 then
            TipsHelper.ShowNormalTip("当前技能尚未习得")
        else
            TipsHelper.ShowNormalTip(szMsg) -- 跳跃技能 or 非天策职业若在马上时不弹错误tips
        end
    end
end

function UIWidgetNormalSkill:StartAutoCastSkill(pPlayer)
    if not self.bIsHD or not SkillData.IsAutoCastEnable()
            or not GameSettingData.GetNewValue(UISettingKey.SkillLongPressAutoCast) or self.skillCombineScript then
        return false
    end

    local tSkillConfig = self.tCurrentSkillConfig
    local nCastType = self.tCurrentSkillConfig.nCastType
    if nCastType == UISkillCastType.Normal or self.tDXSlotData.nType == DX_ACTIONBAR_TYPE.SKILL then
        if tSkillConfig.bJoystick and self.lbSkillDirection and not self:IsCastSkillImmediately(pPlayer) then
            return false -- 需要选择位置的技能在没有立即释放的情况下不进入自动连放
        end
    end

    if self.bLongPressCastingSkill then
        return true
    end
    self.bLongPressCastingSkill = true
    self:PerformAutoCastSkill(pPlayer)
    return true
end

function UIWidgetNormalSkill:StopAutoCastSkill()
    self.bLongPressCastingSkill = false
    self.nLastAutoCastTime = nil
    self.tCasting = nil
end

function UIWidgetNormalSkill:PerformAutoCastSkill(pPlayer)
    if not self.bLongPressCastingSkill then
        return
    end

    if (not self.bInPress and not self.bAutoPress) or not SkillData.IsAutoCastEnable(pPlayer) then
        self:StopAutoCastSkill()
        return
    end

    local nOTState = pPlayer.GetOTActionState()
    if nOTState == CHARACTER_OTACTION_TYPE.ACTION_SKILL_HOARD then
        -- nOTState == CHARACTER_OTACTION_TYPE.ACTION_SKILL_CHANNEL
        --        or nOTState == CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE
        return -- DX只判断了蓄力技能不打断
    end

    if self.tCasting.nSkillID ~= self.nCurrentSkillID then
        local nSkillLevel = pPlayer.GetSkillLevel(self.nCurrentSkillID)
        if nSkillLevel == 0 then
            nSkillLevel = self.bEnterDynamicSkills and self.nDynamicSkillLevel or 1
        end
        self.tCasting.nSkillLevel = nSkillLevel
        self.tCasting.nSkillID = self.nCurrentSkillID
        self.tCasting.tSkillConfig = self.tCurrentSkillConfig
    end

    local nTickCount = GetTickCount()
    local m_bOpenAutoPress = GameSettingData.GetNewValue(UISettingKey.SkillAutoCastWithoutPressing)
    if m_bOpenAutoPress and not self.bAutoPress and nTickCount - (self.nPressStartTime * 1000) > AUTO_LONG_PRESS_TIME then
        self.bAutoPress = true
        local szTip = FormatString(g_tStrings.STR_ACTIONBAR_AUTODOWN_OPEN, self.nSlotID)
        TipsHelper.ShowImportantYellowTip(szTip)
        OutputMessage("MSG_SYS", szTip)
    end

    if not self.bInCoolDown and self.bCanCastSkill and (self.nLastAutoCastTime == nil or nTickCount - self.nLastAutoCastTime > nTryCastSkillInterval) then
        self:CastSkillDown(pPlayer)
        if not self.bCastingHoard then
            self:CastSkillUp(false, pPlayer) -- 保护蓄力技能
        end
        self.nLastAutoCastTime = nTickCount
        self.bCastingHoard = false
    end
end

function UIWidgetNormalSkill:SetCustomState(bCustom)
    self.bCustom = bCustom
    if self.keyBoardScript then
        self.keyBoardScript:SetCustomState(bCustom)
    end
end
return UIWidgetNormalSkill
