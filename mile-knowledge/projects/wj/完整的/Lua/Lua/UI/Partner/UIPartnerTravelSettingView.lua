-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerTravelSettingView
-- Date: 2024-11-21 17:42:31
-- Desc: 侠客委托配置界面
-- Prefab: PanelPartnerTravelSetting
-- ---------------------------------------------------------------------------------

--- 宠物奇遇的类别ID
local ClassID_PetQiYu            = 1
--- 五人秘境
local ClassID_WuRenMiJing        = 5
--- 团队秘境
local ClassID_TuanDuiMiJing      = 6

---@class UIPartnerTravelSettingView
local UIPartnerTravelSettingView = class("UIPartnerTravelSettingView")

---@class BtnPartnerTravelTargetCell 下方的侠客头像组件
---@field ImgAdd table 未配置时的加号头像
---@field MaskIcon table 配置时的头像的上层组件
---@field ImgFrameIcon table 配置时的头像

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerTravelSettingView:_LuaBindList()
    self.BtnClose                        = self.BtnClose --- 关闭按钮
    self.LabelQuestTypeName              = self.LabelQuestTypeName --- 事件类别名称
    self.LabelSelectedQuestName          = self.LabelSelectedQuestName --- 当前选择的事件名称
    self.ScrollViewLeftListMore          = self.ScrollViewLeftListMore --- 事件的scroll view

    self.BtnStartTravel                  = self.BtnStartTravel --- 开始出行按钮

    self.LayoutCurrencyCost              = self.LayoutCurrencyCost --- 消耗的layout
    self.LayoutCurrencyCostList          = self.LayoutCurrencyCostList --- 消耗区域上方的layout

    self.WidgetTopContainer              = self.WidgetTopContainer --- 左侧事件吸顶的容器

    self.BtnGo                           = self.BtnGo --- 前往未解锁的成就或任务界面
    self.LabelGo                         = self.LabelGo --- 前往未解锁的成就或任务界面的label

    self.LabelQuestTypeLimit             = self.LabelQuestTypeLimit --- 事件类别次数信息

    self.WidgetBtnFilter                 = self.WidgetBtnFilter --- 右上角的筛选按钮的挂载点
    self.BtnFilter                       = self.BtnFilter --- 右上角的筛选按钮
    self.ImgBgTitleLine                  = self.ImgBgTitleLine --- 右上角X左边的竖线

    self.LayoutCurrency                  = self.LayoutCurrency --- 拥有的货币的layout

    self.LabelAllTime                    = self.LabelAllTime --- 最终耗时

    self.LabelHintMultipleCost           = self.LabelHintMultipleCost --- 达到指定次数时翻倍的提示文本

    self.WidgetImgInfo                   = self.WidgetImgInfo --- 右侧图片区域（类别、奇遇、秘境难度）
    self.WIdgetDifficultyTog             = self.WIdgetDifficultyTog --- 秘境难度父节点
    self.LabelHintLock                   = self.LabelHintLock --- 未解锁时的提示

    self.BtnAchievement                  = self.BtnAchievement --- 成就奖励按钮
    self.LabelAchievements               = self.LabelAchievements --- 成就奖励按钮

    self.ScrollViewReward                = self.ScrollViewReward --- 奖励的scroll view

    self.LayoutPartner                   = self.LayoutPartner --- 下方侠客头像的最上层layout

    --- 侠客头像组件列表
    ---@type BtnPartnerTravelTargetCell[]
    self.tBtnPartnerTravelTargetCellList = self.tBtnPartnerTravelTargetCellList

    self.WidgetAnchorLeftPop             = self.WidgetAnchorLeftPop --- 左侧侧面板的挂载点

    self.ImgDIfficultyIcon               = self.ImgDIfficultyIcon --- 当前秘境难度 的图片
    self.ImgDIfficultyIconBg             = self.ImgDIfficultyIconBg --- 当前秘境难度 的图片的背景

    self.WidgetBanner                    = self.WidgetBanner --- 单个奇遇的组件
    self.PageViewBanner                  = self.PageViewBanner --- 奇遇的上层组件

    self.LayoutBannerPage                = self.LayoutBannerPage --- 奇遇轮播页的toggle的layout
    self.tPageTogPoints                  = self.tPageTogPoints --- 奇遇轮播页的toggle列表

    self.LayoutDifficultyHead            = self.LayoutDifficultyHead --- 难度信息的layout
    self.tDifficultyWidgetList           = self.tDifficultyWidgetList --- 难度信息的组件列表

    self.ImgMode                         = self.ImgMode --- 类别 的图片
    self.ImgModeBg                       = self.ImgModeBg --- 类别 的图片背景
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIPartnerTravelSettingView:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIPartnerTravelSettingView:OnEnter(nCurrentBoard, nQuestIndex, nClass)
    --- 第几个牌子
    self.nCurrentBoard                                  = nCurrentBoard
    --- 第几个出行位置
    self.nQuestIndex                                    = nQuestIndex
    --- 任务类型信息
    self.nClass                                         = nClass

    --- 当前选择的出行事件ID
    self.nQuestID                                       = nil

    --- 当前选中的侠客ID列表
    --- @type number[]
    self.tSelectedPartnerIDList                         = {}

    self.nPageIndex                                     = 0

    --- 在选择事件后，首次打开侧面板时需要默认选中所需的侠客数目
    self.bNeedSelectFirstNPartnerWhenFirstOpenLeftPanel = true

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()

        FilterDef.TravelPartner.Reset()

        self.bInit = true
    end

    Timer.AddFrameCycle(self, 1, function()
        self:OnScrollViewTaskTouchMoved()
        self:CheckPageView()
    end)

    local tPetTryList = self:GetPetTryList()
    if table.get_len(tPetTryList) == 0 then
        self:UpdateInfo()
    else
        -- 成就按钮先默认隐藏，在选中事件时若有成就再显示
        UIHelper.SetVisible(self.BtnAchievement, false)
        
        --- 宠物奇遇需要先去请求下次数信息再展示
        PartnerData.InitLuckyTable(true)
        RemoteCallToServer("On_QiYu_PetTryList", tPetTryList)
    end
end

function UIPartnerTravelSettingView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPartnerTravelSettingView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnStartTravel, EventType.OnClick, function()
        self:StartTravel()
    end)

    UIHelper.BindUIEvent(self.BtnFilter, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnFilter, TipsLayoutDir.TOP_LEFT, FilterDef.TravelPartner)
    end)

    UIHelper.BindUIEvent(self.BtnAchievement, EventType.OnClick, function()
        self:ShowAchievementReward()
    end)

    for idx, btn in ipairs(self.tBtnPartnerTravelTargetCellList) do
        UIHelper.BindUIEvent(btn, EventType.OnClick, function()
            self:OpenPartnerListLeftPanel()
        end)
    end

    for nIdx, pageToggle in ipairs(self.tPageTogPoints) do
        UIHelper.SetToggleGroupIndex(pageToggle, ToggleGroupIndex.PartnerTravelTryAdventure)
    end
end

