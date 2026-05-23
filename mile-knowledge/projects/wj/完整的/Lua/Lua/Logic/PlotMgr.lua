-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: PlotMgr
-- Date: 2022-11-23 22:56:19
-- Desc: 剧情数据管理
-- ---------------------------------------------------------------------------------
local _NpcCamera = {} --待处理的镜头
local m_bOpenNpcCamera, m_dwTargetID, m_dwCameraID
local ALLOWED_TIP_LIST = {
    EventType.ShowQuestComplete,
    EventType.ShowNormalTip,
    EventType.ShowImportantTip,
    EventType.ShowPlaceTip,
}

PLOT_TYPE = {
    OLD = 1, -- 老版对话面板
    NEW = 2, -- 新版对话面板
}
PLOT_DIALOGUE_ITEM_TYPE = {
    NORMAL_BUTTON = 1,
    SMALL_BUTTON_LIST = 2,
    TEXT = 3,
    NAME = 4,
    IMAGE = 5,
    ITEM = 6,
    SPACE = 7,--空格
    NEWLINE = 8, -- 换行
    SMALL_BUTTON = 9,
    ITEM_WITH_TEXT = 10,

    SELECT_COUNT = 1001,
}

PLOT_DIALOGUE_TYPE = {--情景对话时的对话类型
    IDLE = 1, ----闲置对话
    ACCEPT = 2, ----接受任务对话
    FINISH = 3, ----完成任务对话
    NONE = 4, ----没有进行对话
}

--这些任务提示信息需要关闭界面
local FORBID_QUEST_RESULT ={
    QUEST_RESULT.QUESTLIST_FULL,
    QUEST_RESULT.ERROR_QUEST_STATE,
    QUEST_RESULT.NOT_ENOUGH_FREE_ROOM,
    QUEST_RESULT.DAILY_QUEST_FULL,
    QUEST_RESULT.ERROR_CAMP,
    QUEST_RESULT.CHARGE_LIMIT,
    QUEST_RESULT.ERROR_REPUTE,
}

-- 老兑换框对应的按钮预设ID表
local OLD_DIALOGUE_SMALL_BUTTON =
{
    [9]=
    {
        ["PrefabID"]=4309,
        ["ButtonNum"]=9
    },
    [25]=
    {
        ["PrefabID"]=4307,
        ["ButtonNum"]=25
    },
    [30]=
    {
        ["PrefabID"]=4307,
        ["ButtonNum"]=30
    }
}



PlotMgr = PlotMgr or {className = "PlotMgr"}
local self = PlotMgr
-------------------------------- 消息定义 --------------------------------
PlotMgr.Event = {}
PlotMgr.Event.XXX = "PlotMgr.Msg.XXX"

self.tbOldDialogueDataList = {}
self.tbNewDialogueDataList = {}

self.tbMapName = {
    ["$"] = "dollar",
}

local function Reverse(tbData)
    local data = {}
    for nIndex = #tbData, 1, -1 do
        table.insert(data, tbData[nIndex])
    end
    return data
end

function PlotMgr.Init()
    self.tbTimerlist = {}
    self.tbTimerlist[PLOT_TYPE.NEW] = -1
    self.tbTimerlist[PLOT_TYPE.OLD] = -1

    Event.Reg(self, EventType.OnViewDestroy, function(nViewID)
        if nViewID == VIEW_ID.PanelOldDialogue or nViewID == VIEW_ID.PanelPlotDialogue or nViewID == VIEW_ID.PanelLuckyMeetingDialogue then
            PlotMgr.ShowMainLayer()
            -- PlotMgr.SelectNoTarget()
            PlotMgr.ShowTip()
        end
    end)

    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID == VIEW_ID.PanelOldDialogue or nViewID == VIEW_ID.PanelPlotDialogue or nViewID == VIEW_ID.PanelLuckyMeetingDialogue then
            PlotMgr.HideMainLayer()
            TipsHelper.OnlyShowTipList(ALLOWED_TIP_LIST)
        end
    end)

    Event.Reg(self, EventType.OnQuestRespond, function(nRespondCode)
        if table.contain_value(FORBID_QUEST_RESULT, nRespondCode) then
            self.ClosePanel(PLOT_TYPE.NEW)
            self.ClosePanel(PLOT_TYPE.OLD)
        end
    end)

    Event.Reg(self,"QUEST_ACCEPTED",function(nQuestIndex, dwQuestID)
        if not PlotMgr.IsInQuestList(dwQuestID) then return end

        local bHasNext = PlotMgr.GetNextQuestDialogue(self.dwTargetType, self.dwTargetID)
        if not bHasNext then
            Event.Dispatch(EventType.CloseDialoguePanel)
        end
    end)

    Event.Reg(self,"QUEST_FINISHED",function(dwQuestID)
        if not PlotMgr.IsInQuestList(dwQuestID) then return end
        local bHasNext = PlotMgr.GetSubsequenceQuestDialogue(self.dwTargetType, self.dwTargetID, dwQuestID)

        if not bHasNext then
            bHasNext = PlotMgr.GetNextQuestDialogue(self.dwTargetType, self.dwTargetID)
        end

        if not bHasNext then
            Event.Dispatch(EventType.CloseDialoguePanel)
        end
    end)

    Event.Reg(self,"SET_QUEST_STATE",function(dwQuestID, nQuestState)
        if nQuestState ~= 1 then return end

        if not PlotMgr.IsInQuestList(dwQuestID) then return end
        local bHasNext = PlotMgr.GetSubsequenceQuestDialogue(self.dwTargetType, self.dwTargetID, dwQuestID)

        if not bHasNext then
            bHasNext = PlotMgr.GetNextQuestDialogue(self.dwTargetType, self.dwTargetID)
        end

        if not bHasNext then
            Event.Dispatch(EventType.CloseDialoguePanel)
        end

    end)
end

function PlotMgr.UnInit()

end

function PlotMgr.OnLogin()

end

function PlotMgr.OnFirstLoadEnd()

end

function PlotMgr.InitData(nType, dwIndex, szText, dwTargetType, dwTargetID, dwCameraID)

    if self.nCurPanelType and nType ~= self.nCurPanelType then
        self.ClosePanel(self.nCurPanelType)
    end

    self.nCurPanelType = nType

    self.dwIndex = dwIndex
    self.szText = szText
    self.dwTargetType = dwTargetType
    self.dwTargetID = dwTargetID
    self.dwCameraID = dwCameraID

   self.tbQuestList = {}
   self.bPanelShouldOpen = true
   self.tbQiYuInfo = nil
   self.ExitAccpetQuestState()

end

function PlotMgr.OpenPanel(nType, dwIndex, szText, dwTargetType, dwTargetID, dwCameraID)

    if self.IsDelayClose(nType) then
        self.CanCelDelayClose(nType)--取消延迟关闭界面
    end

    local nViewID = self.GetViewIDByType(nType)
    local bClosing = UIMgr.IsViewCloseing(nViewID)
    local bPlayShowAnim = not (bClosing and nType == PLOT_TYPE.OLD)
    UIMgr.StopClose(nViewID)
    UIMgr.SetPlayShowAnim(bPlayShowAnim)

    self.InitData(nType, dwIndex, szText, dwTargetType, dwTargetID, dwCameraID)
    if nType == PLOT_TYPE.OLD then

        local tbOnDialogue = self._makeOneDialogueData(nType, dwIndex, szText, dwTargetType, dwTargetID, dwCameraID)
        self._push(tbOnDialogue, PLOT_TYPE.OLD)

        if not UIMgr.IsViewOpened(nViewID) and self.bPanelShouldOpen then
            UIMgr.Open(nViewID, dwTargetType, dwTargetID)
        end
        Event.Dispatch(EventType.OnPlotChanged)

    else

        local scriptView = UIMgr.GetViewScript(nViewID)
        if scriptView then
            scriptView:SetHasInitData(false)
        end

        local tbOnDialogue = self._makeOneDialogueData(nType, dwIndex, szText, dwTargetType, dwTargetID, dwCameraID)
        self._push(tbOnDialogue, PLOT_TYPE.NEW)

        if not scriptView and self.bPanelShouldOpen then
            UIMgr.Open(nViewID, dwIndex, szText, dwTargetType, dwTargetID, dwCameraID)
        elseif self.bPanelShouldOpen then
            scriptView:OnEnter(dwIndex, szText, dwTargetType, dwTargetID, dwCameraID)
        end
    end

    UIMgr.SetPlayShowAnim(true)

    if self.HasQiYuQuest() then--开启其余对话，不做后处理，后处理只针对新老界面做（流程有待改进，临时处理，防止移动不了）
        return
    else
        UIMgr.Close(VIEW_ID.PanelLuckyMeetingDialogue)
    end

    --教学 和NPC对话
    FireHelpEvent("OnDialogue", dwTargetType, dwTargetID)
