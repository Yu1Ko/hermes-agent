LoginMgr = LoginMgr or {className = "LoginMgr"}

LoginMgr.bIsLog = true -- 是否打印信息的开关
LoginMgr.bFirstLoadEnding = false -- 客户端第一次登录

local m_tbLoginNotifyFuncs = {} --<nLoginState, tbFuncList>
local m_tbModuleDict = {} --<szModuleName, tbModuleScript>
local m_bIsWaiting = false
local m_nWaitingTimerID = nil
local m_nWaitTime = 0
local m_szCurWaitingMsg = ""
local MAX_WAIT_TIME = 15

local m_nAutoKickTimerID = nil
local m_nAutoKickTime = nil
--local m_bIsSwitchingExit = false --备用：防止OnExit中调用SwitchStep

function LoginMgr.Init()
    require("Lua/Logic/Login/LoginData.lua")

    --初始化所有模块
    local bIsAllModuleOK = true
    for i = 1, #g_tbLoginData.tbModuleList do
        local szModuleName = g_tbLoginData.tbModuleList[i]
        --pcall 防止卡流程
        local bOK, szRet = pcall(LoginMgr._loadModule, szModuleName)
        if not bOK then
            bIsAllModuleOK = false
            LOG.ERROR("[LoginMgr] Login Module [%s] Load Error: %s", szModuleName, szRet)
        end
    end
    LoginMgr.Log("LoginMgr", "All Login Modules are Loaded Successfully.")

    Event.Reg(LoginMgr, "LOGIN_NOTIFY", LoginMgr._loginHandle)
    Event.Reg(LoginMgr, EventType.OnAppPreQuit, LoginMgr.Clear)
end

function LoginMgr.UnInit()
    LoginMgr.Clear()
    Event.UnReg(LoginMgr)
end

function LoginMgr._loadModule(szModuleName)
    local module = require("Lua/Logic/Login/Module/" .. szModuleName .. ".lua")
    if module then
        m_tbModuleDict[szModuleName] = module
        module._szModuleName = szModuleName
        module.RegisterEvent()
    end
end

function LoginMgr._loginHandle(nLoginState, ...)
    local tbFuncList = m_tbLoginNotifyFuncs[nLoginState]
    if tbFuncList then
        for i = 1, #tbFuncList do
            tbFuncList[i](...)
        end
    else
        LOG.WARN("[LoginMgr] An Unregistered LOGIN_NOTIFY: %d", nLoginState)
    end
end

function LoginMgr.Start(...)
    --NOTE：如果进游戏这里出现报错：attempt to index global 'g_tbLoginData' (a nil value)，
    --说明游戏初始化Game.Init()未正常完成，请把log翻到更前面看下有没有别的报错
    if not g_tbLoginData then
        LOG.ERROR("LoginData Init Failed!!! Game.Init() Error. Please Check [LUA ERROR] Log Upper.")
    end

    if (XGSDK_HasPackedChannel and XGSDK_HasPackedChannel()) or (Platform.IsWindows() and not g_tbLoginData.bIsDevelop) then
        if XGSDK_IsInitSuccess() or g_tbLoginData.bIsDevelop then
            LoginMgr.SwitchStep(g_tbLoginData.szStartModule, ...)
        else
            local tArg = {...}
            UIMgr.Open(VIEW_ID.PanelFullScreenPic)
            Event.Reg(LoginMgr, "XGSDK_OnInitSuccess", function()
                --延迟一帧，否则UI无法正常关闭
                Timer.AddFrame(LoginMgr, 1, function()
                    UIMgr.Close(VIEW_ID.PanelFullScreenPic)
                    LoginMgr.SwitchStep(g_tbLoginData.szStartModule, table.unpack(tArg))
                end)
            end)
        end
    else
        LoginMgr.SwitchStep(g_tbLoginData.szStartModule, ...)
    end
end

