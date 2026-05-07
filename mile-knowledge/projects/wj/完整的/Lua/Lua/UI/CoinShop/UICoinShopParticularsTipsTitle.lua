-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopParticularsTipsTitle
-- Date: 2023-04-07 11:33:34
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopParticularsTipsTitle = class("UICoinShopParticularsTipsTitle")

function UICoinShopParticularsTipsTitle:OnEnter(szTitle)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szTitle = szTitle
    self:UpdateInfo()
end

function UICoinShopParticularsTipsTitle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopParticularsTipsTitle:BindUIEvent()
    
end

function UICoinShopParticularsTipsTitle:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICoinShopParticularsTipsTitle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopParticularsTipsTitle:UpdateInfo()
    UIHelper.SetString(self.LabelContentTitle03, self.szTitle)
end


return UICoinShopParticularsTipsTitle