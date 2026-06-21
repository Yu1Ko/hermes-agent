-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIQuestView
-- Date: 2022-11-14 14:58:20
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIQuestView = class("UIQuestView")

function UIQuestView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitData()
    self:UpdateInfo()


    if self.nInitQuestListTime then
        Timer.DelTimer(self, self.nInitQuestListTime)
    end
    self.nInitQuestListTime = Timer.AddFrame(self, 5, function()
        self:UpdateScrollViewQuest()
    end)

    UIHelper.SetClickInterval(self.Btn01, 1)
end

function UIQuestView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIQuestView:OnShow()
    self:UpdateScrollViewQuest()
end

function UIQuestView:OnVisible()

end


function UIQuestView:BindUIEvent()
    for nIndex, tbTogTabList in ipairs(self.tbLayoutTabList) do
        UIHelper.BindUIEvent(tbTogTabList, EventType.OnClick, function()
            self:SetCheckedTogTabList(nIndex)
        end)
    end

    UIHelper.BindUIEvent(self.Btn01, EventType.OnClick, function()
        if self.tbQuestInfo then
            local szContent = string.format(g_tStrings.Quest.STR_QUEST_CANCEL_CONFIRM, UIHelper.GBKToUTF8(self.tbQuestInfo.szName))
            UIHelper.ShowConfirm(szContent, function()
                local dwQuestID = self.tbQuestInfo.nID
                QuestData.CanCelQuest(dwQuestID)
            end)
        end
    end)

    UIHelper.BindUIEvent(self.Btn02, EventType.OnClick, function()
        local nQuestID = self.tbQuestInfo.nID
        if QuestData.IsTracingQuestID(nQuestID) then
            if not QuestData.CanUnTraceQuest(nQuestID) then
                TipsHelper.ShowNormalTip(g_tStrings.Quest.STR_QUEST_CANNOT_CANCEL_TRACING)
            else
                QuestData.UnTraceQuestID(nQuestID)
                QuestData.AddProhibitTraceQuestID(nQuestID)
            end
        else
            QuestData.SetTracingQuestID(nQuestID)
            QuestData.RemoveProhibitTraceQuestID(nQuestID)
        end
        self:UpdateTracingButtonState()
    end)

    -- UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
    --     UIMgr.Close(self)
    -- end)
    UIHelper.BindUIEvent(self.Btn03, EventType.OnClick, function()
        local nQuestID = self.tbQuestInfo.nID
        local nMapID, tbPoints = QuestData.GetQuestMapIDAndPoints(nQuestID)

        if QuestData.IsTracingQuestID(nQuestID) then 
            UIMgr.Open(VIEW_ID.PanelMiddleMap, nMapID, 0, nil, nil, {szMessage = "请前往最近的神行点进行任务"})
            return 
        end

        local _, nMapType = GetMapParams(nMapID)
        if nMapType ~= 1 then
            MapMgr.SetTracePoint(UIHelper.GBKToUTF8(self.tbQuestInfo.szName), nMapID, tbPoints)
            UIMgr.Open(VIEW_ID.PanelMiddleMap, nMapID, 0, nil, nil, {szMessage = "请前往最近的神行点进行任务"})
        else
            MapMgr.OpenWorldMapTransportPanel(nMapID, true)
        end
    end)

    UIHelper.BindUIEvent(self.BtnoadChivalrous, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelRoadChivalrous)
    end)

    UIHelper.BindUIEvent(self.BtnRecord, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelSwordMemories)
    end)

    UIHelper.BindUIEvent(self.BtnSendToChat, EventType.OnClick, function()
        if self.tbQuestInfo then
            local dwQuestID = QuestData.GetQuestID(self.tbQuestInfo.nID)
            ChatHelper.SendQuestToChat(self.tbQuestInfo.nID)
        end
    end)
end

