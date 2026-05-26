-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetBlessCard
-- Date: 2026-02-26 16:07:22
-- Desc: 扬刀大会-祝福卡片
--       大号卡牌: WidgetBlessCardL
--       小号卡牌: WidgetBlessCardS
--       商店卡牌: WidgetBlessCardShopItem
-- ---------------------------------------------------------------------------------

local UIWidgetBlessCard = class("UIWidgetBlessCard")

-- 文本颜色
local TEXT_COLOR_NORMAL = "#FFFFFF"   -- 常规文本颜色
local TEXT_COLOR_FIRE = "#EB9A75"     -- 燃烧文本颜色

local OPACITY_NORMAL = 255
local OPACITY_GRAY = 178

local PRICE_TEXT_COLOR = cc.c3b(255, 255, 255)
local PRICE_TEXT_COLOR_RED = cc.c3b(255, 117, 117)

local szImgBgCardL_NoElement = "UIAtlas2_YangDao_BlessCardBg_Img_BgCardL_NoElement.png"
local tImgBgCardL = 
{
    [BlessElementType.Jin] = "UIAtlas2_YangDao_BlessCardBg_Img_BgCardL_Jin.png",
    [BlessElementType.Mu] = "UIAtlas2_YangDao_BlessCardBg_Img_BgCardL_Mu.png",
    [BlessElementType.Shui] = "UIAtlas2_YangDao_BlessCardBg_Img_BgCardL_Shui.png",
    [BlessElementType.Huo] = "UIAtlas2_YangDao_BlessCardBg_Img_BgCardL_Huo.png",
    [BlessElementType.Tu] = "UIAtlas2_YangDao_BlessCardBg_Img_BgCardL_Tu.png",
}

-- Alpha: 50
local szDefaultCardBgColor = "#655C6B"
local tCardBgColor =
{
    [BlessElementType.Jin] = "#866A2E",
    [BlessElementType.Mu] = "#457230",
    [BlessElementType.Shui] = "#2B6482",
    [BlessElementType.Huo] = "#853634",
    [BlessElementType.Tu] = "#915334",
}

local szDefaultRingBgColor = "#6C6073"
local tRingBgColor =
{
    [BlessElementType.Jin] = "#B38D3C",
    [BlessElementType.Mu] = "#5D9334",
    [BlessElementType.Shui] = "#3882A1",
    [BlessElementType.Huo] = "#A64537",
    [BlessElementType.Tu] = "#AC623A",
}

local szDefaultRingColor = "#AB94AF"
local tRingColor =
{
    [BlessElementType.Jin] = "#FFEA5B",
    [BlessElementType.Mu] = "#AEEB4D",
    [BlessElementType.Shui] = "#54E2E4",
    [BlessElementType.Huo] = "#FF6E3C",
    [BlessElementType.Tu] = "#FF904D",
}

local tTagNode =
{
    [BlessCardTagType.Damage] = "WidgetTagShangHai",
    [BlessCardTagType.Heal] = "WidgetTagZhiLiao",
    [BlessCardTagType.Burst] = "WidgetTagBaoFa",
    [BlessCardTagType.Survive] = "WidgetTagShengCun",
    [BlessCardTagType.Buff] = "WidgetTagZengYi",
    [BlessCardTagType.Debuff] = "WidgetTagJianYi",
    [BlessCardTagType.Resource] = "WidgetTagZiYuan",
    [BlessCardTagType.Special] = "WidgetTagQuWei",
}

-- 这两个不要加png后缀，这里的是RichText里用的，加了后缀识别不了
local szBurningIconPath = "UIAtlas2_YangDao_BlessCard_Icon_Huo_Burning"
local szAshIconPath = "UIAtlas2_YangDao_BlessCard_Icon_Huo_Ash"

local tCardAniName =
{
    [BlessCardAniEvent.OnFire] = "AniHuoKaDianRan_ChuFa",
    [BlessCardAniEvent.OnAsh] = "AniHuoKaHuiJin_ChuFa",
    [BlessCardAniEvent.OnRevive] = "AniHuoKaNiePan_ChuFa",
    [BlessCardAniEvent.OnGrowWood] = "AniMuKa_ChuFa",
    [BlessCardAniEvent.OnEnhanced] = "AniQiangHua_ChuFa",
    [BlessCardAniEvent.OnGetCard] = "AniDaKaHuoDe_ChuFa",
}

