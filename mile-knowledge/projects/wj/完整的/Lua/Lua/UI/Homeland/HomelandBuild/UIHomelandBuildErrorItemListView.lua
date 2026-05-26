-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildErrorItemListView
-- Date: 2023-05-29 10:38:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildErrorItemListView = class("UIHomelandBuildErrorItemListView")
local BuyCDTotalTime = 10

local tErrorInfo =
{
	["CanArchBuy"] = {szName = "CBox_ShortNum_ArchBuy", bCanBuy = true, bCanDel = true, bCanCheck = true, bOverflow = false, bQuickProcess = false},
	["CanCoinBuy"] = {szName = "CBox_ShortNum_CoinBuy", bCanBuy = true, bCanDel = true, bCanCheck = true, bOverflow = false, bQuickProcess = false},
	["SpecialArchBuy"] = {szName = "CBox_ShortNum_Spec_Collected", bCanBuy = true, bCanDel = true, bCanCheck = true, bOverflow = false, bQuickProcess = false},
	["GetSpecial"] = {szName = "CBox_ShortNum_Spec", bCanBuy = false, bCanDel = true, bCanCheck = true, bOverflow = false, bQuickProcess = false},
	["LevelOverflow"] = {szName = "CBox_OverLevel", bCanBuy = false, bCanDel = true, bCanCheck = true, bOverflow = false, bQuickProcess = false},
	["CatgOverflow"] = {szName = "CBox_Maximum", bCanBuy = false, bCanDel = false, bCanCheck = false, bOverflow = true, bQuickProcess = true},
}

local DataModel = {}

function DataModel.Init()
	DataModel.nLastFreshBuyTime = 0
	DataModel.nCooldownBuyTime = 0
	DataModel.tErrorList = {}
	DataModel.tModelID2ObjID = {}
	DataModel.tSelectModelID = {}
	DataModel.szChoose = nil
end

function DataModel.UnInit()
	DataModel.nLastFreshBuyTime = 0
	DataModel.nCooldownBuyTime = 0
	DataModel.tErrorList = {}
	DataModel.tModelID2ObjID = {}
	DataModel.tSelectModelID = {}
	DataModel.szChoose = nil
end

function DataModel.UpdateSomeInfo()
	local tAllObject = HLBOp_Amount.GetAllObjIDInfo()
	if not tAllObject then
		return
	end
	DataModel.tModelID2ObjID = {}
	for dwObjID, dwModelID in pairs(tAllObject) do
		local tInfo = FurnitureData.GetFurnInfoByModelID(dwModelID)
		if tInfo then
			if not DataModel.tModelID2ObjID[tInfo.dwModelID] then
				DataModel.tModelID2ObjID[tInfo.dwModelID] = {}
			end
			table.insert(DataModel.tModelID2ObjID[tInfo.dwModelID], dwObjID)
		end
	end
end

function DataModel.UpdateBuyFresh()
	DataModel.nCooldownBuyTime = DataModel.nCooldownBuyTime - 1
end

function DataModel.UpdateSelectModelID(tModelID)
	DataModel.tSelectModelID = tModelID
end

function DataModel.UpdateErrorItemCommon(szErrorType, nNum, tInfo, tErrorItem)
	tErrorItem.szName = tInfo.szName
	tErrorItem.nQuality = tInfo.nQuality
	tErrorItem.tRGB = Homeland_GetFurnitureRGBByQuality(tInfo.nQuality)
	local dwFurnitureUiId = GetHomelandMgr().MakeFurnitureUIID(tInfo.nFurnitureType, tInfo.dwFurnitureID)
	local tAddInfo = Table_GetFurnitureAddInfo(dwFurnitureUiId)
	if tAddInfo then
		tErrorItem.szImgPath = tAddInfo.szPath
	end
	tErrorItem.nFurnitureType = tInfo.nFurnitureType
	tErrorItem.dwFurnitureID = tInfo.dwFurnitureID
	tErrorItem.dwModelID = tInfo.dwModelID
	tErrorItem.nNum = nNum
	tErrorItem.szErrorType = szErrorType
