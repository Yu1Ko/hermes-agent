-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: ExteriorSellBagData
-- Date: 2024-05-26 16:04:07
-- Desc: 万宝楼寄售功能
-- ---------------------------------------------------------------------------------

ExteriorSellBagData = ExteriorSellBagData or {className = "ExteriorSellBagData"}
local self = ExteriorSellBagData
-------------------------------- 消息定义 --------------------------------
ExteriorSellBagData.Event = {}
ExteriorSellBagData.Event.XXX = "ExteriorSellBagData.Msg.XXX"
-----------------------------DataModel  Begin------------------------------
local function _IsTradeMallFilter(pItem)
    local pItemInfo = GetItemInfo(pItem.dwTabType, pItem.dwIndex)
    local bFilter = pItemInfo.nExistType ~= ITEM_EXIST_TYPE.PERMANENT or pItem.bBind
    return IsTradeMallItem(pItem.dwTabType, pItem.dwIndex) and not bFilter
end

local DataModel = {
    tPackageIndex  = {
        INVENTORY_INDEX.PACKAGE,
        INVENTORY_INDEX.PACKAGE1,
        INVENTORY_INDEX.PACKAGE2,
        INVENTORY_INDEX.PACKAGE3,
        INVENTORY_INDEX.PACKAGE4,
        INVENTORY_INDEX.PACKAGE_MIBAO,
    },
}

function DataModel.Update()
    DataModel.UpdateSelectList()
end

function DataModel.GetItemList()
    local tItemIndex = {}
    DataModel.nCount = 0
    local pPlayer = GetClientPlayer()
    if pPlayer then
        for _, dwBox in pairs(DataModel.tPackageIndex) do
            local nSize = pPlayer.GetBoxSize(dwBox)
            for dwX = 0, nSize - 1 do
                local pItem = ItemData.GetPlayerItem(pPlayer, dwBox, dwX)
                if pItem and _IsTradeMallFilter(pItem) then
                    local tIndex    = {}
                    tIndex.dwBox    = dwBox
                    tIndex.dwX      = dwX
                    tIndex.szName   = pItem.szName
                    tIndex.nQuality = pItem.nQuality
                    table.insert(tItemIndex, tIndex)
                    DataModel.nCount = DataModel.nCount + 1
                end
            end
        end
    end

    return tItemIndex
end

function DataModel.UpdateSelectList()
    local szSearchText = DataModel.szSearchText or ""
    local tItemList = DataModel.GetItemList()

    local tSelectList = {}
    for _, tItem in ipairs(tItemList) do
        if szSearchText == ""  or string.find(tItem.szName, szSearchText) then
            table.insert(tSelectList, tItem)
        end
    end
    DataModel.tSelectList = tSelectList
end
-----------------------------DataModel  End------------------------------

function ExteriorSellBagData.Init()
    
end

function ExteriorSellBagData.UnInit()
    
end

function ExteriorSellBagData.Open()

    Event.Reg(ExteriorSellBagData , "BAG_ITEM_UPDATE" , function ()
        DataModel.Update()
        ExteriorSellBagData.UpdateView()
    end)

    Event.Reg(ExteriorSellBagData , "TRADE_MALL_CODE_NOTIFY" , function ()
        if arg0 == TRADE_MALL_CODE.CONSIGN_ITEM_SUCCESS then
            TipsHelper.ShowNormalTip(g_tStrings.STR_TRADE_MALL_RESULTS[arg0])
        elseif g_tStrings.STR_TRADE_MALL_RESULTS[arg0] then
            TipsHelper.ShowNormalTip(g_tStrings.STR_TRADE_MALL_RESULTS[arg0])
        end
    end)

    Event.Reg(ExteriorSellBagData , EventType.HideAllHoverTips , function ()
        local script = UIMgr.GetViewScript(VIEW_ID.PanelRightBag) 
        if script then
            UIHelper.SetVisible(script.widgetTip,false)
        end
        
    end)

    Event.Reg(ExteriorSellBagData , EventType.OnLeftBagClose , function ()
        Event.UnRegAll(ExteriorSellBagData)
    end)
    DataModel.Update()
    ExteriorSellBagData.UpdateView()
end

function ExteriorSellBagData.UpdateView()
    local tItemBoxAndIndexList = {}
    for i = 1, #DataModel.tSelectList do
        local tItem = DataModel.tSelectList[i]
        table.insert(tItemBoxAndIndexList,{nBox = tItem.dwBox, nIndex = tItem.dwX, nSelectedQuantity = 0, hItem = nil})
    end

    local tbFilterInfo = nil
    local szTempContent = "你确定要将1个\"<color=%s>%s</c>\"上架到万宝楼出售吗？\n确定上架后，请前往万宝楼网站设定价格"
    local script = UIMgr.GetViewScript(VIEW_ID.PanelRightBag) or UIMgr.Open(VIEW_ID.PanelRightBag)
    UIHelper.RemoveAllChildren(script.widgetTip)
    if script then
        script:OnInitWithBox(tItemBoxAndIndexList,tbFilterInfo)
        script:SetClickCallback(function (bSelected, nBox, nIndex)
            if bSelected then
                
                UIHelper.RemoveAllChildren(script.widgetTip)
                local scriptItemTip =  UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, script.widgetTip)

                local tBtnList  = {
                    {
                        szName = "寄售",
                        OnClick = function()
                            if nBox and nIndex then
                                local item = ItemData.GetPlayerItem(g_pClientPlayer, nBox, nIndex)
                                local szDialog = string.format(szTempContent ,ItemQualityColor[item.nQuality+1], UIHelper.GBKToUTF8(ItemData.GetItemNameByItem(item)))
                                local confirmDialog = UIHelper.ShowConfirm(szDialog, function()
                                    ConsignTradeMallItem(nBox, nIndex)
                                end, nil , true)
                            end
                        end
                    },
                }

                scriptItemTip:SetFunctionButtons({})
                scriptItemTip:OnInit(nBox, nIndex)
                scriptItemTip:SetBtnState(tBtnList)
                UIHelper.SetVisible(script.widgetTip, true)
                Event.Dispatch(EventType.OnLeftBagSelectItem)
            else
                UIHelper.RemoveAllChildren(script.widgetTip)
            end
        end)
        script:SetSearchCallback(function (szSearchFiler)
            DataModel.szSearchText  = szSearchFiler
            DataModel.Update()
            ExteriorSellBagData.UpdateView()
        end)
        UIHelper.SetVisible(script.WidgetWanBaoLouWarning , true)
        UIHelper.SetVisible(script.WidgetEmpty , #DataModel.tSelectList == 0)
    end
end