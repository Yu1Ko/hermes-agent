local UIMapScrollComponent = class("UIMapScrollComponent")

-- 根据UIMapTouchComponent修改的带有拖拽惯性/边缘阻尼/边缘回弹/聚焦放大动画的UIMapScrollComponent

-- 常量定义
local SCALE_RATE = 0.077
local SCALE_MAX = 2
local SCALE_MIN = 0.5
local INERTIA_DECELERATION = 0.9        -- 惯性减速率
local INERTIA_MIN_SPEED = 50            -- 最小速度阈值（像素/秒）
local VELOCITY_SAMPLE_TIME = 100        -- 速度采样时间窗口（毫秒）

function UIMapScrollComponent:Init(widget)
    self.widget = widget
    local size = widget:getContentSize()

    -- 移动区域边界
    self.nLeft = -size.width / 2
    self.nRight = size.width / 2
    self.nBottom = -size.height / 2
    self.nTop = size.height / 2

    -- 移动速度配置
    self.nSpeed = 1
    self.nMaxSpeed = 1
    self.nTweenTime = 0.3
    self.nScale = 1

    -- 事件回调表
    self.tbScaleEvent = {}
    self.tbPosEvent = {}

    -- 惯性相关变量
    self.nVelocityX = 0
    self.nVelocityY = 0
    self.bIsInertiaMoving = false
    self.nInertiaScheduler = nil

    -- 阻尼/回弹相关变量
    self.nDamping = 0.5
    self.nReboundScaleX = 0.2
    self.nReboundScaleY = 0.2
    self.nReboundScheduler = nil

    -- 触摸状态
    self.bIsTouching = false
    self.nTouchStartTime = 0
    self.nTouchX = 0
    self.nTouchY = 0

    -- 移动历史记录（记录位置和时间）
    self.tbMoveHistory = {}
    self.nMaxHistoryCount = 10
end

function UIMapScrollComponent:SetMoveRegion(nLeft, nRight, nBottom, nTop)
    self.nLeft = nLeft
    self.nRight = nRight
    self.nBottom = nBottom
    self.nTop = nTop
end

function UIMapScrollComponent:SetScaleLimit(nMin, nMax)
    self.nScaleMin = nMin
    self.nScaleMax = nMax
end

function UIMapScrollComponent:SetReboundScale(nReboundScaleX, nReboundScaleY)
    self.nReboundScaleX = nReboundScaleX
    self.nReboundScaleY = nReboundScaleY
end

function UIMapScrollComponent:SetPosition(nX, nY, bTween)
    self.nScale = self.nScale or 1

    local anchor = self.widget:getParent():getAnchorPointInPoints()
    local nOriX, nOriY = UIHelper.GetPosition(self.widget)

    nX, nY = self:ClampPosition(nX, nY)

    if bTween then
        local parent = UIHelper.GetParent(self.widget)
        if parent then
            local nPx, nPy = UIHelper.GetAnchorPoint(parent)
            local nPw, nPh = UIHelper.GetContentSize(parent)
            nX = nX + nPx * nPw
            nY = nY + nPy * nPh
        end

        local callback = cc.CallFunc:create(function()
            for nIndex, fnEvent in ipairs(self.tbPosEvent) do
                fnEvent(nX, nY)
            end
        end)

        local action = cc.Sequence:create(
            cc.EaseIn:create(cc.MoveTo:create(self.nTweenTime, cc.p(nX, nY)), self.nTweenTime),
            callback
        )
        self.widget:runAction(action)
    else
        UIHelper.SetPosition(self.widget, nX, nY)
        for nIndex, fnEvent in ipairs(self.tbPosEvent) do
            fnEvent(nX, nY)
        end
    end

    return nX ~= nOriX, nY ~= nOriY
end

function UIMapScrollComponent:ClampPosition(nX, nY, nScale)
    local nLeft, nRight, nBottom, nTop = self:GetClampBounds(nScale)

    nX = math.max(nX, nLeft)
    nX = math.min(nX, nRight)
    nY = math.max(nY, nBottom)
    nY = math.min(nY, nTop)

    return nX, nY
end

