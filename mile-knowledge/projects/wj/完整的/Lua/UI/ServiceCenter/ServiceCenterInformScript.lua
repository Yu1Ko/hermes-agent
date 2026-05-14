-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: ServiceCenterInformScript
-- Date: 2023-06-20 14:59:59
-- Desc: 客服中心 - 举报脚本
-- ---------------------------------------------------------------------------------
local WORD_MIN_NUMBER = 5
local WORD_MAX_NUMBER = 256
local ServiceCenterInformScript = class("ServiceCenterInformScript")

function ServiceCenterInformScript:OnEnter(tbSelectInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbSelectInfo = tbSelectInfo
    self:UpdateInfo()
end

function ServiceCenterInformScript:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function ServiceCenterInformScript:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSubmit , EventType.OnClick , function ()
        self:OnSubmit()
    end)
end

function ServiceCenterInformScript:RegEvent()
    
end

function ServiceCenterInformScript:UnRegEvent()
    
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function ServiceCenterInformScript:UpdateInfo()
    local szName = self.tbSelectInfo and self.tbSelectInfo.szName and UIHelper.GBKToUTF8(self.tbSelectInfo.szName)
    local szMapName = self.tbSelectInfo and self.tbSelectInfo.szMapName and UIHelper.GBKToUTF8(self.tbSelectInfo.szMapName)

    UIHelper.SetText(self.WidgetEditUser  , szName or "")
    UIHelper.SetText(self.WidgetEditScene  , szMapName or "")
    UIHelper.SetText(self.WidgetEditDesc  , "")
end

function ServiceCenterInformScript:OnSubmit()
	local szRoleName = UIHelper.GetText(self.WidgetEditUser)
	local szCustom = UIHelper.GetText(self.WidgetEditDesc)
    local confirmView
	if szRoleName == "" then
        confirmView = UIHelper.ShowConfirm(g_tStrings.RABOT_REFUSE)
    elseif string.len(szCustom) < WORD_MIN_NUMBER or string.len(szCustom) > WORD_MAX_NUMBER then
        confirmView = UIHelper.ShowConfirm(g_tStrings.RABOT_REFUSE)
	else
		RemoteCallToServer("OnReportCheat", UIHelper.UTF8ToGBK(szRoleName), UIHelper.UTF8ToGBK(szCustom))
        UIHelper.SetText(self.WidgetEditUser  , "")
        UIHelper.SetText(self.WidgetEditScene  , "")
        UIHelper.SetText(self.WidgetEditDesc  , "")
        confirmView = UIHelper.ShowConfirm(g_tStrings.REPORT_INFO)
	end
    confirmView:HideCancelButton()
end


return ServiceCenterInformScript