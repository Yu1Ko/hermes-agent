-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPasswordIsResettingView
-- Date: 2023-03-06 17:25:46
-- Desc: 安全锁-密码重置中
-- Prefab: PanelPasswordResetPop
-- ---------------------------------------------------------------------------------

local UIPasswordIsResettingView = class("UIPasswordIsResettingView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPasswordIsResettingView:_LuaBindList()
    self.BtnCloseRightTop        = self.BtnCloseRightTop --- 右上角的关闭按钮
    self.BtnCloseLeftBottom      = self.BtnCloseLeftBottom --- 左下角的关闭按钮
    self.BtnCancelReset          = self.BtnCancelReset --- 取消重置
    self.LabelResetRemainingTime = self.LabelResetRemainingTime --- 剩余重置时间
end

function UIPasswordIsResettingView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    
    self:UpdateInfo()
end

function UIPasswordIsResettingView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPasswordIsResettingView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCloseRightTop, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCloseLeftBottom, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancelReset, EventType.OnClick, function()
        self:CancelReset()
    end)
end

function UIPasswordIsResettingView:RegEvent()
    Event.Reg(self, "BANK_LOCK_RESPOND", function(szResult, nCode)
        if szResult == "CANCEL_RESET_BANK_PASSWORD_SUCCESS" then
            UIMgr.Close(self)
        end
    end)
end

function UIPasswordIsResettingView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPasswordIsResettingView:UpdateInfo()
    local player = GetClientPlayer()
    if not player then
        return
    end
    
    UIHelper.SetString(self.LabelResetRemainingTime, "")
    
    local nLeftTime = player.nBankPasswordResetEndTime - GetCurrentTime()
    if nLeftTime > 0 then
        local szTime = TimeLib.GetTimeText(nLeftTime, false, true)
        UIHelper.SetString(self.LabelResetRemainingTime, szTime)
    else
        UIHelper.SetString(self.LabelResetRemainingTime, "")
    end
end

function UIPasswordIsResettingView:CancelReset()
    UIHelper.RemoteCallToServer(BankLock.tRemoteFun.CancelReset)
end

return UIPasswordIsResettingView