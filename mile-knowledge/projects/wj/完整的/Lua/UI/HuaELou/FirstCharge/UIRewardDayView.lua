-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRewardDayView
-- Date: 2022-12-30 15:45:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIRewardDayView = class("UIRewardDayView")

function UIRewardDayView:OnEnter(tbRewardInfo, tbRewardInfoInTable, nLevel)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if tbRewardInfo then
        self.tbRewardInfo = tbRewardInfo
        self.tbRewardInfoInTable = tbRewardInfoInTable
        self.nLevel = nLevel
        self:UpdateInfo()
    end
end

function UIRewardDayView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRewardDayView:BindUIEvent()

end

function UIRewardDayView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRewardDayView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRewardDayView:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewRewardItem)
    local nRewardState = HuaELouData.GetLevelRewardStateOfPlayerByLevel(self.tbRewardInfo, self.nLevel)
    UIHelper.SetVisible(self.ImgGotten, nRewardState == OPERACT_REWARD_STATE.ALREADY_GOT)
    UIHelper.SetVisible(self.ImgReadyToGet, nRewardState == OPERACT_REWARD_STATE.CAN_GET)
    local tbItemInfo = string.split(self.tbRewardInfoInTable.szItems, ";")
    for i=1, #tbItemInfo do
        tbItemInfo[i] = string.trim(tbItemInfo[i], " ")
        if tbItemInfo[i] ~= "" then
			local tBoxInfo 	= string.split(tbItemInfo[i], "_")
			local dwTabType, dwIndex, nStackNum = tBoxInfo[2], tBoxInfo[3], tBoxInfo[4]
            local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetHuaELouReward, self.ScrollViewRewardItem, dwTabType, dwIndex, nStackNum, nRewardState == OPERACT_REWARD_STATE.CAN_GET)
            if scriptView then
                UIHelper.SetVisible(scriptView.ImgNotReady, false)
            end
        end
	end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRewardItem)
end


return UIRewardDayView