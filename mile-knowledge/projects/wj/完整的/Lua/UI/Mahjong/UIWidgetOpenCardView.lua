-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetOpenCardView
-- Date: 2023-08-08 16:48:49
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetOpenCardView = class("UIWidgetOpenCardView")

function UIWidgetOpenCardView:OnEnter(tbCardInfo, nUIDirection)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(tbCardInfo, nUIDirection)
end

function UIWidgetOpenCardView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetOpenCardView:BindUIEvent()
    
end

function UIWidgetOpenCardView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetOpenCardView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetOpenCardView:UpdateInfo(tbCardInfo, nUIDirection)

    local bHu = tbCardInfo.bHu or false
    UIHelper.SetVisible(self.ImgMahjongHu, bHu)
    if bHu then 
        UIHelper.SetSpriteFrame(self.ImgMahjongHu, MahjongData.GetBackCardImg(nUIDirection))
        return 
    end

    local szDirection = MahjongData.ConvertUIDirectionToStringDataDirection(nUIDirection)
    local tbImage = MahjongData.GetMahjongTileInfo(szDirection, tbCardInfo.nType, tbCardInfo.nNumber)
    local szImagePath = MahjongData.GetCardImg(tbImage.szIconPath, tbImage.nIconFrame)

    if self.ImgLeftOpen then
        UIHelper.SetSpriteFrame(self.ImgLeftOpen, szImagePath)
        UIHelper.SetVisible(self.ImgLeftOpen, not bHu)
    end

    if self.ImgRightOpen then
        UIHelper.SetSpriteFrame(self.ImgRightOpen, szImagePath)
        UIHelper.SetVisible(self.ImgRightOpen, not bHu)
    end

    if self.ImgMahjongOpen then
        UIHelper.SetSpriteFrame(self.ImgMahjongOpen, szImagePath)
        UIHelper.SetVisible(self.ImgMahjongOpen, not bHu)
    end

    if self.WidgetLeftOpen then
        UIHelper.SetVisible(self.WidgetLeftOpen, (not bHu) and nUIDirection == tUIPosIndex.Left)
    end

    if self.WidgetRightOpen then
        UIHelper.SetVisible(self.WidgetRightOpen, (not bHu) and nUIDirection == tUIPosIndex.Right)
    end
end


return UIWidgetOpenCardView