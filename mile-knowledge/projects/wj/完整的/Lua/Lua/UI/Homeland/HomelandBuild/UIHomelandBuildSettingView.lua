-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildSettingView
-- Date: 2023-05-24 15:05:05
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildSettingView = class("UIHomelandBuildSettingView")

local TogOperationIndex2Key = {
    "bShowGrid",
    "bGridAlignEnabled",
    "bShowBaseboards",
    "bEnableMultiSelectBasement",
}

local tbCameraSpeedParams = {
    {
        szFormat = "庭院镜头灵敏度：%d",
        nMinValue = BUILD_SETTING.CAM_MOVE_SPEED_OUTDOORS_MIN,
        nMaxValue = BUILD_SETTING.CAM_MOVE_SPEED_OUTDOORS_MAX,
    },
    {
        szFormat = "室内镜头灵敏度：%d",
        nMinValue = BUILD_SETTING.CAM_MOVE_SPEED_INDOORS_MIN,
        nMaxValue = BUILD_SETTING.CAM_MOVE_SPEED_INDOORS_MAX,
    }
}

function UIHomelandBuildSettingView:OnEnter()
    self.nCurWeather = HomelandBuildData.GetWeather(1)
    self.nCurTime = HomelandBuildData.GetWeather(2)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end


    self:UpdateInfo()

    Timer.Add(self, 1, function ()
        HLBOp_Save.DoGetSDKFileLimit()
    end)
end

function UIHomelandBuildSettingView:OnExit()
    self.bInit = false
end

