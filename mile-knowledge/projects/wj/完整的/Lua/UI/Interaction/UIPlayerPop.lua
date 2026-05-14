-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPlayerPop
-- Date: 2022-11-14 19:44:30
-- Desc: ?
-- Prefab: WidgetPlayerPop
-- ---------------------------------------------------------------------------------

local UIPlayerPop = class("UIPlayerPop")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPlayerPop:_LuaBindList()
    self.LayoutMenu = self.LayoutMenu --- 按钮容器

    -- 个人信息部分
    self.LableName = self.LableName --- 名称
    self.LableLevel = self.LableLevel --- 等级
    self.LableCamp = self.LableCamp --- 阵营
    self.LableGroup = self.LableGroup --- 帮会
    self.LabelEquipGrade = self.LabelEquipGrade --- 装备分数

    -- 信誉分部分
    self.LableCreditTitle = self.LableCreditTitle --- 信誉分标题
    self.ProgressBarZhenYingZhanChang = self.ProgressBarZhenYingZhanChang --- 进度条 - 阵营战场
    self.LableZhenYingZhanChang = self.LableZhenYingZhanChang --- 进度数值 - 阵营战场
    self.ProgressBarMingJianDaHui = self.ProgressBarMingJianDaHui --- 进度条 - 名剑大会
    self.LableMingJianDaHui = self.LableMingJianDaHui --- 进度数值 - 名剑大会
    self.ProgressBarLongMenJueJing = self.ProgressBarLongMenJueJing --- 进度条 - 龙门绝境
    self.LableLongMenJueJing = self.LableLongMenJueJing --- 进度数值 - 龙门绝境
    self.ProgressBarDaXiaoGongFang = self.ProgressBarDaXiaoGongFang --- 进度条 - 大小攻防
    self.LableDaXiaoGongFang = self.LableDaXiaoGongFang --- 进度数值 - 大小攻防
    self.ProgressBarLiDuGuiYu = self.ProgressBarLiDuGuiYu --- 进度条 - 李渡鬼域
    self.LableLiDuGuiYu = self.LableLiDuGuiYu --- 进度数值 - 李渡鬼域
    self.ProgressBarLieXingXuJing = self.ProgressBarLieXingXuJing --- 进度条 - 列星虚境
    self.LableLieXingXuJing = self.LableLieXingXuJing --- 进度数值 - 列星虚境
    self.BtnPlayerIcon = self.BtnPlayerIcon --- 一串图标的容器
    self.LayoutSite = self.LayoutSite --- 区域信息的容器

    self.widgetPlayerMenu = self.widgetPlayerMenu --- 按钮容器上层的容器
    self.LayoutPlayer = self.LayoutPlayer --- 玩家信息组件容器
    self.ImgPlayerPopTipsBg = self.ImgPlayerPopTipsBg --- 信誉分界面

    self.TogGroupMenu = self.TogGroupMenu --- toggle按钮的互斥组
    self.ImgPlayerBg = self.ImgPlayerBg --- 背景色图片

    self.WidgetLogInTime = self.WidgetLogInTime --- 拜师与上次登录时间组件
    self.WidgetVoiceSetting = self.WidgetVoiceSetting --- 语音设置
end

local tbShowLabelTipIndex = {
    PlayerIcon = 1,
    Twoway = 2,
    PlaceLabel = 3,
}

function UIPlayerPop:OnEnter(szTargetID, tbAllMenuConfig, tbRoleEntryInfo, bShowPersonLabel, bIsFromChat, tFromVoiceRoom)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self:SyncArenaCorpsData()   --名剑相关数据
        self.bInit = true
    end

    self:InitPlayerDate(szTargetID, tbAllMenuConfig, tbRoleEntryInfo, bShowPersonLabel, bIsFromChat, tFromVoiceRoom)
    self:UpdateInfo()
end

function UIPlayerPop:OnExit()
    self.bInit = false
    self:UnRegEvent()

    -- 主界面退出时，将次级菜单的tips也给干掉
    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetInteractionMorePop)
    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipTargetgetMark)
    Timer.DelAllTimer(self)
end

function UIPlayerPop:OnHoverTipsCreated()
    self:UpdateTipsPos()
end

function UIPlayerPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnPlayerIcon, EventType.OnClick, function ()
        self:ShowPlaceLabelTips(tbShowLabelTipIndex.PlayerIcon)
    end)

    UIHelper.BindUIEvent(self.ImgTwoway, EventType.OnClick, function ()
        self:ShowPlaceLabelTips(tbShowLabelTipIndex.Twoway)
    end)

    UIHelper.BindUIEvent(self.BtnPlaceLabel, EventType.OnClick, function ()
        self:ShowPlaceLabelTips(tbShowLabelTipIndex.PlaceLabel)
    end)

    UIHelper.BindUIEvent(self.BtnGotoLand, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelHome, 1, self.tbPlayerCard.dwLandMapID, self.tbPlayerCard.nLandCopyIndex, self.tbPlayerCard.nLandIndex, self.tbRoleEntryInfo.dwPlayerID)
        TipsHelper.DeleteAllHoverTips()
    end)

    UIHelper.BindUIEvent(self.BtnGotoPrivateLand, EventType.OnClick, function ()
        if not self.tbRoleEntryInfo then
            return
        end

        local tLine = Table_GetPrivateHomeSkin(self.tbPlayerCard.dwPHomeMapID, self.tbPlayerCard.dwPHomeSkin)
        local szText = FormatString(g_tStrings.STR_LINK_PRIVATE_CLICK_MSG, UIHelper.GBKToUTF8(self.tbRoleEntryInfo.szName), FormatString(g_tStrings.STR_LINK_PRIVATE, UIHelper.GBKToUTF8(tLine.szSkinName)))
        UIHelper.ShowConfirm(szText, function ()
            if CheckPlayerIsRemote(nil, g_tStrings.STR_REMOTE_NOT_TIP) then
                return
            end
            local nMapID = self.tbPlayerCard.dwPHomeMapID
            local nCopyIndex = self.tbPlayerCard.nPHomeCopyIndex
            local dwSkinID = self.tbPlayerCard.dwPHomeSkin

            local function _goPrivateLand()
                HomelandData.GoPrivateLand(nMapID, nCopyIndex, dwSkinID, 3)
            end
            if PakDownloadMgr.UserCheckDownloadHomelandRes(nMapID, dwSkinID, _goPrivateLand) then
                _goPrivateLand()
            end
        end)
        TipsHelper.DeleteAllHoverTips()
    end)

    UIHelper.BindUIEvent(self.BtnPersonalCard, EventType.OnClick, function ()
        self:SetPersonalVisible(true)
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetInteractionMorePop)
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipTargetgetMark)
    end)

    UIHelper.BindUIEvent(self.BtnShare, EventType.OnClick, function ()
        ChatHelper.SendPlayerToChat(self.szName)
    end)

    UIHelper.BindUIEvent(self.SliderVolumeAdjustment, EventType.OnChangeSliderPercent , function (SliderEventType, nSliderEvent)
        if nSliderEvent == ccui.SliderEventType.percentChanged then
            local sliderValue = UIHelper.GetProgressBarPercent(self.SliderVolumeAdjustment)
            if sliderValue > 100 then
                sliderValue = 100
            end
            self.nCurrentVolume = math.floor(sliderValue / 100 * 150)
            RoomVoiceData.SetSpeakerVolumeByUserID(self.szRoomID, self.szGVoiceID, self.nCurrentVolume)
            self:UpdateVoiceSetting()
        end
    end)
