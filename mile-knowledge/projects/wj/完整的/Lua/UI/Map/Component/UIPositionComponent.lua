local UIPositionComponent = class("UIPositionComponent")

function UIPositionComponent:Init(w, h, startx, starty, scale, dwMapID)
    self.nWidth = w
    self.nHeight = h
    self.nStartX = startx
    self.nStartY = starty
    self.nScale = scale
    self.dwMapID = dwMapID
end

function UIPositionComponent:Update(img, bHierarchyScale)
    local x, y = UIHelper.GetWorldPosition(img)
    local size = img:getPreferredSize()
    local scale = bHierarchyScale and UIHelper.GetHierarchyScale(img) or UIHelper.GetScale(img)
    self.nImageWidth = size.width * scale
    self.nImageHeight = size.height * scale
    local nAnchorX, nAnchorY = UIHelper.GetAnchorPoint(img)
    self.nMapX = x - self.nImageWidth * nAnchorX
    self.nMapY = y + self.nImageHeight * (1-nAnchorY)
    self.nScaleX = self.nImageWidth / self.nWidth * self.nScale
    self.nScaleY = self.nImageHeight / self.nHeight * self.nScale
end

function UIPositionComponent:LogicPosToMapPos(x, y, w, h, bNotTurnMainMap)
    if not bNotTurnMainMap then
        local dwMainMapID = MapHelper.GetMainMap(self.dwMapID)
        if dwMainMapID and dwMainMapID ~= self.dwMapID then
            local nMainX, nMainY = GetMainMapPosition(dwMainMapID, self.dwMapID, x, y)
            if nMainX ~= -1 and nMainY ~= -1 then
                x, y = nMainX, nMainY
            end
        end
    end
    local retX = self.nMapX + (x - self.nStartX) * self.nScaleX
    local retY = self.nMapY + (y - self.nStartY) * self.nScaleY - self.nImageHeight
    return retX, retY
end

function UIPositionComponent:MapPosToLogicPos(x, y, bTurnSubMap)
    local dwMainMapID = MapHelper.GetMainMap(self.dwMapID)
    if dwMainMapID and dwMainMapID ~= self.dwMapID then
        local nMainX, nMainY = GetMainMapPosition(dwMainMapID, self.dwMapID, x, y)
        if nMainX ~= -1 and nMainY ~= -1 then
            x, y = nMainX, nMainY
        end
    end
    local tPos = {x = x, y = y}
    local retX = self.nStartX + (tPos.x - self.nMapX) / self.nScaleX
    local retY = self.nStartY + (tPos.y - self.nMapY + self.nImageHeight) / self.nScaleY

    if bTurnSubMap then
        local dwMainMapID = MapHelper.GetMainMap(self.dwMapID)
        if dwMainMapID ~= self.dwMapID then
            local nSubX, nSubY = GetSubMapPosition(dwMainMapID, self.dwMapID, retX, retY)
            if nSubX ~= -1 and nSubY ~= -1 then
                retX = nSubX
                retY = nSubY
            end
        end
    end
    return retX, retY
end

return UIPositionComponent