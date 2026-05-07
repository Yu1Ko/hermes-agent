-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UISelfieCameraSettingSlider
-- Date: 2023-05-05 09:54:58
-- Desc: 幻境云图 -- 设置Slider模板
-- ---------------------------------------------------------------------------------

local UISelfieCameraSettingSlider = class("UISelfieCameraSettingSlider")
local _BOKEH_SHAPE_TEXT =
{
	[0] = {1, g_tStrings.STR_SELFIE_BOKEH_SHAPE_4},
	[1] = {3, g_tStrings.STR_SELFIE_BOKEH_SHAPE_6},
	[2] = {4, g_tStrings.STR_SELFIE_BOKEH_SHAPE_8},
	[3] = {2, g_tStrings.STR_SELFIE_BOKEH_SHAPE_0},
}
local _BOKEH_BRIGHTNESS_LOGIC_MIN = 2
function UISelfieCameraSettingSlider:OnEnter(nType , szName , tHideIndex, bStore)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szName = szName
    self.nType = nType
    self.tHideIndex = tHideIndex
    self.bStore = bStore
    self:UpdateInfo()
end

function UISelfieCameraSettingSlider:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISelfieCameraSettingSlider:BindUIEvent()
    UIHelper.BindUIEvent(self.Slider , EventType.OnChangeSliderPercent , function (SliderEventType, nSliderEvent)
        self.bIsExeFunc = false
       -- self.bIsExeFunc = (nSliderEvent == ccui.SliderEventType.slideBallDown or nSliderEvent == ccui.SliderEventType.slideBallUp)
        if  nSliderEvent == ccui.SliderEventType.percentChanged
            or nSliderEvent == ccui.SliderEventType.slideBallDown
            or nSliderEvent == ccui.SliderEventType.slideBallUp then
            self.bIsExeFunc = true
            self:UpdateSliderValue()
        end
    end)
end

function UISelfieCameraSettingSlider:RegEvent()
    Event.Reg(self, EventType.On_UI_OpenAdvancedDof, function ()
        if  self.nType == Selfie_BaseSettingType.BokehShape or
            self.nType == Selfie_BaseSettingType.BokehSize or
            self.nType == Selfie_BaseSettingType.BokehBrightness or
            self.nType == Selfie_BaseSettingType.BokehFalloff then
                self:_UpdateAdvancedState()
        end 
    end)
    Event.Reg(self, EventType.OnCameraCaptureStateChanged, function(nState)
        if self.nType == Selfie_BaseSettingType.ModelBrightness then
            self:_setModelBrightness()
        elseif self.nType == Selfie_BaseSettingType.HeadingAngle then
            self:_setHeadingAngle()
        elseif self.nType == Selfie_BaseSettingType.AltitudeAngle then
            self:_setAltitudeAngle()
        end
    end)

    Event.Reg(self, EventType.OnSelfieWindSwitchEnable, function (bEnable)
        if  self.nType == Selfie_BaseSettingType.WindVecX or
            self.nType == Selfie_BaseSettingType.WindVecY or
            self.nType == Selfie_BaseSettingType.WindVecZ or 
            self.nType == Selfie_BaseSettingType.WindFrequency or
            self.nType == Selfie_BaseSettingType.WindStrength then
            self:SetCanSelect(bEnable,"需要开启角色风场")
        end
    end)

    Event.Reg(self, EventType.OnSelfieClothWindResetData, function (bEnable)
        if  self.nType == Selfie_BaseSettingType.WindVecX then
            self:ResetWindVecX()
        elseif self.nType == Selfie_BaseSettingType.WindVecY then
            self:ResetWindVecY()
        elseif self.nType == Selfie_BaseSettingType.WindVecZ then
            self:ResetWindVecZ()
        elseif self.nType == Selfie_BaseSettingType.WindFrequency then
            self:ResetWindFrequency()
        elseif self.nType == Selfie_BaseSettingType.WindStrength then
            self:ResetWindStrength()
        end
    end)
end

function UISelfieCameraSettingSlider:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISelfieCameraSettingSlider:UpdateVisible(nIndex)
    if self.tHideIndex and table.contain_value(self.tHideIndex , nIndex) then
        UIHelper.SetVisible(self._rootNode, false)
    else
        UIHelper.SetVisible(self._rootNode, true)
    end
end


