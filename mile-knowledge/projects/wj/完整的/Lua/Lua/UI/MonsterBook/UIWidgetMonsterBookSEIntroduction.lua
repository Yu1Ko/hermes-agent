local UIWidgetMonsterBookSEIntroduction = class("UIWidgetMonsterBookSEIntroduction")

function UIWidgetMonsterBookSEIntroduction:OnEnter(tCollectData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bSortAsc = false
    self.tCollectData = tCollectData
    self:UpdateInfo(tCollectData)
    self:UpdateCurrency()
end

function UIWidgetMonsterBookSEIntroduction:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonsterBookSEIntroduction:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnArrangeLevel, EventType.OnClick, function ()
        self.bSortAsc = not self.bSortAsc
        self:UpdateInfo(self.tCollectData)
    end)
end

function UIWidgetMonsterBookSEIntroduction:RegEvent()
    Event.Reg(self, "BAG_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
		self:UpdateCurrency()
    end)
end

function UIWidgetMonsterBookSEIntroduction:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMonsterBookSEIntroduction:UpdateInfo(tCollectData)
    if not tCollectData then
        return
    end
    local nSpiritMaxValue, nEnduranceMaxValue =  tCollectData.nSpiritMaxValue, tCollectData.nEnduranceMaxValue
    
    local szSpirit = string.format("精神值：%d",  nSpiritMaxValue)
    local szEndurance = string.format("耐力值：%d", nEnduranceMaxValue)

    UIHelper.SetString(self.LabelJingshen, szSpirit)
    UIHelper.SetString(self.LabelNaili, szEndurance)

    UIHelper.RemoveAllChildren(self.LayoutCenter)
    local tSEInfoList = tCollectData.tSEInfoList

    local tSort = {}
    for k, v in ipairs(tSEInfoList) do
        if not v.nMinLevel then
            v.nMinLevel = 0
        end
        table.insert(tSort, v)
    end

    UIHelper.SetOpacity(self.ImgUpLevel, self.bSortAsc == true and 255 or 70)
    UIHelper.SetOpacity(self.ImgDownLevel, self.bSortAsc == false and 255 or 70)
    if self.bSortAsc then
        table.sort(tSort, function(a, b)
            if a.nMinLevel ~= b.nMinLevel then
                return a.nMinLevel < b.nMinLevel
            elseif a.nCurProgress ~= b.nCurProgress then
                return a.nCurProgress > b.nCurProgress
            else
                return a.dwBossID < b.dwBossID
            end
        end)
    else
        table.sort(tSort, function(a, b)
            if a.nMinLevel ~= b.nMinLevel then
                return a.nMinLevel > b.nMinLevel
            elseif a.nCurProgress ~= b.nCurProgress then
                return a.nCurProgress > b.nCurProgress
            else
                return a.dwBossID < b.dwBossID
            end
        end)
    end

    for _, tSEInfo in ipairs(tSort) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetJingShenNaiLiDetailCell, self.ScrollViewCenter, tSEInfo, function (script, bSelected)
            UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewCenter, true, true)
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCenter)
            UIHelper.ScrollLocateToPreviewItem(self.ScrollViewCenter, script._rootNode, Locate.TO_CENTER)
        end)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCenter)
end

function UIWidgetMonsterBookSEIntroduction:UpdateCurrency()    
    local tAllBookInfo = Table_GetAllMonsterCommonBookInfo()
    local tItemIndexMap = {}
    UIHelper.RemoveAllChildren(self.LayoutCurrency)
    for _, tBookInfo in ipairs(tAllBookInfo) do
        if not tItemIndexMap[tBookInfo.dwItemIndex] then
            tItemIndexMap[tBookInfo.dwItemIndex] = true
            UIHelper.AddPrefab(PREFAB_ID.WidgetSingleCurrency, self.LayoutCurrency, tBookInfo.dwTabType, tBookInfo.dwItemIndex, true)
        end
    end
end

return UIWidgetMonsterBookSEIntroduction