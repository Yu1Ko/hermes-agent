-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetTradeTypeFilter
-- Date: 2023-03-27 19:51:18
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetTradeTypeFilter = class("UIWidgetTradeTypeFilter")

function UIWidgetTradeTypeFilter:OnEnter(tbInfo, scriptPanelSearchItem, tbTypeToggleInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbInfo = tbInfo
    self.scriptPanelSearchItem = scriptPanelSearchItem
    self.tbTypeToggleInfo = tbTypeToggleInfo
    self:UpdateInfo()
end

function UIWidgetTradeTypeFilter:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetTradeTypeFilter:BindUIEvent()
    UIHelper.BindUIEvent(self._rootNode, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            if self.scriptPanelSearchItem then
                self.scriptPanelSearchItem:SetSortID(self.tbInfo.nSortID)
            end
        end
    end)
end

function UIWidgetTradeTypeFilter:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetTradeTypeFilter:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTradeTypeFilter:UpdateInfo()
    UIHelper.SetString(self.LabelStyleFilterMain, self.tbInfo.szName)
    UIHelper.SetString(self.LabelStyleFilterMainUp, self.tbInfo.szName)
    UIHelper.SetTouchDownHideTips(self._rootNode, false)
    if self.tbInfo.nSortID then
        self.tbTypeToggleInfo[self.tbInfo.nSortID + 1] = self._rootNode
    end
end




return UIWidgetTradeTypeFilter