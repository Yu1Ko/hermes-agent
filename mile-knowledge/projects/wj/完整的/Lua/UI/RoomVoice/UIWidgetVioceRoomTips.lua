-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetVioceRoomTips
-- Date: 2025-09-18 14:48:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetVioceRoomTips = class("UIWidgetVioceRoomTips")
local tbVoiceRoomBgList = {
    ["ui/Image/GiftImage/DefaultBg.tga"] = "UIAtlas2_VoiceRoom_VoiceRoomBg_img_linshi_tip",
    ["ui/Image/GiftImage/FixBg.tga"] = "UIAtlas2_VoiceRoom_VoiceRoomBg_img_yongjiu_tip",
    ["ui/Image/GiftImage/NormalBg.tga"] = "UIAtlas2_VoiceRoom_VoiceRoomBg_img_chaoji_tip"
}

function UIWidgetVioceRoomTips:OnEnter(szRoom)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szRoomID = szRoom
    RoomVoiceData.ApplyVoiceRoomInfo(self.szRoomID)

    -- 申请直播流信息
    local tbInfo = RoomVoiceData.GetVoiceRoomInfo(self.szRoomID)
    if tbInfo and tbInfo.szMasterID then
        RoomVoiceData.ApplyLiveStreamInfo(tbInfo.szMasterID)
    end

    self:UpdateInfo()
end

function UIWidgetVioceRoomTips:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIWidgetVioceRoomTips:BindUIEvent()
    UIHelper.SetTouchDownHideTips(self.TogLike, false)
    UIHelper.BindUIEvent(self.BtnCopy, EventType.OnClick, function()
        SetClipboard(self.szRoomID)
        TipsHelper.ShowNormalTip("复制成功")
    end)

    UIHelper.BindUIEvent(self.BtnEnter, EventType.OnClick, function()
        local tbInfo = RoomVoiceData.GetVoiceRoomInfo(self.szRoomID)
        RoomVoiceData.TryJoinRoom(self.szRoomID, tbInfo.bPwdRequired)
    end)

    UIHelper.BindUIEvent(self.TogLike, EventType.OnSelectChanged, function(_, bSelect)
        local szRoomID = self.szRoomID
        if bSelect then
            RoomVoiceData.AddLike(szRoomID)
        else
            RoomVoiceData.DelLikeRoom(szRoomID)
        end
    end)
end

function UIWidgetVioceRoomTips:RegEvent()
    Event.Reg(self, EventType.ON_SYNC_VOICE_ROOM_INFO, function(szRoom, bRoomExist)
        if szRoom == self.szRoomID then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "SYNC_VOICE_MEMBER_SOCIAL_INFO", function(tbGlobalID)
        if self.szMasterID and table.contain_value(tbGlobalID, self.szMasterID) then
            self:UpdateMasterName()
        end
    end)

    Event.Reg(self, EventType.ON_LIVE_STREAM_INFO_UPDATE, function()
        self:UpdateAudienceArea()
    end)
end

