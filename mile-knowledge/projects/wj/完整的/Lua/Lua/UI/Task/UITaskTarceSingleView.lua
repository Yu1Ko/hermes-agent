-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UITaskTarceSingleView
-- Date: 2023-06-01 14:56:06
-- Desc: 目标栏追踪界面 UITaskTarceSingleView
-- ---------------------------------------------------------------------------------

local UITaskTarceSingleView = class("UITaskTarceSingleView")

local TraceInfoConfig = {
    [ActivityTraceInfoType.WenQuanShanZhuang] = {
        tbBarList = {
            {szTitle = "阶段", nPrefabID = PREFAB_ID.WidgetSlider_Dongzhi, szIconPath = "UIAtlas2_Activity_Winter_Task_Rank"}, 
            {szTitle = "等级", nPrefabID = PREFAB_ID.WidgetSlider_Dongzhi, szIconPath = "UIAtlas2_Activity_Winter_Task_Level"},
            {szTitle = "本日营业额", nPrefabID = PREFAB_ID.WidgetCount_Dongzhi, szIconPath = "UIAtlas2_Activity_Winter_Task_Money"},
            {szTitle = "金钱", nPrefabID = PREFAB_ID.WidgetCount_Dongzhi, szIconPath = "UIAtlas2_Activity_Winter_Task_Money"}, 
            {szTitle = "木材", nPrefabID = PREFAB_ID.WidgetCount_Dongzhi, szIconPath = "UIAtlas2_Activity_Winter_Task_Wood"},
            {szTitle = "石材", nPrefabID = PREFAB_ID.WidgetCount_Dongzhi, szIconPath = "UIAtlas2_Activity_Winter_Task_Stone"},
            {szTitle = "满意度", nPrefabID = PREFAB_ID.WidgetCount_Dongzhi, szIconPath = "UIAtlas2_Activity_Winter_Task_Character"},
            {szTitle = "安全度", nPrefabID = PREFAB_ID.WidgetCount_Dongzhi, szIconPath = "UIAtlas2_Activity_Winter_Task_Safe"},
            {szTitle = "士气值", nPrefabID = PREFAB_ID.WidgetSlider_Dongzhi, szIconPath = "UIAtlas2_Activity_Winter_Task_ShiQiZhi"},
            {szTitle = "出战门客", nPrefabID = PREFAB_ID.WidgetSlider_Dongzhi, szIconPath = "UIAtlas2_Activity_Winter_Task_Character"},
        }
    }
}

local WenQuanShanZhuangLeftTimePQID = 248
-- 突发事件PQID
local WenQuanShanZhuangBattleEventPQIDs = {
    [249] = true,
    [250] = true,
    [252] = true,
    [287] = true,
}

function UITaskTarceSingleView:OnEnter(szKey, tData)
    self.szKey = szKey
    self.tData = tData

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
    Timer.AddCycle(self, 1, function ()
        self:OnSecondBreathe()
    end)
end

function UITaskTarceSingleView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITaskTarceSingleView:BindUIEvent()

end

function UITaskTarceSingleView:RegEvent()
    Event.Reg(self, EventType.On_PQ_RequestDataReturn, function(tbPQInfo, bFieldPQ)
        for _, tbInfo in ipairs(tbPQInfo) do
            if tbInfo.dwPQID == WenQuanShanZhuangLeftTimePQID then
                self.nLeftTime = tbInfo and tbInfo.tbPQValues[1]
                self:OnSecondBreathe()
            elseif WenQuanShanZhuangBattleEventPQIDs[tbInfo.dwPQID] then
                self:RefreshWenQuanShanZhuangBattleEvent(tbInfo)
            end
        end
    end)

    Event.Reg(self, EventType.On_Update_GeneralProgressBar, function(tbInfo)
        local bIsDungeon = DungeonData.IsInDungeon()
        if bIsDungeon and not ActivityData.IsJingHuaMap() then
            Timer.AddFrame(self, 1, function ()
                self:RefreshWenQuanShanZhuangInfo()
            end)
        end
    end)