function UISelfieCameraSettingSlider:UpdateInfo()
    UIHelper.SetString(self.LabelName , self.szName)
    UIHelper.SetString(self.LabelProgress , 0)
    self.nMinPercent = 0
    self.nMinLimit = 0
    self.nUnitValue = 1
    self.bIsExeFunc = false
    if self.nType == Selfie_BaseSettingType.AngleSize then
        self:_setAngleSize()
    elseif self.nType == Selfie_BaseSettingType.FouceDistance then
        self:_setFouceDistance()
    elseif self.nType == Selfie_BaseSettingType.DOF then
        self:_setDOF()
    elseif self.nType == Selfie_BaseSettingType.DOFDegree then
        self:_setDOFDegree()
    elseif self.nType == Selfie_BaseSettingType.BokehShape then
        self:_setBokehShape()
        self:_UpdateAdvancedState()
    elseif self.nType == Selfie_BaseSettingType.BokehSize then
        self:_setBokehSize()
        self:_UpdateAdvancedState()
    elseif self.nType == Selfie_BaseSettingType.BokehBrightness then
        self:_setBokehBrightness()
        self:_UpdateAdvancedState()
    elseif self.nType == Selfie_BaseSettingType.BokehFalloff then
        self:_setBokehFalloff()
        self:_UpdateAdvancedState()
    elseif self.nType == Selfie_BaseSettingType.ModelBrightness then
        self:_setModelBrightness()
    elseif self.nType == Selfie_BaseSettingType.HeadingAngle then
        self:_setHeadingAngle()
    elseif self.nType == Selfie_BaseSettingType.AltitudeAngle then
        self:_setAltitudeAngle()
    elseif self.nType == Selfie_BaseSettingType.WindVecX then   
        self:ResetWindVecX()
        self:SetCanSelect(false,"需要开启角色风场")
    elseif self.nType == Selfie_BaseSettingType.WindVecY then   
        self:ResetWindVecY()
        self:SetCanSelect(false,"需要开启角色风场")
    elseif self.nType == Selfie_BaseSettingType.WindVecZ then   
        self:ResetWindVecZ()
        self:SetCanSelect(false,"需要开启角色风场")
    elseif self.nType == Selfie_BaseSettingType.WindStrength then   
        self:ResetWindStrength()
        self:SetCanSelect(false,"需要开启角色风场")
    elseif self.nType == Selfie_BaseSettingType.WindFrequency then   
        self:ResetWindFrequency()
        self:SetCanSelect(false,"需要开启角色风场")
    end
end

