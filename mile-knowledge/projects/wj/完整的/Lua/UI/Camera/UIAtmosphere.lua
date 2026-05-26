local UIAtmosphere = class("UIAtmosphere")

local tbBasFilterContent =
{
    {nType = Selfie_BaseSettingType.FilterQD , szName = "强度" , tHideIndex = {0, 24, 26, 27}},
    {nType = Selfie_BaseSettingType.FilterLD , szName = "亮度" , tHideIndex = {}},
    {nType = Selfie_BaseSettingType.FilterDBD , szName = "对比度" , tHideIndex = {}},
    {nType = Selfie_BaseSettingType.FilterBHD , szName = "饱和度" , tHideIndex = {}},
    {nType = Selfie_BaseSettingType.FilterAJ , szName = "暗角" , tHideIndex = {}},
    {nType = Selfie_BaseSettingType.FilterKL , szName = "颗粒" , tHideIndex = {}},
    {nType = Selfie_BaseSettingType.FilterBGZ , szName = "曝光值" , tHideIndex = {}},
    {nType = Selfie_BaseSettingType.FilterRG , szName = "柔光" , tHideIndex = {}},
    {nType = Selfie_BaseSettingType.FilterJTSC , szName = "色差" , tHideIndex = {}},
    {nType = Selfie_BaseSettingType.FilterGG , szName = "高光" , tHideIndex = {}},
}

local MAX_PRESET = 10

function UIAtmosphere:OnEnter()
    SelfieData.bCanSetFuncInfo = true
    if SceneMgr.IsInFaceState() then
        rlcmd("bd enable focus face 0")  -- 如果开启怼脸效果则关闭，避免与引擎参数设置冲突
    end
    SelfieData.SafeDefaultFilter()
    self:BindUIEvent()
    self:UpdateInfo()

    UIMutexMgr.SetCanCloseTopSidePageView(false)
end

