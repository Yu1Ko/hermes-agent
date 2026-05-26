BuffMgr = BuffMgr or {}

function BuffMgr.GetBuffName(dwID, nLevel , bIgnorConvertUtf8)
    local szBuffName = Table_GetBuffName(dwID, nLevel)
    if not szBuffName then
        szBuffName = Table_GetBuffName(dwID, 0)
    end
    return bIgnorConvertUtf8 and szBuffName or GBKToUTF8(szBuffName)
end

function BuffMgr.GetBuffTime(dwID, nLevel)
    local nTime = GetBuffTime(dwID, nLevel) or 0
	return UIHelper.GetDeltaTimeText(nTime, true)
end

function BuffMgr.GetBuffCount(dwID, nLevel)
    local _, nCount = GetBuffTime(dwID, nLevel)
	return nCount
end

function BuffMgr.GetInterval(dwID, nLevel)
    local _, _, nInterval = GetBuffTime(dwID, nLevel)
	return UIHelper.GetDeltaTimeText(nInterval, true)
end

function BuffMgr.GetBuffDesc(dwID, nLevel ,bIgnorConvertUtf8)
    local player = GetClientPlayer()
    local szDesc = Table_GetBuffDesc(dwID, nLevel)
    if not szDesc then
        szDesc = Table_GetBuffDesc(dwID, 0)
    end
    local szDescNew = ""
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
                return UIHelper.GetDeltaTimeText(nValue, true)
            end
            return nValue
        end
        return string.gsub(szText, "<BUFF (.-)>", fd)
    end

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
                return UIHelper.GetDeltaTimeText(nValue, true)
            end
            if nBase and nBase ~= 0 then
                local fPercent = math.floor((nValue / nBase  + 0.005)*100)
                return fPercent
            else
                return "0"
            end
        end
        return string.gsub(szText, "<BUFF_EX (%d+) (.-)>", fd)
    end
    szDesc = FormatBuffDesc(szDesc)
    szDesc = FormatBuffDescEx(szDesc)
    return bIgnorConvertUtf8 and szDesc or GBKToUTF8(szDesc)
end

function BuffMgr.GetLeftFrame(info, nLogic)
    nLogic = nLogic or GetLogicFrameCount()
	-- UILog("238", nLogic, GetLogicFrameCount(), info.nEndFrame)
	return math.max(0, math.floor(info.nEndFrame - nLogic))
end

function BuffMgr.Get(character, index, t)
	t.dwID, t.nLevel, t.bCanCancel, t.nEndFrame, t.nIndex, t.nStackNum, t.dwSkillSrcID, t.bValid, t.bIsStackable, t.nLeftFrame = character.GetBuff(index)
end

function BuffMgr.Generate(player, fnGenerate)
    if not player or not fnGenerate then
        return
    end
    local nCount = player.GetBuffCount()
    for i = 0, nCount - 1 do
        local tb = {}
        BuffMgr.Get(player, i, tb)
        fnGenerate(tb)
    end
end

function BuffMgr.GetVisibleBuff(character)
    local tbBuff = {}
    if not character then
        return tbBuff
    end
    local nCount = character.GetBuffCount()
    for i = 0, nCount - 1 do
        local tb = {}
        BuffMgr.Get(character, i, tb)
        if tb.bValid and Table_BuffIsVisible(tb.dwID, tb.nLevel) then
            table.insert(tbBuff, tb)
        end
    end
    return tbBuff
end

function BuffMgr.GetAllBuff(character)
    local tbBuff = {}
    if not character then
        return tbBuff
    end
    local nCount = character.GetBuffCount()
    for i = 0, nCount - 1 do
        local tb = {}
        BuffMgr.Get(character, i, tb)
        if tb.bValid then
            table.insert(tbBuff, tb)
        end
    end
    return tbBuff
end

-- Buff是否可驱散 原端游
local m_tBuffType = {}
function BuffMgr.Buffer_GetType(dwBufferID, nLevel)
    local szKey = dwBufferID.."_"..tostring(nLevel)

	if m_tBuffType[szKey] then
		return m_tBuffType[szKey]
	end

	local attris 	= {}
	local info 		= GetBuffInfo(dwBufferID, nLevel, attris)
	m_tBuffType[szKey] = {[1] = info.nDetachType, [2] = info.nFunctionType}

	return m_tBuffType[szKey]
end

local m_tDispelInfo = {}
function BuffMgr.Buffer_GetDispelInfo(dwPlayerKungfuID)
	dwPlayerKungfuID = dwPlayerKungfuID or UI_GetPlayerMountKungfuID()
	if not dwPlayerKungfuID then
		return
	end

	if not m_tDispelInfo[dwPlayerKungfuID] then
		m_tDispelInfo[dwPlayerKungfuID] = g_tTable.DispelBuff:Search(dwPlayerKungfuID)
	end

	return m_tDispelInfo[dwPlayerKungfuID]
