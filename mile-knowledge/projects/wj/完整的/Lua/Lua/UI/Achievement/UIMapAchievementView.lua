-- ---------------------------------------------------------------------------------
-- Name: UIMapAchievementView
-- Desc: 地图成就
-- Prefab: PanelMapAchievement D:\Code\sword3-products\trunk\client\mui\Lua\UI\Achievement\UIMapAchievementView.lua
-- ---------------------------------------------------------------------------------

local UIMapAchievementView = class("UIMapAchievementView")


function UIMapAchievementView:_LuaBindList()
    self.BtnClose                  = self.BtnClose --- 关闭界面

    self.WidgetContent             = self.WidgetContent
    self.WidgetEmpty               = self.WidgetEmpty

    self.LabelMapName              = self.LabelMapName --- 地图名称
    self.LabelAchievementProgress  = self.LabelAchievementProgress --- 成就进度
    self.LabelZiliProgress         = self.LabelZiliProgress --- 资历进度

    self.WidgetClickBtn            = self.WidgetClickBtn -- 加载弹出框

    self.ScrollViewCell            = self.ScrollViewCell
    self.ToggleGroupTab            = self.ToggleGroupTab
end

function UIMapAchievementView:OnEnter()
    --AchievementData.ResetSearchAndFilter()
    self.dwPlayerID = g_pClientPlayer.dwID
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIMapAchievementView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    self.tFinishAchievementIDList = nil
    self.tNotFinishAchievementIDList = nil
    self.nAllPoint = nil
    self.nAllFinishPoint = nil
end

function UIMapAchievementView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIMapAchievementView:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        UIHelper.SetVisible(self.scriptPop._rootNode, false)
        if self.scriptSelectedCell then
            UIHelper.SetSelected(self.scriptSelectedCell.TogMapAchievementCell, false)
        end
    end)

    Event.Reg(self, EventType.OnSceneTouchNothing, function()
        UIHelper.SetVisible(self.scriptPop._rootNode, false)
        if self.scriptSelectedCell then
            UIHelper.SetSelected(self.scriptSelectedCell.TogMapAchievementCell, false)
        end
    end)

    Event.Reg(self, EventType.OnSceneTouchTarget, function()
        UIHelper.SetVisible(self.scriptPop._rootNode, false)
        if self.scriptSelectedCell then
            UIHelper.SetSelected(self.scriptSelectedCell.TogMapAchievementCell, false)
        end
    end)
end

function UIMapAchievementView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------


--- 页面
function UIMapAchievementView:UpdateInfo()
    UIHelper.RemoveAllChildren(self.WidgetClickBtn)
    self.scriptPop = UIHelper.AddPrefab(PREFAB_ID.WidgetInteractionMorePop, self.WidgetClickBtn)
    UIHelper.SetVisible(self.scriptPop._rootNode, false)

    self.dwMapID = GetClientScene().dwMapID
    local szMapName = Table_GetMapName(self.dwMapID)
    UIHelper.SetString(self.LabelMapName, UIHelper.GBKToUTF8(szMapName))

    self:UpdateData(self.dwPlayerID)

    if #self.tFinishAchievementIDList ~= 0 or #self.tNotFinishAchievementIDList ~= 0 then
        UIHelper.SetVisible(self.WidgetEmpty, false)
        UIHelper.RemoveAllChildren(self.ScrollViewCell)

        if self.nMapAchievementID then
            Timer.DelTimer(self , self.nMapAchievementID)
        end

        local loadIndex = 0
        local loadPre   = #self.tNotFinishAchievementIDList
        local loadCount = loadPre + #self.tFinishAchievementIDList
        self.nMapAchievementID = Timer.AddFrameCycle(self, 1, function()
            for i = 1, 3, 1 do
                loadIndex = loadIndex + 1
                local dwAchievementID
                local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetMapAchievementCell, self.ScrollViewCell) assert(scriptCell)
                UIHelper.ToggleGroupAddToggle(self.ToggleGroupTab, scriptCell.TogMapAchievementCell)
                UIHelper.SetSelected(scriptCell.TogMapAchievementCell, false)
                if loadIndex > loadPre then
                    dwAchievementID = self.tFinishAchievementIDList[loadIndex - loadPre]
                    scriptCell:UpdateData(dwAchievementID, self.dwPlayerID, true)
                else
                    dwAchievementID = self.tNotFinishAchievementIDList[loadIndex]
                    scriptCell:UpdateData(dwAchievementID, self.dwPlayerID, false)
                end
                scriptCell:SetClickFunc(function()
                    self:OnTogClick(dwAchievementID)
                    self.scriptSelectedCell = scriptCell
                end)
                if loadIndex == loadCount then
                    Timer.DelTimer(self, self.nMapAchievementID)
                    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewCell, true, true)
                    UIHelper.ScrollViewDoLayout(self.ScrollViewCell)
                    UIHelper.ScrollToTop(self.ScrollViewCell, 0)
                    break
                end
            end
        end)
    else
        UIHelper.SetVisible(self.WidgetEmpty, true)
    end

    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewCell, true, true)
    UIHelper.ScrollViewDoLayout(self.ScrollViewCell)
    UIHelper.ScrollToTop(self.ScrollViewCell, 0)
