-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMiniGameResultBtn
-- Date: 2025-09-26 11:16:44
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIMiniGameResultBtn = class("UIMiniGameResultBtn")

function UIMiniGameResultBtn:OnEnter(tInfo)
    self.szText = UIHelper.GBKToUTF8(tInfo.szText)
    self.szCallback = tInfo.szCallback
    self.tUserData = tInfo.tUserData
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIMiniGameResultBtn:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMiniGameResultBtn:BindUIEvent()
    UIHelper.BindUIEvent(self.Btn, EventType.OnClick, function ()
        if self.szCallback then
            RemoteCallToServer(self.szCallback, self.tUserData)
        end
        Event.Dispatch("MINI_GAME_RESULT_CLOSE")
    end)
end

function UIMiniGameResultBtn:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIMiniGameResultBtn:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below
-- ----------------------------------------------------------

function UIMiniGameResultBtn:UpdateInfo()
    UIHelper.SetString(self.LabelText, self.szText)
end


return UIMiniGameResultBtn