end

function DataModel.UpdateErrorItemCanBuy(tInfo, nNum, tErrorItem)
	local tConfig = GetHomelandMgr().GetFurnitureConfig(tInfo.dwFurnitureID)
	local tCoinInfo = FurnitureBuy.GetFurnitureInfo(tInfo.dwFurnitureID)
	if tCoinInfo then
		local nMoney = tCoinInfo.nFinalCoin * nNum
		tErrorItem.nCoinMoney = nMoney
		tErrorItem.bSell = tCoinInfo.bSell
		local nDiscount, bInDiscount = FurnitureBuy.GetCoinBuyFurnitureDiscount(tInfo.dwFurnitureID)
		if bInDiscount then
			tErrorItem.nDiscount = nDiscount
			tErrorItem.nOriCoin = tCoinInfo.nCoin * nNum
		end
		table.insert(DataModel.tErrorList.tCanCoinBuy, tErrorItem)
	elseif tConfig then
		local nMoney = tConfig.nFinalArchitecture * nNum
		tErrorItem.nArchMoney = nMoney
		local nDiscount, bInDiscount = FurnitureBuy.GetArchBuyFurnitureDiscount(tInfo.dwFurnitureID)
		if bInDiscount then
			tErrorItem.nDiscount = nDiscount
			tErrorItem.nOriArch = tConfig.nArchitecture * nNum
		end
		table.insert(DataModel.tErrorList.tCanArchBuy, tErrorItem)
	end
end

function DataModel.UpdateErrorItemGetSpecial(szErrorType, tErrorItem)
	if szErrorType == "ItemShort" then
		local szInfo = g_tStrings.STR_FURNITURE_ERROR_LIST_INFO[szErrorType][2]
		tErrorItem.szInfo = szInfo
		if FurnitureData.IsReplaceable(tErrorItem.dwModelID) then
			tErrorItem.bCanReplace = true
		end
	elseif szErrorType == "BrushShort" then
		local szInfo = g_tStrings.STR_FURNITURE_ERROR_LIST_INFO[szErrorType]
		tErrorItem.szInfo = szInfo
	end
	table.insert(DataModel.tErrorList.tGetSpecial, tErrorItem)
end

function DataModel.UpdateErrorItemSpecialArchBuy(szErrorType, tErrorItem)
	if szErrorType == "ItemShort" then
		if FurnitureData.IsReplaceable(tErrorItem.dwModelID) then
			tErrorItem.bCanReplace = true
		end
		local hlMgr = GetHomelandMgr()
		local tConfig = hlMgr.GetFurnitureConfig(tErrorItem.dwFurnitureID)
		tErrorItem.nArchMoney = tConfig.nReBuyCost * tErrorItem.nNum
	end
	table.insert(DataModel.tErrorList.tSpecialArchBuy, tErrorItem)
end

function DataModel.UpdateErrorItemOverLevel(szErrorType, nNum, tInfo, tErrorItem)
	if szErrorType == "ItemShort" then
		local tConfig = GetHomelandMgr().GetFurnitureConfig(tInfo.dwFurnitureID)
		tErrorItem.nLevelLimit = tConfig.nLevelLimit
	elseif szErrorType == "Level" then
		local tConfig = GetHomelandMgr().GetFurnitureConfig(tInfo.dwFurnitureID)
		tErrorItem.nLevelLimit = tConfig.nLevelLimit
	end
	tErrorItem.nTotalNum = #DataModel.tModelID2ObjID[tInfo.dwModelID]
	table.insert(DataModel.tErrorList.tLevelOverflow, tErrorItem)
end

