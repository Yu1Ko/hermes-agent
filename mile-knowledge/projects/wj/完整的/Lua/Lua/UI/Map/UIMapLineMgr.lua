-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMapLineMgr
-- Date: 2025-07-10 17:55:46
-- Desc: ?
-- ---------------------------------------------------------------------------------
local DefaultImg = "mui/Resource/MiddleMap/LinkLine.png"
local UIMapLineMgr = class("UIMapLineMgr")

function UIMapLineMgr:OnEnter(nMapID, PosComponent, szLineImg)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nMapID = nMapID
    self.PosComponent = PosComponent
    self.szLineImg = szLineImg or DefaultImg
    self.tbLineList = {}
    self:AddAllLine()
end

function UIMapLineMgr:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMapLineMgr:BindUIEvent()
    
end

function UIMapLineMgr:RegEvent()
    Event.Reg(self, EventType.ON_MAP_DRAW_LINE_ADD, function(dwMapID, szKey, tbStart, tbEnd)
        if dwMapID ~= self.nMapID then
            return
        end
        self:AddLine(szKey, tbStart, tbEnd)
    end)

    Event.Reg(self, EventType.ON_MAP_DRAW_LINE_DELETE, function(dwMapID, szKey)
        if dwMapID ~= self.nMapID then
            return
        end
        if szKey == nil then
            self:ClearAllLines()
            return
        end
        self:ClearLineByKey(szKey)
    end)
end

function UIMapLineMgr:UnRegEvent()
    
end

function UIMapLineMgr:ClearAllLines()
    for szKey, tbLine in pairs(self.tbLineList) do
        if tbLine.node then
            UIHelper.RemoveFromParent(tbLine.node, true)
        end
    end
    self.tbLineList = {}
end

function UIMapLineMgr:ClearLineByKey(szKey)
    local tbLine = self.tbLineList[szKey]
    if tbLine then
        UIHelper.RemoveFromParent(tbLine.node, true)
        self.tbLineList[szKey] = nil
    end
end

function UIMapLineMgr:AddLine(szKey, tbStart, tbEnd)
    if not tbStart or not tbEnd then
        return
    end
    local node = self:DrawLine(tbStart, tbEnd)
    self.tbLineList[szKey] = {node = node, tbStart = tbStart, tbEnd = tbEnd}
end

function UIMapLineMgr:AddAllLine()
    self:ClearAllLines()
    local tbLines = MapMgr.GetLineByMapID(self.nMapID)
    if not tbLines then
        return
    end
    for szKey, tbLine in pairs(tbLines) do
        if tbLine and tbLine.tbStart and tbLine.tbEnd then
            self:AddLine(szKey, tbLine.tbStart, tbLine.tbEnd)
        end
    end
end


function UIMapLineMgr:UpdateAllLinePos()
    if not self.PosComponent then
        LOG.INFO("UIMapLineMgr:UpdateAllLinePos, PosComponent is nil !")
        return
    end
    for szKey, tbLine in pairs(self.tbLineList) do
        self:UpdateOneLinePos(tbLine.tbStart, tbLine.tbEnd, tbLine.node)
    end
end

function UIMapLineMgr:UpdateOneLinePos(tbStart, tbEnd, sprite)
    if not tbStart or not tbEnd then
        return
    end
    local nStartX, nStartY = self.PosComponent:LogicPosToMapPos(tbStart[1], tbStart[2])
    local nEndX, nEndY = self.PosComponent:LogicPosToMapPos(tbEnd[1], tbEnd[2])
    UIHelper.SetWorldPosition(sprite, nStartX, nStartY)
    local nDistance = math.sqrt((nEndX - nStartX)^2 + (nEndY - nStartY)^2)
    UIHelper.SetWidth(sprite, nDistance)
end

function UIMapLineMgr:UpdateOneLineRotation(tbStart, tbEnd, sprite)
    local nRotation = math.atan2(tbEnd[2] - tbStart[2], tbEnd[1] - tbStart[1]) * 180 / math.pi
    sprite:setRotation(-nRotation)--不知为何正数是反方向
end

function UIMapLineMgr:DrawLine(tbStart, tbEnd)
    if not self.PosComponent then
        LOG.INFO("UIMapLineMgr:DrawLine, PosComponent is nil !")
        return
    end
    local sprite = cc.Sprite:create(self.szLineImg)
    UIHelper.SetAnchorPoint(sprite, 0, 0.5)
    self._rootNode:addChild(sprite)
    self:UpdateOneLineRotation(tbStart, tbEnd, sprite)
    self:UpdateOneLinePos(tbStart, tbEnd, sprite)
    UIHelper.SetHeight(sprite, 10)
    return sprite
end


return UIMapLineMgr