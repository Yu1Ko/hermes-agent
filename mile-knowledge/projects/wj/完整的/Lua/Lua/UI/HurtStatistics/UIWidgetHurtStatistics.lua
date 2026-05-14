-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSkillConfigurationCell
-- Date: 2022-11-23 10:01:29
-- Desc: ?
-- ---------------------------------------------------------------------------------
---@class UIWidgetHurtStatistics
local UIWidgetHurtStatistics = class("UIWidgetHurtStatistics")

local STAT_TYPE2ID = {
    [STAT_TYPE.DAMAGE] = 0,
    [STAT_TYPE.THERAPY] = 1,
    [STAT_TYPE.BE_DAMAGE] = 2,
    [STAT_TYPE.BE_THERAPY] = 3,
}

local INDEX2STAT_TYPE = {
    [1] = STAT_TYPE.HATRED,
    [2] = STAT_TYPE.DAMAGE,
    [3] = STAT_TYPE.THERAPY,
    [4] = STAT_TYPE.BE_DAMAGE,
}

local DAMAGE_TYPE = {
    [STAT_TYPE2ID[STAT_TYPE.DAMAGE]] = 0,
    [STAT_TYPE2ID[STAT_TYPE.THERAPY]] = 1,
    [STAT_TYPE2ID[STAT_TYPE.BE_DAMAGE]] = 0,
    [STAT_TYPE2ID[STAT_TYPE.BE_THERAPY]] = 1,
}

local STAT_ENABLED = Storage.HurtStatisticSettings

local STAT_TYPE2FRAME_IMG = {
    [STAT_TYPE.DAMAGE] = "UIAtlas2_HurtStatistics_HurtStatistics_bg_omen_dps.png",
    [STAT_TYPE.THERAPY] = "UIAtlas2_HurtStatistics_HurtStatistics_bg_omen_cure.png",
    [STAT_TYPE.BE_DAMAGE] = "UIAtlas2_HurtStatistics_HurtStatistics_bg_omen_tank.png",
    [STAT_TYPE.HATRED] = "UIAtlas2_HurtStatistics_HurtStatistics_bg_omen_aggro.png",
}

local function GetStateText(eStatType, eDataType)
    if eStatType == STAT_TYPE.DAMAGE then
        if eDataType == DATA_TYPE.ONCE then
            return g_tStrings.STR_DAMAGE_SINGLE
        else
            return g_tStrings.STR_DAMAGE_ALL
        end
    elseif eStatType == STAT_TYPE.THERAPY then
        if eDataType == DATA_TYPE.ONCE then
            return g_tStrings.STR_THERAPY_SINGLE
        else
            return g_tStrings.STR_THERAPY_ALL
        end
    elseif eStatType == STAT_TYPE.BE_DAMAGE then
        if eDataType == DATA_TYPE.ONCE then
            return g_tStrings.STR_BE_DAMAGE_SINGLE
        else
            return g_tStrings.STR_BE_DAMAGE_ALL
        end
    elseif eStatType == STAT_TYPE.BE_THERAPY then
        if eDataType == DATA_TYPE.ONCE then
            return g_tStrings.STR_BE_THERAPY_SINGLE
        else
            return g_tStrings.STR_BE_THERAPY_ALL
        end
    elseif eStatType == STAT_TYPE.HATRED then
        return g_tStrings.HATRED_COLLECT
    end
end

function UIWidgetHurtStatistics:OnEnter(nStatisticType, ballScript)
    self.ballScript = ballScript
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    for index, tog in ipairs(self.toggles) do
        UIHelper.ToggleGroupAddToggle(self.TogGroup, tog)
    end

    self.eStatType = nil
    self.eDataType = DATA_TYPE.ONCE

    self.ShowType = "dps"
    self.StatNpc = false
    self.StatBoss = false
    self.nVersion = 0
    self.tTargetDataList = {}

    if self.tScrollList == nil then
        self:InitScrollList()
    end

    if self.scriptFilter == nil then
        self:InitFilter()
    end

    self.tEnabledStats = {}
    self.nPage = 2 -- 默认显示第二页

    self:UpdateLayout()
    self:InitBgOpacity()
