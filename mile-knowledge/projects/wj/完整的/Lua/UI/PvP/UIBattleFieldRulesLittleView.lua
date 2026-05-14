-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIBattleFieldRulesLittleView
-- Date: 2023-03-29 11:02:42
-- Desc: PanelBattleFieldRulesLittle
-- ---------------------------------------------------------------------------------

local UIBattleFieldRulesLittleView = class("UIBattleFieldRulesLittleView")

function UIBattleFieldRulesLittleView:OnEnter(dwMapID)
    self.dwMapID = dwMapID

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.SetSwallowTouches(self.ScrollViewBattleRules)
    self:UpdateInfo()
end

function UIBattleFieldRulesLittleView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIBattleFieldRulesLittleView:BindUIEvent()
    
end

function UIBattleFieldRulesLittleView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIBattleFieldRulesLittleView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIBattleFieldRulesLittleView:UpdateInfo()
    local dwMapID = BattleFieldData.GetBattleFieldFatherID(self.dwMapID)
    local szHelpImage, szHelpText = Table_GetBattleFieldHelpInfo(dwMapID)
	local szName = Table_GetBattleFieldName(dwMapID)

    szName = UIHelper.GBKToUTF8(szName)
    UIHelper.SetString(self.LabelTitle, szName)

    szHelpText = UIHelper.GBKToUTF8(szHelpText)

    --print(UTF8ToGBK(szHelpText))
    local szTitle1, szTitle2
    local szRule1, szRule2

    -- 取前两项
    if dwMapID == BATTLE_FIELD_MAP_ID.QING_XIAO_SHAN then
        if szHelpText and string.find(szHelpText, "text=") then
            local szTitleFontID
            szHelpText = string.gsub(szHelpText, "\\\n", "\n")
            szHelpText = string.gsub(szHelpText, "text=.-</text>", function(szTarget)
                local szContent = string.match(szTarget, "text=\"(.-)\"")
                local szFontID = string.match(szTarget, "font=(%d+)")
                if not szTitleFontID then
                    szTitleFontID = szFontID
                end
                if szFontID == szTitleFontID then
                    szContent = string.gsub(szContent, "\n", "")
                    szContent = string.gsub(szContent, "：", "")
                    if not szTitle1 then
                        szTitle1 = szContent
                    elseif not szTitle2 then
                        szTitle2 = szContent
                    end
                else
                    szContent = string.gsub(szContent, "^[\n\r]+", "")
                    if not szRule1 then
                        szRule1 = szContent
                    elseif not szRule2 then
                        szRule2 = szContent
                    end
                end
            end)
        end
    else
        szHelpText = string.pure_text(szHelpText)
        szHelpText = string.gsub(szHelpText, "\\", "\n") or szHelpText
        szHelpText = string.gsub(szHelpText, "\n+", "\n") or szHelpText

        szTitle1, szTitle2 = "胜利目标", "得分方法"
        if dwMapID == 412 then
            --- 列星虚境只有战场背景和胜利目标，特殊处理下
            szTitle1, szTitle2 = "战场背景", "胜利目标"
        end
        
        szRule1, szRule2 = string.match(szHelpText, szTitle1 .. "：?\n(.+)" .. szTitle2 .. "：?\n(.+)")
    
        if not szRule1 or not szRule2 then
            szTitle1, szTitle2 = "胜利目标", "战场规则"
            szRule1, szRule2 = string.match(szHelpText, szTitle1 .. "：?\n(.+)" .. szTitle2 .. "：?\n(.+)")
        end
    
        if not szRule1 or not szRule2 then
            szTitle1, szTitle2 = "胜利目标", nil
            szRule1, szRule2 = string.match(szHelpText, szTitle1 .. "：?\n(.+)")
        end
    end

    local bShowRule1 = not string.is_nil(szTitle1) and not string.is_nil(szRule1)
    local bShowRule2 = not string.is_nil(szTitle2) and not string.is_nil(szRule2)

    if bShowRule1 then
        UIHelper.SetString(self.LabelBattleRulesTitle1, szTitle1)
        UIHelper.SetString(self.LabelBattleRules1, szRule1)
    end
    if bShowRule2 then
        UIHelper.SetString(self.LabelBattleRulesTitle2, szTitle2)
        UIHelper.SetString(self.LabelBattleRules2, szRule2)
    end

    UIHelper.SetVisible(self.WidgetRuleTitle1, bShowRule1)
    UIHelper.SetVisible(self.ImgLine1, bShowRule1)
    UIHelper.SetVisible(self.LabelBattleRules1, bShowRule1)
    UIHelper.SetVisible(self.WidgetRuleTitle2, bShowRule2)
    UIHelper.SetVisible(self.ImgLine2, bShowRule2)
    UIHelper.SetVisible(self.LabelBattleRules2, bShowRule2)

    if szHelpImage and #szHelpImage > 0 then
        --\ui\Image\BattleField\shennongyin.tga 旧路径
        --Resource\BattleField\shennongyin.png 新路径
        szHelpImage = string.gsub(szHelpImage, "\\ui\\Image", "Resource")
        szHelpImage = string.gsub(szHelpImage, ".tga", ".png")

        UIHelper.SetTexture(self.ImgMapRules, szHelpImage)
        UIHelper.SetVisible(self.ImgMapRules, true)
    else
        UIHelper.SetVisible(self.ImgMapRules, false)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewBattleRules)
    UIHelper.ScrollToTop(self.ScrollViewBattleRules, 0)
end


return UIBattleFieldRulesLittleView