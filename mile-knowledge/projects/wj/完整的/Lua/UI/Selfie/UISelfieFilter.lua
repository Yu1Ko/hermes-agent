-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UISelfieFilter
-- Date: 2023-05-04 14:48:19
-- Desc: 幻境云图 -- 滤镜界面
-- ---------------------------------------------------------------------------------

local UISelfieFilter = class("UISelfieFilter")
local tbBasFilterContent = {}

function UISelfieFilter:OnEnter()
    tbBasFilterContent = SelfieData.tbBasFilterContent
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
    SelfieData.EnableFilterPostEffect(true)
end

function UISelfieFilter:OnExit()
    self.bInit = false
    self:UnRegEvent()
    SelfieData.EnableFilterPostEffect(false)
end

function UISelfieFilter:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnReset , EventType.OnClick , function ()
        SelfieData.SafeChangeFilter(SelfieData.nCurSelectFilterIndex)
        self:UpdateFilterSetting(true)
        self:ResetFilterEx(self.nLastSelectFilter)
    end)

end

function UISelfieFilter:RegEvent()
    Event.Reg(self, "SELFIE_STUDIO_ENV_PRESET_UPDATE", function()
        self:ReApplyFilterExParamsSetting()
    end)

    Event.Reg(self, EventType.SelfieFilterSettingReset, function()
        self:ResetFilterSetting(true)
    end)
end

function UISelfieFilter:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
    SelfieData.HideFilterExEffect()
end



function UISelfieFilter:Hide()
    UIHelper.SetVisible(self.ScrollViewSetting , false)
    UIHelper.SetVisible(self._rootNode , false)
    UIHelper.SetVisible(self.ImgRightBack , false)
    UIHelper.SetVisible(self.ImgRightClose , true)
    UIHelper.SetVisible(self.BtnReset , false)
end

function UISelfieFilter:Open()
    if SelfieData.IsInStudioMap() then
        SelfieData.EnableFilterPostEffect(true)
        self:UpdateExParamEnable() 
    end
end

function UISelfieFilter:ResetFilterValue(nType , nPercent)
    if nType == Selfie_BaseSettingType.FilterAJ then
         SelfieData.SetFilterSliderFuncInfoByParamID(5 , nPercent)
    elseif nType == Selfie_BaseSettingType.FilterKL then
         SelfieData.SetFilterSliderFuncInfoByParamID(6 , nPercent)
    elseif nType == Selfie_BaseSettingType.FilterBGZ then
         SelfieData.SetFilterSliderFuncInfoByParamID(7 , nPercent)
    elseif nType == Selfie_BaseSettingType.FilterRG then
         SelfieData.SetFilterSliderFuncInfoByParamID(8 , nPercent)
    elseif nType == Selfie_BaseSettingType.FilterJTSC then
         SelfieData.SetFilterSliderFuncInfoByParamID(9 , nPercent)
    elseif nType == Selfie_BaseSettingType.FilterGG then
         SelfieData.SetFilterSliderFuncInfoByParamID(10 , nPercent)
    end