end

function PlotMgr.GetViewIDByType(nType)
    if nType == PLOT_TYPE.OLD then
        return VIEW_ID.PanelOldDialogue
    else
        return VIEW_ID.PanelPlotDialogue
    end
end

function PlotMgr.ClosePanel(nType)
    if nType == PLOT_TYPE.OLD then
        self._clear(nType)
        self.ExitAccpetQuestState()
        UIMgr.Close(VIEW_ID.PanelOldDialogue)
    else
        self._clear(nType)
        UIMgr.Close(VIEW_ID.PanelPlotDialogue)
    end


end

function PlotMgr.IsInDialogue()
    local bOldDiaOpen = UIMgr.IsViewOpened(VIEW_ID.PanelOldDialogue)
    local bNewDiaOpen = UIMgr.IsViewOpened(VIEW_ID.PanelPlotDialogue)
    return bOldDiaOpen or bNewDiaOpen
end

function PlotMgr.Back(nType)
    if nType == PLOT_TYPE.OLD then
        PlotMgr._pop(nType)

        Event.Dispatch(EventType.OnPlotChanged)
    else
        PlotMgr._pop(nType)
    end
end

function PlotMgr.GetDialogueData(nType)
    if nType == PLOT_TYPE.OLD then
        local nLen = #self.tbOldDialogueDataList
        return self.tbOldDialogueDataList[nLen]
    else
        local nLen = #self.tbNewDialogueDataList
        return self.tbNewDialogueDataList[nLen]
    end
end

function PlotMgr.GetDialogueDataCount(nType)
    if nType == PLOT_TYPE.OLD then
        return #self.tbOldDialogueDataList
    else
        return #self.tbNewDialogueDataList
    end
end

function PlotMgr.EnterAccpetQuestState(nQuestID)
    self.nOldPanelAccpetQuest = nQuestID
    Event.Dispatch(EventType.OnPlotChanged)
end

function PlotMgr.ExitAccpetQuestState()
    self.nOldPanelAccpetQuest = nil
    Event.Dispatch(EventType.OnPlotChanged)
end

function PlotMgr.IsAccpetQuestState()
    return IsNumber(self.nOldPanelAccpetQuest) and self.nOldPanelAccpetQuest > 0
end

function PlotMgr.GetAccpetQuestID()
    return self.nOldPanelAccpetQuest
end


