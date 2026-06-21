-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationWelcomeSignIn
-- Date: 2026-03-23 17:00:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

-- 回归/萌新签到

local UIOperationWelcomeSignIn = class("UIOperationWelcomeSignIn")

--活动250的特殊显示
local SpecialTitleImg ={
    [250] = "UIAtlas2_OperationCenter_PublicModelTitle_ZhuZhanXiaKe.png"
}
local SpecialTitleText ={
    [250] = "景天"
}

function UIOperationWelcomeSignIn:OnEnter(nOperationID, nID)
    self.nOperationID = nOperationID
    self.nID = nID

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:RemoteCallBatchCheck()
    self:UpdateInfo()
end

function UIOperationWelcomeSignIn:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationWelcomeSignIn:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnGetAll, EventType.OnClick, function ()
        if OperationWelcomeSignInData.CheckID(self.nOperationID) then
            OperationWelcomeSignInData.GetReward()
        elseif self.tLine.bNeedRemoteCall then
            RemoteCallToServer("On_Recharge_GetWelfareRwd", self.nOperationID)
        end
    end)

    UIHelper.BindUIEvent(self.ScrollViewGiftList, EventType.OnScrollingScrollView, function(_, eventType)
        if eventType == ccui.ScrollviewEventType.containerMoved then
            self:UpdateGiftFixed()
        end
    end)
end

function UIOperationWelcomeSignIn:RegEvent()
    if OperationWelcomeSignInData.CheckID(self.nOperationID) then
        Event.Reg(self, "REMOTE_NEWSIGNIN_DATA_EVENT", function()
            Timer.AddFrame(self, 1, function()
                self:UpdateInfo()
            end)
        end)
    end

    Event.Reg(self, "On_Check_Operation_CallBack", function (dwID)
        if dwID == self.nOperationID then
            self:UpdateBtnState()
        end
    end)

    Event.Reg(self, "On_Get_Operation_Reward_CallBack", function (dwID)
        if dwID == self.nOperationID then
            self:UpdateBtnState()
        end
    end)
end

function UIOperationWelcomeSignIn:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationWelcomeSignIn:RemoteCallBatchCheck()
    local tLine = Table_GetOperActyInfo(self.nOperationID)
    self.tLine = tLine
    local tToCheckOperatID = {}
    if tLine and tLine.bNeedRemoteCall then
        table.insert(tToCheckOperatID, self.nOperationID)
    end

    if not table.is_empty(tToCheckOperatID) then
        RemoteCallToServer("On_Recharge_CheckWelfare", tToCheckOperatID)
    end
end

function UIOperationWelcomeSignIn:UpdateInfo()
    if OperationWelcomeSignInData.CheckID(self.nOperationID) then
        OperationWelcomeSignInData.InitCurrent(self.nOperationID)
        UIHelper.SetVisible(self.BtnGetAll, OperationWelcomeSignInData.CheckRewardCanGet(self.nOperationID))
    else
        self:UpdateBtnState()
    end

    self:UpdateRewardList()

    if OperationWelcomeSignInData.CheckID(self.nOperationID) then
        local tInfo = OperationCenterData.GetOperationInfo(self.nOperationID)
        local hPlayer = GetClientPlayer()
        local nCreateTime  = hPlayer.GetCreateTime()
        local t = TimeToDate(nCreateTime)
        local szCreateTime = FormatString(g_tStrings.STR_TIME_1, t.year, string.format("%02d", t.month), string.format("%02d", t.day))
        local szContent = FormatString(UIHelper.GBKToUTF8(tInfo.szBriefDesc), szCreateTime)
        if self.nOperationID == OPERACT_ID.WELCOME_BACK_SIGNIN then
            --local nOldTime        = hPlayer.GetExtPoint(403)
            local tData           = GDAPI_NewSignInGetInfo(self.nOperationID)
            --local nLeaveDay       = math.floor(nOldTime / (24 * 60 * 60))
            --local szLeaveTime     = FormatString(g_tStrings.STR_LEAVE_TIME, nLeaveDay)
            local bShowLeaveTime  = tData.bLeaveTime
            if bShowLeaveTime and bShowLeaveTime > 0 then
                local szLeaveTime     = FormatString(g_tStrings.STR_LEAVE_TIME, bShowLeaveTime)
                szContent = szLeaveTime .. szContent
            end
        end
        local szText = ParseTextHelper.ConvertRichTextFormat(szContent, true)
        local tContext = OperationCenterData.GetViewComponentContext()
        local scriptLabelContent = tContext and tContext.tScriptLayoutTop[2]
        scriptLabelContent:SetContent(szText)
    end

    local tContext = OperationCenterData.GetViewComponentContext()
    local scriptCenter = tContext and tContext.scriptCenter
    if SpecialTitleImg and SpecialTitleImg[self.nOperationID] then
        scriptCenter:SetContentNameTitle(SpecialTitleText[self.nOperationID] or "", SpecialTitleImg[self.nOperationID])
    end

