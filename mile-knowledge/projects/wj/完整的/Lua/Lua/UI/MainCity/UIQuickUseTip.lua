-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIQuickUseTip
-- Date: 2023-02-10 16:35:43
-- Desc: ?
-- ---------------------------------------------------------------------------------

local QUICK_USE_TIP_STATE = {
    DYNAMICSTATE = 1,
    ITEMUSESTATE = 2,
    IDENTITYSTATE = 3
}

local QUICK_USE_SIZE = {
    FIRST = 9,
    SECOND = 12
}

local UIQuickUseTip = class("UIQuickUseTip")

function UIQuickUseTip:OnEnter()
    self.tbItemScriptList = {}
    self.tbSkillScriptList = {}
    self.tbIdentitySkillScriptList = {}
    self.bEditMode = false

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    UIHelper.SetTouchDownHideTips(self.BtnSetting, false)
    for k, node in pairs(self.tbItemCellBtnAdd) do
        UIHelper.SetTouchDownHideTips(node, false)
    end
    self:UpdateState()
    self:SetItemTipsState(false)
end

function UIQuickUseTip:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIQuickUseTip:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSetting, EventType.OnClick, function ()
        --if UIMgr.IsViewOpened(VIEW_ID.PanelQuickUsedBag) then
        --    UIMgr.Close(VIEW_ID.PanelQuickUsedBag)
        --    return
        --end
        --self:UpdateItemSelected()
        --UIMgr.Open(VIEW_ID.PanelQuickUsedBag)
        --self.bEditMode = true
        --self:OnEditModeChanged()
        local nX, nY = UIHelper.GetWorldPosition(self._rootNode)
        local nWidth, nHeight = UIHelper.GetContentSize(self._rootNode)
        local _, scriptTips = TipsHelper.ShowClickHoverTipsInDir(PREFAB_ID.WidgetTipMoreOper, TipsLayoutDir.TOP_RIGHT, nX + nWidth/4, nY)
        local bExpand = Storage.QuickUse.nMaxSlotCount == QUICK_USE_SIZE.FIRST
        local tbBtnInfo = {
            {
                szName = "道具编辑",
                OnClick = function ()
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
                    self:StopAutoCloseTimer()
                    if UIMgr.IsViewOpened(VIEW_ID.PanelQuickUsedBag) then
                        return
                    end
                    self:UpdateItemSelected()
                    local nPos = self:findEmptySlot(1, Storage.QuickUse.nMaxSlotCount, 1)
                    self:UpdateAddImgSelectVisible(nPos)
                    UIMgr.Open(VIEW_ID.PanelQuickUsedBag, nPos)
                    self.bEditMode = true
                    self:OnEditModeChanged()
                    TipsHelper.DeleteAllHoverTips(false)
                end
            },
            {
                szName = Storage.QuickUse.bTouchClose and "开启常驻显示" or "关闭常驻显示",
                OnClick = function ()
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
                    local szMessage = Storage.QuickUse.bTouchClose and "开启常驻显示后仅能使用关闭按钮关闭快捷使用界面，点击空白处不会关闭界面，是否确认开启？" or "关闭常驻显示后可以使用关闭按钮或者点击空白处关闭快捷使用界面，是否确认关闭？"
                    local fnCancel = function ()
                    end
                    local dialog = UIHelper.ShowConfirm(szMessage, function()
                        self:UpdateQuickUseCloseBtnState(Storage.QuickUse.bTouchClose)
                    end, fnCancel)
                    dialog:SetButtonContent("Confirm", "确认")
                    dialog:SetButtonContent("Cancel", "取消")
                end
            },
            {
                szName = bExpand and "开启12格" or "恢复9格",
                OnClick = function()
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
                    Storage.QuickUse.nMaxSlotCount = bExpand and QUICK_USE_SIZE.SECOND or QUICK_USE_SIZE.FIRST
                    Storage.QuickUse.Dirty()
                    UIHelper.SetVisible(self.WidgetList4, bExpand)
                    UIHelper.LayoutDoLayout(self.LayoutItemList)
                    for i = 10, 12, 1 do
                        Storage.QuickUse.tbItemTypeListInLKX[i] = nil
                        Storage.QuickUse.tbItemTypeList[i] = nil
                    end
                    self:UpdateItemInfo()
                    self:UpdateCurAddBtnState(bExpand)    --修改格子数量后，当前选中格子可能消失或者已有物品，需要视情况更新选中格子
                    local tbScript = UIMgr.GetViewScript(VIEW_ID.PanelQuickUsedBag)
                    if tbScript then
                        tbScript:UpdateInfo()
                    end
                end
            }
        }
        scriptTips:OnEnter(tbBtnInfo)
    end)

    for i, Button in ipairs(self.tbItemCellBtnAdd) do
        UIHelper.BindUIEvent(Button, EventType.OnClick, function ()
            self:StopAutoCloseTimer()
            self:UpdateItemSelected()
            self:UpdateAddImgSelectVisible(i)
            Event.Dispatch(EventType.OnQuickUseAddItemChanged, i)
            if UIMgr.IsViewOpened(VIEW_ID.PanelQuickUsedBag) then
                return
            end
            UIMgr.Open(VIEW_ID.PanelQuickUsedBag, i)
            self.bEditMode = true
            self:OnEditModeChanged()
            TipsHelper.DeleteAllHoverTips(false)
        end)
    end

    UIHelper.BindUIEvent(self.TogTab_1, EventType.OnSelectChanged, function (toggle, bSelect)
        self:StopAutoCloseTimer()
        if bSelect then
            self:SwitchState(QUICK_USE_TIP_STATE.ITEMUSESTATE)
        end
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        --UIHelper.SetVisible(self._rootNode, false)
        self:TrySetVisible(false)
    end)

    -- UIHelper.BindUIEvent(self.TogTab_2, EventType.OnSelectChanged, function (toggle, bSelect)
    --     self:StopAutoCloseTimer()
    --     if bSelect then
    --         self:SwitchState(QUICK_USE_TIP_STATE.DYNAMICSTATE)
    --     end
    -- end)

    -- UIHelper.BindUIEvent(self.TogTab_3, EventType.OnSelectChanged, function (toggle, bSelect)
    --     self:StopAutoCloseTimer()
    --     if bSelect then
    --         self:SwitchState(QUICK_USE_TIP_STATE.IDENTITYSTATE)
    --     end
    -- end)
