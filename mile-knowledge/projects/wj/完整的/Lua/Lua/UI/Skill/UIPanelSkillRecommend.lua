-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetAcupointTip
-- Date: 2022-11-14 19:57:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIPanelSkillRecommend
local UIPanelSkillRecommend = class("UIPanelSkillRecommend")

function UIPanelSkillRecommend:OnEnter(nCurrentKungFuID, nCurrentSetID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if nCurrentKungFuID then
        self.nCurrentKungFuID = nCurrentKungFuID or g_pClientPlayer.GetActualKungfuMount().dwSkillID
        self.nCurrentSetID = nCurrentSetID or g_pClientPlayer.GetTalentCurrentSet(g_pClientPlayer.dwForceID, self.nCurrentKungFuID)
        self.tRecommendTips = { UIHelper.GetBindScript(self.WidgetSkillRecommend1), UIHelper.GetBindScript(self.WidgetSkillRecommend2) }

        self.tRecommendData = UISkillRecommendTab[self.nCurrentKungFuID]

        self.bStartApply = false
        self.bDisplayOnly = false
        self.nAppliedQixueIndex = 0

        if self.tRecommendData then
            self:UpdateInfo()
        else
            if not self.tRecommendData then
                TipsHelper.ShowImportantRedTip("当前心法还没有配UISkillRecommendTab")
            else
                TipsHelper.ShowImportantRedTip("秘籍或奇穴应该配置对应的下标，数值值的范围为1~2")
            end
        end
    end
end

function UIPanelSkillRecommend:InitDisplayOnly(nCurrentKungFuID, tQiXueList)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nCurrentKungFuID = nCurrentKungFuID
    self.tRecommendTips = { UIHelper.GetBindScript(self.WidgetSkillRecommend1), UIHelper.GetBindScript(self.WidgetSkillRecommend2) }
    self.tRecommendData = UISkillRecommendTab[self.nCurrentKungFuID]
    self.bStartApply = false
    self.bDisplayOnly = true
    self.tQiXueList = tQiXueList

    for _, script in ipairs(self.tRecommendTips) do
        script:HideButton()
    end

    if self.tRecommendData then
        self:UpdateInfo()
    else
        if not self.tRecommendData then
            TipsHelper.ShowImportantRedTip("当前心法还没有配UISkillRecommendTab")
        else
            TipsHelper.ShowImportantRedTip("秘籍或奇穴应该配置对应的下标，数值值的范围为1~2")
        end
    end
end

function UIPanelSkillRecommend:OnExit()
    self.bInit = false
    Event.UnRegAll(self)
end

function UIPanelSkillRecommend:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPanelSkillRecommend:RegEvent()
    Event.Reg(self, "ON_UPDATE_TALENT", function()
        if self.bStartApply then
            self:ApplyRecommend()
        end
    end)

    Event.Reg(self, "SKILL_RECIPE_LIST_UPDATE", function(arg0, arg1, arg2)
        if self.bStartApply then
            self:ApplyRecommend()
        end
    end)
end

function UIPanelSkillRecommend:UpdateInfo()
    self.tList = self.bDisplayOnly and self.tQiXueList
            or SkillData.GetQixueList(true, self.nCurrentKungFuID, self.nCurrentSetID)

    self.tRecommendTips[1]:Init(self.tRecommendData.PVE, self.tList, self.nCurrentKungFuID, self.nCurrentSetID, false, function()
        self:StartApplyRecommend(self.tRecommendData.PVE)
    end, self.bDisplayOnly)
    self.tRecommendTips[2]:Init(self.tRecommendData.PVP, self.tList, self.nCurrentKungFuID, self.nCurrentSetID, true, function()
        self:StartApplyRecommend(self.tRecommendData.PVP)
    end, self.bDisplayOnly)
end

function UIPanelSkillRecommend:StartApplyRecommend(tData)
    if not QTEMgr.CanCastSkill() then
        TipsHelper.ShowNormalTip("动态技能状态下，无法进行该操作")
        return 
    end
    if self.bDisplayOnly then
        return
    end

    if  g_pClientPlayer and g_pClientPlayer.bOnHorse then
        RideHorse()  -- 若在马上则帮他下马
    end

    local tParam = {
        szType = "Normal",
        szFormat = "应用配置",
        bNotShowDescribe = true,
        szIconPath = "UIAtlas2_MainCity_SystemMenu_IconSysteam15.png",
        nDuration = 64 / GLOBAL.GAME_FPS,
        nSize = 128,
        bShowCancel = false
    }
    UIMgr.Open(VIEW_ID.PanelSystemPrograssBar, tParam)

    Timer.Add(self,0.3,function()
        self.nAppliedQixueIndex = 0
        self.nAppliedMijiIndex = 0
        self.tSelectedData = tData
        self.bStartApply = true
        self:ApplyRecommend()
    end)
end

function UIPanelSkillRecommend:ApplyRecommend()
    if not g_pClientPlayer then
        return
    end

    local tData = self.tSelectedData

    -----------------------Qixue---------------------------
    for nIndex = 1, 4 do
        if nIndex > self.nAppliedQixueIndex then
            self.nAppliedQixueIndex = self.nAppliedQixueIndex + 1

            local nSelectIndex = self.tList[nIndex].nSelectIndex
            local dwPointID = self.tList[nIndex].dwPointID
            local SkillArray = self.tList[nIndex].SkillArray

            for nSubIndex = 1, 2 do
                if table.contain_value(tData.QiXue, SkillArray[nSubIndex].dwSkillID) then
                    if nSelectIndex ~= nSubIndex then
                        SkillData.ChangeQiXue(dwPointID, nSubIndex, self.nCurrentKungFuID, self.nCurrentSetID)
                        return
                    end
                end
            end
        end
    end

    ---------------------------Miji---------------------------
    for i = 1, 5 do
        local nSkillID = tData.Skill[i]
        local tRecipe = SkillData.GetTargetMijiInfo(nSkillID, tData.Miji)
        if tRecipe then
            self:ActiveMiJi(tRecipe)
        else
            LOG.WARN("兄弟tm这个 %d 技能没配好秘籍", nSkillID)
        end
    end

    -------------------------Skill---------------------------
    local tSlotToNewSkillID = {}
    for nSlotIndex, nSkillID in ipairs(tData.Skill) do
        tSlotToNewSkillID[nSlotIndex] = nSkillID
    end

    -------------------------AutoSkill---------------------------
    local tAutoSkillList = tData.AutoSkills
    if tAutoSkillList then
        local nKungFuID = g_pClientPlayer.GetActualKungfuMount().dwSkillID
        local nSetID = g_pClientPlayer.GetTalentCurrentSet(g_pClientPlayer.dwForceID, nKungFuID)
        local bHasSkill = false
        for i = 1, AutoBattle.nMaxCustomizeNum do
            local nSkillID = tAutoSkillList[i]
            if nSkillID then
                bHasSkill = true
                AutoBattle.SaveCustomizeSkill(i, nSkillID, nKungFuID, nSetID)
            else
                AutoBattle.ClearCustomizeSkill(i, nKungFuID, nSetID)
            end
        end
        AutoBattle.SetCustomized(bHasSkill, nKungFuID)
    end

    Timer.Add(self, 0.2, function()
        SkillData.ChangeSkill(tSlotToNewSkillID, self.nCurrentKungFuID, self.nCurrentSetID)
        UIMgr.Close(self)
    end)

    --Event.Dispatch(EventType.OnUpdateSkillPanel)
end

function UIPanelSkillRecommend:ActiveMiJi(tRecipe)
    if not tRecipe.active then
        local nRetCode = g_pClientPlayer.ActiveSkillRecipe(tRecipe.recipe_id, tRecipe.recipe_level)
        if nRetCode ~= SKILL_RECIPE_RESULT_CODE.SUCCESS then
            if nRetCode == SKILL_RECIPE_RESULT_CODE.ERROR_IN_FIGHT then
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.SKILL_RECIPE_ERROR_INFIGHT_ON)
            else
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.SKILL_RECIPE_ERROR_UNKNOWN_ON)
            end
        else
            return true
        end
    end
    return false
end

function UIPanelSkillRecommend:PopPveApplyTip()
    RedpointHelper.PanelSkill_OnClickApplyRecommend()
    UIHelper.ShowConfirm(string.format("是否要应用%s配置？", "秘境推荐"), function()
        self:StartApplyRecommend(self.tRecommendData.PVE)
    end)
end

return UIPanelSkillRecommend
