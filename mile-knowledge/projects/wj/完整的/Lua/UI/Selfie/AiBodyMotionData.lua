-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: AiBodyMotionData
-- Date: 
-- Desc: 
-- ---------------------------------------------------------------------------------
AiBodyMotionData = class("AiBodyMotionData")
local self = AiBodyMotionData
local UPLOAD_TIMEOUT_S = 120
local STATUS_SECCESS_CODE = 0
local STATUS_AUTH_FAILED = 401

local UPLOAD_TIMEOUT_MS = 120 * 1000
local AI_MOCAP_UPLOAD_LIMIT_BUFF_ID = 33412

local CHECK_TIME_CD = 50 -- 登录签名有效期为1分钟，提前刷新
local AI_MOCAP_SIGN_WEB_ID = 80

local SELFIE_FILE_PATH_NAME = "selfiedata"
local UNTARGET_BODY_MOTION_FILE_NAME = "aibodymotiondata"
local RETARGET_FILE_NAME = "retargetanimation"
local DRESS_BONE_FILE_NAME = "skirtboneact"
local FACE_MOTION_FILE_NAME = "aifacemotiondata"

local CURL_BODY_MOTION = "http://motioncap.xoyo.com" --生成AI动作服务器链接（正式）
local CURL_BODY_MOTION_TEST = "http://motioncap-qa.xoyo.com"--生成AI动作服务器链接（测试，仅供内网使用）
local PostKey = {
    BODY_MOTION_PRESIGNED_UPLOAD          = "BODY_MOTION_PRESIGNED_UPLOAD",
    DO_BODY_MOTION_UPLOAD                 = "DO_BODY_MOTION_UPLOAD",
    BODY_MOTION_DRESS_PRESIGNED_UPLOAD    = "BODY_MOTION_DRESS_PRESIGNED_UPLOAD",
    DO_BODY_MOTION_DRESS_UPLOAD           = "DO_BODY_MOTION_DRESS_UPLOAD",
    BODY_MOTION_PROCESS                   = "BODY_MOTION_PROCESS",
    BODY_MOTION_QUERY_STATE               = "BODY_MOTION_QUERY_STATE",
    BODY_MOTION_CANCEL                    = "BODY_MOTION_CANCEL",
    BODY_MOTION_DOWNLOAD                  = "BODY_MOTION_DOWNLOAD",
    DO_DOWNLOAD_BODY_MOTION               = "DO_DOWNLOAD_BODY_MOTION",
    BODY_MOTION_APPLY_SHARE               = "BODY_MOTION_APPLY_SHARE",
    BODY_MOTION_QUERY_SHARE               = "BODY_MOTION_QUERY_SHARE",
    BODY_MOTION_GENERATE_DRESS            = "BODY_MOTION_GENERATE_DRESS",
    BODY_MOTION_DOWNLOAD_SHARE            = "BODY_MOTION_DOWNLOAD_SHARE",
}

local PostUrl = {
    BODY_MOTION_PRESIGNED_UPLOAD       = "/api/v1/ai/bodymotion/presigned_upload",
    BODY_MOTION_PROCESS                = "/api/v1/ai/bodymotion/process_v2",
    BODY_MOTION_QUERY_STATE            = "/api/v1/ai/bodymotion/querystate_by_upload",
    BODY_MOTION_CANCEL                 = "/api/v1/ai/bodymotion/cancel",
    BODY_MOTION_DOWNLOAD               = "/api/v1/ai/bodymotion/download",
    BODY_MOTION_APPLY_SHARE            = "/api/v1/ai/bodymotion/applysharelink",
    BODY_MOTION_QUERY_SHARE            = "/api/v1/ai/bodymotion/querystatesharelink",
    BODY_MOTION_GENERATE_DRESS         = "/api/v1/skirtbone",
    BODY_MOTION_DOWNLOAD_SHARE         = "/api/v1/ai/bodymotion/downloadsharelink",
}

local TASK_STATUS = {
    DOWNLOADING = "DOWNLOADING", -- 处理下载
    PENDING     = "PENDING",     -- 验证通过，任务入队
    RUNNING     = "RUNNING",     -- 执行推理任务
    COMPLETED   = "COMPLETED",   -- 流程全部结束
    FAILED      = "FAILED",      -- 生成失败
}
local tRoleSuffix =
{
    [ROLE_TYPE.STANDARD_MALE]   = "M2",
    [ROLE_TYPE.STANDARD_FEMALE] = "F2",
    [ROLE_TYPE.LITTLE_BOY]      = "M1",
    [ROLE_TYPE.LITTLE_GIRL]     = "F1",
}


local STATEMENT_TITLE = "幻境云图协议"
local STATEMENT_CONTENT = [[
为营造清朗的游戏环境，守护公平与和谐，请您在使用“幻境云图”功能前先行确认：
1、不得上传或输入含有低俗、色情、暴力、赌博、迷信、谣言等违法不良信息的内容；
2、不得上传侮辱、诽谤他人或侵害他人合法权益的内容；
3、不得上传涉及个人隐私、泄露他人秘密的内容；
4、您上传的视频可能包含人脸、动作等敏感个人信息，我们仅在必要范围内处理，用于合成动态虚拟角色效果，不会作其他用途；
5、您同意以显著标识方式标识利用深度合成技术生成的内容。
确认使用，即表示您已知晓并遵守以上规则。
]]



local function RefreshAIStageView()
    FireUIEvent("ON_ONE_CLICK_AI_STAGE_CHANGED")