function UIAtmosphere:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function()
        SelfieData.SafeChangeFilter(SelfieData.nCurSelectFilterIndex)
        self:UpdateFilterCache()
        self:UpdateFilterSettingPanel()
        self.bSettingDefaultParams = true
    end)
    UIHelper.BindUIEvent(self.BtnAtmosphereReset, EventType.OnClick, function()
        self.szTime = "INVALID"
        self:UpdateWeatherPanel()
        self:SelectWeather()
    end)
    UIHelper.BindUIEvent(self.BtnRightClose, EventType.OnClick, function()
        self:CloseView()
    end)
    UIHelper.BindUIEvent(self.BtnRightReturn, EventType.OnClick, function()
        self:ResetFilterSettings(self.tbTempParams)
        self:ToggleFilterSettingPanel(false)
    end)
    UIHelper.BindUIEvent(self.BtnDetail, EventType.OnClick, function()
        local tips, tipsScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnDetail
        , TipsLayoutDir.RIGHT_CENTER, SelfieData.szAtmosphereTip)

        local x, y = UIHelper.GetContentSize(tipsScript.ImgPublicLabelTips)
        tips:SetSize(x, y)
        tips:Update()
    end)
    UIHelper.BindUIEvent(self.BtnDemoSetting, EventType.OnClick, function()
        self.bPresetEditMode = true
        self:UpdatePresetEditMode()
        self:UpdateUIState()
    end)
    UIHelper.BindUIEvent(self.TogDemo, EventType.OnSelectChanged, function(_, bSelected)
        self:UpdateUIState(bSelected, nil)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCameraFilter)
    end)
    UIHelper.BindUIEvent(self.TogDemo_Self, EventType.OnSelectChanged, function(_, bSelected)
        if not bSelected then
            self.bPresetEditMode = false
            self:UpdatePresetEditMode()
        end
        self:UpdateUIState(nil, bSelected)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewMyDemo)
    end)
    UIHelper.BindUIEvent(self.BtnSettingCancel, EventType.OnClick, function()
        if UIHelper.GetSelected(self.TogDemo_Self) then
            -- 存为新预设
            self:SavePreset(nil, nil, function()
                self:ToggleFilterSettingPanel(false)
            end)
        else
            self:ResetFilterSettings(self.tbTempParams)
            self:ToggleFilterSettingPanel(false)
        end
    end)
    UIHelper.BindUIEvent(self.BtnSettingConfirm, EventType.OnClick, function()
        if UIHelper.GetSelected(self.TogDemo_Self) then
            -- 替换预设
            self:OverridePreset(function()
                self:ToggleFilterSettingPanel(false)
            end)
        else
            self:ToggleFilterSettingPanel(false)
        end
    end)
    UIHelper.BindUIEvent(self.BtnSave, EventType.OnClick, function()
        if self.bPresetEditMode then
            self.bPresetEditMode = false
            self:UpdatePresetEditMode()
            self:UpdateUIState()
            return
        end

        local nCount = #Storage.FilterParam.tbCustomPresets
        if nCount <= 0 then
            self:SavePreset()
        elseif nCount < MAX_PRESET then
            local dialog = UIHelper.ShowConfirm("要替换预设，还是创建一个新预设", function()
                self:SavePreset()
            end)
            dialog:ShowOtherButton()
            dialog:SetOtherButtonClickedCallback(function()
                self:OverridePreset()
            end)

            dialog:SetConfirmButtonContent("新建预设")
            dialog:SetOtherButtonContent("替换预设")
            dialog:SetCancelButtonContent("取消")
        else
            self:OverridePreset()
        end
    end)
    UIHelper.BindUIEvent(self.BtnApply, EventType.OnClick, function()
        SelfieData.SaveFilterCacheInfoToStorage()
        UIMgr.Close(self)
    end)

    Event.Reg(self, "SET_USER_ENV_PRESENT", function()
        for k, v in pairs(SelfieData.tbFilterCacheInfo) do
            if k ~= Selfie_BaseSettingType.FilterQD then
                SelfieData.SetSelfieFuncInfoByTypeID(k, v)
            end
        end
        -- 设置环境预设会修改景深相关参数，需再环境预设修改后重置
        QualityMgr._UpdateBlurSize()
    end)
    Event.Reg(self, EventType.OnKeyboardDown, function(nKeyCode, szKeyName)
        if szKeyName == "Esc" then
            self:CloseView()
        end
    end)
    Event.Reg(self, EventType.OnSceneTouchWithoutMove, function()
        self:CloseView()
    end)
end

function UIAtmosphere:UpdateFilterCache(tbParams)
    tbParams = tbParams or {}
    local tbDefault = SelfieData.GetFilterParamSettingByDefaultValues(self.nLastSelectFilter)
    SelfieData.tbFilterCacheInfo = {}
    for k, v in pairs(self.tbParamsSlider) do
        SelfieData.tbFilterCacheInfo[v.nType] = tbParams[v.nType] or tbDefault[k]
    end
end

function UIAtmosphere:SelectFilter(nFilterIndex, cellNode)
    if self.gLastSelectCell then
        self.gLastSelectCell:ShowSelectState(false)
        self.gLastSelectCell:SetModifyState(false)
    end
    local tbParamsBefore = self:GetFilterSettings()
    self.nLastSelectFilter = nFilterIndex
    self.gLastSelectCell = cellNode
    SelfieData.nCurSelectFilterIndex = nFilterIndex
    SelfieData.nCurSelectPresetIndex = 0
    SelfieData.SafeChangeFilter(nFilterIndex)

    self:UpdateUIState()
    self:UpdateFilterCache()
    self:UpdateParamsSlider()

    self.bDefaultParams = true
end