local ENHANCED_ANI_SPEED = 0.2
local szEnhancedAniName = "AniQiangHua_StarRingRotate"

local szLargeCardDefaultEnhancedSFXPath = "data\\source\\other\\HD特效\\UI_M\\Pss\\YangDao\\UI_扬刀大会_强化大卡_循环.pss"
local tLargeCardEnhancedSFXPath =
{
    [BlessElementType.Jin] = "data\\source\\other\\HD特效\\UI_M\\Pss\\YangDao\\UI_扬刀大会_强化大卡_循环金.pss",
    [BlessElementType.Mu] = "data\\source\\other\\HD特效\\UI_M\\Pss\\YangDao\\UI_扬刀大会_强化大卡_循环木.pss",
    [BlessElementType.Shui] = "data\\source\\other\\HD特效\\UI_M\\Pss\\YangDao\\UI_扬刀大会_强化大卡_循环水.pss",
    [BlessElementType.Huo] = "data\\source\\other\\HD特效\\UI_M\\Pss\\YangDao\\UI_扬刀大会_强化大卡_循环火.pss",
    [BlessElementType.Tu] = "data\\source\\other\\HD特效\\UI_M\\Pss\\YangDao\\UI_扬刀大会_强化大卡_循环土.pss",
}

local szSmallCardDefaultEnhancedSFXPath = "data\\source\\other\\HD特效\\UI_M\\Pss\\YangDao\\UI_扬刀大会_强化小卡_循环.pss"
local tSmallCardEnhancedSFXPath =
{
    [BlessElementType.Jin] = "data\\source\\other\\HD特效\\UI_M\\Pss\\YangDao\\UI_扬刀大会_强化小卡_循环金.pss",
    [BlessElementType.Mu] = "data\\source\\other\\HD特效\\UI_M\\Pss\\YangDao\\UI_扬刀大会_强化小卡_循环木.pss",
    [BlessElementType.Shui] = "data\\source\\other\\HD特效\\UI_M\\Pss\\YangDao\\UI_扬刀大会_强化小卡_循环水.pss",
    [BlessElementType.Huo] = "data\\source\\other\\HD特效\\UI_M\\Pss\\YangDao\\UI_扬刀大会_强化小卡_循环火.pss",
    [BlessElementType.Tu] = "data\\source\\other\\HD特效\\UI_M\\Pss\\YangDao\\UI_扬刀大会_强化小卡_循环土.pss",
}

function UIWidgetBlessCard:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.SetSwallowTouches(self.TogCard, false)
end

function UIWidgetBlessCard:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetBlessCard:BindUIEvent()
    UIHelper.SetClickInterval(self.TogCard, 0)
    UIHelper.BindUIEvent(self.TogCard, EventType.OnClick, function()
        if not UIHelper.GetTouchEnabled(self.TogCard) then
            -- 防止手指按下后再用另外一个手指触发了SetCanSelect(false)
            return
        end
        if self.fnCallback then
            self.fnCallback()
        end
        self:SetSelected(true)

        if self.tCardData then
            -- print_table(self.tCardData)
            LOG.INFO("[ArenaTower] Click CardID: %s", tostring(self.tCardData.nCardID))
        end
    end)
    UIHelper.BindUIEvent(self.TogCard, EventType.OnSelectChanged, function(_, bSelected)
        UIHelper.SetVisible(self.ImgCardSelect, bSelected)
    end)
end

function UIWidgetBlessCard:RegEvent()
    Event.Reg(self, EventType.OnShowBlessDetailDesc, function()
        self:UpdateDesc()
    end)
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        Timer.AddFrame(self, 4, function()
            self:UpdateLayout()
        end)
    end)
end