end

local function GetFileExt(szFilePath)
    local szExt = string.match(szFilePath, "%.([^.\\/]+)$")
    if not szExt then
        return ""
    end

    return string.lower(szExt)
end
local function ParsePresignedUploadInfo(tData)
    if not tData then
        return nil, nil, nil
    end

    local szUploadID = tData.upload_id
    local szUploadURL = tData.upload_url
    local tUploadFields = tData.upload_fields
    return szUploadID, szUploadURL, tUploadFields
end

local function AdjustDataPath(szPath)
	local szAdjust = szPath .. ".json"
	-- if not Lib.IsFileExist(szAdjust) then
	-- 	return szAdjust
	-- end

	-- for i = 1, 100 do
	-- 	local szAdjust = szPath .. "(" .. i.. ")" .. ".json"
	-- 	if not Lib.IsFileExist(szAdjust) then
	-- 		return szAdjust
	-- 	end
	-- end
	-- local nTickCount = GetTickCount()
	-- local szAdjust = szPath .. "(" .. nTickCount.. ")" .. ".json"
	return szAdjust
end

local function GetContentTypeByFileExt(szFileExt)
    local tContentType = {
        -- 视频
        mp4 = "video/mp4",
        mov = "video/quicktime",
        avi = "video/x-msvideo",
        webm = "video/webm",
        mkv = "video/x-matroska",
    }
    return tContentType[szFileExt] or "application/octet-stream"
end

-- 根据 upload_fields 构建 POST 表单参数（含文件与校验字段）
local function BuildKS3PostParams(tUploadFields, szFilePath)
    if not tUploadFields or not szFilePath then
        return nil
    end

    local szFileExt = GetFileExt(szFilePath)
    local szContentType = GetContentTypeByFileExt(szFileExt)
    local szFileName = string.match(szFilePath, "([^\\/]+)$") or ""

    local tbParams = {}
    for k, v in pairs(tUploadFields) do
        tbParams[k] = v
    end
   -- S3/KS3 presigned POST 要求 file 字段必须是最后一个 part，服务端读完 file 后不再解析后续字段
    tbParams.upload_file = {
        key = "file",
        content_type = szContentType,
        file = szFilePath,
        filename = szFileName,
    }
    return tbParams
end

local function GetUrl()
    if IsDebugClient() then
        return CURL_BODY_MOTION_TEST
    end

    return CURL_BODY_MOTION
end 


------------------------- 签名相关--------------------------------
local m_afnAction = nil
local m_szLoginAccount = nil
local m_nLastApplySignTime = nil
local m_szLoginParam = nil

local function _UpdateLoginParam(uSign, nTime)
    local szAccount = Login_GetAccount()
    local szGlobalID = UI_GetClientPlayerGlobalID()
    if not szGlobalID then
        return
    end
    -- AI接口签名格式：{sign}:{nTime}:{account}:{globalid}
    m_szLoginParam = string.format("%s:%s:%s:%s", tostring(uSign), tostring(nTime), tostring(szAccount), tostring(szGlobalID))
    m_szLoginAccount = szAccount
    m_nLastApplySignTime = GetCurrentTime()
end

local function _ExecuteAllFunc()
    if not m_afnAction then
        return
    end

    for _, v in ipairs(m_afnAction) do
        local fnAction = v[1]
        local tParams = v[2]
        if fnAction then
            if tParams and #tParams > 0 then
                fnAction(unpack(tParams))
            else
                fnAction()
            end
        end
    end
    m_afnAction = nil
end

local function _LoginAccount()
    if GetClientPlayer() then
        WebUrl.OpenByID(AI_MOCAP_SIGN_WEB_ID)
    end
end


local function _GetAIMocapSignHeader()
    local tHeader = {
        [1] = "Content-Type:application/json",
        [2] = "JX3-Game-Signature:" .. tostring(m_szLoginParam),
    }
    return tHeader
end

-- 活动判定：日历时间 + UI 活动状态
local function _IsAIMocapActivityOpen()
    if not GetActivityMgrClient().IsActivityOn(ACTIVITY_ID.AI_MOCAP) or not (ActivityData.IsActivityOn(ACTIVITY_ID.AI_MOCAP) or UI_IsActivityOn(ACTIVITY_ID.AI_MOCAP)) then
        return false
    end
    return true
end

local function _NotifyAIMocapMaintenance()
    local szMsg = g_tStrings.STR_SELFIE_AI_MOCAP_MAINTENANCE
    OutputMessage("MSG_SYS", szMsg)
    OutputMessage("MSG_ANNOUNCE_RED", szMsg)
end


local AI_FEATURE_WHITELIST_EXT_POINT = 817
------------------------- 签名相关 End--------------------------------
local DataModel = {}
DataModel.nAIStage = AI_ACT_STAGE.BEGIN
 
function DataModel.SetUploadFailed()
    DataModel.StopUploadTimeout()
    DataModel.szUploadID = nil
    DataModel.nAIStage = AI_ACT_STAGE.UPLOAD_FAILED

    local szMsg = g_tStrings.STR_SELFIE_AI_UPLOAD_TIMEOUT
    OutputMessage("MSG_SYS", szMsg)
    OutputMessage("MSG_ANNOUNCE_RED", szMsg)

    RefreshAIStageView()
