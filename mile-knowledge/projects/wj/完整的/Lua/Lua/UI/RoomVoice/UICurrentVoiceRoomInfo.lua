-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICurrentVoiceRoomInfo
-- Date: 2025-09-15 15:27:27
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICurrentVoiceRoomInfo = class("UICurrentVoiceRoomInfo")
local tbVoiceRoomBgList = {
    ["ui/Image/GiftImage/DefaultBg.tga"] = "UIAtlas2_VoiceRoom_VoiceRoomBg_img_linshi_bg",
    ["ui/Image/GiftImage/FixBg.tga"] = "UIAtlas2_VoiceRoom_VoiceRoomBg_img_yongjiu_bg",
    ["ui/Image/GiftImage/NormalBg.tga"] = "UIAtlas2_VoiceRoom_VoiceRoomBg_img_chaoji_bg"
}

function UICurrentVoiceRoomInfo:OnEnter(szRoomID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:Init()
    self:SetCurrentRoomID(szRoomID)

    Timer.Add(self, 0.5, function()
        RoomVoiceData.ApplyVoiceRoomInfo(szRoomID)
        RoomVoiceData.ApplyVoiceRoomMemberList(szRoomID)

        -- 申请直播流信息
        local tbRoomInfo = RoomVoiceData.GetVoiceRoomInfo(szRoomID)
        if tbRoomInfo and tbRoomInfo.szMasterID then
            RoomVoiceData.ApplyLiveStreamInfo(tbRoomInfo.szMasterID)
        end
    end)
end

function UICurrentVoiceRoomInfo:OnExit()
    self.bInit = false
    self:UnRegEvent()
    if self.scrollList then
		self.scrollList:Destroy()
		self.scrollList = nil
	end
end

function UICurrentVoiceRoomInfo:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        self:SwitchBatchState(false)
        RoomVoiceData.ClearOperateList()
    end)

    UIHelper.BindUIEvent(self.BtnComfirm, EventType.OnClick, function()
        RoomVoiceData.ConfirmOperate(self.szCurRoomID, function()
            self:SwitchBatchState(false)
        end)
    end)

    UIHelper.BindUIEvent(self.BtnMic, EventType.OnClick, function()
        if not RoomVoiceData.CanOperateMic(self.szCurRoomID) then
            TipsHelper.ShowNormalTip("你无权操作麦克风")
            return
        end
        if RoomVoiceData.IsMicOpen(self.szCurRoomID) then
            RoomVoiceData.CloseMic(self.szCurRoomID)
        else
            RoomVoiceData.OpenMic(self.szCurRoomID)
        end
    end)

    UIHelper.BindUIEvent(self.BtnVoice, EventType.OnClick, function()
        if RoomVoiceData.IsSpeakerOpen(self.szCurRoomID) then
            RoomVoiceData.CloseSpeaker(self.szCurRoomID)
        else
            RoomVoiceData.OpenSpeaker(self.szCurRoomID)
        end
    end)

    UIHelper.BindUIEvent(self.BtnDetail, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PaneVoiceRoomChatRecordPop, self.szCurRoomID)
    end)

    UIHelper.BindUIEvent(self.BtnRecord, EventType.OnClick, function()
        SetClipboard(self.szCurRoomID)
        TipsHelper.ShowNormalTip("复制成功")
    end)

    UIHelper.BindUIEvent(self.TogLike, EventType.OnSelectChanged, function(_, bSelect)
        local szRoomID = self.szCurRoomID
        if bSelect then
            RoomVoiceData.AddLike(szRoomID)
        else
            RoomVoiceData.DelLikeRoom(szRoomID)
        end
    end)

    UIHelper.BindUIEvent(self.BtnAddVip, EventType.OnClick, function()
        local tbInfo = RoomVoiceData.GetVoiceRoomInfo(self.szCurRoomID)
        if tbInfo then
            UIMgr.Open(VIEW_ID.PanelAddVipTimePop, tbInfo.nSuperRoomTime)
        else
            LOG.INFO("Didn't Find RoomInfo, szRoomID:%s", self.szCurRoomID)
        end
    end)

    UIHelper.BindUIEvent(self.LayoutVip, EventType.OnClick, function()
        local tbInfo = RoomVoiceData.GetVoiceRoomInfo(self.szCurRoomID)
        if tbInfo then
            UIMgr.Open(VIEW_ID.PanelAddVipTimePop, tbInfo.nSuperRoomTime)
        else
            LOG.INFO("Didn't Find RoomInfo, szRoomID:%s", self.szCurRoomID)
        end
    end)
