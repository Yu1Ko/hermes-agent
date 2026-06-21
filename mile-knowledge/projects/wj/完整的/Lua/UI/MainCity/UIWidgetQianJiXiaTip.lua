-- ---------------------------------------------------------------------------------
-- Author: JiaYuRan
-- Name: UIWidgetQianJiXiaTp
-- Date: 2026-01-12 15:45:21
-- Desc: ?
-- ---------------------------------------------------------------------------------

local function UpdateBoxInfo()
    local player = GetClientPlayer()
    local dwBagSize = player.GetBoxSize(INVENTORY_INDEX.BULLET_PACKAGE)
    local tList = {}
    local tAllBoxList = {}

    for i = 1, dwBagSize, 1 do
        local dwBox = INVENTORY_INDEX.BULLET_PACKAGE
        local dwX = i - 1

        local tBoxInfo = { dwBox, dwX }
        local item = GetPlayerItem(player, dwBox, dwX)
        if item then
            table.insert(tList, tBoxInfo)
        end

        table.insert(tAllBoxList, tBoxInfo)
    end

    return tList, tAllBoxList
end

local function Stack()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local tList = UpdateBoxInfo()
    local _tItemList = {}
    for _, tInfo in ipairs(tList) do
        local dwBox = tInfo[1]
        local dwX = tInfo[2]
        local dwSize = pPlayer.GetBoxSize(dwBox)
        local item = pPlayer.GetItem(dwBox, dwX)
        if item and item.bCanStack and item.nStackNum < item.nMaxStackNum then
            local key = item.dwTabType .. "|" .. item.dwIndex
            if not _tItemList[key] then
                _tItemList[key] = { dwBox = dwBox, dwX = dwX, nLeftStackNum = item.nMaxStackNum - item.nStackNum }
            else
                if item.nStackNum < _tItemList[key].nLeftStackNum then
                    pPlayer.ExchangeItem(dwBox, dwX, _tItemList[key].dwBox, _tItemList[key].dwX, item.nStackNum)
                    _tItemList[key].nLeftStackNum = _tItemList[key].nLeftStackNum - item.nStackNum
                elseif item.nStackNum == _tItemList[key].nLeftStackNum then
                    pPlayer.ExchangeItem(dwBox, dwX, _tItemList[key].dwBox, _tItemList[key].dwX, _tItemList[key].nLeftStackNum)
                    _tItemList[key] = nil
                elseif item.nStackNum > _tItemList[key].nLeftStackNum then
                    pPlayer.ExchangeItem(dwBox, dwX, _tItemList[key].dwBox, _tItemList[key].dwX, _tItemList[key].nLeftStackNum)
                    _tItemList[key].dwBox = dwBox
                    _tItemList[key].dwX = dwX
                    _tItemList[key].nLeftStackNum = item.nMaxStackNum - item.nStackNum + _tItemList[key].nLeftStackNum
                end
            end
        end
    end
end

local function ExchangeItemBetweenBankAndBag(dwBox, dwX, nAmount)
    if PropsSort.IsBagInSort() or PropsSort.IsBankInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
        return
    end

    local player = GetClientPlayer()
    if not player then
        return
    end
    local dwTargetBox, dwTargetX
    local dwBoxType = player.GetBoxType(dwBox);

    if dwBoxType == INVENTORY_TYPE.BANK or INVENTORY_TYPE.BULLET_PACKAGE then
        dwTargetBox, dwTargetX = player.GetStackRoomInPackage(dwBox, dwX, nAmount)
        if not (dwTargetBox and dwTargetX) then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_ERROR_PACKAGE_IS_FULL);
            return false
        end
    end

    if dwBoxType == INVENTORY_TYPE.PACKAGE then
        dwTargetBox, dwTargetX = player.GetStackRoomInBank(dwBox, dwX, nAmount)
        if not (dwTargetBox and dwTargetX) then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_ERROR_BANK_IS_FULL)
            return false
        end
    end

    
    ItemData.OnExchangeItem(dwBox, dwX, dwTargetBox, dwTargetX, nAmount)
    return true
