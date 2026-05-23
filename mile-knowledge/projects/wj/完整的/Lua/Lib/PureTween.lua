
--[[
    缓动回调类
--]]
PureTween = {}
local M = PureTween

----------------------------------------------------------
function PureTween.tween(duration, callbacks, data, ease)
    return {
        _duration = duration or 0,
        _elapse = 0,
        _callbacks = callbacks,
        _data = data,
        _ease = ease,
        _status = 0, -- 0开始 1运行 2结束 3停止	

        --
        isDone = function (self)
            return 3 == self._status	
        end,

        --
        reset = function (self)
            self._status = 0			
        end,

        --
        finish = function (self)			
            while not self:isDone() do
                self:update(0x7fffffff)							
            end
        end,

        --
        update = function (self, dt)
            local cbs = self._callbacks
            -- beg
            if 0 == self._status then			
                dt = 0
                self._elapse = 0
                self._status = self._status + 1
                if cbs and cbs.b then cbs.b(self._data) end
            end
            -- run
            if 1 == self._status then
                local percent = 1
                self._elapse = self._elapse + dt
                if self._elapse >= self._duration then					
                    self._status = self._status + 1
                else
                    if self._duration > 0 then						
                        percent = self._elapse / self._duration
                        if self._ease then percent = self._ease:easing(percent) end
                    end					
                end
                if cbs and cbs.r then cbs.r(self._data, percent) end
            end
            -- end
            if 2 == self._status then
                self._status = self._status + 1
                if cbs and cbs.e then cbs.e(self._data) end			 
            end			   
        end
    }
end

----------------------------------------------------
function PureTween.sequence(tweenArr, bLoop)
     return {
        _bLoop = bLoop,
        _bDone = false,
        _tweenArr = tweenArr or {},
        _nIndex = 1,

        --
        isDone = function (self)
            return not self._bLoop and self._bDone
        end,

        --
        reset = function (self)
            self._bDone = false
            self._nIndex = 1
            for _,v in ipairs(self._tweenArr) do
                v:reset()
            end
        end,	 

        --
        finish = function (self)
            self._bLoop = false
            while not self:isDone() do
                self:update(0x7fffffff)							
            end
        end,

        --
        update = function (self, dt)
            -- done
            if self._bDone then return end

            -- run
            repeat
                -- is done
                if self._nIndex > #self._tweenArr then
                    if self._bLoop then
                        self:reset()
                    else
                        self._bDone = true
                        break
                    end
                end

                local tween = self._tweenArr[self._nIndex] if not tween then break end				
                tween:update(dt)
                if not tween:isDone() then break end

                self._nIndex = self._nIndex + 1
            until false
        end
     }
end


----------------------------------------------------
function PureTween.concurrent(sequenceArr, bLoop)
     return {		
        _bLoop = bLoop,		
        _sequenceArr = sequenceArr or {},	

        -- 
        add = function (self, sequence)
            table.insert(self._sequenceArr, sequence)
        end,

        --
        isDone = function (self)
            for _,v in ipairs(self._sequenceArr) do
                if not v:isDone() then
                    return false
                end
            end
            return not self._bLoop
        end,

        --
        reset = function (self)			
            for _,v in ipairs(self._sequenceArr) do
                v:reset()
            end
        end,	 

        --
        finish = function (self)			
            self._bLoop = false
            for _,v in ipairs(self._sequenceArr) do
                v:finish()
            end
        end,

        --
        update = function (self, dt)	
            -- done		
            if self:isDone() then
                -- end
                if not self._bLoop then return end

                -- loop
                self:reset()					
            end

            -- run
            for _,v in ipairs(self._sequenceArr) do
                v:update(dt)
            end
        end
     }
end


-----------------------------------------------
function PureTween.easeIn(rate)
    return {
        _rate = rate,
        easing = function (self, p)
            return math.pow(p, self._rate)	
        end
    }
end

--
function PureTween.easeOut(rate)
    return {
        _rate = rate,
        easing = function (self, p)            
            return 1 - math.Pow(1 - p, self._rate)
        end   
    }
