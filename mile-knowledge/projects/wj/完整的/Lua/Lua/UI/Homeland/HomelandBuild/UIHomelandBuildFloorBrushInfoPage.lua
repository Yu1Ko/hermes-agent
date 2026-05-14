-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildFloorBrushInfoPage
-- Date: 2024-01-22 19:09:02
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildFloorBrushInfoPage = class("UIHomelandBuildFloorBrushInfoPage")

local DataModel = HomelandCustomBrushData

function UIHomelandBuildFloorBrushInfoPage:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitView()
    self:UpdateInfo()
end

function UIHomelandBuildFloorBrushInfoPage:OnExit()
    self.bInit = false
end

function UIHomelandBuildFloorBrushInfoPage:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnFillUp, EventType.OnClick, function(btn)
        local scriptDialog = UIHelper.ShowConfirm(g_tStrings.STR_HOMELAND_BUILDING_FLOOR_BRUSH_FULL_CONFIRM, function ()
            DataModel.tSettingInfo.nSettingType = DataModel.SETTING_TYPE.NULL
            HLBOp_CustomBrush.FullFillCustomBrush()
            DataModel.CancelBrush()
        end)
        scriptDialog:SetButtonContent("Confirm", g_tStrings.STR_HOMELAND_BUILDING_FLOOR_BRUSH_FULL)
    end)

    UIHelper.BindUIEvent(self.BtnCleanUp, EventType.OnClick, function(btn)
        local scriptDialog = UIHelper.ShowConfirm(g_tStrings.STR_HOMELAND_BUILDING_FLOOR_BRUSH_WIPE_CONFIRM, function ()
            DataModel.CancelBrush()
            DataModel.tSettingInfo.nSettingType = DataModel.SETTING_TYPE.NULL
            HLBOp_CustomBrush.WipeAllFloorBrush()
        end)
        scriptDialog:SetButtonContent("Confirm", g_tStrings.STR_HOMELAND_BUILDING_FLOOR_BRUSH_WIPE)
    end)

    UIHelper.BindUIEvent(self.TogSwitchBrush, EventType.OnClick, function()
        local bSelected = UIHelper.GetSelected(self.TogSwitchBrush)

        if bSelected then
            DataModel.ExitFloorEdit()
            DataModel.tSettingInfo.nSettingType = DataModel.SETTING_TYPE.FLOOR
            DataModel.UseFloorBrush()
        else
            DataModel.ExitFloorEdit()
            DataModel.tSettingInfo.nSettingType = DataModel.SETTING_TYPE.FLOOR_ERASER
            DataModel.CreateBrush()
        end
    end)

    UIHelper.BindUIEvent(self.BtnBrushSizeLeft, EventType.OnClick, function()
        local tBrushInfo = DataModel.GetSettingData(DataModel.tSettingInfo.nSettingType)
        tBrushInfo["nSize"] = math.max(1, tBrushInfo["nSize"] - 1)
        DataModel.CreateBrush()
        DataModel.SaveOnePlan()
        self:UpdateSettingInfo()
    end)

    UIHelper.BindUIEvent(self.BtnBrushSizeRight, EventType.OnClick, function()
        local tBrushInfo = DataModel.GetSettingData(DataModel.tSettingInfo.nSettingType)
        tBrushInfo["nSize"] = math.min(3, tBrushInfo["nSize"] + 1)
        DataModel.CreateBrush()
        DataModel.SaveOnePlan()
        self:UpdateSettingInfo()
    end)

    UIHelper.BindUIEvent(self.BtnEraserSizeLeft, EventType.OnClick, function()
        local tBrushInfo = DataModel.GetSettingData(DataModel.tSettingInfo.nSettingType)
        tBrushInfo["nSize"] = math.max(1, tBrushInfo["nSize"] - 1)
        DataModel.CreateBrush()
        DataModel.SaveOnePlan()
        self:UpdateSettingInfo()
    end)

    UIHelper.BindUIEvent(self.BtnEraserSizeRight, EventType.OnClick, function()
        local tBrushInfo = DataModel.GetSettingData(DataModel.tSettingInfo.nSettingType)
        tBrushInfo["nSize"] = math.min(3, tBrushInfo["nSize"] + 1)
        DataModel.CreateBrush()
        DataModel.SaveOnePlan()
        self:UpdateSettingInfo()
    end)

    UIHelper.BindUIEvent(self.BtnEraserFeatherizeLeft, EventType.OnClick, function()
        local tBrushInfo = DataModel.GetSettingData(DataModel.tSettingInfo.nSettingType)
        tBrushInfo["nEdge"] = math.max(1, tBrushInfo["nEdge"] - 1)
        DataModel.CreateBrush()
        DataModel.SaveOnePlan()
        self:UpdateSettingInfo()
    end)

    UIHelper.BindUIEvent(self.BtnEraserFeatherizeRight, EventType.OnClick, function()
        local tBrushInfo = DataModel.GetSettingData(DataModel.tSettingInfo.nSettingType)
        tBrushInfo["nEdge"] = math.min(4, tBrushInfo["nEdge"] + 1)
        DataModel.CreateBrush()
        DataModel.SaveOnePlan()
        self:UpdateSettingInfo()
    end)

    local function EditBoxEnded(editBox, nMin, nMax, szValueName)
        local szNum = UIHelper.GetText(editBox)
        local nNum = tonumber(szNum)
        if nNum then
            nNum = math.min(nMax, nNum)
            nNum = math.max(nMin, nNum)

            local tBrushInfo = DataModel.GetSettingData(DataModel.tSettingInfo.nSettingType)
            tBrushInfo[szValueName] = nNum
            DataModel.CreateBrush()
            DataModel.SaveOnePlan()
        end
        UIHelper.SetText(editBox, nNum)
    end

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditBrushSize, function()
			EditBoxEnded(self.EditBrushSize, 1, 3, "nSize")
        end)
        UIHelper.RegisterEditBoxEnded(self.EditEraserSize, function()
			EditBoxEnded(self.EditEraserSize, 1, 3, "nSize")
        end)
        UIHelper.RegisterEditBoxEnded(self.EditEraserFeatherize, function()
			EditBoxEnded(self.EditEraserFeatherize, 1, 4, "nEdge")
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditBrushSize, function()
            EditBoxEnded(self.EditBrushSize, 1, 3, "nSize")
        end)
        UIHelper.RegisterEditBoxReturn(self.EditEraserSize, function()
            EditBoxEnded(self.EditEraserSize, 1, 3, "nSize")
        end)
        UIHelper.RegisterEditBoxReturn(self.EditEraserFeatherize, function()
            EditBoxEnded(self.EditEraserFeatherize, 1, 4, "nEdge")
        end)
    end

    UIHelper.SetEditboxTextHorizontalAlign(self.EditBrushSize, TextHAlignment.CENTER)
    UIHelper.SetEditboxTextHorizontalAlign(self.EditEraserSize, TextHAlignment.CENTER)
    UIHelper.SetEditboxTextHorizontalAlign(self.EditEraserFeatherize, TextHAlignment.CENTER)
end

function UIHomelandBuildFloorBrushInfoPage:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildFloorBrushInfoPage:InitView()
    UIHelper.SetSelected(self.TogSwitchBrush, DataModel.tSettingInfo.nSettingType ~= DataModel.SETTING_TYPE.FLOOR_ERASER)
end

function UIHomelandBuildFloorBrushInfoPage:UpdateInfo()
    self:UpdateSettingInfo()
end

function UIHomelandBuildFloorBrushInfoPage:UpdateSettingInfo()
    local tBrushInfo = DataModel.GetSettingData(DataModel.tSettingInfo.nSettingType)

    if DataModel.tSettingInfo.nSettingType == DataModel.SETTING_TYPE.FLOOR then
        UIHelper.SetText(self.EditBrushSize, tBrushInfo["nSize"])
    elseif DataModel.tSettingInfo.nSettingType == DataModel.SETTING_TYPE.FLOOR_ERASER then
        UIHelper.SetText(self.EditEraserSize, tBrushInfo["nSize"])
        UIHelper.SetText(self.EditEraserFeatherize, tBrushInfo["nEdge"])
    end
end


return UIHomelandBuildFloorBrushInfoPage