end

local UIWidgetQianJiXiaTp = class("UIWidgetQianJiXiaTp")

function UIWidgetQianJiXiaTp:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIWidgetQianJiXiaTp:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIWidgetQianJiXiaTp:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        self:Close()
    end)

    UIHelper.BindUIEvent(self.BtnCloseTip, EventType.OnClick, function()
        self:Close()
    end)
    
    UIHelper.BindUIEvent(self.BtnNeaten, EventType.OnClick, function()
        self:Sort()
    end)

    UIHelper.BindUIEvent(self.BtnCombine, EventType.OnClick, function()
        Stack()
    end)
end

function UIWidgetQianJiXiaTp:RegEvent()
    Event.Reg(self, "BULLETBACKUP_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
        self:UpdateInfo()
    end)
    
end

function UIWidgetQianJiXiaTp:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetQianJiXiaTp:UpdateInfo()
    local player = GetClientPlayer()
    local dwBagSize = player.GetBoxSize(INVENTORY_INDEX.BULLET_PACKAGE)
    self.tScripts = self.tScripts or {}
    for i = 1, dwBagSize, 1 do
        local item = GetPlayerItem(player, INVENTORY_INDEX.BULLET_PACKAGE, i - 1)
        local itemScript = self.tScripts[i]
        if not itemScript then
            itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetRefineMaterial_80, self.LayoutGrid, EQUIP_REFINE_SLOT_TYPE.ADD_MATERIAL)
            self.tScripts[i] = itemScript
        end

        if item then
            itemScript:RefreshInfo(EQUIP_REFINE_SLOT_TYPE.MATERIAL_IN_BAG, nil, item.nUiId, item.nQuality, ItemData.GetItemStackNum(item))
            itemScript:BindCellFunc(function()
                self:UpdateQianJiXiaItemTips(item, INVENTORY_INDEX.BULLET_PACKAGE, i - 1)
            end)
        else
            itemScript:RefreshInfo(EQUIP_REFINE_SLOT_TYPE.ADD_MATERIAL)
            UIHelper.BindUIEvent(itemScript.BtnAdd, EventType.OnClick, function()
                UIMgr.OpenSingle(false, VIEW_ID.PanelQuickUsedBag, nil, true)
            end)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutGrid)
end

function UIWidgetQianJiXiaTp:UpdateQianJiXiaItemTips(hItem, nBox, nIndex)
    _, self.scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self._rootNode, TipsLayoutDir.TOP_LEFT)

    local fnExchangeClick = function(nCount, nBox, nIndex)
        ExchangeItemBetweenBankAndBag(nBox, nIndex, nCount)
        UIHelper.SetVisible(self.scriptItemTip._rootNode, false)
    end

    local szCountTitle = "取出数量："
    local szConfirmLabel = g_tStrings.tbItemString.TAKEOUT_ITEM_CONFIRM_DIALOG_BUTTON_NAME
    if hItem then
        local tbFuncButtons = {}
        local nStackNum = ItemData.GetItemStackNum(hItem)
        self.scriptItemTip:ShowWareHouseSlider(nStackNum, nStackNum, szConfirmLabel, szCountTitle, fnExchangeClick, tbFuncButtons)
        self.scriptItemTip:ShowWareHousePreviewSlider(hItem.dwTabType, hItem.dwIndex)
    end

    self.scriptItemTip:OnInit(nBox, nIndex, false)
end

function UIWidgetQianJiXiaTp:Close()
    UIHelper.SetVisible(self._rootNode, false)
    UIMgr.Close(VIEW_ID.PanelQuickUsedBag)
    Event.Dispatch(EventType.HideAllHoverTips)
end

function UIWidgetQianJiXiaTp:Sort()
    local m_szMark = "bulletbag"
    if PropsSort.IsItemSorting(m_szMark) then
        return
    end

    local tList = {}
    local tAllBoxList = {}
    tList, tAllBoxList = UpdateBoxInfo()
    PropsSort.BeginSort(tList, tAllBoxList, m_szMark)
end

return UIWidgetQianJiXiaTp