--切换到Step
function LoginMgr.SwitchStep(szEnterModule, ...)
    --备用：防止OnExit中调用SwitchStep
    -- if m_bIsSwitchingExit then
    --     LOG.ERROR("[LoginMgr] Can't Switch Step on Module Exit. ")
    -- end
    local moduleEnter = LoginMgr.GetModule(szEnterModule)
    if moduleEnter then
        local szExitModule = g_tbLoginData.szCurrentStep
        local moduleExit = szExitModule and LoginMgr.GetModule(szExitModule)
        if moduleExit then
            LoginMgr.Log("LoginMgr", "SwitchStep: [%s] -> [%s]" ,szExitModule, szEnterModule)
            szExitModule = moduleExit._szModuleName

            if szEnterModule == szExitModule then
                --LOG.WARN("[LoginMgr] EnterModule and ExitModule is same module: [%s]", szEnterModule)
            end

            if moduleExit.OnExit then
                --备用：防止OnExit中报错导致m_bIsSwitchingExit无法恢复
                -- m_bIsSwitchingExit = true
                -- pcall(
                --     function()
                --         tbExitModule.OnExit(szEnterModule)
                --     end
                -- )
                -- m_bIsSwitchingExit = false

                moduleExit.OnExit(szEnterModule)
            end
        else
            LoginMgr.Log("LoginMgr", "SwitchStep: -> [%s]", szEnterModule)
        end
        g_tbLoginData.szCurrentStep = szEnterModule

        if moduleEnter.OnEnter then
            moduleEnter.OnEnter(szExitModule, ...)
        end
    else
        LOG.ERROR("[LoginMgr] Enter Module does not exist: [%s]", (szEnterModule or "nil"))
    end
end

--注册登录回调事件
function LoginMgr.RegisterLoginNotify(nLoginState, func)
    if not m_tbLoginNotifyFuncs[nLoginState] then
        m_tbLoginNotifyFuncs[nLoginState] = {}
    end
    table.insert(m_tbLoginNotifyFuncs[nLoginState], func)
end

--清除登录回调事件
function LoginMgr.ClearLoginNotify(nLoginState)
    if nLoginState and m_tbLoginNotifyFuncs[nLoginState] then
        m_tbLoginNotifyFuncs[nLoginState] = {}
    else
        m_tbLoginNotifyFuncs = {}
    end
end

--获取LoginModule
function LoginMgr.GetModule(szModuleName)
    if szModuleName then
        return m_tbModuleDict[szModuleName]
    end
end

--Clear
function LoginMgr.Clear(...)
    LOG.INFO("[LoginMgr] Clear")
    for szModuleName, module in pairs(m_tbModuleDict) do
        if module and module.OnClear then
            module.OnClear(...)
        end
    end
    LoginMgr.SetWaiting(false)
    LoginMgr.ClearAutoKick()
    --m_tbModuleDict = {}
    --LoginMgr.ClearLoginNotify() --事件先不清，在游戏里退出账号重新登录之后要用
end

--设置阻塞，防止同时发多条协议
function LoginMgr.SetWaiting(bIsWaiting, szWaitingMsg, fnTimeOut, fnSetWaiting)
    --LOG.INFO("[LoginMgr] SetWaiting, %s, %s", tostring(bIsWaiting), debug.traceback())
    if m_bIsWaiting and bIsWaiting then
        local nLeftTime = MAX_WAIT_TIME - (Timer.GetTime() - m_nWaitTime)
        --LoginMgr.ErrorMsg("LoginMgr", "Currently waiting: [%s], can't send. Remaining time: %d seconds", m_szCurWaitingMsg, nLeftTime)
        LOG.INFO("LoginMgr, Currently waiting: [%s], can't send. Remaining time: %d seconds", m_szCurWaitingMsg, nLeftTime)
        return false
    else
        if m_nWaitingTimerID then
            Timer.DelTimer(LoginMgr, m_nWaitingTimerID)
            m_nWaitingTimerID = nil
        end

        if bIsWaiting then
            --超时取消阻塞状态
            m_nWaitTime = Timer.GetTime()
            m_nWaitingTimerID = Timer.Add(LoginMgr, MAX_WAIT_TIME, function()
                m_bIsWaiting = false
                m_nWaitingTimerID = nil

                if fnTimeOut then
                    fnTimeOut()
                else
                    TipsHelper.ShowNormalTip("等待消息超时，请重试")
                    LoginMgr._setWaitingView(false, szWaitingMsg)
                end
            end)
        end
    end
    m_bIsWaiting = bIsWaiting
    m_szCurWaitingMsg = szWaitingMsg or ""
    if fnSetWaiting then
        fnSetWaiting(bIsWaiting)
    else
        LoginMgr._setWaitingView(bIsWaiting, szWaitingMsg)
    end
    return true
end

--获取等待状态
function LoginMgr.IsWaiting()
    return m_bIsWaiting
end

--返回登录
function LoginMgr.BackToLogin(bNotLogout)
    g_tbLoginData.bNotLogout = bNotLogout or false
    ---@see LoginGateway#OnEnter
    LoginMgr.SwitchStep(LoginModule.LOGIN_GATEWAY)
