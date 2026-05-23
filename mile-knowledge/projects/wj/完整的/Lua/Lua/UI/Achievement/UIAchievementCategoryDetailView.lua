-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIAchievementCategoryDetailView
-- Date: 2023-02-17 10:10:38
-- Desc: 隐元秘鉴 - 类别成就详情
-- Prefab: PanelAchievementContent
-- ---------------------------------------------------------------------------------

---@class UIAchievementCategoryDetailView
local UIAchievementCategoryDetailView = class("UIAchievementCategoryDetailView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIAchievementCategoryDetailView:_LuaBindList()
    self.BtnClose                                  = self.BtnClose --- 关闭界面
    self.LabelCategoryNameAndProgress              = self.LabelCategoryNameAndProgress --- 左上角的类别名称与进度

    -- 成就
    self.ScrollViewSubCategoryNameAndProgress      = self.ScrollViewSubCategoryNameAndProgress --- 子类别名称与进度 scroll view
    self.ToggleGroupSubCategoryNameAndProgress     = self.ToggleGroupSubCategoryNameAndProgress --- 子类别名称与进度 toggle group

    self.TableViewAchievementDetail                = self.TableViewAchievementDetail --- 符合当前筛选条件的成就信息 tableview（大类别/子类别/右上角额外筛选条件）
    self.TableViewMask                             = self.TableViewMask --- 单页显示的table view遮罩，用于计算table view单页的高度

    -- 五甲
    self.ScrollViewSubCategoryNameAndProgressRank  = self.ScrollViewSubCategoryNameAndProgressRank --- 子类别名称与进度 scroll view
    self.ToggleGroupSubCategoryNameAndProgressRank = self.ToggleGroupSubCategoryNameAndProgressRank --- 子类别名称与进度 toggle group

    self.TableViewAchievementDetailRank            = self.TableViewAchievementDetailRank --- 符合当前筛选条件的成就信息 tableview（大类别/子类别/右上角额外筛选条件）
    self.TableViewMaskRank                         = self.TableViewMaskRank --- 单页显示的table view遮罩，用于计算table view单页的高度

    self.BtnPrevious                               = self.BtnPrevious --- 切换为上一个类别
    self.BtnNext                                   = self.BtnNext --- 切换为下一个类别

    self.EditBoxSearchText                         = self.EditBoxSearchText --- 搜索文本框
    self.BtnCancelSearch                           = self.BtnCancelSearch --- 取消搜索按钮

    self.BtnShowFilterTip                          = self.BtnShowFilterTip --- 是否显示过滤器的button
    self.ImgScreen                                 = self.ImgScreen --- 未过滤时的图标
    self.ImgScreenBg                               = self.ImgScreenBg --- 过滤时的图标

    self.WidgetEmpty                               = self.WidgetEmpty --- 无任何结果时显示的预制
    self.LabelEmpty                                = self.LabelEmpty --- 无任何结果时显示的搜索关键词

    self.BtnFilterMap                              = self.BtnFilterMap --- 地图筛选的按钮
    self.LabelFilterMap                            = self.LabelFilterMap --- 地图筛选的label
    self.WidgetAnchorRightSide                     = self.WidgetAnchorRightSide --- 右侧侧边栏挂载点
end

function UIAchievementCategoryDetailView:OnEnter(nPanelType, nCategoryType, nSelectedSubCategoryType, dwSelectedAchievementID, dwPlayerID, bOpenFromAchievementSystem, bDoNotResetFilterData)
    self.nPanelType               = nPanelType
    self.nCategoryType            = nCategoryType
    self.dwPlayerID               = dwPlayerID

    -- 这俩参数是奖励收集中直接跳转到对应成就来使用的
    self.nSelectedSubCategoryType = nSelectedSubCategoryType
    self.dwSelectedAchievementID  = dwSelectedAchievementID

    AchievementData.SetJumpFromOtherSystem(not bOpenFromAchievementSystem, bDoNotResetFilterData)

    self.tFilteredAchievementIDList = {}

    self.scriptLeave                = UIHelper.GetBindScript(self.WidgetAnchorLeaveFor)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        AchievementData.InitFilterDef(self.dwPlayerID, self.nPanelType, self.nCategoryType)
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIAchievementCategoryDetailView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    Event.Dispatch(EventType.CloseAchievementCategoryDetail)
end

function UIAchievementCategoryDetailView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    local _, _, tableViewAchievementDetail, _ = self:GetPanelContainers()
    ---@param scriptAchievementContent UIAchievementContent
    UIHelper.TableView_addCellAtIndexCallback(tableViewAchievementDetail, function(tableView, nIndex, scriptAchievementContent, node, cell)
        local dwAchievementID = self.tFilteredAchievementIDList[nIndex]
        if scriptAchievementContent and dwAchievementID then
            scriptAchievementContent:OnManualEnter(self.nPanelType, dwAchievementID, self.dwPlayerID)
            scriptAchievementContent:SetGotoMapFunc(function()
                self:GotoMap(dwAchievementID)
            end)
            
            Timer.AddFrame(self, 1, function()
                scriptAchievementContent:AdjustSize()
            end)

            if self.dwSelectedAchievementID and AchievementData.IsSameAchievementOrSeries(self.dwSelectedAchievementID, dwAchievementID) then
                -- 当需要定位到指定成就时，若该成就所属的成就（自身或者系列成就第一个）包含详情页，则自动弹出详情页
                local aAchievement = Table_GetAchievement(dwAchievementID)
                local bHasDetail   = self.nPanelType == ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT
                        and (aAchievement.szSeries ~= "" or aAchievement.szSubAchievements ~= "")

                if bHasDetail then
                    Timer.AddFrame(self, 15, function()
                        local szSeries = aAchievement.szSeries
                        if szSeries and string.len(szSeries) > 0 then
                            --一系列的成就
                            UIMgr.Open(VIEW_ID.PanelAchievementContentListPop, dwAchievementID, self.dwSelectedAchievementID, self.dwPlayerID)
                        else
                            -- 普通成就
                            UIMgr.Open(VIEW_ID.PanelAchievementContentSchedulePop, dwAchievementID, self.dwPlayerID)
                        end
                    end)
                end

                -- 高亮选中的成就
                UIHelper.SetVisible(scriptAchievementContent.ImgAchievementContentBg, false)
                UIHelper.SetVisible(scriptAchievementContent.ImgAchievementContentBgSelected, true)
                scriptAchievementContent:SetContentClickVisible()

                -- LabelTitle和LabelCount字色变为#FFFFFF、LabelContent字色变为#d7f6ff
                UIHelper.SetTextColor(scriptAchievementContent.LabelName, cc.c4b(255, 255, 255, 255))
                UIHelper.SetTextColor(scriptAchievementContent.LabelProgress, cc.c4b(255, 255, 255, 255))
                UIHelper.SetTextColor(scriptAchievementContent.LabelDescription, cc.c4b(215, 246, 255, 255))
            else
                -- 设置回默认的表现
                UIHelper.SetVisible(scriptAchievementContent.ImgAchievementContentBg, true)
                UIHelper.SetVisible(scriptAchievementContent.ImgAchievementContentBgSelected, false)

                UIHelper.SetTextColor(scriptAchievementContent.LabelName, cc.c4b(174, 217, 224, 255))
                UIHelper.SetTextColor(scriptAchievementContent.LabelProgress, cc.c4b(174, 217, 224, 255))
                UIHelper.SetTextColor(scriptAchievementContent.LabelDescription, cc.c4b(121, 173, 181, 255))
            end
        end
    end)

    UIHelper.BindUIEvent(self.BtnPrevious, EventType.OnClick, function()
        local nPrevious, nNext = self:GetPreviousAndNextCategoryType()
        if nPrevious then
            self.nCategoryType = nPrevious
        end

        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnNext, EventType.OnClick, function()
        local nPrevious, nNext = self:GetPreviousAndNextCategoryType()
        if nNext then
            self.nCategoryType = nNext
        end

        self:UpdateInfo()
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
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnShowFilterTip, TipsLayoutDir.BOTTOM_CENTER, AchievementData.GetFilterDef())
    end)

    UIHelper.BindUIEvent(self.BtnFilterMap, EventType.OnClick, function()
        UIHelper.RemoveAllChildren(self.WidgetAnchorRightSide)
        ---@see UIAchievementMapScreen
        UIHelper.AddPrefab(PREFAB_ID.WidgetAchievementMapScreen, self.WidgetAnchorRightSide)
    end)