function DataModel.GetModelConsumptionInCatg(nCatg1Index, nCatg2Index)
	local hlMgr = GetHomelandMgr()
	local nUsedCount = hlMgr.BuildGetCategoryCount(nCatg1Index, nCatg2Index)
	local tLevelConfig = hlMgr.GetLevelFurnitureConfig(nCatg1Index, nCatg2Index, HLBOp_Enter.GetLevel())
	local nLimitAmount = tLevelConfig and tLevelConfig.LimCount
	return nUsedCount, nLimitAmount
end

function DataModel.UpdateErrorItemOverflow(szErrorType, nNum, tCatg, tInfo, tErrorItem)
	if szErrorType == "CatgOverflow" then
		local nCatg1, nCatg2 = tCatg[1], tCatg[2]
		local tCatg1UIInfo = FurnitureData.GetCatg1Info(nCatg1)
		local tCatg2UIInfo = FurnitureData.GetCatg2Info(nCatg1, nCatg2)
		local szName = FormatString(g_tStrings.STR_ARENA_V_L, tCatg1UIInfo.szName, tCatg2UIInfo.szName)
		tErrorItem.szName = szName
		tErrorItem.tUITexInfo = {szPath = tCatg2UIInfo.szIconImgPath, nFrame = tCatg2UIInfo.nIconFrameNormal}
		tErrorItem.nCatg1 = nCatg1
		tErrorItem.nCatg2 = nCatg2
		local nUsedCount, nLimitAmount = DataModel.GetModelConsumptionInCatg(nCatg1, nCatg2)
		tErrorItem.nUsedCount = nUsedCount
		tErrorItem.nLimitAmount = nLimitAmount
		local nNeedLevel = HLBOp_Enter.GetLevel()
		local nMaxLevel = HOMELAND_MAX_LEVEL
		for i = nNeedLevel + 1, nMaxLevel do
			local tLevel = GetHomelandMgr().GetLevelFurnitureConfig(nCatg1, nCatg2, i)
			nNeedLevel = i
			if tLevel.LimCount >= nUsedCount then
				break
			end
		end
		tErrorItem.nNeedLevel = nNeedLevel
	elseif szErrorType == "ItemOverflow" then
		local szInfo = g_tStrings.STR_FURNITURE_ERROR_LIST_TYPE[szErrorType]
		local tConfig = GetHomelandMgr().GetFurnitureConfig(tInfo.dwFurnitureID)
		DataModel.UpdateErrorItemCommon(szErrorType, nNum, tInfo, tErrorItem)
		tErrorItem.nUsedCount = nNum + tConfig.nMaxAmountPerLand
		tErrorItem.nLimitAmount = tConfig.nMaxAmountPerLand
		tErrorItem.szInfo = szInfo
	elseif szErrorType == "PendantOverflow" then
		local szInfo = g_tStrings.STR_FURNITURE_ERROR_LIST_TYPE[szErrorType]
		DataModel.UpdateErrorItemCommon(szErrorType, nNum, tInfo, tErrorItem)
		tErrorItem.nLimitAmount = 1
		tErrorItem.nUsedCount = nNum + tErrorItem.nLimitAmount
		tErrorItem.szInfo = szInfo
	end
	tErrorItem.bOverflow = true
	table.insert(DataModel.tErrorList.tCatgOverflow, tErrorItem)
end

