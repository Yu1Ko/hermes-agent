-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTipContent11
-- Date: 2024-05-08 11:34:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIItemTipContent11 = class("UIItemTipContent11")

function UIItemTipContent11:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UIItemTipContent11:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIItemTipContent11:BindUIEvent()
    
end

function UIItemTipContent11:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemTipContent11:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIItemTipContent11:UpdateInfo()
    
    UIHelper.SetString(self.LabelTItle , self.tbInfo.szTitle)
    UIHelper.SetRichText(self.RichTextContent , self.tbInfo.szContent)
    UIHelper.LayoutDoLayout(self.LayoutContent)
    UIHelper.LayoutDoLayout(self.WidgetItemTipContent11)
end


return UIItemTipContent11