function PlotMgr.GetPrefabIDByItemType(tbData)
    local nPrefabID = nil
    local nItemType = tbData.nItemType
    if nItemType == PLOT_DIALOGUE_ITEM_TYPE.TEXT or nItemType == PLOT_DIALOGUE_ITEM_TYPE.NAME then
        nPrefabID = PREFAB_ID.WidgetOldDialogueContent1
    elseif nItemType == PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON then
        nPrefabID = PREFAB_ID.WidgetOldDialogueContent2
    elseif nItemType == PLOT_DIALOGUE_ITEM_TYPE.SMALL_BUTTON_LIST then
        local tbSmallButtonTab = OLD_DIALOGUE_SMALL_BUTTON[#tbData.tbSmallButtonList]
        nPrefabID = tbSmallButtonTab and tbSmallButtonTab.PrefabID or nil
    elseif nItemType == PLOT_DIALOGUE_ITEM_TYPE.IMAGE then
        nPrefabID = PREFAB_ID.WidgetOldDialogueContent4
    elseif nItemType == PLOT_DIALOGUE_ITEM_TYPE.ITEM then
        nPrefabID = PREFAB_ID.WidgetOldDialogueItemShell
    elseif nItemType == PLOT_DIALOGUE_ITEM_TYPE.ITEM_WITH_TEXT then
        nPrefabID = PREFAB_ID.WidgetOldDialogueContent12
    elseif nItemType == PLOT_DIALOGUE_ITEM_TYPE.SPACE then
        nPrefabID = PREFAB_ID.WidgetOldDialogueGapHorizontal
    elseif nItemType == PLOT_DIALOGUE_ITEM_TYPE.NEWLINE then
        nPrefabID = PREFAB_ID.WidgetOldDialogueGapVertical
    elseif nItemType == PLOT_DIALOGUE_ITEM_TYPE.SELECT_COUNT then
        nPrefabID = PREFAB_ID.WidgetOldDialogueContent9
    end

    return nPrefabID
end

--暂时这样写死，后面再看看
function PlotMgr.GetPrefabIDWidthByItemType(nPrefabID)
    local nWidth = 0
    if nPrefabID == PREFAB_ID.WidgetOldDialogueContent1 then
        nWidth = 608
    elseif nPrefabID == PREFAB_ID.WidgetOldDialogueContent8 then
        nWidth = 408
    elseif nPrefabID == PREFAB_ID.WidgetOldDialogueContent2 then
        nWidth = 608
    elseif nPrefabID == PREFAB_ID.WidgetOldDialogueItemShell then
        nWidth = 80
    elseif nPrefabID == PREFAB_ID.WidgetOldDialogueGapHorizontal then
        nWidth = 52
    elseif nPrefabID == PREFAB_ID.WidgetOldDialogueContent7 then
        nWidth = 500
    elseif nPrefabID == PREFAB_ID.WidgetOldDialogueContent12 then
        nWidth = 500
    end
    return nWidth
end

--老面板的元素是否需要一条横向的Layout去放
function PlotMgr.IsItemNeedLayout(nPrefabID)
    return nPrefabID == PREFAB_ID.WidgetOldDialogueContent1 or nPrefabID == PREFAB_ID.WidgetOldDialogueItemShell
    or nPrefabID == PREFAB_ID.WidgetOldDialogueGapHorizontal
end

function PlotMgr._push(tbOneDialogueData, nType)
    if nType == PLOT_TYPE.OLD then
        table.insert(self.tbOldDialogueDataList, tbOneDialogueData)
    else
        table.insert(self.tbNewDialogueDataList, tbOneDialogueData)
    end
end

function PlotMgr._pop(nType)
    if nType == PLOT_TYPE.OLD then
        table.remove(self.tbOldDialogueDataList)
    else
        table.remove(self.tbNewDialogueDataList)
    end
end

function PlotMgr._clear(nType)
    if nType == PLOT_TYPE.OLD then
        self.tbOldDialogueDataList = {}
    else
        self.tbNewDialogueDataList = {}
    end

end

-- 当收到一个OpenWindow时
function PlotMgr._makeOneDialogueData(nType, dwIndex, szText, dwTargetType, dwTargetID, dwCameraID)
    local tbOneDialogueData = {}
    tbOneDialogueData.nType = nType
    tbOneDialogueData.dwIndex = dwIndex
    tbOneDialogueData.szText = szText
    tbOneDialogueData.dwTargetType = dwTargetType
    tbOneDialogueData.dwTargetID = dwTargetID
    tbOneDialogueData.dwCameraID = dwCameraID

    tbOneDialogueData.tbData = {}
    tbOneDialogueData.tbData.szTitle = self._getTitle(dwTargetType, dwTargetID)
    tbOneDialogueData.tbData.tbItemDataList = self.GetItemDataList(nType, dwIndex, szText, dwTargetType, dwTargetID, true)

    return tbOneDialogueData
end

function PlotMgr._getTitle(dwTargetType, dwTargetID)
    return GBKToUTF8(TargetMgr.GetTargetName(dwTargetType, dwTargetID))
end

function PlotMgr.GetItemDataList(nType, dwIndex, szText, dwTargetType, dwTargetID, bCanCallAutoCallBack)
    local _, tbInfoList = GWTextEncoder_Encode(szText)

    return self.GetItemDataListByInfoList(nType, dwIndex, tbInfoList, dwTargetType, dwTargetID, bCanCallAutoCallBack)
end

function PlotMgr.GetItemDataListByInfoList(nType, dwIndex, tbInfoList, dwTargetType, dwTargetID, bCanCallAutoCallBack)

    self._initData(nType)
    for k, v in ipairs(tbInfoList or {}) do
        local szName = self.tbMapName[v.name] or v.name
        local szFuncName = string.format("_parse______%s", szName)
        if IsFunction(self[szFuncName]) then
            local tbOneItemData = self[szFuncName](nType, dwIndex, szText, dwTargetType, dwTargetID, v, tbInfoList)
            if tbOneItemData then
                table.insert(self.tbItemDataList, tbOneItemData)
            end
        end
    end

    self._eliminateUnnecessaryData(nType)
    if self.tbShopGroup then
        local tbOneItemData = self._parseShopGroup(nType, dwIndex, szText, dwTargetType, dwTargetID)
        table.insert(self.tbItemDataList, tbOneItemData)
    end

    if self.HasQiYuQuest() then--有奇遇对话，不走普通对话逻辑
        self.StartQuestQiYuDialogue(dwIndex, dwTargetType, dwTargetID)
        return
    end

    self._callAutoExecCallBack(bCanCallAutoCallBack and nType == PLOT_TYPE.NEW)

    Event.Dispatch(EventType.OnItemDataListReady, self.tbItemDataList, nType)


    return self.tbItemDataList
end

function PlotMgr.GetNextItemDataList()
    local tbItemDataList = self.tbItemDataList
    Event.Dispatch(EventType.OnItemDataListReady, tbItemDataList, PLOT_TYPE.NEW)
end

-- 解析文本 text
function PlotMgr._parse______text(nType, dwIndex, szText, dwTargetType, dwTargetID, tbInfo)
    if string.is_nil(tbInfo.context) then
        return nil
    end

    local tbContent = string.split(UIHelper.GBKToUTF8(tbInfo.context), "\n")
    for nIndex, szText in ipairs(tbContent) do
        if szText ~= "" then
            local tbData = self._pushText(nType, szText)
            table.insert(self.tbItemDataList, tbData)
        end
        if nIndex ~= #tbContent then
            local tbDataNewLine = self._getNewLine()
            table.insert(self.tbItemDataList, tbDataNewLine)
        end
    end

    return nil
end

-- 解析选项 $
function PlotMgr._parse______dollar(nType, dwIndex, szText, dwTargetType, dwTargetID, tbInfo)

    local tbData = {}
    tbData.nItemType = PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON
    tbData.tbInfo = tbInfo
    tbData.szContent = string.gsub(UIHelper.GBKToUTF8(tbInfo.context), "（%a+%+%a+）", "")
    if nType == PLOT_TYPE.OLD then
        tbData.szIconName = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
    end
    tbData.szDialogueIcon = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
    tbData.bClockDialogue = false   --按钮出现是否阻塞对话
    tbData.callback = function()
        if tbInfo.attribute.close then
            if nType == PLOT_TYPE.OLD then
                self.ClosePanel(nType)--防止浪客行点击下一关选择地图这种截屏会出现侧面板影子
            else
                self.DelayClose(nType)
            end
        end
        GetClientPlayer().WindowSelect(dwIndex, tbInfo.attribute.id)
    end

    if nType == PLOT_TYPE.NEW and tbData.szContent == "" then
        self.AddNextClickCallBack(tbData.callback)
        return nil
    end

    return tbData
end

-- 解析任务 Q
function PlotMgr._parse______Q(nType, dwIndex, szText, dwTargetType, dwTargetID, tbInfo)
    local nQuestID = tonumber(tbInfo.attribute.questid)

    -- if nType == PLOT_TYPE.OLD and (not QuestData.CanAcceptQuest(nQuestID, dwTargetType, dwTargetID) and not QuestData.CanFinishQuest(nQuestID, dwTargetType, dwTargetID)) then
    --     return nil
    -- end

    local tbQuestStringInfo = QuestData.GetQuestConfig(nQuestID)
    if not tbQuestStringInfo then return end

    local dwOperation = 0
    -- if nType == PLOT_TYPE.NEW then
    table.insert(self.tbQuestList, nQuestID)

    local szQuestState = ""
    local eQuestState, nLevel = QuestData.GetQuestStateAndLevel(nQuestID, dwTargetType, dwTargetID)
    if eQuestState ~= QUEST_STATE_NO_MARK and eQuestState ~= QUEST_STATE_WHITE_EXCLAMATION then
        if eQuestState == QUEST_STATE_YELLOW_QUESTION then
            dwOperation = 2
            szQuestState = "finished"
        elseif eQuestState == QUEST_STATE_BLUE_QUESTION then
            dwOperation = 2
            szQuestState = "finished"
        elseif eQuestState == QUEST_STATE_HIDE then
            dwOperation = 1
            szQuestState = "accpet"
        elseif eQuestState == QUEST_STATE_YELLOW_EXCLAMATION then
            dwOperation = 1
            szQuestState = "accpet"
        elseif eQuestState == QUEST_STATE_BLUE_EXCLAMATION then
            dwOperation = 1
            szQuestState = "accpet"
        elseif eQuestState == QUEST_STATE_WHITE_QUESTION then
            dwOperation = 2
            szQuestState = "finishing"
        elseif eQuestState == QUEST_STATE_DUN_DIA then
            dwOperation = 2
            szQuestState = "option"
        end

        if tbQuestStringInfo and tbQuestStringInfo.IsAdventure == 1 and nType == PLOT_TYPE.NEW then
            self.AddQiYuDialogueInfo(nil, tbQuestStringInfo, szQuestState)
            return nil
        end
    end

    if dwOperation == 0 then return nil end
    -- end

    local bCanFinishQuest = QuestData.CanFinishQuest(nQuestID, dwTargetType, dwTargetID)
    local bCanAcceptQuest = QuestData.CanAcceptQuest(nQuestID, dwTargetType, dwTargetID)

    local tbData = {}
    tbData.nItemType = PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON
    tbData.tbInfo = tbInfo
    tbData.bCanAccept = bCanAcceptQuest
    tbData.bCanFinish = bCanFinishQuest
    tbData.szContent = QuestData.GetQuestName(nQuestID)
    tbData.szIconName = self.GetDialogueQuestIcon(nQuestID, dwTargetType, dwTargetID)
    tbData.szDialogueIcon = self.GetDialogueQuestIcon(nQuestID, dwTargetType, dwTargetID)
    tbData.szIconBg =  bCanFinishQuest and "UIAtlas2_Public_PublicButton_PublicButton1_PublicButton_Erji_Tuijian.png"
    or "UIAtlas2_Public_PublicButton_PublicButton1_PublicButton_Erji.png"
    tbData.szDialogueIconBg = bCanFinishQuest and PLOT_ITEM_BG_IMG[1] or PLOT_ITEM_BG_IMG[2]
    tbData.bClockDialogue = true
    tbData.IsAdventure = tbQuestStringInfo.IsAdventure
    tbData.callback = self._getQuestCallBack(nType, nQuestID, dwTargetType, dwTargetID, dwOperation)
    tbData.nQuestID = nQuestID
    tbData.funcAwardPreview = function()
        --任务奖励预览
        Event.Dispatch(EventType.OnQuestAwardPreview, nQuestID)
    end
    return tbData
end

function PlotMgr._parse______L(nType, dwIndex, szText, dwTargetType, dwTargetID, tbInfo)
    local tbData = {}
    -- tbData.nDataType = PLOT_DATA_TYPE.MAIL
    tbData.nItemType = PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON
    tbData.tbInfo = tbInfo
    tbData.szContent = UIHelper.GBKToUTF8(tbInfo.context)
    if nType == PLOT_TYPE.OLD then
        tbData.szIconName = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
    end

    tbData.szDialogueIcon = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
    tbData.bClockDialogue = false
    tbData.callback = function()
        if not UIMgr.IsViewOpened(VIEW_ID.PanelEmail) then
            UIMgr.Open(VIEW_ID.PanelEmail, dwTargetID)
        end
    end
    return tbData
end

--1、新面板，如果此NPC有商店集了，则只将一个商店集加入进数组
function PlotMgr._parse______M(nType, dwIndex, szText, dwTargetType, dwTargetID, tbInfo)
    local tbData = {}
    -- tbData.nDataType = PLOT_DATA_TYPE.SHOP
    tbData.nItemType = PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON
    tbData.tbInfo = tbInfo
    tbData.szContent = UIHelper.GBKToUTF8(tbInfo.attribute.shopname)
    if nType == PLOT_TYPE.OLD then
        tbData.szIconName = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_merchant.png"
    end
    tbData.szDialogueIcon = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_merchant.png"
    tbData.bClockDialogue = false
    tbData.callback = function()
        if not UIMgr.IsViewOpened(VIEW_ID.PanelPlayStore) then
            UIMgr.Open(VIEW_ID.PanelPlayStore, tonumber(tbInfo.attribute.shopid), dwTargetID)
        end
        self.bPanelShouldOpen = false
        Timer.AddFrame(self, 1, function()
            self.ClosePanel(nType)
        end)
    end

    self._collectbShopGroupData(tbInfo, dwTargetID)

    if self.tbShopGroup then
        return nil --有商店集就不弹每个商店的button了
    end

    return tbData
end


-- 解析 CMD
function PlotMgr._parse______CMD(nType, dwIndex, szText, dwTargetType, dwTargetID, tbInfo, tbInfoList)
    local tbData = {}
    -- tbData.nDataType = PLOT_DATA_TYPE.CMD
    tbData.tbInfo = tbInfo
    tbData.szContent, tbData.szIconName, tbData.nItemType, tbData.callback, tbData.szDialogueIcon = self._parseCMDContent(dwIndex, tbInfo, nType, dwTargetID, tbInfoList)
    tbData.bClockDialogue = false
    if tbData.nItemType == PLOT_DIALOGUE_ITEM_TYPE.ITEM then--物品
        tbData.dwTabType = tonumber(tbInfo.attribute.attri1)
        tbData.dwTabIndex = tonumber(tbInfo.attribute.attri2)
        tbData.nCount = tonumber(tbInfo.attribute.attri3)
        tbData.nID = tonumber(tbInfo.attribute.paramid)
    end

    if tbData.nItemType == PLOT_DIALOGUE_ITEM_TYPE.ITEM_WITH_TEXT then
        tbData.dwTabType = tonumber(tbInfo.attribute.attri1)
        tbData.dwTabIndex = tonumber(tbInfo.attribute.attri2)
        tbData.nCount = tonumber(tbInfo.attribute.attri3)
        tbData.nBoxID = tonumber(tbInfo.attribute.paramid)
        tbData.nID = tonumber(tbInfo.attribute.attri5)
    end

    return tbData
end

function PlotMgr._parse______F(nType, dwIndex, szText, dwTargetType, dwTargetID, tbInfo)

    local color = UIDialogueColorTab[tonumber(tbInfo.attribute.fontid)]
    local text = UIHelper.GBKToUTF8(tbInfo.attribute.text)
    local szStart = ""
    local szEnd = ""
    if color then
        szStart = string.format("<color=%s>", color.Color)
        szEnd = "</color>"
        -- if nType == PLOT_TYPE.NEW then
        --     if tonumber(tbInfo.attribute.fontid) ~= 174 then
        --         szStart = ""
        --         szEnd = ""
        --     else
        --         szStart = "<color=#AED9E0>"
        --         szEnd = "</color>"
        --     end
        -- end
    else
        LOG.INFO("No Color In UIDialogueColorTab, Text: %s, FontID: %s", text, tbInfo.attribute.fontid)
    end

    local tbText = string.split(text, "\n")
    for nIndex, szText in ipairs(tbText) do
        if szText ~= "" then
            local tbData = self._pushText(nType, szText, {szStart = szStart, szEnd = szEnd})
            table.insert(self.tbItemDataList, tbData)
        end
        if nIndex ~= #tbText then
            local tbDataNewLine = self._getNewLine()
            table.insert(self.tbItemDataList, tbDataNewLine)
        end
    end

    return nil
end

function PlotMgr._parse______MT(nType, dwIndex, szText, dwTargetType, dwTargetID, tbInfo)
    local tbData = {}
    -- tbData.nDataType = PLOT_DATA_TYPE.FONT
    tbData.nItemType = PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON
    tbData.tbInfo = tbInfo
    tbData.szContent = UIHelper.GBKToUTF8(tbInfo.attribute.text)
    if nType == PLOT_TYPE.OLD then
        tbData.szIconName = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
    end
    tbData.szDialogueIcon = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
    tbData.bClockDialogue = false
    local nTrafficID = tonumber(tbInfo.attribute.trafficid)
    local nFinishCityID = tbInfo.attribute.trafficend and tonumber(tbInfo.attribute.trafficend)
    tbData.callback = function()
        MapMgr.OpenMiddleMapTraffic(nTrafficID, nFinishCityID, dwTargetID)
        PlotMgr.ClosePanel(nType)
    end
    return tbData
end

function PlotMgr._parse______T(nType, dwIndex, szText, dwTargetType, dwTargetID, tbInfo)

    if nType == PLOT_TYPE.NEW then
        return nil
    end
    local tbData = {}

    local tbConfig = Table_GetItemIconInfo(tonumber(tbInfo.attribute.picid))
    tbData.nItemType = (tbConfig and tbConfig.MobileBigImg) and PLOT_DIALOGUE_ITEM_TYPE.IMAGE or PLOT_DIALOGUE_ITEM_TYPE.SMALL_BUTTON
    tbData.tbInfo = tbInfo
    tbData.bSpace = tbInfo.attribute.picid == "Space"
    tbData.szContent = ""
    if nType == PLOT_TYPE.OLD then
        tbData.szIconName = UIHelper.GetIconPathByIconID(tonumber(tbInfo.attribute.picid))
        if not Lib.IsFileExist(tbData.szIconName) then
            LOG.INFO("can't find ImgPath: %s", tostring(tbData.szIconName))
        end
    end
    tbData.szDialogueIcon = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
    tbData.bClockDialogue = false
    tbData.nTipID = tonumber(tbInfo.attribute.tipid)

    tbData.callback = function()
        if tbInfo.attribute.paramid then
            GetClientPlayer().WindowSelect(dwIndex, tonumber(tbInfo.attribute.paramid))
        end
    end
    return tbData
end

---还缺tip
function PlotMgr._parse______W(nType, dwIndex, szText, dwTargetType, dwTargetID, tbInfo)

    local tbData = {}
    -- tbData.nDataType = PLOT_DATA_TYPE.FONT
    tbData.nItemType = PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON
    tbData.tbInfo = tbInfo
    tbData.szContent = UIHelper.GBKToUTF8(tbInfo.context)
    if nType == PLOT_TYPE.OLD then
        tbData.szIconName = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
    end
    tbData.szDialogueIcon = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
    tbData.bClockDialogue = false

    tbData.callback = function()
        if tbInfo.attribute.id then
            GetClientPlayer().WindowSelect(dwIndex, tonumber(tbInfo.attribute.id))
        end
    end
    return tbData
end

function PlotMgr._parse______N(nType, dwIndex, szText, dwTargetType, dwTargetID, tbInfo)
    local szName = ""
    local nID = tonumber(tbInfo.context)
    if nID then
        szName = UIHelper.GBKToUTF8(Table_GetNpcCallMe(nID))
    else
        szName = UIHelper.GBKToUTF8(GetClientPlayer().szName)
    end
    return self._pushText(nType, szName)
end

function PlotMgr._parse______C(nType, dwIndex, szText, dwTargetType, dwTargetID, tbInfo)
    return self._pushText(nType, g_tStrings.tRoleTypeToName[GetClientPlayer().nRoleType])
end

function PlotMgr._parse______B(nType, dwIndex, szText, dwTargetType, dwTargetID, tbInfo)

    local tbData = {}
    -- tbData.nDataType = PLOT_DATA_TYPE.FONT
    tbData.nItemType = PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON
    tbData.tbInfo = tbInfo
    tbData.szContent = UIHelper.GBKToUTF8(tbInfo.context)
    if nType == PLOT_TYPE.OLD then
        tbData.szIconName = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
    end
    tbData.szDialogueIcon = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
    tbData.bClockDialogue = false

    tbData.callback = function()
        PlotMgr.ClosePanel(nType)
        if dwTargetType == TARGET.NPC then
            Event.Dispatch("OPEN_BANK")
            -- GetClientPlayer().OpenBank(dwTargetID)
        end
    end
    return tbData

end


-- function PlotMgr._parse______FE(nType, dwIndex, szText, dwTargetType, dwTargetID, tbInfo)

--     if nType == PLOT_TYPE.NEW then
--         return nil
--     end
--     local tbData = {}
--     -- tbData.nDataType = PLOT_DATA_TYPE.FONT
--     tbData.nItemType = PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON
--     tbData.tbInfo = tbInfo
--     tbData.szContent = UIHelper.GBKToUTF8(tbInfo.context)
--     if nType == PLOT_TYPE.OLD then
--         tbData.szIconName = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_renwu_hui.png"
--     end
--     tbData.szDialogueIcon = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_renwu_hui.png"
--     tbData.bClockDialogue = false

--     tbData.callback = function()

--     end
--     return tbData

-- end

function PlotMgr._parse______GB(nType, dwIndex, szText, dwTargetType, dwTargetID, tbInfo)

    local tbData = {}
    -- tbData.nDataType = PLOT_DATA_TYPE.FONT
    tbData.nItemType = PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON
    tbData.tbInfo = tbInfo
    tbData.szContent = UIHelper.GBKToUTF8(tbInfo.context)
    if nType == PLOT_TYPE.OLD then
        tbData.szIconName = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_renwu_hui.png"
    end
    tbData.szDialogueIcon = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_renwu_hui.png"
    tbData.bClockDialogue = false

    tbData.callback = function()
        self.bPanelShouldOpen = false
        PlotMgr.ClosePanel(nType)

        local player = GetClientPlayer()
        if not player or player.dwTongID == 0 then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_GUILD_NOT_ACTIVE)
            return
        end

        if player.bFreeLimitFlag then
            return
        end

        UIMgr.OpenSingle(false,VIEW_ID.PanelHalfBag)
        UIMgr.Open(VIEW_ID.PanelHalfWarehouse,WareHouseType.Faction)
    end
    return tbData

