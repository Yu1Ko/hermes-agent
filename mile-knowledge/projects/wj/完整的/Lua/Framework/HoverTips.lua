-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: HoverTips
-- Date: 2022-11-17 15:09:44
-- Desc: 悬浮弹窗
-- ---------------------------------------------------------------------------------

---@class HoverTips
HoverTips = class("HoverTips")

--Tips显示位置相对于点击位置的方向
TipsLayoutDir = {
    AUTO = 1,
    TOP_LEFT = 2,
    TOP_CENTER = 3,
    TOP_RIGHT = 4,
    LEFT_CENTER = 5,
    RIGHT_CENTER = 6,
    BOTTOM_LEFT = 7,
    BOTTOM_CENTER = 8,
    BOTTOM_RIGHT = 9,
    MIDDLE = 10,
}

local DEFAULT_OFFSET_X = 20
local DEFAULT_OFFSET_Y = 20

--定义Tips位置检测顺序
local m_aDirPriority = {
    TipsLayoutDir.BOTTOM_RIGHT,
    TipsLayoutDir.BOTTOM_CENTER,
    TipsLayoutDir.BOTTOM_LEFT,
    TipsLayoutDir.RIGHT_CENTER,
    TipsLayoutDir.LEFT_CENTER,
    TipsLayoutDir.TOP_RIGHT,
    TipsLayoutDir.TOP_CENTER,
    TipsLayoutDir.TOP_LEFT
}

-------------------------------- Public --------------------------------

-- Public Functions:
--
-- function HoverTips:Init(node)                                --初始化
-- function HoverTips:Show(nX, nY)                              --在指定位置周围显示Tips
-- function HoverTips:ShowNodeTips(node)                        --在Node周围显示Tips
-- function HoverTips:UpdatePosByXY(nX, nY)                     --将Tips移动到指定位置周围
-- function HoverTips:UpdatePosByNode(node)                     --将Tips移到到指定Node周围
-- function HoverTips:Update()                                  --更新显示位置
-- function HoverTips:Hide()                                    --隐藏Tips
-- function HoverTips:PrintData()                               --打印数据
-- function HoverTips:SetNode(node)                             --设置浮窗Node
-- function HoverTips:SetNodeData()                             --刷新Node数据
-- function HoverTips:SetDisplayLayoutDir(nDir)                 --设置Tips显示方位（枚举：TipsLayoutDir）
-- function HoverTips:SetAutoLayoutDirPriority(aDir)            --设置自动Layout时，检测方向顺序
-- function HoverTips:SetSize(nSizeX, nSizeY)                   --设置浮窗尺寸数据
-- function HoverTips:SetAnchor(nAnchX, nAnchY)                 --设置浮窗锚点数据
-- function HoverTips:SetSpace(nMinX, nMinY, nMaxX, nMaxY)      --设置浮窗的显示限制区域
-- function HoverTips:SetOffset(nOffsetX, nOffsetY)             --设置点击位置与浮窗的偏移值，避免手指挡住浮窗内容

---@return HoverTips
function HoverTips.New(node, bPrintData)
    local hoverTips = HoverTips.CreateInstance(HoverTips)
    if node then
        hoverTips:Init(node, bPrintData)
    end
    return hoverTips
end

function HoverTips:Init(node, bPrintData)
    if not node then return end

    self.m = {}

    self.m.bIsShow = false

    --初始化目标节点浮窗及其锚点和尺寸数据
    self:SetNode(node)

    --初始化浮窗的显示限制区域，默认为全屏幕内10像素
    local function setSpace()
        local nNotchHeight = Device.GetNotchHeight()
        local screenSize = UIHelper.GetSafeAreaRect()
        local nGap = 10
        self:SetSpace(nGap + nNotchHeight, nGap, screenSize.width - nGap - nNotchHeight, screenSize.height - nGap)
    end

    setSpace()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        setSpace()
    end)

    --初始化Tips显示方位，默认使Tips自动调整显示方位
    self:SetDisplayLayoutDir(TipsLayoutDir.AUTO)

    --初始化点击位置与浮窗的偏移，避免手指挡住浮窗内容
    self:SetOffset(DEFAULT_OFFSET_X, DEFAULT_OFFSET_Y)
    self:_setExtraOffset(0, 0)

    if bPrintData then
        self:PrintData()
    end
end

--在指定位置周围显示Tips
function HoverTips:Show(nX, nY)
    self:UpdatePosByXY(nX, nY)

    UIHelper.SetVisible(self.m.node, true)
    self.m.bIsShow = true
end

--在Node周围显示Tips
function HoverTips:ShowNodeTips(node)
    self:UpdatePosByNode(node)

    UIHelper.SetVisible(self.m.node, true)
    self.m.bIsShow = true
end

--将Tips移动到指定位置周围
function HoverTips:UpdatePosByXY(nX, nY)
    nX = nX or self.m.nLastX --若没有传入位置则使用上一次的位置
    nY = nY or self.m.nLastY
    if not nX or not nY then return end
    if not self.m.node then return end

    self.m.nLastX, self.m.nLastY = nX, nY
    local nPosX, nPosY = self:_getTipsPos(nX, nY)

    UIHelper.SetWorldPosition(self.m.node, nPosX, nPosY)
