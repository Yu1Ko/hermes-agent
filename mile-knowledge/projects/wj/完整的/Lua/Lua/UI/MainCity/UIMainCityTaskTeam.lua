-- ---------------------------------------------------------------------------------
-- Author: huqing, luwenhao1
-- Name: UIMainCityTaskTeam
-- Date: 2022-11-15 15:11:38
-- Desc: 主界面左侧信息显示
-- ---------------------------------------------------------------------------------

local UIMainCityTaskTeam = class("UIMainCityTaskTeam")

--[[
    2023.5.30 luwenhao1 NOTE: 目前左侧一共四个按钮：Task、Team、Info、Other，分别为：
    任务、队伍、信息（公共任务、动态信息Tip等）、其他（特殊玩法如寻宝罗盘等）；
    其中Info和Other按钮平时不显示，只有当里面有内容时才显示，并且Info和Other只会同时显示其中一个按钮；
    而Info或Other里面有多个内容项时，也只会显示其中一个内容项
    （如若Info中同时有公共任务和动态信息Tip，则只会显示其中之一，根据玩家选择来确定显示哪个）；

    如果想在Info中新增显示内容的类型，可详见TraceInfoData.lua，最终可通过发送OnTogTraceInfo事件来显示。
--]]

local WIDGET_TYPE = {
    INFO = 1,
    OTHER = 2,
}

function UIMainCityTaskTeam:OnEnter(bCustom)
    self.bCustom = bCustom or nil
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tWidgetItems = {
        [WIDGET_TYPE.INFO] = {},
        [WIDGET_TYPE.OTHER] = {},
    }

    self.bTogTaskSelected = true
    self.bTogTeamSelected = false

    self.cellWidgetTask = self.cellWidgetTask or PrefabPool.New(PREFAB_ID.WidgetMainCityTaskCell)

    self:InitUI()
end

function UIMainCityTaskTeam:OnExit()
    self.bInit = false
    self:UnRegEvent()

    TraceInfoData.UnRegWidget(self)

    if self.cellWidgetTask then self.cellWidgetTask:Dispose() end
    self.cellWidgetTask = nil
end

function UIMainCityTaskTeam:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnPackUp, EventType.OnClick, function(btn)
        UIHelper.SetVisible(self.WidgetContent, false)

        UIHelper.SetVisible(self.BtnPackUp, false)
        UIHelper.SetVisible(self.BtnUnfold, true)
    end)

    UIHelper.BindUIEvent(self.BtnUnfold, EventType.OnClick, function(btn)
        UIHelper.SetVisible(self.WidgetContent, true)

        UIHelper.SetVisible(self.BtnPackUp, true)
        UIHelper.SetVisible(self.BtnUnfold, false)
    end)

    --NOTE: WidgetTask和WidgetTeam之类的显示隐藏在预制的Toggle里设置

    UIHelper.BindUIEvent(self.TogTask, EventType.OnSelectChanged, function(btn, bSelected)
        if bSelected and self.bTogTaskSelected then
            UIMgr.Open(VIEW_ID.PanelTask)
        end
        self.bTogTaskSelected = bSelected
    end)

    UIHelper.BindUIEvent(self.TogTeam, EventType.OnSelectChanged, function(btn, bSelected)
        if bSelected and self.bTogTeamSelected then
            local bMainCityRoom = RoomData.IsMainCityRoom()
            local bInRoom = RoomData.IsHaveRoom()
            local bInTeam = TeamData.IsInParty()
            if bInRoom and bMainCityRoom then
                UIMgr.Open(VIEW_ID.PanelTeam, 4)
            elseif bInTeam then
                UIMgr.Open(VIEW_ID.PanelTeam, 2)
            else
                UIMgr.Open(VIEW_ID.PanelTeam, 1)
            end
        end
        self.bTogTeamSelected = bSelected
    end)

    UIHelper.BindUIEvent(self.TogInfo, EventType.OnSelectChanged, function(btn, bSelected)
        if bSelected and self.bTogInfoSelected then
            local nInfoCount = self:GetInfoCount()
            if nInfoCount > 1 then
                UIMgr.Open(VIEW_ID.PanelTaskTarceSelect, self.tWidgetItems[WIDGET_TYPE.INFO])
            elseif ActivityData.IsHotSpringActivity() then
                UIMgr.Open(VIEW_ID.PanelActivityTaskTarce, ActivityTraceInfoType.WenQuanShanZhuang)
            end
        end
        self.bTogInfoSelected = bSelected
        RedpointHelper.TraceInfo_ClearAll()
    end)

    UIHelper.BindUIEvent(self.TogPackUp, EventType.OnSelectChanged, function(btn, bSelected)
        if not bSelected then
            Timer.AddFrame(self, 1, function()
                UIHelper.LayoutDoLayout(self.LayoutLeft)
            end)
        end
    end)

    UIHelper.BindUIEvent(self.BtnSelectZoneLight, EventType.OnClick, function()  --进入黑框,maincity加载新的
        Event.Dispatch("ON_ENTER_SINGLENODE_CUSTOM", CUSTOM_RANGE.LEFT, CUSTOM_TYPE.TASK, self.nMode)
    end)
