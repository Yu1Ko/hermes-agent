-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeIdentityCartView
-- Date: 2024-01-23 20:50:35
-- Desc: ?
-- ---------------------------------------------------------------------------------
local FRAME_MODE =
{
    SELL = 1,
    BUY  = 2,
}

local REMOTE_HOME_SELLER = 1151
local tbFilterInfo = {}
    tbFilterInfo.Def = FilterDef.TransactionBag
    tbFilterInfo.tbfuncFilter = {{
        function(_) return true end,
        function(item) return item.nGenre == ITEM_GENRE.TASK_ITEM end, --任务
        function(item) return item.nGenre == ITEM_GENRE.EQUIPMENT end, --装备
        function(item) return item.nGenre == ITEM_GENRE.POTION or item.nGenre == ITEM_GENRE.FOOD end, --药品
        function(item) return item.nGenre == ITEM_GENRE.MATERIAL end, --材料
        function(item) return item.nGenre == ITEM_GENRE.BOOK end, --书籍
        function(item) return item.nGenre == ITEM_GENRE.HOMELAND end, --家具
        function(item) return not item.bBind end, --非绑定
        function(item) return ItemData.GetItemInfo(item.dwTabType, item.dwIndex).nExistType ~= ITEM_EXIST_TYPE.PERMANENT end, --限时
    }}
local UIHomeIdentityCartView = class("UIHomeIdentityCartView")
local DataModel = {}

function DataModel.Init(dwOwnerID)
    local dwPlayerID = UI_GetClientPlayerID()
    if dwOwnerID and dwOwnerID ~= dwPlayerID then
        DataModel.SetFrameMode(FRAME_MODE.BUY)
        DataModel.dwOwnerID = dwOwnerID
        PeekPlayerRemoteData(dwOwnerID, REMOTE_HOME_SELLER)
    else
        DataModel.SetFrameMode(FRAME_MODE.SELL)
        DataModel.dwOwnerID = dwPlayerID
    end

    DataModel.tFoodData = GDAPI_GetFoodList(DataModel.dwOwnerID) or {}
    DataModel.tFoodInfo = Table_GetAllHLCookFood()
end

function DataModel.InitFurniture(dwOwnerID, tData)
    local dwPlayerID = UI_GetClientPlayerID()
    if dwOwnerID and dwOwnerID ~= dwPlayerID then
        DataModel.SetFrameMode(FRAME_MODE.BUY)
        DataModel.dwOwnerID = dwOwnerID
    else
        DataModel.SetFrameMode(FRAME_MODE.SELL)
        DataModel.dwOwnerID = dwPlayerID
    end
    DataModel.bFurniture = true
    DataModel.tFoodData  = tData
    DataModel.tFoodInfo  = Table_GetAllHLCookFood()
end

function DataModel.Update()
    local dwOwnerID = DataModel.dwOwnerID
    DataModel.tFoodData = GDAPI_GetFoodList(dwOwnerID)
end

function DataModel.UpdateFurniture(tData)
    DataModel.tFoodData = tData
end

function DataModel.SetFrameMode(nMode)
    DataModel.nFrameMode = nMode
end

function DataModel.GetFrameMode(nMode)
    return DataModel.nFrameMode
end

function DataModel.GetFoodInfo(dwID)
    for _, v in pairs(DataModel.tFoodInfo) do
        if v.dwID == dwID then
            return v
        end
    end
end

function DataModel.GetFoodData(nIndex)
    return DataModel.tFoodData[nIndex] or nil
end

function DataModel.UnInit()
    for i, v in pairs(DataModel) do
        if type(v) ~= "function" then
            DataModel[i] = nil
        end
    end
end

function UIHomeIdentityCartView:OnEnter(dwOwnerID, dwNpcID, bFurniture)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        DataModel.Init(dwOwnerID)
        self.bInit = true
    end
    self.dwOwnerID  = DataModel.dwOwnerID
    self.dwNpcID    = dwNpcID
    self.bFurniture = bFurniture
    self:Init()
    UIHelper.HidePageBottomBar()
end

function UIHomeIdentityCartView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    UIHelper.ShowPageBottomBar()
end

function UIHomeIdentityCartView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnReturnBag, EventType.OnClick, function ()
        if DataModel.bFurniture then
            RemoteCallToServer("On_HomeLand_TakeBackAllLandFood")
        else
            RemoteCallToServer("On_HomeLand_TakeBackAllFood")
        end
    end)

    UIHelper.BindUIEvent(self.BtnOff, EventType.OnClick, function ()
        RemoteCallToServer("On_HomeLand_PackUpTheStall")
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnOn, EventType.OnClick, function(btn)
        HomelandIdentity.UseToyBoxSkill(85)
        UIMgr.Close(self)
        UIMgr.Close(VIEW_ID.PanelHomeIdentity)
        UIMgr.Close(VIEW_ID.PanelHome)
    end)
