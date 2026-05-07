-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandInteractWarehouseFilter
-- Date: 2023-08-28 10:55:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandInteractWarehouseFilter = class("UIHomelandInteractWarehouseFilter")

function UIHomelandInteractWarehouseFilter:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    UIHelper.SetTouchDownHideTips(self.TogSettleAccounts, false)
end

function UIHomelandInteractWarehouseFilter:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandInteractWarehouseFilter:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSettleAccounts, EventType.OnClick, function()
        self.funcCallBack()
    end)
end

function UIHomelandInteractWarehouseFilter:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandInteractWarehouseFilter:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandInteractWarehouseFilter:UpdateInfo()
    
end

function UIHomelandInteractWarehouseFilter:SetSelect(bSelected)
    UIHelper.SetSelected(self.TogSettleAccounts, bSelected)
end

function UIHomelandInteractWarehouseFilter:SetfuncCallBack(funcCallBack)
    self.funcCallBack = funcCallBack
end

return UIHomelandInteractWarehouseFilter