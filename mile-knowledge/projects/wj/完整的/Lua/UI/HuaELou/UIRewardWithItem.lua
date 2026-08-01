-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRewardWithItem
-- Date: 2024-04-12 16:43:52
-- Desc: 通用简单领奖活动
-- ---------------------------------------------------------------------------------

local UIRewardWithItem = class("UIRewardWithItem")

function UIRewardWithItem:OnEnter(dwOperatActID, nID)
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

    self.nID = nID
    self.dwOperatActID = dwOperatActID
    self.nBtnID = tActivity.nBtnID
    self.SelectToggle = nil

    self:UpdateBtnPos(tActivity)
    self:UpdateInfo()
end

function UIRewardWithItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRewardWithItem:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnReceive, EventType.OnClick, function ()
        RemoteCallToServer("On_Recharge_GetWelfareRwd", self.dwOperatActID)
    end)

    if self.WidgetNumPopShell then
        UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
            UIHelper.SetVisible(self.WidgetNumPopShell, false)
        end)
    end
end

function UIRewardWithItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "On_Recharge_CheckWelfare_CallBack", function (nLimit, nReward, nMoney, bActive, bAppoint, dwID, tCustom, szCustom)
        self:UpdataRewardState(nLimit, nReward, nMoney, bActive, bAppoint, dwID, tCustom, szCustom)
        self:UpdataRewardItem()
    end)

    Event.Reg(self, "On_Recharge_GetWelfareRwd_CallBack", function (dwID, nRewardID)
        if dwID == self.dwOperatActID then
            UIHelper.SetButtonState(self.BtnReceive, BTN_STATE.Disable)
            UIHelper.SetTouchEnabled(self.BtnReceive, false)
            if self.LabelReceive then
                UIHelper.SetString(self.LabelReceive, "已领取")
            end
        end
    end)

    Event.Reg(self, EventType.OnUserInputNumber, function (szInput, nDefault, nMin, nMax, szSource)
        if self.WidgetNumPopShell then
            UIHelper.SetVisible(self.WidgetNumPopShell, true)
            self:UpdataInputNumber(szInput, nDefault, nMin, nMax, szSource)
        end
    end)

    Event.Reg(self, "CHANGE_NEW_EXT_POINT_NOTIFY", function ()
        if self.WidgetNumPopShell then
            UIHelper.SetVisible(self.WidgetNumPopShell, false)
        end
        self:SyncExtPoint()
        self:RemoteCallBatchCheck()
    end)

    Event.Reg(self, "Update_Target_List", function()
        local tTargetList = HuaELouData.GetTargetList(self.dwOperatActID)
        if tTargetList and (not table_is_empty(tTargetList)) then
            local tbBtnPos = self:GetTargetListBtn()
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

    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.SelectToggle and UIHelper.GetSelected(self.SelectToggle) then
            UIHelper.SetSelected(self.SelectToggle, false)
        end
    end)
end

function UIRewardWithItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIRewardWithItem:UpdateBtnPos(tActivity)
    if self.BtnReceive and (tActivity.tbReceiveBtnPosXY[1] ~= 0 or tActivity.tbReceiveBtnPosXY[2] ~= 0) then
        UIHelper.SetPosition(self.BtnReceive, tActivity.tbReceiveBtnPosXY[1], tActivity.tbReceiveBtnPosXY[2])
    end

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

function UIRewardWithItem:GetBtnInfo(k, tActivity)
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

function UIRewardWithItem:UpdateInfo()
    local tLine = Table_GetOperActyInfo(self.dwOperatActID)
    self:SyncExtPoint()
    self:RemoteCallBatchCheck(tLine)
    self:UpdateTimeInfo(tLine)
    self:UpdataRewardItem()

    if HuaELouData.tReward[self.dwOperatActID] then
        self:UpdataRewardState(HuaELouData.tReward[self.dwOperatActID][1][1], HuaELouData.tReward[self.dwOperatActID][1][2],nil,nil,nil, self.dwOperatActID)
    end
end

function UIRewardWithItem:SyncExtPoint()
    local tLine = Table_GetOperActyInfo(self.dwOperatActID)

    if tLine and tLine.bUseExtPoint then
        local tInfo = GDAPI_CheckWelfare(self.dwID)
        if tInfo and tInfo.dwID ~= 0 then
            self.tReward = {{tInfo.nLimit, tInfo.nReward}}
            self.nMoney = tInfo.nMoney
            self.tCustom = tInfo.tCustom
        end
    end

    if tInfo and tInfo.dwID ~= 0 then
        self:UpdataRewardState(tInfo.nLimit, tInfo.nReward, tInfo.nMoney, tInfo.bActive, tInfo.bIsBespoke, tInfo.dwID, tInfo.tCustom, tInfo.szCustom)
    end
end

function UIRewardWithItem:RemoteCallBatchCheck(tLine)
    local tLine = Table_GetOperActyInfo(self.dwOperatActID)
    local tToCheckOperatID = {}
    if tLine and tLine.bNeedRemoteCall then
        table.insert(tToCheckOperatID, self.dwOperatActID)
    end

    if not table.is_empty(tToCheckOperatID) then
        RemoteCallToServer("On_Recharge_CheckWelfare", tToCheckOperatID)
    end
