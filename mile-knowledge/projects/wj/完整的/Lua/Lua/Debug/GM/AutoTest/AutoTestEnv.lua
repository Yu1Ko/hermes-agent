if not AutoTestEnv then
    AutoTestEnv = {
        className = "AutoTestEnv",
        text = '自动化测试',
        szPlaceHolder = '输入用例名',
        nViewID = VIEW_ID.PanelGMRightView,
        tCaseList = {},
        tTabBase = {},
        bCheckResult = false,
    }
end

local REQUEST_FAILED_RETRY_LIMIT = 3 -- 请求失败重试次数限制

local ccFileUtils = cc.FileUtils:getInstance()

local REMOTE_URL = "http://bot.xgame.work:8285/autotest"
local REMOTE_ROBOT_VERSION = "http://bot.xgame.work:8000/getBotVersion"
local VERSION_FILE = "mui/Lua/AutoBot/version.txt"
local FILE_LIST_PATH = "mui/Lua/AutoBot/FileList.lua"
local ROBOT_CASE_LIST = "mui/Lua/AutoBot/RobotCaseList.lua"

local HTTP_REQUEST_KEY = "JX3_ROBOT_HTTP_REQ"
local HTTP_DOWNLOAD_VERSIONLIST_KEY = "JX3_ROBOT_VERSIONLIST_DOWNLOAD"
local HTTP_CHECK_VERSION_KEY = "JX3_ROBOT_CHECK_VERSION"
local HTTP_DOWNLOAD_FILELIST_KEY = "JX3_ROBOT_FILELIST_DOWNLOAD"
local HTTP_DOWNLOAD_FILE_KEY = "JX3_ROBOT_FILE_DOWNLOAD"
local _getUrl = function(szFileName) return REMOTE_URL.."/"..szFileName end

AutoTestEnv.bAllFileDownloaded = nil -- 文件是否已经全部下载完
AutoTestEnv.bProcessing = nil -- 是否正在处理下载中
AutoTestEnv.szTempFileName = nil  -- 下载的临时文件名
AutoTestEnv.bReDownload = nil -- 是否重新下载
AutoTestEnv.bRequireRobotScript = nil -- 是否正在require脚本
AutoTestEnv.nRetryTimes = 0 -- 失败尝试次数

function AutoTestEnv.Download(szURL, szFileName)
    -- 要判断下载目录是否存在，不在就先创建
    local fileUtil = cc.FileUtils:getInstance()
    szFileName = string.gsub(szFileName, "\\", "/")
    local dirPath = string.sub(szFileName, 1, string.find(szFileName, "/[^/]*$"))
    if dirPath and dirPath ~= "" and not fileUtil:isDirectoryExist(dirPath) then
        fileUtil:createDirectory(dirPath)
    end
    CURL_DownloadFile("AutoTest", szURL, GetFullPath(szFileName), true, 120)
end

function AutoTestEnv.FileAdd(szFileName, szContent)
    -- 要判断下载目录是否存在，不在就先创建
    local fileUtil = cc.FileUtils:getInstance()
    szFileName = string.gsub(szFileName, "\\", "/")
    local dirPath = string.sub(szFileName, 1, string.find(szFileName, "/[^/]*$"))
    if dirPath and dirPath ~= "" and not fileUtil:isDirectoryExist(dirPath) then
        fileUtil:createDirectory(dirPath)
    end

    local szFullPath = GetFullPath(szFileName)
    local fileData = Lib.GetStringFromFile(UIHelper.UTF8ToGBK(szFullPath))
    if fileData then
        szContent = fileData .. szContent
    end
    fileUtil:writeStringToFile(szContent, szFullPath)
end


function AutoTestEnv.FileWrite(szFileName, szContent)
    local fileUtil = cc.FileUtils:getInstance()
    szFileName = string.gsub(szFileName, "\\", "/")
    local dirPath = string.sub(szFileName, 1, string.find(szFileName, "/[^/]*$"))
    if dirPath and dirPath ~= "" and not fileUtil:isDirectoryExist(dirPath) then
        fileUtil:createDirectory(dirPath)
    end
    local szFullPath = GetFullPath(szFileName)
    fileUtil:writeStringToFile(szContent, szFullPath)
