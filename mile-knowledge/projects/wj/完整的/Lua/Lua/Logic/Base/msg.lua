--------------------------------------------
-- @File  : msg.lua
-- @Desc  : 消息中心
-- @Author: 未知
-- @Date  : 未知
-- @Email : admin@derzh.com
-- @Last modified by:   Zhai Yiming
-- @Last modified time: 2016-12-12 13:14:55
-- @Version: 1.0
-- @ChangeLog:
--  + v1.0 File formated. -- via翟一鸣
--------------------------------------------
-- 普通消息就是一句话
-- 由多个部分组成的消息。比如对话应该使用richtext
-- '<text>text="[风清扬]:" name=\"namelink\" eventid=515 </text>'                ..
-- '<text>text="清仓大甩卖，需要的密！" </text>'                                 ..
-- '<text>text="[青龙偃月刀]" name="itemlink" eventid=515 userdata=1234 </text>' ..
-- '<text>text="[小七]" name="namelink" eventid=515 </text>'                     ..
-- '<animate>path="ui\image\face.uitex" group=0 </animate>'                      ..
-- '<text>text="\\\n"<text>'
local m_nColorVersion = 0
local g_nChatFont=10
--g_tDefaultChannel = {}

Msg = {}

g_tDefaultChannel = Table_GetMsgChannelDefaultFontsForPlatform()


function WriteMsgDefaultChannelFontToFile()
	local szFile = "ui/Great.tab"
	local file = io.open(szFile, "w")
	assert(file)

	local tData = g_tDefaultChannel
	file:write("szChannel", "\t", "_Comment", "\t", "nFont", "\t", "RGB\n")
	for k, v in pairs(tData) do
		file:write(k, "\t", "", "\t", v.nFont, "\t", v.r .. ";" .. v.g .. ";" .. v.b, "\t", "\n")
	end
	file:close()
end

IDENTITY =
{
	JIANG_HU  = 0,-- 侠
	SHAO_LIN  = 1,-- 少林
	WAN_HUA   = 2, -- 万花
	TIAN_CE   = 3, -- 天策
	CHUN_YANG = 4,-- 纯阳,
	QI_XIU    = 5,-- 七秀
	WU_DU     = 6,-- 五毒
	TANG_MEN  = 7,-- 唐门
	CANG_JIAN = 8,-- 藏剑
	GAI_BANG  = 9,-- 丐帮
	MING_JIAO = 10,-- 明教
	CANG_YUN  = 21,--苍云
  	CANG_GE  = 22,--长歌
	BA_DAO  = 23,--霸刀
	PENG_LAI  = 24,--蓬莱
	LING_XUE  = 25,--凌雪
	YAN_TIAN  = 211,--衍天
	YAO_ZONG  = 212, --药宗
	DAO_ZONG  = 213, --刀宗
	TUAN_ZHANG = 100, --团长
	BANG_ZHU   = 101, -- 帮主
}

g_tIdentityColor =
{
	[IDENTITY.JIANG_HU]  = {r = 22, g = 183, b = 116},
	[IDENTITY.CHUN_YANG] = {r = 16,  g = 168, b = 210},-- 纯阳
	[IDENTITY.TIAN_CE]   = {r = 212, g = 54, b = 69},--天策
	[IDENTITY.QI_XIU]    = {r = 196, g = 62, b = 135},--七秀
	[IDENTITY.SHAO_LIN]  = {r = 197, g = 160, b = 15},--少林
	[IDENTITY.WAN_HUA]   = {r = 118, g = 49, b = 221},--万花
	[IDENTITY.WU_DU]     = {r =23, g = 109, b = 219},--五毒
	[IDENTITY.TANG_MEN]  = {r = 124,   g = 187,  b = 52},--唐门
	[IDENTITY.CANG_JIAN] = {r = 208, g = 206, b = 22},--藏剑
	[IDENTITY.GAI_BANG]  = {r = 252, g = 176,  b = 92},--丐帮
	[IDENTITY.MING_JIAO] = {r =213, g = 122, b = 35},--明教
	[IDENTITY.CANG_YUN]  = {r = 212, g = 73, b = 5},--苍云
	[IDENTITY.CANG_GE]  = {r = 84, g = 203, b = 149},--长歌
	[IDENTITY.BA_DAO]  = {r = 123, g = 125, b = 218},--霸刀
	[IDENTITY.PENG_LAI]  = {r = 195, g = 210, b = 225},--蓬莱
	[IDENTITY.LING_XUE]  = {r = 161, g = 9, b = 34},--凌雪
	[IDENTITY.YAN_TIAN]  = {r = 166, g = 83, b = 251} ,--衍天
	[IDENTITY.YAO_ZONG]  = {r = 0, g = 172, b = 153} ,--药宗
	[IDENTITY.DAO_ZONG]  = {r = 107, g = 183, b = 242} ,--刀宗
	[IDENTITY.TUAN_ZHANG] = {r = 88, g = 238, b = 252},
	[IDENTITY.BANG_ZHU]   = {r = 93, g = 255, b = 112},
}


