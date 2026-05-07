-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIShoppingDyeingGift
-- Date: 2023-05-22 14:53:06
-- Desc: 简单按钮活动
-- ---------------------------------------------------------------------------------

local UIShoppingDyeingGift = class("UIShoppingDyeingGift")

function UIShoppingDyeingGift:OnEnter(dwOperatActID, nID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local tActivity = UIHuaELouActivityTab[nID]
    if not tActivity then
        return
    end

    self.nID = nID
    self.dwOperatActID = dwOperatActID
    self.nBtnID = tActivity.nBtnID

    local tLine = Table_GetOperActyInfo(dwOperatActID)
    if tLine and tLine.szTitle then
        UIHelper.SetString(self.LabelNormalName1, UIHelper.GBKToUTF8(tLine.szTitle))
    end

    self:UpdateBtnPos(tActivity)
    self:UpdateInfo()
end

function UIShoppingDyeingGift:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIShoppingDyeingGift:BindUIEvent()

end

function UIShoppingDyeingGift:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "On_Recharge_CheckWelfare_CallBack", function (nLimit, nReward, nMoney, bActive, bIsBespoke, dwID, tCustom, szCustom)
        if dwID == self.dwOperatActID then
            self:On_Recharge_CheckWelfare_CallBack(nLimit, nReward, nMoney, bActive, bIsBespoke, dwID, tCustom, szCustom)
        end
    end)

    Event.Reg(self, "On_Recharge_GetWelfareRwd_CallBack", function (dwID, nRewardID)
        if dwID == self.dwOperatActID then
            if HuaELouData.tCustom[self.dwOperatActID] then
                self:UpdateRewardBtns(HuaELouData.tCustom[self.dwOperatActID])
            end
        end
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        if UIHelper.GetSelected(self.SelectToggle) then
            UIHelper.SetSelected(self.SelectToggle, false)
        end
    end)

    Event.Reg(self, "COIN_SHOP_BUY_RESPOND", function (nActivityID)
        self:CheckAndProcessHandleOfBuy()
        if HuaELouData.tCustom[self.dwOperatActID] then
            self:UpdateRewardBtns(HuaELouData.tCustom[self.dwOperatActID])
        end
    end)

    Event.Reg(self, "COIN_SHOP_SAVE_RESPOND", function (nActivityID)
        self:CheckAndProcessHandleOfBuy()
        if HuaELouData.tCustom[self.dwOperatActID] then
            self:UpdateRewardBtns(HuaELouData.tCustom[self.dwOperatActID])
        end
    end)

    Event.Reg(self, "Update_Target_List", function(szLink)
        local tTargetList
        if szLink and szLink ~= "" then
            tTargetList = HuaELouData.GetTargetList(nil, szLink)
        else
            tTargetList = HuaELouData.GetTargetList(self.dwOperatActID, nil)
        end
        -- local tTargetList = HuaELouData.GetTargetList(self.dwOperatActID)
        if tTargetList and (not table_is_empty(tTargetList)) then
            local tbBtnPos = self:GetTargetListBtn(szLink)
            if tbBtnPos and UIHelper.GetVisible(tbBtnPos) then
                local  _, scriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicTraceTip, tbBtnPos, TipsLayoutDir.TOP_CENTER)
                if scriptView then
                    scriptView:OnEnter(tTargetList)
                end
            end
        end
    end)

    Event.Reg(self, EventType.OnSelectLeaveForBtn, function(tbInfo)
        TipsHelper.DeleteAllHoverTips()
		ActivityData.Teleport_Go(tbInfo)
	end)

    Event.Reg(self, "ON_JJC_GET_BUFF_CUSTOM_VALUE", function(nCustomValue)
        if self.dwOperatActID == 193 then
            self.nMasterBuffCustomValue = nCustomValue or 0
            self:UpdataRewardSpecialItem()
        end
    end)
end

