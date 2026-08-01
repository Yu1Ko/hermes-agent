-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIJinXiuNiChang
-- Date: 2023-09-05 10:13:41
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIJinXiuNiChang = class("UIJinXiuNiChang")

local PageName2TogIndex = {
    ["Page_EveryDay"] = 1,
    ["Page_EveryWeek"] = 2,
    ["Page_CyclicTask"] = 3,
}

local TogIndex2PageName = {
    "Page_EveryDay",
    "Page_EveryWeek",
    "Page_CyclicTask",
}

local ImgIcon = {
    "UIAtlas2_HuaELou_JinXiuNiChang_Img_Icon_yunjinhuaban.png",
    "UIAtlas2_HuaELou_JinXiuNiChang_Img_Icon_yunjinhuaban_QD.png",
}



local szQuestImgIcon = "UIAtlas2_HuaELou_JinXiuNiChang_Img_JinXiuIcon_"

local szTongBaoRichImg = "<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_TongBao' width='36' height='36'/>"
local szRichImg1 = "<img src='UIAtlas2_HuaELou_JinXiuNiChang_Img_Icon_yunjinhuaban_QD' width='26' height='26'/>"
local szRichImg2 = "<img src='UIAtlas2_HuaELou_JinXiuNiChang_Img_Icon_yunjinhuaban' width='22' height='22'/>"

function UIJinXiuNiChang:OnEnter(dwOperatActID, nID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local tLine = Table_GetOperActyInfo(dwOperatActID)
    if tLine and tLine.szTitle then
        UIHelper.SetString(self.LabelNormalName1, UIHelper.GBKToUTF8(tLine.szTitle))
    end

    self.dwID = nID
    self.dwOperatActID = dwOperatActID
    self.tOperatActInfo = Table_GetOperActyInfo(self.dwOperatActID)

    RemoteCallToServer("On_Recharge_BattlePassCheck")

    self:InitDataTab()
    self:InitPageInfo()
    self:UpdateInfo()
end

function UIJinXiuNiChang:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIJinXiuNiChang:BindUIEvent()
    for k, v in ipairs(self.tbTogIndex) do
        UIHelper.BindUIEvent(v, EventType.OnSelectChanged, function (_, bSelected)
            if bSelected then
                self.nTogIndex = k
                self:UpdateLeftListPageByQuest()
            end
        end)
    end

    UIHelper.BindUIEvent(self.BtnHelp, EventType.OnClick, function()
        self:ShowItemTip(self.BtnHelp)
    end)

end

function UIJinXiuNiChang:ShowItemTip(btn)
    local nNumOfLeftItemCanGet = self.tActivityInfoOfPlayer.nNumOfLeftItemCanGet
    if not nNumOfLeftItemCanGet then return end
    local szImage = string.gsub(ImgIcon[1], ".png", "")
    local szImage2 = string.gsub(ImgIcon[2], ".png", "")
    local szDesc = string.format("<img src='%s' width='25' height='25'/>", szImage) .. FormatString(g_tStrings.STR_BATTLEPASS_NUM_OF_LEFT_ITEMS, nNumOfLeftItemCanGet[1])
    .. "\n" .. string.format("<img src='%s' width='28' height='28'/>", szImage2) .. FormatString(g_tStrings.STR_BATTLEPASS_NUM_OF_LEFT_ITEMS, nNumOfLeftItemCanGet[2])
    local tip, tipScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetRichTextTips, btn, TipsLayoutDir.BOTTOM_CENTER, szDesc)
    tipScript:SetRichTextWidth(300)
end