end


function AutoTestEnv.CopyFile(sourceFile, destFile)
    local fileUtil = cc.FileUtils:getInstance()
    destFile = string.gsub(destFile, "\\", "/")
    local dirPath = string.sub(destFile, 1, string.find(destFile, "/[^/]*$"))
    if dirPath and dirPath ~= "" and not fileUtil:isDirectoryExist(dirPath) then
        fileUtil:createDirectory(dirPath)
    end

    local sourceContent = Lib.GetStringFromFile(UIHelper.UTF8ToGBK(GetFullPath(sourceFile)))
    if sourceContent ~= "" then
        fileUtil:writeStringToFile(sourceContent, GetFullPath(destFile))
        LOG.ERROR(string.format("Backup Success:%s to %s", GetFullPath(sourceFile), GetFullPath(destFile)))
    else
        LOG.ERROR(string.format("Backup Failed:%s to %s", GetFullPath(szFileName), GetFullPath(destFile)))
    end
end


function AutoTestEnv:Init()
    if self.bInit then
        LOG.INFO("[AutoTestEnv] Has Inited.")
        return 
    end

    table.insert(GMMgr.tMiddleCMd, {tbCellLeft = AutoTestEnv})
    self.bAllFileDownloaded = false
    self.bProcessing = true
    CURL_HttpRqst(HTTP_REQUEST_KEY, REMOTE_URL, false, 10)
    -- http request get 事件
    Event.Reg(self, "CURL_REQUEST_RESULT", function (szKey, bSuccess, bBufferSize)
        if szKey == HTTP_REQUEST_KEY then
            if bSuccess then
                LOG.INFO("[AutoTestEnv] http request robot url successed.")
                -- 进行机器人版本检验
                CURL_HttpRqst(HTTP_CHECK_VERSION_KEY, REMOTE_ROBOT_VERSION, false, 10)
            else
                LOG.INFO("[AutoTestEnv] http request robot url failed.")
                self.bProcessing = false
                Event.UnReg(self, "CURL_REQUEST_RESULT")
            end
        elseif szKey == HTTP_CHECK_VERSION_KEY then
            if bSuccess then
                local szValue = arg2
                -- 目前的判断重下逻辑太简陋只进行了版本校验, 应该至少加个文件列表完整检查
                self.bReDownload = self:IsReDownload(tonumber(szValue))
                -- 这里需删除旧文件, 不然新文件改名会不成功
                if self.bReDownload then
                    local REMOTE_VERSION_LIST_URL = string.format("%s/version.txt", REMOTE_URL)
                    self:DownloadFile(HTTP_DOWNLOAD_VERSIONLIST_KEY, REMOTE_VERSION_LIST_URL, VERSION_FILE)
                else
                    -- 无需下载就直接加载模块
                    self:ModleLoad()
                    LOG.INFO("[AutoTestEnv] Check remote Robot Version, not need download.")
                    
                end
                Event.UnReg(self, "CURL_REQUEST_RESULT")
                self.nRetryTimes = 0
            else
                LOG.INFO("[AutoTestEnv] http request robot version check failed.")
                -- 请求失败需要进行重试
                local fnCallBack = function ()
                    CURL_HttpRqst(HTTP_CHECK_VERSION_KEY, REMOTE_ROBOT_VERSION, false, 10)
                end
                self:OnRequestFailed(fnCallBack, "version check")
            end
        end
    end)

    -- file download 事件
    Event.Reg(self, "CURL_DOWNLOAD_RESULT", function(szKey, bSuccess, pszValue, bBufferSize)
        if szKey == HTTP_DOWNLOAD_VERSIONLIST_KEY then
            self:OnVersionListDownloaded(bSuccess)
        elseif szKey == HTTP_DOWNLOAD_FILELIST_KEY then
            self:OnFileListDownloaded(bSuccess)
        elseif szKey == HTTP_DOWNLOAD_FILE_KEY then
            self:OnFileDownloaded(bSuccess)
        end
    end)

    self.bInit = true
