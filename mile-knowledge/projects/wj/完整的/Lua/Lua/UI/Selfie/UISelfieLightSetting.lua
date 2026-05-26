-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UISelfieLightSetting
-- Date: 2023-06-12 11:28:02
-- Desc: 幻境云图 - 灯光设置
-- ---------------------------------------------------------------------------------
local _DEFAULT_LIGHT_PARAMS_PATH = "ui/Scheme/Setting/SelfieLights.json"
local _STR_2_LIGHT_TYPE =
{
	["Point"] = CHARACTER_LIGHT.POINT,
	["Directional"] = CHARACTER_LIGHT.DIRECTIONAL,
	["Spot"] = CHARACTER_LIGHT.POINT, -- 目前没有聚光灯，只有点光
}
local m_aAllLightData =
{
	--[nLightIndex + 1] = {nIntensity, nColorIndex, fSaturation},
}
local m_nLightCount = 8
local m_tbColorRGB = {}
local m_AllLightTransParams = {}
local m_nLightScrollMax = 300
local m_nLightScrollMin = -300
local m_nLightScrollCount = 600
local UISelfieLightSetting = class("UISelfieLightSetting")
local function l_fnSaturate(fValue)
	return math.min(math.max(fValue, 0.0), 1.0)
end

local function l_fnFloatEqual(fValue1, fValue2)
	return math.abs(fValue1-fValue2) < 0.0001
end
--- 0.0 <= r, g, b <= 1.0
--- 0.0 <= h < 360.0, 0.0 <= s, v <= 1.0
local function RGBToHSV(r, g, b)
	r = l_fnSaturate(r)
	g = l_fnSaturate(g)
	b = l_fnSaturate(b)
	local max = math.max(r, g, b)
	local min = math.min(r, g, b)
	local delta = max - min
	local h
	if l_fnFloatEqual(max, min) then
		h = 0
	else
		if l_fnFloatEqual(max, r) then
			if g >= b then
				h = 60.0 * (g-b) / delta
			else
				h = 60.0 * (g-b) / delta + 360.0
			end
		elseif l_fnFloatEqual(max, g) then
			h = 60.0 * (b-r) / delta + 120.0
		else
			h = 60.0 * (r-g) / delta + 240.0
		end
	end
	local s = l_fnFloatEqual(max, 0.0) and 0.0 or (delta / math.max(max, 0.0001))
	local v = max
	return h, s, v
end

--- 0.0 <= r, g, b <= 1.0
--- 0.0 <= h < 360.0, 0.0 <= s, v <= 1.0
local function HSVToRGB(h, s, v)
	local hr = h / 60.0
	local hi = math.floor(hr) % 6
	local f = hr - hi
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)
	local r, g, b
	if hi == 0 then
		r, g, b = v, t, p
	elseif hi == 1 then
		r, g, b = q, v, p
	elseif hi == 2 then
		r, g, b = p, v, t
	elseif hi == 3 then
		r, g, b = p, q, v
	elseif hi == 4 then
		r, g, b = t, p, v
	else
		r, g, b = v, p, q
	end

	return l_fnSaturate(r), l_fnSaturate(g), l_fnSaturate(b)
end
function UISelfieLightSetting:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
	self.bUpdate = SelfieData.Light_CurrentData.bImportPhotoData
	self.tLight = clone(SelfieData.Light_CurrentData)

    self:UpdateInfo()
    -- UILog("self.bUpdate self.tWind", self.bUpdate, self.tWind)
    if self.bUpdate then
        self:SetPhotoScript(self.tLight)
    end
end

function UISelfieLightSetting:OnExit()
	if m_aAllLightData then
		for i = 1, m_nLightCount do
			if m_aAllLightData[i] and m_aAllLightData[i][4] then
				CharacterLight.Disable(i - 1)
			end
		end
	end
	SelfieData.bOpenLightPos = false
	self:ShowAllLights(false)
    self.bInit = false
    self:UnRegEvent()
end

