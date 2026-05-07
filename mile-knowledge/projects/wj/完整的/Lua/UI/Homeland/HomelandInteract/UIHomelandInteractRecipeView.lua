-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandInteractRecipeView
-- Date: 2023-08-29 16:46:37
-- Desc: ?
-- ---------------------------------------------------------------------------------
local tbDIYFoodItemID = {
	[1] = 34935,
    [2] = 38495,
    [3] = 38496,
    [4] = 38497,
}
local tbFoodFilter = {
	[6] = {
		szCheck    = "CheckBox_HouseKeep",
		DATAMANAGE = 1155,
		ITEMSTART  = 0,
		BYTE_NUM   = 2,
	},
	[7] = {
		szCheck    = "CheckBox_ShopKeeper",
		DATAMANAGE = 1157,
		ITEMSTART  = 0,
		BYTE_NUM   = 1,
	},
}
local nMaxMakeNum = {
    [3] = 20,
    [11] = 1
}

--确定主功能按钮
local nMainBtnIndex = {
    [3] = 1,
    [11] = 1
}

local tbFilterInfo = {}
    tbFilterInfo.Def = FilterDef.TransactionBag
    tbFilterInfo.tbfuncFilter = {{
        function(_) return true end,
        function(item) return item.nGenre == ITEM_GENRE.TASK_ITEM end, --任务
        function(item) return item.nGenre == ITEM_GENRE.EQUIPMENT end, --装备
        function(item) return item.nGenre == ITEM_GENRE.POTION or item.nGenre == ITEM_GENRE.FOOD end, --药品
        function(item) return item.nGenre == ITEM_GENRE.MATERIAL end, --材料
        function(item) return item.nGenre == ITEM_GENRE.BOOK end, --书籍
        function(item) return item.nGenre == ITEM_GENRE.HOMELAND end, --家具
        function(item) return not item.bBind end, --非绑定
        function(item) return ItemData.GetItemInfo(item.dwTabType, item.dwIndex).nExistType ~= ITEM_EXIST_TYPE.PERMANENT end, --限时
    }}

-- local nBuffLimitID = 17378

