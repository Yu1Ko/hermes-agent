-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamTargetMark
-- Date: 2023-08-17 16:41:21
-- Desc: ?
-- ---------------------------------------------------------------------------------

local TOGGLE_MARK_TYPE = {
    [1] = 1,
    [2] = 5,
    [3] = 3,
    [4] = 6,
    [5] = 9,
    [6] = 8,
    [7] = 10,
    [8] = 2,
    [9] = 4,
    [10] = 7,
    [11] = 0,
}

local UITeamTargetMark = class("UITeamTargetMark")

function UITeamTargetMark:OnEnter(dwCharacterID, fnClose)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwCharacterID = dwCharacterID
    self.fnClose = fnClose

    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroup)
    for _, tog in ipairs(self.tTogMark) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroup, tog)
        UIHelper.SetTouchDownHideTips(tog, false)
    end
    self:UpdateInfo()
end

function UITeamTargetMark:OnExit()
    self.bInit = false
    self:UnRegEvent()

    if self.fnClose then
        self.fnClose()
    end
end

function UITeamTargetMark:BindUIEvent()
    for index, tog in ipairs(self.tTogMark) do
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(_, bSelected)
            if bSelected then
                local nMarkType = TOGGLE_MARK_TYPE[index]
                GetClientTeam().SetTeamMark(nMarkType, self.dwCharacterID)
            end
        end)
    end
end

function UITeamTargetMark:RegEvent()
    Event.Reg(self, "PARTY_SET_MARK", function()
        self:UpdateInfo()
    end)
end

function UITeamTargetMark:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamTargetMark:UpdateInfo()
    local tTeamMark = GetClientTeam().GetTeamMark()
    local nMyMark = tTeamMark[self.dwCharacterID] or 0
    for index, tog in ipairs(self.tTogMark) do
        local nMarkType = TOGGLE_MARK_TYPE[index]
        if nMyMark == nMarkType then
            UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, tog)
        end
    end
end


return UITeamTargetMark