end

function UICurrentVoiceRoomInfo:RegEvent()

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        Timer.AddFrame(self, 1, function()
            self:UpdateInfo()
        end)
    end)

    Event.Reg(self, EventType.OnOperateListChange, function()
        self:UpdateManage()
    end)

    Event.Reg(self, EventType.ON_VOICE_ROOM_RECORD_UPDATE, function(tbInfo)
        self:UpdateRecord(tbInfo)
    end)

    Event.Reg(self, EventType.OnGMEMicStateChanged, function()
        self:UpdateSelfMicAndVoiceInfo()
    end)

    Event.Reg(self, EventType.OnGMESpeakerStateChanged, function()
        self:UpdateSelfMicAndVoiceInfo()
    end)

    Event.Reg(self, EventType.ON_SYNC_VOICE_ROOM_INFO, function(szRoomID, bRoomExist)
        if self.szCurRoomID == szRoomID and self:IsShow() and bRoomExist then
            self:UpdateRoomMicMode()
            self:UpdateSelfMicAndVoiceInfo()
            self:DelayUpdateMemberList()
        end
    end)

    Event.Reg(self, EventType.ON_LIVE_STREAM_INFO_UPDATE, function()
        self.nUpdateAudienceTimer = self.nUpdateAudienceTimer or Timer.Add(self, 1, function()
            self.nUpdateAudienceTimer = nil
            if self:IsShow() then
                self:UpdateAudienceArea()
            end
        end)
    end)

    Event.Reg(self, "SYNC_VOICE_ROOM_MEMBER_LIST", function(szRoomID)
        if self.szCurRoomID == szRoomID and self:IsShow() then
            self:UpdateRoomMemberListData()
            self:DelayUpdateMemberList()
        end
    end)

    Event.Reg(self, "TIP_IN_VOICE_ROOM_NOTIFY", function(szGlobalID, szTargetGlobalID, nGold, nNum)
        if self.nUpdateBaseByTip then -- 用于更新打赏热度
            return
        end

        if self.szCurRoomID and self:IsShow() then
            RoomVoiceData.ApplyVoiceRoomInfo(self.szCurRoomID)
            self.nUpdateBaseByTip = Timer.Add(self, 0.5, function()
                self:UpdateBaseInfo()
                self.nUpdateBaseByTip = nil
            end)
        end
    end)

    Event.Reg(self, EventType.ON_SYNC_VOICE_PERMISSION_INFO, function(tbEnableMic, tbAdmin, szRoomID)
        if self.szCurRoomID == szRoomID and self:IsShow() then
            self:UpdateRoomMemberListData()
            self:DelayUpdateMemberList()
            self:UpdateSelfMicAndVoiceInfo()
        end
    end)

    Event.Reg(self, EventType.OnMemberMicStateChanged, function(szRoomID, szMemberID, bOpen)
        if self.szCurRoomID == szRoomID and self:IsShow() then
            self:UpdateRoomMemberListData()
            self:DelayUpdateMemberList()
            self:UpdateSelfMicAndVoiceInfo()
        end
    end)
end

function UICurrentVoiceRoomInfo:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end



function UICurrentVoiceRoomInfo:Init()
    UIHelper.SetSwallowTouches(self.ScrollViewRoomChatRecord, false)

    self.scrollList = self.scrollList or UIScrollList.Create({
        listNode = self.LayoutRoomPlayerList,
        nSpace = 0,
        fnGetCellType = function(nIndex)
            -- local nCount = #self.tbEnableMic
            -- if nIndex == nCount + 1 then
            --     --加载横线
            --     return PREFAB_ID.WidgetLine
            -- else
                return PREFAB_ID.WidgetMicPlayerCellGroup
            -- end
        end,
        fnUpdateCell = function(cell, nIndex)
            self:OnUpdateMemberListCell(cell, nIndex)
        end,
    })
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICurrentVoiceRoomInfo:DelayUpdateMemberList()
    if self.nUdMemberTimer ~= nil then
        Timer.DelTimer(self, self.nUdMemberTimer)
        self.nUdMemberTimer = nil
    end
    self.nUdMemberTimer = Timer.AddFrame(self, 2, function()
        self:UpdateMemberList()
    end)
end

