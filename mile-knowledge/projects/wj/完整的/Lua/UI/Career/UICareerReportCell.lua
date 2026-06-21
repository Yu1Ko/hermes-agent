-- WidgetCareerReportCell

local UICareerReportCell = class("UICareerReportCell")

function UICareerReportCell:OnEnter(szText)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(szText)
end

function UICareerReportCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICareerReportCell:BindUIEvent()
    --
end

function UICareerReportCell:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        UIHelper.LayoutDoLayout(self._rootNode)
        Timer.AddFrame(self, 1, function()
            UIHelper.LayoutDoLayout(self._rootNode)
        end)
    end)
end

function UICareerReportCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UICareerReportCell:UpdateInfo(szText)
    UIHelper.SetRichText(self.RichTextContent, szText)
    UIHelper.LayoutDoLayout(self._rootNode)
    Timer.AddFrame(self, 1, function()
        UIHelper.LayoutDoLayout(self._rootNode)
    end)
end

return UICareerReportCell