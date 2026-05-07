-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UItMonthlyPurchase
-- Date: 2023-06-05 14:23:03
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UItMonthlyPurchase = class("UItMonthlyPurchase")

local DEFAULT_DISPLAY_PAGE_INDEX = 2

function UItMonthlyPurchase:OnEnter(dwOperatActID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local tLine = Table_GetOperActyInfo(dwOperatActID)
    if tLine and tLine.szTitle then
        UIHelper.SetString(self.LabelNormalName1, UIHelper.GBKToUTF8(tLine.szTitle))
    end

    self:InitCharegMonthlyBaseInfo()
    self:UpdateRewardListAndState()
end

function UItMonthlyPurchase:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UItMonthlyPurchase:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function ()
        self:Turn2PreviousPage()
        self:UpdateBtnState()
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function ()
        self:Turn2NextPage()
        self:UpdateBtnState()
    end)

    UIHelper.BindUIEvent(self.BtnGetAll, EventType.OnClick, function ()
        self:GetAllCallServer()
    end)

    UIHelper.BindUIEvent(self.TogConsumeDetail, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips,self.TogConsumeDetail, g_tStrings.STR_RECHARGE_REWARD_BTN_TIPS)
    end)
end

function UItMonthlyPurchase:RegEvent()
    Event.Reg(self, "On_Recharge_CheckOnSaleMonthly_CallBack", function (dwID, tRewardInfo, nMoney, bCanDo, nMonthId)
        if nMonthId == self.tPageInfos[self.nCurrentPageIndex][1].dwID then
            self:UpdateRewardState()
            self:UpdateLeftRedPoint()
        end
    end)

    Event.Reg(self, "On_Recharge_GetOnSaleMonthlyRwd_CallBack", function (nMonthId, tLevelInfo)
        self:UpdateRewardState()
        self:UpdateLeftRedPoint()
    end)
end

function UItMonthlyPurchase:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UItMonthlyPurchase:InitCharegMonthlyBaseInfo()
    local tChongXiaoMon, nMaxIssue = Table_GetChongXiaoMonthly()
    table.sort(tChongXiaoMon, function(tLeft, tRight)
		return tLeft[1].nEndTime < tRight[1].nStartTime
    end)

    local tPrevPageInfos, tCurPageInfos, tNextPageInfos = HuaELouData.GetDisplayPageInfo(tChongXiaoMon, nMaxIssue)

    self.tPageInfos = {}
    tPrevPageInfos[1].nLevels = #tPrevPageInfos - 1
    tCurPageInfos[1].nLevels  = #tCurPageInfos - 1
    tNextPageInfos[1].nLevels = #tNextPageInfos - 1
    table.insert(self.tPageInfos, tPrevPageInfos)
    table.insert(self.tPageInfos, tCurPageInfos)
    table.insert(self.tPageInfos, tNextPageInfos)

    self.nCurrentPageIndex = DEFAULT_DISPLAY_PAGE_INDEX
end

function UItMonthlyPurchase:AdjustPos(pos, count)
	if pos < 1 then
		pos = pos + count
	end

	if pos > count then
		pos = pos - count
	end

	return pos
end

function UItMonthlyPurchase:UpdateRewardListAndState()
    self:UpdateTitleText()
    self:UpdateRewardList()
    self:UpdateRewardState()
    RemoteCallToServer("On_Recharge_CheckOnSaleMonthly", OPERACT_ID.CHARGE_MONTHLY, self.tPageInfos[self.nCurrentPageIndex][1].dwID)
end

