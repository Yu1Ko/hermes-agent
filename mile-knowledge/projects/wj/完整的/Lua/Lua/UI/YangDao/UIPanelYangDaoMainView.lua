-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIPanelYangDaoMainView
-- Date: 2026-03-06 17:00:15
-- Desc: 扬刀大会-报名界面 PanelYangDaoMain
-- ---------------------------------------------------------------------------------

local UIPanelYangDaoMainView = class("UIPanelYangDaoMainView")

-- NOTE: 维护活动奖励同时还要修改新花萼楼界面相关的配置表：client\ui\Scheme\Case\OperationActivity\SimpleOperationConfig.txt，相关活动ID：239
local ARENA_TOWER_ACTIVITY = 818

function UIPanelYangDaoMainView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.LayoutCoins, CurrencyType.TianJiToken)
        UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.LayoutCoins, CurrencyType.ArenaTowerAward)
        UIHelper.CascadeDoLayoutDoWidget(UIHelper.GetParent(self.LayoutCoins), true, true)
    end

    self.dwMapID = BATTLE_FIELD_MAP_ID.QING_XIAO_SHAN
    self:UpdateInfo()

    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
    local nPackID = PakDownloadMgr.GetMapResPackID(self.dwMapID)
    scriptDownload:OnInitWithPackID(nPackID)
end

function UIPanelYangDaoMainView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    UIHelper.StopVideo(self.VideoPlayer)
end

