-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: GMHelper
-- Date: 2023-12-29 17:20:17
-- Desc: ?
-- ---------------------------------------------------------------------------------

GMHelper = GMHelper or {}
local self = GMHelper

local ccFileUtils = cc.FileUtils:getInstance()

local REMOTE_URL = "http://gm.j3.work:19090"
local VERSION_LIST_PATH = "mui/Lua/Debug/GM/versionlist.txt"
local GM_VERSION_FILE = "mui/Lua/Debug/GM/GMVersion.txt"
local BEHAVIOR_FILE = "mui/Lua/Debug/GM/Behavior.txt"
local FILE_LIST_PATH = "mui/Lua/Debug/GM/filelist.lua"
local CLIENT_INFO_FILE = "ClientInfo.json"
local CONFIG_HTTP_FILE = "configHttpFile.ini"
local CONFIG_HTTP_BACKUP= "configHttpFile.ini.bak"
local GM_DEBUG_VERSION = "00000000"
local ETG_UPDATE = 0

local HTTP_REQUEST_KEY = "JX3_GM_HTTP_REQ"
local HTTP_INTRANET_KEY = "JX3_INTRANET_HTTP_REQ"
local HTTP_DOWNLOAD_VERSIONLIST_KEY = "JX3_GM_VERSIONLIST_DOWNLOAD"
local HTTP_DOWNLOAD_FILELIST_KEY = "JX3_GM_FILELIST_DOWNLOAD"
local HTTP_DOWNLOAD_FILE_KEY = "JX3_GM_FILE_DOWNLOAD"
local IS_DEV_ENV = ccFileUtils:isDirectoryExist("DebugFiles")
local _getUrl = function(szFileName, szBranch, szVersion) return REMOTE_URL.."/"..szBranch.."/"..szVersion.."/"..szFileName end
local _getFullPath = function(filepath) return Platform.IsMac() and filepath or GetFullPath(filepath) end

self.bAllFileDownloaded = nil -- 文件是否已经全部下载完
self.bProcessing = nil -- 是否正在处理下载中
self.szTempFileName = nil  -- 下载的临时文件名
self.tClientInfo = nil -- 客户端信息
self.nGMVersion = nil -- GM对应的版本号
self.bReDownload = nil -- 是否重新下载
self.bGMMgrInit = false

function GMHelper.Init()
    GMHelper.RegEvent()
    if IsKGPublish() then
        LOG.INFO("[GM] [GMHelper] Publish Version, No Need Download.")
        --带publish且打开config的GM才进行这部分逻辑
        if Config.bGM then
            GMHelper.ParseConfigHttp()
        end
    else
        LOG.INFO("[GM] [GMHelper] is not Publish Version.")
    end
    if IS_DEV_ENV or IsKGPublish() then
        LOG.INFO("[GM] [GMHelper] Dev env or Publish Version.")
        self.bAllFileDownloaded = true
        self.bProcessing = false
        return
    end
    self.BehaviorRecord()
    self.tClientInfo = self.ParseClientInfo()
    self.bAllFileDownloaded = false
    if not Config.bGM then
        LOG.INFO("[GM] [GMHelper] config GM is false.")
        return
    end
    self.bProcessing = true
    LOG.INFO("[GM] [GMHelper] CURL_HttpRqst %s.", REMOTE_URL)
    CURL_HttpRqst(HTTP_REQUEST_KEY, REMOTE_URL, false, 10)
end


