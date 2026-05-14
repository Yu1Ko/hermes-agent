-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMiniGameStartHint
-- Date: 2025-09-18 17:14:39
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIMiniGameStartHint = class("UIMiniGameStartHint")

local tEffectPath = {
    ["NewYear2"] = UTF8ToGBK("data\\source\\other\\HD特效\\其他\\Pss\\UI_接财纳福_红包雨.pss"),
}

local tBgImagePath = {
    ["NewYear2"] = "UIAtlas2_Public_PublicHint_PublicHintGame_SpringFestival_Hint.png",
}

local tBgImagePath_1 = {
    ["Red"]     = "UIAtlas2_Public_PublicHint_PublicHintGame_Red.png",
    ["Blue"]    = "UIAtlas2_Public_PublicHint_PublicHintGame_Blue.png",
    ["Green"]   = "UIAtlas2_Public_PublicHint_PublicHintGame_Green.png",
    ["Purple"]  = "UIAtlas2_Public_PublicHint_PublicHintGame_Purple.png",
    ["NewYear"] = "UIAtlas2_Public_PublicHint_PublicHintGame_Fish1.png",
}

local tBgImagePath_2 = {
    ["NewYear"] = "UIAtlas2_Public_PublicHint_PublicHintGame_Fish2.png",
}

local tBgImageScaleX_1 = {
    ["Red"]     = 1,
    ["Blue"]    = 1,
    ["Green"]   = 1,
    ["Purple"]  = 1,
    ["NewYear"] = 1,
}

local tBgImageScaleX_2 = {
    ["Red"]     = -1,
    ["Blue"]    = -1,
    ["Green"]   = -1,
    ["Purple"]  = -1,
    ["NewYear"] = 1,
}

local AUTO_CLOSE = 5
function UIMiniGameStartHint:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if self.nTimer then
        Timer.DelTimer(self.nTimer)
        self.nTimer = nil
    end
    tInfo           = tInfo or {}
    self.nTimer     = Timer.Add(self, AUTO_CLOSE, function () UIHelper.SetVisible(self._rootNode, false) end)
    self.szTitle    = UIHelper.GBKToUTF8(tInfo.szTitle) or ""
    self.szSubtitle = UIHelper.GBKToUTF8(tInfo.szSubtitle) or ""
    self.szBgType   = tInfo.szBgType or "Blue"
    self.szContent  = UIHelper.GBKToUTF8(tInfo.szContent) or ""
    self:Update()
end

function UIMiniGameStartHint:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMiniGameStartHint:BindUIEvent()

end

function UIMiniGameStartHint:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIMiniGameStartHint:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIMiniGameStartHint:Update()
    UIHelper.SetString(self.LabelHintTitle, self.szTitle)
    UIHelper.SetString(self.LabelHintNum, self.szSubtitle)
    UIHelper.SetString(self.LabelHintContent, self.szContent)

    UIHelper.SetVisible(self.ImgHint, false)
    UIHelper.SetVisible(self.ImgHint1, false)
    UIHelper.SetVisible(self.ImgHint2, false)

    local szBgImagePath = tBgImagePath[self.szBgType]
    if szBgImagePath then
        UIHelper.SetVisible(self.ImgHint, true)
        UIHelper.SetSpriteFrame(self.ImgHint, szBgImagePath)
    else
        UIHelper.SetVisible(self.ImgHint1, true)
        UIHelper.SetVisible(self.ImgHint2, true)

        local szBgImagePath_1 = tBgImagePath_1[self.szBgType] or tBgImagePath_1["Blue"]
        local szBgImagePath_2 = tBgImagePath_2[self.szBgType] or szBgImagePath_1
        UIHelper.SetSpriteFrame(self.ImgHint1, szBgImagePath_1)
        UIHelper.SetSpriteFrame(self.ImgHint2, szBgImagePath_2)

        local nScaleX_1 = tBgImageScaleX_1[self.szBgType] or 1
        local nScaleX_2 = tBgImageScaleX_2[self.szBgType] or -1
        UIHelper.SetScaleX(self.ImgHint1, nScaleX_1)
        UIHelper.SetScaleX(self.ImgHint2, nScaleX_2)
    end

    -- 特效
    local szEffectPath = tEffectPath[self.szBgType]
    if szEffectPath then
        UIHelper.SetSFXPath(self.Effect, szEffectPath, true)
    end

    UIHelper.SetVisible(self._rootNode, true)
end

return UIMiniGameStartHint