end

function UIMainCityTaskTeam:RegEvent()
    Event.Reg(self, "LOADING_END", function ()
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
        local bMainCityRoom = RoomData.IsMainCityRoom()
        local bInRoom = RoomData.IsHaveRoom()
        local bInTeam = TeamData.IsInParty()
        self:UpdateAutoNavButton()
        -- 进入副本时，如果在房间，自动切到队伍
        if (DungeonData.IsInDungeon() or ArenaData.IsInArena() or BattleFieldData.IsInBattleField()) and bInTeam and bMainCityRoom then
            RoomData.SetMainCityRoom(false)
            return
        end
        self:UpdateTeamLabelInfo()
    end)

    Event.Reg(self, "SYNC_ROLE_DATA_END", function ()
        self:UpdateTeamLabelInfo()
    end)

    Event.Reg(self, "PARTY_UPDATE_BASE_INFO", function ()
        self:UpdateTeamLabelInfo()
        self:UpdateTraceList()
    end)

    Event.Reg(self, "PARTY_ADD_MEMBER", function ()
        self:UpdateTeamLabelInfo()
    end)

    Event.Reg(self, "PARTY_DELETE_MEMBER", function (_, dwMemberID)
        self:UpdateTeamLabelInfo()
        if dwMemberID == UI_GetClientPlayerID() then
            self:ClearTeamNotice()
            self:UpdateTraceList()
        end
    end)

    Event.Reg(self, "PARTY_DISBAND", function ()
        self:UpdateTeamLabelInfo()
        self:ClearTeamNotice()
        self:UpdateTraceList()
    end)

    Event.Reg(self, "PARTY_LEVEL_UP_RAID", function ()
        self:UpdateTeamLabelInfo()
        self:UpdateTraceList()
    end)

    -- todo
    Event.Reg(self, "TEAM_AUTHORITY_CHANGED", function ()
        self:UpdateTeamLabelInfo()
    end)

    -- todo
    Event.Reg(self, "PARTY_LOOT_MODE_CHANGED", function ()
        self:UpdateTeamLabelInfo()
    end)

    -- 侠客相关
    Event.Reg(self, EventType.OnPartnerNpcListChanged, function()
        self:UpdateTeamLabelInfo()
    end)

    Event.Reg(self, "GLOBAL_ROOM_NOTIFY", function()
        self:UpdateTeamLabelInfo()
    end)

    Event.Reg(self, "GLOBAL_ROOM_BASE_INFO", function()
        self:UpdateTeamLabelInfo()
    end)

    Event.Reg(self, "GLOBAL_ROOM_DETAIL_INFO", function()
        self:UpdateTeamLabelInfo()
    end)

    Event.Reg(self, "GLOBAL_ROOM_MEMBER_CHANGE", function()
        self:UpdateTeamLabelInfo()
    end)

    Event.Reg(self, EventType.OnSetMainCityRoom, function(bRoom)
        self:UpdateTeamLabelInfo()
        self:SetNoticeVisible(bRoom)
    end)

    Event.Reg(self, EventType.OnNewQuestCanTracing, function(nQuestID)
        if UIHelper.GetSelected(self.TogTask) then
            UIHelper.PlayAni(self, self.AniTask, "AniTask", function() end)
        end
    end)

    Event.Reg(self, EventType.OnSelectedTaskTeamViewToggle, function(bSelectedTeam)
        if not UIHelper.GetSelected(self.TogTeam) and bSelectedTeam then
            UIHelper.SetSelected(self.TogTeam, true)
        end

        if not UIHelper.GetSelected(self.TogTask) and not bSelectedTeam then
            UIHelper.SetSelected(self.TogTask, true)
        end
    end)

    Event.Reg(self, EventType.OnTogTraceInfo, function(szInfoType, bOpen, tData, bShow)
        --print("[TaskTeam] OnTogTraceInfo", szInfoType, bOpen, tData, bShow)
        if bOpen then
            self:OnAddWidgetItem(WIDGET_TYPE.INFO, szInfoType, tData, bShow)
            if szInfoType == TraceInfoType.PublicQuest then
                self:CheckPQShow()
            end
        else
            self:OnRemoveWidgetItem(szInfoType)
        end

        --[[
        -- 性能热点问题，暂时去掉龙舟活动的处理 by qinghu 2024/10/28
        if szInfoType == TraceInfoType.PublicQuest then
            local bVisible = not bOpen and FestivalActivities.bLongZhou
            FestivalActivities.UpdateLongZhouSlider(self.ScrollViewOther, bVisible)
            if bVisible then
                self:OnAddWidgetItem(WIDGET_TYPE.OTHER, TraceInfoType.FestvialActivities, nil, true)
            else
                self:OnRemoveWidgetItem(TraceInfoType.FestvialActivities)
            end
        end
        ]]
    end)

    Event.Reg(self, EventType.OnTogActivityTip, function(bOpen, dwActivityID)
        if dwActivityID == CampData.CAMP_ACTIVITY_TIP_ID then
            return
        end
        self:OnTogActivityTip(bOpen, dwActivityID)
    end)

    Event.Reg(self, EventType.OnSetTraceInfoPriority, function(szKey, dwActivityID)
        if szKey == TraceInfoType.ActivityTip then
            self.dwActivityID = dwActivityID
        end
        self:SetWidgetItemPriority(szKey)
    end)

    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        local hPlayer = g_pClientPlayer
        if hPlayer then
            --换地图清状态
            local nMapID = hPlayer.GetMapID()
            if self.nLastMapID ~= nMapID then
                self.nLastMapID = nMapID
                Event.Dispatch(EventType.OnSetTraceInfoPriority, nil)
            end
        end
    end)

    Event.Reg(self, EventType.OnQuestTracingTargetChanged, function()
        self:UpdateTraceList()
    end)

    Event.Reg(self, "PARTY_MESSAGE_NOTIFY", function()
        if arg0 == PARTY_NOTIFY_CODE.PNC_PARTY_JOINED or arg0 == PARTY_NOTIFY_CODE.PNC_PARTY_CREATED then
			self:UpdateTraceList()
		end
    end)

    Event.Reg(self, "QUEST_FAILED", function(nQuestIndex)
        local nQuestID = g_pClientPlayer and g_pClientPlayer.GetQuestID(nQuestIndex)
        if nQuestID then
            self:UpdateTraceQuestInfo(nQuestID)
        end
    end)
	Event.Reg(self, "QUEST_CANCELED", function(nQuestID)
        self:UpdateTraceQuestInfo(nQuestID)
    end)
	Event.Reg(self, "QUEST_FINISHED", function(nQuestID, bForceFinish, bAssist, nAddStamina, nAddThew)
        self:UpdateTraceQuestInfo(nQuestID)
    end)
	Event.Reg(self, "SET_QUEST_STATE", function(nQuestID, byQuestState)
        self:UpdateTraceQuestInfo(nQuestID)
    end)
	Event.Reg(self, "QUEST_SHARED", function(dwSrcPlayerID, nQuestID)
        self:UpdateTraceQuestInfo(nQuestID)
    end)
	Event.Reg(self, "QUEST_DATA_UPDATE", function(nQuestIndex, eEventType)
        local nQuestID = g_pClientPlayer and g_pClientPlayer.GetQuestID(nQuestIndex)
        if nQuestID then
            self:UpdateTraceQuestInfo(nQuestID)
        end
    end)

    Event.Reg(self, "ON_CHANGE_FONT_SIZE", function (tbSizeType)
        self:UpdateNodeSize(tbSizeType)
    end)

    Event.Reg(self, "ON_SHOW_FAKE_TASKINFO", function (bSelect)
        if self.bCustom then
            UIHelper.SetSelected(self.TogPackUp, bSelect)
            if not UIHelper.GetSelected(self.TogTask) then
                UIHelper.SetSelected(self.TogTask, true)
            end
            local tbQuestList = QuestData.GetTracingQuestIDList()
            if #tbQuestList == 0 then
                self:RemoveAllQuestList()
                local tbFakeQuest = {25220, 25851}
                for i, v in ipairs(tbFakeQuest) do
                    local node, scriptView = self.cellWidgetTask:Allocate(self.ScrollViewTaskNew, v)
                    self.tbTaskListScript[v] = scriptView
                    UIHelper.SetPositionX(scriptView._rootNode, 0, self.ScrollViewTaskNew)
                end
                UIHelper.SetVisible(self.WidgetTaskBg, true)
                if self.nUpdateTraceListTimer then
                    Timer.DelTimer(self, self.nUpdateTraceListTimer)
                end
                self.nUpdateTraceListTimer = Timer.AddFrame(self, 2, function()
                    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTaskNew)
                end)
            end
        end
    end)

    Event.Reg(self, "ON_SHOW_FAKE_TEAMINFO", function (bSelect)
        if self.bCustom then
            UIHelper.SetSelected(self.TogPackUp, bSelect)
            if not UIHelper.GetSelected(self.TogTeam) then
                UIHelper.SetSelected(self.TogTeam, true)
                UIHelper.SetVisible(self.LayoutTeamOperations, false)
            end
        end
    end)

    Event.Reg(self, "LEAVE_GLOBAL_ROOM", function ()
        self:ClearRoomNotice()
    end)

    Event.Reg(self, EventType.On_Update_GeneralProgressBar, function(tbInfo)
        if FestivalActivities.tbProgressBarData then
            FestivalActivities.tbProgressBarData[tbInfo.szName] = tbInfo
        end

        if table.contain_value(FestivalActivities.tbLongzhouName, tbInfo.szName) then
            local tPQHandler = TraceInfoData.GetInfoHandler(TraceInfoType.PublicQuest)
            local bHasPQ = tPQHandler and tPQHandler.HasPQ()
            if not bHasPQ then
                FestivalActivities.UpdateLongZhouSlider(self.ScrollViewOther, true)
                self:OnAddWidgetItem(WIDGET_TYPE.OTHER, TraceInfoType.FestvialActivities, nil, true)
            end
        elseif table.contain_value(FestivalActivities.tbChildrensDayName, tbInfo.szName) then
            FestivalActivities.UpdateMinerSlider(self.ScrollViewOther, true)
            self:OnAddWidgetItem(WIDGET_TYPE.OTHER, TraceInfoType.FestvialActivities, nil, true)
        elseif table.contain_value(FestivalActivities.tbChildrensDayDanceName, tbInfo.szName) then
            FestivalActivities.UpdateDanceSlider(self.ScrollViewOther, true)
            self:OnAddWidgetItem(WIDGET_TYPE.OTHER, TraceInfoType.FestvialActivities, nil, true)
        end
    end)

    Event.Reg(self, EventType.On_Delete_GeneralProgressBar, function(szName)
        if FestivalActivities.tbProgressBarData then
            FestivalActivities.tbProgressBarData[szName] = nil
        end
        if table.contain_value(FestivalActivities.tbLongzhouName, szName) then
            FestivalActivities.UpdateLongZhouSlider(self.ScrollViewOther, false)
            self:OnRemoveWidgetItem(TraceInfoType.FestvialActivities)
        elseif table.contain_value(FestivalActivities.tbChildrensDayName, szName) then
            FestivalActivities.UpdateMinerSlider(self.ScrollViewOther, false)
            self:OnRemoveWidgetItem(TraceInfoType.FestvialActivities)
        elseif table.contain_value(FestivalActivities.tbChildrensDayDanceName, szName) then
            FestivalActivities.UpdateDanceSlider(self.ScrollViewOther, false)
            self:OnRemoveWidgetItem(TraceInfoType.FestvialActivities)
        end
    end)

    Event.Reg(self, "GeneralCounterSFX_RefleshCounter", function(dwID, nCount)
        if FestivalActivities.tbProgressBarData then
            FestivalActivities.tbProgressBarData["Score"] = nCount
        end
    end)

    Event.Reg(self, "GeneralCounterSFX_Close", function()
        if FestivalActivities.tbProgressBarData then
            FestivalActivities.tbProgressBarData["Score"] = nil
        end
    end)

    Event.Reg(self, "OnUpdateSceneProgress", function ()
        self:UpdateBossProgress()
    end)