end

--
function PureTween.easeInOut(rate)
    return {
        _rate = rate,
        easing = function (self, p)
            p = p * 2
            if p < 1 then
                return 0.5 * math.pow(p, self._rate)
            else
                return 1 - 0.5 * math.pow(2 - p, self._rate)
            end			
        end
    }
end

--
function PureTween.easeExponentialIn()
    return {
        easing = function (self, p)
            return 0 == p and 0 or math.pow(2, 10 * (p - 1))
        end		
    }
end

--
function PureTween.easeExponentialOut()
    return {
        easing = function (self, p)
            return 1 == p and 1 or (-(math.pow(2, -10 * p)) + 1)
        end
    }
end

--
function PureTween.easeExponentialInOut()
    return {
        easing = function (self, p)
            if p ~= 1 and p ~= 0 then
                p = p * 2
                if p < 1 then
                    return 0.5 * math.pow(2, 10 * (p - 1))
                else
                    return 0.5 * (-math.pow(2, -10 * (p - 1)) + 2)
                end
            end
            return p			
        end
    }
end

--
function PureTween.easeSineIn()
    return {
        easing = function (self, p)
            return (p == 0 or p == 1) and p or -1 * math.cos(p * math.pi / 2) + 1
        end
    }
end

--
function PureTween.easeSineOut()
    return {
        easing = function (self, p)
            return (p == 0 or p == 1) and p or math.sin(p * math.pi / 2)
        end
    }
end

--
function PureTween.easeSineInOut()
    return {
        easing = function (self, p)
            return (p == 0 or p == 1) and p or -0.5 * (math.cos(math.pi * p) - 1)
        end
    }
end

--
function PureTween.easeElasticIn()
    return {
        easing = function (self, p)
            if p == 0 or p == 1 then return p end
            p = p - 1
            return -math.pow(2, 10 * p) * math.sin((p - (0.3 / 4)) * math.pi * 2 / 0.3)
        end
    }
end

--
function PureTween.easeElasticOut()
    return {
        easing = function (self, p)
            if p == 0 or p == 1 then return p end
            p = p - 1
            return (p == 0 or p == 1) and p or math.pow(2, -10 * p) * math.sin((p - (0.3 / 4)) * math.pi * 2 / 0.3) + 1
        end
    }
end

--
function PureTween.easeElasticInOut(period)
    return {
        _period = period,
        easing = function (self, p)
            local newT = 0
            local locPeriod = self._period
            if p == 0 or p == 1 then
                newT = p
            else
                p = p * 2			
                --locPeriod = locPeriod or 0.3 * 1.5
                local s = locPeriod / 4
                p = p - 1
                if p < 0 then
                    newT = -0.5 * math.pow(2, 10 * p) * math.sin((p - s) * math.pi * 2 / locPeriod)
                else
                    newT = math.pow(2, -10 * p) * math.sin((p - s) * math.pi * 2 / locPeriod) * 0.5 + 1
                end
            end
            return newT			
        end
    }
end


--
function PureTween.easeCubicIn()
    return {
        easing = function (self, p)
            return p * p * p
        end
    }
end


--
function PureTween.easeCubicOut()
    return {
        easing = function (self, p)
            p = p - 1
            return p * p * p + 1			
        end
    }
end


--
function PureTween.easeCubicInOut()
    return {
        easing = function (self, p)
            p = p * 2
            if p < 1 then
                return 0.5 * p * p * p
            end
            p = p - 2
            return 0.5 * (p * p * p + 2)			
        end
    }
end


--------------------------------------------------------------------

function PureTween.delay(nDuration, callback, data)		
    return M.tween(nDuration or 0,
        {
            e = function (data)				
                if callback then
                    callback(data)
                end
            end
        }, 
        data
    )
end

