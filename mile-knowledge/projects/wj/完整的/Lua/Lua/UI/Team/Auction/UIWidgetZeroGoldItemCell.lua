-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetZeroGoldItemCell
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetZeroGoldItemCell = class("UIWidgetZeroGoldItemCell")

function UIWidgetZeroGoldItemCell:OnEnter(tLootInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tLootInfo = tLootInfo
    self:UpdateInfo(tLootInfo)
end

function UIWidgetZeroGoldItemCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIWidgetZeroGoldItemCell:BindUIEvent()

end

function UIWidgetZeroGoldItemCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetZeroGoldItemCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetZeroGoldItemCell:UpdateInfo(tLootInfo)
    local itemInfo = GetItemInfo(tLootInfo.dwItemTabType, tLootInfo.dwItemIndex)
	if not itemInfo then
		return
	end

    local szName = ItemData.GetItemNameByItemInfo(itemInfo, tLootInfo.nBookID)
    szName = UIHelper.GBKToUTF8(szName)

    local MAX_NAME_LENGTH = 12
    local nCharCount, szNewName = GetStringCharCountAndTopChars(szName, MAX_NAME_LENGTH)
    if nCharCount > MAX_NAME_LENGTH then szName = szNewName.."..." end

    local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(itemInfo.nQuality)
    szName = GetFormatText(szName, nil, nDiamondR, nDiamondG, nDiamondB)
    UIHelper.SetRichText(self.RichTextItemName, szName)
    UIHelper.SetVisible(self.Eff_OrangeNew, itemInfo.nQuality >= 5)
    
    local szImagePath = UIHelper.GetIconPathByItemInfo(itemInfo)
    UIHelper.SetTexture(self.ImgItemIcon, szImagePath)
    UIHelper.SetSpriteFrame(self.ImgPolishCountBG, ItemQualityBGColor[itemInfo.nQuality + 1])

    local nCount = 1
    local item = AuctionData.GetItem(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
    if item then
        nCount = ItemData.GetItemStackNum(item)
    end
    UIHelper.SetString(self.LabelCount, tostring(nCount))
    UIHelper.SetVisible(self.LabelCount, nCount > 1)

    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

return UIWidgetZeroGoldItemCell