function UIJinXiuNiChang:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if UIHelper.GetSelected(self.SelectToggle) then
            UIHelper.SetSelected(self.SelectToggle, false)
        end
    end)

    Event.Reg(self, "On_Recharge_BattlePassCheck", function (tRewardInfo, nNumOfItems, nNumOfLeftItemCanGet, nNumOfItemsTwo, nNumOfLeftItemTwoCanGet)
        self:SetActivityInfoOfPlayer(tRewardInfo, nNumOfItems, nNumOfLeftItemCanGet, nNumOfItemsTwo, nNumOfLeftItemTwoCanGet)
        self:UpdateRewardState()
    end)

    Event.Reg(self, "On_Recharge_BattlePassGetRwd", function (tRewardInfo, nNumOfItems, nNumOfLeftItemCanGet, nNumOfItemsTwo, nNumOfLeftItemTwoCanGet)
        local tRewardInfoOfPlayer = self.tActivityInfoOfPlayer.tRewardInfo
        for dwRewardID, tSingleRewardInfo in pairs(tRewardInfo) do
            tRewardInfoOfPlayer[dwRewardID] = tSingleRewardInfo
        end
        self:SetActivityInfoOfPlayer(tRewardInfoOfPlayer, nNumOfItems, nNumOfLeftItemCanGet, nNumOfItemsTwo, nNumOfLeftItemTwoCanGet)
        self:UpdateRewardState()
    end)

    for nItemNum, v in ipairs(self.tbItemBtn) do
        UIHelper.BindUIEvent(v, EventType.OnClick, function ()
            if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EXTERIOR, "CoinShop") then
                return
            end

            local tItemPrice = self:GetTongBaoPerItem()
            local tItemName = self:GetNameOfItem()

            local fnSureAction = function ()
                CoinShop_BuyItem(self.tItemInfo[nItemNum].dwGoodsID, self.tItemInfo[nItemNum].dwGoodsType, self.nCount)
            end

            self:ShowChooseNumConfirm(tItemPrice[nItemNum], g_tStrings.STR_JINXIU_BUY_1, szTongBaoRichImg, nil, UIHelper.GBKToUTF8(tItemName[nItemNum]), false, fnSureAction)
        end)
    end

    Event.Reg(self, "BAG_ITEM_UPDATE", function (nBox, nIndex)
        local item = ItemData.GetItemByPos(nBox, nIndex)
        if not item then return end

        if IsJinXiuNiChangItem(item.dwTabType, item.dwIndex) then
            if self.nBattlePassCheckTimerID then
               Timer.DelTimer(self, self.nBattlePassCheckTimerID)
               self.nBattlePassCheckTimerID = nil
            end

            self.nBattlePassCheckTimerID = Timer.Add(self, 1, function ()
                RemoteCallToServer("On_Recharge_BattlePassCheck")
                self.nBattlePassCheckTimerID = nil
            end)
        end
    end)
end

function UIJinXiuNiChang:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIJinXiuNiChang:UpdateInfo()
    self:UpdateTimeInfo()
end

function UIJinXiuNiChang:InitDataTab()
    self:SetGoodsInfo()
    self.tQuestInfoFromTable = Table_GetBattlePassQuestInfo()
    self.tRewardInfoFromTable = Table_GetBattlePassRewardInfo()
    self.nTogIndex = 1
    self.nRewardIndex = 0
    self.tSaveRewardByID = {}
end

function UIJinXiuNiChang:SetGoodsInfo()
    local szUserData = Table_GetOperationActUserData(OPERACT_ID.BATTLE_PASS)
    local tUserData = SplitString(szUserData, '|')

    self.tItemInfo = {}
    --字符串 %d;%d 商城商品type,商城商品id
    for i, tItemData in ipairs(tUserData) do
        local tGoodData = SplitString(tItemData, ';')
        self.tItemInfo[i] = {}
        self.tItemInfo[i].dwGoodsType = tonumber(tGoodData[1])
        self.tItemInfo[i].dwGoodsID 	 = tonumber(tGoodData[2])
        self.tItemInfo[i].nIconFrame  = tonumber(tGoodData[3])
    end
    if #self.tItemInfo > 1 then
        self.bTwoProp = true
    end
    self:UpdateGoodsInfo()
end