end

function UIPlayerPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnGetPrestigeInfoRespond, function(dwPlayerID, tbInfo)
        self:OnCreditInfoRespond(dwPlayerID, tbInfo)
    end)

    Event.Reg(self, EventType.ApplyPlayerPopPrestige, function (dwPlayerID)
        if not UIHelper.GetVisible(self.ImgPlayerPopTipsBg) then
            self:RequestCreditInfo()
        else
            UIHelper.SetVisible(self.ImgPlayerPopTipsBg, false)
        end
    end)

    Event.Reg(self, "PEEK_OTHER_PLAYER", function(nResult, dwPlayerID)
        if nResult ~= PEEK_OTHER_PLAYER_RESPOND.SUCCESS then
            return
        end

        local targetPlayer
        if self.dwTargetPlayerId then
            targetPlayer = GetPlayer(self.dwTargetPlayerId)
        elseif self.szTargetGlobalID then
            targetPlayer = GetPlayerByGlobalID(self.szTargetGlobalID)
        end

        if not targetPlayer or targetPlayer.dwID ~= dwPlayerID then
            return
        end

        if not UIHelper.GetVisible(self.WidgetPersonalCardTips) then
            UIHelper.SetVisible(self.WidgetEmpty, false)
            UIHelper.SetVisible(self.LayoutPlayer, true)
        end

        UIHelper.SetString(self.LableGroup, self:GetTongName(targetPlayer.dwTongID))
        UIHelper.SetString(self.LabelEquipGrade, PlayerData.GetPlayerTotalEquipScore(targetPlayer))
    end)

    Event.Reg(self, "UPDATE_FELLOWSHIP_CARD", function (tbGlobalID)
        for _, gid in ipairs(tbGlobalID) do
            if gid == self.szTargetGlobalID then
                self.tbPlayerCard = FellowshipData.GetFellowshipCardInfo(self.szTargetGlobalID)
                self:UpdatePlayerCardInfo()
                self:UpdatePersonLabel()
                UIHelper.LayoutDoLayout(self.widgetPlayerMenu)
                UIHelper.LayoutDoLayout(self.LayoutPlayer)
                self:UpdateTipsPos()
            end
        end
    end)

    Event.Reg(self, "FELLOWSHIP_ROLE_ENTRY_UPDATE", function (szGlobalID)
        if szGlobalID == self.szTargetGlobalID then
            self.tbRoleEntryInfo = FellowshipData.GetRoleEntryInfo(self.szTargetGlobalID)
            local tNameCard = UINameCardTab[self.tbRoleEntryInfo.nSkinID]
            if tNameCard then
                UIHelper.SetTexture(self.ImgBgTop, tNameCard.szVisitCardPath)
            end
        end
    end)

    Event.Reg(self, "PEEK_PLAYER_BOOK_STATE", function()
        UIMgr.Open(VIEW_ID.PanelReadMain, self.dwTargetPlayerId)
        TipsHelper.DeleteAllHoverTips()
    end)

    Event.Reg(self, "ON_GET_TONG_NAME_NOTIFY", function ()
        if arg1 == self.dwApplyTongID then
            UIHelper.SetString(self.LableGroup, UIHelper.GBKToUTF8(arg2))
        end
    end)

    Event.Reg(self, "TEAM_AUTHORITY_CHANGED", function ()
        Timer.DelAllTimer(self)
        UIHelper.RemoveAllChildren(self.LayoutMenu)
        self:GenerateMenuConfig()
        self:UpdateMenus()
        UIHelper.LayoutDoLayout(self.LayoutMenu)
        UIHelper.LayoutDoLayout(self.widgetPlayerMenu)
        UIHelper.LayoutDoLayout(self.LayoutPlayer)
        self:UpdateTipsPos()
    end)

    Event.Reg(self, "APPLY_ROLE_MAP_ID_RESPOND", function (szGlobalID, dwMapID)
        if szGlobalID == self.szTargetGlobalID then
            self.szMapName = FellowshipData.GetWhereDesc(dwMapID, self.tbRoleEntryInfo, self.attraction)

            UIHelper.SetString(self.LabelMapName, self.szMapName, 5)
            UIHelper.LayoutDoLayout(self.ImgFriendLabelTips)
            UIHelper.SetEnable(self.BtnPlaceLabel, self.szMapName ~= UIHelper.LimitUtf8Len(self.szMapName, 5))
        end
    end)
end

function UIPlayerPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIPlayerPop:InitPlayerDate(szTargetID, tbAllMenuConfig, tbRoleEntryInfo, bShowPersonLabel, bIsFromChat, tFromVoiceRoom)
    if IsNumber(szTargetID) then
        self.dwTargetPlayerId = szTargetID
        local targetPlayer = GetPlayer(self.dwTargetPlayerId)
        if targetPlayer then
            self.szTargetGlobalID = targetPlayer.GetGlobalID()
            UIHelper.SetVisible(self.WidgetEmpty, false )
        elseif not tbRoleEntryInfo then
            UIHelper.SetVisible(self.WidgetEmpty, true )
            UIHelper.SetVisible(self.LayoutPlayer, false )
        end
        self.bOnLine = true
    elseif IsString(szTargetID) then
        self.szTargetGlobalID = szTargetID
        self.bOnLine = FellowshipData.IsOnline(szTargetID)
        self.bMySelf = self.szTargetGlobalID == UI_GetClientPlayerGlobalID()
        self.bRemoteFriend = FellowshipData.IsRemoteFriend(szTargetID)
    end

    self.tbAllMenuConfig = tbAllMenuConfig
    self.tbRoleEntryInfo = tbRoleEntryInfo

    if self.bMySelf then
        self.tbRoleEntryInfo = FellowshipData.GetRoleEntryInfo(self.szTargetGlobalID)
        self.tbPlayerCard = FellowshipData.GetFellowshipCardInfo(self.szTargetGlobalID)
        FellowshipData.ApplyFellowshipCard(self.szTargetGlobalID)
    end

    if tFromVoiceRoom then
        self.bIsFromVoice = true
        self.szRoomID = tFromVoiceRoom.szRoomID
        self.szGVoiceID = tFromVoiceRoom.szGVoiceID
        self.nCurrentVolume = RoomVoiceData.GetSpeakerVolumeByUserID(self.szRoomID, self.szGVoiceID)
    end

    self.bShowPersonLabel = bShowPersonLabel
    self.bIsFromChat = bIsFromChat
    self.bOpenPanelClose = true
