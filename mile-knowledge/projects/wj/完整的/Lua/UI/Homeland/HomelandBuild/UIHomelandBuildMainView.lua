-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildMainView
-- Date: 2023-04-21 14:20:02
-- Desc: ?
-- ---------------------------------------------------------------------------------
-- 界面打开后不能操作镜头，以下是可以忽略的界面
IGNORE_VIEW_IDS = {
    VIEW_ID.PanelConstructionMain,
}
local UIHomelandBuildMainView = class("UIHomelandBuildMainView")

function UIHomelandBuildMainView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        --HomelandEventHandler.ApplySetCollectionData()
        HomelandData.SetIsHomelandEditing(true)
    end

    if not self.scriptFurnitureList then
        self.scriptFurnitureList = UIHelper.GetBindScript(self.WidgetWareHouse)
        self.scriptFurnitureList:OnEnter()
    end

    UIMgr.HideView(VIEW_ID.PanelMainCity)
    UIHelper.HideInteract()

    self:InitCurrency()
    self:UpdateInfo()
    self:InitInput()
end

function UIHomelandBuildMainView:InitInput()
    ShortcutInteractionData.SetEnableKeyBoard(false)
    UIHelper.AddPrefab(PREFAB_ID.WidgetConstructionJoystick, self.WidgetAnchorJoystick)
    HomelandInput.Bind(self.WidgetDraw)
    if HomelandBuildData.GetInputType() == HLB_INPUT_TYPE.MAK then
        HomelandBulidHotkey.Init()
        self:RegHotkey()
    end
end

function UIHomelandBuildMainView:OnExit()
    self.bInit = false

    UIMgr.ShowLayer(UILayer.Scene)
    UIMgr.ShowView(VIEW_ID.PanelMainCity)
    UIHelper.ShowInteract()

    HomelandData.SetIsHomelandEditing(false)
    ShortcutInteractionData.SetEnableKeyBoard(true)
    HomelandInput.UnBind()
    HomelandBulidHotkey.UnInit()
end

function UIHomelandBuildMainView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBack, EventType.OnClick, function ()
        self:OnClickQuit()
    end)

    UIHelper.BindUIEvent(self.BtnSubarea, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelZoneManagement)
    end)

    UIHelper.BindUIEvent(self.BtnOptions, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelConstructionOptions)
    end)

    UIHelper.BindUIEvent(self.BtnUndo, EventType.OnClick, function ()
        HLBOp_Step.Undo()
    end)

    UIHelper.BindUIEvent(self.BtnRedo, EventType.OnClick, function ()
        HLBOp_Step.Redo()
    end)

    UIHelper.BindUIEvent(self.BtnVersion, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelVersionRecall)
    end)

    UIHelper.BindUIEvent(self.BtnBluePrint, EventType.OnClick, function ()
        -- TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetConstructBluePrintTip, self.BtnBluePrint)
        UIMgr.Open(VIEW_ID.PanelBluePrintManagePop)
    end)

    UIHelper.BindUIEvent(self.BtnPlacedItemList, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelPlacedItemsList)
    end)

    UIHelper.BindUIEvent(self.BtnSave, EventType.OnClick, function ()
        if self.bInBulidCD then
            TipsHelper.ShowNormalTip("建造冷却中")
            return
        end

        if not HLBOp_Main.IsModified() then
            TipsHelper.ShowNormalTip("目前暂无修改，无需保存")
            return
        end

        HLBOp_Select.ClearSelect()
		HLBOp_Place.CancelPlace()
		HLBOp_Brush.CancelBrush()
		HLBOp_Bottom.CancelBottom()
		HLBOp_MultiItemOp.CancelPlace()
		HLBOp_CustomBrush.CancelCustomBrush()
		HLBOp_Blueprint.CancelMoveBlueprint()
		local nMode = HLBOp_Main.GetBuildMode()
		if nMode == BUILD_MODE.COMMUNITY or nMode == BUILD_MODE.PRIVATE then
			HLBOp_Save.DoGetMatchRateAndSave()
		elseif nMode == BUILD_MODE.DESIGN then
            UIHelper.ShowConfirm(g_tStrings.STR_HOMELAND_EXPORT_LAND_BLUEPRINT_CONFIRM, function ()
                HLBOp_Blueprint.ExportBlueprint(false)
            end)
		end
    end)

    UIHelper.BindUIEvent(self.BtnMultiSelect, EventType.OnClick, function ()
        self:EnterMultiChooseMode()
    end)

    UIHelper.BindUIEvent(self.BtnScore, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelHomeContestJoinPop)
    end)

    UIHelper.BindUIEvent(self.BtnChat, EventType.OnClick, function ()
        ChatHelper.Chat()
    end)

    UIHelper.BindUIEvent(self.BtnUpgrade, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelHomeUpgradePop)
    end)

    UIHelper.BindUIEvent(self.TogViewUI, EventType.OnClick, function ()
        if UIHelper.GetSelected(self.TogViewUI) then
            UIHelper.PlayAni(self, self.AniAll, "AniYinCangShow")
        else
            UIHelper.PlayAni(self, self.AniAll, "AniYinCangHide")
        end
    end)

    UIHelper.BindUIEvent(self.Btn360Shot, EventType.OnClick, function(btn)
        HLBOp_Other.ScreenShot360()
    end)

    UIHelper.SetTouchDownHideTips(self.TogConstructOper, false)
