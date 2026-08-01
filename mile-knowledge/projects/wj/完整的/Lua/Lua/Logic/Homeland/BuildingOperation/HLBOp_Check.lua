
NewModule("HLBOp_Check")

function Check()
    -- 是不是在移动蓝图
    -- 是不是正在使用刷子
    -- 是不是手上拿着刷子
    -- 是不是手上拿着物件
    -- 是不是手上拿着自定义刷子
    -- 是不是选择着物件
    -- 在申请数据过程中
    if HLBOp_Blueprint.m_bMoveBlueprint then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_TAKE_OUT_REASON_BLUEPRINT, 3)
        return false
    end
    if HLBOp_Blueprint.m_bInLoadBlueprint then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_IN_LOADING_BLUEPRINT_FILE, 3)
        return false
    end
    if HLBOp_Brush.m_bMoveBrush then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_SELECT_REASON_PICKED_UP, 3)
        return false
    end
    if HLBOp_CustomBrush.m_bStartMove then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_SELECT_REASON_PICKED_UP, 3)
        return false
    end
    if HLBOp_Brush.m_dwModelID ~= 0 then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_SELECT_REASON_PICKED_UP, 3)
        return false
    end
    if HLBOp_Bottom.m_bMoveBottom then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_SELECT_REASON_PICKED_UP, 3)
        return false
    end
    if HLBOp_Bottom.m_bAutoBottomBrush then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_SELECT_REASON_PICKED_UP, 3)
        return false
    end
    if HLBOp_Bottom.m_dwModelID ~= 0 then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_SELECT_REASON_PICKED_UP, 3)
        return false
    end
    if HLBOp_Place.m_nBlueprintObjID ~= 0 then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_TAKE_OUT_REASON_BLUEPRINT, 3)
        return false
    end
    if HLBOp_Place.m_nCreateObjID ~= 0 then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_SELECT_REASON_PICKED_UP, 3)
        return false
    end
    if HLBOp_Place.m_nMoveObjID ~= 0 then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_SELECT_REASON_PICKED_UP, 3)
        return false
    end
    if HLBOp_MultiItemOp.m_bMoveMulti then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_SELECT_REASON_PICKED_UP, 3)
        return false
    end
    if HLBOp_Save.m_bDoDemolish then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_DEMOLISH_IN_DESTROY, 3)
        return false
    end
    if HLBOp_Amount.m_bInRequestConsumption then
        --HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_BUSY, 3)
        return false
    end
    if HLBOp_Amount.m_bInGetAllObject then
        --HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_BUSY, 3)
        return false
    end
    -- if Hotkey.IsKeyDown(GetKeyValue("Z")) or Hotkey.IsKeyDown(GetKeyValue("C")) then
    --     return false
    -- end
    return true
end

function CheckClickItem()
    if HLBOp_Blueprint.m_bMoveBlueprint then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_TAKE_OUT_REASON_BLUEPRINT, 3)
        return false
    end
    if HLBOp_Blueprint.m_bInLoadBlueprint then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_IN_LOADING_BLUEPRINT_FILE, 3)
        return false
    end
    if HLBOp_CustomBrush.m_bStartMove then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_SELECT_REASON_PICKED_UP, 3)
        return false
    end
    if HLBOp_Bottom.m_bAutoBottomBrush then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_SELECT_REASON_PICKED_UP, 3)
        return false
    end
    if HLBOp_Place.m_nBlueprintObjID ~= 0 then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_TAKE_OUT_REASON_BLUEPRINT, 3)
        return false
    end
    if HLBOp_MultiItemOp.m_bMoveMulti then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_SELECT_REASON_PICKED_UP, 3)
        return false
    end
    if HLBOp_Save.m_bDoDemolish then
    	HLBView_Message.Show(g_tStrings.STR_HOMELAND_DEMOLISH_IN_DESTROY, 3)
        return false
    end
    if HLBOp_Amount.m_bInRequestConsumption then
        --HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_BUSY, 3)
        return false
    end
    if HLBOp_Amount.m_bInGetAllObject then
        --HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_BUSY, 3)
        return false
    end
    -- if Hotkey.IsKeyDown(GetKeyValue("Z")) or Hotkey.IsKeyDown(GetKeyValue("C")) then
    --     return false
    -- end
    return true
