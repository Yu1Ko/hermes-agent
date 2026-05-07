-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSingleTextTips
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetSingleTextTips = class("UIWidgetSingleTextTips")

function UIWidgetSingleTextTips:OnEnter(szMsg)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(szMsg)
end

function UIWidgetSingleTextTips:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIWidgetSingleTextTips:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        self.fnSelect(self, bSelected)
    end)
end

function UIWidgetSingleTextTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetSingleTextTips:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSingleTextTips:UpdateInfo(szMsg)
    self.szMsg = szMsg
    if self.LabelTips then
        UIHelper.SetString(self.LabelTips, szMsg)
    end

    if self.RichTextTips then
        UIHelper.SetRichText(self.RichTextTips, szMsg)
    end

    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, false)

    if self.ImgBgTips then
        UIHelper.SetPositionX(self.ImgBgTips, -UIHelper.GetWidth(self.ImgBgTips))
    end
end

function UIWidgetSingleTextTips:SetWidth(nWidth)
    UIHelper.SetWidth(self.LabelTips, nWidth)
    UIHelper.SetWidth(self.ImgBgTips, nWidth + 40)

    if self.szMsg then
        self:UpdateInfo(self.szMsg)
    end
end

function UIWidgetSingleTextTips:SetRichTextWidth(nWidth)
    UIHelper.SetWidth(self.RichTextTips, nWidth)
    UIHelper.SetWidth(self.ImgBgTips, nWidth + 40)

    if self.szMsg then
        self:UpdateInfo(self.szMsg)
    end
end

return UIWidgetSingleTextTips