function UIWidgetBlessCard:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetBlessCard:InitElementLarge(nElementType1, nElementType2, nStar, bShowEnhanced)
    nStar = nStar or 1 -- 无星级显示一星的图
    UIHelper.SetVisible(self.WidgetElementL, false)
    UIHelper.SetVisible(self.WidgetElementR, false)
    for nIndex, widgetElement in pairs(self.tWidgetElementL or {}) do
        if nElementType1 and nIndex == nElementType1 then
            UIHelper.SetVisible(self.WidgetElementL, true)
            UIHelper.SetVisible(widgetElement, true)
        else
            UIHelper.SetVisible(widgetElement, false)
        end
    end
    for nIndex, widgetElement in pairs(self.tWidgetElementR or {}) do
        -- 大号卡牌，若无第二元素，则第二元素位置显示第一元素颜色
        local nElementType = nElementType2 or nElementType1
        if nElementType and nIndex == nElementType then
            UIHelper.SetVisible(self.WidgetElementR, true)
            UIHelper.SetVisible(widgetElement, true)
        else
            UIHelper.SetVisible(widgetElement, false)
        end
    end
    -- 右上角第二元素衬底
    for nIndex, widgetElement in pairs(self.tWidgetElement02Bg or {}) do
        local bVisible = nIndex == nElementType2
        UIHelper.SetVisible(widgetElement, bVisible)
    end
    for nIndex, imgIcon in pairs(self.tImgElementIcon or {}) do
        local bVisible = nIndex == nElementType1 or nIndex == nElementType2
        UIHelper.SetVisible(imgIcon, bVisible)
        if nIndex == nElementType1 then
            UIHelper.SetLocalZOrder(imgIcon, 0)
        elseif nIndex == nElementType2 then
            UIHelper.SetLocalZOrder(imgIcon, 1)
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutElement)

    Timer.DelTimer(self, self.nEnhancedAniTimerID)
    for nIndex, widgetStar in pairs(self.tWidgetStarRing or {}) do
        local bVisible = nStar and nIndex == nStar
        UIHelper.SetVisible(widgetStar, bVisible)
        UIHelper.StopAni(self, widgetStar, szEnhancedAniName)
        if bVisible then
            local imgBg = UIHelper.GetChildByName(widgetStar, "ImgBg") -- ImgBg（衬底圆形光晕）
            local szBgColor = nElementType1 and tRingBgColor[nElementType1] or szDefaultRingBgColor
            local tBgColor = UIHelper.ChangeHexColorStrToColor(szBgColor)
            UIHelper.SetColor(imgBg, tBgColor)
            for i = 0, 4 do
                -- ImgBg0-4（层层叠加的圆环，按元素用同个颜色）
                local img = UIHelper.GetChildByName(widgetStar, string.format("ImgBg%d", i))
                local szColor = nElementType1 and tRingColor[nElementType1] or szDefaultRingColor
                local tColor = UIHelper.ChangeHexColorStrToColor(szColor)
                UIHelper.SetColor(img, tColor)
            end
            if bShowEnhanced then
                self.nEnhancedAniTimerID = Timer.AddFrame(self, 1, function()
                    UIHelper.PlayAni(self, widgetStar, szEnhancedAniName, nil, nil, nil, ENHANCED_ANI_SPEED)
                end)
            end
        end
    end
    UIHelper.SetClearStencilAll(self.WidgetStarRing, true) -- 超出Mask问题处理

    local szImgCardBg = nElementType1 and tImgBgCardL[nElementType1] or szImgBgCardL_NoElement
    UIHelper.SetSpriteFrame(self.ImgCardBg, szImgCardBg)
end

function UIWidgetBlessCard:InitElementSmall(nElementType1, nElementType2)
    UIHelper.SetVisible(self.WidgetElementL, false)
    UIHelper.SetVisible(self.WidgetElementR, false)
    for nIndex, widgetElement in pairs(self.tWidgetElementL or {}) do
        if nElementType1 and nIndex == nElementType1 then
            UIHelper.SetVisible(self.WidgetElementL, true)
            UIHelper.SetVisible(widgetElement, true)
        else
            UIHelper.SetVisible(widgetElement, false)
        end
    end
    for nIndex, widgetElement in pairs(self.tWidgetElementR or {}) do
        if nElementType2 and nIndex == nElementType2 then
            UIHelper.SetVisible(self.WidgetElementR, true)
            UIHelper.SetVisible(widgetElement, true)
        else
            UIHelper.SetVisible(widgetElement, false)
        end
    end
    for nIndex, imgIcon in pairs(self.tImgElementIcon or {}) do
        local bVisible = nIndex == nElementType1 or nIndex == nElementType2
        UIHelper.SetVisible(imgIcon, bVisible)
        if nIndex == nElementType1 then
            UIHelper.SetLocalZOrder(imgIcon, 0)
        elseif nIndex == nElementType2 then
            UIHelper.SetLocalZOrder(imgIcon, 1)
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutElement)

    local szCardColor = nElementType1 and tCardBgColor[nElementType1] or szDefaultCardBgColor
    local tBgColor = UIHelper.ChangeHexColorStrToColor(szCardColor)
    UIHelper.SetColor(self.ImgCardBg, tBgColor)
