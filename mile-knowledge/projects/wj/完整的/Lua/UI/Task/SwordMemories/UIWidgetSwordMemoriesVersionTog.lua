-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSwordMemoriesVersionTog
-- Date: 2023-12-14 14:15:49
-- Desc: ?
-- ---------------------------------------------------------------------------------


local UIWidgetSwordMemoriesVersionTog = class("UIWidgetSwordMemoriesVersionTog")

function UIWidgetSwordMemoriesVersionTog:OnEnter(nSeasonID, swordMemoriesView, bPlayVersionAni, nChapterID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nSeasonID = nSeasonID
    self.swordMemoriesView = swordMemoriesView
    self.tbChapterList = SwordMemoriesData.GetChapterList(self.nSeasonID)
    self.cellSwordMemoriesPart = self.cellSwordMemoriesPart or PrefabPool.New(PREFAB_ID.WidgetSwordMemoriesPartCell, 10)
    self.bPlayVersionAni = bPlayVersionAni
    self.nChapterID = nChapterID
    self.nDefaultSelectIndex = self:GetDefaultSelectIndex()
    self:UpdateInfo()
end

function UIWidgetSwordMemoriesVersionTog:OnExit()
    self.bInit = false
    self:UnRegEvent()

    if self.cellSwordMemoriesPart then self.cellSwordMemoriesPart:Dispose() end
    self.cellSwordMemoriesPart = nil
end

function UIWidgetSwordMemoriesVersionTog:BindUIEvent()
    UIHelper.BindUIEvent(self.TogVersion, EventType.OnClick, function()
        self.swordMemoriesView:BackToVersionList()
    end)

    UIHelper.BindUIEvent(self.BtnFold, EventType.OnClick, function()
        self.swordMemoriesView:BackToVersionList()
    end)

    UIHelper.BindUIEvent(self.TogStretchFold, EventType.OnSelectChanged, function(_, bSelected)
        self:StretchFold(not bSelected)
    end)

    UIHelper.BindUIEvent(self.BtnTask, EventType.OnClick, function()
        if PVPFieldData.IsInPVPField() then -- 千里伐逐内
            TipsHelper.ShowNormalTip("侠士当前所在地图无法直接前往任务")
            return
        end

        if self.nQuestID then
            local player = g_pClientPlayer
            local nResult = player.CanAcceptQuest(self.nQuestID)
            local bCanAccept = nResult == QUEST_RESULT.SUCCESS or nResult == QUEST_RESULT.ALREADY_ACCEPTED or nResult == QUEST_RESULT.ALREADY_FINISHED 
            local nPrevChapter = self.tbCurChapterInfo.nPrevChapter
            local bPrevFinish = false
            local nCur, nTotal = SwordMemoriesData.GetSectionFinishedCount(nPrevChapter)
            if nPrevChapter == 0 or nCur == nTotal then
                bPrevFinish = true
            end

            --前置任务未完成
            if not bCanAccept and not bPrevFinish then
                local tbChapterInfo = SwordMemoriesData.GetChapterInfo(nPrevChapter)
                if tbChapterInfo then
                    local szText = GetFormatText(FormatString(g_tStrings.STR_MAIN_STORY_FINISH_PREV, UIHelper.GBKToUTF8(tbChapterInfo.szName)))
                    TipsHelper.ShowNormalTip(szText)
                    return
                end
            end

            MapMgr.TransferToNearestCity(self.nQuestID)
        end
    end)

    UIHelper.BindUIEvent(self.BtnReward, EventType.OnClick, function()
        if self.bCanGetReward then
            RemoteCallToServer("On_Quest_GetMainStoryReward", self.nSeasonID)
        else
            local tbAwardList = SwordMemoriesData.GetSeasonRewardList(self.nSeasonID)
            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetRewardPreview, self.BtnReward, TipsLayoutDir.TOP_CENTER, tbAwardList, PREFAB_ID.WidgetAward)
        end
    end)
end

function UIWidgetSwordMemoriesVersionTog:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnShowAllSection, function()
        self:UpdateSectionList()
    end)

    Event.Reg(self, EventType.UpdateMainStoryReward, function()
        self:UpdateFinishSectionCount()
    end)
end

function UIWidgetSwordMemoriesVersionTog:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetSwordMemoriesVersionTog:GetDefaultSelectIndex()
    if self.nChapterID then
        for nIndex, szChapterID in ipairs(self.tbChapterList) do
            if self.nChapterID == tonumber(szChapterID) then
                return nIndex
            end
        end
    end
    return 1
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSwordMemoriesVersionTog:UpdateInfo()
    -- local szImagePath = SwordMemoriesVersionBg[self.nSeasonID]
    -- UIHelper.SetSpriteFrame(self.ImgBg, szImagePath)
    self:UpdateName()
    self:UpdateChapterList()
    self:UpdateDesc()
    self:UpdateWidgetComingSoon()
    self:UpdateFinishSectionCount()