function GMHelper.RegEvent()
    -- file download 事件
    Event.Reg(self, "CURL_DOWNLOAD_RESULT", function(szKey, bSuccess, pszValue, bBufferSize)
        if szKey == HTTP_DOWNLOAD_VERSIONLIST_KEY then
            self.OnVersionListDownloaded(bSuccess)
        elseif szKey == HTTP_DOWNLOAD_FILELIST_KEY then
            self.OnFileListDownloaded(bSuccess)
        elseif szKey == HTTP_DOWNLOAD_FILE_KEY then
            self.OnFileDownloaded(bSuccess)
        end
    end)
    -- http request get 事件
    Event.Reg(self, "CURL_REQUEST_RESULT", function (szKey, bSuccess, bBufferSize)
        if szKey == HTTP_REQUEST_KEY then
            Event.UnReg(self, "CURL_REQUEST_RESULT")
            if bSuccess then
                LOG.INFO("[GM] [GMHelper] http request gm url successed.")
                -- 成功以后下载versionlist
                local REMOTE_VERSION_LIST_URL = string.format("%s/%s/versionlist.txt", REMOTE_URL, self.tClientInfo.branch)
                self.DownloadFile(HTTP_DOWNLOAD_VERSIONLIST_KEY, REMOTE_VERSION_LIST_URL, VERSION_LIST_PATH)
            else
                LOG.INFO("[GM] [GMHelper] http request gm url failed.")
                self.bProcessing = false
            end
        end
    end)
end

function GMHelper.OpenGM()
    if self.bProcessing then
        LOG.INFO("[GM] [GMHelper] GM button is clicked.")
        GMHelper.ShowNormalTip("GM脚本正在加载中, 请稍等...")
        return
    end

    -- 比如之前下载出错了，每次点GM的时候，再去下载，这个暂时不做
    -- NOTE:走v5下载无法判断是否真的下载完成
    if not self.bAllFileDownloaded then
        LOG.INFO("[GM] [GMHelper] not AllFileDownloaded.")
    end

    if self.bReDownload then
        LOG.INFO("[GM] [GMHelper] had not find match GM script , please reboot the game.")
        GMHelper.ShowNormalTip("找不到对应版本的GM脚本, 请尝试重启游戏...")
        return
    end

    -- 这里可能出现V5脚本还没下载完, 就在GMMgr中去require, 导致找不到对应的脚本
    if not GMMgr then
        require("Lua/Debug/GM/GMMgr.lua")
        LOG.INFO("[GM] [GMHelper] mgr is successed.")
        GMMgr.Init()
        GMHelper.ShowNormalTip("GMMgr加载成功")
        self.bGMMgrInit = true
    else
        if not self.bGMMgrInit then
            LOG.INFO("[GM] [GMHelper] GMMgr require Scrpit Failed.")
            GMHelper.ShowNormalTip("GMMgr加载失败, 请检查相关脚本是否全部下载完成")
        end
    end

    if UIMgr.GetView(VIEW_ID.PanelGM) then
        LOG.INFO("[GM] [GMHelper] Close the PanelGM.")
        UIMgr.Close(VIEW_ID.PanelGM)
    else
        LOG.INFO("[GM] [GMHelper] Open the PanelGM.")
        UIMgr.Open(VIEW_ID.PanelGM)
    end
end

function GMHelper.CloseGM()
    LOG.INFO("[GM] [GMHelper] clicked Close button to close the PanelGM.")
    UIMgr.Close(VIEW_ID.PanelGM)
end

function GMHelper.ShowNormalTip(szMessage)
    LOG.INFO(string.format("[GMHelper] %s", szMessage))
    TipsHelper.ShowNormalTip(szMessage)
end

-- 记录启动和更新资源版本号
function GMHelper.BehaviorRecord()
    local szFullPath = _getFullPath(BEHAVIOR_FILE)
    local nTime = GetCurrentTime()
    local szDateText  = TimeLib.GetDateText(nTime)
    local szResourceVersion = GetPakV5Version() or 0
    local szCurrentContent = Lib.GetStringFromFile(szFullPath) or "Time\tResVersion\tGMVersion"
    local szContent = string.format("%s\n%s\t%s",szCurrentContent,szDateText,szResourceVersion)
    LOG.INFO("[GM] [GMHelper] %s.", szContent)
    -- 要判断下载目录是否存在，不在就先创建
    local dirPath = string.sub(BEHAVIOR_FILE, 1, string.find(BEHAVIOR_FILE, "/[^/]*$"))
    if dirPath and dirPath ~= "" then
        LOG.INFO("[GM] [GMHelper] BEHAVIOR_FILE path is  %s", dirPath)
        if not ccFileUtils:isDirectoryExist(dirPath) then
            ccFileUtils:createDirectory(dirPath)
            LOG.INFO("[GM] [GMHelper] BEHAVIOR_FILE path is not exist: %s  dir had created", dirPath)
        else
            LOG.INFO("[GM] [GMHelper] BEHAVIOR_FILE path is already exist: %s", dirPath)
        end
    end
    ccFileUtils:writeStringToFile(szContent, szFullPath)
    LOG.INFO("[GM] [GMHelper] BEHAVIOR_FILE writeStringToFile: %s", szFullPath)
