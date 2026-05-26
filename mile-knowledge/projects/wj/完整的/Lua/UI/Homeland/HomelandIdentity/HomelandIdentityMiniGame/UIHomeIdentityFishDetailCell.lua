-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeIdentityFishDetailCell
-- Date: 2024-01-25 14:33:08
-- Desc: ?
-- ---------------------------------------------------------------------------------
local FishQuality = {
    [1] = g_tStrings.STR_HOMELAND_FishBook_White,
    [2] = g_tStrings.STR_HOMELAND_FishBook_Green,
    [3] = g_tStrings.STR_HOMELAND_FishBook_Blue,
    [4] = g_tStrings.STR_HOMELAND_FishBook_Purple,
    [5] = g_tStrings.STR_HOMELAND_FishBook_Orange,
}
local UIHomeIdentityFishDetailCell = class("UIHomeIdentityFishDetailCell")

function UIHomeIdentityFishDetailCell:OnEnter(tInfo, nWeight, nStar)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tInfo = tInfo
    self.nWeight = nWeight
    self.nStar = nStar
    self:UpdateInfo()
end

function UIHomeIdentityFishDetailCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomeIdentityFishDetailCell:BindUIEvent()
    
end

function UIHomeIdentityFishDetailCell:RegEvent()
    
end

function UIHomeIdentityFishDetailCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomeIdentityFishDetailCell:UpdateInfo()
    local szWeight = "--"
    local tInfo = self.tInfo
    local nStar = self.nStar
    local szPath = UIHelper.FixDXUIImagePath(tInfo.szPath)
    self.ImgFish:setTexture(szPath, false)
    if self.ImgFish.getTexture then
        local tex = self.ImgFish:getTexture()
        if tex and tex.getContentSize then
            local size = tex:getContentSize()
            UIHelper.SetContentSize(self.ImgFish, size.width, size.height)
        end
    end
    UIHelper.SetSpriteFrame(self.ImgQuality, HomelandFishQualityImg[tInfo.nQuality])
    UIHelper.SetString(self.LabelRecord, szWeight)
    UIHelper.SetString(self.LabelFishName, UIHelper.GBKToUTF8(tInfo.szName))
    UIHelper.SetString(self.LabelPlayerName, g_tStrings.STR_HOMELAND_FishDetail_NoRecord1)
    for index, img in ipairs(self.tbStarImg) do
        UIHelper.SetVisible(img, index <= nStar)
    end
    UIHelper.LayoutDoLayout(self.LayoutFishName)
    UIHelper.LayoutDoLayout(self.WidgetRecord)
end

function UIHomeIdentityFishDetailCell:UpdateHolderInfo(tHolder)
    local szWeight = g_tStrings.STR_HOMELAND_FishDetail_NoRecord
    local szHolderName = g_tStrings.STR_HOMELAND_FishDetail_Record_Holder..UIHelper.GBKToUTF8(tHolder.szName)
    if tHolder.nRecord > 0 then
        szWeight = FormatString(g_tStrings.STR_HOMELAND_FISHWEIGHT, string.format("%.2f",(tHolder.nRecord / 100)))
    else
        szHolderName = g_tStrings.STR_HOMELAND_FishDetail_NoRecord1
    end
    UIHelper.SetString(self.LabelRecord, szWeight)
    UIHelper.SetString(self.LabelPlayerName, szHolderName)
    UIHelper.SetVisible(self.LabelRecord, tHolder.nRecord > 0)
    UIHelper.LayoutDoLayout(self.WidgetRecord)
end

return UIHomeIdentityFishDetailCell