end
function DataModel.StartUploadTimeout()
    DataModel.nUploadSeq = (DataModel.nUploadSeq or 0) + 1
    local nSeq = DataModel.nUploadSeq
    DataModel.nUploadStartTick = GetTickCount()

    self.nUploadTimer = Timer.Add(self, UPLOAD_TIMEOUT_S, function ()
        if DataModel.nAIStage == AI_ACT_STAGE.UPLOADING and DataModel.nUploadSeq == nSeq then
            DataModel.SetUploadFailed()
        end
    end)
end

function DataModel.StopUploadTimeout()
    Timer.DelTimer(self.nUploadTimer)
end

function AiBodyMotionData.Init()
    if not DataModel.szUploadID then
        DataModel.nAIStage = AI_ACT_STAGE.BEGIN
        DataModel.szBodyAniFile = nil
        DataModel.szFaceAniFile = nil
        DataModel.bSuccess = false

        DataModel.bGenerateBody = true
        DataModel.bGenerateFace = true
        DataModel.bHasSendMocapAddRequest = false
        DataModel.nEnqueuedPosition = 0
        DataModel.bQueryStateRequesting = false
    end

    Event.Reg(self, "CURL_REQUEST_RESULT", function (szKey, bSuccess, szValue)
        AiBodyMotionData.OnCurlRequestResultHandler(szKey, bSuccess, szValue)
    end)

    Event.Reg(self, "CURL_DOWNLOAD_RESULT", function (szKey, bSuccess)
        local szFilePath = ""
        if string.find(szKey, PostKey.DO_DOWNLOAD_BODY_MOTION) then
            local szFilePathID = string.match(szKey, PostKey.DO_DOWNLOAD_BODY_MOTION .. "_(%d+)")
            if szFilePathID and DataModel.tbDownload and DataModel.tbDownload[szFilePathID] then
                szFilePath = DataModel.tbDownload[szFilePathID]
            else
                return
            end
    
            if bSuccess then
                local szFileName = string.match(szFilePath, "([^\\/]+)$")
                LOG.INFO("AiBodyMotionData Download File Success %s", szFileName)
                if string.find(szFileName, UNTARGET_BODY_MOTION_FILE_NAME) then --未区分体型的原始身体动作
                    AiBodyMotionData.TransformMotionData(szFilePath)
                elseif string.find(szFileName, DRESS_BONE_FILE_NAME) then --带裙摆效果的身体动作
                    DataModel.szBodyAniFile = szFilePath
                    if not DataModel.bGenerateFace or DataModel.szFaceAniFile then
                        AiBodyMotionData.NextStep()
                        if not DataModel.bHasSendMocapAddRequest then
                            RemoteCallToServer("On_AIMocap_AddRequest")
                            DataModel.bHasSendMocapAddRequest = true
                        end
                    end
                elseif string.find(szFileName, FACE_MOTION_FILE_NAME) then --脸部动作
                    DataModel.szFaceAniFile = szFilePath
                    if not DataModel.bGenerateBody or DataModel.szBodyAniFile then
                        AiBodyMotionData.NextStep()
                        if not DataModel.bHasSendMocapAddRequest then
                            RemoteCallToServer("On_AIMocap_AddRequest")
                            DataModel.bHasSendMocapAddRequest = true
                        end
                    end
                end
            end
        end
    end)

    Event.Reg(self, "RETARGET_ANIMATION_FINISHED", function (bSuccess)
        if bSuccess then
            local szRetargetFilePath = string.format("%s/%s.json", AiBodyMotionData.GetFolderDir(), RETARGET_FILE_NAME)
            AiBodyMotionData.GenerateDress(szRetargetFilePath)
        else
            LOG.ERROR("AiBodyMotionData RETARGET_ANIMATION_FINISHED Fail")
        end
    end)

    Event.Reg(self, "FIRST_LOADING_END", function()
        m_afnAction = nil
        m_szLoginAccount = nil
        m_nLastApplySignTime = nil
        m_szLoginParam = nil
    end)

    -- Event.Reg(self, "ON_WEB_DATA_SIGN_NOTIFY", function()
	-- 	AiBodyMotionData.OnWebDataSignNotify()
    -- end)

    Event.Reg(self, "PLAYER_LEAVE_GAME", function ()
        if DataModel.nAIStage == AI_ACT_STAGE.PROCESSING and DataModel.szUploadID then
            AiBodyMotionData.CancelQueue()
        end
        AiBodyMotionData.ClearCacheData()
        AiBodyMotionData.Clear()
    end)
end

function AiBodyMotionData.UnInit()
    Event.UnRegAll(AiBodyMotionData)
    Timer.DelAllTimer(self)
    if self.tCustomMotion then
		CustomData.Register(CustomDataType.Role, "SelfieSaveAIActions", self.tCustomMotion)
	end
    AiBodyMotionData.Clear()
end

function AiBodyMotionData.SetAIGenerateStartTick(nTick)
    DataModel.nAIGenerateStartTick = nTick
    if nTick then
        BubbleMsgData.PushMsgWithType("AIBodyGenerateWatingTips", {
            szTitle = "生成排队中",
            szAction = function()
                AiBodyMotionData.OpenGenerateConfirm()
            end,
		})
    else
        BubbleMsgData.RemoveMsg("AIBodyGenerateWatingTips")
    end
end

function AiBodyMotionData.GetAIGenerateStartTick()
    return DataModel.nAIGenerateStartTick
end