end

function UIAchievementCategoryDetailView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnFilter, function(szKey, tbInfo)
        if szKey ~= AchievementData.GetFilterDef().Key then
            return
        end

        AchievementData.ApplyFilter(tbInfo, self.nPanelType)
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        --EventType.OnSceneTouchNothing
        --EventType.OnSceneTouchTarget
        UIHelper.SetVisible(self.scriptLeave._rootNode, false)
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        UIHelper.WidgetFoceDoAlign(self)
    end)

    Event.Reg(self, "CloseAchievementMapScreen", function()
        UIHelper.RemoveAllChildren(self.WidgetAnchorRightSide)
        self:UpdateInfo()
    end)
end

function UIAchievementCategoryDetailView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAchievementCategoryDetailView:GetPreviousAndNextCategoryType()
    local nPreviousCategoryType = nil
    local nNextCategoryType     = nil

    AchievementData.EnsureTreeLoaded()

    local tFilteredGeneral = {}

    AchievementData.TraverseTree(
            self.nPanelType,
            nil,
            function(dwGeneral, tCategory, tCategoryAchievementIDList, nCategoryCount, nCategoryFinish)
                table.insert(tFilteredGeneral, tCategory)
            end,
            nil,
            self.dwPlayerID
    )

    local nCurrentIndex = 0
    for nIndex, tCategory in ipairs(tFilteredGeneral) do
        if tCategory.dwSub == self.nCategoryType then
            nCurrentIndex = nIndex
            break
        end
    end

    if nCurrentIndex > 1 then
        nPreviousCategoryType = tFilteredGeneral[nCurrentIndex - 1].dwSub
    end
    if nCurrentIndex < #tFilteredGeneral then
        nNextCategoryType = tFilteredGeneral[nCurrentIndex + 1].dwSub
    end

    return nPreviousCategoryType, nNextCategoryType