function GetKungfuSchoolColor(dwSchoolID)
	local dwForceID = Table_SchoolToForce(dwSchoolID)
	local c = g_tIdentityColor[dwForceID]
	return c.r, c.g, c.b
end

local g_tCampColor =
{
	[CAMP.NEUTRAL] = {r = 255, g = 255, b = 255},
	[CAMP.GOOD]    = {r = 7,   g = 82,  b = 154},
	[CAMP.EVIL]    = {r = 255, g = 111, b = 83},
}
local MSG_VERSION = 5
_g_MsgVersion = 0
_g_MsgCenter = clone(g_tDefaultChannel)
local g_tMsgCenterMonitor = {}
local l_tMsgFilter = {}
local l_tMsgHook = {}

-- for k, v in pairs(_g_MsgCenter) do
-- 	RegisterCustomData("_g_MsgCenter." .. k)
-- end
-- RegisterCustomData("_g_MsgVersion")

local tMsgCache = {}
local bCloseMsgOut = false

function SwitchMsgOut(bClose)
	bCloseMsgOut = bClose
end


local function fnCheckFilter(szType, szMsg, bRich, nFont, r, g, b, dwTalkerID, szName)
	local tFilter = l_tMsgFilter[szType]
	if tFilter then
		for kM, vM in ipairs(tFilter) do
			if vM(szMsg, nFont, bRich, r, g, b, szType, dwTalkerID, szName) then
				return true
			end
		end
	end

	return false
end

--缓存聊天界面还没有创建时收到的消息
local function fnCheckCacheMsg(...)
	if (not IsChatPanelInit or not IsChatPanelInit()) and szType ~= "MSG_ANNOUNCE_RED" and szType ~= "MSG_ANNOUNCE_YELLOW" then
		local args = {...}
		table.insert(tMsgCache, args)
		return true
	end

	return false
end

--方便插件修改聊天信息
local function fnMsgHook(szType, szMsg, bRich, nFont, r, g, b, dwTalkerID, szName)
	local tHook = l_tMsgHook[szType]
	if tHook then
		for kM, vM in ipairs(tHook) do
			szMsg, nFont, bRich, r, g, b = vM(szMsg, nFont, bRich, r, g, b, szType, dwTalkerID, szName) --参数顺序和fnCheckFilter保持一直
		end
	end
	return szMsg, bRich, nFont, r, g, b
end

local function fnGetMsgFont(szType, nFont)
	if nFont then
		return nFont
	end
	local v = _g_MsgCenter[szType]
	nFont = v and v.nFont or g_nChatFont
	return nFont
end

local function fnGetMsgColor(szType, tColor)
	local v = _g_MsgCenter[szType]
	local r, g, b = 255, 255, 255
	if tColor then
		r = tColor[1]
		g = tColor[2]
		b = tColor[3]
	elseif v then
		r, g ,b = v.r, v.g, v.b
	end
	return r, g, b
end

--- szType 来自UI配置表 MsgChannelDefaultFont.tab
function OutputMessage(szType, szMsg, bRich)
	if bCloseMsgOut then
		return
	end

	szMsg = ParseTextHelper.ParseNormalText(szMsg)

	DispatchEventToMonitor(szType, szMsg, bRich)

	if szType == "MSG_SYS" then
		ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
		return
	end

	TipsHelper.OutputMessage(szType, szMsg, bRich)
	return
