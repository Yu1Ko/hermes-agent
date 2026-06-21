-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: QTEMgr
-- Date: 2023-01-04 11:12:19
-- Desc: ?
-- ---------------------------------------------------------------------------------

QTEMgr = QTEMgr or {className = "QTEMgr"}
local self = QTEMgr
-------------------------------- 消息定义 --------------------------------
QTEMgr.Event = {}
QTEMgr.Event.XXX = "QTEMgr.Msg.XXX"

local m_tbDynamicSkills = {}
local tbPetSkill = {
    id = 16048,
    level = 1
}

--非人哉特殊处理
--有一些动态技能要隐藏主界面交互键
local tbHideActionDynamicSkillID = {
    1183,1194,1195,1196,1197,
}

function QTEMgr.Init()
    self.bCanCastSkill = true
    self.bCanUserChange = false
    self.bCanJump = true

    Event.Reg(self, EventType.OnClientPlayerEnter, function()--进入场景自动进入动态技能状态
        local nNowGroupID = g_pClientPlayer.GetDynamicSkillGroup()
        if self.nCurGroupID ~= 0 and nNowGroupID ~= self.nCurGroupID then
            self.OnSwitchDynamicSkillState(false, self.nCurGroupID)
        end
        if nNowGroupID ~= 0 and nNowGroupID ~= self.nCurGroupID then
            self.OnSwitchDynamicSkillState(true, 0, nNowGroupID)
        end
    end)

    Event.Reg(self, "ON_SKILL_REPLACE", function(arg0, arg1, arg2)
        self.ON_CHANGE_SKILL(arg0, arg1, arg2)
    end)

    Event.Reg(self, "CHANGE_SKILL_ICON", function(nOldSkillID, nSkillID, nBuffID, nBuffLevel)
        self.ON_CHANGE_SKILL(nOldSkillID, nSkillID)
    end)

    Event.Reg(self, "DO_SKILL_CAST", function(dwCaster, dwSkillID, dwLevel)
        self.OnCastSkillRespond(dwSkillID)
    end)
    Event.Reg(self, "DO_SKILL_CHANNEL_PROGRESS", function(nTotalFrame, dwSkillID, dwLevel, dwCasterID)
        self.OnCastSkillRespond(dwSkillID)
    end)
    Event.Reg(self, "DO_SKILL_PREPARE_PROGRESS", function(nTotalFrame, dwSkillID, dwLevel, dwCasterID)
        self.OnCastSkillRespond(dwSkillID)
    end)
    Event.Reg(self, "DO_SKILL_HOARD_PROGRESS", function(nTotalFrame, dwSkillID, dwLevel, dwPlayerID)
        if g_pClientPlayer and g_pClientPlayer.dwID == dwPlayerID then
            self.OnCastSkillRespond(dwSkillID)
        end
    end)

    Event.Reg(self, "DYNAMIC_SKILL_HIGHLIGHT_CHANGED", function(nIndex, bHighlight)
        local tbSkillInfo = self.GetDynamicSkillData(nIndex)
        if tbSkillInfo then
            Event.Dispatch(EventType.ON_DYNAMIC_BUTTON_HIGHLIGHT, tbSkillInfo.id, bHighlight)
        end
    end)
end

function QTEMgr.UnInit()

end

function QTEMgr.OnLogin()

end

function QTEMgr.OnFirstLoadEnd()

end

---self.tbSlotInfo:存储当前提示按键数据
function QTEMgr.GetMainCityQTESlotInfo()
    return self.tbSlotInfo
end

function QTEMgr.SetData(tbData)

    self.ClearAllSlotInfo()
    self._updateMainCityQTESlotInfo(tbData)
    Event.Dispatch(EventType.ON_QTEPANEL_SHOW)

    for index, tbSkillInfo in ipairs(self.tbSlotInfo) do
        local nSlotIndex = tbSkillInfo.nSlotIndex
        Event.Dispatch(EventType.ON_DYNAMIC_BUTTON_HIGHLIGHT, tbSkillInfo.nSkillID, true)
        local nTotalTime = math.ceil(tbSkillInfo.nTotalTime / 1000)
        local nTimer = Timer.Add(self, nTotalTime, function()
            self.RemoveSkillSlotInfoBySlotIndex(nSlotIndex)
        end)
        table.insert(self.tbTimer, nTimer)
    end
