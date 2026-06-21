-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildFurnitureEditPage
-- Date: 2023-04-27 11:01:38
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildFurnitureEditPage = class("UIHomelandBuildFurnitureEditPage")

function UIHomelandBuildFurnitureEditPage:OnEnter(tObjIDs, bUIMultiChoose)
    self.tObjIDs = tObjIDs
	self.bUIMultiChoose = bUIMultiChoose

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

	self:InitView()
	self:UpdateInfo()
	self:UpdateMultiChooseMode()
	self:UpdateCameraMode()
	self:UpdateMultiChooseTimer()
end

function UIHomelandBuildFurnitureEditPage:OnExit()
    self.bInit = false
end

function UIHomelandBuildFurnitureEditPage:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function ()
		HLBOp_Main.SetMoveObjEnabled(false)
        HLBOp_Bottom.EndBottom()
		HLBOp_Brush.EndBrush()
		HLBOp_CustomBrush.EndCustomBrush()

        HLBOp_Place.ConfirmPlace()
		HLBOp_MultiItemOp.ConfirmPlace()
		HLBOp_Blueprint.ConfirmMoveBlueprintPos()

		HLBOp_Select.ClearSelect()
		HLBOp_Place.CancelPlace()
		HLBOp_MultiItemOp.CancelPlace()
	end)

	UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function ()
		HLBOp_Select.ClearSelect()
		HLBOp_Place.CancelPlace()

		HLBOp_Brush.CancelBrush()
		HLBOp_Bottom.CancelBottom()
		HLBOp_MultiItemOp.CancelPlace()
		HLBOp_CustomBrush.CancelCustomBrush()
		HLBOp_Blueprint.CancelMoveBlueprint()

		if self.bUIMultiChoose then
			UIHelper.SetSelected(self.TogMultiChooseMode, false)
			HomelandInput.ExitMultiChooseMode()
			Event.Dispatch(EventType.OnHomelandExitMultiChoose)
		end
	end)

	UIHelper.BindUIEvent(self.BtnCopy, EventType.OnClick, function ()
		local tObjIDs = self.tObjIDs
		if #tObjIDs == 1 then
			local dwModelID = HLBOp_Amount.GetModelIDByObjID(tObjIDs[1])
			if FurnitureData.IsAutoBottomBrush(dwModelID) then
				TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_BUILDING_CANT_COPY_ITEM)
				return
			end
			HLBOp_SingleItemOp.Copy()
		else
			for i = 1, #tObjIDs do
				local dwModelID = HLBOp_Amount.GetModelIDByObjID(tObjIDs[i])
				if FurnitureData.IsAutoBottomBrush(dwModelID) then
					TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_BUILDING_CANT_COPY_ITEM)
					return
				end
			end
			HLBOp_MultiItemOp.Copy()
		end
	end)

	UIHelper.BindUIEvent(self.BtnDeleteBase, EventType.OnClick, function ()
		local tObjIDs = self.tObjIDs
		if #tObjIDs == 1 then
			local dwModelID = HLBOp_Amount.GetModelIDByObjID(tObjIDs[1])

			UIHelper.ShowConfirm(g_tStrings.STR_HOMELAND_REMOVE_BASEBOARD_CONFIRM_1, function ()
				HLBOp_Select.ClearSelect()
				HLBOp_Other.RemoveBasebord(tObjIDs[1])
			end)
		end
	end)

	UIHelper.BindUIEvent(self.BtnExchange, EventType.OnClick, function ()
		local tObjIDs = self.tObjIDs
		if tObjIDs[1] then
			local dwModelID = HLBOp_Amount.GetModelIDByObjID(tObjIDs[1])
			UIMgr.Open(VIEW_ID.PanelChangeJiMuSkin, dwModelID, #tObjIDs)
		end
	end)

	UIHelper.BindUIEvent(self.BtnMultiSelect, EventType.OnClick, function ()

	end)

	UIHelper.BindUIEvent(self.BtnLocate, EventType.OnClick, function ()
		local tObjIDs = self.tObjIDs
		if #tObjIDs >= 1 then
			HLBOp_Other.FocusObject(tObjIDs[1])
		end
	end)

	UIHelper.BindUIEvent(self.BtnLocateWarehouse, EventType.OnClick, function ()
		local tObjIDs = self.tObjIDs
		if #tObjIDs >= 1 then
			local dwModelID = HLBOp_Amount.GetModelIDByObjID(tObjIDs[1])
			Event.Dispatch(EventType.OnGotoHomelandFurnitureListOneItem, dwModelID)

			HLBOp_Select.ClearSelect()
			HLBOp_Place.CancelPlace()

			HLBOp_Brush.CancelBrush()
			HLBOp_Bottom.CancelBottom()
			HLBOp_MultiItemOp.CancelPlace()
			HLBOp_CustomBrush.CancelCustomBrush()
			HLBOp_Blueprint.CancelMoveBlueprint()

			if self.bUIMultiChoose then
				UIHelper.SetSelected(self.TogMultiChooseMode, false)
				HomelandInput.ExitMultiChooseMode()
				Event.Dispatch(EventType.OnHomelandExitMultiChoose)
			end
		end
	end)

	UIHelper.BindUIEvent(self.BtnOutput, EventType.OnClick, function ()
		local tObjIDs = self.tObjIDs
		if #tObjIDs == 1 then
			HLBOp_Blueprint.ExportBlueprint(false, tObjIDs[1])
		elseif #tObjIDs > 1 then
			HLBOp_Blueprint.ExportBlueprint(false, -1)
		end
	end)

	UIHelper.BindUIEvent(self.BtnPaint, EventType.OnClick, function ()
		UIHelper.SetVisible(self.LayoutItemOper, false)
		UIHelper.SetVisible(self.WidgetPaint, true)

		local tObjIDs = self.tObjIDs
		if #tObjIDs == 1 then
			dwModelID = tObjIDs[1]
			local tObjectInfo = HLBOp_Other.GetOneObjectInfo(dwModelID)
			local nCurColorIndex = -1
			if tObjectInfo then
				nCurColorIndex = tObjectInfo.nColorIndex
			end

			UIHelper.SetToggleGroupSelected(self.ToggleGroupColor, nCurColorIndex)
		end

		UIHelper.LayoutDoLayout(self.LayoutItemInfo)
	end)

	UIHelper.BindUIEvent(self.BtnColorConfirm, EventType.OnClick, function ()
		UIHelper.SetVisible(self.LayoutItemOper, true)
		UIHelper.SetVisible(self.WidgetPaint, false)

		UIHelper.LayoutDoLayout(self.LayoutItemInfo)
	end)

	UIHelper.BindUIEvent(self.BtnRestore, EventType.OnClick, function ()
		if self.tObjIDs.bSingle then
			HLBOp_SingleItemOp.Destroy(self.tObjIDs[1])
		else
			HLBOp_MultiItemOp.Destroy()
		end
	end)

	UIHelper.BindUIEvent(self.BtnCameraNext, EventType.OnClick, function ()
		HLBOp_Other.NextCameraMode()
		self:UpdateCameraMode()
	end)

	UIHelper.BindUIEvent(self.BtnCameraPrevious, EventType.OnClick, function ()
		HLBOp_Other.PrevCameraMode()
		self:UpdateCameraMode()
	end)

	UIHelper.BindUIEvent(self.BtnReturn, EventType.OnClick, function()
		HLBOp_Main.SetMoveObjEnabled(false)
        HLBOp_Bottom.EndBottom()
		HLBOp_Brush.EndBrush()
		HLBOp_CustomBrush.EndCustomBrush()

        HLBOp_Place.ConfirmPlace()
		HLBOp_MultiItemOp.ConfirmPlace()
		HLBOp_Blueprint.ConfirmMoveBlueprintPos()

		HLBOp_Select.ClearSelect()
		HLBOp_Place.CancelPlace()
		HLBOp_MultiItemOp.CancelPlace()

		if self.bUIMultiChoose then
			UIHelper.SetSelected(self.TogMultiChooseMode, false)
			HomelandInput.ExitMultiChooseMode()
			Event.Dispatch(EventType.OnHomelandExitMultiChoose)
		end
    end)

	UIHelper.BindUIEvent(self.BtnFlip, EventType.OnClick, function ()
		local bIsSingle, nCount, dwObjID, dwModelID = self:IsSingleItemOp()
		if bIsSingle then
			HLBOp_Other.MechanismReverse(dwObjID)
		end
	end)

	UIHelper.BindUIEvent(self.TogMakeGroup, EventType.OnClick, function(btn)
		local tSelectObjs = HLBOp_Select.GetSelectInfo()
		local bCanDestroyGroup, dwGroupID = HomelandBuildData.CanDestroyGroup(tSelectObjs)
		if bCanDestroyGroup then
			local dwObjID = tSelectObjs[1]
			local dwGroupID = HLBOp_Group.GetGroupID(dwObjID)
			HLBOp_Group.DestroyGroup(dwGroupID)
		else
			local aObjIDs = tSelectObjs
			for i = 1, #aObjIDs do
				local dwModelID = HLBOp_Amount.GetModelIDByObjID(aObjIDs[i])
				if FurnitureData.IsAutoBottomBrush(dwModelID) then
					TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_BUILDING_CANT_GROUP_BASEMENT)
					return
				end
			end
			if dwGroupID then
				HLBOp_Group.DestroyGroup(dwGroupID)
			end
			HLBOp_Group.GroupSelectObj()
		end
	end)

	UIHelper.BindUIEvent(self.TogMultiChooseMode, EventType.OnSelectChanged, function(btn, bSelected)
		if bSelected then
        	HomelandInput.EnterMultiChooseMode()
		else
			HomelandInput.ExitMultiChooseMode()
		end
    end)

	UIHelper.BindUIEvent(self.SliderHeight, EventType.OnChangeSliderPercent, function(SliderEventType, nSliderEvent)
        if nSliderEvent == ccui.SliderEventType.slideBallDown then
            self.bSliding = true

        elseif nSliderEvent == ccui.SliderEventType.slideBallUp then
            self.bSliding = false
            -- 强制修正滑块进度
            local fPerc = (self.fCurHeightCount - self.fMinHeightCount) / self.fTotalHeightCount * 100
            UIHelper.SetProgressBarPercent(self.SliderHeight, fPerc)
            UIHelper.SetProgressBarPercent(self.ImgHeightFg, fPerc)
			UIHelper.SetText(self.EditBoxHeight, math.floor(self.fCurHeightCount))
			HLBOp_SingleItemOp.SetObjLocalPos(HOMELAND_SET_OBJ_LOCAL_POS_TYPE.Y, self.fCurHeightCount)
		end

        if self.bSliding then
            local fPerc = UIHelper.GetProgressBarPercent(self.SliderHeight) / 100
            local fNewHeight = fPerc * self.fTotalHeightCount + self.fMinHeightCount
			if fNewHeight <= self.fMinHeightCount then
				fNewHeight = self.fMinHeightCount
			elseif fNewHeight >= self.fMaxHeightCount then
				fNewHeight = self.fMaxHeightCount
			end
			if self.fCurHeightCount ~= fNewHeight then
				self.fCurHeightCount = fNewHeight

				UIHelper.SetProgressBarPercent(self.ImgHeightFg, fPerc * 100)
				UIHelper.SetText(self.EditBoxHeight, math.floor(self.fCurHeightCount))
				HLBOp_SingleItemOp.SetObjLocalPos(HOMELAND_SET_OBJ_LOCAL_POS_TYPE.Y, self.fCurHeightCount)
			end
		end
    end)

	UIHelper.BindUIEvent(self.BtnHeightPlus, EventType.OnClick, function(btn)
        local fHeight = self.fCurHeightCount + self.fStepHeightCount
        self.fCurHeightCount = math.min(self.fMaxHeightCount, fHeight)
        self.fCurHeightCount = math.max(self.fMinHeightCount, self.fCurHeightCount)

        local fPerc = (self.fCurHeightCount - self.fMinHeightCount) / self.fTotalHeightCount * 100
        UIHelper.SetProgressBarPercent(self.SliderHeight, fPerc)
        UIHelper.SetProgressBarPercent(self.ImgHeightFg, fPerc)
		UIHelper.SetText(self.EditBoxHeight, math.floor(self.fCurHeightCount))
		HLBOp_SingleItemOp.SetObjLocalPos(HOMELAND_SET_OBJ_LOCAL_POS_TYPE.Y, self.fCurHeightCount)
    end)

    UIHelper.BindUIEvent(self.BtnHeightMinus, EventType.OnClick, function(btn)
        local fHeight = self.fCurHeightCount - self.fStepHeightCount
        self.fCurHeightCount = math.min(self.fMaxHeightCount, fHeight)
        self.fCurHeightCount = math.max(self.fMinHeightCount, self.fCurHeightCount)

        local fPerc = (self.fCurHeightCount - self.fMinHeightCount) / self.fTotalHeightCount * 100
        UIHelper.SetProgressBarPercent(self.SliderHeight, fPerc)
        UIHelper.SetProgressBarPercent(self.ImgHeightFg, fPerc)
		UIHelper.SetText(self.EditBoxHeight, math.floor(self.fCurHeightCount))
		HLBOp_SingleItemOp.SetObjLocalPos(HOMELAND_SET_OBJ_LOCAL_POS_TYPE.Y, self.fCurHeightCount)
    end)

	UIHelper.BindUIEvent(self.BtnHeightReset, EventType.OnClick, function(btn)
        self.fCurHeightCount = 0

        local fPerc = (self.fCurHeightCount - self.fMinHeightCount) / self.fTotalHeightCount * 100
        UIHelper.SetProgressBarPercent(self.SliderHeight, fPerc)
		UIHelper.SetProgressBarPercent(self.ImgHeightFg, fPerc)
		UIHelper.SetText(self.EditBoxHeight, math.floor(self.fCurHeightCount))
		HLBOp_SingleItemOp.SetObjLocalPos(HOMELAND_SET_OBJ_LOCAL_POS_TYPE.Y, self.fCurHeightCount)
    end)

	if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditBoxHeight, function(_editbox)
            local szHeight = UIHelper.GetText(self.EditBoxHeight)
			local fHeight = tonumber(szHeight)
            if fHeight then
				fHeight = fHeight + 0	-- 解决显示'-0'的情况
                self.fCurHeightCount = math.min(self.fMaxHeightCount, fHeight)
                self.fCurHeightCount = math.max(self.fMinHeightCount, self.fCurHeightCount)
			else
				TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_BULID_CHANGE_HEIGHT)
            end
            UIHelper.SetText(self.EditBoxHeight, self.fCurHeightCount)

            local fPerc = (self.fCurHeightCount - self.fMinHeightCount) / self.fTotalHeightCount * 100
            UIHelper.SetProgressBarPercent(self.SliderHeight, fPerc)
			UIHelper.SetProgressBarPercent(self.ImgHeightFg, fPerc)
			UIHelper.SetText(self.EditBoxHeight, math.floor(self.fCurHeightCount))
			HLBOp_SingleItemOp.SetObjLocalPos(HOMELAND_SET_OBJ_LOCAL_POS_TYPE.Y, self.fCurHeightCount)
		end)
    else
		UIHelper.SetEditBoxInputMode(self.EditBoxHeight, cc.EDITBOX_INPUT_MODE_NUMERIC)
        UIHelper.RegisterEditBoxReturn(self.EditBoxHeight, function(_editbox)
            local szHeight = UIHelper.GetText(self.EditBoxHeight)
			local fHeight = tonumber(szHeight)
            if fHeight then
				fHeight = fHeight + 0	-- 解决显示'-0'的情况
                self.fCurHeightCount = math.min(self.fMaxHeightCount, fHeight)
                self.fCurHeightCount = math.max(self.fMinHeightCount, self.fCurHeightCount)
            end
            UIHelper.SetText(self.EditBoxHeight, self.fCurHeightCount)

            local fPerc = (self.fCurHeightCount - self.fMinHeightCount) / self.fTotalHeightCount * 100
            UIHelper.SetProgressBarPercent(self.SliderHeight, fPerc)
			UIHelper.SetProgressBarPercent(self.ImgHeightFg, fPerc)
			UIHelper.SetText(self.EditBoxHeight, math.floor(self.fCurHeightCount))
			HLBOp_SingleItemOp.SetObjLocalPos(HOMELAND_SET_OBJ_LOCAL_POS_TYPE.Y, self.fCurHeightCount)
		end)
    end
    UIHelper.SetEditboxTextHorizontalAlign(self.EditBoxHeight, TextHAlignment.CENTER)

	for i, tog in ipairs(self.tbTogColor) do
		UIHelper.ToggleGroupAddToggle(self.ToggleGroupColor, tog)
	end