end

function DispatchEventToMonitor(szType, szMsg, bRich)
	local tMonitor = g_tMsgCenterMonitor[szType]
	if tMonitor then
		for kM, vM in ipairs(tMonitor) do
			vM(szMsg, nil, bRich, nil, nil, nil, szType)
		end
	end
end

function IsMonitorMsg(szType)
	local tMonitor = g_tMsgCenterMonitor[szType]
	return (tMonitor and table.getn(tMonitor) > 0)
end

--注册监听者。Monitor为接收消息函数，msg为接收消息列表
function RegisterMsgMonitor(Monitor, msg)
	assert(type(Monitor) == "function")
	for k, v in pairs(msg) do
		if not _g_MsgCenter[v] then
			_g_MsgCenter[v] = g_tDefaultChannel[v]
			if not _g_MsgCenter[v] then
				_g_MsgCenter[v] = {nFont = 1}
			end
		end
		if not g_tMsgCenterMonitor[v] then
			g_tMsgCenterMonitor[v] = {}
		end

		local bR = false
		for kM, vM in pairs(g_tMsgCenterMonitor[v]) do
			if vM == Monitor then
				bR = true
				break
			end
		end
		if not bR then
			table.insert(g_tMsgCenterMonitor[v], Monitor)
		end
	end
end

--注销监听者。如果msg为空注销所有Monitor监听的消息
function UnRegisterMsgMonitor(Monitor, msg)
	if not msg then
		for k, v in pairs(g_tMsgCenterMonitor) do
			for kM, vM in pairs(v) do
				if vM == Monitor then
					table.remove(v, kM)
					break
				end
			end
		end
		return
	end

	for k, v in pairs(msg) do
		local vT = g_tMsgCenterMonitor[v]
		if vT then
			for kM, vM in pairs(vT) do
				if vM == Monitor then
					table.remove(vT, kM)
					break
				end
			end
		end
	end
end

function RegisterMsgFilter(Filter, msg)
	assert(type(Filter) == "function")
	for _, szType in ipairs(msg) do
		if not l_tMsgFilter[szType] then
			l_tMsgFilter[szType] = {}
		end
		local bExist
		for _, func in ipairs(l_tMsgFilter[szType]) do
			if func == Filter then
				bExist = true
				break
			end
		end
		if not bExist then
			table.insert(l_tMsgFilter[szType], Filter)
		end
	end
end

function UnRegisterMsgFilter(Filter, msg)
	if msg then
		for i, szType in ipairs(msg) do
			if l_tMsgFilter[szType] then
				for i, func in ipairs_r(l_tMsgFilter[szType]) do
					if func == Filter then
						table.remove(l_tMsgFilter[szType], i)
						break
					end
				end
			end
		end
	else
		for szType, funcs in pairs(l_tMsgFilter) do
			for i, func in ipairs_r(funcs) do
				if func == Filter then
					table.remove(funcs, i)
					break
				end
			end
		end
	end
end

local function fnCheckHookExist(fnHook, szType)
	for _, func in ipairs(l_tMsgHook[szType]) do
		if func == fnHook then
			return true
		end
	end
	return false
end

--增加插件hook聊天消息的接口，方便插件修改聊天时间，颜色等信息
function RegisterMsgHook(fnHook, msg)
	assert(type(fnHook) == "function")
	for _, szType in ipairs(msg) do
		if not l_tMsgHook[szType] then
			l_tMsgHook[szType] = {}
		end
		if not fnCheckHookExist(fnHook, szType) then
			table.insert(l_tMsgHook[szType], fnHook)
		end
	end
end

local function fnRemoveHook(func, funcs)
	for i, func in ipairs_r(funcs) do
		if func == fnHook then
			table.remove(funcs, i)
			break
		end
	end
end

function UnRegisterMsgHook(fnHook, msg)
	if msg then
		for i, szType in ipairs(msg) do
			if l_tMsgHook[szType] then
				fnRemoveHook(fnHook, l_tMsgHook[szType])
			end
		end
		return
	end

	for szType, funcs in pairs(l_tMsgHook) do
		fnRemoveHook(fnHook, funcs)
	end
end