end

function QTEMgr.RemoveSkillSlotInfoBySlotIndex(nSlotIndex)
    for index, tbSkillInfo in ipairs(self.tbSlotInfo) do
        if tbSkillInfo.nSlotIndex == nSlotIndex then
            table.remove(self.tbSlotInfo, index)
            Event.Dispatch(EventType.ON_DYNAMIC_BUTTON_HIGHLIGHT, tbSkillInfo.nSkillID, false)
            break
        end
    end
    Timer.DelTimer(self, self.tbTimer[nSlotIndex])
    table.remove(self.tbTimer, nSlotIndex)
end

function QTEMgr.ClearAllSlotInfo()
    if self.tbSlotInfo then
        for nSlotIndex, tbSkillInfo in ipairs(self.tbSlotInfo) do
            Event.Dispatch(EventType.ON_DYNAMIC_BUTTON_HIGHLIGHT, tbSkillInfo.nSkillID, false)
        end
    end

    if self.tbTimer then
        for index, nTimer in ipairs(self.tbTimer) do
            Timer.DelTimer(self, nTimer)
        end
    end
    self.tbTimer = {}
end



--进入动态技能组
function QTEMgr.OnSwitchDynamicSkillState(bEnter, dwOldGroupID, dwNowGroupID, dwGroupType)
    if table.contain_value(tbHideActionDynamicSkillID, dwNowGroupID) then
        Event.Dispatch(EventType.ON_ENTER_HIDE_ACTION_DYNAMIC_SKILL, true)
    elseif table.contain_value(tbHideActionDynamicSkillID, dwOldGroupID) then
        Event.Dispatch(EventType.ON_ENTER_HIDE_ACTION_DYNAMIC_SKILL, false)
    end

    if dwNowGroupID == 10001 then
        self.nCurGroupID = dwNowGroupID
        self.bCanCastSkill = false
        BahuangData.EnterBahuangDynamic()
        return
    end
    if dwOldGroupID == 10001 then
        self.nCurGroupID = 0
        BahuangData.ExitBahuangDynamic()
        self.bCanCastSkill = true
        return
    end

    if dwNowGroupID == 10002 then
        self.nCurGroupID = dwNowGroupID
        self.bCanCastSkill = false
        TreasureBattleFieldSkillData.EnterDynamic()
        return
    end
    if dwOldGroupID == 10002 then
        self.nCurGroupID = 0
        TreasureBattleFieldSkillData.ExitDynamic()
        self.bCanCastSkill = true
    end

    if dwNowGroupID == 10003 then
        self.nCurGroupID = dwNowGroupID
        self.bCanCastSkill = false
        TreasureBattleFieldSkillData.EnterDynamic(true)
        return
    end
    if dwOldGroupID == 10003 then
        self.nCurGroupID = 0
        TreasureBattleFieldSkillData.ExitDynamic()
        self.bCanCastSkill = true
        if not dwNowGroupID or dwNowGroupID == 0 then
            return
        end
    end

    if bEnter then
        self.nCurGroupID = dwNowGroupID
        self._updateDynamicSkillData(dwNowGroupID)
    else
        self.nCurGroupID = 0
        self._updateDynamicSkillData()
    end
    if dwNowGroupID == 914 or dwOldGroupID == 914 or dwNowGroupID == 1108 or dwOldGroupID == 1108 then
        local func = bEnter and function() UIMgr.Open(VIEW_ID.PanelPlayZheng) end or function() UIMgr.Close(VIEW_ID.PanelPlayZheng) end
        func()
    else
        local bFight = (bEnter and not self.IsHorseDynamic()) or (g_pClientPlayer and g_pClientPlayer.bFightState)
        SprintData.SetViewState(not bFight, true)
        Event.Dispatch(EventType.ON_CHANGE_DYNAMIC_SKILL_GROUP, bEnter, self.nCurGroupID)
    end
end


