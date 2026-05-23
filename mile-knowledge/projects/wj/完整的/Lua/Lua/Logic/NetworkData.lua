-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: NetworkData
-- Date: 2023-12-25 08:57:42
-- Desc: ?
-- ---------------------------------------------------------------------------------

NetworkData = NetworkData or {className = "NetworkData"}
local self = NetworkData

local nNetworkRqstID = 0
local tRqstUrl = {
    --["CheckNetworkConnection_Baidu"] = "www.baidu.com",
    ["CheckNetworkConnection_Announcement"] = BulletinData.GetBulletinURL(BulletinType.Announcement),
    ["CheckNetworkConnection_System"] = BulletinData.GetBulletinURL(BulletinType.System),
}

local RQST_STATE = {
    REQUESTING = 1,
    FAILED = 2,
    SUCCESS = 3,
}

function NetworkData.Init()
    self.RegEvent()

    self.tRequestInfo = {}
    self.tRqstKeyConvert = {}
end

function NetworkData.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)
end

function NetworkData.RegEvent()
    Event.Reg(self, "CURL_REQUEST_RESULT", function(szKey, bSuccess, szContent, dwBufferSize)
        self.OnCURLRequestResult(szKey, bSuccess, szContent, dwBufferSize)
    end)
end

--检查网络连接是否通畅；有时即使连上了网络也无法实际访问网页，这里通过访问几个网页来确定网络情况
function NetworkData.CheckNetworkConnection(fnConnected, fnBlocked, nTimeOut)
    nTimeOut = nTimeOut or 3
    nNetworkRqstID = nNetworkRqstID + 1

    local tInfo = {
        nNetworkRqstID = nNetworkRqstID,
        fnConnected = fnConnected,
        fnBlocked = fnBlocked,
        tRqstState = {},
    }

    for szKey, szUrl in pairs(tRqstUrl) do
        local szRqstKey = szKey .. "_" .. nNetworkRqstID
        self.tRqstKeyConvert[szRqstKey] = nNetworkRqstID
        tInfo.tRqstState[szRqstKey] = RQST_STATE.REQUESTING
        self.Request(szRqstKey, szUrl, nTimeOut)
    end

    self.tRequestInfo[nNetworkRqstID] = tInfo
end

function NetworkData.Request(szKey, szUrl, nTimeOut)
    if not szUrl then
        return
    end

    --LOG.INFO("[NetworkData] Check Network Connection, Request: %s", szUrl)

    local bSSL = string.starts(szUrl, "https")
    CURL_HttpRqst(szKey, szUrl, bSSL, nTimeOut)
end

function NetworkData.OnCURLRequestResult(szKey, bSuccess, szContent, dwBufferSize)
    local nNetworkRqstID = self.tRqstKeyConvert[szKey]
    if not nNetworkRqstID then
        return
    end

    self.tRqstKeyConvert[szKey] = nil
    local tInfo = self.tRequestInfo[nNetworkRqstID]
    if not tInfo then
        return
    end

    tInfo.tRqstState[szKey] = bSuccess and RQST_STATE.SUCCESS or RQST_STATE.FAILED

    local bConnected = false
    for szRqstKey, nRqstState in pairs(tInfo.tRqstState) do
        if nRqstState == RQST_STATE.REQUESTING then
            return
        elseif nRqstState == RQST_STATE.SUCCESS then
            bConnected = true
        end
    end

    if bConnected and tInfo.fnConnected then
        tInfo.fnConnected()
    elseif not bConnected and tInfo.fnBlocked then
        tInfo.fnBlocked()
    end

    self.tRequestInfo[nNetworkRqstID] = nil
end