end

--将Tips移到到指定Node周围
function HoverTips:UpdatePosByNode(node)
    node = node or self.m.lastNode
    if not node then return end
    if not self.m.node then return end

    self.m.lastNode = node

    --根据Node数据拿到Node中心点和四个角的位置
    --以中心点作为点击位置
    --中心点到角的距离作为额外偏移值
    local nXMin, nXMax, nYMin, nYMax = UIHelper.GetNodeEdgeXY(node, true)
    local nSizeX, nSizeY = UIHelper.GetScaledContentSize(node)
    local nCenterX, nCenterY = (nXMin + nXMax) / 2, (nYMin + nYMax) / 2
    local nExtraOffsetX, nExtraOffsetY = nSizeX / 2, nSizeY / 2

    self:_setExtraOffset(nExtraOffsetX, nExtraOffsetY)
    self:UpdatePosByXY(nCenterX, nCenterY)
end

--更新显示位置
function HoverTips:Update()
    self:UpdatePosByXY()
end

--隐藏Tips
function HoverTips:Hide()
    UIHelper.SetVisible(self.m.node, false)
    self.m.bIsShow = false
end

--打印数据
function HoverTips:PrintData()
    if not self.m.node then
        LOG.INFO("Node is nil.")
    end

    local szData = "[HoverTips]\n"
    for k, v in pairs(self.m) do
        szData = szData .. tostring(k) .. ": " .. tostring(v) .. "\n"
    end
    LOG.INFO(szData)
end

--设置浮窗Node
function HoverTips:SetNode(node)
    node = node or self._rootNode
    self.m.node = node

    --初始化浮窗的锚点和尺寸数据
    self:SetNodeData()
end

--刷新Node数据
function HoverTips:SetNodeData(node)
    node = node or self.m.node
    if not node then return end


    self:SetSize(UIHelper.GetContentSize(node))
    self:SetAnchor(UIHelper.GetAnchorPoint(node))
end

--设置Tips显示方位（枚举：TipsLayoutDir）
function HoverTips:SetDisplayLayoutDir(nDir)
    self.m.nDisplayLayoutDir = nDir or TipsLayoutDir.AUTO
end

--设置自动Layout时，检测方向顺序
function HoverTips:SetAutoLayoutDirPriority(aDir, bAutoFill)
    self.m.aDirPriority = {}
    if IsTable(aDir) then
        for _, nDir in ipairs(aDir) do
            if table.contain_value(TipsLayoutDir, nDir) and nDir ~= TipsLayoutDir.AUTO then
                table.insert(self.m.aDirPriority, nDir)
            end
        end
    end

    --补齐剩余方向
    if bAutoFill then
        for _, nDir in ipairs(m_aDirPriority) do
            if not table.contain_value(self.m.aDirPriority, nDir) then
                table.insert(self.m.aDirPriority, nDir)
            end
        end
    end
end

--设置浮窗尺寸数据
function HoverTips:SetSize(nSizeX, nSizeY)
    local nScale = UIHelper.GetScale(self.m.node) or 1
    if nSizeX then self.m.nSizeX = nSizeX * nScale end
    if nSizeY then self.m.nSizeY = nSizeY * nScale end
end

--设置浮窗锚点数据
function HoverTips:SetAnchor(nAnchX, nAnchY)
    if nAnchX then self.m.nAnchX = nAnchX end
    if nAnchY then self.m.nAnchY = nAnchY end
end

--设置浮窗的显示限制区域
function HoverTips:SetSpace(nMinX, nMinY, nMaxX, nMaxY)
    if nMinX then self.m.nMinX = nMinX end
    if nMinY then self.m.nMinY = nMinY end
    if nMaxX then self.m.nMaxX = nMaxX end
    if nMaxY then self.m.nMaxY = nMaxY end
end

--设置点击位置与浮窗的偏移值，避免手指挡住浮窗内容
function HoverTips:SetOffset(nOffsetX, nOffsetY)
    if nOffsetX then self.m.nOffsetX = nOffsetX end
    if nOffsetY then self.m.nOffsetY = nOffsetY end
end

-------------------------------- Private --------------------------------

--设置额外偏移，用于标识点击Node时Node中心到四个顶点的距离
function HoverTips:_setExtraOffset(nExtraOffsetX, nExtraOffsetY)
    if nExtraOffsetX then self.m.nExtraOffsetX = nExtraOffsetX end
    if nExtraOffsetY then self.m.nExtraOffsetY = nExtraOffsetY end
end

