local UIMonsterBookSkillTip = class("UIMonsterBookSkillTip")

function UIMonsterBookSkillTip:OnEnter(dwSkillID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(dwSkillID)
end

function UIMonsterBookSkillTip:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMonsterBookSkillTip:BindUIEvent()

end

function UIMonsterBookSkillTip:RegEvent()

end

function UIMonsterBookSkillTip:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIMonsterBookSkillTip:UpdateInfo(dwSkillID)
    local player = GetClientPlayer()
    if not player then
        return player
    end
    
    if not dwSkillID then
        return
    end

    self.dwSkillID = dwSkillID

    local tSkillCollected = player.GetAllSkillInCollection() or {}

    local tSkillInfo = Table_GetMonsterSkillInfo(self.dwSkillID)
    local nLevel = tSkillCollected[self.dwSkillID] or 0
    local nOriginLevel = nLevel
    if nLevel == 0 then
        nLevel = 1
    end
    local tSkill = Table_GetSkill(self.dwSkillID, nLevel) or {}
    local szSkillName = UIHelper.GBKToUTF8(tSkillInfo.szSkillName)
    local szBossName = UIHelper.GBKToUTF8(tSkillInfo.szBossName)
    szBossName = "首领："..szBossName
    local szColorPath, szColorName = MonsterBookData.GetEdgeColorPath(tSkillInfo.nColor)
    local szActive = "未激活"
    local bActive = MonsterBookData.IsActiveSkill(self.dwSkillID)
    if bActive then
        szActive = "已激活"
    end

    UIHelper.SetString(self.LabelSkillName, szSkillName)
    UIHelper.SetString(self.LabelColor, szColorName or "")
    UIHelper.SetString(self.LabelSkillStatus, szActive)
    if szColorPath then
        UIHelper.SetSpriteFrame(self.ImgColorBar, szColorPath)
    end
    UIHelper.SetVisible(self.ImgColorBar, szColorPath ~= nil)

    UIHelper.RemoveAllChildren(self.LayoutSkillInfo)
    -- 类型描述
    local tRecipeKey = player.GetSkillRecipeKey(self.dwSkillID, nLevel)
    UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContentBaiZhanTop, self.ScrollViewSkillInfo, tRecipeKey)
    if szBossName then
        local scriptBossName = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent2, self.ScrollViewSkillInfo)
        scriptBossName:OnEnter({szBossName})
    end
    -- 技能描述
    local szDesc = Table_GetSkillSpecialDesc(self.dwSkillID, nLevel)
    szDesc = UIHelper.GBKToUTF8(szDesc)    
    if szDesc and szDesc ~= "" then
        szDesc = string.format("<color=#AED9E0>%s</c>", szDesc)
        local scriptDesc = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent2, self.ScrollViewSkillInfo)
        scriptDesc:OnEnter({szDesc})
    end

    szDesc = GetSkillDesc(self.dwSkillID, nLevel)
    szDesc = UIHelper.GBKToUTF8(szDesc)    
    if szDesc and szDesc ~= "" then
        szDesc = ParseTextHelper.DevideFormatText(szDesc, "<color=#AED9E0>%s</c>")
        -- szDesc = string.format("<color=#AED9E0>%s</c>", szDesc)
        local scriptDesc = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent2, self.ScrollViewSkillInfo)
        scriptDesc:OnEnter({szDesc})
    end

    szDesc = UIHelper.GBKToUTF8(tSkill.szHelpDesc)
    if szDesc and szDesc ~= "" then
        szDesc = string.format("<color=#AED9E0>%s</c>", szDesc)
        local scriptDesc = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent2, self.ScrollViewSkillInfo)
        scriptDesc:OnEnter({szDesc})
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSkillInfo)
    UIHelper.SetTouchDownHideTips(self.ScrollViewSkillInfo, false)
end

return UIMonsterBookSkillTip