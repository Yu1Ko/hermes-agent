-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopReplaceOutfitView
-- Date: 2022-12-20 15:30:47
-- Desc: ?
-- ---------------------------------------------------------------------------------

local PAGE_EXTERIOR_COUNT = 10

local UICoinShopReplaceOutfitView = class("UICoinShopReplaceOutfitView")

function UICoinShopReplaceOutfitView:OnEnter(funcCloseCallback)
    self.funcCloseCallback = funcCloseCallback

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.m = {}
    self.tbCurOutfit = nil
    self:UpdateInfo()
end

function UICoinShopReplaceOutfitView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopReplaceOutfitView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        if self.funcCloseCallback then
            self.funcCloseCallback()
        end

        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function ()
        local nPage = self.m.nPage-1
        self:UpdateOutfitList(self.m.tbGoodsList, nPage)
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function ()
        local nPage = self.m.nPage+1
        self:UpdateOutfitList(self.m.tbGoodsList, nPage)
    end)

    UIHelper.BindUIEvent(self.BtnOk, EventType.OnClick, function ()
        if self.tbCurOutfit then
            self:RpelaceOutfit(self.tbCurOutfit.nLocalIndex)
        end
    end)
end

function UICoinShopReplaceOutfitView:RegEvent()
end

function UICoinShopReplaceOutfitView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopReplaceOutfitView:UpdateInfo()
    local tbGoodsList = CoinShopData.GetOutfitList()
    self.m.tbGoodsList = tbGoodsList

    self:UpdateOutfitList(self.m.tbGoodsList, 1)
end

function UICoinShopReplaceOutfitView:UpdatePaginate(nPage, nTotalPage)
    UIHelper.SetString(self.EditPaginate, nPage)
    UIHelper.SetString(self.LabelPaginate, "/" .. nTotalPage)
    UIHelper.SetVisible(self.WidgetPaginate, nTotalPage > 1)
    
    if nPage <= 1 then
        UIHelper.SetButtonState(self.BtnLeft, BTN_STATE.Disable)
    else
        UIHelper.SetButtonState(self.BtnLeft, BTN_STATE.Normal)
    end

    if nPage >= nTotalPage then
        UIHelper.SetButtonState(self.BtnRight, BTN_STATE.Disable)
    else
        UIHelper.SetButtonState(self.BtnRight, BTN_STATE.Normal)
    end
end

function UICoinShopReplaceOutfitView:UpdateOutfitList(tbList, nPage)
    local nCount = #tbList
    local nTotalPage = math.ceil(nCount / PAGE_EXTERIOR_COUNT)
    nPage = math.min(nPage, nTotalPage)
    nPage = math.max(nPage, 1)
    local nStart = (nPage - 1) * PAGE_EXTERIOR_COUNT + 1
    local nEnd = nPage * PAGE_EXTERIOR_COUNT
    nEnd = math.min(nEnd, nCount)

    self.tbCurOutfit = nil
    self.ScrollViewExteriorPropList:removeAllChildren()
    UIHelper.ToggleGroupRemoveAllToggle(self.WidgetAnchorReplaceList)
    local fnSelect = function (tbInfo)
        self:OnSelectOutfit(tbInfo)
    end
    for i = nStart, nEnd do
        local tbOutfit = tbList[i]
        local suitItem = UIHelper.AddPrefab(PREFAB_ID.WidgetSuitItem, self.ScrollViewExteriorPropList)
        suitItem:OnInitWithReplace(tbOutfit, fnSelect)
        UIHelper.ToggleGroupAddToggle(self.WidgetAnchorReplaceList, suitItem.TogPetList)
        -- 默认选中第一个
        if self.tbCurOutfit == nil then
            self:OnSelectOutfit(tbOutfit)
        end
    end
  
    UIHelper.SetVisible(self.ScrollViewExteriorPropList, nCount > 0)
    UIHelper.ScrollViewDoLayout(self.ScrollViewExteriorPropList)
    UIHelper.ScrollToTop(self.ScrollViewExteriorPropList, 0)

    self.m.nPage = nPage
    self:UpdatePaginate(nPage, nTotalPage)
end

function UICoinShopReplaceOutfitView:RpelaceOutfit(nIndex)
    local tbOutfit = ExteriorCharacter.GetCurrentOutfit()
    local bRepeat = CoinShop_OutfitCheckRepeat(tbOutfit)
    if bRepeat then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.COINSHOP_OUTFIT_REPLACE_ERROR)
        return
    end

    CoinShop_ReplaceOutfitList(tbOutfit, nIndex, true)
    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.COINSHOP_OUTFIT_REPLACE_SUCCESS)

    if self.funcCloseCallback then
        self.funcCloseCallback()
    end

    UIMgr.Close(self)
end

function UICoinShopReplaceOutfitView:OnSelectOutfit(tbOutfit)
    self.tbCurOutfit = tbOutfit
    LOG.ERROR("todo 模型选中%d", self.tbCurOutfit.nLocalIndex)
end

return UICoinShopReplaceOutfitView