end

-- 解析客户端信息文件
function GMHelper.ParseClientInfo()
    local defaultInfo = {
        channel = "develop",
        branch = "trunk"
    }
    local szClientInfo = PakV5OpenPlatformFile(CLIENT_INFO_FILE)
    if szClientInfo then
        local tClientInfo = JsonDecode(szClientInfo) or defaultInfo
        return tClientInfo
    end
    return defaultInfo
end

function GMHelper.ParseConfigHttp()
    local szFullPath = _getFullPath(CONFIG_HTTP_BACKUP)
    local szCustomFields = '127.0.0.1'
    if Lib.IsFileExist(szFullPath) then
        local szMessage = "是否删除上次confighttp.ini备份"
        local fnDeleteBackUp = function ()
            Lib.RemoveFile(szFullPath)
            GMHelper.ShowNormalTip("删除上次confighttp.ini备份")
        end
        UIHelper.ShowConfirm(szMessage, function () fnDeleteBackUp() end)
    end
    local ini = Ini.Open(CONFIG_HTTP_FILE, true)
    if ini then
        local downloader0 = ini:ReadString("downloader", "downloader0", "")
        local downloader1 = ini:ReadString("downloader", "downloader1", "")
        local szPakV5Option = downloader0
        local nOpionDef =  1
        if downloader1 ~="" then
            if string.find(downloader1, "gm") or string.find(downloader1, "devlogin") then
                local indexNow = string.find(downloader1,"_")
                if not indexNow then
                    GMHelper.ShowNormalTip("downloader0的值不符合规范")
                    return
                end
                local szOption = string.sub(downloader1, 1, indexNow-1)
                nOpionDef = table.get_key(GMHelper.OPTION_FILTER_TYPE, szOption) or nOpionDef
            else
                local etagGetFile = ini:ReadString(downloader1, "getFile", "127.0.0.1")
                szCustomFields = string.match(etagGetFile, "%d+%.%d+%.%d+%.%d+") or "127.0.0.1"
            end
        end

        -- 内外网url判断
        local szUrl = ini:ReadString(szPakV5Option, "getFile", "")
        local nUrlType = 2
        if string.find(szUrl, "10.11.39.60") then
            -- 内网
            nUrlType = 1
        end

        -- UI显示配置
        GMHelper.nLastGmDevOpion = nOpionDef
        GMHelper.nLastUrlType = nUrlType
        GMHelper.GmDevLogin =
        {
            [1] =
            {
                szType = FilterType.RadioButton,
                szSubType = FilterSubType.Small,
                bAllowAllOff = false,
                bResponseImmediately = false,
                szTitle = "GM/开发者登录配置",
                tbList = {"无", "GM+开发者","只要GM","只要开发者"},
                tbDefault = {tonumber(nOpionDef)},
            },
            [2] =
            {
                szType = FilterType.RadioButton,
                szSubType = FilterSubType.Small,
                bAllowAllOff = false,
                bResponseImmediately = false,
                szTitle = "内外网更新url配置",
                tbList = {"内网url","外网url"},
                tbDefault = {tonumber(nUrlType)},
            },
            [3] =
            {
                szType = FilterType.RadioButton,
                szSubType = FilterSubType.Small,
                bAllowAllOff = false,
                bResponseImmediately = true,
                szTitle = "自驾etag(127.0.0.1为未启用)",
                tbList = {szCustomFields, "修改","删除"},
                tbDefault = {1},
            },
            [4] =
            {
                szType = FilterType.RadioButton,
                szSubType = FilterSubType.Small,
                bAllowAllOff = false,
                bResponseImmediately = true,
                szTitle = "configHttpFile.ini操作",
                tbList = {"无", "查看", "删除", "备份", "用备份还原"},
                tbDefault = {1},
            },
        }
        ini:Close()
        -- 绑定一下筛选时的关键字
        setmetatable(GMHelper.GmDevLogin, {
                     __index = {
                        Key = "GmDevLogin",
                     }
                })
    end