end

function UIPlayerPop:UpdateInfo()
    self.BtnPlayerIcon:setTouchDownHideTips(false)
    self.ImgTwoway:setTouchDownHideTips(false)
    self.BtnPlaceLabel:setTouchDownHideTips(false)
    self.BtnGotoLand:setTouchDownHideTips(false)
    self.BtnGotoPrivateLand:setTouchDownHideTips(false)
    self.BtnEmpty:setTouchDownHideTips(false)
    self.BtnPersonalCard:setTouchDownHideTips(false)
    self.BtnShare:setTouchDownHideTips(false)
    self.BarSizeAdjustment:setTouchDownHideTips(false)
    self.SliderVolumeAdjustment:setTouchDownHideTips(false)

    local nTopHeight = UIHelper.GetHeight(self.WidgetTop)
    local nBtnHeight = UIHelper.GetHeight(self.BtnPlayerIcon)
    self.nTopHeight = nTopHeight
    self.nHideBtnpHeight = nTopHeight - nBtnHeight

    -- 隐藏一些组件
    UIHelper.SetVisible(self.LayoutSite, false)
    UIHelper.SetVisible(self.ImgPlayerPopTipsBg, false)
    UIHelper.SetVisible(self.WidgetLogInTime, false)
    UIHelper.SetVisible(self.WidgetStudentNum1, false)
    UIHelper.SetVisible(self.BtnPersonalCard, false)
    UIHelper.SetVisible(self.WidgetVoiceSetting, false)

    if self.bIsFromChat then
        UIHelper.SetVisible(self.LableGroup, not self.bIsFromChat)
        UIHelper.SetVisible(self.LableGroupTitle, not self.bIsFromChat)
        UIHelper.SetVisible(self.WidgetEquip, not self.bIsFromChat)
    end

    -- 预制中默认隐藏，但我们这个界面中需要显示，先调整为可见
    UIHelper.SetVisible(self.widgetPlayerMenu, true)

    self:UpdateMenus()
    self:UpdatePlayerInfo()
    self:UpdatePersonLabel()
    self:UpdateVoiceSetting()
    self:UpdateNpcMoodInfo()

    UIHelper.LayoutDoLayout(self.widgetPlayerMenu)
    UIHelper.LayoutDoLayout(self.LayoutPlayer)
    self:UpdateTipsPos()
end

function UIPlayerPop:UpdateTipsPos()
    if self._hoverTips then
        local nX, nY = UIHelper.GetContentSize(self.LayoutPlayer)
        self._hoverTips:SetSize(nX, nY)
        self._hoverTips:Update()
    end
end

function UIPlayerPop:RequestCreditInfo()
    RemoteCallToServer("On_XinYu_GetInfo", self.dwTargetPlayerId)
end

function UIPlayerPop:OnCreditInfoRespond(dwPlayerID, tbInfo)
    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetPlayerPop)
    UIHelper.RemoveAllChildren(self.WidgetPlayerPop)
    UIMgr.Open(VIEW_ID.PanelPlayerReputationPop,tbInfo,dwPlayerID)
end

function UIPlayerPop:UpdatePlayerInfo()
    local targetPlayer = self.dwTargetPlayerId and GetPlayer(self.dwTargetPlayerId)
    local bHasPlayer = true
    if not targetPlayer then
        targetPlayer = self.tbRoleEntryInfo
        bHasPlayer = false
    end

    if not targetPlayer then
        return
    end

    self.szName = UIHelper.GBKToUTF8(targetPlayer.szName)
    local szUtf8Name = UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(targetPlayer.szName), 8)
    if szUtf8Name == "" then
        UIHelper.SetVisible(self.ImgCamp, false)
        UIHelper.SetVisible(self.BtnShare, false)
        self.bShowPersonLabel = false
    elseif targetPlayer.nCamp then
        CampData.SetUICampImg(self.ImgCamp, targetPlayer.nCamp, nil, true)
    end
    if self.tbRoleEntryInfo and self.tbRoleEntryInfo.nEquipScore then
        UIHelper.SetVisible(self.ImgCamp, false)
    end

    if self.tbRoleEntryInfo then
        UIHelper.SetString(self.LabelSignature, UIHelper.GBKToUTF8(self.tbRoleEntryInfo.szSignature))
        UIHelper.SetVisible(self.LabelSignature, self.tbRoleEntryInfo.szSignature ~= "")
        if self.tbRoleEntryInfo.szSignature and self.tbRoleEntryInfo.szSignature ~= "" and self.bMySelf then
            UIHelper.SetVisible(self.LayoutSite, true)
            UIHelper.SetVisible(self.WidgetSite, false)
            UIHelper.SetVisible(self.WidgetFavorability, false)
            UIHelper.LayoutDoLayout(self.LayoutSite)
        end
    end

    UIHelper.SetString(self.LableName, szUtf8Name == "" and g_tStrings.MENTOR_DELETE_ROLE or szUtf8Name)
    UIHelper.SetSpriteFrame(self.ImgForceID, PlayerForceID2SchoolImg2[bHasPlayer and targetPlayer.dwForceID or targetPlayer.nForceID])
    UIHelper.SetString(self.LableLevel, targetPlayer.nLevel)

    if not bHasPlayer and targetPlayer.nEquipScore then
        UIHelper.SetString(self.LabelEquipGrade, self.tbRoleEntryInfo.nEquipScore)
        UIHelper.SetString(self.LableGroup, UIHelper.GBKToUTF8(TongData.GetName()))
    elseif self.dwTargetPlayerId then
        if not bHasPlayer and targetPlayer.szTongName then
            UIHelper.SetString(self.LableGroup, targetPlayer.szTongName ~= "" and UIHelper.GBKToUTF8(targetPlayer.szTongName) or "无")
        elseif targetPlayer.dwTongID then
            UIHelper.SetString(self.LableGroup, self:GetTongName(targetPlayer.dwTongID))
        end
        UIHelper.SetString(self.LabelEquipGrade, bHasPlayer and PlayerData.GetPlayerTotalEquipScore(targetPlayer) or "未知")
    elseif self.szTargetGlobalID then
        if self.bMySelf then
            local szTongName = "无"
            if g_pClientPlayer and g_pClientPlayer.dwTongID ~= 0  then
                szTongName = UIHelper.GBKToUTF8(GetTongClient().ApplyGetTongName(g_pClientPlayer.dwTongID)) or "无"
            end
            UIHelper.SetString(self.LableGroup, szTongName)
            UIHelper.SetString(self.LabelEquipGrade, PlayerData.GetPlayerTotalEquipScore() or "未知")
        else
            local player = GetPlayerByGlobalID(self.szTargetGlobalID)
            UIHelper.SetString(self.LabelEquipGrade, player and PlayerData.GetPlayerTotalEquipScore(player) or "未知")
        end
    end

    local headScript = UIHelper.AddPrefab(PREFAB_ID.WidgetHead_108, self.WidgetPlayerHead, self.dwTargetPlayerId)
    if headScript and self.tbRoleEntryInfo then
        Timer.AddFrame(self, 1, function()
            if self.tbRoleEntryInfo.bIsAINpc then
                headScript:SetHeadWithTex(self.tbRoleEntryInfo.szSmallAvatarImg)
                return
            end

            headScript:SetHeadInfo(self.dwTargetPlayerId, self.tbRoleEntryInfo.dwMiniAvatarID or 0, self.tbRoleEntryInfo.nRoleType, self.tbRoleEntryInfo.nForceID or targetPlayer.dwForceID)
            if not self.tbRoleEntryInfo.nForceID and self.tbRoleEntryInfo.szImgHeadIcon then
                headScript:SetHeadWithImg(self.tbRoleEntryInfo.szImgHeadIcon)
            end
        end)
        headScript:SetOfflineState(self.bOnLine == false)

        --名帖
        local tNameCard = UINameCardTab[self.tbRoleEntryInfo.nSkinID]
        if tNameCard then
            UIHelper.SetTexture(self.ImgBgTop, tNameCard.szVisitCardPath)
        end

        UIHelper.SetSpriteFrame(self.ImgForceID, PlayerForceID2SchoolImg2[self.tbRoleEntryInfo.nForceID])
        UIHelper.SetString(self.LableForceID, Table_GetForceName(self.tbRoleEntryInfo.nForceID))
    end
    UIHelper.SetTouchEnabled(headScript.BtnHead, false)

    if self.dwTargetPlayerId and self.dwTargetPlayerId ~= g_pClientPlayer.dwID then
        PeekOtherPlayer(self.dwTargetPlayerId)
    elseif self.szTargetGlobalID and self.tbRoleEntryInfo and not self.bMySelf then
        PeekOtherPlayerByGlobalID(self.tbRoleEntryInfo.dwCenterID, self.szTargetGlobalID)
    end

    -- 计算高度
    UIHelper.LayoutDoLayout(self.widgetPlayerMessage)
    UIHelper.LayoutDoLayout(self.LayoutPlayer)
    self:UpdateTipsPos()
