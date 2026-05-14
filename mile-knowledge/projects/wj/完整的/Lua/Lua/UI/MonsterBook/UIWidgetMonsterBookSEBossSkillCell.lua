local UIWidgetMonsterBookSEBossSkillCell = class("UIWidgetMonsterBookSEBossSkillCell")

function UIWidgetMonsterBookSEBossSkillCell:OnEnter(dwSkillID, nLevel)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(dwSkillID, nLevel)
end

function UIWidgetMonsterBookSEBossSkillCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonsterBookSEBossSkillCell:BindUIEvent()
    UIHelper.SetSwallowTouches(self.BtnCell, false)
    UIHelper.BindUIEvent(self.BtnCell, EventType.OnClick, function ()
        local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelBaizhanMain)
        if scriptView then
            scriptView.scriptSkillView:RedirectSkill(self.dwSkillID)
        end
        UIMgr.Close(VIEW_ID.PanelJingShenNaiLiDetailPop)
    end)
end

function UIWidgetMonsterBookSEBossSkillCell:RegEvent()

end

function UIWidgetMonsterBookSEBossSkillCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMonsterBookSEBossSkillCell:UpdateInfo(dwSkillID, nLevel)
    self.dwSkillID = dwSkillID
    self.nLevel = nLevel
    self.bCollected = self.nLevel and self.nLevel > 0
    local nLevel = self.nLevel
    if not self.bCollected then
        self.nLevel = 1
    end
    local tSkill = GetSkill(self.dwSkillID, self.nLevel) or {bIsPassiveSkill = false}
    self.tSkillInfo = Table_GetMonsterSkillInfo(self.dwSkillID)
    local bEmptySkill = MonsterBookData.IsEmptySkill(self.dwSkillID, self.tSkillInfo)
    if not bEmptySkill then
        local szLevel = MonsterBookData.GetLevelText(self.nLevel)
        if nLevel == 0 then
            szLevel = ""
        end
        local dwOutSkillID = MonsterBookData.tIn2OutSkillMap[self.dwSkillID] or self.dwSkillID
        local szImagePath = TabHelper.GetSkillIconPathByIDAndLevel(dwOutSkillID, self.nLevel)
        local szFramePath = MonsterBookData.GetEdgeFramePath(self.tSkillInfo.nColor)
        local szSkillName = Table_GetSkillName(dwSkillID, nLevel)
        szSkillName = UIHelper.GBKToUTF8(szSkillName)
        self.szSkillName = szSkillName
        UIHelper.SetString(self.LabelLevel, szLevel)
        UIHelper.SetString(self.LabelName, szSkillName)
        UIHelper.SetTexture(self.ImgItemIcon, szImagePath)
        if szFramePath then
            UIHelper.SetSpriteFrame(self.ImgColorFrame, szFramePath)
        end        
        UIHelper.SetVisible(self.ImgColorFrame, szFramePath ~= nil)
        UIHelper.SetVisible(self.ImgPassiveFrame, tSkill.bIsPassiveSkill)
        for nIndex, ImgCostPoint in ipairs(self.ImgCostPointList) do
            UIHelper.SetVisible(ImgCostPoint, nIndex <= self.tSkillInfo.nCost)
        end
        -- UIHelper.LayoutDoLayout(self.LayoutCost)
    end
    
    UIHelper.SetVisible(self.LabelLevel, not bEmptySkill)
    UIHelper.SetVisible(self.LabelName, not bEmptySkill)
    UIHelper.SetNodeGray(self.ImgItemIcon, not self.bCollected, true)
    UIHelper.SetVisible(self.LabelGotten, self.bCollected)
    Timer.AddFrame(self, 1, function ()
        UIHelper.UpdateMask(self.MaskItem)
        -- UIHelper.UpdateMask(self.MaskSkill1)
        -- UIHelper.UpdateMask(self.MaskSkill2)        
    end)
end

return UIWidgetMonsterBookSEBossSkillCell