--[[
	Date:		2022-10-13
	Author: 	huqing
	Purpose: 	所在平台
--]]

Platform = Platform or {}

Platform._platform = cc.Application:getInstance():getTargetPlatform()



function Platform.IsWindows()
    return Platform._platform == cc.PLATFORM_OS_WINDOWS
end

function Platform.IsIos()
    return (Platform._platform == cc.PLATFORM_OS_IPHONE or Platform._platform == cc.PLATFORM_OS_IPAD)
end

function Platform.IsAndroid()
    return Platform._platform == cc.PLATFORM_OS_ANDROID
end

function Platform.IsOHOS()
    return Platform._platform == cc.PLATFORM_OS_OHOS
end

function Platform.IsMobile()
    return Platform.IsAndroid() or Platform.IsIos() or Platform.IsOHOS()
end

function Platform.IsIPad()
    return Platform._platform == cc.PLATFORM_OS_IPAD
end

function Platform.IsMac()
    return Platform._platform == cc.PLATFORM_OS_MAC
end

function Platform.GetPlatformName()
    local szName = ""

    if Platform.IsWindows() then
        szName = "windows"
    elseif Platform.IsIos() then
        szName = "ios"
    elseif Platform.IsAndroid() then
        szName = "android"
    elseif Platform.IsMac() then
        szName = "mac"
    elseif Platform.IsOHOS() then
        szName = "ohos"
    end

    return szName
end

function Platform.CheckIsDeviceSupport()
    local nErrorCode = KG3DEngine.GetDeviceNotSupportCode and KG3DEngine.GetDeviceNotSupportCode()
    if nErrorCode and g_tStrings.tDeviceNotSupportCode[nErrorCode] then
        local szErrorMsg = g_tStrings.tDeviceNotSupportCode[nErrorCode]
        local confirm = UIHelper.ShowSystemConfirm(szErrorMsg, function () end)
        LOG.ERROR(string.format("KG3DEngine.GetDeviceNotSupportCode: %s", szErrorMsg))
        confirm:HideButton("Cancel")

        return
    end

    if Device.IsUnderIOS15() then
        if not APIHelper.GlobalIsDid("LOING_CHECK_IOS_VER") then
            local szContent = "经检测您的iOS版本过低，为了获得最佳游戏体验\n建议您升级最新iOS版本进行游戏。"
            local dialog = UIHelper.ShowSystemConfirm(szContent, function() end)
            dialog:HideButton("Cancel")

            APIHelper.GlobalDo("LOING_CHECK_IOS_VER")
        end
        return
    end
end

-- 是否是蔚领云游戏的客户端
function Platform.IsWLColud()
    return Platform.WLCloudIsAndroid() or Platform.WLCloudIsIos()
end

-- 蔚领云游戏APP 对应的是 Android平台
function Platform.WLCloudIsAndroid()
    return Channel.Is_WLColud() and WLCloudPlatformIsAndroid()
end

-- 蔚领云游戏APP 对应的是 iOS平台
function Platform.WLCloudIsIos()
    return Channel.Is_WLColud() and WLCloudPlatformIsIos()
end