-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetOutfitItemCell
-- Date: 2024-03-08 14:42:12
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetOutfitItemCell = class("UIWidgetOutfitItemCell")
local WeaponEnum = {
	[12] = EQUIPMENT_INVENTORY.MELEE_WEAPON,
	[18] = EQUIPMENT_INVENTORY.BIG_SWORD
}

local EquipEnum = {
	    -- 头部
	[13] = EQUIPMENT_INVENTORY.HELM,
		-- 上衣
	[14] = EQUIPMENT_INVENTORY.CHEST,
		-- 腰带
	[15] = EQUIPMENT_INVENTORY.WAIST,
		-- 护腕
	[16] = EQUIPMENT_INVENTORY.BANGLE,
		-- 鞋子
	[17] = EQUIPMENT_INVENTORY.BOOTS,
}

local ItemStatusImg = {
	[1] = "UIAtlas2_Character_OutfitPreview_ImgLocked",
	[2] = "UIAtlas2_Character_OutfitPreview_ImgNotAble"
}
function UIWidgetOutfitItemCell:OnEnter(nTypeInfo, nPlayerID, togGroup, tbCurPreview)
	self.nTypeInfo = nTypeInfo
	self.nType = nTypeInfo.nIndex
	self.nPlayerID = nPlayerID
	self.togGroup = togGroup
	self.tbCurPreview = tbCurPreview
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
	self:UpdateInfo()
end

function UIWidgetOutfitItemCell:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIWidgetOutfitItemCell:BindUIEvent()
	
end

function UIWidgetOutfitItemCell:RegEvent()
	Event.Reg(self, "ON_UPDATE_OUTFITITEM", function ()
		self.tbCurPreview = OutFitPreviewData.tbCurPreview
        self:UpdateWidgetItem()
		Event.Dispatch("ON_UPDATE_SET_PREVIEW", self.nSetPreview)

    end)
	Event.Reg(self, "COIN_SHOP_BUY_RESPOND", function ()
		self:UpdateWidgetItem()
    end)
end

function UIWidgetOutfitItemCell:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetOutfitItemCell:UpdateInfo()
	local szImagePath = self.nTypeInfo.szImagePath
	local szName = self.nTypeInfo.szName
	UIHelper.SetSpriteFrame(self.ImgIcon, szImagePath)
	UIHelper.SetString(self.LabelSlotName, szName)
	self:UpdateWidgetItem()
	if table.GetCount(self.tbCurPreview) == 1 and self.tbScriptOutfitItem then
		UIHelper.SetSelected(self.tbScriptOutfitItem.ToggleSelect, true)
	end
end

