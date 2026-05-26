-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: ZsCachePatch
-- Date: 2024-06-18 10:10:39
-- Desc: 为了解决 zsCache/ver 目录 *.2 文件过多 造成解析卡 10% 的问题
--       做法就是：游戏启动、切场景、关闭商城界面的时候 删除这个目录的所有 *.2文件
-- ---------------------------------------------------------------------------------

ZsCachePatch = ZsCachePatch or {className = "ZsCachePatch"}
local self = ZsCachePatch
-------------------------------- 消息定义 --------------------------------
ZsCachePatch.Event = {}
ZsCachePatch.Event.XXX = "ZsCachePatch.Msg.XXX"

function ZsCachePatch.Init()
    self.DeleteAllDot2Files()

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelExteriorMain then
            self.DeleteAllDot2Files()
        end
    end)

    Event.Reg(self, EventType.OnAccountLogout, function()
        self.DeleteAllDot2Files()
    end)

    Event.Reg(self, "LOADING_END", function()
        self.DeleteAllDot2Files()
    end)

    -- 切后台
    Event.Reg(self, EventType.OnApplicationDidEnterBackground, function()
        self.DeleteAllDot2Files()
        --self.StartTick()
    end)

    -- 切前台
    Event.Reg(self, EventType.OnApplicationWillEnterForeground, function()
        --self.StopTick()
    end)

    -- 进入省电
    Event.Reg(self, EventType.OnEnterPowerSaveMode, function()
        self.DeleteAllDot2Files()
        self.StartTick()
    end)

    -- 退出省电
    Event.Reg(self, EventType.OnExitPowerSaveMode, function()
        self.StopTick()
    end)
end

function ZsCachePatch.UnInit()

end

function ZsCachePatch.StartTick()
    self.StopTick()

    self.nTimerID = Timer.AddCycle(self, 60, function()
        self.DeleteAllDot2Files()
    end)
end

function ZsCachePatch.StopTick()
    if self.nTimerID then
        Timer.DelTimer(self, self.nTimerID)
        self.nTimerID = nil
    end
end

function ZsCachePatch.DeleteAllDot2Files()
    LOG.INFO("[ZsCachePatch] begin -----------------------------")
    LOG.INFO("[ZsCachePatch] plat = %s, device model = %s", Platform.GetPlatformName(), tostring(Device.DeviceModel()))

    local fileUtils = cc.FileUtils:getInstance()

    local nLsStartTime = Timer.RealMStimeSinceStartup()
    local tbFileList = fileUtils:listFiles("zsCache/ver")
    if not tbFileList then
        return
    end
    LOG.INFO("[ZsCachePatch] ls time = "..(Timer.RealMStimeSinceStartup() - nLsStartTime))
    LOG.INFO("[ZsCachePatch] total nLen = "..#tbFileList)

    local nDelStartTime = Timer.RealMStimeSinceStartup()
    local nCount = 0
    for k, szFilePath in ipairs(tbFileList) do
        if szFilePath and string.sub(szFilePath, -2) == ".2" then
            local nLen = string.len(szFilePath)
            local szFileName = string.sub(szFilePath, 13, nLen - 2) or ""
            local nFileNum = tonumber(szFileName) or 0
            if nFileNum >= 10000000 or (nFileNum >= 300000 and nFileNum < 500000) then
                fileUtils:removeFile(szFilePath)
                nCount = nCount + 1
            end
        end
    end

    LOG.INFO("[ZsCachePatch] del count = %s, del time = %s", tostring(nCount), tostring(Timer.RealMStimeSinceStartup() - nDelStartTime))
    LOG.INFO("[ZsCachePatch] total time = "..(Timer.RealMStimeSinceStartup()) - nLsStartTime)
    LOG.INFO("[ZsCachePatch] finish -----------------------------")
end

