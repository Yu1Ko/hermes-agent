-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIMonopolyLottoView
-- Date: 2026-04-20 11:07:42
-- Desc: 大富翁-乐透 PanelRichMan_Lotto
-- ---------------------------------------------------------------------------------

local UIMonopolyLottoView = class("UIMonopolyLottoView")

local LOTTERY_BALL_NUM = 30
local LOTTERY_CHOOSE_MAX = 3
local STAGE_MAIN_CONTENT = 1
local STAGE_LOTTERY_RESULT = 2
local REEL_ANIM_DURATION = 3

-- copy from DX Revision: 1831381
-----------------------------DataModel------------------------------
local DataModel = {}

function DataModel.ResetPlayerChooseData()
    DataModel.tPlayerChoose = {}
    DataModel.tNumOwner = {}

    for i = 1, DFW_PLAYERNUM do
        DataModel.tPlayerChoose[i] = {}
    end
end

function DataModel.BuildNumOwner()
    DataModel.tNumOwner = {}
    for nPlayerIndex = 1, DFW_PLAYERNUM do
        local tChoose = DataModel.tPlayerChoose[nPlayerIndex] or {}
        for _, nNum in ipairs(tChoose) do
            if type(nNum) == "number" and nNum > 0 and nNum <= LOTTERY_BALL_NUM then
                DataModel.tNumOwner[nNum] = nPlayerIndex
            end
        end
    end
end

function DataModel.GetPlayerChoose(nPlayerIndex)
    if not nPlayerIndex or nPlayerIndex <= 0 then
        return {}
    end

    if not DataModel.tPlayerChoose[nPlayerIndex] then
        DataModel.tPlayerChoose[nPlayerIndex] = {}
    end

    return DataModel.tPlayerChoose[nPlayerIndex]
end

function DataModel.RefreshPlayerChooseFromGame(nPlayerIndex)
    if not nPlayerIndex or nPlayerIndex <= 0 then
        return
    end

    local tChoose = DFW_GetPlayerLotteryChoosen(nPlayerIndex) or {}
    local tSaved = {}
    for _, nNum in ipairs(tChoose) do
        if type(nNum) == "number" and nNum > 0 and nNum <= LOTTERY_BALL_NUM then
            if #tSaved < LOTTERY_CHOOSE_MAX then
                table.insert(tSaved, nNum)
            end
        end
    end

    DataModel.tPlayerChoose[nPlayerIndex] = tSaved
end

function DataModel.RefreshAllPlayerChooseFromGame()
    for nPlayerIndex = 1, DFW_PLAYERNUM do
        DataModel.RefreshPlayerChooseFromGame(nPlayerIndex)
    end
    DataModel.BuildNumOwner()
end

function DataModel.AddChoose(nPlayerIndex, nNum)
    if not nPlayerIndex or nPlayerIndex <= 0 then
        return false
    end
    if not nNum or nNum <= 0 or nNum > LOTTERY_BALL_NUM then
        return false
    end

    local tChoose = DataModel.GetPlayerChoose(nPlayerIndex)
    for _, nExist in ipairs(tChoose) do
        if nExist == nNum then
            return true
        end
    end

    if #tChoose >= LOTTERY_CHOOSE_MAX then
        return false
    end

    table.insert(tChoose, nNum)
    DataModel.BuildNumOwner()
    return true
end

function DataModel.RemoveChoose(nPlayerIndex, nNum)
    local tChoose = DataModel.GetPlayerChoose(nPlayerIndex)
    for i, nExist in ipairs(tChoose) do
        if nExist == nNum then
            table.remove(tChoose, i)
            DataModel.BuildNumOwner()
            return true
        end
    end
    return false
end

function DataModel.IsSelfChosen(nNum)
    local nOwner = DataModel.tNumOwner[nNum]
    return nOwner and nOwner == DataModel.nClientPlayerIndex
end

