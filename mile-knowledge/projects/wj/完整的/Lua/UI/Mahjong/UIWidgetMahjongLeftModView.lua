-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetMahjongLeftModView
-- Date: 2023-08-02 11:52:08
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetMahjongLeftModView = class("UIWidgetMahjongLeftModView")

function UIWidgetMahjongLeftModView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIWidgetMahjongLeftModView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMahjongLeftModView:BindUIEvent()
    
end

function UIWidgetMahjongLeftModView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetMahjongLeftModView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMahjongLeftModView:UpdateInfo()
    local nSkinID = MahjongData.GetSkinInfoID("Panel")
    local szSkinID = nSkinID == 2 and "_" .. string.format("%02d", nSkinID) .. "_" or ""
    local szImg = "UIAtlas2_Mahjong_MahjongIcon" .. szSkinID .. "Side"
    UIHelper.SetSpriteFrame(self.ImgMahjongSide, szImg)
end



return UIWidgetMahjongLeftModView