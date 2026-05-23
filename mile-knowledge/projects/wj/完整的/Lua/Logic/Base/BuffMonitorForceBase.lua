BuffMonitorForceBase = BuffMonitorForceBase or { className = "BuffMonitorData" }

local self = BuffMonitorForceBase
local m_tInfo
local m_tMonitorList = {}
local m_nMaxNum
local _G = {}
local LING_XUE_CUSTOM_BUFF_LIST_ID = 3

local function AddMonitorTarget(nSrcTargetID, nStackNum, nEndFrame, nBuffID, nBuffLevel, tLine)
    self.AddMonitorForceTarget(nSrcTargetID, nStackNum, nEndFrame, nBuffID, nBuffLevel, tLine)
    Event.Dispatch("RefreshAllMonitorTarget", m_tMonitorList)
end

local function OnAddMonitorTarget(nSrcTargetID, nStackNum, nEndFrame, nBuffID, nBuffLevel)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    for k, tLine in pairs(m_tInfo) do
        if nBuffID == tLine.dwBuffID and (tLine.dwSkillID == 0 or hPlayer.GetSkillLevel(tLine.dwSkillID) > 0) then
            AddMonitorTarget(nSrcTargetID, nStackNum, nEndFrame, nBuffID, nBuffLevel, tLine)
        end
    end
end

local function OnBuffUpdate()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local nBuffOwnerID, bDelete, nBuffID, nStackNum, nEndFrame, nBuffLevel, nSrcTargetID = arg0, arg1, arg4, arg5, arg6, arg8, arg9
    if hPlayer.dwID ~= nBuffOwnerID or bDelete then
        return
    end

    OnAddMonitorTarget(nSrcTargetID, nStackNum, nEndFrame, nBuffID, nBuffLevel)
end

local function OnKungfuMount()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    if hPlayer then
        local tKungfu = hPlayer.GetKungfuMount()
        if not tKungfu or not TabHelper.IsHDKungfuID(tKungfu.dwSkillID) then
            return
        end
        local tInfo = {}
        local nCount = g_tTable.BuffMonitorForce:GetRowCount()
        for i = 2, nCount do
            local tLine = g_tTable.BuffMonitorForce:GetRow(i)
            if tLine.dwKungfuType == tKungfu.dwMountType then
                table.insert(tInfo, tLine)
                m_nMaxNum = tLine.nMaxNum --默认一种心法的最大个数一样
            end
        end

        if tKungfu.dwSkillID == 10585 then
            m_nMaxNum = 2
            local tBuffList = Table_GetCustomBuffList(LING_XUE_CUSTOM_BUFF_LIST_ID) -- 隐龙决buff特殊处理
            for _, nCustomBuffID in ipairs(tBuffList) do
                table.insert(tInfo, {dwBuffID = nCustomBuffID, dwSkillID = 0})
            end
        end

        if tInfo and #tInfo > 0 then
            m_tInfo = tInfo
            m_tMonitorList = {}
            Event.UnReg(BuffMonitorForceBase, "BUFF_UPDATE")
            Event.Reg(BuffMonitorForceBase, "BUFF_UPDATE", OnBuffUpdate)
        end
    end
end

function BuffMonitorForceBase.AddMonitorForceTarget(nSrcTargetID, nStackNum, nEndFrame, nBuffID, nBuffLevel, tLine)
    local hSrcTarget = GetPlayer(nSrcTargetID)
    local dwFullyType
    if hSrcTarget then
        dwFullyType = TARGET.PLAYER
    else
        hSrcTarget = GetNpc(nSrcTargetID)
        if hSrcTarget then
            dwFullyType = TARGET.NPC
        else
            return
        end
    end
    local bFind = false
    local nTotalFrame = nEndFrame - GetLogicFrameCount()
    for i, value in ipairs(m_tMonitorList) do
        if value.nSrcTargetID == nSrcTargetID and value.nBuffID == nBuffID then
            value.nStackNum = nStackNum

            if nEndFrame >= value.nEndFrame then
                value.nTotalFrame = nTotalFrame --策划特殊需求
            end
            value.nLeftFrame = nTotalFrame
            value.nEndFrame = nEndFrame
            bFind = true
            break
        end
    end

    if not bFind then
        table.insert(m_tMonitorList,
                {
                    nStackNum = nStackNum, nTotalFrame = nTotalFrame,
                    nLeftFrame = nTotalFrame, szSrcName = hSrcTarget.szName or "",
                    nSrcTargetID = nSrcTargetID, dwFullyType = dwFullyType,
                    hSrcTarget = { dwForceID = hSrcTarget.dwForceID or 0, dwModelID = hSrcTarget.dwModelID or 0 ,dwSchoolID = hSrcTarget.dwSchoolID or 0},
                    nBuffID = nBuffID, nEndFrame = nEndFrame, tLine = tLine, nBuffLevel = nBuffLevel
                })
    end
