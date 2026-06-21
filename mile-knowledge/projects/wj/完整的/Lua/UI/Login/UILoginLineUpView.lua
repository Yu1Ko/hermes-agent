-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UILoginLineUpView
-- Date: 2022-12-08 16:53:57
-- Desc: 登录等待服务器消息提示界面 PanelLoginLineUp
-- ---------------------------------------------------------------------------------

local UILoginLineUpView = class("UILoginLineUpView")

function UILoginLineUpView:OnEnter(tMsg)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    tMsg = tMsg or WaitingTipsData.GetCurWaitingTipsData()
    self:UpdateInfo(tMsg)
end

function UILoginLineUpView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    if self.bHidePage then
        UIMgr.ShowLayer(UILayer.Page)
    end
end

function UILoginLineUpView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function ()
        if self.fnCancelCallback then
            self.fnCancelCallback()
        end
    end)
end

function UILoginLineUpView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UILoginLineUpView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UILoginLineUpView:UpdateInfo(tMsg)
    local szWaitingMsg = tMsg.szWaitingMsg or ""
    local fnCancelCallback = tMsg.fnCancelCallback
    local bHidePage = tMsg.bHidePage or false
    local bSwallow = tMsg.bSwallow or false

    self:SetWaitingMsg(szWaitingMsg)
    if self.bHidePage ~= bHidePage then
        self.bHidePage = bHidePage
        if bHidePage then
            UIMgr.HideLayer(UILayer.Page)
        else
            UIMgr.ShowLayer(UILayer.Page)
        end
    end
    UIHelper.SetSwallowTouches(self.WidgetTouchMask, bSwallow)
    if fnCancelCallback then
        self:SetCancelCallback(fnCancelCallback)
    else
        UIHelper.SetVisible(self.BtnCancel, false)
        UIHelper.LayoutDoLayout(self.LayoutBtn)
    end
end

function UILoginLineUpView:SetWaitingMsg(szWaitingMsg)
    szWaitingMsg = szWaitingMsg or ""
    UIHelper.SetString(self.LabelTips, szWaitingMsg)
    UIHelper.LayoutDoLayout(self.LayoutLoading)
end

function UILoginLineUpView:SetCancelCallback(fnCancelCallback)
    UIHelper.SetVisible(self.BtnCancel, true)
    self.fnCancelCallback = fnCancelCallback
    UIHelper.LayoutDoLayout(self.LayoutBtn)
end


return UILoginLineUpView