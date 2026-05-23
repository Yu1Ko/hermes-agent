-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: ServiceCenterAccountSafe
-- Date: 2023-06-20 14:58:27
-- Desc: 客服中心 - 账号安全
-- ---------------------------------------------------------------------------------

local ServiceCenterAccountSafe = class("ServiceCenterAccountSafe")
local tAwards =
{
	[1] = {8, 68},
	[2] = {8, 6916}
}

local tbSafeIcon =
{
    [1] = "UIAtlas2_Service_ServerCenter_Security1",
    [2] = "UIAtlas2_Service_ServerCenter_Security2",
    [3] = "UIAtlas2_Service_ServerCenter_Security3",
    [4] = "UIAtlas2_Service_ServerCenter_Security4",
}

local m_sns_wait_flag
local m_sns_start_wtime = 0
local m_sns_bind_url
local m_bind_flag = nil

function ServiceCenterAccountSafe:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function ServiceCenterAccountSafe:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function ServiceCenterAccountSafe:BindUIEvent()

    UIHelper.BindUIEvent(self.BtnVerifyEmail , EventType.OnClick , function ()
        APIHelper.OpenURL_VerifyMail()
    end)

    UIHelper.BindUIEvent(self.BtnVerifyPhone , EventType.OnClick , function ()
        APIHelper.OpenURL_VerifyPhone()
    end)

    UIHelper.BindUIEvent(self.BtnVerifySafeLock , EventType.OnClick , function ()
        UIMgr.Open(VIEW_ID.PanelSetPasswordPop)
    end)

    UIHelper.BindUIEvent(self.BtnVerifyMiBaoPhone , EventType.OnClick , function ()
        UIHelper.OpenWebWithDefaultBrowser(tUrl.ShoujibanCard)
    end)

    UIHelper.BindUIEvent(self.BtnVerifyMiBaoEntity , EventType.OnClick , function ()
        UIHelper.OpenWebWithDefaultBrowser(tUrl.ShitibanCard)
    end)

    UIHelper.BindUIEvent(self.BtnVerifyWechatService , EventType.OnClick , function ()
        UIHelper.OpenWebWithDefaultBrowser(tUrl.WeiXinServer)
    end)

    UIHelper.BindUIEvent(self.BtnVerifyWechatSubscribe , EventType.OnClick , function ()
        UIHelper.OpenWebWithDefaultBrowser(tUrl.WeiXinDetail)
    end)

    UIHelper.BindUIEvent(self.BtnVerifyWechatManager , EventType.OnClick , function ()
        UIHelper.OpenWebWithDefaultBrowser(tUrl.WeiXinManager)
        Storage.ServerCenter.bLookWechatGM = true
        Event.Dispatch(EventType.OnCheckVerifyWechatManager)
    end)

    UIHelper.BindUIEvent(self.BtnVerifyApp , EventType.OnClick , function ()
        if Channel.IsCloud() then
            UIHelper.OpenWeb(tUrl.JX3APPBind, false, true)
            return
        end

        UIHelper.OpenWebWithDefaultBrowser(tUrl.JX3APPBind)
    end)

    UIHelper.BindUIEvent(self.BtnVerifySina , EventType.OnClick , function ()
        if m_sns_bind_url then
            UIHelper.OpenWebWithDefaultBrowser(m_sns_bind_url)
        else
            self:sns_enter_openurl()
        end

    end)

    UIHelper.BindUIEvent(self.BtnVerifySinaCancel , EventType.OnClick , function ()
        local szMessage = FormatString(g_tStrings.tWeiBo.UNBING, g_tStrings.WEI_BO_S_NAME)
        local Dialog = UIHelper.ShowConfirm(szMessage, function ()
            local hPlayer = GetClientPlayer()
            if hPlayer then
                hPlayer.UnbindWeibo(WEIBO_TYPE.SINA)
            end
        end)
        Dialog:SetButtonContent("Confirm", g_tStrings.STR_HOTKEY_SURE)
        Dialog:SetButtonContent("Cancel",  g_tStrings.STR_HOTKEY_CANCEL)
    end)

    UIHelper.BindUIEvent(self.BtnReward1 , EventType.OnClick , function ()
        TipsHelper.DeleteAllHoverTips()
            local uiTips, uiItemTipScript = TipsHelper.ShowItemTips(self.BtnReward1, tAwards[1][1], tAwards[1][2])
            uiItemTipScript:SetBtnState({})
    end)

    UIHelper.BindUIEvent(self.BtnReward2 , EventType.OnClick , function ()
        TipsHelper.DeleteAllHoverTips()
        local uiTips, uiItemTipScript = TipsHelper.ShowItemTips(self.BtnReward2, tAwards[2][1], tAwards[2][2])
        uiItemTipScript:SetBtnState({})
    end)
