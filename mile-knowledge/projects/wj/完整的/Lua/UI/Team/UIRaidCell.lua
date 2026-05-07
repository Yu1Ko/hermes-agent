-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRaidCell
-- Date: 2022-11-23 14:49:42
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIRaidCell = class("UIRaidCell")

function UIRaidCell:OnEnter(bPuppet, nGroup, nIndex, bScene, fnPeek, BtnTipsPop)
    self.BtnTipsPop = BtnTipsPop
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bPuppet = bPuppet
    self.nGroup = nGroup
    self.nIndex = nIndex
    self.dwID = 0

    self.bMoving = false

    self.bScene = bScene
    self.fnPeek = fnPeek
    self.nMiniSceneIndex = self.nIndex + 1

    self:UpdateInfo()
end

function UIRaidCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIRaidCell:BindUIEvent()
    if self.bPuppet then
        return
    end

    if self.BtnTipsPop then
        UIHelper.BindUIEvent(self.BtnTipsPop, EventType.OnClick, function ()
            if self.dwID ~= 0 then
                UIHelper.SetSelected(self.TogSelect, true)
            end
        end)
    end

    UIHelper.BindUIEvent(self.TogSelect, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            Event.Dispatch(EventType.OnTeamSelected, self.nIndex)

            local tbMemberInfo = TeamData.GetMemberInfo(self.dwID)
            local tbMenuConfig = self:GenerateMenuConfig()
            local tbPlayerCard = {
                -- dwID = self.dwID,
                nRoleType = tbMemberInfo.nRoleType,
                nForceID = tbMemberInfo.dwForceID,
                nLevel = tbMemberInfo.nLevel,
                szName = tbMemberInfo.szName,
                nCamp = tbMemberInfo.nCamp,
                dwMiniAvatarID = tbMemberInfo.dwMiniAvatarID,
            }

            local tips, script = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPlayerPop, self._rootNode, nil, tbMenuConfig, tbPlayerCard)
            script:UpdateTeamData(tbMemberInfo)
            -- UIHelper.SetSelected(self.TogSelect, true, false)
            local nTipsWidth, nTipsHeight = UIHelper.GetContentSize(script.LayoutPlayer)
            local _, nCellHeight = UIHelper.GetContentSize(self._rootNode)
            tips:SetSize(nTipsWidth, nTipsHeight)
            local nDir
            local nOffsetY
            if self.bScene then
                if self.nIndex <= 2 then
                    nDir = TipsLayoutDir.TOP_RIGHT
                    nOffsetY = -nCellHeight
                else
                    nDir = TipsLayoutDir.TOP_LEFT
                    nOffsetY = -nCellHeight
                end
            else
                if self.nGroup <= 2 then
                    nDir = TipsLayoutDir.TOP_RIGHT
                else
                    nDir = TipsLayoutDir.TOP_LEFT
                end
                if self.nIndex <= 2 then
                    nOffsetY = -nTipsHeight
                else
                    nOffsetY = -nCellHeight
                end
            end
            tips:SetDisplayLayoutDir(nDir)
            tips:SetOffset(2, nOffsetY)
            tips:UpdatePosByNode(self._rootNode)
        end
    end)

    UIHelper.BindUIEvent(self.TogSelect, EventType.OnTouchBegan, function (btn, x, y)
        self.nStartX = x
        self.nStartY = y
    end)

    UIHelper.BindUIEvent(self.TogSelect, EventType.OnTouchMoved, function (btn, x, y)
        if self.bMoving then
            Event.Dispatch(EventType.OnRaidCellTouchMoved, self.dwID, x, y)
        else
            if TipsHelper.IsHoverTipsExist(PREFAB_ID.WidgetPlayerPop) then
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetPlayerPop)
            end
            local nWidth, _ = UIHelper.GetContentSize(self._rootNode)
            local dist = math.sqrt(math.abs(x-self.nStartX)^2 + math.abs(y-self.nStartY)^2)
            if dist > nWidth / 8 then
                self.bMoving = true
            end
        end
    end)

    UIHelper.BindUIEvent(self.TogSelect, EventType.OnTouchEnded, function (btn, x, y)
        if self.bMoving then
            self.bMoving = false
            Event.Dispatch(EventType.OnRaidCellTouchEnded, self.dwID)
        end
    end)

    UIHelper.BindUIEvent(self.TogSelect, EventType.OnTouchCanceled, function (btn)
        if self.bMoving then
            self.bMoving = false
            Event.Dispatch(EventType.OnRaidCellTouchEnded, self.dwID)
        end
    end)

    UIHelper.BindUIEvent(self.WidgetAddMember, EventType.OnClick, function ()
        -- UIMgr.Close(VIEW_ID.PanelTeam)
        UIMgr.Open(VIEW_ID.PanelChatSocial, 2)
    end)
