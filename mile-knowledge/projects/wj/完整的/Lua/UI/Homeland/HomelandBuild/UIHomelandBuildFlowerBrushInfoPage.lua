-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildFlowerBrushInfoPage
-- Date: 2024-01-22 19:09:17
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildFlowerBrushInfoPage = class("UIHomelandBuildFlowerBrushInfoPage")

local DataModel = HomelandCustomBrushData

function UIHomelandBuildFlowerBrushInfoPage:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitView()
    self:UpdateInfo()
end

function UIHomelandBuildFlowerBrushInfoPage:OnExit()
    self.bInit = false
end

function UIHomelandBuildFlowerBrushInfoPage:BindUIEvent()
    for i, tog in ipairs(self.tbTogMode) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function(btn)
            if i == 1 then
                DataModel.ExitFlowerEdit()
                DataModel.UseSingleFlowerBrush()
                HomelandCustomBrushData.StartSingleFlowerBrush()
            else
                local nPlanIndex = i - 1
                DataModel.EnterFlowerEdit(nPlanIndex)
                DataModel.UseFlowerPlanBrush(nPlanIndex)
                self:UpdateMultiInfo()
            end
        end)
        UIHelper.ToggleGroupAddToggle(self.TogGroupMode, tog)
    end

    UIHelper.BindUIEvent(self.TogSwitchBrush, EventType.OnClick, function()
        local bSelected = UIHelper.GetSelected(self.TogSwitchBrush)

        if bSelected then
            for i, tog in ipairs(self.tbTogMode) do
                if UIHelper.GetSelected(tog) then
                    if i == 1 then
                        DataModel.ExitFlowerEdit()
                        DataModel.UseSingleFlowerBrush()
                        DataModel.StartSingleFlowerBrush()
                    else
                        local nPlanIndex = i - 1
                        DataModel.EnterFlowerEdit(nPlanIndex)
                        DataModel.UseFlowerPlanBrush(nPlanIndex)
                        self:UpdateMultiInfo()
                    end
                    break
                end
            end
        else
            DataModel.ExitFlowerEdit()
            DataModel.tSettingInfo.nSettingType = DataModel.SETTING_TYPE.FLOWER_ERASER
            DataModel.CreateBrush()
        end
    end)

    UIHelper.BindUIEvent(self.BtnDensityLeft, EventType.OnClick, function()
        local tBrushInfo = DataModel.GetSettingData(DataModel.tSettingInfo.nSettingType)
        tBrushInfo["nDensity"] = math.max(1, tBrushInfo["nDensity"] - 1)
        DataModel.CreateBrush()
        DataModel.SaveOnePlan()
        self:UpdateSettingInfo()
    end)

    UIHelper.BindUIEvent(self.BtnDensityRight, EventType.OnClick, function()
        local tBrushInfo = DataModel.GetSettingData(DataModel.tSettingInfo.nSettingType)
        tBrushInfo["nDensity"] = math.min(10, tBrushInfo["nDensity"] + 1)
        DataModel.CreateBrush()
        DataModel.SaveOnePlan()
        self:UpdateSettingInfo()
    end)

    UIHelper.BindUIEvent(self.BtnSizeLeft, EventType.OnClick, function()
        local tBrushInfo = DataModel.GetSettingData(DataModel.tSettingInfo.nSettingType)
        tBrushInfo["nSize"] = math.max(1, tBrushInfo["nSize"] - 1)
        DataModel.CreateBrush()
        DataModel.SaveOnePlan()
        self:UpdateSettingInfo()
    end)

    UIHelper.BindUIEvent(self.BtnSizeRight, EventType.OnClick, function()
        local tBrushInfo = DataModel.GetSettingData(DataModel.tSettingInfo.nSettingType)
        tBrushInfo["nSize"] = math.min(2, tBrushInfo["nSize"] + 1)
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
        tBrushInfo["nSize"] = math.min(2, tBrushInfo["nSize"] + 1)
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
        UIHelper.RegisterEditBoxEnded(self.EditDensity, function()
			EditBoxEnded(self.EditDensity, 1, 10, "nDensity")
        end)
        UIHelper.RegisterEditBoxEnded(self.EditBrushSize, function()
			EditBoxEnded(self.EditBrushSize, 1, 2, "nSize")
        end)
        UIHelper.RegisterEditBoxEnded(self.EditEraserSize, function()
			EditBoxEnded(self.EditEraserSize, 1, 2, "nSize")
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditDensity, function()
            EditBoxEnded(self.EditDensity, 1, 10, "nDensity")
        end)
        UIHelper.RegisterEditBoxReturn(self.EditBrushSize, function()
            EditBoxEnded(self.EditBrushSize, 1, 2, "nSize")
        end)
        UIHelper.RegisterEditBoxReturn(self.EditEraserSize, function()
            EditBoxEnded(self.EditEraserSize, 1, 2, "nSize")
        end)
    end

    UIHelper.SetEditboxTextHorizontalAlign(self.EditDensity, TextHAlignment.CENTER)
    UIHelper.SetEditboxTextHorizontalAlign(self.EditBrushSize, TextHAlignment.CENTER)
    UIHelper.SetEditboxTextHorizontalAlign(self.EditEraserSize, TextHAlignment.CENTER)
end

function UIHomelandBuildFlowerBrushInfoPage:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildFlowerBrushInfoPage:InitView()
    UIHelper.SetToggleGroupSelected(self.TogGroupMode, 0)
    UIHelper.SetSelected(self.TogSwitchBrush, DataModel.tSettingInfo.nSettingType ~= DataModel.SETTING_TYPE.FLOWER_ERASER)
    if DataModel.tSettingInfo.nSettingType == DataModel.SETTING_TYPE.FLOWER_PLAN then
        UIHelper.SetToggleGroupSelected(self.TogGroupMode, HomelandCustomBrushData.tSettingInfo.nFlowerPlanIndex)
    end
end

function UIHomelandBuildFlowerBrushInfoPage:UpdateInfo()
    self:UpdateSingleInfo()
    self:UpdateMultiInfo()
    self:UpdateSettingInfo()
end

function UIHomelandBuildFlowerBrushInfoPage:UpdateSingleInfo()
    if not UIHelper.GetSelected(self.tbTogMode[1]) then
        return
    end

    UIHelper.SetTabVisible(self.tbWidgetIcon, false)
    UIHelper.SetVisible(self.tbWidgetIcon[1], true)
    self.scriptSingleIcon = self.scriptSingleIcon or UIHelper.GetBindScript(self.tbWidgetIcon[1])
    local nFurnitureID = DataModel.tFlowerBrushConfig.tSingle.nBrushID
    self.scriptSingleIcon:OnEnter(nFurnitureID)
end

function UIHomelandBuildFlowerBrushInfoPage:UpdateMultiInfo()
    if UIHelper.GetSelected(self.tbTogMode[1]) then
        return
    end

    UIHelper.SetTabVisible(self.tbWidgetIcon, true)

    if not self.tbScriptMultiIcon then
        self.tbScriptMultiIcon = {}
        for i, widget in ipairs(self.tbWidgetIcon) do
            self.tbScriptMultiIcon[i] = UIHelper.GetBindScript(widget)
        end
    end

    local tBrushInfo = DataModel.GetSettingData(DataModel.tSettingInfo.nSettingType)
    local tBrushID = tBrushInfo.tBrushID or {}
    local tBrushPer = tBrushInfo.tBrushPer or {}

    for i, cell in ipairs(self.tbScriptMultiIcon) do
        local nFurnitureID = tBrushID[i]
        local nPerc = tBrushPer[i]
        cell:OnEnter(nFurnitureID, nPerc)
    end
end

function UIHomelandBuildFlowerBrushInfoPage:UpdateSettingInfo()
    local tBrushInfo = DataModel.GetSettingData(DataModel.tSettingInfo.nSettingType)

    if DataModel.tSettingInfo.nSettingType == DataModel.SETTING_TYPE.SINGLE_FLOWER or
        DataModel.tSettingInfo.nSettingType == DataModel.SETTING_TYPE.FLOWER_PLAN then
        UIHelper.SetText(self.EditDensity, tBrushInfo["nDensity"])
        UIHelper.SetText(self.EditBrushSize, tBrushInfo["nSize"])
    elseif DataModel.tSettingInfo.nSettingType == DataModel.SETTING_TYPE.FLOWER_ERASER then
        UIHelper.SetText(self.EditEraserSize, tBrushInfo["nSize"])
    end
end


return UIHomelandBuildFlowerBrushInfoPage