function UIShoppingDyeingGift:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIShoppingDyeingGift:UpdateBtnPos(tActivity)
    if not self.tbPublicBtn then
        return
    end

    for k, PublicBtn in ipairs(self.tbPublicBtn) do
        local nBtnID, nBtnPosX, nBtnPosY = self:GetBtnInfo(k, tActivity)

        local scriptBtn = UIHelper.GetBindScript(PublicBtn) assert(scriptBtn)
        if nBtnID ~= 0 then
            scriptBtn:OnEnter(nBtnID)
        end
        UIHelper.SetVisible(PublicBtn, nBtnID ~= 0 or (scriptBtn.nID ~= nil and tonumber(scriptBtn.nID) ~= 0))

        if (nBtnPosX ~= 0 or nBtnPosY~= 0)  then
            UIHelper.SetPosition(PublicBtn, nBtnPosX, nBtnPosY)
        end
    end

    if tActivity.szbgImgPath ~= "" and self.BgGift then
        UIHelper.SetTexture(self.BgGift, tActivity.szbgImgPath)
    end
end

function UIShoppingDyeingGift:GetBtnInfo(k, tActivity)
    local nBtnID, nBtnPosX, nBtnPosY
    if k == 1 then
        nBtnID = tActivity.nBtnID
        nBtnPosX = tActivity.tbBtnPosXY[1]
        nBtnPosY = tActivity.tbBtnPosXY[2]
    elseif k ==2 then
        nBtnID = tActivity.nBtnID2
        nBtnPosX = tActivity.tbBtn2PosXY[1]
        nBtnPosY = tActivity.tbBtn2PosXY[2]
    elseif k ==3 then
        nBtnID = tActivity.nBtnID3
        nBtnPosX = tActivity.tbBtn3PosXY[1]
        nBtnPosY = tActivity.tbBtn3PosXY[2]
    end

    return nBtnID, nBtnPosX, nBtnPosY
end

function UIShoppingDyeingGift:UpdateInfo()
    local tLine = Table_GetOperActyInfo(self.dwOperatActID)
    self:CheckAndProcessHandleOfBuy()
    self:SyncExtPoint(tLine)
    self:RemoteCallBatchCheck(tLine)
    self:UpdateTimeInfo(tLine)
    self:UpdataRewardItem()
    self:UpdataRewardItem_60()
    self:UpdataRewardSpecialItem()
    self:UpdataRewardItem_Layout()
    self:UpdataRewardItem_Scrollview()
    self:DelegateInitMainPage2SpecificActivities(tLine)
    self:UpdataSpecialInfo()

    if HuaELouData.tCustom[self.dwOperatActID] then
        self:UpdateRewardBtns(HuaELouData.tCustom[self.dwOperatActID])
    end
end

function UIShoppingDyeingGift:SyncExtPoint(tLine)
    if tLine and tLine.bUseExtPoint then
        local tInfo = GDAPI_CheckWelfare(self.dwOperatActID)

        if tInfo and tInfo.dwID == self.dwOperatActID then
            self:On_Recharge_CheckWelfare_CallBack(tInfo.nLimit, tInfo.nReward, tInfo.nMoney, tInfo.bActive, tInfo.bIsBespoke, tInfo.dwID, tInfo.tCustom, tInfo.szCustom)
        end
    end
end

function UIShoppingDyeingGift:RemoteCallBatchCheck(tLine)
    local tToCheckOperatID = {}
    if tLine and tLine.bNeedRemoteCall then
        table.insert(tToCheckOperatID, self.dwOperatActID)
    end

    if not table.is_empty(tToCheckOperatID) then
        RemoteCallToServer("On_Recharge_CheckWelfare", tToCheckOperatID)
    end
end

function UIShoppingDyeingGift:On_Recharge_CheckWelfare_CallBack(nLimit, nReward, nMoney, bActive, bIsBespoke, dwID, tCustom, szCustom)
    self.tReward = {
		[1] = {nLimit, nReward},
	}

    if self.LabelMoney then
        UIHelper.SetString(self.LabelMoney, nMoney)
    else
        local WidgetAct = UIHelper.GetChildByName(self.WidgetAniBg, "WidgetAct_"..tostring(self.dwOperatActID))
        if WidgetAct then
            local LayoutDesc = UIHelper.GetChildByName(WidgetAct, "LayoutDesc")
            if LayoutDesc then
                local LabelMoney =  UIHelper.GetChildByName(LayoutDesc, "LabelMoney")
                UIHelper.SetString(LabelMoney, nMoney)
                UIHelper.LayoutDoLayout(LayoutDesc)
            end
        end
        UIHelper.SetVisible(WidgetAct, true)
    end

    if tCustom and tCustom.tValueList and self.tCustomValue then
        for i, v in pairs(tCustom.tValueList) do
            if self.tCustomValue[i] then
                UIHelper.SetString(self.tCustomValue[i], v)
            end
        end
    end
    if self.tbLayout then
        for _, v in ipairs(self.tbLayout) do
            UIHelper.LayoutDoLayout(v)
        end
    end
