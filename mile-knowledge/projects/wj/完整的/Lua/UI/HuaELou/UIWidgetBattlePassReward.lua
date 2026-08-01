-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetBattlePassReward
-- Date: 2022-12-23 10:55:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetBattlePassReward = class("UIWidgetBattlePassReward")
local ROLE_TYPE_INVALID 			= 0
local ROLE_TYPE_STANDARDMALE		= 1
local ROLE_TYPE_STANDARDFEMALE	    = 2
local ROLE_TYPE_STRONGMALE		    = 3
local ROLE_TYPE_SEXYFEMALE		    = 4
local ROLE_TYPE_LITTLEBOY			= 5
local ROLE_TYPE_LITTLEGIRL		    = 6

function UIWidgetBattlePassReward:OnEnter(bTask)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    HuaELouData.Apply()

    if bTask then
        Timer.AddFrame(self, 1, function ()
            self.WidgetQuestView = UIHelper.AddPrefab(PREFAB_ID.WidgetBenefitBPTaskPage, UIHelper.GetParent(self._rootNode))
            self.WidgetQuestView:OnEnter(self._rootNode)
            UIHelper.SetVisible(self._rootNode, false)
        end)
    end

    self.bInitData = true
    self:Init()
    self:InitScrollList()
    self:UpdateInfo()
    self:OnFrameBreathe()
end

function UIWidgetBattlePassReward:OnExit()
    self.bInit = false
    self:UnRegEvent()
    self:UnInitScrollList()
    Timer.DelAllTimer(self)
end

function UIWidgetBattlePassReward:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnGet, EventType.OnClick, function ()
        self:TakeAllAward()
    end)

    UIHelper.BindUIEvent(self.BtnPray, EventType.OnClick, function ()
        UIMgr.OpenSingle(true, VIEW_ID.PanelPrayerPlatform)
    end)

    UIHelper.BindUIEvent(self.PageViewRewardItem, EventType.OnTurningPageView, function ()
        local index = UIHelper.GetPageIndex(self.PageViewRewardItem)+1
        self:AutoFixPageView(index)
    end)

    UIHelper.BindUIEvent(self.BtnUnlock, EventType.OnClick, function ()
        local nDetailViewID = VIEW_ID.PanelBenefitBPRewardDetail

        if g_pClientPlayer.bHideHat then
            --- 如果设置了隐藏帽子，在这里先暂时取消，等界面关闭时再打开
            PlayerData.HideHat(false)


            Event.Reg(self, EventType.OnViewClose, function(nViewID)
                if nViewID == nDetailViewID then
                    Event.UnReg(self, EventType.OnViewClose)

                    PlayerData.HideHat(true)
                end
            end)
        end

        ---@see UIBenefitBPRewardDetailView
        UIMgr.Open(nDetailViewID)
    end)

    for nIndex,toggle in ipairs(self.tFinalRewardPoints) do
        UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function (_, bSelected)
            if bSelected then
                UIHelper.ScrollToPage(self.PageViewRewardItem, nIndex-1, 0.25)
            end
        end)
    end
end

function UIWidgetBattlePassReward:RegEvent()
    Event.Reg(self, "REMOTE_BATTLEPASS", function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_SYNC_SET_COLLECTION", function ()
        HuaELouData.UpdateExp()
        self:UpdateInfo()
    end)

    Event.Reg(self, "UPDATE_WISH_ITEM", function()
        self:UpdateWishItemInfo()
    end)

    Event.Reg(self, EventType.OnEnterBattlePassQuestPanel, function ()
        if self.WidgetQuestView then
            UIHelper.SetVisible(self.WidgetQuestView._rootNode, true)
            UIHelper.SetSelected(self.WidgetQuestView.TogActivityType, false)
        else
            self.WidgetQuestView = UIHelper.AddPrefab(PREFAB_ID.WidgetBenefitBPTaskPage, UIHelper.GetParent(self._rootNode))
            self.WidgetQuestView:OnEnter(self._rootNode)
        end
        UIHelper.SetVisible(self._rootNode, false)
    end)

    Event.Reg(self, EventType.OnExitBattlePassQuestPanel, function ()
        if not self.bInitData then
            self.bInitData = true
            self:Init()
            self:UpdateInfo()
            self:OnFrameBreathe()
        end

    end)

    Event.Reg(self, EventType.OnSelectLeaveForBtn, function (tbInfo)
        HuaELouData.Teleport(tbInfo.nLinkID, tbInfo.dwMapID)
    end)