function UIPanelYangDaoMainView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnRule, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelBattleFieldRulesNew, self.dwMapID)
    end)
    UIHelper.BindUIEvent(self.BtnEquipShop, EventType.OnClick, function()
        ArenaTowerData.OpenArenaTowerAwardShop()
    end)
    UIHelper.BindUIEvent(self.BtnChat, EventType.OnClick, function()
        ChatHelper.Chat(UI_Chat_Channel.Team)
    end)
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnVideo, EventType.OnClick, function()
        if self.szFileName then
            local bImg = UIHelper.GetVisible(self.ImgVideo)
            UIMgr.Open(VIEW_ID.PanelTutorialFullscreenPic, bImg, self.szFileName)
        elseif self.szVideoUrl then
            local tbConfig = {}
            tbConfig.bNet = true
            if Platform.IsMobile() and App_GetNetMode() ~= NET_MODE.WIFI then
                local dialog = UIHelper.ShowConfirm("当前为非Wi-Fi（正在使用非WiFi网络），播放将消耗流量   取消 / 继续播放？", function ()
                    MovieMgr.PlayVideo(self.szVideoUrl, tbConfig, {})
                end, nil)
            else
               MovieMgr.PlayVideo(self.szVideoUrl, tbConfig, {})
            end
        end
    end)
    UIHelper.BindUIEvent(self.BtnRecruit, EventType.OnClick, function()
        local tRecruitInfo = Table_GetTeamInfoByMapID(self.dwMapID)
        if tRecruitInfo then
            UIMgr.Open(VIEW_ID.PanelTeam, 1, nil, tRecruitInfo.dwID)
        else
            TipsHelper.ShowNormalTip("暂未开放")
        end
    end)
    UIHelper.BindUIEvent(self.BtnTeamMatching, EventType.OnClick, function()
        if not PakDownloadMgr.UserCheckDownloadMapRes(self.dwMapID, nil, nil, nil, "扬刀大会") then
            return
        end

        local player = GetClientPlayer()
        if not player then
            return
        end

        if not TeamData.IsInParty() then
            local tRecruitInfo = Table_GetTeamInfoByMapID(self.dwMapID)
            if tRecruitInfo then
                UIMgr.Open(VIEW_ID.PanelTeam, 1, nil, tRecruitInfo.dwID)
            else
                TipsHelper.ShowNormalTip("请先组队再点击前往")
            end
            return
        end
        if not TeamData.IsTeamLeader() then
            TipsHelper.ShowNormalTip("只有队长才能进行前往操作")
            return
        end

        local nTeamMember = 0
        TeamData.Generator(function(dwID, tMemberInfo)
            nTeamMember = nTeamMember + 1
        end)
        if nTeamMember ~= ArenaTowerData.BATTLE_PLAYER_COUNT then
            TipsHelper.ShowNormalTip("队伍人数不符合扬刀大会三名成员的人数要求，无法参与扬刀大会")
            return
        end

        -- NOTE: 由于扬刀大会数据周重置需要在远程数据块加载完成后才能执行，但能触发数据加载的时机只有打开界面、进入地图时，如果玩家不开界面就重置不了数据，局外检查的队伍进度不准
        -- UIHelper.SetButtonState(self.BtnTeamMatching, BTN_STATE.Disable, "正在拉取队友数据...")
        -- ArenaTowerData.ApplyMemberRemoteData()
        -- self.fnApplyMemberRemoteDataCallback = function()
        --     self.fnApplyMemberRemoteDataCallback = nil
        --     UIHelper.SetButtonState(self.BtnTeamMatching, BTN_STATE.Normal)
        --     if not self:CheckMemberSetupValid() then
        --         return
        --     end

        --     local nDiffMode = self:GetDiffMode()
        --     local bInQueue = BattleFieldQueueData.IsInBattleFieldQueue(self.dwMapID)
        --     if not bInQueue then
        --         local bPractice = nDiffMode == ArenaTowerDiffMode.Practice
        --         if not BattleFieldQueueData.EnterBattleFieldQueue(self.dwMapID, BATTLEFIELD_MAP_TYPE.ARENA_TOWER, true, false, bPractice) then
        --             UIHelper.SetButtonState(self.BtnTeamMatching, BTN_STATE.Normal)
        --         end
        --     end
        -- end

        if not self:CheckMemberSetupValid() then
            return
        end

        local nDiffMode = self:GetDiffMode()
        local bInQueue = BattleFieldQueueData.IsInBattleFieldQueue(self.dwMapID)
        if not bInQueue then
            local bPractice = nDiffMode == ArenaTowerDiffMode.Practice
            if not BattleFieldQueueData.EnterBattleFieldQueue(self.dwMapID, BATTLEFIELD_MAP_TYPE.ARENA_TOWER, true, false, bPractice) then
                UIHelper.SetButtonState(self.BtnTeamMatching, BTN_STATE.Normal)
            end
        end
    end)
    UIHelper.BindUIEvent(self.BtnRoomMatching, EventType.OnClick, function()
        if not PakDownloadMgr.UserCheckDownloadMapRes(self.dwMapID, nil, nil, nil, "扬刀大会") then
            return
        end

        -- NOTE: 跨服取不到其他玩家的远程数据，这里不拦了，进图之后匹配机器人的时候脚本再拦
        -- UIHelper.SetButtonState(self.BtnRoomMatching, BTN_STATE.Disable, "正在拉取队友数据...")
        -- ArenaTowerData.ApplyMemberRemoteData()
        -- self.fnApplyMemberRemoteDataCallback = function()
        --     self.fnApplyMemberRemoteDataCallback = nil
        --     UIHelper.SetButtonState(self.BtnRoomMatching, BTN_STATE.Normal)
        --     if not self:CheckMemberSetupValid() then
        --         return
        --     end

        --     local nDiffMode = self:GetDiffMode()
        --     local bInQueue = BattleFieldQueueData.IsInBattleFieldQueue(self.dwMapID)
        --     if not bInQueue then
        --         local bPractice = nDiffMode == ArenaTowerDiffMode.Practice
        --         if not BattleFieldQueueData.EnterBattleFieldQueue(self.dwMapID, BATTLEFIELD_MAP_TYPE.ARENA_TOWER, false, true, bPractice) then
        --             UIHelper.SetButtonState(self.BtnRoomMatching, BTN_STATE.Normal)
        --         end
        --     end
        -- end

        if not self:CheckMemberSetupValid() then
            return
        end

        local nDiffMode = self:GetDiffMode()
        local bInQueue = BattleFieldQueueData.IsInBattleFieldQueue(self.dwMapID)
        if not bInQueue then
            local bPractice = nDiffMode == ArenaTowerDiffMode.Practice
            if not BattleFieldQueueData.EnterBattleFieldQueue(self.dwMapID, BATTLEFIELD_MAP_TYPE.ARENA_TOWER, false, true, bPractice) then
                UIHelper.SetButtonState(self.BtnRoomMatching, BTN_STATE.Normal)
            end
        end
    end)
    UIHelper.BindUIEvent(self.BtnCancelMatching, EventType.OnClick, function()
        UIHelper.SetButtonState(self.BtnCancelMatching, BTN_STATE.Disable)
        if BattleFieldQueueData.IsInBattleFieldQueue(self.dwMapID) then
            BattleFieldQueueData.DoLeaveBattleFieldQueue(self.dwMapID)
        end
    end)

    UIHelper.BindUIEvent(self.BtnMatchingRule, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnMatchingRule, TipsLayoutDir.TOP_RIGHT, g_tStrings.ARENA_TOWER_MATCH_RULE)
    end)
    UIHelper.SetClickInterval(self.TogPractice, 0)
    UIHelper.BindUIEvent(self.TogPractice, EventType.OnClick, function()
        UIHelper.SetSelected(self.TogPractice, true, false)
        UIHelper.SetSelected(self.TogChallenge, false, false)
        if ArenaTowerData.GetSelDiffMode() == ArenaTowerDiffMode.Practice then
            return
        end
        if ArenaTowerData.bDisableSwitchConfirm then
            self:SetSelDiffMode(ArenaTowerDiffMode.Practice)
        else
            local dialog = UIHelper.ShowConfirm(g_tStrings.ARENA_TOWER_SWITCH_PRACTICE_CONFIRM, function()
                self:SetSelDiffMode(ArenaTowerDiffMode.Practice)
            end, function()
                UIHelper.SetSelected(self.TogPractice, false, false)
                UIHelper.SetSelected(self.TogChallenge, true, false)
            end, true)
            dialog:ShowTogOption("本次登录不再提示", ArenaTowerData.bDisableSwitchConfirm)
            dialog:SetTogSelectedFunc(function(bOption)
                ArenaTowerData.bDisableSwitchConfirm = true
            end)
        end
    end)
    UIHelper.SetClickInterval(self.TogChallenge, 0)
    UIHelper.BindUIEvent(self.TogChallenge, EventType.OnClick, function()
        UIHelper.SetSelected(self.TogPractice, false, false)
        UIHelper.SetSelected(self.TogChallenge, true, false)
        if ArenaTowerData.GetSelDiffMode() == ArenaTowerDiffMode.Challenge then
            return
        end
        if ArenaTowerData.bDisableSwitchConfirm then
            self:SetSelDiffMode(ArenaTowerDiffMode.Challenge)
        else
            local dialog = UIHelper.ShowConfirm(g_tStrings.ARENA_TOWER_SWITCH_CHALLENGE_CONFIRM, function()
                self:SetSelDiffMode(ArenaTowerDiffMode.Challenge)
            end, function()
                UIHelper.SetSelected(self.TogPractice, true, false)
                UIHelper.SetSelected(self.TogChallenge, false, false)
            end, true)
            dialog:ShowTogOption("本次登录不再提示", ArenaTowerData.bDisableSwitchConfirm)
            dialog:SetTogSelectedFunc(function(bOption)
                ArenaTowerData.bDisableSwitchConfirm = true
            end)
        end
    end)
    UIHelper.BindUIEvent(self.BtnOverview, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelYangDaoOverview)
    end)
    UIHelper.BindUIEvent(self.BtnShare, EventType.OnClick, function()
        local nDiffMode = self:GetDiffMode()
        local szDiffMode = ""
        if nDiffMode == ArenaTowerDiffMode.Practice then
            szDiffMode = "普通模式"
        elseif nDiffMode == ArenaTowerDiffMode.Challenge then
            szDiffMode = "挑战模式"
        end
        local szName = "扬刀大会" .. szDiffMode
        ChatData.ClearChatInputText()
        -- ChatHelper.SendEventLinkToChat(szName, string.format("ArenaTower/%d", self.dwMapID))
        ChatHelper.SendEventLinkToChat(szName, "ArenaTower")
    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function()
        local dialog = UIHelper.ShowConfirm(g_tStrings.ARENA_TOWER_RESET_PROGRESS_CONFIRM, function()
            ArenaTowerData.ResetProgress()
        end, nil, true)
    end)
    UIHelper.BindUIEvent(self.BtnDifficultyDown, EventType.OnClick, function()
        local dialog = UIHelper.ShowConfirm(g_tStrings.ARENA_TOWER_SWITCH_PRACTICE_CONFIRM, function()
            ArenaTowerData.DifficultyDown()
        end, nil, true)
    end)
