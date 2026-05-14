-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaMainCityTeamPageCell
-- Date: 2022-12-30 15:10:54
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaMainCityTeamPageCell = class("UIArenaMainCityTeamPageCell")

function UIArenaMainCityTeamPageCell:OnEnter(nArenaType, tbInfo)
    self.nArenaType = nArenaType
    self.tbInfo = tbInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIArenaMainCityTeamPageCell:OnExit()
    self.bInit = false
end

function UIArenaMainCityTeamPageCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelPvPTeamAddPlayer, self.nArenaType)
    end)
end

function UIArenaMainCityTeamPageCell:RegEvent()
    Event.Reg(self, EventType.OnArenaStateUpdate, function(nPlayerID)
        self:UpdateInfo()
    end)
end

function UIArenaMainCityTeamPageCell:UpdateInfo()
    if self.tbInfo then
        UIHelper.SetVisible(self.BtnAdd, false)
        UIHelper.SetVisible(self.WidgetPlayer, true)

        UIHelper.SetVisible(self.ImgCaptainIcon, self.tbInfo.bLeader)

        UIHelper.SetString(self.LabelPlayerName, UIHelper.GBKToUTF8(self.tbInfo.szPlayerName or ""), 6)
        UIHelper.SetString(self.LabelScoreNum, tostring(self.tbInfo.nMatchingLevel or 0))

	    local szLevel = Conversion2ChineseNumber(self.tbInfo.nArenaLevel or 0)
        if self.nArenaType == ARENA_UI_TYPE.ARENA_MASTER_3V3 then
            UIHelper.SetString(self.LabelGrade, "")
        else
            UIHelper.SetString(self.LabelGrade, string.format("%s段", szLevel))
        end

        UIHelper.SetString(self.LabelSessionNum, string.format("%d场", self.tbInfo.dwSeasonTotalCount or 0))
        UIHelper.SetString(self.LabelStandingsNum, string.format("%d胜-%d负", self.tbInfo.dwSeasonWinCount or 0, self.tbInfo.dwSeasonTotalCount - self.tbInfo.dwSeasonWinCount))

        UIHelper.SetSpriteFrame(self.ImgSchoolIcon, PlayerForceID2SchoolImg2[self.tbInfo.dwForceID])

        self.scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead, self.tbInfo.dwPlayerID)
        if not GetPlayer(self.tbInfo.dwPlayerID) then
            self.scriptHead:SetHeadWithForceID(self.tbInfo.dwForceID)
        end
        self.scriptHead:SetClickCallback(function()
            if self.tbInfo.dwPlayerID ~= PlayerData.GetPlayerID() then
                TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetJJCTeammate, self.WidgetHead, TipsLayoutDir.RIGHT_CENTER, self.nArenaType, self.tbInfo)
            end
        end)
    else
        UIHelper.SetVisible(self.BtnAdd, true)
        UIHelper.SetVisible(self.WidgetPlayer, false)
    end
end


return UIArenaMainCityTeamPageCell