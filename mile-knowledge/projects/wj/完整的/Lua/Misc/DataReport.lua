-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: DataReport
-- Date: 2024-02-23 15:48:30
-- Desc: 上报统计相关
-- ---------------------------------------------------------------------------------

DataReport = DataReport or {className = "DataReport"}
local self = DataReport

function DataReport.Init()
    self.Reset_PakV4DownLoadInfo()

    Event.Reg(self, "LOADING_END", function()
        self.tbLoadData.dwLoadUICostTime = (self.tbLoadData.dwLoadUIBeginTime > 0) and (GetTickCount() - self.tbLoadData.dwLoadUIBeginTime) or 0
        self.Report_PakV4DownLoadInfo(true)

        UIMgr.ReportOpenedViewList()
        self.ReportExtDevice()
    end)

    Event.Reg(self, EventType.OnGamepadTypeChanged, function()
        self.ReportExtDevice()
    end)

    Event.Reg(self, "OnMobileKeyboardConnected", function()
        self.ReportExtDevice()
    end)

    Event.Reg(self, "OnMobileKeyboardDisConnected", function()
        self.ReportExtDevice()
    end)

    Event.Reg(self, "SCENE_BEGIN_LOAD", function(dwMapID, szPath)
        local nNow = GetTickCount()
        self.tbLoadData.dw3DSceneLoadBeginTime = nNow
        self.tbLoadData.dwLoadingBeginTime = nNow
        self.tbLoadData.dwLoadingMapID = dwMapID
    end)

    Event.Reg(self, "ON_3DSCENE_LOADED", function(dwSceneID, bSuccess)
        self.tbLoadData.dw3DSceneLoadCostTime = (self.tbLoadData.dw3DSceneLoadBeginTime > 0) and (GetTickCount() - self.tbLoadData.dw3DSceneLoadBeginTime) or 0

        if bSuccess then return end

        local logicScene = GetClientScene()
		if logicScene and logicScene.dwID == dwSceneID then
			self.Report_PakV4DownLoadInfo(false)
		end
    end)

    Event.Reg(self, "SYNC_ROLE_DATA_BEGIN", function()
        self.tbLoadData.dwSyncRoleDataBeginTime = GetTickCount()
    end)

    Event.Reg(self, "SYNC_ROLE_DATA_END", function()
        self.tbLoadData.dwSyncRoleDataCostTime = (self.tbLoadData.dwSyncRoleDataBeginTime > 0) and (GetTickCount() - self.tbLoadData.dwSyncRoleDataBeginTime) or 0
    end)

    Event.Reg(self, EventType.UILoadingProgressBegin, function()
        self.tbLoadData.dwLoadUIBeginTime = GetTickCount()
    end)

    Event.Reg(self, "FIRST_LOADING_END", function()
        self.ReportEngineOptions()
    end)

    Event.Reg(self, "ON_REMOTE_REPORT_NOTIFY", function(uType, _uValue)
        if uType == Const.ReportType.Render then
            -- DataReport.RpeortRender()
        end
    end)

    -- Event.Reg(self, EventType.OnViewClose, function(nViewID)
    --     if nViewID ~= VIEW_ID.PanelLoading then return end

    --     self.tbLoadData.dwLoadUICostTime = (self.tbLoadData.dwLoadUIBeginTime > 0) and (GetTickCount() - self.tbLoadData.dwLoadUIBeginTime) or 0
    -- end)
end

function DataReport.UnInit()

end

-- 上报 PakV4DownLoadInfo 其中包括过图时间等
function DataReport.Report_PakV4DownLoadInfo(bLoad3DSceneSuccess)
    self.tbLoadData.dwLoadingCostTime = bLoad3DSceneSuccess and (GetTickCount() - self.tbLoadData.dwLoadingBeginTime) or 0

    local tData =
	{
		--- 基础部分
		uuid = GetUUID(),--XGSDK_GetDeviceId(),
		account = Login_GetAccount() or "",
		global_role_id = g_pClientPlayer and g_pClientPlayer.GetGlobalID() or "",
		video_grade = QualityMgr.GetRecommendQualityType(),

		--- 时间统计部分
		map_id = self.tbLoadData.dwLoadingMapID,
		map_name = "",
		map_success = bLoad3DSceneSuccess and 1 or 0,
		error = 0,  --- 进入地图失败的错误代码，现在总是0
		logic_load_time = bLoad3DSceneSuccess and GetRoundedNumber(self.tbLoadData.dwSyncRoleDataCostTime / 1000) or 0,
		scene_load_time = bLoad3DSceneSuccess and GetRoundedNumber(self.tbLoadData.dw3DSceneLoadCostTime / 1000) or 0,
		ui_load_time = bLoad3DSceneSuccess and GetRoundedNumber(self.tbLoadData.dwLoadUICostTime / 1000) or 0,
		total_load_time = bLoad3DSceneSuccess and GetRoundedNumber(self.tbLoadData.dwLoadingCostTime / 1000) or 0,

		--- PakV4下载信息部分
		is_pakv4 = 0,
		loading_openfile_error_count = 0,  --- 累计打开文件失败次数
		loading_download_error_count = 0,  --- 累计下载失败次数
		pakv4_read_priority = 0,
		addon_test_account = 0,

        -- 这个表的字段不能随意加，要和数据中心的同学对齐沟通，他们要改数据库的
	}

	--if not IsDebugClient() then  --- 只在外网上传数据
		CURL_HttpPost("PakV4DownLoadInfo", tUrl.PakV4SceneLoadinginfo, tData)
	--end

    self.Reset_PakV4DownLoadInfo()
end

