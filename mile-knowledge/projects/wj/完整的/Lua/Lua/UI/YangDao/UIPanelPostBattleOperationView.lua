-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIPanelPostBattleOperationView
-- Date: 2026-03-04 15:16:39
-- Desc: 扬刀大会-局内战斗结束操作界面 PanelPostBattleOperation
-- ---------------------------------------------------------------------------------

local UIPanelPostBattleOperationView = class("UIPanelPostBattleOperationView")

local TEXT_COLOR_READY = "#95FF95"

function UIPanelPostBattleOperationView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self:InitWidgetPlayer()
    end

    Event.Dispatch(EventType.OnSetBottomRightAnchorVisible, false)
    self:UpdateInfo()
end

function UIPanelPostBattleOperationView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelPostBattleOperationView:BindUIEvent()
    -- 按钮都加个CD避免频繁点击
    UIHelper.SetClickInterval(self.BtnMoveOn, 1)
    UIHelper.SetClickInterval(self.BtnRest, 1)
    UIHelper.SetClickInterval(self.BtnCancelPrepare, 1)
    UIHelper.BindUIEvent(self.BtnQuit, EventType.OnClick, function()
        local dialog = UIHelper.ShowConfirm(g_tStrings.ARENA_TOWER_LEAVE_CONFIRM, function()
            ArenaTowerData.LeaveArenaTower()
            UIMgr.Close(self)
        end, nil, true)
    end)
    UIHelper.BindUIEvent(self.BtnMoveOn, EventType.OnClick, function()
        ArenaTowerData.PlayerReady(true)
    end)
    UIHelper.BindUIEvent(self.BtnRest, EventType.OnClick, function()
        ArenaTowerData.PlayerRest()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnCancelPrepare, EventType.OnClick, function()
        ArenaTowerData.PlayerReady(false)
    end)
    UIHelper.BindUIEvent(self.BtnFold, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPanelPostBattleOperationView:RegEvent()
    Event.Reg(self, EventType.OnArenaTowerUpdateRoundState, function()
        self:UpdateInfo()
    end)
    Event.Reg(self, EventType.OnArenaTowerPlayerUpdate, function()
        self:UpdateInfo()
    end)
    Event.Reg(self, EventType.OnArenaTowerUpdateLevelInfo, function()
        self:UpdateInfo()
    end)
    Event.Reg(self, "PARTY_UPDATE_BASE_INFO", function ()
        self:UpdateInfo()
    end)
    Event.Reg(self, "PARTY_UPDATE_MEMBER_INFO", function()
        self:UpdateInfo()
    end)
    Event.Reg(self, "PARTY_SYNC_MEMBER_DATA", function ()
        self:UpdateInfo()
    end)
    Event.Reg(self, "PARTY_ADD_MEMBER", function()
        self:UpdateInfo()
    end)
    Event.Reg(self, "PARTY_DELETE_MEMBER", function()
        self:UpdateInfo()
    end)
    Event.Reg(self, "PARTY_DISBAND", function()
        self:UpdateInfo()
    end)
    Event.Reg(self, "TEAM_AUTHORITY_CHANGED", function()
        self:UpdateInfo()
    end)
end

function UIPanelPostBattleOperationView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelPostBattleOperationView:InitWidgetPlayer()
    self.tWidgetHead = {}
    self.tRichTextName = {}
    self.tImgCheck = {}

    for i, widgetPlayer in ipairs(self.tWidgetPlayer or {}) do
        local widgetHead = UIHelper.GetChildByName(widgetPlayer, "WidgetHead")
        local richTextName = UIHelper.GetChildByName(widgetPlayer, "RichTextName")
        local imgCheck = UIHelper.GetChildByName(widgetPlayer, string.format("ImgCheck%02d", i))
        self.tWidgetHead[i] = widgetHead
        self.tRichTextName[i] = richTextName
        self.tImgCheck[i] = imgCheck
    end
end

function UIPanelPostBattleOperationView:UpdateInfo()
    local player = GetClientPlayer()
    if not player then
        return
    end

    if not ArenaTowerData.CanGetBattleFieldInfo() then
        return
    end

    local nDiffMode, nLevelProgress, _, _ = ArenaTowerData.GetBaseInfo()
    local nBattleState, bReady = ArenaTowerData.GetBattleStateInfo()
    local bRest = nBattleState == ArenaTowerBattleState.Rest
    local bMatching = nBattleState == ArenaTowerBattleState.Matching
    local tLevelConfig = ArenaTowerData.GetLevelConfig(nLevelProgress)
    local bShopRound = tLevelConfig and tLevelConfig.bShopRound or false
    UIHelper.SetVisible(self.BtnQuit, nLevelProgress >= ArenaTowerData.MAX_LEVEL_COUNT)
    UIHelper.SetVisible(self.BtnMoveOn, nLevelProgress < ArenaTowerData.MAX_LEVEL_COUNT)
    UIHelper.SetVisible(self.BtnRest, true)
    UIHelper.SetVisible(self.WidgetTagSpecial, bShopRound)
    UIHelper.SetVisible(self.WidgetAni, bShopRound)
    UIHelper.PlayAni(self, self.WidgetAni, "AniPostBattleOperationBtn")

    UIHelper.SetVisible(self.WidgetNextStep, not bReady and bRest)
    UIHelper.SetVisible(self.WidgetMatching, bReady or not bRest)
    UIHelper.SetVisible(self.BtnCancelPrepare, bReady and bRest)

    local nNextLevel = nLevelProgress + 1
    local szNextLevel
    if nDiffMode == ArenaTowerDiffMode.Practice then
        szNextLevel = string.format(g_tStrings.ARENA_TOWER_NEXT_LEVEL_PRACTICE, tostring(nNextLevel))
    elseif nDiffMode == ArenaTowerDiffMode.Challenge then
        szNextLevel = string.format(g_tStrings.ARENA_TOWER_NEXT_LEVEL_CHALLENGE, tostring(nNextLevel))
    else
        szNextLevel = string.format("<color=#D7F6FF> - 第 %s 关</c>", tostring(nNextLevel))
    end

    -- local szTitle
    if nLevelProgress <= 0 then
        -- szTitle = "开始闯关"
        UIHelper.SetVisible(self.ImgTitle_Start, true)
        UIHelper.SetVisible(self.ImgTitle_Continue, false)
        UIHelper.SetVisible(self.ImgTitle_Finished, false)
    elseif nLevelProgress < ArenaTowerData.MAX_LEVEL_COUNT then
        -- szTitle = "继续闯关"
        UIHelper.SetVisible(self.ImgTitle_Start, false)
        UIHelper.SetVisible(self.ImgTitle_Continue, true)
        UIHelper.SetVisible(self.ImgTitle_Finished, false)
    else
        -- szTitle = "已通关所有关卡"
        UIHelper.SetVisible(self.ImgTitle_Start, false)
        UIHelper.SetVisible(self.ImgTitle_Continue, false)
        UIHelper.SetVisible(self.ImgTitle_Finished, true)
        if nDiffMode == ArenaTowerDiffMode.Practice then
            szNextLevel = g_tStrings.ARENA_TOWER_PRACTICE_ALL_CLEARED
        elseif nDiffMode == ArenaTowerDiffMode.Challenge then
            szNextLevel = g_tStrings.ARENA_TOWER_CHALLENGE_ALL_CLEARED
        else
            szNextLevel = "恭喜您已成功通关所有关卡！"
        end
    end
    -- UIHelper.SetString(self.LabelTitle, szTitle)

    -- UIHelper.SetVisible(self.LabelLevelNum, nNextLevel <= ArenaTowerData.MAX_LEVEL_COUNT)
    UIHelper.SetRichText(self.LabelLevelNum, szNextLevel)

    Timer.DelTimer(self, self.nMatchTimerID)
    if bMatching then
        self:UpdateMatchTime()
        self.nMatchTimerID = Timer.AddCycle(self, 0.5, function()
            self:UpdateMatchTime()
        end)
    else
        UIHelper.SetString(self.LabelMatchTitle, g_tStrings.ARENA_TOWER_WAITING_MEMBER)
    end

    self.tScriptHead = self.tScriptHead or {}
    local tPlayerList = self:GetPlayerList() or {}
    for i = 1, #self.tWidgetPlayer do
        local tInfo = tPlayerList[i]
        if tInfo and tInfo.dwMapID == BATTLE_FIELD_MAP_ID.QING_XIAO_SHAN and tInfo.bIsOnLine then
            local bPlayerReady = tInfo.bReady or bMatching or false
            local _, szName = UIHelper.TruncateString(tInfo.szName, 5, nil, 4)
            if bPlayerReady then
                szName = UIHelper.AttachTextColor(szName, TEXT_COLOR_READY)
            end
            UIHelper.SetRichText(self.tRichTextName[i], szName)
            UIHelper.SetVisible(self.tImgCheck[i], bPlayerReady)
            if not self.tScriptHead[i] then
                self.tScriptHead[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.tWidgetHead[i])
            end
            self.tScriptHead[i]:SetHeadWithImg(PlayerKungfuImg[tInfo.dwKungfuID])
            self.tScriptHead[i]:SetHeadContentSize(96, 96)
        else
            UIHelper.SetRichText(self.tRichTextName[i], "")
            UIHelper.SetVisible(self.tImgCheck[i], false)
            UIHelper.RemoveAllChildren(self.tWidgetHead[i]) -- 清除头像，只保留头像框，不知道为啥ClearTexture无效，所以这里重刷一下
            self.tScriptHead[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.tWidgetHead[i])
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutPlayers)
    UIHelper.LayoutDoLayout(self.LayoutButton)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

