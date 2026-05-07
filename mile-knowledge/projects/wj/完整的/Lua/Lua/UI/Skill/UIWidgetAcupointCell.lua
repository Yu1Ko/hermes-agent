-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSkillConfigurationCell
-- Date: 2022-11-23 10:01:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

local nMaxLimit = 3

---@class UIWidgetAcupointCell
local UIWidgetAcupointCell = class("UIWidgetAcupointCell")

function UIWidgetAcupointCell:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self.bInit = true
    end
    
    self:RegEvent()
end

function UIWidgetAcupointCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetAcupointCell:BindUIEvent()
    if self.BtnApplyMix then
        UIHelper.BindUIEvent(self.BtnApplyMix, EventType.OnClick, function()
            self:ApplyMixedQixue()
        end)
    end
end

function UIWidgetAcupointCell:RegEvent()
end

function UIWidgetAcupointCell:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
local szColor = "#D7F6FF"

function UIWidgetAcupointCell:UpdateInfo(tQixue, bDisplayOnly)
    local hPlayer = g_pClientPlayer
    local bQixueSelected = false
    self:Reset()
    self.tScripts = {}
    
    if tQixue then
        local bIsDouqi = tQixue.nType == SkillData.DouqiQixueType
        UIHelper.SetActiveAndCache(self, self.LayoutSkill1, not bIsDouqi)
        UIHelper.SetActiveAndCache(self, self.LayoutSkill2, bIsDouqi)
        UIHelper.SetActiveAndCache(self, self.LayoutSkillGridVK, bIsDouqi)
        UIHelper.SetActiveAndCache(self, self.LayoutSkillGridDX, false)
        UIHelper.SetActiveAndCache(self, self.WidgetDouqiTitle1, bIsDouqi)
        UIHelper.SetActiveAndCache(self, self.WidgetDouqiTitle2, bIsDouqi)
        
        local dwPointID = tQixue.dwPointID
        local nRequireLevel = tQixue.nRequireLevel
        local nSelectIndex = tQixue.nSelectIndex
        local tSkillArray = tQixue.SkillArray
        local tDefaultLayout = bIsDouqi and self.LayoutSkillGridVK or self.LayoutSkill1
        bQixueSelected = nSelectIndex > 0

        for index = 1, #tSkillArray do
            local tTheSkill = tSkillArray[index]
            local nSkillID = tTheSkill.dwSkillID
            local nSkillLevel = tTheSkill.dwSkillLevel
            local dwSkillColor = tTheSkill.dwSkillColor
            local tSkill = nSkillID > 0 and GetSkill(nSkillID, nSkillLevel)
            local parent = index == tQixue.nSpecialIndex and self.LayoutSkill2 or tDefaultLayout
            
            local nPrefabID = tSkill.bIsPassiveSkill and PREFAB_ID.WidgetSkillPassiveCell or PREFAB_ID.WidgetSkillCell1
            local script = UIHelper.AddPrefab(nPrefabID, parent, nSkillID)
            UIHelper.SetScale(script._rootNode, 0.7, 0.7)
            UIHelper.SetAnchorPoint(script._rootNode, 0.5, 0.5)
           
            script:ShowName(true)
            script:SetQixueBg(dwSkillColor)
            script:SetUsed(nSelectIndex == index)

            if hPlayer and bDisplayOnly ~= true and hPlayer.nLevel < SKILL_RESTRICTION_LEVEL then
                UIHelper.SetNodeGray(script.TogSkill, true, true)
                script:BindSelectFunction(function()
                    TipsHelper.ShowNormalTip("侠士达到106级后方可切换奇穴")
                    Timer.AddFrame(self, 1, function()
                        script:SetSelected(false)
                    end)
                end)
            else
                script:ShowName(true)
                script:BindSelectFunction(function()
                    self.fnFunc(index)
                end)
            end
            table.insert(self.tScripts, script)
        end
    end
    
    UIHelper.SetVisible(self.ImgHintEquip, not bQixueSelected and hPlayer.nLevel >= SKILL_RESTRICTION_LEVEL)
    UIHelper.SetVisible(self.LabelLevelLock, bDisplayOnly ~= true and hPlayer.nLevel < SKILL_RESTRICTION_LEVEL)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function UIWidgetAcupointCell:UpdateInfoDX(tQixue, tTipParent, bDisplayOnly)
    local hPlayer = g_pClientPlayer
    local bQixueSelected = false
    self:Reset()
    self.tScripts = {}

    if tQixue then
        local bIsDouqi = tQixue.nType == SkillData.DouqiQixueType
        UIHelper.SetActiveAndCache(self, self.LayoutSkill1, not bIsDouqi)
        UIHelper.SetActiveAndCache(self, self.LayoutSkill2, bIsDouqi)
        UIHelper.SetActiveAndCache(self, self.LayoutSkillGridDX, bIsDouqi)
        UIHelper.SetActiveAndCache(self, self.LayoutSkillGridVK, false)
        UIHelper.SetActiveAndCache(self, self.WidgetDouqiTitle1, bIsDouqi)
        UIHelper.SetActiveAndCache(self, self.WidgetDouqiTitle2, bIsDouqi)
        
        local nSelectIndex = tQixue.nSelectIndex
        local tSkillArray = tQixue.SkillArray
        local dwPointID = tQixue.dwPointID
        local nRequireLevel = tQixue.nRequireLevel
        local tDefaultLayout = bIsDouqi and self.LayoutSkillGridDX or self.LayoutSkill1
        bQixueSelected = nSelectIndex > 0
        
        for index = 1, #tSkillArray do
            local tTheSkill = tSkillArray[index]
            local nSkillID = tTheSkill.dwSkillID
            local nSkillLevel = tTheSkill.dwSkillLevel
            local dwSkillColor = tTheSkill.dwSkillColor
            local tSkill = nSkillID > 0 and GetSkill(nSkillID, nSkillLevel)
            local bMatchColor = tQixue.nType == TALENT_SELECTION_TYPE.CORE or (dwSkillColor == 0 or dwSkillColor == self.dwCoreSkillColor)
            local parent = index == tQixue.nSpecialIndex and self.LayoutSkill2 or tDefaultLayout
            
            if nSkillID > 0 and tSkill then
                local nPrefabID = tSkill.bIsPassiveSkill and PREFAB_ID.WidgetSkillPassiveCell or PREFAB_ID.WidgetSkillCell1
                local script = UIHelper.AddPrefab(nPrefabID, parent, nSkillID)
                UIHelper.SetScale(script._rootNode, 0.7, 0.7)
                UIHelper.SetAnchorPoint(script._rootNode, 0.5, 0.5)
                script:ShowName(true)
                script:SetQixueBg(dwSkillColor)
                
                local fnShowTips = function(nSubIndex, bHideButton)
                    local fnClose = function()
                        return self:UnSelectAll()
                    end
                    
                    local fnChangeQiXue = function()
                        return SkillData.ChangeQiXue(dwPointID, nSubIndex)
                    end

                    local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetAcupointTip, tTipParent, TipsLayoutDir.MIDDLE)
                    script:Init(tTheSkill, nSelectIndex == nSubIndex, fnChangeQiXue, fnClose, nil)
                    script:ShowQixueCost(tQixue.nCostTrain)
                    if bHideButton then
                        script:HideButton()
                    end
                end

                if not bMatchColor or (hPlayer and bDisplayOnly ~= true and hPlayer.nLevel < nRequireLevel) then
                    UIHelper.SetNodeGray(script.TogSkill, true, true)
                    script:BindSelectFunction(function()
                        fnShowTips(index, true)
                        local szErrorMsg = not bMatchColor and "与核心奇穴套路不同，不可用" or string.format("侠士达到%d级后方可切换该奇穴", nRequireLevel)
                        TipsHelper.ShowNormalTip(szErrorMsg)
                    end)
                else
                    script:BindSelectFunction(function()
                        fnShowTips(index, bDisplayOnly)
                    end)
                end
                UIHelper.SetSwallowTouches(script.TogSkill, false)
                table.insert(self.tScripts, script)
            end
        end

        if nSelectIndex > 0 then
            self.tScripts[nSelectIndex]:SetUsed(true)
        end

        UIHelper.SetVisible(self.ImgHintEquip, not bQixueSelected and hPlayer.nLevel >= nRequireLevel)
        UIHelper.SetVisible(self.LabelLevelLock, bDisplayOnly ~= true and hPlayer.nLevel < nRequireLevel)
        UIHelper.SetString(self.LabelLevelLock, string.format("(需%d级解锁)", nRequireLevel))
    end

   
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function UIWidgetAcupointCell:UpdateInfoDXMixed(tQiXueList, bIsKungFuMatched, tTipParent, bDisplayOnly)
    self:Reset()
    UIHelper.SetActiveAndCache(self, self.LayoutSkill1, false)
    UIHelper.SetActiveAndCache(self, self.LayoutSkill1, false)
    UIHelper.SetActiveAndCache(self, self.LayoutSkillGridDX, true)
    UIHelper.SetActiveAndCache(self, self.LayoutSkillGridVK, false)
    
    local hPlayer = g_pClientPlayer
    local tMixQixue = tQiXueList[#tQiXueList] --最后三层都是混合奇穴，skill一致，直接取最后一层
    if not tMixQixue then
        return
    end
    local nRequireLevel = tMixQixue.nRequireLevel or 0
    local tMixSkillArray = tMixQixue.SkillArray
    local bQixueSelected = false
    local parent = self.LayoutSkillGridDX

    self.tMixSelected = {}
    self.tMixPointSelected = {}
    for _, tQixue in ipairs(tQiXueList) do
        if tQixue.nType == TALENT_SELECTION_TYPE.MIXED then
            self.tMixSelected[tQixue.nSelectIndex] = true
            self.tMixPointSelected[tQixue.dwPointID] = tQixue.nSelectIndex
            if tQixue.nSelectIndex > 0 then
                bQixueSelected = true
            end
        end
    end

    self.tScripts = {}
    self.tChooseMixQixue = {}
    self.nMixCostTrain = tMixQixue.nCostTrain

    local fnShowTips = function(nSubIndex)
        local tSkill = tMixQixue.SkillArray[nSubIndex]
        local nSkillID = tSkill.dwSkillID
        local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetAcupointTip, tTipParent, TipsLayoutDir.MIDDLE)
        script:Init(tSkill)
        script:HideButton()
    end

    if tMixQixue then
        for index = 1, #tMixSkillArray do
            local theSkill = tMixSkillArray[index]
            local nSkillID = theSkill.dwSkillID
            local nSkillLevel = theSkill.dwSkillLevel
            local dwSkillColor = theSkill.dwSkillColor
            local nSkillRequireLevel = math.max(tMixSkillArray[index].nRequireLevel, nRequireLevel)
            local tSkill = nSkillID > 0 and GetSkill(nSkillID, nSkillLevel)
            local bMatchColor = tMixQixue.nType == TALENT_SELECTION_TYPE.CORE or (dwSkillColor == 0 or dwSkillColor == self.dwCoreSkillColor)
            local dwQuestID = theSkill.dwRequireQuestID
            local bQuestFinished = dwQuestID <= 0 or hPlayer.GetQuestState(dwQuestID) == QUEST_STATE.FINISHED
            
            if nSkillID > 0 and tSkill then
                local nPrefabID = tSkill.bIsPassiveSkill and PREFAB_ID.WidgetSkillPassiveCell or PREFAB_ID.WidgetSkillCell1
                local script = UIHelper.AddPrefab(nPrefabID, parent)
                script:UpdateInfo(nSkillID)
                script:ShowName(true)
                script:SetQixueBg(dwSkillColor)
                script:SetUsed(self.tMixSelected[index] or false)
                
                UIHelper.SetScale(script._rootNode, 0.7, 0.7)
                UIHelper.SetAnchorPoint(script._rootNode, 0.5, 0.5)
                UIHelper.SetSwallowTouches(script.TogSkill, false)

                if not bMatchColor or not bQuestFinished or (hPlayer and bDisplayOnly ~= true and hPlayer.nLevel < nSkillRequireLevel) then
                    local szErrorMsg = "与核心奇穴套路不同，不可用"
                    if bMatchColor then
                        szErrorMsg = string.format("侠士达到%d级后方可切换该奇穴", nRequireLevel)
                        script:ShowLearnLevel(nSkillRequireLevel)
                    end
                    if not bQuestFinished then
                        local tQuestString = Table_GetQuestStringInfo(dwQuestID)
                        szErrorMsg = FormatString(g_tStrings.TALENT_LOCK_BY_QUEST_TIP, UIHelper.GBKToUTF8(tQuestString.szName))
                        script:ShowQuest(false)
                    end
                    UIHelper.SetNodeGray(script.TogSkill, true, true)
                    script:BindSelectFunction(function()
                        fnShowTips(index)
                        TipsHelper.ShowNormalTip(szErrorMsg)
                        Timer.AddFrame(self, 1, function()
                            script:SetSelected(false)
                        end)
                    end)
                else
                    UIHelper.BindUIEvent(script.TogSkill, EventType.OnSelectChanged, function(toggle, bSelected)
                        if bSelected then
                            fnShowTips(index)
                        end

                        if not bDisplayOnly then
                            if bSelected then
                                if #self.tChooseMixQixue >= nMaxLimit then
                                    Timer.AddFrame(self, 1, function()
                                        TipsHelper.ShowNormalTip("最多只能选择三个奇穴")
                                        script:SetSelected(false)
                                    end)
                                    return
                                else
                                    table.insert(self.tChooseMixQixue, index)
                                end
                            else
                                table.remove_value(self.tChooseMixQixue, index)
                            end
                            self:RefreshMixedQixue()
                        end
                    end)
                end
                table.insert(self.tScripts, script)

                if self.tMixSelected[index] and bIsKungFuMatched then
                    table.insert(self.tChooseMixQixue, index)
                    UIHelper.SetSelected(script.TogSkill, true, false)
                end
            end
        end
    end

    self:RefreshMixedQixue()
    UIHelper.SetVisible(self.ImgHintEquip, not bQixueSelected and hPlayer.nLevel >= nRequireLevel)
    UIHelper.SetVisible(self.LabelLevelLock, bDisplayOnly ~= true and hPlayer.nLevel < nRequireLevel)
    UIHelper.SetVisible(self.WidgetBtnApplyMix, bIsKungFuMatched and bDisplayOnly ~= true and hPlayer.nLevel >= nRequireLevel)
    UIHelper.SetString(self.LabelLevelLock, string.format("(需%d级解锁)", nRequireLevel))

    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function UIWidgetAcupointCell:GetMixQixueCost()
    local nCost = 0
    for _, nIndex in ipairs(self.tChooseMixQixue) do
        if not self.tMixSelected[nIndex] then
            nCost = nCost + self.nMixCostTrain
        end
    end
    return nCost
