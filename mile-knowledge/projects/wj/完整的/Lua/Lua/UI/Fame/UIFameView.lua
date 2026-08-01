-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIFameView
-- Date: 2023-06-07 19:26:50
-- Desc: 名望
-- Prefab: PanelFame
-- ---------------------------------------------------------------------------------

local UIFameView = class("UIFameView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIFameView:_LuaBindList()
    self.BtnClose               = self.BtnClose --- 关闭界面

    self.ScrollViewFameSelect   = self.ScrollViewFameSelect --- 名望势力列表

    self.WidgetFameGrade        = self.WidgetFameGrade --- 等级和进度信息上层的widget

    self.LabelFameName          = self.LabelFameName --- 势力名称
    self.WidgetAnchorFameStore  = self.WidgetAnchorFameStore --- 名望商人导航组件
    self.BtnNpcLink             = self.BtnNpcLink --- 名望商人的导航按钮
    self.LabelNpcLink           = self.LabelNpcLink --- 名望商人名称
    self.ImgFrameLogo           = self.ImgFrameLogo --- 势力logo

    self.LayoutFameDetail       = self.LayoutFameDetail --- 详情上层的layout
    self.RichTextInfo           = self.RichTextInfo --- 描述
    self.ScrollViewAward        = self.ScrollViewAward --- 奖励的scrollview
    self.ScrollViewFameEvent    = self.ScrollViewFameEvent --- 名望事件的scrollview
    self.LayoutFameEvent        = self.LayoutFameEvent --- 名望事件的最上层组件
    self.LayoutFameCondiction   = self.LayoutFameCondiction --- 解锁条件的最上层组件
    self.WidgetAnchorBtn        = self.WidgetAnchorBtn --- 前往参与按钮上层的组件

    self.TogFameTips            = self.TogFameTips --- 名望tips的toggle
    self.BtnCloseFameTips       = self.BtnCloseFameTips --- 关闭名望tips的按钮
    self.LabelFameTips          = self.LabelFameTips --- 名望tips的内容

    self.LabelFameLevel         = self.LabelFameLevel --- 等级
    self.LabelFameLevelProgress = self.LabelFameLevelProgress --- 等级进度
    self.ProgressBarLevel       = self.ProgressBarLevel --- 等级进度条

    self.TogLevelTips           = self.TogLevelTips --- 等级tips的toggle
    self.BtnCloseLevelTips      = self.BtnCloseLevelTips --- 关闭等级tips的按钮
    self.LabelLevelTips         = self.LabelLevelTips --- 等级tips的内容

    self.BtnLeaveFor            = self.BtnLeaveFor --- 导航当前事件的地图

    self.tWidgetQuestButtonList = self.tWidgetQuestButtonList --- 任务信息组件列表

    self.BtnHowPlay             = self.BtnHowPlay --- 规则按钮
end

function UIFameView:OnEnter(dwID)
    self.nSelectIndex  = 1

    self.tFameInfoList = FameData.GetFameInfoList()

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if dwID then
        local nIndex
        for i = 1, #self.tFameInfoList do
            if self.tFameInfoList[i].dwID == dwID then
                nIndex = i
                break
            end
        end
        if nIndex then
            self.nSelectIndex = nIndex
        end
    else
        self.nSelectIndex = 1
    end

    self:UpdateInfo()
end

function UIFameView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFameView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        UIHelper.SetSelected(self.TogFameTips, false)
        UIHelper.SetSelected(self.TogLevelTips, false)
    end)

    UIHelper.BindUIEvent(self.BtnLeaveFor, EventType.OnClick, function()
        self:ShowCurrentEventMap()
    end)

    UIHelper.BindUIEvent(self.BtnHowPlay, EventType.OnClick, function()
        self:ShowRuleInfo()
    end)
end

function UIFameView:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        Timer.AddFrame(self, 5, function()
            self:UpdateSelectedFameInfo()
            UIHelper.CascadeDoLayoutDoWidget(self.LayoutFameDetail, true, true)
        end)
    end)
end

function UIFameView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFameView:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewFameSelect)

    for idx, tFameInfo in ipairs(self.tFameInfoList) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetFameSelect, self.ScrollViewFameSelect, tFameInfo)
        if idx == self.nSelectIndex then
            UIHelper.SetSelected(script.TogFameSelect, true, false)
        end
        UIHelper.BindUIEvent(script.TogFameSelect, EventType.OnClick, function()
            self.nSelectIndex = idx

            self:UpdateSelectedFameInfo()
        end)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewFameSelect)

    self:UpdateSelectedFameInfo()
end

