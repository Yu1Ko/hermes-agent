-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetVoiceChatContentView
-- Date: 2025-05-19 10:35:02
-- Desc: ?
-- ---------------------------------------------------------------------------------
local PAGE_TYPE = {
    Recommend = 1,
    Like = 2,
    RoomInfo = 3,
    LiveStream = 4,
}


local UIWidgetVoiceChatContentView = class("UIWidgetVoiceChatContentView")

function UIWidgetVoiceChatContentView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:Init()
end

function UIWidgetVoiceChatContentView:OnExit()
    RoomVoiceData.ClearOperateList()
    self.bInit = false
    self:UnRegEvent()
    if self.cellVoiceRoomCell then
        self.cellVoiceRoomCell:Dispose()
    end
    if self.tRoomScrollList then
        self.tRoomScrollList:Destroy()
        self.tRoomScrollList = nil
    end
end

function UIWidgetVoiceChatContentView:BindUIEvent()
    UIHelper.BindUIEvent(self.TogTab_1, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:SwitchPage(PAGE_TYPE.Recommend)
        end
    end)

    UIHelper.BindUIEvent(self.TogTab_2, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:SwitchPage(PAGE_TYPE.Like)
        end
    end)

    UIHelper.BindUIEvent(self.TogTab_3, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:SwitchPage(PAGE_TYPE.LiveStream)
        end
    end)

    UIHelper.BindUIEvent(self.TogTypeFuwuqi, EventType.OnSelectChanged, function(_, bSelected)
        self.bFilterFuwuqi = bSelected -- 仅显示本服
        self:UpdateRecommendOrLikeList()

        Storage.VoiceRoomFilter.bFilterFuwuqi = bSelected
        Storage.VoiceRoomFilter.Dirty()
    end)

    UIHelper.BindUIEvent(self.TogTypeEnter, EventType.OnSelectChanged, function(_, bSelected)
        self.bFilterEnter = bSelected -- 仅显示可进入
        self:UpdateRecommendOrLikeList()

        Storage.VoiceRoomFilter.bFilterEnter = bSelected
        Storage.VoiceRoomFilter.Dirty()
    end)

    UIHelper.BindUIEvent(self.TogSift, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelLiveBroadcastPop, clone(self.tbFilterMapIDs) or {}, function(tbMapIDs)
            if tbMapIDs and not table.is_empty(tbMapIDs) then
                self.tbFilterMapIDs = tbMapIDs
                self:ApplyLiveStreamInfoForRooms()
            else
                self.tbFilterMapIDs = nil
            end
            self:UpdateRecommendOrLikeList()
        end)
    end)

    --点击我的房间
    UIHelper.BindUIEvent(self.tbUIRoomList[1], EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:ChooseMyRoom()
        end
    end)

    --点击他人房间
    UIHelper.BindUIEvent(self.tbUIRoomList[2], EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:ChooseOtherRoom()
        end
    end)

    UIHelper.BindUIEvent(self.BtnCreate, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelCreateVoiceRoomPop)
    end)

    UIHelper.BindUIEvent(self.BtnSendChat, EventType.OnClick, function()
        local tbInfo = RoomVoiceData.GetVoiceRoomInfo(self.szCurRoomID)
        local szName = UIHelper.GBKToUTF8(tbInfo.szRoomName) or ""
        local szLinkInfo = string.format("VoiceRoom/%s", self.szCurRoomID)
        ChatHelper.SendEventLinkToChat("聊天室·"..szName, szLinkInfo)
    end)

    UIHelper.BindUIEvent(self.BtnQuitRoom, EventType.OnClick, function()
        local szMessage = g_tStrings.GVOICE_ROOM_EXIT_MESSAGE_TIP
        local szPlayerGlobalID = g_pClientPlayer.GetGlobalID()
        local tRoomInfo = RoomVoiceData.GetVoiceRoomInfo(self.szCurRoomID)
        if tRoomInfo.nRoomLevel == 0 and tRoomInfo.szMasterID == szPlayerGlobalID then
            szMessage = szMessage .. g_tStrings.GVOICE_ROOM_EXIT_MESSAGE_TIP2
        end
        UIHelper.ShowConfirm(szMessage, function()
            --好像没接口主动退出房间,用踢人接口
            RoomVoiceData.KickOutVoiceRoomMember(self.szCurRoomID, szPlayerGlobalID)
        end)
    end)

    UIHelper.BindUIEvent(self.BtnVip, EventType.OnClick, function()
        local tbInfo = RoomVoiceData.GetVoiceRoomInfo(self.szCurRoomID)
        if tbInfo then
            UIMgr.Open(VIEW_ID.PanelAddVipTimePop, tbInfo.nSuperRoomTime)
        else
            LOG.INFO("Didn't Find RoomInfo, szRoomID:%s", self.szCurRoomID)
        end
    end)

    UIHelper.BindUIEvent(self.BtnSwitched, EventType.OnClick, function()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "player talk") then
            return
        end
        local szRoomID = self.szCurRoomID
        local tbInfo = RoomVoiceData.GetVoiceRoomInfo(szRoomID)
        local nMicMode = tbInfo.nMicMode + 1
        if nMicMode >= 4 then
            nMicMode = 1
        end

        if RoomVoiceData.ChangeRoomDetailInfo(szRoomID, nMicMode, tbInfo.nCampLimitMask, tbInfo.nLevelLimit, tbInfo.bPublic) then
            TipsHelper.ShowNormalTip("修改发言模式成功")
        end
    end)

    UIHelper.BindUIEvent(self.BtnEditAnnouncement, EventType.OnClick, function()
        local szDefault = ""
        local tbInfo = RoomVoiceData.GetVoiceRoomInfo(self.szCurRoomID)
        if tbInfo then
            szDefault = UIHelper.GBKToUTF8(tbInfo.szDescription)
        end
        UIMgr.Open(VIEW_ID.PanelFactionAnnounceEditPop, "语音聊天室公告", szDefault, function(szText)
            RoomVoiceData.ChangeRoomDescription(self.szCurRoomID, UIHelper.UTF8ToGBK(szText))
        end, 50, "房主似乎什么公告也没写...")
    end)

    UIHelper.BindUIEvent(self.BtnBatchManage, EventType.OnClick, function()
        self:SwitchBatchState(not self.bInBatch)
    end)

    UIHelper.BindUIEvent(self.BtnMuteAll, EventType.OnClick, function()
        RoomVoiceData.OperateAllMemberMic(self.szCurRoomID, false)
    end)

    UIHelper.BindUIEvent(self.BtnKickAll, EventType.OnClick, function()
        RoomVoiceData.KickOutAllVoiceRoomMember(self.szCurRoomID)
    end)

    UIHelper.BindUIEvent(self.BtnDissolveRoom, EventType.OnClick, function()
        RoomVoiceData.DisbandVoiceRoom(self.szCurRoomID)
    end)

    UIHelper.BindUIEvent(self.BtnEditRoom, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelCreateVoiceRoomPop, RoomVoiceData.GetVoiceRoomInfo(self.szCurRoomID), self.szCurRoomID)
    end)

    UIHelper.BindUIEvent(self.BtnLevelUp, EventType.OnClick, function()
        local tbInfo = RoomVoiceData.GetVoiceRoomInfo(self.szCurRoomID)
        if tbInfo.nRoomLevel == 0 then
            UIMgr.Open(VIEW_ID.PanelUpgradeChatRoomPop)
        else
            UIMgr.Open(VIEW_ID.PanelUpgradeChatRoomPop, tbInfo.nRoomLevel)
        end
    end)

    UIHelper.BindUIEvent(self.BtnSearch, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelVoiceRoomSearchMenberPop, self.szCurRoomID)
    end)

    UIHelper.BindUIEvent(self.BtnVoiceSetting, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelGameSettings, SettingCategory.Sound, 1)
    end)

    UIHelper.BindUIEvent(self.BtnReportRoom, EventType.OnClick, function()
        local tbRoomInfo = RoomVoiceData.GetVoiceRoomInfo(self.szCurRoomID)
        RoomVoiceData.Report(self.szCurRoomID, tbRoomInfo.szMasterID)
    end)

    UIHelper.BindUIEvent(self.TogMoreSetting, EventType.OnClick, function()
        self:UpdateBtnBeepSwitch()
    end)

    UIHelper.BindUIEvent(self.BtnBeepSwitch, EventType.OnClick, function()
        TipsHelper.ShowNormalTip(RoomVoiceData.IsMemberJoinBeep() and "已关闭成员加入提示音" or "已开启成员加入提示音")
        RoomVoiceData.ToogleMemberJoinBeep()
    end)

    UIHelper.BindUIEvent(self.BtnGoLive, EventType.OnClick, function()
        local tbRoomInfo = RoomVoiceData.GetVoiceRoomInfo(self.szCurRoomID)
        if not tbRoomInfo then
            return
        end

        local bIsRoomOwner = RoomVoiceData.IsRoomOwner(self.szCurRoomID, g_pClientPlayer.GetGlobalID())
        if bIsRoomOwner then
            if OBDungeonData.IsPlayerInOBDungeon() then
                TipsHelper.ShowNormalTip("正在副本观战中，无法开启直播")
                return
            end
            -- 房主：打开副本观战设置弹窗
            local tLiveInfo = RoomVoiceData.GetLiveStreamInfo(tbRoomInfo.szMasterID)
            local nCurrentMapID = tLiveInfo and tLiveInfo.nMapID or 0
            UIMgr.Open(VIEW_ID.PanelLiveBroadcastPop, nCurrentMapID)
        else
            -- 非房主：进入观战
            local tLiveInfo = RoomVoiceData.GetLiveStreamInfo(tbRoomInfo.szMasterID)
            if tLiveInfo and tLiveInfo.bInLiveMap then
                RoomVoiceData.WatchLiveStream(tbRoomInfo.szMasterID)
            end
        end
    end)

    UIHelper.BindUIEvent(self.BtnGift, EventType.OnClick, function()
        if not self.szCurRoomID then
            return
        end

        local tbInfo = RoomVoiceData.GetVoiceRoomInfo(self.szCurRoomID)
        local szMasterID = tbInfo and tbInfo.szMasterID or ""

        if not szMasterID or szMasterID == "0" then
            return
        end

        if RoomVoiceData.IsProcessingTip(szMasterID) then
            TipsHelper.ShowNormalTip("正在赠礼中，请稍候...")
            return
        end

        local dwCenterID, bIsDefault, szSource = RoomVoiceData.GetValidCenterID(szMasterID)
        local function ExecuteTip(nNum, nGold, nTipItemID, dwFinalCenterID, szDataSource)
            local tbInfo = RoomVoiceData.GetVoiceRoomInfo(self.szCurRoomID) or {}
            local szRoomName = tbInfo.szRoomName or ""
            if nGold * nNum >= GiftHelper.MESSAGE_TIP_NUM then
                local szContent = FormatString(g_tStrings.STR_VOICE_REWARD_NUM_BIG_MESSAGE, nGold * nNum)
                UIHelper.ShowConfirm(szContent, function()
                    GiftHelper.TipByGlobalID(dwFinalCenterID, szMasterID, nNum, nGold, nTipItemID, szRoomName, self.szCurRoomID)
                end)
                return
            end
            GiftHelper.TipByGlobalID(dwFinalCenterID, szMasterID, nNum, nGold, nTipItemID, szRoomName, self.szCurRoomID)
        end

        GiftHelper.OpenTip(TIP_TYPE.GlobalID, {szRoomID = self.szCurRoomID, szGlobalID = szMasterID}, function (nNum, nGold, nTipItemID)
            if bIsDefault or dwCenterID == 0 then
                RoomVoiceData.AddTipWaitingTask(
                    szMasterID,
                    function(dwFinalCenterID, szDataSource)
                        ExecuteTip(nNum, nGold, nTipItemID, dwFinalCenterID, szDataSource)
                    end,
                    function()
                        TipsHelper.ShowNormalTip("赠礼超时")
                        JustLog("TipTimeout(Master): szMasterID:", szMasterID)
                    end,
                    3 -- 超时时间 3 秒
                )
            else
                ExecuteTip(nNum, nGold, nTipItemID, dwCenterID, szSource)
            end
        end)
    end)

    UIHelper.RegisterEditBoxEnded(self.SearchEditBox, function()
        local szRoomID = UIHelper.GetText(self.SearchEditBox)
        if UIHelper.IsDigit(szRoomID) then
            self.szSearchID = szRoomID
            self:UpdateRecommendOrLikeList()
        elseif szRoomID == "" then
            self.szSearchID = nil
            self:UpdateRecommendOrLikeList()
        else
            TipsHelper.ShowNormalTip("请输入正确的房间ID")
        end
    end)
