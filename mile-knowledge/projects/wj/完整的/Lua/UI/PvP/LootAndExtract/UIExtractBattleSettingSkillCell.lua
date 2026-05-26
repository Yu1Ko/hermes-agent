-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIExtractBattleSettingSkillCell
-- Date: 2025-06-23 14:19:13
-- Desc: ?
-- ---------------------------------------------------------------------------------
local UIExtractBattleSettingSkillCell = class("UIExtractBattleSettingSkillCell")

function UIExtractBattleSettingSkillCell:OnEnter(nIndex, tbSkill)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nIndex = nIndex
    self.tbSkill = tbSkill
    self:UpdateInfo()
end

function UIExtractBattleSettingSkillCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIExtractBattleSettingSkillCell:BindUIEvent()
    
end

function UIExtractBattleSettingSkillCell:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        if self.scriptSkillCell then
            self.scriptSkillCell:SetSelected(false)
        end
    end)
end

function UIExtractBattleSettingSkillCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIExtractBattleSettingSkillCell:UpdateInfo()
    self.scriptSkillCell = nil
    UIHelper.RemoveAllChildren(self._rootNode)
    if not self.tbSkill then
        return
    end

    local nSkillID = self.tbSkill.nSkillID
    local nSkillLevel = self.tbSkill.nSkillLevel
    self.scriptSkillCell = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, self._rootNode, nSkillID, nSkillLevel)
    self.scriptSkillCell:BindSelectFunction(function()
        if self.fnSelectFunction then
            self.fnSelectFunction()
        end
    end)
end

function UIExtractBattleSettingSkillCell:GetSkillIconScript()
    return self.scriptSkillCell
end

function UIExtractBattleSettingSkillCell:BindSelectFunction(fnSelectFunction)
    self.fnSelectFunction = fnSelectFunction
end

function UIExtractBattleSettingSkillCell:GetItemInfo()
    if not self.tbSkill then
        return {}
    end
    return {nIndex = self.nIndex, dwItemType = "skill", dwItemIndex = self.tbSkill.nSkillID}
end

function UIExtractBattleSettingSkillCell:OnDragEnd(scriptTargetItem, nodeTarget)
    if not scriptTargetItem then
        return
    end

    local tbTargetInfo = scriptTargetItem:GetItemInfo()
    if not tbTargetInfo or tbTargetInfo.dwItemType ~= "skill" then
        return
    end

    TreasureBattleFieldSkillData.ExchangeSkill(tbTargetInfo.nIndex, self.nIndex)
end


return UIExtractBattleSettingSkillCell