end


function AutoTestEnv:LoadFile(filePath)
    local szFullPath = GetFullPath(filePath)
    if ccFileUtils:isFileExist(szFullPath) then
        local fileContent = ccFileUtils:getStringFromFile(szFullPath)
        local chunk = loadstring(fileContent)  -- Lua5.1
        if chunk then
            return chunk()
        end
    end
    return false
end

-- 下载某个文件
function AutoTestEnv:DownloadFile(szKey, szURL, szFileName, fileExistHandler)
    local szFullPath = GetFullPath(szFileName)
    if not self.bReDownload and fileExistHandler and ccFileUtils:isFileExist(szFullPath) then
        fileExistHandler()
        return
    end
    -- 下载前对旧文件执行一次删除, 避免重命名失败
    Lib.RemoveFile(szFullPath)
    
    -- 要判断下载目录是否存在，不在就先创建
    local dirPath = string.sub(szFileName, 1, string.find(szFileName, "/[^/]*$"))
    if dirPath and dirPath ~= "" and not ccFileUtils:isDirectoryExist(dirPath) then
        ccFileUtils:createDirectory(dirPath)
    end
    self.szTempFileName = string.format("%s.download", szFullPath)
    LOG.INFO(string.format("[AutoTestEnv] Preparing to download %s.", self.szTempFileName))
    -- 先下载为临时文件,等判断下载成功后再改为正式文件名
    CURL_DownloadFile(szKey, szURL, self.szTempFileName, true, 120)
end

-- 版本列表下载成功
function AutoTestEnv:OnVersionListDownloaded(bSuccess)
    if bSuccess then
        self.nRetryTimes = 0
        LOG.INFO("[AutoTestEnv] OnVersionTxt Downloaded successed.")
        -- 下载成功后把临时文件名改为正式文件名
        local szFileName = string.gsub(self.szTempFileName, "%.download$", "")
        ccFileUtils:renameFile(self.szTempFileName, szFileName)
        self.szTempFileName = nil
        local szTempFileName = "filelist.lua"
        -- 获取版本号后就可以下载fileslist
        self:DownloadFile(HTTP_DOWNLOAD_FILELIST_KEY, _getUrl(szTempFileName), FILE_LIST_PATH)
    else
        LOG.INFO("[AutoTestEnv] OnVersionTxt Downloaded failed.")
        local fnCallBack = function()
            local REMOTE_VERSION_LIST_URL = string.format("%s/version.txt", REMOTE_URL)
            self:DownloadFile(HTTP_DOWNLOAD_VERSIONLIST_KEY, REMOTE_VERSION_LIST_URL, VERSION_FILE)
        end
        -- 版本文件下载失败重试
        self:OnRequestFailed(fnCallBack, "version.txt download")
    end
end

-- 请求失败重试
function AutoTestEnv:OnRequestFailed(fnCallBack, szMsg)
    if self.nRetryTimes < REQUEST_FAILED_RETRY_LIMIT then
        self.nRetryTimes = self.nRetryTimes + 1
        LOG.INFO("[AutoTestEnv] %s, retry times %d", szMsg, self.nRetryTimes)
        fnCallBack()
        return true
    else
        Event.UnReg(self, "CURL_REQUEST_RESULT")
        LOG.INFO("[AutoTestEnv] %s retry failed out limited.", szMsg)
    end
end

