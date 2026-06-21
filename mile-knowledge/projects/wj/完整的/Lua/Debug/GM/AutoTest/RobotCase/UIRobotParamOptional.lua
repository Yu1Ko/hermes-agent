-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIParamOptional
-- Date: 2023-09-20 23:11:02
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIParamOptional = class("UIParamOptional")

function UIParamOptional:OnEnter(tOptional, callback0, callback1)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    UIHelper.SetString(self.LabelItem, tOptional.OptionalName)
    self.closeView = callback0
    self.setParamValue = callback1
end

function UIParamOptional:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIParamOptional:BindUIEvent()
    UIHelper.BindUIEvent(self.Btnltem, EventType.OnClick, function(btn)
        self.closeView()
        self.setParamValue(UIHelper.GetString(self.LabelItem))
    end)
end

function UIParamOptional:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIParamOptional:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIParamOptional:UpdateInfo()
    
end


return UIParamOptional