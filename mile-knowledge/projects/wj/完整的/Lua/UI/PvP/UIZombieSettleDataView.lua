-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIZombieSettleDataView
-- Date: 2023-09-14 17:18:18
-- Desc: 李渡鬼域-结算
-- Prefab: PanelZombieSettleData
-- ---------------------------------------------------------------------------------

local UIZombieSettleDataView = class("UIZombieSettleDataView")

local tEvaluateIDToName      = {
    [1] = "绝域英豪",
    [2] = "所向披靡",
    [3] = "锲而不舍",
    [4] = "百折不挠",
}

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIZombieSettleDataView:_LuaBindList()
    self.BtnClose                   = self.BtnClose --- 关闭

    self.LabelResult                = self.LabelResult --- 结果
    self.LabelEvaluate              = self.LabelEvaluate --- 战绩评价
    self.LabelScore                 = self.LabelScore --- 个人奖励得分
    self.LabelReward                = self.LabelReward --- 个人奖励货币数

    self.tLabelHumanStats           = self.tLabelHumanStats --- 人形战绩label 列表
    self.tLabelZombieStats          = self.tLabelZombieStats --- 毒化战绩label 列表

    self.BtnLeave                   = self.BtnLeave --- 退出战场
    self.RichTextTime               = self.RichTextTime --- 自动退出的剩余时间

    self.ImgWinnerZombieRightBottom = self.ImgWinnerZombieRightBottom --- 毒化胜利右下角背景图
    self.ImgWinnerZombieLeftTop     = self.ImgWinnerZombieLeftTop --- 毒化胜利左上角背景图
    self.ImgWinnerHumanRightBottom  = self.ImgWinnerHumanRightBottom --- 人形胜利右下角背景图
    self.ImgWinnerHumanLeftTop      = self.ImgWinnerHumanLeftTop --- 人形胜利左上角背景图

    self.ImgEvaluateName1           = self.ImgEvaluateName1 --- 战绩评价图片1
    self.ImgEvaluateName2           = self.ImgEvaluateName2 --- 战绩评价图片2
    self.ImgEvaluateName3           = self.ImgEvaluateName3 --- 战绩评价图片3
    self.ImgEvaluateName4           = self.ImgEvaluateName4 --- 战绩评价图片4

    self.LabelRecordRankNum         = self.LabelRecordRankNum --- 超过的玩家数的百分比的label
end

function UIZombieSettleDataView:OnEnter(tStatistics)
    --- 当前角色的数据
    self.tStatistics = tStatistics

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()

    self:UpdateTime()
    Timer.AddCycle(self, 0.5, function()
        self:UpdateTime()
    end)
end

function UIZombieSettleDataView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIZombieSettleDataView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnLeave, EventType.OnClick, function()
        BattleFieldData.LeaveBattleField()
        UIMgr.Close(self)
    end)
end

function UIZombieSettleDataView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)

    Event.Reg(self, EventType.OnClientPlayerLeave, function(nPlayerID)
        UIMgr.Close(self)
    end)
end

function UIZombieSettleDataView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
local function _GetEvaluateInfo()
    local tEvaluateInfo = {}

    local nCount        = g_tTable.ZombieFianlEvaluate:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.ZombieFianlEvaluate:GetRow(i)
        table.insert(tEvaluateInfo, tLine)
    end

    return tEvaluateInfo
end

local function _GetFinalInfo()
    local tFianlInfo = {}

    local nCount     = g_tTable.ZombieFightFinal:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.ZombieFightFinal:GetRow(i)
        if tLine.bZombie then
            tFianlInfo[1] = tFianlInfo[1] or {}
            table.insert(tFianlInfo[1], tLine)
        else
            tFianlInfo[0] = tFianlInfo[0] or {}
            table.insert(tFianlInfo[0], tLine)
        end
    end

    return tFianlInfo
end

