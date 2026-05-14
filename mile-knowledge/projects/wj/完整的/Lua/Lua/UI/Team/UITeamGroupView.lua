-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamGroupView
-- Date: 2022-12-06 15:37:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local MAX_GROUP_MEMBER_COUNT = 5

local LOOT_MODE_STR = {
    [1] = "自由拾取",
    [2] = "分配者分配",
    [3] = "队伍拾取",
    [4] = "拍团分配",
}

local ROLL_QUALITY_STR = {
    [1] = "白色",
    [2] = "绿色",
    [3] = "蓝色",
    [4] = "紫色",
    [5] = "橙色",
}

local UITeamGroupView = class("UITeamGroupView")

function UITeamGroupView:OnEnter(scene, tPos)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tPos = tPos

    self.tbGroupCells = {}

    local widgetTeamSort = self.WidgetAnchorRight
    for nIndex = 0, MAX_GROUP_MEMBER_COUNT-1 do
        local imgMemberMessageName = "ImgMemberMassage"
        local btnMemberMessageName = "BtnMemberMessage"
        if nIndex ~= 0 then
            imgMemberMessageName = imgMemberMessageName .. nIndex
            btnMemberMessageName = btnMemberMessageName .. nIndex
        end
        local imgMemberMessage = widgetTeamSort:getChildByName(imgMemberMessageName)
        local btnMemberMessage = widgetTeamSort:getChildByName(btnMemberMessageName)
        imgMemberMessage:removeAllChildren()
        local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetMemberMassage, imgMemberMessage)
        cell:OnEnter(false, 0, nIndex, true, function (dwID, nMiniSceneIndex, bStart)
            self:StartStopPeek(dwID, nMiniSceneIndex, bStart)
        end, btnMemberMessage)
        self.tbGroupCells[nIndex] = cell
    end

    self.tbModelViews = {}
    for i = 1, MAX_GROUP_MEMBER_COUNT do
        local hModelView = PlayerModelView.CreateInstance(PlayerModelView)
        hModelView:ctor()
        hModelView:InitBy({
            szName = string.format("TeamGroup_%d", i),
            scene = scene,
            bExScene = false,
            bAPEX = false,
        })
        hModelView:SetLodLevel(2)
        self.tbModelViews[i] = hModelView
    end

    self.tbWaitPeek = {}
    self.dwPeekingID = nil

    self.bStateMark = false
    self.tbDownloadDynamicIDs = {}

    local scriptChat = UIHelper.GetBindScript(self.BtnChat)
    if scriptChat then
        scriptChat:OnEnter(UI_Chat_Channel.Team)
    end
    self:UpdateInfo()

    Timer.AddCycle(self, 5.0, function ()
		self:UpdateDistanceInfo()
	end)
end

function UITeamGroupView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)

    for _, hModelView in pairs(self.tbModelViews) do
        hModelView:release()
    end
    self.tbModelViews = {}

    UIMgr.Close(VIEW_ID.PanelTeamSetUp)

    for index, nDownloadDynamicID in pairs(self.tbDownloadDynamicIDs) do
        PakDownloadMgr.ReleaseDynamicPakInfo(nDownloadDynamicID)
        self.tbDownloadDynamicIDs[index] = nDownloadDynamicID
    end
end