function UIAtmosphere:SelectPreset(nPresetIndex, cellNode, tbCustomParams)
    local nFilterIndex = tbCustomParams.nFilterIndex
    if self.gLastSelectCell then
        self.gLastSelectCell:ShowSelectState(false)
        self.gLastSelectCell:SetModifyState(false)
    end
    self.nLastSelectFilter = nFilterIndex
    self.gLastSelectCell = cellNode
    SelfieData.nCurSelectFilterIndex = nFilterIndex
    SelfieData.nCurSelectPresetIndex = nPresetIndex
    SelfieData.SafeChangeFilter(nFilterIndex)

    self:UpdateUIState()
    self:UpdateFilterCache(tbCustomParams)
    self:UpdateParamsSlider()
end

function UIAtmosphere:UpdateParamsSlider()
    for k, v in pairs(self.tbParamsSlider) do
        v:SetSliderValue(SelfieData.tbFilterCacheInfo[v.nType])
        v:UpdateVisible(self.nLastSelectFilter)
        v:UpdateSliderValue() -- 触发因UnitValue导致的SelfieData.tbFilterCacheInfo刷新
    end
end

function UIAtmosphere:UpdateFilterSettingPanel()
    UIHelper.SetVisible(self.WidgetAtmosphereSetting, self.bShowSetting)
    UIHelper.SetVisible(self.WIdgetAnchorCameraSetting, not self.bShowSetting)
    self:UpdateParamsSlider()

    if UIHelper.GetSelected(self.TogDemo_Self) then
        UIHelper.SetButtonState(self.BtnSettingCancel, #Storage.FilterParam.tbCustomPresets < MAX_PRESET and BTN_STATE.Normal or BTN_STATE.Disable)
        UIHelper.SetButtonState(self.BtnSettingConfirm, #Storage.FilterParam.tbCustomPresets > 0 and BTN_STATE.Normal or BTN_STATE.Disable)
        UIHelper.SetString(self.LabelCancel, "存为新预设")
        UIHelper.SetString(self.LabelConfirm, "替换预设")
    else
        UIHelper.SetButtonState(self.BtnSettingCancel, BTN_STATE.Normal)
        UIHelper.SetButtonState(self.BtnSettingConfirm, BTN_STATE.Normal)
        UIHelper.SetString(self.LabelCancel, "取消")
        UIHelper.SetString(self.LabelConfirm, "确定")
    end

    UIHelper.LayoutDoLayout(self.LayoutCameraSetting)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCameraFilter)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewMyDemo)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCameraFilterSetting)
end

function UIAtmosphere:ToggleFilterSettingPanel(bShow)
    self.bShowSetting = bShow
    self:UpdateFilterSettingPanel()

    if bShow then
        self.tbTempParams = self:GetFilterSettings()
        self.bSettingDefaultParams = self.bDefaultParams
    elseif UIHelper.GetSelected(self.TogDemo) then
        if self:IsFilterSettingsChanged(self.tbTempParams) then
            if self.bDefaultParams then
                self.bDefaultParams = false
            elseif self.bSettingDefaultParams then
                self.bDefaultParams = true
            end
        end
        if self.gLastSelectCell and not self.gLastSelectCell.nPresetIndex then
            self.gLastSelectCell:SetModifyState(not self.bDefaultParams)
        end
    end
end

function UIAtmosphere:ResetFilterSettings(tbParams)
    self:UpdateFilterCache(tbParams)
    self:UpdateFilterSettingPanel()
end

function UIAtmosphere:GetFilterSettings()
    local tbFilterSettings = {}
    for k, v in pairs(self.tbParamsSlider) do
        tbFilterSettings[v.nType] = SelfieData.tbFilterCacheInfo[v.nType]
    end
    return tbFilterSettings
end

-- 约等于
local function approx_equal(a, b, epsilon)
    epsilon = epsilon or 1e-6  -- 默认误差范围
    if a == nil and b == nil then
        return true
    end
    if a == nil or b == nil then
        return false
    end
    return math.abs(a - b) < epsilon