end

function ServiceCenterAccountSafe:RegEvent()
    Event.Reg(self, "SYNC_SAFE_SCORE", function ()
        ServiceCenterData:SetSafeScore(arg0)
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_SYNC_SNS_TOAKEN", function ()
        local sns_type = arg0
        if sns_type == WEIBO_TYPE.SINA then
			self:UpdateSinaState()
		end
    end)

    Event.Reg(self, "ON_SNS_NOTIFY", function ()
        local sns_type = arg0
		local ret = arg1
        if ret == WEIBO_NOTIFY_CODE.UNBIND_SUCCESS then
			if sns_type == WEIBO_TYPE.SINA then
				self:UpdateSinaState()
			end
		end
    end)

    Event.Reg(self, "ON_SYNC_WEIBO_TOKEN", function ()
        local sns_type = arg0
        local token = arg1
        local open_id = arg2
        local open_key = arg3
        local url = arg4
        if token and token ~= "" then
            m_bind_flag = true
        else
            m_bind_flag = false
        end
        if self:sns_is_waiting_send()  then
            self:sns_modify_wait_flag(nil)
        elseif self:sns_is_waiting_openurl() then
            self:sns_modify_wait_flag(nil)
            m_sns_bind_url = url
            if url and url ~= ""  then
                UIHelper.OpenWebWithDefaultBrowser(m_sns_bind_url)
            end
        end
        Event.Dispatch("ON_SYNC_SNS_TOAKEN", sns_type)
    end)

    Event.Reg(self, "ON_WEIBO_NOTIFY", function ()
        local sns_type = arg0
	    local ret = arg1
        local msg  = FormatString(g_tStrings.tWeiBo[ret], "")
        if ret == WEIBO_NOTIFY_CODE.BIND_SUCCESS then
            m_bind_flag = true
            TipsHelper.ShowNormalTip(msg)
            if sns_type == WEIBO_TYPE.SINA then
				self:UpdateSinaState()
			end
        elseif ret == WEIBO_NOTIFY_CODE.UNBIND_SUCCESS then
            m_bind_flag = false
            TipsHelper.ShowNormalTip(msg)
            Event.Dispatch("ON_SNS_NOTIFY", sns_type, ret)
        elseif ret == WEIBO_NOTIFY_CODE.BIND_FAILED then
            TipsHelper.ShowNormalTip(msg)
        elseif ret == WEIBO_NOTIFY_CODE.UNBIND_FAILED then
            TipsHelper.ShowNormalTip(msg)
        end
    end)

    Event.Reg(self, "SNS_TOKEN_INVALID", function ()
        local sns_type = arg0
        local hPlayer = GetClientPlayer()
        if hPlayer then
            hPlayer.ApplyWeiboToken(WEIBO_TYPE.SINA)
        end
        if sns_type == WEIBO_TYPE.SINA then
            self:UpdateSinaState()
        end
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        if UIHelper.GetVisible(self.WidgetSafetyRewardTips) then
            UIHelper.SetVisible(self.WidgetSafetyRewardTips,false)
            UIHelper.SetSelected(self.TogSafetyReward , false)
        end
    end)
end

function ServiceCenterAccountSafe:UnRegEvent()
    Event.UnRegAll(self)
    RedpointMgr.UnRegisterRedpoint(self.ImgRedPoint)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function ServiceCenterAccountSafe:UpdateInfo()
    self:UpdateScore()
    self:UpdateAwards()
    self:UpdateSafeBindState()
    self:UpdateMibaoEntityReward()
    self:UpdateSinaState()
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
    RedpointMgr.RegisterRedpoint(self.ImgRedPoint, nil, ServiceCenterData.tbRedPointIDs)
end

