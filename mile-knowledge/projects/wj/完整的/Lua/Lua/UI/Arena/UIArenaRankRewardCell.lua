-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaRankRewardCell
-- Date: 2023-01-04 10:32:05
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaRankRewardCell = class("UIArenaRankRewardCell")

function UIArenaRankRewardCell:OnEnter(nArenaType, nIndex, bCanGet, bHadGet)
    self.nArenaType = nArenaType
    self.nIndex = nIndex
    self.bCanGet = bCanGet
    self.bHadGet = bHadGet

    self.tbConfig = TabHelper.GetUIArenaRankLevelTab(nIndex)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIArenaRankRewardCell:OnExit()
    self.bInit = false
end

function UIArenaRankRewardCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnGet, EventType.OnClick, function ()
        ArenaData.GetLevelAward(self.nArenaType)
    end)
end

function UIArenaRankRewardCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIArenaRankRewardCell:UpdateInfo()
    local tbRewards = self:GetRewardInfo()

    UIHelper.SetVisible(self.BtnGet, #tbRewards > 0 and self.bCanGet and not self.bHadGet)
    UIHelper.SetVisible(self.WidgetNotReach, self.bHadGet and #tbRewards > 0)
    UIHelper.SetVisible(self.WidgetReward01, #tbRewards > 0)
    UIHelper.SetVisible(self.WidgetReward, #tbRewards <= 0)

	local szLevel = Conversion2ChineseNumber(self.nIndex)

    UIHelper.SetSpriteFrame(self.ImgDanGradingIcon, self.tbConfig.szBigIcon)

    UIHelper.SetString(self.LabelDanGrading, string.format("%s%s·%s", szLevel, g_tStrings.STR_DUAN, self.tbConfig.szTitle))
    UIHelper.SetString(self.LabelPersonageScore, string.format("个人竞技分达到%d", self.tbConfig.nScore))

    UIHelper.RemoveAllChildren(self.LayoutItem)
    for i, tbReward in ipairs(tbRewards) do
        local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayoutItem)
        scriptItem:OnInitWithTabID(tbReward.nType, tbReward.nID)
        scriptItem:SetLabelCount(tbReward.nCount)
        scriptItem:SetToggleGroupIndex(ToggleGroupIndex.ArenaRewardItem)
        scriptItem:SetClickCallback(function()
            Event.Dispatch(EventType.OnArenaClickRewardItem, tbReward.nType, tbReward.nID)
        end)

        Event.Reg(scriptItem, EventType.OnTouchViewBackGround, function()
            scriptItem:SetSelected(false)
        end)
    end
    UIHelper.LayoutDoLayout(self.LayoutItem)
end

function UIArenaRankRewardCell:GetRewardInfo()
    local tbRewards = {}

    local i = 1
    while self.tbConfig["nAwardType"..i] and self.tbConfig["nAwardID"..i] and self.tbConfig["nAwardCount"..i] do
        if self.tbConfig["nAwardType"..i] > 0 and
            self.tbConfig["nAwardID"..i] > 0 and
            self.tbConfig["nAwardCount"..i] > 0 then
            table.insert(tbRewards, {
                nType = self.tbConfig["nAwardType"..i],
                nID = self.tbConfig["nAwardID"..i],
                nCount = self.tbConfig["nAwardCount"..i],
            })
        end
        i = i + 1
    end

    return tbRewards
end


return UIArenaRankRewardCell