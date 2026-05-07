-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBuildFaceIconCell
-- Date: 2023-09-20 20:13:22
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetChangeCloakCell = class("UIWidgetChangeCloakCell")

function UIWidgetChangeCloakCell:OnEnter(szLabel, fnCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.BindUIEvent(self.TogChangeCloakCell, EventType.OnSelectChanged, fnCallback)
    UIHelper.SetString(self.LabelTitle_Normal, szLabel)
    UIHelper.SetString(self.LabelTitle_Selected, szLabel)

    --self:UpdateInfo()
end

function UIWidgetChangeCloakCell:OnExit()
    self.bInit = false
end

function UIWidgetChangeCloakCell:BindUIEvent()

end

function UIWidgetChangeCloakCell:RegEvent()
end

function UIWidgetChangeCloakCell:UpdateInfo()

end

return UIWidgetChangeCloakCell