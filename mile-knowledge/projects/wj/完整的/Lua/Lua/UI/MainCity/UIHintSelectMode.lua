-- ---------------------------------------------------------------------------------
-- Author: liuyumin
-- Name: UIHintSelectMode
-- Date: 2024-02-01 19:18:21
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHintSelectMode = class("UIHintSelectMode")

function UIHintSelectMode:OnEnter()
    self.nIndex = Storage.ControlMode.nMode
    self.bFontShow = Storage.ControlMode.bFontShow
    self.nDevice = MainCityCustomData.GetDeviceType()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:GetFontSizeSet()
    self:UpdateInfo()
    Event.Dispatch(EventType.SetKeyBoardEnableByCustomState, true)
    InputHelper.LockMove(true)
    InputHelper.LockCamera(true)
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelMainCityInteractive)
    if scriptView then
        scriptView:HideView()
    end
    MainCityCustomData.SaveDraggableNodePosition()
end

function UIHintSelectMode:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Event.Dispatch("ON_END_LAYOUT_SETTING")
    Event.Dispatch(EventType.SetKeyBoardEnableByCustomState, false)
    InputHelper.LockMove(false)
    InputHelper.LockCamera(false)
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelMainCityInteractive)
    if scriptView then
        scriptView:ShowView()
    end

    local tbScript = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
	if tbScript then
        -- local tbHurtScript = UIHelper.GetBindScript(tbScript.WidgetHurtStatistics)
        -- tbHurtScript:OnEnter()
        if tbScript.bCustomState then
            self:ExitCustom()
            if MainCityCustomData.bSubsidiaryCustomState then   --退出辅助界面自定义编辑
                MainCityCustomData.EnterSubsidiaryCustom(false)
            else
                tbScript:ExitCurrentNodeCustom()
            end
        end
    end

    MainCityCustomData.UpdateMainCitySkillBoxNonVisible()
end