end

function UIPanelYangDaoMainView:RegEvent()
    --战场状态更新（匹配状态等）
    Event.Reg(self, "BATTLE_FIELD_STATE_UPDATE", function()
        self:UpdateBtnState()
    end)

    Event.Reg(self, "JOIN_BATTLE_FIELD_QUEUE", function(dwMapID, nCode, dwRoleID, szRoleName)
        --若加入队列失败，则更新按钮状态
        if nCode ~= BATTLE_FIELD_RESULT_CODE.SUCCESS then
            self:UpdateBtnState()
        end
    end)

    -- 队伍相关事件
    Event.Reg(self, "PARTY_ADD_MEMBER", function()
        self:UpdateBtnState()
    end)
    Event.Reg(self, "PARTY_DELETE_MEMBER", function()
        self:UpdateBtnState()
    end)
    Event.Reg(self, "TEAM_AUTHORITY_CHANGED", function()
        self:UpdateBtnState()
    end)
    Event.Reg(self, "PARTY_DISBAND", function()
        self:UpdateBtnState()
    end)
    -- 跨服房间相关事件
    Event.Reg(self, "CREATE_GLOBAL_ROOM", function()
        self:UpdateBtnState()
    end)
    Event.Reg(self, "JOIN_GLOBAL_ROOM", function()
        self:UpdateBtnState()
    end)
    Event.Reg(self, "LEAVE_GLOBAL_ROOM", function()
        self:UpdateBtnState()
    end)
    Event.Reg(self, "GLOBAL_ROOM_BASE_INFO", function()
        self:UpdateBtnState()
    end)
    Event.Reg(self, "GLOBAL_ROOM_MEMBER_CHANGE", function()
        self:UpdateBtnState()
    end)
    Event.Reg(self, "GLOBAL_ROOM_DETAIL_INFO", function()
        self:UpdateBtnState()
    end)

    Event.Reg(self, EventType.OnArenaTowerDiffProgressUpdate, function()
        self:UpdateInfo()
    end)
    Event.Reg(self, EventType.OnArenaTowerApplyMemberRemoteData, function()
        if self.fnApplyMemberRemoteDataCallback then
            self.fnApplyMemberRemoteDataCallback()
        end
    end)
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.scriptIcon then
            self.scriptIcon:SetSelected(false)
        end
    end)
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        Timer.AddFrame(self, 5, function()
            UIHelper.LayoutDoLayout(self.LayoutBtn)
            UIHelper.LayoutDoLayout(self.LayoutLabel)
        end)
    end)
