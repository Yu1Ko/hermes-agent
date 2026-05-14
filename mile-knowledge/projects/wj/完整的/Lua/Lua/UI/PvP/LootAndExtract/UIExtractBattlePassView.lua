-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIExtractBattlePassView
-- Date: 2025-03-31 19:23:30
-- Desc: ?
-- ---------------------------------------------------------------------------------
local MAX_LEVEL = 60
local UIExtractBattlePassView = class("UIExtractBattlePassView")

function UIExtractBattlePassView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIExtractBattlePassView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIExtractBattlePassView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnGet, EventType.OnClick, function(btn)
        RemoteCallToServer("On_JueJing_GetSeasonLvReward", self.nCurLevel)
    end)
end

function UIExtractBattlePassView:RegEvent()
    Event.Reg(self, EventType.OnTBFUpdateAllView, function ()
        self:UpdateInfo()
        Event.Dispatch(EventType.OnUpdateExtractRewardRedPoint)
    end)
end

function UIExtractBattlePassView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIExtractBattlePassView:UpdateInfo()
    local tbInfo = GDAPI_TbfWareSeasonLvInfo()
    if not tbInfo then
        return
    end
    local nGotLv = tbInfo.nGotLv
    local nCurLevel = tbInfo.nCurLv
    local nServerLv = tbInfo.nServerLv
    local nPercent = tbInfo.nCurExp / tbInfo.nLvUpExp * 100
    local tRewardList = tbInfo.tRewardList
    self.nCurLevel = nCurLevel

    self:UpdateItemList(tRewardList, nGotLv, nCurLevel)
    UIHelper.SetString(self.LabslGradeNum, nCurLevel)
    UIHelper.SetString(self.LabslUnlockLevel, nCurLevel.."/"..nServerLv)
    UIHelper.SetString(self.LabelExperienceNum, tbInfo.nCurExp.."/"..tbInfo.nLvUpExp)
    UIHelper.SetButtonState(self.BtnGet, nGotLv < nCurLevel and BTN_STATE.Normal or BTN_STATE.Disable, nil, true)
    UIHelper.SetProgressBarPercent(self.ProgressBarGradeProgress, nPercent)
end

function UIExtractBattlePassView:UpdateItemList(tRewardList, nGotLv, nCurLevel)
    UIHelper.RemoveAllChildren(self.ScrollViewXunBaoReward)
    for nIndex, tbItems in ipairs(tRewardList) do
        tbItems.bGot = nIndex <= nGotLv
        tbItems.bReward = nIndex > nGotLv and nIndex <= nCurLevel
        UIHelper.AddPrefab(PREFAB_ID.WidgetXunBaoRewardCell, self.ScrollViewXunBaoReward, nIndex, tbItems)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewXunBaoReward)
    Timer.AddFrame(self, 1, function ()
        if nGotLv > 0 then
            UIHelper.ScrollToIndex(self.ScrollViewXunBaoReward, nGotLv - 1, 0)
        else
            UIHelper.ScrollToTop(self.ScrollViewXunBaoReward, 0)
        end
    end)
end

return UIExtractBattlePassView