end

function UIWidgetBlessCard:InitStar(nStar)
    local bHasStar = nStar and nStar > 0
    UIHelper.SetVisible(self.ImgFrame_0Star, not bHasStar)
    for nIndex, imgStarFrame in pairs(self.tImgStarFrame or {}) do
        local bVisible = nStar and nIndex == nStar
        UIHelper.SetVisible(imgStarFrame, bVisible)
    end
    for nIndex, imgStar in pairs(self.tImgStar or {}) do
        local bVisible = nStar and nIndex <= nStar
        UIHelper.SetVisible(imgStar, bVisible)
    end
    UIHelper.SetVisible(self.WidgetStar, bHasStar)
    UIHelper.LayoutDoLayout(self.WidgetStar)
end

function UIWidgetBlessCard:InitElementPoint(tElementPointType, nAddElementPoint)
    if not self.tImgElementPoint then
        return
    end
    -- 注意这里self.tLabelElement的顺序要与BlessElementType的顺序一致
    -- local tElementPoint, _, _ = ArenaTowerData.GetElementPointInfo()
    local bHasElementPoint = false
    for _, nType in pairs(BlessElementType) do
        local imgElementPoint = self.tImgElementPoint[nType]
        local bShow, nOrder = table.contain_value(tElementPointType, nType)
        UIHelper.SetVisible(imgElementPoint, bShow)
        if bShow then
            bHasElementPoint = true
        end
        if nOrder then
            UIHelper.SetLocalZOrder(imgElementPoint, nOrder)
        end
    end

    UIHelper.SetVisible(self.LayoutElementPoint, bHasElementPoint)
    if bHasElementPoint and nAddElementPoint and nAddElementPoint ~= 0 then
        UIHelper.SetString(self.LabelElementPointNum, "+" .. nAddElementPoint)
        UIHelper.LayoutDoLayout(self.LayoutIcon)
        UIHelper.LayoutDoLayout(self.LayoutElementPoint)
    end
end

function UIWidgetBlessCard:InitCard()
    local tCardData = self.tCardData
    if not tCardData then
        return
    end

    self:StopAllSFXAni()
    self:InitStar(tCardData.nStar)
    self:InitElementStatus()

    local nTag = tCardData.nTag
    for _, nTagType in pairs(BlessCardTagType) do
        local node = self[tTagNode[nTagType]]
        UIHelper.SetVisible(node, nTagType == nTag)
    end

    local bMainSkill = tCardData.bMainSkill
    UIHelper.SetVisible(self.ImgFrame_BeiDong, not bMainSkill)
    UIHelper.SetVisible(self.ImgFrame_ZhuDong, bMainSkill)
    UIHelper.SetVisible(self.WidgetTagSkillZhuDong, bMainSkill)
    UIHelper.LayoutDoLayout(self.LayoutTag)

    UIHelper.SetString(self.LabelBlessName, tCardData.szName)
    UIHelper.SetTexture(self.ImgSkillIcon, tCardData.szIconPath, nil, function()
        UIHelper.UpdateMask(self.MaskIcon)
    end)

    local bEnhanced = tCardData.bEnhanced or false
    local bPreview = tCardData.bPreview or false
    UIHelper.SetVisible(self.ImgCardUpgraded, bEnhanced)
    UIHelper.SetVisible(self.SFX_QiangHua_Loop, bEnhanced and not bPreview)

    UIHelper.LayoutDoLayout(self.WidgetBlessType)

    local nAniEvent = tCardData.nAniEvent
    if nAniEvent then
        self:PlayAni(nAniEvent)
    end
end