function UISelfieCameraSettingSlider:UpdateSliderValue(nSlidervalue)
    if nSlidervalue then -- 兼容导入数据时先改值再刷新的情况
        self.sliderValue = nSlidervalue
        local sliderPercent = self.sliderValue - self.nMinPercent
        UIHelper.SetProgressBarPercent(self.Slider, sliderPercent)
        UIHelper.SetProgressBarPercent(self.ImgLeftMargin , sliderPercent*100 / self.nMaxPercent)
    else
        local sliderPercent =  UIHelper.GetProgressBarPercent(self.Slider)
        self.sliderValue = sliderPercent + self.nMinPercent
        UIHelper.SetProgressBarPercent(self.ImgLeftMargin , sliderPercent*100 / self.nMaxPercent)
    end

    if self.nType == Selfie_BaseSettingType.AngleSize then
        SelfieData.tSelfieCamera.nWidAngle = self.sliderValue
        self:_updateAngleSize()
    elseif self.nType == Selfie_BaseSettingType.FouceDistance then
        SelfieData.tSelfieCamera.nDistanceOfFocus = self.sliderValue
        self:_updateFouceDistance()
    elseif self.nType == Selfie_BaseSettingType.DOF then
        SelfieData.tSelfieCamera.nDepthOfField = self.sliderValue
        self:_updateDOF()
    elseif self.nType == Selfie_BaseSettingType.DOFDegree then
        SelfieData.tSelfieCamera.nDepthOfFieldDegree = self.sliderValue
        self:_updateDOFDegree()
    elseif self.nType == Selfie_BaseSettingType.BokehShape then
        SelfieData.tSelfieCamera.nBokehShape = self.sliderValue
        self:_updateBokehShape()
    elseif self.nType == Selfie_BaseSettingType.BokehSize then
        SelfieData.tSelfieCamera.nBokehSize = self.sliderValue
        self:_updateBokehSize()
    elseif self.nType == Selfie_BaseSettingType.BokehBrightness then
        SelfieData.tSelfieCamera.nBokehBrightness = self.sliderValue
        self:_updateBokehBrightness()
    elseif self.nType == Selfie_BaseSettingType.BokehFalloff then
        SelfieData.tSelfieCamera.nBokehFalloff = self.sliderValue
        self:_updateBokehFalloff()
    elseif self.nType == Selfie_BaseSettingType.ModelBrightness then
        SelfieData.tSelfieCamera.nModelBrightness = self.sliderValue
        self:_updateModelBrightness()
    elseif self.nType == Selfie_BaseSettingType.HeadingAngle then
        SelfieData.tSelfieCamera.nHeadingAngle = self.sliderValue
        self:_updateHeadingAngle()
    elseif self.nType == Selfie_BaseSettingType.AltitudeAngle then
        SelfieData.tSelfieCamera.nAltitudeAngle = self.sliderValue
        self:_updateAltitudeAngle()
    elseif self.nType == Selfie_BaseSettingType.WindVecX then   
        SelfieData.Wind_CurrentData.nX = self.sliderValue
        SelfieData.SetClothWind()
    elseif self.nType == Selfie_BaseSettingType.WindVecY then   
        SelfieData.Wind_CurrentData.nY = self.sliderValue
        SelfieData.SetClothWind()
    elseif self.nType == Selfie_BaseSettingType.WindVecZ then   
        SelfieData.Wind_CurrentData.nZ = self.sliderValue
        SelfieData.SetClothWind()
    elseif self.nType == Selfie_BaseSettingType.WindFrequency then   
        SelfieData.Wind_CurrentData.nFrequency = self.sliderValue
        SelfieData.SetClothWind()
    elseif self.nType == Selfie_BaseSettingType.WindStrength then   
        SelfieData.Wind_CurrentData.nStrength = self.sliderValue
        SelfieData.SetClothWind()
    else
        SelfieData.SetSelfieFuncInfoByTypeID(self.nType, self.sliderValue * self.nUnitValue)
    end
    local bShowHideStr = false
    if self.nType == Selfie_BaseSettingType.DOF and self.sliderValue == self.nMaxDof then
        bShowHideStr = true
    end

    self.sliderValue = self.sliderValue * self.nUnitValue

    SelfieData.SetFilterCacheInfo(self.nType , self.sliderValue)

    if bShowHideStr then
        UIHelper.SetString(self.LabelProgress , "关闭")
    else
        UIHelper.SetString(self.LabelProgress , self.sliderValue)
    end

    if self.nType == Selfie_BaseSettingType.BokehShape then
        UIHelper.SetString(self.LabelProgress , _BOKEH_SHAPE_TEXT[self.sliderValue][2])
    end
    if self.onSliderChangeCallback then
        self.onSliderChangeCallback(self.sliderValue)
    end
end

function UISelfieCameraSettingSlider:SetSliderUnitValue(nUnitValue)
    self.nUnitValue = nUnitValue
end

function UISelfieCameraSettingSlider:SetSliderValue(nPercent)
    local sliderValue = (nPercent - self.nMinLimit) / self.nUnitValue
    sliderValue = sliderValue + 0.0000000001  -- double精度在13-14位
    UIHelper.SetProgressBarPercent(self.Slider,  sliderValue)
end

function UISelfieCameraSettingSlider:SetMaxPercent(nPercent , bFill)
    if not bFill then
        self.nMaxPercent = (nPercent - self.nMinLimit) /self.nUnitValue
    else
        self.nMaxPercent = nPercent
    end

    UIHelper.SetMaxPercent(self.Slider ,self.nMaxPercent)
end

function UISelfieCameraSettingSlider:SetMinPercent(nPercent)
    self.nMinLimit = nPercent
    self.nMinPercent = nPercent/self.nUnitValue
end

function UISelfieCameraSettingSlider:SetSliderChangeCallback(callback)
    self.onSliderChangeCallback = callback
end

function UISelfieCameraSettingSlider:SetCanSelect(bCanSelect,szTip)
    UIHelper.SetEnable(self.Slider,bCanSelect)
    UIHelper.SetCascadeColorEnabled(self._rootNode, true)
    UIHelper.SetColor(self._rootNode , bCanSelect and cc.c3b(255, 255, 255) or cc.c3b(155, 155, 155))
end

