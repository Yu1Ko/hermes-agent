-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaMasterMainInfo
-- Date: 2025-02-10 10:16:49
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaMasterMainInfo = class("UIArenaMasterMainInfo")

function UIArenaMasterMainInfo:OnEnter(nPlayerID, nArenaType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nPlayerID = nPlayerID
    self.nArenaType = nArenaType
    self:UpdateInfo()
end

function UIArenaMasterMainInfo:OnExit()
    self.bInit = false
end

function UIArenaMasterMainInfo:BindUIEvent()

end

function UIArenaMasterMainInfo:RegEvent()
    Event.Reg(self, EventType.OnArenaStateUpdate, function(nPlayerID)
        self:UpdateInfo()
    end)
end
function UIArenaMasterMainInfo:UpdateInfo()
    local nPlayerID = self.nPlayerID
    local nArenaType = self.nArenaType

    local nPassTime, nAvgQueueTime, nQueueArenaType = ArenaData.GetQueueTime()
    if nQueueArenaType ~= ARENA_UI_TYPE.ARENA_PRACTICE then
        if self.nMatchingTimerID then
            Timer.DelTimer(self, self.nMatchingTimerID)
            self.nMatchingTimerID = nil
        end
        self.nMatchingTimerID = Timer.AddCycle(self, 0.5, function()
            local nPassTime, nAvgQueueTime, nQueueArenaType = ArenaData.GetQueueTime()
            if nQueueArenaType ~= ARENA_UI_TYPE.ARENA_2V2 and
                nQueueArenaType ~= ARENA_UI_TYPE.ARENA_3V3 and
                nQueueArenaType ~= ARENA_UI_TYPE.ARENA_5V5 then
                if self.nMatchingTimerID then
                    UIHelper.SetString(self.LabelMatchingTime, "已匹配 0秒  预计排队 0秒")
                    UIHelper.SetVisible(self.LabelMatchingTime, false)
                    Timer.DelTimer(self, self.nMatchingTimerID)
                    self.nMatchingTimerID = nil
                end
                return
            end
            UIHelper.SetString(self.LabelMatchingTime, string.format("已匹配 %s  预计排队 %s", ArenaData.FormatArenaTime(nPassTime), ArenaData.FormatArenaTime(nAvgQueueTime)))
        end)
    end

    local nArenaLevel = ArenaData.GetArenaLevel(nPlayerID, nArenaType)
    local tbArenaInfo = ArenaData.GetCorpsRoleInfo(nPlayerID, nArenaType)
    local nTeamScore = ArenaData.GetCorpsLevel(nPlayerID, nArenaType)
    local nLeftDoubleCount, nMaxDoubleCount = ArenaData.GetDoubleRewardInfo(nArenaType)
    local nScore = tbArenaInfo.nMatchLevel or 1000

    UIHelper.SetString(self.LabelPersonageScore, nScore)

    local nPlacementCount = GetArenaPlacementNumber()
    if tbArenaInfo.dwSeasonTotalCount and tbArenaInfo.dwSeasonTotalCount < nPlacementCount then
        UIHelper.SetString(self.LabelTeamScore, "定级中")
    else
        UIHelper.SetString(self.LabelTeamScore, nTeamScore)
    end
    UIHelper.SetString(self.LabelDssMatchCount, string.format("%d", tbArenaInfo.dwSeasonTotalCount or 0))

    local nWinCount = tbArenaInfo.dwSeasonWinCount or 0
    local nTotalCount = tbArenaInfo.dwSeasonTotalCount or 0
    UIHelper.SetString(self.LabelDssTeamVictory, string.format("%d", nWinCount))
    UIHelper.SetString(self.LabelDssTeamDefeat, string.format("%d", nTotalCount - nWinCount))
    UIHelper.LayoutDoLayout(self.LayoutDssTeamMatchDetail)

    nWinCount = 0
    nTotalCount = 0
    local tbMemberData = ArenaData.tbCorpsMemberInfo[nArenaType] or {}
    for k, v in ipairs(tbMemberData) do
        if v.dwPlayerID == nPlayerID then
            nWinCount = v.dwSeasonWinCount
            nTotalCount = v.dwSeasonTotalCount
            break
        end
    end
    UIHelper.SetString(self.LabelDssPersonVictory, string.format("%d", nWinCount))
    UIHelper.SetString(self.LabelDssPersonDefeat, string.format("%d", nTotalCount - nWinCount))
    UIHelper.LayoutDoLayout(self.LayoutDssPersonMatchDetail)

    local nCorpsID = ArenaData.GetCorpsID(nArenaType, nPlayerID)
    local bEmpty = not nCorpsID or nCorpsID <= 0
    if bEmpty then
        UIHelper.SetString(self.LabelDssTeamName, "海选赛队伍名")
    else
        local tbTeamData = ArenaData.tbCorpsInfo[nArenaType] or {}
        UIHelper.SetString(self.LabelDssTeamName, UIHelper.GBKToUTF8(tbTeamData.szCorpsName))
    end
    UIHelper.SetVisible(self.WidgetDssTeamMatchDetail, not bEmpty)
    UIHelper.SetVisible(self.WidgetDssPersonMatchDetail, not bEmpty)
    UIHelper.LayoutDoLayout(self.WidgetDssMessage)

    local bIsInWarning = self:IsInWarning(tbArenaInfo.dwWeekTotalCount or 0)
    UIHelper.SetVisible(self.BtnHelpRule, bIsInWarning)
    self:UpdateWeekTotalInfo(self.tbImgDoubleSchedule, nLeftDoubleCount)
end

function UIArenaMasterMainInfo:UpdateWeekTotalInfo(tbImg, nTotalCount)
    for i, img in ipairs(tbImg) do
        if i <= #tbImg - (nTotalCount or 0) then
            UIHelper.SetSpriteFrame(img, "UIAtlas2_Pvp_PvpEntrance_Img_Double1.png")
        else
            UIHelper.SetSpriteFrame(img, "UIAtlas2_Pvp_PvpEntrance_Img_Double2.png")
        end
    end
end

function UIArenaMasterMainInfo:IsInWarning(nCount)
    --本周场次小于10
	return nCount < 10
end


return UIArenaMasterMainInfo