end

function UIHomelandBuildMainView:RegEvent()
    Event.Reg(self, "HOME_LAND_RESULT_CODE_INT", function()
        local nResultType = arg0
		if nResultType == HOMELAND_RESULT_CODE.APPLY_LAND_INFO then --获取地块属性信息
			self:UpdateInfo()
		elseif nResultType == HOMELAND_RESULT_CODE.APPLY_LEVEL_UP then --是否可以升级
            self:UpdateInfo()
		end
    end)

    Event.Reg(self, "SET_RENDER_SCENE", function (dwSceneID)
        if dwSceneID < 10000 then
            return
        end

        UIHelper.SetVisible(self.MiniScene, true)
        self.MiniScene:SetScene(dwSceneID)
        UIMgr.HideLayer(UILayer.Scene)
    end)

    Event.Reg(self, "LUA_HOMELAND_SELECT_CHANGE", function ()
        self:OnSelectedObj()
    end)

    Event.Reg(self, "LUA_HOMELAND_CREATE_CUSTOM_BRUSH", function ()
        local nMode = 1

        if HomelandCustomBrushData.tSettingInfo.nSettingType == HomelandCustomBrushData.SETTING_TYPE.SINGLE_FLOWER or
            HomelandCustomBrushData.tSettingInfo.nSettingType == HomelandCustomBrushData.SETTING_TYPE.FLOWER_PLAN or
            HomelandCustomBrushData.tSettingInfo.nSettingType == HomelandCustomBrushData.SETTING_TYPE.FLOWER_ERASER then

            nMode = 2
        elseif HomelandCustomBrushData.tSettingInfo.nSettingType == HomelandCustomBrushData.SETTING_TYPE.FLOOR or
            HomelandCustomBrushData.tSettingInfo.nSettingType == HomelandCustomBrushData.SETTING_TYPE.FLOOR_ERASER then

            nMode = 3
        end

        self:OnCreateBrush(nMode)
    end)

    Event.Reg(self, "LUA_HOMELAND_CANCEL_CUSTOM_BRUSH", function ()
        self:OnEndBrush()
    end)

    Event.Reg(self, "LUA_HOMELAND_CREATE_BRUSH", function ()
        self:OnCreateBrush()
    end)

    Event.Reg(self, "LUA_HOMELAND_END_BRUSH", function ()
        self:OnEndBrush()
    end)

    Event.Reg(self, "LUA_HOMELAND_CREATE_BOTTOM", function ()
        self:OnCreateBrush()
    end)

    Event.Reg(self, "LUA_HOMELAND_END_BOTTOM", function ()
        self:OnEndBrush()
    end)

    Event.Reg(self, "LUA_HOMELAND_START_LOAD_BLUEPRINT", function ()
        self:OnStartLoadBlueprint()
    end)

    Event.Reg(self, "LUA_HOMELAND_END_LOAD_BLUEPRINT", function ()
        self:OnEndLoadBlueprint()
        Event.Dispatch("LUA_HOMELAND_ENTER_MULTI_CHOOSE_MODE")
    end)

    Event.Reg(self, "LUA_HOMELAND_LAYERS_UPDATE", function (nBottomCount)
        if not self.scriptBottomCountTip then
            self.scriptBottomCountTip = UIHelper.AddPrefab(PREFAB_ID.WidgetBasementLevel, self._rootNode)
        end

        self.scriptBottomCountTip:OnEnter(nBottomCount)
    end)

    Event.Reg(self, "LUA_HOMELAND_ENTER_MULTI_CHOOSE_MODE", function ()
        self:EnterMultiChooseMode()
    end)

    Event.Reg(self, "UPDATE_ARCHITECTURE", function ()
        self:UpdateCurrency()
    end)

    -- Event.Reg(self, "SYNC_COIN", function ()
    --     self:UpdateCurrency()
    -- end)

    -- Event.Reg(self, "MONEY_UPDATE", function ()
    --     self:UpdateCurrency()
    -- end)

    Event.Reg(self, EventType.OnHomelandBuildTypeTog, function(bTogSelected)
        UIHelper.SetVisible(self.BtnMultiSelect, not bTogSelected)
    end)

    Event.Reg(self, EventType.OnHomelandAddBuildCD, function()
        self:CreatBuildCD()
    end)

    Event.Reg(self, EventType.OnHomelandExitMultiChoose, function()
        self:ExitMultiChooseMode()
    end)

    Event.Reg(self, EventType.OnSceneTouchBegan, function (x, y)
        UIHelper.SetSelected(self.TogConstructOper, false)

        self.m_bIsItemLButtonHold = true
		HLBOp_Brush.StartBrush()
		HLBOp_Bottom.StartBottom()
		HLBOp_CustomBrush.StartCustomBrush()

        self.bTouchMove = false
        self.nStartTouchX, self.nStartTouchY = x, y
    end)

    Event.Reg(self, EventType.OnSceneTouchMoved, function (x, y)
        if HLBOp_Brush.IsMoveBrush() or HLBOp_Blueprint.IsMoveBlueprint() then
            HLBOp_Main.SetMoveObjEnabled(true)
        end

        if self.nStartTouchX and self.nStartTouchY and (math.abs(self.nStartTouchX - x) > 1 or math.abs(self.nStartTouchY - y) > 1) then
            self.bTouchMove = true
        end
    end)

    Event.Reg(self, EventType.OnSceneTouchEnded, function ()
        if self.m_bIsItemLButtonHold then
            self.m_bIsItemLButtonHold = false
            HLBOp_Bottom.EndBottom()
            HLBOp_Brush.EndBrush()
            HLBOp_CustomBrush.EndCustomBrush()
        end

        local bFlag = HLBOp_Check.CheckNoHint() and not HomelandInput.IsMultiChooseMode() and not self.bTouchMove
        if bFlag then
            local fnAction = function()
                HLBOp_Select.SelectScreen()
            end

            if HomelandBuildData.GetInputType() == HLB_INPUT_TYPE.MAK then
                if HomelandBulidHotkey.GetCtrlDown() then
                    Event.Dispatch("LUA_HOMELAND_ENTER_MULTI_CHOOSE_MODE")
                end
            end

            if self.bUIMultiChoose then
                HLBOp_Select.SelectScreenInCtrl()
                return
            end
            local tSelectObjs = HLBOp_Select.GetSelectInfo()
            if #tSelectObjs > 1 then
                Timer.Add(self, 0.1, fnAction)
            else
                fnAction()
            end
        end

        HLBOp_Main.SetMoveObjEnabled(false)
    end)

    Event.Reg(self, EventType.OnSceneTouchCancelled, function ()
        if self.m_bIsItemLButtonHold then
            self.m_bIsItemLButtonHold = false
            HLBOp_Bottom.EndBottom()
            HLBOp_Brush.EndBrush()
            HLBOp_CustomBrush.EndCustomBrush()
        end

        local bFlag = HLBOp_Check.CheckNoHint() and not HomelandInput.IsMultiChooseMode() and not self.bTouchMove
        if bFlag then
            local fnAction = function()
                HLBOp_Select.SelectScreen()
            end
            if self.bUIMultiChoose then
                HLBOp_Select.SelectScreenInCtrl()
                return
            end
            local tSelectObjs = HLBOp_Select.GetSelectInfo()
            if #tSelectObjs > 1 then
                Timer.Add(self, 0.1, fnAction)
            else
                fnAction()
            end
        end

        HLBOp_Main.SetMoveObjEnabled(false)
    end)

    Event.Reg(self, "LUA_HOMELAND_UPDATE_LANDDATA", function ()
		self:UpdateBaseInfo()
    end)

    Event.Reg(self, EventType.OnShowPageBottomBar, function(callback)
        UIHelper.PlayAni(self, self.AniAll, "AniRightShow")
    end)

    Event.Reg(self, EventType.OnHidePageBottomBar, function(callback)
        UIHelper.PlayAni(self, self.AniAll, "AniRightHide")
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        UIHelper.SetSelected(self.TogConstructOper, false)
    end)

    -- Event.Reg(self, "HOME_LAND_RESULT_CODE", function ()
    --     local nRetCode = arg0
    --     if nRetCode == HOMELAND_RESULT_CODE.TASK_BUILDING_SUCCEED then
	-- 	    self:UpdateBaseInfo()
    --     end
    -- end)
