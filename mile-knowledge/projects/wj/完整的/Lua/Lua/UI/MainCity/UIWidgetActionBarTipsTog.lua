-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetActionBarTipsTog
-- Date: 2025-08-04 15:07:22
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetActionBarTipsTog = class("UIWidgetActionBarTipsTog")

function UIWidgetActionBarTipsTog:OnEnter(ToggleGroup, nState, fnSelect)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.fnSelect = fnSelect
    self:UpdateInfo(ToggleGroup, nState)
end

function UIWidgetActionBarTipsTog:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetActionBarTipsTog:BindUIEvent()
    UIHelper.BindUIEvent(self._rootNode, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect and self.fnSelect then
            self.fnSelect()
        end
    end)
end

function UIWidgetActionBarTipsTog:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetActionBarTipsTog:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetActionBarTipsTog:UpdateInfo(ToggleGroup, nState)
    UIHelper.ToggleGroupAddToggle(ToggleGroup, self._rootNode)
    local szTitle = ACTIONBAR_NAME[nState]
    local szIcon = ACTIONBAR_ICON[nState]
    UIHelper.SetString(self.LabelEquip, szTitle)
    UIHelper.SetSpriteFrame(self.ImgIcon, szIcon)
end


return UIWidgetActionBarTipsTog