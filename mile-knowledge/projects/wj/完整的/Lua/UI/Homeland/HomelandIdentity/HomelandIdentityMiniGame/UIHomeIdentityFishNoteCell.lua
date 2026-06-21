-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeIdentityFishNoteCell
-- Date: 2024-01-25 11:09:53
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeIdentityFishNoteCell = class("UIHomeIdentityFishNoteCell")

function UIHomeIdentityFishNoteCell:OnEnter(nIndex, tInfo, nWeight, nStar)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nIndex = nIndex
    self.tInfo = tInfo
    self.nWeight = nWeight
    self.nStar = nStar
    self:UpdateInfo()
end

function UIHomeIdentityFishNoteCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomeIdentityFishNoteCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnFish, EventType.OnClick, function()
        Event.Dispatch(EventType.OnFishNoteOpenDetailPop, self.nIndex, self.tInfo)
    end)
end

function UIHomeIdentityFishNoteCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomeIdentityFishNoteCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomeIdentityFishNoteCell:UpdateInfo()
    local nIndex = self.nIndex
    local tInfo = self.tInfo
    local nWeight = self.nWeight
    local nStar = self.nStar
    local szPath = UIHelper.FixDXUIImagePath(tInfo.szPath)
    local size = nil
    self.ImgFish:setTexture(szPath, false)
    if self.ImgFish.getTexture then
        local tex = self.ImgFish:getTexture()
        if tex and tex.getContentSize then
            size = tex:getContentSize()
        end
    end
    UIHelper.SetContentSize(self.ImgFish, size.width, size.height)
    UIHelper.SetString(self.LabelFishName, UIHelper.GBKToUTF8(tInfo.szName))
    UIHelper.SetNodeGray(self.ImgFish, nWeight == 0, true)
    for index, img in ipairs(self.tbStarImg) do
        UIHelper.SetVisible(img, index <= nStar)
    end
end


return UIHomeIdentityFishNoteCell