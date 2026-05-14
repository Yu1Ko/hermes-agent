-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandIdentityView
-- Date: 2024-01-17 11:00:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandIdentityView = class("UIHomelandIdentityView")
local ACTIVITY_FISH = 899
local LOCK_FONT = 102
local EXP_FONT = 101
local UNLOCK_FONT = 165
local RANK_LIST_ID = 292
local HLIDENTITY_INDEX =
{
    FLOWER = 1, --花匠
    COOK   = 2, --掌柜
    FISH   = 3, --渔夫
}
local HLIdentityType2Index =
{
    [HLIDENTITY_TYPE.FLOWER] = HLIDENTITY_INDEX.FLOWER,
    [HLIDENTITY_TYPE.COOK] = HLIDENTITY_INDEX.COOK,
    [HLIDENTITY_TYPE.FISH] = HLIDENTITY_INDEX.FISH,
}
local MAX_IDENTITY = 3
local bApplyHomelandInfo = false
-----------------------------DataModel------------------------------
local DataModel = {}

function DataModel.Init()
    DataModel.nCurrentSelect  = 0
    DataModel.tFishPoint      = {}
    DataModel.tIdentityData   = GDAPI_GetHLIdentityInfo()
    DataModel.tIdentityInfo   = Table_GetAllHLIdentity()
    DataModel.tHLPriorityInfo = Table_GetAllHLIdentityPriority()
    DataModel.tHLPriorityType = Table_GetAllHLIdentityPriorityType()
    DataModel.tHLTaskInfo     = Table_GetAllHLTask()
    DataModel.ParseAllPriority()
end

local function ParsePriority(tValue)
    local tRes = {}
    for i, v in pairs(tValue) do
        tRes[i] = tonumber(v)
    end
    return tRes
end

local function ParseExtPriority(tValue)
    local tRes = {}
    local tExtList = ParsePriority(tValue)
    for _, v in pairs(tExtList) do
        local tInfo = DataModel.GetPriorityInfo(v)
        if tInfo and tInfo.nType then
            if not tRes[tInfo.nType] then
                tRes[tInfo.nType] = {}
            end
            table.insert(tRes[tInfo.nType], tInfo)
        end
    end
    return tRes
end

function DataModel.ParseAllPriority()
    for k, v in pairs(DataModel.tIdentityInfo) do
        DataModel.tIdentityInfo[k].tAbility  = ParsePriority(SplitString(v.szAbility, ";"))
        DataModel.tIdentityInfo[k].tExtList  = ParseExtPriority(SplitString(v.szExtPriority, ";"))
        DataModel.tIdentityInfo[k].tBaseList = ParsePriority(SplitString(v.szBasePriority, ";"))
    end
end

function DataModel.Update()
    DataModel.tIdentityData = GDAPI_GetHLIdentityInfo()
end

function DataModel.GetIdentityData(dwID)
    for _, v in pairs(DataModel.tIdentityData) do
        if v.dwID == dwID then
            return v
        end
    end
end

function DataModel.GetIdentityInfo(dwID)
    for _, v in pairs(DataModel.tIdentityInfo) do
        if v.dwID == dwID then
            return v
        end
    end
end

function DataModel.GetBaseList(dwID)
    for _, v in pairs(DataModel.tIdentityInfo) do
        if v.dwID == dwID then
            return v.tBaseList
        end
    end
end

function DataModel.GetExtList(dwID)
    for _, v in pairs(DataModel.tIdentityInfo) do
        if v.dwID == dwID then
            return v.tExtList
        end
    end
end

function DataModel.GetTaskData(dwID, dwTaskID)
    for _, v in pairs(DataModel.tIdentityData) do
        if v.dwID == dwID and v.tTaskInfo then
            for _, tData in pairs(v.tTaskInfo) do
                if tData.dwTaskID == dwTaskID then
                    return tData
                end
            end
        end
    end
end

function DataModel.GetTaskInfo(dwID)
    for _, v in pairs(DataModel.tHLTaskInfo) do
        if v.dwID == dwID then
            return v
        end
    end
end

function DataModel.GetBaseData(dwID, dwPriorityID)
    for _, v in pairs(DataModel.tIdentityData) do
        if v.dwID == dwID then
            if v.tBaseInfo then
                for _, tData in pairs(v.tBaseInfo) do
                    if tData.dwID == dwPriorityID then
                        return tData
                    end
                end
            end
        end
    end
end

function DataModel.GetExtData(dwID, dwPriorityID)
    for _, v in pairs(DataModel.tIdentityData) do
        if v.dwID == dwID then
            if v.tExtInfo then
                for _, tData in pairs(v.tExtInfo) do
                    if tData.dwID == dwPriorityID then
                        return tData
                    end
                end
            end
        end
    end
end

function DataModel.GetPriorityType(nType)
    for _, v in pairs(DataModel.tHLPriorityType) do
        if v.nType == nType then
            return v
        end
    end
end

function DataModel.GetPriorityInfo(dwID)
    for _, v in pairs(DataModel.tHLPriorityInfo) do
        if v.dwID == dwID then
            return v
        end
    end
end

function DataModel.UnInit()
    for i, v in pairs(DataModel) do
        if type(v) ~= "function" then
            DataModel[i] = nil
        end
    end
end

function UIHomelandIdentityView:OnEnter(nType)
    if not self.bInit then
        DataModel.Init()
        self:Init()
        self:RegEvent()
        self:BindUIEvent()
        ApplyCustomRankList(RANK_LIST_ID)
        self.bInit = true
    end
    self.nTypeIndex = HLIdentityType2Index[nType] or HLIDENTITY_INDEX.FLOWER
    UIHelper.SetToggleGroupSelected(self.ToggleGroup, self.nTypeIndex - 1)
    self:UpdateInfo()
