require("Lua/require.lua")

local logError = LogError

function __G__TRACKBACK__(msg)
    logError("----------------------------------------")
    logError("LUA ERROR: " .. tostring(msg))
    logError(debug.traceback())
    logError("----------------------------------------")
end

local function PatchUpdateConfigHttpFile()
    if Platform.IsMac() and GetVersionCode() == 319173 then
        local szLocalFilePath = GetFullPath("configHttpFile.ini")
        local szURL = "https://jx3v5-update.xoyocdn.com/jx3_v5_mini/mac_mb/configHttpFile.ini"
        CURL_DownloadFile("configHttpFile.ini", szURL, szLocalFilePath, true, 5)
    end
end

local function main()
    if Platform.IsMac() then
        PatchUpdateConfigHttpFile()
    end

	Game.Init()
end

xpcall(main, __G__TRACKBACK__)
