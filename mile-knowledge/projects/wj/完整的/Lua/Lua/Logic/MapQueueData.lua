-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: MapQueueData
-- Date: 2023-04-24 14:40:58
-- Desc: ?
-- ---------------------------------------------------------------------------------

MapQueueData = MapQueueData or {className = "MapQueueData"}
local self = MapQueueData
-------------------------------- 消息定义 --------------------------------
MapQueueData.Event = {}
MapQueueData.Event.XXX = "MapQueueData.Msg.XXX"
MapQueueData.tQueueList = {}

local HIDE_RANK_DURATION = 60
local m_nStartHideRank = 0
local tAppointmentActivity = {}
local tBeBigBattleCache = {}
local tMapQueueType = {
	[CAMP.NEUTRAL] = MAP_QUEUE_TYPE.NEUTRAL,
	[CAMP.GOOD]    = MAP_QUEUE_TYPE.GOOD,
	[CAMP.EVIL]    = MAP_QUEUE_TYPE.EVIL,
}
local tMapShowCopy = {
	[25] = true,
	[27] = true,
	[216] = true,
    [656] = true,
}
local bFirstInit = false

function MapQueueData.Init()
    Timer.AddCycle(self, 0.1, function()
        local bChanged = false
        for _, v in ipairs(self.tQueueList) do
            local bOld = tBeBigBattleCache[v.mapid] or false
            local bNow = self.BeBigBattle(v.mapid)
            if bOld ~= bNow then
                bChanged = true
            end
        end
        if bChanged then
            Event.Dispatch(EventType.OnBigBattleQueueActivityChanged)
        end
    end)
end

function MapQueueData.UnInit()
    Timer.DelAllTimer(self)
    Event.UnRegAll(self)
end

function MapQueueData.OnLogin()

end

function MapQueueData.OnFirstLoadEnd()

end

function MapQueueData.OnQueueStart(mapid, copyindex, queuetype, starttime, rank)
    self.OnQueuePosUpdate(mapid, copyindex, queuetype, rank)
    if not UIMgr.IsViewOpened(VIEW_ID.PanelMapLineUpPop) then
        UIMgr.Open(VIEW_ID.PanelMapLineUpPop)
    end
end

function MapQueueData.OnQueuePosUpdate(mapid, copyindex, queuetype, rank, bAppointment)
    local bExist = false
    for _, v in ipairs(self.tQueueList) do
        if v.mapid == mapid and v.copyindex == copyindex then
            v.queuetype = queuetype
            v.rank = rank
            v.bAppointment = bAppointment
            bExist = true
            break
        end
    end
    if not bExist then
        table.insert(self.tQueueList, {
            mapid = mapid,
            copyindex = copyindex,
            queuetype = queuetype,
            rank = rank,
            bAppointment = bAppointment,
        })
    end

    table.sort(self.tQueueList, function(l, r)
        if l.rank == r.rank then
           return l.mapid < r.mapid
        end
        return l.rank < r.rank
    end)

    self.UpdateBubbleMsgData()
end

function MapQueueData.GetMapName(dwMapID, nCopyIndex)
	if not dwMapID then
		return ""
	end
	local tMapCopyInfo = GDAPI_GetMapCopyInfo(dwMapID)
	local nCopyCount   = tMapCopyInfo and tMapCopyInfo.nMaxCopy or 0
	local szMapName    = UIHelper.GBKToUTF8(Table_GetMapName(dwMapID))
	if nCopyCount > 0 or tMapShowCopy[dwMapID] then
        if dwMapID == 656 then
            nCopyIndex = nCopyIndex + 1
        end
		szMapName = string.format("%d线-%s",  nCopyIndex, szMapName)
	end
	return szMapName
end

function MapQueueData.GetBubbleBarTitle()
    local t = {}
    if #PVPFieldData.tQueueList > 0 then
        table.insert(t, PVPFieldData.tQueueList[1])
    end
    if #self.tQueueList > 0 then
        table.insert(t, self.tQueueList[1])
    end
    if table_is_empty(t) then
        return ""
    end
    table.sort(t, function(l, r)
        return l.rank < r.rank
    end)

    local szRankTip
    if not MapQueueData.BeBigBattle(t[1].mapid) and not t[1].bAppointment then
        szRankTip = tostring(t[1].rank)
    else
        szRankTip = "排队中"
    end
    return string.format("排队-%s(%s)", MapQueueData.GetMapName(t[1].mapid, t[1].copyindex), szRankTip)
