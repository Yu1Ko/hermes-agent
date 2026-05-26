-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetPQ
-- Date: 2024-04-17 20:41:31
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetPQ = class("UIWidgetPQ")

function UIWidgetPQ:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetPQ:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetPQ:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnMove, EventType.OnClick, function()
        Event.Dispatch("ON_START_MOVE_BOARD_NODE", self.script)
        UIHelper.SetVisible(self._rootNode, false)
    end)

    UIHelper.BindUIEvent(self.BtnDelect, EventType.OnClick, function()
        self.script.fnDelete()
        UIHelper.SetVisible(self._rootNode, false)
    end)
end

function UIWidgetPQ:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetPQ:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetPQ:Show(script, nX, nY)
    self.script = script
    self:UpdateInfo(nX, nY)
end





-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetPQ:UpdateInfo(nX, nY)
    
    local nBtnState = self.script.fnMove ~= nil and BTN_STATE.Normal or BTN_STATE.Disable
    UIHelper.SetButtonState(self.BtnMove, nBtnState, nil, true)

    UIHelper.SetPosition(self._rootNode, nX, nY)
    UIHelper.SetVisible(self._rootNode, true)
end


return UIWidgetPQ