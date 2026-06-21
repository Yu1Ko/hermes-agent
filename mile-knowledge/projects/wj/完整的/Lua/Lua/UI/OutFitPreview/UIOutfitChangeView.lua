-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOutfitChangeView
-- Date: 2024-02-29 19:24:39
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOutfitChangeView = class("UIOutfitChangeView")

local PendantType = {
    [1] = PENDENT_SELECTED_POS.LSHOULDER,
    [2] = PENDENT_SELECTED_POS.RSHOULDER,
    [3] = PENDENT_SELECTED_POS.FACE,
    [4] = PENDENT_SELECTED_POS.LGLOVE,
    [5] = PENDENT_SELECTED_POS.RGLOVE,
    [6] = PENDENT_SELECTED_POS.GLASSES,
    [7] = PENDENT_SELECTED_POS.BACKCLOAK,
    [8] = 0,
    [9] = PENDENT_SELECTED_POS.BAG,
    [10] = PENDENT_SELECTED_POS.BACK,
    [11] = PENDENT_SELECTED_POS.WAIST,
	[12] = PENDENT_SELECTED_POS.HEAD,
	[13] = PENDENT_SELECTED_POS.HEAD2,
	[14] = PENDENT_SELECTED_POS.HEAD3,
}

local EquipType = {
    EXTERIOR_INDEX_TYPE.HELM,
    EXTERIOR_INDEX_TYPE.CHEST,
    EXTERIOR_INDEX_TYPE.WAIST,
    EXTERIOR_INDEX_TYPE.BANGLE,
    EXTERIOR_INDEX_TYPE.BOOTS,
	WEAPON_EXTERIOR_BOX_INDEX_TYPE.MELEE_WEAPON,
	WEAPON_EXTERIOR_BOX_INDEX_TYPE.BIG_SWORD,
}

local EquipEnum = {
    -- 头部
    EQUIPMENT_INVENTORY.HELM,
    -- 上衣
    EQUIPMENT_INVENTORY.CHEST,
    -- 腰带
    EQUIPMENT_INVENTORY.WAIST,
	-- 护腕
	EQUIPMENT_INVENTORY.BANGLE,
    -- 鞋子
    EQUIPMENT_INVENTORY.BOOTS,
}

local WeaponEnum = {
    -- 普通近战武器
    EQUIPMENT_INVENTORY.MELEE_WEAPON,
    -- 重剑
    EQUIPMENT_INVENTORY.BIG_SWORD
}


function UIOutfitChangeView:OnEnter(nPlayerID)
	self.nPlayerID = nPlayerID
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
	self:UpdateInfo()
end

function UIOutfitChangeView:OnExit()
	self.bInit = false
	self:UnRegEvent()
	OutFitPreviewData.tbCurBagPreviewItem = {}
	Event.Dispatch("ON_UPDATE_PREVIEW_MODEL_LOOKPOS", "left")
end

function UIOutfitChangeView:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function()
		UIMgr.Close(self)
	end)

	UIHelper.BindUIEvent(self.BtnGetoffAll, EventType.OnClick, function()
		OutFitPreviewData.tbCurPreview = {}
		OutFitPreviewData.tbCurBagPreviewItem = {}
		Event.Dispatch("ON_RESETPLAYER_OUTFIT")
		Event.Dispatch("ON_UPDATE_OUTFITITEM")
		Event.Dispatch("ON_UPDATE_OUTFIT_BAG_CELL")
		self:UpdatePendantInfo()
		self:UpdateOutFitInfo()
		self:UpdateEquipInfo()
		self:UpdateWeaponInfo()
	end)
end

function UIOutfitChangeView:RegEvent()
	--Event.Reg(self, EventType.XXX, func)
end

