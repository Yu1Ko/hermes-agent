-- ---------------------------------------------------------------------------------
-- Name: UIWidgetCampElectionCell
-- Prefab: WidgetCampaignName
-- Desc: 阵营 - 指挥竞选
-- ---------------------------------------------------------------------------------
local UIWidgetCampElectionCell = class("UIWidgetCampElectionCell")

local tRankImg = {
    [1] = "UIAtlas2_FengYunLu_Rank_icon_ranking01",
    [2] = "UIAtlas2_FengYunLu_Rank_icon_ranking02",
    [3] = "UIAtlas2_FengYunLu_Rank_icon_ranking03"
}

function UIWidgetCampElectionCell:OnEnter(tInfo, nRank, nCamp)
    if not self.bInit then
        self:BindUIEvent()
        self.bInit = true
    end
    self.nCamp = nCamp
    UIHelper.SetVisible(self.BtnMore, false)
    self:UpdateInfo(tInfo, nRank)
end

function UIWidgetCampElectionCell:OnExit()
    self.bInit = false
end

function UIWidgetCampElectionCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnGift, EventType.OnClick, function()
        local bLocked = BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP)
        if bLocked then
            TipsHelper.ShowNormalTip("少侠开启了安全锁定，解锁之后方可投票！")
            UIMgr.OpenSingle(false, VIEW_ID.PanelLingLongMiBao, SAFE_LOCK_EFFECT_TYPE.EQUIP)
            return
        end
        
        if KeyBoard.IsKeyDown(cc.KeyCode.KEY_CTRL) then
			local ADDCOUNT = 5
			RemoteCallToServer("On_Camp_ComVote", self.dwTongID, ADDCOUNT, self.szName)
		else
			local ADDCOUNT = 1
			RemoteCallToServer("On_Camp_ComVote", self.dwTongID, ADDCOUNT, self.szName)
		end
		ApplyCustomRankList(self.nCamp)
    end)

    UIHelper.BindUIEvent(self.BtnHead, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelCampaignCommand, self.dwPlayerID, self.szName)
    end)

    UIHelper.BindUIEvent(self.BtnMore, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnMore, UIHelper.RichTextEscape(self.szMsg))
    end)
end

function UIWidgetCampElectionCell:UpdateInfo(tInfo, nRank)
    if not tInfo then
        return
    end
    self.dwTongID = tInfo.dwID
    self.dwPlayerID = tInfo.dwPID
	self.szName = tInfo.szName

    if nRank <= 3 then
        UIHelper.SetSpriteFrame(self.ImgRankingIcon, tRankImg[nRank])
        UIHelper.SetVisible(self.ImgRankingIcon, true)
        UIHelper.SetVisible(self.LabelRanking, false)
	else
        UIHelper.SetString(self.LabelRanking, nRank)
		UIHelper.SetVisible(self.ImgRankingIcon, false)
        UIHelper.SetVisible(self.LabelRanking, true)
	end

    if not self.tInfo or tInfo.dwMinID ~= self.tInfo.dwMinID or tInfo.nRole ~= self.tInfo.nRole or tInfo.nForce ~= self.tInfo.nForce then
        UIHelper.RoleChange_UpdateAvatar(self.ImgPlayerIcon, tInfo.dwMinID, self.SFXPlayerIcon, self.AnimatePlayerIcon, tInfo.nRole, tInfo.nForce, true)
    end

    UIHelper.SetString(self.LabeltHeadCaptainName, UIHelper.GBKToUTF8(tInfo.szName))

    local szMsg = tInfo.szMsg
    if TextFilterCheck(szMsg) == false then 
		_, szMsg = TextFilterReplace(szMsg) 
	end
    self.szMsg = UIHelper.GBKToUTF8(szMsg) or ""

    if UIHelper.GetUtf8Len(self.szMsg) > 9 then
        UIHelper.SetVisible(self.BtnMore, true)
    end
    UIHelper.SetString(self.LabeltHeadCaptainSlogan, self.szMsg, 9)

    UIHelper.SetString(self.LabelMoney, UIHelper.GBKToUTF8(tInfo.szTName))
    local nGoldB, nGold = ConvertGoldToGBrick(tInfo.nMoney)
    local szMoney = nGoldB .. "<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Zhuan' width='40' height='40'/>"
             .. nGold .. "<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Jin' width='40' height='40'/>"
    UIHelper.SetRichText(self.RichTextMoney, szMoney)

    local szFenghuoling = tInfo.nKey .. "<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_leyoubi' width='40' height='40'/>"
    UIHelper.SetRichText(self.RichTextFenghuoling, szFenghuoling)

    self:UpdateTeam(tInfo.tTeamInfo)

    self.tInfo = tInfo
end

function UIWidgetCampElectionCell:UpdateTeam(tTeam)
    if not tTeam then
        return
    end

    UIHelper.RemoveAllChildren(self.WidgetNember)
	for szName, tInfo in pairs(tTeam) do
        local headScript = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetNember, tInfo.dwID)
        assert(headScript)
        headScript:SetHeadInfo(tInfo.dwID, tInfo.dwMinID, tInfo.nRole, tInfo.nForce)
        headScript:SetClickCallback(function()
            UIMgr.Open(VIEW_ID.PanelCampaignCommand, tInfo.dwID, szName)
        end)
	end
    UIHelper.LayoutDoLayout(self.WidgetNember)
end

function UIWidgetCampElectionCell:SetSloganVisible(bVisible)
    UIHelper.SetVisible(self.LabeltHeadCaptainSlogan, bVisible)
end

return UIWidgetCampElectionCell