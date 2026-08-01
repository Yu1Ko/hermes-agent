-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UICityHistoryPopView
-- Date: 2023-06-28 11:12:29
-- Desc: 据点历史、阵营大事记 PanelCityHistroyPop
-- ---------------------------------------------------------------------------------

local UICityHistoryPopView = class("UICityHistoryPopView")

function UICityHistoryPopView:OnEnter(nType, dwCastleID)
    -- nType = CUSTOM_RECORDING_TYPE.CASTLE_SYSTEM 据点历史
    -- nType = CUSTOM_RECORDING_TYPE.CAMP_SYSTEM 阵营大事记

    self.nType = nType
    self.dwCastleID = dwCastleID

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitUI()

    --当前正在显示的年/月
    self.nShowYear = 0
	self.nShowMonth = 0

    self:InitSystemRecord()
    self:UpdateSystemRecord()
    GetCustomRecording(nType, dwCastleID)
end

function UICityHistoryPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICityHistoryPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.TogYear, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            UIHelper.SetSelected(self.TogMonth, false, false)
            self:OnSelectYearDropList()
        end
    end)
    UIHelper.BindUIEvent(self.TogMonth, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            UIHelper.SetSelected(self.TogYear, false, false)
            self:OnSelectMonthDropList()
        end
    end)
end

function UICityHistoryPopView:RegEvent()
    Event.Reg(self, "ON_SYNC_CUSTOM_RECORDING", function(nType, dwID, tRecord)
        if nType == self.nType then
            self.tRecord = tRecord
            self:InitSystemRecord()
            self:UpdateSystemRecord()
        end
    end)
    Event.Reg(self, EventType.HideAllHoverTips, function()
        UIHelper.SetSelected(self.TogYear, false, false)
        UIHelper.SetSelected(self.TogMonth, false, false)
    end)
end

function UICityHistoryPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UICityHistoryPopView:InitUI()
    if self.nType == CUSTOM_RECORDING_TYPE.CASTLE_SYSTEM then
        UIHelper.SetString(self.LabelTitle, "据点历史")
    elseif self.nType == CUSTOM_RECORDING_TYPE.CAMP_SYSTEM then
        UIHelper.SetString(self.LabelTitle, "阵营大事记")
    end

    UIHelper.SetSelected(self.TogYear, false, false)
    UIHelper.SetSelected(self.TogMonth, false, false)
    UIHelper.SetTouchDownHideTips(self.TogYear, false)
    UIHelper.SetTouchDownHideTips(self.TogMonth, false)
    UIHelper.SetTouchDownHideTips(self.ScrollViewYearUnfold, false)
    UIHelper.SetTouchDownHideTips(self.ScrollViewMonthUnfold, false)
end

function UICityHistoryPopView:UpdateSystemRecord()
    local szYear = self.nShowYear ~= 0 and self.nShowYear or "选择年份"
    local szMonth = self.nShowMonth ~= 0 and self.nShowMonth or "选择月份"
    UIHelper.SetString(self.LabelYear, szYear)
    UIHelper.SetString(self.LabelMonth, szMonth)

    local bHaveYear = #self.tYear > 0
    local bHaveMonth = self.tYearMonth[self.nShowYear] and #self.tYearMonth[self.nShowYear] > 0
    UIHelper.SetEnable(self.TogYear, bHaveYear)
    UIHelper.SetEnable(self.TogMonth, bHaveMonth)
    UIHelper.SetVisible(self.WidgetYearIconFold, bHaveYear)
    UIHelper.SetVisible(self.WidgetMonthIconFold, bHaveMonth)

    UIHelper.RemoveAllChildren(self.ScrollViewCityHistory)

    local tRecord = self.tRecord or {}
	if IsTableEmpty(tRecord) then
		self:UpdateEmptyRecord()
		return
	end

    for k, v in ipairs(tRecord) do
        if v.year == self.nShowYear and v.month == self.nShowMonth then
            local szTime = FormatString(g_tStrings.STR_TIME_6, v.year, v.month, v.day, v.hour, v.minute)
            local szText = ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(v.text), false)
            
            UIMgr.AddPrefab(PREFAB_ID.WidgetContentCityHistory, self.ScrollViewCityHistory, szTime, szText)
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCityHistory)
end

