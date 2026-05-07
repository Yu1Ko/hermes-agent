local UIMonsterBookDistribute = class("UIMonsterBookDistribute")

local DEFAULT_SKILL_LEVEL = 1
local COST_LIMIT          = 3 -- 技能消耗上限
local SKILL_BOX_LIMIT     = 3 -- 每个成员可分配技能种数
local SKILL_TOGGLE_GROUP_INDEX = 01291950 -- 技能列表的GroupIndex
local PLAYER_TOGGLE_GROUP_INDEX = 01291951 -- 玩家列表的GroupIndex
function UIMonsterBookDistribute:OnEnter(bMulti, tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitData(bMulti, tInfo)
    self:UpdateInfo(bMulti)

    self.nTimerID = self.nTimerID or Timer.AddFrameCycle(self, 1, function ()
        local dwLastSkillID = self.dwLastSkillID or 0
        local dwSelectSkillID = self.dwSelectSkillID or 0
        if dwLastSkillID ~= dwSelectSkillID then
            self.dwLastSkillID = self.dwSelectSkillID
            Event.Dispatch(EventType.OnMonsterBookSelectTempSkillChange, self.dwSelectSkillID, self.tPlayerList)
        end
    end)
end

function UIMonsterBookDistribute:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Event.Dispatch(EventType.OnEnterMonsterBookScene) -- 这个界面被远程调用关闭时，说明需要刷新
end

function UIMonsterBookDistribute:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function ()
        self:ConfirmDispense()
    end)

    UIHelper.BindUIEvent(self.BtnTeamConfirm, EventType.OnClick, function ()
        self:ConfirmDispense()
    end)

    UIHelper.BindUIEvent(self.BtnWarehouse, EventType.OnClick, function ()
        local dwSkillID = self.dwSelectSkillID
        if dwSkillID then
            RemoteCallToServer("On_MonsterBook_Store", dwSkillID)
        end
    end)

    UIHelper.BindUIEvent(self.BtnHelp, EventType.OnClick, function ()
        local szMsg = "可以将仓库内的临时技能分配给团队玩家，或者将已经分配的临时技能退回仓库"
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnHelp, szMsg)
    end)

    UIHelper.BindUIEvent(self.BtnDistributeHelp, EventType.OnClick, function ()
        local szMsg = "战斗分数越高越有可能获得临时技能，临时技能可以分配给团队玩家或者放入团队仓库"
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnHelp, szMsg)
    end)

    UIHelper.BindUIEvent(self.BtnFilter, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnFilter, TipsLayoutDir.BOTTOM_RIGHT, FilterDef.MonsterBookDynamicSkill)
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxSearch, function ()
        self:InitTeamSkillList()
    end)
end

function UIMonsterBookDistribute:RegEvent()
    Event.Reg(self, EventType.OnFilter, function ()
        self:FiltType()
        self:InitTeamSkillList()
    end)
end

function UIMonsterBookDistribute:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIMonsterBookDistribute:InitData(bMulti, tInfo)
    table.sort(tInfo.tSkillChoose)
    self.tSkillChoose      = tInfo.tSkillChoose
    self.dwSkillUsed       = nil -- 用于个人分配
    self.tPlayerList       = tInfo.tPlayerList or {}
    self.dwSelectSkillID   = nil
    self.bMulti            = bMulti
    self.nMaxLevel         = tInfo.nMaxSkillLevel -- 技能等级升级上限
    FilterDef.MonsterBookDynamicSkill.Reset()
    
    self:InitDistribute() -- [dwPlayerID] = {nSkillID_1, nSkillID_2, ...}
    self:FiltType()

    if self.bMulti then
        UIHelper.SetString(self.LabelTitle, "团队技能库")
    else
        UIHelper.SetString(self.LabelTitle, "掉落分配")
    end
    UIHelper.SetVisible(self.WidgetBtnConfirm, self.bMulti)
    UIHelper.SetVisible(self.WidgetBtnDistribute, not self.bMulti)
    UIHelper.SetVisible(self.WidgetAnchorWareHouse, self.bMulti)
    UIHelper.SetVisible(self.WidgetAnchorDistribute, not self.bMulti)
    UIHelper.SetVisible(self.WidgetEditSearch, self.bMulti)
    UIHelper.SetVisible(self.BtnFilter, self.bMulti)
    UIHelper.SetVisible(self.BtnHelp, self.bMulti)