function UISelfieLightSetting:BindUIEvent()
    for i, v in ipairs(self.tbLightToggle) do
        UIHelper.BindUIEvent(v , EventType.OnClick , function ()
			UIHelper.SetVisible(self.tbLightToggleSelecLighttImg[self.nCurSelectLightSettingIndex],false)
			self:OnSelectLightSetting(i)
			self:UpdateLightColorSetting()
			UIHelper.SetVisible(self.tbLightToggleSelecLighttImg[i],true)
        end)
		UIHelper.SetVisible(self.tbLightToggleSelecLighttImg[i],false)
    end

    for i, v in ipairs(self.tbColorSelectToggle) do
		UIHelper.SetVisible(self.tbLightColorSelectState[i] , false)
        UIHelper.BindUIEvent(v , EventType.OnClick , function ()
            if m_aAllLightData[self.nCurSelectLightSettingIndex][4] then
				self:OnClickColor(i)
            else
                TipsHelper.ShowNormalTip(g_tStrings.STR_SELFIE_LIGHT_CANT_CHANGE_COLOR_LIGHT_OFF)
			end
        end)
    end

	UIHelper.BindUIEvent(self.BtnLightSettingSelect , EventType.OnClick , function ()
		self.bClickLightSettingSelect = not self.bClickLightSettingSelect
		UIHelper.SetVisible(self.WidgetLightSelectPanel , self.bClickLightSettingSelect)
		if self.bClickLightSettingSelect then
			UIHelper.SetSelected(self.tbLightSettingToggle[self.nCurSelectLightSettingIndex] , true)
		end
	end)

	for i, v in ipairs(self.tbLightSettingToggle) do
		UIHelper.SetSelected(v , false)
        UIHelper.BindUIEvent(v , EventType.OnClick , function ()
			self.bClickLightSettingSelect = false
			self:OnSelectLightSetting(i)
			self:UpdateLightColorSetting()
			UIHelper.SetVisible(self.WidgetLightSelectPanel , false)
        end)
    end

	UIHelper.BindUIEvent(self.WidgetLightSettingLabel, EventType.OnTouchBegan, function(btn, nX, nY)
		if m_aAllLightData[self.nCurSelectLightSettingIndex] and not m_aAllLightData[self.nCurSelectLightSettingIndex][4] then
			TipsHelper.ShowNormalTip(g_tStrings.STR_SELFIE_LIGHT_CANT_CHANGE_COLOR_LIGHT_OFF)
			return
		end
        self:UpdateLightBarPos(nX, nY)
    end)

    UIHelper.BindUIEvent(self.WidgetLightSettingLabel, EventType.OnTouchMoved, function(btn, nX, nY)
		if m_aAllLightData[self.nCurSelectLightSettingIndex] and not m_aAllLightData[self.nCurSelectLightSettingIndex][4] then
			return
		end
        self:UpdateLightBarPos(nX, nY)
    end)

	UIHelper.BindUIEvent(self.BtnRemarkSetting, EventType.OnClick, function()
        self:ResetLightSetting()
    end)

	UIHelper.SetVisible(self.ToggleLightSwitch, false)
	UIHelper.BindUIEvent(self.ToggleLightSwitch, EventType.OnClick, function()
		local lightOn = not  m_aAllLightData[self.nCurSelectLightSettingIndex][4]
        self:ToggleLightOn(self.nCurSelectLightSettingIndex ,lightOn)
		self:UpdateLightColorSettingState()
		UIHelper.SetVisible(self.tbLightToggleSelectImg[self.nCurSelectLightSettingIndex],lightOn)
		UIHelper.SetVisible(self.tbLightToggleSelecLighttImg[self.nCurSelectLightSettingIndex],lightOn)

		UIHelper.SetEnable(self.ToggleLightSwitch, false)
		Timer.Add(self, 0.5 ,function ()
			UIHelper.SetEnable(self.ToggleLightSwitch, true)
		end)
    end)


	for i, v in ipairs(self.tbLightOpenTogs) do
        UIHelper.BindUIEvent(v , EventType.OnSelectChanged , function (_,bSelected)
			--local lightOn = not  m_aAllLightData[i][4]
			self:ToggleLightOn(i ,bSelected)
			self:UpdateLightColorSettingState()
			UIHelper.SetEnable(v, false)
			Timer.Add(self, 0.5 ,function ()
				UIHelper.SetEnable(v, true)
			end)
        end)
    end


	UIHelper.SetSelected(self.ToggleLightSwitch, false)
	UIHelper.BindUIEvent(self.ToggleLightPositionSwitch , EventType.OnSelectChanged , function (_,bSelected)
		SelfieData.bOpenLightPos = bSelected
		self:ShowAllLights(bSelected)
	end)

	self.lightVecX_Script = UIHelper.GetBindScript(UIHelper.FindChildByName(self.ScrollLightSetting,"WidgetSliderCameraSettingX"))
	self.lightVecX_Script:OnEnter(Selfie_BaseSettingType.LightVecX, "灯光位置-X轴") 
	self.lightVecY_Script = UIHelper.GetBindScript(UIHelper.FindChildByName(self.ScrollLightSetting,"WidgetSliderCameraSettingY"))
	self.lightVecY_Script:OnEnter(Selfie_BaseSettingType.LightVecY, "灯光位置-Y轴") 
	self.lightVecZ_Script = UIHelper.GetBindScript(UIHelper.FindChildByName(self.ScrollLightSetting,"WidgetSliderCameraSettingZ"))
	self.lightVecZ_Script:OnEnter(Selfie_BaseSettingType.LightVecZ, "灯光位置-Z轴") 
	self.lightVecX_Script:SetSliderChangeCallback(function ()
		self:SetLightXYZ()
	end)
	self.lightVecY_Script:SetSliderChangeCallback(function ()
		self:SetLightXYZ()
	end)
	self.lightVecZ_Script:SetSliderChangeCallback(function ()
		self:SetLightXYZ()
	end)
