-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeAchievementRightPopPanl
-- Date: 2023-07-19 20:51:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeAchievementRightPopView = class("UIHomeAchievementRightPopView")

function UIHomeAchievementRightPopView:OnEnter(nIndex, nCollected, nMaxCollect)
    self.nCollected     = nCollected
    self.nIndex         = nIndex
    self.nMaxCollect    = nMaxCollect
    self.tbCells = self.tbCells or {}
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIHomeAchievementRightPopView:OnExit()
    self.bInit = false
end

function UIHomeAchievementRightPopView:BindUIEvent()
    
end

function UIHomeAchievementRightPopView:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        UIMgr.Close(self)
    end)

    Event.Reg(self, EventType.OnHomeAchievementRightPopOpen, function (nIndex, nCollected, nMaxCollect)
        -- UIHelper.RemoveAllChildren(self.WidgetRightPop)
        self.nCollected     = nCollected
        self.nIndex         = nIndex
        self.nMaxCollect    = nMaxCollect
        self.tbCells = self.tbCells or {}
        self:UpdateInfo()
    end)

    -- UIHelper.SetTouchDownHideTips(self.Btn, false)
end

function UIHomeAchievementRightPopView:UpdateInfo()
    UIHelper.SetVisible(self.ImgSubtitleIcon, true)
    self:UpdateInfoByRightCells()
end

function UIHomeAchievementRightPopView:UpdateInfoByRightCells()
	local tFurnitureInfo = Table_GetSeasonFurnitureInfo(self.nIndex)
	local nRewardFurnitureType = tFurnitureInfo.nFurnitureType
	local nRewardFurnitureIndex = tFurnitureInfo.nFurnitureIndex
	local tActivityIndex = string.split(tFurnitureInfo.szActivityIndex, ";")
	local tAttributeID = string.split(tFurnitureInfo.szAttributeID, ";")
    local szImgHomeIcon = HomeLandAchievementCellUnderIconImg[self.nIndex]
    local szTopTitleNum = tostring(self.nCollected).."/"..tostring(self.nMaxCollect)
    if self.nCollected >= self.nMaxCollect then
        szTopTitleNum = tostring(self.nMaxCollect).."/"..tostring(self.nMaxCollect)
    end
    local szTopTitle = ""
    if self.nIndex == 9 then
        szImgHomeIcon = ""
        szTopTitle = "结庐总进度："
        UIHelper.SetVisible(self.ImgSubtitleIcon, false)
    else
        szTopTitle = g_tStrings.tSeasonFurName[self.nIndex].."点数："
    end
    UIHelper.SetString(self.LabelSubtitleNum, szTopTitleNum)
    UIHelper.SetString(self.LabelSubtitle, szTopTitle)
    UIHelper.SetSpriteFrame(self.ImgSubtitleIcon, szImgHomeIcon)
    UIHelper.LayoutDoLayout(self.WidgetSubtitle)

    for _, cell in ipairs(self.tbCells) do
        UIHelper.RemoveFromParent(cell._rootNode, true)
    end
    self.tbCells = {}
    self:SetGainWayInfo(tActivityIndex)
    self:SetRewardFurnitureInfo(nRewardFurnitureType, nRewardFurnitureIndex)
    self:SetAttributeList(tAttributeID)
    UIHelper.SetTouchDownHideTips(self.ScrollViewHomeAchievementInfo, false)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewHomeAchievementInfo)
end

