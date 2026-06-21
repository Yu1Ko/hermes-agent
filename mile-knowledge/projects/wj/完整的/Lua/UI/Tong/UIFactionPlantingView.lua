-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIFactionPlantingView
-- Date: 2023-06-01 10:19:19
-- Desc: 帮会活动-种菜
-- Prefab: PanelFactionPlanting
-- ---------------------------------------------------------------------------------

local TONG_FARM_MATURE      = 100

---@class UIFactionPlantingView
local UIFactionPlantingView = class("UIFactionPlantingView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIFactionPlantingView:_LuaBindList()
    self.SliderHealth         = self.SliderHealth --- 健康值进度条
    self.LabelBarNumHealth    = self.LabelBarNumHealth --- 健康值进度百分比

    self.SliderGrowth         = self.SliderGrowth --- 成长值进度条
    self.LabelBarNumGrowth    = self.LabelBarNumGrowth --- 成长值进度百分比

    self.LabelBarLandLevel    = self.LabelBarLandLevel --- 土地等级
    self.SliderLandLevel      = self.SliderLandLevel --- 土地等级进度条
    self.LabelBarNumLandLevel = self.LabelBarNumLandLevel --- 土地等级进度百分比

    self.BtnChoose            = self.BtnChoose --- 选择种子按钮
    self.WidgetLeftBag        = self.WidgetLeftBag --- 挂载左侧背包预制的节点
    self.WidgetItem           = self.WidgetItem --- 挂载当前选择或者已种植的种子道具的节点
    self.LabelCellTitle       = self.LabelCellTitle --- 当前种子的名称
    self.BtnAdd               = self.BtnAdd --- 更换为其他种子的按钮
    self.LayoutItemBox        = self.LayoutItemBox --- 种子信息上层的layout

    self.BtnPlant             = self.BtnPlant --- 种植按钮

    self.LayoutBtn            = self.LayoutBtn --- 按钮的layout
    self.BtnRemove            = self.BtnRemove --- 铲除按钮
    self.BtnHarvest           = self.BtnHarvest --- 收获按钮
end

function UIFactionPlantingView:OnEnter(dwNpcID, bEmpty, dwOwnerID, nHealth, nMature, nSeedItemID, nSoilLevel, nSoilExperience)
    --- 土地的NpcID
    self.dwNpcID         = dwNpcID
    --- 是否为空地（未种植）
    self.bEmpty          = bEmpty
    --- 当前种植的玩家ID
    self.dwOwnerID       = dwOwnerID
    --- 健康值
    self.nHealth         = nHealth
    --- 成长值
    self.nMature         = nMature
    --- 当前种植的种子ID
    self.nSeedItemID     = nSeedItemID
    --- 土地等级
    self.nSoilLevel      = nSoilLevel
    --- 土地经验
    self.nSoilExperience = nSoilExperience

    if self.nSoilExperience and self.nSoilExperience > TONG_FARM_MATURE then
        self.nSoilExperience = TONG_FARM_MATURE
    end
    if self.nHealth and self.nHealth > TONG_FARM_MATURE then
        self.nHealth = TONG_FARM_MATURE
    end
    if self.nMature and self.nMature > TONG_FARM_MATURE then
        self.nMature = TONG_FARM_MATURE
    end

    --- 当前是否放置了种子，准备播种
    self.bPutSeed = false

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
    
    self.nTimerID = self.nTimerID or Timer.AddFrameCycle(self, 1, function() 
        self:OnFrameBreathe()
    end)
end

function UIFactionPlantingView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFactionPlantingView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnChoose, EventType.OnClick, function()
        self:ShowLeftBag()
    end)

    UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function()
        self:ShowLeftBag()
    end)

    UIHelper.BindUIEvent(self.BtnPlant, EventType.OnClick, function()
        self:Plant()
    end)

    UIHelper.BindUIEvent(self.BtnRemove, EventType.OnClick, function()
        self:RemovePlants()
    end)

    UIHelper.BindUIEvent(self.BtnHarvest, EventType.OnClick, function()
        self:Harvest()
    end)
end

function UIFactionPlantingView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "UPDATE_SELECT_TARGET", function()
        local hPlayer = GetClientPlayer()
        local dwTargetType, dwTargetID = hPlayer.GetTarget()
        if dwTargetType ~= TARGET.NPC or dwTargetID ~= self.dwNpcID then
            self:ClosePanels()
        end
    end)
end

function UIFactionPlantingView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFactionPlantingView:UpdateInfo()
    if not self.bEmpty then
        UIHelper.SetProgressBarPercent(self.SliderHealth, self.nHealth)
        UIHelper.SetString(self.LabelBarNumHealth, self.nHealth .. "%")

        UIHelper.SetProgressBarPercent(self.SliderGrowth, self.nMature)
        UIHelper.SetString(self.LabelBarNumGrowth, self.nMature .. "%")
    else
        UIHelper.SetProgressBarPercent(self.SliderHealth, 0)
        UIHelper.SetString(self.LabelBarNumHealth, "")

        UIHelper.SetProgressBarPercent(self.SliderGrowth, 0)
        UIHelper.SetString(self.LabelBarNumGrowth, "")
    end

    self:UpdateSeedInfo()

    UIHelper.SetString(self.LabelBarLandLevel, self.nSoilLevel + 1)
    UIHelper.SetProgressBarPercent(self.SliderLandLevel, self.nSoilExperience)
    UIHelper.SetString(self.LabelBarNumLandLevel, self.nSoilExperience .. "%")

    UIHelper.SetVisible(self.BtnPlant, self.bEmpty)
    UIHelper.SetVisible(self.LayoutBtn, not self.bEmpty)
    UIHelper.SetVisible(self.BtnRemove, not self.bEmpty)
    UIHelper.SetVisible(self.BtnHarvest, not self.bEmpty)

    local nStateBtnPlant   = BTN_STATE.Disable
    local nStateBtnRemove  = BTN_STATE.Disable
    local nStateBtnHarvest = BTN_STATE.Disable

    if self.bPutSeed then
        nStateBtnPlant = BTN_STATE.Normal
    elseif not self.bEmpty then
        if self.nMature >= TONG_FARM_MATURE then
            nStateBtnHarvest = BTN_STATE.Normal
        elseif g_pClientPlayer and g_pClientPlayer.dwID == self.dwOwnerID then
            nStateBtnRemove = BTN_STATE.Normal
        end
    end

    UIHelper.SetButtonState(self.BtnPlant, nStateBtnPlant)
    UIHelper.SetButtonState(self.BtnRemove, nStateBtnRemove)
    UIHelper.SetButtonState(self.BtnHarvest, nStateBtnHarvest)
