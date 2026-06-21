-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UITogSchoolFilterCell
-- Date: 2023-11-01 17:12:57
-- Desc: 帮会成员列表筛选项
-- Prefab: WidgetTogSchoolFilterCell
-- ---------------------------------------------------------------------------------

local UITogSchoolFilterCell = class("UITogSchoolFilterCell")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UITogSchoolFilterCell:_LuaBindList()
    self.Toggle              = self.Toggle --- toggle
    self.LabelFilter         = self.LabelFilter --- 筛选项名称
    self.LabelFilterSelected = self.LabelFilterSelected --- 筛选项名称（选中）
end

function UITogSchoolFilterCell:OnEnter(tbInfo)
    if not tbInfo then
        return
    end
    
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    --- {szName, nGroupIndex}
    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UITogSchoolFilterCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITogSchoolFilterCell:BindUIEvent()

end

function UITogSchoolFilterCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITogSchoolFilterCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITogSchoolFilterCell:UpdateInfo()
    local szName = UIHelper.TruncateStringReturnOnlyResult(self.tbInfo.szName, 5, "…", 4)
    
    UIHelper.SetString(self.LabelFilter, szName)
    UIHelper.SetString(self.LabelFilterSelected, szName)
end

function UITogSchoolFilterCell:GetGroupIndex()
    return self.tbInfo.nGroupIndex
end

return UITogSchoolFilterCell