function UIMapScrollComponent:GetClampBounds(nScale)
    nScale = nScale or self.nScale or 1

    local tWinSize = UIHelper.GetWinSizeInPixels()
    local nRangeHeight = tWinSize.height
    local nRangeWidth = tWinSize.width

    if self.widgetRange then
        nRangeWidth, nRangeHeight = UIHelper.GetContentSize(self.widgetRange)
    end

    local anchor = self.widget:getParent():getAnchorPointInPoints()

    local nBottom = nRangeHeight + self.nBottom * nScale - anchor.y
    local nTop    = self.nTop * nScale - anchor.y
    local nLeft   = nRangeWidth + self.nLeft * nScale - anchor.x
    local nRight  = self.nRight * nScale - anchor.x

    return nLeft, nRight, nBottom, nTop
end

-- 阻尼计算
function UIMapScrollComponent:ApplyDamping(nPos, nMinPos, nMaxPos, nDelta, nReboundScale)
    -- nPos: 当前坐标
    -- nMinPos, nMaxPos: 最小/最大坐标
    -- nDelta: 本次位移
    -- nDampingRange: 阻尼触发范围，表示距离边界多远开始阻尼
    if nDelta == 0 then return 0 end
    nReboundScale = nReboundScale or 0
    local nDamping = self.nDamping or 0.5

    local nReboundRange = (nMaxPos - nMinPos) * nReboundScale

    if nDelta < 0 then
        local nDistToMin = nPos - nMinPos
        if nDistToMin < nReboundRange then
            local nT = nDistToMin / nReboundRange
            nT = math.max(0, math.min(1, nT))
            local nRatio = nT * nT * (3 - 2 * nT)
            return nDelta * math.max(nRatio, 0) * nDamping
        end
    else
        local nDistToMax = nMaxPos - nPos
        if nDistToMax < nReboundRange then
            local nT = nDistToMax / nReboundRange
            nT = math.max(0, math.min(1, nT))
            local nRatio = nT * nT * (3 - 2 * nT)
            return nDelta * math.max(nRatio, 0) * nDamping
        end
    end

    return nDelta
end

function UIMapScrollComponent:TryRebound()
    local nPosX, nPosY = UIHelper.GetPosition(self.widget)
    local nMinPosX, nMaxPosX, nMinPosY, nMaxPosY = self:GetClampBounds()
    local nReboundRangeX = (nMaxPosX - nMinPosX) * self.nReboundScaleX
    local nReboundRangeY = (nMaxPosY - nMinPosY) * self.nReboundScaleY

    local nTargetX = nPosX
    local nTargetY = nPosY

    local bNeedRebound = false

    local nMinSoftX = math.min(nMinPosX + (nReboundRangeX or 0), nMaxPosX)
    local nMaxSoftX = math.max(nMaxPosX - (nReboundRangeX or 0), nMinPosX)

    if nPosX < nMinSoftX then
        nTargetX = nMinSoftX
        bNeedRebound = true
    elseif nPosX > nMaxSoftX then
        nTargetX = nMaxSoftX
        bNeedRebound = true
    end

    local nMinSoftY = math.min(nMinPosY + (nReboundRangeY or 0), nMaxPosY)
    local nMaxSoftY = math.max(nMaxPosY - (nReboundRangeY or 0), nMinPosY)

    if nPosY < nMinSoftY then
        nTargetY = nMinSoftY
        bNeedRebound = true
    elseif nPosY > nMaxSoftY then
        nTargetY = nMaxSoftY
        bNeedRebound = true
    end

    if not bNeedRebound then
        return
    end

    self:StopInertia()
    self:StopRebound()
    self.widget:stopAllActions()

    local nTime = 0.25        -- 总动画时间
    local nElapsed = 0        -- 已过时间
    local nStartX, nStartY = nPosX, nPosY

    local scheduler = cc.Director:getInstance():getScheduler()
    self.nReboundScheduler = scheduler:scheduleScriptFunc(function(nDt)
        -- 如果正在触摸，停止回弹
        if self.bIsTouching then
            self:StopRebound()
            return
        end

        nElapsed = nElapsed + nDt
        local nT = math.min(nElapsed / nTime, 1)

        -- EaseBackOut 曲线：f(t) = 1 - (1 - t)^3
        local nEaseT = 1 - (1 - nT) * (1 - nT) * (1 - nT)

        local nCurX = nStartX + (nTargetX - nStartX) * nEaseT
        local nCurY = nStartY + (nTargetY - nStartY) * nEaseT

        UIHelper.SetPosition(self.widget, nCurX, nCurY)

        if nT >= 1 then
            self:StopRebound()
            -- 确保最终位置精确
            self:SetPosition(nTargetX, nTargetY)
        end
    end, 0, false)
