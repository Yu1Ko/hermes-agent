-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetRightBottonFunction
-- Date: 2022-11-21 20:34:55
-- Desc: 主界面右下角功能按钮区域 WidgetRightBottonFunction
-- ---------------------------------------------------------------------------------

local UIWidgetRightBottonFunction = class("UIWidgetRightBottonFunction")

local DOUBLE_KEY_INTERVAL = 250

local TRANSFER_ID = 10023
local LKX_RETURBN_CITY_ID = 1007
local TRANSMISSION_POWER_ID = 10032

local TRANSPORT_SKILL_ID = 81
local LKX_RETURT_CITY_SKILL_ID = 26572
local TRANSMISSION_POWER_SKILL_ID = 35

function UIWidgetRightBottonFunction:OnEnter(bSelfieMode)
    self.bSelfieMode = bSelfieMode

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self:InitUI()

        if not self.bSelfieMode then
            FuncSlotMgr.Init()
        else
            FuncSlotMgr.InvokeFuncSlotChanged()
        end
    end
end

function UIWidgetRightBottonFunction:OnExit()
    self.bInit = false
    self:UnRegEvent()

    if not self.bSelfieMode then
        FuncSlotMgr.UnInit()
    end
    for _, tbSlot in ipairs(self.tbSlotData or {}) do
        local btn = tbSlot.btn
        if btn then
            UIHelper.UnBindUIEvent(btn, EventType.OnTouchBegan)
            UIHelper.UnBindUIEvent(btn, EventType.OnTouchEnded)
            UIHelper.UnBindUIEvent(btn, EventType.OnTouchCanceled)
            btn.fnOnDown = nil
            btn.fnOnUp = nil
        end
    end
end

function UIWidgetRightBottonFunction:BindUIEvent()
end

function UIWidgetRightBottonFunction:RegEvent()
    Event.Reg(self, EventType.OnMainViewButtonSlotClick, function(nSlotIndex, bIsDown)
        local tbSlot = self.tbSlotData[nSlotIndex]
        local btn = tbSlot and tbSlot.btn
        if bIsDown then
            local scriptView = tbSlot and tbSlot.scriptView
            local aniNode = btn and btn.aniNode
            UIHelper.StopAni(scriptView, aniNode, "AnicLick")
            UIHelper.PlayAni(scriptView, aniNode, "AnicLick")
        end
        self:OnBtnEvent(btn, bIsDown)
    end)

    Event.Reg(self, EventType.OnAutoDoubleSprint, function()
        if FuncSlotMgr._checkTeammate(1) then
            TipsHelper.ShowNormalTip("双人轻功已准备完毕，面朝目标并疾跑靠近即可自动开始双人轻功")
            self.bAutoDoubleSprint = true
        else
            TipsHelper.ShowNormalTip("请先选中目标并与目标组队")
        end
    end)

    Event.Reg(self, "UPDATE_SELECT_TARGET", function()
        if not self.bAutoDoubleSprint then
            return
        end

        if not FuncSlotMgr._checkTeammate(1) then
            TipsHelper.ShowNormalTip("目标丢失，双人轻功中止")
            self.bAutoDoubleSprint = false
        end
    end)

    Event.Reg(self, EventType.OnFuncSlotChanged, function(tbAction)
        self:UpdateBtnSlot(tbAction)
    end)

    Event.Reg(self, EventType.ON_CHANGE_DYNAMIC_SKILL_GROUP, function(bEnterDynamicSkills, nGroupID)
        self:UpdateHorseDynamicSkill(bEnterDynamicSkills, nGroupID)
    end)

    Event.Reg(self, EventType.OnPlayerSprintStateChanged, function()
        if SprintData.GetHasFightBtn() then
            FuncSlotMgr.InvokeFuncSlotChanged()
        end
    end)

    if not self.bSelfieMode then
        Event.Reg(self, EventType.OnShortcutInteractionMultiKeyDown, function(tbKeyNames, nKeybordLen)
            self:OnKeyEvent(tbKeyNames, true)
        end)

        Event.Reg(self, EventType.OnShortcutInteractionSingleKeyDown, function(szVKName)
            self:OnKeyEvent(szVKName, true)
        end)

        Event.Reg(self, EventType.OnShortcutInteractionMultiKeyUp, function(tbKeyNames, nKeybordLen)
            self:OnKeyEvent(tbKeyNames, false)
        end)

        Event.Reg(self, EventType.OnShortcutInteractionSingleKeyUp, function(szVKName)
            self:OnKeyEvent(szVKName, false)
        end)
    end
end

function UIWidgetRightBottonFunction:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