function UIJinXiuNiChang:UpdateGoodsInfo()
    local tItemInfo = self:GetItemTypeAndItemIndexOfItem()
    local tItemPrice = self:GetTongBaoPerItem()
    local tItemName = self:GetNameOfItem()

    local tbScriptItem = {}

    if self.bTwoProp then
        for k, v in ipairs(self.tbItemWidget) do
            local ScriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, v)
            if ScriptItem then
                ScriptItem:OnInitWithTabID(tItemInfo[k].dwItemTabType, tItemInfo[k].dwItemTabIndex, 1)
                ScriptItem:SetClickCallback(function (nTabType, nTabID)
                    self.SelectToggle = ScriptItem.ToggleSelect
                    if nTabType and nTabID then
                        local _, scriptItemTip = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip,self.SelectToggle)
                        scriptItemTip:OnInitWithTabID(nTabType, nTabID)
                        scriptItemTip:SetBtnState({})

                        for _,iScript in ipairs(tbScriptItem) do
                            if UIHelper.GetSelected(iScript.ToggleSelect) and ScriptItem.ToggleSelect ~= iScript.ToggleSelect then
                                UIHelper.SetSelected(iScript.ToggleSelect,false)
                            end
                        end
                    end
                end)
                table.insert(tbScriptItem, ScriptItem)
            end
            UIHelper.SetString(self.tbItemPrice[k], tItemPrice[k])
            UIHelper.SetString(self.tbItemName[k], UIHelper.GBKToUTF8(tItemName[k]))
        end
    end
end

function UIJinXiuNiChang:GetItemTypeAndItemIndexOfItem()
    local tInfo = {}
    for i, Item in ipairs(self.tItemInfo) do
        tInfo[i] = GetRewardsShop().GetRewardsShopInfo(Item.dwGoodsID)
    end
    return tInfo
end

function UIJinXiuNiChang:GetTongBaoPerItem()
    local tItemPrice = {}
    for i, ItemInfo in ipairs(self.tItemInfo) do
        tItemPrice[i] = CoinShop_GetPrice(ItemInfo.dwGoodsID, ItemInfo.dwGoodsType) or 0
    end
    return tItemPrice
end

function UIJinXiuNiChang:GetNameOfItem()
    local tInfo = self:GetItemTypeAndItemIndexOfItem()
    local tItemName = {}
    for i, ItemInfo in ipairs(tInfo) do
        local hItemInfo = ItemData.GetItemInfo(ItemInfo.dwItemTabType, ItemInfo.dwItemTabIndex)
        if hItemInfo then
            tItemName[i] =  ItemData.GetItemNameByItemInfo(hItemInfo)
        else
            tItemName[i] = ""
        end
    end
    return tItemName
end

function UIJinXiuNiChang:InitPageInfo()
    self:MockActiveLeftListDefaultPage()
    self:InitRewardRightList()
end

function UIJinXiuNiChang:MockActiveLeftListDefaultPage()
    self:UpdateLeftListPageByQuest()
end

function UIJinXiuNiChang:UpdateLeftListPageByQuest()
    local tQuestInfoFromTable = self.tQuestInfoFromTable
    local tListQuestInfo = tQuestInfoFromTable[TogIndex2PageName[self.nTogIndex]]

    local tActivityInfoFromOperatact = self.tOperatActInfo

    self:UpdateQuestCellWithQuestInfo(tListQuestInfo)
end