end

function UIWidgetSwordMemoriesVersionTog:UpdateName()
    if self.bPlayVersionAni then
        self.swordMemoriesView:PlayAni("AniVersion")
    end
    UIHelper.SetSpriteFrame(self.ImgVersionTitle, SwordMemoriesVersionTitleBg[self.nSeasonID])
end

function UIWidgetSwordMemoriesVersionTog:UpdateDesc()
    UIHelper.SetString(self.LabelOverview, SwordMemoriesData.GetSeasonDesc(self.nSeasonID))
end

function UIWidgetSwordMemoriesVersionTog:RemoveChapterList()
    if self.tbChapterListScript then
        for nIndex, scriptView in ipairs(self.tbChapterListScript) do
            UIHelper.SetVisible(scriptView._rootNode, false)
        end
    else
        self.tbChapterListScript = {}
    end
end

function UIWidgetSwordMemoriesVersionTog:UpdateChapterList()

    self:RemoveChapterList()
    local tbChapterList = self.tbChapterList
    local nUIIndex = 0
    local nTotalUINum = 0
    for nIndex, szChapterID in ipairs(tbChapterList) do
        local tbChapterInfo = SwordMemoriesData.GetChapterInfo(tonumber(szChapterID))
        local tbSectionList = SwordMemoriesData.GetSectionList(tonumber(szChapterID))
        if #tbSectionList > 0 then
            local scriptView = self.tbChapterListScript[nIndex]
            local bSelect = nIndex == self.nDefaultSelectIndex
            if scriptView then
                scriptView:OnEnter(tbChapterInfo, self, bSelect)
            else
                scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetSwordMemoriesChapterTog, self.ScrollViewChapter, tbChapterInfo, self, bSelect)
                table.insert(self.tbChapterListScript, scriptView)
            end
            nTotalUINum = nTotalUINum + 1 
            if bSelect then
                nUIIndex = nTotalUINum
            end
        end
    end

    if self.nDelayTimer then
        Timer.DelTimer(self, self.nDelayTimer)
        self.nDelayTimer = nil
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewChapter)
    self.nDelayTimer = Timer.AddFrame(self, 2, function()
        UIHelper.ScrollToIndex(self.ScrollViewChapter, nUIIndex - 1, 0, false)
    end)
    UIHelper.PlayAni(self, self._rootNode, "AniSwordMemoriesVersionTog")
end


function UIWidgetSwordMemoriesVersionTog:UpdateChapterInfo()
    self:UpdateTitle()
    self:UpdateImageBG()
    self:UpdateNum()
    self:UpdateSectionList()
    self:UpdateCurQuestName()
    self:UpdateFinish()
end

function UIWidgetSwordMemoriesVersionTog:UpdateTitle()
    local tbChapterInfo = self.tbCurChapterInfo
    local szTitle = tbChapterInfo.szName
    UIHelper.SetString(self.LabelChapterTitle, UIHelper.GBKToUTF8(szTitle))
end

function UIWidgetSwordMemoriesVersionTog:UpdateImageBG()
    local tbChapterInfo = self.tbCurChapterInfo
    local nTexIndex = string.match(tbChapterInfo.szImagePath, "MainPlotMap(%d+).UITex")
    local nFrameIndex = tbChapterInfo.nFrame
    local szImagePath = string.format("mui/Resource/WorldMap/MainPlotMap/MainPlotMap%s_%s.png", nTexIndex, nFrameIndex)
    if szImagePath and szImagePath ~= "" then
        UIHelper.SetTexture(self.ImgChapterBg, szImagePath, true)
        UIHelper.UpdateMask(self.MaskBg)
    end
end

function UIWidgetSwordMemoriesVersionTog:UpdateNum()
    local tbChapterInfo = self.tbCurChapterInfo
    local nCount, nTotal = SwordMemoriesData.GetChapterProgress(self.nChapterID)
    local szNum = FormatString(g_tStrings.STR_QUEST_SECTION, nCount, nTotal)
    UIHelper.SetString(self.LabelChapterNum, szNum)
    UIHelper.SetVisible(self.LabelChapterNum, not tbChapterInfo.bLock)
    UIHelper.SetVisible(self.LabelChapterLocked, tbChapterInfo.bLock)

    for nIndex, widget in ipairs(self.tbWidgetPart) do
        UIHelper.SetVisible(widget, nIndex <= nTotal and (not tbChapterInfo.bLock))
    end

    for nIndex = 1, nTotal do
        local WidgetLock = self.tbPartLocked[nIndex]
        local WidgetUnLock = self.tbPartUnLocked[nIndex]
        if WidgetLock and WidgetUnLock then
            UIHelper.SetVisible(WidgetLock, nIndex > nCount)
            UIHelper.SetVisible(WidgetUnLock, nIndex <= nCount)
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutPartUnlock)
end

