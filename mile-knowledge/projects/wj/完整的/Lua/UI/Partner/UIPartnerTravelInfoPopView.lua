-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerTravelInfoPopView
-- Date: 2024-11-23 19:21:59
-- Desc: 出行事件详情页面
-- Prefab: PanelPartnerTravelInfoPop
-- ---------------------------------------------------------------------------------

---@class UIPartnerTravelInfoPopView
local UIPartnerTravelInfoPopView = class("UIPartnerTravelInfoPopView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerTravelInfoPopView:_LuaBindList()
    self.WidgetTravelInfoPop  = self.WidgetTravelInfoPop --- 出行信息的锚点

    self.WidgetRewardHint     = self.WidgetRewardHint --- 实际的奖励信息组件的父节点
    self.BtnCheck             = self.BtnCheck --- 奖励界面的确定按钮

    self.LayoutReward         = self.LayoutReward --- <=3个奖励的layout
    self.ScrollViewRewardMore = self.ScrollViewRewardMore --- >3个奖励的scrollview
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIPartnerTravelInfoPopView:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIPartnerTravelInfoPopView:OnEnter(tQuestInfo, nCurrentBoard, nQuestIndex, nClass)
    --- {}
    --- {nQuest, tHeroList, nStart, nMinute}
    self.tQuestInfo    = tQuestInfo

    --- 第几个牌子
    self.nCurrentBoard = nCurrentBoard
    --- 第几个出行位置
    self.nQuestIndex   = nQuestIndex
    --- 任务类型信息
    self.nClass        = nClass

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if tQuestInfo then
        self:UpdateInfo()
    end
end

function UIPartnerTravelInfoPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPartnerTravelInfoPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCheck, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    
    UIHelper.SetScrollViewCombinedBatchEnabled( self.ScrollViewRewardMore, false)
end

function UIPartnerTravelInfoPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "OnShowHeroTravelReaward", function(tInfoList)
        self:ShowRewardList(tInfoList)
    end)

    Event.Reg(self, EventType.OnGuideItemSource, function()
        UIMgr.Close(self)
    end)

    UIHelper.TempHideCurrentViewOnSomeViewOpen(self, {
        VIEW_ID.PanelAchievementContent,
    })
end

function UIPartnerTravelInfoPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerTravelInfoPopView:UpdateInfo()
    UIHelper.RemoveAllChildren(self.WidgetTravelInfoPop)
    ---@see UITravelInfoPop
    UIMgr.AddPrefab(PREFAB_ID.WidgetTravelInfoPop, self.WidgetTravelInfoPop, self)
end

function UIPartnerTravelInfoPopView:ShowRewardList(tInfoList)
    UIHelper.SetVisible(self.WidgetTravelInfoPop, false)
    UIHelper.SetVisible(self.WidgetRewardHint, true)

    for nIndex, tInfo in ipairs(tInfoList) do
        tInfo.nIndex = nIndex
    end
    local function fnSort(tInfoLeft, tInfoRight)
        -- 触发奇遇的优先显示，其他的按照原来的顺序
        local bHasTriggerLeft  = PartnerData.IsTravelQuestTriggered(Table_GetPartnerTravelTask(tInfoLeft[1]))
        local bHasTriggerRight = PartnerData.IsTravelQuestTriggered(Table_GetPartnerTravelTask(tInfoRight[1]))

        if bHasTriggerLeft ~= bHasTriggerRight then
            return bHasTriggerLeft
        end

        return tInfoLeft.nIndex < tInfoRight.nIndex
    end

    table.sort(tInfoList, fnSort)

    local bUseScrollView = #tInfoList > 3

    UIHelper.SetVisible(self.LayoutReward, not bUseScrollView)
    UIHelper.SetVisible(self.ScrollViewRewardMore, bUseScrollView)

    local container
    if bUseScrollView then
        container = self.ScrollViewRewardMore
    else
        container = self.LayoutReward
    end

    UIHelper.RemoveAllChildren(container)

    for _, tInfo in ipairs(tInfoList) do
        ---@type UITravelRewardCardList
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetTravelRewardCardList, container, tInfo)

        if bUseScrollView then
            UIHelper.SetAnchorPoint(script._rootNode, 0, 0)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutReward)
    UIHelper.ScrollViewDoLayout(self.ScrollViewRewardMore)
end

return UIPartnerTravelInfoPopView