end

function UIHomelandBuildMainView:UpdateInfo()
    local tConfig = Homeland_GetModeConfig(HLBOp_Main.GetBuildMode())
    UIHelper.SetVisible(self.BtnSubarea, tConfig.bPrivate)
    UIHelper.SetString(self.LabelLevel, HLBOp_Enter.GetLevel().."级")

    self:UpdateBaseInfo()
end

function UIHomelandBuildMainView:UpdateBaseInfo()
    local hlMgr = GetHomelandMgr()
    -- local nMapID, nCopyIndex, nLandIndex = HomelandBuildData.GetMapInfo()
    -- self.tbLandInfo = hlMgr.GetLandInfo(nMapID, nCopyIndex, nLandIndex)
    -- if not self.tbLandInfo then
	-- 	return
	-- end

    local tData = {}
    tData.nScore = hlMgr.BuildGetRecordInfo()
    tData.nTotalArch = hlMgr.BuildGetArchitectureCost()

    UIHelper.SetRichText(self.RichTextZhuangXiuNum, tostring(tData.nScore))

    UIHelper.SetString(self.LabelValueNum, tData.nTotalArch)
    UIHelper.SetString(self.LabelLevelNum, tData.nScore)

    UIHelper.LayoutDoLayout(self.LayoutTotalValue)
