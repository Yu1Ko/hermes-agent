-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetVisonSelectView
-- Date: 2023-07-24 10:47:36
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetVisonSelectView = class("UIWidgetVisonSelectView")

function UIWidgetVisonSelectView:OnEnter(tbVersion)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbVersion = tbVersion
    self:UpdateInfo()
end

function UIWidgetVisonSelectView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetVisonSelectView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnVision, EventType.OnClick, function()
        Event.Dispatch(EventType.OnSelectVersion, self.tbVersion.nIndex)
    end)
end

function UIWidgetVisonSelectView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetVisonSelectView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetVisonSelectView:UpdateInfo()
    UIHelper.SetTexture(self.ImgVision, UIHelper.UTF8ToGBK(self.tbVersion.szImage))
end


return UIWidgetVisonSelectView