-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAddIncomePopView
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIAddIncomePopView = class("UIAddIncomePopView")

local MAX_COMMENT_LENGTH = 20
function UIAddIncomePopView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIAddIncomePopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIAddIncomePopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function ()
        self:OnConfirm()
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxReason, function ()
        local szComment = UIHelper.GetText(self.EditBoxReason)
        local nCharNum = GetStringCharCount(szComment)
        local szLimit = string.format("%d/%d", nCharNum, MAX_COMMENT_LENGTH)
        UIHelper.SetString(self.LabelLimit, szLimit)
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxZhuan, function ()
        local szBrick = UIHelper.GetText(self.EditBoxZhuan)
        UIHelper.SetText(self.EditBoxZhuan, tostring(tonumber(szBrick) or 0))
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxJin, function ()
        local szGold = UIHelper.GetText(self.EditBoxJin)
        UIHelper.SetText(self.EditBoxJin, tostring(tonumber(szGold) or 0))
    end)
end

function UIAddIncomePopView:RegEvent()
    Event.Reg(self, EventType.OnTouchViewBackGround, function ()
        UIMgr.Close(self)
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardOpen, function(editbox)
        if editbox == self.EditBoxZhuan then
            UIHelper.SetEditBoxGameKeyboardRange(self.EditBoxZhuan, 0, 9999)
        elseif editbox == self.EditBoxJin then
            UIHelper.SetEditBoxGameKeyboardRange(self.EditBoxJin, 0, 9999)
        end        
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        if editbox == self.EditBoxZhuan then
            local szBrick = UIHelper.GetText(self.EditBoxZhuan)
            UIHelper.SetText(self.EditBoxZhuan, tostring(tonumber(szBrick) or 0))
        elseif editbox == self.EditBoxJin then
            local szGold = UIHelper.GetText(self.EditBoxJin)
            UIHelper.SetText(self.EditBoxJin, tostring(tonumber(szGold) or 0))
        end
    end)
end

function UIAddIncomePopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAddIncomePopView:UpdateInfo()
    
end

function UIAddIncomePopView:OnConfirm()
    local szBrick = UIHelper.GetText(self.EditBoxZhuan)
    local szGold = UIHelper.GetText(self.EditBoxJin)
    local szComment = UIHelper.GetText(self.EditBoxReason)
    local nBrick = tonumber(szBrick) or 0
    local nGold = tonumber(szGold) or 0
    local nMoneyInGolds = nBrick * 10000 + nGold

    local szMoney = ShopData.GetPriceRichText(nBrick, nGold, 0, 0)
    local szContent = string.format("你确认往团队中追加资金%s吗？", szMoney)
    UIHelper.ShowConfirm(szContent, function ()
        AuctionData.AddPenaltyRecord(UI_GetClientPlayerID(), nMoneyInGolds, szComment)
        UIMgr.Close(self)
    end, nil, true)
end

return UIAddIncomePopView