--获取Tips在当前点击坐标和指定方向下的具体显示坐标
function HoverTips:_getPosByDir(nDir, nX, nY, nLeftX, nRightX, nTopY, nBottomY)
    local nPosX, nPosY
    if nDir == TipsLayoutDir.TOP_LEFT then
        nPosX, nPosY = nLeftX, nTopY
    elseif nDir == TipsLayoutDir.TOP_CENTER then
        nPosX, nPosY = nX + self.m.nSizeX * (self.m.nAnchX - 0.5), nTopY --以正中心对齐
    elseif nDir == TipsLayoutDir.TOP_RIGHT then
        nPosX, nPosY = nRightX, nTopY
    elseif nDir == TipsLayoutDir.LEFT_CENTER then
        nPosX, nPosY = nLeftX, nY + self.m.nSizeY * (self.m.nAnchY - 0.5)
    elseif nDir == TipsLayoutDir.RIGHT_CENTER then
        nPosX, nPosY = nRightX, nY + self.m.nSizeY * (self.m.nAnchY - 0.5)
    elseif nDir == TipsLayoutDir.BOTTOM_LEFT then
        nPosX, nPosY = nLeftX, nBottomY
    elseif nDir == TipsLayoutDir.BOTTOM_CENTER then
        nPosX, nPosY = nX + self.m.nSizeX * (self.m.nAnchX - 0.5), nBottomY
    elseif nDir == TipsLayoutDir.BOTTOM_RIGHT then
        nPosX, nPosY = nRightX, nBottomY
    elseif nDir == TipsLayoutDir.MIDDLE then
        nPosX, nPosY = nX + self.m.nSizeX * (self.m.nAnchX - 0.5), nY + self.m.nSizeY * (self.m.nAnchY - 0.5)
    end
    return nPosX, nPosY
end

--根据鼠标的位置获取浮窗位置
function HoverTips:_getTipsPos(nX, nY)
    local nPosX, nPosY

    local nOffsetX = self.m.nOffsetX + self.m.nExtraOffsetX
    local nOffsetY = self.m.nOffsetY + self.m.nExtraOffsetY

    --浮窗坐标最大最小值
    local nMinPosX = self.m.nMinX + self.m.nSizeX * self.m.nAnchX
    local nMaxPosX = self.m.nMaxX - self.m.nSizeX * (1 - self.m.nAnchX)
    local nMinPosY = self.m.nMinY + self.m.nSizeY * self.m.nAnchY
    local nMaxPosY = self.m.nMaxY - self.m.nSizeY * (1 - self.m.nAnchY)

    --各个能让浮窗有足够空间显示的浮窗坐标位置对应的x, y值 (worldPosition)
    local nLeftX = nX - nOffsetX - self.m.nSizeX * (1 - self.m.nAnchX)
    local nRightX = nX + nOffsetX + self.m.nSizeX * self.m.nAnchX
    local nTopY = nY + nOffsetY + self.m.nSizeY * self.m.nAnchY
    local nBottomY = nY - nOffsetY - self.m.nSizeY * (1 - self.m.nAnchY)

    if not self.m.nDisplayLayoutDir or self.m.nDisplayLayoutDir == TipsLayoutDir.AUTO then
        --自动方位布局，按优先级找到第一个有足够空间的位置

        local aDirPriority = self.m.aDirPriority or m_aDirPriority
        local bHasSpace = false
        local nMinNeedSpace, nMinDir
        for i = 1, #aDirPriority do
            local nDir = aDirPriority[i]
            nPosX, nPosY = self:_getPosByDir(nDir, nX, nY, nLeftX, nRightX, nTopY, nBottomY)

            if nPosX >= nMinPosX and nPosX <= nMaxPosX and nPosY >= nMinPosY and nPosY <= nMaxPosY then
                bHasSpace = true
                break
            else
                --当前空间不足，并求出仍需多少空间
                local nNeedSpace = (nMinPosX > nPosX and nMinPosX - nPosX or 0) +
                (nMaxPosX < nPosX and nPosX - nMaxPosX or 0) +
                (nMinPosY > nPosY and nMinPosY - nPosY or 0) +
                (nMaxPosY < nPosY and nPosY - nMaxPosY or 0)

                if not nMinNeedSpace or nNeedSpace < nMinNeedSpace then
                    nMinNeedSpace = nNeedSpace
                    nMinDir = nDir
                end
            end
        end

        --若都无足够空间，则使用需求空间最小的方向
        if not bHasSpace then
            nPosX, nPosY = self:_getPosByDir(nMinDir, nX, nY, nLeftX, nRightX, nTopY, nBottomY)
        end
    else
        --手动
        nPosX, nPosY = self:_getPosByDir(self.m.nDisplayLayoutDir, nX, nY, nLeftX, nRightX, nTopY, nBottomY)
    end

    -- --若无足够空间，则使用默认位置显示（正中心）
    -- if not nPosX or not nPosY then
    --     LOG.WARN("Tips does not has enough space to show. Use default position.")
    --     nPosX = self.m.nMinX + (self.m.nMaxX - self.m.nMinX) / 2
    --     nPosY = self.m.nMinY + (self.m.nMaxY - self.m.nMinY) / 2
    -- end

    --超出屏幕
    if nPosX < nMinPosX then
        nPosX = nMinPosX
    elseif nPosX > nMaxPosX then
        nPosX = nMaxPosX
    end
    if nPosY < nMinPosY then
        nPosY = nMinPosY
    elseif nPosY > nMaxPosY then
        nPosY = nMaxPosY
    end

    return nPosX, nPosY
end

return HoverTips