-- 文件列表下载成功
function AutoTestEnv:OnFileListDownloaded(bSuccess)
    if bSuccess then
        self.nRetryTimes = 0
        LOG.INFO("[AutoTestEnv] OnFileListDownloaded successed.")
        -- 下载成功后把临时文件名改为正式文件名
        local szFileName = string.gsub(self.szTempFileName, "%.download$", "")
        ccFileUtils:renameFile(self.szTempFileName, szFileName)
        self.szTempFileName = nil
        self.tbFileList = self:LoadFile(FILE_LIST_PATH)
        if not self.tbFileList or #self.tbFileList == 0 then
            LOG.INFO("[AutoTestEnv] OnFileListDownloaded, filelist is empty.")
            self.bProcessing = false
            return
        end
        self.szDestFileName = table.remove(self.tbFileList)
        self.szDownloadingFilePath = string.format("mui/Lua/AutoBot/%s",self.szDestFileName)
        self:DownloadFile(HTTP_DOWNLOAD_FILE_KEY, _getUrl(self.szDestFileName), self.szDownloadingFilePath, function() self:OnFileDownloaded(true, true) end)
    else
        LOG.INFO("[AutoTestEnv] OnFileListDownloaded failed.")
        local fnCallBack = function ()
            local szTempFileName = "filelist.lua"
            -- 获取版本号后就可以下载fileslist
            self:DownloadFile(HTTP_DOWNLOAD_FILELIST_KEY, _getUrl(szTempFileName), FILE_LIST_PATH)
        end
        self:OnRequestFailed(fnCallBack, "filelist.lua download")
    end
end

-- 文件下载成功（注意，下载下来的是加密文件）
function AutoTestEnv:OnFileDownloaded(bSuccess, bFileIsExist)
    if bFileIsExist then
        LOG.INFO("[AutoTestEnv] OnFileDownloaded %s, file is exist, no need download.", self.szDownloadingFilePath)
    else
        if bSuccess then
            self.nRetryTimes = 0
            local szFileName = string.gsub(self.szTempFileName, "%.download$", "")
            ccFileUtils:renameFile(self.szTempFileName, szFileName)
            self.szTempFileName = nil
            LOG.INFO("[AutoTestEnv] OnFileDownloaded %s, Success.", self.szDownloadingFilePath)
        else
            LOG.INFO("[AutoTestEnv] OnFileDownloaded %s, Failed.", self.szDownloadingFilePath)
            local fnCallBack = function ()
                self.szDownloadingFilePath = string.format("mui/Lua/AutoBot/%s", self.szDestFileName)
                self:DownloadFile(HTTP_DOWNLOAD_FILE_KEY, _getUrl(self.szDestFileName), self.szDownloadingFilePath, function() self:OnFileDownloaded(true, true) end)
            end
            -- 下载失败重试，重试超过次数限制就不下了
            self:OnRequestFailed(fnCallBack, string.format("file:%s download", self.szTempFileName))
            return
        end
    end

    self.szDestFileName = table.remove(self.tbFileList)
    if self.szDestFileName then
        self.szDownloadingFilePath =  string.format("mui/Lua/AutoBot/%s",self.szDestFileName)
        self:DownloadFile(HTTP_DOWNLOAD_FILE_KEY, _getUrl(self.szDestFileName), self.szDownloadingFilePath, function() self:OnFileDownloaded(true, true) end)
    else
        self:OnAllFileDownloaded()
    end
end

function AutoTestEnv:OnAllFileDownloaded()
    LOG.INFO("[AutoTestEnv] OnAllFileDownloaded.")
    self.bAllFileDownloaded = true
    self.bProcessing = false
    self.bReDownload = false
    self:ModleLoad()
end

-- -- 重新下载判断
function AutoTestEnv:IsReDownload(nRemoteVersion)
    -- TODO:这里的重下逻辑加个本地文件列表完整性检查
    local szFullPath = GetFullPath(VERSION_FILE)
    if not Lib.IsFileExist(szFullPath) then
        return true
    end
    local nCurVersion = tonumber(Lib.GetStringFromFile(szFullPath))
    return nCurVersion ~= nRemoteVersion or self:RobotFilesListCheck()
end

