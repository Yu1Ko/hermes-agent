-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIPanelYangDaoSettleDataView
-- Date: 2026-03-04 15:55:57
-- Desc: 扬刀大会-结算界面 PanelYangDaoSettleData
-- ---------------------------------------------------------------------------------

local UIPanelYangDaoSettleDataView = class("UIPanelYangDaoSettleDataView")

local szImgIconPracticePath = "UIAtlas2_YangDao_YangDaoPanel01_ImgIcon_Pra.png"
local szImgIconChallengePath = "UIAtlas2_YangDao_YangDaoPanel01_ImgIcon_Cha.png"

function UIPanelYangDaoSettleDataView:OnEnter(tBattleFieldInfo, funcClickBackMvpCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tBattleFieldInfo = tBattleFieldInfo
    self.funcClickBackMvpCallback = funcClickBackMvpCallback

    self:UpdateInfo()

    UIMgr.HideView(VIEW_ID.PanelRevive)
    UIMgr.HideLayer(UILayer.Main)
end

function UIPanelYangDaoSettleDataView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    UIMgr.ShowLayer(UILayer.Main)
    UIMgr.ShowView(VIEW_ID.PanelRevive)
end

function UIPanelYangDaoSettleDataView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnMvp, EventType.OnClick, function()
        if self.funcClickBackMvpCallback then
            self.funcClickBackMvpCallback()
        end
    end)
    UIHelper.BindUIEvent(self.BtnRest, EventType.OnClick, function()
        UIMgr.Close(self)
        ArenaTowerData.PlayerRest()
    end)
    UIHelper.BindUIEvent(self.BtnRetry, EventType.OnClick, function()
        UIMgr.Close(self)
        ArenaTowerData.bArenaTowerViewFold = false
        Event.Dispatch(EventType.OnArenaTowerUpdateRoundState)
    end)
    UIHelper.BindUIEvent(self.BtnBless, EventType.OnClick, function()
        UIMgr.Close(self)
        UIMgr.Open(VIEW_ID.PanelBlessChoose)
    end)
    UIHelper.BindUIEvent(self.BtnNext, EventType.OnClick, function()
        UIMgr.Close(self)

        local tMyData = self.tBattleFieldInfo and self.tBattleFieldInfo.tMyData
        local nDiffMode = tMyData and tMyData[PQ_STATISTICS_INDEX.SPECIAL_OP_1] or 0
        UIMgr.Open(VIEW_ID.PanelYangDaoSettlement, ArenaTowerSettleResult.AllClear, function()
            UIMgr.Open(VIEW_ID.PanelYangDaoStats, self.tBattleFieldInfo)
        end, nDiffMode)
    end)
    UIHelper.BindUIEvent(self.BtnPraiseAll, EventType.OnClick, function()
        BattleFieldData.ReqPraiseAll()
    end)
    -- UIHelper.BindUIEvent(self.BtnReport, EventType.OnClick, function()
    -- end)
    UIHelper.BindUIEvent(self.BtnChat, EventType.OnClick, function()
        ChatHelper.Chat(UI_Chat_Channel.Team)
    end)
    -- 分享按钮BtnShareStage由scriptShare管理
end

function UIPanelYangDaoSettleDataView:RegEvent()
    Event.Reg(self, "SCENE_BEGIN_LOAD", function()
        UIMgr.Close(self)
    end)
    Event.Reg(self, EventType.HideAllHoverTips, function()
        UIHelper.SetVisible(self.WidgetPersonalCardLeft, false)
        UIHelper.SetVisible(self.WidgetPersonalCardRight, false)
    end)

    self.scriptShare = self.scriptShare or UIHelper.GetBindScript(self.WidgetShare)
    self.scriptShare:OnEnter(nil, true)
end

