-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetBuffMessage
-- Date: 2024-08-27 10:47:39
-- Desc: PanelTradeMessagePop中的WidgetBuffMessage
-- ---------------------------------------------------------------------------------

local UIWidgetBuffMessage = class("UIWidgetBuffMessage")

function UIWidgetBuffMessage:OnEnter(nBuffID)
    if not nBuffID then
        return
    end

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nBuffID = nBuffID
    self:UpdateInfo()
end

function UIWidgetBuffMessage:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetBuffMessage:BindUIEvent()
    
end

function UIWidgetBuffMessage:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetBuffMessage:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetBuffMessage:UpdateInfo()
    local szName = BuffMgr.GetBuffName(self.nBuffID, 1)
    local szDesc = BuffMgr.GetBuffDesc(self.nBuffID, 1)
    local szIcon = TabHelper.GetBuffIconPath(self.nBuffID, 1)

    UIHelper.SetString(self.LabelTitle, szName)
    UIHelper.SetString(self.LabelDesc, szDesc)

    local szPath = szIcon and string.format("Resource/icon/%s", szIcon)
    if szPath and Lib.IsFileExist(szPath) then
        UIHelper.SetTexture(self.ImgBuffIcon, szPath)
    end

    print(szName, szDesc, szIcon)
end


return UIWidgetBuffMessage