function AutoTestEnv:RobotFilesListCheck()
    local tbFileList = self:LoadFile(FILE_LIST_PATH)
    if not tbFileList or #tbFileList == 0 then
        LOG.INFO("[AutoTestEnv] local GM filelist is empty, need redownload.")
        return true
    end

    for _, filepath in ipairs(tbFileList) do
        local szFullPath = GetFullPath(string.format("mui/Lua/AutoBot/%s",filepath))
        if not ccFileUtils:isFileExist(szFullPath) then
            LOG.INFO("[AutoTestEnv] File integrity check false, %s need redownload.", szFullPath)
            return true
        end
    end
    LOG.INFO("[AutoTestEnv] File integrity check true, not need redownload.")
    return false
end

function AutoTestEnv:ModleLoad()
    self.bRequireRobotScript = true
    -- 全部下载完，就可以require
    LOG.INFO("[AutoTestEnv] require Robot script begin .")
    OutputMessage("MSG_ANNOUNCE_RED","机器人脚本require中,请稍等")
    require("Lua/AutoBot/AutoTestBot/AutoTestBot.lua")
    local robotCaseList = self:LoadFile(ROBOT_CASE_LIST)
    for index, robotCase in ipairs(robotCaseList) do
        local szFileName = string.format("Lua/AutoBot/Bot/%s",robotCase)
        if Lib.IsFileExist(szFileName) then
            LOG.INFO("[AutoTestEnv] prepare require %s.", szFileName)
            require(szFileName)
        else
            LOG.INFO("[AutoTestEnv] %s not exist", szFileName)
        end
    end
    OutputMessage("MSG_ANNOUNCE_RED","机器人脚本require完成")
    LOG.INFO("[AutoTestEnv] require Robot script end .")
    self.bRequireRobotScript = false
end

function AutoTestEnv:FillAll()
    self.tCaseList = {}
    for _, tBotInfo in pairs(BotDescList) do
        local tTemp = {ID = tBotInfo.szDesc, Name = UIHelper.UTF8ToGBK(tBotInfo.szDesc), TypeName = tBotInfo.szName, ButtonLabel = '启动',
            tBtnStatus = {
                BtnOperate = true, BtnOperate1 = false, BtnOperate2 = false,
                BtnOperate3 = false, BtnOperate4 = false
                    }
         }
         table.insert(self.tCaseList, tTemp)
    end
end

function AutoTestEnv:ShowSubWindow(tbGMView)
    tbGMView.PanelRightView:setVisible(true)
    tbGMView.LabelExtension:setVisible(true)
    tbGMView.EditSearchRight:setPlaceHolder(self.szPlaceHolder)
    if tbGMView.tbLastData~=nil and next(tbGMView.tbLastData) then
        UIHelper.SetString(tbGMView.EditSearchRight, tbGMView.tbLastData.EditLabelRight)
    else
        UIHelper.SetString(tbGMView.EditSearchRight, "")
    end
    UIHelper.SetString(tbGMView.LabelExtension, self.text)
end


function AutoTestEnv:OnClick(tbGMView)
    if self.bRequireRobotScript then
        OutputMessage("MSG_ANNOUNCE_RED","机器人脚本require中,请稍等")
    end
    if not next(self.tCaseList) then
        self:FillAll()
    end
    self:ShowSubWindow(tbGMView)
    UIHelper.SetString(tbGMView.EditSearchRight, "")
    tbGMView.tbGMPanelRight = AutoTestEnv
    tbGMView.tbRawDataRight = self.tCaseList
    tbGMView.tbSearchResultRight = self.tCaseList
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbRawDataRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end

function AutoTestEnv:BtnOperate(tbData)
    AutoTestBot:PrepareRun(tbData.TypeName, true)
end

function AutoTestEnv:GetAllData(tbGMView)
    tbGMView.tbSearchResultRight = self.tCaseList
    UIHelper.TableView_init(tbGMView.LuaTableViewRight, #tbGMView.tbSearchResultRight, PREFAB_ID.WidgetSunmon)
    UIHelper.TableView_reloadData(tbGMView.LuaTableViewRight)
end


AutoTestEnv:Init()