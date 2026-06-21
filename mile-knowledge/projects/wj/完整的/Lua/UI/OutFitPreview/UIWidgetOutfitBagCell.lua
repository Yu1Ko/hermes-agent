-- ---------------------------------------------------------------------------------
-- Author: liuyumin
-- Name: UIWidgetOutfitBagCell
-- Date: 2024-04-03 15:42:19
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetOutfitBagCell = class("UIWidgetOutfitBagCell")
local tbPosition = {
	[1] = "左肩",
	[2] = "右肩",
	[3] = "面部",
	[4] = "左手",
	[5] = "右手",
	[6] = "眼部",
	[7] = "披风",
	[8] = "挂宠",
	[9] = "佩囊",
	[10] = "背部",
	[11] = "腰部",
	[12] = "武器",
	[13] = "帽子",
	[14] = "上衣",
	[15] = "腰带",
	[16] = "护腕",
	[17] = "鞋子",
	[18] = "重剑",
	[19] = "发型",
	[20] = "头饰"
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

local EquipType = {
    [13] = EXTERIOR_INDEX_TYPE.HELM,
    [14] = EXTERIOR_INDEX_TYPE.CHEST,
    [15] = EXTERIOR_INDEX_TYPE.WAIST,
    [16] = EXTERIOR_INDEX_TYPE.BANGLE,
    [17] = EXTERIOR_INDEX_TYPE.BOOTS,
	[12] = WEAPON_EXTERIOR_BOX_INDEX_TYPE.MELEE_WEAPON,
	[18] = WEAPON_EXTERIOR_BOX_INDEX_TYPE.BIG_SWORD,
	[19] = EQUIPMENT_REPRESENT.HAIR_STYLE
}

local WeaponEnum = {
    -- 普通近战武器
    [12] = EQUIPMENT_INVENTORY.MELEE_WEAPON,
    -- 重剑
    [18] = EQUIPMENT_INVENTORY.BIG_SWORD
}

local PendantType = {
    [1] = KPENDENT_TYPE.LSHOULDER,
    [2] = KPENDENT_TYPE.RSHOULDER,
    [3] = KPENDENT_TYPE.FACE,
    [4] = KPENDENT_TYPE.LGLOVE,
    [5] = KPENDENT_TYPE.RGLOVE,
    [6] = KPENDENT_TYPE.GLASSES,
    [7] = KPENDENT_TYPE.BACKCLOAK,
    [8] = 0,
    [9] = KPENDENT_TYPE.BAG,
    [10] = KPENDENT_TYPE.BACK,
    [11] = KPENDENT_TYPE.WAIST,
	[20] = KPENDENT_TYPE.HEAD
}

function UIWidgetOutfitBagCell:OnEnter(item)
	self.item = item
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
	self:UpdateInfo()
end

function UIWidgetOutfitBagCell:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIWidgetOutfitBagCell:BindUIEvent()
	
end

function UIWidgetOutfitBagCell:RegEvent()
	Event.Reg(self, "ON_UPDATE_OUTFIT_BAG_CELL", function ()
		self:UpdateInfo()
    end)
end

function UIWidgetOutfitBagCell:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetOutfitBagCell:UpdateInfo()
	local player = PlayerData.GetClientPlayer()
    if not player then return end
	local item = self.item
	UIHelper.SetString(self.LabelItemPosition, tbPosition[item.nPosition])
	--UIHelper.RemoveAllChildren(self.WidgetItem80)
	--self.tbScript = nil
	if not self.tbScript then
		self.tbScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem80)
	end
	if item.nType == OutFitPreviewData.PreviewType.ExteriorEquip then	--普通外观
		self:UpdateExteriorItemInfo(item)
	elseif item.nType == OutFitPreviewData.PreviewType.Pandent then	--挂件
		self:UpdatePandentItemInfo(item)
	elseif item.nType == OutFitPreviewData.PreviewType.EquipWeapon then	--装备武器
		self:UpdateEquipWeaponItemInfo(item)
	elseif item.nType == OutFitPreviewData.PreviewType.Equip then	--装备
		self:UpdpateEquipItemInfo(item)
	elseif item.nType == OutFitPreviewData.PreviewType.ExteriorHair then	--发型
		self:UpdateHairItemInfo(item)
	end
	self.tbScript:SetLabelCountVisible(false)
	UIHelper.SetToggleGroupIndex(self.tbScript.ToggleSelect, ToggleGroupIndex.PreviewBagItem)
	UIHelper.SetSwallowTouches(self.tbScript.ToggleSelect, false)
