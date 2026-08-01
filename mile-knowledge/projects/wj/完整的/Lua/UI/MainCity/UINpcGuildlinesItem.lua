-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UINpcGuildlinesItem
-- Date: 2023-04-28 16:46:48
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UINpcGuildlinesItem = class("UINpcGuildlinesItem")

function UINpcGuildlinesItem:OnEnter(tNpc, fnAction)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tNpc = tNpc
    self.fnAction = fnAction
    self:UpdateInfo()
end

function UINpcGuildlinesItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UINpcGuildlinesItem:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnList, EventType.OnClick, function ()
        self.fnAction()
    end)
end

function UINpcGuildlinesItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UINpcGuildlinesItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UINpcGuildlinesItem:UpdateInfo()
    UIHelper.SetString(self.LabelIocation, UIHelper.GBKToUTF8(self.tNpc.szTypeName))
end


return UINpcGuildlinesItem