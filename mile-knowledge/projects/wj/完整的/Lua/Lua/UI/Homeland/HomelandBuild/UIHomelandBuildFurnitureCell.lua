-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildFurnitureCell
-- Date: 2023-04-21 17:03:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildFurnitureCell = class("UIHomelandBuildFurnitureCell")

function UIHomelandBuildFurnitureCell:OnEnter(DataModel, tbInfo, bShowBtnSubgroup)
    self.DataModel = DataModel
    self.tbInfo = tbInfo
	self.bShowBtnSubgroup = bShowBtnSubgroup

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandBuildFurnitureCell:OnExit()
    self.bInit = false
end

function UIHomelandBuildFurnitureCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnConstructionItem, EventType.OnClick, function ()
		if self.tbInfo and self.tbInfo.dwModelID then
			self.DataModel.RemoveRedDot(self.tbInfo.dwModelID)
		end

		if self.DataModel.bInSearch then
			Event.Dispatch(EventType.OnGotoHomelandFurnitureListOneItem, self.tbInfo.dwModelID)
			return
		end

		local nMode = HLBOp_Main.GetBuildMode()
		if nMode == BUILD_MODE.COMMUNITY or nMode == BUILD_MODE.PRIVATE then
			if self.tbInfo.nBrushModeCnt > 0 then
				-- do nothing
			elseif self.tbInfo.tNumInfo and self.tbInfo.tNumInfo.nLeftAmount <= 0 then
				local tips, scriptTips = TipsHelper.ShowItemTips(self.BtnConstructionItem)
				scriptTips:OnInitFurniture(self.tbInfo.nFurnitureType, self.tbInfo.dwFurnitureID)
				self:UpdateTipsBtnState(scriptTips)
				return
			end
		end

		self:TryCreatAndPlaceItem()
    end)

    UIHelper.BindUIEvent(self.BtnConstructionItem, EventType.OnLongPress, function ()
		local tips, scriptTips = TipsHelper.ShowItemTips(self.BtnConstructionItem)
		scriptTips:OnInitFurniture(self.tbInfo.nFurnitureType, self.tbInfo.dwFurnitureID)
		self:UpdateTipsBtnState(scriptTips)
	end)

	UIHelper.BindUIEvent(self.BtnMore, EventType.OnClick, function ()
		self.DataModel.nCurSubgroup = self.tbInfo.nSubgroupID
        self.DataModel.bNeedScrollToLeft = true
		Event.Dispatch("LUA_HOMELAND_UPDATE_LANDDATA")
	end)
	UIHelper.SetSwallowTouches(self.BtnMore, true)
end

function UIHomelandBuildFurnitureCell:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
		UIHelper.SetVisible(self.ImgUp, false)
	end)

	Event.Reg(self, EventType.OnGotoHomelandFurnitureListOneItem, function(dwModelID)
		if self.tbInfo.dwModelID == dwModelID then
			return
		end
		UIHelper.SetVisible(self.ImgUp, false)
	end)
end

function UIHomelandBuildFurnitureCell:UpdateItemNum()
	local tInfo = self.tbInfo
	if self.DataModel.bInSearch or not tInfo then
		UIHelper.SetVisible(self.ImgBgItemNum, false)
		UIHelper.SetVisible(self.LabelItemNum, false)
		return
	end
	local szNum = "MAX"
	local szPublic = ""

	local nMode = HLBOp_Main.GetBuildMode()
	if tInfo.nFurnitureType == HS_FURNITURE_TYPE.APPLIQUE_BRUSH then
		szNum = g_tStrings.STR_HOMELAND_BUILDING_FLOOR_BRUSH
	elseif tInfo.nFurnitureType == HS_FURNITURE_TYPE.FOLIAGE_BRUSH then
		szNum = g_tStrings.STR_HOMELAND_BUILDING_FLOWER_BRUSH
	elseif tInfo.bShowNumberAsBrush then
		szNum = g_tStrings.STR_HOMELAND_BUILDING_FURNITURE_BRUSH
	elseif nMode ~= BUILD_MODE.TEST and tInfo.tNumInfo then
		local tNumInfo = tInfo.tNumInfo
		if nMode == BUILD_MODE.COMMUNITY or nMode == BUILD_MODE.PRIVATE then
			szNum = tostring(tNumInfo.nLeftAmount - tNumInfo.nWarehouseLeftAmount)
			if tNumInfo.nWarehouseLeftAmount > 0 then
				szPublic = ("+" .. tostring(tNumInfo.nWarehouseLeftAmount))
			end
		end
	end

	UIHelper.SetString(self.LabelItemNum, szNum..szPublic)

	UIHelper.SetVisible(self.ImgBgItemNum, true)
	UIHelper.SetVisible(self.LabelItemNum, true)
	UIHelper.LayoutDoLayout(self.ImgBgItemNum)

