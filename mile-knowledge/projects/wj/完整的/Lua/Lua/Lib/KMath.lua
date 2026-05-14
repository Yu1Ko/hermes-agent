-- 一些数学计算
kmath = kmath or {}

local type, sqrt = type, math.sqrt
-- 局部缓存函数
local BitwiseAnd, BitwiseOr, SetNumberBit = BitwiseAnd, BitwiseOr, SetNumberBit
local kZpointToXy, kMetreLength = Const.kZpointToXy, Const.kMetreLength

---comment 逻辑距离转为米距离
---@param l number
---@return number
function kmath.to_metre(l)
    return l * kMetreLength
end

---comment 获取逻辑距离（逻辑单位）
---@param nLogicX number
---@param nLogicY number
---@param nLogicZ number|nil
---@return number
function kmath.logic_len(nLogicX, nLogicY, nLogicZ)
    nLogicZ = nLogicZ and nLogicZ / kZpointToXy or 0
    return sqrt(nLogicX * nLogicX + nLogicY * nLogicY + nLogicZ * nLogicZ)
end

---comment 获以米为单位的逻辑距离
---@param nLogicX number
---@param nLogicY number
---@param nLogicZ number|nil
---@return number len 米
function kmath.metre_len(nLogicX, nLogicY, nLogicZ)
    nLogicZ = nLogicZ and nLogicZ / kZpointToXy or 0
    return sqrt(nLogicX * nLogicX + nLogicY * nLogicY + nLogicZ * nLogicZ) * kMetreLength
end

function kmath.len2(pos1, pos2, pos3, pos4) -- pos1, pos2 or (x1, y1) (x2, y2)
    if type(pos1) == "table" then
        return sqrt((pos1.x - pos2.x) * (pos1.x - pos2.x) +
            (pos1.y - pos2.y) * (pos1.y - pos2.y))
    else
        return sqrt((pos1 - pos3) * (pos1 - pos3) + (pos2 - pos4) * (pos2 - pos4))
    end
end

function kmath.len3(pos1, pos2, pos3, pos4, pos5, pos6) -- pos1, pos2 or (x1, y1, z1) (x2, y2, z2)
    if type(pos1) == "table" then
        return sqrt((pos1.x - pos2.x) * (pos1.x - pos2.x) +
            (pos1.y - pos2.y) * (pos1.y - pos2.y) + (pos1.z - pos2.z) * (pos1.z - pos2.z))
    else
        return sqrt((pos1 - pos4) * (pos1 - pos4) + (pos2 - pos5) * (pos2 - pos5) + (pos3 - pos6) * (pos3 - pos6))
    end
end

function kmath.vec3_init(pos, x, y, z)
    pos.x = x
    pos.y = y
    pos.z = z
end

--[[
      |
   2  |  1
  __________ x
        |
   3  |   4
      y
  ]]
function kmath.coor_region(x, y)
    if x >= 0 and y >= 0 then
        return 1
    elseif x < 0 and y >= 0 then
        return 2
    elseif x < 0 and y < 0 then
        return 3
    else
        return 4
    end
end

--点乘
function kmath.dot(v1, v2)
     return v1.x * v2.x + v1.y * v2.y
end

--叉乘
--向量v1与向量v2的叉积>0，则向量v1在向量v2的顺时针方向
function kmath.cross(v1, v2)
     return v1.x * v2.y - v2.x * v1.y
end

function kmath.sub(v1, v2, out)
    -- body
    out = out or {}
    out.x = v1.x - v2.x
    out.y = v1.y - v2.y
    return out
end

function kmath.add(v1, v2, out)
    -- body
    out = out or {}
    out.x = v2.x + v1.x
    out.y = v2.y + v1.y
    return out
end

function kmath.normalize2(x, y)
    local len = sqrt(x * x + y * y)
    return x / len, y / len
end

function kmath.normalize3(x, y, z)
    local len = sqrt(x * x + y * y + z * z)
    return x / len, y / len, z / len
end

