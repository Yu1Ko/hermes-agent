-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetAcupointTip
-- Date: 2022-11-14 19:57:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIWidgetMijiTips
local UIWidgetMijiTips = class("UIWidgetMijiTips")

function UIWidgetMijiTips:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        UIHelper.SetTouchDownHideTips(self.BtnEquip, false)
        UIHelper.SetTouchDownHideTips(self.ScrollViewSkillDetailsList, false)

        UIHelper.SetSwallowTouches(self.ScrollViewSkillDetailsList, false)
    end
end

function UIWidgetMijiTips:OnExit()
    self.bInit = false
    Event.UnRegAll(self)
end

function UIWidgetMijiTips:BindUIEvent()
end

function UIWidgetMijiTips:RegEvent()

end

function UIWidgetMijiTips:UpdateInfo(tRecipe, fnCallback)
    if tRecipe then
        self:UpdateBasicInfo(tRecipe)

        if fnCallback and self.BtnEquip and self.LabelEquip then
            local szLabel = tRecipe.active and "卸下" or "装备"
            UIHelper.SetString(self.LabelEquip, szLabel)

            UIHelper.BindUIEvent(self.BtnEquip, EventType.OnClick, function()
                if not ArenaData.IsCanChangeSkillRecipe() then
                    TipsHelper.ShowImportantRedTip("比赛即将开始或正在进行中，无法切换招式奇穴")
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetMijiTips)
                    return
                end
                fnCallback()
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetMijiTips)
            end)
        end
    end
end

function UIWidgetMijiTips:UpdateBasicInfo(tRecipe)
    local tSkillRecipe = Table_GetSkillRecipe(tRecipe.recipe_id, tRecipe.recipe_level)
    local szIconPath = UIHelper.GetIconPathByIconID(tSkillRecipe.nIconID)
    if not string.is_nil(szIconPath) then
        UIHelper.SetTexture(self.ImgSkillIcon, szIconPath)
        Timer.Add(self, 0.01, function()
            UIHelper.UpdateMask(self.MaskSkill)
        end)
    end

    local szDesc = UIHelper.GBKToUTF8(tSkillRecipe.szDesc)
    szDesc = SkillData.ProcessSkillPlaceholder(szDesc)
    szDesc = SkillData.FormSpecialNoun(szDesc)

    UIHelper.SetString(self.LabelSkillName, UIHelper.GBKToUTF8(tSkillRecipe.szName))
    UIHelper.AddPrefab(PREFAB_ID.WidgetListDescribeCell, self.ScrollViewSkillDetailsList, szDesc, nil, false)

    --if UIHelper.GetVisible(self._rootNode) then
    --    UIHelper.PlayAni(self, self.AniTip, "AniTip")
    --end

    local szLabel = tRecipe.active and "卸下" or "装备"
    local bSelected = tRecipe.active or false
    UIHelper.SetString(self.LabelEquip, szLabel)
    UIHelper.SetVisible(self.ImgSelectFrame, bSelected)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSkillDetailsList)
end

function UIWidgetMijiTips:GetToggle()
    return self.TogConfiguration
end

function UIWidgetMijiTips:PlayAnim()
    if not self.bPlayAni then
        self.bPlayAni = true
        UIHelper.SetOpacity(self.AniTip, 0) --设置初始状态，防止闪
        Timer.Add(self, 0.05, function()
            UIHelper.PlayAni(self, self.AniTip, "AniItemTip", function()
                self.bPlayAni = false
            end)
        end)
    end
end

function UIWidgetMijiTips:BindClickCallback(fnCallback)
    if fnCallback then
        UIHelper.BindUIEvent(self.TogConfiguration, EventType.OnClick, fnCallback)
    end
end

return UIWidgetMijiTips