end

function UIHomeIdentityCartView:RegEvent()
    Event.Reg(self, "REMOTE_HOME_SELLER_EVENT", function (dwPlayerID, dwRemoteID, bSuccess)
        local dwID = UI_GetClientPlayerID()
        if dwRemoteID == REMOTE_HOME_SELLER then
            if not bSuccess then
                DataModel.tFoodData = {}
            elseif (dwPlayerID ~= dwID and HaveOtherPlayerRemoteData(dwPlayerID, dwRemoteID))
            or dwPlayerID == dwID then
                DataModel.tFoodData = GDAPI_GetFoodList(dwPlayerID)
            end
            self:UpdateInfo(true)
        end
    end)

    Event.Reg(self, EventType.OnFoodCartUpdateFoodList, function (nIndex)
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnFoodCartOpenDetailPop, function (nIndex, tData, bAddNew)
        tData = tData or DataModel.GetFoodData(nIndex)

        local dwOwnerID = DataModel.dwOwnerID
        if tData and tData.nLevel then
            return
        end
        UIMgr.Open(VIEW_ID.PanelDiningCarCuisinePop, dwOwnerID, nIndex, tData, bAddNew)
    end)

    Event.Reg(self, EventType.OnFoodCartSelectEmptyFood, function (nIndex, tData)
        self:OpenLeftBag(nIndex, tData)
    end)
end

function UIHomeIdentityCartView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIHomeIdentityCartView:Init()
    self:UpdateViewInfo()
    self:UpdateListInfo()
    self:UpdateBtnState()
end

function UIHomeIdentityCartView:UpdateInfo(bNotPeek)
    if not bNotPeek and DataModel.dwOwnerID and DataModel.dwOwnerID ~= 0 then
        PeekPlayerRemoteData(DataModel.dwOwnerID, REMOTE_HOME_SELLER)
    end
    DataModel.Update()
    self:UpdateViewInfo()
    self:UpdateListInfo()
    self:UpdateBtnState()
end

function UIHomeIdentityCartView:UpdateListInfo()
    local tFoodListData      = DataModel.tFoodData
    local nFrameMode = DataModel.GetFrameMode()
    UIHelper.RemoveAllChildren(self["ScrollViewMessageContent0"..nFrameMode])
    for index, tData in ipairs(tFoodListData) do
        if tData.dwID or nFrameMode == FRAME_MODE.SELL then
            local tFoodInfo = DataModel.GetFoodInfo(tData.dwID)
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetDiningCarCell, self["ScrollViewMessageContent0"..nFrameMode])
            script:OnEnter(index, tFoodInfo, tData, nFrameMode)
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self["ScrollViewMessageContent0"..nFrameMode])
end

function UIHomeIdentityCartView:UpdateViewInfo()
    local nMode = DataModel.GetFrameMode()
    local dwOwnerID = DataModel.dwOwnerID
    local player = GetPlayer(dwOwnerID)
    local npcMyFoodCart = self:GetFoodCartNpc()

    UIHelper.SetVisible(self.WidgetDiningCar, false)
    UIHelper.SetVisible(self.WidgetCustomer, false)
    if nMode == FRAME_MODE.SELL then
        UIHelper.SetVisible(self.WidgetDiningCar, true)
        self:UpdateWeekRurnoverInfo()
    else
        UIHelper.SetVisible(self.WidgetCustomer, true)
    end

    if player then
        local szName = UIHelper.GBKToUTF8(player.szName)
        UIHelper.SetString(self.LabelName01, szName)
    else
        UIHelper.SetVisible(self.LabelName01, false)
    end
end

function UIHomeIdentityCartView:UpdateBtnState()
    local dwOwnerID = DataModel.dwOwnerID

    UIHelper.SetVisible(self.BtnOn, false)
    UIHelper.SetVisible(self.BtnOff, false)
    UIHelper.SetVisible(self.BtnReturnBag, false)
    if dwOwnerID == PlayerData.GetPlayerID() then
        local bOn = false
        local player = GetPlayer(dwOwnerID)
        if player then
            BuffMgr.Generate(player, function (tb)
                if tb.dwID == 27774 then
                    bOn = true
                end
            end)
        end

        UIHelper.SetVisible(self.BtnOn, not bOn)
        UIHelper.SetVisible(self.BtnOff, bOn)
        UIHelper.SetVisible(self.BtnReturnBag, bOn)
    end

    UIHelper.LayoutDoLayout(self.LayoutBtns)
