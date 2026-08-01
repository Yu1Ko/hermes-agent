-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAuctionPreparationView
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIAuctionPreparationView = class("UIAuctionPreparationView")

function UIAuctionPreparationView:OnEnter(tLootInfo)
    if not tLootInfo then
        return
    end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tLootInfo = tLootInfo
    --self:LoadData()
    self:UpdateInfo()
end

function UIAuctionPreparationView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAuctionPreparationView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(VIEW_ID.PanelAuctionPreparationPop)
    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function ()
        UIHelper.SetText(self.EditBoxStartBrick, "0")
        UIHelper.SetText(self.EditBoxStartGold, "0")
        UIHelper.SetText(self.EditBoxStepBrick, "0")
        UIHelper.SetText(self.EditBoxStepGold, "1")
    end)

    UIHelper.BindUIEvent(self.BtnStart, EventType.OnClick, function ()
        local szStartBrick = UIHelper.GetText(self.EditBoxStartBrick)
        local szStartGold = UIHelper.GetText(self.EditBoxStartGold)
        local szBidBrick = UIHelper.GetText(self.EditBoxStepBrick)
        local szBidGold = UIHelper.GetText(self.EditBoxStepGold)
        local nStartBrick = tonumber(szStartBrick) or 0
        local nStartGold = tonumber(szStartGold) or 0
        local nBidBrick = tonumber(szBidBrick) or 0
        local nBidGold = tonumber(szBidGold) or 0

        if self.nStepGold and self.nStepGold > 0 then
            nBidGold = self.nStepGold
        end

        local bInvaidNum = not nStartBrick or not nStartGold or not nBidBrick or not nBidGold
        bInvaidNum = bInvaidNum and nStartBrick <= 0 and nStartGold <= 0 and nBidBrick <= 0 and nBidGold <= 0
        if bInvaidNum then
            TipsHelper.ShowNormalTip(g_tStrings.GOLD_TEAM_BID_PRICE_EMPTY)
            return
        end
        local tData = {
            tLootInfo = self.tLootInfo,
            nStartBrick = nStartBrick,
            nStartGold = nStartGold,
            nBidBrick = nBidBrick,
            nBidGold = nBidGold,
        }
        Event.Dispatch(EventType.OnAuctionPreparation, tData)
        local nStartPrice = tData.nStartBrick * 10000 + tData.nStartGold
        local nStepPrice = tData.nBidBrick * 10000 + tData.nBidGold
        --nStartPrice = nStartPrice + nStepPrice  -- 潜规则:服务器会认为传上去的起步价包含了一个步长

        local bRebidding = false
        local tBidInfo = AuctionData.GetBiddingInfo(tData.tLootInfo.dwDoodadID, tData.tLootInfo.nItemLootIndex)
        if tBidInfo then
            bRebidding = tBidInfo.nState == BIDDING_INFO_STATE.BIDDING or tBidInfo.nState == BIDDING_INFO_STATE.COUNT_DOWN
        end

        local teamBidMgr = GetTeamBiddingMgr()
        local nCode = teamBidMgr.CanBeginBidding(tData.tLootInfo.dwDoodadID, tData.tLootInfo.nItemLootIndex, nStartPrice, nStepPrice, bRebidding)
        if nCode ~= TEAM_BIDDING_START_RESULT.SUCCESS then
            TipsHelper.ShowNormalTip(g_tStrings.tTeamBiddingStartError[nCode])
            return
        end
        teamBidMgr.BeginBidding(tData.tLootInfo.dwDoodadID, tData.tLootInfo.nItemLootIndex, nStartPrice, nStepPrice, bRebidding)
        UIMgr.Close(VIEW_ID.PanelAuctionPreparationPop)
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxStartBrick, function ()
        UIHelper.SetText(self.EditBoxStartBrick, tostring(tonumber(UIHelper.GetText(self.EditBoxStartBrick)) or 0))
    end)
    UIHelper.RegisterEditBoxEnded(self.EditBoxStartGold, function ()
        UIHelper.SetText(self.EditBoxStartGold, tostring(tonumber(UIHelper.GetText(self.EditBoxStartGold)) or 0))
    end)
    -- UIHelper.RegisterEditBoxEnded(self.EditBoxStepBrick, function ()
    --     UIHelper.SetText(self.EditBoxStepBrick, tostring(tonumber(UIHelper.GetText(self.EditBoxStepBrick)) or 0))
    --     if not self:CheckData() then
    --         UIHelper.SetText(self.EditBoxStepGold, "1")
    --     end
    -- end)
    -- UIHelper.RegisterEditBoxEnded(self.EditBoxStepGold, function ()
    --     UIHelper.SetText(self.EditBoxStepGold, tostring(tonumber(UIHelper.GetText(self.EditBoxStepGold)) or 0))
    --     if not self:CheckData() then
    --         UIHelper.SetText(self.EditBoxStepGold, "1")
    --     end
    -- end)
end

