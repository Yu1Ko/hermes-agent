local UIMapTouchComponent = class("UIMapTouchComponent")

local SCALE_RATE = 0.077
local SCALE_MAX = 2
local SCALE_MIN = 0.5

function UIMapTouchComponent:Init(widget)
    self.widget = widget
    local size = widget:getContentSize()
    self.nLeft = -size.width / 2
    self.nRight = size.width / 2
    self.nBottom = -size.height / 2
    self.nTop = size.height / 2
    self.nSpeed = 1
    self.nMaxSpeed = 1
    self.nTweenTime = 0.3

    self.tbScaleEvent = {}
    self.tbPosEvent = {}
end

function UIMapTouchComponent:SetMoveRegion(nLeft, nRight, nBottom, nTop)
    self.nLeft = nLeft
    self.nRight = nRight
    self.nBottom = nBottom
    self.nTop = nTop
end

function UIMapTouchComponent:SetScaleLimit(nMin, nMax)
    self.nScaleMin = nMin
    self.nScaleMax = nMax
end

function UIMapTouchComponent:SetPosition(x, y, bTween)
    self.nScale = self.nScale or 1
    local WinSize = UIHelper.GetWinSizeInPixels()
    local nRangeHeight = WinSize.height
    local nRangeWidth = WinSize.width
    if self.widgetRange then
        nRangeWidth, nRangeHeight = UIHelper.GetContentSize(self.widgetRange)
    end
    local anchor = self.widget:getParent():getAnchorPointInPoints()
    local nBottom = nRangeHeight + self.nBottom * self.nScale - anchor.y
    local nTop = self.nTop * self.nScale - anchor.y
    local nLeft = nRangeWidth + self.nLeft * self.nScale - anchor.x
    local nRight = self.nRight * self.nScale - anchor.x
    local nOriX, nOriY = UIHelper.GetPosition(self.widget)
    
    x = math.max(x, nLeft)
    x = math.min(x, nRight)
    y = math.max(y, nBottom)
    y = math.min(y, nTop)
    
    if bTween then
        local parent = UIHelper.GetParent(self.widget)
        if parent then
            local px, py = UIHelper.GetAnchorPoint(parent)
            local pw, ph = UIHelper.GetContentSize(parent)
            x = x + px * pw
            y = y + py * ph
        end
        local callback = cc.CallFunc:create(function()
            for nIndex, event in ipairs(self.tbPosEvent) do
                event(x, y)
            end
        end)
        local action = cc.Sequence:create(cc.EaseIn:create(cc.MoveTo:create(self.nTweenTime, cc.p(x, y)), self.nTweenTime), callback)
        self.widget:runAction(action)
    else
        UIHelper.SetPosition(self.widget, x, y)
        for nIndex, event in ipairs(self.tbPosEvent) do
            event(x, y)
        end
    end
    
    return x ~= nOriX, y ~= nOriY
end

function UIMapTouchComponent:MoveToNode(node)
    if not safe_check(node) then
        return
    end

    local pareNode = UIHelper.GetParent(node)
    local parentWidget = UIHelper.GetParent(self.widget)
    if not pareNode or not parentWidget then
        return
    end

    local nX, nY = 0, 0
    if safe_check(node) then
        nX, nY = node:getPosition()
    end
    local wX, wY = UIHelper.ConvertToWorldSpace(pareNode, nX, nY)
    local x, y = UIHelper.ConvertToNodeSpace(self.widget, wX, wY)
    self:SetPosition(-x * self.nScale, -y * self.nScale, true)
end

function UIMapTouchComponent:TouchBegin(nX, nY)
    local nLocalX, nLocalY = UIHelper.ConvertToNodeSpace(self.widget:getParent(), nX, nY)
    self.nTouchX = nLocalX
    self.nTouchY = nLocalY
end

