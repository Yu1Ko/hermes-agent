-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSkillConfigurationCell
-- Date: 2022-11-23 10:01:29
-- Desc: ?
-- ---------------------------------------------------------------------------------
---@class UIWidgetHurtStatisticsCell
local UIWidgetHurtStatisticsCell = class("UIWidgetHurtStatisticsCell")

function UIWidgetHurtStatisticsCell:OnEnter(nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.nIndex = nIndex
    end
    self:UpdateInfo()
end

function UIWidgetHurtStatisticsCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetHurtStatisticsCell:OnPoolRecycled()
    UIHelper.ClearTexture(self.ImgNumBg)
    UIHelper.SetString(self.LabelTagNum, "")
end

function UIWidgetHurtStatisticsCell:BindUIEvent()

end

function UIWidgetHurtStatisticsCell:RegEvent()

end

function UIWidgetHurtStatisticsCell:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

local nRankToRankIcon = {
    [1] = "UIAtlas2_Public_PublicIcon_PublicIcon1_MapIconBg7.png",
    [2] = "UIAtlas2_Public_PublicIcon_PublicIcon1_MapIconBg5.png",
    [3] = "UIAtlas2_Public_PublicIcon_PublicIcon1_MapIconBg3.png",
}

function UIWidgetHurtStatisticsCell:UpdateInfo(nIndex)
    self.nIndex = nIndex or self.nIndex
    if self.nIndex then
        UIHelper.SetString(self.LabelTagNum, self.nIndex)

        local szIconName = nRankToRankIcon[self.nIndex] or "UIAtlas2_Public_PublicIcon_PublicIcon1_MapIconBg1.png"
        UIHelper.SetSpriteFrame(self.ImgNumBg, szIconName)
    end
end

return UIWidgetHurtStatisticsCell