function DataModel.UpdateErrorItem(szErrorType, dwModelID, nNum, tCatg)
	local tErrorItem = {}

	local tInfo
	if dwModelID then
		tInfo = FurnitureData.GetFurnInfoByModelID(dwModelID)
	end

	if nNum and nNum < 0 then
		nNum = -nNum
	end

	if szErrorType == "CatgOverflow" or szErrorType == "ItemOverflow" or szErrorType == "PendantOverflow" then
		DataModel.UpdateErrorItemOverflow(szErrorType, nNum, tCatg, tInfo, tErrorItem)
	elseif szErrorType == "BrushShort" then
		DataModel.UpdateErrorItemCommon(szErrorType, nil, tInfo, tErrorItem)
		DataModel.UpdateErrorItemGetSpecial(szErrorType, tErrorItem)
	elseif DataModel.tModelID2ObjID[tInfo.dwModelID] then
		DataModel.UpdateErrorItemCommon(szErrorType, nNum, tInfo, tErrorItem)
		if szErrorType == "ItemShort" then
			local bCanBuy, eCantBuyReason = HomelandEventHandler.CanBuyFurnitureWithArchitecture(tInfo.dwFurnitureID, false, 1)
			if not bCanBuy then
				if eCantBuyReason == HomelandEventHandler.FURNITURE_CANT_BUY_REASON.LEVEL_TOO_HIGH then
					-- 等级
					DataModel.UpdateErrorItemOverLevel(szErrorType, nNum, tInfo, tErrorItem)
				elseif eCantBuyReason == HomelandEventHandler.FURNITURE_CANT_BUY_REASON.NOT_BY_ARCHITECTURE then
					local tCoinInfo = FurnitureBuy.GetFurnitureInfo(tInfo.dwFurnitureID)
					if tCoinInfo then
						DataModel.UpdateErrorItemCanBuy(tInfo, nNum, tErrorItem)
					else
						-- 特殊
						if tInfo.nFurnitureType == HS_FURNITURE_TYPE.FURNITURE and
							FurnitureBuy.IsSpecialFurnitrueCanBuy(tInfo.dwFurnitureID) then
							DataModel.UpdateErrorItemSpecialArchBuy(szErrorType, tErrorItem)
						else
							DataModel.UpdateErrorItemGetSpecial(szErrorType, tErrorItem)
						end
					end
				else
					DataModel.UpdateErrorItemCanBuy(tInfo, nNum, tErrorItem)
				end
			else
				-- 购买
				DataModel.UpdateErrorItemCanBuy(tInfo, nNum, tErrorItem)
			end
		elseif szErrorType == "PendantShort" then
			-- 拓印前需
			local nCatg1, nCatg2 = tInfo.nCatg1Index, tInfo.nCatg2Index
			local bCanIsotype, szCantType = Homeland_CanIsotypePendant(tInfo.dwFurnitureID)
			local tLine = FurnitureData.GetPendantInfo(nCatg1, nCatg2)
			if not bCanIsotype and PENDANT_ERROR_TYPE.NOT_ACQUIRED then
				szInfo = UIHelper.GBKToUTF8(tLine.szBeforeCollect)
			else
				szInfo = UIHelper.GBKToUTF8(tLine.szAfterCollect)
				tErrorItem.bPendantBuy = true
			end
			tErrorItem.szInfo = szInfo
			DataModel.UpdateErrorItemGetSpecial(szErrorType, tErrorItem)
		elseif szErrorType == "Level" then
			DataModel.UpdateErrorItemOverLevel(szErrorType, nNum, tInfo, tErrorItem)
		end
	end
end