--判断一个点是否在一个复杂多边形的内部
function kmath.is_in_polygon(x, y, polygon)
    local inPolygon = false
    local polySides = #polygon
    local j = #polygon
    local start = 1

    --Output("is_in_polygon", polygon)
    if polygon[1].x then
        if polySides > 3 and (polygon[2].x == polygon[polySides].x and polygon[2].y == polygon[polySides].y) then
            start = 2
        end

        for i=start, polySides, 1 do
            if (
                (polygon[i].y < y and polygon[j].y >= y or polygon[j].y < y and polygon[i].y >= y) and
                (polygon[i].x <= x or polygon[j].x <= x) ) then

                if ( polygon[i].x + (y - polygon[i].y) / (polygon[j].y - polygon[i].y) * (polygon[j].x - polygon[i].x) < x) then
                     inPolygon = not inPolygon
                end
            end
            j = i
        end
    else
        if polySides > 3 and (polygon[2][1] == polygon[polySides][1] and polygon[2][2] == polygon[polySides][2]) then
            start = 2
        end

        for i=start, polySides, 1 do
            if (
                (polygon[i][2] < y and polygon[j][2] >= y or polygon[j][2] < y and polygon[i][2] >= y) and
                (polygon[i][1] <= x or polygon[j][1] <= x) ) then

                if ( polygon[i][1] + (y - polygon[i][2]) / (polygon[j][2] - polygon[i][2]) * (polygon[j][1] - polygon[i][1]) < x) then
                     inPolygon = not inPolygon
                end
            end
            j = i
        end
    end

    return inPolygon
end

--当p3在直线p1p2上时，OnSegment函数用于确认p3在上，还是在的延长线上。
local function is_in_line(p1, p2, p3)
    local x_min, x_max, y_min, y_max

    if (p1.x < p2.x) then
        x_min = p1.x
        x_max = p2.x
    else
        x_min = p2.x
        x_max = p1.x
    end

    if (p1.y < p2.y) then
        y_min = p1.y
        y_max = p2.y

    else
        y_min = p2.y
        y_max = p1.y
    end

    if (p3.x < x_min or p3.x > x_max or p3.y < y_min or p3.y > y_max) then
        return false
    else
        return true
    end
end

--判断2线段是否相交
function kmath.is_2line_intersect(p1, p2, p3, p4)
    local d1 = kmath.cross( kmath.sub(p1, p3),  kmath.sub(p4, p3) )
    local d2 = kmath.cross( kmath.sub(p2, p3),  kmath.sub(p4, p3) )
    local d3 = kmath.cross( kmath.sub(p3, p1),  kmath.sub(p2, p1) )
    local d4 = kmath.cross( kmath.sub(p4, p1),  kmath.sub(p2, p1) )

    if (d1 * d2 < 0 and d3 * d4 < 0)  then
        return true
    elseif (d1==0 and is_in_line(p3,p4,p1)) then
        return true
    elseif (d2==0 and is_in_line(p3,p4,p2)) then
        return true
    elseif (d3==0 and is_in_line(p1,p2,p3)) then
        return true
    elseif (d4==0 and is_in_line(p1,p2,p4)) then
        return true
    end

    return false
end

-- * 保留小数点后面几位
function kmath.dcl_point(value, n)
    n = n or 0

    local power = 10 ^ n
    return math.floor(value * power) / power;
end

-- * 保留小数点后面几位, 会四舍五入的进位
function kmath.dcl_wpoint(value, n)
    n = n or 0
    return string.format("%g", string.format("%." .. n .. "f", value))
end

-- return (lh & rh)
function kmath.bit_and(lh, rh)
    return BitwiseAnd(lh, rh)
end

-- return (lh | rh)
function kmath.bit_or(lh, rh)
    return BitwiseOr(lh, rh)
end

-- return ( lh | (1 << (bit_pos - 1)) )
function kmath.add_bit(lh, bit_pos)
    return SetNumberBit(lh, bit_pos, true)
end

-- return ( lh & ~(1 << (bit_pos - 1)) )
function kmath.del_bit(lh, bit_pos)
    return SetNumberBit(lh, bit_pos, false)
end

-- * 判断某一位上的值是否为 1
function kmath.is_bit1(lh, bit_pos)
    local v = kmath.add_bit(0, bit_pos)
    return (kmath.bit_and(lh, v) ~= 0)
end

-- * 逻辑上是从0位开始的，UI之前是从1位开始的很怪，包一个新的用来判断逻辑传值某一位上的值是否为 1
function kmath.is_logicbit1(lh, bit_pos)
	return kmath.is_bit1(lh, bit_pos + 1)
end

-- * 输出某一位上的值
function kmath.get_bit(lh, bit_pos)
    local v = kmath.add_bit(0, bit_pos)
    return kmath.bit_and(lh, v)
end

--Lua封装位运算符
local function __andBit(left, right)    --与
    return (left == 1 and right == 1) and 1 or 0
end

local function __orBit(left, right)    --或
    return (left == 1 or right == 1) and 1 or 0
end

local function __xorBit(left, right)   --异或
    return (left + right) == 1 and 1 or 0
end

local function __base(left, right, op) --对每一位进行op运算，然后将值返回
    if left < right then
        left, right = right, left
    end
    local res = 0
    local shift = 1
    while left ~= 0 do
        local ra = left % 2    --取得每一位(最右边)
        local rb = right % 2
        res = shift * op(ra,rb) + res
        shift = shift * 2
        left = math.modf( left / 2)  --右移
        right = math.modf( right / 2)
    end
    return res
