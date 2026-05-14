-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuyQuicklySearch
-- Date: 2024-07-10 16:25:17
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuyQuicklySearch = class("UIHomelandBuyQuicklySearch")
local FRESH_CD = 5000

-----------------------------DataModel------------------------------
local DataModel = {}

function DataModel.Init(tSearch)
    DataModel.dwCenterID          = tSearch.dwCenterID
    DataModel.dwMapID             = tSearch.dwMapID
    DataModel.bDiscrete           = tSearch.bDiscrete
    DataModel.tIndexList          = tSearch.tIndexList
    DataModel.tLandIndexList      = tSearch.tLandIndexList
    DataModel.bIndexNoLimit       = tSearch.bIndexNoLimit
    DataModel.bLandNoLimit        = tSearch.bLandNoLimit
    DataModel.nCommunityLevel     = tSearch.nCommunityLevel
    DataModel.nLastCommunityIndex = 0

    DataModel.nRetCount           = 0
    DataModel.nBtnEnableTime      = GetTickCount() + FRESH_CD

    DataModel.ApplySearch()
end

function DataModel.UnInit()
    DataModel.dwCenterID          = nil
    DataModel.dwMapID             = nil
    DataModel.bDiscrete           = nil
    DataModel.tIndexList          = nil
    DataModel.tLandIndexList      = nil
    DataModel.bIndexNoLimit       = nil
    DataModel.bLandNoLimit        = nil
    DataModel.nCommunityLevel     = nil
    DataModel.nLastCommunityIndex =  nil

    DataModel.dwRetCenterID = nil
    DataModel.nRetMapID     = nil
    DataModel.nRetCount     = nil
    DataModel.tRetIndex     = nil
    DataModel.tRetLevel     = nil

    DataModel.nBtnEnableTime = nil
end

function DataModel.Update(tResult)
    local nRet = nil
    if tResult.CommunityCount == 0 and DataModel.nRetCount == 0 then
        nRet = -1
    elseif tResult.CommunityCount == 0 and DataModel.nRetCount > 0 then
        nRet = 0
    elseif tResult.CommunityCount > 0 then
        nRet = 1
        DataModel.dwRetCenterID = tResult.CenterID
        DataModel.nRetMapID = tResult.MapID
        DataModel.nRetCount = tResult.CommunityCount
        DataModel.tRetIndex = tResult.CommunityIndex
        DataModel.tRetLevel = tResult.CommunityLevel
        DataModel.nLastCommunityIndex = DataModel.tRetIndex[DataModel.nRetCount]
    end
    return nRet
end

function DataModel.ApplySearch()
    RemoteCallToServer("On_HomeLand_FastSearch",
        DataModel.dwCenterID,
        DataModel.dwMapID,
        DataModel.bDiscrete,
        DataModel.tIndexList,
        DataModel.tLandIndexList,
        DataModel.bIndexNoLimit,
        DataModel.bLandNoLimit,
        DataModel.nCommunityLevel,
        DataModel.nLastCommunityIndex
    )
end

function UIHomelandBuyQuicklySearch:OnEnter(tSearch)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    UIHelper.RemoveAllChildren(self.ScrollViewResult)
    UIHelper.SetVisible(self.WidgetEmpty, true)
    DataModel.Init(tSearch)
    self:Init()
end

function UIHomelandBuyQuicklySearch:OnExit()
    self.bInit = false
    self:UnRegEvent()
    DataModel.UnInit()
end

function UIHomelandBuyQuicklySearch:OnPageExit()
    Timer.DelAllTimer(self)
    DataModel.UnInit()
end

function UIHomelandBuyQuicklySearch:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnNextSearch, EventType.OnClick, function(btn)
        DataModel.ApplySearch()
        DataModel.nBtnEnableTime = GetTickCount() + FRESH_CD
    end)
end

function UIHomelandBuyQuicklySearch:RegEvent()
    Event.Reg(self, "HOME_LAND_RESULT_CODE", function ()
        local nResultType = arg0
        if nResultType == HOMELAND_RESULT_CODE.EASY_SEARCH_COMMUNITY_SUCCEED then
            local tResult = GetHomelandMgr().GetEasySearchCommunity()
            local nRet = DataModel.Update(tResult)
            self:UpdateInfo(nRet)
        elseif nResultType == HOMELAND_RESULT_CODE.EASY_SEARCH_COMMUNITY_FAILED then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_HOMELAND_LANDINDEX_SEARCH_NOMORE)
        end
    end)
end

function UIHomelandBuyQuicklySearch:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandBuyQuicklySearch:Init()
    Timer.AddFrameCycle(self, 1, function ()
        if GetTickCount() >= DataModel.nBtnEnableTime then
            UIHelper.SetString(self.LabelNext, g_tStrings.STR_ALL_LIVE_CHANGE)
            UIHelper.SetButtonState(self.BtnNextSearch, BTN_STATE.Normal)
        else
            local nCoolDownTime = math.ceil((DataModel.nBtnEnableTime - GetTickCount()) / 1000)
            UIHelper.SetString(self.LabelNext, g_tStrings.STR_ALL_LIVE_CHANGE .. "(" .. nCoolDownTime .. ")")
            UIHelper.SetButtonState(self.BtnNextSearch, BTN_STATE.Disable)
        end
    end)
end

function UIHomelandBuyQuicklySearch:UpdateInfo(nRet)
    if nRet == 0 then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_HOMELAND_LANDINDEX_SEARCH_NOMORE)
    elseif nRet == -1 then
        UIHelper.RemoveAllChildren(self.ScrollViewResult)
        UIHelper.SetVisible(self.WidgetEmpty, true)
    elseif nRet == 1 then
        UIHelper.RemoveAllChildren(self.ScrollViewResult)
        for i = 1, DataModel.nRetCount, 1 do
            local nIndex = DataModel.tRetIndex[i]
            local nLevel = DataModel.tRetLevel[i]
            local szName = UIHelper.GBKToUTF8(Table_GetMapName(DataModel.nRetMapID))
            local tbInfo = {
                szMapName = szName,
                nIndex = nIndex,
                nRankValue = nLevel,
                bRecommend = false,
            }
            UIHelper.AddPrefab(PREFAB_ID.WidgetHomeLandLeftListCell, self.ScrollViewResult, tbInfo)
        end
    end

    UIHelper.SetVisible(self.WidgetEmpty, DataModel.nRetCount == 0)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewResult)
end


return UIHomelandBuyQuicklySearch