function UIOutfitChangeView:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOutfitChangeView:UpdateInfo()
	local player = self:GetPlayer()
	if not player then return end
	if self.nPlayerID == g_pClientPlayer.dwID then
		UIHelper.SetString(self.LabelTitle, "背包内的外观")
	else
		local szName = player.szName
		UIHelper.SetString(self.LabelTitle, string.format("%s的外观", UIHelper.GBKToUTF8(szName)))
	end
	UIHelper.SetVisible(self.WidgetContentSelfOutfit, self.nPlayerID == g_pClientPlayer.dwID)
	UIHelper.SetVisible(self.WidgetContentPlayerOutfit, self.nPlayerID ~= g_pClientPlayer.dwID)
	if self.nPlayerID == g_pClientPlayer.dwID then	--玩家背包外观
		UIHelper.RemoveAllChildren(self.LayoutSelfBagOutfit)
		local tbPendantList, tbExteriorList, tbEquipList = OutFitPreviewData.GetPlayerBagItemList()
		self:UpdatePlayerPendantGroup(tbPendantList)
		self:UpdatePlayerExteriorGroup(tbExteriorList)
		self:UpdatePlayerEquipGroup(tbEquipList)
		Timer.AddFrame(self, 1, function ()
			UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSelfBagOutfit)
		end)
		
	else
		self:UpdatePendantInfo()
		self:UpdateOutFitInfo()
		self:UpdateEquipInfo()
		self:UpdateWeaponInfo()
	end
	Event.Dispatch("ON_UPDATE_PREVIEW_MODEL_LOOKPOS", "center")

end

function UIOutfitChangeView:UpdatePendantInfo()
	local player = self:GetPlayer()
	if not player then return end

	local nPetIndex = player.GetEquippedPendentPet()
    if nPetIndex and nPetIndex > 0 then
        PendantType[8] = nPetIndex
	else
		PendantType[8] = 0
    end
	self.tbScriptPandentItem = self.tbScriptPandentItem or {}
	for i, widgetItem in ipairs(self.tbPendantItem) do
		self.tbScriptPandentItem[i] = self.tbScriptPandentItem[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, widgetItem)
		if i == 8 then --特判宠物
			if PendantType[i] > 0 then
				UIHelper.SetVisible(self.tbScriptPandentItem[i]._rootNode, true)
				self.tbScriptPandentItem[i]:OnInitWithTabID(ITEM_TABLE_TYPE.CUST_TRINKET, PendantType[i])
                self.tbScriptPandentItem[i]:SetLabelCountVisible(false)
				UIHelper.ToggleGroupAddToggle(self.ToggleGroupItem, self.tbScriptPandentItem[i].ToggleSelect)
				UIHelper.SetSwallowTouches(self.tbScriptPandentItem[i].ToggleSelect,false)
				local nIndex = player.GetEquippedPendentPet()
				local nType = OutFitPreviewData.PandentItemType[4][0]
				local itemInfo = OutFitPreviewData.tbCurPreview[nType]
				UIHelper.SetVisible(self.tbPendantEquippedIcon[i], itemInfo and itemInfo.dwIndex == nIndex)
				
				self.tbScriptPandentItem[i]:SetClickCallback(function(nBox, nIndex)
                    if nBox and nIndex then
						self:SetPandentClickCallBack(true, nType, nBox, nIndex, i)
                    end
                end)
			else
				UIHelper.SetVisible(self.tbScriptPandentItem[i]._rootNode, false)
			end
		elseif player.GetSelectPendent(PendantType[i]) ~= 0 then
			UIHelper.SetVisible(self.tbScriptPandentItem[i]._rootNode, true)
            self.tbScriptPandentItem[i]:OnInitWithTabID(ITEM_TABLE_TYPE.CUST_TRINKET, player.GetSelectPendent(PendantType[i]))
            self.tbScriptPandentItem[i]:SetLabelCountVisible(false)
            UIHelper.ToggleGroupAddToggle(self.ToggleGroupItem, self.tbScriptPandentItem[i].ToggleSelect)
			UIHelper.SetSwallowTouches(self.tbScriptPandentItem[i].ToggleSelect,false)
			local nType = OutFitPreviewData.PandentItemType[1][PendantType[i]]
			local itemInfo = OutFitPreviewData.tbCurPreview[nType]
			local nIndex = player.GetSelectPendent(PendantType[i])
			UIHelper.SetVisible(self.tbPendantEquippedIcon[i], itemInfo and itemInfo.dwIndex == nIndex)

            self.tbScriptPandentItem[i]:SetClickCallback(function(nBox, nIndex)
                if nBox and nIndex then
					self:SetPandentClickCallBack(false, nType, nBox, nIndex, i)
                end
            end)
		else
			UIHelper.SetVisible(self.tbScriptPandentItem[i]._rootNode, false)
		end
	end
	self:ClearSelect()
