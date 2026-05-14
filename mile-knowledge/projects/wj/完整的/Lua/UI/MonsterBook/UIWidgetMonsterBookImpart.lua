local UIWidgetMonsterBookImpart = class("UIWidgetMonsterBookImpart")

local LEVEL_CHANGE_CD = 1.1 -- 切换技能CD，单位为秒
local IMPART_SKILL_ID = 35167 -- 传道授业技能ID
function UIWidgetMonsterBookImpart:OnEnter(targetPlayer)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.dwTargetPlayerID = targetPlayer.dwID
    self.targetPlayer = targetPlayer
    self.nImpartSkillID    = nil
    self.nImpartLevel      = nil
    self.tImpartSkillList  = nil
    self.nImpartCounts     = nil
    self.nMaxImpartCounts  = nil
    self.nBeImpartedCounts = nil
    self.nMaxBeImpCounts   = nil
    self.bFilterImpart     = nil    
    self.bEnableLevelChange = true

    FilterDef.MonsterBook.Reset()
    self:UpdateInfo()
    Timer.AddFrameCycle(self, 30, function ()
        self:OnFrameBreathe()
    end)
end

function UIWidgetMonsterBookImpart:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonsterBookImpart:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogRecommend, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self:UpdateImpartSkillLevelList()
        else
            UIHelper.SetVisible(self.LayoutUnfold1, false)
            UIHelper.SetVisible(self.ImgScrollviewBg, false)
        end

    end)

    UIHelper.BindUIEvent(self.BtnFilter, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnFilter, TipsLayoutDir.BOTTOM_RIGHT, FilterDef.MonsterBook)
    end)

    UIHelper.BindUIEvent(self.BtnHelp, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelBZTransSkillRulePop)
    end)

    UIHelper.BindUIEvent(self.BtnTrans, EventType.OnClick, function()
        local player = GetClientPlayer()
        if player.nMoveState == MOVE_STATE.ON_SIT then
            self:DoTransfer()
        else
            local nPlayerX, nPlayerY, _ = player.GetAbsoluteCoordinate()
            local nTargetX, nTargetY, _ = self.targetPlayer.GetAbsoluteCoordinate()
            local nDisX = nTargetX - nPlayerX
            local nDisY = nTargetY - nPlayerY
            local nDir = GetLogicDirection(nDisX, nDisY)
            TurnTo(nDir)
            Timer.AddFrame(self, 30, function ()
                local dwSkillID = 17 --打坐技能
                OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
                self.bDelayImpart = true
            end)            
        end
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxSearch, function ()
        self.bNeedRebuild = true
        self:UpdateInfo()
    end)
end

function UIWidgetMonsterBookImpart:RegEvent()
    Event.Reg(self, "REMOTE_IMPARTSKILL_EVENT", function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnFilter, function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, "PLAYER_LEAVE_SCENE", function (dwPlayerID)
        if dwPlayerID == self.dwTargetPlayerID then
            TipsHelper.ShowImportantBlueTip("目标玩家已经离开可传授范围")
            UIMgr.Close(self)
        end
    end)
end

function UIWidgetMonsterBookImpart:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIWidgetMonsterBookImpart:UpdateInfo()
    self:UpdateImpartSkillData()
    self:UpdateCurImpartSkill()
    self:UpdateImpartCounts()
    self:UpdateBeImpartedCounts()
    self:UpdateTogState()
end

function UIWidgetMonsterBookImpart:OnFrameBreathe()
    if self.bDelayImpart and GetClientPlayer().nMoveState == MOVE_STATE.ON_SIT then
        self:DoTransfer()        
    end
end

