-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidegtFocusManagePanel
-- Date: 2024-5-11
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIWidegtFocusManageCell
local UIWidegtFocusManageCell = class("UIWidegtFocusManageCell")

function UIWidegtFocusManageCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        --self.parentScript = parentScript ---@type UIGameSettingView
    end

    --self:UpdateInfo()
end

function UIWidegtFocusManageCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidegtFocusManageCell:BindUIEvent()
end

function UIWidegtFocusManageCell:RegEvent()
end

function UIWidegtFocusManageCell:UnRegEvent()
end

return UIWidegtFocusManageCell