end

function UIWidgetOutfitBagCell:UpdpateEquipItemInfo(item)
	local nTabType = item.nTabType
	local dwIndex = item.dwIndex
	local nPosition = item.nPosition
	self.tbScript:OnInitWithTabID(nTabType, dwIndex)
	local nType = OutFitPreviewData.PandentItemType[3][EquipEnum[nPosition]]
	self:UpdateItemEquipIcon(nType, nPosition, item)
	self.tbScript:SetClickCallback(function(nBox, nIndex)
		if nBox and nIndex then
			local tbOldItem = g_pClientPlayer.GetItem(INVENTORY_INDEX.EQUIP, EquipEnum[nPosition]) or {["dwTabType"] = 0, ["dwIndex"] = 0}
			local tbRightItem = OutFitPreviewData.tbCurPreview[nType]
			local tbLeftItem = OutFitPreviewData.tbCurBagPreviewItem[nPosition]	--左边对应格子
			if tbRightItem then	--右边对应格子已有
				Timer.AddFrame(self, 1, function ()
					Event.Dispatch("ON_CANCEL_EQUIP_PREVIEW", nTabType, dwIndex, tbOldItem.dwTabType, tbOldItem.dwIndex)
				end)
				if tbRightItem.nType == OutFitPreviewData.PreviewType.Equip then	--装备
					local tbCurItem = tbRightItem
					if nTabType == tbCurItem.nTabType and nIndex == tbCurItem.dwIndex and UIHelper.GetVisible(self.ImgEquipped) then	--自己
						self:ChooseSelfItem(nType, nPosition)
						local dwExteriorID = CoinShop_GetExteriorID(nTabType, dwIndex)
						Event.Dispatch("ON_UPDATE_OUTFITITEM")
					else	----
						if tbLeftItem then
							UIHelper.SetVisible(tbLeftItem.script.ImgEquipped, false)
						end
						OutFitPreviewData.tbCurPreview[nType] = {["nType"] = OutFitPreviewData.PreviewType.Equip, ["nTabType"] = nTabType, ["dwIndex"] = dwIndex}
						self:ChooseOtherItem(nPosition, item)
					end
				elseif OutFitPreviewData.tbCurPreview[nType].nType == OutFitPreviewData.PreviewType.ExteriorEquip then --与外装互斥
					OutFitPreviewData.tbCurPreview[nType] = {["nType"] = OutFitPreviewData.PreviewType.Equip, ["nTabType"] = nTabType, ["dwIndex"] = dwIndex}
					if tbLeftItem then
						UIHelper.SetVisible(tbLeftItem.script.ImgEquipped, false)
					end
					self:ChooseOtherItem(nPosition, item)
				end
			else	--没有，直接穿
				OutFitPreviewData.tbCurPreview[nType] = {["nType"] = OutFitPreviewData.PreviewType.Equip, ["nTabType"] = nTabType, ["dwIndex"] = dwIndex}
				self:ChooseOtherItem(nPosition, item)
			end
		end
	end)
end