function AiBodyMotionData.OpenGenerateConfirm()
    local onGetTime = function()
        local nEnqueuedPos = AiBodyMotionData.GetEnqueuedPosition()
        local nTick = AiBodyMotionData.GetAIGenerateStartTick()
        local nAvgWaitSec = nEnqueuedPos * 45
        local nStartTick = nTick or GetCurrentTime()
        local nPassSec = math.max(GetCurrentTime() - nStartTick, 0)
        local szContent = string.format("动捕努力生成中\n%s%s\n%s%s", g_tStrings.STR_SELFIE_AI_QUEUE_AVGTIME, AiBodyMotionData.FormatArenaTime(nAvgWaitSec), g_tStrings.STR_SELFIE_AI_QUEUE_PASSTIME, AiBodyMotionData.FormatArenaTime(nPassSec))
        return szContent
    end
   
    local dialog = UIHelper.ShowConfirm(onGetTime(), function ()
        Timer.DelTimer(self, self.nGenerateTimerID )
    end, function ()
        AiBodyMotionData.Reset()
        BubbleMsgData.RemoveMsg("AIBodyGenerateWatingTips")
        Timer.DelTimer(self, self.nGenerateTimerID )
    end)

    dialog:SetButtonContent("Confirm", "继续生成")
    dialog:SetButtonContent("Cancel", "取消排队")
    self.nGenerateTimerID = Timer.AddCycle(self, 1, function ()
        dialog:SetNromalContent(onGetTime())
    end)
end

function AiBodyMotionData.FormatArenaTime(nTime)
	local szTime
	if nTime > 60 then
		szTime = math.floor(nTime / 60) .. g_tStrings.STR_BUFF_H_TIME_M
	else
		szTime = nTime .. g_tStrings.STR_BUFF_H_TIME_S
	end
	return szTime
end

function AiBodyMotionData.GetEnqueuedPosition()
    return DataModel.nEnqueuedPosition
end

function AiBodyMotionData.ClearCacheData()
    DataModel.tbDownload = nil
    DataModel.szSessionUntargetPath = nil
end

function AiBodyMotionData.CheckCustomActionData()
	if not self.tCustomMotion then
		self.tCustomMotion = CustomData.GetData(CustomDataType.Role, "SelfieSaveAIActions") or {}
	end
end

function AiBodyMotionData.SaveCustomFile(tMotion,szSourcePath, szSavePath)
    local content = Lib.GetStringFromFile(szSourcePath)
    Lib.WriteStringToFile(content, szSavePath)

    self.CheckCustomActionData()
    table.insert(self.tCustomMotion, tMotion)
    CustomData.Register(CustomDataType.Role, "SelfieSaveAIActions", self.tCustomMotion)
end

function AiBodyMotionData.GetAllCustomFile()
    self.CheckCustomActionData()
    return self.tCustomMotion
end

function AiBodyMotionData.DeleteCustomFile(nType, szCustomName)
    self.CheckCustomActionData()
    for k, v in pairs(self.tCustomMotion) do
        if v.nType == nType and v.szName == szCustomName then
            table.remove(self.tCustomMotion, k)
            break
        end
    end
    CustomData.Register(CustomDataType.Role, "SelfieSaveAIActions", self.tCustomMotion)
end

function AiBodyMotionData.Reset()
    AiBodyMotionData.Clear()
    RefreshAIStageView()
end

function AiBodyMotionData.Clear()
    DataModel.StopUploadTimeout()
    DataModel.szUploadID = nil
    DataModel.szUploadFilePath = nil
    DataModel.szDressUploadID = nil
    DataModel.szDressFilePath = nil
    DataModel.szDressFileType = nil
    DataModel.szDataID = nil
    DataModel.nAIStage =  AI_ACT_STAGE.BEGIN
    DataModel.szBodyAniFile = nil
    DataModel.szFaceAniFile = nil
    DataModel.bSuccess = false

    DataModel.bGenerateBody = true
    DataModel.bGenerateFace = true
    DataModel.bHasSendMocapAddRequest = false
    DataModel.nEnqueuedPosition = 0
    DataModel.bQueryStateRequesting = false
    DataModel.nAIGenerateStartTick = nil
end

function AiBodyMotionData.SetTest()
    DataModel.nAIStage =  AI_ACT_STAGE.FINISHED
    DataModel.szBodyAniFile = AiBodyMotionData.GetFolderDir() .."/aibodymotiondata_20260415_165309.json"
    DataModel.szFaceAniFile = AiBodyMotionData.GetFolderDir() .."/aifacemotiondata_20260415_165309.json"
end

function AiBodyMotionData.IsAIFeatureInWhitelist()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return false
    end
    
    local nWhiteFlag = pPlayer.GetExtPoint(AI_FEATURE_WHITELIST_EXT_POINT)
    return nWhiteFlag == 1
end

function AiBodyMotionData.IsMaxLevel()
    local pPlayer = GetClientPlayer()
    local nCurLevel = pPlayer and pPlayer.nLevel or 0
    local nMaxLevel = GetMaxPlayerLevel() or 0
    return nCurLevel >= nMaxLevel
end

local m_bAgreeStatementFlag = false

function AiBodyMotionData.GetAgreeStatementFlag()
    return m_bAgreeStatementFlag
end

function AiBodyMotionData.SetAgreeStatementFlag(bFlag)
    m_bAgreeStatementFlag = bFlag
end

function AiBodyMotionData.GetStage()
    return DataModel.nAIStage
end

function AiBodyMotionData.GetGenerateOption()
    return DataModel.bGenerateBody, DataModel.bGenerateFace
