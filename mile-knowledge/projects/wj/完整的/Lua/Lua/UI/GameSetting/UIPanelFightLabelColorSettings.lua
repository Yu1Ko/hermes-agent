-- ---------------------------------------------------------------------------------
-- Author: jiayuran
-- Name: UIPanelFightLabelColorSettings
-- Date: 2024-08-28 19:51:18
-- Desc: UIPanelFightLabelColorSettings
-- ---------------------------------------------------------------------------------
local fnCompareColor = function(tCol1, tCol2)
    if tCol1 and tCol2 then
        return tCol1.r == tCol2.r and tCol1.b == tCol2.b and tCol1.g == tCol2.g
    end
    return false
end

local tFightInfoClass = {
    {
        szTitle = "攻击",
        tDamageTypes = {
            SKILL_RESULT_TYPE.PHYSICS_DAMAGE,
            SKILL_RESULT_TYPE.SOLAR_MAGIC_DAMAGE,
            SKILL_RESULT_TYPE.NEUTRAL_MAGIC_DAMAGE,
            SKILL_RESULT_TYPE.LUNAR_MAGIC_DAMAGE,
            SKILL_RESULT_TYPE.POISON_DAMAGE,
        }
    },
    {
        szTitle = "防御与治疗",
        tDamageTypes = {
            SKILL_RESULT_TYPE.THERAPY,
            SKILL_RESULT_TYPE.STEAL_LIFE,
            SKILL_RESULT_TYPE.REFLECTIED_DAMAGE,
            --SKILL_RESULT_TYPE.ABSORB_DAMAGE,
            SKILL_RESULT_TYPE.PARRY_DAMAGE,
            SKILL_RESULT_TYPE.ABSORB_THERAPY
        }
    }
}

local UIPanelFightLabelColorSettings = class("UIPanelFightLabelColorSettings")

function UIPanelFightLabelColorSettings:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tTempColor = clone(Storage.BattleFontColor.Active)
    self:InitNavigation()
end

function UIPanelFightLabelColorSettings:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelFightLabelColorSettings:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        local bChanged = false
        for szKey, nVal in pairs(self.tTempColor) do
            if not fnCompareColor(Storage.BattleFontColor.Active[szKey], nVal) then
                bChanged = true
                break
            end
        end

        if bChanged then
            UIHelper.ShowConfirm("当前效果发生修改，是否保存并退出?", function()
                self:Save()
                UIMgr.Close(self)
            end, function()
                UIMgr.Close(self)
            end)
        else
            UIMgr.Close(self)
        end
    end)

    UIHelper.BindUIEvent(self.BtnRecover, EventType.OnClick, function()
        self:Reset()
    end)

    UIHelper.BindUIEvent(self.BtnSave, EventType.OnClick, function()
        self:Save()
        UIMgr.Close(self)
    end)
end

function UIPanelFightLabelColorSettings:RegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelFightLabelColorSettings:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelFightLabelColorSettings:InitNavigation()
    UIHelper.RemoveAllChildren(self.ScrollViewLeftList)

    for nIndex, tInfo in ipairs(tFightInfoClass) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetChatSettingToggle, self.ScrollViewLeftList)
        script:OnEnter(nil, tInfo.szTitle, nIndex == 1, nil, function()
            self:UpdateInfo(tInfo)
        end)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewLeftList)
end

function UIPanelFightLabelColorSettings:UpdateInfo(tInfo)
    UIHelper.RemoveAllChildren(self.ScrollViewContent)
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroup)

    self.scrips = {}
    for nIndex, nDamageType in ipairs(tInfo.tDamageTypes) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetFightLabelColorSettingsGroup, self.ScrollViewContent)
        script:Init(nDamageType, self.tTempColor)
        script:BindScrollViewRefresh(function()
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
            UIHelper.ScrollToIndex(self.ScrollViewContent, nIndex - 1)
        end)
        table.insert(self.scrips, script)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
end

function UIPanelFightLabelColorSettings:Save()
    for szKey, nVal in pairs(self.tTempColor) do
        Storage.BattleFontColor.Active[szKey] = nVal
    end
    Storage.BattleFontColor.Flush()
end

function UIPanelFightLabelColorSettings:Reset()
    for szKey, nVal in pairs(DAMAGE_TYPE_COLOR_ACTIVE) do
        self.tTempColor[szKey] = nVal
    end
    for nIndex, script in ipairs(self.scrips) do
        script:UpdateInfo()
    end
end


return UIPanelFightLabelColorSettings