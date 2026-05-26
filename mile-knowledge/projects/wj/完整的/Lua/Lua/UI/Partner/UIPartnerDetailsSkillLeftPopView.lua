-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerDetailsSkillLeftPopView
-- Date: 2023-04-03 15:31:58
-- Desc: 侠客-技能侧边栏
-- Prefab: WidgetPartnerDetailsSkillLeftPop
-- ---------------------------------------------------------------------------------

local UIPartnerDetailsSkillLeftPopView = class("UIPartnerDetailsSkillLeftPopView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerDetailsSkillLeftPopView:_LuaBindList()
    self.LayoutLeft          = self.LayoutLeft --- 上层的layout

    self.TogSkill            = self.TogSkill --- 招式的toggle
    self.TogAdditionalSkill1 = self.TogAdditionalSkill1 --- 追加技一的toggle
    self.TogAdditionalSkill2 = self.TogAdditionalSkill2 --- 追加技二的toggle

    self.WidgetSkillDetails  = self.WidgetSkillDetails --- 当前选中的技能详情

    self.BtnMask             = self.BtnMask --- 左侧栏的遮罩按钮，点击后隐藏
    self.BtnCloseLeft        = self.BtnCloseLeft --- 关闭按钮，点击后隐藏侧边栏

    self.WidgetTitleTog      = self.WidgetTitleTog --- 顶部标题栏的组件
end

function UIPartnerDetailsSkillLeftPopView:OnEnter(dwSkillID, nSkillLevel)
    self.dwSkillID   = dwSkillID
    self.nSkillLevel = nSkillLevel

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPartnerDetailsSkillLeftPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPartnerDetailsSkillLeftPopView:BindUIEvent()
    for _, uiToggle in ipairs({ self.TogSkill, self.TogAdditionalSkill1, self.TogAdditionalSkill2 }) do
        UIHelper.SetToggleGroupIndex(uiToggle, ToggleGroupIndex.SkillDetail)
    end
end

function UIPartnerDetailsSkillLeftPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPartnerDetailsSkillLeftPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerDetailsSkillLeftPopView:UpdateInfo()
    UIHelper.RemoveAllChildren(self.WidgetSkillDetails)

    -- todo: 当前侠客和主角共用这个技能详情预制，侠客不需要上面的部分，后续主角使用该组件时再由其自行使用
    UIHelper.SetVisible(self.WidgetTitleTog, false)

    UIHelper.AddPrefab(PREFAB_ID.WidgetLeftPopSkillDetailsList, self.WidgetSkillDetails, self.dwSkillID, self.nSkillLevel)

    UIHelper.LayoutDoLayout(self.LayoutLeft)
end

return UIPartnerDetailsSkillLeftPopView