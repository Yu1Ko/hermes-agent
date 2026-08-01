-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: VagabondData
-- Date: 2023-04-10 15:50:28
-- Desc: ?
-- ---------------------------------------------------------------------------------

VagabondData = VagabondData or {}
local self = VagabondData
-------------------------------- 消息定义 --------------------------------
VagabondData.Event = {}
VagabondData.Event.XXX = "VagabondData.Msg.XXX"
local tbDataInfo = {}

function VagabondData.Init(tbSelectionInfo, nTargetType, nTargetID, nLeftCanGet)
    self.InitData(tbSelectionInfo, nTargetType, nTargetID, nLeftCanGet)
    if not UIMgr.IsViewOpened(VIEW_ID.PanelChooseLv) then
        UIMgr.Open(VIEW_ID.PanelChooseLv, tbDataInfo)
    end
end

function VagabondData.UnInit()
    
end

function VagabondData.OnLogin()
    
end

function VagabondData.OnFirstLoadEnd()
    
end

function VagabondData.InitData(tbSelectionInfo, nTargetType, nTargetID, nLeftCanGet)
    tbDataInfo = {}
    tbDataInfo.nTargetType = nTargetType
    tbDataInfo.nTargetID = nTargetID
    tbDataInfo.nLeftCanGet = nLeftCanGet
    tbDataInfo.tInfo = {}
    for _, tInfo in ipairs(tbSelectionInfo) do
        local tLine = Table_GetVagabondStartInfo(tInfo.dwID)
        if tLine then
            tbDataInfo.nCurrentID = tbDataInfo.nCurrentID or tInfo.dwID
            tLine.dwID = tInfo.dwID
            table.insert(tbDataInfo.tInfo, tLine)
            if tInfo.nPlayerNum then
                tbDataInfo.nCurrentID = tInfo.dwID
                tbDataInfo.nSaveSelectionID = tInfo.dwID
                tbDataInfo.nPlayerNum = tInfo.nPlayerNum
            end
        end
    end
end

function VagabondData.UpdateTipWndMsg(bNewSave, tPlayerState)
    local pTeam = GetClientTeam()
    self.bNewSave = bNewSave
    self.bCanStart = true
    for _, tMsg in pairs(tPlayerState) do
        local pTeammate = GetPlayer(tMsg.dwID)
        if pTeam and not pTeammate then
            pTeammate = {szName = pTeam.GetClientTeamMemberName(tMsg.dwID)}
        end
        tMsg.szName = pTeammate.szName
        tMsg.szErrorType = tMsg.szErrorType or "NoLimit"
        if tMsg.szErrorType ~= "NoLimit" then
            self.bCanStart = false
        end
    end
    self.tPlayerState = tPlayerState
end

function VagabondData.GetPlayerNum()
    return tbDataInfo.nPlayerNum
end

function VagabondData.GetNewSave()
    return self.bNewSave
end

function VagabondData.GetCanStart()
    return self.bCanStart
end

function VagabondData.GetPlayerState()
    return self.tPlayerState
end

function VagabondData.GetDataInfo()
    return tbDataInfo
end

function VagabondData.GetCurrentID()
    return tbDataInfo.nCurrentID
end

function VagabondData.GetSaveSelectionID()
    return tbDataInfo.nSaveSelectionID
end

function VagabondData.GetCurDataInfo()
    return self.GetDataInfoByDWID(tbDataInfo.nCurrentID)
end

function VagabondData.GetDataInfoByDWID(dwID)
    for index, tbInfo in ipairs(tbDataInfo.tInfo) do
        if tbInfo.dwID == dwID then
            return tbInfo
        end
    end
    return nil
end

function VagabondData.SetCurrentID(dwID)
    tbDataInfo.nCurrentID = dwID
end