function UISelfieCameraSettingSlider:SetEnableState(bEnable)
    UIHelper.SetEnable(self.Slider , bEnable) 
    UIHelper.SetCascadeColorEnabled(self._rootNode, true)
    UIHelper.SetVisible(self.ImgLeftMargin , bEnable)
    UIHelper.SetColor(self._rootNode , bEnable and cc.c3b(255, 255, 255) or cc.c3b(155, 155, 155))
end

function UISelfieCameraSettingSlider:_setAngleSize()
    local t3DEngineCaps = VideoData.Get3DEngineOptionCaps()
    self:SetMaxPercent(math.floor((t3DEngineCaps.fMaxCameraAngle - t3DEngineCaps.fMinCameraAngle) / math.pi * 180) , true)
    local tSelfieSave = SelfieData.GetSelfieSave()
    local tReservedData = SelfieData.GetReservedData()
    if tSelfieSave.nVersion == SelfieData.SAVE_DATA_VERSION then
        UIHelper.SetProgressBarPercent(self.Slider , tSelfieSave.nWidAngle)
        self.sliderValue = tSelfieSave.nWidAngle + self.nMinPercent
    else
        UIHelper.SetProgressBarPercent(self.Slider ,t3DEngineCaps.fMinCameraAngle)
        self.sliderValue = t3DEngineCaps.fMinCameraAngle + self.nMinPercent
    end
end

function UISelfieCameraSettingSlider:_updateAngleSize()
    local t3DEngineCaps = VideoData.Get3DEngineOptionCaps()
    local fCameraFov = t3DEngineCaps.fMinCameraAngle + self.sliderValue * math.pi / 180
    CameraMgr.SetCameraFov(fCameraFov)
    self.sliderValue = math.floor(self.sliderValue + t3DEngineCaps.fMinCameraAngle / math.pi * 180)
end

function UISelfieCameraSettingSlider:_setFouceDistance()
    self:SetMaxPercent(MAIN_SCENE_DOF_DIST_MAX - MAIN_SCENE_DOF_DIST_MIN , true)
    UIHelper.SetProgressBarPercent(self.Slider , SelfieData.GetDistanceOfFocus() - MAIN_SCENE_DOF_DIST_MIN)
    self.sliderValue = SelfieData.GetDistanceOfFocus() - MAIN_SCENE_DOF_DIST_MIN + self.nMinPercent
end

function UISelfieCameraSettingSlider:_updateFouceDistance()
    local nFocus = self.sliderValue + MAIN_SCENE_DOF_DIST_MIN
    nFocus = math.min(MAIN_SCENE_DOF_DIST_MAX, math.max(nFocus, MAIN_SCENE_DOF_DIST_MIN))
    if self.bIsExeFunc then
        CameraMgr.SetPostRenderDoFParam(nFocus)
    end

    self.sliderValue = nFocus
end

function UISelfieCameraSettingSlider:_setDOF()
   if Platform.IsWindows() or Platform.IsMac() then
       self.nMaxDof =  SelfieData.DOF_PARAM_MAX.DOF.WIN
   else
        local nRecommendQualityType = QualityMgr.GetRecommendQualityType()
        self.nMaxDof = SelfieData.DOF_PARAM_MAX.DOF.MOBILE[nRecommendQualityType] or SelfieData.DOF_PARAM_MAX.DOF.MOBILE[GameQualityType.EXTREME_HIGH]
   end
    self:SetMaxPercent(self.nMaxDof , true)
    local tSelfieSave = SelfieData.GetSelfieSave()
    if tSelfieSave.nVersion == SelfieData.SAVE_DATA_VERSION then
        UIHelper.SetProgressBarPercent(self.Slider , tSelfieSave.nDepthOfField)
        self.sliderValue = tSelfieSave.nDepthOfField + self.nMinPercent 
    else
        UIHelper.SetProgressBarPercent(self.Slider , self.nMaxDof)
        self.sliderValue = self.nMaxDof + self.nMinPercent 
    end
end

function UISelfieCameraSettingSlider:_updateDOF()
   local tbEngineOption = KG3DEngine.GetMobileEngineOption()
    if self.sliderValue == self.nMaxDof then
        tbEngineOption.bEnableDof = false
    else
        tbEngineOption.bEnableDof = true
    end
    KG3DEngine.SetMobileEngineOption(tbEngineOption)
    if self.bIsExeFunc then
        CameraMgr.SetPostRenderDoFParam(nil, self.sliderValue)
    end
end

