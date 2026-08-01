RENDER_LEVEL =
{
	LOW = 100,
	HIGH = 200,
	BD = 250,
}
CONFIGURE_LEVEL =
{
	ENABLE = 0,
	ATTEND = 1,
	LOWEST = 2, 		--最简
	LOW_MOST = 3,		--简约
	LOW = 4,			--均衡
	MEDIUM = 5,			--唯美 //这档现在弃用了，原来选这档的人进来以后直接改成均衡
	HIGH = 6,			--高效
	PERFECTION = 7,		--电影
	HD = 8,				--极致
	PERFECT = 10, 		--沉浸
	EXPLORE = 9, 		--探索

	BD_LOW = 132,		--BD均衡
	BD_PERFECTION = 135,--BD电影
	BD_HD = 136,		--BD极致
}

VIDEO_DEFAULT_RESOLUTION =
{
	WIDTH = 1280,
	HEIGHT = 720,
}

VideoData = VideoData or {className = "VideoData"}
local self = VideoData
--本来是通过KG3DEngine.Get3DEngineOptionCaps(a3DEngineOption)从引擎取得值，现在改到UI来，改起来方便
local a3DEngineCaps = {
	aAdapterModes = {
		{nWidth = 800, nHeight = 600, uRefreshRates = {60}},
		{nWidth = 1024, nHeight = 768, uRefreshRates = {60}},
		{nWidth = 1152, nHeight = 864, uRefreshRates = {60}},
		{nWidth = 1280, nHeight = 720, uRefreshRates = {60}},
		{nWidth = 1280, nHeight = 768, uRefreshRates = {60}},
		{nWidth = 1280, nHeight = 800, uRefreshRates = {60}},
		{nWidth = 1280, nHeight = 960, uRefreshRates = {60}},
		{nWidth = 1280, nHeight = 1024, uRefreshRates = {60}},
		{nWidth = 1360, nHeight = 768, uRefreshRates = {60}},
		{nWidth = 1366, nHeight = 768, uRefreshRates = {60}},
		{nWidth = 1440, nHeight = 900, uRefreshRates = {60}},
		{nWidth = 1680, nHeight = 1050, uRefreshRates = {60}},
		{nWidth = 1920, nHeight = 1080, uRefreshRates = {60}},
	},

	fMinCameraAngle = math.pi / 6,
	fMaxCameraAngle = math.pi / 3 * 2,
	aScaleOutputSize = {512, 640, 768, 896, 1024, 1280, 1600, 1920, 2048},
	aClientSFXLimit = {15, 30, 60, 100, 1000}, --同屏特效限制
	aMDLRenderLimit = {0, 5, 10, 15, 20, 25, 30, 40, 50, 60, 80, 100, 120, 1000}, --同屏玩家人数、同屏NPC人数限制
	aMaxFPSLimit = {30, 35, 40, 45, 50, 55, 60, 65, 67}, --最高帧数限制
	aNISSharpness = {0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1},--NIS锐利度
	bCameraShake = false
}
-- 找机会存进文件保存
local tbCustomConfig =
{
	["VideoBase.nConfigureLevel"] = 8,
	["VideoBase.nRecommendLevel"] = 8,
	["VideoBase.nRecommendVersion"] = 4,
	["VideoBase.nLogCount"] = 21,
	["VideoBase.nLogVersion"] = 1,
	["VideoBase.nRepresentVersion"]=2,
	["VideoBase.nVersion"] =2
}
local BD_LEVEL_START = 10

local tbResolution = {
	nWidth = VIDEO_DEFAULT_RESOLUTION.WIDTH,
	nHeight = VIDEO_DEFAULT_RESOLUTION.HEIGHT,
}

local function Init3DEngineCaps()
	local function AddNew(szName, min, max, add, n)
		local a = min
		local t = {}
		while(a <= max) do
			table.insert(t, tonumber(kmath.dcl_wpoint(a, n)) + 0) --避免-0的情况
			a = a + add
		end
		a3DEngineCaps[szName] = t
	end
	AddNew("aScreenSizeLimitedRate", 0.2, 2, 0.01, 2) --画面精度限制 0.2-2, 0.01
	AddNew("aScreenBrightnessRate", 0, 1, 0.01, 2) --护眼模式限制0-1, 0.01
	AddNew("aEffectLimitRate", 0.1, 1, 0.1, 1) --自身特效透明度、自身特效明暗度、他人特效透明度、他人特效明暗度设置0.1-1, 0.1
	AddNew("aDLSSParam", -1, 1, 0.1, 1) --DLSS限制，0-1, 0.1
	AddNew("aSpeedTreeLeafScale", 30, 100, 10) --树叶缩放限制，0-100, 10