function UIHomeAchievementRightPopView:SetGainWayInfo(tActivityIndex)
    if self.nIndex == 9 then
        local nActivityIndex = tActivityIndex[1]
        local tbActivityInfo = Table_GetSeasonFurnitureActivity(nActivityIndex)
        local scriptMainBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetRightPopAccessBg, self.LayoutAccess)
        local tbMainActivity = {{szGainDesc = UIHelper.GBKToUTF8(tbActivityInfo.szGainDesc), dwActivityID = tbActivityInfo.dwActivityID}}
        table.insert(self.tbCells, scriptMainBtn)
        scriptMainBtn:OnEnter(tbMainActivity, 40)
        UIHelper.LayoutDoLayout(self.LayoutHomeAchievementInfo)
        UIHelper.LayoutDoLayout(self.LayoutAccess)
        return
    end

    local tDailyActivity = {}
    local tWeeklyActivity = {}
    local tCyclicActivity = {}

    for _, nActivityIndex in ipairs(tActivityIndex) do
        local tbActivityInfo = Table_GetSeasonFurnitureActivity(nActivityIndex)
        if tbActivityInfo.nTypeFrame == 40 then
            table.insert(tDailyActivity, {szGainDesc = UIHelper.GBKToUTF8(tbActivityInfo.szGainDesc), dwActivityID = tbActivityInfo.dwActivityID})
        elseif tbActivityInfo.nTypeFrame == 41 then
            table.insert(tCyclicActivity, {szGainDesc = UIHelper.GBKToUTF8(tbActivityInfo.szGainDesc), dwActivityID = tbActivityInfo.dwActivityID})
        elseif tbActivityInfo.nTypeFrame == 42 then
            table.insert(tWeeklyActivity, {szGainDesc = UIHelper.GBKToUTF8(tbActivityInfo.szGainDesc), dwActivityID = tbActivityInfo.dwActivityID})
        end
    end

    if not table.is_empty(tDailyActivity) then
        local scriptDailyActivity = UIHelper.AddPrefab(PREFAB_ID.WidgetRightPopAccessBg, self.LayoutAccess)
        table.insert(self.tbCells, scriptDailyActivity)
        scriptDailyActivity:OnEnter(tDailyActivity, 40)
    end
    if not table.is_empty(tCyclicActivity) then
        local scriptCyclicActivity = UIHelper.AddPrefab(PREFAB_ID.WidgetRightPopAccessBg, self.LayoutAccess)
        table.insert(self.tbCells, scriptCyclicActivity)
        scriptCyclicActivity:OnEnter(tCyclicActivity, 41)
    end
    if not table.is_empty(tWeeklyActivity) then
        local scriptWeeklyActivity = UIHelper.AddPrefab(PREFAB_ID.WidgetRightPopAccessBg, self.LayoutAccess)
        table.insert(self.tbCells, scriptWeeklyActivity)
        scriptWeeklyActivity:OnEnter(tWeeklyActivity, 42)
    end
    UIHelper.LayoutDoLayout(self.LayoutHomeAchievementInfo)
    UIHelper.LayoutDoLayout(self.LayoutAccess)
end

function UIHomeAchievementRightPopView:SetRewardFurnitureInfo(nRewardFurnitureType, nRewardFurnitureIndex)

    local tItemInfo = GetItemInfo(nRewardFurnitureType, nRewardFurnitureIndex)
    local szFurnitureName = ItemData.GetItemNameByItemInfo(tItemInfo)
    local szName = "<color=#D7F6FF>家具奖励：</c><color=#eebf58>"..UIHelper.GBKToUTF8(szFurnitureName).."</color>"
    if tItemInfo then
		dwFurnitureID = tItemInfo.dwFurnitureID
	end
    UIHelper.SetRichText(self.RichTextlFurnitureReward, szName)
    local scriptFurnitureReward = UIHelper.AddPrefab(PREFAB_ID.WidgetRightPopFurnitureCell, self.LayoutFurnitureReward, nRewardFurnitureType, nRewardFurnitureIndex, self.nIndex)
    table.insert(self.tbCells, scriptFurnitureReward)
    UIHelper.LayoutDoLayout(self.LayoutFurnitureReward)
end

function UIHomeAchievementRightPopView:SetAttributeList(tAttributeID)

    for _, nAttributeID in pairs(tAttributeID) do
        local tAttributeInfo = Table_GetSeasonFurnitureAttribute(nAttributeID)
        local scriptRewardCell = UIHelper.AddPrefab(PREFAB_ID.WidgetRightPopRewardCell, self.LayoutEffectReward)
        table.insert(self.tbCells, scriptRewardCell)
        scriptRewardCell:OnEnter(tAttributeInfo)
    end
    UIHelper.LayoutDoLayout(self.LayoutEffectReward)
end

return UIHomeAchievementRightPopView