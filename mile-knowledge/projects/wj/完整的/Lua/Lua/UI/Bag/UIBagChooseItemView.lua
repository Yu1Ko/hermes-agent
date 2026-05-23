-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIBagChooseItemView
-- Date: 2023-11-01 16:03:01
-- Desc: 背包选择道具界面
-- ---------------------------------------------------------------------------------

local UIBagChooseItemView = class("UIBagChooseItemView")

function UIBagChooseItemView:OnEnter(dwBoxIndex, dwPos)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwBoxIndex = dwBoxIndex
    self.dwPos = dwPos
    self:UpdateInfo()
end

function UIBagChooseItemView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIBagChooseItemView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose , EventType.OnClick , function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel , EventType.OnClick , function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnAccept , EventType.OnClick , function ()
        ItemData.OpenBox(true , self.dwBoxIndex, self.dwPos)
        UIMgr.Close(self)
    end)
end

function UIBagChooseItemView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIBagChooseItemView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIBagChooseItemView:UpdateInfo()
    local hPlayer = GetClientPlayer()
	local hBox = hPlayer.GetItem(self.dwBoxIndex, self.dwPos)
    local hBoxInfo = GetItemInfo(hBox.dwTabType, hBox.dwIndex)
    hPlayer.ClientOpenBox(self.dwBoxIndex, self.dwPos)
    local tItemObjList = hPlayer.GetBoxItem()
	local tBoxInfo = g_tTable.BoxInfo:Search(hBoxInfo.dwBoxTemplateID)
    local itemCount = table.get_len(tItemObjList)
    local bSmallList = itemCount <= 6
    local itemParent = bSmallList and self.LayoutItemListSmall or self.ScrollViewList
    for nIndex, tItem in ipairs(tItemObjList) do
        local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItemWithName , itemParent)


        local szItemName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItem(tItem))
        local szIconPath = UIHelper.GetIconPathByItemInfo(tItem)
        local color = cc.c3b(GetItemFontColorByQuality(tItem.nQuality, false))

        itemScript:SetLabelItemName(szItemName)
        itemScript:SetImgIcon(szIconPath)
        itemScript:SetTextColor(color)
        itemScript:SetItemQualityBg(tItem.nQuality)
        itemScript:SetLableCount(self:GetItemNum(tItem))
        itemScript:RegisterSelectEvent(function(bSelect)
            self:CloseTip()
            if bSelect then
                local tips, tipsScriptView = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, itemScript._rootNode)
                tipsScriptView:SetFunctionButtons({})
                tipsScriptView:SetBookID(tItem.nBookID)
                tipsScriptView:OnInitWithTabID(tItem.dwTabType, tItem.dwIndex)
                self.nCurItemView = itemScript
            end
        end)
    end

    UIHelper.LayoutDoLayout(self.LayoutItemListSmall)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewList)
    UIHelper.SetString(self.LabelTips , "")
    UIHelper.SetString(self.LabelTitle ,UIHelper.GBKToUTF8(tBoxInfo.szTitle))
end

function UIBagChooseItemView:GetItemNum(item)
    if not item then return end

    if item.nGenre == ITEM_GENRE.EQUIPMENT then
        if item.nSub == EQUIPMENT_SUB.ARROW and item.nCurrentDurability > 1 then
            return item.nCurrentDurability
        else
            return 1
        end
    else
        if item.bCanStack and item.nMaxStackNum > 1 then
            return item.nStackNum
        else
            return 1
        end
    end
end

function UIBagChooseItemView:CloseTip()
    if self.nCurItemView then
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
        self.nCurItemView:RawSetSelected(false)
        self.nCurItemView = nil
    end
end

return UIBagChooseItemView