end

function UIOutfitChangeView:UpdateOutFitInfo()
    -- 基础数据校验
    local player = self:GetPlayer()
    if not player or not GetExterior() then return end
    
    -- 数据预处理
    local nCurrentSetID = player.GetCurrentSetID() or 0
    local tExteriorSet = player.GetExteriorSet(nCurrentSetID) or {}
    local tWeaponExterior = player.GetWeaponExteriorSet(nCurrentSetID) or {}
    local tRepresentID = player.GetRepresentID() or {}
    local nHairID = tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE] or 0
    
    -- 初始化容器
    self.tbScriptOutfitItem = self.tbScriptOutfitItem or {}
    
    -- 通用属性设置函数
    local function SetupCommonItemProperties(itemWidget, bShow)
        UIHelper.SetVisible(itemWidget._rootNode, bShow)
        if bShow then
            itemWidget:SetLabelCountVisible(false)
            UIHelper.ToggleGroupAddToggle(self.ToggleGroupItem, itemWidget.ToggleSelect)
            UIHelper.SetSwallowTouches(itemWidget.ToggleSelect, false)
        end
    end

	-- 延迟隐藏逻辑封装
	local function ScheduleHideItem(i)
		Timer.AddFrame(self, 1, function()
			if i == 7 then
				UIHelper.SetVisible(self.WidgetItemSecondWeapon, false)
			end
			UIHelper.SetVisible(self.tbScriptOutfitItem[i]._rootNode, false)
		end)
	end
    
    -- 武器处理逻辑
    local function ProcessWeapon(i, nWeaponSub)
        local dwExteriorID = tWeaponExterior[nWeaponSub] or 0
        local itemWidget = self.tbScriptOutfitItem[i]
        
        if dwExteriorID > 0 then
            itemWidget:OnInitWithTabID("WeaponExterior", dwExteriorID)
            SetupCommonItemProperties(itemWidget, true)
            
            -- 武器特定逻辑
            local nType = OutFitPreviewData.PandentItemType[5][nWeaponSub]
            local itemInfo = OutFitPreviewData.tbCurPreview[nType]
            local bShowIcon = itemInfo and itemInfo.nType == OutFitPreviewData.PreviewType.ExteriorWeapon
            UIHelper.SetVisible(self.tbExteriorEquippedIcon[i], bShowIcon)
            
            itemWidget:SetClickCallback(function()
                self:SetExteriorWeaponClickCallBack(player, nWeaponSub, nType, i)
            end)
            
            -- 轻剑特殊处理
            if i == 7 then
                UIHelper.SetString(self.LabelWeaponPosition, "轻剑")
            end
        else
            ScheduleHideItem(i)
        end
    end
    
    -- 发型处理逻辑
    local function ProcessHair(i)
        if nHairID > 0 then
            self.tbScriptOutfitItem[i]:OnInitWithIconID(10775, 2, 1)
            SetupCommonItemProperties(self.tbScriptOutfitItem[i], true)
            
            local nType = OutFitPreviewData.PandentItemType[6][EQUIPMENT_REPRESENT.HAIR_STYLE]
            local itemInfo = OutFitPreviewData.tbCurPreview[nType]
            local bShowIcon = itemInfo and itemInfo.nHairID > 0
            UIHelper.SetVisible(self.tbExteriorEquippedIcon[i], bShowIcon)
            
            self.tbScriptOutfitItem[i]:SetClickCallback(function()
                self:SetHairClickCallBack(nType, nHairID, i)
            end)
        else
            ScheduleHideItem(i)
        end
    end
    
    -- 通用装备处理
    local function ProcessEquipment(i, nExteriorSub)
        local dwExteriorID = tExteriorSet[nExteriorSub] or 0
        local itemWidget = self.tbScriptOutfitItem[i]
        
        if dwExteriorID > 0 then
            itemWidget:OnInitWithTabID("EquipExterior", dwExteriorID)
            SetupCommonItemProperties(itemWidget, true)
            
            local nType = OutFitPreviewData.PandentItemType[2][nExteriorSub]
            local itemInfo = OutFitPreviewData.tbCurPreview[nType]
            local bShowIcon = itemInfo and itemInfo.nType == OutFitPreviewData.PreviewType.ExteriorEquip
                          and itemInfo.dwExteriorID == dwExteriorID
            UIHelper.SetVisible(self.tbExteriorEquippedIcon[i], bShowIcon)
            
            itemWidget:SetClickCallback(function()
                self:SetExteriorClickCallBack(nType, tExteriorSet, nExteriorSub, dwExteriorID, i)
            end)
        else
            ScheduleHideItem(i)
        end
    end
    
    -- 主循环处理
    for i, widgetItem in ipairs(self.tbExteriorItem) do
        self.tbScriptOutfitItem[i] = self.tbScriptOutfitItem[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, widgetItem)
        
        if i == 6 or i == 7 then
            ProcessWeapon(i, EquipType[i])
        elseif i == 8 then
            ProcessHair(i)
        else
            ProcessEquipment(i, EquipType[i])
        end
    end
    
    self:ClearSelect()
