-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandOrderView
-- Date: 2024-01-12 14:52:25
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandOrderView = class("UIHomelandOrderView")
local REMOTE_CALL = {
    [HLORDER_TYPE.FLOWER] = "On_HomeLand_CompleteFlowerOrder",
    [HLORDER_TYPE.COOK]   = "On_HomeLand_CompleteCookOrder",
}

local ITEM_TABTYPE = 5
local REFRESH_ITEM_INDEX = 66098
local TONGFIELD_LINK_ID = 2530
local TONGFIELD_MAPID = 74
local REMOTE_HOME_FLOWER = 1150 --花匠远程数据块ID
local function IsClientPlayerHaveTong()
	local hPlayer = GetClientPlayer()
	if not hPlayer or not hPlayer.dwTongID or hPlayer.dwTongID == 0 then
		return false
	end
	return true
end
-----------------------------DataModel------------------------------
local DataModel = {}
function DataModel.Init(dwOwnerID)
    DataModel.tOrderData = {}
    local dwPlayerID = UI_GetClientPlayerID()
    if not dwOwnerID or dwPlayerID == dwOwnerID then
        DataModel.bOwner = true
        DataModel.dwOwnerID = dwPlayerID
        DataModel.DoApplyMyHomeInfo()
    else
        DataModel.bOwner = false
        DataModel.dwOwnerID = dwOwnerID
        DataModel.tOrderData[HLORDER_TYPE.FLOWER] = {}
        PeekPlayerRemoteData(dwOwnerID, REMOTE_HOME_FLOWER)
    end

    DataModel.tOrderData[HLORDER_TYPE.FLOWER] = GDAPI_GetHLFlowerOrder(DataModel.dwOwnerID) or {}
    DataModel.tOrderData[HLORDER_TYPE.COOK] = GDAPI_GetHLCookOrder()
    DataModel.tTongOrder = {}
    DataModel.tOrderInfo = Table_GetAllHLOrder()
    DataModel.tCurrentSelect = {}
    DataModel.nTongOrderCount = 0
    DataModel.ParseOrderInfo()
end

function DataModel.Update()
    DataModel.tOrderData[HLORDER_TYPE.FLOWER] = GDAPI_GetHLFlowerOrder(DataModel.dwOwnerID) or {}
    DataModel.tOrderData[HLORDER_TYPE.COOK] = GDAPI_GetHLCookOrder()
end

-- 用于获取主角家园的社区分线、私宅皮肤信息
function DataModel.DoApplyMyHomeInfo()
    local pHomelandMgr = GetHomelandMgr()
    if not pHomelandMgr then
        return
    end

    local tLandHash = pHomelandMgr.GetAllMyLand()
    for _, tHash in ipairs(tLandHash) do
        if not tHash.bPrivateLand and not tHash.bAllied then
            local nMapID, nCopyIndex = pHomelandMgr.ConvertLandID(tHash.uLandID)
            pHomelandMgr.ApplyCommunityInfo(nMapID, nCopyIndex)
        end
    end

    for _, tHash in ipairs(pHomelandMgr.GetAllMyPrivateHome()) do
        pHomelandMgr.ApplyPrivateHomeInfo(tHash.dwMapID, tHash.nCopyIndex)
    end
end

local function ParseItem(szItemList)
    local tRes = {}
    local tItemList = SplitString(szItemList, ';')
    for _, v in pairs(tItemList) do
        local tItem = SplitString(v, '_')
        table.insert(tRes, {dwTabType = tonumber(tItem[1]), dwIndex = tonumber(tItem[2]), nCount = tonumber(tItem[3])})
    end
    return tRes
end

function DataModel.GetOrderDataList(nType)
    return DataModel.tOrderData[nType]
end

function DataModel.GetOrderData(nType, nIndex)
    if DataModel.tOrderData[nType] then
        return DataModel.tOrderData[nType][nIndex]
    end
end

function DataModel.ParseOrderInfo()
    for i, v in pairs(DataModel.tOrderInfo) do
        v.tItemList   = ParseItem(v.szProduct)
        v.tRewardList = ParseItem(v.szReward)
    end
