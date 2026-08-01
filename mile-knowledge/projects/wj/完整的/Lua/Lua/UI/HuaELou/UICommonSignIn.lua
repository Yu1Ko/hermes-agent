-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICommonSignIn
-- Date: 2023-06-07 11:41:42
-- Desc: 公用多段签到活动
-- ---------------------------------------------------------------------------------

local UICommonSignIn = class("UICommonSignIn")

function UICommonSignIn:OnEnter(dwOperatActID, nID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.dwID = dwOperatActID

    local tLine = Table_GetOperActyInfo(self.dwID)
    if tLine then
        self:SyncExtPoint(tLine)
        self:RemoteCallBatchCheck(tLine)
        self:UpdateReward(tLine.szReward)
        self:UpdateSpecialReward(tLine.szReward)
        self:UpdateInfo(tLine.tStartTime, tLine.tEndTime, nID, tLine.szCustomTime, tLine.szTitle)
    end
end

function UICommonSignIn:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICommonSignIn:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSignIn, EventType.OnClick,function ()
        RemoteCallToServer("On_Recharge_GetWelfareRwd", self.dwID)
    end)
end

function UICommonSignIn:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if UIHelper.GetSelected(self.SelectToggle) then
            UIHelper.SetSelected(self.SelectToggle, false)
        end
    end)

    Event.Reg(self, "CHANGE_NEW_EXT_POINT_NOTIFY", function ()
        self:SyncExtPoint()
        self:UpdataRewardState()
    end)

    Event.Reg(self, "On_Recharge_GetWelfareRwd_CallBack", function (dwID, nRewardID)
        if dwID == self.dwID then
            if nRewardID then
                self:On_Recharge_GetMultiRwd_CallBack(dwID, nRewardID)
            else
                self:On_Recharge_GetWelfareRwd_CallBack(dwID)
            end
        end
    end)

    Event.Reg(self, "On_Recharge_CheckWelfare_CallBack", function (nLimit, nReward, nMoney, bActive, bIsBespoke, dwID, tCustom, szCustom)
        if dwID == self.dwID then
            self:On_Recharge_CheckWelfare_CallBack(nLimit, nReward, nMoney, bActive, bIsBespoke, dwID, tCustom, szCustom)
        end
    end)

    Event.Reg(self, "Update_Target_List", function(szLink)
        local tTargetList
        if szLink and szLink ~= "" then
            tTargetList = HuaELouData.GetTargetList(nil, szLink)
        else
            tTargetList = HuaELouData.GetTargetList(self.dwID, szLink)
        end
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
end

function UICommonSignIn:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UICommonSignIn:SyncExtPoint(tLine)
    if tLine and tLine.bUseExtPoint then
        local tInfo = GDAPI_CheckWelfare(self.dwID)
        if tInfo and tInfo.dwID ~= 0 then
            self.tReward = {{tInfo.nLimit, tInfo.nReward}}
            self.nMoney = tInfo.nMoney
            self.tCustom = tInfo.tCustom
        end
    end
end

function UICommonSignIn:RemoteCallBatchCheck(tLine)
    local tToCheckOperatID = {}
    if tLine and tLine.bNeedRemoteCall then
        table.insert(tToCheckOperatID, self.dwID)
    end

    if not table.is_empty(tToCheckOperatID) then
        RemoteCallToServer("On_Recharge_CheckWelfare", tToCheckOperatID)
    end
end

function UICommonSignIn:On_Recharge_CheckWelfare_CallBack(nLimit, nReward, nMoney, bActive, bIsBespoke, dwID, tCustom, szCustom)
    self.tReward = {
		[1] = {nLimit, nReward},
	}
    self.tCustom = tCustom

    if self.tCustom and self.tCustom.szImagePath and self.tCustom.szImagePath ~= "" then
        if self.SignInGift_4 then
            --加载图
            local szImgName = string.match(self.tCustom.szImagePath, "\\([^\\]+)tga")
            if not szImgName then
                szImgName = string.match(self.tCustom.szImagePath, "/([^/]+)tga")
            end
            local szImgPath = "Texture/HuaELouReward/Act_119/"..szImgName.."png"
            UIHelper.SetTexture(self.SignInGift_4, szImgPath)
        end
    end

    self:UpdataRewardState()
end

function UICommonSignIn:On_Recharge_GetWelfareRwd_CallBack(nActivityID)
    if self.dwID == nActivityID then
        for k, v in pairs(self.tReward) do
            self.tReward[k] = {1, 1}
        end

        self:UpdataRewardState()
    end
end

function UICommonSignIn:On_Recharge_GetMultiRwd_CallBack(nActivityID, nRewardID)
    if self.dwID == nActivityID then
        for k, v in pairs(self.tReward) do
            self.tReward[k] = {1, 1}
        end

        self:UpdataRewardState()
    end
end

function UICommonSignIn:UpdateReward(szReward)
    local tList = Table_GetOnePhotoRewards(szReward)
    self.nCount = #tList
    UIHelper.RemoveAllChildren(self.ScrollViewReward)
    self.tSignInCellScript = {}
    self.tSignInItemCellScript = {}

    for k, v in ipairs(tList) do
        local signInCellScript = UIHelper.AddPrefab(PREFAB_ID.WidgetCommonSignInCell, self.ScrollViewReward)
        if signInCellScript then
            UIHelper.SetString(signInCellScript.LabelDay, "第"..k.."天")

            local ItemCellScript = {}

            for _, tItem in ipairs(v.tItem) do
				local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetHuaELouReward, signInCellScript.LayoutItem, tItem.dwType, tItem.dwIndex, tItem.nCount)
                if itemScript then
                    itemScript:SetClickCallback(function (nTabType, nTabID)
                        self.SelectToggle = itemScript.ToggleSelect
                        if nTabType and nTabID then
                            local _, scriptItemTip = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip,self.SelectToggle)
                            scriptItemTip:OnInitWithTabID(nTabType, nTabID)
                        end
                    end)

                    UIHelper.SetNodeSwallowTouches(itemScript.ToggleSelect, false, true)
                end
                table.insert(ItemCellScript,itemScript)
			end
            table.insert(self.tSignInCellScript, signInCellScript)
            table.insert(self.tSignInItemCellScript, ItemCellScript)

            UIHelper.LayoutDoLayout(signInCellScript.LayoutItem)
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewReward)
end