end

function UIRaidCell:RegEvent()
    Event.Reg(self, EventType.OnRaidCellToggleSelectedByPos, function (nGroup, nIndex)
        if self.bPuppet then
            return
        end
        UIHelper.SetSelected(self.TogSelect, self.nGroup == nGroup and self.nIndex == nIndex, false)
    end)

    Event.Reg(self, EventType.OnTeamVoiceForbided, function (dwID)
        if dwID ~= self.dwID then return end
        UIHelper.SetVisible(self.ImgMute, GVoiceMgr.IsMemberForbid(self.dwID))
    end)

    Event.Reg(self, "PARTY_SET_MARK", function()
        self:UpdateTeamMark()
    end)

    Event.Reg(self, EventType.UpdateStartReadyConfirm, function()
        self:UpdateReadyInfo()
    end)

    Event.Reg(self, EventType.UpdateMemberReadyConfirm, function(dwID)
        if dwID == self.dwID then
            self:UpdateReadyInfo()
        end
    end)
end

function UIRaidCell:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIRaidCell:UpdateInfo(bNotPeek)
    if self.dwID == 0 then
        UIHelper.SetVisible(self.WidgetMemberIn, false)
        UIHelper.SetVisible(self.WidgetAddMember, false)
        if TeamData.IsTeamLeader() then
            local tGroupInfo = TeamData.GetGroupInfo(self.nGroup)
            if tGroupInfo and tGroupInfo.MemberList then
                if self.nIndex == #tGroupInfo.MemberList then
                    UIHelper.SetVisible(self.WidgetAddMember, true)
                end
            end
        end
        return
    end

    UIHelper.SetVisible(self.WidgetMemberIn, true)
    UIHelper.SetVisible(self.WidgetAddMember, false)
    local hTeam = GetClientTeam()
    local tbMemberInfo = TeamData.GetMemberInfo(self.dwID, hTeam)

    if not self.widgetHead then
        self.widgetHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetMemberHead)
    end
    self.widgetHead:SetHeadInfo(self.dwID, tbMemberInfo.dwMiniAvatarID, tbMemberInfo.nRoleType, tbMemberInfo.dwForceID)
    --self.widgetHead:SetTouchEnabled(false)
    UIHelper.SetTouchEnabled(self.widgetHead.BtnHead, false)

    UIHelper.SetVisible(self.ImgMemberBg, self.bPuppet)

    local szUtf8Name = UIHelper.GetUtf8SubString(UIHelper.GBKToUTF8(tbMemberInfo.szName), 1, 6)
    UIHelper.SetString(self.LableName, szUtf8Name)
    UIHelper.SetString(self.LableLevel, tbMemberInfo.nLevel)

    for _, imgMark in ipairs(self.tbImgMark) do
        UIHelper.SetVisible(imgMark, false)
    end

    local nIndex = 1
    if hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) == self.dwID then
        UIHelper.SetSpriteFrame(self.tbImgMark[nIndex], "UIAtlas2_Public_PublicIcon_PublicIcon1_img_captain.png")
        UIHelper.SetVisible(self.tbImgMark[nIndex], true)
        nIndex = nIndex + 1
    end

    if hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.DISTRIBUTE) == self.dwID then
        UIHelper.SetSpriteFrame(self.tbImgMark[nIndex], "UIAtlas2_Public_PublicIcon_PublicIcon1_img_allot.png")
        UIHelper.SetVisible(self.tbImgMark[nIndex], true)
        nIndex = nIndex + 1
    end

    if hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK) == self.dwID then
        UIHelper.SetSpriteFrame(self.tbImgMark[nIndex], "UIAtlas2_Public_PublicIcon_PublicIcon1_img_sign.png")
        UIHelper.SetVisible(self.tbImgMark[nIndex], true)
        nIndex = nIndex + 1
    end

    local nGroup = hTeam.GetMemberGroupIndex(self.dwID)
    if hTeam.GetGroupFormationLeader(nGroup) == self.dwID then
        UIHelper.SetSpriteFrame(self.tbImgMark[nIndex], "UIAtlas2_Public_PublicIcon_PublicIcon1_img_kernel.png")
        UIHelper.SetVisible(self.tbImgMark[nIndex], true)
        nIndex = nIndex + 1
    end

    UIHelper.SetVisible(self.LayoutIconMark, nIndex > 1)
    UIHelper.LayoutDoLayout(self.LayoutIconMark)

    UIHelper.SetVisible(self.ImgBgDisconnected, not tbMemberInfo.bIsOnLine)

    CampData.SetUICampImg(self.ImgIcon2, tbMemberInfo.nCamp)
    if (tbMemberInfo.dwForceID == 0) then
        UIHelper.SetSpriteFrame(self.ImgIcon, PlayerForceID2SchoolImg2[tbMemberInfo.dwForceID])
    else
        PlayerData.SetMountKungfuIcon(self.ImgIcon, tbMemberInfo.dwMountKungfuID, tbMemberInfo.nClientVersionType)
    end

    PlayerData.SetPlayerLogionSite(self.ImgLoginSite ,TeamData.GetMemberClientVersionType(self.dwID) , self.dwID)
    UIHelper.LayoutDoLayout(self.LayoutIcon)

    self:UpdateReadyInfo()
    self:UpdateDistanceInfo()
    self:UpdateTeamMark()
    self:UpdatePositionInfo()
    self:UpdateLMRInfo()

    if self.bScene and not bNotPeek then
        self.fnPeek(self.dwID, self.nMiniSceneIndex, tbMemberInfo.bIsOnLine)
    end

    UIHelper.SetVisible(self.ImgMute, GVoiceMgr.IsMemberForbid(self.dwID))
