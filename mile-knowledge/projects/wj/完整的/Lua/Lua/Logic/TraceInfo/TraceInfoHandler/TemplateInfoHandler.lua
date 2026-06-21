local _M = {}
local self = _M

--信息追踪处理 模板
--_M.szInfoType = TraceInfoType.XXX

function _M.Init()
    self.RegEvent()

end

function _M.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)

end

function _M.RegEvent()

end

-- 更新UI显示
-- @param script 要显示内容的Widget上的脚本，用于存放部分数据
-- @param scrollViewParent 要显示内容的Widget上具体的ScrollView父节点
-- @param tData 触发OnTogTraceInfo事件时传入的参数tData
function _M.OnUpdateView(script, scrollViewParent, tData)

end

--清理
-- @param script 要显示内容的Widget上的脚本，用于存放部分数据
function _M.OnClear(script)

end

--------------------------------  --------------------------------



return _M