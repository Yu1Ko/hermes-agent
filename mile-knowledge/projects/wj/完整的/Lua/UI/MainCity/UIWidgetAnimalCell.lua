-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetAnimalCell
-- Date: 2025-08-14 16:05:43
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetAnimalCell = class("UIWidgetAnimalCell")
local _nDragThreshold2 = 450
function UIWidgetAnimalCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetAnimalCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetAnimalCell:BindUIEvent()
    
end

function UIWidgetAnimalCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetAnimalCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetAnimalCell:UpdateInfo()
    
end

function UIWidgetAnimalCell:BindMoveFunction(fnDragStart, fnDragMoved, fnDragEnd)
    UIHelper.BindUIEvent(self.TogAnimalCell, EventType.OnTouchBegan, function(btn, nX, nY)
        self.nTouchBeganX, self.nTouchBeganY = nX, nY
        self.bDragging = false
        return true
    end)

    UIHelper.BindUIEvent(self.TogAnimalCell, EventType.OnTouchMoved, function(btn, nX, nY)
        if not self.bDragging then
            local dx = nX - self.nTouchBeganX
            local dy = nY - self.nTouchBeganY
            local dx2 = dx * dx
            local dy2 = dy * dy
            if dx2 + dy2 > _nDragThreshold2 then
                self.bDragging = fnDragStart(nX, nY)  -- 成功触发拖动
            end
        end

        if self.bDragging then
            fnDragMoved(nX, nY)
        end

    end)

    UIHelper.BindUIEvent(self.TogAnimalCell, EventType.OnTouchEnded, function(btn, nX, nY)
        if self.bDragging then
            fnDragEnd(nX, nY)
            self.bDragging = false
        end

    end)

    UIHelper.BindUIEvent(self.TogAnimalCell, EventType.OnTouchCanceled, function(btn, nX, nY)
        if self.bDragging then
            fnDragEnd(nX, nY)
            self.bDragging = false
        end
    end)
end

function UIWidgetAnimalCell:SetAnimalInfo(nIndex, tInfo)
    if not nIndex or not tInfo then
        return
    end

    self.tInfo = tInfo
    self.nIndex = nIndex
end

function UIWidgetAnimalCell:GetAnimalInfo()
    return self.nIndex, self.tInfo
end

function UIWidgetAnimalCell:GetToggle()
    return self.TogAnimalCell
end

return UIWidgetAnimalCell