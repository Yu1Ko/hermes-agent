-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UINpcGuildlinesSubClass
-- Date: 2023-04-28 16:00:37
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UINpcGuildlinesSubClass = class("UINpcGuildlinesSubClass")

function UINpcGuildlinesSubClass:OnEnter(tSubClass, fnAction)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tSubClass = tSubClass
    self.fnAction = fnAction
    self:UpdateInfo()
end

function UINpcGuildlinesSubClass:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UINpcGuildlinesSubClass:BindUIEvent()
    UIHelper.BindUIEvent(self.TogList, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self.fnAction()
        end
    end)
end

function UINpcGuildlinesSubClass:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UINpcGuildlinesSubClass:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UINpcGuildlinesSubClass:UpdateInfo()
    UIHelper.SetString(self.LabelNormal, UIHelper.GBKToUTF8(self.tSubClass.szTypeName))
    UIHelper.SetString(self.LabelSelect, UIHelper.GBKToUTF8(self.tSubClass.szTypeName))
end


return UINpcGuildlinesSubClass