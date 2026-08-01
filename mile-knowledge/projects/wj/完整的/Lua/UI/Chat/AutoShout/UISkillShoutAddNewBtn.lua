-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISkillShoutAddNewBtn
-- Date: 2025-03-06 10:10:38
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISkillShoutAddNewBtn = class("UISkillShoutAddNewBtn")

function UISkillShoutAddNewBtn:OnEnter(fnClickCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.fnClickCallback = fnClickCallback
end

function UISkillShoutAddNewBtn:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISkillShoutAddNewBtn:BindUIEvent()
    UIHelper.BindUIEvent(self._rootNode, EventType.OnClick, function()
        if self.fnClickCallback then
            self.fnClickCallback()
        end
    end)
end

function UISkillShoutAddNewBtn:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISkillShoutAddNewBtn:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISkillShoutAddNewBtn:UpdateInfo()
    
end


return UISkillShoutAddNewBtn