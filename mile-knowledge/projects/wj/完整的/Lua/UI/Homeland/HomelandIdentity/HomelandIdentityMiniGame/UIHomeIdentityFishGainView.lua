-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeIdentityFishGainView
-- Date: 2024-02-02 17:46:00
-- Desc: ?
-- ---------------------------------------------------------------------------------
local MAX_SHOW_NUM = 4
local TIME_TO_CLOSE = 6
local UIHomeIdentityFishGainView = class("UIHomeIdentityFishGainView")
local DataModel = {
    tFishData   = {},
    tModLine    = {},
    nCount      = 1,
    bIsOperate  = false,
    -- bHaveBreak  = false,
    nAddFish    = 0,
    nStartTime  = 0
}

function DataModel.Init(tFish, nExp)
    DataModel.nStartTime   = 0
    DataModel.tFishData    = tFish
    DataModel.nExp         = nExp
    DataModel.tFishInfo    = Table_GetAllFishInfo()
    DataModel.nFisherLevel = GDAPI_HLIdentityGetCurLv(1)
    DataModel.tModLine     = {}
    DataModel.nCount       = 1
    DataModel.bIsOperate   = false
    -- DataModel.bHaveBreak   = CheckBreakFish()

end

function DataModel.GetFishInfo(dwID)
    for _, v in pairs(DataModel.tFishInfo) do
        if v.dwID == dwID then
            return v
        end
    end
end

local function GetTheFishTable()
    local tFish = {}
    for _, v in pairs(DataModel.tFishData) do
        table.insert(tFish, {nFishIndex = v.nFishIndex, num = v.num})
    end
    return tFish
end

local function PutLastFishInBag()
    local tFish = GetTheFishTable()
    RemoteCallToServer("On_HomeLand_GetFish", tFish, Storage.HLIdentity.bIsAutoGetFish)
end

function DataModel.UnInit()
    DataModel.tFishData = {}
    DataModel.tModLine     = {}
    DataModel.nCount    = 1
end

function UIHomeIdentityFishGainView:OnEnter(tFish, nExp)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        DataModel.Init(tFish, nExp)
        DataModel.nStartTime = GetCurrentTime()
        self.bInit = true
    end
    self.tFish = tFish
    self.nExp = nExp
    self:UpdateInfo()
end

function UIHomeIdentityFishGainView:OnExit()
    local tFish = GetTheFishTable()
    self:SetAutoFishing(tFish, Storage.HLIdentity.bIsAutoGetFish)
    self.bInit = false
    self:UnRegEvent()
end

function UIHomeIdentityFishGainView:BindUIEvent()
    UIHelper.SetSelected(self.TogAuto, Storage.HLIdentity.bIsAutoGetFish)
    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function(btn)
        Event.Dispatch(EventType.OnGetFishTips, self.tFish, self.nExp)
        UIMgr.Close(self)
    end)

    UIHelper.SetClickInterval(self.TogAuto, 0)
    UIHelper.BindUIEvent(self.TogAuto, EventType.OnClick, function()
        local scriptFishView = UIMgr.GetViewScript(VIEW_ID.PanelFish)
        if scriptFishView then
            scriptFishView:SetAutoFishing(UIHelper.GetSelected(self.TogAuto), true)
        end
        UIHelper.SetSelected(self.TogAuto, Storage.HLIdentity.bIsAutoGetFish)
        if Storage.HLIdentity.bIsAutoGetFish then
            self:UpdateAutoCloseTimer()
        else
            UIHelper.SetVisible(self.LabelAcceptTime, false)
            UIHelper.LayoutDoLayout(self.LayoutAccept)
            Timer.DelTimer(self, self.nTimerID)
            self.nTimerID = nil
        end
    end)
end

function UIHomeIdentityFishGainView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomeIdentityFishGainView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomeIdentityFishGainView:UpdateInfo(tFish, nExp)
    if tFish and #tFish > 0 then
        if #DataModel.tFishData + #tFish > 8 then
            -- 防止新来的鱼无法被接受
            PutLastFishInBag()
            DataModel.Init(tFish, nExp)
        elseif #DataModel.tFishData == 1 and DataModel.nExp == 0 then
            PutLastFishInBag()
            DataModel.Init(tFish, nExp)
        else
            DataModel.nAddFish = #DataModel.tFishData + 1
            for _, v in pairs(tFish) do
                table.insert(DataModel.tFishData, v)
            end
            DataModel.nExp = DataModel.nExp + nExp
        end
    end
    self:UpdateExpInfo()
    self:UpdateFishList()

    if Storage.HLIdentity.bIsAutoGetFish then
        self:UpdateAutoCloseTimer()
    else
        UIHelper.SetVisible(self.LabelAcceptTime, false)
        UIHelper.LayoutDoLayout(self.LayoutAccept)
    end
end

function UIHomeIdentityFishGainView:UpdateExpInfo()
    local nExp = DataModel.nExp or 0
    UIHelper.SetString(self.LabelRewardNum, tostring(nExp))
end

function UIHomeIdentityFishGainView:UpdateFishList()
    UIHelper.RemoveAllChildren(self.ScrollViewFishGet)
    UIHelper.RemoveAllChildren(self.LayoutFishGet01)
    UIHelper.SetVisible(self.ScrollViewFishGet, false)
    UIHelper.SetVisible(self.LayoutFishGet01, false)

    local tFishList = DataModel.tFishData
    local layout = self.LayoutFishGet01
    if #tFishList > MAX_SHOW_NUM then
        layout = self.ScrollViewFishGet
    end

    for _, tData in ipairs(tFishList) do
        local tInfo = DataModel.GetFishInfo(tData.nFishIndex)
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetFishGetCell, layout)
        script:OnEnter(tData, tInfo)
    end

    UIHelper.SetVisible(layout, true)
    UIHelper.LayoutDoLayout(self.LayoutFishGet01)
    UIHelper.WidgetFoceDoAlignAssignNode(self, self.LayoutFishGet01)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewFishGet)
end

function UIHomeIdentityFishGainView:UpdateAutoCloseTimer()
    local nTime = TIME_TO_CLOSE
    local function func()
        nTime = nTime - 1
        UIHelper.SetString(self.LabelAcceptTime, string.format("(%s)", nTime))
        if nTime <= 0 then
            UIMgr.Close(self)
            Timer.DelTimer(self, self.nTimerID)
            self.nTimerID = nil
        end
    end

    UIHelper.SetVisible(self.LabelAcceptTime, true)
    UIHelper.LayoutDoLayout(self.LayoutAccept)
    self.nTimerID = self.nTimerID or Timer.AddCycle(self, 1, function ()
        func()
    end)

    func()
end

function UIHomeIdentityFishGainView:SetAutoFishing(tFish, bAuto)
    local bOldState = Storage.HLIdentity.bIsAutoGetFish
    if not HomelandFishingData.tExpData or HomelandFishingData.tExpData.nLevel < 2 then
        if bAuto then
            TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_GetFish_Level)
        end
        bAuto = false
    end
    Storage.HLIdentity.bIsAutoGetFish = bAuto
    UIHelper.SetSelected(self.TogAuto, Storage.HLIdentity.bIsAutoGetFish)
    RemoteCallToServer("On_HomeLand_GetFish", tFish, Storage.HLIdentity.bIsAutoGetFish)
end
return UIHomeIdentityFishGainView