function UIJinXiuNiChang:UpdateQuestCellWithQuestInfo(tListQuestInfo)
    UIHelper.RemoveAllChildren(self.ScrollViewLeft)
    for k, tQuestInfo in ipairs(tListQuestInfo) do

        local ScriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetJinXiuTask, self.ScrollViewLeft)
        if ScriptCell then
            UIHelper.SetString(ScriptCell.LabelTask, UIHelper.GBKToUTF8(tQuestInfo.szQuestDesc))
            UIHelper.SetString(ScriptCell.LabelRewardNum01, tQuestInfo.nItemCanGet)
            UIHelper.SetString(ScriptCell.LabelRewardNum02, tQuestInfo.nItemTwoCanGet)
            UIHelper.SetString(ScriptCell.LabelRewardNum03, tQuestInfo.nGoldCanGet)
            UIHelper.SetVisible(ScriptCell.LayoutReward03, tQuestInfo.nGoldCanGet~=0)
            UIHelper.SetSpriteFrame(ScriptCell.ImgIcon, szQuestImgIcon..tQuestInfo.nIconFrame)
            UIHelper.SetVisible(ScriptCell.ImgGoto, tQuestInfo.szLink ~= "")

            self:UpdateQuestModState(ScriptCell, tQuestInfo)

            UIHelper.BindUIEvent(ScriptCell.BtnTask, EventType.OnClick, function ()
                if tQuestInfo.szLink ~= "" then
                    HuaELouData.HandleJump(tQuestInfo.szLink)
                end
            end)

            local nBuffFinish  = 0
            local nQuestFinish = 0
            local nFinishCount = 0
            local szQuestID = tQuestInfo.szQuestID
            local nBuffID = tQuestInfo.nBuffID
            local nMaxCount = tQuestInfo.nNumOfMaxFinished

            if nBuffID ~= 0 then
                local buff = Player_GetBuff(nBuffID)
                if buff then
                    nBuffFinish = buff.nStackNum
                end
            end
            if szQuestID ~= "" then
                local tQuestIDs = SplitString(tQuestInfo.szQuestID, ";")
                for _, szQuest in ipairs(tQuestIDs) do
                    local dwQuestID = tonumber(szQuest)
                    local nFinishedCount, nTotalCount = g_pClientPlayer.GetRandomDailyQuestFinishedCount(dwQuestID)
                    if nFinishedCount == nTotalCount then
                        nQuestFinish = nQuestFinish + 1
                    end
                end
            end

            nFinishCount = math.max(nBuffFinish, nQuestFinish)
            local szFinish = string.format("%d/%d", nFinishCount, nMaxCount)
            UIHelper.SetString(ScriptCell.LabelNum, szFinish)
            UIHelper.SetVisible(ScriptCell.LabelNum, (nBuffID ~= 0 or szQuestID ~= "") and nMaxCount > 1 and nFinishCount < nMaxCount )

            for i, v in ipairs(ScriptCell.tbLayoutReward) do
                UIHelper.LayoutDoLayout(v)
            end
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewLeft)
end

function UIJinXiuNiChang:UpdateQuestModState(ScriptCell, tQuestInfo)
	local nMaxCount = tQuestInfo.nNumOfMaxFinished
	local szQuestID = tQuestInfo.szQuestID or ""
	local nBuffID = tQuestInfo.nBuffID or 0
	local nBuffFinish = 0
	local nQuestFinish = 0

    if nBuffID == 0 and szQuestID == "" then
        UIHelper.SetVisible(ScriptCell.LabelFinished, false)
        UIHelper.SetVisible(ScriptCell.LabelFinishedNot, false)
        return
    end

	if nBuffID and nBuffID ~= 0 then
		local buff = Player_GetBuff(tQuestInfo.nBuffID)
		if buff then
			nBuffFinish = buff.nStackNum
		end
	end

	if szQuestID ~= "" then
		local tQuestIDs = SplitString(szQuestID, ";")
		for _, szQuest in ipairs(tQuestIDs) do
			local nFinishedCount, nTotalCount = g_pClientPlayer.GetRandomDailyQuestFinishedCount(tonumber(szQuest))
			if nFinishedCount == nTotalCount then
				nQuestFinish = nQuestFinish + 1
			end
		end
	end

	local nFinishCount = math.max(nBuffFinish, nQuestFinish)

    UIHelper.SetVisible(ScriptCell.LabelFinished, nFinishCount >= nMaxCount)
    UIHelper.SetVisible(ScriptCell.LabelFinishedNot, nMaxCount == 1 and nFinishCount == 0)
    UIHelper.SetVisible(ScriptCell.LabelNum, nMaxCount > 1 and nFinishCount < nMaxCount)
