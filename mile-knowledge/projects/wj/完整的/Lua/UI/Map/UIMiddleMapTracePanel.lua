local UIMiddleMapTracePanel = class("UIMiddleMapTracePanel")

function UIMiddleMapTracePanel:RegisterEvent()
    UIHelper.BindUIEvent(self.BtnClose03, EventType.OnClick, function()
        Event.Dispatch("ON_MIDDLE_MAP_MARK_UNCHECK")
        self:Hide()
    end)
end

function UIMiddleMapTracePanel:OnEnter()
    self._rootNode:setVisible(false)
    self:RegisterEvent()

    self.QuestScript = UIHelper.GetBindScript(self.WidgerAnchorTrace)
    -- self.MerchantScript = UIHelper.GetBindScript(self.WidgerAnchorMerchant)
end

function UIMiddleMapTracePanel:ShowQuest(tbInfo, nMapID, tPoint, bTrace, szFrame)
    self._rootNode:setVisible(true)
    -- self.WidgerAnchorMerchant:setVisible(false)
    self.WidgerAnchorTrace:setVisible(true)
    self.QuestScript:Show(tbInfo, nMapID, tPoint, bTrace, szFrame)
end


function UIMiddleMapTracePanel:Hide()
    self._rootNode:setVisible(false)
end

return UIMiddleMapTracePanel