end

function UIWidgetVoiceChatContentView:RegEvent()

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        Timer.AddFrame(self, 5, function()
            self:UpdateRecommendOrLikeList()
        end)
    end)
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        UIHelper.SetSelected(self.TogManage, false)
        UIHelper.SetSelected(self.TogMoreSetting, false)
        UIHelper.LayoutDoLayout(self.LayoutMenu)
    end)

    Event.Reg(self, EventType.BackToVoiceRoom, function()
        self:UpdateRoomListAutoSelect()
    end)

    Event.Reg(self, EventType.OnLikeRoomChanged, function()
        if self.nPage == PAGE_TYPE.Like and not self:IsInSearchMode() then
            self:UpdateRecommendOrLikeList()
        end
    end)

    Event.Reg(self, EventType.ON_SYNC_ROLE_VOICE_ROOM_LIST, function()
        self:UpdateLeftRoomList()
        self:UpdateRoomListAutoSelect()
    end)

    Event.Reg(self, EventType.ON_JOIN_VOICE_ROOM, function(szRoomID, szSignature, bCreateRoom, bIsTeamRoom)
        self:UpdateLeftRoomList()
        self:UpdateRoomListAutoSelect()
    end)

    Event.Reg(self, EventType.OnMemberLeaveVoiceRoom, function(szRoomID, szMemberID)
        self:OnLeaveRoom(szRoomID, szMemberID)
    end)

    Event.Reg(self, EventType.OnMemberJoinVoiceRoom, function(szRoomID, szMemberID)
        self:OnJoinRoom(szRoomID, szMemberID)
    end)

    Event.Reg(self, EventType.ON_SYNC_VOICE_ROOM_INFO, function(szRoomID, bRoomExist)
        if self.szSearchID and self.szSearchID == szRoomID and self.nPage == PAGE_TYPE.Recommend and bRoomExist then
            self:UpdateRecommendOrLikeList()
        end

        if (self.nPage == PAGE_TYPE.Recommend or self.nPage == PAGE_TYPE.LiveStream) and bRoomExist then
            self.nUpdateRoomInfoTimer = self.nUpdateRoomInfoTimer or Timer.Add(self, 3, function()
                self:UpdateRecommendOrLikeList()
                self.nUpdateRoomInfoTimer = nil
            end)
        end

        if self.nPage == PAGE_TYPE.RoomInfo then
            self:UpdateSetting()
        end
        self:UpdateLeftRoomName()
    end)

    Event.Reg(self, EventType.ON_LIVE_STREAM_INFO_UPDATE, function()
        if self.nPage == PAGE_TYPE.RoomInfo then
            self:UpdateSetting()
        end

        -- 地图筛选模式下，只在申请的直播数据返回时刷新
        if self.tbFilterMapIDs and next(self.tbPendingLiveStreamMasters) then
            local bHasNewData = false
            for szMasterID in pairs(self.tbPendingLiveStreamMasters) do
                if RoomVoiceData.GetLiveStreamInfo(szMasterID) then
                    bHasNewData = true
                    break
                end
            end
            if bHasNewData then
                self.tbPendingLiveStreamMasters = {}
                self:UpdateRecommendOrLikeList()
            end
        end
    end)

    Event.Reg(self, "DISBAND_VOICE_ROOM", function(szRoomID)
        self:OnLeaveRoom(szRoomID, g_pClientPlayer.GetGlobalID())
    end)

    Event.Reg(self, "GET_TOP_POPULARITY_VOICE_ROOM", function(tbRoomList)
        RoomVoiceData.OnGetTopPopularityVoiceRoom(tbRoomList)

        self.nUpdateRoomInfoTimer = self.nUpdateRoomInfoTimer or Timer.Add(self, 2, function()
            self:UpdateRecommendOrLikeList()
            self.nUpdateRoomInfoTimer = nil
        end)
    end)

    Event.Reg(self, "TIP_IN_VOICE_ROOM_NOTIFY", function(szGlobalID, szTargetGlobalID, nGold, nNum)
        if self.nPage ~= PAGE_TYPE.RoomInfo then
            return
        end
        self:UpdateTipHint(szGlobalID, szTargetGlobalID, nGold, nNum)
    end)

    Event.Reg(self, EventType.OnNeedToUpdateTopRecommendList, function()
        if self.nPage == PAGE_TYPE.Recommend or self.nPage == PAGE_TYPE.Like or self.nPage == PAGE_TYPE.LiveStream then
            self:UpdateRecommendOrLikeList(true)
        end
    end)

    Event.Reg(self, EventType.OnMemberMicStateChanged, function(szRoomID, szMemberID, bOpen)
        self:UpdateLeftRoomMicAndSpeakState()
    end)

    Event.Reg(self, EventType.OnGMEMicStateChanged, function()
        self:UpdateLeftRoomMicAndSpeakState()
    end)

    Event.Reg(self, EventType.OnGMESpeakerStateChanged, function()
        self:UpdateLeftRoomMicAndSpeakState()
    end)
