-- ---------------------------------------------------------------------------------
-- Author: liuyumin
-- Name: UIWidgetSpecialRelevanceSkill
-- Date: 2025-07-24 15:00:55
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetSpecialRelevanceSkill = class("UIWidgetSpecialRelevanceSkill")

function UIWidgetSpecialRelevanceSkill:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.tbSkillMainScript = self.tbSkillMainScript or UIHelper.AddPrefab(PREFAB_ID.WidgetSimpleSkill, self.SkillMain)
        self:SetMainSkillVisible(false)
    end

    self:UpdateInfo()
end

function UIWidgetSpecialRelevanceSkill:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSpecialRelevanceSkill:BindUIEvent()

end

function UIWidgetSpecialRelevanceSkill:RegEvent()
end

function UIWidgetSpecialRelevanceSkill:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSpecialRelevanceSkill:UpdateInfo()
    Event.UnRegAll(self)
    self.tbSkillChildScriptList = {}

    local bShow = false
    if not BattleFieldData.IsInTreasureBattleFieldMap() then
        bShow = true
        if SpecialDXSkillData.IsKungFuMatched({ 10176, 10175 }) and SpecialDXSkillData.IsHavePetSkill() then
            self:OpenWudu()
            --elseif SpecialDXSkillData.IsKungFuMatched({ 10062, 10026 }) then
            --    self:OpenTianCe()
        elseif SpecialDXSkillData.IsKungFuMatched(10225) then
            self:OpenTangMen_TianLuo()
        elseif SpecialDXSkillData.IsKungFuMatched(10615) then
            self:OpenYanTian()
        elseif SpecialDXSkillData.IsKungFuMatched(10533) then
            self:OpenPengLai()
        elseif SpecialDXSkillData.IsKungFuMatched({ 10447, 10448 }) then
            self:OpenChangGe()
        elseif SpecialDXSkillData.IsKungFuMatched({ 10014, 10015 }) then
            self:OpenChunYang()
        else
            bShow = false
        end

        if SpecialDXSkillData.IsKungFuMatched(10014) then
            UIHelper.AddPrefab(PREFAB_ID.WidgetChunYangSward, self.WidgetQCSwordParent)
        elseif SpecialDXSkillData.IsKungFuMatched({ 10626, 10627 }) then
            -- UIHelper.AddPrefab(PREFAB_ID.WidgetYaoZongCangJi, self.WidgetDaoZongParent)
        elseif SpecialDXSkillData.IsKungFuMatched(10268) then
            self:OpenGaiBang()
        elseif SpecialDXSkillData.IsKungFuMatched(10698) then
            UIHelper.AddPrefab(PREFAB_ID.WidgetDaoZongPoZhan, self.WidgetDaoZongParent)
        elseif SpecialDXSkillData.IsKungFuMatched(10028) then
            UIHelper.AddPrefab(PREFAB_ID.WidgetWanHuaBlackWhite, self.WidgetDaoZongParent)
        elseif SpecialDXSkillData.IsKungFuMatched(10756) then
            UIHelper.AddPrefab(PREFAB_ID.WidgetWanLingMaincity, self.WidgetDaoZongParent)
        elseif SpecialDXSkillData.IsKungFuMatched(10224) then   --唐门
            local tbScript = UIHelper.GetBindScript(self.WidgetTangMen)
            if tbScript then
                tbScript:OnEnter()
            end
        end

        -- if SpecialDXSkillData.IsKungFuMatched({ 10021, 10585, 10627, 10224 }) then
        --     UIHelper.AddPrefab(PREFAB_ID.WidgetSpecialSkillBuff, self.WidgetSpecialSkillBuffParent)  --buff监控
        -- end
    end
    if not bShow then
        self:RemoveMainSkill()
        self:RemoveChildrenSkill()
    end
end

function UIWidgetSpecialRelevanceSkill:UpdateMainSkill(nMainSkillID, nMainShortcutIndex)
    if self.tbSkillMainScript then
        UIHelper.SetActiveAndCache(self, self.SkillMain, true)
        self.tbSkillMainScript:InitSkill(nMainSkillID, nMainShortcutIndex)
        self:SetMainSkillVisible(true)
    end
end

function UIWidgetSpecialRelevanceSkill:RemoveMainSkill()
    if self.tbSkillMainScript then
        local widgetKeyBoard = UIHelper.FindChildByName(UIHelper.GetParent(self.tbSkillMainScript._rootNode), "WidgetKeyBoardKey")
        if widgetKeyBoard then
            local script = UIHelper.GetBindScript(widgetKeyBoard)
            script:SetID(-1)
            script:RefreshUI()
        end
        UIHelper.SetActiveAndCache(self, self.SkillMain, false)
    end
