-- ---------------------------------------------------------------------------------
-- Author: KSG
-- Name: UIPanelAudienceList
-- Date: 2026-03-24
-- Desc: 副本观战观众列表面板（参考 PC 端 AudienceListPanel.lua）
-- ---------------------------------------------------------------------------------

local UIPanelAudienceList = class("UIPanelAudienceList")

function UIPanelAudienceList:OnEnter()
    if not self.bInit then
        self:InitScrollList()
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bIsLeader = OBDungeonData.IsPlayerDungeonOwner()
    self.tAudienceList = {}

    -- 申请观众列表数据
    RoomVoiceData.ApplyLiveStreamMapRoleList(LIVE_STREAM_MEMBER_TYPE.OBSERVER)
    self:UpdateInfo()
end

function UIPanelAudienceList:OnExit()
    self:UninitScrollList()
    self.bInit = false
end

function UIPanelAudienceList:RegEvent()
    -- 观众列表数据同步（对应 PC 端 ON_DUNGEON_OB_AUDIENCE_LIST_UPDAT）
    Event.Reg(self, EventType.ON_LIVE_STREAM_INFO_UPDATE, function()
        if not self.bInit then return end
        self:UpdateInfo()
    end)

    -- 社交信息同步完成后刷新显示
    Event.Reg(self, "SYNC_VOICE_MEMBER_SOCIAL_INFO", function()
        if not self.bInit then return end
        self:UpdateInfo()
    end)

    -- 队长权限变更：非队长关闭面板
    Event.Reg(self, "TEAM_AUTHORITY_CHANGED", function(nAuthorityType)
        if not self.bInit then return end
        if nAuthorityType == TEAM_AUTHORITY_TYPE.LEADER then
            self.bIsLeader = OBDungeonData.IsPlayerDungeonOwner()
            if not self.bIsLeader then
                UIMgr.Close(VIEW_ID.PanelAudienceList)
            end
        end
    end)
end

function UIPanelAudienceList:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnSearch, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelAudienceSearchMenberPop)
    end)
end

function UIPanelAudienceList:InitScrollList()
    if self.tScrollList then return end
    self.tScrollList = UIScrollList.Create({
        listNode = self.LayoutAudienceList,
        fnGetCellType = function(nIndex)
            return "WidgetAudienceItem"
        end,
        fnUpdateCell = function(cell, nIndex)
            self:UpdateAudienceCell(cell, nIndex)
        end,
    })
end

function UIPanelAudienceList:UninitScrollList()
    if self.tScrollList then
        self.tScrollList:Destroy()
        self.tScrollList = nil
    end
end

function UIPanelAudienceList:UpdateAudienceCell(cell, nIndex)
    local szGlobalID = self.tAudienceList[nIndex]
    if not szGlobalID then return end
    local tSocialInfo = RoomVoiceData.GetVoiceRoomMemberSocialInfo(szGlobalID)
    local szName = (tSocialInfo and tSocialInfo.szName) or ""
    local szDisplayName = szName
    if tSocialInfo and tSocialInfo.dwCenterID and tSocialInfo.dwCenterID > 0 then
        local szCenterName = GetCenterNameByCenterID(tSocialInfo.dwCenterID)
        if szCenterName and szCenterName ~= "" then
            szDisplayName = szName .. "·" .. szCenterName
        end
    end
    cell.szGlobalID = szGlobalID
    cell.fnKickCallback = function()
        self:OnKickAudience(szGlobalID, szDisplayName)
    end
    cell:UpdateInfo(szName, self.bIsLeader)
end

-- 刷新观众列表
function UIPanelAudienceList:UpdateInfo()
    self.tAudienceList = OBDungeonData.GetAllDungeonOBPlayer()
    local nCount = #self.tAudienceList
    local bHasAny = nCount > 0

    UIHelper.SetVisible(self.WidgetEmpty, not bHasAny)

    -- 批量申请社交信息
    if bHasAny then
        RoomVoiceData.ApplyVoiceMemberSocialInfo(self.tAudienceList)
    end

    if self.tScrollList then
        self.tScrollList:Reset(nCount)
    end
end

-- 踢出观众确认
function UIPanelAudienceList:OnKickAudience(szGlobalID, szPlayerName)
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

return UIPanelAudienceList
