-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBtnSendToChat
-- Date: 2023-10-17 16:02:52
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBtnSendToChat = class("UIBtnSendToChat")

function UIBtnSendToChat:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.SetSpriteFrame(self.ImgIcon, "UIAtlas2_Public_PublicButton_PublicButton1_Btn_SendToChat.png")
    UIHelper.SetString(self.LabelTitle, g_tStrings.SEND_TO_CHAT)
end

function UIBtnSendToChat:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIBtnSendToChat:BindUIEvent()

end

function UIBtnSendToChat:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIBtnSendToChat:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIBtnSendToChat:UpdateInfo()

end


return UIBtnSendToChat