-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIForgetPasswordView
-- Date: 2023-03-06 16:45:21
-- Desc: 安全锁-忘记密码
-- Prefab: PanelForgetPasswoedPop
-- ---------------------------------------------------------------------------------

local UIForgetPasswordView = class("UIForgetPasswordView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIForgetPasswordView:_LuaBindList()
    self.BtnClose               = self.BtnClose --- 关闭界面
    self.BtnCancel              = self.BtnCancel --- 取消
    self.BtnConfirm             = self.BtnConfirm --- 确定
    self.BtnResetPasswords      = self.BtnResetPasswords --- 打开重置密码界面

    self.LabelQuestion          = self.LabelQuestion --- 密码问题
    self.EditBoxAnswer          = self.EditBoxAnswer --- 回答问题
    self.EditBoxPassword        = self.EditBoxPassword --- 密码
    self.EditBoxPasswordConfirm = self.EditBoxPasswordConfirm --- 再次输入密码，用于确认

    self.BtnLingLongMiBao  = self.BtnLingLongMiBao --- 去绑定玲珑密保锁
end

function UIForgetPasswordView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIForgetPasswordView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIForgetPasswordView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        self:ForgetPassword()
    end)

    UIHelper.BindUIEvent(self.BtnResetPasswords, EventType.OnClick, function()
        self:ResetPassword()
    end)

    UIHelper.BindUIEvent(self.BtnLingLongMiBao , EventType.OnClick , function ()
        UIHelper.OpenWebWithDefaultBrowser(tUrl.ShoujibanCard)
    end)
end

function UIForgetPasswordView:RegEvent()
    Event.Reg(self, "BANK_LOCK_RESPOND", function(szResult, nCode)
        if szResult == "MODIFY_BANK_PASSWORD_SUCCESS" then
            UIMgr.Close(self)
        elseif szResult == "RESET_BANK_PASSWORD_SUCCESS" then
            UIMgr.Close(self)
        end
    end)
end

function UIForgetPasswordView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIForgetPasswordView:UpdateInfo()
    local nBankPasswordQuestionID = GetClientPlayer().nBankPasswordQuestionID
    if nBankPasswordQuestionID == 0 then
        UIMgr.Close(self)
        return
    end

    UIHelper.SetString(self.LabelQuestion, g_tStrings.tBankQuestion[nBankPasswordQuestionID])
end

function UIForgetPasswordView:ForgetPassword()
    local szAnswer          = UIHelper.GetString(self.EditBoxAnswer)
    local szPassword        = UIHelper.GetString(self.EditBoxPassword)
    local szPasswordConfirm = UIHelper.GetString(self.EditBoxPasswordConfirm)

    if szPassword ~= szPasswordConfirm then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_BANK_PASSWORD_NOT_SAME)
        return
    end

    if szAnswer == nil or szAnswer == "" then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_BANK_PASSWORD_CANT_EMPTY_ANSWER)
        return
    end

    local nQuestionID = GetClientPlayer().nBankPasswordQuestionID
    if nQuestionID >= 1 and nQuestionID <= #g_tStrings.tBankQuestion then
        UIHelper.RemoteCallToServer(BankLock.tRemoteFun.Modify, szAnswer, UIHelper.MD5(szPassword))
    end
end

function UIForgetPasswordView:ResetPassword()
    BankLock.ResetPassword()
end

return UIForgetPasswordView