end

function UIHomelandBuildMainView:InitCurrency()
    UIHelper.AddPrefab(PREFAB_ID.WidgetCurrency, self.LayoutCurrency)
    self.currencyScript = UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.LayoutCurrency)
    self.currencyScript:SetCurrencyType(CurrencyType.Architecture)
    self:UpdateCurrency()
    -- UIHelper.SetAnchorPoint(self.currencyScript._rootNode, 0, 0.5)
end

function UIHomelandBuildMainView:UpdateCurrency()
	local player = PlayerData.GetClientPlayer()
    local nArch = 0
    local nCoin = 0
    local tMoney = {nGold = 0}
    if player then
        nArch = player.nArchitecture or 0
        nCoin = player.nCoin or 0
        tMoney = player.GetMoney() or {nGold = 0}
    end
    self.currencyScript:SetLableCount(nArch)
    UIHelper.LayoutDoLayout(self.LayoutCurrency)
end

function UIHomelandBuildMainView:UpdateDecorate()
    local hlMgr = GetHomelandMgr()
    local nMapID, nCopyIndex, nLandIndex = HomelandBuildData.GetMapInfo()
    self.tbLandInfo = hlMgr.GetLandInfo(nMapID, nCopyIndex, nLandIndex)
    if not self.tbLandInfo then
		return
	end

    UIHelper.SetString(self.LabelLevel, HLBOp_Enter.GetLevel())
    UIHelper.SetRichText(self.RichTextZhuangXiuNum, tostring(self.tbLandInfo.dwRecordInfo))