end

function UIMainCityTaskTeam:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIMainCityTaskTeam:InitUI()
    UIHelper.SetVisible(self.WidgetOther, false)
    UIHelper.SetVisible(self.WidgetInfo, false)
    local tbTraceQuest = QuestData.GetTracingQuestIDList()
    if #tbTraceQuest == 0 then
        QuestData.FindNextTraceQuestID()
    end
    self:UpdateAutoNavButton()
    self:UpdateTraceList()
    self:UpdateTeamLabelInfo()
    self:UpdateNodeScale()

    self:SetTaskTeamCustomState()

    if Platform.IsMobile() then
        UIHelper.SetSwallowTouches(self.ScrollViewInfo, false)
        UIHelper.SetSwallowTouches(self.ScrollViewTaskNew, false)
    end
end

function UIMainCityTaskTeam:UpdateInfo()
    -- UIHelper.GetBindScript(node)
end

function UIMainCityTaskTeam:UpdateTeamLabelInfo()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local bMainCityRoom = RoomData.IsMainCityRoom()
    local bInRoom = RoomData.IsHaveRoom()
    local bInTeam = TeamData.IsInParty()
    if not bInTeam and bInRoom and not bMainCityRoom then
        RoomData.SetMainCityRoom(true)
        return
    elseif not bInRoom and bMainCityRoom then
        RoomData.SetMainCityRoom(false)
        return
    end

    if bInTeam and not bMainCityRoom then
        local hTeam = GetClientTeam()
        local szNum

        local nTeamSize     = hTeam.GetTeamSize()
        local nPartnerCount = #PartnerData.GetCurrentTeamPartnerNpcList()
        local nTotalCount   = nTeamSize + nPartnerCount

        if TeamData.IsInRaid(hTeam) then
            szNum = nTotalCount .. "/25"
        else
            szNum = nTotalCount .. "/5"
        end

        if nPartnerCount > 0 then
            -- 组队时，召唤了下侠客，则一直按团队来显示
            szNum = nTotalCount .. "/25"
        end

        UIHelper.SetString(self.LabelTeamSelect, szNum)
        UIHelper.SetString(self.LabelTeam, szNum)
        UIHelper.SetSpriteFrame(self.ImgTeamIcon1, "UIAtlas2_MainCity_MainCity1_4")
        UIHelper.SetSpriteFrame(self.ImgTeamIconSelect1, "UIAtlas2_MainCity_MainCity1_4_1")
    elseif bInRoom and bMainCityRoom then
        local szNum = RoomData.GetSize() .. "/25"
        UIHelper.SetString(self.LabelTeamSelect, szNum)
        UIHelper.SetString(self.LabelTeam, szNum)
        UIHelper.SetSpriteFrame(self.ImgTeamIcon1, "UIAtlas2_MainCity_MainCity1_8")
        UIHelper.SetSpriteFrame(self.ImgTeamIconSelect1, "UIAtlas2_MainCity_MainCity1_8_1")
    elseif not bInTeam and table.get_len(PartnerData.GetCurrentTeamPartnerNpcList()) > 0 then
        -- 单人，但召唤了侠客，此时需要特殊处理下
        local nCount = 1 + #PartnerData.GetCurrentTeamPartnerNpcList()
        local szNum = nCount .. "/5"
        if nCount > 5 then
            szNum = nCount .. "/25"
        end

        UIHelper.SetString(self.LabelTeamSelect, szNum)
        UIHelper.SetString(self.LabelTeam, szNum)
        UIHelper.SetSpriteFrame(self.ImgTeamIcon1, "UIAtlas2_MainCity_MainCity1_4")
        UIHelper.SetSpriteFrame(self.ImgTeamIconSelect1, "UIAtlas2_MainCity_MainCity1_4_1")
    else
        UIHelper.SetString(self.LabelTeamSelect, "")
        UIHelper.SetString(self.LabelTeam, "")
        UIHelper.SetSpriteFrame(self.ImgTeamIcon1, "UIAtlas2_MainCity_MainCity1_4")
        UIHelper.SetSpriteFrame(self.ImgTeamIconSelect1, "UIAtlas2_MainCity_MainCity1_4_1")
    end
