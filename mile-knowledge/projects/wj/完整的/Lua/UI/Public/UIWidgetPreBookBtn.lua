-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetPreBookBtn
-- Date: 2024-07-24 10:04:07
-- Desc: WidgetPreBookBtn 地图排队预约按钮
-- ---------------------------------------------------------------------------------

local UIWidgetPreBookBtn = class("UIWidgetPreBookBtn")

function UIWidgetPreBookBtn:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIWidgetPreBookBtn:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetPreBookBtn:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnPreBookBtn, EventType.OnClick, function()
        local dwBookedMap = GetScheduledMap()
        if self.dwMapID then
            if dwBookedMap ~= self.dwMapID then
                AppointmentData.AppointmentMap(self.dwMapID)
            else
                AppointmentData.CancelAppointmentMap(self.dwMapID)
            end
        elseif self.dwAppointmentID then
            local tInfo = AppointmentData.GetMapAppointmentInfoByID(self.dwAppointmentID)
            if tInfo and tInfo.dwActivityID then
                local dwBookedMapID = GetScheduledMap()
                if tInfo.dwActivityID == 946 then --的卢预约
                    local dwMapID = AppointmentData.GetAppointmentMapByActivityID(946)
                    if dwMapID ~= dwBookedMapID then
                        AppointmentData.AppointmentMap(dwMapID)
                    else
                        AppointmentData.CancelAppointmentMap(dwMapID)
                    end
                    return
                elseif tInfo.dwActivityID == 490 then --大攻防
                    local nWeekDay = TimeLib.GetCurrentWeekday()
                    local dwTodayMapID = 0
                    if nWeekDay == 7 then
                        dwTodayMapID = CampData.CAMP_MAP_ID[CAMP.EVIL]
                    elseif nWeekDay == 6 then
                        dwTodayMapID = CampData.CAMP_MAP_ID[CAMP.GOOD]
                    end
                    if dwTodayMapID ~= dwBookedMapID then
                        AppointmentData.AppointmentMap(dwTodayMapID)
                    else
                        AppointmentData.CancelAppointmentMap(dwTodayMapID)
                    end
                    return
                end
                AppointmentData.LinkAppointmentPanel(tInfo.dwActivityID)
            else
                TipsHelper.ShowImportantYellowTip("当前活动已不可预约")
            end

            RedpointHelper.MapAppointment_SetNew(self.dwAppointmentID, false)
        end
    end)
end

function UIWidgetPreBookBtn:RegEvent()
    Event.Reg(self, "ON_SCHEDULE_MAP_APPOINTMENT_RESPOND", function(dwMapID, nResultCode)
        self:UpdateInfo()
    end)
    Event.Reg(self, EventType.OnMapAppointmentNewUpdate, function()
        self:UpdateInfo()
    end)
end

function UIWidgetPreBookBtn:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetPreBookBtn:OnInitWithMapID(dwMapID, nCopyIndex)
    self.dwMapID = dwMapID
    self.nCopyIndex = nCopyIndex
    self.dwAppointmentID = nil
    self:UpdateInfo()
end

function UIWidgetPreBookBtn:OnInitWithAppointmentID(dwAppointmentID)
    self.dwMapID = nil
    self.nCopyIndex = nil
    self.dwAppointmentID = dwAppointmentID
    self:UpdateInfo()
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetPreBookBtn:UpdateInfo()
    if (not self.dwMapID or self.nCopyIndex) and not self.dwAppointmentID then
        UIHelper.SetVisible(UIHelper.GetParent(self._rootNode), false)
        return
    end

    local nState = MAP_APPOINTMENT_SATE.CANNOT_BOOK
    if self.dwMapID then
        nState = AppointmentData.GetMapAppointmentState(self.dwMapID)
    elseif self.dwAppointmentID then
        nState = AppointmentData.GetMapAppointmentStateByID(self.dwAppointmentID)
    end

    UIHelper.SetVisible(UIHelper.GetParent(self._rootNode), nState ~= MAP_APPOINTMENT_SATE.CANNOT_BOOK)

    UIHelper.SetVisible(self.Eff_HuoDongBtnSelect, nState == MAP_APPOINTMENT_SATE.ALREADY_BOOKED)
    UIHelper.SetVisible(self.ImgBgSelect, nState == MAP_APPOINTMENT_SATE.ALREADY_BOOKED)
    UIHelper.SetVisible(self.ImgBg, nState ~= MAP_APPOINTMENT_SATE.ALREADY_BOOKED)
    UIHelper.SetString(self.LabelPrograss, nState == MAP_APPOINTMENT_SATE.ALREADY_BOOKED and "已预约" or "预约")

    if self.dwAppointmentID then
        UIHelper.SetVisible(self.Eff_HuoDongBtn, nState == MAP_APPOINTMENT_SATE.CAN_BOOK)
        UIHelper.SetVisible(self.ImgRedPoint, RedpointHelper.MapAppointment_HasRedPoint(self.dwAppointmentID) or false)
    else
        UIHelper.SetVisible(self.Eff_HuoDongBtn, false)
        UIHelper.SetVisible(self.ImgRedPoint, false)
    end
end

return UIWidgetPreBookBtn