end

function UIShoppingDyeingGift:DelegateInitMainPage2SpecificActivities(tLine)
    if tLine and (self.dwOperatActID == OPERACT_ID.GIVE_MONTH_CARD or OPERACT_ID.GIVE_DIANKA == self.dwOperatActID or tLine.bUseExtPoint) then
        local nChargedMoney = g_pClientPlayer.GetExtPoint(tonumber(tLine.szUserData)) or 0
        if self.LabelMoney then
            if self.dwOperatActID == OPERACT_ID.GIVE_MONTH_CARD then
                UIHelper.SetString(self.LabelMoney, nChargedMoney .. "通宝")
            else

                UIHelper.SetString(self.LabelMoney, nChargedMoney)
            end
            UIHelper.SetVisible(self.LayoutDesc, true)
        else
            local WidgetAct = UIHelper.GetChildByName(self.WidgetAniBg, "WidgetAct_"..tostring(self.dwOperatActID))
            if WidgetAct then
                local LayoutDesc = UIHelper.GetChildByName(WidgetAct, "LayoutDesc")
                if LayoutDesc then
                    local LabelMoney =  UIHelper.GetChildByName(LayoutDesc, "LabelMoney")
                    UIHelper.SetString(LabelMoney, nChargedMoney)
                    UIHelper.LayoutDoLayout(LayoutDesc)
                end
            end
            UIHelper.SetVisible(WidgetAct, true)
        end
    end
end

function UIShoppingDyeingGift:UpdataSpecialInfo()
    if self.dwOperatActID == OPERACT_ID.MingJianCuiFeng then
        UIHelper.RemoveAllChildren(self.WidgetItem)
        local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, self.WidgetItem)
        if itemScript then
            local nBuffID, nLevel = 23137, 1
            local szName = BuffMgr.GetBuffName(nBuffID, nLevel)
            local szDesc = BuffMgr.GetBuffDesc(nBuffID, nLevel)
            local szIcon = TabHelper.GetBuffIconPath(nBuffID, nLevel)
            local szPath = szIcon and string.format("Resource/icon/%s", szIcon)
            if szPath then
                UIHelper.SetTexture(self.ImgBuffIcon, szPath)
            end
            itemScript:OnInitWithIconID()
            itemScript:SetIconByTexture(szPath)
            UIHelper.SetVisible(itemScript.ImgPolishCountBG, false)
            itemScript:HideLabelCount()
            itemScript:SetClickCallback(function ()
                local tips, tipsScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips
                , itemScript._rootNode, TipsLayoutDir.BOTTOM_RIGHT, szName.."\n"..szDesc)
                if UIHelper.GetSelected(itemScript.ToggleSelect) then
                    UIHelper.SetSelected(itemScript.ToggleSelect,false)
                end
            end)
        end
    end

    if self.dwOperatActID == 193 then
        ArenaData.GetMasterBuffCustomValue()
    end
end

function UIShoppingDyeingGift:UpdateTimeInfo(tLine)
    if self.LabelMiddle then
        local szText = ""
        if tLine.szCustomTime and tLine.szCustomTime ~= "" then
            szText = UIHelper.GBKToUTF8(tLine.szCustomTime)
        else
            local tStartTime, tEndTime = tLine.tStartTime, tLine.tEndTime
            local nStart = tStartTime[1]
            local nEnd = tEndTime and tEndTime[1]
            szText = HuaELouData.GetTimeShowText(nStart, nEnd) or ""
        end

        UIHelper.SetString(self.LabelMiddle, szText)
        if self.WidgetAnchorBottom then
            UIHelper.SetVisible(self.WidgetAnchorBottom, szText ~= "")
        end
    end