local UIHomelandInteractRecipeView = class("UIHomelandInteractRecipeView")
function UIHomelandInteractRecipeView:OnEnter(tData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.nImgSize = UIHelper.GetWidth(self.ImgSliderNum)
    end
    self:DataInit(tData)
    HomelandMiniGameData.OnInit()
    HomelandMiniGameData.tData = HomelandMiniGameData.ParseMinGameData(tData)
	assert(HomelandMiniGameData.tData, "UIHomelandInteractCommonView tData == nil")

    self.nToAwardItemIndex = 0
    self.tData = clone(HomelandMiniGameData.tData)
    -- self:PlayMakeEff()
    self:UpdateInfo()
end

function UIHomelandInteractRecipeView:OnExit()
    self.bInit = false
    HomelandMiniGameData.Reset()
end

function UIHomelandInteractRecipeView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(VIEW_ID.PanelLeftBag)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnRevert, EventType.OnClick, function ()
        self:InitDiyRecipeMeterialTable()
        local tCurRecipe = clone(self.tbDiyRecipeMeterial)

        self.scriptCurRecipe.tbInfo = tCurRecipe
        self:UpdateRightInfo()
        if self.scriptLeftBag then
            self.scriptLeftBag:OnInitWithBox(self:GetBagMaterial(), tbFilterInfo)
        end
    end)

    UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function ()
        local nCount = tonumber(UIHelper.GetString(self.LabelManufactureNum))
        if nCount < nMaxMakeNum[self.nGameID] then
            nCount = nCount + 1
        end
        UIHelper.SetString(self.LabelManufactureNum, nCount)
        UIHelper.SetProgressBarPercent(self.SliderNum, nCount / nMaxMakeNum[self.nGameID] * 100)
    end)

    UIHelper.BindUIEvent(self.BtnMinus, EventType.OnClick, function ()
        local nCount = tonumber(UIHelper.GetString(self.LabelManufactureNum))
        if nCount > 0 then
            nCount = nCount - 1
        end
        UIHelper.SetString(self.LabelManufactureNum, nCount)
        UIHelper.SetProgressBarPercent(self.SliderNum, nCount / nMaxMakeNum[self.nGameID] * 100)
    end)

    UIHelper.BindUIEvent(self.BtnRule, EventType.OnClick, function ()
        local szTip = UIHelper.GBKToUTF8(self.tData.szTip)
        szTip = string.gsub(szTip, "配方指引.*$", "")
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnRule, TipsLayoutDir.BOTTOM_RIGHT, szTip)
    end)

    UIHelper.BindUIEvent(self.BtnWater, EventType.OnClick, function ()
        local player = GetClientPlayer()
        if self.nGameID == 11 then
            if player.GetItemAmountInAllPackages(ITEM_TABLE_TYPE.OTHER, 35560) == 0 then
                OutputMessage("MSG_ANNOUNCE_NORMAL", "获取成功")
            end
            HomelandMiniGameData.GameProtocol(self.tData.aBtns[1].nID, 0)
            UIMgr.Close(self)
        end
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function ()
        local function DiyModToAwardItemCheck()
            local bIsAwardItem = false
            for _, nTabIndex in ipairs(tbDIYFoodItemID) do
                if self.nToAwardItemIndex == nTabIndex then
                    bIsAwardItem = true
                end
            end
            return bIsAwardItem and self.bDIYRecipeMode
        end

        if not HomelandMiniGameData.CheckCanOpenFrame(self.tData.tPosInfo) then
            UIMgr.Close(self)
            UIMgr.Close(VIEW_ID.PanelLeftBag)
            TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_DISTANCE)
            return
        end

        if self.nGameState == 2 then
            TipsHelper.ShowNormalTip(self:GetWaringTips())
            return
        elseif self.nGameState == 1 and self.scriptCurRecipe  and self.scriptCurRecipe.nTabIndex ~= self.nToAwardItemIndex then
            if not table.contain_value(tbDIYFoodItemID, self.scriptCurRecipe.nTabIndex) or not table.contain_value(tbDIYFoodItemID, self.nToAwardItemIndex) then
                TipsHelper.ShowNormalTip(self:GetWaringTips())
                return
            end
        end --烹饪中或未领取对应产物时返回

        if self.nGameState == 1 then
            if self.scriptCurRecipe.nTabIndex == self.nToAwardItemIndex or DiyModToAwardItemCheck() then
                HomelandMiniGameData.GameProtocol(self.tData.aBtns[nMainBtnIndex[self.nGameID]].nID, 0)
                UIMgr.Close(VIEW_ID.PanelLeftBag)
                Timer.Add(self, 0.1, function ()
                    self:PlayMakeEff()
                    Homeland_SendMessage(HOMELAND_BUILD_OP.GET_INTERACTION_OBJECT_INFO, self.tData.nLandIndex, self.tData.nFurnitureInstanceID, self.tData.nFurnitureInstanceID)
                end)
                return
            end
        else
            local bSure = self:ConfirmManufacture()
            if bSure then
                HomelandMiniGameData.GameProtocol(self.tData.aBtns[nMainBtnIndex[self.nGameID]].nID, 0)
                if self.nGameID == 11 then
                    UIMgr.Close(self)   -- 酿酒成功直接退出
                    UIMgr.Close(VIEW_ID.PanelLeftBag)
                else
                    UIMgr.Close(VIEW_ID.PanelLeftBag)
                    Timer.Add(self, 0.1, function ()
                        self:PlayMakeEff()
                        Homeland_SendMessage(HOMELAND_BUILD_OP.GET_INTERACTION_OBJECT_INFO, self.tData.nLandIndex, self.tData.nFurnitureInstanceID, self.tData.nFurnitureInstanceID)
                    end)
                end
            end
        end
    end)

    UIHelper.BindUIEvent(self.SliderNum, EventType.OnChangeSliderPercent, function(slider, event)
        local nProgressBarPercent = UIHelper.GetProgressBarPercent(self.SliderNum)
        UIHelper.SetWidth(self.ImgSliderNum, nProgressBarPercent * self.nImgSize / 100 )
        local nMakeNum = math.floor(nProgressBarPercent * nMaxMakeNum[self.nGameID] / 100)
        self.nManufactureCount = nMakeNum
        if self.scriptCurRecipe then
            self:UpdateRightInfo()
        end
    end)

    UIHelper.BindUIEvent(self.BtnMax, EventType.OnClick, function()
        local nCount = nMaxMakeNum[self.nGameID]
        UIHelper.SetString(self.LabelManufactureNum, nCount)
        UIHelper.SetProgressBarPercent(self.SliderNum, nCount / nMaxMakeNum[self.nGameID] * 100)
    end)
end