function DataModel.UpdateErrorList()
	local tErrorList = HLBOp_Other.GetErrorList()
	DataModel.tErrorList.tCanArchBuy = {}
	DataModel.tErrorList.tCanCoinBuy = {}
	DataModel.tErrorList.tSpecialArchBuy = {}
	DataModel.tErrorList.tGetSpecial = {}
	DataModel.tErrorList.tLevelOverflow = {}
	DataModel.tErrorList.tCatgOverflow = {}
	for szErrorType, tErrorItems in pairs(tErrorList) do
		if szErrorType == "CatgOverflow" then
			for _, tCatg in pairs(tErrorItems) do
				DataModel.UpdateErrorItem(szErrorType, nil, nil, tCatg)
			end
		elseif szErrorType == "ItemShort" or szErrorType == "ItemOverflow" or szErrorType == "PendantOverflow" or szErrorType == "BrushShort" then
			for dwModelID, nNum in pairs(tErrorItems) do
				DataModel.UpdateErrorItem(szErrorType, dwModelID, nNum, nil)
			end
		else -- "LevelOverflow"
			for _, dwModelID in pairs(tErrorItems) do
				DataModel.UpdateErrorItem(szErrorType, dwModelID, nil, nil)
			end
		end
	end
	local function comp(tL, tR)
		if tL.bSell == nil or tR.bSell == nil then
			return false
		end
		if tL.bSell == tR.bSell then
			return false
		end
		return tL.bSell
	end
	local function compArch(tL, tR)
		if tL.nArchMoney and tR.nArchMoney then
			return tL.nArchMoney > tR.nArchMoney
		end
		return false
	end
	table.sort(DataModel.tErrorList.tCanCoinBuy, comp)
	table.sort(DataModel.tErrorList.tCanArchBuy, compArch)
	DataModel.SetChoose()
end

function DataModel.SetChoose()
	if (not DataModel.szChoose) or
		#DataModel.tErrorList['t' .. DataModel.szChoose] == 0 then
		if #DataModel.tErrorList.tCanArchBuy > 0 then
			DataModel.szChoose = "CanArchBuy"
		elseif #DataModel.tErrorList.tCanCoinBuy > 0 then
			DataModel.szChoose = "CanCoinBuy"
		elseif #DataModel.tErrorList.tSpecialArchBuy > 0 then
			DataModel.szChoose = "SpecialArchBuy"
		elseif #DataModel.tErrorList.tGetSpecial > 0 then
			DataModel.szChoose = "GetSpecial"
		elseif #DataModel.tErrorList.tLevelOverflow > 0 then
			DataModel.szChoose = "LevelOverflow"
		elseif #DataModel.tErrorList.tCatgOverflow > 0 then
			DataModel.szChoose = "CatgOverflow"
		else
			DataModel.szChoose = nil
		end
	end
end

local function IsCanCheck()
	local szChoose = DataModel.szChoose
	return tErrorInfo[szChoose].bCanCheck
end

function UIHomelandBuildErrorItemListView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    DataModel.Init()
    DataModel.UpdateSomeInfo()
    DataModel.UpdateErrorList()
    self:UpdateInfo()
end

function UIHomelandBuildErrorItemListView:OnExit()
    self.bInit = false
end

function UIHomelandBuildErrorItemListView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

	UIHelper.BindUIEvent(self.BtnBatchDelete, EventType.OnClick, function ()
		local nCount, nCountChecked, nTotleArch, nTotleCoin, nTotalGold, tModelID = self:GetSelectedItemInfo()
		UIHelper.ShowConfirm(g_tStrings.STR_HOMELAND_BUILDING_DELALL_ENSURE, function ()
			self:BatchDelete(tModelID)
		end)
    end)

	UIHelper.BindUIEvent(self.BtnBatchBuy, EventType.OnClick, function ()
		self:StartBuyCD()
		self:BatchBuy()
    end)

	UIHelper.BindUIEvent(self.BtnOutputList, EventType.OnClick, function ()
        HLBOp_Other.ExportAllErrorList(DataModel.tErrorList)
    end)

	UIHelper.BindUIEvent(self.TogSelect, EventType.OnClick, function ()
        local bSelected = UIHelper.GetSelected(self.TogSelect)
		self:SetAllItemSelected(bSelected)
		self:UpdateBtnState()
    end)

end

