-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICurrencyCellDesc
-- Date: 2023-01-03 15:32:07
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICurrencyCellDesc = class("UICurrencyCellDesc")

function UICurrencyCellDesc:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UICurrencyCellDesc:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICurrencyCellDesc:BindUIEvent()
    
end

function UICurrencyCellDesc:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICurrencyCellDesc:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICurrencyCellDesc:UpdateTitle(szTitle)
    UIHelper.SetString(self.LabelTitle1 , szTitle)
end

function UICurrencyCellDesc:UpdateContent(szContent)
    UIHelper.SetRichText(self.RichTextState , szContent)
    UIHelper.LayoutDoLayout(self._rootNode)
end


return UICurrencyCellDesc