function UIPartnerTravelSettingView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnGetAdventurePetTryBook, function(tPetTryMap)
        for nAdvID, nTryTime in pairs(tPetTryMap) do
            PartnerData.UpdatePetTryTime(nAdvID, nTryTime)
        end

        self:UpdateInfo()
    end)

    Event.Reg(self, "PartnerTravelSetting_UpdateSelectedPartnerIDList", function(tSelectedPartnerIDList)
        self.tSelectedPartnerIDList = tSelectedPartnerIDList

        self:UpdateSelectedPartnerListInfo()
    end)

    UIHelper.BindUIEvent(self.PageViewBanner, EventType.OnTurningPageView, function()
        self.nPageIndex = UIHelper.GetPageIndex(self.PageViewBanner)

        self:AutoFixPageView(self.nPageIndex + 1)
        Timer.DelTimer(self, self.nAutoPageTimer)
        self.nAutoPageTimer = nil
    end)

    for nIndex, toggle in ipairs(self.tPageTogPoints) do
        UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function(_, bSelected)
            if bSelected then
                UIHelper.ScrollToPage(self.PageViewBanner, nIndex - 1, 0.25)
            end
        end)
    end

    Event.Reg(self, EventType.OnRichTextOpenUrl, function(szUrl, node)
        if string.is_nil(szUrl) then
            return
        end

        szUrl                        = UrlDecode(szUrl)

        local szLinkEvent, szLinkArg = szUrl:match("(%w+)/(.*)")
        
        if szLinkEvent == "Achievement" then
            -- Achievement/120
            local dwAchievementID      = tonumber(szLinkArg)

            local aAchievement = Table_GetAchievement(dwAchievementID)

            UIMgr.Open(VIEW_ID.PanelAchievementContent, aAchievement.dwGeneral, aAchievement.dwSub, aAchievement.dwDetail, aAchievement.dwID)
        else
            LOG.ERROR("UIPartnerTravelSettingView 尚未支持的链接: %s", szUrl)
        end
    end)
end

function UIPartnerTravelSettingView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerTravelSettingView:UpdateInfo()
    local tInfo       = Table_GetPartnerTravelClass(self.nClass)

    local szTypeName  = UIHelper.GBKToUTF8(tInfo.szClassName)

    local szCountInfo = PartnerData.GetTravelCountInfo(tInfo.nDataIndex)

    UIHelper.SetString(self.LabelQuestTypeName, szTypeName)
    UIHelper.SetString(self.LabelQuestTypeLimit, szCountInfo)

    UIHelper.SetString(self.LabelSelectedQuestName, "暂未选择")
    UIHelper.SetString(self.LabelAllTime, "")

    local bIsMiJing = self:IsMiJingClass(self.nClass)
    UIHelper.SetVisible(self.WIdgetDifficultyTog, bIsMiJing)

    if not bIsMiJing then
        self:UpdateQuestListInfo()
    else
        self:UpdateMijingListInfo()
    end
end

function UIPartnerTravelSettingView:UpdateQuestListInfo()
    ---@type table<number, UIPartnerTravelSettingListTitle>
    self.tSubToScript     = {}
    ---@type table<number, UIPartnerTravelSettingListTask>
    self.tQuestIdToScript = {}

    UIHelper.RemoveAllChildren(self.ScrollViewLeftListMore)

    local tSubToInfo = Table_GetPartnerTravelClassToSubToInfo()[self.nClass]

    local tSubIdList = {}
    for nSub, _ in pairs(tSubToInfo) do
        table.insert(tSubIdList, nSub)
    end
    table.sort(tSubIdList)

    local nDefaultSelectQuestId = nil
    if self.nClass ~= ClassID_PetQiYu then
        nDefaultSelectQuestId = PartnerData.tTravelClassToLastChooseQuestId[self.nClass]
    end

    local nDefaultSelectScrollViewIndex = 0

    local bHasMultipleSubClass          = table.get_len(tSubIdList) > 1

    UIHelper.SetVisible(self.WidgetTopContainer, bHasMultipleSubClass)
    ---@type UIPartnerTravelSettingListTitle
    self.ScriptAutoToping = UIHelper.AddPrefab(PREFAB_ID.WidgetPartnerTravelSettingListTitle, self.WidgetTopContainer)
    UIHelper.ScrollViewDoLayoutAndToTop(self.WidgetTopContainer)

    for _, nSub in ipairs(tSubIdList) do
        local tSubInfo = tSubToInfo[nSub]

        local bShow    = true
        if bHasMultipleSubClass and tSubInfo.nSub == 0 then
            --- 有多个子类别时，0代表大类的信息，不展示
            bShow = false
        end

        if bShow then
            if bHasMultipleSubClass then
                -- 有多个子类时，需要展示子类的标题信息
                local szName                     = UIHelper.GBKToUTF8(tSubInfo.szSubName)
                local szCountInfo                = PartnerData.GetTravelCountInfo(tSubInfo.nDataIndex)

                local szShowInfo                 = string.format("%s %s", szName, szCountInfo)

                ---@type UIPartnerTravelSettingListTitle
                local scriptTitle                = UIHelper.AddPrefab(PREFAB_ID.WidgetPartnerTravelSettingListTitle, self.ScrollViewLeftListMore, szShowInfo)
                self.tSubToScript[tSubInfo.nSub] = scriptTitle

                UIHelper.BindUIEvent(scriptTitle.ToggleTitle, EventType.OnSelectChanged, function(_, bSelected)
                    self:OnSelectSubTitle(tSubInfo.nSub, bSelected)
                end)
            end

            local tQuestList = Table_GetPartnerTravelTaskClassToSubToInfoList()[tSubInfo.nClass][tSubInfo.nSub]

            ---@param tQuestLeft PartnerTravelTask
            ---@param tQuestRight PartnerTravelTask
            local function fnSort(tQuestLeft, tQuestRight)
                ---@param tQuest PartnerTravelTask
                local fnGetOrder  = function(tQuest)
                    -- 已解锁，有福缘，未尝试
                    -- 已解锁，未尝试
                    -- 未解锁，有福缘
                    -- 未解锁
                    -- 已尝试
                    -- 已触发
                    local nOrderUnlocked_FuYuan_HasTryCount = 1
                    local nOrderUnlocked_HasTryCount        = 2
                    local nOrderLocked_FuYuan               = 3
                    local nOrderLocked                      = 4
                    local nOrderUnlocked_HasNoTryCount      = 5
                    local nOrderUnlocked_Triggered          = 6

                    local bLocked                           = PartnerData.IsTravelQuestLocked(tQuest)

                    local bHasFuYuan                        = false
                    if tQuest.dwAdventureID ~= 0 then
                        bHasFuYuan = PartnerData.GetAdvantureInfo(tQuest.dwAdventureID)
                    end

                    if not bLocked then
                        local bHasTrigger = PartnerData.IsTravelQuestTriggered(tQuest)
                        if bHasTrigger then
                            --- 已触发
                            return nOrderUnlocked_Triggered
                        end

                        if tQuest.dwAdventureID ~= 0 then
                            local tTryInfo = PartnerData.tPetAdvIdToTryInfo[tQuest.dwAdventureID]
                            if tTryInfo then
                                local bTryMax = tTryInfo.nHasTry >= tTryInfo.nTryMax
                                if bTryMax then
                                    -- 已尝试
                                    return nOrderUnlocked_HasNoTryCount
                                end
                            end
                        end

                        if bHasFuYuan then
                            --- 已解锁，有福缘，未尝试
                            return nOrderUnlocked_FuYuan_HasTryCount
                        else
                            --- 已解锁，未尝试
                            return nOrderUnlocked_HasTryCount
                        end
                    else
                        if bHasFuYuan then
                            --- 已解锁，有福缘，未尝试
                            return nOrderLocked_FuYuan
                        else
                            --- 已解锁，未尝试
                            return nOrderLocked
                        end
                    end
                end

                local nOrderLeft  = fnGetOrder(tQuestLeft)
                local nOrderRight = fnGetOrder(tQuestRight)
                if nOrderLeft ~= nOrderRight then
                    return nOrderLeft < nOrderRight
                end

                return tQuestLeft.dwID < tQuestRight.dwID
            end

            table.sort(tQuestList, fnSort)

            for nIndex, tQuest in ipairs(tQuestList) do
                ---@type UIPartnerTravelSettingListTask
                local script                       = UIHelper.AddPrefab(PREFAB_ID.WidgetPartnerTravelSettingListTask, self.ScrollViewLeftListMore, tQuest)
                self.tQuestIdToScript[tQuest.dwID] = script

                UIHelper.SetToggleGroupIndex(script.ToggleTask, ToggleGroupIndex.PartnerTravelTask)

                UIHelper.BindUIEvent(script.ToggleTask, EventType.OnClick, function()
                    self:SelectQuest(tQuest.dwID)
                end)

                if not nDefaultSelectQuestId then
                    nDefaultSelectQuestId = tQuest.dwID
                end

                if tQuest.dwID == nDefaultSelectQuestId then
                    nDefaultSelectScrollViewIndex = UIHelper.GetChildrenCount(self.ScrollViewLeftListMore) - 1
                end
            end
        end
    end

    if nDefaultSelectQuestId then
        local questScript = self.tQuestIdToScript[nDefaultSelectQuestId]
        UIHelper.SetSelected(questScript.ToggleTask, true, false)

        self:SelectQuest(nDefaultSelectQuestId)

        local tQuest      = Table_GetPartnerTravelTask(nDefaultSelectQuestId)
        local scriptTitle = self.tSubToScript[tQuest.nSub]
        if scriptTitle then
            UIHelper.SetSelected(scriptTitle.ToggleTitle, true, false)

            self:OnSelectSubTitle(tQuest.nSub, true)
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewLeftListMore)

    Timer.AddFrame(self, 1, function()
        UIHelper.ScrollToIndex(self.ScrollViewLeftListMore, nDefaultSelectScrollViewIndex)
    end)