function UIWidgetBlessCard:InitElementStatus()
    local bHasElementStatus = false

    local tCardData = self.tCardData
    if not tCardData then
        return
    end

    -- 点燃
    local nState = tCardData.nState or BlessCardState.Normal
    if not nState or nState == BlessCardState.Normal then
        UIHelper.SetVisible(self.WidgetStatus_Huo, false)
        UIHelper.SetVisible(self.WidgetStatus_Huo2, false)
        UIHelper.SetVisible(self.WidgetStatus_Huo3, false)
        UIHelper.SetVisible(self.SFX_HuoKa_Loop, false)
    elseif nState == BlessCardState.Burning then
        bHasElementStatus = true
        local nLeftBurnRound = tCardData.nLeftBurnRound or 0
        UIHelper.SetVisible(self.WidgetStatus_Huo, true)
        UIHelper.SetVisible(self.WidgetStatus_Huo2, false)
        UIHelper.SetVisible(self.WidgetStatus_Huo3, false)
        UIHelper.SetVisible(self.SFX_HuoKa_Loop, true)
        UIHelper.SetString(self.LabelHuoNum, nLeftBurnRound)
    elseif nState == BlessCardState.Ash then
        bHasElementStatus = true
        UIHelper.SetVisible(self.WidgetStatus_Huo, false)
        UIHelper.SetVisible(self.WidgetStatus_Huo2, true)
        UIHelper.SetVisible(self.WidgetStatus_Huo3, false)
        UIHelper.SetVisible(self.SFX_HuoKa_Loop, false)
    elseif nState == BlessCardState.Revive then
        bHasElementStatus = true
        UIHelper.SetVisible(self.WidgetStatus_Huo, false)
        UIHelper.SetVisible(self.WidgetStatus_Huo2, false)
        UIHelper.SetVisible(self.WidgetStatus_Huo3, true)
        UIHelper.SetVisible(self.SFX_HuoKa_Loop, false)
    end

    -- 生机点
    local bWood = ArenaTowerData.CardHasElement(tCardData, BlessElementType.Mu)
    if bWood then
        bHasElementStatus = true
        local _, nGrowWoodPoint, nMaxGrowWoodPoint = ArenaTowerData.GetElementPointInfo()
        local fPercent = 100 * nGrowWoodPoint / nMaxGrowWoodPoint
        UIHelper.SetVisible(self.WidgetStatus_Mu, true)
        UIHelper.SetProgressBarStarPercentPt(self.ImgBarFg, 0.5, 0)
        UIHelper.SetProgressBarPercent(self.ImgBarFg, fPercent)
        UIHelper.SetString(self.LabelMuTitle, string.format("%d/%d", nGrowWoodPoint, nMaxGrowWoodPoint))
        UIHelper.LayoutDoLayout(self.LayoutMuContent)
    else
        UIHelper.SetVisible(self.WidgetStatus_Mu, false)
    end

    local nSpecialTag = not bHasElementStatus and tCardData.nSpecialTag
    UIHelper.SetVisible(self.WidgetStatus_Jin, nSpecialTag == BlessCardSpecialTagType.GoldState)
    UIHelper.SetVisible(self.WidgetStatus_Shui, nSpecialTag == BlessCardSpecialTagType.WaterState)
    UIHelper.SetVisible(self.WidgetStatus_Tu, nSpecialTag == BlessCardSpecialTagType.EarthState)
    if nSpecialTag and nSpecialTag > 0 then
        bHasElementStatus = true
    end

    UIHelper.LayoutDoLayout(self.LayoutBottom, true)
    UIHelper.SetVisible(self.LayoutBottom, bHasElementStatus)
    UIHelper.SetVisible(self.WidgetBottomLeft, bHasElementStatus)
end

