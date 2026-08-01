-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHorseEquipExteriorView
-- Date: 2024-03-11 17:13:57
-- Desc: ?
-- ---------------------------------------------------------------------------------

local tLogicIndexToUIIndex = {
    [HORSE_ENCHANT_DETAIL_TYPE.HEAD] = 3,
    [HORSE_ENCHANT_DETAIL_TYPE.CHEST] = 4,
    [HORSE_ENCHANT_DETAIL_TYPE.FOOT] = 5,
    [HORSE_ENCHANT_DETAIL_TYPE.HANT_ITEM] = 6,
}

local tUIIndexToLogicIndex = {
    [3] = HORSE_ENCHANT_DETAIL_TYPE.HEAD,
    [4] = HORSE_ENCHANT_DETAIL_TYPE.CHEST,
    [5] = HORSE_ENCHANT_DETAIL_TYPE.FOOT,
    [6] = HORSE_ENCHANT_DETAIL_TYPE.HANT_ITEM,
}


local UIHorseEquipExteriorView = class("UIHorseEquipExteriorView")

local nPageHorseEquipSetCount = 5
local nPageHorseEquipCount = 40

local tEquipExteriorTogIndex = {
    All = 1,
    Set = 2,
    HEAD = 3,
    CHEST = 4,
    FOOT = 5,
    HANT_ITEM = 6,
}

local function GetEquipExteriorList(nEquipExteriorTogIndex, nFilter, szSearch)
    local nDetail = tUIIndexToLogicIndex[nEquipExteriorTogIndex]
    if not nDetail then
        nDetail = -1
    end
    if nEquipExteriorTogIndex == tEquipExteriorTogIndex.Set then
        return RideExteriorData.GetHorseEquipExteriorSet(szSearch, nFilter)
    else
        return RideExteriorData.GetHorseEquipExteriorList(szSearch, nFilter, nDetail)
    end
end

function UIHorseEquipExteriorView:OnEnter(nDetail)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    local tbSelected = FilterDef.RideExterior.GetRunTime()
    self.nFilter = RideExteriorData.FILTER_TYPE.ALL
    if tbSelected then
        self.nFilter = tbSelected[1][1]
    end
    self.szSearch = ""

    UIMgr.Close(VIEW_ID.PanelLeftBag)
    self.nEquipExteriorTogIndex = tLogicIndexToUIIndex[nDetail]
    if not self.nEquipExteriorTogIndex then
        self.nEquipExteriorTogIndex = tEquipExteriorTogIndex.All
    end
    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)
    
    self:UpdateInfo()
end

function UIHorseEquipExteriorView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHorseEquipExteriorView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnScreen, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnScreen, TipsLayoutDir.BOTTOM_RIGHT, FilterDef.RideExterior)
    end)

    for index,Toggle in ipairs(self.tbTogBackBag) do
        UIHelper.BindUIEvent(Toggle,EventType.OnSelectChanged,function (_,bSelected)
            if bSelected then
                self.nEquipExteriorTogIndex = index
                self.nPageIndex = 1
                UIHelper.SetString(self.EditPaginate, self.nPageIndex)
                self:UpdateInfo()
            end
        end)
    end

    UIHelper.BindUIEvent(self.BtnLeft,EventType.OnClick,function ()
        if self.nPageIndex > 1 then
            self.nPageIndex = self.nPageIndex - 1
            UIHelper.SetString(self.EditPaginate, self.nPageIndex)
            self:UpdateInfo()
        end
    end)

    UIHelper.BindUIEvent(self.BtnRight,EventType.OnClick,function ()
        if self.nPageIndex < self.nPageCount then
            self.nPageIndex = self.nPageIndex + 1
            UIHelper.SetString(self.EditPaginate, self.nPageIndex)
            self:UpdateInfo()
        end
    end)

    UIHelper.RegisterEditBoxEnded(self.EditPaginate, function ()
        local nPageIndex = tonumber(UIHelper.GetString(self.EditPaginate))
        if nPageIndex then
            if nPageIndex ~= self.nPageIndex then
                if nPageIndex < 1 then
                    self.nPageIndex = 1
                elseif nPageIndex > self.nPageCount then
                    self.nPageIndex = self.nPageCount
                else
                    self.nPageIndex = nPageIndex
                end
                if self.nPageIndex ~= nPageIndex then
                    UIHelper.SetString(self.EditPaginate, self.nPageIndex)
                end
                self:UpdateInfo()
            end
        else
            UIHelper.SetString(self.EditPaginate, self.nPageIndex)
        end
    end)

    UIHelper.RegisterEditBox(self.EditKindSearch, function(szType, _editbox)
        if not self.bInit then
            return
        end

        if szType == "changed" then
            local szText = UIHelper.GetString(self.EditKindSearch)
            self.szSearch = szText
            self.nPageIndex = 1
            self:UpdateInfo()
        end
    end)
end

function UIHorseEquipExteriorView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if not szKey or szKey ~= "RideExterior" then
            return
        end
        local nFilter = tbSelected[1][1]
        self.nFilter = nFilter
        self.nPageIndex = 1
        self:UpdateInfo()

        local bFilter = false
        for _, v in pairs(tbSelected or {}) do
            if v[1] ~= 1 then
                bFilter = true
                break
            end
        end

        --筛选图标
        local szImgPath = bFilter and "UIAtlas2_Public_PublicButton_PublicButton1_icon_screen_ing" or "UIAtlas2_Public_PublicButton_PublicButton1_icon_screen"
        UIHelper.SetSpriteFrame(self.ImgIconScreen, szImgPath)
    end)
    
    Event.Reg(self, "ON_SET_HORSE_EQUIP_EXTERIOR", function()
        self:SetHorseEquipExteriorInPreview()
    end)