end


function PlotMgr._parse______G(nType, dwIndex, szText, dwTargetType, dwTargetID, tbInfo)--4个英文空格
    -- local szSpace = g_tStrings.STR_TWO_CHINESE_SPACE
    -- if tbInfo.attribute.english then
    --     szSpace = "    "
    -- end
    local tbData = {}
    tbData.nItemType = PLOT_DIALOGUE_ITEM_TYPE.SPACE
    tbData.tbInfo = tbInfo
    tbData.szContent = ""
    return tbData
    -- return self._pushText(nType, "G", szSpace)
end


function PlotMgr._parse______J(nType, dwIndex, szText, dwTargetType, dwTargetID, tbInfo)
    --金钱
    local szSpace = g_tStrings.STR_TWO_CHINESE_SPACE
    if tbInfo.attribute.english then
        szSpace = "    "
    end
    return self._pushText(nType, szSpace)
end

function PlotMgr._parse______AT(nType, dwIndex, szText, dwTargetType, dwTargetID, tbInfo)
    --动作

    local player = g_pClientPlayer
    if dwTargetID and player then
        local bFace = false
        if tbInfo.attribute.face then
            bFace = true
        end
        Character_PlayAnimation(dwTargetID, player.dwID, tonumber(tbInfo.attribute.actionid), bFace)
    end
    return nil
