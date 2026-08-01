-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIAttributeCell
-- Date: 2023-03-29 17:27:40
-- Desc: 侠客-单条属性组件
-- Prefab: WidgetAttributeCell
-- ---------------------------------------------------------------------------------

local UIAttributeCell = class("UIAttributeCell")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIAttributeCell:_LuaBindList()
    self.LabelName  = self.LabelName --- 名称
    self.LabelValue = self.LabelValue --- 值
    self.ImgRankBg  = self.ImgRankBg --- 双数显示的条纹图片
end

function UIAttributeCell:OnEnter(szName, nValue, nIndex)
    self.szName = szName
    self.nValue = nValue
    self.nIndex = nIndex

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIAttributeCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAttributeCell:BindUIEvent()

end

function UIAttributeCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIAttributeCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAttributeCell:UpdateInfo()
    UIHelper.SetString(self.LabelName, self.szName)
    UIHelper.SetString(self.LabelValue, self.nValue)
    
    UIHelper.SetVisible(self.ImgRankBg, self.nIndex % 2 == 0)
end

return UIAttributeCell