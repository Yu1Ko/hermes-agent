-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandOverviewMain
-- Date: 2024-01-29 14:52:24
-- Desc: ?
-- ---------------------------------------------------------------------------------
local MAX_BIG_ACTIVITY_NUM = 2
local UIHomelandOverviewMain = class("UIHomelandOverviewMain")


local OverviewInfoIndex = {1,2,7,4,5,3,6,8,10,9}
function UIHomelandOverviewMain:OnEnter(tLinkIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tLinkIndex = tLinkIndex
    self:Init()
    UIMgr.HideLayer(UILayer.Main)
    CameraMgr.EnterUIMode(true)
    rlcmd("enable camera focus diverge 1 -0.30 0 3")

    local nScale = CameraMgr.nLastScale
    CameraMgr.SetZoomLimit(nScale, nScale)
    if (GetClientPlayer() and GetClientPlayer().GetQuestIndex(21783)) and true then
        RemoteCallToServer("On_OPEN_PANEL", "JYZONGLAN")
	end

    Timer.Add(self, 0.2, function()
        UIHelper.SetVisible(self.WidgetOverview, true)
    end)
end

function UIHomelandOverviewMain:OnExit()
    self.bInit = false
    self:UnRegEvent()
    UIMgr.ShowLayer(UILayer.Main)
    CameraMgr.ExitUIMode(1)
    rlcmd("enable camera focus diverge 0")
end

function UIHomelandOverviewMain:BindUIEvent()
    UIHelper.SetSwallowTouches(self.BtnCloseAwardList, false)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCloseAwardList, EventType.OnClick, function(btn)
        Event.Dispatch(EventType.OnClearOverviewRewardListSelected)
    end)

    UIHelper.BindUIEvent(self.BtnBlueprint, EventType.OnClick, function(btn)
        Homeland_VisitWanBaoLouBlpsWeb()
    end)
    UIHelper.SetVisible(self.BtnBlueprint, Platform.IsWindows() or Platform.IsAndroid())

    UIHelper.BindUIEvent(self.BtnHome, EventType.OnClick, function(btn)
        UIMgr.Close(self)
        UIMgr.Open(VIEW_ID.PanelHome)
    end)

    UIHelper.BindUIEvent(self.BtnAuthority, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelHomeAuthoritySettingPop)
    end)

    UIHelper.BindUIEvent(self.BtnFlowerPrice, EventType.OnClick, function(btn)
        local player = GetClientPlayer()
        if not player or IsRemotePlayer(player.dwID) then
            return
        end
        UIMgr.Open(VIEW_ID.PanelFlowerPrice)
    end)

    UIHelper.BindUIEvent(self.BtnMerchant, EventType.OnClick, function(btn)
        local player = GetClientPlayer()
        if not player or IsRemotePlayer(player.dwID) then
            return
        end
        UIMgr.Open(VIEW_ID.PanelMerchant)
    end)

    UIHelper.BindUIEvent(self.BtnMainCity, EventType.OnClick, function(btn)
        RemoteCallToServer("On_HomeLand_Back2City")
    end)

    UIHelper.BindUIEvent(self.BtnMessage, EventType.OnClick, function(btn)
        local dwMapID, nCopyIndex, nLandIndex = HomelandBuildData.GetMapInfo()
		local bMyLand = HomelandBuildData.CheckIsMyLand(dwMapID, nCopyIndex, nLandIndex)
        if not bMyLand then
            return
        end
        UIMgr.HideView(VIEW_ID.PanelHomeOverview)
        UIMgr.Close(self)
        UIMgr.Open(VIEW_ID.PanelMessageBoard, dwMapID, nCopyIndex, nLandIndex)
    end)

    UIHelper.BindUIEvent(self.BtnWarehouse, EventType.OnClick, function(btn)
        UIMgr.Close(self)
        UIMgr.Open(VIEW_ID.PanelHalfBag)
        UIMgr.Open(VIEW_ID.PanelHalfWarehouse,WareHouseType.Homeland)
    end)

    UIHelper.BindUIEvent(self.BtnShop, EventType.OnClick, function(btn)
        ShopData.OpenSystemShopGroup(1, 1240)
    end)
end

function UIHomelandOverviewMain:RegEvent()
    Event.Reg(self, "REMOTE_HL_OVERVIEW_EVENT", function ()
        self:Init()
    end)

    Event.Reg(self, "HOME_LAND_RESULT_CODE", function ()
        local nResultType = arg0
        if nResultType == HOMELAND_RESULT_CODE.APPLY_ESTATE_SUCCEED then
            self:Init()
        end
    end)

    Event.Reg(self, EventType.OnClickOverviewActivityCell, function(tMenuInfo)
        self:UpdateTargetListInfo(tMenuInfo)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:CloseTargetList()
    end)

    Event.Reg(self, EventType.OnEnterOverviewRewardList, function()
        self.scriptLeftOverview:Close()
        self.scriptLeftRewardList:Show()
    end)

    Event.Reg(self, EventType.OnExitOverviewRewardList, function()
        self.scriptLeftOverview:Show()
        self.scriptLeftRewardList:Close()
    end)

    Event.Reg(self, EventType.OnTryTransferToFurniture, function()
        rlcmd("enable camera focus diverge 0")
        UIMgr.HideView(VIEW_ID.PanelHomeOverview)
        UIMgr.Close(self)
    end)

    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID == VIEW_ID.PanelFlowerPrice
            or nViewID == VIEW_ID.PanelMerchant then
            UIHelper.PlayAni(self, self.WidgetAniRight, "AniRightHide")
        end
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelFlowerPrice
            or nViewID == VIEW_ID.PanelMerchant then
            UIHelper.PlayAni(self, self.WidgetAniRight, "AniRightShow")
        end
    end)
