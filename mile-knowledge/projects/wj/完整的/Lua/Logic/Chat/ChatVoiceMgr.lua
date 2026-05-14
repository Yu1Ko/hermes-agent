-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: ChatVoiceMgr
-- Date: 2024-03-14 20:50:58
-- Desc: 语音消息 以 语音转文字
-- ---------------------------------------------------------------------------------

ChatVoiceMgr = ChatVoiceMgr or {className = "ChatVoiceMgr"}
local self = ChatVoiceMgr

local RECORD_WITH_STREAM = not Channel.Is_WLColud() -- 流式语音（蔚领云游戏不能用流式的，因为路径问题会导致宕机）

local GME_ERROR =
{
    [4097] = "参数为空", -- （检查代码中接口参数是否正确）
    [4098] = "初始化错误", -- （检查设备是否被占用，或者权限是否正常，是否初始化正常）
    [4099] = "正在录制中", -- （确保在正确的时机使用 SDK 录制功能）
    [4100] = "没有采集到音频数据", -- （检查麦克风设备是否正常）
    [4101] = "录音时，录制文件访问错误", -- （确保文件存在，文件路径的合法性）
    [4102] = "麦克风未授权错误", -- （使用 SDK 需要麦克风权限，添加权限请参考对应引擎或平台的 SDK 工程配置文档）
    [4103] = "录音时间太短错误", -- （首先，限制录音时长的单位为毫秒，检查参数是否正确；其次，录音时长要1000毫秒以上才能成功录制）
    [4104] = "没有启动录音操作", -- （检查是否已经调用启动录音接口）

    [32775] = "流式语音转文本失败，但是录音成功", -- （调用 UploadRecordedFile 接口上传录音，再调用 SpeechToText 接口进行语音转文字操作）
    [32777] = "流式语音转文本失败，但是录音成功，上传成功", -- （返回的信息中有上传成功的后台 url 地址，调用 SpeechToText 接口进行语音转文字操作）
    [32786] = "流式语音转文本失败", -- （在流式录制状态当中，请等待流式录制接口执行结果返回）

    [8193] = "上传文件时，文件访问错误", -- （确保文件存在，文件路径的合法性）
    [8194] = "签名校验失败错误", -- （检查鉴权密钥是否正确，检查是否有初始化离线语音）
    [8195] = "网络错误", -- （检查设备网络是否可以正常访问外网环境）
    [8196] = "获取上传参数过程中网络失败", -- （检查鉴权是否正确，检查设备网络是否可以正常访问外网环境）
    [8197] = "获取上传参数过程中回包数据为空", -- （检查鉴权是否正确，检查设备网络是否可以正常访问外网环境）
	[8198] = "获取上传参数过程中回包解包失败", -- （检查鉴权是否正确，检查设备网络是否可以正常访问外网环境）
	[8200] = "没有设置 appinfo", -- （检查 apply 接口是否有调用，或者入参是否为空）

    [12289] = "下载文件时，文件访问错误", --  （检查文件路径是否合法）
	[12290] = "签名校验失败", --  （检查鉴权密钥是否正确，检查是否有初始化离线语音）
	[12291] = "网络存储系统异常", --  （服务器获取语音文件失败，检查接口参数 fileid 是否正确，检查网络是否正常，检查 COS 文件存不存在）
	[12292] = "服务器文件系统错误", --  （检查设备网络是否可以正常访问外网环境，检查服务器上是否有此文件）
	[12293] = "获取下载参数过程中，HTTP 网络失败", --  （检查设备网络是否可以正常访问外网环境）
	[12294] = "获取下载参数过程中，回包数据为空", --  （检查设备网络是否可以正常访问外网环境）
	[12295] = "获取下载参数过程中，回包解包失败", --  （检查设备网络是否可以正常访问外网环境）
	[12297] = "没有设置 appinfo", --  （检查鉴权密钥是否正确，检查是否有初始化离线语音）

    [20481] = "初始化错误", -- （检查设备是否被占用，或者权限是否正常，是否初始化正常）
    [20482] = "正在播放中，试图打断并播放下一个失败了", --（正常是可以打断的） （检查代码逻辑是否正确）
    [20483] = "参数为空", -- （检查代码中接口参数是否正确）
    [20484] = "内部错误", -- （初始化播放器错误，解码失败等问题产生此错误码，需要结合日志定位问题）

    [32769] = "内部错误", -- （分析日志，获取后台返回给客户端的真正错误码，并联系后台同事协助解决）
	[32770] = "网络失败", -- （检查设备网络是否可以正常访问外网环境）
	[32772] = "回包解包失败", -- （分析日志，获取后台返回给客户端的真正错误码，并联系后台同事协助解决）
	[32774] = "没有设置 appinfo", -- （检查鉴权密钥是否正确，检查是否有初始化离线语音）
	[32776] = "authbuffer 校验失败", -- （检查 authbuffer 是否正确）
	[32784] = "语音转文本参数错误", -- （检查代码中接口参数 fileid 是否为空）
	[32785] = "语音转文本翻译返回错误", -- （离线语音后台错误，请分析日志，获取后台返回给客户端的真正错误码，并联系后台同事协助解决）
	[32787] = "转文本成功，文本翻译服务未开通", -- （需要在控制台开通文本翻译服务）
	[32788] = "转文本成功，文本翻译语言参数不支持", -- （重新检查传入参数）
}



