-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOpenVoiceRoomBtn
-- Date: 2025-09-11 20:13:17
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOpenVoiceRoomBtn = class("UIOpenVoiceRoomBtn")

function UIOpenVoiceRoomBtn:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
    end
    self.nTimer = Timer.AddFrameCycle(self, 1, function()
        self:UpdateInfo()
    end)
end

function UIOpenVoiceRoomBtn:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOpenVoiceRoomBtn:BindUIEvent()
    UIHelper.BindUIEvent(self._rootNode, EventType.OnClick, function()
        RoomVoiceData.JumpToRoomVoice()
    end)
end

function UIOpenVoiceRoomBtn:RegEvent()
    
end

function UIOpenVoiceRoomBtn:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOpenVoiceRoomBtn:UpdateInfo()
    UIHelper.SetVisible(self.ImgMic, RoomVoiceData.IsMeSaying())
    UIHelper.SetVisible(self.ImgSound, RoomVoiceData.HasMemberSaying())
end


return UIOpenVoiceRoomBtn