function UIHomelandInteractRecipeView:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        Event.Dispatch(EventType.OnClearUICommonItemSelect)
        if self.scriptItemTips then
            UIHelper.RemoveFromParent(self.scriptItemTips._rootNode)
            self.scriptItemTips = nil
            TipsHelper.DeleteAllHoverTips(true)
        end
        self.scriptMainIcon:SetSelected(false)
    end)

    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        self.scriptLeftBag = nil
        UIMgr.Close(VIEW_ID.PanelLeftBag)
    end)

    Event.Reg(self, EventType.OnGuideItemSource, function()
        self.scriptLeftBag = nil
        UIMgr.Close(VIEW_ID.PanelLeftBag)
        -- UIMgr.Close(self)
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelLeftBag then
            self.scriptLeftBag = nil
            UIHelper.SetVisible(self.ScrollViewEquipment, true)
        else
            self:UpdateRightInfo()
        end
    end)

    Event.Reg(self, EventType.EmailBagItemSelected, function(nBox,nIndex,nCurCount)
        local bReplace = false
        local function ItemListCheck(item)
            for _, tbInfo in ipairs(self.tbDiyRecipeMeterial) do
                if item.dwIndex == tbInfo[1] then
                    return true
                end
            end
            return false
        end
        local item = ItemData.GetItemByPos(nBox, nIndex)
        local tCurRecipe = clone(self.tbDiyRecipeMeterial)
        if not tCurRecipe or not item then
            return
        end

        if ItemListCheck(item) then
            bReplace = true
        end
        for index, tbInfo in ipairs (tCurRecipe) do
            if tbInfo[2] == 0 then
                tCurRecipe[index] = nil
            end
        end

        if bReplace then
            for index, tInfo in ipairs(tCurRecipe) do
                if tInfo[1] == item.dwIndex then
                    tCurRecipe[index] = {[1] = item.dwIndex, [2] = nCurCount}
                end
            end
        else
            table.insert(tCurRecipe, {[1] = item.dwIndex, [2] = nCurCount})
        end

        for index = 1, 4 do --补全空位
            tCurRecipe[index] = tCurRecipe[index] or {}
            if table_is_empty(tCurRecipe[index]) then
                tCurRecipe[index] = { [1] = 0, [2] = 0 }
            end
        end

        self.scriptCurRecipe.tbInfo = tCurRecipe
        self.tbDiyRecipeMeterial = tCurRecipe
        self:UpdateRightInfo()
        self.scriptLeftBag:OnInitWithBox(self:GetBagMaterial(), tbFilterInfo)
        TipsHelper.DeleteAllHoverTips(true)
        UIHelper.SetToggleGroupSelected(self.ToggleGroupDiyMaterialAddTog, 0)
    end)
end

function UIHomelandInteractRecipeView:UpdateInfo()
    self:UpdateGameStateInfo()
    self:UpdateLeftInfo()               --左侧菜谱
    self:UpdateSliderWithMakeNum()        --滑动条
    self:UpdateRightInfo()              --制作面板
end

function UIHomelandInteractRecipeView:DataInit(tData)
    self:InitDiyRecipeMeterialTable()
    self:InitOrderInfo()
    if tData.nGameID == 11 then
        self.tRecipe = HomelandEventHandler.GetAlcoholRecipe()
    elseif tData.nGameID == 3 then
        self.tRecipe = HomelandEventHandler.GettRecipes()
    end
    self.nGameID = tData.nGameID
    self.nGameState = tData.nGameState
end

function UIHomelandInteractRecipeView:InitDiyRecipeMeterialTable()
    self.tbDiyRecipeMeterial = {
        [1] = { [1] = 0, [2] = 0 },
        [2] = { [1] = 0, [2] = 0 },
        [3] = { [1] = 0, [2] = 0 },
        [4] = { [1] = 0, [2] = 0 },
    }
end

local function ParseItem(tbInfo)
    tbInfo.tItemList = {}
    local tRes = {}
    local tItemList = SplitString(tbInfo.szProduct, ';')
    for _, v in pairs(tItemList) do
        local tItem = SplitString(v, '_')
        tbInfo.tItemList = {dwTabType = tonumber(tItem[1]), dwIndex = tonumber(tItem[2]), nCount = tonumber(tItem[3])}
    end
end

local function GetHouseBagNum(nItemID)
    local nClassBagNum = 0
    for nClassType, tFilter in pairs(tbFoodFilter) do
        local tHomeLandClassBag = Table_GetHomelandLockerInfoByClass(nClassType)
        for _, v in pairs(tHomeLandClassBag) do
            if v and v.dwItemID == nItemID then
                nClassBagNum = GetClientPlayer().GetRemoteArrayUInt(tFilter.DATAMANAGE, tFilter.ITEMSTART + (v.dwDataIndex - 1) * tFilter.BYTE_NUM, tFilter.BYTE_NUM)
                return nClassBagNum
            end
        end
    end
    return nClassBagNum
end

function UIHomelandInteractRecipeView:InitOrderInfo()
    local tOrderData = GDAPI_GetHLCookOrder() or {}
    local tOrderInfo = Table_GetHLOrderByType(HLORDER_TYPE.COOK)
    for _, v in pairs(tOrderInfo) do
        ParseItem(v)
    end

    local tbOrderFood = {}
    for _, tbData in ipairs(tOrderData) do
        local dwID = tbData.dwID
        if not tbData.bFinish and dwID and dwID > 0 and tOrderInfo[dwID] then
            local dwIndex = tOrderInfo[dwID].tItemList.dwIndex
            if tbOrderFood[dwIndex] and tbOrderFood[dwIndex] > 0 then
                tbOrderFood[dwIndex] = tbOrderFood[dwIndex] + tOrderInfo[dwID].tItemList.nCount
            else
                tbOrderFood[dwIndex] = tOrderInfo[dwID].tItemList.nCount
            end
        end
    end
    self.tbOrderFood = tbOrderFood
end

