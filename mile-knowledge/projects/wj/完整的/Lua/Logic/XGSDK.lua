XGSDK = XGSDK or {className = "XGSDK"}

XGSDK.szPayType = ""

-- 每次拉起充值时，设置该值为true
-- 在失败时设为false
-- 当该值为true时，在 SYNC_COIN OnSyncRechargeInfo 事件弹出充值成功的提示，并设置为false
XGSDK.bNeedSuccessNotify = false

function XGSDK.UpdateNeedSuccessNotify(szReason, bNeed)
    XGSDK.bNeedSuccessNotify = bNeed
    LOG.DEBUG("XGSDK UpdateNeedSuccessNotify szReason=%s bNeed => %s", szReason, tostring(bNeed))
end

--记录最后购买的支付信息，上报支付成功使用
XGSDK.tPayInfo = {}

-- 战令的实物订单信息，在购买成功或取消购买的时候用于删除对应订单
XGSDK.BattlePass_szOrderSN = ""

-- 玩家是否是试玩账号，充值前更新下，用于在充值成功后判断之前是否是试玩账号，进行特殊逻辑处理
XGSDK.bDemoAccount = false

function XGSDK.Pay(szProductId, szCustomInfo, szOrderSN, nBuyCount)
    local tConfig = PayData.GetPayConfig(szProductId)
    if tConfig == nil then
        LOG.ERROR(string.format("XGSDK_Pay invalid szProductId=%s", szProductId))
        return
    end

    -- 这里记录下最后购买的商品类别，用于支付成功时显示不同的提示语
    XGSDK.szPayType = tConfig.szType
    XGSDK.tPayInfo = {}

    -- 充值前记录下玩家是否是试玩账号
    local bCharged = Login_GetZoneChargeFlag() and Login_GetChargeFlag()
    XGSDK.bDemoAccount = not bCharged

    LOG.DEBUG(string.format("XGSDK_Pay szProductId=%s", szProductId))

    local player = GetClientPlayer()
    local moduleServerList = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)
    local tCurrentServer = moduleServerList.GetSelectServer()

    -- -------- 必填的一些字段 --------
    local szUid = Login_GetUnionAccount()

    local szProductName = tConfig.szProductName

    --- 自定义档位和补差价可以一次性购买多份，直接计算出总价，西瓜那边会按照单价来计算出买了几份，发对应数目的商品
    local nBatchBuyCount = nBuyCount or 1
    --- 西瓜的单位为分，这里转换下
    local nPayAmount = nBatchBuyCount * tConfig.nPrice * 100

    local szCurrencyName = "CNY"

    -- note: 这三个仅为辅助数据，没有其实也能充值。充值定位账号使用的是大区ID和剑三账号（在西瓜服务器侧用西瓜uid映射过去）
    --      所以，在特定时机（如登录时），没有角色数据也可以照常充值，到时候根据情况决定是否要判定下player是否为空
    local szRoleId = "NoRole"
    local szRoleName = "NoRole"
    local nRoleLevel = 0

    if player then
        szRoleId = tostring(player.dwID)
        szRoleName = UIHelper.GBKToUTF8(player.szName)
        nRoleLevel = player.nLevel
    end

    local szServerId = tCurrentServer.szServer
    local szZoneId = tCurrentServer.szSerial

    -- -------- 可选参数 --------
    local szProductDesc = tConfig.szProductDesc

    local nRoleVipLevel = 0
    local szPartyName = ""

    -- 游戏这边用不到订单号，在这里基于当前用户id生成一个按秒唯一的id，方便埋点排查
    local szGameTradeNo = string.format("%s%d", szUid, os.time())
    local szGameCallbackUrl = ""
    if szOrderSN then
        szGameTradeNo = szOrderSN
    end

    if not szCustomInfo then
        szCustomInfo = ""
    end
    
    --- 批量购买的时候，名称与描述特殊处理下
    if nBatchBuyCount > 1 then
        if tConfig.szType == PayData.RechargeTypeEnum.szCoin then
            --- 1000通宝*数量
            szProductName = string.format("%s*%d", tConfig.szProductName, nBatchBuyCount)
            szProductDesc = string.format("%s*%d", tConfig.szProductDesc, nBatchBuyCount)
        end
    end

    XGSDK_TrackSelectProduct(szProductId)
    XGSDK_TrackCreateGameOrder(szProductId, "1", szGameTradeNo, "0", "")

    XGSDK.UpdateNeedSuccessNotify("拉起支付", true)

    XGSDK_Pay(szUid, szProductId, szProductName, szProductDesc, nPayAmount, szCurrencyName,
              szRoleId, szRoleName, nRoleLevel, nRoleVipLevel,
              szServerId, szZoneId,
              szGameTradeNo, szGameCallbackUrl, szPartyName, szCustomInfo, nBatchBuyCount)

    XGSDK.tPayInfo.szProductId = szProductId
    XGSDK.tPayInfo.szProductName = szProductName
    XGSDK.tPayInfo.szProductDesc = szProductDesc
    XGSDK.tPayInfo.nPayAmount = nPayAmount
    XGSDK.tPayInfo.szCurrencyName = szCurrencyName
    XGSDK.tPayInfo.szGameTradeNo = szGameTradeNo
    XGSDK.tPayInfo.nBatchBuyCount = nBatchBuyCount