end

function UIWidgetBattlePassReward:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetBattlePassReward:Init()
    self.nFinalRewardIndex = 1
    UIHelper.SetPageIndex(self.PageViewRewardItem, 0)
    HuaELouData.UpdateExp()

    if HuaELouData.PASS_USE_RMB then
        UIHelper.SetVisible(self.ImgUnlockCoin, false)
        UIHelper.SetString(self.LabelUnlockCoin, "188元")
        UIHelper.LayoutDoLayout(UIHelper.GetParent(self.LabelUnlockCoin))
    end
end

function UIWidgetBattlePassReward:UpdateInfo()
    self.nMaxVisableLevel = nil
    self:UpdateWishItemInfo()
    self:UpdateRewardInfo()
    self:UpdateFinalRewardInfo()
    self:TryScrollToNextRewardGroup()
end

function UIWidgetBattlePassReward:OnFrameBreathe()
    -- 自动监听翻页变化
    local nPageIndex = UIHelper.GetPageIndex(self.PageViewRewardItem)
    if self.nPageIndex and self.nPageIndex ~= nPageIndex then
        self:AutoFixPageView(nPageIndex + 1)
    end
    self.nPageIndex = nPageIndex

    self:OnScrollViewTouchMoved()
    Timer.AddFrame(self, 1, function ()
        self:OnFrameBreathe()
    end)
end

function UIWidgetBattlePassReward:UpdateWishItemInfo()
    local tInfo = GDAPI_GetSpecialWishInfo()
    DungeonData.tWishInfo = tInfo
    
    local nPercent = tInfo.nWishCoin/tInfo.nMaxWishCoinLimit
    local szText = tostring(tInfo.nWishCoin)
    if tInfo.nWishIndex ~= 0 then
        nPercent = (DungeonData.MAX_WISH_ITEM_RETRY_COUNT - tInfo.nRemainTryCount) / DungeonData.MAX_WISH_ITEM_RETRY_COUNT
        szText = string.format("%d次内必出", tInfo.nRemainTryCount)
    end
    UIHelper.SetProgressBarPercent(self.ImgSliderWishCoin, nPercent * 100)
    UIHelper.SetString(self.LabelWishCoin, szText)
    UIHelper.SetVisible(self.ImgPrayRedDot, tInfo.nWishIndex == 0 and tInfo.nWishCoin == tInfo.nMaxWishCoinLimit)
    UIHelper.SetVisible(self.ImgPrayUp, tInfo.nWishIndex ~= 0 and tInfo.nRemainTryCount == 1)
    UIHelper.SetVisible(self.WidgetPrayEff, DungeonData.CanWishItemFlash())
end

