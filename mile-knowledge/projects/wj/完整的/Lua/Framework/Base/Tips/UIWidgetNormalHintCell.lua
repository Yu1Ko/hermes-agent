-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetNormalHintCell
-- Date: 2023-11-30 09:55:52
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetNormalHintCell = class("UIWidgetNormalHintCell")

function UIWidgetNormalHintCell:OnEnter(tbData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbData = tbData
    self:UpdateInfo()
end

function UIWidgetNormalHintCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetNormalHintCell:BindUIEvent()

end

function UIWidgetNormalHintCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetNormalHintCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetNormalHintCell:OnPoolAllocated(tbData)

end

function UIWidgetNormalHintCell:OnPoolRecycled(tbData)

end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetNormalHintCell:UpdateInfo()

    local tbData = self.tbData
    local szText = tbData.szText

    local bRichText = tbData.bRichText
    if not UIHelper.IsRichText(szText) then
        bRichText = false
    end

    if bRichText then
        local nFontSize = self.RichTextNormal:getFontSize()
        local nWidth = UIHelper.GetUtf8RichTextWidth(szText, nFontSize)
        if nWidth > TIPS_MAX.RichText then nWidth = TIPS_MAX.RichText end
        UIHelper.SetWidth(self.RichTextNormal, nWidth + 30)
        UIHelper.SetRichText(self.RichTextNormal, szText)
        UIHelper.SetRichTextCanClick(self.RichTextNormal, false)
    else
        szText = string.gsub(szText, "[\n]+$", "")
        szText = UIHelper.LimitUtf8Len(szText, TIPS_MAX.Normal)

        -- local nFontSize = self.LabelNormal:getTTFConfig().fontSize
        -- local nWidth = UIHelper.GetUtf8RichTextWidth(szText, nFontSize) + 30
        UIHelper.SetString(self.LabelNormal, szText)
        -- UIHelper.SetWidth(self.LabelNormal, nWidth)
    end

    UIHelper.SetVisible(self.ImgNormalHintBg, not bRichText)
    UIHelper.SetVisible(self.ImgNormalHintBg1, bRichText)

    local callback = tbData.callback
    UIHelper.PlayAni(self, self.AniNormal, "AniNormal", function()
        if tbData.funcTipEnd then tbData.funcTipEnd() end
        callback(self._rootNode)
    end)

    if tbData.szImagePath then
        UIHelper.SetSpriteFrame(self.ImgNormalHintBg, tbData.szImagePath)
    end
end

function UIWidgetNormalHintCell:GetText()
    return self.tbData.szText
end

return UIWidgetNormalHintCell