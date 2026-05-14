-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: ChatCommand
-- Date: 2024-6-11 14:32:49
-- Desc: 聊天命令 /roll 这种
-- ---------------------------------------------------------------------------------

ChatCommand = ChatCommand or {className = "ChatCommand"}
local self = ChatCommand
self.tbCMD = {}
self.tbHelper = {}

function ChatCommand.RegCMD(szKey, func, szHelper)
    if string.is_nil(szKey) then return end

    self.tbCMD[szKey] = func
    self.tbHelper[szKey] = szHelper
end

function ChatCommand.UnRegCMD(szKey)
    if string.is_nil(szKey) then return end

    self.tbCMD[szKey] = nil
    self.tbHelper[szKey] = nil
end

function ChatCommand.ParseCMD(szInput)
    local bResult = false

    if not string.is_nil(szInput) then
        local tbSplit = string.split(szInput, " ") -- 先空格分隔
        if tbSplit and #tbSplit >=1 then
            local szCmd = table.remove(tbSplit, 1)
            if string.sub(szCmd, 1, 1) == "/" then
                szCmd = string.sub(szCmd, 2, string.len(szCmd))
                if not string.is_nil(szCmd) then
                    local funcCMD = self.tbCMD[szCmd]
                    if IsFunction(funcCMD) then
                        funcCMD(unpack(tbSplit))
                        bResult = true
                    end
                end
            end
        end
    end

    return bResult
end


-- /roll
function ChatCommand._cmd_roll(szRollNumber)
    self.nLastRollTime = self.nLastRollTime or 0

    local nCurrentTime = GetCurrentTime()
	if nCurrentTime - self.nLastRollTime < 2 then
		return
	end

	self.nLastRollTime = nCurrentTime

	if szRollNumber == "help" or szRollNumber == "?" or szRollNumber == "ˋ" then
		OutputMessage("MSG_SYS", self.tbHelper["roll"] .. "\n")
		return
	end

	local nDefaultMin, nDefaultMax = 1, 100

	if not szRollNumber or szRollNumber == "" then
		RemoteCallToServer("ClientNormalRoll", nDefaultMin, nDefaultMax)
		return
	end

	local szRolllow, szRollHigh = szRollNumber:match("^%s*(%d+)%s*(%d*)%s*$")

	if not szRolllow or szRolllow == "" then
		RemoteCallToServer("ClientNormalRoll", nDefaultMin, nDefaultMax)
		return
	end

	if not szRollHigh or szRollHigh == "" then
		szRollHigh = szRolllow
		szRolllow = tostring(nDefaultMin)
	end

	local nRolllow = tonumber(szRolllow:sub(1,5))
	local nRollHigh = tonumber(szRollHigh:sub(1,5))

	if nRolllow and nRollHigh and nRolllow < nRollHigh then
		RemoteCallToServer("ClientNormalRoll", nRolllow, nRollHigh)
	else
		RemoteCallToServer("ClientNormalRoll", nDefaultMin, nDefaultMax)
	end
end

-- /played
function ChatCommand._cmd_played()
    self.nLastPlayedCheckTime = self.nLastPlayedCheckTime or 0

	local nCurrentTime = GetCurrentTime()
	if (nCurrentTime - self.nLastPlayedCheckTime) < 1 then
		return
	end

	self.nLastPlayedCheckTime = nCurrentTime

	RemoteCallToServer("OnPlayedCheckCommand")
end

-- /createtime
function ChatCommand._cmd_createtime()
    self.nLastCreateTimeCheckTime = self.nLastCreateTimeCheckTime or 0

	local nCurrentTime = GetCurrentTime()
	if (nCurrentTime - self.nLastCreateTimeCheckTime) < 1 then
		return
	end

	self.nLastCreateTimeCheckTime = nCurrentTime

	RemoteCallToServer("OnCreateTimeCheckCommand")
end






























ChatCommand.RegCMD("played", ChatCommand._cmd_played, g_tStrings.HELPME_PLAYED)
ChatCommand.RegCMD(g_tStrings.COMMAND_PLAYED.PLAYED, ChatCommand._cmd_played, g_tStrings.HELPME_PLAYED)

ChatCommand.RegCMD("createtime", ChatCommand._cmd_createtime, g_tStrings.HELPME_CREATETIME)
ChatCommand.RegCMD(g_tStrings.COMMAND_PLAYED.CREATETIME, ChatCommand._cmd_createtime, g_tStrings.HELPME_CREATETIME)

ChatCommand.RegCMD("roll", ChatCommand._cmd_roll, g_tStrings.HELPME_ROLL)