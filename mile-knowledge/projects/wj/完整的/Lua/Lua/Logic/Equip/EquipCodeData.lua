EquipCodeData = EquipCodeData or {className = "EquipCodeData"}
local self = EquipCodeData

EquipCodeData.nMaxRoleSetCount = 4

-- 功能总开关
local bEnabled = true
local WEB_URL_TEST = "https://test-ws.xoyo.com"
local WEB_URL = "https://ws.xoyo.com"
local LOGIN_TIME_OUT_LIMIT = 120

local PostKey = {
    LOGIN_ACCOUNT_EQUIPCODE         = "LOGIN_ACCOUNT_EQUIPCODE",
    UPLOAD_EQUIPS_BY_GAME           = "UPLOAD_EQUIPS_BY_GAME",
    MY_EQUIPS_LIST                  = "MY_EQUIPS_LIST",
    GET_EQUIPS                      = "GET_EQUIPS",
    DEL_EQUIPS                      = "DEL_EQUIPS",
    EQUIPS_LIST                     = "EQUIPS_LIST",
    ROLE_EQUIPS_UPLOAD              = "ROLE_EQUIPS_UPLOAD",
    ROLE_EQUIPS_LIST                = "ROLE_EQUIPS_LIST",
    ROLE_EQUIPS_UPDATE              = "ROLE_EQUIPS_UPDATE",
    ROLE_EQUIPS_DEL                 = "ROLE_EQUIPS_DEL",
}

local PostUrl = {
    LOGIN_ACCOUNT_EQUIPCODE = "/core/jx3tools/get_current_account",
    UPLOAD_EQUIPS_BY_GAME   = "/jx3/equipsupload240711/upload_equips_by_game",
    MY_EQUIPS_LIST          = "/jx3/equipsupload240711/my_equips_list",
    GET_EQUIPS              = "/jx3/equipsupload240711/get_equips",
    DEL_EQUIPS              = "/jx3/equipsupload240711/del_equips",
    EQUIPS_LIST             = "/jx3/equipsupload240711/equips_list",
    ROLE_EQUIPS_UPLOAD      = "/jx3/equipsupload240711/role_equips_upload",
    ROLE_EQUIPS_LIST        = "/jx3/equipsupload240711/role_equips_list",
    ROLE_EQUIPS_UPDATE      = "/jx3/equipsupload240711/role_equips_update",
    ROLE_EQUIPS_DEL         = "/jx3/equipsupload240711/role_equips_del",
}

local ApplyLoginSignWebID = 3102

local STATUS_CODE = {
    [1] = "成功",
    [0] = "系统错误",
    [-10151] = "活动未开启",
    [-10152] = "活动配置错误",
    [-10153] = "活动未开始",
    [-10154] = "活动已结束",
    [-10201] = "系统处理中",
    [-10701] = "未知驱动",
    [-14801] = "数据不合法",
    [-14802] = "登录态过期，请重新打开界面",
    [-14803] = "参数缺失",
    [-20101] = "角色不能为空",
    [-20102] = "大区不能为空",
    [-20103] = "账号不存在",
    [-20104] = "您分享的配装信息已达到上限",
    [-20105] = "赛季信息不能为空",
    [-20106] = "标题不能为空",
    [-20107] = "游戏大区不能为空",
    [-20108] = "服务器不能为空",
    [-20109] = "门派不能为空",
    [-20110] = "心法id不能为空",
    [-20111] = "心法名称不能为空",
    [-20112] = "装分不能为空",
    [-20113] = "配装信息不能为空",
    [-20114] = "上传配装信息异常，请稍后再重试！",
    [-20115] = "缺少分享id！",
    [-20116] = "配装信息不存在",
    [-20122] = "角色ID信息缺失",
    [-20123] = "您的个人配装数量已达上限",
    [-20124] = "请选择删除的记录",
    [-20125] = "配装记录不存在",
    [-20126] = "标题长度过长",
    [-20127] = "标题包含敏感词，请更换后再提交",
}

function EquipCodeData.Init()
    EquipCodeData.tCurEquip = nil
    EquipCodeData.tRoleEquips = nil
    EquipCodeData.tRecommendEquips = nil
    EquipCodeData.szSessionID = nil
    EquipCodeData.bReqLogin = false
    EquipCodeData.nLastLoginTime = 0

    EquipCodeData.RegEvent()
end

function EquipCodeData.UnInit()
    EquipCodeData.tCurEquip = nil
    EquipCodeData.tRoleEquips = nil
    EquipCodeData.tRecommendEquips = nil
    EquipCodeData.szSessionID = nil
    EquipCodeData.bReqLogin = false
    EquipCodeData.nLastLoginTime = 0

    Event.UnRegAll(EquipCodeData)
end