end

function kmath.andOperator(left, right)
    return __base(left, right, __andBit)
end

function kmath.xorOperator(left, right)
    return __base(left, right, __xorBit)
end

function kmath.orOperator(left, right)
    return __base(left, right, __orBit)
end

function kmath.notOperator(left)
    return left > 0 and -(left + 1) or -left - 1
end

function kmath.lShiftOperator(left, num)  --left左移num位
    return left * (2 ^ num)
end

function kmath.rShiftOperator(left,num)  --right右移num位
    return math.floor(left / (2 ^ num))
end

---comment 欧拉交转四元数
---@param pitch number x方向旋转弧度
---@param yaw number y方向旋转弧度
---@param roll number z方向旋转弧度
---@return table
function kmath.fromEuler(pitch, yaw, roll)
    local sinX = math.sin(pitch * 0.5);
    local cosX = math.cos(pitch * 0.5);
    local sinY = math.sin(yaw * 0.5);
    local cosY = math.cos(yaw * 0.5);
    local sinZ = math.sin(roll * 0.5);
    local cosZ = math.cos(roll * 0.5);
    return {x = cosY * sinX * cosZ + sinY * cosX * sinZ,
        y = sinY * cosX * cosZ - cosY * sinX * sinZ,
        z = cosY * cosX * sinZ - sinY * sinX * cosZ,
        w = cosY * cosX * cosZ + sinY * sinX * sinZ
    }
end

-- 斜率(nX/ny)对应的逻辑角度值(0~64°)
local TAN_VALUE_TABLE = { --64位
    0,                  0.024548622108925,  0.049126849769467,  0.073764431522449,  0.098491403357164,  0.12333823613674,   0.14833598753835,   0.17351646013786,
    0.19891236737966,   0.22455750931713,   0.25048696019131,   0.27673727014041,   0.30334668360734,   0.33035537734433,   0.35780572131452,   0.38574256627112,
    0.4142135623731,    0.44326951389086,   0.47296477589132,   0.50335769979929,   0.53451113595079,   0.56649300273034,   0.59937693368192,   0.63324301617757,
    0.6681786379193,    0.70427946086504,   0.74165054627204,   0.78040765965394,   0.82067879082866,   0.86260593225674,   0.90634716901915,   0.95207914670093,
    1,                  1.0503328462399,    1.1033299757335,    1.1592779073334,    1.218503525588,     1.2813815800366,    1.3483439134867,    1.4198909034941,
    1.4966057626655,    1.5791725679602,    1.6683992055835,    1.7652468700942,    1.8708684117894,    1.9866587923434,    2.1143223575486,    2.2559638519292,
    2.4142135623731,    2.5924025177381,    2.7948127724905,    3.0270432043178,    3.2965582089383,    3.6135356813074,    3.9922237837701,    4.4532022244144,
    5.0273394921258,    5.7631420051188,    6.741452405415,     8.1077858036769,    10.153170387609,    13.556669242352,    20.355467624987,    40.735483872083,
}
local TAN_VALUE_TABLE_LEN = #TAN_VALUE_TABLE
local _dichotomy
function _dichotomy(nMin, nMax, nTargetValue)
    local nMiddle = math.floor((nMin + nMax) / 2)
    local nValue = TAN_VALUE_TABLE[nMiddle]

    if nMiddle == nMin then
        local nMaxValue = TAN_VALUE_TABLE[nMax]
        if nMaxValue <= nTargetValue then
            return nMax
        else
            return nMin
        end
    end

    if nValue == nTargetValue then
        return nMiddle
    elseif nValue > nTargetValue then
        return _dichotomy(nMin, nMiddle, nTargetValue)
    else
        return _dichotomy(nMiddle, nMax, nTargetValue)
    end
end

---comment 快速tan角度计算(逻辑角度)
---@param nSlope number x/y斜率
---@return integer logic_dir 逻辑角度(0-64)
function kmath.fastArcTan(nSlope)
    local nMin, nMax = 1, TAN_VALUE_TABLE_LEN
    return _dichotomy(nMin, nMax, nSlope) - 1
end

---comment
---@param r number red
---@param g number green
---@param b number blue
---@param a number|nil alpha
---@return integer 32_bit_color
function kmath.fromRGBA(r, g, b, a)
    r = math.floor(r * 255)
    g = math.floor(g * 255)
    b = math.floor(b * 255)
    a = math.floor((a or 1) * 255)
    return a * (2^24) + r * (2^16) + g * (2^8) + b
end
