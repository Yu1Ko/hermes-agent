-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandInteractCommonView
-- Date: 2023-08-02 15:36:22
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandInteractCommonView = class("UIHomelandInteractCommonView")

local _BTN_COST_TYPE =
{
	--NO_COST = 0,
	FOR_COST = 1,               -- 定价按钮
	SHOW_COST_TIP_FIRST = 2,    -- 点击后需要先提示付费使用
	FOR_PASSWORD = 3,	        --设置密码
	SHOW_PW_TIP = 4,            --解密，传送使用
}

local _BTN_TYPE =
{
    PLANT_CARE = 5,             -- 照料
    RESET = 14,                 -- 重置
    CANG_JIU = 16,              -- 藏酒
    CHANGE_FOOD_MONEY = 30,     -- 餐盘修改价格
    ADD_FOOD = 31,              -- 餐盘加菜
    GET_FOOD_MONEY = 34,        -- 餐盘取货款
    GET_FISH = 44,              -- 养鱼-垂钓
    COLOR_SHOW = 48,            -- 土地种植-颜色参考
    CABINET = 49,               -- 收藏柜
}

local ADD_QUICK_BTN_TYPE =  -- 需要添加一键操作全部的按钮在这里，如：一键种植
{
    PLANTTING = 4,              -- 播种
    PLANT_CARE = 5,             -- 照料
    PLANT_GAIN = 6,             -- 收获
    CANG_JIU = 16,              -- 藏酒
    PLANTTING_SOIL = 27,        -- 播种(土壤用)
}

local GameID2RuleID = {
    --藏酒
    [7] = 31,
    --宠物窝
    [1] = 32,
    [5] = 32,
    --啮齿
    [6] = 33,
    --禽鸟
    [4] = 34,
    --餐盘
    [12] = 35,
    --家园种植
    [2] = 36,
    [13] = 36,
    -- --武器架
    -- [20] = 38,
    -- 传送锁
    [17] = 38,
}

function UIHomelandInteractCommonView:OnEnter(tData)
    self.tData = tData

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.scriptLeftBag = UIHelper.GetBindScript(self.WidgetAniLeft)
    end

    if tData.nGameID == 20 then
        HomelandWeaponDisplayData.Init(tData)
        self:UpdateWeaponDisplayInfo()
        return
    end

    HomelandMiniGameData.OnInit()

    HomelandMiniGameData.tData = HomelandMiniGameData.ParseMinGameData(tData)
	assert(HomelandMiniGameData.tData, "UIHomelandInteractCommonView tData == nil")
    self.bUseHistory = true
    self:UpdateInfo()
    self.bUseHistory = nil
end

function UIHomelandInteractCommonView:OnExit()
    self.bInit = false
    HomelandMiniGameData.Reset()
    HomelandWeaponDisplayData.UnInit()
end

function UIHomelandInteractCommonView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        if self.scriptLeftBag:IsShow() then
            self.scriptLeftBag:Hide()
            UIHelper.PlayAni(self, self.AniAll, "AniLeftHide")
            return
        end
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnTips, EventType.OnClick, function(btn)
        if self.tData.nGameID == 2 or self.tData.nGameID == 13 then
            UIMgr.Open(VIEW_ID.PanelHelpPop, GameID2RuleID[self.tData.nGameID])
            return
        end
        TipsHelper.ShowTextTipsWithRuleID(self.BtnTips, TipsLayoutDir.LEFT_CENTER, GameID2RuleID[self.tData.nGameID])
    end)

end

function UIHomelandInteractCommonView:RegEvent()
    Event.Reg(self, EventType.OnUpdateHomelandInteractItemData, function ()
        if self.tData.nGameID == 20 then
            self:UpdateWeaponDisplayInfo()
        else
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.OnSelectedHomelandInteractItemCell, function (nIndex, tbInfo, nModuleID)
        UIHelper.PlayAni(self, self.AniAll, "AniLeftShow")
        self.scriptLeftBag:OnEnter(tbInfo, nModuleID)
    end)

    Event.Reg(self, EventType.OnGuideItemSource, function()
        UIMgr.Close(self)
    end)

    Event.Reg(self, EventType.OnKeyboardDown, function (nKeyCode, szVKName)
        if nKeyCode == cc.KeyCode.KEY_ESCAPE then
            if self.scriptLeftBag:IsShow() then
                self.scriptLeftBag:Hide()
                UIHelper.PlayAni(self, self.AniAll, "AniLeftHide")
            else
                UIMgr.Close(self)
            end
        end
    end)
end

