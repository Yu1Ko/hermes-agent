-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPasswordUnlockView
-- Date: 2023-03-06 16:05:32
-- Desc: 安全锁-解锁
-- Prefab: PanelPasswordUnlockPop
-- ---------------------------------------------------------------------------------

local UIPasswordUnlockView = class("UIPasswordUnlockView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPasswordUnlockView:_LuaBindList()
    self.BtnClose          = self.BtnClose --- 关闭界面
    self.BtnCancel         = self.BtnCancel --- 取消
    self.BtnConfirm        = self.BtnConfirm --- 确认
    self.EditBoxPassword   = self.EditBoxPassword --- 密码的 edit box
    self.BtnForgetPassword = self.BtnForgetPassword --- 打开忘记密码界面

    self.BtnLingLongMiBao  = self.BtnLingLongMiBao --- 去绑定玲珑密保锁
end

function UIPasswordUnlockView:OnEnter(fnUnLockAction)
    self.fnUnLockAction = fnUnLockAction
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    
    self:UpdateInfo()
end

function UIPasswordUnlockView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPasswordUnlockView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        self:UnlockPassword()
    end)

    UIHelper.BindUIEvent(self.BtnForgetPassword, EventType.OnClick, function()
        if not self:IsWrongStateAccount() then
            UIMgr.Open(VIEW_ID.PanelForgetPasswoedPop)
        else
            BankLock.ResetPassword()
        end
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnLingLongMiBao , EventType.OnClick , function ()
        UIHelper.OpenWebWithDefaultBrowser(tUrl.ShoujibanCard)
    end)
end

function UIPasswordUnlockView:RegEvent()
    Event.Reg(self, "BANK_LOCK_RESPOND", function(szResult, nCode)
        if szResult == "VERIFY_BANK_PASSWORD_SUCCESS" then

            if self.fnUnLockAction then
                self.fnUnLockAction()
            end

            UIMgr.Close(self)
        end
    end)
end

function UIPasswordUnlockView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPasswordUnlockView:UpdateInfo()
    if self:IsWrongStateAccount() then
        local label = UIHelper.GetChildren(self.BtnForgetPassword)[1]

        UIHelper.SetString(label, "重置密码")
    end
end

function UIPasswordUnlockView:UnlockPassword()
    local szPassword = UIHelper.GetString(self.EditBoxPassword)

    UIHelper.RemoteCallToServer(BankLock.tRemoteFun.Verify, UIHelper.MD5(szPassword))
end

function UIPasswordUnlockView:IsWrongStateAccount()
    --- 存在部分账号，有密保锁，但是没有密保问题。也许是在添加密保问题功能之前版本设置的密保锁，这种账号不支持忘记密码（需要密保问题），这种情况将忘记密码按钮修改为重置密码
    return g_pClientPlayer.nBankPasswordQuestionID == 0
end

return UIPasswordUnlockView