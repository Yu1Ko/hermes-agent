-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetRoomPlayerCell
-- Date: 2025-05-27 10:55:24
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetRoomPlayerCell = class("UIWidgetRoomPlayerCell")

function UIWidgetRoomPlayerCell:OnEnter(szRoomID, tbMember, bInBatch, fnSelectPlayer)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbMember = tbMember
    self.bInBatch = bInBatch
    self.szGlobalID = tbMember.szGlobalID
    self.bEnableMic = tbMember.bEnableMic
    self.szGVoiceID = tbMember.szGVoiceID
    self.bNotOnline = tbMember.bNotOnline
    self.szRoomID = szRoomID
    self.fnSelectPlayer = fnSelectPlayer
    self:UpdateInfo()
    Timer.DelTimer(self, self.nTimerID)
    if not self.bNotOnline then
        self.nTimerID = Timer.AddCycle(self, 0.5, function()
            self:UpdateMic()
        end)
    end
end

function UIWidgetRoomPlayerCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetRoomPlayerCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSelectPlayer, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            RoomVoiceData.AddOperateList(self.tbMember, self.szRoomID)
        else
            RoomVoiceData.DelOperateList(self.tbMember)
        end
    end)

    UIHelper.BindUIEvent(self.BtnPlayerHead, EventType.OnClick, function(_, bSelected)
        self:OnSelectPlayer()
    end)
end

function UIWidgetRoomPlayerCell:RegEvent()
    Event.Reg(self, "SYNC_VOICE_MEMBER_SOCIAL_INFO", function(tbGlobalID)
        if table.contain_value(tbGlobalID, self.szGlobalID) then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "ON_CLIENT_MEMEBER_VOICE", function(szRoomID)
        
    end)

    Event.Reg(self, "FELLOWSHIP_ROLE_ENTRY_UPDATE", function(tPlayerID)
        if self.ApplyRoleEntryInfo then
            self:OnSelectPlayer()
        end
	end)
end


function UIWidgetRoomPlayerCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetRoomPlayerCell:GetMenuConfigSet(szRoomID, szGlobalID, tbRoleEntryInfo)
    local tbMenuConfig = {
        {
            szName = "添加好友", bCloseOnClick = true,
            fnCheckShow = function () return tbRoleEntryInfo.dwPlayerID ~= PlayerData.GetPlayerID() and not FellowshipData.IsFriend(szGlobalID) end,
            callback = function()
                FellowshipData.AddFellowship(tbRoleEntryInfo.szName)
            end
        },

        { 
            szName = "密聊", bCloseOnClick = true, callback = function()
                local bDelete = tbRoleEntryInfo.szName == ""
                local szName = UIHelper.GBKToUTF8(tbRoleEntryInfo.szName)
                local dwTalkerID = tbRoleEntryInfo.dwPlayerID
                local dwForceID = tbRoleEntryInfo.nForceID
                local dwMiniAvatarID = tbRoleEntryInfo.dwMiniAvatarID
                local nRoleType = tbRoleEntryInfo.nRoleType
                local nLevel = tbRoleEntryInfo.nLevel
                local szGlobalID = szGlobalID
                local dwCenterID = tbRoleEntryInfo.dwCenterID
                local tbData = {szName = szName, dwTalkerID = dwTalkerID, dwForceID = dwForceID, dwMiniAvatarID = dwMiniAvatarID, nRoleType = nRoleType, nLevel = nLevel, szGlobalID = szGlobalID, dwCenterID = dwCenterID}

                ChatHelper.WhisperTo(szName, tbData)
                UIHelper.SetSelected(self.ToggleSelect, false)
                UIMgr.Close(VIEW_ID.PanelVoiceRoomSearchMenberPop)
            end , fnDisable = function()
                return false--not bOnLine
            end
        },

        
        { 
            szName = "查看装备", bCloseOnClick = true, callback = function()
                UIMgr.Open(VIEW_ID.PanelOtherPlayer, tbRoleEntryInfo.dwPlayerID, tbRoleEntryInfo.dwCenterID, szGlobalID)
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetPlayerPop)
            end,fnDisable = function()
                return self.bNotOnline
            end 
        },

         { 
            szName = "举报", bCloseOnClick = true, callback = function()
                RoomVoiceData.Report(szRoomID, self.szGlobalID)
            end
        },
    }

    local bSelfRoomOwner = RoomVoiceData.IsRoomOwner(szRoomID, g_pClientPlayer.GetGlobalID())
    local bSelfAdmin = RoomVoiceData.IsAdmin(szRoomID, g_pClientPlayer.GetGlobalID())
    local bAdmin = RoomVoiceData.IsAdmin(szRoomID, self.szGlobalID)
    local bNormalMember = RoomVoiceData.IsNormalMember(szRoomID, self.szGlobalID)
    local bRoomOwner = RoomVoiceData.IsRoomOwner(szRoomID, self.szGlobalID)
    local bAudience = not bAdmin and not bRoomOwner

    if (bSelfRoomOwner or bSelfAdmin) and bAudience then
        local tbRoomInfo = RoomVoiceData.GetVoiceRoomInfo(szRoomID)
        local nMicMode = tbRoomInfo and tbRoomInfo.nMicMode or VOICE_ROOM_MIC_MODE.INVALID
        local tbMemberInfo = RoomVoiceData.GetVoiceRoomMemberSocialInfo(szGlobalID)
        if nMicMode == VOICE_ROOM_MIC_MODE.MANAGE_MODE then
            if self.bEnableMic then
                table.insert(tbMenuConfig, {
                    szName = "下麦", bCloseOnClick = true, callback = function()
                        RoomVoiceData.OperateMemberMic(szRoomID, self.szGlobalID, false)
                    end,
                })
            else
                table.insert(tbMenuConfig, {
                szName = "上麦", bCloseOnClick = true, callback = function()
                    RoomVoiceData.OperateMemberMic(szRoomID, self.szGlobalID, true)
                end,})
            end
        end

        table.insert(tbMenuConfig, { 
            szName = "踢出", bCloseOnClick = true, callback = function()
                local szMessage = FormatString(g_tStrings.GVOICE_ROOM_KICKOUT_MESSAGE_TIP, UIHelper.GBKToUTF8(tbRoleEntryInfo.szName))
                UIHelper.ShowConfirm(szMessage, function()
                    RoomVoiceData.KickOutVoiceRoomMember(self.szRoomID, self.szGlobalID)
                end)
            end,
        })
    end

    if self.szRoomID and self.szRoomID ~= "0" and self.szGlobalID ~= g_pClientPlayer.GetGlobalID() then
        table.insert(tbMenuConfig, 1, {
            szName = "赠礼", bCloseOnClick = true, callback = function()
                local szGlobalID = self.szGlobalID
                -- 检查是否正在处理该玩家的赠礼（防重复点击）
                if RoomVoiceData.IsProcessingTip(szGlobalID) then
                    TipsHelper.ShowNormalTip("正在赠礼中，请稍候...")
                    return
                end

                local dwCenterID, bIsDefault, szSource = RoomVoiceData.GetValidCenterID(szGlobalID)
                local function ExecuteTip(nNum, nGold, nTipItemID, dwFinalCenterID, szDataSource)
                    local tbInfo = RoomVoiceData.GetVoiceRoomInfo(self.szRoomID) or {}
                    local szRoomName = tbInfo.szRoomName or ""

                    if nGold * nNum >= GiftHelper.MESSAGE_TIP_NUM then
                        local szContent = FormatString(g_tStrings.STR_VOICE_REWARD_NUM_BIG_MESSAGE, nGold * nNum)
                        UIHelper.ShowConfirm(szContent, function()
                            LOG.INFO("VOICE_ROOM todo ExecuteTip: dwCenterID: %s, source: %s, nNum: %s, nGold: %s", dwFinalCenterID, szDataSource, nNum, nGold)
                            GiftHelper.TipByGlobalID(dwFinalCenterID, szGlobalID, nNum, nGold, nTipItemID, szRoomName, self.szRoomID)
                        end)
                        return
                    end

                    LOG.INFO("VOICE_ROOM todo ExecuteTip: dwCenterID: %s, source: %s, nNum: %s, nGold: %s", dwFinalCenterID, szDataSource, nNum, nGold)
                    GiftHelper.TipByGlobalID(dwFinalCenterID, szGlobalID, nNum, nGold, nTipItemID, szRoomName, self.szRoomID)
                end

                GiftHelper.OpenTip(TIP_TYPE.GlobalID, {szRoomID = self.szRoomID, szGlobalID = szGlobalID}, function (nNum, nGold, nTipItemID)
                    if bIsDefault or dwCenterID == 0 then
                        RoomVoiceData.AddTipWaitingTask(
                            szGlobalID,
                            function(dwFinalCenterID, szDataSource)
                                ExecuteTip(nNum, nGold, nTipItemID, dwFinalCenterID, szDataSource)
                            end,
                            function()
                                TipsHelper.ShowNormalTip("赠礼超时")
                                JustLog("VOICE_ROOM TipTimeout: szGlobalID:", szGlobalID)
                            end,
                            3 -- 超时时间 3 秒
                        )
                    else
                        ExecuteTip(nNum, nGold, nTipItemID, dwCenterID, szSource)
                    end
                end)
            end,
            fnDisable = function()
                return self.bNotOnline
            end
        })
    end

    if bSelfRoomOwner then
        if bAudience then
            table.insert(tbMenuConfig, { 
                szName = "设为管理员", bCloseOnClick = true, callback = function()
                    RoomVoiceData.SetVoiceRoomAdmin(self.szRoomID, self.szGlobalID, true)
                end,
            })
        elseif bAdmin then
            table.insert(tbMenuConfig, { 
                szName = "取消管理员", bCloseOnClick = true, callback = function()
                    RoomVoiceData.SetVoiceRoomAdmin(self.szRoomID, self.szGlobalID, false)
                end,
            })
        end
    end

    return tbMenuConfig