function UIHomelandBuildErrorItemListView:RegEvent()
    local function UpdateData()
		if self.nUpdateDataTimerID then
			Timer.DelTimer(self, self.nUpdateDataTimerID)
			self.nUpdateDataTimerID = nil
		end
		self.nUpdateDataTimerID = Timer.Add(self, 0.5, function ()
			DataModel.UpdateSomeInfo()
			DataModel.UpdateErrorList()
			self:UpdateInfo()
		end)
    end

    Event.Reg(self, "LUA_HOMELAND_UPDATE_LANDDATA", UpdateData)
    Event.Reg(self, "HOME_LAND_CHANGE_FURNITURE", UpdateData)
    Event.Reg(self, "HOME_LAND_CHANGE_PENDANT_FURNITURE", UpdateData)
    Event.Reg(self, "HOME_LAND_CHANGE_PAINTBRUSH", UpdateData)

    Event.Reg(self, "LUA_HOMELAND_FRESH_ITEM_LIST", UpdateData)

    Event.Reg(self, EventType.OnSelectedHomelandBuildErrorListCell, function ()
		self:UpdateBtnState()
	end)
end

function UIHomelandBuildErrorItemListView:UpdateInfo()
    self:UpdateTypeInfo()
    self:UpdateItemInfo()
    self:UpdateBtnState()
end

local tbTypeKey = {
    "CanArchBuy",
    "CanCoinBuy",
    "SpecialArchBuy",
    "GetSpecial",
    "LevelOverflow",
    "CatgOverflow",
}
function UIHomelandBuildErrorItemListView:UpdateTypeInfo()
    self.tbTypeCell = self.tbTypeCell or {}
    UIHelper.HideAllChildren(self.ScrollViewCategoryList)
	local nCount = 0
    for i, szKey in ipairs(tbTypeKey) do
        if #DataModel.tErrorList["t"..szKey] > 0 then
			nCount = nCount + 1
            local cell = self.tbTypeCell[i]
            if not cell then
                cell = UIHelper.AddPrefab(PREFAB_ID.WidgetMissingCategoryCell, self.ScrollViewCategoryList)
                self.tbTypeCell[i] = cell
				UIHelper.ToggleGroupAddToggle(self.TogGroupCategory, cell.TogSelect)
            end

            UIHelper.SetVisible(cell._rootNode, true)
            cell:OnEnter(DataModel, szKey)
        end
    end

	for i, cell in ipairs(self.tbTypeCell) do
		if UIHelper.GetVisible(cell._rootNode) and cell.szKey == DataModel.szChoose then
			UIHelper.SetSelected(cell.TogSelect, true)
		else
			UIHelper.SetSelected(cell.TogSelect, false)
		end
	end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCategoryList)

	if nCount <= 0 then
		TipsHelper.ShowNormalTip("已处理所有缺失物件")
		UIMgr.Close(self)
	end
end

function UIHomelandBuildErrorItemListView:UpdateItemInfo()
    self.tbItemCell = self.tbItemCell or {}
    self.tbItemTypeCell = self.tbItemTypeCell or {}
    UIHelper.HideAllChildren(self.ScrollViewMissingItemList)
    if DataModel.szChoose == nil then
        return
    end

    local tbItems = DataModel.tErrorList["t"..DataModel.szChoose]
    if not tbItems or #tbItems <= 0 then
        return
    end

	local tbSetting = tErrorInfo[DataModel.szChoose]
    if tbSetting.bCanCheck then
        for i, tbInfo in ipairs(tbItems) do
            local cell = self.tbItemCell[i]
            if not cell then
                cell = UIHelper.AddPrefab(PREFAB_ID.WidgetMissingItemToggleCell, self.ScrollViewMissingItemList)
                self.tbItemCell[i] = cell
            end

            UIHelper.SetVisible(cell._rootNode, true)
            cell:OnEnter(DataModel, tbInfo)
        end
    else
        for i, tbInfo in ipairs(tbItems) do
            local cell = self.tbItemTypeCell[i]
            if not cell then
                cell = UIHelper.AddPrefab(PREFAB_ID.WidgetMissingTypeCell, self.ScrollViewMissingItemList)
                self.tbItemTypeCell[i] = cell
            end

            UIHelper.SetVisible(cell._rootNode, true)
            cell:OnEnter(DataModel, tbInfo)
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewMissingItemList)
	self:SetAllItemSelected(true)
