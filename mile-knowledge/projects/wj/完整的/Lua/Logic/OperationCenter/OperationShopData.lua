-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: OperationShopData
-- Date: 2026-03-26 11:30:02
-- Desc: ?
-- ---------------------------------------------------------------------------------

OperationShopData = OperationShopData or {className = "OperationShopData"}
local self = OperationShopData
-------------------------------- 消息定义 --------------------------------
OperationShopData.Event = {}
OperationShopData.Event.XXX = "OperationShopData.Msg.XXX"

-------------------------------- 刷新事件 --------------------------------
local tRefreshEvents = {
    "MONEY_UPDATE",
    "UPDATE_ACHIEVEMENT_POINT",
    "UPDATE_ACHIEVEMENT_COUNT",
    "PLAYER_LEVEL_UPDATE",
    "UPDATE_EXAMPRINT",
    "UPDATE_ARENAAWARD",
    "UPDATE_CONTRIBUTION",
    "UPDATE_PRESTIGE",
    "UPDATE_JUSTICE",
    "BAG_ITEM_UPDATE",
    "REMOTE_SHOPLIMIT_FRESH",
}

function OperationShopData.InitOperation()
    local fnShopUpdate = function()
        if not self.bShopReady then
            self.RefreshShopState()
            return
        end
        Event.Dispatch(EventType.OnOperationShopDataUpdate)
    end

    for _, event in ipairs(tRefreshEvents) do
        Event.Reg(self, event, function()
            fnShopUpdate()
        end)
    end

    local tCurrencyUpdateEvent = Currency_Base.GetCurrencyList()
	for _, szCurrency in ipairs(tCurrencyUpdateEvent) do
		local szEvent = ("UPDATE_" .. szCurrency):upper()
		if szEvent then
			Event.Reg(self, szEvent, function()
				fnShopUpdate()
			end)
		end
	end

    for _, dwID in ipairs(self.GetSupportedOperationIDs()) do
        HuaELouData.RegisterProcessor(dwID, self)
    end
end

function OperationShopData.CheckShow(dwID)
    local tData = GDAPI_CanOperationShopShow(dwID)
    local nCurrentTime = GetCurrentTime()
    if not tData or not tData.bShow or (tData.nEndTime ~= 0 and nCurrentTime >= tData.nEndTime) then
        return false
    end
    return true
end

function OperationShopData.GetSupportedOperationIDs()
    if self.tSupportedOperationIDs then
        return self.tSupportedOperationIDs
    end

    local tSupportedOperationIDs = {}
    for _, tInfo in ipairs(Table_GetOperationActivity() or {}) do
        if tInfo.dwID and tInfo.nOperatMode == OPERACT_MODE.SHOP then
            table.insert(tSupportedOperationIDs, tInfo.dwID)
        end
    end

    self.tSupportedOperationIDs = tSupportedOperationIDs
    return self.tSupportedOperationIDs
end

function OperationShopData.CheckID(dwID)
    return table.contain_value(self.GetSupportedOperationIDs(), dwID)
end

function OperationShopData.GetOperationInfo()
    if not self.dwOperationID then
        return nil
    end

    return OperationCenterData.GetOperationInfoByID(self.dwOperationID)
end

function OperationShopData.GetShopConfig()
    if not self.dwOperationID then
        return nil
    end

    return Table_GetOperationShopByID(self.dwOperationID)
end

function OperationShopData.GetShopID()
    local tShopInfo = self.GetShopConfig()
    return tShopInfo and tShopInfo.nShopID or nil
end

local function ApplyShopInfo(nShopID)
    local tShopInfo = GetShop(nShopID)
    if not tShopInfo then
        return false
    end

    local S = ShopDataBase.GetState()
    local player = GetClientPlayer()

    S.m_nNpcID           = tShopInfo.dwNpcID or 0
    S.m_dwRequireForceID = tShopInfo.dwRequireForceID or 0
    S.m_szShopName       = tShopInfo.szShopName or ""
    S.m_bCanRepair       = tShopInfo.bCanRepair or false
    S.m_nTemplateID      = tShopInfo.dwTemplateID or 0
    S.m_bCustomShop      = tShopInfo.bCustomShop or false
    S.m_Selector         = Table_GetShopPanelSelector(S.m_nTemplateID) or {}
    S.m_dwPlayerRemoteDataID = tShopInfo.dwPlayerRemoteDataID or 0

    if S.m_dwPlayerRemoteDataID > 0 then
        if not player then
            return false
        end

        if not player.HaveRemoteData(S.m_dwPlayerRemoteDataID) then
            if self.dwWaitingRemoteDataID ~= S.m_dwPlayerRemoteDataID then
                self.dwWaitingRemoteDataID = S.m_dwPlayerRemoteDataID
                player.ApplyRemoteData(S.m_dwPlayerRemoteDataID, REMOTE_DATA_APPLY_EVENT_TYPE.CLIENT_APPLY_SERVER_CALL_BACK)
            end
            return false
        end

        self.dwWaitingRemoteDataID = nil
    end

    return true
