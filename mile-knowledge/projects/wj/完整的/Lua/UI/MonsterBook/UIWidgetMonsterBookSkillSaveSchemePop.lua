local UIWidgetMonsterBookSkillSaveSchemePop = class("UIWidgetMonsterBookSkillSaveSchemePop")

function UIWidgetMonsterBookSkillSaveSchemePop:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIWidgetMonsterBookSkillSaveSchemePop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonsterBookSkillSaveSchemePop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnComfirm, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelBZModifySchemeNamePop, self.nCurSchemeID)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.ToggleNewScheme, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then self.nCurSchemeID = nil end
    end)
end

function UIWidgetMonsterBookSkillSaveSchemePop:RegEvent()
    Event.Reg(self, "REMOTE_MONSTERSKILLPRESET_EVENT", function ()
        --self:UpdateInfo()
    end)
end

function UIWidgetMonsterBookSkillSaveSchemePop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMonsterBookSkillSaveSchemePop:UpdateInfo()
    self.tSkillSchemeList = GDAPI_GetMonsterSkillPreset(g_pClientPlayer)
    self.nMaxPlanCount = GDAPI_GetMonsterPresetMaxCount(g_pClientPlayer)

    self.nCurSchemeID = nil
    for _, scriptScheme in ipairs(self.tScriptScheme) do
        UIHelper.RemoveFromParent(scriptScheme._rootNode, true)
    end

    self.tScriptSchemeMap = {}
    for nSchemeID, tSkillIDList in ipairs(self.tSkillSchemeList) do
        if nSchemeID <= self.nMaxPlanCount then
            local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetSaveBZSkillTog, self.ScrollViewOptionList, nSchemeID, tSkillIDList, function ()
                self.nCurSchemeID = nSchemeID
            end)
            if scriptCell and self.nMaxPlanCount >= MonsterBookData.MAX_SCHEME_COUNT then
                UIHelper.SetSelected(scriptCell.ToggleSelect, nSchemeID == 1, false)
                self.nCurSchemeID = 1
            end
        end
    end
    local bCanCreate = self.nMaxPlanCount < MonsterBookData.MAX_SCHEME_COUNT
    UIHelper.SetSelected(self.ToggleNewScheme, bCanCreate, false)
    UIHelper.SetVisible(self.ToggleNewScheme, bCanCreate)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewOptionList)

    UIHelper.SetString(self.LabelTitle, string.format("存为预设招式（%d/%d）", self.nMaxPlanCount, MonsterBookData.MAX_SCHEME_COUNT))
end

return UIWidgetMonsterBookSkillSaveSchemePop