end

function UIQuickUseTip:RegEvent()
    Event.Reg(self, EventType.OnQuickUseListChanged, function(bRemove, nIndex)
        self:UpdateItemInfo()
        local nPos = nil
        if not bRemove then
            nPos = self:findEmptySlot(nIndex, Storage.QuickUse.nMaxSlotCount, 1)
            if not nPos then
                nPos = self:findEmptySlot(1, nIndex, 1)
            end
        else
            nPos = nIndex
        end
        if nPos then
            self:UpdateItemSelected()
            self:UpdateAddImgSelectVisible(nPos)
            Event.Dispatch(EventType.OnQuickUseAddItemChanged, nPos)
        end
    end)

    Event.Reg(self, EventType.OnQuickUseListCfgEnd, function ()
        self.bEditMode = false
        self:OnEditModeChanged()
    end)

    Event.Reg(self, "BAG_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
        self:UpdateItemInfo()
    end)

    Event.Reg(self, EventType.OnSkillSlotQuickUseChange, function ()
        self:UpdateSkillRecallVisible()
    end)

    Event.Reg(self, "BUFF_UPDATE", function()
        local owner, bdelete, index, cancancel, id, stacknum, endframe, binit, level, srcid, isvalid, leftframe = arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11
        for i, v in ipairs(self.tbWaitUpdateBuffList) do
            if v.nbuff ~= 0 and v.nbuff == id then
                self.tbItemScriptList[self.tbWaitUpdateBuffList[i].nCellIndex]:SetRecallVisible(not bdelete)
                table.remove(self.tbWaitUpdateBuffList, i)
                break
            end
        end
    end)

    Event.Reg(self, EventType.UpdateActionToySkillState, function ()
        self:UpdateSkillRecallVisible()
    end)