function UIHomelandInteractRecipeView:UpdateGameStateInfo()
    local szTitle = UIHelper.GBKToUTF8(self.tData.szTitle)
    local szInfo = string.pure_text(UIHelper.GBKToUTF8(self.tData.tModule1.szInfo))
    szInfo = self:ParseGetTipDesc(szInfo)

    if self.nCountdownTimerID then
        Timer.DelTimer(self, self.nCountdownTimerID)
        self.nCountdownTimerID = nil
    end

    UIHelper.SetString(self.LabelNeedTime, szInfo)
    UIHelper.SetString(self.LabelTitle, szTitle)
    UIHelper.SetVisible(self.ImgCookBg, false)
    UIHelper.SetVisible(self.ImgBrewageBg, false)
    UIHelper.SetVisible(self.LabelLiquorTimeNow, false)
    UIHelper.SetVisible(self.BtnWater, false)
    local szBtnName = ""

    if self.tData.tModule1Item then
        self.nToAwardItemIndex = self.tData.tModule1Item.dwIndex
    end

    if self.nGameID == 3 then   --烹饪相关界面设置
        szBtnName = self.tData.aBtns[1].szName
        UIHelper.SetVisible(self.ImgCookBg, true)
        if self.nGameState == 0 then
            szBtnName = UIHelper.GBKToUTF8(szBtnName)
            UIHelper.SetString(self.LabelConfirm, szBtnName)
            UIHelper.SetVisible(self.WidgetTime, false)
        elseif self.nGameState == 1 then
            self.nToAwardItemNum = self:GetMakeNumWithGetTips(szInfo)
            szBtnName = UIHelper.GBKToUTF8(szBtnName)
            UIHelper.SetString(self.LabelConfirm, szBtnName)
            UIHelper.SetVisible(self.WidgetTime, false)
            UIHelper.SetVisible(self.WidgetQuantity, false)
            UIHelper.SetVisible(self.LabelGetTip, false)
        elseif self.nGameState == 2 then
            self.nToAwardItemNum = self:GetMakeNumWithGetTips(szInfo)
            UIHelper.SetString(self.LabelConfirm, "烹饪需1分钟")
            UIHelper.SetVisible(self.WidgetTime, false)
            UIHelper.SetVisible(self.WidgetQuantity, false)
            UIHelper.SetNodeGray(self.BtnConfirm, true, true)
        end
    elseif self.nGameID == 11 then  --酿酒相关界面设置
        szBtnName = self.tData.aBtns[1].szName
        UIHelper.SetVisible(self.WidgetTime, false)
        UIHelper.SetVisible(self.ImgBrewageBg, true)
        UIHelper.SetVisible(self.WidgetController, false)
        if self.nGameState == 0 then
            szBtnName = UIHelper.GBKToUTF8(szBtnName)
            UIHelper.SetString(self.LabelConfirm, szBtnName)
        elseif self.nGameState == 1 then
            szBtnName = UIHelper.GBKToUTF8(szBtnName)
            local nTime = self.tData.tModule1.nTime
            local szTxt = ""
            local fnCountdown = function()
                local nCurrTime = GetCurrentTime()
                local nDiffTime = 0
                nDiffTime = nCurrTime - nTime
                if nDiffTime < 0 then
                    nDiffTime = 0
                end
                szTxt = self:GetCDTimeText(nDiffTime)
                UIHelper.SetString(self.LabelLiquorTimeNow, "已酿造时间"..szTxt)
            end

            self.nCountdownTimerID = Timer.AddCycle(self, 0.5, function ()
                fnCountdown()
            end)
            fnCountdown()
            UIHelper.SetVisible(self.LabelLiquorTime, true)
            UIHelper.SetVisible(self.LabelLiquorTimeNow, true)
            UIHelper.SetVisible(self.WidgetTime, false)
            UIHelper.SetString(self.LabelLiquorTime, szInfo)
            UIHelper.SetString(self.LabelConfirm, szBtnName)
        end
    end
end