function UIPanelYangDaoSettleDataView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelYangDaoSettleDataView:UpdateInfo()
    if not self.tBattleFieldInfo then
        return
    end

    self:UpdateBattleDataInfo()

    local bWin = self.tBattleFieldInfo.bWin or false
    UIHelper.SetVisible(self.WidgetDraw, false) -- 没有平局
    UIHelper.SetVisible(self.WidgetVictory, bWin)
    UIHelper.SetVisible(self.WidgetDefeat, not bWin)

    local tStatistics = self.tBattleFieldInfo and self.tBattleFieldInfo.tStatistics
    local tMyData = self.tBattleFieldInfo and self.tBattleFieldInfo.tMyData
    local tForceIDList = {}
    for _, tData in ipairs(tStatistics or {}) do
        tForceIDList[tData.BattleFieldSide] = tForceIDList[tData.BattleFieldSide] or {}
        table.insert(tForceIDList[tData.BattleFieldSide], {dwForceID = tData.ForceID})
    end

    local szTeamName1 = ArenaData.GetAutoName(tForceIDList[0])
    local szTeamName2 = ArenaData.GetAutoName(tForceIDList[1])
    UIHelper.SetString(self.LabelTeam1, UIHelper.GBKToUTF8(szTeamName1))
    UIHelper.SetString(self.LabelTeam2, UIHelper.GBKToUTF8(szTeamName2))

    self:UpdateTitleState()
    self:UpdateBtnState()
    UIHelper.SetVisible(self.RichTextTime, false)

    local _, _, nBeginTime, nEndTime = GetBattleFieldPQInfo()
    local nCurrentTime = GetGSCurrentTime()
    local _, nBattleStartTime, nBattleEndTime = ArenaTowerData.GetTitleInfo()
    if nBattleStartTime and nBattleStartTime > 0 then
        nBeginTime = nBattleStartTime
    end
    if nBattleEndTime and nBattleEndTime > 0 then
        nEndTime = nBattleEndTime
    end
    if nBeginTime and nBeginTime > 0 then
        local nTime = 0
        if nEndTime ~= 0 and nCurrentTime > nEndTime then
            nTime = nEndTime - nBeginTime
        else
            nTime = nCurrentTime - nBeginTime
        end
        local szTime = nTime > 0 and UIHelper.GetDeltaTimeText(nTime, false) or ("0" .. g_tStrings.STR_BUFF_H_TIME_S)
        UIHelper.SetString(self.LabelBattleTotalTime, string.format("%s%s", g_tStrings.STR_BATTLEFIELD_TIME_USED, szTime))
        UIHelper.SetVisible(self.LabelBattleTotalTime, true)
    else
        UIHelper.SetVisible(self.LabelBattleTotalTime, false)
    end

    local nDiffMode = tMyData and tMyData[PQ_STATISTICS_INDEX.SPECIAL_OP_1] or ArenaTowerDiffMode.Practice
    local nLevelIndex = tMyData and tMyData[PQ_STATISTICS_INDEX.SPECIAL_OP_2] or 0
    if nDiffMode == ArenaTowerDiffMode.Practice then
        UIHelper.SetVisible(self.ImgIcon, true)
        UIHelper.SetSpriteFrame(self.ImgIcon, szImgIconPracticePath)
        UIHelper.SetString(self.LabelLevelTypePractice, string.format("普通模式 - 第 %d 层", nLevelIndex))
        UIHelper.SetVisible(self.LabelLevelTypePractice, true)
        UIHelper.SetVisible(self.LabelLevelTypeChallenge, false)
    elseif nDiffMode == ArenaTowerDiffMode.Challenge  then
        UIHelper.SetVisible(self.ImgIcon, true)
        UIHelper.SetSpriteFrame(self.ImgIcon, szImgIconChallengePath)
        UIHelper.SetString(self.LabelLevelTypeChallenge, string.format("挑战模式 - 第 %d 层", nLevelIndex))
        UIHelper.SetVisible(self.LabelLevelTypePractice, false)
        UIHelper.SetVisible(self.LabelLevelTypeChallenge, true)
    else
        UIHelper.SetVisible(self.ImgIcon, false)
        UIHelper.SetVisible(self.LabelLevelTypePractice, false)
        UIHelper.SetVisible(self.LabelLevelTypeChallenge, false)
    end

    local tLevelConfig = ArenaTowerData.GetLevelConfig(nLevelIndex)
    local szLevelName = UIHelper.GBKToUTF8(tLevelConfig and tLevelConfig.szName or "")
    UIHelper.SetString(self.LabelLevelName, szLevelName)

    local bLevelDown = tMyData and tMyData[PQ_STATISTICS_INDEX.SPECIAL_OP_7] == 1
    UIHelper.SetVisible(self.WidgetLevelDownHint, bLevelDown)

    local bReward = false
    local nArenaTowerAward = tMyData and tMyData[PQ_STATISTICS_INDEX.AWARD_1] or 0 -- 鸣铮玉
    local nPrestige = tMyData and tMyData[PQ_STATISTICS_INDEX.AWARD_2] or 0 --威名点
    local nTitlePoint = tMyData and tMyData[PQ_STATISTICS_INDEX.AWARD_3] or 0 --战阶
    local nTianJiToken = tMyData and tMyData[PQ_STATISTICS_INDEX.AWARD_4] or 0 -- 天机筹

    local function AddCurrencyPrefab(szName, szCurrencyName, nCount)
        if nCount > 0 then
            bReward = true
            local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetAwardItem1, self.LayoutRewardList)
            itemScript:OnEnter(szName, nCount)
            itemScript:SetIconCount()
            itemScript:SetSingleClickCallback(function()
                TipsHelper.ShowCurrencyTips(itemScript._rootNode, szCurrencyName, nCount)
            end)
        end
    end

    AddCurrencyPrefab("鸣铮玉", CurrencyType.ArenaTowerAward, nArenaTowerAward)
    AddCurrencyPrefab("威名", CurrencyType.Prestige, nPrestige)
    AddCurrencyPrefab("战阶", CurrencyType.TitlePoint, nTitlePoint)
    AddCurrencyPrefab("天机筹", CurrencyType.TianJiToken, nTianJiToken)
    UIHelper.SetVisible(self.WidgetReward, bReward)
    UIHelper.LayoutDoLayout(self.LayoutRewardList)
