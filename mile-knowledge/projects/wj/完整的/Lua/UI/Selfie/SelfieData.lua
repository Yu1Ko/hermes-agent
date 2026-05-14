require("Lua/UI/Selfie/SelfieMusicData.lua")
require("Lua/UI/Selfie/AiBodyMotionData.lua")
require("Lua/UI/Selfie/SelfieOneClickModeData.lua")

local WEB_URL_TEST = "https://test-ws.xoyo.com"
local WEB_URL = "https://ws.xoyo.com"
local ApplyLoginSignWebID = 3200

local PostKey = {
    LOGIN_ACCOUNT           = "LOGIN_ACCOUNT",
	GET_UPLOAD_TIME			= "GET_UPLOAD_TIME",
	GET_UPLOAD_TOKEN 		= "GET_UPLOAD_TOKEN",
	UPLOAD_VIDEO			= "UPLOAD_VIDEO",
	DO_UPLOAD_VIDEO			= "DO_UPLOAD_VIDEO"
}

local PostUrl = {
    LOGIN_ACCOUNT     	= "/core/jx3tools/get_current_account",
	GET_UPLOAD_TIME 	= "/jx3/videoupload241121/remain_upload_time",
	GET_UPLOAD_TOKEN	= "/jx3/videoupload241121/get_upload_token",
	UPLOAD_VIDEO		= "/jx3/videoupload241121/video_upload_log",
}
local SELFIE_STUDIO_MAP_LIST    = {705}
local tEnableActPresetMap = {25, 27} --由开关控制天气预设的地图列表

SELFIE_CAMERA_RIGHT_TYPE = 
{
    MUSIC = 1, -- 音乐
    MOVIE = 2, -- 运镜
	AIGC  = 3, -- 动捕
}

SELFIE_CAMERA_RIGHT_TYPE_NAME = 
{
    [SELFIE_CAMERA_RIGHT_TYPE.MUSIC] = "音乐",
    [SELFIE_CAMERA_RIGHT_TYPE.MOVIE] = "运镜",
	[SELFIE_CAMERA_RIGHT_TYPE.AIGC] = "动捕",
}

SELFIE_CAMERA_RIGHT_TAG = 
{
    DEFAULT = 1, -- 默认
    CUSTOM =  2, -- 自定义
}

SELFIE_VIDEO_RECORD_TYPE = 
{
	MUSIC = 1, -- 音乐
    MOVIE = 2, -- 运镜
	AIGC  = 3, -- 动捕
	PREVIEW = 4, -- 预览
	FILM = 5,	-- 成片
}

SELFIE_VIDEO_RECORD_TYPE_NAME = 
{
	[SELFIE_VIDEO_RECORD_TYPE.MUSIC] = "音乐",
    [SELFIE_VIDEO_RECORD_TYPE.MOVIE] = "运镜",
	[SELFIE_VIDEO_RECORD_TYPE.AIGC] = "动捕",
	[SELFIE_VIDEO_RECORD_TYPE.PREVIEW] = "预览",
	[SELFIE_VIDEO_RECORD_TYPE.FILM] = "成片",
}

Selfie_BaseSettingType =
{
	None = 0,
	ShowSelf = 1,
	ShowNPC = 2,
	ShowAllPlayer = 3,
	ShowPet = 4,
	ShowTeam = 5,
	CameraFoucs = 6,
	EyeFoucs = 7,
	AngleSize = 8,
	FouceDistance = 9,
	DOF = 10,
	DOFDegree = 11,
	FilterQD = 12,
	FilterLD = 13,
	FilterDBD = 14,
	FilterBHD = 15,
	FilterAJ = 16,
	FilterKL = 17,
	FilterBGZ = 18,
	FilterRG = 19,
	FilterJTSC = 20,
	FilterGG = 21,
	ShowFaceCount = 22,
	AdvancedDof = 23,
	BokehShape = 24,
	BokehSize = 25,
	BokehBrightness = 26,
	BokehFalloff = 27,
	ModelBrightness = 28,
	HeadingAngle = 29,
	AltitudeAngle = 30,
	LightVecX = 31,
	LightVecY = 32,
	LightVecZ = 33,

    Pendant_Head = 34,
    Pendant_Face = 35,
    Pendant_Glasses = 36,
    Pendant_BackCloak = 37,
    Pendant_PendantPet = 38,
    Pendant_Bag= 39,
    Pendant_LShoulder = 40,
    Pendant_RShoulder = 41,
    Pendant_LHand = 42,
    Pendant_RHand = 43,
    Pendant_Back = 44,
    Pendant_Waist = 45,
	Pendant_Weapon = 46,
	Pendant_BigSword = 47,
	LightPos = 48,

	WindEnable = 49,	--角色风场
	FabricEnable = 50,	--布料效果
	WindStrength = 51,	--风场强度
	WindFrequency = 52,	--风场频率
	WindVecX = 53,
	WindVecY = 54,
	WindVecZ = 55,
	BloomEnbale = 56,
	Pendant_Head2 = 57,
	Pendant_Head3 = 58,
}

Selfie_BaseSettingCellType =
{
	Toggle = 1,
	Slider = 2,
	ToggleLong = 3,

}

SelfieData = SelfieData or {className = "SelfieData"}
local self = SelfieData
local tbSelfieSave = {
	nDepthOfField = 0,
	nDistanceOfFocus = 0,
	nDepthOfFieldDegree = 50,
	bEnableRC_Depth = false,
}

SelfieData.szAtmosphereTip = "目前支持时光切换的场景：扬州、成都、侠客岛、长安、洛阳、太原、河西瀚漠、万花、少林、纯阳、七秀、天策、藏剑山庄、五毒、唐门、明教、丐帮、苍云、长歌门、霸刀山庄、蓬莱、凌雪阁、衍天宗、北天药宗、刀宗、万灵山庄、南诏段氏。其他场景暂未开放，敬请期待。"

SelfieData.SAVE_DATA_VERSION = 1

SelfieData.nEnter = 0		-- 是否进入环境云图
-- 自身
SelfieData.g_ShowSelf = true
-- NPC
SelfieData.g_ShowNPC = true
-- 玩家
SelfieData.g_ShowPlayer = true
-- 队友
SelfieData.g_ShowPartyPlayer = true
-- 镜头焦点
SelfieData.bCameraSmoothing = false
-- 眼睛焦点
SelfieData.bEyeFollow = false
-- 自定义捏脸
SelfieData.bShowFaceCount = false
-- 开启高级景深
SelfieData.bOpenAdvancedDof = false

SelfieData.CameraRemoveSpeed = 5

SelfieData.BASE_PARAM_MAX =
{
	DOF = 100,
	DOF_DEGREE = 3000,
	BOKEH_SIZE = 30,  --- 最小值：0
	BOKEH_BRIGHTNESS = 5,  --- 最小值：1；设置的时候将取互补值；最值设为80的话会非常卡
	BOKEH_FALLOFF = 1.0,  --- 单位长度0.1
}
local _MIN_EXPORT_NUM = 0.0001 --- 小于这个值时，上传的数字会变成科学计数法

SelfieData.DOF_PARAM_MAX =
{
	DOF =
	{
		WIN = 16000,
		MOBILE =
		{
			[GameQualityType.LOW] = 10000,
			[GameQualityType.MID] = 10000,
			[GameQualityType.HIGH] = 14000,
			[GameQualityType.EXTREME_HIGH] = 16000,
		}
	},
	DOF_DEGREE =
	{
		[GameQualityType.LOW] = 20,
		[GameQualityType.MID] = 20,
		[GameQualityType.HIGH] = 20,
		[GameQualityType.EXTREME_HIGH] = 20,
	}
}

SelfieData.tbLayerIgnoreIDs =
{
	[UILayer.Tips] = {VIEW_ID.PanelRestScreen,VIEW_ID.PanelHintTop ,VIEW_ID.PanelNodeExplorer},
	[UILayer.HoverTips] = {VIEW_ID.PanelHoverTips},
	[UILayer.Page] = {VIEW_ID.PanelResourcesDownload, VIEW_ID.PanelPersonalCardAdorn, VIEW_ID.PanelPersonalAccounts,
					  VIEW_ID.PanelWorldMap, VIEW_ID.PanelTopUpMain, VIEW_ID.PanelExteriorMain,
					  VIEW_ID.PanelSettleAccounts, VIEW_ID.PanelMusicMainPlay,
					  VIEW_ID.PanelShareStation, VIEW_ID.PanelCoinShopBuildDyeing, VIEW_ID.PanelCameraCodeList, VIEW_ID.PanelCameraCodeListLocal,
					  VIEW_ID.PanelBulidFaceDetail, VIEW_ID.PanelSettleAccounts, VIEW_ID.PanelTopUpMain, VIEW_ID.PanelQuickPop, 
					  VIEW_ID.PanelCutMusic, VIEW_ID.PanelCameraSettingRight, VIEW_ID.PanelToVideo, VIEW_ID.PanelRecord} ,
	[UILayer.Battle] = {},
	[UILayer.Main] = {},
	[UILayer.Guide] = {},
	[UILayer.Top] = {VIEW_ID.PanelGamepadCursor},
}

SelfieData.tbCaptureScreenIgnoreIDs = 
{
	VIEW_ID.PanelQiYuPop,
}

SelfieData.tbFilterCacheInfo = {}
SelfieData.tSelColorID = {}
SelfieData.tExtraCell = {}
SelfieData.tParamSlider = {}

SelfieData.WEB_STATUS_CODE = {
    [1] = "成功",
    [0] = "系统错误",
    [-10151] = "活动未开启",
    [-10152] = "活动配置错误",
    [-10153] = "活动未开始",
    [-10154] = "活动已结束",
    [-20101] = "账号不存在",
    [-20102] = "今日上传次数已达上限",
    [-20105] = "未开启上传",
}

local _DEFAULT_LIGHT_PARAMS_PATH = "ui/Scheme/Setting/SelfieLights.json"
SelfieData.tLookAtPos = {x = 0, y = 0,}
SelfieData.tFocusPos  = {x = 0, y = 0,}
SelfieData.tSelfieCamera = {}
SelfieData.tRoleBoxCheck = {}

SelfieData.Light_CurrentData = {}
SelfieData.Light_DefaultData = {}

SelfieData.Wind_DefaultData  = {
	nX = 100,
	nY = 100,
	nZ = 100,
	nStrength = 20,
	nFrequency = 0.5,
}
SelfieData.Wind_CurrentData = {}


SelfieData.CAMERA_ANI_TYPE = {
    DEFAULT = 1,
    CUSTOM = 2,
}

SelfieData.bShowDropConfirm = true
SelfieData.bShowUIVideoRecord = false



local tReservedData = {}
function SelfieData.GetSelfieSave()
	return tbSelfieSave
end

function SelfieData.SetReservedData(tbData)
	tReservedData = tbData
end

function SelfieData.GetReservedData()
	return tReservedData
end

function SelfieData.Init()
	SelfieData.bShowDropConfirm = true
	SelfieData._bLastInSelfieStudio = false
	SelfieMusicData.Init()
	AiBodyMotionData.Init()
	SelfieOneClickModeData.Init()
end

function SelfieData.UnInit()
	Event.UnRegAll(SelfieData)
	SelfieMusicData.UnInit()
	AiBodyMotionData.UnInit()
	SelfieOneClickModeData.UnInit()
end


function SelfieData.Enter()
	if self.bIsWaitSwitchPortrait then
		return	-- 竖屏切换过程中跳过设置
	end

	self.nEnter = self.nEnter + 1
	if self.nEnter ~= 1 then
		return
	end

	CameraMgr.EnableSegment(false, false)
	rlcmd("x3d enter selfie 1")		 		-- 特殊处理主角Lod问题

	local pScene = SceneMgr.GetGameScene()
	if pScene and not QualityMgr.bDisableCameraLight then
		pScene:OpenCameraLight("", true)	-- 开启镜头光
	end

	self.tEnvCtrl = RLEnv.PushVisibleCtrl()
	self.tEnvCtrl:SetHDFaceCount(5)			-- 幻境云图默认5个高清脸
	SelfieOneClickModeData.Init()
