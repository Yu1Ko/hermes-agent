-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UISkillCell
-- Date: 2023-04-03 11:12:41
-- Desc: 侠客-武学招式组件
-- Prefab: WidgetSkillCell
-- ---------------------------------------------------------------------------------

local UISkillCell = class("UISkillCell")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UISkillCell:_LuaBindList()
    self.TogSkill      = self.TogSkill --- 技能选中的toggle
    self.ImgSkillIcon1 = self.ImgSkillIcon1 --- 技能图标
end

function UISkillCell:OnEnter(dwSkillID, nSkillLevel)
    self.dwSkillID   = dwSkillID
    self.nSkillLevel = nSkillLevel

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UISkillCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISkillCell:BindUIEvent()

end

function UISkillCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISkillCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISkillCell:UpdateInfo()
    UIHelper.SetToggleGroupIndex(self.TogSkill, ToggleGroupIndex.PartnerSkill)

    local nIconID    = Table_GetSkillIconID(self.dwSkillID, self.nSkillLevel)
    UIHelper.SetItemIconByIconID(self.ImgSkillIcon1, nIconID, true, function()
        UIHelper.UpdateMask(self.MaskSkill1)
    end)
    UIHelper.UpdateMask(self.MaskSkill1)
end

return UISkillCell