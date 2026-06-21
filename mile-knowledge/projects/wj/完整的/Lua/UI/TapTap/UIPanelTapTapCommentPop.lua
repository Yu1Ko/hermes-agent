-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSkillConfigurationCell
-- Date: 2023-11-24 10:01:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIPanelTapTapCommentPop
local UIPanelTapTapCommentPop = class("UIPanelTapTapCommentPop")

function UIPanelTapTapCommentPop:OnEnter(szTapEventType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.szTapEventType = szTapEventType

        local szMsg = string.format("game.taptap_%s.popTip.pop", self.szTapEventType)
        XGSDK_TrackEvent(szMsg, "弹出弹窗", {})
    end
end

function UIPanelTapTapCommentPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelTapTapCommentPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        local szMsg = string.format("game.taptap_%s.firstPop.close", self.szTapEventType)
        XGSDK_TrackEvent(szMsg, "点击关闭按钮", {})
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function()
        local szMsg = string.format("game.taptap_%s.firstPop.encourage", self.szTapEventType)
        XGSDK_TrackEvent(szMsg, "点击马上鼓励", {})
        UIHelper.OpenWebWithDefaultBrowser("https://www.taptap.cn/app/382756/review")
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
        UIMgr.Open(self.szTapEventType == TapEventType.Mail and VIEW_ID.PanelTapTapMailRoastPop or VIEW_ID.PanelTapTapRoastPop, self.szTapEventType)
    end)
end

function UIPanelTapTapCommentPop:RegEvent()
end

function UIPanelTapTapCommentPop:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelTapTapCommentPop:UpdateInfo()

end

return UIPanelTapTapCommentPop