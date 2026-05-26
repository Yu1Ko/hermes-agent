-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeCollectionListToggle
-- Date: 2023-08-03 16:20:41
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeCollectionListToggle = class("UIHomeCollectionListToggle")

function UIHomeCollectionListToggle:OnEnter(tbSetInfo)
    self.tbSetInfo = tbSetInfo
    self.fnSelectedCallback = tbSetInfo.fnSelectedCallback
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:SetSelected(false)
    self:UpdateInfo()
end

function UIHomeCollectionListToggle:OnExit()
    self.bInit = false
end

function UIHomeCollectionListToggle:BindUIEvent()
    UIHelper.BindUIEvent(self.TogLaunchFurnitureList, EventType.OnClick, function ()
        Event.Dispatch(EventType.OnSelectedHomeCollectionLaunchTog, self.tbSetInfo)
        if self.fnSelectedCallback then
            self.fnSelectedCallback()
        end
    end)

    UIHelper.BindUIEvent(self.TogCollect, EventType.OnClick, function()
        local bSelected = UIHelper.GetSelected(self.TogCollect)
        if bSelected then
            TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_FURNITURE_SET_LIKE_TIP)
            self:AppendOneLikedSet(self.tbSetInfo.dwSetID)
        else
            TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_FURNITURE_SET_DISLIKE_TIP)
            self:RemoveOneLikedSet(self.tbSetInfo.dwSetID)
        end
        Event.Dispatch(EventType.OnClickHomeCollectionLikeSetTog)
    end)

    UIHelper.BindUIEvent(self.TogCollect_S, EventType.OnClick, function()
        local bSelected = UIHelper.GetSelected(self.TogCollect_S)
        if bSelected then
            TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_FURNITURE_SET_LIKE_TIP)
            self:AppendOneLikedSet(self.tbSetInfo.dwSetID)
        else
            TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_FURNITURE_SET_DISLIKE_TIP)
            self:RemoveOneLikedSet(self.tbSetInfo.dwSetID)
        end
        Event.Dispatch(EventType.OnClickHomeCollectionLikeSetTog)
    end)
end

function UIHomeCollectionListToggle:RegEvent()
    Event.Reg(self, EventType.OnSelectedHomeCollectionLaunchTog, function(tbSetInfo)
        if self.tbSetInfo == tbSetInfo then
            self:SetSelected(true)
        else
            self:SetSelected(false)
        end
        -- self:UpdateInfo()
    end)

    Event.Reg(self, "ON_SYNC_SET_COLLECTION", function()
		self:UpdateInfo()
    end)

    Event.Reg(self, "LUA_HOMELAND_BUY_FURNITURE_END", function()
		self:UpdateInfo()
    end)
end

function UIHomeCollectionListToggle:UpdateInfo()
    UIHelper.SetSwallowTouches(self.TogLaunchFurnitureList, false)
    UIHelper.SetSwallowTouches(self.TogCollect, true)
    self:UpdateNameAndStars()
    self:UpdateAwardPoint()

    UIHelper.SetSelected(self.TogCollect, false)
    if self:IsLikedSetCheck(self.tbSetInfo.dwSetID) then
        UIHelper.SetSelected(self.TogCollect, true)
        UIHelper.SetSelected(self.TogCollect_S, true)
    end
end

function UIHomeCollectionListToggle:UpdateNameAndStars()
    local tbSetInfo = self.tbSetInfo
    local eCollectType, nCollectedFurnNum, nOverallFurnNum = self:GetSetBriefCollectProgress(tbSetInfo.dwSetID)
    local szImgPath = string.gsub(tbSetInfo.szImgPath, "ui/Image", "mui/Resource")
    szImgPath = string.gsub(szImgPath, ".tga", ".png")
    local szSetCollected = "（"..nCollectedFurnNum.."/"..nOverallFurnNum.."）"

    for i = 1, #self.tbFurnitureLv, 1 do
        if i > tbSetInfo.nStars then
            UIHelper.SetVisible(self.tbFurnitureLv[i], false)
        end
    end
    if eCollectType == SET_COLLECTION_STATE_TYPE.TO_AWARD then
        UIHelper.SetVisible(self.ImgRedDot, true)
        UIHelper.SetVisible(self.ImgFullCollect, true)
        UIHelper.SetVisible(self.ImgFullCollect_S, true)
        UIHelper.SetVisible(self.LabelFurnitureNum, false)
        UIHelper.SetVisible(self.LabelFurnitureNum_S, false)
    elseif eCollectType == SET_COLLECTION_STATE_TYPE.COLLECTED then
        UIHelper.SetVisible(self.ImgRedDot, false)
        UIHelper.SetVisible(self.ImgFullCollect, true)
        UIHelper.SetVisible(self.ImgFullCollect_S, true)
        UIHelper.SetVisible(self.LabelFurnitureNum, false)
        UIHelper.SetVisible(self.LabelFurnitureNum_S, false)
    else
        UIHelper.SetVisible(self.ImgRedDot, false)
        UIHelper.SetVisible(self.ImgFullCollect, false)
        UIHelper.SetVisible(self.ImgFullCollect_S, false)
    end

    UIHelper.SetString(self.LabelFurnitureName, UIHelper.GBKToUTF8(tbSetInfo.szName))
    UIHelper.SetString(self.LabelFurnitureNum, szSetCollected)

    UIHelper.SetString(self.LabelFurnitureName_S, UIHelper.GBKToUTF8(tbSetInfo.szName))
    UIHelper.SetString(self.LabelFurnitureNum_S, szSetCollected)

    UIHelper.LayoutDoLayout(self.LayoutNormal)
    UIHelper.LayoutDoLayout(self.LayoutSelect)
    self.ImgNormalIcon:setTexture(szImgPath, true)
