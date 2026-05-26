-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIGradeContent
-- Date: 2022-12-08 20:49:19
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIGradeContent = class("UIGradeContent")

function UIGradeContent:OnEnter(szGrade,szContent)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(szGrade,szContent)
end

function UIGradeContent:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIGradeContent:BindUIEvent()
    
end

function UIGradeContent:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIGradeContent:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIGradeContent:UpdateInfo(szGrade,szContent)
    UIHelper.SetString(self.LabelGrade, szGrade)
    UIHelper.SetRichText(self.RichTextGradeContent,szContent)
    UIHelper.LayoutDoLayout(self.WidgetGradeContent)
end


return UIGradeContent