end

function UIMonsterBookDistribute:InitDistribute()
    self.tDistribute  = {}
    for _, v in pairs(self.tPlayerList) do
        if v.dwID then
            self.tDistribute[v.dwID] = v.tInSkillID or {}
        end
    end
    self.bCanQuickDis = true
end

function UIMonsterBookDistribute:FiltType(nFiltType, nFiltID)
    if not self.tSearchFilter then
        self.tSearchFilter = {1,1,1,1,1}
    end
    for nIndex, tSelected in ipairs(FilterDef.MonsterBookDynamicSkill.GetRunTime() or {}) do
        if nIndex < 4 then -- 团队技能库隐藏了重数筛选和传授筛选
            self.tSearchFilter[nIndex] = tSelected[1]
        end
    end
    if nFiltType and nFiltID then
        self.tSearchFilter[nFiltType] = nFiltID
    end
    local nType = self.tSearchFilter[1]
    self.tTypeFiltedList = MonsterBookData.GetFiltedList(nType, self.tSearchFilter, self.tSkillChoose)
end

function UIMonsterBookDistribute:GetSkillByIndex(nIndex)
    return self.tSkillChoose[nIndex] or 0
end

function UIMonsterBookDistribute:IsSkillSelected(dwSkillID)
    local nIndex = self.dwSelectSkillID
    if dwSkillID then
        return self.dwSelectSkillID == dwSkillID
    else
        return self.dwSelectSkillID ~= nil
    end
end

function UIMonsterBookDistribute:IsSkillDispensed(dwPlayerID)
    if self.tDistribute and dwPlayerID then
        local tSkill = self.tDistribute[dwPlayerID]
        if tSkill and not IsEmpty(tSkill) then
            return true
        end
    end
    return false
end

function UIMonsterBookDistribute:GetMemberSkillCollected(dwPlayerID)
    local tSkillID, tSkillLevel = {}, {}
    for nIndex, tInfo in ipairs(self.tPlayerList) do
        if dwPlayerID == tInfo.dwID then
            tSkillID = tInfo.tSkillID
            tSkillLevel = tInfo.tSkillLevel
            break
        end
    end
    return tSkillID, tSkillLevel
end

function UIMonsterBookDistribute:GetMemberSkillUnCollected(dwPlayerID)
    return self.tDistribute[dwPlayerID]
end

function UIMonsterBookDistribute:GetTotalCost(dwPlayerID)
    local nTotalCost = 0
    local tCollectedSkill = self:GetMemberSkillCollected(dwPlayerID)
    local tUnCollectedSkill = self:GetMemberSkillUnCollected(dwPlayerID)

    for i, dwSkillID in ipairs(tCollectedSkill) do
        local nCost = MonsterBookData.GetCost(dwSkillID, true)
        nTotalCost = nTotalCost + nCost
    end

    for i, dwSkillID in ipairs(tUnCollectedSkill) do
        local bRepeat = false
        for _, v in ipairs(tCollectedSkill) do
            if v == dwSkillID then
                bRepeat = true
                break
            end
        end
        if not bRepeat then
            for j = i - 1, 1, -1 do
                if tUnCollectedSkill[j] == dwSkillID then
                    bRepeat = true
                    break
                end
            end
        end
        if not bRepeat then
            local nCost = MonsterBookData.GetCost(dwSkillID, true)
            nTotalCost = nTotalCost + nCost
        end
    end
    return nTotalCost
end

