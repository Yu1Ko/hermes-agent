-- 基于 ui/Script/MergedServer.lua 修改
------------------------------------------------
-- 所有合服相关的数据预处理
-- @Author: Unkonwn
-- @Date:   Unkonwn
-- @Email:  root@derzh.com
-- @Project: JX3 UI
-- @Last modified by:   Zhai Yiming
-- @Last modified time: 2017-04-18 10:56:35
------------------------------------------------
--UILog("====================load MergedServer.lua===================================================", debug.traceback())

MergedServer = MergedServer or {}

local l_mergedRankingLoadingList = nil
MergedServer.tMergedRanking = setmetatable({}, {
    __index = function(t, szServerGBK)
        if not l_mergedRankingLoadingList then
            l_mergedRankingLoadingList = LoadLUAData("ui/MergedServer/MergedRankingLoadingList.jx3dat", true)
        end

        local szPath = l_mergedRankingLoadingList[szServerGBK]
        if not szPath then
            return
        end

        local data = LoadLUAData(szPath)
        if not data then
            return
        end
        t[szServerGBK] = data
        return data
    end,
})

local l_gatewayServerMapping = nil
function MergedServer.GetGatewayServer(szServerGBK)
    if not l_gatewayServerMapping then
        l_gatewayServerMapping = LoadLUAData("ui/MergedServer/GatewayServerMapping.jx3dat", true)
    end

    local server = l_gatewayServerMapping[szServerGBK]
    if not server then
        return szServerGBK
    end
    return server
end

local l_interworkingServerInfo = nil
function MergedServer.GetInterworkingServers(szServerUTF8)
    local szServerGBK = UIHelper.UTF8ToGBK(szServerUTF8)

    szServerGBK       = MergedServer.GetGatewayServer(szServerGBK)

    if not l_interworkingServerInfo then
        l_interworkingServerInfo = LoadLUAData("ui/MergedServer/InterworkingServerInfo.jx3dat", true)
    end

    local serverlist  = l_interworkingServerInfo[szServerGBK]
    if not serverlist then
        return {{ szServerGBK }}
    end
    return clone(serverlist)
end