end

-- 修改downloader字段
function GMHelper.UpdateDownloaderKey(szKeyName)
    local ini = Ini.Open(CONFIG_HTTP_FILE, true)
    if ini then
        ini:WriteInteger("enable", "fileVersion", 99999999)
        -- 直接添加downloader1, 不过要先获取原来的资源字段
        local rawDownloader0 = ini:ReadString("downloader", "downloader0", "")
        local szSection = string.format("%s_%s", szKeyName, rawDownloader0)
        ini:WriteString("downloader", "downloader1", szSection)
        if not ini:IsSectionExist(szSection) then
            ini:WriteString(szSection, "repoName", "ht_etag")
            ini:WriteInteger(szSection, "versionType", 3)
            ini:WriteInteger(szSection, "getSvnVersion", 0)
            ini:WriteInteger(szSection, "getVersionFile", 0)
            ini:WriteInteger(szSection, "getVersionBaseFile3", 0)
            local szResourceVersion = GetPakV5Version() or 0
            local szGetEtagFolder = string.format("http://newgm.j3.work:18080/ht_etag/%s/%s/",szSection, szResourceVersion)
            local szGetFile = string.format("http://newgm.j3.work:18080/ht/%s/%s/",szSection, szResourceVersion)
            ini:WriteString(szSection, "getEtagFolder", szGetEtagFolder)
            ini:WriteString(szSection, "getFile", szGetFile)
        end
        GMHelper.ShowNormalTip("更新GM和开发者相关配置完成")
        ini:Save(CONFIG_HTTP_FILE)
        ini:Close()
        return true
    end
end

-- 修改etag_self
function GMHelper.UpdateEtagSelf(szIp)
    local ini = Ini.Open(CONFIG_HTTP_FILE, true)
    if ini then
        ini:WriteString("downloader", "downloader1", "etag_self")
        ini:WriteInteger("enable", "fileVersion", 99999999)
        ini:WriteString("etag_self", "repoName", "ht_etag")
        ini:WriteInteger("etag_self", "versionType", 3)
        ini:WriteInteger("etag_self", "getSvnVersion", 0)
        ini:WriteInteger("etag_self", "getVersionFile", 0)
        ini:WriteInteger("etag_self", "getVersionBaseFile3", 0)
        local szGetEtagFolder = string.format("http://%s:8285/ht_etag/",szIp)
        local szGetFile = string.format("http://%s:8285/ht/",szIp)
        ini:WriteString("etag_self", "getEtagFolder", szGetEtagFolder)
        ini:WriteString("etag_self", "getFile", szGetFile)
    end
    GMHelper.ShowNormalTip("更新自驾etag ip完成")
    ini:Save(CONFIG_HTTP_FILE)
    ini:Close()
end

-- 删除downloader1
function GMHelper.DeleteDownloader1()
    local ini = Ini.Open(CONFIG_HTTP_FILE, true)
    if ini then
        local rawDownloader1 = ini:ReadString("downloader", "downloader1", "")
        if rawDownloader1 ~="" then
            ini:EraseKey("downloader", "downloader1")
            GMHelper.ShowNormalTip("删除downloader字段中的downloader1完成")
        else
            GMHelper.ShowNormalTip("未找到downloader字段中的downloader1")
        end
        ini:Save(CONFIG_HTTP_FILE)
        ini:Close()
        return true
    end
end

