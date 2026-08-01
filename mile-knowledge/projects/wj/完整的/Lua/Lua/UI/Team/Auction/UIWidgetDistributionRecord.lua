-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetDistributionRecord
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetDistributionRecord = class("UIWidgetDistributionRecord")

function UIWidgetDistributionRecord:OnEnter(tLootInfo, bHasDetail, fCallBack)
    if not tLootInfo then
        return
    end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tLootInfo = tLootInfo
    self.fCallBack = fCallBack
    if bHasDetail then
        self.ScrollViewPlayerList = self.ScrollViewPlayerListWithDetail
    else
        self.ScrollViewPlayerList = self.ScrollViewPlayerListWithoutDetail
    end
    self:UpdateInfo(tLootInfo.dwDoodadID, bHasDetail)

    local tBidInfo = AuctionData.GetBiddingInfo(tLootInfo.dwDoodadID, tLootInfo.nItemLootIndex)
    if tBidInfo and tBidInfo.dwDestPlayerID then
        self:RedirectPlayer(tBidInfo.dwDestPlayerID)
    end
end

function UIWidgetDistributionRecord:OnEnterWithBidInfo(tBidInfo, bHasDetail, fCallBack)
    if not tBidInfo then
        return
    end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tBidInfo = tBidInfo
    self.fCallBack = fCallBack
    if bHasDetail then
        self.ScrollViewPlayerList = self.ScrollViewPlayerListWithDetail
    else
        self.ScrollViewPlayerList = self.ScrollViewPlayerListWithoutDetail
    end
    self:UpdateInfo(tBidInfo.dwDoodadID, bHasDetail)
end

function UIWidgetDistributionRecord:OnEnterWithDoodadID(dwDoodadID, bHasDetail, fCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwDoodadID = dwDoodadID
    self.fCallBack = fCallBack
    if bHasDetail then
        self.ScrollViewPlayerList = self.ScrollViewPlayerListWithDetail
    else
        self.ScrollViewPlayerList = self.ScrollViewPlayerListWithoutDetail
    end
    self:UpdateInfo(dwDoodadID, bHasDetail)
end

function UIWidgetDistributionRecord:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIWidgetDistributionRecord:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnConfirmWithDetail, EventType.OnClick, function ()
        self:OnComfirm()
    end)

    UIHelper.BindUIEvent(self.BtnConfirmWithoutDetail, EventType.OnClick, function ()
        self:OnComfirm()
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        self:HidePanel(false)
    end)

    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function ()
        self:HidePanel(true)
    end)

    UIHelper.BindUIEvent(self.BtnResetWithDetail, EventType.OnClick, function ()
        self:UpdateInfo(self.dwDoodadID, self.bHasDetail)
    end)

    UIHelper.RegisterEditBoxEnded(self.EditRemark, function ()
        self:RefreshCommitLimit()
    end)

    UIHelper.RegisterEditBoxEnded(self.EditPriceBrick, function ()
        local szBrick = UIHelper.GetText(self.EditPriceBrick)
        UIHelper.SetText(self.EditPriceBrick, tostring(tonumber(szBrick) or 0))
    end)

    UIHelper.RegisterEditBoxEnded(self.EditPriceGold, function ()
        local szGold = UIHelper.GetText(self.EditPriceGold)
        UIHelper.SetText(self.EditPriceGold, tostring(tonumber(szGold) or 0))
    end)
end

function UIWidgetDistributionRecord:RegEvent()
    Event.Reg(self, EventType.OnGameNumKeyboardOpen, function(editbox)
        if editbox == self.EditPriceBrick then
            UIHelper.SetEditBoxGameKeyboardRange(self.EditPriceBrick, 0, 9999)
        elseif editbox == self.EditPriceGold then
            UIHelper.SetEditBoxGameKeyboardRange(self.EditPriceGold, 0, 9999)
        end        
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        if editbox == self.EditPriceBrick then
            local szBrick = UIHelper.GetText(self.EditPriceBrick)
            UIHelper.SetText(self.EditPriceBrick, tostring(tonumber(szBrick) or 0))
        elseif editbox == self.EditPriceGold then
            local szGold = UIHelper.GetText(self.EditPriceGold)
            UIHelper.SetText(self.EditPriceGold, tostring(tonumber(szGold) or 0))
        end
    end)
end