end

function UITaskTarceSingleView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UITaskTarceSingleView:UpdateInfo()
    if self.szKey == ActivityTraceInfoType.WenQuanShanZhuang then
        self:UpdateWenQuanShanZhuangInfo()
    end

    self:OnSecondBreathe()
end

function UITaskTarceSingleView:UpdateWenQuanShanZhuangInfo()
    UIHelper.SetString(self.LabelTaskTitleName, "温泉山庄")
    if not self.nLeftTime then
        local tCoolDownData = PublicQuestData.tbPQInfoMap[WenQuanShanZhuangLeftTimePQID]
        self.nLeftTime = tCoolDownData and tCoolDownData.tbPQValues[1]
    end
    UIHelper.RemoveAllChildren(self.LayoutContent)
    self.ScriptCard = UIHelper.AddPrefab(PREFAB_ID.WidgetTaskTarceSelectCard_DongZhi, self.LayoutContent)

    UIHelper.RemoveAllChildren(self.ScriptCard.WidgetEmergency)
    self.ScriptBattleEvent = UIHelper.AddPrefab(PREFAB_ID.WidgetEmergencyCell, self.ScriptCard.WidgetEmergency)

    local tbConfig = TraceInfoConfig[ActivityTraceInfoType.WenQuanShanZhuang]
    self.tbScriptBar = {}
    for _, tbBar in ipairs(tbConfig.tbBarList) do
        local scriptBar = UIHelper.AddPrefab(tbBar.nPrefabID, self.ScriptCard.LayoutContent)
        self.tbScriptBar[tbBar.szTitle] = scriptBar
        UIHelper.SetString(scriptBar.LabelOtherTarget, tbBar.szTitle)
        UIHelper.SetSpriteFrame(scriptBar.ImgIcon, tbBar.szIconPath)
    end

    self:RefreshWenQuanShanZhuangBattleEvent()
    self:RefreshWenQuanShanZhuangInfo()
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutContent, true, true)
end

function UITaskTarceSingleView:RefreshWenQuanShanZhuangInfo()
    for _, script in pairs(self.tbScriptBar) do
        UIHelper.SetVisible(script._rootNode, false)
    end

    for _, tbInfo in pairs(DungeonData.tDungeonProgressInfoMap) do
        local szTitle = UIHelper.GBKToUTF8(tbInfo.szTitle)
        local szDesc = UIHelper.GBKToUTF8(tbInfo.szDesc)
        szDesc = szDesc or tostring(tbInfo.nMolecular)
        local scriptBar = self.tbScriptBar[szTitle]
        if not scriptBar then
            for szKey, script in pairs(self.tbScriptBar) do
                local nStart = string.find(szTitle, szKey)
                if nStart and nStart > 0 then
                    scriptBar = script
                end
            end
        end
        if scriptBar then
            UIHelper.SetString(scriptBar.LabelOtherTarget, szTitle)
            UIHelper.SetString(scriptBar.LabelOtherTargetProgress, szDesc)
            if scriptBar.SliderTarget and tbInfo.nPercent then
                UIHelper.SetProgressBarPercent(scriptBar.SliderTarget, tbInfo.nPercent)
            end
            UIHelper.SetVisible(scriptBar._rootNode, true)
        end
    end

    if self.ScriptCard then
        UIHelper.LayoutDoLayout(self.ScriptCard.LayoutContent)
    end
end

