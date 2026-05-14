-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIFilterItem
-- Date: 2023-02-22 22:27:17
-- Desc: 隐元秘鉴 - 成就类别/成就详情/五甲 - 过滤器 - 单个过滤条件widget
-- Prefab: WidgetScreenTips
-- ---------------------------------------------------------------------------------

local UIFilterItem = class("UIFilterItem")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIFilterItem:_LuaBindList()
    self.LabelFilterName     = self.LabelFilterName --- 过滤条件名称
    self.LabelFilterProgress = self.LabelFilterProgress --- 该过滤条件下的成就的进度（完成数/总数）

    self.TogFilter           = self.TogFilter --- 过滤条件的 toggle
end

function UIFilterItem:OnEnter(szName, nFinished, nTotal)
    self.szName    = szName
    self.nFinished = nFinished
    self.nTotal    = nTotal

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIFilterItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFilterItem:BindUIEvent()

end

function UIFilterItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIFilterItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFilterItem:UpdateInfo()
    if not self.szName then
        return
    end
    
    UIHelper.SetString(self.LabelFilterName, self.szName)
    UIHelper.SetString(self.LabelFilterProgress, string.format("%d/%d", self.nFinished, self.nTotal))
end

return UIFilterItem