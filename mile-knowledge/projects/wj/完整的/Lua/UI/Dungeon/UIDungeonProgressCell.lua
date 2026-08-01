local UIDungeonProgressCell = class("UIDungeonProgressCell")

function UIDungeonProgressCell:OnEnter(dwMapID, dwPlayerID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    ApplyDungeonRoleProgress(dwMapID, dwPlayerID)
    self.dwMapID = dwMapID
    self.dwPlayerID = dwPlayerID
    self:UpdateInfo(dwPlayerID)
end

function UIDungeonProgressCell:OnExit()
    self.bInit = false
end

function UIDungeonProgressCell:BindUIEvent()
end

function UIDungeonProgressCell:RegEvent()
    Event.Reg(self, "UPDATE_DUNGEON_ROLE_PROGRESS", function ()
        self:UpdateBossProgress()
    end)

    Event.Reg(self, "TEAM_AUTHORITY_CHANGED", function()
        local clientTeam = GetClientTeam()
        if not clientTeam then return end

        if arg0 == TEAM_AUTHORITY_TYPE.LEADER then
            local bLeader = clientTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) == self.dwPlayerID
            UIHelper.SetVisible(self.WidgetLeader, bLeader)
        end
    end)

    Event.Reg(self, "PARTY_SET_MEMBER_ONLINE_FLAG", function()
        self:UpdateInfo(self.dwPlayerID)
    end)
end

function UIDungeonProgressCell:UpdateInfo(dwPlayerID)
    local clientTeam = GetClientTeam()
    if not clientTeam then return end

    local tMemberInfo = TeamData.GetMemberInfo(dwPlayerID, clientTeam)
    if not tMemberInfo then return end

    local bLeader = clientTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) == dwPlayerID
    UIHelper.SetVisible(self.WidgetLeader, bLeader)

    local szName = UIHelper.GBKToUTF8(tMemberInfo.szName)
    UIHelper.SetString(self.LabelName, szName)

    local szSchool = PlayerForceID2SchoolImg2[tMemberInfo.dwForceID]
    UIHelper.SetSpriteFrame(self.ImgSchool, szSchool)

    CampData.SetUICampImg(self.ImgCamp, tMemberInfo.nCamp, nil, true)
    UIHelper.LayoutDoLayout(self.LayoutName)

    UIHelper.SetString(self.LabelLevel, tMemberInfo.nLevel .. g_tStrings.STR_LEVEL)

    local bOffline = not tMemberInfo.bIsOnLine
    UIHelper.SetVisible(self.LabelStatus, bOffline)

    UIHelper.SetString(self.LabelEquipScore, string.format("装分%d", tMemberInfo.nEquipScore))
    UIHelper.LayoutDoLayout(self.LabelEquipScore)
    self:UpdateBossProgress()
end

function UIDungeonProgressCell:UpdateBossProgress()
    local _,_,_,_,_,_,_,bIsDungeonRoleProgressMap = GetMapParams(self.dwMapID)
    if bIsDungeonRoleProgressMap then
        local aProgressIDs = {}
        local aBossProcessInfoList = Table_GetCDProcessBoss(self.dwMapID)
        for j = 1, #aBossProcessInfoList do
            table.insert(aProgressIDs, aBossProcessInfoList[j].dwProgressID)
        end
        self:RefreshKillBossProgress(self.dwMapID, self.dwPlayerID, aProgressIDs)
    end
end

function UIDungeonProgressCell:RefreshKillBossProgress(dwMapID, dwPlayerID, aProgressIDs)
    for nIndex, imgPoint in ipairs(self.ImgPoints) do
        local nodeParent = UIHelper.GetParent(imgPoint)
        UIHelper.SetVisible(nodeParent, false)
    end
    for i = 1, #aProgressIDs do
		local nProgressID = aProgressIDs[i]
		local bHasKilled = GetDungeonRoleProgress(dwMapID, dwPlayerID, nProgressID)
        local nodeParent = UIHelper.GetParent(self.ImgPoints[i])
        UIHelper.SetVisible(nodeParent, true)
        UIHelper.SetVisible(self.ImgPoints[i], bHasKilled)
        UIHelper.SetVisible(self.ImgUnkilledPoints[i], not bHasKilled)
	end
    UIHelper.LayoutDoLayout(self.WidgetPoints)
end

return UIDungeonProgressCell