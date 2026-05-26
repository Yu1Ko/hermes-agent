-- ---------------------------------------------------------------------------------
-- 奖励展示cell
-- PanelTreasureBoxRewardPop
-- ---------------------------------------------------------------------------------

local UIPanelTreasureBoxRewardPop = class("UIPanelTreasureBoxRewardPop")

function UIPanelTreasureBoxRewardPop:_LuaBindList()
    self.BtnClose               = self.BtnClose
    self.LayoutItemShellShort   = self.LayoutItemShellShort --- 奖励layout 少
    self.ScrollViewItemShell    = self.ScrollViewItemShell --- 奖励Scroll 少

    self.BtnRewardTip           = self.BtnRewardTip --- 大奖btn
    self.ImgReward              = self.ImgReward --- 大奖图片
    self.LabelRewardName        = self.LabelRewardName -- 大奖名字
    self.BtnCalloff             = self.BtnCalloff
    self.BtnOk                  = self.BtnOk
end

function UIPanelTreasureBoxRewardPop:OnEnter(tInfo, dwBoxID, dwAwardSeriesID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    -- local tFakeInfo = {}
    --     tFakeInfo[1] = {
    --         nRewardNum = 14,
    --         nRewardIndex = 24445,
    --         bFlag = true,
    --         nRewardType = 5,
    --     }
    --     tFakeInfo[2] = {
    --         nRewardNum = 14,
    --         nRewardIndex = 24445,
    --         bFlag = false,
    --         nRewardType = 5,
    --     }
    --     tFakeInfo[3] = {
    --         nRewardNum = 14,
    --         nRewardIndex = 24445,
    --         bFlag = false,
    --         nRewardType = 5,
    --     }
    --     tFakeInfo[4] = {
    --         nRewardNum = 14,
    --         nRewardIndex = 24445,
    --         bFlag = false,
    --         nRewardType = 5,
    --     }
    --     tFakeInfo[5] = {
    --         nRewardNum = 14,
    --         nRewardIndex = 24445,
    --         bFlag = false,
    --         nRewardType = 5,
    --     }
    --     tFakeInfo[6] = {
    --         nRewardNum = 14,
    --         nRewardIndex = 24445,
    --         bFlag = false,
    --         nRewardType = 5,
    --     }
    --     tFakeInfo[7] = {
    --         nRewardNum = 14,
    --         nRewardIndex = 24445,
    --         bFlag = false,
    --         nRewardType = 5,
    --     }
    self.dwBoxID = dwBoxID
    self.dwAwardSeriesID = dwAwardSeriesID
    self:UpdateInfo(tInfo)
end

function UIPanelTreasureBoxRewardPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelTreasureBoxRewardPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
    
    UIHelper.BindUIEvent(self.BtnOk, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCalloff, EventType.OnClick, function ()
        -- self.fnClick()
        if not UIMgr.IsViewOpened(VIEW_ID.PanelRandomTreasureBox) then
            UIMgr.Open(VIEW_ID.PanelRandomTreasureBox, self.dwBoxID, nil, self.dwAwardSeriesID)
        end
        UIMgr.Close(self)
    end)
end

function UIPanelTreasureBoxRewardPop:RegEvent()
    
end

function UIPanelTreasureBoxRewardPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelTreasureBoxRewardPop:UpdateInfo(tInfo)
    local bShort = false
    if #tInfo > 10 then
        bShort = false
    else
        bShort = true
    end

    local bHaveBigAward = false
    for _, tItem in ipairs(tInfo) do
        if tItem.bFlag == false then
            local tRewardItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, (bShort and self.LayoutItemShellShort) or self.ScrollViewItemShell)
            assert(tRewardItemScript)
            if tItem.nRewardIndex == "prestige" then
                tRewardItemScript:OnInitWithCurrencyType(tItem.nRewardIndex)
                tRewardItemScript:SetLabelCount(tItem.nRewardNum)
                tRewardItemScript:SetClickCallback(function()
                    TipsHelper.DeleteAllHoverTips()
                    CurrencyData.ShowCurrencyHoverTipsInDir(tRewardItemScript._rootNode, TipsLayoutDir.RIGHT_CENTER, CurrencyNameToType[tItem.nRewardIndex])
                end)
            elseif IsString(tItem.nRewardIndex) then
                local nCurrencyType = CurrencyNameToType[tItem.nRewardIndex]
                if nCurrencyType then
                    tRewardItemScript:OnInitWithCurrencyType(tItem.nRewardIndex)
                    tRewardItemScript:SetLabelCount(tItem.nRewardNum)
                    tRewardItemScript:SetClickCallback(function()
                        TipsHelper.DeleteAllHoverTips()
                        CurrencyData.ShowCurrencyHoverTipsInDir(tRewardItemScript._rootNode, TipsLayoutDir.RIGHT_CENTER, CurrencyNameToType[tItem.nRewardIndex])
                    end)
                else
                    LOG.WARN("UIPanelTreasureBoxRewardPop:UpdateInfo - Invalid reward index: %s" .. tostring(tItem.nRewardIndex))
                end
            else
                tRewardItemScript:OnInitWithTabID(tItem.nRewardType, tItem.nRewardIndex, tItem.nRewardNum)
                tRewardItemScript:SetClickCallback(function(dwItemTabType, dwItemTabIndex)
                    TipsHelper.DeleteAllHoverTips()
                    local uiTips, uiItemTipScript = TipsHelper.ShowItemTips(tRewardItemScript._rootNode, dwItemTabType, dwItemTabIndex)
                    uiItemTipScript:SetBtnState({})
                end)
            end
            UIHelper.ToggleGroupAddToggle(self.ToggleGroup, tRewardItemScript.ToggleSelect)
            UIHelper.SetSelected(tRewardItemScript.ToggleSelect, false)
            UIHelper.SetAnchorPoint(tRewardItemScript._rootNode, 0, 0)
        elseif tItem.bFlag == true then
            bHaveBigAward = true
            self.tBigAward = tItem
        end
    end

    if bShort then
        UIHelper.SetVisible(self.LayoutItemShellShort, true)
        UIHelper.SetVisible(self.ScrollViewItemShell, false)
        UIHelper.LayoutDoLayout(self.LayoutItemShellShort)
    else
        UIHelper.SetVisible(self.LayoutItemShellShort, false)
        UIHelper.SetVisible(self.ScrollViewItemShell, true)
        UIHelper.ScrollViewDoLayout(self.ScrollViewItemShell)
    end

    if bHaveBigAward then
        local AwardItem = ItemData.GetItemInfo(self.tBigAward.nRewardType, self.tBigAward.nRewardIndex)
        local tItemInfo = TreasureBoxData.GetRewardItemInfo(self.tBigAward.nRewardType, self.tBigAward.nRewardIndex)
        
        UIHelper.SetVisible(self.WidgetHeadFrame, false)
        UIHelper.SetVisible(self.ImgReward, false)
        if tItemInfo and tItemInfo.nAvatarID and tItemInfo.nAvatarID ~= 0 then
            UIHelper.SetVisible(self.WidgetHeadFrame, true)
            local avatarCell = UIHelper.AddPrefab(PREFAB_ID.WidgetHeadListItem, self.WidgetHeadFrame)
            assert(avatarCell)
            avatarCell:UpdateBoxReward(tItemInfo.nAvatarID)
        elseif tItemInfo and tItemInfo.szVKImagePath and tItemInfo.szVKImagePath ~= "" then
            UIHelper.SetTexture(self.ImgReward, tItemInfo.szVKImagePath)
            UIHelper.SetVisible(self.ImgReward, true)
        else
            UIHelper.SetItemIconByItemInfo(self.ImgReward, AwardItem)
            UIHelper.SetVisible(self.ImgReward, true)
        end
        
        local szItemName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItem(AwardItem))
        UIHelper.SetString(self.LabelRewardName, szItemName)

        -- 试穿功能
        -- local bNotShowBtn = false
        -- local nSub = AwardItem.nSub
        -- local nGenre = AwardItem.nGenre
        -- if nGenre ~= ITEM_GENRE.EQUIPMENT or (nGenre == ITEM_GENRE.EQUIPMENT and nSub == EQUIPMENT_SUB.MINI_AVATAR) then
        --     bNotShowBtn = true
        -- end
        -- self:SetPreviewAward(bNotShowBtn)
    else
        UIHelper.SetVisible(self.BtnCalloff, false)
        UIHelper.LayoutDoLayout(self.LayoutBtn)

        UIHelper.SetVisible(self.WidgetBigReward, false)
        UIHelper.LayoutDoLayout(self.WidgetReward)
    end
end

function UIPanelTreasureBoxRewardPop:SetPreviewAward(bNotShowBtn)
    if bNotShowBtn then
        UIHelper.SetVisible(self.BtnCalloff, false)
        UIHelper.LayoutDoLayout(self.LayoutBtn)
    else
        local tbBtn = OutFitPreviewData.SetPreviewBtn(self.tBigAward.nRewardType, self.tBigAward.nRewardIndex)
        if tbBtn and tbBtn[1] and tbBtn[1].OnClick then
            self.fnClick = tbBtn[1].OnClick
        else
            UIHelper.SetVisible(self.BtnCalloff, false)
            UIHelper.LayoutDoLayout(self.LayoutBtn)
        end
    end
end


return UIPanelTreasureBoxRewardPop