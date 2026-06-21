-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetUnknownImgUpView
-- Date: 2023-08-02 14:41:52
-- Desc: ?
-- ---------------------------------------------------------------------------------

local MaxCardNum = 2
local UIWidgetUnknownImgUpView = class("UIWidgetUnknownImgUpView")

function UIWidgetUnknownImgUpView:OnEnter(tbWallInfo , nUIDirection)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nUIDirection = nUIDirection
    self.tbWallInfo = tbWallInfo
    self:UpdateInfo()
end

function UIWidgetUnknownImgUpView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetUnknownImgUpView:BindUIEvent()
    
end

function UIWidgetUnknownImgUpView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetUnknownImgUpView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIWidgetUnknownImgUpView:GetRemainCardNum()
    local nRemainNum = 0
    nRemainNum  = nRemainNum + (self.tbWallInfo[2] == false and 1 or 0)
    nRemainNum  = nRemainNum + (self.tbWallInfo[1] == false and 1 or 0)
    return nRemainNum
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetUnknownImgUpView:UpdateInfo()
    

    UIHelper.SetVisible(self.tbCardList[1], self.tbWallInfo[1])
    UIHelper.SetVisible(self.tbCardList[2], self.tbWallInfo[2])
    self:UpdateSkin()

end

function UIWidgetUnknownImgUpView:UpdateSkin()
    local szImg = MahjongData.GetBackCardImg(self.nUIDirection)
    for index, img in ipairs(self.tbCardList) do
        UIHelper.SetSpriteFrame(img, szImg)
    end
end



function UIWidgetUnknownImgUpView:SetVisible(nIndex, bShow)
    UIHelper.SetVisible(self.tbCardList[nIndex], bShow)
end

function UIWidgetUnknownImgUpView:GetVisible(nIndex)
    return UIHelper.GetVisible(self.tbCardList[nIndex])
end

return UIWidgetUnknownImgUpView