function UIMapTouchComponent:TouchMoved(nX, nY)
    local bFlag = false
    local nLocalX, nLocalY = UIHelper.ConvertToNodeSpace(self.widget:getParent(), nX, nY)
    local x, y = UIHelper.GetPosition(self.widget)
    
    local nDeltaX = nLocalX - self.nTouchX
    local nDeltaY = nLocalY - self.nTouchY
    
    self.nTouchX = nLocalX
    self.nTouchY = nLocalY
    
    if (nDeltaX ~= 0 or nDeltaY ~= 0) then
        bFlag = self:SetPosition(x + nDeltaX * self.nSpeed, y + nDeltaY * self.nSpeed)
    end
    return bFlag
end

function UIMapTouchComponent:Scale(nScale)
    self.nScale = self.nScale or 1
    nScale = self:_clampScale(nScale)

    local x, y = UIHelper.GetPosition(self.widget)
    local nDeltaScale = nScale / self.nScale

    UIHelper.SetScale(self.widget, nScale, nScale)

    for _, v in ipairs(self.tbNoScaling) do
        UIHelper.SetScale(v, 1 / nScale, 1 / nScale)
    end

    self.nScale = nScale
    self:SetPosition(x * nDeltaScale, y * nDeltaScale)

    for _, event in ipairs(self.tbScaleEvent) do
        event(self.nScale)
    end
end

function UIMapTouchComponent:Zoom(delta)
    local nScale = self.nScale or 1

    --数值太小时不动，避免手机端轻微移动时就触发缩放
    if math.abs(delta) < 2 then
        return
    end

    if delta < 0 then
        nScale = nScale - SCALE_RATE
    else
        nScale = nScale + SCALE_RATE
    end

    self:Scale(nScale)
end

function UIMapTouchComponent:_clampScale(nScale)
    local nScaleMax = self.nScaleMax or SCALE_MAX
    local nScaleMin = self.nScaleMin or SCALE_MIN

    if nScale >= nScaleMax then nScale = nScaleMax end
    if nScale <= nScaleMin then nScale = nScaleMin end

    return nScale
end

function UIMapTouchComponent:RegisterScaleEvent(event)
    table.insert(self.tbScaleEvent, event)
end

function UIMapTouchComponent:RegisterPosEvent(event)
    table.insert(self.tbPosEvent, event)
end

function UIMapTouchComponent:SetRangeWidget(widgetRange)
    self.widgetRange = widgetRange
end

function UIMapTouchComponent:GetScale()
    local nScale = self.nScale or 1
    return nScale
end

function UIMapTouchComponent:SetMoveSpeed(nSpeed,nMaxSpeed)
    self.nSpeed = nSpeed
    self.nMaxSpeed = nMaxSpeed
end

function UIMapTouchComponent:SetTweenTime(nTweenTime)
    self.nTweenTime = nTweenTime
end

function UIMapTouchComponent:TouchMovedXY(nX, nY, bCanXAxizMove, bCanYAxizMove)
    if bCanXAxizMove == nil then
        bCanXAxizMove = true
    end
    if bCanYAxizMove == nil then
        bCanYAxizMove = true
    end

    local bXMoved, bYMoved = false, false
    local nDeltaX = nX
    local nDeltaY = nY

    if (nDeltaX ~= 0 or nDeltaY ~= 0) then
        bXMoved, bYMoved = self:SetPosition(nDeltaX * self.nSpeed, nDeltaY * self.nSpeed)
    end
    return bXMoved, bYMoved
end

function UIMapTouchComponent:TweenToPos(nX, nY)
    local nDeltaX = nX 
    local nDeltaY = nY

    if (nDeltaX ~= 0 or nDeltaY ~= 0) then
        self:SetPosition( nDeltaX * self.nSpeed,  nDeltaY * self.nSpeed,true)
    end
end

--function UIMapTouchComponent:MoveToNodeWithSpeed(wX, wY, nXOffset, nCurrentScale)
--    local parentWidget = UIHelper.GetParent(self.widget)
--    if not parentWidget then
--        return
--    end
--
--    nXOffset = nXOffset or 0
--    local x, y = UIHelper.ConvertToNodeSpace(parentWidget, wX, wY)
--    x = x + nXOffset
--    local nPercentage = 1
--    self:SetPosition(-x * nPercentage * nCurrentScale, -y * nPercentage * nCurrentScale, true)
--end

return UIMapTouchComponent