end

function UIWidgetRoomPlayerCell:OnSelectPlayer()
    if self.szGlobalID == g_pClientPlayer.GetGlobalID() then return end
    local tbRoleEntryInfo = FellowshipData.GetRoleEntryInfo(self.szGlobalID)
    if not tbRoleEntryInfo then
        FellowshipData.ApplyRoleEntryInfo({self.szGlobalID})
        self.ApplyRoleEntryInfo = true
        return
    end
    self.ApplyRoleEntryInfo = false
    local tbMenuConfig =self:GetMenuConfigSet(self.szRoomID, self.szGlobalID, tbRoleEntryInfo)
    if self.fnSelectPlayer then
        local tFromRoom = {szRoomID = self.szRoomID, szGVoiceID = self.szGVoiceID}
        self.fnSelectPlayer(tbMenuConfig, tbRoleEntryInfo, self._rootNode, self.szGlobalID, tFromRoom)
    end
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetRoomPlayerCell:UpdateInfo()
    self.tbInfo = RoomVoiceData.GetVoiceRoomMemberSocialInfo(self.szGlobalID)
    self.bIsRoomOwner = RoomVoiceData.IsRoomOwner(self.szRoomID, self.szGlobalID)
    self.bIsAdmin = RoomVoiceData.IsAdmin(self.szRoomID, self.szGlobalID)
    if not self.tbInfo then
        return
    end
    local tbInfo = self.tbInfo
    UIHelper.SetString(self.LabelPlayerName, UIHelper.GBKToUTF8(tbInfo.szName), 4)

    if not self.scriptHead then
        self.scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead_72)
    end
    self.scriptHead:SetHeadInfo(nil, tbInfo.dwMiniAvatarID or 0, tbInfo.nRoleType, tbInfo.nForceID)
    self.scriptHead:SetTouchEnabled(false)
    UIHelper.SetVisible(self.ImgSelf, self.szGlobalID == g_pClientPlayer.GetGlobalID())
    UIHelper.SetVisible(self.WidgetRoomOwner, self.bIsRoomOwner or self.bIsAdmin)
    UIHelper.SetSwallowTouches(self.BtnPlayerHead, false)
    local bGray = self.bNotOnline ~= nil and self.bNotOnline == true
    UIHelper.SetNodeGray(self.BtnPlayerHead, bGray, true)
    UIHelper.SetString(self.LabelMicMode, self.bIsRoomOwner and "房主" or "管理")
    UIHelper.SetVisible(self.ImgOffLine, self.bNotOnline)
    self:UpdateMic()
    self:SwitchState(self.bInBatch)
end

function UIWidgetRoomPlayerCell:UpdateMic()
    local bEnableMic = RoomVoiceData.CanMemberMic(self.szRoomID, self.szGlobalID)
    self.bEnableMic = bEnableMic
    if bEnableMic then
        UIHelper.SetVisible(self.ImgMicOn, self.szGVoiceID and RoomVoiceData.IsMemberSaying(self.szRoomID, self.szGVoiceID))
    else
        UIHelper.SetVisible(self.ImgMicOn, true)
    end
    local szFrame = bEnableMic and "UIAtlas2_VoiceRoom_VoiceRoom1_icon_mic03" or "UIAtlas2_VoiceRoom_VoiceRoom1_icon_mic02"
    UIHelper.SetSpriteFrame(self.ImgMicOn, szFrame)
end

function UIWidgetRoomPlayerCell:CheckCanSelect()
    return not self.bIsRoomOwner and not RoomVoiceData.IsAdmin(self.szRoomID, self.szGlobalID)
end

function UIWidgetRoomPlayerCell:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogSelectPlayer, bSelected)
end

function UIWidgetRoomPlayerCell:UpdateSelectState()
    UIHelper.SetVisible(self.TogSelectPlayer, self.bInSelect and self:CheckCanSelect())
    if not self.bInSelect then
        UIHelper.SetSelected(self.TogSelectPlayer, false, false)
    else
        UIHelper.SetSelected(self.TogSelectPlayer, RoomVoiceData.IsInOperateList(self.tbMember), false)
    end
end

function UIWidgetRoomPlayerCell:SwitchState(bEnter)
    self.bInSelect = bEnter
    self:UpdateSelectState()
end

return UIWidgetRoomPlayerCell