end

function LoginMgr.IsLogin()
    if g_tbLoginData.bIsDevelop then
        return not table.is_empty(g_tbLoginData.tbLoginInfo)
    else
        local moduleSDK = LoginMgr.GetModule(LoginModule.LOGIN_SDK)
        return moduleSDK.GetAuthInfo() ~= nil
    end
end

--设置等待UI
function LoginMgr._setWaitingView(bIsWaiting, szWaitingMsg)
    if bIsWaiting then
        local tMsg = {
            szType = "LoginWaiting",
            szWaitingMsg = szWaitingMsg,
            nPriority = 1,
            bHidePage = true,
            bSwallow = true,
        }
        WaitingTipsData.PushWaitingTips(tMsg)
    else
        WaitingTipsData.RemoveWaitingTips("LoginWaiting")
    end
end

function LoginMgr.StartAutoKick(nTimeSec)
    if AppReviewMgr.IsReview() then
        return
    end

    LoginMgr.ClearAutoKick()
    nTimeSec = nTimeSec or 15 * 60 --默认15分钟
    LOG.INFO("[LoginMgr] StartAutoKick, nTimeSec: %d", nTimeSec)
    m_nAutoKickTimerID = Timer.AddCycle(LoginMgr, 5, function()
        local nCurTime = Timer.GetTime()
        local bIsWaiting = WaitingTipsData.GetMsgByType("LoginQueue") or WaitingTipsData.GetMsgByType("LoginQueue_WQPN")
        if nCurTime - m_nAutoKickTime >= nTimeSec and not bIsWaiting then
            LoginMgr.ClearAutoKick()
            LoginMgr.BackToLogin(true)
            local dialog = UIHelper.ShowConfirm("检测到客户端长时间无操作，为了账号安全，请重新登录\n（正在下载的资源包不受影响）")
            dialog:HideCancelButton()
        end
    end)
    LoginMgr.UpdateAutoKick()

    Event.Reg(LoginMgr, EventType.OnSceneTouchBegan, LoginMgr.UpdateAutoKick)
    Event.Reg(LoginMgr, EventType.OnWindowsMouseWheel, LoginMgr.UpdateAutoKick)
    Event.Reg(LoginMgr, EventType.OnWidgetTouchDown, LoginMgr.UpdateAutoKick)
end

function LoginMgr.UpdateAutoKick()
    if not m_nAutoKickTimerID then
        return
    end

    --LOG.INFO("[LoginMgr] UpdateAutoKick")
    m_nAutoKickTime = Timer.GetTime()
end

function LoginMgr.ClearAutoKick()
    LOG.INFO("[LoginMgr] ClearAutoKick")
    Timer.DelTimer(LoginMgr, m_nAutoKickTimerID)
    m_nAutoKickTimerID = nil
    m_nAutoKickTime = nil

    Event.UnReg(LoginMgr, EventType.OnSceneTouchBegan)
    Event.UnReg(LoginMgr, EventType.OnWindowsMouseWheel)
    Event.UnReg(LoginMgr, EventType.OnWidgetTouchDown)
end

function LoginMgr.IsInGame()
    local moduleEnterGame = LoginMgr.GetModule(LoginModule.LOGIN_ENTERGAME)
    if not moduleEnterGame then
        return false
    end
    local szRoleName = moduleEnterGame.GetCurRoleInfo()
    return not string.is_nil(szRoleName)
end

 ---------------- 打印相关 ----------------

function LoginMgr.ErrorMsg(script, szErrorFormat, ...)
    szErrorFormat = szErrorFormat or ""
    local title = LoginMgr._getLogTitle(script)
    LOG.ERROR(title .. szErrorFormat, ...)

    local szErrorInfo = string.format(szErrorFormat, ...)
    TipsHelper.ShowNormalTip(szErrorInfo)
end

function LoginMgr.Log(script, szFormat, ...)
    if not LoginMgr.bIsLog then return end

    szFormat = szFormat or ""
    local title = LoginMgr._getLogTitle(script)
    LOG.INFO(title .. szFormat, ...)
end

function LoginMgr._getLogTitle(script)
    if script then
        if type(script) == "string" then
            return "[" .. script .. "] "
        elseif type(script) == "table" and script._szModuleName then
            return "[" .. script._szModuleName .. "] "
        end
    end
    return ""
end

return LoginMgr
