local UIDungeonProgressPop = class("UIDungeonProgressPop")

function UIDungeonProgressPop:OnEnter(dwMapID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.dwMapID = dwMapID
    self:UpdateInfo()
end

function UIDungeonProgressPop:OnExit()
    self.bInit = false
end

function UIDungeonProgressPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
		UIMgr.Close(self)
	end)
end

function UIDungeonProgressPop:RegEvent()
    Event.Reg(self, "PARTY_ADD_MEMBER", function(dwPlayerID)
        Timer.AddFrame(self, 1, function ()
            self:UpdateInfo()
        end)
    end)

    Event.Reg(AuctionData, "PARTY_DELETE_MEMBER", function(dwPlayerID)
        Timer.AddFrame(self, 1, function ()
            self:UpdateInfo()
        end)
    end)
end

function UIDungeonProgressPop:UpdateInfo()
    local tDungeonInfo = Table_GetDungeonInfo(self.dwMapID)
    if not tDungeonInfo then return end

    local clientTeam = GetClientTeam()
    if not clientTeam then return end

    local szLayer3Name = UIHelper.GBKToUTF8(tDungeonInfo.szLayer3Name)
    local szMapName = UIHelper.GBKToUTF8(tDungeonInfo.szOtherName)
    UIHelper.SetString(self.LabelTargetName, szLayer3Name..szMapName)

    UIHelper.RemoveAllChildren(self.LayoutRoommateList)
    local tMemberInfoList = {}
    local nGroupNum = AuctionData.GetTeamGroupNum()
	for nGroupID = 0, nGroupNum - 1 do
        local tInfoList = AuctionData.GetTeamGroupList(nGroupID)
        table.insert_tab(tMemberInfoList, tInfoList)
	end

    table.sort(tMemberInfoList, function (dwID1, dwID2)
        local tInfo1 = TeamData.GetMemberInfo(dwID1, clientTeam)
        local tInfo2 = TeamData.GetMemberInfo(dwID2, clientTeam)
        return tInfo1.nEquipScore > tInfo2.nEquipScore
    end)

    for i, dwID in ipairs(tMemberInfoList) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetlDungeonProgressCell, self.ScrollViewRoommateList, self.dwMapID, dwID)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRoommateList)
end

return UIDungeonProgressPop