function UIWidgetOutfitItemCell:UpdateWidgetItem()
	local nIndex = self.nTypeInfo.nIndex
	local tbItemInfo = self.tbCurPreview[nIndex]
	self.tbScriptOutfitItem = nil
	UIHelper.RemoveAllChildren(self.WidgetItem80)
	if tbItemInfo then
		self.bHave = false
		self.bCanBuy = false
		UIHelper.SetVisible(self.TogChoose, true)
		self.tbScriptOutfitItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem80)
		if tbItemInfo.nType == OutFitPreviewData.PreviewType.Pandent then 	--饰品
			self.tbScriptOutfitItem:OnInitWithTabID(tbItemInfo.nTabType, tbItemInfo.dwIndex)
			self.tbScriptOutfitItem:SetLabelCountVisible(false)
			UIHelper.SetToggleGroupIndex(self.tbScriptOutfitItem.ToggleSelect, ToggleGroupIndex.PreviewOutfit)
			UIHelper.SetSwallowTouches(self.tbScriptOutfitItem.ToggleSelect,false)
			UIHelper.BindUIEvent(self.TogChoose, EventType.OnSelectChanged, function(btn, bSelected)
				self:UpdatePandentPreview(bSelected, nIndex)
				Timer.AddFrame(self, 1, function()
					Event.Dispatch("ON_UPDATE_TOGPANDENTTITLE")
				end)
			end)
			UIHelper.SetSelected(self.TogChoose, true, false)
		elseif tbItemInfo.nType == OutFitPreviewData.PreviewType.ExteriorEquip then --外装装备
			self.tbScriptOutfitItem:OnInitWithTabID("EquipExterior", tbItemInfo.dwExteriorID)
			self.tbScriptOutfitItem:SetLabelCountVisible(false)
			UIHelper.SetToggleGroupIndex(self.tbScriptOutfitItem.ToggleSelect, ToggleGroupIndex.PreviewOutfit)
			UIHelper.SetSwallowTouches(self.tbScriptOutfitItem.ToggleSelect,false)
			UIHelper.BindUIEvent(self.TogChoose, EventType.OnSelectChanged, function(btn, bSelected)
				self:UpdateExteriorEquipPreview(bSelected, nIndex)
				Timer.AddFrame(self, 1, function()
					Event.Dispatch("ON_UPDATE_TOGOUTFITTITLE")
				end)
			end)
			UIHelper.SetSelected(self.TogChoose, true, false)
			local dwExteriorID = tbItemInfo.dwExteriorID
			self:UpdateExteriorBox(dwExteriorID)
			local bCollect = CoinShop_GetCollectInfo(COIN_SHOP_GOODS_TYPE.EXTERIOR, tbItemInfo.dwExteriorID)
			self.nSetPreview = dwExteriorID or 0
			local bIsSchool = self:IsSchoolExtrior(dwExteriorID)
			self:UpdateImgState(self.bCanBuy, bCollect, self.tbScriptOutfitItem, bIsSchool)
		elseif tbItemInfo.nType == OutFitPreviewData.PreviewType.ExteriorWeapon then --外装武器
			self.tbScriptOutfitItem:OnInitWithTabID("WeaponExterior", tbItemInfo.dwWeaponID)
			self.tbScriptOutfitItem:SetLabelCountVisible(false)
			UIHelper.SetToggleGroupIndex(self.tbScriptOutfitItem.ToggleSelect, ToggleGroupIndex.PreviewOutfit)
			UIHelper.SetSwallowTouches(self.tbScriptOutfitItem.ToggleSelect,false)
			UIHelper.BindUIEvent(self.TogChoose, EventType.OnSelectChanged, function(btn, bSelected)
				self:UpdateExteriorWeaponPreview(bSelected)
				Timer.AddFrame(self, 1, function()
					Event.Dispatch("ON_UPDATE_TOGOUTFITTITLE")
				end)
			end)
			UIHelper.SetSelected(self.TogChoose, true, false)
			local dwWeaponID = tbItemInfo.dwWeaponID
			self:UpdateWeaponBox(dwWeaponID)
			local bCollect = CoinShop_GetCollectInfo(self.eGoodsType, dwWeaponID)
			self:UpdateImgState(self.bCanBuy, bCollect, self.tbScriptOutfitItem)
		elseif tbItemInfo.nType == OutFitPreviewData.PreviewType.Equip then 	--装备
			local nPlayerID = self.nPlayerID or g_pClientPlayer.dwID
			self.tbScriptOutfitItem:SetPlayerID(nPlayerID)
			self.tbScriptOutfitItem:OnInitWithTabID(tbItemInfo.nTabType, tbItemInfo.dwIndex)
			self.tbScriptOutfitItem:SetLabelCountVisible(false)
			UIHelper.SetToggleGroupIndex(self.tbScriptOutfitItem.ToggleSelect, ToggleGroupIndex.PreviewOutfit)
			UIHelper.SetSwallowTouches(self.tbScriptOutfitItem.ToggleSelect,false)
			UIHelper.BindUIEvent(self.TogChoose, EventType.OnSelectChanged, function(btn, bSelected)
				self:UpdateEquipPreview(bSelected, nIndex)
				Timer.AddFrame(self, 1, function()
					Event.Dispatch("ON_UPDATE_TOGOUTFITTITLE")
				end)
			end)
			UIHelper.SetSelected(self.TogChoose, true, false)
			local dwExteriorID = CoinShop_GetExteriorID(tbItemInfo.nTabType, tbItemInfo.dwIndex)
			self:UpdateExteriorBox(dwExteriorID)
			local bCollect = CoinShop_GetCollectInfo(COIN_SHOP_GOODS_TYPE.EXTERIOR, dwExteriorID)
			self.nSetPreview = dwExteriorID or 0
			local bIsSchool = self:IsSchoolExtrior(dwExteriorID)
			self:UpdateImgState(self.bCanBuy, bCollect, self.tbScriptOutfitItem, bIsSchool)
		elseif tbItemInfo.nType == OutFitPreviewData.PreviewType.EquipWeapon then	--	装备武器
			local nPlayerID = self.nPlayerID or g_pClientPlayer.dwID
			self.tbScriptOutfitItem:SetPlayerID(nPlayerID)
			self.tbScriptOutfitItem:OnInitWithTabID(tbItemInfo.nTabType, tbItemInfo.dwIndex)
			self.tbScriptOutfitItem:SetLabelCountVisible(false)
			UIHelper.SetToggleGroupIndex(self.tbScriptOutfitItem.ToggleSelect, ToggleGroupIndex.PreviewOutfit)
			UIHelper.SetSwallowTouches(self.tbScriptOutfitItem.ToggleSelect,false)
			UIHelper.BindUIEvent(self.TogChoose, EventType.OnSelectChanged, function(btn, bSelected)
				self:UpdateEquipWeaponPreview(bSelected, nIndex)
				Timer.AddFrame(self, 1, function()
					Event.Dispatch("ON_UPDATE_TOGOUTFITTITLE")
				end)
			end)
			UIHelper.SetSelected(self.TogChoose, true, false)
			local itemInfo = ItemData.GetItemInfo(tbItemInfo.nTabType, tbItemInfo.dwIndex)
			local dwWeaponID = CoinShop_GetWeaponIDByItemInfo(itemInfo)
			self:UpdateWeaponBox(dwWeaponID)
			local bCollect = CoinShop_GetCollectInfo(COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR, dwWeaponID)
			self:UpdateImgState(self.bCanBuy, bCollect, self.tbScriptOutfitItem)
		elseif tbItemInfo.nHairID then
			if tbItemInfo.nTabType and tbItemInfo.dwIndex then
				self.tbScriptOutfitItem:OnInitWithTabID(tbItemInfo.nTabType, tbItemInfo.dwIndex)
			else
			 self.tbScriptOutfitItem:OnInitWithIconID(10775, 2, 1)
			end
			self.tbScriptOutfitItem:SetLabelCountVisible(false)
			UIHelper.SetToggleGroupIndex(self.tbScriptOutfitItem.ToggleSelect, ToggleGroupIndex.PreviewOutfit)
			UIHelper.SetSwallowTouches(self.tbScriptOutfitItem.ToggleSelect,false)
			UIHelper.BindUIEvent(self.TogChoose, EventType.OnSelectChanged, function(btn, bSelected)
				self:UpdateHairPreview(bSelected, nIndex)
			end)
			UIHelper.SetSelected(self.TogChoose, true, false)
			local nHairID = tbItemInfo.nHairID

			self:UpdateHairBox(nHairID)
			self:UpdateImgState(self.bCanBuy, true, self.tbScriptOutfitItem)
		end
		self.tbScriptOutfitItem:SetSelectChangeCallback(function (_, bSelected)
			if bSelected then
				Event.Dispatch("ON_UPDATE_SET_PREVIEW", self.nSetPreview)
			end
        end)
		--Event.Dispatch("ON_UPDATE_SET_PREVIEW", self.nSetPreview)
	else
		self.bCanBuy = false
		self.bHave = false
		UIHelper.SetVisible(self.ImgStatus, false)
		UIHelper.SetVisible(self.TogChoose, false)
		UIHelper.SetSelected(self.TogChoose, false, false)
	end