function DataReport.Reset_PakV4DownLoadInfo()
    self.tbLoadData =
    {
        dwLoadingMapID = 0,
        dwLoadingBeginTime = -1,

        dw3DSceneLoadBeginTime = -1,
        dw3DSceneLoadCostTime = 0,

        dwSyncRoleDataBeginTime = -1,
        dwSyncRoleDataCostTime = 0,

        dwLoadUIBeginTime = -1,
        dwLoadUICostTime = 0,
    }
end

function DataReport.Report_QualityInfo()
    local hPlayer = GetClientPlayer()
    local dwMapID = 0
    if hPlayer then
        dwMapID = hPlayer.GetMapID()
    end

    local tData = {
        --- 基础部分
        uuid = GetUUID(), --XGSDK_GetDeviceId(),
        global_role_id = g_pClientPlayer and g_pClientPlayer.GetGlobalID() or "",
        map_id = dwMapID,

        --- 画质信息部分
        fps = FPS_OPTION_NAME_TO_VALUE[GameSettingData.GetNewValue(UISettingKey.FrameRateLimit).szDec], -- number
        quality_setting_type = GameSettingData.GetNewValue(UISettingKey.GraphicsQuality), -- number

        camp_same_model = tostring(GameSettingData.GetNewValue(UISettingKey.FactionModel)),  -- boolean
        render_limit = GameSettingData.GetNewValue(UISettingKey.PlayersOnScreen), -- number
        render_npc_limit = GameSettingData.GetNewValue(UISettingKey.NPCsOnScreen), -- number
        sfx_limit = GameSettingData.GetNewValue(UISettingKey.EffectsOnScreen), -- number
        other_sfx_limit = GameSettingData.GetNewValue(UISettingKey.OtherPlayerEffects), -- number
        self_effect_quality = GameSettingData.GetNewValue(UISettingKey.SelfEffectQuality).szDec,  -- string
        other_effect_quality = GameSettingData.GetNewValue(UISettingKey.OtherEffectQuality).szDec, -- string
        render_resolution = GameSettingData.GetNewValue(UISettingKey.RenderResolution).szDec,  -- string
        render_precision = GameSettingData.GetNewValue(UISettingKey.RenderPrecision).szDec, -- string
        shadow_level = GameSettingData.GetNewValue(UISettingKey.ShadowQuality).szDec, -- string
        anti_alias = GameSettingData.GetNewValue(UISettingKey.AntiAliasing).szDec, -- string

        backup_1 = GameSettingData.GetNewValue(UISettingKey.AmbientOcclusion) and 1 or 0, -- boolean
        backup_2 = GameSettingData.GetNewValue(UISettingKey.BloomEffect) and 1 or 0, -- boolean
        backup_3 = GamepadData.GetGamepadType(), -- 手柄类型 0：无, 1：PS4, 2：PS5, 3：XBox, 4：Switch
        backup_4 = KeyBoard.MobileHasKeyboard() and 1 or 0, -- 移动端是否连接了蓝牙键盘
        --backup_5 = 10,
        --backup_6 = 10,
        --backup_7 = 10,
        --backup_7 = 10,
        --backup_8 = 10,
        --backup_9 = 10,
        --backup_10 = 10,
    }

    for k,v in pairs(tData) do
        local convertedNumber = QualityNameToTypeEnum[v]
        if convertedNumber then
            tData[k] = convertedNumber -- 将中文选项档位转换为对应数字
        end
    end

    if Platform.IsMobile() then
        tData["irx_render"] = tostring(GameSettingData.GetNewValue(UISettingKey.IRXRenderBoost)) -- boolean
    end

    if not IsDebugClient() then  --- 只在外网上传数据
        CURL_HttpPost("VideoSetting", tUrl.VideoSettingLog, tData)
    end
end

function DataReport.ReportEngineOptions()
    local function report_format(v)
        if type(v) == "number" then
            if v % 1 == 0 then
                return tostring(v)
            else
                return string.format("%.3f", v)
            end
        else
            return tostring(v):gsub('=', ''):gsub(',', ''):gsub(';', '')
        end
    end

    local tbOptions = {}
    local tbEngineOptions = KG3DEngine.GetEngineOptionsAdapter()
    for k, v in pairs(tbEngineOptions) do
        table.insert(tbOptions, k.."="..report_format(v))
    end
    table.sort(tbOptions)

    local szOptions = nil
    for k, v in ipairs(tbOptions) do
        if not szOptions then
            szOptions = v
        else
            szOptions = szOptions ..','.. v
        end

        if string.len(szOptions) > 2048 * 0.8 or k == #tbOptions then  -- protocol size limit 2048 [see KGPlayerActionLog.uCommentSize <= LOG_COMMENT_MAX_SIZE]
            ReportEngineOptions(szOptions)
            szOptions = nil
        end
    end
end

function DataReport.ReportTouch(szTouchRecord)
    local tbSize = UIHelper.GetWinSize()
    local eventBody = {
        {"win_width", tostring(tbSize.width)},
        {"win_height", tostring(tbSize.height)},
        {"touch_record", szTouchRecord}
    }
    XGSDK_TrackEvent("game.report.touch", "report", eventBody)
end

function DataReport.ReportExtDevice()
    local eventBody = {
        {"plat", Platform.GetPlatformName()}, -- 平台
        {"game_pad_type", tostring(GamepadData.GetGamepadType())}, -- 手柄类型 0：无, 1：PS4, 2：PS5, 3：XBox, 4：Switch
        {"mobile_has_keyboard", tostring(KeyBoard.MobileHasKeyboard() and 1 or 0)}, -- 移动端是否连接了蓝牙键盘
    }

    XGSDK_TrackEvent("game.ext.device", "report", eventBody)
end