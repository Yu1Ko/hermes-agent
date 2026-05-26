-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetRewardChooseOne
-- Date: 2023-04-11 20:57:06
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetRewardChooseOne = class("UIWidgetRewardChooseOne")

function UIWidgetRewardChooseOne:OnEnter(tbItem, ToggleGroup, bSelect, scriptReward)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbItem = tbItem
    self.ToggleGroup = ToggleGroup
    self.bSelect = bSelect
    self.scriptReward = scriptReward
    self:UpdateInfo()
end

function UIWidgetRewardChooseOne:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetRewardChooseOne:BindUIEvent()
    UIHelper.BindUIEvent(self._rootNode, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self.scriptReward:SetItemInfo(self.tbItem)
        end
    end)
end

function UIWidgetRewardChooseOne:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetRewardChooseOne:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetRewardChooseOne:UpdateInfo()
    local KItemInfo = GetItemInfo(self.tbItem.nType, self.tbItem.nID)
    local szName = ItemData.GetItemNameByItemInfo(KItemInfo)
    UIHelper.SetString(self.NodeName, UIHelper.GBKToUTF8(szName))

    local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.RewardGoods)
    scriptView:OnInitWithTabID(self.tbItem.nType, self.tbItem.nID)
    scriptView:SetToggleGroupIndex(1)
    scriptView:SetClickCallback(function(nItemType, nTabID)
        if nItemType and nTabID then
            self:OpenTips(nItemType, nTabID, scriptView)
        else
            self:CloseTips()
        end
    end)

    local tbItemInfo = ItemData.GetItemInfo(self.tbItem.nType, self.tbItem.nID)
    local nQuality = tbItemInfo.nQuality
    local szImagePath = nQuality == 5 and "UIAtlas2_LangKeXing_LKXSkillBg_LKXEquipNormalYellow.png" or "UIAtlas2_LangKeXing_LKXSkillBg_LKXEquipNormal.png"
    UIHelper.SetSpriteFrame(self.ImgBg, szImagePath)


    UIHelper.ToggleGroupAddToggle(self.ToggleGroup, self._rootNode)

    if self.bSelect then
        self.scriptReward:SetItemInfo(self.tbItem)
    end
end

function UIWidgetRewardChooseOne:OpenTips(...)
    self.scriptReward:OpenTips(PREFAB_ID.WidgetItemTip, self._rootNode, ...)
end

function UIWidgetRewardChooseOne:CloseTips()
    self.scriptReward:CloseTips()
end

return UIWidgetRewardChooseOne