end

function UIWidgetHurtStatistics:OnExit()
    self.bInit = false
    self:UnRegEvent()
    self:UnInitScrollList()

    if self.HurtStatisticsCellPool then
        self.HurtStatisticsCellPool:Dispose()
    end
    self.HurtStatisticsCellPool = nil
end

function UIWidgetHurtStatistics:BindUIEvent()
    self.ballScript:BindDrag(self.BtnDrag)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function()
        ClearPlayerSingleStatData()
        self.ballScript:UpdateInfo(self.eStatType, 0)
        self:Reset()
    end)

    UIHelper.BindUIEvent(self.BtnInfo, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelCombatStatistics)
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function()
        self:TurnPage(self.nPage + 1)
    end)
    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function()
        self:TurnPage(self.nPage - 1)
    end)

    UIHelper.BindUIEvent(self.BtnSetting, EventType.OnClick, function()
        if self.scriptFilter then
            self.scriptFilter:Show()
        end

        -- local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSettingsMultipleChoicePop, self.BtnSetting, TipsLayoutDir.BOTTOM_RIGHT)
        -- local tBtnInfoList = {}
        -- for nIndex, nType in ipairs(lst) do
        --     local tInfo = {
        --         szName = STAT_TYPE2DESC[nType],
        --         func = function(bSelected)
        --             if not STAT_ENABLED[nType] or fnCanUnselect() then
        --                 self:ShowStatistic(nType)
        --             else
        --                 TipsHelper.ShowNormalTip(string.format("至少要选择1项"))
        --                 Timer.DelTimer(self, self.nUnSelectTimerID)
        --                 self.nUnSelectTimerID = Timer.AddFrame(self, 1, function()
        --                     script:SetBtnSelectedWithoutEvent(nIndex, true)
        --                 end)
        --             end
        --         end,
        --         bSelected = self:GetStatisticEnabled(nType)
        --     }

        --     table.insert(tBtnInfoList, tInfo)
        -- end

        --local tInfo = {
        --    szName = "侠客拆分",
        --    func = function(bSelected)
        --        STAT_ENABLED.IsSeparatePartnerData = bSelected  -- 侠客浮动信息分离显示
        --        STAT_ENABLED.Flush()
        --        TipsHelper.ShowNormalTip("本次改动仅对变更后产生的数据生效")
        --    end,
        --    bSelected = STAT_ENABLED.IsSeparatePartnerData
        --}
        --table.insert(tBtnInfoList, tInfo)

        -- script:UpdateMultipleChoice(tBtnInfoList)
        -- tip:SetOffset(20, 0)
        -- tip:Update()
    end)
end

function UIWidgetHurtStatistics:RegEvent()
    Event.Reg(self, "CHARACTER_THREAT_RANKLIST", function(arg0, arg1, arg2)
        --LOG.WARN("CHARACTER_THREAT_RANKLIST")
        if self.eStatType == STAT_TYPE.HATRED then
            self:OnReceiveThreatRankList(arg0, arg1, arg2)
        end
    end)

    Event.Reg(self, "PARTY_DELETE_MEMBER", function(arg0, arg1, arg2)
        LOG.WARN("PARTY_DELETE_MEMBER")
    end)

    Event.Reg(self, "CUSTOM_DATA_LOADED", function(arg0, arg1, arg2)
        LOG.WARN("CUSTOM_DATA_LOADED")
    end)

    Event.Reg(self, "UPDATE_STAT_DATA", function()
        if self.eStatType ~= STAT_TYPE.HATRED then
            self:UpdateList()
        end
    end)

    Event.Reg(self, "STAT_SINGLE_BEGIN", function()
        if self.tScrollList then
            self.tScrollList:Reset(0) --刷新数量
        end
    end)

    Event.Reg(self, "STAT_SINGLE_END", function()
        self:UpdateTimeText()
    end)

    Event.Reg(self, EventType.OnSetDragDpsBgOpacity, function(nOpacity)
        if nOpacity then
            UIHelper.SetOpacity(self.ImgListBg, nOpacity)
        end
    end)
end

