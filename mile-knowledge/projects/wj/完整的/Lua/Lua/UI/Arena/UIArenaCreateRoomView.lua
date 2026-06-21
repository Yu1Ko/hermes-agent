-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaCreateRoomView
-- Date: 2022-12-27 10:07:26
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaCreateRoomView = class("UIArenaCreateRoomView")

local TogModeConfig = {
    {nIndex = 1, nValue = ARENA_UI_TYPE.ARENA_2V2, szName = "2 对 2"},
    {nIndex = 2, nValue = ARENA_UI_TYPE.ARENA_3V3, szName = "3 对 3"},
    {nIndex = 3, nValue = ARENA_UI_TYPE.ARENA_5V5, szName = "5 对 5"},
}

local TogSideConfig = {
    {nIndex = 1, nValue = 0, szName = "红方"},
    {nIndex = 2, nValue = 1, szName = "蓝方"},
    -- {nIndex = 3, nValue = 2, szName = "访客"},
}

local MenuType = {
    Map = 1,
    Mode = 2,
    Side = 3,
}

function UIArenaCreateRoomView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self:InitMapConfig()
        self.bInit = true
    end

    self.tbCurSelectInfo = {self.tbTogMapConfig[1], TogModeConfig[1], TogSideConfig[1]}
    self:CloseAllTip()
    self:UpdateInfo()
end

function UIArenaCreateRoomView:OnExit()
    self.bInit = false
end

function UIArenaCreateRoomView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        ArenaData.SetCacheData("nCreateRoomSide", self.tbCurSelectInfo[MenuType.Side].nValue)
        ArenaData.CreatePracticeRoom(self.tbCurSelectInfo[MenuType.Map].nValue, self.tbCurSelectInfo[MenuType.Mode].nValue)
    end)

    UIHelper.BindUIEvent(self.TogMenuMap, EventType.OnClick, function()
        UIHelper.SetSelected(self.TogMenuMode, false)
        UIHelper.SetSelected(self.TogMenuSide, false)
        UIHelper.SetToggleGroupSelected(self.WidgetMapTitle, self.tbCurSelectInfo[MenuType.Map].nIndex - 1)
    end)

    UIHelper.BindUIEvent(self.TogMenuMode, EventType.OnClick, function()
        UIHelper.SetSelected(self.TogMenuMap, false)
        UIHelper.SetSelected(self.TogMenuSide, false)
        UIHelper.SetToggleGroupSelected(self.WidgetModelTitle, self.tbCurSelectInfo[MenuType.Mode].nIndex - 1)
    end)

    UIHelper.BindUIEvent(self.TogMenuSide, EventType.OnClick, function()
        UIHelper.SetSelected(self.TogMenuMap, false)
        UIHelper.SetSelected(self.TogMenuMode, false)
        UIHelper.SetToggleGroupSelected(self.WidgetIdentityTitle, self.tbCurSelectInfo[MenuType.Side].nIndex - 1)
    end)
end

function UIArenaCreateRoomView:RegEvent()
    Event.Reg(self, "ON_CREATE_ARENA_ROOM_NOTIFY", function(nRoomKey, bSuccess)
		if bSuccess == ARENA_RESULT_CODE.SUCCESS then
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

function UIArenaCreateRoomView:InitMapConfig()
    self.tbTogMapConfig = {
        {nIndex = 1, nValue = 0, szName = "随机地图"},
    }

    local tCorpsMap = Table_GetMapInfoIdxByMapID()
    local nIndex = 2
    for i, tItem in custom_pairs(tCorpsMap, function(a, b) if a < b then return true end end) do --TODO Sorted by mapID
        local tbInfo = {nIndex = nIndex, nValue = tItem.nMapID, szName = UIHelper.GBKToUTF8(tItem.szMapName)}
        table.insert(self.tbTogMapConfig, tbInfo)
        nIndex = nIndex + 1
    end
end

function UIArenaCreateRoomView:UpdateInfo()
    self:UpdateMenuInfo(MenuType.Map, self.tbTogMapConfig, self.LabelChooseMap, self.tbTogMap, self.WidgetMapTitle)
    self:UpdateMenuInfo(MenuType.Mode, TogModeConfig, self.LabelChooseMode, self.tbTogMode, self.WidgetModelTitle)
    self:UpdateMenuInfo(MenuType.Side, TogSideConfig, self.LabelChooseSide, self.tbTogSide, self.WidgetIdentityTitle)


end

function UIArenaCreateRoomView:UpdateMenuInfo(nMenuType, tbConfig, labelCur, tbTogList, toggleGroup)
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

    if nMenuType == MenuType.Map then
        UIHelper.ScrollViewDoLayout(self.ScrollViewMap)
        UIHelper.ScrollToTop(self.ScrollViewMap, 0)
    end

    UIHelper.SetToggleGroupSelected(toggleGroup, 0)

    self:UpdateCurSelectInfo(nMenuType, labelCur, tbInfo)
end

function UIArenaCreateRoomView:UpdateCurSelectInfo(nMenuType, labelCur)
    local tbInfo = self.tbCurSelectInfo[nMenuType]
    UIHelper.SetString(labelCur, tbInfo.szName)
end

function UIArenaCreateRoomView:CloseAllTip()
    UIHelper.SetSelected(self.TogMenuMap, false)
    UIHelper.SetSelected(self.TogMenuMode, false)
    UIHelper.SetSelected(self.TogMenuSide, false)
end

return UIArenaCreateRoomView