-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuyQuicklyFilterCell
-- Date: 2024-07-05 14:48:45
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuyQuicklyFilterCell = class("UIHomelandBuyQuicklyFilterCell")

function UIHomelandBuyQuicklyFilterCell:OnEnter(szTitle, bNew, fnAction)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szTitle    = szTitle
    self.bNew       = bNew
    self.fnAction   = fnAction
    self:UpdateInfo()
end

function UIHomelandBuyQuicklyFilterCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandBuyQuicklyFilterCell:BindUIEvent()
    UIHelper.SetTouchDownHideTips(self.TogTypeFilter, false)
    -- UIHelper.SetSwallowTouches(self.TogTypeFilter, true)

    UIHelper.BindUIEvent(self.TogTypeFilter, EventType.OnSelectChanged, function(_, bSelected)
        if not bSelected or not self.fnAction then
            return
        end

        self.fnAction()
    end)
end

function UIHomelandBuyQuicklyFilterCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuyQuicklyFilterCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandBuyQuicklyFilterCell:UpdateInfo()
    UIHelper.SetString(self.LabelTypeFilterName, self.szTitle)
    UIHelper.SetVisible(self.ImgNewIcon, self.bNew)
    UIHelper.LayoutDoLayout(self.LayoutTypeName)
end


return UIHomelandBuyQuicklyFilterCell