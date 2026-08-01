-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetPlayer_Results
-- Date: 2026-04-20 17:24:10
-- Desc: 大富翁 乐透-右侧玩家信息；小游戏玩家头像 WidgetPlayer_Results
-- ---------------------------------------------------------------------------------

local UIWidgetPlayer_Results = class("UIWidgetPlayer_Results")

local LOTTERY_CHOOSE_MAX = 3

function UIWidgetPlayer_Results:OnEnter(nPlayerIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nPlayerIndex = nPlayerIndex
    self:UpdateInfo()
end

function UIWidgetPlayer_Results:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetPlayer_Results:BindUIEvent()

end

function UIWidgetPlayer_Results:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetPlayer_Results:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetPlayer_Results:UpdateInfo()
    self.scriptName = self.scriptName or UIHelper.AddPrefab(PREFAB_ID.WidgetPlayerName_Color, self.WidgetName_Color)
    MonopolyData.SetPlayerBaseInfo(self, self.nPlayerIndex)
end

function UIWidgetPlayer_Results:UpdateLottoNum(tChoose, nWinningNum)
    UIHelper.SetVisible(self.LayoutLottoNum, true)
    UIHelper.SetVisible(self.LabelScore, false)
    UIHelper.RemoveAllChildren(self.LayoutLottoNum)

    local bPlayerWinning = false
    for i = 1, LOTTERY_CHOOSE_MAX do
        local nNum = tChoose and tChoose[i]
        local bWinning = nNum and nNum == nWinningNum
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetLottoNum, self.LayoutLottoNum)
        script:SetCanSelect(false)
        script:SetLotteryNum(nNum and string.format("%02d", nNum) or "")
        script:SetWinning(bWinning)

        -- 有数字且未中奖的置灰
        local bGray = nNum and not bWinning or false
        script:SetChosen(false, bGray)

        if bWinning then
            bPlayerWinning = true
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutLottoNum)

    -- 未中奖的置灰
    UIHelper.SetOpacity(self.WidgetHead, bPlayerWinning and 255 or 128)
    UIHelper.SetOpacity(self.WidgetName_Color, bPlayerWinning and 255 or 128)
end

function UIWidgetPlayer_Results:UpdateScore(nScore, nAddScore)
    UIHelper.SetVisible(self.LabelScore, true)
    UIHelper.SetVisible(self.LayoutLottoNum, false)
    -- TODO 小游戏加分
end

function UIWidgetPlayer_Results:SetName(szName)
    if self.scriptName then
        self.scriptName:SetName(szName)
    end
end

function UIWidgetPlayer_Results:SetColorBg(szBgPath)
    if self.scriptName then
        self.scriptName:SetColorBg(szBgPath)
    end
end

return UIWidgetPlayer_Results