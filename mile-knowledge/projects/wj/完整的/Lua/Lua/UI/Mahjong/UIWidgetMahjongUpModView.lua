-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetMahjongUpModView
-- Date: 2023-08-02 11:52:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetMahjongUpModView = class("UIWidgetMahjongUpModView")

function UIWidgetMahjongUpModView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIWidgetMahjongUpModView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMahjongUpModView:BindUIEvent()
    
end

function UIWidgetMahjongUpModView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetMahjongUpModView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMahjongUpModView:UpdateInfo()
    local nSkinID = MahjongData.GetSkinInfoID("Panel")
    local szSkinID = nSkinID == 2 and "_" .. string.format("%02d", nSkinID) .. "_" or "_"
    local szImg = "UIAtlas2_Mahjong_MahjongIcon" .. szSkinID .. "Vertical"
    if nSkinID == 3 then--特判黑金皮肤，以前导进的图，不重新导一遍
        szImg = szImg .. "BG"
    end
    UIHelper.SetSpriteFrame(self.ImgMahjong, szImg)
end



return UIWidgetMahjongUpModView