end

function UIPartnerTravelSettingView:UpdateMijingListInfo()
    local tDungeon, tOrderNames      = self:GetVersionName2DungeonList()

    --- 副本名称 => 不同难度的该副本信息列表
    ---@type table<string, DungeonRecord[]>
    self.tMapNameToDungeonRecordList = {}
    --- 版本名称 => 大标题的脚本
    ---@type table<string, UIPartnerTravelSettingListTitle>
    self.tVersionNameToTitleScript   = {}
    --- 副本名称 => 小标题的脚本
    ---@type table<string, UIPartnerTravelSettingListTask>
    self.tDungeonNameToTaskScript    = {}

    UIHelper.RemoveAllChildren(self.ScrollViewLeftListMore)

    --- 默认选中的副本信息
    ---@type DungeonRecord
    local tDefaultSelectDungeonRecord = nil
    --- 如果上次选择过一个秘境出行事件，则本次打开时默认选中该事件对应的副本条目（对应小标题和难度）
    if PartnerData.tTravelClassToLastChooseQuestId[self.nClass] then
        local nDefaultSelectQuestId = PartnerData.tTravelClassToLastChooseQuestId[self.nClass]
        local tQuest                = Table_GetPartnerTravelTask(nDefaultSelectQuestId)

        for _, szVersionName in ipairs(tOrderNames) do
            local tClass  = tDungeon[szVersionName]
            local tRecord = tClass.dwMapIDMap[tQuest.dwMapID]
            if tRecord then
                tDefaultSelectDungeonRecord = tRecord
            end
        end
    end

    local nDefaultSelectScrollViewIndex = 0

    UIHelper.SetVisible(self.WidgetTopContainer, true)
    ---@type UIPartnerTravelSettingListTitle
    self.ScriptAutoToping = UIHelper.AddPrefab(PREFAB_ID.WidgetPartnerTravelSettingListTitle, self.WidgetTopContainer)
    UIHelper.ScrollViewDoLayoutAndToTop(self.WidgetTopContainer)

    -- tOrderNames 最上层的版本名称列表，如推荐、丝路风雨、横刀断浪
    for idx = #tOrderNames, 1, -1 do
        local szVersionName                           = tOrderNames[idx]
        -- tClass 版本下面的具体副本信息
        local tClass                                  = tDungeon[szVersionName]
        local szTitle                                 = UIHelper.GBKToUTF8(szVersionName)

        -- re: 版本的标题信息
        ---@type UIPartnerTravelSettingListTitle
        local scriptTitle                             = UIHelper.AddPrefab(PREFAB_ID.WidgetPartnerTravelSettingListTitle, self.ScrollViewLeftListMore, szTitle)
        self.tVersionNameToTitleScript[szVersionName] = scriptTitle

        UIHelper.BindUIEvent(scriptTitle.ToggleTitle, EventType.OnSelectChanged, function(_, bSelected)
            self:OnSelectDungeonVersionName(szVersionName, bSelected)
        end)

        if scriptTitle then
            -- 构建 副本名 => 不同难度的该副本的信息的列表
            -- tClass.tRecordList 版本下面的地图信息列表，同一个副本的不同难度区分为不同的条目，如推荐下面的不染窟（包含多个难度）
            for nRecordID = 1, #tClass.tRecordList do
                -- tRecord.szVersionName 版本标题名字（最上层的折叠，如 推荐、丝路风雨）
                -- tRecord.szName 地图名字（左侧展开的内容，如 不染窟 、一之窟）
                -- tRecord.szLayer3Name 难度名称（最右侧的选项，如 5人英雄、10人普通）
                -- tRecord.dwMapID 副本ID 应该可以用这个跟秘境出行事件关联
                local tRecord = tClass.tRecordList[nRecordID]
                if not self.tMapNameToDungeonRecordList[tRecord.szName] then
                    self.tMapNameToDungeonRecordList[tRecord.szName] = {}
                end
                -- 这里把同一个地图的不同难度的条目放到同一个列表中，方便展示
                local tRecordMap = self.tMapNameToDungeonRecordList[tRecord.szName]
                if not table.contain_value(tRecordMap, tRecord) then
                    table.insert(tRecordMap, tRecord)
                end
            end

            local tCheckMap = {}
            -- tClass.tHeadInfoList 这个版本下的副本大类列表，按顺序暗示，包含每个副本中默认选中的难度信息
            for nRecordID = 1, #tClass.tHeadInfoList do
                local tRecord = tClass.tHeadInfoList[nRecordID]

                -- 理论上来说headinfo中不会重复出现同一个副本的不同难度，不过为了保险起见，这里检查下
                if not tCheckMap[tRecord.szName] then
                    tCheckMap[tRecord.szName]                     = true

                    -- re: 副本小标题
                    ---@type UIPartnerTravelSettingListTask
                    local scriptTask                              = UIHelper.AddPrefab(PREFAB_ID.WidgetPartnerTravelSettingListTask, self.ScrollViewLeftListMore, nil, true, tRecord)
                    self.tDungeonNameToTaskScript[tRecord.szName] = scriptTask

                    UIHelper.SetToggleGroupIndex(scriptTask.ToggleTask, ToggleGroupIndex.PartnerTravelTask)

                    UIHelper.BindUIEvent(scriptTask.ToggleTask, EventType.OnClick, function()
                        self:SelectDungeon(tRecord)
                    end)

                    if not tDefaultSelectDungeonRecord then
                        tDefaultSelectDungeonRecord = tRecord
                    end

                    if tRecord.szName == tDefaultSelectDungeonRecord.szName then
                        nDefaultSelectScrollViewIndex = UIHelper.GetChildrenCount(self.ScrollViewLeftListMore) - 1
                    end
                end
            end
        end
    end

    if tDefaultSelectDungeonRecord then
        local scriptName = self.tDungeonNameToTaskScript[tDefaultSelectDungeonRecord.szName]
        UIHelper.SetSelected(scriptName.ToggleTask, true, false)

        self:SelectDungeon(tDefaultSelectDungeonRecord)

        local scriptVersionName = self.tVersionNameToTitleScript[tDefaultSelectDungeonRecord.szVersionName]
        if scriptVersionName then
            UIHelper.SetSelected(scriptVersionName.ToggleTitle, true, false)

            self:OnSelectDungeonVersionName(tDefaultSelectDungeonRecord.szVersionName, true)
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewLeftListMore)
    UIHelper.ScrollToTop(self.ScrollViewLeftListMore, 0)

    Timer.AddFrame(self, 1, function()
        UIHelper.ScrollToIndex(self.ScrollViewLeftListMore, nDefaultSelectScrollViewIndex)
    end)
end

