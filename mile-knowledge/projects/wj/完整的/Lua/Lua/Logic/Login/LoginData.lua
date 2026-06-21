g_tbLoginData = {
    --LoginMgr初始化时加载的登录模块列表
    tbModuleList = {
        LoginModule.LOGIN_CONFIG,
        LoginModule.LOGIN_LOGO,
        LoginModule.LOGIN_DOWNLOAD,
        LoginModule.LOGIN_SCENE,
        LoginModule.LOGIN_CAMERA,
        LoginModule.LOGIN_SDK,
        LoginModule.LOGIN_ACCOUNT,
        LoginModule.LOGIN_GATEWAY,
        LoginModule.LOGIN_SERVERLIST,
        LoginModule.LOGIN_ROLE,
        LoginModule.LOGIN_ROLELIST,
        LoginModule.LOGIN_ENTERGAME,
    },
    szStartModule = LoginModule.LOGIN_LOGO, --开始时启用的登录模块
    --服务器列表
    aServerList = {

    },

    --部分静态设置
    bShowDevelopBtn = not Config.bSDKLogin, --是否显示开发按钮
    bIsDevelop = not Config.bSDKLogin, --是否开发版本
    bUseRemoteServerList = not Version.IsBVT(), --使用远程服务器列表
    bShowLogo = true, --Config.bSDKLogin,

    --动态变量
    szCurrentStep = nil, --当前步骤
    LoginView = nil, --登录界面
    tbLoginInfo = {}, --登录信息，若为空表则未登录

    bAutoLogin = false, --是否自动登录 --TODO 提审版本自动登录先关掉
    bRequestServerList = false, --是否正在请求服务器列表
    bRequestServerListSuccess = false, --服务器列表是否请求成功
    bReLoginToRoleListFlag = false, --重登到角色列表
    bVerifyMiBao = false, --删除角色时密保验证
    bIsGetAllRoleListSuccess = false,
    bNotLogout = false,
    bKickAccount = false, --是否被踢出登录
    bXgSdkLoginLostNetworkTryReConnect = false, --西瓜sdk方式登录情况下，在选角界面断网后设置该标志，并立即尝试重连。若成功，则清除。若重连失败，将清除该标志，并提示回到登录界面

    GetDevServerList = function()
        if G_UIServerListTab == nil then
            local szData = Lib.GetStringFromFile(LoginServerDef.DevServerList)
	        if szData then
                szData = GBKToUTF8(szData)
                local tbServerList = LoginServerDef.ParseServerListString(szData)
                G_UIServerListTab = {}
                for k, v in ipairs(tbServerList) do
                    table.insert(G_UIServerListTab, v)
                end
            end
        end

        return G_UIServerListTab
    end,
}