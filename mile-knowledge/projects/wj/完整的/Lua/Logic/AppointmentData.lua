-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: AppointmentData
-- Date: 2024-07-23 17:02:11
-- Desc: 地图排队预约管理
-- ---------------------------------------------------------------------------------

AppointmentData = AppointmentData or {className = "AppointmentData"}
local self = AppointmentData

local m_tLastUpdate   = {}
local m_tActivityList = {}
local m_tMapAppointmentInfo = {}
local m_tMapAppointmentActivity = {}

--活动开启前10分钟显示按钮
local SHOW_APPOINTMENT_LEFT = 600

local function IsNeedUpdate()
    local tTodayTime = TimeLib.GetTodayTime()
    if m_tLastUpdate.day ~= tTodayTime.day or m_tLastUpdate.month ~= tTodayTime.month or m_tLastUpdate.year ~= tTodayTime.year then
        return true
    end

    if not m_tMapAppointmentInfo or IsEmpty(m_tMapAppointmentInfo) then
        return true
    end
end

--更新当天活动时间信息
local function UpdateActivity()
    local hActivityMgr = GetActivityMgrClient()
    if not hActivityMgr then
        return
    end

    local tTodayTime = TimeLib.GetTodayTime()
    if m_tLastUpdate.day ~= tTodayTime.day or m_tLastUpdate.month ~= tTodayTime.month or m_tLastUpdate.year ~= tTodayTime.year then
        m_tActivityList = hActivityMgr.GetActivityOfDayEx(tTodayTime.year, tTodayTime.month, tTodayTime.day)
        m_tLastUpdate = {year = tTodayTime.year, month = tTodayTime.month, day = tTodayTime.day,}
    end

    if not m_tMapAppointmentInfo or IsEmpty(m_tMapAppointmentInfo) then
        m_tMapAppointmentInfo = Table_GetAllMapAppointmentInfo()
    end
end

local function GetTimeText(nTime)
    if nTime < 10 then
        return '0' .. nTime
    else
        return nTime
    end
end

local function GetCoolTimeText(nLeft)
    nLeft = nLeft or 0
    local szText
    local nH, nM, nS = TimeLib.GetTimeToHourMinuteSecond(nLeft, false)
    if nH > 0 then
        szText = GetTimeText(nH) ..':'
    else
        szText = "00:"
    end
    if nM  > 0 then
        szText = szText .. GetTimeText(nM) ..':'
    else
        szText = szText .. "00:"
    end
    if nS >= 0 then
        szText = szText .. GetTimeText(nS)
    else
        szText = szText .. "00:"
    end
    return szText
end

function AppointmentData.Init()
    self.RegEvent()
    m_tMapAppointmentInfo = Table_GetAllMapAppointmentInfo()

    for _, v in pairs(m_tMapAppointmentInfo) do
        m_tMapAppointmentActivity[v.dwAppointmentID] = false
    end

    -- Timer.AddCycle(self, 0.5, function()
    --     if not g_pClientPlayer then
    --         return
    --     end

    --     for dwAppointmentID, bValue in pairs(m_tMapAppointmentActivity) do
    --         local bOpen = ActivityData.IsActivityOn(dwAppointmentID)
    --         if bValue ~= bOpen then
    --             m_tMapAppointmentActivity[dwAppointmentID] = bOpen
    --             RedpointHelper.MapAppointment_SetNew(dwAppointmentID, bOpen)
    --         end
    --     end

    --     self.UpdateBubbleMsgData()
    -- end)
end

function AppointmentData.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)
end