end

function UIPanelYangDaoMainView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelYangDaoMainView:UpdateInfo()
    if self.bSetSelDiffMode then
        return
    end

    self:UpdateBtnState()

    local nDiffMode, nLevelProgress, _, _ = ArenaTowerData.GetBaseInfo()
    local szBgPath = string.format("Texture\\YangDao\\LevelSceneImgs\\Bg_Level%02d.png", nLevelProgress or 0)
    UIHelper.SetTexture(self.ImgPicBg, szBgPath, nil, function()
        UIHelper.UpdateMask(self.MaskBg)
    end)

    if nLevelProgress > 0 then
        UIHelper.SetVisible(self.WidgetDifficultyChoose, false)
        UIHelper.SetVisible(self.WidgetProgress, true)
        self:UpdateCurrentLevel(nDiffMode, nLevelProgress)
    else
        local nSelDiffMode = ArenaTowerData.GetSelDiffMode()
        UIHelper.SetVisible(self.WidgetDifficultyChoose, true)
        UIHelper.SetVisible(self.WidgetProgress, false)
        if nSelDiffMode == ArenaTowerDiffMode.Practice then
            UIHelper.SetSelected(self.TogPractice, true, false)
            UIHelper.SetSelected(self.TogChallenge, false, false)
        elseif nSelDiffMode == ArenaTowerDiffMode.Challenge then
            UIHelper.SetSelected(self.TogPractice, false, false)
            UIHelper.SetSelected(self.TogChallenge, true, false)
        end
    end
    UIHelper.LayoutDoLayout(self.WidgetAnchorBottom)

    self:UpdateReward()