function UIHomelandInteractRecipeView:UpdateLeftInfo()
    local bFirstCell = true
    local nToAwardTogIndex = 0
    local index = -1

    self.tbDiyAddRecipe = nil
    UIHelper.RemoveAllChildren(self.ScrollViewEquipment)
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupRecipeCell)
    if self.nGameID == 3 then
        self:InitDIYRecipeTog()
        index = index + 1
        UIHelper.SetVisible(self.tbDiyAddRecipe.ImgRedDot, false)
        for _, nFoodItemID in ipairs(tbDIYFoodItemID) do
            if self.nToAwardItemIndex == nFoodItemID then
                self.bDIYRecipeMode = true
                self.scriptCurRecipe = self.tbDiyAddRecipe
                UIHelper.SetVisible(self.tbDiyAddRecipe.ImgRedDot, true)
                break
            end
        end
        bFirstCell = false
    end
    for nTabIndex, tbInfo in pairs(self.tRecipe) do
        index = index + 1
        local item = GetItemInfo(ITEM_TABLE_TYPE.OTHER, nTabIndex)
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetHomeRecipeCell, self.ScrollViewEquipment)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupRecipeCell, scriptCell.ToggleHomeRecipeCell)

        scriptCell:OnEnter(item, false, tbInfo, self.nGameID == 11)
        scriptCell.tbInfo = tbInfo
        scriptCell.nTabIndex = nTabIndex
        scriptCell:SetfuncCallBack(function ()
            self.bDIYRecipeMode = false
            self.scriptCurRecipe = scriptCell
            self:UpdateSliderWithMakeNum()
            self:UpdateRightInfo()
            self.scriptLeftBag = nil
            UIMgr.Close(VIEW_ID.PanelLeftBag)
            UIHelper.SetVisible(self.ScrollViewEquipment, true)
        end)

        if self.nGameState == 1 or self.nGameState == 2 then
            if self.nToAwardItemIndex == nTabIndex  then
                nToAwardTogIndex = index
                self.scriptCurRecipe = scriptCell

                scriptCell:SetRedDotVisible(self.nGameState == 1)-- 待领取
                UIHelper.SetVisible(scriptCell.LabelCook, self.nGameState == 2) -- 制作中
            end
        end

        if self.tbOrderFood[nTabIndex] and self.tbOrderFood[nTabIndex] > 0 then
            UIHelper.SetVisible(scriptCell.WidgteOrders, true)
            UIHelper.SetString(scriptCell.LabelOrders, "订单需求量："..self.tbOrderFood[nTabIndex])
        end

        if bFirstCell and not self.bDIYRecipeMode then
            self.scriptCurRecipe = scriptCell
            self:UpdateSliderWithMakeNum()
            bFirstCell = false
        end
    end
    UIHelper.SetToggleGroupAllowedNoSelection(self.ToggleGroupRecipeCell, false)
    UIHelper.SetToggleGroupSelected(self.ToggleGroupRecipeCell, nToAwardTogIndex)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewEquipment)
end

function UIHomelandInteractRecipeView:UpdateRightInfo()
    UIHelper.RemoveAllChildren(self.WidgeItemIcon)
    UIHelper.RemoveAllChildren(self.ScrollViewConsume)
    self.tbMaterialScript = {}

    local nTabIndex = self.scriptCurRecipe.nTabIndex
    local tbRecipe = self:ParseRecipeTab(self.scriptCurRecipe)
    local item = GetItemInfo(ITEM_TABLE_TYPE.OTHER, nTabIndex)

    self.scriptMainIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgeItemIcon)
    if self.nGameID == 11 then
        -- 酿酒一次制作10份
        self:InitIconFunction(self.scriptMainIcon ,nTabIndex, 10 * self.nManufactureCount)
    else
        self:InitIconFunction(self.scriptMainIcon ,nTabIndex, self.nManufactureCount)
    end

    self:UpdateMaterialCell(tbRecipe)

    UIHelper.SetString(self.LabelTime, "0:01:00")
    UIHelper.SetString(self.LabelManufactureNum, self.nManufactureCount)
    UIHelper.SetString(self.LabelFoodTitle, UIHelper.GBKToUTF8(item.szName))
    if self.bDIYRecipeMode then
        UIHelper.SetString(self.LabelFoodTitle, "创意食品")
        UIHelper.SetVisible(self.WidgetQuantity, false)
        UIHelper.SetVisible(self.LabelManufactureNum, false)
        UIHelper.SetVisible(self.scriptMainIcon.ImgPolishCountBG, false)
    else
        UIHelper.SetVisible(self.LabelManufactureNum, true)
        if self.nGameState == 0 then
            UIHelper.SetVisible(self.WidgetQuantity, true)
        elseif self.nGameState == 1 then
            if self.nToAwardItemIndex == nTabIndex and self.nGameID == 11  then
                UIHelper.SetVisible(self.LabelLiquorTime, true)
            else
                UIHelper.SetVisible(self.LabelLiquorTime, false)
            end
        end
    end
    UIHelper.SetVisible(self.WidgetWineTip, self.nToAwardItemIndex == nTabIndex and self.nGameID == 11 and self.nGameState == 1)
    UIHelper.ScrollToLeft(self.ScrollViewConsume, 0)
    UIHelper.ScrollViewDoLayout(self.ScrollViewConsume)
end

function UIHomelandInteractRecipeView:InitDIYRecipeTog()    --还好只有烹饪有
    local nTabIndex = 34935       --创意食品
    local item = GetItemInfo(ITEM_TABLE_TYPE.OTHER, nTabIndex)
    local tbInfo = self.tbDiyRecipeMeterial   --留空方便判断

    self.tbDiyAddRecipe = UIHelper.AddPrefab(PREFAB_ID.WidgetHomeRecipeCell, self.ScrollViewEquipment)
    self.tbDiyAddRecipe:OnEnter(item, true)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupRecipeCell, self.tbDiyAddRecipe.ToggleHomeRecipeCell)

    self.tbDiyAddRecipe.tbInfo = tbInfo
    self.tbDiyAddRecipe.nTabIndex = nTabIndex
    self.tbDiyAddRecipe:SetfuncCallBack(function ()
        -- self:InitDiyRecipeMeterialTable()
        self.tbDiyAddRecipe.tbInfo = self.tbDiyRecipeMeterial
        self.scriptCurRecipe = self.tbDiyAddRecipe
        self.bDIYRecipeMode = true
        self:UpdateSliderWithMakeNum()
        self:UpdateRightInfo()
    end)
    if self.nGameState == 0 then
        self.scriptCurRecipe = self.tbDiyAddRecipe
        self.bDIYRecipeMode = true
    end
    UIHelper.SetString(self.tbDiyAddRecipe.LabelTittle, "创意食品")
    UIHelper.SetString(self.tbDiyAddRecipe.LabelTittleSelected, "创意食品")