end

function CheckNoHint()
    if HLBOp_Blueprint.m_bMoveBlueprint then
        return false
    end
    if HLBOp_Brush.m_bMoveBrush then
        return false
    end
    if HLBOp_CustomBrush.m_bStartMove then
        return false
    end
    if HLBOp_Brush.m_dwModelID ~= 0 then
        return false
    end
    if HLBOp_Bottom.m_bMoveBottom then
        return false
    end
    if HLBOp_Bottom.m_bAutoBottomBrush then
        return false
    end
    if HLBOp_Bottom.m_dwModelID ~= 0 then
        return false
    end
    if HLBOp_Place.m_nBlueprintObjID ~= 0 then
        return false
    end
    if HLBOp_Place.m_nCreateObjID ~= 0 then
        return false
    end
    -- if HLBOp_Place.m_nMoveObjID ~= 0 then
    --     return false
    -- end
    -- if HLBOp_MultiItemOp.m_bMoveMulti then
    --     return false
    -- end
    if HLBOp_Save.m_bDoDemolish then
        return false
    end
    if HLBOp_Amount.m_bInRequestConsumption then
        return false
    end
    if HLBOp_Amount.m_bInGetAllObject then
        return false
    end
    -- if Hotkey.IsKeyDown(GetKeyValue("Z")) or Hotkey.IsKeyDown(GetKeyValue("C")) then
    --     return false
    -- end
    return true
end

function CheckSave()
    if not HLBOp_Main.IsModified() then
        return false
    end
    -- if Hotkey.IsKeyDown(GetKeyValue("Z")) or Hotkey.IsKeyDown(GetKeyValue("C")) then
    --     return false
    -- end

    local tSelectObjs = HLBOp_Select.GetSelectInfo()
    if #tSelectObjs == 1 then
        HLBOp_Rotate.BackObjAngle(tSelectObjs[1])
    end

    local hlMgr = GetHomelandMgr()
	if hlMgr.IsSDSizeExceedLimit() or hlMgr.IsLandObjectSizeExceedLimit() then
        local szInfo = ""
		if hlMgr.IsSDSizeExceedLimit() then
			szInfo = g_tStrings.STR_HOMELAND_SD_SIZE_LIMIT_REACHED
		elseif hlMgr.IsLandObjectSizeExceedLimit() then
			szInfo = g_tStrings.STR_HOMELAND_INS_SIZE_LIMIT_REACHED
		end
		local szMsg = szInfo .. g_tStrings.STR_HOMELAND_SD_SIZE_LIMIT_REACHED_REMIND_3
		OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
		Homeland_Log(szMsg)
		return false
	end

    local tResult =	HLBOp_Other.GetErrorList()
	if not IsTableEmpty(tResult) then
        UIMgr.Open(VIEW_ID.PanelMissingItem)
        local szMsg = g_tStrings.STR_HOMELAND_FURNITURE_COUNT_CHECK_ERROR_WHEN_SAVING_M

        local bDigital = HLBOp_Enter.IsDigitalBlueprint()
        if not bDigital then
            szMsg = szMsg .. g_tStrings.STR_HOMELAND_FURNITURE_COUNT_CHECK_ERROR_WHEN_SAVING_EXPORT
        end

        local dialog = UIHelper.ShowConfirm(szMsg, nil, function ()
            HLBOp_Blueprint.ExportBlueprint(false)
        end)

        if bDigital then
            dialog:HideButton("Cancel")
        else
            dialog:SetButtonContent("Cancel", g_tStrings.STR_HOMELAND_EXPORT)
        end

        -- HLBView_Operations.CheckItemList()
		-- HLBView_ItemList.GoToErrorList()
		return false
	end
    return true
end

function CheckAutoSave()
    if not CheckNoHint() then
        return false
    end
    -- if Hotkey.IsKeyDown(GetKeyValue("Z")) or Hotkey.IsKeyDown(GetKeyValue("C")) then
    --     return false
    -- end

    if not HLBOp_Main.IsModified() then
        return false
    end

    local hlMgr = GetHomelandMgr()
	if hlMgr.IsSDSizeExceedLimit() or hlMgr.IsLandObjectSizeExceedLimit() then
		return false
	end

    local tResult =	hlMgr.BuildCheckAllFurniture()
	if not IsTableEmpty(tResult) then
		return false
	end
    return true
