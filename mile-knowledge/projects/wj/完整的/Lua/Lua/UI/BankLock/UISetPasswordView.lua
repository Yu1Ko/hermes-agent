-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UISetPasswordView
-- Date: 2023-03-03 16:12:21
-- Desc: 安全锁-设置密码
-- Prefab: PanelSetPasswordPop
-- ---------------------------------------------------------------------------------

local UISetPasswordView = class("UISetPasswordView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UISetPasswordView:_LuaBindList()
    self.BtnClose               = self.BtnClose --- 关闭界面
    self.BtnCancel              = self.BtnCancel --- 取消
    self.BtnConfirm             = self.BtnConfirm --- 确认

    self.EditBoxPassword        = self.EditBoxPassword --- 密码
    self.EditBoxPasswordConfirm = self.EditBoxPasswordConfirm --- 再次输入的密码
    self.EditBoxAnswer          = self.EditBoxAnswer --- 密保问题的答案

    self.TogQuestion            = self.TogQuestion --- 密保问题列表的 toggle
    self.tbBtnQuestionList      = self.tbBtnQuestionList --- 密保问题选项按钮 的列表
    self.LabelSelectedQuestion  = self.LabelSelectedQuestion --- 当前选择的问题的 label
end

function UISetPasswordView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UISetPasswordView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISetPasswordView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        self:SetPassword()
    end)

    self.nSelectedQuestionID = -1
    for idx, btnQuestion in ipairs(self.tbBtnQuestionList) do
        UIHelper.BindUIEvent(btnQuestion, EventType.OnClick, function()
            self.nSelectedQuestionID = idx
            UIHelper.SetString(self.LabelSelectedQuestion, g_tStrings.tBankQuestion[idx])
            UIHelper.SetSelected(self.TogQuestion, false)
        end)
    end
end

function UISetPasswordView:RegEvent()
    Event.Reg(self, "BANK_LOCK_RESPOND", function(szResult, nCode)
        if szResult == "SET_BANK_PASSWORD_SUCCESS" then
            UIMgr.Close(self)
        end
    end)
end

function UISetPasswordView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

local tLockSet_Config =  --- 表示密码要保护哪些业务；漏掉了逻辑常量里另外几个枚举值。实际上并未用到~
{
    [SAFE_LOCK_EFFECT_TYPE.TRADE] = true,
    [SAFE_LOCK_EFFECT_TYPE.AUCTION] = true,
    [SAFE_LOCK_EFFECT_TYPE.SHOP] = true,
    [SAFE_LOCK_EFFECT_TYPE.MAIL] = true,
    [SAFE_LOCK_EFFECT_TYPE.TONG_DONATE] = true,
    [SAFE_LOCK_EFFECT_TYPE.TONG_PAY_SALARY] = true,
    [SAFE_LOCK_EFFECT_TYPE.EQUIP] = true,
    [SAFE_LOCK_EFFECT_TYPE.BANK] = true,
    [SAFE_LOCK_EFFECT_TYPE.TONG_REPERTORY] = true,
}

function UISetPasswordView:UpdateInfo()

end

function UISetPasswordView:SetPassword()
    local szPassword = UIHelper.GetString(self.EditBoxPassword)
    local szPasswordConfirm = UIHelper.GetString(self.EditBoxPasswordConfirm)
    local nQuestionID = self.nSelectedQuestionID
    local szAnswer = UIHelper.GetString(self.EditBoxAnswer)

    if szPassword ~= szPasswordConfirm then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_BANK_PASSWORD_NOT_SAME)
        return
    end

    if nQuestionID == -1 then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_PASSWORD_MUST_CHOOSE_QUESTION)
        return
    end

    if not szAnswer or szAnswer == "" then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_BANK_PASSWORD_CANT_EMPTY_ANSWER)
        return
    end

    if nQuestionID >= 1 and nQuestionID <= #g_tStrings.tBankQuestion then
        UIHelper.RemoteCallToServer(BankLock.tRemoteFun.Set, UIHelper.MD5(szPassword), nQuestionID, szAnswer, tLockSet_Config) --- 最后的参数并未被用到
    end
end

return UISetPasswordView