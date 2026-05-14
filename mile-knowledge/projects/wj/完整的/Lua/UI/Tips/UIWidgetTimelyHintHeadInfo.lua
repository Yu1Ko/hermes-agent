-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetTimelyHintHeadInfo
-- Date: 2023-12-21 16:46:05
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetTimelyHintHeadInfo = class("UIWidgetTimelyHintHeadInfo")

function UIWidgetTimelyHintHeadInfo:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetTimelyHintHeadInfo:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetTimelyHintHeadInfo:BindUIEvent()

end

function UIWidgetTimelyHintHeadInfo:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetTimelyHintHeadInfo:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTimelyHintHeadInfo:UpdateInfo()

end

function UIWidgetTimelyHintHeadInfo:SetHeadInfo(dwID, dwMiniAvatarID, nRoleType, dwForceID)
    self.scriptHead = self.scriptHead or UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead)
    self.scriptHead:SetHeadInfo(dwID, dwMiniAvatarID, nRoleType, dwForceID)
    UIHelper.SetVisible(self.ImgSchool, false)
    UIHelper.SetVisible(self.ImgLoginSite, false)
    UIHelper.SetVisible(self.LabelLevel, false)
end

function UIWidgetTimelyHintHeadInfo:SetPlayerID(dwID)
    if not self.scriptHead then
        self.scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead, dwID)
    else
        self.scriptHead:OnEnter(dwID)
    end
    UIHelper.SetVisible(self.ImgSchool, false)
    UIHelper.SetVisible(self.ImgLoginSite, false)
    UIHelper.SetVisible(self.LabelLevel, false)
end

function UIWidgetTimelyHintHeadInfo:SetTeamInfo(tInfo)
    local szInviteSrc, dwSrcCamp, dwSrcForceID, dwSrcLevel, nType, nParam, dwSrcMiniAvatarID, dwSrcMountKungfuID, nSrcEquipScore, nRoleType, nClientVersionType = table.unpack(tInfo)
    self:SetHeadInfo(nil, dwSrcMiniAvatarID, nRoleType, dwSrcForceID)
    if tInfo[12] then
        self:SetTeamHeadOnclick(tInfo)
    end
    UIHelper.SetVisible(self.ImgSchool, true)
    -- UIHelper.SetSpriteFrame(self.ImgSchool, PlayerKungfuImg[dwSrcMountKungfuID])
    PlayerData.SetMountKungfuIcon(self.ImgSchool, dwSrcMountKungfuID, nClientVersionType)
    UIHelper.SetVisible(self.LabelLevel, true)
    UIHelper.SetString(self.LabelLevel, dwSrcLevel)
    PlayerData.SetPlayerLogionSite(self.ImgLoginSite, nClientVersionType)
end

function UIWidgetTimelyHintHeadInfo:SetTeamHeadOnclick(tInfo)
    local szInviteSrc, dwSrcCamp, dwSrcForceID, dwSrcLevel, nType, nParam, dwSrcMiniAvatarID, dwSrcMountKungfuID, nSrcEquipScore, nRoleType, nClientVersionType, dwInviteSrc = table.unpack(tInfo)
    local function funcOnClikcFun()
        local tbMenuConfig = {
            { szName = "密聊", bCloseOnClick = true,
                callback = function()
                    local szName = UIHelper.GBKToUTF8(szInviteSrc)
                    local tbData = {szName = szName, dwTalkerID = dwInviteSrc, dwForceID = dwSrcForceID, dwMiniAvatarID = dwSrcMiniAvatarID, nRoleType = nRoleType, nLevel = dwSrcLevel}
                    ChatHelper.WhisperTo(szName, tbData)
                end
            },
            {
                szName = "查看装备",
                bCloseOnClick = true,
                callback = function()
                    if not UIMgr.GetView(VIEW_ID.PanelOtherPlayer) then
                        UIMgr.Open(VIEW_ID.PanelOtherPlayer, dwInviteSrc)
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

        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPlayerPop, self.scriptHead._rootNode, TipsLayoutDir.BOTTOM_LEFT, dwInviteSrc, tbMenuConfig, tbPlayerCard)
    end

    if self.scriptHead then
        self.scriptHead:SetClickCallback(funcOnClikcFun)
    end
end

function UIWidgetTimelyHintHeadInfo:SetAssistHeadInfo(dwPlayerID, dwMiniAvatarID, nRoleType, dwForceID)
    self.scriptHead = self.scriptHead or UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead)
    self.scriptHead:SetHeadInfo(dwPlayerID, dwMiniAvatarID, nRoleType, dwForceID)
    UIHelper.SetSpriteFrame(self.ImgSchool, PlayerForceID2SchoolImg2[dwForceID])
    UIHelper.SetVisible(self.ImgSchool, true)
    UIHelper.SetVisible(self.ImgLoginSite, false)
    UIHelper.SetVisible(self.LabelLevel, false)
end

return UIWidgetTimelyHintHeadInfo