end

local m_tBuffDispel = {}
function BuffMgr.Buffer_IsDispel(dwBufferID, nLevel)
    local szKey = dwBufferID.."_"..tostring(nLevel)
    if m_tBuffDispel[szKey] then
        return m_tBuffDispel[szKey]
    end

	local btype = BuffMgr.Buffer_GetType(dwBufferID, nLevel)[1]
	if btype == 0 then
        m_tBuffDispel[szKey] = false
		return false
	end

	local info = BuffMgr.Buffer_GetDispelInfo()
	if info and info["szBuffTye"..btype] == 1 then
        m_tBuffDispel[szKey] = true
		return true
	end

    m_tBuffDispel[szKey] = false
	return false
end

local m_tBuffDispelMobile = {}
function BuffMgr.Buffer_IsDispelMobile(dwBufferID, nLevel)
    local szKey = dwBufferID.."_"..tostring(nLevel)
    if m_tBuffDispelMobile[szKey] then
        return m_tBuffDispelMobile[szKey]
    end

    local tType = BuffMgr.Buffer_GetType(dwBufferID, nLevel)
    m_tBuffDispelMobile[szKey] = false
    if (tType[1] >= 3 and tType[1] <= 12) or (tType[2] == 12) then
        m_tBuffDispelMobile[szKey] = true
    end
    return m_tBuffDispelMobile[szKey]
end

function BuffMgr.Buffer_IsDebuffDispelMobile(dwBufferID, nLevel)
	local tType = BuffMgr.Buffer_GetType(dwBufferID, nLevel)
	if tType[1] == 4 or tType[1] == 6 or tType[1] == 8 or tType[1] == 10 or tType[1] == 12 or tType[2] == 12 then
        return true
    end
	return false
end

-- Buff的UIBuffCatalogInfoTab
local m_tBuffCatalog = {}
function BuffMgr.GetBuffCatalog(dwBufferID, nLevel)
    local szKey = dwBufferID.."_"..tostring(nLevel)
    if m_tBuffCatalog[szKey] then
        return m_tBuffCatalog[szKey]
    end

    local info = Table_GetBuff(dwBufferID, nLevel)
    m_tBuffCatalog[szKey] = info and UIBuffCatalogInfoTab[info.nCatalog]
    return m_tBuffCatalog[szKey]
end

-- Buff 优先级
function BuffMgr.GetSortedBuff(character, bSortTime, bIgnoreCatalog)
    local function fnSortedTime(a,b)
        if bSortTime then
            local nA = a.nLeftFrame
            local nB = b.nLeftFrame
            if nA and nB then
                return nA < nB
            elseif nA or nB then
                return nB == nil
            else
                return a.dwID < b.dwID
            end
        else
            return a.dwID < b.dwID
        end
    end

    local function fnThirdCompare(a, b)
        local tA = BuffMgr.GetBuffCatalog(a.dwID, a.nLevel)
        local tB = BuffMgr.GetBuffCatalog(b.dwID, b.nLevel)
        if tA and tB then
            if tA.nPriority == tB.nPriority then
                return fnSortedTime(a,b)
            else
                return tA.nPriority < tB.nPriority
            end
        elseif tA or tB then
            return tB == nil
        else
            fnSortedTime(a,b)
        end
    end

    local function fnSecondCompare(a,b)
        local bA = BuffMgr.Buffer_IsDispelMobile(a.dwID, a.nLevel)
        local bB = BuffMgr.Buffer_IsDispelMobile(b.dwID, b.nLevel)
        if bA == bB then
            return fnThirdCompare(a, b)
        else
            return bA == true
        end
    end

    -- BUFF类型（0：中性；1：增益；2：减益）
    local function fnFirstCompareFriend(a,b)
        local tA = BuffMgr.GetBuffCatalog(a.dwID, a.nLevel)
        local tB = BuffMgr.GetBuffCatalog(b.dwID, b.nLevel)
        if tA and tB then
            local nA = tA.nType
            local nB = tB.nType
            if nA == nB then
                return fnSecondCompare(a,b)
            elseif nA == 0 or nB == 0 then
                return nA > nB
            else
                return nA > nB
            end
        elseif tA or tB then
            return tB == nil
        else
            return fnSecondCompare(a,b)
        end
    end

    local function fnFirstCompareEnemy(a,b)
        local tA = BuffMgr.GetBuffCatalog(a.dwID, a.nLevel)
        local tB = BuffMgr.GetBuffCatalog(b.dwID, b.nLevel)
        if tA and tB then
            local nA = tA.nType
            local nB = tB.nType
            if nA == nB then
                return fnSecondCompare(a,b)
            elseif nA == 0 or nB == 0 then
                return nA > nB
            else
                return nA < nB
            end
        elseif tA or tB then
            return tB == nil
        else
            return fnSecondCompare(a,b)
        end
    end

    local tbBuff = BuffMgr.GetVisibleBuff(character)
    if g_pClientPlayer and character then
        if IsEnemy(g_pClientPlayer.dwID, character.dwID) then
            table.sort(tbBuff, fnFirstCompareEnemy)
        else
            table.sort(tbBuff, fnFirstCompareFriend)
        end
    end

    -- local tTestResult =  BuffMgr.TestSortResult(tbBuff)
    if bSortTime == true then
        return tbBuff
    else
        local tLimitedBuff = {}
        local tCataCatalog = {}
        local nNum = 0
        for i = 1, #tbBuff do
            local buff = tbBuff[i]
            local tbCatalog = BuffMgr.GetBuffCatalog(buff.dwID, buff.nLevel)
            local bIsMBUIListPriority = bIgnoreCatalog and (BuffMgr.GetMBUIListPriority(buff.dwID, buff.nLevel) > 0)
            if bIsMBUIListPriority or (tbCatalog and tbCatalog.nType ~= 0 and not tCataCatalog[tbCatalog.nID]) then
                table.insert(tLimitedBuff, buff)
                if tbCatalog then
                    tCataCatalog[tbCatalog.nID] = true
                end
                nNum = nNum + 1
            end
            if nNum > 6 then
                break
            end
        end

        if nNum == 0 and #tbBuff > 0 then
            local buff = tbBuff[1]
            table.insert(tLimitedBuff, buff)
        end

        return tLimitedBuff
    end