end

function UIQuickUseTip:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIQuickUseTip:UpdateInfo()

    self:UpdateBaseInfo()
    -- if self.nState == QUICK_USE_TIP_STATE.DYNAMICSTATE then
    --     self:UpdateDynamicSkillInfo()
    -- elseif self.nState == QUICK_USE_TIP_STATE.IDENTITYSTATE then
    --     self:UpdateIdentitySkillInfo()
    -- else
        self:UpdateItemInfo()
    -- end
end

function UIQuickUseTip:UpdateBaseInfo()
    -- UIHelper.SetVisible(self.BtnSetting, self.nState == QUICK_USE_TIP_STATE.ITEMUSESTATE)
    -- UIHelper.SetSelected(self.TogTab_1, self.nState == QUICK_USE_TIP_STATE.ITEMUSESTATE, false)
    -- UIHelper.SetSelected(self.TogTab_2, self.nState == QUICK_USE_TIP_STATE.DYNAMICSTATE, false)
    -- UIHelper.SetSelected(self.TogTab_3, self.nState == QUICK_USE_TIP_STATE.IDENTITYSTATE, false)

    -- UIHelper.SetVisible(self.TogTab_2, (QTEMgr.CanCastSkill() and QTEMgr.IsInDynamicSkillState() and (not QTEMgr.IsHorseDynamic())) and true or false)
    -- UIHelper.SetVisible(self.TogTab_3, IdentitySkillData.IsInDynamicSkillState())
    -- UIHelper.LayoutDoLayout(self.WidgetTab)
end

function UIQuickUseTip:UpdateWidgetTab()
    -- local bVisible = (QTEMgr.CanCastSkill() and QTEMgr.IsInDynamicSkillState()) and true or false or IdentitySkillData.IsInDynamicSkillState()
    -- UIHelper.SetVisible(self.WidgetTab, bVisible)
end

function UIQuickUseTip:UpdateDynamicSkillInfo()

    for _nIndex, itemScript in ipairs(self.tbSkillScriptList) do
        UIHelper.SetVisible(itemScript._rootNode, false)
    end

    for index, imgBgAdd in ipairs(self.tbImageBgAdd) do
        UIHelper.SetVisible(imgBgAdd, false)
    end

    local nSKillCount = QTEMgr.GetDynamicSkillCount()
    if (QTEMgr.CanCastSkill() and QTEMgr.IsInDynamicSkillState()) then
        for nIndex = 1, nSKillCount do
            local tbSkill = QTEMgr.GetDynamicSkillData(nIndex)
            local widget = self.tbItemCellWidget[nIndex]
            self.tbSkillScriptList[nIndex] = self.tbSkillScriptList[nIndex] or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, widget)
            local itemScript = self.tbSkillScriptList[nIndex]
            itemScript:OnInitSkill(tbSkill.id, tbSkill.level)
            itemScript:SetClickCallback(function()
                tbSkill.callback()
                self:StopAutoCloseTimer()
            end)
            UIHelper.SetVisible(itemScript._rootNode, true)
            UIHelper.SetVisible(widget, true)
            itemScript:SetTouchDownHideTips(false)
        end
    end


    UIHelper.LayoutDoLayout(self.LayoutItemList)
end