end

function UIHomelandBuildErrorItemListView:UpdateBtnState()
	local tbSetting = tErrorInfo[DataModel.szChoose]
	if not tbSetting then
		UIHelper.SetVisible(self.WidgetAnchorBatchOper, false)
		UIHelper.SetVisible(self.WidgetAnchorQuickOper, false)
		return
	end

	UIHelper.SetVisible(self.WidgetAnchorBatchOper, not tbSetting.bQuickProcess)
	-- UIHelper.SetVisible(self.WidgetAnchorQuickOper, tbSetting.bQuickProcess)
	UIHelper.SetVisible(self.WidgetAnchorQuickOper, false)

	local nCount, nCountChecked, nTotleArch, nTotleCoin, nTotalGold, tModelID = self:GetSelectedItemInfo()
	-- LOG.TABLE({nCount = nCount, nCountChecked = nCountChecked, nTotleArch = nTotleArch, nTotleCoin = nTotleCoin, nTotalGold = nTotalGold})

	if tbSetting.bCanBuy and nCountChecked > 0 and not self.bInBuyCD then
		UIHelper.SetVisible(self.LayoutCoin, true)
		if nTotleArch > 0 then
			UIHelper.SetString(self.LabelMoney_Zhuan, nTotleArch)
			UIHelper.SetSpriteFrame(self.ImgZhuan, "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_YuanZhaiBi.png")
		elseif nTotleCoin > 0 then
			UIHelper.SetString(self.LabelMoney_Zhuan, nTotleCoin)
			UIHelper.SetSpriteFrame(self.ImgZhuan, "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_TongBao.png")
		elseif nTotalGold > 0 then
			UIHelper.SetString(self.LabelMoney_Zhuan, nTotalGold)
			UIHelper.SetSpriteFrame(self.ImgZhuan, "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Jin.png")
		end
		UIHelper.LayoutDoLayout(self.LayoutCoin)
		UIHelper.SetButtonState(self.BtnBatchBuy, BTN_STATE.Normal)
	else
		UIHelper.SetVisible(self.LayoutCoin, false)
		UIHelper.SetButtonState(self.BtnBatchBuy, BTN_STATE.Disable)
	end

	UIHelper.SetSelected(self.TogSelect, nCount == nCountChecked)
end

function UIHomelandBuildErrorItemListView:SetAllItemSelected(bSelected)
	for i, cell in ipairs(self.tbItemCell) do
		cell:SetSelected(bSelected)
	end
end

function UIHomelandBuildErrorItemListView:GetSelectedItemInfo()
	local nCount = 0
	local nCountChecked = 0
	local nTotleArch = 0
	local nTotleCoin = 0
	local nTotalGold = 0
	local tModelID = {}

	for i, cell in ipairs(self.tbItemCell) do
		if UIHelper.GetVisible(cell._rootNode) then
			local bSelected, dwModelID, nArchMoney, nCoinMoney, nGold = cell:GetItemInfo()
			nCount = nCount + 1
			if bSelected then
				nCountChecked = nCountChecked + 1

				nTotleArch = nTotleArch + nArchMoney
				nTotleCoin = nTotleCoin + nCoinMoney
				nTotalGold = nTotalGold + nGold

				if dwModelID > 0 then
					table.insert(tModelID, dwModelID)
				end
			end
		end
	end

	return nCount, nCountChecked, nTotleArch, nTotleCoin, nTotalGold, tModelID
end

