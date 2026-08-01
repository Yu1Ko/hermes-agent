-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIAchievementMapScreen
-- Date: 2025-01-09 15:39:58
-- Desc: 成就地图筛选
-- Prefab: WidgetAchievementMapScreen
-- ---------------------------------------------------------------------------------

---@class UIAchievementMapScreen
local UIAchievementMapScreen = class("UIAchievementMapScreen")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIAchievementMapScreen:_LuaBindList()
    self.BtnCloseRight        = self.BtnCloseRight --- 关闭界面

    self.WidgetAnchorFilter   = self.WidgetAnchorFilter --- 层级筛选脚本的挂载点
    self.BtnReset             = self.BtnReset --- 重置按钮

    self.TogType              = self.TogType --- 按区域树筛选
    self.TogSearch            = self.TogSearch --- 按关键字筛选

    self.WidgetChooseType     = self.WidgetChooseType --- 按区域树筛选的上层组件
    self.WidgetSearchMap      = self.WidgetSearchMap --- 按关键字筛选的上层组件

    self.EditSearchMap        = self.EditSearchMap --- 关键字的editbox
    self.WidgetEmptySearchMap = self.WidgetEmptySearchMap --- 无搜索结果时的显示组件
    self.ScrollViewSearchMap  = self.ScrollViewSearchMap --- 搜索结果列表的scrollview
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIAchievementMapScreen:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIAchievementMapScreen:OnEnter()
    self.tbMenu = self:BuildMenu()

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        local aniAll = UIHelper.GetChildByName(self._rootNode, "AniAll")
        UIHelper.PlayAni(self, aniAll, "AniRightShow")
    end

    local bShowType = UIHelper.GetSelected(self.TogType)
    self:UpdateInfo(bShowType)
end

function UIAchievementMapScreen:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAchievementMapScreen:BindUIEvent()
    local tToggleList = { self.TogType, self.TogSearch }
    for _, tToggle in ipairs(tToggleList) do
        UIHelper.SetToggleGroupIndex(tToggle, ToggleGroupIndex.AchievementFilterMap)
        UIHelper.SetClickInterval(tToggle, 0)
        
        UIHelper.BindUIEvent(tToggle, EventType.OnSelectChanged, function(_, bSelected)
            if bSelected then
                local bShowType = tToggle == self.TogType
                self:UpdateInfo(bShowType)
            end
        end)
    end
    UIHelper.SetSelected(self.TogType, true)

    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function()
        Event.Dispatch("CloseAchievementMapScreen")
    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function()
        if UIHelper.GetSelected(self.TogType) then
            ---@type UITeamRecruitNavigationFilter
            local navigationFilter = UIHelper.GetBindScript(self.WidgetAnchorFilter)
            navigationFilter:SetChecked(self.tbMenu, true)
        else
            self:InitFilterBySearchKeyWord()
        end
    end)

    UIHelper.RegisterEditBoxEnded(self.EditSearchMap, function()
        self:UpdateFilterBySearchKeyWordInfo()
    end)
end

function UIAchievementMapScreen:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIAchievementMapScreen:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAchievementMapScreen:UpdateInfo(bShowType)
    UIHelper.SetVisible(self.WidgetChooseType, bShowType)
    UIHelper.SetVisible(self.WidgetSearchMap, not bShowType)

    if bShowType then
        self:InitFilterByMapTree()
    else
        self:InitFilterBySearchKeyWord()
    end
end

function UIAchievementMapScreen:CheckedCallback(tbMenu)
    if not tbMenu then
        return
    end

    local dwMapID, szMapName = table.unpack(tbMenu.UserData)
    if szMapName == "当前地图" then
        --- 替换为实际的名称，用于后续显示
        szMapName = UIHelper.GBKToUTF8(Table_GetMapName(dwMapID) or "")
    end

    if dwMapID ~= nil or szMapName == "全部" then
        --- 与dx的行为保持一致，以下几种情况覆盖筛选数据
        --- 实际选择了一个地图
        --- 选择了全部，将数据置空
        AchievementData.SetFilterData_m_dwASceneID_And_m_dwASceneName(dwMapID, szMapName)
    end

    local aniAll = UIHelper.GetChildByName(self._rootNode, "AniAll")
    UIHelper.PlayAni(self, aniAll, "AniRightHide", function ()
        Event.Dispatch("CloseAchievementMapScreen")
    end)