end

function UIRewardWithItem:UpdateTimeInfo(tLine)
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
    end
end

function UIRewardWithItem:UpdataRewardItem()
    if self.LayoutContent then
        UIHelper.RemoveAllChildren(self.LayoutContent)

        local WidgetAct = UIHelper.GetChildByName(self.WidgetAnchorShop, "WidgetAct_"..tostring(self.dwOperatActID))
        local RewardLayout = self.LayoutContent
        if WidgetAct then
            RewardLayout = UIHelper.GetChildByName(WidgetAct, "LayoutContent")
        end

        local tCustom = HuaELouData.tCustom[self.dwOperatActID]
        local tReward = HuaELouData.GetShowReward(self.nID)
        if tReward and not table_is_empty(tReward) then
            UIHelper.SetVisible(RewardLayout, true)
            for k, tItem in ipairs(tReward) do
                if self.dwOperatActID == 220 then
                    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, RewardLayout)
                    script:OnInitWithTabID(tItem[1], tItem[2], tItem[3])
                    script:SetClickCallback(function ()
                        TipsHelper.ShowItemTips(nil, tItem[1], tItem[2])
                        if script.ToggleSelect  then
                            self.SelectToggle = script.ToggleSelect
                        end
                    end)
                    if tCustom and tCustom.tRewardState and tCustom.tRewardState[k] then
                        script:SetItemReceived(tCustom.tRewardState[k] == 1)
                    end
                else
                    local itemIconScript = UIHelper.AddPrefab(PREFAB_ID.WidgetHuaELouReward, RewardLayout, tItem[1], tItem[2], tItem[3])
                    if itemIconScript then
                        itemIconScript:SetClickCallback(function ()
                            TipsHelper.ShowItemTips(nil, tItem[1], tItem[2])
                        end)
                        UIHelper.SetVisible(itemIconScript.ImgNotReady, false)
                    end
                end
            end
        end

        UIHelper.LayoutDoLayout(RewardLayout)
    end
end

function UIRewardWithItem:UpdataRewardState(nLimit, nReward, nMoney, bActive, bAppoint, dwID, tCustom, szCustom)
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
            if tCustom.tValueList then
                for i, v in pairs(tCustom.tValueList) do
                    if self.tbCustomValue and self.tbCustomValue[i] then
                        UIHelper.SetRichText(self.tbCustomValue[i], v)
                        -- UIHelper.SetString(self.tbCustomValue[i], v)
                    elseif self.tbCustomValueLabel and self.tbCustomValueLabel[i] then
                        UIHelper.SetString(self.tbCustomValueLabel[i], v)
                    end
                end
            end

            if tCustom.tProgressBar then
                for i, v in pairs(tCustom.tProgressBar) do
                    if self.tProgressBar and self.tProgressBar[i] then
                        local fPercent = v.nTotalValue ~= 0 and v.nCurValue / v.nTotalValue or 0
                        UIHelper.SetProgressBarPercent(self.tProgressBar[i], fPercent * 100)

                        if self.tProgressBarLabel and self.tProgressBarLabel[i] then
                            UIHelper.SetString(self.tProgressBarLabel[i], v.szBarValue)
                        end

                        if self.tProgressBarTail and self.tProgressBarTail[i] then
                            local x, y = UIHelper.GetPosition(self.tProgressBar[i])
                            local w = UIHelper.GetWidth(self.tProgressBarTail[i])
                            local nBarW = UIHelper.GetWidth(self.tProgressBar[i])
                            local nSelfX, nSelfY = UIHelper.GetPosition(self.tProgressBarTail[i])
                            UIHelper.SetPosition(self.tProgressBarTail[i], x + nBarW * fPercent - w / 2, nSelfY)
                        end
                    end
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

function UIRewardWithItem:UpdataInputNumber(szInput, nDefault, nMin, nMax, szSource)
    local function fnActionSure(nCount)
        if nCount > 0 then
            RemoteCallToServer(szInput, nCount)
        end
    end
    if not nMin then
        nMin = 0
    end

    if nMax < 0 then
        nMin = 0
    end

    self.InputNumberScript = self.InputNumberScript or UIHelper.AddPrefab(PREFAB_ID.WidgetSmallNumInsertPop, self.WidgetNumPopShell)
    if self.InputNumberScript then
        self.InputNumberScript:UpdataInputNumber(szInput, nDefault, nMin, nMax, szSource, fnActionSure)
    end
end

function UIRewardWithItem:GetTargetListBtn()
    if not self.tbPublicBtn then
        return
    end

    for _, PublicBtn in ipairs(self.tbPublicBtn) do
        local scriptBtn = UIHelper.GetBindScript(PublicBtn) assert(scriptBtn)
        local tbInfo = UIBtnCtrlTab[scriptBtn.nID]
        for _, v in ipairs(tbInfo.tbActionFunc) do
            if string.match(v, "Update_Target_List") then
                return PublicBtn
            end
        end
    end
end

return UIRewardWithItem