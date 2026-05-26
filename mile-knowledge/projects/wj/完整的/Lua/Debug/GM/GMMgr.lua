-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: GMMgr
-- Date: 2022-11-07 20:10:54
-- Desc: ?
-- ---------------------------------------------------------------------------------

GMMgr = GMMgr or {className = "GMMgr"}
local self = GMMgr

local ChineseDictionary = nil
local _getFullPath = function(filepath) return Platform.IsMac() and filepath or GetFullPath(filepath) end
if Config.bGM then
    ChineseDictionary = require("Lua/Debug/GM/ChineseDictionary.lua")
    require("Lua/Debug/GM/GMCMD.lua")
    require("Lua/Debug/GM/SearchMap.lua")
    require("Lua/Debug/GM/SearchItem.lua")
    require("Lua/Debug/GM/SearchQuest.lua")
    require("Lua/Debug/GM/SearchItemWeapon.lua")
    require("Lua/Debug/GM/SearchNPC.lua")
    require("Lua/Debug/GM/SearchItemArmor.lua")
    require("Lua/Debug/GM/SearchDoodad.lua")
    require("Lua/Debug/GM/SearchItemTrinket.lua")
    require("Lua/Debug/GM/SearchSkill.lua")
    require("Lua/Debug/GM/SearchExterior.lua")
    require("Lua/Debug/GM/SearchHair.lua")
    require("Lua/Debug/GM/GetPoints.lua")
    require("Lua/Debug/GM/SearchBuff.lua")
    require("Lua/Debug/GM/SearchCraft.lua")
    require("Lua/Debug/GM/SearchBook.lua")
    require("Lua/Debug/GM/SearchActivity.lua")
    require("Lua/Debug/GM/BuffDebugFrame.lua")
    require("Lua/Debug/GM/SearchHomelandItem.lua")
    require("Lua/Debug/GM/ConfigureAccount.lua")
    require("Lua/Debug/GM/SearchPanel/IniFile.lua")
    require("Lua/Debug/GM/SearchPanel/SearchPanel.lua")
    require("Lua/Debug/GM/SearchRobot.lua")

    GMMgr.tMiddleCMd = {
        {tbCellLeft = SearchMap, tbCellRight = SearchItem},
        {tbCellLeft = SearchQuest, tbCellRight = SearchItemWeapon},
        {tbCellLeft = SearchNPC, tbCellRight = SearchItemArmor},
        {tbCellLeft = SearchDoodad, tbCellRight = SearchItemTrinket},
        {tbCellLeft = SearchExterior, tbCellRight = SearchSkill},
        {tbCellLeft = SearchHair, tbCellRight = SearchBuff},
        {tbCellLeft = SearchCraft, tbCellRight = SearchBook},
        {tbCellLeft = SearchActivity,tbCellRight = BuffDebugFrame},
        {tbCellLeft = GetPoints, tbCellRight = SearchHomelandItem},
        {tbCellLeft = ConfigureAccount, tbCellRight = SearchRobot}
    }
end



GMMgr.tbLastGMPanel = {}
GMMgr.LevelUpData = {}

function GMMgr.DelayCall(nTime, fnCallBack, ...)
    local args = {...} -- 将不定参数存储在一个表中
    local fnDelayCallBack = function ()
        -- unpack Lua 5.1有效,更高版本使用table.unpack(args)
        fnCallBack(unpack(args))
    end
    Timer.Add(self, nTime, fnDelayCallBack)
end

function GMMgr.GetLeftData(szSearchKey)
    if not szSearchKey or szSearchKey == nil or szSearchKey == '' then
        return tGMCMD or {}
    end

    local tSearchCMD = {}
    for _, tCMD in pairs(tGMCMD) do
        if string.find(tCMD.text, szSearchKey) or string.find(tCMD.pattern, szSearchKey) then
            table.insert(tSearchCMD, tCMD)
        end
    end
    return tSearchCMD
end

function GMMgr.GetMiddleData()
    -- 这里要自己解析ini文件获取需要显示的文本
    return GMMgr.tMiddleCMd or {}