local function RemoveAddonActions(tActions)
	local addonEnv = GetAddonEnv()
	for szChannel, fnActions in pairs(tActions) do
		for i = #fnActions, 1, -1 do
			if getfenv(fnActions[i]) == addonEnv then
				table.remove(fnActions, i)
			end
		end
	end
end

function ClearAddonMsgMonitor()
	RemoveAddonActions(g_tMsgCenterMonitor)
	RemoveAddonActions(l_tMsgFilter)
	RemoveAddonActions(l_tMsgHook)
end

function GetMsgFontString(szType, tColor)
	local v = _g_MsgCenter[szType] or g_tDefaultChannel[szType]
	local szReturn
	if not v or not v.nFont then
		szReturn = " font=10".." r=255 g=255 b=255 "
	else
		local r, g, b = v.r, v.g, v.b
		if tColor then
			r = tColor.r
			g = tColor.g
			b = tColor.b
		end

		if r and g and b then
			szReturn = " font="..v.nFont.." r="..r.." g="..g.." b="..b.." "
		else
			szReturn = " font="..v.nFont.." "
		end
	end
	return szReturn
end

function GetMsgFont(szType)
	local v = _g_MsgCenter[szType] or g_tDefaultChannel[szType]
	if not v or not v.nFont then
		return g_nChatFont
	end
	return v.nFont
end

function GetMsgFontColor(szType, bA)
	local v = _g_MsgCenter[szType] or g_tDefaultChannel[szType]
	local r = 255
	local g = 255
	local b = 255
	if v then
		if v.r then
			r = v.r
		end
		if v.g then
			g = v.g
		end
		if v.b then
			b = v.b
		end
	end

	if bA then
		return {r, g, b}
	end
	return r, g, b
end

function SetMsgFontColor(szType, r, g, b)
	local v = _g_MsgCenter[szType]
	if v and r and g and b then

		v.r, v.g, v.b = r, g, b
		m_nColorVersion = GetCurrentTime()
		FireUIEvent("ON_CHAT_MSG_COLOR_CHANGE", szType, r, g, b)
	end
end

function GetMsgFontColorVersionTime()
	return m_nColorVersion
end

function SetDefaultMsgFontColor()
	FightLog.SetDefaultKeywordColor()
	_g_MsgCenter = clone(g_tDefaultChannel)
	m_nColorVersion = GetCurrentTime()
	FireEvent("ON_CHAT_MSG_COLOR_SET_DEFAULT")
end

function OutputCacheMsg()
	for _, tMsg in ipairs(tMsgCache) do
		OutputMessage(unpack(tMsg))
	end
end

Event.Reg("CHAT_PANEL_INIT", function() OutputCacheMsg() end)

------------------------------------
--            背景通讯            --
------------------------------------
-- ON_BG_CHANNEL_MSG
-- arg0: 消息szKey
-- arg1: 消息来源频道
-- arg2: 消息发布者ID
-- arg3: 消息发布者名字
-- arg4: 不定长参数数组数据
------------------------------------
-- 判断一个tSay结构是不是背景通讯
function IsBgMsg(t)
	return type(t) == "table" and t[1] and t[1].type == "eventlink" and t[1].name == "BG_CHANNEL_MSG"