end

function UIHomeCollectionListToggle:GetSetBriefCollectProgress(dwSetID)
	local tInfo = GetClientPlayer().GetSetCollection(dwSetID)
	local eCollectType = tInfo.eType
	local aSetIndicesCollectStates = tInfo.tSetUnit
	local nCollectedNum = 0
	for _, value in ipairs(aSetIndicesCollectStates) do
		if value == 1 then
			nCollectedNum = nCollectedNum + 1
		end
	end
	return eCollectType, nCollectedNum, #aSetIndicesCollectStates
end

function UIHomeCollectionListToggle:UpdateAwardPoint()
    local tbSetInfo = self.tbSetInfo
    local nCollectPoints = self:GetSetCollectPoints(tbSetInfo.dwSetID)
    local nAchievePoints = tbSetInfo.nAchievePts
    local nFurniturePoints = self:GetSeasonFurniturePoints(tbSetInfo.dwSetID)
    for i = 1, 3, 1 do
        UIHelper.SetSpriteFrame(self.imgFurnitureCost[i], HomeLandCollectionAwardPointImg[i])
        UIHelper.SetSpriteFrame(self.imgFurnitureCost_S[i], HomeLandCollectionAwardPointImg[i])
    end

    if nAchievePoints == 0 then
        UIHelper.SetVisible(self.imgFurnitureCost[2], false)
        UIHelper.SetVisible(self.tbFurniturePointAward[2], false)
        UIHelper.SetVisible(self.imgFurnitureCost_S[2], false)
        UIHelper.SetVisible(self.tbFurniturePointAward_S[2], false)
    end
    if nFurniturePoints == 0 then
        UIHelper.SetVisible(self.imgFurnitureCost[3], false)
        UIHelper.SetVisible(self.tbFurniturePointAward[3], false)
        UIHelper.SetVisible(self.imgFurnitureCost_S[3], false)
        UIHelper.SetVisible(self.tbFurniturePointAward_S[3], false)
    end

    UIHelper.SetString(self.tbFurniturePointAward[1], tostring(nCollectPoints))
    UIHelper.SetString(self.tbFurniturePointAward[2], tostring(nAchievePoints))
    UIHelper.SetString(self.tbFurniturePointAward[3], tostring(nFurniturePoints))

    UIHelper.SetString(self.tbFurniturePointAward_S[1], tostring(nCollectPoints))
    UIHelper.SetString(self.tbFurniturePointAward_S[2], tostring(nAchievePoints))
    UIHelper.SetString(self.tbFurniturePointAward_S[3], tostring(nFurniturePoints))

end

function UIHomeCollectionListToggle:GetSetCollectPoints(dwSetID)
	local tConfig = GetSetCollectionConfig(dwSetID)
	return tConfig and tConfig.dwCustomAwardData1 or 0
end

function UIHomeCollectionListToggle:GetSeasonFurniturePoints(dwSetID)
	local tConfig = GetSetCollectionConfig(dwSetID)
	return tConfig and tConfig.dwCustomAwardData2 or 0
end

function UIHomeCollectionListToggle:IsLikedSetCheck(dwSetID)
    if table.contain_value(Storage.HomeLand.tbLikedSetID, dwSetID) then return true end
    return false
end

function UIHomeCollectionListToggle:AppendOneLikedSet(dwSetID)
    if table.contain_value(Storage.HomeLand.tbLikedSetID, dwSetID) then return end
    table.insert(Storage.HomeLand.tbLikedSetID, dwSetID)
    Storage.HomeLand.Dirty()
end

function UIHomeCollectionListToggle:RemoveOneLikedSet(dwSetID)
    local tbLikedSetID = Storage.HomeLand.tbLikedSetID
    for index, value in ipairs(tbLikedSetID) do
        if value == dwSetID then
            table.remove(tbLikedSetID, index)
            break
        end
    end
    Storage.HomeLand.Dirty()
end

function UIHomeCollectionListToggle:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogLaunchFurnitureList, bSelected)
end

return UIHomeCollectionListToggle