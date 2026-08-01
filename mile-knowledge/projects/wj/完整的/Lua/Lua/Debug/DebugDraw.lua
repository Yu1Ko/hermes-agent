DebugDraw = {}
local self = DebugDraw

local CIRCLE_SEGMENTS = 32

local m_drawNode

function DebugDraw.Init()
    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelHint then
            m_drawNode = nil
        end
    end)
end

function DebugDraw.UnInit()
    Event.UnRegAll(self)
    m_drawNode = nil
end


-- tbOrigin: cc.p(x, y)
-- tbDestination: cc.p(x, y)
-- tbColor: cc.c4f(r, g, b, a)
function DebugDraw.DrawLine(tbOrigin, tbDestination, tbColor)
    self._initDrawNode()

    tbColor = tbColor or cc.c4f(1, 1, 1, 1)
    m_drawNode:drawLine(tbOrigin, tbDestination, tbColor)
end

function DebugDraw.DrawLineXY(nOriginX, nOriginY, nDestinationX, nDestinationY, tbColor)
    local tbOrigin = cc.p(nOriginX, nOriginY)
    local tbDestination = cc.p(nDestinationX, nDestinationY)
    self.DrawLine(tbOrigin, tbDestination, tbColor)
end

-- tbOrigin: cc.p(x, y)
-- tbDestination: cc.p(x, y)
-- tbColor: cc.c4f(r, g, b, a)
function DebugDraw.DrawRect(tbOrigin, tbDestination, tbColor)
    self._initDrawNode()

    tbColor = tbColor or cc.c4f(1, 1, 1, 1)
    m_drawNode:drawRect(tbOrigin, tbDestination, tbColor)
end

function DebugDraw.DrawRectXY(nOriginX, nOriginY, nDestinationX, nDestinationY, tbColor)
    local tbOrigin = cc.p(nOriginX, nOriginY)
    local tbDestination = cc.p(nDestinationX, nDestinationY)
    self.DrawRect(tbOrigin, tbDestination, tbColor)
end

-- tbCenter: cc.p(x, y)
-- tbColor: cc.c4f(r, g, b, a)
function DebugDraw.DrawCircle(tbCenter, nRadius, nAngle, tbColor)
    self._initDrawNode()

    nAngle = nAngle or 360
    tbColor = tbColor or cc.c4f(1, 1, 1, 1)
    m_drawNode:drawCircle(tbCenter, nRadius, nAngle, CIRCLE_SEGMENTS, false, tbColor)
end

function DebugDraw.DrawCircleXY(nCenterX, nCenterY, nRadius, nAngle, tbColor)
    local tbCenter = cc.p(nCenterX, nCenterY)
    self.DrawCircle(tbCenter, nRadius, nAngle, tbColor)
end

function DebugDraw.Clear()
    if not UIMgr.IsViewOpened(VIEW_ID.PanelHint) then
        m_drawNode = nil
        return
    end
    if m_drawNode then
        m_drawNode:clear()
    end
end

function DebugDraw._initDrawNode()
    if m_drawNode then return end

    local uiView = UIMgr.GetView(VIEW_ID.PanelHint)
    local scriptView = uiView and uiView.scriptView
    if scriptView then
        local drawNode = cc.DrawNode:create()
        scriptView._rootNode:addChild(drawNode, -1)
        m_drawNode = drawNode
    else
        m_drawNode = nil
    end
end
