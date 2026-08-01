-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIAchievementContentSeriesAchievement
-- Date: 2023-02-21 16:14:26
-- Desc: 隐元秘鉴 - 类别成就详情 - 成就widget - 系列成就详细信息 - 系列成就widget
-- Prefab: WidgetAchievementContentPopList
-- ---------------------------------------------------------------------------------

local UIAchievementContentSeriesAchievement = class("UIAchievementContentSeriesAchievement")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIAchievementContentSeriesAchievement:_LuaBindList()
    self.LayoutTopLevel              = self.LayoutTopLevel --- 最上层 layout

    self.LabelDescriptionAndProgress = self.LabelDescriptionAndProgress --- 描述 和 进度（配有计数器时显示）
    self.ImgFinishStatus             = self.ImgFinishStatus --- 是否完成（仅完成时显示）

    self.LayoutRewardItem            = self.LayoutRewardItem --- 奖励的道具和资历

    self.ScrollViewSubAchievement    = self.ScrollViewSubAchievement --- 子成就（若有）的 scroll view
    self.LayoutSubAchievement        = self.LayoutSubAchievement --- 子成就（若有）的 layout

    self.TogAchievement              = self.TogAchievement --- 是否显示子组件的 toggle

    self.LabelName                   = self.LabelName --- 名称
end

function UIAchievementContentSeriesAchievement:OnEnter(dwAchievementID)
    self.dwAchievementID = dwAchievementID

    self.aAchievement    = Table_GetAchievement(dwAchievementID)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIAchievementContentSeriesAchievement:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAchievementContentSeriesAchievement:BindUIEvent()

end

function UIAchievementContentSeriesAchievement:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIAchievementContentSeriesAchievement:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAchievementContentSeriesAchievement:UpdateInfo()
    local szDescription                          = UIHelper.GBKToUTF8(self.aAchievement.szDesc)
    local bFoundCounter, nProgress, nMaxProgress = AchievementData.GetAchievementCountInfo(self.aAchievement.szCounters)
    if bFoundCounter then
        szDescription = string.format("%s %d/%d", szDescription, nProgress, nMaxProgress)
    end
    local bFinish   = AchievementData.IsAchievementAcquired(self.dwAchievementID, self.aAchievement, nil, true)
    local _, nPoint = Table_GetAchievementInfo(self.dwAchievementID)

    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(self.aAchievement.szName))
    UIHelper.SetString(self.LabelDescriptionAndProgress, szDescription)
    UIHelper.SetVisible(self.ImgFinishStatus, bFinish)

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

    self:UpdateSubAchievements()

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutTopLevel, true, false)
end

function UIAchievementContentSeriesAchievement:UpdateSubAchievements()
    local hPlayer      = GetClientPlayer()
    local aAchievement = Table_GetAchievement(self.dwAchievementID)

    UIHelper.RemoveAllChildren(self.ScrollViewSubAchievement)
    UIHelper.SetVisible(self.ScrollViewSubAchievement, false)
    if not aAchievement then
        return
    end

    local bEmpty = true
    local szSubAchievements = aAchievement.szSubAchievements
    for s in string.gmatch(szSubAchievements, "%d+") do
        local dwSubAchievement = tonumber(s)
        local aSubAchievement  = Table_GetAchievement(dwSubAchievement)
        if aSubAchievement then
            bEmpty = false
            UIHelper.AddPrefab(
                    PREFAB_ID.WidgetAchievementContentScheduleCell, self.ScrollViewSubAchievement,
                    dwSubAchievement
            )
        end
    end

    --UIHelper.SetVisible(self.ScrollViewSubAchievement, not bEmpty)
    -- note: 与dx保持一致，系列成就不显示子成就信息（成就515，PS:如果显示的话，子成就预制会不显示，到时候要启用的话，需要看看具体咋回事）
    UIHelper.SetVisible(self.ScrollViewSubAchievement, false)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSubAchievement)
end

return UIAchievementContentSeriesAchievement