end

function UIMainCityTaskTeam:CheckPQShow()
    local szPriority, szCurrent = self.szPriorityItemKey, self.szCurItemKey
    local bCanShow = szPriority == TraceInfoType.PublicQuest or not szCurrent

    --若当前显示的是动态信息，且不是优先显示，则自动切到公共任务
    if not szPriority and szCurrent == TraceInfoType.ActivityTip then
        self:SetWidgetItemVisible(TraceInfoType.PublicQuest, true)
    end

    return bCanShow
end

function UIMainCityTaskTeam:OnTogActivityTip(bOpen, dwActivityID)
    local tData = self.tWidgetItems[WIDGET_TYPE.INFO][TraceInfoType.ActivityTip] or {}
    if bOpen then
        if not table.contain_value(tData, dwActivityID) then
            table.insert(tData, dwActivityID)
        end
        if not self.dwActivityID then
            self.dwActivityID = dwActivityID
        end
        self:OnAddWidgetItem(WIDGET_TYPE.INFO, TraceInfoType.ActivityTip, tData)
    else
        if table.contain_value(tData, dwActivityID) then
            table.remove_value(tData, dwActivityID)
        end
        if self.dwActivityID == dwActivityID then
            self.dwActivityID = nil
            if self.szCurItemKey == TraceInfoType.ActivityTip then
                self:SetWidgetItemVisible(TraceInfoType.ActivityTip, true) --刷新显示
            end
        end

        --若已无dwActivityID，则移除
        if #tData <= 0 then
            if self.szPriorityItemKey == TraceInfoType.ActivityTip then
                self:SetWidgetItemPriority(nil)
            end
            self:OnRemoveWidgetItem(TraceInfoType.ActivityTip)
        end
    end

    self:UpdateInfoCount()
    self:UpdateTraceInfoPanel()
