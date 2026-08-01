-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOutfitPreview
-- Date: 2024-02-29 16:59:10
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOutfitPreview = class("UIOutfitPreview")
local PendantType = {
    [1] = {["nType"] = PENDENT_SELECTED_POS.LSHOULDER, ["szImagePath"] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_ShoulderLeft", ["szName"] = "左肩", ["nIndex"] = 1},
    [2] = {["nType"] = PENDENT_SELECTED_POS.RSHOULDER, ["szImagePath"] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_ShoulderRight", ["szName"] = "右肩", ["nIndex"] = 2},
    [3] = {["nType"] = PENDENT_SELECTED_POS.FACE, ["szImagePath"] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_Face", ["szName"] = "面部", ["nIndex"] = 3},
    [4] = {["nType"] = PENDENT_SELECTED_POS.LGLOVE, ["szImagePath"] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_HandLeft", ["szName"] = "左手", ["nIndex"] = 4},
	[5] = {["nType"] = PENDENT_SELECTED_POS.RGLOVE, ["szImagePath"] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_HandRight", ["szName"] = "右手", ["nIndex"] = 5},
	[6] = {["nType"] = PENDENT_SELECTED_POS.GLASSES, ["szImagePath"] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_eye", ["szName"] = "眼部", ["nIndex"] = 6},
	[7] = {["nType"] = PENDENT_SELECTED_POS.BACKCLOAK, ["szImagePath"] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_Cloak", ["szName"] = "披风", ["nIndex"] = 7},
	[8] = {["nType"] = 0, ["szImagePath"] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_PetHanging", ["szName"] = "挂宠", ["nIndex"] = 8},
	[9] = {["nType"] = PENDENT_SELECTED_POS.BAG, ["szImagePath"] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_BagHanging", ["szName"] = "佩囊", ["nIndex"] = 9},
	[10] = {["nType"] = PENDENT_SELECTED_POS.BACK, ["szImagePath"] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_BackHanging", ["szName"] = "背部", ["nIndex"] = 10},
	[11] = {["nType"] = PENDENT_SELECTED_POS.WAIST, ["szImagePath"] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_WaistHanging", ["szName"] = "腰部", ["nIndex"] = 11},
	[12] = {["nType"] = PENDENT_SELECTED_POS.HEAD, ["szImagePath"] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_Head", ["szName"] = "头饰", ["nIndex"] = 20},
	[13] = {["nType"] = PENDENT_SELECTED_POS.HEAD1, ["szImagePath"] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_Head", ["szName"] = "头饰二", ["nIndex"] = 21},
	[14] = {["nType"] = PENDENT_SELECTED_POS.HEAD2, ["szImagePath"] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_Head", ["szName"] = "头饰三", ["nIndex"] = 22},
}

local ExteriorType = {
    [1] = {["nType"] = EXTERIOR_INDEX_TYPE.HELM, ["szImagePath"] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_hat", ["szName"] = "帽子", ["nIndex"] = 13},
    [2] = {["nType"] = EXTERIOR_INDEX_TYPE.CHEST, ["szImagePath"] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_topwear", ["szName"] = "上装", ["nIndex"] = 14},
    [3] = {["nType"] = EXTERIOR_INDEX_TYPE.WAIST, ["szImagePath"] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_belt", ["szName"] = "腰带", ["nIndex"] = 15},
    [4] = {["nType"] = EXTERIOR_INDEX_TYPE.BANGLE, ["szImagePath"] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_wristguard", ["szName"] = "护腕", ["nIndex"] = 16},
	[5] = {["nType"] = EXTERIOR_INDEX_TYPE.BOOTS, ["szImagePath"] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_shoes", ["szName"] = "鞋子", ["nIndex"] = 17},
	[6] = {["nType"] = WEAPON_EXTERIOR_BOX_INDEX_TYPE.MELEE_WEAPON, ["szImagePath"] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_weapon_primary", ["szName"] = "武器", ["nIndex"] = 12},
	[7] = {["nType"] = WEAPON_EXTERIOR_BOX_INDEX_TYPE.BIG_SWORD, ["szImagePath"] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_equip_weapon_secondary", ["szName"] = "重剑", ["nIndex"] = 18},
	[8] = {["nType"] = EQUIPMENT_REPRESENT.HAIR_STYLE, ["szImagePath"] = "UIAtlas2_Public_PublicItem_PublicItem_Icon_Img_hair", ["szName"] = "发型", ["nIndex"] = 19}
}

local tbStandardCameraLookPos = {
	["left"] = {
		x = 60,
		y = 80,
		z = 78
	},
	["center"] = {
		x = 10,
		y = 80,
		z = 78
	}
}

local tbLittleCameraLookPos = {
	["left"] = {
		x = 60,
		y = 65,
		z = 78
	},
	["center"] = {
		x = 10,
		y = 65,
		z = 78
	}
}

local tbFrame            = { tRadius = { 480, 730 } }

function UIOutfitPreview:OnEnter(nOtherPlayerID, tbCurPreview, bNpc)
	self.nOtherPlayerID = nOtherPlayerID
	self.tbCurPreview = tbCurPreview
	self.tRepresentID = nil
	self.bNpc = bNpc
	OutFitPreviewData.tbCurPreview = tbCurPreview
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
	self.nPlayerId = g_pClientPlayer and g_pClientPlayer.dwID or 0
	self.bDefaultApplyExterior = g_pClientPlayer.IsApplyExterior()
	self.bDefaultHideHat = g_pClientPlayer.bHideHat
	self.bDefaultHideFacePendent = g_pClientPlayer.bHideFacePendent

	self.bApplyExterior = g_pClientPlayer.IsApplyExterior()
	self.bHideHat = g_pClientPlayer.bHideHat
	self.bHideFacePendent = g_pClientPlayer.bHideFacePendent
	self:InitMiniScene()
	UIMgr.AddPrefab(PREFAB_ID.WidgetCoin, self.LayoutCurrency, CurrencyType.Coin, false, nil, true)
    self.RewardsScript = UIMgr.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.LayoutCurrency)
	self.RewardsScript:SetCurrencyType(CurrencyType.StorePoint)
    self:UpdateCurreny()
end

function UIOutfitPreview:OnExit()
	self.bInit = false
	self:UnRegEvent()

	UITouchHelper.UnBindModel()

	OutFitPreviewData.tbCurPreview = {}
	OutFitPreviewData.nCurrentOtherPlayerID = nil
	self.hModelView:release()
	if self.bDefaultApplyExterior then
		RemoteCallToServer("OnApplyExterior")
	else
		RemoteCallToServer("OnUnApplyExterior")
	end
	PlayerData.HideHat(self.bDefaultHideHat)
	g_pClientPlayer.SetFacePendentHideFlag(self.bDefaultHideFacePendent)

	local tbScript = UIMgr.GetViewScript(VIEW_ID.PanelOtherPlayer)
	if tbScript and tbScript.hModelView then
		UITouchHelper.BindModel(tbScript.TouchContainer, tbScript.hModelView)
	else
		--恢复中地图滚轮绑定
		tbScript = UIMgr.GetViewScript(VIEW_ID.PanelMiddleMap)
		if tbScript and tbScript.WidgetTouch and tbScript.TouchComponent then
			UITouchHelper.BindUIZoom(tbScript.WidgetTouch, function(delta)
				if tbScript.TouchComponent then
					tbScript.TouchComponent:Zoom(delta)
				end
			end)
		end
	end
end

function UIOutfitPreview:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
		UIMgr.Close(self)
	end)

	UIHelper.BindUIEvent(self.BtnOther, EventType.OnClick, function()
		UIMgr.Open(VIEW_ID.PanelOutfitChange, self.nOtherPlayerID)
	end)

	UIHelper.BindUIEvent(self.BtnSelfBag, EventType.OnClick, function()
		UIMgr.Open(VIEW_ID.PanelOutfitChange, self.nPlayerId)
	end)

	UIHelper.BindUIEvent(self.TogShow, EventType.OnSelectChanged, function (_, bSelected)
		UIHelper.SetVisible(self.WidgetAnchorName, not bSelected)
		UIHelper.SetVisible(self.WidgetAnchorButtons, not bSelected)
		UIHelper.SetVisible(self.LayoutCurrency, not bSelected)
		UIHelper.SetVisible(self.WidgetAniRight, not bSelected)
    end)

	UIHelper.BindUIEvent(self.TogPandentTitle, EventType.OnClick, function()
		local bSelected = UIHelper.GetSelected(self.TogPandentTitle)
		UIHelper.SetSelected(self.TogPandentTitle, bSelected)
		for k, itemCell in pairs(self.tbScriptPandentItem) do
			local item = itemCell.tbScriptOutfitItem
			if item then
				UIHelper.SetSelected(itemCell.TogChoose, bSelected)
			end
		end
	end)

	UIHelper.BindUIEvent(self.TogOutfitTitle, EventType.OnClick, function()
		local bSelected = UIHelper.GetSelected(self.TogOutfitTitle)
		UIHelper.SetSelected(self.TogOutfitTitle, bSelected)
		for k, itemCell in pairs(self.tbScriptEquipItem) do
			local item = itemCell.tbScriptOutfitItem
			if item then
				UIHelper.SetSelected(itemCell.TogChoose, bSelected)
			end
		end
	end)

	UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function()
		LOG.INFO("BuyPendant")
		if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EXTERIOR, "CoinShop") then
			return
		end
		local tChangeList = self:GetChange()
		if #tChangeList > 0 then
			UIMgr.Open(VIEW_ID.PanelSettleAccounts, tChangeList, false)
		end

	end)

	UIHelper.BindUIEvent(self.TogAppearanceNew, EventType.OnSelectChanged, function (_, bSelected)	--外观
		if not bSelected then
			TipsHelper.ShowNormalTip("已隐藏外观显示")
			self.bApplyExterior = false
			--把原有所有外观隐藏先
			local nCurrentSetID = g_pClientPlayer.GetCurrentSetID()
			local tExteriorSet = g_pClientPlayer.GetExteriorSet(nCurrentSetID)
			for i = 1, EXTERIOR_SUB_NUMBER do
				local nExteriorSub  = Exterior_BoxIndexToExteriorSub(i)
				local dwExteriorID = tExteriorSet[nExteriorSub]
				self:CancelByExterior(dwExteriorID, nil)
			end
		else
			TipsHelper.ShowNormalTip("已开启外观显示")
			self.bApplyExterior = true
			--把原有外观先显示出来先
			local nCurrentSetID = g_pClientPlayer.GetCurrentSetID()
			local tExteriorSet = g_pClientPlayer.GetExteriorSet(nCurrentSetID)
			for i = 1, EXTERIOR_SUB_NUMBER do
				local nExteriorSub = Exterior_BoxIndexToExteriorSub(i)
				local dwExteriorID = tExteriorSet[nExteriorSub]
				self:UpdateByExteriorID(dwExteriorID)
			end
		end
		self:HideHat(self.bHideHat)
		Timer.AddFrame(self, 3, function ()
			self:UpdatePlayerOutFit()
		end)
    end)

    UIHelper.BindUIEvent(self.TogHatNew, EventType.OnSelectChanged, function (_, bSelected)		--帽子
		self:HideHat(not bSelected)
		local szMsg = (bSelected and "已显示" or "已隐藏") .. "帽子"
        TipsHelper.ShowNormalTip(szMsg)
    end)

    UIHelper.BindUIEvent(self.TogFaceDecoNew, EventType.OnSelectChanged, function (_, bSelected)	--面饰

    end)

	UIHelper.BindUIEvent(self.TogFaceHangingNew, EventType.OnSelectChanged, function (_, bSelected)		--面挂
		local nOldIndex = g_pClientPlayer.GetSelectPendent(KPENDENT_TYPE.FACE) or 0
		local hItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, nOldIndex)
		if not bSelected then
			self.bHideFacePendent = true
			self.tRepresentID.bHideFacePendent = true
			--把原有面挂隐藏先
			if hItemInfo then
				local nRepresentSub, nRepresentColor = ExteriorView_GetRepresentSub(hItemInfo.nSub, hItemInfo.nDetail)
				self.tRepresentID[nRepresentSub] = 0
			end
			self:UpdateRoleRepresent()
		else
			self.bHideFacePendent = false
			self.tRepresentID.bHideFacePendent = false
			--把原有面挂显示出来先
			local hItemInfo = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, nOldIndex)
			if hItemInfo then
				local nRepresentSub, nRepresentColor = ExteriorView_GetRepresentSub(hItemInfo.nSub, hItemInfo.nDetail)
				self.tRepresentID[nRepresentSub] = hItemInfo.nRepresentID
			end
			self:UpdateRoleRepresent()
		end
		local szMsg = (bSelected and "已显示" or "已隐藏") .. "面挂"
        TipsHelper.ShowNormalTip(szMsg)
		Timer.AddFrame(self, 5, function()
			self:UpdatePlayerOutFit()
		end)
    end)


	UIHelper.BindUIEvent(self.BtnAllSet, EventType.OnClick, function()	--套装预览
		self:UpdateBySetID(self.dwSetExteriorID)
	end)

	UIHelper.BindUIEvent(self.ToggleCamera, EventType.OnSelectChanged, function (_, bSelected)
		local tbZoomConfigs = self.cameraModel:GetConfig()
		local szRadius = bSelected and "Max" or "Min"
		if szRadius == "Min" then
			self.cameraModel:UpdateZoom(1, 0, 0, 0.2)
		elseif szRadius == "Max" then
			self.cameraModel:UpdateZoom(#tbZoomConfigs - 1, 100, 0, 0.2)
		end

		if szRadius == "Max" then
            UIHelper.SetSelected(self.ToggleCamera, true, false)
        else
            UIHelper.SetSelected(self.ToggleCamera, false, false)
        end

    end)
end

function UIOutfitPreview:RegEvent()
	Event.Reg(self, "UPDATE_PREVIEW_OUTFIT", function ()
		self.tbCurPreview = OutFitPreviewData.tbCurPreview
		self:UpdateCurOptions()
        self:UpdatePlayerOutFit()
    end)

	Event.Reg(self, "ON_CANCEL_PANDENTPETPREVIEW", function (nNewTabType, nNewIndex, nOldTabType, nOldIndex)
        self:CancelByPandentPet(nNewTabType, nNewIndex, nOldTabType, nOldIndex)
    end)

	Event.Reg(self, "ON_CANCEL_PANDENTPREVIEW", function (nNewTabType, nNewIndex, nOldTabType, nOldIndex, nNewRepresentSub)
        self:CancelByPandent(nNewTabType, nNewIndex, nOldTabType, nOldIndex, nNewRepresentSub)
    end)

	Event.Reg(self, "ON_CANCEL_EQUIP_PREVIEW", function (nNewTabType, nNewIndex, nOldTabType, nOldIndex, nNewRepresentSub)
        self:CancelByEquipItem(nNewTabType, nNewIndex, nOldTabType, nOldIndex, nNewRepresentSub)
    end)

	Event.Reg(self, "ON_CANCEL_EXTERIORWEAPONPREVIEW", function (nNewIndex, nOldIndex)
        self:CancelByExteriorWeapon(nNewIndex, nOldIndex)
    end)

	Event.Reg(self, "ON_CANCEL_EXTERIORPREVIEW", function (nNewIndex, nOldIndex)
        self:CancelByExterior(nNewIndex, nOldIndex)
    end)

	Event.Reg(self, "ON_UPDATE_ITEMPREVIEW", function (dwTabType, dwIndex, nRepresentSub)
        self:UpdateByItem(dwTabType, dwIndex, nRepresentSub)
    end)

	Event.Reg(self, "ON_UPDATE_EXTERIORPREVIEW", function (dwExteriorID)
        self:UpdateByExteriorID(dwExteriorID)
    end)

	Event.Reg(self, "ON_UPDATE_EXTERIORWEAPONPREVIEW", function (dwWeaponID)
        self:UpdateByWeaponID(dwWeaponID)
    end)

	Event.Reg(self, "ON_RESETPLAYER_OUTFIT", function ()
		Timer.AddFrame(self, 1, function ()
			self.bApplyExterior = g_pClientPlayer.IsApplyExterior()
			self.bHideHat = g_pClientPlayer.bHideHat
			self.bHideFacePendent = g_pClientPlayer.bHideFacePendent
			self:ResetPlayer()
			self:UpdateTogOptions()
		end)
    end)

	Event.Reg(self, "ON_UPDATE_TOGPANDENTTITLE", function ()
        self:UpdateTogPandentTitle()
    end)

	Event.Reg(self, "ON_UPDATE_TOGOUTFITTITLE", function ()
        self:UpdateTogOutfitTitle()
    end)

	Event.Reg(self, EventType.OnEquipPakResourceDownload, function()
		self:UpdateModelInfo()
        self:UpdatePlayerOutFit()
    end)


	--Event.Reg(self, "ON_UPDATE_PREVIEW_MODEL_LOOKPOS", function(szType)
	--	local tbCameraLookPos = self:GetCameraLookPosByRoleType()
	--	local tbLookPos = tbCameraLookPos[szType]
	--	--self.hModelView:SetCameraLookPos(tbLookPos.x, tbLookPos.y, tbLookPos.z)
	--	if self.cameraModel then self.cameraModel:setlook(tbLookPos.x, tbLookPos.y, tbLookPos.z) else self.hModelView:SetCameraLookPos(tbLookPos.x, tbLookPos.y, tbLookPos.z) end
    --end)

	Event.Reg(self, "ON_UPDATE_HAIRPREVIEW", function(nHairID)
		self:UpdateByHairID(nHairID)
    end)

	Event.Reg(self, EventType.OnMiniSceneLoadProgress, function(nProcess)
        if nProcess >= 100 then
            local scene = self.hModelView.m_scene
            if scene and not QualityMgr.bDisableCameraLight then
                scene:OpenCameraLight(QualityMgr.szCameraLightForUI)
            end
        end
    end)

	Event.Reg(self, "ON_UPDATE_OUTFITITEM", function ()
        self:UpdateRightOutfitInfo()
		local nLength = 0
		for k, tbData in pairs(OutFitPreviewData.tbCurPreview) do
			if tbData.bSetItem then
				nLength = nLength + 1
			end
		end
		self.nSetSubLength = self.nSetSubLength or 0
		if nLength ~= 0 and nLength >= self.nSetSubLength then
			UIHelper.SetVisible(self.LabelSetName, true)
		else
			UIHelper.SetVisible(self.LabelSetName, false)
		end
    end)

	Event.Reg(self, "COIN_SHOP_BUY_RESPOND", function ()
		self:UpdateBuyBtnState()
    end)


	Event.Reg(self, "ON_UPDATE_SET_PREVIEW", function (dwExteriorID)	--整套预览
		self.dwSetExteriorID = dwExteriorID
		local bShow = dwExteriorID and dwExteriorID > 0 or not dwExteriorID and false
		UIHelper.SetVisible(self.WidgetBtnAllSet, bShow)
		UIHelper.LayoutDoLayout(self.LayoutBtns)
	end)
end

function UIOutfitPreview:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end



--PanelOtherPlayer
--PanelOutfitPreview
-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOutfitPreview:UpdateInfo()
	self:UpdateCurOptions()
	self:UpdateTogOptions()
	self:GetRepresentID()
	self:UpdatePlayerInfo()
	self:UpdateRightOutfitInfo()
	self:UpdatePlayerOutFit()
end

function UIOutfitPreview:UpdateCurOptions()
	for k, itemInfo in pairs(self.tbCurPreview) do
		if itemInfo.nType == OutFitPreviewData.PreviewType.ExteriorEquip then
			local tInfo = GetExterior().GetExteriorInfo(itemInfo.dwExteriorID)
			local nIndex = Exterior_SubToBoxIndex(tInfo.nSubType)
			local nRepresentSub = Exterior_BoxIndexToRepresentSub(nIndex)
			local nEquipSub = Exterior_RepresentSubToEquipSub(nRepresentSub)
			if nEquipSub == EQUIPMENT_INVENTORY.HELM then	--外观帽子
				self.bHideHat = false
			end
			self.bApplyExterior = true
		elseif itemInfo.nType == OutFitPreviewData.PreviewType.Equip then
			local hItemInfo = GetItemInfo(itemInfo.nTabType, itemInfo.dwIndex)
			local nRepresentSub = ExteriorView_GetRepresentSub(hItemInfo.nSub)
			if nRepresentSub == EQUIPMENT_REPRESENT.HELM_STYLE then	--帽子
				self.bHideHat = false
			end
		elseif itemInfo.nType == OutFitPreviewData.PreviewType.Pandent then
			local hItemInfo = GetItemInfo(itemInfo.nTabType, itemInfo.dwIndex)
			local hPendant
			if hItemInfo.nDetail and hItemInfo.nDetail > 0 then
				hPendant = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, hItemInfo.nDetail)
			else
				hPendant = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, itemInfo.dwIndex)
			end
			local nRepresentSub, nRepresentColor = ExteriorView_GetRepresentSub(hPendant.nSub, hPendant.nDetail)
			if nRepresentSub == EQUIPMENT_REPRESENT.FACE_EXTEND then	--面挂
				self.bHideFacePendent = false
			end
		end
	end
end

function UIOutfitPreview:UpdateTogOptions()
	UIHelper.SetSelected(self.TogAppearanceNew, self.bApplyExterior, false)
	UIHelper.SetSelected(self.TogHatNew, not self.bHideHat, false)
    --UIHelper.SetSelected(self.TogFaceDecoNew, self.bHideFace, false)		--面饰
    UIHelper.SetSelected(self.TogFaceHangingNew, not self.bHideFacePendent, false)	--挂件
end

function UIOutfitPreview:HideHat(bSelected)
	local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
	local hExteriorClient = GetExterior()
    if not hExteriorClient then
        return
    end
	if bSelected then	--隐藏
		self.bHideHat = true
		--把原有帽子隐藏先
		self.tRepresentID[EQUIPMENT_REPRESENT.HELM_STYLE] = 0
        self.tRepresentID[EQUIPMENT_REPRESENT.HELM_COLOR] = 0
	else	--显示
		self.bHideHat = false
		--把原有帽子显示先
		local nIndex = Exterior_RepresentToBoxIndex(EQUIPMENT_REPRESENT.HELM_STYLE)
		local dwExteriorID = 0
		if self.bApplyExterior then	--已显示外观
			local nCurrentSetID = g_pClientPlayer.GetCurrentSetID()
			local tExteriorSet = g_pClientPlayer.GetExteriorSet(nCurrentSetID)
			dwExteriorID = tExteriorSet[EXTERIOR_INDEX_TYPE.HELM]
		end
        local nEquipSub = Exterior_RepresentSubToEquipSub(EQUIPMENT_REPRESENT.HELM_STYLE)
        local hItem = PlayerData.GetPlayerItem(hPlayer, INVENTORY_INDEX.EQUIP, nEquipSub)
        if dwExteriorID and dwExteriorID > 0 then
            local tExteriorInfo = hExteriorClient.GetExteriorInfo(dwExteriorID)
            self.tRepresentID[EQUIPMENT_REPRESENT.HELM_STYLE] = tExteriorInfo.nRepresentID
            self.tRepresentID[EQUIPMENT_REPRESENT.HELM_COLOR] = tExteriorInfo.nColorID
        elseif hItem then
            self.tRepresentID[EQUIPMENT_REPRESENT.HELM_STYLE] = hItem.nRepresentID
            self.tRepresentID[EQUIPMENT_REPRESENT.HELM_COLOR] = hItem.nColorID
		else
			self.tRepresentID[EQUIPMENT_REPRESENT.HELM_STYLE] = 0
            self.tRepresentID[EQUIPMENT_REPRESENT.HELM_COLOR] = 0
        end
	end
	self:UpdateRoleRepresent()
	Timer.AddFrame(self, 2, function()
		self:UpdatePlayerOutFit()
	end)
end

function UIOutfitPreview:InitMiniScene()
	if self.bNpc then	--侠客
		self.hModelView = NpcModelView.CreateInstance(NpcModelView)
		self.hModelView:ctor()
		self.hModelView:init(nil, false, true, "data\\source\\maps\\MB商城_2023_001\\MB商城_2023_001.jsonmap", "PreviewPartner")
		self.MiniScene:SetScene(self.hModelView.m_scene)
		self:UpdateNpcInfo()
	else
		self.hModelView = PlayerModelView.CreateInstance(PlayerModelView)
		self.hModelView:ctor()
		self.hModelView:InitBy({
			szName = "PlayerOutFitPreview",
			bExScene = true,
			szExSceneFile = "data\\source\\maps\\MB商城_2023_001\\MB商城_2023_001.jsonmap",
			bAPEX = false,
			nModelType = UI_MODEL_TYPE.PANEL_VIEW
		 })
		self.MiniScene:SetScene(self.hModelView.m_scene)
		self:UpdateModelInfo()
		self:UpdateInfo()
	end
end

local tRoleTypeToCameraInfo = {
    [ROLE_TYPE.STANDARD_MALE] = { -200, 151, -600, 10, 80, 78, 0.33, 1.77777779, 20, 40000, true }, --rtStandardMale,     // 标准男
    [ROLE_TYPE.STANDARD_FEMALE] = { -200, 151, -600, 10, 80, 78, 0.33, 1.77777779, 20, 40000, true }, --rtStandardFemale,   // 标准女
    [ROLE_TYPE.LITTLE_BOY] = { -200, 151, -600, 10, 65, 78, 0.27, 1.77777779, 20, 40000, true }, --rtLittleBoy,        // 小男孩
    [ROLE_TYPE.LITTLE_GIRL] = { -200, 143, -600, 10, 65, 78, 0.27, 1.77777779, 20, 40000, true }, --rtLittleGirl,       // 小孩女
}

function UIOutfitPreview:InitCamera(camera, szType, nIndex, nZoomIndex, nZoomValue)
    if not camera then
        return
    end
    local nWidth, nHeight = UIHelper.GetContentSize(self.MiniScene)
    camera:init(
        self.hModelView.m_scene,
        0, 0, 0, 0, 0, 0, 0.3,
		nWidth / nHeight, nil, nil, true
    )

	camera:InitCameraConfig(szType, nIndex, nZoomIndex, nZoomValue)
end

function UIOutfitPreview:UpdateModelInfo()
	self.hModelView:UnloadModel()

    if not self.nPlayerId then
        return
    end
	local hPlayer = GetPlayer(self.nPlayerId)

	self.hModelView:LoadPlayerRes(self.nPlayerId, false, false)
	self.hModelView:LoadModel()
	self.hModelView:SetWeaponSocketDynamic()
	self.hModelView:PlayAnimation("Idle", "loop")

	self.hModelView:SetTranslation(0, 0, 0)

	local nRoleType   = Player_GetRoleType(hPlayer)
	self.cameraModel = MiniSceneCamera.CreateInstance(MiniSceneCamera)
    self.cameraModel:ctor()

	local nRoleType = Player_GetRoleType(hPlayer)
	local tbCameraInfo = ExteriorCharacter.GetCameraInfo()
    local nCameraIndex = tbCameraInfo.tbIDs[nRoleType]
    self:InitCamera(self.cameraModel, tbCameraInfo.szType, nCameraIndex, tbCameraInfo.nDefaultZoomIndex, tbCameraInfo.nDefaultZoomValue)

	UITouchHelper.BindModel(self.TouchContainer, self.hModelView, self.cameraModel, { tbFrame = tbFrame })
end

function UIOutfitPreview:TouchModel(bTouch, x, y)
    self.hModelView:TouchModel(bTouch, x, y)
end

function UIOutfitPreview:UpdatePlayerInfo()
	UIHelper.SetString(self.LabelName, GBKToUTF8(g_pClientPlayer.szName))
	UIHelper.SetSpriteFrame(self.ImgPlayerSchoolIcon, PlayerForceID2SchoolImg2[g_pClientPlayer.dwForceID])
	if not self.nOtherPlayerID then
		UIHelper.SetVisible(self.BtnOther, false)
	end
end

function UIOutfitPreview:UpdatePlayerOutFit()
	UIHelper.SetVisible(self.WidgetDownloadBtnShell, false)
	if not table.is_empty(self.tbCurPreview) then
		--单件试穿
		for k, iteminfo in pairs(self.tbCurPreview) do
			if iteminfo.nType == OutFitPreviewData.PreviewType.Equip or iteminfo.nType == OutFitPreviewData.PreviewType.Pandent or iteminfo.nType == OutFitPreviewData.PreviewType.EquipWeapon then	--防具或饰品
				local dwTabType = iteminfo.nTabType
				local dwIndex = iteminfo.dwIndex
				local nRepresentSub = OutFitPreviewData.GetPendantSub(k)
				self:UpdateByItem(dwTabType, dwIndex, nRepresentSub)
			elseif iteminfo.nType == OutFitPreviewData.PreviewType.ExteriorWeapon then	--武器
				local dwWeaponID = iteminfo.dwWeaponID
				self:UpdateByWeaponID(dwWeaponID)
			elseif iteminfo.nType == OutFitPreviewData.PreviewType.ExteriorEquip then	--外观
				local dwExteriorID = iteminfo.dwExteriorID
				self:UpdateByExteriorID(dwExteriorID)
			elseif iteminfo.nType == OutFitPreviewData.PreviewType.ExteriorHair then
				local nHairID = iteminfo.nHairID
				self:UpdateByHairID(nHairID)
			end
		end
		self:UpdateDownloadEquipRes()
	else
		return
	end
	self:UpdateTogOptions()
end

function UIOutfitPreview:UpdateByItem(nTabType, nIndex, nRepresentSub)
	local bCanPreview =  OutFitPreviewData.CanPreview(nTabType, nIndex)
    if not bCanPreview then
        return
    end
	self:UpdatePlayer(nil, nTabType, nIndex, nRepresentSub)
	self:UpdateRoleRepresent()
end

function UIOutfitPreview:UpdateByWeaponID(dwWeaponID)
	if dwWeaponID > 0 then
		self:UpdatePlayer(COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR, dwWeaponID, nil)
		self:UpdateRoleRepresent()
	end
end

function UIOutfitPreview:UpdateByExteriorID(dwExteriorID)
	if dwExteriorID > 0 then
		self:UpdatePlayer(COIN_SHOP_GOODS_TYPE.EXTERIOR, dwExteriorID, nil)
		self:UpdateRoleRepresent()
	end
end

local tbTogList = {
	[EQUIPMENT_REPRESENT.HELM_STYLE]  = 1,
    [EQUIPMENT_REPRESENT.CHEST_STYLE] = 2,
    [EQUIPMENT_REPRESENT.BANGLE_STYLE] = 4,
    [EQUIPMENT_REPRESENT.WAIST_STYLE] = 3,
    [EQUIPMENT_REPRESENT.BOOTS_STYLE] = 5,
    [EQUIPMENT_REPRESENT.WEAPON_STYLE] = 6,
    [EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] = 7,
}

function UIOutfitPreview:UpdatePlayer(eGoodsType, nTabType, nIndex, nNewRepresentSub)
	local hExterior = GetExterior()
    if not hExterior then
        return
    end
	local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
	if eGoodsType and (eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR or eGoodsType == COIN_SHOP_GOODS_TYPE.WEAPON_EXTERIOR or eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR) then
		if eGoodsType == COIN_SHOP_GOODS_TYPE.EXTERIOR then
            local dwExteriorID = nTabType
            local tExteriorInfo = hExterior.GetExteriorInfo(dwExteriorID)
			local tInfo = GetExterior().GetExteriorInfo(dwExteriorID)
			local nIndex = Exterior_SubToBoxIndex(tInfo.nSubType)
			local nRepresentSub = Exterior_BoxIndexToRepresentSub(nIndex)
			local nEquipSub = Exterior_RepresentSubToEquipSub(nRepresentSub)
			local nRepresentColor = Exterior_RepresentSubToColor(nRepresentSub)
			local hItem = ExteriorCharacter.GetPlayerItem(g_pClientPlayer, INVENTORY_INDEX.EQUIP, nEquipSub)
			local nTogIndex = tbTogList[nRepresentSub]
			self:UpdateHideExterior(tExteriorInfo, nRepresentSub, nRepresentColor, hItem, nTogIndex)
		elseif eGoodsType == COIN_SHOP_GOODS_TYPE.HAIR then
			local tHairDyeingData = hPlayer.GetEquippedHairCustomDyeingData(nTabType) or {}
			self.tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE] = nTabType
			self.tRepresentID.tHairDyeingData = tHairDyeingData
        else
			local dwWeaponID = nTabType
			local tExteriorInfo = CoinShop_GetWeaponExteriorInfo(dwWeaponID, hExterior)
			local dwWeaponEnchant1 = tExteriorInfo.nEnchantRepresentID1
            local dwWeaponEnchant2 = tExteriorInfo.nEnchantRepresentID2
            local nSub = EQUIPMENT_SUB.MELEE_WEAPON
			local nRepresentSub = ExteriorView_GetRepresentSub(nSub, tExteriorInfo.nDetailType)
			self:UpdatePlayerRes(
                nSub, tExteriorInfo.nDetailType,
                tExteriorInfo.nRepresentID, {tExteriorInfo.nColorID}, dwWeaponEnchant1,
                dwWeaponEnchant2
            )
        end
	else
		local hItemInfo = GetItemInfo(nTabType, nIndex)
		if hItemInfo.nGenre == ITEM_GENRE.COIN_SHOP_QUANTITY_LIMIT_ITEM then
			if hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.EXTERIOR then
				local dwExteriorID = hItemInfo.nDetail
                local tExteriorInfo = hExterior.GetExteriorInfo(dwExteriorID)
				self:UpdatePlayerRes(tExteriorInfo.nSubType, nil, tExteriorInfo.nRepresentID, {tExteriorInfo.nColorID})
				local nRepresentSub = ExteriorView_GetRepresentSub(tExteriorInfo.nSubType)
			elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HAIR then
				local nHairID = hItemInfo.nDetail
                self.tRepresentID[EQUIPMENT_REPRESENT.HAIR_STYLE] = nHairID
			elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PENDENT then
				local hPendant = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, hItemInfo.nDetail)
				local nRepresentSub, nRepresentColor = ExteriorView_GetRepresentSub(hPendant.nSub, hPendant.nDetail)
				if nRepresentSub ~= EQUIPMENT_REPRESENT.FACE_EXTEND or nRepresentSub == EQUIPMENT_REPRESENT.FACE_EXTEND and not self.bHideFacePendent then
					self.tRepresentID[nRepresentSub] = hPendant.nRepresentID
					self.tRepresentID.bHideFacePendent = self.bHideFacePendent
				end
                if nRepresentSub == EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND then
                    local tColorID = hPendant.GetColorID()
					self.tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR1] = tColorID[1]
                    self.tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR2] = tColorID[2]
                    self.tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR3] = tColorID[3]
				end
			elseif hItemInfo.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.PENDENT_PET then
				local hPendantPet = GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, hItemInfo.nDetail)
                local nRepresentSub, nRepresentColor = ExteriorView_GetRepresentSub(hPendantPet.nSub, hPendantPet.nDetail)
                self.tRepresentID[nRepresentSub] = hPendantPet.nRepresentID
                self.tRepresentID[EQUIPMENT_REPRESENT.PENDENT_PET_POS] = 0
			end
		else
			local tEnchant = hItemInfo.GetEnchantRepresentID()
            local tColorID = hItemInfo.GetColorID()
            local dwWeaponEnchant1, dwWeaponEnchant2
			local nRepresentSub
            if hItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and
                hItemInfo.nSub == EQUIPMENT_SUB.MELEE_WEAPON
            then
                dwWeaponEnchant1 = tEnchant[1]
                dwWeaponEnchant2 = tEnchant[2]
                -- local dwWeaponID = CoinShop_GetWeaponIDByItemInfo(hItemInfo)
                -- nRepresentSub = ExteriorView_GetRepresentSub(hItemInfo.nSub, hItemInfo.nDetail)
            else
				local dwExteriorID = CoinShop_GetExteriorID(nTabType, nIndex)
                nRepresentSub = ExteriorView_GetRepresentSub(hItemInfo.nSub)
				if hItemInfo.nSub == EQUIPMENT_SUB.HELM and self.bHideHat then
					hItemInfo.tRepresentID[EQUIPMENT_REPRESENT.HELM_STYLE] = 0
					hItemInfo.tRepresentID[EQUIPMENT_REPRESENT.HELM_COLOR] = 0
				end
				if hItemInfo.nSub == EQUIPMENT_SUB.HEAD_EXTEND and nNewRepresentSub then
					nRepresentSub = nNewRepresentSub
				end
            end
            self:UpdatePlayerRes(
                hItemInfo.nSub, hItemInfo.nDetail,
                hItemInfo.nRepresentID, tColorID, dwWeaponEnchant1,
                dwWeaponEnchant2, nRepresentSub
            )
		end
	end

	Timer.AddFrame(self, 1, function ()
		self:UpdateBuyBtnState()
	end)
end

function UIOutfitPreview:UpdateRoleRepresent()
	local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
	local x, y, z = self.hModelView:GetTranslation()
	local nYaw = self.hModelView:GetYaw()
	self.hModelView:UnloadModel()
	self.hModelView:LoadRes(hPlayer.dwID, self.tRepresentID)

	self.hModelView:LoadModel()
	self.hModelView:PlayAnimation("Idle", "loop")
	self.hModelView:SetTranslation(x, y, z)
    self.hModelView:SetYaw(nYaw)
end

function UIOutfitPreview:UpdatePlayerRes(nSubType, nDetailType, nRepresentID, tColorID,dwWeaponEnchant1, dwWeaponEnchant2, nSetRepresentSub)
	local nRepresentSub, nRepresentColor, nEnchantSub1, nEnchantSub2 = ExteriorView_GetRepresentSub(nSubType, nDetailType)
	if nSetRepresentSub then
		nRepresentSub = nSetRepresentSub
	end
	self.tRepresentID[nRepresentSub] = nRepresentID
    if nRepresentSub == EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND then
        self.tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR1] = tColorID[1]
        self.tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR2] = tColorID[2]
        self.tRepresentID[EQUIPMENT_REPRESENT.BACK_CLOAK_COLOR3] = tColorID[3]
    elseif nRepresentSub == EQUIPMENT_REPRESENT.PENDENT_PET then
        self.tRepresentID[EQUIPMENT_REPRESENT.PENDENT_PET_POS] = 0
    elseif nRepresentColor then
        self.tRepresentID[nRepresentColor] = tColorID[1]
    end

    if dwWeaponEnchant1 and dwWeaponEnchant2 and
        nEnchantSub1 and nEnchantSub2
    then
        self.tRepresentID[nEnchantSub1] = dwWeaponEnchant1
        self.tRepresentID[nEnchantSub2] = dwWeaponEnchant2
    end

	self.tRepresentID.tCustomRepresentData = self:GetRoleCustomPendant(self.tRepresentID)
end

function UIOutfitPreview:GetRepresentID()
	local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
	if not self.tRepresentID then
		self:ResetPlayer()
	end
end

function UIOutfitPreview:ResetPlayer()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	local tRepresentID = Role_GetRepresentID(hPlayer)
	tRepresentID.tBody = hPlayer.GetEquippedBodyBoneData()
    tRepresentID.nBody = hPlayer.GetEquippedBodyBoneIndex()

	tRepresentID.tCustomRepresentData = self:GetRoleCustomPendant(tRepresentID)
    self.tRepresentID = tRepresentID
	self:UpdateRoleRepresent()
end

function UIOutfitPreview:UpdateCurreny()
	local nRewards = CoinShopData.GetRewards()
    self.RewardsScript:SetLableCount(nRewards)
    UIHelper.LayoutDoLayout(self.LayoutCurrency)
end


function UIOutfitPreview:CancelByPandentPet(nNewTabType, nNewIndex, nOldTabType, nOldIndex)	--取消挂宠
	local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
	local hItemInfo = GetItemInfo(nOldTabType, nOldIndex) --原本身上的挂宠
	if hItemInfo then	--换成旧外装
		self:UpdateByItem(nOldTabType, nOldIndex)
	else--清空当前
		self.tRepresentID[EQUIPMENT_REPRESENT.PENDENT_PET_STYLE] = 0
		self.tRepresentID[EQUIPMENT_REPRESENT.PENDENT_PET_POS] = 0
	end
	self:UpdateRoleRepresent()
end

function UIOutfitPreview:CancelByPandent(nNewTabType, nNewIndex, nOldTabType, nOldIndex, nRepresentSub) 	--取消挂件
	local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
	if nOldTabType and nOldIndex and nOldIndex > 0 then
		self:UpdateByItem(nOldTabType, nOldIndex, nRepresentSub)
	else
		local tbNewItem
		local hNewItemInfo = GetItemInfo(nNewTabType, nNewIndex)
		if not hNewItemInfo.nDetail or hNewItemInfo.nDetail == 0 then
			tbNewItem = GetItemInfo(nNewTabType, nNewIndex)
		else
			tbNewItem = GetItemInfo(nNewTabType, hNewItemInfo.nDetail)
		end
		local nRepresentSub, nRepresentColor = ExteriorView_GetRepresentSub(tbNewItem.nSub, tbNewItem.nDetail)
		self.tRepresentID[nRepresentSub] = 0
	end
	self:UpdateRoleRepresent()
end

function UIOutfitPreview:CancelByExteriorWeapon(nNewIndex, nOldIndex) 		--取消外装武器
	local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
	if nOldIndex ~= 0 then 	--有武器
		self:UpdateByWeaponID(nOldIndex)
	else
		--local nIndex = CoinShop_GetWeaponIndex(dwID)
		local nIndex = CoinShop_GetWeaponIndex(nNewIndex)
		--ExteriorCharacter.ResUpdate_Weapon(nOldIndex, nIndex)
		local tExteriorInfo = CoinShop_GetWeaponExteriorInfo(nOldIndex)

		local nRepresentSub = Exterior_BoxIndexToRepresentSub(nIndex)
		local nSubType = Exterior_BoxIndexToSub(nIndex)
		local nRepresentColor = Exterior_RepresentSubToColor(nRepresentSub)
		local tWeaponEnchant = CoinShop_GetWeaponEnchantArray()

		local nEquipSub = Exterior_RepresentSubToEquipSub(nRepresentSub)
		local nEnchant1, nEnchant2 = unpack(tWeaponEnchant[nIndex])
		local hItem = ExteriorCharacter.GetPlayerItem(g_pClientPlayer, INVENTORY_INDEX.EQUIP, nEquipSub)
		local bHideBigSword = nRepresentSub == EQUIPMENT_REPRESENT.BIG_SWORD_STYLE and
				g_pClientPlayer.dwForceID ~= FORCE_TYPE.CANG_JIAN and g_pClientPlayer.dwForceID ~= 0
		local nForceID = hPlayer.dwForceID
		if not hItem or nOldIndex > 0 or bHideBigSword then
			self:UpdatePlayerRes(
                nEquipSub, tExteriorInfo.nDetailType, tExteriorInfo.nRepresentID, {tExteriorInfo.nColorID}, tExteriorInfo.nEnchantRepresentID1, tExteriorInfo.nEnchantRepresentID2
            )
			self:UpdateRoleRepresent()
			return
		end

		local tEnchant = hItem.GetEnchantRepresentID()
		self.tRepresentID[nRepresentSub] = hItem.nRepresentID
		self.tRepresentID[nRepresentColor] = hItem.nColorID
		self.tRepresentID[nEnchant1] = tEnchant[1]
		self.tRepresentID[nEnchant2] = tEnchant[2]
	end
	self:UpdateRoleRepresent()
end

function UIOutfitPreview:CancelByExterior(nNewIndex, nOldIndex)	--取消外装
	local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
	local tInfo = GetExterior().GetExteriorInfo(nNewIndex)
    local nIndex = Exterior_SubToBoxIndex(tInfo.nSubType)
	local dwExteriorID = nOldIndex
	local tExteriorInfo = GetExterior().GetExteriorInfo(dwExteriorID)

    local nRepresentSub = Exterior_BoxIndexToRepresentSub(nIndex)
    local nSubType = Exterior_BoxIndexToSub(nIndex)
    local nRepresentColor = Exterior_RepresentSubToColor(nRepresentSub)

    local nEquipSub = Exterior_RepresentSubToEquipSub(nRepresentSub)
    local hItem = ExteriorCharacter.GetPlayerItem(g_pClientPlayer, INVENTORY_INDEX.EQUIP, nEquipSub)

    --if not hItem or dwExteriorID > 0 then
        --if nSubType ~= EQUIPMENT_SUB.HELM then
    	--self.tRepresentID[nRepresentSub] = tExteriorInfo.nRepresentID
    	--self.tRepresentID[nRepresentColor] = tExteriorInfo.nColorID
        --end
    --else
    --    --if nSubType ~= EQUIPMENT_SUB.HELM then
    --        self.tRepresentID[nRepresentSub] = hItem.nRepresentID
    --        self.tRepresentID[nRepresentColor] = hItem.nColorID
    --    --end
    --end
	if self.bApplyExterior then
		if nEquipSub ~= EQUIPMENT_INVENTORY.HELM or nEquipSub == EQUIPMENT_INVENTORY.HELM and not self.bHideHat then
			self.tRepresentID[nRepresentSub] = tExteriorInfo.nRepresentID
			self.tRepresentID[nRepresentColor] = tExteriorInfo.nColorID
		end
	else
		if hItem then
			if nEquipSub ~= EQUIPMENT_INVENTORY.HELM or nEquipSub == EQUIPMENT_INVENTORY.HELM and not self.bHideHat then
				self.tRepresentID[nRepresentSub] = hItem.nRepresentID
				self.tRepresentID[nRepresentColor] = hItem.nColorID
			end
		else
			self.tRepresentID[nRepresentSub] = 0
		end
	end
	self:UpdateRoleRepresent()
end

function UIOutfitPreview:CancelByEquipItem(nNewTabType, nNewIndex, nOldTabType, nOldIndex, nNewRepresentSub)
	local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

	if nOldTabType and nOldIndex and nOldIndex > 0 then
		self:UpdateByItem(nOldTabType, nOldIndex, nNewRepresentSub)
	elseif nNewTabType and nNewIndex and nNewIndex > 0 then
		local hNewItemInfo = GetItemInfo(nNewTabType, nNewIndex)
		local nRepresentSub = nil

		if hNewItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and hNewItemInfo.nSub == EQUIPMENT_SUB.MELEE_WEAPON then
			nRepresentSub = ExteriorView_GetRepresentSub(hNewItemInfo.nSub, hNewItemInfo.nDetail)
		else
			nRepresentSub = ExteriorView_GetRepresentSub(hNewItemInfo.nSub)
		end
		self.tRepresentID[nRepresentSub] = 0
		self:UpdateRoleRepresent()
	end
end

function UIOutfitPreview:UpdateRightOutfitInfo()
	self:UpdateRightPandentInfo()
	self:UpdateRightEquipInfo()
end

function UIOutfitPreview:UpdateRightPandentInfo()
	self.tbScriptPandentItem = self.tbScriptPandentItem or {}
	for i, nTypeInfo in ipairs(PendantType) do
		self.tbScriptPandentItem[i] = self.tbScriptPandentItem[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetOutfitGroupItemCell, self.LayoutPandent, nTypeInfo, self.nOtherPlayerID, self.ToggleGroupItem, self.tbCurPreview)
	end
	UIHelper.LayoutDoLayout(self.LayoutPandent)
	UIHelper.LayoutDoLayout(self.WidgetPandentGroup)
end

function UIOutfitPreview:UpdateRightEquipInfo()
	self.tbScriptEquipItem = self.tbScriptEquipItem or {}
	local nType = OutFitPreviewData.PreviewType.Exterior
	for i, nTypeInfo in ipairs(ExteriorType) do
		self.tbScriptEquipItem[i] = self.tbScriptEquipItem[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetOutfitGroupItemCell, self.LayoutEquip, nTypeInfo, self.nOtherPlayerID, self.ToggleGroupItem, self.tbCurPreview)
		local item = self.tbScriptEquipItem[i].tbScriptOutfitItem
	end
end

function UIOutfitPreview:UpdateTogPandentTitle()
	for k, itemCell in pairs(self.tbScriptPandentItem) do
		if itemCell.tbScriptOutfitItem then
			local bSelected = UIHelper.GetSelected(itemCell.TogChoose)
			if not bSelected then
				UIHelper.SetSelected(self.TogPandentTitle, false)
				return
			end
		end
	end
	UIHelper.SetSelected(self.TogPandentTitle, true)
end

function UIOutfitPreview:UpdateTogOutfitTitle()
	for k, itemCell in pairs(self.tbScriptEquipItem) do
		if itemCell.tbScriptOutfitItem then
			local bSelected = UIHelper.GetSelected(itemCell.TogChoose)
			if not bSelected then
				UIHelper.SetSelected(self.TogOutfitTitle, false)
				return
			end
		end
	end
	UIHelper.SetSelected(self.TogOutfitTitle, true)
end

function UIOutfitPreview:UpdateBuyBtnState()
	local tbBuyList = self:GetChange()
	if #tbBuyList > 0 then
		UIHelper.SetButtonState(self.BtnBuy, BTN_STATE.Normal)
	else
		UIHelper.SetButtonState(self.BtnBuy, BTN_STATE.Disable)
	end
end

local tRepresentSubToIndex =
{
    [EQUIPMENT_REPRESENT.HAIR_STYLE] = 0,
    [EQUIPMENT_REPRESENT.HELM_STYLE] = 1,
    [EQUIPMENT_REPRESENT.CHEST_STYLE] = 2,
    [EQUIPMENT_REPRESENT.BANGLE_STYLE] = 4,
    [EQUIPMENT_REPRESENT.WAIST_STYLE] = 3,
    [EQUIPMENT_REPRESENT.BOOTS_STYLE] = 5,
    [EQUIPMENT_REPRESENT.WEAPON_STYLE] = 12,
    [EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] = 13,
}

function UIOutfitPreview:GetChange()
	local tChangeList = {}
	for k, tbScript in pairs(self.tbScriptEquipItem) do
		if tbScript.bCanBuy and not tbScript.bHave then
			local tItem = CoinShopData.FormatGood(tbScript.dwGoodsID, tbScript.eGoodsType)
			table.insert(tChangeList, tItem)
		end
	end
    return tChangeList
end

function UIOutfitPreview:UpdateDownloadEquipRes()
    if not PakDownloadMgr.IsEnabled() then
        return
    end
    if not self.hModelView then
        return
    end
    --local nRoleType, tEquipList, tEquipSfxList = self.hModelView:GetPakEquipResource()
	local nRoleType = g_pClientPlayer.nRoleType
    local tEquipList, tEquipSfxList = Player_GetPakEquipResource(nRoleType, self.tRepresentID.nHatStyle, self.tRepresentID)
    local scriptDownload                       = UIHelper.GetBindScript(self.WidgetDownloadBtnShell)
    local tConfig                              = {}
    tConfig.bLong                              = true
    local bRemoteNotExist
    self.nDownloadDynamicID, bRemoteNotExist   = PakDownloadMgr.UserCheckDownloadEquipRes(nRoleType, tEquipList, tEquipSfxList, self.nDownloadDynamicID)
    CoinShopPreview.UpdateSimpleDownloadBtn(scriptDownload, self.nDownloadDynamicID, bRemoteNotExist, tConfig)
end

function UIOutfitPreview:UpdateByHairID(nHairID)
	if nHairID > 0 then
		self:UpdatePlayer(COIN_SHOP_GOODS_TYPE.HAIR, nHairID, nil)
		self:UpdateRoleRepresent()
	end
end

function UIOutfitPreview:UpdateBySetID(dwExteriorID)	--整套预览
	local hExterior = GetExterior()
    if not hExterior then
        return
    end

	local tInfo = hExterior.GetExteriorInfo(dwExteriorID)
    if not tInfo then
        return
    end

	local tLine = Table_GetExteriorSet(tInfo.nSet)
    if not tLine then
        return
    end
	local tSub = tLine.tSub
	local szLabelName = UIHelper.GBKToUTF8(tLine.szSetName)
	UIHelper.SetVisible(self.LabelSetName, true)
	UIHelper.SetString(self.LabelSetName, string.format("试穿套装|%s", szLabelName))
	self.nSetSubLength = table.GetCount(tSub) or 0
	if tSub then
		for _, dwExteriorID in pairs(tSub) do
			local tExteriorInfo = hExterior.GetExteriorInfo(dwExteriorID)
			local nRepresentSub = ExteriorView_GetRepresentSub(tExteriorInfo.nSubType)
			local nIndex = tRepresentSubToIndex[nRepresentSub]
			self.tbScriptEquipItem[nIndex]:UpdateSetPreview(dwExteriorID)
		end
		UIHelper.SetVisible(self.WidgetBtnAllSet, false)
		UIHelper.LayoutDoLayout(self.LayoutBtns)
		Timer.AddFrame(self, 1, function ()
			Event.Dispatch("ON_UPDATE_OUTFITITEM")
			Event.Dispatch("UPDATE_PREVIEW_OUTFIT")
		end)
	end
end

function UIOutfitPreview:UpdateHideExterior(tExteriorInfo, nRepresentSub, nRepresentColor, hItem, nIndex)
	local nEquipSub = Exterior_RepresentSubToEquipSub(nRepresentSub)
	if self.bApplyExterior then 	--显示
		local bTogSelected = not table.is_empty(self.tbScriptEquipItem) and UIHelper.GetSelected(self.tbScriptEquipItem[nIndex].TogChoose)
		if bTogSelected then	--右边对应格子有勾选，穿右边的外观
			if nEquipSub ~= EQUIPMENT_INVENTORY.HELM or nEquipSub == EQUIPMENT_INVENTORY.HELM and not self.bHideHat then
				self:UpdatePlayerRes(tExteriorInfo.nSubType, nil, tExteriorInfo.nRepresentID, {tExteriorInfo.nColorID})
			end
		else	--自身的外观
			local nOldCurrentSetID = g_pClientPlayer.GetCurrentSetID() or 0
			local tOldExteriorSet = g_pClientPlayer.GetExteriorSet(nOldCurrentSetID) or {}
			local dwOldExteriorID = tOldExteriorSet[ExteriorType[nIndex].nType] or 0

			local tExteriorInfo = GetExterior().GetExteriorInfo(dwOldExteriorID)
			self.tRepresentID[nRepresentSub] = tExteriorInfo.nRepresentID
			self.tRepresentID[nRepresentColor] = tExteriorInfo.nColorID
		end
	else	--隐藏外观
		if hItem then
			if nEquipSub ~= EQUIPMENT_INVENTORY.HELM or nEquipSub == EQUIPMENT_INVENTORY.HELM and not self.bHideHat then
				self.tRepresentID[nRepresentSub] = hItem.nRepresentID
				self.tRepresentID[nRepresentColor] = hItem.nColorID
			end
		else
			self.tRepresentID[nRepresentSub] = 0
		end
	end
end

------------------------侠客-----------------------
function UIOutfitPreview:UpdateNpcInfo()
	self.tbPartnerList = Partner_GetAllPartnerList()
	local dwPartnerID
    local szName
	if not dwPartnerID then
        for _, tNpcInfo in ipairs(self.tbPartnerList) do
            if tNpcInfo.bHave then
                dwPartnerID = tNpcInfo.dwID
                szName = tNpcInfo.szName
                break
            end
        end
    end
	self:ChoiceNPC(dwPartnerID, szName)
	self:UpdatePartnerInfo()
end

function UIOutfitPreview:UpdatePlayerAction()
	local hPlayer = GetPlayer(self.nPlayerId)
    if not hPlayer then
        self.hModelView:PlayAnimation("Idle", "loop")
        return
    end

    local dwIdleActionID = hPlayer.GetDisplayIdleAction(PLAYER_IDLE_ACTION_DISPLAY_TYPE.COIN_SHOP)
    local dwRepresentID = CharacterIdleActionData.GetActionRepresentID(dwIdleActionID)

    if dwRepresentID and dwRepresentID > 0 then
        local szDefaultAni = CharacterIdleActionData.GetDefaultAni(PLAYER_IDLE_ACTION_DISPLAY_TYPE.COIN_SHOP)
        self.hModelView:PlayAnimationByLogicID(dwRepresentID, szDefaultAni)
    else
        self.hModelView:PlayAnimation("Idle", "loop")
    end
end

function UIOutfitPreview:ChoiceNPC(nPartnerID, szName)
	self.nCurPartnerID = nPartnerID
	local tNpcRepresentID = GetNpcAssistedTemplateRepresentID(nPartnerID)
	local tRepresentID = PartnerView.NPCRepresentToPlayerRepresent(tNpcRepresentID)

	-- 将外观应用上去
	local tExteriorList   = Partner_GetEquippedExteriorList(self.nPlayerId, nPartnerID)
	for nType, tInfo in pairs(tExteriorList) do
		PartnerExterior.UpdateRepresentID(tRepresentID, nType, tInfo)
	end
	local tNpcModel = Partner_GetNpcModelInfo(nPartnerID)
	tRepresentID    = NpcAssited_TransformDefaultResource(tNpcModel.nRoleType, GetNpcAssistedTemplateID(nPartnerID), 0, tRepresentID)
	self.hModelView:LoadNpcRes(tNpcModel.dwOrigModelID, false, tNpcModel.nRoleType, false, tNpcModel.bSheath, tRepresentID)

	self.hModelView:LoadModel()
	self.hModelView:PlayAnimation("Idle", "loop")

	self.hModelView:SetTranslation(0, 0, 0)
    self.hModelView:SetYaw(0.16)

	local nRoleType = OutFitPreviewData.GetPartnerRoleType(self.nCurPartnerID)
	local tCameraInfo = tRoleTypeToCameraInfo[nRoleType]
	self.hModelView:SetCamera(tCameraInfo)
	local tbCameraLookPos = self:GetCameraLookPosByRoleType()
	local tbLookPos = tbCameraLookPos["left"]
	self.hModelView:SetCameraLookPos(tbLookPos.x, tbLookPos.y, tbLookPos.z)
	self.hModelView.m_scene:SetMainPlayerPosition(0, 0, 0)
	UITouchHelper.BindModel(self.TouchContainer, self.hModelView)
end

function UIOutfitPreview:UpdatePartnerInfo()
	local tInfo = Table_GetPartnerNpcInfo(self.nCurPartnerID)
	UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(tInfo.szName))
    UIHelper.SetSpriteFrame(self.ImgPlayerSchoolIcon, PartnerKungfuIndexToImg[tInfo.nKungfuIndex])
end

local function GetRoleType()
    local nRoleType = 1
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return nRoleType
    end
    nRoleType = pPlayer.nRoleType
    return nRoleType
end

function UIOutfitPreview:GetCameraLookPosByRoleType()
	local nRoleType = GetRoleType()
	local tbCameraLookPos = tbStandardCameraLookPos

	if nRoleType == ROLE_TYPE.LITTLE_BOY or nRoleType == ROLE_TYPE.LITTLE_GIRL then
		tbCameraLookPos = tbLittleCameraLookPos
	end

	return tbCameraLookPos
end

function UIOutfitPreview:GetRoleCustomPendant(tRepresentID)	--挂件自定义
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tCustomRepresentData = {}
    local tType = GetAllCustomPendantType()
    for nIndex, v in pairs(tType) do
        if tRepresentID[nIndex] ~= 0 then
            local nRepresentID = tRepresentID[nIndex]
            local tData = CoinShopData.GetLocalCustomPendantData(nIndex, nRepresentID)
            tCustomRepresentData[nIndex] = tData
        end
    end
    return tCustomRepresentData
end

return UIOutfitPreview