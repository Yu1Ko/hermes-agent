-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSeasonLevelTask
-- Date: 2026-03-13 16:48:48
-- Desc: ?
-- ---------------------------------------------------------------------------------
local tbClassList = {
    [1] = 1,    --秘境
    [2] = 6,    --家园
    [3] = 3,    --竞技
    [4] = 2,    --阵营
    [5] = 4,    --战场
    [6] = 7,    --休闲
    [7] = 5,    --绝境
}

local CLASS2PAGE = {
    [1] = COLLECTION_PAGE_TYPE.SECRET,
    [2] = COLLECTION_PAGE_TYPE.CAMP,
    [3] = COLLECTION_PAGE_TYPE.ATHLETICS,
    [4] = COLLECTION_PAGE_TYPE.ATHLETICS,
    [5] = COLLECTION_PAGE_TYPE.ATHLETICS,
    [6] = COLLECTION_PAGE_TYPE.REST,
    [7] = COLLECTION_PAGE_TYPE.REST,
}

local TYPE = {
	WEEK = 1,
	SEASON = 2,
}
local MAX_EXP_SEASON = 1500 --赛季段位最大点数
local MAX_EXP_OVERFLOW = 500 --溢出积分上限

local tbProgressBarBgColor = {
    Normal = {r = 255, g = 255, b = 255},
    OverFlow = {r = 255, g = 234, b = 136}
}
local UIWidgetSeasonLevelTask = class("UIWidgetSeasonLevelTask")

function UIWidgetSeasonLevelTask:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nCategory = self.nCategory or 1
    self.nPeriod = TYPE.WEEK
    self:UpdateInfo()
    RemoteCallToServer("On_SA_ONopen")
end

function UIWidgetSeasonLevelTask:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSeasonLevelTask:BindUIEvent()
    UIHelper.BindUIEvent(self.TogWeek, EventType.OnSelectChanged, function(_, bSelect)
        if bSelect then
            self.nPeriod = TYPE.WEEK
            self:UpdateRightTaskList(self.nCategory)
            self:UpdateExpCapTask(self.nCategory, self.nPeriod)
        end
    end)

    UIHelper.BindUIEvent(self.TogSeason, EventType.OnSelectChanged, function(_, bSelect)
        if bSelect then
            self.nPeriod = TYPE.SEASON
            self:UpdateRightTaskList(self.nCategory)
            self:UpdateExpCapTask(self.nCategory, self.nPeriod)
        end
    end)

    UIHelper.BindUIEvent(self.BtnFriendBuff, EventType.OnClick, function()
        local szTips = "师徒/挚友（好感度六重）同地图组队完成任务，可额外获得10%周段位分（不计入赛季段位分，遵循周上限及结算规则）"
        local tip, tipScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetRichTextTips, self.BtnFriendBuff, TipsLayoutDir.BOTTOM_CENTER, szTips)
    end)
end

function UIWidgetSeasonLevelTask:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        Timer.AddFrame(self, 5, function ()
            -- for k, tbScript in pairs(self.tbTaskScriptList) do
            --     UIHelper.LayoutDoLayout(tbScript.LayoutTitle)
            -- end
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewWeekTask)
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSeasonTask)
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSeasonTaskGuide)
        end)
    end)

    Event.Reg(self, "CB_SA_TeShuRenWu", function(szKey)
        if string.is_nil(szKey) or not self.nCategory then
            return
        end
        self:UpdateRightTaskList(self.nCategory)
        self:UpdateExpCapTask(self.nCategory, self.nPeriod)
    end)

    Event.Reg(self, "CB_SA_TaskUpdate", function()
        if not self.nCategory then
            return
        end
        self:UpdateRightTaskList(self.nCategory)
        self:UpdateExpCapTask(self.nCategory, self.nPeriod)
    end)
end

function UIWidgetSeasonLevelTask:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSeasonLevelTask:UpdateInfo()
    UIHelper.ToggleGroupAddToggle(self.ToggleGroup, self.TogWeek)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroup, self.TogSeason)

    self:UpdateLeftGuideTogList(self.nCategory)
end

