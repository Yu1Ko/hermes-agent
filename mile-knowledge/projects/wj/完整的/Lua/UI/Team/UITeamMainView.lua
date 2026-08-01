-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamMainView
-- Date: 2023-02-08 10:19:43
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITeamMainView = class("UITeamMainView")

local MODEL_POS = Const.MiniScene.TeamGroupView.tbModelPos
local CAMERA_POS = Const.MiniScene.TeamGroupView.tbCamare

local Page2Tog = {
    [1] = "TogTabList",
    [2] = "TogTabList01",
    [3] = "TogTabList02",
    [4] = "TogTabList03",
}

local tbCloseRightViewID = {
    [VIEW_ID.PanelChatSocial] = 1,
}

local SZ_KEY_GUANZHAN_REDPOINT = "TEAM_VIEW_SZ_KEY_GUANZHAN_REDPOINT"

function UITeamMainView:OnEnter(nPage, dwTeamBuildApplyID, dwTeamBuildRecruitID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if not nPage then
        if TeamData.IsInParty() then
            nPage = 2
        else
            nPage = 1
        end
    end

    -- 跨服只能是2
    -- if CrossMgr.IsCrossing() then
    --     nPage = 2

    --     UIHelper.SetCanSelect(self.TogTabList, false, g_tStrings.STR_REMOTE_NOT_TIP)
    --     UIHelper.SetCanSelect(self.TogTabList02, false, g_tStrings.STR_REMOTE_NOT_TIP)
    -- end

    local teamFindScript = UIHelper.GetBindScript(self.WidgetSeekTeam)
    teamFindScript:OnEnter(dwTeamBuildApplyID, dwTeamBuildRecruitID)

    self.m_scene = SceneHelper.Create(Const.COMMON_SCENE, true, true, true)
    self.ItemMiniScene:SetScene(self.m_scene)

    local sizeDeviceScreen = UIHelper.DeviceScreenSize()
	local nRate = sizeDeviceScreen.width / sizeDeviceScreen.height
    LOG.INFO("[UITeamMainView] nRate=%.2f", nRate)
    for i, tPos in ipairs(MODEL_POS) do
        self.tPos = clone(tPos)
        local tNextPos = MODEL_POS[i+1] or MODEL_POS[#MODEL_POS]
        if nRate >= tNextPos.nAspect then
            local nFixRate = math.max(math.min(nRate, tPos.nAspect), tNextPos.nAspect)
            for j = 1, #tPos do
                for k = 1, 4 do
                    self.tPos[j][k] = (nFixRate - tNextPos.nAspect) * (tPos[j][k]- tNextPos[j][k]) / (tPos.nAspect - tNextPos.nAspect) + tNextPos[j][k]
                end
            end
            self.tPos.nFovy = (nFixRate - tNextPos.nAspect) * (tPos.nFovy - tNextPos.nFovy) / (tPos.nAspect - tNextPos.nAspect) + tNextPos.nFovy
            break
        end
    end
    LOG.TABLE(self.tPos)
    self:SetSceneCamera({CAMERA_POS[1], CAMERA_POS[2], CAMERA_POS[3], CAMERA_POS[4], CAMERA_POS[5], CAMERA_POS[6], self.tPos.nFovy, CAMERA_POS[8], CAMERA_POS[9], CAMERA_POS[10], true})

    Timer.AddFrame(self, 1, function ()
        UIHelper.SetSelected(self[Page2Tog[nPage]], true)
    end)

    self:UpdateInfo()
end

function UITeamMainView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)

    if not UIMgr.IsLayerVisible(UILayer.Scene) then
        UIMgr.ShowLayer(UILayer.Scene)
    end

    SceneHelper.Delete(self.m_scene)
    self.m_scene = nil
end

function UITeamMainView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function (btn)
        UIMgr.Close(VIEW_ID.PanelTeam)
    end)

    UIHelper.BindUIEvent(self.TogTabList, EventType.OnSelectChanged, function(_, bSelected)
        self:UpdateRecruitTab(bSelected)
    end)

    UIHelper.BindUIEvent(self.TogTabList01, EventType.OnSelectChanged, function (_, bSelected)
        self:UpdateTeamTab(bSelected)
    end)

    UIHelper.BindUIEvent(self.TogTabList02, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            if TeamBuilding.tbSelfRecruitInfo and not table_is_empty(TeamBuilding.tbSelfRecruitInfo) then
                TeamBuilding.OnApplyList()
            end
        end
        self:UpdateManageTab(bSelected)
    end)

    UIHelper.BindUIEvent(self.TogTabList03, EventType.OnSelectChanged, function (_, bSelected)
        self:UpdateRoomTab(bSelected)
    end)

    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function()
        for nViewID in pairs(tbCloseRightViewID) do
            if UIMgr.IsViewOpened(nViewID) then
                UIMgr.Close(nViewID)
            end
        end
    end)

    UIHelper.BindUIEvent(self.BtnDungeonGuanZhan, EventType.OnClick, function()
        RoomVoiceData.JumpToRoomVoice(false, true)
        APIHelper.Do(SZ_KEY_GUANZHAN_REDPOINT)
        self:UpdateGuanZhanRedpoint()
    end)