function AppointmentData.RegEvent()
    -- --地图预约消息
    -- Event.Reg(self, "ON_SCHEDULE_MAP_APPOINTMENT_RESPOND", function(dwMapID, nResultCode)
    --     -- OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tMapAppointmentResult[nResultCode])

    --     if nResultCode == SCHEDULE_MAP_APPOINTMENT_CODE.SCHEDULE_SUCCESS then
    --         local szAppointName = UIHelper.AttachTextColor(self.GetMapAppointmentName(dwMapID), FontColorID.ImportantYellow)
    --         local tInfo         = self.GetMapAppointmentInfo(dwMapID) or {}
    --         local nStartTime    = self.GetMapAppointmentStartTime(tInfo.dwActivityID)
    --         local szStartTime   = UIHelper.AttachTextColor(TimeLib.GetDateText(nStartTime), FontColorID.ImportantYellow)
    --         local szText = FormatString(g_tStrings.STR_MAP_APPOINTMENT_SUCCESS, szAppointName, szStartTime)
    --         local scriptView = UIHelper.ShowConfirm(szText, nil, nil, true)
    --         scriptView:HideCancelButton()
    --     elseif nResultCode == SCHEDULE_MAP_APPOINTMENT_CODE.SCHEDULE_UPDATE or
    --     nResultCode == SCHEDULE_MAP_APPOINTMENT_CODE.SCHEDULE_FORCE_UPDATE then
    --         --RefreshAppointmentPanel
    --     elseif g_tStrings.tMapAppointmentResult[nResultCode] then
    --         OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tMapAppointmentResult[nResultCode])
    --     end
    -- end)
end

function AppointmentData.GetMapAppointmentState(dwMapID)
    --无效地图
    if not dwMapID or dwMapID == 0 then
        return MAP_APPOINTMENT_SATE.CANNOT_BOOK
    end

    --预约中
    local dwBookMapID = GetScheduledMap()
    if dwBookMapID == dwMapID then
        return MAP_APPOINTMENT_SATE.ALREADY_BOOKED
    end

    --预约活动开启的地图
    for _, v in pairs(m_tMapAppointmentInfo) do
        if v.dwMapID == dwMapID and ActivityData.IsActivityOn(v.dwAppointmentID) then
            return MAP_APPOINTMENT_SATE.CAN_BOOK
        end
    end
    return MAP_APPOINTMENT_SATE.CANNOT_BOOK
end

function AppointmentData.GetMapAppointmentStateByID(dwAppointmentID)
    local nState          = MAP_APPOINTMENT_SATE.CANNOT_BOOK
    local dwBookMapID     = GetScheduledMap()
    if not dwAppointmentID then
        return nState
    end

    for _, v in pairs(m_tMapAppointmentInfo) do
        if v.dwAppointmentID == dwAppointmentID and ActivityData.IsActivityOn(dwAppointmentID) then
            if v.dwMapID == dwBookMapID then
                return MAP_APPOINTMENT_SATE.ALREADY_BOOKED, dwBookMapID
            end
            nState = MAP_APPOINTMENT_SATE.CAN_BOOK
        end
    end
    return nState
end

--获取活动时间（当天）
function AppointmentData.GetMapAppointmentTime(dwActivityID)
    if IsNeedUpdate() then
        UpdateActivity()
    end
    for _, v in pairs(m_tActivityList) do
        if v.dwID == dwActivityID then
            return v.TimeInfo
        end
    end
end

--获取活动开启时间（当天未开启）
function AppointmentData.GetMapAppointmentStartTime(dwActivityID)
    local tTimeList  = self.GetMapAppointmentTime(dwActivityID) or {}
    local nStartTime = 0
    local nCurTime   = GetCurrentTime()
    for _, v in pairs(tTimeList) do
        if nCurTime <= v.nStartTime then
            nStartTime = v.nStartTime
            break
        end
    end

    return nStartTime
end

--活动名·地图名
function AppointmentData.GetMapAppointmentName(dwMapID)
    local szAppointmentName = ""
    for _, v in pairs(m_tMapAppointmentInfo) do
        if v.dwMapID == dwMapID then
            szAppointmentName = UIHelper.GBKToUTF8(v.szName)
            break
        end
    end
    local szMapName = UIHelper.GBKToUTF8(Table_GetMapName(dwMapID)) or ""
    szAppointmentName = FormatString(g_tStrings.STR_MAP_APPOINTMENT_NAME, szAppointmentName, szMapName)
    return szAppointmentName
end

function AppointmentData.GetMapAppointmentInfo(dwMapID)
    for _, v in pairs(m_tMapAppointmentInfo) do
        if v.dwMapID == dwMapID and ActivityData.IsActivityOn(v.dwAppointmentID) then
            return v
        end
    end
end

