-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildBlueprintLoadingView
-- Date: 2024-04-23 19:46:55
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildBlueprintLoadingView = class("UIHomelandBuildBlueprintLoadingView")
local DELAY_TIME = 3
function UIHomelandBuildBlueprintLoadingView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.fPercentage = 0
    self:UpdateInfo()
end

function UIHomelandBuildBlueprintLoadingView:OnExit()
    self.bInit = false
end

function UIHomelandBuildBlueprintLoadingView:BindUIEvent()

end

function UIHomelandBuildBlueprintLoadingView:RegEvent()
    Event.Reg(self, "LUA_HOMELAND_UPDATE_LOADBAR", function()
        if self.nCloseTimerID then
            return
        end
        local fPercentage = arg0
        if fPercentage >= 100 then
            self.nCloseTimerID = Timer.Add(self, DELAY_TIME, function()
                UIMgr.Close(self)
            end)
        end

        self.fPercentage = fPercentage
        self:UpdateInfo()
    end)
end

function UIHomelandBuildBlueprintLoadingView:UpdateInfo()
    UIHelper.SetString(self.LabelHide, string.format("蓝图加载中…%d%%", self.fPercentage))
    UIHelper.SetProgressBarPercent(self.ProgressBarLoading, self.fPercentage)
end


return UIHomelandBuildBlueprintLoadingView