function UIHomelandBuildSettingView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function ()
        g_HomelandBuildingData = Lib.copyTab(g_HomelandBuildingDefaultData)
        if HLBOp_Camera.IsCameraIndoorsMode() then
            HLBOp_Camera.SwitchIndoorsMode()
        end

        HLBOp_Other.SetGrid(g_HomelandBuildingData.bShowGrid)
        HLBOp_Other.SetGridAlignment(g_HomelandBuildingData.bGridAlignEnabled)
        HLBOp_Other.SetBaseboard(g_HomelandBuildingData.bShowBaseboards)
        HLBOp_Other.SetMultiSelectBasement(g_HomelandBuildingData.bEnableMultiSelectBasement)


        self.nCurWeather = 1
        self.nCurTime = 1
        HomelandBuildData.SetWeather(self.nCurWeather, self.nCurTime)
        UIHelper.SetToggleGroupSelected(self.TogGroupWeather, self.nCurWeather - 1)
        UIHelper.SetToggleGroupSelected(self.TogGroupTime, self.nCurTime - 1)

        self:UpdateInfo()

        TipsHelper.ShowNormalTip("已恢复默认设置")
    end)

    UIHelper.BindUIEvent(self.BtnPlacedItems, EventType.OnClick, function ()
        UIMgr.Close(self)
        UIMgr.Open(VIEW_ID.PanelPlacedItemsList)
    end)

    UIHelper.BindUIEvent(self.BtnRuleCameraMode, EventType.OnClick, function(btn)
        TipsHelper.ShowTextTipsWithRuleID(self.BtnRuleCameraMode, TipsLayoutDir.RIGHT_CENTER, 29)
    end)

    UIHelper.BindUIEvent(self.BtnRuleOperations, EventType.OnClick, function(btn)
        TipsHelper.ShowTextTipsWithRuleID(self.BtnRuleOperations, TipsLayoutDir.RIGHT_CENTER, 30)
    end)

    UIHelper.BindUIEvent(self.TogCameraMode, EventType.OnClick, function ()
        HLBOp_Camera.SwitchIndoorsMode()
		if HLBOp_Camera.IsCameraIndoorsMode() then
			TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_SWITCHED_TO_CAMERA_INDOORS)
		else
			TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_SWITCHED_TO_CAMERA_OUTDOORS)
		end
    end)

    UIHelper.BindUIEvent(self.BtnFlipBase, EventType.OnClick, function ()
        HLBOp_Other.TurnBase()
    end)

    UIHelper.BindUIEvent(self.TogBrushType, EventType.OnClick, function ()
        if HomelandEventHandler.GetGrasseEffectFurniture() == 1 then
			HomelandEventHandler.SetGrasseEffectFurniture(0)
		else
			HomelandEventHandler.SetGrasseEffectFurniture(1)
		end
    end)

    for i, btn in ipairs(self.tbBtnCameraSpeedAdd) do
        UIHelper.BindUIEvent(btn, EventType.OnClick, function ()
            local tbInfo = tbCameraSpeedParams[i]
            if i == 1 then
                g_HomelandBuildingData.nCamMoveSpeedOutdoors = math.min(g_HomelandBuildingData.nCamMoveSpeedOutdoors + 1, tbInfo.nMaxValue)
            else
                g_HomelandBuildingData.nCamMoveSpeedIndoors = math.min(g_HomelandBuildingData.nCamMoveSpeedIndoors + 1, tbInfo.nMaxValue)
            end
            self:UpdateCameraInfo()
        end)
    end

    for i, btn in ipairs(self.tbBtnCameraSpeedSub) do
        UIHelper.BindUIEvent(btn, EventType.OnClick, function ()
            local tbInfo = tbCameraSpeedParams[i]
            if i == 1 then
                g_HomelandBuildingData.nCamMoveSpeedOutdoors = math.max(g_HomelandBuildingData.nCamMoveSpeedOutdoors - 1, tbInfo.nMinValue)
            else
                g_HomelandBuildingData.nCamMoveSpeedIndoors = math.max(g_HomelandBuildingData.nCamMoveSpeedIndoors - 1, tbInfo.nMinValue)
            end
            self:UpdateCameraInfo()
        end)
    end

    for i, slider in ipairs(self.tbSliderCameraSpeed) do
        UIHelper.BindUIEvent(slider, EventType.OnChangeSliderPercent, function(SliderEventType, nSliderEvent)
            if nSliderEvent == ccui.SliderEventType.slideBallDown then
                self.bSliding = true
            elseif nSliderEvent == ccui.SliderEventType.slideBallUp then
                self.bSliding = false
                self:UpdateCameraInfo()
            end

            local tbInfo = tbCameraSpeedParams[i]
            if self.bSliding then
                local fPerc = UIHelper.GetProgressBarPercent(slider) / 100
                local nValue = math.floor(fPerc * (tbInfo.nMaxValue - tbInfo.nMinValue) + tbInfo.nMinValue)

                if i == 1 then
                    g_HomelandBuildingData.nCamMoveSpeedOutdoors = nValue
                else
                    g_HomelandBuildingData.nCamMoveSpeedIndoors = nValue
                end
                UIHelper.SetString(self.tbLabelCameraSpeed[i], nValue)
                UIHelper.SetProgressBarPercent(self.tbProgressBarCameraSpeed[i], fPerc * 100)
            end
        end)
    end

    for i, tog in ipairs(self.tbTogWeather) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function ()
            self.nCurWeather = i
            HomelandBuildData.SetWeather(self.nCurWeather, self.nCurTime)
            HLBOp_Other.SwitchWeather(self.nCurTime, self.nCurWeather)
        end)
        UIHelper.ToggleGroupAddToggle(self.TogGroupWeather, tog)
    end
    UIHelper.SetToggleGroupSelected(self.TogGroupWeather, self.nCurWeather - 1)

    for i, tog in ipairs(self.tbTogTime) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function ()
            self.nCurTime = i
            HomelandBuildData.SetWeather(self.nCurWeather, self.nCurTime)
            HLBOp_Other.SwitchWeather(self.nCurTime, self.nCurWeather)
        end)
        UIHelper.ToggleGroupAddToggle(self.TogGroupTime, tog)
    end
    UIHelper.SetToggleGroupSelected(self.TogGroupTime, self.nCurTime - 1)

    for i, tog in ipairs(self.tbTogOperation) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function ()
            local bSelected = UIHelper.GetSelected(tog)
            local szKey = TogOperationIndex2Key[i]
            g_HomelandBuildingData[szKey] = bSelected
            if szKey == "bShowGrid" then
                HLBOp_Other.SetGrid(g_HomelandBuildingData.bShowGrid)
            elseif szKey == "bGridAlignEnabled" then
                if g_HomelandBuildingData.bGridAlignEnabled then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_SWITCHED_TO_GRID_ALIGNMENT)
                else
                    TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_SWITCHED_TO_FREE_PLACEMENT)
                end
		        HLBOp_Other.SetGridAlignment(g_HomelandBuildingData.bGridAlignEnabled)
            elseif szKey == "bShowBaseboards" then
                HLBOp_Other.SetBaseboard(g_HomelandBuildingData.bShowBaseboards)
            elseif szKey == "bEnableMultiSelectBasement" then
                if g_HomelandBuildingData.bEnableMultiSelectBasement then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_SWITCHED_TO_ALLOWING_MULTI_SELECT_BASEMENT)
                else
                    TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_SWITCHED_TO_FORBIDDING_MULTI_SELECT_BASEMENT)
                end
                HLBOp_Other.SetMultiSelectBasement(g_HomelandBuildingData.bEnableMultiSelectBasement)
            end
        end)
    end

    local dwMapID = HomelandBuildData.GetMapInfo()
    -- UIHelper.SetVisible(self.WidgetWeatherTime, not HomelandData.IsPrivateHome(dwMapID))
    UIHelper.SetVisible(self.WidgetWeatherTime, false)