end

--创建缓存表
GMMgr.tNameSet = GMMgr.tNameSet or {}

local function GeneratePinyinTable(tNames)
    GMMgr.tPinyinCache = GMMgr.tPinyinCache or {}
    local utf8_char_pattern = "[%z\1-\127\194-\244][\128-\191]*"

    for _, name in ipairs(tNames) do
        if type(name) ~= "string" or name == "" then
            LOG.INFO("Invalid name encountered: ", name)
        else
            if not GMMgr.tNameSet[name] then
                GMMgr.tNameSet[name] = true
                local szAllPinyin = ''
                local szInitials = ''
                for char in name:gmatch(utf8_char_pattern) do
                    local pinyin = GMMgr.HanziToPinyin[char]
                    if pinyin then
                        szAllPinyin = szAllPinyin .. pinyin
                        szInitials = szInitials .. pinyin:sub(1, 1)
                    end
                end
                GMMgr.tPinyinCache[name] = {Initials = szInitials, AllPinyin = szAllPinyin}
            end
        end
    end
    return GMMgr.tPinyinCache
end

-- 返回所有搜索到的汉字
local function SearchPinyin(tChineseToPinyinCache, szSearchKey)
    local tChinese = {}
    local bFoundWithInitials = false

    for key, value in pairs(tChineseToPinyinCache) do
        if string.find(value.Initials, szSearchKey) then
            bFoundWithInitials = true
            table.insert(tChinese, key)
        end
    end

    if not bFoundWithInitials then
        for key, value in pairs(tChineseToPinyinCache) do
            if string.find(value.AllPinyin, szSearchKey) then
                table.insert(tChinese, key)
            end
        end
    end
    return tChinese
end

-- 检查是否是纯英文字符,忽略前导和尾部的空白字符
local function IsEnglishInput(szSearchKey)
    if type(szSearchKey) ~= "string" then
        return false
    end
    szSearchKey = szSearchKey:match("^%s*(.-)%s*$") -- 删除前后空白字符
    local match = szSearchKey:match("^[a-zA-Z]+$")
    return match ~= nil
end

--在函数外创建,避免在函数内反复生成影响效率
local tNameList = {} -- 名称列表
local tNameToDataMap = {} -- 名称到数据的映射
local lastTempRightTable = nil
function GMMgr.ClearCache()
    tNameList = {}
    tNameToDataMap = {}
    GMMgr.tNameSet = {}
    GMMgr.tPinyinCache = {}
    lastTempRightTable = nil
end

GMMgr.CacheManager = {
    caches = {}
}

function GMMgr.CacheManager:GetCache(tNames)
    local key = #tNames
    for i, name in ipairs(tNames) do
        key = key .. name
        if i >= 3 then break end
    end
    if not self.caches[key] then
        self.caches[key] = GeneratePinyinTable(tNames)
    end
    return self.caches[key]
end

