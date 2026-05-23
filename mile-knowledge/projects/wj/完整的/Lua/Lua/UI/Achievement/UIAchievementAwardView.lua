-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIAchievementAwardView
-- Date: 2023-02-13 17:44:02
-- Desc: 隐元秘鉴 - 资历奖励
-- Prefab: PanelAchievementAward
-- ---------------------------------------------------------------------------------

local UIAchievementAwardView = class("UIAchievementAwardView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIAchievementAwardView:_LuaBindList()
    self.BtnClose                   = self.BtnClose --- 关闭界面
    self.LabelAchievementPoint      = self.LabelAchievementPoint --- 资历（成就点数）
    self.LayoutAchievementPoint     = self.LayoutAchievementPoint --- 资历layout容器
    self.LayoutAchievementAward     = self.LayoutAchievementAward --- 各阶段资历奖励的layout
    self.ScrollViewAchievementAward = self.ScrollViewAchievementAward --- 各阶段资历奖励的scroll view
end

function UIAchievementAwardView:OnEnter(tPointAwardList, dwPlayerID)
    self.tPointAwardList = tPointAwardList
    self.dwPlayerID = dwPlayerID
    self.hPlayer = g_pClientPlayer
    if self.dwPlayerID then
        self.hPlayer = GetPlayer(self.dwPlayerID)
    end

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIAchievementAwardView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAchievementAwardView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIAchievementAwardView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIAchievementAwardView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAchievementAwardView:UpdateInfo()

    if self.dwPlayerID then
        local szName = UIHelper.GBKToUTF8(self.hPlayer.szName) .. "的资历"
        UIHelper.SetString(self.LabelMyAchievement, szName)
    else
        UIHelper.SetString(self.LabelMyAchievement, "我的资历")
    end
    local nAllFinishPoint = self.hPlayer.GetAchievementRecord()

    UIHelper.RemoveAllChildren(self.LayoutAchievementPoint)
    ---@see UICoin#OnEnter
    UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.LayoutAchievementPoint, CurrencyType.AchievementPoint)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutAchievementPoint, true, true)

    self:UpdateAwardList(nAllFinishPoint)
end

function UIAchievementAwardView:UpdateAwardList(nAllFinishPoint)
    UIHelper.RemoveAllChildren(self.ScrollViewAchievementAward)

    for _, tAward in ipairs(self.tPointAwardList) do
        UIHelper.AddPrefab(
                PREFAB_ID.WidgetAchievementAward, self.ScrollViewAchievementAward,
                UIHelper.GBKToUTF8(tAward.szName),
                tAward.szMobileImagePath,
                tAward.nTop,
                nAllFinishPoint,
                tAward.nItemType,
                tAward.nItemID
        )
    end

    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewAchievementAward, true, true)
    UIHelper.ScrollViewDoLayout(self.ScrollViewAchievementAward)
    UIHelper.ScrollToLeft(self.ScrollViewAchievementAward, 0)
end

return UIAchievementAwardView