end

function UIMapScrollComponent:StopRebound()
    if self.nReboundScheduler then
        local scheduler = cc.Director:getInstance():getScheduler()
        scheduler:unscheduleScriptEntry(self.nReboundScheduler)
        self.nReboundScheduler = nil
    end
end

function UIMapScrollComponent:MoveToNode(node)
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

    local nWx, nWy = UIHelper.ConvertToWorldSpace(pareNode, nX, nY)
    local nLx, nLy = UIHelper.ConvertToNodeSpace(self.widget, nWx, nWy)
    self:SetPosition(-nLx * self.nScale, -nLy * self.nScale, true)
end

function UIMapScrollComponent:MoveToNodeWithScale(node, nTargetScale, nTweenTime)
    if not safe_check(node) then
        return
    end

    nTweenTime = nTweenTime or self.nTweenTime or 0.3

    local pareNode = UIHelper.GetParent(node)
    local parentWidget = UIHelper.GetParent(self.widget)
    if not pareNode or not parentWidget then
        return
    end

    -- 当前 scale
    local nStartScale = self.nScale or 1
    nTargetScale = self:ClampScale(nTargetScale or nStartScale)

    -- 1. 计算目标位置
    local nX, nY = node:getPosition()
    local nWx, nWy = UIHelper.ConvertToWorldSpace(pareNode, nX, nY)
    local nLx, nLy = UIHelper.ConvertToNodeSpace(self.widget, nWx, nWy)

    local nTargetPosX = -nLx * nTargetScale
    local nTargetPosY = -nLy * nTargetScale

    nTargetPosX, nTargetPosY = self:ClampPosition(nTargetPosX, nTargetPosY, nTargetScale)

    -- 当前状态
    local nStartPosX, nStartPosY = UIHelper.GetPosition(self.widget)

    -- 停止旧动画
    self.widget:stopAllActions()

    -- 2. 自定义 tween（位置 + scale 同步）
    local nElapsed = 0

    local scheduler = cc.Director:getInstance():getScheduler()
    self.nMoveToScheduler = scheduler:scheduleScriptFunc(function(nDt)
        nElapsed = nElapsed + nDt
        local nT = math.min(nElapsed / nTweenTime, 1)

        -- 可换成 easeInOut
        local nEaseT = nT * nT * (3 - 2 * nT)

        -- 插值 scale
        local nCurScale = nStartScale + (nTargetScale - nStartScale) * nEaseT
        UIHelper.SetScale(self.widget, nCurScale, nCurScale)

        for _, fnEvent in ipairs(self.tbScaleEvent) do
            fnEvent(self.nScale)
        end

        -- 插值位置
        local nCurX = nStartPosX + (nTargetPosX - nStartPosX) * nEaseT
        local nCurY = nStartPosY + (nTargetPosY - nStartPosY) * nEaseT
        UIHelper.SetPosition(self.widget, nCurX, nCurY)

        -- 更新内部 scale
        self.nScale = nCurScale

        if nT >= 1 then
            scheduler:unscheduleScriptEntry(self.nMoveToScheduler)
            self.nMoveToScheduler = nil

            -- 修正最终状态
            self.nScale = nTargetScale
            UIHelper.SetScale(self.widget, nTargetScale, nTargetScale)
            self:SetPosition(nTargetPosX, nTargetPosY)

            -- 回调
            for _, fnEvent in ipairs(self.tbScaleEvent) do
                fnEvent(self.nScale)
            end
        end
    end, 0, false)
end

function UIMapScrollComponent:TouchBegin(nX, nY)
    -- 停止惯性运动
    self:StopInertia()
    self:StopRebound()

    local nLocalX, nLocalY = UIHelper.ConvertToNodeSpace(self.widget:getParent(), nX, nY)

    -- 设置触摸状态
    self.bIsTouching = true
    self.nTouchStartTime = GetTickCount()
    self.nTouchX = nLocalX
    self.nTouchY = nLocalY

    -- 重置速度和历史记录
    self.nVelocityX = 0
    self.nVelocityY = 0
    self.tbMoveHistory = {}

    -- 记录初始位置
    table.insert(self.tbMoveHistory, {
        nX = nLocalX,
        nY = nLocalY,
        nTime = self.nTouchStartTime
    })