function UIWidgetOutfitBagCell:UpdateEquipWeaponItemInfo(item)
	local nTabType = item.nTabType
	local dwIndex = item.dwIndex
	local nPosition = item.nPosition
	self.tbScript:OnInitWithTabID(nTabType, dwIndex)
	local nType = OutFitPreviewData.PandentItemType[3][WeaponEnum[nPosition]]
	self:UpdateItemEquipIcon(nType, nPosition, item)
	self.tbScript:SetClickCallback(function(nBox, nIndex)
		local tbOldItem = g_pClientPlayer.GetItem(INVENTORY_INDEX.EQUIP, WeaponEnum[nPosition]) or {["dwTabType"] = 0, ["dwIndex"] = 0}
		local tbRightItem = OutFitPreviewData.tbCurPreview[nType]
		local tbLeftItem = OutFitPreviewData.tbCurBagPreviewItem[nPosition]	--左边对应格子
		if nBox and nIndex then
			if tbRightItem then	--右边已装备
				Timer.AddFrame(self, 1, function ()
					Event.Dispatch("ON_CANCEL_EQUIP_PREVIEW", nTabType, dwIndex, tbOldItem.dwTabType, tbOldItem.dwIndex)
				end)
				if tbRightItem.nType == OutFitPreviewData.PreviewType.EquipWeapon then	--装备武器
					local tbCurItem = tbRightItem
					if nTabType == tbCurItem.nTabType and nIndex == tbCurItem.dwIndex and UIHelper.GetVisible(self.ImgEquipped) then	--自己
						self:ChooseSelfItem(nType, nPosition)
						local hItemInfo = GetItemInfo(nTabType, dwIndex)
						local dwWeaponID = CoinShop_GetWeaponIDByItemInfo(hItemInfo)
						Event.Dispatch("ON_UPDATE_OUTFITITEM")
					else	--其他装备武器
						if tbLeftItem then
							UIHelper.SetVisible(tbLeftItem.script.ImgEquipped, false)
						end
						OutFitPreviewData.tbCurPreview[nType] = {["nType"] = OutFitPreviewData.PreviewType.EquipWeapon, ["nTabType"] = nTabType, ["dwIndex"] = dwIndex}
						self:ChooseOtherItem(nPosition, item)
					end
				elseif tbRightItem.nType == OutFitPreviewData.PreviewType.ExteriorWeapon then	--外装武器
					OutFitPreviewData.tbCurPreview[nType] = {["nType"] = OutFitPreviewData.PreviewType.EquipWeapon, ["nTabType"] = nTabType, ["dwIndex"] = dwIndex}
					if tbLeftItem then
						UIHelper.SetVisible(tbLeftItem.script.ImgEquipped, false)
					end
					self:ChooseOtherItem(nPosition, item)
				end	
			else
				OutFitPreviewData.tbCurPreview[nType] = {["nType"] = OutFitPreviewData.PreviewType.EquipWeapon, ["nTabType"] = nTabType, ["dwIndex"] = dwIndex}
				self:ChooseOtherItem(nPosition, item)
			end
		end
	end)
end