function UIPanelPostBattleOperationView:GetPlayerList()
    -- 当玩家距离太远（如在驿站）直接GetPlayer会拿不到，根据队伍/房间拿
    local tPlayerList = {}
    if TeamData.IsInParty() then
        TeamData.Generator(function(dwID, tMemberInfo)
            local tInfo = {
                dwPlayerID = tMemberInfo.dwMemberID,
                szName = UIHelper.GBKToUTF8(tMemberInfo.szName),
                -- dwForceID = tMemberInfo.dwForceID,
                dwKungfuID = tMemberInfo.dwMountKungfuID,
                dwMapID = tMemberInfo.dwMapID, -- 过图的时候ID为0，用来判断是否显示头像
                bIsOnLine = tMemberInfo.bIsOnLine,
                bReady = ArenaTowerData.GetPQStatisticsData(tMemberInfo.dwMemberID, PQ_STATISTICS_INDEX.SPECIAL_OP_4) == 1,
            }
            table.insert(tPlayerList, tInfo)
        end)
    elseif RoomData.IsHaveRoom() then
        local hRoom = GetGlobalRoomClient()
        local tRoomInfo = hRoom and hRoom.GetGlobalRoomInfo()
        local nMemberCount = 0
        for _, tMemberInfo in pairs(tRoomInfo or {}) do
            if type(tMemberInfo) == "table" and tMemberInfo.szGlobalID then
                local dwPlayerID = RoomData.GetTeamPlayerIDByGlobalID(tMemberInfo.szGlobalID)
                local tInfo = {
                    dwPlayerID = dwPlayerID,
                    szName = UIHelper.GBKToUTF8(tMemberInfo.szName),
                    -- dwForceID = tMemberInfo.dwForceID,
                    dwKungfuID = tMemberInfo.dwKungfuID,
                    dwMapID = BATTLE_FIELD_MAP_ID.QING_XIAO_SHAN,
                    bIsOnLine = true,
                    bReady = ArenaTowerData.GetPQStatisticsData(dwPlayerID, PQ_STATISTICS_INDEX.SPECIAL_OP_4) == 1,
                }
                table.insert(tPlayerList, tInfo)
            end
        end
    end

    -- 排序 自己在前 后面按ID排
    local player = GetClientPlayer()
    local dwSelfPlayerID = player and player.dwID
    table.sort(tPlayerList, function(a, b)
        if a.dwPlayerID == dwSelfPlayerID then
            return true
        end
        if b.dwPlayerID == dwSelfPlayerID then
            return false
        end
        if a.dwMapID == BATTLE_FIELD_MAP_ID.QING_XIAO_SHAN and b.dwMapID ~= BATTLE_FIELD_MAP_ID.QING_XIAO_SHAN then
            return true
        end
        if b.dwMapID == BATTLE_FIELD_MAP_ID.QING_XIAO_SHAN and a.dwMapID ~= BATTLE_FIELD_MAP_ID.QING_XIAO_SHAN then
            return false
        end
        return a.dwPlayerID < b.dwPlayerID
    end)

    return tPlayerList
end

function UIPanelPostBattleOperationView:UpdateMatchTime()
    local nMatchStartTime = ArenaTowerData.GetMatchInfo()
    if not nMatchStartTime then
        return
    end

    local nTime = math.max(GetCurrentTime() - nMatchStartTime, 0)
    local szMatchTitle = g_tStrings.ARENA_TOWER_MATCHING .. UIHelper.GetHeightestTwoTimeText(nTime)
    UIHelper.SetString(self.LabelMatchTitle, szMatchTitle)
end

return UIPanelPostBattleOperationView