function UITeamGroupView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSetUp, EventType.OnClick, function (btn)
        UIMgr.Open(VIEW_ID.PanelTeamSetUp)
    end)

    UIHelper.BindUIEvent(self.BtnReturn, EventType.OnClick, function (btn)
        TeamData.RequestLeaveTeam()
    end)

    UIHelper.BindUIEvent(self.tbBtnUnder[1], EventType.OnClick, function (btn)
        local tbBtnCfg = self:GetUnderButtonConfig()
        if not tbBtnCfg[1] then
            return
        end
        tbBtnCfg[1].fnAction()
    end)

    UIHelper.BindUIEvent(self.tbBtnUnder[2], EventType.OnClick, function (btn)
        local tbBtnCfg = self:GetUnderButtonConfig()
        if not tbBtnCfg[2] then
            return
        end
        tbBtnCfg[2].fnAction()
    end)

    UIHelper.BindUIEvent(self.tbBtnUnder[3], EventType.OnClick, function (btn)
        local tbBtnCfg = self:GetUnderButtonConfig()
        if not tbBtnCfg[3] then
            return
        end
        tbBtnCfg[3].fnAction()
    end)

    UIHelper.BindUIEvent(self.TogVoice, EventType.OnSelectChanged, function(btn, bSelected)
        if bSelected then
            UIHelper.SetSelected(self.TogMicSpeaker, GVoiceMgr.IsOpenSpeakerAndMic())
            UIHelper.SetSelected(self.TogSpeaker, GVoiceMgr.IsOpenSpeakerCloseMic())
            UIHelper.SetSelected(self.TogClose, GVoiceMgr.IsCloseSpeakerAndMic())
        end
    end)

    UIHelper.BindUIEvent(self.TogMicSpeaker, EventType.OnSelectChanged, function(btn, bSelected)
        if bSelected then
            GVoiceMgr.OpenSpeakerAndMic()
            self:UpdateMic()
        end
    end)

    UIHelper.BindUIEvent(self.TogSpeaker, EventType.OnSelectChanged, function(btn, bSelected)
        if bSelected then
            GVoiceMgr.OpenSpeakerCloseMic()
            self:UpdateMic()
        end
    end)

    UIHelper.BindUIEvent(self.TogClose, EventType.OnSelectChanged, function(btn, bSelected)
        if bSelected then
            GVoiceMgr.CloseSpeakerAndMic()
            self:UpdateMic()
        end
    end)

    UIHelper.BindUIEvent(self.BtnDistributionRecord, EventType.OnClick, function (btn)
        if GetClientTeam().nLootMode ~= PARTY_LOOT_MODE.BIDDING then
            TipsHelper.ShowImportantYellowTip(g_tStrings.GOLD_TEAM_CAN_ONLY_OPEN_IN_BIDDING_MODE)
            return
        end
        UIMgr.Open(VIEW_ID.PanelAuctionRecord)
    end)

    UIHelper.BindUIEvent(self.BtnInvite, EventType.OnClick, function()
        -- UIMgr.Close(VIEW_ID.PanelTeam)
        UIMgr.Open(VIEW_ID.PanelChatSocial, 2)
    end)
end

