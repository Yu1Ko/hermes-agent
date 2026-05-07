-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamRecruitFilterItem
-- Date: 2023-02-09 10:37:39
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UITeamRecruitFilterItem
local UITeamRecruitFilterItem = class("UITeamRecruitFilterItem")

function UITeamRecruitFilterItem:OnEnter(tbMenu, fnAction)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbMenu = tbMenu
    self.fnAction = fnAction
    self:UpdateInfo()
end

function UITeamRecruitFilterItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITeamRecruitFilterItem:BindUIEvent()
    UIHelper.BindUIEvent(self.TogFilterItem, EventType.OnClick, function ()
        self.fnAction(self.tbMenu)
    end)
end

function UITeamRecruitFilterItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITeamRecruitFilterItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamRecruitFilterItem:UpdateInfo()
    UIHelper.SetString(self.LabelFilterItem, self.tbMenu.szOption)
    UIHelper.SetString(self.LabelFilterItemSelected, self.tbMenu.szOption)
    UIHelper.SetSelected(self.TogFilterItem, false)
    UIHelper.SetVisible(self.ImgNext, #self.tbMenu > 0)
    UIHelper.SetVisible(self.ImgRecommend, self.tbMenu.bMark)
end

function UITeamRecruitFilterItem:SetChecked(bChecked)
    UIHelper.SetSelected(self.TogFilterItem, bChecked)
    UIHelper.SetVisible(self.ImgNext, #self.tbMenu > 0)
end

return UITeamRecruitFilterItem