end

-- ******** 左侧WidgetInfo、WidgetOther相关 ********

function UIMainCityTaskTeam:UpdateTraceInfoPanel()
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelTaskTarceSelect)
    if scriptView then
        local nInfoCount = self:GetInfoCount()
        if nInfoCount > 0 then
            scriptView:OnEnter(self.tWidgetItems[WIDGET_TYPE.INFO])
        else
            --所有消息移除，自动关闭
            UIMgr.Close(VIEW_ID.PanelTaskTarceSelect)
        end
    end
end

function UIMainCityTaskTeam:HasWidgetItem(szKey)
    if not szKey then
        return false
    end

    for nWidgetType, tItemList in pairs(self.tWidgetItems or {}) do
        for szItemKey, tData in pairs(tItemList) do
            if szItemKey == szKey then
                return true
            end
        end
    end

    return false
end

--当前正在实际显示的Item的key
function UIMainCityTaskTeam:GetCurWidgetItem()
    return self.szCurItemKey, self.dwActivityID
end

--当前正在优先显示的Item的key
function UIMainCityTaskTeam:GetPriorityWidgetItem()
    return self.szPriorityItemKey
end

--记录当前Widget上会存在哪些信息，并根据优先级来确定Widget的显隐
function UIMainCityTaskTeam:OnAddWidgetItem(nWidgetType, szKey, tData, bShow)
    --("[TaskTeam] OnAddWidgetItem", nWidgetType, szKey, tData, bShow)
    if not nWidgetType or not self.tWidgetItems[nWidgetType] then
        return
    end

    tData = tData or {}

    local bInfoChanged = false
    if nWidgetType == WIDGET_TYPE.INFO and not self.tWidgetItems[nWidgetType][szKey] then
        RedpointHelper.TraceInfo_SetNew(szKey, true)
        bInfoChanged = true
    end
    self.tWidgetItems[nWidgetType][szKey] = tData

    --信息数量变化，更新显示
    if bInfoChanged then
        self:UpdateInfoCount()
        self:UpdateTraceInfoPanel()
    end

    --若当前没有显示其他东西，则切换显示，否则不自动切换
    if bShow or not self.szCurItemKey or self.szPriorityItemKey == szKey then
        self:SetWidgetItemVisible(szKey, true)
    end
end

