-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetPvPCampRewardListNormal
-- Date: 2023-03-02 19:49:15
-- Desc: WidgetPvPCampRewardListAttribute、WidgetPvPCampRewardListEquip
-- ---------------------------------------------------------------------------------

local UIWidgetPvPCampRewardListNormal = class("UIWidgetPvPCampRewardListNormal")

function UIWidgetPvPCampRewardListNormal:OnEnter(tInfo)
    self.szTitle = tInfo and tInfo.szTitle
    self.szContent = tInfo and tInfo.szContent

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIWidgetPvPCampRewardListNormal:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetPvPCampRewardListNormal:BindUIEvent()
    
end

function UIWidgetPvPCampRewardListNormal:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetPvPCampRewardListNormal:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetPvPCampRewardListNormal:UpdateInfo()
    if self.szTitle and #self.szTitle > 0 then
        if self.LabelTitle then
            UIHelper.SetString(self.LabelTitle, self.szTitle)
            UIHelper.SetVisible(self.LabelTitle, true)
        elseif self.RichTextTitle then
            UIHelper.SetRichText(self.RichTextTitle, self.szTitle)
            UIHelper.SetVisible(self.RichTextTitle, true)
        end
    else
        UIHelper.SetVisible(self.LabelTitle, false)
        UIHelper.SetVisible(self.RichTextTitle, false)
    end

    if self.szContent and #self.szContent > 0 then
        if self.LabelContent then
            UIHelper.SetString(self.LabelContent, self.szContent)
            UIHelper.SetVisible(self.LabelContent, true)
        elseif self.RichTextContent then
            UIHelper.SetRichText(self.RichTextContent, self.szContent)
            UIHelper.SetVisible(self.RichTextContent, true)
            local nWidth = UIHelper.GetUtf8RichTextWidth(self.szContent)
            UIHelper.SetWidth(self.RichTextContent, nWidth)
        end
    else
        UIHelper.SetVisible(self.LabelContent, false)
        UIHelper.SetVisible(self.RichTextContent, false)
    end
end


return UIWidgetPvPCampRewardListNormal