-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRoomView
-- Date: 2024-02-18 17:16:25
-- Desc: ?
-- ---------------------------------------------------------------------------------

local function IsIegalExchange(tPlayerPos)
    for k, v in pairs(tPlayerPos) do
        for i, w in pairs(tPlayerPos) do
            if i ~= k and v == w then
                return false
            end
        end
    end

    return true
end

-----------------------------DataModel------------------------------
local DataModel = {}

function DataModel.Init()
    DataModel.bSceneReady = true
    DataModel.tPlayerPos = {}
    DataModel.tPlayerMap = {}
    DataModel.tOfflinePlayerMap = {}
    DataModel.tInRaidPlayerMap = {}
    DataModel.bUpdateAll = true
    DataModel.dwLastClickTrack = 0
    DataModel.tGlobalRecruit = Table_GetGlobalTeamRecruit()
end

function DataModel.ApplyRoomBaseInfo()
    GetGlobalRoomClient().ApplyBaseInfo()
end

function DataModel.UpdateRoomInfo(bInit)
    local tRoomInfo = GetGlobalRoomClient().GetGlobalRoomInfo()

    DataModel.eRoomState = tRoomInfo.eRoomState
    DataModel.dwTargetMapID = tRoomInfo.nTargetMapID
    DataModel.tRoomInfo = tRoomInfo

    local tPlayerMap = {}
    local tPlayerPos = {}
    for _, v in pairs(tRoomInfo) do
        if type(v) == "table" and v.szGlobalID then
            tPlayerPos[v.nMemberIndex] = v.szGlobalID
            tPlayerMap[v.szGlobalID] = v
        end
    end

    DataModel.bUpdateAll = bInit or (not IsTableEqual(tPlayerPos, DataModel.tPlayerPos)) or DataModel.szOwnerID ~= tRoomInfo.szOwnerID
    DataModel.szOwnerID = tRoomInfo.szOwnerID
    DataModel.tPlayerPos = tPlayerPos
    DataModel.tPlayerMap = tPlayerMap
end

function DataModel.GetMaxGroupNum()
    local nMaxIndex = 0
    for k, v in pairs(DataModel.tPlayerPos) do
        nMaxIndex = math.max(nMaxIndex, k)
    end
    return math.floor((nMaxIndex - 1)/ 5) + 1
end

function DataModel.UpdateOfflinePlayerMap()
    local tOfflineList = GetGlobalRoomClient().GetOfflineMemberList()
    local tOfflinePlayerMap = {}
    for _, szGlobalID in ipairs(tOfflineList) do
        tOfflinePlayerMap[szGlobalID] = true
    end

    DataModel.tOfflinePlayerMap = tOfflinePlayerMap
end

local function IsPlayerInRaid(szGlobalID)
    local player = GetClientPlayer()
    local hTeam = GetClientTeam()
    if player and player.IsInParty() then
        local tMemberInfo = hTeam.GetMemberInfoByGlobalID(szGlobalID)
        if tMemberInfo then
            return true
        end
    end
end

-----------------------------View------------------------------
local UIRoomView = class("UIRoomView")

function UIRoomView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tRoomCells = {}
    for nGroup = 0, 4 do
        local widgetTeamSortName = "WidgetTeamSort"
        if nGroup ~= 0 then
            widgetTeamSortName = widgetTeamSortName .. nGroup
        end
        self.tRoomCells[nGroup] = {}
        local widgetTeamSort = self.WidgetAnchorRight:getChildByName(widgetTeamSortName)
        for nIndex = 0, 4 do
            local imgMemberMessageName = "ImgMemberMassage"
            if nIndex ~= 0 then
                imgMemberMessageName = imgMemberMessageName .. nIndex
            end
            local imgMemberMessage = widgetTeamSort:getChildByName(imgMemberMessageName)
            imgMemberMessage:removeAllChildren()
            local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetRoommateCell, imgMemberMessage)
            cell:OnEnter(false, nGroup, nIndex)
            self.tRoomCells[nGroup][nIndex] = cell
        end
    end

    self.bStateMove = false
    self.movingCell = nil

    self.bSyncOffline = false
    self.dwSyncOfflineTime = 0
    self.bSyncInRaid = false
    self.dwSyncInRaidTime = 0

    -- DataModel.ApplyRoomBaseInfo()
    DataModel.Init()
    DataModel.UpdateRoomInfo(true)

    local scriptChat = UIHelper.GetBindScript(self.BtnChat)
    if scriptChat then
        scriptChat:OnEnter(UI_Chat_Channel.Team)
    end
    self:UpdateInfo()

    Timer.AddCycle(self, 0.5, function()
        local nTime = GetTickCount()
        if self.dwSyncOfflineTime ~= 0 and nTime - self.dwSyncOfflineTime > 60000 then --在线统计
            self.bSyncOffline = false
            self.dwSyncOfflineTime = 0
            self:UpdateAllGroup()
        end
        if self.dwSyncInRaidTime ~= 0 and nTime - self.dwSyncInRaidTime > 60000 then --进本统计
            self.bSyncInRaid = false
            self.dwSyncInRaidTime = 0
            self:UpdateAllGroup()
        end
    end)