function UIWidgetMonsterBookImpart:UpdateCurImpartSkill()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local dwSkillID, nLevel = GDAPI_MonsterBook_GetSelectImpartSkill(pPlayer)
    if dwSkillID ~= 0 and nLevel ~= 0 then
        self.nImpartSkillID = dwSkillID
        self.nImpartLevel = nLevel
        local scriptSkill = self.tScriptSkillList[dwSkillID]
        if scriptSkill then UIHelper.SetSelected(scriptSkill.ToggleSelect, true) end
    end

    local szSkillName = Table_GetSkillName(self.nImpartSkillID, self.nImpartLevel)
    szSkillName = UIHelper.GBKToUTF8(szSkillName)
    local tCostPoints = GDAPI_MonsterBook_GetImpartCostPoints()
    local nCost = tCostPoints[self.nImpartLevel] or 0
    local szCost = string.format("传授消耗%d", nCost)
    local szLevel = MonsterBookData.GetLevelText(self.nImpartLevel or 1)
    UIHelper.SetString(self.LabelSkillName, szSkillName)
    UIHelper.SetString(self.LabelCost, szCost)
    UIHelper.SetString(self.LabelRecommend, szLevel)

    self.scriptImpartItem = self.scriptImpartItem or UIHelper.AddPrefab(PREFAB_ID.WidgetBZSkillPlayerItem, self.WidgetBZSkillPlayerItemShell)
    self.scriptImpartItem:OnEnter(dwSkillID, nLevel)
end

function UIWidgetMonsterBookImpart:GetCurImpartSkill()
    return self.nImpartSkillID
end

function UIWidgetMonsterBookImpart:UpdateImpartSkillData()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local tSkillList =  GDAPI_MonsterBook_GetImpartSkill(pPlayer)
    if not tSkillList then
        return
    end
    self.tImpartSkillList = {}
    for _, tSkill in ipairs(tSkillList) do
        local dwSkillID = tSkill[1]
        local nMaxImpartLevel = tSkill[2]
        if dwSkillID and nMaxImpartLevel and dwSkillID > 0 and nMaxImpartLevel > 0 then
            self.tImpartSkillList[dwSkillID] = nMaxImpartLevel
        end
    end

    self:UpdateImpartSkillListInfo()
end

function UIWidgetMonsterBookImpart:GetImpartSkillList()
    return self.tImpartSkillList
end

function UIWidgetMonsterBookImpart:UpdateImpartCounts()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local nImpartCounts, nMaxImpartCounts = GDAPI_MonsterBook_GetImpartPoints(pPlayer)
    self.nImpartCounts = nImpartCounts
    self.nMaxImpartCounts = nMaxImpartCounts

    local szImpart = string.format("%d/%d", self.nImpartCounts, self.nMaxImpartCounts)
    UIHelper.SetString(self.LabelNeili, szImpart)
end

function UIWidgetMonsterBookImpart:GetImpartCounts()
    return self.nImpartCounts
end

function UIWidgetMonsterBookImpart:UpdateBeImpartedCounts()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local nBeImpartedCounts, nMaxBeImpCounts = GDAPI_MonsterBook_GetBeImpartedPoints(pPlayer)
    self.nBeImpartedCounts = nBeImpartedCounts
    self.nMaxBeImpCounts = nMaxBeImpCounts

    local szImpart = string.format("%d/%d", self.nBeImpartedCounts, self.nMaxBeImpCounts)
    UIHelper.SetString(self.LabelTimes, szImpart)
end

function UIWidgetMonsterBookImpart:GetBeImpartedCounts()
    return self.nBeImpartedCounts
end

function UIWidgetMonsterBookImpart:UpdateImpartSkillListInfo()
    self:ApplyFilter()
    local szSearch = UIHelper.GetText(self.EditBoxSearch)
    local tFiltedList = MonsterBookData.GetSearchList(UIHelper.UTF8ToGBK(szSearch), self.tTypeFiltedList) or {}
    tFiltedList = self:FilterImpartList(tFiltedList, self.tSearchFilter[5])

    if self.bNeedRebuild or not self:TryRefreshSkillList(tFiltedList) then
        self:TryReubuildSkillList(tFiltedList)
    end
end

function UIWidgetMonsterBookImpart:TryReubuildSkillList(tFiltedList)
    local player = GetClientPlayer()
    UIHelper.RemoveAllChildren(self.LayoutContent)
    self.bNeedRebuild = false
    self.tScriptSkillList = {}
    local dwFirstSkill = nil
    for _, tSkillInfo in pairs(tFiltedList) do
        local dwSkillID = tSkillInfo.dwOutSkillID
        local nLevel = player.GetCollectionSkillLevel(dwSkillID)
        local scriptSkill = UIHelper.AddPrefab(PREFAB_ID.WidgetBaiZhanSkillItem, self.ScrollViewContent, dwSkillID, nLevel, function ()
            self:OnSelectImpartSkill(dwSkillID)
        end)
        if not dwFirstSkill and not self.nImpartSkillID then
            dwFirstSkill = dwSkillID
        end
        self.tScriptSkillList[dwSkillID] = scriptSkill
    end
    if dwFirstSkill then
        self:OnSelectImpartSkill(dwFirstSkill)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