end

function UIJinXiuNiChang:InitRewardRightList()
    local tAllRewardInfoFromTable = self.tRewardInfoFromTable

    UIHelper.RemoveAllChildren(self.ScrollViewRight)
    local tbItemScript = {}
    self.tbRewardCell = {}

    for nRewardID, tRewardInfoFromTable in ipairs(tAllRewardInfoFromTable) do
        local ScriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetJinXiuReward, self.ScrollViewRight)
        if ScriptCell then
            UIHelper.SetString(ScriptCell.LabelRewardName, UIHelper.GBKToUTF8(tRewardInfoFromTable.szName))
            local ScriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, ScriptCell.WidgetItem80)
            if ScriptItem then
                self:UpdateRewardInfo(tRewardInfoFromTable, ScriptItem, tbItemScript)
                table.insert(tbItemScript, ScriptItem)
            end

            if tRewardInfoFromTable.nItemNeeded > 0 then
                UIHelper.SetString(ScriptCell.LabelRewardNum, tRewardInfoFromTable.nItemNeeded)
                UIHelper.SetSpriteFrame(ScriptCell.ImgIcon01, ImgIcon[1])
            elseif tRewardInfoFromTable.nItemTwoNeeded > 0 then
                UIHelper.SetString(ScriptCell.LabelRewardNum, tRewardInfoFromTable.nItemTwoNeeded)
                UIHelper.SetSpriteFrame(ScriptCell.ImgIcon01, ImgIcon[2])
            end

            UIHelper.SetVisible(ScriptCell.BtnMore, tRewardInfoFromTable.szRewardTextureOrLink ~= "")
            UIHelper.BindUIEvent(ScriptCell.BtnMore, EventType.OnClick, function ()
                FireUIEvent("EVENT_LINK_NOTIFY", tRewardInfoFromTable.szRewardTextureOrLink)
            end)

            UIHelper.BindUIEvent(ScriptCell.BtnGet, EventType.OnClick, function ()
                local nPrice, szText, szRichImg
                if tRewardInfoFromTable.nItemNeeded > 0 then
                    nPrice = tRewardInfoFromTable.nItemNeeded
                    szText = g_tStrings.STR_JINXIU_BUY_2
                    szRichImg = szRichImg2
                elseif tRewardInfoFromTable.nItemTwoNeeded > 0 then
                    nPrice = tRewardInfoFromTable.nItemTwoNeeded
                    szText = g_tStrings.STR_JINXIU_BUY_3
                    szRichImg = szRichImg1
                end

                local nLimit = (tAllRewardInfoFromTable[nRewardID] and tAllRewardInfoFromTable[nRewardID].nLimit) or 0

                local fnSureAction = function ()
                    RemoteCallToServer("On_Recharge_BattlePassGetRwd", tRewardInfoFromTable.dwID, self.nCount)
                end
                local szNmae = self:GetRewardName(tRewardInfoFromTable)

                self:ShowChooseNumConfirm(nPrice, szText, szRichImg, nLimit < 0 and nil or nLimit, szNmae, nLimit == 1 and true or false, fnSureAction)
            end)

            table.insert(self.tbRewardCell, ScriptCell)
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRight)
end

function UIJinXiuNiChang:UpdateRewardInfo(tRewardInfoFromTable, ScriptItem, tbItemScript)
    local tBoxInfo = string.split(tRewardInfoFromTable.szItem, "_")
    ScriptItem:OnInitWithTabID(tBoxInfo[2], tBoxInfo[3], tBoxInfo[4])
    ScriptItem:SetClickCallback(function (nTabType, nTabID)
        self.SelectToggle = ScriptItem.ToggleSelect
        if nTabType and nTabID then
            local _, scriptItemTip = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip,self.SelectToggle)
            scriptItemTip:OnInitWithTabID(nTabType, nTabID)
            scriptItemTip:SetBtnState({})

            for _,iScript in ipairs(tbItemScript) do
                if UIHelper.GetSelected(iScript.ToggleSelect) and ScriptItem.ToggleSelect ~= iScript.ToggleSelect then
                    UIHelper.SetSelected(iScript.ToggleSelect,false)
                end
            end
        end
    end)
    UIHelper.SetNodeSwallowTouches(ScriptItem.ToggleSelect, false, true)