function UIWidgetSwordMemoriesVersionTog:RemoveSectionList()
    if self.tbSectionNode then
        for nIndex, tbInfo in ipairs(self.tbSectionNode) do
            self.cellSwordMemoriesPart:Recycle(tbInfo.node)
        end
    end
    self.tbSectionNode = {}
end

function UIWidgetSwordMemoriesVersionTog:UpdateSectionList()
    local tbChapterInfo = self.tbCurChapterInfo
    local tbSectionList = SwordMemoriesData.GetSectionList(self.nChapterID)

    local bDefaulSelect = false --默认展开
    self:RemoveSectionList()
    for nIndex, szSectionID in ipairs(tbSectionList) do
        local tbSectionInfo = SwordMemoriesData.GetSectionInfo(tonumber(szSectionID))
        -- if SwordMemoriesData.IsSectionVisible(tbSectionInfo) then
            local node, scriptView = self.cellSwordMemoriesPart:Allocate(self.ScrollViewChapterContent, tbSectionInfo, self, bDefaulSelect)
            table.insert(self.tbSectionNode, {node = node, script = scriptView})
        -- end
    end
    self.nTotalSection = #tbSectionList
    self.nSelectedNum = 0

    if self.nTimer then Timer.DelTimer(self, self.nTimer) end
    self.nTimer = Timer.AddFrame(self, 1, function()
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewChapterContent)
    end)
    UIHelper.SetSelected(self.TogStretchFold, not bDefaulSelect, false)
end

function UIWidgetSwordMemoriesVersionTog:UpdateCurQuestName()
    self.nQuestID = SwordMemoriesData.GetFirstUnFinishQuestID(self.nChapterID)
    local bHasQuest = self.nQuestID ~= 0
    if bHasQuest then
        local szQuestName = QuestData.GetQuestName(self.nQuestID)
        UIHelper.SetString(self.LabelTaskName, szQuestName)
    end
    UIHelper.SetVisible(self.LabelTaskName, bHasQuest)
    UIHelper.SetVisible(self.BtnTask, bHasQuest)
    UIHelper.SetVisible(self.LabelTaskTitle, bHasQuest)
end

function UIWidgetSwordMemoriesVersionTog:UpdateFinish()
    UIHelper.SetVisible(self.WidgetFinished, SwordMemoriesData.IsChapterFinished(self.nChapterID))
end

function UIWidgetSwordMemoriesVersionTog:UpdateWidgetComingSoon()
    local bHasReward = SwordMemoriesData.HasRewardList(self.nSeasonID)
    UIHelper.SetVisible(self.WidgetComingSoon, not bHasReward)
    UIHelper.SetVisible(self.WidgetOngoing, bHasReward)
    UIHelper.SetTouchEnabled(self.BtnReward, bHasReward)
end

function UIWidgetSwordMemoriesVersionTog:UpdateFinishSectionCount()
    self.bCanGetReward = SwordMemoriesData.CanGetReward(self.nSeasonID)
    local nCount, nTotal = SwordMemoriesData.GetSeasonProgress(self.nSeasonID)
    UIHelper.SetString(self.LabelProgressNum, string.format("%s/%s", nCount, nTotal))
    UIHelper.SetVisible(self.ImgAvailable, self.bCanGetReward)
    UIHelper.SetVisible(self.ImgGotten, SwordMemoriesData.HasGetReward(self.nSeasonID) and SwordMemoriesData.IsSeasonFinished(self.nSeasonID))

end

function UIWidgetSwordMemoriesVersionTog:SetCurChapter(tbCurChapterInfo)
    self.nChapterID = tbCurChapterInfo.dwID
    self.tbCurChapterInfo = tbCurChapterInfo
    self:UpdateChapterInfo()
end

function UIWidgetSwordMemoriesVersionTog:ScrollViewDoLayout(script)
    UIHelper.ScrollViewDoLayout(self.ScrollViewChapterContent)
    UIHelper.ScrollLocateToPreviewItem(self.ScrollViewChapterContent, script._rootNode, Locate.TO_CENTER)
end

function UIWidgetSwordMemoriesVersionTog:UpdateSelectedNum(bSelected)
    local nNum = bSelected and 1 or -1
    self.nSelectedNum = self.nSelectedNum + nNum
    if self.nSelectedNum == 0 then
        UIHelper.SetSelected(self.TogStretchFold, true, false)
    end

    if self.nSelectedNum == self.nTotalSection then
        UIHelper.SetSelected(self.TogStretchFold, false, false)
    end
end

function UIWidgetSwordMemoriesVersionTog:StretchFold(bSelected)
    self.nSelectedNum = bSelected and self.nTotalSection or 0
    if self.tbSectionNode then
        for nIndex, tbInfo in ipairs(self.tbSectionNode) do
            local script = tbInfo.script
            script:SetSelected(bSelected, false)
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewChapterContent)
end

return UIWidgetSwordMemoriesVersionTog