-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationRewardWithItem
-- Date: 2024-04-12 16:43:52
-- Desc: 通用简单领奖活动
-- ---------------------------------------------------------------------------------

local UIOperationRewardWithItem = class("UIOperationRewardWithItem")

function UIOperationRewardWithItem:OnEnter(dwOperatActID, nID, tComponentContext)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local tActivity = TabHelper.GetHuaELouActivityByOperationID(dwOperatActID)
    local tLine = Table_GetOperActyInfo(dwOperatActID)
    if not tActivity or not tLine then
        return
    end

    self.nID = nID
    self.dwOperatActID = dwOperatActID
    self.tActivity = tActivity
    self.tLine = tLine
    self.tComponentContext = tComponentContext

    local tScriptBottom = tComponentContext and tComponentContext.tScriptLayoutBottom
    self.scriptRewardList = tScriptBottom and tScriptBottom[1] -- WidgetLayOutRewardList

    self:UpdateInfo()
end

function UIOperationRewardWithItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationRewardWithItem:BindUIEvent()
end

function UIOperationRewardWithItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "On_Check_Operation_CallBack", function (dwID, tCustom)
        if dwID == self.dwOperatActID then
            self:UpdataRewardItemState()
            self:UpdataBtnState()
        end
    end)

    Event.Reg(self, "On_Get_Operation_Reward_CallBack", function (dwID, nRewardID)
        if dwID == self.dwOperatActID then
            self:UpdataRewardItemState()
            self:UpdataBtnState()
        end
    end)

    Event.Reg(self, "CHANGE_NEW_EXT_POINT_NOTIFY", function ()
        self:SyncExtPoint()
        self:RemoteCallBatchCheck()
    end)

    Event.Reg(self, "OperationOnClickBtn", function (dwOperatActID)
        if dwOperatActID == self.dwOperatActID then
            RemoteCallToServer("On_Recharge_GetWelfareRwd", self.dwOperatActID)
        end
    end)
end

function UIOperationRewardWithItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationRewardWithItem:UpdateInfo()
    -- 算了先不加了 不知道以后用不用了
    -- self:SyncExtPoint()
    self:RemoteCallBatchCheck()
    self:UpdataRewardItemState()
    self:UpdataBtnState()
end

function UIOperationRewardWithItem:SyncExtPoint()
    if self.tLine and self.tLine.bUseExtPoint then
        local tInfo = GDAPI_CheckWelfare(self.dwID)
        if tInfo and tInfo.dwID ~= 0 then
            self.tReward = {{tInfo.nLimit, tInfo.nReward}}
            self.nMoney = tInfo.nMoney
            self.tCustom = tInfo.tCustom
        end
    end
end

function UIOperationRewardWithItem:RemoteCallBatchCheck()
    local tToCheckOperatID = {}
    if self.tLine and self.tLine.bNeedRemoteCall then
        table.insert(tToCheckOperatID, self.dwOperatActID)
    end

    if not table.is_empty(tToCheckOperatID) then
        RemoteCallToServer("On_Recharge_CheckWelfare", tToCheckOperatID)
    end
end

function UIOperationRewardWithItem:UpdataRewardItemState()
    local tCustom = HuaELouData.tCustom[self.dwOperatActID]
    if tCustom and tCustom.tRewardState then
        self.scriptRewardList:UpdataItemState(tCustom.tRewardState)
    end
end

function UIOperationRewardWithItem:UpdataBtnState()
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelOperationCenter)
    local tCustom = HuaELouData.tCustom[self.dwOperatActID]
    local tButtonList = self.tActivity.nLayoutStyle == 1 and scriptView.tButton420 or scriptView.tButton540

    for k,btn in ipairs(tButtonList) do
        if UIHelper.GetVisible(btn) then
            if tCustom.tRewardState[k] == OPERACT_REWARD_STATE.CAN_GET then
                UIHelper.SetButtonState(btn, BTN_STATE.Normal)
            else
                UIHelper.SetButtonState(btn, BTN_STATE.Disable)
                if tCustom.tRewardState[k] == OPERACT_REWARD_STATE.ALREADY_GOT then
                    local scriptBtn = UIHelper.GetBindScript(btn)
                    scriptBtn:UpdateBtnDes("已领取")
                    UIHelper.SetEnable(btn, false)
                end
            end
        end
    end
end

return UIOperationRewardWithItem