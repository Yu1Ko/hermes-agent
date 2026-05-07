-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIFameAward
-- Date: 2023-06-08 15:13:38
-- Desc: 名望-奖励
-- Prefab: WidgetFameAward
-- ---------------------------------------------------------------------------------

local UIFameAward = class("UIFameAward")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIFameAward:_LuaBindList()
    self.LabelFameLevel = self.LabelFameLevel --- 需要的名望等级
    self.WidgetItem_80  = self.WidgetItem_80 --- 奖励道具挂载点
    self.TogItem        = self.TogItem --- 外侧的toggle
end

function UIFameAward:OnEnter(nLevel, dwTabType, dwIndex)
    self.nLevel    = nLevel
    self.dwTabType = dwTabType
    self.dwIndex   = dwIndex

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIFameAward:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFameAward:BindUIEvent()
    UIHelper.BindUIEvent(self.TogItem, EventType.OnClick, function()
        self:ShowItemTips()
    end)
end

function UIFameAward:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIFameAward:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFameAward:UpdateInfo()
    UIHelper.SetString(self.LabelFameLevel, self.nLevel)

    local widgetItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem_80)
    widgetItem:OnInitWithTabID(self.dwTabType, self.dwIndex)

    widgetItem:SetClickCallback(function(nItemType, nItemIndex)
        self:ShowItemTips()
    end)

    UIHelper.SetAnchorPoint(widgetItem._rootNode, 0, 0)
    UIHelper.SetToggleGroupIndex(widgetItem.ToggleSelect, ToggleGroupIndex.FameReward)

    widgetItem:SetClickNotSelected(true)

    widgetItem:SetToggleSwallowTouches(false)
    UIHelper.SetSwallowTouches(self.TogItem, false)
end

function UIFameAward:ShowItemTips()
    TipsHelper.ShowItemTips(self.WidgetItem_80, self.dwTabType, self.dwIndex, false)
end

return UIFameAward