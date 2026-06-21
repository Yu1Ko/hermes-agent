-- ---------------------------------------------------------------------------------
-- Author: jiayuran
-- Name: UIWidgetFengYunLuDesignationPanel
-- ---------------------------------------------------------------------------------

---@class UIFengYunLuTeamConfigurationPanel
local UIFengYunLuTeamConfigurationPanel = class("UIFengYunLuTeamConfigurationPanel")

function UIFengYunLuTeamConfigurationPanel:OnEnter(dwCorpsID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.dwCorpsID = dwCorpsID
    end
    self:UpdateInfo()
end

function UIFengYunLuTeamConfigurationPanel:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFengYunLuTeamConfigurationPanel:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIFengYunLuTeamConfigurationPanel:RegEvent()
    Event.Reg(self, "SYNC_CORPS_MEMBER_DATA", function()
        self:UpdateInfo()
    end)
end

function UIFengYunLuTeamConfigurationPanel:UnRegEvent()
    Event.UnRegAll(self)
end

local nSyncCorpsMemTime = nil
local function GetMemberInfo(dwCorpsID, bMaster)
    local bRank = not bMaster
    local tMember = GetCorpsMemberInfo(dwCorpsID, bRank)
    if not tMember then
        local bCoolDown = (not SyncCorpsMemberData(dwCorpsID, bRank, GetClientPlayer().dwID))

        local nCurrentTime = GetCurrentTime()
        if bCoolDown then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_SYNC_MEMBER_INFO)
            OutputMessage("MSG_SYS", g_tStrings.STR_SYNC_MEMBER_INFO .. "\n")
        end

        if bCoolDown and (not nSyncCorpsMemTime or nCurrentTime > nSyncCorpsMemTime) then
            nSyncCorpsMemTime = GetCurrentTime() + 15
        end
        return
    end
    return tMember
end

function UIFengYunLuTeamConfigurationPanel:UpdateInfo()
    local tMembers = GetMemberInfo(self.dwCorpsID, true) or {}
    LOG.TABLE(tMembers)
    for i = 1, 5 do
        local tMemberInfo = tMembers[i]
        if tMemberInfo == nil then
            return
        end

        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetFengYunLuTeamConfigirationCell, self.LayoutContent)

        UIHelper.SetString(script.LabelPlayerName, UIHelper.GBKToUTF8(tMemberInfo.szPlayerName))
        UIHelper.SetString(script.LabelSession, tMemberInfo.dwSeasonTotalCount)

        local dwSeasonLostCount = tMemberInfo.dwSeasonTotalCount - tMemberInfo.dwSeasonWinCount
        UIHelper.SetString(script.LabelVictoeyDefeat, string.format("%d-%d", tMemberInfo.dwSeasonWinCount, dwSeasonLostCount))
        UIHelper.SetString(script.LabelScore, tMemberInfo.nGrowupLevel)

        UIHelper.SetSpriteFrame(script.LabelSchool, PlayerForceID2SchoolImg2[tMemberInfo.dwForceID])
    end

    UIHelper.LayoutDoLayout(self.LayoutContent)
end

return UIFengYunLuTeamConfigurationPanel