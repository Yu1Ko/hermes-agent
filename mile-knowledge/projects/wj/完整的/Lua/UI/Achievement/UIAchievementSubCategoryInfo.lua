-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIAchievementSubCategoryInfo
-- Date: 2023-02-17 15:22:06
-- Desc: 隐元秘鉴 - 类别成就详情 - 子类别信息小部件
-- Prefab: WidgetAchievementContentClassify
-- ---------------------------------------------------------------------------------

local UIAchievementSubCategoryInfo = class("UIAchievementSubCategoryInfo")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIAchievementSubCategoryInfo:_LuaBindList()
    self.TogSubCategoryInfo                      = self.TogSubCategoryInfo --- 控制选中状态的 toggle

    self.LabelSubCategoryNameNotSelected         = self.LabelSubCategoryNameNotSelected --- 子类别名称（未选中）
    self.LabelSubCategoryInfoProgressNotSelected = self.LabelSubCategoryInfoProgressNotSelected --- 子类别进度（未选中）

    self.LabelSubCategoryNameSelected            = self.LabelSubCategoryNameSelected --- 子类别名称（选中）
    self.LabelSubCategoryInfoProgressSelected    = self.LabelSubCategoryInfoProgressSelected --- 子类别进度（选中）
end

function UIAchievementSubCategoryInfo:OnEnter(szName, nFinished, nTotal)
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

function UIAchievementSubCategoryInfo:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAchievementSubCategoryInfo:BindUIEvent()

end

function UIAchievementSubCategoryInfo:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIAchievementSubCategoryInfo:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAchievementSubCategoryInfo:UpdateInfo()
    local szProgress = string.format("%d/%d", self.nFinished, self.nTotal)
    
    UIHelper.SetString(self.LabelSubCategoryNameNotSelected, self.szName)
    UIHelper.SetString(self.LabelSubCategoryInfoProgressNotSelected, szProgress)

    UIHelper.SetString(self.LabelSubCategoryNameSelected, self.szName)
    UIHelper.SetString(self.LabelSubCategoryInfoProgressSelected, szProgress)
end

return UIAchievementSubCategoryInfo