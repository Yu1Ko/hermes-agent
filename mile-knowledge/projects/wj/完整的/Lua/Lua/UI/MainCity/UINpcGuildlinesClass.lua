-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UINpcGuildlinesClass
-- Date: 2023-04-28 15:39:58
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UINpcGuildlinesClass = class("UINpcGuildlinesClass")

function UINpcGuildlinesClass:OnEnter(tClass, fnAction)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tClass = tClass
    self.fnAction = fnAction
    self:UpdateInfo()
end

function UINpcGuildlinesClass:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UINpcGuildlinesClass:BindUIEvent()
    UIHelper.BindUIEvent(self.TogTabList, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self.fnAction()
        end
    end)
end

function UINpcGuildlinesClass:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UINpcGuildlinesClass:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UINpcGuildlinesClass:UpdateInfo()
    UIHelper.SetString(self.LabelNormal, UIHelper.GBKToUTF8(self.tClass.szGuildName))
    UIHelper.SetString(self.LabelUpAll, UIHelper.GBKToUTF8(self.tClass.szGuildName))
end


return UINpcGuildlinesClass