function UISelfieCameraSettingSlider:_setDOFDegree()
    self.nDofDegreeMin = KG3DEngine.GetPostRenderDofGatherBlurSize()
    local nRecommendQualityType = QualityMgr.GetRecommendQualityType()
    local nMaxDofDegree = SelfieData.DOF_PARAM_MAX.DOF_DEGREE[nRecommendQualityType] or SelfieData.DOF_PARAM_MAX.DOF_DEGREE[GameQualityType.EXTREME_HIGH]
    self:SetMaxPercent(nMaxDofDegree - self.nDofDegreeMin , true)
    UIHelper.SetProgressBarPercent(self.Slider , 0)
    self.sliderValue = 0 + self.nMinPercent 
end

function UISelfieCameraSettingSlider:_updateDOFDegree()
    self.sliderValue = self.sliderValue + self.nDofDegreeMin
    if self.bIsExeFunc then
        KG3DEngine.SetPostRenderDofGatherBlurSize(self.sliderValue)
    end
end

function UISelfieCameraSettingSlider:_setBokehShape()
    self:SetMaxPercent(table.get_len(_BOKEH_SHAPE_TEXT)-1)
    UIHelper.SetProgressBarPercent(self.Slider , 0)
    self.sliderValue = 0 + self.nMinPercent 
end

function UISelfieCameraSettingSlider:_setBokehSize()
    self:SetMaxPercent(SelfieData.BASE_PARAM_MAX.BOKEH_SIZE)
    UIHelper.SetProgressBarPercent(self.Slider , 0)
    self.sliderValue = 0 + self.nMinPercent 
end

function UISelfieCameraSettingSlider:_setBokehBrightness()
    self:SetMinPercent(1)
    self:SetMaxPercent(SelfieData.BASE_PARAM_MAX.BOKEH_BRIGHTNESS)
    UIHelper.SetProgressBarPercent(self.Slider , SelfieData.BASE_PARAM_MAX.BOKEH_BRIGHTNESS - 1)
    self.sliderValue = SelfieData.BASE_PARAM_MAX.BOKEH_BRIGHTNESS - 1 + self.nMinPercent 
end

function UISelfieCameraSettingSlider:_setBokehFalloff()
    self:SetSliderUnitValue(0.1)
    self:SetMaxPercent(SelfieData.BASE_PARAM_MAX.BOKEH_FALLOFF  / self.nUnitValue, true)
    UIHelper.SetProgressBarPercent(self.Slider ,SelfieData.BASE_PARAM_MAX.BOKEH_FALLOFF / self.nUnitValue)
    self.sliderValue = SelfieData.BASE_PARAM_MAX.BOKEH_FALLOFF / self.nUnitValue + self.nMinPercent 
end

function UISelfieCameraSettingSlider:_updateBokehShape()
    local nShapeIndex = _BOKEH_SHAPE_TEXT[self.sliderValue][1]
    KG3DEngine.SetPostRenderBokehShape(nShapeIndex)
end

function UISelfieCameraSettingSlider:_updateBokehSize()
    KG3DEngine.SetPostRenderBokehSize(self.sliderValue)
end

function UISelfieCameraSettingSlider:_updateBokehBrightness()
    local realValue = _BOKEH_BRIGHTNESS_LOGIC_MIN + (SelfieData.BASE_PARAM_MAX.BOKEH_BRIGHTNESS - self.sliderValue )
    KG3DEngine.SetPostRenderBokehBrightness(realValue)
end

function UISelfieCameraSettingSlider:_updateBokehFalloff()
    KG3DEngine.SetPostRenderBokehBrightness(SelfieData.BASE_PARAM_MAX.BOKEH_FALLOFF - self.sliderValue * self.nUnitValue)
end


function UISelfieCameraSettingSlider:_UpdateAdvancedState()
    UIHelper.SetEnable(self.Slider , SelfieData.bOpenAdvancedDof) 
    UIHelper.SetCascadeColorEnabled(self._rootNode, true)
    UIHelper.SetVisible(self.ImgLeftMargin , SelfieData.bOpenAdvancedDof)
    UIHelper.SetColor(self._rootNode , SelfieData.bOpenAdvancedDof and cc.c3b(255, 255, 255) or cc.c3b(155, 155, 155))
end