function UIFameView:UpdateSelectedFameInfo()
    local tInfo = self.tFameInfoList[self.nSelectIndex]

    -- 公共的组件
    UIHelper.SetVisible(self.WidgetFameGrade, not tInfo.bLocked)
    UIHelper.SetVisible(self.TogLevelTips, not tInfo.bLocked)

    UIHelper.SetString(self.LabelFameName, UIHelper.GBKToUTF8(tInfo.szName))

    -- 名望tips
    local szAccountSharedState = ""
    if g_pClientPlayer.bAccountShared then
        szAccountSharedState = g_tStrings.STR_FAME_ACCOUNT_SHARED
    else
        szAccountSharedState = g_tStrings.STR_FAME_ACCOUNT_NOT_SHARED
    end
    local szFameTip = ParseTextHelper.ParseNormalText(FormatString(g_tStrings.STR_FAME_TIPS, szAccountSharedState))
    UIHelper.SetString(self.LabelFameTips, szFameTip)

    -- 名望商人按钮
    ---@type UIWidgetRenownStoreDescribe
    local scriptStoreDescribe = UIHelper.GetBindScript(self.WidgetAnchorFameStore)
    if scriptStoreDescribe then
        for k, v in ipairs(tInfo.tRewardNPCInfo) do
            local tNpcInfo                    = SplitString(tInfo.tRewardNPCInfo[k], ";")
            local szName, dwGroupID, dwShopID = tNpcInfo[1], tonumber(tNpcInfo[2]), tonumber(tNpcInfo[3])

            UIHelper.SetString(scriptStoreDescribe.LabelNpcLink, UIHelper.GBKToUTF8(szName))
            UIHelper.BindUIEvent(scriptStoreDescribe.BtnNpcLink, EventType.OnClick, function()
                ShopData.OpenSystemShopGroup(dwGroupID, dwShopID)
            end)
            break
        end
    end

    UIHelper.SetSpriteFrame(self.ImgFrameLogo, FameLogImg[tInfo.szLogoPath])

    UIHelper.SetRichText(self.RichTextInfo, UIHelper.GBKToUTF8(tInfo.szDec))

    -- 奖励列表
    self:UpdateRewardInfo()

    if tInfo.dwID == 1 then
        UIHelper.SetVisible(self.LayoutFameEvent, not tInfo.bLocked)
    else
        UIHelper.SetVisible(self.LayoutFameEvent, false)
    end
    UIHelper.SetVisible(self.WidgetAnchorBtn, not tInfo.bLocked)
    UIHelper.SetVisible(self.LayoutFameCondiction, tInfo.bLocked)

    if not tInfo.bLocked then
        -- 已解锁
        -- 等级
        UIHelper.SetString(self.LabelFameLevel, tInfo.nNowLevel .. "级")

        local szProgress = tInfo.nProgressUp .. "/" .. tInfo.nProgressDown
        local fProgress  = 0
        if tInfo.nProgressDown ~= 0 then
            fProgress = tInfo.nProgressUp / tInfo.nProgressDown
        end
        if tInfo.nNowLevel >= tInfo.nMaxLevel then
            szProgress = ""
            fProgress  = 0
        end
        UIHelper.SetString(self.LabelFameLevelProgress, szProgress)
        UIHelper.SetProgressBarPercent(self.ProgressBarLevel, fProgress * 100)

        -- 等级tips
        local szAccountOrRule = ""
        if g_pClientPlayer.bAccountShared then
            szAccountOrRule = g_tStrings.STR_FAME_ACCOUNT
        else
            szAccountOrRule = g_tStrings.STR_FAME_ROLE
        end
        local szLevelTip = ParseTextHelper.ParseNormalText(FormatString(UIHelper.GBKToUTF8(tInfo.szLevelTips), szAccountOrRule, tInfo.nNowLevel, tInfo.nMaxLevel))
        UIHelper.SetString(self.LabelLevelTips, szLevelTip)

        self:UpdateEventList()
    else
        -- 未解锁

        -- 解锁条件
        self:UpdateUnlockMapQuestInfo()
    end

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutFameDetail, true, true)
end

function UIFameView:UpdateRewardInfo()
    local tInfo = self.tFameInfoList[self.nSelectIndex]

    UIHelper.RemoveAllChildren(self.ScrollViewAward)

    for k, v in ipairs(tInfo.tRewardInfo) do
        -- 1;5;49340
        local tRewardItemInfo            = SplitString(tInfo.tRewardInfo[k], ";")
        local nLevel, dwTabType, dwIndex = tonumber(tRewardItemInfo[1]), tonumber(tRewardItemInfo[2]), tonumber(tRewardItemInfo[3])

        UIHelper.AddPrefab(PREFAB_ID.WidgetFameAward, self.ScrollViewAward, nLevel, dwTabType, dwIndex)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewAward)
    UIHelper.ScrollToLeft(self.ScrollViewAward, 0)
