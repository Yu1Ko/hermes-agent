-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: GiftHelper
-- Date: 2025-09-22 14:11:19
-- Desc: 打赏、提现相关
-- ---------------------------------------------------------------------------------
local CERTIFICATION_URL_ID = 73
local GM_SUPPORT_URL_ID = 74

local MESSAGE_TIP_NUM = 2000 --显示弹窗的金额

local WITHDRAW_LIMIT = {
    [0] = {nSingleMin = 1000, nSingleMax = 100000, nDailyMax = 100000}, --未认证
    [1] = {nSingleMin = 1000, nSingleMax = 400000, nDailyMax = 400000}, --已认证
}

GiftHelper = GiftHelper or {className = "GiftHelper"}
local self = GiftHelper

GiftHelper.MESSAGE_TIP_NUM = MESSAGE_TIP_NUM
function GiftHelper.Init()
    GiftHelper.RegEvent()
end

function GiftHelper.UnInit()

end

local nErrorCount = 0
local nLastForbidTime = 0
local nMaxErrCount = 3
local nForbidTime = 60 * 5 -- 5分钟内禁止提现

function GiftHelper.RegEvent()
    Event.Reg(self, "ON_GET_SMS_CODE_NOTIFY", function ()
        if arg1 == SMS_CODE_STATUS.WITHDRAW_CODE_FAILED then
            if nLastForbidTime > 0 and GetCurrentTime() - nLastForbidTime >= nForbidTime then
                nErrorCount = 0 -- 重置错误次数
                nLastForbidTime = 0
            end

            nErrorCount = nErrorCount + 1
            if nErrorCount >= nMaxErrCount then
                nLastForbidTime = GetCurrentTime()
                Event.Dispatch("ON_WITHDRAW_CODE_FAILED", nLastForbidTime)
                TipsHelper.ShowNormalTip(g_tStrings.WITHDRAW_CODE_FORBID)
            end
        end

        if g_tStrings.tTipErrorCode[arg1] then
            TipsHelper.ShowNormalTip(g_tStrings.tTipErrorCode[arg1])
        elseif g_tStrings.tTipSuccessCode[arg1] then
            TipsHelper.ShowNormalTip(g_tStrings.tTipSuccessCode[arg1])
        end
    end)

    Event.Reg(self, "TIP_IN_VOICE_ROOM_NOTIFY", function ()
        GiftHelper.OnVoiceRoomTip()
    end)
end

--获取提现的单次额度和每日额度
function GiftHelper.GetDailyQuotaInfo(bCertified)
    if bCertified then
        return WITHDRAW_LIMIT[1]
    end
    return WITHDRAW_LIMIT[0]
end

-- 是否是认证创作者
function GiftHelper.IsCertifiedCreator()
    if IsVersionTW() then
        return
    end

	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return false
	end

	local nValue = pPlayer.GetExtPoint(EXT_POINT.CERTIFICATION) or 0
	return nValue ~= 0
end

-- 获取剩余提现额度
function GiftHelper.GetRemainQuota()
    if IsVersionTW() then
        return
    end

    local pPlayer = GetClientPlayer()
	if not pPlayer then
		return 0
	end

    local nCanBeWithdrawn = pPlayer.GetExtPoint(EXT_POINT.REMIAN_QUOTA) or 0
    return nCanBeWithdrawn
end

-- 获取今日提现额度
function GiftHelper.GetDailyHaveQuota()
    if IsVersionTW() then
        return
    end

    local pPlayer = GetClientPlayer()
	if not pPlayer then
		return 0
	end

    local nRecordTime = pPlayer.GetExtPoint(EXT_POINT.WITHDRAW_TIMES) or 0
	local tRecord = TimeToDate(nRecordTime)
	local nDate = tRecord.year * 10000 + tRecord.month * 100 + tRecord.day  --提现记录里的上次提现时间
    local tCurrent = TimeToDate(GetCurrentTime())
	local nCurrentDate = tCurrent.year * 10000 + tCurrent.month * 100 + tCurrent.day --当下提现的时间

    if nDate < nCurrentDate then
        return 0
    else
        return pPlayer.GetExtPoint(EXT_POINT.DAILY_QUOTA) or 0
    end
