-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: WidgetPvPCampRewardListRank
-- Date: 2023-03-02 19:49:15
-- Desc: WidgetPvPCampRewardListRank
-- ---------------------------------------------------------------------------------

local UIWidgetPvPCampRewardListRank = class("UIWidgetPvPCampRewardListRank")

function UIWidgetPvPCampRewardListRank:OnEnter(tInfo)
    self.szText = tInfo and tInfo.szText
    self.tReward = tInfo and tInfo.tReward or {}


    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIWidgetPvPCampRewardListRank:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetPvPCampRewardListRank:BindUIEvent()
    
end

function UIWidgetPvPCampRewardListRank:RegEvent()

end

function UIWidgetPvPCampRewardListRank:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetPvPCampRewardListRank:UpdateInfo()
    if self.szText then
        UIHelper.SetString(self.LabelNum, self.szText)
    end

    UIHelper.RemoveAllChildren(self.LayoutIcon)
    for i, tItem in ipairs(self.tReward) do
        local dwTabType = tItem[1]
        local dwIndex = tItem[2]
        local nCount = tItem[3]

        local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, self.LayoutIcon)
        itemScript:OnInitWithTabID(dwTabType, dwIndex)
        itemScript:SetEnable(true)
        itemScript:SetLabelCount(nCount)
        itemScript:SetSelectChangeCallback(function(_, bSelected)
            if bSelected then
                Event.Dispatch(EventType.OnUpdateCampRewardTips, dwTabType, dwIndex)
            else
                Event.Dispatch(EventType.OnUpdateCampRewardTips)
            end
        end)
    end
end


return UIWidgetPvPCampRewardListRank