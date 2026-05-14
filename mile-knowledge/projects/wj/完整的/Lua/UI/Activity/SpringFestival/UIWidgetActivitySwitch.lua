-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetActivitySwitch
-- Date: 2025-01-14 20:12:11
-- Desc: 年兽陶罐-自动砸罐 开关选择 PanelNianShouTaobaoGuanSetting-WidgetActivitySwitch
-- ---------------------------------------------------------------------------------

local UIWidgetActivitySwitch = class("UIWidgetActivitySwitch")

function UIWidgetActivitySwitch:OnEnter(szTitle, bEnable)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.SetLabel(self.LabelTitle, szTitle)
    UIHelper.SetSelected(self.ToggleEnable, bEnable, false)
end

function UIWidgetActivitySwitch:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetActivitySwitch:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleEnable, EventType.OnSelectChanged, function(_, bSelected)
        if self.fnCallback then
            self.fnCallback(bSelected)
        end
    end)
    
end

function UIWidgetActivitySwitch:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetActivitySwitch:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetActivitySwitch:UpdateInfo()
    
end

function UIWidgetActivitySwitch:BindCallback(fnCallback)
    self.fnCallback = fnCallback
end


return UIWidgetActivitySwitch