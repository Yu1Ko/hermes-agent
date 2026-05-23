-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIEquipScoreRushSlotCell
-- Date: 2024-03-21 20:20:53
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIEquipScoreRushSlotCell = class("UIEquipScoreRushSlotCell")

function UIEquipScoreRushSlotCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIEquipScoreRushSlotCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIEquipScoreRushSlotCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBtnGet, EventType.OnClick, function ()
        RemoteCallToServer("On_Recharge_GetProgressReward", self.nActivityID, self.nLevel)
    end)
end

function UIEquipScoreRushSlotCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIEquipScoreRushSlotCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIEquipScoreRushSlotCell:SetEquipScoreRushSlot(tRewardInfo)
    self.nActivityID = tRewardInfo.dwID
    self.nLevel = tRewardInfo.nLevel

    UIHelper.SetString(self.LabelTitle, UIHelper.GBKToUTF8(tRewardInfo.szName))
    UIHelper.SetSpriteFrame(self.ImgScore, tRewardInfo.szVKIconPath)

    local tItems = SplitString(tRewardInfo.szReward, ";")
    for k, v in ipairs(tItems) do
        local tItem = SplitString(tItems[k], "_")
        local itemIconScript = UIHelper.AddPrefab(PREFAB_ID.WidgetHuaELouReward, self.LayoutReward,tItem[1], tItem[2], tItem[3])
        if itemIconScript then
            itemIconScript:SetClickCallback(function ()
                TipsHelper.ShowItemTips(nil, tItem[1], tItem[2])
            end)
            UIHelper.SetVisible(itemIconScript.ImgNotReady, false)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutReward)
end

function UIEquipScoreRushSlotCell:SetRewardState(nState)
    UIHelper.SetVisible(self.BtnBtnGet, nState == OPERACT_REWARD_STATE.CAN_GET)
    UIHelper.SetVisible(self.ImgLocked, nState == OPERACT_REWARD_STATE.NON_GET)
    UIHelper.SetVisible(self.ImgGotten, nState == OPERACT_REWARD_STATE.ALREADY_GOT)
    UIHelper.SetVisible(self.WidgetNotAchieved, nState == OPERACT_REWARD_STATE.NON_GET)
    UIHelper.SetVisible(self.WidgetAchieved, nState ~= OPERACT_REWARD_STATE.NON_GET)
end


return UIEquipScoreRushSlotCell