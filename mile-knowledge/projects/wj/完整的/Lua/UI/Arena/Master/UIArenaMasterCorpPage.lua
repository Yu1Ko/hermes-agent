-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaMasterCorpPage
-- Date: 2025-02-10 10:16:49
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaMasterCorpPage = class("UIArenaMasterCorpPage")

function UIArenaMasterCorpPage:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIArenaMasterCorpPage:OnExit()
    self.bInit = false
end

function UIArenaMasterCorpPage:BindUIEvent()

end

function UIArenaMasterCorpPage:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end
function UIArenaMasterCorpPage:UpdateInfo()

end


return UIArenaMasterCorpPage