end

function BuffMgr.GetMBUIListPriority(dwID, nLevel)
    local tbBuffConf = Table_GetBuff(dwID, nLevel)
    local nMbUIListPriority = tbBuffConf and tbBuffConf.nMbUIListPriority or 0
    return nMbUIListPriority
end

function BuffMgr.TestSortResult(tbBuff)
    local tTestResult = {}
    for i = 1, #tbBuff do
        local tResult = {}
        local tC = BuffMgr.GetBuffCatalog(tbBuff[i].dwID, tbBuff[i].nLevel)
        if tC then
            tResult[1] = tC.nType
            tResult[3] = tC.nPriority
        else
            tResult[1] = 0
            tResult[3] = 99
        end
        tResult[2] = BuffMgr.Buffer_IsDispelMobile(tbBuff[i].dwID, tbBuff[i].nLevel)
        tResult[4] = tbBuff[i].dwID
        tResult[5] = BuffMgr.GetBuffName(tbBuff[i].dwID, tbBuff[i].nLevel)
        table.insert(tTestResult, tResult)
    end
    return tTestResult
end

local m_tBuffMobileTeamShowInfo = {}
function BuffMgr.Buffer_GetMobileTeamShowInfo(dwBufferID, nLevel)
    local szKey = dwBufferID.."_"..tostring(nLevel)
    if not m_tBuffMobileTeamShowInfo[szKey] then
        return m_tBuffMobileTeamShowInfo[szKey]
    end

    local info = Table_GetBuff(dwBufferID, nLevel)
    m_tBuffMobileTeamShowInfo[szKey] = {
        bMbSpecialShow = info.bMbSpecialShow,
        nMbSpecialShowPriority = info.nMbSpecialShowPriority,
        bMbCantRebirth = info.bMbCantRebirth,
    }
    return m_tBuffMobileTeamShowInfo[szKey]
end

function BuffMgr.GetMobileTeamShowInfo(character)
    local tbShowBuff = {}
    local bCantRebirth = false
    if not character then
        return tbBuff, bCantRebirth
    end

    local nCount = character.GetBuffCount()
    for i = 0, nCount - 1 do
        local tb = {}
        BuffMgr.Get(character, i, tb)
        if tb.bValid then
            local bShow, nPriority, bCant = Table_GetBuffTeamShowInfo(tb.dwID, tb.nLevel)
            if bShow then
                tb.nPriority = nPriority
                table.insert(tbShowBuff, tb)
            end
            if bCant then
                bCantRebirth = bCant
            end
        end
    end

    table.sort(tbShowBuff,function(a, b)
        return a.nPriority > b.nPriority -- 优先级高的在前面
    end)

    return tbShowBuff, bCantRebirth, #tbShowBuff > 0
end

function BuffMgr.GetSkillBuff(character)
    local  tbResult = {}
    local nCount = character.GetBuffCount()
    for i = 0, nCount - 1 do
        local tb = {}
        BuffMgr.Get(character, i, tb)
        if tb.bValid then
            if Table_IsSkillBuff(tb.dwID, tb.nLevel) then
                table.insert(tbResult, tb)
            end
        end
    end
    return tbResult
end