end

function UIPanelYangDaoMainView:SetSelDiffMode(nDiffMode)
    self.bSetSelDiffMode = true
    ArenaTowerData.SetSelDiffMode(nDiffMode)
    self.bSetSelDiffMode = false
end

function UIPanelYangDaoMainView:UpdateReward()
    -- local dwGoodsID = 6262
    -- local tbVideoList = CoinShop_GetAllLimitVideo(dwGoodsID)
    -- if #tbVideoList > 0 then
    --     self:InitRewardVideo(tbVideoList[1].szUrl, true)
    -- end

    -- local szImgPath = "TeachBox/Teach_21.png"
    local szVideoPath = "Video\\%s\\YangDao\\YangDaoReward.bk2"
    self:InitRewardVideo(szVideoPath)

    local function ModifyItemPositionY(itemScript)
        local _, _, _, nScrollViewYMax = UIHelper.GetNodeEdgeXY(self.ScrolViewItemList)
        local _, _, _, nItemYMax = UIHelper.GetNodeEdgeXY(itemScript._rootNode)
        UIHelper.SetPositionY(itemScript._rootNode, nScrollViewYMax - nItemYMax)
    end

    UIHelper.RemoveAllChildren(self.ScrolViewItemList)
    local tRewardList = ActivityData.GetAwardInfo(ARENA_TOWER_ACTIVITY)
    for nIndex, tInfo in ipairs(tRewardList or {}) do
        if type(tInfo.szCount) == "number" then
            local szName = CurrencyNameToType[tInfo.szType]
            if szName then
                local nCount = tInfo.szCount
                if szName == g_tStrings.Quest.STR_QUEST_CAN_GET_MONEY then
                    nCount = nCount * 10000
                end
                local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.ScrolViewItemList)
                ModifyItemPositionY(itemScript)
                itemScript:OnInitCurrency(szName, nCount)
                itemScript:SetSelectChangeCallback(function(_, bSelected)
                    if bSelected then
                        if self.scriptIcon then
                            self.scriptIcon:SetSelected(false)
                        end
                        local _, scriptTip = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, itemScript._rootNode)
                        scriptTip:OnInitCurrency(szName, nCount)
                        self.scriptIcon = itemScript
                    else
                        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
                        self.scriptIcon = nil
                    end
                end)
            end
        elseif type(tInfo.szCount) == "string" then
            local tInfo = string.split(tInfo.szCount, ";")
            local dwTabType = tonumber(tInfo[1])
            local dwIndex = tonumber(tInfo[2])
            local nCount = tonumber(tInfo[3])
            local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.ScrolViewItemList)
            ModifyItemPositionY(itemScript)
            itemScript:OnInitWithTabID(dwTabType, dwIndex)
            if nCount > 1 then
                itemScript:SetLabelCount(nCount)
            end
            itemScript:SetSelectChangeCallback(function(_, bSelected)
                if bSelected then
                    if self.scriptIcon then
                        self.scriptIcon:SetSelected(false)
                    end
                    local tips, scriptTip = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, itemScript._rootNode)
                    scriptTip:OnInitWithTabID(dwTabType, dwIndex)
                    self.scriptIcon = itemScript
                else
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
                    self.scriptIcon = nil
                end
            end)
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrolViewItemList)
    UIHelper.ScrollToLeft(self.ScrolViewItemList, 0)
