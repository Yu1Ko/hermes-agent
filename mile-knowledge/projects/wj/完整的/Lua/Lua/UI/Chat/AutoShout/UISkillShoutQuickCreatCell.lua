-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISkillShoutQuickCreatCell
-- Date: 2025-04-08 10:41:38
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISkillShoutQuickCreatCell = class("UISkillShoutQuickCreatCell")

function UISkillShoutQuickCreatCell:OnEnter(nSkillID, fnCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nSkillID = nSkillID
    self.fnCallBack = fnCallBack
    self:UpdateInfo()
end

function UISkillShoutQuickCreatCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISkillShoutQuickCreatCell:BindUIEvent()
    UIHelper.BindUIEvent(self._rootNode, EventType.OnSelectChanged, function(_, bSelected)
        if self.fnCallBack then
            self.fnCallBack(bSelected)
        end
    end)
end

function UISkillShoutQuickCreatCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISkillShoutQuickCreatCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISkillShoutQuickCreatCell:UpdateInfo()
    local tbSkillInfo = TabHelper.GetUISkill(self.nSkillID)
    local szName = tbSkillInfo and tbSkillInfo.szName or ""
    if not tbSkillInfo then
        tbSkillInfo = Table_GetSkill(self.nSkillID, 1)
        szName = UIHelper.GBKToUTF8(tbSkillInfo.szName)
    end
    local bEquip = ChatAutoShout.CheckIsSkillNameEquiped(szName)

    UIHelper.SetString(self.LabelTogName, szName)
    UIHelper.SetString(self.LabelTogName_Selected, szName)
    UIHelper.SetVisible(self.WidgetState, bEquip)
    UIHelper.SetEnable(self._rootNode, not bEquip)
    self:SetSelected(bEquip, false)

    local scriptSkill = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, self.WidgetSkillCell)
    scriptSkill:UpdateInfo(self.nSkillID)
    UIHelper.SetAnchorPoint(scriptSkill._rootNode, 0.5, 0.5)
    UIHelper.SetEnable(scriptSkill.TogSkill, false)
end

function UISkillShoutQuickCreatCell:SetSelected(bSelected, bCallback)
    UIHelper.SetSelected(self._rootNode, bSelected, bCallback)
end
return UISkillShoutQuickCreatCell