end

function UIPlayerPop:UpdatePersonLabel()
    local bShow = self.bShowPersonLabel
    UIHelper.SetVisible(self.BtnPlayerIcon, bShow)
    if not bShow then
        UIHelper.SetHeight(self.WidgetTop, self.nHideBtnpHeight)
        return
    else
        UIHelper.SetHeight(self.WidgetTop, self.nTopHeight)
    end

    local tSocialInfo = FellowshipData.tApplySocialList[self.tbRoleEntryInfo.dwPlayerID]
    if not self.tbPlayerCard then
        self.tbPlayerCard = tSocialInfo
    end

    if self.tbPlayerCard then
        UIHelper.RemoveAllChildren(self.WidgetPlayerPraiseList)
        self.tSortPraiseinfo = self:SortPraiseInfo()
        for _, tInfo in ipairs(self.tSortPraiseinfo) do
            local nodeScript = UIHelper.AddPrefab(PREFAB_ID.WidgetBtnIcon, self.WidgetPlayerPraiseList)
            if nodeScript then
                nodeScript:UpdateInfo(tInfo)
                -- nodeScript:SetClickCallBack(function()
                --     self:ShowPlaceLabelTips(tbShowLabelTipIndex.PlayerIcon)
                -- end)
            end
        end
    end
end

function UIPlayerPop:UpdateVoiceSetting()
    UIHelper.SetVisible(self.WidgetVoiceSetting, self.bIsFromVoice)
    if self.bIsFromVoice then
        local fProgress = math.floor(self.nCurrentVolume / 150 * 100)
        UIHelper.SetProgressBarPercent(self.BarSizeAdjustment, fProgress)
        UIHelper.SetProgressBarPercent(self.SliderVolumeAdjustment, fProgress)
        UIHelper.SetString(self.LabelSizeNum, string.format("%d", self.nCurrentVolume))
    end
end

function UIPlayerPop:UpdateNpcMoodInfo()
    if not self.tbRoleEntryInfo then
        return
    end
    if not self.tbRoleEntryInfo.bIsAINpc then
        return
    end

    UIHelper.SetVisible(self.PlayerMassage, false)
    UIHelper.SetVisible(self.BtnShare, false)

    local szName = self.tbRoleEntryInfo.szName and GBKToUTF8(self.tbRoleEntryInfo.szName) or ""
    UIHelper.SetString(self.LableNPCName, szName)

    UIHelper.SetVisible(self.WidgetNPCMassage, true)
    local nMood = self.tbRoleEntryInfo.nMood or 0
    UIHelper.SetString(self.LabelNPCMood, string.format(g_tStrings.STR_NPC_MOOD, nMood))
    UIHelper.SetVisible(UIHelper.GetParent(self.LabelNPCMood), ChatAINpcMgr.IsShowMood())
end

function UIPlayerPop:GetTongName(dwTongID)
    local szTongName = ''
    if dwTongID and dwTongID ~= 0 then
        szTongName = UIHelper.GBKToUTF8(GetTongClient().ApplyGetTongName(dwTongID)) or ''
        if szTongName == '' then
            self.dwApplyTongID = dwTongID
        end
    end

    if szTongName == '' then
        szTongName = "无"
    end

    return szTongName
end

function UIPlayerPop:GetCampName(nCamp)
    return g_tStrings.STR_GUILD_CAMP_NAME[nCamp]
end