end

function UIHomelandBuildMainView:OnClickQuit(bLink)
    if HLBOp_Save.IsInDemolishSaving() then
        TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_BUILDING_IN_SAVE)
        return
    end

    local tStrTable = {
		[1] = g_tStrings.STR_HOMELAND_QUIT_BUILDING_IN_DESIGN_YARD,
		[2] = g_tStrings.STR_HOMELAND_QUIT_BUILDING_IN_DESIGN_YARD_OPTION_1,
		[3] = g_tStrings.STR_HOMELAND_QUIT_BUILDING_IN_DESIGN_YARD_OPTION_2,
		[4] = g_tStrings.STR_HOMELAND_QUIT_BUILDING_SURE_1,
		[5] = g_tStrings.STR_HOMELAND_SAVE_AND_QUIT_BUILDING,
		[6] = g_tStrings.STR_HOMELAND_NO_SAVE_AND_QUIT_BUILDING,
		[7] = g_tStrings.STR_HOMELAND_QUIT_BUILDING_SURE_2,
		[8] = g_tStrings.STR_HOMELAND_QUIT_BUILDING,
	}
	if bLink then
		tStrTable = {
			[1] = g_tStrings.STR_HOMELAND_QUIT_BUILDING_IN_DESIGN_YARD_BY_LINK,
			[2] = g_tStrings.STR_HOMELAND_QUIT_BUILDING_IN_DESIGN_YARD_OPTION_1_BY_LINK,
			[3] = g_tStrings.STR_HOMELAND_QUIT_BUILDING_IN_DESIGN_YARD_OPTION_2_BY_LINK,
			[4] = g_tStrings.STR_HOMELAND_QUIT_BUILDING_SURE_1_BY_LINK,
			[5] = g_tStrings.STR_HOMELAND_SAVE_AND_QUIT_BUILDING_BY_LINK,
			[6] = g_tStrings.STR_HOMELAND_NO_SAVE_AND_QUIT_BUILDING_BY_LINK,
			[7] = g_tStrings.STR_HOMELAND_QUIT_BUILDING_SURE_2_BY_LINK,
			[8] = g_tStrings.STR_HOMELAND_QUIT_BUILDING_BY_LINK,
		}
	else
		HLBOp_Exit.SetActionBeforeExit(nil)
	end

    local fnCancel = function ()
        HLBOp_Exit.SetActionBeforeExit(nil)
    end

    local nMode = HLBOp_Main.GetBuildMode()
	if nMode == BUILD_MODE.DESIGN then
        local scriptDialog = UIHelper.ShowConfirm(tStrTable[1],
            function ()
                HLBOp_Exit.DoExit()
            end, fnCancel, false)

        scriptDialog:ShowOtherButton()
        scriptDialog:SetButtonContent("Confirm", tStrTable[3])
        scriptDialog:SetButtonContent("Other", tStrTable[2])

        scriptDialog:SetOtherButtonClickedCallback(function ()
            HLBOp_Blueprint.ExportBlueprint(false, nil, true)
        end)

	elseif (nMode == BUILD_MODE.COMMUNITY or nMode == BUILD_MODE.PRIVATE) and HLBOp_Main.IsModified() then
        local scriptDialog = UIHelper.ShowConfirm(tStrTable[4],
            function ()
                HLBOp_Save.DoGetMatchRateAndSaveAndQuit()
            end, fnCancel, false)

        scriptDialog:ShowOtherButton()
        scriptDialog:SetButtonContent("Confirm", tStrTable[5])
        scriptDialog:SetButtonContent("Other", tStrTable[6])

        scriptDialog:SetOtherButtonClickedCallback(function ()
            HLBOp_Exit.RemoveBakFile()
            HLBOp_Exit.DoExit()
        end)
	else
        local scriptDialog = UIHelper.ShowConfirm(tStrTable[7],
            function ()
                HLBOp_Exit.DoExit()
            end, fnCancel, false)

        scriptDialog:SetButtonContent("Confirm", tStrTable[8])
	end

