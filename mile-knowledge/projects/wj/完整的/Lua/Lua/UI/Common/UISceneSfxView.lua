-- 场景特效
-- 可支持同时播放多个
local UISceneSfxView = class("UISceneSfxView")

function UISceneSfxView:OnEnter()
    self.tbSfxMap = {}
    UIHelper.SetLocalZOrder(self._rootNode, -2)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UISceneSfxView:OnExit()

end

function UISceneSfxView:BindUIEvent()

end

function UISceneSfxView:RegEvent()
    
end

function UISceneSfxView:AddSfx(tbOpt)
    if not IsTable(tbOpt) then
        return
    end

    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSceneSfx, self.WidgetSFXParent, tbOpt)
    table.insert(self.tbSfxMap, script)
end

function UISceneSfxView:RemoveSfx()
    if not self.tbSfxMap then 
        return 
    end

    for nIndex, script in ipairs(self.tbSfxMap) do
        if safe_check(script._rootNode) then
            UIHelper.RemoveFromParent(script._rootNode, true)
        end
    end
    self.tbSfxMap = {}
end

return UISceneSfxView