function UISelfieCameraSettingSlider:_setModelBrightness()
    self:SetSliderUnitValue(0.1)
    self:SetMinPercent(SelfieData.MODEL_BRIGHTNESS_MIN)
    self:SetMaxPercent(SelfieData.MODEL_BRIGHTNESS_MAX)
    local fModelBrightness = KG3DEngine.GetPostRenderFixedExposure()
    UIHelper.SetProgressBarPercent(self.Slider, (fModelBrightness - SelfieData.MODEL_BRIGHTNESS_MIN) / self.nUnitValue)
    self.sliderValue = (fModelBrightness - SelfieData.MODEL_BRIGHTNESS_MIN) / self.nUnitValue + self.nMinPercent
end

function UISelfieCameraSettingSlider:_updateModelBrightness()
    KG3DEngine.SetPostRenderFixedExposure(self.sliderValue * self.nUnitValue)
end

function UISelfieCameraSettingSlider:_setHeadingAngle()
    self:SetMinPercent(SelfieData.HEADING_ANGLE_MIN)
    self:SetMaxPercent(SelfieData.HEADING_ANGLE_MAX)
    local fHeadingAngle, fAltitudeAngle = SelfieData.GetMainLightDirection()
    if not fHeadingAngle or not  fAltitudeAngle then
        return
    end
    UIHelper.SetProgressBarPercent(self.Slider, fHeadingAngle - SelfieData.HEADING_ANGLE_MIN)
    self.sliderValue = fHeadingAngle - SelfieData.HEADING_ANGLE_MIN + self.nMinPercent
end

function UISelfieCameraSettingSlider:_updateHeadingAngle()
    local fHeadingAngle, fAltitudeAngle = SelfieData.GetMainLightDirection()
    SelfieData.SetMainLightDirection(self.sliderValue, fAltitudeAngle)
end

function UISelfieCameraSettingSlider:_setAltitudeAngle()
    self:SetMaxPercent(90, true)
    local fHeadingAngle, fAltitudeAngle = SelfieData.GetMainLightDirection()
    if not fHeadingAngle or not  fAltitudeAngle then
        return
    end
    UIHelper.SetProgressBarPercent(self.Slider, -fAltitudeAngle)
    self.sliderValue = -fAltitudeAngle + self.nMinPercent
end

function UISelfieCameraSettingSlider:_updateAltitudeAngle()
    local fHeadingAngle, fAltitudeAngle = SelfieData.GetMainLightDirection()
    SelfieData.SetMainLightDirection(fHeadingAngle, -self.sliderValue)
end

function UISelfieCameraSettingSlider:ResetVisible(bShow)
    UIHelper.SetVisible(self._rootNode,bShow)
end

function UISelfieCameraSettingSlider:ResetWindFrequency()
    self:SetMinPercent(0)
    self:SetMaxPercent(10)
    self.nUnitValue = 0.1
    SelfieData.Wind_CurrentData.nFrequency = SelfieData.Wind_DefaultData.nFrequency
    self:SetSliderValue(SelfieData.Wind_DefaultData.nFrequency)
end

function UISelfieCameraSettingSlider:ResetWindStrength()
    self:SetMinPercent(0)
    self:SetMaxPercent(100)
    SelfieData.Wind_CurrentData.nStrength = SelfieData.Wind_DefaultData.nStrength
    self:SetSliderValue(SelfieData.Wind_DefaultData.nStrength * 10)
end

function UISelfieCameraSettingSlider:ResetWindVecX()
    self:SetMinPercent(-100)
    self:SetMaxPercent(100)
    SelfieData.Wind_CurrentData.nX = SelfieData.Wind_DefaultData.nX
    self:SetSliderValue(SelfieData.Wind_DefaultData.nX)
end

function UISelfieCameraSettingSlider:ResetWindVecY()
    self:SetMinPercent(-100)
    self:SetMaxPercent(100)
    SelfieData.Wind_CurrentData.nY = SelfieData.Wind_DefaultData.nY
    self:SetSliderValue(SelfieData.Wind_DefaultData.nY)
end

function UISelfieCameraSettingSlider:ResetWindVecZ()
    self:SetMinPercent(-100)
    self:SetMaxPercent(100)
    SelfieData.Wind_CurrentData.nZ = SelfieData.Wind_DefaultData.nZ
    self:SetSliderValue(SelfieData.Wind_DefaultData.nZ)
end

function UISelfieCameraSettingSlider:SetWindCell(nValue)
    self:SetSliderValue(nValue)
end

return UISelfieCameraSettingSlider