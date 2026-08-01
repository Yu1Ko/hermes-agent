-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAnniversaryGiveBack
-- Date: 2024-08-09 11:41:07
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIAnniversaryGiveBack = class("UIAnniversaryGiveBack")

local DEFAULT_DISPLAY_LEVEL = 1
local REMOTECALL_TABLE = {
	[OPERACT_ID.FIRST_CHARGE] = {
		CHECK 	= "On_Recharge_CheckFirstCharge",
		GET 	= "On_Recharge_GetFirstChargeRwd",
	},
	[OPERACT_ID.ANNIVERSARY_FEEDBACK] = {
		CHECK 	= "On_Recharge_CheckOnSale",
		GET 	= "On_Recharge_GetOnSaleRwd",
	},
}

function UIAnniversaryGiveBack:OnEnter(dwOperatActID, nID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local tActivity = UIHuaELouActivityTab[nID]
    if not tActivity then
        return
    end

    local tLine = Table_GetOperActyInfo(dwOperatActID)
    if tLine and tLine.szTitle then
        UIHelper.SetString(self.LabelNormalName1, UIHelper.GBKToUTF8(tLine.szTitle))
    end

    self.dwOperatActID = dwOperatActID
    self.nID = nID

    self:InitRewardBaseInfo()
    self:UpdateInfo(tLine)
end

function UIAnniversaryGiveBack:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAnniversaryGiveBack:BindUIEvent()
    UIHelper.BindUIEvent(self.TogConsumeDetail, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips,self.TogConsumeDetail, g_tStrings.STR_RECHARGE_REWARD_BTN_TIPS)
    end)

    UIHelper.BindUIEvent(self.BtnGetAll, EventType.OnClick, function ()
        self:GetAllCallServer()
    end)
end

function UIAnniversaryGiveBack:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "On_Recharge_CheckOnSale_CallBack", function (dwID, tRewardInfo, nMoney, bCanDo)
        if self.dwOperatActID == dwID then
            self:UpdateRewardState()
        end
    end)

    Event.Reg(self, "On_Recharge_GetOnSaleRwd_CallBack", function (dwID, tLevelInfo)
        if self.dwOperatActID == dwID then
            self:UpdateRewardState()
        end
    end)
end

function UIAnniversaryGiveBack:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAnniversaryGiveBack:UpdateInfo(tLine)
    self:UpdateTimeInfo(tLine)
    self:UpdateRewardState()

    RemoteCallToServer(REMOTECALL_TABLE[self.dwOperatActID].CHECK, self.dwOperatActID)
end

function UIAnniversaryGiveBack:InitRewardBaseInfo()
    self.tbRewardInfoFromTable = HuaELouData.GetRewardLevelInfoByActivityID(self.dwOperatActID)

    local tbItemScript = {}
    self.tbRewardCell = {}
    UIHelper.RemoveAllChildren(self.ScrollViewReward)

    for nLevel, tRewardInfo in pairs(self.tbRewardInfoFromTable) do
        local RewardCell = UIHelper.AddPrefab(PREFAB_ID.WidgetMonthlyPurchaseRewardCell, self.ScrollViewReward)
        if RewardCell then
            local tInfo = string.split(tRewardInfo.szItems, ";")
            for i = 1, #tInfo do
                tInfo[i] = string.trim(tInfo[i], " ")
                if tInfo[i] ~= "" then
                    local tBoxInfo = string.split(tInfo[i], "_")
                    local dwTabType, dwIndex, nStackNum = tBoxInfo[2], tBoxInfo[3], tBoxInfo[4]

                    local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, RewardCell.LayoutItem)
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
                    table.insert(tbItemScript, itemScript)
                end
            end

            UIHelper.SetString(RewardCell.LabelPurchaseConsunption, FormatString(g_tStrings.STR_RECHARGE_TIME_REWARD_CELL_TIPS, tRewardInfo.nMoney))

            UIHelper.BindUIEvent(RewardCell.TogRewardCell, EventType.OnSelectChanged,function (_, bSelected)
                if bSelected then
                    local szPath = tRewardInfo.szRewardTextureFile
                    szPath = string.gsub(szPath,"/ui/Image/OperationActivity3/Gift_YearCharge","Texture/HuaELouReward/Gift_YearCharge")
                    szPath = string.gsub(szPath, "tga","png")
                    UIHelper.SetTexture(self.ImgRewardPreview,szPath)
                    local sztext = FormatString(g_tStrings.STR_RECHARGE_TIME_REWARD_TIPS, tRewardInfo.nMoney)
                    UIHelper.SetRichText(self.RichTextPreview, sztext)
                end
            end)

            UIHelper.BindUIEvent(RewardCell.BtnGetItem, EventType.OnClick,function ()
                UIHelper.ShowConfirm(g_tStrings.STR_GET_REWARD_SRUE, function ()
                    if self.dwOperatActID == OPERACT_ID.FIRST_CHARGE then
                        RemoteCallToServer(REMOTECALL_TABLE[self.dwOperatActID].GET, tRewardInfo.nLevel, self.dwOperatActID)
                    else
                        RemoteCallToServer(REMOTECALL_TABLE[self.dwOperatActID].GET, self.dwOperatActID, tRewardInfo.nLevel)
                    end
                end)
            end)

            table.insert(self.tbRewardCell, RewardCell)
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewReward)
    if self.tbRewardCell[1] then
        UIHelper.SetSelected(self.tbRewardCell[1].TogRewardCell, true)
    end