end

function UIOutfitChangeView:UpdateEquipInfo()
	local player = self:GetPlayer()
    if not player then return end
	self.tbScriptEquipItem = self.tbScriptEquipItem or {}
	for i, widgetItem in ipairs(self.tbEquipItem) do
		self.tbScriptEquipItem[i] = self.tbScriptEquipItem[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, widgetItem)
		local item = player.GetItem(INVENTORY_INDEX.EQUIP, EquipEnum[i])
		if item then
			self.tbScriptEquipItem[i]:SetPlayerID(self.nPlayerID)
			self.tbScriptEquipItem[i]:OnInit(INVENTORY_INDEX.EQUIP, EquipEnum[i])
			self.tbScriptEquipItem[i]:SetLabelCountVisible(false)
			UIHelper.ToggleGroupAddToggle(self.ToggleGroupItem, self.tbScriptEquipItem[i].ToggleSelect)
			UIHelper.SetSwallowTouches(self.tbScriptEquipItem[i].ToggleSelect,false)
			local nType = OutFitPreviewData.PandentItemType[3][EquipEnum[i]]
			local itemInfo = OutFitPreviewData.tbCurPreview[nType]
			if itemInfo and itemInfo.nTabType == item.dwTabType and itemInfo.dwIndex == item.dwIndex then
				UIHelper.SetVisible(self.tbEquipEquipedIcon[i], true)
			else
				UIHelper.SetVisible(self.tbEquipEquipedIcon[i], false)
			end
			self.tbScriptEquipItem[i]:SetClickCallback(function(nBox, nIndex)
				if nBox and nIndex then
					self:SetEquipItemClickCallBack(player, nBox, nIndex, nType, i)
				end
			end)
			UIHelper.SetVisible(self.tbScriptEquipItem[i]._rootNode, true)
		else
			Timer.AddFrame(self, 1, function ()
				UIHelper.SetVisible(self.tbScriptEquipItem[i]._rootNode, false)
			end)
		end
	end
	self:ClearSelect()
end

function UIOutfitChangeView:UpdateWeaponInfo()
	local player = self:GetPlayer()
    if not player then return end
	self.tbScriptWeaponItem = self.tbScriptWeaponItem or {}
	for i, widgetItem in ipairs(self.tbWeaponItem) do
		self.tbScriptWeaponItem[i] = self.tbScriptWeaponItem[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, widgetItem)
		local item = player.GetItem(INVENTORY_INDEX.EQUIP, WeaponEnum[i])
		if item then
			self.tbScriptWeaponItem[i]:SetPlayerID(self.nPlayerID)
			self.tbScriptWeaponItem[i]:OnInit(INVENTORY_INDEX.EQUIP, WeaponEnum[i])
			self.tbScriptWeaponItem[i]:SetLabelCountVisible(false)
			UIHelper.ToggleGroupAddToggle(self.ToggleGroupItem, self.tbScriptWeaponItem[i].ToggleSelect)
			UIHelper.SetSwallowTouches(self.tbScriptWeaponItem[i].ToggleSelect,false)
			local nType = OutFitPreviewData.PandentItemType[3][WeaponEnum[i]]
			local itemInfo = OutFitPreviewData.tbCurPreview[nType]
			if itemInfo and itemInfo.nTabType == item.dwTabType and itemInfo.dwIndex == item.dwIndex then
				UIHelper.SetVisible(self.tbWeaponEquipedIcon[i], true)
			else
				UIHelper.SetVisible(self.tbWeaponEquipedIcon[i], false)
			end
			self.tbScriptWeaponItem[i]:SetClickCallback(function(nBox, nIndex)
				if nBox and nIndex then
					self:SetEquipWeaponClickCallBack(player, nBox, nIndex, nType, i)
				end
			end)
			UIHelper.SetVisible(self.tbScriptWeaponItem[i]._rootNode, true)
		else
			Timer.AddFrame(self, 1, function ()
				UIHelper.SetVisible(self.tbScriptWeaponItem[i]._rootNode, false)
			end)
		end

	end
	UIHelper.SetVisible(self.WidgetItemWeaponSecondary, player.bCanUseBigSword)
	if player.bCanUseBigSword then
		UIHelper.SetString(self.LabelItemPosition, "轻剑")
	else
		UIHelper.SetString(self.LabelItemPosition, "武器")
	end
	self:ClearSelect()
