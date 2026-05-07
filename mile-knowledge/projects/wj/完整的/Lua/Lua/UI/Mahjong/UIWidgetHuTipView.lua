-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetHuTipView
-- Date: 2023-08-04 17:06:17
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetHuTipView = class("UIWidgetHuTipView")

function UIWidgetHuTipView:OnEnter(tbCardInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbCardInfo = tbCardInfo
    self:UpdateInfo()
end

function UIWidgetHuTipView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetHuTipView:BindUIEvent()
    
end

function UIWidgetHuTipView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetHuTipView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetHuTipView:UpdateInfo()
    local tbImage = MahjongData.GetMahjongTileInfo("Down1", self.tbCardInfo.nType, self.tbCardInfo.nNumber)
    local szImagePath = MahjongData.GetCardImg(tbImage.szIconPath, tbImage.nIconFrame)
    if szImagePath ~= "" then
        UIHelper.SetSpriteFrame(self.ImgMahjong, szImagePath)
    end

    UIHelper.SetString(self.TextCount, tostring(self.tbCardInfo.nCount)..g_tStrings.STR_MAHJONG_COUNT)
    UIHelper.SetString(self.TextMultiple, tostring(self.tbCardInfo.nMultiple)..g_tStrings.STR_MAHJONG_MULTIPLY)
end


return UIWidgetHuTipView