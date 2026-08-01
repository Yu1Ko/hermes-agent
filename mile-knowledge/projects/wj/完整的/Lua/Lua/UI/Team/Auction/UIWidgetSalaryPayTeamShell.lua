-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSalaryPayTeamShell
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetSalaryPayTeamShell = class("UIWidgetSalaryPayTeamShell")

function UIWidgetSalaryPayTeamShell:OnEnter(nGroupID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    
    self.nGroupID = nGroupID
    self:UpdateInfo(nGroupID)
end

function UIWidgetSalaryPayTeamShell:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIWidgetSalaryPayTeamShell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogMulti, EventType.OnClick, function ()
        self:SelelctAll()
    end)
end

function UIWidgetSalaryPayTeamShell:RegEvent()
    Event.Reg(self, EventType.OnSalaryDispatched, function ()
        self:UpdateInfo(self.nGroupID)
        --UIHelper.SetSelected(self.TogMulti, false)
    end)

    Event.Reg(self, "TEAM_AUTHORITY_CHANGED", function (nAuthorityType)
        if nAuthorityType == TEAM_AUTHORITY_TYPE.DISTRIBUTE then
            UIHelper.SetVisible(self.TogMulti, AuctionData.IsDistributeMan())
        end
    end)

    Event.Reg(self, EventType.OnSalaryDataChanged, function ()
        self:UpdateInfo(self.nGroupID)
    end)
end

function UIWidgetSalaryPayTeamShell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSalaryPayTeamShell:UpdateInfo(nGroupID)
    local clientTeam = GetClientTeam()
    local tMemberInfoList = AuctionData.GetTeamGroupList(nGroupID)
	local tConsume = AuctionData.GetAllPlayerConsumeData()
    self.tScriptList = {}
    UIHelper.RemoveAllChildren(self.LayoutPlayerList)
    local bAllSelected = true
    for _, dwGID in ipairs(tMemberInfoList) do
        local tMemberInfo = AuctionData.GetPlayerInfo(dwGID)
        local tData = {
            dwGID = dwGID,
            dwPlayerID = dwGID,
            tMemberInfo = tMemberInfo,
            nConsumeGolds = tConsume[dwGID] or 0
        }
        if RoomData.IsInGlobalRoomDungeon() then tData.dwPlayerID = RoomData.GetTeamPlayerIDByGlobalID(dwGID) or 0 end
        tData.nConsumeGolds = tConsume[tData.dwPlayerID] or 0
        bAllSelected = bAllSelected and AuctionData.tCheckTeamers[dwGID]
        local scriptMember = UIHelper.AddPrefab(PREFAB_ID.WidgetSalaryPayPlayerItem, self.LayoutPlayerList)
        scriptMember:OnEnter(tData)
        table.insert(self.tScriptList, scriptMember)
    end
    self.bAllSelected = bAllSelected
    UIHelper.SetSelected(self.TogMulti, bAllSelected)

    UIHelper.SetVisible(self.TogMulti, AuctionData.IsDistributeMan())

    local szGroupName = g_tStrings.STR_TEAM .. UIHelper.NumberToChinese(nGroupID+1)
    UIHelper.SetString(self.LabelTeamName, szGroupName)
end

function UIWidgetSalaryPayTeamShell:SelelctAll()
    local bSelected = UIHelper.GetSelected(self.TogMulti)
    for _, scriptMember in ipairs(self.tScriptList) do
        scriptMember:SetSelected(bSelected)
    end
    Event.Dispatch(EventType.OnSalaryDataChanged)
end

return UIWidgetSalaryPayTeamShell