function UIWidgetBlessCard:UpdateDesc()
    local tCardData = self.tCardData
    if not tCardData then
        return
    end

    local function GetCardDesc(tInfo)
        if not tInfo then return end
        if ArenaTowerData.bShowBlessDetailDesc then
            if not string.is_nil(tInfo.szDesc) then
                return tInfo.szDesc
            elseif not string.is_nil(tInfo.szShortDesc) then
                return tInfo.szShortDesc
            end
        else
            if not string.is_nil(tInfo.szShortDesc) then
                return tInfo.szShortDesc
            elseif not string.is_nil(tInfo.szDesc) then
                return tInfo.szDesc
            end
        end
        return ""
    end

    local szDesc, szFireDesc
    if tCardData.bEnhanced and tCardData.tEnhancedSkillInfo then
        szDesc = GetCardDesc(tCardData.tEnhancedSkillInfo)
        szFireDesc = GetCardDesc(tCardData.tEnhancedFireSkillInfo)
    elseif tCardData.tSkillInfo then
        szDesc = GetCardDesc(tCardData.tSkillInfo)
        szFireDesc = GetCardDesc(tCardData.tFireSkillInfo)
    else
        szDesc = GetCardDesc(tCardData)
    end

    -- 常规：常规描述+燃烧描述（半透明）；
    -- 燃烧：燃烧描述+常规描述（半透明）；
    -- 灰烬：常规描述（半透明）+燃烧描述（半透明）；
    -- 涅槃：常规描述；

    szDesc = UIHelper.AttachTextColor(szDesc or "", TEXT_COLOR_NORMAL)
    szFireDesc = szFireDesc and UIHelper.AttachTextColor(szFireDesc, TEXT_COLOR_NORMAL)
    local szFormat = "<img src='%s' width='25' height='30'/><color=%s>[点燃] </c>%s"

    local nState = tCardData.nState or BlessCardState.Normal
    if nState == BlessCardState.Normal then
        UIHelper.SetRichText(self.RichTextDesc01, szDesc)
        UIHelper.SetOpacity(self.RichTextDesc01, OPACITY_NORMAL)
        if szFireDesc then
            szFireDesc = string.format(szFormat, szBurningIconPath, TEXT_COLOR_FIRE, szFireDesc)
            UIHelper.SetRichText(self.RichTextDesc02, "【未生效】" .. szFireDesc)
            UIHelper.SetVisible(self.RichTextDesc02, true)
            UIHelper.SetOpacity(self.RichTextDesc02, OPACITY_GRAY)
        else
            UIHelper.SetVisible(self.RichTextDesc02, false)
        end
    elseif nState == BlessCardState.Burning then
        UIHelper.SetOpacity(self.RichTextDesc01, OPACITY_NORMAL)
        if szFireDesc then
            szFireDesc = string.format(szFormat, szBurningIconPath, TEXT_COLOR_FIRE, szFireDesc)
            UIHelper.SetRichText(self.RichTextDesc01, szFireDesc)
            UIHelper.SetRichText(self.RichTextDesc02, "【未生效】" .. szDesc)
            UIHelper.SetVisible(self.RichTextDesc02, true)
            UIHelper.SetOpacity(self.RichTextDesc02, OPACITY_GRAY)
        else
            UIHelper.SetRichText(self.RichTextDesc01, szDesc)
            UIHelper.SetVisible(self.RichTextDesc02, false)
        end
    elseif nState == BlessCardState.Ash then
        UIHelper.SetRichText(self.RichTextDesc01, szDesc)
        UIHelper.SetOpacity(self.RichTextDesc01, OPACITY_GRAY)
        if szFireDesc then
            szFireDesc = string.format(szFormat, szAshIconPath, TEXT_COLOR_FIRE, szFireDesc)
            UIHelper.SetRichText(self.RichTextDesc02, "【未生效】" .. szFireDesc)
            UIHelper.SetVisible(self.RichTextDesc02, true)
            UIHelper.SetOpacity(self.RichTextDesc02, OPACITY_GRAY)
        else
            UIHelper.SetVisible(self.RichTextDesc02, false)
        end
    elseif nState == BlessCardState.Revive then
        UIHelper.SetRichText(self.RichTextDesc01, szDesc)
        UIHelper.SetOpacity(self.RichTextDesc01, OPACITY_NORMAL)
        UIHelper.SetVisible(self.RichTextDesc02, false)
    end

    UIHelper.SetSwallowTouches(self.ScrollViewDesc, false)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDesc)
end