function UICurrentVoiceRoomInfo:UpdateInfo()
    self:UpdateRecord()
    self:UpdateBaseInfo()
    self:DelayUpdateMemberList()
    self:UpdateRoomMicMode()
    self:UpdateSelfMicAndVoiceInfo()
    self:SwitchBatchState(false)
end

function UICurrentVoiceRoomInfo:RemoveRecord()
    if self.tbRoomRecord then
        for nIndex, tbInfo in ipairs(self.tbRoomRecord) do
            UIHelper.RemoveFromParent(tbInfo.node, self.ScrollViewRoomChatRecord)
        end
    end
    self.tbRoomRecord = {}
end

function UICurrentVoiceRoomInfo:UpdateRecord()
    local tbRecord = RoomVoiceData.GetRecord(self.szCurRoomID)
    self.tbRoomRecord = self.tbRoomRecord or {}
    UIHelper.HideAllChildren(self.ScrollViewRoomChatRecord)
    if not tbRecord then
        return
    end

    local tbGlobalIDList = {}
    local tbCheckedIDs = {} -- 用于去重
    for index, info in ipairs(tbRecord) do
        local script = self.tbRoomRecord[index] and self.tbRoomRecord[index].script
        local node = self.tbRoomRecord[index] and self.tbRoomRecord[index].node
        if not script then
            script = UIHelper.AddPrefab(PREFAB_ID.WidgetRoomChatRecordCell, self.ScrollViewRoomChatRecord, info, UIHelper.GetWidth(self.ScrollViewRoomChatRecord) - 40)
            node = script._rootNode
            table.insert(self.tbRoomRecord, {node = node, script = script})
        end

        script:OnEnter(info, UIHelper.GetWidth(self.ScrollViewRoomChatRecord) - 40)
        UIHelper.SetVisible(node, true)
        local szGlobalID = info.szGlobalID
        if szGlobalID and szGlobalID ~= "0" and not tbCheckedIDs[szGlobalID] then
            local tbRoleEntryInfo = RoomVoiceData.GetVoiceRoomMemberSocialInfo(szGlobalID)
            if not tbRoleEntryInfo then
                table.insert(tbGlobalIDList, szGlobalID)
                tbCheckedIDs[szGlobalID] = true -- 标记已检查
            end
        end
    end
    if #tbGlobalIDList > 0 then
        RoomVoiceData.ApplyVoiceMemberSocialInfo(tbGlobalIDList)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewRoomChatRecord)

    Timer.DelTimer(self, self.nUpdateScrollToBottomTimerID)
    self.nUpdateScrollToBottomTimerID = Timer.AddFrame(self, 1, function()
        UIHelper.ScrollToBottom(self.ScrollViewRoomChatRecord)
    end)
end

function UICurrentVoiceRoomInfo:AddRecord(tbInfo)
    if not tbInfo then
        return
    end

    if not self.tbRoomRecord then self.tbRoomRecord = {} end
    if tbInfo and table.GetCount(tbInfo) > 1 then
        tbInfo = {tbInfo[#tbInfo]}
    end
    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetRoomChatRecordCell, self.ScrollViewRoomChatRecord, tbInfo, UIHelper.GetWidth(self.ScrollViewRoomChatRecord) - 40)
    local node = script._rootNode
    table.insert(self.tbRoomRecord, {node = node, script = script})
    UIHelper.ScrollViewDoLayout(self.ScrollViewRoomChatRecord)

    Timer.DelTimer(self, self.nAddScrollToBottomTimerID)
    self.nAddScrollToBottomTimerID = Timer.AddFrame(self, 1, function()
        UIHelper.ScrollToBottom(self.ScrollViewRoomChatRecord)
    end)

    local tbRoleEntryInfo = RoomVoiceData.GetVoiceRoomMemberSocialInfo(tbInfo.szGlobalID)
    if not tbRoleEntryInfo and tbInfo.szGlobalID ~= "0" then
        RoomVoiceData.ApplyVoiceMemberSocialInfo({tbInfo.szGlobalID})
    end
end

---------------------------------------------成员列表 Start-------------------------------

function UICurrentVoiceRoomInfo:OnUpdateMemberListCell(cell, nIndex)
    -- local nCount = #self.tbEnableMic
    local tbMemList = self.tbRoomMemberList[nIndex]
    -- if nIndex <= nCount then
    --     tbMemList = self.tbEnableMic[nIndex]
    -- elseif nIndex > nCount and nIndex ~= nCount + 1 then
    --     tbMemList = self.tbUnEnableMic[nIndex - nCount - 1]
    -- end
    if tbMemList then
        cell:InitInfo(self.szCurRoomID, tbMemList, self.bInBatch, function(tbMenuConfig, tbRoleInfo, node, szGlobalID, tFromRoom)
            local tips, script = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPlayerPop, node, szGlobalID, tbMenuConfig, tbRoleInfo, false, false, tFromRoom)
        end)
    end
