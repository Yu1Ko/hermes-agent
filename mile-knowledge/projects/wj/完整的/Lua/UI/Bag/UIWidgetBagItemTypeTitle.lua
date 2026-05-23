-- ---------------------------------------------------------------------------------
-- Author: liuyumin
-- Name: UIWidgetBagItemTypeTitle
-- Date: 2024-01-23 11:12:34
-- Desc: ?
-- ---------------------------------------------------------------------------------



---@class UIWidgetBagItemTypeTitle
local UIWidgetBagItemTypeTitle = class("UIWidgetBagItemTypeTitle")

function UIWidgetBagItemTypeTitle:OnEnter(ScrollBagTypeList, tbSelectedTabCfg, nIndex)
    self.nIndex = nIndex
    self.tbSelectedTabCfg = tbSelectedTabCfg
    self.ScrollBagTypeList = ScrollBagTypeList
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbBox = {}
    self:UpdateInfo()
end

function UIWidgetBagItemTypeTitle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetBagItemTypeTitle:BindUIEvent()
    UIHelper.SetClickInterval(self.TogSettingsMultipleChoice, 0.01)
    UIHelper.BindUIEvent(self.TogSettingsMultipleChoice, EventType.OnClick, function()
        local bSelected = UIHelper.GetSelected(self.TogSettingsMultipleChoice)
        self:UpdateTogSelected(bSelected)
    end)
end

function UIWidgetBagItemTypeTitle:RegEvent()

end

function UIWidgetBagItemTypeTitle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetBagItemTypeTitle:UpdateInfo()
    UIHelper.SetString(self.LabelSettingsMultipleChoiceTitle, self.tbSelectedTabCfg.szName)
end

function UIWidgetBagItemTypeTitle:UpdateTogSelected(bSelected)
    local bHasCell = self:HasCell()
    if not bHasCell and bSelected then
        return -- 没有cell时不允许展开
    end
    UIHelper.SetSelected(self.TogSettingsMultipleChoice, bSelected)
    --local bSelected = UIHelper.GetSelected(self.TogSettingsMultipleChoice)

    --UIHelper.SetVisible(self.WidgetEmpty, not bHasCell and bSelected)
    UIHelper.SetVisible(self.LayoutContainer, bHasCell and bSelected)

    UIHelper.LayoutDoLayout(self.LayoutContainer)
    UIHelper.LayoutDoLayout(self._rootNode)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollBagTypeList)
    UIHelper.ScrollToIndex(self.ScrollBagTypeList, self.nIndex)
end

function UIWidgetBagItemTypeTitle:HasCell()
    return UIHelper.GetChildrenCount(self.LayoutContainer) > 0
end

function UIWidgetBagItemTypeTitle:UpdateLayout()
    local bHasCell = UIHelper.GetChildrenCount(self.LayoutContainer) > 0
    local bSelected = UIHelper.GetSelected(self.TogSettingsMultipleChoice)
    --UIHelper.SetVisible(self.WidgetEmpty, not bHasCell and bSelected)
    
    UIHelper.SetVisible(self.LayoutContainer, bHasCell and bSelected)
    UIHelper.LayoutDoLayout(self.LayoutContainer)
    UIHelper.LayoutDoLayout(self._rootNode)

    UIHelper.SetEnable(self.TogSettingsMultipleChoice, bHasCell)
    UIHelper.SetOpacity(self._rootNode, not bHasCell and 128 or 255)
    UIHelper.SetVisible(self.TogSettingsMultipleChoice, bHasCell)
    
    if not bHasCell and bSelected then
        UIHelper.SetSelected(self.TogSettingsMultipleChoice, false)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollBagTypeList)
end

function UIWidgetBagItemTypeTitle:GetLayout()
    return self.LayoutContainer
end

return UIWidgetBagItemTypeTitle