end

function UIOutfitChangeView:GetPlayer()
	local player = GetPlayer(self.nPlayerID)
	return player
end

function UIOutfitChangeView:ClearSelect()
	for _, scriptItem in pairs(self.tbScriptPandentItem or {}) do
        scriptItem:SetSelected(false)
    end
	
    for _, scriptItem in pairs(self.tbScriptOutfitItem or {}) do
        scriptItem:SetSelected(false)
    end

	for _, scriptItem in pairs(self.tbScriptEquipItem or {}) do
        scriptItem:SetSelected(false)
    end

	for _, scriptItem in pairs(self.tbScriptWeaponItem or {}) do
        scriptItem:SetSelected(false)
    end
end

function UIOutfitChangeView:UpdatePlayerPendantGroup(tbItemList)
	self.tbPandentGroupScript = nil
	if tbItemList and not table.is_empty(tbItemList) then
		self.tbPandentGroupScript = UIHelper.AddPrefab(PREFAB_ID.WidgetOutfitGroup, self.LayoutSelfBagOutfit, tbItemList, OutFitPreviewData.PreviewType.Pandent)
	end
	
end

function UIOutfitChangeView:UpdatePlayerExteriorGroup(tbItemList)
	self.tbExteriorGroupScript = nil
	if tbItemList and not table.is_empty(tbItemList) then
		self.tbExteriorGroupScript = UIHelper.AddPrefab(PREFAB_ID.WidgetOutfitGroup, self.LayoutSelfBagOutfit, tbItemList, OutFitPreviewData.PreviewType.ExteriorEquip)
	end
end

function UIOutfitChangeView:UpdatePlayerEquipGroup(tbItemList)
	self.tbEquipGroupScript = nil
	if tbItemList and not table.is_empty(tbItemList) then
		self.tbEquipGroupScript = UIHelper.AddPrefab(PREFAB_ID.WidgetOutfitGroup, self.LayoutSelfBagOutfit, tbItemList, OutFitPreviewData.PreviewType.Equip)
	end
end

function UIOutfitChangeView:UpdatePendentPetItemInfo(nType, dwIndex, nIndex)
	OutFitPreviewData.tbCurPreview[nType] = {["nType"] = OutFitPreviewData.PreviewType.Pandent, ["nTabType"] = ITEM_TABLE_TYPE.CUST_TRINKET, ["dwIndex"] = nIndex}
	UIHelper.SetVisible(self.tbPendantEquippedIcon[dwIndex], true)
	Timer.AddFrame(self, 1, function ()
		Event.Dispatch("UPDATE_PREVIEW_OUTFIT")
		Event.Dispatch("ON_UPDATE_OUTFITITEM")
	end)
end