function GMHelper.UpdateCdnUrl(bExtranetCdn)
    local ini = Ini.Open(CONFIG_HTTP_FILE, true)
    local bUpdateSuccess = false
    if ini then
        local szCdnSection = ini:ReadString("downloader", "downloader0", "")
        local szUrl = ini:ReadString(szCdnSection, "getFile", "")
        local szSectionBak = string.format("%s_bak", szCdnSection)
        if not string.find(szUrl, "10.11.39.60") and not ini:IsSectionExist(szSectionBak) then
            local szNextKey = "version"
            while szNextKey do
                local szOldValue= ini:ReadString(szCdnSection, szNextKey, "")
                ini:WriteString(szSectionBak, szNextKey, szOldValue)
                szNextKey = ini:GetNextKey(szCdnSection, szNextKey)
            end
        end
        if not bExtranetCdn then
            local szNewUrl = string.format("http://10.11.39.60/v5/%s/", szCdnSection)
            ini:WriteString(szCdnSection, "getFile", szNewUrl)
            -- 删除原来其他的cdn
            ini:EraseKey(szCdnSection, "getFile1")
            ini:EraseKey(szCdnSection, "getFile2")
            ini:EraseKey(szCdnSection, "getFile3")
            ini:EraseKey(szCdnSection, "getFile4")
            ini:EraseKey(szCdnSection, "getFile5")
            ini:EraseKey(szCdnSection, "getFile6")
            GMHelper.ShowNormalTip("切换cdn地址成功")
            bUpdateSuccess = true
        else
            if ini:IsSectionExist(szSectionBak) then
                local szNextKey = "version"
                while szNextKey do
                    local szOldValue= ini:ReadString(szSectionBak, szNextKey, "")
                    ini:WriteString(szCdnSection, szNextKey, szOldValue)
                    szNextKey = ini:GetNextKey(szSectionBak, szNextKey)
                end
                GMHelper.ShowNormalTip("切换cdn地址成功")
                bUpdateSuccess = true
            else
                GMHelper.ShowNormalTip("切换cdn地址失败, 找不到外网cdn地址")
            end
        end
        ini:Save(CONFIG_HTTP_FILE)
        ini:Close()
    else
        GMHelper.ShowNormalTip(string.format("%s, 读取失败", CONFIG_HTTP_FILE))
    end
    return bUpdateSuccess
end

-- 删除confighttp.ini
function GMHelper.DeleteConfigHttp()
    local szFilePath = _getFullPath(CONFIG_HTTP_FILE)
    if Lib.IsFileExist(szFilePath) then
        Lib.RemoveFile(szFilePath)
        GMHelper.ShowNormalTip("confighttp.ini 已删除, 请重启游戏")
    else
        GMHelper.ShowNormalTip("confighttp.ini 不存在")
    end
end

-- 备份confighttp.ini
function GMHelper.BackupConfigHttp()
    local szFullPath = _getFullPath(CONFIG_HTTP_BACKUP)
    local fnBackupFile = function ()
        local szText = Lib.GetStringFromFile(CONFIG_HTTP_FILE)
        Lib.WriteStringToFile(szText, szFullPath)
        GMHelper.ShowNormalTip("confighttp.ini备份完成")
    end
    if not Lib.IsFileExist(szFullPath) then
        fnBackupFile()
    else
        UIHelper.ShowConfirm("备份已经存在, 是否覆盖?", function () fnBackupFile() end)
    end
end

-- 还原confighttp.ini
function GMHelper.ReStoreConfigHttp()
    local szFilePath = _getFullPath(CONFIG_HTTP_FILE)
    local szBackUpFilePath= _getFullPath(CONFIG_HTTP_BACKUP)
    -- 判断有无备份, 有就删除confighttp后备份重命名
    if Lib.IsFileExist(szBackUpFilePath) then
        Lib.RemoveFile(szFilePath)
        ccFileUtils:renameFile(szBackUpFilePath, szFilePath)
        GMHelper.ShowNormalTip("confighttp.ini 已恢复原始文件, 请重启游戏")
    else
        GMHelper.ShowNormalTip("confighttp.ini备份文件不存在,无法还原")
    end
