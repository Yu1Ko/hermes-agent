-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIBattleFieldRulesView
-- Date: 2023-01-03 09:41:34
-- Desc: 战场规则界面（旧） PanelBattleFieldRules
-- ---------------------------------------------------------------------------------

local UIBattleFieldRulesView = class("UIBattleFieldRulesView")

local TITLE_COLOR = "#f0dc82"

function UIBattleFieldRulesView:OnEnter(dwMapID)
    self.dwMapID = dwMapID

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIBattleFieldRulesView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIBattleFieldRulesView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIBattleFieldRulesView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIBattleFieldRulesView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIBattleFieldRulesView:UpdateInfo()
    local dwMapID = BattleFieldData.GetBattleFieldFatherID(self.dwMapID)
    local szHelpImage, szHelpText = Table_GetBattleFieldHelpInfo(dwMapID)
	local szName = Table_GetBattleFieldName(dwMapID)

    szName = UIHelper.GBKToUTF8(szName)
    UIHelper.SetString(self.LabelTittle, szName)
    UIHelper.SetString(self.LabelTitle, "战场") --TODO 以后有其他战场类型改这个

    szHelpText = string.pure_text(szHelpText)
    szHelpText = string.gsub(szHelpText, "\\", "\n") or szHelpText
    szHelpText = UIHelper.GBKToUTF8(szHelpText)
    szHelpText = string.gsub(szHelpText, "战场背景：?", string.format("<color=%s>战场背景：</color>", TITLE_COLOR)) or szHelpText
    szHelpText = string.gsub(szHelpText, "胜利目标：?", string.format("<color=%s>胜利目标：</color>", TITLE_COLOR))or szHelpText
    szHelpText = string.gsub(szHelpText, "得分方法：?", string.format("<color=%s>得分方法：</color>", TITLE_COLOR)) or szHelpText
    szHelpText = string.gsub(szHelpText, "\n+", "\n\n")
    UIHelper.SetRichText(self.RichTextRules, szHelpText)

    --LOG.INFO(szHelpText)

    if szHelpImage and #szHelpImage > 0 then
        --\ui\Image\BattleField\shennongyin.tga 旧路径
        --Resource\BattleField\shennongyin.png 新路径
        szHelpImage = string.gsub(szHelpImage, "\\ui\\Image", "Resource")
        szHelpImage = string.gsub(szHelpImage, ".tga", ".png")

        UIHelper.SetTexture(self.ImgRules, szHelpImage)
        UIHelper.SetVisible(self.ImgRules, true)
    else
        UIHelper.SetVisible(self.ImgRules, false)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewActivityHelp)
    UIHelper.ScrollToTop(self.ScrollViewActivityHelp)
end


return UIBattleFieldRulesView