end

function UIHomelandBuildFurnitureCell:UpdateInfo()

	UIHelper.SetTextColor(self.LabelItemName, ItemQualityColorC4b[(self.tbInfo.nQuality or 1) + 1])
    UIHelper.SetString(self.LabelItemName, UIHelper.GBKToUTF8(self.tbInfo.szName), 8)
	UIHelper.SetVisible(self.ImgBgLock, self.tbInfo.bLocked)
	UIHelper.SetVisible(self.WidgetNew, self.tbInfo.bNew)
	self:UpdateItemRedDot()

	if self.tbInfo.nSubgroupID and self.tbInfo.nSubgroupID > 0 and self.DataModel.tCurSubgroupList[self.tbInfo.nSubgroupID] then
		local bShow = #self.DataModel.tCurSubgroupList[self.tbInfo.nSubgroupID] > 1 and self.bShowBtnSubgroup
		UIHelper.SetVisible(self.BtnMore, bShow)
	else
		UIHelper.SetVisible(self.BtnMore, false)
	end

	if self.DataModel.bIsBluepList then
		UIHelper.SetVisible(self.ImgBgItemNum, false)
		-- local szPath = string.gsub(self.tbInfo.szTipImgPath, "ui/Image/", "Resource/")
		-- szPath = string.gsub(szPath, ".tga", ".png")
		-- UIHelper.SetTexture(self.ImgItemIcon, szPath)
	else
		local dwFurnitureUiId = GetHomelandMgr().MakeFurnitureUIID(self.tbInfo.nFurnitureType, self.tbInfo.dwFurnitureID)
		local tUIInfo = FurnitureData.GetFurnInfoByTypeAndID(self.tbInfo.nFurnitureType, self.tbInfo.dwFurnitureID)
		local tAddInfo = FurnitureData.GetFurnAddInfo(dwFurnitureUiId)
		if tAddInfo then
			local szPath = string.gsub(tAddInfo.szPath, "ui/Image/", "Resource/")
			szPath = string.gsub(szPath, ".tga", ".png")
			UIHelper.SetTexture(self.ImgItemIcon, szPath)
		end

		local tJudge2Type =
		{
			{tUIInfo.nBrushModeCnt > 0 and (not FurnitureData.IsBrushForAutoBottomBrush(tUIInfo.dwModelID)) , "Brush"},
			{tUIInfo.nBrushModeCnt > 0 and FurnitureData.IsBrushForAutoBottomBrush(tUIInfo.dwModelID), "CellarBrush"},
			{tUIInfo.bInteract, "Interaction"},
			{FurnitureData.FurnCanDye(tUIInfo.dwModelID), "Dye"},
			{tUIInfo.tScaleRange, "Scalable"},
			{FurnitureData.IsReplaceable(tUIInfo.dwModelID), "Replaceable"}
		}

		UIHelper.HideAllChildren(self.LayoutItemFeature)
		local nTypeIconIndex = 1
		for _, tbTypeInfo in ipairs(tJudge2Type) do
			if tbTypeInfo[1] then
				UIHelper.SetVisible(self.tbImgFeature[nTypeIconIndex], true)
				UIHelper.SetSpriteFrame(self.tbImgFeature[nTypeIconIndex], FurnitureItemFeatureType[tbTypeInfo[2]])

				nTypeIconIndex = nTypeIconIndex + 1
			end
		end

		UIHelper.LayoutDoLayout(self.LayoutItemFeature)

		self:UpdateItemNum()
	end
end

function UIHomelandBuildFurnitureCell:GetOneModelAvailableCountInWarehouse(nFurnitureType, dwFurnitureID)
	local hlMgr = GetHomelandMgr()
	if HLBOp_Enter.IsCohabit() then
		local tInfo = FurnitureData.GetFurnInfoByTypeAndID(nFurnitureType, dwFurnitureID)
		local nUsedCount = hlMgr.BuildGetOnLandFurniture(nFurnitureType, dwFurnitureID)
		local nCountInWarehouse = hlMgr.GetSumWareHouse(nFurnitureType == HS_FURNITURE_TYPE.FURNITURE, dwFurnitureID)
		if not nCountInWarehouse then
			return 0
		end
		return nCountInWarehouse - nUsedCount
	else
		return 0
	end
end

