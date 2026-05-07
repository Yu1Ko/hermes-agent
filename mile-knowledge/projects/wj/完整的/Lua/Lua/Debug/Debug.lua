Debug = {className = "Debug"}
Debug.bOpenDebug = Config.bGM

local self = Debug
local IS_DEV_ENV = cc.FileUtils:getInstance():isDirectoryExist("DebugFiles")

function Debug.Init()
    if Platform.IsWindows() then
        if Debug.bOpenDebug then
            local backup = package.cpath
            package.cpath = package.cpath .. ';mui\\Lua\\Debug\\packages\\?.dll'
            require("Lua/Debug/LuaPanda.lua").start("127.0.0.1", 8818)
            package.cpath = backup

            if Config.bOpenPerformanceTool then
                if not IsDebug() and not IsKGPublish() and Debug.IsDevEnv() then
                    if cc.FileUtils:getInstance():isFileExist("interface/PerformanceCollect/PerformanceCollectEx.lua") then
                        require("interface/PerformanceCollect/PerformanceCollectEx.lua")
                    end
                end
            end
        end
    end

    KG3DEngine.SetMobileEngineOption({bRenderUIDebug = Storage.Debug.bShowDebugInfo})

    if Config.bGM then
        Event.Reg(self, EventType.OnKeyboardDown, function(nKeyCode, szKeyName)
            if nKeyCode == cc.KeyCode.KEY_ALT then
                self.bAlt = true
            elseif nKeyCode == cc.KeyCode.KEY_CTRL then
                self.bCtrl = true
            end

            if self.bAlt and self.bCtrl then
                self.StartSearchSceneObject()
            end
        end)

        Event.Reg(self, EventType.OnKeyboardUp, function(nKeyCode, szKeyName)
            if nKeyCode == cc.KeyCode.KEY_ALT then
                self.bAlt = false
                self.StopSearchSceneObject()
            elseif nKeyCode == cc.KeyCode.KEY_CTRL then
                self.bCtrl = false
                self.StopSearchSceneObject()
            end
        end)

        Event.Reg(self, "OnWindowsLostFocus", function()
            self.bAlt = false
            self.bCtrl = false
            self.StopSearchSceneObject()
        end)
    end
end

function Debug.UnInit()

end

function Debug.IsDevEnv()
    return IS_DEV_ENV
end