--进入动态技能组(假动态技能)
function QTEMgr.OnSwitchDynamicSkillStateBySkills(tbSkills)
    local bEnter = tbSkills ~= nil
    if bEnter then
        self.nCurGroupID = 1
        self._updateDynamicSkillDataBySkills(tbSkills)
    else
        self.nCurGroupID = 0
        self._updateDynamicSkillDataBySkills()
    end
    local bFight = bEnter or (g_pClientPlayer and g_pClientPlayer.bFightState)
    SprintData.SetViewState(not bFight, true)
    Event.Dispatch(EventType.ON_CHANGE_DYNAMIC_SKILL_GROUP, bEnter)
end

function QTEMgr.GetCurGroupID()
    return self.nCurGroupID
end

function QTEMgr.IsInDynamicSkillState()
    return self.nCurGroupID and self.nCurGroupID ~= 0
end

function QTEMgr.IsInDynamicSkillStateBySkills()
    return self.nCurGroupID and self.nCurGroupID == 1
end

function QTEMgr.IsInXunBaoState()
    return self.nCurGroupID and self.nCurGroupID == 10003
end

function QTEMgr.ExitDynamicSkillState(bShowConfirm)
    local funcExit = function()
        local player = g_pClientPlayer
        if player then
            player.SetDynamicSkillGroup(0)

            if player.GetWeaponSkillGroup() > 0 then
                player.SetWeaponSkillGroup(0)
            end
        end
    end
    if bShowConfirm == nil then bShowConfirm = true end
    local szExitText = self.GetCanExitText()
    if szExitText ~= "" and bShowConfirm then
        UIHelper.ShowConfirm(UIHelper.GBKToUTF8(szExitText), function()
            funcExit()
        end)
    else
        funcExit()
    end
end

function QTEMgr.GetCanExitText()
    if self.nCurGroupID then
        local tbInfo = g_tTable.DynamicSkill:Search(self.nCurGroupID)
        return tbInfo.szCancel
    end
    return ""
end

function QTEMgr.GetDynamicSkillData(nSlotIndex)
    return m_tbDynamicSkills[nSlotIndex]
end

function QTEMgr.GetDynamicSkillCount()
    return #m_tbDynamicSkills
end

---动态技能是否可以和其它技能键共存
function QTEMgr.CanCastSkill()
    if self.IsInDynamicSkillState() then
        return self.bCanCastSkill
    else
        return true
    end
end

function QTEMgr.IsHorseDynamic(nGroupID)
    local nCurGroupID = nGroupID or self.nCurGroupID
    return QTEMgr.IsDynamicSkillGroupType(nCurGroupID, "Horse")
end

function QTEMgr.CanUserChange()--用户是否可以主动退出动态技能
    return self.bCanUserChange or false
end


function QTEMgr.CanJump()
    return self.bCanJump
end


function QTEMgr.ON_CHANGE_SKILL(nOldSkillID, nSkillID, nSkillLevel)

    if not self.IsInDynamicSkillState() then return end
    nSkillLevel = nSkillLevel or g_pClientPlayer.GetSkillLevel(nSkillID)
    if nSkillLevel == 0 then nSkillLevel = 1 end

    local nSkillIndex = 0
    for nIndex, tbSkill in ipairs(m_tbDynamicSkills) do
        if tbSkill.id == nOldSkillID then
            tbSkill.id = nSkillID
            tbSkill.level = nSkillLevel
            self._collectSkillInfo(tbSkill)
            nSkillIndex = nIndex
        end
    end

    Event.Dispatch(EventType.ON_DYNAMIC_SKILL_CHANGE, nOldSkillID, nSkillIndex)

end

function QTEMgr._collectSkillInfo(tbSkill)
    tbSkill.szImgPath = TabHelper.GetSkillIconPathByIDAndLevel(tbSkill.id, tbSkill.level)
    tbSkill.callback = function()
        local player = g_pClientPlayer
        if player then
            SkillData.SetCastPointToTargetPos()
            local nMask = (tbSkill.id * (tbSkill.id % 10 + 1))
            OnUseSkill(tbSkill.id, nMask, nil, nil, self.bCanCastSkill)
        end
    end
end


