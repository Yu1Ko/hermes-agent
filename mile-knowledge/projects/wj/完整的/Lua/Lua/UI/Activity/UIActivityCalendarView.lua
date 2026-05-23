-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIActivityCalendarView
-- Date: 2022-12-05 17:30:17
-- Desc: ?
-- ---------------------------------------------------------------------------------
local TogIndexToActivityType = {
    [1] = ACTIVITY_TYPE.LIKE,
    [2] = ACTIVITY_TYPE.RELAX,
    [3] = ACTIVITY_TYPE.TEAM,
    [4] = ACTIVITY_TYPE.CONFRONT,
    [5] = ACTIVITY_TYPE.HOME,
    [6] = ACTIVITY_TYPE.HISTORY,
}



local UIActivityCalendarView = class("UIActivityCalendarView")

function UIActivityCalendarView:OnEnter(nActivityType, dwActivity)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitData(nActivityType, dwActivity)
    self:UpdateInfo()
end

function UIActivityCalendarView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    UIHelper.PlayAni(self, self.AniAll, "Ani_L_R_BG_Hide")
end

function UIActivityCalendarView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    for nIndex, toggle in ipairs(self.tbToggleGroup) do
        UIHelper.BindUIEvent(toggle, EventType.OnClick, function(toggle)
            Event.Dispatch(EventType.OnTeachButtonClick, VIEW_ID.PanelActivityCalendar, UIHelper.GetName(toggle))
            self:SetCurActivityType(TogIndexToActivityType[nIndex])
            self:SetCurActivityIndex(1)
            self:UpdateInfo()
        end)
    end

    UIHelper.BindUIEvent(self.BtnLeaveFor, EventType.OnClick, function()
        if self.tbActiveInfo.dwID == 633 then
            TipsHelper.ShowNormalTip("剑网3无界端暂不开放此功能")
            return
        end

        local szPanelLink = self.tbActiveInfo.szPanelLink

        if #self.tbTravelList == 1 then
            local tbInfo = self.tbTravelList[1]
            ActivityData.Teleport_Go(tbInfo, self.tbActiveInfo.dwID)
        elseif szPanelLink and szPanelLink ~= "" then
            FireUIEvent("EVENT_LINK_NOTIFY", szPanelLink)
        else
            self:UpdateTravelTargets()
        end
    end)

    UIHelper.BindUIEvent(self.TogLike, EventType.OnClick, function(toggle)
        local bSelect = UIHelper.GetSelected(self.TogLike)
        if bSelect then
            ActivityData.AddLikeActivity(self.tbActiveInfo.dwID, self.tbActiveInfo)
        else
            ActivityData.RemoveLikeActivity(self.tbActiveInfo.dwID)
        end
        if self.nCurActiveType == ACTIVITY_TYPE.LIKE then
            self:SetCurActivityType(self.nCurActiveType)
            self:SetCurActivityIndex(0, true)
            self:UpdateInfo(true)
        end
        Event.Dispatch("OnUpdateActivityRedPoint")
    end)

    UIHelper.BindUIEvent(self.BtnTeam, EventType.OnClick, function()

    end)

    UIHelper.TableView_addCellAtIndexCallback(self.TableViewForce, function(tableView, nIndex, script, node, cell)
        local tbActiveInfo = self.tbActivityList[nIndex]
        if tbActiveInfo and script then
            script:OnEnter(nIndex, tbActiveInfo)
            script:SetSelected(nIndex == self.nCurActivityIndex)
        end
    end)

    UIHelper.BindUIEvent(self.TogType, EventType.OnSelectChanged, function(toggle, bSelect)
        Storage.Activity.bAutoCollect = not bSelect
        Storage.Activity.Dirty()
    end)


    UIHelper.BindUIEvent(self.BtnSendToChat, EventType.OnClick, function()
        local szName = UIHelper.GBKToUTF8(self.tbActiveInfo.szName) or ""
        local szLinkInfo = string.format("LinkActivity/%d", self.tbActiveInfo.dwID)
        ChatHelper.SendEventLinkToChat(szName, szLinkInfo)
    end)
end

