-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAdventureAwardCell
-- Date: 2023-05-05 14:56:43
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIAdventureAwardCell = class("UIAdventureAwardCell")

function UIAdventureAwardCell:OnEnter(fnAction)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.fnAction = fnAction
end

function UIAdventureAwardCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAdventureAwardCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function ()
        if self.fnAction then
            self.fnAction()
        end
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function ()
        if self.fnAction then
            self.fnAction()
        end
    end)
end

function UIAdventureAwardCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIAdventureAwardCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAdventureAwardCell:UpdateInfo()
    
end


return UIAdventureAwardCell