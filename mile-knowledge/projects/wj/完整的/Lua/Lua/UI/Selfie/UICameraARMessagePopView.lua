-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICameraARMessagePopView
-- Date: 2024-09-12 17:00:28
-- Desc: AR模式协议界面
-- ---------------------------------------------------------------------------------

local UICameraARMessagePopView = class("UICameraARMessagePopView")

function UICameraARMessagePopView:OnEnter(fnCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.fnCallback = fnCallback
    self:UpdateInfo()
end

function UICameraARMessagePopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICameraARMessagePopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function()
        Storage.Selfie.bAcceptARConsent = true
        Storage.Selfie.Flush()

        if self.fnCallback then
            self.fnCallback()
        end

        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnRefuse, EventType.OnClick, function()
        Storage.Selfie.bAcceptARConsent = false
        Storage.Selfie.Flush()

        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnOK, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UICameraARMessagePopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICameraARMessagePopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICameraARMessagePopView:UpdateInfo()
    UIHelper.SetVisible(self.BtnAccept, not Storage.Selfie.bAcceptARConsent)
    UIHelper.SetVisible(self.BtnRefuse, not Storage.Selfie.bAcceptARConsent)
    UIHelper.SetVisible(self.BtnOK, Storage.Selfie.bAcceptARConsent)
    UIHelper.LayoutDoLayout(self.LayoutBtnList)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewArenaIntegral)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewArenaIntegral, self.WidgetArrow)
end


return UICameraARMessagePopView