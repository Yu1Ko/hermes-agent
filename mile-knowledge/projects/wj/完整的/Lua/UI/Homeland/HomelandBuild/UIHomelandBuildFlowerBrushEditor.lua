-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildFlowerBrushEditor
-- Date: 2024-01-22 15:17:28
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildFlowerBrushEditor = class("UIHomelandBuildFlowerBrushEditor")

local DataModel = HomelandCustomBrushData
local SLIDER_MAX_X = 480

function UIHomelandBuildFlowerBrushEditor:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbSliderValue = {0, 0}
    self:UpdateInfo()
end

function UIHomelandBuildFlowerBrushEditor:OnExit()
    self.bInit = false
end

function UIHomelandBuildFlowerBrushEditor:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSingleIcon, EventType.OnClick, function(btn)
        if DataModel.tFlowerBrushConfig.tSingle.nBrushID == 0 then
            TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_BUILDING_FLOWER_BRUSH_BOTTOM_CHOOSE)
        end
    end)

    for i, tog in ipairs(self.tbTogBrush) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function(btn)
            if i == 1 then
                if DataModel.tFlowerBrushConfig.tSingle.nBrushID == 0 then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_BUILDING_FLOWER_BRUSH_BOTTOM_CHOOSE)
                end
                DataModel.ExitFlowerEdit()
                DataModel.UseSingleFlowerBrush()
                UIHelper.SetVisible(self.WidgetSingleBrush, true)
                UIHelper.SetVisible(self.WidgetMultiBrush, false)
            else
                UIHelper.SetToggleGroupSelected(self.TogGroupMultiBrush, 0)

                local nPlanIndex = i - 1
                DataModel.EnterFlowerEdit(nPlanIndex)
                self:UpdateMultiInfo()
                UIHelper.SetVisible(self.WidgetSingleBrush, false)
                UIHelper.SetVisible(self.WidgetMultiBrush, true)
            end
        end)
        UIHelper.ToggleGroupAddToggle(self.TogGroupMode, tog)
    end

    for i, tog in ipairs(self.tbTogMultiIcon) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function(btn)
            local tBrushID = DataModel.tFlowerEditInfo.tBrushID
            if tBrushID[i] == 0 then
                TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_BUILDING_FLOWER_BRUSH_BOTTOM_CHOOSE)
            end

            -- 中间的格子不能选
            if i ~= 1 and tBrushID[i - 1] == 0 then
                for j = i, 2, -1 do
                    if tBrushID[j - 1] and tBrushID[j - 1] > 0 then
                        UIHelper.SetToggleGroupSelected(self.TogGroupMultiBrush, j - 1)
                        DataModel.tFlowerEditInfo.nItemIndex = j
                        DataModel.SelectItem(tBrushID[j])
                        return
                    end
                end

                UIHelper.SetToggleGroupSelected(self.TogGroupMultiBrush, 0)
                DataModel.tFlowerEditInfo.nItemIndex = 1
                DataModel.SelectItem(tBrushID[1])
                return
            end
            DataModel.tFlowerEditInfo.nItemIndex = i
            DataModel.SelectItem(tBrushID[i])
        end)
        UIHelper.ToggleGroupAddToggle(self.TogGroupMultiBrush, tog)
    end

    UIHelper.BindUIEvent(self.BtnApply, EventType.OnClick, function(btn)
        local nIndex = UIHelper.GetToggleGroupSelectedIndex(self.TogGroupMode)
        if nIndex == 0 then
            DataModel.StartSingleFlowerBrush()
        else
            DataModel.UseFlowerPlanBrush(nIndex)
        end
    end)

    UIHelper.BindUIEvent(self.BtnSlider01, EventType.OnTouchMoved, function(btn, x, y)
        local x1, y1 = UIHelper.ConvertToNodeSpace(self.WidgetDoubleSlider, x, y)
        x1 = math.max(0, x1)
        x1 = math.min(self.tbSliderValue[2] / 100 * SLIDER_MAX_X, x1)
        self.tbSliderValue[1] = 100 * x1 / SLIDER_MAX_X
        UIHelper.SetPositionX(self.BtnSlider01, x1)

        local tBrushPer = DataModel.tFlowerEditInfo.tBrushPer or {}
        tBrushPer[2] = tBrushPer[2] - self.tbSliderValue[1] + tBrushPer[1]
        tBrushPer[1] = self.tbSliderValue[1]

        self:UpdateMultiInfo()
    end)

    UIHelper.BindUIEvent(self.BtnSlider02, EventType.OnTouchMoved, function(btn, x, y)
        local x1, y1 = UIHelper.ConvertToNodeSpace(self.WidgetDoubleSlider, x, y)
        x1 = math.max(self.tbSliderValue[1] / 100 * SLIDER_MAX_X, x1)
        x1 = math.min(SLIDER_MAX_X, x1)
        self.tbSliderValue[2] = 100 * x1 / SLIDER_MAX_X
        UIHelper.SetPositionX(self.BtnSlider02, x1)

        local tBrushPer = DataModel.tFlowerEditInfo.tBrushPer or {}
        tBrushPer[2] = self.tbSliderValue[2] - self.tbSliderValue[1]
        tBrushPer[3] = 100 - self.tbSliderValue[2]

        self:UpdateMultiInfo()
    end)