end

function UIHomelandBuildMainView:ConfirmQuitAndDoAction(fnAction)
    HLBOp_Exit.SetActionBeforeExit(fnAction)
	self:OnClickQuit(true)
end

function UIHomelandBuildMainView:OnShowPlaceItemInfoView(bShow, tObjIDs)
    if bShow then
        local nCount = #(tObjIDs or {})
        UIHelper.SetVisible(self.WidgetAniRightTop, false)
        UIHelper.SetVisible(self.WidgetWareHouse, false)
        UIHelper.SetVisible(self.WidgetPlaceItem, true)
        UIHelper.SetVisible(self.WidgetBrushItem, false)
        UIHelper.SetVisible(self.WidgetBlueprintItem, false)
        UIHelper.SetVisible(self.scriptObjTip._rootNode, nCount == 1 or self.bUIMultiChoose)

        if not self.scriptEdit then
            self.scriptEdit = UIHelper.GetBindScript(self.WidgetPlaceItem)
        end

        self.scriptEdit:OnEnter(tObjIDs, self.bUIMultiChoose)
        self.scriptObjTip:OnEnter(tObjIDs, self.bUIMultiChoose)
    else
        UIHelper.SetVisible(self.WidgetAniRightTop, true)
        UIHelper.SetVisible(self.WidgetWareHouse, true)
        UIHelper.SetVisible(self.WidgetPlaceItem, false)
        UIHelper.SetVisible(self.WidgetBrushItem, false)
        UIHelper.SetVisible(self.WidgetBlueprintItem, false)
        UIHelper.SetVisible(self.scriptObjTip._rootNode, false)
    end
end

function UIHomelandBuildMainView:OnSelectedObj()
    if not self.scriptObjTip then
        self.scriptObjTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemEditHandle, self.WidgetAniMiddle)
        UIHelper.SetVisible(self.scriptObjTip._rootNode, false)
    end

    if self.nDelayShowPlaceItemInfoViewTimerID then
        Timer.DelTimer(self, self.nDelayShowPlaceItemInfoViewTimerID)
        self.nDelayShowPlaceItemInfoViewTimerID = nil
    end

    local tObjIDs = HLBOp_Select.GetSelectInfo()
    local nCount = #tObjIDs
    if nCount < 1 and not HLBOp_Blueprint.IsMoveBlueprint() then
        if self.bUIMultiChoose then
            self.scriptEdit:OnEnter(tObjIDs, self.bUIMultiChoose)
            UIHelper.SetVisible(self.scriptObjTip._rootNode, false)
            return
        end

        self.nDelayShowPlaceItemInfoViewTimerID = Timer.Add(self, 0.1, function ()
            self:OnShowPlaceItemInfoView(false)
        end)
    else
        self.nDelayShowPlaceItemInfoViewTimerID = Timer.Add(self, 0.1, function ()
            self:OnShowPlaceItemInfoView(true, tObjIDs)
        end)
    end
end

