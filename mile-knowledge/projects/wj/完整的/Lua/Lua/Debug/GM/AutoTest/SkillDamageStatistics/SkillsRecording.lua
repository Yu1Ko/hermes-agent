require("Lua/Debug/GM/AutoTest/AutoTestEnv.lua")

SkillsRecording =  SkillsRecording or {className = "SkillsRecording"}

SkillsRecording.tVersionCheck =  {
    download = "http://bot.xgame.work:8285/autotest/SkillDamageStatistics/version.txt",
    backup = "./mui/Lua/AutoBot/SkillDamageStatistics/version.txt",
}

SkillsRecording.tDownLoad = {
    UIWidgetNormalSkill = {
        download = "http://bot.xgame.work:8285/autotest/SkillDamageStatistics/UIWidgetNormalSkill.lua",
        backup = "./mui/Lua/UI/MainCity/UIWidgetNormalSkill.lua",
    }
}

SkillsRecording.tBackUp = {
    UIWidgetNormalSkill = "./mui/Lua/UI/MainCity/UIWidgetNormalSkill.lua"
}

SkillsRecording.tRecordList = {}

local function WriteTab(tSkillCast, szFileName)
    -- 遍历表数据并写入文件
    local szContext = "ID\tnSkillID\tnSkillLevel\tDurationTime(s)\tnCastTime(ms)\n备注：序号\t技能ID\t技能等级\t按压持续时间(秒)\t技能释放之间的间隔(毫秒)\n"
    for key, value in ipairs(tSkillCast) do
        local line = string.format("%d\t%d\t%d\t%f\t%d\n", key, value.nSkillID, value.nSkillLevel, value.nDurationTime, value.nNextCastTime)
        szContext = string.format("%s%s", szContext, line)
    end
    AutoTestEnv.FileWrite(szFileName, szContext)
end

local function Download(szURL, szFileName)
    -- 要判断下载目录是否存在，不在就先创建
    local fileUtil = cc.FileUtils:getInstance()
    local dirPath = string.sub(szFileName, 1, string.find(szFileName, "/[^/]*$"))
    if dirPath and dirPath ~= "" and not fileUtil:isDirectoryExist(dirPath) then
        fileUtil:createDirectory(dirPath)
    end
    CURL_DownloadFile("AutoTest", szURL, UIHelper.GBKToUTF8(GetFullPath(szFileName)), true, 120)
end

-- 备份原文件为了之后还原环境
local function Backup(sourceFile, destFile)
    local fileUtil = cc.FileUtils:getInstance()
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



function SkillsRecording:Init()
    UIMgr.Close(VIEW_ID.PanelGM)
    if self.bInit then
        UIMgr.Open(VIEW_ID.PanelSkillRecord)
        return
    end
    self:OnRegister()
    self.bInit = true
    self.bRecording = false
    CURL_HttpRqst("AutoTest_RecordVersion", "http://bot.xgame.work:8000/getRecordVersion", false, 10)
    self.tTempSkillInfo = nil
    self.tSkillCast = {}
    self.tSkillCastTest = {}
    UIMgr.Close(VIEW_ID.PanelGM)
    UIMgr.Open(VIEW_ID.PanelSkillRecord)
end

function SkillsRecording:_RecordVersionCheck(nRemoteVersion)
    local bCheckResult = AutoTestEnv.VersionCheck(self.tVersionCheck.download, self.tVersionCheck.backup, nRemoteVersion)
    if not bCheckResult then
        Download(self.tVersionCheck.download, self.tVersionCheck.backup)
        for key, value in pairs(SkillsRecording.tDownLoad) do
            local szSavePath = string.format("./mui/Lua/AutoBot/skilldamagestatistics/%s.lua", key)
            Download(value.download, szSavePath)
        end
    else
        for key, value in pairs(SkillsRecording.tDownLoad) do
            local szSavePath = string.format("./mui/Lua/AutoBot/skilldamagestatistics/%s.lua", key)
            if not Lib.IsFileExist(szSavePath) then
                Download(value.download, szSavePath)
            else
                LOG.INFO(string.format("%s has existed", szSavePath))
            end
        end
    end

    Timer.Add(SkillsRecording, 1, function()
        local bUIClosed = false
        if Platform.IsWindows() then
            if UIMgr.GetView(VIEW_ID.PanelMainCity) then
                UIMgr.Close(VIEW_ID.PanelMainCity)
                bUIClosed = true
            end
            Backup(self.tBackUp.UIWidgetNormalSkill, "./mui/Lua/AutoBot/backup/UIWidgetNormalSkill.lua")
        end
        for key, value in pairs(SkillsRecording.tDownLoad) do
            -- 这里会出现, 还没下载完就备份为空的情况
            Backup(string.format("./mui/Lua/AutoBot/skilldamagestatistics/%s.lua", key), value.backup)
        end
        -- PC上可以采用这种方式, 但手机上需要重启一次游戏才能挂包外
        if Platform.IsWindows() then
            ReloadScript.Reload("Lua/UI/MainCity/UIWidgetNormalSkill.lua")
            if bUIClosed then
                UIMgr.Open(VIEW_ID.PanelMainCity)
            end
        else
            OutputMessage("MSG_ANNOUNCE_YELLOW", "需要重启游戏, 如果已经重启请忽略")
        end
    end);
