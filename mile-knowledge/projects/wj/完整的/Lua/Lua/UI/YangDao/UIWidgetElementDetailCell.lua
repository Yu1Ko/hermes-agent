-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetElementDetailCell
-- Date: 2026-03-05 15:35:13
-- Desc: 扬刀大会-属性详细信息 元素详细信息 WidgetElementDetailCell(PanelElementDetailSide)
-- ---------------------------------------------------------------------------------

local UIWidgetElementDetailCell = class("UIWidgetElementDetailCell")

function UIWidgetElementDetailCell:OnEnter(szTitle, szIconPath, nValue, szContent)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:SetTitle(szTitle)
    self:SetIcon(szIconPath)
    self:SetValue(nValue)
    self:SetContent(szContent)
end

function UIWidgetElementDetailCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetElementDetailCell:BindUIEvent()

end

function UIWidgetElementDetailCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetElementDetailCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetElementDetailCell:SetTitle(szTitle)
    UIHelper.SetString(self.LabelTitle, szTitle)
end

function UIWidgetElementDetailCell:SetIcon(szIconPath)
    UIHelper.SetSpriteFrame(self.ImgIcon, szIconPath)
end

function UIWidgetElementDetailCell:SetValue(nValue)
    UIHelper.SetString(self.LabelTitleNum, nValue or "-")
end

function UIWidgetElementDetailCell:SetContent(szContent)
    UIHelper.SetRichText(self.RichTextDesc, szContent)
    UIHelper.LayoutDoLayout(self._rootNode)
end

return UIWidgetElementDetailCell