end

function UIWidgetVoiceChatContentView:UnRegEvent()
    -- 清理打赏提示相关资源
    if self.tbDalayShowTips then
        self.tbDalayShowTips = {}
    end
    self.bIsShowingTip = false
end

function UIWidgetVoiceChatContentView:Init()
    self.cellVoiceRoomCell = self.cellVoiceRoomCell or PrefabPool.New(PREFAB_ID.WidgetVoiceRoomListCell)
    if not self.tRoomScrollList then
        self.tRoomScrollList = UIScrollList.Create({
            listNode = self.LayoutVoiceChatRoomList,
            nSpace = 0,
            fnGetCellType = function(nIndex)
                return PREFAB_ID.WidgetVoiceRoomListCell
            end,
            fnUpdateCell = function(cell, nIndex)
                local szRoomID = self.tbRecommendRoomList and self.tbRecommendRoomList[nIndex]
                if szRoomID then
                    cell:OnEnter(szRoomID, function(szRoomID, bPwdRequired)
                        self:TryJoinRoom(szRoomID, bPwdRequired)
                    end, self.nPage)
                end
            end,
        })
    end
    UIHelper.SetToggleGroupIndex(self.TogTab_1, ToggleGroupIndex.FlowerFertilizerItem)
    UIHelper.SetToggleGroupIndex(self.TogTab_2, ToggleGroupIndex.FlowerFertilizerItem)
    UIHelper.SetToggleGroupIndex(self.TogTab_3, ToggleGroupIndex.FlowerFertilizerItem)
    for nIndex, tog in ipairs(self.tbUIRoomList) do
        UIHelper.SetToggleGroupIndex(tog, ToggleGroupIndex.FlowerFertilizerItem)
    end
    self.nPage = nil

    self.bFilterEnter = Storage.VoiceRoomFilter.bFilterEnter
    self.bFilterFuwuqi = Storage.VoiceRoomFilter.bFilterFuwuqi
    UIHelper.SetSelected(self.TogTypeEnter, self.bFilterEnter, false)
    UIHelper.SetSelected(self.TogTypeFuwuqi, self.bFilterFuwuqi, false)

    self.tbFilterMapIDs = nil -- 地图筛选 ID 集合，nil 表示无筛选
    self.tbPendingLiveStreamMasters = {} -- 等待直播信息返回的主播 ID 集合

    UIHelper.SetSelected(self.TogTab_1, true)

    RoomVoiceData.ApplyRoomList()