function UItMonthlyPurchase:UpdateRewardList()
    local tCurPageInfos = self.tPageInfos[self.nCurrentPageIndex]

    local tbItemScript = {}
    self.tbRewardCell = {}

    UIHelper.RemoveAllChildren(self.ScrollViewReward)

    for nIndex = 2, #tCurPageInfos do
        if tCurPageInfos[nIndex].nSubID ~= 0 and tCurPageInfos[nIndex].bShow then
            local RewardCell = UIHelper.AddPrefab(PREFAB_ID.WidgetMonthlyPurchaseRewardCell, self.ScrollViewReward) assert(RewardCell)

            local tInfo = string.split(tCurPageInfos[nIndex].szItems, ";")
            for i = 1, #tInfo do
                tInfo[i] = string.trim(tInfo[i], " ")
                local tBoxInfo = string.split(tInfo[i], "_")
                local dwTabType, dwIndex, nStackNum = tBoxInfo[2], tBoxInfo[3], tBoxInfo[4]

                local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80,RewardCell.LayoutItem)

                if itemScript then
                    itemScript:OnInitWithTabID(dwTabType, dwIndex, nStackNum)

                    itemScript:SetClickCallback(function (nTabType, nTabID)
                        if nTabType and nTabID then
                            local tips, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.RichTextPreview, TipsLayoutDir.AUTO)
                            scriptItemTip:OnInitWithTabID(nTabType, nTabID)
                            scriptItemTip:SetBtnState({})
                            if UIHelper.GetSelected(itemScript.ToggleSelect) then
                                UIHelper.SetSelected(itemScript.ToggleSelect,false)
                            end
                        end
                    end)
                end
                table.insert(tbItemScript,itemScript)
            end

            UIHelper.SetString(RewardCell.LabelPurchaseConsunption, FormatString(g_tStrings.STR_RECHARGE_TIME_REWARD_CELL_TIPS, tCurPageInfos[nIndex].nMoney))

            UIHelper.BindUIEvent(RewardCell.TogRewardCell,EventType.OnSelectChanged,function (_, bSelected)
                if bSelected then
                    local szPath = tCurPageInfos[nIndex].szRewardTextureFile
                    szPath = string.gsub(szPath,"ui/Image/OperationActivity3/Gift_ChargeGiftMonthly","Texture/HuaELouReward/MonthlyPurchaseGift")
                    szPath = string.gsub(szPath, "tga","png")
                    UIHelper.SetTexture(self.ImgRewardPreview,szPath)
                    local sztext = FormatString(g_tStrings.STR_RECHARGE_TIME_REWARD_TIPS, tCurPageInfos[nIndex].nMoney)
                    UIHelper.SetRichText(self.RichTextPreview, sztext)
                end
            end)

            UIHelper.BindUIEvent(RewardCell.BtnGetItem,EventType.OnClick,function (_, bSelected)
                local nMonthId = self.tPageInfos[self.nCurrentPageIndex][1].dwID
                if not nMonthId or -1 == nMonthId then
                    return
                end
                RemoteCallToServer("On_Recharge_GetOnSaleMonthlyRwd", OPERACT_ID.CHARGE_MONTHLY, nMonthId, tCurPageInfos[nIndex].nSubID)
            end)

            table.insert(self.tbRewardCell, RewardCell)
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewReward)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewReward, self.WidgetArrow)
    if self.tbRewardCell[1] then
        UIHelper.SetSelected(self.tbRewardCell[1].TogRewardCell, true)
    end

end

function UItMonthlyPurchase:UpdateTitleText()
    UIHelper.SetString(self.LabelMiddle, UIHelper.GBKToUTF8(self.tPageInfos[self.nCurrentPageIndex][1].szActivityTime))
    UIHelper.SetString(self.LabelPeriod, UIHelper.GBKToUTF8(self.tPageInfos[self.nCurrentPageIndex][1].szTitle))
end

function UItMonthlyPurchase:UpdateRewardState()
    local nMonthId = self.tPageInfos[self.nCurrentPageIndex][1].dwID

    if HuaELouData.tMonthlyRecharge and HuaELouData.tMonthlyRecharge[nMonthId] then
        local tReward = HuaELouData.tMonthlyRecharge[nMonthId].tRewardInfo
        local nMoney = HuaELouData.tMonthlyRecharge[nMonthId].nMoney
        UIHelper.SetString(self.LabelConsumeNum,nMoney.."元")
        UIHelper.LayoutDoLayout(self.LabelConsumeNum)

        self.bEnableBtnCollectAllBtn = false
        for k,RewardCell in ipairs(self.tbRewardCell) do
            local nState = HuaELouData.GetLevelRewardStateOfPlayerByLevel(tReward,self.tPageInfos[self.nCurrentPageIndex][k+1].nSubID)
            UIHelper.SetVisible(RewardCell.LabelNotAchieved, nState == OPERACT_REWARD_STATE.NON_GET)
            UIHelper.SetVisible(RewardCell.LabelAchieved, nState == OPERACT_REWARD_STATE.CAN_GET)
            UIHelper.SetVisible(RewardCell.BtnGetItem, nState == OPERACT_REWARD_STATE.CAN_GET)
            UIHelper.SetVisible(RewardCell.LabelReceived, nState == OPERACT_REWARD_STATE.ALREADY_GOT)

            self.bEnableBtnCollectAllBtn = self.bEnableBtnCollectAllBtn or nState == OPERACT_REWARD_STATE.CAN_GET
        end

        UIHelper.SetButtonState(self.BtnGetAll, self.bEnableBtnCollectAllBtn and BTN_STATE.Normal or BTN_STATE.Disable)
    end