function UIWidgetOutfitBagCell:UpdateExteriorItemInfo(item)
	local nPosition = item.nPosition
	local dwExteriorID = item.dwExteriorID
	self.tbScript:OnInitWithTabID("EquipExterior", dwExteriorID)
	local nExteriorSub = EquipType[nPosition]
	local nType = OutFitPreviewData.PandentItemType[2][nExteriorSub]
	local tbRightItemInfo = OutFitPreviewData.tbCurPreview[nType]
	local tbCurBagItem = OutFitPreviewData.tbCurBagPreviewItem[nPosition]
	if tbRightItemInfo and tbRightItemInfo.dwExteriorID == dwExteriorID and not tbCurBagItem then
		OutFitPreviewData.tbCurBagPreviewItem[nPosition] = {["script"] = self, ["tbItem"] = item}
		UIHelper.SetVisible(self.ImgEquipped, true)
	else
		UIHelper.SetVisible(self.ImgEquipped, false)
	end
	self.tbScript:SetClickCallback(function(nBox, nIndex)
		if nBox and nIndex then
			local tbRightItem = OutFitPreviewData.tbCurPreview[nType]
			local tbLeftItem = OutFitPreviewData.tbCurBagPreviewItem[nPosition]	--左边对应格子
			if tbRightItem then	--右边对应格子已有
				local dwNewExteriorID = item.dwExteriorID or 0
				local nOldCurrentSetID = g_pClientPlayer.GetCurrentSetID() or 0
				local tOldExteriorSet = g_pClientPlayer.GetExteriorSet(nOldCurrentSetID) or {}
				local dwOldExteriorID = tOldExteriorSet[nExteriorSub] or 0
				Event.Dispatch("ON_CANCEL_EXTERIORPREVIEW", dwNewExteriorID, dwOldExteriorID)
				if tbRightItem.nType == OutFitPreviewData.PreviewType.ExteriorEquip then	--外装
					local tbCurItem = tbRightItem
					if dwExteriorID == tbCurItem.dwExteriorID and UIHelper.GetVisible(self.ImgEquipped) then	--自己
						self:ChooseSelfItem(nType, nPosition)
						Event.Dispatch("ON_UPDATE_OUTFITITEM")
					else	----其他
						if tbLeftItem then
							UIHelper.SetVisible(tbLeftItem.script.ImgEquipped, false)
						end
						OutFitPreviewData.tbCurPreview[nType] = {["nType"] = OutFitPreviewData.PreviewType.ExteriorEquip, ["dwExteriorID"] = dwExteriorID}
						self:ChooseOtherItem(nPosition, item)
					end
				elseif OutFitPreviewData.tbCurPreview[nType].nType == OutFitPreviewData.PreviewType.Equip then --与装备互斥
					if tbLeftItem then
						UIHelper.SetVisible(tbLeftItem.script.ImgEquipped, false)
					end
					OutFitPreviewData.tbCurPreview[nType] = {["nType"] = OutFitPreviewData.PreviewType.ExteriorEquip, ["dwExteriorID"] = dwExteriorID}
					self:ChooseOtherItem(nPosition, item)
				end
			else	--没有，直接穿
				OutFitPreviewData.tbCurPreview[nType] = {["nType"] = OutFitPreviewData.PreviewType.ExteriorEquip, ["dwExteriorID"] = dwExteriorID}
				self:ChooseOtherItem(nPosition, item)
			end
		end
	end)
end

function UIWidgetOutfitBagCell:UpdatePandentItemInfo(item)
	local nTabType = item.nTabType
	local dwIndex = item.dwIndex
	local nPosition = item.nPosition
	self.tbScript:OnInitWithTabID(nTabType, dwIndex)
	local nType = nil
	if nPosition == 8 then	--特判宠物
		nType = OutFitPreviewData.PandentItemType[4][0]
	else
		nType = OutFitPreviewData.PandentItemType[1][PendantType[nPosition]]
	end
	self:UpdateItemEquipIcon(nType, nPosition, item)
	self.tbScript:SetClickCallback(function(nBox, nIndex)
		local tbRightItem = OutFitPreviewData.tbCurPreview[nType]
		local tbCurItem = tbRightItem
		local tbLeftItem = OutFitPreviewData.tbCurBagPreviewItem[nPosition]	--左边对应格子
		if nBox and nIndex then
			if tbRightItem then	--已装备
				local nOldIndex = 0
				if nPosition == 8 then
					nOldIndex = g_pClientPlayer.GetEquippedPendentPet() or 0
					Event.Dispatch("ON_CANCEL_PANDENTPETPREVIEW", nTabType, dwIndex, nTabType, nOldIndex)
				else
					nOldIndex = g_pClientPlayer.GetSelectPendent(PendantType[nPosition]) or 0
					Event.Dispatch("ON_CANCEL_PANDENTPREVIEW", nTabType, dwIndex, ITEM_TABLE_TYPE.CUST_TRINKET, nOldIndex)
				end
				if nTabType == tbCurItem.nTabType and nIndex == tbCurItem.dwIndex and UIHelper.GetVisible(self.ImgEquipped) then	--自己
					self:ChooseSelfItem(nType, nPosition)
					Event.Dispatch("ON_UPDATE_OUTFITITEM")
				else	--其他
					if tbLeftItem then
						UIHelper.SetVisible(tbLeftItem.script.ImgEquipped, false)
					end
					OutFitPreviewData.tbCurPreview[nType] = {["nType"] = OutFitPreviewData.PreviewType.Pandent, ["nTabType"] = item.nTabType, ["dwIndex"] = item.dwIndex}
					self:ChooseOtherItem(nPosition, item)
				end
			else	--未装备
				OutFitPreviewData.tbCurPreview[nType] = {["nType"] = OutFitPreviewData.PreviewType.Pandent, ["nTabType"] = item.nTabType, ["dwIndex"] = item.dwIndex}
				self:ChooseOtherItem(nPosition, item)
			end
		end
	end)


