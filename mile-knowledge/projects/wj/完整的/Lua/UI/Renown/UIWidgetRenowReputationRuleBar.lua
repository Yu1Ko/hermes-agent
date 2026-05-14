local UIWidgetRenowReputationRuleBar = class("UIWidgetRenowReputationRuleBar")


function UIWidgetRenowReputationRuleBar:OnEnter(tData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if not tData then
        return
    end
    self.tData = tData
    self:UpdateInfo(tData)
end

function UIWidgetRenowReputationRuleBar:OnExit()
    self.bInit = false
end

function UIWidgetRenowReputationRuleBar:BindUIEvent()

end

function UIWidgetRenowReputationRuleBar:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetRenowReputationRuleBar:UpdateInfo(tData)
    UIHelper.SetString(self.LabelTitle, tData.szLevel)
    UIHelper.SetRichText(self.RichTextContent, tData.szDesc)
end

return UIWidgetRenowReputationRuleBar