function UIQuestView:RegEvent()
    Event.Reg(self, EventType.OnChooseQuestEvent, function(tbQuestInfo)
        self:OnChooseQuestEvent(tbQuestInfo)
    end, false)

    Event.Reg(self, "QUEST_ACCEPTED", function(nQuestIndex, dwQuestID) self:OnQuestAccepted(nQuestIndex, dwQuestID) end)
	Event.Reg(self, "QUEST_FAILED", function(nQuestIndex) self:OnQuestFailed(nQuestIndex) end)
	Event.Reg(self, "QUEST_CANCELED", function(dwQuestID) self:OnQuestCanceled(dwQuestID) end)
    Event.Reg(self, "QUEST_TIME_UPDATE", function() self:UpdateQuestTarget() end)
    Event.Reg(self, EventType.OnTouchViewBackGround, function ()
        self:HideItemTip()
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        self.nScrollViewDetailHeight = UIHelper.GetHeight(self.ScrollViewDetail)
        self:DelayUpdateInfo()
    end)
end

function UIQuestView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIQuestView:InitData()
    self.nScrollViewDetailHeight = UIHelper.GetHeight(self.ScrollViewDetail)
    self.tbWidgetTaskToggleList  = {}
    self.tbWidgetAwardList = {}
    self:SetCurQuestType(QuestType.All)

    local tbQuestIDList = QuestData.GetTracingQuestIDList()
    if #tbQuestIDList > 0 then
        self:SetQuestInfo(self:GetQuestInfoByID(tbQuestIDList[1]))
    else
        self:SetQuestInfo(self:GetQuestInfoByPos(1, 1))
    end
end


function UIQuestView:UpdateInfo()
    self:UpdateLayoutTabList()
    self:UpdateQuestInfo()
end

-------------------------------------------------交互后的事件---------------------------------------------------

function UIQuestView:SetCheckedTogTabList(nIndex)
    self:SetCurQuestType(nIndex)
    self:SetQuestInfo(self:GetQuestInfoByPos(1, 1))
    self:UpdateLayoutTabList()
    self:UpdateScrollViewQuest()
end

function UIQuestView:OnChooseQuestEvent(tbQuestInfo)
    self:SetQuestInfo(tbQuestInfo)
end

function UIQuestView:OnQuestAccepted(nQuestIndex, dwQuestID)
    self:SetCurQuestType(self.nCurQuestType)
    self:UpdateScrollViewQuest()
    self:UpdateQuestInfo()
end

function UIQuestView:OnQuestFailed(nQuestIndex)


end

function UIQuestView:OnQuestCanceled(dwQuestID)
    self:SetCurQuestType(self.nCurQuestType)
    self:SetQuestInfo(self:GetQuestInfoByPos(1, 1))
    self:UpdateScrollViewQuest()
end

----------------------------------------------------------更新当前界面UI-------------------------------------------


--更新任务列表
function UIQuestView:UpdateLayoutTabList()
    for i,togTabList in ipairs(self.tbLayoutTabList) do
        UIHelper.SetSelected(togTabList, i == self.nCurQuestType)
     end
end