end

function UIHomelandBuildSettingView:RegEvent()
    Event.Reg(self, "LUA_HOMELAND_UPDATE_FILE_LIMIT", function()
        self:UpdateSaveUsageInfo()
    end)
end

function UIHomelandBuildSettingView:UpdateInfo()
    self:UpdateSaveUsageInfo()
    self:UpdateItemListInfo()
    self:UpdateTogOperation()
    self:UpdateCameraInfo()
    self:UpdateFlowerBrushInfo()

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewMessageContent)
end

function UIHomelandBuildSettingView:UpdateSaveUsageInfo()
    local tbPerc = {
        HomelandBuildData.GetSDKFileLimitPercentage(),
        HomelandBuildData.GetLandObjectPercentage(),
        HomelandBuildData.GetSaveFurniturePercentage()
    }

    for i, label in ipairs(self.tbLabelSaveUsage) do
        local fPerc = tbPerc[i]
        UIHelper.SetString(label, string.format("%.2f%%", fPerc * 100))
        UIHelper.SetProgressBarPercent(self.tbSliderSaveUsage[i], fPerc * 100)
    end
end

function UIHomelandBuildSettingView:UpdateItemListInfo()
    local tAllObject = HLBOp_Amount.GetAllObjIDInfo()
	local nItemCount = 0
	if not tAllObject then
		return
	end
	for dwObjID, dwModelID in pairs(tAllObject) do
		local tInfo = FurnitureData.GetFurnInfoByModelID(dwModelID)
		if tInfo then
			nItemCount = nItemCount + 1
		end
	end

    UIHelper.SetString(self.LabelPlacedNum, tostring(nItemCount))
end


function UIHomelandBuildSettingView:UpdateTogOperation()
    for nIndex, tog in ipairs(self.tbTogOperation) do
        local szKey = TogOperationIndex2Key[nIndex]
        UIHelper.SetSelected(tog, g_HomelandBuildingData[szKey])
    end
end

function UIHomelandBuildSettingView:UpdateCameraInfo()
    UIHelper.SetSelected(self.TogCameraMode, HLBOp_Camera.IsCameraIndoorsMode())

    for i, label in ipairs(self.tbLabelCameraSpeed) do
        local tbInfo = tbCameraSpeedParams[i]
        local nValue = g_HomelandBuildingData.nCamMoveSpeedOutdoors

        if i == 2 then
            nValue = g_HomelandBuildingData.nCamMoveSpeedIndoors
        end

        UIHelper.SetString(label, nValue)
        local fPerc = (nValue - tbInfo.nMinValue) / (tbInfo.nMaxValue - tbInfo.nMinValue)
        UIHelper.SetProgressBarPercent(self.tbProgressBarCameraSpeed[i], fPerc * 100)
        UIHelper.SetProgressBarPercent(self.tbSliderCameraSpeed[i], fPerc * 100)
    end

    HLBOp_Camera.UpdateCamMoveSpeed()
end

function UIHomelandBuildSettingView:UpdateFlowerBrushInfo()
    UIHelper.SetSelected(self.TogBrushType, HomelandEventHandler.GetGrasseEffectFurniture() == 1)
end

return UIHomelandBuildSettingView