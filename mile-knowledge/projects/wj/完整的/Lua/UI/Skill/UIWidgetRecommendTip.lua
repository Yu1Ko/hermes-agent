-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetMiJiBtn
-- Date: 2022-11-14 19:57:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIWidgetRecommendTip
local UIWidgetRecommendTip = class("UIWidgetRecommendTip")

function UIWidgetRecommendTip:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetRecommendTip:OnExit()
    self.bInit = false
    Event.UnRegAll(self)
end

function UIWidgetRecommendTip:BindUIEvent()
end

function UIWidgetRecommendTip:RegEvent()

end

function UIWidgetRecommendTip:Init(tData, tQiXueList, nCurrentKungFuID, nCurrentSetID, bIsPVP, fnApplied, bDisplayOnly)
    self.tData = tData
    self.tQiXueList = tQiXueList
    self.nCurrentKungFuID = nCurrentKungFuID
    self.nCurrentSetID = nCurrentSetID
    self.bDisplayOnly = bDisplayOnly

    local szConfigName = bIsPVP and "竞技武学" or "秘境武学"
    self:UpdateQixue()
    self:UpdateSkill()

    UIHelper.BindUIEvent(self.BtnEquip, EventType.OnClick, function()
        RedpointHelper.PanelSkill_OnClickApplyRecommend(bIsPVP)
        UIHelper.ShowConfirm(string.format("是否要应用%s配置？", szConfigName), fnApplied)
    end)

    if not bDisplayOnly then
        local bActivated = SkillData.IsRecommendActivated(nCurrentKungFuID, nCurrentSetID, tData)
        UIHelper.SetVisible(self.ImgEquipMark, bActivated)
        UIHelper.SetVisible(self.BtnEquip, not bActivated)
    end
end

function UIWidgetRecommendTip:UpdateQixue()
    for nIndex, tQixue in ipairs(self.tQiXueList) do
        local nPrefabID = nIndex ~= 4 and PREFAB_ID.WidgetSkillPassiveCell or PREFAB_ID.WidgetSkillCell1
        local tSkillArray = tQixue.SkillArray

        for i = 1, 2 do
            if table.contain_value(self.tData.QiXue, tSkillArray[i].dwSkillID) then
                local script = UIHelper.AddPrefab(nPrefabID, self.LayoutQiXue, tSkillArray[i].dwSkillID)
                script:BindSelectFunction(function()
                    local fnClose = function()
                        script:SetSelected(false)
                    end

                    local tip, tipsScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetAcupointTip, script._rootNode, TipsLayoutDir.RIGHT_CENTER)
                    local pw, ph = UIHelper.GetContentSize(tipsScript._rootNode)
                    tip:SetSize(pw + 50, ph + 200)
                    tip:Update()

                    tipsScript:Init(tSkillArray[i], false, nil, fnClose)
                    tipsScript:HideButton()
                end)
            end
        end
    end
end

local function GetMijiIndex(nSkillID, tTargetMijiIDList)
    local tList = SkillData.GetFinalRecipeList(nSkillID)
    for nIndex, tRecipe in ipairs(tList) do
        if table.contain_value(tTargetMijiIDList, tRecipe.recipe_id) then
            return nIndex
        end
    end
end

function UIWidgetRecommendTip:UpdateSkill()
    for nIndex, nSkillID in ipairs(self.tData.Skill) do
        local tParent = nIndex == 1 and self.WidgetSkillCell or self.LayoutSkill
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, tParent, nSkillID)
        script:BindSelectFunction(function()
            local nFakeIndex = GetMijiIndex(nSkillID, self.tData.Miji)
            local tips, tipsScriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSkillInfoTips, script._rootNode, TipsLayoutDir.RIGHT_CENTER)
            tipsScriptView:InitDisplayOnly(nSkillID, self.nCurrentKungFuID, nFakeIndex)

            tipsScriptView:SetBtnVisible(false)
            tipsScriptView:BindExitFunc(function()
                script:SetSelected(false)
            end)
        end)
    end
end

function UIWidgetRecommendTip:HideButton()
    self.bHideButton = true
    UIHelper.SetVisible(self.WiddgetAnchorBtn, false)
end

return UIWidgetRecommendTip
