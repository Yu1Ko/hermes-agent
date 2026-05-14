-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerTravelAchievePopView
-- Date: 2025-02-12 16:33:45
-- Desc: 侠客出行事件成就信息
-- Prefab: PanelPartnerTravelAchievePop
-- ---------------------------------------------------------------------------------

---@class UIPartnerTravelAchievePopView
local UIPartnerTravelAchievePopView = class("UIPartnerTravelAchievePopView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerTravelAchievePopView:_LuaBindList()
    self.BtnClose          = self.BtnClose --- 关闭按钮
    self.LabelTitle        = self.LabelTitle --- 标题
    self.ScrollViewAchieve = self.ScrollViewAchieve --- 成就列表的scroll view
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIPartnerTravelAchievePopView:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIPartnerTravelAchievePopView:OnEnter(nQuestID)
    self.nQuestID = nQuestID
    
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    
    self:UpdateInfo()
end

function UIPartnerTravelAchievePopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPartnerTravelAchievePopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPartnerTravelAchievePopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPartnerTravelAchievePopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerTravelAchievePopView:UpdateInfo()
    local tQuest             = Table_GetPartnerTravelTask(self.nQuestID)
    local tAchievementReward = SplitString(tQuest.szAchievement, ";")
    
    local tOriginalIndex = {}
    for nIdx, v in pairs(tAchievementReward) do
        tOriginalIndex[v] = nIdx
    end
    
    local fnComp = function(aLeft, aRight)
        local dwLeft = tonumber(aLeft)
        local dwRight = tonumber(aRight)

        local bFinishLeft = AchievementData.IsAchievementAcquired(dwLeft, Table_GetAchievement(dwLeft))
        local bFinishRight = AchievementData.IsAchievementAcquired(dwRight, Table_GetAchievement(dwRight))
        if bFinishLeft ~= bFinishRight then
            return not bFinishLeft
        end
        
        return tOriginalIndex[aLeft] < tOriginalIndex[aRight]
    end
    
    table.sort(tAchievementReward, fnComp)
    
    local nAchievementCount, nAchievementFinish = AchievementData.GetAchievementFinishCount(tAchievementReward)
    UIHelper.SetString(self.LabelTitle, string.format("成就（%d/%d）", nAchievementFinish, nAchievementCount))
    
    UIHelper.RemoveAllChildren(self.ScrollViewAchieve)
    for _, v in pairs(tAchievementReward) do
        local dwAchievementID = tonumber(v)

        ---@see UIAchievementPartnerItem
        UIHelper.AddPrefab(PREFAB_ID.WidgetAchievementPartnerItem, self.ScrollViewAchieve, dwAchievementID, self)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAchieve)
end

return UIPartnerTravelAchievePopView