--更新槽位按钮
function UIWidgetRightBottonFunction:UpdateBtnSlot(tbAction)
    self:UpdateSpecState()

    local bHasFightBtn = false
    for nSlotIndex = 1, #self.tbSlotData do
        local tbSlot = self.tbSlotData[nSlotIndex]
        local btn = tbSlot.btn
        local tbBtnData = FuncSlotMgr.GetBtnDataBySlotIndex(nSlotIndex)

        tbBtnData = self:CheckReplaceBtnData(tbBtnData, nSlotIndex)

        local bBtnShow = self:CanBtnShow(tbBtnData, tbAction)
        local bBtnEnabled, szTips = self:CheckBtnEnabled(tbBtnData)

        if tbBtnData and tbBtnData.nBtnID == 1001 then
            bHasFightBtn = true
        end

        UIHelper.SetVisible(tbSlot.nodeSlot, bBtnShow)
        UIHelper.SetButtonState(btn, bBtnEnabled and BTN_STATE.Normal or BTN_STATE.Disable, szTips, false, false)
        UIHelper.SetNodeGray(tbSlot.imgIcon, not bBtnEnabled)
        UIHelper.SetColor(tbSlot.imgIcon, not bBtnEnabled and cc.c3b(155, 155, 155) or cc.c3b(255, 255, 255))

        if self.bHorseDynamicSkill and table.contain_value(self.tbHorseSkillSlotIndex, nSlotIndex) then
            UIHelper.SetVisible(tbSlot.nodeSlot, true)
            UIHelper.SetButtonState(btn, BTN_STATE.Normal)
        else
            local tbSkillScript = self.tbHorseDynamicScript[nSlotIndex]
            if tbSkillScript then
                -- tbSkillScript:SetSkillVisible(false)
                UIHelper.SetVisible(tbSkillScript._rootNode, false)
            end

        end


        -- 若按钮被置灰或隐藏，且正在被按下，则触发抬起事件
        if not bBtnShow or not bBtnEnabled then
            if btn.bWaitUp then
                if btn.fnOnUp then
                    btn.fnOnUp()
                end
            end
        end

        -- 解绑按钮事件
        btn.fnOnDown = nil
        btn.fnOnUp = nil
        btn.bWaitUp = false

        if tbSlot.nCDTimer then
            Timer.DelTimer(self, tbSlot.nCDTimer)
            tbSlot.nCDTimer = nil

            UIHelper.SetActiveAndCache(self, tbSlot.cdLabel, false)
            UIHelper.SetActiveAndCache(self, tbSlot.imgSkillCd, false)
        end


        if (tbBtnData and bBtnShow) then
            --绑定按钮事件并记录
            self:BindSlotBtnEvent(btn, nSlotIndex, tbBtnData.nEventType)
            ShortcutInteractionData.SetupSprintSlotInfo(nSlotIndex, tbBtnData)

            local szImgPath = tbBtnData.szImgPath

            --特殊处理，攻击键用widgetIcon显示，因为剑的图标会超出Mask
            if tbBtnData.nBtnID == 1001 then
                UIHelper.SetSpriteFrame(tbSlot.imgIcon, szImgPath)
                UIHelper.SetVisible(tbSlot.widgetIcon, true)
                UIHelper.SetVisible(tbSlot.maskIcon, false)
            else
                UIHelper.SetSpriteFrame(tbSlot.imgSkillIcon, szImgPath)
                UIHelper.SetVisible(tbSlot.widgetIcon, false)
                UIHelper.SetVisible(tbSlot.maskIcon, true)
            end

            self:UpdateBtnAnim(nSlotIndex)
            self:UpdateBtnOtherPerform(tbBtnData, nSlotIndex)

            if self:CheckAutoExecuteBtn(tbBtnData) then
                self:OnSlotButtonEvent(nSlotIndex)
            end
        else
            local szSlotAnim = "AniDaQingGongStop"
            local szIconAnim = "AniFunctionIconStop"
            self:PlayBtnAnim(nSlotIndex, szSlotAnim, szIconAnim)
            UIHelper.SetVisible(tbSlot.eff4, false)
        end
    end

    SprintData.SetHasFightBtn(bHasFightBtn)

    Event.Dispatch(EventType.OnShortcutInteractionChange)
end

--绑定槽位按钮事件
function UIWidgetRightBottonFunction:BindSlotBtnEvent(btn, nSlotIndex, nEventType)
    if nEventType == 1 then
        --Down
        btn.fnOnDown = function(bButton)
            self:OnSlotButtonEvent(nSlotIndex, nil, bButton)
        end
    elseif nEventType == 2 then
        --Up
        btn.fnOnUp = function(bButton)
            self:OnSlotButtonEvent(nSlotIndex, nil, bButton)
        end
    elseif nEventType == 3 then
        --Long Press
        btn.fnOnDown = function(bButton)
            btn.bWaitUp = true
            self:OnSlotButtonEvent(nSlotIndex, 1, bButton)
        end
        btn.fnOnUp = function(bButton)
            btn.bWaitUp = false
            self:OnSlotButtonEvent(nSlotIndex, 2, bButton)
        end
    end
end

