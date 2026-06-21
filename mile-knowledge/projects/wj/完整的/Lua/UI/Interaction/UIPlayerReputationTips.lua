-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPlayerReputationTips
-- Date: 2023-05-15 11:01:00
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPlayerReputationTips = class("UIPlayerReputationTips")

function UIPlayerReputationTips:OnEnter(tbInfo,dwPlayerID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:OnCreditInfoRespond(tbInfo,dwPlayerID)
end

function UIPlayerReputationTips:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPlayerReputationTips:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnDetail, EventType.OnClick, function ()
        local szContent = table.concat(g_tStrings.STR_TIPS, "\n")
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnDetail, TipsLayoutDir.BOTTOM_RIGHT, szContent)
    end)
end

function UIPlayerReputationTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPlayerReputationTips:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPlayerReputationTips:UpdateInfo()

end

function UIPlayerReputationTips:OnCreditInfoRespond(tbInfo,dwPlayerID)
    local totalProgress = 100
    local listProgressComponents = {
        { self.ProgressBarZhenYingZhanChang, self.LableZhenYingZhanChang },
        { self.ProgressBarMingJianDaHui, self.LableMingJianDaHui },
        { self.ProgressBarLongMenJueJing, self.LableLongMenJueJing },
        { self.ProgressBarDaXiaoGongFang, self.LableDaXiaoGongFang },
        { self.ProgressBarLiDuGuiYu, self.LableLiDuGuiYu },
        { self.ProgressBarLieXingXuJing, self.LableLieXingXuJing },
    }

    for indexProgress, progressComponents in ipairs(listProgressComponents) do
        local progressBar, label = table.unpack(progressComponents)
        local progress = tbInfo[indexProgress]
        UIHelper.SetProgressBarPercent(progressBar, progress / totalProgress * 100)
        UIHelper.SetString(label, progress .. "/" .. totalProgress)
    end

    local targetPlayer = GetPlayer(dwPlayerID) or g_pClientPlayer
    UIHelper.SetString(self.LableCreditTitle, UIHelper.GBKToUTF8(targetPlayer.szName) .. "的信誉")
    UIHelper.LayoutDoLayout(self.WidgetTitleLabel)
end

return UIPlayerReputationTips