end

function UIHomelandInteractRecipeView:UpdateMaterialCell(tbRecipe)
    local bAllEnough = true --用于判断按钮是否置灰
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupDiyMaterialAddTog)
    local player = GetClientPlayer()
    if self.bDIYRecipeMode then
        bAllEnough = false
        for _, tbInfo in ipairs(tbRecipe) do
            local scriptMeterial = UIHelper.AddPrefab(PREFAB_ID.WidgetItemWithName, self.ScrollViewConsume)
            local nNeedNum = tbInfo[2]
            scriptMeterial.nTabIndex = tbInfo[1]
            if scriptMeterial.nTabIndex > 0 then
                table.insert(self.tbMaterialScript, scriptMeterial)
            end
            if nNeedNum > 0 then
                self:InitIconFunction(scriptMeterial ,tbInfo[1], nNeedNum, true)
                scriptMeterial:SetRecallVisible(true)
                scriptMeterial:RegisterRecallEvent(function ()
                    self:DeleteAddedMateral(tbInfo[1])
                    self.scriptLeftBag:OnInitWithBox(self:GetBagMaterial(), tbFilterInfo)
                end)
                scriptMeterial.nTabIndex = tbInfo[1]
                if self.nGameState == 0 then
                    bAllEnough = true
                end
            else
                scriptMeterial:SetAddBtnVisible(true)
                scriptMeterial:SetLabelItemName("待添加")
                scriptMeterial:SetLableCount("")
                scriptMeterial:RegisterSelectEvent(function (bSelected)
                    self.nSelectedMeterial = 0
                    self:CallLeftBagUp(bSelected)
                end)
                UIHelper.ToggleGroupAddToggle(self.ToggleGroupDiyMaterialAddTog, scriptMeterial.ToggleAddSelect)
                UIHelper.SetVisible(scriptMeterial.ToggleSelect, false)
                UIHelper.SetVisible(scriptMeterial.ImgPolishCountBG, false)
            end
        end
    else
        for _, tbInfo in ipairs(tbRecipe) do
            local scriptMeterial = UIHelper.AddPrefab(PREFAB_ID.WidgetItemWithName, self.ScrollViewConsume)
            local nNeedNum = tbInfo[2] * self.nManufactureCount
            scriptMeterial.nTabIndex = tbInfo[1]
            if scriptMeterial.nTabIndex > 0 then
                table.insert(self.tbMaterialScript, scriptMeterial)
            end
            self:InitIconFunction(scriptMeterial ,tbInfo[1], nNeedNum, true)

            local nPlayerHoldNum = player.GetItemAmountInAllPackages(self.nGameState == 2 or ITEM_TABLE_TYPE.OTHER, tbInfo[1]) + GetHouseBagNum(tbInfo[1])
            if nPlayerHoldNum < nNeedNum or nNeedNum == 0 and not self.bDIYRecipeMode then
                scriptMeterial:SetItemGray(true)
                bAllEnough = false
            elseif self.scriptCurRecipe.nTabIndex ~= self.nToAwardItemIndex and self.nGameState == 1 then
                bAllEnough = false
            else
                scriptMeterial:SetItemGray(false)
            end

            -- if self.nGameID == 11 and self.nGameState == 1 then
            --     scriptMeterial:SetItemGray(true)
            -- end
        end
    end

    if self.bDIYRecipeMode then
        if table_is_empty(self.tbMaterialScript) or self.tbMaterialScript[1].nTabIndex == 0 then
            UIHelper.SetNodeGray(self.BtnConfirm, true, true)
        end
        UIHelper.SetNodeGray(self.BtnConfirm, not bAllEnough, true)
        UIHelper.SetVisible(self.BtnRevert, true)
    else
        UIHelper.SetNodeGray(self.BtnConfirm, not bAllEnough or self.nManufactureCount == 0 or self.nGameState == 2, true)
        UIHelper.SetVisible(self.BtnRevert, false)
    end
    if UIHelper.GetVisible(self.scriptCurRecipe.ImgRedDot) and self.nGameState ~= 2 then
        UIHelper.SetNodeGray(self.BtnConfirm, false, true)
    end
end