end

function SelfieData.Leave()
	if self.bIsWaitSwitchPortrait then
		return
	end

	self.nEnter = self.nEnter - 1
	if self.nEnter ~= 0 then
		return
	end

	RLEnv.RemoveVisibleCtrl(self.tEnvCtrl)	-- 回滚设置
	self.tEnvCtrl = nil

	local pScene = SceneMgr.GetGameScene()
	if pScene then
		pScene:RestoreCameraLight()
	end

	rlcmd("x3d enter selfie 0")
	CameraMgr.EnableSegment(true)
	SelfieOneClickModeData.UnInit()
end

function SelfieData.GetEnvCtrl()
	return self.tEnvCtrl
end

function SelfieData.StartRegCurlRequest()
	Event.Reg(SelfieData, "WEB_SIGN_NOTIFY", function()
		if arg3 == 3 then
			SelfieData.OnLoginWebDataSignNotify()
		end
    end)

    Event.Reg(SelfieData, "ON_WEB_DATA_SIGN_NOTIFY", function()
		SelfieData.OnWebDataSignNotify()
    end)

	Event.Reg(SelfieData, "CURL_REQUEST_RESULT", function ()
		local szKey = arg0
		local bSuccess = arg1
		local szValue = arg2
		local uBufSize = arg3

		local bVaildKey = false
		for _, key in pairs(PostKey) do
			if szKey == key then
				bVaildKey = true
				break
			end
		end
		if not bVaildKey then
			return
		end


		if not bSuccess then
			LOG.ERROR("SelfieData CURL_REQUEST_RESULT FAILED!szKey:%s", szKey)
			return
		end
		LOG.INFO("CURL_REQUEST_RESULT  %s,%s",szKey,szValue)
		local tInfo, szErrMsg = JsonDecode(szValue)
		if szKey == PostKey.LOGIN_ACCOUNT then
			local tData = tInfo.data
			if tData then
				SelfieData.szUploadVideoSessionID = tData.session_id
			end
		elseif szKey == PostKey.GET_UPLOAD_TOKEN then
			if tInfo and tInfo.code then
				if tInfo.code == 1 then
					SelfieData.DoUploadVideo(tInfo.data.action, tInfo.data.input_values)
				elseif SelfieData.WEB_STATUS_CODE[tInfo.code] then
					TipsHelper.ShowNormalTip(SelfieData.WEB_STATUS_CODE[tInfo.code])
				end
			end
		elseif szKey == PostKey.UPLOAD_VIDEO then
			if tInfo and tInfo.code and tInfo.code ~= 1 and SelfieData.WEB_STATUS_CODE[tInfo.code] then
				TipsHelper.ShowNormalTip(SelfieData.WEB_STATUS_CODE[tInfo.code])
			end
		end
		Event.Dispatch(EventType.OnSelfieWebCodeRsp, szKey, tInfo)
	end)
end

function SelfieData.EndRegCurlRequest()
	Event.UnReg(SelfieData, "CURL_REQUEST_RESULT")
	Event.UnReg(SelfieData, "WEB_SIGN_NOTIFY")
	Event.UnReg(SelfieData, "ON_WEB_DATA_SIGN_NOTIFY")
end
----------------------------------------------------------------------
------------------------------ 基础设置 -------------------------------
local nDistanceOfFocus = 0
function SelfieData.SetDistanceOfFocus(nFocus)
	nDistanceOfFocus = math.min(MAIN_SCENE_DOF_DIST_MAX, math.max(nFocus, MAIN_SCENE_DOF_DIST_MIN))
end
function SelfieData.GetDistanceOfFocus()
	return nDistanceOfFocus
end
----------------------------------------------------------------------
------------------------------ 滤镜 ----------------------------------

local tFilterBase = {
	PARAM_IDS_AFFECTED_BY_INTENSITY =  -- 会被滤镜强度所影响的参数ID
	{
		2, 3, 4,
	},
	NO_STOP_DAY_NIGHT_FILTERS =  -- 不影响日夜循环的滤镜列表
	{
		24, 25, 26, 27,
	},

	PARAM_ID_TO_FILTER_UI_INFO_FIELD =
	{
		[2] = "fDefGain",
		[3] = "fDefContrast",
		[4] = "fDefSaturation",
		[5] = "fDefVignetteIntensity",
		[6] = "fDefGrainIntensity",
		[7] = "fDefExposure",
		[8] = "fDefBloom",
		[9] = "fDefChromaticAberration",
		[10] = "fDefSpecular",
	},

	SCENE_POST_RENDER_PARAM_ID =
	{
		[2] = "vGain",
		[3] = "vConstrast",
		[4] = "vSaturation",
		[5] = "fVignetteIntensity",
		[6] = "",--fGrainIntensity rc文件目前没有
		[7] = "fFixedExposure",
		[8] = "fBloom",
		[9] = "fChromaticAberrationIntensity",
		[10] = "fSpecular",
	},

	FILTER_PARAM_COUNT = 10,

	FILTER_INTENSITY_PARAM_ID = 1,

	PARAM_ID_2_DEF_PARAM_INDEX =
	{
		[2] = 1,
		[3] = 2,
		[4] = 3,
	},

	FILTER_DEFAULT_PARAMS =
	{
		[0] = {{1.0, 1.0, 1.0, 1.0}, {1.0, 1.0, 1.0, 1.0}, {1.0, 1.0, 1.0, 1.0}},
		[1] = {{1.0, 0.67, 0.873, 1.0}, {0.55,1.0,0.975,1.65}, {1.0, 1.0, 1.0, 1.0}},
		[2] = {{1.00,0.863,0.75,0.60}, {1.286,1.3095,1.107,1.00}, {0.536,1.40,0.714,1.20}},
		[3] = {{0.95,1.00,1.00,1.80}, {0.845,0.845,0.833,1.083}, {1.036,1.012,0.988,0.595}},
		[4] = {{1.000000,1.000000,1.000000,1.080000}, {1.000000,1.000000,1.000000,1.050000}, {1.000000,1.000000,1.000000,0.023800}},
		[5] = {{1.000000,0.749615,0.460526,0.988100}, {0.928600,0.693076,0.562047,0.881000}, {0.000000,0.500000,1.000000,1.000000}},
		[6] = {{1.000000,0.779608,0.473684,2.000000}, {1.000000,0.929588,0.539474,1.000000}, {1.000000,1.000000,1.000000,1.000000}},
		[7] = {{1.000000,1.047600,1.083300,1.100000}, {0.900000,1.000000,1.000000,0.650000}, {1.000000,1.000000,1.000000,1.000000}},
		[8] = {{1.000000,1.050000,1.000000,1.200000}, {1.000000,0.950000,1.000000,0.960000}, {1.000000,1.200000,0.900000,1.100000}},
		[9] = {{1.000000,1.000000,1.000000,1.000000}, {1.000000,1.000000,1.000000,0.550000}, {1.000000,1.000000,1.000000,1.000000}},
		[10] = {{1.000000,1.000000,1.000000,1.500000}, {1.000000,1.000000,1.000000,1.000000}, {1.000000,1.000000,1.000000,1.000000}},
		[11] = {{1.000000,0.719611,0.486842,0.500000}, {1.000000,1.011900,1.000000,1.100000}, {1.000000,1.000000,1.202400,1.000000}},
		[12] = {{0.772057,1.107100,0.816031,1.150000}, {0.680000,1.000000,0.789474,1.250000}, {1.000000,1.000000,1.000000,1.000000}},
		[13] = {{1.000000,1.000000,1.000000,1.000000}, {1.000000,1.000000,1.000000,1.500000}, {0.000000,0.000000,0.000000,1.000000}},
		[14] = {{0.896457,0.852632,1.080000,1.595200}, {0.736842,0.784712,1.000000,0.869000}, {1.000000,1.631000,0.800000,0.900000}},
		[15] = {{1.000000,1.000000,1.000000,1.000000}, {1.071400,1.071400,0.869000,0.738100}, {1.000000,0.996407,0.776316,1.200000}},
		[16] = {{0.631579,0.688619,1.000000,1.797600}, {1.000000,1.000000,1.000000,1.200000}, {1.000000,1.000000,1.000000,1.300000}},
		[17] = {{0.998620,1.107100,0.611818,0.511900}, {1.000913,1.071400,1.059500,0.928600}, {0.289474,1.000000,0.758032,1.166700}},
		[18] = {{0.868421,0.947451,1.000000,1.500000}, {0.710526,1.000000,0.950284,1.500000}, {1.000000,1.000000,1.000000,1.000000}},
		[19] = {{0.644737,0.733553,1.000000,1.214300}, {1.238100,1.119000,0.797600,0.850000}, {1.000000,1.000000,1.000000,1.000000}},
		[20] = {{1.000000,1.000000,1.200000,0.300000}, {0.750000,0.838917,1.000000,0.940500}, {1.000000,1.000000,1.000000,1.000000}},
		[21] = {{1.000000,1.000000,1.000000,1.000000}, {1.000000,0.950000,0.900000,0.900000}, {0.900000,1.250000,1.200000,1.200000}},
		[22] = {{1.000000,0.952130,0.809500,1.000000}, {0.892900,0.862740,0.552188,1.200000}, {1.000000,0.708883,0.447368,1.150000}},
		[23] = {{1.000000,0.923589,0.842105,1.000000}, {1.030000,0.720000,0.430000,1.080000}, {0.750000,1.000000,1.000000,1.000000}},
		[24] = {{1.000000,0.951667,0.842105,0.900000}, {1.000000,1.000000,1.000000,0.950000}, {1.000000,0.949831,0.845200,1.000000}},
		[25] = {{1.000000,1.000000,1.000000,0.850000}, {1.000000,1.000000,1.000000,0.900000}, {1.000000,1.000000,1.000000,1.050000}},
		[26] = {{1.000000,1.000000,1.000000,1.200000}, {1.000000,1.000000,1.000000,1.000000}, {1.000000,1.000000,1.000000,1.150000}},
		[27] = {{1.000000,1.000000,1.000000,1.000000}, {1.000000,1.000000,1.000000,0.850000}, {1.000000,1.000000,1.000000,1.150000}},
	}, -- Gain, Constrast, Saturation

	SLIDER_FUNC_INFO =
	{
		[1] = {fnSet=function(fValue) SelfieData.SetPostRenderFilterIntensity(fValue) end, tData={1, 1}},
		[2] = {fnSet=function(fValue)
			local fR, fG, fB, fA = SelfieData.GetParamComponentsByMajor(fValue, 1, false, SelfieData.nCurSelectFilterIndex)
			KG3DEngine.SetPostRenderFilterGain(fR, fG, fB, fA)
		end, tData={2, 2}},
		[3] = {fnSet=function(fValue)
			local fR, fG, fB, fA = SelfieData.GetParamComponentsByMajor(fValue, 2, false, SelfieData.nCurSelectFilterIndex)
			KG3DEngine.SetPostRenderFilterConstrast(fR, fG, fB, fA)
		end, tData={2, 2}},
		[4] = {fnSet=function(fValue)
			local fR, fG, fB, fA = SelfieData.GetParamComponentsByMajor(fValue, 3, false, SelfieData.nCurSelectFilterIndex)
			KG3DEngine.SetPostRenderFilterSaturation(fR, fG, fB, fA)
		end, tData={2, 2}},
		[5] = {fnSet=function(fValue)
			KG3DEngine.SetPostRenderVignetteEnable(fValue > 0.001)
			KG3DEngine.SetPostRenderFilterVignetteIntensity(fValue)
		end, tData={1, 1}},
		[6] = {fnSet=function(fValue)
			KG3DEngine.SetPostRenderGrainEnable(fValue > 0.001)
			KG3DEngine.SetPostRenderFilterGrainIntensity(fValue)
		end, tData={1, 1}},
		[7] = {fnSet=function(fValue) KG3DEngine.SetPostRenderFilterFixedExposure(fValue) end, tData={1, 5, -5}},
		[8] = {fnSet=function(fValue) KG3DEngine.SetPostRenderFilterBloom(fValue) end, tData={1, 8, -1}},
		[9] = {fnSet=function(fValue)
			KG3DEngine.SetPostRenderChromaticAberrationEnable(fValue > 0.001)
			KG3DEngine.SetPostRenderFilterChromaticAberration(fValue)
		end, tData={1, 1}},
		[10] = {fnSet=function(fValue) KG3DEngine.SetPostRenderFilterSpecular(1 - fValue / 2) end, tData={1, 1}},
	},

	SELFIE_EX_SLIDER_FUNC_PARAM = {
    ------------------------------------- 详细信息 --------------------------------------
    --- 开关
    [1] = {nType = 1,   nPostEffectParam = POST_EFFECT_PARAM_ID.DETAIL_ENABLE, bTitle = true},
    --- 使明朗
	[2] = {nType = 8,  nPostEffectParam = POST_EFFECT_PARAM_ID.DETAIL_SHARPEN, szDefaultValName = "fDefSharpen"},
    --- HDR调色
	[3] = {nType = 8,  nPostEffectParam = POST_EFFECT_PARAM_ID.DETAIL_HDR, szDefaultValName = "fDefHDR"},
    --- 亮点
	[4] = {nType = 8,  nPostEffectParam = POST_EFFECT_PARAM_ID.DETAIL_HIGHLIGHT, szDefaultValName = "fDefHighLight"},
    --- 阴影
	[5] = {nType = 8,  nPostEffectParam = POST_EFFECT_PARAM_ID.DETAIL_SHADOW, szDefaultValName = "fDefShadow"},
    ------------------------------------------------------------------------------------

    ------------------------------------- SSRTGI ---------------------------------------
    --- 开关
    [6] = {nType = 1,  nPostEffectParam = POST_EFFECT_PARAM_ID.SSRTGI_ENABLE, bTitle = true},
    --- 强度
	[7] = {nType = 8,  nPostEffectParam = POST_EFFECT_PARAM_ID.SSRTGI_INTENSITY, szDefaultValName = "fDefSSRTGIIntensity"},
    --- 渐变距离
	[8] = {nType = 8,  nPostEffectParam = POST_EFFECT_PARAM_ID.SSRTGI_REACH, szDefaultValName = "fDefSSRTGIReach"},
    ------------------------------------------------------------------------------------

    ---------------------------------------- HSL ---------------------------------------
    --- 开关
    [9] = {nType = 1,  nPostEffectParam = POST_EFFECT_PARAM_ID.HSL_ENABLE, bTitle = true},
    --- 色相
	[10] = {nType = 8,  szPostEffectParam = "HSL_HUE", szDefaultValName = "fDefHSLHue", nColorClass = 1}, --nColorClass对应FilterColorParamSetting表里配的nColorClass
    --- 饱和度
	[11] = {nType = 8,  szPostEffectParam = "HSL_SATURATION", szDefaultValName = "fDefHSLSaturation", nColorClass = 1},
    --- 亮度
	[12] = {nType = 8,  szPostEffectParam = "HSL_LIGHTNESS", szDefaultValName = "fDefHSLLightness", nColorClass = 1},
    ------------------------------------------------------------------------------------
	},


	m_nCurFilter = 0,
	m_bCaptureEnabled = false,

	bEnableActivityPreset = true, --目前仅用来控制大攻防地图的天气预设
    nActivityPreset = nil, --活动开启优先设置的预设
}

