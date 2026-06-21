-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIChatViewCell_Time
-- Date: 2022-12-15 16:42:04
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIChatViewCell_Time = class("UIChatViewCell_Time")

function UIChatViewCell_Time:OnEnter(nIndex, tbChatData)
    self.nIndex = nIndex
    self.tbChatData = tbChatData

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChatViewCell_Time:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChatViewCell_Time:BindUIEvent()

end

function UIChatViewCell_Time:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIChatViewCell_Time:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatViewCell_Time:UpdateInfo()
    if not self.tbChatData then return end

    UIHelper.SetString(self.LabelTime, self.tbChatData.szContent)
    UIHelper.SetVisible(self.WidgetTime, true)
    UIHelper.SetVisible(self.LayoutWainning, false)

    local bIsAIChannel = self.tbChatData.nChannel == CLIENT_PLAYER_TALK_CHANNEL.AINPC
    local bIsWarringType = self.tbChatData.bIsWarringType
    if bIsAIChannel and bIsWarringType then
        UIHelper.SetString(self.LabelTip, self.tbChatData.szContent)
        UIHelper.SetVisible(self.WidgetTime, false)
        UIHelper.SetVisible(self.LayoutWainning, true)
        UIHelper.LayoutDoLayout(self.LayoutWainning)
    end
end


return UIChatViewCell_Time