-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetCueWordsCell
-- Date: 2025-12-15 16:19:27
-- Desc: WidgetHintZhuZiGuoChangCell1/WidgetHintZhuZiGuoChangCell2/WidgetHintZhuZiGuoChangCellVertical
-- ---------------------------------------------------------------------------------

local UIWidgetCueWordsCell = class("UIWidgetCueWordsCell")

function UIWidgetCueWordsCell:OnEnter(szText)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.SetRichText(self.RichText, szText)
end

function UIWidgetCueWordsCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetCueWordsCell:BindUIEvent()
    
end

function UIWidgetCueWordsCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetCueWordsCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetCueWordsCell:UpdateInfo()
    
end


return UIWidgetCueWordsCell