function UIMainCityTaskTeam:OnRemoveWidgetItem(szKey)
    --print("[TaskTeam] OnRemoveWidgetItem", szKey)
    if self.szCurItemKey == szKey then
        self:SetWidgetItemVisible(szKey, false)
    end

    local bInfoChanged = false
    local bChanged = false
    for nWidgetType, tItemList in pairs(self.tWidgetItems or {}) do
        if self.tWidgetItems[nWidgetType][szKey] then
            bChanged = true
            if nWidgetType == WIDGET_TYPE.INFO then
                RedpointHelper.TraceInfo_SetNew(szKey, false)
                bInfoChanged = true
            end
        end
        self.tWidgetItems[nWidgetType][szKey] = nil
    end

    --信息数量变化，更新显示
    if bInfoChanged then
        self:UpdateInfoCount()
        self:UpdateTraceInfoPanel()
    end

    if bChanged then
        self:SetWidgetItemVisible(self.szPriorityItemKey, true) --刷新显示
    end
end

function UIMainCityTaskTeam:SetWidgetItemPriority(szKey)
    self.szPriorityItemKey = szKey --可空

    if szKey then
        --隐藏上一个
        self:SetWidgetItemVisible(self.szCurItemKey, false)
        self:SetWidgetItemVisible(szKey, true, true)
    end
end

function UIMainCityTaskTeam:SetWidgetItemVisible(szKey, bVisible, bForceSelected)
    --print("[TaskTeam] SetWidgetItemVisible", szKey, bVisible, self.szCurItemKey, self.szPriorityItemKey)

    local nCurWidgetType
    for nWidgetType, tItemList in pairs(self.tWidgetItems or {}) do
        for szItemKey, tItemData in pairs(tItemList) do
            if not szKey or szItemKey == szKey then --szKey若为空，则取第一个
                nCurWidgetType = nWidgetType
                if bVisible then
                    if nCurWidgetType == WIDGET_TYPE.INFO then
                        if szItemKey == TraceInfoType.ActivityTip then
                            local dwActivityID = self.dwActivityID or tItemData[1]
                            local tData = {
                                dwActivityID = dwActivityID,
                                bAddTitle = true,
                            }
                            TraceInfoData.RegWidget(szItemKey, self, self.ScrollViewInfo, tData)
                        else
                            local tData = clone(tItemData)
                            tData.bAddTitle = true
                            TraceInfoData.RegWidget(szItemKey, self, self.ScrollViewInfo, tData)
                        end
                    end
                    self.szCurItemKey = szItemKey
                elseif self._szTraceInfoType == szItemKey then
                    TraceInfoData.UnRegWidget(self)
                end
                break
            end
        end
    end

    --若要显示的key不存在，则默认显示第一个
    if szKey and not nCurWidgetType then
        self:SetWidgetItemVisible(nil, bVisible)
        return
    end

    local bHasItem = nCurWidgetType ~= nil and bVisible

    --更新Toggle和Widget显示状态
    local bShowInfo
    local bShowOther
    if bHasItem then
        --未隐藏则显示
        if nCurWidgetType == WIDGET_TYPE.INFO and not UIHelper.GetVisible(self.TogInfo) then
            bShowInfo = true
        elseif nCurWidgetType == WIDGET_TYPE.OTHER and not UIHelper.GetVisible(self.TogOther) then
            bShowOther = true
        end
    else
        --正在显示则隐藏
        if UIHelper.GetVisible(self.TogInfo) then
            bShowInfo = false
        elseif UIHelper.GetVisible(self.TogOther) then
            bShowOther = false
        end
        self.szCurItemKey = nil
    end

    --print("[TaskTeam] DoSetWidgetItemVisible", bShowInfo, bShowOther, bHasItem, nCurWidgetType, self.szCurItemKey, self.szPriorityItemKey)
    if bShowInfo ~= nil or bShowOther ~= nil then
        local bShowTask = not bHasItem and not self.bTogTeamSelected
        local bShowTeam = not bHasItem and self.bTogTeamSelected
        bShowInfo = bShowInfo or false
        bShowOther = bShowOther or false

        local bShowTogInfo = bShowInfo

        if not bForceSelected then
            --公共任务不自动切
            local tPQHandler = TraceInfoData.GetInfoHandler(TraceInfoType.PublicQuest)
            local bIsFBCountDownSceneClose = tPQHandler and tPQHandler.FBCountDownIsSceneClose()
            if self.szCurItemKey == TraceInfoType.PublicQuest and bIsFBCountDownSceneClose then
                bShowTask = not self.bTogTeamSelected
                bShowTeam = self.bTogTeamSelected
                bShowInfo = false
            end

            --副本内组队时不自动切到副本进度
            if self.szCurItemKey == TraceInfoType.DungeonProgress and self.bTogTeamSelected and TeamData.IsPlayerInTeam() then
                bShowTeam = true
                bShowInfo = false
            end
        end

        if bShowInfo then
            RedpointHelper.TraceInfo_SetNew(self.szCurItemKey, false)
        end

        --先设置Toggle再设置Widget的Visible，因为预制里设置了Toggle显隐的一些东西，会影响Widget的显隐

        if
            self.bTogTaskSelected ~= bShowTask or
            self.bTogTeamSelected ~= bShowTeam or
            (UIHelper.GetSelected(self.TogInfo) ~= bShowInfo) or
            (UIHelper.GetSelected(self.TogOther) ~= bShowOther)
        then
            UIHelper.SetSelected(self.TogTask, bShowTask, false)
            UIHelper.SetSelected(self.TogTeam, bShowTeam, false)
            UIHelper.SetSelected(self.TogInfo, bShowInfo, false)
            UIHelper.SetSelected(self.TogOther, bShowOther, false)

            self.bTogTaskSelected = bShowTask
            self.bTogTeamSelected = bShowTeam
            self.bTogInfoSelected = bShowInfo
        end

        UIHelper.SetVisible(self.TogInfo, bShowTogInfo)
        UIHelper.SetVisible(self.TogOther, bShowOther)

        UIHelper.SetVisible(self.WidgetTask, bShowTask)
        UIHelper.SetVisible(self.WidgetTeam, bShowTeam)
        UIHelper.SetVisible(self.WidgetInfo, bShowInfo)
        UIHelper.SetVisible(self.WidgetOther, bShowOther)

        UIHelper.LayoutDoLayout(self.LayoutToggleGroup, true, true)

        if UIHelper.GetVisible(self.LayoutToggleGroup) then
            UIHelper.LayoutDoLayout(self.LayoutLeft)
        end
    end