end

function UITeamMainView:RegEvent()
    Event.Reg(self, "PARTY_UPDATE_BASE_INFO", function ()
        self:UpdateTeamTab()
    end)

    Event.Reg(self, "PARTY_DELETE_MEMBER", function (_, dwMemberID)
        self:UpdateTeamTab()
    end)

    Event.Reg(self, "PARTY_DISBAND", function ()
        self:UpdateTeamTab()
    end)

    Event.Reg(self, "PARTY_LEVEL_UP_RAID", function ()
        self:UpdateTeamTab()
        OutputMessage("MSG_SYS", g_tStrings.STR_MSG_RAID_CONVERTED)
    end)

    Event.Reg(self, EventType.OnRecruitPushTeam, function ()
        self:UpdateManageTab()
    end)

    Event.Reg(self, "GLOBAL_ROOM_NOTIFY", function()
        self:UpdateRoomTab()
    end)

    Event.Reg(self, "GLOBAL_ROOM_BASE_INFO", function()
        self:UpdateRoomTab()
    end)

    Event.Reg(self, "GLOBAL_ROOM_DETAIL_INFO", function()
        self:UpdateRoomTab()
    end)

    local tbHideViewID = {
        [VIEW_ID.PanelOtherPlayer] = 1,
    }

    Event.Reg(self, EventType.OnViewOpen, function (nViewID)
        if tbHideViewID[nViewID] then
            UIHelper.SetVisible(self._rootNode, false)
        end

        if tbCloseRightViewID[nViewID] then
            UIHelper.SetVisible(self.BtnCloseRight, true)
        end
    end)

    Event.Reg(self, EventType.OnViewClose, function (nViewID)
        if tbHideViewID[nViewID] then
            UIHelper.SetVisible(self._rootNode, true)
        end

        if tbCloseRightViewID[nViewID] then
            UIHelper.SetVisible(self.BtnCloseRight, false)
        end
    end)

    Event.Reg(self, EventType.OnRecruitLocate, function(dwLoacteApplyID)
        UIHelper.SetSelected(self.TogTabList, true)
        local teamFindScript = UIHelper.GetBindScript(self.WidgetSeekTeam)
        teamFindScript:LocateApply(dwLoacteApplyID)
    end)
end

function UITeamMainView:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamMainView:UpdateInfo()
    self:UpdateRecruitTab()
    self:UpdateTeamTab()
    self:UpdateManageTab()
    self:UpdateRoomTab()
    self:UpdateGuanZhanRedpoint()
end

function UITeamMainView:UpdateRecruitTab(bSelected)
    if bSelected then
        self:UpdateSceneVisible(false)
    end
end

function UITeamMainView:UpdateTeamTab(bSelected)
    if bSelected == nil then
        bSelected = UIHelper.GetSelected(self.TogTabList01)
    end
    local bInParty = TeamData.IsInParty()
    local bInRaid = TeamData.IsInRaid()
    UIHelper.SetVisible(self.ImgBgTitleLine, not (bSelected and not bInParty))

    local teamNode = self.WidgetAnchorContentRight:getChildByName("WidgetTeamScene")
    local raidNode = self.WidgetAnchorContentRight:getChildByName("WidgetTeam")
    if not bInRaid then
        if not teamNode then
            self.teamScript = UIHelper.AddPrefab(PREFAB_ID.WidgetTeamScene, self.WidgetAnchorContentRight, self.m_scene, self.tPos)
            -- UIHelper.SetVisible(self.ItemMiniScene, bSelected and bInParty)
            -- UIHelper.SetVisible(self.ImgBgMask, bSelected and bInParty)
            UIHelper.SetVisible(self.teamScript._rootNode, bSelected)
            self.teamScript:SetModelVisible(bSelected)
        else
            -- UIHelper.SetVisible(self.ItemMiniScene, bSelected and bInParty)
            -- UIHelper.SetVisible(self.ImgBgMask, bSelected and bInParty)
            UIHelper.SetVisible(teamNode, bSelected)
            local script = UIHelper.GetBindScript(teamNode)
            script:SetModelVisible(bSelected)
        end
    else
        if teamNode then
            teamNode:removeFromParent(true)
        end
        -- UIHelper.SetVisible(self.ItemMiniScene, false)
        -- UIHelper.SetVisible(self.ImgBgMask, false)
    end

    if bInRaid then
        if not raidNode then
            local raidScript = UIHelper.AddPrefab(PREFAB_ID.WidgetTeam, self.WidgetAnchorContentRight)
            UIHelper.SetVisible(raidScript._rootNode, bSelected)
        else
            UIHelper.SetVisible(raidNode, bSelected)
        end
    else
        if raidNode then
            raidNode:removeFromParent(true)
        end
    end

    UIHelper.LayoutDoLayout(self.ToggleGroupNaviList)

    if bSelected then
        self:UpdateSceneVisible(TeamData.IsInParty())
    end