end

function UIRoomView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRoomView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnGoto, EventType.OnClick, function()
        local dwNowTime = GetTickCount()
        if dwNowTime - DataModel.dwLastClickTrack > 10000 then
            MapMgr.BeforeTeleport()
            RemoteCallToServer("On_Team_RoomToEnterScene")
            DataModel.dwLastClickTrack = GetTickCount()
            UIMgr.Close(VIEW_ID.PanelTeam)
        else
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_ROOM_HAVE_APPLY_SCENE)
        end
    end)

    UIHelper.BindUIEvent(self.BtnInvite, EventType.OnClick, function ()
        UIHelper.ShowConfirm(g_tStrings.STR_ROOM_REQUEST_INVITE_JOIN_MAP, function()
            GetGlobalRoomClient().InviteAllJoinScene()
        end)
    end)

    UIHelper.BindUIEvent(self.BtnConvert, EventType.OnClick, function ()
        if self.bStateMove then
            local fnOk = function()
                GetGlobalRoomClient().SetGlobalRoomMemberPos(DataModel.tPlayerPos)
            end
            local fnCancel = function()
                DataModel.tPlayerPos = clone(self.tClonePlayerPos)
                Timer.AddFrame(self, 1, function()
                    self:UpdateAllGroup()
                end)
            end
            if Storage.Team.bEnableRoomAutoSyncToTeam then
                local scriptView = UIHelper.ShowConfirm(g_tStrings.STR_ROOM_SYNC_QUEUE_RAID_AND_ROOM, fnOk, fnCancel)
                scriptView:SetButtonContent("Cancel", "不保存")
                scriptView:SetButtonContent("Confirm", "保存")
            else
                fnOk()
            end
        else
            self.tClonePlayerPos = clone(DataModel.tPlayerPos)
        end
        self.bStateMove = not self.bStateMove
        self:UpdateBtnState()
    end)


    UIHelper.BindUIEvent(self.BtnMore, EventType.OnClick, function()
        local nX,nY = UIHelper.GetWorldPosition(self.BtnMore)
        local nSizeW,nSizeH = UIHelper.GetContentSize(self.BtnMore)
        local _, scriptTips = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetTipMoreOper, nX-nSizeW/2-38, nY+nSizeH/2)
        scriptTips:OnEnter({{
            szName = g_tStrings.STR_ROOM_LOOKUP_PROCESS,
            OnClick = function ()
                MonsterBookData.CheckRemoteRoommateProgress(DataModel.dwTargetMapID)
            end
        }, {
            szName = g_tStrings.STR_ROOM_LOOKUP_ONLINE,
            OnClick = function ()
                GetGlobalRoomClient().ApplyRoleOnlineFlag()
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end
        }, {
            szName = g_tStrings.STR_ROOM_LOOKUP_INRAID,
            bDisabled = not RoomData.IsRoomOwner() or not RoomData.IsInGlobalRoomDungeon(),
            OnClick = function()
                self.dwSyncInRaidTime = GetTickCount()
                self.dwSyncOfflineTime = 0
                self.bSyncInRaid = true
                self.bSyncOffline = false
                self:UpdateInRaidPlayerMap()
                self:UpdateAllGroup()
                TipsHelper.OutputMessage("MSG_SYS", g_tStrings.STR_ROOM_TAG_TIP)
            end
        }, {
            szName = "顺序同步团队",
            bDisabled = not RoomData.IsRoomOwner(),
            OnClick = function ()
                RoomData.SyncRoomQueueToTeam()
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end
        }})
    end)

    UIHelper.BindUIEvent(self.BtnExit, EventType.OnClick, function()
        RoomData.ConfirmQuitGlobalRoom()
    end)

    UIHelper.BindUIEvent(self.BtnTarget, EventType.OnClick, function()
        local tList = {}
        local tDefault = {}
        for i = 1, #DataModel.tGlobalRecruit do
            local tRecruit = DataModel.tGlobalRecruit[i]
            table.insert(tList, UIHelper.GBKToUTF8(tRecruit.szName))
            if tRecruit.dwMapID == DataModel.dwTargetMapID then
                table.insert(tDefault, i)
            end
        end
        FilterDef.RoomTarget2[1].tbList = tList
        FilterDef.RoomTarget2[1].tbDefault = tDefault
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnTarget, TipsLayoutDir.BOTTOM_CENTER, FilterDef.RoomTarget2)
    end)

    UIHelper.BindUIEvent(self.BtnCreate, EventType.OnClick, function()
        RoomData.CreateRoom()
    end)

    UIHelper.BindUIEvent(self.BtnRecruit, EventType.OnClick, function()
        local tbSelfRecruitInfo = nil
        if not table_is_empty(TeamBuilding.tbSelfRecruitInfo) then
            tbSelfRecruitInfo = TeamBuilding.tbSelfRecruitInfo
        end
        UIMgr.Open(VIEW_ID.PanelReleaseRecruitPop, tbSelfRecruitInfo, nil, true)
    end)

    UIHelper.BindUIEvent(self.BtnSendToChat, EventType.OnClick, function()
        RoomData.ShareRoomToChat()
    end)

    UIHelper.BindUIEvent(self.BtnSetUp, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelTeamNoticeEditPop, true)
    end)

    UIHelper.BindUIEvent(self.TogAutoSync, EventType.OnSelectChanged, function (_, bSelected)
        Storage.Team.bEnableRoomAutoSyncToTeam = bSelected
        Storage.Team.Flush()
    end)
