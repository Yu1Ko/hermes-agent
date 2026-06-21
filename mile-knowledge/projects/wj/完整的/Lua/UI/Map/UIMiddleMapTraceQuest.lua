local UIMiddleMapTraceQuest = class("UIMiddleMapTraceQuest")

function UIMiddleMapTraceQuest:OnEnter()
    self.WidgetQuest = UIHelper.GetBindScript(self.WidgetQuest)
end

function UIMiddleMapTraceQuest:Show(tbInfo, nMapID, tPoint, bTrace, szFrame)
    local nQuestID, szType = unpack(tbInfo)
    self.nQuestID = nQuestID
    self.tbInfo = tbInfo

    self.WidgetQuest:Init(nQuestID, {})
    self.WidgetQuest:UpdateInfo()
    self._rootNode:setVisible(true)

    self.tbWidgetAwardList = {}

    local szQuestName = QuestData.GetQuestName(nQuestID)
    UIHelper.SetString(self.LabelTitle01, szQuestName)

    UIHelper.ScrollViewDoLayout(self.ScrollViewMessage)
    UIHelper.ScrollToTop(self.ScrollViewMessage, 0, false)

    UIHelper.ScrollViewDoLayout(self.ScrollViewAward)
    UIHelper.ScrollToTop(self.ScrollViewAward, 0, false)

    local szText = bTrace and g_tStrings.STR_MAP_TRACE_CANCCEL or g_tStrings.STR_MAP_TRACE_BEGIN
    self.LabelTrace01:setString(szText)

    UIHelper.BindUIEvent(self.BtnTrace01, EventType.OnClick, function()
        if bTrace then
            MapMgr.ClearTracePoint()
            Event.Dispatch("ON_MIDDLE_MAP_MARK_UNCHECK")
        else
            MapMgr.SetTracePoint(szQuestName, nMapID, tPoint, nil, szFrame)
            Event.Dispatch("ON_MIDDLE_MAP_MARK_UNCHECK")
        end
    end)

    UIHelper.BindUIEvent(self.BtnWalk, EventType.OnClick, function()
        local szRemark = "Quest_" .. self.nQuestID
        szRemark = UIHelper.LimitUtf8Len(szRemark, 64)
        AutoNav.NavTo(nMapID, tPoint[1], tPoint[2], tPoint[3], AutoNav.DefaultNavCutTailCellCount, szRemark)
    end)
end

function UIMiddleMapTraceQuest:OnExit()

end

return UIMiddleMapTraceQuest