function UIHomelandInteractRecipeView:InitIconFunction(scriptCell ,nTabIndex, nStackNum, bMeterial)
    bMeterial = bMeterial or false
    local function InitItemTips(bMeterial)
        UIHelper.RemoveAllChildren(self.WidgetTip)
        if self.bDIYRecipeMode then
            self.scriptMainIcon:SetClickNotSelected(true)
        end
        if bMeterial or not self.bDIYRecipeMode then
            self.scriptItemTips = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetTip)
            local itemInfo = ItemData.GetItemInfo(ITEM_TABLE_TYPE.OTHER, nTabIndex)
            local nAllHadNum = 0
            if itemInfo then
                nAllHadNum = ItemData.GetItemAllStackNum(itemInfo, false)
            end
            local nNeedNum = math.max(1, nStackNum - nAllHadNum)
            self.scriptItemTips:SetShopNeedCount(nNeedNum)

            self.scriptItemTips:SetForbidShowEquipCompareBtn(true)
            self.scriptItemTips:OnInitWithTabID(ITEM_TABLE_TYPE.OTHER, nTabIndex)
            self.scriptItemTips:SetBtnState({})
            self.scriptItemTips:SetForbidAutoShortTip(true)
        end
    end

    scriptCell:OnInitWithTabID(ITEM_TABLE_TYPE.OTHER, nTabIndex, nStackNum)
    if bMeterial then
        scriptCell:RegisterSelectEvent(function (...)
            self.nSelectedMeterial = nTabIndex
            if self.bDIYRecipeMode then
                self:CallLeftBagUp(true)
                return
            end
            InitItemTips(bMeterial)
        end)
    else
        scriptCell:SetClickCallback(function()
            InitItemTips(bMeterial)
        end)
    end
end

function UIHomelandInteractRecipeView:UpdateSliderWithMakeNum()
    self.nManufactureCount = 1
    if self.nToAwardItemIndex and self.scriptCurRecipe then
        if self.scriptCurRecipe.nTabIndex == self.nToAwardItemIndex then
            self.nManufactureCount = self.nToAwardItemNum or 1
        end
    end
    UIHelper.SetString(self.LabelManufactureNum, self.nManufactureCount)
    local nCount = tonumber(UIHelper.GetString(self.LabelManufactureNum))
    UIHelper.SetProgressBarPercent(self.SliderNum, nCount / nMaxMakeNum[self.nGameID] * 100)
end

function UIHomelandInteractRecipeView:ConfirmManufacture()
    local tbAllMaterial = {}
    local player = GetClientPlayer()
    local bAllEnough = true
    local tSlots1 = self.tData.tModule1.tSlot
    local tSlots2 = not table_is_empty(self.tData.tModule2) and self.tData.tModule2[1].tSlots or {}

    for _, scriptMeterial in ipairs(self.tbMaterialScript) do
        local nCostNum = tonumber(UIHelper.GetString(scriptMeterial.LabelCount)) or 1
        if nCostNum <= 0 then
            return
        end

        local item = GetItemInfo(ITEM_TABLE_TYPE.OTHER, scriptMeterial.nTabIndex)
        local nItemID = item.dwID
        if player.GetItemAmountInAllPackages(ITEM_TABLE_TYPE.OTHER, nItemID) + GetHouseBagNum(nItemID) >= nCostNum then
            bAllEnough = true and bAllEnough
        else
            bAllEnough = false and bAllEnough
        end
        table.insert(tbAllMaterial, {dwIndex = scriptMeterial.nTabIndex, dwTabType = ITEM_TABLE_TYPE.OTHER, nStackNum = nCostNum, bIsProduct = true})
    end

    if bAllEnough and self.nGameState == 0 then
        for index, tbItem in ipairs(tbAllMaterial) do
            if index == 1 then
                HomelandMiniGameData.AddItemToSlot(tSlots1, tbItem)
            else
                HomelandMiniGameData.AddItemToSlot(tSlots2[index - 1], tbItem)
            end
        end
    end
    local bSure = HomelandMiniGameData.CheckSlotState(self.tData.aBtns[1].aConditionSlots)
    return bSure
end

function UIHomelandInteractRecipeView:DeleteAddedMateral(nTabIndex)
    local tCurRecipe = clone(self.tbDiyRecipeMeterial)
    local bDeleted = false
    for index = 1, 4 do
        if tCurRecipe[index][1] == nTabIndex then
            tCurRecipe[index] = tCurRecipe[index + 1] or { [1] = 0, [2] = 0 }
            bDeleted = true
        elseif tCurRecipe[index][1] ~= nTabIndex and bDeleted then
            tCurRecipe[index] = tCurRecipe[index + 1] or { [1] = 0, [2] = 0 }
        end
    end
    self.scriptCurRecipe.tbInfo = tCurRecipe
    self.tbDiyRecipeMeterial = tCurRecipe
    self:UpdateRightInfo()
end

