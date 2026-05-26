-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaJoinRoomView
-- Date: 2022-12-27 10:12:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaJoinRoomView = class("UIArenaJoinRoomView")

local MenuType = {
    Side = 1,
}

local TogSideConfig = {
    {nIndex = 1, nValue = 0, szName = "红方"},
    {nIndex = 2, nValue = 1, szName = "蓝方"},
    -- {nIndex = 3, nValue = 2, szName = "访客"},
}

function UIArenaJoinRoomView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbCurSelectInfo = {TogSideConfig[1]}
    self:CloseAllTip()
    self:UpdateInfo()
end

function UIArenaJoinRoomView:OnExit()
    self.bInit = false
end

function UIArenaJoinRoomView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnPersonal, EventType.OnClick, function()
        local szRoomID = UIHelper.GetText(self.EditBoxID)
        if string.is_nil(szRoomID) then
            TipsHelper.ShowNormalTip("请先输入房间号", false)
            return
        end
        ArenaData.JoinPracticeRoom(szRoomID, self.tbCurSelectInfo[MenuType.Side].nValue, false, false)
    end)

    UIHelper.BindUIEvent(self.BtnTeam, EventType.OnClick, function()
        local szRoomID = UIHelper.GetText(self.EditBoxID)
        if string.is_nil(szRoomID) then
            TipsHelper.ShowNormalTip("请先输入房间号", false)
            return
        end
        ArenaData.JoinPracticeRoom(szRoomID, self.tbCurSelectInfo[MenuType.Side].nValue, true, false)
    end)

    UIHelper.BindUIEvent(self.TogMenuSide, EventType.OnClick, function()
        UIHelper.SetToggleGroupSelected(self.WidgetIdentity, self.tbCurSelectInfo[MenuType.Side].nIndex - 1)
    end)
end

function UIArenaJoinRoomView:RegEvent()
    Event.Reg(self, "JOIN_ARENA_QUEUE", function(nErrorCode, dwErrorRoleID, szErrorRoleName)
        if nErrorCode == ARENA_RESULT_CODE.SUCCESS then
            UIMgr.Close(self)
        end
    end)

    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        self:CloseAllTip()
    end)

    Event.Reg(self, "SCENE_BEGIN_LOAD", function()
        UIMgr.Close(self)
    end)
end

function UIArenaJoinRoomView:UpdateInfo()
    self:UpdateMenuInfo(MenuType.Side, TogSideConfig, self.LabelChooseSide, self.tbTogSide, self.WidgetIdentity)
end

function UIArenaJoinRoomView:UpdateMenuInfo(nMenuType, tbConfig, labelCur, tbTogList, toggleGroup)
    for i, tog in ipairs(tbTogList) do
        local tbInfo = tbConfig[i]
        if not tbInfo then
            UIHelper.SetVisible(tog, false)
        else
            UIHelper.SetVisible(tog, true)
            UIHelper.ToggleGroupAddToggle(toggleGroup, tog)
            UIHelper.BindUIEvent(tog, EventType.OnClick, function()
                self.tbCurSelectInfo[nMenuType] = tbInfo
                self:UpdateCurSelectInfo(nMenuType, labelCur)
                self:CloseAllTip()
            end)
        end
    end

    self:UpdateCurSelectInfo(nMenuType, labelCur, tbInfo)
end

function UIArenaJoinRoomView:UpdateCurSelectInfo(nMenuType, labelCur)
    local tbInfo = self.tbCurSelectInfo[nMenuType]
    UIHelper.SetString(labelCur, tbInfo.szName)
end

function UIArenaJoinRoomView:CloseAllTip()
    UIHelper.SetSelected(self.TogMenuSide, false)
end


return UIArenaJoinRoomView