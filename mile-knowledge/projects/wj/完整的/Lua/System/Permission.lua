Permission = Permission or {className = "Permission"}


-- ---------------------------------------
-- 权限定义 和C++ EPermission 同步
Permission.Camera = 0
Permission.ExternalStorageRead = 1
Permission.ExternalStorageWrite = 2
Permission.Microphone = 3
Permission.CoarseLocation = 4
Permission.FineLocation = 5
-- ---------------------------------------

local PermissionTypeToName =
{
    [Permission.Camera] = "相机",
    [Permission.ExternalStorageRead] = "存储",
    [Permission.ExternalStorageWrite] = "相册",
    [Permission.Microphone] = "麦克风",
    [Permission.CoarseLocation] = "定位",
    [Permission.FineLocation] = "定位",
}

local PermissionTypeToFunction =
{
    [Permission.Camera] = "？",
    [Permission.ExternalStorageRead] = "？",
    [Permission.ExternalStorageWrite] = "幻境云图",
    [Permission.Microphone] = "语音",
    [Permission.CoarseLocation] = "？",
    [Permission.FineLocation] = "？",
}

AddRequestPermissionCallback()
Event.Reg(Permission, "OnRequestPermissionCallback_CPP", function(nPermission, bResult)
    LOG.INFO("Permission.OnRequestPermissionCallback_CPP, nPermission = %s, bResult = %s", tostring(nPermission), tostring(bResult))

    Timer.Add(Permission, 0.1, function()
        Storage.Permission.tbHasAsked[nPermission] = true
        Storage.Permission.Flush()

        Event.Dispatch("OnRequestPermissionCallback", nPermission, bResult)
    end)
end)


-- 请求设备权限
function Permission.RequestUserPermission(nPermission, szFunctionName)
    LOG.INFO("Permission.RequestUserPermission, nPermission = "..tostring(nPermission))

    local szPermissionName = PermissionTypeToName[nPermission]
    szFunctionName = szFunctionName or PermissionTypeToFunction[nPermission]
    local szContent = string.format("为了正常使用%s功能，需要获取您的%s权限。", szFunctionName, szPermissionName)

    local scriptView = UIHelper.ShowConfirm(szContent, function()
        RequestUserPermission(nPermission)
    end)

    scriptView:HideButton("Cancel")
    scriptView:SetButtonContent("Confirm", "好的")
end

-- 查看设备权限是否已授权
function Permission.CheckPermission(nPermission)
    LOG.INFO("Permission.CheckPermission, nPermission = "..tostring(nPermission))
    return CheckPermission(nPermission)
end

-- 打开App权限管理页面
function Permission.SwitchToAppPermissionSetting()
    LOG.INFO("Permission.SwitchToAppPermissionSetting")
    SwitchToAppPermissionSetting()
end

-- 检查权限是否之前询问过
function Permission.CheckHasAsked(nPermission)
    if Platform.IsMac() then
        return false
    end

    return Storage.Permission.tbHasAsked[nPermission]
end

-- 二次确认是否打开APP的权限管理页面
function Permission.AskForSwitchToAppPermissionSetting(nPermission)
    local szContent = string.format("%s权限暂未开启，确定前往设置权限？", PermissionTypeToName[nPermission])
    UIHelper.ShowConfirm(szContent, function()
        Permission.SwitchToAppPermissionSetting()
    end)
end