function UIWidgetSeasonLevelTask:UpdateLeftGuideTogList(nCategory)
    UIHelper.RemoveAllChildren(self.ScrollViewSeasonTaskGuide)
    self.tbLeftTogList = {}

    for i, nClass in ipairs(tbClassList) do
        local scirpt = UIHelper.AddPrefab(PREFAB_ID.WidgetTaskGuideTog, self.ScrollViewSeasonTaskGuide)
        local szCategory = g_tStrings.STR_RANK_TITLE_NAMA[nClass] or ""
        UIHelper.SetString(scirpt.LabelNormal, szCategory)
        UIHelper.SetString(scirpt.LabelUpAll01, szCategory)
        UIHelper.BindUIEvent(scirpt.TogSecondNav, EventType.OnSelectChanged, function(_, bSelect)
            if bSelect then
                self.nCategory = nClass
                self:UpdateRightTaskList(nClass)
                self:UpdateExpCapTask(self.nCategory, self.nPeriod)
            end
        end)
        self.tbLeftTogList[nClass] = scirpt.TogSecondNav
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSeasonTaskGuide)

    if self.tbLeftTogList[self.nCategory] then
        UIHelper.SetSelected(self.tbLeftTogList[self.nCategory], true)
    end
end

function UIWidgetSeasonLevelTask:SetClass(nClass)
    self.nCategory = nClass
    if self.tbLeftTogList and self.tbLeftTogList[self.nCategory] then
        UIHelper.SetSelected(self.tbLeftTogList[self.nCategory], true)
    end
end

local function FormatTaskList(tbTaskList, tbTaskProgress)
    local tbFormattedList = {
        [1] = {}, -- 每周任务 (nPeriod = 1)
        [2] = {}  -- 赛季任务 (nPeriod = 2)
    }
    
    if tbTaskList then
        for _, tbTask in ipairs(tbTaskList) do
            if tbTask.nType == 1 then
                table.insert(tbFormattedList[1], tbTask)
            elseif tbTask.nType == 2 then
                table.insert(tbFormattedList[2], tbTask)
            end
        end
    end

    for i = 1, 2 do
        table.sort(tbFormattedList[i], function(a, b)
            local procA = (tbTaskProgress[a.szKey] and tbTaskProgress[a.szKey].nProcess) or 0
            local maxA = a.nMaxProgress or 0
            local bFinishA = (procA >= maxA) and maxA > 0

            local procB = (tbTaskProgress[b.szKey] and tbTaskProgress[b.szKey].nProcess) or 0
            local maxB = b.nMaxProgress or 0
            local bFinishB = (procB >= maxB) and maxB > 0

            if bFinishA ~= bFinishB then
                return not bFinishA
            end

            local idA = a.nTaskID or 0
            local idB = b.nTaskID or 0
            return idA < idB
        end)
    end
    
    return tbFormattedList
end

