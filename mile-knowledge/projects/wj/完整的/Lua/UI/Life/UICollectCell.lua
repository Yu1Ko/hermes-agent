-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICollectCell
-- Date: 2022-11-22 11:08:51
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICollectCell = class("UICollectCell")

function UICollectCell:OnEnter(tbCollectCell, func)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nItemID = tbCollectCell.nCraftItemID
    self.bProItem = tbCollectCell.bProItem
    self.tbCollectCell = tbCollectCell
    self:UpdateInfo()
end

function UICollectCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICollectCell:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        self.SelectFunc(self.tbCollectCell, bSelected)
    end)
end

function UICollectCell:RegEvent()
end

function UICollectCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UICollectCell:UpdateInfo()
    local nIconID = Table_GetItemIconID(self.nItemID, false)
    if nIconID > 0 then
        UIHelper.SetString(self.LabelItemName, UIHelper.GBKToUTF8(Table_GetItemName(self.nItemID)))
        UIHelper.SetItemIconByIconID(self.ImgIcon, nIconID)
    end
    UIHelper.SetVisible(self.ImgSpecializationCorner, self.bProItem)

    local itemInfo = ItemData.GetItemInfo(self.tbCollectCell.dwItemType, self.tbCollectCell.dwItemIndex)
    local nStackNum = ItemData.GetItemAllStackNum(itemInfo, false)
    UIHelper.SetVisible(self.LabelCount, nStackNum and nStackNum > 0)
    UIHelper.SetString(self.LabelCount, nStackNum)
    UIHelper.SetSpriteFrame(self.ImgPolishCountBG, ItemQualityBGColor[itemInfo.nQuality + 1])
end

function UICollectCell:AddTogSelected(func)
    self.SelectFunc = func
end

return UICollectCell