end

-- 查看confighttpfile.ini
function GMHelper.ViewConfigHttp()
    -- 先判断是否已经在UIRuleTab中添加对应显示规则
    local szFullPath = _getFullPath(CONFIG_HTTP_FILE)
    if Lib.IsFileExist(szFullPath) then
        local szText = Lib.GetStringFromFile(szFullPath)
        if not GMHelper.nRuleID then
            -- 在现有规则数量上+1
            GMHelper.nRuleID = table.maxn(UIRuleTab) + 1
        end
        UIRuleTab[GMHelper.nRuleID] =
        {
            ["ID"]=GMHelper.nRuleID,
            ["szDesc1"]=szText,
            ["szTitle"]="confighttpfile.ini",
            ["nPrefabID1"]=5124,
        }
        Event.Dispatch(EventType.HideAllHoverTips)
        UIMgr.Open(VIEW_ID.PanelHelpPop, GMHelper.nRuleID)
    else
        -- 文件不存在提醒
        GMHelper.ShowNormalTip("confighttpfile.ini 不存在")
    end
end

function GMHelper.LoadFile(filePath)
    local szFullPath = _getFullPath(filePath)
    LOG.INFO("[GM] [GMHelper] to load file: %s begin", szFullPath)
    if ccFileUtils:isFileExist(szFullPath) then
        local fileContent = ccFileUtils:getStringFromFile(szFullPath)
        local chunk = loadstring(fileContent)  -- Lua5.1
        if chunk then
            LOG.INFO("[GM] [GMHelper] load file: %s end SUCCESS", szFullPath)
            return chunk()
        end
    end
    LOG.INFO("[GM] [GMHelper] load file: %s end false", szFullPath)
    return false
end

-- 下载某个文件
function GMHelper.DownloadFile(szKey, szURL, szFileName, fileExistHandler)
    local szFullPath = _getFullPath(szFileName)
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
    self.szTempFileName = string.format("%s.download", GetFullPath(szFileName))
    LOG.INFO("[GM] [GMHelper] Preparing to download %s to %s", szURL, self.szTempFileName)
    -- 先下载为临时文件,等判断下载成功后再改为正式文件名
    CURL_DownloadFile(szKey, szURL, self.szTempFileName, true, 120)
end

-- 版本列表下载成功
function GMHelper.OnVersionListDownloaded(bSuccess)
    if bSuccess then
        LOG.INFO("[GMHelper] OnVersionListDownloaded successed.")
        -- 下载成功后把临时文件名改为正式文件名
        local szFileName = string.gsub(self.szTempFileName, "%.download$", "")
        ccFileUtils:renameFile(self.szTempFileName, szFileName)
        self.szTempFileName = nil
        -- 重新下载判断
        self.bReDownload  = self.IsReDownload()
        local szTempFileName = "filelist.lua"
        -- 获取版本号后就可以下载fileslist
        self.DownloadFile(HTTP_DOWNLOAD_FILELIST_KEY, _getUrl(szTempFileName, self.tClientInfo.branch, self.nGMVersion), FILE_LIST_PATH)
    else
        LOG.INFO("[GM] [GMHelper] OnVersionListDownloaded failed.")
    end
end

-- 文件列表下载成功
function GMHelper.OnFileListDownloaded(bSuccess)
    if bSuccess then
        LOG.INFO("[GM] [GMHelper] OnFileListDownloaded successed.")
        -- 下载成功后把临时文件名改为正式文件名
        local szFileName = string.gsub(self.szTempFileName, "%.download$", "")
        LOG.INFO("[GM] [GMHelper] OnFileListDownloaded, %s to %s", self.szTempFileName, szFileName)
        ccFileUtils:renameFile(self.szTempFileName, szFileName)
        self.szTempFileName = nil
        self.tbFileList = self.LoadFile(FILE_LIST_PATH)
        if not self.tbFileList then
            LOG.INFO("[GM] [GMHelper] OnFileListDownloaded, local filelist not exists.")
            self.bProcessing = false
            return
        end
        if #self.tbFileList == 0 then
            LOG.INFO("[GM] [GMHelper] OnFileListDownloaded, filelist is empty.")
            self.bProcessing = false
            return
        end

        szFileName = table.remove(self.tbFileList)
        self.szDownloadingFilePath = szFileName
        self.DownloadFile(HTTP_DOWNLOAD_FILE_KEY, _getUrl(szFileName, self.tClientInfo.branch, self.nGMVersion), szFileName, function() self.OnFileDownloaded(true, true) end)
    else
        LOG.INFO("[GMHelper] OnFileListDownloaded failed.")
    end
