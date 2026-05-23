-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIKeyExchangePopView
-- Date: 2023-06-25 11:29:44
-- Desc: 激活码兑换
-- ---------------------------------------------------------------------------------

local UIKeyExchangePopView = class("UIKeyExchangePopView")

function UIKeyExchangePopView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIKeyExchangePopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIKeyExchangePopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        RemoteCallToServer("OnActivityPasswordReceived", UIHelper.GetText(self.EditBox), 1)
    end)
end

function UIKeyExchangePopView:RegEvent()

end

function UIKeyExchangePopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIKeyExchangePopView:UpdateInfo()
    
end


return UIKeyExchangePopView