function UIWidgetHurtStatistics:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetHurtStatistics:GetStatisticEnabled(nStatType)
    local bState = STAT_ENABLED[nStatType]
    if bState == nil then
        bState = true
    end
    return bState
end

function UIWidgetHurtStatistics:ShowStatistic(nStatType)
    local bState = STAT_ENABLED[nStatType]
    if bState == nil then
        bState = true
    end
    STAT_ENABLED[nStatType] = not bState
    STAT_ENABLED.Dirty()

    --LOG.TABLE(STAT_ENABLED)

    self:UpdateLayout()
end

function UIWidgetHurtStatistics:UpdateLayout()
    self.tEnabledStats = {}
    local lst = { STAT_TYPE.HATRED, STAT_TYPE.DAMAGE, STAT_TYPE.THERAPY, STAT_TYPE.BE_DAMAGE }
    for _, statType in ipairs(lst) do
        if STAT_ENABLED[statType] then
            table.insert(self.tEnabledStats, statType)
        end
    end

    self:TurnPage(self.nPage)
end

function UIWidgetHurtStatistics:TurnPage(nNewPage)
    local nClamp = math.min(nNewPage, #self.tEnabledStats)
    nClamp = math.max(nClamp, 1)
    self.nPage = nClamp
    self:SwitchStatistics(self.tEnabledStats[nClamp])

    UIHelper.SetString(self.LabelPage, nClamp .. "/" .. #self.tEnabledStats)
end

function UIWidgetHurtStatistics:SwitchStatistics(nStatisticType)
    if nStatisticType and self.eStatType ~= nStatisticType then
        Timer.DelAllTimer(self)

        self.tTargetDataList = {}
        self.eStatType = nStatisticType
        self.ballScript:UpdateInfo(nStatisticType, 0)
        self:UpdateInfo_Content() --重置属性

        self.szTitle = GetStateText(self.eStatType, DATA_TYPE.ONCE)
        UIHelper.SetVisible(self.BtnReset, nStatisticType ~= STAT_TYPE.HATRED)
        if nStatisticType == STAT_TYPE.HATRED then
            self:UpdateThreatList()
            Timer.AddFrameCycle(self, 3, function()
                self:ApplyThreatList()
            end)
            UIHelper.SetString(self.LabelStatistics, self.szTitle)
        else
            self:UpdateTimeText()
            self.nTimeCycleID = Timer.AddFrameCycle(self, 2, function()
                if self.eStatType ~= STAT_TYPE.HATRED and FightSkillLog.IsFighting() then
                    self:UpdateTimeText()
                end
            end)
            self:UpdateList()
        end
        UIHelper.SetSpriteFrame(self.ImgTitleBg, STAT_TYPE2FRAME_IMG[self.eStatType])
    end
end

------------------------仇恨相关----------------------------------

local dwApplyTargetID = nil
function UIWidgetHurtStatistics:OnReceiveThreatRankList(arg0, arg1, arg2)
    if arg0 ~= dwApplyTargetID then
        return
    end
    self.SelfHatred = 65535

    --local frame = Station.Lookup("Normal/HatredPanel")
    --if not frame or not frame:IsVisible() then
    --    FireUIEvent("OnReceiveThreatRanlist", arg0, arg1, arg2)
    --    return
    --end

    local dwPlayerID = UI_GetClientPlayerID()
    local t = {}
    for k, v in pairs(arg1) do
        table.insert(t, { k, v })
        if k == dwPlayerID then
            self.SelfHatred = v
        end
    end
    table.sort(t, function(a, b)
        return a[2] > b[2]
    end)
    FireUIEvent("OnReceiveThreatRanlist", arg0, t, arg2, true)

    self.aThreatRankList = t
    self.dwTargetID = arg2
    if arg2 and arg1[arg2] then
        self.dwTargetRank = arg1[arg2]
        if self.dwTargetRank == 0 then
            self.dwTargetRank = 65535
        end
    else
        self.dwTargetRank = 65535
    end
    self:UpdateThreatList()
end

local function UpdateThreatApplyTarget()
    local dwType, dwID = Target_GetTargetData()
    if dwType == TARGET.PLAYER then
        dwType, dwID = Target_GetTargetData()
    end

    local dwTargetID = nil
    if dwType == TARGET.NPC then
        dwTargetID = dwID
    end
    if dwTargetID ~= dwApplyTargetID then
        dwApplyTargetID = dwTargetID
        FireUIEvent("THREAT_TARGET_CHANGE", dwTargetID)
    end
end

local function UIApplyThreatRankList()
    UpdateThreatApplyTarget()

    if dwApplyTargetID then
        ApplyCharacterThreatRankList(dwApplyTargetID)
    end
    return dwApplyTargetID
end

function UIWidgetHurtStatistics:ApplyThreatList()
    local dwID = UIApplyThreatRankList()

    if self.dwID ~= dwID then
        self.dwID = dwID
        self.aThreatRankList = {}
        --print("切换目标 目标id %d", self.dwID)
        self:UpdateThreatList()
    end
end

function UIWidgetHurtStatistics:UpdateThreatList()
    local t = self.aThreatRankList or {}

    if self.dwID and self.dwID ~= 0 then
        local npc = GetNpc(self.dwID)
        local szName = g_tStrings.HATRED_COLLECT
        if npc then
            szName = szName .. "(" .. UIHelper.GBKToUTF8(npc.szName) .. ")"
        else
            t = {}
        end
        self.szTitle = szName
    else
        self.szTitle = g_tStrings.HATRED_COLLECT
    end
    UIHelper.SetString(self.LabelStatistics, self.szTitle, 8)

    local clientTeam = GetClientTeam()
    local nSelfPercentage = 0
    for i = 1, #t, 1 do
        local a = t[i]
        if a then
            local szName = ""
            local dwID = a[1]
            local dwForceID = 0
            local dwMKungfuID = 0
            if IsPlayer(dwID) then
                local p = GetPlayer(dwID)
                if p then
                    szName = p.szName
                    dwForceID = p.dwForceID
                    dwMKungfuID = p.GetKungfuMountID()
                elseif clientTeam.IsPlayerInTeam(dwID) then
                    local tMemberInfo = clientTeam.GetMemberInfo(dwID)
                    szName = tMemberInfo.szName
					dwForceID = tMemberInfo.dwForceID
					dwMKungfuID = tMemberInfo.dwMountKungfuID
                end
            else
                local npc = GetNpc(dwID)
                if npc then
                    szName = npc.szName
                end
            end

            local fP = a[2] / self.dwTargetRank
            fP = math.floor(fP * 100)

            a.szName = szName
            a.dwID = dwID
            a.dwForceID = dwForceID
            a.dwHDMKungfuID = GetHDKungfuID(dwMKungfuID)
            a.fP = fP

            if szName == g_pClientPlayer.szName then
                nSelfPercentage = fP
            end
        end
    end

    self.ballScript:UpdateInfo(self.eStatType, nSelfPercentage)

    self.tTargetDataList = t
    local min, max = self.tScrollList:GetIndexRangeOfLoadedCells()
    self.tScrollList:ReloadWithStartIndex(#self.tTargetDataList, min) --刷新数量
end

function UIWidgetHurtStatistics:UpdateThreatCell(script, tThreatInfo, nIndex)
    local a = tThreatInfo
    if a then
        script:UpdateInfo(nIndex)

        local szName = UIHelper.GBKToUTF8(a.szName)
        local dwForceID = a.dwForceID
        UIHelper.SetString(script.LabelName, UIHelper.LimitUtf8Len(szName, 7))

        local fP = a.fP
        UIHelper.SetString(script.LabelNum, fP .. "%")

        local progressBar = nil
        if fP <= 100 then
            UIHelper.SetVisible(script.ProgressBarYellow, true)
            UIHelper.SetVisible(script.ProgressBarRed, false)

            progressBar = script.ProgressBarYellow
        else
            UIHelper.SetVisible(script.ProgressBarYellow, false)
            UIHelper.SetVisible(script.ProgressBarRed, true)

            progressBar = script.ProgressBarRed
        end

        local tbFontColor = UIHelper.ChangeHexColorStrToColor(Table_GetMKungfuFightColor(KUNGFU_ID.JIANG_HU))
        UIHelper.SetTextColor(script.LabelName, tbFontColor)
        UIHelper.SetTextColor(script.LabelTagNum, tbFontColor)
        UIHelper.SetVisible(script.ProgressBarCustom, false)
        UIHelper.SetProgressBarPercent(progressBar, math.floor(fP / 1.2))
    end
end

-------------------------------------------------------------

function UIWidgetHurtStatistics:UpdateList()
    --local tResult = FightSkillLog.GetTotalDataByStatType(self.eStatType)
    --tResult = tResult or {}
    --
    --local tStatList = {}
    --for dwID, tInfo in pairs(tResult) do
    --    if not tInfo.bIsEnemy then
    --        local nDps = 0
    --        local nTime = FightSkillLog.GetLastFightTimeInSeconds()
    --        nTime = nTime <= 0 and 1 or nTime
    --        local tList = tInfo.tList
    --        local nTotalNum = 0
    --        for _, data in pairs(tList) do
    --            nTotalNum = nTotalNum + data.nTotalDamage
    --        end
    --        nDps = math.floor(nTotalNum / nTime)
    --        table.insert(tStatList, { dwID = dwID, nValue = nDps, nValuePer = nDps })
    --    end
    --end

    local tResult = self:GetStatData(self.eDataType, STAT_TYPE2ID[self.eStatType])
    tResult = tResult or {}
    self:UpdateStatList(tResult)
end

function UIWidgetHurtStatistics:UpdateStatList(tResult)
    local hTeam = nil
    local ClientPlayer = g_pClientPlayer
    if ClientPlayer and ClientPlayer.IsInParty() then
        hTeam = GetClientTeam()
    end

    if self.ShowType == "dps" then
        table.sort(tResult, function(a, b)
            return a.nValuePer > b.nValuePer
        end)
    else
        table.sort(tResult, function(a, b)
            return a.nValue > b.nValue
        end)
    end

    local tFinal = {}
    self.nFirstValue = 0
    for nIndex, v in ipairs(tResult) do
        local dwID = v.dwID
        local nValue = v.nValue
        local nDps = v.nValuePer
        if nValue > 0 then
            local KNpc = GetNpc(dwID)
            local szName = UIHelper.GBKToUTF8(v.szName)
            if KNpc and KNpc.dwEmployer and KNpc.dwEmployer ~= 0 then
                local tInfo = FightSkillLog.GetCharacterInfo(KNpc.dwEmployer)
                local szEmployer = tInfo and tInfo.szName or g_tStrings.STR_SOME_BODY
                szName = szName .. "·" .. szEmployer
            end

            local tInfo = FightSkillLog.GetCharacterInfo(dwID, hTeam, szName)
            if tInfo then
                v.tCharacterInfo = tInfo
                if nIndex == 1 then
                    self.nFirstValue = self.ShowType == "dps" and nDps or nValue
                end

                if tInfo.bClientPlayer then
                    self.ballScript:UpdateInfo(self.eStatType, nDps)
                end
                table.insert(tFinal, v)
            end
        end
    end

    self.tTargetDataList = tFinal
    local min, max = self.tScrollList:GetIndexRangeOfLoadedCells()
    self.tScrollList:ReloadWithStartIndex(#self.tTargetDataList, min) --刷新数量
end

function UIWidgetHurtStatistics:UpdateStatItem(script, nIndex, nValue, nDps, tInfo, nStateIndex, bPartner)
    local dwForceID, szName, dwHDMKungfuID = tInfo.dwForceID, tInfo.szName, tInfo.dwHDMKungfuID
    local szInfo = ""
    local szDpsType = "DPS"
    local nUseValue
    if nDps == 0 then
        nDps = 1
    end

    if self.ShowType == "dps" then
        local szConverted = UIHelper.NumberToTenThousand(nDps, 2)
        if nStateIndex == STAT_TYPE2ID[STAT_TYPE.DAMAGE] then
            szInfo = szConverted
        elseif nStateIndex == STAT_TYPE2ID[STAT_TYPE.THERAPY] then
            szInfo = szConverted
            szDpsType = "HPS"
        elseif nStateIndex == STAT_TYPE2ID[STAT_TYPE.BE_DAMAGE] then
            szInfo = szConverted
        elseif nStateIndex == STAT_TYPE2ID[STAT_TYPE.BE_THERAPY] then
            szInfo = szConverted
            szDpsType = "HPS"
        end
        nUseValue = nDps
    else
        szInfo = nValue
        nUseValue = nValue
    end

    script:UpdateInfo(nIndex)

    local szPlayerName = szName or "未知侠士"
    UIHelper.SetString(script.LabelName, UIHelper.LimitUtf8Len(szPlayerName, 6))
    UIHelper.SetString(script.LabelNum, szInfo)
    UIHelper.SetString(script.LabelDps, szDpsType)

    local percent = GetPercent(nUseValue, self.nFirstValue) * 100
    local progressBar = script.ProgressBarCustom
    UIHelper.SetVisible(script.ProgressBarYellow, false)
    UIHelper.SetVisible(script.ProgressBarRed, false)
    UIHelper.SetVisible(progressBar, true)
    UIHelper.SetProgressBarPercent(progressBar, percent)

  
    local szColor = Table_GetMKungfuFightColor(dwHDMKungfuID)
    local szBGColor = Table_GetMKungfuFightBGColor(dwHDMKungfuID)

    if szColor then
        local tbFontColor = UIHelper.ChangeHexColorStrToColor(szColor)
        local tbBgColor = UIHelper.ChangeHexColorStrToColor(szBGColor)
        UIHelper.SetTextColor(script.LabelName, tbFontColor)
        UIHelper.SetTextColor(script.LabelTagNum, tbFontColor)
        UIHelper.SetColor(progressBar, tbBgColor)
    elseif bPartner then
        local tbFontColor = UIHelper.ChangeHexColorStrToColor("#8abbc2")
        local tbBgColor = UIHelper.ChangeHexColorStrToColor("#7da0a5")
        UIHelper.SetTextColor(script.LabelName, tbFontColor)
        UIHelper.SetTextColor(script.LabelTagNum, tbFontColor)
        UIHelper.SetColor(progressBar, tbBgColor)
    end
end

function UIWidgetHurtStatistics:UpdateTimeText()
    local nTime = FightSkillLog.GetLastFightTimeInSeconds()
    local bCeil = false
    local nD = math.floor(nTime / 3600 / 24)
    local nH = math.floor(nTime / 3600 % 24)
    local nM = math.floor((nTime % 3600) / 60)
    local nS = (nTime % 3600) % 60

    if bCeil then
        nS = math.ceil(nS)
    else
        nS = math.floor(nS)
    end

    local text
    if nH ~= 0 then
        text = string.format("%d:%d:%02d", nH, nM, nS)
    else
        text = string.format("(%d:%02d)", nM, nS)
    end

    UIHelper.SetString(self.LabelStatistics, self.szTitle .. text)
end

function UIWidgetHurtStatistics:Reset()
    self:UpdateStatList({})
    --UIHelper.SetString(self.LabelStatistics, self.szTitle)
end

--------------------------ScrollList相关--------------------------------

function UIWidgetHurtStatistics:InitScrollList()
    self:UnInitScrollList()

    self.tScrollList = UIScrollList.Create({
        listNode = self.LayoutList,
        nReboundScale = 1,
        nSpace = 5,
        bSlowRebound = true,
        fnGetCellType = function(nIndex)
            return PREFAB_ID.WidgetHurtStatisticsCell
        end,
        fnUpdateCell = function(cell, nIndex)
            self:UpdateOneCell(cell, nIndex)
        end,
    })
end

function UIWidgetHurtStatistics:InitFilter()
    self.scriptFilter = UIHelper.GetBindScript(self.WidgetFiltrateTip)
    self.scriptFilter:Init(HURT_STAT_TYPE.BALL)

    local tbToggles = self.scriptFilter:GetMainOptions()
    for nIndex, tog in ipairs(tbToggles) do
        UIHelper.SetSelected(tog, STAT_ENABLED[INDEX2STAT_TYPE[nIndex]])
    end

    self.scriptFilter:BindMainOptionsCallBack(function(nIndex, bSelected)
        if not bSelected then -- 是否最后一个取消选中
            local bEmptySelect = true
            for i, tog in ipairs(tbToggles) do
                if i ~= nIndex and UIHelper.GetSelected(tog) then
                    bEmptySelect = false
                    break
                end
            end

            if bEmptySelect then
                TipsHelper.ShowNormalTip(string.format("至少要选择1项"))
                Timer.AddFrame(self, 1, function()
                    UIHelper.SetSelected(tbToggles[nIndex], true)
                end)
                return
            end
        end


        STAT_ENABLED[INDEX2STAT_TYPE[nIndex]] = bSelected
        STAT_ENABLED.Dirty()
        self:UpdateLayout()
    end)
end

function UIWidgetHurtStatistics:UpdateInfo_Content()
    local nDataLen = #self.tTargetDataList
    if self.tScrollList then
        if nDataLen == 0 then
            self.tScrollList:Reset(nDataLen) --完全重置，包括速度、位置
        end
    end
end

function UIWidgetHurtStatistics:UpdateOneCell(cell, nIndex)
    if not cell then
        return
    end
    local tInfo = self.tTargetDataList[nIndex]
    if tInfo then
        if self.eStatType ~= STAT_TYPE.HATRED then
            local bPartner = tInfo.bPartner
            local dwID = tInfo.dwID
            local nValue = tInfo.nValue
            local nDps = tInfo.nValuePer
            local tCharacterInfo = tInfo.tCharacterInfo
            self:UpdateStatItem(cell, nIndex, nValue, nDps, tCharacterInfo, STAT_TYPE2ID[self.eStatType], bPartner)
        else
            self:UpdateThreatCell(cell, tInfo, nIndex)
        end
    end
end

function UIWidgetHurtStatistics:UnInitScrollList()
    if self.tScrollList then
        self.tScrollList:Destroy()
        self.tScrollList = nil
    end
end

--------------------------------------------------------------------------

function UIWidgetHurtStatistics:EnterCustomState(bEnter)
    UIHelper.SetEnable(self.BtnInfo, not bEnter)
    UIHelper.SetEnable(self.BtnSetting, not bEnter)
    UIHelper.SetEnable(self.BtnReset, not bEnter)
    UIHelper.SetEnable(self.BtnLeft, not bEnter)
    UIHelper.SetEnable(self.BtnRight, not bEnter)
end

function UIWidgetHurtStatistics:InitBgOpacity()
    self:SaveDefaultBgOpacity()
    local nOpacity = MainCityCustomData.GetHurtBgOpacity() or Storage.MainCityNode.tbDpsBgOpcity.nOpacity
    if nOpacity then
        UIHelper.SetOpacity(self.ImgListBg, nOpacity)
    else
        UIHelper.SetOpacity(self.ImgListBg, Storage.MainCityNode.tbDpsBgOpcity.nDefault)
    end
end

function UIWidgetHurtStatistics:SaveDefaultBgOpacity()
    if not Storage.MainCityNode.tbDpsBgOpcity.nDefault then
        local nOpacity = UIHelper.GetOpacity(self.ImgListBg)
        Storage.MainCityNode.tbDpsBgOpcity.nDefault = nOpacity
    end
end

--local m_tCharacterInfo = {}
--function UIWidgetHurtStatistics:GetCharacterInfo(dwID, hTeam, szName)
--    if not hTeam then
--        local player = GetClientPlayer()
--        if player and player.IsInParty() then
--            hTeam = GetClientTeam()
--        end
--    end
--
--    if hTeam then
--        local tMemberInfo = hTeam.GetMemberInfo(dwID)
--        if tMemberInfo then
--            m_tCharacterInfo[dwID] = {
--                szName = tMemberInfo.szName,
--                dwForceID = tMemberInfo.dwForceID,
--                nLevel = tMemberInfo.nLevel,
--                dwMountKungfuID = tMemberInfo.dwMountKungfuID,
--                bClientPlayer = (dwID == UI_GetClientPlayerID()),
--            }
--        end
--    else
--        local player = GetClientPlayer()
--        if player and dwID == player.dwID then
--            m_tCharacterInfo[dwID] = {
--                szName = player.szName,
--                dwForceID = player.dwForceID,
--                nLevel = player.nLevel,
--                dwMountKungfuID = player.GetActualKungfuMount().dwSkillID,
--                bClientPlayer = true,
--            }
--        end
--    end
--
--    if m_tCharacterInfo[dwID] then
--        return m_tCharacterInfo[dwID]
--    end
--
--    if not IsPlayer(dwID) then
--        if not szName then
--            local npc = GetNpc(dwID)
--            if npc then
--                szName = npc.szName
--            end
--        end
--
--        m_tCharacterInfo[dwID] = {
--            szName = szName or "",
--            dwForceID = 0,
--            nLevel = 0,
--        }
--        return m_tCharacterInfo[dwID]
--    end
--
--    return m_tCharacterInfo[dwID]
--end

local function GetCharacterType(dwID)
    if IsPlayer(dwID) then
        return 0
    end
    return 1
end

local function UIQuerySkillStatData(ojbType, dwID, eDataType, nStatType)
    if nStatType == STAT_TYPE2ID[STAT_TYPE.BE_DAMAGE] or nStatType == STAT_TYPE2ID[STAT_TYPE.BE_THERAPY] then
        return QueryReceiveSkillStatData(ojbType, dwID, eDataType, DAMAGE_TYPE[nStatType])
    else
        return QuerySkillStatData(ojbType, dwID, eDataType, DAMAGE_TYPE[nStatType])
    end
end

--function UIWidgetHurtStatistics:GetSkillData(dwID, eDataType, eStatType)
--    local tSkill, nTotalValue, tInfo, szName
--    if m_historyIndex then
--        local tData = m_historyData
--        if tData.tSkills[dwID] then
--            tSkill = tData.tSkills[dwID].tSkill
--            nTotalValue = tData.tSkills[dwID].nTotalValue
--            tInfo = tData.tSkills[dwID].tInfo
--        end
--    else
--        tSkill, nTotalValue, szName = UIQuerySkillStatData(GetCharacterType(dwID), dwID, eDataType,
--                STAT_TYPE2ID[eStatType])
--        tInfo = self:GetCharacterInfo(dwID, nil, szName)
--    end
--
--    return tSkill, nTotalValue, tInfo
--end

function UIWidgetHurtStatistics:IsShowParnterData(tParner)
	local npc = GetNpc(tParner.dwID)
	if not npc or npc.dwEmployer == 0 then
		return false
	end

	if Storage.HurtStatisticSettings.ShowParnterType == PARTNER_FIGHT_LOG_TYPE.ALL then
		return true
	end

	local bSelf = npc.dwEmployer == UI_GetClientPlayerID()
	if bSelf and Storage.HurtStatisticSettings.ShowParnterType == PARTNER_FIGHT_LOG_TYPE.SELF then
		return true
	end

	return false
end


function UIWidgetHurtStatistics:GetStatData(eDataType, nStatType)
    local nIntensity = 0
    local open_npc = false
    if nStatType == STAT_TYPE2ID[STAT_TYPE.DAMAGE] then
        nIntensity = 2
        open_npc = self.StatBoss
    else
        open_npc = (self.StatNpc or self.StatBoss)
    end

    local bShowPartner = Storage.HurtStatisticSettings.IsSeparatePartnerData
    local tResult = QueryPlayerStatData(0, eDataType, nStatType, 0)              -- player

    if bShowPartner then
		local tPartnerRes = QueryPlayerStatData(1, eDataType, nStatType, nIntensity, true) -- 侠客
		for k, v in pairs(tPartnerRes) do
			if self:IsShowParnterData(v) then
				v.bPartner = true
				table.insert(tResult, v)
			end
		end
	end

    if open_npc then
        local tNpcRes = QueryPlayerStatData(1, eDataType, nStatType, nIntensity, false) -- npc
        for k, v in pairs(tNpcRes) do
            if v.nValue > 0 and (nIntensity == 0 or (v.nIntensity == 2 or v.nIntensity == 6)) then
                table.insert(tResult, v)
            end
        end
    end
    return tResult
end

return UIWidgetHurtStatistics
