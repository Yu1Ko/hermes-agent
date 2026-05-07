-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIInvitationMessagePopCell
-- Date: 2023-03-24 09:24:28
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIInvitationMessagePopCell = class("UIInvitationMessagePopCell")

function UIInvitationMessagePopCell:OnEnter(tbInfo, nType)
    self.tbInfo = tbInfo
    self.nType = nType

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIInvitationMessagePopCell:OnExit()
    self.bInit = false
end

function UIInvitationMessagePopCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function()
        if self.tbInfo.funcConfirm then
            self.tbInfo.funcConfirm()
            TimelyMessagesBtnData.RemoveBtnInfo(self.tbInfo.nType, self.tbInfo, false)
        end
    end)

    UIHelper.BindUIEvent(self.BtnRefuse, EventType.OnClick, function()
        TimelyMessagesBtnData.RemoveBtnInfo(self.tbInfo.nType, self.tbInfo, false)
        if self.tbInfo.funcCancel then
            self.tbInfo.funcCancel()
        end
    end)
end

function UIInvitationMessagePopCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIInvitationMessagePopCell:UpdateInfo()
    if self.nType == TimelyMessagesType.Team or
    self.nType == TimelyMessagesType.Friend then
        self:UpdateTeam()
        self:SetTeamHeadOnclick()
    elseif self.nType == TimelyMessagesType.Room then
        self:UpdateRoom()
    end
end

function UIInvitationMessagePopCell:UpdateTeam()
    local szInviteSrc, dwSrcCamp, dwSrcForceID, dwSrcLevel, nType, nParam, dwSrcMiniAvatarID, dwSrcMountKungfuID, nSrcEquipScore, nRoleType ,nClientVersionType
    if self.tbInfo and self.tbInfo.tbParams then
        szInviteSrc, dwSrcCamp, dwSrcForceID, dwSrcLevel, nType, nParam, dwSrcMiniAvatarID, dwSrcMountKungfuID, nSrcEquipScore, nRoleType ,nClientVersionType = table.unpack(self.tbInfo.tbParams)

    elseif self.tbInfo and self.tbInfo.tbPlayerCard then
        szInviteSrc = self.tbInfo.tbPlayerCard.szName
        dwSrcLevel = self.tbInfo.tbPlayerCard.nLevel
        dwSrcForceID = self.tbInfo.tbPlayerCard.dwForceID or self.tbInfo.tbPlayerCard.nForceID
        dwSrcMiniAvatarID = self.tbInfo.tbPlayerCard.dwMiniAvatarID
        nRoleType = self.tbInfo.tbPlayerCard.nRoleType

        UIHelper.SetVisible(self.WidgetOtherInfo, false)
    end

    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(szInviteSrc))
    UIHelper.SetString(self.LabelLevel, tostring(dwSrcLevel))
    UIHelper.SetVisible(self.BtnCoFightBuff, false)
    CampData.SetUICampImg(self.ImgGroup, dwSrcCamp)

    if nSrcEquipScore then
        UIHelper.SetString(self.LabelEquipScore, string.format("装备分数  %d", nSrcEquipScore))
    end

    if dwSrcMountKungfuID then
        local szKungfuName = UIHelper.GBKToUTF8(Table_GetSkillName(dwSrcMountKungfuID, 1))
        UIHelper.SetString(self.LabelXinFa, szKungfuName)
        -- UIHelper.SetSpriteFrame(self.ImgXinFa, PlayerKungfuImg[dwSrcMountKungfuID])
        PlayerData.SetMountKungfuIcon(self.ImgXinFa, dwSrcMountKungfuID, nClientVersionType)
    end

    UIHelper.SetSpriteFrame(self.ImgSchool, PlayerForceID2SchoolImg2[dwSrcForceID])

    self.scriptHead = self.scriptHead or UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead, -1)
    self.scriptHead:SetHeadInfo(nil, dwSrcMiniAvatarID, nRoleType, dwSrcForceID)

    UIHelper.LayoutDoLayout(self.LayoutTitle)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutInfo, true, false)
    PlayerData.SetPlayerLogionSite(self.ImgLoginSite , nClientVersionType)
end

function UIInvitationMessagePopCell:UpdateRoom()
    local nJoinType, szSrcName, szGlobalID, szRoomID, dwCenterID = table.unpack(self.tbInfo.tbParams)
    local szName = RoomData.GetGlobalName(szSrcName, dwCenterID, true)
    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(szName))
    UIHelper.SetVisible(self.WidgetHead, false)
    UIHelper.SetVisible(self.ImgIconType, true)

    UIHelper.SetVisible(self.ImgSchool, false)
    UIHelper.SetVisible(self.LabelLevel, false)
    UIHelper.SetVisible(self.BtnCoFightBuff, false)
    UIHelper.SetVisible(self.ImgGroup, false)
    UIHelper.SetVisible(self.WidgetOtherInfo, false)

    UIHelper.LayoutDoLayout(self.LayoutTitle)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutInfo, true, false)
    UIHelper.SetVisible(self.ImgLoginSite , false)
end

function UIInvitationMessagePopCell:SetTeamHeadOnclick()
    if self.nType == TimelyMessagesType.Team then
        local szInviteSrc, dwSrcCamp, dwSrcForceID, dwSrcLevel, nType, nParam, dwSrcMiniAvatarID, dwSrcMountKungfuID, nSrcEquipScore, nRoleType, nClientVersionType, dwInviteSrc = table.unpack(self.tbInfo.tbParams)
        local function funcOnClikcFun()
            local tbMenuConfig = {
                { szName = "密聊", bCloseOnClick = true,
                    callback = function()
                        local szName = UIHelper.GBKToUTF8(szInviteSrc)
                        local tbData = {szName = szName, dwTalkerID = dwInviteSrc, dwForceID = dwSrcForceID, dwMiniAvatarID = dwSrcMiniAvatarID, nRoleType = nRoleType, nLevel = dwSrcLevel}
                        ChatHelper.WhisperTo(szName, tbData)
                        UIMgr.Close(VIEW_ID.PanelInvitationMessagePop)
                    end
                },
                {
                    szName = "查看装备",
                    bCloseOnClick = true,
                    callback = function()
                        if not UIMgr.GetView(VIEW_ID.PanelOtherPlayer) then
                            UIMgr.Open(VIEW_ID.PanelOtherPlayer, dwInviteSrc)
                            UIMgr.Close(VIEW_ID.PanelInvitationMessagePop)
                        end
                    end
                },
            }
            local tbPlayerCard = {
                -- dwID = tInfo.dwID,
                nRoleType = nRoleType,
                nForceID = dwSrcForceID,
                nLevel = dwSrcLevel,
                szName = szInviteSrc,
                nCamp = dwSrcCamp,
                dwMiniAvatarID = dwSrcMiniAvatarID or 0,
                nEquipScore = nSrcEquipScore,
            }

            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPlayerPop, self.scriptHead._rootNode, TipsLayoutDir.BOTTOM_RIGHT, dwInviteSrc, tbMenuConfig, tbPlayerCard)
        end

        if self.scriptHead then
            self.scriptHead:SetClickCallback(funcOnClikcFun)
        end
    end
end

return UIInvitationMessagePopCell