end

function AiBodyMotionData.GetBodyAniFile()
    return DataModel.szBodyAniFile
end

function AiBodyMotionData.GetFaceAniFile()
    return DataModel.szFaceAniFile
end

function AiBodyMotionData.GetFolderDir()
    local szDir = GetFullPath(SELFIE_FILE_PATH_NAME) .. "/aibodymotion"
    if not IsLocalFileExist(szDir) then
        CPath.MakeDir(szDir)
    end
    szDir = string.gsub(szDir, "\\","/")
    return szDir
end

function AiBodyMotionData.GetSaveBodyActPath(szName)
    local szFilePath = AiBodyMotionData.GetFolderDir() .. "/bodyact_" .. szName
    return AdjustDataPath(szFilePath)
end

function AiBodyMotionData.GetSaveFaceActPath(szName)
    local szFilePath = AiBodyMotionData.GetFolderDir() .. "/faceact_" .. szName
    return AdjustDataPath(szFilePath)
end

function AiBodyMotionData.NextStep()
    local nCurStep = DataModel.nAIStage
    if nCurStep >= AI_ACT_STAGE.FINISHED then
        return
    end

    DataModel.nAIStage = DataModel.nAIStage + 1
    RefreshAIStageView()
end

function AiBodyMotionData.BackStep()
    local nCurStep = DataModel.nAIStage
    if nCurStep <= AI_ACT_STAGE.BEGIN then
        return
    end
    if nCurStep == AI_ACT_STAGE.PROCESSING then
        AiBodyMotionData.CancelQueue()
        AiBodyMotionData.CloseBreathStateCell()
        AiBodyMotionData.Reset()
        return
    end
    if nCurStep == AI_ACT_STAGE.UPLOADED then
        DataModel.nAIStage = AI_ACT_STAGE.BEGIN
    else
        DataModel.nAIStage = DataModel.nAIStage - 1
    end
    RefreshAIStageView()
end

--删除上传的视频
function AiBodyMotionData.DeleteData()
    DataModel.szUploadID = nil
end

function AiBodyMotionData.OpenBreathStateCell(refreshTime)
    AiBodyMotionData.CloseBreathStateCell()
    self.nBreathCallTimer = Timer.AddCycle(self, refreshTime, function()
        AiBodyMotionData.GetBodyMotionState()
    end)
end

function AiBodyMotionData.CloseBreathStateCell()
    Timer.DelTimer(self, self.nBreathCallTimer)
end

function AiBodyMotionData.DoDownloadData(szDataLink, szFileName)
    if not szDataLink then
        return
    end

    local tTime = TimeToDate(GetCurrentTime())
	local szTime = string.format("%d%02d%02d_%02d%02d%02d", tTime.year, tTime.month, tTime.day, tTime.hour, tTime.minute, tTime.second)
    local szFilePath = string.format("%s/%s", AiBodyMotionData.GetFolderDir(), szFileName .. "_" .. szTime)
    szFilePath = AdjustDataPath(szFilePath)

    if not DataModel.tbDownload then
        DataModel.tbDownload = {}
    end

    local szID = tostring(table.get_len(DataModel.tbDownload) + 1)
    DataModel.tbDownload[szID] = szFilePath
    CURL_DownloadFile(string.format("%s_%s", PostKey.DO_DOWNLOAD_BODY_MOTION, szID), szDataLink, szFilePath, true, 60, 60)
end

function AiBodyMotionData.TransformMotionData(szSrcAniFile)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    
    local nTarRoleType = pPlayer.nRoleType
    local szTarAniFile = string.format("%s/%s.json", AiBodyMotionData.GetFolderDir(), RETARGET_FILE_NAME)

    local subScrAniFile =   szSrcAniFile:match("selfiedata/.*$") or szSrcAniFile
    local bSuccess = KG3DEngine.RetargetAnimation(subScrAniFile, szTarAniFile, nTarRoleType)
    if not bSuccess then
        LOG.INFO("[error]AiBodyMotionData RetargetAnimation Fail")
        return
    end
end

function AiBodyMotionData.ProcessAIAction(szKey, bOneClick)
    if not szKey or szKey == "" then
        return
    end
    local startPos = szKey:find(SELFIE_FILE_PATH_NAME, 1, true) 
    local newPath = startPos and szKey:sub(startPos) or szKey
    RemoteCallToServer("On_EmotionAction_DoAction", nil, newPath, bOneClick)
end

function AiBodyMotionData.ProcessFaceMotion(szKey)
	EmotionData.ProcessFaceMotion(szKey)
end

function AiBodyMotionData.StopFaceMotion()
    local dwPlayerID = UI_GetClientPlayerID()
    rlcmd(string.format("play ai face motion %d 0", dwPlayerID))
end

function AiBodyMotionData.StopAIAction()
    local dwPlayerID = UI_GetClientPlayerID()
    rlcmd(string.format("play ai animation %d 0", dwPlayerID)) 
end

---------------------------------登录签名---------------------------------
function AiBodyMotionData.OnWebDataSignNotify()
    local szComment = arg6
    local dwApplyWebID = szComment and szComment:match("APPLY_WEBID_(.*)")
    if not dwApplyWebID then
        return
    end

    dwApplyWebID = tonumber(dwApplyWebID)
    if dwApplyWebID ~= AI_MOCAP_SIGN_WEB_ID then
        return
    end

    local uSign = arg0
    local nTime = arg2
    _UpdateLoginParam(uSign, nTime)
    _ExecuteAllFunc()