end

--- 数据筛选
function UIMapAchievementView:UpdateData(dwPlayerID)
    AchievementData.EnsureTreeLoaded()

    local tGeneral, dwMapID
    
    tGeneral    = AchievementData.tTree[ACHIEVEMENT_PANEL_TYPE.ACHIEVEMENT]
    dwMapID     = self.dwMapID

    self.tFinishAchievementIDList = {}
    self.tNotFinishAchievementIDList = {}
    self.nAllPoint = 0
    self.nAllFinishPoint = 0
    for _, tCategory in ipairs(tGeneral) do
        for _, tSubCategory in ipairs(tCategory) do
            self:FliterOfMapAndStats(tSubCategory.szAchievements, dwMapID, dwPlayerID)
        end
    end

    local nFinishCount = #self.tFinishAchievementIDList
    local nAllCount = #self.tNotFinishAchievementIDList + nFinishCount

    UIHelper.SetString(self.LabelAchievementProgress, nFinishCount .. "/" .. nAllCount)
    UIHelper.SetString(self.LabelZiliProgress, self.nAllFinishPoint .. "/" .. self.nAllPoint)
end

function UIMapAchievementView:FliterOfMapAndStats(szAchievements, dwSceneID, dwPlayerID)
    for s in string.gmatch(szAchievements, "%d+") do
        local dwAchievement = tonumber(s) -- 系列成就ID，示例：成就128
        local aAchievement  = Table_GetAchievement(dwAchievement)

        local bInsert       = false
        local bFinish       = AchievementData.IsAchievementAcquired(dwAchievement, aAchievement, dwPlayerID)
        local nFinishPoint, nAllPoint = 0, 0 -- 资历点统计

        if aAchievement.szSeries == "" then
            if AchievementData.InScenes(aAchievement.szSceneID, dwSceneID) then
                bInsert = true
                local _, nPoint  = Table_GetAchievementInfo(dwAchievement)
                if bFinish then
                    nFinishPoint = nPoint
                end
                nAllPoint = nPoint
            end
        else
            if AchievementData.InScenes(aAchievement.szSceneID, dwSceneID) then
                bInsert = true
            else
                local szSeries      = aAchievement.szSeries
                for s1 in string.gmatch(szSeries, "%d+") do
                    local dwAchievement1 = tonumber(s1)
                    local tLine          = Table_GetAchievement(dwAchievement1)
                    if AchievementData.InScenes(tLine.szSceneID, dwSceneID) then
                        bInsert = true
                        break
                    end
                end
            end
            if bInsert then
                local bFind = false --是否找到第一个未完成的系列成就ID
                local szSeries      = aAchievement.szSeries
                local bSubFinish = false
                for s1 in string.gmatch(szSeries, "%d+") do
                    local dwAchievement1 = tonumber(s1)
                    local tLine          = Table_GetAchievement(dwAchievement1)
                    bSubFinish           = not bFind and AchievementData.IsAchievementAcquired(dwAchievement1, tLine, dwPlayerID, true)
                    local _, nPoint      = Table_GetAchievementInfo(dwAchievement1)
                    if bSubFinish then
                        nFinishPoint     = nFinishPoint + nPoint
                    else
                        if not bFind then
                            bFind = true
                        end
                    end
                    nAllPoint            = nAllPoint + nPoint
                end
            end
        end

        if bInsert then
            if bFinish then
                table.insert(self.tFinishAchievementIDList, dwAchievement)
            else
                table.insert(self.tNotFinishAchievementIDList, dwAchievement)
            end

            self.nAllFinishPoint = self.nAllFinishPoint + nFinishPoint
            self.nAllPoint = self.nAllPoint + nAllPoint
        end
    end