function UIHintSelectMode:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        if self.nIndex ~= Storage.ControlMode.nMode then
            Event.Dispatch("ON_CHANGE_MAINCITYPOSITION", Storage.ControlMode.nMode)
        end

        UIMgr.Close(self)

    end)

    UIHelper.BindUIEvent(self.TogMode1, EventType.OnClick, function()
        self.nIndex = MAIN_CITY_CONTROL_MODE.SIMPLE
        UIHelper.SetSelected(self.TogMode2, false)
        UIHelper.SetSelected(self.TogMode1, true)
        Event.Dispatch("ON_CHANGE_MAINCITYPOSITION", self.nIndex)
        self:GetFontSizeSet()
    end)

    UIHelper.BindUIEvent(self.TogMode2, EventType.OnClick, function()
        self.nIndex = MAIN_CITY_CONTROL_MODE.CLASSIC
        UIHelper.SetSelected(self.TogMode1, false)
        UIHelper.SetSelected(self.TogMode2, true)
        Event.Dispatch("ON_CHANGE_MAINCITYPOSITION", self.nIndex)
        self:GetFontSizeSet()
    end)

    UIHelper.BindUIEvent(self.BtnSclect, EventType.OnClick, function()
        Storage.ControlMode.nMode = self.nIndex
        Storage.ControlMode.Dirty()
        local tInfo = self.nIndex == MAIN_CITY_CONTROL_MODE.CLASSIC and GameSettingType.MainOperateMode.Classic or GameSettingType.MainOperateMode.Simplified
        GameSettingData.StoreNewValue(UISettingKey.MainViewLayout, tInfo)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnOtherSetting, EventType.OnClick, function()    --界面自定义
        self:EnterCustomMode()
    end)

    --BtnNewReSet
    UIHelper.BindUIEvent(self.BtnNewReSet, EventType.OnClick, function()    --恢复默认大小，当前模式下的真假节点恢复到本地保存的默认位置
        local szMessage = "是否将常规布局和辅助界面都重置为初始状态？"
        UIHelper.ShowConfirm(szMessage, function()
            local tbDefaultScaleInfo = TabHelper.GetUIFontSizeTab(DEVICE_NAME[self.nDevice], self.nIndex)
            self.tbFontSizeType = {
                nMap = tbDefaultScaleInfo.nMap,
                nSkill = tbDefaultScaleInfo.nSkill,
                nChat = tbDefaultScaleInfo.nChat,
                nTask = tbDefaultScaleInfo.nTask,
                nTeam = tbDefaultScaleInfo.nTeam,
                nBuff = tbDefaultScaleInfo.nBuff,
                nQuickuse = tbDefaultScaleInfo.nQuickuse,
                nPlayer = tbDefaultScaleInfo.nPlayer,
                nTarget = tbDefaultScaleInfo.nTarget,
                nLeftBottom = tbDefaultScaleInfo.nLeftBottom,
                nEnergyBar = tbDefaultScaleInfo.nEnergyBar,
                nSpecialSkillBuff = tbDefaultScaleInfo.nSpecialSkillBuff,
                nDxSkill = tbDefaultScaleInfo.nDxSkill,
                nKillFeed = tbDefaultScaleInfo.nKillFeed,
            }

            Event.Dispatch("ON_CHANGE_FONT_SIZE", self.tbFontSizeType)
            self.tbFontShow = {
                [CUSTOM_TYPE.CUSTOMBTN] = true,
                [CUSTOM_TYPE.MENU] = true,
                [CUSTOM_TYPE.SKILL] = true,
            }
            for k, bShow in pairs(self.tbFontShow) do
                Event.Dispatch("ON_CHANGE_MAINCITY_FONT_VISLBLE", self.tbFontShow, k)
            end

            Event.Dispatch("ON_SET_NODE_POSITION_DEFAULT", self.nIndex)

            local nDefaultOpacity = Storage.ControlMode.tbChatBgDefaultOpacity[self.nIndex] or 75
            Event.Dispatch(EventType.OnSetChatBgOpacity, nDefaultOpacity)

            Storage.MainCityNode.tbMaincityNodePos = {} --恢复拖动节点位置
            Storage.MainCityNode.Dirty()
            Event.Dispatch(EventType.OnSetDragInfoDefault)
            --恢复拖动节点大小
            MainCityCustomData.ResetAllDragNodeScale()
            --恢复dps透明度
            MainCityCustomData.ResetDragNodeBgOpacity(DRAGNODE_TYPE.DPS)
        end)
    end)

    UIHelper.BindUIEvent(self.BtnFreeSetting1, EventType.OnClick, function()    --一键大小
        self:ShowFontSizeSetTips()
    end)

    UIHelper.BindUIEvent(self.BtnFreeSetting2, EventType.OnClick, function()    --默认选中技能区域编辑
        Event.Dispatch("ON_ENTER_SINGLENODE_CUSTOM", CUSTOM_RANGE.RIGHT, CUSTOM_TYPE.SKILL, self.nIndex)
    end)

    UIHelper.BindUIEvent(self.BtnCustomClose, EventType.OnClick, function()
        local tbScript = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
        if tbScript:IsExistOverLapping() then   --有折叠，弹对应提示
            local szMessage = "模块存在重叠，更改未保存，仍要退出吗？"
            UIHelper.ShowConfirm(szMessage, function()
                self:ExitCustom()
            end)
        elseif tbScript.bPositionChanged or MainCityCustomData.GetChatBgOpacityChanged() or MainCityCustomData.IsDraggableNodePositionChanged()
                 or MainCityCustomData.IsDragNodeScaleChanged() or self:IsFontVisibleChanged() or self:IsNodeScaleChanged()
                 or MainCityCustomData.GetHurtBgOpacityChanged() or MainCityCustomData.GetChatContentSizeChanged() then   --有改动
            local szMessage = "当前布局发生修改，是否保存并退出？"
            local fnCancel = function ()
                self:ExitCustom()
            end
            local dialog = UIHelper.ShowConfirm(szMessage, function()
                self:SaveCustomInfo(true)
            end, fnCancel)
            dialog:SetButtonContent("Confirm", "保存")
            dialog:SetButtonContent("Cancel", "取消并退出")
            --直接返回
        else    --无折叠，无改动，直接返回
            Event.Dispatch("ON_ENTER_CUSTOMIZATION", self.nIndex, false, true)   --退出自定义,保存位置
            self:UpdateViewState(false)
        end
    end)

    UIHelper.BindUIEvent(self.BtnFreeCheck, EventType.OnClick, function()   --保存设置
        local tbScript = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
        if tbScript:IsExistOverLapping() then   --折叠
            TipsHelper.ShowImportantRedTip("模块存在折叠，无法保存，请调整模块位置")
        elseif tbScript.bPositionChanged or MainCityCustomData.GetChatBgOpacityChanged() or MainCityCustomData.IsDraggableNodePositionChanged()
                 or MainCityCustomData.IsDragNodeScaleChanged() or self:IsFontVisibleChanged() or self:IsNodeScaleChanged()
                 or MainCityCustomData.GetHurtBgOpacityChanged() or MainCityCustomData.GetChatContentSizeChanged() then
            local szMessage = "当前布局发生修改，是否保存并退出？"
            local fnCancel = function ()
                self:ExitCustom()
            end
            local dialog = UIHelper.ShowConfirm(szMessage, function()
                self:SaveCustomInfo(true)
            end, nil)
            dialog:SetButtonContent("Confirm", "保存")
            dialog:SetButtonContent("Cancel", "取消")
        else
            self:SaveCustomInfo(false)
        end
    end)

    --BtnInfoRule
    UIHelper.BindUIEvent(self.BtnInfoRule, EventType.OnClick, function()    --问号指引
        TeachBoxData.OpenTutorialPanel(62)
    end)


    UIHelper.BindUIEvent(self.BtnFreeSetting3, EventType.OnClick, function()    --辅助界面自定义
        MainCityCustomData.EnterSubsidiaryCustom(true)
    end)