end

function UISelfieLightSetting:RegEvent()
    Event.Reg(self, "SelfieLightPosOpen", function (nShow)
		self:ShowAllLights(SelfieData.bOpenLightPos)
	end)
	Event.Reg(self, EventType.OnCameraCaptureStateChanged, function()
		self:ShowAllLights(SelfieData.bOpenLightPos)
	end)
end

function UISelfieLightSetting:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end
function UISelfieLightSetting:Hide()

end

function UISelfieLightSetting:Open()
	self.bClickLightSettingSelect = false
	UIHelper.SetVisible(self.WidgetLightSelectPanel , false)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISelfieLightSetting:UpdateInfo()
	UIHelper.SetSelected(self.ToggleLightPositionSwitch, SelfieData.bOpenLightPos)
    for i, v in ipairs(self.tbLightToggle) do
        UIHelper.SetSelected(v , false)
    end

    for i, v in ipairs(self.tbColorSelectToggle) do
        UIHelper.SetSelected(v , false)
    end
	UIHelper.SetVisible(self.WidgetLightSelectPanel , false)
	UIHelper.SetScrollViewCombinedBatchEnabled(self.ScrollLightSetting, false)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollLightSetting)
	UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewLightSelect)

	self.lightVecX_Script:SetMinPercent(m_nLightScrollMin)
	self.lightVecY_Script:SetMinPercent(m_nLightScrollMin)
	self.lightVecZ_Script:SetMinPercent(m_nLightScrollMin)

	self.lightVecX_Script:SetMaxPercent(m_nLightScrollMax)
	self.lightVecY_Script:SetMaxPercent(m_nLightScrollMax)
	self.lightVecZ_Script:SetMaxPercent(m_nLightScrollMax)

    self:InitAllLightParams()
	self:OnSelectLightSetting(1)
	self.bClickLightSettingSelect = false
	self.nLightBarOrgiX, self.nLightBarOrgiY = UIHelper.GetPosition(self.BtnLightColorBarArea)
	self.nLightBarRadius = UIHelper.GetContentSize(self.ImgLightColorSettingNum)*0.5

	UIHelper.SetSwallowTouches(self.BtnLightSelectBg , true)
	UIHelper.SetSwallowTouches(self.WidgetLightSettingLabel , true)
	
end

function UISelfieLightSetting:OnSelectLightSetting(nLightIndex)

	if self.nCurSelectLightSettingIndex then
		if nLightIndex == self.nCurSelectLightSettingIndex then
			return
		end
		UIHelper.SetSelected(self.tbLightSettingToggle[self.nCurSelectLightSettingIndex] , false)
	end

	self.nCurSelectLightSettingIndex = nLightIndex
    self.tbAllLightConfigParams = self.tbAllLightConfigParams or Table_GetAllSelfieLightParams()
	local tConfigParams = self.tbAllLightConfigParams[nLightIndex]
	if not tConfigParams then
		LOG.ERROR("当前选择的灯光index(" .. tostring(nLightIndex) .. ")无效！")
		return
	end
    local tLightUIParams = m_aAllLightData[nLightIndex]
    self.nIntensityMin = tConfigParams.fIntensityMin
	self.nIntensityMax = tConfigParams.fIntensityMax
	m_aAllLightData[self.nCurSelectLightSettingIndex][5] = self.nIntensityMax - self.nIntensityMin
    self.nIntensityValue = tLightUIParams[1]
	local bNeedSetIntensity = false
	if self.nIntensityValue < self.nIntensityMin then
		tLightUIParams[1] = self.nIntensityMin
		self.nIntensityValue = self.nIntensityMin
		bNeedSetIntensity = true
	elseif self.nIntensityValue > self.nIntensityMax then
		tLightUIParams[1] = self.nIntensityMax
		self.nIntensityValue = self.nIntensityMax
		bNeedSetIntensity = true
	end
    if bNeedSetIntensity then
		local tParams = clone(self.m_aAllLightDefaultParams[nLightIndex])
		tParams.Intensity = self.nIntensityValue
		CharacterLight.SetParam(nLightIndex - 1, tParams)
	end
    local aColorList = tConfigParams.aColorList
	for i, tRGB in ipairs(aColorList) do
        m_tbColorRGB[i] = {r = tRGB[1], g = tRGB[2], b = tRGB[3]}
	end

	local bTranslation 	= not self.m_aAllLightDefaultParams[nLightIndex].bTranslation
	if bTranslation then
		local tTranslation 	= self.m_aAllLightDefaultParams[nLightIndex].Translation
		if not IsTableEmpty(m_AllLightTransParams) and m_AllLightTransParams[nLightIndex] then
			if not IsTableEmpty(m_AllLightTransParams[nLightIndex]) then
				tTranslation = m_AllLightTransParams[nLightIndex]
			end
		end

		self.lightVecX_Script:SetSliderValue(tTranslation.x)
		self.lightVecY_Script:SetSliderValue(tTranslation.y)
		self.lightVecZ_Script:SetSliderValue(tTranslation.z)
	end

	self.nSaturationMin = tConfigParams.fSaturationMin
	self.nSaturationMax = tConfigParams.fSaturationMax
	m_aAllLightData[self.nCurSelectLightSettingIndex][6] = self.nSaturationMax - self.nSaturationMin
	self.nSaturationValue = tLightUIParams[3]
	if self.nSaturationValue then
		if self.nSaturationValue < self.nSaturationMin then
			tLightUIParams[3] = self.nSaturationMin
			self.nSaturationValue = self.nSaturationMin
		elseif self.nSaturationValue > self.nSaturationMax then
			tLightUIParams[3] = self.nSaturationMax
			self.nSaturationValue = self.nSaturationMax
		end
	else
		self:OnClickColor(1)
	end
	self:UpdateVecSliderState()
