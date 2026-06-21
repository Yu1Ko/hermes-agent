local function GetTimeText(nTime, bFrame)
    local szUtf8Text = TimeLib.GetTimeText(nTime, bFrame)

    -- buff中其他地方获得的字符串基本是gbk的，这里把时间也转换成gbk的，确保后续转换不会出问题
    return UIHelper.UTF8ToGBK(szUtf8Text)
end

function OutputBuffTip(dwCharacter, dwID, nLevel, nCount, bShowTime, nTime, Rect, bLink, bVisibleWhenHideUI)
	local szTip = "<Text>text="..EncodeComponentsString(Table_GetBuffName(dwID, nLevel).."\t").." font=65 </text>"

	local aInfo = {}
	local bufferInfo = GetBuffInfo(dwID, nLevel, aInfo)

	local szDetachType = ""
	if g_tStrings.tBuffDetachType[bufferInfo.nDetachType] then
		szDetachType = g_tStrings.tBuffDetachType[bufferInfo.nDetachType]
	end
	szTip = szTip.."<Text>text="..EncodeComponentsString(szDetachType.."\n").." font=106 </text>"

	local szDesc = GetBuffDesc(dwID, nLevel, "desc")
	if szDesc and Table_IsBuffDescAddPeriod(dwID, nLevel) then
		szDesc = szDesc..g_tStrings.STR_FULL_STOP
	end
	szTip = szTip.."<Text>text="..EncodeComponentsString(szDesc).." font=106 </text>"

	if bShowTime then
		local szTime = ""
		if nTime > 0 then
			local szLeftH = ""
			local szLeftM = ""
			local szLeftS = ""

			local h = math.floor(nTime / 3600)
			if h > 0 then
				szLeftH = h..g_tStrings.STR_BUFF_H_TIME_H.." "
			end

			local m = math.floor((nTime - h * 3600) / 60)
			if h > 0 or m > 0 then
				szLeftM = m..g_tStrings.STR_BUFF_H_TIME_M_SHORT.." "
			end

			local s = math.floor((nTime - h * 3600 - m * 60))
			if h > 0 or m > 0 or s > 0 then
				szLeftS = s..g_tStrings.STR_BUFF_H_TIME_S
				szTime = FormatString(g_tStrings.STR_BUFF_H_LEFT_TIME_MSG, szLeftH, szLeftM, szLeftS)
			else
				szTime = g_tStrings.STR_BUFF_H_TIME_ZERO
			end
		else
			szTime = g_tStrings.STR_BUFF_H_TIME_ZERO
		end
		szTip = szTip.."<Text>text="..EncodeComponentsString("\n"..szTime).." font=102 </text>"
	end

	-- 以下为测试代码
	if IsCtrlKeyDown() then
		szTip = szTip.."<Text>text="..EncodeComponentsString("\n"..g_tStrings.DEBUG_INFO_ITEM_TIP.."\n".."ID：      "..dwID.."\nLevel： "..tostring(nLevel).."\n").." font=102 </text>"
        local nIconID = Table_GetBuffIconID(dwID, nLevel)
        szTip = szTip .. GetFormatText("IconID："..tostring(nIconID).."\n", 102)
	end
	-- 以上为测试代码

	OutputTip(szTip, 300, Rect, nil, bLink, "buff-" .. dwID, nil, nil, nil, nil, nil, nil, nil, bVisibleWhenHideUI)
end