end

function XGSDK.TrackShipped()
    local player = GetClientPlayer()
    local moduleServerList = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)
    local tCurrentServer = moduleServerList.GetSelectServer()

    -- -------- 必填的一些字段 --------
    local szUid = Login_GetUnionAccount()

    -- note: 这三个仅为辅助数据，没有其实也能充值。充值定位账号使用的是大区ID和剑三账号（在西瓜服务器侧用西瓜uid映射过去）
    --      所以，在特定时机（如登录时），没有角色数据也可以照常充值，到时候根据情况决定是否要判定下player是否为空
    local szRoleId = ""
    local szRoleName = ""
    local nRoleLevel = 0

    if player then
        szRoleId = tostring(player.dwID)
        szRoleName = UIHelper.GBKToUTF8(player.szName)
        nRoleLevel = player.nLevel
    end

    local szServerId = tCurrentServer.szServer
    local szZoneId = tCurrentServer.szSerial

    -- -------- 可选参数 --------
    local nRoleVipLevel = 0
    local szPartyName = ""


    local szGameCallbackUrl = ""

    local szProductId = XGSDK.tPayInfo.szProductId
    local szProductName = XGSDK.tPayInfo.szProductName
    local szProductDesc = XGSDK.tPayInfo.szProductDesc
    local nPayAmount = XGSDK.tPayInfo.nPayAmount
    local szCurrencyName = XGSDK.tPayInfo.szCurrencyName
    local szGameTradeNo = XGSDK.tPayInfo.szGameTradeNo
    local nBatchBuyCount = XGSDK.tPayInfo.nBatchBuyCount

    XGSDK_TrackShipped(szUid, szProductId, szProductName, szProductDesc, nPayAmount, szCurrencyName,
            szRoleId, szRoleName, nRoleLevel, nRoleVipLevel,
            szServerId, szZoneId,
            szGameTradeNo, szGameCallbackUrl, szPartyName, nBatchBuyCount)

    XGSDK.tPayInfo = {}
end

Event.Reg(XGSDK, "SYNC_ROLE_DATA_END", function()
    LOG.DEBUG("login finished, report data to xgsdk")

    local player = g_pClientPlayer
    local moduleServerList = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)
    local tCurrentServer = moduleServerList.GetSelectServer()

    -- -------- 必填的一些字段 --------
    local szUid = Login_GetUnionAccount()

    local szRoleId = tostring(player.dwID)
    local szRoleName = UIHelper.GBKToUTF8(player.szName)
    local szRoleCreateTime = tostring(player.GetCreateTime())
    local nRoleLevel = player.nLevel

    local szZoneId = tCurrentServer.szSerial
    local szServerId = tCurrentServer.szServer
    local szZoneName = tCurrentServer.szRegion
    local szServerName = tCurrentServer.szServer

    local szGender = "m"
    local szBalance = tostring(player.nCoin)

    -- -------- 可选参数 --------
    local szRoleType = ""
    local nRoleVipLevel = 0
    local szPartyName = ""

    local szAgeInGame = ""
    local szAccountAgeInGame = ""
    local szRoleFigure = ""
    local szExt = ""

    XGSDK_TrackEnterGame(szUid, szRoleId, szRoleName, szRoleType, szRoleCreateTime, nRoleLevel, nRoleVipLevel,
            szZoneId, szServerId, szZoneName, szServerName,
            szPartyName, szGender, szBalance, szAgeInGame, szAccountAgeInGame, szRoleFigure, szExt
    )
end)

