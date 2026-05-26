AutoTestLog={}
AutoTestLog.file=nil
AutoTestLog.szLogPath=SearchPanel.szInterfacePath.."AutoTestLog.txt"
--用于替换LOG.INFO
--移除日志文件 避免覆盖
SearchPanel.RemoveFile(AutoTestLog.szLogPath)
function AutoTestLog.INFO(szLogInfo)
    -- body
    if not AutoTestLog.file then
        AutoTestLog.file=io.open(AutoTestLog.szLogPath,'a+')
    end
    LOG.INFO(szLogInfo)
    szLogInfo=szLogInfo..'\n'
    AutoTestLog.file:write(szLogInfo)
    AutoTestLog.file:flush()
end

--用于替换LoginMgr.Log
function AutoTestLog.Log(szTabName,szLogInfo)
    -- body
    if not AutoTestLog.file then
        AutoTestLog.file=io.open(AutoTestLog.szLogPath,'a+')
    end
    LOG.INFO(szLogInfo)
    szLogInfo='['..szTabName..'] '..szLogInfo..'\n'
    AutoTestLog.file:write(szLogInfo)
    AutoTestLog.file:flush()
end

function AutoTestLog.Error(msg)
    -- body
    AutoTestLog.INFO("----------------------------------------")
    AutoTestLog.INFO("LUA ERROR: " .. tostring(msg))
    AutoTestLog.INFO(debug.traceback())
    AutoTestLog.INFO("----------------------------------------")
end