end

--- 弹出框功能
function UIMapAchievementView:OnTogClick(dwAchievementID)
    local aBaseAchievement = Table_GetAchievement(dwAchievementID)
    local tbBtnInfo = {
        {
            OnClick = function ()
                local szMoHeBaseUrl = "https://www.jx3box.com/cj/view/"
                if Platform.IsMobile() then
                    szMoHeBaseUrl = "https://www.jx3box.com/wujie/cj/view/"
                end
                local szUrl = szMoHeBaseUrl .. dwAchievementID
                UIHelper.OpenWeb(szUrl)
            end,
            szName = "成就攻略"
        },
        {
            OnClick = function ()
                if aBaseAchievement.szSeries ~= "" then
                    --一系列的成就
                    UIMgr.Open(VIEW_ID.PanelAchievementContentListPop, dwAchievementID, self.dwPlayerID)
                elseif aBaseAchievement.szSubAchievements ~= "" then
                    -- 普通成就
                    UIMgr.Open(VIEW_ID.PanelAchievementContentSchedulePop, dwAchievementID, self.dwPlayerID)
                else
                    UIMgr.Open(VIEW_ID.PanelAchievementContent, aBaseAchievement.dwGeneral, aBaseAchievement.dwSub, aBaseAchievement.dwDetail, dwAchievementID, self.dwPlayerID)
                end
            end,
            szName = "查看"
        },
        {
            OnClick = function ()
                ChatHelper.SendAchievementToChat(dwAchievementID)
            end,
            szName = "分享"
        },
    }

    local tGotoMapID = {}
    for s1 in string.gmatch(aBaseAchievement.szSceneID, "%d+") do
        local dwMapID = tonumber(s1)
        local _, nMapType = GetMapParams(dwMapID)
        local bGotoType = nMapType and (nMapType == MAP_TYPE.DUNGEON or nMapType == MAP_TYPE.NORMAL_MAP or nMapType == MAP_TYPE.TONG_DUNGEON)
        if bGotoType then
            table.insert(tGotoMapID, dwMapID)
        end
    end

    if #tGotoMapID > 0 then
        local fnGotoMap = function(dwMapID)
            local _, nMapType = GetMapParams(dwMapID)
            if nMapType == MAP_TYPE.DUNGEON then
                local tRecord = {
                    dwTargetMapID = dwMapID,
                }
                if not UIMgr.IsViewOpened(VIEW_ID.PanelDungeonEntrance, true) then
                    UIMgr.Open(VIEW_ID.PanelDungeonEntrance, tRecord)
                else
                    UIMgr.CloseWithCallBack(VIEW_ID.PanelDungeonEntrance, function ()
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
                    UIMgr.CloseWithCallBack(VIEW_ID.PanelWorldMap, function ()
                        local viewScript = UIMgr.Open(VIEW_ID.PanelWorldMap, tRecord)
                        viewScript:SetJumpToMiddle(true)
                        viewScript:TraceMap(dwMapID, true)
                    end)
                end
            end
        end

        local tGotoBtn = {}
        if #tGotoMapID > 1 then
            tGotoBtn =
            {
                bNesting = true,
                szName = "前往",
                tbSubMenus = {},
            }
            for _, dwMapID in ipairs(tGotoMapID) do
                local tSubBtn = {
                    szName = UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(Table_GetMapName(dwMapID)), 6),
                    OnClick = function ()
                        fnGotoMap(dwMapID)
                    end,
                }
                table.insert(tGotoBtn.tbSubMenus, tSubBtn)
            end
        else
            tGotoBtn =
            {
                OnClick = function ()
                    fnGotoMap(tGotoMapID[1])
                end,
                szName = "前往"
            }
        end
        table.insert(tbBtnInfo, 1, tGotoBtn)
    end

    UIHelper.SetVisible(self.scriptPop.ScrollviewMore, false)
    UIHelper.RemoveAllChildren(self.scriptPop.LayoutMore)
    self:CreateMenus(tbBtnInfo, self.scriptPop.LayoutMore)
    UIHelper.SetVisible(self.scriptPop._rootNode, true)
