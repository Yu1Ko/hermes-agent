-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetMahjongRightModView
-- Date: 2023-08-02 11:51:26
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetMahjongRightModView = class("UIWidgetMahjongRightModView")

function UIWidgetMahjongRightModView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIWidgetMahjongRightModView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMahjongRightModView:BindUIEvent()
    
end

function UIWidgetMahjongRightModView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetMahjongRightModView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMahjongRightModView:UpdateInfo()
    local nSkinID = MahjongData.GetSkinInfoID("Panel")
    local szSkinID = nSkinID == 2 and "_" .. string.format("%02d", nSkinID) .. "_" or ""
    local szImg = "UIAtlas2_Mahjong_MahjongIcon" .. szSkinID .. "Side"
    UIHelper.SetSpriteFrame(self.ImgMahjongSide, szImg)
end




return UIWidgetMahjongRightModView