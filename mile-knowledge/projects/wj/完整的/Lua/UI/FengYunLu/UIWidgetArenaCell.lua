-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetPvPCampRewardListNormal
-- Date: 2023-03-02 19:49:15
-- Desc: WidgetPvPCampRewardListAttribute、WidgetPvPCampRewardListEquip
-- ---------------------------------------------------------------------------------

---@class UIWidgetArenaCell
local UIWidgetArenaCell = class("UIWidgetArenaCell")

function UIWidgetArenaCell:OnEnter(tArgs)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.nRankLevel = tArgs.nRankLevel
        self.tInfo = tArgs.tInfo
        
        UIHelper.SetSwallowTouches(self.BtnList,false)
    end

    self:UpdateInfo()
end

function UIWidgetArenaCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetArenaCell:BindUIEvent()
end

function UIWidgetArenaCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetArenaCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

local nRankToBg = {
    [1] = "UIAtlas2_FengYunLu_Rank_img_ranking_bg01.png",
    [2] = "UIAtlas2_FengYunLu_Rank_img_ranking_bg02.png",
    [3] = "UIAtlas2_FengYunLu_Rank_img_ranking_bg03.png",
}

local nRankToRankIcon = {
    [1] = "UIAtlas2_FengYunLu_Rank_icon_ranking01.png",
    [2] = "UIAtlas2_FengYunLu_Rank_icon_ranking02.png",
    [3] = "UIAtlas2_FengYunLu_Rank_icon_ranking03.png",
}

function UIWidgetArenaCell:UpdateInfo()
    if self.nRankLevel <= 3 then
        UIHelper.SetVisible(self.ImgRankNum, false)
        UIHelper.SetVisible(self.ImgRankIcon, true)

        UIHelper.SetSpriteFrame(self.ImgRankBg, nRankToBg[self.nRankLevel])
        UIHelper.SetSpriteFrame(self.ImgRankIcon, nRankToRankIcon[self.nRankLevel])
    else
        UIHelper.SetVisible(self.ImgRankIcon, false)
        UIHelper.SetVisible(self.ImgRankNum, true)

        UIHelper.SetString(self.ImgRankNum,
                self.nRankLevel ~= 0 and self.nRankLevel or "--")

        local path = "UIAtlas2_FengYunLu_Rank_img_ranking_bg04.png"
        UIHelper.SetSpriteFrame(self.ImgRankBg, path)
    end

    if self.tInfo then
        local tInfo = self.tInfo
        local szTip = FormatString(g_tStrings.STR_ARENA_V_L, tInfo.dwSeasonWinCount, tInfo.dwSeasonTotalCount - tInfo.dwSeasonWinCount)
        UIHelper.SetString(self.LabelPlayerName, UIHelper.GBKToUTF8(tInfo.szCorpsName))
        UIHelper.SetString(self.LabelVictoeyDefeat, szTip)
        UIHelper.SetString(self.LabelTeamScore, tInfo.nCorpsLevel)

        UIHelper.BindUIEvent(self.BtnTeamConfigiration, EventType.OnClick, function()
            UIMgr.Open(VIEW_ID.PanelFengYunLuTeamConfigirationPop, tInfo.dwCorpsID)
        end)
    end
end

return UIWidgetArenaCell