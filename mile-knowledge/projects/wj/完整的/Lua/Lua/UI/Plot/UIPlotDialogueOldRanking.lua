-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPlotDialogueOldRanking
-- Date: 2022-11-23 20:53:39
-- Desc: ?
-- ---------------------------------------------------------------------------------
local tGlobalRanking = {}

local function GetRankingRefreshTime(nTime)
    local aTime = TimeToDate(nTime)
    local nTimeRefresh = DateToTime(aTime.year, aTime.month, aTime.day, 7, 0, 0)
    local nDay = aTime.weekday
    if nDay == 0 then
        nDay = 7
    end

    nTimeRefresh = nTimeRefresh - (nDay - 1) * 24 * 3600
    if nDay == 1 and nTime < nTimeRefresh then
        -- 如果当前时间是周一的0~7点，那么刷新时间应该是上周一的7点
        nTimeRefresh = nTimeRefresh - 7 * 24 * 3600
    end
    return nTimeRefresh
end

local function RequestRankData(szKey, nStart)
    local a = tGlobalRanking[szKey]
    local nTime = GetCurrentTime()
    if not a or not a.nQueryTime then
        RemoteCallToServer("OnQueryGlobalRanking", szKey, nStart, 2)
        return
    end

    local nlastQTime = a.nQueryTime or 0
    local nTimeRefresh = GetRankingRefreshTime(nTime)
    if nTime > nTimeRefresh and nlastQTime < nTimeRefresh then
        RemoteCallToServer("OnQueryGlobalRanking", szKey, nStart, 2)
        a.nQueryTime = nTime
        return
    end
end

local function GetRankCount(szKey)
    local tGlobalKey = tGlobalRanking[szKey]
    if not tGlobalKey or not tGlobalKey.tRanking then
        return 0
    end

    return #tGlobalKey.tRanking
end

local UIPlotDialogueOldRanking = class("UIPlotDialogueOldRanking")

function UIPlotDialogueOldRanking:OnEnter(tbDialogueData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    UIHelper.SetString(self.LabelPage, "0/0")

    local attribute = tbDialogueData.tbData.tbItemDataList[1].tbInfo.attribute
    self.nForceID = attribute.attri1
    self.nStart = tonumber(attribute.attri2)
    self.nCount = tonumber(attribute.attri3)
    self.nRequestTotal = tonumber(attribute.attri4)
    self.szKey = "Rank_Role_ItemMentor_" .. self.nForceID

    self:AppendMentorRank(self.nStart)
end

function UIPlotDialogueOldRanking:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPlotDialogueOldRanking:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnNext, EventType.OnClick, function()
        local nCount = GetRankCount(self.szKey)
        local nPages = math.ceil(nCount / self.nCount)
        local nIndex = math.ceil(self.nStart / self.nCount)
        if nIndex < nPages then
            self:AppendMentorRank(self.nStart + self.nCount)
        end
    end)

    UIHelper.BindUIEvent(self.BtnPrevious, EventType.OnClick, function()
        local nCount = GetRankCount(self.szKey)
        local nIndex = math.ceil(self.nStart / self.nCount)
        if nIndex > 1 then
            self:AppendMentorRank(self.nStart - self.nCount)
        end
    end)
end

function UIPlotDialogueOldRanking:RegEvent()
    --Event.Reg(self, EventType.OnWindowsSizeChanged, function()
    --    self.nScrollViewDetailHeight = UIHelper.GetHeight(self.ScrollViewDetail)
    --    self:UpdateInfo()
    --end)

    Event.Reg(self, "ON_MENTORSTONE_GET_RANKING", function(arg0, arg1, arg2, arg3, arg4)
        self:OnMentorStoneRank(arg0, arg1, arg2, arg3, arg4)
    end)
end

function UIPlotDialogueOldRanking:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPlotDialogueOldRanking:Init(dwQuestID, tbDialogueData)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

--------------------------------------------------------------------更新UI-----------------------------------------------------------

function UIPlotDialogueOldRanking:AppendMentorRank(nStart)
    local nSize = 0
    local szKey = self.szKey
    local tGlobalKey = tGlobalRanking[szKey]
    if tGlobalKey and tGlobalKey.tRanking then
        nSize = #tGlobalKey.tRanking
    end

    --if nStart then
    --    if nStart > nSize then
    --        return
    --    end
    --    self.nStart = nStart
    --end
    self.nStart = nStart
    self:UpdateMentorStone()

    local nEnd = nStart + self.nCount
    if nEnd > nSize then
        RequestRankData(szKey, nSize + 1)
    end
end

function UIPlotDialogueOldRanking:OnMentorStoneRank(arg0, arg1, arg2, arg3, arg4)
    local szKey, tMsg, bSuccess, nStartIndex, nNextIndex = arg0, arg1, arg2, arg3, arg4
    local nCount = tMsg and #tMsg or 0
  
    local tGlobalKey = tGlobalRanking[szKey]
    if not tGlobalKey or not tGlobalKey.tRanking then
        tGlobalRanking[szKey] = { nQueryTime = GetCurrentTime(), tRanking = {} }
        tGlobalKey = tGlobalRanking[szKey]
    end

    local tRanking = tGlobalKey.tRanking
    for _, v in ipairs(tMsg) do
        table.insert(tRanking, v)
    end

    self:UpdateMentorStone()
    if nNextIndex ~= 0 and self.nRequestTotal > nNextIndex then
        RemoteCallToServer("OnQueryGlobalRanking", szKey, nNextIndex, 2)
    end
end

function UIPlotDialogueOldRanking:UpdateMentorStone()
    local tGlobalKey = tGlobalRanking[self.szKey] or {}
    local tRanking = tGlobalKey.tRanking or {}
    local nCount = #tRanking
    local nStart = self.nStart
    local nEnd = nStart + self.nCount - 1
    nEnd = math.min(nEnd, nCount)

    UIHelper.RemoveAllChildren(self.ScrollViewRankingList)
    for i = nStart, nEnd, 1 do
        local tData = tRanking[i]
        if tData and tData[7] ~= 0 then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetOldDialogueContentRankXinHuo, self.ScrollViewRankingList)
            -- UIHelper.SetVisible(script.ImgBg, i % 2 == 0)
            UIHelper.SetString(script.LabelRankNum, tData[8])
            UIHelper.SetString(script.LabelPlayerName, UIHelper.GBKToUTF8(tData[1]))
            UIHelper.SetString(script.LabelCampName, g_tStrings.STR_CAMP_TITLE[tData[6]])
            UIHelper.SetString(script.LabelXinHuoPoint, tData[7])
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRankingList)

    local nCount = GetRankCount(self.szKey)
    local nPages = math.ceil(nCount / self.nCount)
    local nIndex = math.ceil(self.nStart / self.nCount)
    UIHelper.SetString(self.LabelPage, nIndex .. "/" .. nPages)
end

return UIPlotDialogueOldRanking