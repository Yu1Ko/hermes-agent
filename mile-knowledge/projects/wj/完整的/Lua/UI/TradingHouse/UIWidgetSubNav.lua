-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSubNav
-- Date: 2023-03-07 09:35:38
-- Desc: 交易行购买界面左侧小分类按钮
-- ---------------------------------------------------------------------------------

local UIWidgetSubNav = class("UIWidgetSubNav")

function UIWidgetSubNav:OnEnter(tbData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if tbData then 
        self.szName = tbData.szName
        self.funcCallBack = tbData.funcCallBack
        self.toggleGroup = tbData.toggleGroup
        self.bLast = tbData.bLast
        self.bShowRedDot = tbData.bShowRedDot
        self:UpdateInfo()
    end
end

function UIWidgetSubNav:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSubNav:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSubNav, EventType.OnClick, function(toggle)
        local bSelect = UIHelper.GetSelected(self.TogSubNav)
        self:OnSelectChanged(bSelect)
    end)

    -- UIHelper.BindUIEvent(self.TogSubNav, EventType.OnSelectChanged, function(toggle, bSelect)
    --     local bSelect = UIHelper.GetSelected(self.TogSubNav)
    --     self:OnSelectChanged(bSelect)
    -- end)
end

function UIWidgetSubNav:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetSubNav:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSubNav:UpdateInfo()
    UIHelper.SetString(self.LabelNormal, self.szName)
    UIHelper.SetString(self.LabelUpAll01, self.szName)
    UIHelper.SetSwallowTouches(self.TogSubNav, false)
    UIHelper.ToggleGroupAddToggle(self.toggleGroup, self.TogSubNav)
    if self.bShowRedDot ~= nil then
        UIHelper.SetVisible(self.ImgNormalRedDot, self.bShowRedDot)
        UIHelper.SetVisible(self.ImgSelectedRedDot, self.bShowRedDot)
    end

    -- if self.bLast then
    --     UIHelper.SetSpriteFrame(self.ImgNavigationLine, "UIAtlas2_Public_PublicButton_PublicNavigation_Ce_ErjiLine_Last.png")
    -- end
end

function UIWidgetSubNav:SetSelected(bSelect)
    UIHelper.SetToggleGroupSelectedToggle(self.toggleGroup, self.TogSubNav)
end

function UIWidgetSubNav:RawSetSelected(bSelect)
    UIHelper.SetSelected(self.TogSubNav, bSelect, false)
end

function UIWidgetSubNav:GetName()
    return self.szName
end

function UIWidgetSubNav:GetToggle()
    return self.TogSubNav
end

function UIWidgetSubNav:SetScriptContainer(scriptContainer)
    self.scriptContainer = scriptContainer
end

function UIWidgetSubNav:OnSelectChanged(bSelect)
    -- if bSelect then
        self.funcCallBack(self, self.scriptContainer, bSelect)
    -- end
end

return UIWidgetSubNav