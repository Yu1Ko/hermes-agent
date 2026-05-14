-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIStatementRulePop
-- Date: 2026-03-12 16:12:50
-- Desc: 协议同意 弹窗
-- ---------------------------------------------------------------------------------

local UIStatementRulePop = class("UIStatementRulePop")

function UIStatementRulePop:OnEnter(szTitle, szContent, funcConfirm, funcCancel)
    self.szTitle = szTitle
    self.szContent = szContent
    self.funcConfirm = funcConfirm
    self.funcCancel = funcCancel

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIStatementRulePop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIStatementRulePop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function(btn)
        if self.funcConfirm then
            self.funcConfirm()
        end
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        _G.bIsStatementScrollBottom = false
        if self.funcCancel then
            self.funcCancel()
        end
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        _G.bIsStatementScrollBottom = false
        UIMgr.Close(self)
    end)
end

function UIStatementRulePop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIStatementRulePop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIStatementRulePop:UpdateInfo()
    UIHelper.SetString(self.LabelTitle, self.szTitle or "")
    UIHelper.SetString(self.LabelContent, self.szContent or "")

    UIHelper.ScrollViewDoLayout(self.ScrollView)
    UIHelper.ScrollToTop(self.ScrollView, 0)

    Timer.DelAllTimer(self)
    Timer.AddFrame(self, 1, function()
        self:UpdateButton()
    end)
end

function UIStatementRulePop:UpdateButton()
    local nState = _G.bIsStatementScrollBottom and BTN_STATE.Normal or BTN_STATE.Disable
    UIHelper.SetButtonState(self.BtnAccept, nState, "请先翻阅温馨提示，再点击接受", true)

    UIHelper.BindUIEvent(self.ScrollView, EventType.OnScrollingScrollView, function(_, eventType)
        local nPercent = UIHelper.GetScrollPercent(self.ScrollView)
        if nPercent >= 100 then
            _G.bIsStatementScrollBottom = true
            self:UpdateButton()
            UIHelper.UnBindUIEvent(self.ScrollView, EventType.OnScrollingScrollView)
        end
    end)
end

function UIStatementRulePop:SetConfirmLabel(szVal)
    if string.is_nil(szVal) then
        return
    end
    UIHelper.SetString(self.LabelAccept, szVal)
end

function UIStatementRulePop:SetCancelLabel(szVal)
    if string.is_nil(szVal) then
        return
    end
    UIHelper.SetString(self.LabelCancel, szVal)
end

function UIStatementRulePop:ShowCancel(bShow)
    UIHelper.SetVisible(self.BtnCancel, bShow)
end



return UIStatementRulePop