LoginModule = {
    LOGIN_CONFIG        = "LoginConfig",
    LOGIN_LOGO          = "LoginLogo",
    LOGIN_DOWNLOAD      = "LoginDownload",
    LOGIN_SCENE         = "LoginScene",
    LOGIN_CAMERA        = "LoginCamera",
    LOGIN_SDK           = "LoginSDK",
    LOGIN_ACCOUNT       = "LoginAccount",
    LOGIN_SERVERLIST    = "LoginServerList",
    LOGIN_GATEWAY       = "LoginGateway",
    LOGIN_ROLE          = "LoginRole",
    LOGIN_ENTERGAME     = "LoginEnterGame",
    LOGIN_ROLELIST      = "LoginRoleList",
}

LoginModel = {
    ROLE        = 1,
    FORCE_ROLE  = 2, --门派角色预览，目前门派角色预览只显示一个角色
    -- STANDARD_MALE = ROLE_TYPE.STANDARD_MALE, --1
    -- STANDARD_FEMALE = ROLE_TYPE.STANDARD_FEMALE, --2
    -- STRONG_MALE = ROLE_TYPE.STRONG_MALE, --3
    -- SEXY_FEMALE = ROLE_TYPE.SEXY_FEMALE, --4
    -- LITTLE_BOY = ROLE_TYPE.LITTLE_BOY, --5
    -- LITTLE_GIRL = ROLE_TYPE.LITTLE_GIRL, --6
}

--镜头状态
LoginCameraStatus = {
    LOGIN                   = 1,
    ROLE_LIST               = 2,
    BUILD_FACE_STEP1        = 3,
    BUILD_FACE_STEP2_FACE   = 4,
    BUILD_FACE_STEP2_HAIR   = 5,
    BUILD_FACE_STEP2_BODY   = 6,
    BUILD_FACE_STEP2_SHARE   = 7,
    BUILD_FACE_STEP2_BUILDALL   = 8,
    BUILD_FACE_STEP_INPUTNAME   = 9,
    ROLE_CHOOSE_SHOW = 10,
}

LoginServerDef = {
    AutoRegion = "常用", -- 手机上才有的自动选BVT的Region
    AutoServer = "互通BVT", -- 手机上才有的自动选BVT的服务器名

    AutoRegion_SDKTest = "西瓜", -- 切换到SDK登录时自动选SDK测试服的Region
    AutoServer_SDKTest = "西瓜通行证登录服", -- 切换到SDK登录时自动选SDK测试服的服务器名

    DevServerList = "ui/Scheme/Case/serverlist.ini",

    -- serverlist.ini 解析函数
    ParseServerListString = function(szValue)
        if not szValue then
            return
        end

        -- ParseServerListFromString
        local aServerList = {}
        local aIPList = {}
        local tLine = SplitString(szValue, "\n")
        for k, szLine in pairs(tLine) do
            local t = SplitString(szLine, "\r")
            for _, szL in pairs(t) do
                local aServer = SplitString(szL, "\t")
                if aServer[15] then
                    aServer[15] = aServer[15] == "1"
                end

                if not aServer[16] or aServer[16] == "" then
                    aServer[16] = 0
                end

                table.insert(aServerList, aServer)
            end
        end

        return aServerList
    end
}

LoginServerStatus = {
    --COMMEND     = 0, --推荐
    --SMOOTHLY    = 1, --流畅
    --FULL        = 2, --爆满
    SERVICING   = 3, --维护
    IDLE        = 4, --空闲 新的状态有5个，防止和旧的混淆，从状态4重新开始
    SMOOTHLY    = 5, --流畅
    GOOD        = 6, --良好
    BUSY        = 7, --繁忙
    FULL        = 8, --爆满
}

LoginServerStatusText = {
    -- [LoginServerStatus.COMMEND]     = g_tStrings.STR_SERVER_STATUS_COMMEND,
    -- [LoginServerStatus.SMOOTHLY]    = g_tStrings.STR_SERVER_STATUS_SMOOTHLY,
    -- [LoginServerStatus.FULL]        = g_tStrings.STR_SERVER_STATUS_FULL,
    [LoginServerStatus.SERVICING]   = g_tStrings.STR_SERVER_STATUS_SERVICING,
    [LoginServerStatus.IDLE]        = g_tStrings.STR_SERVER_STATUS_IDLE,
    [LoginServerStatus.SMOOTHLY]    = g_tStrings.STR_SERVER_STATUS_SMOOTHLY,
    [LoginServerStatus.GOOD]        = g_tStrings.STR_SERVER_STATUS_GOOD,
    [LoginServerStatus.BUSY]        = g_tStrings.STR_SERVER_STATUS_BUSY,
    [LoginServerStatus.FULL]        = g_tStrings.STR_SERVER_STATUS_FULL,
}