function ServiceCenterAccountSafe:UpdateScore()
    local safeScore = ServiceCenterData:GetSafeScore()
	if safeScore < 30 then
        UIHelper.SetSpriteFrame(self.ImgSecurityLevelIcon, tbSafeIcon[1])
        UIHelper.SetString(self.LabelLevel , g_tStrings.GM_SAFE_TYPE[1])
        UIHelper.SetString(self.LabelDescribe , g_tStrings.GM_SAFE_TITLE[1])
	elseif safeScore >= 30 and safeScore < 60 then
        UIHelper.SetSpriteFrame(self.ImgSecurityLevelIcon, tbSafeIcon[2])
        UIHelper.SetString(self.LabelLevel , g_tStrings.GM_SAFE_TYPE[2])
		UIHelper.SetString(self.LabelDescribe , g_tStrings.GM_SAFE_TITLE[2])
	elseif safeScore >= 60 and safeScore < 90 then
        UIHelper.SetSpriteFrame(self.ImgSecurityLevelIcon, tbSafeIcon[3])
        UIHelper.SetString(self.LabelLevel , g_tStrings.GM_SAFE_TYPE[3])
		UIHelper.SetString(self.LabelDescribe , g_tStrings.GM_SAFE_TITLE[3])
	elseif safeScore >= 90 then
        UIHelper.SetSpriteFrame(self.ImgSecurityLevelIcon, tbSafeIcon[4])
        UIHelper.SetString(self.LabelLevel , g_tStrings.GM_SAFE_TYPE[4])
		UIHelper.SetString(self.LabelDescribe , g_tStrings.GM_SAFE_TITLE[4])
	end
end

function ServiceCenterAccountSafe:UpdateAwards()
	local bBindEmail = ServiceCenterData:IsEMailBind()
	local bBindPhone = ServiceCenterData:IsPhoneBind()
	local bBindSafeLock = ServiceCenterData:IsSafeLockBind()
	local bCompleteBasic = bBindEmail and bBindPhone and bBindSafeLock

    UIHelper.SetVisible(self.BaseRewardOK , bCompleteBasic)

	local bMibaoType = ServiceCenterData:GetMibaoMode()
	local bCompleteMibao = false
	if bMibaoType == PASSPOD_MODE.TOKEN or bMibaoType == PASSPOD_MODE.MATRIX or bMibaoType == PASSPOD_MODE.PHONE then
		bCompleteMibao = true
	end
    UIHelper.SetVisible(self.AdvancedRewardOK , bCompleteBasic and bCompleteMibao)
end

function ServiceCenterAccountSafe:UpdateMibaoEntityReward()
    local item = ItemData.GetItemInfo(tAwards[1][1], tAwards[1][2])
    UIHelper.SetItemIconByItemInfo(self.ImgReward1, item)
    UIHelper.SetSpriteFrame(self.ImgPolishCountBG01, ItemQualityBGColor[item.nQuality + 1])

    item = ItemData.GetItemInfo(tAwards[2][1], tAwards[2][2])
    UIHelper.SetItemIconByItemInfo(self.ImgReward2, item)
    UIHelper.SetSpriteFrame(self.ImgPolishCountBG02, ItemQualityBGColor[item.nQuality + 1])
end

