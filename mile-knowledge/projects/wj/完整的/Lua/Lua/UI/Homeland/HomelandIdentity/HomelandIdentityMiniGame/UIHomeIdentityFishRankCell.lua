-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeIdentityFishRankCell
-- Date: 2024-04-09 19:39:43
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeIdentityFishRankCell = class("UIHomeIdentityFishRankCell")

function UIHomeIdentityFishRankCell:OnEnter(nIndex, tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nIndex = nIndex
    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UIHomeIdentityFishRankCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomeIdentityFishRankCell:BindUIEvent()
    
end

function UIHomeIdentityFishRankCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomeIdentityFishRankCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomeIdentityFishRankCell:UpdateInfo()
    UIHelper.SetString(self.LabelFish, self.tbInfo.szFishName)
    UIHelper.SetString(self.LabelWeight, self.tbInfo.szWeight)
    UIHelper.SetString(self.LabelPlayerName, self.tbInfo.szPlayerName, 7)
end


return UIHomeIdentityFishRankCell