Login_SchoolIndexTopForceID = {
    [1]  =  KUNGFU_ID.DUAN_SHI,
    [2]  =  KUNGFU_ID.CHUN_YANG,
    [3]  =  KUNGFU_ID.QI_XIU,
    [4]  =  KUNGFU_ID.WAN_HUA,
    [5]  =  KUNGFU_ID.TIAN_CE,
    [6]  =  KUNGFU_ID.SHAO_LIN,
    [7]  =  KUNGFU_ID.CANG_JIAN,
    [8]  =  KUNGFU_ID.WU_DU,
    [9]  =  KUNGFU_ID.TANG_MEN,
    [10] =  KUNGFU_ID.MING_JIAO,
    [11] =  KUNGFU_ID.GAI_BANG,
    [12] =  KUNGFU_ID.CANG_YUN,
    [13] =  KUNGFU_ID.CHANG_GE,
    [14] =  KUNGFU_ID.BA_DAO,
    [15] =  KUNGFU_ID.PENG_LAI,
    [16] =  KUNGFU_ID.LING_XUE,
    [17] =  KUNGFU_ID.YAN_TIAN,
    [18] =  KUNGFU_ID.YAO_ZONG,
    [19] =  KUNGFU_ID.DAO_ZONG,
    [20] =  KUNGFU_ID.WAN_LING,
}

