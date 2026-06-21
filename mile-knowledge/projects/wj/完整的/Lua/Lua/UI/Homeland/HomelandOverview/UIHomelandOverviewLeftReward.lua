-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandOverviewLeftReward
-- Date: 2024-01-29 16:08:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandOverviewLeftReward = class("UIHomelandOverviewLeftReward")

function UIHomelandOverviewLeftReward:OnEnter(tRewardInfo, tData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tData = tData
    self.tRewardInfo = tRewardInfo
    self:UpdateInfo()
end

function UIHomelandOverviewLeftReward:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandOverviewLeftReward:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBack, EventType.OnClick, function(btn)
        Event.Dispatch(EventType.OnExitOverviewRewardList)
    end)
end

function UIHomelandOverviewLeftReward:RegEvent()

end

function UIHomelandOverviewLeftReward:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandOverviewLeftReward:UpdateInfo()
    local tData             = self.tData
    local tRewardInfo       = self.tRewardInfo
    local nTotalActiveNum   = tData.nTotalActiveNum
    local nPercent          = math.min(nTotalActiveNum / tRewardInfo[#tRewardInfo].nScore, 1) * 100
    UIHelper.SetString(self.LabelActiveNum01, nTotalActiveNum)
    UIHelper.RemoveAllChildren(self.WidgetActiveRewardList)
    for index, tbInfo in ipairs(tRewardInfo) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetActivityRewardCell, self.WidgetActiveRewardList)
        script:OnEnter(tbInfo, nTotalActiveNum)
    end
    UIHelper.SetProgressBarPercent(self.ProgressBarActive, nPercent)
    UIHelper.CascadeDoLayoutDoWidget(self.WidgetActiveRewardList, true, true)
end

function UIHomelandOverviewLeftReward:Show()
    UIHelper.SetVisible(self._rootNode, true)
end

function UIHomelandOverviewLeftReward:Close()
    UIHelper.SetVisible(self._rootNode, false)
end

return UIHomelandOverviewLeftReward