end

function UIHorseEquipExteriorView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHorseEquipExteriorView:UpdateInfo()
    self:UpdateHorseEquipExterior()
    self:UpdateTogSelect()
end

function UIHorseEquipExteriorView:InitHorseEquipExteriorInfo()
    --self:InitHorseEquipFilter()
    self:InitHorseEquipExteriorSetList()
end

function UIHorseEquipExteriorView:InitHorseEquipExteriorFilter()
    -- self.m_tSelectGainWay = {}
    -- local tGainWayList = Table_GetHorseEquipGainWay()
    -- for _, tLine in pairs(tGainWayList) do
    --     self.m_tSelectGainWay[tLine.nIndex] = true
    -- end
    -- self.nHorseEquipState = tHorseEquipState.All
end

function UIHorseEquipExteriorView:UpdateHorseEquipExterior()
    UIHelper.SetVisible(self.ScrollViewSuit, self.nEquipExteriorTogIndex == tEquipExteriorTogIndex.Set)
    UIHelper.SetVisible(self.ScrollViewGridList, self.nEquipExteriorTogIndex ~= tEquipExteriorTogIndex.Set)

    local tList = GetEquipExteriorList(self.nEquipExteriorTogIndex, self.nFilter, self.szSearch)

    self.nPageIndex = self.nPageIndex or 1
    self.tbHorseEquipExteriorBag = {}
    self.tbHorseEquipExteriorSet = {}

    if self.nEquipExteriorTogIndex == tEquipExteriorTogIndex.Set then
        self:UpdateHorseEquipExteriorSet(tList)
    else
        self:UpdateHorseEquipExteriorGrid(tList)
    end

    UIHelper.SetVisible(self.WidgetEmpty, #tList == 0)
    UIHelper.SetString(self.LabelPaginate, "/"..self.nPageCount)

    self:SetHorseEquipExteriorInPreview()
end

function UIHorseEquipExteriorView:UpdateHorseEquipExteriorSet(tList)
    UIHelper.RemoveAllChildren(self.ScrollViewSuit)

    if tList and not table_is_empty(tList) then
        self.nPageCount = math.ceil(#tList / nPageHorseEquipSetCount) or 0
        local nIndex1 = nPageHorseEquipSetCount * (self.nPageIndex - 1) + 1
        local nIndex2 = nIndex1 + nPageHorseEquipSetCount - 1
        for i = nIndex1, nIndex2 do
            local tSet = tList[i]
            if tList[i] then
                local HorseEquipExteriorScript = UIHelper.AddPrefab(PREFAB_ID.WidgetHorseEquipExteriorContent, self.ScrollViewSuit, tSet)
                self.tbHorseEquipExteriorSet[tSet.nSetID] = HorseEquipExteriorScript
            end
        end
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSuit)
    end
end

function UIHorseEquipExteriorView:UpdateHorseEquipExteriorGrid(tList)
    UIHelper.RemoveAllChildren(self.ScrollViewGridList)

    self.nPageCount = math.ceil(#tList / nPageHorseEquipCount) or 0
    local nIndex1 = nPageHorseEquipCount * (self.nPageIndex - 1) + 1
    local nIndex2 = nIndex1 + nPageHorseEquipCount - 1

    for i = nIndex1, nIndex2 do
        local tExteriorInfo = tList[i]
        if tExteriorInfo then
            local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.ScrollViewGridList)
            if itemScript then
                itemScript:OnInitWithRideExterior(tExteriorInfo.dwExteriorID,  true)
                itemScript:SetClickCallback(function(dwExteriorID, bEquip)
                    local tips, scriptTips = TipsHelper.ShowItemTips(itemScript._rootNode)
                    scriptTips:OnInitRideExterior(dwExteriorID, bEquip)
                    scriptTips:SetBtnState(RideExteriorData.GetExteriorTipsBtnState(dwExteriorID, bEquip))
                    if UIHelper.GetSelected(itemScript.ToggleSelect) then
                        UIHelper.SetSelected(itemScript.ToggleSelect, false)
                    end
                end)
                self.tbHorseEquipExteriorBag[tExteriorInfo.dwExteriorID] = itemScript
            end
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewGridList)
end

function UIHorseEquipExteriorView:SetHorseEquipExteriorInPreview()
    if self.nEquipExteriorTogIndex == tEquipExteriorTogIndex.Set then
        for nSetID, HorseEquipExteriorScript in pairs(self.tbHorseEquipExteriorSet) do
            HorseEquipExteriorScript:SetHorseEquipExteriorInPreview()
        end
    else
        for dwExteriorID, itemIcon in pairs(self.tbHorseEquipExteriorBag) do
            local bWear = RideExteriorData.IsInPreview(dwExteriorID, true)
            itemIcon:SetItemWear(bWear)
        end
    end
end

function UIHorseEquipExteriorView:UpdateTogSelect()
    for nIndex, Toggle in ipairs(self.tbTogBackBag) do
        UIHelper.SetSelected(Toggle, self.nEquipExteriorTogIndex == nIndex, false)
    end
end

return UIHorseEquipExteriorView