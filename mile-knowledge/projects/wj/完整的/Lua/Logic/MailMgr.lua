-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: MailMgr
-- Date: 2023-12-23 19:47:01
-- Desc: ?
-- ---------------------------------------------------------------------------------

MailMgr = MailMgr or {className = "MailMgr"}
local self = MailMgr
-------------------------------- 消息定义 --------------------------------
MailMgr.Event = {}
MailMgr.Event.XXX = "MailMgr.Msg.XXX"

function MailMgr.Init()
    Event.Reg(self, EventType.OnRoleLogin, function()
        Event.Reg(self, "LOADING_END", function()
            GetMailClient().ApplyMailList()
        end, true)
    end)

end

function MailMgr.UnInit()

end

function MailMgr.OnLogin()

end

function MailMgr.OnFirstLoadEnd()

end

function MailMgr.ApplyMailList()
    GetMailClient().ApplyMailList()
end

function MailMgr.GetMailList(szFilter)
    return GetMailClient().GetMailList(szFilter) or {}
end

function MailMgr.GetOfficialMailList()
    local aSystemMail = GetMailClient().GetMailList("system") or {}
    local aAuctionMail = GetMailClient().GetMailList("auction") or {}

    for _,v in ipairs(aAuctionMail) do
        table.insert(aSystemMail,v)
    end

    table.sort(aSystemMail, function (a, b)
        return a > b
    end)

    return aSystemMail
end

function MailMgr.GetPlayerMailList()
    local aPlayerMail = GetMailClient().GetMailList("player") or {}

    table.sort(aPlayerMail, function (a, b)
        return a > b
    end)

    return aPlayerMail
end

function MailMgr.GetAllMailList()
    local aSystemMail = GetMailClient().GetMailList("system") or {}
    local aPlayerMail = GetMailClient().GetMailList("player") or {}
    local aAuctionMail = GetMailClient().GetMailList("auction") or {}

    for _,v in ipairs(aAuctionMail) do
        table.insert(aSystemMail,v)
    end

    table.sort(aSystemMail, function (a, b)
        return a > b
    end)

    table.sort(aPlayerMail, function (a, b)
        return a > b
    end)

    return aSystemMail, aPlayerMail
end

function MailMgr.GetMailInfo(dwID)
    return GetMailClient().GetMailInfo(dwID)
end

function MailMgr.DeleteMail(dwID)
    GetMailClient().DeleteMail(dwID)
end

function MailMgr.ReturnMail(dwID)
    GetMailClient().ReturnMail(dwID)
end

function MailMgr.GetMailCount(szFilter)
    if szFilter == "system" then
        local aMail  = GetMailClient().GetMailList("system") or {}
        local aMail1 = GetMailClient().GetMailList("auction") or {}

        return #(aMail) + #(aMail1)
    else
        local aMail  = GetMailClient().GetMailList("player") or {}

        return #(aMail)
    end
end

function MailMgr.GetMailTip()
    local pScene = GetClientScene()
    local bEnable = not pScene.GetMapOperationState(MAP_OPERATION_TYPE.DISABLE_MAIL_BOX)
    if not bEnable then
        TipsHelper.ShowNormalTip(g_tStrings.STR_MAIL_DISABLE_TIPS1)
    elseif g_pClientPlayer.bFightState then
        TipsHelper.ShowNormalTip(g_tStrings.STR_MAIL_DISABLE_TIPS3)
    elseif g_pClientPlayer.nMoveState == MOVE_STATE.ON_DEATH then
        TipsHelper.ShowNormalTip(g_tStrings.STR_MAIL_DISABLE_TIPS2)
    end
end