end

function UIWidgetMonsterBookImpart:TryRefreshSkillList(tFiltedList)
    if table.GetCount(self.tScriptSkillList) ~= #tFiltedList then
        return false
    end
    local player = GetClientPlayer()
    local tRefreshScriptList = {}
    for nIndex, v in ipairs(tFiltedList) do
        local dwSkillID = v.dwOutSkillID
        local nLevel = player.GetCollectionSkillLevel(dwSkillID) or 0
        local scriptSkill = self.tScriptSkillList[dwSkillID]
        if not scriptSkill then
            return false
        elseif nLevel ~= scriptSkill.nLevel then
            scriptSkill.dwSkillID = dwSkillID
            scriptSkill.nLevel = nLevel
            table.insert(tRefreshScriptList, scriptSkill)
        end
    end

    for _, scriptSkill in ipairs(tRefreshScriptList) do
        scriptSkill:OnEnter(scriptSkill.dwSkillID, scriptSkill.nLevel, scriptSkill.fCallBack)

        local scriptActive = self.tActivedScriptList[scriptSkill.dwSkillID]
        if scriptActive then
            scriptActive:OnEnter(scriptActive.dwSkillID, scriptActive.nLevel, scriptActive.fCallBack)
        end
    end
    return true
end

function UIWidgetMonsterBookImpart:ApplyFilter(nFiltType, nFiltID)
    if not self.tSearchFilter then
        self.tSearchFilter = {1,1,1,1,1}
    end
    for nIndex, tSelected in ipairs(FilterDef.MonsterBook.GetRunTime() or {}) do
        self.tSearchFilter[nIndex] = tSelected[1]
    end
    if nFiltType and nFiltID then
        self.tSearchFilter[nFiltType] = nFiltID
    end
    local nType = self.tSearchFilter[1]
    self.tTypeFiltedList = MonsterBookData.GetFiltedList(nType, self.tSearchFilter)
end

function UIWidgetMonsterBookImpart:FilterImpartList(tSkillList, nFilterIndex)
    if nFilterIndex == 1 then
        return tSkillList
    end
    local tFilterCanImpart = {}
    local tFilterCannotImpart = {}
    local tImpartSkillList = self.tImpartSkillList
    for _, tLine in ipairs(tSkillList) do
        local dwSkillID = tLine.dwOutSkillID
        if tImpartSkillList[dwSkillID] and tImpartSkillList[dwSkillID] > 0 then
            table.insert(tFilterCanImpart, tLine)
        else
            table.insert(tFilterCannotImpart, tLine)
        end
    end
    if nFilterIndex == 2 then
        return tFilterCanImpart
    elseif nFilterIndex == 3 then
        return tFilterCannotImpart
    end
end

function UIWidgetMonsterBookImpart:UpdateTogState()
    UIHelper.SetCanSelect(self.TogRecommend, true)
    UIHelper.SetSelected(self.TogRecommend, false)
    if not self.nImpartSkillID or not self.nImpartLevel then
        UIHelper.SetCanSelect(self.TogRecommend, false)
    elseif not self.bEnableLevelChange then
        UIHelper.SetCanSelect(self.TogRecommend, false, "正在调息中")
    end
end

