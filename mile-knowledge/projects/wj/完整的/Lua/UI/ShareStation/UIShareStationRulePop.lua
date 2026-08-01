-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIShareStationRulePop
-- Date: 2025-07-25 14:24:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIShareStationRulePop = class("UIShareStationRulePop")

function UIShareStationRulePop:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollView)
end

function UIShareStationRulePop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIShareStationRulePop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function(btn)
        Storage.ShareStationRule.bShowRule = true
        Storage.ShareStationRule.Dirty()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        Storage.ShareStationRule.bShowRule = false
        Storage.ShareStationRule.Dirty()

        BuildFaceData.ResetFaceData()
        BuildBodyData.ResetBodyData()
        FireUIEvent("COINSHOP_INIT_ROLE", true, true)
        FireUIEvent("RESET_BODY")
        FireUIEvent("RESET_NEW_FACE")
        Event.Dispatch(EventType.OnChangeBuildFaceDefault)

        UIMgr.Close(self)
        Event.Dispatch(EventType.OnCloseShareStation)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)
end

function UIShareStationRulePop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIShareStationRulePop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIShareStationRulePop:UpdateInfo()
    
end


return UIShareStationRulePop