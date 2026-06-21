-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWishPanel
-- Date: 2024-04-07 19:21:08
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWishPanel = class("UIWishPanel")

function UIWishPanel:OnEnter(nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nIndex = nIndex
    self:UpdateInfo()
end

function UIWishPanel:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWishPanel:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function(btn)
        local szContent = UIHelper.GetString(self.EditBox)
        RemoteCallToServer("OnWishRequest", UIHelper.UTF8ToGBK(szContent), self.nIndex)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)
end

function UIWishPanel:RegEvent()
    -- Event.Reg(self, EventType.XXX, func)
end

function UIWishPanel:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWishPanel:UpdateInfo()
    
end


return UIWishPanel