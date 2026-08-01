-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopReplaceConfirm
-- Date: 2023-05-11 17:22:22
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopReplaceConfirm = class("UICoinShopReplaceConfirm")

function UICoinShopReplaceConfirm:OnEnter(fnOld, fnNew)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.fnOld = fnOld
    self.fnNew = fnNew
    self:UpdateInfo()
end

function UICoinShopReplaceConfirm:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopReplaceConfirm:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCalloff, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnOld, EventType.OnClick, function ()
        UIMgr.Close(self)
        self.fnOld()
    end)

    UIHelper.BindUIEvent(self.BtnNew, EventType.OnClick, function ()
        UIMgr.Close(self)
        self.fnNew()
    end)
end

function UICoinShopReplaceConfirm:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICoinShopReplaceConfirm:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopReplaceConfirm:UpdateInfo()
    
end


return UICoinShopReplaceConfirm