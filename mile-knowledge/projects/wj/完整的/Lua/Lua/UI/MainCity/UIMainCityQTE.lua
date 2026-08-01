-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMainCityQTE
-- Date: 2023-01-03 10:43:08
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIMainCityQTE = class("UIMainCityQTE")

function UIMainCityQTE:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIMainCityQTE:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMainCityQTE:BindUIEvent()
    
end

function UIMainCityQTE:RegEvent()
    Event.Reg(self, EventType.ON_QTEPANEL_SHOW, function()
        self:UpdateInfo()
    end)

end

function UIMainCityQTE:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMainCityQTE:UpdateInfo()
    for index, UI in ipairs(self.tbQteSkill) do
        UIHelper.SetVisible(UI, false)
    end
    local tbSlotInfo = QTEMgr.GetMainCityQTESlotInfo()
    for index, tbInfo in ipairs(tbSlotInfo) do
        local UI = self.tbQteSkill[index]
        if UI then
            local scriptView = UIHelper.GetBindScript(UI)
            if scriptView then
                scriptView:OnEnter(tbInfo)
            end
        end
    end
    UIHelper.LayoutDoLayout(self.Layout)
end



return UIMainCityQTE