---@param tRecord DungeonRecord
function UIPartnerTravelSettingView:SelectDungeon(tRecord)
    local tDifficultyRecordList = self.tMapNameToDungeonRecordList[tRecord.szName]

    local funcComp              = function(tData1, tData2)
        if not tData1 or not tData2 then
            return false
        end
        return tData1.dwMapID < tData2.dwMapID
    end
    table.sort(tDifficultyRecordList, funcComp)

    local nTotalCount = table.get_len(tDifficultyRecordList)

    for nIdx, tDifficultWidget in ipairs(self.tDifficultyWidgetList) do
        local script = UIHelper.GetBindScript(tDifficultWidget)

        UIHelper.SetVisible(tDifficultWidget, nIdx <= nTotalCount)

        if nIdx <= nTotalCount then
            local tDifficultyRecord = tDifficultyRecordList[nIdx]

            local szDifficulty      = UIHelper.GBKToUTF8(tDifficultyRecord.szLayer3Name)

            local tQuest            = self:GetQuestByDungeonID(tDifficultyRecord.dwMapID)
            local bLocked           = PartnerData.IsTravelQuestLocked(tQuest)

            UIHelper.SetString(script.LabelNormal, szDifficulty)
            UIHelper.SetString(script.LabelUp, szDifficulty)

            UIHelper.SetVisible(script.ImgBgLock, bLocked)

            UIHelper.BindUIEvent(script.ToggleSelect, EventType.OnSelectChanged, function()
                self.tRecord = tDifficultyRecord

                self:SelectQuest(tQuest.dwID)
            end)

            if tDifficultyRecord.dwMapID == tRecord.dwMapID then
                UIHelper.SetSelected(script.ToggleSelect, true, true)
            end
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutDifficultyHead)
end

function UIPartnerTravelSettingView:GetQuestByDungeonID(dwMapID)
    local tSubToInfoList = Table_GetPartnerTravelTaskClassToSubToInfoList()[self.nClass]
    for _, tInfoList in pairs(tSubToInfoList) do
        for _, tInfo in ipairs(tInfoList) do
            if tInfo.dwMapID == dwMapID then
                return tInfo
            end
        end
    end

    return nil
end

---@class DungeonRecord 副本信息
---@field szVersionName string 版本名称，如 丝路风雨
---@field szName string 副本名称
---@field szLayer3Name string 难度名称，如 5人英雄、10人普通
---@field dwMapID number 副本地图ID
---
---@field dwClassID number _
---@field nEnterMapID number _
---@field szIntroduction string _
---@field bIsPast boolean _
---@field bRushmode boolean _
---@field nFitMinLevel number _
---@field nFitMaxLevel number _
---@field bIsRecommend boolean _
---@field bHideDetail boolean _
---@field szReward string _
---@field szExtReward string _
---@field dwQuestID number _

---@class VersionDungeonInfo 某个资料片版本的副本信息
---@field dwMapIDMap table<number, DungeonRecord> 副本地图ID => 副本信息
---@field tRecordList DungeonRecord[] 副本信息列表
---@field tHeadInfoList DungeonRecord[] 该版本各副本的代表难度副本信息列表（每个副本取最早配置的那个难度作为代表）
---@field tHeadInfoMap table<string, DungeonRecord> 代表难度的副本名称 => 副本信息

---@return table<string, VersionDungeonInfo>, string[]
function UIPartnerTravelSettingView:GetVersionName2DungeonList()
    --- 本秘境出行事件大类的副本ID集合
    local tMapIdSet      = {}
    local tSubToInfoList = Table_GetPartnerTravelTaskClassToSubToInfoList()[self.nClass]
    for _, tInfoList in pairs(tSubToInfoList) do
        for _, tInfo in ipairs(tInfoList) do
            tMapIdSet[tInfo.dwMapID] = true
        end
    end

    --- 构造当前秘境出行事件大类的副本二级列表
    local tDungeon    = {}
    local tOrderNames = {}

    local nCount      = g_tTable.DungeonInfo:GetRowCount()
    --row 1 for default
    for i = 2, nCount do
        local tLine = g_tTable.DungeonInfo:GetRow(i)

        if tMapIdSet[tLine.dwMapID] then
            local szVersionName = Table_GetDLCInfo(tLine.nDLCID).szDLCName
            if not tDungeon[szVersionName] then
                tDungeon[szVersionName] = {
                    dwMapIDMap = {},
                    tRecordList = {},
                    tHeadInfoList = {},
                    tHeadInfoMap = {} -- 用来展示同名副本
                }
                table.insert(tOrderNames, szVersionName)
            end

            local tRecord          = {}
            tRecord.dwClassID      = tLine.dwClassID
            tRecord.dwMapID        = tLine.dwMapID
            tRecord.nEnterMapID    = tLine.nEnterMapID
            tRecord.szName         = tLine.szOtherName
            tRecord.szIntroduction = tLine.szIntroduction
            tRecord.bIsPast        = tLine.bIsPast
            tRecord.bRushmode      = tLine.bRushmode
            tRecord.szLayer3Name   = tLine.szLayer3Name
            tRecord.nFitMinLevel   = tLine.nFitMinLevel
            tRecord.nFitMaxLevel   = tLine.nFitMaxLevel
            tRecord.bIsRecommend   = tLine.bIsRecommend
            tRecord.bHideDetail    = tLine.bHideDetail
            tRecord.szReward       = tLine.szReward
            tRecord.szExtReward    = tLine.szExtReward
            tRecord.dwQuestID      = tLine.dwQuestID
            tRecord.szVersionName  = szVersionName

            if not tDungeon[szVersionName].tHeadInfoMap[tRecord.szName] then
                tDungeon[szVersionName].tHeadInfoMap[tRecord.szName] = tRecord
                table.insert(tDungeon[szVersionName].tHeadInfoList, tRecord)
            end
            tDungeon[szVersionName].dwMapIDMap[tLine.dwMapID] = tRecord
            table.insert(tDungeon[szVersionName].tRecordList, tRecord)
        end
    end

    local fnSortTDungeon = function(tLeft, tRight)
        return tLeft.dwMapID > tRight.dwMapID
    end
    for _, tDungeonInfo in pairs(tDungeon) do
        table.sort(tDungeonInfo.tRecordList, fnSortTDungeon)
        table.sort(tDungeonInfo.tHeadInfoList, fnSortTDungeon)
    end

    return tDungeon, tOrderNames
end

