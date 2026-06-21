-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamRecruitBreadNaviItem
-- Date: 2023-02-09 10:22:27
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UITeamRecruitBreadNaviItem
local UITeamRecruitBreadNaviItem = class("UITeamRecruitBreadNaviItem")

function UITeamRecruitBreadNaviItem:OnEnter(tbMenu, bSuper, fnAction)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbMenu = tbMenu
    self.bSuper = bSuper
    self.fnAction = fnAction
    self:UpdateInfo()
end

function UITeamRecruitBreadNaviItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITeamRecruitBreadNaviItem:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBreadNavi, EventType.OnClick, function ()
        self.fnAction(self.tbMenu)
    end)
end

function UITeamRecruitBreadNaviItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITeamRecruitBreadNaviItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamRecruitBreadNaviItem:UpdateInfo()
    UIHelper.SetVisible(self.WidgetBreadNavi01, self.bSuper)
    UIHelper.SetVisible(self.WidgetBreadNavi02, not self.bSuper)

    UIHelper.SetString(self.LabelBreadNavi01, self.tbMenu.szOption)
    UIHelper.SetString(self.LabelBreadNavi02, self.tbMenu.szOption)

    UIHelper.SetString(self.LabelBreadNavi01_Black, self.tbMenu.szOption)
    UIHelper.SetString(self.LabelBreadNavi02_Black, self.tbMenu.szOption)
    self:SetChecked(false)
end

function UITeamRecruitBreadNaviItem:SetChecked(bChecked)
    UIHelper.SetVisible(self.LabelBreadNavi01, bChecked)
    UIHelper.SetVisible(self.LabelBreadNavi02, bChecked)
    UIHelper.SetVisible(self.ImgBreadNaviBg01, bChecked)
    UIHelper.SetVisible(self.ImgBreadNaviBg02, bChecked)

    UIHelper.SetVisible(self.LabelBreadNavi01_Black, not bChecked)
    UIHelper.SetVisible(self.LabelBreadNavi02_Black, not bChecked)
    UIHelper.SetVisible(self.ImgBreadNaviBg01_Light, not bChecked)
    UIHelper.SetVisible(self.ImgBreadNaviBg02_Light, not bChecked)
end

return UITeamRecruitBreadNaviItem