function EquipCodeData.RegEvent()
    Event.Reg(EquipCodeData, "LOGIN_NOTIFY", function(nEvent)
        if not bEnabled then return end

		if nEvent == LOGIN.REQUEST_LOGIN_GAME_SUCCESS or nEvent == LOGIN.MISS_CONNECTION then
            EquipCodeData.bInitRoleEquipData = false
            EquipCodeData.bReqLogin = false
            EquipCodeData.tRoleEquips = nil
            EquipCodeData.tRecommendEquips = nil
            EquipCodeData.nLastLoginTime = 0
		end
    end)

    Event.Reg(EquipCodeData, "WEB_SIGN_NOTIFY", function()
        if not bEnabled then return end

		if arg3 == 3 then
			EquipCodeData.OnLoginWebDataSignNotify()
		end
    end)

    Event.Reg(EquipCodeData, "ON_WEB_DATA_SIGN_NOTIFY", function()
        if not bEnabled then return end

		EquipCodeData.OnWebDataSignNotify()
    end)

    Event.Reg(EquipCodeData, "CURL_REQUEST_RESULT", function ()
        if not bEnabled then return end

		local szKey = arg0
		local bSuccess = arg1
		local szValue = arg2
		local uBufSize = arg3

        local bVaildKey = false
        for _, key in pairs(PostKey) do
            if szKey == key then
                bVaildKey = true
                break
            end
        end
        if not bVaildKey then
            return
        end

        if not bSuccess then
            LOG.ERROR("EquipCodeData CURL_REQUEST_RESULT FAILED!szKey:%s", szKey)
            return
        end

        local tInfo, szErrMsg = JsonDecode(szValue)
        if tInfo and tInfo.code and tInfo.code ~= 1 and STATUS_CODE[tInfo.code] then
            -- 提审服打开商店会弹这个提示，但实际上并不影响商店使用，所以这里做个特殊处理
            if not AppReviewMgr.IsReview() then
                TipsHelper.ShowNormalTip(STATUS_CODE[tInfo.code])
            end
        end

        if tInfo.code == -14802 and GetCurrentTime() - EquipCodeData.nLastLoginTime > LOGIN_TIME_OUT_LIMIT then
            EquipCodeData.nLastLoginTime = GetCurrentTime()
            EquipCodeData.bReqLogin = true
            EquipCodeData.LoginAccount(false)
        end

        if szKey == PostKey.LOGIN_ACCOUNT_EQUIPCODE then
            local tData = tInfo.data
            if tData then
                EquipCodeData.szSessionID = tData.session_id

                if not EquipCodeData.bInitRoleEquipData and EquipCodeData.bReqLogin then
                    EquipCodeData.ReqGetRoleEquipList()
                end
            end
        elseif szKey == PostKey.UPLOAD_EQUIPS_BY_GAME then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tData = tInfo.data
                if tData then
                    UIMgr.Open(VIEW_ID.PanelShareSetCodePop, tData.share_id)
                end
            end
        elseif szKey == PostKey.MY_EQUIPS_LIST then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tData = tInfo.data
                if tData then
                    EquipCodeData.tMyEquips = tData.list
                end
                Event.Dispatch(EventType.OnUpdateEquipCodeList)
            end
        elseif szKey == PostKey.GET_EQUIPS then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tData = tInfo.data
                if tData then
                    EquipCodeData.ImportCustomizedSetEquip(tData.equips, false)
                    TipsHelper.ShowNormalTip("已成功导入云端配装")
                end
            end
        elseif szKey == PostKey.DEL_EQUIPS then
            if tInfo and tInfo.code and tInfo.code == 1 then
                TipsHelper.ShowNormalTip("已删除云端配装")
            end
            EquipCodeData.ReqGetMyEquipList()
        elseif szKey == PostKey.EQUIPS_LIST then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tData = tInfo.data
                if tData then
                    EquipCodeData.tRecommendEquips = tData.list
                end
            end
        elseif szKey == PostKey.ROLE_EQUIPS_UPLOAD then
            if tInfo and tInfo.code and tInfo.code == 1 then
                TipsHelper.ShowNormalTip("已上传配装")
                EquipCodeData.ReqGetRoleEquipList()
            end
        elseif szKey == PostKey.ROLE_EQUIPS_LIST then
            if tInfo and tInfo.code and tInfo.code == 1 then
                local tData = tInfo.data
                if tData then
                    EquipCodeData.bInitRoleEquipData = true
                    EquipCodeData.SetRoleEquipData(tData.list)
                    EquipCodeData.InitCustomizedSetData()
                end
            end
        elseif szKey == PostKey.ROLE_EQUIPS_UPDATE then
            if tInfo and tInfo.code and tInfo.code == 1 then
                TipsHelper.ShowNormalTip("已更新配装")
                EquipCodeData.ReqGetRoleEquipList()
            end
        elseif szKey == PostKey.ROLE_EQUIPS_DEL then
            if tInfo and tInfo.code and tInfo.code == 1 then
                TipsHelper.ShowNormalTip("已删除配装")
                EquipCodeData.ReqGetRoleEquipList()
            end
        end

        -- LOG.TABLE({tInfo = tInfo, szKey = szKey})
        Event.Dispatch(EventType.OnEquipCodeRsp, szKey, tInfo)
    end)
end

function EquipCodeData.GetURL()
	local bTestMode = IsDebugClient() or IsVersionExp()
    if bTestMode then
        return WEB_URL_TEST
    end

    return WEB_URL
end

function EquipCodeData.LoginAccount(bIsLogin)
    if not bEnabled then return end

    if bIsLogin then
        WebUrl.ApplyLoginSignWeb(ApplyLoginSignWebID, 3)
    else
        WebUrl.ApplySignWeb(ApplyLoginSignWebID, WEB_DATA_SIGN_RQST.LOGIN)
    end
end