end


function UIWidgetVoiceChatContentView:UpdateRoomListAutoSelect()
    local nState = RoomVoiceData.GetPlayerRoomState()
    if RoomVoiceData.bAutoSelectedLiveTab then
        self:SelectTog(self.TogTab_3) -- 跳转直播页
        RoomVoiceData.bAutoSelectedLiveTab = false
    elseif nState == RoomVoiceData.PLAYER_VOICE_ROO_STATE.InMyOwnRoom then
        self:SelectTog(self.tbUIRoomList[1])
    elseif nState == RoomVoiceData.PLAYER_VOICE_ROO_STATE.InOtherRoom then
        self:SelectTog(self.tbUIRoomList[2])
    else
        self:SelectTog(self.TogTab_1)
    end

    local szMyRoomID, szCurRoomID = RoomVoiceData.GetRoleVoiceRoomList()
    RoomVoiceData.DelayApplyVoiceRoomInfo(szMyRoomID)
    RoomVoiceData.DelayApplyVoiceRoomInfo(szCurRoomID)
end

function UIWidgetVoiceChatContentView:SelectTog(tog)
    UIHelper.SetSelected(tog, true)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetVoiceChatContentView:ClearSearchEdit()
    UIHelper.SetText(self.SearchEditBox, "")
    self.szSearchID = nil
end

function UIWidgetVoiceChatContentView:IsInSearchMode()
    return self.szSearchID ~= nil
end

function UIWidgetVoiceChatContentView:OnPageChange()
    self.tbFilterMapIDs = nil
    self:UpdateTogSiftImg()

    if self.nPage == PAGE_TYPE.Recommend then
        self:ClearSearchEdit()
        RoomVoiceData.ApplyTopPopularityVoiceRoom()
        self:UpdateRecommendOrLikeList()
        Timer.Add(self, 1, function()
            self:ApplyLiveStreamInfoForRooms()
        end)
    elseif self.nPage == PAGE_TYPE.Like then
        self:ClearSearchEdit()
        self:UpdateRecommendOrLikeList()
    elseif self.nPage == PAGE_TYPE.LiveStream then
        self:ClearSearchEdit()
        RoomVoiceData.ApplyTopPopularityVoiceRoom()
        self:UpdateRecommendOrLikeList()
        Timer.Add(self, 1, function()
            self:ApplyLiveStreamInfoForRooms()
        end)
    else
        self:UpdateRoomInfoWithApply()
    end
    self:UpdateSetting()
end

function UIWidgetVoiceChatContentView:UpdateRoomInfoWithApply()
    RoomVoiceData.ApplyVoiceRoomPermissionInfo(self.szCurRoomID)
    RoomVoiceData.DelayApplyVoiceRoomInfo(self.szCurRoomID)
    RoomVoiceData.ApplyVoiceRoomMemberList(self.szCurRoomID)
    self:UpdateRoomInfo()
end

--1、推荐 2、最近 3、房间 4、直播
function UIWidgetVoiceChatContentView:SwitchPage(nPage)
    if self.nPage == nPage then
        return
    end

    self.nPage = nPage
    self:OnPageChange()
end

function UIWidgetVoiceChatContentView:ChooseMyRoom()
    local script = UIHelper.GetBindScript(self.WidgetCurrentVoiceRoomContent)

    local nState = RoomVoiceData.GetPlayerRoomState()
    if nState ~= RoomVoiceData.PLAYER_VOICE_ROO_STATE.InMyOwnRoom then
        RoomVoiceData.TryJoinMyOwnRoom(function()
            self:UpdateRoomListAutoSelect()
        end)
        if script then
            UIHelper.SetOpacity(script._rootNode, 0)
        end
        return
    end
    if script then
        UIHelper.SetOpacity(script._rootNode, 255)
    end
    local szMyRoomID, szCurrentRoomID = RoomVoiceData.GetRoleVoiceRoomList()
    self:ChooseRoom(szMyRoomID)
end

function UIWidgetVoiceChatContentView:ChooseOtherRoom()
    local script = UIHelper.GetBindScript(self.WidgetCurrentVoiceRoomContent)
    if script then
        UIHelper.SetOpacity(script._rootNode, 255)
    end
    local szMyRoomID, szCurrentRoomID = RoomVoiceData.GetRoleVoiceRoomList()
    self:ChooseRoom(szCurrentRoomID)
end

function UIWidgetVoiceChatContentView:ChooseRoom(szRoomID)
    self.szCurRoomID = szRoomID
    if self.nPage == PAGE_TYPE.RoomInfo then
        self:UpdateRoomInfoWithApply()
    else
        self:SwitchPage(PAGE_TYPE.RoomInfo)
    end
