-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamFindingView
-- Date: 2023-02-08 15:41:52
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITeamFindingView = class("UITeamFindingView")

local LIMIT_APPLY_TEAM = 5



function UITeamFindingView:OnEnter(dwLocateApplyID, dwLocateRecruitID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szSearch = ""

    self.tbBreadNaviCells = {}
    self.tbFilterItemCells = {}
    self.tbCheckedMenu = nil
    self.tbRecruitList = {}
    self.dwLocateApplyID = dwLocateApplyID
    self.dwLocateRecruitID = dwLocateRecruitID
    self.bDescendSortNum = nil
    TeamBuilding.SetApplyDst(self.dwLocateRecruitID)

    local navigationFilter = UIHelper.GetBindScript(self.WidgetAnchorFilter)
    local fnCheckedCallback = function (tbMenu, bLocate)
        self:OnCheckedMenu(tbMenu, bLocate)
    end
    navigationFilter:OnInit(PREFAB_ID.WidgetBreadNaviCell, PREFAB_ID.WidgetFilterItemCell, fnCheckedCallback, nil, nil, PREFAB_ID.WidgetBreadNaviCellLong)

    local widgetSortDown = UIHelper.GetChildByName(self.TogSort, "WidgetDown")
    local widgetSortUp = UIHelper.GetChildByName(self.TogSort, "WidgetUp")
    UIHelper.SetVisible(widgetSortDown, false)
    UIHelper.SetVisible(widgetSortUp, false)
    UIHelper.SetVisible(self.WidgetSortDefault, true)

    local scriptChat = UIHelper.GetBindScript(self.BtnChat)
    if scriptChat then
        scriptChat:OnEnter(UI_Chat_Channel.Team)
    end
    self:UpdateInfo()
    Timer.AddCycle(self, 1, function ()
        self:UpdateRefreshBtn()
    end)
end

function UITeamFindingView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UITeamFindingView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnScreen, EventType.OnClick, function ()
        self:OpenFilterMenu()
    end)

    UIHelper.BindUIEvent(self.BtnClose02, EventType.OnClick, function ()
        self:CloseFilterMenu()
    end)

    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function ()
        self:CloseFilterMenu()
    end)

    UIHelper.BindUIEvent(self.BtnRenovate, EventType.OnClick, function ()
        self.dwLocateApplyID = nil
        TeamBuilding.OnApplyTeamList()
        TeamBuilding.OnApplyInfo(ApplyTeamList, GetGlobalRoomPushClient().SyncPlayerApplyRoomPushList) --获取我申请过的队伍
        TeamBuilding.dwApplyTeam =  GetCurrentTime() + LIMIT_APPLY_TEAM
        self:UpdateRefreshBtn()
    end)

    UIHelper.BindUIEvent(self.BtnReleaseRecruit, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelReleaseRecruitPop, nil, self.dwLocateRecruitID)
    end)

    UIHelper.BindUIEvent(self.BtnClose01, EventType.OnClick, function ()
        UIHelper.SetString(self.EditBox, "")
        self:UpdateRecruitList()
    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function ()
        if self.tbMenu and not table_is_empty(self.tbMenu) then
            local navigationFilter = UIHelper.GetBindScript(self.WidgetAnchorFilter)
            navigationFilter:SetChecked(self.tbMenu)
        end
    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditBox, function()
            self:UpdateRecruitList()
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditBox, function()
            self:UpdateRecruitList()
        end)
    end

    UIHelper.TableView_addCellAtIndexCallback(self.TableView, function(tableView, nIndex, script, node, cell)
        local tbInfo = self.tbRecruitList[nIndex]
        if tbInfo and script then
            local bLocate = false
            if self.dwLocateApplyID then
                if IsString(self.dwLocateApplyID) then
                    bLocate = tbInfo["szRoomID"] == self.dwLocateApplyID
                else
                    bLocate = tbInfo["dwRoleID"] == self.dwLocateApplyID
                end
            end
            script:OnEnter(tbInfo, bLocate)
            TeamBuilding.ApplyLeaderPraise({tbInfo}, 1, 1)
        end
    end)

    UIHelper.BindUIEvent(self.TogSameServer, EventType.OnSelectChanged, function(_, bSelected)
        TeamBuilding.bLocalServer = bSelected
        self:UpdateRecruitList()
    end)

    UIHelper.BindUIEvent(self.TogCrossServer, EventType.OnSelectChanged, function(_, bSelected)
        TeamBuilding.bSwitchServer = bSelected
        self:UpdateRecruitList()
    end)

    UIHelper.BindUIEvent(self.TogRookieGuide, EventType.OnSelectChanged, function (_, bSelected)
        TeamBuilding.bFilterTeachTeam = bSelected
        self:UpdateRecruitList()
    end)

    UIHelper.BindUIEvent(self.TogSort, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self.bDescendSortNum = 0
            self:UpdateRecruitList()
        else
            self.bDescendSortNum = 1
            self:UpdateRecruitList()
        end
        UIHelper.SetVisible(self.WidgetSortDefault, false)
    end)

    UIHelper.BindUIEvent(self.BtnSetting, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelGameSettings, SettingCategory.WordBlock)
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        UIHelper.TableView_scrollToTop(self.TableView)
    end)