end

function MapQueueData.UpdateBubbleMsgData()
    if table_is_empty(self.tQueueList) then
        BubbleMsgData.RemoveMsg("MapQueueTips")
        Event.Dispatch(EventType.OnMapQueueDataUpdate)
        return
    end
    local mapid = self.tQueueList[1].mapid
    local queuetype = self.tQueueList[1].queuetype
    local rank = self.tQueueList[1].rank
    local copyindex = self.tQueueList[1].copyindex
    local bAppointment = self.tQueueList[1].bAppointment
    local szCamp = g_tStrings.STR_CAMP_TITLE[CAMP.NEUTRAL]
    if queuetype == MAP_QUEUE_TYPE.NEUTRAL then
        szCamp = g_tStrings.STR_CAMP_TITLE[CAMP.NEUTRAL]
    elseif queuetype == MAP_QUEUE_TYPE.GOOD then
        szCamp = g_tStrings.STR_CAMP_TITLE[CAMP.GOOD]
    elseif queuetype == MAP_QUEUE_TYPE.EVIL then
        szCamp = g_tStrings.STR_CAMP_TITLE[CAMP.EVIL]
    else
        szCamp = g_tStrings.tMapQueueType[queuetype]
    end

    local szRankTip
    if not MapQueueData.BeBigBattle(mapid) and not bAppointment then
        szRankTip = tostring(rank)
    else
        szRankTip = "排队中"
    end
    local szContent = string.format("[%s]%s(%s)\n已排队：%d个场景", szCamp, MapQueueData.GetMapName(mapid, copyindex), szRankTip, #self.tQueueList)
    BubbleMsgData.PushMsgWithType("MapQueueTips",{
        szBarTitle = MapQueueData.GetBubbleBarTitle(), 			-- 显示在小地图旁边的气泡栏的短标题(若与szTitle一样, 可以不填)
        nBarTime = 0, 			-- 显示在气泡栏的时长, 单位为秒
        nRank = rank,
        szContent = szContent, 		-- 显示在信息列表项中的内容
        nQueueMapCount = #self.tQueueList,
        szAction = function ()
            UIMgr.Open(VIEW_ID.PanelMapLineUpPop)
        end,
    })
    Event.Dispatch(EventType.OnMapQueueDataUpdate)
end

function MapQueueData.OnQueueEnd(mapid, copyindex, eQuitQueueType)
    local dwBookedMapID = GetScheduledMap()
	if mapid == dwBookedMapID then
		return
	end
    if eQuitQueueType == QUIT_MAP_QUEUE_CODE.KICK then
		-- OutputWarningMessage("MSG_WARNING_RED", g_tStrings.STR_MAP_QUEUE_END_KICK)
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_MAP_QUEUE_END_KICK)
		OutputMessage("MSG_SYS", g_tStrings.STR_MAP_QUEUE_END_KICK_IN_CHATPANEL)
	end
    for k, v in ipairs(self.tQueueList) do
        if v.mapid == mapid and v.copyindex == copyindex then
            table.remove(self.tQueueList, k)
            break
        end
    end
    self.UpdateBubbleMsgData()
end

function MapQueueData.OnCanEnterMap(mapid, copyindex)
    if not Storage.MapQueue.bShowSureNotice then
        ComfirmEnterQueuedMap(mapid, copyindex)
		return
	end
    local szMapName = MapQueueData.GetMapName(mapid, copyindex)
    local szMsg = FormatString(g_tStrings.STR_SWITCHMAP_GFZ_TIP, szMapName)
    local fnConfirm = function ()
        ComfirmEnterQueuedMap(mapid, copyindex)
    end
    UIHelper.ShowConfirm(szMsg, fnConfirm)
end

function MapQueueData.OnClearMapQueue()
    for _, v in ipairs(self.tQueueList) do
        self.StartLeaveMapQueue(v.mapid, v.copyindex)
    end
end

function MapQueueData.IsHideRank(dwMapID)
    -- if not self.aaa then
    --     self.aaa = GetGSCurrentTime()
    -- end
    -- local bbb = GetGSCurrentTime()
    -- LOG.INFO("TIMETIME %s", tostring(bbb - self.aaa))
    -- if (bbb > self.aaa + 10 and bbb < self.aaa + 80) or (bbb > self.aaa + 90) then
    --     return true
    -- else
    --     return false
    -- end
	local dwActivityID = tAppointmentActivity[dwMapID]
	if not dwActivityID then
		dwActivityID = AppointmentData.GetMapAppointmentActivity(dwMapID)
		tAppointmentActivity[dwMapID] = dwActivityID
	end
	if not dwActivityID or dwActivityID == 0 then
		return
	end
	return ActivityData.IsActivityOn(dwActivityID)