end

-----------------↓打赏相关↓-----------------------
function GiftHelper.OpenTip(nTipType, tTarget, fnSendGift)
    local fnConfirm = function (tTipItem)
        local nNum = tTipItem.nNum or 1
        local nGold = tTipItem.nGoldNum
        local nTipItemID = tTipItem.dwID
        fnSendGift(nNum, nGold, nTipItemID)
    end

    if nTipType == TIP_TYPE.GlobalID then
        local tbMemberList = RoomVoiceData.GetVoiceRoomMemberList(tTarget.szRoomID)
        if not tbMemberList then
            return
        end
        local bNotOnline = true
        for _, tMemberInfo in pairs(tbMemberList) do
            if tMemberInfo.szGlobalID == tTarget.szGlobalID then
                bNotOnline = tMemberInfo.bNotOnline
                break
            end
        end
        if bNotOnline then
            TipsHelper.ShowNormalTip(g_tStrings.STR_VOICE_REWARD_NUM_NOT_ONLINE)
            return
        end
    end

    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.COIN) then
        return
    end

    UIMgr.Open(VIEW_ID.PanelSendGiftNewPop, nTipType, tTarget, fnConfirm)
end

function GiftHelper.TipByShareCode(nShareType, szShareCode, szProduct, nNum, nGold, nTipItemID)
    if IsVersionTW() then
        return
    end

    local player = GetClientPlayer()
    if not player then
        return
    end

    if nNum <= 0 then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_VOICE_REWARD_INVALID_NUM)
        return false
    end

    local nGoldNum = player.GetMoney().nGold or 0
    if nGoldNum < nGold * nNum then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_VOICE_REWARD_NOT_ENOUGH_GOLD)
        return false
    end

    local bRet = player.TipByShareCode(nShareType, szShareCode, nNum, nGold, nTipItemID, szProduct, TIP_TYPE.ShareStation)
    if bRet then
        UIMgr.Close(VIEW_ID.PanelSendGiftNewPop)
        -- TipsHelper.ShowNormalTip(g_tStrings.STR_VOICE_REWARD_SUCCESS)
        Event.Dispatch(EventType.OnTipsGiftSuccess, TIP_TYPE.ShareStation, nGold, nNum, szProduct)
    end
    return bRet
end

function GiftHelper.TipByGlobalID(nCenteriD, szGloballD, nNum, nGold, nTipItemID, szRoomName, szRoomID, nTipType, szTargetName)
    if IsVersionTW() then
        return
    end

    local player = GetClientPlayer()
    if not player then
        return
    end

    if not nCenteriD or nCenteriD == 0 then
        return false
    end

    if nNum <= 0 then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_VOICE_REWARD_INVALID_NUM)
        return false
    end

    local nGoldNum = player.GetMoney().nGold or 0
    if nGoldNum < nGold * nNum then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_VOICE_REWARD_NOT_ENOUGH_GOLD)
        return false
    end

    local bRet = player.TipByGlobalID(nCenteriD, szGloballD, nNum, nGold, nTipItemID, szRoomName, nTipType or TIP_TYPE.GlobalID, szRoomID)
    if bRet then
        UIMgr.Close(VIEW_ID.PanelSendGiftNewPop)
        -- TipsHelper.ShowNormalTip(g_tStrings.STR_VOICE_REWARD_SUCCESS)
        Event.Dispatch(EventType.OnTipsGiftSuccess, nTipType or TIP_TYPE.GlobalID, nGold, nNum, szTargetName)
    end
    return bRet
end