end

function PlotMgr._parse______SD(nType, dwIndex, szText, dwTargetType, dwTargetID, tbInfo)
    --动作

    local player = g_pClientPlayer
    if dwTargetID and player then
        Character_PlaySound(dwTargetID, player.dwID, tbInfo.attribute.soundid, false)
    end
    return nil
end

function PlotMgr._parse______CP(nType, dwIndex, szText, dwTargetType, dwTargetID, tbInfo)

    local tbData = {}
    -- tbData.nDataType = PLOT_DATA_TYPE.FONT
    tbData.nItemType = PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON
    tbData.tbInfo = tbInfo
    tbData.szContent = UIHelper.GBKToUTF8(tbInfo.context)
    if nType == PLOT_TYPE.OLD then
        tbData.szIconName = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
    end
    tbData.szDialogueIcon = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
    tbData.bClockDialogue = false

    tbData.callback = function()
        PlotMgr.ClosePanel(nType)
        if dwTargetType == TARGET.NPC then
            UIMgr.OpenSingle(false, VIEW_ID.PanelHalfBag)
            UIMgr.Open(VIEW_ID.PanelHalfWarehouse, WareHouseType.Horse)
        end
    end
    return tbData
end

function PlotMgr._parseShopGroup(nType, dwIndex, szText, dwTargetType, dwTargetID)
    local tbData = {}
    -- tbData.nDataType = PLOT_DATA_TYPE.FONT
    tbData.nItemType = PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON
    local tbInfo = { ["name"] = "ShopGroup" }
    tbData.tbInfo = tbInfo--商店集没有Info
    tbData.szContent = UIHelper.GBKToUTF8(self.tbShopGroup.szName)
    if nType == PLOT_TYPE.OLD then
        tbData.szIconName = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_merchant.png"
    end
    tbData.szDialogueIcon = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_merchant.png"
    tbData.bClockDialogue = false
    tbData.callback = function()
        if not UIMgr.IsViewOpened(VIEW_ID.PanelPlayStore) then
            UIMgr.Open(VIEW_ID.PanelPlayStore, dwTargetID, self.tbShopGroup)
        end
        self.bPanelShouldOpen = false
        Timer.AddFrame(self, 1, function()
            self.ClosePanel(nType)
        end)
    end

    return tbData
end

function PlotMgr._parse______Y(nType, dwIndex, szText, dwTargetType, dwTargetID, tbInfo)

    local tbData = {}
    -- tbData.nDataType = PLOT_DATA_TYPE.FONT
    tbData.nItemType = PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON
    tbData.tbInfo = tbInfo
    tbData.szContent = UIHelper.GBKToUTF8(tbInfo.context)
    if nType == PLOT_TYPE.OLD then
        tbData.szIconName = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
    end
    tbData.szDialogueIcon = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
    tbData.bClockDialogue = false

    tbData.callback = function()
        PlotMgr.ClosePanel(nType)
        TradingData.InitTradingHouse(dwTargetType, dwTargetID)
    end
    return tbData
end

function PlotMgr._parse______U(nType, dwIndex, szText, dwTargetType, dwTargetID, tbInfo)

    local tbData = {}
    -- tbData.nDataType = PLOT_DATA_TYPE.FONT
    tbData.nItemType = PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON
    tbData.tbInfo = tbInfo
    tbData.szContent = UIHelper.GBKToUTF8(tbInfo.attribute.text)
    if nType == PLOT_TYPE.OLD then
        tbData.szIconName = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
    end
    tbData.szDialogueIcon = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
    tbData.bClockDialogue = false

    local nTrafficID = tonumber(tbInfo.attribute.pointid)

    tbData.callback = function()
        PlotMgr.ClosePanel(nType)
        UIMgr.Open(VIEW_ID.PanelWorldMap, { bTraffic = true, nTrafficID = nTrafficID })
    end
    return tbData
end