function GMMgr.GetRightData(szSearchKey, tTempRightTable)
    if lastTempRightTable ~= tTempRightTable then
        GMMgr.ClearCache()
        lastTempRightTable = tTempRightTable
    end
    if not szSearchKey or szSearchKey == '' then
        return tTempRightTable
    end
    if IsEnglishInput(szSearchKey) then
        local lowerSearchKey = string.lower(szSearchKey)
        if next(tNameList) == nil and next(tNameToDataMap) == nil then
            for _, tData in pairs(tTempRightTable) do
                local szDataName = UIHelper.GBKToUTF8(tData.Name)
                if not szDataName then
                    error("szDataName is nil for tData: " .. tostring(tData))
                else
                    if not tNameToDataMap[szDataName] then
                        table.insert(tNameList, szDataName)
                        tNameToDataMap[szDataName] = tData
                    end
                end
            end
        end
        local tChineseToPinyin = GMMgr.CacheManager:GetCache(tNameList)
        local tChinese = SearchPinyin(tChineseToPinyin, lowerSearchKey)
        table.sort(tChinese, function(a, b) return #a < #b end)
        local tSearchTable = {}
        for _, name in ipairs(tChinese) do
            if tNameToDataMap[name] then
                table.insert(tSearchTable, tNameToDataMap[name])
            end
        end
    return tSearchTable
    else
        local tSearchTable = {}
        local bMultipleIndex = false
        for _, tData in pairs(tTempRightTable) do
            local szDataName = UIHelper.GBKToUTF8(tData.Name)
            if tData.ID == tonumber(szSearchKey) then
                table.insert(tSearchTable, tData)
                bMultipleIndex = true
                -- break
            elseif szDataName and string.find(szDataName, szSearchKey) then
                table.insert(tSearchTable, tData)
            else
                if bMultipleIndex then
                    break
                end
            end
        end
        return tSearchTable
    end
end

local function GetReloadWhiteList()
    local szFullPath = _getFullPath("mui/Lua/Debug/GM/GMReloadWhiteList.txt")
    local szPermissionAccount =  Lib.GetStringFromFile(szFullPath)
    local tbReloadWhiteList = {}
    if szPermissionAccount then
        for line in string.gmatch(szPermissionAccount, "[^\r\n]+") do
            line = string.gsub(line, '[\r\n]+', '')
            tbReloadWhiteList[line]=true
        end
    end
    return tbReloadWhiteList
end

function GMMgr.Init()
    Timer.AddFrame(self, 1, function()
        GMMgr.OnUpdate()
    end)
    GMMgr.ReloadWhiteList = GetReloadWhiteList() or {}
    local szConFullPath = GetFullPath("mui/ConWithPy.lua")
    LOG.INFO("通信模块："..szConFullPath)
    local fileUtils = cc.FileUtils:getInstance()
    if fileUtils:isFileExist(szConFullPath) then
        if not AutoTestEnv then
            require("Lua/Debug/GM/AutoTest/AutoTestEnv.lua")
            self.runBotTimer = Timer.AddCycle(self, 2, function()
                if AutoTestBot then
                    require("ConWithPy.lua")
                    ConWithPy.Init()
                    GMMgr.szDeviceID = ConWithPy.szDeviceID
                    LOG.INFO("设备id："..GMMgr.szDeviceID)
                    GMMgr.tRet = nil
                    Timer.DelTimer(self, self.runBotTimer)
                    self.runBotTimer = nil
                end
            end)
        end
    end
end

function GMMgr.UnInit()

end

GMMgr.HanziToPinyin = {}
function GMMgr.OnUpdate()
    local utf8_char_pattern = "[%z\1-\127\194-\244][\128-\191]*"
    for pinyin, hanziStr in pairs(ChineseDictionary) do
        if hanziStr == nil or hanziStr == '' then
            LOG.INFO("错误: 对于拼音 " .. pinyin .. " 没有找到对应的汉字字符串")
        else
            for char in hanziStr:gmatch(utf8_char_pattern) do
                GMMgr.HanziToPinyin[char] = pinyin
            end
        end
    end
end

function _MsgError(msg)
    LOG.ERROR("----------------------------------------")
    LOG.ERROR("LUA ERROR: " .. tostring(msg) .. "\n")
    LOG.ERROR(debug.traceback())
    LOG.ERROR("----------------------------------------")
end

local function MatchInstructionPrefix(szCMD)
    local szStandard =  string.gsub(szCMD, "^%s*", "")
    local szNewCMD = string.gsub(szStandard, "^/[Gg]?[Mm]?%s*", "")
    return szNewCMD
end

-- Reload相关指令关键字列表
local tReloadKeyList = {
        "ReloadAllScripts",
        "ReloadScripts",
        "ReloadOtherItemTab",
        "ReloadNpcTemplate",
        "ReloadDoodadTemplate",
        "ReloadAllSkill",
        "ReloadAllBuff",
        "ReloadChatServerScript",
        "ReloadCoolDown"
    }

function GMMgr.ExecuteGMCommand(szText, szCMD, szType)
    local szStandardCMD = UIHelper.UTF8ToGBK(MatchInstructionPrefix(szCMD))
    local function ExecuteGMCommand()
        if szType == "GM" then
            SendGMCommand(szStandardCMD)
        else
            local fun = loadstring(szStandardCMD)
            setfenv(fun, _G)
            if fun then
                xpcall(fun, _MsgError)
            end
        end
    end

    -- 先判断reload关键字，减少不必要的字符串查找
    local bNeedConfirm = false
    if szStandardCMD:lower():find("reload") then
        for _, szKey in ipairs(tReloadKeyList) do
            if szStandardCMD:lower():find(szKey:lower()) then
                bNeedConfirm = true
                break
            end
        end
    end
    if bNeedConfirm then
        reloadScriptConfirm(ExecuteGMCommand, szText)
    else
        ExecuteGMCommand()
    end
end

function GMMgr.LoadTabList(szClientPath,szFilePath,hasDefault,tabRowNeed)
    local szClientPath = szClientPath or ""
    local tTotalTab = GMMgr.LoadFile(szClientPath,szFilePath)    --加载LIST表
    local tProcessTab = {}
    local tDefaultTab = nil
    local beNotSetIndex = true

    for i,v in ipairs(tTotalTab) do
        local tSubTabFile = {}
        local filePath = v.FilePath
        if i == 1 and hasDefault then
            tDefaultTab = GMMgr.LoadFile(szClientPath,filePath,tabRowNeed)        --加载默认表
        else
            --默认值为一个tabFile或者false
            if hasDefault then
                tSubTabFile = GMMgr.LoadFile(szClientPath,filePath,tabRowNeed)    --设置默认值    ,此时的tSubTabFile 是userdata;
                local tDefaultValue = tDefaultTab[1]
                tDefaultValue.__index = tDefaultValue
                for i = 1, #tSubTabFile do
                    local row = tSubTabFile[i]
                    for header,value  in pairs(row) do
                        if row[header] == "" then
                            row[header] = nil
                        end
                    end
                    setmetatable(row, tDefaultValue)    --设置元表,为空时返回元表内容
                end
            else
                tSubTabFile =  GMMgr.LoadFile(szClientPath,filePath,tabRowNeed) --没有默认值时
            end

            for i,j in pairs(tSubTabFile) do
                if i == "tIndexTable" then
                    if beNotSetIndex then
                        tProcessTab.tIndexTable = j
                        beNotSetIndex = false
                    end
                else
                    table.insert(tProcessTab,j)
                end
            end
        end
    end
    return tProcessTab
end

function GMMgr.LoadFile(szClientPath, szFilePath, tabRowNeed, hasDefault)
    local szFileDir = szClientPath..szFilePath
    local self = {}
    self.tIndexTable = {}
    local bPak
    if Lib.IsFileExist(szFileDir) then
        bPak = false
    else
        bPak = true
    end
    if bPak then
        local file_string = LoadDataFromFile(szFileDir, bPak) --二进制字符串,windows 换行就是\r\n,linux 是\n,io的读取会自动帮你处理;
        local file_tab = GMMgr.ParseFromString(file_string)
        if file_tab then
            self.tIndexTable = file_tab[1] --表头
        end
    else
        local text = Lib.GetStringFromFile(szFileDir)
        if not text then
            OutputMessage("MSG_ANNOUNCE_NORMAL", "<open file : [" .. UIHelper.GBKToUTF8(szFileDir) .. "] failed>")
            return;
        end
        local strList = string.split(text, "\r\n")
        for _, szLine in ipairs(strList) do
            self.tIndexTable = GMMgr.Tab_SetIndex(szLine)
            break
        end

    end
    local tBaseTabHead = {
        Path = szFilePath,
        Title = {},
        }

    for index,keyName in ipairs(self.tIndexTable) do
        table.insert(tBaseTabHead.Title,{f = "s", t = keyName})
    end

    local mode = TABLE_FILE_OPEN_MODE.DEFAULT
	if hasDefault then
		mode = TABLE_FILE_OPEN_MODE.NORMAL
	end

	local tBaseTab = KG_Table.Load(tBaseTabHead.Path, tBaseTabHead.Title, mode) --TABLE_FILE_OPEN_MODE.NORMAL
    if tBaseTab == nil then
        Output("LoadFile",szFilePath)
    end

    for i = 1, tBaseTab:GetRowCount() do
        local row = tBaseTab:GetRow(i)
        self[i] = {}
        if tabRowNeed then
            for k, v in pairs(tabRowNeed) do
                self[i][v] = row[v]
            end
        else
            self[i] = row
        end
    end
    return self
end

function GMMgr.StringSpliter(szWords, szSpliter)
    --迭代器,切分字符串
    local state = {
        words = szWords or "",
        count = 0,
        startpos = 0,
        endpos = 0,
        spliter = szSpliter or ","
    }
    state.words = state.words .. state.spliter
    local function iter()
        local bFoundSpliter = false
        state.count = state.count + 1
        bFoundSpliter, state.endpos = state.words:find(state.spliter, state.startpos)
        if bFoundSpliter then        -- 找到了分隔符
            local szSplited = state.words:sub(state.startpos, state.endpos - #state.spliter)
            state.startpos = state.endpos + 1
            return state.count, szSplited
        end
    end

    return iter
end

function GMMgr.Tab_SetIndex(szLine) --传进来一行数据,从里面分割出各列组成表头,返回值是table;
    local tIndexTable = {}
    local szTableSpliter = "\t"

    for k, v in GMMgr.StringSpliter(szLine, szTableSpliter) do
        tIndexTable[k] = v
    end
    return tIndexTable
end

function GMMgr.GetRowCount(fileTab)
    return #fileTab
end

function GMMgr.GetRow(fileTab,i)
    local tRow = {}
    if fileTab[i] then
        tRow = fileTab[i]
    end
    return tRow
end

function GMMgr.Search(fileTab,keyName,expValue,bFuzzySearch)
    if not fileTab and not keyName and not expValue then
        OutputMessage("MSG_SYS","[GMMgr]待查询的原表,表头和预期值参数不全,无法查询结果!\n")
        return nil
    end
    for index,data in pairs(fileTab) do
        local curValue = UIHelper.GBKToUTF8(data[keyName])
        if not curValue then
            return nil
        end
        if type(expValue) == "number" then
            curValue = tonumber(curValue)
        end
        if not bFuzzySearch then
            if curValue == expValue then
                return data
            end
        else
            if string.lower(curValue) == string.lower(expValue) then
                return data
            end
        end
    end
    return nil
end

function GMMgr.GetLevelUpData_New(nRoleType,Level)
    local tFile = GMMgr.LevelUpData[nRoleType] or {}
    if tFile[1] then
        for index,data in pairs(tFile) do
            if tonumber(data.Level) == Level then
                return data
            end
        end
    end
    return nil
end


function GMMgr.LevelUpData_Load(roleType)
    if not GMMgr.LevelUpData then
        GMMgr.LevelUpData = {}
    end
    if not GMMgr.LevelUpData[roleType] then
        local tLevelUpDataFile = {
            [1]="settings\\LevelUpData\\StandardMale.tab", --PAK需要拷贝的表
            [2]="settings\\LevelUpData\\StandardFemale.tab", --PAK需要拷贝的表
            [3]="settings\\LevelUpData\\StrongMale.tab", --PAK需要拷贝的表
            [4]="settings\\LevelUpData\\SexyFemale.tab", --PAK需要拷贝的表
            [5]="settings\\LevelUpData\\LittleBoy.tab", --PAK需要拷贝的表
            [6]="settings\\LevelUpData\\LittleGirl.tab", --PAK需要拷贝的表
        }
        if not tLevelUpDataFile[roleType] then
            OutputMessage("MSG_SYS","[GMMgr] tLevelUpDataFile没有当前体型信息,请维护插件!\n")
        else
            local start_time = GetTickCount()
            local old_memory = collectgarbage("count") --获取加载完成时的内存信息

            local index_temp_LevelUpData = {"Level","Experience"}
            GMMgr.LevelUpData[roleType] = GMMgr.LoadFile("",tLevelUpDataFile[roleType],index_temp_LevelUpData,true)

            local end_time = GetTickCount()
            local dif_time = end_time - start_time
            local new_memory = collectgarbage("count") --获取加载完成时的内存信息
            local dif_memory = string.format("%.2f",(new_memory - old_memory)/1024)
            OutputMessage("MSG_SYS","[GMMgr] loadFile LevelUpData,耗时"..dif_time.."毫秒!内存变化"..dif_memory.."MB\n")
        end
    end
end

function GMMgr.ReadTabFile(filePath)
    local fileContent = Lib.GetStringFromFile(filePath)
    local tabTable = {}
    local indexTable = {}  -- 列标题
    local lines = string.split(fileContent, "\n")
    local indexLine = lines[1]
    indexTable = string.split(indexLine, "\t")

    for i = 2, #lines do
        local line = lines[i]
        if line ~= "" then
            local rowData = string.split(line, "\t")
            local rowDataObj = {}
            for j = 1, #indexTable do
                rowDataObj[indexTable[j]] = rowData[j]
            end
            table.insert(tabTable, rowDataObj)
        end
    end

    return tabTable
end

function GMMgr.Recipe_Load()
	if not GMMgr.Recipe then
		-- local start_time = GetTickCount()
		-- local old_memory = collectgarbage("count") --获取加载完成时的内存信息
		local index_temp_Recipe = {"RecipeID","BelongSchool","RecipeLevel","Type"} --,"RecipeName"
		GMMgr.Recipe = GMMgr.LoadFile("","settings\\skill_mobile\\recipeSkill.tab",index_temp_Recipe,true)
		-- local end_time = GetTickCount()
		-- local dif_time = end_time - start_time
		-- local new_memory = collectgarbage("count") --获取加载完成时的内存信息
		-- local dif_memory = string.format("%.2f",(new_memory - old_memory)/1024)
--~ 		OutputMessage("MSG_SYS","★[GMMgr]★ loadFile Recipe!\n")
		--OutputMessage("MSG_SYS","★[GMMgr]★ loadFile Recipe,耗时"..dif_time.."毫秒!内存变化"..dif_memory.."MB\n")
	end
end


function GMMgr.SearchRecipe(MountSkillID,Type)
	local MountSkill
	if not _G.bClassic then
		MountSkill = {[1]="少林",[2]="万花",[3]="天策",[4]="纯阳",[5]="七秀",[6]="五毒",[7]="唐门",[8]="藏剑",[9]="丐帮",[10]="明教",[21]="苍云",[22]="长歌",[23]="霸刀",[24]="蓬莱",[25]="凌雪阁",[211]="衍天宗",[212]="北天药宗",[213]="刀宗",[214]="万灵山庄",[215]="大理段氏"} --新出门派需要维护
	else
		MountSkill = {[1]="少林",[2]="万花",[3]="天策",[4]="纯阳",[5]="七秀",} --[6]="五毒",[7]="唐门",[8]="藏剑",[9]="丐帮",[10]="明教",[21]="苍云",[22]="长歌",[23]="霸刀",[24]="蓬莱",[25]="凌雪阁",[211]="衍天宗"} --新出门派需要维护
	end
	local Recipetab = {}
	--local index_temp_Recipe = {"RecipeID","BelongSchool","RecipeLevel"} --"RecipeName"
	if not GMMgr.Recipe then
		GMMgr.Recipe_Load() --s-----------实现使用时即时加载表,表较大会卡一下
	end
	for i,v in ipairs(GMMgr.Recipe) do
		local bNeed = true
		if Type and tonumber(v.Type) ~= Type then
			bNeed = false
		end
		if v.BelongSchool == MountSkill[MountSkillID] and bNeed then
			table.insert(Recipetab,v)
		end
	end
	return Recipetab
end