-- 打赏副本观战全团成员
function GiftHelper.TipDungeonAllTeam(nTeamNum, nNum, nGold, nTipItemID, nTipType, szTeamName)
    if IsVersionTW() then
        return
    end

    local player = GetClientPlayer()
    if not player then
        return
    end

    if nNum <= 0 then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_VOICE_REWARD_INVALID_NUM)
        return false
    end

    local nGoldNum = player.GetMoney().nGold or 0
    if nGoldNum < nGold * nNum * nTeamNum then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_VOICE_REWARD_NOT_ENOUGH_GOLD)
        return false
    end

    local szContent = FormatString(g_tStrings.STR_VOICE_REWARD_NUM_BIG_MESSAGE, nGold * nNum * nTeamNum)
    UIHelper.ShowConfirm(szContent, function()
        local pScene = GetClientPlayer() and GetClientPlayer().GetScene()
        if not pScene then return end

        local szMapName = Table_GetMapName(pScene.dwMapID) .. "|" .. player.dwCenterID .. "|" .. pScene.nCopyIndex
        local tTeamPlayer = OBDungeonData.GetDungeonCompetitorsList()
        if not tTeamPlayer then return end

        local bRet = false
        for dwPlayerID, tTargetPlayer in pairs(tTeamPlayer) do
            local TargetPlayer = GetPlayer(dwPlayerID)
            if TargetPlayer then
                local szGlobalID = TargetPlayer.GetGlobalID()
                local dwCenterID = tTargetPlayer.dwCenterID or TargetPlayer.dwCenterID
                bRet = player.TipByGlobalID(dwCenterID, szGlobalID, nNum, nGold, nTipItemID, szMapName, nTipType, "1")
            end
        end

        if bRet then
            UIMgr.Close(VIEW_ID.PanelSendGiftNewPop)
            -- TipsHelper.ShowNormalTip(g_tStrings.STR_VOICE_REWARD_SUCCESS)
            Event.Dispatch(EventType.OnTipsGiftSuccess, nTipType or TIP_TYPE.ObserveInstance_Team, nGold, nNum, szTeamName)
        end
    end)
end

function GiftHelper.RegGiftEffect(script, widget, eff)
    if not widget and not eff then
        return
    end

    Event.Reg(script, EventType.OnTipsGiftSuccess, function(nType, nGold, nNum, szProductName, szSrcGlobalID, szTargetGlobalID)
        local tItem = nil
        local tTipItemList = Table_GetTipItemList()
        for _, tTipItem in pairs(tTipItemList) do
            if tTipItem.nGoldNum == nGold then
                tItem = tTipItem
            end
        end

        Timer.Add(script, 0.1, function()
            local scriptWidget = UIHelper.GetBindScript(widget)
            if tItem then
                local bUp = tItem.nUpNum and tItem.nUpNum <= nNum
                local szSFXPath = bUp and tItem.szUpSfxPath or tItem.szSfxPath
                UIHelper.SetVisible(eff, true)
                UIHelper.SetSFXPath(eff, szSFXPath, 0)
                UIHelper.PlaySFX(eff, 0)

                if nType == TIP_TYPE.ShareStation and scriptWidget then
                    local szGiftName = string.format(g_tStrings.STR_TIPS_GIFT_NAME, UIHelper.GBKToUTF8(tItem.szName), nNum)
                    local szIcon = bUp and tItem.szUpImagePath or tItem.szImagePath
                    szIcon = UIHelper.FixDXUIImagePath(szIcon)

                    UIHelper.SetString(scriptWidget.LabelGiftName, szGiftName)
                    UIHelper.SetString(scriptWidget.LabelSend, string.format(g_tStrings.STR_TIPS_GIFT_SEND, UIHelper.GBKToUTF8(szProductName)))
                    UIHelper.SetTexture(scriptWidget.ImgZhuan, szIcon)
                    UIHelper.SetVisible(scriptWidget.ImgZhuan, true)
                    UIHelper.SetVisible(scriptWidget._rootNode, true)

                    UIHelper.StopAni(script, scriptWidget._rootNode, "AniGiveGiftsShow")
                    UIHelper.PlayAni(script, scriptWidget._rootNode, "AniGiveGiftsShow", function()
                        UIHelper.PlayAni(script, scriptWidget._rootNode, "AniGiveGiftsHide")
                    end)
                    return
                end

                Timer.Add(script, tItem.nShowTime / 1000 or 2, function()
                    UIHelper.SetVisible(widget, false)
                    UIHelper.SetVisible(eff, false)
                end)
            end
        end)
    end)
