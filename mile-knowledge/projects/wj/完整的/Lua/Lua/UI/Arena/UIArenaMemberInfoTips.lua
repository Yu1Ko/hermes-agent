-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaMemberInfoTips
-- Date: 2023-07-10 15:06:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaMemberInfoTips = class("UIArenaMemberInfoTips")

function UIArenaMemberInfoTips:OnEnter(nArenaType, tbInfo)
    self.nArenaType = nArenaType
    self.tbInfo = tbInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIArenaMemberInfoTips:OnExit()
    self.bInit = false
end

function UIArenaMemberInfoTips:BindUIEvent()
    UIHelper.SetTouchDownHideTips(self.TogTeam, false)
    UIHelper.BindUIEvent(self.TogTeam, EventType.OnClick, function()
        TeamData.InviteJoinTeam(self.tbInfo.szPlayerName)
        TipsHelper.ShowNormalTip("已发送组队申请")

        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetJJCTeammate)
    end)

    UIHelper.SetTouchDownHideTips(self.TogChat, false)
    UIHelper.BindUIEvent(self.TogChat, EventType.OnClick, function()
        ChatHelper.Chat(UI_Chat_Channel.Whisper)

        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetJJCTeammate)
    end)

    UIHelper.SetTouchDownHideTips(self.TogRemove, false)
    UIHelper.BindUIEvent(self.TogRemove, EventType.OnClick, function()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.ARENA, "") then
            return
        end

        local nPlayerID = PlayerData.GetPlayerID()
        local nCorpsID = ArenaData.GetCorpsID(self.nArenaType, nPlayerID)

        if not nCorpsID or nCorpsID <= 0 then
            TipsHelper.ShowNormalTip("你当前暂无战队")
            return
        end

        local szContent = FormatString(g_tStrings.STR_AREAN_REMOVE_TIP, UIHelper.GBKToUTF8(self.tbInfo.szPlayerName or ""))
        szContent = string.pure_text(szContent)
        local fnConfirm = function ()
            ArenaData.CorpsDelMember(self.tbInfo.dwPlayerID, nCorpsID)
        end
        local scriptDialog = UIHelper.ShowConfirm(szContent, fnConfirm, nil, false)

        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetJJCTeammate)
    end)

    UIHelper.SetTouchDownHideTips(self.TogCaptain, false)
    UIHelper.BindUIEvent(self.TogCaptain, EventType.OnClick, function()
        local nPlayerID = PlayerData.GetPlayerID()
        local nCorpsID = ArenaData.GetCorpsID(self.nArenaType, nPlayerID)

        if not nCorpsID or nCorpsID <= 0 then
            TipsHelper.ShowNormalTip("你当前暂无战队")
            return
        end

        local szContent = FormatString(g_tStrings.STR_ARENA_CHANGE_SURE_TIP, g_tStrings.tCorpsType[self.nArenaType])
        szContent = string.pure_text(szContent)
        local fnConfirm = function ()
            ArenaData.CorpsChangeLeader(self.tbInfo.dwPlayerID, nCorpsID)
        end
        local scriptDialog = UIHelper.ShowConfirm(szContent, fnConfirm, nil, false)

        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetJJCTeammate)
    end)
end

function UIArenaMemberInfoTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIArenaMemberInfoTips:UpdateInfo()
    self.scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetPlayerHead, self.tbInfo.dwPlayerID)
    if not GetPlayer(self.tbInfo.dwPlayerID) then
        self.scriptHead:SetHeadWithForceID(self.tbInfo.dwForceID)
    end
    UIHelper.SetString(self.LableCamp, g_tStrings.STR_CAMP_TITLE[self.tbInfo.nCamp])

    local szTongName = UIHelper.GBKToUTF8(self.tbInfo.szTongName or "")
    if szTongName == "" then
        szTongName = "无"
    end
    UIHelper.SetString(self.LableGroup, szTongName)
    UIHelper.SetString(self.LableName, UIHelper.GBKToUTF8(self.tbInfo.szPlayerName or ""))
    UIHelper.SetString(self.LableLevel, string.format("%d级", self.tbInfo.nLevel or 0))
    UIHelper.SetSpriteFrame(self.Img_level, PlayerForceID2SchoolImg[self.tbInfo.dwForceID])

    local bLeader = self:IsLeader()
    UIHelper.SetVisible(self.TogRemove, bLeader)
    UIHelper.SetVisible(self.TogCaptain, bLeader)
    UIHelper.LayoutDoLayout(self.LayoutPlayerMenu)
end

function UIArenaMemberInfoTips:IsLeader()
    local bLeader = false
    local nSelfPlayerID = PlayerData.GetPlayerID()
    local tbMemberData = ArenaData.tbCorpsMemberInfo[self.nArenaType] or {}
    for _, tbInfo in ipairs(tbMemberData) do
        if tbInfo.bLeader and nSelfPlayerID == tbInfo.dwPlayerID then
            bLeader = true
            break
        end
    end

    return bLeader
end

return UIArenaMemberInfoTips