SelfieData.tbBasFilterContent =
{
    {nType = Selfie_BaseSettingType.FilterQD , szName = "强度" , tHideIndex = {0}},
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

local PendantShowType =
{
    [Selfie_BaseSettingType.Pendant_Head] = EQUIPMENT_REPRESENT.HEAD_EXTEND,
    [Selfie_BaseSettingType.Pendant_Face] = EQUIPMENT_REPRESENT.FACE_EXTEND,
    [Selfie_BaseSettingType.Pendant_Glasses] = EQUIPMENT_REPRESENT.GLASSES_EXTEND,
    [Selfie_BaseSettingType.Pendant_BackCloak] = EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND,
    [Selfie_BaseSettingType.Pendant_PendantPet] = EQUIPMENT_REPRESENT.PENDENT_PET_STYLE,
    [Selfie_BaseSettingType.Pendant_Bag] = EQUIPMENT_REPRESENT.BAG_EXTEND,
    [Selfie_BaseSettingType.Pendant_LShoulder] = EQUIPMENT_REPRESENT.L_SHOULDER_EXTEND,
    [Selfie_BaseSettingType.Pendant_RShoulder] = EQUIPMENT_REPRESENT.R_SHOULDER_EXTEND,
    [Selfie_BaseSettingType.Pendant_LHand] =  EQUIPMENT_REPRESENT.L_GLOVE_EXTEND,
    [Selfie_BaseSettingType.Pendant_RHand] = EQUIPMENT_REPRESENT.R_GLOVE_EXTEND,
    [Selfie_BaseSettingType.Pendant_Back] = EQUIPMENT_REPRESENT.BACK_EXTEND,
    [Selfie_BaseSettingType.Pendant_Waist] = EQUIPMENT_REPRESENT.WAIST_EXTEND,
    [Selfie_BaseSettingType.Pendant_Weapon] = EQUIPMENT_REPRESENT.WEAPON_STYLE,
    [Selfie_BaseSettingType.Pendant_BigSword] = EQUIPMENT_REPRESENT.BIG_SWORD_STYLE,
    [Selfie_BaseSettingType.Pendant_Head2] = EQUIPMENT_REPRESENT.HEAD_EXTEND1,
    [Selfie_BaseSettingType.Pendant_Head3] = EQUIPMENT_REPRESENT.HEAD_EXTEND2,
}

SelfieData.nCurSelectFilterIndex = 0
SelfieData.nCurSelectPresetIndex = 0
SelfieData.tbCurSelfieFilterTab = nil

local m_nDynamicWeather = 0

function SelfieData.IsVideoLevelLow()
	local nConfigureLevel = VideoData.GetConfigureLevel()
	if nConfigureLevel == CONFIGURE_LEVEL.LOWEST or nConfigureLevel == CONFIGURE_LEVEL.LOW_MOST then
		return true
	end
	return false
end

function SelfieData.CanShowFilterSettingPage()
	return not self.IsVideoLevelLow()
end

function SelfieData.SafeChangeFilter(nFilterIndex , bForce)
	if not SelfieData.bCanSetFuncInfo then
		return
	end
	if nFilterIndex ~= tFilterBase.m_nCurFilter or bForce then
		local tbColorGradeParams
		if nFilterIndex <= 0 then
			tbColorGradeParams = self.tbDefaultColorGradeParams
		else
			tbColorGradeParams = KG3DEngine.GetColorGradeParams()
			local tableInfo = TabHelper.GetUISelfieFilterTab(nFilterIndex)
			for k, v in pairs(tableInfo) do
				tbColorGradeParams[k] = v
			end
			SelfieData.tbCurSelfieFilterTab = tableInfo
		end
		-- KG3DEngine.SetPostRenderVignetteEnable(true)
		-- KG3DEngine.SetPostRenderGrainEnable(true)
		-- KG3DEngine.SetPostRenderChromaticAberrationEnable(true)
		tbColorGradeParams.bParamsChange = true
		tFilterBase.m_nCurFilter = nFilterIndex
		KG3DEngine.SetColorGradeParams(tbColorGradeParams)
	end
end

function SelfieData.SafeDefaultFilter()
	self.tbDefaultColorGradeParams = KG3DEngine.GetColorGradeParams()
end


function SelfieData.GetSceneDefaultFilterParams(aParams)
	local tFilterParams = Table_GetSelfieFilterParamsByLogicIndex(0)
	for nParamID = 1, tFilterBase.FILTER_PARAM_COUNT, 1 do
		local fDefaultValue
		if nParamID == tFilterBase.FILTER_INTENSITY_PARAM_ID then
			fDefaultValue = 1.0
		else
			local szFieldName = tFilterBase.SCENE_POST_RENDER_PARAM_ID[nParamID]
			local nParamIndex = tFilterBase.PARAM_ID_2_DEF_PARAM_INDEX[nParamID]
			if nParamIndex then
				local vec4 = SelfieData.tCurScenePostRenderParams[szFieldName]
				fDefaultValue = math.max(vec4[1], vec4[2], vec4[3], vec4[4])
			else
				if string.is_nil(szFieldName) then
					local newName = tFilterBase.PARAM_ID_TO_FILTER_UI_INFO_FIELD[nParamID]
					fDefaultValue = newName and tFilterParams[newName] or 0.0
				else
					fDefaultValue = SelfieData.tCurScenePostRenderParams[szFieldName] or 0.0
				end
			end
			if szFieldName == "fChromaticAberrationIntensity" then
				if not SelfieData.tCurScenePostRenderParams["bChromaticAberrationEnable"] then
					fDefaultValue = 0
				end
			elseif szFieldName == "fSpecular" then
				fDefaultValue = 1 - fDefaultValue -- 反着的
			end
		end

		aParams[nParamID] = fDefaultValue
	end
	return aParams
end

function SelfieData.GetFilterParamSettingByDefaultValues(nFilterIndex)
	local aParams = {}
	local aExParams = {}
	local tFilterParams = Table_GetSelfieFilterParamsByLogicIndex(nFilterIndex)
	if tFilterParams then
		for nParamID = 1, tFilterBase.FILTER_PARAM_COUNT, 1 do
			local fDefaultValue
			if nParamID == tFilterBase.FILTER_INTENSITY_PARAM_ID then
				fDefaultValue = 1.0
			else
				local szFieldName = tFilterBase.PARAM_ID_TO_FILTER_UI_INFO_FIELD[nParamID]
				fDefaultValue = szFieldName and tFilterParams[szFieldName] or 0.0
				local nParamIndex =tFilterBase.PARAM_ID_2_DEF_PARAM_INDEX[nParamID]
				if nParamIndex then
					local fR, fG, fB, fA = self.GetParamComponentsByMajor(fDefaultValue, nParamIndex, true, nFilterIndex)
					fDefaultValue = math.max(fR, fG, fB, fA)
				end
			end

			aParams[nParamID] = fDefaultValue
		end
	else
		return nil
	end
	if nFilterIndex == 0 then
		if SelfieData.tCurScenePostRenderParams then
			aParams = SelfieData.GetSceneDefaultFilterParams(aParams)
		end
	end
	for nExParamID, tInfo in pairs(tFilterBase.SELFIE_EX_SLIDER_FUNC_PARAM) do
		local szDefaultValName = tInfo.szDefaultValName
		if szDefaultValName and tFilterParams[szDefaultValName] then
			if tInfo.nColorClass then
				local tColorSetting = Table_GetFilterColorParamSetting(tInfo.nColorClass)
				aExParams[nExParamID] = {}
				for _, tColor in ipairs(tColorSetting) do
					aExParams[nExParamID][tColor.nColorID] = tFilterParams[szDefaultValName]
				end
			else
				aExParams[nExParamID] = tFilterParams[szDefaultValName]
			end
		end
	end

	return aParams,aExParams
end

function SelfieData.GetFilterExParamSetting()
	return tFilterBase.SELFIE_EX_SLIDER_FUNC_PARAM
end

function SelfieData.SetPostEffectExParam(nExParamID, fValue, nColorID)
    local tSetInfo = tFilterBase.SELFIE_EX_SLIDER_FUNC_PARAM[nExParamID]
    if tSetInfo then
        if tSetInfo.nPostEffectParam then
            KG3DEngine.SetPostEffectParam(tSetInfo.nType, tSetInfo.nPostEffectParam, fValue)
        elseif tSetInfo.szPostEffectParam and nColorID then
            local nPostEffectParam = POST_EFFECT_PARAM_ID[tSetInfo.szPostEffectParam .. nColorID]
            KG3DEngine.SetPostEffectParam(tSetInfo.nType, nPostEffectParam, fValue)
        end
    end
end

function SelfieData.GetParamComponentsByMajor(fMajor, nDefParamIndex, bIsMajorOnlyScale, nFilterIndex)

	local tDefaultParamComponents = tFilterBase.FILTER_DEFAULT_PARAMS[nFilterIndex][nDefParamIndex]
	local fDefaultMajor = math.max(tDefaultParamComponents[1], tDefaultParamComponents[2], tDefaultParamComponents[3], tDefaultParamComponents[4])
	if fDefaultMajor == 0 then
		return 0, 0, 0, fMajor
	else
		if bIsMajorOnlyScale then
			return self.ClampedMultiply(tDefaultParamComponents[1], tDefaultParamComponents[2], tDefaultParamComponents[3], tDefaultParamComponents[4], fMajor, 2)
		else
			fMajor = math.min(fMajor, 2)
			local fScale = fMajor / fDefaultMajor
			return tDefaultParamComponents[1] * fScale, tDefaultParamComponents[2] * fScale, tDefaultParamComponents[3] * fScale, tDefaultParamComponents[4] * fScale
		end
	end
end

function SelfieData.ClampedMultiply(fR, fG, fB, fA, fScale, fMax)
	local fMajor = math.max(fR, fG, fB, fA)
	fScale = math.min(fScale, math.min(fMajor * fScale, fMax) / ((fMajor > 0) and fMajor or 1))
	return fR * fScale, fG * fScale, fB * fScale, fA * fScale
end

function SelfieData.GetFilterSliderFuncInfoByParamID(nParamID)
	return tFilterBase.SLIDER_FUNC_INFO[nParamID]
end

function SelfieData.SetFilterSliderFuncInfoByParamID(nParamID , fValue)
	local funcInfo = tFilterBase.SLIDER_FUNC_INFO[nParamID]
	if funcInfo then
		funcInfo.fnSet(fValue)
	end
end

function SelfieData.SetPostRenderFilterIntensity(weight)
	local tbColorGradeParams = KG3DEngine.GetColorGradeParams()
	local vec4Lerp = function(sourceVec , targetVec)
		local tbNewVec = {}
		for i, v in ipairs(sourceVec) do
			tbNewVec[i] =  sourceVec[i] + (targetVec[i] - sourceVec[i]) * weight
		end
		return tbNewVec
	end

	local sectionLerp = function(szField)
		local Contrast = szField..".Contrast"
		local Saturation = szField..".Saturation"
		local Gamma = szField..".Gamma"
		local Gain = szField..".Gain"
		local Offset = szField..".Offset"
		if SelfieData.tbCurSelfieFilterTab then
			tbColorGradeParams[Contrast] = vec4Lerp(self.tbDefaultColorGradeParams[Contrast] , SelfieData.tbCurSelfieFilterTab[Contrast])
			tbColorGradeParams[Saturation] = vec4Lerp(self.tbDefaultColorGradeParams[Saturation] , SelfieData.tbCurSelfieFilterTab[Saturation])
			tbColorGradeParams[Gamma] = vec4Lerp(self.tbDefaultColorGradeParams[Gamma], SelfieData.tbCurSelfieFilterTab[Gamma])
			tbColorGradeParams[Gain] = vec4Lerp(self.tbDefaultColorGradeParams[Gain], SelfieData.tbCurSelfieFilterTab[Gain])
			tbColorGradeParams[Offset] = vec4Lerp(self.tbDefaultColorGradeParams[Offset] , SelfieData.tbCurSelfieFilterTab[Offset])
		end

	end
	sectionLerp("Global")
	sectionLerp("Highlights")
	sectionLerp("Midtones")
	sectionLerp("Shadows")
	KG3DEngine.SetColorGradeParams(tbColorGradeParams)
end

function SelfieData.AsyncSwitchPortrait(bIsPortrait , bNameCard)
	SelfieData.bIsWaitSwitchPortrait = true
	SelfieData.bIsPortrait = bIsPortrait
	SelfieData.bNameCard = bNameCard
	Timer.Add(SelfieData , 0.2 , function ()
		UIMgr.ShowLayer(UILayer.Page)
		UIMgr.ShowLayer(UILayer.Scene)
		if bIsPortrait then
			UIMgr.Close(VIEW_ID.PanelCamera)

		else
			UIMgr.Close(VIEW_ID.PanelCameraVertical)

		end
	end)
end

function SelfieData.AddLayerIgnoreView(layerName , nViewID)
	for layer , tbIgnoreViewIDs in pairs(SelfieData.tbLayerIgnoreIDs) do
	   	if layer == layerName then
			if not table.contain_value(tbIgnoreViewIDs , nViewID) then
				table.insert(SelfieData.tbLayerIgnoreIDs[layer] , nViewID)
			end
			break
		end
	end
end

function SelfieData.RemoveLayerIgnoreView(layerName , nViewID)
	for layer , tbIgnoreViewIDs in pairs(SelfieData.tbLayerIgnoreIDs) do
	   	if layer == layerName then
			table.remove_value( SelfieData.tbLayerIgnoreIDs[layer], nViewID )
			break
		end
	end
end

function SelfieData.SetFilterCacheInfo(nFilterType , value)
	if table.contain_key(SelfieData.tbFilterCacheInfo , nFilterType) then
		SelfieData.tbFilterCacheInfo[nFilterType] = value
	end
end

function SelfieData.GetFilterCacheInfo(nFilterType)
	if SelfieData.tbFilterCacheInfo then
		return SelfieData.tbFilterCacheInfo[nFilterType]
	end
	return nil
end

function SelfieData.SaveFilterCacheInfoToStorage()
	local nMapID = g_pClientPlayer.GetMapID()
    Storage.FilterParam.tbMapParams[nMapID] = SelfieData.tbMapParams
	Storage.FilterParam.nFilterIndex = SelfieData.nCurSelectFilterIndex
	if Storage.FilterParam.tbCustomPresets[SelfieData.nCurSelectPresetIndex] then
		Storage.FilterParam.nPresetIndex = SelfieData.nCurSelectPresetIndex
	else
		Storage.FilterParam.nPresetIndex = 0
	end
	for k, v in pairs(SelfieData.tbFilterCacheInfo) do
		Storage.FilterParam.tbParams[k] = v
	end
	Storage.FilterParam.Dirty()
end

function SelfieData.ResetFilterFromStorage(bForce)
	if not g_pClientPlayer then
		return
	end

	SelfieData.UpdateActivityPreset() --切地图后预设会默认清空，不需要手动重置

	local szEnvPreset
    local nMapID = g_pClientPlayer.GetMapID()
    local tAtmosphere = Table_GetFilterAtmosphere(nMapID)
    local tMapParam = Storage.FilterParam.tbMapParams[nMapID]

    if tAtmosphere and tMapParam then
        local szTime = tMapParam.szTime
        local szWeather = tMapParam.szWeather
        szEnvPreset = tAtmosphere[szTime] and tAtmosphere[szTime][szWeather]
	end

	if szEnvPreset or not tFilterBase.nActivityPreset or bForce then
        local nDofX, nDofY, nDofZ, nDofW = KG3DEngine.GetPostRenderDoFParam()
        rlcmd("set user env preset " .. (szEnvPreset or ""))
        -- 设置环境预设会修改景深相关参数，需再环境预设修改后重置
    	QualityMgr._UpdateBlurSize()
       	KG3DEngine.SetPostRenderDoFParam(nDofX, nDofY, nDofZ, nDofW)
    end

	if nMapID and nMapID > 0 then
		if not IsEmpty(Storage.FilterParam.tbParams) then
			SelfieData.nCurSelectFilterIndex = Storage.FilterParam.nFilterIndex
			SelfieData.SafeDefaultFilter()
			Timer.Add(self, 0.1, function()
				SelfieData.SafeChangeFilter(SelfieData.nCurSelectFilterIndex, true)

				for k, v in pairs(Storage.FilterParam.tbParams) do
					if k ~= Selfie_BaseSettingType.FilterQD then
						SelfieData.SetSelfieFuncInfoByTypeID(k, v)
					end
				end
			end)
		else
			SelfieData.nCurSelectFilterIndex = 0
			SelfieData.SafeDefaultFilter()
			Timer.Add(self, 0.1, function()
				SelfieData.SafeChangeFilter(SelfieData.nCurSelectFilterIndex, true)

				local tbParams = SelfieData.GetFilterParamSettingByDefaultValues(0)
				for k, v in pairs(SelfieData.tbBasFilterContent) do
					if v.nType ~= Selfie_BaseSettingType.FilterQD then
						local nValue = tbParams[k]
						SelfieData.SetSelfieFuncInfoByTypeID(v.nType, nValue + 0.0000000001)
					end
				end
			end)
		end
		if Storage.FilterParam.tbCustomPresets[Storage.FilterParam.nPresetIndex] then
			SelfieData.nCurSelectPresetIndex = Storage.FilterParam.nPresetIndex
		else
			SelfieData.nCurSelectPresetIndex = 0
		end
	end
end

function SelfieData.SaveAndApplyCustomPreset(szName, nPresetIndex)
	local tbParams = {}
	tbParams.nFilterIndex = SelfieData.nCurSelectFilterIndex
	tbParams.szName = szName
	for k, v in pairs(SelfieData.tbFilterCacheInfo) do
		tbParams[k] = v
	end

	if nPresetIndex then
		Storage.FilterParam.tbCustomPresets[nPresetIndex] = tbParams
	else
		table.insert(Storage.FilterParam.tbCustomPresets, tbParams)
		nPresetIndex = #Storage.FilterParam.tbCustomPresets
	end
	Storage.FilterParam.nFilterIndex = SelfieData.nCurSelectFilterIndex
	Storage.FilterParam.nPresetIndex = nPresetIndex
	SelfieData.nCurSelectPresetIndex = nPresetIndex
	Storage.FilterParam.Dirty()
end

function SelfieData.GetFilterParamsByFilterIndex(nFilterIndex)
    local tFilterParams = Table_GetAllOutsideFilterParams()
    for i, tbParams in pairs(tFilterParams) do
        if tbParams.nLogicIndex == nFilterIndex then
            return tbParams
        end
    end
end

function SelfieData.UpdateActivityPreset()
    local dwCurMapID = SelfieData.GetCurrentMapID()
    if not table.contain_value(tEnableActPresetMap, dwCurMapID) then
        tFilterBase.nActivityPreset = nil
        return
    end

    local tList = Table_GetActivityFilterPresetList(dwCurMapID)
    local fWindStrength, fClothWindRatio
    local nPresetID
    for _, tPreset in ipairs(tList) do
        if tPreset.dwMapID == dwCurMapID and (ActivityData.IsActivityOn(tPreset.dwActivityID) or UI_IsActivityOn(tPreset.dwActivityID)) then
            fWindStrength = tPreset.fWindStrength
            fClothWindRatio = tPreset.fClothWindRatio
            nPresetID = tPreset.nPresetID
            break
        end
    end

    if nPresetID and tFilterBase.bEnableActivityPreset then
		LOG.INFO("SelfieData.UpdateActivityPreset set env preset nPresetID:%d", nPresetID)

        tFilterBase.nActivityPreset = nPresetID
        rlcmd("set env preset " .. nPresetID)

        SelfieData.SetEnvWind(fWindStrength, fClothWindRatio)
    else
		LOG.INFO("SelfieData.UpdateActivityPreset set env preset nPresetID:0")

        tFilterBase.nActivityPreset = nil
        rlcmd("set env preset 0")

        SelfieData.ResetEnvWind()
    end
end

function SelfieData.SetEnvWind(fWindStrength, fClothWindRatio)
    if fWindStrength and fWindStrength ~= 0 then
        rlcmd("set wind strength " .. fWindStrength)

        if fClothWindRatio and fClothWindRatio ~= 1 then
            rlcmd("enable env cloth wind 1") --允许自定义环境风对布料的影响系数
            rlcmd("set env cloth wind ratio " .. fClothWindRatio) --设置环境风对布料的影响系数
        end
    else
        SelfieData.ResetEnvWind()
    end
end

function SelfieData.ResetEnvWind()
    rlcmd("enable env cloth wind 0") --恢复环境风对布料的影响系数为初值 1.0
    rlcmd("reset wind strength") --设置场景默认风场强度
end

function SelfieData.InitActivityPresetSetting()
	tFilterBase.bEnableActivityPreset = Storage.Camp.bEnableActivityPreset
end

function SelfieData.IsActivityPresetEnabled()
    return tFilterBase.bEnableActivityPreset
end

function SelfieData.EnableActivityPreset(bEnable)
    tFilterBase.bEnableActivityPreset = bEnable

	--存盘
	Storage.Camp.bEnableActivityPreset = bEnable
	Storage.Camp.Dirty()

	--绑定设置雨雪开关
	GameSettingData.ApplyNewValue(UISettingKey.WeatherSimulation, bEnable)

    FireUIEvent("ON_ACTIVITY_PRESET_ENABLE_STATE_CHANGE")
end

function SelfieData.IsInSelfieView()
	if UIMgr.GetView(VIEW_ID.PanelCamera) or UIMgr.GetView(VIEW_ID.PanelCameraVertical)  then
		return true
	end
	return false
end

function SelfieData.IsInFreeAnimation()
	if SelfieData.IsInSelfieView() and g_pClientPlayer.IsHaveBuff(12024, 1) then
		return true
	end
	return false
end

function SelfieData.ChangeDynamicWeather(nType, bSet)
	if m_nDynamicWeather ~= nType then
		m_nDynamicWeather = nType
		FireUIEvent("SELFIE_STUDIO_DYNAMIC_WEATHER_UPDATE")
	end
	if bSet then
		rlcmd(string.format("Set dynamicWeather_RainSnow %d", nType))
	end
end

function SelfieData.GetDynamicWeather()
	return m_nDynamicWeather
end

Event.Reg(SelfieData , EventType.OnViewClose , function(nViewID)
	if nViewID == VIEW_ID.PanelCameraVertical or nViewID == VIEW_ID.PanelCamera then
		if SelfieData.bIsWaitSwitchPortrait then
			if SelfieData.bIsPortrait then
				UIMgr.Open(VIEW_ID.PanelCameraVertical, SelfieData.bNameCard)
			else
				UIMgr.Open(VIEW_ID.PanelCamera, SelfieData.bNameCard)
			end
			-- 窗口开启以后再重置标记
			SelfieData.bIsWaitSwitchPortrait = false
		end
	end
end)

Event.Reg(SelfieData , "LOADING_END" , function()
	if SelfieData.bOpenAgain then
		Timer.Add(SelfieData, 0.1,function ()
			if not UIMgr.GetView(VIEW_ID.PanelLogin) then
				UIMgr.Open(VIEW_ID.PanelCamera, SelfieData.bNameCard)
			end
		end)
	end
	if KG3DEngine.GetPostRenderParams then
		SelfieData.tCurScenePostRenderParams =  KG3DEngine.GetPostRenderParams()
	end

	SelfieData.OnLoadingEnd()
	SelfieData.InitActivityPresetSetting()
end)

Event.Reg(SelfieData, EventType.OnAccountLogout, function()
	SelfieData._bLastInSelfieStudio = false
end)

Event.Reg(SelfieData, "LUA_ON_ACTIVITY_STATE_CHANGED_NOTIFY", function ()
    local dwActivityID = arg0
    local dwCurMapID = SelfieData.GetCurrentMapID()
    if Table_IsActivityNeedPreset(dwCurMapID, dwActivityID) then
        SelfieData.ResetFilterFromStorage() -- 特定地图在指定活动开启后切换环境预设
    end
end)

SelfieData._bLastInSelfieStudio = false
function SelfieData.OnLoadingEnd()
	SelfieData.nPresetIndex = 0
    local dwMapID = SelfieData.GetCurrentMapID()
	local bInSelfieStudio = SelfieData.IsInStudioMap()
	--LOG.INFO("SelfieData.OnLoadingEnd  %s-%s", tostring(SelfieData._bLastInSelfieStudio) , tostring(bInSelfieStudio))
	if SelfieData._bLastInSelfieStudio == bInSelfieStudio then
		return
	end
    SelfieData._bLastInSelfieStudio = bInSelfieStudio

    if bInSelfieStudio then
		rlcmd("hide player title")
		rlcmd("hide npc title")

		rlcmd(string.format("set show player title relation %u %u", RL_FORCE_RELATION.PARTY, 1))
		rlcmd(string.format("set show player title relation %u %u", RL_FORCE_RELATION.SELF, 1))

		rlcmd(string.format("set show npc title relation %u %u", RL_FORCE_RELATION.PARTY, 1))
		rlcmd(string.format("set show npc title relation %u %u", RL_FORCE_RELATION.SELF, 1))

		rlcmd("set hide shadow 1")
		rlcmd(string.format("set show shadow relation %u %u", RL_FORCE_RELATION.PARTY, 1))
		rlcmd(string.format("set show shadow relation %u %u", RL_FORCE_RELATION.SELF, 1))

		rlcmd(string.format("hide relation npc %u", RL_FORCE_RELATION.INVALID))
		rlcmd(string.format("hide relation npc %u", RL_FORCE_RELATION.FOE))
		rlcmd(string.format("hide relation npc %u", RL_FORCE_RELATION.ENEMY))
		rlcmd(string.format("hide relation npc %u", RL_FORCE_RELATION.NEUTRALITY))
		rlcmd(string.format("hide relation npc %u", RL_FORCE_RELATION.ALLY))


		rlcmd(string.format("_hide character water effect relation %u %u", RL_FORCE_RELATION.INVALID, 1))
		rlcmd(string.format("_hide character water effect relation %u %u", RL_FORCE_RELATION.FOE, 1))
		rlcmd(string.format("_hide character water effect relation %u %u", RL_FORCE_RELATION.ENEMY, 1))
		rlcmd(string.format("_hide character water effect relation %u %u", RL_FORCE_RELATION.NEUTRALITY, 1))
		rlcmd(string.format("_hide character water effect relation %u %u", RL_FORCE_RELATION.ALLY, 1))
		rlcmd(string.format("_hide character water effect relation %u %u", RL_FORCE_RELATION.NONE, 1))

		rlcmd("enable npc use employer relation 1")

		rlcmd("show or hide all doodad 0")

		rlcmd(string.format("hide sfx by character relation %u %u", RL_FORCE_RELATION.INVALID, 1))
		rlcmd(string.format("hide sfx by character relation %u %u", RL_FORCE_RELATION.FOE, 1))
		rlcmd(string.format("hide sfx by character relation %u %u", RL_FORCE_RELATION.ENEMY, 1))
		rlcmd(string.format("hide sfx by character relation %u %u", RL_FORCE_RELATION.NEUTRALITY, 1))
		rlcmd(string.format("hide sfx by character relation %u %u", RL_FORCE_RELATION.ALLY, 1))
		rlcmd(string.format("hide sfx by character relation %u %u", RL_FORCE_RELATION.NONE, 1))

		RLEnv.GetActiveVisibleCtrl():ShowPlayer(PLAYER_SHOW_MODE.kParter)
	else
		rlcmd(string.format("set show npc title relation %u %u", RL_FORCE_RELATION.PARTY, 0))
		rlcmd(string.format("set show npc title relation %u %u", RL_FORCE_RELATION.SELF, 0))

		rlcmd(string.format("set show player title relation %u %u", RL_FORCE_RELATION.PARTY, 0))
		rlcmd(string.format("set show player title relation %u %u", RL_FORCE_RELATION.SELF, 0))

		rlcmd("show npc title")
		rlcmd("show player title")

		rlcmd("set hide shadow 0")
		rlcmd(string.format("set show shadow relation %u %u", RL_FORCE_RELATION.PARTY, 0))
		rlcmd(string.format("set show shadow relation %u %u", RL_FORCE_RELATION.SELF, 0))

		rlcmd(string.format("show relation npc %u", RL_FORCE_RELATION.INVALID))
		rlcmd(string.format("show relation npc %u", RL_FORCE_RELATION.FOE))
		rlcmd(string.format("show relation npc %u", RL_FORCE_RELATION.ENEMY))
		rlcmd(string.format("show relation npc %u", RL_FORCE_RELATION.NEUTRALITY))
		rlcmd(string.format("show relation npc %u", RL_FORCE_RELATION.ALLY))

		rlcmd(string.format("_hide character water effect relation %u %u", RL_FORCE_RELATION.INVALID, 0))
		rlcmd(string.format("_hide character water effect relation %u %u", RL_FORCE_RELATION.FOE, 0))
		rlcmd(string.format("_hide character water effect relation %u %u", RL_FORCE_RELATION.ENEMY, 0))
		rlcmd(string.format("_hide character water effect relation %u %u", RL_FORCE_RELATION.NEUTRALITY, 0))
		rlcmd(string.format("_hide character water effect relation %u %u", RL_FORCE_RELATION.ALLY, 0))
		rlcmd(string.format("_hide character water effect relation %u %u", RL_FORCE_RELATION.NONE, 0))

		rlcmd("enable npc use employer relation 0")

		rlcmd("show or hide all doodad 1")

		rlcmd(string.format("hide sfx by character relation %u %u", RL_FORCE_RELATION.INVALID, 0))
		rlcmd(string.format("hide sfx by character relation %u %u", RL_FORCE_RELATION.FOE, 0))
		rlcmd(string.format("hide sfx by character relation %u %u", RL_FORCE_RELATION.ENEMY, 0))
		rlcmd(string.format("hide sfx by character relation %u %u", RL_FORCE_RELATION.NEUTRALITY, 0))
		rlcmd(string.format("hide sfx by character relation %u %u", RL_FORCE_RELATION.ALLY, 0))
		rlcmd(string.format("hide sfx by character relation %u %u", RL_FORCE_RELATION.NONE, 0))

		if not SelfieData.g_ShowPlayer then
			if SelfieData.g_ShowPartyPlayer then
				RLEnv.GetActiveVisibleCtrl():ShowPlayer(PLAYER_SHOW_MODE.kParter)
			else
				RLEnv.GetActiveVisibleCtrl():ShowPlayer(PLAYER_SHOW_MODE.kNone)
			end
		else
			RLEnv.GetActiveVisibleCtrl():ShowPlayer(PLAYER_SHOW_MODE.kAll)
		end
	end

end
---------------------------------------------------------------------------
------------------------------隐藏头顶信息----------------------------------
local l_bHidden, l_bHT_I_LEFE
function HideGlobalHeadTop()
	if not l_bHidden then
		local tCtrl = RLEnv.GetActiveVisibleCtrl()
		tCtrl:ShowAllHeadFlags(false)

		l_bHT_I_LEFE  = GetGlobalTopIntelligenceLife() SetGlobalTopIntelligenceLife(false)

		Global_UpdateHeadTopPosition()
		rlcmd("enable time percentage 0")
		l_bHidden = true
	end
end

function ResumeGlobalHeadTop()
	if l_bHidden then
		local tCtrl = RLEnv.GetActiveVisibleCtrl()
		tCtrl:RestoreHeadFlags()
		SetGlobalTopIntelligenceLife(l_bHT_I_LEFE)

		Global_UpdateHeadTopPosition()
		rlcmd("enable time percentage 1")
		l_bHidden = false
	end
end
---------------------------------------------------------------------------
------------------------------快捷键----------------------------------------
local tbKeycode2Img = {
    ["<"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyJianKHLeft' width='26' height='27'/>",
    [">"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyJianKHRight' width='26' height='27'/>",
    ["1"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_Key1' width='26' height='27'/>",
    ["6"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_Key6' width='26' height='27'/>",
    ["A"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyA' width='26' height='27'/>",
    ["C"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyC' width='26' height='27'/>",
    ["D"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyD' width='26' height='27'/>",
    ["E"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyE' width='26' height='27'/>",
    ["L"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyL' width='26' height='27'/>",
    ["O"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyO' width='26' height='27'/>",
    ["Q"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyQ' width='26' height='27'/>",
    ["R"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyR' width='26' height='27'/>",
    ["S"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyS' width='26' height='27'/>",
    ["U"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyU' width='26' height='27'/>",
    ["W"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyW' width='26' height='27'/>",
    ["X"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyX' width='26' height='27'/>",
    ["Y"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyY' width='26' height='27'/>",
    ["Z"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyZ' width='26' height='27'/>",
    ["V"]       = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyV' width='26' height='27'/>",
    ["F1"]      = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyF1' width='48' height='27'/>",
    ["F2"]      = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyF2' width='48' height='27'/>",
    ["F3"]      = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyF3' width='48' height='27'/>",
    ["F4"]      = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyF4' width='48' height='27'/>",
    ["F5"]      = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyF5' width='48' height='27'/>",
    ["F6"]      = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyF6' width='48' height='27'/>",
    ["LMB"]     = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_MouseLeftClick' width='26' height='27'/>",
    ["LMB_HM"]  = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_MouseLeftHoldMove' width='26' height='27'/>",
    ["LMB_DBL"] = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_MouseLeftHold' width='26' height='27'/>",
    ["MMB_HM"]  = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_MouseMiddleHoldMove' width='26' height='27'/>",
    ["MMB"]     = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_MouseMiddleScroll' width='26' height='27'/>",
    ["RMB"]     = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_MouseRightClick' width='26' height='27'/>",
    ["RMB_HM"]  = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_MouseRightHoldMove' width='26' height='27'/>",
    ["BKT_L"]   = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyFangKHLeft' width='26' height='27'/>",
    ["BKT_R"]   = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyFangKHRight' width='26' height='27'/>",
    ["CTRL"]    = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyCtrl' width='48' height='27'/>",
    ["DEL"]     = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyDel' width='48' height='27'/>",
    ["ALT"]     = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyAlt' width='48' height='27'/>",
    ["ESC"]     = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyEsc' width='48' height='27'/>",
	["ENTER"]     = "<img src='UIAtlas2_Home_HomeLandBuilding_VKHotKeys_Img_KeyEnter' width='48' height='27'/>",
}

local tbBulidHotkeyList = {
	{
		name = "重置镜头",
		szHotkey = "[CTRL]+[R]"
	},
	{
		name = "右移镜头",
		szHotkey = "[CTRL]+[D]"
	},
	{
		name = "左移镜头",
		szHotkey = "[CTRL]+[A]"
	},

	{
		name = "下移镜头",
		szHotkey = "[CTRL]+[S]"
	},
	{
		name = "上移镜头",
		szHotkey = "[CTRL]+[W]"
	},
	{
		name = "右翻镜头",
		szHotkey = "[CTRL]+[X]"
	},
	{
		name = "左翻镜头",
		szHotkey = "[CTRL]+[Z]"
	},
	{
		name = "定格角色表现",
		szHotkey = "[ENTER]"
	},
	{
		name = "拍照/录屏",
		szHotkey = "[CTRL]+[ENTER]"
	},
}

local function _GetHotkeyDescWithImg(szHotkey)
    local nHotkeyNum = 0
	local szContent = szHotkey
    local tbKeycode = string.gmatch(szContent, "%[([^%]]+)%]")
    for key in tbKeycode do
        local szFrame = tbKeycode2Img[key]
        szContent = string.gsub(szContent, "%[([^%]]+)%]", szFrame, 1)
        nHotkeyNum = nHotkeyNum + 1
    end
    szContent = string.gsub(szContent, "[%[%]]", "")
    return szContent, nHotkeyNum
end

function SelfieData.GetHomeBuildHotkeyList()
    local bFlag = false
    local tbHotkeyList = {}
    for k, v in ipairs(tbBulidHotkeyList) do
        local szContent, nHotkeyNum = _GetHotkeyDescWithImg(v.szHotkey)
        if nHotkeyNum >= 2 then
            table.insert(tbHotkeyList, {{szTitle = v.name, szContent = szContent}})
        elseif nHotkeyNum < 2 and bFlag then
            table.insert(tbHotkeyList[#tbHotkeyList], {szTitle = v.name, szContent = szContent})
            bFlag = false
        else
            table.insert(tbHotkeyList, {{szTitle = v.name, szContent = szContent}})
            bFlag = true
        end
    end
    return tbHotkeyList
end

---------------------------------------------------------------------------
------------------------------AR模式----------------------------------

SelfieData.bShowARTips = false

Event.Reg(SelfieData, EventType.OnRoleLogin, function()
    SelfieData.bShowARTips = true
end)

Event.Reg(SelfieData, "PLAYER_LEAVE_GAME", function ()
	SelfieMusicData.Clear()
end)

--设备是否支持AR模式
function SelfieData.IsDeviceAvailableCamera()
    return IsDeviceAvailableCamera() or GetCameraAuthorizeState() == CAMERA_AUTHORIZE_STATE.Denied
end

--打开AR模式
function SelfieData.StartCameraCapture()
    if GetCameraAuthorizeState() == CAMERA_AUTHORIZE_STATE.Denied then
        Permission.AskForSwitchToAppPermissionSetting(Permission.Camera)
    else
        StartCameraCapture()
    end
end

--关闭AR模式
function SelfieData.StopCameraCapture()
    StopCameraCapture()
end

---------------------------------------------------------------------------
------------------------------光源方向----------------------------------

--角色模型亮度
SelfieData.MODEL_BRIGHTNESS_MIN = -2.0
SelfieData.MODEL_BRIGHTNESS_MAX = 2.0

function SelfieData.GetMainLightDirection()
	return SelfieData.fHeadingAngle, SelfieData.fAltitudeAngle
end

function SelfieData.SetMainLightDirection(fHeadingAngle, fAltitudeAngle)
	if not fHeadingAngle or not fAltitudeAngle then
		return
	end
	SelfieData.fHeadingAngle = fHeadingAngle
	SelfieData.fAltitudeAngle = fAltitudeAngle
	local f3Vector = SelfieData.AngleToVector(fHeadingAngle, fAltitudeAngle)
	CameraMgr.SetMainLightDirection(-f3Vector.x, -f3Vector.y, -f3Vector.z) --因为编辑器端保存 environment.json 取反了
end

--Sword3\Source\KG3DEngine\KG3DEngineOpenGL\KEngine\rendervk\KEngineOptionsImgui.cpp

SelfieData.HEADING_ANGLE_MIN = -180.0
SelfieData.HEADING_ANGLE_MAX = 180.0
SelfieData.ALTITUDE_ANGLE_MIN = -90.0
SelfieData.ALTITUDE_ANGLE_MAX = 90.0

function SelfieData.AngleToVector(fHeadingAngle, fAltitudeAngle)
	if not fHeadingAngle then return end;
	if not fAltitudeAngle then return end;

	fHeadingAngle = cc.clampf(fHeadingAngle, SelfieData.HEADING_ANGLE_MIN + 0.1, SelfieData.HEADING_ANGLE_MAX - 0.1);
	fAltitudeAngle = cc.clampf(fAltitudeAngle, SelfieData.ALTITUDE_ANGLE_MIN + 0.1, SelfieData.ALTITUDE_ANGLE_MAX - 0.1);

	local f3Vector = {};

	-- 进行一次标准的三维坐标系到球坐标系的转换
	-- 参考http://zh.wikipedia.org/zh-cn/%E7%90%83%E5%9D%90%E6%A0%87%E7%B3%BB
	local f3Descartes = {};

	local fHeadingAngle_Radian = fHeadingAngle * (math.pi / 180.0);
	local fAltitudeAngle_Radian = fAltitudeAngle * (math.pi / 180.0);

	-- 1.1转成标准球坐标系
	local fTheta = math.pi / 2 - fAltitudeAngle_Radian;
	local fPhi = math.pi / 2 - fHeadingAngle_Radian;

	local fSinTheta = math.sin(fTheta);
	local fCosPhi = math.cos(fPhi);
	local fSinPhi = math.sin(fPhi);

	-- 1.2转成笛卡尔右手坐标系
	f3Descartes.x = fSinTheta * fCosPhi;
	f3Descartes.y = fSinTheta * fSinPhi;
	f3Descartes.z = math.cos(fTheta);

	-- 1.3转成DX左手坐标系
	f3Vector.x = f3Descartes.x;
	f3Vector.y = f3Descartes.z;
	f3Vector.z = f3Descartes.y;

	return f3Vector;
end

function SelfieData.VectorToAngle(f3Vector)
	if not f3Vector then return end;

	local fHeadingAngle;
	local fAltitudeAngle;
	local f3NormalizedVector = cc.vec3normalize(f3Vector);

	local function IsNearlyEqual(a, b) return math.abs(a - b) <= 1.0e-08 end

	-- 排除特殊情况
	if IsNearlyEqual(f3NormalizedVector.x, 0.0) and IsNearlyEqual(f3NormalizedVector.z, 0.0) then
		fHeadingAngle = 0.0;
		fAltitudeAngle = (f3NormalizedVector.y > 0.0) and 90.0 or -90.0;
		return fHeadingAngle, fAltitudeAngle;
	end

	-- 进行一次标准的三维坐标系到球坐标系的转换
	-- 参考http://zh.wikipedia.org/zh-cn/%E7%90%83%E5%9D%90%E6%A0%87%E7%B3%BB

	local fHeadingAngle_Radian;
	local fAltitudeAngle_Radian;

	-- 1.1转成标准笛卡尔右手坐标系
	local f3Descartes = { x = f3NormalizedVector.x, y = f3NormalizedVector.z, z = f3NormalizedVector.y };

	-- 1.2应用公式
	local fTheta = math.acos(f3Descartes.z / 1); -- 高度角，从顶轴开始，

	local fPhi = 0;
	if not IsNearlyEqual(f3Descartes.x, 0.0) then
		fPhi = math.atan(f3Descartes.y / f3Descartes.x); -- 角度角，从x开始，逆时针
	end

	-- 象限修正
	if f3Descartes.x > 0 then
		fHeadingAngle_Radian = math.pi / 2 - fPhi;
	elseif IsNearlyEqual(f3Descartes.x, 0.0) then
		fHeadingAngle_Radian = f3Descartes.y > 0 and 0 or math.pi;
	else
		fHeadingAngle_Radian = -math.pi / 2 - fPhi;
	end

	-- 1.3转换为地平坐标系
	fAltitudeAngle_Radian = math.pi / 2 - fTheta;

	-- 1.4弧度制转角度制
	fHeadingAngle = fHeadingAngle_Radian * (180.0 / math.pi);
	fAltitudeAngle = fAltitudeAngle_Radian * (180.0 / math.pi);

	return fHeadingAngle, fAltitudeAngle
end
SelfieData.bCanSetFuncInfo = true
function SelfieData.SetSelfieFuncInfoByTypeID(nType, fValue)
	if SelfieData.bCanSetFuncInfo then
		if nType == Selfie_BaseSettingType.FilterQD then
			SelfieData.SetFilterSliderFuncInfoByParamID(1 , fValue)
		elseif nType == Selfie_BaseSettingType.FilterLD then
			SelfieData.SetFilterSliderFuncInfoByParamID(2 , fValue)
		elseif nType == Selfie_BaseSettingType.FilterDBD then
			SelfieData.SetFilterSliderFuncInfoByParamID(3 , fValue)
		elseif nType == Selfie_BaseSettingType.FilterBHD then
			SelfieData.SetFilterSliderFuncInfoByParamID(4 , fValue)
		elseif nType == Selfie_BaseSettingType.FilterAJ then
			SelfieData.SetFilterSliderFuncInfoByParamID(5 , fValue)
		elseif nType == Selfie_BaseSettingType.FilterKL then
			SelfieData.SetFilterSliderFuncInfoByParamID(6 , fValue)
		elseif nType == Selfie_BaseSettingType.FilterBGZ then
			SelfieData.SetFilterSliderFuncInfoByParamID(7 , fValue)
		elseif nType == Selfie_BaseSettingType.FilterRG then
			SelfieData.SetFilterSliderFuncInfoByParamID(8 , fValue)
		elseif nType == Selfie_BaseSettingType.FilterJTSC then
			SelfieData.SetFilterSliderFuncInfoByParamID(9 , fValue)
		elseif nType == Selfie_BaseSettingType.FilterGG then
			SelfieData.SetFilterSliderFuncInfoByParamID(10 , fValue)
		end
	end
end


function SelfieData.SetNewFilter(nIndex)
	SelfieData.SafeChangeFilter(nIndex, true)
	local tbParams = SelfieData.GetFilterParamSettingByDefaultValues(nIndex)
	for k, v in pairs(SelfieData.tbBasFilterContent) do
		if v.nType ~= Selfie_BaseSettingType.FilterQD then
			local nValue = tbParams[k]
			SelfieData.SetSelfieFuncInfoByTypeID(v.nType, nValue + 0.0000000001)
		end
	end
end

function SelfieData.EnableFilterPostEffect(bEnable)
    KG3DEngine.SetPostEffectParam(1, POST_EFFECT_PARAM_ID.POST_EFFECT_ENABLE, bEnable)
end

function SelfieData.HideFilterExEffect()
	for k, tSetInfo in pairs(tFilterBase.SELFIE_EX_SLIDER_FUNC_PARAM) do
		if tSetInfo.nType == 1 then
			KG3DEngine.SetPostEffectParam(1, tSetInfo.nPostEffectParam, false)
		end
	end

end

function SelfieData.l_fnSaturate(fValue)
	return math.min(math.max(fValue, 0.0), 1.0)
end

function SelfieData.l_fnFloatEqual(fValue1, fValue2)
	return math.abs(fValue1-fValue2) < 0.0001
end

function SelfieData.RGBToHSV(r, g, b)
	r = SelfieData.l_fnSaturate(r)
	g = SelfieData.l_fnSaturate(g)
	b = SelfieData.l_fnSaturate(b)
	local max = math.max(r, g, b)
	local min = math.min(r, g, b)
	local delta = max - min
	local h
	if SelfieData.l_fnFloatEqual(max, min) then
		h = 0
	else
		if SelfieData.l_fnFloatEqual(max, r) then
			if g >= b then
				h = 60.0 * (g-b) / delta
			else
				h = 60.0 * (g-b) / delta + 360.0
			end
		elseif SelfieData.l_fnFloatEqual(max, g) then
			h = 60.0 * (b-r) / delta + 120.0
		else
			h = 60.0 * (r-g) / delta + 240.0
		end
	end
	local s = SelfieData.l_fnFloatEqual(max, 0.0) and 0.0 or (delta / math.max(max, 0.0001))
	local v = max
	return h, s, v
end

function SelfieData.HSVToRGB(h, s, v)
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

function SelfieData.RetrieveOneLightDefaultParams(tLightParams)
	local _STR_2_LIGHT_TYPE =
	{
		["Point"] = CHARACTER_LIGHT.POINT,
		["Directional"] = CHARACTER_LIGHT.DIRECTIONAL,
		["Spot"] = CHARACTER_LIGHT.POINT, -- 目前没有聚光灯，只有点光
	}

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
		t.Radius = tLightData.SpotLight.Length
	end

	return t
end

function SelfieData.UpdateLightDefaultParam()
	local tAllLightDefaultParams = {}
	local szText = Lib.GetStringFromFile(_DEFAULT_LIGHT_PARAMS_PATH)
    local aAllLightParams, szErrMsg = JsonDecode(szText)
	local tTabParams = Table_GetAllSelfieLightParams()
	local nLightCount = math.min(#aAllLightParams, #tTabParams)
	for i = 1, nLightCount do
		local tLightParams = aAllLightParams[i]
		local t = SelfieData.RetrieveOneLightDefaultParams(tLightParams)
        local aAllLightConfigParams = tTabParams
        local tConfigParams = aAllLightConfigParams[i]
        local aColorList = tConfigParams.aColorList
        local tFirstColor = aColorList[1]
        t.Color = {r = tFirstColor[1] / 255, g = tFirstColor[2] / 255, b = tFirstColor[3] / 255 }
        table.insert(tAllLightDefaultParams, t)
		SelfieData.Light_CurrentData[i] = {
			[1] = t.Intensity,
			[2] = 1,
			[3] = 0.5,
			[4] = false,
			tColorSaturation = {},
			Translation = {},
		}
	end
    SelfieData.Light_DefaultData = tAllLightDefaultParams
end

function SelfieData.InitLightData(aAllLightParams, aAllLightConfigParams)
	local nLightCount = math.min(#aAllLightParams, #aAllLightConfigParams)
	for i = 1, nLightCount do
		local tLightParams = aAllLightParams[i]
		local t = SelfieData.RetrieveOneLightDefaultParams(tLightParams)
        local tConfigParams = aAllLightConfigParams[i]
        local aColorList = tConfigParams.aColorList
        local tFirstColor = aColorList[1]
        -- assert(tFirstColor)
        t.Color = {r = tFirstColor[1] / 255, g = tFirstColor[2] / 255, b = tFirstColor[3] / 255 }

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
end

function SelfieData.SetLightData(tLightData)
	local szText = Lib.GetStringFromFile(_DEFAULT_LIGHT_PARAMS_PATH)
    local aAllLightParams, szErrMsg = JsonDecode(szText)
	local aAllLightConfigParams = Table_GetAllSelfieLightParams()
	SelfieData.InitLightData(aAllLightParams, aAllLightConfigParams)

	local tDefData = clone(SelfieData.Light_DefaultData)
	for nLightIndex, tDefParam in ipairs(tDefData) do
		local fIntensity = tLightData[nLightIndex][1]  -- 灯的强度、饱和、颜色
		local nColorIndex = tLightData[nLightIndex][2]
		local fSaturation = tLightData[nLightIndex][3]
		local tConfigParams = aAllLightConfigParams[nLightIndex]
		local tColor = tConfigParams.aColorList[nColorIndex]
		local r, g, b = tColor[1], tColor[2], tColor[3]
		if fSaturation then
			local h, s, v = SelfieData.RGBToHSV(r / 255, g / 255, b / 255)
			r, g, b = SelfieData.HSVToRGB(h, fSaturation, v)
		end
		local tParams = tDefParam
		tParams.Intensity = fIntensity
		tParams.Color.r = r
		tParams.Color.g = g
		tParams.Color.b = b
		CharacterLight.SetParam(nLightIndex - 1, tParams)

		local bTurnOn = tLightData[nLightIndex][4]  -- 灯的开关与位置
		if bTurnOn then
			CharacterLight.Enable(nLightIndex - 1)
			local tTranslation = tLightData[nLightIndex].Translation
			local nPercentX = tTranslation.x + 0.0000000001
			local nPercentY = tTranslation.y + 0.0000000001
			local nPercentZ = tTranslation.z + 0.0000000001
			if nPercentX and nPercentY and nPercentZ then
				CharacterLight.SetTranslation(nLightIndex - 1, nPercentX, nPercentY, nPercentZ)
			end
		else
			CharacterLight.Disable(nLightIndex - 1)
		end
	end
end

function SelfieData.GetLightData()
	SelfieData.Light_CurrentData.nVersion = 1
	return SelfieData.Light_CurrentData
end

function SelfieData.SetClothWind()
	for k, v in pairs(SelfieData.Wind_DefaultData) do
		if not self.Wind_CurrentData[k] then
			self.Wind_CurrentData[k] = v
		end
	end
	rlcmd(string.format("set local cloth wind %f %d %d %d %f", self.Wind_CurrentData.nStrength, self.Wind_CurrentData.nX, self.Wind_CurrentData.nY, self.Wind_CurrentData.nZ, self.Wind_CurrentData.nFrequency))
	rlcmd(string.format("set character dir arrow %d %d %d", self.Wind_CurrentData.nX, self.Wind_CurrentData.nY, self.Wind_CurrentData.nZ))
end

function SelfieData.GetClothWind()
	local tWind = self.Wind_CurrentData
	tWind.bCloth = SelfieData.bClothEnable or false
	tWind.bWind = SelfieData.bWindEnable or false
	return clone(tWind)
end

function SelfieData.GetBaseData()
	local tBase = {
		bIsLookAt = SelfieData.bEyeFollow,
		bIsFocus = SelfieData.bCameraSmoothing,
		bEnableBloom = SelfieData.bEnableBloom,
		tFocusPos = SelfieData.tFocusPos,
		tLookAtPos = SelfieData.tLookAtPos,
		tSelfieCamera = SelfieData.tSelfieCamera,
		tShowHide = {},
	}
	tBase.tSelfieCamera.bAdvancedDOFChecked = SelfieData.bOpenAdvancedDof
	tBase.tShowHide = {
		bHideNPC = not SelfieData.g_ShowNPC,
		bHideSelf = not SelfieData.g_ShowSelf,
		bShowAllPlayers = SelfieData.g_ShowPlayer,
		bOnlyTeammates = SelfieData.g_ShowPartyPlayer,
		bShowFeature = SelfieData.bShowFaceCount,
		tRoleBoxCheck = SelfieData.tRoleBoxCheck,
	}
	local fScale, fYaw, fPitch = Camera_GetRTParams()
	local offsetx, offsety, offsetz, offsetAngle = CameraMgr.TranslationOffset()
	fScale = (fScale >= _MIN_EXPORT_NUM) and fScale or 0
	fYaw = (fYaw >= _MIN_EXPORT_NUM) and fYaw or 0
	fPitch = (fPitch >= _MIN_EXPORT_NUM) and fPitch or 0
	tBase.tSelfieCamera.tRTParams = {
		fScale = fScale,
		fYaw = fYaw,
		fPitch = fPitch,
		nTick = 1000,
		nOffsetX = offsetx,
		nOffsetY =  offsety,
		noffsetZ =  offsetz,
		nOffsetAngle = offsetAngle,
	}

	return tBase
end

local nFilterDataParamsOffset = 11
function SelfieData.GetFilterData()
	local dwMapID = g_pClientPlayer.GetMapID()

	local tFilter = {}
	if SelfieData.tbMapParams and not IsTableEmpty(SelfieData.tbMapParams) then
		tFilter.tMapParams = {
			[dwMapID] = SelfieData.tbMapParams
		}
	end
	tFilter.nVersion = 1
	tFilter.nFilterIndex = SelfieData.nCurSelectFilterIndex
	tFilter.aParams = {}
	tFilter.tEnableExParamClass = {}
	tFilter.tVKExParams = {}
	tFilter.tColor = SelfieData.tSelColorID

	for k, v in pairs(SelfieData.tbFilterCacheInfo) do
		tFilter.aParams[k - nFilterDataParamsOffset] = v -- 这个数据上传之后在DX也会用，统一为从1开始
	end

	for nClassID, tInfo in pairs(SelfieData.tExtraCell) do
		tFilter.tEnableExParamClass[nClassID] = tInfo.bEnable or false
		tFilter.tVKExParams[nClassID] = {}
		local tsubCell = tInfo.tSubCells
		for _, subCell in pairs(tsubCell) do
			if subCell.nParamID then
				tFilter.tVKExParams[nClassID][subCell.nParamID] = subCell.sliderValue or 0
			end
		end
	end

	return clone(tFilter)
end

-- tFilter.aParams -> tParam
function SelfieData.ExtractFilterDataParams(tFilter)
	if not tFilter or not tFilter.aParams then
		return
	end

	local tParams = {}
	for k, v in pairs(tFilter.aParams) do
		tParams[k + nFilterDataParamsOffset] = v
	end
	return tParams
end

function SelfieData.ResetClothWindData()
	Event.Dispatch(EventType.OnSelfieClothWindResetData)
end

SelfieData.bShowClothWindArror = false
function SelfieData.ShowClothWind(bShow)
	SelfieData.bShowClothWindArror = bShow
	local nSet = bShow and 1 or 0
	rlcmd(string.format("enable character dir arrow %d",nSet))
	if bShow then
		SelfieData.SetClothWind()
	end

end
SelfieData.bOpenAgain = false

function SelfieData.IsInStudioMap()
    local player = GetClientPlayer()
	if not player then
		return
    end
    local nMapID = SelfieData.GetCurrentMapID()
    for k, v in ipairs(SELFIE_STUDIO_MAP_LIST) do
        if v == nMapID then
            return true
        end
    end
    return false
end

function SelfieData.IsStudioMap(dwMapID)
	if not dwMapID then
		return
	end
    for k, v in ipairs(SELFIE_STUDIO_MAP_LIST) do
        if v == dwMapID then
            return true
        end
    end
    return false
end

function SelfieData.GetCurrentMapID()
    local hPlayer = GetClientPlayer()
    local dwMapID = 0
    local dwMapType = 0
    local mapName = 0
	if hPlayer then
		dwMapID = hPlayer.GetMapID()
		mapName, dwMapType = GetMapParams(dwMapID)
	end
	return dwMapID, dwMapType
end

function SelfieData.OnLeaveStudioScene(bAgain)
	local dialog = UIHelper.ShowConfirm(g_tStrings.STR_SELFIE_STUDIO_LEAVE_MSG, function()
		SelfieData.bOpenAgain = bAgain
		RemoteCallToServer("On_PhotoStudio_Leave")
	end)
	dialog:SetButtonContent("Confirm", g_tStrings.STR_HOTKEY_SURE)
	dialog:SetButtonContent("Cancel", g_tStrings.STR_HOTKEY_CANCEL)
end

SelfieData.nPresetIndex = 0
function SelfieData.IsSetPresetInStudio()
	if SelfieData.IsInStudioMap() then
		return SelfieData.nPresetIndex > 0
	end
	return false
end
----------------------------Movie-----------------------------
local szMovieAIContentProducer = nil
local szMovieAISettingFile = "/ui/Scheme/Setting/SelfieMovieAISetting.ini"
local nMovieAIReserverdID = 0
local bAgreeStatementFlag
local function GetMovieAIContentProducer()
    if szMovieAIContentProducer then
        return szMovieAIContentProducer
    end

    szMovieAIContentProducer = ""
    local pFile = Ini.Open(szMovieAISettingFile)
    if pFile then
        szMovieAIContentProducer = pFile:ReadString("MovieAI", "ContentProducer", "")
        pFile:Close()
    end
    return szMovieAIContentProducer
end

function SelfieData.SetAIParam()
    local player = GetClientPlayer()
    if not player then
        return
    end

    local dwPlayerID = UI_GetClientPlayerGlobalID() or 0
    local nTimeStamp = GetCurrentTime()
    local szContentProducer = GetMovieAIContentProducer()
    local szProductID = string.format("%s-%d", tostring(dwPlayerID), nTimeStamp)

    nMovieAIReserverdID = nMovieAIReserverdID + 1
    local szReserverdCode = string.format("%s-%d-%d", tostring(dwPlayerID), nTimeStamp, nMovieAIReserverdID)

    SetMovieAIParam(szContentProducer, szProductID, szReserverdCode)
end

function SelfieData.SetAgreeStatementFlag(bFlag)
    bAgreeStatementFlag = bFlag
end

function SelfieData.GetAgreeStatementFlag()
    return bAgreeStatementFlag
end

----------------------------视频分享相关-----------------------------

function SelfieData.GetURL()
	local bTestMode = IsDebugClient()
    if bTestMode then
        return WEB_URL_TEST
    end

    return WEB_URL
end

function SelfieData.ShareLoginAccount()
	WebUrl.ApplySignWeb(ApplyLoginSignWebID, WEB_DATA_SIGN_RQST.LOGIN)
end

function SelfieData.OnWebDataSignNotify()
    local szComment = arg6
	local dwApplyWebID = szComment:match("APPLY_WEBID_(.*)")
	if dwApplyWebID then
		dwApplyWebID = tonumber(dwApplyWebID)
        if dwApplyWebID ~= ApplyLoginSignWebID then
            return
        end
		local uSign = arg0
		local nTime = arg2
		local nZoneID = arg3
		local dwCenterID = arg4
		SelfieData.OnLoginAccount(dwApplyWebID, uSign, nTime, nZoneID, dwCenterID, false)
	end
end

function SelfieData.OnLoginWebDataSignNotify()
    local szComment = arg2
	local dwApplyWebID = szComment:match("APPLY_LOGIN_WEBID_(.*)")
	if dwApplyWebID then
		dwApplyWebID = tonumber(dwApplyWebID)
        if dwApplyWebID ~= ApplyLoginSignWebID then
            return
        end
		local uSign = arg0
		local nTime = arg1
		local nZoneID = 0
		local dwCenterID = 0
		SelfieData.OnLoginAccount(dwApplyWebID, uSign, nTime, nZoneID, dwCenterID, true)
	end
end

function SelfieData.OnLoginAccount(dwID, uSign, nTime, nZoneID, dwCenterID, bLogin)
    local dwPlayerID = 0
    local dwForceID = 0
    local szRoleName = ""
    local dwCreateTime = 0
    local szGlobalID = ""
	local szAccount = Login_GetAccount()
    local szDefaultParam

    if bLogin then
        szDefaultParam = "params=%d/%s//%d///////%d/%d"
	    szDefaultParam = string.format(szDefaultParam, uSign, szAccount, nTime, dwCreateTime, GetAccountType())
    else
        local player = PlayerData.GetClientPlayer()
        if player then
            dwPlayerID = player.dwID
            dwForceID = player.dwForceID
            szRoleName =  UrlEncode(UIHelper.GBKToUTF8(player.szName))
            dwCreateTime = player.GetCreateTime()
            szGlobalID = player.GetGlobalID()
        end

        local szUserRegion, szUserSever = WebUrl.GetServerName()
        --param=sign/account/roleID/time/zoneID/centerID/测试区/测试服/门派ID/角色名称/角色创建时间/账号类型
        szDefaultParam = "params=%d/%s/%d/%d/%d/%d/%s/%s/%d/%s/%d/%d"
        szDefaultParam = string.format(
            szDefaultParam, uSign, szAccount, dwPlayerID, nTime, nZoneID,
            dwCenterID, UrlEncode(szUserRegion), UrlEncode(szUserSever),
            dwForceID, szRoleName, dwCreateTime, GetAccountType()
        )
    end

    SelfieData.szDefaultParam = szDefaultParam
    local szUrl = SelfieData.GetURL()
    local szPostUrl = string.format("%s%s?%s", szUrl, PostUrl.LOGIN_ACCOUNT, szDefaultParam)
	LOG.INFO("CURL_HttpPost   key:%s , url:%s",PostKey.LOGIN_ACCOUNT,szPostUrl)
    CURL_HttpPost(PostKey.LOGIN_ACCOUNT, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

-- 请求获取剩余上传次数
function SelfieData.ReqGetUploadTime()
	local szUrl = SelfieData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s", szUrl, PostUrl.GET_UPLOAD_TIME,SelfieData.szUploadVideoSessionID)
	LOG.INFO("CURL_HttpPost   key:%s , url:%s",PostKey.GET_UPLOAD_TIME,szPostUrl)
	CURL_HttpPost(PostKey.GET_UPLOAD_TIME, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function SelfieData.ReqGetUploadToken(szFilePath, szFileName)
	SelfieData.szUploadFileName = szFileName
	SelfieData.szUploadFilePath = szFilePath
    local szUrl = SelfieData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s",szUrl,PostUrl.GET_UPLOAD_TOKEN,SelfieData.szUploadVideoSessionID)
	LOG.INFO("CURL_HttpPost   key:%s , url:%s",PostKey.GET_UPLOAD_TOKEN,szPostUrl)
    CURL_HttpPost(PostKey.GET_UPLOAD_TOKEN, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function SelfieData.DoUploadVideo(szUrl, tbUploadToken)

    if string.is_nil(szUrl) then
        LOG.ERROR("SelfieData.DoUploadVideo Error! szUrl is nil")
        return
    end

    if not tbUploadToken or table.is_empty(tbUploadToken) then
        LOG.ERROR("SelfieData.DoUploadVideo Error! tbUploadToken is nil")
        return
    end

    local szFilePath = string.gsub(SelfieData.szUploadFilePath, "\\", "/")
	if Platform.IsMobile() then
        szFilePath = UIHelper.GBKToUTF8(szFilePath)
    end
    local tbParams = {
        upload_file =
		{
			key = "file",
			content_type = "multipart/form-data",
			file = szFilePath,
            filename = SelfieData.szUploadFileName,
		},
		name = SelfieData.szUploadFileName,
        key = tbUploadToken.key,
        token = tbUploadToken.token,
        domain = tbUploadToken.domain,
    }
	LOG.INFO("CURL_HttpPost   key:%s , url:%s ,%s,%s",PostKey.DO_UPLOAD_VIDEO,szUrl,szFilePath,SelfieData.szUploadFileName)
    CURL_HttpPost(PostKey.DO_UPLOAD_VIDEO, szUrl, tbParams, true, 60, 60, {"Content-Type:multipart/form-data"})
end

function SelfieData.ReqVideoUploadLog(szFileID, szVideoUrl)
	if not szVideoUrl then
        LOG.ERROR("SelfieData.ReqVideoUploadLog Error! szVideoUrl is nil")
        return
    end

    if not szFileID then
        LOG.ERROR("SelfieData.ReqVideoUploadLog Error! szFileID is nil")
        return
    end

    local szUrl = BodyCodeData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s&file_id=%s&video_url=%s",
        szUrl,
        PostUrl.UPLOAD_VIDEO,
		SelfieData.szUploadVideoSessionID,
        szFileID,
        szVideoUrl)

    CURL_HttpPost(PostKey.UPLOAD_VIDEO, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end
--------------------------------------------------------------------

function SelfieData.SetEnvPreset(dwID)
	if not dwID then
		return
	end
	if not SelfieData.IsInStudioMap() then
		return
	end
	LOG.INFO("SelfieData.SetEnvPreset set env preset dwID:%d", dwID)
	rlcmd(string.format("set env preset %d", dwID))
	SelfieData.ChangeDynamicWeather(0)
	if not SelfieData.CanShowFilterSettingPage() then
        return
    end

	Event.Dispatch(EventType.SelfieFilterSettingReset)

	-- 设置环境预设会修改景深相关参数，需再环境预设修改后重置
	QualityMgr._UpdateBlurSize()

	local pScene = SceneMgr.GetGameScene()
	if pScene and not QualityMgr.bDisableCameraLight then
		pScene:OpenCameraLight("", true)	-- 开启镜头光
	end
end