function UIHomelandInteractCommonView:UpdateInfo()
    self:UpdateTitleInfo()
    self:UpdateBtnList()
    self:UpdateModel1Info()
    self:UpdateModel2Info()
    self:UpdateBtnLineInfo()
end

function UIHomelandInteractCommonView:UpdateTitleInfo()
    if HomelandMiniGameData.tData.szTitle then
        UIHelper.SetString(self.LabelTitle, UIHelper.GBKToUTF8(HomelandMiniGameData.tData.szTitle))
    else
        UIHelper.SetString(self.LabelTitle, "")
    end

    if GameID2RuleID[self.tData.nGameID] then
        UIHelper.SetVisible(self.BtnTips, true)
    else
        UIHelper.SetVisible(self.BtnTips, false)
    end

end

function UIHomelandInteractCommonView:UpdateModel1Info()
    local tModule1Item = HomelandMiniGameData.tData.tModule1Item
    if tModule1Item and tModule1Item.dwIndex then
        local tItem = {
            dwIndex = tModule1Item.dwIndex,
            dwTabType = tModule1Item.dwTabType,
            nStackNum = 1,
            bIsProduct = true,
            nAddSlotID = tModule1Item.nAddSlotID,
            nBtnID = tModule1Item.nBtnID,
            nCostType = tModule1Item.nCostType,
        }
        HomelandMiniGameData.AddItemToSlot(HomelandMiniGameData.tData.tModule1.tSlot, tItem)
    end

    self.scriptModel1 = self.scriptModel1 or UIHelper.AddPrefab(PREFAB_ID.WidgetItemNcessary, self.LayoutContent)
    self.scriptModel1:OnEnter(HomelandMiniGameData.tData.tModule1, true)
    if self.scriptModel1.scriptNcessaryItemIcon and self.bUseHistory then
        self.scriptModel1:UpdateHistoryItem(self.scriptModel1.scriptNcessaryItemIcon, 1, HomelandMiniGameData.tData.tModule1.tSlot)
    end
    UIHelper.SetName(self.scriptModel1._rootNode, "WidgetItemNcessary".."1")

    UIHelper.SetVisible(self.LayoutContent, true)
    UIHelper.SetVisible(self.LabelDes, false)

    if HomelandMiniGameData.tData.tModule1 then
        if HomelandMiniGameData.tData.tModule1.nModuleID == 25 then
            UIHelper.SetVisible(self.scriptModel1.WidgetFoodPrice, true)
            self.scriptFoodPrice = self.scriptFoodPrice or UIHelper.AddPrefab(PREFAB_ID.WidgetFoodPrice, self.scriptModel1.WidgetFoodPrice)
            self.scriptFoodPrice:OnEnter()
            UIHelper.CascadeDoLayoutDoWidget(self.scriptModel1._rootNode, true, true)
        elseif HomelandMiniGameData.tData.tModule1.nModuleID == 33 then
            UIHelper.SetVisible(self.LayoutContent, false)
            UIHelper.SetVisible(self.LabelDes, true)

            UIHelper.SetString(self.LabelDes, HomelandMiniGameData.tData.tModule1.szInfo)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutContent)
end

function UIHomelandInteractCommonView:UpdateModel2Info()
    self.tbModel2Cell = self.tbModel2Cell or {}

    local nIndex = 1
    for i, tbInfo in ipairs(HomelandMiniGameData.tData.tModule2) do
        if tbInfo.nModuleID ~= 32 then
            if not self.tbModel2Cell[i] then
                self.tbModel2Cell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetItemNcessary, self.LayoutContent)
            end

            self.tbModel2Cell[i]:OnEnter(tbInfo, false)
            UIHelper.SetName(self.tbModel2Cell[i]._rootNode, "WidgetItemNcessary"..i+1)

            if self.bUseHistory then
                if HomelandMiniGameData.tData.tModule2[i - 1] then
                    nIndex = nIndex + #HomelandMiniGameData.tData.tModule2[i - 1].tSlots -- 重要：写法可能改进
                end
                for k, tSlot in pairs(tbInfo.tSlots or {}) do
                    self.tbModel2Cell[i]:UpdateHistoryItem(self.tbModel2Cell[i].tbSlotCell[k], nIndex + k, tSlot)
                end
            end
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutContent)
end

local fnBtnListSort = function (tbBtns)
    table.sort(tbBtns, function (a,b)
        if b and b.szShortcutKey then
            return true
        end
    end)
end