local function IsReBuyFurnitureCantRecycle(nReBuyCost, tInfo)
	return nReBuyCost > 0 and (not GDAPI_Homeland_IfDismantleFurnitrue(tInfo))
end

function UIHomelandBuildFurnitureCell:UpdateTipsBtnState(scriptTips)
	local bBuyEnable = true
	local bRecycleEnable = true
	local bExtractFurnitureEnable = true
	local bExtractAllEnable = true

	local tbBuyBtnInfo = {}
	local szBuyBtnText = g_tStrings.STR_HOMELAND_FURNITURE_BUY

	local hlMgr = GetHomelandMgr()
	local dwFurnitureID = self.tbInfo.dwFurnitureID
	local nFurnitureType = self.tbInfo.nFurnitureType

	if nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
		tbBuyBtnInfo.nCoin = nil
		tbBuyBtnInfo.nArchitecture = nil
		local tConfig = hlMgr.GetFurnitureConfig(dwFurnitureID)
		local tCoinInfo = FurnitureBuy.GetFurnitureInfo(dwFurnitureID)
		local bSpecialBuy = FurnitureBuy.IsSpecialFurnitrueCanBuy(dwFurnitureID)
		local tInfo = FurnitureData.GetFurnInfoByTypeAndID(nFurnitureType, dwFurnitureID)

		if tCoinInfo and tCoinInfo.bSell then
			tbBuyBtnInfo.nCoin = tCoinInfo.nCoin
		elseif tConfig.nArchitecture > 0 then
			if not self.tbInfo.bLocked then
				tbBuyBtnInfo.nArchitecture = tConfig.nArchitecture
				if IsReBuyFurnitureCantRecycle(tConfig.nReBuyCost, tInfo) then
					bRecycleEnable = false
				end
			else
				bBuyEnable = false
				if not HomelandEventHandler.CanDismantleFurniture(dwFurnitureID, false, 1) then
					bRecycleEnable = false
				end
			end
		elseif bSpecialBuy then
			if not self.tbInfo.bLocked then
				tbBuyBtnInfo.nGold = tConfig.nReBuyCost
			else
				bBuyEnable = false
			end
			if IsReBuyFurnitureCantRecycle(tConfig.nReBuyCost, tInfo) then
				bRecycleEnable = false
			end
		else
			bBuyEnable = false
			bRecycleEnable = false
			if tConfig.nReBuyCost > 0 then
				tbBuyBtnInfo.szTip = g_tStrings.STR_HOMELAND_FURNITURE_CANT_BUY_REASON_NOT_BY_ARCHITECTURE
			else
				tbBuyBtnInfo.szTip = g_tStrings.STR_HOMELAND_FURNITURE_CANT_BUY_REASON_NOT_BUY
			end
		end
		if not HLBOp_Enter.IsCohabit() then
			bExtractFurnitureEnable = false
			bExtractAllEnable = false
		else
			local nMyContributedCountInWarehouse = hlMgr.GetWareHouseCount(UI_GetClientPlayerID(), true, dwFurnitureID)
			local nTotalCountInWarehouse = self:GetOneModelAvailableCountInWarehouse(nFurnitureType, dwFurnitureID)
			if (not HLBOp_Main.IsModified()) and math.min(nMyContributedCountInWarehouse, nTotalCountInWarehouse) > 0 then -- 重要： 可能以后放开限制（下同）
				-- Do nothing.
			else
				bExtractFurnitureEnable = false
			end
			if HLBOp_Main.IsModified() then
				bExtractAllEnable = false
			end
		end
	elseif nFurnitureType == HS_FURNITURE_TYPE.PENDANT then
		bRecycleEnable = false
		local szErrMsg
		local tInfo = FurnitureData.GetFurnInfoByTypeAndID(nFurnitureType, dwFurnitureID)
		local nCatg1, nCatg2 = tInfo.nCatg1Index, tInfo.nCatg2Index
		local tLine = FurnitureData.GetPendantInfo(nCatg1, nCatg2)
		local bCanDo, eErrType = Homeland_CanIsotypePendant(dwFurnitureID)
		szBuyBtnText = UIHelper.GBKToUTF8(tLine.szTitle)

		if bCanDo then
			tbBuyBtnInfo.nArchitecture = nil
		else
			bBuyEnable = false

			if eErrType == PENDANT_ERROR_TYPE.NOT_ACQUIRED then
				szErrMsg = UIHelper.GBKToUTF8(tLine.szButtonTip)
			elseif eErrType == PENDANT_ERROR_TYPE.ALREADY_ISOTYPED then
				szErrMsg = UIHelper.GBKToUTF8(tLine.szAlreadyTip)
			end

			tbBuyBtnInfo.szTip = szErrMsg
		end

		if HLBOp_Main.IsModified() then
			bExtractAllEnable = false
		end

		local nMyContributedCountInWarehouse = hlMgr.GetWareHouseCount(UI_GetClientPlayerID(), false, dwFurnitureID)
		local nTotalCountInWarehouse = self:GetOneModelAvailableCountInWarehouse(nFurnitureType, dwFurnitureID)
		if (not HLBOp_Main.IsModified()) and math.min(nMyContributedCountInWarehouse, nTotalCountInWarehouse) > 0 then
			-- Do nothing.
		else
			bExtractFurnitureEnable = false
		end
	elseif nFurnitureType == HS_FURNITURE_TYPE.APPLIQUE_BRUSH or nFurnitureType == HS_FURNITURE_TYPE.FOLIAGE_BRUSH then
		scriptTips:SetBtnState({})
		return
	end

	local tbBtnInfo =
	{
		{
			szName = szBuyBtnText,
			bDisabled = not bBuyEnable,
			szDisableTip = tbBuyBtnInfo.szTip,
			OnClick = function ()
				if tbBuyBtnInfo.nCoin then
					UIMgr.Open(VIEW_ID.PanelTongBaoPurchasePop, true, {{dwFurnitureID =  self.tbInfo.dwFurnitureID, nNum = 1}})
				elseif tbBuyBtnInfo.nArchitecture then
					UIMgr.Open(VIEW_ID.PanelItemPurchasePop, {{dwFurnitureID =  self.tbInfo.dwFurnitureID, nNum = 1}})
				elseif tbBuyBtnInfo.nGold then
					UIMgr.Open(VIEW_ID.PanelItemPurchasePop, {{dwFurnitureID =  self.tbInfo.dwFurnitureID, nNum = 1}})
				else
					UIMgr.Open(VIEW_ID.PanelInviteZhiJiaoPop, self.tbInfo.dwFurnitureID)
				end

				TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
			end,
		},
		{
			szName = "拆解",
			bDisabled = not bRecycleEnable,
			OnClick = function ()
				local nMaxRecycleNum = 0
				local tNumInfo = self.tbInfo.tNumInfo

				if tNumInfo then
					local nLeftAmount, nRealAmount = tNumInfo.nLeftAmount, tNumInfo.nRealAmount
					nMaxRecycleNum = math.min(nLeftAmount, nRealAmount)
				end

				if nMaxRecycleNum > 0 then
					UIMgr.Open(VIEW_ID.PanelDisassemblePop, self.tbInfo.dwFurnitureID, nMaxRecycleNum)
				else
					TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_FURNITURE_CANT_RECYCLE_REASON_NONE_LEFT)
				end
				TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
			end,
		},
		{
			szName = "提取",
			bDisabled = not bExtractFurnitureEnable,
			OnClick = function ()
				UIMgr.Open(VIEW_ID.PanelExtractSinglePop, HLBOp_Enter.GetLandIndex(), nFurnitureType, dwFurnitureID)
				TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
			end,
		},
		{
			szName = "提取全部",
			bDisabled = not bExtractAllEnable,
			OnClick = function ()
				UIMgr.Open(VIEW_ID.PanelExtractMultiPop)
				TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
			end,
		},
	}
	if self.tbInfo.tNumInfo and self.tbInfo.tNumInfo.nLeftAmount <= 0 then
		local tbTryBtn = {
			szName = "试摆放",
			bNormalBtn = true,
			OnClick = function ()
				self:TryCreatAndPlaceItem()
				TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
			end,
		}
		table.insert(tbBtnInfo, tbTryBtn)
	end
	local nMode = HLBOp_Main.GetBuildMode()
	local tUIInfo = FurnitureData.GetFurnInfoByTypeAndID(nFurnitureType, dwFurnitureID)
	if nMode == BUILD_MODE.DESIGN or nMode == BUILD_MODE.TEST then
		tbBtnInfo = {}
	elseif (self.tbInfo.nSubgroupID and self.tbInfo.nSubgroupID ~= Homeland_GetNullSubgroupID()) and tUIInfo.nBrushModeCnt > 0 then
		tbBtnInfo = {}	-- 空模家具和笔刷家具不显示任何按钮tips
	end
	scriptTips:SetBtnState(tbBtnInfo)
