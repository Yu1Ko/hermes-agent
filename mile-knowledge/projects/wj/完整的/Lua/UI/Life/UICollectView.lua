-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICollectView
-- Date: 2022-11-21 19:51:53
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICollectView = class("UICollectView")

local tbCraftConfig =
{
    {szName = "采金", szBGPath = "UIAtlas2_Life_Collection_CaiJin", szTitlePath = "UIAtlas2_Life_Collection_Title_CaiJing"},
    {szName = "神农", szBGPath = "UIAtlas2_Life_Collection_ShenNong", szTitlePath = "UIAtlas2_Life_Collection_Title_ShenNong"},
    {szName = "庖丁", szBGPath = "UIAtlas2_Life_Collection_PaoDing", szTitlePath = "UIAtlas2_Life_Collection_Title_PaoDing"},
}

function UICollectView:OnEnter(nDefaultProfessionID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbSelectCollectCell = nil
    -- self.VigorScript = UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.WidgetCurrency)
    -- self.VigorScript:SetCurrencyType(CurrencyType.Vigor)
    self.nProfessionID = nDefaultProfessionID or 1
    UIHelper.SetToggleGroupSelected(self.WidgetAnchorLeft, self.nProfessionID - 1)
    local Profession = GetProfession(self.nProfessionID)
    self:Init()
    self:UpdateVigor()
    self:UpdateInfo()
end

function UICollectView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICollectView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnMask, EventType.OnClick, function ()
        local node = UIHelper.GetParent(self.BtnMask)
        UIHelper.SetVisible(node, false)
    end)

    for index, tog in ipairs(self.tbTogAnchor) do
        UIHelper.ToggleGroupAddToggle(self.WidgetAnchorLeft, tog)
        UIHelper.BindUIEvent(tog, EventType.OnClick, function ()
            UIHelper.SetToggleGroupSelected(self.WidgetAnchorLeft, index - 1)
            if self.nProfessionID ~= index then
                self.nProfessionID = index
                self.tbSelectCollectCell = nil
                UIHelper.SetString(self.LabelCast, tbCraftConfig[self.nProfessionID].szName)
                self:UpdateInfo()
                if self.fSwtichCallBack then self.fSwtichCallBack(self.nProfessionID) end
            end
        end)
    end
end

function UICollectView:RegEvent()
    Event.Reg(self, "SYNC_ROLE_DATA_END", function()
        self:UpdateVigor()
    end)
    Event.Reg(self, "PLAYER_EXPERIENCE_UPDATE", function()
        self:UpdateVigor()
    end)
    Event.Reg(self, "UPDATE_VIGOR", function()
        self:UpdateVigor()
    end)
end

function UICollectView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UICollectView:Init()
    self:InitCraftTabe()
    local player = GetClientPlayer()
    for index, tog in ipairs(self.tbTogAnchor) do
        local nodes = UIHelper.GetChildren(tog)
        local bExpertised = player.IsProfessionExpertised(index)
        if not bExpertised then
            for i, node in ipairs(nodes) do
                local name = tostring(node:getName())
                if name == "ImgSpecialization" then
                    UIHelper.SetVisible(node, false)
                end
            end
        end
    end
end

function UICollectView:InitCraftTabe()
    self.tbCraft = CraftData.tbCollectTable
end

function UICollectView:UpdateInfo()
    self:UpdateCell()
    self:UpdateDetail()
end

function UICollectView:UpdateCell()
    UIHelper.ToggleGroupRemoveAllToggle(self.WidgetAniMiddle)
    UIHelper.RemoveAllChildren(self.ScrollviewMining)
    local tabItem = self.tbCraft[self.nProfessionID]
    for _, v in pairs(tabItem) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItemLift, self.ScrollviewMining, v)
        script:AddTogSelected(function (tbCell, bSelected)
            if bSelected then
                self.tbSelectCollectCell = tbCell
                self:UpdateDetail()
            else
                self.tbSelectCollectCell = nil
            end
        end)
        UIHelper.ToggleGroupAddToggle(self.WidgetAniMiddle, script.ToggleSelect)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollviewMining)
    UIHelper.ScrollToTop(self.ScrollviewMining, 0)
end