end

function UIAchievementMapScreen:InitFilterByMapTree()
    ---@type UITeamRecruitNavigationFilter
    local navigationFilter = UIHelper.GetBindScript(self.WidgetAnchorFilter)
    navigationFilter:OnInit(PREFAB_ID.WidgetBreadNaviCell, PREFAB_ID.WidgetFilterItemCell, function(tbMenu) 
        self:CheckedCallback(tbMenu)
    end, nil, nil, PREFAB_ID.WidgetBreadNaviCellLong)

    navigationFilter:SetChecked(self.tbMenu, true)
end

function UIAchievementMapScreen:BuildMenu()
    local tbMenu = {}

    local g2u    = UIHelper.GBKToUTF8

    TeamBuilding.SetMenuInfo(tbMenu, "地图类型", false, false, { nil, "地图类型" }, nil, false)

    local tbOptionAll = TeamBuilding.GetCheckedMenu("全部", true, false, { nil, "全部" }, nil, false)
    table.insert(tbMenu, tbOptionAll)

    local tbOptionCurrent = TeamBuilding.GetCheckedMenu("当前地图", true, false, { GetClientScene().dwMapID, "当前地图" }, nil, false)
    table.insert(tbMenu, tbOptionCurrent)

    -- 这个就是数据来源
    local tRegionList = self:GetRegionList()
    for _, tInfo in ipairs(tRegionList) do
        local tbActivityMenu = TeamBuilding.GetCheckedMenu(g2u(tInfo.szRegionName), true, false, { nil, g2u(tInfo.szRegionName) }, nil, false)
        table.insert(tbMenu, tbActivityMenu)

        local tMapList = AchievementData.m_tMapRegion[tInfo.dwRegionID]
        if tMapList then
            if table.get_len(tMapList.tRaid) > 0 then
                local tbRaidMenu = TeamBuilding.GetCheckedMenu("团队秘境", true, false, { nil, "团队秘境" }, nil, false)
                table.insert(tbActivityMenu, tbRaidMenu)

                for _, dwMapID in ipairs(tMapList.tRaid) do
                    local tNameList = Table_GetMiddleMap(dwMapID)
                    for nIndex, szMiddleMap in ipairs(tNameList) do
                        if szMiddleMap ~= "" then
                            local tbSubMenu = TeamBuilding.GetCheckedMenu(g2u(szMiddleMap), true, false, { dwMapID, g2u(szMiddleMap) }, nil, false)
                            table.insert(tbRaidMenu, tbSubMenu)
                        end
                    end
                end
            end

            if table.get_len(tMapList.tDungeon) > 0 then
                local tbDungeonMenu = TeamBuilding.GetCheckedMenu("五人秘境", true, false, { nil, "五人秘境" }, nil, false)
                table.insert(tbActivityMenu, tbDungeonMenu)

                for _, dwMapID in ipairs(tMapList.tDungeon) do
                    local tNameList = Table_GetMiddleMap(dwMapID)
                    for nIndex, szMiddleMap in ipairs(tNameList) do
                        if szMiddleMap ~= "" then
                            local tbSubMenu = TeamBuilding.GetCheckedMenu(g2u(szMiddleMap), true, false, { dwMapID, g2u(szMiddleMap) }, nil, false)
                            table.insert(tbDungeonMenu, tbSubMenu)
                        end
                    end
                end
            end

            for _, dwMapID in ipairs(tMapList) do
                local tNameList = Table_GetMiddleMap(dwMapID)
                for nIndex, szMiddleMap in ipairs(tNameList) do
                    if szMiddleMap ~= "" then
                        local tbSubMenu = TeamBuilding.GetCheckedMenu(g2u(szMiddleMap), true, false, { dwMapID, g2u(szMiddleMap) }, nil, false)
                        table.insert(tbActivityMenu, tbSubMenu)
                    end
                end
            end
        end
    end

    return tbMenu
