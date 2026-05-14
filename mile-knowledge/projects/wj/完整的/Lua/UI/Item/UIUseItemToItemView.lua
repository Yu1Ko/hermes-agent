-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIUseItemToItemView
-- Date: 2023-02-09 09:33:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIUseItemToItemView = class("UIUseItemToItemView")

function UIUseItemToItemView:OnEnter(dwBox, dwX, funcConfirmAction, tbTargetItemList)
    self.dwBox = dwBox
    self.dwX = dwX
    self.tbSelected = { dwBox = nil, dwX = nil }
    self.funcConfirmAction = funcConfirmAction
    self.tbTargetItemList = tbTargetItemList

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIUseItemToItemView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIUseItemToItemView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        if self.funcCloseCallback then
            self.funcCloseCallback()
        else
            UIMgr.Close(self)
        end
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function ()
        if self.funcCloseCallback then
            self.funcCloseCallback()
        else
            UIMgr.Close(self)
        end
    end)

    UIHelper.BindUIEvent(self.BtnUse, EventType.OnClick, function ()
        if not self.tbSelected.dwBox or not self.tbSelected.dwX then
            TipsHelper.ShowNormalTip(g_tStrings.tbItemString.ON_ITEM_USE_FAILED)
            return
        end

        if self.funcConfirmAction then
            self.funcConfirmAction(self.tbSelected.dwBox, self.tbSelected.dwX)
        end

        if self.funcCloseCallback then
            self.funcCloseCallback()
        else
            UIMgr.Close(self)
        end
    end)
end

function UIUseItemToItemView:RegEvent()
    Event.Reg(self, EventType.OnGuideItemSource, function ()
        if UIMgr.GetView(VIEW_ID.PanelUseItemToItem) then
            UIMgr.Close(VIEW_ID.PanelUseItemToItem)
        end
    end)
end

function UIUseItemToItemView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIUseItemToItemView:SetCloseCallback(funcCloseCallback)
    self.funcCloseCallback = funcCloseCallback
end

function UIUseItemToItemView:UpdateInfo()
    local bEmpty = true
    UIHelper.RemoveAllChildren(self.ScrollViewItem)
    UIHelper.RemoveAllChildren(self.LayoutItemOneLine)

    local hSrcItem = ItemData.GetItemByPos(self.dwBox, self.dwX)
    if hSrcItem then
        UIHelper.SetString(self.LabelSrcItemName, UIHelper.GBKToUTF8(hSrcItem.szName))
        local ItemIconScript = UIHelper.GetBindScript(self.WidgetSrcItem)
        if ItemIconScript then
            ItemIconScript:OnInit(self.dwBox, self.dwX, false)
            ItemIconScript:SetEnable(false)
        end
    end

    local tbTargetItemList = self.tbTargetItemList or ItemData.GetUseItemTargetItemList(self.dwBox, self.dwX) or {}
    local Container = #tbTargetItemList < 6 and self.LayoutItemOneLine or self.ScrollViewItem

    for _, tbItemInfo in ipairs(tbTargetItemList) do
        local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, Container)
        if tbItemInfo.nBox and tbItemInfo.nIndex then
            itemScript:OnInit(tbItemInfo.nBox, tbItemInfo.nIndex)
        else
            itemScript:OnInitWithTabID(tbItemInfo.dwTabType, tbItemInfo.dwIndex, 0)
            UIHelper.SetNodeGray(itemScript._rootNode, true, true)
        end

        -- local itemScript = cellScript:GetItemScript()
        if itemScript then
            itemScript:SetToggleGroupIndex(ToggleGroupIndex.UseItemToItem)
            itemScript:SetClickCallback(function(nBox, nIndex) itemScript:ShowItemTips() end)
            if tbItemInfo.nBox and tbItemInfo.nIndex then
                itemScript:SetSelectChangeCallback(function(_dwItemID, bSelected) self:OnItemSelectChange(tbItemInfo.nBox, tbItemInfo.nIndex, bSelected) end)
                if #tbTargetItemList == 1 then
                    itemScript:SetSelected(true)
                end
            end
        end
        bEmpty = false
    end
    UIHelper.SetVisible(self.WidgetEmpty, bEmpty)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewItem)
    -- UIHelper.ScrollToLeft(self.ScrollViewItem, 0)
    -- UIHelper.ScrollViewDoLayout(self.ScrollViewItem)

    UIHelper.LayoutDoLayout(self.LayoutItemOneLine)
end

function UIUseItemToItemView:OnItemSelectChange(dwBox, dwX, bSelected)
    if bSelected then
        self.tbSelected = {dwBox = dwBox, dwX = dwX}
    else
        self.tbSelected = {}
    end
end

return UIUseItemToItemView