end

function UIJinXiuNiChang:GetRewardName(tRewardInfoFromTable)
    local tBoxInfo = string.split(tRewardInfoFromTable.szItem, "_")
    local itemInfo = ItemData.GetItemInfo(tBoxInfo[2], tBoxInfo[3])

    local szItemName = string.format("<color=%s>%s</c>", ItemQualityColor[itemInfo.nQuality + 1], UIHelper.GBKToUTF8(itemInfo.szName))

    return szItemName
end

function UIJinXiuNiChang:UpdateRewardState()
    UIHelper.SetString(self.LabelCoinsNum01, self.tActivityInfoOfPlayer.nNumOfItems[1])
    UIHelper.SetString(self.LabelCoinsNum02, self.tActivityInfoOfPlayer.nNumOfItems[2])
    UIHelper.LayoutDoLayout(self.LayoutCoins01)
    UIHelper.LayoutDoLayout(self.LayoutCoins02)
    UIHelper.LayoutDoLayout(self.WidgetAnchorCoins)

    for nRewardID, ScriptCell in ipairs(self.tbRewardCell) do
        local szTextBuy = self:GetBuyNumText(nRewardID)
        UIHelper.SetString(ScriptCell.LabelRewardNum01, szTextBuy)
        local tAllRewardInfoOfPlayer = self.tActivityInfoOfPlayer and self.tActivityInfoOfPlayer.tRewardInfo or {}
        local tRewardInfoFromTable = self.tRewardInfoFromTable[nRewardID]
        if  tAllRewardInfoOfPlayer and tAllRewardInfoOfPlayer[tRewardInfoFromTable.dwID] then
            local tRewardInfoOfPlayer = tAllRewardInfoOfPlayer[tRewardInfoFromTable.dwID]
            UIHelper.SetVisible(ScriptCell.BtnGet, tRewardInfoOfPlayer.nCanGet > 0)
            UIHelper.SetVisible(ScriptCell.WidgetNotAchieved, tRewardInfoOfPlayer.nCanGet <= 0 and tRewardInfoOfPlayer.nGot <= 0)
            UIHelper.SetVisible(ScriptCell.WidgetGotten, tRewardInfoOfPlayer.nCanGet <= 0 and tRewardInfoOfPlayer.nGot > 0)
        end
    end
end

function UIJinXiuNiChang:GetBuyNumText(nRewardID)
    local tAllRewardInfoFromTable = self.tRewardInfoFromTable
    local nLimit = (tAllRewardInfoFromTable[nRewardID] and tAllRewardInfoFromTable[nRewardID].nLimit) or 0
    local tRewardInfoOfPlayer = self.tActivityInfoOfPlayer.tRewardInfo

    if nLimit < 0 then
        return g_tStrings.STR_REWARD_UNLIMITED
    end

    if not tRewardInfoOfPlayer or not tRewardInfoOfPlayer[nRewardID] then
        return "0/" .. nLimit
    end

    if  tRewardInfoOfPlayer[nRewardID].nGot == -1 then
        return g_tStrings.STR_REWARD_UNLIMITED
    end

    return  tRewardInfoOfPlayer[nRewardID].nGot .. "/" .. nLimit
end


