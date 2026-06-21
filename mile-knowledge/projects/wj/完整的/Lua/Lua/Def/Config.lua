--=================================================================================================
-- Config.ini 的读取操作
--=================================================================================================

Config = Config or {}
Config.PATH = "config.ini"

function Config.SaveVideoSetting()
    local tValue = GameSettingData.GetNewValue(UISettingKey.WindowResolution)
    if tValue and tValue.bNoBoarderFullScreen then
        return  -- 全屏模式不存盘
    end

    local szCustomPath = "customdata/ClientCustom.ini"
    local ini = Ini.Open(szCustomPath, true)
    if not ini then
        ini = Ini.Create()
        if not ini then
            return
        end
    end

    local tVideoSettings = Wnd_GetSaveInfo()
    ini:WriteInteger("Mobile", "nWidth", tVideoSettings.width)
    ini:WriteInteger("Mobile", "nHeight", tVideoSettings.height)
    ini:WriteInteger("Mobile", "nX", tVideoSettings.x)
    ini:WriteInteger("Mobile", "nY", tVideoSettings.y)
    ini:WriteInteger("Mobile", "bMaximize", tVideoSettings.bMaximize)
    ini:Save(szCustomPath)
    ini:Close()
end

local ini = Ini.Open(Config.PATH, true)
if ini then
    Config.bReleaseVerPrintUILog = ini:ReadInteger("Mobile", "bReleaseVerPrintUILog", 0) == 1
    Config.bOptickLuaSample = ini:ReadInteger("Mobile", "bOptickLuaSample", 0) == 1
    Config.bIsCEVer = ini:ReadInteger("Mobile", "bIsCEVer", 0) == 1
    Config.szSimulateDeviceModel = ini:ReadString("Mobile", "szSimulateDeviceModel", "")
    Config.bOpenPerformanceTool = ini:ReadInteger("Mobile", "bOpenPerformanceTool", 0) == 1
    Config.bShowDownloadAll = ini:ReadInteger("Mobile", "bShowDownloadAll", 0) == 1

    if IsKGPublish() then
        Config.bGM = ini:ReadInteger("XGSDK_MobileDebug", "bGM", 0) == 1
        Config.bSDKLogin = true--ini:ReadInteger("XGSDK_MobileDebug", "bSDKLogin", 0) == 1
    else
        Config.bGM = ini:ReadInteger("MobileDebug", "bGM", 0) == 1
        Config.bSDKLogin = ini:ReadInteger("MobileDebug", "bSDKLogin", 0) == 1
    end

    Config.X3DENGINEOPTION = {}
    Config.X3DENGINEOPTION.fCameraFarClip = ini:ReadInteger("X3DENGINEOPTION", "fCameraFarClip", 200000)

    ini:Close()
end


-- 如果是iOS提审版本，那么 bIsCEVer 字段就默认为 false，即iOS提审版本不受 bIsCEVer 影响
if Version.IsIOS() then
    Config.bIsCEVer = false
end

Config.bIsIosReview = Version.IsIOS()