--bButton 是否由按钮触发，false则为快捷键或手柄按键触发
function UIWidgetRightBottonFunction:OnBtnEvent(btn, bIsDown, bButton)
    if not btn or btn.nBtnState and btn.nBtnState ~= BTN_STATE.Normal then
        return
    end

    if bIsDown then
        if btn.fnOnDown then
            btn.fnOnDown(bButton)
        end
    else
        if btn.fnOnUp then
            btn.fnOnUp(bButton)
        end
    end
end

function UIWidgetRightBottonFunction:OnKeyEvent(tbKeyNames, bIsDown)
    if not ShortcutInteractionData.IsSprintState() then
        return
    end

    local szVKName
    if IsString(tbKeyNames) then
        if string.is_nil(tbKeyNames) then
            return
        end

        szVKName = tbKeyNames
        tbKeyNames = {szVKName}
    end

    if bIsDown then
        if szVKName then
            local nCurTime = GetTickCount()
            self.bDoubleClick = false
            if szVKName == self.szLastVKName and self.nLastKeyTime and nCurTime - self.nLastKeyTime < DOUBLE_KEY_INTERVAL then
                self.bDoubleClick = true
            end
            self:OnExecuteBinding({szVKName}, true)

            self.szLastVKName = szVKName
            self.nLastKeyTime = nCurTime
        else
            self:OnExecuteBinding(tbKeyNames, true)
        end
    else
        self:OnExecuteBinding(tbKeyNames, false)
    end
end

--保存各槽位信息
function UIWidgetRightBottonFunction:InitUI()
    local tbSlotData = {}
    local nIndex = 1
    while (self["FunctionSlot" .. nIndex]) do
        local nodeSlot = self["FunctionSlot" .. nIndex]
        UIHelper.RemoveAllChildren(nodeSlot)

        local nPrefabID = nIndex == 1 and PREFAB_ID.WidgetFunctionSlot1 or PREFAB_ID.WidgetFunctionSlot2
        local scriptView = UIHelper.AddPrefab(nPrefabID, nodeSlot)

        local btn = scriptView.BtnFunction
        assert(btn, "Can't find BtnFunction:" .. nIndex)
        local maskIcon = scriptView.MaskIcon
        assert(btn, "Can't find MaskIcon:" .. nIndex)
        local imgSkillIcon = scriptView.ImgFunctionIcon
        assert(imgSkillIcon, "Can't find ImgFunctionIcon:" .. nIndex)
        local widgetIcon = scriptView.WidgetFunctionIcon
        local imgIcon = scriptView.ImgFunctionIcon
        local imgSkillCd = scriptView.ImgSkillCd
        local cdLabel = scriptView.CdLabel

        local eff1 = scriptView.tbEffectNode[1]
        local eff2 = scriptView.tbEffectNode[2]
        local eff3 = scriptView.tbEffectNode[3]
        local eff4 = scriptView.tbEffectNode[4]

        btn.aniNode = scriptView._rootNode

        UIHelper.BindUIEvent(btn, EventType.OnTouchBegan, function(btn)
            UIHelper.StopAni(scriptView, btn.aniNode, "AnicLick")
            UIHelper.PlayAni(scriptView, btn.aniNode, "AnicLick")
            self:OnBtnEvent(btn, true, true)
        end)
        UIHelper.BindUIEvent(btn, EventType.OnTouchEnded, function(btn)
            self:OnBtnEvent(btn, false, true)
        end)
        UIHelper.BindUIEvent(btn, EventType.OnTouchCanceled, function(btn)
            if btn.nBtnState and btn.nBtnState ~= BTN_STATE.Normal then
                return
            end
            if btn.bWaitUp and btn.fnOnUp then
                btn.fnOnUp()
            end
        end)

        UIHelper.SetButtonClickSound(btn, "")

        local tbSlot = {
            scriptView = scriptView,
            nodeSlot = scriptView._rootNode,
            btn = btn,
            maskIcon = maskIcon,
            imgSkillIcon = imgSkillIcon,
            widgetIcon = widgetIcon,
            imgIcon = imgIcon,
            imgSkillCd = imgSkillCd,
            cdLabel = cdLabel,

            eff1 = eff1,
            eff2 = eff2,
            eff3 = eff3,
            eff4 = eff4,

            szSlotAnim = nil,
            szIconAnim = nil,
            nLastAnimPlayTime = nil,
            bDropFlag = false,
            bClickFlag = false,
            bDelayAnim = false,
            nTimerID = nil, --动画延迟播放TimerID
            nCDTimer = nil, --神行技能TimerID
        }
        tbSlotData[nIndex] = tbSlot
        nIndex = nIndex + 1
    end
    self.tbSlotData = tbSlotData

    --触发快捷键KeyID刷新
    if not self.bSelfieMode then
        Event.Dispatch(EventType.OnPrefabAdd, self._nPrefabID, self)
    end

    self:InitHorseDynamicSkillScript()

    UIHelper.SetCombinedBatchEnabled(self._rootNode, true)
