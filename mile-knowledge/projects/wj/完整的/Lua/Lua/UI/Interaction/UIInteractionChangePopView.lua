-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIInteractionChangePopView
-- Date: 2023-02-07 17:11:14
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIInteractionChangePopView = class("UIInteractionChangePopView")

function UIInteractionChangePopView:OnEnter(bCanBeDirectMentor, bFree)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bCanBeDirectMentor = bCanBeDirectMentor
    self.bFree = bFree
    self.nTranApprenticeCost = 3000
    self:UpdateChange()
end

function UIInteractionChangePopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIInteractionChangePopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose,EventType.OnClick,function ()
        UIMgr.Close(VIEW_ID.PanelInteractionChangePop)
    end)
    UIHelper.BindUIEvent(self.BtnChange,EventType.OnClick,function ()
        --local nCoin 	= g_pClientPlayer.nCoin
        if not self.bFree and self.bCanBeDirectMentor then
            if g_pClientPlayer.nCoin < self.nTranApprenticeCost then
                --钱不够，弹窗，跳转，充值
                UIHelper.ShowConfirm(g_tStrings.MENTOR_RECHARGE,function ()
                    UIMgr.Open(VIEW_ID.PanelTopUpMain)
                    UIMgr.Close(self)
                end,nil,false)
            else
                self:UpdateChangeConfirm()
            end
        else
            if self.bCanBeDirectMentor and self.bFree then
                RemoteCallToServer("OnIsFreeToDirectApprentice")
            end
            self:UpdateChangeConfirm()
        end
    end)
end

function UIInteractionChangePopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "ON_COIN_BUY_RESPOND", function (arg0)--重置亲传徒弟状态是否成功
        if arg0 == COIN_BUY_RESPOND_CODE.BUY_DIRECT_MENTOR_RESET_SUCCESS then
			--TransToAppSuccess(this)
            TipsHelper.ShowNormalTip(g_tStrings.tCoinBuyRespond[COIN_BUY_RESPOND_CODE.BUY_DIRECT_MENTOR_RESET_SUCCESS])
            self.bCanBeDirectMentor = false
            self:UpdateChange()
        elseif arg0 == COIN_BUY_RESPOND_CODE.BUY_DIRECT_MENTOR_RESET_FAILED then
            TipsHelper.ShowNormalTip(g_tStrings.tCoinBuyRespond[COIN_BUY_RESPOND_CODE.BUY_DIRECT_MENTOR_RESET_FAILED])
		end
    end)
    Event.Reg(self, "TRANSFORM_TO_MASTER",function () --重置为亲传师傅状态成功后
        TipsHelper.ShowNormalTip(g_tStrings.STR_DIRECT_MASTER_EXPLAIN)
        self.bCanBeDirectMentor = true
        self:UpdateChange()
    end)
    Event.Reg(self, "TRANSFORM_TO_APPRENTICE",function () --免费重置为亲传徒弟状态成功后
        TipsHelper.ShowNormalTip(g_tStrings.STR_DIRECT_APPRENTICE_EXPLAIN)
        self.bCanBeDirectMentor = false
        self:UpdateChange()
    end)

    Event.Reg(self, "ON_IS_FREE_TO_DIRECT_APPRENTICE",function (bFree)  --能否免费转换为亲传徒弟
        self.bFree = bFree
    end)
end

function UIInteractionChangePopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIInteractionChangePopView:UpdateChangeConfirm()
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP, "COIN") then
        return
    end

    --判断一下是转为师傅还是转为徒弟
    if not self.bCanBeDirectMentor then
        UIHelper.ShowConfirm(g_tStrings.STR_TRANSFORM,function ()
            RemoteCallToServer("OnTurnToDirectMentor")
        end)
    else
        local szText = g_tStrings.STR_TRANSFORM
        if not self.bFree then
            szText = g_tStrings.STR_TRANSFORM_NOT_FREE
        end
        UIHelper.ShowConfirm(szText,function ()
            RemoteCallToServer("OnBuyDirectMentorReset")
        end,nil,true)
    end
end

function UIInteractionChangePopView:UpdateChange()
    UIHelper.SetVisible(self.ImgArrowsRight,not self.bCanBeDirectMentor)
    UIHelper.SetVisible(self.ImgStatusTipA,not self.bCanBeDirectMentor)
    UIHelper.SetVisible(self.ImgArrowsLeft,self.bCanBeDirectMentor)
    UIHelper.SetVisible(self.ImgStatusTipM,self.bCanBeDirectMentor)
    if self.bCanBeDirectMentor then
        self:UpdateCost()
    end
end

function UIInteractionChangePopView:UpdateCost()
    UIHelper.SetVisible(self.LableFree,self.bFree)
    UIHelper.SetVisible(self.ImgMoney,not self.bFree)
end


return UIInteractionChangePopView