end

function UIShoppingDyeingGift:UpdataRewardItem()
    local tReward = HuaELouData.GetShowReward(self.nID)
    if tReward and not table_is_empty(tReward) then
        for k, v in ipairs(self.tbItem) do
            local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, v)
            if itemScript then
                self:UpdataItemScript(itemScript, tReward, k)
            end
        end
    end
end

function UIShoppingDyeingGift:UpdataRewardItem_60()
    local tReward = HuaELouData.GetShowReward(self.nID)
    if tReward and not table_is_empty(tReward) then
        for k, v in ipairs(self.tbItem_60) do
            local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, v)
            if itemScript then
                self:UpdataItemScript(itemScript, tReward, k)
            end
        end
    end
end

--这个奖励很特殊 除了展示之外还需要有领取状态
function UIShoppingDyeingGift:UpdataRewardSpecialItem()
    if self.dwOperatActID ~= 193 then
        return
    end

    local tRewardInfo = Table_GetArenaCropRewardInfo()
	for nIndex, tLine in ipairs(tRewardInfo) do
        UIHelper.RemoveAllChildren(self.tSpecialReward[nIndex])
		for k, tItem in ipairs(tLine.tItem) do
            local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, self.tSpecialReward[nIndex])
            cell:SetClickNotSelected(true)
            cell:OnInitWithTabID(tItem.dwTabType, tItem.dwIndex)
            cell:SetLabelCount(tItem.nCount)

            cell:SetClickCallback(function(nTabType, nTabID)
                local _, scriptWinRewardItemTip = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, cell._rootNode)
                scriptWinRewardItemTip:OnInitWithTabID(nTabType, nTabID)
                local tbBtnInfo = {}
                TreasureBoxData.GetPreviewBtn(tbBtnInfo, nTabType, nTabID)
                scriptWinRewardItemTip:SetBtnState(tbBtnInfo)
            end)

            self.nMasterBuffCustomValue = self.nMasterBuffCustomValue or 0
            local bReceived = math.floor((self.nMasterBuffCustomValue + 1) / 2) >= nIndex
            cell:SetItemReceived(bReceived)
        end
        UIHelper.LayoutDoLayout(self.tSpecialReward[nIndex])
	end
end

function UIShoppingDyeingGift:UpdataRewardState(nLimit, nReward, nMoney, bActive, bAppoint, dwID, tCustom, szCustom)
    if dwID == self.dwOperatActID then
        UIHelper.SetButtonState(self.BtnReceive, (nLimit == 1 and nReward == 0) and BTN_STATE.Normal or BTN_STATE.Disable)
        UIHelper.SetTouchEnabled(self.BtnReceive, nLimit == 1 and nReward == 0)
        if self.LabelReceive then
            if nLimit == 1 and nReward == 0 then
                UIHelper.SetString(self.LabelReceive, "立即领取")
            elseif  nReward == 1 then
                UIHelper.SetString(self.LabelReceive, "已领取")
            end
        end

        if tCustom then
            for i, v in pairs(tCustom.tValueList) do
                if self.tbCustomValue and self.tbCustomValue[i] then
                    UIHelper.SetRichText(self.tbCustomValue[i], v)
                    -- UIHelper.SetString(self.tbCustomValue[i], v)
                elseif self.tbCustomValueLabel and self.tbCustomValueLabel[i] then
                    UIHelper.SetString(self.tbCustomValueLabel[i], v)
                end
            end
        end

        if nMoney then
            if self.LabelMoney then
                UIHelper.SetString(self.LabelMoney, nMoney)
            end
        end
    end
end

function UIShoppingDyeingGift:UpdataRewardItem_Layout()
    if not self.LayoutContent then
        return
    end

    local tReward = HuaELouData.GetShowReward(self.nID)
    UIHelper.RemoveAllChildren(self.LayoutContent)
    if  tReward and not table_is_empty(tReward) and self.LayoutContent then
        for k, v in ipairs(tReward) do
            local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.LayoutContent)
            self:UpdataItemScript(itemScript, tReward, k)
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutContent)
end