end

function AiBodyMotionData.CheckSignAndExecute(fnAction, ...)
    local nTime = GetCurrentTime()
    local szAccount = Login_GetAccount()
    if not m_szLoginParam or not m_szLoginAccount or m_szLoginAccount ~= szAccount
        or not m_nLastApplySignTime or (nTime - m_nLastApplySignTime > CHECK_TIME_CD)
    then
        if not m_afnAction then
            m_afnAction = {}
        end
        if fnAction then
            table.insert(m_afnAction, {fnAction, {...}})
        end
        _LoginAccount()
    else
        if fnAction then
            fnAction(...)
        end
    end
end


-- 供界面判断幻境 AI 动捕活动是否处于开启状态（同 CheckSystemShopCanShow 判定流程）
function AiBodyMotionData.IsAIMocapActivityEnabled()
    return _IsAIMocapActivityOpen()
end

function AiBodyMotionData.HandleSignAuthFailed(szKey, nRetCode)
    local szBusyMsg = g_tStrings.tAiMotionCodeMsg[nRetCode]
    OutputMessage("MSG_SYS", szBusyMsg)
    OutputMessage("MSG_ANNOUNCE_RED", szBusyMsg)
    DataModel.StopUploadTimeout()
    DataModel.bQueryStateRequesting = false
    AiBodyMotionData.CloseBreathStateCell()

    if szKey == PostKey.BODY_MOTION_PROCESS or szKey == PostKey.BODY_MOTION_QUERY_STATE
        or szKey == PostKey.BODY_MOTION_DOWNLOAD
    then
        DataModel.nAIStage = AI_ACT_STAGE.UPLOADED
        DataModel.bSuccess = false
        DataModel.szDataID = nil
        DataModel.szBodyAniFile = nil
        DataModel.szFaceAniFile = nil
        RefreshAIStageView()
    else
        AiBodyMotionData.Reset()
    end
end

function AiBodyMotionData.CheckAgreeStatement()
    if not m_bAgreeStatementFlag then
        AiBodyMotionData.OpenAgreeStatement()
        return false
    end
    return true
end

function AiBodyMotionData.OpenAgreeStatement()
    UIMgr.Open(VIEW_ID.PanelStatementRulePop, STATEMENT_TITLE, STATEMENT_CONTENT, function()
        m_bAgreeStatementFlag = true
    end)
end

---------------------------------对外接口---------------------------------
--上传体型动作视频
function AiBodyMotionData.UploadData(szFilePath)
    if not szFilePath then
        LOG.INFO("AiBodyMotionData UploadBodyMotionData Fail")
        return
    end

    if not _IsAIMocapActivityOpen() then
        _NotifyAIMocapMaintenance()
        return
    end

    if not AiBodyMotionData.CheckAgreeStatement() then
        return
    end

	DataModel.nAIStage = AI_ACT_STAGE.UPLOADING
    RefreshAIStageView()
    DataModel.StartUploadTimeout()
    DataModel.szUploadFilePath = szFilePath
    DataModel.szUploadID = nil
    DataModel.bHasSendMocapAddRequest = false

    local szGlobalID = UI_GetClientPlayerGlobalID()
    local szUrl = GetUrl() .. PostUrl.BODY_MOTION_PRESIGNED_UPLOAD
    local tHttpData = {}
    tHttpData["file_ext"] = GetFileExt(szFilePath)
    tHttpData["business_type"] = "motion_capture"
    tHttpData["user_id"] = szGlobalID

    AiBodyMotionData.CheckSignAndExecute(function()
        CURL_HttpPost(PostKey.BODY_MOTION_PRESIGNED_UPLOAD, szUrl, JsonEncode(tHttpData), false, 60, 60, _GetAIMocapSignHeader())
    end)
end

--启动AI模型处理体型动作（非阻塞）将任务入队立即返回
function AiBodyMotionData.ProcessData(bBody, bFace)
    if not DataModel.szUploadID then
        return
    end

    if not _IsAIMocapActivityOpen() then
        _NotifyAIMocapMaintenance()
        return
    end

    DataModel.bGenerateBody = bBody
    DataModel.bGenerateFace = bFace

    DataModel.szBodyAniFile = nil
    DataModel.szFaceAniFile = nil
    DataModel.szDataID = nil
    DataModel.bSuccess = false

    local szGlobalID = UI_GetClientPlayerGlobalID()
    local szPostUrl = GetUrl() .. PostUrl.BODY_MOTION_PROCESS
    local tHttpData = {}
	tHttpData["user_id"] = szGlobalID
	tHttpData["upload_id"] = DataModel.szUploadID
	tHttpData["body_type"] = "F2" --原始数据默认按成女生成，后续再用单独的接口转成其他体型
    AiBodyMotionData.CheckSignAndExecute(function()
        CURL_HttpPost(PostKey.BODY_MOTION_PROCESS, szPostUrl, JsonEncode(tHttpData), false, 60, 60, _GetAIMocapSignHeader())
    end)
end

function AiBodyMotionData.GetBodyMotionState()
    if not DataModel.szUploadID then
        return
    end
    if DataModel.bQueryStateRequesting then
        return
    end
    local szPostUrl = string.format("%s%s/%s", GetUrl(), PostUrl.BODY_MOTION_QUERY_STATE, DataModel.szUploadID)
    DataModel.bQueryStateRequesting = true
    AiBodyMotionData.CheckSignAndExecute(function()
        CURL_HttpPost(PostKey.BODY_MOTION_QUERY_STATE, szPostUrl, nil, true, 60, 60, _GetAIMocapSignHeader())
    end)