end
-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISelfieFilter:UpdateInfo(bOutSide)
    
    UIHelper.RemoveAllChildren(self.LayoutCameraFilterOption)
    self.bShowSetting = false
    self.tbFilterCellInfo = {}
    self.nLastSelectFilter = -1
    self.gLastSelectCell = nil
    local tbFilterParamList = bOutSide and Table_GetAllOutsideFilterParams() or Table_GetAllSelfieFilterParams()
    local fileterCellCallback = function(nFilterIndex , cellNode)
        if self.nLastSelectFilter == nFilterIndex then
            return
        end
        if self.gLastSelectCell then
            self.gLastSelectCell:ShowSelectState(false)
        end
        self.nLastSelectFilter = nFilterIndex
        self.gLastSelectCell = cellNode
        SelfieData.nCurSelectFilterIndex = nFilterIndex
        SelfieData.tbFilterCacheInfo = {}
        local tbParams = SelfieData.GetFilterParamSettingByDefaultValues(self.nLastSelectFilter)
        if tbParams ~= nil then
            for k, v in pairs(self.tbParamsSlider) do
                v:SetSliderValue(tbParams[k])
                SelfieData.tbFilterCacheInfo[v.nType] = tbParams[k]
            end
        end
        SelfieData.SetNewFilter(nFilterIndex)
        self:ResetFilterEx(self.nLastSelectFilter)
    end
    local EditorCellCallback = function()
        self:UpdateFilterSetting()
    end
    local gFirstNode = nil
    for i = 1, #tbFilterParamList do
        local tFilterParams = tbFilterParamList[i]
        local node =  UIHelper.AddPrefab(PREFAB_ID.WidgetCameraFilterOption , self.LayoutCameraFilterOption)
		node:UpdateInfo(tFilterParams , fileterCellCallback,EditorCellCallback)
        if i == 1 then
            gFirstNode = node
        end
	end
    UIHelper.LayoutDoLayout(self.LayoutCameraFilterOption)
    UIHelper.SetVisible(self.ScrollViewSetting , false)
    UIHelper.SetVisible(self.BtnReset , false)
    UIHelper.RemoveAllChildren(self.LayouSetting)
    self.tbParamsSlider = {}
    for i, v in ipairs(tbBasFilterContent) do
        local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetSliderCameraSetting , self.LayouSetting)
        cell:OnEnter(v.nType , v.szName , v.tHideIndex)

        local tFuncInfo = SelfieData.GetFilterSliderFuncInfoByParamID(i)
        local tData = tFuncInfo and tFuncInfo.tData
        if tData then
            local nMinValue = tData[3] or 0
            local nUnitValue = math.pow(10, -tData[1])
            cell:SetSliderUnitValue(nUnitValue)
            cell:SetMinPercent(nMinValue)
            cell:SetMaxPercent(tData[2])
        end
        self.tbParamsSlider[i] = cell
     end
    self:InitFilterExParams()
    UIHelper.LayoutDoLayout(self.LayouSetting)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSetting)
    fileterCellCallback(0,gFirstNode)
    gFirstNode:ShowSelectState(true)
end

function UISelfieFilter:UpdateFilterSetting(bReset)
    self.bShowSetting = true--self.nLastSelectFilter ~= 0
    UIHelper.SetVisible(self.ScrollViewSetting , self.bShowSetting)
    UIHelper.SetVisible(self._rootNode , not self.bShowSetting)
    self:ResetFilterSetting(bReset)
    UIHelper.LayoutDoLayout(self.LayouSetting)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSetting)
    UIHelper.SetVisible(self.ImgRightBack , true)
    UIHelper.SetVisible(self.ImgRightClose , false)

    UIHelper.SetVisible(self.BtnReset , self.bShowSetting)
end

function UISelfieFilter:ResetFilterSetting(bReset)
    if bReset then
        SelfieData.tbFilterCacheInfo = {}
    end
    local tbParams = SelfieData.GetFilterParamSettingByDefaultValues(self.nLastSelectFilter)
    if tbParams ~= nil then
        for k, v in pairs(self.tbParamsSlider) do
            if bReset then
                SelfieData.tbFilterCacheInfo[v.nType] = tbParams[k]
            end
            v:SetSliderValue(SelfieData.GetFilterCacheInfo(v.nType) or tbParams[k])
            v:UpdateVisible(self.nLastSelectFilter)
        end
    end
end

function UISelfieFilter:UpdateAllFilterParamSetting(tbParams)
    if tbParams ~= nil then
        for k, v in pairs(self.tbParamsSlider) do
            v:SetSliderValue(SelfieData.GetFilterCacheInfo(v.nType) or tbParams[k])
            -- v:UpdateVisible(self.nLastSelectFilter)
        end
    end
end