end

function UIRaidCell:UpdateReadyInfo()
    if self.dwID == 0 then
        return
    end
    UIHelper.SetVisible(self.ImgBgPrepare, TeamData.GetMemberReadyConfirm(self.dwID) == RAID_READY_CONFIRM_STATE.NotYet)
end

function UIRaidCell:UpdateDistanceInfo()
    if self.dwID == 0 then
        return
    end

    UIHelper.SetVisible(self.ImgMarkTop1, false)

    local hPlayer = GetClientPlayer()
    local hTeam = GetClientTeam()
    local tbMemberInfo = TeamData.GetMemberInfo(self.dwID, hTeam)
    if hPlayer.dwID == self.dwID then
        UIHelper.SetSpriteFrame(self.ImgMarkTop1, "UIAtlas2_Public_PublicIcon_PublicIcon1_TeamIcon4")
        UIHelper.SetVisible(self.ImgMarkTop1, true)
    else
        if tbMemberInfo.bDeathFlag then
            UIHelper.SetSpriteFrame(self.ImgMarkTop1, "UIAtlas2_Public_PublicIcon_PublicIcon1_TeamIcon3")
            UIHelper.SetVisible(self.ImgMarkTop1, true)
        else
            UIHelper.SetVisible(self.ImgMarkTop1, false)
        end
        -- if not tbMemberInfo.bIsOnLine then
        --     UIHelper.SetSpriteFrame(self.ImgMarkTop1, "UIAtlas2_Public_PublicIcon_PublicIcon1_TeamIcon2")
        --     UIHelper.SetVisible(self.ImgMarkTop1, true)
        -- else
        --     local dwPeekPlayerID = GetPeekPlayerID()
        --     local dwDistance = GetCharacterDistance(hPlayer.dwID, self.dwID)
        --     if dwDistance == -1 or dwPeekPlayerID == self.dwID then
        --         UIHelper.SetSpriteFrame(self.ImgMarkTop1, "UIAtlas2_Public_PublicIcon_PublicIcon1_TeamIcon1")
        --         UIHelper.SetVisible(self.ImgMarkTop1, true)
        --     elseif tbMemberInfo.bDeathFlag then
        --         UIHelper.SetSpriteFrame(self.ImgMarkTop1, "UIAtlas2_Public_PublicIcon_PublicIcon1_TeamIcon3")
        --         UIHelper.SetVisible(self.ImgMarkTop1, true)
        --     else
        --         UIHelper.SetVisible(self.ImgMarkTop1, false)
        --     end
        -- end
    end