end

function DataModel.GetOrderInfo(dwID, nType)
    for _, v in pairs(DataModel.tOrderInfo) do
        if v.dwID == dwID and v.nType == nType then
            return v
        end
    end
end

function DataModel.GetTongData(nIndex)
    return DataModel.tTongOrder[nIndex]
end

function DataModel.UnInit()
    for i, v in pairs(DataModel) do
        if type(v) ~= "function" then
            DataModel[i] = nil
        end
    end
end
-----------------------------View------------------------------
function UIHomelandOrderView:OnEnter(dwOwnerID, nTypeIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if dwOwnerID then
        self.dwOwnerID = dwOwnerID
    else
        local tLandInfo = HomelandData.Homeland_GetHLLandInfo() or {}
        self.dwOwnerID = tLandInfo.dwOwnerID
    end
    self.nTypeIndex = nTypeIndex or 1
    DataModel.Init(self.dwOwnerID)
    self:Init()
    self:UpdateInfo(true)

	if (GetClientPlayer() and GetClientPlayer().GetQuestIndex(21781) and true) then
        RemoteCallToServer("On_OPEN_PANEL", "JYDINGDAN")
	end
end

function UIHomelandOrderView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    -- DataModel.UnInit()
end

function UIHomelandOrderView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnFaction, EventType.OnClick, function ()
        local bHaveTong = IsClientPlayerHaveTong()
        if not bHaveTong then
            OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_HOMELAND_JOIN_TONG)
            return
        end
        local tLink = Table_GetCareerLinkNpcInfo(TONGFIELD_LINK_ID, TONGFIELD_MAPID)
        if not tLink then
            return
        end
        local tTrack = {
            nID      = TONGFIELD_LINK_ID,
            dwMapID  = TONGFIELD_MAPID,
            szName   = UIHelper.GBKToUTF8(tLink.szNpcName),
            nX       = tLink.fX,
            nY       = tLink.fY,
            nZ       = tLink.fZ,
            szSource = "Custom",
        }
        UIMgr.Close(self)
        UIMgr.Close(VIEW_ID.PanelHomeIdentity)
        MapMgr.SetTracePoint(tTrack.szName, tTrack.dwMapID, {tTrack.nX, tTrack.nY, tTrack.nZ})
        if GetClientPlayer().GetMapID() ~= TONGFIELD_MAPID then
            MapMgr.TryTransfer(TONGFIELD_MAPID)
        end
    end)

    for index, tog in ipairs(self.tbOrderTabToggle) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function ()
            self.nTypeIndex = index
            self:UpdateInfo(true)
            if index == HLORDER_TYPE.TONG and DataModel.bOwner then
                RemoteCallToServer("On_HomeLand_GetTongOrder")
            end
        end)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupTab, tog)
    end
end

function UIHomelandOrderView:RegEvent()
    Event.Reg(self, EventType.OnHomelandOrderUpdate, function (bNotPeek)
        self:UpdateInfo(bNotPeek)
    end)

    Event.Reg(self, "REMOTE_HOME_FLOWER_EVENT", function (dwPlayerID, dwRemoteID, bSuccess)
        self:OnPeekOtherPlayerRemoteData(dwPlayerID, dwRemoteID, bSuccess)
    end)

    Event.Reg(self, EventType.OnGetTongOrder, function (tInfo)
        self:UpdateTongOrder(tInfo)
    end)

    Event.Reg(self, EventType.OnSubmitHomelandOrder, function (dwID, nIndex, bTong)
        if bTong then
            RemoteCallToServer("On_HomeLand_CompleteTongOrder", dwID, nIndex)
            return
        end

        if DataModel.bOwner then
            RemoteCallToServer(REMOTE_CALL[self.nTypeIndex], dwID, nIndex)
        else
            RemoteCallToServer("On_HomeLand_AssistOrder", dwID, nIndex)
        end
    end)
end

