-- UI全屏特效
-- 一次只支持一个全屏特效

local tbNameToScaleMap =
{
    ["ROB_TRAP_SFX_3"] = 3
}


local UIFullScreenSfxView = class("UIFullScreenSfxView")

function UIFullScreenSfxView:OnEnter(szSfxName)
    self.szSfxName = szSfxName

    local tbSFXInfoMap = Table_GetFullScreenSFXInfo()
    local nLayer = 1
    if tbSFXInfoMap[szSfxName] then
        self.szPath, self.szPathMobile, self.szDisableMapID = tbSFXInfoMap[szSfxName].File, tbSFXInfoMap[szSfxName].FileMobile, ""
        nLayer = tbSFXInfoMap[szSfxName].nLayer
    else
        self.szPath, self.szPathMobile, self.szDisableMapID = Table_GetPath(szSfxName)
    end
    if self.nLayer and nLayer < self.nLayer then return end--优先级低的不能顶掉优先级高的

    self.nLayer = nLayer
    self.nAlpha = 255
    self.nAngle = 0
    self.nYaw = 0
    self.bShowOnce = true
    self.bStateFrame = true
    self.nScale = 1
    self.nOffsetX = 0
    self.nOffsetY = 100
    self.nTime = Const.FullScreenSFXTime[self.szSfxName]

    UIHelper.SetLocalZOrder(self._rootNode, -1)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIFullScreenSfxView:OnExit()

end

function UIFullScreenSfxView:BindUIEvent()

end

function UIFullScreenSfxView:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        self:UpdateScale()
    end)
    Event.Reg(self, "OnCCSFXPlayEnded", function(nModelID)
        if self.WidgetSFX:GetSFXModel() == nModelID then
            self:OnPlayEnded()
        end
    end)
end

function UIFullScreenSfxView:UpdateInfo()
    self:UpdateScale()

    UIHelper.SetVisible(self.LabelError, false)
    UIHelper.SetVisible(self.WidgetSFX, false)

    -- 1. VK端特效只支持.pss格式
    -- 2. 默认读取移动端路径，如果移动端路径为空则读取szPath
    local szSFXPath = self.szPathMobile

    if string.is_nil(szSFXPath) then
        szSFXPath = self.szPath
    end

    if Config.bGM and string.is_nil(szSFXPath) then
        LOG.ERROR(string.format("FullScreenSFX Error, [name] = %s", tostring(self.szSfxName)))
        -- UIHelper.SetVisible(self.LabelError, true)
        -- UIHelper.SetString(self.LabelError, string.format("FullScreenSFX Error, [name] = %s", self.szSfxName))
        return
    end

    if Config.bGM and string.sub(szSFXPath, -4) ~= ".pss" then
        local szError = string.format("FullScreenSFX Error, [name] = %s\n[path] = %s", tostring(self.szSfxName), tostring(szSFXPath))
        LOG.ERROR(szError)

        -- UIHelper.SetVisible(self.LabelError, true)
        -- UIHelper.SetString(self.LabelError, GBKToUTF8(szError))
        return
    end

    if not self:CheckCanPlay() then
        return
    end

    UIHelper.SetVisible(self.WidgetSFX, true)
    if Platform.IsWindows() and tbNameToScaleMap[self.szSfxName] then
        self.WidgetSFX:SetScaleSensitive(true)
    end
    self.WidgetSFX:LoadSfx(szSFXPath, self.nAlpha, self.nAngle, self.nYaw, (self.bShowOnce and 1 or 0), (self.bStateFrame and 1 or 0))

    Timer.DelTimer(self, self.nTimerID)
    if self.nTime then
        self.nTimerID = Timer.Add(self, self.nTime, function()
            UIMgr.Close(self)
        end)
    end
end

function UIFullScreenSfxView:UpdateScale()
    if Platform.IsWindows() then
        --local nScaleX, nScaleY = UIHelper.GetScreenToDesignScale()
        local nScale = tbNameToScaleMap[self.szSfxName] or 0.92
        UIHelper.SetScale(self.WidgetParent, nScale, nScale)
    end
end

function UIFullScreenSfxView:CheckCanPlay()
    local bResult = true

    self.tbDisableMapIDs = {}
    if not string.is_nil(self.szDisableMapID) then
        self.tbDisableMapIDs = string.split(self.szDisableMapID, ",") or {}
        if g_pClientPlayer then
            local dwMapID = g_pClientPlayer.GetMapID()
            bResult = not table.contain_value(self.tbDisableMapIDs, tostring(dwMapID))
        end
    end

    return bResult
end

function UIFullScreenSfxView:OnPlayEnded()
    self.nLayer = 0
end

return UIFullScreenSfxView
