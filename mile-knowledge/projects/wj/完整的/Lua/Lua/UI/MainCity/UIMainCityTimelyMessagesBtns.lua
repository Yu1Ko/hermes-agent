-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMainCityTimelyMessagesBtns
-- Date: 2023-03-20 11:23:21
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIMainCityTimelyMessagesBtns = class("UIMainCityTimelyMessagesBtns")
local Index2BtnType = {
    [1] = TimelyMessagesType.Team,
}
function UIMainCityTimelyMessagesBtns:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIMainCityTimelyMessagesBtns:OnExit()
    self.bInit = false
end

function UIMainCityTimelyMessagesBtns:BindUIEvent()

end

function UIMainCityTimelyMessagesBtns:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIMainCityTimelyMessagesBtns:UpdateInfo()
    for index, widgetBtn in ipairs(self.tbScriptBtns) do
        local scriptBtn = UIHelper.GetBindScript(widgetBtn)
        if scriptBtn then
            scriptBtn:OnEnter(Index2BtnType[index])
        end
    end
end


return UIMainCityTimelyMessagesBtns