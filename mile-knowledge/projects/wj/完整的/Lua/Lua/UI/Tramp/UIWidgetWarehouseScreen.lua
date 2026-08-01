-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetWarehouseScreen
-- Date: 2023-04-19 20:32:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetWarehouseScreen = class("UIWidgetWarehouseScreen")

function UIWidgetWarehouseScreen:OnEnter(tbData, funcCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbData = tbData
    self.funcCallBack = funcCallBack
    self:UpdateInfo()
end

function UIWidgetWarehouseScreen:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetWarehouseScreen:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSettleAccounts, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self.funcCallBack(self.tbData)
        end
    end)
end

function UIWidgetWarehouseScreen:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetWarehouseScreen:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetWarehouseScreen:UpdateInfo()
    UIHelper.SetString(self.LabelFullReduction, self.tbData.szName)
    UIHelper.SetString(self.LabelFullReduction01, self.tbData.szName)
    UIHelper.ToggleGroupAddToggle(self.tbData.ToggleGroup, self.TogSettleAccounts)
end


return UIWidgetWarehouseScreen