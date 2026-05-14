-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopWelfareReturnView
-- Date: 2023-04-11 16:29:11
-- Desc: ?
-- ---------------------------------------------------------------------------------

local DataModel = {}

function DataModel.Init()
    DataModel.WelfareList = {}
    DataModel.Update()
end

function DataModel.UnInit()
    DataModel.WelfareList = nil
end

function DataModel.Update()
    DataModel.WelfareList = GetInnerChargeCache().GetAvailableInnerChargeInfo()
end

local UICoinShopWelfareReturnView = class("UICoinShopWelfareReturnView")

function UICoinShopWelfareReturnView:OnEnter(nTimeCardNum, nMonthCardNum)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        UIMgr.Open(VIEW_ID.PanelUID)
        self.bInit = true
    end

    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.COIN, "") then
        return
    end

    GetInnerChargeCache().Query()

    DataModel.Init()

    if not nTimeCardNum or not nMonthCardNum then
        RemoteCallToServer("On_RewardsDraw_GetCoin")
    else
        self.nTimeCardNum = nTimeCardNum
        self.nMonthCardNum = nMonthCardNum
        self:UpdateInfo()
    end
end

function UICoinShopWelfareReturnView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    DataModel.UnInit()
    UIMgr.Close(VIEW_ID.PanelUID)
end

function UICoinShopWelfareReturnView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
end

function UICoinShopWelfareReturnView:RegEvent()
    Event.Reg(self, "ON_QUERY_AVAILABLE_INNER_CHARGE_RESPOND", function (arg0)
        local nResult = arg0
        if nResult == INNER_CHARGE_ERROR.QUERY_SUCCESS then
            self:UpdateInfo()
        elseif nResult == INNER_CHARGE_ERROR.QUERY_COUNT_LIMIT then
            self:TryAgain(nResult)
        end
    end)

    Event.Reg(self, "ON_DO_INNER_CHARGE_RESPOND", function (arg0, arg1)
        local szOrderSN = arg0
        local nResult = arg1
        if nResult == INNER_CHARGE_ERROR.DO_SUCCESS then
            self:UpdateInfo()
            self:DoChargeSuccess(nResult)
        elseif nResult == INNER_CHARGE_ERROR.DO_FAILED then
            self:DoChargeFailed(nResult)
        elseif nResult == INNER_CHARGE_ERROR.DO_CHARGE_COUNT_LIMIT then
            self:TryAgain(nResult)
        end
    end)

    Event.Reg(self, EventType.OnRewardsDrawGetCoin, function (nCoinNum, nTimeCardNum, nMonthCardNum)
        self.nTimeCardNum = nTimeCardNum
        self.nMonthCardNum = nMonthCardNum
        self:UpdateInfo()
    end)
end

function UICoinShopWelfareReturnView:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopWelfareReturnView:UpdateInfo()
    DataModel.Update()

    -- DataModel.WelfareList = {
    --     [1] = {
    --         ["szOrderSN"] = "123",
    --         ["uInnerChargeType"] = INNER_CHARGE_TYPE.SECOND,
    --         ["uInnerChargeAmount"] = 20,
    --         ["uExpiredTime"] = 1694313944,
    --     },
    --     [2] = {
    --         ["szOrderSN"] = "4567",
    --         ["uInnerChargeType"] = INNER_CHARGE_TYPE.DATE,
    --         ["uInnerChargeAmount"] = 7,
    --         ["uExpiredTime"] = 1694314944,
    --     }
    -- }

    local szTips = string.format("<color=#E2F6FB>获得：</c><color=#eebf58>%d</color><color=#E2F6FB>元点卡</c><color=#eebf58>%d</color><color=#E2F6FB>元月卡</c>", self.nTimeCardNum, self.nMonthCardNum)
    UIHelper.SetRichText(self.LabelWelfareReturnTips01, szTips)
    -- if not DataModel.WelfareList or #DataModel.WelfareList == 0 then
    --     return
    -- end
    UIHelper.RemoveAllChildren(self.ScrollViewWelfareReturn)
    local fnAction = function (script)
        GetInnerChargeCache().DoCharge(script.tInfo.szOrderSN)
    end
    for k, v in ipairs(DataModel.WelfareList or {}) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetWelfareReturnCell, self.ScrollViewWelfareReturn, v, fnAction)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewWelfareReturn)
    UIHelper.SetVisible(self.WidgetEmpty, not DataModel.WelfareList or #DataModel.WelfareList <= 0)
end

function UICoinShopWelfareReturnView:DoChargeFailed(nResult)
    OutputMessage("MSG_SYS", g_tStrings.tDoInnerChargeRespond[nResult])
    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tDoInnerChargeRespond[nResult])
end

function UICoinShopWelfareReturnView:DoChargeSuccess(nResult)
    OutputMessage("MSG_SYS", g_tStrings.tDoInnerChargeRespond[nResult])
    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tDoInnerChargeRespond[nResult])
end

function UICoinShopWelfareReturnView:TryAgain(nResult)
    OutputMessage("MSG_SYS", g_tStrings.tDoInnerChargeRespond[nResult])
    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tDoInnerChargeRespond[nResult])
end

return UICoinShopWelfareReturnView