function UIWidgetVioceRoomTips:UnRegEvent()
    Event.UnRegAll(self)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetVioceRoomTips:UpdateInfo()
    local tbInfo = RoomVoiceData.GetVoiceRoomInfo(self.szRoomID)
    UIHelper.SetString(self.LabelRoomIDEmpty, "ID:" .. self.szRoomID)

    for index, node in ipairs(self.tbHideList) do
        UIHelper.SetVisible(node, tbInfo ~= nil)
    end

    UIHelper.SetString(self.LabelRoomNameEmpty, "聊天室已解散")
    UIHelper.SetString(self.LabelRoomPlayerNum, "--")
    UIHelper.SetVisible(self.WidgetVip, false)
    UIHelper.SetVisible(self.ImgVip, false)
    UIHelper.SetVisible(self.ImgCamp, false)
    UIHelper.SetVisible(self.ImgUnpublic, false)
    UIHelper.SetVisible(self.ImgJinZhi, false)
    UIHelper.SetVisible(self.LabelRoomNameEmpty, tbInfo == nil)
    UIHelper.SetVisible(self.LabelRoomIDEmpty, tbInfo == nil)

    UIHelper.SetButtonState(self.BtnEnter, tbInfo == nil and BTN_STATE.Disable or BTN_STATE.Normal)
    UIHelper.SetButtonState(self.BtnCopy, tbInfo == nil and BTN_STATE.Disable or BTN_STATE.Normal)

    if not tbInfo then
        return
    end
    self:UpdateCamp(tbInfo.nCampLimitMask)

    local bIsFreeze = (tbInfo.nFreezeTime - GetCurrentTime()) > 0
    local bSuperRoom = tbInfo.nSuperRoomTime > GetCurrentTime() and tbInfo.nRoomLevel > 0

    UIHelper.SetVisible(self.ImgVip, bSuperRoom)
    UIHelper.SetVisible(self.TogLike, tbInfo.nRoomLevel > 0)
    UIHelper.SetSelected(self.TogLike, RoomVoiceData.IsLikeRoom(self.szRoomID), false)

    local szName = bIsFreeze and "聊天室已解散" or UIHelper.GBKToUTF8(tbInfo.szRoomName)
    UIHelper.SetString(self.LabelRoomName, szName)
    UIHelper.SetVisible(self.ImgUnpublic, tbInfo.bPwdRequired)
    UIHelper.SetString(self.LableVip, tbInfo.nRoomLevel .."级")
    UIHelper.SetVisible(self.WidgetVip, tbInfo.nRoomLevel > 0 and not bSuperRoom)
    UIHelper.SetVisible(self.ImgListening, RoomVoiceData.IsListening(self.szRoomID))
    UIHelper.LayoutDoLayout(self.LayoutRoomNameVip)

    local nCurrentTime = GetCurrentTime()
    local nRemainTime = 0
    if tbInfo.nSuperRoomTime > nCurrentTime then
        nRemainTime = tbInfo.nSuperRoomTime - nCurrentTime
    end
    local tPath = RoomVoiceData.GetRoomSkinPath(tbInfo.nRoomLevel, nRemainTime)
    local szPath = tPath and tbVoiceRoomBgList[tPath.szRoomPath] or "UIAtlas2_VoiceRoom_VoiceRoomBg_img_linshi_tip"
    UIHelper.SetSpriteFrame(self.ImgBg, szPath)

    UIHelper.SetString(self.LabelRoomID, "ID:" .. tostring(self.szRoomID))

    local szPopularity = bIsFreeze and "--" or tostring(tbInfo.dwPopularity)
    UIHelper.SetString(self.LabelRoomPlayerNum, szPopularity)
    local szImg = RoomVoiceData.GetHotRankImg(tbInfo.dwPopularity)
    if szImg then
        UIHelper.SetSpriteFrame(self.ImgHot, szImg)
    end

    UIHelper.LayoutDoLayout(self.LayoutRoomPlayerNum)
    UIHelper.LayoutDoLayout(self.WidgetVip)

    self.szMasterID = tbInfo.szMasterID
    self:UpdateMasterName()
    UIHelper.LayoutDoLayout(self.LayoutButtonRank02)

    self:UpdateAudienceArea(tbInfo)
    UIHelper.LayoutDoLayout(self.LayoutRoomInfo)
end

function UIWidgetVioceRoomTips:UpdateAudienceArea(tbInfo)
    tbInfo = tbInfo or RoomVoiceData.GetVoiceRoomInfo(self.szRoomID)
    if not tbInfo or not tbInfo.szMasterID then
        UIHelper.SetVisible(self.ImgAudience, false)
        UIHelper.SetVisible(self.LabelAudienceNum, false)
        UIHelper.SetVisible(self.LayoutAudience, false)
        return
    end
    local tLiveInfo = RoomVoiceData.GetLiveStreamInfo(tbInfo.szMasterID)
    local bIsLiving = tLiveInfo and tLiveInfo.nMapID and tLiveInfo.nMapID ~= 0
    UIHelper.SetVisible(self.ImgAudience, bIsLiving)
    UIHelper.SetVisible(self.LabelAudienceNum, bIsLiving)
    UIHelper.SetVisible(self.LayoutAudience, bIsLiving)

    if bIsLiving then
        if tLiveInfo.bInLiveMap then
            UIHelper.SetString(self.LabelAudienceNum, "直播中")
            UIHelper.SetVisible(self.LabelAudienceNum, true)
        else
            UIHelper.SetString(self.LabelAudienceNum, "待前往")
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutAudience)
end

function UIWidgetVioceRoomTips:UpdateMasterName()
    local tbInfo = RoomVoiceData.GetVoiceRoomMemberSocialInfo(self.szMasterID)
    if not tbInfo then
        RoomVoiceData.ApplyVoiceMemberSocialInfo({self.szMasterID})
        return
    end
    UIHelper.SetString(self.LabelRoomPlayerName, UIHelper.GBKToUTF8(tbInfo.szName))
    UIHelper.LayoutDoLayout(self.LayoutRoomOwner)
end

function UIWidgetVioceRoomTips:UpdateCamp(nCampLimitMask)
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

return UIWidgetVioceRoomTips