function UITeamGroupView:RegEvent()
    Event.Reg(self, "PARTY_UPDATE_BASE_INFO", function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, "PARTY_UPDATE_MEMBER_INFO", function (_, dwMemberID)
        self:enumGroupCells(function (cell)
            if cell.dwID == dwMemberID then
                cell:UpdateInfo(true)
                return false
            end
            return true
        end)
    end)

    Event.Reg(self, "PARTY_ADD_MEMBER", function (_, dwMemberID, nGroupIndex)
        self:UpdateGroupInfo()
    end)

    Event.Reg(self, "PARTY_SYNC_MEMBER_DATA", function (_, _, nGroupIndex)
        self:UpdateGroupInfo()
    end)

    Event.Reg(self, "PARTY_DELETE_MEMBER", function (_, dwMemberID, _, nGroupIndex)
        local hPlayer = GetClientPlayer()
		if hPlayer.dwID == dwMemberID then
            UIMgr.Close(VIEW_ID.PanelTeamSetUp)
            self:UpdateInfo()
			return
		end
        self:UpdateGroupInfo()
    end)

    Event.Reg(self, "PARTY_DISBAND", function ()
        UIMgr.Close(VIEW_ID.PanelTeamSetUp)
        self:UpdateInfo()
    end)

    Event.Reg(self, "TEAM_AUTHORITY_CHANGED", function (nAuthorityType, dwTeamID, dwOldAuthorityID, dwNewAuthorityID)
        self:UpdateMic()
        self:UpdateAuthorityInfo()

        self:enumGroupCells(function (cell)
            cell:UpdateInfo(true)
            return true
        end)
    end)

    Event.Reg(self, "PARTY_LOOT_MODE_CHANGED", function ()
        self:UpdateLootInfo()
	end)

    Event.Reg(self, "PARTY_ROLL_QUALITY_CHANGED", function ()
        self:UpdateLootInfo()
    end)

    Event.Reg(self, "PARTY_SET_FORMATION_LEADER", function (dwFormationLeader)
        self:UpdateGroupInfo()
    end)

    Event.Reg(self, "PARTY_SET_MEMBER_ONLINE_FLAG", function ()
        self:enumGroupCells(function(cell)
            if cell.dwID == arg1 then
                cell:UpdateInfo(false)
                return false
            end
            return true
        end)
    end)

    Event.Reg(self, "PARTY_UPDATE_MEMBER_POSITION", function()
        self:enumGroupCells(function(cell)
            if cell.dwID == arg1 then
                cell:UpdatePositionInfo()
                return false
            end
            return true
        end)
    end)

    Event.Reg(self, "PARTY_UPDATE_MEMBER_LMR", function (_, dwMemberID)
        self:enumGroupCells(function(cell)
            if cell.dwID == dwMemberID then
                cell:UpdateLMRInfo()
                return false
            end
            return true
        end)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        self:ClearSelect()
    end)

    Event.Reg(self, "PEEK_OTHER_PLAYER", function ()
        if arg0 ~= PEEK_OTHER_PLAYER_RESPOND.SUCCESS then
            self:FinishPeek(arg1, false)
            return
        end
        PeekOtherPlayerExterior(arg1)
    end)

    Event.Reg(self, "PEEK_PLAYER_EXTERIOR", function ()
        self:FinishPeek(arg0, true)
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        -- if self.hModelView then
        --    self.hModelView:SetCamera({CAMERA_POS[1], CAMERA_POS[2], CAMERA_POS[3], CAMERA_POS[4], CAMERA_POS[5], CAMERA_POS[6], GetCameraW(), CAMERA_POS[8], CAMERA_POS[9], CAMERA_POS[10], true})
        -- end
    end)

    Event.Reg(self, "OnRequestPermissionCallback", function(nPermission, bResult)
        if nPermission == Permission.Microphone then
            self:UpdateTeam()
        end
    end)

    Event.Reg(self, EventType.OnEquipPakResourceDownload, function(nDownloadDynamicID)
        for nMiniSceneIndex, nPackID in pairs(self.tbDownloadDynamicIDs) do
            if nPackID == nDownloadDynamicID then
                self:enumGroupCells(function (cell)
                    if cell.nMiniSceneIndex == nMiniSceneIndex then
                        cell:UpdateInfo()
                        return false
                    end
                    return true
                end)
                break
            end
        end
    end)

    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID == VIEW_ID.PanelTeamSetUp then
            UIHelper.PlayAni(self, self.AniAll, "AniBottomHide")
        end
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelTeamSetUp then
            UIHelper.PlayAni(self, self.AniAll, "AniBottomShow")
        end
    end)

    Event.Reg(self, EventType.UpdateStartReadyConfirm, function()
        self:UpdateAuthorityInfo()
    end)

    Event.Reg(self, "FIGHT_HINT", function(bFight)
        self:UpdateAuthorityInfo()
    end)
end

function UITeamGroupView:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamGroupView:UpdateInfo()
    self.bStateMark = false
    self:ClearGroupInfo()

    local hPlayer = GetClientPlayer()
    local bInParty = hPlayer.IsInParty()
    UIHelper.SetVisible(self.WidgetAnchorEmpty, not bInParty)
    UIHelper.SetVisible(self.WidgetAnchorRight, bInParty)
    UIHelper.SetVisible(self.WidgetAnchorRightTop, bInParty)
    UIHelper.SetVisible(self.WidgetAnchorRightBottom, bInParty)
    UIHelper.SetVisible(self.WidgetAnchorLeftBottom, bInParty)

    if bInParty then
        self:UpdateMic()
        self:UpdateGroupInfo()
        self:UpdateAuthorityInfo()
        self:UpdateLootInfo()
    end
end

function UITeamGroupView:UpdateMic()
    UIHelper.SetSelected(self.TogVoice, false)

    if GVoiceMgr.IsOpenSpeakerAndMic() then
        UIHelper.SetSpriteFrame(self.ImgVoice, "UIAtlas2_Public_PublicButton_PublicButton1_img_voice")
        UIHelper.SetString(self.LableVoice, "开麦")
    elseif GVoiceMgr.IsOpenSpeakerCloseMic() then
        UIHelper.SetSpriteFrame(self.ImgVoice, "UIAtlas2_Public_PublicButton_PublicButton1_img_voice01")
        UIHelper.SetString(self.LableVoice, "收听")
    else
        UIHelper.SetSpriteFrame(self.ImgVoice, "UIAtlas2_Public_PublicButton_PublicButton1_img_voice_close")
        UIHelper.SetString(self.LableVoice, "拒听")
    end