function PlotMgr._parseCMDContent(dwIndex, tbInfo, nType, dwTargetID, tbInfoList)
    local szType = tbInfo.attribute.attri0
    local szText = ""
    local szIconPath = ""
    local nItemType = PLOT_DIALOGUE_ITEM_TYPE.NAME
    local szDialogueIcon = ""
    local funcCallBack = function()

    end
    if szType == "LOCK_PANEL" then
        --解锁开关
        szText = g_tStrings.STR_LOCK_PANEL_CONTEXT
    elseif szType == "NPC_GUIDE" then
        szText = UIHelper.GBKToUTF8(tbInfo.attribute.attri3)
    elseif szType == "CHANGE_COIN_TO_TIME" then
        szText = UIHelper.GBKToUTF8(tbInfo.attribute.attri1)
        szIconPath = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
        szDialogueIcon = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
        nItemType = PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON
        funcCallBack = function()
            if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.COIN, "COIN") then
                return
            end

            UIMgr.Open(VIEW_ID.PanelConvertPop)
        end
    elseif szType == "ARENA_QUEUE" then
        --JJC排队
        szText = UIHelper.GBKToUTF8(tbInfo.attribute.attri1)
    elseif szType == "NewDialog" then
        szText = "告辞"
        szIconPath = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
        szDialogueIcon = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
        nItemType = PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON
        funcCallBack = function()
            self.ClosePanel(PLOT_TYPE.NEW)
        end
        self.AddQiYuDialogueInfo(tbInfoList, nil, nil)
    elseif szType == "SHARED_PACKAGE" then
        szText = UIHelper.GBKToUTF8(tbInfo.attribute.attri1)
        szIconPath = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
        szDialogueIcon = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
        nItemType = PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON
        funcCallBack = function()
            self.ClosePanel(PLOT_TYPE.OLD)
            UIMgr.OpenSingle(false,VIEW_ID.PanelHalfBag)
            UIMgr.Open(VIEW_ID.PanelHalfWarehouse,WareHouseType.Account)
            --self.DelayClose(PLOT_TYPE.OLD)
        end
    elseif szType == "ITEM_BOX" then
        szText = "ITEM_BOX"
        szIconPath = ""
        nItemType = PLOT_DIALOGUE_ITEM_TYPE.ITEM
        funcCallBack = function(bSelect)
            if tbInfo.attribute.paramid then
                self.DelayClose(nType)
                GetClientPlayer().WindowSelect(tonumber(dwIndex), tonumber(tbInfo.attribute.paramid))
            end
        end
    elseif szType == "ITEM_BOX_SHOW_COUNT" then
        szText = "ITEM_BOX_SHOW_COUNT"
        szIconPath = ""
        nItemType = PLOT_DIALOGUE_ITEM_TYPE.ITEM
        funcCallBack = function(bSelect)
            if tbInfo.attribute.paramid then
                self.DelayClose(nType)
                GetClientPlayer().WindowSelect(tonumber(dwIndex), tonumber(tbInfo.attribute.paramid))
            end
        end
    elseif szType == "ITEM_BOX_SELECTION" then
        szText = UIHelper.GBKToUTF8(tbInfo.attribute.attri4)
        nItemType = PLOT_DIALOGUE_ITEM_TYPE.ITEM_WITH_TEXT
        funcCallBack = function(bSelect)
            if tbInfo.attribute.paramid then
                if tbInfo.attribute.close then
                    self.DelayClose(nType)
                end
                GetClientPlayer().WindowSelect(tonumber(dwIndex), tonumber(tbInfo.attribute.paramid))
            end
        end
    elseif szType == "NPC_NAME" then
        szText = UIHelper.GBKToUTF8(tbInfo.attribute.attri1)
        szIconPath = QuestDialogueNameBGColor["NPC_NAME"]
        nItemType = PLOT_DIALOGUE_ITEM_TYPE.NAME
    elseif szType == "PLAYER_NAME" then
        szText = UIHelper.GBKToUTF8(PlayerData.GetPlayerName())
        szIconPath = QuestDialogueNameBGColor["PLAYER_NAME"]
        nItemType = PLOT_DIALOGUE_ITEM_TYPE.NAME
    elseif szType == "LINK" then
        szText = UIHelper.GBKToUTF8(tbInfo.attribute.attri1)
        nItemType = PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON
        szIconPath = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
        szDialogueIcon = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
        funcCallBack = function()
            local szLinkInfo = UIHelper.GBKToUTF8(tbInfo.attribute.attri2)
            FireUIEvent("EVENT_LINK_NOTIFY", szLinkInfo)
            self.ClosePanel(nType)
        end
    elseif szType == "PIC_BTN" then
        local nBtnID = tonumber(tbInfo.attribute.attri2)
        local tLine = Table_GetDialogBtn(nBtnID)
        szIconPath = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
        szDialogueIcon = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"
        nItemType = PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON
        szText = string.format("<img src='%s' align='center' width='272' height='68'/>", DialogueBtnTitleImg[tLine.szTitlePath])
        funcCallBack = function()
            GetClientPlayer().WindowSelect(dwIndex, tbInfo.attribute.attri1)
            self.DelayClose(nType)
        end
    elseif szType == "NEXT_PAGE" then

    end
    return szText, szIconPath, nItemType, funcCallBack, szDialogueIcon
end

function PlotMgr._pushText(nType, szText, tbTag)
    local tbData = {}
    tbData.nItemType = PLOT_DIALOGUE_ITEM_TYPE.TEXT
    tbData.szContent = ParseTextHelper.DeleteOperationDesc(szText)
    -- tbData.szContent = ParseTextHelper.ParseOldDialogueText(tbData.szContent)
    tbData.tbTag = tbTag
    if nType == PLOT_TYPE.NEW and tbTag then
        tbData.szContent = tbTag.szStart .. tbData.szContent .. tbTag.szEnd
    end
    if tbData.szContent ~= "" then
        return tbData
    else
        return nil
    end
end

function PlotMgr._getNewLine()
    local tbData = {}
    tbData.nItemType = PLOT_DIALOGUE_ITEM_TYPE.NEWLINE
    return tbData
end

--旧对话框面板提出并调整一些不必要的元素，①、合并字符串规则：将中间没有其它元素连续的几个Text文本合成一个；②、剔除两个button之间的换行
function PlotMgr._getFirstItemTypePos(nItemType)
    for index, tbData in ipairs(self.tbItemDataList) do
        if tbData.nItemType == nItemType then return index end
    end
    return 0
end

function PlotMgr._getLastItemTypePos(nItemType)
    for nIndex = #self.tbItemDataList, 1, -1 do
        local tbData = self.tbItemDataList[nIndex]
        if tbData.nItemType == nItemType then return nIndex end
    end
    return 0
end

function PlotMgr._eliminateUnnecessaryData(nType)
    if nType == PLOT_TYPE.OLD then
        local szText = ""
        local nItemCount = self.GetItemTypeCount(PLOT_DIALOGUE_ITEM_TYPE.SMALL_BUTTON)
        local bToItem = OLD_DIALOGUE_SMALL_BUTTON[nItemCount] == nil -- 没有对应数量的配置，将SMALL_BUTTON转换成item类型

        for nIndex = #self.tbItemDataList, 1, -1  do
            local tbData = self.tbItemDataList[nIndex]

            if tbData.nItemType == PLOT_DIALOGUE_ITEM_TYPE.TEXT and tbData.szContent == "选择制作：" then
                local tbNewData = {
                    nItemType = PLOT_DIALOGUE_ITEM_TYPE.SELECT_COUNT,
                    tbInfo = {},
                }

                for i = nIndex + 4, nIndex, -1 do
                    table.insert(tbNewData.tbInfo, 1, self.tbItemDataList[i])
                    table.remove(self.tbItemDataList, i)
                end

                table.insert(self.tbItemDataList, nIndex, tbNewData)


            elseif tbData.nItemType == PLOT_DIALOGUE_ITEM_TYPE.TEXT then--调整文本
                if  tbData.szContent ~= "\n\n" then

                else--文本只有两个换行符，直接干掉
                    table.remove(self.tbItemDataList, nIndex)
                end

            elseif tbData.nItemType == PLOT_DIALOGUE_ITEM_TYPE.SMALL_BUTTON and not tbData.bSpace and bToItem then--调整五子棋之类的按钮
                tbData.nItemType = PLOT_DIALOGUE_ITEM_TYPE.ITEM
            elseif tbData.bSpace and tbData.nItemType == PLOT_DIALOGUE_ITEM_TYPE.SMALL_BUTTON then
                tbData.nItemType = PLOT_DIALOGUE_ITEM_TYPE.SPACE
            end
        end

        if not bToItem then
            self.CreateSmallButtonList()
        end

        --NORMAL_BUTTON之间没有换行符
        local nButtonStart = self._getFirstItemTypePos(PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON)
        local nButtonEnd = self._getLastItemTypePos(PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON)
        for nIndex = nButtonEnd, nButtonStart, - 1 do
            local tbData = self.tbItemDataList[nIndex]
            if tbData and tbData.nItemType == PLOT_DIALOGUE_ITEM_TYPE.NEWLINE then
                table.remove(self.tbItemDataList, nIndex)
            end
        end
    else
        --合并对话
        local szText = ""
        for nIndex = #self.tbItemDataList, 1, -1  do
            local tbData = self.tbItemDataList[nIndex]
            if tbData.nItemType == PLOT_DIALOGUE_ITEM_TYPE.TEXT then
                szText = tbData.szContent..szText
                table.remove(self.tbItemDataList, nIndex)
            end
        end
        local tbData = {}
        tbData.nItemType = PLOT_DIALOGUE_ITEM_TYPE.TEXT
        tbData.szContent = szText
        tbData.szContent = string.gsub(tbData.szContent, "[%s]+$", "")
        table.insert(self.tbItemDataList, 1, tbData)
    end
end

function PlotMgr.CreateSmallButtonList()
    local nStartIndex = nil
    for nIndex = #self.tbItemDataList, 1, -1 do
        local tbData = self.tbItemDataList[nIndex]
        local nItemType = tbData.nItemType
        if nItemType == PLOT_DIALOGUE_ITEM_TYPE.SMALL_BUTTON then
            table.insert(self.tbSmallButtonList, tbData)
            table.remove(self.tbItemDataList, nIndex)
            nStartIndex = nIndex
        end
    end

    self.tbSmallButtonList = Reverse(self.tbSmallButtonList)
    local tbData = {}
    tbData.nItemType = PLOT_DIALOGUE_ITEM_TYPE.SMALL_BUTTON_LIST
    tbData.tbSmallButtonList = self.tbSmallButtonList
    table.insert(self.tbItemDataList, nStartIndex, tbData)
end