end

function UIHomelandBuildFurnitureCell:UpdateItemRedDot()
	local nCatg1Index, nCatg2Index = self.tbInfo.nCatg1Index, self.tbInfo.nCatg2Index
	local tRedInfo = nil
	if self.DataModel.tRedDotInfo[nCatg1Index] then
		tRedInfo = self.DataModel.tRedDotInfo[nCatg1Index][nCatg2Index]
	end
	local dwModelID = self.tbInfo.dwModelID
	local bShowRedDot = tRedInfo and table.contain_value(tRedInfo, dwModelID)
	UIHelper.SetVisible(self.ImgRedPoint, bShowRedDot)

	local bShowRedDotMore = false
	if self.tbInfo.nSubgroupID and self.tbInfo.nSubgroupID > 0 and self.DataModel.tCurSubgroupList[self.tbInfo.nSubgroupID] then
		for _, tbInfo in ipairs(self.DataModel.tCurSubgroupList[self.tbInfo.nSubgroupID]) do
			local bShow = #self.DataModel.tCurSubgroupList[self.tbInfo.nSubgroupID] > 1 and self.bShowBtnSubgroup
			bShow = bShow and tRedInfo and table.contain_value(tRedInfo, tbInfo.dwModelID)
			if bShow then
				bShowRedDotMore = true
				break
			end
		end
	end
	UIHelper.SetVisible(self.ImgRedPointMore, bShowRedDotMore)