end

function UIHomelandIdentityView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandIdentityView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnNote, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelHomeFishNote)
    end)

    UIHelper.BindUIEvent(self.BtnOrder, EventType.OnClick, function ()
        local dwPlayerID = PlayerData.GetClientPlayer().dwID
        HomelandIdentity.OpenPanelHomeOrder(dwPlayerID, self.nTypeIndex)
    end)

    UIHelper.BindUIEvent(self.BtnMenuExplain, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelTutorialLite, 35)
    end)

    for index, tog in ipairs(self.tbToggleIdentityType) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function ()
            self.nTypeIndex = index
            self:UpdateInfo()
        end)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroup, tog)
    end

    UIHelper.SetTouchDownHideTips(self.ScrollViewTipsLabel, false)
end

function UIHomelandIdentityView:RegEvent()
    Event.Reg(self, EventType.OnHomeIdentityOpenDetailsPop, function ()
        if not UIHelper.GetVisible(self.scriptDetailsPop._rootNode) then
            self:OpenDetailsPop()
        end
    end)

    Event.Reg(self, EventType.OnHomeIdentityCloseDetailsPop, function ()
        self:CloseDetailsPop()
    end)

    Event.Reg(self, EventType.OnHomeIdentityOpenTips, function (tbTips)
        self:ShowIdentityTip(tbTips)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        self:HideIdentityTip()
    end)

    Event.Reg(self, EventType.OnHomelandIdentityUpdate, function ()
        DataModel.Update()
        self:UpdateInfo()
    end)

    Event.Reg(self, "CUSTOM_RANK_UPDATE", function(arg0)
        if arg0 == RANK_LIST_ID then
            DataModel.tFishPoint = GetCustomRankList(RANK_LIST_ID)
            self.scriptRightActity:UpdateInfo(self.nTypeIndex)
        end
    end)

    Event.Reg(self, "REMOTE_HOME_FISH_EVENT", function()
        DataModel.Update()
        local nTypeIndex = self.nTypeIndex
        self.scriptLeftCard:UpdateInfo(nTypeIndex)
    end)

    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID == VIEW_ID.PanelDiningCar then
            UIHelper.PlayAni(self,self.AniAll, "AniRightHide")
        end
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelDiningCar then
            UIHelper.PlayAni(self,self.AniAll, "AniRightShow")
        end
    end)
end

function UIHomelandIdentityView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIHomelandIdentityView:Init()
    self.scriptRightActity  =  UIHelper.GetBindScript(self.WidgetAnchorRight)
    self.scriptLeftCard     =  UIHelper.GetBindScript(self.WidgetLeftUp)

    self.scriptRightActity:OnEnter(DataModel)
    self.scriptLeftCard:OnEnter(DataModel)
end

function UIHomelandIdentityView:UpdateInfo()
    local nTypeIndex = self.nTypeIndex
    self.scriptLeftCard:UpdateInfo(nTypeIndex)
    self.scriptRightActity:UpdateInfo(nTypeIndex)
    self:UpdatePageInfo(nTypeIndex)
end

function UIHomelandIdentityView:UpdatePageInfo(nTypeIndex)
    local tIdentityUIInfo = DataModel.tIdentityInfo
    local szRoleImgPath = UIHelper.FixDXUIImagePath(tIdentityUIInfo[nTypeIndex].szImagePath)
    UIHelper.SetTexture(self.ImgRole, szRoleImgPath)
    UIHelper.SetVisible(self.BtnNote, nTypeIndex == HLIDENTITY_INDEX.FISH)
    UIHelper.SetVisible(self.ImgBgTitleLine, nTypeIndex == HLIDENTITY_INDEX.FISH) -- 左侧没有按钮时分割线隐藏
    UIHelper.SetVisible(self.BtnMenuExplain, nTypeIndex == HLIDENTITY_INDEX.FISH) -- 垂钓教学按钮

    UIHelper.LayoutDoLayout(self.LayoutRTop)
    UIHelper.WidgetFoceDoAlignAssignNode(self, self.LayoutRTop)
end

function UIHomelandIdentityView:OpenDetailsPop()
    UIHelper.PlayAni(self, self.AniAll, "AniBottomHide", function ()
        self.scriptDetailsPop:OpenDetailsPop(self.nTypeIndex)
        UIHelper.SetVisible(self.scriptRightActity._rootNode, false)
    end)
end

function UIHomelandIdentityView:CloseDetailsPop()
    self.scriptDetailsPop:CloseDetailsPop(self.nTypeIndex)
    UIHelper.SetVisible(self.scriptRightActity._rootNode, true)
    UIHelper.PlayAni(self, self.AniAll, "AniBottomShow")
end

function UIHomelandIdentityView:ShowIdentityTip(tbTips)
    UIHelper.SetVisible(self.AniTip, true)
    UIHelper.RemoveAllChildren(self.ScrollViewTipsLabel)

    for _, tbTip in ipairs(tbTips) do
        local scriptTipList = UIHelper.AddPrefab(PREFAB_ID.WidgetTipsLabelList, self.ScrollViewTipsLabel)
        scriptTipList:OnEnter(tbTip)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTipsLabel)
end

function UIHomelandIdentityView:HideIdentityTip()
    UIHelper.SetVisible(self.AniTip, false)
end

-- function UIHomelandIdentityView:UpdateInfo()

-- end

return UIHomelandIdentityView