-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterScorePopView
-- Date: 2022-11-11 14:51:06
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICharacterScorePopView = class("UICharacterScorePopView")

function UICharacterScorePopView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UICharacterScorePopView:OnExit()
    self.bInit = false
end

function UICharacterScorePopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnHelp, EventType.OnClick, function(btn)
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnHelp, TipsLayoutDir.RIGHT_CENTER, "装分提示：侠士可以点击面板中的秘境评分或者对抗评分切换装分提升提示，当侠士获取并装备新装备时，会根据选择进行评分升降提醒。")
    end)

    UIHelper.BindUIEvent(self.TogMystery, EventType.OnClick, function(_)
        local bSelected = UIHelper.GetSelected(self.TogMystery)
        if bSelected then
            Storage.Player.bShowFightingNum = true
            Storage.Player.bShowPVPSkillScore = false
        else
            Storage.Player.bShowFightingNum = false
            Storage.Player.bShowPVPSkillScore = false
        end
        Storage.Player.Dirty()

        self:UpdateToggleState()
    end)

    UIHelper.BindUIEvent(self.TogPk, EventType.OnClick, function(_)
        local bSelected = UIHelper.GetSelected(self.TogPk)
        if bSelected then
            Storage.Player.bShowFightingNum = true
            Storage.Player.bShowPVPSkillScore = true
        else
            Storage.Player.bShowFightingNum = false
            Storage.Player.bShowPVPSkillScore = true
        end
        Storage.Player.Dirty()

        self:UpdateToggleState()
    end)

    UIHelper.BindUIEvent(self.TogHideScore, EventType.OnClick, function(_)
        local bSelected = not Storage.Player.bShowFightingNum
        Storage.Player.bShowFightingNum = bSelected
        Storage.Player.Dirty()

        self:UpdateToggleState()
    end)

    UIHelper.BindUIEvent(self.BtnTip, EventType.OnClick, function(btn)
        local player = PlayerData.GetClientPlayer()
        if not player then
            return
        end
        local nBaseScores = player.GetBaseEquipScore()
        local nStrengthScores = player.GetStrengthEquipScore()
        local nStoneScores = player.GetMountsEquipScore()

        local szTip = string.format("<color=#FFE26E>%s</c>", FormatString(g_tStrings.STR_ITEM_H_ITEM_SCORE, nBaseScores + nStrengthScores + nStoneScores))
        szTip = GetFormatText(szTip.."\n", 157)
        szTip = szTip .. g_tStrings.STR_EQUIP_SCORES_TIP
        szTip = szTip .. GetFormatText("\n\n")
        szTip = szTip .. GetFormatText(g_tStrings.STR_EQUIP_BASE_SCORES ..g_tStrings.STR_COLON..nBaseScores.."\n")
        szTip = szTip .. GetFormatText(g_tStrings.STR_EQUIP_STRENGTH_SCORES ..g_tStrings.STR_COLON..nStrengthScores.."\n")
        szTip = szTip .. GetFormatText(g_tStrings.STR_EQUIP_STONE_SCORES ..g_tStrings.STR_COLON..nStoneScores)

        local tips, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnTip, TipsLayoutDir.BOTTOM_CENTER, szTip)
    end)

end

function UICharacterScorePopView:RegEvent()
    -- Event.Reg(self, EventType.XXX, func)
end

function UICharacterScorePopView:UpdateInfo()
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

	local nAttackPVP, nToughPVP, nTherapyPVP, nAttackPVE, nToughPVE, nTherapyPVE = PlayerData.GetAttackAndToughScore(player)
    local tInfo = PlayerData.GetShowInfo(player)
	local bShowTherapy = tInfo.bShowTherapy
	local bTherapyMainly = tInfo.bTherapyMainly

    UIHelper.SetString(self.LabelNum, PlayerData.GetPlayerTotalEquipScore(player))

    UIHelper.SetString(self.LabelPVEDefnseNum1, nToughPVE)
    UIHelper.SetString(self.LabelPVEDefnseNum2, nToughPVE)
    UIHelper.SetString(self.LabelPVPDefnseNum1, nToughPVP)
    UIHelper.SetString(self.LabelPVPDefnseNum2, nToughPVP)

    if bTherapyMainly then
        UIHelper.SetString(self.LabelPVEAttackNum1, nTherapyPVE)
        UIHelper.SetString(self.LabelPVEAttackNum2, nTherapyPVE)
        UIHelper.SetString(self.LabelPVPAttackNum1, nTherapyPVP)
        UIHelper.SetString(self.LabelPVPAttackNum2, nTherapyPVP)
        UIHelper.SetString(self.LabelPVPAttack, "治疗评分")
        UIHelper.SetString(self.LabelPVPAttack2, "治疗评分")
        UIHelper.SetString(self.LabelPVEAttack, "治疗评分")
        UIHelper.SetString(self.LabelPVEAttack2, "治疗评分")
    else
        UIHelper.SetString(self.LabelPVEAttackNum1, nAttackPVE)
        UIHelper.SetString(self.LabelPVEAttackNum2, nAttackPVE)
        UIHelper.SetString(self.LabelPVPAttackNum1, nAttackPVP)
        UIHelper.SetString(self.LabelPVPAttackNum2, nAttackPVP)
        UIHelper.SetString(self.LabelPVPAttack, "攻击评分")
        UIHelper.SetString(self.LabelPVPAttack2, "攻击评分")
        UIHelper.SetString(self.LabelPVEAttack, "攻击评分")
        UIHelper.SetString(self.LabelPVEAttack2, "攻击评分")

    end

    self:UpdateToggleState()
    self:UpdateScorePointInfo()
end

function UICharacterScorePopView:UpdateScorePointInfo()
    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    local nBaseScores = player.GetBaseEquipScore()
	local nStrengthScores = player.GetStrengthEquipScore()
	local nStoneScores = player.GetMountsEquipScore()
	local nScores =  nBaseScores + nStrengthScores + nStoneScores

	local nScoreLevel, szFrame = PlayerData.GetEquipScoresLevel(nScores)
    UIHelper.SetSpriteFrame(self.ImgIconEquipRank, szFrame)

    UIHelper.SetTabVisible(self.tbImgScoreDot, false)
    if nBaseScores > 0 then
		UIHelper.SetVisible(self.tbImgScoreDot[1], true)
	end
	if nStrengthScores > 0 then
		UIHelper.SetVisible(self.tbImgScoreDot[2], true)
	end
	if nStoneScores > 0 then
		UIHelper.SetVisible(self.tbImgScoreDot[3], true)
	end
end

function UICharacterScorePopView:UpdateToggleState()
    UIHelper.SetSelected(self.TogMystery, not Storage.Player.bShowPVPSkillScore)
    UIHelper.SetSelected(self.TogPk, Storage.Player.bShowPVPSkillScore)
    UIHelper.SetSelected(self.TogHideScore, not Storage.Player.bShowFightingNum)
    UIHelper.SetVisible(self.WidgetAlert1, Storage.Player.bShowFightingNum)
    UIHelper.SetVisible(self.WidgetAlert2, Storage.Player.bShowFightingNum)
end

return UICharacterScorePopView