self.tbFileID2PathMap = {} -- fileid 和 filepath 的映射，防止重复去云端拉语音文件
--self.tbFileID2TextMap = {} -- fileid 和 text 的映射，防止重复转文字



function ChatVoiceMgr.Init()
    self.nCount = 1
    self.nMaxRecordTime = ChatData.GetRecordingMaxTime()

    self._removeFilePath()

    Event.Reg(self, "FIRST_LOADING_END", function()
        -- local szOpenID = GVoiceMgr.GetOpenID()
        -- GME_Init(szOpenID)

        GVoiceMgr.InitSDK()

        GME_PTT_SetMaxMessageLength(self.nMaxRecordTime)
    end)

    Event.Reg(self, "GME_ON_PTT_RECORD_WITHSTREAMING_COMPLETED", function(nResult, filepath, fileid, text)
        LOG.INFO("ChatVoiceMgr, GME_ON_PTT_RECORD_WITHSTREAMING_COMPLETED, nResult = %s, filepath = %s, fileid = %s, text = %s", tostring(nResult), tostring(filepath), tostring(fileid), tostring(text))

        if nResult == 0 then
            -- 流式录音结束后
            self.tbFileID2PathMap[fileid] = filepath

            local nFileSize = ChatVoiceMgr.GetFileSize(filepath)
            local nVoiceDuration = ChatVoiceMgr.GetVoiceFileDuration(filepath)

            if not string.is_nil(fileid) and string.is_nil(text) then
                text = " "
            end

            local tbMsg = self._makeChatData(filepath, fileid, text, nVoiceDuration)

            Event.Dispatch(EventType.OnChatVoiceRecordSuccessed, true, filepath, fileid, text, nVoiceDuration, tbMsg)
            UIHelper.HideTouchMask()
        else
            Event.Dispatch(EventType.OnChatVoiceRecordFailed, true, filepath)
            self._handlError(nResult)
        end
    end)

    Event.Reg(self, "GME_ON_PTT_RECORD_WITHSTREAMING_RUNNING", function(nResult, filepath)
        LOG.INFO("ChatVoiceMgr, GME_ON_PTT_RECORD_WITHSTREAMING_RUNNING, nResult = %s, filepath = %s", tostring(nResult), tostring(filepath))
    end)

    Event.Reg(self, "GME_ON_PTT_RECORD_COMPLETED", function(nResult, filepath)
		LOG.INFO("ChatVoiceMgr, GME_ON_PTT_RECORD_COMPLETED, nResult = %s, filepath = %s", tostring(nResult), tostring(filepath))

        if nResult == 0 then
            -- 录音结束后上传
            Event.Dispatch(EventType.OnChatVoiceRecordSuccessed, false, filepath)
            ChatVoiceMgr.UploadRecordedFile(filepath)
        else
            Event.Dispatch(EventType.OnChatVoiceRecordFailed, false, filepath)
            self._handlError(nResult)
        end
	end)

	Event.Reg(self, "GME_ON_PTT_UPLOAD_COMPLETED", function(nResult, filepath, fileid)
        LOG.INFO("ChatVoiceMgr, GME_ON_PTT_UPLOAD_COMPLETED, nResult = %s, filepath = %s, fileid = ", tostring(nResult), tostring(filepath), tostring(fileid))

        if nResult == 0 then
            if not string.is_nil(fileid) and not string.is_nil(filepath) then
                -- 上传成功后 转文字
                self.tbFileID2PathMap[fileid] = filepath

                Event.Dispatch(EventType.OnChatVoiceUploadSuccessed, filepath, fileid)
                ChatVoiceMgr.SpeechToText(fileid)
            end
        else
            Event.Dispatch(EventType.OnChatVoiceUploadFailed, filepath)
            self._handlError(nResult)
        end
	end)

	Event.Reg(self, "GME_ON_PTT_DOWNLOAD_COMPLETED", function(nResult, filepath, fileid)
        LOG.INFO("ChatVoiceMgr, GME_ON_PTT_DOWNLOAD_COMPLETED, nResult = %s, filepath = %s, fileid = ", tostring(nResult), tostring(filepath), tostring(fileid))

		if nResult == 0 then
            if not string.is_nil(fileid) and not string.is_nil(filepath) then
                self.tbFileID2PathMap[fileid] = filepath
                Event.Dispatch(EventType.OnChatVoiceDownloadSuccessed, filepath, fileid)
            end
        else
            Event.Dispatch(EventType.OnChatVoiceDownloadFailed, filepath, fileid)
            self._handlError(nResult)
        end

        self.szDownloadFileID = nil
	end)

	Event.Reg(self, "GME_ON_PTT_PLAY_COMPLETED", function(nResult, filepath)
        LOG.INFO("ChatVoiceMgr, GME_ON_PTT_PLAY_COMPLETED, nResult = %s, filepath = %s", tostring(nResult), tostring(filepath))

        if nResult == 0 then
            Event.Dispatch(EventType.OnChatVoicePlaySuccessed, filepath)
        else
            Event.Dispatch(EventType.OnChatVoicePlayFailed, filepath)
            self._handlError(nResult)
        end

        self.szPlayingFilePath = nil
	end)

	Event.Reg(self, "GME_ON_PTT_SPEECH2TEXT_COMPLETED", function(nResult, fileid, text)
        LOG.INFO("ChatVoiceMgr, GME_ON_PTT_SPEECH2TEXT_COMPLETED, nResult = %s, fileid = %s, text = ", tostring(nResult), tostring(fileid), tostring(text))

		if nResult == 0 then
            if not string.is_nil(fileid) then
                -- 文字转完后就发送出去
                UIHelper.HideTouchMask()

                local szFilePath = self.tbFileID2PathMap[fileid]
                local nFileSize = ChatVoiceMgr.GetFileSize(szFilePath)
                local nVoiceDuration = ChatVoiceMgr.GetVoiceFileDuration(szFilePath)

                local tbMsg = self._makeChatData(szFilePath, fileid, text, nVoiceDuration)

                Event.Dispatch(EventType.OnChatVoiceToTexSuccessed, fileid, szFilePath, nFileSize, nVoiceDuration, tbMsg)
            end
        else
            Event.Dispatch(EventType.OnChatVoiceToTextFailed, fileid)
            self._handlError(nResult)
        end
	end)