end

function UIAtmosphere:IsFilterSettingsChanged(tbFilterSettings)
    for k, v in pairs(self.tbParamsSlider) do
        if tbFilterSettings and not approx_equal(tbFilterSettings[v.nType], SelfieData.tbFilterCacheInfo[v.nType]) then
            return true
        end
    end
    return false
end

function UIAtmosphere:UpdateWeatherPanel()
    for _, scripts in ipairs(self.tbAtmosphereScripts) do
        scripts:ShowSelectState(scripts.szName == self.szTime)
    end
end

function UIAtmosphere:SelectWeather()
    local szEnvPreset = self.tAtmosphereParams[self.szTime] and self.tAtmosphereParams[self.szTime][self.szWeather] or ""
    if self.szEnvPreset ~= szEnvPreset then
        local dwMapID = g_pClientPlayer.GetMapID()
        local nDofX, nDofY, nDofZ, nDofW = KG3DEngine.GetPostRenderDoFParam()
        SelfieData.tbMapParams = {
            szTime = self.szTime,
            szWeather = self.szWeather
        }
        rlcmd("set user env preset " .. szEnvPreset)
        self.szEnvPreset = szEnvPreset
    end
end

function UIAtmosphere:UpdateUIState(bFilterPage, bPresetPage)
    if bFilterPage == nil then
        bFilterPage = UIHelper.GetSelected(self.TogDemo)
    end
    if bPresetPage == nil then
        bPresetPage = UIHelper.GetSelected(self.TogDemo_Self)
    end

    local bFilterEmpty = bFilterPage and table.is_empty(self.tbFilterScripts or {})
    local bPresetEmpty = bPresetPage and table.is_empty(self.tbPresetScript or {})
    UIHelper.SetVisible(self.WidgetEmpty, bFilterEmpty or bPresetEmpty)

    UIHelper.SetVisible(self.BtnSave, bFilterPage or self.bPresetEditMode)
    UIHelper.SetVisible(self.BtnDemoSetting, bPresetPage and not self.bPresetEditMode)

    UIHelper.SetString(self.LabelSave, self.bPresetEditMode and "退出编辑" or "存为预设")

    local bSelFilter = self.nLastSelectFilter == SelfieData.nCurSelectFilterIndex and SelfieData.nCurSelectPresetIndex == 0
    local bSelPreset = SelfieData.nCurSelectPresetIndex > 0
    local bBtnEnable = (bFilterPage and bSelFilter) or (bPresetPage and bSelPreset)
    UIHelper.SetButtonState(self.BtnSave, (bBtnEnable or self.bPresetEditMode) and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetButtonState(self.BtnApply, bBtnEnable and BTN_STATE.Normal or BTN_STATE.Disable)

    UIHelper.LayoutDoLayout(self.WidgetAnchorButton)
end

function UIAtmosphere:UpdateInfo()
    self.szWeather = "" -- 暂时没有天气
    self.bPresetEditMode = false

    UIHelper.RemoveAllChildren(self.LayoutCameraFilterOption)
    UIHelper.RemoveAllChildren(self.LayoutAtmosphere)
    UIHelper.RemoveAllChildren(self.LayoutCameraSetting)
    UIHelper.SetSelected(self.TogDemo, true)

    if self.WidgetJoystick then
        UIHelper.AddPrefab(PREFAB_ID.WidgetPerfabJoystick, self.WidgetJoystick)
    end

    self.tbParamsSlider = {}
    for i, v in ipairs(tbBasFilterContent) do
        local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetSliderCameraSetting , self.LayoutCameraSetting)
        cell:OnEnter(v.nType , v.szName , v.tHideIndex, true)

        local tFuncInfo = SelfieData.GetFilterSliderFuncInfoByParamID(i)
        local tData = tFuncInfo and tFuncInfo.tData
        if tData then
            local nMinValue = tData[3] or 0
            local nUnitValue = math.pow(10, -tData[1])
            cell:SetSliderUnitValue(nUnitValue)
            cell:SetMinPercent(nMinValue)
            cell:SetMaxPercent(tData[2])
        end
        table.insert(self.tbParamsSlider, cell)
    end

    local tFilterParams = Table_GetAllOutsideFilterParams()

    self.tbFilterScripts = {}
    for i, v in ipairs(tFilterParams) do
        local node = UIHelper.AddPrefab(PREFAB_ID.WidgetCameraFilterOption, self.LayoutCameraFilterOption)
        node:UpdateInfo(v, function(nFilterIndex, cellNode)
            self:SelectFilter(nFilterIndex, cellNode)
        end, function()
            self:ToggleFilterSettingPanel(true)
        end, function()
            self.bDefaultParams = true
            self:ResetFilterSettings() -- Reset DefaultValue
            node:SetModifyState(false)
        end)
        table.insert(self.tbFilterScripts, node)
        local tbCustomParams = Storage.FilterParam.tbCustomPresets[Storage.FilterParam.nPresetIndex]
        if v.nLogicIndex == Storage.FilterParam.nFilterIndex and not tbCustomParams then
            node:ShowSelectState(true)
            self:SelectFilter(Storage.FilterParam.nFilterIndex, node)
            UIHelper.SetSelected(self.TogDemo, true)
            UIHelper.SetSelected(self.TogDemo_Self, false)
        end
    end

    self:UpdateCustomPresets()

    self.tbAtmosphereScripts = {}
    local nMapID = g_pClientPlayer.GetMapID()
    SelfieData.tbMapParams = Storage.FilterParam.tbMapParams[nMapID]
    if SelfieData.tbMapParams then
        self.szTime = SelfieData.tbMapParams.szTime
        self.szWeather = SelfieData.tbMapParams.szWeather or ""
    end

    self.tAtmosphereParams = Table_GetFilterAtmosphere(nMapID)
    local tTimeList = Table_GetFilterAtmosphereTimeList(nMapID)
    if tTimeList then
        UIHelper.SetVisible(self.WidgetBg, true)
        UIHelper.SetVisible(self.ImgBg2, false)

        for i, node in ipairs(self.tbTogAtmosphere) do
            local script = UIHelper.GetBindScript(node)
            local szTime = tTimeList[i]
            if szTime then
                script:UpdateInfo(szTime, function(szTime, bSelected)
                    self.szTime = bSelected and szTime or "INVALID"
                    self:UpdateWeatherPanel()
                    self:SelectWeather()
                end)
                table.insert(self.tbAtmosphereScripts, script)
            else
                UIHelper.SetVisible(script.LabelNormal, false)
                UIHelper.SetVisible(script.ImgAtmosphere, true)
                UIHelper.SetEnable(node, false)
            end
        end
    else
        UIHelper.SetVisible(self.WidgetBg, false)
        UIHelper.SetVisible(self.ImgBg2, true)
    end
    self:UpdateWeatherPanel()

    self:UpdateUIState()
    local tbParamsBefore = self:GetFilterSettings()
    self:UpdateFilterCache(Storage.FilterParam.tbParams)
    self:UpdateParamsSlider()
    self.bDefaultParams = not self:IsFilterSettingsChanged(tbParamsBefore)
    if self.gLastSelectCell and not self.gLastSelectCell.nPresetIndex then
        self.gLastSelectCell:SetModifyState(not self.bDefaultParams)
    end

    -- 删除customdata后刷一下
    if IsTableEmpty(Storage.FilterParam.tbParams) then
        SelfieData.SaveFilterCacheInfoToStorage()
    end

    UIHelper.LayoutDoLayout(self.LayoutCameraFilterOption)
    UIHelper.LayoutDoLayout(self.LayoutAtmosphere)
    UIHelper.LayoutDoLayout(self.LayoutCameraSetting)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCameraFilter)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewMyDemo)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCameraFilterSetting)