end

function UIWidgetOutfitBagCell:UpdateHairItemInfo(item)
	local nTabType = item.nTabType
	local dwIndex = item.dwIndex
	local nPosition = item.nPosition
	local nHairID = item.nHairID
	self.tbScript:OnInitWithTabID(nTabType, dwIndex)
	local nType = OutFitPreviewData.PandentItemType[6][EquipType[nPosition]]
	self:UpdateItemEquipIcon(nType, nPosition, item)
	self.tbScript:SetClickCallback(function(nBox, nIndex)
		local tbRightItem = OutFitPreviewData.tbCurPreview[nType]
		local tbCurItem = tbRightItem
		local tbLeftItem = OutFitPreviewData.tbCurBagPreviewItem[nPosition]	--左边对应格子
		if nBox and nIndex then
			if tbRightItem then	--已装备
				if nTabType == tbCurItem.nTabType and nIndex == tbCurItem.dwIndex and UIHelper.GetVisible(self.ImgEquipped) then	--自己
					self:ChooseSelfItem(nType, nPosition)
					local tRepresentID = g_pClientPlayer.GetRepresentID()
					local nHairID = tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE]
					Event.Dispatch("ON_UPDATE_HAIRPREVIEW", nHairID)
					Event.Dispatch("ON_UPDATE_OUTFITITEM")
				else	--其他
					if tbLeftItem then
						UIHelper.SetVisible(tbLeftItem.script.ImgEquipped, false)
					end
					OutFitPreviewData.tbCurPreview[nType] = {["nType"] = OutFitPreviewData.PreviewType.ExteriorHair, ["nTabType"] = item.nTabType, ["dwIndex"] = item.dwIndex, ["nHairID"] = item.nHairID}
					self:ChooseOtherItem(nPosition, item)
				end
			else
				OutFitPreviewData.tbCurPreview[nType] = {["nType"] = OutFitPreviewData.PreviewType.ExteriorHair, ["nTabType"] = item.nTabType, ["dwIndex"] = item.dwIndex, ["nHairID"] = item.nHairID}
				self:ChooseOtherItem(nPosition, item)
			end
		end
	end)
end

function UIWidgetOutfitBagCell:UpdateItemEquipIcon(nType, nPosition, item)
	local tbRightItemInfo = OutFitPreviewData.tbCurPreview[nType]
	local tbCurBagItem = OutFitPreviewData.tbCurBagPreviewItem[nPosition]
	if tbRightItemInfo and tbRightItemInfo.nTabType == item.nTabType and tbRightItemInfo.dwIndex == item.dwIndex and not tbCurBagItem then
		OutFitPreviewData.tbCurBagPreviewItem[nPosition] = {["script"] = self, ["tbItem"] = item}
		UIHelper.SetVisible(self.ImgEquipped, true)
	else
		UIHelper.SetVisible(self.ImgEquipped, false)
	end
end

function UIWidgetOutfitBagCell:ChooseSelfItem(nType, nPosition)
	OutFitPreviewData.tbCurPreview[nType] = nil
	OutFitPreviewData.tbCurBagPreviewItem[nPosition] = nil
	UIHelper.SetVisible(self.ImgEquipped, false)
end

function UIWidgetOutfitBagCell:ChooseOtherItem(nPosition, item)
	OutFitPreviewData.tbCurBagPreviewItem[nPosition] = {["script"] = self, ["tbItem"] = item}
	UIHelper.SetVisible(self.ImgEquipped, true)
	Event.Dispatch("ON_UPDATE_OUTFITITEM")
	Timer.AddFrame(self, 5, function ()
		Event.Dispatch("UPDATE_PREVIEW_OUTFIT")
	end)
end

return UIWidgetOutfitBagCell