function UIPlayerPop:GenerateMenuConfig()
    local targetPlayer = self.dwTargetPlayerId and GetPlayer(self.dwTargetPlayerId) or self.tbRoleEntryInfo
    if not targetPlayer then
        return
    end

    if not self.bMySelf then
        -- 他人的交互按钮
        PlayerPopData.SetTarget(targetPlayer, self.szTargetGlobalID, self.dwTargetPlayerId, self.tbRoleEntryInfo)
        PlayerPopData.SetTeamAndMaskMenu()
        self.tbAllMenuConfig = PlayerPopData.GetTargetMenuConfig()
        table.insert_tab(self.tbAllMenuConfig, JX_TargetList.GenerateMenuConfig(self.dwTargetPlayerId
        , UIHelper.GBKToUTF8(targetPlayer.szName), false, true))
    else
        -- 自己的交互按钮
        self.tbAllMenuConfig = {
            { szName = "勿扰选项", bCloseOnClick = true, callback = function()
                UIMgr.ToggleView(VIEW_ID.PanelShieldPop)
            end },
            { szName = "关闭阵营模式", bCloseOnClick = true, callback = function()
                --if not Station_IsInUserAction() then
                --    return
                --end
                RemoteCallToServer("OnCloseCampFlag")
            end, fnDisable = function()
                return not (GetClientPlayer().CanCloseCampFlag())
            end  },
            { szName = "自定义头像", bCloseOnClick = true, callback = function()
                UIMgr.ToggleView(VIEW_ID.PanelCustomAvatar)
            end },
            { szName = "开始摆擂", bCloseOnClick = true, callback = function()
                --local player = GetClientPlayer()
                --local nCDLeft = player.GetCDLeft(Challenge.BAI_LEI_ID)
                --if nCDLeft > 0 then
                --    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.PK_CD_MSG)
                --else
                RemoteCallToServer("On_PK_TryBaiTan")
                --end
            end },
            { szName = "系统设置", bCloseOnClick = true, callback = function()
                UIMgr.Open(VIEW_ID.PanelGameSettings)
            end },
            { szName = "更换名帖", bCloseOnClick = true, callback = function()
                UIMgr.Open(VIEW_ID.PanelNameCard)
            end },
        }
    end
end

function UIPlayerPop:UpdateMenus()
    if not self.tbAllMenuConfig then
        self:GenerateMenuConfig()
        UIHelper.SetVisible(self.BtnPersonalCard, not self.bMySelf)
    end

    if self.tbAllMenuConfig and #self.tbAllMenuConfig == 0 then
        UIHelper.SetVisible(self.widgetPlayerMenu, false)
    end
    self:CreateMenus(self.tbAllMenuConfig, self.LayoutMenu)
end

function UIPlayerPop:AddFocusMenus(tbExtraMenuConfig)
    Timer.DelAllTimer(self)
    UIHelper.RemoveAllChildren(self.LayoutMenu)
    self.tbAllMenuConfig = {}
    self:GenerateMenuConfig()
    table.insert_tab(self.tbAllMenuConfig, tbExtraMenuConfig)
    UIHelper.SetVisible(self.BtnPersonalCard, false)

    if self.tbAllMenuConfig and #self.tbAllMenuConfig == 0 then
        UIHelper.SetVisible(self.widgetPlayerMenu, false)
    end
    self:CreateMenus(self.tbAllMenuConfig, self.LayoutMenu)
    UIHelper.LayoutDoLayout(self.widgetPlayerMenu)
end

function UIPlayerPop:CreateMenus(tbAllMenuConfig, layoutParent, morePopParent)
    local tbShowMenuConfig = {}

    for _, tbMenuConfig in ipairs(tbAllMenuConfig or {}) do
        if not tbMenuConfig.fnCheckShow or  tbMenuConfig.fnCheckShow() then
            table.insert(tbShowMenuConfig, tbMenuConfig)
        end
    end

    local nMididx = math.ceil(#tbShowMenuConfig / 2) % 2 ~= 0 and math.ceil(#tbShowMenuConfig / 2) or math.ceil(#tbShowMenuConfig / 2) + 1

    for idx, tbMenuConfig in ipairs(tbShowMenuConfig) do
        if tbMenuConfig.bTeamMark then
            self:CreateTeamMarkMenu(tbMenuConfig, layoutParent)
        elseif not tbMenuConfig.bNesting then
            -- 判断是否设置了不满足条件时隐藏窗口
            local bHide = tbMenuConfig.bHideIfDisable and IsFunction(tbMenuConfig.fnDisable) and tbMenuConfig.fnDisable()

            if not bHide then
                -- 普通按钮
                local btnScript = UIHelper.AddPrefab(PREFAB_ID.WidgetInteractionMoreBtn, layoutParent)

                UIHelper.SetString(btnScript.LableMpore, tbMenuConfig.szName)

                if not morePopParent and nMididx == idx then
                    morePopParent = btnScript._rootNode
                end

                UIHelper.SetTouchDownHideTips(btnScript.Btn, false)

                UIHelper.BindUIEvent(btnScript.Btn, EventType.OnClick, function(btnClicked)
                    if IsFunction(tbMenuConfig.fnDisable) and tbMenuConfig.fnDisable() then
                        -- 如果按钮禁用的时候能有明显ui表现，这里可以挪到上面，并调整为将按钮禁用
                        TipsHelper.ShowNormalTip(tbMenuConfig.szName .. " 不符合条件，无法操作")
                        return
                    end

                    if tbMenuConfig.bCloseOnClick then
                        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetPlayerPop)
                        Event.Dispatch(EventType.DeletePlayerPop)
                    end

                    if IsFunction(tbMenuConfig.callback) then
                        tbMenuConfig.callback()
                    end
                end)

                if IsFunction(tbMenuConfig.fnDisable) then
                    local fnCheckDisable = function()
                        local nState = tbMenuConfig.fnDisable() and BTN_STATE.Disable or BTN_STATE.Normal
                        UIHelper.SetButtonState(btnScript.Btn, nState)
                    end

                    -- 初始先检查一次
                    fnCheckDisable()

                    -- 如果设置了检查间隔，就定时检查
                    if tbMenuConfig.nCheckDisableInterval then
                        Timer.AddCycle(self, tbMenuConfig.nCheckDisableInterval, function()
                            fnCheckDisable()
                        end)
                    end
                end
            end
        else
            local toggleScript = UIHelper.AddPrefab(PREFAB_ID.WidgetInteractionMoreTog, layoutParent)
            self.tbTogMenu = self.tbTogMenu or {}
            table.insert(self.tbTogMenu, toggleScript)

            if not morePopParent and nMididx == idx then
                morePopParent = toggleScript._rootNode
            end

            local nIndex = #self.tbTogMenu
            UIHelper.SetString(toggleScript.LableMpore, tbMenuConfig.szName)
            UIHelper.SetSelected(toggleScript.Toggle, false)
            UIHelper.ToggleGroupAddToggle(self.TogGroupMenu, toggleScript.Toggle)

            toggleScript.Toggle:setTouchDownHideTips(false)
            UIHelper.BindUIEvent(toggleScript.Toggle, EventType.OnClick, function ()
                local bSelected = UIHelper.GetSelected(toggleScript.Toggle)
                if bSelected then
                    -- 记录自己的序号，用于后续判定是否需要在被取消勾选时删除按钮
                    self.nCurSelectTogIndex = nIndex

                    local fnOnMorePopClose = function()
                        -- 展开的子菜单被关闭时，取消自己的勾选状态
                        UIHelper.SetSelected(toggleScript.Toggle, false)
                    end
                    -- 移除现有的三级菜单
                    if self.nCurSelectTogIndex <= 6 or self.dwTargetPlayerId == GetClientPlayer().dwID then
                        --原来没准备多一级菜单的判断，这里6个是指二级菜单的moreBtn数量
                        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetInteractionMorePop)
                    end
                    -- 创建自己的三级菜单
                    -- 子菜单的上层节点默认是调用时传入的指定节点，未若指定，则使用当前层。这样可实现后续更深层的子菜单也以第一层节点为父节点
                    -- 记录了一个中间的位置，中间节点后面节点的三级菜单以中间节点位置为准
                    local parent = toggleScript._rootNode
                    if idx >= math.ceil(#tbShowMenuConfig / 2) then
                        parent = morePopParent
                    end
                    local tips, tipsScriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetInteractionMorePop, parent, TipsLayoutDir.BOTTOM_LEFT, fnOnMorePopClose)

                    -- 调整tips位置，与右上角对齐
                    local nRootHeight = UIHelper.GetHeight(parent)
                    tips:SetOffset(0, -nRootHeight)
                    tips:ShowNodeTips(parent)
                    -- 添加按钮
                    if #tbMenuConfig.tbSubMenus >= 6 then
                        self:CreateMenus(tbMenuConfig.tbSubMenus, tipsScriptView.ScrollviewMore, parent)
                        UIHelper.AddPrefab(PREFAB_ID.WidgetArrow, tipsScriptView.WidgetArrow)
                        UIHelper.SetVisible(tipsScriptView.ScrollviewMore, true)
                    else
                        self:CreateMenus(tbMenuConfig.tbSubMenus, tipsScriptView.LayoutMore, parent)
                        UIHelper.SetVisible(tipsScriptView.ScrollviewMore, false)
                    end
                    -- 调整背景色高度
                    local nWidgetHeight = UIHelper.GetHeight(tipsScriptView.ScrollviewMore)
                    UIHelper.SetHeight(tipsScriptView.ImgPopBg, nWidgetHeight)
                    UIHelper.ScrollViewDoLayoutAndToTop(tipsScriptView.ScrollviewMore)
                    UIHelper.LayoutDoLayout(tipsScriptView.LayoutMore)
                    UIHelper.SetTouchDownHideTips(tipsScriptView.ScrollviewMore, false)
                    FellowshipData.nVisiblePlayerPop = 2
                elseif self.nCurSelectTogIndex == nIndex then
                    -- 当自己被取消勾选时，移除自己的按钮
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetInteractionMorePop)
                end
            end)
        end
    end

    UIHelper.LayoutDoLayout(layoutParent)