end

function UIWidgetSpecialRelevanceSkill:RemoveChildrenSkill()
    if self.tbSkillChildScriptList and not table.is_empty(self.tbSkillChildScriptList) then
        for k, v in pairs(self.tbSkillChildScriptList) do
            local parent = UIHelper.GetParent(v._rootNode)
            local widgetKeyBoard = UIHelper.FindChildByName(parent, "WidgetKeyBoardKey")
            if widgetKeyBoard then
                local script = UIHelper.GetBindScript(widgetKeyBoard)
                script:SetID(-1)
                script:RefreshUI()
            end
            UIHelper.RemoveFromParent(v._rootNode)
            UIHelper.SetVisible(parent, false)
        end
        self.tbSkillChildScriptList = {}
    end
end

function UIWidgetSpecialRelevanceSkill:SetMainSkillVisible(bVisible)
    if self.tbSkillMainScript then
        UIHelper.SetVisible(self.tbSkillMainScript._rootNode, bVisible)
    end
end

----------------------------------天策-----------------------------------------------

function UIWidgetSpecialRelevanceSkill:OpenTianCe()
    local nMainSkillID, nMainShortcutIndex = SpecialDXSkillData.GetTianCeMainSkill()
    self:UpdateMainSkill(nMainSkillID, nMainShortcutIndex)
    UIHelper.SetVisible(self.Widget4Skill, true)
end

----------------------------------五毒-----------------------------------------------
local function CorrectPetSkillMap(tSkill)
    local dwID, nLevel
    for _, v in pairs(tSkill) do
        dwID, nLevel = v[1], v[2]
        local szName = Table_GetSkillName(dwID, nLevel)
        if not szName then
            szName = Table_GetSkillName(dwID, 0)
        end

        if szName then
            g_PetSkillNameToID[UIHelper.GBKToUTF8(szName)] = dwID
            g_PetSkillNameToID[dwID] = dwID
        end
    end
end

function UIWidgetSpecialRelevanceSkill:OpenWudu()
    local nCurPetIndex = self.nCurPetIndex or 1
    self.dwNpcTemplateID = nil
    self:UpdateMainPet(nCurPetIndex)
    UIHelper.SetVisible(self.Widget4Skill, true)

    Event.Reg(self, "ON_UPDATE_TALENT", function()
        self:UpdatePetSkillIcon()
    end)

    Event.Reg(self, "OpenPetActionBar", function(dwNpcTemplateID)
        self:OpenPetSkillBar(dwNpcTemplateID)   --五毒召唤宠物技能
    end)

    Event.Reg(self, "PLAYER_ENTER_SCENE", function()
        local hPlayer = GetClientPlayer()
        if hPlayer and hPlayer.dwID == arg0 then
            self:HidePetSkillBar()
        end
    end)

    Event.Reg(self, "REMOVE_PET_TEMPLATEID", function()
        self:HidePetSkillBar()
    end)

    Event.Reg(self, "DO_SKILL_CAST", function(dwCaster, dwSkillID, dwLevel)
        local bMatch = dwCaster == UI_GetClientPlayerID()
        local KNpc = not bMatch and GetNpc(dwCaster)
        local dwEmployer = KNpc and KNpc.dwEmployer
        if bMatch or dwEmployer == UI_GetClientPlayerID() then
            local _, resIdx = table.find_if(SpecialDXSkillData.tCallUpPetSkill, function(nValue)
                return nValue == dwSkillID
            end)
            if resIdx then
                self:UpdateMainPet(resIdx)
            end

            if self.dwNpcTemplateID then
                self:UpdateChildSkillIcon(dwSkillID)
            end
        end
    end)
end

function UIWidgetSpecialRelevanceSkill:HidePetSkillBar()
    if not table.is_empty(self.tbSkillChildScriptList) then
        for k, script in pairs(self.tbSkillChildScriptList) do
            local parent = UIHelper.GetParent(script._rootNode)
            local widgetKeyBoard = UIHelper.FindChildByName(parent, "WidgetKeyBoardKey")
            if widgetKeyBoard then
                local script = UIHelper.GetBindScript(widgetKeyBoard)
                script:SetID(-1)
                script:RefreshUI()
            end
            UIHelper.SetVisible(parent, false)
            local tbCombineScript = script.skillCombineScript
            if tbCombineScript and tbCombineScript.tbCellScriptList then
                for k, tbSkillScript in pairs(tbCombineScript.tbCellScriptList) do
                    tbSkillScript:InitSkill()
                end
            end
        end
    end