function UIHomelandInteractCommonView:UpdateBtnList()
    UIHelper.SetVisible(self.BtnSetting, false)
    UIHelper.SetVisible(self.BtnMoney, false)
    UIHelper.SetVisible(self.BtnRefresh, false)
    UIHelper.SetVisible(self.BtnCollect, false)

    if not HomelandMiniGameData.tData.aBtns then
        UIHelper.SetVisible(self.BtnOne, false)
        UIHelper.SetVisible(self.WidgetBtnTwo, false)
		return
	end
	local aBtns = Lib.copyTab(HomelandMiniGameData.tData.aBtns)
	local tDisableBtn = Lib.copyTab(HomelandMiniGameData.tData.tDisableBtn)
    local nBtnCount = #aBtns
    for i = nBtnCount, 1, -1 do
        local tbBtnInfo = aBtns[i]
        -- local szName = UIHelper.GBKToUTF8(tbBtnInfo.szName)
        if table.contain_value(tDisableBtn ,tbBtnInfo.nID) then
            table.remove(aBtns, i)
        elseif tbBtnInfo.nID == _BTN_TYPE.RESET then
            UIHelper.SetVisible(self.BtnRefresh, true)
            self:UpdateBtnInfo(self.BtnRefresh, nil, tbBtnInfo)
            table.remove(aBtns, i)
        elseif tbBtnInfo.nID == _BTN_TYPE.ADD_FOOD then
            local tModule1Item = HomelandMiniGameData.tData.tModule1Item
            if tModule1Item and tModule1Item.dwIndex then
                tModule1Item.nAddSlotID = 41
                tModule1Item.nBtnID = tbBtnInfo.nID
                tModule1Item.nCostType = tbBtnInfo.nCostType
            end
            table.remove(aBtns, i)
        elseif tbBtnInfo.nID == _BTN_TYPE.GET_FOOD_MONEY then
            UIHelper.SetVisible(self.BtnMoney, true)
            self:UpdateBtnInfo(self.BtnMoney, nil, tbBtnInfo)
            table.remove(aBtns, i)
        elseif tbBtnInfo.nID == _BTN_TYPE.CHANGE_FOOD_MONEY or tbBtnInfo.nID == _BTN_TYPE.COLOR_SHOW then
            table.remove(aBtns, i)
        elseif tbBtnInfo.nID == _BTN_TYPE.CABINET then
            UIHelper.SetVisible(self.BtnCollect, true)
            self:UpdateBtnInfo(self.BtnCollect, nil, tbBtnInfo, true)
            table.remove(aBtns, i)
        elseif tbBtnInfo.nID == _BTN_TYPE.PLANT_CARE then
            table.remove(aBtns, i)
        elseif tbBtnInfo.nID == _BTN_TYPE.CANG_JIU then
            UIHelper.SetVisible(self.BtnWine, true)
            self:UpdateBtnInfo(self.BtnWine, nil, aBtns[2], true)
            table.remove(aBtns, 2)
        end
        if table.contain_value(ADD_QUICK_BTN_TYPE, tbBtnInfo.nID) then
            -- 新增一键批量操作
            local tbNewBtn = clone(tbBtnInfo)
            tbNewBtn.szName = UIHelper.UTF8ToGBK("一键"..UIHelper.GBKToUTF8(tbBtnInfo.szName))
            tbNewBtn.bSeedingAll = true
            table.insert(aBtns, 1, tbNewBtn)
        end
    end

    fnBtnListSort(aBtns)
    for i, _ in ipairs(aBtns) do
        if i > 2 then   -- 防止新增按钮导致旧按钮失效
            table.remove(aBtns, i)
        end
    end
    if #aBtns == 1 then
        UIHelper.SetVisible(self.BtnOne, true)
        UIHelper.SetVisible(self.WidgetBtnTwo, false)
        UIHelper.SetVisible(self.WidgetBtnThree, false)

        self:UpdateBtnInfo(self.tbBtns[1], self.tbLabelBtnNames[1], aBtns[1])
    elseif #aBtns == 2 then
        UIHelper.SetVisible(self.BtnOne, false)
        UIHelper.SetVisible(self.WidgetBtnTwo, true)
        UIHelper.SetVisible(self.WidgetBtnThree, false)

        for index, tbInfo in ipairs(aBtns) do
            self:UpdateBtnInfo(self.tbBtns[index + 1], self.tbLabelBtnNames[index + 1], tbInfo)
        end
    elseif #aBtns == 3 then
        UIHelper.SetVisible(self.BtnOne, false)
        UIHelper.SetVisible(self.WidgetBtnTwo, false)
        UIHelper.SetVisible(self.WidgetBtnThree, true)

        for index, tbInfo in ipairs(aBtns) do
            self:UpdateBtnInfo(self.tbBtns[index + 3], self.tbLabelBtnNames[index + 3], tbInfo)
        end
    else
        UIHelper.SetVisible(self.BtnOne, false)
        UIHelper.SetVisible(self.WidgetBtnTwo, false)
        UIHelper.SetVisible(self.WidgetBtnThree, false)
    end