function ServiceCenterAccountSafe:UpdateSafeBindState()
    local hPlayer = GetClientPlayer()
    local bBindPhone = ServiceCenterData:IsPhoneBind()
    local bBindEmail = ServiceCenterData:IsEMailBind()
    local bBindSafeLock = ServiceCenterData:IsSafeLockBind()
    UIHelper.SetVisible(self.WidgetVerifyEmailOk , bBindEmail)
    UIHelper.SetVisible(self.WidgetVerifyPhoneOk , bBindPhone)
    UIHelper.SetVisible(self.WidgetVerifySafeLockOk , bBindSafeLock)
    UIHelper.SetVisible(self.BtnVerifyEmail , not bBindEmail)
    UIHelper.SetVisible(self.BtnVerifyPhone , not bBindPhone)
    UIHelper.SetVisible(self.BtnVerifySafeLock , not bBindSafeLock)
    UIHelper.SetVisible(self.WidgetVerifyMiBaoPhone , false)
    UIHelper.SetVisible(self.WidgetVerifyMiBaoEntity , false)
    local eMibaoType = ServiceCenterData:GetMibaoMode()
    if eMibaoType == PASSPOD_MODE.PHONE then
        UIHelper.SetVisible(self.BtnVerifyMiBaoPhone , false)
		UIHelper.SetVisible(self.WidgetVerifyMiBaoPhone , true)
	elseif eMibaoType == PASSPOD_MODE.TOKEN then
        UIHelper.SetVisible(self.BtnVerifyMiBaoEntity , false)
		UIHelper.SetVisible(self.WidgetVerifyMiBaoEntity , true)
	elseif eMibaoType == PASSPOD_MODE.UNBIND then
        UIHelper.SetVisible(self.BtnVerifyMiBaoPhone , true)
        UIHelper.SetVisible(self.BtnVerifyMiBaoEntity , true)
	end

    UIHelper.SetVisible(self.WidgetVerifyWeChat , self:IsServiceWeChatBind())
    UIHelper.SetVisible(self.WidgetVerifyWeChat01 , self:IsPublicWeChatBind())
    UIHelper.SetVisible(self.WidgetVerifyWechatManager , self:IsManagerWeChatBind())
    UIHelper.SetVisible(self.WidgetVerifyApp , self:IsAppBind())
end

function ServiceCenterAccountSafe:UpdateSinaState()
	local is_bind = self:IsSinaBind()
    UIHelper.SetVisible(self.BtnVerifySina , not is_bind)
    UIHelper.SetVisible(self.WidgetVerifySina , is_bind)
    UIHelper.SetVisible(self.BtnVerifySinaCancel , is_bind)
end

function ServiceCenterAccountSafe:IsServiceWeChatBind()
	local hPlayer = GetClientPlayer()
    if not hPlayer then
		return
	end
	local bBind = hPlayer.GetSNSBindFlag(SNS_BIND_TYPE.FOLLOW_WECHAT_JX3_SERVICE_ACCOUNT)
	return bBind
end

function ServiceCenterAccountSafe:IsPublicWeChatBind()
	local hPlayer = GetClientPlayer()
    if not hPlayer then
		return
	end
	local bBind = hPlayer.GetSNSBindFlag(SNS_BIND_TYPE.FOLLOW_WECHAT_JX3_SUBSCRIPTION_ACCOUNT)

	return bBind
end

function ServiceCenterAccountSafe:IsManagerWeChatBind()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

	local bBind = hPlayer.GetSNSBindFlag(SNS_BIND_TYPE.BIND_JX3_WECHAT_MANAGER)

	return bBind
end

function ServiceCenterAccountSafe:IsAppBind()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

	local bBind = hPlayer.GetSNSBindFlag(SNS_BIND_TYPE.BIND_JX3_ASSISTANT_APP)

	return bBind
end

function ServiceCenterAccountSafe:IsSinaBind()
    if m_bind_flag ~= nil then
		return m_bind_flag
	end
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

	local bBind = hPlayer.GetSNSBindFlag(SNS_BIND_TYPE.BIND_SINA_WEIBO)

	return bBind
end
function ServiceCenterAccountSafe:sns_enter_openurl()
    if not self:sns_is_waiting_send() and not self:sns_is_waiting_openurl() then
		self:sns_modify_wait_flag("url")
        local hPlayer = GetClientPlayer()
        if hPlayer then
            hPlayer.ApplyWeiboToken(WEIBO_TYPE.SINA)
        end
	else
        TipsHelper.ShowNormalTip(FormatString(g_tStrings.tWeiBo.URLOPENING, g_tStrings.WEI_BO_S_NAME))
	end
end

function ServiceCenterAccountSafe:sns_is_waiting_send()
	return (m_sns_wait_flag == "send")
end

function ServiceCenterAccountSafe:sns_is_waiting_openurl()
	return (m_sns_wait_flag == "url")
end

function ServiceCenterAccountSafe:sns_modify_wait_flag(flag)
	m_sns_wait_flag = flag
	local cost_time = 60 * 1000
	if m_sns_wait_flag  == "send" or m_sns_wait_flag == "url" then
        Timer.DelTimer(self , self.sns_timeID)
		self.sns_timeID = Timer.Add(self , cost_time , function ()
            self:sns_modify_wait_flag(nil)
        end)
	end
end

return ServiceCenterAccountSafe