end

function UIHomelandBuildFurnitureCell:FindModelID(dwModelID)
	return self.tbInfo and self.tbInfo.dwModelID == dwModelID
end

function UIHomelandBuildFurnitureCell:TryCreatAndPlaceItem()
	local tSelectObjs = HLBOp_Select.GetSelectInfo()
	if #tSelectObjs == 1 then
		HLBOp_Rotate.BackObjAngle(tSelectObjs[1])
	end
	HLBOp_Brush.CancelBrush()
	HLBOp_Place.CancelPlace()
	HLBOp_MultiItemOp.CancelPlace()
	HLBOp_Bottom.CancelBottom()

	if self.DataModel.nCurCatg1Index == Homeland_GetCustomBrushCatg1Index() then
		if self.DataModel.nCurCatg2Index == Homeland_GetFlowerBrushCatg2Index() and (not self.tbInfo.bLocked) then
			HomelandCustomBrushData.SelectOneFlowerBrush(self.tbInfo.dwFurnitureID)
		elseif self.DataModel.nCurCatg2Index == Homeland_GetFloorBrushCatg2Index() and (not self.tbInfo.bLocked) then
			HomelandCustomBrushData.SelectOneFloorBrush(self.tbInfo.dwFurnitureID)
		elseif self.tbInfo.bLocked then
			if HLBOp_Enter.IsTenant() then
				OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_HOMELAND_BUILDING_BRUSH_TENANT_LOCKED)
			else
				OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_HOMELAND_BUILDING_BRUSH_LOCKED)
			end
		end
	elseif FurnitureData.IsAutoBottomBrush(self.tbInfo.dwModelID) then
		if not HLBOp_Check.CheckClickItem() then
			return
		end
		local dwModelID = self.tbInfo.dwModelID
		Timer.Add(self, 0.1, function () HLBOp_Bottom.CreateBottom(dwModelID) end)
		self.DataModel.tLastTaken.dwModelID = self.tbInfo.dwModelID
		HomelandBuildData.SetCurSelectedInfo(self.tbInfo)
	elseif self.tbInfo.nBrushModeCnt > 0 then
		if not HLBOp_Check.CheckClickItem() then
			return
		end
		-- local bEnable = IsShiftKeyDown() or FurnitureData.IsDefaultSmartBrush(self.tbInfo.dwModelID)
		local bEnable = FurnitureData.IsDefaultSmartBrush(self.tbInfo.dwModelID)
		HLBOp_Other.EnableSmartBrush(bEnable)
		local dwModelID = self.tbInfo.dwModelID
		Timer.Add(self, 0.1, function () HLBOp_Brush.CreateBrush(dwModelID) end)
		self.DataModel.tLastTaken.dwModelID = self.tbInfo.dwModelID
		HomelandBuildData.SetCurSelectedInfo(self.tbInfo)
	else
		if not HLBOp_Check.CheckClickItem() then
			return
		end
		local dwModelID = self.tbInfo.dwModelID
		Timer.Add(self, 0.1, function () HLBOp_Place.CreateItem(dwModelID) end)
		self.DataModel.tLastTaken.dwModelID = self.tbInfo.dwModelID
		HomelandBuildData.SetCurSelectedInfo(self.tbInfo)
	end
	-- HLBView_Main.ChangeFocusToHLB()
end

return UIHomelandBuildFurnitureCell