function UIQuickUseTip:UpdateIdentitySkillInfo()

    for _nIndex, itemScript in ipairs(self.tbIdentitySkillScriptList) do
        UIHelper.SetVisible(itemScript._rootNode, false)
    end

    for index, imgBgAdd in ipairs(self.tbImageBgAdd) do
        UIHelper.SetVisible(imgBgAdd, false)
    end
    local nSKillCount = IdentitySkillData.GetDynamicSkillCount()
    for nIndex = 1, nSKillCount do
        local tbSkill = IdentitySkillData.GetDynamicSkillData(nIndex)
        local widget = self.tbItemCellWidget[nIndex]
        self.tbIdentitySkillScriptList[nIndex] = self.tbIdentitySkillScriptList[nIndex] or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, widget)
        local itemScript = self.tbIdentitySkillScriptList[nIndex]
        itemScript:OnInitSkill(tbSkill.id, tbSkill.level)
        itemScript:SetClickCallback(function()
            tbSkill.callback()
            self:StopAutoCloseTimer()
        end)
        UIHelper.SetVisible(itemScript._rootNode, true)
        UIHelper.SetVisible(widget, true)
        itemScript:SetTouchDownHideTips(false)
    end
end


function UIQuickUseTip:UpdateItemInfo()
    for _nIndex, itemScript in pairs(self.tbItemScriptList) do
        UIHelper.SetVisible(itemScript._rootNode, false)
    end

    for index, imgBgAdd in ipairs(self.tbImageBgAdd) do
        UIHelper.SetVisible(imgBgAdd, true)
    end

    local tbQuickUseSlotInfo = ItemData.GetQuickUseSlotInfo()
    local tbItemTypeList = TravellingBagData.IsInTravelingMap() and Storage.QuickUse.tbItemTypeListInLKX or Storage.QuickUse.tbItemTypeList
    --for nIndex, tbItemTab in ipairs(tbItemTypeList) do
    for nIndex = 1, Storage.QuickUse.nMaxSlotCount, 1 do
        local tbItemTab = tbItemTypeList[nIndex]
        if tbItemTab then
            local bToy = tbItemTab.bToy
            local nBox, _nIndex = not bToy and ItemData.GetItemPos(tbItemTab.dwTabType, tbItemTab.dwIndex)
            local nAmount = not bToy and ItemData.GetItemAmountInPackage(tbItemTab.dwTabType, tbItemTab.dwIndex) or nil
            local tbToyInfo = nil
            local widget = self.tbItemCellWidget[nIndex]
            self.tbItemScriptList[nIndex] = self.tbItemScriptList[nIndex] or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, widget)
            local itemScript = self.tbItemScriptList[nIndex]
            local bInSkillSlot = not bToy and tbQuickUseSlotInfo and tbQuickUseSlotInfo.dwTabType == tbItemTab.dwTabType and tbQuickUseSlotInfo.dwIndex == tbItemTab.dwIndex

            if bToy then
                tbToyInfo = Table_GetToyBox(tbItemTab.dwID)
                tbToyInfo.nCellIndex = nIndex
                tbToyInfo.bIsHave = true
                itemScript:OnInitWithIconID(tbToyInfo.nIcon, tbToyInfo.nQuality)
                itemScript:UpdateCDProgressBySkill(tbToyInfo.nSkillID, tbToyInfo.nSkillLevel)
            else
                itemScript:OnInitWithTabID(tbItemTab.dwTabType, tbItemTab.dwIndex)
            end

            local bInActionBar = bToy and ToyBoxData.IsToyInActionBar(tbToyInfo.dwID)

            if not bToy and tbItemTab.dwTabType == ITEM_TABLE_TYPE.OTHER then
                itemScript:SetLabelCount(nAmount)
            end
            itemScript:SetRecallCallback(function ()
                if bToy then
                    if self.bEditMode then
                        ItemData.RemoveQuickUseToyList(tbItemTab.dwID)
                    else
                        local function fnCallBack()
                            self:WaitUpdateBuff(tbToyInfo)
                        end
                        ToyBoxData.UseToySkill(tbToyInfo, fnCallBack)
                    end
                else
                    ItemData.RemoveQuickUseList(tbItemTab.dwTabType, tbItemTab.dwIndex)
                end

                self:StopAutoCloseTimer()
            end)
            itemScript:SetClickCallback(function ()
                self:StopAutoCloseTimer()
                self:UpdateAddImgSelectVisible(0)
                if self.bEditMode then return end

                local itemInfo = ItemData.GetItemInfo(tbItemTab.dwTabType, tbItemTab.dwIndex)
                if bToy then
                    local function fnCallBack()
                        self:WaitUpdateBuff(tbToyInfo)
                    end
                    ToyBoxData.UseToySkill(tbToyInfo, fnCallBack)
                elseif itemInfo and itemInfo.nGenre == ITEM_GENRE.ENCHANT_ITEM then
                    local nBox, nIndex = ItemData.GetItemPos(tbItemTab.dwTabType, tbItemTab.dwIndex)
                    local item = nBox and ItemData.GetItemByPos(nBox, nIndex) or nil
                    if item then
                        UIMgr.Open(VIEW_ID.PanelPowerUp, PREFAB_ID.WidgetEnchant, item)
                    end
                else
                    if ItemData.CanQuickUseOnSkillSlot(tbItemTab.dwTabType, tbItemTab.dwIndex, ItemData.QuickUseOperateType.QuickUseTip) then
                        ItemData.AddQuickUseSlotType(tbItemTab.dwTabType, tbItemTab.dwIndex, ItemData.QuickUseOperateType.QuickUseTip)
                    else
                        local nResult = ItemData.QuickUseItem(tbItemTab.dwTabType, tbItemTab.dwIndex)
                        if nResult == USE_ITEM_RESULT_CODE.SUCCESS then
                            Event.Dispatch(EventType.OnQuickUseSuccess)
                        end
                    end
                end
            end)
            itemScript:SetLongPressCallback(function ()
                if self.bEditMode then return end
                local itemInfo = ItemData.GetItemInfo(tbItemTab.dwTabType, tbItemTab.dwIndex)
                local tCursor = GetCursorPoint()
                local tips, tipsScriptView = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetItemTip, tCursor.x, tCursor.y)
                
                if bToy then
                    --玩具tips
                    tipsScriptView:OnInitOperationBoxItem(tbToyInfo, function(useboxInfo) end)
                    tipsScriptView:SetBtnState({})
                else
                    tipsScriptView:OnInitWithTabID(tbItemTab.dwTabType, tbItemTab.dwIndex)
                    tipsScriptView:SetFunctionButtons({})
                end
                self:SetItemTipsState(true)
            end)

            if self.bEditMode then
                itemScript:SetRecallVisible(true)
            else
                itemScript:SetRecallVisible(bToy and tbToyInfo.nbuff and GetClientPlayer().IsHaveBuff(tbToyInfo.nbuff, tbToyInfo.nbuffLevel))
            end
            itemScript:SetSkillRecallCallback(function ()
                self:StopAutoCloseTimer()
                if not bToy then
                    ItemData.RemoveQuickUseSlotType(tbItemTab.dwTabType, tbItemTab.dwIndex)
                else
                    ToyBoxData.RemoveActionToy(tbToyInfo.dwID)
                end
            end)
            itemScript:SetSkillRecallVisible(bInSkillSlot and not self.bEditMode or bInActionBar)
            itemScript:SetToggleGroupIndex(ToggleGroupIndex.QuickUseItemTip)
            UIHelper.SetVisible(itemScript._rootNode, true)
            if not bToy then
                if (nAmount == 0 and tbItemTab.dwTabType == ITEM_TABLE_TYPE.OTHER) or (nBox ~= INVENTORY_INDEX.EQUIP and tbItemTab.dwTabType ~= ITEM_TABLE_TYPE.OTHER) then
                    itemScript:SetColor(cc.c3b(55, 55, 55))
                else
                    itemScript:SetColor(cc.c3b(255, 255, 255))
                end
            end


            itemScript:SetTouchDownHideTips(false)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutItemList)