end

--- 由于五甲界面没有左右切换的需求，两侧预留的箭头区域会空出来，所以五甲使用另外的一套容器，使界面更加紧凑
function UIAchievementCategoryDetailView:GetPanelContainers()
    if self.nPanelType == ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT then
        return self.ScrollViewSubCategoryNameAndProgress, self.ToggleGroupSubCategoryNameAndProgress, self.TableViewAchievementDetail, self.TableViewMask
    else
        return self.ScrollViewSubCategoryNameAndProgressRank, self.ToggleGroupSubCategoryNameAndProgressRank, self.TableViewAchievementDetailRank, self.TableViewMaskRank
    end
end

function UIAchievementCategoryDetailView:UpdateInfo()
    local scrollViewSubCategoryNameAndProgress, toggleGroupSubCategoryNameAndProgress, tableViewAchievementDetail, _ = self:GetPanelContainers()

    local nPrevious, nNext                                                                                           = self:GetPreviousAndNextCategoryType()
    UIHelper.SetVisible(self.BtnPrevious, nPrevious ~= nil and self.nPanelType == ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT)
    UIHelper.SetVisible(self.BtnNext, nNext ~= nil and self.nPanelType == ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT)

    UIHelper.SetVisible(self.ToggleGroupSubCategoryNameAndProgress, self.nPanelType == ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT)
    UIHelper.SetVisible(self.TableViewMask, self.nPanelType == ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT)

    UIHelper.SetVisible(self.ToggleGroupSubCategoryNameAndProgressRank, self.nPanelType == ACHIEVEMENT_PANEL_TYPE.TOP_RECORD)
    UIHelper.SetVisible(self.TableViewMaskRank, self.nPanelType == ACHIEVEMENT_PANEL_TYPE.TOP_RECORD)

    if AchievementData.GetFilterData().dwAchievementID then
        -- 显示指定成就时隐藏切换类别按钮
        UIHelper.SetVisible(self.BtnPrevious, false)
        UIHelper.SetVisible(self.BtnNext, false)
    end

    -- 打开页面时将过滤器收起来
    UIHelper.SetSelected(self.TogShowFilterTip, false)

    -- 初始化时保留搜索词
    UIHelper.SetString(self.EditBoxSearchText, AchievementData.GetFilterData().szAKey)

    local szFilterMapName = AchievementData.GetFilterMapName()
    UIHelper.SetString(self.LabelFilterMap, UIHelper.TruncateStringReturnOnlyResult(szFilterMapName, 3))

    UIHelper.SetButtonState(self.BtnFilterMap, not AchievementData.bJumpFromOtherSystem and BTN_STATE.Normal or BTN_STATE.Disable)

    local bHasFilter = AchievementData.HasFilter(ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT)
    UIHelper.SetVisible(self.ImgScreen, not bHasFilter)
    UIHelper.SetVisible(self.ImgScreenBg, bHasFilter)

    UIHelper.ToggleGroupRemoveAllToggle(toggleGroupSubCategoryNameAndProgress)
    UIHelper.RemoveAllChildren(scrollViewSubCategoryNameAndProgress)

    UIHelper.TableView_init(tableViewAchievementDetail, 0, PREFAB_ID.WidgetAchievementContent)
    UIHelper.TableView_reloadData(tableViewAchievementDetail)

    local nCurrentSubCategoryIndex = 1

    local nDefaultSelectedIndex    = 1
    local tDefaultSelectedTogSubCategoryInfo
    local tDefaultSelectedSubCategoryAchievementIDList

    AchievementData.TraverseTree(
            self.nPanelType,
            function(dwGeneral, nAllCount, nAllFinish)
                if dwGeneral == ACHIEVEMENT_PANEL_TYPE.TOP_RECORD then
                    -- 五甲界面是直接展示全部类别，所以在大类这个回调中更新全部数据
                    UIHelper.SetString(
                            self.LabelCategoryNameAndProgress,
                            string.format(
                                    "%s（%d/%d）",
                                    "五甲", nAllFinish, nAllCount
                            )
                    )
                end
            end,
            function(dwGeneral, tCategory, tCategoryAchievementIDList, nCategoryCount, nCategoryFinish)
                if tCategory.dwSub ~= self.nCategoryType then
                    return
                end

                if dwGeneral == ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT then
                    -- 更新大类别的成就进度
                    UIHelper.SetString(
                            self.LabelCategoryNameAndProgress,
                            string.format(
                                    "%s（%d/%d）",
                                    tCategory.szName, nCategoryFinish, nCategoryCount
                            )
                    )
                end
            end,
            function(dwGeneral, tCategory, tSubCategory, tSubCategoryAchievementIDList, nSubCategoryCount, nSubCategoryFinish)
                -- 成就页面仅显示单个类别
                local bMatchCategory            = tCategory.dwSub == self.nCategoryType
                -- 五甲页面显示全部大类别
                local bTopRecordShowAllCategory = dwGeneral == ACHIEVEMENT_PANEL_TYPE.TOP_RECORD and self.nCategoryType == ACHIEVEMENT_CATEGORY_TYPE.SHOW_ALL

                if not (bMatchCategory or bTopRecordShowAllCategory) then
                    return
                end

                local szName             = tSubCategory.szName

                local bAddCategoryPrefix = bTopRecordShowAllCategory
                if tCategory.szName == "秘境" then
                    -- 如果是秘境分类，则不添加这个前缀，避免过长
                    bAddCategoryPrefix = false
                end
                if bAddCategoryPrefix then
                    szName = string.format("%s-%s", tCategory.szName, tSubCategory.szName)
                end

                local widgetSubCategoryInfoScript = UIHelper.AddPrefab(
                        PREFAB_ID.WidgetAchievementContentClassify, scrollViewSubCategoryNameAndProgress,
                        szName, nSubCategoryFinish, nSubCategoryCount
                )
                UIHelper.BindUIEvent(widgetSubCategoryInfoScript.TogSubCategoryInfo, EventType.OnClick, function()
                    self:ShowAchievements(tSubCategoryAchievementIDList)
                end)

                UIHelper.SetToggleGroupIndex(widgetSubCategoryInfoScript.TogSubCategoryInfo, ToggleGroupIndex.AchievementSubCategory)

                UIHelper.SetSelected(widgetSubCategoryInfoScript.TogSubCategoryInfo, false)

                -- 默认选中第一个或者被指定的子类别（后者优先）
                local bNeedSelect = false

                if self.nSelectedSubCategoryType and tSubCategory.dwDetail == self.nSelectedSubCategoryType then
                    bNeedSelect = true
                end

                if nCurrentSubCategoryIndex == 1 then
                    -- 默认选中第一个并显示
                    bNeedSelect = true
                end

                if bNeedSelect then
                    nDefaultSelectedIndex                        = nCurrentSubCategoryIndex
                    tDefaultSelectedTogSubCategoryInfo           = widgetSubCategoryInfoScript.TogSubCategoryInfo
                    tDefaultSelectedSubCategoryAchievementIDList = tSubCategoryAchievementIDList
                end

                nCurrentSubCategoryIndex = nCurrentSubCategoryIndex + 1
            end,
            self.dwPlayerID
    )

    UIHelper.CascadeDoLayoutDoWidget(scrollViewSubCategoryNameAndProgress, true, true)
    UIHelper.ScrollViewDoLayout(scrollViewSubCategoryNameAndProgress)

    -- 滚动到默认选中的子类别的位置
    UIHelper.ScrollToIndex(scrollViewSubCategoryNameAndProgress, nDefaultSelectedIndex - 1, 0)

    if tDefaultSelectedTogSubCategoryInfo and tDefaultSelectedSubCategoryAchievementIDList then
        -- 选中并显示默认选中的子类别
        UIHelper.SetSelected(tDefaultSelectedTogSubCategoryInfo, true)
        self:ShowAchievements(tDefaultSelectedSubCategoryAchievementIDList)
    end

    UIHelper.SetVisible(self.WidgetEmpty, UIHelper.GetChildrenCount(scrollViewSubCategoryNameAndProgress) == 0)
    local szEmptyTip = string.format("暂无【%s】相关成就", AchievementData.GetFilterData().szAKey)
    if string.is_nil(AchievementData.GetFilterData().szAKey) then
        szEmptyTip = "暂无相关成就"
    end
    UIHelper.SetString(self.LabelEmpty, szEmptyTip)