function UIWidgetBattlePassReward:UpdateRewardInfo()
    -- 更新各等级奖励
    self.tScrollList:Reset(#HuaELouData.tRewardList + 1)
    -- 更新按钮
    -- UIHelper.SetVisible(self.BtnUnlock, not HuaELouData.IsGrandRewardUnlock())
    if HuaELouData.IsGrandRewardUnlock() and HuaELouData.IsExtralUnlock() then
        -- UIHelper.RemoveFromParent(self.BtnUnlock, true)
        UIHelper.SetVisible(self.BtnUnlock, false)
    end
    UIHelper.LayoutDoLayout(self.LayoutRightButtons)
end

function UIWidgetBattlePassReward:OnScrollViewTouchMoved()
    local nMaxVisableLevel = self.tScrollList:GetMaxVisableCellIndex() - 1
    nMaxVisableLevel = HuaELouData.GetTargetNearLevel(nMaxVisableLevel)
    if self.nMaxVisableLevel and self.nMaxVisableLevel == nMaxVisableLevel then
        return
    end
    self.nMaxVisableLevel = nMaxVisableLevel
    local scriptNearReward = UIHelper.GetBindScript(self.WidgetAnchorReward)
    local nNearLevel = nMaxVisableLevel
    local tReward = HuaELouData.tRewardList[nMaxVisableLevel]
    if scriptNearReward and tReward then
        scriptNearReward:OnEnter(nNearLevel, tReward)
    end
end

function UIWidgetBattlePassReward:TryScrollToNextRewardGroup()
    local bHasAward = false
    local nStartLevel = HuaELouData.GetLevel() -- 默认定位到玩家当前等级
    for nLevel = 0, HuaELouData.GetLevel() do
        local tReward = HuaELouData.tRewardList[nLevel]
        local bToAward = false
        local tGrandRewardDetail = HuaELouData.GetRewardDetatil(tReward.dwSetID)
        if tGrandRewardDetail and tGrandRewardDetail.AwardItem and #tGrandRewardDetail.AwardItem > 0 then
            local eSetState, _ = HuaELouData.GetCollectionState(tReward.dwSetID)
            bToAward = bToAward or eSetState == SET_COLLECTION_STATE_TYPE.TO_AWARD
        end
        tGrandRewardDetail = HuaELouData.GetRewardDetatil(tReward.dwSetID2)
        if HuaELouData.IsGrandRewardUnlock() and tGrandRewardDetail and tGrandRewardDetail.AwardItem and #tGrandRewardDetail.AwardItem > 0 then
            local eSetState, _ = HuaELouData.GetCollectionState(tReward.dwSetID2)
            bToAward = bToAward or eSetState == SET_COLLECTION_STATE_TYPE.TO_AWARD
        end

        if bToAward then    -- 定位到第一个有奖励的栏位
            nStartLevel = nLevel
            bHasAward = true
            break
        end
    end
    self.tScrollList:ScrollToIndex(nStartLevel + 1)
    if bHasAward then
        UIHelper.SetButtonState(self.BtnGet, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnGet, BTN_STATE.Disable, "暂无任何可领取奖励")
    end
end

function UIWidgetBattlePassReward:AutoFixPageView(index)
    for nIndex, togglePoint in ipairs(self.tFinalRewardPoints) do
        local bSelected = nIndex == index
        if bSelected then
            self.nFinalRewardIndex = nIndex
            self:UpdateFinalRewardPage()
        end
        UIHelper.SetSelected(togglePoint, bSelected)
    end
end

local function GetRewardPath(tInfo)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return tInfo.szRewardPicPath
    end
    local nRoleType = hPlayer.nRoleType

    if tInfo.szMalePicPath ~= "" and nRoleType == ROLE_TYPE_STANDARDMALE or nRoleType == ROLE_TYPE_STRONGMALE then
        return tInfo.szMalePicPath
    elseif tInfo.szFemalePicPath ~= "" and nRoleType == ROLE_TYPE_STANDARDFEMALE or nRoleType == ROLE_TYPE_SEXYFEMALE then
        return tInfo.szFemalePicPath
    elseif tInfo.szBoyPicPath ~= "" and nRoleType == ROLE_TYPE_LITTLEBOY then
        return tInfo.szBoyPicPath
    elseif tInfo.szGirlPicPath ~= "" and nRoleType == ROLE_TYPE_LITTLEGIRL then
        return tInfo.szGirlPicPath
    else
        return tInfo.szRewardPicPath
    end
end

function UIWidgetBattlePassReward:UpdateFinalRewardInfo()
    UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupRewardItem)
    local nFinalRewardCount = #HuaELouData.tValuableReward
    for nIndex, togglePoint in ipairs(self.tFinalRewardPoints) do
        local bVisable = nIndex<=nFinalRewardCount
        UIHelper.SetVisible(togglePoint, bVisable)
        if bVisable then
            UIHelper.ToggleGroupAddToggle(self.TogGroupRewardItem, togglePoint)
        end
    end

    local nChildCount = UIHelper.GetChildrenCount(self.PageViewRewardItem) or 0
    for nIndex = 1, nChildCount do
        UIHelper.RemovePageAtIndex(self.PageViewRewardItem, 0)
    end
    for nIndex, nLevel in ipairs(HuaELouData.tValuableReward) do
        local tReward = HuaELouData.tRewardList[nLevel]
        local szImagePath = GetRewardPath(tReward)
        szImagePath = string.gsub(szImagePath, "/ui/Image/Active/ActivityFistPage/", "Resource/")
        szImagePath = string.gsub(szImagePath, ".tga", ".png")

        local eSetState, _ = HuaELouData.GetCollectionState(tReward.dwSetID2)
        if not eSetState then eSetState = SET_COLLECTION_STATE_TYPE.UNCOLLECTED end

        UIHelper.PageViewAddPage(self.PageViewRewardItem, PREFAB_ID.WidgetFinalRewardPicture, szImagePath, eSetState)
    end

    UIHelper.SetVisible(self.ImgLock, not HuaELouData.IsGrandRewardUnlock())
    self:UpdateFinalRewardPage()
