-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetTittleView
-- Date: 2023-07-24 10:39:07
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetTittleView = class("UIWidgetTittleView")

function UIWidgetTittleView:OnEnter(tbTitle)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(tbTitle)
end

function UIWidgetTittleView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetTittleView:BindUIEvent()

end

function UIWidgetTittleView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetTittleView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTittleView:UpdateInfo(tbTitle)
    local szTitle = tbTitle and tbTitle[4]
    szTitle = string.is_nil(szTitle) and "" or GBKToUTF8(tbTitle[4])
    UIHelper.SetString(self.LabelTittle, szTitle)
end


return UIWidgetTittleView