function UIHomelandBuildErrorItemListView:GetSelectedItemFurnitureInfo()
	local nCount = 0
	local nCountChecked = 0
	local bHaveForbidBuy = false
	local tbFurnitureInfo = {}

	for i, cell in ipairs(self.tbItemCell) do
		if UIHelper.GetVisible(cell._rootNode) then
			local bSelected, dwFurnitureID, nNum, bForbidBuy = cell:GetItemFurnitureInfo()
			nCount = nCount + 1
			if bSelected then
				nCountChecked = nCountChecked + 1

				if bForbidBuy then
					bHaveForbidBuy = true
				end

				if dwFurnitureID and dwFurnitureID > 0 and nNum and nNum > 0 then
					table.insert(tbFurnitureInfo, {
						dwFurnitureID = dwFurnitureID,
						nNum = nNum,
					})
				end
			end
		end
	end

	return nCount, nCountChecked, bHaveForbidBuy, tbFurnitureInfo
end

function UIHomelandBuildErrorItemListView:BatchDelete(tModelIDs)
	local tDelFloorBrush = {}
	local tNormalFurniture = {}
	HLBOp_Select.ClearSelect()

	for i = 1, #tModelIDs do
		local dwModelID = tModelIDs[i]
		local tUIInfo = FurnitureData.GetFurnInfoByModelID(dwModelID)
		if tUIInfo and tUIInfo.nFurnitureType == HS_FURNITURE_TYPE.APPLIQUE_BRUSH then
			table.insert(tDelFloorBrush, dwModelID)
		elseif tUIInfo and tUIInfo.nFurnitureType == HS_FURNITURE_TYPE.FOLIAGE_BRUSH then
			HLBOp_CustomBrush.DelSingleFlowerBrush(dwModelID)
		else
			table.insert(tNormalFurniture, dwModelID)
		end
	end
	HLBOp_CustomBrush.DelFloorBrush(tDelFloorBrush)

	for _, dwModelID in pairs(tNormalFurniture) do
		HLBOp_Select.SelectModelItemWithoutOutline(dwModelID)
	end
	HLBOp_MultiItemOp.DestroyWithoutUpdateData()
	HLBOp_Amount.RefreshLandData()
    HLBOp_Group.RequestAllGroupIDs()
end

function UIHomelandBuildErrorItemListView:BatchBuy()
	local nCount, nCountChecked, bHaveForbidBuy, tbFurnitureInfo = self:GetSelectedItemFurnitureInfo()
	if nCountChecked <= 0 then
		return
	end

	if bHaveForbidBuy then
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_BUY_FURNITURE_SELL_END_ERROR)
		return
	end

	if DataModel.szChoose == "CanCoinBuy" then
		UIMgr.Open(VIEW_ID.PanelTongBaoPurchasePop, true, tbFurnitureInfo)
	else
		UIMgr.Open(VIEW_ID.PanelItemPurchasePop, tbFurnitureInfo)
	end
end

function UIHomelandBuildErrorItemListView:StartBuyCD()
	if self.nBuyCDTimerID then
		Timer.DelTimer(self, self.nBuyCDTimerID)
		self.nBuyCDTimerID = nil
	end

	self.bInBuyCD = true
	UIHelper.SetButtonState(self.BtnBatchBuy, BTN_STATE.Disable)

	local nEndTime = GetTickCount() + BuyCDTotalTime * 1000
	local nLeftTime = math.ceil((nEndTime - GetTickCount()) / 1000.0)
	UIHelper.SetString(self.LabelQuickOper, string.format("批量购买(%d)", nLeftTime))
	self.nBuyCDTimerID = Timer.AddCycle(self, 0.5, function ()
		nLeftTime = math.ceil((nEndTime - GetTickCount()) / 1000.0)
		UIHelper.SetString(self.LabelQuickOper, string.format("批量购买(%d)", nLeftTime))
		if nLeftTime <= 0 then
			self.bInBuyCD = false
			UIHelper.SetString(self.LabelQuickOper, "批量购买")
			Timer.DelTimer(self, self.nBuyCDTimerID)
			self.nBuyCDTimerID = nil

			self:UpdateBtnState()
		end
	end)
end

return UIHomelandBuildErrorItemListView