function UIWidgetMonsterBookImpart:OnSelectImpartSkill(dwSkillID)
    if not dwSkillID then
        return
    end
    local player = GetClientPlayer()
    local tSkillList = player.GetAllSkillInCollection()
    local nMaxLevel = tSkillList[dwSkillID]
    if not nMaxLevel then
        local szMsg = g_tStrings.MONSTER_BOOK_IMPART_NOT_HAVE_SKILL
        TipsHelper.ShowImportantRedTip(szMsg)
        return
    end

    local tImpartSkillList = self:GetImpartSkillList()
    local nMaxImpLevel = tImpartSkillList[dwSkillID]
    if not nMaxImpLevel then
        local szMsg = g_tStrings.MONSTER_BOOK_CANNOT_IMPART
        TipsHelper.ShowImportantRedTip(szMsg)
        return
    end

    local DEFAULT_IMPART_LEVEL = nMaxImpLevel
    local dwCurImpSkillID = self:GetCurImpartSkill()
    if dwCurImpSkillID and dwCurImpSkillID == dwSkillID then
        return
    end
    self.nImpartLevel = DEFAULT_IMPART_LEVEL
    self.nMaxImpLevel = nMaxImpLevel
    RemoteCallToServer("On_MonsterBook_SetImpartSkill", dwSkillID, DEFAULT_IMPART_LEVEL)
    self:OnModifyImpartSkill()
end

function UIWidgetMonsterBookImpart:UpdateImpartSkillLevelList()
    local player = GetClientPlayer()
    if not player then
        return
    end
    local LIMIT_LEVEL = 6
    local tSkillList = player.GetAllSkillInCollection()
    local nMaxLevel = tSkillList[self.nImpartSkillID]
    if not nMaxLevel then
        return
    end
    if self.nMaxImpLevel <= nMaxLevel and self.nMaxImpLevel >= 1 then
        nMaxLevel = self.nMaxImpLevel
    end
    UIHelper.SetVisible(self.LayoutUnfold1, nMaxLevel <= LIMIT_LEVEL)
    UIHelper.SetVisible(self.ImgScrollviewBg, nMaxLevel > LIMIT_LEVEL)
    UIHelper.SetVisible(self.ScrollviewContent, nMaxLevel > LIMIT_LEVEL)

    UIHelper.RemoveAllChildren(self.LayoutUnfold1)
    UIHelper.RemoveAllChildren(self.ScrollviewContent)

    local parent
    if nMaxLevel <= LIMIT_LEVEL then
        parent = self.LayoutUnfold1
    else
        parent = self.ScrollviewContent
    end

    for nLevel = 1, nMaxLevel do
        local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetSelectTog260X50, parent)
        local szText = FormatString(g_tStrings.MONSTER_BOOK_LEVEL, UIHelper.NumberToChinese(nLevel))
        scriptItem:OnEnter(nLevel, szText, function (nLevel, szText)
            self.nSelectLevel = nLevel
            UIHelper.SetSelected(self.TogRecommend, false)
            UIHelper.SetString(self.LabelRecommend, szText)
            self:OnChangeImpartSkillLevel(nLevel)
        end)

    end

    if nMaxLevel <= LIMIT_LEVEL then
        UIHelper.LayoutDoLayout(self.LayoutUnfold1)
    else
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollviewContent)
    end
end

function UIWidgetMonsterBookImpart:OnChangeImpartSkillLevel(nSelectLevel)
    local nLevel = self.nImpartLevel
    local dwSkillID = self.nImpartSkillID
    if not nLevel or nLevel == 0 or not dwSkillID then
        return
    end
    local tImpartSkillList = self:GetImpartSkillList()
    local nMaxLevel = tImpartSkillList[dwSkillID]
    if not nMaxLevel then
        return
    end
    nLevel = nSelectLevel
    if not nLevel or nLevel < 1 or nLevel > nMaxLevel then
        return
    end
    RemoteCallToServer("On_MonsterBook_SetImpartSkill", dwSkillID, nLevel)
    self:OnModifyImpartSkill()
end

function UIWidgetMonsterBookImpart:OnModifyImpartSkill()
    self.bEnableLevelChange = false
    self:UpdateTogState()
    self.nSwitchCoolDown = self.nSwitchCoolDown or Timer.Add(self, LEVEL_CHANGE_CD, function ()
        self.nSwitchCoolDown = nil
        self.bEnableLevelChange = true
        self:UpdateTogState()
    end)
    self:UpdateCurImpartSkill()
end

function UIWidgetMonsterBookImpart:DoTransfer()
    self.bDelayImpart = false
    SkillData.SetCastPointToTargetPos()
    local nMask = (IMPART_SKILL_ID * (IMPART_SKILL_ID % 10 + 1))
    OnUseSkill(IMPART_SKILL_ID, nMask, nil, nil, true)
end

return UIWidgetMonsterBookImpart