end

function UIAchievementCategoryDetailView:ShowAchievements(tSubCategoryAchievementIDList)
    local _, _, tableViewAchievementDetail, tableViewMask = self:GetPanelContainers()

    local tAchievements                                   = tSubCategoryAchievementIDList

    -- bd版完成状态过滤改为在data中搜索时一起处理，这里不需要再处理了
    self.tFilteredAchievementIDList                       = tAchievements

    if AchievementData.GetFilterData().dwAchievementID and #tAchievements ~= 0 then
        -- 显示指定成就时，强制替换成就为指定成就，这样可以避免指定的是系列成就中非第一个时，会显示的是第一个成就的问题
        self.tFilteredAchievementIDList = { AchievementData.GetFilterData().dwAchievementID }
    end

    UIHelper.TableView_init(tableViewAchievementDetail, #self.tFilteredAchievementIDList, PREFAB_ID.WidgetAchievementContent)
    UIHelper.TableView_reloadData(tableViewAchievementDetail)

    if self.dwSelectedAchievementID then
        -- 若指定了成就，则滚动到对应位置
        local nIndex
        for idx, dwAchievementID in ipairs(self.tFilteredAchievementIDList) do
            if AchievementData.IsSameAchievementOrSeries(self.dwSelectedAchievementID, dwAchievementID) then
                nIndex = idx
                break
            end
        end
        if nIndex then
            -- 整个table view的最外层组件，可能跨越一个屏幕，基于这个计算每个cell的高度
            local uiWholeTable                     = UIHelper.GetChildren(tableViewAchievementDetail)[1]
            local nCellCount                       = #self.tFilteredAchievementIDList

            -- 单个cell的高度
            local nCellHeight                      = UIHelper.GetHeight(uiWholeTable) / nCellCount
            -- 实际显示在屏幕中的table的部分的高度
            local nPageHeight                      = UIHelper.GetHeight(tableViewMask)

            -- 单个屏幕中显示的cell数目
            local nCellCountPerPage                = math.floor(nPageHeight / nCellHeight)
            -- 带小数点的cell个数
            local fDecimalFractionCellCountPerPage = nPageHeight / nCellHeight - nCellCountPerPage

            -- table view默认会在最下方，offset是y轴移动距离，负值时表示整个table view在屏幕中往下拖动，效果就是上面的cell会慢慢显示在屏幕中
            -- 由于table view的可视区域可能不是cell的整数倍，因此需要先往上拖动 fDecimalFractionCellCountPerPage，初始状态时的第一个完整可见的格子会在屏幕最上方
            -- 然后往下拖动 nCellCount - nCellCountPerPage 后，第一个cell会显示在屏幕最上方
            -- 如果想要第 nIndex 个cell显示在屏幕最上方，需要减少拖动 nIndex - 1 个cell的距离
            UIHelper.TableView_scrollTo(tableViewAchievementDetail, (fDecimalFractionCellCountPerPage - (nCellCount - nCellCountPerPage - (nIndex - 1))) * nCellHeight)
        end
    end
end

function UIAchievementCategoryDetailView:GotoMap(dwAchievementID)
    local aMapAchievement = Table_GetAchievement(dwAchievementID)

    local tGotoMapID      = {}
    for s1 in string.gmatch(aMapAchievement.szSceneID, "%d+") do
        local dwMapID = tonumber(s1)
        if dwMapID ~= 0 then
            local _, nMapType = GetMapParams(dwMapID)
            local bGotoType   = nMapType and (nMapType == MAP_TYPE.DUNGEON or nMapType == MAP_TYPE.NORMAL_MAP or nMapType == MAP_TYPE.TONG_DUNGEON)
            if bGotoType then
                table.insert(tGotoMapID, dwMapID)
            end
        end
    end

    if #tGotoMapID <= 0 then
        return
    end

    local fnGotoMap = function(dwMapID)
        local _, nMapType = GetMapParams(dwMapID)
        if nMapType == MAP_TYPE.DUNGEON then
            local tRecord = {
                dwTargetMapID = dwMapID,
            }
            if not UIMgr.IsViewOpened(VIEW_ID.PanelDungeonEntrance, true) then
                UIMgr.Open(VIEW_ID.PanelDungeonEntrance, tRecord)
            else
                UIMgr.CloseWithCallBack(VIEW_ID.PanelDungeonEntrance, function()
                    UIMgr.Open(VIEW_ID.PanelDungeonEntrance, tRecord)
                end)
            end
        else
            local tRecord = {
                nTraceMapID = dwMapID,
            }
            if not UIMgr.IsViewOpened(VIEW_ID.PanelWorldMap, true) then
                local viewScript = UIMgr.Open(VIEW_ID.PanelWorldMap, tRecord)
                viewScript:SetJumpToMiddle(true)
                viewScript:TraceMap(dwMapID, true)
            else
                UIMgr.CloseWithCallBack(VIEW_ID.PanelWorldMap, function()
                    local viewScript = UIMgr.Open(VIEW_ID.PanelWorldMap, tRecord)
                    viewScript:SetJumpToMiddle(true)
                    viewScript:TraceMap(dwMapID, true)
                end)
            end
        end
    end

    if #tGotoMapID > 1 then
        local tGotoBtn = {}
        for _, dwMapID in ipairs(tGotoMapID) do
            local tSubBtn = {
                szName = UIHelper.GBKToUTF8(Table_GetMapName(dwMapID)),
                OnClick = function()
                    fnGotoMap(dwMapID)
                end,
            }
            table.insert(tGotoBtn, tSubBtn)
        end
        self.scriptLeave:UpdateByFunc(tGotoBtn, 6)
        UIHelper.SetVisible(self.scriptLeave._rootNode, true)
    else
        fnGotoMap(tGotoMapID[1])
    end

end

return UIAchievementCategoryDetailView