end

function UICurrentVoiceRoomInfo:UpdateMemberList()
    self.LayoutRoomPlayerList:setClippingEnabled(true, true)
    local nMinIndex, nMaxIndex = self.scrollList:GetIndexRangeOfLoadedCells()
    self.scrollList:ReloadWithStartIndex(#self.tbRoomMemberList, nMinIndex) --刷新数量
    self.scrollList:UpdateListSize()
    self.scrollList:UpdateContentPos()

    self:UpdateBaseInfo()
end
---------------------------------------------成员列表 End----------------------------

function UICurrentVoiceRoomInfo:UpdateBaseInfo()
    UIHelper.SetVisible(self.ImgCamp, false)
    UIHelper.SetVisible(self.ImgJinZhi, false)
    local szRoomID = self.szCurRoomID
    local tbInfo = RoomVoiceData.GetVoiceRoomInfo(szRoomID)
    if not tbInfo then
        return
    end
    self:UpdateCamp(tbInfo.nCampLimitMask)

    local nMemeberCount = self.nMemberCount--RoomVoiceData.GetVoiceRoomMemberCount(szRoomID, true) or 0
    local bRoomOwner = RoomVoiceData.IsRoomOwner(szRoomID, g_pClientPlayer.GetGlobalID())
    UIHelper.SetSelected(self.TogLike, RoomVoiceData.IsLikeRoom(szRoomID), false)
    UIHelper.SetTouchEnabled(self.TogLike, not (tbInfo.nRoomLevel == 0))
    UIHelper.SetNodeGray(self.TogLike, tbInfo.nRoomLevel == 0)
    UIHelper.SetVisible(self.TogLike, not (tbInfo.nRoomLevel == 0))

    UIHelper.SetString(self.LabelRoomName, UIHelper.GBKToUTF8(tbInfo.szRoomName))
    UIHelper.SetString(self.LabelRoomID, "ID:" .. UIHelper.GBKToUTF8(szRoomID))
    UIHelper.SetString(self.LabelRoomPlayerNum, nMemeberCount .. "/" .. RoomVoiceData.GetMaxPeopleNum(szRoomID))
    UIHelper.SetVisible(self.ImgUnpublic, tbInfo.bPwdRequired)
    UIHelper.SetString(self.LableVip, tbInfo.nRoomLevel .. "级")
    UIHelper.SetVisible(self.WidgetLinShi, tbInfo.nRoomLevel == 0)
    UIHelper.SetVisible(self.LayoutLevel, tbInfo.nRoomLevel >= 1 )
    UIHelper.SetString(self.LabelRoomHot, tbInfo.dwPopularity)
    local szImg = RoomVoiceData.GetHotRankImg(tbInfo.dwPopularity)
    if szImg then
        UIHelper.SetSpriteFrame(self.ImgHot, szImg)
    end

    local nRemainTime = math.max(0, tbInfo.nSuperRoomTime - GetCurrentTime())
    local szText = nRemainTime > 0 and TimeLib.GetTimeText(nRemainTime, false, true) or "未开启"
    UIHelper.SetVisible(self.LayoutVip, tbInfo.nRoomLevel >= 1 and bRoomOwner and nRemainTime > 0)
    UIHelper.SetVisible(self.BtnAddVip, tbInfo.nRoomLevel >= 1 and bRoomOwner and nRemainTime <= 0)
    UIHelper.SetVisible(self.ImgVip2, tbInfo.nRoomLevel >= 1 and not bRoomOwner and nRemainTime > 0)
    UIHelper.SetString(self.LableVIPDay, szText)

    UIHelper.SetVisible(self.ImgVip2, tbInfo.nRoomLevel > 0 and nRemainTime > 0 and not bRoomOwner)

    local tPath = RoomVoiceData.GetRoomSkinPath(tbInfo.nRoomLevel, nRemainTime)
    local szPath = tPath and tbVoiceRoomBgList[tPath.szRoomPath] or "UIAtlas2_VoiceRoom_VoiceRoomBg_img_linshi_bg"
    UIHelper.SetSpriteFrame(self.ImgBg1, szPath)

    self:UpdateAudienceArea()

    UIHelper.LayoutDoLayout(self.LayoutRoomHot)
    UIHelper.LayoutDoLayout(self.LayoutLevel)
    UIHelper.LayoutDoLayout(self.LayoutRoomNameVip)
    UIHelper.LayoutDoLayout(self.LayoutRoomPlayerNum)
    UIHelper.LayoutDoLayout(self.LayoutRoomID)
end

--语音模式
function UICurrentVoiceRoomInfo:UpdateRoomMicMode()
    local szRoomID = self.szCurRoomID
    local tbInfo = RoomVoiceData.GetVoiceRoomInfo(szRoomID)
    if not tbInfo then return end
    UIHelper.SetString(self.LabelMicMode, VOICE_ROOM_MIC_MODE_LIST[tbInfo.nMicMode])
    UIHelper.LayoutDoLayout(self.LayoutRoomMicMode)
end

--麦和声音状态
function UICurrentVoiceRoomInfo:UpdateSelfMicAndVoiceInfo()
    UIHelper.SetSpriteFrame(self.ImgVoice, VOICE_STATE_IMG[RoomVoiceData.IsSpeakerOpen(self.szCurRoomID)][1])
    UIHelper.SetSpriteFrame(self.ImgMic, MIC_STATE_IMG[RoomVoiceData.IsMicOpen(self.szCurRoomID)][1])

    UIHelper.SetString(self.LableVoiceState, RoomVoiceData.IsSpeakerOpen(self.szCurRoomID) and "声音" or "静音")
    UIHelper.SetString(self.LableMicState, RoomVoiceData.IsMicOpen(self.szCurRoomID) and "自由" or "闭麦")

    local nState = RoomVoiceData.CanOperateMic(self.szCurRoomID) and BTN_STATE.Normal or BTN_STATE.Disable
    UIHelper.SetButtonState(self.BtnMic, nState)
end

function UICurrentVoiceRoomInfo:UpdateManage()
    local nMaxCount = math.max(RoomVoiceData.GetCanOperateListCount(self.szCurRoomID), 0)--暂定除了房主和主管都可以被选
    local nCount = RoomVoiceData.GetOperateListCount()
    UIHelper.SetString(self.LabelSelectedNum, string.format("（%s/%s）", nCount, nMaxCount))
    UIHelper.LayoutDoLayout(self.LayoutLabelSelected)
end

function UICurrentVoiceRoomInfo:SwitchBatchState(bInBatch)
    self.bInBatch = bInBatch
    self.tbSelectedMemberList = {}

    UIHelper.SetVisible(self.TogAllSelect, false)
    UIHelper.SetVisible(self.WidgetManage, bInBatch)
    if bInBatch then
        self:UpdateManage()
    end
    self:UpdateMemberList()
end


function UICurrentVoiceRoomInfo:SetCurrentRoomID(szRoomID)
    self.szCurRoomID = szRoomID
    self:UpdateRoomMemberListData()
    self:UpdateInfo()
end

function UICurrentVoiceRoomInfo:SplitMemberListData(tbMemberList)
    local tbRes = {}
    for nIndex = 1, #tbMemberList, 4 do
        local tbMemList = {}
        for index = nIndex, nIndex + 3 do
            local tbMember = tbMemberList[index]
            if tbMember then
                table.insert(tbMemList, tbMember)
            end
        end
        table.insert(tbRes, tbMemList)
    end
    return tbRes
end

function UICurrentVoiceRoomInfo:UpdateRoomMemberListData()
    -- 一次性获取成员列表和房间信息
    self.tbRoomMemberList = RoomVoiceData.GetVoiceRoomMemberList(self.szCurRoomID) or {}
    self.nMemberCount = 0

    -- 收集需要获取社交信息的成员ID
    local tbGlobalIDList = {}
    local tbCheckedIDs = {} -- 用于去重

    for _, tbMember in ipairs(self.tbRoomMemberList) do
        local szGlobalID = tbMember.szGlobalID
        if szGlobalID and szGlobalID ~= "0" and not tbCheckedIDs[szGlobalID] then
            local tbRoleEntryInfo = RoomVoiceData.GetVoiceRoomMemberSocialInfo(szGlobalID)
            if not tbRoleEntryInfo then
                table.insert(tbGlobalIDList, szGlobalID)
                tbCheckedIDs[szGlobalID] = true -- 标记已检查
            end
        end

        local bOnline = tbMember.bNotOnline == nil or tbMember.bNotOnline == false
        if bOnline then
            self.nMemberCount = self.nMemberCount + 1
        end
    end

    -- 批量申请社交信息
    if #tbGlobalIDList > 0 then
        RoomVoiceData.ApplyVoiceMemberSocialInfo(tbGlobalIDList)
    end

    self.tbRoomMemberList = self:SplitMemberListData(self.tbRoomMemberList)
    -- self.tbUnEnableMic = self:SplitMemberListData(self.tbUnEnableMic)
    -- self.tbEnableMic = self:SplitMemberListData(self.tbEnableMic)
end

function UICurrentVoiceRoomInfo:UpdateAudienceArea()
    local tbInfo = RoomVoiceData.GetVoiceRoomInfo(self.szCurRoomID)
    if not tbInfo then
        return
    end
    local tLiveInfo = tbInfo.szMasterID and RoomVoiceData.GetLiveStreamInfo(tbInfo.szMasterID)
    local bIsLiving = tLiveInfo and tLiveInfo.nMapID and tLiveInfo.nMapID ~= 0
    UIHelper.SetVisible(self.ImgAudience, bIsLiving)
    UIHelper.SetVisible(self.ImgemptyAudience, bIsLiving)
    UIHelper.SetVisible(self.LabelAudienceNum, bIsLiving)
    if bIsLiving then
        if tLiveInfo.bInLiveMap then
            -- local nAudienceNum = RoomVoiceData.GetLiveAudienceCount()
            UIHelper.SetString(self.LabelAudienceNum, "")
            UIHelper.SetVisible(self.LabelAudienceNum, false)
        else
            UIHelper.SetString(self.LabelAudienceNum, "待前往")
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutRoomPlayerNum)
end

