-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIScreeningNumTog
-- Date: 2023-03-28 17:48:20
-- Desc: 侠客-筛选项
-- Prefab: WidgetScreeningNumTog
-- ---------------------------------------------------------------------------------

local UIScreeningNumTog = class("UIScreeningNumTog")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIScreeningNumTog:_LuaBindList()
    self.LabelScreening     = self.LabelScreening --- 筛选项名称

    self.TogScreeningIndex  = self.TogScreeningIndex --- 序号风格的toggle
    self.LabelIndex         = self.LabelIndex --- 序号

    self.TogScreeningSelect = self.TogScreeningSelect --- 打钩风格的toggle
end

function UIScreeningNumTog:OnEnter(szName, bUseIndexStyle)
    self.szName         = szName
    self.bUseIndexStyle = bUseIndexStyle
    self.nIndex         = 0

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIScreeningNumTog:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIScreeningNumTog:BindUIEvent()

end

function UIScreeningNumTog:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIScreeningNumTog:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIScreeningNumTog:UpdateInfo()
    UIHelper.SetString(self.LabelScreening, self.szName)

    UIHelper.SetVisible(self.TogScreeningIndex, self.bUseIndexStyle)
    UIHelper.SetVisible(self.TogScreeningSelect, not self.bUseIndexStyle)

    UIHelper.SetSelected(self.TogScreeningIndex, false)
    UIHelper.SetSelected(self.TogScreeningSelect, false)

    if self.bUseIndexStyle then
        UIHelper.SetString(self.LabelIndex, self.nIndex)
    end
end

function UIScreeningNumTog:SetIndex(nIndex)
    self.nIndex = nIndex
    UIHelper.SetString(self.LabelIndex, self.nIndex)
end

return UIScreeningNumTog