end

function CheckSDKFileLimit()
    if HLBOp_Blueprint.m_bMoveBlueprint then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_TAKE_OUT_REASON_BLUEPRINT, 3)
        return false
    end
    if HLBOp_Blueprint.m_bInLoadBlueprint then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_IN_LOADING_BLUEPRINT_FILE, 3)
        return false
    end
    if HLBOp_Brush.m_bMoveBrush then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_SELECT_REASON_PICKED_UP, 3)
        return false
    end
    if HLBOp_CustomBrush.m_bStartMove then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_SELECT_REASON_PICKED_UP, 3)
        return false
    end
    if HLBOp_Brush.m_dwModelID ~= 0 then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_SELECT_REASON_PICKED_UP, 3)
        return false
    end
    if HLBOp_Bottom.m_bMoveBottom then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_SELECT_REASON_PICKED_UP, 3)
        return false
    end
    if HLBOp_Bottom.m_bAutoBottomBrush then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_SELECT_REASON_PICKED_UP, 3)
        return false
    end
    if HLBOp_Bottom.m_dwModelID ~= 0 then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_SELECT_REASON_PICKED_UP, 3)
        return false
    end
    if HLBOp_Place.m_nBlueprintObjID ~= 0 then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_TAKE_OUT_REASON_BLUEPRINT, 3)
        return false
    end
    if HLBOp_Place.m_nCreateObjID ~= 0 then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_SELECT_REASON_PICKED_UP, 3)
        return false
    end
    if HLBOp_Place.m_nMoveObjID ~= 0 then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_SELECT_REASON_PICKED_UP, 3)
        return false
    end
    if HLBOp_MultiItemOp.m_bMoveMulti then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_SELECT_REASON_PICKED_UP, 3)
        return false
    end
    if HLBOp_Save.m_bDoDemolish then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_DEMOLISH_IN_DESTROY, 3)
        return false
    end
    return true
end

function CheckGridAlignment()
    if HLBOp_MultiItemOp.m_bMoveMulti then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_CANT_TOGGLE_GRID_ALIGNMENT_IN_MULTI_EDIT, 3)
        return false
    end
    return true
end

function CheckCopy()
    -- if Hotkey.IsKeyDown(GetKeyValue("Z")) or Hotkey.IsKeyDown(GetKeyValue("C")) then
    --     return false
    -- end
    if HLBOp_Place.IsMoveObj() or HLBOp_MultiItemOp.IsMoveObj() then
        HLBView_Message.Show(g_tStrings.STR_HOMELAND_BUILDING_CANT_COPY_WHILE_MOVING, 3)
        return false
    end
    return true
end

