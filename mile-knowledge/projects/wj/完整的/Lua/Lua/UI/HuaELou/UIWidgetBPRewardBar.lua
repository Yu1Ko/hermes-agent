-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetBPRewardBar
-- Date: 2022-12-23 10:55:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetBPRewardBar = class("UIWidgetBPRewardBar")
function UIWidgetBPRewardBar:OnEnter(nLevel, tReward)
    if not nLevel or not tReward then
        return
    end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(nLevel, tReward)
end

function UIWidgetBPRewardBar:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetBPRewardBar:BindUIEvent()

end

function UIWidgetBPRewardBar:RegEvent()

end

function UIWidgetBPRewardBar:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetBPRewardBar:UpdateInfo(nLevel, tReward)
    local player = GetClientPlayer()
    if not player then
        return
    end

    if self.LabelLevel then
        UIHelper.SetString(self.LabelLevel, tostring(nLevel))
    elseif self.LabelTitle then
        UIHelper.SetString(self.LabelTitle, string.format("%d级可领", nLevel))
    end

    for nIndex = 0, #self.WidgetRewardItems do
        UIHelper.SetVisible(self.WidgetRewardItems[nIndex], false)
        UIHelper.SetVisible(self.WidgetRewardMasks[nIndex], false)
        UIHelper.SetVisible(self.WidgetRewardCheckMarks[nIndex], false)
        UIHelper.SetVisible(self.WidgetRewardActivates[nIndex], false)
    end
    UIHelper.SetVisible(self.WidgetGrandRewardItem, false)
    UIHelper.SetVisible(self.WidgetGrandRewardItem2, false)
    UIHelper.SetVisible(self.WidgetGrandRewardMask, false)
    UIHelper.SetVisible(self.WidgetGrandRewardMask2, false)
    UIHelper.SetVisible(self.WidgetGrandRewardCheck, false)
    UIHelper.SetVisible(self.WidgetGrandRewardCheck2, false)
    UIHelper.SetVisible(self.WidgetGrandRewardActivate, false)
    UIHelper.SetVisible(self.WidgetGrandRewardActivate2, false)
    UIHelper.SetVisible(self.WidgetGrandRewardLock, not HuaELouData.IsGrandRewardUnlock())
    UIHelper.SetVisible(self.WidgetGrandRewardLock2, not HuaELouData.IsGrandRewardUnlock())
    
    local bNeedHighLight = false
    local tNormalRewardDetail = HuaELouData.GetRewardDetatil(tReward.dwSetID)
    if tNormalRewardDetail and tNormalRewardDetail.AwardItem then
        for nIndex, tItemInfo in pairs(tNormalRewardDetail.AwardItem) do
            local dwTabType = tItemInfo.dwItemType
            local dwIndex   = tItemInfo.dwItemID
            local nStackNum = tItemInfo.nItemAmount

            UIHelper.SetVisible(self.WidgetRewardItems[nIndex], true)
            UIHelper.RemoveAllChildren(self.WidgetRewardSlots[nIndex])
            local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetHuaELouReward, self.WidgetRewardSlots[nIndex], dwTabType, dwIndex, nStackNum, true)
            local eSetState, _ = HuaELouData.GetCollectionState(tReward.dwSetID)
            if scriptView and eSetState then
                UIHelper.SetSwallowTouches(scriptView.ToggleSelect, false)
                UIHelper.SetAnchorPoint(scriptView._rootNode, 0.5, 0.5)
                if eSetState == SET_COLLECTION_STATE_TYPE.UNCOLLECTED
                or eSetState == SET_COLLECTION_STATE_TYPE.COLLECTING then
                    bNeedHighLight = true
                    UIHelper.SetVisible(scriptView.ImgNotReady, false)
                elseif eSetState == SET_COLLECTION_STATE_TYPE.COLLECTED then                    
                    UIHelper.SetVisible(self.WidgetRewardCheckMarks[nIndex], true)
                    --UIHelper.SetVisible(self.WidgetRewardMasks[nIndex], true)
                elseif eSetState == SET_COLLECTION_STATE_TYPE.TO_AWARD then
                    bNeedHighLight = true
                    UIHelper.SetVisible(self.WidgetRewardActivates[nIndex], true)
                    UIHelper.SetVisible(scriptView.ImgNotReady, false)
                end

                UIHelper.SetVisible(scriptView.ImgBlack, false)                
                scriptView:SetSelectChangeCallback(function (bSelected)
                    local eSetState, _ = HuaELouData.GetCollectionState(tReward.dwSetID)
                    if eSetState == SET_COLLECTION_STATE_TYPE.TO_AWARD then
                        player.ApplySetCollectionAward(tReward.dwSetID)
                    elseif bSelected and not self.bTipsShowing then
                        self.bTipsShowing = true
                        TipsHelper.DeleteAllHoverTips(true)
                        Timer.AddFrame(self, 1, function ()
                            TipsHelper.DeleteAllHoverTips(true)
                            TipsHelper.ShowItemTips(scriptView._rootNode, dwTabType, dwIndex, false)
                            self.bTipsShowing = false
                        end)
                    end
                end)
            end
        end
    end

    if tReward.dwSetID2 and tReward.dwSetID2 > 0 then
        local tGrandRewardDetail = HuaELouData.GetRewardDetatil(tReward.dwSetID2)
        if tGrandRewardDetail then
            local tItemInfo1, dwTabType1, dwIndex1, nStackNum1
            if tGrandRewardDetail.AwardItem and tGrandRewardDetail.AwardItem[1] then
                tItemInfo1 = tGrandRewardDetail.AwardItem[1]
                dwTabType1 = tItemInfo1.dwItemType
                dwIndex1   = tItemInfo1.dwItemID
                nStackNum1 = tItemInfo1.nItemAmount
            elseif tGrandRewardDetail.dwCustomAwardData1 and tGrandRewardDetail.dwCustomAwardData1 > 0 then
                dwTabType1 = "CurrencyType"
                dwIndex1   = CurrencyType.Coin
                nStackNum1 = tGrandRewardDetail.dwCustomAwardData1
            end
            if nStackNum1 then
                UIHelper.SetVisible(self.WidgetGrandRewardItem, true)
                local eSetState, _ = HuaELouData.GetCollectionState(tReward.dwSetID2)
                local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetHuaELouReward, self.WidgetGrandRewardSlot, dwTabType1, dwIndex1, nStackNum1, true)
                if scriptView and eSetState then
                    UIHelper.SetSwallowTouches(scriptView.ToggleSelect, false)
                    UIHelper.SetAnchorPoint(scriptView._rootNode, 0.5, 0.5)
                    if eSetState == SET_COLLECTION_STATE_TYPE.UNCOLLECTED
                    or eSetState == SET_COLLECTION_STATE_TYPE.COLLECTING then
                        UIHelper.SetVisible(scriptView.ImgNotReady, false)
                    elseif eSetState == SET_COLLECTION_STATE_TYPE.COLLECTED then
                        bNeedHighLight = true
                        UIHelper.SetVisible(self.WidgetGrandRewardCheck, true)
                        --UIHelper.SetVisible(self.WidgetGrandRewardMask, true)
                    elseif eSetState == SET_COLLECTION_STATE_TYPE.TO_AWARD then
                        bNeedHighLight = true
                        UIHelper.SetVisible(self.WidgetGrandRewardActivate, true)
                        UIHelper.SetVisible(scriptView.ImgNotReady, false)
                    end
                    UIHelper.SetVisible(scriptView.ImgBlack, false)                    
                    scriptView:SetSelectChangeCallback(function (bSelected)
                        local eSetState, _ = HuaELouData.GetCollectionState(tReward.dwSetID2)
                        if eSetState == SET_COLLECTION_STATE_TYPE.TO_AWARD then
                            player.ApplySetCollectionAward(tReward.dwSetID2)
                        elseif bSelected then
                            Timer.AddFrame(self, 1, function ()
                                TipsHelper.DeleteAllHoverTips(true)
                                TipsHelper.ShowItemTips(scriptView._rootNode, dwTabType1, dwIndex1, false)
                            end)
                        end
                    end)
                end
            end
            -- 检查有没有第二个付费奖励
            local tItemInfo2, dwTabType2, dwIndex2, nStackNum2
            if tGrandRewardDetail.AwardItem and #tGrandRewardDetail.AwardItem > 1 and tGrandRewardDetail.AwardItem[2] then
                tItemInfo2 = tGrandRewardDetail.AwardItem[2]
                dwTabType2 = tItemInfo2.dwItemType
                dwIndex2   = tItemInfo2.dwItemID
                nStackNum2 = tItemInfo2.nItemAmount
            end
            if nStackNum2 then
                UIHelper.SetVisible(self.WidgetGrandRewardItem2, true)                
                local eSetState, _ = HuaELouData.GetCollectionState(tReward.dwSetID2)
                local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetHuaELouReward, self.WidgetGrandRewardSlot2, dwTabType2, dwIndex2, nStackNum2, true)
                if scriptView and eSetState then
                    UIHelper.SetSwallowTouches(scriptView.ToggleSelect, false)
                    UIHelper.SetAnchorPoint(scriptView._rootNode, 0.5, 0.5)
                    if eSetState == SET_COLLECTION_STATE_TYPE.UNCOLLECTED
                    or eSetState == SET_COLLECTION_STATE_TYPE.COLLECTING then
                        UIHelper.SetVisible(scriptView.ImgNotReady, false)
                    elseif eSetState == SET_COLLECTION_STATE_TYPE.COLLECTED then
                        bNeedHighLight = true
                        UIHelper.SetVisible(self.WidgetGrandRewardCheck2, true)
                    elseif eSetState == SET_COLLECTION_STATE_TYPE.TO_AWARD then
                        bNeedHighLight = true
                        UIHelper.SetVisible(self.WidgetGrandRewardActivate2, true)
                        UIHelper.SetVisible(scriptView.ImgNotReady, false)
                    end
                    UIHelper.SetVisible(scriptView.ImgBlack, false)                    
                    scriptView:SetSelectChangeCallback(function (bSelected)
                        local eSetState, _ = HuaELouData.GetCollectionState(tReward.dwSetID2)
                        if eSetState == SET_COLLECTION_STATE_TYPE.TO_AWARD then
                            player.ApplySetCollectionAward(tReward.dwSetID2)
                        elseif bSelected then                            
                            Timer.AddFrame(self, 1, function ()
                                TipsHelper.DeleteAllHoverTips(true)
                                TipsHelper.ShowItemTips(scriptView._rootNode, dwTabType2, dwIndex2, false)
                            end)
                        end
                    end)
                end
            end
        end        
    end
    
    UIHelper.SetVisible(self.ImgGradeRewardLightBg, bNeedHighLight)
    UIHelper.SetVisible(self.ImgGradeRewardDarkBg, not bNeedHighLight)
end

return UIWidgetBPRewardBar