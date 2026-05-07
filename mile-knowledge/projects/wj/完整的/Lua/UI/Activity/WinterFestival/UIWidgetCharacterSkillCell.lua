-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetCharacterSkillCell
-- Date: 2024-11-28 14:36:55
-- Desc: UIWIdgetCharacterSkill 门客培养 技能Widget
-- ---------------------------------------------------------------------------------

local UIWidgetCharacterSkillCell = class("UIWidgetCharacterSkillCell")

function UIWidgetCharacterSkillCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetCharacterSkillCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetCharacterSkillCell:OnInit(nSkillID, nSkillLevel, szSkillTip)
    self.nSkillID = nSkillID
    self.nSkillLevel = nSkillLevel
    self.szSkillTip = szSkillTip

    if nSkillID and nSkillLevel then
        self:UpdateInfo()
    end
end

function UIWidgetCharacterSkillCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnLockedDetail, EventType.OnClick, function()
        if not string.is_nil(self.szSkillTip) then
            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnLockedDetail, TipsLayoutDir.TOP_CENTER, self.szSkillTip)
        end
    end)
end

function UIWidgetCharacterSkillCell:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.scriptSkillCell then
            self.scriptSkillCell:SetSelected(false)
        end
    end)
end

function UIWidgetCharacterSkillCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetCharacterSkillCell:UpdateInfo()
    local nSkillID = self.nSkillID
    local nSkillLevel = self.nSkillLevel

    local bLearned = nSkillLevel > 0
    if nSkillLevel == 0 then
        nSkillLevel = 1
    end

    self.scriptSkillCell = self.scriptSkillCell or UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, self.WidgetSkillCell)
    self.scriptSkillCell:OnEnter(nSkillID, nSkillLevel)

    UIHelper.SetSwallowTouches(self.scriptSkillCell.TogSkill, false)
    self.scriptSkillCell:BindSelectFunction(function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSkillInfoTips, self.WidgetSkillCell,
        TipsLayoutDir.LEFT_CENTER, nSkillID, nil, nil, nSkillLevel)
    end)

    UIHelper.SetVisible(self.WidgetLocked, not bLearned)
    UIHelper.SetVisible(self.WidgetLockedBtn, not bLearned)
    self.scriptSkillCell:SetGrey(not bLearned)
    
    if not bLearned then
        UIHelper.SetString(self.LabelSkillName, g_tStrings.STR_ARENA_LOCK)
    else
        local szName = UIHelper.GBKToUTF8(Table_GetSkillName(nSkillID, nSkillLevel))
        UIHelper.SetString(self.LabelSkillName, szName)
    end

    UIHelper.LayoutDoLayout(self.LayoutSkillName)
end


return UIWidgetCharacterSkillCell