end

function UITeamGroupView:ClearGroupInfo()
    self:enumGroupCells(function (cell)
        cell:Clear()
        return true
    end)
end

function UITeamGroupView:UpdateGroupInfo()
    local hTeam = GetClientTeam()
    local hPlayer = GetClientPlayer()
    local nGroupID = hTeam.GetMemberGroupIndex(hPlayer.dwID)
    local tbGroupInfo = TeamData.GetGroupInfo(nGroupID)

    local nIndex = 0
    for _, dwMemberID in ipairs(tbGroupInfo.MemberList) do
        self.tbGroupCells[nIndex]:SetID(dwMemberID)
        nIndex = nIndex + 1
    end
    for i = nIndex, MAX_GROUP_MEMBER_COUNT-1 do
        self.tbGroupCells[i]:Clear()
    end
end


function UITeamGroupView:UpdateAuthorityInfo()
    UIHelper.SetVisible(self.BtnSetUp, true)
    UIHelper.SetVisible(self.BtnInviteRoom, false)
    UIHelper.LayoutDoLayout(self.WidgetAnchorRightTop)

    local tbBtnCfg = self:GetUnderButtonConfig()
    for i, btn in ipairs(self.tbBtnUnder) do
        if tbBtnCfg[i] then
            UIHelper.SetString(self.tbLableUnder[i], tbBtnCfg[i].szName)
            UIHelper.SetVisible(btn, true)
            UIHelper.SetButtonState(btn, tbBtnCfg[i].bDisable and BTN_STATE.Disable or BTN_STATE.Normal)
        else
            UIHelper.SetVisible(btn, false)
        end
    end

    UIHelper.LayoutDoLayout(self.WidgetAnchorButton)
end

function UITeamGroupView:UpdateLootInfo()
    local hTeam = GetClientTeam()

    UIHelper.SetString(self.LabelColor, ROLL_QUALITY_STR[hTeam.nRollQuality])
    UIHelper.SetString(self.LabelType, LOOT_MODE_STR[hTeam.nLootMode])
end

function UITeamGroupView:GetUnderButtonConfig()
    local hTeam = GetClientTeam()
    local hPlayer = GetClientPlayer()

    local tbAllBtn = {
        {
            szName = "转为团队",
            fnCondition=function()
                return hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) == hPlayer.dwID and not TeamData.IsInRaid(hTeam)
            end,
            fnAction=function()
                local fnConfirm = function()
                    GetClientTeam().LevelUpRaid()
                end
                UIHelper.ShowConfirm(g_tStrings.STR_MSG_RAID_CONFIRM, fnConfirm, nil, false)
            end,
        },

        {
            szName = "就位确认",
            fnCondition=function()
                return hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) == hPlayer.dwID and not TeamData.IsStartReadyConfirm()
            end,
            bDisable = hPlayer.bFightState,
            fnAction=function()
                local fnConfrim = function()
                   TeamData.StartReadyConfirm()
                end
                UIHelper.ShowConfirm(g_tStrings.STR_RAID_MSG_START_READY_CONFIRM, fnConfrim, nil, false)
            end,
        },

        {
            szName = "就位重置",
            fnCondition=function()
                return hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.LEADER) == hPlayer.dwID and TeamData.IsStartReadyConfirm()
            end,
            fnAction=function()
                TeamData.ResetReadyConfirm()
            end,
        },

        -- {
        --     szName = "标记",
        --     fnCondition=function(hTeam, hPlayer)
        --         return hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK) == hPlayer.dwID and not self.bStateMark
        --     end,
        --     fnAction=function()
        --         self.bStateMark = true
        --         self:UpdateAuthorityInfo()
        --     end,
        -- },
    }

    local tbEffectBtn = {}
    for _, btn in ipairs(tbAllBtn)  do
        if btn.fnCondition and btn.fnCondition() then
            table.insert(tbEffectBtn, btn)
            if btn.bInterrupt then
                break
            end
        end
    end

    return tbEffectBtn
end

function UITeamGroupView:UpdateDistanceInfo()
    self:enumGroupCells(function(cell)
        if cell.dwID ~= 0 then
            cell:UpdateDistanceInfo()
        end
        return true
    end)
end

function UITeamGroupView:enumGroupCells(fnAction)
    for nIndex = 0, MAX_GROUP_MEMBER_COUNT-1 do
        if not fnAction(self.tbGroupCells[nIndex]) then
            return false
        end
    end
    return true
