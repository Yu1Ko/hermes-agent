-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandIdentityActityCard
-- Date: 2024-01-18 10:55:02
-- Desc: ?
-- ---------------------------------------------------------------------------------
local FURNITURE_TYPE = {
    Cook = 4,
    Brew = 18,
}
local tFishActivity = {
    [1] = 161,    --帮会钓鱼
    [2] = 899,    --野外钓鱼(工作日)
    [3] = 920,    --野外钓鱼(周末)
}

local DataModel = {}
local UIHomelandIdentityActityCard = class("UIHomelandIdentityActityCard")
function UIHomelandIdentityActityCard:OnEnter(tbDataModel)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    DataModel = tbDataModel
end

function UIHomelandIdentityActityCard:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandIdentityActityCard:BindUIEvent()
    UIHelper.SetScrollViewCombinedBatchEnabled(self.ScrollViewActivityTarget)
    UIHelper.SetScrollViewCombinedBatchEnabled(self.ScrollViewFish)
    UIHelper.SetSwallowTouches(self.ScrollViewActivityTarget, false)
    UIHelper.BindUIEvent(self.BtnRacks, EventType.OnClick, function ()
        --小推车
        UIMgr.Open(VIEW_ID.PanelDiningCar)
    end)

    UIHelper.BindUIEvent(self.BtnFisher, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelHomeFishDeal)
    end)

    UIHelper.BindUIEvent(self.BtnOrder, EventType.OnClick, function ()
        --订单
        local dwPlayerID = PlayerData.GetClientPlayer().dwID
        HomelandIdentity.OpenPanelHomeOrder(dwPlayerID, self.nTypeIndex)
    end)

    UIHelper.BindUIEvent(self.BtnConfiguration, EventType.OnClick, function ()
        --调香
        HomelandIdentity.OpenConfigurationPop()
    end)

    UIHelper.BindUIEvent(self.BtnBrew, EventType.OnClick, function ()
        UIHelper.ShowConfirm(g_tStrings.tbTryTransferToFurniture.Brea, function ()
            UIMgr.Close(VIEW_ID.PanelHomeIdentity)
            HomelandData.TryTransferToFurniture(FURNITURE_TYPE.Brew)
        end)
    end)

    UIHelper.BindUIEvent(self.BtnCook, EventType.OnClick, function ()
        UIHelper.ShowConfirm(g_tStrings.tbTryTransferToFurniture.Cook, function ()
            UIMgr.Close(VIEW_ID.PanelHomeIdentity)
            HomelandData.TryTransferToFurniture(FURNITURE_TYPE.Cook)
        end)
    end)

    UIHelper.BindUIEvent(self.BtnConfigurationSide, EventType.OnClick, function ()
        HomelandIdentity.UseToyBoxSkill(76)
    end)
end

function UIHomelandIdentityActityCard:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandIdentityActityCard:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
local function GetActiveActivity()
    local tRes = {}
    for _, v in pairs(tFishActivity) do
        if ActivityData.CheckActiveIsShowByID(v) then
            table.insert(tRes, v)
        end
    end
    return tRes
end

function UIHomelandIdentityActityCard:UpdateInfo(nTypeIndex)
    UIHelper.RemoveAllChildren(self.ScrollViewActivityTarget)
    self.nTypeIndex = nTypeIndex
    local tIdentityUIInfo   = DataModel.tIdentityInfo[nTypeIndex]
    local dwID              = tIdentityUIInfo.dwID
    local tData         = DataModel.GetIdentityData(dwID)
    local tBaseList     = DataModel.GetBaseList(dwID)
    local tTashInfo     = tData.tTaskInfo

    if nTypeIndex ~= HLORDER_TYPE.FLOWER then
        local dwPriorityID  = tBaseList[1]
        local tBaseInfo     = DataModel.GetPriorityInfo(dwPriorityID) or {}
        local tBaseData     = DataModel.GetBaseData(dwID, dwPriorityID) or {}
        local szBaseData    = UIHelper.GBKToUTF8(tBaseInfo.szName) or ""
        UIHelper.AddPrefab(PREFAB_ID.WidgetOrderTitle2, self.ScrollViewActivityTarget, szBaseData, tBaseData.nValue)
    end

    for index, v in ipairs(tTashInfo) do
        local dwTaskID = v.dwTaskID
        local tTaskData     = DataModel.GetTaskData(dwID, dwTaskID)
        local tTaskInfo     = DataModel.GetTaskInfo(dwTaskID)
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetOrderTitle, self.ScrollViewActivityTarget)
        script:OnEnter(tTaskData, tTaskInfo)
    end

    UIHelper.SetVisible(self.WidgetBtnCook, false)
    UIHelper.SetVisible(self.BtnConfiguration, false)
    UIHelper.SetVisible(self.BtnConfigurationSide, false)
    UIHelper.SetVisible(self.BtnRacks, false)
    UIHelper.SetVisible(self.BtnOrder, false)
    UIHelper.SetVisible(self.BtnFisher, false)
    UIHelper.SetVisible(self.WidgetFishEmpty, false)
    UIHelper.SetVisible(self.ScrollViewFish, false)
    UIHelper.SetVisible(self.ScrollViewFishTop, false)
    if nTypeIndex == HLORDER_TYPE.FLOWER then
        UIHelper.SetVisible(self.BtnOrder, true)
        UIHelper.SetVisible(self.BtnConfiguration, true)
        UIHelper.SetVisible(self.BtnConfigurationSide, true)
    elseif nTypeIndex == HLORDER_TYPE.COOK then
        UIHelper.SetVisible(self.BtnRacks, true)
        UIHelper.SetVisible(self.BtnOrder, true)
        UIHelper.SetVisible(self.WidgetBtnCook, true)
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetTurnover, self.ScrollViewActivityTarget)
        script:OnEnter(true)
    else
        UIHelper.SetVisible(self.BtnFisher, true)
        UIHelper.SetVisible(self.ScrollViewFish, true)
        UIHelper.RemoveAllChildren(self.ScrollViewFish)

        local scriptPrivateHomeFish = UIHelper.AddPrefab(PREFAB_ID.WidgetOrderListTitle, self.ScrollViewFish)
        UIHelper.SetString(scriptPrivateHomeFish.LabelTitleUp, g_tStrings.STR_ACTIVITY_PRIVATE_HOME_FISH)
        UIHelper.SetRichText(scriptPrivateHomeFish.LabelTime, "<color=#245460>"..g_tStrings.STR_ACTIVITY_PERMANENT.."</color>")
        UIHelper.SetVisible(scriptPrivateHomeFish.LabelTime, false)
        UIHelper.SetVisible(scriptPrivateHomeFish.BtnGo, true)
        UIHelper.BindUIEvent(scriptPrivateHomeFish.BtnGo, EventType.OnClick, function()
            local tPrivateHash = GetHomelandMgr().GetAllMyPrivateHome()
            RemoteCallToServer("On_HomeLand_GoHomeSmart", 6, 1, 16)
            if table.is_empty(tPrivateHash) then
                HomelandData.OpenHomelandPanel()
            else
                UIMgr.Close(VIEW_ID.PanelHomeIdentity)
                UIMgr.Close(VIEW_ID.PanelHomeOverview)
                UIMgr.Close(VIEW_ID.PanelHome)
            end
        end)

        local tActivityList = GetActiveActivity()
        for index, dwActiveID in ipairs(tActivityList) do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetOrderListTitle, self.ScrollViewFish)
            script:OnEnter(dwActiveID, DataModel.tFishPoint)
        end
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewFish)
        UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewActivityTarget)
end


return UIHomelandIdentityActityCard