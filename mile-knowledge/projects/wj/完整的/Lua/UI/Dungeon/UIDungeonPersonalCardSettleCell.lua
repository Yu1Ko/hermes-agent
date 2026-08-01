-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIDungeonPersonalCardSettleCell
-- Date: 2026-01-11 11:09:46
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIDungeonPersonalCardSettleCell = class("UIDungeonPersonalCardSettleCell")

function UIDungeonPersonalCardSettleCell:OnEnter(tExcellent)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tExcellent = tExcellent
    self:UpdateInfo()
end

function UIDungeonPersonalCardSettleCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIDungeonPersonalCardSettleCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnPriaise, EventType.OnClick, function ()
        local dwLeaderID, tInfo = DungeonSettleCardData.GetTeamLeaderInfo()
        if not dwLeaderID or not tInfo then
            return
        end

        if not self.tExcellent.bPraised then
            self.tExcellent.bPraised = true
            UIHelper.SetSpriteFrame(self.ImgPraise, ArenaPraiseIconPath.PraisedIconPath)
            RemoteCallToServer("On_FriendPraise_AddRequest", UI_GetClientPlayerID(), dwLeaderID, PRAISE_TYPE.GREAT_LEADER, tInfo.szGlobalID)
            RemoteCallToServer("On_FriendPraise_AddRequest", UI_GetClientPlayerID(), dwLeaderID, PRAISE_TYPE.TEAM_LEADER, tInfo.szGlobalID)
        end
    end)
end

function UIDungeonPersonalCardSettleCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDungeonPersonalCardSettleCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIDungeonPersonalCardSettleCell:UpdateInfo()
    local tExcellent = self.tExcellent
    if not tExcellent then
        return
    end
    UIHelper.SetVisible(self.BtnPriaise, tExcellent.dwID == DUNGEON_EXCELLENT_ID.GREAT_LEADER)
    UIHelper.SetString(self.LabelMvpLabel, tExcellent.szName and UIHelper.GBKToUTF8(tExcellent.szName) or "")
    UIHelper.SetSpriteFrame(self.ImgMvpLabel, tExcellent.szMBImagePath)
    UIHelper.SetSpriteFrame(self.ImgMvpLabelBg1, tExcellent.szMBBgImagePath)
    if self.tExcellent.bPraised then
        UIHelper.SetSpriteFrame(self.ImgPraise, ArenaPraiseIconPath.PraisedIconPath)
    end

    if string.is_nil(tExcellent.szMBBgImagePath) then
        UIHelper.SetVisible(self.LabelMvpLabel, true)
    end

    UIHelper.SetSFXPath(self.Eff_ZuiJia, tExcellent.szSfxPath)
    UIHelper.PlaySFX(self.Eff_ZuiJia, 0)

    local tPlayerInfo = tExcellent.tPlayerInfo
    UIHelper.RemoveAllChildren(self.WidgetPersonalCard)
    self.scriptCard = UIHelper.AddPrefab(PREFAB_ID.WidgetPersonalCard, self.WidgetPersonalCard, tExcellent.szGlobalID)
    self.scriptCard:SetPlayerId(tExcellent.dwPlayerID)
    if self.scriptCard and tPlayerInfo then
        local tInfo = {
            szName = tPlayerInfo.szName and UIHelper.GBKToUTF8(tPlayerInfo.szName) or "",
            dwPlayerID = tExcellent.dwPlayerID,
            dwMiniAvatarID = tPlayerInfo.dwMiniAvatarID,
            nRoleType = tPlayerInfo.nRoleType,
            dwForceID = tPlayerInfo.dwForceID,
            nLevel = tPlayerInfo.nLevel
        }
        self.scriptCard:SetPersonalInfo(tInfo)
        self.scriptCard:OnEnter(tExcellent.szGlobalID)
    end
    UIHelper.SetAnchorPoint(self.scriptCard._rootNode, 0.5, 0.5)
end


return UIDungeonPersonalCardSettleCell