end

--槽位按钮事件
function UIWidgetRightBottonFunction:OnSlotButtonEvent(nSlotIndex, nCommandIndex, bButton)
    nCommandIndex = nCommandIndex or 1

    local nCurrentTime = GetTickCount()
    if nCommandIndex == 1 and self.nClickCDTime and self.nClickCDTime > nCurrentTime then
        return
    end

    local tbBtnData = FuncSlotMgr.GetBtnDataBySlotIndex(nSlotIndex)
    tbBtnData = self:CheckReplaceBtnData(tbBtnData, nSlotIndex)
    if not tbBtnData then
        return
    end

    self.nClickCDTime = nCurrentTime + tbBtnData.nClickCD * 1000

    local szCommand = tbBtnData.tbCommand[nCommandIndex]
    LOG.INFO("点击按钮: %s (nBtnID: %d, szCommand: %s)", tbBtnData.szDesc, tbBtnData.nBtnID, szCommand or "")

    local tbSlot = self.tbSlotData[nSlotIndex]
    if tbBtnData.szDesc == "急降" then
        tbSlot.bDropFlag = true
        tbSlot.bDelayAnim = true
        SprintData.SetDropFlag(true) --急降标记，用于落地后自动停止轻功
    else
        tbSlot.bClickFlag = true
        SprintData.SetDropFlag(false) --清空急降标记，急降后再点击其他轻功按钮，再落地之后就不自动停止轻功了
    end

    --TODO 可配置参数?
    FuncSlotMgr.ExecuteCommand(szCommand, bButton)
end

--按钮是否需要显示
function UIWidgetRightBottonFunction:CanBtnShow(tbBtnData, tbAction)
    if not tbBtnData then
        return
    end

    local player = GetClientPlayer()
    if not player then
        return
    end

    if table.contain_value(tbBtnData.tbCommand or {}, "Drop") and tbBtnData.tbKeyInfo and tbBtnData.tbKeyInfo.szKeyDesc == "Ctrl" then
        --特殊处理：战斗状态下不显示通用急降按钮
        if player.bFightState then
            return false
        end

        --特殊处理，存在门派急降时，不显示通用急降
        if self.bNotShowDrop then
            return false
        end
    end

    -- --特殊处理，在地面时不显示退出轻功，通过松开摇杆退出
    -- if table.contain_value(tbBtnData.tbCommand or {}, "EndSprint") and player.nJumpCount == 0 then
    --     return false
    -- end

    --特殊处理 连冲和续飞仅在切入前显示
    if tbBtnData.szDesc == "连冲" or tbBtnData.szDesc == "续飞" then
        -- 一苇渡江·一段 -> szSprintName = "一苇渡江", nSprintPhase = 1, szSprintType = ""
        -- 一苇渡江·莲台二段 -> szSprintName = "一苇渡江", nSprintPhase = 2, szSprintType = "莲台"
        if tbAction and tbAction.szSprintType and tbAction.szSprintType ~= "" then
            return false
        end
    end

    -- 特殊处理 VKPC端，若已有急坠按钮，则不显示续轻功按钮，避免快捷键冲突
    if tbBtnData.nBtnID == 1014 and (Platform.IsWindows() or Platform.IsMac()) then
        if self.bNotShowReSprint then
            return false
        end
    end

    --特殊处理 翻越需要设置打开才显示
    if tbBtnData.nBtnID == 64 and not GameSettingData.GetNewValue(UISettingKey.CrossTerrain) then
        --切入5.0翻越
        return false
    end

    --特殊处理 滑行需要设置打开才显示
    if tbBtnData.nBtnID == 72 and not GameSettingData.GetNewValue(UISettingKey.Gliding) then
        --切入滑行
        return false
    end

    --特殊处理 双人同骑
    if tbBtnData.nBtnID == 10040 then
        -- --判断是否选中玩家
        -- local dwTargetType, dwTargetID = player.GetTarget()
        -- if dwTargetType ~= TARGET.PLAYER or dwTargetID == player.dwID then
        --     return false
        -- end

        --判断坐骑是否可双人同骑
        local item = player.GetEquippedHorse()
        if item then
            local baseAttib = item.GetBaseAttrib()
            for _, v in pairs(baseAttib) do
                local nID = v.nID
                local nValue1 = v.nValue1 or v.nMin
                local nValue2 = v.nValue2 or v.nMax
                if nID == ATTRIBUTE_TYPE.ENABLE_DOUBLE_RIDE then
                    return true
                end
            end
            local magicAttib = item.GetMagicAttrib()
            for _, v in pairs(magicAttib) do
                local nID = v.nID
                local nValue1 = v.nValue1 or v.Param0
                local nValue2 = v.nValue2 or v.Param2
                if nID == ATTRIBUTE_TYPE.ENABLE_DOUBLE_RIDE then
                    return true
                end
            end
        end
        return false
    end

    return true