---@param tQuest PartnerTravelTask
function UIPartnerTravelSettingView:SelectQuest(dwQuestID)
    self.nQuestID                                       = dwQuestID

    self.tSelectedPartnerIDList                         = {}
    self.bNeedSelectFirstNPartnerWhenFirstOpenLeftPanel = true

    self.nPageIndex                                     = 0

    local tQuest                                        = Table_GetPartnerTravelTask(self.nQuestID)

    local szQuestName                                   = UIHelper.GBKToUTF8(tQuest.szName)
    UIHelper.SetString(self.LabelSelectedQuestName, szQuestName)

    self:UpdateRewardListInfo()

    local bLocked, bAchievementLocked, bQuestLocked, bAdventureTryLocked, bFameLocked = PartnerData.IsTravelQuestLocked(tQuest)
    local bHasTrigger                                                                 = PartnerData.IsTravelQuestTriggered(tQuest)

    local bShowCardList                                                               = not (bLocked or bHasTrigger)

    UIHelper.SetVisible(self.LayoutPartner, bShowCardList)
    UIHelper.SetVisible(self.BtnStartTravel, bShowCardList)
    UIHelper.SetVisible(self.LabelHintMultipleCost, bShowCardList)
    UIHelper.SetVisible(self.LabelAllTime, bShowCardList)

    UIHelper.SetVisible(self.LabelHintLock, not bShowCardList)
    UIHelper.SetVisible(self.BtnGo, not bShowCardList)

    UIHelper.SetVisible(self.LayoutCurrencyCostList, not bHasTrigger)
    UIHelper.SetRichText(self.LabelHintLock, "")

    if not bHasTrigger then
        self:UpdateCostListInfo()
    end

    if bShowCardList then
        self:UpdateMultipleCostInfo()

        self:UpdateSelectedPartnerListInfo()
    else
        local szUnlockTips = ""

        if bLocked then
            local szUnlockTarget = ""

            if bAchievementLocked then
                szUnlockTarget = "成就"
            elseif bQuestLocked then
                szUnlockTarget = "任务"
            end

            szUnlockTips = string.format("需要完成%s前置%s方可开启委托出行", szQuestName, szUnlockTarget)
            if tQuest.dwAdventureID ~= 0 then
                szUnlockTips = "需要大侠亲身体验后解锁委派"
            end

            szUnlockTips = string.format("<color=#FFE26E>%s</color>", szUnlockTips)

            if self:IsMiJingClass(self.nClass) then
                -- 秘境的提示信息特殊处理，可点击跳转到成就页面
                local szLink = UrlEncode(string.format("Achievement/%s", tQuest.szPreAchievement))
                
                local aAchievement      = Table_GetAchievement(tonumber(tQuest.szPreAchievement))
                local szAchievementName = UIHelper.GBKToUTF8(aAchievement.szName)
                
                szUnlockTips            = string.format("需完成<href=%s><color=#FFE26E>[%s]</color></href>后解锁！", szLink, szAchievementName)
            end

        elseif bHasTrigger then
            szUnlockTips = "<color=#FFE26E>已触发</color>"
        end

        UIHelper.SetRichText(self.LabelHintLock, szUnlockTips)

        local szBtnText = "前往解锁"
        if self:IsMiJingClass(self.nClass) then
            szBtnText = "立即前往"
        elseif bHasTrigger then
            szBtnText = "查看详情"
        end
        UIHelper.SetString(self.LabelGo, szBtnText)

        UIHelper.BindUIEvent(self.BtnGo, EventType.OnClick, function()
            if self:IsMiJingClass(self.nClass) then
                -- 特殊处理秘境事件，跳转到对应秘境页面
                --self.tRecord.dwMapID
                ---@type UIDungeonEntranceView
                UIMgr.Open(VIEW_ID.PanelDungeonEntrance, { dwTargetMapID = self.tRecord.dwMapID })
                return
            end

            if bAchievementLocked then
                local aAchievement = Table_GetAchievement(tonumber(tQuest.szPreAchievement))

                UIMgr.Open(VIEW_ID.PanelAchievementContent, aAchievement.dwGeneral, aAchievement.dwSub, aAchievement.dwDetail, aAchievement.dwID)
            elseif bQuestLocked then
                local dwTaskID = tonumber(tQuest.szPreQuest)

                -- todo: 如果没有接到身上，这里好像没法追踪，等策划后面看看，比如说加个剑侠录的章节指引
                QuestData.SetTracingQuestID(dwTaskID)
                QuestData.RemoveProhibitTraceQuestID(dwTaskID)

                UIMgr.Open(VIEW_ID.PanelTask)
            elseif tQuest.dwAdventureID ~= 0 then
                UIMgr.Open(VIEW_ID.PanelQiYu, nil, tQuest.dwAdventureID)
            elseif bFameLocked then
                UIMgr.Open(VIEW_ID.PanelFame, tonumber(tQuest.szPreFame))
            end
        end)
    end

    if tQuest.dwAdventureID ~= 0 then
        local tTryInfo = PartnerData.tPetAdvIdToTryInfo[tQuest.dwAdventureID]
        UIHelper.SetButtonState(self.BtnStartTravel, tTryInfo.nHasTry < tTryInfo.nTryMax and BTN_STATE.Normal or BTN_STATE.Disable)
    end

    self:UpdateCurrencyListInfo()

    self:UpdateRightSideImgInfo()
end

function UIPartnerTravelSettingView:UpdateSelectedPartnerListInfo()
    local tQuest = Table_GetPartnerTravelTask(self.nQuestID)

    for idx, node in ipairs(self.tBtnPartnerTravelTargetCellList) do
        local script = UIHelper.GetBindScript(node)

        local bShow  = idx <= tQuest.nNeedPartnerNum
        UIHelper.SetVisible(node, bShow)

        if bShow then
            local dwPartnerID = self.tSelectedPartnerIDList[idx]

            local bSelected   = dwPartnerID ~= nil

            UIHelper.SetVisible(script.ImgAdd, not bSelected)
            UIHelper.SetVisible(script.MaskIcon, bSelected)

            if bSelected then
                local tPartnerInfo = Table_GetPartnerNpcInfo(dwPartnerID)
                local szImgPath    = tPartnerInfo.szSmallAvatarImg
                UIHelper.SetTexture(script.ImgFrameIcon, szImgPath)
            end
        end
    end

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutPartner, true, true)

    --- 更新所需总时长
    local fFinalDiscount = 1
    for _, dwPartnerID in ipairs(self.tSelectedPartnerIDList) do
        local tInfo         = Table_GetPartnerNpcInfo(dwPartnerID)
        local fOrigDiscount = GDAPI_HeroTravelTimeDisCount(dwPartnerID, self.nQuestID, tInfo.nQuality)

        --- 加算折扣
        fFinalDiscount      = fFinalDiscount - (1 - fOrigDiscount)
    end

    local szTime = self:FormatHourTime(math.ceil(tQuest.nTime * fFinalDiscount) * 60 / 3600)
    UIHelper.SetString(self.LabelAllTime, string.format("总时长：%s", szTime))

    local szColor = "#FFFFFF"
    if fFinalDiscount < 1 then
        szColor = "#95ff95"
    end
    UIHelper.SetColor(self.LabelAllTime, UIHelper.ChangeHexColorStrToColor(szColor))
end

function UIPartnerTravelSettingView:StartTravel()
    local tQuest    = Table_GetPartnerTravelTask(self.nQuestID)

    local nBoard    = self.nCurrentBoard
    local nIndex    = self.nQuestIndex
    local nQuest    = self.nQuestID
    local tHeroList = self:GetSelectedPartnerIDList()

    if nQuest == nil then
        TipsHelper.ShowNormalTip("请选择委托事件")
        return
    end
    if #tHeroList ~= tQuest.nNeedPartnerNum then
        TipsHelper.ShowNormalTip(string.format("请选择%d位要委托的侠客", tQuest.nNeedPartnerNum))
        self:OpenPartnerListLeftPanel()
        return
    end
    if not PartnerData.CheckTravelCost({ self.nQuestID }) then
        return
    end

    LOG.TABLE({
                  "调试：侠客开始出行",
                  nBoard, nIndex, nQuest, tHeroList
              })
    UIHelper.RemoteCallToServer("On_Hero_StartTravel", {
        { nBoard, nIndex, nQuest, tHeroList },
    })

    if tQuest.nClass ~= ClassID_PetQiYu then
        PartnerData.tTravelClassToLastChooseQuestId[tQuest.nClass] = nQuest
    end

    UIMgr.Close(self)
end

---@return number[]
function UIPartnerTravelSettingView:GetSelectedPartnerIDList()
    return self.tSelectedPartnerIDList
end

function UIPartnerTravelSettingView:UpdateRewardListInfo()
    self:UpdatePreviewRewardList()

    local tQuest             = Table_GetPartnerTravelTask(self.nQuestID)
    local tAchievementReward = SplitString(tQuest.szAchievement, ";")
    UIHelper.SetVisible(self.BtnAchievement, table.get_len(tAchievementReward) > 0)

    local nAchievementCount, nAchievementFinish = AchievementData.GetAchievementFinishCount(tAchievementReward)
    UIHelper.SetString(self.LabelAchievements, string.format("成就(%d/%d)", nAchievementFinish, nAchievementCount))
end

