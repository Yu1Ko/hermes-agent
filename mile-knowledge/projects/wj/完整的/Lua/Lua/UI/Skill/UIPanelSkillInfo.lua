-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSkillConfigurationCell
-- Date: 2022-11-23 10:01:29
-- Desc: ?
-- ---------------------------------------------------------------------------------
---@class UIPanelSkillInfo
local UIPanelSkillInfo = class("UIPanelSkillInfo")

function UIPanelSkillInfo:OnEnter(dwKungFuID, nSetID, nSkillID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.tSlotToNewSkillID = {}
        self.nCurrentKungFuID = dwKungFuID
        self.nCurrentSetID = nSetID
        self.nSkillID = nSkillID

        --local compLuaBind = self.WidgetAnchorInfoSkill:getComponent("LuaBind")
        --self.widgetSkillDetailScript = compLuaBind and compLuaBind:getScriptObject()
        self.WidgetInfoSkillScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillInfoTips, self.WidgetAnchorInfoSkill)
    end
    self:UpdateInfo()
end

function UIPanelSkillInfo:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelSkillInfo:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnBigSkill, EventType.OnClick, function()
        local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetConfigurationAcupointTip, self.BtnBigSkill
        , TipsLayoutDir.TOP_CENTER, self.nCurrentKungFuID, self.nCurrentSetID)
    end)

    local layout = UIHelper.GetParent(self.LabelMoney_XiuWei)
    UIHelper.BindUIEvent(layout, EventType.OnClick, function()
        CurrencyData.ShowCurrencyHoverTips(layout, CurrencyType.Train)
    end)
    UIHelper.SetTouchEnabled(layout, true)
end

function UIPanelSkillInfo:RegEvent()
    Event.Reg(self, "UI_TRAIN_VALUE_UPDATE", function()
        self:UpdateTrain()
    end)

    Event.Reg(self, "ON_SKILL_REPLACE", function(arg0, arg1, arg2)
        LOG.WARN("UIPanelSkillInfo ON_SKILL_REPLACE")
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_UPDATE_TALENT", function(arg0, arg1, arg2)
        self:UpdateInfo()
    end)
end

function UIPanelSkillInfo:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelSkillInfo:UpdateInfo()
    self:UpdateSkillList()
    self:UpdateQiXue()
    self:UpdateSkillPanel()
    self:UpdateTrain()
end

function UIPanelSkillInfo:UpdateTrain()
    UIHelper.SetString(self.LabelMoney_XiuWei, g_pClientPlayer.nCurrentTrainValue)
end

function UIPanelSkillInfo:UpdateSkillList()
    local currentKungFuID = self.nCurrentKungFuID
    local skillInfoList = SkillData.GetCurrentPlayerSkillList(currentKungFuID)

    self.commonSkillList = {}
    self.secSprintSkillList = {}
    self.normalSkillList = {}
    self.tAppendSkillDict = SkillData.GetAppendSkillDict(self.nCurrentKungFuID)

    for _, tSkill in ipairs(skillInfoList) do
        local nSkillID = tSkill.nID
        local skillInfo = tSkill.tInfo
        if skillInfo.nType == UISkillType.Common then
            table.insert(self.commonSkillList, nSkillID)
        elseif skillInfo.nType == UISkillType.Skill then
            table.insert(self.normalSkillList, nSkillID)
        elseif skillInfo.nType == UISkillType.SecSprint then
            table.insert(self.secSprintSkillList, nSkillID)
        end
    end
end

function UIPanelSkillInfo:UpdateQiXue()
    self.uniqueSkillList = {}

    local tList = SkillData.GetQixueList(true, self.nCurrentKungFuID, self.nCurrentSetID)
    for index, tQixue in ipairs(tList) do
        local nSelectIndex = tQixue.nSelectIndex
        local tSkillArray = tQixue.SkillArray

        if nSelectIndex > 0 then
            local tSkill = tSkillArray[nSelectIndex]
            if index == 4 then
                table.insert(self.uniqueSkillList, tSkill.dwSkillID)
            end
        end
    end
end

--------------------------武学相关--------------------------------

function UIPanelSkillInfo:UpdateSkillPanel()
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupRight)

    self.targetSkillToggle = nil
    self:UpdateSkillGroup(self.commonSkillList, self.commonSkillParents)
    self:UpdateSkillGroup(self.secSprintSkillList, self.sprintSkillParents)
    self:UpdateSkillGroup(self.normalSkillList, self.LayoutSkillCell)
    self:UpdateSkillGroup(self.uniqueSkillList, { self.WIdgetSkillCell06 })

    if self.targetSkillToggle then
        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupRight, self.targetSkillToggle)
        Timer.AddFrame(self, 1, function()
            self.WidgetInfoSkillScript:OnEnter(self.nSkillID, self.nCurrentKungFuID, self.nCurrentSetID, 1) --延后一帧更新，防止ScrollView位置不对
        end)
    end
end

function UIPanelSkillInfo:UpdateSkillGroup(skillIDList, parentList)
    if IsTable(parentList) then
        for index, parent in ipairs(parentList) do
            UIHelper.RemoveAllChildren(parent)
            local skillID = skillIDList[index]
            if skillID then
                local x = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, parent, skillID)
                self:SetSkillToggle(x:GetToggle(), skillID)
                if skillID == self.nSkillID then
                    self.targetSkillToggle = x:GetToggle()
                end
            end
        end
    else
        local layout = parentList
        UIHelper.RemoveAllChildren(layout)
        for index, skillID in ipairs(skillIDList) do
            --print(skillID)
            local x = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, layout, skillID)
            self:SetSkillToggle(x:GetToggle(), skillID)
            if skillID == self.nSkillID then
                self.targetSkillToggle = x:GetToggle()
            end
        end
    end
end

function UIPanelSkillInfo:SetSkillToggle(toggle, nSkillID)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupRight, toggle)
    UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function(toggle, bSelected)
        --print("SetSkillToggle",toggle,nSkillID)
        if bSelected then
            self.nSkillID = nSkillID
            self.WidgetInfoSkillScript:OnEnter(self.nSkillID, self.nCurrentKungFuID, self.nCurrentSetID, 1)
        end
    end)
end

function UIPanelSkillInfo:_GetNewSkillIDList()
    local lst = {}
    for i = 1, 5 do
        if self.tSlotToNewSkillID[i] then
            table.insert(lst, self.tSlotToNewSkillID[i])
        end
    end
    return lst
end

return UIPanelSkillInfo