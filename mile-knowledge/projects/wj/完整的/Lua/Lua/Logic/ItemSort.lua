ItemSort = ItemSort or {className = "ItemSort"}

function ItemSort.Init()

end

function ItemSort.UnInit()

end

function ItemSort.StackItem()
    if PropsSort.IsBagInSort() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_DO_ITEM_INSORT)
        return
    end
    
	if not g_pClientPlayer then
		return
	end

	if g_pClientPlayer.nMoveState == MOVE_STATE.ON_DEATH then
		TipsHelper.ShowNormalTip(g_tStrings.STR_CAN_NOT_OPERATE_IN_DEATH, false)
		return
	end

    ItemSort.tCanUseBagSet = g_pClientPlayer.CanUseMibaoPackage() and ItemData.BoxSet.Bag or ItemData.BoxSet.BagExceptMiBao

	local function JudgeStack(bStackDiffExistTime)
		local _tItemList = {}
        local tbItemList = ItemData.GetItemList(ItemSort.tCanUseBagSet)
        local nExchangeCount = 0
        for _, tbItemInfo in ipairs(tbItemList) do
            local item = tbItemInfo.hItem
            local dwBox = tbItemInfo.nBox
            local dwX = tbItemInfo.nIndex
            if item and item.bCanStack and item.nStackNum < item.nMaxStackNum then
                local bLockBox = dwBox and dwX and BagViewData.IsLockBox(dwBox, dwX)--被锁住得格子不允许堆叠
                if not bLockBox then 
                    local key
                    if bStackDiffExistTime then
                        key = item.dwTabType .. "|" .. item.dwIndex
                    else
                        key = item.dwTabType .. "|" .. item.dwIndex .. "|" .. item.GetLeftExistTime()
                    end
                    if not _tItemList[key] then
                        _tItemList[key] = {dwBox = dwBox, dwX = dwX, nLeftStackNum = item.nMaxStackNum - item.nStackNum}
                    else
                        if item.nStackNum < _tItemList[key].nLeftStackNum then
                            g_pClientPlayer.ExchangeItem(dwBox, dwX, _tItemList[key].dwBox, _tItemList[key].dwX, item.nStackNum)
                            _tItemList[key].nLeftStackNum = _tItemList[key].nLeftStackNum - item.nStackNum
                            nExchangeCount = nExchangeCount + 1
                        elseif item.nStackNum == _tItemList[key].nLeftStackNum then
                            g_pClientPlayer.ExchangeItem(dwBox, dwX, _tItemList[key].dwBox, _tItemList[key].dwX, _tItemList[key].nLeftStackNum)
                            _tItemList[key] = nil
                            nExchangeCount = nExchangeCount + 1
                        elseif item.nStackNum > _tItemList[key].nLeftStackNum then
                            g_pClientPlayer.ExchangeItem(dwBox, dwX, _tItemList[key].dwBox, _tItemList[key].dwX, _tItemList[key].nLeftStackNum)
                            _tItemList[key].dwBox = dwBox
                            _tItemList[key].dwX = dwX
                            _tItemList[key].nLeftStackNum = item.nMaxStackNum - item.nStackNum + _tItemList[key].nLeftStackNum
                            nExchangeCount = nExchangeCount + 1
                        end
                    end

                    -- 超过100个的等下再堆叠，防止协议发送过多掉线
                    if nExchangeCount > 100 then
                        Timer.AddWaitGSResponse(ItemSort, function () JudgeStack(bStackDiffExistTime) end)
                        return
                    end
                end
            end
        end
	end
	local bJudge = false
	local _tJudgeList = {}

    local tbItemList = ItemData.GetItemList(ItemSort.tCanUseBagSet)
    for _, tbItemInfo in ipairs(tbItemList) do
        local item = tbItemInfo.hItem
        if item and item.bCanStack and item.nStackNum < item.nMaxStackNum then
            local key = item.dwTabType .. "|" .. item.dwIndex
            if not _tJudgeList[key] then
                _tJudgeList[key] = item.GetLeftExistTime()
            elseif _tJudgeList[key] ~= item.GetLeftExistTime() then
                bJudge = true
                break
            end
        end
    end

	if bJudge then
        UIHelper.ShowConfirm(
            g_tStrings.STR_STACK_BAG_JUDGE,
            function () JudgeStack(true) end,
            function () JudgeStack(false) end,
            false
        )
	else
		JudgeStack(false)
	end
end