--- 解析形如下面格式的道具货币列表，并添加到layout中
--- COIN_1_50;COIN_4_250;COIN_5_3500;5_75330;
function UIPartnerTravelSettingView:UpdatePreviewRewardList()
    local tQuest = Table_GetPartnerTravelTask(self.nQuestID)

    UIHelper.RemoveAllChildren(self.ScrollViewReward)

    --- 必得奖励
    local tMustGetReward = SplitString(tQuest.szGiftItem, ";")
    local tRandomGift    = SplitString(tQuest.szRandomGiftItem, ";")

    local tAllReward     = {
        { tMustGetReward, true },
        { tRandomGift, false },
    }
    for _, tRewardCfg in ipairs(tAllReward) do
        local tReward  = tRewardCfg[1]
        local bMustGet = tRewardCfg[2]

        for _, v in pairs(tReward) do
            local tInfo                   = SplitString(v, "_")
            local dwType, dwIndex, nCount = tonumber(tInfo[1]), tonumber(tInfo[2]), tonumber(tInfo[3])
            nCount                        = nCount or 0

            if tInfo[1] ~= "COIN" then
                --- 道具
                local hItemInfo  = GetItemInfo(dwType, dwIndex)
                local szName     = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(hItemInfo, nCount))
                szName           = UIHelper.TruncateStringReturnOnlyResult(szName, 3)

                local bCollected = self:IsItemCollected(hItemInfo, dwType, dwIndex, nCount)

                ---@type UIQuestAwardView
                local script     = UIHelper.AddPrefab(
                        PREFAB_ID.WidgetAwardItemPartner, self.ScrollViewReward,
                        szName, nCount, dwType, dwIndex, nil, nil, nil, true
                )
                script:OnEnter(szName, nCount, dwType, dwIndex, nil, nil, nil, true)
                UIHelper.SetAnchorPoint(script._rootNode, 0, 0)

                local bIsBook = hItemInfo.nGenre == ITEM_GENRE.BOOK

                if not bIsBook and nCount > 1 then
                    script:SetIconCount(nCount)
                end

                script:SetSingleClickCallback(function(nItemType, nItemIndex)
                    TipsHelper.DeleteAllHoverTips()
                    local uiTips, uiItemTipScript = TipsHelper.ShowItemTips(script._rootNode, nItemType, nItemIndex)

                    if bIsBook then
                        uiItemTipScript:SetBookID(nCount)
                        uiItemTipScript:OnInitWithTabID(nItemType, nItemIndex)
                    end

                    uiItemTipScript:SetBtnState({})
                end)

                UIHelper.SetVisible(script.ImgBiDe, bMustGet)
                UIHelper.SetVisible(script.ImgGet, bCollected)
            else
                --- 货币
                local tbLine = Table_GetCalenderActivityAwardIconByID(dwIndex) or {}
                local szName = CurrencyNameToType[tbLine.szName]
                szName       = UIHelper.TruncateStringReturnOnlyResult(szName, 3)

                ---@type UIQuestAwardView
                local script = UIHelper.AddPrefab(
                        PREFAB_ID.WidgetAwardItemPartner, self.ScrollViewReward,
                        szName, nCount, nil, nil, nil, nil, nil, true
                )
                script:OnEnter(szName, nCount, nil, nil, nil, nil, nil, true)
                UIHelper.SetAnchorPoint(script._rootNode, 0, 0)
                UIHelper.SetSpriteFrame(script.scriptItemIcon.ImgIcon, CurrencyData.tbImageBigIcon[CurrencyNameToType[tbLine.szName]])

                script:SetIconCount(nCount)

                script:SetSingleClickCallback(function(nItemType, nItemIndex)
                    TipsHelper.DeleteAllHoverTips()

                    TipsHelper.ShowItemTips(script._rootNode, "CurrencyType", szName, false)
                end)
            end
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewReward)
end

-- 参考 UIItemTip:UpdateCollectedInfo(item)
function UIPartnerTravelSettingView:IsItemCollected(item, dwType, dwIndex, nCount)
    local bCollected = false

    local bHasItem   = ItemData.GetItemAmountInPackage(dwType, dwIndex) > 0

    if ItemData.IsPendantItem(item) then
        --挂件
        bCollected = bHasItem or g_pClientPlayer.IsPendentOwn(dwIndex)
    elseif item.nGenre == ITEM_GENRE.EQUIPMENT and ItemData.IsPendantPetItem(item) then
        -- 挂宠
        bCollected = bHasItem or g_pClientPlayer.IsHavePendentPet(dwIndex)
    elseif item.nGenre == ITEM_GENRE.TOY then
        -- 玩具
        bCollected = bHasItem

        local tToy = Table_GetToyBoxByItem(dwIndex)
        if tToy then
            bCollected = bCollected or GDAPI_IsToyHave(g_pClientPlayer, tToy.dwID, tToy.nCountDataIndex)
        end
    elseif item.nGenre == ITEM_GENRE.EQUIPMENT and item.nSub == EQUIPMENT_SUB.PET then
        -- 宠物
        local nPetIndex = GetFellowPetIndexByItemIndex(ITEM_TABLE_TYPE.CUST_TRINKET, dwIndex)
        bCollected      = bHasItem or g_pClientPlayer.IsFellowPetAcquired(nPetIndex)
    elseif item.nGenre == ITEM_GENRE.HOMELAND then
        --家具
        bCollected = bHasItem or HomelandEventHandler.IsFurnitureCollected(item.dwFurnitureID)
    elseif item.nGenre == ITEM_GENRE.BOOK then
        --书籍        
        local bInBag              = self:IsBookInBag(dwType, dwIndex, nCount)

        local nBookID, nSegmentID = GlobelRecipeID2BookID(nCount)

        bCollected                = bInBag or g_pClientPlayer.IsBookMemorized(nBookID, nSegmentID)
    elseif item.nSub == EQUIPMENT_SUB.HORSE_EQUIP then
        -- 马具
        local tList = g_pClientPlayer.GetAllHorseEquip()
        for _, tItem in ipairs(tList) do
            if tItem.dwItemIndex == dwIndex then
                bCollected = true
                break
            end
        end

        bCollected = bHasItem or bCollected
    end

    return bCollected
end

function UIPartnerTravelSettingView:IsBookInBag(dwType, dwIndex, nBookID)
    local tbBoxSet = ItemData.BoxSet.Bag
    for i, nBox in ipairs(tbBoxSet) do
        for k, tbItemInfo in ipairs(ItemData.GetBoxItem(nBox)) do
            local hItem = ItemData.GetItemByPos(tbItemInfo.nBox, tbItemInfo.nIndex)
            if hItem and hItem.dwTabType == dwType and hItem.dwIndex == dwIndex and hItem.nBookID == nBookID then
                return true
            end
        end
    end

    return false
end

function UIPartnerTravelSettingView:UpdateCostListInfo()
    local tQuest     = Table_GetPartnerTravelTask(self.nQuestID)

    local layout     = self.LayoutCurrencyCost
    local szGiftItem = tQuest.szCostList

    UIHelper.RemoveAllChildren(layout)

    local tReward = SplitString(szGiftItem, ";")
    for _, v in pairs(tReward) do
        local tInfo                   = SplitString(v, "_")
        local dwType, dwIndex, nCount = tonumber(tInfo[1]), tonumber(tInfo[2]), tonumber(tInfo[3])
        nCount                        = nCount or 0

        if tInfo[1] ~= "COIN" then
            local nActualCount = PartnerData.GetTravelItemCostCount(dwType, dwIndex, nCount, tQuest.nDataIndex, 1)

            ---@see UISingleCurrency
            local script       = UIHelper.AddPrefab(PREFAB_ID.WidgetSingleCurrency, layout, dwType, dwIndex, true, nActualCount)

            local nItemCount   = PartnerData.GetItemAmountInPackage(dwType, dwIndex)
            if nItemCount < nActualCount then
                UIHelper.SetColor(script.LabelCurrency, UIHelper.ChangeHexColorStrToColor("#FF0000"))
            end
        else
            local tbLine = Table_GetCalenderActivityAwardIconByID(dwIndex) or {}
            local szName = CurrencyNameToType[tbLine.szName]

            ---@type UIOtherCurrency
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, layout)
            script:SetCurrencyType(szName)
            script:SetLableCount(nCount)

            local nCurrentCount = CurrencyData.GetCurCurrencyCount(szName)
            if nCurrentCount < nCount then
                UIHelper.SetColor(script.LabelCount, UIHelper.ChangeHexColorStrToColor("#FF0000"))
            end
        end
    end

    UIHelper.LayoutDoLayout(layout)

    UIHelper.LayoutDoLayout(self.LayoutCurrencyCostList)
