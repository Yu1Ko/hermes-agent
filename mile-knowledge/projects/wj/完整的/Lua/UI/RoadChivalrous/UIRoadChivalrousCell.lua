-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRoadChivalrousCell
-- Date: 2023-04-06 16:44:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIRoadChivalrousCell = class("UIRoadChivalrousCell")

function UIRoadChivalrousCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIRoadChivalrousCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRoadChivalrousCell:Init(tbSubModuleID)
    self.tbSubModuleID = tbSubModuleID
    self:UpdateInfo()
end 

function UIRoadChivalrousCell:BindUIEvent()
    
end

function UIRoadChivalrousCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRoadChivalrousCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRoadChivalrousCell:UpdateInfo()
    for index, button in ipairs(self.tbButton) do
        local nSubModuleID = self.tbSubModuleID[index]
        local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetKnotSingleCell, button, nSubModuleID)
        -- scriptView:OnEnter(nSubModuleID)
    end

    for index, line in ipairs(self.tbLine) do
        local nSubModuleID = self.tbSubModuleID[index] 
        local scriptView = UIHelper.GetBindScript(line)
        scriptView:OnEnter(nSubModuleID)
    end
end

function UIRoadChivalrousCell:GetNodeCount()
    return #self.tbButton
end

return UIRoadChivalrousCell