end

function UIHomelandInteractCommonView:UpdateBtnInfo(btn, label, tbInfo, bClickToClose)
    UIHelper.SetString(label, UIHelper.GBKToUTF8(tbInfo.szName))
    UIHelper.BindUIEvent(btn, EventType.OnClick, function ()
        self:OnClickBtnSure(tbInfo)
        if bClickToClose then
            UIMgr.Close(self)
        end
    end)
end

function UIHomelandInteractCommonView:UpdateBtnLineInfo()
    local tbBtnList = UIHelper.GetChildren(self.WidgetTopBtn) or {}
    local bShowLine = false
    for index, btn in ipairs(tbBtnList) do
        if UIHelper.GetVisible(btn) then
            bShowLine = true
            break
        end
    end
    UIHelper.SetVisible(self.ImgBtnLine, bShowLine)
    UIHelper.LayoutDoLayout(self.WidgetTopBtn)
end

function UIHomelandInteractCommonView:OnClickBtnSure(tbInfo)
    if not HomelandMiniGameData.CheckCanOpenFrame(self.tData.tPosInfo) then
        UIMgr.Close(self)
        TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_DISTANCE)
        return
    end

	local bSure = HomelandMiniGameData.CheckSlotState(tbInfo.aConditionSlots)
	if bSure then
		local nBtnID = tbInfo.nID
		local nCostType = tbInfo.nCostType
        if nBtnID == _BTN_TYPE.GET_FISH then
            HomelandFishingData.MarkCurFishPond(self.tData)
        end

		if nCostType == _BTN_COST_TYPE.FOR_COST then
			-- ShowWndSetCost(hFrame, nBtnID, nCostType, tbInfo.bClosePanel)
        elseif tbInfo.bSeedingAll then
            HomelandMiniGameData.SeedingAllFurniture(nBtnID, nCostType, tbInfo.bClosePanel)
		elseif nCostType == _BTN_COST_TYPE.SHOW_COST_TIP_FIRST then
			local nCost = HomelandMiniGameData.GetMiniGameCost()
			if nCost == 0 then
				HomelandMiniGameData.GameProtocol(nBtnID, nCostType, tbInfo.bClosePanel)
			else
				local szMsgString
				local tModule1ItemInfo = HomelandMiniGameData.GetModule1SlotItemInfo()
				local dwTabType, nStackNum, dwIndex
				if tModule1ItemInfo then
					dwTabType, nStackNum, dwIndex = HomelandMiniGameData.GetItemCommonDataFromUIItem(tModule1ItemInfo)
				end
				if dwTabType then
					local szItemName, szItemColor = "", ""
					local itemInfo = ItemData.GetItemInfo(dwTabType, dwIndex)
					szItemName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItem(itemInfo))
					szItemName = "[" .. szItemName .. "]"
					local szText = g_tStrings.tStrHouseUseItemWithCostSure[nBtnID] or g_tStrings.tStrHouseUseItemWithCostSure["default"]
                    szMsgString = string.format(szText, UIHelper.GetMoneyText(nCost * 10000, nil, nil, false), GetFormatText(szItemName, 162, GetItemFontColorByQuality(itemInfo.nQuality, false)))
				else
					szMsgString = string.format(g_tStrings.STR_HOUSE_USE_ITEM_WITH_COST_WHEN_NO_ITEM_SURE, UIHelper.GetMoneyText(nCost * 10000, nil, nil, false))
				end

                UIHelper.ShowConfirm(szMsgString, function ()
                    HomelandMiniGameData.GameProtocol(nBtnID, nCostType, tbInfo.bClosePanel)
                end, nil, true)
			end
		elseif nCostType == _BTN_COST_TYPE.FOR_PASSWORD then
			-- TogglePassWordSet(hFrame,nBtnID, nCostType, tbInfo.bClosePanel)
            self:ShowPassWordSet(nBtnID, nCostType)
		elseif nCostType == _BTN_COST_TYPE.SHOW_PW_TIP then
			-- TogglePassWordInput(hFrame, nBtnID, nCostType, tbInfo.bClosePanel)
            self:ShowPassWordTips(nBtnID, nCostType)
		else
			HomelandMiniGameData.GameProtocol(nBtnID, nCostType, tbInfo.bClosePanel)
		end
	else
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_HOUSE_CONDITION_TIP)
	end
