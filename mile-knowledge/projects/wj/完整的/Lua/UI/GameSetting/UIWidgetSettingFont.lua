-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSettingFont
-- Date: 2024-07-15 16:19:35
-- Desc: ?
-- ---------------------------------------------------------------------------------

local MAX_FONT_NUM = 4

---@class UIWidgetSettingFont
local UIWidgetSettingFont = class("UIWidgetSettingFont")

function UIWidgetSettingFont:OnEnter(funcClickCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    
    self.funcClickCallback = funcClickCallback
    self:UpdateInfo()
end

function UIWidgetSettingFont:OnExit()
    self.bInit = false
end

function UIWidgetSettingFont:BindUIEvent()
end

function UIWidgetSettingFont:RegEvent()

end

function UIWidgetSettingFont:UpdateInfo()
end

function UIWidgetSettingFont:AddFont(tInfo, toggleGroup, funcClickCallback)
    self.nAvailableIndex = self.nAvailableIndex or 1

    local parent = self.tbWidgetFonts[self.nAvailableIndex]
    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSettingFontCell, parent)
    script:UpdateInfo(tInfo, toggleGroup, funcClickCallback)

    self.nAvailableIndex = self.nAvailableIndex + 1
end

function UIWidgetSettingFont:IsFull()
    return self.nAvailableIndex and self.nAvailableIndex > MAX_FONT_NUM
end

return UIWidgetSettingFont