end

function UIMainCityTaskTeam:UpdateInfoCount()
    --计数
    local nInfoCount = self:GetInfoCount()

    local bShowInfoCount = nInfoCount > 1
    UIHelper.SetVisible(self.LabelInfo, bShowInfoCount)
    UIHelper.SetVisible(self.LabelInfoSelect, bShowInfoCount)
    if bShowInfoCount then
        UIHelper.SetString(self.LabelInfo, nInfoCount)
        UIHelper.SetString(self.LabelInfoSelect, nInfoCount)
    end
end

function UIMainCityTaskTeam:GetInfoCount()
    local nInfoCount = 0
    for szKey, tData in pairs(self.tWidgetItems[WIDGET_TYPE.INFO]) do
        if szKey == TraceInfoType.ActivityTip then
            nInfoCount = nInfoCount + #tData
        else
            nInfoCount = nInfoCount + 1
        end
    end
    return nInfoCount
end

function UIMainCityTaskTeam:RemoveAllQuestList()
    if self.tbTaskListScript then
        for nQuestID, scriptView in pairs(self.tbTaskListScript) do
            self.cellWidgetTask:Recycle(scriptView._rootNode)
        end
    end
    self.tbTaskListScript = {}
end

function UIMainCityTaskTeam:UpdateTraceList()
    local nZorder = 2
    local tbQuestList = QuestData.GetTracingQuestIDList()
    self:RemoveAllQuestList()
    for nIndex, nQuestID in ipairs(tbQuestList) do
        local node, scriptView = self.cellWidgetTask:Allocate(self.ScrollViewTaskNew, nQuestID)
        self.tbTaskListScript[nQuestID] = scriptView
        UIHelper.SetPositionX(scriptView._rootNode, 0, self.ScrollViewTaskNew)
        UIHelper.SetLocalZOrder(node, nZorder)
    end

    UIHelper.SetVisible(self.WidgetTaskBg, #tbQuestList >= 1)
    if self.nUpdateTraceListTimer then
        Timer.DelTimer(self, self.nUpdateTraceListTimer)
    end
    self.nUpdateTraceListTimer = Timer.AddFrame(self, 2, function()
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTaskNew)
    end)

end

function UIMainCityTaskTeam:UpdateAutoNavButton()
    self:RemoveAutoNav()
    if self:CanAddAutoNav() then
        self:AddAutoNav()
        DungeonData.RemoteGetSceneProgress()
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTaskNew)
end



function UIMainCityTaskTeam:RemoveAutoNav()
    if self.scriptNavTitle then
        UIHelper.RemoveFromParent(self.scriptNavTitle._rootNode, true)
        self.scriptNavTitle = nil
    end

    if self.scritNavButton then
        UIHelper.RemoveFromParent(self.scritNavButton._rootNode, true)
        self.scritNavButton = nil
    end
end

function UIMainCityTaskTeam:AddAutoNav()
    local nKillCount, nTotalCount = DungeonData.GetCurrentMapBossProgress()
    local szText = string.format("通关进度 %s/%s", tostring(nKillCount), tostring(nTotalCount))
    self.scriptNavTitle = UIHelper.AddPrefab(PREFAB_ID.WidgetTaskTeamSubtitle, self.ScrollViewTaskNew, szText, 5)
    self.scritNavButton = UIHelper.AddPrefab(PREFAB_ID.WidgetTaskItemUse, self.ScrollViewTaskNew, nil, nil, nil, true)
    self.scritNavButton._rootNode:setPositionX(UIHelper.GetWidth(self.scritNavButton._rootNode) / 2)
    UIHelper.SetLocalZOrder(self.scriptNavTitle._rootNode, 0)
    UIHelper.SetLocalZOrder(self.scritNavButton._rootNode, 1)
end