end
-- 处理背景通讯
function ProcessBgMsg(t, nChannel, dwTalkerID, szName, bEcho)
	if IsBgMsg(t) and not bEcho and not (
		nChannel == PLAYER_TALK_CHANNEL.NEARBY
	 	or nChannel == PLAYER_TALK_CHANNEL.WORLD
	 	or nChannel == PLAYER_TALK_CHANNEL.FORCE
	 	or nChannel == PLAYER_TALK_CHANNEL.CAMP
	 	or nChannel == PLAYER_TALK_CHANNEL.FRIENDS
	 	or nChannel == PLAYER_TALK_CHANNEL.MENTOR
	) then
		local szKey, aParam = t[1].linkinfo or "", {}
		if #t > 1 then
			for i = 2, #t do
				-- 这里不能使用table.insert(aParam, oData)因为oData有可能是nil
				if t[i].type == "text" then
					aParam[i - 1] = t[i].text
				elseif t[i].type == "eventlink" and t[i].name == "" then
					aParam[i - 1] = str2var(t[i].linkinfo)
				end
			end
		end

		-- szKey: 消息, nChannel: 消息来源频道, dwTalkerID: 消息发布者ID, szName: 消息发布者名字, aParam: 不定长参数数组数据
		--if QuestTraceList.bShowTeamateQuestTrace then
			if szKey == "QUEST_SHARE_INFO"
			and nChannel == PLAYER_TALK_CHANNEL.RAID
			and szName ~= UI_GetClientPlayerName() then
				local szText, dwQuestID, szEnd = unpack(aParam)
				szText = GBKToUTF8(szText)
				szEnd = GBKToUTF8(szEnd)
				if dwQuestID then
					local szFont = GetMsgFontString("MSG_SYS")
					local nSysFont = GetMsgFont("MSG_SYS")
					local r, g, b = GetMsgFontColor("MSG_SYS")
					local tQuestStringInfo = Table_GetQuestStringInfo(dwQuestID)
					local szLink = ChatHelper.MakeLink_quest(dwQuestID)
					local szColor = "#FFFFFF"
    				local szQuestName = string.format("<href=%s><color=%s>[%s]</color></href>", szLink, szColor, GBKToUTF8(tQuestStringInfo.szName))
					local szText = GetFormatText(szText, nSysFont, r, g, b) .. szQuestName
					if szEnd then
						szText = szText .. GetFormatText(szEnd, nSysFont, r, g, b)
					end
					szText = szText .. GetFormatText("\n")
					--OutputMessage("MSG_ANNOUNCE_NORMAL", szText, true)
					OutputMessage("MSG_SYS", szText, true)
				else
					OutputMessage("MSG_ANNOUNCE_NORMAL", szText)
				end
			end
		--end

		 Event.Dispatch("ON_BG_CHANNEL_MSG", szKey, nChannel, dwTalkerID, szName, aParam)
	end
end
-- 发送背景通讯
-- SendBgMsg("茗伊", "RAID_READY_CONFIRM") -- 单人背景通讯
-- SendBgMsg(PLAYER_TALK_CHANNEL.RAID, "RAID_READY_CONFIRM") -- 频道背景通讯
function SendBgMsg(nChannel, szKey, ...)
	local tSay ={{ type = "eventlink", name = "BG_CHANNEL_MSG", linkinfo = szKey }}
	local szTarget = ""
	if type(nChannel) == "string" then
		szTarget = nChannel
		nChannel = PLAYER_TALK_CHANNEL.WHISPER
	end
	local tArg = {...}
	local nCount = select("#", ...) -- 这里有个坑 如果直接ipairs({...})可能会掉进坑： for遇到nil就中断了导致后续参数丢失
	for i = 1, nCount do
		table.insert(tSay, { type = "eventlink", name = "", linkinfo = var2str(tArg[i]) })
	end
	Player_Talk(GetClientPlayer(), nChannel, szTarget, tSay, false)
end
------------------------------------
-- 有种可能背景通讯数据太大 需要分次发送
-- 懒得写了先马克在这里 以后有时间再说吧
-- 在_SendBgMsg和ProcessBgMsg做拆分重组就好
-- 记得每次重组数据时发送接收数据百分比的事件
------------------------------------
--           背景通讯END          --
------------------------------------

local function On_Msg_Version_Change()
	if arg0 == "Role" then
		if not _g_MsgVersion then
			_g_MsgVersion = 0
		end

		if _g_MsgVersion ~= MSG_VERSION and MSG_VERSION == 5 then
			_g_MsgCenter = clone(g_tDefaultChannel)
		end

		if _g_MsgVersion < MSG_VERSION then
			if _g_MsgCenter then
				_g_MsgCenter["MSG_FACE"] = {nFont = g_nChatFont, r = 255, g = 255, b = 255}
			end

			_g_MsgCenter["MSG_GM_ANNOUNCE"] = g_tDefaultChannel["MSG_GM_ANNOUNCE"]
			_g_MsgCenter["MSG_GUILD_ALLIANCE"] = g_tDefaultChannel["MSG_GUILD_ALLIANCE"]
			_g_MsgVersion = MSG_VERSION
		end
	end
end

--RegisterEvent("CUSTOM_DATA_LOADED", On_Msg_Version_Change)