function UIActivityCalendarView:RegEvent()
    Event.Reg(self, EventType.OnActivitySelect, function(nIndex)
        self:SetCurActivityIndex(nIndex)
        self:UpdateCurActiveInfo()
    end)

    -- Event.Reg(self, EventType.OnViewOpen, function(nViewID)
    --     if nViewID == VIEW_ID.PanelMiddleMap then
    --         UIMgr.Close(self)
    --     end
    -- end)

    Event.Reg(self, EventType.OnTouchViewBackGround, function ()
        self:CloseTip()
        UIHelper.SetVisible(self.WidgetAnchorLeaveFor, false)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:CloseTip()
        UIHelper.SetVisible(self.WidgetAnchorLeaveFor, false)
    end)

    Event.Reg(self, "DO_SKILL_PREPARE_PROGRESS", function(arg0, arg1, arg2, arg3, arg4)
        local skillName = Table_GetSkillName(arg1, arg2)
        skillName = UIHelper.GBKToUTF8(skillName)

        if skillName == "神行千里" then
            UIMgr.Close(self)
        end
    end)

    Event.Reg(self, "DO_CUSTOM_OTACTION_PROGRESS", function()
        UIMgr.Close(self)
        UIMgr.Close(VIEW_ID.PanelSystemMenu)
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        self:DelayUpdateInfo()
    end)

    Event.Reg(self, EventType.OnSelectLeaveForBtn, function(tbInfo)
        ActivityData.Teleport_Go(tbInfo, self.tbActiveInfo.dwID)
        UIHelper.SetVisible(self.WidgetAnchorLeaveFor, false)
    end)

    Event.Reg(self, EventType.OnRichTextOpenUrl, function(szUrl, node)
        if UIMgr.GetLayerTopViewID(UILayer.Page) ~= VIEW_ID.PanelActivityCalendar then
            return
        end

        APIHelper.HandleRichTextLink(szUrl, node)
    end)
end

function UIActivityCalendarView:UnRegEvent()

end


function UIActivityCalendarView:InitData(nActivityType, dwActivity)
    if not nActivityType then
        local tbLikeActivityList = ActivityData.GetActivityListByType(ACTIVITY_TYPE.LIKE)
        nActivityType = #tbLikeActivityList >= 1 and ACTIVITY_TYPE.LIKE or ACTIVITY_TYPE.RELAX--有收藏默认收藏
    end
    self:SetCurActivityType(nActivityType)
    if dwActivity then
        self:SelectedActivityIndexByActivityID(dwActivity)
    else
        self:SetCurActivityIndex(1)
    end
    self:InitToggleGroup(nActivityType)
    self:InitTogType()
end



function UIActivityCalendarView:InitToggleGroup(nActivityType)
    for index, toggle in ipairs(self.tbToggleGroup) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroup, toggle)
    end

    for index, toggle in ipairs(self.tbToggleGroup) do
        if TogIndexToActivityType[index] == nActivityType then
            UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, toggle)
            break
        end
    end
end

function UIActivityCalendarView:InitTogType()
    UIHelper.SetSelected(self.TogType, not Storage.Activity.bAutoCollect, false)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIActivityCalendarView:DelayUpdateInfo()
    if self.nUpdateTimer then
        Timer.DelTimer(self, self.nUpdateTimer)
    end
    self.nUpdateTimer = Timer.AddFrame(self, 2, function ()
        self:UpdateInfo()
        self.nUpdateTimer = nil
    end)
end

function UIActivityCalendarView:UpdateInfo(bNotUpdateActiveInfo)
    UIHelper.PlayAni(self, self.AniAll, "Ani_L_R_BG_Show")
    local nStartTime = Timer.RealMStimeSinceStartup()
    self:UpdateActiveList()
    if not bNotUpdateActiveInfo then
        self:UpdateCurActiveInfo()
    end
    self:UpdateEmptyContent()
    local nEndTime = Timer.RealMStimeSinceStartup()

end

