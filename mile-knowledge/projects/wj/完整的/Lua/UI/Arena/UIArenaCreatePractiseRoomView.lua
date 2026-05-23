-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaCreatePractiseRoomView
-- Date: 2023-12-04 20:33:11
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaCreatePractiseRoomView = class("UIArenaCreatePractiseRoomView")

local TogModeConfig = {
    {nIndex = 1, nValue = ARENA_UI_TYPE.ARENA_2V2, szName = "2 对 2"},
    {nIndex = 2, nValue = ARENA_UI_TYPE.ARENA_3V3, szName = "3 对 3"},
}

local TogStrengthConfig = {
    {nIndex = 1, nValue = ARENA_GAME_TYPE.PRACTICE_LV1, szName = "普通"},
    {nIndex = 2, nValue = ARENA_GAME_TYPE.PRACTICE_LV2, szName = "中等"},
    {nIndex = 3, nValue = ARENA_GAME_TYPE.PRACTICE_LV3, szName = "困难"},
}

local MenuType = {
    Mode    = 1,
    Strength = 2,
}

function UIArenaCreatePractiseRoomView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbCurSelectInfo = {TogModeConfig[1], TogStrengthConfig[1]}
    self:CloseAllTip()
    self:UpdateInfo()
end

function UIArenaCreatePractiseRoomView:OnExit()
    self.bInit = false
end

function UIArenaCreatePractiseRoomView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnSure, EventType.OnClick, function()
        ArenaData.JoinArenaQueue(self.tbCurSelectInfo[MenuType.Mode].nValue, false, self.tbCurSelectInfo[MenuType.Strength].nValue, false)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogStrengthMenu, EventType.OnClick, function()
        UIHelper.SetSelected(self.TogModelMenu, false)
        UIHelper.SetToggleGroupSelected(self.WidgetMapTitle, self.tbCurSelectInfo[MenuType.Strength].nIndex - 1)
    end)

    UIHelper.BindUIEvent(self.TogModelMenu, EventType.OnClick, function()
        UIHelper.SetSelected(self.TogStrengthMenu, false)
        UIHelper.SetToggleGroupSelected(self.WidgetModelTitle, self.tbCurSelectInfo[MenuType.Mode].nIndex - 1)
    end)
end

function UIArenaCreatePractiseRoomView:RegEvent()
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

function UIArenaCreatePractiseRoomView:UpdateInfo()
    self:UpdateMenuInfo(MenuType.Mode, TogModeConfig, self.LabelNum, self.tbTogMode, self.TogGroupMode)
    self:UpdateMenuInfo(MenuType.Strength, TogStrengthConfig, self.LabelStrength, self.tbTogStrength, self.TogGroupStrength)
end

function UIArenaCreatePractiseRoomView:UpdateMenuInfo(nMenuType, tbConfig, labelCur, tbTogList, toggleGroup)
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

    UIHelper.SetToggleGroupSelected(toggleGroup, 0)

    self:UpdateCurSelectInfo(nMenuType, labelCur, tbInfo)
end

function UIArenaCreatePractiseRoomView:UpdateCurSelectInfo(nMenuType, labelCur)
    local tbInfo = self.tbCurSelectInfo[nMenuType]
    UIHelper.SetString(labelCur, tbInfo.szName)
end

function UIArenaCreatePractiseRoomView:CloseAllTip()
    UIHelper.SetSelected(self.TogModelMenu, false)
    UIHelper.SetSelected(self.TogStrengthMenu, false)
end

return UIArenaCreatePractiseRoomView