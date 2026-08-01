-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIPvPCampRankReward
-- Date: 2023-03-17 11:19:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPvPCampRankReward = class("UIPvPCampRankReward")

local REWARD_MAX_COUNT = 500 -- 奖励的最大人数
local REWARD_MIN_POINT = 5000 -->=5000，才有战阶奖励

function UIPvPCampRankReward:OnEnter(tInfo)
    self.nRank = tInfo and tInfo.Rank or 501
    self.nLastPoint = tInfo and tInfo.TitlePoint or 0
    self.bCanReceive = tInfo and tInfo.Receive or false --是否可领取奖励

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPvPCampRankReward:OnExit()
    self.bInit = false
    self:UnRegEvent()

    self:CloseTips()
end

function UIPvPCampRankReward:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnGetReward, EventType.OnClick, function()
        if self.bCanReceive then
            RemoteCallToServer("On_Camp_GetTitlePointRankReward")
        end
    end)
end

function UIPvPCampRankReward:RegEvent()
    Event.Reg(self, "On_CAMP_GETTITLEPOINTRANKREWARD", function()
        UIMgr.Close(self)
    end)
    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        self:CloseTips()
    end)
    Event.Reg(self, EventType.OnHoverTipsDeleted, function()
        if self.lastItemScript then
            self.lastItemScript:RawSetSelected(false)
        end
    end)
end

function UIPvPCampRankReward:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPvPCampRankReward:UpdateInfo()
    UIHelper.RemoveAllChildren(self.LayoutRankRewardList)

    local tNowReward = CampData.GetNowReward(self.nRank, self.nLastPoint)
    if tNowReward then
        for nIndex, tItem in ipairs(tNowReward.tReward) do
            local dwTabType = tItem[1]
            local dwIndex = tItem[2]
            local nCount = tItem[3]

            local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.LayoutRankRewardList)
            itemScript:OnInitWithTabID(dwTabType, dwIndex)
            itemScript:SetEnable(true)
            itemScript:RawSetSelected(false)
            itemScript:SetLabelCount(nCount)
            itemScript:SetSelectChangeCallback(function(_, bSelected)
                if bSelected then
                    if self.lastItemScript and self.lastItemScript ~= itemScript then
                        self.lastItemScript:RawSetSelected(false)
                    end
                    self.lastItemScript = itemScript

                    local nDir = nIndex > #tNowReward.tReward / 2 and TipsLayoutDir.RIGHT_CENTER or TipsLayoutDir.LEFT_CENTER

                    local tip, tipScript = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, itemScript._rootNode)
                    tip:SetDisplayLayoutDir(nDir)
                    tip:SetOffset(100)
                    tip:Update()
                    tipScript:OnInitWithTabID(dwTabType, dwIndex)
                    tipScript:SetBtnState({})
                else
                    self:CloseTips()
                end
            end)
        end
        UIHelper.SetVisible(self.WidgetContent, true)
        UIHelper.SetVisible(self.WidgetEmpty, false)
    else
        UIHelper.SetVisible(self.WidgetContent, false)
        UIHelper.SetVisible(self.WidgetEmpty, true)
    end
    UIHelper.LayoutDoLayout(self.LayoutRankRewardList)

    if self.bCanReceive then
        UIHelper.SetString(self.LabelGetReward, "领取")
        UIHelper.SetButtonState(self.BtnGetReward, BTN_STATE.Normal)
    else
        if self.nRank <= REWARD_MAX_COUNT or self.nLastPoint >= REWARD_MIN_POINT then
            UIHelper.SetString(self.LabelGetReward, "已领取")
            UIHelper.SetButtonState(self.BtnGetReward, BTN_STATE.Disable)
        elseif self.nRank > REWARD_MAX_COUNT and self.nLastPoint < REWARD_MIN_POINT then
            UIHelper.SetString(self.LabelGetReward, "未达到领取标准")
            UIHelper.SetButtonState(self.BtnGetReward, BTN_STATE.Disable)

            UIHelper.SetVisible(self.WidgetContent, false)
            UIHelper.SetVisible(self.WidgetEmpty, true)
        end
    end
end

function UIPvPCampRankReward:CloseTips()
    TipsHelper.DeleteAllHoverTips()
    if self.lastItemScript then
        self.lastItemScript:RawSetSelected(false)
    end
end


return UIPvPCampRankReward