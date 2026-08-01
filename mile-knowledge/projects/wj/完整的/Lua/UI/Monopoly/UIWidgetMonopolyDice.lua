local UIWidgetMonopolyDice = class("UIWidgetMonopolyDice")

local DICE_NUM = 3  -- WndCheckBox_Dice 总数量
local DICE_ANIM_TIME = 3000
local DICE_RESULT_SHOW_TIME = 3000
local DICE_FRAME_BASE = 22

local ROLL_IMAGE_FRAME = {
    "UIAtlas2_Baizhan_LevelChoose_Img_Dice01",
    "UIAtlas2_Baizhan_LevelChoose_Img_Dice02",
    "UIAtlas2_Baizhan_LevelChoose_Img_Dice03",
    "UIAtlas2_Baizhan_LevelChoose_Img_Dice04",
    "UIAtlas2_Baizhan_LevelChoose_Img_Dice05",
    "UIAtlas2_Baizhan_LevelChoose_Img_Dice06",
}

local DEFAULT_ROLL_IMAGE_PATH = "UIAtlas2_HomeIdentify_HomeFish_Btn_Fish"

function UIWidgetMonopolyDice:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitData()
    self:UpdateInfo()
end

function UIWidgetMonopolyDice:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonopolyDice:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnRollDice, EventType.OnClick, function ()
        MonopolyData.SendServerOperate(MINI_GAME_OPERATE_TYPE.SERVER_OPERATE, DFW_OPERATE_UP_ACTION_ROLLDICE, self.nSelectedDice)
    end)

    for nIndex, TogDice in ipairs(self.TogDiceList) do
        UIHelper.BindUIEvent(TogDice, EventType.OnSelectChanged, function (_, bSelected)
            if not bSelected then return end
            self.nSelectedDice = nIndex
        end)
    end
end

function UIWidgetMonopolyDice:RegEvent()
    Event.Reg(self, EventType.OnMonopolyBeginDiceShow, function ()
        self:BeginDiceShow()
    end)
end

function UIWidgetMonopolyDice:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetMonopolyDice:InitData()
    self.nPlayerIndex = MonopolyData.GetClientPlayerIndex() or 0
    -- 可用骰子数
    self.nModifyNum = DFW_GetPlayerModifyNum(self.nPlayerIndex) or 0
    -- 玩家当前选中的骰子编号（1~DICE_NUM，默认选中1号）
    self.nSelectedDice = 1
    self.bDiceAnimating = false
    self.nAnimEndTick = 0
    self.bResultShowing = false
    self.nResultEndTick = 0
    self.nResultCount = 1
    self.tDiceResult = {1, 1, 1}
end

function UIWidgetMonopolyDice:CalcDiceResultCount(tDiceResult)
    if type(tDiceResult) ~= "table" then
        return 0
    end

    local nResultCount = 0
    for _, nValue in ipairs(tDiceResult) do
        if (tonumber(nValue) or 0) ~= 0 then
            nResultCount = nResultCount + 1
        end
    end
    return nResultCount
end

function UIWidgetMonopolyDice:StartDiceResultShow()
    self.tDiceResult = DFW_GetPublicStepsNumList()
    self.nResultCount = self:CalcDiceResultCount(self.tDiceResult)
    self.bDiceAnimating = true
    self.nAnimEndTick = GetTickCount() + DICE_ANIM_TIME
    self.bResultShowing = false
    self.nResultEndTick = 0

    TipsHelper.ShowImportantBlueTip(string.format("本次总点数为%d", self.nResultCount), false, DICE_RESULT_SHOW_TIME/1000)
end

function UIWidgetMonopolyDice:UpdateInfo()
    self:UpdateState()

    for i = 1, DICE_NUM do
        local WidgetLock = self.WidgetDiceLockList[i]
        if WidgetLock then
            local bEnable = i <= self.nModifyNum
            UIHelper.SetVisible(WidgetLock, bEnable)
        end
    end
end

function UIWidgetMonopolyDice:UpdateStageVisible(bDiceShow)
    -- VK_TODO:用来切摇骰子动画的
end

function UIWidgetMonopolyDice:PlayDiceAnimation()
    -- VK_TODO:等方案等预制等资源
    for i = 1, DICE_NUM do
        local bShow = i <= self.nResultCount
    end
end

function UIWidgetMonopolyDice:ShowDiceResult()
    for i = 1, DICE_NUM do
        local bShow = i <= self.nResultCount
        local nValue = self.tDiceResult[i] or 1
    end
end

function UIWidgetMonopolyDice:UpdateState()
    local nTableState = MonopolyData.GetGameState()
    local bShowDiceAnimation = nTableState ~= DFW_CONST_TABLE_STATE_DICE
    self:UpdateStageVisible(bShowDiceAnimation)
end

function UIWidgetMonopolyDice:BeginDiceShow()
    self:UpdateState()

    self:StartDiceResultShow()

    self:UpdateStageVisible(false)
    self:PlayDiceAnimation()
end

return UIWidgetMonopolyDice