end

function UISelfieLightSetting:OnClickColor(nColorIndex , bIgnoreChange)
	if self.nSelectColorIndex and self.nSelectColorIndex > 0 then
		UIHelper.SetSelected(self.tbColorSelectToggle[self.nSelectColorIndex] , false)
		UIHelper.SetVisible(self.tbLightColorSelectState[self.nSelectColorIndex] , false)
	end
    self.nSelectColorIndex = nColorIndex
    UIHelper.SetSelected(self.tbColorSelectToggle[self.nSelectColorIndex] , true)
	UIHelper.SetVisible(self.tbLightColorSelectState[self.nSelectColorIndex] , true)
	if bIgnoreChange then
		return
	end
    self:OnChangeLightColor()
end

function UISelfieLightSetting:OnChangeLightColor()
	local bNeedChangeColor = false
    local colorRGB =  m_tbColorRGB[self.nSelectColorIndex]
	local fHue, fSaturation, fValue = RGBToHSV(colorRGB.r / 255, colorRGB.g / 255, colorRGB.b / 255)
	if m_aAllLightData[self.nCurSelectLightSettingIndex].tColorSaturation[self.nSelectColorIndex] then
		fSaturation = m_aAllLightData[self.nCurSelectLightSettingIndex].tColorSaturation[self.nSelectColorIndex]
		bNeedChangeColor = true
	elseif fSaturation < self.nSaturationMin then
		fSaturation = self.nSaturationMin
		bNeedChangeColor = true
	elseif fSaturation > self.nSaturationMax then
		fSaturation = self.nSaturationMax
		bNeedChangeColor = true
	end


	local tParams = clone(self.m_aAllLightDefaultParams[self.nCurSelectLightSettingIndex])
	if bNeedChangeColor then
		local r, g, b = HSVToRGB(fHue, fSaturation, fValue)
		tParams.Color.r = r
		tParams.Color.g = g
		tParams.Color.b = b
	else
		tParams.Color.r = colorRGB.r / 255
		tParams.Color.g = colorRGB.g / 255
		tParams.Color.b = colorRGB.b / 255
	end

	tParams.Intensity = m_aAllLightData[self.nCurSelectLightSettingIndex][1] or 50

	m_aAllLightData[self.nCurSelectLightSettingIndex].tColorSaturation[self.nSelectColorIndex] = fSaturation
	m_aAllLightData[self.nCurSelectLightSettingIndex][3] = fSaturation
	m_aAllLightData[self.nCurSelectLightSettingIndex][2] = self.nSelectColorIndex
	self:ResetLightBarPos()
	CharacterLight.SetParam(self.nCurSelectLightSettingIndex-1, tParams)

	SelfieData.Light_CurrentData[self.nCurSelectLightSettingIndex] = m_aAllLightData[self.nCurSelectLightSettingIndex]
	SelfieData.Light_CurrentData[self.nCurSelectLightSettingIndex].Translation = m_AllLightTransParams[self.nCurSelectLightSettingIndex]
end

function UISelfieLightSetting:ToggleLightOn(nLightIndex , bTurnOn)
    if bTurnOn then
		CharacterLight.Enable(nLightIndex - 1)
	else
		CharacterLight.Disable(nLightIndex - 1)
	end
    m_aAllLightData[nLightIndex][4] = bTurnOn
	self.nSelectLightIndex = nLightIndex