end

function UIAtmosphere:UpdateCustomPresets()
    if self.gLastSelectCell and self.gLastSelectCell.nPresetIndex then
        self.gLastSelectCell = nil
    end

    UIHelper.RemoveAllChildren(self.LayoutMyDemo)
    self.tbPresetScript = {}
    for i, tbCustomParams in ipairs(Storage.FilterParam.tbCustomPresets) do
        local nPresetIndex = i
        local nFilterIndex = tbCustomParams.nFilterIndex
        local tbParams = SelfieData.GetFilterParamsByFilterIndex(nFilterIndex)
        if tbParams then
            local node = UIHelper.AddPrefab(PREFAB_ID.WidgetCameraFilterOption, self.LayoutMyDemo)
            node.nPresetIndex = nPresetIndex
            node:UpdatePresetInfo(tbParams, tbCustomParams, function(nFilterIndex, cellNode)
                --clickCallback
                self:SelectPreset(nPresetIndex, cellNode, tbCustomParams)
            end, function()
                -- editorCallback
                self:ToggleFilterSettingPanel(true)
            end, function()
                -- deleteCallback
                local dialog = UIHelper.ShowConfirm("是否确认删除预设？", function()
                    table.remove(Storage.FilterParam.tbCustomPresets, nPresetIndex)
                    Storage.FilterParam.Dirty()
                    if SelfieData.nCurSelectPresetIndex == nPresetIndex then
                        SelfieData.nCurSelectPresetIndex = 0
                        for k, v in pairs(self.tbFilterScripts) do
                            if v.nFilterIndex == nFilterIndex then
                                v:ShowSelectState(true)
                                self:SelectFilter(nFilterIndex, v)
                                break
                            end
                        end
                    elseif SelfieData.nCurSelectPresetIndex > nPresetIndex then
                        SelfieData.nCurSelectPresetIndex = SelfieData.nCurSelectPresetIndex - 1
                    end
                    if Storage.FilterParam.nPresetIndex == nPresetIndex then
                        Storage.FilterParam.nPresetIndex = 0
                        SelfieData.SaveFilterCacheInfoToStorage() -- ApplyFilterCache
                    elseif Storage.FilterParam.nPresetIndex > nPresetIndex then
                        --删除后，后面的往前移一位
                        Storage.FilterParam.nPresetIndex = Storage.FilterParam.nPresetIndex - 1
                    end
                    TipsHelper.ShowNormalTip("预设已删除")
                    self:UpdateCustomPresets()
                end)
            end, function()
                -- renameCallback
                local editBox = UIMgr.Open(VIEW_ID.PanelPromptPop, tbCustomParams.szName, "预设名", function(szText)
                    if string.is_nil(szText) then
                        TipsHelper.ShowNormalTip("预设名不能为空")
                        return
                    end
                    if not TextFilterCheck(UIHelper.UTF8ToGBK(szText)) then --过滤文字
                        TipsHelper.ShowNormalTip("您输入的备注名中含有敏感字词")
                        return
                    end
                    Storage.FilterParam.tbCustomPresets[nPresetIndex].szName = szText
                    Storage.FilterParam.Dirty()
                    TipsHelper.ShowNormalTip("预设名修改成功")
                    self:UpdateCustomPresets()
                end)
                editBox:SetTitle("预设命名")
                editBox:SetMaxLength(6)
            end)
            node:SetEditMode(self.bPresetEditMode)
            table.insert(self.tbPresetScript, node)
            -- 外部可能修改使用的nFilterIndex，若对不上也不算选中
            if nPresetIndex == SelfieData.nCurSelectPresetIndex and nFilterIndex == SelfieData.nCurSelectFilterIndex then
                node:ShowSelectState(true)
                self:SelectPreset(nPresetIndex, node, tbCustomParams)
                UIHelper.SetSelected(self.TogDemo_Self, true)
                UIHelper.SetSelected(self.TogDemo, false)
            end
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutMyDemo)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewMyDemo)

    self:UpdateUIState()
    self:UpdatePresetCount()