end

function UIWidgetRightBottonFunction:UpdateSpecState()
    self.bNotShowDrop = false --特殊处理，存在门派急降时，不显示通用急降；这里判断是否存在门派急降，并记录状态
    self.bNotShowReSprint = false --特殊处理，存在急坠时，VKPC不显示续轻功；这里判断是否存在急坠，并记录状态
    for nSlotIndex = 1, #self.tbSlotData do
        local tbSlot = self.tbSlotData[nSlotIndex]
        local tbBtnData = FuncSlotMgr.GetBtnDataBySlotIndex(nSlotIndex)
        if tbBtnData then
            if tbBtnData.nBtnID == 15 then
                self.bNotShowDrop = true
            elseif tbBtnData.nBtnID == 62 then
                self.bNotShowReSprint = true
            end
        end
    end
end

function UIWidgetRightBottonFunction:CheckReplaceBtnData(tbBtnData, nSlotIndex)
    local player = GetClientPlayer()
    if not player then
        return
    end

    -- --简化轻功，自动添加攻击键
    -- local bAutoFly = player.nMoveState == MOVE_STATE.ON_AUTO_FLY or player.nMoveState == MOVE_STATE.ON_START_AUTO_FLY
    -- if not tbBtnData and nSlotIndex == 1 and self:IsSimpleSprintMode(true) and not bAutoFly then
    --     tbBtnData = FuncSlotMgr.GetBtnData(1001)
    -- end

    if not tbBtnData then
        return
    end

    --自动前进相关按钮替换处理
    if tbBtnData.nBtnID == 10021 and SprintData.GetAutoForward() then
        tbBtnData = FuncSlotMgr.GetBtnData(10022)
    end

    --根据设置将续飞和连冲相互切换
    local szReFly = GameSettingType.SpecialSprint.ReFly.szDec
    local szDash = GameSettingType.SpecialSprint.Dash.szDec
    if tbBtnData.szDesc == szReFly or tbBtnData.szDesc == szDash then
        local szSpecialSprint = GameSettingData.GetNewValue(UISettingKey.SpecialSprint).szDec
        if tbBtnData.szDesc ~= szSpecialSprint then
            if szSpecialSprint == GameSettingType.SpecialSprint.None.szDec then
                return
            elseif szSpecialSprint == szReFly then
                tbBtnData = FuncSlotMgr.GetBtnData(1013) --续飞
            elseif szSpecialSprint == szDash then
                tbBtnData = FuncSlotMgr.GetBtnData(10111) --连冲
            end
        end
    end

    --根据设置将门派急降替换为通用急降
    local szSprintMode = GameSettingData.GetNewValue(UISettingKey.SprintMode).szDec
    if tbBtnData.szDesc == "急降" and szSprintMode ~= GameSettingType.SprintMode.Common.szDec then
        local szSprinDrop = GameSettingData.GetNewValue(UISettingKey.SprintDrop).szDec
        if szSprinDrop == GameSettingType.SprintDrop.Common.szDec and not table.contain_value(tbBtnData.tbCommand or {}, "Drop") then
            tbBtnData = clone(tbBtnData)
            tbBtnData.tbCommand = {"Drop"}
        end
    end

    --明教简化轻功，按钮文本修改
    if tbBtnData.nBtnID == 1010 and self:IsSimpleSprintMode() then
        if player then
            if player.nJumpCount == 1 then
                tbBtnData.szDesc = "一段"
            elseif player.nJumpCount == 2 then
                tbBtnData.szDesc = "二段"
            elseif player.nJumpCount == 3 then
                tbBtnData.szDesc = "三段"
            elseif player.nJumpCount == 4 then
                tbBtnData.szDesc = "四段"
            end
        end
    end

    return tbBtnData
end

function UIWidgetRightBottonFunction:CheckAutoExecuteBtn(tbBtnData)
    if not tbBtnData then
        return false
    end

    --暂不支持长按类型

    --双人轻功相关按钮自动点击处理
    if tbBtnData.nBtnID == 7 and self.bAutoDoubleSprint then
        self.bAutoDoubleSprint = false
        return true
    end

    return false
end

