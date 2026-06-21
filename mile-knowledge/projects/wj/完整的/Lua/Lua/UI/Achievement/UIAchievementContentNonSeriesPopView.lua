-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIAchievementContentNonSeriesPopView
-- Date: 2023-02-20 20:00:36
-- Desc: 隐元秘鉴 - 类别成就详情 - 成就widget - 成就详细信息
-- Prefab: PanelAchievementContentSchedulePop
-- ---------------------------------------------------------------------------------

local UIAchievementContentNonSeriesPopView = class("UIAchievementContentNonSeriesPopView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIAchievementContentNonSeriesPopView:_LuaBindList()
    self.BtnClose                    = self.BtnClose --- 关闭界面
    self.LabelName                   = self.LabelName --- 名称
    self.WidgetAchievementLabel      = self.WidgetAchievementLabel --- 成就描述
    self.LabelDescriptionAndProgress = self.LabelDescriptionAndProgress --- 描述 和 进度（配有计数器时显示）
    self.ImgFinishStatus             = self.ImgFinishStatus --- 是否完成（仅完成时显示）
    self.LayoutRewardItem            = self.LayoutRewardItem --- 奖励的道具和资历

    self.LabelCounterProgress        = self.LabelCounterProgress --- 进度（配有计数器时显示）（已废弃，该信息与描述一起显示了，隐藏即可）

    self.ScrollViewSubAchievement    = self.ScrollViewSubAchievement --- 子成就（若有）的 scroll view
    self.LayoutSubAchievement        = self.LayoutSubAchievement --- 子成就（若有）的 layout
end

function UIAchievementContentNonSeriesPopView:OnEnter(dwAchievementID, dwPlayerID)
    self.dwAchievementID = dwAchievementID
    self.dwPlayerID = dwPlayerID

    self.aAchievement    = Table_GetAchievement(dwAchievementID)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIAchievementContentNonSeriesPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAchievementContentNonSeriesPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIAchievementContentNonSeriesPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.CloseSubOrSeriesAchievement, function()
        UIMgr.Close(self)
    end)
end

function UIAchievementContentNonSeriesPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAchievementContentNonSeriesPopView:UpdateInfo()
    -- todo: 这段代码与 UIAchievementContent 有较多重叠，看看有没有办法抽取到 Data 文件中，以及有无必要（比如是否会导致两边强耦合）
    local szDescription                          = UIHelper.GBKToUTF8(self.aAchievement.szDesc)
    local bFoundCounter, nProgress, nMaxProgress = AchievementData.GetAchievementCountInfo(self.aAchievement.szCounters)
    if bFoundCounter then
        szDescription = string.format("%s %d/%d", szDescription, nProgress, nMaxProgress)
    end
    local bFinish   = AchievementData.IsAchievementAcquired(self.dwAchievementID, self.aAchievement, self.dwPlayerID)
    local _, nPoint = Table_GetAchievementInfo(self.dwAchievementID)

    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(self.aAchievement.szName))
    UIHelper.SetString(self.LabelDescriptionAndProgress, szDescription)
    UIHelper.SetVisible(self.ImgFinishStatus, bFinish)

    -- 与系列成就同样做法，将进度改与名称放在一起，避免重叠
    UIHelper.SetVisible(self.LabelCounterProgress, false)

    UIHelper.RemoveAllChildren(self.LayoutRewardItem)

    -- 奖励的道具
    if self.aAchievement.dwItemType ~= 0 and self.aAchievement.dwItemID ~= 0 then
        local tRewardItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayoutRewardItem)

        tRewardItemScript:OnInitWithTabID(self.aAchievement.dwItemType, self.aAchievement.dwItemID)
        tRewardItemScript:SetClickCallback(function(nItemType, nItemIndex)
            Timer.AddFrame(self, 1, function()
                TipsHelper.ShowItemTips(tRewardItemScript._rootNode, self.aAchievement.dwItemType, self.aAchievement.dwItemID, false)
            end)
        end)
    end

    -- 奖励的资历点数
    local tPointItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayoutRewardItem)
    tPointItemScript:OnInitCurrency(CurrencyType.AchievementPoint, nPoint)
    tPointItemScript:SetSelectEnable(false)
    UIHelper.SetVisible(tPointItemScript.LabelPolishCount, false)

    if AchievementData.HasPrefixOrPostfix(self.dwAchievementID) then
        UIHelper.AddPrefab(PREFAB_ID.WidgetDesignationIcon, self.LayoutRewardItem,
                           self.dwAchievementID
        )
    end

    UIHelper.LayoutDoLayout(self.LayoutRewardItem)
    UIHelper.LayoutDoLayout(self.WidgetAchievementLabel)

    self:UpdateSubAchievements()
end

function UIAchievementContentNonSeriesPopView:UpdateSubAchievements()
    local hPlayer      = GetClientPlayer()
    local aAchievement = Table_GetAchievement(self.dwAchievementID)

    UIHelper.RemoveAllChildren(self.ScrollViewSubAchievement)
    if not aAchievement then
        return
    end

    local szSubAchievements = aAchievement.szSubAchievements
    for s in string.gmatch(szSubAchievements, "%d+") do
        local dwSubAchievement = tonumber(s)
        local aSubAchievement  = Table_GetAchievement(dwSubAchievement)
        if aSubAchievement then
            UIHelper.AddPrefab(
                    PREFAB_ID.WidgetAchievementContentScheduleCell, self.ScrollViewSubAchievement,
                    dwSubAchievement
            )
        end
    end

    Timer.AddFrame(self, 1, function()
        UIHelper.ScrollViewDoLayout(self.ScrollViewSubAchievement)
        UIHelper.ScrollToTop(self.ScrollViewSubAchievement, 0)
    end)
end

return UIAchievementContentNonSeriesPopView