function UIMonsterBookDistribute:AddSkillToMember(dwPlayerID, dwSkillID, bChangeData)
    if not dwSkillID or dwSkillID == 0 or not dwPlayerID or not self.tDistribute then
        return false
    end

    local tCollectedSkill, tCollectedSkillLevel = self:GetMemberSkillCollected(dwPlayerID)
    local tUnCollectedSkill = self:GetMemberSkillUnCollected(dwPlayerID)
    local tRecordLevel = {}
    local tRecordPos = {}
    local nRecordLength = 0
    for i, v in ipairs(tCollectedSkill) do
        tRecordLevel[v] = tCollectedSkillLevel[i]
        nRecordLength = nRecordLength + 1
        tRecordPos[v] = nRecordLength
    end
    for i, v in ipairs(tUnCollectedSkill) do
        if not tRecordLevel[v] then
            tRecordLevel[v] = 1
            nRecordLength = nRecordLength + 1
            tRecordPos[v] = nRecordLength
        else
            tRecordLevel[v] = tRecordLevel[v] + 1
        end
    end

    if bChangeData then
        if not tRecordLevel[dwSkillID] then
            tRecordLevel[dwSkillID] = 1
            nRecordLength = nRecordLength + 1
            tRecordPos[dwSkillID] = nRecordLength
        else
            tRecordLevel[dwSkillID] = tRecordLevel[dwSkillID] + 1
        end
    end

    local bAddSuccess = true
    local nAddPos = tRecordPos[dwSkillID]
    local nLevel = tRecordLevel[dwSkillID]
    local nMaxLevel = self:GetMaxSkillLevel()
    if bChangeData then
        if nAddPos > SKILL_BOX_LIMIT then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.MONSTER_BOOK_POS_LIMIT)
            tRecordPos[dwSkillID] = nil
            tRecordLevel[dwSkillID] = nil
            nRecordLength = nRecordLength - 1
            bAddSuccess = false
        elseif nLevel > nMaxLevel then
            OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.MONSTER_BOOK_LEVEL_LIMIT)
            tRecordLevel[dwSkillID] = tRecordLevel[dwSkillID] - 1
            bAddSuccess = false
        end
    end

    local nCost = 0
    for dwSkillID, _ in pairs(tRecordPos) do
        nCost = nCost + MonsterBookData.GetCost(dwSkillID, true)
    end
    if nCost > COST_LIMIT then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.MONSTER_BOOK_COST_LIMIT)
        bAddSuccess = false
    end

    if bAddSuccess and bChangeData then
        if not self.bMulti then
            self.dwSkillUsed = dwSkillID
        end

        if not self.tDistribute[dwPlayerID] then
            self.tDistribute[dwPlayerID] = {dwSkillID}
        else
            table.insert(self.tDistribute[dwPlayerID], dwSkillID)
        end

        local nCount = 0
        for i = #self.tSkillChoose, 1, -1 do
            if self.tSkillChoose[i] == self.dwSelectSkillID then
                nCount = nCount + 1
                if nCount == 1 then
                    table.remove(self.tSkillChoose, i)
                end
            end
        end
        if nCount <= 1 or not self.bMulti then
            self.dwSelectSkillID = nil
        end
        self.bCanQuickDis = false
    end

    return bAddSuccess, nAddPos, nLevel, nCost
end

function UIMonsterBookDistribute:DeleteMemberSkill(dwPlayerID, dwSkillID)
    self.dwSelectSkillID = nil
    local nReduceLevel = 0
    if not self.bMulti and self.dwSkillUsed == dwSkillID then
        self.dwSkillUsed = nil
        nReduceLevel = 1
    elseif self.bMulti then
        nReduceLevel = self.nMaxLevel
    end

    local nCount = 0
    if self.tDistribute then
        local tSkill = self.tDistribute[dwPlayerID]
        for i = #tSkill, 1, -1 do
            if nCount >= nReduceLevel then break end
            if tSkill[i] == dwSkillID then
                table.remove(self.tDistribute[dwPlayerID], i)
                table.insert(self.tSkillChoose, dwSkillID)
                nCount = nCount + 1
            end
        end
        self.bCanQuickDis = false
    end
    return nCount
end