end

function AiBodyMotionData.GenerateDress(szFilePath)
    if not szFilePath then
        LOG.INFO("[error]AiBodyMotionData GenerateDress Fail")
        return
    end

    DataModel.szDressFilePath = szFilePath
    DataModel.szDressUploadID = nil
    DataModel.szDressFileType = GetFileExt(szFilePath)

    local szPostUrl = GetUrl() .. PostUrl.BODY_MOTION_PRESIGNED_UPLOAD
    local szGlobalID = UI_GetClientPlayerGlobalID()
    local tHttpData = {}
    tHttpData["file_ext"] = DataModel.szDressFileType
    tHttpData["business_type"] = "skirtbone"
    tHttpData["user_id"] = szGlobalID
    AiBodyMotionData.CheckSignAndExecute(function()
        CURL_HttpPost(PostKey.BODY_MOTION_DRESS_PRESIGNED_UPLOAD, szPostUrl, JsonEncode(tHttpData), false, 60, 60, _GetAIMocapSignHeader())
    end)
end

--申请下载动作文件
function AiBodyMotionData.ApplyData()
    if not DataModel.szDataID then
        return
    end

    local szGlobalID = UI_GetClientPlayerGlobalID()
    local szPostUrl = GetUrl() .. PostUrl.BODY_MOTION_DOWNLOAD
    local tHttpData = {}
	tHttpData["user_id"] = szGlobalID
	tHttpData["data_id"] = DataModel.szDataID
	tHttpData["body_type"] = "F2"
    AiBodyMotionData.CheckSignAndExecute(function()
        CURL_HttpPost(PostKey.BODY_MOTION_DOWNLOAD, szPostUrl, JsonEncode(tHttpData), false, 60, 60, _GetAIMocapSignHeader())
    end)
end

function AiBodyMotionData.CancelQueue()
    if not DataModel.szUploadID then
        return
    end

    local szPostUrl = string.format("%s%s?upload_id=%s", GetUrl(), PostUrl.BODY_MOTION_CANCEL, DataModel.szUploadID)
    AiBodyMotionData.CheckSignAndExecute(function()
        local tHeader = {[1] = "JX3-Game-Signature:" .. tostring(m_szLoginParam)}
        CURL_HttpPost(PostKey.BODY_MOTION_CANCEL, szPostUrl, JsonEncode({}), true, 60, 60, tHeader)
    end)
end

