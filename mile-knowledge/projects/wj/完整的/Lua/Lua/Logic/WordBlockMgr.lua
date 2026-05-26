-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: WordBlockMgr
-- Date: 2024-09-05 16:52:09
-- Desc: 文字屏蔽
-- ---------------------------------------------------------------------------------


-- 最大字符长度
local MAX_WORD_LEN = 10

-- 屏蔽词条最大可存储数目
local MAX_STORAGE_LEN = 20

-- 帮助提示
local STRING_TIPS = "聊天栏屏蔽：\n功能开启后，其他玩家发送的消息中包含你设置的屏蔽关键词，该消息将自动被过滤，你将无法在选定的聊天频道中看到这条消息。\n招募屏蔽：\n勾选了“屏蔽招募列表”的选项时，任何包含屏蔽关键词的招募信息将不会显示在你的招募列表中。"

-- 屏蔽字，聊天频道列表
local CHAT_BLOCK_CFG_LIST =
{
	{
		szKey = "Near",
		szName = "近聊频道",
		tbChannelIDs = {1},
        bDefaultSelect = true,
	},
	{
		szKey = "Map",
		szName = "地图频道",
		tbChannelIDs = {5},
        bDefaultSelect = true,
	},
	{
		szKey = "World",
		szName = "世界频道",
		tbChannelIDs = {32},
        bDefaultSelect = true,
	},
	{
		szKey = "Team",
		szName = "队伍频道",
		tbChannelIDs = {2},
        bDefaultSelect = false,
    },
	{
		szKey = "Raid",
		szName = "团队频道",
		tbChannelIDs = {3},
        bDefaultSelect = false,
	},
	{
		szKey = "Room",
		szName = "房间频道",
		tbChannelIDs = {50},
        bDefaultSelect = false,
	},
	{
		szKey = "Camp",
		szName = "阵营频道",
		tbChannelIDs = {34},
        bDefaultSelect = true,
	},
	{
		szKey = "Battle",
		szName = "战场频道",
		tbChannelIDs = {4},
        bDefaultSelect = false,
	},
	{
		szKey = "Force",
		szName = "门派频道",
		tbChannelIDs = {33},
        bDefaultSelect = true,
	},
	{
		szKey = "Tong",
		szName = "帮会频道",
		tbChannelIDs = {29,30,31},
        bDefaultSelect = false,
	},
	{
		szKey = "Identity",
		szName = "萌新频道",
		tbChannelIDs = {40},
        bDefaultSelect = false,
	},
	{
		szKey = "All",
		szName = "全服频道",
		tbChannelIDs = {49},
        bDefaultSelect = false,
	},
}

--[[
    存盘数据格式如下：
    Storage.WordBlock.tbWordBlockList =
    {
        [1] =
        {
            szWord = "屏蔽文字1",
            tbChatKeyList = {"Near", "Map", "World", "Team"},
            bRecruitBlock = false,
        },
        [2] =
        {
            szWord = "屏蔽文字2",
            tbChatKeyList = {"Near", "Team"},
            bRecruitBlock = false,
        },
    }
]]


WordBlockMgr = WordBlockMgr or {className = "WordBlockMgr"}
local self = WordBlockMgr

self.tbMapKeyToBlockCfg = {} -- Kye 对应某个配置 {["Near"] = CHAT_BLOCK_CFG_LIST[1]}
self.tbMapWordToStorage = {} -- Word 对应某个存储的配置 {["关键字1"] = Storage.WordBlock.tbWordBlockList[1]}
self.tbMapChannelToWord = {} -- 聊天频道ID和关键字 {[PLAYER_TALK_CHANNEL.NEARBY] = {"关键字1", "关键字2"}}
self.tbListRecruitWord  = {} -- 招募屏蔽文字列表


function WordBlockMgr.Init()
    for k, v in ipairs(CHAT_BLOCK_CFG_LIST) do
        self.tbMapKeyToBlockCfg[v.szKey] = v
    end

    self.InitData()
end

function WordBlockMgr.InitData()
    self.tbMapWordToStorage = {}
    self.tbMapChannelToWord = {}
    self.tbListRecruitWord = {}

    local tbStorageWordBlockList = WordBlockMgr.GetStorageList()
    for k, v in ipairs(tbStorageWordBlockList) do
        local szWord = v.szWord
        local tbChatKeyList = v.tbChatKeyList or {}
        local bRecruitBlock = v.bRecruitBlock

        self.tbMapWordToStorage[szWord] = v

        for _, szChatKey in ipairs(tbChatKeyList) do
            local tbCfg = WordBlockMgr.GetOneChatBlockCfg(szChatKey)
            local tbChannelIDs = tbCfg and tbCfg.tbChannelIDs or {}
            for _, nChannelID in ipairs(tbChannelIDs) do
                if not self.tbMapChannelToWord[nChannelID] then
                    self.tbMapChannelToWord[nChannelID] = {}
                end

                -- 先去重
                if not table.contain_value(self.tbMapChannelToWord[nChannelID], szWord) then
                    table.insert(self.tbMapChannelToWord[nChannelID], szWord)
                end
            end
        end

        if bRecruitBlock then
            table.insert(self.tbListRecruitWord, szWord)
        end
    end

    return
end

function WordBlockMgr.UnInit()