end

function UITeamFindingView:RegEvent()
    Event.Reg(self, EventType.OnRecruitPushTeam, function ()
        self:UpdateRecruitList()
        self:UpdateSelfTeamInfo()
    end)

    Event.Reg(self, "ON_SYNC_TEAM_MEMBER_FORCE_ID_NOTIFY", function ()
        UIMgr.Open(VIEW_ID.PanelTeamInfoPop, arg0, nil, arg1)
    end)

    Event.Reg(self, "ON_SYNC_ROOM_MEMBER_FORCE_ID_NOTIFY", function ()
        UIMgr.Open(VIEW_ID.PanelTeamInfoPop, nil, arg0, arg1)
    end)
end

function UITeamFindingView:UnRegEvent()
    Event.UnRegAll()
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamFindingView:UpdateInfo()
    local bRemote = IsRemotePlayer(UI_GetClientPlayerID())
    TeamBuilding.bLocalServer = not bRemote
	TeamBuilding.bSwitchServer = true
    UIHelper.SetSelected(self.TogSameServer, TeamBuilding.bLocalServer, false)
    UIHelper.SetSelected(self.TogCrossServer, TeamBuilding.bSwitchServer, false)
    UIHelper.SetSelected(self.TogRookieGuide, TeamBuilding.bFilterTeachTeam, false)
    UIHelper.SetEnable(self.TogSameServer, not bRemote)

    RemoteCallToServer("On_Zhanchang_GetTodayZhanchang")
    if not TeamBuilding.dwApplyTeam or GetCurrentTime() > TeamBuilding.dwApplyTeam then
        TeamBuilding.tbPraise = {}
        TeamBuilding.OnApplyTeamList()
        TeamBuilding.OnApplyInfo(ApplyTeamList, GetGlobalRoomPushClient().SyncPlayerApplyRoomPushList)
        TeamBuilding.dwApplyTeam =  GetCurrentTime() + LIMIT_APPLY_TEAM
    end
    self:UpdateRefreshBtn()
    self:UpdateRecruitList()
    self:UpdateSelfTeamInfo()
    self:UpdateFilterMenu()
end

