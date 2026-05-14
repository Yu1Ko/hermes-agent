-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISceneSfx
-- Date: 2023-04-26 19:45:53
-- Desc: ?
-- ---------------------------------------------------------------------------------
local tbNameToScaleMap =
{
    ["ROB_TRAP_SFX_3"] = 3
}

local UISceneSfx = class("UISceneSfx")

function UISceneSfx:OnEnter(tbOpt)
    self.tbOpt = tbOpt

    self.szSfxName = tbOpt.sfxid
    self.szPath = Table_GetPath(self.szSfxName)
    self.nAlpha = 255
    self.nAngle = 0
    self.nYaw = 0
    self.bLoop = tbOpt.loop
    self.bStateFrame = true
    self.nScale = 1
    self.nOffsetX = tbOpt.x
    self.nOffsetY = tbOpt.y

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UISceneSfx:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISceneSfx:BindUIEvent()

end

function UISceneSfx:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        self:UpdateScale()
    end)
end

function UISceneSfx:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISceneSfx:UpdateInfo()
    self:UpdateScale()

    UIHelper.SetVisible(self.WidgetSFX, false)

    if string.is_nil(self.szPath) then
        return
    end

    if string.sub(self.szPath, -4) ~= ".pss" then
        local szError = string.format("UISceneSfx Play Error, name = %s\n[path] = %s", self.szSfxName, self.szPath)
        LOG.ERROR(szError)
        return
    end

    UIHelper.SetVisible(self.WidgetSFX, true)
    Timer.AddFrame(self, 1, function()
        UIHelper.SetPosition(self.WidgetSFX, self.nOffsetX or 0, self.nOffsetY or 0)
    end)
    -- UIHelper.SetPosition(self.WidgetSFX, self.nOffsetX, self.nOffsetY)
    self.WidgetSFX:LoadSfx(self.szPath, self.nAlpha, self.nAngle, self.nYaw, (self.bLoop and 0 or 1), (self.bStateFrame and 1 or 0))
end

function UISceneSfx:UpdateScale()
    if Platform.IsWindows() or Platform.IsMac() then
        --local nScaleX, nScaleY = UIHelper.GetScreenToDesignScale()
        local nScale = tbNameToScaleMap[self.szSfxName] or 0.92
        UIHelper.SetScale(self.WidgetSFX, nScale, nScale)
    end
end


return UISceneSfx