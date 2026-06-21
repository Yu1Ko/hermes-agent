-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandOverviewLeftCard
-- Date: 2024-01-29 16:04:54
-- Desc: ?
-- ---------------------------------------------------------------------------------
local MAX_SHOW_NUM = 10000
local UIHomelandOverviewLeftCard = class("UIHomelandOverviewLeftCard")

function UIHomelandOverviewLeftCard:OnEnter(tbRewardInfo, tbData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbRewardInfo = tbRewardInfo
    self.tbData = tbData
    self:UpdateInfo()
end

function UIHomelandOverviewLeftCard:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandOverviewLeftCard:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnReward, EventType.OnClick, function(btn)
        Event.Dispatch(EventType.OnEnterOverviewRewardList)
    end)

    UIHelper.BindUIEvent(self.BtnGetReward, EventType.OnClick, function(btn)
        RemoteCallToServer("On_HomeLand_RequestOVVReward")
    end)
end

function UIHomelandOverviewLeftCard:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandOverviewLeftCard:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandOverviewLeftCard:UpdateInfo()
    local player            = PlayerData.GetClientPlayer()
    local tbData            = self.tbData
    local tbRewardInfo      = self.tbRewardInfo

    local nRecord           = player.GetHomelandRecord()
    local nSensonRecord     = tbData.nSensonRecord
    local nArchitecture     = player.nArchitecture
    local nItemCount        = player.GetCurrency(CURRENCY_TYPE.HOMELANDTOKEN)
    local nNowActiveNum     = tbData.nNowActiveNum
    local nNextActiveNum    = tbData.nNextActiveNum
    local nTotalActiveNum   = tbData.nTotalActiveNum
    local bCanRequestReward = tbData.bCanRequestReward

    local szLevel = FormatString(g_tStrings.szHouseKeeperEquippedSkill, nNowActiveNum, nNextActiveNum)
    local nPercent = nNowActiveNum / nNextActiveNum * 100
    UIHelper.SetString(self.LabelActiveNum, szLevel)
    UIHelper.SetProgressBarPercent(self.ProgressBarActive, nPercent)
    UIHelper.SetVisible(self.WidgetBtnGetReward, bCanRequestReward)
    UIHelper.SetVisible(self.WidgetBtnReward, not bCanRequestReward)

    local nGetRewardCount = 0
    for _, v in ipairs(tbRewardInfo) do
        if v.nScore > nTotalActiveNum then
            break
        end
        nGetRewardCount = nGetRewardCount + 1
    end
    UIHelper.SetString(self.LabelRewardNum, FormatString(g_tStrings.STR_NEW_PQ_TYPE2, nGetRewardCount, #tbRewardInfo))

    local tbStateInfo = {nRecord, nSensonRecord, nArchitecture, nItemCount}
    for i, label in ipairs(self.tbStateLabel) do
        local nStateNum = tbStateInfo[i]
        local szText = nStateNum
        if nStateNum > MAX_SHOW_NUM then
            nStateNum = math.floor(nStateNum / MAX_SHOW_NUM * 100) / 100
            szText = FormatString(g_tStrings.MPNEY_TENTHOUSAND, nStateNum)
        end
        UIHelper.SetString(label, szText)
    end
end

function UIHomelandOverviewLeftCard:Show()
    UIHelper.SetVisible(self._rootNode, true)
end

function UIHomelandOverviewLeftCard:Close()
    UIHelper.SetVisible(self._rootNode, false)
end

return UIHomelandOverviewLeftCard