function UIQuestView:UpdateScrollViewQuest()
    -- UIHelper.SetString(self.LabelTitle11, QuestTypeName[self.nCurQuestType])

    -- UIHelper.TableView_init(self.TableView, #self.tbQuestConfList, PREFAB_ID.WidgetTaskListCell)
    -- UIHelper.TableView_reloadData(self.TableView)--当WidgetTaskListCell里有还有一层Layout时，排版会乱掉？
    if self.tbQuestConfList == nil then self.tbQuestConfList = {} end
    local bHasList = #self.tbQuestConfList ~= 0

    UIHelper.RemoveAllChildren(self.ScrollViewTask)
    self.tbCells = {}
    for nIndex, tbQuestTypeInfo in ipairs(self.tbQuestConfList) do
        self.tbCells[nIndex] = UIHelper.AddPrefab(PREFAB_ID.WidgetTaskListCell, self.ScrollViewTask, tbQuestTypeInfo, self.tbQuestInfo)
    end

    UIHelper.SetVisible(self.WidgetAnchorEmpty, not bHasList)
    UIHelper.SetVisible(self.WidgetAnchorRight, bHasList)
    UIHelper.SetVisible(self.WidgetAnchorContent, bHasList)

    UIHelper.ScrollViewDoLayout(self.ScrollViewTask)
    local selectNode = nil
    local tbScriptCells = {}
    for index, scriptCell in pairs(self.tbCells) do
        for _, script in ipairs(scriptCell:GetScriptCells()) do
            table.insert_tab(tbScriptCells, script)
            if script:IsSelected() and selectNode == nil then
                selectNode = script._rootNode
            end
        end
    end
    if selectNode then
        UIHelper.ScrollLocateToPreviewItem(self.ScrollViewTask, selectNode, Locate.TO_BOTTOM, 0)
    else
        UIHelper.ScrollToTop(self.ScrollViewTask)
    end
    UIHelper.PlayListAni(tbScriptCells, "AniAll", "AniTaskToggleShow", 2)
end


function UIQuestView:DelayUpdateInfo()
    if self.nUpdateTimer then
        Timer.DelTimer(self, self.nUpdateTimer)
    end
    self.nUpdateTimer = Timer.AddFrame(self, 2, function ()
        self:UpdateQuestInfo()
        self.nUpdateTimer = nil
    end)
end

function UIQuestView:UpdateQuestInfo()
    self:UpdateQuestAward()
    self:UpdateQuestDesc()
    self:UpdateQuestMessage()
    self:UpdateQuestTarget()
    self:UpdateWidgetLayoutTitle()
    self:UpdateTracingButtonState()
    self:UpdateLeaveForButtonState()
    self:UpdateCancelButtonState()


    UIHelper.LayoutDoLayout(self.LayoutMessage)
    UIHelper.LayoutDoLayout(self.LayoutTarget)
    UIHelper.LayoutDoLayout(self.LayoutDesc)


    local tbAwardList = self.tbQuestInfo and QuestData.GetCurQuestAwardList(self.tbQuestInfo.nID) or {}
    local nWidgetAnchorRewardHeight = UIHelper.GetHeight(self.WidgetAnchorReward)

    UIHelper.SetHeight(self.ScrollViewDetail, self.nScrollViewDetailHeight + (#tbAwardList == 0 and nWidgetAnchorRewardHeight or 0))

    UIHelper.ScrollViewDoLayout(self.ScrollViewDetail)
    UIHelper.ScrollToTop(self.ScrollViewDetail, 0)
    UIHelper.SetSwallowTouches(self.ScrollViewDetail, false)
    UIHelper.LayoutDoLayout(self.WidgetButton)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewDetail, self.WidgetArrow)
end

--更新任务标题
function UIQuestView:UpdateWidgetLayoutTitle()
    local szContent = ""
    if self.tbQuestInfo then
        szContent = self.tbQuestInfo.szName
    end
    UIHelper.SetString(self.WidgetLayoutTitle[1], UIHelper.GBKToUTF8(szContent))
end

--更新任务目标
function UIQuestView:UpdateQuestTarget()

    local scriptView = UIHelper.GetBindScript(self.LayoutTarget)
    scriptView:OnEnter(self.tbQuestInfo)
end

--更新任务描述
function UIQuestView:UpdateQuestDesc()

    local scriptView = UIHelper.GetBindScript(self.LayoutDesc)
    scriptView:OnEnter(self.tbQuestInfo)
end


function UIQuestView:UpdateQuestMessage()

    local scriptView = UIHelper.GetBindScript(self.LayoutMessage)
    scriptView:OnEnter(self.tbQuestInfo)
end

--更新任务奖励
function UIQuestView:UpdateQuestAward()

    local scriptView = UIHelper.GetBindScript(self.WidgetReward)
    local tbAwardList = self.tbQuestInfo and QuestData.GetCurQuestAwardList(self.tbQuestInfo.nID) or {}
    scriptView:OnEnter(tbAwardList, PREFAB_ID.WidgetAwardItem1)
    -- UIHelper.SetVisible(self.WidgetReward, self.tbQuestInfo ~= nil)
end



function UIQuestView:UpdateTracingButtonState()
    UIHelper.SetVisible(self.Btn02, self.tbQuestInfo ~= nil)

    if not self.tbQuestInfo then
        -- 教学 关闭任务追踪教学
        TeachEvent.TeachClose(34)
        return
    end

    local bTracing = QuestData.IsTracingQuestID(self.tbQuestInfo.nID)
    local szContent = bTracing and g_tStrings.Quest.STR_QUEST_CANCEL_TRACING or g_tStrings.Quest.STR_QUEST_TRACING
    UIHelper.SetString(self.LabelTtrace01, szContent)

    if not bTracing then
        -- 教学 任务追踪教学
        if TeachEvent.CheckCondition(34) then
            TeachEvent.TeachStart(34)
        end
    else
        TeachEvent.TeachClose(34)
    end
end

function UIQuestView:UpdateLeaveForButtonState()

    UIHelper.SetVisible(self.Btn03, self.tbQuestInfo ~= nil)
    if not self.tbQuestInfo then return end

    local bCurrentMap, bHasPoint = QuestData.IsInCurrentMap(self.tbQuestInfo.nID)
    UIHelper.SetVisible(self.Btn03, not bCurrentMap and bHasPoint)
end

function UIQuestView:UpdateCancelButtonState()
    UIHelper.SetVisible(self.Btn01, self.tbQuestInfo ~= nil)
    if not self.tbQuestInfo then return end
    local bCancelQuest = self.tbQuestInfo.bCancelQuest
    local bSystemQuest = QuestData.IsSystemQuest(self.tbQuestInfo.nID)
    UIHelper.SetVisible(self.Btn01, not bSystemQuest or bCancelQuest)
end

function UIQuestView:HideItemTip()
    local scriptView = UIHelper.GetBindScript(self.WidgetReward)
    scriptView:HideItemTip()
end


--------------------------------------------------设置当前界面的变量值--------------------------
function UIQuestView:SetQuestInfo(tbQuestInfo)
    self.tbQuestInfo = tbQuestInfo
    self:UpdateQuestInfo()
end

function UIQuestView:SetCurQuestType(nType)
    self.nCurQuestType = nType
    self:UpdateCurQuestList()
end

--当前tbQuestConfList对应的列表信息，
--[[
{ 
    {
        szTypeName = "主线", 	
        tbQuestList = {
        {
            szClassName = "稻香村",
            tbQuestList = {
                tbQuestInfo,
                tbQuestInfo,
            }
        },
        {
            szClassName = "XXXX",
            tbQuestList = {
                tbQuestInfo,
                tbQuestInfo,
            }
        },
        {--最后的任务列表没class
            tbQuestInfo,
            tbQuestInfo,
        }
    }，
    {
        szTypeName = "XX", 	
        tbQuestList = {
        {
            szClassName = "XX",
            tbQuestList = {
                tbQuestInfo,
                tbQuestInfo,
            }
        },
}	
]]--

function UIQuestView:UpdateCurQuestList()
    self.tbQuestConfList = QuestData.GetQuestList(self.nCurQuestType)
end


function UIQuestView:GetQuestInfoByPos(nClass, nQuestIndex)
    if not self.tbQuestConfList or #self.tbQuestConfList == 0 then return nil end
    for nClassIndex, tbQuestTypeInfo in ipairs(self.tbQuestConfList) do
        for nIndex, tbQuestInfo in ipairs(tbQuestTypeInfo.tbQuestList) do
            if nClassIndex == nClass and nQuestIndex == nIndex then
                return tbQuestInfo
            end
        end
    end
    return nil
end

function UIQuestView:GetQuestInfoByID(nQuestID)
    if not self.tbQuestConfList or #self.tbQuestConfList == 0 then return nil end
    for nTypeListIndex, tbQuestTypeInfo in ipairs(self.tbQuestConfList) do
        for nClassIndex, tbQuestInfo in ipairs(tbQuestTypeInfo.tbQuestList) do
            if tbQuestInfo.nID == nQuestID then
                return tbQuestInfo
            end
        end
    end
    return nil
end

return UIQuestView