end

function OperationShopData.SyncShopState()
    local nShopID = self.GetShopID()
    if not nShopID then
        LOG.ERROR("OperationShop missing OperationShop config, dwID = " .. tostring(self.dwOperationID))
        return false
    end

    local S = ShopDataBase.GetState()

    S.m_szFilter         = nil
    S.m_nShopID          = nShopID
    S.m_nNpcID           = 0
    S.m_dwRequireForceID = 0
    S.m_szShopName       = ""
    S.m_bCanRepair       = false
    S.m_nTemplateID      = 0
    S.m_bCustomShop      = false
    S.m_bGroup           = false
    S.m_bFullScreen      = false
    S.m_nFullScreen      = 0
    S.m_goodsSelected    = nil
    S.m_tCustomShop      = {}
    S.m_tCustomShopEx    = {}
    S.m_Selector         = {}
    S.m_dwPlayerRemoteDataID = 0
    self.bShopReady = false
    self.bRefreshing = false
    self.dwWaitingRemoteDataID = nil

    OpenShopRequest(nShopID, S.m_nNpcID, self.dwOperationID)
    return true
end

function OperationShopData.RefreshShopState()
    if self.bRefreshing then
        return false
    end

    self.bRefreshing = true

    local nShopID = self.GetShopID()
    if not nShopID then
        self.bRefreshing = false
        return false
    end

    if not ApplyShopInfo(nShopID) then
        self.bShopReady = false
        self.bRefreshing = false
        return false
    end

    local tShopItems = GetShopAllItemInfoParam(nShopID)
    if not tShopItems then
        self.bShopReady = false
        self.bRefreshing = false
        return false
    end

    ShopDataBase.SwitchFullShop(nShopID)
    local nSchoolID = PlayerData.GetMountBelongSchoolID()
    if nSchoolID then
        ShopDataBase.GenerateSelector('SchoolSelector')
        ShopDataBase.SetSelector('SchoolSelector', nSchoolID, true)
        ShopDataBase.ApplySelector(true)
    end
    ShopDataBase.QueryAllPageData()
    self.bShopReady = true
    self.bRefreshing = false

    Timer.AddFrame(self, 1, function()
        Event.Dispatch(EventType.OnOperationShopDataUpdate)
    end)
    return true
end

function OperationShopData.GetShopState()
    local S = ShopDataBase.GetState()
    return S or {}
end

function OperationShopData.GetGoodsList()
    local S = ShopDataBase.GetState()
    return S and S.m_aGoods or {}
end

function OperationShopData.GetTitleText()
    local tInfo = self.GetOperationInfo() or {}
    if tInfo.szTitle and tInfo.szTitle ~= "" then
        return tInfo.szTitle
    end
    return tInfo.szName or ""
end

function OperationShopData.GetLeftTimeText()
    local tInfo = self.GetOperationInfo() or {}
    local nEndTime = tonumber(tInfo.nEndTime) or 0
    if nEndTime > 0 then
        local nLeftTime = math.max(0, nEndTime - GetCurrentTime())
        return GetTimeToDayHourMinute(nLeftTime)
    end
    return tInfo.szCustomTime or ""
end

function OperationShopData.GetExplainText()
    local tInfo = self.GetOperationInfo() or {}
    return tInfo.szActivityExplain or ""
end

function OperationShopData.Init(dwOperationID)
    self.dwOperationID = dwOperationID
    self.SyncShopState()
end

function OperationShopData.UnInit()
    local S = ShopDataBase.GetState()
    if S then
        S.m_dwPlayerRemoteDataID = nil
    end
    self.bShopReady = false
    self.bRefreshing = false
    self.dwWaitingRemoteDataID = nil
    self.dwOperationID = nil
end

function OperationShopData.GetRefreshEvents()
    return tRefreshEvents
end

Event.Reg(self, "SHOP_OPENSHOP", function(dwShopID, dwOperationID)
    if not UIMgr.IsViewOpened(VIEW_ID.PanelOperationCenter) then
        return
    end
    if not self.dwOperationID or self.dwOperationID ~= dwOperationID then
        return false
    end

    if self.GetShopID() ~= dwShopID then
        return false
    end

    self.RefreshShopState()
    return true
end)