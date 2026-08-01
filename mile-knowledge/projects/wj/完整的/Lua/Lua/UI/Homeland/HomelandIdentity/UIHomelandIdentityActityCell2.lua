-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandIdentityActityCell2
-- Date: 2024-01-18 16:54:47
-- Desc: ?
-- ---------------------------------------------------------------------------------
local UIHomelandIdentityActityCell2 = class("UIHomelandIdentityActityCell2")

function UIHomelandIdentityActityCell2:OnEnter(szTitile, szData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szTitile = szTitile
    self.szData = szData
    self:UpdateInfo()
end

function UIHomelandIdentityActityCell2:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandIdentityActityCell2:BindUIEvent()
    
end

function UIHomelandIdentityActityCell2:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandIdentityActityCell2:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandIdentityActityCell2:UpdateInfo()
    UIHelper.SetString(self.LabelOrder, self.szTitile)
    UIHelper.SetString(self.LabelOrderNum, self.szData)
end


return UIHomelandIdentityActityCell2