function UIAuctionPreparationView:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        --UIHelper.SetSelected(self.TogBidVariatePrice, false)
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardOpen, function(editbox)
        if editbox == self.EditBoxStartBrick then
            UIHelper.SetEditBoxGameKeyboardRange(self.EditBoxStartBrick, 0, 9999)
        elseif editbox == self.EditBoxStartGold then
            UIHelper.SetEditBoxGameKeyboardRange(self.EditBoxStartGold, 0, 9999)
        end        
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        if editbox == self.EditBoxStartBrick then
            local szBrick = UIHelper.GetText(self.EditBoxStartBrick)
            UIHelper.SetText(self.EditBoxStartBrick, tostring(tonumber(szBrick) or 0))
        elseif editbox == self.EditBoxStartGold then
            local szGold = UIHelper.GetText(self.EditBoxStartGold)
            UIHelper.SetText(self.EditBoxStartGold, tostring(tonumber(szGold) or 0))
        end
    end)
end

function UIAuctionPreparationView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIAuctionPreparationView:LoadData()
    self.bDirty = false
    self.nCurIndex = 1
    self.tCustomData = CustomData.GetData(CustomDataType.Role, "UIAuctionPresetPop")
    if not self.tCustomData or not self.tCustomData.tPresets then
        self.tCustomData = {
            tPresets = {},
        }
    end

    for nIndex, _ in ipairs(self.TogTagList) do
        if not self.tCustomData.tPresets[nIndex] then
            self.tCustomData.tPresets[nIndex] = {
                szName = UIHelper.GetString(self.LabelTagNameList[nIndex*2]),
                szStartBrick = 0,
                szStartGold = 0,
                szStepBrick = 0,
                szStepGold = 1,
            }
        else
            local tPreset = self.tCustomData.tPresets[nIndex]
            UIHelper.SetString(self.LabelTagNameList[nIndex*2-1], tPreset.szName)
            UIHelper.SetString(self.LabelTagNameList[nIndex*2], tPreset.szName)
        end
    end
    UIHelper.SetSelected(self.TogTagList[1], true)
end

function UIAuctionPreparationView:CheckData()
    local nStepBrick = tonumber(UIHelper.GetText(self.EditBoxStepBrick)) or 0
    local nStepGold = tonumber(UIHelper.GetText(self.EditBoxStepGold)) or 0
    if nStepBrick == 0 and nStepGold == 0 then
        TipsHelper.ShowImportantRedTip("变价梯度不能为0")
        return false
    end

    return true
end

function UIAuctionPreparationView:UpdateInfo()
    local item = AuctionData.GetItem(self.tLootInfo.dwDoodadID, self.tLootInfo.nItemLootIndex)
    if not item then
        return
    end

    self.scriptIcon = self.scriptIcon or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)
    self.scriptIcon:OnInitWithTabID(item.dwTabType, item.dwIndex)
    if item.bCanStack and item.nStackNum > 0 then
        self.scriptIcon:SetLabelCount(item.nStackNum)
    end
    UIHelper.SetVisible(self.scriptIcon.WidgetSelectBG, false)
    self.scriptIcon:SetClickCallback(function (nItemType, nItemIndex)
        local _, scriptItemTip = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, self.scriptIcon._rootNode)
        scriptItemTip:SetFunctionButtons({})
        scriptItemTip:OnInitWithItemID(self.tLootInfo.dwItemID)          
    end)

    local szItemName = ItemData.GetItemNameByItem(item)
    szItemName = UIHelper.GBKToUTF8(szItemName)
    UIHelper.SetString(self.LabelItemName, szItemName)

    -- 设置默认起拍价
    local nDefaultPrice, nDefaultStepPrice = AuctionData.GetDefaultPriceInfo(item)
    self.nDefaultPrice = nDefaultPrice
    self.nDefaultStepPrice = nDefaultStepPrice
    local nStartBrick = math.floor(self.nDefaultPrice / 10000)
    local nStratGold = self.nDefaultPrice - nStartBrick * 10000
    local nStepBrick = math.floor(self.nDefaultStepPrice / 10000)
    local nStepGold = self.nDefaultStepPrice - nStepBrick * 10000
    UIHelper.SetText(self.EditBoxStartBrick, tostring(nStartBrick))
    UIHelper.SetText(self.EditBoxStartGold, tostring(nStratGold))
    UIHelper.SetText(self.EditBoxStepBrick, tostring(nStepBrick))
    UIHelper.SetText(self.EditBoxStepGold, tostring(nStepGold))

    local nType = GDAPI_GetDefaulItem(item) or 0
    local szCellName = AuctionData.PRESET_TYPE_NAME[nType] or "其它"
    local szPresetName = "官方"
    local tPreset = Storage.Auction.tPricePreset[Storage.Auction.nPricePresetID]    
    if tPreset then
        szPresetName = tPreset.szType
    end
    UIHelper.SetString(self.LabelType, szCellName)
    UIHelper.SetString(self.LabelPreset, szPresetName)
end

return UIAuctionPreparationView