end

function UIMapAchievementView:CreateMenus(tbShowMenuConfig, layoutParent)

    for _, tbMenuConfig in ipairs(tbShowMenuConfig) do
        if not tbMenuConfig.bNesting then
            local btnScript = UIHelper.AddPrefab(PREFAB_ID.WidgetInteractionMoreBtn, layoutParent)

            UIHelper.SetString(btnScript.LableMpore, tbMenuConfig.szName)
            UIHelper.SetTouchDownHideTips(btnScript.Btn, false)

            UIHelper.BindUIEvent(btnScript.Btn, EventType.OnClick, function()
                if IsFunction(tbMenuConfig.OnClick) then
                    tbMenuConfig.OnClick()
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetInteractionMorePop)
                end
            end)
        else
            local toggleScript = UIHelper.AddPrefab(PREFAB_ID.WidgetInteractionMoreTog, layoutParent)

            UIHelper.SetString(toggleScript.LableMpore, tbMenuConfig.szName)
            UIHelper.SetSelected(toggleScript.Toggle, false)
            toggleScript.Toggle:setTouchDownHideTips(false)

            UIHelper.BindUIEvent(toggleScript.Toggle, EventType.OnSelectChanged, function(_, bSelected)
                if bSelected then

                    local fnOnMorePopClose = function()
                        UIHelper.SetSelected(toggleScript.Toggle, false)
                    end

                    local parent = toggleScript._rootNode
                    local _, tipsScriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetInteractionMorePop, parent, TipsLayoutDir.BOTTOM_LEFT, fnOnMorePopClose)

                    -- 添加按钮
                    UIHelper.SetVisible(tipsScriptView.ScrollviewMore, #tbMenuConfig.tbSubMenus >= 6)
                    UIHelper.SetVisible(tipsScriptView.LayoutMore, #tbMenuConfig.tbSubMenus < 6)
                    if #tbMenuConfig.tbSubMenus >= 6 then
                        self:CreateMenus(tbMenuConfig.tbSubMenus, tipsScriptView.ScrollviewMore)
                        UIHelper.AddPrefab(PREFAB_ID.WidgetArrow, tipsScriptView.WidgetArrow)
                        
                        local nWidgetHeight = UIHelper.GetHeight(tipsScriptView.ScrollviewMore)
                        UIHelper.SetHeight(tipsScriptView.ImgPopBg, nWidgetHeight)
                        UIHelper.ScrollViewDoLayoutAndToTop(tipsScriptView.ScrollviewMore)
                        UIHelper.SetTouchDownHideTips(tipsScriptView.ScrollviewMore, false)
                    else
                        self:CreateMenus(tbMenuConfig.tbSubMenus, tipsScriptView.LayoutMore)
                        UIHelper.LayoutDoLayout(tipsScriptView.LayoutMore)
                    end
                end
            end)
        end
    end

    UIHelper.LayoutDoLayout(layoutParent)
end

return UIMapAchievementView