function UITeamFindingView:UpdateRecruitList()
    local dwSearchID = nil
    if self.tbCheckedMenu ~= nil then
        dwSearchID = self.tbCheckedMenu.UserData[1]
    end
    local szSearch = UIHelper.GetString(self.EditBox)

    self.tbRecruitList = TeamBuilding.GetFilteredRecruitList(szSearch, dwSearchID) or {}
    if self.bDescendSortNum then
        TeamBuilding.SortByPlayerNumber(self.tbRecruitList, self.bDescendSortNum)
    else
        TeamBuilding.SortByCreateTime(self.tbRecruitList, 1)
    end

    UIHelper.SetVisible(self.TableViewMask, true)
    UIHelper.TableView_init(self.TableView, #self.tbRecruitList, PREFAB_ID.WidgetSeekTeamCell)
    UIHelper.TableView_reloadData(self.TableView)

    if self.dwLocateApplyID then
        for nIndex, tbInfo in ipairs(self.tbRecruitList) do
            local bLocate = false
            if IsString(self.dwLocateApplyID) then
                bLocate = tbInfo["szRoomID"] == self.dwLocateApplyID
            else
                bLocate = tbInfo["dwRoleID"] == self.dwLocateApplyID
            end
            if bLocate then
                UIHelper.TableView_scrollToCellFitTop(self.TableView, #self.tbRecruitList, nIndex, 0)
                break
            end
        end
    end

    UIHelper.SetVisible(self.WidgetEmptySeekTeam, #self.tbRecruitList <= 0)
end

function UITeamFindingView:UpdateSelfTeamInfo()
    local bEnable = g_pClientPlayer.nLevel >= TeamBuilding.GetRequiredPlayerLevel()
    if not bEnable then
        UIHelper.SetButtonState(self.BtnReleaseRecruit, BTN_STATE.Disable, FormatString(g_tStrings.STR_TEAM_BUILDING_REQUIRE_LEVEL_TIP2, TeamBuilding.GetRequiredPlayerLevel()))
        return
    end
    if not table_is_empty(TeamBuilding.tbSelfRecruitInfo) then
        UIHelper.SetButtonState(self.BtnReleaseRecruit, BTN_STATE.Disable)
    else
        UIHelper.SetButtonState(self.BtnReleaseRecruit, BTN_STATE.Normal)
    end
end

function UITeamFindingView:UpdateRefreshBtn()
    local dwCurrentTime = GetCurrentTime()
    if TeamBuilding.dwApplyTeam then
        local nDel = TeamBuilding.dwApplyTeam - dwCurrentTime
        if nDel > 0 then
            UIHelper.SetString(self.LabelRenovate, "刷新列表(" .. nDel .. "秒)")
            UIHelper.SetButtonState(self.BtnRenovate, BTN_STATE.Disable)
        else
            UIHelper.SetString(self.LabelRenovate, "刷新列表")
            UIHelper.SetButtonState(self.BtnRenovate, BTN_STATE.Normal)
        end
    end
end

function UITeamFindingView:OpenFilterMenu()
    UIHelper.SetVisible(self.WidgetAnchorFilterScreen, true)
    local script = UIHelper.GetBindScript(self.PanelTeam)
    UIHelper.PlayAni(script, self.WidgetAnchorFilterScreen, "AniRightShow")
    UIHelper.SetVisible(self.WidgetAnchorRightTop, false)
    UIHelper.SetVisible(self.BtnClose, false)
    self.dwBeforeApplyID = self.tbCheckedMenu and self.tbCheckedMenu.UserData[1]
end

function UITeamFindingView:CloseFilterMenu()
    local script = UIHelper.GetBindScript(self.PanelTeam)
    UIHelper.PlayAni(script, self.WidgetAnchorFilterScreen, "AniRightHide", function ()
        UIHelper.SetVisible(self.WidgetAnchorFilterScreen, false)
        UIHelper.SetVisible(self.WidgetAnchorRightTop, true)
        UIHelper.SetVisible(self.BtnClose, true)
    end)
    -- 目标变更后自动刷新一下
    local dwAfterApplyID = self.tbCheckedMenu and self.tbCheckedMenu.UserData[1]
    if self.dwBeforeApplyID ~= dwAfterApplyID then
        TeamBuilding.OnApplyTeamList()
    end
    self.dwBeforeApplyID = nil
end

function UITeamFindingView:UpdateFilterMenu()
    local tbMenu = {}
    local tbAll = Table_GetTeamRecruit()
    local tbLocateMenu = {}

    TeamBuilding.OnGetTeamRecruitDynamic(tbMenu)

    for _, v1 in ipairs(tbAll) do
        local tbSuperMenu = {}
        local tbSuperID = {}
        for _, v2 in ipairs(v1) do
            local tbSubMenu = {}
            if v2.bParent then
                local tbSubID = {}
				for _, v3 in ipairs(v2) do
					local bShow = TeamBuilding.UseSubMenu(v3)
                    local bLocate = self.dwLocateRecruitID and v3.dwID == self.dwLocateRecruitID
					if bShow or bLocate then
                        local szName = UIHelper.GBKToUTF8(v3.szName)
                        if v3.bSwitchServer then
                            szName = g_tStrings.STR_SWICTH_SEVER .. szName
                        end
						local tbLastMenu = TeamBuilding.GetCheckedMenu(szName, true, false, {v3.dwID, v3.szName}, nil, v3.bMark)
						table.insert(tbSubMenu, tbLastMenu)
						table.insert(tbSubID, v3.dwID)
						table.insert(tbSuperID, v3.dwID)
                        if bLocate then
                            table.insert(tbLocateMenu, tbSuperMenu)
                            table.insert(tbLocateMenu, tbSubMenu)
                            table.insert(tbLocateMenu, tbLastMenu)
                        end
					end
				end
                if not table_is_empty(tbSubMenu) then
                    if #tbSubMenu <= 14 then --逻辑超过20个类型会报错，只能用奇怪的方式限制一下
                        local tbFirstMenu = TeamBuilding.GetCheckedMenu(g_tStrings.STR_GUILD_ALL, true, false, {tbSubID, v2.SubTypeName}, nil, false)
                        table.insert(tbSubMenu, 1, tbFirstMenu)
                    end
                    TeamBuilding.SetMenuInfo(tbSubMenu, UIHelper.GBKToUTF8(v2.SubTypeName), false, false, {v2.SubType, v2.SubTypeName}, nil, v2.bMark)
                    table.insert(tbSuperMenu, tbSubMenu)
				end
            else
                local bShow = TeamBuilding.UseSubMenu(v2)
                local bLocate = self.dwLocateRecruitID and v2.dwID == self.dwLocateRecruitID
				if bShow or bLocate then
                    local szName = UIHelper.GBKToUTF8(v2.szName)
                    if v2.bSwitchServer then
                        szName = g_tStrings.STR_SWICTH_SEVER .. szName
                    end
					tbSubMenu = TeamBuilding.GetCheckedMenu(szName, true, false, {v2.dwID, v2.szName}, nil, v2.bMark)
					table.insert(tbSuperMenu, tbSubMenu)
					table.insert(tbSuperID, v2.dwID)
                    if bLocate then
                        table.insert(tbLocateMenu, tbSuperMenu)
                        table.insert(tbLocateMenu, tbSubMenu)
                    end
				end
            end
            if not table_is_empty(tbSuperMenu) then
                TeamBuilding.SetMenuInfo(tbSuperMenu, UIHelper.GBKToUTF8(v1.TypeName), false, false, {v1.Type, v1.TypeName}, nil, v1.bMark)
            end
        end
        if not table_is_empty(tbSuperMenu) then
			if #tbSuperMenu <= 14 then
                local bLocate = IsTable(self.dwLocateRecruitID) and IsTableEqual(tbSuperID, self.dwLocateRecruitID)
				local tbFirstMenu = TeamBuilding.GetCheckedMenu(g_tStrings.STR_GUILD_ALL, true, false, {tbSuperID, UIHelper.UTF8ToGBK(tbSuperMenu.szOption), nil}, nil, false)
				table.insert(tbSuperMenu, 1, tbFirstMenu)
                if bLocate then
                    table.insert(tbLocateMenu, tbSuperMenu)
                    table.insert(tbLocateMenu, tbFirstMenu)
                end
			end
			table.insert(tbMenu, tbSuperMenu)
		end
    end
    if not table_is_empty(tbMenu) then
        TeamBuilding.SetMenuInfo(tbMenu, "活动类型", false, false, {0, "活动类型"}, nil, false)
        local navigationFilter = UIHelper.GetBindScript(self.WidgetAnchorFilter)
        navigationFilter:SetChecked(tbMenu, true)
    end
    UIHelper.SetVisible(self.WidgetEmpty, table_is_empty(tbMenu))
    UIHelper.SetVisible(self.ImgLine, not table_is_empty(tbMenu))
    self.tbMenu = tbMenu

    for _, v in ipairs(tbLocateMenu) do
        local navigationFilter = UIHelper.GetBindScript(self.WidgetAnchorFilter)
        navigationFilter:SetChecked(v, true)
    end
end

function UITeamFindingView:OnCheckedMenu(tbMenu, bLocate)
    self.tbCheckedMenu = tbMenu
    if tbMenu ~= nil then
        UIHelper.SetVisible(self.LabelCurrentTarget, true)
        UIHelper.SetString(self.LabelCurrentTarget, string.format("当前目标：%s", tbMenu.szOption))
        UIHelper.SetSpriteFrame(self.ImgScreenIcon, "UIAtlas2_Public_PublicButton_PublicButton1_icon_screen_ing")
    else
        UIHelper.SetVisible(self.LabelCurrentTarget, false)
        UIHelper.SetSpriteFrame(self.ImgScreenIcon, "UIAtlas2_Public_PublicButton_PublicButton1_icon_screen")
    end
    UIHelper.LayoutDoLayout(self.WidgetAnchorRightTop)

    if not bLocate then
        self.dwLocateRecruitID = nil
        TeamBuilding.SetApplyDst(tbMenu and tbMenu.UserData[1])
        if tbMenu then
            self:CloseFilterMenu()
        end
    end
end

function UITeamFindingView:LocateApply(dwLocateApplyID)
    self.dwLocateApplyID = dwLocateApplyID
    self.dwLocateRecruitID = nil
    if self.tbMenu and not table_is_empty(self.tbMenu) then
        local navigationFilter = UIHelper.GetBindScript(self.WidgetAnchorFilter)
        navigationFilter:SetChecked(self.tbMenu, true)
    end
    TeamBuilding.SetApplyDst(nil)
    TeamBuilding.OnApplyTeamList()
end

return UITeamFindingView