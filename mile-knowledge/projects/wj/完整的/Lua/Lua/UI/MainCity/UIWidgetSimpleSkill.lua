--**********************************************************************************
-- 脚本名称: UIWidgetSimpleSkill
-- 创建时间: 2025年7月23日
-- 功能概述: 精简技能槽位 目前用于DX技能
--**********************************************************************************

local tSpecialSkillImg = {
    [24858] = "UIAtlas2_SkillDX_SpecialSkill_YanTian_1",
    [24859] = "UIAtlas2_SkillDX_SpecialSkill_YanTian_2",
    [24860] = "UIAtlas2_SkillDX_SpecialSkill_YanTian_3"
}

local Timer = Timer

local UIWidgetSimpleSkill = class("UIWidgetSimpleSkill")

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

function UIWidgetSimpleSkill:OnEnter(nSlotID)
    if not self.bInit then
        self.bInCoolDown = false
        self.bCanCastSkill = false

        self.bHaveSkill = false
        self.bIsHD = SkillData.IsUsingHDKungFu()
        self.nSlotID = nSlotID
        self.bPlaySFX = false

        self:InitMember()
        self:BindUIEventListener() -- 绑定组件消息
        self:RegEvents()
        self.bInit = true

        local keyBoardNode = UIHelper.FindChildByName(UIHelper.GetParent(self._rootNode), "WidgetKeyBoardKey")
        self.keyBoardScript = keyBoardNode and UIHelper.GetBindScript(keyBoardNode) ---@type UIShortcutInteraction

        self:SetSkillDirectionCtrl(SkillPanelDXHelper.SkillDirectionScript)
        self:SetSkillCancelCtrl(SkillPanelDXHelper.SkillCancelScript)

        UIHelper.SetLocalZOrder(self._rootNode, -1) --使按钮显示在按键映射标签下
    end
end

function UIWidgetSimpleSkill:OnExit()
    self.funcSwitchDynamicSkills = nil
    self.nSlotID = nil
    self:InitMember()
    Timer.DelAllTimer(self)

    if self.skillCombineScript then
        UIHelper.RemoveFromParent(self.skillCombineScript._rootNode, true)
        self.skillCombineScript = nil
    end
end