function UICollectView:UpdateDetail()
    if self.tbSelectCollectCell == nil then
        local tbCells = self.tbCraft[self.nProfessionID]
        if tbCells == nil then
            return
        end
        self.tbSelectCollectCell = tbCells[1]
    end

    local nIconID = Table_GetItemIconID(self.tbSelectCollectCell.nCraftItemID, false)
    if nIconID > 0 then
        UIHelper.SetString(self.LabelInfoTitle, self.tbSelectCollectCell.szName)
        UIHelper.SetItemIconByIconID(self.ImgIconGoods, nIconID)

        local itemInfo = ItemData.GetItemInfo(self.tbSelectCollectCell.dwItemType, self.tbSelectCollectCell.dwItemIndex)
        UIHelper.SetSpriteFrame(self.ImgPolishCountBG, ItemQualityBGColor[itemInfo.nQuality + 1])
    end

    local szDescList = string.split(self.tbSelectCollectCell.szDesc, '\n')
    if #szDescList == 2 then
        local szDesc = string.format(
            "<img src='UIAtlas2_Life_Collection_TitielHintImg' width='15' height='15'/><color=#d7f6ff> 百科：</color><color=#aed9e0>%s</color>", szDescList[1])
        UIHelper.SetRichText(self.tbRichTextDetails[1], szDesc)
        szDesc = string.gsub(szDescList[2], "小提示：", "")
        szDesc = string.format(
            "<img src='UIAtlas2_Life_Collection_TitielHintImg' width='15' height='15'/><color=#d7f6ff> 小提示：</color><color=#aed9e0>%s</color>", szDesc)
        UIHelper.SetRichText(self.tbRichTextDetails[2], szDesc)
        UIHelper.SetVisible(self.tbRichTextDetails[3], false)
    elseif #szDescList == 4 then
        local szDesc = string.format(
            "<img src='UIAtlas2_Life_Collection_TitielHintImg' width='15' height='15'/><color=#d7f6ff> 百科：</color><color=#aed9e0>%s\n%s</color>", szDescList[2], szDescList[3])
        UIHelper.SetRichText(self.tbRichTextDetails[1], szDesc)

        szDesc = string.gsub(szDescList[1], "携带：", "")
        szDesc = string.format(
            "<img src='UIAtlas2_Life_Collection_TitielHintImg' width='15' height='15'/><color=#d7f6ff> 携带：</color><color=#aed9e0>%s</color>", szDesc)
        UIHelper.SetRichText(self.tbRichTextDetails[2], szDesc)

        UIHelper.SetVisible(self.tbRichTextDetails[3], true)
        szDesc = string.gsub(szDescList[4], "小提示：", "")
        szDesc = string.format(
            "<img src='UIAtlas2_Life_Collection_TitielHintImg' width='15' height='15'/><color=#d7f6ff> 小提示：</color><color=#aed9e0>%s</color>", szDesc)
        UIHelper.SetRichText(self.tbRichTextDetails[3], szDesc)
    else

    end
    local tbConfig = tbCraftConfig[self.nProfessionID]
    UIHelper.SetSpriteFrame(self.ImgTitle, tbConfig.szTitlePath)
    UIHelper.SetSpriteFrame(self.ImgAnchorMiningBg, tbConfig.szBGPath)

    UIHelper.RemoveAllChildren(self.LayoutPlaceName)

    local bIsEmpty =
        not self.tbSelectCollectCell.tProduceInfoList and
        not self.tbSelectCollectCell.tCollectDInfoList and
        not self.tbSelectCollectCell.tCollectNInfoList

    UIHelper.SetVisible(self.LabelFullMap, bIsEmpty)
    if not bIsEmpty then
        for _, tInfo in pairs(self.tbSelectCollectCell.tProduceInfoList) do
            UIHelper.AddPrefab(PREFAB_ID.WidgetItemWays, self.ScrollViewDetail, tInfo)
        end
        for _, tInfo in pairs(self.tbSelectCollectCell.tCollectDInfoList) do
            UIHelper.AddPrefab(PREFAB_ID.WidgetItemWays, self.ScrollViewDetail, tInfo)
        end
        for _, tInfo in pairs(self.tbSelectCollectCell.tCollectNInfoList) do
            UIHelper.AddPrefab(PREFAB_ID.WidgetItemWays, self.ScrollViewDetail, tInfo)
        end
    end


    local player = GetClientPlayer()
    local ProTab = player.GetProfession()
    local tProInfo = nil
    for _, val in pairs(ProTab) do
        local nProID = val.ProfessionID
        if nProID == self.nProfessionID then
            tProInfo = val
        end
    end
    if tProInfo == nil then
        local node = UIHelper.GetParent(self.BarMiningProgress)
        UIHelper.SetVisible(node, false)
        return
    end
    local nExp = tProInfo.Proficiency or 0
    local Profession = GetProfession(self.nProfessionID)
    local nMaxExp = Profession.GetLevelProficiency(tProInfo.Level)
    UIHelper.SetString(self.LabslLevelNum, tProInfo.Level + tProInfo.AdjustLevel .. "级")
    UIHelper.SetString(self.LabelNum, nExp .. '/' .. nMaxExp)
    UIHelper.SetProgressBarPercent(self.BarMiningProgress, 100 * nExp / nMaxExp)

    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)

    local nTotalHeight = UIHelper.GetHeight(self.WidgetAnchortRight)
    local nScrollViewHeight = math.abs(UIHelper.GetPositionY(self.WidgetDistributed) or 0)
    local nDeltaHeight = nTotalHeight - nScrollViewHeight - 30
    UIHelper.SetHeight(self.WidgetDistributed, nDeltaHeight)
    UIHelper.SetHeight(self.ScrollViewDetail, nDeltaHeight)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDetail)

    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function UICollectView:UpdateVigor()
    -- local player = GetClientPlayer()
    -- local nCurrentVigor = player.nVigor + player.nCurrentStamina
	-- local nMaxVigor = player.GetMaxVigor() + player.nMaxStamina
    -- self.VigorScript:SetLableCount(nCurrentVigor..'/'..nMaxVigor)
    -- UIHelper.CascadeDoLayoutDoWidget(self.LayoutAnchorRightTop, true, true)
end

function UICollectView:SetSwitchCallBack(fCallBack)
    self.fSwtichCallBack = fCallBack
end

return UICollectView