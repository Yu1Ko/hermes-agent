-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIExtractPersetSkillCell
-- Date: 2025-06-10 15:32:50
-- Desc: ?
-- ---------------------------------------------------------------------------------
local MAX_SHOW_SKILL_NUM = 5
local UIExtractPersetSkillCell = class("UIExtractPersetSkillCell")

function UIExtractPersetSkillCell:OnEnter(szTitle, tSkillList, bSelected)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szTitle = szTitle or 0
    self.tSkillList = tSkillList or {}
    self.bSelected = bSelected or false
    self:UpdateInfo()
end

function UIExtractPersetSkillCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIExtractPersetSkillCell:BindUIEvent()
    
end

function UIExtractPersetSkillCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIExtractPersetSkillCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIExtractPersetSkillCell:UpdateInfo()
    UIHelper.SetVisible(self.WidgetSelect, self.bSelected)
    local tSkillList = self.tSkillList
    local szTitle = UIHelper.GBKToUTF8(self.szTitle) or ""

    for i = 1, MAX_SHOW_SKILL_NUM, 1 do
        local nSkillID = tonumber(tSkillList[i])
        local widgetSlot = self.tbWidgetSlot[i]
        local scriptSkill = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, widgetSlot)
        local toggle = scriptSkill:GetToggle()
        UIHelper.SetSwallowTouches(toggle, false)
        Event.Reg(scriptSkill, EventType.HideAllHoverTips, function()
            UIHelper.SetSelected(toggle, false)
        end)

        scriptSkill:UpdateInfo(nSkillID)
        scriptSkill:BindSelectFunction(function()
            local tips, tipsScriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSkillInfoTips, scriptSkill._rootNode,
                                            TipsLayoutDir.Right, nSkillID)
                tipsScriptView:InitDisplayOnly(nSkillID)
        end)
    end

    UIHelper.SetString(self.LabelEquipNormal, szTitle)
    UIHelper.SetString(self.LabelEquipLight, szTitle)
end


return UIExtractPersetSkillCell