end

function UIHintSelectMode:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "ON_CHANGE_FONT_SIZE", function (tbSizeType)
        self.tbFontSizeType = tbSizeType
    end)

    Event.Reg(self, "ON_CHANGE_MAINCITY_FONT_VISLBLE", function (tbFontShow, nType)
        self.tbFontShow = tbFontShow
    end)

    Event.Reg(self, EventType.OnSetChatBgOpacity, function (nOpacity)
        self.nOpacity = nOpacity
    end)
end

function UIHintSelectMode:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHintSelectMode:UpdateInfo()
    UIHelper.SetToggleGroupIndex(self.TogMode1, ToggleGroupIndex.HintSelectModeItem)
    UIHelper.SetToggleGroupIndex(self.TogMode2, ToggleGroupIndex.HintSelectModeItem)
    UIHelper.SetSelected(self.TogMode1, Storage.ControlMode.nMode == MAIN_CITY_CONTROL_MODE.SIMPLE)
    UIHelper.SetSelected(self.TogMode2, Storage.ControlMode.nMode == MAIN_CITY_CONTROL_MODE.CLASSIC)
    UIHelper.SetVisible(self.BtnNon, true)
end

function UIHintSelectMode:GetFontSizeSet()
    self.tbFontSizeType = clone(Storage.ControlMode.tbMainCityNodeScaleType[self.nIndex])
    --local tbSizeInfo = TabHelper.GetUIFontSizeTab(self.nDevice)
    --for k, nSize in pairs(self.tbFontSizeType) do
    --    if nSize == 0 then
    --        self.tbFontSizeType[k] = tbSizeInfo.nDefaultSize
    --        Storage.ControlMode.tbNodeSizeType[k] = tbSizeInfo.nDefaultSize
    --    end
    --end
    --Storage.ControlMode.Dirty()
    self.tbFontShow = clone(Storage.ControlMode.tbFontShow)

    self.nOpacity = clone(Storage.ControlMode.tbChatBgOpacity[self.nIndex]) or clone(Storage.ControlMode.tbChatBgDefaultOpacity[self.nIndex]) or 75
end

function UIHintSelectMode:ShowFontSizeSetTips()
    local tBtnInfoList = {}
    local tbSizeInfo = TabHelper.GetUIFontSizeTab(DEVICE_NAME[self.nDevice], self.nIndex)
    local tCellInfo = {
        [1] = {
            szName = "推荐",
            tbSize = tbSizeInfo
        },
        [2] = {
            szName = "大",
            nSize = tbSizeInfo.nBigSize
        },
        [3] = {
            szName = "中",
            nSize = tbSizeInfo.nMediumSize
        },
        [4] = {
            szName = "小",
            nSize = tbSizeInfo.nSmallSize
        },
        [5] = {
            szName = "极小",
            nSize = tbSizeInfo.nMiniSize
        },
    }

    local nIndex = self:GetSameSize(tCellInfo)  --获得当前所有模块大小


    for k, tbData in ipairs(tCellInfo) do
        local tbTipInfo = { szName = tbData.szName, func = function()
            if k == 1 then  --推荐大小
                local tbSizeInfo = tbData.tbSize
                for szType, v in pairs(self.tbFontSizeType) do
                    self.tbFontSizeType[szType] = tbSizeInfo[szType]
                end
            else
                for szType, v in pairs(self.tbFontSizeType) do
                    self.tbFontSizeType[szType] = tbData.nSize
                end
            end
            UIHelper.SetString(self.tbLabelList[nIndex], tbData.szName)
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetSettingsMultipleChoicePop)
            Event.Dispatch("ON_CHANGE_FONT_SIZE", self.tbFontSizeType, CUSTOM_BTNSTATE.ENTER)
        end, fnSelected = function()
            return k == nIndex
        end }
        table.insert(tBtnInfoList, tbTipInfo)
    end

    local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSettingsMultipleChoicePop, self.BtnFreeSetting1, TipsLayoutDir.LEFT_CENTER)
    script:UpdateSingleChoice(tBtnInfoList)
    tip:Update()