end

function UIPlayerPop:ShowFellowshipInfo(tbPlayerInfo, nMapID)
    UIHelper.SetVisible(self.BtnPersonalCard, true)
    UIHelper.SetVisible(self.LayoutSite, true)

    local tbRoleEntryInfo = self.tbRoleEntryInfo or FellowshipData.GetRoleEntryInfo(tbPlayerInfo.id)
    self.tbPlayerCard = FellowshipData.GetFellowshipCardInfo(tbPlayerInfo.id)
    if (not self.tbPlayerCard or table_is_empty(self.tbPlayerCard)) then
        FellowshipData.ApplyFellowshipCard(tbPlayerInfo.id)
    end

    FellowshipData.ApplyRoleMapID(tbPlayerInfo.id)
    nMapID = FellowshipData.GetFellowshipMapID(tbPlayerInfo.id)

    self.attraction = tbPlayerInfo.attraction
    self.szMapName = FellowshipData.GetWhereDesc(nMapID, self.tbRoleEntryInfo, self.attraction)

    UIHelper.SetString(self.LabelMapName, self.szMapName, 5)
    UIHelper.LayoutDoLayout(self.ImgFriendLabelTips)
    UIHelper.SetEnable(self.BtnPlaceLabel, self.szMapName ~= UIHelper.LimitUtf8Len(self.szMapName, 5))
    UIHelper.SetString(self.LabelSignature, UIHelper.GBKToUTF8(tbRoleEntryInfo.szSignature))
    UIHelper.SetVisible(self.LabelSignature, tbRoleEntryInfo.szSignature ~= "")

    local nLevel, fP = FellowshipData.GetAttractionLevel(tbPlayerInfo.attraction)
	local szLevelName = g_tStrings.tAttractionLevel[nLevel]

    UIHelper.SetString(self.LabelAttractionName, szLevelName)
    UIHelper.SetString(self.LabelAttraction, string.format("(%d)", tbPlayerInfo.attraction))

    for i = 1, 7, 1 do
        if i < nLevel then
            UIHelper.SetProgressBarPercent(self.tImgHeart[i], 100)
        elseif i == nLevel then
            UIHelper.SetProgressBarPercent(self.tImgHeart[i], fP)
        else
            UIHelper.SetProgressBarPercent(self.tImgHeart[i], 0)
        end
    end

    local tLine = UINameCardTab[tbRoleEntryInfo.nSkinID]
    if tLine then
        UIHelper.SetTexture(self.ImgBgTop,tLine.szVisitCardPath)
    end

    self:UpdatePersonLabel()
    self:UpdatePlayerCardInfo()
    UIHelper.LayoutDoLayout(self.LayoutSite)
end

function UIPlayerPop:UpdatePlayerCardInfo()
    local tbPlayerCard = self.tbPlayerCard
    if tbPlayerCard then
        UIHelper.SetVisible(self.ImgTwoway, tbPlayerCard.bIsTwoWayFriend == 1)

        if tbPlayerCard.dwLandMapID and tbPlayerCard.nLandCopyIndex and tbPlayerCard.nLandIndex
        and tbPlayerCard.dwLandMapID ~= 0 and tbPlayerCard.nLandCopyIndex ~= 0 then
            UIHelper.SetVisible(self.BtnGotoLand, true)
            local tInfo = Table_GetMapLandInfo(tbPlayerCard.dwLandMapID, tbPlayerCard.nLandIndex)
            if tInfo then
                UIHelper.SetSpriteFrame(self.ImgIconLand, tInfo.szMobileIconPath)
            end
        else
            UIHelper.SetVisible(self.BtnGotoLand, false)
        end

        if tbPlayerCard.dwPHomeMapID and tbPlayerCard.nPHomeCopyIndex and tbPlayerCard.dwPHomeSkin
        and tbPlayerCard.dwPHomeMapID ~= 0 and tbPlayerCard.nPHomeCopyIndex ~= 0 then
            UIHelper.SetVisible(self.BtnGotoPrivateLand, true)
            local tInfo = Table_GetMapLandInfo(tbPlayerCard.dwPHomeMapID, tbPlayerCard.dwPHomeSkin)
            if tInfo then
                UIHelper.SetSpriteFrame(self.ImgIconPrivateLand, tInfo.szMobileIconPath)
            end
        else
            UIHelper.SetVisible(self.BtnGotoPrivateLand, false)
        end

        UIHelper.SetVisible(self.LayoutPlayerIcon, true)
        UIHelper.LayoutDoLayout(self.LayoutSite)
    else
        UIHelper.SetVisible(self.LayoutPlayerIcon, false)
    end