end

function UIWidgetOutfitItemCell:UpdatePandentPreview(bSelected, nIndex)
	local tbItemInfo = nil
	local nOldIndex = 0
	if nIndex == 8 then
		tbItemInfo = self.tbCurPreview[OutFitPreviewData.PandentItemType[4][0]] or {["nTabType"] = 0, ["dwIndex"] = 0}
	else
		tbItemInfo = self.tbCurPreview[OutFitPreviewData.PandentItemType[1][self.nTypeInfo.nType]] or {["nTabType"] = 0, ["dwIndex"] = 0}
	end
	if bSelected then--穿
		if nIndex == 8 then
			Event.Dispatch("ON_UPDATE_ITEMPREVIEW", tbItemInfo.nTabType, tbItemInfo.dwIndex)
		else
			local nRepresentSub = OutFitPreviewData.GetPendantSub(nIndex)
			Event.Dispatch("ON_UPDATE_ITEMPREVIEW", tbItemInfo.nTabType, tbItemInfo.dwIndex, nRepresentSub)
		end
	else	--脱		
		if nIndex == 8 then
			nOldIndex = g_pClientPlayer.GetEquippedPendentPet() or 0
			Event.Dispatch("ON_CANCEL_PANDENTPETPREVIEW", tbItemInfo.nTabType, tbItemInfo.dwIndex, tbItemInfo.nTabType, nOldIndex)
		else	--饰品
			nOldIndex = g_pClientPlayer.GetSelectPendent(self.nTypeInfo.nType) or 0
			local nRepresentSub = OutFitPreviewData.GetPendantSub(nIndex)
			Event.Dispatch("ON_CANCEL_PANDENTPREVIEW", tbItemInfo.nTabType, tbItemInfo.dwIndex, ITEM_TABLE_TYPE.CUST_TRINKET, nOldIndex, nRepresentSub)
		end
	end