function UISelfieFilter:HideSettingPanel()
    self.bShowSetting = false
    UIHelper.SetVisible(self.ScrollViewSetting , self.bShowSetting)
    UIHelper.SetVisible(self._rootNode , not self.bShowSetting)
    UIHelper.SetVisible(self.ImgRightBack , false)
    UIHelper.SetVisible(self.ImgRightClose , true)
    UIHelper.SetVisible(self.BtnReset , self.bShowSetting)
end

function UISelfieFilter:IsHideSettingPanel()
    return self.bShowSetting
end


function UISelfieFilter:ResetFilterEx(nIndex)
    local bEnable = true--nIndex ~= 0
    local _, aExParams= SelfieData.GetFilterParamSettingByDefaultValues(self.nLastSelectFilter)
    self.tbExparamsDefaultValue = aExParams
    if self.m_tExtraCell then
        for nClass, v in pairs(self.m_tExtraCell) do
            UIHelper.SetVisible(v.tTitleCell._rootNode, bEnable)
            self:UpdatExtraFilterSubState(nClass,  v.bEnable and bEnable, bEnable)
            for _, subCell in pairs(self.m_tExtraCell[nClass].tSubCells) do
                UIHelper.SetVisible(subCell._rootNode, bEnable)
            end
        end
    end
    UIHelper.LayoutDoLayout(self.LayouSetting)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSetting)
    SelfieData.tExtraCell = self.m_tExtraCell
    SelfieData.tSelColorID = self.m_aSelColorID
end


function UISelfieFilter:InitFilterExParams()
    self.m_aSelColorID = {}
    self.m_tExtraCell = {}
    self.nColorClassRootID = 0
    local tExParamInfo = Table_GetFilterParamSetting()
    for _, tClass in ipairs(tExParamInfo) do
        local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetCameraSettingTogLong,self.LayouSetting)
        cell:OnEnter(Selfie_BaseSettingType.None, UIHelper.GBKToUTF8(tClass.szTitleName)) 
        cell.nSettingClass = tClass.nClass
        cell:SetToggleChangeCallback(function (bShow)
            self.m_tExtraCell[tClass.nClass].bEnable = bShow
            self:UpdatExtraFilterSubState(cell.nSettingClass, bShow)
            self:UpdateExParamEnable()
            UIHelper.LayoutDoLayout(self.LayouSetting)
            UIHelper.ScrollViewDoLayout(self.ScrollViewSetting)
        end)
        cell:SetResetCallback(function ()
            self:OnResetFilterExParams(tClass.nClass)
        end)
        self.m_tExtraCell[tClass.nClass] = {
            bEnable = false,
            tTitleCell = cell,
            tSubCells = {}
        }
        if tClass.tSub then
            local nColorClass = tClass.nColorClass
            if nColorClass and nColorClass ~= 0 then
                local tColorSetting = Table_GetFilterColorParamSetting(nColorClass)
                for _, tColor in ipairs(tColorSetting) do
                    local nColorID = tColor.nColorID
                    if not self.m_aSelColorID[nColorClass] then
                        self.m_aSelColorID[nColorClass] = nColorID
                    end
                end
                self.nColorClassRootID = tClass.nClass
                local subCell = UIHelper.AddPrefab(PREFAB_ID.WidgetHSLSetting , self.LayouSetting)
                table.insert(self.m_tExtraCell[tClass.nClass].tSubCells, subCell)
                subCell:OnEnter(tColorSetting, function (nColorID)
                    self:OnSetFilterParamColorItem(nColorID)
                end)
                subCell:SearchColorID(self.m_aSelColorID[nColorClass])
            end

            for _, tSubInfo in ipairs(tClass.tSub) do
                local nParamID = tSubInfo.nParamID
                local nClssID = tClass.nClass
                local tInfo = Table_GetFilterParamByID(nParamID)
                local nUnitValue = math.pow(10, -tInfo.nDecimal)
                local subCell = UIHelper.AddPrefab(PREFAB_ID.WidgetSliderCameraSetting , self.LayouSetting)
                subCell:OnEnter(Selfie_BaseSettingType.None , UIHelper.GBKToUTF8(tSubInfo.szOptionName))
                subCell:SetSliderUnitValue(nUnitValue)
                subCell:SetMinPercent(tInfo.nMinValue)
                subCell:SetMaxPercent(tInfo.nMaxValue)
                subCell:SetSliderValue(0)
                subCell.nParamID = nParamID
                subCell:SetSliderChangeCallback(function (fValue)
                    self:UpdatExtraFilterSliderChange(nClssID, nParamID, fValue)
                end)
                table.insert(self.m_tExtraCell[tClass.nClass].tSubCells, subCell)
            end
        end
    end
    SelfieData.tExtraCell = self.m_tExtraCell
    SelfieData.tSelColorID = self.m_aSelColorID