function UIZombieSettleDataView:UpdateInfo()
    -- 结果
    self:UpdateWin()

    -- 评价
    local nMyLevel      = self.tStatistics[PQ_STATISTICS_INDEX.AWARD_MONEY]
    local tEvaluateInfo = _GetEvaluateInfo()
    local nEvaluateID   = 1
    for _, info in ipairs(tEvaluateInfo) do
        if nMyLevel == info.nLevel then
            nEvaluateID = info.dwID
            break
        end
    end

    local szEvaluate = tEvaluateIDToName[nEvaluateID]
    UIHelper.SetString(self.LabelEvaluate, szEvaluate)

    for idx = 1, 4 do
        local img = self["ImgEvaluateName" .. idx]
        UIHelper.SetVisible(img, idx == nEvaluateID)
    end

    -- 个人奖励
    local nScore = tonumber(self.tStatistics[PQ_STATISTICS_INDEX.AWARD_2]) or 0
    local szScoreText
    if nScore >= 0 then
        szScoreText = g_tStrings.STR_ADD_SYMBOL .. nScore .. g_tStrings.STR_ZOMBIE_SCORE
    else
        szScoreText = nScore .. g_tStrings.STR_ZOMBIE_SCORE
    end

    local nReward = self.tStatistics[PQ_STATISTICS_INDEX.AWARD_3]

    UIHelper.SetString(self.LabelScore, szScoreText)
    UIHelper.SetString(self.LabelReward, nReward)

    --表现超越
    local nMyRanking  = self.tStatistics[PQ_STATISTICS_INDEX.SPECIAL_OP_7]
    local PERSON_SUM  = 50 --战场总人数
    local nPercentage = math.ceil((PERSON_SUM - nMyRanking) / PERSON_SUM * 100)

    UIHelper.SetString(self.LabelRecordRankNum, string.format("%d%%", nPercentage))

    -- 战绩
    self:UpdateFinalInfo()
end

function UIZombieSettleDataView:UpdateWin()
    local tObjective = GetBattleFieldObjective()
    if not tObjective then
        return
    end

    local bHumanWin = false
    if tObjective[1][1] >= tObjective[1][2] then
        bHumanWin = true
    elseif tObjective[2][1] >= tObjective[2][2] then
        bHumanWin = false
    elseif tObjective[3][1] >= tObjective[3][2] then
        bHumanWin = false
    end

    local szResult = bHumanWin and "探秘者胜" or "感染者胜"
    UIHelper.SetString(self.LabelResult, szResult)

    UIHelper.SetVisible(self.ImgWinnerZombieRightBottom, not bHumanWin)
    UIHelper.SetVisible(self.ImgWinnerZombieLeftTop, not bHumanWin)

    UIHelper.SetVisible(self.ImgWinnerHumanRightBottom, bHumanWin)
    UIHelper.SetVisible(self.ImgWinnerHumanLeftTop, bHumanWin)
end

function UIZombieSettleDataView:UpdateFinalInfo()
    local tFianlInfo = _GetFinalInfo()

    self:UpdateSideFinalInfo(self.tLabelHumanStats, tFianlInfo[0])
    self:UpdateSideFinalInfo(self.tLabelZombieStats, tFianlInfo[1])
end

function UIZombieSettleDataView:UpdateSideFinalInfo(tLabelStats, tSideFinalInfo)
    local tInfo = self.tStatistics

    for idx, v in ipairs(tSideFinalInfo) do
        local tLabelValue = tLabelStats[idx]
        local nValue      = tInfo[PQ_STATISTICS_INDEX[v.szValueName]]

        UIHelper.SetString(tLabelValue, nValue)
    end
end

function UIZombieSettleDataView:UpdateTime()
    local tInfo       = BattleFieldData.GetBattleFieldInfo()
    local nBanishTime = tInfo.nBanishTime
    local nCurTime    = GetCurrentTime()

    if nBanishTime and nBanishTime >= nCurTime then
        local nTime = nBanishTime - nCurTime
        UIHelper.SetRichText(self.RichTextTime, string.format("<color=#d7f6ff>将在<color=#ffe26e>%d秒</c>后传出地图</c>", nTime))
    else
        UIHelper.SetVisible(self.RichTextTime, false)
    end
end

return UIZombieSettleDataView