function UIWidgetSimpleSkill:BindUIEventListener()
    UIHelper.BindUIEvent(self.skillBtn, EventType.OnTouchBegan, function(_, x, y)
        self:OnPressDown(x, y)
        return not self.bInCoolDown
    end)

    UIHelper.SetLongPressDelay(self.skillBtn, SHOW_TIP_PRESS_TIME)
    UIHelper.SetLongPressDistThreshold(self.skillBtn, 5)
    UIHelper.BindUIEvent(self.skillBtn, EventType.OnLongPress, function(_)
        if self.skillCombineScript and not UIHelper.GetVisible(self.skillCombineScript._rootNode) then
            if self.bWuDu or self.tbPetSkillGroup or self.tbPuppetSkillGroup or self.tbShadowSkillGroup then
                self.skillCombineScript:OnDragStart()
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
        if self.skillCombineScript and UIHelper.GetVisible(self.skillCombineScript._rootNode) then
            if self.bWuDu or self.tbPetSkillGroup or self.tbPuppetSkillGroup or self.tbShadowSkillGroup then
                self.skillCombineScript:OnDragEnd()
            end
            return
        end
    end
    UIHelper.BindUIEvent(self.skillBtn, EventType.OnTouchEnded, fnTouchEnd)
    UIHelper.BindUIEvent(self.skillBtn, EventType.OnTouchCanceled, fnTouchEnd)

    UIHelper.SetButtonClickSound(self.skillBtn, "")
end

function UIWidgetSimpleSkill:RegEvents()
    Event.Reg(self, EventType.OnDXSkillSlotChanged, function()
        self:UpdateFuncName() -- 监听技能变更事件 刷新快捷键
    end)

    Event.Reg(self, "SKILL_MOUNT_KUNG_FU", function()
        self.bIsHD = SkillData.IsUsingHDKungFu()
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
            end
        end
    end
    Event.Reg(self, "ON_SKILL_REPLACE", function(nOldSkillID, nSkillID, arg2)
        fnChangeSkill(nOldSkillID, nSkillID)
    end)

    Event.Reg(self, "CHANGE_SKILL_ICON", function(nOldSkillID, nSkillID, arg2, arg3)
        fnChangeSkill(nOldSkillID, nSkillID)
    end)

    Event.Reg(self, "DO_SKILL_CHANNEL_PROGRESS_END", function(arg0, arg1)
        local dwSkillID = arg1
        if dwSkillID == self.nCurrentSkillID then
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

    Event.Reg(self, EventType.OnShortcutUseSkillSelect, function(nSlotId, nPressType, bFromAutoBattle)
        if self.nSlotID == nSlotId then
            if nPressType == 1 then
                if bFromAutoBattle then
                    self:UpdateCanCastState()
                    self:UpdateCD()
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

    Event.Reg(self, EventType.OnDXSkillSlotChanged, function()
        self:UpdateFuncName()
    end)
end

function UIWidgetSimpleSkill:UnRegEvents()
    Event.UnRegAll(self)
end

function UIWidgetSimpleSkill:InitMember()
    self.nCurrentSkillID = nil
    self.tCurrentSkillConfig = nil
    self.tDXSlotData = {}
    self.bInCoolDown = false
    self.nPressStartTime = 0
end

function UIWidgetSimpleSkill:InitSkill(nSkillID, nShortcutIndex)
    self:OnEnter()

    local pPlayer = g_pClientPlayer
    if not pPlayer then
        return
    end

    if self.keyBoardScript then
        self.keyBoardScript:SetID(nShortcutIndex, nil, true)
    end
    self:ResetSkill()
    if not self.nSlotID then
        self.nSlotID = SpecialDXSkillData.GetSpecialSkillSlotID()
    end

    self.nLeftTime = 0
    self.nShortcutIndex = nShortcutIndex
    self.nCurrentSkillID = nil
    self.tCurrentSkillConfig = nil
    self.tCDSliders = {}
    self:OnSwitchSkill(nSkillID)

    self._IsSkillIconGreyCache = nil  ---刷新技能置灰状态

    if SkillData.GetCacheSlotID() == self.nSlotID then
        SkillData.ClearSkillCache()
    end

    self.bHaveSkill = self.nCurrentSkillID ~= nil --技能状态，如果找不到可以显示的，就隐藏
    self.bIsPetSkill = SpecialDXSkillData.tCurrentPetSkill[self.nCurrentSkillID]

    if SkillData.GetCacheSlotID() == self.nSlotID then
        SkillData.ClearSkillCache()
    end

    if self.nUpdateTimerID then
        Timer.DelTimer(self, self.nUpdateTimerID)
        self.nUpdateTimerID = nil
    end
    if self.bHaveSkill then
        self.nUpdateTimerID = Timer.AddFrameCycle(self, 2, function()
            self:OnUpdate()
        end)
    end
end

---------------------------------------------------------

function UIWidgetSimpleSkill:UpdateTiShiQuan(bShow)
    UIHelper.SetVisible(self.Eff_UI_TiShiQuan, bShow)
    if bShow and not self.bPlaySFX then
        UIHelper.PlaySFX(self.Eff_UI_TiShiQuan, 1)
        self.bPlaySFX = true
    end
end

function UIWidgetSimpleSkill:ShowSkillTip()
    --if not g_pClientPlayer or g_pClientPlayer.nLevel < 102 then
    --    return
    --end
    --local tCursor = GetCursorPoint()
    --local nSkillLevel = g_pClientPlayer.GetSkillLevel(self.nCurrentSkillID)
    --if nSkillLevel then
    --    nSkillLevel = self.bEnterDynamicSkills and self.nDynamicSkillLevel or 1
    --end
    --
    --local tips, tipsScriptView = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetSkillInfoTips, tCursor.x,
    --        tCursor.y, self.nCurrentSkillID, nil, nil, nSkillLevel)
    --tipsScriptView:SetBtnVisible(false)
end

function UIWidgetSimpleSkill:ShowSkillCancel()
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

function UIWidgetSimpleSkill:HideSkillCancel()
    if self.scriptSkillCancelCtrl then
        self.scriptSkillCancelCtrl:Hide()
        self.bSHowSkillCancelCtrl = false
    end
end

---------------------------------------------------------

function UIWidgetSimpleSkill:BeginDirectionSkill(nTouchX, nTouchY)
    local pPlayer = g_pClientPlayer
    if not pPlayer then
        return
    end
    local tCasting = self.tCasting

    if SkillData.UsePCSkillReleaseMode() then
        local nTargetID, nTargetType = TargetMgr.GetSelect()
        local tTargetInfo = nTargetType == TARGET.PLAYER and GetPlayer(nTargetID) or GetNpc(nTargetID)
        local nSkillLevel = g_pClientPlayer.GetSkillLevel(self.nCurrentSkillID)
        local pSkill = GetPlayerSkill(self.nCurrentSkillID, nSkillLevel, pPlayer.dwID)
        if nTargetID ~= 0 and tTargetInfo and pSkill then
            local distance = GetDistance(pPlayer, tTargetInfo)
            local nMaxSkillDistance = pSkill.nMaxRadius / 64
            if distance and distance <= nMaxSkillDistance then
                SkillData.CastSkillXYZ(pPlayer, tCasting.nSkillID, tCasting.nSkillLevel, tTargetInfo.nX, tTargetInfo.nY, tTargetInfo.nZ) -- DX技能在有目标且距离合法时直接释放
                return
            end
        end
    end

    self.lbSkillDirection:OnPressDown(
            nTouchX, nTouchY,
            self.nSlotID, tCasting.nSkillID, tCasting.tSkillConfig, tCasting.tTarget,
            function(x, y, z)
                --print(tCasting.nSkillID, tCasting.nSkillLevel, x, y, z)
                SkillData.CastSkillXYZ(pPlayer, tCasting.nSkillID, tCasting.nSkillLevel, x, y, z)
            end,
            function(x, y, z)
                return SkillData.CanCastSkillXYZ(pPlayer, tCasting.nSkillID, tCasting.nSkillLevel, x, y, z)
            end
    )
end

function UIWidgetSimpleSkill:CastCommonSkill(tCasting)
    if tCasting.tSkillConfig.bJoystick then
        if self.lbSkillDirection then
            self.lbSkillDirection:OnPressUp(self.nSlotID)
        end
    else
        local bValidPosition = true
        if SkillData.IsUseSkillDirectionCancel() and self.scriptSkillCancelCtrl then
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
                SkillData.CastSkill(g_pClientPlayer, tCasting.nSkillID)
            end
            SkillData.AddLastCast(self.nSlotID, Timer.GetPassTime())
        elseif self.bHorseDynamicSkill then
            SkillData.CastSkill(g_pClientPlayer, tCasting.nSkillID)
            SkillData.AddLastCast(self.nSlotID, Timer.GetPassTime())
        end

        if self.bEnterDynamicSkills then
            APIHelper.SetUsePendantAction(3)
        end
    end
end

function UIWidgetSimpleSkill:StopCommonSkill(tCasting)
    assert(tCasting.tSkillConfig.nCastType == UISkillCastType.Normal)

    if self.lbSkillDirection then
        self.lbSkillDirection:OnPressUp(self.nSlotID)
    end
end

function UIWidgetSimpleSkill:BeginChannelSkill(tCasting, nX, nY)
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

    tCasting.bChannelSkillGuarding = true
    tCasting.nWaitForResponse = Timer.Add(self, 0.4, function()
        tCasting.bChannelSkillGuarding = false

        self.nChannelX = nil
        self.nChannelY = nil
        self.bWaitForChannelRespond = false
    end) -- 等待服务器通道技释放成功回调
end

function UIWidgetSimpleSkill:OnChannelSkillRespond()
    local pPlayer = g_pClientPlayer
    local tCasting = self.tCasting
    local tSkillConfig = self.tCasting and self.tCasting.tSkillConfig
    if tCasting and self.bWaitForChannelRespond then
        if tCasting.nWaitForResponse then
            Timer.DelTimer(self, tCasting.nWaitForResponse)
            tCasting.nWaitForResponse = nil
        end

        if tSkillConfig and tSkillConfig.bJoystick and self.lbSkillDirection then
            self.lbSkillDirection:OnPressDown(self.nChannelX, self.nChannelY, self.nSlotID, tCasting.nSkillID,
                    tSkillConfig, tCasting.tTarget)
        end

        if tSkillConfig.fPressGuardTime > 0 then
            tCasting.bChannelSkillGuarding = true
            local nSecond = tSkillConfig.fPressGuardTime / 1000 * 1024 / (1024 + pPlayer.nCurrentHasteRate)
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
            tCasting.nUpdateTimerID = Timer.AddCycle(self, 0.2, function()
                local pos = SkillData.GetCastPoint()
                g_pClientPlayer.SetSubSkillPosition(tCasting.nSkillID, tCasting.nSkillLevel, pos.x, pos.y, pos.z)
            end)
        end

        self.bWaitForChannelRespond = false
    end
end

function UIWidgetSimpleSkill:StopChannelSkill(tCasting, bStopSkillToServer)
    if self.lbSkillDirection and tCasting.tSkillConfig.bJoystick then
        self.lbSkillDirection:OnPressUp(self.nSlotID)
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

function UIWidgetSimpleSkill:StopSkill(tCasting, bStopSkillToServer)
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

function UIWidgetSimpleSkill:OnUpdate()
    local pPlayer = g_pClientPlayer
    if not pPlayer or not UIHelper.GetVisible(self._rootNode) then
        return
    end

    self:UpdateCanCastState()
    self:UpdateCD()
    self:UpdateCacheSlot(pPlayer)
end

function UIWidgetSimpleSkill:UpdateCacheSlot(pPlayer)
    if not SkillData.CacheSlotInfo or SkillData.GetCacheSlotID() ~= self.nSlotID then
        return
    end

    local nTime = Timer.GetPassTime()
    if IsChannelSkill(self.tCurrentSkillConfig.nCastType) or SkillData.CacheSlotInfo.StartTime + SkillData.SkillCacheTime < nTime then
        SkillData.ClearSkillCache() -- zyx说通道技能不参与技能缓存
        return
    end

    if AutoBattle.IsInAutoBattle() and pPlayer and pPlayer.bFightState then
        return
    end

    if self.tCurrentSkillConfig.nCastType == SkillData.CacheSlotInfo.CastType and not self.bInCoolDown and not self.bStartIntervalCastSkill then
        self:OnPressDown()
        self:OnPressUp()
        SkillData.ClearSkillCache()
    end
end

--更新是否可以释放
function UIWidgetSimpleSkill:UpdateCanCastState()
    if not self.nCurrentSkillID then
        return
    end

    local bCanCast = true
    if not self.bIsPetSkill then
        bCanCast = SkillData.CanCastSkill(g_pClientPlayer, self.nCurrentSkillID) -- 宠物技能默认允许释放
    end

    if self.tDXSlotData.nType == DX_ACTIONBAR_TYPE.ITEM_INFO then
        if self.tDXSlotData.tbItemInfo.nGenre == ITEM_GENRE.EQUIPMENT then
            local bEquipped = ItemData.HasItemInBox(INVENTORY_INDEX.EQUIP, self.tDXSlotData.data1, self.tDXSlotData.data2)
            bCanCast = bEquipped
        end
    end

    local nDisableBuff = SpecialDXSkillData.GetSkillDisableBuff(self.nCurrentSkillID)
    if nDisableBuff then
        bCanCast = g_pClientPlayer.GetBuff(nDisableBuff, 0) == nil
    end

    self.bCanCastSkill = bCanCast
    if self.bInCoolDown then
        return
    end

    local bGray = (not bCanCast) and (not self.bIsPassiveSkill) --被动技能不置灰
    self:SetSkillGreyAndCache(bGray)
end

local tShowChargePointIndexList = {
    [1] = { 2 },
    [2] = { 2, 3 },
    [3] = { 1, 2, 3 },
    [4] = { 1, 2, 3, 4 },
}

function UIWidgetSimpleSkill:UpdateRechargeCD(bCool, nLeft, nTotal, nCount, nMaxCount, bIsRecharge, bPublicCD)
    --if UIHelper.GetProgressBarPercent(self.imgSkillCd) ~= 100 then
    --    UIHelper.SetProgressBarPercent(self.imgSkillCd, 100)
    --end

    if nMaxCount and nMaxCount > 1 then
        self.bIsRechargeSkill = true -- 是否为充能或透支技能
        if bIsRecharge then
            UIHelper.SetActiveAndCache(self, self.ImgEnergyBg, true)

            if nCount ~= self.nLastRechargeCount then
                UIHelper.SetProgressBarPercent(self.imgSkillCd, 100)
                UIHelper.SetActiveAndCache(self, self.imgSkillCd, nCount == 0)
                UIHelper.SetString(self.LabelEnergy, nCount)
                if self.nLastRechargeCount and nCount > self.nLastRechargeCount and self.Eff_UIskillEnergy then
                    self.Eff_UIskillEnergy:Play(0)
                end
            end
        else
            if not self.nLastRechargeCount or nCount ~= self.nLastRechargeCount then
                local tIndexList = tShowChargePointIndexList[nCount]
                UIHelper.SetRotation(self.WidgetSkillChargePont4, nCount % 2 == 0 and 90 or 103.5)
                for index, node in ipairs(self.tRechargePoints) do
                    UIHelper.SetActiveAndCache(self, node, table.contain_value(tIndexList, index)) --通过旋转实现透支技能的豆豆展示
                end
            end
        end
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

    --if not bPublicCD then
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

    if self.bRechargeHasCD ~= bCool then
        self.bRechargeHasCD = bCool
        UIHelper.SetActiveAndCache(self, self.cdLabel, bCool)
        UIHelper.SetActiveAndCache(self, self.SliderCharge, bCool)
        UIHelper.SetActiveAndCache(self, self.Eff_ChongNeng, bCool)
    end

    return true
end

function UIWidgetSimpleSkill:SetCDVisible(bShow)
    UIHelper.SetActiveAndCache(self, self.cdLabel, bShow)
end

function UIWidgetSimpleSkill:UpdateCD()
    if not self.nCurrentSkillID then
        return
    end

    local fRelatedCDPercent = nil
    local bShouldShow = false
    if self.tCurrentSkillConfig and self.tCurrentSkillConfig.nType == UISkillType.Append then
        local bShowSecondSlider, nEndFrame, nTotalFrame = g_pClientPlayer.CanUIShowSkill(self.nCurrentSkillID)
        nEndFrame = nEndFrame or 0
        local leftFrame = nEndFrame - Timer.GetLogicFrameCount()
        if leftFrame > 0 then
            bShouldShow = true
            UIHelper.SetProgressBarPercent(self.SliderSkillSecond, (leftFrame / nTotalFrame) * 100)
        end
    end

    local tbTime = SpecialDXSkillData.GetSkillBuffTimeEnd(self.nCurrentSkillID)
    if tbTime and not table.is_empty(tbTime) then
        local nEndTime = tbTime.nEndTime
        local nTotalTime = tbTime.nTotalTime
        local leftTime = nEndTime - GetTickCount()
        if leftTime > 0 then
            bShouldShow = not self.skillCombineScript
            fRelatedCDPercent = (leftTime / nTotalTime) * 100
            UIHelper.SetProgressBarPercent(self.SliderSkillSecond, fRelatedCDPercent)
            local bHighLight = SpecialDXSkillData.IsHighLightSkill(self.nCurrentSkillID)
            self:UpdateTiShiQuan(bHighLight)
        end
    end

    local nLampLeft = SpecialDXSkillData.GetLampLeftFrame(self.nCurrentSkillID)
    if nLampLeft then
        UIHelper.SetString(self.LabelLampTimeLeft, UIHelper.GetSkillCDText(nLampLeft / GLOBAL.GAME_FPS, true))
    end

    UIHelper.SetActiveAndCache(self, self.WidgetLampTime, nLampLeft ~= nil)
    UIHelper.SetActiveAndCache(self, self.SliderSkillSecond, bShouldShow)

    local _, nLeft, nTotal, nCDCount, nMaxCount, bIsRecharge, bPublicCD = SkillData.GetSkillCDProcess(g_pClientPlayer, self.nCurrentSkillID)

    nLeft = nLeft or 0
    nTotal = nTotal or 1

    nLeft = nLeft / GLOBAL.GAME_FPS
    nTotal = nTotal / GLOBAL.GAME_FPS

    local bCool = nLeft > 0 or nTotal > 0

    local nCountBuff = SpecialDXSkillData.GetSkillCountBuff(self.nCurrentSkillID)
    if nCountBuff then
        local nStackNum = Buffer_GetStackNum(nCountBuff)
        nMaxCount = nStackNum
        nCDCount = nStackNum
    end

    if self:UpdateRechargeCD(bCool, nLeft, nTotal, nCDCount, nMaxCount, bIsRecharge, bPublicCD) then
        return
    end

    local bCanCastSkill = QTEMgr.CanCastSkill()
    local bShowSFX = (not bCanCastSkill) or (bCanCastSkill and self.nSlotID ~= 1)
    if self.bInCoolDown ~= nil and self.bInCoolDown ~= (bCool) and self.Eff_UIskillRefresh_IndependentCD and not bCool then
        ---在技能cd结束时播放特效
        if not bPublicCD and bShowSFX then
            self.Eff_UIskillRefresh_IndependentCD:Play(0)
        end
    end

    self.bInCoolDown = bCool
    self.nLeftTime = nLeft
    self.bPublicCD = bPublicCD

    local fPercent = 0 --数字倒计时
    if bCool then
        if nTotal > 0 then
            fPercent = nLeft / nTotal * 100
        end

        if self:SetCountDownAndCache(nLeft) then
            UIHelper.SetProgressBarPercent(self.imgSkillCd, fPercent)
        end
    end

    fRelatedCDPercent = fRelatedCDPercent or (100 - fPercent)
    if self.tCDSliders and self.nSliderPercent ~= fRelatedCDPercent then
        self.nSliderPercent = fRelatedCDPercent
        for _, slider in ipairs(self.tCDSliders) do
            UIHelper.SetProgressBarPercent(slider, self.nSliderPercent)
        end
    end

    UIHelper.SetActiveAndCache(self, self.cdLabel, bCool and nLeft >= 0.01)
    UIHelper.SetActiveAndCache(self, self.imgSkillCd, bCool and nLeft >= 0.01)
end

---------------------------------------------------------

function UIWidgetSimpleSkill:UpdateSkillIconAndName()
    if not self.nCurrentSkillID or not self.tCurrentSkillConfig then
        return
    end

    if self.tDXSlotData.nType == DX_ACTIONBAR_TYPE.ITEM_INFO then
        local bResult = UIHelper.SetItemIconByItemInfo(self.imgSkillIcon, self.tDXSlotData.tbItemInfo, nil, true, function()
            UIHelper.UpdateMask(self.MaskSkillIcon)
        end)
        if not bResult then
            UIHelper.ClearTexture(self.imgSkillIcon)
        end
        return
    end

    if self.nCurrentSkillID > 0 then
        local nSkillID = self.nCurrentSkillID
        local nSkillLevel = g_pClientPlayer.GetSkillLevel(nSkillID)
        if nSkillLevel == 0 then
            nSkillLevel = self.bEnterDynamicSkills and self.nDynamicSkillLevel or 1
        end

        if tSpecialSkillImg[nSkillID] then
            UIHelper.SetSpriteFrame(self.imgSkillIcon, tSpecialSkillImg[nSkillID], true, true)
        else
            local szImgPath = TabHelper.GetSkillIconPath(nSkillID) or
                    TabHelper.GetSkillIconPathByIDAndLevel(nSkillID, nSkillLevel)

            if szImgPath then
                if not string.find(szImgPath, "Resource/icon/") then
                    szImgPath = "Resource/icon/" .. szImgPath
                end

                UIHelper.SetTexture(self.imgSkillIcon, szImgPath, true, function()
                    UIHelper.UpdateMask(self.MaskSkillIcon)
                end)
            end
        end

        self:UpdateFuncName()
    end
end

function UIWidgetSimpleSkill:UpdateFuncName(bUpdate)
    local fnCanReplaceFunction = function(szFuncName)
        if szFuncName == "" then
            return true
        end
        if string.starts(szFuncName, DX_SKILL_SHORTCUT_EVENT) then
            local tSpilt = string.split(szFuncName, "_")
            local nSlotIndex = tonumber(tSpilt[2])
            return not (nSlotIndex <= SkillData.DXMaxSlotNum and nSlotIndex >= 1) -- 确认是否为特殊技能槽位事件 是的话允许修改
        end
        return false
    end

    local szName = ""
    local bHDKungFu = self.bIsHD
    local _nShortcutID = self.nShortcutIndex
    if not _nShortcutID then
        _nShortcutID = SkillData.tSlotId2FightIndex[self.nSlotID]
        if bHDKungFu then
            _nShortcutID = SkillData.tDXSlotID2FightIndex[self.nSlotID]
        end
    end

    if bHDKungFu and szName == "" then
        local nSkillID = self.nCurrentSkillID
        local nSkillLevel = g_pClientPlayer.GetSkillLevel(nSkillID)
        if nSkillLevel == 0 then
            nSkillLevel = 1
        end
        szName = UIHelper.LimitUtf8Len(SkillData.GetSkillName(nSkillID, 1), 4)
    end

    -- 轮盘主技能只负责显示快捷键 不进行快捷键信息更新行为
    if not self.skillCombineScript or bUpdate then
        local lst = { SHORTCUT_KEY_BOARD_STATE.Fight, SHORTCUT_KEY_BOARD_STATE.Normal, SHORTCUT_KEY_BOARD_STATE.SimpleNormal,
                      SHORTCUT_KEY_BOARD_STATE.Common, SHORTCUT_KEY_BOARD_STATE.DXFight }
        for _, nType in ipairs(lst) do
            local script = _nShortcutID and SHORTCUT_INTERACTION[nType][_nShortcutID]
            if script then
                script.szFuncName = szName
                if fnCanReplaceFunction(script.interactionFunction) then
                    script.interactionFunction = DX_SKILL_SHORTCUT_EVENT .. self.nSlotID
                end
            end
        end
    end

    if self.keyBoardScript then
        self.keyBoardScript:OnEnter()
    end
end

---多段技能切换逻辑
function UIWidgetSimpleSkill:OnSwitchSkill(dwSkillID2)
    self.bRechargeHasCD = nil
    self.bIsRechargeSkill = nil
    self.nLastRechargeCount = nil

    local pPlayer = g_pClientPlayer
    local nNextSkillID = dwSkillID2
    if not nNextSkillID then
        self.bHaveSkill = false
        self.nCurrentSkillID = nil
        self.tCurrentSkillConfig = nil
        return -- 当前槽位无技能
    end

    self.bHaveSkill = true

    if self.nCurrentSkillID and nNextSkillID == self.nCurrentSkillID then
        return -- 如果找到的技能跟原先的一样或当前无法切换，保持原有的
    end

    self.nCurrentSkillID = nNextSkillID
    local nSkillLevel = g_pClientPlayer.GetSkillLevel(nNextSkillID)
    if nSkillLevel == 0 then
        nSkillLevel = self.bEnterDynamicSkills and self.nDynamicSkillLevel or 1
    end

    -- 如果有技能UI配置，则走UI配置
    -- 如果是动态技能栏技能，则走技能配置适配
    self.tCurrentSkillConfig = TabHelper.GetUISkillMap(nNextSkillID)
    if not self.tCurrentSkillConfig then
        self.tCurrentSkillConfig = SkillData.GetUIDynamicSkillMap(nNextSkillID, nSkillLevel)
    end
    assert(self.tCurrentSkillConfig)

    self:UpdateSkillIconAndName()

    UIHelper.PlayAni(self, self.AniAll, "AniSwitchShow", nil)
end

--还原技能按键的状态
function UIWidgetSimpleSkill:ResetSkill()
    UIHelper.SetActiveAndCache(self, self.Eff_UIskillRefresh_UIskillChuFa, false)
    UIHelper.SetActiveAndCache(self, self.SliderBigCharge, false)
    UIHelper.SetActiveAndCache(self, self.Eff_BigChongNeng, false)
    UIHelper.SetActiveAndCache(self, self.imgSkillCd, false)

    if self.tCasting then
        local tCasting = self.tCasting
        self.tCasting = nil
        self:StopSkill(tCasting)
    end

    self:InitMember()
end

function UIWidgetSimpleSkill:SetSkillVisible(bValue)
    self.bShow = bValue

    local bVisible = self.bHaveSkill and self.bShow
    if bVisible ~= self._isShown or self._isShown == nil then
        local node = UIHelper.GetParent(self._rootNode) or self._rootNode
        UIHelper.SetVisible(node, bVisible)

        --Timer.DelAllTimer(self)
        --if bVisible then
        --    self:OnUpdate()
        --    Timer.AddFrameCycle(self, 2, function()
        --        self:OnUpdate()     ---- 添加到Update Cycle
        --    end)
        --end
        self._isShown = bVisible
    end
end

---------------------------------------------------------

-- 技能键按下
function UIWidgetSimpleSkill:OnPressDown(nX, nY)
    local pPlayer = g_pClientPlayer
    local nSkillID = self.nCurrentSkillID
    local tSkillConfig = self.tCurrentSkillConfig

    if self.bIsPassiveSkill or not self.bHaveSkill then
        if self.bIsPassiveSkill then
            TipsHelper.ShowNormalTip(g_tStrings.STR_PASSIVESKILL_TIP)
        end
        return
    end

    if self.bFromAutoBattle ~= true and self.bInCoolDown and (self.nLeftTime and self.nLeftTime <= SkillData.SkillCacheTime) then
        SkillData.AddSkillCache(self.nSlotID, self.tCurrentSkillConfig.nCastType, Timer.GetPassTime(), self.nCurrentSkillID) -- 当剩余冷却时间不大于缓存时间 且不在自动连放状态 时缓存技能 
    end

    Event.Dispatch(EventType.OnSkillPressDown)
    if not pPlayer or self.bInPress or (self.tCasting and self.tCasting.bChannelSkillGuarding) then
        return -- 已经被按住或处于通道技保护时间
    end

    if not self:IsJumpSkill() and pPlayer.dwSchoolID ~= SCHOOL_TYPE.TIAN_CE and pPlayer.bOnHorse and not self.bEnterDynamicSkills then
        RideHorse() -- 非天策职业若在马上的情况下帮他下马
        self:UpdateCanCastState()
        return
    end

    if self:IsJumpSkill() or TargetMgr.TrySelectOneTarget(self.nCurrentSkillID) then
        self:UpdateCanCastState() -- 每次释放技能前帮玩家默认选一个目标
    end

    UIHelper.PlayAni(self, self.AniAll, "AnicLick", nil)
    if not self.bCanCastSkill then
        self:ShowCannotCastTip()
        return -- 无法释放
    end

    if self:IsJumpSkill() then
        return Jump()
    end

    if (pPlayer.GetOTActionState() == CHARACTER_OTACTION_TYPE.ACTION_SKILL_PREPARE and IsChannelSkill(tSkillConfig.nCastType)) then
        return TipsHelper.ShowImportantBlueTip(g_tStrings.STR_ERROR_IN_OTACTION) -- 持续释放（倒读条）无法打断正在释放的吟唱（正读条）技能，在此处打断释放，避免在当前技能未释放的状态下进入通道技保护时间
    end

    self.nPressStartTime = Timer.GetPassTime()
    self.bInPress = true

    if not tSkillConfig then
        return
    end

    local nSkillLevel = pPlayer.GetSkillLevel(nSkillID)
    if nSkillLevel == 0 then
        nSkillLevel = self.bEnterDynamicSkills and self.nDynamicSkillLevel or 1
    end

    -- 索敌
    local tTarget
    local nCastType = tSkillConfig.nCastType
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

    if self.bInCoolDown then
        self.tCasting = nil
        return
    end

    --蓄力技能逻辑
    local szType = Skill_GetOptType(self.nCurrentSkillID, nSkillLevel)
    if szType == "hoard" then
        LOG.INFO("----------------szType hoard----------------------")
        OnUseSkill(nSkillID, nSkillID * (nSkillID % 10 + 1), nil, true)
        return
    end

    self:ShowSkillCancel()

    if nCastType == UISkillCastType.Normal or nCastType == UISkillCastType.Down then
        if tSkillConfig.bJoystick and self.lbSkillDirection then
            self:BeginDirectionSkill(nX, nY) -- 为了兼容长按唤出轮盘 simpleskill不实现Down模式
        end
    elseif IsChannelSkill(nCastType) then
        if not self.bIsHD then
            self:BeginChannelSkill(self.tCasting, nX, nY)
        else
            self:BeginDirectionSkill(nX, nY) -- HD的通道技能和方向技用一样的释放方式
        end
    end
end

-- 技能键抬起
function UIWidgetSimpleSkill:OnPressUp(bForceCancel)
    if self:IsJumpSkill() then
        EndJump()
        return
    end

    if not self.bInPress then
        return
    end

    bForceCancel = bForceCancel or false

    local pPlayer = g_pClientPlayer
    local tCasting = self.tCasting
    local nDurationTime = Timer.GetPassTime() - self.nPressStartTime

    self.nPressStartTime = 0
    self.bInPress = false
    self.tCasting = nil

    self:HideSkillCancel()

    if not tCasting then
        return -- 当前未释放技能
    end

    if tCasting.bChannelSkillGuarding then
        self.tCasting = tCasting
        return -- 处于通道技保护时间, 等保护时间结束以后结束技能
    end

    --蓄力技能逻辑
    local szType = Skill_GetOptType(tCasting.nSkillID, tCasting.nSkillLevel)
    if szType == "hoard" then
        LOG.INFO("----------------szType hoard up----------------------")
        OnUseSkill(tCasting.nSkillID, tCasting.nSkillID * (tCasting.nSkillID % 10 + 1), nil)
        return
    end

    --if self.bStartIntervalCastSkill then
    --    self:StopIntervalCastSkill()
    --    return
    --end

    if self.lbSkillDirection and bForceCancel then
        self.lbSkillDirection:OnDirectionSkillEnd(self.nSlotID)
    end

    local nCastType = tCasting.tSkillConfig.nCastType
    if (nCastType == UISkillCastType.Normal or nCastType == UISkillCastType.Down) and not bForceCancel then
        if self.bCanCastSkill then
            self:CastCommonSkill(tCasting)
        else
            self:StopSkill(tCasting, true)
        end
    elseif IsChannelSkill(nCastType) then
        self:StopSkill(tCasting, true)
    end
end

---------------------------------------------------------

function UIWidgetSimpleSkill:SetSkillDirectionCtrl(ctrl)
    self.lbSkillDirection = ctrl ---@type UISkillDirection
end

function UIWidgetSimpleSkill:SetSkillCancelCtrl(ctrl)
    self.scriptSkillCancelCtrl = ctrl ---@type UISkillCancel
end

function UIWidgetSimpleSkill:SetSkillGreyAndCache(isGrey)
    local isCurIconGrey = self._IsSkillIconGreyCache
    if isGrey ~= isCurIconGrey then
        --LOG.WARN("SetSkillGreyAndCache %d %s",self.nSlotID,isGrey and "true" or "false")
        UIHelper.SetNodeGray(self.imgSkillIcon, isGrey)
        UIHelper.SetColor(self.imgSkillIcon, isGrey and cc.c3b(155, 155, 155) or cc.c3b(255, 255, 255))
        self._IsSkillIconGreyCache = isGrey

        if not isGrey and self.bEnterDynamicSkills then
            self.Eff_UIskillRefresh_IndependentCD:Play(0)
        end
    end
end

function UIWidgetSimpleSkill:SetCountDownAndCache(fTime)
    local cacheTime = self._CountDownCache
    if fTime ~= cacheTime then
        UIHelper.SetString(self.cdLabel, UIHelper.GetSkillCDText(fTime, true))
        self._CountDownCache = fTime
        return true
    end
    return false
end

function UIWidgetSimpleSkill:IsJumpSkill()
    return self.nCurrentSkillID == UI_SKILL_JUMP_ID
end

function UIWidgetSimpleSkill:GetCurrentSkill()
    return self.nCurrentSkillID
end

function UIWidgetSimpleSkill:SetWuDuSpecialSkill()
    self.bWuDu = true
end

function UIWidgetSimpleSkill:SetPetSkillGroup(tbPetSkillGroup)
    self.tbPetSkillGroup = tbPetSkillGroup
end

function UIWidgetSimpleSkill:SetPuppetSkillGroup(tbPuppetSkillGroup, dwNpcTemplateID)
    self.tbPuppetSkillGroup = tbPuppetSkillGroup
    self.dwNpcTemplateID = dwNpcTemplateID
end

function UIWidgetSimpleSkill:SetShadowSkillGroup(tbShadowSkillGroup)
    self.tbShadowSkillGroup = tbShadowSkillGroup
end

function UIWidgetSimpleSkill:UpdateCombineSkill()
    if not self.skillCombineScript then
        if self.bWuDu or self.tbPetSkillGroup or self.tbPuppetSkillGroup or self.tbShadowSkillGroup then
            self.skillCombineScript = SkillPanelDXHelper.AddSkillCombine()
            Timer.AddFrame(self, 1, function()
                self.skillCombineScript:UpdatePositionByNode(self._rootNode) -- 防止切换心法后轮盘错位
            end)
        end
    end

    if self.skillCombineScript then
        local bShowSlider = false
        if self.bWuDu then
            bShowSlider = self.skillCombineScript:InitPet()
        elseif self.tbPetSkillGroup then
            bShowSlider = self.skillCombineScript:InitPetSkill(self.tbPetSkillGroup)
        elseif self.tbPuppetSkillGroup then
            bShowSlider = self.skillCombineScript:InitPuppetSkill(self.tbPuppetSkillGroup, self.dwNpcTemplateID)
        elseif self.tbShadowSkillGroup then
            bShowSlider = self.skillCombineScript:InitShadowSkill(self.tbShadowSkillGroup)
        end
        self:OnPressUp(true)
        self.skillCombineScript:SetVisible(false)
        if self.cdScript then
            UIHelper.RemoveFromParent(self.cdScript._rootNode, true)
            self.cdScript = nil
        end

        if bShowSlider then
            self.cdScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCombineSlider, self._rootNode)
            self.skillCombineScript:ClearCDSlider()
            self.skillCombineScript:BindCDSlider(self.cdScript)
        end
        UIHelper.SetVisible(self.ImgSkillBg, not bShowSlider)
    end
    UIHelper.SetLongPressDelay(self.skillBtn, self.skillCombineScript and SHOW_COMBO_PRESS_TIME or SHOW_TIP_PRESS_TIME)
end

function UIWidgetSimpleSkill:ShowCannotCastTip()
    if self.bInCoolDown or self.bIsPassiveSkill then
        return
    end

    local nRespondCode = SkillData.GetCastSkillResult(g_pClientPlayer, self.nCurrentSkillID)
    local szMsg = FightLog.GetSkillRespondText(nRespondCode)
    if not self:IsJumpSkill() and not (g_pClientPlayer.dwForceID ~= FORCE_TYPE.TIAN_CE and g_pClientPlayer.bOnHorse) then
        if self.tDXSlotData.tbItemInfo and self.tDXSlotData.tbItemInfo.nGenre == ITEM_GENRE.EQUIPMENT then
            if not ItemData.HasItemInBox(INVENTORY_INDEX.EQUIP, self.tDXSlotData.data1, self.tDXSlotData.data2) then
                return TipsHelper.ShowNormalTip(g_tStrings.STR_USE_FAILED_NOT_EQUIPED)
            end
        end
        TipsHelper.ShowNormalTip(szMsg) -- 跳跃技能 or 非天策职业若在马上时不弹错误tips
    end
end

function UIWidgetSimpleSkill:UpdateIcon(szSkillIcon, szSliderIcon)
    if szSkillIcon then
        UIHelper.SetSpriteFrame(self.imgSkillIcon, szSkillIcon)
    end

    if szSliderIcon then
        UIHelper.SetSpriteFrame(self.SliderSkillSecond, szSliderIcon)
    end
end

function UIWidgetSimpleSkill:SetCDSlider(tCDSlider)
    if tCDSlider then
        table.insert(self.tCDSliders, tCDSlider)
    end
end

function UIWidgetSimpleSkill:ClearCDSlider()
    self.tCDSliders = {}
end

function UIWidgetSimpleSkill:HideSkillBg()
    UIHelper.SetVisible(self.ImgSkillBg, false)
end

return UIWidgetSimpleSkill