end

function UIHintSelectMode:GetSameSize(tCellInfo)
    local found = false
    local nResult = nil
    for key, tData in ipairs(tCellInfo) do
        local nResult = key
        if key == 1 then    --特判推荐大小
            local tbInfo = tData.tbSize
            for k, v in pairs(self.tbFontSizeType) do
                if v ~= tbInfo[k] then
                    nResult = nil
                    break
                end
            end
            if nResult then
                return nResult
            end
        else
            local nSize = tData.nSize
            for _, v in pairs(self.tbFontSizeType) do
                if nSize ~= v then
                    nResult = nil
                    break
                end
            end
            if nResult then
                return nResult
            end
        end
    end
    return nResult
end

function UIHintSelectMode:SaveCustomInfo(bSave)
    Event.Dispatch("ON_ENTER_CUSTOMIZATION", self.nIndex, false, true)   --退出经典模式的自定义
    self:UpdateViewState(false)
    --保存大小和显隐、聊天框透明度至本地
    if bSave then
        Storage.ControlMode.tbMainCityNodeScaleType[self.nIndex] = clone(self.tbFontSizeType)
        Storage.ControlMode.tbFontShow = clone(self.tbFontShow)
        Storage.ControlMode.tbChatBgOpacity[self.nIndex] = clone(self.nOpacity)
        Storage.ControlMode.Dirty()
        MainCityCustomData.SetChatBgOpacityChanged(false)

        MainCityCustomData.SaveDraggableNodePosition()
        MainCityCustomData.SaveDraggableNodeScale(true)
        MainCityCustomData.SaveHurtBgOpacity(true)
    end
end

function UIHintSelectMode:ExitCustom()
    Event.Dispatch(EventType.OnQuestTracingTargetChanged)
    Event.Dispatch("ON_RESET_STORAGE_POSITION") --恢复至本地保存位置
    --恢复本地保存大小
    self.tbFontSizeType = clone(Storage.ControlMode.tbMainCityNodeScaleType[self.nIndex])
    Event.Dispatch("ON_CHANGE_FONT_SIZE", self.tbFontSizeType)
    --恢复本地文字显隐
    self.tbFontShow = clone(Storage.ControlMode.tbFontShow)
    for k, bShow in pairs(self.tbFontShow) do
        Event.Dispatch("ON_CHANGE_MAINCITY_FONT_VISLBLE", self.tbFontShow, k)
    end

    --恢复本地聊天框背景透明度
    local nDefaultOpacity = Storage.ControlMode.tbChatBgOpacity[self.nIndex] or Storage.ControlMode.tbChatBgDefaultOpacity[self.nIndex] or 75
    Event.Dispatch(EventType.OnSetChatBgOpacity, nDefaultOpacity)

    --恢复拖动节点本地位置和大小、dps透明度
    Event.Dispatch(EventType.OnSetDragInfoDefault)
    MainCityCustomData.SaveDraggableNodeScale(false)
    MainCityCustomData.SaveHurtBgOpacity(false)

    Event.Dispatch("ON_ENTER_CUSTOMIZATION", self.nIndex, false, false)   --退出自定义,保存位置
    self:UpdateViewState(false)
end

function UIHintSelectMode:EnterCustomMode()
    if SystemOpen.IsSystemOpen(SystemOpenDef.MainCityCustom, true) then
        RedpointHelper.MainCityCustom_ClearAll()
        Event.Dispatch("OnUpdateCustomRedPoint")
        Event.Dispatch("ON_ENTER_CUSTOMIZATION", self.nIndex, true)   --进入自定义
        self:UpdateViewState(true)
    end
end

function UIHintSelectMode:IsFontVisibleChanged()
    for k, v in pairs(self.tbFontShow) do
        if v ~= Storage.ControlMode.tbFontShow[k] then
            return true
        end
    end
    return false
end

function UIHintSelectMode:IsNodeScaleChanged()
    for k, nSize in pairs(self.tbFontSizeType) do
        if self.tbFontSizeType[k] ~= Storage.ControlMode.tbMainCityNodeScaleType[self.nIndex][k] then
            return true
        end
    end
    return false
end

function UIHintSelectMode:UpdateViewState(bCustom)
    UIHelper.SetVisible(self.WidgetFreeSetting, bCustom)
    UIHelper.SetVisible(self.WidgetMode, not bCustom)
    UIHelper.SetVisible(self.BtnClose, not bCustom)
    UIHelper.SetVisible(self.BtnNon, not bCustom)
end

return UIHintSelectMode