end

function UIPanelYangDaoMainView:InitRewardVideo(szFileName, bUrl)
    self.szFileName = nil
    self.szVideoUrl = nil
    if not szFileName then
        return
    end

    UIHelper.SetVisible(self.ImgPlayIcon, false)
    UIHelper.SetVisible(self.ImgVideo, false)
    UIHelper.SetVisible(self.VideoPlayer, false)

    if bUrl then
        if Platform.IsMobile() and App_GetNetMode() ~= NET_MODE.WIFI then
            UIHelper.SetVisible(self.ImgPlayIcon, true)
            UIHelper.SetVisible(self.ImgVideo, true)
        else
            local szUrl = MovieMgr.ParseStaticUrl(szFileName)
            UIHelper.SetVisible(self.VideoPlayer, true)
            self.VideoPlayer:setUserInputEnabled(false)  -- 禁止暂停
            UIHelper.SetVideoPlayerModel(self.VideoPlayer, VIDEOPLAYER_MODEL.FFMPEG)
            UIHelper.SetVideoLooping(self.VideoPlayer, true)
            UIHelper.PlayVideo(self.VideoPlayer, szUrl, false, function(nVideoPlayerEvent, szMsg)
                if nVideoPlayerEvent == ccui.VideoPlayerEvent.COMPLETED then
                elseif nVideoPlayerEvent == ccui.VideoPlayerEvent.ERROR then
                    TipsHelper.ShowNormalTip("视频播放错误："..tostring(szMsg))
                end
            end)
        end
        self.szVideoUrl = szFileName
        return
    end

    local szPostfix
    for szPart in string.gmatch(szFileName, "[^%.]+") do
        szPostfix = szPart
    end

    if szPostfix == "png" then
        -- 顺便兼容一下图片
        UIHelper.SetVisible(self.ImgVideo, true)
        szFileName = string.format("Resource/%s", szFileName)
        self.szFileName = szFileName
        UIHelper.SetTexture(self.ImgVideo, szFileName)
    elseif szPostfix == "bk2" then
        UIHelper.SetVisible(self.VideoPlayer, true)
        self.VideoPlayer:setUserInputEnabled(false)  -- 禁止暂停
        UIHelper.SetVideoPlayerModel(self.VideoPlayer, VIDEOPLAYER_MODEL.BINK)
        UIHelper.SetVideoLooping(self.VideoPlayer, true)
        szFileName = UIHelper.ParseVideoPlayerFile(szFileName, VIDEOPLAYER_MODEL.BINK)
        szFileName = string.format(szFileName, Platform.IsMobile() and "MOBILE" or "PC")
        UIHelper.PlayVideo(self.VideoPlayer, szFileName, true, function(nVideoPlayerEvent, szMsg)
            if nVideoPlayerEvent == ccui.VideoPlayerEvent.COMPLETED then
            elseif nVideoPlayerEvent == ccui.VideoPlayerEvent.ERROR then
                TipsHelper.ShowNormalTip("视频播放错误："..tostring(szMsg))
            end
        end)
        self.szFileName = szFileName
    end
end