end

function UIRoomView:RegEvent()
    Event.Reg(self, "GLOBAL_ROOM_NOTIFY", function()
        DataModel.UpdateRoomInfo()
        self:UpdateInfo()
    end)

    Event.Reg(self, "GLOBAL_ROOM_BASE_INFO", function()
        local szRoomID, bMemberChange, bInit = arg0, arg1, arg2
        DataModel.UpdateRoomInfo(bInit or bMemberChange)
        self:UpdateInfo()
    end)

    Event.Reg(self, "GLOBAL_ROOM_DETAIL_INFO", function()
        local szRoomID, bMemberChange, bInit = arg0, arg1, arg2
        DataModel.UpdateRoomInfo(bInit or bMemberChange)
        self:UpdateInfo()
    end)

    Event.Reg(self, "GLOBAL_ROOM_MEMBER_CHANGE", function()
        DataModel.UpdateRoomInfo()
        self:UpdateInfo()
    end)

    Event.Reg(self, "GLOBAL_ROOM_MEMBER_ONLINE_FLAG", function()
        self.bSyncOffline = true
        self.dwSyncOfflineTime = GetTickCount()
        self.bSyncInRaid = false
        self.dwSyncInRaidTime = 0
        DataModel.UpdateOfflinePlayerMap()
        self:UpdateAllGroup()
    end)

    Event.Reg(self, EventType.OnRoomCellTouchMoved, function (tInfo, nGroup, nIndex, nX, nY)
        if not self.bStateMove then
            return
        end
        if not self.movingCell then
            self.movingCell = UIHelper.AddPrefab(PREFAB_ID.WidgetRoommateCell, self.WidgetAnchorRight)
            self.movingCell:OnEnter(true, nGroup, nIndex)
            self.movingCell:SetInfo(tInfo)
            UIHelper.SetAnchorPoint(self.movingCell._rootNode, 0.5, 0.5)
        end

        local nLocalX, nLocalY = UIHelper.ConvertToNodeSpace(self.WidgetAnchorRight, nX, nY)
        UIHelper.SetPosition(self.movingCell._rootNode, nLocalX, nLocalY, self.WidgetAnchorRight)

        local dstCell = self:CheckMovingCellPos()
        if dstCell then
            Event.Dispatch(EventType.OnRoomCellToggleSelectedByPos, dstCell.nGroup, dstCell.nIndex)
        end
    end)

    Event.Reg(self, EventType.OnRoomCellTouchEnded, function ()
        if self.movingCell then
            local dstCell = self:CheckMovingCellPos()
            if dstCell then
                local szDstGlobalID = DataModel.tPlayerPos[dstCell:MemberIndex()]
                local tPlayerPos = clone(DataModel.tPlayerPos)
                tPlayerPos[self.movingCell:MemberIndex()] = szDstGlobalID
                tPlayerPos[dstCell:MemberIndex()] = self.movingCell.tInfo.szGlobalID
                if IsIegalExchange(tPlayerPos) then
                    DataModel.tPlayerPos = tPlayerPos
                    Timer.AddFrame(self, 1, function()
                        self:UpdateAllGroup()
                    end)
                end
            end

            self.movingCell._rootNode:removeFromParent(true)
            self.movingCell = nil

            Event.Dispatch(EventType.OnRoomCellToggleSelectedByPos, -1, -1)
        end
    end)

    Event.Reg(self, EventType.OnRoomCellTouchCanceled, function ()
        if self.movingCell then
            self.movingCell._rootNode:removeFromParent(true)
            self.movingCell = nil

            Event.Dispatch(EventType.OnRoomCellToggleSelectedByPos, -1, -1)
        end
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        self:ClearSelect()
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.RoomTarget2.Key then
            local nIndex = tbSelected[1][1]
            local tRecruit = DataModel.tGlobalRecruit[nIndex]
            if not tRecruit then
                return
            end
            if tRecruit.dwMapID and tRecruit.dwMapID ~= DataModel.dwTargetMapID then
                GetGlobalRoomClient().UpdateRoomTarget(tRecruit.dwMapID)
            end
        end
    end)
