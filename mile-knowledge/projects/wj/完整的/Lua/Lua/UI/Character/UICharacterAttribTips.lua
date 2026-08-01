-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterAttribTips
-- Date: 2024-06-05 16:29:54
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICharacterAttribTips = class("UICharacterAttribTips")

function UICharacterAttribTips:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UICharacterAttribTips:OnExit()
    self.bInit = false
end

function UICharacterAttribTips:BindUIEvent()
    UIHelper.SetTouchDownHideTips(self.ScrollViewContent, false)
end

function UICharacterAttribTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end
function UICharacterAttribTips:UpdateInfo()
    UIHelper.SetString(self.LabelSkillName, self.tbInfo.szName)
    UIHelper.SetRichText(self.RichTextDesc1, string.format("<color=#AED9E0>%s</c>", self.tbInfo.szTip))
    UIHelper.SetRichText(self.RichTextDesc2, string.format("<color=#AED9E0>%s</c>", self.tbInfo.szTip))

    UIHelper.LayoutDoLayout(self.LayoutShort)
    UIHelper.ScrollViewDoLayout(self.ScrollViewContent)

    local nBaseHeight = UIHelper.GetHeight(self.ScrollViewContent)
    local nCurHeight = UIHelper.GetHeight(self.LayoutShort)

    if nCurHeight > nBaseHeight then
        UIHelper.SetVisible(self.ScrollViewContent, true)
        UIHelper.SetVisible(self.LayoutShort, false)
    else
        UIHelper.SetVisible(self.ScrollViewContent, false)
        UIHelper.SetVisible(self.LayoutShort, true)
    end

end


return UICharacterAttribTips