end

function GiftHelper.OnVoiceRoomTip()
    local szSrcGlobalID = arg0
    local szTargetGlobalID = arg1
    local nGold = arg2
    local nNum = arg3

    local tItem = nil
    local tTipItemList = Table_GetTipItemList()
    for _, tTipItem in pairs(tTipItemList) do
        if tTipItem.nGoldNum == nGold then
            tItem = tTipItem
        end
    end

    if not tItem then
        return
    end

    local tSrcInfo = RoomVoiceData.GetRoomMemberSocialInfo(szSrcGlobalID)
    local tRecInfo = RoomVoiceData.GetRoomMemberSocialInfo(szTargetGlobalID)

    local function GetAppendText(tSrcInfo, tRecInfo)
        local szFlowerIcon = "<img emojiid='64' src='' width='30' height='30'/>"
        local szSrcName = RoomData.GetGlobalName(tSrcInfo.szName, tSrcInfo.dwCenterID, true)
        local szRecName = RoomData.GetGlobalName(tRecInfo.szName, tRecInfo.dwCenterID, true)
        local szGift = "[" .. tItem.szName .. "]x" .. nNum
        local szTip = FormatString(UIHelper.UTF8ToGBK(g_tStrings.STR_VOICE_REWARD_TIP_MESSAGE) .. szGift, szSrcName, szRecName)
        szTip = UIHelper.GBKToUTF8(szTip)
        szTip = szTip .. szFlowerIcon .. szFlowerIcon
        return szTip
    end

    -- OutputMessage("MSG_SYS", szTip, true)
    if tSrcInfo.bDefault or tRecInfo.bDefault then
        Timer.Add(self, 1, function()
            local tSrcInfo = RoomVoiceData.GetRoomMemberSocialInfo(szSrcGlobalID)
            local tRecInfo = RoomVoiceData.GetRoomMemberSocialInfo(szTargetGlobalID)
            ChatData.Append(GetAppendText(tSrcInfo, tRecInfo), 0, PLAYER_TALK_CHANNEL.VOICE_ROOM, false, "")
        end)
    else
        ChatData.Append(GetAppendText(tSrcInfo, tRecInfo), 0, PLAYER_TALK_CHANNEL.VOICE_ROOM, false, "")
    end
end

-----------------↑打赏相关↑-----------------------

-----------------↓提现相关↓-----------------------
function GiftHelper.WithdrawDeposit(szSMSCode, nGold)
    if IsVersionTW() then
        return
    end

    local player = GetClientPlayer()
    if not player then
        return
    end

    local nCurrentTime = GetCurrentTime()
    if nCurrentTime - nLastForbidTime < nForbidTime then
        TipsHelper.ShowNormalTip(g_tStrings.WITHDRAW_CODE_FORBID)
        return
    end

    local bRet = player.WithdrawDeposit(szSMSCode, nGold)
    return bRet
end

function GiftHelper.GetSMSCode(nType)
    if IsVersionTW() then
        return
    end

    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.COIN) then
        return
    end

    local player = GetClientPlayer()
    if not player then
        return
    end

    local bRet = player.GetSMSCode()
    return bRet
end

-- 获取验证码状态
function GiftHelper.GetTipStatus()
    if IsVersionTW() then
        return
    end

    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    return pPlayer.GetTipStatus()
end

function GiftHelper.Link2Certif()
    WebUrl.OpenByID(CERTIFICATION_URL_ID)
end

function GiftHelper.Link2GM()
    WebUrl.OpenByID(GM_SUPPORT_URL_ID)
end
-------------------↑提现相关↑-----------------------