-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: ServiceCenterProposal
-- Date: 2023-06-20 15:00:30
-- Desc: 客服中心 - 体验意见
-- ---------------------------------------------------------------------------------

local ServiceCenterProposal = class("ServiceCenterProposal")
local ToggleType = 
{
    Quest = 1,
    Craft = 2,
    Scene = 3,
    Skill = 4,
    Other = 5,
}
local CURL_REQUEST_TAG = "Advice"

function ServiceCenterProposal:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function ServiceCenterProposal:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function ServiceCenterProposal:BindUIEvent()
    for i, v in ipairs(self.tbToggleType) do
        UIHelper.BindUIEvent(v , EventType.OnClick , function ()
            UIHelper.SetSelected(self.tbToggleType[self.nCurSelectType] , false)
            self.nCurSelectType = i
            UIHelper.SetSelected(self.tbToggleType[self.nCurSelectType] , true)
        end)
    end

    UIHelper.BindUIEvent(self.BtnSubmit , EventType.OnClick , function ()
        self:OnSubmit()
     end)
end

function ServiceCenterProposal:RegEvent()
    Event.Reg(self, "CURL_REQUEST_RESULT", function ()
        local szKey = arg0
        local bSuccess = arg1
        local szValue = arg2
        local uBufSize = arg3
        if szKey == CURL_REQUEST_TAG then
            local confirmView = UIHelper.ShowConfirm(g_tStrings.MSG_QUEST_SEND_SUCCEED)
            confirmView:HideCancelButton()
        end
    end)
    
end

function ServiceCenterProposal:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function ServiceCenterProposal:UpdateInfo()
    self.nCurSelectType = 1
    UIHelper.SetSelected(self.tbToggleType[self.nCurSelectType] , true)
    UIHelper.SetText(self.DescribeEdit  , "")
    UIHelper.SetText(self.MailEdit  , "")
    UIHelper.SetText(self.PhoneEdit  , "")
end

function ServiceCenterProposal:OnSubmit()

    local szMail = UIHelper.GetText(self.MailEdit)
	local szPhone = UIHelper.GetText(self.PhoneEdit)
    local szMessage = UIHelper.GetText(self.DescribeEdit)
    local confirmView
    if string.len(szMessage) < 20 then
        confirmView = UIHelper.ShowConfirm(g_tStrings.MSG_DESCRIBE_TOO_FEW1)
	else
		local szType = self:GetAdviceTypeName()
		if szType == "" then
            confirmView = UIHelper.ShowConfirm(g_tStrings.MSG_CHOOSE_SUBMIT_TYPE)
		else
			local UrlParam = {}

			ServiceCenterData.FillBasicInfo("Advice", UrlParam)
			UrlParam["Email"] = UIHelper.UTF8ToGBK(szMail)
			UrlParam["CellPhone"] = UIHelper.UTF8ToGBK(szPhone)
			UrlParam["AdviceType"] = UIHelper.UTF8ToGBK(szType)
			UrlParam["Advice"] = UIHelper.UTF8ToGBK(szMessage)
            if Platform.IsAndroid() or bIsAndroid then
                UrlParam["Platform"] = "Android"
            elseif Platform.IsIos() or bIsIos then
                UrlParam["Platform"] = "Ios"
            else
                UrlParam["Platform"] = "VKWin"
            end
			ServiceCenterData.SendDataToGMWEB("Advice", UrlParam)
            CURL_HttpPost("Advice", ServiceCenterData.GetGameMasterReportUrl(), UrlParam)
            UIHelper.SetText(self.MailEdit  , "")
            UIHelper.SetText(self.PhoneEdit  , "")
            UIHelper.SetText(self.DescribeEdit  , "")
		end
	end
    if confirmView then
        confirmView:HideCancelButton()
    end
    
end

function ServiceCenterProposal:GetAdviceTypeName()
    local szResult = ""
	if self.nCurSelectType == ToggleType.Quest then
		szResult = "Quest"
	elseif self.nCurSelectType == ToggleType.Craft then
		szResult = "Craft"
	elseif self.nCurSelectType == ToggleType.Skill then
		szResult = "Skill"
	elseif self.nCurSelectType == ToggleType.Scene then
		szResult = "Map"
	elseif self.nCurSelectType == ToggleType.Other then
		szResult = "Other"
	end
	return szResult
end

return ServiceCenterProposal