--按钮置灰
function UIWidgetRightBottonFunction:CheckBtnEnabled(tbBtnData)
    if not tbBtnData then
        return false
    end

    local player = GetClientPlayer()
    if not player then
        return false
    end

    --轻功时攻击键置灰
    if tbBtnData.nBtnID == 1001 then
        if player.bSprintFlag then
            return false
        end
    end

    --无法使用轻功的地图置灰
    if tbBtnData.nBtnID == 1002 then
        local tbMapParams = MapHelper.GetMapParams()
        if not tbMapParams.bCanSprint then
            return false, "当前场景无法使用轻功"
        end
    end

    --空中打坐、骑马、神行置灰
    if tbBtnData.nBtnID == 1003 or tbBtnData.nBtnID == 1005 or tbBtnData.nBtnID == 10023 then
        if player.nJumpCount > 0 then
            return false
        end
    end

    --特殊处理，奇趣坐骑的轻功和下马牵行不可操作时置灰
    if tbBtnData.nBtnID == 1002 or tbBtnData.nBtnID == 10041 then
        local item = g_pClientPlayer.GetEquippedHorse()
        if item then
            local tHorse1002 = GetTableFromSpecial(tSpecialHorse[item.dwIndex])
            local tHorse10041 = tSpecialHorse[item.dwIndex] or tCampHorse[item.dwIndex]
            if tHorse1002 and tbBtnData.nBtnID == 1002 and g_pClientPlayer.bOnHorse then
                return tHorse1002.bSprint
            elseif tHorse10041 and tbBtnData.nBtnID == 10041 then
                return false
            end
        end
    end

    --特殊处理 双人同骑时，双人同骑按钮置灰
    if tbBtnData.nBtnID == 10040 then
        if player.nFollowType == FOLLOW_TYPE.RIDE then
            return false
        end
    end

    --特殊处理 传功按钮未选中玩家时置灰
    if tbBtnData.nBtnID == TRANSMISSION_POWER_ID then
        local dwTargetType, dwTargetID = player.GetTarget()
        if dwTargetType ~= TARGET.PLAYER or dwTargetID == player.dwID then
            if dwTargetType == TARGET.NO_TARGET then
                return false, g_tStrings.STR_ERROR_SKILL_NO_TARGET
            else
                return false, g_tStrings.STR_ERROR_SKILL_INVALID_TARGET
            end
        end
    end

    return true
end

function UIWidgetRightBottonFunction:UpdateBtnAnim(nSlotIndex)
    local tbSlot = self.tbSlotData[nSlotIndex]
    if not tbSlot then
        return
    end

    local player = GetClientPlayer()
    if not player then
        return
    end

    local szSlotAnim = "AniDaQingGongStop"
    local szIconAnim = "AniFunctionIconStop"

    --TODO 根据按钮ID或类型播放对应动画
    if nSlotIndex == 5 and player.bSprintFlag and player.nMoveState ~= MOVE_STATE.ON_SPRINT_BREAK then
        if tbSlot.bClickFlag then
            szSlotAnim = "AniDaQingGong02"
            tbSlot.bClickFlag = false
        elseif tbSlot.bDropFlag then
            szSlotAnim = "AniDaQingGong03"
            tbSlot.bDropFlag = false
        elseif player.nMoveState == MOVE_STATE.ON_RUN then
            szSlotAnim = "AniDaQingGong01"
        end
        szIconAnim = "AniFunctionIconLoop"
    end

    Timer.DelTimer(self, tbSlot.nTimerID)
    if tbSlot.bDelayAnim then
        --急降之后右下角按钮会隐藏一会，这里动画也延迟一点播放
        tbSlot.bDelayAnim = false
        tbSlot.nTimerID = Timer.Add(self, 0.2, function()
            self:PlayBtnAnim(nSlotIndex, szSlotAnim, szIconAnim)
        end)
    else
        self:PlayBtnAnim(nSlotIndex, szSlotAnim, szIconAnim)
    end
end

function UIWidgetRightBottonFunction:PlayBtnAnim(nSlotIndex, szSlotAnim, szIconAnim)
    local tbSlot = self.tbSlotData[nSlotIndex]
    if not tbSlot then
        return
    end

    --动画播放CD，防止动画快速切换时闪烁
    local nCurrentTime = GetTickCount()
    local bReplaySlotAnim = not tbSlot.nLastAnimPlayTime or nCurrentTime - tbSlot.nLastAnimPlayTime > 300 --动画播放CD，防止动画快速切换时闪烁
    tbSlot.nLastAnimPlayTime = nCurrentTime

    if tbSlot.szSlotAnim ~= szSlotAnim or bReplaySlotAnim then
        UIHelper.StopAni(tbSlot.scriptView, tbSlot.nodeSlot, tbSlot.szSlotAnim)
        UIHelper.PlayAni(tbSlot.scriptView, tbSlot.nodeSlot, szSlotAnim, function()
            if tbSlot and szSlotAnim == "AniDaQingGongStop" then
                UIHelper.SetVisible(tbSlot.eff1, tbSlot.szIconAnim == "AniFunctionIconLoop") --特殊处理，Icon动画循环时使Eff1保持高亮
            end
        end)
    else
        UIHelper.SetVisible(tbSlot.eff1, szIconAnim == "AniFunctionIconLoop")
    end

    if tbSlot.szIconAnim ~= szIconAnim then
        UIHelper.StopAni(tbSlot.scriptView, tbSlot.imgSkillIcon, tbSlot.szIconAnim)
        UIHelper.PlayAni(tbSlot.scriptView, tbSlot.imgSkillIcon, szIconAnim)
    end

    tbSlot.szSlotAnim = szSlotAnim
    tbSlot.szIconAnim = szIconAnim
