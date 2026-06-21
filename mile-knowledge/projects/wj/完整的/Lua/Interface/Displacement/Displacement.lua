-- 副本人物跑动实现接口
Displacement = {}
Displacement.nXcenter = 0
Displacement.nYcenter = 0
Displacement.nZcenter = 0
Displacement.nDistance=1000 --距离中心点半径


function Displacement.SetCenterPoint(nX,nY,nZ)
    Displacement.nXcenter = nX
    Displacement.nYcenter = nY
    Displacement.nZcenter = nZ
end

function Displacement.SenDistance(nDistance)
    Displacement.nDistance=nDistance
end

-- 根据中心点,半径,角度 推算出坐标
function Displacement.GetAngle(nRadius,nAngle)
    local angle_rad = math.rad(nAngle)  -- 角度转弧度
    local x = Displacement.nXcenter + nRadius * math.cos(angle_rad)
    local y = Displacement.nYcenter + nRadius * math.sin(angle_rad)
    return x, y
end

Displacement.tbCustom = {}
-- 根据角度算出全部坐标
function Displacement.GetPoint()
    for i=0,360,60 do
        local nXpoint ,nYpoint = Displacement.GetAngle(Displacement.nDistance,i)
        local tbCoordinate = {
            nXpoint,
            nYpoint,
            Displacement.nZcenter,
        }
        table.insert(Displacement.tbCustom,tbCoordinate)
    end
end

-- 设置范围
function Displacement.SetPoint(nRange)
    local nRangeNum = tonumber(nRange)
    for i=0,360,60 do
        local nXpoint ,nYpoint = Displacement.GetAngle(nRangeNum,i)
        local tbCoordinate = {
            nXpoint,
            nYpoint,
            Displacement.nZcenter,
        }
        table.insert(Displacement.tbCustom,tbCoordinate)
    end
end

-- 帧函数
Displacement.bPlayerMove = false
function Displacement.FrameUpdate()
    if not Displacement.bPlayerMove then
        --开启跑图 并帧更新判断跑图是否结束 将执行CMD的帧更新停止
        CustomRunMapByData.Start(Displacement.tbCustom)
        Displacement.bPlayerMove = true
        return
    end
    if CustomRunMapByData.IsEnd() then
        -- 重置下次跑图的点数
        Displacement.bPlayerMove = false
    end
end
-- 跑动结束
function Displacement.Stop()
    Timer.DelAllTimer(Displacement)
    Displacement.tbCustom = {}
end
-- 跑动开始
function Displacement.Start()
    Timer.AddCycle(Displacement,1,function ()
        Displacement.FrameUpdate()
    end)
end