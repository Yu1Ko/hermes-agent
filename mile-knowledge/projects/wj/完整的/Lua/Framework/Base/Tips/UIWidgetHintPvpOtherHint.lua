-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetHintPvpOtherHint
-- Date: 2024-04-02 10:48:56
-- Desc: ?
-- ---------------------------------------------------------------------------------
local CAMP_TO_IMGBG = {
    [CAMP.GOOD] = "UIAtlas2_Public_PublicHint_PublicSpecialHint_BossHintRed.png",
    [CAMP.EVIL] = "UIAtlas2_Public_PublicHint_PublicSpecialHint_BossHintBlue.png",
}
local nStartFadedTime = 3
local nFadedDuration = 3

local UIWidgetHintPvpOtherHint = class("UIWidgetHintPvpOtherHint")

function UIWidgetHintPvpOtherHint:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetHintPvpOtherHint:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetHintPvpOtherHint:BindUIEvent()
    
end

function UIWidgetHintPvpOtherHint:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnShieldTip, function(szEvent, tbData)
        local bClose = tbData.bClose
        if bClose then
            -- self[string.format("Close", ...)]()--关闭
        else
            local func = self[string.format("Update%sVis", szEvent)]
            if func then func(self) end
        end
    end)

    Event.Reg(self, EventType.OnUnShieldTip, function(szEvent, bClose)
        if not bClose then
            local func = self[string.format("Update%sVis", szEvent)]
            if func then func(self) end
        end
    end)

    Event.Reg(self, EventType.OnClientPlayerLeave, function()
        self:HideCampHint()
    end)

end

function UIWidgetHintPvpOtherHint:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetHintPvpOtherHint:ShowCampHint(nBossID)
    if g_pClientPlayer.nCamp == CAMP.NEUTRAL then return end
    self.RichTextBossHint:ignoreContentAdaptWithSize(true)
    local tbInfo = CampData.GetBossInfoByID(nBossID)
    local nBossCamp = tbInfo.nCamp
    local szBossName = UIHelper.GBKToUTF8(tbInfo.szBossName)
    local szIconImage = tbInfo.szMobileBossIcon
    local szText = g_tStrings.STR_CAMP_TIP[g_pClientPlayer.nCamp][nBossCamp]

    UIHelper.SetRichText(self.RichTextBossHint, szText)
    UIHelper.SetSpriteFrame(self.ImgBgZhenying, CAMP_TO_IMGBG[nBossCamp])
    UIHelper.SetSpriteFrame(self.ImgBossIcon, szIconImage)

    self.bShowCampHint = true
    self:UpdateShowCampHintVis()

    self:StartAutoClose()
end


function UIWidgetHintPvpOtherHint:HideCampHint()
    self.bShowCampHint = false
    self:UpdateShowCampHintVis()
    self:StopAutoClose()
end 

function UIWidgetHintPvpOtherHint:StartAutoClose()

    self:StopAutoClose()

    -- UIHelper.FadeNode(self.AniZhenYingHint, 255, 0)
    -- self.nAutoClose = Timer.Add(self, nStartFadedTime, function()
    --     UIHelper.FadeNode(self.AniZhenYingHint, 0, nFadedDuration, function()
    --         self:HideCampHint()
    --     end)
    --     self.nAutoClose = nil
    -- end)
    UIHelper.PlayAni(self, self.AniZhenYingHint, "AniZhenYingHint")
end

function UIWidgetHintPvpOtherHint:StopAutoClose()
    -- if self.nAutoClose then
    --     Timer.DelTimer(self, self.nAutoClose)
    --     self.nAutoClose = nil
    -- end
    -- UIHelper.StopAllActions(self.AniZhenYingHint)
    UIHelper.StopAni(self, self.AniZhenYingHint, "AniZhenYingHint")
end


function UIWidgetHintPvpOtherHint:UpdateShowCampHintVis()
    local bVis = not TipsHelper.IsTipShield(EventType.ShowCampHint) and self.bShowCampHint
    UIHelper.SetVisible(self.AniZhenYingHint, bVis)
end


return UIWidgetHintPvpOtherHint