function UIWidgetBlessCard:UpdateLeftBuyCount()
    local tCardData = self.tCardData
    if not tCardData then
        return
    end

    local nLeftBuyCount = tCardData.nLeftBuyCount
    local nShopItemType = tCardData.nShopItemType
    local bShowLeftBuyCount = nShopItemType ~= BlessShopItemType.Bless or nLeftBuyCount > 1 -- 祝福且可购买次数为1也不显示标签
    if nLeftBuyCount and nLeftBuyCount > 0 and bShowLeftBuyCount then
        UIHelper.SetVisible(self.WidgetTagAttribute, true)
        UIHelper.SetString(self.LabelAttribute, string.format("还可祈卦%d次", nLeftBuyCount))
    else
        UIHelper.SetVisible(self.WidgetTagAttribute, false)
    end
    UIHelper.LayoutDoLayout(self.LayoutTag)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDesc)
end

-- 附加标识: bPreview - 强化界面预览状态不显示“已强化”标识，避免玩家误以为已经强化
function UIWidgetBlessCard:OnInitLargeCard(tCardData, bCanSelect)
    self.tCardData = tCardData
    self:InitCard()
    self:SetCanSelect(bCanSelect or false)

    if not tCardData then
        return
    end

    local nStar = tCardData.nStar
    local nElementType1 = tCardData.nElementType1
    local nElementType2 = tCardData.nElementType2
    local bShowEnhanced = tCardData.bEnhanced and not tCardData.bPreview or false
    local bShowEnhancable = tCardData.bCanEnhanced and (not tCardData.bEnhanced or tCardData.bPreview) or false

    self:InitElementLarge(nElementType1, nElementType2, nStar, bShowEnhanced) -- 大号卡牌，若无第二元素，则第二元素位置显示第一元素颜色
    self:InitElementPoint(tCardData.tElementPointType, tCardData.nAddElementPoint)

    UIHelper.SetVisible(self.WidgetLineUpgraded, bShowEnhanced)
    UIHelper.SetVisible(self.WidgetLineUpgradable, bShowEnhancable)
    UIHelper.SetVisible(self.LabelUpgradable, bShowEnhancable and not tCardData.bPreview)
    UIHelper.SetVisible(self.LabelPreview, bShowEnhancable and tCardData.bPreview)
    UIHelper.SetVisible(self.ImgLineNormal, not bShowEnhanced and not bShowEnhancable)

    local szEnhancedSFXPath = nElementType1 and tLargeCardEnhancedSFXPath[nElementType1] or szLargeCardDefaultEnhancedSFXPath
    UIHelper.SetSFXPath(self.SFX_QiangHua_Loop, UIHelper.UTF8ToGBK(szEnhancedSFXPath))

    self:UpdateDesc()
    self:UpdateLeftBuyCount()

    UIHelper.UnBindUIEvent(self.WidgetStatus_Huo, EventType.OnClick)
    UIHelper.UnBindUIEvent(self.WidgetStatus_Huo2, EventType.OnClick)
    UIHelper.UnBindUIEvent(self.WidgetStatus_Huo3, EventType.OnClick)
    UIHelper.UnBindUIEvent(self.WidgetStatus_Mu, EventType.OnClick)
    UIHelper.UnBindUIEvent(self.WidgetStatus_Jin, EventType.OnClick)
    UIHelper.UnBindUIEvent(self.WidgetStatus_Shui, EventType.OnClick)
    UIHelper.UnBindUIEvent(self.WidgetStatus_Tu, EventType.OnClick)
    UIHelper.BindUIEvent(self.WidgetStatus_Huo, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.WidgetStatus_Huo, TipsLayoutDir.AUTO, g_tStrings.ARENA_TOWER_TIPS_FIRE)
    end)
    UIHelper.BindUIEvent(self.WidgetStatus_Huo2, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.WidgetStatus_Huo2, TipsLayoutDir.AUTO, g_tStrings.ARENA_TOWER_TIPS_ASHES)
    end)
    UIHelper.BindUIEvent(self.WidgetStatus_Huo3, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.WidgetStatus_Huo3, TipsLayoutDir.AUTO, g_tStrings.ARENA_TOWER_TIPS_REVIVE)
    end)
    UIHelper.BindUIEvent(self.WidgetStatus_Mu, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.WidgetStatus_Mu, TipsLayoutDir.AUTO, g_tStrings.ARENA_TOWER_TIPS_GROW)
    end)
    UIHelper.BindUIEvent(self.WidgetStatus_Jin, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.WidgetStatus_Jin, TipsLayoutDir.AUTO, g_tStrings.ARENA_TOWER_TIPS_GOLD)
    end)
    UIHelper.BindUIEvent(self.WidgetStatus_Shui, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.WidgetStatus_Shui, TipsLayoutDir.AUTO, g_tStrings.ARENA_TOWER_TIPS_WATER)
    end)
    UIHelper.BindUIEvent(self.WidgetStatus_Tu, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.WidgetStatus_Tu, TipsLayoutDir.AUTO, g_tStrings.ARENA_TOWER_TIPS_EARTH)
    end)