end

function UIPartnerTravelSettingView:UpdateMultipleCostInfo()
    local tQuest     = Table_GetPartnerTravelTask(self.nQuestID)
    
    local tLuCaiMultiCostConfigList = PartnerData.GetTravelClassLuCaiMultiCostConfigList(tQuest.nDataIndex)
    local bHasMultiCost             = table.get_len(tLuCaiMultiCostConfigList) > 0

    UIHelper.SetVisible(self.LabelHintMultipleCost, bHasMultiCost)
    if bHasMultiCost then
        local tFirstConfig    = tLuCaiMultiCostConfigList[1]
        local szMultiCostTips = string.format("出行达到%d次时，[路菜]消耗翻%d倍。", tFirstConfig.nReachCount, tFirstConfig.nMultiple)

        local _, nCount, nMax = PartnerData.GetTravelCountInfo(tQuest.nDataIndex)
        if nCount >= tFirstConfig.nReachCount then
            szMultiCostTips = string.format("出行已达到%d次，[路菜]消耗翻%d倍 。", tFirstConfig.nReachCount, tFirstConfig.nMultiple)

            --- 已经达到时显示黄色
            UIHelper.SetColor(self.LabelHintMultipleCost, UIHelper.ChangeHexColorStrToColor("#ffe26e"))
        end

        UIHelper.SetString(self.LabelHintMultipleCost, szMultiCostTips)
    end
end

function UIPartnerTravelSettingView:OnSelectSubTitle(nSub, bSelected)
    local scriptTitle = self.tSubToScript[nSub]

    if bSelected then
        for _, otherScriptTitle in pairs(self.tSubToScript) do
            if scriptTitle ~= otherScriptTitle then
                otherScriptTitle.bSelected = false
                UIHelper.SetSelected(otherScriptTitle.ToggleTitle, false)
            end
        end
        self.nCurSub = nSub
    end
    scriptTitle.bSelected = bSelected
    UIHelper.SetSelected(self.ScriptAutoToping.ToggleTitle, bSelected, false)

    self:UpdateQuestListToggle()
end

function UIPartnerTravelSettingView:UpdateQuestListToggle()
    for nQuest, script in pairs(self.tQuestIdToScript) do
        local tQuest    = Table_GetPartnerTravelTask(nQuest)
        local scriptCur = self.tSubToScript[self.nCurSub]

        local bShow     = tQuest.nSub == self.nCurSub and scriptCur.bSelected

        UIHelper.SetVisible(script._rootNode, bShow)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewLeftListMore)

    if self.nCurSub then
        local scriptCur = self.tSubToScript[self.nCurSub]
        UIHelper.ScrollLocateToPreviewItem(self.ScrollViewLeftListMore, scriptCur._rootNode, Locate.TO_TOP)
    end
end

function UIPartnerTravelSettingView:OnSelectDungeonVersionName(szVersionName, bSelected)
    local scriptTitle = self.tVersionNameToTitleScript[szVersionName]

    if bSelected then
        for _, otherScriptTitle in pairs(self.tVersionNameToTitleScript) do
            if otherScriptTitle ~= scriptTitle then
                otherScriptTitle.bSelected = false
                UIHelper.SetSelected(otherScriptTitle.ToggleTitle, false)
            end
        end
        self.szCurVersionName = szVersionName
    end
    scriptTitle.bSelected = bSelected

    UIHelper.SetSelected(self.ScriptAutoToping.ToggleTitle, bSelected, false)

    self:UpdateDungeonNameListToggle()
end

function UIPartnerTravelSettingView:UpdateDungeonNameListToggle()
    for szName, script in pairs(self.tDungeonNameToTaskScript) do
        local tDungeonRecordList = self.tMapNameToDungeonRecordList[szName]

        local bShow              = false
        if table.get_len(tDungeonRecordList) > 0 then
            local tRecord   = tDungeonRecordList[1]
            local scriptCur = self.tVersionNameToTitleScript[self.szCurVersionName]

            bShow           = tRecord.szVersionName == self.szCurVersionName and scriptCur.bSelected
        end

        UIHelper.SetVisible(script._rootNode, bShow)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewLeftListMore)

    if self.szCurVersionName then
        local scriptCur = self.tVersionNameToTitleScript[self.szCurVersionName]
        Timer.AddFrame(self, 1, function()
            UIHelper.ScrollLocateToPreviewItem(self.ScrollViewLeftListMore, scriptCur._rootNode, Locate.TO_TOP)
        end)
    end
end

function UIPartnerTravelSettingView:OnScrollViewTaskTouchMoved()
    if not self.nCurSub and not self.szCurVersionName then
        return
    end

    ---@type UIPartnerTravelSettingListTitle
    local scriptCur
    if self.nCurSub then
        scriptCur = self.tSubToScript[self.nCurSub]
    elseif self.szCurVersionName then
        scriptCur = self.tVersionNameToTitleScript[self.szCurVersionName]
    end

    if not scriptCur then
        return
    end

    local bShow = true
    if not scriptCur.bSelected then
        bShow = false
    end

    local nTopY       = UIHelper.GetWorldPositionY(self.ScriptAutoToping._rootNode)
    local nSelectY    = UIHelper.GetWorldPositionY(scriptCur._rootNode)
    local bAutoToping = UIHelper.GetVisible(self.WidgetTopContainer)

    --- 如果当前标题在固定项下方，则不显示
    -- note: 这里初始位置可能有点偏差，把固定项高度看高一点点
    if nSelectY <= nTopY + 1 then
        bShow = false
    end

    if bShow and not bAutoToping then
        UIHelper.SetVisible(self.WidgetTopContainer, true)
        UIHelper.SetVisible(scriptCur._rootNode, false)

        self.ScriptAutoToping:OnEnter(scriptCur.szTitle)
        UIHelper.BindUIEvent(self.ScriptAutoToping.ToggleTitle, EventType.OnSelectChanged, function(_, bSelected)
            UIHelper.SetVisible(scriptCur._rootNode, true)
            UIHelper.SetSelected(scriptCur.ToggleTitle, bSelected, false)

            if not self:IsMiJingClass(self.nClass) then
                self:OnSelectSubTitle(self.nCurSub, bSelected)
            else
                self:OnSelectDungeonVersionName(self.szCurVersionName, bSelected)
            end
        end)
    elseif not bShow and bAutoToping then
        UIHelper.SetVisible(self.WidgetTopContainer, false)
        UIHelper.SetVisible(scriptCur._rootNode, true)
    end
end

function UIPartnerTravelSettingView:UpdateCurrencyListInfo()
    local tQuest     = Table_GetPartnerTravelTask(self.nQuestID)

    local szGiftItem = tQuest.szCostList

    UIHelper.RemoveAllChildren(self.LayoutCurrency)

    local tReward = SplitString(szGiftItem, ";")
    for _, v in pairs(tReward) do
        local tInfo                   = SplitString(v, "_")
        local dwType, dwIndex, nCount = tonumber(tInfo[1]), tonumber(tInfo[2]), tonumber(tInfo[3])
        nCount                        = nCount or 0

        if tInfo[1] ~= "COIN" then
            -- 道具
            local nItemCount = PartnerData.GetItemAmountInPackage(dwType, dwIndex)

            ---@see UISingleCurrency
            local script     = UIHelper.AddPrefab(PREFAB_ID.WidgetSingleCurrency, self.LayoutCurrency, dwType, dwIndex, true, nItemCount)
        else
            -- 货币
            local tbLine        = Table_GetCalenderActivityAwardIconByID(dwIndex) or {}
            local szName        = CurrencyNameToType[tbLine.szName]

            local nCurrentCount = CurrencyData.GetCurCurrencyCount(szName)

            ---@type UIOtherCurrency
            local script        = UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.LayoutCurrency)
            script:SetCurrencyType(szName)
            script:SetLableCount(nCurrentCount)
        end
    end

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutCurrency, true, true)
end