end

local function InitSM()
	if SM_IsEnable() then
		local a3DEngineOption = KG3DEngine.Get3DEngineOption()

		self.nConfigureLevel = a3DEngineOption.nEngineGraphicsLevel + 1
		self.nRecommendLevel = a3DEngineOption.nEngineGraphicsLevel + 1
	end
end

local function LoadHistory()
	local function GetData(szKey)
		for k, v in pairs(tbCustomConfig) do
			if k == szKey then
				return v
			end
		end
	end
	if not SM_IsEnable() then
		self.nConfigureLevel 	= GetData("VideoData.nConfigureLevel") or self.nConfigureLevel
		self.nRecommendLevel 	= GetData("VideoData.nRecommendLevel") or self.nRecommendLevel

		if self.nConfigureLevel and self.nConfigureLevel == CONFIGURE_LEVEL.MEDIUM then
			self.nConfigureLevel = CONFIGURE_LEVEL.LOW
		end
		if self.nConfigureLevel and self.nConfigureLevel > BD_LEVEL_START
		and self.nConfigureLevel ~= CONFIGURE_LEVEL.BD_LOW
		and self.nConfigureLevel ~= CONFIGURE_LEVEL.BD_PERFECTION
		and self.nConfigureLevel ~= CONFIGURE_LEVEL.BD_HD then
			self.nConfigureLevel = CONFIGURE_LEVEL.BD_PERFECTION
		end
		if self.nRecommendLevel and self.nRecommendLevel == CONFIGURE_LEVEL.MEDIUM then
			self.nRecommendLevel = CONFIGURE_LEVEL.LOW
		end
		if self.nRecommendLevel and self.nRecommendLevel > BD_LEVEL_START
		and self.nRecommendLevel ~= CONFIGURE_LEVEL.BD_LOW
		and self.nRecommendLevel ~= CONFIGURE_LEVEL.BD_PERFECTION
		and self.nRecommendLevel ~= CONFIGURE_LEVEL.BD_HD then
			self.nRecommendLevel = CONFIGURE_LEVEL.BD_PERFECTION
		end
	end
	self.nRecommendVersion		= GetData("VideoData.nRecommendVersion") or self.nRecommendVersion
	self.nLogCount 			= GetData("VideoData.nLogCount") or self.nLogCount
	self.nLogVersion 			= GetData("VideoData.nLogVersion") or self.nLogVersion
	self.nRepresentVersion 	= GetData("VideoData.nRepresentVersion") or self.nRepresentVersion
	self.nVersion 				= GetData("VideoData.nVersion") or self.nVersion

	if KG3DEngine.IsRTXEnabled() then --就默认开了探索
		VideoData.nConfigureLevel = CONFIGURE_LEVEL.EXPLORE
	end
end

local function SaveHistory()
	local t = {}
	local function SetData(szKey, nValue)
		table.insert(t, {k = szKey, v = nValue})
	end

	SetData("VideoData.nConfigureLevel", self.nConfigureLevel)
	SetData("VideoData.nRecommendLevel", self.nRecommendLevel)
	SetData("VideoData.nRecommendVersion", self.nRecommendVersion)
	SetData("VideoData.nLogCount", self.nLogCount)
	SetData("VideoData.nLogVersion", self.nLogVersion)
	SetData("VideoData.nRepresentVersion", self.nRepresentVersion)
	SetData("VideoData.nVersion", self.nVersion)
	local file = "userdata/customconfigure.dat"
	if string.char( string.byte(file, 2, 2) ) == ':' then
		return
	end
	--local data = var2str(t)
	--return SaveDataToFile(data, file)
end

function VideoData.OnSave3DEngineOption()
	KG3DEngine.Set3DEngineOption(a3DEngineCaps)
	SaveHistory()
end

function VideoData.Get3DEngineOptionCaps()
	return a3DEngineCaps
end

function VideoData.GetConfigureLevel()
	return self.nConfigureLevel
end

function VideoData.GetResolution()
	return tbResolution
end

--------------------------------------------------------------------------------------------------
function VideoData.Init()
	self.nConfigureLevel = CONFIGURE_LEVEL.LOW
	self.nVersion = 1
	self.nLastWidth = nil
	self.nLastHeight = nil
	self.nLogCount = 0
	self.nRecommendVersion = 1
	self.nRepresentVersion = 1
    LoadHistory()
	InitSM()
	Init3DEngineCaps()
	self.regEvents()
end

function VideoData.UnInit()
   Event.UnRegAll()
end

function VideoData.regEvents()
	Event.Reg(self, "GAME_EXIT", self.OnSave3DEngineOption())
end