end

function UIWidgetVoiceChatContentView:TryJoinRoom(szRoomID, bPwdRequired)
    RoomVoiceData.TryJoinRoom(szRoomID, bPwdRequired)
end

function UIWidgetVoiceChatContentView:OnLeaveRoom(szRoomID, szMemberID)
    if g_pClientPlayer.GetGlobalID() ~= szMemberID then
        if self.nPage == PAGE_TYPE.RoomInfo then
            self:DelayUpdateRoomInfo()
        end
    else
        self:UpdateLeftRoomList()
        self:UpdateRoomListAutoSelect()
    end
end

function UIWidgetVoiceChatContentView:OnJoinRoom(szRoomID, szMemberID)
    if g_pClientPlayer.GetGlobalID() ~= szMemberID then
        if self.nPage == PAGE_TYPE.RoomInfo then
            self:DelayUpdateRoomInfo()
        end
    end
end

function UIWidgetVoiceChatContentView:OnDisableMic(szRoomID, szMemberID)
    if g_pClientPlayer.GetGlobalID() ~= szMemberID then
        return
    end
    if RoomVoiceData.IsMicOpen(szRoomID) then
        RoomVoiceData.CloseMic(szRoomID)
    end
end

function UIWidgetVoiceChatContentView:SwitchBatchState(bInBatch)
    local script = UIHelper.GetBindScript(self.WidgetCurrentVoiceRoomContent)
    if script then
        script:SwitchBatchState(bInBatch)
    end
end

function UIWidgetVoiceChatContentView:RemoveRecommendRoomList()
    -- UIScrollList 自动管理 Cell 回收，无需手动 Recycle
    self.tbRecommendRoomNode = {}
    self.tbRecommendRoomList = nil
end

function UIWidgetVoiceChatContentView:GetRecommendRoomList()
    local tbList
    if self.nPage == PAGE_TYPE.Recommend then
        tbList = RoomVoiceData.GetTopPopularityVoiceRoom()
    elseif self.nPage == PAGE_TYPE.LiveStream then
        tbList = RoomVoiceData.GetTopPopularityLiveStream()
    else
        tbList = RoomVoiceData.GetLikeList()
    end

    -- 推荐/直播榜单筛选
    if (self.nPage == PAGE_TYPE.Recommend or self.nPage == PAGE_TYPE.Like or self.nPage == PAGE_TYPE.LiveStream) and (self.bFilterFuwuqi or self.bFilterEnter or self.tbFilterMapIDs) then
        local tbFilterList = {}
        for _, szRoomID in ipairs(tbList) do
            local tbInfo = RoomVoiceData.GetVoiceRoomInfo(szRoomID)
            if tbInfo and not table.is_empty(tbInfo) then
                local bShow = true
                local bIsFreeze = (tbInfo.nFreezeTime - GetCurrentTime()) > 0
                bShow = not bIsFreeze -- 冻结中的房间不显示

                local tMaster = RoomVoiceData.GetVoiceRoomMemberSocialInfo(tbInfo.szMasterID)
                if bShow and self.bFilterFuwuqi then
                    local nMyCenterID = UI_GetClientPlayerCenterID()
                    local nMasterCenterID = tMaster and tMaster.dwCenterID or 0
                    bShow = bShow and (nMyCenterID == nMasterCenterID)
                end
                if bShow and self.bFilterEnter then
                    local nMyCamp = GetClientPlayer().nCamp
                    local bCanEnter = GetNumberBit(tbInfo.nCampLimitMask, nMyCamp + 1)
                    bShow = bShow and bCanEnter
                end
                if bShow and self.tbFilterMapIDs then
                    local tLiveInfo = RoomVoiceData.GetLiveStreamInfo(tbInfo.szMasterID)
                    bShow = tLiveInfo and self.tbFilterMapIDs[tLiveInfo.nMapID] or false
                end
                if bShow then
                    table.insert(tbFilterList, szRoomID)
                end
            end
        end
        tbList = tbFilterList
    end

    if self.szSearchID and self.szSearchID ~= "" then--搜索
        tbList = {self.szSearchID}
        local tbInfo = RoomVoiceData.GetVoiceRoomInfo(self.szSearchID)
        RoomVoiceData.ApplyVoiceRoomInfo(self.szSearchID)
        if not tbInfo then
            tbList = {}
        end
    end

    -- 推荐榜单筛选
    if self.nPage == PAGE_TYPE.Recommend then
        local tbFilterList = {}
        for _, szRoomID in ipairs(tbList) do
            local tbInfo = RoomVoiceData.GetVoiceRoomInfo(szRoomID)
            if tbInfo and not table.is_empty(tbInfo) then
                local bShow = true
                local bIsFreeze = (tbInfo.nFreezeTime - GetCurrentTime()) > 0
                bShow = not bIsFreeze -- 冻结中的房间不显示
                if bShow then
                    table.insert(tbFilterList, szRoomID)
                end
            end
        end
        tbList = tbFilterList
    end

    return tbList
end

-- 为推荐/收藏/直播列表中所有房间的主播申请直播信息（用于地图筛选）
function UIWidgetVoiceChatContentView:ApplyLiveStreamInfoForRooms()
    local tbList
    if self.nPage == PAGE_TYPE.Recommend then
        tbList = RoomVoiceData.GetTopPopularityVoiceRoom()
    elseif self.nPage == PAGE_TYPE.LiveStream then
        tbList = RoomVoiceData.GetTopPopularityLiveStream()
    else
        tbList = RoomVoiceData.GetLikeList()
    end
    for _, szRoomID in ipairs(tbList) do
        local tbInfo = RoomVoiceData.GetTopVoiceRoomInfo(szRoomID)
        if tbInfo and tbInfo.szMasterID then
            self.tbPendingLiveStreamMasters[tbInfo.szMasterID] = true
            RoomVoiceData.ApplyLiveStreamInfo(tbInfo.szMasterID)
        end
    end
end