end

function UIQuickUseTip:UpdateSkillRecallVisible()
    local tbQuickUseSlotInfo = ItemData.GetQuickUseSlotInfo()
    local tbItemTypeList = TravellingBagData.IsInTravelingMap() and Storage.QuickUse.tbItemTypeListInLKX or Storage.QuickUse.tbItemTypeList
    for nIndex, itemScript in pairs(self.tbItemScriptList) do
        if UIHelper.GetVisible(itemScript._rootNode) then
            local tbItemTab = tbItemTypeList[nIndex]
            local bInActionBar = false
            if tbItemTab.bToy then
                bInActionBar = ToyBoxData.IsToyInActionBar(tbItemTab.dwID)
            end
            local bInSkillSlot = tbQuickUseSlotInfo and tbQuickUseSlotInfo.dwTabType == tbItemTab.dwTabType and tbQuickUseSlotInfo.dwIndex == tbItemTab.dwIndex
            itemScript:SetSkillRecallVisible((bInActionBar or bInSkillSlot) and not self.bEditMode)
        end
    end
end

function UIQuickUseTip:OnEditModeChanged()
    local tbItemTypeList = TravellingBagData.IsInTravelingMap() and Storage.QuickUse.tbItemTypeListInLKX or Storage.QuickUse.tbItemTypeList
    --for _nIndex, itemScript in pairs(self.tbItemScriptList) do
    for _nIndex = 1, Storage.QuickUse.nMaxSlotCount, 1 do
        local tbItemTab = tbItemTypeList[_nIndex]
        local itemScript = self.tbItemScriptList[_nIndex]
        if itemScript and tbItemTab then
            itemScript:SetRecallVisible(self.bEditMode)
            if tbItemTab.bToy and not self.bEditMode then
                local tbToyInfo = Table_GetToyBox(tbItemTab.dwID)
                itemScript:SetRecallVisible(tbItemTab.bToy and tbToyInfo.nbuff and GetClientPlayer().IsHaveBuff(tbToyInfo.nbuff, tbToyInfo.nbuffLevel))
            end
        end
    end

    self:UpdateSkillRecallVisible()

    if not self.bEditMode then
        self:UpdateItemSelected()
        self:UpdateAddImgSelectVisible(0)
    end