end

function UIRaidCell:UpdateTeamMark()
    if self.dwID == 0 then
        return
    end
    local tTeamMark = GetClientTeam().GetTeamMark()
    local nMyMark = tTeamMark[self.dwID] or 0
    local szIconPath = TeamData.TargetMarkIcon[nMyMark]
    if szIconPath then
        UIHelper.SetSpriteFrame(self.ImgMarkIcon, szIconPath)
        UIHelper.SetVisible(self.ImgMarkIcon, true)
    else
        UIHelper.SetVisible(self.ImgMarkIcon, false)
    end
end

function UIRaidCell:UpdatePositionInfo()
    if self.dwID == 0 then
        return
    end
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tbMemberInfo = TeamData.GetMemberInfo(self.dwID)
    if not tbMemberInfo.bIsOnLine then
        UIHelper.SetVisible(self.LayoutLocation, false)
    else
        UIHelper.SetVisible(self.LayoutLocation, true)
        UIHelper.SetVisible(self.ImgMarkProgress, hPlayer.IsPartyMemberInSameScene(self.dwID))
        local szMapName = UIHelper.GBKToUTF8(Table_GetMapName(tbMemberInfo.dwMapID))
        UIHelper.SetString(self.LableLocation, UIHelper.GetUtf8SubString(szMapName, 1, 9))
        UIHelper.LayoutDoLayout(self.LayoutLocation)
    end
end

function UIRaidCell:UpdateLMRInfo()
    if self.dwID == 0 then
        return
    end
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tbMemberInfo = TeamData.GetMemberInfo(self.dwID)
    UIHelper.SetString(self.LabelEquipScoreNum, tbMemberInfo.nEquipScore)
    UIHelper.LayoutDoLayout(self.WidgetEquipScore)
end

function UIRaidCell:Clear()
    if self.bMoving then
        self.bMoving = false
        Event.Dispatch(EventType.OnRaidCellTouchCanceled, self.dwID)
    end

    if self.bScene then
        self.fnPeek(self.dwID, self.nMiniSceneIndex, false)
    end

    self.dwID = 0
    self:UpdateInfo()
end

function UIRaidCell:SetID(dwID)
    if self.dwID == dwID then
        self:UpdateInfo(true)
    else
        self:Clear()
        self.dwID = dwID
        self:UpdateInfo()
    end
end

function UIRaidCell:GenerateMenuConfig()
    local hPlayer = GetClientPlayer()
    local tbMenus = {}
    local tbMemberInfo = TeamData.GetMemberInfo(self.dwID)
    if self.dwID ~= hPlayer.dwID then
        TeamData.InsertTeammateMenus(tbMenus, self.dwID, true, true)
    else
        TeamData.InsertTeamPlayerMenus(tbMenus)
    end
    return tbMenus
end

return UIRaidCell