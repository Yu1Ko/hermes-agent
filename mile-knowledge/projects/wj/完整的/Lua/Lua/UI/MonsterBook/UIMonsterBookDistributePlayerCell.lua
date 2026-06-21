local UIMonsterBookDistributePlayerCell = class("UIMonsterBookDistributePlayerCell")
local SKILL_BOX_LIMIT     = 3 -- 每个成员可分配技能种数
function UIMonsterBookDistributePlayerCell:OnEnter(tInfo, fCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if tInfo.dwID ~= UI_GetClientPlayerID() then
        local hPlayer = GetPlayer(self.dwPlayerID)
        if hPlayer then
            local dwCenter = GetCenterID() or 0
            local szGlobalID = hPlayer.GetGlobalID() 
            if szGlobalID then
                PeekOtherPlayerSkillCollection(dwCenter, szGlobalID)
            end
        end
    end

    self.tSkillIDMap = {}
    self.fCallBack = fCallBack
    self:UpdateInfo(tInfo)
end

function UIMonsterBookDistributePlayerCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMonsterBookDistributePlayerCell:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnClick, function ()
        self.fCallBack()
    end)
end

function UIMonsterBookDistributePlayerCell:RegEvent()
    Event.Reg(self, EventType.OnMonsterBookSelectTempSkillChange, function (dwSkillID)
        dwSkillID = dwSkillID or 0
        local nLevel = 0
        local player = GetPlayer(self.dwPlayerID)
        if player then
            local tCollectionedSkill = player.GetAllSkillInCollection() or {}
            local dwOutSkillID = MonsterBookData.tIn2OutSkillMap[dwSkillID]
            nLevel = tCollectionedSkill[dwOutSkillID] or 0
        end
        local bHasSelected = dwSkillID ~= 0
        UIHelper.SetString(self.LabelCostAll, "已消耗")
        if bHasSelected then
            local szSkillName = Table_GetSkillName(dwSkillID, nLevel)
            szSkillName = UIHelper.GBKToUTF8(szSkillName)
            local szSkillLevel = "未收集"
            if nLevel > 0 then
                szSkillLevel = string.format("已收集：%s重", g_tStrings.tChineseNumber[nLevel])
            end

            UIHelper.SetString(self.LabelCostAll, szSkillName)
            UIHelper.SetString(self.LabelLevel, szSkillLevel)
        end
        UIHelper.SetVisible(self.LabelLevel, bHasSelected)
        UIHelper.SetVisible(self.LayoutCostAll, not bHasSelected)
    end)
end

function UIMonsterBookDistributePlayerCell:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIMonsterBookDistributePlayerCell:UpdateInfo(tInfo)
    self.dwPlayerID = tInfo.dwID
    self.tSkillID, self.tSkillLevel = tInfo.tSkillID, tInfo.tSkillLevel
    self.UnCollectedSkillList = tInfo.UnCollectedSkillList
    local szName = UIHelper.GBKToUTF8(tInfo.szName)
    local szImagePath = PlayerForceID2SchoolImg2[tInfo.dwForceID]
    
    local _, szNewName = GetStringCharCountAndTopChars(szName, 5)
    if #szNewName < #szName then
        szName = szNewName .. "..."
    end
    UIHelper.SetString(self.LabelName, szName)
    UIHelper.SetTexture(self.ImgSchool, szImagePath)
    UIHelper.SetSpriteFrame(self.ImgSchool, szImagePath)

    self.nSkillCount = 0
    self.tScritpList = {}
    UIHelper.RemoveAllChildren(self.LayoutSkillBox)
    for i = 1, SKILL_BOX_LIMIT do
        local scriptSkill = UIHelper.AddPrefab(PREFAB_ID.WidgetBZSkillPlayerItem, self.LayoutSkillBox)
        scriptSkill:OnEnter(0, 0, nil)
        self.tScritpList[i] = scriptSkill
    end
    UIHelper.LayoutDoLayout(self.LayoutSkillBox)
end

function UIMonsterBookDistributePlayerCell:AllocSkillSolt(dwSkillID, nLevel, fRemoveCallBack)
    local scriptSkill
    if self.tSkillIDMap[dwSkillID] then
        local nIndex = self.tSkillIDMap[dwSkillID]
        scriptSkill = self.tScritpList[nIndex]
        scriptSkill:OnEnter(dwSkillID, nLevel, fRemoveCallBack)
    elseif self.nSkillCount < #self.tScritpList then
        self.nSkillCount = self.nSkillCount + 1
        scriptSkill = self.tScritpList[self.nSkillCount]
        scriptSkill:OnEnter(dwSkillID, nLevel, fRemoveCallBack)
        self.tSkillIDMap[dwSkillID] = self.nSkillCount
    end
    
    return scriptSkill
end

function UIMonsterBookDistributePlayerCell:ClearAllSkillSolt()
    if self.nSkillCount == 0 then
        return
    end    
    self.tSkillIDMap = {}
    for i = 1, self.nSkillCount do
        local scriptSkill = self.tScritpList[self.nSkillCount]
        scriptSkill:OnEnter(0, 0)
    end
    self.nSkillCount = 0
end

return UIMonsterBookDistributePlayerCell