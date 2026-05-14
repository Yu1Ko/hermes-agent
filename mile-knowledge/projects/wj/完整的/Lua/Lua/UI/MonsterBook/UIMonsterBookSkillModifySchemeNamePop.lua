local UIMonsterBookSkillModifySchemeNamePop = class("UIMonsterBookSkillModifySchemeNamePop")

function UIMonsterBookSkillModifySchemeNamePop:OnEnter(nSchemeID, bChangeName)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nSchemeID = nSchemeID
    self.bChangeName = bChangeName
    local nMaxPlanCount = GDAPI_GetMonsterPresetMaxCount(g_pClientPlayer)

    if not nSchemeID and nMaxPlanCount >= MonsterBookData.MAX_SCHEME_COUNT then
        UIMgr.Close(self)
        return
    end

    self.bNeedDelete = not nSchemeID
    if self.bNeedDelete then
        self.nSchemeID = nMaxPlanCount + 1
        RemoteCallToServer("On_MonsterBook_CreatePreset", nMaxPlanCount + 1)
    end
    self:UpdateInfo()
end

function UIMonsterBookSkillModifySchemeNamePop:OnExit()
    self.bInit = false
    self:UnRegEvent()

    if self.bNeedDelete then 
        local nMaxPlanCount = GDAPI_GetMonsterPresetMaxCount(g_pClientPlayer) 
        RemoteCallToServer("On_MonsterBook_DeletePreset", nMaxPlanCount)
    end
end

function UIMonsterBookSkillModifySchemeNamePop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function ()
        self:DoSaveScheme()
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBox, function ()
        local szName = UIHelper.GetText(self.EditBox) or ""
        local nCharCount = GetStringCharCount(szName)
        UIHelper.SetString(self.LableHintCount, string.format("%d/%d", nCharCount, MonsterBookData.MAX_SCHEME_NAME_SIZE))
    end)
end

function UIMonsterBookSkillModifySchemeNamePop:RegEvent()

end

function UIMonsterBookSkillModifySchemeNamePop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMonsterBookSkillModifySchemeNamePop:InitData()

end

function UIMonsterBookSkillModifySchemeNamePop:UpdateInfo()
    if not self.bNeedDelete then
        local szName = Storage.MonsterBook.tSkillPresetName[self.nSchemeID]
        UIHelper.SetText(self.EditBox, szName)
        local nCharCount = GetStringCharCount(szName)
        UIHelper.SetString(self.LableHintCount, string.format("%d/%d", nCharCount, MonsterBookData.MAX_SCHEME_NAME_SIZE))
    end
end

function UIMonsterBookSkillModifySchemeNamePop:DoSaveScheme()
    self.tSkillSchemeList = GDAPI_GetMonsterSkillPreset(g_pClientPlayer)
    self.nMaxPlanCount = GDAPI_GetMonsterPresetMaxCount(g_pClientPlayer) or 0

    local szName = UIHelper.GetText(self.EditBox) or ""
    if #szName == 0 then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CUSTOMIZED_SET_NAME_ERROR1)
        return
    end

    if MonsterBookData.MatchString(szName, " ") then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CUSTOMIZED_SET_NAME_ERROR2)
        return
    end

    if not TextFilterCheck(UIHelper.UTF8ToGBK(szName)) then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CUSTOMIZED_SET_NAME_ERROR3)
        return
    end

    if self.bNeedDelete then
        if self.nMaxPlanCount > MonsterBookData.MAX_SCHEME_COUNT then
            TipsHelper.ShowNormalTip("预设数量已达上限")
            return
        end
        self.bNeedDelete = false
        Storage.MonsterBook.tSkillPresetName[self.nSchemeID] = szName
        RemoteCallToServer("On_MonsterBook_SavePreset", self.nSchemeID)
    elseif not self.bChangeName then
        Storage.MonsterBook.tSkillPresetName[self.nSchemeID] = szName
        RemoteCallToServer("On_MonsterBook_SavePreset", self.nSchemeID)
    else
        Storage.MonsterBook.tSkillPresetName[self.nSchemeID] = szName
        Event.Dispatch(EventType.OnMonsterBookSchemeNameChange, self.nSchemeID, szName)
        TipsHelper.ShowNormalTip("方案名称修改成功")
    end
    UIMgr.Close(self)
end

return UIMonsterBookSkillModifySchemeNamePop