end

function UIRoomView:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRoomView:UpdateInfo()
    local bHasRoom = RoomData.IsHaveRoom()
    UIHelper.SetVisible(self.WidgetAnchorRight, bHasRoom)
    UIHelper.SetVisible(self.WidgetAnchorLeftBottom, bHasRoom)
    UIHelper.SetVisible(self.WidgetAnchorRightBottom, bHasRoom)
    UIHelper.SetVisible(self.WidgetAnchorRightTop, bHasRoom)
    UIHelper.SetVisible(self.WidgetAnchorEmpty, not bHasRoom)

    local bOwner = RoomData.GetRoomOwner() == UI_GetClientPlayerGlobalID()
    UIHelper.SetVisible(self.BtnSetUp, bOwner)

    UIHelper.LayoutDoLayout(self.WidgetAnchorRightTop)

    if bHasRoom then
        -- if DataModel.bUpdateAll then
        --     self:UpdateAllGroup()
        --     DataModel.bUpdateAll = false
        -- end
        self:UpdateAllGroup()
        DataModel.bUpdateAll = false
        self:UpdateTarget()
        self:UpdateBtnState()
    end

    if RoomData.bDelaySyncToTeam then
        RoomData.SyncRoomQueueToTeam()
        RoomData.bDelaySyncToTeam = false
    end
end

function UIRoomView:UpdateTarget()
    if DataModel.dwTargetMapID and DataModel.dwTargetMapID ~= 0 then
        UIHelper.SetString(self.LabelTargetName, UIHelper.GBKToUTF8(Table_GetMapName(DataModel.dwTargetMapID)))
    else
        UIHelper.SetString(self.LabelTargetName, g_tStrings.STR_ROOM_NO_TARGET)
    end
    UIHelper.LayoutDoLayout(self.LayoutTargetContent)
end

function UIRoomView:UpdateInRaidPlayerMap()
    if not RoomData.IsRoomOwner() then
        self.bSyncInRaid = false
        return
    end

    if not RoomData.IsInGlobalRoomDungeon() then
        self.bSyncInRaid = false
        return
    end

    for szGlobalID, tPlayer in pairs(DataModel.tPlayerMap) do
        local bInRaid = IsPlayerInRaid(szGlobalID)
        DataModel.tInRaidPlayerMap[szGlobalID] = bInRaid
    end
end

