-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetLottoNum
-- Date: 2026-04-20 16:46:16
-- Desc: 大富翁 乐透-数字 WidgetLottoNum
-- ---------------------------------------------------------------------------------

local UIWidgetLottoNum = class("UIWidgetLottoNum")

function UIWidgetLottoNum:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetLottoNum:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetLottoNum:BindUIEvent()
    UIHelper.BindUIEvent(self.TogLottoNum, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected and self.fnClickCallback then
            self.fnClickCallback()
        end
    end)
end

function UIWidgetLottoNum:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetLottoNum:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetLottoNum:SetLotteryNum(szLotteryNum)
    UIHelper.SetString(self.LabelNum, szLotteryNum)
end

function UIWidgetLottoNum:SetChosen(bSelfChosen, bOtherChosen)
    UIHelper.SetVisible(self.ImgDone, bSelfChosen)
    UIHelper.SetVisible(self.ImgBg_Gray, bSelfChosen or bOtherChosen)
end

function UIWidgetLottoNum:SetWinning(bWinning)
    UIHelper.SetVisible(self.ImgBg_Winning, bWinning)
end

function UIWidgetLottoNum:SetClickCallback(fnClickCallback)
    self.fnClickCallback = fnClickCallback
end

function UIWidgetLottoNum:SetCanSelect(bCanSelect)
    UIHelper.SetCanSelect(self.TogLottoNum, bCanSelect, nil, false)
end

function UIWidgetLottoNum:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogLottoNum, bSelected)
end

return UIWidgetLottoNum