end

function UIWidgetRightBottonFunction:UpdateBtnOtherPerform(tbBtnData, nSlotIndex)
    local tbSlot = self.tbSlotData[nSlotIndex]
    if not tbSlot then
        return
    end

    if not g_pClientPlayer then
        return
    end

    --神行/浪客行回城/传功CD显示
    if tbBtnData.nBtnID == TRANSFER_ID or tbBtnData.nBtnID == LKX_RETURBN_CITY_ID or tbBtnData.nBtnID == TRANSMISSION_POWER_ID then
        local fnUpdate = function()
            if not g_pClientPlayer then
                return
            end

            local nSkillID
            if tbBtnData.nBtnID == TRANSFER_ID then
                nSkillID = TRANSPORT_SKILL_ID
            elseif tbBtnData.nBtnID == LKX_RETURBN_CITY_ID then
                nSkillID = LKX_RETURT_CITY_SKILL_ID
            elseif tbBtnData.nBtnID == TRANSMISSION_POWER_ID then
                nSkillID = TRANSMISSION_POWER_SKILL_ID
            end

            local nSkillLevel = g_pClientPlayer.GetSkillLevel(nSkillID)
            local _, nLeft, nTotal = Skill_GetCDProgress(nSkillID, nSkillLevel, nil, g_pClientPlayer)
            nLeft = nLeft / GLOBAL.GAME_FPS
            nTotal = nTotal / GLOBAL.GAME_FPS

            local bCool = nLeft > 0 or nTotal > 0
            local fPercent = nTotal ~= 0 and nLeft / nTotal or 0
            if nLeft ~= tbBtnData.cacheTime then
                UIHelper.SetProgressBarPercent(tbSlot.imgSkillCd, fPercent * 100)
                UIHelper.SetString(tbSlot.cdLabel, UIHelper.GetSkillCDText(nLeft, true))
                tbBtnData.cacheTime = nLeft
            end
            UIHelper.SetActiveAndCache(self, tbSlot.cdLabel, bCool)
            UIHelper.SetActiveAndCache(self, tbSlot.imgSkillCd, bCool)
        end
        fnUpdate()
        tbSlot.nCDTimer = Timer.AddFrameCycle(self, 2, fnUpdate)
    end

    --骑马进战提示下马特效
    local bShowEff4 = false
    if tbBtnData.nBtnID == 23 then
        bShowEff4 = g_pClientPlayer.bFightState and g_pClientPlayer.dwSchoolID ~= SCHOOL_TYPE.TIAN_CE
    end
    UIHelper.SetVisible(tbSlot.eff4, bShowEff4)
end

--坐骑的动态技能固定加载在上面四个(6,7,8,9)槽位上
function UIWidgetRightBottonFunction:UpdateHorseDynamicSkill(bEnterDynamicSkills, nGroupID)
    self.tbHorseSkillSlotIndex = {}
    if QTEMgr.IsHorseDynamic(nGroupID) and bEnterDynamicSkills then
        self.bHorseDynamicSkill = bEnterDynamicSkills
        if QTEMgr.IsInDynamicSkillState() and (QTEMgr.CanCastSkill() or QTEMgr.IsHorseDynamic()) then
            local tSkillInfo = self:GetHorseDynamicSkill()
            local nIndex = 1
            for nSlotIndex = 6, #self.tbSlotData do
                local tbSkillInfo = tSkillInfo[nIndex]
                local tbSkillScript = self.tbHorseDynamicScript[nSlotIndex]
                if tbSkillInfo and tbSkillScript then
                    tbSkillScript:SwitchDynamicSkills(bEnterDynamicSkills, tbSkillInfo)
                    UIHelper.SetVisible(tbSkillScript._rootNode, true)
                    tbSkillScript:SetSkillVisible(true)
                    table.insert(self.tbHorseSkillSlotIndex, nSlotIndex)
                end

                UIHelper.SetVisible(self.tbSlotData[nSlotIndex].nodeSlot, tbSkillInfo and true or false)
                local widgetFunction = self.tbSlotData[nSlotIndex].nodeSlot:getChildByName("WidgetFunction")
                UIHelper.SetVisible(widgetFunction, not (tbSkillInfo and true or false))
                nIndex = nIndex + 1
            end
        end
    elseif self.bHorseDynamicSkill then
        self.bHorseDynamicSkill = false
        for nSlotIndex = 6, #self.tbSlotData do
            local scriptView = self.tbHorseDynamicScript[nSlotIndex]
            if scriptView then
                UIHelper.SetVisible(scriptView._rootNode, false)
                scriptView:SetSkillVisible(false)
            end
            UIHelper.SetVisible(self.tbSlotData[nSlotIndex].nodeSlot, false)
            local widgetFunction = self.tbSlotData[nSlotIndex].nodeSlot:getChildByName("WidgetFunction")
            UIHelper.SetVisible(widgetFunction, true)
            UIHelper.SetButtonState(self.tbSlotData[nSlotIndex].btn, BTN_STATE.Disable)
        end
    end