function Debug.DisplayMemoryInfo()
    local szTitle = "UI相关内存信息"
    local nLuaMem = collectgarbage("count") / 1024

    -- 简要信息
    local szLuaMem = string.format("Lua: %.3fMB", nLuaMem)

    local szTextureInfo = GBKToUTF8(cc.Director:getInstance():getTextureCache():getCachedTextureInfo())
    local tbTextureInfo = string.split(szTextureInfo, "\n")
    local szTextureMem = tbTextureInfo[#tbTextureInfo - 1]

    local szFontInfo = GBKToUTF8(GetFontAtlasCacheInfo())
    local tbFontInfo = string.split(szFontInfo, "\n")
    local szFontMem = tbFontInfo[#tbFontInfo - 1]

    local szBreifInfo = string.format("%s\n%s\n%s\n\n", szLuaMem, szTextureMem, szFontMem)


    -- 详细信息
    local szDetailLuaMem = "[Lua内存] -------------------\n"
    szDetailLuaMem = szDetailLuaMem .. string.format("current lua stack memory = %.3fM\n", nLuaMem)

    local szDetailTextureMem = "[纹理内存] -------------------\n"
    szDetailTextureMem = szDetailTextureMem .. string.format("%s\n", szTextureInfo)

    local szDetailFontMem = "[字体内存] -------------------\n"
    szDetailFontMem = szDetailFontMem .. string.format("%s\n", szFontInfo)

    local szDetailInfo = string.format("%s\n%s\n%s", szDetailLuaMem, szDetailTextureMem, szDetailFontMem)

    local szContent = szBreifInfo .. szDetailInfo
    UIMgr.Open(VIEW_ID.PanelInfoPop, szTitle, szContent)
end

function Debug.DisplayDeviceInfo()
    local szTitle = "设备相关内存信息"
    local szContent = "OS: " .. tostring(GetDeviceOS()) .. "\n"
    szContent = szContent .. "GPU: " .. tostring(GetDeviceGPU()) .. "\n"
    szContent = szContent .. "DeviceModel: " .. tostring(GetDeviceModel()) .. "\n"
    szContent = szContent .. "IsSimulator: " .. tostring(IsSimulator()) .. "\n"
    szContent = szContent .. "NotchHeight: " .. tostring(GetNotchHeight()) .. "\n"
    szContent = szContent .. "RealNotchHeight: " .. tostring(GetRealNotchHeight()) .. "\n"
    szContent = szContent .. "HomeIndicatorHeight: " .. tostring(GetHomeIndicatorHeight()) .. "\n"
    szContent = szContent .. "DeviceScreenSize: w = " .. tostring(GetDeviceScreenSize().width) .. ", h = " .. tostring(GetDeviceScreenSize().height) .. "\n"
    szContent = szContent .. "DeviceIsPadModel: " .. tostring(Device.GetDeviceIsPadModel()) .. "\n"
    szContent = szContent .. "TotalMemorySize: " .. string.format("%0.2f", Device.GetDeviceTotalMemorySize(true)) .. " GB\n"
	szContent = szContent .. "AvailableMemorySize: " .. string.format("%0.2f", Device.GetDeviceAvailableMemorySize(true)) .. " GB\n"
    szContent = szContent .. "BatteryTemperature: " .. string.format("%0.2f", App_GetBatteryTemperature()) .."℃\n"
    szContent = szContent .. "IsTouchScreenSupported: " .. tostring(Device.IsTouchScreenSupported()) .. "\n"
    UIMgr.Open(VIEW_ID.PanelInfoPop, szTitle, szContent)
end

function Debug.DisplayUISizeInfo()
    local szTitle = "UI各种尺寸相关信息"
    local szContent = "DeviceScreenSize: w = " .. tostring(GetDeviceScreenSize().width) .. ", h = " .. tostring(GetDeviceScreenSize().height) .. "\n"
    szContent = szContent .. "UIHelper.GetScreenSize(): w = " .. tostring(UIHelper.GetScreenSize().width) .. ", h = " .. tostring(UIHelper.GetScreenSize().height) .. "\n"
    local nX, nY = UIHelper.GetScreenToResolutionScale()
    szContent = szContent .. "UIHelper.GetScreenToResolutionScale(): x = " .. tostring(nX) .. ", y = " .. tostring(nY) .. "\n"
    szContent = szContent .. "UIHelper.GetWinSize(): w = " .. tostring(UIHelper.GetWinSize().width) .. ", h = " .. tostring(UIHelper.GetWinSize().height) .. "\n"
    szContent = szContent .. "UIHelper.GetWinSizeInPixels(): w = " .. tostring(UIHelper.GetWinSizeInPixels().width) .. ", h = " .. tostring(UIHelper.GetWinSizeInPixels().height) .. "\n"
    szContent = szContent .. "UIHelper.GetSafeAreaRect(): w = " .. tostring(UIHelper.GetSafeAreaRect().width) .. ", h = " .. tostring(UIHelper.GetSafeAreaRect().height) .. "\n"
    szContent = szContent .. "UIHelper.GetDesignResolutionSize(): w = " .. tostring(UIHelper.GetDesignResolutionSize().width) .. ", h = " .. tostring(UIHelper.GetDesignResolutionSize().height) .. "\n"
    szContent = szContent .. "UIHelper.GetCurResolutionSize(): w = " .. tostring(UIHelper.GetCurResolutionSize().width) .. ", h = " .. tostring(UIHelper.GetCurResolutionSize().height) .. "\n"
    szContent = szContent .. "Device.IsPad(): = "..tostring(Device.IsPad()) .. "\n"

    UIMgr.Open(VIEW_ID.PanelInfoPop, szTitle, szContent)
end

function Debug.DisplayClientVerSionInfo()
    local szResourceVersion= GetPakV5Version() or 0
    local szVersionLineFullName, szVersion, szVersionLineName, szVersionEx, szVersionName = GetVersion()
    local ServerListUrl = GetServerListUrl()
    local szTitle ="客户端版本信息和version_vk.cfg"
    local szContent = string.format('szVersion:%s\nszResourceVersion:%s\nszVersionLineFullName:%s\nszVersionLineName:%s\nszVersionEx:%s\nszVersionName:%s\nServerListUrl:%s',
    szVersion, szResourceVersion, szVersionLineFullName, szVersionLineName, szVersionEx, UIHelper.GBKToUTF8(szVersionName), ServerListUrl)
    UIMgr.Open(VIEW_ID.PanelInfoPop, szTitle, szContent)
end

function Debug.StartSearchSceneObject()
    Timer.DelTimer(self, self.nTimerID)
    self.nTimerID = Timer.AddFrameCycle(self, 1, function()
        local tCursor = GetViewCursorPoint()
        local player = g_pClientPlayer
        local tPos = cc.Director:getInstance():convertToGL({ x = tCursor.x, y = tCursor.y })
        local nScaleX, nScaleY = UIHelper.GetScreenToResolutionScale()
        local tSelectObject = Scene_SelectObjectsX3D(tPos.x * nScaleX, tPos.y * nScaleY)
        local nTargetType, nTargetID = TARGET.NO_TARGET, 0
        for _, obj in pairs(tSelectObject or {}) do
            if self._canSelect(obj.Type, obj.ID) then
                nTargetType, nTargetID = obj.Type, obj.ID
                self._showTips(nTargetType, nTargetID, tCursor)
                break
            end
        end

    end)
end

function Debug.StopSearchSceneObject()
    Timer.DelTimer(self, self.nTimerID)
    self.nDisplayType = nil
    self.nDisplayID = nil

    Timer.Add(self, 1, function()
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipsWithSubtitle)
    end)
end

function Debug._canSelect(dwType, dwID)
    local bSel = false

	if dwType == TARGET.NPC then
        local npc = GetNpc(dwID)
        if npc and npc.IsSelectable() then
            bSel = true
        end
    elseif dwType == TARGET.DOODAD then
        local doodad = GetDoodad(dwID)
        if doodad and doodad.IsSelectable() then
            -- local player = GetClientPlayer()
            -- local bQuestDoodad = doodad.nKind == DOODAD_KIND.QUEST
            -- if bQuestDoodad and doodad.HaveQuest(player.dwID) then
            --     bSel = true
            -- end
            bSel = true
        end
    end

	return bSel
end

function Debug._showTips(nTargetType, nTargetID, tPos)
    if nTargetType == TARGET.NPC then

        if self.nDisplayType ~= nTargetType or self.nDisplayID ~= nTargetID then
            local szTitle, szContent = OutputNpcTip(nTargetID)
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipsWithSubtitle)
            TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetTipsWithSubtitle, tPos.x, tPos.y, "", szTitle, szContent)
        end

        self.nDisplayType = nTargetType
        self.nDisplayID = nTargetID
    elseif nTargetType == TARGET.DOODAD then

        if self.nDisplayType ~= nTargetType or  self.nDisplayID ~= nTargetID then
            local szTitle, szContent = OutputDoodadTip(nTargetID)
            szContent = ParseTextHelper.ParseNormalText(szContent)
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipsWithSubtitle)
            TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetTipsWithSubtitle, tPos.x, tPos.y, "", szTitle, szContent)
        end

        self.nDisplayType = nTargetType
        self.nDisplayID = nTargetID
    end

end