end

function UIHomelandBuildFlowerBrushEditor:RegEvent()
    Event.Reg(self, EventType.OnChangeHomelandBuildCustomBrushData, function ()
        self:UpdateInfo()
    end)
end

function UIHomelandBuildFlowerBrushEditor:UpdateInfo()
    self:UpdateSingleInfo()
    self:UpdateMultiInfo()
end

function UIHomelandBuildFlowerBrushEditor:UpdateSingleInfo()
    self.scriptSingleIcon = self.scriptSingleIcon or UIHelper.GetBindScript(self.TogSingleIcon)
    local nFurnitureID = DataModel.tFlowerBrushConfig.tSingle.nBrushID
    self.scriptSingleIcon:OnEnter(nFurnitureID)
    self.scriptSingleIcon:SetRecallCallback(function()
        DataModel.ExitFlowerEdit()
        DataModel.tFlowerBrushConfig.tSingle.nBrushID = 0
        DataModel.tSettingInfo.nSettingType = DataModel.SETTING_TYPE.NULL
        DataModel.CancelBrush()
        self:UpdateSingleInfo()
    end)
end

function UIHomelandBuildFlowerBrushEditor:UpdateMultiInfo()
    if not self.tbScriptMultiIcon then
        self.tbScriptMultiIcon = {}
        for i, tog in ipairs(self.tbTogMultiIcon) do
            self.tbScriptMultiIcon[i] = UIHelper.GetBindScript(tog)
        end
    end

    local tBrushID = DataModel.tFlowerEditInfo.tBrushID or {}
    local tBrushPer = DataModel.tFlowerEditInfo.tBrushPer or {}

    local nCount = 0
    for i, cell in ipairs(self.tbScriptMultiIcon) do
        local nFurnitureID = tBrushID[i]
        if nFurnitureID and nFurnitureID > 0 then
            nCount = nCount + 1
        end
        local nPerc = tBrushPer[i]
        cell:OnEnter(nFurnitureID, nPerc)

        local nIndex = i
        cell:SetRecallCallback(function()
            DataModel.DelOneFlowerEditItem(nIndex)
        end)
    end

    UIHelper.SetVisible(self.WidgetDoubleSlider, nCount >= 2)
    UIHelper.SetVisible(self.BtnSlider02, nCount > 2)

    self.tbSliderValue = {tBrushPer[1] or 0, (tBrushPer[1] or 0) + (tBrushPer[2] or 0)}
    UIHelper.SetPositionX(self.BtnSlider01, self.tbSliderValue[1] / 100 * SLIDER_MAX_X)
    UIHelper.SetPositionX(self.BtnSlider02, self.tbSliderValue[2] / 100 * SLIDER_MAX_X)

    self:UpdateSliderInfo()
end

function UIHomelandBuildFlowerBrushEditor:UpdateSliderInfo()
    -- if self.tbSliderValue[1] > self.tbSliderValue[2] then
    --     local v = self.tbSliderValue[1]
    --     self.tbSliderValue[1] = self.tbSliderValue[2]
    --     self.tbSliderValue[2] = v
    -- end

    UIHelper.SetWidth(self.tbImgBar[1], SLIDER_MAX_X / 100 * self.tbSliderValue[1])
    UIHelper.SetWidth(self.tbImgBar[2], SLIDER_MAX_X / 100 * self.tbSliderValue[2])
    UIHelper.SetWidth(self.tbImgBar[3], SLIDER_MAX_X)
end


return UIHomelandBuildFlowerBrushEditor