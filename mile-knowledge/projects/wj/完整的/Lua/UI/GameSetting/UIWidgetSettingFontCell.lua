-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSettingFontCell
-- Date: 2024-07-15 17:33:18
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetSettingFontCell = class("UIWidgetSettingFontCell")

function UIWidgetSettingFontCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    UIHelper.SetSwallowTouches(self.ToggleFont, false)
end

function UIWidgetSettingFontCell:OnExit()
    self.bInit = false
end

function UIWidgetSettingFontCell:BindUIEvent()
end

function UIWidgetSettingFontCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end
function UIWidgetSettingFontCell:UpdateInfo(tInfo, toggleGroup, funcClickCallback)
    local tConfig = FontMgr.GetFontConfigGameSettingDesc(tInfo.szDec)
    if not tConfig then
        return
    end

    UIHelper.SetString(self.LabelTitle, tConfig.szName)
    UIHelper.ToggleGroupAddToggle(toggleGroup, self.ToggleFont)
    UIHelper.BindUIEvent(self.ToggleFont, EventType.OnClick, function(btn)
        if funcClickCallback then
            funcClickCallback()
        end
    end)
     UIHelper.SetSpriteFrame(self.ImgFont, tConfig.szFontImg)
end

return UIWidgetSettingFontCell