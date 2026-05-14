-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandIdentityBaseTipCell
-- Date: 2024-01-22 11:20:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandIdentityBaseTipCell = class("UIHomelandIdentityBaseTipCell")

function UIHomelandIdentityBaseTipCell:OnEnter(tbTip)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbTip = tbTip
    self:UpdateInfo()
end

function UIHomelandIdentityBaseTipCell:InitFishHolder(tInfo, nWeight, nStar)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tInfo = tInfo
    self.nWeight = nWeight
    self.nStar = nStar
    self:UpdateFishHolderInfo()
end

function UIHomelandIdentityBaseTipCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandIdentityBaseTipCell:BindUIEvent()

end

function UIHomelandIdentityBaseTipCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandIdentityBaseTipCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandIdentityBaseTipCell:UpdateInfo()
    local tbTip = self.tbTip
    local label = tbTip.bFish and self.LabelFishContent or self.LabelContent
    if tbTip.szName == "" then
        UIHelper.SetVisible(self.WidgetContentTitle, false)
    end
    if not tbTip.bLock then
        UIHelper.SetVisible(self.ImgState, true)
        UIHelper.SetVisible(self.ImgState02, false)
    end
    UIHelper.SetString(label, tbTip.szContent)
    UIHelper.SetString(self.LabelContentTitle, tbTip.szName)
    UIHelper.SetVisible(self.LabelFishContent, tbTip.bFish)
    UIHelper.SetVisible(self.LabelContent, not tbTip.bFish)
    UIHelper.LayoutDoLayout(self._rootNode)
end

function UIHomelandIdentityBaseTipCell:UpdateFishHolderInfo(tHolder)
    UIHelper.SetVisible(self.WidgetContentTitle, false)
    UIHelper.SetVisible(self.LabelContent, false)
    UIHelper.SetVisible(self.ImgLineNormal, false)
    UIHelper.SetVisible(self.WidgetFishRecord, true)
    UIHelper.SetVisible(self.WidgetBest, false)
    UIHelper.SetVisible(self.ImgChampion, false)

    if self.nWeight <= 0 then
        UIHelper.SetVisible(self.LabelNone, true)
        return
    elseif tHolder and tHolder.nWeight == self.nWeight then --自己和服务器记录的最大记录相同时显示“记录保持者”
        UIHelper.SetVisible(self.ImgChampion, true)
    end

    UIHelper.SetVisible(self.WidgetBest, true)
    UIHelper.SetVisible(self.LabelNone, false)
    local szWeight = g_tStrings.STR_HOMELAND_FishDetail_NoRecord
    szWeight = FormatString(g_tStrings.STR_HOMELAND_FISHWEIGHT, string.format("%.2f",(self.nWeight / 100)))

    UIHelper.SetString(self.LabelMoney, szWeight)
    for index, img in ipairs(self.tbStarsImg) do
        UIHelper.SetVisible(img, index <= self.nStar)
    end
end

return UIHomelandIdentityBaseTipCell