end

function UIWidgetAcupointCell:ApplyMixedQixue()
    local tSelectQixue = self.tChooseMixQixue or {}
    local tMixSelected = self.tMixSelected
    local tMixPointSelected = clone(self.tMixPointSelected) or {}

    local function fnSelectMixQixue()
        local hPlayer = g_pClientPlayer
        if hPlayer.bOnHorse then
            TipsHelper.ShowImportantRedTip(g_tStrings.SELECT_TALENT_ERROR_ONHORSE)
        else
            local tConfirmList = {}
            for _, nSetIndex in ipairs(tSelectQixue) do
                if not tMixSelected[nSetIndex] then
                    for dwPointID, nSelectedIndex in pairs(tMixPointSelected) do
                        if not CheckIsInTable(tSelectQixue, nSelectedIndex) then
                            local nRetCode = hPlayer.CanSelectNewTalentPoint(dwPointID, nSetIndex)
                            if nRetCode == SELECT_TALENT_RESULT.SUCCESS then
                                table.insert(tConfirmList, { dwPointID, nSetIndex })
                                tMixPointSelected[dwPointID] = nSetIndex
                                break
                            else
                                TipsHelper.ShowImportantRedTip(g_tStrings.tSelectTalentResult[nRetCode])
                            end
                        end
                    end
                end
            end
            if #tConfirmList > 0 then
                RemoteCallToServer("On_Skill_SetNewTalent", tConfirmList)
            end
        end

        self.tChooseMixQixue = {}
    end

    local szText = ""
    local nCost = self:GetMixQixueCost()
    if nCost > 0 then
        szText = FormatString(g_tStrings.NEW_MIX_SKILL_SELECT_TALENT, nCost)
    else
        szText = g_tStrings.NEW_MIX_SKILL_SELECT_TALENT_NO_COST
    end
    UIHelper.ShowConfirm(szText, fnSelectMixQixue)