function AppointmentData.GetMapAppointmentInfoByID(dwAppointmentID)
    for _, v in pairs(m_tMapAppointmentInfo) do
        if v.dwAppointmentID == dwAppointmentID and ActivityData.IsActivityOn(v.dwAppointmentID) then
            return v
        end
    end
end

--获取预约地图对应的真实活动
function AppointmentData.GetMapAppointmentActivity(dwMapID)
    for _, v in pairs(m_tMapAppointmentInfo) do
        if v.dwMapID == dwMapID then
            return v.dwActivityID
        end
    end
end

function AppointmentData.GetAppointmentMapByActivityID(dwActivityID)
    for _, v in pairs(m_tMapAppointmentInfo) do
        if v.dwActivityID == dwActivityID then
            return v.dwMapID
        end
    end
end

function AppointmentData.LinkAppointmentPanel(dwID)
    local dwMapID      = GetScheduledMap()
    local dwActivityID = dwID or self.GetMapAppointmentActivity(dwMapID)
    if not dwActivityID then
        return
    end

    if dwActivityID == 410 then --小攻防
        --跳转到阵营沙盘界面 攻防地图预约界面
        local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelCampMap) or UIMgr.Open(VIEW_ID.PanelCampMap)
        scriptView:ShowMapSelectInfo(216)
    elseif dwActivityID == 490 then --大攻防
        local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelCampMap) or UIMgr.Open(VIEW_ID.PanelCampMap)
        scriptView:ShowMapSelectInfoByTime()
    elseif dwActivityID == 946 then --的卢
        CollectionData.LinkToNormalCardByID(15)
    end
end

function AppointmentData.AppointmentMap(dwMapID)
    if not dwMapID or dwMapID == 0 then
        return
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) then
        return
    end

    local nState = self.GetMapAppointmentState(dwMapID)
    if nState == MAP_APPOINTMENT_SATE.CANNOT_BOOK then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_MAP_APPOINTMENT_FAILED)
        return
    elseif nState == MAP_APPOINTMENT_SATE.ALREADY_BOOKED then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_MAP_APPOINTMENT_REPEAT)
        return
    end

    local dwBookedMapID = GetScheduledMap()
    local nBaseScores     = hPlayer.GetBaseEquipScore()
    local nStrengthScores = hPlayer.GetStrengthEquipScore()
    local nStoneScores    = hPlayer.GetMountsEquipScore()
    local nScores         = nBaseScores + nStrengthScores + nStoneScores
    local nNotPVPCount    = 0

    for i = 0, EQUIPMENT_INVENTORY.BANGLE do
        local pEquip = PlayerData.GetPlayerItem(hPlayer, INVENTORY_INDEX.EQUIP, i)
        if pEquip then
            if (i == EQUIPMENT_INVENTORY.MELEE_WEAPON or i == EQUIPMENT_INVENTORY.BIG_SWORD) and pEquip.nQuality == 5  then
            elseif pEquip.nEquipUsage ~= EQUIPMENT_USAGE_TYPE.IS_PVP_EQUIP and pEquip.nEquipUsage ~= EQUIPMENT_USAGE_TYPE.IS_GENERAL_EQUIP then
                nNotPVPCount = nNotPVPCount + 1
            end
        end
    end

    if dwBookedMapID ~= 0 then
        local szMapName = UIHelper.AttachTextColor(self.GetMapAppointmentName(dwMapID), FontColorID.ImportantYellow)
        local szBookedMapName = UIHelper.AttachTextColor(self.GetMapAppointmentName(dwBookedMapID), FontColorID.ImportantYellow)
        local szText = FormatString(g_tStrings.STR_MAP_APPOINTMENT_CHANGE_CONFIRM, szBookedMapName, szMapName)

        szText = szText .. "\n\n" .. g_tStrings.STR_MAP_APPOINTMENT_NOTICE
        szText = szText .. "\n" .. FormatString(g_tStrings.STR_CURRENT_EQUIP_SCORE, UIHelper.AttachTextColor(nScores, FontColorID.ImportantRed))
        if nNotPVPCount ~= 0 then
            szText = szText .. "\n" .. UIHelper.AttachTextColor(FormatString(g_tStrings.STR_WARNING_LOW_PVP_EQUIP_COUNT, tostring(nNotPVPCount)), FontColorID.ImportantRed)
        end

        szText = "<font size='24'>" .. szText .. "</font>"

        UIHelper.ShowConfirm(szText, function()
            AbortMapAppointment(dwBookedMapID)
            ScheduleMapAppointment(dwMapID)
        end, nil, true)
    else
        local szMapName  = UIHelper.AttachTextColor(self.GetMapAppointmentName(dwMapID), FontColorID.ImportantYellow)
        local tInfo      = self.GetMapAppointmentInfo(dwMapID) or {}
        local nStartTime = self.GetMapAppointmentStartTime(tInfo.dwActivityID)
        local szText     = FormatString(g_tStrings.STR_MAP_APPOINTMENT_CONFIRM_WITHOUT_TIME, szMapName)
        if nStartTime and nStartTime ~= 0 then
            local szStartTime = UIHelper.AttachTextColor(TimeLib.GetDateText(nStartTime), FontColorID.ImportantYellow)
            szText = FormatString(g_tStrings.STR_MAP_APPOINTMENT_CONFIRM, szMapName, szStartTime)
        end

        szText = szText .. "\n\n" .. g_tStrings.STR_MAP_APPOINTMENT_NOTICE
        szText = szText .. "\n" .. FormatString(g_tStrings.STR_CURRENT_EQUIP_SCORE, UIHelper.AttachTextColor(nScores, FontColorID.ImportantRed))
        if nNotPVPCount ~= 0 then
            szText = szText .. "\n" .. UIHelper.AttachTextColor(FormatString(g_tStrings.STR_WARNING_LOW_PVP_EQUIP_COUNT, tostring(nNotPVPCount)), FontColorID.ImportantRed)
        end

        szText = "<font size='24'>" .. szText .. "</font>"

        UIHelper.ShowConfirm(szText, function()
            ScheduleMapAppointment(dwMapID)
        end, nil, true)
    end
