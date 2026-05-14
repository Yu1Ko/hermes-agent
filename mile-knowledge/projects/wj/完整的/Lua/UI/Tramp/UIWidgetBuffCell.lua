-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetBuffCell
-- Date: 2023-05-08 16:19:11
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetBuffCell = class("UIWidgetBuffCell")

function UIWidgetBuffCell:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UIWidgetBuffCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetBuffCell:BindUIEvent()

end

function UIWidgetBuffCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetBuffCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetBuffCell:UpdateInfo()
    UIHelper.SetString(self.LabelBuffLevel, self.tbInfo.nStackNum)
    UIHelper.SetItemIconByIconID(self.ImgBuffIcon, self.tbInfo.nIconID)
end


return UIWidgetBuffCell