end

function UIQuickUseTip:TrySetVisible(bVisible)
    self:UpdateState()
    if not bVisible and self.bEditMode then
        UIMgr.Close(VIEW_ID.PanelQuickUsedBag)
        return false
    end

    UIHelper.SetVisible(self._rootNode, bVisible)
    return true
end

function UIQuickUseTip:OnDynamicStateExit()
    for _nIndex, itemScript in ipairs(self.tbSkillScriptList) do
        UIHelper.SetVisible(itemScript._rootNode, false)
    end
end

function UIQuickUseTip:OnItemStateExit()
    for _nIndex, itemScript in pairs(self.tbItemScriptList) do
        UIHelper.SetVisible(itemScript._rootNode, false)
    end
end

function UIQuickUseTip:OnIdentityStateExit()
    for _nIndex, itemScript in ipairs(self.tbIdentitySkillScriptList) do
        UIHelper.SetVisible(itemScript._rootNode, false)
    end
end

function UIQuickUseTip:OnStateExit(nState)
    if nState == QUICK_USE_TIP_STATE.DYNAMICSTATE then
        self:OnDynamicStateExit()
    elseif nState == QUICK_USE_TIP_STATE.IDENTITYSTATE then
        self:OnIdentityStateExit()
    else
        self:OnItemStateExit()
    end
end

