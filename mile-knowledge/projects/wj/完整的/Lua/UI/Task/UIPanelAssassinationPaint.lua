-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelAssassinationPaint
-- Date: 2024-03-26 17:22:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelAssassinationPaint = class("UIPanelAssassinationPaint")

function UIPanelAssassinationPaint:OnEnter(nID, bShowContent)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nID = nID
    self.bShowContent = bShowContent
    self:UpdateInfo()
end

function UIPanelAssassinationPaint:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelAssassinationPaint:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end) 
end

function UIPanelAssassinationPaint:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelAssassinationPaint:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelAssassinationPaint:UpdateInfo()
    local tbInfo = Table_GetAssassinationTaskScrollInfo(self.nID)
    local szDefaultText = Table_GetAssassinationTaskScrollInfo(0).szText
    if not tbInfo then return end

    local szTitle = tbInfo.szTitle
    UIHelper.SetString(self.LabelTitle, UIHelper.GBKToUTF8(szTitle))

    local szText = self:ParseText(tbInfo.szText)
    szText = string.gsub(szText, "\\n", "\n")
    UIHelper.SetRichText(self.RichTextContent, string.format("<color=#463329>%s</c>", szText))

    local szMobileBgImageWithoutWordsPath = tbInfo.szMobileBgImageWithoutWordsPath
	local szMobileBgImageWithWordsPath = tbInfo.szMobileBgImageWithWordsPath
	local szMobileImageTitlePath = tbInfo.szMobileImageTitlePath
	local szMobileImageSealPath	= tbInfo.szMobileImageSealPath

    UIHelper.SetTexture(self.ImgPic01, szMobileBgImageWithoutWordsPath)
    UIHelper.SetTexture(self.ImgPic02, szMobileBgImageWithWordsPath)
    UIHelper.SetSpriteFrame(self.ImgSeal, szMobileImageSealPath)
    UIHelper.SetSpriteFrame(self.ImgMiling, szMobileImageTitlePath)

    UIHelper.SetVisible(self.ImgSeal, szMobileImageSealPath ~= "" and self.bShowContent)
    UIHelper.SetVisible(self.ImgMiling, szMobileImageTitlePath ~= "" and self.bShowContent)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)

    UIHelper.SetVisible(self.ScrollViewContent, tbInfo.szText ~= szDefaultText and self.bShowContent)
    UIHelper.SetVisible(self.LabelTitle, self.bShowContent)


end

function UIPanelAssassinationPaint:ParseText(szDesc)
    local function GetEncodeName(tInfo)
        local szName = ""
        local nID = tonumber(tInfo.context)
        if nID then
            szName = Table_GetNpcCallMe(nID)
        else
            szName = GetClientPlayer().szName
        end
        return szName
    end

    local _, aInfo = GWTextEncoder_Encode(szDesc)
	if not aInfo then
		return ""
	end

	local szText = ""
	for  k, v in pairs(aInfo) do
		if v.name == "text" then --普通文本
			szText = szText..UIHelper.GBKToUTF8(v.context)
        elseif v.name == "N" then -- NPC对玩家的自定义称呼
            szText = szText..UIHelper.GBKToUTF8(GetEncodeName(v))
		elseif v.name == "C" then	--自己的体型对应的称呼
			szText = szText..g_tStrings.tRoleTypeToName[g_pClientPlayer.nRoleType]
		elseif v.name == "F" then	--字体
            local tbColor = UIDialogueColorTab[tonumber(v.attribute.fontid)]
			szText = szText..string.format("<color=%s>", tbColor.Color)..UIHelper.GBKToUTF8(v.attribute.text).."</color>"
		elseif v.name == "G" then	--4个英文空格
			local szSpace = g_tStrings.STR_TWO_CHINESE_SPACE
			if v.attribute.english then
				szSpace = "    "
			end
			szText = szText..szSpace
		elseif v.name == "J" then	--金钱
			local nM = tonumber(v.attribute.money)
			szText = szText..UIHelper.GetMoneyText(nM)
		end
	end
    szText = string.gsub(szText, "\\n", "\n")--将\n替换为换行符

    return szText
end


return UIPanelAssassinationPaint