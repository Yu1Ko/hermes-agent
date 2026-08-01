local UIWidgetMonsterBookSkillBagCell = class("UIWidgetMonsterBookSkillBagCell")

function UIWidgetMonsterBookSkillBagCell:OnEnter(item, fCallBack, fIconCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.item = item
    self.fCallBack = fCallBack
    self.fIconCallBack = fIconCallBack
    self:UpdateInfo()
end

function UIWidgetMonsterBookSkillBagCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonsterBookSkillBagCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCell, EventType.OnClick, function ()
        self.fCallBack(self.item)
    end)
end

function UIWidgetMonsterBookSkillBagCell:RegEvent()

end

function UIWidgetMonsterBookSkillBagCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMonsterBookSkillBagCell:UpdateInfo()
    UIHelper.RemoveAllChildren(self.WidgetItem60Shell)
    local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.WidgetItem60Shell)
    scriptItem:OnInitWithTabID(self.item.dwTabType, self.item.dwIndex)
    scriptItem:SetClickCallback(function(nItemType, nItemIndex)
        self.fIconCallBack(self.item)
    end)
    UIHelper.SetToggleGroupIndex(scriptItem.ToggleSelect, ToggleGroupIndex.MonsterBookSkillBook)
    local szItemName = ItemData.GetItemNameByItem(self.item)
    szItemName = UIHelper.GBKToUTF8(szItemName)
    local MAX_WORD_COUNT = 13
    local nCharCount, szTopChars = GetStringCharCountAndTopChars(szItemName, MAX_WORD_COUNT)
    szItemName = szTopChars
    if nCharCount > MAX_WORD_COUNT then szItemName = szItemName .. "..." end

    local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(self.item.nQuality)
    local szRichText = string.format("<color=#%X%X%X>%s</c>", nDiamondR, nDiamondG, nDiamondB, szItemName)
    UIHelper.SetRichText(self.RichTextName, szRichText)
end

return UIWidgetMonsterBookSkillBagCell