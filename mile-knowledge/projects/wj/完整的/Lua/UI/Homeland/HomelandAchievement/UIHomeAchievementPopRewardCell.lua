-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeAchievementPopRewardCell
-- Date: 2023-07-19 20:15:18
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeAchievementPopRewardCell = class("UIHomeAchievementPopRewardCell")

function UIHomeAchievementPopRewardCell:OnEnter(tAttributeInfo)
    self.tAttributeInfo = tAttributeInfo
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIHomeAchievementPopRewardCell:OnExit()
    self.bInit = false
end

function UIHomeAchievementPopRewardCell:BindUIEvent()
    
end

function UIHomeAchievementPopRewardCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomeAchievementPopRewardCell:UpdateInfo()
    local szAttributeName = UIHelper.GBKToUTF8(self.tAttributeInfo.szAttributeName)
    local szAttributeDesc = UIHelper.GBKToUTF8(self.tAttributeInfo.szAttributeDesc)
    local szInfo = "<color=#ffcf58>"..szAttributeName.."</c><color=#aed9e0>"..szAttributeDesc.."</c>"
    UIHelper.SetRichText(self.RichTextEffectReward, szInfo)
    UIHelper.LayoutDoLayout(self.WidgetRightPopRewardCell)
    UIHelper.WidgetFoceDoAlign(self)
end


return UIHomeAchievementPopRewardCell