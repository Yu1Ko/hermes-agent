-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIGameLogReport
-- Date: 2024-06-18 11:11:45
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIGameLogReport = class("UIGameLogReport")

function UIGameLogReport:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIGameLogReport:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIGameLogReport:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose , EventType.OnClick , function ()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnCancel , EventType.OnClick , function ()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.ToggleHideNpc , EventType.OnClick , function ()
        self.blogOpen = not self.blogOpen
        GameSettingData.OnOpenLogReport(self.blogOpen)
        GameSettingData.StoreNewValue(UISettingKey.EnableLogging, self.blogOpen)  --记录在设置表里
        UIHelper.SetVisible(self.LayoutButton , self.blogOpen)
    end)

    UIHelper.BindUIEvent(self.BtnCommit , EventType.OnClick , function ()
        GameSettingData.OnLogReport()
        UIMgr.Close(self)
    end)
    
end

function UIGameLogReport:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIGameLogReport:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIGameLogReport:UpdateInfo()
    self.blogOpen = GameSettingData.IsOpenLogReport()
    UIHelper.SetSelected(self.ToggleHideNpc , self.blogOpen)
    UIHelper.SetVisible(self.LayoutButton , self.blogOpen)
end

return UIGameLogReport