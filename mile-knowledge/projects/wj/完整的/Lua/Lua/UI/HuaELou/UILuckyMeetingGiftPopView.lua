-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UILuckyMeetingGiftPopView
-- Date: 2024-04-12 18:33:53
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UILuckyMeetingGiftPopView = class("UILuckyMeetingGiftPopView")

function UILuckyMeetingGiftPopView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UILuckyMeetingGiftPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UILuckyMeetingGiftPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
end

function UILuckyMeetingGiftPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UILuckyMeetingGiftPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UILuckyMeetingGiftPopView:UpdateInfo()

end


return UILuckyMeetingGiftPopView