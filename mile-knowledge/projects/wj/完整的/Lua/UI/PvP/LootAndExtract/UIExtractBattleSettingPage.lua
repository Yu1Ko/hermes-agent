-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIExtractBattleSettingPage
-- Date: 2025-06-23 14:14:55
-- Desc: ?
-- ---------------------------------------------------------------------------------
local LEFT = 1
local RIGHT = 2
local EQUIP = 3
local LOOT_COLOR_MENU = {
    "蓝色及以上",   -- 3
    "紫色及以上",
    "橙色及以上",
}

local DROP_COLOR_MENU = {
    "不丢弃",
    "白色",      -- 1
    "绿色及以下", -- 2
    "蓝色及以下",
    "紫色及以下",
}

local UIExtractBattleSettingPage = class("UIExtractBattleSettingPage")

function UIExtractBattleSettingPage:OnEnter(nType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nType = nType
    self:UpdateInfo()
end

function UIExtractBattleSettingPage:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIExtractBattleSettingPage:BindUIEvent()
    UIHelper.SetToggleGroupAllowedNoSelection(self.ToggleGroupAction, true)
end

function UIExtractBattleSettingPage:RegEvent()
    Event.Reg(self, EventType.OnUpdateTreasureBattleFieldSkill, function ()
        self:UpdateSkillInfo()
    end)
end

function UIExtractBattleSettingPage:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIExtractBattleSettingPage:UpdateInfo()
    self:UpdateSkillInfo()
    self:UpdateSettingInfo()
end

function UIExtractBattleSettingPage:UpdateSkillInfo()
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupAction)
    for nIndex, widget in ipairs(self.tbSkillWidget) do
        local script = UIHelper.GetBindScript(widget)
        local tbSkill = TreasureBattleFieldSkillData.GetDynamicSkill(nIndex)
        script:OnEnter(nIndex, tbSkill)

        local scriptSkill = script:GetSkillIconScript()
        if scriptSkill then
            scriptSkill:SetToggleGroup(self.ToggleGroupAction)
            scriptSkill:BindSelectFunction(function()
                local scriptDrag = UIHelper.GetBindScript(self.WidgetDrag)
                local scriptItemTips = scriptDrag:OpenSkillTip(LEFT)
                scriptItemTips:InitDisplayOnly(tbSkill.nSkillID)
            end)
        end
    end
end

function UIExtractBattleSettingPage:UpdateSettingInfo()
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
    lootScript:OnEnter(tLootConf, false)

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
    local dropScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSetContent, self.ScorllViewSetContent)
    dropScript:OnEnter(tDropConf, false)

    local tXunbaoItemConf = {}
    tXunbaoItemConf.szName = "奇境宝钞道具快捷丢弃设置"
    for i = 1, #DROP_COLOR_MENU do
        local szName = DROP_COLOR_MENU[i]
        local nColor = i
        local bChecked = TreasureBattleFieldData.nXunbaoItemColor == nColor
        local fnAction = function (bSelected)
            if bSelected then
                TreasureBattleFieldData.nXunbaoItemColor = nColor
            end
        end
        table.insert(tXunbaoItemConf, { szName = szName, bChecked = bChecked, fnAction = fnAction, bToggleGroup = true })
    end
    local scriptXunBao = UIHelper.AddPrefab(PREFAB_ID.WidgetSetContent, self.ScorllViewSetContent)
    scriptXunBao:OnEnter(tXunbaoItemConf, false)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScorllViewSetContent)
end


return UIExtractBattleSettingPage