end

function UIAchievementMapScreen:GetRegionList()
    ---@type RegionMapInfo[]
    local tRegionList = clone(AchievementData.m_tRegionList)

    ---@param tInfoLeft RegionMapInfo
    ---@param tInfoRight RegionMapInfo
    local fnSort      = function(tInfoLeft, tInfoRight)
        --- 实际有子地图的区域放到前面
        local bHasSubMapLeft  = AchievementData.m_tMapRegion[tInfoLeft.dwRegionID] ~= nil
        local bHasSubMapRight = AchievementData.m_tMapRegion[tInfoRight.dwRegionID] ~= nil
        if bHasSubMapLeft ~= bHasSubMapRight then
            return bHasSubMapLeft
        end

        return tInfoLeft.dwRegionID < tInfoRight.dwRegionID
    end

    table.sort(tRegionList, fnSort)

    return tRegionList
end

function UIAchievementMapScreen:InitFilterBySearchKeyWord()
    UIHelper.SetString(self.EditSearchMap, "")

    self:UpdateFilterBySearchKeyWordInfo()
end

function UIAchievementMapScreen:UpdateFilterBySearchKeyWordInfo()
    local szKeyWord         = UIHelper.GetString(self.EditSearchMap)

    local tSearchResultList = {}

    local fnAddMatchResult  = function(dwMapID, szMapName)
        local bMatch = false

        if szKeyWord ~= "" then
            if szMapName ~= "" and string.find(szMapName, szKeyWord) then
                bMatch = true
            end
        else
            -- 没有输入关键词时，显示当前地图
            bMatch = dwMapID == GetClientScene().dwMapID
        end
        
        if bMatch then
            table.insert(tSearchResultList, { dwMapID, szMapName })
        end
    end

    local g2u               = UIHelper.GBKToUTF8

    local tRegionList       = self:GetRegionList()
    for _, tInfo in ipairs(tRegionList) do
        local tMapList = AchievementData.m_tMapRegion[tInfo.dwRegionID]
        if tMapList then
            if table.get_len(tMapList.tRaid) > 0 then
                for _, dwMapID in ipairs(tMapList.tRaid) do
                    local tNameList = Table_GetMiddleMap(dwMapID)
                    for nIndex, szMiddleMap in ipairs(tNameList) do
                        fnAddMatchResult(dwMapID, g2u(szMiddleMap))
                    end
                end
            end

            if table.get_len(tMapList.tDungeon) > 0 then
                for _, dwMapID in ipairs(tMapList.tDungeon) do
                    local tNameList = Table_GetMiddleMap(dwMapID)
                    for nIndex, szMiddleMap in ipairs(tNameList) do
                        fnAddMatchResult(dwMapID, g2u(szMiddleMap))
                    end
                end
            end

            for _, dwMapID in ipairs(tMapList) do
                local tNameList = Table_GetMiddleMap(dwMapID)
                for nIndex, szMiddleMap in ipairs(tNameList) do
                    fnAddMatchResult(dwMapID, g2u(szMiddleMap))
                end
            end
        end
    end

    local bHasResult = #tSearchResultList > 0
    UIHelper.SetVisible(self.WidgetEmptySearchMap, not bHasResult)
    UIHelper.SetVisible(self.ScrollViewSearchMap, bHasResult)
    if bHasResult then
        UIHelper.RemoveAllChildren(self.ScrollViewSearchMap)

        for _, tResult in ipairs(tSearchResultList) do
            local dwMapID, szMapName = table.unpack(tResult)

            local tbSubMenu          = TeamBuilding.GetCheckedMenu(szMapName, true, false, { dwMapID, szMapName }, nil, false)

            ---@type UITeamRecruitFilterItem
            local filterCell         = UIHelper.AddPrefab(PREFAB_ID.WidgetFilterItemCell, self.ScrollViewSearchMap)
            filterCell:OnEnter(tbSubMenu, function(tbMenu)
                self:CheckedCallback(tbMenu)
            end)
        end

        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSearchMap)
    end
end

return UIAchievementMapScreen