function EquipCodeData.ReqUploadEquip(szTitle, nKungFuID, szKungFuName, szSchoolName, nScore, szTags, tData)
    if not bEnabled then return end
    if not EquipCodeData.CheckIsEditAllowed() then return end

    if not EquipCodeData.szSessionID then
        LOG.ERROR("EquipCodeData.ReqGetEquipList Error! szSessionID is nil")
        return
    end

    local player = PlayerData.GetClientPlayer()
    if not player then return end

    szSeason = szSeason or UIHelper.GBKToUTF8(tStrCreditsVersion[#tStrCreditsVersion][1])
    nKungFuID = nKungFuID or PlayerData.GetPlayerMountKungfuID()
    szTags = szTags or "PVP"

    local nHeat = 0
    local szUserRegion, szUserSever = WebUrl.GetServerName()
    local szRoleName = UIHelper.GBKToUTF8(player.szName)

    local szEquip = JsonEncode(tData)
    local szUrl = EquipCodeData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s&season=%s&title=%s&role_name=%s&zone=%s&server=%s&kungfu_id=%d&kungfu_name=%s&force=%s&tags=%s&score=%d&heat=%d&equips=%s",
        szUrl,
        PostUrl.UPLOAD_EQUIPS_BY_GAME,
        EquipCodeData.szSessionID,
        UrlEncode(szSeason),
        UrlEncode(szTitle),
        UrlEncode(szRoleName),
        UrlEncode(szUserRegion),
        UrlEncode(szUserSever),
        nKungFuID,
        UrlEncode(szKungFuName),
        UrlEncode(szSchoolName),
        UrlEncode(szTags),
        nScore,
        nHeat,
        szEquip
    )

    LOG.INFO("-------EquipCodeData.ReqUploadEquip------szPostUrl:%s", szPostUrl)
    CURL_HttpPost(PostKey.UPLOAD_EQUIPS_BY_GAME, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function EquipCodeData.ReqGetMyEquipList()
    if not bEnabled then return end

    if not EquipCodeData.szSessionID then
        LOG.ERROR("EquipCodeData.ReqGetEquipList Error! szSessionID is nil")
        return
    end

    local szUrl = EquipCodeData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s", szUrl, PostUrl.MY_EQUIPS_LIST, EquipCodeData.szSessionID)
    LOG.INFO("-------EquipCodeData.ReqGetMyEquipList------szPostUrl:%s", szPostUrl)
    CURL_HttpPost(PostKey.MY_EQUIPS_LIST, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function EquipCodeData.ReqGetRecommendEquipList(szSeason, szSchoolName, nKungFuID, szTags, nLimit)
    if not bEnabled then return end

    if not EquipCodeData.szSessionID then
        LOG.ERROR("EquipCodeData.ReqGetEquipList Error! szSessionID is nil")
        return
    end

    szSeason = szSeason or UIHelper.GBKToUTF8(tStrCreditsVersion[#tStrCreditsVersion][1])
    szSchoolName = szSchoolName or PlayerData.GetMountBelongSchoolName()
    nKungFuID = nKungFuID or PlayerData.GetPlayerMountKungfuID()
    szTags = szTags or "PVP"
    nLimit = nLimit or 10

    local szUrl = EquipCodeData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s&season=%s&force=%s&kungfu_id=%d&tags=%s&limit=%d",
        szUrl,
        PostUrl.EQUIPS_LIST,
        EquipCodeData.szSessionID,
        UrlEncode(szSeason),
        UrlEncode(szSchoolName),
        nKungFuID,
        UrlEncode(szTags),
        nLimit
    )
    LOG.INFO("-------EquipCodeData.ReqGetRecommendEquipList------szPostUrl:%s", szPostUrl)
    CURL_HttpPost(PostKey.EQUIPS_LIST, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function EquipCodeData.ReqGetEquip(szEquipCode)
    if not bEnabled then return end

    if not EquipCodeData.szSessionID then
        LOG.ERROR("EquipCodeData.ReqGetEquip Error! szSessionID is nil")
        return
    end

    if string.is_nil(szEquipCode) then
        LOG.ERROR("EquipCodeData.ReqGetEquip Error! szEquipCode is nil")
        return
    end

    local szUrl = EquipCodeData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s&share_id=%s",
        szUrl,
        PostUrl.GET_EQUIPS,
        EquipCodeData.szSessionID,
        szEquipCode)
    LOG.INFO("-------EquipCodeData.ReqGetEquip------szPostUrl:%s", szPostUrl)
    CURL_HttpPost(PostKey.GET_EQUIPS, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function EquipCodeData.ReqDelEquip(tbCodes)
    if not bEnabled then return end

    if not EquipCodeData.szSessionID then
        LOG.ERROR("EquipCodeData.ReqGetEquip Error! szSessionID is nil")
        return
    end

    local szCodes = ""
    for _, szCode in ipairs(tbCodes) do
        if szCodes == "" then
            szCodes = szCodes .. szCode
        else
            szCodes = szCodes .. "," .. szCode
        end
    end

    local szUrl = EquipCodeData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s&share_ids=%s",
        szUrl,
        PostUrl.DEL_EQUIPS,
        EquipCodeData.szSessionID,
        szCodes)
    LOG.INFO("-------EquipCodeData.ReqDelEquip------szPostUrl:%s", szPostUrl)
    CURL_HttpPost(PostKey.DEL_EQUIPS, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function EquipCodeData.ReqUploadRoleEquips(szTitle, szKungFuName, nScore, tData)
    if not bEnabled then return end
    if not EquipCodeData.CheckIsEditAllowed() then return end

    if not EquipCodeData.szSessionID then
        LOG.ERROR("EquipCodeData.ReqUploadRoleEquips Error! szSessionID is nil")
        return
    end

    if string.is_nil(szTitle) then
        LOG.ERROR("EquipCodeData.ReqUploadRoleEquips Error! szTitle is nil")
        return
    end

    local szEquip
    if type(tData) == "string" then
        szEquip = tData
    else
        szEquip = JsonEncode(tData)
    end

    local szUrl = EquipCodeData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s&title=%s&kungfu_name=%s&score=%s&equips=%s",
        szUrl,
        PostUrl.ROLE_EQUIPS_UPLOAD,
        EquipCodeData.szSessionID,
        UrlEncode(szTitle),
        UrlEncode(szKungFuName),
        nScore,
        szEquip)
    LOG.INFO("-------EquipCodeData.ReqUploadRoleEquips------szPostUrl:%s", szPostUrl)
    CURL_HttpPost(PostKey.ROLE_EQUIPS_UPLOAD, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function EquipCodeData.ReqGetRoleEquipList()
    if not bEnabled then return end

    local player = PlayerData.GetClientPlayer()
    if not player then
        return
    end

    if not EquipCodeData.szSessionID then
        LOG.ERROR("EquipCodeData.ReqGetRoleEquipList Error! szSessionID is nil")
        return
    end

    local szUrl = EquipCodeData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s",
        szUrl,
        PostUrl.ROLE_EQUIPS_LIST,
        EquipCodeData.szSessionID)
    LOG.INFO("-------EquipCodeData.ReqGetRoleEquipList------szPostUrl:%s", szPostUrl)
    CURL_HttpPost(PostKey.ROLE_EQUIPS_LIST, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function EquipCodeData.ReqUpdateRoleEquips(nID, szTitle, szKungFuName, nScore, tData)
    if not bEnabled then return end
    if not EquipCodeData.CheckIsEditAllowed() then return end

    if not EquipCodeData.szSessionID then
        LOG.ERROR("EquipCodeData.ReqUpdateRoleEquips Error! szSessionID is nil")
        return
    end

    if not nID then
        LOG.ERROR("EquipCodeData.ReqUpdateRoleEquips Error! nID is nil")
        return
    end

    if string.is_nil(szTitle) then
        LOG.ERROR("EquipCodeData.ReqUpdateRoleEquips Error! szTitle is nil")
        return
    end

    local szEquip
    if type(tData) == "string" then
        szEquip = tData
    else
        szEquip = JsonEncode(tData)
    end

    local szUrl = EquipCodeData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s&id=%d&title=%s&kungfu_name=%s&score=%d&equips=%s",
        szUrl,
        PostUrl.ROLE_EQUIPS_UPDATE,
        EquipCodeData.szSessionID,
        nID,
        UrlEncode(szTitle),
        UrlEncode(szKungFuName),
        nScore,
        szEquip)
    LOG.INFO("-------EquipCodeData.ReqUpdateRoleEquips------szPostUrl:%s", szPostUrl)
    CURL_HttpPost(PostKey.ROLE_EQUIPS_UPDATE, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function EquipCodeData.ReqDelRoleEquip(nID)
    if not bEnabled then return end

    if not EquipCodeData.szSessionID then
        LOG.ERROR("EquipCodeData.ReqDelRoleEquip Error! szSessionID is nil")
        return
    end

    if not nID then
        LOG.ERROR("EquipCodeData.ReqDelRoleEquip Error! nID is nil")
        return
    end

    local szUrl = EquipCodeData.GetURL()
    local szPostUrl = string.format("%s%s?session_id=%s&id=%d",
        szUrl,
        PostUrl.ROLE_EQUIPS_DEL,
        EquipCodeData.szSessionID,
        nID
)
    LOG.INFO("-------EquipCodeData.ReqDelRoleEquip------szPostUrl:%s", szPostUrl)
    CURL_HttpPost(PostKey.ROLE_EQUIPS_DEL, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function EquipCodeData.OnWebDataSignNotify()
    local szComment = arg6
	local dwApplyWebID = szComment:match("APPLY_WEBID_(.*)")
	if dwApplyWebID then
		dwApplyWebID = tonumber(dwApplyWebID)
        if dwApplyWebID ~= ApplyLoginSignWebID then
            return
        end
		local uSign = arg0
		local nTime = arg2
		local nZoneID = arg3
		local dwCenterID = arg4
		EquipCodeData.OnLoginAccount(dwApplyWebID, uSign, nTime, nZoneID, dwCenterID, false)
	end
end

function EquipCodeData.OnLoginWebDataSignNotify()
    local szComment = arg2
	local dwApplyWebID = szComment:match("APPLY_LOGIN_WEBID_(.*)")
	if dwApplyWebID then
		dwApplyWebID = tonumber(dwApplyWebID)
        if dwApplyWebID ~= ApplyLoginSignWebID then
            return
        end
		local uSign = arg0
		local nTime = arg1
		local nZoneID = 0
		local dwCenterID = 0
		EquipCodeData.OnLoginAccount(dwApplyWebID, uSign, nTime, nZoneID, dwCenterID, true)
	end
end

function EquipCodeData.OnLoginAccount(dwID, uSign, nTime, nZoneID, dwCenterID, bLogin)
    local dwPlayerID = 0
    local dwForceID = 0
    local szRoleName = ""
    local dwCreateTime = 0
    local szGlobalID = ""
	local szAccount = Login_GetAccount()
    local szDefaultParam

    if bLogin then
        szDefaultParam = "params=%d/%s//%d///////%d/%d"
	    szDefaultParam = string.format(szDefaultParam, uSign, szAccount, nTime, dwCreateTime, GetAccountType())
    else
        local player = PlayerData.GetClientPlayer()
        if player then
            dwPlayerID = player.dwID
            dwForceID = player.dwForceID
            szRoleName =  UrlEncode(UIHelper.GBKToUTF8(player.szName))
            dwCreateTime = player.GetCreateTime()
            szGlobalID = player.GetGlobalID()
        end

        local szUserRegion, szUserSever = WebUrl.GetServerName()
        --param=sign/account/roleID/time/zoneID/centerID/测试区/测试服/门派ID/角色名称/角色创建时间/账号类型
        szDefaultParam = "params=%d/%s/%d/%d/%d/%d/%s/%s/%d/%s/%d/%d"
        szDefaultParam = string.format(
            szDefaultParam, uSign, szAccount, dwPlayerID, nTime, nZoneID,
            dwCenterID, UrlEncode(szUserRegion), UrlEncode(szUserSever),
            dwForceID, szRoleName, dwCreateTime, GetAccountType()
        )
    end

    EquipCodeData.szDefaultParam = szDefaultParam

    local nValidateCheckType = 1 --是否开启区服校验（内网和国际服不开启）
    if IsDebugClient() or IsVersionTW() then
        nValidateCheckType = 0
    end

    local szUrl = EquipCodeData.GetURL()
    local szPostUrl = string.format("%s%s?%s&validate_zone_server=%d", szUrl, PostUrl.LOGIN_ACCOUNT_EQUIPCODE, szDefaultParam, nValidateCheckType)
    CURL_HttpPost(PostKey.LOGIN_ACCOUNT_EQUIPCODE, szPostUrl, {}, true, 60, 60, {["Content-Type"]="application/json"})
end

function EquipCodeData.GetRoleEquipSetDataWithID(nID)
    local tRoleEquips = EquipCodeData.GetRoleEquipData()

    for _, tData in ipairs(tRoleEquips or {}) do
        if tData["id"] == nID then
            return tData
        end
    end
end

function EquipCodeData.CheckIsRoleRecommendEquip(dwTabType, dwIndex)
    local tRoleEquips = EquipCodeData.GetRoleEquipData()
    for nIndex, tData in ipairs(tRoleEquips or {}) do
        if not tData.tEquipDatas then
            if not string.is_nil(tData.equips) then
                local tJsonEquipData, szErrMsg = JsonDecode(tData.equips)
                if tJsonEquipData and tJsonEquipData.Equips then
                    tData.tEquipDatas = tJsonEquipData.Equips
                end
            end
        end

        for _, tEquipData in pairs(tData.tEquipDatas or {}) do
            local nEquipType = tonumber(tEquipData.UcPos)
            local dwTabType1 = EquipType2ItemType[nEquipType]
            local dwIndex1 = tonumber(tEquipData.ID)

            if dwTabType == dwTabType1 and dwIndex == dwIndex1 then
                return true, tData.title, nIndex
            else
                local tSource = ItemData.GetItemSourceList(dwTabType1, dwIndex1)
                -- todo：判断当前道具为推荐表装备的关联道具
                if tSource and tSource.tItems and #tSource.tItems > 0 then
                    for _, v in ipairs(tSource.tItems) do
                        local nLinkItemTabType = tonumber(v[1])
                        local nLinkItemIndex = tonumber(v[2])
                        if dwTabType == nLinkItemTabType and dwIndex == nLinkItemIndex then
                            return true, tData.title, nIndex
                        end
                    end
                end
            end
        end
    end

    return false
end

function EquipCodeData.GetRoleEquipData()
    local tRoleEquips = EquipCodeData.tRoleEquips

    if not EquipCodeData.bReqLogin then
        EquipCodeData.bReqLogin = true
        EquipCodeData.LoginAccount(false)
    end

    return tRoleEquips
end

function EquipCodeData.SetRoleEquipData(tRoleEquips)
    table.sort(tRoleEquips, function (a, b)
        return a.id < b.id
    end)
    EquipCodeData.tRoleEquips = tRoleEquips
    Event.Dispatch(EventType.OnUpdateCustomizedSetList)
end

function EquipCodeData.IsHadRoleEquipSet()
    local tRoleEquips = EquipCodeData.GetRoleEquipData()
    return tRoleEquips and #tRoleEquips > 0
end

function EquipCodeData.IsNewEquipSet()
    return EquipCodeData.tCurInfo == nil
end

function EquipCodeData.CheckIsEditAllowed()
    local bAllowed = ActivityData.IsMsgEditAllowed()
    -- bAllowed = false
    if not bAllowed then
        TipsHelper.ShowNormalTip("暂时无法使用该功能")
    end

    return bAllowed
end


-------------------------------------------当前自定义装备相关----------------------------------------
function EquipCodeData.InitCustomizedSetData()
    local tCurInfo = EquipCodeData.tCurInfo

    EquipCodeData.tCurEquip = nil
    EquipCodeData.tCurInfo = nil
    EquipCodeData.dwCurForceID = nil
    EquipCodeData.dwCurKungfuID = nil

    local tRoleEquips = EquipCodeData.GetRoleEquipData()
    if tRoleEquips and #tRoleEquips > 0 then
        local tData = tRoleEquips[1]
        if tCurInfo and EquipCodeData.GetRoleEquipSetDataWithID(tCurInfo.nID) then
            tData = EquipCodeData.GetRoleEquipSetDataWithID(tCurInfo.nID)
        end
        EquipCodeData.ImportCustomizedSetEquip(tData, true)
    end
end

function EquipCodeData.UnInitCustomizedSetData()
    EquipCodeData.tCurEquip = nil
    EquipCodeData.tCurInfo = nil
    EquipCodeData.dwCurForceID = nil
    EquipCodeData.dwCurKungfuID = nil
end

function EquipCodeData.DoImportEquip(tData, bRoleEquip)
    local tEquips = {}
    local tInfo
    local dwForceID, dwKungfuID

    if bRoleEquip then
        tInfo = {
            szKungFuName = tData.kungfu_name,
            nScore = tonumber(tData.score),
            nID = tData.id,
            szTitle = tData.title,
            nCreateTime = tData.create_time,
        }

        if tData.kungfu_name then
            dwKungfuID = table.get_key(PlayerKungfuChineseName, tData.kungfu_name)
        else
            dwKungfuID = PlayerData.GetPlayerMountKungfuID()
        end
        dwForceID = Kungfu_GetType(dwKungfuID)
    else
        local szSchoolName = tData.force
        local dwBelongSchool = Table_GetSkillSchoolIDByName(UIHelper.UTF8ToGBK(szSchoolName))
        dwForceID = Table_SchoolToForce(dwBelongSchool)
        if not dwForceID then
            dwForceID = FORCE_TYPE.CHUN_YANG
        end
        dwKungfuID = tonumber(tData.kungfu_id)
    end

    if not string.is_nil(tData.equips) then
        local tJsonEquipData, szErrMsg = JsonDecode(tData.equips)
        for _, tEquipData in pairs(tJsonEquipData.Equips) do
            local tEquip = {}
            local tPowerUpInfo = {}
            local nEquipType = tonumber(tEquipData.UcPos)
            local dwTabType = EquipType2ItemType[nEquipType]
            local dwIndex = tonumber(tEquipData.ID)
            local itemInfo = ItemData.GetItemInfo(dwTabType, dwIndex)
            local tbRecommendEquipInfo = Table_GetRecommendEquipInfo(dwTabType, dwIndex)

            tEquips[nEquipType] = tEquips[nEquipType] or {}
            if tbRecommendEquipInfo then
                tEquip = {
                    item = itemInfo,
                    tbConfig = tbRecommendEquipInfo.tbConfig,
                    dwTabType = tbRecommendEquipInfo.tbConfig.dwTabType,
                    dwIndex = tbRecommendEquipInfo.tbConfig.dwIndex,
                }
            else
                tEquip = {
                    item = itemInfo,
                    dwTabType = dwTabType,
                    dwIndex = dwIndex,
                }
            end

            tPowerUpInfo.nMaxEquipBoxStrengthLevel = tonumber(tEquipData.MaxEquipBoxStrengthLevel)
            tPowerUpInfo.nMaxStrengthLevel = tonumber(tEquipData.MaxStrengthLevel)
            tPowerUpInfo.nStrengthLevel = tonumber(tEquipData.StrengthLevel)
            tPowerUpInfo.tbSlotInfo = tPowerUpInfo.tbSlotInfo or {}
            for _, tValue in pairs(tEquipData.FiveStone or {}) do
                tPowerUpInfo.tbSlotInfo[tValue.SlotIdx + 1] = tonumber(tValue.Level)
            end

            if tEquipData.ColorStone then
                tPowerUpInfo.tbColorStone = {
                    nID = tonumber(tEquipData.ColorStone.ID),
                    nLevel = tonumber(tEquipData.ColorStone.Level),
                }
            end

            if tEquipData.WPermanentEnchant then
                tPowerUpInfo.tbEnchant = {
                    nID = tonumber(tEquipData.WPermanentEnchant.ID),
                }
            end

            if tEquipData.WCommonEnchant then
                tPowerUpInfo.tbBigEnchant = {
                    nID = tonumber(tEquipData.WCommonEnchant.ID),
                }
            end


            tEquips[nEquipType].tEquip = tEquip
            tEquips[nEquipType].tPowerUpInfo = tPowerUpInfo
        end
    end

    return tEquips, tInfo, dwForceID, dwKungfuID
end


function EquipCodeData.ImportCustomizedSetEquip(tData, bRoleEquip)
    EquipCodeData.tCurEquip = {}

    local tEquip, tInfo, dwForceID, dwKungfuID = EquipCodeData.DoImportEquip(tData, bRoleEquip)
    EquipCodeData.tCurEquip = tEquip
    EquipCodeData.tCurInfo = tInfo
    EquipCodeData.dwCurForceID = dwForceID
    EquipCodeData.dwCurKungfuID = dwKungfuID
    Event.Dispatch(EventType.OnUpdateCustomizedSetEquipFilter)
    Event.Dispatch(EventType.OnUpdateCustomizedSetEquipList, nil)
end

function EquipCodeData.DoExportEquip(tEquipDatas)
    local tEquips = {}
    for nType, tEquipData in pairs(tEquipDatas) do
        if tEquipData.tEquip and tEquipData.tEquip.dwIndex then
            local tPowerUpInfo = tEquipData.tPowerUpInfo or {}
            local tEquipStrengthInfo = EquipData.GetStrength(tEquipData.tEquip.item, false)
            local tMountAttribInfos = EquipData.GetEquipSlotTip(tEquipData.tEquip.item, false, { bCmp = false, bLink = true })

            local tEquipData2 = {
                ["MaxStrengthLevel"] = tPowerUpInfo.nMaxStrengthLevel or 0,
                ["MaxEquipBoxStrengthLevel"] = tPowerUpInfo.nMaxEquipBoxStrengthLevel or 0,
                ["StrengthLevel"] = tPowerUpInfo.nStrengthLevel or 0,
                ["ID"] = tEquipData.tEquip.dwIndex,
                ["FiveStone"] = {},
                ["UcPos"] = nType
            }

            local tbSlotInfo = tPowerUpInfo.tbSlotInfo or {}
            for i, _ in ipairs(tMountAttribInfos) do
                table.insert(tEquipData2.FiveStone, {
                    ["Level"] = tbSlotInfo[i] or 0,
                    ["SlotIdx"] = i - 1
                })
            end

            local tbColorStone = tPowerUpInfo.tbColorStone
            if tbColorStone then
                tEquipData2.ColorStone = {
                    ID = tbColorStone.nID,
                    Level = tbColorStone.nLevel,
                }
            end

            local tbEnchant = tPowerUpInfo.tbEnchant
            if tbEnchant then
                tEquipData2.WPermanentEnchant = {
                    ID = tbEnchant.nID,
                }
            end

            local tbBigEnchant = tPowerUpInfo.tbBigEnchant
            if tbBigEnchant then
                tEquipData2.WCommonEnchant = {
                    ID = tbBigEnchant.nID,
                }
            end

            table.insert(tEquips, tEquipData2)
        end
    end

    table.sort(tEquips, function(a, b)
        return a.UcPos < b.UcPos
    end)

    return tEquips
end

function EquipCodeData.ExportCustomizedSetEquip(tEquip, dwKungfuID)
    tEquip = tEquip or EquipCodeData.tCurEquip
    dwKungfuID = dwKungfuID or EquipCodeData.dwCurKungfuID

    local tData = {}

    -- 装备部分
    tData.Equips = EquipCodeData.DoExportEquip(tEquip)

    -- 属性部分
    local szKungFu = PlayerKungfuName[dwKungfuID] or ""
    local _, tMatchDetail = CalculateKungfuPanel(szKungFu, Lib.copyTab(tData), false)

    tData.MatchDetail = tMatchDetail

    return tData
end

function EquipCodeData.SaveCustomizedSet()
    local tbData = EquipCodeData.ExportCustomizedSetEquip()

    local szKungFuName = PlayerKungfuName[EquipCodeData.dwCurKungfuID] or ""
    local szKungFuChineseName = PlayerKungfuChineseName[EquipCodeData.dwCurKungfuID] or ""
    local nTotalScore = CalculateTotalEquipsScore(szKungFuName, Lib.copyTab(tbData))
    if not EquipCodeData.IsNewEquipSet() then
        local tCurInfo = EquipCodeData.tCurInfo
        EquipCodeData.ReqUpdateRoleEquips(tCurInfo.nID, tCurInfo.szTitle, szKungFuChineseName,  nTotalScore, tbData)
    else
        UIMgr.Open(VIEW_ID.PanelCustomSetInputPop, EquipCodeData.dwCurKungfuID, tbData)
    end
end

function EquipCodeData.GetAttributeData(szKungfu, tEquipDatas, bPVE)
    local tEquips = { Equips = {} }
    tEquips.Equips = EquipCodeData.DoExportEquip(tEquipDatas)

    local tShowItem, tMatchDetail = CalculateKungfuPanel(szKungfu, Lib.copyTab(tEquips), bPVE)
    local nTotalScore = CalculateTotalEquipsScore(szKungfu, Lib.copyTab(tEquips))

    return tShowItem, tMatchDetail, nTotalScore
end

function EquipCodeData.SetCustomizedSetEquip(nType, tData)
    if not nType then
        LOG.ERROR("EquipCodeData.SetCustomizedSetEquip Error! nType is nil!")
        return
    end

    EquipCodeData.tCurEquip = EquipCodeData.tCurEquip or {}
    EquipCodeData.tCurEquip[nType] = EquipCodeData.tCurEquip[nType] or {}

    local tOldData = EquipCodeData.tCurEquip[nType].tEquip
    EquipCodeData.tCurEquip[nType].tEquip = tData

    Event.Dispatch(EventType.OnUpdateCustomizedSetEquipList, nType)

    if tData then
        if not tOldData or tData.dwIndex ~= tOldData.dwIndex or tData.dwTabType ~= tOldData.dwTabType then
            local tPowerUpInfo = EquipCodeData.GetCustomizedSetEquipPowerUpInfo(nType) or {}
            local tEquipStrengthInfo = EquipData.GetStrength(tData.item, false)

            tPowerUpInfo.nStrengthLevel = tEquipStrengthInfo.nEquipMaxLevel
            tPowerUpInfo.nMaxStrengthLevel = tEquipStrengthInfo.nEquipMaxLevel
            tPowerUpInfo.nMaxEquipBoxStrengthLevel = tEquipStrengthInfo.nBoxMaxLevel
            tPowerUpInfo.tbBigEnchant = nil
            EquipCodeData.SetCustomizedSetEquipPowerUpInfo(nType, tPowerUpInfo)
        end
    end
end

function EquipCodeData.GetCustomizedSetEquip(nType)
    if not nType then
        LOG.ERROR("EquipCodeData.GetCustomizedSetEquip Error! nType is nil!")
        return
    end

    return EquipCodeData.tCurEquip and EquipCodeData.tCurEquip[nType] and EquipCodeData.tCurEquip[nType].tEquip
end

function EquipCodeData.SetCustomizedSetEquipPowerUpInfo(nType, tbInfo)
    if not nType then
        LOG.ERROR("EquipCodeData.SetCustomizedSetEquipPowerUpInfo Error! nType is nil!")
        return
    end

    EquipCodeData.tCurEquip = EquipCodeData.tCurEquip or {}
    EquipCodeData.tCurEquip[nType] = EquipCodeData.tCurEquip[nType] or {}
    EquipCodeData.tCurEquip[nType].tPowerUpInfo = tbInfo

    Event.Dispatch(EventType.OnUpdateCustomizedSetEquipList, nType)
end

function EquipCodeData.GetCustomizedSetEquipPowerUpInfo(nType)
    if not nType then
        LOG.ERROR("EquipCodeData.GetCustomizedSetEquipPowerUpInfo Error! nType is nil!")
        return
    end

    return EquipCodeData.tCurEquip and EquipCodeData.tCurEquip[nType] and EquipCodeData.tCurEquip[nType].tPowerUpInfo
end

function EquipCodeData.SyncCustomizedSetEquipPowerUpStrengthInfo(nType)
    if not nType then
        LOG.ERROR("EquipCodeData.SyncCustomizedSetEquipPowerUpStrengthInfo Error! nType is nil!")
        return
    end

    local tSrcPowerUpInfo = EquipCodeData.GetCustomizedSetEquipPowerUpInfo(nType) or {}
    for k, v in pairs(EquipCodeData.tCurEquip) do
        if k ~= nType then
            local tbData = EquipCodeData.GetCustomizedSetEquip(k)
            if tbData and tbData.item then
                local tbPowerUpInfo = EquipCodeData.GetCustomizedSetEquipPowerUpInfo(k) or {}
                local tbEquipStrengthInfo = EquipData.GetStrength(tbData.item, false)

                if tSrcPowerUpInfo.nStrengthLevel then
                    tbPowerUpInfo.nStrengthLevel = math.min(tSrcPowerUpInfo.nStrengthLevel, tbEquipStrengthInfo.nEquipMaxLevel)
                else
                    tbPowerUpInfo.nStrengthLevel = 0
                end
                tbPowerUpInfo.nMaxStrengthLevel = tbEquipStrengthInfo.nEquipMaxLevel
                tbPowerUpInfo.nMaxEquipBoxStrengthLevel = tbEquipStrengthInfo.nBoxMaxLevel
                EquipCodeData.SetCustomizedSetEquipPowerUpInfo(k, tbPowerUpInfo)
            end
        end
    end
end

function EquipCodeData.SyncCustomizedSetEquipPowerUpMountInfo(nType)
    if not nType then
        LOG.ERROR("EquipCodeData.SyncCustomizedSetEquipPowerUpMountInfo Error! nType is nil!")
        return
    end

    local tSrcPowerUpInfo = EquipCodeData.GetCustomizedSetEquipPowerUpInfo(nType) or {}
    for k, v in pairs(EquipCodeData.tCurEquip) do
        if k ~= nType then
            local tbData = EquipCodeData.GetCustomizedSetEquip(k)
            if tbData and tbData.item then
                local tbPowerUpInfo = EquipCodeData.GetCustomizedSetEquipPowerUpInfo(k) or {}
                local tbMountAttribInfos = EquipData.GetEquipSlotTip(tbData.item, false, { bCmp = false, bLink = true })
                local nMountCount = #tbMountAttribInfos

                tbPowerUpInfo.tbSlotInfo = {}
                for nSlot, nLevel in pairs(tSrcPowerUpInfo.tbSlotInfo or {}) do
                    if nMountCount >= nSlot then
                        tbPowerUpInfo.tbSlotInfo[nSlot] = nLevel
                    end
                end

                EquipCodeData.SetCustomizedSetEquipPowerUpInfo(k, tbPowerUpInfo)
            end
        end
    end
end

function EquipCodeData.CheckCurCustomizedSetIsChanged()
    local bChanged = false

    if PlayerData.GetPlayerForceID() ~= EquipCodeData.dwCurForceID then
        return bChanged
    end

    local tData = EquipCodeData.ExportCustomizedSetEquip()
    if not EquipCodeData.IsNewEquipSet() then
        local tCurInfo = EquipCodeData.tCurInfo
        local tRoleData = EquipCodeData.GetRoleEquipSetDataWithID(tCurInfo.nID)

        if tRoleData and tData then
            local szEquip = JsonEncode(tData)
            if szEquip ~= tRoleData.equips then
                bChanged = true
            end
        end
    else
        if tData and tData.Equips then
            for _, tEquipData in pairs(tData.Equips) do
                if tEquipData.ID then
                    bChanged = true
                    break
                end
            end
        end
    end

    return bChanged
end

function EquipCodeData.CreateNewSet()
    EquipCodeData.tCurEquip = nil
    EquipCodeData.tCurInfo = nil
    Event.Dispatch(EventType.OnUpdateCustomizedSetList)
    Event.Dispatch(EventType.OnUpdateCustomizedSetEquipList, nil)
end

function EquipCodeData.IsHadCustomizedSetData()
    return EquipCodeData.tCurEquip ~= nil
end

-- 计算配装器自定义装备的石头/附魔总分数
function EquipCodeData.GetCustomEquipStoneScore(tPowerUpInfo)
    if not tPowerUpInfo then
        return 0
    end

    local nStoneScore = 0
    -- 五行石分数
    if tPowerUpInfo.tbSlotInfo then
        nStoneScore = nStoneScore + GetEquipFiveStoneScore(tPowerUpInfo.tbSlotInfo)
    end
    -- 五彩石分数
    if tPowerUpInfo.tbColorStone and tPowerUpInfo.tbColorStone.nID and tPowerUpInfo.tbColorStone.nID > 0 then
        nStoneScore = nStoneScore + GetEquipColorStoneScore(tPowerUpInfo.tbColorStone.nID)
    end
    -- 小附魔分数
    if tPowerUpInfo.tbEnchant and tPowerUpInfo.tbEnchant.nID and tPowerUpInfo.tbEnchant.nID > 0 then
        nStoneScore = nStoneScore + Table_GetEnchantScore(tPowerUpInfo.tbEnchant.nID)
    end
    -- 大附魔分数
    if tPowerUpInfo.tbBigEnchant and tPowerUpInfo.tbBigEnchant.nID and tPowerUpInfo.tbBigEnchant.nID > 0 then
        nStoneScore = nStoneScore + Table_GetEnchantScore(tPowerUpInfo.tbBigEnchant.nID)
    end

    return nStoneScore
end