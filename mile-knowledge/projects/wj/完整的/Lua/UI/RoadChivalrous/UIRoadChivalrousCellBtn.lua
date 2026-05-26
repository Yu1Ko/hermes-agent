-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRoadChivalrousCellBtn
-- Date: 2023-04-06 17:12:10
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIRoadChivalrousCellBtn = class("UIRoadChivalrousCellBtn")

function UIRoadChivalrousCellBtn:OnEnter(nSubModuleID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nSubModuleID = nSubModuleID
    self:UpdateInfo()
end

function UIRoadChivalrousCellBtn:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRoadChivalrousCellBtn:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnNodeMiddle, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelRoadChivalrousRightPop, self.nSubModuleID)
    end)
end

function UIRoadChivalrousCellBtn:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRoadChivalrousCellBtn:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRoadChivalrousCellBtn:UpdateInfo()
    local nState = RoadChivalrousData.GetSubModuleState(self.nSubModuleID)
    UIHelper.SetVisible(self.WidgetIncompleted, nState == ROAD_CHIVALROUS_SUBMODULE_STATE.INCOMPLETED)
    UIHelper.SetVisible(self.WidgetNotGetReward, nState == ROAD_CHIVALROUS_SUBMODULE_STATE.COMPLETED_NOT_GOT_REWARDS)
    UIHelper.SetVisible(self.WidgetInactivated, nState == ROAD_CHIVALROUS_SUBMODULE_STATE.INACTIVATED)
    UIHelper.SetVisible(self.WidgetGotReward, nState == ROAD_CHIVALROUS_SUBMODULE_STATE.COMPLETED_GOT_REWARDS)
    UIHelper.SetVisible(self.LabelNode03, not nState == ROAD_CHIVALROUS_SUBMODULE_STATE.COMPLETED_NOT_GOT_REWARDS)

    local szNodeName = RoadChivalrousData.GetSubModuleName(self.nSubModuleID)
    szNodeName = UIHelper.GBKToUTF8(szNodeName)
    UIHelper.SetString(self.LabelNode01, szNodeName)
    UIHelper.SetString(self.LabelNode02, szNodeName)
    UIHelper.SetString(self.LabelNode03, szNodeName)
    UIHelper.SetString(self.LabelNode04, szNodeName)

    local tbImage = UIRoadChivalrousTab[self.nSubModuleID]

    UIHelper.SetSpriteFrame(self.ImgNodeBgInCompleted, tbImage.NormalPath)
    UIHelper.SetSpriteFrame(self.ImgNodeBgInactivated, tbImage.InActivePath)
    UIHelper.SetSpriteFrame(self.ImgNodeBgNotGetReward, tbImage.NotRewardPath)
    UIHelper.SetSpriteFrame(self.ImgNodeBgGotReward, tbImage.GotRewardPath)
end


return UIRoadChivalrousCellBtn