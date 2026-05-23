-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIInstrumentRulePop
-- Date: 2025-07-25 14:24:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIInstrumentRulePop = class("UIInstrumentRulePop")

function UIInstrumentRulePop:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollView)
end

function UIInstrumentRulePop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIInstrumentRulePop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function(btn)
        Storage.InstrumentRule.bShowRule = true
        Storage.InstrumentRule.Dirty()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        Storage.InstrumentRule.bShowRule = false
        Storage.InstrumentRule.Dirty()
        UIMgr.Close(self)
        UIMgr.Close(VIEW_ID.PanelMusicMainPlay)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)
end

function UIInstrumentRulePop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIInstrumentRulePop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIInstrumentRulePop:UpdateInfo()
    
end


return UIInstrumentRulePop