end

function SkillsRecording:Start()
    if self.bRecording then
        OutputMessage("MSG_ANNOUNCE_YELLOW", "正在录制, 请勿重复尝试")
        return
    end
    self.bRecording = true
    self.tSkillCast = {}
    OutputMessage("MSG_ANNOUNCE_YELLOW", "准备开始录制")
end

function SkillsRecording:ReStart()
    OutputMessage("MSG_ANNOUNCE_YELLOW", "重新录制")
    self.tTempSkillInfo = nil
    self.tSkillCast = {}
    self.tSkillCastTest = {}
end

function SkillsRecording:Save(szFileName)
    if not self.bInit then
        OutputMessage("MSG_ANNOUNCE_YELLOW", "还没初始化测试环境")
        return
    end

    if not self.bRecording then
        OutputMessage("MSG_ANNOUNCE_YELLOW", "还没开始录制")
        return
    end

    -- 最后一个释放的技能
    if self.tTempSkillInfo ~= nil then
        local tSkillInfo = {
            nNextCastTime = 0,
            nSkillID = self.tTempSkillInfo.nSkillID,
            nSkillLevel = self.tTempSkillInfo.nSkillLevel,
            nDurationTime = self.tTempSkillInfo.nDurationTime
        }
        table.insert(self.tSkillCast, tSkillInfo)
    end
    OutputMessage("MSG_ANNOUNCE_YELLOW", "结束录制并保存")
    self.bRecording = false
    self.tTempSkillInfo = nil
    self.tSkillCastTest = {}
    WriteTab(self.tSkillCast, string.format('./mui/Lua/AutoBot/SkillDamageStatistics/%s.tab', szFileName))
    AutoTestEnv.FileAdd("./mui/Lua/AutoBot/SkillDamageStatistics/SkillOrderList.txt", string.format("\n%s",szFileName))
end

function SkillsRecording:UnInit()
    if not self.bInit then
        OutputMessage("MSG_ANNOUNCE_YELLOW", "还没初始化测试环境")
        return
    end
    self.bInit = false

    self:Recovery()
    Timer.Add(SkillsRecording, 1, function()
        ReloadScript.Reload("Lua/UI/MainCity/UIWidgetNormalSkill.lua")
        if UIMgr.GetView(VIEW_ID.PanelMainCity) then
            UIMgr.Close(VIEW_ID.PanelMainCity)
            UIMgr.Open(VIEW_ID.PanelMainCity)
        end
    end);
    Event.UnRegAll(self)
end

function SkillsRecording:OnRegister()
    Event.Reg(self, "CURL_REQUEST_RESULT", function ()
        local szKey = arg0
		local bSuccess = arg1
		local szValue = arg2
        if szKey == "AutoTest_RecordVersion" and bSuccess then
			-- self.nRemoteVersion = tonumber(szValue)
            self:_RecordVersionCheck(tonumber(szValue))
        end
    end)

    Event.Reg(self, "IsCastSkill", function(nSkillID, nSkillLevel, nDurationTime)
        local nDurationTime = nDurationTime or 0
        if self.tTempSkillInfo == nil then
            self.tTempSkillInfo = {
                nCastTime = GetTickCount() - nDurationTime*1000,
                nSkillID = nSkillID,
                nSkillLevel = nSkillLevel,
                nDurationTime = nDurationTime
            }
            table.insert(self.tSkillCastTest, self.tTempSkillInfo)
        else
            local nCurTime = GetTickCount() - nDurationTime*1000
            local tSkillInfo = {
                nNextCastTime = nCurTime - self.tTempSkillInfo.nCastTime,
                nSkillID = self.tTempSkillInfo.nSkillID,
                nSkillLevel = self.tTempSkillInfo.nSkillLevel,
                nDurationTime = self.tTempSkillInfo.nDurationTime
            }
            table.insert(self.tSkillCast, tSkillInfo)
            self.tTempSkillInfo = {
                nCastTime = nCurTime,
                nSkillID = nSkillID,
                nSkillLevel = nSkillLevel,
                nDurationTime = nDurationTime or 0
            }
            table.insert(self.tSkillCastTest, self.tTempSkillInfo)
        end
    end)
end

-- 把备份的文件还原回去
function SkillsRecording:Recovery()
    if Platform.IsWindows() then
        for key, value in pairs(SkillsRecording.tBackUp) do
            Backup(string.format("./mui/Lua/AutoBot/backup/%s.lua", key), value)
        end
    else
        for key, value in pairs(SkillsRecording.tBackUp) do
            Lib.RemoveFile(GetFullPath(value))
        end
    end
end