end

-- 文件下载成功（注意，下载下来的是加密文件）
function GMHelper.OnFileDownloaded(bSuccess, bFileIsExist)
    if bFileIsExist then
        -- bFileIsExist 在本文件中只有在判断不用重下的情况下才会传入
        LOG.INFO("[GM] [GMHelper] OnFileDownloaded %s, file is exist, no need download.", self.szDownloadingFilePath)
    else
        if bSuccess then
            LOG.INFO("[GM] [GMHelper] OnFileDownloaded %s, successed.", self.szDownloadingFilePath)
            local szFileName = string.gsub(self.szTempFileName, "%.download$", "")
            ccFileUtils:renameFile(self.szTempFileName, szFileName)
            self.szTempFileName = nil

            LOG.INFO("[GM] [GMHelper] OnFileDownloaded Success %s rename %s ", self.szDownloadingFilePath, szFileName)
        else
            LOG.INFO("[GM] [GMHelper] OnFileDownloaded %s, failed.", self.szDownloadingFilePath)
        end
    end

    local szFileName = table.remove(self.tbFileList)
    if szFileName then
        self.szDownloadingFilePath = szFileName
        local nowWantToGet = _getUrl(szFileName, self.tClientInfo.branch, self.nGMVersion)

        self.DownloadFile(HTTP_DOWNLOAD_FILE_KEY, nowWantToGet, szFileName, function() self.OnFileDownloaded(true, true) end)
    else
        self.OnAllFileDownloaded()
    end
end

function GMHelper.OnAllFileDownloaded()
    LOG.INFO("[GMHelper] OnAllFileDownloaded.")
    self.bAllFileDownloaded = true
    self.bProcessing = false
    self.bReDownload = false
    --全部下载完成后记录GM版本和本次启动的行为
    local szFullPath = _getFullPath(GM_VERSION_FILE)
    local szBehaviorFile = _getFullPath(BEHAVIOR_FILE)
    ccFileUtils:writeStringToFile(self.nGMVersion, szFullPath)
    local szCurrentContent = Lib.GetStringFromFile(szBehaviorFile)
    local szContent = string.format("%s\t%s",tostring(szCurrentContent), tostring(self.nGMVersion))
    ccFileUtils:writeStringToFile(szContent, szBehaviorFile)
end

-- 获取满足条件的版本号
function GMHelper.GetMatchedVersion(szResourceVersion)
    local tVersionList = {}
    local szFullPath = _getFullPath(VERSION_LIST_PATH)
    if ccFileUtils:isFileExist(szFullPath) then
        local fileContent = ccFileUtils:getStringFromFile(szFullPath)
        for line in string.gmatch(fileContent, "[^\r\n]+") do
            line = string.gsub(line, '[\r\n]+', '')
            local nVersion = tonumber(line)
            table.insert(tVersionList, nVersion)
        end
    end
    table.sort(tVersionList)
    local nResourceVersion = tonumber(szResourceVersion)
    for index = #tVersionList, 1, -1 do
        if nResourceVersion==ETG_UPDATE then
            return tostring(tVersionList[index])
        elseif tVersionList[index] <= nResourceVersion then
            return tostring(tVersionList[index])
        end
    end
    LOG.INFO("[GMHelper] Not Find Match Version GM, Default use %s.", GM_DEBUG_VERSION)
    return GM_DEBUG_VERSION