function UIShoppingDyeingGift:UpdataRewardItem_Scrollview()
    if not self.ScrollViewItem then
        return
    end

    local tReward = HuaELouData.GetShowReward(self.nID)
    UIHelper.RemoveAllChildren(self.ScrollViewItem)
    if tReward and not table_is_empty(tReward) and self.ScrollViewItem then
        for k, v in ipairs(tReward) do
            local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.ScrollViewItem)
            if itemScript then
                self:UpdataItemScript(itemScript, tReward, k)
            end
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewItem)
end

function UIShoppingDyeingGift:UpdataItemScript(itemScript, tReward, k)
    if itemScript then
        itemScript:OnInitWithTabID(tReward[k][1], tReward[k][2], tReward[k][3])
        itemScript:SetClickCallback(function (nTabType, nTabID)
            self.SelectToggle = itemScript.ToggleSelect

            local _, scriptItemTip = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip,self.SelectToggle)
            scriptItemTip:OnInitWithTabID(nTabType, nTabID)
        end)
    end
end

function UIShoppingDyeingGift:CheckAndProcessHandleOfBuy()
    if self.tbBtnShopBuy then
        for v, tBtn in ipairs(self.tbBtnShopBuy) do
            local scriptBtn = UIHelper.GetBindScript(tBtn)
            if scriptBtn then
                local tbInfo = UIBtnCtrlTab[tonumber(scriptBtn.nID)]
                local szAction = tbInfo.tbActionFunc[1]
                local szActionLinkInfo = string.split(szAction, "'")
                local szLinkInfo = szActionLinkInfo[2]

                local tInfo = SplitString(szLinkInfo, "-")
                local szBuyLinkInfo = tInfo[2]

                local tStringInfo = SplitString(szBuyLinkInfo, '|')
                local eGoodsType, dwGoodsID = tonumber(tStringInfo[1]), tonumber(tStringInfo[2])
                if IsHavePreOrder(eGoodsType, dwGoodsID) then
                else
                    scriptBtn:UpdateBtnState(BTN_STATE.Disable)
                end
            end
        end
    end
end

function UIShoppingDyeingGift:GetTargetListBtn(szLink)
    if not self.tbPublicBtn then
        return
    end

    for _, PublicBtn in ipairs(self.tbPublicBtn) do
        local scriptBtn = UIHelper.GetBindScript(PublicBtn) assert(scriptBtn)
        local tbInfo = UIBtnCtrlTab[scriptBtn.nID]
        for _, v in ipairs(tbInfo.tbActionFunc) do
            if szLink then
                local endPos = string.find(v,szLink)
                if endPos then
                    return PublicBtn
                end
            else
                if string.match(v, "Update_Target_List") then
                    return PublicBtn
                end
            end
        end
    end
end

function UIShoppingDyeingGift:UpdateRewardBtns(tCustom)
    if not self.tbReceiveBtn then
        return
    end

    if not tCustom then
        return
    end

    for nIndex, btn in ipairs(self.tbReceiveBtn) do
        local labelBtn = self.tbReceiveBtnLabel[nIndex]
        local nLimit = tCustom.tBtnState and tCustom.tBtnState[nIndex]
        local nReward = tCustom.tRewardState and tCustom.tRewardState[nIndex]

        if nLimit then
            UIHelper.SetButtonState(btn, (nLimit == 1 and nReward == 2) and BTN_STATE.Normal or BTN_STATE.Disable)
            UIHelper.SetTouchEnabled(btn, nLimit == 1 and nReward == 2)
            if labelBtn then
                if nLimit == 1 and nReward == 2 then
                    UIHelper.SetString(labelBtn, "立即领取")
                elseif nReward == 1 then
                    UIHelper.SetString(labelBtn, "已领取")
                end
            end
        end
        UIHelper.BindUIEvent(btn, EventType.OnClick, function()
            RemoteCallToServer("On_Recharge_GetWelfareRwd", self.dwOperatActID, nIndex)
        end)
    end
end

return UIShoppingDyeingGift