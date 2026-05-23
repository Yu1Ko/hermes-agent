-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetMahjongBgView
-- Date: 2025-06-11 15:37:39
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetMahjongBgView = class("UIWidgetMahjongBgView")

function UIWidgetMahjongBgView:OnEnter(nSkinID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(nSkinID)
end

function UIWidgetMahjongBgView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMahjongBgView:BindUIEvent()
    
end

function UIWidgetMahjongBgView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetMahjongBgView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMahjongBgView:UpdateInfo(nSkinID)

    local szSkinID = nSkinID ~= 2 and "_" or "_" .. string.format("%02d",nSkinID) .. "_"
    local szImgBG = "UIAtlas2_Mahjong_MahjongBigBg".. szSkinID .."_CommonBigBg"
    local szImgMountainLeft = "UIAtlas2_Mahjong_MahjongBigBg".. szSkinID .."CommoneLeft"
    local szImgMountainRight = "UIAtlas2_Mahjong_MahjongBigBg".. szSkinID .."CommonRight"
    local szImgMountainMid = "UIAtlas2_Mahjong_MahjongBigBg".. szSkinID .."CommonMiddle"

    local szSkinID2 = nSkinID ~= 2 and "" or "_" .. string.format("%02d", nSkinID)
    local szImgFlower = "UIAtlas2_Mahjong_MahjongBg_imgmiddleflower".. szSkinID2
    local szImgRight = "UIAtlas2_Mahjong_MahjongMix_imgslipsbg".. szSkinID2
    local szImgLeft = "UIAtlas2_Mahjong_MahjongMix_imgslipsbg".. szSkinID2
    local szImgDown = "UIAtlas2_Mahjong_MahjongMix_imgslipsbg".. szSkinID2
    local szImgUp = "UIAtlas2_Mahjong_MahjongMix_imgslipsbg".. szSkinID2


    UIHelper.SetSpriteFrame(self.ImgBigBg, szImgBG)
    UIHelper.SetSpriteFrame(self.ImgMountainLeft, szImgMountainLeft)
    UIHelper.SetSpriteFrame(self.ImgMountainRight, szImgMountainRight)
    UIHelper.SetSpriteFrame(self.ImgMountainMiddle, szImgMountainMid)


    UIHelper.SetSpriteFrame(self.Imgflower, szImgFlower)
    UIHelper.SetSpriteFrame(self.Imgright, szImgRight)
    UIHelper.SetSpriteFrame(self.Imgleft, szImgLeft)
    UIHelper.SetSpriteFrame(self.Imgdown, szImgDown)
    UIHelper.SetSpriteFrame(self.imgup, szImgUp)

end


return UIWidgetMahjongBgView