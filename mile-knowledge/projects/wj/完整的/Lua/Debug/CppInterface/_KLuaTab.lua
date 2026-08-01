-- KLuaDynTab.cpp

---@class KLuaTab LuaTab表C++对象
local KLuaTab = {}

---@class KG_Table 操作Lua表的接口
KG_Table = {}

---comment 获取表的行数
---@return integer rowNum
function KLuaTab:GetRowCount() return 0 end

---comment 获取表指定行数据
---@param row integer 行号
---@return table|nil rowData
function KLuaTab:GetRow(row) return {} end

---comment 获取已排序表的指定索引数据
---@param index integer 排序后的索引
---@return table|nil rowData
function KLuaTab:GetSorted(index) return {} end

---comment 按Key值列表搜索数据
---@param ... any tab表的前N项值, N最大值不能超过8
---@return any|nil rowData 查找到的第项匹配数据
---@return integer|nil index 排序后的索引
function KLuaTab:Search(...) return {}, 0 end

---comment 根据过滤器搜索数据
---@param filter table 指定过滤器{k1=v1, k2=v2}
---@param index integer|nil 起始索引（排序后的索引）
---@return table|nil rowData
---@return integer|nil index
function KLuaTab:LinearSearch(filter, index) return {}, 0 end

---comment 获取指定键值的范围，返回已排序后的索引[firstIdex, lastIndex]，需通过GetSorted获取行数据
---@param key1 table 键值1
---@param key2 table|nil 键值2
---@return integer firstIndex 起始索引
---@return integer lastIndex 结束索引
function KLuaTab:Range(key1, key2) return 0, 0 end