end

function UIFactionPlantingView:UpdateSeedInfo()
    local bShowSeedItem = self.nSeedItemID ~= 0

    UIHelper.SetVisible(self.WidgetItem, bShowSeedItem)
    UIHelper.SetVisible(self.BtnChoose, not bShowSeedItem)
    UIHelper.SetVisible(self.BtnAdd, self.bPutSeed)

    if bShowSeedItem then
        local dwTabType, dwIndex = ITEM_TABLE_TYPE.OTHER, self.nSeedItemID

        UIHelper.RemoveAllChildren(self.WidgetItem)
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetItem)
        script:OnInitWithTabID(dwTabType, dwIndex)
        script:SetClickCallback(function(dwItemTabType, dwItemTabIndex)
            TipsHelper.ShowItemTips(script._rootNode, dwTabType, dwIndex)
        end)

        local ItemInfo   = GetItemInfo(dwTabType, dwIndex)
        local szItemName = ItemData.GetItemNameByItemInfo(ItemInfo)
        UIHelper.SetString(self.LabelCellTitle, UIHelper.GBKToUTF8(szItemName))
    else
        UIHelper.SetString(self.LabelCellTitle, "种子")
    end

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutItemBox, true, true)
end

function UIFactionPlantingView:ShowLeftBag()
    local tSeedItemIndexList = {}

    -- SEED【种子属性表】[种子编号] = {种子ItemID, 种子DoodadID, 半成熟DoodadID, 成熟DoodadID, 成熟时间, 种子等级(从0开始),
    --	是否战斗, 招怪系数, 生长经验, 成就ID, 体力值, 需求生活技能ID, 需求生活技能等级, 生活技能经验, 当前版本是否可用，种子类型（用于种植时进行特殊条件判断）},
    for i = 1, #SEED do
        local tSeed                   = SEED[i]

        local dwIndex                 = tSeed[1]
        local bEnableInCurrentVersion = tSeed[15]

        if bEnableInCurrentVersion then
            table.insert(tSeedItemIndexList, {
                dwTabType = ITEM_TABLE_TYPE.OTHER,
                dwIndex = dwIndex,
            })
        end
    end

    local tItemTipBtnList = {}
    table.insert(tItemTipBtnList, {
        szName = "置入",
        OnClick = function(dwItemTabType, dwItemTabIndex)
            Event.Dispatch(EventType.HideAllHoverTips)
            UIMgr.Close(VIEW_ID.PanelLeftBag)

            self.nSeedItemID = dwItemTabIndex
            self.bPutSeed    = true

            self:UpdateInfo()
        end
    })

    local script = UIMgr.Open(VIEW_ID.PanelLeftBag)
    script:OnInitWithTabID(tSeedItemIndexList, tItemTipBtnList)
    UIHelper.SetString(script.LabelEmptyDescription, "请前往种子商郭语成处购买种子")
end

function UIFactionPlantingView:Plant()
    local nSeedLevel = self:GetSeedLevel()

    if nSeedLevel > self.nSoilLevel then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.TONG_FARM_SEED_LEVEL_NOT_MATCH)
    else
        RemoteCallToServer("SowingPlant", self.dwNpcID, self.nSeedItemID)
        self:ClosePanels()
    end
end

function UIFactionPlantingView:GetSeedLevel()
    local nSeedLevel = 0
    for i = 1, #SEED do
        local tSeed = SEED[i]
        if tSeed[1] == self.nSeedItemID then
            if not tSeed[15] then
                return
            end

            nSeedLevel = tSeed[6]
            break
        end
    end

    return nSeedLevel
end

function UIFactionPlantingView:RemovePlants()
    local szMessage = string.trim(g_tStrings.TONG_FARM_SEED_KILL, " ")
    UIHelper.ShowConfirm(szMessage, function()
        RemoteCallToServer("KillPlant", self.dwNpcID)
        self:ClosePanels()
    end, nil)
end

function UIFactionPlantingView:Harvest()
    RemoteCallToServer("ReapPlant", self.dwNpcID)
    self:ClosePanels()
end

function UIFactionPlantingView:OnFrameBreathe()
    local hPlayer = GetClientPlayer()
    if not hPlayer or hPlayer.nMoveState == MOVE_STATE.ON_DEATH then
        self:ClosePanels()
        return
    end

    if self.dwNpcID then
        local hNpc = GetNpc(self.dwNpcID)
        if not hNpc or not hNpc.CanDialog(hPlayer) then
            self:ClosePanels()
        end
    end
end

function UIFactionPlantingView:ClosePanels()
    UIMgr.Close(self)
    UIMgr.Close(VIEW_ID.PanelLeftBag)
end

return UIFactionPlantingView