function DataModel.IsOtherChosen(nNum)
    local nOwner = DataModel.tNumOwner[nNum]
    return nOwner and nOwner ~= DataModel.nClientPlayerIndex
end

function DataModel.RefreshLotteryBonus()
    local nLotteryBonus = DFW_GetLotteryBonus() or 0
    if nLotteryBonus < 0 then
        nLotteryBonus = 0
    end

    DataModel.nLotteryBonus = nLotteryBonus
end

function DataModel.Init()
    DataModel.nClientPlayerIndex = MonopolyData.GetClientPlayerIndex() or 1
    DataModel.nStage = STAGE_MAIN_CONTENT
    DataModel.nWinningNum = 0
    DataModel.nLotteryBonus = 0
    DataModel.bReelAnimating = false
    DataModel.nReelEndTime = 0
    DataModel.nLastReelUpdateTime = 0

    DataModel.ResetPlayerChooseData()
    DataModel.RefreshLotteryBonus()
    DataModel.RefreshAllPlayerChooseFromGame()

    local nGameState = MonopolyData.GetGameState()
    if nGameState then
        self:UpdateStageState(nGameState)
    end
end

function DataModel.UnInit()
    for i, v in pairs(DataModel) do
        if type(v) ~= "function" then
            DataModel[i] = nil
        end
    end
end

-----------------------------View------------------------------
function UIMonopolyLottoView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.LayoutMoney, CurrencyType.MonopolyMoney)
        UIHelper.CascadeDoLayoutDoWidget(self.LayoutMoney, true, true)

        DataModel.Init()
        math.randomseed(GetCurrentTime())
        Timer.AddFrameCycle(self, 1, function()
            self:OnUpdate()
        end)
    end
    self:UpdateInfo()
end

function UIMonopolyLottoView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    DataModel.UnInit()

    if self.bActive then
        MonopolyData.SendServerOperate(MINI_GAME_OPERATE_TYPE.SERVER_OPERATE, DFW_OPERATE_UP_LOTTERYDRAW_CLOSE)
    end
end

