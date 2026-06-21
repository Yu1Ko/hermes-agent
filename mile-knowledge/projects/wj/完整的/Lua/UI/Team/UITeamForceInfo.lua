-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamForceInfo
-- Date: 2023-02-20 20:09:19
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITeamForceInfo = class("UITeamForceInfo")

function UITeamForceInfo:OnEnter(dwApplyID, szRoomID, tbForceInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwApplyID = dwApplyID
    self.szRoomID = szRoomID
    self.tbForceInfo = tbForceInfo
    self:UpdateInfo()
end

function UITeamForceInfo:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITeamForceInfo:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnApply, EventType.OnClick, function ()
        if self.szRoomID then
            local tbAllRecruitList = TeamBuilding.GetAllSwitchServerList()
            for k, tbRecruitInfo in ipairs(tbAllRecruitList) do
                if tbRecruitInfo["szRoomID"] == self.szRoomID then
                    TeamBuilding.ApplyTeam(tbRecruitInfo)
                    return
                end
            end
        else
            local tbAllRecruitList = TeamBuilding.GetAllRecruitList()
            for k, tbRecruitInfo in ipairs(tbAllRecruitList) do
                if tbRecruitInfo["dwRoleID"] == self.dwApplyID then
                    TeamBuilding.ApplyTeam(tbRecruitInfo)
                    return
                end
            end
        end

    end)
end

function UITeamForceInfo:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITeamForceInfo:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamForceInfo:UpdateInfo()
    UIHelper.SetString(self.LabelTitle, "队伍配置(" .. #self.tbForceInfo.. ")")
    local tbResult = {}
    LOG.TABLE(self.tbForceInfo)
    for k, v in ipairs(self.tbForceInfo) do
        if not tbResult[v] then
            tbResult[v] = 0
        end
        tbResult[v] = tbResult[v] + 1
    end
    for k, v in pairs(tbResult) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetTeamXinfaListCell, self.ScrollViewXinfaList, k, v)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewXinfaList)
    UIHelper.ScrollToTop(self.ScrollViewXinfaList, 0)
end


return UITeamForceInfo