function UITaskTarceSingleView:RefreshWenQuanShanZhuangBattleEvent(tbInfo)
    if not self.ScriptCard or not self.ScriptBattleEvent then return end

    if not tbInfo then
        for dwPQID, _ in pairs(WenQuanShanZhuangBattleEventPQIDs) do
            tbInfo = tbInfo or PublicQuestData.tbPQInfoMap[dwPQID]
        end
    end
    UIHelper.SetVisible(self.ScriptCard.WidgetEmergency, tbInfo ~= nil)
    if tbInfo then
        local szSubTitle = UIHelper.GBKToUTF8(tbInfo.szSubTitle)
        UIHelper.SetString(self.ScriptBattleEvent.LabelEmergencyTitle, szSubTitle)        
        local bShowProgress = false
        --数值1显示方式（1：分子/分母），2：进度条，3：boss血量（百分比），4倒计时，倒计时的单位是秒）
        for key, nValue in pairs(tbInfo.tbPQValues) do
            if tbInfo["nValueType"..key] == 1 then
                local szTitle = UIHelper.GBKToUTF8(tbInfo["szValueText"..key])
                local szText = FormatString(g_tStrings.STR_NEW_PQ_TYPE2, szTitle, nValue, tbInfo["dwValueMax"..key])
                UIHelper.SetString(self.ScriptBattleEvent.LabelEmergencyPrograss, szText)
                UIHelper.SetString(self.ScriptBattleEvent.LabelEmergencyDetail, szTitle)
            elseif tbInfo["nValueType"..key] == 2 then
                local szTitle = UIHelper.GBKToUTF8(tbInfo["szValueText"..key])
                local szValue = FormatString(g_tStrings.STR_NEW_PQ_TYPE2, nValue, tbInfo["dwValueMax"..key])
                local nPercent = nValue / tbInfo["dwValueMax"..key] * 100
                UIHelper.SetString(self.ScriptBattleEvent.LabelEmergencyPrograss, szValue)
                UIHelper.SetProgressBarPercent(self.ScriptBattleEvent.SliderTarget, nPercent)
                UIHelper.SetString(self.ScriptBattleEvent.LabelEmergencyDetail, szTitle)
                bShowProgress = true
            elseif tbInfo["nValueType"..key] == 3 then
                local szTitle = UIHelper.GBKToUTF8(tbInfo["szValueText"..key])
                local szValue = string.format("%.0f%%", nValue / tbInfo["dwValueMax"..key] * 100)
                local nPercent = nValue / tbInfo["dwValueMax"..key] * 100
                UIHelper.SetString(self.ScriptBattleEvent.LabelEmergencyPrograss, szValue)
                UIHelper.SetProgressBarPercent(self.ScriptBattleEvent.SliderTarget, nPercent)
                UIHelper.SetString(self.ScriptBattleEvent.LabelEmergencyDetail, szTitle)
                bShowProgress = true
            elseif tbInfo["nValueType"..key] == 4 then
                self.nBattleEventLeftTime = nValue
                self:OnSecondBreathe()
            end 
        end
        UIHelper.SetVisible(self.ScriptBattleEvent.SliderTarget, bShowProgress)
    end
end

local function GetTimeText(nTime)
    local nD = math.floor(nTime / 3600 / 24)
    local nH = math.floor(nTime / 3600 % 24)
    local nM = math.floor((nTime % 3600) / 60)
    local nS = (nTime % 3600) % 60

    if nD > 0 then
        return string.format("%02d:%02d:%02d:%02d", nD, nH, nM, nS)
    elseif nH > 0 then
        return string.format("%02d:%02d:%02d", nH, nM, nS)
    else
        return string.format("%02d:%02d", nM, nS)
    end
end

function UITaskTarceSingleView:OnSecondBreathe()
    if self.nLeftTime and self.nLeftTime > 0 then self.nLeftTime = self.nLeftTime - 1 end
    if self.nBattleEventLeftTime and self.nBattleEventLeftTime > 0 then self.nBattleEventLeftTime = self.nBattleEventLeftTime - 1 end

    if self.szKey == ActivityTraceInfoType.WenQuanShanZhuang then
        local nLeftTime = self.nLeftTime or 0
        local szLeftTime = GetTimeText(nLeftTime)
        UIHelper.SetString(self.LabelTime, szLeftTime)

        if self.ScriptBattleEvent then
            local nBattleEventLeftTime = self.nBattleEventLeftTime or 0
            local szBattleEventLeftTime = GetTimeText(nBattleEventLeftTime)
            UIHelper.SetString(self.ScriptBattleEvent.LabelEmergencyTime, szBattleEventLeftTime)
        end
    end
end

return UITaskTarceSingleView