end

function UIPlayerPop:ShowMentorInfo(tbFellowshipInfo, tbPlayerCard)
    --UIHelper.SetVisible(self.WidgetEquip, false)
    UIHelper.SetVisible(self.LayoutPlayerIcon, false)
    UIHelper.SetVisible(self.WidgetLogInTime, true)
    UIHelper.SetVisible(self.WidgetStudentNum1, true)
    UIHelper.SetVisible(self.ImgCamp, false)

    --拜师时间
    local t = TimeToDate(tbFellowshipInfo.nCreateTime)
	local szText = FormatString(g_tStrings.STR_TIME_1, t.year - 2000, t.month, t.day)

    --上次登录时间
    local szTime = ""
    if tbFellowshipInfo.bOnLine then
        szTime = g_tStrings.STR_GUILD_ONLINE
    else
        if tbFellowshipInfo.nOfflineTime < 0 then tbFellowshipInfo.nOfflineTime = 0 end
        local nYear = math.floor(tbFellowshipInfo.nOfflineTime / (3600 * 24 * 365))
        if tbFellowshipInfo.bDelete then
            szTime = g_tStrings.STR_NO_TIME
        elseif nYear > 0 then
            szTime = FormatString(g_tStrings.STR_GUILD_TIME_YEAR_BEFORE, nYear)
        else
            local nD = math.floor(tbFellowshipInfo.nOfflineTime / (3600 * 24))
            if nD > 0 then
                szTime = FormatString(g_tStrings.STR_GUILD_TIME_DAY_BEFORE, nD)
            else
                local nH = math.floor(tbFellowshipInfo.nOfflineTime / 3600)
                if nH > 0 then
                    szTime = FormatString(g_tStrings.STR_GUILD_TIME_HOUR_BEFORE, nH)
                else
                    szTime = g_tStrings.STR_GUILD_TIME_IN_ONE_HOUR
                end
            end
        end
        szTime = szTime .. "登录"
    end

    UIHelper.SetString(self.LableTime1,szText)
    UIHelper.SetString(self.LableLogIn1,szTime)
    UIHelper.SetVisible(self.WidgetStudentNum1, tbFellowshipInfo.nMentorValue and tbFellowshipInfo.bDirectM ~= false)
    UIHelper.SetString(self.LabelStudentNum1, tbFellowshipInfo.nMentorValue)
end

function UIPlayerPop:SetbOpenPanelClose()
    self.bOpenPanelClose = false
end

function UIPlayerPop:UpdateTeamData(tMemberInfo)
    UIHelper.SetVisible(self.LayoutSite, true)
    UIHelper.SetVisible(self.LabelSignature, false)
    UIHelper.SetVisible(self.LayoutPlayerIcon, false)
    UIHelper.SetVisible(self.LabelAttractionName, false)
    UIHelper.SetVisible(self.LabelAttraction, false)
    UIHelper.SetVisible(self.BtnFirendLabel, false)
    UIHelper.SetVisible(self.LableGroup, false)
    UIHelper.SetVisible(self.LableGroupTitle, false)
    UIHelper.SetVisible(self.LabelEquip, true)
    UIHelper.SetVisible(self.LabelEquipGrade, true)
    UIHelper.SetString(self.LabelEquipGrade, tMemberInfo.nEquipScore)

    local szMapName
    if not tMemberInfo.bIsOnLine then
        szMapName = g_tStrings.UNKNOWN_MAP
    else
        szMapName = UIHelper.GBKToUTF8(Table_GetMapName(tMemberInfo.dwMapID))
    end
    self.szMapName = szMapName
    UIHelper.SetString(self.LabelMapName, szMapName)
    UIHelper.LayoutDoLayout(self.LayoutSite)
    UIHelper.LayoutDoLayout(self.LayoutPlayer)
    self:UpdateTipsPos()
end

function UIPlayerPop:CreateTeamMarkMenu(tbMenuConfig, layoutParent)
    local toggleScript = UIHelper.AddPrefab(PREFAB_ID.WidgetInteractionMoreTog, layoutParent)
    UIHelper.SetString(toggleScript.LableMpore, tbMenuConfig.szName)
    UIHelper.SetSelected(toggleScript.Toggle, false)
    UIHelper.ToggleGroupAddToggle(self.TogGroupMenu, toggleScript.Toggle)

    toggleScript.Toggle:setTouchDownHideTips(false)
    UIHelper.BindUIEvent(toggleScript.Toggle, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            local fnTipsClose = function()
                UIHelper.SetSelected(toggleScript.Toggle, false)
            end
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetInteractionMorePop)
            local tips, tipsScriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetTipTargetgetMark, toggleScript._rootNode, TipsLayoutDir.BOTTOM_LEFT, tbMenuConfig.dwMemberID, fnTipsClose)

            local _, nHeight = UIHelper.GetContentSize(tipsScriptView._rootNode)
            local _, _, nRootYMin = UIHelper.GetNodeEdgeXY(self.LayoutPlayer)
            local _, _, nToggleYMin = UIHelper.GetNodeEdgeXY(toggleScript._rootNode)
            tips:SetOffset(0, -(nHeight-(nToggleYMin-nRootYMin)))
            tips:ShowNodeTips(toggleScript._rootNode)
        else
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipTargetgetMark)
        end
    end)
end

function UIPlayerPop:ShowPlaceLabelTips(nIndex)
    if (nIndex == tbShowLabelTipIndex.PlayerIcon and self.bShowPraiseStatus) or
    (nIndex == tbShowLabelTipIndex.Twoway and self.bShowLabelTips) or
    (nIndex == tbShowLabelTipIndex.PlaceLabel and self.bShowPlaceLabelTips) then
        self.bShowPraiseStatus = false
        self.bShowLabelTips = false
        self.bShowPlaceLabelTips = false
    else
        self.bShowPraiseStatus = nIndex == tbShowLabelTipIndex.PlayerIcon
        self.bShowLabelTips = nIndex == tbShowLabelTipIndex.Twoway
        self.bShowPlaceLabelTips = nIndex == tbShowLabelTipIndex.PlaceLabel
    end

    if self.bShowPraiseStatus then
        self.PraiseStatusScript = self.PraiseStatusScript or UIHelper.AddPrefab(PREFAB_ID.WidgetPraiseStatus, self.WidgetPraiseStatus, self.tSortPraiseinfo or {})
    end
    UIHelper.SetVisible(self.WidgetPraiseStatus, self.bShowPraiseStatus)

    if self.bShowPraiseStatus then
        self:AdjustPos()
    end

    self.FriendLabelTipsScript = self.FriendLabelTipsScript or UIHelper.AddPrefab(PREFAB_ID.WidgetFriendLabelTips, self.WidgetFriendLabelTips, "你与对方互为好友")
    UIHelper.SetVisible(self.WidgetFriendLabelTips, self.bShowLabelTips)

    UIHelper.SetVisible(self.WidgetPlaceLabelTips, self.bShowPlaceLabelTips)
    UIHelper.SetRichText(self.LabelPlaceTips, self.szMapName)