function UIWidgetSeasonLevelTask:UpdateRightTaskList(nCategory)
    UIHelper.SetSpriteFrame(self.ImgTaskGuideTitle, CLASS_IMG[nCategory])
    UIHelper.SetSpriteFrame(self.ImgTaskGuide, CLASS_BGIMG[nCategory])

    local tbTaskList = CollectionData.GetSeasonLevelTaskListByClass(nCategory)
    local tbTaskProgress = GDAPI_SA_GetTaskListProgress(nCategory)
    tbTaskList = FormatTaskList(tbTaskList, tbTaskProgress)
    self:UpdateLevelInfo(nCategory)

    self.tbTaskScriptList = {}

    for i, tbTaskInfo in pairs(tbTaskList) do
        local ScrollView = i == 1 and self.ScrollViewWeekTask or self.ScrollViewSeasonTask
        UIHelper.RemoveAllChildren(ScrollView)
        table.sort(tbTaskInfo, function(a, b)
            local procA = (tbTaskProgress[a.szKey] and tbTaskProgress[a.szKey].nProcess) or 0
            local maxA = a.nMaxProgress or 0
            local nRoundA = tbTaskProgress[a.szKey] and tbTaskProgress[a.szKey].Round or 0
            local nMaxRoundA = tbTaskProgress[a.szKey] and tbTaskProgress[a.szKey].RoundMax or 0
            local bFinishA = false
            if nMaxRoundA > 0 then
                bFinishA = nRoundA == nMaxRoundA
            else
                bFinishA = procA == maxA
            end

            local procB = (tbTaskProgress[b.szKey] and tbTaskProgress[b.szKey].nProcess) or 0
            local maxB = b.nMaxProgress or 0
            local nRoundB = tbTaskProgress[b.szKey] and tbTaskProgress[b.szKey].Round or 0
            local nMaxRoundB = tbTaskProgress[b.szKey] and tbTaskProgress[b.szKey].RoundMax or 0
            local bFinishB = false
            if nMaxRoundB > 0 then
                bFinishB = nRoundB == nMaxRoundB
            else
                bFinishB = procB == maxB
            end

            if bFinishA ~= bFinishB then
                return not bFinishA
            end

            local bLockA = a.bLock == true
            local bLockB = b.bLock == true
            if bLockA ~= bLockB then
                return not bLockA
            end

            local idA = a.nSort or 0
            local idB = b.nSort or 0
            return idA < idB
        end)
        for i, tbInfo in ipairs(tbTaskInfo) do
            if tbInfo.bShow then
                local tbProgressInfo = tbTaskProgress[tbInfo.szKey]
                local nProcess = tbProgressInfo and tbProgressInfo.nProcess or 0
                local nMaxProgress = tbProgressInfo and tbProgressInfo.nProcessMax or tbInfo.nProcessMax or 0
                local nRound = tbProgressInfo and tbProgressInfo.Round or 0
                local nMaxRound = tbProgressInfo and tbProgressInfo.RoundMax or 0
                
                local szDesc = UIHelper.GBKToUTF8(tbInfo.szDesc) or ""
                local bFinished = false
                if nMaxRound > 0 then
                    bFinished = nRound == nMaxRound
                else
                    bFinished = nProcess == nMaxProgress
                end
                local nScore = tbInfo.nScore or 0
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSeasonLevelTaskList, ScrollView)
                local bHideRound = nRound == 0 and nMaxRound == 0
                local bLock = tbInfo.bLock
                local szLockTips = UIHelper.GBKToUTF8(tbInfo.szLockTime) or ""

                UIHelper.SetVisible(script.LabelTaskProgress, nMaxProgress > 1)
                UIHelper.SetVisible(script.imgBgProgressNon, nMaxProgress == 1 and not bFinished)
                UIHelper.SetVisible(script.imgBgProgressGet, bFinished)
                UIHelper.SetVisible(script.imgBgWeekTaskNum, not bHideRound and not bLock)
                UIHelper.SetString(script.LabelWeekTaskNum, string.format("轮次%d/%d", nRound, nMaxRound))
                UIHelper.SetString(script.LabelTaskProgress, string.format("%d/%d", nProcess, nMaxProgress))
                UIHelper.SetString(script.LabelTask, szDesc)
                UIHelper.SetVisible(script.imgBgFinish, bFinished)
                UIHelper.SetEnable(script._rootNode, not bFinished)
                UIHelper.SetVisible(script.imgBgHint, not bFinished)
                UIHelper.SetString(script.LabelTaskReward, string.format("%s分", tostring(nScore)))
                UIHelper.SetVisible(script.imgFriend, tbInfo.bAddition and not bLock)
                UIHelper.SetVisible(script.imgFinish, bFinished)
                UIHelper.SetVisible(script.imgBgWeekTaskLock, bLock)
                UIHelper.SetString(script.LabelWeekTaskLock, szLockTips)

                UIHelper.BindUIEvent(script._rootNode, EventType.OnClick, function ()
                    if bLock then
                        TipsHelper.ShowNormalTip("暂未开启,敬请期待")
                    else
                        if tbInfo.szMobileFunction and tbInfo.szMobileFunction ~= "" then
                            CollectionFuncList.Excute(tbInfo.szMobileFunction)
                        elseif tbInfo.szLink and tbInfo.szLink ~= "" then
                            Event.Dispatch("EVENT_LINK_NOTIFY", tbInfo.szLink)
                        end
                    end

                end)
                table.insert(self.tbTaskScriptList, script)
            end
        end
        UIHelper.ScrollViewDoLayoutAndToTop(ScrollView)
    end
