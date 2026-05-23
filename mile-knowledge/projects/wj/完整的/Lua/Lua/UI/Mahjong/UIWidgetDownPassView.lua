-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetDownPassView
-- Date: 2023-08-03 10:01:20
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetDownPassView = class("UIWidgetDownPassView")

function UIWidgetDownPassView:OnEnter(tbCardInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(tbCardInfo)
end

function UIWidgetDownPassView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetDownPassView:BindUIEvent()
    
end

function UIWidgetDownPassView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetDownPassView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIWidgetDownPassView:Hide()
    UIHelper.SetVisible(self._rootNode, false)
    self:SetArrowVisible(false)
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetDownPassView:UpdateInfo(tbCardInfo)
    local tbImage = MahjongData.GetMahjongTileInfo("Down1", tbCardInfo.nType, tbCardInfo.nNumber)
    local szImagePath = MahjongData.GetCardImg(tbImage.szIconPath, tbImage.nIconFrame)
    if szImagePath ~= "" then
        UIHelper.SetSpriteFrame(self.ImgMiddleMahjong, szImagePath)
    end
    UIHelper.SetVisible(self._rootNode, true)
end

function UIWidgetDownPassView:SetArrowVisible(bShow)
    UIHelper.SetVisible(self.ImgArrow, bShow)
end



return UIWidgetDownPassView