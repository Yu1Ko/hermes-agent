-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelVoiceRoomSearchMenberPopView
-- Date: 2025-09-16 16:16:56
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelVoiceRoomSearchMenberPopView = class("UIPanelVoiceRoomSearchMenberPopView")

function UIPanelVoiceRoomSearchMenberPopView:OnEnter(szRoomID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szRoomID = szRoomID
    self:UpdateInfo()
end

function UIPanelVoiceRoomSearchMenberPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelVoiceRoomSearchMenberPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxFactionSearch, function()
        local szKey = UIHelper.GetText(self.EditBoxFactionSearch)
        self:UpdateInfo(szKey)
    end)
end

function UIPanelVoiceRoomSearchMenberPopView:RegEvent()
    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID == VIEW_ID.PanelTutorialCollection or
            nViewID == VIEW_ID.PanelOtherPlayer then
                UIMgr.Close(self)
        end
    end)
end

function UIPanelVoiceRoomSearchMenberPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelVoiceRoomSearchMenberPopView:GetMemberList(szKey)
    if not szKey or szKey == "" then
        return {}
    end
    local tbMemberList = RoomVoiceData.GetVoiceRoomMemberList(self.szRoomID)
    local tbResult = {}
    for nIndex, tbMember in ipairs(tbMemberList) do
        local tbInfo = RoomVoiceData.GetVoiceRoomMemberSocialInfo(tbMember.szGlobalID)
        if tbInfo and string.match(UIHelper.GBKToUTF8(tbInfo.szName), szKey) then
            table.insert(tbResult, tbMember)
        end
    end
    return tbResult
end

function UIPanelVoiceRoomSearchMenberPopView:UpdateInfo(szKey)
    UIHelper.RemoveAllChildren(self.ScrollViewRoomPlayerList)
    local tbMemberList = self:GetMemberList(szKey)
    for nIndex = 1, #tbMemberList, 4 do
        local tbMemList = {}
        for index = nIndex, nIndex + 3 do
            if tbMemberList[index] then
                table.insert(tbMemList, tbMemberList[index])
            end
        end
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetMicPlayerCellGroup, self.ScrollViewRoomPlayerList)
        script:InitInfo(self.szRoomID, tbMemList, false, function(tbMenuConfig, tbRoleInfo, node, szGlobalID, tFromRoom)
            local tips, script = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPlayerPop, node, szGlobalID, tbMenuConfig, tbRoleInfo, false, false, tFromRoom)
        end)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRoomPlayerList)
    UIHelper.SetVisible(self.WidgetEmpty, #tbMemberList == 0)
end

return UIPanelVoiceRoomSearchMenberPopView