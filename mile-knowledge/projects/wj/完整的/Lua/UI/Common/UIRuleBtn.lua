-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRuleBtn
-- Date: 2023-02-23 09:34:21
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIRuleBtn = class("UIRuleBtn")

function UIRuleBtn:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIRuleBtn:OnExit()
    self.bInit = false
end

function UIRuleBtn:BindUIEvent()
    UIHelper.BindUIEvent(self._rootNode, EventType.OnClick, function()
        if not self.szRuleID or self.szRuleID == "" then
            return
        end
        UIMgr.Open(VIEW_ID.PanelHelpPop, tonumber(self.szRuleID))
    end)
end

return UIRuleBtn