end

function UIAtmosphere:UpdatePresetCount()
    local presetCntStr = string.format("预设\n(%d/%d)", #Storage.FilterParam.tbCustomPresets, MAX_PRESET)
    UIHelper.SetString(self.LabelDemo_Self, presetCntStr)
    UIHelper.SetString(self.LabelSelectDemo_Self, presetCntStr)
end

function UIAtmosphere:UpdatePresetEditMode()
    for k, v in pairs(self.tbPresetScript) do
        v:SetEditMode(self.bPresetEditMode)
    end
end

function UIAtmosphere:SavePreset(szName, nPresetIndex, fnCallback)
    if string.is_nil(szName) then
        local editBox = UIMgr.Open(VIEW_ID.PanelPromptPop, "新预设", "预设名", function(szText)
            if string.is_nil(szText) then
                TipsHelper.ShowNormalTip("预设名不能为空")
                return
            end
            if not TextFilterCheck(UIHelper.UTF8ToGBK(szText)) then --过滤文字
                TipsHelper.ShowNormalTip("您输入的备注名中含有敏感字词")
                return
            end
            self:SavePreset(szText, nPresetIndex, fnCallback)
        end)
        editBox:SetTitle("预设命名")
        editBox:SetMaxLength(6)
        return
    end

    SelfieData.SaveAndApplyCustomPreset(szName, nPresetIndex)
    SelfieData.SaveFilterCacheInfoToStorage()
    UIHelper.SetSelected(self.TogDemo_Self, true)
    TipsHelper.ShowNormalTip("预设已保存并应用")
    self:UpdateCustomPresets()

    if fnCallback then
        fnCallback()
    end
end

function UIAtmosphere:OverridePreset(fnCallback)
    UIMgr.Open(VIEW_ID.PanelAtmosphereSlefDemoList, SelfieData.nCurSelectPresetIndex, function(nPresetIndex)
        local tbCustomParams = Storage.FilterParam.tbCustomPresets[nPresetIndex]
        local szName = tbCustomParams and tbCustomParams.szName
        self:SavePreset(szName, nPresetIndex, fnCallback)
    end, function()
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCameraFilter)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewMyDemo)
    end)