function ParseBuffDesc(szDesc, dwID, nLevel, tDescCtx)
	local player = GetClientPlayer()
	tDescCtx = CreateBuffDescContext(dwID, nLevel, player, tDescCtx)
	local szDesc1 = ""
	szDesc = szDesc or ""

	szDesc = string.gsub(szDesc, "<BUFFDESC (%d+) (%d+)>",
		function(szBuffID, szLevel)
			local dwBuffID = tonumber(szBuffID)
			local dwLevel = tonumber(szLevel) or 1
			local buff = {}
			Buffer_GetByID(player, dwBuffID, dwLevel, buff)
			if buff.dwID and buff.dwID == dwBuffID then
				local szDesc2 = Table_GetBuffDesc(dwBuffID, dwLevel)
				if not szDesc2 then
					szDesc2 = Table_GetBuffDesc(dwBuffID, 0)
				end
				szDesc1 = szDesc1 .. "。\n" .. ParseBuffDesc(szDesc2, dwBuffID, dwLevel, tDescCtx)
			end
			return ""
		end
	)

	szDesc = string.gsub(szDesc, "<Skill (%d+) (%d+) (.-)>",
		function(dwSkillID, nLevel, szDesc1)
			dwSkillID = tonumber(dwSkillID)
			local nRequestLevel = tonumber(nLevel) or 1
			local nLevel = player.GetSkillLevel(dwSkillID)
			if nLevel == nRequestLevel then
				return szDesc1
			end
			return ""
		end
	)

	szDesc = ParseSkillDescCommonTokens(szDesc, dwID, nLevel, nil, nil, nil, player, nil, tDescCtx)

	local function FormatBuffDesc(szText)
		local aInfo = {}
		string.gsub(szText, "<BUFF (.-)>", function(s) table.insert(aInfo, s) return s end)
		local bufferInfo = GetBuffInfo(dwID, nLevel, aInfo)
		if not bufferInfo then
			return szText
		end
		bufferInfo.time, bufferInfo.count, bufferInfo.interval = GetBuffTime(dwID, nLevel)
		local fd = function(s)
			local nValue = math.abs(bufferInfo[s])
			if s == "time" or s == "interval" then
				return GetTimeText(nValue, true)
			end
			return nValue
		end
		return string.gsub(szText, "<BUFF (.-)>", fd)
	end
	szDesc = FormatBuffDesc(szDesc)

	local function FormatBuffDescEx(szText)
		local aInfo = {}
		string.gsub(szText, "<BUFF_EX (%d+) (.-)>", function(nBase, s) table.insert(aInfo, s) return s end)
		local bufferInfo = GetBuffInfo(dwID, nLevel, aInfo)
		if not bufferInfo then
			return szText
		end
		bufferInfo.time, bufferInfo.count, bufferInfo.interval = GetBuffTime(dwID, nLevel)
		local fd = function(nBase, s)
			local nValue = math.abs(bufferInfo[s])
			if s == "time" or s == "interval" then
				return GetTimeText(nValue, true)
			end
			if nBase and nBase ~= 0 then
				local fPercent = math.floor((nValue / nBase + 0.005) * 100)
				return fPercent
			else
				return "0"
			end
		end
		return string.gsub(szText, "<BUFF_EX (%d+) (.-)>", fd)
	end
	szDesc = FormatBuffDescEx(szDesc)

	return szDesc, szDesc1
end

function GetBuffDesc(dwID, nLevel, szKey, tDescCtx)
	local player = GetClientPlayer()
	tDescCtx = CreateBuffDescContext(dwID, nLevel, player, tDescCtx)
	if szKey == "name" then
		local szBuffName = Table_GetBuffName(dwID, nLevel)
		if not szBuffName then
			szBuffName = Table_GetBuffName(dwID, 0)
		end
		return szBuffName
	elseif szKey == "time" then
		local nTime = GetBuffTime(dwID, nLevel)
		return GetTimeText(nTime, true)
	elseif szKey == "count" then
		local _, nCount = GetBuffTime(dwID, nLevel)
		return nCount
	elseif szKey == "interval" then
		local _, _, nInterval = GetBuffTime(dwID, nLevel)
		return GetTimeText(nInterval, true)
	elseif szKey == "desc" then
		local szDesc = Table_GetBuffDesc(dwID, nLevel)
		local szDesc1 = ""
		if not szDesc then
			szDesc = Table_GetBuffDesc(dwID, 0)
		end

		szDesc, szDesc1 = ParseBuffDesc(szDesc, dwID, nLevel, tDescCtx)
		if szDesc1 ~= "" then
			szDesc = szDesc .. szDesc1
		end
		return szDesc
	end
end

function GetBindBuffDesc(nIndex, dwID, nLevel, szKey, skillKey)
	if szKey == "name" then
		return Table_GetBuffName(dwID, nLevel)
	elseif szKey == "time" then
		local nTime = GetBindBuffTime(nIndex, skillKey)
		return GetTimeText(nTime, true)
	elseif szKey == "count" then
		local _, nCount = GetBindBuffTime(nIndex, skillKey)
		return nCount
	elseif szKey == "interval" then
		local _, _, nInterval = GetBindBuffTime(nIndex, skillKey)
		return GetTimeText(nInterval, true)
	elseif szKey == "desc" then
		local szDesc = Table_GetBuffDesc(dwID, nLevel) or ""
		szDesc = GetPureText(szDesc)
		local aInfo = {}
		string.gsub(szDesc, "<BUFF (.-)>", function(s) table.insert(aInfo, s) return s end)
		local bufferInfo = GetBindBuffInfo(nIndex, skillKey, aInfo)
		bufferInfo.time, bufferInfo.count, bufferInfo.interval = GetBindBuffTime(nIndex, skillKey)
		local fd = function(s)
			local nValue = math.abs(bufferInfo[s])
			if s == "time" or s == "interval" then
				return GetTimeText(nValue, true)
			end
			return nValue
		end
		return string.gsub(szDesc, "<BUFF (.-)>", fd)
	end
end

local m_tDispelInfo = {}
-- * 获取buffer的驱散信息
function Buffer_GetDispelInfo(dwPlayerKungfuID)
	dwPlayerKungfuID = dwPlayerKungfuID or UI_GetPlayerMountKungfuID()
	if not dwPlayerKungfuID then
		return
	end

	if not m_tDispelInfo[dwPlayerKungfuID] then
		m_tDispelInfo[dwPlayerKungfuID] = g_tTable.DispelBuff:Search(dwPlayerKungfuID)
	end

	return m_tDispelInfo[dwPlayerKungfuID]