end

function UIOperationWelcomeSignIn:UpdateRewardList()
    local tList = Table_GetSignInReward(self.nOperationID)

    UIHelper.RemoveAllChildren(self.ScrollViewGiftList)
    self.tScripts = {}
    for _, tInfo in ipairs(tList) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetReturnGiftCell, self.ScrollViewGiftList, tInfo, self.nOperationID)
        table.insert(self.tScripts, script)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewGiftList)

    if OperationWelcomeSignInData.CheckID(self.nOperationID) then
        Timer.AddFrame(self, 1, function()
            -- 滚动到第一个可领取的奖励位置
            local tData = OperationWelcomeSignInData.GetCurrentData()
            for nIndex, script in ipairs(self.tScripts) do
                if tData.tCanGet[script.tInfo.nIndex] == 1 and tData.tHaveGet[script.tInfo.nIndex] == 0 then
                    UIHelper.ScrollToIndex(self.ScrollViewGiftList, nIndex-1)
                    break
                end
            end
            self:UpdateGiftFixed()
        end)
    end
end

function UIOperationWelcomeSignIn:UpdateGiftFixed()
    if not self.tScripts then
        return
    end

    local tData
    if OperationWelcomeSignInData.CheckID(self.nOperationID) then
        tData = OperationWelcomeSignInData.GetCurrentData()
    else
        tData = HuaELouData.tCustom[self.nOperationID] and HuaELouData.tCustom[self.nOperationID].tRewardState
    end
    local nFixedX = UIHelper.GetWorldPositionX(self.WidgetGiftFixed)

    local tNextScript = nil
    for _, script in ipairs(self.tScripts) do
        if OperationWelcomeSignInData.CheckID(self.nOperationID) then
            if script.tInfo.bIsMainReward and tData.tHaveGet[script.tInfo.nIndex] == 0 then
                local nCellX = UIHelper.GetWorldPositionX(script._rootNode)
                if nCellX > nFixedX then
                    tNextScript = script
                    break
                end
            end
        else
            if script.tInfo.bIsMainReward and tData[script.tInfo.nIndex] ~= OPERACT_REWARD_STATE.ALREADY_GOT then
                local nCellX = UIHelper.GetWorldPositionX(script._rootNode)
                if nCellX > nFixedX then
                    tNextScript = script
                    break
                end
            end
        end
    end

    if not tNextScript then
        UIHelper.SetVisible(self.WidgetGiftFixed, false)
        self.nNextIndex = nil
        return
    end

    if self.nNextIndex ~= tNextScript.tInfo.nIndex then
        UIHelper.RemoveAllChildren(self.WidgetGiftFixed)
        UIHelper.AddPrefab(PREFAB_ID.WidgetReturnGiftCell, self.WidgetGiftFixed, tNextScript.tInfo, self.nOperationID)
        self.nNextIndex = tNextScript.tInfo.nIndex
    end
    UIHelper.SetVisible(self.WidgetGiftFixed, true)
end

function UIOperationWelcomeSignIn:UpdateBtnState()
    local bCanRevive = false
    local tCustom = HuaELouData.tCustom[self.nOperationID]
    if tCustom and tCustom.tRewardState then
        for k, v in ipairs(tCustom.tRewardState) do
            if tCustom.tRewardState[k] == OPERACT_REWARD_STATE.CAN_GET then
                bCanRevive = true
                break
            end
        end
    end

    UIHelper.SetVisible(self.BtnGetAll, false)
end

return UIOperationWelcomeSignIn
