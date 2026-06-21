-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopLotteryMyRewardsView
-- Date: 2023-04-11 19:34:07
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopLotteryMyRewardsView = class("UICoinShopLotteryMyRewardsView")

function UICoinShopLotteryMyRewardsView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UICoinShopLotteryMyRewardsView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopLotteryMyRewardsView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
end

function UICoinShopLotteryMyRewardsView:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        self:ClearSelect()
    end)

    Event.Reg(self, EventType.OnGuideItemSource, function()
        UIMgr.Close(self)
    end)
end

function UICoinShopLotteryMyRewardsView:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopLotteryMyRewardsView:UpdateInfo()
    UIHelper.RemoveAllChildren(self.LayoutExamineReward)
    self.tRewardsScriptList = {}
    local tStorageRewardsList = On_DrawCardGetRecord(g_pClientPlayer)
    for _, tRewardsItem in ipairs(tStorageRewardsList) do
        if not tRewardsItem then
            break
        end
        local nItemType = tRewardsItem[1]
        local dwItemIndex = tRewardsItem[2]
        local nItemNum = tRewardsItem[3]
		if nItemType ~= 0 then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetExamineRewardCell, self.LayoutExamineReward, tRewardsItem)
            table.insert(self.tRewardsScriptList, script)
        end
    end
    UIHelper.SetVisible(self.WidgetEmpty, #self.tRewardsScriptList == 0)
    UIHelper.LayoutDoLayout(self.LayoutExamineReward)
end

function UICoinShopLotteryMyRewardsView:ClearSelect()
    if self.tRewardsScriptList then
        for _, script in ipairs(self.tRewardsScriptList) do
            if script.itemIconScript then
                script.itemIconScript:RawSetSelected(false)
            end
        end
    end
end

return UICoinShopLotteryMyRewardsView