end

function MapQueueData.BeBigBattle(mapid)
	local dwMapID = mapid
    local nCurrentTime = GetGSCurrentTime()
	local tCurrentTime = TimeToDate(nCurrentTime)
    local bResult = false
	if dwMapID == 25 and tCurrentTime.weekday == 6 and ActivityData.IsActivityOn(ACTIVITY_ID.BIGBATTLE_QUEUE) then
		bResult = true
	elseif dwMapID == 27 and tCurrentTime.weekday == 0 and ActivityData.IsActivityOn(ACTIVITY_ID.BIGBATTLE_QUEUE) then
		bResult = true
	elseif self.IsHideRank(dwMapID) then
		bResult = true
	end
	if bResult then
		if m_nStartHideRank == 0 then
			m_nStartHideRank = nCurrentTime
		elseif nCurrentTime - m_nStartHideRank > HIDE_RANK_DURATION then
			bResult = false
		end
	else
		m_nStartHideRank = 0
	end
    tBeBigBattleCache[dwMapID] = bResult
    return bResult
end

function MapQueueData.StartLeaveMapQueue(dwMapID, nCopyIndex)
	local dwBookedMapID = GetScheduledMap()
	if dwBookedMapID == dwMapID then
		AbortMapAppointment(dwBookedMapID)
    end
	LeaveMapQueue(dwMapID, nCopyIndex)
end

function MapQueueData.OnMapAppointment()
	local dwMapID       = arg0
	local nResultCode   = arg1
	local dwBookedMapID = GetScheduledMap()
	local nCamp         = g_pClientPlayer and g_pClientPlayer.nCamp or CAMP.NEUTRAL
	local nMapQueueType = tMapQueueType[nCamp]

    if dwMapID and nResultCode and nResultCode ~= SCHEDULE_MAP_APPOINTMENT_CODE.SCHEDULE_SUCCESS and
        nResultCode ~= SCHEDULE_MAP_APPOINTMENT_CODE.ABORT_SUCCESS and
        nResultCode ~= SCHEDULE_MAP_APPOINTMENT_CODE.SCHEDULE_UPDATE and
        nResultCode ~= SCHEDULE_MAP_APPOINTMENT_CODE.SCHEDULE_FORCE_UPDATE then
        return
    end

	if dwBookedMapID == 0 then
        local bChanged = false
        for i = #self.tQueueList, 1, -1 do
            local v = self.tQueueList[i]
            if v.bAppointment then
                table.remove(self.tQueueList, i)
                bChanged = true
            end
        end
        if bChanged then
            self.UpdateBubbleMsgData()
        end
	else
		self.OnQueuePosUpdate(dwBookedMapID, 1, nMapQueueType, 1, true)
	end
end

Event.Reg(self, "ON_START_MAP_QUEUING", function ()
    self.OnQueueStart(arg0, arg1, arg2, arg3, arg4)
end)

Event.Reg(self, "ON_MAP_QUEUE_POS_UPDATE", function ()
    self.OnQueuePosUpdate(arg0, arg1, arg2, arg3)
end)

Event.Reg(self, "ON_END_MAP_QUEUING", function ()
    self.OnQueueEnd(arg0, arg1, arg2)
end)

Event.Reg(self, "ON_CAN_ENTER_MAP_NOTIFY", function ()
    self.OnQueueEnd(arg0, arg1, arg2)
    self.OnCanEnterMap(arg0, arg1)
end)

Event.Reg(self, EventType.OnClearMapQueue, function ()
    self.OnClearMapQueue()
end)

Event.Reg(self, "PLAYER_EXIT_GAME", function()
	self.tQueueList = {}
    tBeBigBattleCache = {}
    bFirstInit = false
end)

Event.Reg(self, EventType.OnBigBattleQueueActivityChanged, function()
    self.UpdateBubbleMsgData()
end)

Event.Reg(self, "ON_SCHEDULE_MAP_APPOINTMENT_RESPOND", function()
    MapQueueData.OnMapAppointment()
end)

Event.Reg(self, "LOADING_END", function()
    if not bFirstInit then
        MapQueueData.OnMapAppointment(nil, nil)
        bFirstInit = true
    end
end)