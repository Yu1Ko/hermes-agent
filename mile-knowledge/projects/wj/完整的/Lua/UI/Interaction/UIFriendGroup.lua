-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIFriendGroup
-- Date: 2022-11-22 20:50:10
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIFriendGroup = class("UIFriendGroup")
local MENTOR_PANEL_APPLY = 3

function UIFriendGroup:OnEnter(nIndex, tbPlayerCell)
    if not tbPlayerCell then
        return
    end

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nFriendListIndex = nIndex
    self:UpdateInfo(tbPlayerCell)
end

function UIFriendGroup:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFriendGroup:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function ()
        local szConfirmContent = string.format(g_tStrings.STR_CONFIRM_DEL_FRIEND_GROUP, self.name)
        UIHelper.ShowConfirm(szConfirmContent, function ()
            local nResultCode = FellowshipData.DelFellowshipGroup(self.id)
            if nResultCode ~= PLAYER_FELLOWSHIP_RESPOND.SUCCESS then
                Global.OnFellowshipMessage(nResultCode)
            end
            Event.Dispatch(EventType.OnUpdateFellowShip)
        end, nil, false)
    end)

    UIHelper.BindUIEvent(self.BtnAlter, EventType.OnClick, function ()
        local editBox = UIMgr.Open(VIEW_ID.PanelPromptPop, self.name, g_tStrings.STR_SET_FRIEND_GROUP_NAME_TIP_CONTENT, function (szText)
            if szText == self.name then return end

            if szText == "" then
                TipsHelper.ShowNormalTip(g_tStrings.STR_MSG_GROUP_NAME_EMPTY)
                return
            end
            if not FellowshipData.CheckGroupName(UIHelper.UTF8ToGBK(szText)) then
                TipsHelper.ShowNormalTip(g_tStrings.STR_MSG_GROUP_EXIST)
                return
            end

            local nResultCode = FellowshipData.RenameFellowshipGroup(self.id, UIHelper.UTF8ToGBK(szText))
            if nResultCode ~= PLAYER_FELLOWSHIP_RESPOND.RENAME_GROUP_SUCCESS then
                Global.OnFellowshipMessage(nResultCode)
            end
        end)
        editBox:SetTitle(g_tStrings.STR_FRIEND_CHANG_G_NAME)
        editBox:SetMaxLength(15)
    end)

    UIHelper.BindUIEvent(self.TogSelect, EventType.OnClick, function ()
        self.bSelected = not self.bSelected
        self:OnSelectedChange(self.bSelected)
    end)
end

function UIFriendGroup:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIFriendGroup:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFriendGroup:UpdateInfo(tbPlayerCell)
    if tbPlayerCell.bInEditor then
        UIHelper.SetVisible(self.WidgetEditor, true)
        UIHelper.SetVisible(self.TogSelect, false)
        UIHelper.SetString(self.LabelGroupNameEditor, tbPlayerCell.szTitle)
        self.id = tbPlayerCell.id
        self.name = tbPlayerCell.szTitle
    else
        UIHelper.SetVisible(self.TogSelect, true)
        UIHelper.SetSelected(self.TogSelect, tbPlayerCell.bSelected)
        UIHelper.SetString(self.LabelNum, tbPlayerCell.szNum)
        self.bSelected = tbPlayerCell.bSelected
        self.nIndex = tbPlayerCell.nGroupID
        UIHelper.SetString(self.LabelGroupName, tbPlayerCell.szTitle)
        UIHelper.LayoutDoLayout(self.LayoutName)
    end
    UIHelper.WidgetFoceDoAlign(self)
end

function UIFriendGroup:OnSelectedChange(bSelected)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, false)
    if self.toggleCallback then
        self.toggleCallback(bSelected, self.nIndex, self.nFriendListIndex)
    end
end

function UIFriendGroup:SetToggleCallback(toggleCallback)
    self.toggleCallback = toggleCallback
end

function UIFriendGroup:SetVisible(bVisible)
    self.bVisible = bVisible
    UIHelper.SetVisible(self._rootNode, self.bVisible)
end

return UIFriendGroup