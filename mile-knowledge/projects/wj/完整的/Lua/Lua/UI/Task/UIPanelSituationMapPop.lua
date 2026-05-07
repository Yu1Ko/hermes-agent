-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelSituationMapPop
-- Date: 2024-01-12 16:16:43
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelSituationMapPop = class("UIPanelSituationMapPop")

function UIPanelSituationMapPop:OnEnter(nID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nID = nID 
    self.tbSituationMapInfo = Table_GetSituationMapInfoById(nID)
    self:UpdateInfo()
end

function UIPanelSituationMapPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelSituationMapPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPanelSituationMapPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelSituationMapPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelSituationMapPop:UpdateInfo()
    local tbSituationMapInfo = self.tbSituationMapInfo
    local bLankeShan = tbSituationMapInfo.szIniPath == "\\ui\\Config\\Default\\SituationMap\\Lankeshan.ini"
    UIHelper.SetVisible(self.WidgetSituationLankeshan, bLankeShan)
end


return UIPanelSituationMapPop