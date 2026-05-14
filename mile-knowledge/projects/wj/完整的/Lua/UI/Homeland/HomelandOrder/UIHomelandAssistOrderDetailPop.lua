-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandAssistOrderDetailPop
-- Date: 2024-02-02 10:13:06
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandAssistOrderDetailPop = class("UIHomelandAssistOrderDetailPop")

function UIHomelandAssistOrderDetailPop:OnEnter(tbLinkData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbLinkData = tbLinkData
    self:UpdateInfo()
end

function UIHomelandAssistOrderDetailPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandAssistOrderDetailPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnChat, EventType.OnClick, function()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "player talk") then
            return
        end
        local tbLinkData = self.tbLinkData
        local tbData = {szName = UIHelper.GBKToUTF8(tbLinkData.szName), dwTalkerID = tbLinkData.dwTalkerID, szGlobalID = tbLinkData.szGlobalID}
        ChatHelper.WhisperTo(UIHelper.GBKToUTF8(tbLinkData.szName), tbData)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnOK, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIHomelandAssistOrderDetailPop:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        Event.Dispatch(EventType.OnClearUICommonItemSelect)
    end)
end

function UIHomelandAssistOrderDetailPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
local function ParseItem(tbInfo)
    tbInfo.tItemList = {}
    local tRes = {}
    local tItemList = SplitString(tbInfo.szProduct, ';')
    for _, v in pairs(tItemList) do
        local tItem = SplitString(v, '_')
        table.insert(tbInfo.tItemList, {dwTabType = tonumber(tItem[1]), dwIndex = tonumber(tItem[2]), nCount = tonumber(tItem[3])})
    end
end

local function GetOrderInfo (dwID)
    -- 目前只有调香订单有援助订单，所以只取调香的
    local tbAllOrderInfo = Table_GetHLOrderByType(HLORDER_TYPE.FLOWER)
    if tbAllOrderInfo and tbAllOrderInfo[dwID] then
        local tbOrderInfo = tbAllOrderInfo[dwID]
        ParseItem(tbOrderInfo)
        return tbOrderInfo
    end
end

function UIHomelandAssistOrderDetailPop:UpdateInfo()
    local tbLinkData = self.tbLinkData
    local dwID = tbLinkData.dwID
    local nMoney = tbLinkData.nMoney
    local szPlayerName = UIHelper.GBKToUTF8(tbLinkData.szName)
    local tbOrderInfo = GetOrderInfo(dwID)

    self:UpdateItemInfo(tbOrderInfo)
    UIHelper.SetString(self.LabelMoney_Jin, tostring(nMoney))
    UIHelper.SetString(self.LabelName, szPlayerName)
end

function UIHomelandAssistOrderDetailPop:UpdateItemInfo(tbOrderInfo)
    local tItemInfo    = tbOrderInfo.tItemList[1]
    local dwTabType    = tItemInfo.dwTabType
    local dwIndex      = tItemInfo.dwIndex
    local nTotalCount  = tItemInfo.nCount

    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItemWithName, self.LayoutItem)
    script:OnInitWithTabID(dwTabType, dwIndex, nTotalCount)
    script:RegisterSelectEvent(function (bSelected)
        if bSelected then
            TipsHelper.ShowItemTips(script._rootNode, dwTabType, dwIndex)
        else
            Event.Dispatch(EventType.OnClearUICommonItemSelect)
        end
    end)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutContent, true, true)
end

return UIHomelandAssistOrderDetailPop