end

function UIAnniversaryGiveBack:UpdateTimeInfo(tLine)
    if self.LabelMiddle then
        local tStartTime, tEndTime = tLine.tStartTime, tLine.tEndTime
        local nStart = tStartTime[1]
        local nEnd = tEndTime and tEndTime[1]
        local szText = HuaELouData.GetTimeShowText(nStart, nEnd)

        UIHelper.SetString(self.LabelMiddle, szText)
    end
end

function UIAnniversaryGiveBack:UpdateRewardState()
    local tOperActyInfo = HuaELouData.tOperActyInfo and HuaELouData.tOperActyInfo[self.dwOperatActID] or {}
    if tOperActyInfo and not table_is_empty(tOperActyInfo) then
        UIHelper.SetString(self.LabelConsumeNum, tOperActyInfo.nMoney.."元")
        UIHelper.LayoutDoLayout(self.LayoutDetail)
        local tReward = tOperActyInfo.tRewardInfo

        self.bEnableBtnCollectAllBtn = false
        for i ,RewardCell in ipairs(self.tbRewardCell) do
            local nState = HuaELouData.GetLevelRewardStateOfPlayerByLevel(tReward, i)
            UIHelper.SetVisible(RewardCell.LabelNotAchieved, nState == OPERACT_REWARD_STATE.NON_GET)
            UIHelper.SetVisible(RewardCell.LabelAchieved, nState == OPERACT_REWARD_STATE.CAN_GET)
            UIHelper.SetVisible(RewardCell.BtnGetItem, nState == OPERACT_REWARD_STATE.CAN_GET)
            UIHelper.SetVisible(RewardCell.LabelReceived, nState == OPERACT_REWARD_STATE.ALREADY_GOT)

            self.bEnableBtnCollectAllBtn = self.bEnableBtnCollectAllBtn or nState == OPERACT_REWARD_STATE.CAN_GET
        end

        UIHelper.SetButtonState(self.BtnGetAll, self.bEnableBtnCollectAllBtn and BTN_STATE.Normal or BTN_STATE.Disable)
    end
end

function UIAnniversaryGiveBack:GetAllCallServer()
    UIHelper.ShowConfirm(g_tStrings.STR_GET_REWARD_SRUE, function ()
        if self.dwOperatActID == OPERACT_ID.FIRST_CHARGE then
			RemoteCallToServer(REMOTECALL_TABLE[self.dwOperatActID].GET)
		else
			RemoteCallToServer(REMOTECALL_TABLE[self.dwOperatActID].GET, self.dwOperatActID)
		end
    end)
end

return UIAnniversaryGiveBack