function UIRoomView:UpdateBtnState()
    local bRoomOwner = RoomData.IsRoomOwner()
    local bRemote = IsRemotePlayer(UI_GetClientPlayerID())
    local bWaitEnter = DataModel.eRoomState == GLOBAL_ROOM_STATE_CODE.ROOM_WAIT_ENTER

    local bTrack = (bRoomOwner or bWaitEnter) and not bRemote
    if DataModel.dwTargetMapID and DataModel.dwTargetMapID ~= 0 then
        UIHelper.SetButtonState(self.BtnGoto, bTrack and BTN_STATE.Normal or BTN_STATE.Disable)
    else
        UIHelper.SetButtonState(self.BtnGoto, BTN_STATE.Disable)
    end

    UIHelper.SetVisible(self.BtnGoto, not self.bStateMove)
    UIHelper.SetVisible(self.BtnInvite, RoomData.IsRoomOwner() and not self.bStateMove)
    UIHelper.SetButtonState(self.BtnInvite, bWaitEnter and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetVisible(self.BtnConvert, RoomData.IsRoomOwner())
    UIHelper.SetVisible(self.BtnMore, not self.bStateMove)
    if self.bStateMove then
        UIHelper.SetString(self.LabelContent, "确定")
        UIHelper.SetVisible(self.TogAutoSync, true)
        UIHelper.SetSelected(self.TogAutoSync, Storage.Team.bEnableRoomAutoSyncToTeam, false)
    else
        UIHelper.SetString(self.LabelContent, "换位")
        UIHelper.SetVisible(self.TogAutoSync, false)
    end
    UIHelper.LayoutDoLayout(self.WidgetAnchorButton)

    UIHelper.SetVisible(self.ImgTargetIcon, RoomData.IsRoomOwner())
    UIHelper.SetEnable(self.BtnTarget, RoomData.IsRoomOwner())
    UIHelper.SetVisible(self.BtnRecruit, RoomData.IsRoomOwner())
    UIHelper.LayoutDoLayout(self.LayoutTargetContent)
    UIHelper.LayoutDoLayout(self.WidgetBtnTarget)
end

function UIRoomView:UpdateAllGroup()
    if self.movingCell then
        self.movingCell._rootNode:removeFromParent(true)
        self.movingCell = nil
    end

    self:enumRoomCells(function (cell)
        local i = cell:MemberIndex()
        if DataModel.tPlayerPos[i] then
            local dwGlobalID = DataModel.tPlayerPos[i]
            local tPlayerInfo = DataModel.tPlayerMap[dwGlobalID]
            local bOffline = self.bSyncOffline and DataModel.tOfflinePlayerMap[dwGlobalID]
            local bNotInRaid = self.bSyncInRaid and not DataModel.tInRaidPlayerMap[dwGlobalID]
            cell:SetInfo(tPlayerInfo, bOffline, bNotInRaid)
        else
            cell:Clear()
        end
    end)
end

function UIRoomView:CheckMovingCellPos()
    if not self.movingCell then
        return nil
    end

    local dstCell = nil
    local nMinDist = 2^30
    local nX, nY = UIHelper.GetPosition(self.movingCell._rootNode)
    local nW, nH = UIHelper.GetContentSize(self.movingCell._rootNode)
    nX = nX - 0.5 * nW
    nY = nY - 0.5 * nH
    local rect1 = cc.rect(nX, nY, nW, nH)
    self:enumRoomCells(function (cell)
        local nX2, nY2 = UIHelper.GetWorldPosition(cell._rootNode)
        nX2, nY2 = UIHelper.ConvertToNodeSpace(self.WidgetAnchorRight, nX2, nY2)
        local rect2 = cc.rect(nX2, nY2, rect1.width, rect1.height)
        if cc.rectIntersectsRect(rect1, rect2) then
            local nCurDist = math.sqrt(math.abs(rect1.x - rect2.x)^2+math.abs(rect1.y-rect2.y)^2)
            if nCurDist < nMinDist then
                nMinDist = nCurDist
                dstCell = cell
            end
        end
    end)
    return dstCell
end

function UIRoomView:enumRoomCells(fnAction)
    for nGroup = 0, 4 do
        for nIndex = 0, 4 do
            local cell = self.tRoomCells[nGroup][nIndex]
            fnAction(cell)
        end
    end
end

function UIRoomView:ClearSelect()
    self:enumRoomCells(function (cell)
        UIHelper.SetSelected(cell.TogSelect, false, false)
        return true
    end)
end



return UIRoomView