function PureTween.scaleTo(node, targetScale, nDuration, ease)
    assert(node)
    return M.tween(nDuration,
        {
            b = function (data)   
                data.originScale.x = UIHelper.GetScaleX(data.node)
                data.originScale.y = UIHelper.GetScaleY(data.node)
            end,				
            r = function (data, p)
                UIHelper.SetScale(data.node, 
                    data.originScale.x * (1 - p) + data.targetScale.x * p,
                    data.originScale.y * (1 - p) + data.targetScale.y * p)                
            end
        }, 
        {
            node = node,
            targetScale = targetScale,			
        }, 
        ease
    )
end

function PureTween.fadeIn(node, nDuration, ease)
    assert(node)
    return M.tween(nDuration,
        {
            r = function (data, p)
                UIHelper.SetOpacity(data.node, 255 * (1 - p))                
            end
        }, 
        {
            node = node,
        }, 
        ease
    )
end

function PureTween.fadeOut(node, nDuration, ease)
    assert(node)
    return M.tween(nDuration,
        {
            r = function (data, p)	 
                UIHelper.SetOpacity(data.node, 255 * p)                
            end
        }, 
        {
            node = node,
        }, 
        ease
    )
end

---@class 移动物体一段距离
---@node 移动的物体 tranform
---@addPos 移动的增量
---@nDuration 事件
---@ease 缓动的类型 默认为匀速
function PureTween.moveBy(node, addPos, nDuration, ease)
    assert(node)
    return M.tween(nDuration,
        {
            b = function (data)                   
                data.originPos = cc.p(UIHelper.GetPosition(data.node))
                data.targetPos = data.originPos + data.addPos
            end,		  
            r = function (data, p)
                UIHelper.SetPosition(data.node,
                    data.originPos.x * (1 - p) + data.targetPos.x * p,
                    data.originPos.y * (1 - p) + data.targetPos.y * p)				
            end
        }, 
        {
            node = node,
            addPos = addPos,			
        }, 
        ease
    )
end


function PureTween.moveTo(node, targetPos, nDuration, ease)
    assert(node)
    return M.tween(nDuration,
        {
            b = function (data)   
                data.originPos = cc.p(UIHelper.GetPosition(data.node))
            end,		
            r = function (data, p)				
                UIHelper.SetPosition(data.node,
                    data.originPos.x * (1 - p) + data.targetPos.x * p,
                    data.originPos.y * (1 - p) + data.targetPos.y * p)					   
            end
        }, 
        {
            node = node,
            targetPos = targetPos,
        }, 
        ease
    )
end

function PureTween.moveTo_parabola(node, peakPos, targetPos, nDuration, ease)
    assert(node)
    return M.tween(nDuration,
        {
            b = function (data)   
                data.originPos = cc.p(UIHelper.GetPosition(data.node))
                data.a, data.b, data.c = M._computeParabola(data.originPos, data.peakPos, data.targetPos)			
                data.dx = data.targetPos.x - data.originPos.x
                data.dy = data.targetPos.y - data.originPos.y			 
            end,
            r = function (data, p)
                if 1 == p then
                    UIHelper.SetPosition(data.node, data.targetPos.x, data.targetPos.y)                    
                else
                    local x = data.originPos.x + data.dx * p					
                    local y = data.a * x * x + data.b * x + data.c
                    UIHelper.SetPosition(data.node, x, y)
                end				
            end
        },
        {
            node = node,
            peakPos = peakPos,
            targetPos = targetPos,
        },
        ease
    )
end

function PureTween._computeParabola(originPos, peakPos, targetPos)	
    local x1, x2, x3 = originPos.x, peakPos.x, targetPos.x
    local y1, y2, y3 = originPos.y, peakPos.y, targetPos.y
    local x22_x33 = x2*x2 - x3*x3
    local x11_x22 = x1*x1 - x2*x2
    local tmp = (x22_x33 * (x1 - x2) - x11_x22 * (x2 - x3))
    local b = (x22_x33 * (y1 - y2) - x11_x22 * (y2 - y3)) / (0 == tmp and 1 or tmp) 
    local a = (y1 - y2 - b * (x1 - x2)) / (0 == x11_x22 and 1 or x11_x22)
    local c = y1 - a * x1 * x1 - b * x1
    return a, b, c	
end