function UIMonsterBookDistribute:ConfirmDispense()
    local tData = {}
    for dwPlayerID, tSkill in pairs(self.tDistribute) do
        local tSkillID = self:GetMemberSkillUnCollected(dwPlayerID)
        tData[dwPlayerID] = tSkillID
    end
    if self.bMulti then
        RemoteCallToServer("On_MonsterBook_TeamConfirm", tData)
    else
        RemoteCallToServer("On_MonsterBook_Confirm", tData, self.dwSkillUsed)
    end
end

function UIMonsterBookDistribute:GetMaxSkillLevel()
    return self.nMaxLevel
end

function UIMonsterBookDistribute:OnFrameBreathe()
    
end

------------------------------表现-----------------------------------
function UIMonsterBookDistribute:UpdateInfo(bMulti)
    if bMulti then
        self:InitTeamSkillList()
    else
        self:InitPersonSkillList()
    end
    self:InitMemberList()
end

function UIMonsterBookDistribute:UpdateSkillList()
    if self.bMulti then
        self:FiltType()
        self:InitTeamSkillList()
    else
        self:InitPersonSkillList()
        self:UpdateSkillSelectState()
    end
end

function UIMonsterBookDistribute:InitTeamSkillList()
    local szSearch = UIHelper.GetText(self.EditBoxSearch)
    szSearch = UIHelper.UTF8ToGBK(szSearch)
    local tFiltedSearchList = MonsterBookData.GetSearchList(szSearch, self.tTypeFiltedList) or {}
    table.sort(tFiltedSearchList, function (tSkillInfo1, tSkillInfo2)
        return tSkillInfo1.dwInSkillID > tSkillInfo2.dwInSkillID
    end)

    self.dwSelectSkillID = nil
    self.tScriptSkillList = {}
    UIHelper.RemoveAllChildren(self.LayoutSkillList)
    for _, v in ipairs(tFiltedSearchList) do
        local dwSkillID = v.dwInSkillID
        local scriptSkill = UIHelper.AddPrefab(PREFAB_ID.WidgetBaiZhanSkillItem, self.ScrollViewSkillList, v.dwOutSkillID, DEFAULT_SKILL_LEVEL, function (scriptCell)
            local bSelectChanged = self.dwSelectSkillID == nil or self.dwSelectSkillID ~= dwSkillID
            self.dwSelectSkillID = dwSkillID

            self:UpdateBtnState()
            self:UpdateSkillSelectState(bSelectChanged)           
            if not bSelectChanged then
                scriptCell:SetMultiSelected(not scriptCell.bMultiSelected)
            end
            local nSelectCount = self:GetSkillSelectCount()
            if not scriptCell.bMultiSelected and nSelectCount == 0 then
                Event.Dispatch(EventType.OnMonsterBookSelectTempSkillChange, nil, self.tPlayerList)
            elseif scriptCell.bMultiSelected and not bSelectChanged then
                Event.Dispatch(EventType.OnMonsterBookSelectTempSkillChange, self.dwSelectSkillID, self.tPlayerList)
            end
        end)
        scriptSkill:SetMultiMode(true)
        if not self.tScriptSkillList[dwSkillID] then
            self.tScriptSkillList[dwSkillID] = {}
        end
        table.insert(self.tScriptSkillList[dwSkillID], scriptSkill)
    end
    UIHelper.SetVisible(self.WidgetEmpty, #tFiltedSearchList == 0)
    UIHelper.SetSelected(self.ToggleDefaultSkill, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSkillList)
end

function UIMonsterBookDistribute:InitPersonSkillList()
    self.dwSelectSkillID = nil
    self.tScriptSkillList = {}
    UIHelper.RemoveAllChildren(self.LayoutDropSkillList)
    for _, dwSkillID in ipairs(self.tSkillChoose) do
        local dwOutSkillID = MonsterBookData.tIn2OutSkillMap[dwSkillID] or dwSkillID
        local scriptSkill = UIHelper.AddPrefab(PREFAB_ID.WidgetBaiZhanSkillItem, self.LayoutDropSkillList, dwOutSkillID, DEFAULT_SKILL_LEVEL, function ()
            local bSelected = self.dwSelectSkillID ~= dwSkillID
            if self.dwSelectSkillID == dwSkillID then
                UIHelper.SetSelected(self.ToggleDefaultSkill, true)
                self.dwSelectSkillID = nil
            else
                self.dwSelectSkillID = dwSkillID
            end            

            if not bSelected then
                Event.Dispatch(EventType.OnMonsterBookSelectTempSkillChange, nil, self.tPlayerList)
            else                
                Event.Dispatch(EventType.OnMonsterBookSelectTempSkillChange, self.dwSelectSkillID, self.tPlayerList)
            end
            self:UpdateBtnState()
        end)
        scriptSkill:SetMultiMode(false)
        self.tScriptSkillList[dwSkillID] = scriptSkill        
    end
    UIHelper.SetSelected(self.ToggleDefaultSkill, true)
end

function UIMonsterBookDistribute:InitMemberList()
    self.tScriptPlayerList = {}
    local scriptRow = nil
    UIHelper.RemoveAllChildren(self.LayoutPlayerList)
    for nIndex, tInfo in ipairs(self.tPlayerList) do
        local dwPlayerID = tInfo.dwID
        if not scriptRow then
            scriptRow = UIHelper.AddPrefab(PREFAB_ID.WidgetPlayerListDoubleCell, self.LayoutPlayerList)
            scriptRow:OnEnter()
        end
        local scriptCell, bCanPush = scriptRow:CreateCellScript()
        self.tScriptPlayerList[dwPlayerID] = scriptCell
        if not bCanPush then
            scriptRow = nil
        end
        scriptCell:OnEnter(tInfo, function ()
            if self.dwSelectSkillID then
                if self.bMulti then
                    local scriptSkillList = self.tScriptSkillList[self.dwSelectSkillID]
                    local nCount = 0
                    for _, scriptSkill in ipairs(scriptSkillList) do
                        if scriptSkill.bMultiSelected then nCount = nCount + 1 end
                    end
                    self:AddSkillToMemberCell(scriptCell, dwPlayerID, self.dwSelectSkillID, true, nCount)
                else
                    self:AddSkillToMemberCell(scriptCell, dwPlayerID, self.dwSelectSkillID, true)
                end                
            end            
        end)
        self:UpdateMemberSkillCollected(scriptCell, dwPlayerID)
        self:UpdateMemberSkillUnCollected(scriptCell, dwPlayerID)
        self:UpdateMemberCost(scriptCell, dwPlayerID)
    end
    UIHelper.SetSelected(self.ToggleDefaultPlayer, true)
    UIHelper.LayoutDoLayout(self.LayoutPlayerList)
    self:UpdateBtnState()
end

function UIMonsterBookDistribute:UpdateMemberSkillCollected(scriptCell, dwPlayerID)
    local tSkillID, tSkillLevel = self:GetMemberSkillCollected(dwPlayerID)
    for i = 1, #tSkillID do
        local dwSkillID = tSkillID[i]
        local nLevel = tSkillLevel[i]
        if dwSkillID and nLevel then
            scriptCell:AllocSkillSolt(dwSkillID, nLevel)
        end
    end
    UIHelper.LayoutDoLayout(scriptCell.LayoutSkillBox)
end

function UIMonsterBookDistribute:UpdateMemberSkillUnCollected(scriptCell, dwPlayerID)
    local tSkillList = self:GetMemberSkillUnCollected(dwPlayerID)
    for _, dwSkillID in ipairs(tSkillList) do
        self:AddSkillToMemberCell(scriptCell, dwPlayerID, dwSkillID, false)
    end
end

function UIMonsterBookDistribute:AddSkillToMemberCell(scriptCell, dwPlayerID, dwSkillID, bChangeData, nCount)
    nCount = nCount or 1
    for i = 1, nCount do
        local bAddSuccess, nAddPos, nLevel, nTotalCost = self:AddSkillToMember(dwPlayerID, dwSkillID, bChangeData)
        if bAddSuccess then
            local scriptSkill = scriptCell:AllocSkillSolt(dwSkillID, nLevel, function () -- 移除技能回调函数
                if not self.bMulti and not self.dwSkillUsed then
                    TipsHelper.ShowImportantRedTip("当前界面不能卸除已装备的临时技能")
                    return
                end
                UIHelper.SetSelected(self.ToggleDefaultSkill, true)
                UIHelper.SetSelected(self.ToggleDefaultPlayer, true)
                Timer.AddFrame(self, 1, function ()
                    self:DeleteMemberSkill(dwPlayerID, dwSkillID)
                    self:DeleteMemberSkillCell(scriptCell, dwPlayerID)
                end)
            end)
            UIHelper.SetVisible(scriptSkill.WidgetBtnRemove, true)
            self:UpdateMemberCost(scriptCell, dwPlayerID, nTotalCost)
        end
    end

    self:UpdateSkillList()
    self:UpdateBtnState()
end

function UIMonsterBookDistribute:DeleteMemberSkillCell(scriptCell, dwPlayerID)
    scriptCell:ClearAllSkillSolt()
    self:UpdateMemberSkillCollected(scriptCell, dwPlayerID)
    self:UpdateMemberSkillUnCollected(scriptCell, dwPlayerID)
    self:UpdateMemberCost(scriptCell, dwPlayerID)
    self:UpdateSkillList()
    self:UpdateBtnState()
end

function UIMonsterBookDistribute:UpdateMemberCost(scriptCell, dwPlayerID, nTotalCost)
    if not scriptCell then
        scriptCell = self.tScriptPlayerList[dwPlayerID]
    end
    if not nTotalCost then
        nTotalCost = self:GetTotalCost(dwPlayerID)
    end

    self.nTotalCost = nTotalCost
    for i = 1, #scriptCell.ImgCostPonits do
        UIHelper.SetVisible(scriptCell.ImgCostPonits[i], i <= nTotalCost)
    end
end

function UIMonsterBookDistribute:QuickDistribute(tMemberSkillIndex)
    for dwPlayerID, tSkillID in pairs(tMemberSkillIndex) do
        local scriptCell = self.tScriptPlayerList[dwPlayerID]
        if scriptCell then
            for _, dwSkillID in ipairs(tSkillID) do
                self.dwSelectSkillID = dwSkillID
                self:AddSkillToMemberCell(scriptCell, dwPlayerID, self.dwSelectSkillID, true)
            end
        end
    end
    self:UpdateBtnState()
end

function UIMonsterBookDistribute:UpdateSkillSelectState(bSelectChanged)
    if self.bMulti then        
        if bSelectChanged then
            local deSelectSkill = self.dwSelectSkillID or 0
            for dwSkillID, scriptSkillList in pairs(self.tScriptSkillList) do
                for _, scriptSkill in ipairs(scriptSkillList) do
                    scriptSkill:SetMultiSelected(deSelectSkill == dwSkillID)
                end
            end
        end        
    else
        for _, scriptSkill in pairs(self.tScriptSkillList) do
            UIHelper.SetCanSelect(scriptSkill.ToggleSelect, not self.dwSkillUsed, "请先取回已经分配给队员的临时技能")
        end
    end
end

function UIMonsterBookDistribute:GetSkillSelectCount()
    local nSelectCount = 0
    if self.bMulti then
        for dwSkillID, scriptSkillList in pairs(self.tScriptSkillList) do
            for _, scriptSkill in ipairs(scriptSkillList) do
                if scriptSkill.bMultiSelected then nSelectCount = nSelectCount + 1 end
            end
        end
    end
    return nSelectCount
end

function UIMonsterBookDistribute:UpdateBtnState()
    local bSelectSkill = self.dwSelectSkillID ~= nil
    UIHelper.SetVisible(self.LabelBeforeSelectSkill, not bSelectSkill)
    UIHelper.SetVisible(self.LabelAfterSelectSkill, bSelectSkill)
    if bSelectSkill and not self.dwSkillUsed then
        UIHelper.SetButtonState(self.BtnWarehouse, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnWarehouse, BTN_STATE.Disable, "请先选中技能")
    end

    UIHelper.SetVisible(self.BtnClose, self.bMulti)
    if self.dwSkillUsed then
        UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Disable, "请先完成技能分配")
    end
end

return UIMonsterBookDistribute