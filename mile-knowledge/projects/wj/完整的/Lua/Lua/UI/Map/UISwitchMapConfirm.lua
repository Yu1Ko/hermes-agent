local UISwitchMapConfirm = class("UISwitchMapConfirm")

function UISwitchMapConfirm:OnEnter(szContent, funcConfirm, funcCancel)
    self.szContent = szContent
    self.funcConfirm = funcConfirm
    self.funcCancel = funcCancel

    self:RegisterEvent()
    self:UpdateInfo()

    self:UpdateTime()
    self.nUpdateTimer = Timer.AddCycle(self, 0.5, function()
        self:UpdateTime()
    end)
end

function UISwitchMapConfirm:RegisterEvent()
    UIHelper.BindUIEvent(self.BtnCalloff, EventType.OnClick, function()
        if self.funcCancel then
            self.funcCancel()
        end

        UIMgr.Close(self._nViewID)
    end)

    UIHelper.BindUIEvent(self.BtnOk, EventType.OnClick, function()
        local bClose
        if self.funcConfirm then
            bClose = self.funcConfirm()
        end

        if bClose == nil or bClose == true then
            UIMgr.Close(self._nViewID)
        end
    end) 

    Event.Reg(self, EventType.OnGuideItemSource, function()
        UIMgr.Close(self)
    end)
end

function UISwitchMapConfirm:UpdateInfo()
    UIHelper.SetRichText(self.LabelHint, self.szContent)
    local nCount = MapMgr.GetResetItemCount()
    local szResetCount = nCount > 0 and g_tStrings.STR_RESET_ITEM_COUNT or g_tStrings.STR_RESET_ITEM_INVALID_COUNT
    UIHelper.SetRichText(self.LabelQuantity, FormatString(szResetCount, nCount))

    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, self.WidgetProp) ---@type UIItemIcon
    script:SetClickNotSelected(true)
    script:OnInitWithTabID(5, 40385)
    script:SetClickCallback(function()
        local tip, tipScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, script._rootNode
        , TipsLayoutDir.TOP_CENTER)
        tipScript:SetFunctionButtons({})
        tipScript:OnInitWithTabID(5, 40385)
    end)

    UIHelper.SetButtonState(self.BtnOk, nCount > 0 and BTN_STATE.Normal or BTN_STATE.Disable)
end

function UISwitchMapConfirm:UpdateTime()
    local _, szLeft, nLeft = MapMgr.GetTransferSkillCD()
    if nLeft <= 0 then
        UIHelper.SetRichText(self.LabelHint, "神行冷却时间已结束，是否直接执行神行操作？")
        UIHelper.SetVisible(self.LabelTime, false)
        UIHelper.SetVisible(UIHelper.GetParent(self.LabelQuantity), false)
        Timer.DelTimer(self, self.nUpdateTimer)
        return
    end
    UIHelper.SetRichText(self.LabelTime, FormatString(g_tStrings.STR_COOL_DOWN, szLeft))
end

function UISwitchMapConfirm:UpdateMentor()
    UIHelper.SetRichText(self.LabelHint, self.szContent)
    local nCount = MapMgr.GetResetItemCount()
    local szResetCount = nCount > 0 and g_tStrings.STR_RESET_ITEM_COUNT or g_tStrings.STR_RESET_ITEM_INVALID_COUNT
    UIHelper.SetRichText(self.LabelQuantity, FormatString(szResetCount, nCount))

    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, self.WidgetProp)
    MapMgr.UpdateResetItemIcon(script)

    UIHelper.SetVisible(self.LabelTime, false)
    Timer.DelAllTimer(self)
end

function UISwitchMapConfirm:Exit()

end

return UISwitchMapConfirm