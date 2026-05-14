-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIAchievementContentSeriesPopView
-- Date: 2023-02-21 15:48:21
-- Desc: 隐元秘鉴 - 类别成就详情 - 成就widget - 系列成就详细信息
-- Prefab: PanelAchievementContentListPop
-- ---------------------------------------------------------------------------------

local UIAchievementContentSeriesPopView = class("UIAchievementContentSeriesPopView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIAchievementContentSeriesPopView:_LuaBindList()
    self.BtnClose                    = self.BtnClose --- 关闭界面
    self.LabelName                   = self.LabelName --- 成就名称
    self.ScrollViewSeriesAchievement = self.ScrollViewSeriesAchievement --- 各个系列成就的 scroll view
    self.LayoutSeriesAchievement     = self.LayoutSeriesAchievement --- 各个系列成就的 layout
end

function UIAchievementContentSeriesPopView:OnEnter(dwAchievementID, dwSelectedAchievementID, dwPlayerID)
    self.dwAchievementID         = dwAchievementID
    self.dwPlayerID              = dwPlayerID

    -- 默认选中的系列成就
    self.dwSelectedAchievementID = dwSelectedAchievementID

    self.aAchievement            = Table_GetAchievement(dwAchievementID)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIAchievementContentSeriesPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAchievementContentSeriesPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIAchievementContentSeriesPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.CloseSubOrSeriesAchievement, function()
        UIMgr.Close(self)
    end)
end

function UIAchievementContentSeriesPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAchievementContentSeriesPopView:UpdateInfo(dwPlayerID)
    self.dwPlayerId = dwPlayerID
    UIHelper.SetString(self.LabelName, "成就详情")

    self:UpdateSeries()
end

function UIAchievementContentSeriesPopView:UpdateSeries()
    UIHelper.RemoveAllChildren(self.ScrollViewSeriesAchievement)

    local tSelectSeriesScript
    -- 按下列顺序尝试默认选中某个系列成就
    --      从外部传入的指定系列成就
    --      第一个未完成的系列成就
    --      完全完成时，最后一个系列成就
    local dwCurrentAchievement     = self.dwSelectedAchievementID or AchievementData.GetCurrentStageSeriesAchievementID(self.dwAchievementID, self.dwPlayerID)

    local tSeriesAchievementIDList = {}
    for s in string.gmatch(self.aAchievement.szSeries, "%d+") do
        local dwAchievement = tonumber(s)

        table.insert(tSeriesAchievementIDList, dwAchievement)
    end

    local nCurrentIndex = 1
    for idx, dwAchievement in ipairs(tSeriesAchievementIDList) do
        local tScriptSeries = UIHelper.AddPrefab(PREFAB_ID.WidgetAchievementContentPopList, self.ScrollViewSeriesAchievement,
                                                 dwAchievement
        )
        -- 默认隐藏
        UIHelper.SetSelected(tScriptSeries.TogAchievement, false)

        UIHelper.BindUIEvent(tScriptSeries.TogAchievement, EventType.OnClick, function()
            UIHelper.LayoutDoLayout(tScriptSeries.LayoutTopLevel)

            UIHelper.ScrollViewDoLayout(self.ScrollViewSeriesAchievement)
            UIHelper.ScrollToIndex(self.ScrollViewSeriesAchievement, idx - 1, 0)
        end)

        if dwAchievement == dwCurrentAchievement then
            tSelectSeriesScript = tScriptSeries
            nCurrentIndex       = idx
        end
    end

    if tSelectSeriesScript then
        UIHelper.SetSelected(tSelectSeriesScript.TogAchievement, true)
    end

    Timer.AddFrame(self, 2, function()
        UIHelper.ScrollViewDoLayout(self.ScrollViewSeriesAchievement)
        UIHelper.ScrollToIndex(self.ScrollViewSeriesAchievement, nCurrentIndex - 1, 0)
    end)
end

return UIAchievementContentSeriesPopView