end

function UIWidgetSeasonLevelTask:UpdateLevelInfo(nCategory)
    local tAllRankInfo = GDAPI_SA_GetAllRankBaseInfo()
    local tClassInfo = tAllRankInfo[nCategory]
    local nRankLv = tClassInfo and tClassInfo.nRankLv or 0
    local nScore = tClassInfo and tClassInfo.nTotalScores or 0
    local tbNextLevelInfo = CollectionData.GetLevelRewardListByLevel(nRankLv + 1)
    local nNextScore = tbNextLevelInfo and tbNextLevelInfo.score or 0
    local tCurRankInfo = Table_GetRankInfoByLevel(nRankLv)
    local szRankName = tCurRankInfo and UIHelper.GBKToUTF8(tCurRankInfo.szRankName) or ""
    local nRankPoint = tCurRankInfo and tCurRankInfo.nRankPoint or 0
    local nScoreMAX = tClassInfo and tClassInfo.nScoreMAX or 0
    local szRankFullName = UIHelper.GBKToUTF8(tCurRankInfo.szRankFullName) or ""
    local szSuffix
    if nScore < nScoreMAX then
        szSuffix = string.format("%s %d", szRankFullName, nScore)
    else
        szSuffix = string.format("%s 已最高", szRankFullName)
    end

    UIHelper.SetString(self.LabelRankTitle, szSuffix)
    if nNextScore - nScore > 0 then
        UIHelper.SetString(self.LabelRank, string.format("下一阶段需：%d", nNextScore - nScore))
    end
    UIHelper.SetVisible(self.LabelRank, nNextScore - nScore > 0)
end

function UIWidgetSeasonLevelTask:UpdateExpCapTask(nClass, nType)
    if not nClass or not nType then
        return
    end
    local _, _, nCurExp_Week, nCurExp_Season, _, nMaxExp, _nWeekSpareScores = GDAPI_SA_GetRankBaseInfo(nClass)
    local nCurExp
	if nType == TYPE.WEEK then 
		nCurExp = nCurExp_Week
	elseif nType == TYPE.SEASON then
		nCurExp = nCurExp_Season
		nMaxExp = MAX_EXP_SEASON
	end

    local bOverFlow = _nWeekSpareScores > 0
    local nPercent = 0
    local tbColor = bOverFlow and tbProgressBarBgColor.OverFlow or tbProgressBarBgColor.Normal
    UIHelper.SetColor(self.ProgressBarMining, cc.c3b(tbColor.r, tbColor.g, tbColor.b))

    if bOverFlow and nType == TYPE.WEEK then
        nPercent = (_nWeekSpareScores / MAX_EXP_OVERFLOW) * 100
        UIHelper.SetString(self.LabelNum, string.format("%d/%d", _nWeekSpareScores, MAX_EXP_OVERFLOW))
    elseif nMaxExp == 0 then
	    nPercent = 0
	else
	    nPercent = (nCurExp/nMaxExp) * 100
        UIHelper.SetString(self.LabelNum, string.format("%d/%d", nCurExp, nMaxExp))
    end
    UIHelper.SetProgressBarPercent(self.ProgressBarMining, nPercent)

    local szTitle = string.format("%s周段位分上限", nClass and g_tStrings.STR_RANK_TITLE_NAMA[nClass] or "")
    if nType == TYPE.SEASON then
        szTitle = string.format("%s赛季段位分", nClass and g_tStrings.STR_RANK_TITLE_NAMA[nClass] or "")
    end
    if bOverFlow and nType == TYPE.WEEK then
        szTitle = string.format("%s周段位分溢出", nClass and g_tStrings.STR_RANK_TITLE_NAMA[nClass] or "")
    end
    UIHelper.SetString(self.LabelLevelNum, szTitle)
end

return UIWidgetSeasonLevelTask