function UIJinXiuNiChang:SetActivityInfoOfPlayer(tRewardInfo, nNumOfItems, nNumOfLeftItemCanGet, nNumOfItemsTwo, nNumOfLeftItemTwoCanGet)
    if not self.tActivityInfoOfPlayer then
        self.tActivityInfoOfPlayer =  {}
    end

    self.tActivityInfoOfPlayer.tRewardInfo = tRewardInfo
    self.tActivityInfoOfPlayer.nNumOfItems = self.tActivityInfoOfPlayer.nNumOfItems or {}
    self.tActivityInfoOfPlayer.nNumOfItems[1] = nNumOfItems
    self.tActivityInfoOfPlayer.nNumOfLeftItemCanGet = self.tActivityInfoOfPlayer.nNumOfLeftItemCanGet or {}
    self.tActivityInfoOfPlayer.nNumOfLeftItemCanGet[1] = nNumOfLeftItemCanGet

    if self.bTwoProp then
        self.tActivityInfoOfPlayer.nNumOfLeftItemCanGet[2] = nNumOfLeftItemTwoCanGet
        self.tActivityInfoOfPlayer.nNumOfItems[2] = nNumOfItemsTwo
    end
end

function UIJinXiuNiChang:IsRewardCanBeReceived()
    local bFlag = false
    local tRewardInfoOfPlayer = self.tActivityInfoOfPlayer.tRewardInfo
    if tRewardInfoOfPlayer then
        for _, tSingleInfo in pairs(tRewardInfoOfPlayer) do
            if tSingleInfo.nCanGet > 0 then
                bFlag = true
                break
            end
        end
    end

    return bFlag
end

function UIJinXiuNiChang:UpdateTimeInfo()
    local tLine = self.tOperatActInfo
    if self.LabelMiddle then
        local tStartTime, tEndTime = tLine.tStartTime, tLine.tEndTime
        local nStart = tStartTime[1]
        local nEnd = tEndTime and tEndTime[1]
        local szText = HuaELouData.GetTimeShowText(nStart, nEnd)

        UIHelper.SetString(self.LabelMiddle, szText)
    end
end

function UIJinXiuNiChang:ShowChooseNumConfirm(nPrice, szJinxiuBuy, szRichImg, nMaxCount, szItemName, bLimit, fnSureAction)
    local scriptView = UIMgr.Open(VIEW_ID.PanelNormalConfirmation, "")
    if scriptView then
        self.nCount = 1
        self.nMoney = nPrice * self.nCount
        local szContent = string.format(szJinxiuBuy, self.nMoney, szRichImg, szItemName)

        local funcAdd = function ()
            self.nCount = tonumber(scriptView:GetChooseNum()) or 0
            if not nMaxCount or nMaxCount <= 0 or self.nCount < nMaxCount then
                self.nCount = self.nCount + 1
            else
                self.nCount = 1
            end
            self.nMoney = nPrice * self.nCount
            szContent = string.format(szJinxiuBuy, self.nMoney, szRichImg, szItemName)
            scriptView:SetChooseNum(szContent, self.nCount)
        end

        local funcMinus = function ()
            self.nCount = tonumber(scriptView:GetChooseNum()) or 0
            if self.nCount > 1 then
                self.nCount = self.nCount - 1
            end
            self.nMoney = nPrice * self.nCount
            szContent = string.format(szJinxiuBuy, self.nMoney, szRichImg, szItemName)
            scriptView:SetChooseNum(szContent, self.nCount)
        end

        local fnEditAction = function ()
            self.nCount = tonumber(scriptView:GetChooseNum()) or 1
            self.nCount = math.ceil(self.nCount)
            if nMaxCount and nMaxCount > 0 and self.nCount > nMaxCount then
                self.nCount = nMaxCount
            elseif self.nCount < 1 then
                self.nCount = 1
            end
            self.nMoney = nPrice * self.nCount
            szContent = string.format(szJinxiuBuy, self.nMoney, szRichImg, szItemName)
            scriptView:SetChooseNum(szContent, self.nCount)
        end

        scriptView:SetChooseNumContent(szContent, self.nCount, (not bLimit) and funcAdd or nil, (not bLimit) and funcMinus or nil, fnSureAction, fnEditAction)
    end
end


return UIJinXiuNiChang