end

function UISelfieFilter:UpdatExtraFilterSubState(nClassID, bShow, bUpdateValue)
    for _, subCell in pairs(self.m_tExtraCell[nClassID].tSubCells) do
        if subCell.SetEnableState then
            subCell:SetEnableState(bShow)
        end
       
        if bUpdateValue and subCell.nParamID then
            local tParamInfo = Table_GetFilterParamByID(subCell.nParamID)
            if not nClassID or nClassID == tParamInfo.nClass then
                local fValue
                local aParams = self.tbExparamsDefaultValue[subCell.nParamID]
                if tParamInfo.nColorClass ~= 0 and type(aParams) == "table" then
                    local nSelColorID = self.m_aSelColorID[tParamInfo.nColorClass]
                    fValue = aParams[nSelColorID]
                else
                    fValue = aParams
                end
                subCell:SetSliderValue(fValue)
            end
        end
    end
end

function UISelfieFilter:UpdatExtraFilterSliderChange(nClssID, nParamID, fValue)
    local tParamInfo = Table_GetFilterParamByID(nParamID)
    if tParamInfo then
        if self.m_tExtraCell[nClssID].bEnable then
            local tExParamInfo = SelfieData.GetFilterExParamSetting()
            local tSetInfo = tExParamInfo[nParamID]
            local bColor = tSetInfo.nColorClass and tSetInfo.nColorClass ~= 0
            if bColor then
                local nSelColorID = self.m_aSelColorID[tSetInfo.nColorClass]
                SelfieData.SetPostEffectExParam(nParamID, fValue, nSelColorID)
                if self.tbExparamsDefaultValue then
                    if not self.tbExparamsDefaultValue[nParamID] then
                        self.tbExparamsDefaultValue[nParamID] = {}
                    end
                    self.tbExparamsDefaultValue[nParamID][nSelColorID] = fValue
                end
            else
                SelfieData.SetPostEffectExParam(nParamID, fValue)
                if self.tbExparamsDefaultValue then
                    self.tbExparamsDefaultValue[nParamID] = fValue
                end
            end
        end
    end
    SelfieData.tExtraCell = self.m_tExtraCell
    SelfieData.tSelColorID = self.m_aSelColorID
end