end

-- 附加标识: bEnhancedView - 标识当前在强化界面，不可强化的卡牌显示相关标识
function UIWidgetBlessCard:OnInitSmallCard(tCardData)
    self.tCardData = tCardData
    self:InitCard()
    self:SetCanSelect(true)

    if not tCardData then
        return
    end

    local nElementType1 = tCardData.nElementType1
    local nElementType2 = tCardData.nElementType2
    self:InitElementSmall(nElementType1, nElementType2)

    local szEnhancedSFXPath = nElementType1 and tSmallCardEnhancedSFXPath[nElementType1] or szSmallCardDefaultEnhancedSFXPath
    UIHelper.SetSFXPath(self.SFX_QiangHua_Loop, UIHelper.UTF8ToGBK(szEnhancedSFXPath))

    if tCardData.bEnhancedView then
        UIHelper.SetVisible(self.WidgetCantUpgrade, not tCardData.bCanEnhanced or tCardData.bEnhanced)
    end

    self:UpdateLeftBuyCount() -- 其实小卡应该不会显示这个，不过保险起见可以顺便加一下
end

function UIWidgetBlessCard:OnInitShopItem(tCardData)
    self.tCardData = tCardData
    self:InitCard()
    self:SetCanSelect(true)

    if not tCardData then
        return
    end

    local nElementType1 = tCardData.nElementType1
    local nElementType2 = tCardData.nElementType2
    self:InitElementSmall(nElementType1, nElementType2)

    UIHelper.SetVisible(self.WidgetNoElementL, not nElementType1)
    UIHelper.SetVisible(self.WidgetElementL, true)

    local nPrice = tCardData.nPrice
    local nCoinInGame, _ = ArenaTowerData.GetCoinInGameInfo()
    UIHelper.SetString(self.LabelNum, nPrice)
    UIHelper.SetColor(self.LabelNum, nCoinInGame >= nPrice and PRICE_TEXT_COLOR or PRICE_TEXT_COLOR_RED)
    UIHelper.LayoutDoLayout(self.LayoutCurrency)

    local bCanBuy = tCardData.nLeftBuyCount > 0
    UIHelper.SetVisible(self.LayoutCurrency, bCanBuy)
    UIHelper.SetVisible(self.WidgetGot, not bCanBuy)

    self:UpdateLeftBuyCount()
end

function UIWidgetBlessCard:SetClickCallback(fnCallback)
    self.fnCallback = fnCallback
end

function UIWidgetBlessCard:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogCard, bSelected)
end

function UIWidgetBlessCard:SetCanSelect(bCanSelect)
    UIHelper.SetTouchEnabled(self.TogCard, bCanSelect)
    UIHelper.SetSwallowTouches(self.TogCard, false)
end

function UIWidgetBlessCard:SetNewCard(bNewCard)
    UIHelper.SetVisible(self.WidgetNew, bNewCard)
end

function UIWidgetBlessCard:UpdateLayout()
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDesc)
end

-- BlessCardAniEvent
function UIWidgetBlessCard:PlayAni(nAniEvent, fnCallback)
    self:StopAllSFXAni()
    local szAniName = tCardAniName[nAniEvent]
    if not szAniName then
        if fnCallback then
            fnCallback()
        end
        return
    end

    UIHelper.PlayAni(self, self.AniAll, szAniName, fnCallback)
end

function UIWidgetBlessCard:StopAllSFXAni()
    UIHelper.StopAllAni(self)
    for _, aniNode in ipairs(self.tSFXAniNode or {}) do
        UIHelper.SetVisible(aniNode, false)
    end
end

return UIWidgetBlessCard