end

function BuffMonitorForceBase.CheckList()
    local bNeedUpdateList = false
    local i = 1
    while i <= m_nMaxNum and i <= #m_tMonitorList do
        local nLeftFrame = self.GetBuffLeftFrame(i)
        if nLeftFrame == 0 then
            table.remove(m_tMonitorList, i)
            bNeedUpdateList = true
        else
            m_tMonitorList[i].nLeftFrame = nLeftFrame
            i = i + 1
        end
    end
    return bNeedUpdateList, #m_tMonitorList
end

function BuffMonitorForceBase.GetBuff(tInfo)
    local hPlayer = GetClientPlayer()
    if not hPlayer or not tInfo then
        return
    end

    for i = 1, hPlayer.GetBuffCount() do
        local tBuff = {}
        Buffer_Get(hPlayer, i - 1, tBuff)
        if tBuff.dwID == tInfo.nBuffID and tBuff.dwSkillSrcID == tInfo.nSrcTargetID then
            return tBuff
        end
    end
end

function BuffMonitorForceBase.GetImagePath(dwFullyType, hSrcTarget, nSrcTargetID, szSuffix)
    local szPath, nFrame

    if dwFullyType == TARGET.NPC then
        if not hSrcTarget then
            return
        end
        local dwModelID = hSrcTarget.dwModelID

        local szProtraitPath = NPC_GetProtrait(dwModelID)
        local szHeadImageFilePath = NPC_GetHeadImageFile(dwModelID)
        if szProtraitPath and IsImageFileExist(szProtraitPath) then
            szPath = szProtraitPath
        else
            szPath = szHeadImageFilePath
        end

        if IsImageFileExist(szPath) then
            nFrame = true
        else
            szPath, nFrame = NpcData.GetNpcHeadImage(nSrcTargetID)
        end
    elseif dwFullyType == TARGET.PLAYER then
        szPath = UIHelper.GetSchoolIcon(hSrcTarget.dwSchoolID)
    end
    return szPath
end

function BuffMonitorForceBase.GetBuffLeftFrame(nIndex)
    local tInfo = m_tMonitorList[nIndex]
    local tBuff = self.GetBuff(tInfo)
    if tBuff then
        return Buffer_GetLeftFrame(tBuff) or 0
    end
    return 0
end

function BuffMonitorForceBase.GetMaxNum()
    return m_nMaxNum
end

function BuffMonitorForceBase.ReInit()
    local tInfo = m_tMonitorList[1]
    if not tInfo then
        return
    end

    local szPathName = tInfo.tLine.szIniName
    if _G[szPathName] and _G[szPathName].Close then
        _G[szPathName].Close()
    end

    local tOld = clone(m_tMonitorList)
    m_tMonitorList = {}
    for k, v in ipairs(tOld) do
        OnAddMonitorTarget(v.nSrcTargetID, v.nStackNum, v.nEndFrame, v.nBuffID, v.nBuffLevel)
    end
end

Event.Reg(BuffMonitorForceBase, EventType.OnClientPlayerEnter, OnKungfuMount)
Event.Reg(BuffMonitorForceBase, "SKILL_MOUNT_KUNG_FU", OnKungfuMount)