end

-- 重新下载判断
function GMHelper.IsReDownload()
    local bVersionCompare = self.GMVersionCheck()
    -- 暂时只要出现需要重下就全部重下
    return bVersionCompare or self.GMFilesListCheck()
end

-- GMversion.txt 版本号比较
function GMHelper.GMVersionCheck()
    local szFullPath = _getFullPath(GM_VERSION_FILE)
    local szLocalVersion =  Lib.GetStringFromFile(szFullPath)
    -- 调试版本GM直接每次都重下
    if szLocalVersion == GM_DEBUG_VERSION then
        self.nGMVersion = GM_DEBUG_VERSION
        LOG.INFO(string.format("[GM] [GMHelper] LocalVersion is: %s, return true", szLocalVersion))
        return true
    else
        local szResourceVersion = GetPakV5Version() or ETG_UPDATE
        local szMatchVersion = self.GetMatchedVersion(szResourceVersion)
        self.nGMVersion = szMatchVersion
        LOG.INFO("[GM] [GMHelper] LocalVersion is: %s", szLocalVersion or "nil")
        LOG.INFO("[GM] [GMHelper] szMatchVersion is: %s", szMatchVersion or "nil")
        local bRecode = szLocalVersion ~= szMatchVersion
        LOG.INFO("[GM] [GMHelper] LocalVersion is: %s", tostring(bRecode))
        return bRecode
    end
end

-- GM相关文件, 本地完整性检测
function GMHelper.GMFilesListCheck()
    local tbFileList = self.LoadFile(FILE_LIST_PATH)
    if not tbFileList then
        LOG.INFO("[GM] [GMHelper] local GM filelist not exists, need redownload.")
        return true
    end
    if #tbFileList == 0 then
        LOG.INFO("[GM] [GMHelper] local GM filelist is empty, need redownload.")
        return true
    end

    for _, filepath in ipairs(tbFileList) do
        local szFullPath = _getFullPath(filepath)
        if not ccFileUtils:isFileExist(szFullPath) then
            LOG.INFO("[GM] [GMHelper] File integrity check false, file not exists, %s need redownload.", szFullPath)
            return true
        end
    end
    LOG.INFO("[GM] [GMHelper] File integrity check true, not need redownload.")
    return false
end


function GMHelper.SetDebug()
    self.bReDownload = true
    self.nGMVersion = GM_DEBUG_VERSION
    local szFullPath = _getFullPath(GM_VERSION_FILE)
    ccFileUtils:writeStringToFile(GM_DEBUG_VERSION, szFullPath)
    GMHelper.ShowNormalTip("GM设置为Debug模式, 请重启游戏...")
    LOG.INFO("[GM] [GMHelper] SetDebug ok, please reboot the game.")
end

function GMHelper.CancelDebug()
    self.bReDownload = true
    local szFullPath = _getFullPath(GM_VERSION_FILE)
    ccFileUtils:writeStringToFile(0, szFullPath)
    GMHelper.ShowNormalTip("GM设置为正常模式, 请重启游戏...")
    LOG.INFO("[GM] [GMHelper] CancelDebug ok, please reboot the game.")
end

GMHelper.UIConfig= {
    GmDevLogin= 1,
    CDN = 2,
    Etag = 3,
    FileOperation = 4
}

GMHelper.OPTION_FILTER_TYPE =
{
    default = 1,
    [2] = "gmdevlogin",
    [3] = "gm",
    [4] = "devlogin"
}

GMHelper.URL_FILTER_TYPE =
{
    intranet = 1, -- 内网
    extranet = 2, -- 外网
}

-- confighttpfile.ini 操作
GMHelper.FILE_OPERAtE =
{
    default = 1, -- 默认无操作
    view = 2, -- 查看文件
    delete = 3, --删除文件
    backup = 4, -- 备份文件
    restore = 5, -- 通过备份恢复
}

-- 自定义etag字段操作
GMHelper.CUSTOM_FIELDS =
{
    default = 1,
    update = 2,
    delete   = 3
}
