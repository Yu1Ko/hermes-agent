-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopParticularsTipsContent
-- Date: 2023-04-07 11:28:37
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopParticularsTipsContent = class("UICoinShopParticularsTipsContent")

function UICoinShopParticularsTipsContent:OnEnter(szContent)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szContent = szContent
    self:UpdateInfo()
end

function UICoinShopParticularsTipsContent:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopParticularsTipsContent:BindUIEvent()
end

function UICoinShopParticularsTipsContent:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICoinShopParticularsTipsContent:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopParticularsTipsContent:UpdateInfo()
    UIHelper.SetString(self.LabelContentTitle01, self.szContent)
end

return UICoinShopParticularsTipsContent