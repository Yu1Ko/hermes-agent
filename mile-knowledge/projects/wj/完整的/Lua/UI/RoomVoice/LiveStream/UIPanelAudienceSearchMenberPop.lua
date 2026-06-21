-- ---------------------------------------------------------------------------------
-- Author: KSG
-- Name: UIPanelAudienceSearchMenberPop
-- Date: 2026-03-30
-- Desc: 副本观战观众搜索弹窗（替换原 UIPanelVoiceRoomSearchMenberPopView 绑定）
-- ---------------------------------------------------------------------------------

local UIPanelAudienceSearchMenberPop = class("UIPanelAudienceSearchMenberPop")

function UIPanelAudienceSearchMenberPop:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bIsLeader = OBDungeonData.IsPlayerDungeonOwner()
    self.tAudienceList = OBDungeonData.GetAllDungeonOBPlayer() or {}
    self:UpdateInfo()
end

function UIPanelAudienceSearchMenberPop:OnExit()
    self.bInit = false
end

function UIPanelAudienceSearchMenberPop:RegEvent()
    Event.Reg(self, "SYNC_VOICE_MEMBER_SOCIAL_INFO", function()
        if not self.bInit then return end
        -- 社交信息同步后重新按当前关键字搜索
        local szKey = UIHelper.GetText(self.EditBoxFactionSearch)
        self:UpdateInfo(szKey)
    end)
end

function UIPanelAudienceSearchMenberPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxFactionSearch, function()
        local szKey = UIHelper.GetText(self.EditBoxFactionSearch)
        self:UpdateInfo(szKey)
    end)
end

-- 根据关键字过滤观众列表
function UIPanelAudienceSearchMenberPop:GetFilteredList(szKey)
    if not szKey or szKey == "" then
        return {}
    end
    local tResult = {}
    for _, szGlobalID in ipairs(self.tAudienceList) do
        local tSocialInfo = RoomVoiceData.GetVoiceRoomMemberSocialInfo(szGlobalID)
        if tSocialInfo and tSocialInfo.szName then
            local szNameUTF8 = UIHelper.GBKToUTF8(tSocialInfo.szName)
            if szNameUTF8 and string.find(szNameUTF8, szKey, 1, true) then
                table.insert(tResult, szGlobalID)
            end
        end
    end
    return tResult
end

function UIPanelAudienceSearchMenberPop:UpdateInfo(szKey)
    UIHelper.RemoveAllChildren(self.ScrollViewRoomPlayerList)
    local tFiltered = self:GetFilteredList(szKey)
    local bHasAny = #tFiltered > 0

    UIHelper.SetVisible(self.WidgetEmpty, not bHasAny)

    for _, szGlobalID in ipairs(tFiltered) do
        local tSocialInfo = RoomVoiceData.GetVoiceRoomMemberSocialInfo(szGlobalID)
        local szName = (tSocialInfo and tSocialInfo.szName) or ""
        -- 拼接服务器名用于踢出确认弹窗
        local szDisplayName = szName
        if tSocialInfo and tSocialInfo.dwCenterID and tSocialInfo.dwCenterID > 0 then
            local szCenterName = GetCenterNameByCenterID(tSocialInfo.dwCenterID)
            if szCenterName and szCenterName ~= "" then
                szDisplayName = szName .. UIHelper.UTF8ToGBK("·").. szCenterName
            end
        end
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetAudienceItem, self.ScrollViewRoomPlayerList,
            szGlobalID, szName, self.bIsLeader)
        if script then
            script.fnKickCallback = function()
                self:OnKickAudience(szGlobalID, szDisplayName)
            end
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRoomPlayerList)
end

-- 踢出观众确认
function UIPanelAudienceSearchMenberPop:OnKickAudience(szGlobalID, szPlayerName)
    if not self.bIsLeader then
        return
    end
    szPlayerName = UIHelper.GBKToUTF8(szPlayerName or "")
    local szMsg = string.format(g_tStrings.STR_OBDUNGEON_REMOVE_AUDIENCE_TIP, szPlayerName)
    UIHelper.ShowConfirm(szMsg, function()
        OBDungeonData.KickOutOB(szGlobalID)
        RoomVoiceData.ApplyLiveStreamMapRoleList(LIVE_STREAM_MEMBER_TYPE.OBSERVER)
    end)
end

return UIPanelAudienceSearchMenberPop
