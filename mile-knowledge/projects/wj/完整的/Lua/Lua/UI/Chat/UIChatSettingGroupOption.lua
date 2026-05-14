-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIChatSettingGroupOption
-- Date: 2022-12-13 19:53:04
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIChatSettingGroupOption = class("UIChatSettingGroupOption")

function UIChatSettingGroupOption:OnEnter(nIndex, szUIChannel, szGroupType, nMinSelect, nMaxSelect, bUnCheckAble, szName, bSelected, tbOneChannel, selectCheck, unSelectCheck)
    self.nIndex = nIndex
    self.szUIChannel = szUIChannel
    self.szGroupType = szGroupType
    self.nMinSelect = nMinSelect
    self.nMaxSelect = nMaxSelect
    self.bUnCheckAble = bUnCheckAble
    self.szName = szName
    self.bSelected = bSelected
    self.tbOneChannel = tbOneChannel
    self.selectCheck = selectCheck
    self.unSelectCheck = unSelectCheck

    self.bOnlyOne = (self.nMaxSelect == 1 and self.nMinSelect == 1)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChatSettingGroupOption:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChatSettingGroupOption:BindUIEvent()
    UIHelper.BindUIEvent(self.WidgetChatSettingGroupOption, EventType.OnSelectChanged, function(btn, bSelected)
        UIHelper.UnBindUIEvent(self.WidgetChatSettingGroupOption, EventType.OnClick)
        if self.bSelected == bSelected then
            UIHelper.BindUIEvent(self.WidgetChatSettingGroupOption, EventType.OnClick, function()
                if self.bSelected then
                    if self.bUnCheckAble == false then
                        TipsHelper.ShowNormalTip("该频道不可隐藏")
                        return
                    end

                    if self.bOnlyOne then
                        TipsHelper.ShowNormalTip(string.format("至少要选择%s项", g_tStrings.STR_NUMBER[self.nMinSelect]))
                    end
                end
            end)
            return
        end

        self.bSelected = bSelected

        if self.nToggleGroupIndex == -1 then
            if bSelected then
                if self.selectCheck then
                    local bFlag = self.selectCheck()
                    if not bFlag then
                        Timer.DelTimer(self, self.nSelectTimerID)
                        self.nSelectTimerID = Timer.AddFrame(self, 1, function()
                            self:SetSelected(false)
                        end)
                        return
                    end
                end
            else
                if self.unSelectCheck then
                    local bFlag = true

                    if self.bUnCheckAble == false then
                        bFlag = false
                        TipsHelper.ShowNormalTip("该频道不可隐藏")
                    else
                        bFlag = self.unSelectCheck()
                    end

                    if not bFlag then
                        Timer.DelTimer(self, self.nUnSelectTimerID)
                        self.nUnSelectTimerID = Timer.AddFrame(self, 1, function()
                            self:SetSelected(true)
                        end)
                        return
                    end
                end
            end
        end

        Event.Dispatch(EventType.OnChatSettingChanged, self.szUIChannel, self.szGroupType, self.szName, bSelected)
    end)

end

function UIChatSettingGroupOption:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIChatSettingGroupOption:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatSettingGroupOption:UpdateInfo()
    local szUIChannel = self.tbOneChannel and self.tbOneChannel.szUIChannel
    if string.is_nil(szUIChannel) then
        UIHelper.SetString(self.LabelOption, self.szName)
    else
        local szName = ChatData.GetUIChannelNickName(szUIChannel)
        UIHelper.SetString(self.LabelOption, szName)
    end

    if self.bSelected then
        UIHelper.SetSelected(self.WidgetChatSettingGroupOption, true)
    end

    self.nToggleGroupIndex = self.bOnlyOne and (ToggleGroupIndex.UIChatSettingGroupOption + self.nIndex) or -1
    UIHelper.SetToggleGroupIndex(self.WidgetChatSettingGroupOption, self.nToggleGroupIndex)

    UIHelper.SetNodeSwallowTouches(self._rootNode, false, true)

    if self.bUnCheckAble == false then
        UIHelper.SetTextColor(self.LabelOption, cc.c4b(127,131,132,255))
    end
end

function UIChatSettingGroupOption:IsSelected()
    return self.bSelected
end

function UIChatSettingGroupOption:SetSelected(bSelected)
    if self.bSelected == bSelected then return end
    UIHelper.SetSelected(self.WidgetChatSettingGroupOption, bSelected)
    self.bSelected = bSelected
end

function UIChatSettingGroupOption:Init(szName, bSelected, func)
    if szName then
        UIHelper.SetString(self.LabelOption, szName)
    end
    UIHelper.BindUIEvent(self.WidgetChatSettingGroupOption, EventType.OnSelectChanged, function(toggle, bSel)
        if func then
            func(bSel)
        end
    end)
    UIHelper.SetSelected(self.WidgetChatSettingGroupOption, bSelected, false)
end



return UIChatSettingGroupOption