function UICityHistoryPopView:UpdateEmptyRecord()
    local szText = ""
    local nType = self.nType
    if nType == CUSTOM_RECORDING_TYPE.CAMP_SYSTEM then
        szText = g_tStrings.STR_NO_CAMP_BIGTHING
    elseif nType == CUSTOM_RECORDING_TYPE.CASTLE_SYSTEM then
        szText = g_tStrings.STR_NO_CASTLE_BIGTHING
    end
    
    local dwCurrentTime = GetCurrentTime()
    local tTime = TimeToDate(dwCurrentTime)
    UIHelper.SetString(self.LabelYear, tTime.year)
    UIHelper.SetString(self.LabelMonth, tTime.month)

    UIMgr.AddPrefab(PREFAB_ID.WidgetContentCityHistory, self.ScrollViewCityHistory, "", szText)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCityHistory)
end

function UICityHistoryPopView:InitSystemRecord()
    local fnSort = function(tLeft, tRight)
        return tLeft.time > tRight.time
    end

    local tRecord = self.tRecord or {}
    table.sort(tRecord, fnSort)
    
    local nYear = 0
    local nMonth = 0
    local bFirst = true
    self.tYear = {}
    self.tYearMonth = {}

    for k, v in ipairs(tRecord) do
        local tTime = TimeToDate(v.time)
        v.year = tTime.year
        v.month = tTime.month
        v.day = tTime.day
        v.hour = tTime.hour
        v.minute = string.format("%02d",tTime.minute)
        
        if bFirst and self.nShowYear == 0 and self.nShowMonth == 0 then
            self.nShowYear = v.year
            self.nShowMonth = v.month
            bFirst = false
        end
        
        if v.year ~= nYear or v.month ~= nMonth then
            nYear, nMonth= v.year, v.month

            if not table.contain_value(self.tYear, nYear) then
                table.insert(self.tYear, nYear)
            end

            if not self.tYearMonth[nYear] then
                self.tYearMonth[nYear] = {}
            end

            if not table.contain_value(self.tYearMonth[nYear], nMonth) then
                table.insert(self.tYearMonth[nYear], nMonth)
            end
        end
    end
end

function UICityHistoryPopView:OnSelectYearDropList()
    UIHelper.RemoveAllChildren(self.ScrollViewYearUnfold)

    for i, v in ipairs(self.tYear) do
        local nYear = v
        local scriptView = UIMgr.AddPrefab(PREFAB_ID.WidgetCityTimeSelectTog, self.ScrollViewYearUnfold)

        scriptView:OnEnter(nYear, nYear, nil, nYear == self.nShowYear)

        scriptView:SetClickCallback(function()
            UIHelper.SetSelected(self.TogYear, false, false)
            self.nShowYear = nYear
            self.nShowMonth = self.tYearMonth[nYear][1] or 0 --选中当前年份的第一个存在的月份
            self:UpdateSystemRecord()
        end)

        UIHelper.SetTouchDownHideTips(scriptView.ToggleSelect, false)
    end

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutYearUnfold, true, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewYearUnfold)
end

function UICityHistoryPopView:OnSelectMonthDropList()
    UIHelper.RemoveAllChildren(self.ScrollViewMonthUnfold)

    local tYearMonth = self.tYearMonth or {}

    for i, v in ipairs(tYearMonth[self.nShowYear] or {}) do
        local nMonth = v
        local scriptView = UIMgr.AddPrefab(PREFAB_ID.WidgetCityTimeSelectTog, self.ScrollViewMonthUnfold)

        scriptView:OnEnter(nMonth, nMonth, nil, nMonth == self.nShowMonth)

        scriptView:SetClickCallback(function()
            UIHelper.SetSelected(self.TogMonth, false, false)
            self.nShowMonth = nMonth
            self:UpdateSystemRecord()
        end)

        UIHelper.SetTouchDownHideTips(scriptView.ToggleSelect, false)
    end

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutMonthUnfold, true, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewMonthUnfold)
end

return UICityHistoryPopView