function UIMonopolyLottoView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnInfo, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetRichManTips, self.BtnInfo, TipsLayoutDir.TOP_LEFT, "大乐透玩法", "怎么玩的什么时候开奖balabala")
    end)
    UIHelper.BindUIEvent(self.BtnCanel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIMonopolyLottoView:RegEvent()
    Event.Reg(self, EventType.OnMonopolyLotteryBegin, function()
        self.bActive = true
    end)
    Event.Reg(self, EventType.OnMonopolyLotteryUpdataPlayerChoosen, function(nPlayerIndex)
        self:UpdataPlayerLotteryChoosen(nPlayerIndex)
    end)
    Event.Reg(self, EventType.OnMonopolyLotterySwitchToResultStage, function()
        self:SwitchToResultStage()
    end)
end

function UIMonopolyLottoView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIMonopolyLottoView:GetNumText(nNum)
    if not nNum or nNum < 0 then
        nNum = 0
    end
    return string.format("%02d", nNum)
end

function UIMonopolyLottoView:SetStageVisible()
    UIHelper.SetVisible(self.LayoutLotto, DataModel.nStage == STAGE_MAIN_CONTENT)
    UIHelper.SetVisible(self.WidgetWinningResults, DataModel.nStage == STAGE_LOTTERY_RESULT)
end

function UIMonopolyLottoView:UpdatePrizePool()
    DataModel.RefreshLotteryBonus()
    local szText = "奖池：" .. (DataModel.nLotteryBonus or 0)
    UIHelper.SetString(self.LabelJackpotNum, szText)
    UIHelper.SetString(self.LabelJackpotNum2, szText)
end

function UIMonopolyLottoView:UpdateListHintCost(nPlayerIndex)
    if not nPlayerIndex or nPlayerIndex <= 0 then
        nPlayerIndex = DataModel.nClientPlayerIndex
    end

    local nLotteryBonus = DFW_GetPlayerLotteryBonus(nPlayerIndex) or 0
    if nLotteryBonus < 0 then
        nLotteryBonus = 0
    end

    local szIconPath = "UIAtlas2_YangDao_YangDaoPanel01_ImgReward_Pra02" -- TODO
    local szText = string.format("买定离手！每注花费%d <img src='%s' width='19' height='21' />", nLotteryBonus, szIconPath)
    UIHelper.SetRichText(self.RichTextLottoPirce, szText)
end

function UIMonopolyLottoView:UpdateMainContent()
    self:UpdatePrizePool()
    self:UpdateListHintCost(DataModel.nClientPlayerIndex)

    UIHelper.SetString(self.LabelTitle, "大乐透")

    self.tScriptLottoNum = self.tScriptLottoNum or {}
    for i = 1, LOTTERY_BALL_NUM do
        local nNum = i
        local bSelfChosen = DataModel.IsSelfChosen(nNum)
        local bOtherChosen = DataModel.IsOtherChosen(nNum)
        self.tScriptLottoNum[nNum] = self.tScriptLottoNum[nNum] or UIHelper.AddPrefab(PREFAB_ID.WidgetLottoNum, self.LayoutLottoNum)
        self.tScriptLottoNum[nNum]:SetLotteryNum(self:GetNumText(nNum))
        self.tScriptLottoNum[nNum]:SetChosen(bSelfChosen, bOtherChosen)
        self.tScriptLottoNum[nNum]:SetCanSelect(not bSelfChosen and not bOtherChosen)
        self.tScriptLottoNum[nNum]:SetClickCallback(function()
            if self.selectedBall and self.selectedBall ~= self.tScriptLottoNum[nNum] then
                self.selectedBall:SetSelected(false)
            end
            self.selectedBall = self.tScriptLottoNum[nNum]
            self:OnLotteryNumClick(nNum)
        end)
    end

    UIHelper.LayoutDoLayout(self.LayoutLottoNum)
end

function UIMonopolyLottoView:UpdateResultLeftCol()
    local szWinningNum = self:GetNumText(DataModel.nWinningNum)
    UIHelper.SetRichText(self.RichTextNum, FormatString(g_tStrings.STR_MONOPOLY_LOTTERY_WINNING_NUM, szWinningNum))
    --TODO 动画节点里的数字？
end

function UIMonopolyLottoView:UpdateLotteryResult()
    UIHelper.SetString(self.LabelTitle, "开奖")

    UIHelper.RemoveAllChildren(self.LayoutPlayer)
    for nPlayerIndex = 1, DFW_PLAYERNUM do
        local scriptPlayer = UIHelper.AddPrefab(PREFAB_ID.WidgetPlayer_Results, self.LayoutPlayer, nPlayerIndex)
        local tChoose = DataModel.GetPlayerChoose(nPlayerIndex)
        scriptPlayer:UpdateLottoNum(tChoose, DataModel.nWinningNum)
    end

    UIHelper.LayoutDoLayout(self.LayoutPlayer)
    self:UpdateResultLeftCol()
end

function UIMonopolyLottoView:UpdateReelRolling()
    local nRollL = math.random(1, LOTTERY_BALL_NUM)
    local nRollM = math.random(1, LOTTERY_BALL_NUM)
    local nRollR = math.random(1, LOTTERY_BALL_NUM)

    -- local hNumL = hLeftCol:Lookup("Handle_ResultReelStrip/Handle_ResultReelSlotL/Text_ResultReelNumL")
    -- local hNumM = hLeftCol:Lookup("Handle_ResultReelStrip/Handle_ResultReelSlotM/Text_ResultReelNumM")
    -- local hNumR = hLeftCol:Lookup("Handle_ResultReelStrip/Handle_ResultReelSlotR/Text_ResultReelNumR")

    -- if hNumL then
    --     hNumL:SetText(View.GetNumText(nRollL))
    -- end
    -- if hNumM then
    --     hNumM:SetText(View.GetNumText(nRollM))
    -- end
    -- if hNumR then
    --     hNumR:SetText(View.GetNumText(nRollR))
    -- end
end

function UIMonopolyLottoView:FinishReel()
    DataModel.bReelAnimating = false
    self:UpdateResultLeftCol()
    self:UpdateLotteryResult()
end

function UIMonopolyLottoView:StartReel()
    DataModel.bReelAnimating = true
    DataModel.nReelEndTime = GetCurrentTime() + REEL_ANIM_DURATION
    DataModel.nLastReelUpdateTime = 0
    self:UpdateReelRolling()
end

function UIMonopolyLottoView:UpdateInfo()
    self:SetStageVisible()

    if DataModel.nStage == STAGE_MAIN_CONTENT then
        self:UpdateMainContent()
    elseif DataModel.nStage == STAGE_LOTTERY_RESULT then
        self:UpdateLotteryResult()
    end
end

-----------------------------Controller------------------------------
function UIMonopolyLottoView:OnLotteryNumClick(nNum)
    if not nNum or nNum <= 0 then
        return
    end

    if DataModel.IsOtherChosen(nNum) or DataModel.IsSelfChosen(nNum) then
        return
    end

    MonopolyData.SendServerOperate(MINI_GAME_OPERATE_TYPE.SERVER_OPERATE, DFW_OPERATE_UP_LOTTERYBET_CHOOSEN, nNum)
end

function UIMonopolyLottoView:OnUpdate()
    if not DataModel.bReelAnimating then
        return
    end

    local nNow = GetCurrentTime()
    if nNow >= DataModel.nReelEndTime then
        self:FinishReel()
        return
    end

    if DataModel.nLastReelUpdateTime ~= nNow then
        DataModel.nLastReelUpdateTime = nNow
        self:UpdateReelRolling()
    end
end

-- 切换到押注选择阶段
function UIMonopolyLottoView:SwitchToChooseStage()
    DataModel.nStage = STAGE_MAIN_CONTENT
    DataModel.bReelAnimating = false
    self:UpdateInfo()
end

-- 切换到开奖结果阶段
-- @param nWinningNum 中奖号码
function UIMonopolyLottoView:SwitchToResultStage()
    local nWinningNum = DFW_GetTableLotteryResult()
    DataModel.nWinningNum = nWinningNum or 0
    DataModel.nStage = STAGE_LOTTERY_RESULT
    self:UpdateInfo()
    self:StartReel()
end

-- 根据阶段状态切换到对应阶段
-- @param nState 游戏阶段状态
function UIMonopolyLottoView:UpdateStageState(nState)
    if nState == DFW_CONST_TABLE_STATE_LOTTERYBET then
        self:SwitchToChooseStage()
    elseif nState == DFW_CONST_TABLE_STATE_LOTTERYDRAW then
        self:SwitchToResultStage()
    end
end

-- 同步玩家的押注号码更新
-- @param nPlayerIndex 玩家索引
function UIMonopolyLottoView:UpdataPlayerLotteryChoosen(nPlayerIndex)
    if not nPlayerIndex or nPlayerIndex <= 0 then
        return
    end

    DataModel.RefreshPlayerChooseFromGame(nPlayerIndex)
    DataModel.BuildNumOwner()

    self:UpdateInfo()
end

-- 刷新指定玩家的押注数据
function UIMonopolyLottoView:RefreshLotteryChooseByPlayer(nPlayerIndex)
    if nPlayerIndex == nil then
        nPlayerIndex = arg4
    end

    DataModel.RefreshPlayerChooseFromGame(nPlayerIndex)
    DataModel.BuildNumOwner()

    self:UpdateInfo()
end

-- 刷新所有玩家的押注数据
function UIMonopolyLottoView:RefreshLotteryChooseAll()
    DataModel.RefreshAllPlayerChooseFromGame()
    self:UpdateInfo()
end

return UIMonopolyLottoView