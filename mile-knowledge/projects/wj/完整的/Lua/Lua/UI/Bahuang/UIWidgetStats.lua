-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetStats
-- Date: 2024-01-01 19:33:30
-- Desc: 战绩
-- ---------------------------------------------------------------------------------

local UIWidgetStats = class("UIWidgetStats")

function UIWidgetStats:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIWidgetStats:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetStats:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnRecord, EventType.OnClick, function()
        if not UIMgr.IsViewOpened(VIEW_ID.PanelBahuangResult, false) then
            UIMgr.Open(VIEW_ID.PanelBahuangResult, BahuangData.GetLastGameData(), true)
        end
    end)
end

function UIWidgetStats:RegEvent()
    Event.Reg(self, EventType.OnLastGameDataUpdate, function()
        self:UpdateBtnState()
    end)
end

function UIWidgetStats:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetStats:UpdateInfo()
    local tbTotalData = BahuangData.GetTotalDataInfo()
    UIHelper.SetString(self.LabelDataCellDetail1, tbTotalData.nPlayNum)

    UIHelper.SetString(self.LabelDataCellDetail2, tbTotalData.nSoloClear)
    UIHelper.SetString(self.LabelDataCellDetail3, tbTotalData.nTeamClear)
    UIHelper.SetString(self.LabelDataCellDetail4, tbTotalData.nKillNum)
    UIHelper.SetString(self.LabelDataCellDetail5, tbTotalData.nBossNum)
    UIHelper.SetString(self.LabelDataCellDetail6, tbTotalData.nAltarNum)
    UIHelper.SetString(self.LabelDataCellDetail7, tbTotalData.nSceneChest)
    UIHelper.SetString(self.LabelDataCellDetail8, tbTotalData.nGainNum)

    self:UpdateBtnState()
end

function UIWidgetStats:UpdateBtnState()
    local nState = BahuangData.IsNeverPlayedGame() and BTN_STATE.Disable or BTN_STATE.Normal
    UIHelper.SetButtonState(self.BtnRecord, nState)
end


return UIWidgetStats