end

function UIHomelandOverviewMain:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandOverviewMain:Init()
    local pHomelandMgr  = GetHomelandMgr()
    local tTemp         = pHomelandMgr.GetAllMyLand()
    local nCommunityCount = 0
    for i = 1, #tTemp do
        if not tTemp[i].bPrivateLand then
            nCommunityCount = nCommunityCount + 1
        end
    end

    local tData                 = GDAPI_GetHomelandOverviewInfo(nCommunityCount > 0)
    local tRewardInfo           = Table_GetHomelandOverviewRewardInfo()
    local tOverviewInfo         = Table_GetHomelandOverviewInfo()
    self.scriptLeftOverview     = UIHelper.GetBindScript(self.WidgetOverview)
    self.scriptLeftRewardList   = UIHelper.GetBindScript(self.WidgetRewardList)
    self.scriptTargetList       = UIHelper.AddPrefab(PREFAB_ID.WidgetInteractionTargetList, self.WidgetTargetListShell)

    self.scriptTargetList:OnEnter()
    self.scriptLeftOverview:OnEnter(tRewardInfo, tData)
    self.scriptLeftRewardList:OnEnter(tRewardInfo, tData)
    self:UpdateRightActivityCardInfo(tOverviewInfo, tData, nCommunityCount)
    self:UpdateLevelInfo()
end

function UIHomelandOverviewMain:UpdateRightActivityCardInfo(tOverviewInfo, tData, nCommunityCount)
    UIHelper.RemoveAllChildren(self.WidgetAnchorActivitiyListBig)
    UIHelper.RemoveAllChildren(self.WidgetAnchorActivitiyListSmall)
    for _, index in ipairs(OverviewInfoIndex) do
        local tbInfo = tOverviewInfo[index]
        local script = nil
        if index <= MAX_BIG_ACTIVITY_NUM then
            script = UIHelper.AddPrefab(PREFAB_ID.WidgetActivityCellBig, self.WidgetAnchorActivitiyListBig)
        else
            script = UIHelper.AddPrefab(PREFAB_ID.WidgetActivityCellSmall, self.WidgetAnchorActivitiyListSmall)
        end
        script:OnEnter(tbInfo, tData[index], nCommunityCount)

        if self.tLinkIndex and self.tLinkIndex[1] == tostring(index) then
            Timer.Add(self, 1, function()
                script:OnClick()
                self.tLinkIndex = nil
            end)
        end
    end

    UIHelper.CascadeDoLayoutDoWidget(self.WidgetAnchorActivitiyList, true, true)
end

function UIHomelandOverviewMain:UpdateLevelInfo()
    UIHelper.SetVisible(self.LayoutLevel, false)

    local pHlMgr = GetHomelandMgr()
    if pHlMgr then
        local dwMapID, nCopyIndex, nLandIndex = HomelandData.GetNowLandInfo()
        local tLandInfo = pHlMgr.GetLandInfo(dwMapID, nCopyIndex, nLandIndex)
        local dwGlobalID = UI_GetClientPlayerGlobalID()
        if tLandInfo and tLandInfo.szOwnerID and dwGlobalID == tLandInfo.szOwnerID then
            UIHelper.SetVisible(self.LayoutLevel, true)
            UIHelper.SetString(self.LabelLevelNum, tLandInfo.nLevel.."级")
            UIHelper.LayoutDoLayout(self.LayoutLevel)
        end
    end
end

function UIHomelandOverviewMain:UpdateTargetListInfo(tMenuInfo)
    local pHlMgr = GetHomelandMgr()
    if table.is_empty(tMenuInfo) or not pHlMgr then
        self:CloseTargetList()
    end
    local bEmpty = true
    local dwID = tMenuInfo.dwID
    local dwMapID, nCopyIndex, nLandIndex = HomelandData.GetNowLandInfo()
    local tLandInfo = pHlMgr.GetLandInfo(dwMapID, nCopyIndex, nLandIndex)
    local tData = GDAPI_GetHomelandOverviewMenuInfo(dwID)

    self.scriptTargetList:ShowList(tMenuInfo, tLandInfo, tData)
    UIHelper.SetVisible(self.WidgetTargetListShell, true)
end

function UIHomelandOverviewMain:CloseTargetList()
    UIHelper.SetVisible(self.WidgetTargetListShell, false)
end

return UIHomelandOverviewMain