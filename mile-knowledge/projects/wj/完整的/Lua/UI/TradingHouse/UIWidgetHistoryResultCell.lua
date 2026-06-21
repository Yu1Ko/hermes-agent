-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetHistoryResultCell
-- Date: 2023-03-27 17:00:58
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetHistoryResultCell = class("UIWidgetHistoryResultCell")

function UIWidgetHistoryResultCell:OnEnter(szItemName, scriptSearchItem)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szItemName = szItemName
    self.scriptSearchItem = scriptSearchItem
    self:UpdateInfo()
end

function UIWidgetHistoryResultCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetHistoryResultCell:BindUIEvent()
    UIHelper.BindUIEvent(self._rootNode, EventType.OnClick, function()
        self.scriptSearchItem:SetItemName(self.szItemName)
        TradingData.ApplyNormalLookUp(true, 1, 0, 0, -1, self.szItemName)
    end)

    UIHelper.BindUIEvent(self.BtnDeleteResult, EventType.OnClick, function()
        TradingData.DeleteHistoryByName(self.szItemName)
        self.scriptSearchItem:UpdateInfo_History()
    end)
end

function UIWidgetHistoryResultCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetHistoryResultCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetHistoryResultCell:UpdateInfo()
    UIHelper.SetString(self.LabelTargetTitle, self.szItemName, 10)
    UIHelper.SetSwallowTouches(self.BtnDeleteResult, true)
end


return UIWidgetHistoryResultCell