function UIHomelandInteractRecipeView:CallLeftBagUp(bSelected)
    if self.nGameState ~= 0 then
        return
    end
    if bSelected then
        local tbItemList = self:GetBagMaterial()
        self.scriptLeftBag = self.scriptLeftBag or UIMgr.Open(VIEW_ID.PanelLeftBag)
        self.scriptLeftBag:OnInitWithBox(tbItemList, tbFilterInfo)
        self.scriptLeftBag:SetClickCallback(function (bSelected, nBox, nIndex)
            if not bSelected then
                return
            end
            local tItem = ItemData.GetItemByPos(nBox, nIndex)
            local nStackNum = ItemData.GetItemStackNum(tItem)
            local function getOneItemAddedNum(nTabIndex)
                for _, tbInfo in ipairs(self.tbDiyRecipeMeterial) do
                    if tbInfo[1] == nTabIndex then
                        return tbInfo[2] or 0
                    end
                end
            end
            self.scriptItemTips = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.scriptLeftBag.WidgetAnchorTips)
            self.scriptItemTips:ShowPlacementBtn(true, nStackNum, getOneItemAddedNum(tItem.dwIndex))
            self.scriptItemTips:OnInit(nBox, nIndex)
        end)

        if self.nSelectedMeterial > 0 then
            for _, scriptCell in ipairs(self.scriptLeftBag.tItemScript) do
                local nItemTabIndex = ItemData.GetItemByPos(scriptCell.nBox, scriptCell.nIndex).dwIndex
                if self.nSelectedMeterial == nItemTabIndex then
                    UIHelper.SetSelected(scriptCell.ToggleSelect, true)
                end
            end
        else
            UIHelper.SetToggleGroupSelected(self.ToggleGroupDiyMaterialAddTog, 0)
        end
        UIHelper.SetVisible(self.ScrollViewEquipment, false)
        self.scriptLeftBag._scriptBG:SetSwallowTouches(false)
    end
end

function UIHomelandInteractRecipeView:ParseRecipeTab(tbRecipe)
    local tCurRecipe = {}
    if self.nGameID == 3 then --统一表tCurRecipe格式
        tCurRecipe = tbRecipe.tbInfo
    elseif self.nGameID == 11 then
        local tbFlag = clone(tbRecipe.tbInfo.tRecipe)
        for index, value in ipairs(tbFlag) do
            tbFlag[index][1] = nil
        end
        for nIndex, value in ipairs(tbFlag) do
            local tValue = {}
            local nNewIndex = 1
            for i, tbInfo in pairs(value) do
                tValue[nNewIndex] = value[i]
                nNewIndex = nNewIndex + 1
            end
            table.insert(tCurRecipe, tValue)
        end
    end
    return tCurRecipe
end

function UIHomelandInteractRecipeView:GetBagMaterial()
    local tbItemList = {}
    local player = GetClientPlayer()
    local tAllMaterial = HomelandEventHandler.GetMaterial()
    for dwIndex, _ in pairs(tAllMaterial) do
        local bAdded = false
        local nBox, nIndex = ItemData.GetItemPos(ITEM_TABLE_TYPE.OTHER, dwIndex)
        local hItem = ItemData.GetItemByPos(nBox, nIndex)
        if hItem then
            local nSelectedQuantity = 0
            for _, tbInfo in ipairs(self.tbDiyRecipeMeterial) do
                if tbInfo[1] == dwIndex then
                    bAdded = true
                    nSelectedQuantity = tbInfo[2]
                end
            end
            if bAdded then
                table.insert(tbItemList,{nBox = nBox, nIndex = nIndex, nSelectedQuantity = nSelectedQuantity, hItem = hItem})
            else
                table.insert(tbItemList,{nBox = nBox, nIndex = nIndex, nSelectedQuantity = nSelectedQuantity, hItem = hItem})
            end
        end
    end
    return tbItemList
end

function UIHomelandInteractRecipeView:PlayMakeEff()
    UIHelper.SetVisible(self.Eff_Complete, false)
    if self.nGameState == 0 then
        UIHelper.SetVisible(self.Eff_Complete, true)
    end
end

function UIHomelandInteractRecipeView:ParseGetTipDesc(szDesc)
    local szInfo = ""
    szInfo = szDesc
    if self.nGameID == 3 then
        if self.nGameState == 0 then
            szInfo = string.gsub(szInfo, "\n", "")
        elseif self.nGameState == 1 then
            szInfo = string.gsub(szInfo, "\n", "，")
        end
    elseif self.nGameID == 11 then
        if self.nGameState == 0 then
            -- szInfo = string.gsub(szInfo, "\n", "")
        elseif self.nGameState == 1 then
            szInfo = string.gsub(szInfo, "\n", "，")
        end
    end
    return szInfo
end

function UIHomelandInteractRecipeView:GetMakeNumWithGetTips(szGetTips)
    local szNum = string.match(szGetTips, "产量：%s*(%d+)")
    return szNum
end

function UIHomelandInteractRecipeView:GetCDTimeText(nTime)
	local szTxt = ""
	local nH, nM, nS = TimeLib.GetTimeToHourMinuteSecond(nTime)
	local szH = string.format("%02d:", nH)
    local szM = string.format("%02d:", nM)
    local szS = string.format("%02d", nS)
    szTxt = szH .. szM .. szS
	return szTxt
end

function UIHomelandInteractRecipeView:GetWaringTips()
	local szTxt = ""
    if self.nGameID == 3 then
        szTxt = g_tStrings.STR_HOMELAND_COOK_GAIN_WARN
    elseif self.nGameID == 11 then
        szTxt = g_tStrings.STR_HOMELAND_BREA_GAIN_WARN
    end
	return szTxt
end

return UIHomelandInteractRecipeView