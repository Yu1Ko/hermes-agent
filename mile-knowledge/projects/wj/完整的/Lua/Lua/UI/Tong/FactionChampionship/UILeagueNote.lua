-- ---------------------------------------------------------------------------------
-- Desc: 武林争霸赛事N强弹出
-- Prefab:PanelChampionshipRankPop
-- ---------------------------------------------------------------------------------

local UILeagueNote = class("UILeagueNote")

function UILeagueNote:_LuaBindList()
    self.LabelName              = self.LabelName --- 玩家姓名
    self.LabelSide              = self.LabelSide --- 浩气恶人
    self.ImgSide                = self.ImgSide
    self.LabelFactionName       = self.LabelFactionName --- 帮会
    self.LabelSeason            = self.LabelSeason --- XX界
    self.ImgNum                 = self.ImgNum --- 结果

    self.BtnClose               = self.BtnClose
end

function UILeagueNote:OnEnter(nRank)
    self.nRank          = nRank

    if not self.bInit then
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitView()
end

function UILeagueNote:OnExit()
    self.bInit = false
end

function UILeagueNote:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UILeagueNote:InitView()
    if not g_pClientPlayer then
        return 
    end

    UIHelper.SetString(self.LabelSeason, "第六届武林争霸赛")

    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(g_pClientPlayer.szName))

    local szTongName = TongData.GetName()
    local tong = GetTongClient()
    local nCamp = tong and tong.nCamp or g_pClientPlayer.nCamp
    if szTongName == "" and tong and g_pClientPlayer.dwTongID ~= 0 then
        szTongName = tong.ApplyGetTongName(g_pClientPlayer.dwTongID) or ''
    end
    UIHelper.SetString(self.LabelFactionName, UIHelper.GBKToUTF8(szTongName))

    if nCamp == CAMP.GOOD then
    UIHelper.SetString(self.LabelSide, "浩气盟侠士")
        UIHelper.SetSpriteFrame(self.ImgSide, "UIAtlas2_Faction_ChampionshipPop_Bg_HaoQi")
    elseif nCamp == CAMP.EVIL then
        UIHelper.SetString(self.LabelSide, "恶人谷侠士")
        UIHelper.SetSpriteFrame(self.ImgSide, "UIAtlas2_Faction_ChampionshipPop_Bg_ERen")
    else
        UIHelper.SetVisible(self.LabelSide, false)
        UIHelper.SetVisible(self.ImgSide, false)
    end

    local tRank2Img = {
        [4] = "UIAtlas2_Faction_ChampionshipPop_RankLabel_LeagueNoticeInner_6",
        [8] = "UIAtlas2_Faction_ChampionshipPop_RankLabel_LeagueNoticeInner_8",
        [16] = "UIAtlas2_Faction_ChampionshipPop_RankLabel_LeagueNoticeInner_2",
        [32] = "UIAtlas2_Faction_ChampionshipPop_RankLabel_LeagueNoticeInner_3",
        [64] = "UIAtlas2_Faction_ChampionshipPop_RankLabel_LeagueNoticeInner_4",
    }
    if tRank2Img[self.nRank] then
        UIHelper.SetSpriteFrame(self.ImgNum, tRank2Img[self.nRank])
    end
end

return UILeagueNote