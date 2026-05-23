-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetRichManTips
-- Date: 2026-04-20 20:21:05
-- Desc: 大富翁 Tips UIWidgetRichManTips
-- ---------------------------------------------------------------------------------

local UIWidgetRichManTips = class("UIWidgetRichManTips")

function UIWidgetRichManTips:OnEnter(szTitle, szTips)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szTitle = szTitle
    self.szTips = szTips
    self:UpdateInfo()
end

function UIWidgetRichManTips:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetRichManTips:BindUIEvent()

end

function UIWidgetRichManTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetRichManTips:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetRichManTips:UpdateInfo()
    UIHelper.SetVisible(self.LabelTitle, not string.is_nil(self.szTitle))
    UIHelper.SetVisible(self.LabelTips, not string.is_nil(self.szTips))
    UIHelper.SetString(self.LabelTitle, self.szTitle)
    UIHelper.SetRichText(self.LabelTips, self.szTips)
    UIHelper.LayoutDoLayout(self.ImgRichManTips)
end

function UIWidgetRichManTips:ShowPlayerName(nPlayerIndex)
    UIHelper.SetVisible(self.LabelTitle, true)
    self.scriptName = self.scriptName or UIHelper.AddPrefab(PREFAB_ID.WidgetPlayerName_Color, self.WidgetName_Color)
    MonopolyData.SetPlayerBaseInfo(self.scriptName, nPlayerIndex)
    UIHelper.LayoutDoLayout(self.ImgRichManTips)
end

return UIWidgetRichManTips