end

function UIWidgetSpecialRelevanceSkill:OpenPetSkillBar(dwNpcTemplateID)
    if not dwNpcTemplateID then
        return
    end

    local tSkill = Table_GetPetSkill(dwNpcTemplateID)
    if not tSkill then
        return
    end

    self.nCount = #tSkill
    self.dwNpcTemplateID = dwNpcTemplateID
    self:UpdatePetSkillGroup(tSkill, dwNpcTemplateID)
    self:UpdatePetSkillBar()
    CorrectPetSkillMap(tSkill)
end

local function IsOldSkillID(dwSkillID)
    local bRet = false
    local tPetSkillChange = SpecialDXSkillData.GetPetSkillChangeList()
    for _, tChangeList in pairs(tPetSkillChange) do
        if dwSkillID == tChangeList.nOldSkillID then
            bRet = true
            break
        end
    end
    return bRet
end

local PET_NORMAL_SKILL_COUNT = 6
local tbSkillIndex2PrefabIndex = {
    [1] = 1,
    [2] = 1,
    [3] = 1,
    [4] = 2,
    [5] = 2,
    [6] = 2,
    [7] = 3,
    [8] = 3,
    [9] = 3,
}

function UIWidgetSpecialRelevanceSkill:UpdatePetSkillGroup(tSkill, dwNpcTemplateID)
    --分三组获取宠物技能
    SpecialDXSkillData.InitPetSkillChangeList(dwNpcTemplateID)

    SpecialDXSkillData.tCurrentPetSkill = {}
    local tPetSkillChange = SpecialDXSkillData.GetPetSkillChangeList()
    local tbPetSkillInfoList = {}   --9个宠物技能info
    for nIndex, tSkillData in ipairs(tSkill) do
        if (nIndex - 1) % 3 == 0 then
            local group = {}
            for i = nIndex, math.min(nIndex + 2, #tSkill) do
                local tSkillData = tSkill[i]
                local nOldSkillID = tSkillData[1]
                local nSkillID = tSkillData[1]
                local nOldSkillLevel = tSkillData[2]
                local nLevel = tSkillData[2]
                local nPrefabIndex = tbSkillIndex2PrefabIndex[i]

                if i > PET_NORMAL_SKILL_COUNT and IsOldSkillID(nSkillID) then
                    for _, tChangeList in pairs(tPetSkillChange) do
                        if SpecialDXSkillData.CheckPetSkillChange(tChangeList) then
                            nSkillID = tChangeList.nNewSkillID
                            break
                        end
                    end
                end

                local tbPetSkillInfo = {
                    nOldSkillID = nOldSkillID,
                    nSkillID = nSkillID,
                    nOldSkillLevel = nOldSkillLevel,
                    nLevel = nLevel,
                    nPrefabIndex = nPrefabIndex,
                }
                table.insert(group, tbPetSkillInfo)
                SpecialDXSkillData.tCurrentPetSkill[nSkillID] = true
            end
            table.insert(tbPetSkillInfoList, group)
        end
    end

    self.tbChildSkillGroupList = tbPetSkillInfoList
end

function UIWidgetSpecialRelevanceSkill:UpdatePetSkillIcon()
    local bChange = false
    if not self.dwNpcTemplateID then
        return
    end
    local tPetSkillChange = SpecialDXSkillData.GetPetSkillChangeList()
    for _, tChangeList in pairs(tPetSkillChange) do
        if SpecialDXSkillData.CheckPetSkillChange(tChangeList) then
            bChange = true
            local tSkill = Table_GetPetSkill(self.dwNpcTemplateID)
            for _, tSkillInfo in ipairs(tSkill) do
                if tSkillInfo[1] == tChangeList.nOldSkillID then
                    tSkillInfo[1] = tChangeList.nNewSkillID
                    break
                end
            end
            CorrectPetSkillMap(tSkill)
            self:UpdatePetSkillGroup(tSkill, self.dwNpcTemplateID)
            self:UpdatePetSkillBar()
            break
        end
    end

    if not bChange then
        local tSkill = Table_GetPetSkill(self.dwNpcTemplateID)
        CorrectPetSkillMap(tSkill)
    end
end

function UIWidgetSpecialRelevanceSkill:UpdatePetSkillBar()
    local tbPetSkillGroupList = self.tbChildSkillGroupList
    if not tbPetSkillGroupList or table.is_empty(tbPetSkillGroupList) then
        return
    end

    for i, tbSkillGroup in ipairs(tbPetSkillGroupList) do
        local nGroupIndex = i == 3 and 2 or 1
        local nChildSkillID = tbSkillGroup[nGroupIndex].nSkillID or 0
        local skillChildScript = (self.tbSkillChildScriptList and self.tbSkillChildScriptList[i]) or UIHelper.AddPrefab(PREFAB_ID.WidgetSimpleSkill, self.tbSkillChildList[i])
        local nPrefabIndex = tbSkillGroup[nGroupIndex].nPrefabIndex or 1
        local nChildShortcutIndex = SpecialDXSkillData.tPetSkillList[nPrefabIndex][nGroupIndex]
        if skillChildScript then
            skillChildScript:InitSkill(nChildSkillID, nChildShortcutIndex)
            skillChildScript:SetPetSkillGroup(tbSkillGroup)
            skillChildScript:UpdateCombineSkill()
            skillChildScript:UpdateFuncName(true)
            self.tbSkillChildScriptList[i] = skillChildScript
            UIHelper.SetVisible(self.tbSkillChildList[i], true)
        end
    end
end

function UIWidgetSpecialRelevanceSkill:UpdateMainPet(nIndex)
    if not nIndex or nIndex < 1 or nIndex > #SpecialDXSkillData.tPetList or self.nCurPetIndex == nIndex then
        return
    end

    self.nCurPetIndex = nIndex

    local nMainSkillID = SpecialDXSkillData.tPetList[nIndex].nSkillID
    local nMainShortcutIndex = SpecialDXSkillData.tPetList[nIndex].nShortcutIndex
    self:UpdateMainSkill(nMainSkillID, nMainShortcutIndex)
    self.tbSkillMainScript:SetWuDuSpecialSkill(true)
    self.tbSkillMainScript:UpdateCombineSkill()
end

function UIWidgetSpecialRelevanceSkill:UpdateChildSkillIcon(nSkillID)
    local list = self.tbChildSkillGroupList
    if not list or table.is_empty(list) then
        return
    end

    for i, tbSkillGroup in ipairs(list) do
        for j, tbSkillInfo in ipairs(tbSkillGroup) do
            if tbSkillInfo.nSkillID == nSkillID then
                local nPrefabIndex = tbSkillGroup[1].nPrefabIndex or 1
                local nChildShortcutIndex = SpecialDXSkillData.tPetSkillList[nPrefabIndex][j]
                local skillChildScript = self.tbSkillChildScriptList[i]
                if skillChildScript then
                    skillChildScript:InitSkill(nSkillID, nChildShortcutIndex)
                end
                break
            end
        end
    end
end

---------------------------千机变---------------------------------
local tbMainTemplateIDList = {
    16174, 16177
}

local function CorrectSkillMap(tSkill)
    local dwID, nLevel
    for _, v in pairs(tSkill) do
        dwID, nLevel = v[1], v[2]
        local szName = Table_GetSkillName(dwID, nLevel)
        if not szName then
            szName = Table_GetSkillName(dwID, 0)
        end

        if szName then
            g_PuppetSkillNameToID[UIHelper.GBKToUTF8(szName)] = dwID
            g_PuppetSkillNameToID[dwID] = dwID
        end
    end
end

function UIWidgetSpecialRelevanceSkill:OpenTangMen_TianLuo()
    self.tbSkillChildScriptList = {}
    UIHelper.SetVisible(self.Widget4Skill, true)
    Event.Reg(self, "OPEN_PUPPET_ACTIONBAR", function(dwNpcTemplateID)
        self:OpenPuppetActionBar(dwNpcTemplateID)
    end)

    Event.Reg(self, "REMOVE_PUPPET_TEMPLATEID", function()
        self:ClosePuppetActionBar()
    end)
end

function UIWidgetSpecialRelevanceSkill:OpenPuppetActionBar(dwNpcTemplateID)
    if not dwNpcTemplateID then
        return
    end

    local tSkill, tGroup = Table_GetPuppetSkill(dwNpcTemplateID)
    if dwNpcTemplateID == tbMainTemplateIDList[1] and not self.tbMainPuppetSkillList then
        self.tbMainPuppetSkillList = {}
        for i, v in ipairs(tSkill) do
            local nSkillID = v[1]
            local nLevel = v[2]
            table.insert(self.tbMainPuppetSkillList, { nSkillID, nLevel })-- 千机变三种形态切换技能
        end
    end
    self:SetMainSkillVisible(true)

    self.dwNpcTemplateID = dwNpcTemplateID
    g_PuppetSkillNameToID._puppet_open = true
    CorrectSkillMap(tSkill)

    local tbMainSkillList, tbChildSkillList = self:GetPuppetSKillGroup(dwNpcTemplateID, tSkill)
    self.tbMainSkillList = tbMainSkillList
    self:UpdateMainPuppetSKill(tbMainSkillList)
    self:UpdateChildPuppetSkill(tbChildSkillList)
end

function UIWidgetSpecialRelevanceSkill:GetPuppetSKillGroup(dwNpcTemplateID, tSkill)
    --按组获取当前千机变技能列表
    if not tSkill then
        return
    end

    local tbMainSkillList, tbChildSkillList = {}, {}
    if table.contain_value(tbMainTemplateIDList, dwNpcTemplateID) then
        --千机变形态,毒刹形态
        tbMainSkillList = tSkill
    else
        local tSkillIDSet = {}
        for _, v in ipairs(tSkill) do
            tSkillIDSet[v[1]] = true
        end

        -- 主技能列表：self.tbMainPuppetSkillList中存在且tSkill中也存在的技能
        for _, tbSkillInfo in ipairs(self.tbMainPuppetSkillList or {}) do
            local nSkillID, nLevel = tbSkillInfo[1], tbSkillInfo[2]
            if tSkillIDSet[nSkillID] then
                table.insert(tbMainSkillList, { nSkillID, nLevel })
            end
        end

        local tbMainSet = {}
        for _, tbSkillInfo in ipairs(self.tbMainPuppetSkillList or {}) do
            tbMainSet[tbSkillInfo[1]] = true
        end

        -- 子技能列表：tSkill中不在主技能集合中的技能
        for _, v in ipairs(tSkill) do
            local nSkillID = v[1]
            if not tbMainSet[nSkillID] then
                table.insert(tbChildSkillList, v)
            end
        end
    end

    return tbMainSkillList, tbChildSkillList
end

function UIWidgetSpecialRelevanceSkill:UpdateMainPuppetSKill(tbMainSkillList)
    if not tbMainSkillList or table.is_empty(tbMainSkillList) then
        return
    end

    local nSkillID = tbMainSkillList[1][1]
    local dwNpcTemplateID = self.dwNpcTemplateID
    local nShortcutIndex = SpecialDXSkillData.tPuppetShortcutIndexList[dwNpcTemplateID][1]
    local nLen = table.get_len(tbMainSkillList)
    if nLen > 1 then
        self.tbSkillMainScript:SetPuppetSkillGroup(tbMainSkillList, dwNpcTemplateID)
        self.tbSkillMainScript:UpdateCombineSkill()
        self:UpdateMainSkill(nSkillID, nShortcutIndex)
    else
        self.tbSkillMainScript:SetPuppetSkillGroup()
        self.tbSkillMainScript:UpdateCombineSkill()
        self:UpdateMainSkill(nSkillID, nShortcutIndex)
        self.tbSkillMainScript:UpdateFuncName(true)
    end
end

function UIWidgetSpecialRelevanceSkill:UpdateChildPuppetSkill(tbChildSkillList)
    if not tbChildSkillList or table.is_empty(tbChildSkillList) or table.get_len(tbChildSkillList) ~= 3 then
        self:RemoveChildrenSkill()
        return
    end

    local dwNpcTemplateID = self.dwNpcTemplateID

    for i, tbSkillInfo in ipairs(tbChildSkillList) do
        local nChildSkillID = tbSkillInfo[1] or 0
        local skillChildScript = (self.tbSkillChildScriptList and self.tbSkillChildScriptList[i]) or UIHelper.AddPrefab(PREFAB_ID.WidgetSimpleSkill, self.tbSkillChildList[i])
        local nChildShortcutIndex = SpecialDXSkillData.tPuppetShortcutIndexList[dwNpcTemplateID][i + 2]
        if skillChildScript then
            skillChildScript:InitSkill(nChildSkillID, nChildShortcutIndex)
            self.tbSkillChildScriptList[i] = skillChildScript
            UIHelper.SetVisible(self.tbSkillChildList[i], true)
        end
    end
end

function UIWidgetSpecialRelevanceSkill:ClosePuppetActionBar()
    self:RemoveMainSkill()
    self:SetMainSkillVisible(false)
    self:RemoveChildrenSkill()
    g_PuppetSkillNameToID._puppet_open = nil
end

---------------------------衍天---------------------------------

local YanTianModel = {}

function YanTianModel.Init(tLamps)
    YanTianModel.tDefaultAnchor = {}
    YanTianModel.tLamps = {}
    for i = 1, #tLamps do
        tLamps[i].nNpcID = nil
        YanTianModel.tLamps[i] = tLamps[i]
    end
end

function YanTianModel.UnInit()
    YanTianModel.tDefaultAnchor = nil
    YanTianModel.tLamps = nil
end

function YanTianModel.UpdateLampExist(nSkillID, nNpcID)
    for i = 1, #YanTianModel.tLamps do
        if YanTianModel.tLamps[i].id == nSkillID then
            YanTianModel.tLamps[i].nNpcID = nNpcID
            return
        end
    end
end

function UIWidgetSpecialRelevanceSkill:OpenYanTian()
    UIHelper.SetVisible(self.Widget4Skill, true)
    Event.Reg(self, "DELETE_ONE_LAMP", function()
        local nSkillID = arg0
        YanTianModel.UpdateLampExist(nSkillID, nil)
        self:UpdateLamp()

    end)

    Event.Reg(self, "ADD_ONE_LAMP", function()
        local nSkillID, nNpcID = arg0, arg1
        YanTianModel.UpdateLampExist(nSkillID, nNpcID)
        self:UpdateLamp()
    end)

    Event.Reg(self, "OpenTianZongSoullampBar", function(tLampList)
        YanTianModel.Init(tLampList)
        self:UpdateLamp()
    end)
end

function UIWidgetSpecialRelevanceSkill:UpdateLamp()
    local nCount = #YanTianModel.tLamps
    if nCount == 0 then
        self:RemoveChildrenSkill()
        return
    end
    local tShortcutList = { 120, 121, 122 }

    for i, tbLampInfo in ipairs(YanTianModel.tLamps) do
        local skillChildScript = self.tbSkillChildScriptList[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetSimpleSkill, self.tbSkillChildList[i])
        self.tbSkillChildScriptList[i] = skillChildScript

        if tbLampInfo.nNpcID then
            local nChildSkillID = tbLampInfo.id
            local nChildShortcutIndex = tShortcutList[i]
            skillChildScript:InitSkill(nChildSkillID, nChildShortcutIndex)
        else
            skillChildScript:InitSkill(nil, -1)
        end

        if self.tbSkillChildScriptList[i] then
            self.tbSkillChildScriptList[i]:SetSkillVisible(tbLampInfo.nNpcID ~= nil)
        end
    end
end

---------------------------长歌---------------------------------

function UIWidgetSpecialRelevanceSkill:OpenChangGe()
    UIHelper.SetVisible(self.Widget4Skill, true)
    Event.Reg(self, "UPDATE_NEW_SHADOW", function()
        self:UpdateShadowBar(arg0)
    end)

    Event.Reg(self, "DELETE_ONE_SHADOW", function()
        local tSkills = self:DeleteOneShadow(arg0)
        self:UpdateShadowBar(tSkills)
    end)

    Event.Reg(self, "ADD_ONE_SHADOW", function()
        local tSkills = self:AddOneShadow(arg0, arg1, arg2, arg3)
        self:UpdateShadowBar(tSkills)
    end)

    Event.Reg(self, "OPEN_CHANGGE_SHADOWBAR", function(tShadowList)
        self:UpdateShadowBar(tShadowList)
    end)

    Event.Reg(self, "CLOSE_CHANGGE_SHADOWBAR", function()
        self:CloseShadowBar()
    end)
end

function UIWidgetSpecialRelevanceSkill:UpdateShadowBar(tShadowList)
    if not tShadowList or table.is_empty(tShadowList) then
        if self.tbSkillMainScript.skillCombineScript then
            self.tbSkillMainScript.skillCombineScript:UnInitShadowSkill()
        end
        return
    end

    self.tShadowList = tShadowList
    local nCount = table.get_len(tShadowList)

    if nCount > 0 then
        local nSkillID = tShadowList[1].id
        local nShortcutIndex = SpecialDXSkillData.tShadowShortcutIndexList[1]
        local nBuff = tShadowList[1].buff
        self.tbSkillMainScript:SetShadowSkillGroup(tShadowList)
        self.tbSkillMainScript:UpdateCombineSkill()
        self:UpdateMainSkill(nSkillID, nShortcutIndex)
        local szIcon, szSecondIcon = SpecialDXSkillData.GetSkillIconByBuff(nBuff)
        if szIcon and szSecondIcon then
            self.tbSkillMainScript:UpdateIcon(szIcon, szSecondIcon)
        end
        SpecialDXSkillData.SetSkillBuffTimeEnd(nSkillID, nBuff)
    end
end

function UIWidgetSpecialRelevanceSkill:CloseShadowBar()
    self:UpdateShadowBar()
    self:RemoveMainSkill()
    self:SetMainSkillVisible(false)
    self:RemoveChildrenSkill()
end

function UIWidgetSpecialRelevanceSkill:DeleteOneShadow(dwSkillID)
    local tList = {}
    local nCount = table.get_len(self.tShadowList)
    if nCount <= 0 then
        return tList
    end

    SpecialDXSkillData.ClearSkillBuffTimeEnd(dwSkillID)

    for i = 1, nCount, 1 do
        local tSkill = self.tShadowList[i]
        if tSkill.id and dwSkillID ~= tSkill.id then
            table.insert(tList, { id = tSkill.id,
                                  level = tSkill.level,
                                  dwNpcID = tSkill.dwNpcID,
                                  buff = tSkill.buff or 0,
            })
        end
    end

    return tList
end

function UIWidgetSpecialRelevanceSkill:AddOneShadow(dwSkillID, dwNpcID, bNotJudge, dwBuff)
    local tList = self.tShadowList or {}
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    SpecialDXSkillData.ClearSkillBuffTimeEnd(dwSkillID)

    local dwLevel = hPlayer.GetSkillLevel(dwSkillID)
    if dwLevel == 0 then
        dwLevel = 1
    end
    table.insert(tList, { id = dwSkillID, level = dwLevel, dwNpcID = dwNpcID, buff = dwBuff })

    return tList
end


---------------------------蓬莱---------------------------------

local PengLaiModel = {}

function PengLaiModel.Init()
    PengLaiModel.tActionBarData = {}
    PengLaiModel.tSkillData = Table_GetPLActionBarSkill()
    PengLaiModel.UpdateSkills()
end

function PengLaiModel.UnInit()
    PengLaiModel.tSkillData = nil
    PengLaiModel.tShowSkills = nil
    PengLaiModel.tActionBarData = nil
end

function PengLaiModel.GetShowSkills()
    local pPlayer = GetClientPlayer()
    PengLaiModel.tShowSkills = {}
    for _, tSkillInfo in ipairs(PengLaiModel.tSkillData) do
        local nSkillLevel = tSkillInfo.nSkillLevel
        if nSkillLevel > 0 or tSkillInfo.bIsPermanent then
            if nSkillLevel < 1 then
                nSkillLevel = 1
            end
            local pSkill = GetSkill(tSkillInfo.nSkillID, nSkillLevel)
            local tKungfu = pPlayer.GetActualKungfuMount()
            if not tKungfu then
                return
            end
            if pSkill and pSkill.dwBelongSchool == tKungfu.dwMountType then
                table.insert(PengLaiModel.tShowSkills, { nSkillID = tSkillInfo.nSkillID, nSkillLevel = tSkillInfo.nSkillLevel })
            end
        end
    end
end

function PengLaiModel.UpdateSkills()
    local pPlayer = GetClientPlayer()
    for _, tSkillInfo in ipairs(PengLaiModel.tSkillData) do
        tSkillInfo.nSkillLevel = pPlayer.GetSkillLevel(tSkillInfo.nSkillID)
    end
    PengLaiModel.GetShowSkills()
end

function PengLaiModel.ReplaceSkill(nOldSkillID, nNewSkillID)
    local pPlayer = GetClientPlayer()
    for _, tSkillInfo in ipairs(PengLaiModel.tSkillData) do
        if tSkillInfo.nSkillID == nOldSkillID then
            tSkillInfo.nSkillID = nNewSkillID
            tSkillInfo.nSkillLevel = pPlayer.GetSkillLevel(tSkillInfo.nSkillID)
        end
    end
    PengLaiModel.GetShowSkills()
end

function UIWidgetSpecialRelevanceSkill:OpenPengLai()
    Event.Reg(self, "SKILL_UPDATE", function()
        PengLaiModel.UpdateSkills()
        self:UpdatePengLaiSkills()
    end)

    Event.Reg(self, "CHANGE_SKILL_ICON", function(nOldSkillID, nNewSkillID)
        PengLaiModel.ReplaceSkill(nOldSkillID, nNewSkillID)
    end)

    Event.Reg(self, "ON_SKILL_REPLACE", function(nOldSkillID, nNewSkillID)
        PengLaiModel.ReplaceSkill(nOldSkillID, nNewSkillID)
    end)
    PengLaiModel.Init()
    PengLaiModel.GetShowSkills()
    self:UpdatePengLaiSkills()

    UIHelper.SetVisible(self.Widget5Skill, true)
end

function UIWidgetSpecialRelevanceSkill:UpdatePengLaiSkills()
    local nCount = #PengLaiModel.tShowSkills
    if nCount == 0 then
        self:RemoveChildrenSkill()
        return
    end
    local tShortcutList = { 120, 121, 122, 123, 124, 125 }

    for i, tbSkillInfo in ipairs(PengLaiModel.tShowSkills) do
        local skillChildScript = self.tbSkillChildScriptList[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetSimpleSkill, self.tbFiveChildSkillList[i])
        self.tbSkillChildScriptList[i] = skillChildScript

        local nChildSkillID = tbSkillInfo.nSkillID
        local nChildShortcutIndex = tShortcutList[i]
        skillChildScript:InitSkill(nChildSkillID, nChildShortcutIndex)
    end

    for nIndex, skillChildScript in ipairs(self.tbSkillChildScriptList) do
        local tInfo = PengLaiModel.tShowSkills[nIndex]
        if not tInfo then
            skillChildScript:InitSkill(nil, -1)
        end
        skillChildScript:SetSkillVisible(tInfo ~= nil)
    end
end

---------------------------丐帮---------------------------------
function UIWidgetSpecialRelevanceSkill:OpenGaiBang()
    Event.Reg(self, EventType.OnUpdateGaibangComboVisible, function(bShow)
        UIHelper.RemoveAllChildren(self.WidgetGaiBangParent)
        if bShow then
            UIHelper.AddPrefab(PREFAB_ID.WidgetGaiBangLianZhao, self.WidgetGaiBangParent)
        end
    end)

    local bShow = GameSettingData.GetNewValue(UISettingKey.ShowGaiBangCombo)
    if bShow then
        UIHelper.AddPrefab(PREFAB_ID.WidgetGaiBangLianZhao, self.WidgetGaiBangParent)
    end
end

---------------------------纯阳---------------------------------

local CYModel = {}

function CYModel.Init()
    CYModel.tGasList = {}
    CYModel.tAllGasConfig = Table_GetGasConfig()
end

function CYModel.GetGasConfig(dwTemplateID)
    local dwMKungfuID = UI_GetPlayerMountKungfuID()
    local tList = CYModel.tAllGasConfig[dwMKungfuID]
    if not tList then
        return
    end
    for _, tGasInfo in pairs(tList) do
        if tGasInfo.dwTemplateID == dwTemplateID then
            return tGasInfo
        end
    end
    return nil
end

function CYModel.RemoveGas(dwNPCID)
    for i, tGasInfo in pairs(CYModel.tGasList) do
        if tGasInfo.dwNPCID == dwNPCID then
            table.remove(CYModel.tGasList, i)
            break
        end
    end
end

function CYModel.UnInit()
    CYModel.tGasList = {}
end

function UIWidgetSpecialRelevanceSkill:OpenChunYang()
    CYModel.Init()
    UIHelper.SetVisible(self.Widget4Skill, true)

    Event.Reg(self, "OnUpdateCYGas", function(tGasInfo)
        if tGasInfo.nEndTime then
            table.insert(CYModel.tGasList, tGasInfo)
        else
            for i, tGas in pairs(CYModel.tGasList) do
                if tGas.dwNPCID == tGasInfo.dwNPCID then
                    table.remove(CYModel.tGasList, i)
                    break
                end
            end
        end
        self:UpdateChunYang()
    end)

end

function UIWidgetSpecialRelevanceSkill:UpdateChunYang()
    local tGasList = CYModel.tGasList
    if #tGasList == 0 then
        self:RemoveChildrenSkill()
        return
    end

    for i = 1, 3 do
        local tGasInfo = tGasList[i]
        local parent = self.tbSkillChildList[i]
        if tGasInfo and tGasInfo.nEndTime then
            local skillChildScript = self.tbSkillChildScriptList[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetChunYangQiChang, parent)
            self.tbSkillChildScriptList[i] = skillChildScript
            local tConfig = CYModel.GetGasConfig(tGasInfo.dwTemplateID)
            tGasInfo.dwSkillID = tConfig.dwSkillID
            skillChildScript:UpdateQiChangInfo(tGasInfo)

            local nParentScale = UIHelper.GetScaleX(parent)
            UIHelper.SetScale(skillChildScript._rootNode, 1 / nParentScale, 1 / nParentScale)
        end
        UIHelper.SetVisible(parent, tGasInfo and tGasInfo.nEndTime ~= nil)
    end
end

return UIWidgetSpecialRelevanceSkill