function UIHomelandOrderView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandOrderView:Init()
    for index, tog in ipairs(self.tbOrderTabToggle) do
        if index > 1 then   -- 援助者只显示调香订单
            UIHelper.SetVisible(tog, DataModel.bOwner)
        end
    end
    self.scriptOrder        = self.scriptOrder or UIHelper.GetBindScript(self.WidgetBlendAndBoss)
    self.scriptToneOrder    = self.scriptToneOrder or UIHelper.GetBindScript(self.WidgetFaction)
    self.scriptRightTop     = self.scriptRightTop or UIHelper.GetBindScript(self.WidgetContentRightTop)
    self.scriptOrderCard    = self.scriptOrderCard or UIHelper.GetBindScript(self.WidgetRight)

    self.scriptOrder:OnEnter(DataModel)
    self.scriptToneOrder:OnEnter(DataModel)
    self.scriptRightTop:OnEnter(DataModel)
    self.scriptOrderCard:OnEnter(DataModel)
    UIHelper.SetToggleGroupSelected(self.ToggleGroupTab, self.nTypeIndex-1)
end

function UIHomelandOrderView:UpdateInfo(bNotPeek)
    if not bNotPeek and DataModel.dwOwnerID and DataModel.dwOwnerID ~= 0 then
        PeekPlayerRemoteData(DataModel.dwOwnerID, REMOTE_HOME_FLOWER)
    end
    DataModel.Update()
    self:UpdateOrderPage()
end

function UIHomelandOrderView:UpdateOrderPage()
    local nTypeIndex = self.nTypeIndex
    UIHelper.SetVisible(self.scriptOrder._rootNode, true)
    UIHelper.SetVisible(self.BtnFaction, false)
    if nTypeIndex == HLORDER_TYPE.TONG then
        UIHelper.SetVisible(self.BtnFaction, true)
        UIHelper.SetVisible(self.scriptOrder._rootNode, false)
        UIHelper.SetVisible(self.scriptToneOrder._rootNode, true)
    end
    self.scriptOrder:UpdateInfo(nTypeIndex)
    self.scriptRightTop:UpdateInfo(nTypeIndex)
    self.scriptToneOrder:UpdatePageInfo(nTypeIndex)
end

function UIHomelandOrderView:OnPeekOtherPlayerRemoteData(dwPlayerID, dwRemoteID, bSuccess)
    local dwID = UI_GetClientPlayerID()
    if dwRemoteID == REMOTE_HOME_FLOWER then
        if not bSuccess then
            DataModel.tOrderData[HLORDER_TYPE.FLOWER] = {}
            self:UpdateInfo(true)
        elseif (dwPlayerID ~= dwID and HaveOtherPlayerRemoteData(dwPlayerID, dwRemoteID)) then
            DataModel.tOrderData[HLORDER_TYPE.FLOWER] = GDAPI_GetHLFlowerOrder(dwPlayerID)
            self:UpdateInfo(true)
        end
    end
end

function UIHomelandOrderView:UpdateTongOrder(tInfo)
    if not self.scriptToneOrder then
        self.scriptToneOrder = UIHelper.GetBindScript(self.WidgetFaction)
    end
    local tRes = {}
    for i = 1, #tInfo do
        local tTemp = tInfo[i] or {}
        local tOrderInfo = DataModel.GetOrderInfo(tTemp.dwID or 0, HLORDER_TYPE.TONG)
        if tOrderInfo and tOrderInfo.szProduct and tOrderInfo.szReward then
            tTemp.tItemList   = ParseItem(tOrderInfo.szProduct)
            tTemp.tRewardList = ParseItem(tOrderInfo.szReward)
        end
        table.insert(tRes, tTemp)
    end

    DataModel.tTongOrder = tRes
    self.scriptToneOrder:UpdateInfo(DataModel.tTongOrder)
end

function UIHomelandOrderView:OnFinishTongOrder(nIndex, dwID, nTimes)
    if DataModel.tTongOrder[nIndex] then
        DataModel.tTongOrder[nIndex].nTimes = nTimes
    end
    self:UpdateInfo()
    DataModel.nFinishTongOrderIndex = nIndex
    DataModel.nFinishTongOrderID = dwID
    if DataModel.bOwner then
        RemoteCallToServer("On_HomeLand_GetTongOrder")
    end
end
return UIHomelandOrderView