function UIHomelandBuildMainView:OnCreateBrush(nMode)
    if self.nDelayShowPlaceItemInfoViewTimerID then
        Timer.DelTimer(self, self.nDelayShowPlaceItemInfoViewTimerID)
        self.nDelayShowPlaceItemInfoViewTimerID = nil
    end

    UIHelper.SetVisible(self.WidgetAniRightTop, false)
    UIHelper.SetVisible(self.WidgetWareHouse, false)
    UIHelper.SetVisible(self.WidgetPlaceItem, false)
    UIHelper.SetVisible(self.WidgetBrushItem, true)
    UIHelper.SetVisible(self.WidgetBlueprintItem, false)
    HomelandInput.SetTouchEnabled(false)

    if not self.scriptBrush then
        self.scriptBrush = UIHelper.GetBindScript(self.WidgetBrushItem)
    end

    self.scriptBrush:OnEnter(nMode)
end

function UIHomelandBuildMainView:OnEndBrush()
    if self.nDelayShowPlaceItemInfoViewTimerID then
        Timer.DelTimer(self, self.nDelayShowPlaceItemInfoViewTimerID)
        self.nDelayShowPlaceItemInfoViewTimerID = nil
    end

    UIHelper.SetVisible(self.WidgetAniRightTop, true)
    UIHelper.SetVisible(self.WidgetWareHouse, true)
    UIHelper.SetVisible(self.WidgetPlaceItem, false)
    UIHelper.SetVisible(self.WidgetBrushItem, false)
    UIHelper.SetVisible(self.WidgetBlueprintItem, false)
    HomelandInput.SetTouchEnabled(true)
end

function UIHomelandBuildMainView:OnStartLoadBlueprint()
    if self.nDelayShowPlaceItemInfoViewTimerID then
        Timer.DelTimer(self, self.nDelayShowPlaceItemInfoViewTimerID)
        self.nDelayShowPlaceItemInfoViewTimerID = nil
    end

    UIHelper.SetVisible(self.WidgetAniRightTop, false)
    UIHelper.SetVisible(self.WidgetWareHouse, false)
    UIHelper.SetVisible(self.WidgetPlaceItem, false)
    UIHelper.SetVisible(self.WidgetBrushItem, false)
    UIHelper.SetVisible(self.WidgetBlueprintItem, true)

    if not self.scriptBlueprint then
        self.scriptBlueprint = UIHelper.GetBindScript(self.WidgetBlueprintItem)
    end

    self.scriptBlueprint:OnEnter()
end

function UIHomelandBuildMainView:OnEndLoadBlueprint()
    if self.nDelayShowPlaceItemInfoViewTimerID then
        Timer.DelTimer(self, self.nDelayShowPlaceItemInfoViewTimerID)
        self.nDelayShowPlaceItemInfoViewTimerID = nil
    end

    UIHelper.SetVisible(self.WidgetAniRightTop, true)
    UIHelper.SetVisible(self.WidgetWareHouse, true)
    UIHelper.SetVisible(self.WidgetPlaceItem, false)
    UIHelper.SetVisible(self.WidgetBrushItem, false)
    UIHelper.SetVisible(self.WidgetBlueprintItem, false)
end

function UIHomelandBuildMainView:EnterMultiChooseMode()
    self.bUIMultiChoose = true

    if self.nDelayShowPlaceItemInfoViewTimerID then
        Timer.DelTimer(self, self.nDelayShowPlaceItemInfoViewTimerID)
        self.nDelayShowPlaceItemInfoViewTimerID = nil
    end

    UIHelper.SetVisible(self.WidgetWareHouse, false)
    UIHelper.SetVisible(self.WidgetPlaceItem, true)

    if not self.scriptEdit then
        self.scriptEdit = UIHelper.GetBindScript(self.WidgetPlaceItem)
    end

    self.scriptEdit:OnEnter(nil, true)

    Event.Dispatch(EventType.OnHomelandEnterMultiChoose)
end

