-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWuLinTongJianInnerView
-- Date: 2023-11-28 16:54:11
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWuLinTongJianInnerView = class("UIWuLinTongJianInnerView")

function UIWuLinTongJianInnerView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWuLinTongJianInnerView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWuLinTongJianInnerView:BindUIEvent()

end

function UIWuLinTongJianInnerView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWuLinTongJianInnerView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWuLinTongJianInnerView:UpdateInfo()

end


return UIWuLinTongJianInnerView