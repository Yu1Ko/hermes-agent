-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandOverVIewTargetList
-- Date: 2024-01-30 17:17:34
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandOverVIewTargetList = class("UIHomelandOverVIewTargetList")

function UIHomelandOverVIewTargetList:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nCommunityCount = 0

    local pHomelandMgr = GetHomelandMgr()
    local tTemp = pHomelandMgr.GetAllMyLand()
    self.nCommunityCount = 0
    for i = 1, #tTemp do
        if not tTemp[i].bPrivateLand then
            self.nCommunityCount = self.nCommunityCount + 1
        end
    end
end

function UIHomelandOverVIewTargetList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandOverVIewTargetList:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        Event.Dispatch(EventType.HideAllHoverTips)
    end)
end

function UIHomelandOverVIewTargetList:RegEvent()
    Event.Reg(self, "HOME_LAND_RESULT_CODE", function ()
        local pHomelandMgr = GetHomelandMgr()
        local tTemp = pHomelandMgr.GetAllMyLand()
        self.nCommunityCount  = 0
        for i = 1, #tTemp do
            if not tTemp[i].bPrivateLand then
                self.nCommunityCount  = self.nCommunityCount  + 1
            end
        end
    end)
end

function UIHomelandOverVIewTargetList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandOverVIewTargetList:ShowList(tMenuInfo, tLandInfo, tData)
    UIHelper.RemoveAllChildren(self.LayoutSalesmanList)
    self.tMenuInfo          = tMenuInfo
    self.tLandInfo          = tLandInfo
    self.tData              = tData

    for index, tbTargetInfo in ipairs(self.tMenuInfo) do
        local bContinue = true
        if Homeland_ToBoolean(tbTargetInfo.nCommunityLimit) then
            if self.nCommunityCount < 1 then
                bContinue = false
            end
        end
        if bContinue then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetLeaveForBtn, self.LayoutSalesmanList)
            self:InitLeaveBtn(script, index, tbTargetInfo)
            UIHelper.SetTouchDownHideTips(script.BtnLeaveFor, false)
        end
    end
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutList, true, true)
end

function UIHomelandOverVIewTargetList:InitLeaveBtn(btn, nIndex, tbTargetInfo)
    local tLandInfo = self.tLandInfo
    local tData = self.tData
    local szInfo = UIHelper.GBKToUTF8(tbTargetInfo.szName)
    local bLock = false
    if tLandInfo and tbTargetInfo.nLevel > 0 and tbTargetInfo.nLevel > tLandInfo.nLevel then
        szInfo = szInfo .. FormatString(g_tStrings.STR_HOMELAND_OVERVIEW_LEVEL_LIMIT, tbTargetInfo.nLevel)
        bLock = true
    else
        bLock = false
        local nNowCount = tData[nIndex]
        if tbTargetInfo.nMax and tbTargetInfo.nMax >= 0 then
            szInfo = szInfo .. FormatString(g_tStrings.STR_FURNITURE_LIST_TYPE_NUM, nNowCount, tbTargetInfo.nMax)
        end
    end
    if bLock then
        btn:BindClickFunction()
        UIHelper.SetNodeGray(btn._rootNode, true, true)
    else
        btn:BindClickFunction(function ()
            self:OnClickLeaveForBtn(tbTargetInfo, nIndex)
        end)
    end
    btn:SetLabelText(szInfo)
end

function UIHomelandOverVIewTargetList:OnClickLeaveForBtn(tbTargetInfo, nIndex)
    MapMgr.BeforeTeleport()
    if tbTargetInfo.nLinkID > 0 and tbTargetInfo.nMapID > 0 then
        local tLink = Table_GetCareerLinkNpcInfo(tbTargetInfo.nLinkID, tbTargetInfo.nMapID)
        local tTrack = {
            dwMapID  = tLink.dwMapID,
            szName   = UIHelper.GBKToUTF8(tLink.szNpcName),
            nX       = tLink.fX,
            nY       = tLink.fY,
            nZ       = tLink.fZ,
            szSource = "HomelandOverview",
        }
        MapMgr.SetTracePoint(tTrack.szName, tTrack.dwMapID, {tTrack.nX, tTrack.nY, tTrack.nZ})
        UIMgr.Open(VIEW_ID.PanelMiddleMap, tLink.dwMapID, 0)
    elseif tbTargetInfo.nCalendarID > 0 then
        local szLink = "LinkActivity/" .. tbTargetInfo.nCalendarID
        Event.Dispatch("EVENT_LINK_NOTIFY", szLink)
    elseif tbTargetInfo.nFurnitureType > 0 then
        local nFurnitureType = tbTargetInfo.nFurnitureType
        local pHlMgr = GetHomelandMgr()
        local nCount
        local dwMapID, nCopyIndex, nLandIndex = HomelandBuildData.GetMapInfo()
        local bIsMyLand = pHlMgr.IsMyLand(dwMapID, nCopyIndex, nLandIndex)
        if nLandIndex == 0 then
            nCount = 0
        else
            nCount = pHlMgr.GetCategoryCount(nLandIndex, nFurnitureType)
        end
        local fnCallback = function()
            if not bIsMyLand and nCount == 0 then
                UIMgr.Close(VIEW_ID.PanelHomeOverview)
                RemoteCallToServer("On_HomeLand_GoHomeSmart", self.tMenuInfo.dwID, nIndex, tbTargetInfo.nFurnitureType)
            else
                HomelandData.TryTransferToFurniture(nFurnitureType, tbTargetInfo.nCatg1, tbTargetInfo.nCatg2, tbTargetInfo.nSubgroup)
            end
        end

        if HomelandData.IsHomelandCommunityMap(dwMapID) or HomelandData.OnTransToHomelandMap() then
            fnCallback()
        else
            MapMgr.CheckTransferCDExecute(fnCallback)
        end
    elseif tbTargetInfo.nGuide > 0 then
        local nGuide = tbTargetInfo.nGuide
        RemoteCallToServer("On_HomeLand_OVVSpGuide", nGuide)
        UIMgr.Close(VIEW_ID.PanelHomeOverview)
    end
end


return UIHomelandOverVIewTargetList