end

function UIHomeIdentityCartView:UpdateWeekRurnoverInfo()
    local dwPlayerID = UI_GetClientPlayerID()
    local nWeekMoney = GDAPI_GetTurnover(dwPlayerID) or 0

    local tbWeekMoney = {UIHelper.MoneyToBullionGoldSilverAndCopper(nWeekMoney)}
    for i = 1, 3, 1 do
        UIHelper.SetString(self.tbWeekCurrencyLabel[i], tbWeekMoney[i])
    end
end

local function IsItemLegal(dwTabType, dwIndex)
    if not DataModel.tFoodInfo or IsTableEmpty(DataModel.tFoodInfo) then
        DataModel.tFoodInfo = Table_GetAllHLCookFood()
    end

    local tInfo    = DataModel.tFoodInfo
    for _, v in pairs(tInfo) do
        if v.dwItemType == dwTabType and v.dwIndex == dwIndex then
            return v.dwID
        end
    end
end

local function CheckCanSell(pItem)
    if not pItem then
        return
    end

    local dwTabType   = pItem.dwTabType
	local dwItemIndex = pItem.dwIndex

    return IsItemLegal(dwTabType, dwItemIndex)
end

local function GetFoodInfoByIndex(dwIndex)
    for _, v in pairs(DataModel.tFoodInfo) do
        if v.dwIndex == dwIndex then
            return v
        end
    end
end

function UIHomeIdentityCartView:OpenLeftBag(nIndex, tData)
    local tbItemList = self:GetFoodCanSell()
    local tbBtnList = {{
        szName = "放入",
        OnClick = function (dwTabType, dwIndex)
            local dwID = IsItemLegal(dwTabType, dwIndex)
            tData.dwID = dwID
            Event.Dispatch(EventType.OnFoodCartOpenDetailPop, nIndex, tData, true)
            Event.Dispatch(EventType.HideAllHoverTips)
        end
    }}
    local scriptLeftBag = UIMgr.OpenSingle(false, VIEW_ID.PanelLeftBag)
    scriptLeftBag:OnInitWithTabID(tbItemList, tbBtnList, tbFilterInfo)
end

function UIHomeIdentityCartView:GetFoodCanSell()
    local tLockerFood = Table_GetAllHLCookFood()
    local tFoodList   = {}
    local tItemCount  = {}
    local hPlayer     = GetClientPlayer()

    --背包
    for _, dwBox in pairs(ItemData.BoxSet.Bag) do
        local nSize = hPlayer.GetBoxSize(dwBox)
        for dwX = 0, nSize - 1 do
            local pItem = ItemData.GetPlayerItem(hPlayer, dwBox, dwX)
            if pItem and CheckCanSell(pItem) then
                local tFood   = GetFoodInfoByIndex(pItem.dwIndex)
                local dwType  = tFood.dwItemType
                local dwIndex = tFood.dwIndex
                if tFood then
                    if not tItemCount[dwType] then
                        tItemCount[dwType] = {}
                    end
                    if tItemCount[dwType][dwIndex] then
                        tItemCount[dwType][dwIndex] = tItemCount[dwType][dwIndex] + pItem.nStackNum
                    else
                        tItemCount[dwType][dwIndex] = pItem.nStackNum
                    end
                end
            end
        end
    end

    --家园储物箱
    for _, v in pairs(tLockerFood) do
        local nCount = GDAPI_GetLockerItemCount(HLORDER_TYPE.COOK, v.dwItemType, v.dwIndex)
        if nCount > 0 then
            local dwType  = v.dwItemType
            local dwIndex = v.dwIndex
            if not tItemCount[dwType] then
                tItemCount[dwType] = {}
            end
            if tItemCount[dwType][dwIndex] then
                tItemCount[dwType][dwIndex] = tItemCount[dwType][dwIndex] + nCount
            else
                tItemCount[dwType][dwIndex] = nCount
            end
        end
    end

    for dwType, v in pairs(tItemCount) do
        for dwIndex, nCount in pairs(v) do
            table.insert(tFoodList, {dwTabType = dwType, dwIndex = dwIndex, nAmount = nCount})
        end
    end

    return tFoodList
end

function UIHomeIdentityCartView:GetFoodCartNpc()
    local player = GetClientPlayer()
    local scene = player.GetScene()
	if not scene or not player then
		return
	end


end

return UIHomeIdentityCartView