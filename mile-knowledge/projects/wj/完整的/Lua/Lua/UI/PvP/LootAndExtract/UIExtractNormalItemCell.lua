-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIExtractNormalItemCell
-- Date: 2025-03-24 19:44:03
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIExtractNormalItemCell = class("UIExtractNormalItemCell")

function UIExtractNormalItemCell:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    local nIndex, dwItemType, dwItemIndex, nNum = tbInfo.nIndex, tbInfo.dwItemType, tbInfo.dwItemIndex, tbInfo.nNum
    local nBox = tbInfo.nBox
    local bLock, bSafe = tbInfo.bLock, tbInfo.bSafe
    local nPrice = tbInfo.nPrice
    if self.tbInfo and table.deepCompare(tbInfo, self.tbInfo) and table.deepCompare(self.tbInfo, tbInfo)  then
        -- 防止重复更新导致闪烁
        return
    end
    self.tbInfo = tbInfo
    self.nBox = nBox
    self.nIndex = nIndex
    self.dwItemType = dwItemType
    self.dwItemIndex = dwItemIndex
    self.nNum = nNum
    self.bLock = bLock
    self.bSafe = bSafe
    self.nPrice = nPrice
    self:UpdateInfo()
end

function UIExtractNormalItemCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIExtractNormalItemCell:BindUIEvent()
    UIHelper.SetSwallowTouches(self.BtnLock, false)
    UIHelper.BindUIEvent(self.BtnLock, EventType.OnClick, function ()
        TipsHelper.ShowNormalTip("未解锁当前格子")
    end)
end

function UIExtractNormalItemCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIExtractNormalItemCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIExtractNormalItemCell:UpdateInfo()
    UIHelper.RemoveAllChildren(self.WidgetItem_80)
    self.scriptItem = nil

    if self.dwItemType and self.dwItemIndex and self.dwItemType > 0 and self.dwItemIndex > 0 then
        local tbItemInfo = ItemData.GetItemInfo(self.dwItemType, self.dwItemIndex)
        if tbItemInfo then
            self.scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem_80)
            self.scriptItem:SetForbidShowCoolDown(self.bForbidShowCoolDown)
            self.scriptItem:OnInitWithTabID(self.dwItemType, self.dwItemIndex, self.nNum)
            if not tbItemInfo.bCanStack then
                self.scriptItem:SetLabelCountVisible(false)
            end
            self.scriptItem:SetToggleSwallowTouches(false)
        end
    end

    UIHelper.SetVisible(self.BtnLock, self.bLock)

    UIHelper.SetVisible(self.ImgBg2, self.bSafe)
    UIHelper.SetVisible(self.ImgProtect, self.bSafe)
    UIHelper.SetVisible(self.LayoutLock, not not self.scriptItem)
    UIHelper.SetVisible(self.ImgProtect2, self.bSafe)

    UIHelper.SetVisible(self.LabelPrice, not not self.nPrice)
    UIHelper.SetString(self.LabelPrice, self.nPrice)
    UIHelper.LayoutDoLayout(self.LayoutLock)
end

function UIExtractNormalItemCell:OnDragEnd(nTargetType, nTargetSlot, bInParent)
    if self.fnDragEndCallBack and IsFunction(self.fnDragEndCallBack) then
        self.fnDragEndCallBack(nTargetType, nTargetSlot, bInParent)
    end
end

function UIExtractNormalItemCell:OnDoubleClick()
    if self.fnDoubleClickCallBack and IsFunction(self.fnDoubleClickCallBack) then
        self.fnDoubleClickCallBack()
    end
end

function UIExtractNormalItemCell:GetItemScript()
    return self.scriptItem
end

function UIExtractNormalItemCell:GetItemInfo()
    return self.tbInfo
end

function UIExtractNormalItemCell:SetSwallowTouches(bSet)
    if not self.scriptItem then
        return
    end
    self.scriptItem:SetToggleSwallowTouches(bSet)
end

function UIExtractNormalItemCell:SetIsLock(bSet)
    UIHelper.SetVisible(self.BtnLock, bSet)
end

function UIExtractNormalItemCell:SetToggleGroupIndex(nIndex)
    if not self.scriptItem then
        return
    end
    self.scriptItem:SetToggleGroupIndex(nIndex)
end

function UIExtractNormalItemCell:SetSelectChangeCallback(fnCallBack)
    if not self.scriptItem then
        return
    end
    self.scriptItem:SetSelectChangeCallback(fnCallBack)
end

function UIExtractNormalItemCell:SetClearSeletedOnCloseAllHoverTips(bClearSeletedOnCloseAllHoverTips)
    if not self.scriptItem then
        return
    end
    self.scriptItem:SetClearSeletedOnCloseAllHoverTips(bClearSeletedOnCloseAllHoverTips)
end

function UIExtractNormalItemCell:SetForbidShowCoolDown(bForbid)
    self.bForbidShowCoolDown = bForbid
end

function UIExtractNormalItemCell:SetDragEndCallBack(fnCallBack)
    self.fnDragEndCallBack = fnCallBack
end

function UIExtractNormalItemCell:SetDoubleClickCallBack(fnCallBack)
    self.fnDoubleClickCallBack = fnCallBack
end
return UIExtractNormalItemCell