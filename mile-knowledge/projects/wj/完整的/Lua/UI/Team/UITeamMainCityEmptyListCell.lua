-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamMainCityEmptyListCell
-- Date: 2023-03-02 11:01:35
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITeamMainCityEmptyListCell = class("UITeamMainCityEmptyListCell")

function UITeamMainCityEmptyListCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UITeamMainCityEmptyListCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UITeamMainCityEmptyListCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnTeamPlayerEmpty, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelTeam)
    end)
end

function UITeamMainCityEmptyListCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITeamMainCityEmptyListCell:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamMainCityEmptyListCell:UpdateInfo()
    
end

return UITeamMainCityEmptyListCell