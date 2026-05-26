-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMyHomePageBranchList
-- Date: 2023-04-12 16:59:54
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandMyHomePageBranchList = class("UIHomelandMyHomePageBranchList")

function UIHomelandMyHomePageBranchList:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandMyHomePageBranchList:OnExit()
    self.bInit = false
end

function UIHomelandMyHomePageBranchList:BindUIEvent()

end

function UIHomelandMyHomePageBranchList:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandMyHomePageBranchList:UpdateInfo()

end


return UIHomelandMyHomePageBranchList