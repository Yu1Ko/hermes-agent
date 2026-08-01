-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHideUIView
-- Date: 2023-10-27 09:59:13
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHideUIView = class("UIHideUIView")

local nDefaultHideCloseBtnTime = 5

function UIHideUIView:OnEnter(tbHideViewID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbHideViewID = tbHideViewID
    self.bInHide = false
    self:UpdateInfo()
end

function UIHideUIView:OnExit()
    self.bInit = false

    for _, nViewID in ipairs(self.tbHideViewID) do
        UIMgr.ShowView(nViewID)
    end
end

function UIHideUIView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnViewUI, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)
end

function UIHideUIView:RegEvent()
    Event.Reg(self, EventType.OnSceneTouchEnded, function ()
        if self.nHideTimerID then
            Timer.DelTimer(self, self.nHideTimerID)
            self.nHideTimerID = nil
        end

        if self.bInHide then
            UIHelper.PlayAni(self, self.AniAll, "Ani_FullScreen_Show")
        end
        self.nHideTimerID = Timer.Add(self, nDefaultHideCloseBtnTime, function ()
            UIHelper.PlayAni(self, self.AniAll, "Ani_FullScreen_Hide")
            self.bInHide = true
            self.nHideTimerID = nil
        end)
    end)
end

function UIHideUIView:UpdateInfo()
    for _, nViewID in ipairs(self.tbHideViewID) do
        UIMgr.HideView(nViewID)
    end

    self.nHideTimerID = Timer.Add(self, nDefaultHideCloseBtnTime, function ()
        UIHelper.PlayAni(self, self.AniAll, "Ani_FullScreen_Hide")
        self.bInHide = true
        self.nHideTimerID = nil
    end)
end


return UIHideUIView