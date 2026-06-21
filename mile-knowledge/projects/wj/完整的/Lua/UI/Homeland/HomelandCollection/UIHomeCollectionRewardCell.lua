-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeCollectionRewardCell
-- Date: 2023-08-09 11:24:01
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeCollectionRewardCell = class("UIHomeCollectionRewardCell")

function UIHomeCollectionRewardCell:OnEnter(nIndex, tInfo, nCPLevel, nPointsInLevel, nDestPointsInLevel, bEnd)
    self.nIndex = nIndex
    self.tInfo = tInfo
    self.bEnd = bEnd
    self.nCPLevel = nCPLevel
    self.nPointsInLevel = nPointsInLevel
    self.nDestPointsInLevel = nDestPointsInLevel
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIHomeCollectionRewardCell:OnExit()
    self.bInit = false
end

function UIHomeCollectionRewardCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnFurnitureReward, EventType.OnClick, function ()
        local _, scriptTips = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, self._rootNode)
		scriptTips:OnInitWithTabID(self.tInfo.nItemType, self.tInfo.dwItemIndex)
        scriptTips:SetBtnState({})
    end)
end

function UIHomeCollectionRewardCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomeCollectionRewardCell:UpdateInfo()
    self:UpdateProgressBarInfo()

    local szPoint = tostring(self.tInfo.nPoints)
    local szName = UIHelper.GBKToUTF8(self.tInfo.szName)
    local nFlowerIcon = self.nIndex > (self.nCPLevel - 1) and 2 or 1
    local szIconPath = string.gsub(self.tInfo.szIconPath, "ui/Image", "mui/Resource")
    szIconPath = string.gsub(szIconPath, ".tga", ".png")

    UIHelper.SetString(self.LabelFurnitureTitle, szName)
    UIHelper.SetString(self.LabelNum, szPoint)
    UIHelper.SetTexture(self.ImgFurniture, szIconPath)

    UIHelper.SetSpriteFrame(self.ImgFurnitureCount, HomeLandCollectionLevelSchedule[nFlowerIcon])
end

function UIHomeCollectionRewardCell:UpdateProgressBarInfo()
    local nNowLevel = self.nCPLevel - 1
    local nProgressBarPercent = self.nPointsInLevel / self.nDestPointsInLevel *100
    if self.nIndex == 1 then
        UIHelper.SetVisible(self.ImgProgressBg01Front, true)
        UIHelper.SetVisible(self.ProgressBarFurnitureFront, true)
        if self.nIndex < nNowLevel then
            UIHelper.SetProgressBarPercent(self.ProgressBarFurnitureFront, 100)
            UIHelper.SetProgressBarPercent(self.ProgressBarFurniture, 100)
        elseif self.nIndex == nNowLevel then
            UIHelper.SetProgressBarPercent(self.ProgressBarFurnitureFront, 100)
            UIHelper.SetProgressBarPercent(self.ProgressBarFurniture, nProgressBarPercent)
        elseif self.nIndex > nNowLevel then
            UIHelper.SetProgressBarPercent(self.ProgressBarFurnitureFront, nProgressBarPercent)
            UIHelper.SetProgressBarPercent(self.ProgressBarFurniture, 0)
        end
    elseif self.nIndex < nNowLevel and nNowLevel >= 0 then
        UIHelper.SetVisible(self.ImgProgressBg01Front, false)
        UIHelper.SetVisible(self.ProgressBarFurnitureFront, false)
        UIHelper.SetProgressBarPercent(self.ProgressBarFurniture, 100)
    elseif self.nIndex == nNowLevel and nNowLevel >= 0 then
        UIHelper.SetVisible(self.ImgProgressBg01Front, false)
        UIHelper.SetVisible(self.ProgressBarFurnitureFront, false)
        UIHelper.SetProgressBarPercent(self.ProgressBarFurniture, nProgressBarPercent)
    elseif self.nIndex > nNowLevel and nNowLevel >= 0 then
        UIHelper.SetVisible(self.ImgProgressBg01Front, false)
        UIHelper.SetVisible(self.ProgressBarFurnitureFront, false)
        UIHelper.SetProgressBarPercent(self.ProgressBarFurniture, 0)
    end
    if self.bEnd then
        UIHelper.SetVisible(self.ProgressBarFurniture, false)
        UIHelper.SetVisible(self.ImgProgressBg, false)
    end
end

return UIHomeCollectionRewardCell