end

function UIWidgetBattlePassReward:UpdateFinalRewardPage()
    local nLevel = HuaELouData.tValuableReward[self.nFinalRewardIndex]
    local tReward = HuaELouData.tRewardList[nLevel]
    if tReward and tReward.dwSetID2 then
        local tNormalRewardDetail
        local tAwardItem
        if tReward.dwSetID2 > 0 then
            tNormalRewardDetail = HuaELouData.GetRewardDetatil(tReward.dwSetID2)
            tAwardItem = tNormalRewardDetail.AwardItem[1]
            if #tNormalRewardDetail.AwardItem >= 2 then tAwardItem = tNormalRewardDetail.AwardItem[2] end
        else
            tAwardItem = {
                dwItemType = 5,
                dwItemID = 86132
            }
        end
        local itemInfo = ItemData.GetItemInfo(tAwardItem.dwItemType, tAwardItem.dwItemID)
        local szItemName = "【配置错误】"
        if itemInfo then
            local nBookInfo
            if itemInfo.nGenre == ITEM_GENRE.BOOK then
                nBookInfo = itemInfo.nDurability
            end
            szItemName = ItemData.GetItemNameByItemInfo(itemInfo, nBookInfo)
            szItemName = UIHelper.GBKToUTF8(szItemName)
        end
        szItemName = string.gsub(szItemName, "【", "︻")
        szItemName = string.gsub(szItemName, "】", "︼")
        local szDesc = UIHelper.GBKToUTF8(tReward.szDesc)
        UIHelper.SetString(self.LabelFinalRewardTitle, szItemName)
        UIHelper.SetString(self.LabelFinalRewardLevel, szDesc)
        UIHelper.SetSpriteFrame(self.ImgTitleBg, tReward.szShortDescPicPath)
    end
end

function UIWidgetBattlePassReward:TakeAllAward()
    local player = GetClientPlayer()
    if not player then
        return
    end
    local bHasAward = false
    for nLevel = 0, HuaELouData.GetLevel() do
        local tReward = HuaELouData.tRewardList[nLevel]
        if tReward then
            local eSetState, _ = HuaELouData.GetCollectionState(tReward.dwSetID)
            if tReward.dwSetID and eSetState == SET_COLLECTION_STATE_TYPE.TO_AWARD then
                player.ApplySetCollectionAward(tReward.dwSetID)
                bHasAward = true
            end
            eSetState, _ = HuaELouData.GetCollectionState(tReward.dwSetID2)
            if tReward.dwSetID2 and eSetState == SET_COLLECTION_STATE_TYPE.TO_AWARD and HuaELouData.IsGrandRewardUnlock() then
                player.ApplySetCollectionAward(tReward.dwSetID2)
                bHasAward = true
            end
        end
    end
    if not bHasAward then
        TipsHelper.ShowNormalTip("当前没有任何奖励可以领取")
    end
end

function UIWidgetBattlePassReward:InitScrollList()
	self:UnInitScrollList()
	self.tScrollList = UIScrollList.Create({
		nSpace = 4,
		listNode = self.LayoutContentGradeReward,
        bHorizontal = true,
        bMinPosAlign = true,
		fnGetCellType = function(nIndex)
            if nIndex == 1 then return PREFAB_ID.WidgetBattlePassGradeRewardLarge end
            return PREFAB_ID.WidgetBattlePassGradeReward
        end,
		fnUpdateCell = function(scriptCell, nIndex)
            local nLevel = nIndex - 1
            local tReward = HuaELouData.tRewardList[nLevel]
			scriptCell:OnEnter(nLevel, tReward)
		end,
	})
end

function UIWidgetBattlePassReward:UnInitScrollList()
	if self.tScrollList then
		self.tScrollList:Destroy()
		self.tScrollList = nil
	end
end

return UIWidgetBattlePassReward