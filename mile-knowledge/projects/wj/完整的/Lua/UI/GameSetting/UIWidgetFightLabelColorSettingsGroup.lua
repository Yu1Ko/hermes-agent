-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetFightLabelColorSettingsGroup
-- Date: 2024-08-08 11:11:45
-- Desc: ?
-- ---------------------------------------------------------------------------------
local fnCompareColor = function(tCol1, tCol2)
    if tCol1 and tCol2 then
        return tCol1.r == tCol2.r and tCol1.b == tCol2.b and tCol1.g == tCol2.g
    end
    return false
end

local tColors = {
    cc.c3b(0xff, 0xff, 0xff), cc.c3b(0xff, 0x7c, 0x85),
    cc.c3b(0xff, 0xff, 0x00), cc.c3b(0x34, 0xf3, 0xff),
    cc.c3b(0x80, 0xff, 0x80), cc.c3b(0x2a, 0xff, 0x2a)
}

local DAMAGE_TYPE2NAME = {
    [SKILL_RESULT_TYPE.PHYSICS_DAMAGE] = "外功攻击",
    [SKILL_RESULT_TYPE.SOLAR_MAGIC_DAMAGE] = "阳性攻击",
    [SKILL_RESULT_TYPE.NEUTRAL_MAGIC_DAMAGE] = "混元攻击",
    [SKILL_RESULT_TYPE.LUNAR_MAGIC_DAMAGE] = "阴性攻击",
    [SKILL_RESULT_TYPE.POISON_DAMAGE] = "毒性攻击",

    [SKILL_RESULT_TYPE.THERAPY] = "有效治疗",
    [SKILL_RESULT_TYPE.REFLECTIED_DAMAGE] = "反弹伤害",
    [SKILL_RESULT_TYPE.STEAL_LIFE] = "偷取气血",
    [SKILL_RESULT_TYPE.PARRY_DAMAGE] = "伤害化解",
    [SKILL_RESULT_TYPE.ABSORB_THERAPY] = "伤害吸收",
    ['DEFAULT'] = "默认",
}

local UIWidgetFightLabelColorSettingsGroup = class("UIWidgetFightLabelColorSettingsGroup")

function UIWidgetFightLabelColorSettingsGroup:OnEnter()

end

function UIWidgetFightLabelColorSettingsGroup:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetFightLabelColorSettingsGroup:BindUIEvent()

end

function UIWidgetFightLabelColorSettingsGroup:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetFightLabelColorSettingsGroup:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetFightLabelColorSettingsGroup:Init(nDamageType, tTempColor)
    self:BindUIEvent()

    if self.bSelected == nil then
        self.bSelected = false
    end

    self.nDamageType = nDamageType
    self.tTempColor = tTempColor

    self:UpdateInfo()
end

function UIWidgetFightLabelColorSettingsGroup:UpdateInfo()
    local tTempColor = self.tTempColor
    local nDamageType = self.nDamageType
    
    local tCurrentColor = tTempColor[nDamageType] or tTempColor.DEFAULT
    UIHelper.SetString(self.LabelTitle, DAMAGE_TYPE2NAME[nDamageType])
    UIHelper.SetColor(self.ImgColor, tCurrentColor)

    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroup)
    UIHelper.RemoveAllChildren(self.LayoutColorList)
    for nIndex, tColor in ipairs(tColors) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBulidFaceItem_80, self.LayoutColorList)
        script:InitFontColor(tColor, self.ToggleGroup, function()
            tTempColor[nDamageType] = tColor
            UIHelper.SetColor(self.ImgColor, tColor)
        end)

        if fnCompareColor(tCurrentColor, tColor) then
            UIHelper.SetToggleGroupSelected(self.ToggleGroup, nIndex - 1)
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutColorList)
end

function UIWidgetFightLabelColorSettingsGroup:BindScrollViewRefresh(fnFunc)
    if IsFunction(fnFunc) then
        self.fnRefreshScrollView = fnFunc

        UIHelper.BindUIEvent(self.BtnColor, EventType.OnClick, function()
            self.bSelected = not self.bSelected

            UIHelper.SetVisible(self.WidgetSelected, self.bSelected)
            UIHelper.SetVisible(self.LayoutColorList, self.bSelected)
            UIHelper.SetVisible(self.WidgetClose, not self.bSelected)

            UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
            fnFunc()
        end)
    end
end

return UIWidgetFightLabelColorSettingsGroup