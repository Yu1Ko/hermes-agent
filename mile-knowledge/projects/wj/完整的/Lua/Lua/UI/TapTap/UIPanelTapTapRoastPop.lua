-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSkillConfigurationCell
-- Date: 2023-11-24 10:01:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIPanelTapTapRoastPop
local UIPanelTapTapRoastPop = class("UIPanelTapTapRoastPop")

function UIPanelTapTapRoastPop:OnEnter(szTapEventType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.bAccepted = false
        self.szTapEventType = szTapEventType
    end
end

function UIPanelTapTapRoastPop:OnExit()
    self.bInit = false
    self:UnRegEvent()

    if not self.bAccepted then
        UIMgr.Open(self.szTapEventType == TapEventType.Mail and VIEW_ID.PanelTapTapMailPop or VIEW_ID.PanelTapTapCommentPop, self.szTapEventType)
        --UIMgr.Open(VIEW_ID.PanelTapTapCommentPop, TapEventType.PaySuccess)
    end
end

function UIPanelTapTapRoastPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        local szMsg = string.format("game.taptap_%s.secondPop.close", self.szTapEventType)
        XGSDK_TrackEvent(szMsg, "点击关闭按钮", {})
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function()
        local szMsg = string.format("game.taptap_%s.secondPop.complain", self.szTapEventType)
        XGSDK_TrackEvent(szMsg, "点击我要吐槽", {})
        UIHelper.OpenWeb(tUrl.NegativeReviewQuestionnaire)
        self.bAccepted = true
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        local szMsg = string.format("game.taptap_%s.secondPop.consider", self.szTapEventType)
        XGSDK_TrackEvent(szMsg, "点击考虑一下", {})
        UIMgr.Close(self)
    end)
end

function UIPanelTapTapRoastPop:RegEvent()
end

function UIPanelTapTapRoastPop:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelTapTapRoastPop:UpdateInfo()

end

return UIPanelTapTapRoastPop