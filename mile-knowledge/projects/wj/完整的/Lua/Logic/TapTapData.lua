-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: TapTapData
-- Date: 2023-04-18 19:17:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

TapTapData = TapTapData or { className = "TapTapData" }

TapEventType = {
    --SignIn = "SignIn",
    --Qiyu = "Qiyu",
    PaySuccess = "PaySuccess",
    Mail = "Mail",
}

local self = TapTapData
--local EX_POINT_SIGN_DAY = 259    -- 签到天数
local nVersion = 6 -- 每次需要重启TapTap问卷时需要将版本号增大

self.bShowIOS = true
self.bShowAndroid = true
self.bShowWindows = true
self.bShowMac = true
self.nPlayerCoin = nil
self.debug = false -- 修改为true后重启客户端，可无视签到条件，在回到主界面时打开界面


function TapTapData.Init()
    --Event.Reg(TapTapData, EventType.PlayAnimMainCityShow, function()
    --    if g_pClientPlayer then
    --        TapTapData.OnBackToMainCity()
    --    end
    --end)

    --Event.Reg(TapTapData, "LOADING_END", function()
    --    if nVersion > Storage.TapTap.nVersion then
    --        Storage.TapTap.nVersion = nVersion
    --
    --        --Storage.TapTap.bSignInCompleted = false
    --        Storage.TapTap.bPayCompleted = false
    --        --Storage.TapTap.bQiyuCompleted = false
    --
    --        --Storage.TapTap.bShouldShowQiyu = false
    --        Storage.TapTap.bShouldShowPay = false
    --        --Storage.TapTap.nInitialSignInCount = g_pClientPlayer.GetExtPoint(EX_POINT_SIGN_DAY) or 0
    --
    --        Storage.TapTap.Flush()
    --    end
    --
    --    TapTapData.nPlayerCoin = g_pClientPlayer and g_pClientPlayer.nCoin or nil
    --    TapTapData.ShowPaySuccessPop()
    --end)

    --Event.Reg(TapTapData, "OpenAdventure", function()
    --    if not Storage.TapTap.bQiyuCompleted and not Storage.TapTap.bShouldShowQiyu then
    --        Storage.TapTap.bShouldShowQiyu = true -- 触发奇遇 进入倒计时
    --        --Timer.Add(TapTapData, nPopWaitSecond, function()
    --        --    TapTapData.ShowQiyuPop()
    --        --end)
    --        CustomData.Flush(CustomDataType.Account)
    --
    --        --TapTapData.ShowQiyuPop()
    --    end
    --end)

    --Event.Reg(TapTapData, "SYNC_COIN", function()
    --    if g_pClientPlayer ~= nil and TapTapData.nPlayerCoin and TapTapData.nPlayerCoin < g_pClientPlayer.nCoin then
    --        TapTapData.OnPaySuccess()
    --    end
    --end)
    --
    --Event.Reg(TapTapData, EventType.OnSyncRechargeInfo, function()
    --    if XGSDK.szPayType == PayData.RechargeTypeEnum.szPointCard or XGSDK.szPayType == PayData.RechargeTypeEnum.szMonthCard then
    --        TapTapData.OnPaySuccess()
    --    end
    --end)
end

function TapTapData.UnInit()
    Event.UnRegAll(TapTapData)
end

function TapTapData.OnPaySuccess()
    local nTime = GetCurrentTime()
    local nStartTime = DateToTime(2024, 6, 14, 7, 0, 0) -- 在开始时间之后才能触发充值成功逻辑
    if nTime >= nStartTime then
        if not Storage.TapTap.bPayCompleted and not Storage.TapTap.bShouldShowPay then
            Storage.TapTap.bShouldShowPay = true
            --Timer.Add(TapTapData, nPopWaitSecond, function()
            --    TapTapData.ShowPaySuccessPop()
            --end)
            Storage.TapTap.Flush()
        end
    end
end

--function TapTapData.OnBackToMainCity()
--    if self.debug or (not Storage.TapTap.bSignInCompleted and TapTapData.CheckDailySigninCount()) then
--        if TapTapData.IsPlatformSatisfied() then
--            UIMgr.Open(VIEW_ID.PanelTapTapCommentPop, TapEventType.SignIn)
--            Storage.TapTap.bSignInCompleted = true
--            CustomData.Flush(CustomDataType.Account)
--        end
--    end
--end

--function TapTapData.ShowQiyuPop()
--    if (not Storage.TapTap.bQiyuCompleted and Storage.TapTap.bShouldShowQiyu) then
--        if TapTapData.IsPlatformSatisfied() then
--            UIMgr.Open(VIEW_ID.PanelTapTapCommentPop, TapEventType.Qiyu)
--            Storage.TapTap.bQiyuCompleted = true
--            Storage.TapTap.bShouldShowQiyu = false
--
--            CustomData.Flush(CustomDataType.Account)
--            return true
--        end
--    end
--    return false
--end

function TapTapData.ShowPaySuccessPop()
    if (not Storage.TapTap.bPayCompleted and Storage.TapTap.bShouldShowPay) and not AppReviewMgr.IsReview() then
        if TapTapData.IsPlatformSatisfied() then
            UIMgr.Open(VIEW_ID.PanelTapTapCommentPop, TapEventType.PaySuccess)
            Storage.TapTap.bPayCompleted = true
            Storage.TapTap.bShouldShowPay = false

            Storage.TapTap.Flush()
            return true
        end
    end
    return false
end

--function TapTapData.CheckDailySigninCount()
--    local nCount = g_pClientPlayer.GetExtPoint(EX_POINT_SIGN_DAY) or 0
--    return nCount - Storage.TapTap.nInitialSignInCount >= 3 --累计登录第3天，花萼楼签到回主界面弹出
--end

function TapTapData.IsPlatformSatisfied()
    local bSatisfiedPlatform = false
    if Platform.IsAndroid() and self.bShowAndroid then
        bSatisfiedPlatform = true
    elseif Platform.IsIos() and self.bShowIOS then
        bSatisfiedPlatform = true
    elseif Platform.IsWindows() and self.bShowWindows then
        if not Version.IsEXP() then
            bSatisfiedPlatform = true
        end
    elseif Platform.IsMac() and self.bShowMac then
        bSatisfiedPlatform = true
    end
    return bSatisfiedPlatform
end

function TapTapData.OnReload()
end