local UIMonsterBookView = class("UIMonsterBookView")

local SELECT_MODE = {
    PROGRESS = 1,
    SKILL = 2
}

function UIMonsterBookView:OnEnter(nMode, dwPlayerID, dwCenterID, szGlobalID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwPlayerID = dwPlayerID or UI_GetClientPlayerID()
    self.dwCenterID = dwCenterID
    self.szGlobalID = szGlobalID

    if not szGlobalID then
        local hPlayer = GetPlayer(self.dwPlayerID)
        if hPlayer then
            self.dwCenter = GetCenterID() or 0
            self.szGlobalID = hPlayer.GetGlobalID()
        end
    end

    if nMode then
        UIHelper.SetSelected(self.TogNavigationProgress, nMode == SELECT_MODE.PROGRESS, false)
        UIHelper.SetSelected(self.TogNavigationSkill, nMode == SELECT_MODE.SKILL, false)
    end
    self.nSelectMode = nMode
    self:InitMonsterBookView()
end

function UIMonsterBookView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMonsterBookView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogNavigationProgress, EventType.OnSelectChanged, function (bSelected)
        if not bSelected then return end
        self:RefreshModeView(SELECT_MODE.PROGRESS)
    end)
    
    UIHelper.BindUIEvent(self.TogNavigationSkill, EventType.OnSelectChanged, function (bSelected)
        if not bSelected then return end
        self:RefreshModeView(SELECT_MODE.SKILL)
    end)
end

function UIMonsterBookView:RegEvent()
    Event.Reg(self, EventType.OnViewOpen, function (nViewID)
        if VIEW_ID.PanelTutorialLite == nViewID then -- 教学弹出来了说明动画播完了
            UIHelper.SetVisible(self.BtnMask, false)
        elseif VIEW_ID.PanelBaiZhanSkillBag == nViewID then
            UIHelper.PlayAni(self, self.AniAll, "AniBottomHide", function ()
                UIHelper.SetVisible(self.WidgetAniBottom, false)
            end)
        end
    end)

    Event.Reg(self, EventType.OnViewClose, function (nViewID)
        if VIEW_ID.PanelBaiZhanSkillBag == nViewID then
            UIHelper.PlayAni(self, self.AniAll, "AniBottomShow", function ()
                UIHelper.SetVisible(self.WidgetAniBottom, true)
            end)
        end
    end)
end

function UIMonsterBookView:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMonsterBookView:InitMonsterBookView()
    UIHelper.RemoveAllChildren(self.WidgetAnchorMiddle)
    self.scriptSkillView = UIHelper.AddPrefab(PREFAB_ID.WidgetBaizhanSkills, self.WidgetAnchorMiddle, self.dwPlayerID, self.dwCenterID, self.szGlobalID)
    self.scriptProgressView = UIHelper.AddPrefab(PREFAB_ID.WidgetBaizhanProcess, self.WidgetAnchorMiddle)     
    self:RefreshModeView(self.nSelectMode or SELECT_MODE.PROGRESS)   
end

function UIMonsterBookView:RefreshModeView(nMode)
    self.nSelectMode = nMode or self.nSelectMode
    UIHelper.SetVisible(self.scriptProgressView._rootNode, self.nSelectMode == SELECT_MODE.PROGRESS)
    UIHelper.SetVisible(self.scriptSkillView._rootNode, self.nSelectMode == SELECT_MODE.SKILL)

    if self.nSelectMode == SELECT_MODE.PROGRESS and not MonsterBookData.tCustomData.bHasFirstProgressPanel then
        MonsterBookData.tCustomData.bHasFirstProgressPanel = true
        UIHelper.SetVisible(self.BtnMask, true) -- 有教学时，动画播完前不让点
        UIMgr.Open(VIEW_ID.PanelTutorialLite, 43)        
    end

    if self.nSelectMode == SELECT_MODE.SKILL and not MonsterBookData.tCustomData.bHasFirstSkillPanel then
        MonsterBookData.tCustomData.bHasFirstSkillPanel = true
        UIHelper.SetVisible(self.BtnMask, true) -- 有教学时，动画播完前不让点
        UIMgr.Open(VIEW_ID.PanelTutorialLite, 42)
    end

    if self.dwPlayerID ~= UI_GetClientPlayerID() then
        UIHelper.SetVisible(self.scriptProgressView._rootNode, false)
        UIHelper.SetVisible(self.TogNavigationProgress, false)
        UIHelper.SetVisible(self.TogNavigationSkill, false)

        local szName = "查看百战信息"
        local player = GetPlayer(self.dwPlayerID)
        if player and player.szName and player.szName ~= "" then szName = UIHelper.GBKToUTF8(player.szName) end
        UIHelper.SetString(self.LabelTitle, szName)
    end
end

return UIMonsterBookView