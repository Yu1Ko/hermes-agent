-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetVoiceRoomListCell
-- Date: 2025-05-22 15:27:00
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetVoiceRoomListCell = class("UIWidgetVoiceRoomListCell")
local tbVoiceRoomBgList = {
    ["ui/Image/GiftImage/DefaultBgS.tga"] = "UIAtlas2_VoiceRoom_VoiceRoomBg_img_linshi_cell",
    ["ui/Image/GiftImage/FixBgS.tga"] = "UIAtlas2_VoiceRoom_VoiceRoomBg_img_yongjiu_cell",
    ["ui/Image/GiftImage/NormalBgS.tga"] = "UIAtlas2_VoiceRoom_VoiceRoomBg_img_chaoji_cell"
}

local PAGE_TYPE = {
    Recommend = 1,
    Like = 2,
    LiveStream = 4,
}

function UIWidgetVoiceRoomListCell:OnEnter(szRoomID, fnAction, nPage)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bClickRoom = false
    self.szRoomID = szRoomID
    self.fnAction = fnAction
    self.nPage = nPage or PAGE_TYPE.Recommend
    if self.nPage ~= PAGE_TYPE.Recommend then -- 推荐房间的信息在RoomVoiceData.tbRecommendData中
        RoomVoiceData.ApplyVoiceRoomInfo(self.szRoomID)
    end

    -- 申请直播流信息
    local tbInfo = RoomVoiceData.GetVoiceRoomInfo(self.szRoomID)
    if tbInfo and tbInfo.szMasterID then
        RoomVoiceData.ApplyLiveStreamInfo(tbInfo.szMasterID)
    end

    self:UpdateInfo()
end

function UIWidgetVoiceRoomListCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIWidgetVoiceRoomListCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnVoiceRoomListCell, EventType.OnClick, function()
        self:OnClickCell()
    end)

    UIHelper.BindUIEvent(self.BtnTopView, EventType.OnClick, function()
        self:OnClickTopView()
    end)

    UIHelper.BindUIEvent(self.TogLike, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            RoomVoiceData.AddLike(self.szRoomID)
        else
            UIHelper.ShowConfirm("你是否要取消收藏该语音聊天室？", function()
                RoomVoiceData.DelLikeRoom(self.szRoomID)
            end, function()
                UIHelper.SetSelected(self.TogLike, true, false)
            end)
        end
    end)
end

function UIWidgetVoiceRoomListCell:RegEvent()
    Event.Reg(self, EventType.ON_SYNC_VOICE_ROOM_INFO, function()
        self:UpdateInfo()
    end)

    Event.Reg(self, "SYNC_VOICE_ROOM_MEMBER_LIST", function()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.ON_LIVE_STREAM_INFO_UPDATE, function()
        self:UpdateAudienceArea()
    end)
end

function UIWidgetVoiceRoomListCell:UnRegEvent()
    Event.UnRegAll(self)
end


function UIWidgetVoiceRoomListCell:OnClickCell()
    local tbInfo = RoomVoiceData.GetVoiceRoomInfo(self.szRoomID)
    if not tbInfo then
        TipsHelper.ShowNormalTip("聊天室已解散")
        return
    end
    if self.fnAction then
        self.fnAction(self.szRoomID, tbInfo.bPwdRequired)
    end
end