end

function UIHomelandBuildFurnitureEditPage:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
	Event.Reg(self, EventType.OnHomelandResetCameraMode, function ()
		self:UpdateCameraMode()
	end)

	Event.Reg(self, "LUA_HOMELAND_UPDATE_ITEMOP_INFO", function ()
		local tObjIDs = self.tObjIDs or {}
		if #tObjIDs > 1 then
			self:UpdateHeightInfo()
		else
			self:UpdateHeightInfo(tObjIDs[1])
		end
	end)

	Event.Reg(self, EventType.OnHomeLandBuildResponseKey, function (szKey, ...)
		if szKey == "R" then
			local bIsCtrlDown = ...
			if bIsCtrlDown then
				return
			end
			local tObjIDs = self.tObjIDs
			if tObjIDs[1] then
				local dwModelID = HLBOp_Amount.GetModelIDByObjID(tObjIDs[1])
				UIMgr.Open(VIEW_ID.PanelChangeJiMuSkin, dwModelID, #tObjIDs)
			end
		elseif szKey == "L" then
			local bIsCtrlDown = ...
			if bIsCtrlDown then
				return
			end
			self:LocateWareHouse()
		elseif tonumber(szKey) then
			local bIsCtrlDown = ...
			if bIsCtrlDown then
				return
			end
			-- 染色
			local nInputNum = tonumber(szKey)
			if nInputNum >= 1 and nInputNum <= 6 then
				self:ChangeColorByHotkey(nInputNum - 1)
			end
		end
	end)
end

function UIHomelandBuildFurnitureEditPage:InitView()
	UIHelper.SetVisible(self.LayoutItemOper, true)
	UIHelper.SetVisible(self.WidgetPaint, false)

	UIHelper.LayoutDoLayout(self.LayoutItemInfo)
	UIHelper.LayoutDoLayout(self.LayoutMainOper)

end

function UIHomelandBuildFurnitureEditPage:UpdateInfo()
    self.nNowMultiColorIndex = -1
    local tObjIDs = self.tObjIDs or {}
	local nLen = #tObjIDs

	if nLen == 0 then
		return
	end

	if nLen == 1 then
		HLBOp_Other.GetObjectInfo(tObjIDs[1])
		self:ShowSingleItemOperations(tObjIDs[1])
		self:UpdateHeightInfo(tObjIDs[1])
	else
		local aModelIDs = {}
		for i = 1, nLen do
			local dwObjID = tObjIDs[i]
			local dwModelID = HLBOp_Amount.GetModelIDByObjID(dwObjID)
			if not dwModelID then
				return
			end
			if not CheckIsInTable(aModelIDs, dwModelID) then
				table.insert(aModelIDs, dwModelID)
			end
		end

		self:ShowMultiItemOperations(tObjIDs, aModelIDs)
		self:UpdateHeightInfo()
	end

end

function UIHomelandBuildFurnitureEditPage:UpdateColorInfo()
	if table.is_empty(self.aColorInfos) then
		UIHelper.SetVisible(self.BtnPaint, false)
		return
	end

	UIHelper.SetVisible(self.BtnPaint, true)
	UIHelper.LayoutDoLayout(self.LayoutItemOper)
	UIHelper.LayoutDoLayout(self.LayoutItemInfo)
	UIHelper.LayoutDoLayout(self.LayoutMainOper)

	UIHelper.HideAllChildren(self.LayoutColor)
	for i, t in ipairs(self.aColorInfos) do
		local nColorIndex = t[1]
		local nR, nG, nB = t[2], t[3], t[4]

		local tog = self.tbTogColor[i]
		local img = self.tbImgColor[i]

		UIHelper.SetVisible(tog, true)
		UIHelper.SetColor(img, cc.c3b(nR, nG, nB))
		UIHelper.BindUIEvent(tog, EventType.OnClick, function ()
			if self.tObjIDs.bSingle then
				HLBOp_SingleItemOp.Dye(nColorIndex)
			else
				HLBOp_MultiItemOp.Dye(nColorIndex)
			end
		end)
	end

	UIHelper.LayoutDoLayout(self.LayoutColor)
end

function UIHomelandBuildFurnitureEditPage:ShowSingleItemOperations(dwObjID)
    local dwModelID = HLBOp_Amount.GetModelIDByObjID(dwObjID)
    local tbCurSelectedInfo = HomelandBuildData.GetCurSelectedInfo()
	self.aColorInfos = nil

    if not dwModelID and not tbCurSelectedInfo then
		UIHelper.SetVisible(self.LayoutItemInfo, false)
		return
	else
		UIHelper.SetVisible(self.LayoutItemInfo, true)
    end


	UIHelper.SetVisible(self.BtnFlip, false)
	UIHelper.SetVisible(self.BtnDeleteBase, false)
	UIHelper.SetVisible(self.TogMakeGroup, false)
	UIHelper.SetVisible(self.BtnLocate, true)
	UIHelper.SetVisible(self.BtnLocateWarehouse, true)
	UIHelper.SetVisible(self.BtnOutput, not HLBOp_Enter.IsDigitalBlueprint())

    if dwModelID then
        local bCanReplace = FurnitureData.IsReplaceable(dwModelID)
		UIHelper.SetVisible(self.BtnExchange, bCanReplace)

        self.aColorInfos = FurnitureData.GetFurnColorInfos(dwModelID)
		self:UpdateColorInfo()

		local tLine = FurnitureData.GetFurnInfoByModelID(dwModelID)
		if tLine then
			self:UpdateItemBaseInfo(tLine)

			if FurnitureData.IsCatgForMechanism(tLine.nCatg1Index, tLine.nCatg2Index) then
				UIHelper.SetVisible(self.BtnFlip, true)
			end

			if FurnitureData.IsCatgForBaseboard(tLine.nCatg1Index, tLine.nCatg2Index) then
				UIHelper.SetVisible(self.BtnDeleteBase, true)
			end
		end

		UIHelper.SetVisible(self.LayoutItemOper, true)
		UIHelper.LayoutDoLayout(self.LayoutItemOper)
		UIHelper.LayoutDoLayout(self.LayoutItemInfo)
		UIHelper.LayoutDoLayout(self.LayoutMainOper)
    elseif tbCurSelectedInfo then
        self:UpdateItemBaseInfo(tbCurSelectedInfo)
	end
end

function UIHomelandBuildFurnitureEditPage:ShowMultiItemOperations(aObjIDs, aModelIDs)
	--HLBOp_Select.SetOutLine(aObjIDs)
	UIHelper.SetVisible(self.TogMakeGroup, true)
	UIHelper.SetVisible(self.BtnLocate, false)
	UIHelper.SetVisible(self.BtnDeleteBase, false)
	UIHelper.SetVisible(self.BtnExchange, false)
	UIHelper.SetVisible(self.BtnPaint, false)
	UIHelper.SetVisible(self.BtnLocateWarehouse, false)
	UIHelper.SetVisible(self.BtnFlip, false)
	UIHelper.SetVisible(self.BtnOutput, not HLBOp_Enter.IsDigitalBlueprint())

	local tSelectObjs = HLBOp_Select.GetSelectInfo()
	local bCanDestroyGroup= HomelandBuildData.CanDestroyGroup(tSelectObjs)
	UIHelper.SetSelected(self.TogMakeGroup, bCanDestroyGroup)

	UIHelper.LayoutDoLayout(self.LayoutItemOper)
end

function UIHomelandBuildFurnitureEditPage:UpdateHeightInfo(dwObjID)
	if not dwObjID then
		UIHelper.SetVisible(self.WidgetHeightHandleNew, false)
		return
	end

	local tObjectInfo = HLBOp_Other.GetOneObjectInfo(dwObjID)
    if not tObjectInfo then
		UIHelper.SetVisible(self.WidgetHeightHandleNew, false)
        return
    end

	local dwModelID = tObjectInfo.dwModelID
    local fCurHeight = tObjectInfo.fYPos
    local tLine = FurnitureData.GetFurnInfoByModelID(dwModelID)
    local tRange = Homeland_GetRange(tLine.szHeightLimit)
    if not tRange then
		UIHelper.SetVisible(self.WidgetHeightHandleNew, false)
        return
    end

	UIHelper.SetVisible(self.WidgetHeightHandleNew, true)

	self.fCurHeightCount = fCurHeight
    self.fMinHeightCount = tRange[1]
    self.fMaxHeightCount = tRange[2]
    self.fTotalHeightCount = tRange[2] - tRange[1]
	self.fStepHeightCount = math.floor((self.fMaxHeightCount - self.fMinHeightCount) / 12)

    local fPerc = (self.fCurHeightCount - self.fMinHeightCount) / self.fTotalHeightCount * 100
    UIHelper.SetProgressBarPercent(self.SliderHeight, fPerc)
	UIHelper.SetProgressBarPercent(self.ImgHeightFg, fPerc)
	UIHelper.SetText(self.EditBoxHeight, math.floor(self.fCurHeightCount))
end

function UIHomelandBuildFurnitureEditPage:UpdateItemBaseInfo(tbInfo)
    local szNum = "MAX"
	local szPublic = ""

	local nMode = HLBOp_Main.GetBuildMode()
	if tbInfo.nFurnitureType == HS_FURNITURE_TYPE.APPLIQUE_BRUSH then
		szNum = g_tStrings.STR_HOMELAND_BUILDING_FLOOR_BRUSH
	elseif tbInfo.nFurnitureType == HS_FURNITURE_TYPE.FOLIAGE_BRUSH then
		szNum = g_tStrings.STR_HOMELAND_BUILDING_FLOWER_BRUSH
	elseif tbInfo.bShowNumberAsBrush then
		szNum = g_tStrings.STR_HOMELAND_BUILDING_FURNITURE_BRUSH
	elseif nMode ~= BUILD_MODE.TEST and tbInfo.tNumInfo then
		local tNumInfo = tbInfo.tNumInfo
		if nMode == BUILD_MODE.COMMUNITY or nMode == BUILD_MODE.PRIVATE then
			szNum = tostring(tNumInfo.nLeftAmount - tNumInfo.nWarehouseLeftAmount)
			if tNumInfo.nWarehouseLeftAmount > 0 then
				szPublic = ("+" .. tostring(tNumInfo.nWarehouseLeftAmount))
			end
		end
	end

    UIHelper.SetString(self.LabelItemName, UIHelper.GBKToUTF8(tbInfo.szName))
    -- UIHelper.SetString(self.LabelItemNum, szNum)
    UIHelper.SetString(self.LabelItemNum, "")

	UIHelper.SetVisible(self.LayoutItemOper, false)
	UIHelper.LayoutDoLayout(self.LayoutItemInfo)
	UIHelper.LayoutDoLayout(self.LayoutMainOper)
end

function UIHomelandBuildFurnitureEditPage:UpdateCameraMode()
	local szMode = string.format("镜头 - %s", HLBOp_Other.GetCameraModeDesc())
	UIHelper.SetString(self.LabelCameraModeName, szMode)
end

function UIHomelandBuildFurnitureEditPage:UpdateMultiChooseMode()
	local nLen = self.tObjIDs and #self.tObjIDs or 0
	UIHelper.SetVisible(self.BtnRestore, nLen > 0)

	if not self.bUIMultiChoose then
		UIHelper.SetVisible(self.BtnConfirm, true)
		UIHelper.SetVisible(self.BtnCancel, true)
		UIHelper.SetVisible(self.BtnReturn, false)
		UIHelper.SetVisible(self.WidgetItemInfo, true)
		UIHelper.SetVisible(self.TogMultiChooseMode, false)
		UIHelper.LayoutDoLayout(self.LayoutItemInfo)
		UIHelper.LayoutDoLayout(self.LayoutMainOper)
		return
	end
	UIHelper.SetVisible(self.BtnConfirm, nLen > 0)
	UIHelper.SetVisible(self.BtnCancel, nLen > 0)
	UIHelper.SetVisible(self.BtnReturn, nLen == 0)
	UIHelper.SetVisible(self.LayoutItemOper, nLen > 0)
	UIHelper.SetVisible(self.WidgetItemInfo, nLen == 1)
	UIHelper.SetVisible(self.TogMultiChooseMode, true)

	UIHelper.LayoutDoLayout(self.LayoutItemOper)
	UIHelper.LayoutDoLayout(self.LayoutItemInfo)
	UIHelper.LayoutDoLayout(self.LayoutMainOper)
end

function UIHomelandBuildFurnitureEditPage:UpdateMultiChooseTimer()
	if not Platform.IsWindows() then
		return
	end

	self.nMultiChooseTimerID = self.nMultiChooseTimerID or Timer.AddCycle(self, 0.1, function ()
		if UIHelper.GetVisible(self._rootNode) then
			UIHelper.SetSelected(self.TogMultiChooseMode, HomelandInput.IsMultiChooseMode(), false)
		end
	end)
end

function UIHomelandBuildFurnitureEditPage:IsSingleItemOp()
	local tSelectObjs = HLBOp_Select.GetSelectInfo()
	if #tSelectObjs == 1 then
		local dwModelID = HLBOp_Amount.GetModelIDByObjID(tSelectObjs[1])
		return true, #tSelectObjs, tSelectObjs[1], dwModelID
	elseif #tSelectObjs > 1 then
		local dwModelID = HLBOp_Amount.GetModelIDByObjID(tSelectObjs[1])
		return false, #tSelectObjs, tSelectObjs[1], dwModelID
	else
		return false, 0
	end
end

function UIHomelandBuildFurnitureEditPage:LocateWareHouse()
	local tObjIDs = self.tObjIDs
	if #tObjIDs >= 1 then
		local dwModelID = HLBOp_Amount.GetModelIDByObjID(tObjIDs[1])
		Event.Dispatch(EventType.OnGotoHomelandFurnitureListOneItem, dwModelID)

		HLBOp_Select.ClearSelect()
		HLBOp_Place.CancelPlace()

		HLBOp_Brush.CancelBrush()
		HLBOp_Bottom.CancelBottom()
		HLBOp_MultiItemOp.CancelPlace()
		HLBOp_CustomBrush.CancelCustomBrush()
		HLBOp_Blueprint.CancelMoveBlueprint()

		if self.bUIMultiChoose then
			UIHelper.SetSelected(self.TogMultiChooseMode, false)
			HomelandInput.ExitMultiChooseMode()
			Event.Dispatch(EventType.OnHomelandExitMultiChoose)
		end
	end
end

function UIHomelandBuildFurnitureEditPage:ChangeColorByHotkey(nColorIndex)
	if table.is_empty(self.aColorInfos) then
		return
	end
	UIHelper.SetVisible(self.LayoutItemOper, false)
	UIHelper.SetVisible(self.WidgetPaint, true)

	UIHelper.SetToggleGroupSelected(self.ToggleGroupColor, nColorIndex)
	UIHelper.LayoutDoLayout(self.LayoutItemInfo)

	if self.tObjIDs.bSingle then
		HLBOp_SingleItemOp.Dye(nColorIndex)
	else
		HLBOp_MultiItemOp.Dye(nColorIndex)
	end
end
return UIHomelandBuildFurnitureEditPage