function UIWidgetVoiceChatContentView:UpdateRecommendOrLikeList(bNotToTop)
    self:RemoveRecommendRoomList()
    self:ClearTreeRecommendList()
    self:UpdateTogSiftImg()

    local tbList = self:GetRecommendRoomList()
    local bEmpty = (not tbList or #tbList == 0) and self.nPage ~= PAGE_TYPE.RoomInfo

    UIHelper.SetVisible(self.ScrollViewVoiceChatRoomList, false)
    UIHelper.SetVisible(self.WidgetSearchResultList, false)

    -- LiveStream 页始终按地图分组展示；其他页仅在地图筛选模式下按地图分组
    local bUseTreeView = self.nPage == PAGE_TYPE.LiveStream or (self.tbFilterMapIDs and not bEmpty) and not self.szSearchID
    if bUseTreeView then
        UIHelper.SetVisible(self.WidgetSearchResultList, true)
        self:UpdateTreeRecommendList(tbList)
    else
        UIHelper.SetVisible(self.ScrollViewVoiceChatRoomList, true)
        if not bEmpty then
            self.tbRecommendRoomList = tbList
            self.tRoomScrollList:Reset(#tbList)
        end
    end

    UIHelper.SetVisible(self.WidgetEmpty, bEmpty)
    if bEmpty then
        UIHelper.SetVisible(self.ScrollViewVoiceChatRoomList, false)
        UIHelper.SetVisible(self.WidgetSearchResultList, false)
    end

    local szTip = g_tStrings.VOICE_ROOM_RECOMMEND
    if self.nPage == PAGE_TYPE.Like then
        szTip = g_tStrings.VOICE_ROOM_LIKE
    elseif self.nPage == PAGE_TYPE.LiveStream then
        szTip = g_tStrings.VOICE_ROOM_LIVE_STREAM
    end
    if self.szSearchID and self.szSearchID ~= ""
            or (self.tbFilterMapIDs and not table.is_empty(self.tbFilterMapIDs)) then
        szTip = g_tStrings.VOICE_ROOM_SEARCH
    end
    UIHelper.SetString(self.LabelEmptyDesc, szTip)
end

-- ScrollTree 按地图分组展示房间列表
function UIWidgetVoiceChatContentView:UpdateTreeRecommendList(tbList)
    local scriptScrollViewTree = UIHelper.GetBindScript(self.WidgetSearchResultList)
    if not scriptScrollViewTree then
        return
    end

    -- 按 nMapID 分组
    local tbMapGroups = {}
    local tbMapOrder = {}
    for _, szRoomID in ipairs(tbList) do
        local tbInfo = RoomVoiceData.GetTopVoiceRoomInfo(szRoomID)
        if tbInfo then
            local tLiveInfo = RoomVoiceData.GetLiveStreamInfo(tbInfo.szMasterID)
            local nMapID = tLiveInfo and tLiveInfo.nMapID
            if nMapID and not tbMapGroups[nMapID] then
                tbMapGroups[nMapID] = {}
                table.insert(tbMapOrder, nMapID)
            end
            if nMapID then
                table.insert(tbMapGroups[nMapID], szRoomID)
            end
        end
    end

    -- 构建 SetupScrollViewTree 所需的 tData
    local tData = {}
    for _, nMapID in ipairs(tbMapOrder) do
        local szMapName = "其它"
        if nMapID ~= 0 then
            szMapName = UIHelper.GBKToUTF8(Table_GetMapName(nMapID))
        end
        local nCount = #tbMapGroups[nMapID]
        table.insert(tData, {
            tArgs = {szMapName = szMapName, nCount = nCount},
            tItemList = {},
        })
    end

    UIHelper.SetupScrollViewTree(scriptScrollViewTree, PREFAB_ID.WidgetSearchResultTog, PREFAB_ID.WidgetVoiceRoomListCell,
    function(scriptContainer, tArgs)
        UIHelper.SetString(scriptContainer.LabelTitle, tArgs.szMapName)
        UIHelper.SetString(scriptContainer.LabelSelect, tArgs.szMapName)
        UIHelper.SetString(scriptContainer.LabelNum1, "("..tostring(tArgs.nCount)..")")
        UIHelper.SetString(scriptContainer.LabelNum2, "("..tostring(tArgs.nCount)..")")
    end, tData)

    -- 向各容器填充房间节点
    for i, nMapID in ipairs(tbMapOrder) do
        local tContainerInfo = scriptScrollViewTree.tContainerList[i]
        if tContainerInfo and tContainerInfo.scriptContainer then
            local scriptContainer = tContainerInfo.scriptContainer
            for _, szRoomID in ipairs(tbMapGroups[nMapID]) do
                local node = self.cellVoiceRoomCell:Allocate(scriptContainer.LayoutContent, szRoomID,
                    function(szRoomID, bPwdRequired)
                        self:TryJoinRoom(szRoomID, bPwdRequired)
                    end,
                    PAGE_TYPE.LiveStream -- 直播筛选固定为LiveStream
                )
                table.insert(self.tbRecommendRoomNode, node)
            end
            UIHelper.CascadeDoLayoutDoWidget(scriptContainer._rootNode, true, false)
        end
    end

    scriptScrollViewTree:SetOuterInitSelect()
    UIHelper.ScrollViewDoLayoutAndToTop(scriptScrollViewTree.ScrollViewContent)

    Timer.AddFrame(self, 2, function()
        local scriptContainer = scriptScrollViewTree.tContainerList and scriptScrollViewTree.tContainerList[1] and scriptScrollViewTree.tContainerList[1].scriptContainer
        if scriptContainer then
            UIHelper.SetSelected(scriptContainer.ToggleSelect, true)
        end
    end)
end

-- 清空 ScrollTree 视图
function UIWidgetVoiceChatContentView:ClearTreeRecommendList()
    if self.tbFilterMapIDs or self.nPage == PAGE_TYPE.LiveStream then
        local scriptScrollViewTree = UIHelper.GetBindScript(self.WidgetSearchResultList)
        if scriptScrollViewTree then
            scriptScrollViewTree:ClearContainer()
        end
    end
end

function UIWidgetVoiceChatContentView:RemoveRoomList()
    for nIndex, node in ipairs(self.tbUIRoomList) do
        UIHelper.SetVisible(node, false)
    end
end

function UIWidgetVoiceChatContentView:UpdateLeftRoomList()
    self:RemoveRoomList()
    local nState = RoomVoiceData.GetPlayerRoomState()
    local bHasOwnRoom = RoomVoiceData.HasMyOwnRoom()
    local bHasOtherRoom = nState == RoomVoiceData.PLAYER_VOICE_ROO_STATE.InOtherRoom
    UIHelper.SetVisible(self.tbUIRoomList[1], bHasOwnRoom)
    UIHelper.SetVisible(self.tbUIRoomList[2], bHasOtherRoom)
    UIHelper.SetVisible(self.WidgetCreate, not bHasOwnRoom)

    if bHasOtherRoom then
        UIHelper.SetButtonState(self.BtnCreate, BTN_STATE.Disable, "退出当前房间后才能创建新房间")
    else
        UIHelper.SetButtonState(self.BtnCreate, BTN_STATE.Normal)
    end

    UIHelper.SetVisible(self.ImgAddBg, not bHasOwnRoom)

    UIHelper.LayoutDoLayout(self.LayoutBtnVoiceChatRoom)
    if self.tRoomScrollList then
        self.tRoomScrollList:UpdateListSize()
    end
    self:UpdateLeftRoomName()
    self:UpdateLeftRoomMicAndSpeakState()
end

function UIWidgetVoiceChatContentView:UpdateLeftRoomName()
    local szMyRoomID, szCurRoomID = RoomVoiceData.GetRoleVoiceRoomList()
    local tbMyRoomInfo = RoomVoiceData.GetVoiceRoomInfo(szMyRoomID)
    if tbMyRoomInfo then
        UIHelper.SetString(self.LabelRoomName1, UIHelper.GBKToUTF8(tbMyRoomInfo.szRoomName), 5)
    end

    local tbOtherRoomInfo = RoomVoiceData.GetVoiceRoomInfo(szCurRoomID)
    if tbOtherRoomInfo then
        UIHelper.SetString(self.LabelRoomName2, UIHelper.GBKToUTF8(tbOtherRoomInfo.szRoomName), 5)
    end
end

function UIWidgetVoiceChatContentView:UpdateLeftRoomMicAndSpeakState()
    local szMyRoomID, szCurrentRoomID = RoomVoiceData.GetRoleVoiceRoomList()
    if szMyRoomID ~= '0' then
        UIHelper.SetSpriteFrame(self.ImgVoiveState, VOICE_STATE_IMG[RoomVoiceData.IsSpeakerOpen(szMyRoomID)][2])
        UIHelper.SetSpriteFrame(self.ImgMicState, MIC_STATE_IMG[RoomVoiceData.IsMicOpen(szMyRoomID)][2])
    end

    if szCurrentRoomID ~= '0' then
        UIHelper.SetSpriteFrame(self.ImgVoiveState1, VOICE_STATE_IMG[RoomVoiceData.IsSpeakerOpen(szCurrentRoomID)][2])
        UIHelper.SetSpriteFrame(self.ImgMicState1, MIC_STATE_IMG[RoomVoiceData.IsMicOpen(szCurrentRoomID)][2])
    end
end

--更新房间信息
function UIWidgetVoiceChatContentView:UpdateRoomInfo()
    UIHelper.SetVisible(self.WidgetEmpty, false)
    local script = UIHelper.GetBindScript(self.WidgetCurrentVoiceRoomContent)
    script:OnEnter(self.szCurRoomID)
    self:UpdateLeftRoomMicAndSpeakState()
end

--延迟更新房间信息
function UIWidgetVoiceChatContentView:DelayUpdateRoomInfo()
    self.nUpdateRoomInfoTimer = self.nUpdateRoomInfoTimer or Timer.Add(self, 0.5, function()
        self.nUpdateRoomInfoTimer = nil
        self:UpdateRoomInfo()
    end)
end


function UIWidgetVoiceChatContentView:UpdateSetting()
    local bIsRoomOwner = self.szCurRoomID and RoomVoiceData.IsRoomOwner(self.szCurRoomID, g_pClientPlayer.GetGlobalID())
    UIHelper.SetVisible(self.WidgetWisperSetting, self.nPage == PAGE_TYPE.RoomInfo)
    UIHelper.SetVisible(self.BtnQuitRoom, true)

    UIHelper.SetVisible(self.BtnEditRoom, bIsRoomOwner)
    UIHelper.SetVisible(self.BtnGift, not bIsRoomOwner)
    UIHelper.SetVisible(self.TogManage, bIsRoomOwner)

    UIHelper.SetButtonState(self.TogSift, self.nPage == PAGE_TYPE.Recommend and BTN_STATE.Disable or BTN_STATE.Normal)

    -- 观战按钮显示逻辑
    local bShowGoLive = false
    if self.szCurRoomID and not bIsRoomOwner then
        local tbRoomInfo = RoomVoiceData.GetVoiceRoomInfo(self.szCurRoomID)
        if tbRoomInfo and tbRoomInfo.szMasterID then
            bShowGoLive = RoomVoiceData.IsLiveStreamActive(tbRoomInfo.szMasterID)
        end
    end
    -- 观战按钮显示逻辑
    if self.szCurRoomID then
        local tbRoomInfo = RoomVoiceData.GetVoiceRoomInfo(self.szCurRoomID)
        if tbRoomInfo and tbRoomInfo.szMasterID then
            local bIsLiving = RoomVoiceData.IsLiveStreamActive(tbRoomInfo.szMasterID)

            if bIsRoomOwner then
                -- 房主视角：显示创建直播按钮
                if bIsLiving then
                    UIHelper.SetSpriteFrame(self.ImgGoLive, "UIAtlas2_VoiceRoom_VoiceRoom1_Icon_guanzhan")
                    UIHelper.SetString(self.LabelGoLive, "直播")
                else
                    UIHelper.SetSpriteFrame(self.ImgGoLive, "UIAtlas2_VoiceRoom_VoiceRoom1_Icon_guanzhan")
                    UIHelper.SetString(self.LabelGoLive, "直播")
                end
            else
                -- 非房主视角：显示观战按钮
                local tLiveInfo = RoomVoiceData.GetLiveStreamInfo(tbRoomInfo.szMasterID)
                if tLiveInfo and tLiveInfo.bInLiveMap then
                    UIHelper.SetSpriteFrame(self.ImgGoLive, "UIAtlas2_VoiceRoom_VoiceRoom1_Icon_guanzhan")
                    UIHelper.SetString(self.LabelGoLive, "观战")
                else
                    bShowGoLive = false
                end
            end
        end
    end
    UIHelper.SetVisible(self.BtnGoLive, bShowGoLive or bIsRoomOwner)

    --批量操作等功能不开放
    UIHelper.SetVisible(self.BtnBatchManage, false)
    UIHelper.SetVisible(self.BtnMuteAll, false)
    UIHelper.SetVisible(self.BtnKickAll, false)
    UIHelper.SetVisible(self.BtnSearch, bIsRoomOwner or RoomVoiceData.IsAdmin(self.szCurRoomID, g_pClientPlayer.GetGlobalID()))


    UIHelper.SetSelected(self.TogManage, false, false)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
    UIHelper.LayoutDoLayout(self.LayoutMenu)

    if self.szCurRoomID and self.nPage == PAGE_TYPE.RoomInfo then
        local tbInfo = RoomVoiceData.GetVoiceRoomInfo(self.szCurRoomID)
        if not tbInfo then return end
        UIHelper.SetString(self.LableLevelUp, tbInfo.nRoomLevel == 0 and "固化" or "升级")
        UIHelper.SetVisible(self.BtnLevelUp, tbInfo.nRoomLevel == 0)
        UIHelper.SetVisible(self.BtnSwitched, bIsRoomOwner)
        UIHelper.SetVisible(self.WidgetSwitchBtn, bIsRoomOwner)
        UIHelper.LayoutDoLayout(self.LayoutMenuBtn)
    end
end

function UIWidgetVoiceChatContentView:UpdateTipHint(szGlobalID, szTargetGlobalID, nGold, nNum)
    if not szGlobalID or not szTargetGlobalID or not nGold or not nNum then
        return
    end

    self.tbDalayShowTips = self.tbDalayShowTips or {}
    table.insert(self.tbDalayShowTips, {szGlobalID, szTargetGlobalID, nNum, nGold})

    -- 如果当前没有正在播放的提示，立即开始播放
    if not self.bIsShowingTip then
        self:ProcessNextTip()
    end
end

function UIWidgetVoiceChatContentView:ProcessNextTip()
    if not self.tbDalayShowTips or #self.tbDalayShowTips == 0 then
        self.bIsShowingTip = false
        UIHelper.SetVisible(self.WidgeGiftHint, false)
        UIHelper.SetVisible(self.GiftSFX, false)
        return
    end

    self.bIsShowingTip = true
    local tipData = table.remove(self.tbDalayShowTips, 1)
    local szPlayer1, szPlayer2, nNum, nGold = tipData[1], tipData[2], tipData[3], tipData[4]

    local function ShowTip(szPlayer1, szPlayer2, nGold, nNum)
        local tItem = nil
        local szMyRoomID, szCurrentRoomID = RoomVoiceData.GetRoleVoiceRoomList()
        local tTipItemList = Table_GetTipItemList()
        for _, tTipItem in pairs(tTipItemList) do
            if tTipItem.nGoldNum == nGold then
                tItem = tTipItem
                break
            end
        end

        if not tItem then
            self.bIsShowingTip = false
            self:ProcessNextTip()
            return
        end

        local szGiftName = string.format(g_tStrings.STR_TIPS_GIFT_NAME, UIHelper.GBKToUTF8(tItem.szName), nNum)
        local szSFXPath = (tItem.nUpNum and tItem.nUpNum <= nNum) and tItem.szUpSfxPath or tItem.szSfxPath
        UIHelper.SetVisible(self.WidgeGiftHint, true)
        UIHelper.SetVisible(self.GiftSFX, true)

        UIHelper.SetString(self.LabelGiftName, szGiftName)
        UIHelper.SetSFXPath(self.GiftSFX, szSFXPath, 0)
        UIHelper.PlaySFX(self.GiftSFX, 0)
        UIHelper.UpdateMask(self.MsdkGiftSFX)

        if szPlayer1 and szPlayer2 then
            UIHelper.RemoveAllChildren(self.WidgetRoomPlayerSend)
            UIHelper.RemoveAllChildren(self.WidgetRoomPlayerreceive)
            local scriptSend = UIHelper.AddPrefab(PREFAB_ID.WidgetRoomPlayerCell, self.WidgetRoomPlayerSend, szCurrentRoomID, {szGlobalID = szPlayer1})
            local scriptReceive = UIHelper.AddPrefab(PREFAB_ID.WidgetRoomPlayerCell, self.WidgetRoomPlayerreceive, szCurrentRoomID, {szGlobalID = szPlayer2})
        end

        UIHelper.StopAni(self, self.WidgeGiftHint, "AniGiftHintShow")
        UIHelper.PlayAni(self, self.WidgeGiftHint, "AniGiftHintShow")

        Timer.Add(self, tItem.nShowTime / 1000 or 2, function()
            UIHelper.SetVisible(self.WidgeGiftHint, false)
            -- UIHelper.SetVisible(self.GiftSFX, false)

            self.bIsShowingTip = false
            self:ProcessNextTip()
        end)
    end

    ShowTip(szPlayer1, szPlayer2, nGold, nNum)
end

function UIWidgetVoiceChatContentView:UpdateBtnBeepSwitch()
    local bIsMemberJoinBeep = RoomVoiceData.IsMemberJoinBeep()
    UIHelper.SetString(self.LabelBeepSwitch, bIsMemberJoinBeep and "关闭提示音" or "开启提示音")
end

function UIWidgetVoiceChatContentView:UpdateTogSiftImg()
    if self.tbFilterMapIDs and not table.is_empty(self.tbFilterMapIDs) then
        UIHelper.SetSpriteFrame(self.ImgInfoIcon, "UIAtlas2_Public_PublicButton_PublicButton1_icon_screen_ing")
    else
        UIHelper.SetSpriteFrame(self.ImgInfoIcon, "UIAtlas2_Public_PublicButton_PublicButton1_icon_screen")
    end
end

return UIWidgetVoiceChatContentView
