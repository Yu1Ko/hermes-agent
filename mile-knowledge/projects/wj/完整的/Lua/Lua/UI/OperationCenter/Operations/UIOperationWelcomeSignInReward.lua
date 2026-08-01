-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationWelcomeSignInReward
-- Date: 2026-03-23 17:09:26
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationWelcomeSignInReward = class("UIOperationWelcomeSignInReward")

function UIOperationWelcomeSignInReward:OnEnter(tInfo, nOperationID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tInfo = tInfo
    self.nOperationID = nOperationID
    self:UpdateInfo()
end

function UIOperationWelcomeSignInReward:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationWelcomeSignInReward:BindUIEvent()
    UIHelper.BindUIEvent(self._rootNode, EventType.OnClick, function()
        if OperationWelcomeSignInData.CheckID(self.nOperationID) then
            if self.tInfo then
                OperationWelcomeSignInData.GetReward(self.tInfo.nIndex)
            end
        else
            RemoteCallToServer("On_Recharge_GetWelfareRwd", self.nOperationID, self.tInfo.nIndex)
        end
    end)
end

function UIOperationWelcomeSignInReward:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if UIHelper.GetSelected(self.SelectToggle) then
            UIHelper.SetSelected(self.SelectToggle, false)
        end
    end)

    Event.Reg(self, "On_Check_Operation_CallBack", function (dwID)
        if dwID == self.nOperationID then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "On_Get_Operation_Reward_CallBack", function (dwID)
        if dwID == self.nOperationID then
            self:UpdateInfo()
        end
    end)
end

function UIOperationWelcomeSignInReward:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

local tBgSprite = {
    [true]  = {
        [OPERACT_REWARD_STATE.ALREADY_GOT] = "UIAtlas2_OperationCenter_WelcomeSignIn_jhqd5.png",
        [OPERACT_REWARD_STATE.CAN_GET]     = "UIAtlas2_OperationCenter_WelcomeSignIn_jhqd4.png",
        [OPERACT_REWARD_STATE.NON_GET]     = "UIAtlas2_OperationCenter_WelcomeSignIn_jhqd4.png",
    },
    [false] = {
        [OPERACT_REWARD_STATE.ALREADY_GOT] = "UIAtlas2_OperationCenter_WelcomeSignIn_jhqd2.png",
        [OPERACT_REWARD_STATE.CAN_GET]     = "UIAtlas2_OperationCenter_WelcomeSignIn_jhqd1.png",
        [OPERACT_REWARD_STATE.NON_GET]     = "UIAtlas2_OperationCenter_WelcomeSignIn_jhqd1.png",
    },
}

local tNormalBgSprite = {
    [true]  = {
        [OPERACT_REWARD_STATE.ALREADY_GOT] = "UIAtlas2_OperationCenter_WelcomeSignIn_XianJianSignIn4.png",
        [OPERACT_REWARD_STATE.CAN_GET]     = "UIAtlas2_OperationCenter_WelcomeSignIn_XianJianSignIn5.png",
        [OPERACT_REWARD_STATE.NON_GET]     = "UIAtlas2_OperationCenter_WelcomeSignIn_XianJianSignIn5.png",
    },
    [false] = {
        [OPERACT_REWARD_STATE.ALREADY_GOT] = "UIAtlas2_OperationCenter_WelcomeSignIn_XianJianSignIn2.png",
        [OPERACT_REWARD_STATE.CAN_GET]     = "UIAtlas2_OperationCenter_WelcomeSignIn_XianJianSignIn3.png",
        [OPERACT_REWARD_STATE.NON_GET]     = "UIAtlas2_OperationCenter_WelcomeSignIn_XianJianSignIn3.png",
    },
}