end

function UIWidgetRightBottonFunction:InitHorseDynamicSkillScript()
    self.tbHorseDynamicScript = {}
    local nIndex = SKILL_SLOT_ENUM.HorseSkillSlot1
    for nSlotIndex = 6, #self.tbSlotData do
        local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetNormalSkill, self.tbSlotData[nSlotIndex].nodeSlot, nIndex, nil, -1, false, false, nil, nil, nil)

        local scriptMainCity = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
        local scriptCancel = scriptMainCity:GetSkillCanCelScript()
        local scriptDirection = scriptMainCity:GetSkillDirectionScript()

        scriptView:SetSkillCancelCtrl(scriptCancel)
        scriptView:SetSkillDirectionCtrl(scriptDirection)
        scriptView:SetHorseDynamicSkill(true)
        -- UIHelper.SetVisible(scriptView._rootNode, false)
        scriptView:SetSkillVisible(false)

        self.tbHorseDynamicScript[nSlotIndex] = scriptView
        nIndex = nIndex + 1
    end
end

function UIWidgetRightBottonFunction:GetHorseDynamicSkill()
    local nSKillCount = QTEMgr.GetDynamicSkillCount()
    local tSkillInfo = {}
    for nIndex = 1, nSKillCount do
        local skillInfo = QTEMgr.GetDynamicSkillData(nIndex)
        --关于下马的技能要屏蔽掉，使用统一的槽位交互
        if skillInfo.id ~= 9020 and skillInfo.id ~= 22023 then
            table.insert(tSkillInfo, skillInfo)
        end
    end

    return tSkillInfo
end

function UIWidgetRightBottonFunction:IsSimpleSprintMode(bIncludeCommon)
    local szSprintMode = GameSettingData.GetNewValue(UISettingKey.SprintMode).szDec
    return szSprintMode == GameSettingType.SprintMode.Simple.szDec or (bIncludeCommon and szSprintMode == GameSettingType.SprintMode.Common.szDec)
end

function UIWidgetRightBottonFunction:OnExecuteBinding(tbKeyNames, bDown)
    --print("[Sprint] OnExecuteBinding", szName, bDown, self.bDoubleClick)
    for nSlotIndex = 1, #self.tbSlotData do
        local tbSlot = self.tbSlotData[nSlotIndex]
        local btn = tbSlot and tbSlot.btn
        local tbBtnData = FuncSlotMgr.GetBtnDataBySlotIndex(nSlotIndex)
        tbBtnData = self:CheckReplaceBtnData(tbBtnData, nSlotIndex)

        local tbKeyInfo = tbBtnData and tbBtnData.tbKeyInfo
        if tbKeyInfo then
            local szKeyName = ShortcutInteractionData.GetKeyByDXBinding(tbKeyInfo.szKeyName)
            local tbTargetKeys = string.split(szKeyName, "+")
            local nKeyState = tbKeyInfo.nKeyState

            if self:CheckKeyMatch(tbTargetKeys, tbKeyNames) then

                local function _onBtnEvent()
                    UIHelper.StopAni(tbSlot.scriptView, btn.aniNode, "AnicLick")
                    UIHelper.PlayAni(tbSlot.scriptView, btn.aniNode, "AnicLick")
                    if tbBtnData.nEventType == 1 then
                        self:OnBtnEvent(btn, true)
                    elseif tbBtnData.nEventType == 2 then
                        self:OnBtnEvent(btn, false)
                    elseif tbBtnData.nEventType == 3 then
                        self:OnBtnEvent(btn, bDown)
                    end
                end

                --0: Down, 1: Up, 2:Double down, 3: Double Up, -1: Other
                if bDown and self.bDoubleClick and nKeyState == 2 then
                    _onBtnEvent()
                elseif not bDown and self.bDoubleClick and nKeyState == 3 then
                    _onBtnEvent()
                elseif bDown and nKeyState == 0 then
                    _onBtnEvent()
                elseif not bDown and nKeyState == 1 then
                    _onBtnEvent()
                elseif nKeyState == -1 then
                    _onBtnEvent()
                end
            end
        end
    end
end


function UIWidgetRightBottonFunction:CheckKeyMatch(tbTargetKeys, tbSrcKeys)
    if tbTargetKeys == nil then
        return false
    end
    local nTargetLen = table.get_len(tbTargetKeys)
    local nSrcLen = table.get_len(tbSrcKeys)
    if nTargetLen == nSrcLen then
        for k, v in pairs(tbTargetKeys) do
            if not table.contain_value(tbSrcKeys, v) then
                return false
            end
        end
    else
        return false
    end
    return true
end

return UIWidgetRightBottonFunction
