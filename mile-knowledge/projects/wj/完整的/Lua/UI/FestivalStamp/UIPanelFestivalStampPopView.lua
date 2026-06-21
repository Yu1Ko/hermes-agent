-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelFestivalStampPopView
-- Date: 2025-05-14 17:14:53
-- Desc: ?
-- ---------------------------------------------------------------------------------
local PAGE_ITEM_COUNT = 4
local UIPanelFestivalStampPopView = class("UIPanelFestivalStampPopView")

function UIPanelFestivalStampPopView:OnEnter(tbCollectInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:Init(tbCollectInfo)
    self:UpdateInfo()
end

function UIPanelFestivalStampPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelFestivalStampPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnChangeOver01, EventType.OnClick, function()
        self.nCurrentPage = (self.nCurrentPage - 1) % self.nAllPage
        UIHelper.ScrollToPage(self.PageViewStamp, self.nCurrentPage)
    end)

    UIHelper.BindUIEvent(self.BtnChangeOver02, EventType.OnClick, function()
        self.nCurrentPage = (self.nCurrentPage + 1) % self.nAllPage
        UIHelper.ScrollToPage(self.PageViewStamp, self.nCurrentPage)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    for nIndex, tog in ipairs(self.tbTogItem) do
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(_toggle, bSelected)
            if bSelected then
                self.nCurrentPage = nIndex - 1
                UIHelper.ScrollToPage(self.PageViewStamp, self.nCurrentPage)
            end
        end)
    end
end

function UIPanelFestivalStampPopView:RegEvent()
    Event.Reg(self, EventType.OnSelectLeaveForBtn, function(tbInfo)
        ActivityData.Teleport_Go(tbInfo, self.nActivityID)
    end)

    Event.Reg(self, "DO_CUSTOM_OTACTION_PROGRESS", function()
        UIMgr.Close(self)
    end)
end

function UIPanelFestivalStampPopView:UnRegEvent()
    
end

function UIPanelFestivalStampPopView:GetCollectBgImage(nActivityID)
    local tInfo = Table_GetActivityCollectInfoByID(nActivityID)
    if not tInfo then
        return
    end
    return tInfo.szMoileBgPath
end

function UIPanelFestivalStampPopView:Init(tbCollectInfo)
    self:UpdateItemCollectState(tbCollectInfo)
    self.tbCollectInfo = tbCollectInfo
    self.nActivityID = tbCollectInfo.nActivityID
    self.nCurrentPage = 0

    local tbItemList = self.tbCollectInfo
    local nAllPage = math.modf(#tbItemList / PAGE_ITEM_COUNT)
    if math.fmod(#tbItemList, PAGE_ITEM_COUNT) > 0 then
        nAllPage = nAllPage + 1
    end
    self.nAllPage = nAllPage or 1

    self.tbItemList = {}
    local nIndex = 1
    for index = 1, #tbItemList do
        if not self.tbItemList[nIndex] then
            self.tbItemList[nIndex] = {}
        end
        table.insert(self.tbItemList[nIndex], tbItemList[index])
        if index % PAGE_ITEM_COUNT == 0 then
            nIndex = nIndex + 1
        end
    end


    self.szBgImg = self:GetCollectBgImage(self.nActivityID)

    Timer.AddFrameCycle(self, 10, function()
        self:CheckCurrentPage()
    end)
end

function UIPanelFestivalStampPopView:UpdateItemCollectState(tItemList)
    for _, tItem in ipairs(tItemList) do
        local bCollect = false
        if tItem.dwIndex and tItem.dwTabType then
            if ItemData.GetGeneralItemCollectState(tItem.dwTabType, tItem.dwIndex) then
                bCollect = true
            end
        end
        tItem.bCollect = bCollect
    end
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelFestivalStampPopView:UpdateInfo()
    for nIndex = 1, self.nAllPage do
        local script = UIHelper.PageViewAddPage(self.PageViewStamp, PREFAB_ID.WidgetFestivalStampPageCell, self.tbItemList[nIndex])
    end

    UIHelper.ScrollViewDoLayout(self.PageViewStamp)

    for nIndex, tog in ipairs(self.tbTogItem) do
        UIHelper.ToggleGroupAddToggle(self.TogGroupRewardItem, tog)
        UIHelper.SetVisible(tog, nIndex <= self.nAllPage)
    end

    UIHelper.ScrollToPage(self.PageViewStamp, self.nCurrentPage)
    UIHelper.SetSpriteFrame(self.ImgBg, self.szBgImg)
end


function UIPanelFestivalStampPopView:CheckCurrentPage()
    local nCurrentPage = UIHelper.GetPageIndex(self.PageViewStamp)
    local nTogIndex = UIHelper.GetToggleGroupSelectedIndex(self.TogGroupRewardItem)
    if nTogIndex ~= nCurrentPage then
        UIHelper.SetToggleGroupSelected(self.TogGroupRewardItem, nCurrentPage)
    end
    UIHelper.SetVisible(self.BtnChangeOver01, nCurrentPage > 0)
    UIHelper.SetVisible(self.BtnChangeOver02, nCurrentPage < self.nAllPage - 1)
end


return UIPanelFestivalStampPopView