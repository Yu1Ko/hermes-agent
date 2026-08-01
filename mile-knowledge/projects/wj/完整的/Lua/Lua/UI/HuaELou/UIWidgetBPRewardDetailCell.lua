-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIWidgetBPRewardDetailCell
-- Date: 2024-03-21 11:20:47
-- Desc: 战令购买页面代表奖励
-- Prefab: WidgetBPRewardDetailCell
-- ---------------------------------------------------------------------------------

---@class UIWidgetBPRewardDetailCell
local UIWidgetBPRewardDetailCell = class("UIWidgetBPRewardDetailCell")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIWidgetBPRewardDetailCell:_LuaBindList()
    self.LabelLevel   = self.LabelLevel --- 等级
    self.WidgetItem80 = self.WidgetItem80 --- 奖励道具组件
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIWidgetBPRewardDetailCell:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    ---@class BattlePassAwardItem 战令奖励道具
    ---@field dwItemType number 道具类别
    ---@field dwItemID number 道具ID
    ---@field nItemAmount number 道具数目
end

---@param tItemInfo BattlePassAwardItem
function UIWidgetBPRewardDetailCell:OnEnter(nLevel, tItemInfo)
    self.nLevel    = nLevel
    self.tItemInfo = tItemInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIWidgetBPRewardDetailCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetBPRewardDetailCell:BindUIEvent()

end

function UIWidgetBPRewardDetailCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetBPRewardDetailCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetBPRewardDetailCell:UpdateInfo()
    UIHelper.SetString(self.LabelLevel, string.format("%d级", self.nLevel))

    if self.tItemInfo then
        local dwItemType, dwItemIndex, nStackNum = self.tItemInfo.dwItemType, self.tItemInfo.dwItemID, self.tItemInfo.nItemAmount

        ---@type UIItemIcon
        local widgetItem                         = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem80)

        widgetItem:OnInitWithTabID(dwItemType, dwItemIndex, nStackNum)
        widgetItem:SetClickNotSelected(true)
        UIHelper.SetSwallowTouches(widgetItem.ToggleSelect, false)

        widgetItem:SetClickCallback(function(nItemType, nItemIndex)
            Timer.AddFrame(self, 1, function()
                TipsHelper.ShowItemTips(widgetItem._rootNode, dwItemType, dwItemIndex)
            end)
        end)
    end
end

return UIWidgetBPRewardDetailCell