function QTEMgr._updateDynamicSkillDataBySkills(tbSKillInfo)
    Timer.DelAllTimer(self)

    if not tbSKillInfo then
        m_tbDynamicSkills = {}
        self.bCanCastSkill = true
        self.bCanUserChange = false
        self.bCanJump = true
        return
    end

    m_tbDynamicSkills = {}
    self.bCanCastSkill = tbSKillInfo.CanCastSkill
    self.bCanUserChange = tbSKillInfo.canuserchange--用户是否可以主动退出动态技能


    self._getSkillData(tbSKillInfo.tbSkilllist)
end


function QTEMgr._updateDynamicSkillData(dwGroupID)
    Timer.DelAllTimer(self)

    if not dwGroupID then
        self.ClearAllSlotInfo()
        m_tbDynamicSkills = {}
        self.bCanCastSkill = true
        self.bCanUserChange = false
        self.bCanJump = true
        TargetMgr.EnableQteSearch(false)
        return
    end

    m_tbDynamicSkills = {}
    local tbSkills = GetDynamicSkillGroupSkills(dwGroupID)
    self.bCanCastSkill = tbSkills.CanCastSkill
    self.bCanUserChange = tbSkills.canuserchange--用户是否可以主动退出动态技能
    self.bCanJump = not tbSkills.CanJump--反转一下,表里反着配

    TargetMgr.EnableQteSearch(true, dwGroupID)

    self._getSkillData(tbSkills.active)
    self._getSkillData(tbSkills.passive)
end


function QTEMgr._getSkillData(tbSkills)
    local nCount = #tbSkills
    for i = 1, nCount, 1 do
        local tbSkill = tbSkills[i]
        if tbSkill then
            self._collectSkillInfo(tbSkill)
            if tbSkill.id == tbPetSkill.id and tbSkill.level == tbPetSkill.level then
                JiangHuData.tbIdentitySkills = {}
                table.insert(JiangHuData.tbIdentitySkills, {tbPetSkill.id, tbPetSkill.level})
            else
                table.insert(m_tbDynamicSkills, tbSkill)
            end
        end
    end
end


function QTEMgr._updateMainCityQTESlotInfo(tbData)
    self.tbSlotInfo = {}
    for nIndex, tQTEDate in ipairs(tbData) do
        local tbInfo = {}
        tbInfo.nSlotIndex = nIndex
        tbInfo.nSkillID = tQTEDate.nSkillID
        tbInfo.nSkillLevel = tQTEDate.nSkillLevel
        tbInfo.szImgPath = TabHelper.GetSkillIconPathByIDAndLevel(tQTEDate.nSkillID, tQTEDate.nSkillLevel)
        tbInfo.callback = function()
            local player = g_pClientPlayer
            if player then
                SkillData.CastSkill(player, tQTEDate.nSkillID, nil, tQTEDate.nSkillLevel)
                self.RemoveSkillSlotInfoBySlotIndex(nIndex)
            end
        end
        tbInfo.nTotalTime = tQTEDate.nTotalTime
        table.insert(self.tbSlotInfo, tbInfo)
    end
    return self.tbSlotInfo
end

function QTEMgr.IsDynamicSkillGroupType(dwGroupID, szKey)
    local tDynamicSkills = clone(UIDynamicSkillGroupType) or {}
    for _, v in ipairs(tDynamicSkills) do
        if v.szGamePlay == szKey and dwGroupID == v.nGroup then
            return true
        end
    end
    return false
end

function QTEMgr.GetSkillSlotByID(dwSkillID)
    if not self.tbSlotInfo then return 0 end
    for nSlotIndex, tbInfo in ipairs(self.tbSlotInfo) do
        if dwSkillID == tbInfo.nSkillID then
            return tbInfo.nSlotIndex
        end
    end
    return 0
end

--主要控制屏幕中央QTE，右下角走普通技能逻辑
function QTEMgr.OnCastSkillRespond(dwSkillID)

    local nSlotIndex = self.GetSkillSlotByID(dwSkillID)
    if nSlotIndex == 0 or (not self.IsInDynamicSkillState()) then return end--Slot为零则不在当前Qte技能
    self.RemoveSkillSlotInfoBySlotIndex(nSlotIndex)
end