end

function UITeamGroupView:StartStopPeek(dwID, nMiniSceneIndex, bStart)
    local hModelView = self.tbModelViews[nMiniSceneIndex]
    if not hModelView then
        return
    end

    if not bStart then
        self.tbWaitPeek[dwID] = nil
        hModelView:UnloadModel(nMiniSceneIndex)
        UIHelper.SetVisible(self.tbWidgetDownloadBtnShell[nMiniSceneIndex], false)
        return
    end

    if dwID == g_pClientPlayer.dwID then
        self:UpdateMiniSceneModel(dwID)
        return
    end

    if GetPlayer(dwID) then
        self:UpdateMiniSceneModel(dwID)
        return
    end

    if not self.dwPeekingID then
        PeekOtherPlayer(dwID)
        self.dwPeekingID = dwID
    else
        self.tbWaitPeek[dwID] = nMiniSceneIndex
    end
end

function UITeamGroupView:FinishPeek(dwID, bOk)
    if not self.dwPeekingID or dwID ~= self.dwPeekingID then
        return
    end
    if bOk then
        self:UpdateMiniSceneModel(dwID)
    end
    self.tbWaitPeek[dwID] = nil
    self.dwPeekingID = nil
    for dwFirstID, nMiniSceneIndex in pairs(self.tbWaitPeek) do
        self:StartStopPeek(dwFirstID, nMiniSceneIndex, true)
    end
end

function UITeamGroupView:UpdateMiniSceneModel(dwID)
    self:enumGroupCells(function (cell)
        if cell.dwID == dwID then
            self:UpdateDownloadEquipRes(dwID, cell.nMiniSceneIndex)
            self:UpdateModel(dwID, cell.nMiniSceneIndex)
            return false
        end
        return true
    end)
end

function UITeamGroupView:UpdateDownloadEquipRes(dwID, nMiniSceneIndex)
    if not PakDownloadMgr.IsEnabled() then
        return
    end
    local hTarget = GetPlayer(dwID)
    if not hTarget then
        return
    end
    local tRepresentID = Role_GetRepresentID(hTarget)
    local nRoleType = hTarget.nRoleType
    local tEquipList, tEquipSfxList = Player_GetPakEquipResource(nRoleType, tRepresentID.nHatStyle, tRepresentID)
    local scriptDownload = UIHelper.GetBindScript(self.tbWidgetDownloadBtnShell[nMiniSceneIndex])
    local tConfig = {}
    tConfig.bLong = true
    local bRemoteNotExist
    self.tbDownloadDynamicIDs[nMiniSceneIndex], bRemoteNotExist = PakDownloadMgr.UserCheckDownloadEquipRes(nRoleType, tEquipList, tEquipSfxList, self.tbDownloadDynamicIDs[nMiniSceneIndex])
    CoinShopPreview.UpdateSimpleDownloadBtn(scriptDownload, self.tbDownloadDynamicIDs[nMiniSceneIndex], bRemoteNotExist, tConfig)
end

function UITeamGroupView:UpdateModel(dwID, nMiniSceneIndex)
    local hModelView = self.tbModelViews[nMiniSceneIndex]
    if not hModelView then
        return
    end
    local hTarget = GetPlayer(dwID)
    if not hTarget then
        return
    end
    local pos = self.tPos[nMiniSceneIndex]
    hModelView:UnloadModel()
    hModelView:LoadPlayerRes(hTarget.dwID, false)
    hModelView:LoadModel()
    hModelView:SetWeaponSocketDynamic()
    hModelView:PlayAnimation("StandardNew", "loop")
    hModelView:SetTranslation(pos[1], pos[2], pos[3])
    hModelView:SetYaw(pos[4])
    hModelView:Show(self.bModelVisible or false)
end

function UITeamGroupView:SetModelVisible(bVisible)
    self.bModelVisible = bVisible
    if self.tbModelViews then
        for _, hModelView in pairs(self.tbModelViews) do
            hModelView:Show(bVisible)
        end
    end
end

function UITeamGroupView:ClearSelect()
    self:enumGroupCells(function (cell)
        UIHelper.SetSelected(cell.TogSelect, false, false)
        return true
    end)
    UIHelper.SetSelected(self.TogVoice, false)
end

return UITeamGroupView