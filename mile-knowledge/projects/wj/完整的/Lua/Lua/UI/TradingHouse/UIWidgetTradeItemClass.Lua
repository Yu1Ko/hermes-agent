-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetTradeItemClass
-- Date: 2023-07-05 15:41:38
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetTradeItemClass = class("UIWidgetTradeItemClass")

function UIWidgetTradeItemClass:OnEnter(tbInfo ,toggleGroup)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbInfo = tbInfo
    self.toggleGroup = toggleGroup
    self:UpdateInfo()
end

function UIWidgetTradeItemClass:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetTradeItemClass:BindUIEvent()

end

function UIWidgetTradeItemClass:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetTradeItemClass:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTradeItemClass:UpdateInfo()
    local tbInfo1 = self.tbInfo[1]
    local tbInfo2 = self.tbInfo[2]
    local bSell = tbInfo1.bSell
    UIHelper.SetVisible(self.WidgetClassBuy, not bSell)
    UIHelper.SetVisible(self.WidgetClassSell, bSell)
    UIHelper.SetVisible(self.WidgetTradeItemCell1, tbInfo1 ~= nil)
    UIHelper.SetVisible(self.WidgetTradeItemCell2, tbInfo2 ~= nil)
    UIHelper.SetVisible(self.WidgetTradeItemCell3, tbInfo1 ~= nil)
    UIHelper.SetVisible(self.WidgetTradeItemCell4, tbInfo2 ~= nil)
    self.tbScriptView = {}

    if tbInfo1 then
        local scriptView = bSell and UIHelper.GetBindScript(self.WidgetTradeItemCell3) or UIHelper.GetBindScript(self.WidgetTradeItemCell1)
        scriptView:OnEnter(tbInfo1, self.toggleGroup)
        table.insert(self.tbScriptView, scriptView)
    end
    if tbInfo2 then
        local scriptView = bSell and UIHelper.GetBindScript(self.WidgetTradeItemCell4) or UIHelper.GetBindScript(self.WidgetTradeItemCell2)
        scriptView:OnEnter(tbInfo2, self.toggleGroup)
        table.insert(self.tbScriptView, scriptView)
    end
end

function UIWidgetTradeItemClass:UpdateInfo_Selected(bSelectAll)
    for index, scriptView in ipairs(self.tbScriptView) do
        scriptView:UpdateInfo_Selected(bSelectAll)
    end
end

function UIWidgetTradeItemClass:SetSelected(nIndex, bSelect)
    local scriptView = self.tbScriptView[nIndex]
    if scriptView then
        scriptView:UpdateInfo_Selected(bSelect)
    end
end

return UIWidgetTradeItemClass