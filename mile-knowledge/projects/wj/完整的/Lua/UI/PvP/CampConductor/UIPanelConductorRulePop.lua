-- ---------------------------------------------------------------------------------
-- Name: UIPanelConductorRulePop
-- Desc: 攻防指挥手册说明弹出框
-- Prefab:PanelConductorRulePop
-- ---------------------------------------------------------------------------------

local UIPanelConductorRulePop = class("UIPanelConductorRulePop")

function UIPanelConductorRulePop:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIPanelConductorRulePop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelConductorRulePop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPanelConductorRulePop:RegEvent()
    
end

function UIPanelConductorRulePop:UnRegEvent()

end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

return UIPanelConductorRulePop