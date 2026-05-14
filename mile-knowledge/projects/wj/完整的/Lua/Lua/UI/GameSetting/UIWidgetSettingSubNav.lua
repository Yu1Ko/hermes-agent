-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetSettingSubNav
-- Date: 2023-11-16 15:46:18
-- Desc: WidgetSettingSubNav
-- ---------------------------------------------------------------------------------

local UIWidgetSettingSubNav = class("UIWidgetSettingSubNav")

function UIWidgetSettingSubNav:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.SetSwallowTouches(self.ToggleChildNavigation, false)

    local szName, bRecommend
    if IsString(tInfo) then
        szName = tInfo
    elseif IsTable(tInfo) then
        szName = tInfo.szTitle
        bRecommend = tInfo.bRecommend
    end

    self:UpdateInfo(szName, bRecommend)
end

function UIWidgetSettingSubNav:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSettingSubNav:BindUIEvent()

end

function UIWidgetSettingSubNav:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetSettingSubNav:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSettingSubNav:UpdateInfo(szName, bRecommend)
    if szName then
        self.szName = szName
        UIHelper.SetString(self.LabelChildNavigationNormal, szName)
        UIHelper.SetString(self.LabelChildNavigationSelect, szName)
    end

    UIHelper.SetVisible(self.ImgRecommend, bRecommend or false)
end

function UIWidgetSettingSubNav:SetToggleGroup(toggleGroup)
    UIHelper.ToggleGroupAddToggle(toggleGroup, self.ToggleChildNavigation)
end

function UIWidgetSettingSubNav:SetSelected(bSelected, bCallback)
    UIHelper.SetSelected(self.ToggleChildNavigation, bSelected, bCallback)
end

function UIWidgetSettingSubNav:GetName(bSelected)
    return self.szName
end

return UIWidgetSettingSubNav