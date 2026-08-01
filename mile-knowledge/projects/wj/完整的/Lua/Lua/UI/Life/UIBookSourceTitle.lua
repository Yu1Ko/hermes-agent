-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBookSourceTitle
-- Date: 2022-12-15 22:46:58
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBookSourceTitle = class("UIBookSourceTitle")

function UIBookSourceTitle:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIBookSourceTitle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIBookSourceTitle:BindUIEvent()
    
end

function UIBookSourceTitle:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIBookSourceTitle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIBookSourceTitle:SetTitle(szTitle)
    UIHelper.SetString(self.LabelSourceTitle, szTitle)
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIBookSourceTitle:UpdateInfo()
    
end


return UIBookSourceTitle