end

function UIHomelandInteractCommonView:UpdateWeaponDisplayInfo()
    UIHelper.SetVisible(self.BtnSetting, false)
    UIHelper.SetVisible(self.BtnMoney, false)
    UIHelper.SetVisible(self.BtnRefresh, true)
    UIHelper.SetVisible(self.BtnOne, true)
    UIHelper.SetVisible(self.WidgetBtnTwo, false)
    UIHelper.SetVisible(self.WidgetBtnThree, false)
    UIHelper.SetVisible(self.BtnTips, false)

    UIHelper.BindUIEvent(self.BtnRefresh, EventType.OnClick, function ()
        HomelandWeaponDisplayData.GameProtocol(0, 0, 2)
    end)

    UIHelper.BindUIEvent(self.tbBtns[1], EventType.OnClick, function ()
        local nWeaponID1 = HomelandWeaponDisplayData.tData.tWeaponList[1]
        local nWeaponID2 = HomelandWeaponDisplayData.tData.tWeaponList[2]
        HomelandWeaponDisplayData.GameProtocol(nWeaponID1, nWeaponID2, 1)
    end)

    UIHelper.SetString(self.LabelTitle, "武器架")
    UIHelper.SetString(self.tbLabelBtnNames[1], "展示确认")

    local nWeaponID1, nWeaponID2 = 0, 0
    if HomelandWeaponDisplayData.tData.tWeaponList and HomelandWeaponDisplayData.tData.tWeaponList[1] then
        nWeaponID1 = HomelandWeaponDisplayData.tData.tWeaponList[1]
    end

    if HomelandWeaponDisplayData.bCJ then
        if HomelandWeaponDisplayData.tData.tWeaponList and HomelandWeaponDisplayData.tData.tWeaponList[2] then
            nWeaponID2 = HomelandWeaponDisplayData.tData.tWeaponList[2]
        end
    end

    self.scriptModel1 = self.scriptModel1 or UIHelper.AddPrefab(PREFAB_ID.WidgetItemNcessary, self.LayoutContent)

    if HomelandWeaponDisplayData.bCJ then
        self.scriptModel1:OnEnter({
            szTitle = UIHelper.UTF8ToGBK("轻剑展示"),
            tSlot = {
                nItemMinNum = 0,
                nType = PETS_SCREE_TYPE.WEAPON,
                nDetail = WEAPON_DETAIL.SWORD,
                nWeaponID = nWeaponID1,
            },
        }, true)
        self.scriptModel2 = self.scriptModel2 or UIHelper.AddPrefab(PREFAB_ID.WidgetItemNcessary, self.LayoutContent)
        self.scriptModel2:OnEnter({
            szTitle = UIHelper.UTF8ToGBK("重剑展示"),
            tSlot = {
                nItemMinNum = 0,
                nType = PETS_SCREE_TYPE.WEAPON,
                nDetail = WEAPON_DETAIL.BIG_SWORD,
                nWeaponID = nWeaponID2,
            },
        }, true)
    else
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
        local dwForceID = hPlayer.dwForceID
        local nDetail = GetForceWeaponType(dwForceID)

        self.scriptModel1:OnEnter({
            szTitle = UIHelper.UTF8ToGBK("武器展示"),
            tSlot = {
                nItemMinNum = 0,
                nType = PETS_SCREE_TYPE.WEAPON,
                nDetail = nDetail,
                nWeaponID = nWeaponID1,
            },
        }, true)
    end
end

function UIHomelandInteractCommonView:ShowPassWordSet(nBtnID, nCostType)
    UIMgr.Open(VIEW_ID.PanelHomeChuanSong, "设置密钥", function (tbPassword)
        for i, nNum in ipairs(tbPassword) do
            HomelandMiniGameData["nPWD"..i] = nNum
        end
        HomelandMiniGameData.GameProtocol(nBtnID, nCostType, true)
    end)
end

function UIHomelandInteractCommonView:ShowPassWordTips(nBtnID, nCostType)
    UIMgr.Open(VIEW_ID.PanelHomeChuanSong, "机关解密", function (tbPassword)
        for i, nNum in ipairs(tbPassword) do
            HomelandMiniGameData["nPWD"..i] = nNum
        end
        HomelandMiniGameData.GameProtocol(nBtnID, nCostType, true)
    end)
end

return UIHomelandInteractCommonView