end

function ChatVoiceMgr.UnInit()

end



-- 开始录音 - 按下开始录音 文件路径外面无需关心，内部处理即可
function ChatVoiceMgr.StartRecording()
    if Platform.IsWindows() then
        if not GVoiceMgr.IsMicAvail() then
            TipsHelper.ShowNormalTip(g_tStrings.GVOICE_MIC_UNAVIAL_STATE_TIP)
            return
        end
    else
        if not Permission.CheckPermission(Permission.Microphone) then
            if Permission.CheckHasAsked(Permission.Microphone) then
                Permission.AskForSwitchToAppPermissionSetting(Permission.Microphone)
                return
            else
                Permission.RequestUserPermission(Permission.Microphone)
                Event.Reg(self, "OnRequestPermissionCallback", function(nPermission, bResult)
                    if nPermission == Permission.Microphone then
                        Event.UnReg(self, "OnRequestPermissionCallback")
                        if bResult then
                            -- TODO show tips [request permission successed].
                        end
                    end
                end)
                return
            end
        end
    end

    if IsWLCloudClient() then
        SyncCloudAppMicState(true)
    end

    local szFilePath = self._getFilePath()

    if RECORD_WITH_STREAM then
        GME_PTT_StartRecordingWithStreamingRecognition(szFilePath)
    else
        GME_PTT_StartRecording(szFilePath)
    end

    local nAutoHideTime = self.nMaxRecordTime / 1000 + 10
    UIHelper.ShowTouchMask(nAutoHideTime) -- 开始录音的时候不能让玩家操作干别的，要等录音文字上传到云端以后并且发送出去才行
end

-- 停止录音 - 停止录音后会有录音完成回调，成功之后录音文件才可用。 松手或者时间到了要结束录音
-- Event: GME_ON_PTT_RECORD_COMPLETED
function ChatVoiceMgr.StopRecording()
    GME_PTT_StopRecording()

    if IsWLCloudClient() then
        if GVoiceMgr.GetMicState() ~= MIC_STATE.OPEN then
            SyncCloudAppMicState(false)
        end
    end
