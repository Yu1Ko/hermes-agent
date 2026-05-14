local UIWidgetMonsterBookSkillSchemeCell = class("UIWidgetMonsterBookSkillSaveSchemeCell")

function UIWidgetMonsterBookSkillSchemeCell:OnEnter(nSchemeID, tSkillList, fCallBack)
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

function UIWidgetMonsterBookSkillSchemeCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonsterBookSkillSchemeCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function ()
        local szName = Storage.MonsterBook.tSkillPresetName[self.nSchemeID]
        UIHelper.ShowConfirm(string.format("确定删除预设【%s】？", szName), function ()
            RemoteCallToServer("On_MonsterBook_DeletePreset", self.nSchemeID)

            for nIndex = self.nSchemeID, #Storage.MonsterBook.tSkillPresetName - 1 do
                Storage.MonsterBook.tSkillPresetName[nIndex] = Storage.MonsterBook.tSkillPresetName[nIndex + 1]
            end
        end)
    end)

    UIHelper.BindUIEvent(self.BtnRename, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelBZModifySchemeNamePop, self.nSchemeID, true)
    end)

    UIHelper.BindUIEvent(self.BtnApply, EventType.OnClick, function ()
        if self.fCallBack then self.fCallBack() end
    end)
end

function UIWidgetMonsterBookSkillSchemeCell:RegEvent()
    Event.Reg(self, EventType.OnMonsterBookSchemeNameChange, function ()
        self:RefreshLabels()
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        UIHelper.LayoutDoLayout(self.LayoutTitle)
    end)
end

function UIWidgetMonsterBookSkillSchemeCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMonsterBookSkillSchemeCell:UpdateInfo()
    self:RefreshLabels()

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

function UIWidgetMonsterBookSkillSchemeCell:RefreshLabels()
    local szName = Storage.MonsterBook.tSkillPresetName[self.nSchemeID]

    UIHelper.SetString(self.LabelTitle, szName)
    UIHelper.LayoutDoLayout(self.LayoutTitle)
end

return UIWidgetMonsterBookSkillSchemeCell