Event.Reg(XGSDK, "LOGIN_NOTIFY", function(nEvent, szMatrixPosition, dwLimitPlayTimeFlag, szRoleName, nVerifyInterval, dwPostion, nChannel, szIP, szXGMessage)
    if nEvent ~= LOGIN.CREATE_ROLE_SUCCESS then
        return
    end

    local nRoleCount = Login_GetRoleCount()
    local role
    for i = 0, nRoleCount - 1 do
        local tRoleInfo = Login_GetRoleInfo(i)
        if tRoleInfo and tRoleInfo.RoleName == szRoleName then
            role = tRoleInfo
            break
        end
    end

    if not role then
        return
    end

    local moduleServerList = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)
    local tCurrentServer = moduleServerList.GetSelectServer()

    -- -------- 必填的一些字段 --------
    local szUid = Login_GetUnionAccount()

    local szRoleId = tostring(role.RoleID)
    local szRoleNameUtf8 = UIHelper.GBKToUTF8(role.RoleName)
    local szRoleCreateTime = tostring(os.time())--这里需要创建时间，c++无法改动了，先用这个近似值
    local nRoleLevel = role.RoleLevel

    local szZoneId = tCurrentServer.szSerial
    local szServerId = tCurrentServer.szServer
    local szZoneName = tCurrentServer.szRegion
    local szServerName = tCurrentServer.szServer

    local szGender = (role.RoleType == 2 or role.RoleType == 6) and "f" or "m"
    local szBalance = "0"  -- 这个时候无法获取玩家的通宝

    -- -------- 可选参数 --------
    local szRoleType = tostring(role.RoleType)
    local nRoleVipLevel = 0
    local szPartyName = ""

    local szAgeInGame = ""
    local szAccountAgeInGame = ""
    local szRoleFigure = ""
    local szExt = ""

    XGSDK_TrackCreateRole(szUid, szRoleId, szRoleNameUtf8, szRoleType, szRoleCreateTime, nRoleLevel, nRoleVipLevel,
            szZoneId, szServerId, szZoneName, szServerName,
            szPartyName, szGender, szBalance, szAgeInGame, szAccountAgeInGame, szRoleFigure, szExt
    )
end)

Event.Reg(XGSDK, "SYNC_COIN", function()
    LOG.DEBUG("XGSDK SYNC_COIN nCoin=%d szPayType=%s bNeedSuccessNotify=%s",
              ItemData.GetCoin(),
              XGSDK.szPayType, tostring(XGSDK.bNeedSuccessNotify)
    )

    if XGSDK.szPayType == PayData.RechargeTypeEnum.szCoin then
        if g_pClientPlayer == nil then
            --- 游戏角色对象不存在时，无视该提示，等后续有对象后，可以实际获得通宝值时，收到该事件时再提示
            LOG.WARN("SYNC_COIN ShowPaySuccessTips player is nil, ignore")
            return
        end

        XGSDK.ShowPaySuccessTips()
    end
end)

Event.Reg(XGSDK, "REMOTE_BATTLEPASS", function()
    LOG.DEBUG("XGSDK REMOTE_BATTLEPASS szPayType=%s bNeedSuccessNotify=%s",
              XGSDK.szPayType, tostring(XGSDK.bNeedSuccessNotify)
    )

    if not XGSDK.bNeedSuccessNotify then
        return
    end

    HuaELouData.UpdateExp()
    if HuaELouData.IsGrandRewardUnlock() or HuaELouData.IsExtralUnlock() then
        XGSDK.UpdateNeedSuccessNotify("战令到账", false)
        XGSDK.TrackShipped()

        XGSDK.TryDeleteBattlePassOrder()
    end
end)

--- 实物订单直购可能最终的奖励是发放道具，这里对其进行判定，用于确认是否在发货
Event.Reg(XGSDK, "BAG_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
    --- 判断下最近一次购买是否是直购
    if XGSDK.szPayType ~= PayData.RechargeTypeEnum.szBuyItemWithRMB then
        return
    end

    --- 判断下是否是新获取
    if not bNewAdd then
        return
    end

    --- 仅当购买后未成功判定发货前处理
    if not XGSDK.bNeedSuccessNotify then
        return
    end

    local item = ItemData.GetItemByPos(nBox, nIndex)
    if item then
        --- 看看是否是直购的商品对应的道具，且与上次购买的商品id一样
        local szProductId      = PayData.GetRMBItemProductID(item.dwTabType, item.dwIndex)
        if szProductId and szProductId ~= "" and szProductId == XGSDK.tPayInfo.szProductId then
            LOG.DEBUG("XGSDK BAG_ITEM_UPDATE dwTabType=%d dwIndex=%d szProductId=%s szPayType=%s bNeedSuccessNotify=%s",
                      item.dwTabType, item.dwIndex, szProductId,
                      XGSDK.szPayType, tostring(XGSDK.bNeedSuccessNotify)
            )

            XGSDK.UpdateNeedSuccessNotify(string.format("直购商品到账-%s", szProductId), false)
            XGSDK.TrackShipped()
        end
    end
end)

