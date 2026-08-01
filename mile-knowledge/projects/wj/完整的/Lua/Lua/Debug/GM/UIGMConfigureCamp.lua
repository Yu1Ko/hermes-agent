local UIGMConfigureCamp = class("UIGMConfigureCamp")

function UIGMConfigureCamp:OnEnter(tKungFungList)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(tKungFungList)
end

function UIGMConfigureCamp:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIGMConfigureCamp:BindUIEvent()
    
end

function UIGMConfigureCamp:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIGMConfigureCamp:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIGMConfigureCamp:UpdateInfo(tKungFungList)
    UIHelper.RemoveAllChildren(self.ScrollViewRoleList)
    for _,  camp in ipairs(tKungFungList) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetConfigureKungFu, self.ScrollViewRoleList, camp, camp.fnAction)
    end
end


return UIGMConfigureCamp