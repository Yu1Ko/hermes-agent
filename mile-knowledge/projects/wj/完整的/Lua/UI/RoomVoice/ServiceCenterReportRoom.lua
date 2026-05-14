-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: ServiceCenterReportRoom
-- Date: 2025-10-16 16:37:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

local ServiceCenterReportRoom = class("ServiceCenterReportRoom")

function ServiceCenterReportRoom:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self:Init()
        self.bInit = true
    end
    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function ServiceCenterReportRoom:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function ServiceCenterReportRoom:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSubmit, EventType.OnClick, function()
        self:OnClick()
    end)
    for index, tog in ipairs(self.tbTogList) do
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(_, bSelected)
            if bSelected then
                self.szType = g_tStrings.tReportChatRoomType[index]
            end
        end)
    end
end

function ServiceCenterReportRoom:RegEvent()

end

function ServiceCenterReportRoom:UnRegEvent()

end


function ServiceCenterReportRoom:Init()
    for index, tog in ipairs(self.tbTogList) do
        UIHelper.SetToggleGroupIndex(tog, ToggleGroupIndex.MobaEquipmentSubTab)
    end
    Timer.AddFrame(self, 1, function()
        UIHelper.SetSelected(self.tbTogList[4], true)
    end)
end

function ServiceCenterReportRoom:OnClick()
    local szRoleName = UIHelper.GetString(self.WidgetNameEdit)
    local szRoomID = UIHelper.GetString(self.WidgetRoomEdit)
    local szTime = UIHelper.GetText(self.WidgetEditScene)
    local szType = self.szType
    local szGVoiceID = self.tbInfo.szGVoiceID
    local szGlobalID = self.tbInfo.szGlobalID
    local szRoomName = self.tbInfo.szRoomName
    local szContent = UIHelper.GetText(self.WidgetEditDesc)

    if szType == "" then
		UIHelper.ShowConfirm(g_tStrings.REPORT_SELECT_TYPE)
	elseif (szRoleName == "") or (szRoomID == "") then
        UIHelper.ShowConfirm(g_tStrings.REPORT_REFUSE_ROOM)
	elseif UIHelper.GetUtf8Len(szContent) < 20 then
        UIHelper.ShowConfirm(g_tStrings.REPORT_REFUSE_ROOM_CONTENT)
	else
		szContent = "(" .. szType .. ")" .. szContent

		local tReportInfo = {
			szGVoiceID = szGVoiceID,
			szRoomName = szRoomName,
			szRoomID = szRoomID,
			szTime = szTime,
		}
        local szPlatform = "vkWin"
        if Platform.IsAndroid() then
            szPlatform = "Android"
        elseif Platform.IsIos() then
            szPlatform = "Ios"
        end
		RemoteCallToServer("OnReportTrick", UIHelper.UTF8ToGBK(szRoleName), UIHelper.UTF8ToGBK(szContent), nil, szGlobalID , szPlatform, tReportInfo)
        local script = UIHelper.ShowConfirm(g_tStrings.REPORT_ROOM_SUCCESS_TIP)
        script:HideCancelButton()

        UIHelper.SetString(self.WidgetNameEdit, "")
        UIHelper.SetString(self.WidgetRoomEdit, "")
        --UIHelper.SetString(self.WidgetEditScene, "")
        UIHelper.SetString(self.WidgetEditDesc, "")
    end



end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function ServiceCenterReportRoom:FormatTimeString(nTime)
	local t = TimeToDate(nTime)
	return string.format("%d-%02d-%02d %02d:%02d:%02d", t.year, t.month, t.day, t.hour, t.minute, t.second)
end

function ServiceCenterReportRoom:GetLocalTimeString()
	local nTime = GetCurrentTime()
	local szTime = self:FormatTimeString(nTime)
	return szTime
end

function ServiceCenterReportRoom:UpdateInfo()
    local tbInfo = self.tbInfo
    UIHelper.SetString(self.LabelName, "")
    UIHelper.SetString(self.LabelRoomID, "")
    UIHelper.SetText(self.WidgetEditScene, self:GetLocalTimeString())
    if self.WidgetRoomEdit == nil then
        self.WidgetRoomEdit = UIHelper.GetChildByPath(UIHelper.GetParent(self.LabelRoomID), "WidgetRoomEdit/WidgetEditScene")
    end
    if self.WidgetNameEdit == nil then
        self.WidgetNameEdit = UIHelper.GetChildByPath(UIHelper.GetParent(self.LabelName), "WidgetNameEdit/WidgetEditScene")
    end
    if self.WidgetNameEdit and self.WidgetRoomEdit then
        UIHelper.SetVisible(UIHelper.GetParent(self.WidgetRoomEdit), true)
        UIHelper.SetVisible(UIHelper.GetParent(self.WidgetNameEdit), true)
        if tbInfo then
            UIHelper.SetText(self.WidgetNameEdit, tbInfo.szName)
            UIHelper.SetText(self.WidgetRoomEdit, string.format("%s;%s", UIHelper.GBKToUTF8(tbInfo.szRoomName), tbInfo.szRoomID))
        else
            UIHelper.SetText(self.WidgetNameEdit, "")
            UIHelper.SetText(self.WidgetRoomEdit, "")
        end
    end
end


return ServiceCenterReportRoom