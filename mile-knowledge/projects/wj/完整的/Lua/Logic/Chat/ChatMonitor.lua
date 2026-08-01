-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: ChatMonitor
-- Date: 2024-11-20 16:45:25
-- Desc: ?
-- ---------------------------------------------------------------------------------

ChatMonitor = ChatMonitor or {className = "ChatMonitor"}
local self = ChatMonitor

--Storage.ChatMonitor = {
--    tbKeyWord = {
--		[1] = {
--			szWord = "监控文本1",
--			tbChannelList = {"Near", "Map", "World", "Team"}
--		},
--		[2] = {
--			szWord = "监控文本2",
--			tbChannelList = {"World", "Team"}
--		}
--},  --关键词
--    tbChatData = {
--		[1] = {...},--监控到的聊天内容
--		[2] = {...},--监控到的聊天内容
--} 
--}
local MAX_MONTIOR_CHAT_NUM = 30		--监控到的聊天内容最大可存储数目

local MAX_STORAGE_LEN = 5	--可配置关键词最大存储数目

local MAX_MONITOR_WORD_NUM = 5		--可配置监控文本最大数目

local MAX_WORD_LEN = 10		--监控文本最大字符长度

local CHAT_MONITOR_CFG_LIST = {
	{szKey = "Near", szName = "近聊频道", tbChannelIDs = {1}, bDefaultSelect = true,},
	{szKey = "Map", szName = "地图频道", tbChannelIDs = {5}, bDefaultSelect = true,},
	{szKey = "World", szName = "世界频道", tbChannelIDs = {32}, bDefaultSelect = true,},
	{szKey = "Team", szName = "队伍频道", tbChannelIDs = {2}, bDefaultSelect = true, },
	{szKey = "Raid", szName = "团队频道", tbChannelIDs = {3}, bDefaultSelect = true, },
	{szKey = "Room", szName = "房间频道", tbChannelIDs = {50}, bDefaultSelect = true, },
	{ szKey = "Camp", szName = "阵营频道", tbChannelIDs = {34}, bDefaultSelect = true, },
	{ szKey = "Battle", szName = "战场频道", tbChannelIDs = {4}, bDefaultSelect = true, },
	{ szKey = "Lidu", szName = "李渡鬼域", tbChannelIDs = {47}, bDefaultSelect = true, },
	{ szKey = "Whisper", szName = "密聊频道", tbChannelIDs = {6}, bDefaultSelect = true, },
	{ szKey = "Friend", szName = "好友频道", tbChannelIDs = {36}, bDefaultSelect = true, },
	{ szKey = "Teacher", szName = "拜师频道", tbChannelIDs = {35}, bDefaultSelect = true, },
	{ szKey = "Force", szName = "门派频道", tbChannelIDs = {33}, bDefaultSelect = true, },
	{ szKey = "Tong", szName = "帮会频道", tbChannelIDs = {29,31}, bDefaultSelect = true, },
	{ szKey = "TongMeng", szName = "同盟频道", tbChannelIDs = {30}, bDefaultSelect = true, },
	{ szKey = "Identity", szName = "萌新频道", tbChannelIDs = {40}, bDefaultSelect = true, },
	{ szKey = "Danmaku", szName = "弹幕频道", tbChannelIDs = {42}, bDefaultSelect = true, },
	{ szKey = "All", szName = "全服频道", tbChannelIDs = {49}, bDefaultSelect = true, },
	{ szKey = "System", szName = "系统频道", tbChannelIDs = nil, szUIChannel = UI_Chat_Channel.System, bDefaultSelect = true, },
	{ szKey = "NpcPlot", szName = "NPC剧情", tbChannelIDs = nil, szUIChannel = UI_Chat_Channel.NPCStory, bDefaultSelect = true, },
	{ szKey = "PlayerPlot", szName = "玩家剧情", tbChannelIDs = {28}, bDefaultSelect = true, },
}

self.tbMapKeyToMonitorCfg = {} -- Key 对应某个配置 {["Near"] = CHAT_MONITOR_CFG_LIST[1]}
self.tbMapWordToStorage = {} -- Word 对应某个存储的配置 {["监控文本1"] = Storage.ChatMonitor.tbKeyWord[1]}
self.tbMapChannelToWord = {} -- 聊天频道ID和监控文本 {[PLAYER_TALK_CHANNEL.NEARBY] = {"监控文本1", "监控文本2"}}