function UIMainCityTaskTeam:CanAddAutoNav()
    local nKillCount, nTotalCount = DungeonData.GetCurrentMapBossProgress()
    return DungeonData.IsInDungeon() and nTotalCount ~= 0
end


function UIMainCityTaskTeam:UpdateBossProgress()
    if self.scriptNavTitle then
        local nKillCount, nTotalCount = DungeonData.GetCurrentMapBossProgress()
        local szText = string.format("通关进度 %s/%s", tostring(nKillCount), tostring(nTotalCount))
        self.scriptNavTitle:OnEnter(szText, 5)
    end
end



function UIMainCityTaskTeam:UpdateTraceQuestInfo(nQuestID)
    local scriptView = self.tbTaskListScript[nQuestID]
    if scriptView then
        scriptView:UpdateInfo()
    end
    if UIHelper.GetSelected(self.TogTask) then
        if self.nUpdateQuestInfoTimer then
            Timer.DelTimer(self, self.nUpdateQuestInfoTimer)
        end
        self.nUpdateQuestInfoTimer = Timer.AddFrame(self, 2, function()

            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTaskNew)
        end)
    end
end

function UIMainCityTaskTeam:UpdateNodeScale()
    local nMode = Storage.ControlMode.nMode
    local tbSizeInfo = Storage.ControlMode.tbMainCityNodeScaleType[nMode]
    self:UpdateNodeSize(tbSizeInfo)
end


function UIMainCityTaskTeam:ClearTeamNotice()
    if self.bTeamNoticeScript then
        self.bTeamNoticeScript:SetTeamNotice("", "")
        UIHelper.SetVisible(self.bTeamNoticeScript.WidgetTeamNoticeTips, false)
    end
end

function UIMainCityTaskTeam:ClearRoomNotice()
    if self.bRoomNoticeScript then
        self.bRoomNoticeScript:SetTeamNotice("", "")
        UIHelper.SetVisible(self.bRoomNoticeScript.WidgetTeamNoticeTips, false)
    end
end

function UIMainCityTaskTeam:SetNoticeVisible(bRoom)
    if bRoom then
        if self.bTeamNoticeScript then
            UIHelper.SetVisible(self.bTeamNoticeScript.WidgetTeamNoticeTips, false)
        end
    else
        if self.bRoomNoticeScript then
            UIHelper.SetVisible(self.bRoomNoticeScript.WidgetTeamNoticeTips, false)
        end
    end
end

function UIMainCityTaskTeam:UpdatePrepareState(nMode, bStart)
    self:UpdateCustomNodeState(bStart and CUSTOM_BTNSTATE.ENTER or CUSTOM_BTNSTATE.COMMON)
	self.nMode = nMode
end

function UIMainCityTaskTeam:UpdateCustomState()
    self:UpdateCustomNodeState(CUSTOM_BTNSTATE.EDIT)
end


function UIMainCityTaskTeam:UpdateCustomNodeState(nState)
    local szFrame = nState == CUSTOM_BTNSTATE.CONFLICT and "UIAtlas2_MainCity_MainCity1_maincitykuang3" or "UIAtlas2_MainCity_MainCity1_maincitykuang4"
    UIHelper.SetSpriteFrame(self.ImgSelectZone, szFrame)
    UIHelper.SetVisible(self.ImgSelectZone, nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.EDIT)
    UIHelper.SetVisible(self.BtnSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER or nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.OTHER)
    UIHelper.SetVisible(self.ImgSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER)
    self.nState = nState
end

function UIMainCityTaskTeam:SetTaskTeamCustomState()
    if self.bCustom then
        local tbScript = UIHelper.GetBindScript(self.LayoutTeamOperations)
        local tbScript2 = UIHelper.GetBindScript(self.LayoutTeamMoreContent)
        tbScript:SetCustomState(true)
        tbScript2:SetCustomState(true)
    end
end

function UIMainCityTaskTeam:UpdateNodeSize(tbSizeInfo)
    UIHelper.SetScale(self.WidgetTask, tbSizeInfo["nTask"], tbSizeInfo["nTask"])
    UIHelper.SetScale(self.WidgetOther, tbSizeInfo["nTask"], tbSizeInfo["nTask"])
    UIHelper.SetScale(self.WidgetInfo, tbSizeInfo["nTask"], tbSizeInfo["nTask"])
    UIHelper.SetScale(self.WidgetTeam, tbSizeInfo["nTeam"], tbSizeInfo["nTeam"])
    UIHelper.SetScale(self.ImgSelectZone, tbSizeInfo["nTeam"], tbSizeInfo["nTeam"])
    UIHelper.SetScale(self.BtnSelectZoneLight, tbSizeInfo["nTeam"], tbSizeInfo["nTeam"])
end

function UIMainCityTaskTeam:GetCurrentWidgetItems()
    return self.tWidgetItems
end

function UIMainCityTaskTeam:UpdateWidgetItems(tWidgetItems)
    for nWidgetType, tItemList in pairs(tWidgetItems or {}) do
        for szItemKey, tData in pairs(tItemList) do
            self:OnAddWidgetItem(nWidgetType, szItemKey, tData, false)
        end
    end
end

return UIMainCityTaskTeam