function UIOperationWelcomeSignInReward:UpdateInfo()
    if OperationWelcomeSignInData.CheckID(self.nOperationID) then
        self:UpdateWelcomeSignInInfo()
    else
        self:UpdateOtherSignInInfo()
    end

    local nState

    if OperationWelcomeSignInData.CheckID(self.nOperationID) then
        nState = OperationWelcomeSignInData.GetRewardState(self.tInfo.nIndex)
    else
        local tCustom = HuaELouData.tCustom[self.nOperationID]
        if tCustom and tCustom.tRewardState then
            nState = tCustom.tRewardState[self.tInfo.nIndex]
        end
    end

    if nState ~= OPERACT_REWARD_STATE.CAN_GET then
        local szChinese = UIHelper.NumberToChinese(self.tInfo.nIndex)
        local nLen = utf8.len(szChinese)
        local szDay = nLen > 2 and UIHelper.GetUtf8SubString(szChinese, nLen - 1, 2) or szChinese
        UIHelper.SetString(self.LabelTime, string.format("第%s天", szDay))
    end

    UIHelper.SetCanSelect(self._rootNode, nState == OPERACT_REWARD_STATE.CAN_GET)

    UIHelper.SetVisible(self.LabelTime, nState ~= OPERACT_REWARD_STATE.CAN_GET)
    UIHelper.SetVisible(self.WidgetSFX, nState == OPERACT_REWARD_STATE.CAN_GET)

    -- 文字颜色
    if nState == OPERACT_REWARD_STATE.ALREADY_GOT then
        UIHelper.SetTextColor(self.LabelTime, cc.c4b(0x57, 0x55, 0x55, 255))
    else
        UIHelper.SetTextColor(self.LabelTime, cc.c4b(255, 255, 255, 255))
    end

    -- 特效区分普通/重要
    local bMain = self.tInfo.bIsMainReward or false
    UIHelper.SetVisible(self.EffRewardGetGeneral, nState == OPERACT_REWARD_STATE.CAN_GET and not bMain)
    UIHelper.SetVisible(self.EffRewardGetImportant, nState == OPERACT_REWARD_STATE.CAN_GET and bMain)
end

function UIOperationWelcomeSignInReward:UpdateOtherSignInInfo()
    local nState, bGot = nil, false
    local tCustom = HuaELouData.tCustom[self.nOperationID]
    if tCustom and tCustom.tRewardState then
        nState = tCustom.tRewardState[self.tInfo.nIndex]
    end
    bGot = nState == OPERACT_REWARD_STATE.ALREADY_GOT

    self.SelectToggle = nil
    UIHelper.RemoveAllChildren(self.LayoutGift60)
    for _, tItem in ipairs(self.tInfo.tRewardList) do
        local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayoutGift60)
        itemScript:OnInitWithTabID(tItem.dwType, tItem.dwIndex, tItem.nCount)

        itemScript:SetClickCallback(function(nTabType, nTabID)
            self.SelectToggle = itemScript.ToggleSelect
            local _, scriptItemTip = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, self.SelectToggle)
            scriptItemTip:OnInitWithTabID(nTabType, nTabID)
        end)

        itemScript:SetItemGray(bGot)
        itemScript:SetItemReceived(bGot)
        itemScript:SetToggleSwallowTouches(false)
    end
    UIHelper.LayoutDoLayout(self.LayoutGift60)

    -- 背景底板切换
    local bMain = self.tInfo.bIsMainReward or false
    local tBg = tNormalBgSprite[bMain]
    if tBg and tBg[nState] then
        UIHelper.SetSpriteFrame(self.ImgBg, tBg[nState])
    end
end

function UIOperationWelcomeSignInReward:UpdateWelcomeSignInInfo()
    local nState = OperationWelcomeSignInData.GetRewardState(self.tInfo.nIndex)
    local bGot = nState == OPERACT_REWARD_STATE.ALREADY_GOT

    self.SelectToggle = nil
    for _, tItem in ipairs(self.tInfo.tRewardList) do
        local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.LayoutGift)
        itemScript:OnInitWithTabID(tItem.dwType, tItem.dwIndex, tItem.nCount)

        itemScript:SetClickCallback(function(nTabType, nTabID)
            self.SelectToggle = itemScript.ToggleSelect
            local _, scriptItemTip = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, self.SelectToggle)
            scriptItemTip:OnInitWithTabID(nTabType, nTabID)
        end)

        itemScript:SetItemGray(bGot)
        itemScript:SetItemReceived(bGot)
        itemScript:SetToggleSwallowTouches(false)
    end
    UIHelper.LayoutDoLayout(self.LayoutGift)

    -- 背景底板切换
    local bMain = self.tInfo.bIsMainReward or false
    local tBg = tBgSprite[bMain]
    if tBg and tBg[nState] then
        UIHelper.SetSpriteFrame(self.ImgBg, tBg[nState])
    end
end

return UIOperationWelcomeSignInReward