function UIQuickUseTip:SwitchState(nState)
    --if self.nState and self.nState == nState then return end
    --self:OnStateExit(self.nState)
    if self.nState ~= nState then
        self:OnStateExit(self.nState)
    end
    self.nState = nState
    self:UpdateInfo()
end

function UIQuickUseTip:StartAutoCloseTimer()
    self:StopAutoCloseTimer()
    self.nAutoCloseTimer = Timer.Add(self, 5, function()
        self:TrySetVisible(false)
    end)
end

function UIQuickUseTip:StopAutoCloseTimer()
    if self.nAutoCloseTimer then
        Timer.DelTimer(self, self.nAutoCloseTimer)
        self.nAutoCloseTimer = nil
    end
end

function UIQuickUseTip:UpdateState()--有动态技能情况下点开默认是动态技能
    local bInDynamicSkill = QTEMgr.CanCastSkill() and QTEMgr.IsInDynamicSkillState() and (not QTEMgr.IsHorseDynamic())
    local bInIdentitySkill = IdentitySkillData.IsInDynamicSkillState() --有身份技能情况下点开默认是身份技能
    local nState = bInIdentitySkill and QUICK_USE_TIP_STATE.IDENTITYSTATE or bInDynamicSkill and QUICK_USE_TIP_STATE.DYNAMICSTATE or QUICK_USE_TIP_STATE.ITEMUSESTATE
    self:UpdateWidgetTab()
    self:SwitchState(nState)
    UIHelper.SetVisible(self.WidgetList4, Storage.QuickUse.nMaxSlotCount == 12)
end

function UIQuickUseTip:UpdateItemSelected()
    for k, tbScript in pairs(self.tbItemScriptList) do
        if tbScript:GetSelected() then
            tbScript:SetSelected(false)
        end
    end
end

function UIQuickUseTip:UpdateAddImgSelectVisible(nIndex)
    for k, img in ipairs(self.tbSelectImgList) do
        UIHelper.SetVisible(img, k == nIndex)
    end
end

function UIQuickUseTip:UpdateQuickUseCloseBtnState(bTouchClose)
    Storage.QuickUse.bTouchClose = not bTouchClose
    Storage.QuickUse.Dirty()
end

function UIQuickUseTip:UpdateCurAddBtnState(bExpand)
    if not self.bEditMode then
        return
    end
    local tbItemTypeList = TravellingBagData.IsInTravelingMap() and Storage.QuickUse.tbItemTypeListInLKX or Storage.QuickUse.tbItemTypeList
    local nPos = QUICK_USE_SIZE.FIRST
    for i = 1, bExpand and QUICK_USE_SIZE.SECOND or QUICK_USE_SIZE.FIRST, 1 do
        local tbItemInfo = tbItemTypeList[i]
        if not tbItemInfo then
            nPos = i
            break
        end
    end

    self:UpdateItemSelected()
    self:UpdateAddImgSelectVisible(nPos)
    Event.Dispatch(EventType.OnQuickUseAddItemChanged, nPos)
end

function UIQuickUseTip:WaitUpdateBuff(useboxInfo)
    self.tbWaitUpdateBuffList = self.tbWaitUpdateBuffList or {}
    local bIsAdd = true
    for k, v in pairs(self.tbWaitUpdateBuffList) do
        if v.nbuff == useboxInfo.nbuff then
            bIsAdd = false
            break
        end
    end
    if bIsAdd then
        table.insert(self.tbWaitUpdateBuffList, useboxInfo)
    end
end

function UIQuickUseTip:findEmptySlot(start, finish, step)
    for i = start, finish, step do
        local itemScript = self.tbItemScriptList[i]
        if not itemScript or not UIHelper.GetVisible(itemScript._rootNode) then
            return i
        end
    end
end

function UIQuickUseTip:SetItemTipsState(bHaveTips)
    self.bHaveTips = bHaveTips
end

function UIQuickUseTip:GetItemTipsState()
    return self.bHaveTips
end

return UIQuickUseTip