end

function UIPlayerPop:SyncArenaCorpsData()
    SyncCorpsList(GetClientPlayer().dwID)
    ArenaData.SyncAllCorpsBaseInfo()        --名剑相关
end

function UIPlayerPop:SetPersonalVisible(bVisible)
    if bVisible ~= nil then
        FellowshipData.bDefaultPersonal = bVisible
    end

    if FellowshipData.bDefaultPersonal and not GDAPI_CanPeekPersonalCard(self.szTargetGlobalID) then
        FellowshipData.bDefaultPersonal = false
        TipsHelper.ShowNormalTip("当前模式下无法查看名片")
    end

    UIHelper.SetVisible(self.WidgetPersonalCardTips, FellowshipData.bDefaultPersonal)
    UIHelper.SetVisible(self.LayoutPlayer, not FellowshipData.bDefaultPersonal)
end

function UIPlayerPop:ShowTop(bVisible)
    UIHelper.SetVisible(self.WidgetTop, bVisible)
    UIHelper.LayoutDoLayout(self.LayoutPlayer)
    self:UpdateTipsPos()
end

function UIPlayerPop:ShowTopSimple(bVisible, szName)
    UIHelper.SetString(self.LableNameSimple, szName or "", 12)
    UIHelper.SetVisible(self.WidgetTopSimple, bVisible)
    UIHelper.LayoutDoLayout(self.LayoutPlayer)
    self:UpdateTipsPos()

    UIHelper.BindUIEvent(self.BtnSendNameSimple, EventType.OnClick, function()
        ChatHelper.SendPlayerToChat(szName)
    end)
end

function UIPlayerPop:SetShareVis(bVis)
    UIHelper.SetVisible(self.BtnShare, bVis)
end

function UIPlayerPop:SetEquipVis(bVis)
    UIHelper.SetVisible(self.LabelEquip, bVis)
    UIHelper.SetVisible(self.LabelEquipGrade, bVis)
end

function UIPlayerPop:ShowCommandMemberInfo(tbInfo)
    UIHelper.SetVisible(self.LayoutPlayer, true)
    UIHelper.SetVisible(self.WidgetEmpty, false)
    UIHelper.SetString(self.LableName, UIHelper.GBKToUTF8(tbInfo.szName))
    UIHelper.SetString(self.LableGroup, UIHelper.GBKToUTF8(tbInfo.szTName))
    CampData.SetUICampImg(self.ImgCamp, tbInfo.nCamp, nil, true)
    UIHelper.SetString(self.LableLevel, tbInfo.nLevel)
    UIHelper.SetSpriteFrame(self.ImgForceID, PlayerForceID2SchoolImg2[tbInfo.dwForceID])


    UIHelper.RemoveAllChildren(self.WidgetPlayerHead)
    local scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead_108, self.WidgetPlayerHead, tbInfo.id)
    scriptHead:SetHeadInfo(tbInfo.id, 0, nil, tbInfo.nForceID)

    UIHelper.SetVisible(self.LabelEquip, false)
    UIHelper.SetVisible(self.LabelEquipGrade, false)

    UIHelper.LayoutDoLayout(self.LayoutMenu)
    UIHelper.LayoutDoLayout(self.widgetPlayerMenu)
    UIHelper.LayoutDoLayout(self.LayoutPlayer)
    self:UpdateTipsPos()
end

function UIPlayerPop:ShowCommandAddMemberInfo(tbInfo)
    UIHelper.SetVisible(self.LayoutPlayer, true)
    UIHelper.SetVisible(self.WidgetEmpty, false)
    UIHelper.SetString(self.LableName, UIHelper.GBKToUTF8(tbInfo.szName))
    -- UIHelper.SetString(self.LableGroup, UIHelper.GBKToUTF8(tbInfo.szTName))
    -- CampData.SetUICampImg(self.ImgCamp, tbInfo.nCamp, nil, true)
    UIHelper.SetString(self.LableLevel, tbInfo.nLevel)
    UIHelper.SetSpriteFrame(self.ImgForceID, PlayerForceID2SchoolImg2[tbInfo.nForceID])


    UIHelper.SetVisible(self.ImgCamp, false)

    UIHelper.SetVisible(self.LableGroup,false)
    UIHelper.SetVisible(self.LableGroupTitle, false)
    UIHelper.SetVisible(self.LabelEquip, false)
    UIHelper.SetVisible(self.LabelEquipGrade, false)

    UIHelper.RemoveAllChildren(self.WidgetPlayerHead)
    local scriptHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead_108, self.WidgetPlayerHead, tbInfo.id)
    scriptHead:SetHeadInfo(tbInfo.id, 0, nil, tbInfo.nForceID)

    UIHelper.LayoutDoLayout(self.LayoutMenu)
    UIHelper.LayoutDoLayout(self.widgetPlayerMenu)
    UIHelper.LayoutDoLayout(self.LayoutPlayer)
    self:UpdateTipsPos()
end

function UIPlayerPop:AdjustPos()
    --Timer.Add(self, 0.3, function()
        local nWorldPosX = UIHelper.GetWorldPositionX(self.WidgetPraiseStatus)
        local nWidth = UIHelper.GetWidth(self.WidgetPraiseStatus)
        local nPos = nWorldPosX + nWidth / 2
        local nScreenWidth = UIHelper.GetDesignResolutionSize().width

        if nPos > nScreenWidth then
            local nDelta = nPos - nScreenWidth - 10
            LOG.INFO("QH, nDelta = "..nDelta)
            UIHelper.SetPositionX(self._rootNode, UIHelper.GetPositionX(self._rootNode) - nDelta)
        end
    --end)
end

--- 动态加载点赞
function UIPlayerPop:SortPraiseInfo()
    local labels = self.tbPlayerCard.Praiseinfo or {}
    local tbInfo = {}
    local tRes = Table_GetAllPersonLabel()
    for _, info in ipairs(tRes) do
        local id = info.id + 1
        tbInfo[id] = {}
        tbInfo[id].id = info.id
        tbInfo[id].info = info
        local nCount = labels[info.id] or 0
        tbInfo[id].nCount = nCount
        tbInfo[id].nLevel = PersonLabel_GetLevel(nCount, info.id)
    end

    local function fnSort(tA, tB)
        if tA.nLevel == tB.nLevel then
            return tA.info.queue < tB.info.queue
        else
            return tA.nLevel > tB.nLevel
        end
	end
    table.sort(tbInfo, fnSort)
    return tbInfo
end

return UIPlayerPop