end

-- 取消录音 - 取消之后不会收到回调
function ChatVoiceMgr.CancelRecording()
    GME_PTT_CancelRecording()

    UIHelper.HideTouchMask()

    if IsWLCloudClient() then
        if GVoiceMgr.GetMicState() ~= MIC_STATE.OPEN then
            SyncCloudAppMicState(false)
        end
    end
end

-- 上传录音文件到云端
-- Event: GME_ON_PTT_UPLOAD_COMPLETED
function ChatVoiceMgr.UploadRecordedFile(szFilePath)
    GME_PTT_UploadRecordedFile(szFilePath)
end

-- 下载云端录音到本地
-- Event: GME_ON_PTT_DOWNLOAD_COMPLETED
function ChatVoiceMgr.DownloadRecordedFile(szFileID, szFilePath)
    GME_PTT_DownloadRecordedFile(szFileID, szFilePath)
end

-- 播放录音
-- Event: GME_ON_PTT_PLAY_COMPLETED
function ChatVoiceMgr.PlayRecordedFile(szFilePath)
    ChatVoiceMgr.StopPlayFile()

    GME_PTT_PlayRecordedFile(szFilePath)

    self.szPlayingFilePath = szFilePath
end

-- 根据fileid播放录音文件，本地可能没有，则需要先下载再播放
function ChatVoiceMgr.PlayRecordedFileByFileID(szFileID)
    local szFilePath = self.tbFileID2PathMap[szFileID]
    if szFilePath then -- 如果有直接播本地
        ChatVoiceMgr.PlayRecordedFile(szFilePath)
        return
    end

    -- 如果没有则先下载
    if self.szDownloadFileID == szFileID then
        return
    end

    self.szDownloadFileID = szFileID
    ChatVoiceMgr.DownloadRecordedFile(szFileID, self._getFilePath())
end

-- 停止正在播放的录音
function ChatVoiceMgr.StopPlayFile()
    GME_PTT_StopPlayFile()
    self.szPlayingFilePath = nil
end

function ChatVoiceMgr.IsPlaying(szFilePath)
    if self.szPlayingFilePath == nil then
        return false
    end
    return self.szPlayingFilePath == szFilePath
end

-- 获取录音文件大小
function ChatVoiceMgr.GetFileSize(szFilePath)
    return GME_PTT_GetFileSize(szFilePath)
end

-- 获取录音时长
function ChatVoiceMgr.GetVoiceFileDuration(szFilePath)
    return GME_PTT_GetVoiceFileDuration(szFilePath)
end

-- 语音转文字
-- Event: GME_ON_PTT_SPEECH2TEXT_COMPLETED
function ChatVoiceMgr.SpeechToText(szFileID)
    GME_PTT_SpeechToText(szFileID)
end

-- 通过id去地址，有可能没有
function ChatVoiceMgr.GetFilePathByFileID(szFileID)
    return self.tbFileID2PathMap[szFileID]
end



-- 获取一个录音文件路径，应该是增长不重复的
function ChatVoiceMgr._getFilePath()
    local path = GetFullPath("gme")
    if not Lib.IsFileExist(path) then
        CPath.MakeDir(path)
    end

    local szDir = UIHelper.GBKToUTF8(path) .. (Platform.IsWindows() and "\\" or "/")
    local szName = string.format("%s_%s.ogg", os.date("%Y%m%d%H%M%S", os.time()), self.nCount)

    local szPath = string.format("%s%s", szDir, szName)

    self.nCount = self.nCount + 1

    return szPath
end

function ChatVoiceMgr._removeFilePath()
    local path = GetFullPath("gme")
    if not Lib.IsDirectoryExist(path, false) then
        return
    end

    -- -- TODO 删不掉？
    -- cc.FileUtils:getInstance():removeDirectory(path)

    local tbAllRecordFilePath = Lib.ListFiles(path) or {}
    for _, szFilePath in pairs(tbAllRecordFilePath) do
        Lib.RemoveFile(szFilePath)
    end
end

function ChatVoiceMgr._handlError(nErrorCode)
    TipsHelper.ShowNormalTip(GME_ERROR[nErrorCode])
    UIHelper.HideTouchMask()

    -- 还需要通知UI
end

function ChatVoiceMgr._makeChatData(filepath, fileid, text, nVoiceDuration)
    local tbMsg =
    {
        {type = "voice", fileid = fileid, time = nVoiceDuration},
        {type = "text", text = UTF8ToGBK(text)},
    }

    return tbMsg
end