function UIWidgetDistributionRecord:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetDistributionRecord:UpdateInfo(dwDoodadID, bHasDetail)
    self.dwDoodadID = dwDoodadID
    self.bHasDetail = bHasDetail
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupMember)
    UIHelper.RemoveAllChildren(self.ScrollViewPlayerList)

    local player = g_pClientPlayer
    if not player then return end
    local scene = player.GetScene()
    if not scene then return end

    self.tScriptList = {}
    local aPartyMember = scene.GetLooterList(dwDoodadID)
    if aPartyMember and #aPartyMember > 0 then
        for nIndex, mbr in ipairs(aPartyMember) do
            if mbr.bOnlineFlag then
                local scriptRecord = UIHelper.AddPrefab(PREFAB_ID.WidgetDistriRecordPlayerItem, self.ScrollViewPlayerList)
                scriptRecord:OnEnter(mbr.dwID, function ()
                    self.dwPlayerID = mbr.dwID
                end)
                self.tScriptList[mbr.dwID] = scriptRecord
                UIHelper.ToggleGroupAddToggle(self.ToggleGroupMember, scriptRecord.ToggleSelect)
                UIHelper.SetTouchDownHideTips(scriptRecord.ToggleSelect, false)

                local nWidth = UIHelper.GetWidth(self.ScrollViewPlayerList)
                UIHelper.SetWidth(scriptRecord._rootNode, nWidth)
                UIHelper.CascadeDoLayoutDoWidget(scriptRecord._rootNode, true, true)
            end
        end
    else
        aPartyMember = AuctionData.GetAllOnlineTeamMemberInfo()
        for nIndex, tMemberInfo in ipairs(aPartyMember) do
            if tMemberInfo.dwPlayerID then 
                local scriptRecord = UIHelper.AddPrefab(PREFAB_ID.WidgetDistriRecordPlayerItem, self.ScrollViewPlayerList)
                scriptRecord:OnEnter(tMemberInfo.dwPlayerID, function ()
                    self.dwPlayerID = tMemberInfo.dwPlayerID
                end)
                self.tScriptList[tMemberInfo.dwPlayerID] = scriptRecord
                UIHelper.ToggleGroupAddToggle(self.ToggleGroupMember, scriptRecord.ToggleSelect)
                UIHelper.SetTouchDownHideTips(scriptRecord.ToggleSelect, false)
            end
        end
    end
    UIHelper.SetToggleGroupSelected(self.ToggleGroupMember, 0)

    UIHelper.ScrollViewDoLayout(self.ScrollViewPlayerList)
    UIHelper.ScrollToTop(self.ScrollViewPlayerList, 0)

    UIHelper.SetTouchDownHideTips(self.ScrollViewPlayerList, false)
    UIHelper.SetTouchDownHideTips(self.BtnMask, false)
    UIHelper.SetSwallowTouches(self.BtnMask, true)
    UIHelper.SetVisible(self.WidgetContentDetail, bHasDetail)
    UIHelper.SetVisible(self.WidgetContentNoDetail, not bHasDetail)

    local nDefaultBrick = 0
    local nDefaultGold = 0
    if self.tLootInfo then
        local tBidInfo = AuctionData.GetBiddingInfo(self.tLootInfo.dwDoodadID, self.tLootInfo.nItemLootIndex)
        if tBidInfo then
            local nPaidMoney = 0
            local nPrice = 0
            if tBidInfo.nPaidMoney then
                nPaidMoney = tBidInfo.nPaidMoney
            end
            if tBidInfo.nPrice then
                local nCurPrice = tBidInfo.nPrice
                if tBidInfo.szDestPlayerName and tBidInfo.szDestPlayerName == "" then nCurPrice = tBidInfo.nPrice + tBidInfo.nStepPrice end
                nPrice = nCurPrice - nPaidMoney
                nDefaultBrick = math.floor(nPrice / 10000)
                nDefaultGold = nPrice - nDefaultBrick * 10000
            end
        end
    end
    UIHelper.SetText(self.EditPriceBrick, tostring(nDefaultBrick))
    UIHelper.SetText(self.EditPriceGold, tostring(nDefaultGold))
    UIHelper.SetText(self.EditRemark, "")

    self:RefreshCommitLimit()
end

function UIWidgetDistributionRecord:RedirectPlayer(dwPlayerID)
    local scriptRecord = self.tScriptList[dwPlayerID]
    if scriptRecord then
        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupMember, scriptRecord.ToggleSelect)
        self.dwPlayerID = dwPlayerID
    end
end

function UIWidgetDistributionRecord:OnComfirm(bHasDetail)
    local szBrick = UIHelper.GetText(self.EditPriceBrick)
    local nBrick = tonumber(szBrick)
    local szGold = UIHelper.GetText(self.EditPriceGold)
    local nGold = tonumber(szGold)
    local szComment = UIHelper.GetText(self.EditRemark)
    local tData = {
        nBrick = nBrick or 0,
        nGold = nGold or 0,
        szComment = szComment,
        dwPlayerID = self.dwPlayerID
    }


    self.fCallBack(tData)
    self:HidePanel(false)
end

function UIWidgetDistributionRecord:ShowPanel(bPlayAnimate)
    if bPlayAnimate then
        UIHelper.SetVisible(self._rootNode, true)
        UIHelper.PlayAni(self, self.AniAll, "AniLeftShow")
    else
        UIHelper.SetVisible(self._rootNode, true)
    end
    if self.fShowPanelCallback then self.fShowPanelCallback() end
end

function UIWidgetDistributionRecord:HidePanel(bPlayAnimate)
    if bPlayAnimate then
        UIHelper.PlayAni(self, self.AniAll, "AniLeftHide", function ()
            UIHelper.SetVisible(self._rootNode, false)
        end)
    else
        UIHelper.SetVisible(self._rootNode, false)
    end
    if self.fHidePanelCallback then self.fHidePanelCallback() end
end

function UIWidgetDistributionRecord:SetShowPanelCallback(fCallBack)
    self.fShowPanelCallback = fCallBack
end

function UIWidgetDistributionRecord:SetHidePanelCallback(fCallBack)
    self.fHidePanelCallback = fCallBack
end

function UIWidgetDistributionRecord:RefreshCommitLimit()
    local szComment = UIHelper.GetText(self.EditRemark)
    local szCount = tostring(GetStringCharCount(szComment)) .. "/20"
    UIHelper.SetString(self.LabelLimit, szCount)
end

return UIWidgetDistributionRecord