local UIWidgetMonsterBookSkillSchemeBag = class("UIWidgetMonsterBookSkillSchemeBag")

function UIWidgetMonsterBookSkillSchemeBag:OnEnter(tParam)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tParam = tParam
    self.fHidePanelCallback = tParam.fHidePanelCallback

    self.tSkillSchemeList = GDAPI_GetMonsterSkillPreset(g_pClientPlayer)
    self.nMaxPlanCount = GDAPI_GetMonsterPresetMaxCount(g_pClientPlayer)

    self:UpdateInfo()
end

function UIWidgetMonsterBookSkillSchemeBag:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonsterBookSkillSchemeBag:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        if self.fHidePanelCallback then self.fHidePanelCallback() end
    end)

    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function ()
        if self.fHidePanelCallback then self.fHidePanelCallback() end
    end)
end

function UIWidgetMonsterBookSkillSchemeBag:RegEvent()
    Event.Reg(self, "REMOTE_MONSTERSKILLPRESET_EVENT", function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_UPDATE_SKILL_COLLECTION", function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCell)
    end)
end

function UIWidgetMonsterBookSkillSchemeBag:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMonsterBookSkillSchemeBag:UpdateInfo()
    local tSkillSchemeList = GDAPI_GetMonsterSkillPreset(g_pClientPlayer)
    local nMaxPlanCount = GDAPI_GetMonsterPresetMaxCount(g_pClientPlayer)
    
    UIHelper.RemoveAllChildren(self.ScrollViewCell)
    for nSchemeID, tSkillList in ipairs(tSkillSchemeList) do
        if nSchemeID <= nMaxPlanCount then
            UIHelper.AddPrefab(PREFAB_ID.WidgetBZSkillScheme, self.ScrollViewCell, nSchemeID, tSkillList, function ()
                RemoteCallToServer("On_MonsterBook_ActivePreset", nSchemeID)
                if self.fHidePanelCallback then self.fHidePanelCallback() end
            end)
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCell)

    UIHelper.SetString(self.LabelTitle, string.format("预设招式（%d/%d）", nMaxPlanCount, MonsterBookData.MAX_SCHEME_COUNT))
    UIHelper.SetVisible(self.WidgetEmpty, nMaxPlanCount == 0)
end

return UIWidgetMonsterBookSkillSchemeBag