function UIPanelYangDaoMainView:UpdateBtnState()
    local bInQueue, _, _ = BattleFieldQueueData.IsInBattleFieldQueue(self.dwMapID)
    local bCanOperateMatch = not BattleFieldQueueData.IsInBattleFieldBlackList()
    local bCanJoinTeam = false
    local bCanJoinRoom = false

    local tbNotify = BattleFieldQueueData.GetBattleFieldNotify(self.dwMapID)
    local bMatchSuccess = tbNotify and tbNotify.nNotifyType == BATTLE_FIELD_NOTIFY_TYPE.JOIN_BATTLE_FIELD_QUEUE
    local bCanJoin = not bInQueue and not bMatchSuccess

    local player = GetClientPlayer()
    if player and player.IsInParty() and player.IsPartyLeader() then
        bCanJoinTeam = true
    end

    local szTeamTip, szRoomTip
    local bRoomOwner = RoomData.IsRoomOwner()
    local nRoomSize = RoomData.GetSize()
    if bRoomOwner and nRoomSize == ArenaTowerData.BATTLE_PLAYER_COUNT then
        bCanJoinRoom = true
    elseif not bRoomOwner then
        szRoomTip = "只有跨服房间房主才可进行跨服匹配"
    elseif nRoomSize ~= ArenaTowerData.BATTLE_PLAYER_COUNT then
        szRoomTip = "跨服房间中为三名成员才可进行跨服匹配"
    end

    if not bCanOperateMatch then
        local nTime = BattleFieldQueueData.GetBattleFieldBlackCoolTime()
        local szTime = BattleFieldQueueData.NumberBattleFieldTime(nTime)
        szTeamTip = FormatString(g_tStrings.STR_BATTLEFIELD_BLACK_LIST, szTime)
        szRoomTip = szTeamTip
    end

    UIHelper.SetVisible(self.WidgetContentNormal, bCanJoin)
    UIHelper.SetVisible(self.BtnCancelMatching, not bCanJoin)
    UIHelper.LayoutDoLayout(self.WidgetBtns)

    UIHelper.SetButtonState(self.BtnTeamMatching, bCanOperateMatch and BTN_STATE.Normal or BTN_STATE.Disable, szTeamTip) --bCanJoinTeam为false时也可点击组队按钮弹出组队界面
    UIHelper.SetButtonState(self.BtnRoomMatching, (bCanOperateMatch and bCanJoinRoom) and BTN_STATE.Normal or BTN_STATE.Disable, szRoomTip)
    UIHelper.SetButtonState(self.BtnCancelMatching, (not bMatchSuccess and (bCanJoinTeam or bCanJoinRoom)) and BTN_STATE.Normal or BTN_STATE.Disable) --队长才能取消
end

function UIPanelYangDaoMainView:UpdateCurrentLevel(nDiffMode, nLevelIndex)
    local tLevelConfig = ArenaTowerData.GetLevelConfig(nLevelIndex)
    if not tLevelConfig then
        return
    end

    UIHelper.SetVisible(self.WidgetBgPractice, nDiffMode == ArenaTowerDiffMode.Practice)
    UIHelper.SetVisible(self.WidgetBgChallenge, nDiffMode == ArenaTowerDiffMode.Challenge)
    UIHelper.SetVisible(self.LabelTitle, nLevelIndex > 0)
    UIHelper.SetString(self.LabelTitle, string.format("第 %d 关", nLevelIndex))
    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(tLevelConfig.szName))
    UIHelper.LayoutDoLayout(self.LayoutLabel)

    UIHelper.SetVisible(self.WidgetReset, nLevelIndex > 0)
    UIHelper.SetVisible(self.WidgetDifficultyDown, nDiffMode == ArenaTowerDiffMode.Challenge and nLevelIndex < ArenaTowerData.MAX_LEVEL_COUNT)

    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

