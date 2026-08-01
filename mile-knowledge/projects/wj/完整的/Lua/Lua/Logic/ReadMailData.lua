-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: ReadMailData
-- Date: 2024-10-16 10:19:51
-- Desc: ?
-- ---------------------------------------------------------------------------------

ReadMailData = ReadMailData or {className = "ReadMailData"}
local self = ReadMailData
-------------------------------- 消息定义 --------------------------------
ReadMailData.Event = {}
ReadMailData.Event.XXX = "ReadMailData.Msg.XXX"

function ReadMailData.Init(nMailID)

    local player = g_pClientPlayer
    if not player then return end

    if nMailID then
        self.nMailID = nMailID
        self.tbPanelInfo = Table_GetReadMailPanelInfo(nMailID)
    else
        self.tbPanelInfo = Table_GetReadMailPanelInfo(player.dwForceID)
    end
end

function ReadMailData.UnInit()
    
end

function ReadMailData.OnLogin()
    
end

function ReadMailData.OnFirstLoadEnd()
    
end

function ReadMailData.EncodeString(szText)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return szText
    end

    return string.gsub(szText, "%[PlayerName%]", UIHelper.GBKToUTF8(pPlayer.szName))
end

function ReadMailData.GetMailInfo()
    return self.tbPanelInfo
end