function UIOutfitChangeView:SetPandentClickCallBack(bPet, nType, nBox, nIndex, nKey)
	if OutFitPreviewData.tbCurPreview[nType] then
		--脱下--dwTabType
		local itemInfo = OutFitPreviewData.tbCurPreview[nType]
		local nOldIndex = g_pClientPlayer.GetEquippedPendentPet() or 0
		if bPet then
			Event.Dispatch("ON_CANCEL_PANDENTPETPREVIEW", itemInfo.nTabType, itemInfo.dwIndex, itemInfo.nTabType, nOldIndex)
		else
			nOldIndex = g_pClientPlayer.GetSelectPendent(PendantType[nType]) or 0
			Event.Dispatch("ON_CANCEL_PANDENTPREVIEW", itemInfo.nTabType, itemInfo.dwIndex, ITEM_TABLE_TYPE.CUST_TRINKET, nOldIndex)
		end
		if itemInfo.nTabType == nBox and itemInfo.dwIndex == nIndex and UIHelper.GetVisible(self.tbPendantEquippedIcon[nKey]) then
			OutFitPreviewData.tbCurPreview[nType] = nil
			UIHelper.SetVisible(self.tbPendantEquippedIcon[nKey], false)
			Event.Dispatch("ON_UPDATE_OUTFITITEM")
		else
			self:UpdatePendentPetItemInfo(nType, nKey, nIndex)
		end
	else
		self:UpdatePendentPetItemInfo(nType, nKey, nIndex)
	end
end

function UIOutfitChangeView:UpdateExteriorWeaponItemInfo(nType, dwWeaponID, nKey)
	OutFitPreviewData.tbCurPreview[nType] = {["nType"] = OutFitPreviewData.PreviewType.ExteriorWeapon, ["dwWeaponID"] = dwWeaponID}
	UIHelper.SetVisible(self.tbExteriorEquippedIcon[nKey], true)
	Timer.AddFrame(self, 1, function ()
		Event.Dispatch("UPDATE_PREVIEW_OUTFIT")
		Event.Dispatch("ON_UPDATE_OUTFITITEM")
	end)
end

function UIOutfitChangeView:SetExteriorWeaponClickCallBack(player, nWeaponSub, nType, nKey)
	local nPlayerCurrentSetID = g_pClientPlayer.GetCurrentSetID() or 0
	local tPlayerWeaponExterior = g_pClientPlayer.GetWeaponExteriorSet(nPlayerCurrentSetID) or {}
	local nPlayerOldIndex = tPlayerWeaponExterior[nWeaponSub] or 0
	
	local nOtherPlayerCurrentSetID = player.GetCurrentSetID() or 0
	local tOtherPlayerWeaponExterior = player.GetWeaponExteriorSet(nOtherPlayerCurrentSetID) or {}
	local nOtherPlayerIndex = tOtherPlayerWeaponExterior[nWeaponSub] or 0
	if OutFitPreviewData.tbCurPreview[nType] then
		if OutFitPreviewData.tbCurPreview[nType].nType == OutFitPreviewData.PreviewType.ExteriorWeapon then	--右边为外装武器
			if OutFitPreviewData.tbCurPreview[nType].dwWeaponID == nOtherPlayerIndex and UIHelper.GetVisible(self.tbExteriorEquippedIcon[nKey]) then	--自己
				if g_pClientPlayer.dwForceID ~= FORCE_TYPE.CANG_JIAN and nKey == 7 then
				else
					Event.Dispatch("ON_CANCEL_EXTERIORWEAPONPREVIEW", nOtherPlayerIndex,  nPlayerOldIndex)
					OutFitPreviewData.tbCurPreview[nType] = nil
					UIHelper.SetVisible(self.tbExteriorEquippedIcon[nKey], false)
					Event.Dispatch("ON_UPDATE_OUTFITITEM")
				end
			end
		elseif OutFitPreviewData.tbCurPreview[nType].nType == OutFitPreviewData.PreviewType.EquipWeapon then --右边为装备武器
			UIHelper.SetVisible(self.tbWeaponEquipedIcon[nKey - 5], false)
			self:UpdateExteriorWeaponItemInfo(nType, nOtherPlayerIndex, nKey)
		end
	else--没有，直接穿
		self:UpdateExteriorWeaponItemInfo(nType, nOtherPlayerIndex, nKey)
	end
end

function UIOutfitChangeView:SetHairClickCallBack(nType, nHairID, nKey)
	if not g_pClientPlayer then
        return
end

	if OutFitPreviewData.tbCurPreview[nType] then
		local tRepresentID = g_pClientPlayer.GetRepresentID()
		local nHairID = tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE]
		Event.Dispatch("ON_UPDATE_HAIRPREVIEW", nHairID)
		OutFitPreviewData.tbCurPreview[nType] = nil
		UIHelper.SetVisible(self.tbExteriorEquippedIcon[nKey], false)
		Event.Dispatch("ON_UPDATE_OUTFITITEM")
	else
		self:UpdateHairInfo(nType, nHairID, nKey)
		UIHelper.SetVisible(self.tbExteriorEquippedIcon[nKey], true)
	end
