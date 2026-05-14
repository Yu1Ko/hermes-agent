-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIPlotDialogueOldNormalCell_Text
-- Date: 2022-11-24 14:57:51
-- Desc: 老对话框 文本
-- ---------------------------------------------------------------------------------

local UIPlotDialogueOldNormalCell_Text = class("UIPlotDialogueOldNormalCell_Text")

function UIPlotDialogueOldNormalCell_Text:OnEnter(tbData)
    self.tbData = tbData

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPlotDialogueOldNormalCell_Text:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPlotDialogueOldNormalCell_Text:BindUIEvent()

end

function UIPlotDialogueOldNormalCell_Text:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPlotDialogueOldNormalCell_Text:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPlotDialogueOldNormalCell_Text:UpdateInfo()
    local szText = self.tbData.szContent
    local tbTag = self.tbData.tbTag

    local nWidth = UIHelper.GetUtf8Width(szText, 26)
    UIHelper.SetWidth(self._rootNode, nWidth)

    if tbTag then 
        szText = tbTag.szStart..szText..tbTag.szEnd
    end
    UIHelper.SetRichText(self.RichTextContent, szText, true)
    UIHelper.SetNodeSwallowTouches(self._rootNode, false, true)

end

function UIPlotDialogueOldNormalCell_Text:GetWidth()
    return UIHelper.GetWidth(self._rootNode)
end

return UIPlotDialogueOldNormalCell_Text