end

-- 某个聊天消息是否被屏蔽了
function WordBlockMgr.HasWordBlockedInChat(szMsg, nChannel)
    local bResult = false

    if self.GetIsOpen() and not string.is_nil(szMsg) then
        local tbWords = self.tbMapChannelToWord[nChannel]
        for k, szWord in ipairs(tbWords or {}) do
            if string.find(szMsg, szWord) then
                bResult = true
                break
            end
        end
    end

    return bResult
end

-- 某个招募消息是否被屏蔽了
function WordBlockMgr.HasWordBlockedInRecruit(szMsg)
    local bResult = false

    if self.GetIsOpen() and not string.is_nil(szMsg) then
        for _, szWord in ipairs(self.tbListRecruitWord) do
            if string.find(szMsg, szWord) then
                bResult = true
                break
            end
        end
    end

    return bResult
end

-- 获取聊天屏蔽配置列表
function WordBlockMgr.GetChatBlockCfgList()
    return Lib.copyTab(CHAT_BLOCK_CFG_LIST) -- CHAT_BLOCK_CFG_LIST
end

-- 获取某个聊天屏蔽配置
function WordBlockMgr.GetOneChatBlockCfg(szChatKey)
    if string.is_nil(szChatKey) then
        return nil
    end

    return self.tbMapKeyToBlockCfg[szChatKey]
end

-- 获取关键词文字的最大长度
function WordBlockMgr.GetMaxWordLen()
    return MAX_WORD_LEN
end

-- 获取关键词最多能存储的条数
function WordBlockMgr.GetMaxStorageLen()
    return MAX_STORAGE_LEN
end

-- 获取提示文字
function WordBlockMgr.GetStringTips()
    return STRING_TIPS
end

-- 获得 是否开启屏蔽
function WordBlockMgr.GetIsOpen()
    return Storage.WordBlock.bIsOpen
end

-- 设置 是否开启屏蔽
function WordBlockMgr.SetIsOpen(bIsOpen)
    if Storage.WordBlock.bIsOpen == bIsOpen then
        return
    end

    Storage.WordBlock.bIsOpen = bIsOpen
    Storage.WordBlock.Flush()
end

-- 已有相同的屏蔽字
function WordBlockMgr.AlreadyHasdWordInBlockList(szWord)
    return self.GetStorageByWord(szWord) ~= nil
end

function WordBlockMgr.GetBlokDescByWord(szWord)
    local szDesc = ""
    local tbData = WordBlockMgr.GetStorageByWord(szWord)
    local tbDesc = {}

    if not table.is_empty(tbData.tbChatKeyList) then
        table.insert(tbDesc, "聊天")
    end

    if tbData.bRecruitBlock then
        table.insert(tbDesc, "招募")
    end

    szDesc = table.concat(tbDesc, '、')

    return szDesc
end

--[[
    根据关键字获得存储内容，单个关键字的存储内容如下：
    {
		szWord = "屏蔽文字2",
		tbChatKeyList = {"Near", "Team"},
		bBulletBlock = false,
		bRecruitBlock = false,
	}
]]
function WordBlockMgr.GetStorageByWord(szWord)
    return self.tbMapWordToStorage[szWord]
end

function WordBlockMgr.GetStorageList(szSearchWord)
    local tbDataList = {}

    if not string.is_nil(szSearchWord) then
        for k, v in ipairs(Storage.WordBlock.tbWordBlockList) do
            if string.find(v.szWord, szSearchWord)  then
                table.insert(tbDataList, v)
            end
        end
    else
        tbDataList = Storage.WordBlock.tbWordBlockList
    end

    return tbDataList
end

function WordBlockMgr.GetStorageLen()
    return #Storage.WordBlock.tbWordBlockList
end

-- 根据关键字设置存储内容
function WordBlockMgr.SetStorageByWord(szWord, tbData)
    if string.is_nil(szWord) then
        return false
    end

    -- 之前没有，表示要新增，这时候要检查是否超过最大
    if self.tbMapWordToStorage[szWord] == nil then
        local nLen = WordBlockMgr.GetStorageLen()
        if nLen >= MAX_STORAGE_LEN then
            TipsHelper.ShowNormalTip("屏蔽关键词已达上限")
            return false
        end

        table.insert(Storage.WordBlock.tbWordBlockList, tbData)
    else
        for k, v in ipairs(Storage.WordBlock.tbWordBlockList) do
            if v.szWord == szWord then
                if tbData == nil then
                    table.remove(Storage.WordBlock.tbWordBlockList, k)
                else
                    Storage.WordBlock.tbWordBlockList[k] = tbData
                end
                break
            end
        end
    end

    Storage.WordBlock.Flush()
    self.InitData()

    return true
end

-- 批量删除
function WordBlockMgr.DeleteStorageByWordList(tbWordList)
    if not tbWordList then return end
    if table.is_empty(tbWordList) then return end

    for k, szWord in ipairs(tbWordList) do
        if not string.is_nil(szWord) then
            for k, v in ipairs(Storage.WordBlock.tbWordBlockList) do
                if v.szWord == szWord then
                    table.remove(Storage.WordBlock.tbWordBlockList, k)
                    break
                end
            end
        end
    end

    Storage.WordBlock.Flush()
    self.InitData()
end