end

function UIOutfitChangeView:UpdateHairInfo(nType, nHairID, nKey)
	OutFitPreviewData.tbCurPreview[nType] = {["nType"] = OutFitPreviewData.PreviewType.ExteriorHair, ["nTabType"] = ITEM_TABLE_TYPE.CUST_TRINKET, ["nHairID"] = nHairID}
	Event.Dispatch("UPDATE_PREVIEW_OUTFIT")
	Event.Dispatch("ON_UPDATE_OUTFITITEM")
end

function UIOutfitChangeView:UpdateExteriorItemInfo(nType, dwExteriorID, nKey)
	OutFitPreviewData.tbCurPreview[nType] = {["nType"] = OutFitPreviewData.PreviewType.ExteriorEquip, ["dwExteriorID"] = dwExteriorID}
	UIHelper.SetVisible(self.tbExteriorEquippedIcon[nKey], true)
	Timer.AddFrame(self, 1, function ()
		Event.Dispatch("UPDATE_PREVIEW_OUTFIT")
		Event.Dispatch("ON_UPDATE_OUTFITITEM")
	end)
end

function UIOutfitChangeView:SetExteriorClickCallBack(nType, tExteriorSet, nExteriorSub, dwExteriorID, nKey)
	if OutFitPreviewData.tbCurPreview[nType] then
		local dwNewExteriorID = tExteriorSet[nExteriorSub] or 0
		local nOldCurrentSetID = g_pClientPlayer.GetCurrentSetID() or 0
		local tOldExteriorSet = g_pClientPlayer.GetExteriorSet(nOldCurrentSetID) or {}
		local dwOldExteriorID = tOldExteriorSet[nExteriorSub] or 0
		Event.Dispatch("ON_CANCEL_EXTERIORPREVIEW", dwNewExteriorID, dwOldExteriorID)
		if OutFitPreviewData.tbCurPreview[nType].nType == OutFitPreviewData.PreviewType.ExteriorEquip then	--右边为外装
			if OutFitPreviewData.tbCurPreview[nType].dwExteriorID == dwNewExteriorID and UIHelper.GetVisible(self.tbExteriorEquippedIcon[nKey]) then	--自己
				OutFitPreviewData.tbCurPreview[nType] = nil
				UIHelper.SetVisible(self.tbExteriorEquippedIcon[nKey], false)
				Event.Dispatch("ON_UPDATE_OUTFITITEM")
			else	--其他外装
				self:UpdateExteriorItemInfo(nType, dwExteriorID, nKey)
			end

		elseif OutFitPreviewData.tbCurPreview[nType].nType == OutFitPreviewData.PreviewType.Equip then--右边为装备
			UIHelper.SetVisible(self.tbEquipEquipedIcon[nKey], false)
			self:UpdateExteriorItemInfo(nType, dwExteriorID, nKey)
		end
	else
		self:UpdateExteriorItemInfo(nType, dwExteriorID, nKey)
	end
end

function UIOutfitChangeView:UpdateEquipItemInfo(nType, dwTabType, dwIndex, nKey)
	OutFitPreviewData.tbCurPreview[nType] = {["nType"] = OutFitPreviewData.PreviewType.Equip, ["nTabType"] = dwTabType, ["dwIndex"] = dwIndex}
	UIHelper.SetVisible(self.tbEquipEquipedIcon[nKey], true)
	Timer.AddFrame(self, 1, function ()
		Event.Dispatch("UPDATE_PREVIEW_OUTFIT")
		Event.Dispatch("ON_UPDATE_OUTFITITEM")
	end)
end