function PlotMgr._collectbShopGroupData(tbInfo, dwTargetID)
    if not self.tbShopGroup or not self.tShopMap then
        local npc = GetNpc(dwTargetID)
        self.tbShopGroup, self.tShopMap = Table_GetShopGroup(npc.dwTemplateID)
    end

    local nShopID = tonumber(tbInfo.attribute.shopid)
    local nShopTemplateID = tonumber(tbInfo.attribute.shoptemplateid)

    if self.tShopMap and self.tShopMap[nShopTemplateID] then
        local tShop = self.tShopMap[nShopTemplateID]
        tShop.bShow = true
        tShop.szShopName = tbInfo.attribute.shopname
        tShop.nShopID = nShopID
    end
end

function PlotMgr._getQuestCallBack(nType, nQuestID, dwTargetType, dwTargetID, dwOperation)
    local callback = function()
    end
    if nType == PLOT_TYPE.OLD then
        callback = function()
            PlotMgr.EnterAccpetQuestState(nQuestID)
        end
    else
        callback = function()
            local func = function()
                local tbQuestRpg, bAccepted = Table_GetQuestRpg(nQuestID, dwTargetType, dwTargetID, dwOperation)
                Event.Dispatch(EventType.OnStartNewQuestDialogue, nQuestID, tbQuestRpg, dwOperation)
            end

            if not self.CanDispatchDialogueEvent() then
                table.insert(self.tbOnDialogueOpenFunc, func)
            else
                func()
            end
        end
    end
    return callback
end


function PlotMgr.GetItemTypeCount(nItemType)
    local nItemTypeNum = 0
    for nIndex, tbData in ipairs(self.tbItemDataList) do
        if tbData.nItemType == nItemType then
            nItemTypeNum = nItemTypeNum + 1
        end
    end
    return nItemTypeNum
end

function PlotMgr.AddNextClickCallBack(callback)
    table.insert(self.tbNextClickCallBack, callback)
end

function PlotMgr.GetNextClickCallBackCount()
    return #self.tbNextClickCallBack
end

function PlotMgr.CallNextClickCallBack()
    for index, callback in ipairs(self.tbNextClickCallBack) do
        callback()
    end
    -- self.tbNextClickCallBack = {}
end

function PlotMgr._callAutoExecCallBack(bCanCallAutoCallBack)
    if bCanCallAutoCallBack then
        local nButtonNum = self.GetItemTypeCount(PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON)
        local tbRemoveList = {}
        if nButtonNum == 1 then
            for index, tbData in ipairs(self.tbItemDataList) do
                if tbData.tbInfo and (tbData.tbInfo.name == "M" or tbData.tbInfo.name == "ShopGroup" or (tbData.tbInfo.name == "Q" and tbData.tbInfo.IsAdventure ~= 1)
                or tbData.tbInfo.name == "GB") then
                    tbData.callback()
                    table.insert(tbRemoveList, index)
                end
            end
            for index = #tbRemoveList, 1, -1 do
                table.remove(self.tbItemDataList, tbRemoveList[index])
            end
        end
    end
end

function PlotMgr._initData(nType)
    self.tbItemDataList = {}
    self.tbShopGroup = nil
    self.tShopMap = nil
    self.tbNextClickCallBack = {}
    self.tbSmallButtonList = {}
    self.tbOnDialogueOpenFunc = {}
    if nType ==  PLOT_TYPE.NEW then
        self.szText = ""
    else
        self.szText = nil
    end
end

function PlotMgr.GetDialogueQuestIcon(nQuestID, dwTargetType, dwTargetID)
    local bCanFinishQuest = QuestData.CanFinishQuest(nQuestID, dwTargetType, dwTargetID)
    local bCanAcceptQuest = QuestData.CanAcceptQuest(nQuestID, dwTargetType, dwTargetID)

    if bCanFinishQuest then
        return DialogueQuestIcon[2][QuestType.Activity]
    elseif bCanAcceptQuest then
        return DialogueQuestIcon[1][QuestType.Activity]
    else
        return DialogueQuestIcon[3][QuestData.GetQuestNewType(nQuestID)]
    end
end

function PlotMgr.CallOnDialogueOpenFunc()
    for index, callback in ipairs(self.tbOnDialogueOpenFunc) do
        callback()
    end
    self.tbOnDialogueOpenFunc = {}
end

function PlotMgr.IsInQuestList(nQuestID)
    if not self.tbQuestList then return false end
    return table.contain_value(self.tbQuestList, nQuestID)
end

function PlotMgr.GetSubsequenceQiYuQuestDialogue(dwTargetType, dwTargetID, nQuestID)
    local questInfo = GetQuestInfo(nQuestID)
    if questInfo then
        if questInfo.dwSubsequenceID ~= 0  then
            local hPlayer = g_pClientPlayer
            local nCanAccept = hPlayer.CanAcceptQuest(questInfo.dwSubsequenceID, dwTargetType, dwTargetId)
            if nCanAccept == QUEST_RESULT.SUCCESS then
                Event.Dispatch(EventType.OnStartQiYuDialogue, nil, self.tbQiYuInfo.tbQuestStringInfo, "finished")
                return true
            end
        end
    end
    return false
end

function PlotMgr.GetSubsequenceQuestDialogue(dwTargetType, dwTargetID, nQuestID)
    local questInfo = GetQuestInfo(nQuestID)
    if questInfo then
        if questInfo.dwSubsequenceID ~= 0  then
            local pPlayer = g_pClientPlayer
            local eCanAccept = pPlayer.CanAcceptQuest(questInfo.dwSubsequenceID, dwTargetType, dwTargetID)
            if eCanAccept == QUEST_RESULT.SUCCESS then
                local tbQuestRpg, bAccepted = Table_GetQuestRpg(dwQuestID, dwTargetType, dwTargetID, 1)
                Event.Dispatch(EventType.OnStartNewQuestDialogue, questInfo.dwSubsequenceID, tbQuestRpg, 1)
                return true
            end
        end
    end
    return false
end

function PlotMgr.GetNextQiYuQuestDialogue(dwTargetType, dwTargetID, tbQuestList)
	local hPlayer = g_pClientPlayer
	for _, dwQuestId in pairs(tbQuestList) do
		local tbQuestStringInfo = Table_GetQuestStringInfo(dwQuestId)
		local nState = hPlayer.CanFinishQuest(dwQuestId, dwTargetType, dwTargetID)
		if tbQuestStringInfo.IsAdventure == 1 and nState == QUEST_RESULT.SUCCESS then
			Event.Dispatch(EventType.OnStartQiYuDialogue, nil, tbQuestStringInfo, "finished")
			return true
		end

		local nState = hPlayer.CanAcceptQuest(dwQuestId, dwTargetType, dwTargetID)
		if tbQuestStringInfo.IsAdventure == 1 and nState == QUEST_RESULT.SUCCESS then
			Event.Dispatch(EventType.OnStartQiYuDialogue, nil, tbQuestStringInfo, "accpet")
			return true
		end
	end
    return false
end

function PlotMgr.GetNextQuestDialogue(dwTargetType, dwTargetID)
    local pPlayer = g_pClientPlayer
    if (not pPlayer) or (not self.tbQuestList) then return false end
	for i, dwQuestID in ipairs(self.tbQuestList) do
		local nState = pPlayer.CanFinishQuest(dwQuestID, dwTargetType, dwTargetID)
		if nState == QUEST_RESULT.SUCCESS  then
            local tbQuestRpg, bAccepted = Table_GetQuestRpg(dwQuestID, dwTargetType, dwTargetID, 2)
			Event.Dispatch(EventType.OnStartNewQuestDialogue, dwQuestID, tbQuestRpg, 2)
			return true
		end

		nState = pPlayer.CanAcceptQuest(dwQuestID, dwTargetType, dwTargetID)
		if nState == QUEST_RESULT.SUCCESS then
            local tbQuestRpg, bAccepted = Table_GetQuestRpg(dwQuestID, dwTargetType, dwTargetID, 1)
			Event.Dispatch(EventType.OnStartNewQuestDialogue, dwQuestID, tbQuestRpg, 1)
			return true
		end
	end
end

function PlotMgr.CanCelDelayClose(nType)
    Timer.DelTimer(self, self.tbTimerlist[nType])
    self.tbTimerlist[nType] = -1
end

function PlotMgr.IsDelayClose(nType)
    return self.tbTimerlist[nType] ~= -1
end

function PlotMgr.DelayClose(nType)
    if self.IsDelayClose(nType) then self.CanCelDelayClose(nType) end
    local nEntryID = Timer.Add(self, 0.5, function()
        self.ClosePanel(nType)
        self.tbTimerlist[nType] = -1
    end)
    self.tbTimerlist[nType] = nEntryID
