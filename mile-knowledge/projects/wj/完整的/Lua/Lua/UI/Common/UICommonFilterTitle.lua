-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICommonFilterTitle
-- Date: 2022-11-30 19:12:51
-- Desc: WidgetTittleCell
-- ---------------------------------------------------------------------------------

local UICommonFilterTitle = class("UICommonFilterTitle")

function UICommonFilterTitle:OnEnter(bCanSelectAll)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.SetVisible(self.TogSelectedAll, bCanSelectAll)
    UIHelper.SetTouchDownHideTips(self.TogSelectedAll, false)
end

function UICommonFilterTitle:OnExit()
    self.bInit = false
    self:UnRegEvent()

    self.SelectAllCallBack = nil
end

function UICommonFilterTitle:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSelectedAll, EventType.OnClick, function ()
        if self.SelectAllCallBack then
            self.SelectAllCallBack(UIHelper.GetSelected(self.TogSelectedAll))
        end
    end)

    UIHelper.BindUIEvent(self.TogMultiFunction, EventType.OnSelectChanged, function (_, bSelected)
        if self.fnSetApplyCallBack then
            self.fnSetApplyCallBack(bSelected)
        end
    end)
end

function UICommonFilterTitle:RegEvent()

end

function UICommonFilterTitle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UICommonFilterTitle:RegisterSelectAllEvent(func)
    self.SelectAllCallBack = func
end

function UICommonFilterTitle:RegisterSetApplyEvent(func)
    self.fnSetApplyCallBack = func
end

function UICommonFilterTitle:UpdateInfo()
    
end


return UICommonFilterTitle