function UICurrentVoiceRoomInfo:IsShow()
    return UIHelper.GetVisible(self._rootNode)
end

function UICurrentVoiceRoomInfo:UpdateCamp(nCampLimitMask)
    local bNeutralCanJoin, bGoodCanJoin, bEvilCanJoin = RoomVoiceData.CheckRoomCampLimitMask(nCampLimitMask)
    UIHelper.SetVisible(self.ImgCamp, bNeutralCanJoin and bGoodCanJoin and bEvilCanJoin)
    UIHelper.SetVisible(self.ImgJinZhi, not bNeutralCanJoin and not bGoodCanJoin and not bEvilCanJoin)

    if bNeutralCanJoin and bGoodCanJoin and not bEvilCanJoin then -- 中浩
        UIHelper.SetVisible(self.ImgCamp, true)
        UIHelper.SetSpriteFrame(self.ImgCamp, "UIAtlas2_Public_PublicSchool_PublicSchool_img_haoqimeng")
    elseif not bNeutralCanJoin and bGoodCanJoin and not bEvilCanJoin then -- 浩
        UIHelper.SetVisible(self.ImgCamp, true)
        UIHelper.SetSpriteFrame(self.ImgCamp, "UIAtlas2_Public_PublicSchool_PublicSchool_img_haoqimeng")
    elseif bNeutralCanJoin and not bGoodCanJoin and bEvilCanJoin then -- 中恶
        UIHelper.SetVisible(self.ImgCamp, true)
        UIHelper.SetSpriteFrame(self.ImgCamp, "UIAtlas2_Public_PublicSchool_PublicSchool_img_erengu")
    elseif not bNeutralCanJoin and not bGoodCanJoin and bEvilCanJoin then -- 恶
        UIHelper.SetVisible(self.ImgCamp, true)
        UIHelper.SetSpriteFrame(self.ImgCamp, "UIAtlas2_Public_PublicSchool_PublicSchool_img_erengu")
    elseif bNeutralCanJoin and not bGoodCanJoin and not bEvilCanJoin then -- 中
        UIHelper.SetVisible(self.ImgCamp, true)
        UIHelper.SetSpriteFrame(self.ImgCamp, "UIAtlas2_Public_PublicSchool_PublicSchool_img_zhongli")
    else
        UIHelper.SetVisible(self.ImgCamp, false)
    end
end

return UICurrentVoiceRoomInfo