function ChatMonitor.Init()
	for k, v in ipairs(CHAT_MONITOR_CFG_LIST) do
        self.tbMapKeyToMonitorCfg[v.szKey] = v
    end

	Event.Reg(self, EventType.OnReceiveChat, function(tbData)
		if not tbData then return end

		local tbChatData = clone(tbData)

		local nPrefabID = tbChatData.nPrefabID
        if nPrefabID == PREFAB_ID.WidgetChatTime then
            return
        end

		local nChannel = tbChatData.nChannel
		local szName = tbChatData.szName
		local szMsg = tbChatData.szContent
--
		local bMonitor = ChatMonitor.HasMonitoredInChat(szName, szMsg, nChannel)
		--检查改条消息是否符合监听条件
		if bMonitor then
			if not UIMgr.GetViewScript(VIEW_ID.PanelChatMonitor) then
				ChatMonitor.UpdateBubbleMsgData()
			end
			self.AddChatInfo(tbChatData)
			Event.Dispatch(EventType.OnAddChatMonitor, tbChatData)
		end
	end)

	Event.Reg(self, EventType.OnRoleLogin, function (szRoleName)
		self.InitData()
    end)
end

function ChatMonitor.UnInit()
	
end

function ChatMonitor.InitData()
	self.tbMapWordToStorage = {} 
	self.tbMapChannelToWord = {} 

	local tbStorageMonitorList = ChatMonitor.GetMonitorKeyWordInfo()
	for i, v in ipairs(tbStorageMonitorList) do
		local szWord = v.szWord
		local tbChannelList = v.tbChatKeyList or {}
		self.tbMapWordToStorage[szWord] = v

		for i, szChannel in ipairs(tbChannelList) do
			local tbCfg = ChatMonitor.GetOneMonitorCfg(szChannel)
			local tbChannelIDs = tbCfg and tbCfg.tbChannelIDs or {}
			local szUIChannel = tbCfg and tbCfg.szUIChannel
			for _, nChannelID in ipairs(tbChannelIDs) do
                if not self.tbMapChannelToWord[nChannelID] then
                    self.tbMapChannelToWord[nChannelID] = {}
                end

                -- 先去重
                if not table.contain_value(self.tbMapChannelToWord[nChannelID], szWord) then
                    table.insert(self.tbMapChannelToWord[nChannelID], szWord)
                end
            end

			if table.is_empty(tbChannelIDs) and szUIChannel then
				if not self.tbMapChannelToWord[szUIChannel] then
                    self.tbMapChannelToWord[szUIChannel] = {}
                end

				if not table.contain_value(self.tbMapChannelToWord[szUIChannel], szWord) then
                    table.insert(self.tbMapChannelToWord[szUIChannel], szWord)
                end
			end
		end
	end

end

function ChatMonitor.GetOneMonitorCfg(szChannel)
	if string.is_nil(szChannel) then
        return nil
    end

    return self.tbMapKeyToMonitorCfg[szChannel]
end

function ChatMonitor.GetMonitorKeyWordInfo()	--存本地的监控文本配置
	return Storage.ChatMonitor.tbKeyWord
end

function ChatMonitor.HasMonitoredInChat(szName, szMsg, nChannel)	--该消息是否被监听
	local bResult = false

	if not string.is_nil(szMsg) then
		local bNpcMsg = ChatData.IsSystemChannel(nChannel) and not string.is_nil(szName)
		local bSystemMsg = ChatData.IsSystemChannel(nChannel)
		local nChannel = bNpcMsg and UI_Chat_Channel.NPCStory or bSystemMsg and UI_Chat_Channel.System or nChannel
		local tbWords = self.tbMapChannelToWord[nChannel]
		szMsg = ChatMonitor.ParseChatMsg(szMsg)	--提取富文本中的纯文本内容
		for k, szWord in ipairs(tbWords or {}) do
			local tbStorage = ChatMonitor.GetStorageByWord(szWord)
			if tbStorage.bMonitor and string.find(szMsg, szWord, 1, true) then
				bResult = true
                break
			end
        end
	end

	return bResult
end

-- 获取聊天监控配置列表
function ChatMonitor.GetChatMonitorCfgList()
    return Lib.copyTab(CHAT_MONITOR_CFG_LIST)