LoginEventName = {
    [LOGIN.UNABLE_TO_CONNECT_SERVER]            = g_tStrings.tbLoginString.UNABLE_TO_CONNECT_SERVER,                -- "无法连接服务器"
    [LOGIN.MISS_CONNECTION]                     = g_tStrings.tbLoginString.MISS_CONNECTION,                         -- "服务器连接丢失"
    [LOGIN.SYSTEM_MAINTENANCE]                  = g_tStrings.tbLoginString.SYSTEM_MAINTENANCE,                      -- "系统维护"
    [LOGIN.UNMATCHED_LOGIN_PROTOCOL_VERSION]    = g_tStrings.tbLoginString.UNMATCHED_LOGIN_PROTOCOL_VERSION,        -- "登录协议版本不匹配，请更新"
    [LOGIN.UNMATCHED_GAME_PROTOCOL_VERSION]     = g_tStrings.tbLoginString.UNMATCHED_GAME_PROTOCOL_VERSION,         -- "游戏协议版本不匹配，请更新"
    [LOGIN.UNMATCHED_GAME_RESOURCE_VERSION]     = g_tStrings.tbLoginString.UNMATCHED_GAME_RESOURCE_VERSION,         -- "游戏资源版本不匹配，请更新"
    [LOGIN.ACCOUNT_VERIFY_TOO_FREQUENTLY]       = g_tStrings.tbLoginString.ACCOUNT_VERIFY_TOO_FREQUENTLY,           -- "验证太频繁了，你是脱机外挂吧"
    [LOGIN.BAD_GUY]                             = g_tStrings.tbLoginString.BAD_GUY,                                 -- "系统错误，修改了客户端或者协议"
    [LOGIN.HANDSHAKE_ACCOUNT_SYSTEM_LOST]       = g_tStrings.tbLoginString.HANDSHAKE_ACCOUNT_SYSTEM_LOST,           -- "账号系统在维护，请稍后重试"

    [LOGIN.VERIFY_SUCCESS]                      = g_tStrings.tbLoginString.VERIFY_SUCCESS,                          -- "验证通过,一切顺利"
    [LOGIN.VERIFY_ACC_PSW_ERROR]                = g_tStrings.tbLoginString.VERIFY_ACC_PSW_ERROR,                    -- "账号或者密码错误"
    [LOGIN.VERIFY_NO_MONEY]                     = g_tStrings.tbLoginString.VERIFY_NO_MONEY,                         -- "没钱了"
    [LOGIN.VERIFY_NOT_ACTIVE]                   = g_tStrings.tbLoginString.VERIFY_NOT_ACTIVE,                       -- "账号没有激活"
    [LOGIN.VERIFY_ACTIVATE_CODE_ERR]            = g_tStrings.tbLoginString.VERIFY_ACTIVATE_CODE_ERR,                -- "激活码错误，不存在或已经被使用过了"
    [LOGIN.VERIFY_IN_OTHER_GROUP]               = g_tStrings.tbLoginString.VERIFY_IN_OTHER_GROUP,                   -- "该账号已经在其他区服登录"
    [LOGIN.VERIFY_ACC_FREEZED]                  = g_tStrings.tbLoginString.VERIFY_ACC_FREEZED,                      -- "账号被冻结了"
    [LOGIN.VERIFY_PAYSYS_BLACK_LIST]            = g_tStrings.tbLoginString.VERIFY_PAYSYS_BLACK_LIST,                -- "多次密码错误,账号被Paysys锁进黑名单了"
    [LOGIN.VERIFY_LIMIT_ACCOUNT]                = g_tStrings.tbLoginString.VERIFY_LIMIT_ACCOUNT,                    -- "访沉迷用户，不能登入"
    [LOGIN.VERIFY_LIMIT_FACE_RECOGNITION]       = g_tStrings.tbLoginString.VERIFY_LIMIT_FACE_RECOGNITION,           -- "防沉迷，需要人脸识别验证"
    [LOGIN.VERIFY_ACC_SMS_LOCK]                 = g_tStrings.tbLoginString.VERIFY_ACC_SMS_LOCK,                     -- "账号被用户短信锁定"
    [LOGIN.VERIFY_IN_GAME]                      = g_tStrings.tbLoginString.VERIFY_IN_GAME,                          -- "该账号正在游戏中，请稍后再试"
    [LOGIN.VERIFY_ALREADY_IN_GATEWAY]           = g_tStrings.tbLoginString.VERIFY_ALREADY_IN_GATEWAY,               -- "该账号正在被使用"
    [LOGIN.ACCOUNT_FREEZE_PLAYER_TOKEN]         = g_tStrings.tbLoginString.ACCOUNT_FREEZE_PLAYER_TOKEN,             -- "帐号被手机令牌冻结"
    [LOGIN.ACCOUNT_FREEZE_PLAYER_SMS]           = g_tStrings.tbLoginString.ACCOUNT_FREEZE_PLAYER_SMS,               -- "帐号被短信冻结"
    [LOGIN.ACCOUNT_FREEZE_PLAYER_WEB]           = g_tStrings.tbLoginString.ACCOUNT_FREEZE_PLAYER_WEB,               -- "帐号从官网自助页面被冻结"
    [LOGIN.ACCOUNT_FREEZE_PLAYER_FARMER]        = g_tStrings.tbLoginString.ACCOUNT_FREEZE_PLAYER_FARMER,            -- "疑似工作室，帐号被冻结了"
    [LOGIN.ACCOUNT_VERIFY_TOO_FREQUENTLY]       = g_tStrings.tbLoginString.ACCOUNT_VERIFY_TOO_FREQUENTLY,           -- "验证过于频繁"
    [LOGIN.VERIFY_UNKNOWN_ERROR]                = g_tStrings.tbLoginString.VERIFY_UNKNOWN_ERROR,                    -- "未处理的错误码"
    [LOGIN.VERIFY_REJECT_CLIENT_BY_VERSION]     = g_tStrings.tbLoginString.VERIFY_REJECT_CLIENT_BY_VERSION,         -- "未处理的错误码"

    [LOGIN.UNION_ACCOUNT_VERIFY_HTTP_FAILED]    = g_tStrings.tbLoginString.UNION_ACCOUNT_VERTIFY_FAILED,            -- "登录失败，请稍后重试"
    [LOGIN.UNION_ACCOUNT_VERIFY_FAILED]         = g_tStrings.tbLoginString.UNION_ACCOUNT_VERTIFY_FAILED,            -- "登录失败，请稍后重试"
    [LOGIN.UNION_ACCOUNT_VERIFY_UNKNOWN_FAILED] = g_tStrings.tbLoginString.UNION_ACCOUNT_VERTIFY_FAILED,            -- "登录失败，请稍后重试"

    [LOGIN.CREATE_ROLE_SUCCESS]                 = g_tStrings.tbLoginString.CREATE_ROLE_SUCCESS,                     -- "创建角色成功"
    [LOGIN.CREATE_ROLE_NAME_EXIST]              = g_tStrings.tbLoginString.CREATE_ROLE_NAME_EXIST,                  -- "创建失败,角色名已存在"
    [LOGIN.CREATE_ROLE_INVALID_NAME]            = g_tStrings.tbLoginString.CREATE_ROLE_INVALID_NAME,                -- "创建失败,角色名非法"
    [LOGIN.CREATE_ROLE_NAME_TOO_LONG]           = g_tStrings.tbLoginString.CREATE_ROLE_NAME_TOO_LONG,               -- "创建失败,角色名太长"
    [LOGIN.CREATE_ROLE_NAME_TOO_SHORT]          = g_tStrings.tbLoginString.CREATE_ROLE_NAME_TOO_SHORT,              -- "创建失败,角色名太短"
    [LOGIN.CREATE_ROLE_NEED_OLD_ROLE_MAX_LEVEL] = g_tStrings.tbLoginString.CREATE_ROLE_NEED_OLD_ROLE_MAX_LEVEL,     -- "创建失败，需要至少拥有大于XX级的角色"
    [LOGIN.CREATE_ROLE_LIMIT_BY_IP]             = g_tStrings.tbLoginString.CREATE_ROLE_LIMIT_BY_IP,                 -- "创建失败，此IP无法创建新角色"
    [LOGIN.CREATE_ROLE_UNABLE_TO_CREATE]        = g_tStrings.tbLoginString.CREATE_ROLE_UNABLE_TO_CREATE,            -- "创建失败,无法创建角色"


    [LOGIN.REQUEST_LOGIN_GAME_SUCCESS]          = g_tStrings.tbLoginString.REQUEST_LOGIN_GAME_SUCCESS,              -- "已经取得游戏世界登陆信息，正在连接服务器"
    [LOGIN.REQUEST_LOGIN_GAME_MAINTENANCE]      = g_tStrings.tbLoginString.REQUEST_LOGIN_GAME_MAINTENANCE,          -- "服务器正在维护"
    [LOGIN.REQUEST_LOGIN_GAME_OVERLOAD]         = g_tStrings.tbLoginString.REQUEST_LOGIN_GAME_OVERLOAD,             -- "游戏世界人数已满,稍后再来"
    [LOGIN.REQUEST_LOGIN_GAME_ROLE_LIMIT]       = g_tStrings.tbLoginString.REQUEST_LOGIN_GAME_ROLE_LIMIT,           -- "限制角色登录"
    [LOGIN.REQUEST_LOGIN_GAME_ROLEFREEZE]       = g_tStrings.tbLoginString.REQUEST_LOGIN_GAME_ROLEFREEZE,           -- "该角色已冻结"
    [LOGIN.REQUEST_LOGIN_GAME_SWITCH_CENTER]    = g_tStrings.tbLoginString.REQUEST_LOGIN_GAME_SWITCH_CENTER,        -- "该角色正在转服"
    [LOGIN.REQUEST_LOGIN_GAME_CHANGE_ACCOUNT]   = g_tStrings.tbLoginString.REQUEST_LOGIN_GAME_CHANGE_ACCOUNT,       -- "帐号分离中"
    [LOGIN.REQUEST_LOGIN_GAME_NEED_BIND_PHONE]  = g_tStrings.tbLoginString.REQUEST_LOGIN_GAME_NEED_BIND_PHONE,      -- "帐号需要绑定手机"
    [LOGIN.REQUEST_LOGIN_GAME_UNKNOWN_ERROR]    = g_tStrings.tbLoginString.REQUEST_LOGIN_GAME_UNKNOWN_ERROR,        -- "未处理的其他错误"
    [LOGIN.VERIFY_ROLE_LOGIN_TIME_LIMIT]        = g_tStrings.tbLoginString.VERIFY_ROLE_LOGIN_TIME_LIMIT,            -- "角色当天允许在线时间已用完了"
    [LOGIN.VERIFY_ROLE_INVALID_ROLE_NAME]       = g_tStrings.tbLoginString.VERIFY_ROLE_INVALID_ROLE_NAME,           -- "角色名非法"
    [LOGIN.VERIFY_ROLE_NOT_EXISTS]              = g_tStrings.tbLoginString.VERIFY_ROLE_NOT_EXISTS,                  -- "角色不存在"


    [LOGIN.DELETE_ROLE_DELAY]                    =  g_tStrings.tbLoginString.DELETE_ROLE_DELAY,                     -- 进入延时删除队列
    [LOGIN.DELETE_ROLE_TONG_MASTER]              =  g_tStrings.tbLoginString.DELETE_ROLE_TONG_MASTER,               -- 帮主不允许删除
    [LOGIN.DELETE_ROLE_FREEZE_ROLE]              =  g_tStrings.tbLoginString.DELETE_ROLE_FREEZE_ROLE,               -- 冻结角色不允许删除
    [LOGIN.DELETE_ROLE_SELLING_GAME_CARD]        =  g_tStrings.tbLoginString.DELETE_ROLE_SELLING_GAME_CARD,         -- 有通宝在寄卖，不能删除
    [LOGIN.DELETE_ROLE_HAVE_PEER_PAY_FOR_TAKE]   =  g_tStrings.tbLoginString.DELETE_ROLE_HAVE_PEER_PAY_FOR_TAKE,    -- 有待领取的通宝代付，不能删除
    [LOGIN.DELETE_ROLE_MIBAO_VERIFY_FAILED]      =  g_tStrings.tbLoginString.DELETE_ROLE_MIBAO_VERIFY_FAILED,       -- 密保验证失败
    [LOGIN.DELETE_ROLE_CAPTCHA_VERIFY_TIMEOUT]   =  g_tStrings.tbLoginString.DELETE_ROLE_CAPTCHA_VERIFY_TIMEOUT,    -- 图形验证码验证有效期超时（一般在等待输入令牌时）
    [LOGIN.DELETE_ROLE_SWITCHING_CENTER]         =  g_tStrings.tbLoginString.DELETE_ROLE_SWITCHING_CENTER,          -- 转服中不允许删除角色
    [LOGIN.DELETE_ROLE_HAVE_TONG_BIND_ITEM]      =  g_tStrings.tbLoginString.DELETE_ROLE_HAVE_TONG_BIND_ITEM,       -- 包裹或仓库中有帮会绑定物品，不能删除
    [LOGIN.DELETE_ROLE_HAVE_UNFINISHED_GROUPON]  =  g_tStrings.tbLoginString.DELETE_ROLE_HAVE_UNFINISHED_GROUPON,   -- 有没完成的商城团购，不能删除
    [LOGIN.DELETE_ROLE_UNKNOWN_ERROR]            =  g_tStrings.tbLoginString.DELETE_ROLE_UNKNOWN_ERROR,             -- 不晓得什么原因，反正失败了:)
    [LOGIN.DELETE_ROLE_IN_ASURA_TEAM]            =  g_tStrings.tbLoginString.DELETE_ROLE_IN_ASURA_TEAM,             -- 处于修罗挑战战队中，不能删除]

    [LOGIN.RENAME_NAME_ALREADY_EXIST]               =  g_tStrings.tbLoginString.RENAME_NAME_ALREADY_EXIST,          -- 角色名已存在或处于保护期，请换个名字试试
    [LOGIN.RENAME_NAME_TOO_LONG]                    =  g_tStrings.tbLoginString.RENAME_NAME_TOO_LONG,               -- 你的角色名太长，请输入2-6个汉字
    [LOGIN.RENAME_NAME_TOO_SHORT]                   =  g_tStrings.tbLoginString.RENAME_NAME_TOO_SHORT,              -- 你的角色名太短，请输入2-6个汉字
    [LOGIN.RENAME_NEW_NAME_ERROR]                   =  g_tStrings.tbLoginString.RENAME_NEW_NAME_ERROR,              -- 你的角色名中含有敏感词汇，请重新输入
    [LOGIN.RENAME_ERROR]                            =  g_tStrings.tbLoginString.RENAME_ERROR,                       -- 系统升级中，功能暂不可使用
    [LOGIN.VERIFY_KICK_BY_GM]                       =  g_tStrings.tbLoginString.VERIFY_KICK_BY_GM,                   -- 你被GM踢下线了

}