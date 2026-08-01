-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIActivityLeaveForView
-- Date: 2022-12-13 15:06:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIActivityLeaveForView = class("UIActivityLeaveForView")

function UIActivityLeaveForView:OnEnter(tbTravelList, nMaxFixedTravelCount)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    
    if nMaxFixedTravelCount then
        self.nMaxFixedTravelCount = nMaxFixedTravelCount
    else
        self.nMaxFixedTravelCount = 8
    end
    
    if tbTravelList then
        self.tbTravelList = tbTravelList
        self:UpdateInfo()
    end
end

function UIActivityLeaveForView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIActivityLeaveForView:BindUIEvent()

end

function UIActivityLeaveForView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIActivityLeaveForView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIActivityLeaveForView:UpdateInfo()
    local nCount = #self.tbTravelList
    UIHelper.RemoveAllChildren(self.ScrollViewActivityDetail)
    UIHelper.RemoveAllChildren(self.LayoutLeaveFor)
    UIHelper.SetVisible(self.WidgetScrollViewDetail, nCount > self.nMaxFixedTravelCount)
    UIHelper.SetVisible(self.WidgetLayoutDetail, nCount <= self.nMaxFixedTravelCount)

    local parent = nCount > self.nMaxFixedTravelCount and self.ScrollViewActivityDetail or self.LayoutLeaveFor
    for nIndex, tbTravelInfo in ipairs(self.tbTravelList) do
        local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetLeaveForBtn, parent, tbTravelInfo)
        UIHelper.SetTouchDownHideTips(cell.BtnLeaveFor, false)
    end

    UIHelper.LayoutDoLayout(self.LayoutLeaveFor)
    UIHelper.LayoutDoLayout(self.LayoutLeaveForParent)
    UIHelper.ScrollViewDoLayout(self.ScrollViewActivityDetail)
    UIHelper.ScrollToTop(self.ScrollViewActivityDetail, 0)
    UIHelper.SetTouchDownHideTips(self.ScrollViewActivityDetail, false)
    if self.WidgetArrow then
        UIHelper.ScrollViewSetupArrow(self.ScrollViewActivityDetail, self.WidgetArrow)
    end
end

function UIActivityLeaveForView:UpdateByFunc(tbList, nMaxFixedTravelCount)
    self.nMaxFixedTravelCount = nMaxFixedTravelCount
    local nCount = #tbList
    UIHelper.RemoveAllChildren(self.ScrollViewActivityDetail)
    UIHelper.RemoveAllChildren(self.LayoutLeaveFor)
    UIHelper.SetVisible(self.WidgetScrollViewDetail, nCount > self.nMaxFixedTravelCount)
    UIHelper.SetVisible(self.WidgetLayoutDetail, nCount <= self.nMaxFixedTravelCount)

    local parent = nCount > self.nMaxFixedTravelCount and self.ScrollViewActivityDetail or self.LayoutLeaveFor
    for _, tbInfo in ipairs(tbList) do
        local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetLeaveForBtn, parent)
        cell:SetLabelText(tbInfo.szName)
        cell:BindClickFunction(tbInfo.OnClick)
        UIHelper.SetTouchDownHideTips(cell.BtnLeaveFor, false)
    end

    UIHelper.LayoutDoLayout(self.LayoutLeaveFor)
    UIHelper.LayoutDoLayout(self.LayoutLeaveForParent)
    UIHelper.ScrollViewDoLayout(self.ScrollViewActivityDetail)
    UIHelper.ScrollToTop(self.ScrollViewActivityDetail, 0)
    UIHelper.SetTouchDownHideTips(self.ScrollViewActivityDetail, false)
end

function UIActivityLeaveForView:SetSwallowTouches(bSwallow)
    UIHelper.SetSwallowTouches(self.ScrollViewActivityDetail, bSwallow)
    UIHelper.SetSwallowTouches(self.LayoutLeaveFor, bSwallow)
end

return UIActivityLeaveForView