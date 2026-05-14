-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationFriendRecruitReward
-- Date: 2026-03-25 17:17:20
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationFriendRecruitReward = class("UIOperationFriendRecruitReward")

function UIOperationFriendRecruitReward:OnEnter(tInfo, nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tInfo = tInfo
    self.nIndex = nIndex
    self:UpdateInfo()
end

function UIOperationFriendRecruitReward:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationFriendRecruitReward:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnNormal1, EventType.OnClick, function ()
        local tInfo = self.tInfo
        local szRewardName = UIHelper.GBKToUTF8(tInfo.szName)
        local nImgRewardCost = tInfo.dwIntergral
        local nRewardIndex = tInfo.dwID
        UIHelper.ShowConfirm(FormatString(g_tStrings.BUY_REWARD_SURE, nImgRewardCost, szRewardName),function ()
            RemoteCallToServer("On_Recharge_GetFriInvReward", nRewardIndex)
        end)
    end)

    UIHelper.BindUIEvent(self.BtnFriendRecruitCell, EventType.OnClick, function()
        Event.Dispatch(EventType.OnOperationRecruitSelectReward, self.nIndex)
    end)
end

function UIOperationFriendRecruitReward:RegEvent()
     Event.Reg(self, EventType.HideAllHoverTips, function()
        if UIHelper.GetSelected(self.SelectToggle) then
            UIHelper.SetSelected(self.SelectToggle, false)
        end
    end)

    Event.Reg(self, EventType.OnOperationRecruitSelectReward, function(nIndex)
        self:OnSelectChange(nIndex  == self.nIndex)
    end)

    Event.Reg(self, "On_Recharge_GetFriInvReward_CallBack", function()
        Timer.AddFrame(self, 1, function()
            self:RefreshState()
        end)
    end)

    Event.Reg(self, "On_Recharge_GetFriendsPoints_CallBack", function(nLeftPoint)
        Timer.AddFrame(self, 1, function()
            self:RefreshState()
        end)
    end)
end

function UIOperationFriendRecruitReward:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationFriendRecruitReward:UpdateInfo()
    local tInfo = self.tInfo

    UIHelper.SetString(self.LabelCount, tInfo.dwIntergral or 0)
    UIHelper.RemoveAllChildren(self.WidgetItem)
    self.itemScript = nil
    if tInfo.szFRecallReward and tInfo.szFRecallReward ~= "" then
        local tReward = SplitString(tInfo.szFRecallReward, ";")
        local dwTabType = tonumber(tReward[1])
        local dwIndex = tonumber(tReward[2])
        local nCount = tonumber(tReward[3]) or 1
        if dwTabType and dwIndex then
            self.dwTabType = dwTabType
            self.dwIndex = dwIndex
            local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)
            if itemScript then
                itemScript:OnInitWithTabID(dwTabType, dwIndex, nCount)
                itemScript:SetClickCallback(function(nTabType, nTabID)
                    if nTabType and nTabID then
                        self.SelectToggle =  itemScript.ToggleSelect
                        TipsHelper.ShowItemTips(self.WidgetItem, nTabType, nTabID)
                    end
                end)
                itemScript:SetClickNotSelected(true)
                itemScript:SetToggleSwallowTouches(false)
            end
            self.itemScript = itemScript
        end
    end

    self:RefreshState()
end

function UIOperationFriendRecruitReward:RefreshState()
    local tInfo = self.tInfo
    local nState = OperationFriendRecruitData.GetRewardStateByRewardIndex(tInfo.dwID)
    UIHelper.SetVisible(self.ImgTaskFinish, nState == OPERACT_REWARD_STATE.ALREADY_GOT)
    UIHelper.SetVisible(self.WidgetFinish, nState == OPERACT_REWARD_STATE.ALREADY_GOT)
    UIHelper.SetVisible(self.BtnNormal1, nState == OPERACT_REWARD_STATE.CAN_GET)
    if self.itemScript then
        self.itemScript:SetItemReceived(nState == OPERACT_REWARD_STATE.ALREADY_GOT)
    end
end

function UIOperationFriendRecruitReward:OnSelectChange(bSelected)
    UIHelper.SetVisible(self.ImgBgSelect, bSelected)
    if bSelected then
        local tInfo = self.tInfo
        local tContext = OperationCenterData.GetViewComponentContext()
        local scriptCenter = tContext and tContext.scriptCenter
        if scriptCenter then
            --scriptCenter:ShowModelInfo(self.dwTabType, self.dwIndex)
            scriptCenter:ShowItemBg(tInfo.szMobileRewardTextureFile)
            scriptCenter:SetContentNameTitle(UIHelper.GBKToUTF8(tInfo.szName), tInfo.szMobileRewardTypePath)
        end
    end
end


return UIOperationFriendRecruitReward