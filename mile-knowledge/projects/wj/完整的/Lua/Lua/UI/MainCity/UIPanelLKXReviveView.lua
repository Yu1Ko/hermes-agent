-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelLKXReviveView
-- Date: 2024-05-29 17:54:38
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelLKXReviveView = class("UIPanelLKXReviveView")

function UIPanelLKXReviveView:OnEnter(szText, szType, nMessageID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:Init(szText, szType, nMessageID)
    self:UpdateInfo()
end

function UIPanelLKXReviveView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelLKXReviveView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnExit, EventType.OnClick, function()
        UIHelper.ShowConfirm("是否确定退出场景", function()
            RemoteCallToServer("OnMessageBoxRequest", self.nMessageID, false, nil)
        end)
    end)
end

function UIPanelLKXReviveView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelLKXReviveView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIPanelLKXReviveView:Init(szText, szType, nMessageID)
    self.szText, self.szType, self.nMessageID = szText, szType, nMessageID
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelLKXReviveView:UpdateInfo()
    UIHelper.SetRichText(self.RichTextRevive, UIHelper.GBKToUTF8(self.szText))
    UIHelper.LayoutDoLayout(self.LayoutTextRevive)

    if self.szType == "teamquit" then
        UIHelper.SetString(self.LabelRevive1, "全队退出")
    else
        UIHelper.SetString(self.LabelRevive1, "退出")
    end
end


return UIPanelLKXReviveView