function UIOutfitChangeView:SetEquipItemClickCallBack(player, nBox, nIndex, nType, nKey)
	local Item = ItemData.GetPlayerItem(player, nBox, nIndex)
	local tbOldItem = g_pClientPlayer.GetItem(INVENTORY_INDEX.EQUIP, EquipEnum[nKey]) or {["dwTabType"] = 0, ["dwIndex"] = 0}
	if OutFitPreviewData.tbCurPreview[nType] then
		Event.Dispatch("ON_CANCEL_EQUIP_PREVIEW", Item.dwTabType, Item.dwIndex, tbOldItem.dwTabType, tbOldItem.dwIndex)
		if OutFitPreviewData.tbCurPreview[nType].nType == OutFitPreviewData.PreviewType.Equip then	--右边为装备
			local tbCurItem = OutFitPreviewData.tbCurPreview[nType]
			if Item.dwTabType == tbCurItem.nTabType and Item.dwIndex == tbCurItem.dwIndex and UIHelper.GetVisible(self.tbEquipEquipedIcon[nKey]) then	--自己
				OutFitPreviewData.tbCurPreview[nType] = nil
				UIHelper.SetVisible(self.tbEquipEquipedIcon[nKey], false)
				local dwExteriorID = CoinShop_GetExteriorID(Item.dwTabType, Item.dwIndex)
				Event.Dispatch("ON_UPDATE_OUTFITITEM")
			else	--其他
				self:UpdateEquipItemInfo(nType, Item.dwTabType, Item.dwIndex, nKey)
			end
		elseif OutFitPreviewData.tbCurPreview[nType].nType == OutFitPreviewData.PreviewType.ExteriorEquip then --右边为外装
			UIHelper.SetVisible(self.tbExteriorEquippedIcon[nKey], false)
			self:UpdateEquipItemInfo(nType, Item.dwTabType, Item.dwIndex, nKey)
		end
	else
		self:UpdateEquipItemInfo(nType, Item.dwTabType, Item.dwIndex, nKey)
	end
end

function UIOutfitChangeView:UpdateEquipWeaponItemInfo(nType, dwTabType, dwIndex, nKey)
	OutFitPreviewData.tbCurPreview[nType] = {["nType"] = OutFitPreviewData.PreviewType.EquipWeapon, ["nTabType"] = dwTabType, ["dwIndex"] = dwIndex}
	UIHelper.SetVisible(self.tbWeaponEquipedIcon[nKey], true)
	Timer.AddFrame(self, 1, function ()
		Event.Dispatch("UPDATE_PREVIEW_OUTFIT")
		Event.Dispatch("ON_UPDATE_OUTFITITEM")
	end)
end

function UIOutfitChangeView:SetEquipWeaponClickCallBack(player, nBox, nIndex, nType, nKey)
	local Item = ItemData.GetPlayerItem(player, nBox, nIndex)
	if OutFitPreviewData.tbCurPreview[nType] then

		local tbOldItem = g_pClientPlayer.GetItem(INVENTORY_INDEX.EQUIP, WeaponEnum[nKey]) or {["dwTabType"] = 0, ["dwIndex"] = 0}
		local tbCurItem = OutFitPreviewData.tbCurPreview[nType]
		if OutFitPreviewData.tbCurPreview[nType].nType == OutFitPreviewData.PreviewType.EquipWeapon then	--装备武器
			if Item.dwTabType == tbCurItem.nTabType and Item.dwIndex == tbCurItem.dwIndex and UIHelper.GetVisible(self.tbWeaponEquipedIcon[nKey]) then	--自己
				Event.Dispatch("ON_CANCEL_EQUIP_PREVIEW", Item.dwTabType, Item.dwIndex, tbOldItem.dwTabType, tbOldItem.dwIndex)
				OutFitPreviewData.tbCurPreview[nType] = nil
				UIHelper.SetVisible(self.tbWeaponEquipedIcon[nKey], false)
				local hItemInfo = GetItemInfo(Item.dwTabType, Item.dwIndex)
				local dwWeaponID = CoinShop_GetWeaponIDByItemInfo(hItemInfo)
				Event.Dispatch("ON_UPDATE_OUTFITITEM")
			else 	--其他
				self:UpdateEquipWeaponItemInfo(nType, Item.dwTabType, Item.dwIndex, nKey)
			end
		elseif OutFitPreviewData.tbCurPreview[nType].nType == OutFitPreviewData.PreviewType.ExteriorWeapon then --外装武器
			UIHelper.SetVisible(self.tbExteriorEquippedIcon[nKey + 5], false)
			self:UpdateEquipWeaponItemInfo(nType, Item.dwTabType, Item.dwIndex, nKey)
		end
	else
		self:UpdateEquipWeaponItemInfo(nType, Item.dwTabType, Item.dwIndex, nKey)
	end
end

return UIOutfitChangeView