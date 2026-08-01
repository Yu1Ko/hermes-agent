-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeAchievementPopFurnitureCell
-- Date: 2023-07-19 20:01:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeAchievementPopFurnitureCell = class("UIHomeAchievementPopFurnitureCell")

function UIHomeAchievementPopFurnitureCell:OnEnter(nRewardFurnitureType, nRewardFurnitureIndex, nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nIndex = nIndex
    self.nRewardFurnitureType = nRewardFurnitureType
    self.nRewardFurnitureIndex = nRewardFurnitureIndex
    self:UpdateInfo()
end

function UIHomeAchievementPopFurnitureCell:OnExit()
    self.bInit = false
end

function UIHomeAchievementPopFurnitureCell:BindUIEvent()
    
end

function UIHomeAchievementPopFurnitureCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomeAchievementPopFurnitureCell:UpdateInfo()
    local szImgHomeFrame = HomeLandAchievementCellCenterImg[self.nIndex]
    UIHelper.SetSpriteFrame(self.ImgFurniture, szImgHomeFrame)
end


return UIHomeAchievementPopFurnitureCell