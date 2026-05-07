local UIWidgetMonsterBookSkillSaveSchemeCell = class("UIWidgetMonsterBookSkillSaveSchemeCell")

function UIWidgetMonsterBookSkillSaveSchemeCell:OnEnter(nSchemeID, tSkillList, fCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nSchemeID = nSchemeID
    self.tSkillList = tSkillList
    self.fCallBack = fCallBack
    self:UpdateInfo()
end

function UIWidgetMonsterBookSkillSaveSchemeCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonsterBookSkillSaveSchemeCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected and self.fCallBack then self.fCallBack() end
    end)
end

function UIWidgetMonsterBookSkillSaveSchemeCell:RegEvent()

end

function UIWidgetMonsterBookSkillSaveSchemeCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMonsterBookSkillSaveSchemeCell:UpdateInfo()
    local szName = Storage.MonsterBook.tSkillPresetName[self.nSchemeID]
    local szText = string.format("覆盖【%s】", szName)

    UIHelper.SetString(self.LabelApply, szText)
    UIHelper.SetString(self.LabelApplySelect, szText)

    UIHelper.RemoveAllChildren(self.LayoutBZSkills)

    local tSkillCollected = g_pClientPlayer.GetAllSkillInCollection()
    local nTotalCost = 0
    for _, dwSkillID in ipairs(self.tSkillList) do
        local scriptSkill = UIHelper.AddPrefab(PREFAB_ID.WidgetBZSkillPlayerItem, self.LayoutBZSkills)
        if dwSkillID > 0 then
            local nLevel = tSkillCollected[dwSkillID]            
            scriptSkill:OnEnter(dwSkillID, nLevel)
            
            local tSkillInfo = Table_GetMonsterSkillInfo(dwSkillID) or {}
            nTotalCost = nTotalCost + (tSkillInfo.nCost or 0)            
        else
            scriptSkill:OnEnter()
        end
        scriptSkill:SetSkillNameEnable(true)
    end

    UIHelper.LayoutDoLayout(self.LayoutBZSkills)

    for nIndex, imgPoint in ipairs(self.tbImgLightPoints) do
        UIHelper.SetVisible(imgPoint, nIndex <= nTotalCost)
    end
end

return UIWidgetMonsterBookSkillSaveSchemeCell