end

function UIPanelYangDaoSettleDataView:UpdateTitleState()
    -- local bShowPraise = self.tBattleFieldInfo and table.get_len(self.tBattleFieldInfo.tPraiseList) > 0 or false
    UIHelper.SetVisible(self.BtnPraiseAll, false) -- 扬刀大会没有点赞
    UIHelper.SetVisible(self.BtnReport, false) -- 扬刀大会没有举报
    UIHelper.LayoutDoLayout(self.LayoutRightTopBtn)
end

function UIPanelYangDaoSettleDataView:UpdateBtnState()
    local tMyData = self.tBattleFieldInfo and self.tBattleFieldInfo.tMyData
    local nLevelIndex = tMyData and tMyData[PQ_STATISTICS_INDEX.SPECIAL_OP_2] or 0
    local bLastLevel = nLevelIndex >= ArenaTowerData.MAX_LEVEL_COUNT
    local tLevelConfig = ArenaTowerData.GetLevelConfig(nLevelIndex)
    local bShopRound = tLevelConfig and tLevelConfig.bShopRound or false
    local bWin = self.tBattleFieldInfo.bWin or false
    local bCanChooseBless = ArenaTowerData.CanChooseBless()

    -- UIHelper.SetVisible(self.BtnRest, not bLastLevel or not bWin)
    UIHelper.SetVisible(self.BtnRest, false)
    UIHelper.SetVisible(self.BtnRetry, not bLastLevel and not bWin)
    UIHelper.SetVisible(self.BtnBless, bWin and bCanChooseBless and not bLastLevel)
    UIHelper.SetVisible(self.BtnNext, bWin and bLastLevel)
    UIHelper.SetVisible(self.BtnMvp, self.funcClickBackMvpCallback ~= nil)
    UIHelper.SetVisible(self.WidgetTagSpecial, bWin and bShopRound)

    UIHelper.LayoutDoLayout(self.WidgetRightDown)
end

function UIPanelYangDaoSettleDataView:UpdateBattleDataInfo()
    if not self.tBattleFieldInfo then
        return
    end

    local tStatistics = self.tBattleFieldInfo and self.tBattleFieldInfo.tStatistics
    local tExcellentData = self.tBattleFieldInfo and self.tBattleFieldInfo.tExcellentData
    local nClientPlayerSide = self.tBattleFieldInfo and self.tBattleFieldInfo.nClientPlayerSide

    UIHelper.RemoveAllChildren(self.LayoutPlayerLeft)
    UIHelper.RemoveAllChildren(self.LayoutPlayerRight)

    for _, tData in ipairs(tStatistics or {}) do
        local tExcellent = tExcellentData[tData.dwPlayerID]
        if tData.nBattleFieldSide == nClientPlayerSide then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetYangDaoSettleDataLeft, self.LayoutPlayerLeft, tData, tExcellent)
            script:SetWidgetPersonalCard(self.WidgetPersonalCardLeft)
        else
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetYangDaoSettleDataRight, self.LayoutPlayerRight, tData, tExcellent)
            script:SetWidgetPersonalCard(self.WidgetPersonalCardRight)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutPlayerLeft)
    UIHelper.LayoutDoLayout(self.LayoutPlayerRight)
end

return UIPanelYangDaoSettleDataView