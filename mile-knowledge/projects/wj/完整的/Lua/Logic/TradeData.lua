TradeData = TradeData or {className = "TradeData"}
local self = TradeData
local nTradeInviteExistTime = 300 -- s

function TradeData.Init()
    self.RegEvent()
end

function TradeData.UnInit()
    Event.UnRegAll(self)
end

function TradeData.RegEvent()
    Event.Reg(self, "TRADING_OPEN_NOTIFY", function(dwID)
        --print("[Trade] TRADING_OPEN_NOTIFY", dwID)
        self.OnTradingOpenNotify(dwID)
    end)
    Event.Reg(self, "TRADING_INVITE", function(dwPlayerID)
        --print("[Trade] TRADING_INVITE", dwPlayerID)
        self.OnTradingInvite(dwPlayerID)
    end)
end

function TradeData.OnTradingOpenNotify(dwID)
     if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TRADE) then
         TradingConfirm(false)
         return
     end

    local player = GetClientPlayer()
    if not player or player.nMoveState == MOVE_STATE.ON_DEATH then
        return
    end

    UIMgr.Open(VIEW_ID.PanelTransaction, dwID)
end

function TradeData.OnTradingInvite(dwPlayerID)
    local player = GetPlayer(dwPlayerID)
    if not IsRegisterEvent("TRADING_INVITE") then
        player.TradingInviteRespond(false)
        return
    end

    if FellowshipData.IsInBlackListByPlayerID(dwPlayerID) then 
        player.TradingInviteRespond(false)
        return 
    end

    local fnTradingReply = function(bAgree)
        local me = GetClientPlayer()
        if bAgree then
            if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TRADE) then
                Event.Dispatch(EventType.OnTimelyHintTipsSwitchToSmall, true, EventType.ShowTradeTip)
                return false
            end
            me.TradingInviteRespond(true)
        else
            local player = GetPlayer(dwPlayerID)
            if not player or not player.CanDialog(me) then
                OutputMessage("MSG_SYS", g_tStrings.STR_TRADING_CANCEL_REASON_TOO_FAR)
            -- elseif player.nMoveState == MOVE_STATE.ON_DEATH then
            --     OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_TRADING_CANCEL_REASON_WHO_DIE, UIHelper.GBKToUTF8(player.szName)))
            -- elseif me.nMoveState == MOVE_STATE.ON_DEATH then
            --     OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_TRADING_CANCEL_REASON_WHO_DIE, g_tStrings.STR_YOU))
            else
                OutputMessage("MSG_SYS", g_tStrings.STR_TRADING_YOU_CANCEL)
                PlayTipSound("054")
            end
            me.TradingInviteRespond(false)
        end
    end

    local fnAutoCloseTrade = function()
        local player = GetPlayer(dwPlayerID)
        if not player or not player.CanDialog(GetClientPlayer()) or player.nMoveState == MOVE_STATE.ON_DEATH or GetClientPlayer().nMoveState == MOVE_STATE.ON_DEATH then
            fnTradingReply(false)
            return true
        end
    end

    if IsFilterOperate("TRADING_INVITE") then
        fnTradingReply(false)
        return
    end

    if SceneMgr.IsLoading() then
        fnTradingReply(false)
        return
    end

    local fnCancelAction = function()
        -- BubbleMsgData.RemoveMsg("TradeInviteTip")
        return fnTradingReply(false)
    end

    local tbMsgInfo = {
        szType = "TradeInviteTip",
        szInviterName = player.szName,
        -- fnConfirmAction = fnConfirmAction,
        fnCancelAction = fnCancelAction,
        fnAutoClose = fnAutoCloseTrade
    }
    TipsHelper.ShowTradeTip(tbMsgInfo)
end

function TradeData.GetTimelyHintMaxExistTime()
   return nTradeInviteExistTime
end