end

function UIAtmosphere:CloseView()
    if self.bShowSetting then
        self:ResetFilterSettings(self.tbTempParams)
        self:ToggleFilterSettingPanel(false)
    end

    local bFilterChanged = Storage.FilterParam.nFilterIndex ~= SelfieData.nCurSelectFilterIndex
    local bPresetChanged = Storage.FilterParam.nPresetIndex ~= SelfieData.nCurSelectPresetIndex
    local bParamsChanged = self:IsFilterSettingsChanged(Storage.FilterParam.tbParams)

    local nMapID = g_pClientPlayer and g_pClientPlayer.GetMapID()
    local tStorageWeather = nMapID and Storage.FilterParam.tbMapParams[nMapID] or {}
    local tCurWeather = SelfieData.tbMapParams or {}
    local bWeatherChanged = not IsTableEqual(tStorageWeather, tCurWeather)

    if bFilterChanged or bPresetChanged or bParamsChanged or bWeatherChanged then
        local dialog = UIHelper.ShowConfirm("当前滤镜未保存，是否确认退出", function()
            SelfieData.ResetFilterFromStorage(true)
            UIMgr.Close(self)
        end)
        dialog:SetConfirmButtonContent("不保存并退出")
    else
        UIMgr.Close(self)
    end
end

function UIAtmosphere:OnExit()
    UIMutexMgr.SetCanCloseTopSidePageView(true)
end

return UIAtmosphere