function UIPartnerTravelSettingView:FormatHourTime(fTime)
    local szTime = string.format("%.1f小时", fTime)
    if fTime == math.floor(fTime) then
        szTime = string.format("%.0f小时", fTime)
    end

    return szTime
end

function UIPartnerTravelSettingView:ShowAchievementReward()
    ---@see UIPartnerTravelAchievePopView#OnEnter
    UIMgr.Open(VIEW_ID.PanelPartnerTravelAchievePop, self.nQuestID)
end

function UIPartnerTravelSettingView:GetPetTryList()
    local tPetTryList = {}

    local tSubToInfo  = Table_GetPartnerTravelClassToSubToInfo()[self.nClass]

    local tSubIdList  = {}
    for nSub, _ in pairs(tSubToInfo) do
        table.insert(tSubIdList, nSub)
    end

    for _, nSub in ipairs(tSubIdList) do
        local tSubInfo   = tSubToInfo[nSub]

        local tQuestList = Table_GetPartnerTravelTaskClassToSubToInfoList()[tSubInfo.nClass][tSubInfo.nSub]

        for nIndex, tQuest in ipairs(tQuestList) do
            if tQuest.dwAdventureID ~= 0 then
                table.insert(tPetTryList, tQuest.dwAdventureID)
            end
        end
    end

    return tPetTryList
end

function UIPartnerTravelSettingView:OpenPartnerListLeftPanel()
    UIHelper.RemoveAllChildren(self.WidgetAnchorLeftPop)
    UIHelper.SetVisible(self.WidgetAnchorLeftPop, true)

    ---@see UIPartnerTravelSelectRole
    UIHelper.AddPrefab(PREFAB_ID.WidgetPartnerTravelSelectRole, self.WidgetAnchorLeftPop, self.nQuestID, self.tSelectedPartnerIDList, self.bNeedSelectFirstNPartnerWhenFirstOpenLeftPanel)

    self.bNeedSelectFirstNPartnerWhenFirstOpenLeftPanel = false
end

local szDifficultyImgPath        = {
    "UIAtlas2_Dungeon_Dungeon01_img_difficulty_Icon01",
    "UIAtlas2_Dungeon_Dungeon01_img_difficulty_Icon02",
    "UIAtlas2_Dungeon_Dungeon01_img_difficulty_Icon03",
}

local tClassToSettingImagePath   = {
    [4] = "UIAtlas2_Partner_ParterTravelSetting_img_zi1", -- 公共任务
    [2] = "UIAtlas2_Partner_ParterTravelSetting_img_zi2", -- 往期茶馆
    [3] = "UIAtlas2_Partner_ParterTravelSetting_img_zi3", -- 往期名望
    [8] = "UIAtlas2_Partner_ParterTravelSetting_img_zi4", -- 往期日常
    [7] = "UIAtlas2_Partner_ParterTravelSetting_img_zi5", -- 活动
}
local tClassToSettingImageBgPath = {
    [4] = "UIAtlas2_Partner_ParterTravelSetting_img_tu1", -- 公共任务
    [2] = "UIAtlas2_Partner_ParterTravelSetting_img_tu2", -- 往期茶馆
    [3] = "UIAtlas2_Partner_ParterTravelSetting_img_tu3", -- 往期名望
    -- fixme: 这里的7和8其实也要单独的背景图，但是这次没制作，暂时先用默认的公共任务的图，后续有资源了补上
}

function UIPartnerTravelSettingView:UpdateRightSideImgInfo()
    local tQuest           = Table_GetPartnerTravelTask(self.nQuestID)

    local tAdventureIdList = self:GetTryAdventureList()
    local nCount           = table.get_len(tAdventureIdList)

    local bMiJing          = self:IsMiJingClass(tQuest.nClass)

    UIHelper.SetVisible(self.ImgDIfficultyIconBg, nCount == 0 and bMiJing)
    UIHelper.SetVisible(self.ImgMode, nCount == 0 and not bMiJing)
    UIHelper.SetVisible(self.WidgetBanner, nCount == 1)
    UIHelper.SetVisible(self.PageViewBanner, nCount > 1)
    UIHelper.SetVisible(self.LayoutBannerPage, nCount > 1)

    if nCount == 0 then
        -- 没有奇遇的情况

        if bMiJing then
            -- 秘境
            local nDifficultyID = DungeonData.GetDungeonDifficultyID(UIHelper.GBKToUTF8(self.tRecord.szLayer3Name))
            UIHelper.SetSpriteFrame(self.ImgDIfficultyIcon, szDifficultyImgPath[nDifficultyID])
        else
            -- 其他
            local szIconPath   = tClassToSettingImagePath[self.nClass]
            local szIconBgPath = tClassToSettingImageBgPath[self.nClass]
            UIHelper.SetSpriteFrame(self.ImgMode, szIconPath)
            UIHelper.SetSpriteFrame(self.ImgModeBg, szIconBgPath)
        end
    elseif nCount == 1 then
        UIHelper.RemoveAllChildren(self.WidgetBanner)

        local dwAdventureID = tAdventureIdList[1]

        ---@see UIPartnerTravelSettingBanner
        local script        = UIHelper.AddPrefab(PREFAB_ID.WidgetPartnerTravelSettingBanner, self.WidgetBanner, dwAdventureID)
    else
        -- 显示奇遇的轮播组件
        UIHelper.RemoveAllChildren(self.PageViewBanner)

        for _, dwAdventureID in ipairs(tAdventureIdList) do
            ---@see UIPartnerTravelSettingBanner
            local script = UIHelper.PageViewAddPage(self.PageViewBanner, PREFAB_ID.WidgetPartnerTravelSettingBanner, dwAdventureID)
            UIHelper.SetAnchorPoint(script._rootNode, 0, -0.5)
        end

        UIHelper.ScrollViewDoLayout(self.PageViewBanner)
        UIHelper.ScrollToPage(self.PageViewBanner, 0)

        for nIdx, pageToggle in ipairs(self.tPageTogPoints) do
            UIHelper.SetVisible(pageToggle, nIdx <= nCount)
        end
        UIHelper.LayoutDoLayout(self.LayoutBannerPage)
    end
end

function UIPartnerTravelSettingView:GetTryAdventureList()
    local tQuest             = Table_GetPartnerTravelTask(self.nQuestID)

    -- 可能的格式如下，这里处理下数据
    --
    -- 21
    -- 21;22;
    local tSzAdventureIdList = string.split(tQuest.szTryAdventure, ";")
    local tAdventureIdList   = {}

    for _, szAdventureID in ipairs(tSzAdventureIdList) do
        if szAdventureID ~= "" then
            table.insert(tAdventureIdList, tonumber(szAdventureID))
        end
    end

    return tAdventureIdList
end

function UIPartnerTravelSettingView:CheckPageView()
    local nPageIndex = UIHelper.GetPageIndex(self.PageViewBanner)
    if self.nPageIndex and self.nPageIndex ~= nPageIndex then
        self:AutoFixPageView(nPageIndex + 1)
    end
    self.nPageIndex = nPageIndex

    if not self.nAutoPageTimer then
        self.nAutoPageTimer = Timer.Add(self, 5, function()
            local nAdventureLen  = table.get_len(self:GetTryAdventureList())
            local nNextPageIndex = (self.nPageIndex + 1) % nAdventureLen

            UIHelper.ScrollToPage(self.PageViewBanner, nNextPageIndex, 0.25)
        end)
    end
end

function UIPartnerTravelSettingView:AutoFixPageView(index)
    for i, pageToggle in ipairs(self.tPageTogPoints) do
        UIHelper.SetSelected(pageToggle, i == index, false)
    end
end

function UIPartnerTravelSettingView:IsMiJingClass(nClass)
    return nClass == ClassID_WuRenMiJing or nClass == ClassID_TuanDuiMiJing
end

return UIPartnerTravelSettingView