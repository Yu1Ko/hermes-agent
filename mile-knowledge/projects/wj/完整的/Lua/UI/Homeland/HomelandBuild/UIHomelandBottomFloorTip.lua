-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBottomFloorTip
-- Date: 2023-11-03 10:39:32
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBottomFloorTip = class("UIHomelandBottomFloorTip")

local HideTime = 1

function UIHomelandBottomFloorTip:OnEnter(nNum)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nNum = nNum
    self:UpdateInfo()
end

function UIHomelandBottomFloorTip:OnExit()
    self.bInit = false
end

function UIHomelandBottomFloorTip:BindUIEvent()

end

function UIHomelandBottomFloorTip:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBottomFloorTip:UpdateInfo()
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetString(self.LabelBasementLevel, self.nNum.."层")

    local tCursor = GetViewCursorPoint()
    self._rootNode:setPosition(tCursor.x, tCursor.y)

    if self.nHideTimerID then
        Timer.DelTimer(self, self.nHideTimerID)
        self.nHideTimerID = nil
    end

    self.nHideTimerID = Timer.Add(self, HideTime, function ()
        UIHelper.SetVisible(self._rootNode, false)
        self.nHideTimerID = nil
    end)
end


return UIHomelandBottomFloorTip