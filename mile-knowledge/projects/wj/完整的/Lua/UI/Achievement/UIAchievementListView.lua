-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIAchievementListView
-- Date: 2023-02-16 10:35:52
-- Desc: 隐元秘鉴 - 成就类别列表
-- Prefab: PanelAchievementList
-- ---------------------------------------------------------------------------------

---@class UIAchievementListView
local UIAchievementListView = class("UIAchievementListView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIAchievementListView:_LuaBindList()
    self.BtnClose               = self.BtnClose --- 关闭界面

    self.ScrollViewCategoryList = self.ScrollViewCategoryList --- 成就类别列表的 scroll view
    self.LayoutCategoryList     = self.LayoutCategoryList --- 成就类别列表的 layout

    self.EditBoxSearchText      = self.EditBoxSearchText --- 搜索文本框
    self.BtnCancelSearch        = self.BtnCancelSearch --- 取消搜索按钮

    self.BtnShowFilterTip       = self.BtnShowFilterTip --- 是否显示过滤器的button
    self.ImgScreen              = self.ImgScreen --- 未过滤时的图标
    self.ImgScreenBg            = self.ImgScreenBg --- 过滤时的图标

    self.WidgetEmpty            = self.WidgetEmpty --- 无任何结果时显示的预制
    self.LabelEmpty             = self.LabelEmpty --- 无任何结果时显示的搜索关键词
    
    self.BtnFilterMap           = self.BtnFilterMap --- 地图筛选的按钮
    self.LabelFilterMap         = self.LabelFilterMap --- 地图筛选的label
    self.WidgetAnchorRightSide  = self.WidgetAnchorRightSide --- 右侧侧边栏挂载点
end

function UIAchievementListView:OnEnter(dwPlayerId, fnCustomFilterDataCallback)
    self.dwPlayerID = dwPlayerId

    --- 若设置了自定义过滤数据回调，则说明是从其他系统跳转过来的，设置为需要使用单独的筛选数据，并每次会重置，不影响玩家自己设置的数据
    AchievementData.SetJumpFromOtherSystem(fnCustomFilterDataCallback ~= nil)
    if fnCustomFilterDataCallback ~= nil then
        fnCustomFilterDataCallback()
    end

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIAchievementListView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAchievementListView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxSearchText, function()
        AchievementData.SetFilterData_szAKey(UIHelper.GetString(self.EditBoxSearchText))
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnCancelSearch, EventType.OnClick, function()
        AchievementData.SetFilterData_szAKey("")
        UIHelper.SetString(self.EditBoxSearchText, "")
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnShowFilterTip, EventType.OnClick, function()
        if not self.bInitFilter then
            AchievementData.InitFilterDef(self.dwPlayerID, ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT, nil)
            self.bInitFilter = true
        end
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnShowFilterTip, TipsLayoutDir.BOTTOM_CENTER, AchievementData.GetFilterDef())
    end)

    UIHelper.BindUIEvent(self.BtnFilterMap, EventType.OnClick, function()
        UIHelper.RemoveAllChildren(self.WidgetAnchorRightSide)
        ---@see UIAchievementMapScreen
        UIHelper.AddPrefab(PREFAB_ID.WidgetAchievementMapScreen, self.WidgetAnchorRightSide)
    end)
end

function UIAchievementListView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnFilter, function(szKey, tbInfo)
        if szKey ~= AchievementData.GetFilterDef().Key then
            return
        end

        AchievementData.ApplyFilter(tbInfo, ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT)
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.CloseAchievementCategoryDetail, function()
        -- 成就类别详情页打开时会更新筛选器中的类别设置，为了确保关闭后回来列表时仍显示正确，在其关闭时刷新列表页这里的筛选设置
        -- AchievementData.InitFilterDef(self.dwPlayerID, ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT, nil)
    end)
    
    Event.Reg(self, "CloseAchievementMapScreen", function()
        UIHelper.RemoveAllChildren(self.WidgetAnchorRightSide)
        self:UpdateInfo()
    end)
end

function UIAchievementListView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAchievementListView:UpdateInfo()
    -- 初始化时保留搜索词
    UIHelper.SetString(self.EditBoxSearchText, AchievementData.GetFilterData().szAKey)

    local szFilterMapName = AchievementData.GetFilterMapName()
    UIHelper.SetString(self.LabelFilterMap, UIHelper.TruncateStringReturnOnlyResult(szFilterMapName, 3))
    
    UIHelper.SetButtonState(self.BtnFilterMap, not AchievementData.bJumpFromOtherSystem and BTN_STATE.Normal or BTN_STATE.Disable)

    local bHasFilter = AchievementData.HasFilter(ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT)
    UIHelper.SetVisible(self.ImgScreen, not bHasFilter)
    UIHelper.SetVisible(self.ImgScreenBg, bHasFilter)

    UIHelper.RemoveAllChildren(self.ScrollViewCategoryList)

    AchievementData.TraverseTree(
            ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT,
            function(dwGeneral, nAllCount, nAllFinish)
                -- todo: 需要确认过滤后没有任何结果时如何显示，目前交互中是有个专门的表现，但是看预制好像没发现这个东西，全部做完后问问策划
                --local hNoFind 	= hPage:Lookup("", "Text_Not" .. szAdd .. "Find")
                --if nAllCount == 0 then
                --    hNoFind:Show()
                --else
                --    hNoFind:Hide()
                --end
            end,
            function(dwGeneral, tCategory, tCategoryAchievementIDList, nCategoryCount, nCategoryFinish)
                -- 仅显示过滤后有符合条件成就的类别
                UIHelper.AddPrefab(PREFAB_ID.WidgetAchievementListEntrance, self.ScrollViewCategoryList,
                                   dwGeneral, tCategory.dwSub, tCategory.szName, nCategoryFinish, nCategoryCount, self.dwPlayerID)
            end,
            function(dwGeneral, tCategory, tSubCategory, tSubCategoryAchievementIDList, nSubCategoryCount, nSubCategoryFinish)
                -- do nothing
            end,
            self.dwPlayerID
    )

    UIHelper.SetVisible(self.WidgetEmpty, UIHelper.GetChildrenCount(self.ScrollViewCategoryList) == 0)
    UIHelper.SetString(self.LabelEmpty, string.format("暂无【%s】相关成就", AchievementData.GetFilterData().szAKey))

    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewCategoryList, true, true)
    UIHelper.ScrollViewDoLayout(self.ScrollViewCategoryList)
    UIHelper.ScrollToTop(self.ScrollViewCategoryList, 0)
end

return UIAchievementListView