-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelHotSpotBannerView
-- Date: 2023-06-15 16:01:29
-- Desc: ?
-- ---------------------------------------------------------------------------------
local MODULE_NUM = 5
local tID = {1, 2, 5, 4, 3}
local MODULE_CENTRE = 3

-- local tAniStep =
-- {
--     { nPriority = 1},
--     { nPriority = 2},
--     { nPriority = 5},
--     { nPriority = 4},
--     { nPriority = 3},
-- }
local UIPanelHotSpotBannerView = class("UIPanelHotSpotBannerView")

function UIPanelHotSpotBannerView:OnEnter(nEventID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nEventID = nEventID or HotSpotData.GetCareerData().fPopID
    self.tbEvent =  HotSpotData.GetEvent(self.nEventID)
    self.nCenterIndex = HotSpotData.GetCenterIndex()
    self:UpdateInfo()
end

function UIPanelHotSpotBannerView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    WaitingTipsData.RemoveWaitingTips("RefreshImage")
end

function UIPanelHotSpotBannerView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnRefresh, EventType.OnClick, function()
        self:OnClickRefresh()
    end)
end

function UIPanelHotSpotBannerView:RegEvent()
    Event.Reg(self, EventType.OnTouchViewBackGround, function(scriptView)
        if scriptView == self then
            UIMgr.Close(self)
        end
    end)
    Event.Reg(self, EventType.RefreshHotSpotData, function()
        self:RemoveMsg()
        UIHelper.SetButtonState(self.BtnRefresh, BTN_STATE.Normal)
        UIHelper.SetVisible(self.WidgetRefresh, false)
        self:UpdateInfo()
    end)
end

function UIPanelHotSpotBannerView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelHotSpotBannerView:UpdateInfo()
    self:UpdateInfo_RefreshBtn()

    local tbDataList = {}
    local tbTabIndex = {}
    for nIndex = 1, HotSpotData.nCount do
        local tbData = {}
        tbData.nID = tID[nIndex]
        local nTabIndex = nIndex
        if not table.contain_value(tbTabIndex, nTabIndex) then
            tbData.nTabID = self.tbEvent.tTab[nTabIndex]
            local tTab = HotSpotData.GetTab(tbData.nTabID)
            if tTab.bShow then
                tbData.tTab = tTab
                -- tbData.nPriority = tAniStep[tbData.nID].nPriority
                table.insert(tbDataList, tbData)
                table.insert(tbTabIndex, nTabIndex)
            end
        end
    end


    local scriptLoopPVComp = UIHelper.GetBindScript(self.WidgetAnchorMiddle)
    scriptLoopPVComp:OnEnter(PREFAB_ID.WidgetHotSpotBannerCell, tbDataList, self.nCenterIndex, true)
end

function UIPanelHotSpotBannerView:PushMsg()
    local tMsg = {
        szType = "RefreshImage",
        szWaitingMsg = "正在加载中，请稍后...",
        nPriority = 1,
        bHidePage = false,
        bSwallow = false,
    }
    WaitingTipsData.PushWaitingTips(tMsg)
    UIHelper.SetVisible(self.Img_Empty, false)
end

function UIPanelHotSpotBannerView:RemoveMsg()
    WaitingTipsData.RemoveWaitingTips("RefreshImage")
    UIHelper.SetVisible(self.Img_Empty, true)
end

function UIPanelHotSpotBannerView:OnClickRefresh()
    local function Refresh()
        self:PushMsg()
        HotSpotData.RefreshImage()
        UIHelper.SetButtonState(self.BtnRefresh, BTN_STATE.Disable)
        UIHelper.SetVisible(self.WidgetRefresh, true)
    end
    local nNetMode = App_GetNetMode()
    if nNetMode == NET_MODE.CELLULAR then
        UIHelper.ShowConfirm("当前处于移动网络，是否使用流量进行刷新热点图资源？", function()
            Refresh()
        end)
    else
        Refresh()
    end
end

function UIPanelHotSpotBannerView:UpdateInfo_RefreshBtn()
    UIHelper.SetVisible(self.BtnRefresh, HotSpotData.CanRefresh())
end

return UIPanelHotSpotBannerView