end

function UItMonthlyPurchase:Turn2PreviousPage()
    local nPrevPage = self.nCurrentPageIndex - 1
    local tPrevPageInfos = self.tPageInfos[nPrevPage]
    local bPrevPageValid = self:IsPrevPageValid(tPrevPageInfos)

    if not bPrevPageValid then
        return
    end

    self.nCurrentPageIndex = nPrevPage
    self:UpdateRewardListAndState()
end

function UItMonthlyPurchase:IsPrevPageValid(tPrevPageInfos)
    local bRes = false
    local nCurrentTime = GetCurrentTime()
    if  tPrevPageInfos and tPrevPageInfos[1] and
        tPrevPageInfos[1].bShow and
        tPrevPageInfos[1].nLevels > 0
    then
        bRes = true
    end
    return bRes
end

function UItMonthlyPurchase:Turn2NextPage()
    local nNextPage = self.nCurrentPageIndex + 1
    local tNextPageInfos = self.tPageInfos[nNextPage]
    local tNextPageValid = self:IsNextPageValid(tNextPageInfos)

    if not (tNextPageValid) then
        return
    end

    self.nCurrentPageIndex = nNextPage
    self:UpdateRewardListAndState()
end

function UItMonthlyPurchase:IsNextPageValid(tNextPageInfos)
    local bRes = false
    local nCurrentTime = GetCurrentTime()
    if tNextPageInfos and tNextPageInfos[1] and
       tNextPageInfos[1].bShow and
       tNextPageInfos[1].nLevels > 0 and
       nCurrentTime > tNextPageInfos[1].nDisplayTime
    then
        bRes = true
    end
    return bRes
end

function UItMonthlyPurchase:UpdateBtnState()
    local tNextPageValid = self:IsNextPageValid(self.tPageInfos[self.nCurrentPageIndex - 1])
    self:UpdateLeftRedPoint()
    tNextPageValid = self:IsNextPageValid(self.tPageInfos[self.nCurrentPageIndex + 1])
end

function UItMonthlyPurchase:UpdateLeftRedPoint()
    local bRedPoint = false
    if self.tPageInfos[self.nCurrentPageIndex - 1] then
        local nMonthId = self.tPageInfos[self.nCurrentPageIndex - 1][1].dwID
        if HuaELouData.tMonthlyRecharge[nMonthId] then
            local tReward = HuaELouData.tMonthlyRecharge[nMonthId].tRewardInfo

            for k ,v in ipairs(tReward) do
                local nState = HuaELouData.GetLevelRewardStateOfPlayerByLevel(tReward, self.tPageInfos[self.nCurrentPageIndex - 1][k + 1].nSubID)
                bRedPoint = bRedPoint or nState == OPERACT_REWARD_STATE.CAN_GET
                if bRedPoint then
                    break
                end
            end
        end
    end

    UIHelper.SetVisible(self.ImgRedPoint, bRedPoint)
end

function UItMonthlyPurchase:GetAllCallServer()
    UIHelper.ShowConfirm(g_tStrings.STR_GET_REWARD_SRUE, function ()
        local nMonthId = self.tPageInfos[self.nCurrentPageIndex][1].dwID
        if not nMonthId or -1 == nMonthId then
            return
        end
        RemoteCallToServer("On_Recharge_GetOnSaleMonthlyRwd", OPERACT_ID.CHARGE_MONTHLY, nMonthId)
    end)
end

return UItMonthlyPurchase