end

function UIMapScrollComponent:TouchMoved(nX, nY)
    if not self.bIsTouching then
        return false
    end

    local nCurrentTime = GetTickCount()
    local nLocalX, nLocalY = UIHelper.ConvertToNodeSpace(self.widget:getParent(), nX, nY)
    local nPosX, nPosY = UIHelper.GetPosition(self.widget)

    local nDeltaX = nLocalX - self.nTouchX
    local nDeltaY = nLocalY - self.nTouchY

    -- 阻尼处理
    local nMinPosX, nMaxPosX, nMinPosY, nMaxPosY = self:GetClampBounds()
    nDeltaX = self:ApplyDamping(nPosX, nMinPosX, nMaxPosX, nDeltaX, self.nReboundScaleX)
    nDeltaY = self:ApplyDamping(nPosY, nMinPosY, nMaxPosY, nDeltaY, self.nReboundScaleY)

    -- 记录当前位置到历史
    table.insert(self.tbMoveHistory, {
        nX = nLocalX,
        nY = nLocalY,
        nTime = nCurrentTime
    })

    -- 只保留最近的记录
    if #self.tbMoveHistory > self.nMaxHistoryCount then
        table.remove(self.tbMoveHistory, 1)
    end

    -- 清理过期的历史记录（超过采样时间窗口2倍的）
    while #self.tbMoveHistory > 1 do
        local tbOldestRecord = self.tbMoveHistory[1]
        if nCurrentTime - tbOldestRecord.nTime > VELOCITY_SAMPLE_TIME * 2 then
            table.remove(self.tbMoveHistory, 1)
        else
            break
        end
    end

    self.nTouchX = nLocalX
    self.nTouchY = nLocalY

    local bFlag = false
    if nDeltaX ~= 0 or nDeltaY ~= 0 then
        bFlag = self:SetPosition(nPosX + nDeltaX * self.nSpeed, nPosY + nDeltaY * self.nSpeed)
    end

    return bFlag
end

function UIMapScrollComponent:TouchEnded(nX, nY)
    if not self.bIsTouching then
        return
    end

    self.bIsTouching = false

    -- 记录最后位置
    local nCurrentTime = GetTickCount()
    local nLocalX, nLocalY = UIHelper.ConvertToNodeSpace(self.widget:getParent(), nX, nY)
    table.insert(self.tbMoveHistory, {
        nX = nLocalX,
        nY = nLocalY,
        nTime = nCurrentTime
    })

    -- 使用最后一段时间的速度作为惯性速度
    self.nVelocityX, self.nVelocityY = self:CalculateVelocity()

    -- 计算速度大小
    local nSpeed = math.sqrt(self.nVelocityX * self.nVelocityX + self.nVelocityY * self.nVelocityY)

    -- 如果速度足够大，启动惯性滑动
    if nSpeed > INERTIA_MIN_SPEED then
        self:StartInertia()
    else
        self.nVelocityX = 0
        self.nVelocityY = 0
    end

    self:TryRebound()

    -- 清空历史记录
    self.tbMoveHistory = {}
end

function UIMapScrollComponent:TouchCanceled()
    if not self.bIsTouching then
        return
    end

    -- 立即停止所有运动
    self.bIsTouching = false
    self.nVelocityX = 0
    self.nVelocityY = 0
    self.tbMoveHistory = {}

    -- 停止惯性
    self:StopInertia()

    -- 停止所有动画
    if self.widget then
        self.widget:stopAllActions()
    end
end

