-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoin
-- Date: 2022-11-14 16:57:56
-- Desc: ?
-- Prefab: WidgetCoin
-- ---------------------------------------------------------------------------------

---@class UICoin
local UICoin = class("UICoin")

function UICoin:OnEnter(nCurrencyType, bAddBtnVisible, nSpecialCount, bShowRecharge)
    self.nCurrencyType = nCurrencyType or CurrencyType.Coin
    if bAddBtnVisible == nil then
        bAddBtnVisible = true
    end
    self.bAddBtnVisible = bAddBtnVisible

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nSpecialCount = nSpecialCount
    self.bShowRecharge = bShowRecharge

    self:UpdateInfo()
end

function UICoin:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoin:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelTopUpMain)
    end)
    UIHelper.BindUIEvent(self.BtnTopUp, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelTopUpMain)
    end)

    UIHelper.BindUIEvent(self.LayoutCoin, EventType.OnClick, function ()
        CurrencyData.ShowCurrencyHoverTipsInDir(self.LayoutCoin, TipsLayoutDir.BOTTOM_LEFT, self.nCurrencyType)
    end)
end

function UICoin:RegEvent()
    Event.Reg(self, "SYNC_COIN", function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, "UPDATE_ARCHITECTURE", function ()
        if self.nCurrencyType == CurrencyType.Architecture then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "UPDATE_PRESTIGE", function(nOldPrestige)
        if self.nCurrencyType == CurrencyType.Prestige then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "TITLE_POINT_UPDATE", function(nNewTitlePoint, nAddTitlePoint)
        if self.nCurrencyType == CurrencyType.TitlePoint then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "BAG_ITEM_UPDATE", function()
        if self.nCurrencyType == CurrencyType.FeiShaWand then
            self.nTimerFeiShaWand = self.nTimerFeiShaWand or Timer.AddFrame(self, 1, function ()
                RemoteCallToServer("On_Zhanchang_Remain")
                self.nTimerFeiShaWand = nil
            end)
        end
    end)

    Event.Reg(self, "UPDATE_FEISHAWAND", function()
        if self.nCurrencyType == CurrencyType.FeiShaWand then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "On_ArenaTower_UpdateCoinInGame", function()
        if self.nCurrencyType == CurrencyType.TianJiToken then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "UPDATE_ACTCOINDFW", function()
        if self.nCurrencyType == CurrencyType.MonopolyCoin then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.OnMonopolyUpdatePlayerMoney, function()
        if self.nCurrencyType == CurrencyType.MonopolyMoney then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.OnMonopolyUpdatePlayerPointNum, function()
        if self.nCurrencyType == CurrencyType.MonopolyPoint then
            self:UpdateInfo()
        end
    end)

    --TODO 其他货币的更新事件
end

function UICoin:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoin:UpdateInfo()
    local nCurrency = CurrencyData.GetCurCurrencyCount(self.nCurrencyType)
    local szCurrencyImg = CurrencyData.tbImageSmallIcon[self.nCurrencyType]

    if self.nSpecialCount then
        UIHelper.SetString(self.LabelMoney_Zhuan, self.nSpecialCount)
    else
        UIHelper.SetString(self.LabelMoney_Zhuan, nCurrency)
    end


    if self.bShowRecharge then
        UIHelper.SetVisible(self.WidgetTongBao_Shopping, true)
        UIHelper.SetVisible(self.ImgZhuan, false)
    else
        UIHelper.SetVisible(self.WidgetTongBao_Shopping, false)
        UIHelper.SetVisible(self.ImgZhuan, true)
        UIHelper.SetSpriteFrame(self.ImgZhuan, szCurrencyImg)
    end

    --TODO 有哪些货币显示“+”按钮
    self:SetAddBtnVisible((self.nCurrencyType == CurrencyType.Coin) and self.bAddBtnVisible)

    UIHelper.LayoutDoLayout(self.LayoutCoin)
    UIHelper.SetContentSize(self._rootNode, UIHelper.GetContentSize(self.LayoutCoin))
    local parent = UIHelper.GetParent(self._rootNode)
    UIHelper.LayoutDoLayout(parent)
    UIHelper.SetTouchEnabled(self.LayoutCoin, true)
end

function UICoin:SetAddBtnVisible(bVisible)
    UIHelper.SetVisible(self.BtnAdd, bVisible)
end

function UICoin:SetCurrencyCount(nCount)
    UIHelper.SetString(self.LabelMoney_Zhuan, nCount)
end

return UICoin