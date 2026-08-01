-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UILeftPopSkillDetailsList
-- Date: 2023-04-03 16:24:56
-- Desc: 侠客-技能详细描述
-- Prefab: WidgetLeftPopSkillDetailsList
-- ---------------------------------------------------------------------------------

local UILeftPopSkillDetailsList = class("UILeftPopSkillDetailsList")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UILeftPopSkillDetailsList:_LuaBindList()
    self.LayoutSkillDetailsList = self.LayoutSkillDetailsList --- 上层的layout

    self.WidgetSkillCell        = self.WidgetSkillCell --- 图标组件

    self.LabelSkillName         = self.LabelSkillName --- 名称
    self.LabelSkillLevel        = self.LabelSkillLevel --- 等级
    self.LabelSkillType         = self.LabelSkillType --- 类型（攻击/治疗等）
    self.LabelSkillTime         = self.LabelSkillTime --- 冷却时间
    self.LabelDescribe          = self.LabelDescribe --- 具体描述

    self.WidgetAttribute        = self.WidgetAttribute --- 属性的组件
end

function UILeftPopSkillDetailsList:OnEnter(dwSkillID, nSkillLevel)
    self.dwSkillID   = dwSkillID
    self.nSkillLevel = nSkillLevel

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UILeftPopSkillDetailsList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UILeftPopSkillDetailsList:BindUIEvent()

end

function UILeftPopSkillDetailsList:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UILeftPopSkillDetailsList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UILeftPopSkillDetailsList:UpdateInfo()
    local dwID, nLevel = self.dwSkillID, self.nSkillLevel

    local szName       = Table_GetSkillName(dwID, nLevel)
    szName             = UIHelper.GBKToUTF8(szName)

    -- todo
    local szType       = "技能类型"

    local tRecipeKey   = g_pClientPlayer.GetSkillRecipeKey(dwID, nLevel)
    local pSkillInfo   = GetSkillInfo(tRecipeKey)

    local nCooldown    = 0
    for i = 1, 3 do
        local szKey = "CoolDown" .. i

        if pSkillInfo[szKey] > nCooldown then
            nCooldown = pSkillInfo[szKey]
        end
    end

    local nCD           = nCooldown / GLOBAL.GAME_FPS

    local szDescription = GetSubSkillDesc(dwID, nLevel)
    szDescription       = UIHelper.GBKToUTF8(szDescription)

    UIHelper.RemoveAllChildren(self.WidgetSkillCell)
    UIMgr.AddPrefab(PREFAB_ID.WidgetSkillCell, self.WidgetSkillCell, self.dwSkillID, self.nSkillLevel)

    UIHelper.SetString(self.LabelSkillName, szName)
    UIHelper.SetString(self.LabelSkillType, szType)
    UIHelper.SetString(self.LabelSkillLevel, string.format("等级 %d", nLevel))
    UIHelper.SetString(self.LabelSkillTime, string.format("冷却  %d秒", nCD))
    UIHelper.SetString(self.LabelDescribe, szDescription)

    UIHelper.SetVisible(self.LabelSkillType, false)

    UIHelper.LayoutDoLayout(self.LayoutSkillDetailsList)
end

return UILeftPopSkillDetailsList