function CheckAdd(tStore)
    -- if Hotkey.IsKeyDown(GetKeyValue("Z")) or Hotkey.IsKeyDown(GetKeyValue("C")) then
    --     return false
    -- end
    local tConfig = Homeland_GetModeConfig(HLBOp_Main.GetBuildMode())
    local hlMgr = GetHomelandMgr()
    for k, v in ipairs(tStore) do
		local nModelID, nModelAmount = v.nModelID, v.nModelAmount
        local tInfo = FurnitureData.GetFurnInfoByModelID(nModelID)
		if tInfo then
            --分类数量限制
            local nCatg1, nCatg2 = tInfo.nCatg1Index, tInfo.nCatg2Index
            local nUsedCount = hlMgr.BuildGetCategoryCount(nCatg1, nCatg2)
            local tLevelConfig = hlMgr.GetLevelFurnitureConfig(nCatg1, nCatg2, HLBOp_Enter.GetLevel())
            local nLimitAmount = tLevelConfig and tLevelConfig.LimCount
            if nUsedCount + nModelAmount > nLimitAmount then
                local tCatg1Info = FurnitureData.GetCatg1Info(nCatg1)
                local tCatg2Info = FurnitureData.GetCatg2Info(nCatg1, nCatg2)
                local szMsg = FormatString(g_tStrings.STR_HOMELAND_CATEGORY_LIMIT_REACHED, UIHelper.GBKToUTF8(tCatg1Info.szName), UIHelper.GBKToUTF8(tCatg2Info.szName))
                local scriptView = UIHelper.ShowConfirm(szMsg)
                scriptView:HideButton("Cancel")
                return false
            end

            --单个物件数量限制
            if tInfo.nFurnitureType == HS_FURNITURE_TYPE.FURNITURE or
                tInfo.nFurnitureType == HS_FURNITURE_TYPE.PENDANT then
                local nLimitAmount = nil
                if tInfo.nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
                    local tConfig = hlMgr.GetFurnitureConfig(tInfo.dwFurnitureID)
                    nLimitAmount = tConfig.nMaxAmountPerLand
                else
                    nLimitAmount = 1
                end

                local nUsedCount = hlMgr.BuildGetOnLandFurniture(tInfo.nFurnitureType, tInfo.dwFurnitureID)
                if nUsedCount + nModelAmount > nLimitAmount then
                    local szMsg = FormatString(g_tStrings.STR_HOMELAND_ITEM_CONSUME_LIMIT_REACHED_FROM_BRUSH, UIHelper.GBKToUTF8(tInfo.szName))
                    local scriptView = UIHelper.ShowConfirm(szMsg)
                    scriptView:HideButton("Cancel")
                    return false
                end
            end
		end
	end
    if tConfig.bDesign then
        return true
    end


    local tLackList = {}
	for k, v in ipairs(tStore) do
		local nModelID, nModelAmount = v.nModelID, v.nModelAmount
        local tInfo = FurnitureData.GetFurnInfoByModelID(nModelID)
		if tInfo then
            --数量欠缺
            local nFurnitureType, nFurnitureID = tInfo.nFurnitureType, tInfo.dwFurnitureID
            local nLeftAmount = hlMgr.BuildGetFurnitureCanUse(nFurnitureType, nFurnitureID)
            if nLeftAmount < nModelAmount then
                table.insert(tLackList, {nFurnitureID = nFurnitureID,
                    nFurnitureType = nFurnitureType, nAmount = nModelAmount - nLeftAmount})
            end
		end
	end
    local szMsg = ""
    if #tLackList == 1 then
        local tItem = tLackList[1]
        if tItem.nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
            local tConfig = hlMgr.GetFurnitureConfig(tItem.nFurnitureID)
            local tCoinInfo = FurnitureBuy.GetFurnitureInfo(tItem.nFurnitureID)
            local bSpecialBuy = FurnitureBuy.IsSpecialFurnitrueCanBuy(tItem.nFurnitureID)
            if tConfig.nLevelLimit > HLBOp_Enter.GetLevel() then
                local tInfo = FurnitureData.GetFurnInfoByTypeAndID(tItem.nFurnitureType, tItem.nFurnitureID)
                szMsg = FormatString(g_tStrings.STR_HOMELAND_THIS_ITEM_LEVEL_TOO_HIGH, UIHelper.GBKToUTF8(tInfo.szName), tConfig.nLevelLimit)
            elseif tCoinInfo and tCoinInfo.bSell then
                HLBOp_Camera.OnRBtnClick()
                UIMgr.Open(VIEW_ID.PanelTongBaoPurchasePop, true, {{dwFurnitureID = tItem.nFurnitureID, nNum = tItem.nAmount}})
            elseif tConfig.nArchitecture > 0 then
                HLBOp_Camera.OnRBtnClick()
                UIMgr.Open(VIEW_ID.PanelItemPurchasePop, {{dwFurnitureID = tItem.nFurnitureID, nNum = tItem.nAmount}})
            elseif bSpecialBuy then
                HLBOp_Camera.OnRBtnClick()
                UIMgr.Open(VIEW_ID.PanelItemPurchasePop, {{dwFurnitureID = tItem.nFurnitureID, nNum = tItem.nAmount}})
            else
                szMsg = g_tStrings.STR_HOMELAND_ITEM_STORAGE_USED_UP
            end
        elseif tItem.nFurnitureType == HS_FURNITURE_TYPE.PENDANT then
            --local ePendantState = hlMgr.GetPendantFurniture(tItem.nFurnitureID)
            local bHavePendant = hlMgr.GetPendantFurniture(tItem.nFurnitureID)
            local tInfo = FurnitureData.GetFurnInfoByTypeAndID(HS_FURNITURE_TYPE.PENDANT, tItem.nFurnitureID)
            local tLine = FurnitureData.GetPendantInfo(tInfo.nCatg1Index, tInfo.nCatg2Index)
            --if ePendantState == HS_PENDANT_STATE_TYPE.NOT_ACQUIRED then
            if not bHavePendant then
                szMsg = UIHelper.GBKToUTF8(tLine.szPlaceTip)
            else
                local nPrevAmountInLand = hlMgr.BuildGetFurnitureCanUse(tItem.nFurnitureType, tItem.nFurnitureID) - 1
                if nPrevAmountInLand > 0 then
                    szMsg = g_tStrings.STR_HOMELAND_PENDANT_ITEM_STORAGE_USED_UP_2
                else
                    local tCatg2Info = FurnitureData.GetCatg2Info(tInfo.nCatg1Index, tInfo.nCatg2Index)
                    szMsg = FormatString(g_tStrings.STR_HOMELAND_PENDANT_ITEM_STORAGE_USED_UP_3, UIHelper.GBKToUTF8(tCatg2Info.szName), UIHelper.GBKToUTF8(tInfo.szName), UIHelper.GBKToUTF8(tLine.szTitle))
                end
            end
        end
        if szMsg ~= "" then
            local scriptView = UIHelper.ShowConfirm(szMsg)
            scriptView:HideButton("Cancel")
        end

        return false
    elseif #tLackList > 1 then
        local bFurniture, bPendant, bSpecBuy, bCoinBuy, bArchBuy  = false, false, false, false, false
        local tBuyList = {}
        for i = 1, #tLackList do
            local tItem = tLackList[i]
            if tItem.nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
                local tConfig = hlMgr.GetFurnitureConfig(tItem.nFurnitureID)
                local tCoinInfo = FurnitureBuy.GetFurnitureInfo(tItem.nFurnitureID)
                local bSpecialBuy = FurnitureBuy.IsSpecialFurnitrueCanBuy(tItem.nFurnitureID)
                if tCoinInfo and tCoinInfo.bSell then
                    table.insert(tBuyList, {dwFurnitureID = tItem.nFurnitureID, nNum = tItem.nAmount})
                    bCoinBuy = true
                elseif tConfig.nArchitecture > 0 then
                    table.insert(tBuyList, {dwFurnitureID = tItem.nFurnitureID, nNum = tItem.nAmount})
                    bArchBuy = true
                elseif bSpecialBuy then
                    table.insert(tBuyList, {dwFurnitureID = tItem.nFurnitureID, nNum = tItem.nAmount})
                    bSpecBuy = true
                else
                    szMsg = g_tStrings.STR_HOMELAND_ITEM_STORAGE_USED_UP
                end
                bFurniture = true
            elseif tItem.nFurnitureType == HS_FURNITURE_TYPE.PENDANT then
                bPendant = true
            end
        end
        if bFurniture and bPendant then
            szMsg = g_tStrings.STR_HOMELAND_ITEM_STORAGE_USED_UP
        end
        if bCoinBuy and (not bArchBuy) and (not bSpecBuy) then
            HLBOp_Camera.OnRBtnClick()
            UIMgr.Open(VIEW_ID.PanelTongBaoPurchasePop, true, tBuyList)
        elseif bArchBuy and (not bCoinBuy) and (not bSpecBuy) then
            HLBOp_Camera.OnRBtnClick()
            UIMgr.Open(VIEW_ID.PanelItemPurchasePop, tBuyList)
        elseif bSpecBuy and (not bCoinBuy) and (not bArchBuy) then
            HLBOp_Camera.OnRBtnClick()
            UIMgr.Open(VIEW_ID.PanelItemPurchasePop, tBuyList)
        else
            szMsg = g_tStrings.STR_HOMELAND_ITEM_STORAGE_USED_UP
        end
        if szMsg ~= "" then
            local scriptView = UIHelper.ShowConfirm(szMsg)
            scriptView:HideButton("Cancel")
        end

        return false
    end
    return true
end

function Init()

end

function UnInit()

end