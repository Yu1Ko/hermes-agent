CollectMapEnv = CollectMapEnv or {}
local self = CollectMapEnv

local ccFileUtils = cc.FileUtils:getInstance()

local REMOTE_URL = "http://autobot.j3.work:8818/CollectMapFiles"
local FILE_LIST_PATH = "/cmapfilelist.lua"

local HTTP_REQUEST_KEY = "JX3_CMap_HTTP_REQ"
local HTTP_DOWNLOAD_FILELIST_KEY = "JX3_CMap_FILELIST_DOWNLOAD"
local HTTP_DOWNLOAD_FILE_KEY = "JX3_CMap_FILE_DOWNLOAD"
local _getUrl = function(szFileName, szPlatform)
    if szPlatform then
        return REMOTE_URL .. "/" .. szPlatform .. "/" .. szFileName
    else
        return REMOTE_URL .. "/" .. szFileName
    end
end

self.bAllFileDownloaded = nil -- 文件是否已经全部下载完
self.bProcessing = nil -- 是否正在处理下载中
GMHelper.szTempFileName = nil -- 下载的临时文件名

function CollectMapEnv.Init()
    if Platform.IsWindows() then
        self.szPlatform = 'pc'
    elseif Platform.IsAndroid() then
        self.szPlatform = 'android'
    elseif Platform.IsIos() then
        self.szPlatform = 'ios'
    elseif Platform.IsMac() then
        self.szPlatform = 'mac'
    end

    local szContent = '确认配置地图资源收集环境吗？\nTips:确认将强制退出游戏'
    local funcConfirm = function()
        self.bAllFileDownloaded = false
        self.bProcessing = true
        CURL_HttpRqst(HTTP_REQUEST_KEY, REMOTE_URL, false, 10)
        -- http request get 事件
        Event.Reg(
            self,
            "CURL_REQUEST_RESULT",
            function(szKey, bSuccess, bBufferSize)
                if szKey == HTTP_REQUEST_KEY then
                    Event.UnReg(self, "CURL_REQUEST_RESULT")
                    if bSuccess then
                        LOG.INFO("[CollectMapEnv] http request CMap url successed.")
                        GMHelper.szTempFileName = nil
                        local szTempFileName = "cmapfilelist.lua"
                        GMHelper.DownloadFile(HTTP_DOWNLOAD_FILELIST_KEY, _getUrl(szTempFileName), FILE_LIST_PATH)
                    else
                        LOG.INFO("[CollectMapEnv] http request CMap url failed.")
                        self.bProcessing = false
                    end
                end
            end
        )

        -- file download 事件
        Event.Reg(
            self,
            "CURL_DOWNLOAD_RESULT",
            function(szKey, bSuccess, pszValue, bBufferSize)
                if szKey == HTTP_DOWNLOAD_FILELIST_KEY then
                    self.OnFileListDownloaded(bSuccess)
                elseif szKey == HTTP_DOWNLOAD_FILE_KEY then
                    self.OnFileDownloaded(bSuccess)
                end
            end
        )

        self.CheckFinishTimer = Timer.AddCycle(self, 1, function ()
            if self.bAllFileDownloaded then
                Timer.DelTimer(self, self.CheckFinishTimer)
                self.CheckFinishTimer = nil
                -- 退出游戏
                Game.Exit()
            end
        end)
    end
    local funcCancel = function()
        print('cancel')
    end
    UIHelper.ShowConfirm(szContent, funcConfirm, funcCancel, true)
end

-- 文件列表下载成功
function CollectMapEnv.OnFileListDownloaded(bSuccess)
    if bSuccess then
        LOG.INFO("[GMHelper] OnFileListDownloaded successed.")
        -- 下载成功后把临时文件名改为正式文件名
        local szFileName = string.gsub(GMHelper.szTempFileName, "%.download$", "")
        local szFullPath = GetFullPath(szFileName)
        if ccFileUtils:isFileExist(szFullPath) then
            Lib.RemoveFile(szFullPath)
        end
        ccFileUtils:renameFile(GMHelper.szTempFileName, szFileName)
        GMHelper.szTempFileName = nil
        self.tbFileList = GMHelper.LoadFile(FILE_LIST_PATH)
        if not self.tbFileList or #self.tbFileList == 0 then
            LOG.INFO("[GMHelper] OnFileListDownloaded, filelist is empty.")
            self.bProcessing = false
            return
        end

        szFileName = table.remove(self.tbFileList)
        self.szDownloadingFilePath = szFileName

        GMHelper.DownloadFile(
            HTTP_DOWNLOAD_FILE_KEY,
            _getUrl(szFileName, self.szPlatform),
            szFileName
        )
    else
        LOG.INFO("[GMHelper] OnFileListDownloaded failed.")
    end
end

-- 文件下载成功（注意，下载下来的是加密文件）
function CollectMapEnv.OnFileDownloaded(bSuccess)
    if bSuccess then
        local szFileName = string.gsub(GMHelper.szTempFileName, "%.download$", "")
        local szFullPath = GetFullPath(szFileName)
        if ccFileUtils:isFileExist(szFullPath) then
            Lib.RemoveFile(szFullPath)
        end
        ccFileUtils:renameFile(GMHelper.szTempFileName, szFileName)
        GMHelper.szTempFileName = nil
    end
    LOG.INFO(
        "[GMHelper] OnFileDownloaded %s, %s.",
        self.szDownloadingFilePath,
        bSuccess and "successed" or "failed"
    )

    local szFileName = table.remove(self.tbFileList)
    if szFileName then
        self.szDownloadingFilePath = szFileName
        GMHelper.DownloadFile(
            HTTP_DOWNLOAD_FILE_KEY,
            _getUrl(szFileName, self.szPlatform),
            szFileName
        )
    else
        self.OnAllFileDownloaded()
    end
end

function CollectMapEnv.OnAllFileDownloaded()
    LOG.INFO("[GMHelper] OnAllFileDownloaded.")
    self.bAllFileDownloaded = true
    self.bProcessing = false
    self.bReDownload = false
end