-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPaySubsidyPopView
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPaySubsidyPopView = class("UIPaySubsidyPopView")

local MAX_COMMENT_LENGTH = 20
function UIPaySubsidyPopView:OnEnter(dwPlayerID)
    if not dwPlayerID then
        return
    end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwPlayerID = dwPlayerID
    self:UpdateInfo()
end

function UIPaySubsidyPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIPaySubsidyPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnHint, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnHint, g_tStrings.GOLD_SET_EXPAY_FAILED)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function ()
        local szBrick = UIHelper.GetText(self.EditBoxBrick)
        local szGold = UIHelper.GetText(self.EditBoxGold)
        local szComment = UIHelper.GetText(self.EditBoxReason)
        local nBrick = tonumber(szBrick) or 0
        local nGold = tonumber(szGold) or 0
        local nTotalGold = nBrick*10000 + nGold
        if nTotalGold < 0 then
            TipsHelper.ShowImportantYellowTip("补贴金额太低")
            return
        end

        if nTotalGold > GetClientTeam().nInComeMoney * 0.2 then
            TipsHelper.ShowImportantYellowTip("补助金额不能高于团队总收入的两成")
            return
        end
        
        AuctionData.UpdateTeamExPays(self.dwPlayerID, nTotalGold, szComment)
        UIMgr.Close(self)
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxBrick, function ()
        self:RefreshMoney()
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxGold, function ()
        self:RefreshMoney()
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxReason, function ()
        local szComment = UIHelper.GetText(self.EditBoxReason)
        local nCharNum = GetStringCharCount(szComment)
        local szLimit = string.format("%d/%d", nCharNum, MAX_COMMENT_LENGTH)
        UIHelper.SetString(self.LabelLimit, szLimit)
    end)
end

function UIPaySubsidyPopView:RegEvent()
    Event.Reg(self, EventType.OnGameNumKeyboardOpen, function(editbox)
        if editbox == self.EditBoxBrick then
            UIHelper.SetEditBoxGameKeyboardRange(self.EditBoxBrick, 0, 9999)
        elseif editbox == self.EditBoxGold then
            UIHelper.SetEditBoxGameKeyboardRange(self.EditBoxGold, 0, 9999)
        end
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        if editbox == self.EditBoxBrick then
            self:RefreshMoney()
        elseif editbox == self.EditBoxGold then
            self:RefreshMoney()
        end
    end)
end

function UIPaySubsidyPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPaySubsidyPopView:UpdateInfo()
    local nInComeMoney = GetClientTeam().nInComeMoney
    local nBrick = math.floor(nInComeMoney * 0.2 / 10000)
    local nGold = math.floor(nInComeMoney * 0.2 % 10000)
    self.nInComeMoney = nInComeMoney
    UIHelper.SetString(self.LabelMoney_ZhuanLimit, tostring(nBrick))
    UIHelper.SetString(self.LabelMoney_JinLimit, tostring(nGold))

    local color = cc.c4b(215, 246,255, 75)
    UIHelper.SetTextColor(self.PlaceHolderZhuan, color)
    UIHelper.SetTextColor(self.PlaceHolderGold, color)
    UIHelper.SetTextColor(self.PlaceHolderHint, color)

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutLimit, true, true)
end

function UIPaySubsidyPopView:RefreshMoney()
    local szBrick = UIHelper.GetText(self.EditBoxBrick)
    local szGold = UIHelper.GetText(self.EditBoxGold)
    local nBrick = tonumber(szBrick) or 0
    local nGold = tonumber(szGold) or 0
    local nTotalGold = nBrick*10000 + nGold
    local nLimitGold = math.floor(self.nInComeMoney * 0.2)
    if nTotalGold > nLimitGold then nTotalGold = nLimitGold end
    if nTotalGold < 0 then nTotalGold = 0 end

    nBrick = math.floor(nTotalGold / 10000)
    nGold = nTotalGold - nBrick * 10000
    UIHelper.SetText(self.EditBoxBrick, tostring(nBrick))
    UIHelper.SetText(self.EditBoxGold, tostring(nGold))
end

return UIPaySubsidyPopView