end

function UIFameView:UpdateEventList()
    local tInfo           = self.tFameInfoList[self.nSelectIndex]

    -- 计算以当前事件为中心的五个事件
    local nHappenMapId    = GDAPI_GetFamePlaceHappen(g_pClientPlayer, tInfo.dwID)

    local _, nHappenIndex = table.find_if(tInfo.tMapIDs, function(szMapID)
        return tonumber(szMapID) == nHappenMapId
    end)

    local nHour           = GetCurrentHour()
    local nMinute         = GetCurrentMinute()

    local nSideCount      = 2
    local tEventInfoList  = {}
    for idx = nHappenIndex - nSideCount, nHappenIndex + nSideCount do
        local nEventMinuteCount = nHour * 60 + nMinute + (idx - nHappenIndex) * 30
        if nEventMinuteCount < 0 then
            nEventMinuteCount = nEventMinuteCount + 24 * 60
        elseif nEventMinuteCount > 24 * 60 then
            nEventMinuteCount = nEventMinuteCount - 24 * 60
        end

        local nEventHour   = math.floor(nEventMinuteCount / 60)
        local nEventMinute = nEventMinuteCount % 60
        local szMinuteType = ""
        if nEventMinute < 30 then
            szMinuteType = "00"
        else
            szMinuteType = "30"
        end

        local szEventTime = string.format("%s:%s", tostring(nEventHour), szMinuteType)
        local nMapIndex   = (idx + #tInfo.tMapIDs - 1) % #tInfo.tMapIDs + 1

        table.insert(tEventInfoList, {
            bCurrentEvent = idx == nHappenIndex,
            szTime = szEventTime,
            nMapId = tInfo.tMapIDs[nMapIndex],
        })
    end

    -- 展示事件
    UIHelper.RemoveAllChildren(self.ScrollViewFameEvent)

    for _, tEventInfo in ipairs(tEventInfoList) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetFameEvent, self.ScrollViewFameEvent, tEventInfo.bCurrentEvent, tEventInfo.szTime, tEventInfo.nMapId)
        UIHelper.SetAnchorPoint(script._rootNode, 0, 0)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewFameEvent)
    UIHelper.ScrollToLeft(self.ScrollViewFameEvent)
end

function UIFameView:ShowCurrentEventMap()
    local tInfo        = self.tFameInfoList[self.nSelectIndex]

    local nHappenMapId = GDAPI_GetFamePlaceHappen(g_pClientPlayer, tInfo.dwID)

    UIMgr.Open(VIEW_ID.PanelMiddleMap, nHappenMapId, 0)
end

local tIdToRuleId = {
    [1] = 42,
    [2] = 43,
    [3] = 50,
}

function UIFameView:ShowRuleInfo()
    local tInfo   = self.tFameInfoList[self.nSelectIndex]

    local nRuleId = tInfo.nVKRuleId

    UIMgr.Open(VIEW_ID.PanelHelpPop, nRuleId)
end

function UIFameView:UpdateUnlockMapQuestInfo()
    local tInfo = self.tFameInfoList[self.nSelectIndex]

    for idx, tWidgetQuest in ipairs(self.tWidgetQuestButtonList) do
        local scriptWidgetQuest = UIHelper.GetBindScript(tWidgetQuest)

        local bVisible          = idx <= #tInfo.tQuestIDs and idx <= #tInfo.tMapIDs
        UIHelper.SetVisible(scriptWidgetQuest._rootNode, bVisible)

        if bVisible then
            local nMapId           = tonumber(tInfo.tMapIDs[idx])
            local nQuestId         = tonumber(tInfo.tQuestIDs[idx])
            local nChapterID   = tonumber(tInfo.tMainChapter[idx])

            local szMapName        = UIHelper.GBKToUTF8(Table_GetMapName(nMapId))

            local tQuestStringInfo = Table_GetQuestStringInfo(nQuestId)
            local szQuestName      = UIHelper.GBKToUTF8(tQuestStringInfo.szName)

            local szMapQuestName   = string.format("【%s】%s", szMapName, szQuestName)

            local bQuestDone       = g_pClientPlayer.GetQuestState(nQuestId) == QUEST_STATE.FINISHED

            UIHelper.SetString(scriptWidgetQuest.LableLeaveFor, szMapQuestName)
            UIHelper.SetVisible(scriptWidgetQuest.ImgDone, bQuestDone)

            UIHelper.BindUIEvent(scriptWidgetQuest.BtnLeaveFor, EventType.OnClick, function()
                UIMgr.Open(VIEW_ID.PanelSwordMemories, nChapterID)
            end)
        end
    end
end

return UIFameView