end

function PlotMgr.IsOpen()
    return UIMgr.IsViewOpened(VIEW_ID.PanelPlotDialogue) or UIMgr.IsViewOpened(VIEW_ID.PanelOldDialogue) or UIMgr.IsViewVisible(VIEW_ID.PanelLuckyMeetingDialogue)
end

function PlotMgr.ShowMainLayer()
    if not UIMgr.IsViewVisible(VIEW_ID.PanelOldDialogue) and not UIMgr.IsViewVisible(VIEW_ID.PanelPlotDialogue) and not UIMgr.IsViewVisible(VIEW_ID.PanelLuckyMeetingDialogue) then
        --情景对话的两个面板(新老面版)都消失了则显示主界面，否则会出现如老界面关闭但新界面打开时，主界面一同出现
        UIMgr.ShowLayer(UILayer.Main, {VIEW_ID.PanelHint, VIEW_ID.PanelMainCityInteractive})
    end
    UIHelper.ShowInteract()
end

function PlotMgr.ShowTip()
    if not UIMgr.IsViewVisible(VIEW_ID.PanelOldDialogue) and not UIMgr.IsViewVisible(VIEW_ID.PanelPlotDialogue) and not UIMgr.IsViewVisible(VIEW_ID.PanelLuckyMeetingDialogue) then
        --情景对话的两个面板(新老面版)都消失了则显示主界面，否则会出现如老界面关闭但新界面打开时，主界面一同出现
        TipsHelper.ShowAllTip()
    end
end

function PlotMgr.SelectNoTarget()
    if not UIMgr.IsViewVisible(VIEW_ID.PanelOldDialogue) and not UIMgr.IsViewVisible(VIEW_ID.PanelPlotDialogue) and not UIMgr.IsViewVisible(VIEW_ID.PanelLuckyMeetingDialogue) then
        TargetMgr.doSelectTarget(0, TARGET.NO_TARGET)
    end
end

function PlotMgr.HideMainLayer()
    UIMgr.HideLayer(UILayer.Main, {VIEW_ID.PanelHint, VIEW_ID.PanelMainCityInteractive})
    UIHelper.HideInteract()--逻辑有冲突，防止UIMutexMgr里侧面板关闭直接打开交互列表
end



function PlotMgr.AddQiYuDialogueInfo(tbInfo, tbQuestStringInfo, szQuestState)
    self.tbQiYuInfo = {}
    self.tbQiYuInfo.tbInfo = tbInfo
    self.tbQiYuInfo.tbQuestStringInfo = tbQuestStringInfo
    self.tbQiYuInfo.szQuestState = szQuestState
end

function PlotMgr.HasQiYuQuest()
    return self.tbQiYuInfo ~= nil
end

function PlotMgr.CanDispatchDialogueEvent()
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelPlotDialogue)
    if not scriptView then
        return false
    end
    return scriptView:GetHasInitData()
end

function PlotMgr.StartQuestQiYuDialogue(dwIndex, dwTargetType, dwTargetID)


    self.bPanelShouldOpen = false
    self.ClosePanel(self.nCurPanelType)

    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelLuckyMeetingDialogue)
    if scriptView then
        scriptView:OnEnter(dwIndex, dwTargetType, dwTargetID, self.tbQiYuInfo.tbInfo, self.tbQiYuInfo.tbQuestStringInfo, self.tbQiYuInfo.szQuestState)
    else
        UIMgr.Open(VIEW_ID.PanelLuckyMeetingDialogue, dwIndex, dwTargetType, dwTargetID, self.tbQiYuInfo.tbInfo, self.tbQiYuInfo.tbQuestStringInfo, self.tbQiYuInfo.szQuestState)
    end

end



function PlotMgr.GetQiYuDialogueList(bQuest, tbInfoList, tbQuestStringInfo, szQuestState, dwTargetType, dwTargetID, dwIndex)
    local tbDialogueList = {}
    tbDialogueList.tbTextList = {}
    tbDialogueList.tbButtList = {}

    local nCount = #tbInfoList
    if bQuest then
        local szText = ""
        for i = 1, nCount, 1 do
            local v = tbInfoList[i]
            if v.name == "text" then --普通文本
                table.insert(tbDialogueList.tbTextList, szText)
                szText = ""
            elseif v.name == "F" then	--字体
                local tbColor = UIDialogueColorTab[tonumber(v.attribute.fontid)]
                if tbColor then
                    szText = szText..string.format("<color=%s>", tbColor.Color)..UIHelper.GBKToUTF8(v.attribute.text).."</color>"
                else
                    szText = szText..UIHelper.GBKToUTF8(v.attribute.text)
                end
            -- elseif v.name == "H" then	--控制行高，如果高度大于当前行高，调整为这个高度，否则，不变
            --     szText = szText.."<null>h="..v.attribute.height.."</null>"
            elseif v.name == "G" then	--4个英文空格
                local szSpace = g_tStrings.STR_TWO_CHINESE_SPACE
                if v.attribute.english then
                    szSpace = "    "
                end
                szText = szText..szSpace
            end
        end

        if szQuestState == "finished" then
            local tbButtonInfo = {}
            tbButtonInfo.callback = function()
                QuestData.FinishQuest(tbQuestStringInfo.nID, dwTargetType, dwTargetID, 0, 0)
            end
            tbButtonInfo.szContent = UIHelper.GBKToUTF8(tbQuestStringInfo.szFinishDes)
            tbButtonInfo.szDialogueIcon = self.GetDialogueQuestIcon(tbQuestStringInfo.nID, dwTargetType, dwTargetID)
            table.insert(tbDialogueList.tbButtList, tbButtonInfo)
        elseif szQuestState == "accpet" then
            local tbButtonInfo = {}
            tbButtonInfo.callback = function()
                QuestData.AcceptQuest(dwTargetType, dwTargetID, tbQuestStringInfo.nID)
                UIMgr.Close(VIEW_ID.PanelLuckyMeetingDialogue)
            end
            tbButtonInfo.szContent = UIHelper.GBKToUTF8(tbQuestStringInfo.szAcceptDes)
            tbButtonInfo.szDialogueIcon = self.GetDialogueQuestIcon(tbQuestStringInfo.nID, dwTargetType, dwTargetID)
            table.insert(tbDialogueList.tbButtList, tbButtonInfo)
        end




    else
        for i = 1, nCount, 1 do
            local v = tbInfoList[i]
            local tbInfo = {}
            if v.name == "text" then --普通文本
                table.insert(tbDialogueList.tbTextList, UIHelper.GBKToUTF8(v.context))
            elseif v.name == "$" then --选项

                local tbButtonInfo = {}
                tbButtonInfo.callback = function()
                    if v.attribute.close then
                        local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelLuckyMeetingDialogue)
                        scriptView:DelayClose()
                    end
                    GetClientPlayer().WindowSelect(dwIndex, tonumber(v.attribute.id))
                end
                tbButtonInfo.szContent = string.gsub(UIHelper.GBKToUTF8(v.context), "（%a+%+%a+）", "")
                tbButtonInfo.szDialogueIcon = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_Dialogue.png"

                table.insert(tbDialogueList.tbButtList, tbButtonInfo)
            end
        end
    end

    return tbDialogueList
end

-----------------------------对话镜头------------------
local function OpenCamera(dwTargetID, dwCameraID)
    rlcmd(string.format("dialogue with npc 1 %d %d", dwTargetID, dwCameraID))
    m_bOpenNpcCamera    = true
    m_dwTargetID        = dwTargetID
    m_dwCameraID        = dwCameraID
end

local function CloseCamera()
    rlcmd("dialogue with npc 0")
    m_bOpenNpcCamera    = false
    m_dwTargetID        = nil
    m_dwCameraID        = nil
end

function PlotMgr.NpcCamera_Open(dwTargetType, dwTargetID, dwCameraID)
    if dwTargetType ~= TARGET.NPC then
        CloseCamera()
        return
    end

    if not m_dwTargetID then
        OpenCamera(dwTargetID, dwCameraID)
        return
    end

    if dwTargetID ~= m_dwTargetID then
        CloseCamera()
        OpenCamera(dwTargetID, dwCameraID)
        return
    end
end

function PlotMgr.NpcCamera_Close(dwTargetType)
    if dwTargetType ~= TARGET.NPC then
        return
    end

    if m_bOpenNpcCamera then
        CloseCamera()
        return
    end
end