end

function UIWidgetOutfitItemCell:UpdateHairPreview(bSelected, nIndex)--19
	local item = self.tbCurPreview[nIndex]
	local nNewHair = item and item.nHairID or 0
	local tRepresentID = g_pClientPlayer.GetRepresentID()
    local nHairID = tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE]
	if bSelected then
		Event.Dispatch("ON_UPDATE_HAIRPREVIEW", nNewHair)
	else
		Event.Dispatch("ON_UPDATE_HAIRPREVIEW", nHairID)
	end
end

function UIWidgetOutfitItemCell:UpdateExteriorEquipPreview(bSelected, nIndex)
	--local player = GetPlayer(self.nPlayerID)
	--local nCurrentSetID = player.GetCurrentSetID() or 0
	--local tExteriorSet = player.GetExteriorSet(nCurrentSetID) or {}
	--local dwNewExteriorID = tExteriorSet[self.nTypeInfo.nType] or 0
	local dwNewExteriorID = self.tbCurPreview[nIndex] and self.tbCurPreview[nIndex].dwExteriorID or 0
	if bSelected then
		Timer.AddFrame(self, 1, function()
			Event.Dispatch("ON_UPDATE_EXTERIORPREVIEW", dwNewExteriorID)
		end)
	else
		local nOldCurrentSetID = g_pClientPlayer.GetCurrentSetID() or 0
		local tOldExteriorSet = g_pClientPlayer.GetExteriorSet(nOldCurrentSetID) or {}
		local dwOldExteriorID = tOldExteriorSet[self.nTypeInfo.nType] or 0
		Event.Dispatch("ON_CANCEL_EXTERIORPREVIEW", dwNewExteriorID, dwOldExteriorID)
	end
end

function UIWidgetOutfitItemCell:UpdateExteriorWeaponPreview(bSelected)
	local player = GetPlayer(self.nPlayerID)
	local nPlayerCurrentSetID = g_pClientPlayer.GetCurrentSetID() or 0
	local tPlayerWeaponExterior = g_pClientPlayer.GetWeaponExteriorSet(nPlayerCurrentSetID) or {}
	local nPlayerOldIndex = tPlayerWeaponExterior[self.nTypeInfo.nType] or 0
	
	local nOtherPlayerCurrentSetID = player.GetCurrentSetID() or 0
	local tOtherPlayerWeaponExterior = player.GetWeaponExteriorSet(nOtherPlayerCurrentSetID) or {}
	local nOtherPlayerIndex = tOtherPlayerWeaponExterior[self.nTypeInfo.nType] or 0
	if bSelected then
		Event.Dispatch("ON_UPDATE_EXTERIORWEAPONPREVIEW", nOtherPlayerIndex)
	else
		if g_pClientPlayer.dwForceID ~= FORCE_TYPE.CANG_JIAN and self.nTypeInfo.nType == WEAPON_EXTERIOR_BOX_INDEX_TYPE.BIG_SWORD then
			Timer.AddFrame(self, 1, function ()
				UIHelper.SetSelected(self.TogChoose, true)
			end)
		else
			Event.Dispatch("ON_CANCEL_EXTERIORWEAPONPREVIEW", nOtherPlayerIndex, nPlayerOldIndex)
		end
	end
end

function UIWidgetOutfitItemCell:UpdateEquipPreview(bSelected, nIndex)
	local player = GetPlayer(self.nPlayerID)
	local tbOldItem = g_pClientPlayer.GetItem(INVENTORY_INDEX.EQUIP, EquipEnum[nIndex]) or {["dwTabType"] = 0, ["dwIndex"] = 0}
	--local item = player.GetItem(INVENTORY_INDEX.EQUIP, EquipEnum[nIndex])
	local item = self.tbCurPreview[nIndex] or {["nTabType"] = 0, ["dwIndex"] = 0}
	if bSelected then
		Event.Dispatch("ON_UPDATE_ITEMPREVIEW", item.nTabType, item.dwIndex)
	else
		Event.Dispatch("ON_CANCEL_EQUIP_PREVIEW", item.nTabType, item.dwIndex, tbOldItem.dwTabType, tbOldItem.dwIndex)
	end