end

function UITeamMainView:UpdateManageTab(bSelected)
    if bSelected == nil then
        bSelected = UIHelper.GetSelected(self.TogTabList02)
    end
    -- local bVisible = not table_is_empty(TeamBuilding.tbSelfRecruitInfo)
    local bVisible = true
    if not bVisible and UIHelper.GetSelected(self.TogTabList02) then
        UIHelper.SetSelected(self.TogTabList, true)
    end
    UIHelper.SetVisible(self.TogTabList02, bVisible)
    UIHelper.LayoutDoLayout(self.ToggleGroupNaviList)

    if bSelected then
        self:UpdateSceneVisible(false)
    end
end

function UITeamMainView:UpdateRoomTab(bSelected)
    if bSelected == nil then
        bSelected = UIHelper.GetSelected(self.TogTabList03)
    end
    if bSelected and not self.roomScript then
        self.roomScript = UIHelper.AddPrefab(PREFAB_ID.WidgetCrossServerRoom, self.WidgetAnchorContentRight)
    end
    if self.roomScript then
        UIHelper.SetVisible(self.roomScript._rootNode, bSelected)
    end

    if bSelected then
       self:UpdateSceneVisible(RoomData.IsHaveRoom())
    end
end

function UITeamMainView:SetSceneCamera(args)
    if args.camera == nil then
        local xp = args[1]
        local yp = args[2]
        local zp = args[3]
        local xl = args[4]
        local yl = args[5]
        local zl = args[6]
        local p1 = args[7]
        local p2 = args[8]
        local p3 = args[9]
        local p4 = args[10]
        local bPerspective = args[11]

        self.m_scene:SetCameraLookAtPosition(xl, yl, zl)
        self.m_scene:SetMainPlayerPosition(xl, yl, zl)
        self.m_scene:SetCameraPosition(xp, yp, zp)

        if bPerspective then
            self.m_scene:SetCameraPerspective(p1, p2, p3, p4)
        else
            self.m_scene:SetCameraOrthogonal(p1, p2, p3, p4)
        end
    else
        local c = args.camera
        if c ~= nil then
            self.m_scene:SetCameraPosition(c[1], c[2], c[3])
        end

        local l = args.lookat
        if l ~= nil then
            self.m_scene:SetCameraLookAtPosition(l[1], l[2], l[3])
        end

        local p = args.player
        if p ~= nil then
            self.m_scene:SetMainPlayerPosition(p[1], p[2], p[3])
        else
            self.m_scene:SetMainPlayerPosition(l[1], l[2], l[3])
        end

        local fovy = args.fovy
        if fovy ~= nil then
            local aspect = args.aspect
            local z_near = args.z_near
            local z_far = args.z_far

            self.m_scene:SetCameraPerspective(fovy, aspect, z_near, z_far)
        end

        local width = args.width
        if width ~= nil then
            local height = args.height
            local z_near = args.z_near
            local z_far = args.z_far

            self.m_scene:SetCameraOrthogonal(width, height, z_near, z_far)
        end
    end
end

function UITeamMainView:UpdateSceneVisible(bVisible)
    UIHelper.SetVisible(self.WidgetMiniScene, bVisible)
    UIHelper.SetVisible(self.WidgetSfx, not bVisible)
    if bVisible then
        if UIMgr.IsLayerVisible(UILayer.Scene) then
            UIMgr.HideLayer(UILayer.Scene)
        end
    end
end

function UITeamMainView:UpdateGuanZhanRedpoint()
    UIHelper.SetVisible(self.ImgRedPointGuanZhan, not APIHelper.IsDid(SZ_KEY_GUANZHAN_REDPOINT))
end

return UITeamMainView