end

-- 获取监听文字的最大长度
function ChatMonitor.GetMaxWordLen()
    return MAX_WORD_LEN
end

function ChatMonitor.GetStorageByWord(szWord)
    return self.tbMapWordToStorage[szWord]
end

function ChatMonitor.GetStorageLen()
    return #Storage.ChatMonitor.tbKeyWord
end

-- 根据关键字设置存储内容
function ChatMonitor.SetStorageByWord(szWord, tbData, szOldWord)
    if string.is_nil(szWord) then
        return false
    end

	local bChange = szOldWord and true or false

    -- 之前没有，表示要新增或修改，这时候要检查是否超过最大
    if self.tbMapWordToStorage[szWord] == nil then
		if bChange then	--修改
			for k, v in ipairs(Storage.ChatMonitor.tbKeyWord) do
            	if v.szWord == szOldWord then
                	Storage.ChatMonitor.tbKeyWord[k] = tbData
                	break
            	end
        	end
		else	--新增
			local nLen = ChatMonitor.GetStorageLen()
        	if nLen >= MAX_STORAGE_LEN then
        	    TipsHelper.ShowNormalTip("监控关键词已达上限")
        	    return false
        	end
			table.insert(Storage.ChatMonitor.tbKeyWord, tbData)
		end  
    else
        for k, v in ipairs(Storage.ChatMonitor.tbKeyWord) do
            if v.szWord == szWord then
                if tbData == nil then
                    table.remove(Storage.ChatMonitor.tbKeyWord, k)
                else
                    Storage.ChatMonitor.tbKeyWord[k] = tbData
                end
                break
            end
        end
    end

    Storage.ChatMonitor.Flush()
    self.InitData()

    return true
end

-- 获取关键词最多能存储的条数
function ChatMonitor.GetMaxStorageLen()
    return MAX_STORAGE_LEN
end

function ChatMonitor.GetStorageList()
    local tbDataList = {}

    tbDataList = Storage.ChatMonitor.tbKeyWord
    return tbDataList
end

function ChatMonitor.GetMonitorChatList()
	return Storage.ChatMonitor.tbChatData
end

function ChatMonitor.AddChatInfo(tbChatInfo)	--添加监听内容到列表
	if not tbChatInfo then
		return
	end

	local tbChatData = Storage.ChatMonitor.tbChatData
	if tbChatInfo.tbMsg then
		local szContent = ""
		local bChange = false
		for i, v in ipairs(tbChatInfo.tbMsg) do
			local szResult = ""
			if v.type == "emotion" then
				if v.id ~= -1 then
                    local szEmoji = string.format("<img emojiid='%d' src='' width='30' height='30'/>", v.id)
                    szContent = szContent .. szEmoji
                end
			elseif v.type == "item" then
				local item = GetItem(v.item)
				if item then
					bChange = true
					local tbItemInfo = {tabtype  = item.dwTabType, type = "iteminfo", index = item.dwIndex, version = 1}
					local szResult = ChatHelper.DecodeTalkData_iteminfo(tbItemInfo)
					szContent = szContent .. szResult
				end
			else
				szContent = v.text or ""
				szContent = szContent .. szResult
			end
		end
		if bChange then
			tbChatInfo.szContent = UIHelper.GBKToUTF8(szContent)
		end
	end

	table.insert(tbChatData, tbChatInfo)
	if #tbChatData > MAX_MONTIOR_CHAT_NUM then
        table.remove(tbChatData, 1)
    end
    Storage.ChatMonitor.Dirty()
end

function ChatMonitor.UpdateBubbleMsgData()
	BubbleMsgData.PushMsgWithType("ChatMonitorTips",{
		nBarTime = 5,
		szContent = string.format("你收到新监控消息，点击可查看详细信息"),
		szAction = function ()
			UIMgr.Open(VIEW_ID.PanelChatMonitor)
		end,
	})
end

function ChatMonitor.ParseChatMsg(szText)
	local szRemoveHref = szText:gsub("<href.-</href>", "")

	local szRemoveColor = szRemoveHref:gsub("<color=[^>]->", ""):gsub("</c>", "")

	local szRemoveAllTags = szRemoveColor:gsub("<%s*(%w+)%s*[^>]-/?>", "")

	local szResult = szRemoveAllTags:gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
	
	return szResult
end