-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIChatSettingView
-- Date: 2022-12-12 17:42:21
-- Desc: 聊天设置界面
-- ---------------------------------------------------------------------------------

local UIChatSettingView = class("UIChatSettingView")

function UIChatSettingView:OnEnter(nIndex)
    self.nIndex = nIndex

    self.tbTempData = Lib.copyTab(ChatData.GetRuntimeData())

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()

    ChatData.SyncChatSetting()
end

function UIChatSettingView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChatSettingView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnRecover, EventType.OnClick, function(btn)
        --UIHelper.ShowConfirm("恢复")

        local tbSettingConf = ChatSetting[self.nIndex]
        local szUIChannel = tbSettingConf and tbSettingConf.szUIChannel

        ChatData.RecoverRuntimeData(szUIChannel)
        ChatData.RecoverUIChannelNickName(szUIChannel)
        ChatData.SaveRuntimeData()

        self.tbTempData = Lib.copyTab(ChatData.GetRuntimeData())
        self:UpdateInfo_Group()

        Event.Dispatch(EventType.OnChatSettingSaved, true)
    end)

    UIHelper.BindUIEvent(self.BtnSave, EventType.OnClick, function(btn)
        ChatData.SetRuntimeData(self.tbTempData)
        ChatData.SaveRuntimeData()

        if GameSettingData.GetNewValue(UISettingKey.SyncChatSetting) then
            ChatData.SaveRuntimeData_ToServer(true)
        end

        Event.Dispatch(EventType.OnChatSettingSaved, true)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnChangeName, EventType.OnClick, function(btn)
        local tbSettingConf = ChatSetting[self.nIndex]
        local szUIChannel = tbSettingConf and tbSettingConf.szUIChannel
        local szUIChannelName = ChatData.GetUIChannelNickName(szUIChannel)

        local editBox = UIMgr.Open(VIEW_ID.PanelPromptPop, "", "请输入新的频道名字，字数不能超过2个中文字符", function (szText)
            if string.is_nil(szText) then
                TipsHelper.ShowNormalTip("频道名字不能为空。")
                return
            end

            local chinese, english = APIHelper.CountChineseAndEnglish(szText)
            if chinese > 2 or
                (chinese == 2 and english > 0) or
                (chinese == 1 and english > 2) or
                (chinese == 0 and english > 4) then
                    TipsHelper.ShowNormalTip("字数超出限制，请重新输入。")
                    return
            end

            if not TextFilterCheck(UIHelper.UTF8ToGBK(szText)) then --过滤文字
                TipsHelper.ShowNormalTip(g_tStrings.STR_FACE_RENAME_ERROR)
                return
            end

            self:_doChangeName(szText)
            TipsHelper.ShowNormalTip("频道改名成功。")
            UIMgr.Close(VIEW_ID.PanelPromptPop)
        end)
        if editBox then
            editBox:SetPlaceHolder(szUIChannelName)
            editBox:SetMaxLength(10)
            editBox:SetTitle("频道改名")
            editBox:SetConfirmCloseSelf(false)
        end
    end)
end

function UIChatSettingView:RegEvent()
    Event.Reg(self, EventType.OnChatSettingSyncServerData, function()
        self:OnEnter(self.nIndex)
    end)

    Event.Reg(self, EventType.OnChatSettingChanged, function(szUIChannel, szGroupName, szChannelName, bSelected)
        self:_setSettingData(szUIChannel, szGroupName, szChannelName, bSelected)
    end)
end

function UIChatSettingView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatSettingView:UpdateInfo()
    self:UpdateInfo_LeftList()
    self.widgetArrowDown = UIHelper.FindChildByName(UIHelper.GetParent(self.ScrollViewLeftList), "WidgetArrowDown")
    self.nTimer = Timer.AddFrameCycle(self, 2, function()
        self:UpdateArrow()
    end)
end

function UIChatSettingView:UpdateInfo_LeftList()
    UIHelper.RemoveAllChildren(self.ScrollViewLeftList)

    local nSelectIdx = self.nIndex or 1

    for k, v in ipairs(ChatSetting) do
        if v.bSettable and v.bVisible then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetChatSettingToggle, self.ScrollViewLeftList)
            script:OnEnter(k, v.szName, nSelectIdx == k, v, function() self:Select(k) end)
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewLeftList)

    if self.nIndex > 8 then
        Timer.AddFrame(self, 1, function()
            UIHelper.ScrollToIndex(self.ScrollViewLeftList, self.nIndex - 1)
        end)
    else
        UIHelper.ScrollToTop(self.ScrollViewLeftList)
    end
end

function UIChatSettingView:UpdateInfo_Group()
    UIHelper.RemoveAllChildren(self.ScrollViewRightList)

    local tbConf = ChatSetting[self.nIndex]
    if not tbConf then return end
    local szUIChannel = tbConf.szUIChannel

    for k, v in ipairs(tbConf.tbGroupList) do
        if v.bVisible then
            local nPrefabID = PREFAB_ID.WidgetChatSettingGroup
            local tbSettingData = self:_getSettingData(szUIChannel, v)
            local script = UIHelper.AddPrefab(nPrefabID, self.ScrollViewRightList)
            script:OnEnter(self.nIndex, tbConf, v, tbSettingData)
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewRightList)
    UIHelper.ScrollToTop(self.ScrollViewRightList)
end

function UIChatSettingView:Select(nIndex)
    --if self.nIndex == nIndex then return end

    self.nIndex = nIndex
    self:UpdateInfo_Group()
    self:_updateBtnChangeName()
end

function UIChatSettingView:UpdateArrow()
    local nPercent = UIHelper.GetScrollPercent(self.ScrollViewLeftList)
    local nHeight = UIHelper.GetHeight(self.ScrollViewLeftList)
    local bShow = nPercent <= 90
    local tbSize = self.ScrollViewLeftList:getInnerContainerSize()
    UIHelper.SetVisible(self.widgetArrowDown, bShow and tbSize.height > nHeight)
end

function UIChatSettingView:_getSettingData(szUIChannel, tbGroupConf)
    local szSettingType = tbGroupConf.szType
    return self.tbTempData[szUIChannel][szSettingType]
end

function UIChatSettingView:_setSettingData(szUIChannel, szSettingType, szChannelName, bSelected)
    if not self.tbTempData[szUIChannel] then return end
    if not self.tbTempData[szUIChannel][szSettingType] then return end

    self.tbTempData[szUIChannel][szSettingType][szChannelName] = bSelected
end

function UIChatSettingView:_updateBtnChangeName()
    local tbSettingConf = ChatSetting[self.nIndex]
    local bVisible = tbSettingConf and tbSettingConf.bCanRename

    UIHelper.SetVisible(self.BtnChangeName, bVisible)
end

function UIChatSettingView:_doChangeName(szNewName)
    local tbSettingConf = ChatSetting[self.nIndex]
    local szUIChannel = tbSettingConf and tbSettingConf.szUIChannel
    ChatData.SetUIChannelNickName(szUIChannel, szNewName)
end

return UIChatSettingView