end

function AppointmentData.CancelAppointmentMap(dwMapID)
    local dwBookedMapID = GetScheduledMap()
    if dwMapID ~= dwBookedMapID or dwBookedMapID == 0 then
        return
    end

    UIHelper.ShowConfirm(g_tStrings.STR_MAP_APPOINTMENT_CANCEL_CONFIRM, function()
        AbortMapAppointment(dwBookedMapID)
    end)
end

function AppointmentData.UpdateBubbleMsgData()
    local dwAppointmentID
    local dwBookedMapID = GetScheduledMap()

    if dwBookedMapID ~= 0 then
        local nCurrentTime = GetCurrentTime()
        local dwActivityID = self.GetMapAppointmentActivity(dwBookedMapID)
        local nStartTime   = self.GetMapAppointmentStartTime(dwActivityID)
        local nLeft = nStartTime - nCurrentTime

        if nLeft <= SHOW_APPOINTMENT_LEFT then
            if not BubbleMsgData.GetMsgByType("AppointmentTips") then
                local fnGetContent = function()
                    local dwMapID      = GetScheduledMap()
                    local dwActivityID = self.GetMapAppointmentActivity(dwMapID)
                    local nStartTime   = self.GetMapAppointmentStartTime(dwActivityID)
                    local szMapName    = self.GetMapAppointmentName(dwMapID)
                    local szTip        = ""
                    local nCurrentTime = GetCurrentTime()
                    local nLeft        = nStartTime - nCurrentTime

                    szTip = szTip .. FormatString(g_tStrings.STR_MAP_APPOINTMENT_TITLE, szMapName) .. "\n"
                    if nStartTime and nStartTime ~= 0 then
                        szTip = szTip .. FormatString(g_tStrings.STR_MAP_APPOINTMENT_COUNTDOWN, GetCoolTimeText(nLeft)) .. "\n"
                    end
                    return szTip, 0.5
                end
                BubbleMsgData.PushMsgWithType("AppointmentTips", {
                    szTitle = "预约中",
                    nBarTime = 0,
                    szContent = fnGetContent,
                    szAction = function()
                        self.LinkAppointmentPanel(dwAppointmentID)
                    end,
                })
            end
            return
        end
    end

    if BubbleMsgData.GetMsgByType("AppointmentTips") then
        BubbleMsgData.RemoveMsg("AppointmentTips")
    end
end