end

function UISelfieLightSetting:InitAllLightParams()
    self.m_aAllLightDefaultParams = {}
    local szText = Lib.GetStringFromFile(_DEFAULT_LIGHT_PARAMS_PATH)
    local aAllLightParams, szErrMsg = JsonDecode(szText)
    m_nLightCount = math.min(#aAllLightParams, #Table_GetAllSelfieLightParams())
    for i = 1, m_nLightCount do
		local tLightParams = aAllLightParams[i]
		local t = self:RetrieveOneLightDefaultParams(tLightParams)
        local aAllLightConfigParams = Table_GetAllSelfieLightParams()
        local tConfigParams = aAllLightConfigParams[i]
        local aColorList = tConfigParams.aColorList
        local tFirstColor = aColorList[1]
        assert(tFirstColor)
        t.Color = {r = tFirstColor[1] / 255, g = tFirstColor[2] / 255, b = tFirstColor[3] / 255 }
        table.insert(self.m_aAllLightDefaultParams, t)

        local _logicLightIndex = i - 1

        CharacterLight.SetParam(_logicLightIndex, t)
        CharacterLight.SetBindingType(_logicLightIndex, CHARACTER_LIGHT_BINDING.CHARACTER)

        local tTransform = tLightParams.Transform
        local tDisableFlags = tTransform.Flags.Disable

        local dwTransformFlags = 0
        if tDisableFlags.Scaling then
            dwTransformFlags = BitwiseOr(dwTransformFlags, TRANSFORM.DISABLE_SCALING)
        end
        if tDisableFlags.Rotation then
            dwTransformFlags = BitwiseOr(dwTransformFlags, TRANSFORM.DISABLE_ROTATION)
        end
        if tDisableFlags.Translation then
            dwTransformFlags = BitwiseOr(dwTransformFlags, TRANSFORM.DISABLE_TRANSLATION)
        end
        CharacterLight.SetTransformFlags(_logicLightIndex, dwTransformFlags)
        if BitwiseAnd(TRANSFORM.DISABLE_TRANSLATION, dwTransformFlags) == 0 then
            local tTranslation = tTransform.Translation_Mobile
            CharacterLight.SetTranslation(_logicLightIndex, tTranslation.x, tTranslation.y, tTranslation.z)
        end
        if BitwiseAnd(TRANSFORM.DISABLE_ROTATION, dwTransformFlags) == 0 then
            local tRotation = tTransform.Rotation
            CharacterLight.SetRotation(_logicLightIndex, tRotation.x, tRotation.y, tRotation.z, tRotation.w)
        end
	end

    for nIndex = 1, m_nLightCount do
        local tParams = self.m_aAllLightDefaultParams[nIndex]
        m_aAllLightData[nIndex] = {}
        self:InitOneLightParams(m_aAllLightData[nIndex], tParams, nIndex)
    end
end

function UISelfieLightSetting:RetrieveOneLightDefaultParams(tLightParams)
	local tLightData = tLightParams.Light
	local t = {}
	local szType = tLightData.Type
	t.Type = _STR_2_LIGHT_TYPE[szType]
	t.Intensity = tLightData.Intensity
	t.CastShadow = tLightData.CastShadow
	t.Strength = tLightData.Strength
	t.DepthBias = tLightData.DepthBias
	t.TextureSize = tLightData.TextureSize
	t.NearPlane = tLightData.NearPlane
	t.bTranslation = tLightParams.Transform.Flags.Disable.Translation
	if not t.bTranslation then
		t.Translation = tLightParams.Transform.Translation_Mobile
	end
	local bForPlayer = tLightData.ForPlayer
	if type(bForPlayer) == "boolean" then
		t.ForPlayer = bForPlayer
	else
		t.ForPlayer = bForPlayer ~= 0
	end
	if szType == "Point" then
		t.Radius = tLightData.PointLight.Radius
	elseif szType == "Directional" then
		local tDirectionalData = tLightData.DirectionalLight
		t.Radius = tDirectionalData.Radius
		t.Length = tDirectionalData.Length
		t.RadialAttenuationStart = tDirectionalData.RadialAttenuationStart
		t.AxialAttenuationStart = tDirectionalData.AxialAttenuationStart
	elseif szType == "Spot" then
		--local tSpotLightData = tLightData.SpotLight
		--t.Length = tSpotLightData.Length
		--t.Cutoff = tSpotLightData.Cutoff
		t.Radius = tLightData.SpotLight.Length
	end

	return t
end

function UISelfieLightSetting:InitOneLightParams(tLightData, tParams, bReset, nColorIndex)
	tLightData[1] = tParams.Intensity
	tLightData[2] = 1
	tLightData[3] = 0.5
	if not bReset then 
		tLightData[4] = false
	end
	tLightData.tColorSaturation = {}
end

function UISelfieLightSetting:UpdateLightColorSetting()
	UIHelper.SetString(self.LabelLightSettingTitle , string.format("灯光%d设置",self.nCurSelectLightSettingIndex))
	self:OnClickColor(m_aAllLightData[self.nCurSelectLightSettingIndex][2])
	self:ResetLightBarPos()
end

function UISelfieLightSetting:UpdateLightColorSettingState()
	-- if not m_aAllLightData[self.nCurSelectLightSettingIndex][4] and self.nSelectColorIndex then
	-- 	self:OnClickColor(1)
	-- end
	self:UpdateVecSliderState()
end

function UISelfieLightSetting:UpdateLightBarPos(nX ,nY)
	local nCursorX, nCursorY = UIHelper.ConvertToNodeSpace(self.WidgetLightSettingLabel, nX, nY)
    local nDistance = kmath.len2(nCursorX, nCursorY, self.nLightBarOrgiX, self.nLightBarOrgiY)
    local nNormalizeX, nNormalizeY = kmath.normalize2(nCursorX - self.nLightBarOrgiX , nCursorY - self.nLightBarOrgiY)

	local xProgess = 0
	local yProgess = 0
	local nPosX = 0
	local nPosY = 0
    if nDistance < self.nLightBarRadius then
		nPosX = nCursorX
		nPosY = nCursorY
    else
		nPosX = self.nLightBarOrgiX + nNormalizeX * self.nLightBarRadius
		nPosY = self.nLightBarOrgiY + nNormalizeY * self.nLightBarRadius
    end

	xProgess = nPosX / self.nLightBarRadius
	yProgess = nPosY / self.nLightBarRadius
	xProgess = (1- xProgess)*0.5
	yProgess = (1+ yProgess)*0.5
	UIHelper.SetPosition(self.BtnLightColorBarArea, nPosX, nPosY)
	self:ChangeLightIntensityAndSaturation(xProgess,yProgess)
end

function UISelfieLightSetting:ResetLightBarPos()
	local fIntensity = (m_aAllLightData[self.nCurSelectLightSettingIndex][1] / m_aAllLightData[self.nCurSelectLightSettingIndex][5]) or 0.5
	local fSaturation= m_aAllLightData[self.nCurSelectLightSettingIndex][3] or 0.5
	local nCursorX = (1- fIntensity * 2)*self.nLightBarRadius
	local nCursorY = (fSaturation * 2 - 1)*self.nLightBarRadius

	local nDistance = kmath.len2(nCursorX, nCursorY, self.nLightBarOrgiX, self.nLightBarOrgiY)
    local nNormalizeX, nNormalizeY = kmath.normalize2(nCursorX - self.nLightBarOrgiX , nCursorY - self.nLightBarOrgiY)

	local nPosX = 0
	local nPosY = 0
    if nDistance < self.nLightBarRadius then
		nPosX = nCursorX
		nPosY = nCursorY
    else
		nPosX = self.nLightBarOrgiX + nNormalizeX * self.nLightBarRadius
		nPosY = self.nLightBarOrgiY + nNormalizeY * self.nLightBarRadius
    end
	UIHelper.SetPosition(self.BtnLightColorBarArea, nPosX, nPosY)
end

function UISelfieLightSetting:GetLightParams(nLightIndex)
	local fIntensity = m_aAllLightData[nLightIndex][1]
	local nColorIndex = m_aAllLightData[nLightIndex][2]
	local fSaturation = m_aAllLightData[nLightIndex][3]
	local aAllLightConfigParams = Table_GetAllSelfieLightParams()
	local tConfigParams = aAllLightConfigParams[nLightIndex]
	local tColor = tConfigParams.aColorList[nColorIndex]
	local r, g, b = tColor[1], tColor[2], tColor[3]

	if fSaturation then
		local h, s, v = RGBToHSV(r / 255, g / 255, b / 255)
		r, g, b = HSVToRGB(h, fSaturation, v)
	end

	local tParams = clone(self.m_aAllLightDefaultParams[nLightIndex])
	tParams.Intensity = fIntensity
	tParams.Color.r = r
	tParams.Color.g = g
	tParams.Color.b = b
	return tParams
end

function UISelfieLightSetting:ChangeLightIntensityAndSaturation(intensity , saturation)
	local fIntensity = self.nIntensityMin + intensity* m_aAllLightData[self.nCurSelectLightSettingIndex][5]
	local fSaturation = self.nSaturationMin + saturation
	m_aAllLightData[self.nCurSelectLightSettingIndex][1] = fIntensity
	m_aAllLightData[self.nCurSelectLightSettingIndex][3] = fSaturation
	m_aAllLightData[self.nCurSelectLightSettingIndex].tColorSaturation[self.nSelectColorIndex] = fSaturation
	local tParams = self:GetLightParams(self.nCurSelectLightSettingIndex)
	CharacterLight.SetParam(self.nCurSelectLightSettingIndex - 1, tParams)

	SelfieData.Light_CurrentData[self.nCurSelectLightSettingIndex] = m_aAllLightData[self.nCurSelectLightSettingIndex]
	SelfieData.Light_CurrentData[self.nCurSelectLightSettingIndex].Translation = m_AllLightTransParams[self.nCurSelectLightSettingIndex]
end

function UISelfieLightSetting:ResetLightSetting(bResetAll)
	if bResetAll then
		m_AllLightTransParams = {}
		for nIndex = 1, #m_aAllLightData do
			local tParams = self.m_aAllLightDefaultParams[nIndex]
			self:InitOneLightParams(m_aAllLightData[nIndex], tParams, true, nIndex)
			CharacterLight.SetParam(nIndex - 1, tParams)

			SelfieData.Light_CurrentData[nIndex] = m_aAllLightData[nIndex]
			SelfieData.Light_CurrentData[nIndex].Translation = m_AllLightTransParams[nIndex]
		end
	else
		m_AllLightTransParams[self.nCurSelectLightSettingIndex] = nil
		local tParams = self.m_aAllLightDefaultParams[self.nCurSelectLightSettingIndex]
		self:InitOneLightParams(m_aAllLightData[self.nCurSelectLightSettingIndex], tParams, true, self.nCurSelectLightSettingIndex) 
		CharacterLight.SetParam(self.nCurSelectLightSettingIndex - 1, tParams)

		SelfieData.Light_CurrentData[self.nCurSelectLightSettingIndex] = m_aAllLightData[self.nCurSelectLightSettingIndex]
		SelfieData.Light_CurrentData[self.nCurSelectLightSettingIndex].Translation = m_AllLightTransParams[self.nCurSelectLightSettingIndex]
	end
	local nLightIndex = self.nCurSelectLightSettingIndex
	self.nCurSelectLightSettingIndex = nil
	self:OnSelectLightSetting(nLightIndex)
	self:UpdateLightColorSetting()
end

function UISelfieLightSetting:SetLightXYZ()
	if m_aAllLightData[self.nCurSelectLightSettingIndex][4] then
		local nPercentX = self.lightVecX_Script.sliderValue + 0.0000000001
		local nPercentY = self.lightVecY_Script.sliderValue + 0.0000000001
		local nPercentZ = self.lightVecZ_Script.sliderValue + 0.0000000001
		if nPercentX and nPercentY and nPercentZ then
			m_AllLightTransParams[self.nCurSelectLightSettingIndex] = {
				x = nPercentX,
				y = nPercentY,
				z = nPercentZ,
			}
			CharacterLight.SetTranslation(self.nCurSelectLightSettingIndex - 1, nPercentX, nPercentY, nPercentZ)
			SelfieData.Light_CurrentData[self.nCurSelectLightSettingIndex].Translation = {
				x = nPercentX,
				y = nPercentY,
				z = nPercentZ,
			}
		end
	end
end

function UISelfieLightSetting:UpdateVecSliderState()
	local bCanSelect = m_aAllLightData[self.nCurSelectLightSettingIndex] and m_aAllLightData[self.nCurSelectLightSettingIndex][4]
	self.lightVecX_Script:SetCanSelect(bCanSelect, g_tStrings.STR_SELFIE_LIGHT_CANT_CHANGE_COLOR_LIGHT_OFF)
	self.lightVecY_Script:SetCanSelect(bCanSelect, g_tStrings.STR_SELFIE_LIGHT_CANT_CHANGE_COLOR_LIGHT_OFF)
	self.lightVecZ_Script:SetCanSelect(bCanSelect, g_tStrings.STR_SELFIE_LIGHT_CANT_CHANGE_COLOR_LIGHT_OFF)
end

function UISelfieLightSetting:ShowAllLights(bShow)
	if GetCameraCaptureState() == CAMERA_CAPTURE_STATE.Capturing then
		bShow = false
	end

	local cameraMain = UIMgr.GetViewScript(VIEW_ID.PanelCamera) or UIMgr.GetViewScript(VIEW_ID.PanelCameraVertical)
	local nLightCount = table.get_len(cameraMain.tbLocalLightNodes)
    UIHelper.SetVisible(cameraMain.WidgetLightLocal, bShow)
	if bShow then
		for i = 1, nLightCount do
			UIHelper.SetVisible(cameraMain.tbLocalLightNodes[i], false)
		end
	end
	
    if bShow then
		local nRenderFrameCount = 0
        Timer.DelTimer(self, self.nAllLightPosTimeID)
		for _, nCallID in pairs(self.m_aGetLightPosCallIDs) do
			CrossThreadCoor_Unregister(nCallID)
		end
		self.m_aGetLightPosCallIDs = {}
		self.nAllLightPosTimeID = Timer.AddFrameCycle(self, 1, function ()
			nRenderFrameCount = nRenderFrameCount + 1
            if self.m_bIsGettingAllLightPos then
				for i = 1, nLightCount do
					self:UpdateLightIconPos(cameraMain,i)
				end
				for _, nCallID in pairs(self.m_aGetLightPosCallIDs) do
					CrossThreadCoor_Unregister(nCallID)
				end
				self.m_bIsGettingAllLightPos = false
			else
				if (nRenderFrameCount % 10 == 0) then 
					for nIndex = 1, nLightCount do
						self.m_aGetLightPosCallIDs[nIndex] = CrossThreadCoor_Register(CTCT.CHARACTER_LIGHT_POS_2_SCREEN_POS, nIndex - 1)
					end
	
					self.m_bIsGettingAllLightPos = true 
				end
			end
    	end)
    else
        Timer.DelTimer(self, self.nAllLightPosTimeID)
		for _, nCallID in pairs(self.m_aGetLightPosCallIDs) do
			CrossThreadCoor_Unregister(nCallID)
		end
    end
end

function UISelfieLightSetting:UpdateLightIconPos(mainView, nIndex)
	local nTargetScreenX, nTargetScreenY, bTargetFront = CrossThreadCoor_Get(self.m_aGetLightPosCallIDs[nIndex])  
	local screenSize = UIHelper.GetScreenSize()
	local node = mainView.tbLocalLightNodes[nIndex]
	if not nTargetScreenX or not nTargetScreenY then
		UIHelper.SetVisible(node, false)
		return
	end
	UIHelper.SetVisible(node, true)
	if not bTargetFront then -- 在视野后方的让点永远显示在屏幕下方
		nTargetScreenX = screenSize.width - nTargetScreenX
		nTargetScreenY = math.abs(nTargetScreenY) + screenSize.height
	end

	local nScaleX, nScaleY = UIHelper.GetScreenToResolutionScale()
	local nTargetScreenRealX, nTargetScreenRealY = nTargetScreenX / nScaleX, nTargetScreenY / nScaleY
	local tPos = cc.Director:getInstance():convertToGL({x = nTargetScreenRealX, y = nTargetScreenRealY})
	local nX, nY = UIHelper.ConvertToNodeSpace(mainView._rootNode, tPos.x, tPos.y)
	local iconWidth, iconHeight = UIHelper.GetContentSize(node)
	local fDestX, fDestY = nX - 0.5 * iconWidth, nY - 0.5 * iconHeight
	UIHelper.SetPosition(node, fDestX, fDestY)
end

function UISelfieLightSetting:SetPhotoScript(tLight)
	local tLight = tLight or self.tLight
	m_aAllLightData = clone(tLight)
	local nCurIndex = self.nCurSelectLightSettingIndex or 1
	local tCurInfo = clone(tLight[nCurIndex])
	local bCurSelect = tCurInfo[4] or false

	for i, v in ipairs(self.tbLightOpenTogs) do
		local lightOn = clone(tLight[i][4])
		self:ToggleLightOn(i, lightOn)
		UIHelper.SetSelected(v, lightOn)
    end

	UIHelper.SetVisible(self.tbLightToggleSelecLighttImg[nCurIndex], bCurSelect)
	self:ToggleLightOn(nCurIndex, bCurSelect)
	for i = 1, #tLight do
		local tInfo = clone(tLight[i])
		local bSelect = tInfo[4] or false
		if bSelect and i == nCurIndex then
			self.nCurSelectLightSettingIndex = i
			self:ToggleLightOn(i, bSelect)
			self:UpdateLightColorSetting()  -- 更新颜色与色盘位置
			self:UpdateLightColorSettingState()
			if tInfo.Translation and not IsTableEmpty(tInfo.Translation) then   -- 更新位置
				self.lightVecX_Script:SetSliderValue(tInfo.Translation.x)
				self.lightVecY_Script:SetSliderValue(tInfo.Translation.y)
				self.lightVecZ_Script:SetSliderValue(tInfo.Translation.z)
			end
		end
		m_AllLightTransParams[i] = clone(tLight[i].Translation)
		-- SelfieData.Light_CurrentData[i] = tLight[i]
		-- SelfieData.Light_CurrentData[i].tTranslation = m_AllLightTransParams[i]
	end

	m_aAllLightData = tLight
	SelfieData.Light_CurrentData.bImportPhotoData = false
end

return UISelfieLightSetting