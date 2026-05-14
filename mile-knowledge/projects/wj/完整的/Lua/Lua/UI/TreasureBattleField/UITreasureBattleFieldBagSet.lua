-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITreasureBattleFieldBagSet
-- Date: 2023-05-22 16:12:57
-- Desc: ?
-- ---------------------------------------------------------------------------------

local LOOT_COLOR_MENU = {
    "蓝色以上",   -- 3
    "紫色以上",
    "橙色以上",
}

local DROP_COLOR_MENU = {
    "不丢弃",
    "白色",     -- 1
    "绿色",     -- 2
    "蓝色及以下",
    "紫色及以下",
}

local UITreasureBattleFieldBagSet = class("UITreasureBattleFieldBagSet")

function UITreasureBattleFieldBagSet:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UITreasureBattleFieldBagSet:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITreasureBattleFieldBagSet:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UITreasureBattleFieldBagSet:RegEvent()
    Event.Reg(self, EventType.OnClientPlayerLeave, function (nPlayerID)
        UIMgr.Close(self)
    end)
end

function UITreasureBattleFieldBagSet:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITreasureBattleFieldBagSet:UpdateInfo()
    local tLootConf = {}
    tLootConf.szName = "自动拾取设置"
    for i = 1, #LOOT_COLOR_MENU do
        local szName = LOOT_COLOR_MENU[i]
        local nColor = i + 2
        local bChecked = TreasureBattleFieldData.nLootColor == nColor
        local fnAction = function (bSelected)
            if bSelected then
                TreasureBattleFieldData.nLootColor = nColor
            end
        end
        table.insert(tLootConf, { szName = szName, bChecked = bChecked, fnAction = fnAction, bToggleGroup = true })
    end
    local lootScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSetContent, self.ScorllViewSetContent)
    lootScript:OnEnter(tLootConf)

    local tDropConf = {}
    tDropConf.szName = "装备快捷丢弃设置"
    for i = 1, #DROP_COLOR_MENU do
        local szName = DROP_COLOR_MENU[i]
        local nColor = i - 1
        local bChecked = TreasureBattleFieldData.nDropColor == nColor
        local fnAction = function (bSelected)
            if bSelected then
                TreasureBattleFieldData.nDropColor = nColor
            end
        end
        table.insert(tDropConf, { szName = szName, bChecked = bChecked, fnAction = fnAction, bToggleGroup = true })
    end
    local fnDropHorse = function (bSelected)
        TreasureBattleFieldData.bIncludeHorse = bSelected
    end
    table.insert(tDropConf, { szName = "包含坐骑", bChecked = TreasureBattleFieldData.bIncludeHorse, fnAction = fnDropHorse})
    local dropScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSetContent, self.ScorllViewSetContent)
    dropScript:OnEnter(tDropConf)

    local tFeedConf = {}
    tFeedConf.szName = "自动喂马设置"
    local fnFeedHorse = function (bSelected)
        TreasureBattleFieldData.bAutoFeedHorse = bSelected
    end
    table.insert(tFeedConf, { szName = "自动喂马", bChecked = TreasureBattleFieldData.bAutoFeedHorse, fnAction = fnFeedHorse})
    local feedScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSetContent, self.ScorllViewSetContent)
    feedScript:OnEnter(tFeedConf)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScorllViewSetContent)
    -- UIHelper.ScrollViewDoLayout(self.ScorllViewSetContent)
end


return UITreasureBattleFieldBagSet