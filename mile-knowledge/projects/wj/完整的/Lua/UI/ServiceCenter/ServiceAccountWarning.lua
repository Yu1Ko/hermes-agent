-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: ServiceAccountWarning
-- Date: 2024-03-21 15:00:48
-- Desc: 账号安全风险提示
-- ---------------------------------------------------------------------------------

local ServiceAccountWarning = class("ServiceAccountWarning")

function ServiceAccountWarning:OnEnter(bLoginWarning,nLoginTime,szCity)
    self.bLoginWarning = bLoginWarning
    self.nLoginTime = nLoginTime
    self.szCity = szCity
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function ServiceAccountWarning:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function ServiceAccountWarning:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnDes, EventType.OnClick , function ()
        
    end)

    UIHelper.BindUIEvent(self.BtnOk, EventType.OnClick , function ()
        UIHelper.OpenWeb(tUrl.ChangePwd)
    end)

    UIHelper.BindUIEvent(self.BtnCalloff, EventType.OnClick , function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnGo, EventType.OnClick , function ()
        UIMgr.Open(VIEW_ID.PanelUnlockAccount)
    end)
end

function ServiceAccountWarning:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function ServiceAccountWarning:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function ServiceAccountWarning:UpdateInfo()
    if ServiceCenterData.SafeReminder.nSecurityState == ACCOUNT_SECURITY_STATE.DANGER then
		UIHelper.SetString(self.LabelWarning , "您的账号存在风险！安全保护已启动！")
	elseif ServiceCenterData.SafeReminder.nSecurityState == ACCOUNT_SECURITY_STATE.SAFE then
		UIHelper.SetString(self.LabelWarning , "账号异常解除，可正常使用！")
	end
    UIHelper.SetVisible(self.BtnGo , ServiceCenterData.SafeReminder.nSecurityState == ACCOUNT_SECURITY_STATE.DANGER and not self.bLoginWarning)
    UIHelper.SetVisible(self.BtnOk , ServiceCenterData.SafeReminder.nSecurityState == ACCOUNT_SECURITY_STATE.DANGER )

    if ServiceCenterData.SafeReminder.nSecurityState ~= ACCOUNT_SECURITY_STATE.DANGER and self.bLoginWarning then
        UIHelper.SetString(UIHelper.GetChildByName(self.BtnCalloff , "LabelCalloff"), "确定")
    else
        UIHelper.SetString(UIHelper.GetChildByName(self.BtnCalloff , "LabelCalloff"), "取消")
    end

    UIHelper.LayoutDoLayout(self.LayoutBtn)
    
    if self.bLoginWarning then
        UIHelper.SetString(self.LabelTip, "如果上次不是您本人，请尽快查杀木马后，修改密码；\n如发现有解锁或物品被盗的情况，那么有可能是您的个人信息已经泄露，请尽快联系客服查明原因。")
        UIHelper.SetString(self.LabelSecurityLevel, string.format("当前账号等级为：%s",self:GetAccountScoreType()))
        UIHelper.SetRichText(self.LabelHint, "<color=#FFE26E>由于您的账号上次登录存在风险，我们对上次所有交易权限进行了锁定以保护您的账号安全。</c><color=#FFFFFF></color>")
        local t = TimeToDate(self.nLoginTime)
        local szTime = string.format("%d-%02d-%02d %02d:%02d", t.year, t.month, t.day, t.hour, t.minute)
        UIHelper.SetRichText(self.LabelInformation , string.format("<color=#FFFFFF>风险登录地点：%s\n风险登录时间：%s</color>",self.szCity,szTime))
    else
        UIHelper.SetString(self.LabelTip, "关闭后可在帮助-客服中心修改密码")
        UIHelper.SetString(self.LabelSecurityLevel, "当前账号已被限制行为")
        UIHelper.SetRichText(self.LabelHint, "1.本次登录地点异常\n2.或您的账号存在被盗风险，<color=#FFE26E>请尽快修改密码，</c><color=#FFFFFF>请不要使用与其他平台相同的密码。</color>")
        UIHelper.SetRichText(self.LabelInformation , "")
    end
    UIHelper.LayoutDoLayout(self.LayoutSecurityLevel)
end

function ServiceAccountWarning:GetAccountScoreType()
    local safeScore = ServiceCenterData:GetSafeScore()
	if safeScore < 30 then
       return g_tStrings.GM_SAFE_TYPE[1]
	elseif safeScore >= 30 and safeScore < 60 then
        return g_tStrings.GM_SAFE_TYPE[2]
	elseif safeScore >= 60 and safeScore < 90 then
        return g_tStrings.GM_SAFE_TYPE[3]
	elseif safeScore >= 90 then
        return g_tStrings.GM_SAFE_TYPE[4]
	end
    return ""
end

return ServiceAccountWarning