local LoginLogo = {}
local self = LoginLogo

local NEXT_LOGIN_STEP = LoginModule.LOGIN_SCENE
--local NEXT_LOGIN_STEP = LoginModule.LOGIN_SCENE

function LoginLogo.RegisterEvent()

end

function LoginLogo.OnEnter(szPrevStep)
    self.bCompleted = false

    if g_tbLoginData.bShowLogo and Platform.IsWindows() and not IsWLCloudClient() then
        UpdateCursorSize() -- 初始化鼠标指针大小
        UIMgr.Open(VIEW_ID.PanelLogoVideo, self._onLogoComplete, nil, true, true)
    else
        LoginMgr.SwitchStep(NEXT_LOGIN_STEP)
    end
end

function LoginLogo.OnExit(szNextStep)
    UIMgr.Close(VIEW_ID.PanelLogoVideo)
end

-------------------------------- Public --------------------------------

-------------------------------- Private --------------------------------

function LoginLogo._onLogoComplete()
    if self.bCompleted then return end

    Timer.DelTimer(self, self.nTimerID)
    LoginMgr.SwitchStep(NEXT_LOGIN_STEP)
    self.bCompleted = true
end

return LoginLogo