function UIHomelandBuildMainView:CreatBuildCD()
    local nCDTime = HLBOp_Save.GetReEnterCD()

    UIHelper.SetVisible(self.WidgetConstructCD, true)
    UIHelper.SetString(self.LabelConstructCD, "冷却"..tostring(nCDTime).."秒")
    self.nBulidCDTimerID = self.nBulidCDTimerID or Timer.AddCycle(self, 1, function ()
        self.bInBulidCD = true
        nCDTime = nCDTime - 1
        UIHelper.SetString(self.LabelConstructCD, "冷却"..tostring(nCDTime).."秒")
        if nCDTime < 0 then
            nCDTime = -1
            self.bInBulidCD = false
            UIHelper.SetVisible(self.WidgetConstructCD, false)
            Timer.DelTimer(self, self.nBulidCDTimerID)
            self.nBulidCDTimerID = nil
        end
    end)
end

function UIHomelandBuildMainView:ExitMultiChooseMode()
    self.bUIMultiChoose = false
    HomelandInput.SetTouchEnabled(true)
    self.scriptEdit:OnEnter({}, true)
    self.scriptObjTip:OnEnter({}, self.bUIMultiChoose)

    if self.nDelayShowPlaceItemInfoViewTimerID then
        Timer.DelTimer(self, self.nDelayShowPlaceItemInfoViewTimerID)
        self.nDelayShowPlaceItemInfoViewTimerID = nil
    end

    UIHelper.SetVisible(self.WidgetWareHouse, true)
    UIHelper.SetVisible(self.WidgetPlaceItem, false)
end

function UIHomelandBuildMainView:RegHotkey()
    Event.Reg(self, EventType.OnHomeLandBuildResponseKey, function (szKey, ...)
        if szKey == "U" then
            local bCtrlDown = ...
            if not bCtrlDown then
                return
            end
            if UIHelper.GetSelected(self.TogViewUI) then
                UIHelper.PlayAni(self, self.AniAll, "AniYinCangHide")
                UIHelper.SetSelected(self.TogViewUI, false)
            else
                UIHelper.PlayAni(self, self.AniAll, "AniYinCangShow")
                UIHelper.SetSelected(self.TogViewUI, true)
            end
        elseif szKey == "S" then
            local bCtrlDown = ...
            if not bCtrlDown then
                return
            end
            local nPageLen = UIMgr.GetLayerStackLength(UILayer.Page, IGNORE_VIEW_IDS)
            local nPopLen = UIMgr.GetLayerStackLength(UILayer.Popup)
            local nMsgBoxLen = UIMgr.GetLayerStackLength(UILayer.MessageBox)
            if nPageLen <= 0 and nPopLen <= 0 and nMsgBoxLen <= 0 then
                self:Save()
            end
        end
    end)
end

function UIHomelandBuildMainView:Save()
    if self.bInBulidCD then
        TipsHelper.ShowNormalTip("建造冷却中")
        return
    end

    if not HLBOp_Main.IsModified() then
        TipsHelper.ShowNormalTip("目前暂无修改，无需保存")
        return
    end

    HLBOp_Select.ClearSelect()
    HLBOp_Place.CancelPlace()
    HLBOp_Brush.CancelBrush()
    HLBOp_Bottom.CancelBottom()
    HLBOp_MultiItemOp.CancelPlace()
    HLBOp_CustomBrush.CancelCustomBrush()
    HLBOp_Blueprint.CancelMoveBlueprint()
    local nMode = HLBOp_Main.GetBuildMode()
    if nMode == BUILD_MODE.COMMUNITY or nMode == BUILD_MODE.PRIVATE then
        HLBOp_Save.DoGetMatchRateAndSave()
    elseif nMode == BUILD_MODE.DESIGN then
        UIHelper.ShowConfirm(g_tStrings.STR_HOMELAND_EXPORT_LAND_BLUEPRINT_CONFIRM, function ()
            HLBOp_Blueprint.ExportBlueprint(false)
        end)
    end
end

return UIHomelandBuildMainView