end

function UIWidgetOutfitItemCell:UpdateEquipWeaponPreview(bSelected, nIndex)
	local player = GetPlayer(self.nPlayerID)
	--local item = player.GetItem(INVENTORY_INDEX.EQUIP, WeaponEnum[nIndex])
	local item = self.tbCurPreview[nIndex] or {["nTabType"] = 0, ["dwIndex"] = 0}
	local tbOldItem = g_pClientPlayer.GetItem(INVENTORY_INDEX.EQUIP, WeaponEnum[nIndex]) or {["dwTabType"] = 0, ["dwIndex"] = 0}
	if bSelected then
		Event.Dispatch("ON_UPDATE_ITEMPREVIEW", item.nTabType, item.dwIndex)
	else
		Event.Dispatch("ON_CANCEL_EQUIP_PREVIEW", item.nTabType, item.dwIndex, tbOldItem.dwTabType, tbOldItem.dwIndex)
	end
end

function UIWidgetOutfitItemCell:SetItemSelected(bSelected)
	local nIndex = self.nTypeInfo.nIndex
	local tbItemInfo = self.tbCurPreview[nIndex]
	if tbItemInfo then
		if tbItemInfo.nType == OutFitPreviewData.PreviewType.Pandent then 	--饰品
			self:UpdatePandentPreview(bSelected, nIndex)
			UIHelper.SetSelected(self.TogChoose, bSelected)
		elseif tbItemInfo.nType == OutFitPreviewData.PreviewType.ExteriorEquip then --外装装备
			UIHelper.SetSelected(self.TogChoose, bSelected)
			--self:UpdateExteriorEquipPreview(bSelected, nIndex)
		elseif tbItemInfo.nType == OutFitPreviewData.PreviewType.ExteriorWeapon then --外装武器
			self:UpdateExteriorWeaponPreview(bSelected)
			UIHelper.SetSelected(self.TogChoose, bSelected)
		elseif tbItemInfo.nType == OutFitPreviewData.PreviewType.Equip then 	--装备
			self:UpdateEquipPreview(bSelected, nIndex)
			UIHelper.SetSelected(self.TogChoose, bSelected)
		elseif tbItemInfo.nType == OutFitPreviewData.PreviewType.EquipWeapon then	--	装备武器
			self:UpdateEquipWeaponPreview(bSelected, nIndex)
			UIHelper.SetSelected(self.TogChoose, bSelected)
		end
	end
end

function UIWidgetOutfitItemCell:UpdateImgState(bCanBuy, bCollect, tbScript, bIsSchool)
	if bCanBuy and not bCollect then	--未收集
		UIHelper.SetVisible(self.ImgStatus, true)
		UIHelper.SetSpriteFrame(self.ImgStatus, ItemStatusImg[1])
		tbScript:SetClickCallback(function ()
			TipsHelper.ShowNormalTip("收集对应装备后方可购买")
        end)
	elseif not bCanBuy then	--无法购买
		UIHelper.SetVisible(self.ImgStatus, true)
		UIHelper.SetSpriteFrame(self.ImgStatus, ItemStatusImg[2])
		tbScript:SetClickCallback(function ()
			local szTips = bIsSchool and "当前外观无法直接购买获取" or "非本门派外观，无法购买"
			TipsHelper.ShowNormalTip(szTips)
        end)
	else
		UIHelper.SetVisible(self.ImgStatus, false)
	end
end

function UIWidgetOutfitItemCell:UpdateExteriorBox(dwExteriorID)
	local hPlayer = GetClientPlayer()
    if not hPlayer then
        return 
    end

	local hExterior = GetExterior()
    if not hExterior then
        return
    end
	self.dwGoodsID = dwExteriorID
	self.eGoodsType = COIN_SHOP_GOODS_TYPE.EXTERIOR
	if dwExteriorID and dwExteriorID > 0 then
		local nTimeType, nTime = g_pClientPlayer.GetExteriorTimeLimitInfo(dwExteriorID)
		local bTimeLimit = nTimeType and 
			(nTimeType == COIN_SHOP_TIME_LIMIT_TYPE.SEVEN_DAYS_LIMIT or 
				nTimeType == COIN_SHOP_TIME_LIMIT_TYPE.FREE_TRY_ON)
		if nTimeType == COIN_SHOP_TIME_LIMIT_TYPE.FREE_TRY_ON then
			nTime = GetCoinShopClient().GetFreeTryOnEndTime()
		end
		self.bHave = nTimeType ~= nil
		local bCanBuy = CoinShop_ExteriorCanBuy(dwExteriorID)
		self.bCanBuy = bCanBuy
	else
		self.bCanBuy = false
	end
