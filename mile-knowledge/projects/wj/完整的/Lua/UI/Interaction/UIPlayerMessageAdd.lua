-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPlayerMessageAdd
-- Date: 2023-04-24 16:56:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPlayerMessageAdd = class("UIPlayerMessageAdd")
local AROUND_PLAYER_TYPE = -1

function UIPlayerMessageAdd:OnEnter(nRelationType, tbPlayerInfo, nDisplayMode, tbPlayerCard, dwPushType)
    self.nRelationType = nRelationType
    self.nDisplayMode = nDisplayMode or 0
    self.tbPlayerInfo = tbPlayerInfo
    self.tbPlayerCard = tbPlayerCard or (self.tbPlayerInfo and FellowshipData.GetFellowshipCardInfo(self.tbPlayerInfo.id)) or {}
    self.dwPushType = dwPushType

    if not self.tbPlayerCard.dwForceID then
        self.tbPlayerCard.dwForceID = self.tbPlayerCard.nForceID
    end

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if tbPlayerInfo then
        self:UpdateInfo()
        UIHelper.SetVisible(self._rootNode, true)
    else
        UIHelper.SetVisible(self._rootNode, false)
    end
end

function UIPlayerMessageAdd:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPlayerMessageAdd:BindUIEvent()
    -- 查看装备
    UIHelper.BindUIEvent(self.BtnQuery, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelOtherPlayer, self.tbPlayerInfo.id or self.tbPlayerInfo.dwID)
        UIMgr.HideView(VIEW_ID.PanelFriendRecommendPop)
    end)

    -- 添加
    UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function ()
        FellowshipData.AddFellowship(self.tbPlayerCard.szName)

        if self.dwPushType ~= FELLOW_SHIP_PUSH_TYPE.AROUND then
            RemoteCallToServer("On_Achievement_AddRequest", 4456, 1)
            if self.dwPushType == FELLOW_SHIP_PUSH_TYPE.PUSH then
                LogAddFriendByRecommend(self.tbPlayerInfo.id, self.dwPushSubType, 0, 0)
            elseif self.dwPushType ~= FELLOW_SHIP_PUSH_TYPE.IP then
                LogAddFriendByRecommend(self.tbPlayerInfo.id, self.dwPushSubType, self.dwType, self.dwPushSubType)
            end
        end
    end)

    -- 密聊
    UIHelper.BindUIEvent(self.BtnDialogue, EventType.OnClick, function ()
        local szName = UIHelper.GBKToUTF8(self.tbPlayerCard.szName)
        local dwTalkerID = self.tbPlayerInfo.id
        local bIsFriend = self.nRelationType == FellowshipData.tbRelationType.nFriend
        local dwForceID = self.tbPlayerCard.dwForceID
        local dwMiniAvatarID = self.tbPlayerCard.dwMiniAvatarID
        local nRoleType = self.tbPlayerCard.nRoleType
        local nLevel = self.tbPlayerCard.nLevel
        local tbData = {szName = szName, dwTalkerID = dwTalkerID, dwForceID = dwForceID, dwMiniAvatarID = dwMiniAvatarID, nRoleType = nRoleType, nLevel = nLevel}

        ChatHelper.WhisperTo(szName, tbData)
    end)
end

function UIPlayerMessageAdd:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPlayerMessageAdd:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPlayerMessageAdd:UpdateInfo()
    if self.tbPlayerInfo then
        UIHelper.RemoveAllChildren(self.WidgetHead)
        self.headScript = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead, self.tbPlayerInfo.id)
        if self.headScript and self.tbPlayerCard then
            if self.tbPlayerCard.dwMiniAvatarID and self.tbPlayerCard.nRoleType and self.tbPlayerCard.dwForceID then
                self.headScript:SetHeadInfo(self.tbPlayerInfo.id, self.tbPlayerCard.dwMiniAvatarID, self.tbPlayerCard.nRoleType, self.tbPlayerCard.dwForceID)
            elseif self.tbPlayerCard.dwForceID then
                self.headScript:SetHeadInfo(self.tbPlayerInfo.id, 0, nil, self.tbPlayerCard.dwForceID)
            end
        end
    end
    local szUtf8Name = UIHelper.GBKToUTF8(self.tbPlayerCard.szName)
    UIHelper.SetString(self.LabelName, szUtf8Name, 8)
    if self.tbPlayerCard.szSignature ~= "" then
        UIHelper.SetString(self.LabelSignature, self.tbPlayerCard.szSignature)
    end

    UIHelper.SetString(self.LabelLevel, string.format(g_tStrings.STR_LEVEL_FARMAT, self.tbPlayerCard.nLevel))
    UIHelper.SetSpriteFrame(self.ImgForceID, PlayerForceID2SchoolImg2[self.tbPlayerCard.dwForceID])
end

function UIPlayerMessageAdd:UpdateSignature(Signature)
    UIHelper.SetString(self.LabelSignature, Signature)
end

function UIPlayerMessageAdd:SetPlayerPushSubType(dwSubType, dwType)
    self.dwPushSubType = dwSubType
    self.dwType = dwType
end

return UIPlayerMessageAdd