-- 计算最后一段时间的平均速度
function UIMapScrollComponent:CalculateVelocity()
    if #self.tbMoveHistory < 2 then
        return 0, 0
    end

    local nCurrentTime = GetTickCount()
    local tbCurrentPos = self.tbMoveHistory[#self.tbMoveHistory]

    -- 找到采样时间窗口内最早的点
    local nStartIndex = #self.tbMoveHistory
    for i = #self.tbMoveHistory - 1, 1, -1 do
        local tbRecord = self.tbMoveHistory[i]
        if nCurrentTime - tbRecord.nTime <= VELOCITY_SAMPLE_TIME then
            nStartIndex = i
        else
            break
        end
    end

    -- 如果只有一个点或时间差太小，返回0
    if nStartIndex >= #self.tbMoveHistory then
        return 0, 0
    end

    local tbStartPos = self.tbMoveHistory[nStartIndex]
    local nDeltaTime = (tbCurrentPos.nTime - tbStartPos.nTime) / 1000  -- 转换为秒

    -- 时间差太小，避免除以0
    if nDeltaTime < 0.001 then
        return 0, 0
    end

    -- 计算平均速度（像素/秒）
    local nVelocityX = (tbCurrentPos.nX - tbStartPos.nX) / nDeltaTime
    local nVelocityY = (tbCurrentPos.nY - tbStartPos.nY) / nDeltaTime

    -- 限制最大速度
    local nMaxVelocity = self.nMaxSpeed * 2000
    local nSpeed = math.sqrt(nVelocityX * nVelocityX + nVelocityY * nVelocityY)
    if nSpeed > nMaxVelocity then
        local nScale = nMaxVelocity / nSpeed
        nVelocityX = nVelocityX * nScale
        nVelocityY = nVelocityY * nScale
    end

    return nVelocityX, nVelocityY
end

-- 启动惯性滑动
function UIMapScrollComponent:StartInertia()
    self:StopInertia()

    self.bIsInertiaMoving = true

    local scheduler = cc.Director:getInstance():getScheduler()
    self.nInertiaScheduler = scheduler:scheduleScriptFunc(function(nDt)
        self:UpdateInertia(nDt)
    end, 0, false)
end

-- 停止惯性滑动
function UIMapScrollComponent:StopInertia()
    if self.nInertiaScheduler then
        local scheduler = cc.Director:getInstance():getScheduler()
        scheduler:unscheduleScriptEntry(self.nInertiaScheduler)
        self.nInertiaScheduler = nil
    end
    self.bIsInertiaMoving = false
end

-- 更新惯性运动
function UIMapScrollComponent:UpdateInertia(nDt)
    if not self.bIsInertiaMoving then
        return
    end

    -- 如果正在触摸，停止惯性
    if self.bIsTouching then
        self:StopInertia()
        return
    end

    local nPosX, nPosY = UIHelper.GetPosition(self.widget)
    local nMinPosX, nMaxPosX, nMinPosY, nMaxPosY = self:GetClampBounds()
    local nReboundRangeX = (nMaxPosX - nMinPosX) * self.nReboundScaleX
    local nReboundRangeY = (nMaxPosY - nMinPosY) * self.nReboundScaleY

    -- 判断是否进入阻尼/回弹区域
    local nExtraDampingX, nExtraDampingY = 1, 1
    if nPosX < nMinPosX + nReboundRangeX or nPosX > nMaxPosX - nReboundRangeX then
        nExtraDampingX = 0.7  -- 可调：越界衰减更快
    end
    if nPosY < nMinPosY + nReboundRangeY or nPosY > nMaxPosY - nReboundRangeY then
        nExtraDampingY = 0.7
    end

    -- 应用惯性衰减（基础衰减 * 额外衰减）
    self.nVelocityX = self.nVelocityX * INERTIA_DECELERATION * nExtraDampingX
    self.nVelocityY = self.nVelocityY * INERTIA_DECELERATION * nExtraDampingY

    -- 计算速度大小
    local nSpeed = math.sqrt(self.nVelocityX * self.nVelocityX + self.nVelocityY * self.nVelocityY)

    -- 速度过小时停止
    if nSpeed < INERTIA_MIN_SPEED then
        self:StopInertia()
        self.nVelocityX = 0
        self.nVelocityY = 0
        self:TryRebound()
        return
    end

    -- 应用位移（速度单位是像素/秒，dt是秒）
    local nPosX, nPosY = UIHelper.GetPosition(self.widget)
    local nDeltaX = self.nVelocityX * nDt
    local nDeltaY = self.nVelocityY * nDt

    -- 阻尼处理
    nDeltaX = self:ApplyDamping(nPosX, nMinPosX, nMaxPosX, nDeltaX, self.nReboundScaleX)
    nDeltaY = self:ApplyDamping(nPosY, nMinPosY, nMaxPosY, nDeltaY, self.nReboundScaleY)

    local bXMoved, bYMoved = self:SetPosition(
        nPosX + nDeltaX * self.nSpeed,
        nPosY + nDeltaY * self.nSpeed
    )

    -- 如果碰到边界，停止对应方向的速度
    if not bXMoved then
        self.nVelocityX = 0
    end
    if not bYMoved then
        self.nVelocityY = 0
    end
end

function UIMapScrollComponent:SetInertiaParams(nDeceleration, nMinSpeed, nSampleTime)
    if nDeceleration then
        INERTIA_DECELERATION = nDeceleration
    end
    if nMinSpeed then
        INERTIA_MIN_SPEED = nMinSpeed
    end
    if nSampleTime then
        VELOCITY_SAMPLE_TIME = nSampleTime
    end
end

function UIMapScrollComponent:IsMoving()
    return self.bIsTouching or self.bIsInertiaMoving
end

function UIMapScrollComponent:GetVelocity()
    return self.nVelocityX, self.nVelocityY
end

function UIMapScrollComponent:Scale(nScale)
    self.nScale = self.nScale or 1
    nScale = self:ClampScale(nScale)

    local nPosX, nPosY = UIHelper.GetPosition(self.widget)
    local nDeltaScale = nScale / self.nScale

    UIHelper.SetScale(self.widget, nScale, nScale)

    self.nScale = nScale
    self:SetPosition(nPosX * nDeltaScale, nPosY * nDeltaScale)
    self:TryRebound()

    for _, fnEvent in ipairs(self.tbScaleEvent) do
        fnEvent(self.nScale)
    end
end

function UIMapScrollComponent:Zoom(nDelta)
    local nScale = self.nScale or 1

    -- 数值太小时不动，避免手机端轻微移动时就触发缩放
    if math.abs(nDelta) < 2 then
        return
    end

    if nDelta < 0 then
        nScale = nScale - SCALE_RATE
    else
        nScale = nScale + SCALE_RATE
    end

    self:Scale(nScale)
end

function UIMapScrollComponent:ClampScale(nScale)
    local nScaleMax = self.nScaleMax or SCALE_MAX
    local nScaleMin = self.nScaleMin or SCALE_MIN

    if nScale >= nScaleMax then
        nScale = nScaleMax
    end
    if nScale <= nScaleMin then
        nScale = nScaleMin
    end

    return nScale
end

function UIMapScrollComponent:RegisterScaleEvent(fnEvent)
    table.insert(self.tbScaleEvent, fnEvent)
end

function UIMapScrollComponent:RegisterPosEvent(fnEvent)
    table.insert(self.tbPosEvent, fnEvent)
end

function UIMapScrollComponent:SetRangeWidget(widgetRange)
    self.widgetRange = widgetRange
end

function UIMapScrollComponent:GetScale()
    return self.nScale or 1
end

function UIMapScrollComponent:SetMoveSpeed(nSpeed, nMaxSpeed)
    self.nSpeed = nSpeed
    self.nMaxSpeed = nMaxSpeed
end

function UIMapScrollComponent:SetTweenTime(nTweenTime)
    self.nTweenTime = nTweenTime
end

function UIMapScrollComponent:TouchMovedXY(nX, nY, bCanXAxisMove, bCanYAxisMove)
    bCanXAxisMove = bCanXAxisMove ~= false
    bCanYAxisMove = bCanYAxisMove ~= false

    local bXMoved, bYMoved = false, false
    if nX ~= 0 or nY ~= 0 then
        bXMoved, bYMoved = self:SetPosition(nX * self.nSpeed, nY * self.nSpeed)
    end

    return bXMoved, bYMoved
end

function UIMapScrollComponent:TweenToPos(nX, nY)
    if nX ~= 0 or nY ~= 0 then
        self:SetPosition(nX * self.nSpeed, nY * self.nSpeed, true)
    end
end

function UIMapScrollComponent:Dispose()
    self:StopInertia()
    self:StopRebound()
    self.tbScaleEvent = {}
    self.tbPosEvent = {}
    self.tbMoveHistory = {}
    self.bIsTouching = false
end

return UIMapScrollComponent
