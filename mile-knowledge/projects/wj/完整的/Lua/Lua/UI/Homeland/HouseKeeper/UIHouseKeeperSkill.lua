-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHouseKeeperSkill
-- Date: 2023-08-09 09:55:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHouseKeeperSkill = class("UIHouseKeeperSkill")

function UIHouseKeeperSkill:OnEnter(szTitle, tbSkillInfo, nMaxSkillNum)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szTitle = szTitle
    self.tbSkillInfo = tbSkillInfo
    self.nMaxSkillNum = nMaxSkillNum
    self:UpdateInfo()
end

function UIHouseKeeperSkill:OnExit()
    self.bInit = false
end

function UIHouseKeeperSkill:BindUIEvent()

end

function UIHouseKeeperSkill:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHouseKeeperSkill:UpdateInfo()
    UIHelper.SetString(self.LabelSkillTitle, self.szTitle)

    self.tbCells = self.tbCells or {}
    for i, tbInfo in ipairs(self.tbSkillInfo) do
        if not self.tbCells[i] then
            self.tbCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetHouseKeepSkillCell, self.LayoutSkill)
        end
        self.tbCells[i]:OnEnter(i, tbInfo)
    end

    if self.nMaxSkillNum and self.nMaxSkillNum > #self.tbCells then
        for i = #self.tbCells + 1, self.nMaxSkillNum do
            self.tbCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetHouseKeepSkillCell, self.LayoutSkill)
            self.tbCells[i]:OnEnter(i)
        end
    elseif #self.tbCells > #self.tbSkillInfo then
        for i = #self.tbSkillInfo + 1, #self.tbCells do
            self.tbCells[i]:OnEnter(i)
        end
    end

    if self.nMaxSkillNum then
        UIHelper.SetString(self.LabelSkillTitle, string.format("%s：%d/%d", self.szTitle, #self.tbSkillInfo, self.nMaxSkillNum))
        UIHelper.SetVisible(self.BtnSkillTips, true)
    else
        UIHelper.SetString(self.LabelSkillTitle, self.szTitle)
        UIHelper.SetVisible(self.BtnSkillTips, false)
    end

    UIHelper.LayoutDoLayout(self.LayoutSkill)
    UIHelper.LayoutDoLayout(self.WidgetHouseKeepSkill)
end


return UIHouseKeeperSkill