function UIPanelYangDaoMainView:CheckMemberSetupValid()
    local tMemberData = {}

    if TeamData.IsInParty() then
        TeamData.Generator(function(dwID, tMemberInfo)
            local szCenterName = GetCenterNameByCenterID(tMemberInfo.dwCenterID) or ""
            local nHDKungFuID = TabHelper.GetHDKungfuID(tMemberInfo.dwMountKungfuID)
            local nPosType = PlayerKungfuPosition[nHDKungFuID]
            local dwPlayerID = tMemberInfo.dwMemberID
            -- local nDiffMode, nLevelProgress = ArenaTowerData.GetMemberBaseInfo(dwPlayerID)
            local tData = {
                szName = UIHelper.GBKToUTF8(tMemberInfo.szName),
                szCenterName = UIHelper.GBKToUTF8(szCenterName),
                dwForceID = tMemberInfo.dwForceID or 0,
                -- nDiffMode = nDiffMode or 0,
                -- nLevelProgress = nLevelProgress or 0,
                nPosType = nPosType,
            }
            table.insert(tMemberData, tData)
        end)
    elseif RoomData.IsHaveRoom() then
        local hRoom = GetGlobalRoomClient()
        local tRoomInfo = hRoom and hRoom.GetGlobalRoomInfo()
        for _, tMemberInfo in pairs(tRoomInfo or {}) do
            if type(tMemberInfo) == "table" and tMemberInfo.szGlobalID then
                local szCenterName = GetCenterNameByCenterID(tMemberInfo.dwCenterID) or ""
                local nHDKungFuID = TabHelper.GetHDKungfuID(tMemberInfo.dwKungfuID)
                local nPosType = PlayerKungfuPosition[nHDKungFuID]
                -- local dwPlayerID = RoomData.GetTeamPlayerIDByGlobalID(tMemberInfo.szGlobalID) -- 跨服获取不到
                -- local nDiffMode, nLevelProgress
                -- if dwPlayerID then
                --     nDiffMode, nLevelProgress = ArenaTowerData.GetMemberBaseInfo(dwPlayerID)
                -- else
                --     -- TODO
                -- end

                local tData = {
                    szName = UIHelper.GBKToUTF8(tMemberInfo.szName),
                    szCenterName = UIHelper.GBKToUTF8(szCenterName),
                    dwForceID = tMemberInfo.dwForceID or 0,
                    -- nDiffMode = nDiffMode or 0,
                    -- nLevelProgress = nLevelProgress or 0,
                    nPosType = nPosType,
                }
                table.insert(tMemberData, tData)
            end
        end
    else
        return false
    end

    -- 1. 检测队伍是否符合2输出1治疗的配置
    -- 2. 检测队友进度是否相同（弃用）
    local nDiffMode = self:GetDiffMode()
    local nDpsCount, nHealCount = 0, 0
    for _, tData in ipairs(tMemberData) do
        if tData.nPosType == KUNGFU_POSITION.DPS then
            nDpsCount = nDpsCount + 1
        elseif tData.nPosType == KUNGFU_POSITION.Heal then
            nHealCount = nHealCount + 1
        end
        -- if nLevelProgress ~= tData.nLevelProgress or (tData.nLevelProgress > 0 and nDiffMode ~= tData.nDiffMode) then
        --     UIMgr.Open(VIEW_ID.PanelYangDaoHintPop, tMemberData)
        --     return false
        -- end
    end

    if nDpsCount < ArenaTowerData.TEAM_DPS_REQUIRE or nHealCount < ArenaTowerData.TEAM_HEAL_REQUIRE then
        UIMgr.Open(VIEW_ID.PanelYangDaoHintPop, tMemberData)
        return false
    end

    return true
end

function UIPanelYangDaoMainView:GetDiffMode()
    local nDiffMode, nLevelProgress, _, _ = ArenaTowerData.GetBaseInfo() -- 以玩家当前的作为基准
    if nLevelProgress <= 0 then
        nDiffMode = ArenaTowerData.GetSelDiffMode()
    end
    return nDiffMode
end

return UIPanelYangDaoMainView