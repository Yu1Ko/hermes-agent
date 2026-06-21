-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRoadChivalrousCellLine
-- Date: 2023-04-06 17:46:24
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIRoadChivalrousCellLine = class("UIRoadChivalrousCellLine")

function UIRoadChivalrousCellLine:OnEnter(nSubModuleID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nSubModuleID = nSubModuleID
    self:UpdateInfo()
end

function UIRoadChivalrousCellLine:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRoadChivalrousCellLine:BindUIEvent()
    
end

function UIRoadChivalrousCellLine:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRoadChivalrousCellLine:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRoadChivalrousCellLine:UpdateInfo()
    local nState = RoadChivalrousData.GetSubModuleState(self.nSubModuleID)
    UIHelper.SetVisible(self.LineB, nState ~= ROAD_CHIVALROUS_SUBMODULE_STATE.INACTIVATED)
    UIHelper.SetVisible(self.LineD, nState == ROAD_CHIVALROUS_SUBMODULE_STATE.INACTIVATED)
end


return UIRoadChivalrousCellLine