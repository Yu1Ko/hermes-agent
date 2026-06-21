-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildFloorBrushEditor
-- Date: 2024-01-19 11:42:08
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildFloorBrushEditor = class("UIHomelandBuildFloorBrushEditor")

local DataModel = HomelandCustomBrushData
local MAX_ITEM = 3

function UIHomelandBuildFloorBrushEditor:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
    self:OnSelectCell(1)
end

function UIHomelandBuildFloorBrushEditor:OnExit()
    self.bInit = false
end

function UIHomelandBuildFloorBrushEditor:BindUIEvent()
    for i, cell in ipairs(self.tbScriptCell) do
        local script = UIHelper.GetBindScript(cell)
        UIHelper.BindUIEvent(script.TogLayer, EventType.OnClick, function(btn)
            local nIndex = i
            self:OnSelectCell(nIndex)
        end)
        UIHelper.ToggleGroupAddToggle(self.TogGroupBrushLayer, script.TogLayer)
    end

    UIHelper.BindUIEvent(self.BtnApply, EventType.OnClick, function(btn)
        local nCount = 0
        for i = 1, MAX_ITEM do
            if DataModel.tFloorBrushConfig[i].nBrushID > 0 then
                nCount = nCount + 1
            end
        end
        if nCount == 0 then
            -- View.CheckFloorBrush(false)
            -- View.ShowFloorGuide()
            return
        end
        DataModel.tSettingInfo.nSettingType = DataModel.SETTING_TYPE.FLOOR
        DataModel.ExitFloorEdit()
        DataModel.UseFloorBrush()
    end)

    UIHelper.BindUIEvent(self.BtnFeatherizeLeft, EventType.OnClick, function()
        local tBrushInfo = DataModel.GetSettingData(DataModel.tSettingInfo.nSettingType)
        tBrushInfo["nEdge"] = math.max(1, tBrushInfo["nEdge"] - 1)
        DataModel.CreateBrush()
        DataModel.SaveOnePlan()
        self:UpdateSettingInfo()
    end)

    UIHelper.BindUIEvent(self.BtnFeatherizeRight, EventType.OnClick, function()
        local tBrushInfo = DataModel.GetSettingData(DataModel.tSettingInfo.nSettingType)
        tBrushInfo["nEdge"] = math.min(4, tBrushInfo["nEdge"] + 1)
        DataModel.CreateBrush()
        DataModel.SaveOnePlan()
        self:UpdateSettingInfo()
    end)

    UIHelper.BindUIEvent(self.BtnStrengthLeft, EventType.OnClick, function()
        local tBrushInfo = DataModel.GetSettingData(DataModel.tSettingInfo.nSettingType)
        tBrushInfo["nStrength"] = math.max(0, tBrushInfo["nStrength"] - 1)
        DataModel.CreateBrush()
        DataModel.SaveOnePlan()
        self:UpdateSettingInfo()
    end)

    UIHelper.BindUIEvent(self.BtnStrengthRight, EventType.OnClick, function()
        local tBrushInfo = DataModel.GetSettingData(DataModel.tSettingInfo.nSettingType)
        tBrushInfo["nStrength"] = math.min(4, tBrushInfo["nStrength"] + 1)
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
        UIHelper.RegisterEditBoxEnded(self.EditFeatherizePaginate, function()
			EditBoxEnded(self.EditFeatherizePaginate, 1, 4, "nEdge")
        end)
        UIHelper.RegisterEditBoxEnded(self.EditStrengthPaginate, function()
			EditBoxEnded(self.EditStrengthPaginate, 0, 4, "nStrength")
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditFeatherizePaginate, function()
            EditBoxEnded(self.EditFeatherizePaginate, 1, 4, "nEdge")
        end)
        UIHelper.RegisterEditBoxReturn(self.EditStrengthPaginate, function()
            EditBoxEnded(self.EditStrengthPaginate, 0, 4, "nStrength")
        end)
    end

    UIHelper.SetEditboxTextHorizontalAlign(self.EditFeatherizePaginate, TextHAlignment.CENTER)
    UIHelper.SetEditboxTextHorizontalAlign(self.EditStrengthPaginate, TextHAlignment.CENTER)
end

function UIHomelandBuildFloorBrushEditor:RegEvent()
    Event.Reg(self, EventType.OnChangeHomelandBuildCustomBrushData, function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnSelectCustomBrushFloorItem, function (nIndex)
        self:OnSelectCell(nIndex)
    end)
end

function UIHomelandBuildFloorBrushEditor:UpdateInfo()
    self:UpdateCellInfo()
    self:UpdateSettingInfo()
end

function UIHomelandBuildFloorBrushEditor:UpdateCellInfo()
    if not self.tbCells then
        self.tbCells = {}
        for i, cell in ipairs(self.tbScriptCell) do
            self.tbCells[i] = UIHelper.GetBindScript(cell)
        end
    end

    local tBrushID = DataModel.tFloorBrushConfig or {}

    for i = 1, MAX_ITEM, 1 do
        local tbInfo = tBrushID[i] or {}
        local nFurnitureID = tbInfo.nBrushID
        local cell = self.tbCells[i]
        cell:OnEnter(i, nFurnitureID)

        local nIndex = i
        cell:SetRecallCallback(function()
            DataModel.DelOneFloorEditItem(nIndex)
        end)
    end
end

function UIHomelandBuildFloorBrushEditor:UpdateSettingInfo()
    local tBrushInfo = DataModel.GetSettingData(DataModel.SETTING_TYPE.FLOOR_ITEM) or {}

    UIHelper.SetText(self.EditFeatherizePaginate, tBrushInfo["nEdge"] or 1)
    UIHelper.SetText(self.EditStrengthPaginate, tBrushInfo["nStrength"] or 4)
end

function UIHomelandBuildFloorBrushEditor:OnSelectCell(nIndex)
    local tBrushInfo = DataModel.tFloorBrushConfig
    if nIndex ~= 1 and tBrushInfo[nIndex - 1].nBrushID == 0 then
        return
    end
    DataModel.tSettingInfo.nFloorIndex = nIndex
    DataModel.tSettingInfo.nSettingType = DataModel.SETTING_TYPE.FLOOR_ITEM
    DataModel.SelectItem(tBrushInfo[nIndex].nBrushID)
    if tBrushInfo[nIndex].nBrushID > 0 then
        self:UpdateSettingInfo()
    end

    UIHelper.SetToggleGroupSelected(self.TogGroupBrushLayer, nIndex - 1)
end

return UIHomelandBuildFloorBrushEditor