function AiBodyMotionData.OnCurlRequestResultHandler(szKey, bSuccess, szValue)
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
    if szKey == PostKey.BODY_MOTION_QUERY_STATE then
        DataModel.bQueryStateRequesting = false
    end
    if not bSuccess then
        if szKey == PostKey.DO_BODY_MOTION_UPLOAD then
            DataModel.SetUploadFailed()
        end
        LOG.INFO("AiBodyMotionData CURL_HttpPost Failed!szPostKey=%s", tostring(szKey))
        return
    end
    
    LOG.INFO("AiBodyMotionData Post Success %s,%s", szKey, szValue)

    if szKey == PostKey.DO_BODY_MOTION_UPLOAD then
        if DataModel.nAIStage ~= AI_ACT_STAGE.UPLOADING then
            return
        end

        local nStartTick = DataModel.nUploadStartTick
        if nStartTick and GetTickCount() - nStartTick > UPLOAD_TIMEOUT_MS then
            return
        end

        if DataModel.szUploadID then
            DataModel.StopUploadTimeout()
            AiBodyMotionData.NextStep()
        else
            DataModel.SetUploadFailed()
            LOG.INFO("AiBodyMotionData Upload KS3 Fail InvalidUploadID")
        end
        return
    elseif szKey == PostKey.DO_BODY_MOTION_DRESS_UPLOAD then
        local szUploadID = DataModel.szDressUploadID
        if not szUploadID then
            LOG.INFO("AiBodyMotionData Dress Upload KS3 InvalidInfo")
            return
        end

        local szPostUrl = GetUrl() .. PostUrl.BODY_MOTION_GENERATE_DRESS
        local szGlobalID = UI_GetClientPlayerGlobalID()
        local pPlayer = GetClientPlayer()
        if not pPlayer then
            return
        end
        local tHttpData = {}
        tHttpData["upload_id"] = szUploadID
        tHttpData["body_type"] = tRoleSuffix[pPlayer.nRoleType]
        tHttpData["user_id"] = szGlobalID
        AiBodyMotionData.CheckSignAndExecute(function()
            CURL_HttpPost(PostKey.BODY_MOTION_GENERATE_DRESS, szPostUrl, JsonEncode(tHttpData), false, 60, 60, _GetAIMocapSignHeader())
        end)
        return
    end

    local tInfo, szErrMsg = JsonDecode(szValue)
    if not tInfo then
        return
    end

    local nRetCode = tInfo.code
    if not nRetCode then
        return
    end

    
    if nRetCode == STATUS_AUTH_FAILED then
        AiBodyMotionData.HandleSignAuthFailed(szKey, nRetCode)
        return
    elseif szKey ~= PostKey.BODY_MOTION_QUERY_STATE and szKey ~= PostKey.BODY_MOTION_CANCEL and nRetCode ~= STATUS_SECCESS_CODE and g_tStrings.tAiMotionCodeMsg[nRetCode] then
        OutputMessage("MSG_SYS", g_tStrings.tAiMotionCodeMsg[nRetCode])
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tAiMotionCodeMsg[nRetCode])
    end

    if szKey == PostKey.BODY_MOTION_PRESIGNED_UPLOAD then
        if DataModel.nAIStage ~= AI_ACT_STAGE.UPLOADING then
            return
        end

        local nStartTick = DataModel.nUploadStartTick
        if nStartTick and GetTickCount() - nStartTick > UPLOAD_TIMEOUT_MS then
            return
        end

        if nRetCode == STATUS_SECCESS_CODE then
            local tData = tInfo.data
            local szUploadID, szUploadURL, tUploadFields = ParsePresignedUploadInfo(tData)
            local szUploadFilePath = DataModel.szUploadFilePath
            if not szUploadID or not szUploadURL or not szUploadFilePath then
                AiBodyMotionData.Reset()
                LOG.INFO("AiBodyMotionData Presigned Upload InvalidData  %s", szValue)
                return
            end

            local tbParams = BuildKS3PostParams(tUploadFields, szUploadFilePath)
            if not tbParams then
                AiBodyMotionData.Reset()
                LOG.INFO("AiBodyMotionData Presigned Upload Missing upload_fields  %s", szValue)
                return
            end

            DataModel.szUploadID = szUploadID
            CURL_HttpPost(PostKey.DO_BODY_MOTION_UPLOAD, szUploadURL, tbParams, false, 120, 120)
        else
            AiBodyMotionData.Reset()
            LOG.INFO("AiBodyMotionData Upload Fail %s", szValue)
        end
    elseif szKey == PostKey.BODY_MOTION_DRESS_PRESIGNED_UPLOAD then
        if nRetCode == STATUS_SECCESS_CODE then
            local tData = tInfo.data
            local szUploadID, szUploadURL, tUploadFields = ParsePresignedUploadInfo(tData)
            local szDressFilePath = DataModel.szDressFilePath
            local szDressFileType = DataModel.szDressFileType or GetFileExt(szDressFilePath or "")
            if not szUploadID or not szUploadURL or not szDressFilePath then
                LOG.INFO("AiBodyMotionData Presigned Dress InvalidData %s", szValue)
                return
            end

            local tbParams = BuildKS3PostParams(tUploadFields, szDressFilePath)
            if not tbParams then
                LOG.INFO("AiBodyMotionData Presigned Dress Missing upload_fields %s", szValue)
                return
            end

            DataModel.szDressUploadID = szUploadID
            DataModel.szDressFileType = szDressFileType
            CURL_HttpPost(PostKey.DO_BODY_MOTION_DRESS_UPLOAD, szUploadURL, tbParams, false, 120, 120)
        else
            LOG.INFO("AiBodyMotionData Dress Presigned Upload Fail %s", szValue)
        end
    elseif szKey == PostKey.BODY_MOTION_PROCESS then
        if nRetCode == STATUS_SECCESS_CODE then
            local tData = tInfo.data
            if tData and tData.upload_id then
                DataModel.szUploadID = tData.upload_id
                DataModel.nEnqueuedPosition = tData.enqueued_position or 0
            end
            AiBodyMotionData.OpenBreathStateCell(3) --每隔3秒刷新生成状态
            RefreshAIStageView()
        else --处理失败，设置为生成失败状态
            DataModel.nAIStage = AI_ACT_STAGE.PROCESSING_FAILED
            RefreshAIStageView()
        end
    elseif szKey == PostKey.BODY_MOTION_QUERY_STATE then
        local tData = tInfo.data
        local nStatus = tData.status
        if nRetCode == STATUS_SECCESS_CODE then
            if tData.data_id then
                DataModel.szDataID = tData.data_id
            end
            local bFinish = nStatus == TASK_STATUS.COMPLETED
            if bFinish then
                AiBodyMotionData.CloseBreathStateCell()
                AiBodyMotionData.ApplyData()
            end
            DataModel.bSuccess = bFinish
        else
            if nStatus == TASK_STATUS.FAILED then
                AiBodyMotionData.CloseBreathStateCell()
                LOG.INFO("AiBodyMotionData Capture Fail  %s", szValue)

                local szMsg = g_tStrings.tAiMotionCodeMsg[nRetCode] or g_tStrings.STR_SELFIE_AI_GENERATE_FAIL
                OutputMessage("MSG_SYS", szMsg)
                OutputMessage("MSG_ANNOUNCE_RED", szMsg)

                DataModel.nAIStage = AI_ACT_STAGE.PROCESSING_FAILED
                RefreshAIStageView()
            end
        end
    elseif szKey == PostKey.BODY_MOTION_DOWNLOAD then
        if nRetCode == STATUS_SECCESS_CODE then
            local tData = tInfo.data
            if DataModel.bGenerateBody then
                AiBodyMotionData.DoDownloadData(tData.motion, UNTARGET_BODY_MOTION_FILE_NAME)
            end

            if DataModel.bGenerateFace then
                AiBodyMotionData.DoDownloadData(tData.emo, FACE_MOTION_FILE_NAME)
            end
        end
    elseif szKey == PostKey.BODY_MOTION_GENERATE_DRESS then
        if nRetCode == STATUS_SECCESS_CODE then
            local tData = tInfo.data
            AiBodyMotionData.DoDownloadData(tData.download_url, DRESS_BONE_FILE_NAME)
        end
    end
end