function UISelfieFilter:UpdateExParamEnable()
	local bEnableGeneralFilters = true--sself.nLastSelectFilter ~= 0
    local tExParamInfo = SelfieData.GetFilterExParamSetting()
    for nExParamID, tSetInfo in pairs(tExParamInfo) do
        local tParamInfo = Table_GetFilterParamByID(nExParamID)
        local nClssID = tParamInfo.nClass
        local bEnableExParam = false
        if nClssID then
            bEnableExParam = self.m_tExtraCell[nClssID].bEnable
        end
        if tSetInfo.bTitle then
            if bEnableGeneralFilters then
                KG3DEngine.SetPostEffectParam(tSetInfo.nType, tSetInfo.nPostEffectParam, bEnableExParam)
            end
        else
            if bEnableExParam then
                for k, subCell in pairs(self.m_tExtraCell[nClssID].tSubCells) do
                    if subCell.nParamID and subCell.nParamID == nExParamID then
                        local bColor = tSetInfo.nColorClass and tSetInfo.nColorClass ~= 0
                        if bColor then
                            local nColorID = self.m_aSelColorID[tSetInfo.nColorClass]
                            SelfieData.SetPostEffectExParam(nExParamID, subCell.sliderValue, nColorID)
                        else
                            SelfieData.SetPostEffectExParam(nExParamID, subCell.sliderValue)
                        end
                    end
                end
            end
        end
    end
    SelfieData.tExtraCell = self.m_tExtraCell
    SelfieData.tSelColorID = self.m_aSelColorID
end

function UISelfieFilter:OnResetFilterExParams(nClassID)
    if not self.m_tExtraCell[nClassID].bEnable then
        return
    end
    local _, aExParams= SelfieData.GetFilterParamSettingByDefaultValues(self.nLastSelectFilter)

    for _, subCell in pairs(self.m_tExtraCell[nClassID].tSubCells) do
        if subCell.nParamID then
            local tParamInfo = Table_GetFilterParamByID(subCell.nParamID)
            if not nClassID or nClassID == tParamInfo.nClass then
                local fValue
                local aParams = aExParams[subCell.nParamID]
                self.tbExparamsDefaultValue[subCell.nParamID] = aParams
                if tParamInfo.nColorClass ~= 0 and type(aParams) == "table" then
                    local nSelColorID = self.m_aSelColorID[tParamInfo.nColorClass]
                    fValue = aParams[nSelColorID]
                else
                    fValue = aParams
                end
                subCell:SetSliderValue(fValue)
            end
        end
    end
    SelfieData.tExtraCell = self.m_tExtraCell
    SelfieData.tSelColorID = self.m_aSelColorID
end

function UISelfieFilter:OnSetFilterParamColorItem(nColorID)
    local nColorClass = Table_GetFilterColorClassByID(nColorID)
    self.m_aSelColorID[nColorClass] = nColorID
    self:UpdatExtraFilterSubState(self.nColorClassRootID,self.m_tExtraCell[self.nColorClassRootID].bEnable,true)
    SelfieData.tSelColorID = self.m_aSelColorID
    SelfieData.tExtraCell = self.m_tExtraCell
end


function UISelfieFilter:ReApplyFilterExParamsSetting()
    if not SelfieData.CanShowFilterSettingPage() then
        return
    end
    self:UpdateExParamEnable()
end

function UISelfieFilter:UpdatetFilterPage()
    if not SelfieData.CanShowFilterSettingPage() then
        return
    end
    self:UpdateExParamEnable()
end


function UISelfieFilter:SetPhotoScript(tFilter)
    SelfieData.nCurSelectFilterIndex = tFilter.nFilterIndex
    self.nLastSelectFilter = tFilter.nFilterIndex
    SelfieData.SafeChangeFilter(SelfieData.nCurSelectFilterIndex)

    local tParams = SelfieData.ExtractFilterDataParams(tFilter)
    SelfieData.tbFilterCacheInfo = tParams
    self:UpdateAllFilterParamSetting(tParams)

    self.m_aSelColorID = tFilter.tColor
    local tExParams = clone(tFilter.tVKExParams)
    

    for nClass, v in pairs(self.m_tExtraCell) do
        local tInfo = tExParams[nClass]
        local bEnable = tFilter.tEnableExParamClass[nClass]
        UIHelper.SetVisible(v.tTitleCell._rootNode, bEnable)
        self:UpdatExtraFilterSubState(nClass, bEnable, bEnable)
        for _, subCell in pairs(self.m_tExtraCell[nClass].tSubCells) do
            UIHelper.SetVisible(subCell._rootNode, bEnable)
        end
    end
end

return UISelfieFilter