end

function UIWidgetOutfitItemCell:UpdateWeaponBox(dwWeaponID)
	self.dwGoodsID = dwWeaponID
	self.eGoodsType = COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR
	if dwWeaponID and dwWeaponID > 0 then
		local nTimeType, nTime = g_pClientPlayer.GetWeaponExteriorTimeLimitInfo(dwWeaponID)
		local bTimeLimit = nTimeType and 
			(nTimeType == COIN_SHOP_TIME_LIMIT_TYPE.SEVEN_DAYS_LIMIT or 
				nTimeType == COIN_SHOP_TIME_LIMIT_TYPE.FREE_TRY_ON)
		if nTimeType == COIN_SHOP_TIME_LIMIT_TYPE.FREE_TRY_ON then
			nTime = GetCoinShopClient().GetFreeTryOnEndTime()
		end
		self.bHave = nTimeType ~= nil
		self.bCanBuy = CoinShop_WeaponCanBuy(dwWeaponID)
	else
		self.bCanBuy = false
	end
end

function UIWidgetOutfitItemCell:UpdateHairBox(nHairID)
	self.dwGoodsID = nHairID
	self.eGoodsType = COIN_SHOP_GOODS_TYPE.HAIR
	if nHairID > 0 then
		local nHaveHairType = GetCoinShopClient().CheckAlreadyHave(COIN_SHOP_GOODS_TYPE.HAIR, nHairID)
		self.bHave = nHaveHairType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
		self.bCanBuy = OutFitPreviewData.HairCanBuy(HAIR_STYLE.HAIR, nHairID)
	else
		self.bCanBuy = false
	end
end

function UIWidgetOutfitItemCell:UpdateSetPreview(dwExteriorID)
	local nIndex = self.nTypeInfo.nIndex
	local tbItemInfo = self.tbCurPreview[nIndex]
	if not g_pClientPlayer then
		return
	end
	if tbItemInfo then	--当前格子有外装
		--取消当前外装的预览
		if tbItemInfo.nType == OutFitPreviewData.PreviewType.ExteriorEquip then	--外装
			local nOldCurrentSetID = g_pClientPlayer.GetCurrentSetID() or 0
			local tOldExteriorSet = g_pClientPlayer.GetExteriorSet(nOldCurrentSetID) or {}
			local dwOldExteriorID = tOldExteriorSet[self.nTypeInfo.nType] or 0
			Event.Dispatch("ON_CANCEL_EXTERIORPREVIEW", tbItemInfo.dwExteriorID, dwOldExteriorID)
		elseif tbItemInfo.nType == OutFitPreviewData.PreviewType.Equip then	--装备
			local tbOldItem = g_pClientPlayer.GetItem(INVENTORY_INDEX.EQUIP, EquipEnum[nIndex]) or {["dwTabType"] = 0, ["dwIndex"] = 0}
			local item = self.tbCurPreview[nIndex] or {["nTabType"] = 0, ["dwIndex"] = 0}
			Event.Dispatch("ON_CANCEL_EQUIP_PREVIEW", item.nTabType, item.dwIndex, tbOldItem.dwTabType, tbOldItem.dwIndex)
		end
		OutFitPreviewData.tbCurPreview[nIndex] = nil
		UIHelper.RemoveAllChildren(self.WidgetItem80)
		self.tbScriptOutfitItem = nil
		UIHelper.SetVisible(self.TogChoose, false)
	end
	OutFitPreviewData.tbCurPreview[nIndex] = {["nType"] = OutFitPreviewData.PreviewType.ExteriorEquip, ["dwExteriorID"] = dwExteriorID, ["bSetItem"] = true}
end

function UIWidgetOutfitItemCell:IsSchoolExtrior(dwExteriorID)
	local hExterior = GetExterior()
    if not hExterior then
        return false
    end
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return false
    end
	local tInfo = hExterior.GetExteriorInfo(dwExteriorID)

	if tInfo.nForceID == 0 then
		return true
	end

	return tInfo.nForceID == hPlayer.dwForceID
end

return UIWidgetOutfitItemCell