function UIActivityCalendarView:UpdateEmptyContent()
    UIHelper.SetVisible(self.WidgetAnchirEmpty, self.tbActivityList == nil or #self.tbActivityList == 0)
end


function UIActivityCalendarView:UpdateActiveList()
    UIHelper.SetVisible(self.TableViewMaskForce, self.tbActivityList ~= nil or #self.tbActivityList > 0)
    -- if not self.tbActivityList or #self.tbActivityList == 0 then return end

    UIHelper.TableView_init(self.TableViewForce, #self.tbActivityList, PREFAB_ID.WidgetActivitySelect)
    UIHelper.TableView_reloadData(self.TableViewForce)
end

function UIActivityCalendarView:UpdateCurActiveInfo()
    local nStartTime = Timer.RealMStimeSinceStartup()
    UIHelper.SetVisible(self.WidgetAnchorRight, self.tbActiveInfo ~= nil)
    if not self.tbActiveInfo then return end
    if self.tbActiveInfo then
        local scriptView = UIHelper.GetBindScript(self.WidgetAnchorRight)
        scriptView:OnEnter(self.tbActiveInfo)
    end
    self:UpdateBtnLeaveForState()
    self:UpdateTogLikeState()
    UIHelper.SetVisible(self.WidgetAnchorLeaveFor, false)
    local nEndTime = Timer.RealMStimeSinceStartup()

end

function UIActivityCalendarView:UpdateTogLikeState()
    local bLikeActivity = ActivityData.IsLikeActivity(self.tbActiveInfo.dwID)
    UIHelper.SetSelected(self.TogLike, bLikeActivity, false)
end

function UIActivityCalendarView:UpdateBtnLeaveForState()
    local szPanelLink = self.tbActiveInfo.szPanelLink
    UIHelper.SetVisible(self.BtnLeaveFor, #self.tbTravelList ~= 0 or (szPanelLink and szPanelLink ~= ""))
    UIHelper.LayoutDoLayout(self.WidgetAnchorBtn)
end

function UIActivityCalendarView:UpdateTravelTargets()
    UIHelper.SetVisible(self.WidgetAnchorLeaveFor, true)
    local scriptView = UIHelper.GetBindScript(self.WidgetAnchorLeaveFor)
    if scriptView and self.tbTravelList then
        scriptView:OnEnter(self.tbTravelList)
    end
end

function UIActivityCalendarView:CloseTip()
    local scriptView = UIHelper.GetBindScript(self.WidgetAnchorRight)
    if scriptView then
        scriptView:HideItemTip()
    end
end




function UIActivityCalendarView:SetCurActivityType(nType)
    self.nCurActiveType = nType
    self.tbActivityList = ActivityData.GetActivityListByType(self.nCurActiveType)
end

function UIActivityCalendarView:SetCurActivityInfo(nIndex)
    if self.tbActivityList then
        self.tbActiveInfo = self.tbActivityList[nIndex]
        self:SetCurActivityTravelList()
    else
        self.tbActiveInfo = nil
    end
end

function UIActivityCalendarView:SelectedActivityIndexByActivityID(dwActivity)
    local nSelectIndex = nil
    for nIndex, tbActiveInfo in ipairs(self.tbActivityList) do
        if tbActiveInfo.dwID == dwActivity then
            nSelectIndex = nIndex
            break
        end
    end

    Timer.AddFrame(self, 1, function()--界面刚打开时需要等待整个tableview的最外层组件高度计算完成，不然会滚到错误的位置
        UIHelper.TableView_scrollToCell(self.TableViewForce, #self.tbActivityList, nSelectIndex, 0)
    end)
    self:SetCurActivityIndex(nSelectIndex)

    self:UpdateActiveList()
end

function UIActivityCalendarView:SetCurActivityTypeByActivityID(dwActivity)
    local tbActivity = ActivityData.GetActiveInfo(dwActivity)
    local nTargetType = ClassIDToType[tbActivity.nClass]
    if nTargetType == self.nCurActiveType then
        return
    end
    self:SetCurActivityType(nTargetType)
end

function UIActivityCalendarView:SetCurActivityIndex(nIndex, bNotUpdateInfo)
    self.nCurActivityIndex = nIndex
    if not bNotUpdateInfo then
        self:SetCurActivityInfo(nIndex)
    end
end

function UIActivityCalendarView:SetCurActivityTravelList()
    self.tbTravelList = ActivityData.GetLinkList(self.tbActiveInfo)
end
return UIActivityCalendarView