function UICommonSignIn:UpdateSpecialReward(szReward)
    local tList = Table_GetOnePhotoRewards(szReward)
    local tSpecialList = self:GetSpecialRewardList(tList)
    local RewardLayout = self.LayoutItem

    local WidgetAct = UIHelper.GetChildByName(self.WidgetAniMiddle, "WidgetAct_"..tostring(self.dwID))
    if WidgetAct then
        RewardLayout = UIHelper.GetChildByName(WidgetAct, "LayoutItem")
    else
        WidgetAct = self.WidgetMainReward
    end

    if #tSpecialList ~= 0 and RewardLayout then
        for _, v in ipairs(tSpecialList) do
            local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, RewardLayout)
            if itemScript then
                itemScript:OnInitWithTabID(v.tItem.dwType, v.tItem.dwIndex, v.tItem.nCount)
                itemScript:SetClickCallback(function (nTabType, nTabID)
                    self.SelectToggle = itemScript.ToggleSelect
                    if nTabType and nTabID then
                        local _, scriptItemTip = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip,self.SelectToggle)
                        scriptItemTip:OnInitWithTabID(nTabType, nTabID)
                    end
                end)

            end
        end

        UIHelper.LayoutDoLayout(RewardLayout)
    end

    UIHelper.SetVisible(WidgetAct, #tSpecialList ~= 0)
end

function UICommonSignIn:GetSpecialRewardList(tList)
    local tSpecialList = {}
	for _, v in ipairs(tList) do
		if v.tSpecial then
			table.insert(tSpecialList, {szTitle = v.szTitle, tItem = v.tSpecial})
		end
	end
	return tSpecialList
end

function UICommonSignIn:UpdateInfo(tStartTime, tEndTime, nID, szCustomTime, szTitle)
    local tActivity = UIHuaELouActivityTab[nID]
    if not tActivity then
        return
    end

    if self.LabelNormalName1 then
        UIHelper.SetString(self.LabelNormalName1, UIHelper.GBKToUTF8(szTitle))
    end

    if self.LabelMiddle then
        local szText = ""
        if szCustomTime and szCustomTime ~= "" then
            szText = UIHelper.GBKToUTF8(szCustomTime)
        else
            local nStart = tStartTime[1]
            local nEnd = tEndTime and tEndTime[1]
            szText = HuaELouData.GetTimeShowText(nStart, nEnd) or ""
        end

        UIHelper.SetString(self.LabelMiddle, szText)
    end

    if self.SignInGift_4 then
        UIHelper.SetTexture(self.SignInGift_4, tActivity.szbgImgPath)
    end

    self:UpdateBtnInfo(tActivity)
end

function UICommonSignIn:UpdateBtnInfo(tActivity)
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
end

function UICommonSignIn:GetBtnInfo(k, tActivity)
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

function UICommonSignIn:UpdataRewardState()
    local nState = HuaELouData.GetLevelRewardStateOfPlayerByLevel(self.tReward, 1)

    if self.tReward then
        UIHelper.SetButtonState(self.BtnSignIn, nState == OPERACT_REWARD_STATE.CAN_GET and BTN_STATE.Normal or BTN_STATE.Disable)

        for k,signInCellScript in ipairs(self.tSignInCellScript) do
            UIHelper.SetVisible(signInCellScript.LabelReceived, k <= self.tCustom.nSign)
            UIHelper.SetVisible(signInCellScript.LabelReady, nState == OPERACT_REWARD_STATE.CAN_GET and k == self.tCustom.nSign + 1)
            UIHelper.SetVisible(signInCellScript.ImgBgLight, nState == OPERACT_REWARD_STATE.CAN_GET and k == self.tCustom.nSign + 1)
            UIHelper.SetVisible(signInCellScript.LabelNotReady, k > self.tCustom.nSign + 1 or (nState == OPERACT_REWARD_STATE.ALREADY_GOT and k == self.tCustom.nSign + 1) )
            for _,v in ipairs(self.tSignInItemCellScript[k]) do
                v:SetCanGetState(nState == OPERACT_REWARD_STATE.CAN_GET and k == self.tCustom.nSign + 1, k <= self.tCustom.nSign)
            end
            if not self.nIndex and nState == OPERACT_REWARD_STATE.CAN_GET and k == self.tCustom.nSign + 1 then
                self.nIndex = k - 1
            end
        end

        local tLine = Table_GetOperActyInfo(self.dwID) assert(tLine)
        local tList = Table_GetOnePhotoRewards(tLine.szReward)
        UIHelper.SetString(self.LabelRight, "已签到次数："..self.tCustom.nSign.."/"..#tList)
    end

    if self.tCustom and self.tCustom.nSign then
        self.nIndex = self.nIndex or self.tCustom.nSign - 1
    end

    UIHelper.ScrollToIndex(self.ScrollViewReward, self.nIndex or 0)
end

function UICommonSignIn:GetTargetListBtn(szLink)
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

return UICommonSignIn