end


local m_buffer = {}
function Buffer_GetType(dwBufferID, nLevel)
	if m_buffer[dwBufferID] then
		return m_buffer[dwBufferID]
	end

	local attris 	= {}
	local info 		= GetBuffInfo(dwBufferID, nLevel, attris)
	local btype 	= info.nDetachType
	m_buffer[dwBufferID] = btype

	return m_buffer[dwBufferID]
end

-- * 是否可驱散
function Buffer_IsDispel(dwBufferID, nLevel)
	local btype = Buffer_GetType(dwBufferID, nLevel)
	if btype == 0 then
		return false
	end

	local info = Buffer_GetDispelInfo()
	if info and info["szBuffTye"..btype] == 1 then
		return true
	end

	return false
end

function Buffer_GetTimeData(dwBufferID)
	if not dwBufferID then
		return
	end

	local player = GetClientPlayer()

	if not player then
		return
	end

	local buff = {}
	Buffer_GetByID(player, dwBufferID, 0, buff)
	if buff.dwID then
		--return {nEndFrame = buff.nEndFrame, nLeftFrame = buff.nLeftFrame}
		return {nEndFrame = buff.nEndFrame}
	end
end

function Buffer_GetEndFrame(dwBufferID)
	if not dwBufferID then
		return
	end

	local player = GetClientPlayer()

	if not player then
		return
	end

	local buff = {}
	Buffer_GetByID(player, dwBufferID, 0, buff)
	if buff.dwID then
		return buff.nEndFrame
	end
end

function Buffer_GetStackNum(nBuffID)
	local pPlayer = GetClientPlayer()
	if not pPlayer or not nBuffID then
		return 0
	end

	local nCount = pPlayer.GetBuffCount()
	local tBuff = {}
	for i = 1, nCount, 1 do
		Buffer_Get(pPlayer, i - 1, tBuff)
		if tBuff.dwID == nBuffID then
			return tBuff.nStackNum
		end
	end
	return 0
end

function Buffer_GetLeftFrame(info, nLogic)
	--尝试修复BUFF某时刻显示时间停住
	-- if info.nLeftFrame then
	-- 	return info.nLeftFrame
	-- end
	nLogic = nLogic or GetLogicFrameCount()
	-- UILog("238", nLogic, GetLogicFrameCount(), info.nEndFrame)
	return math.max(0, math.floor(info.nEndFrame - nLogic))
end

function Buffer_GetSparkFrame(dwID, nLevel)
	local nSparkFrame = Table_GetBuffTime(dwID, nLevel)
	if nSparkFrame then
		nSparkFrame = nSparkFrame * 0.2
		if nSparkFrame < 32 then
			nSparkFrame = 32
		elseif nSparkFrame > 480 then
			nSparkFrame = 480
		end
	end
	return nSparkFrame
end

function Buffer_Get(tar, index, t)
	t.dwID, t.nLevel, t.bCanCancel, t.nEndFrame, t.nIndex, t.nStackNum, t.dwSkillSrcID, t.bValid, t.bIsStackable, t.nLeftFrame = tar.GetBuff(index)
end

function Buffer_GetByID(tar, buffid, bufflevel, t)
	bufflevel = bufflevel or 0
	local tBuff = tar.GetBuff(buffid, bufflevel)
	if tBuff and tBuff.nLevel then
		local aInfo = {}
		local bufferInfo = GetBuffInfo(buffid, tBuff.nLevel, aInfo)
		t.dwID = tBuff.dwID
		t.nLevel = tBuff.nLevel
		t.bCanCancel = bufferInfo.bCanCancel
		t.nStackNum = tBuff.nStackNum
		t.nIndex = tBuff.nIndex
		t.nEndFrame = tBuff.GetEndTime()
		t.bValid = tBuff.bValidity
		t.dwSkillSrcID = tBuff.dwSkillSrcID
		t.bIsStackable = tBuff.IsStackable()
		-- t.nLeftFrame 显示时间停住的时候用，还没上外网，先不弄了
	end
end

function Buff_Have(hPlayer, dwBuffID, nBuffLevel)
	if not nBuffLevel then
		nBuffLevel = 0
	end
	return hPlayer.IsHaveBuff(dwBuffID, nBuffLevel)
end

--给插件过滤某些BUFF的接口
local m_tFilterBuff = {}
function Buff_AddonSetFilter(tFilterBuff)
	m_tFilterBuff = {}
	for k, v in pairs(tFilterBuff) do
		m_tFilterBuff[v.dwBuffID .. "_" .. v.dwBuffLevel] = true
	end
end

function Buff_AddonFilter(dwBuffID, dwBuffLevel)
	if m_tFilterBuff[dwBuffID .. "_" .. dwBuffLevel] then
		return true
	end
end

--==== end ===============================================================