function UIWidgetVoiceRoomListCell:OnClickTopView()
    local tbInfo = RoomVoiceData.GetVoiceRoomInfo(self.szRoomID)
    if not tbInfo then
        TipsHelper.ShowNormalTip("聊天室已解散")
        return
    end
    RoomVoiceData.TryJoinRoomAndWatchLiveStream(self.szRoomID, tbInfo.bPwdRequired, tbInfo.szMasterID)
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetVoiceRoomListCell:UpdateInfo()
    local tbInfo = RoomVoiceData.GetVoiceRoomInfo(self.szRoomID)

    UIHelper.SetString(self.LabelRoomName, "聊天室已解散")
    UIHelper.SetString(self.LabelRoomEmpty, "聊天室已解散")
    UIHelper.SetString(self.LabelState, "--")
    UIHelper.SetVisible(self.LabelRoomEmpty, tbInfo == nil)
    UIHelper.SetVisible(self.LayoutRoomName, tbInfo ~= nil)
    UIHelper.SetVisible(self.LabelState, tbInfo ~= nil)
    UIHelper.SetVisible(self.ImgCamp, false)
    UIHelper.SetVisible(self.ImgJinZhi, false)
    UIHelper.SetVisible(self.ImgNormalBg, false)
    UIHelper.SetVisible(self.LayoutVip, false)
    UIHelper.SetVisible(self.ImgVip, false)
    UIHelper.SetVisible(self.BtnTopView, false)
    UIHelper.SetSelected(self.TogLike, RoomVoiceData.IsLikeRoom(self.szRoomID), false)
    UIHelper.SetVisible(self.ImgListening, RoomVoiceData.IsListening(self.szRoomID))
    if not tbInfo then
        return
    end

    local bIsFreeze = (tbInfo.nFreezeTime - GetCurrentTime()) > 0
    local bSuperRoom = tbInfo.nSuperRoomTime > GetCurrentTime() and tbInfo.nRoomLevel > 0
    local bIsLiveStream = self.nPage == PAGE_TYPE.LiveStream
    UIHelper.SetVisible(self.TogLike, tbInfo.nRoomLevel ~= 0 and self.nPage == PAGE_TYPE.Like)

    if bIsFreeze then
        return
    end

    self:UpdateCamp(tbInfo.nCampLimitMask)
    UIHelper.SetVisible(self.ImgUnpublic, tbInfo.bPwdRequired)

    -- 已废弃
    UIHelper.SetVisible(self.LayoutVip, tbInfo.nRoomLevel > 0 and not bSuperRoom and not bIsLiveStream)
    -- UIHelper.SetString(self.LableVip, tbInfo.nRoomLevel .. "级")

    UIHelper.SetVisible(self.ImgVip,  bSuperRoom and not bIsLiveStream)
    UIHelper.SetVisible(self.ImgLinshi, tbInfo.nRoomLevel == 0 and not bIsLiveStream)
    local szName = bIsFreeze and "聊天室已解散" or UIHelper.GBKToUTF8(tbInfo.szRoomName)
    UIHelper.SetString(self.LabelRoomName, szName, 8)
    local szPopularity = bIsFreeze and "--" or tostring(tbInfo.dwPopularity)
    UIHelper.SetString(self.LabelState, szPopularity)
    local szImg = RoomVoiceData.GetHotRankImg(tbInfo.dwPopularity)
    if szImg then
        UIHelper.SetSpriteFrame(self.ImgHot, szImg)
    end

    local nRemainTime = 0
    if tbInfo.nSuperRoomTime > GetCurrentTime() then
        nRemainTime = tbInfo.nSuperRoomTime - GetCurrentTime()
    end
    local tPath = RoomVoiceData.GetRoomSkinPath(tbInfo.nRoomLevel, nRemainTime)
    local szPath = tPath and tbVoiceRoomBgList[tPath.szRecommandPath] or "UIAtlas2_VoiceRoom_VoiceRoomBg_img_linshi_cell"
    UIHelper.SetSpriteFrame(self.ImgNormalBg, szPath)
    UIHelper.SetVisible(self.ImgNormalBg, true)
    UIHelper.SetNodeSwallowTouches(self.TogLike, true, false)

    UIHelper.LayoutDoLayout(self.LayoutRoomName)
    UIHelper.LayoutDoLayout(self.LayoutOperation)

    UIHelper.LayoutDoLayout(self.LayoutVip)
    Timer.AddFrame(self, 1, function()
        UIHelper.LayoutDoLayout(self.LayoutRoomPlayerNum)
    end)

    self:UpdateAudienceArea(tbInfo)
end

function UIWidgetVoiceRoomListCell:UpdateAudienceArea(tbInfo)
    tbInfo = tbInfo or RoomVoiceData.GetVoiceRoomInfo(self.szRoomID)
    if not tbInfo or not tbInfo.szMasterID then
        UIHelper.SetVisible(self.ImgAudience, false)
        UIHelper.SetVisible(self.LabelAudienceNum, false)
        UIHelper.SetVisible(self.BtnTopView, false)
        return
    end
    local tLiveInfo = RoomVoiceData.GetLiveStreamInfo(tbInfo.szMasterID)
    local bIsLiving = tLiveInfo and tLiveInfo.nMapID and tLiveInfo.nMapID ~= 0
    UIHelper.SetVisible(self.ImgAudience, bIsLiving)
    UIHelper.SetVisible(self.LabelAudienceNum, bIsLiving)
    if bIsLiving then
        if tLiveInfo.bInLiveMap then
            UIHelper.SetString(self.LabelAudienceNum, "直播中")
            UIHelper.SetVisible(self.LabelAudienceNum, true)
            UIHelper.SetVisible(self.BtnTopView, self.nPage == PAGE_TYPE.LiveStream)
        else
            UIHelper.SetString(self.LabelAudienceNum, "待前往")
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutRoomPlayerNum)
    UIHelper.LayoutDoLayout(self.LayoutOperation)
    Timer.AddFrame(self, 1, function()
        UIHelper.LayoutDoLayout(self.LayoutRoomPlayerNum)
    end)
end

function UIWidgetVoiceRoomListCell:UpdateCamp(nCampLimitMask)
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

return UIWidgetVoiceRoomListCell