Event.Reg(XGSDK, EventType.OnSyncRechargeInfo, function(nRechargeType, nPointsAmount, nRMBAmount, nEndTimeOfFee)
    LOG.DEBUG("XGSDK OnSyncRechargeInfo nRechargeType=%d, nPointsAmount=%d, nRMBAmount=%d, nEndTimeOfFee=%d szPayType=%s bNeedSuccessNotify=%s",
              nRechargeType, nPointsAmount, nRMBAmount, nEndTimeOfFee,
              XGSDK.szPayType, tostring(XGSDK.bNeedSuccessNotify)
    )

    if XGSDK.szPayType == PayData.RechargeTypeEnum.szPointCard or XGSDK.szPayType == PayData.RechargeTypeEnum.szMonthCard then
        XGSDK.ShowPaySuccessTips()

        --LOG.DEBUG("XGSDK OnSyncRechargeInfo bDemoAccount=%s", tostring(XGSDK.bDemoAccount))
        --if XGSDK.bDemoAccount then
        --    local szTips = "全民畅玩免点卡活动进行中，进游戏即可获赠持续至7月15日7:00的月卡！而从未充值时长的账号，也可免点卡畅玩！但从未充值时长的账号在游戏内充值时长后，需重新登录方可获赠月卡，否则在退出游戏前将会消耗本次充值的时长"
        --    ---@type UIConfirmView
        --    local scriptView = UIHelper.ShowConfirm(szTips)
        --    scriptView:HideCancelButton()
        --end
    end
end)

function XGSDK.ShowPaySuccessTips()
    if not XGSDK.bNeedSuccessNotify then
        return
    end
    XGSDK.UpdateNeedSuccessNotify("显示支付提示", false)

    local szSuccessMessage = "充值成功"
    if XGSDK.szPayType == PayData.RechargeTypeEnum.szCoin then
        szSuccessMessage = string.format("充值成功 当前通宝值：%d", ItemData.GetCoin())
    elseif XGSDK.szPayType == PayData.RechargeTypeEnum.szPointCard or XGSDK.szPayType == PayData.RechargeTypeEnum.szMonthCard then
        local nMonthEndTime, nPointLeftTime, nDayLeftTime, nFeeEndTime = Login_GetTimeOfFee()
        nPointLeftTime                                                 = PayData.GetActualPointLeftTime(nPointLeftTime, nMonthEndTime)

        local szPointLeftTime = PayData.FormatPointTime(nPointLeftTime)

        local dateMonthEndTime = TimeToDate(nMonthEndTime)
        local szMonthCardExpirationTime = string.format("%d-%02d-%02d %02d:%02d", dateMonthEndTime.year, dateMonthEndTime.month, dateMonthEndTime.day, dateMonthEndTime.hour, dateMonthEndTime.minute)

        if XGSDK.szPayType == PayData.RechargeTypeEnum.szPointCard then
            szSuccessMessage = string.format("充值成功 当前点卡：%s", szPointLeftTime)
        elseif XGSDK.szPayType == PayData.RechargeTypeEnum.szMonthCard then
            szSuccessMessage = string.format("充值成功 当前月卡：%s", szMonthCardExpirationTime)
            --- 如果玩家是首次充值，且充值的是月卡，因为此时paysys处该玩家仍是试玩账号，返回的月卡时间会是默认值(2004-01-01 00:00:00)，这里特别处理下
            --- 详情可写作搜索： 玩家未充值，是试玩账号
            if nMonthEndTime == 1072886400 then
                szSuccessMessage = "充值成功，重开充值界面后可查看剩余时间"
            end
        end
    end
    LOG.DEBUG("XGSDK ShowPaySuccessTips %s", szSuccessMessage)

    local scriptView = UIHelper.ShowConfirm(szSuccessMessage)
    scriptView:HideButton("Cancel")

    XGSDK.TrackShipped()

    if XGSDK.szPayType == PayData.RechargeTypeEnum.szCoin then
        Event.Dispatch("OnCoinRechargeSuccess")
    end
end

-- 购买成功或取消时，删除战令的实物订单
function XGSDK.TryDeleteBattlePassOrder()
    if XGSDK.BattlePass_szOrderSN ~= "" then
        if g_pClientPlayer then
            g_pClientPlayer.DeleteBuyItemOrderData(XGSDK.BattlePass_szOrderSN)
            LOG.DEBUG("XGSDK TryDeleteBattlePassOrder szOrderSN=%s", XGSDK.BattlePass_szOrderSN)
        end

        XGSDK.BattlePass_szOrderSN = ""
    end
end

-- 调用 西瓜方法：XGSDK_CallXGMethodSync，返回字符串
function XGSDK.CallXGMethodSync(szMethodName, tbArgs)
    if string.is_nil(szMethodName) then return end
    if not IsTable(tbArgs) then tbArgs = {} end
    return XGSDK_CallXGMethodSync(szMethodName, tbArgs)
end