end

function UIWidgetAcupointCell:RefreshMixedQixue()
    if #self.tChooseMixQixue > 0 then
        UIHelper.SetRichText(self.LabelTitle1, string.format("<color=%s>%s(%d/%d)</color>", szColor, "混选奇穴", #self.tChooseMixQixue, nMaxLimit))
    else
        UIHelper.SetRichText(self.LabelTitle1, UIHelper.AttachTextColor("混选奇穴", szColor))
    end
    UIHelper.SetButtonState(self.BtnApplyMix,
            (#self.tChooseMixQixue == nMaxLimit and self:GetMixQixueCost() > 0) and BTN_STATE.Normal or BTN_STATE.Disable)
end

function UIWidgetAcupointCell:BindClickEvent(fnFunc)
    self.fnFunc = fnFunc
end

function UIWidgetAcupointCell:UnSelectAll()
    for index, script in ipairs(self.tScripts) do
        script:SetSelected(false)
    end
end

function UIWidgetAcupointCell:HideEquipHint()
    UIHelper.SetVisible(self.ImgHintEquip, false)
end

function UIWidgetAcupointCell:SetCoreColor(dwCoreSkillColor)
    self.dwCoreSkillColor = dwCoreSkillColor
end

function UIWidgetAcupointCell:SetTitle(szTitle)
    UIHelper.SetRichText(self.LabelTitle1, string.format("<color=%s>%s</color>", szColor, szTitle))
end

function UIWidgetAcupointCell:Reset()
    UIHelper.RemoveAllChildren(self.LayoutSkill1)
    UIHelper.RemoveAllChildren(self.LayoutSkill2)
    UIHelper.RemoveAllChildren(self.LayoutSkillGridDX)
    UIHelper.RemoveAllChildren(self.LayoutSkillGridVK)
    UIHelper.LayoutSetSpacingX(self.LayoutSkill1, self.LayoutXSpacingDX)
    UIHelper.LayoutSetSpacingX(self.LayoutSkill2, self.LayoutXSpacingDX)
end

return UIWidgetAcupointCell
