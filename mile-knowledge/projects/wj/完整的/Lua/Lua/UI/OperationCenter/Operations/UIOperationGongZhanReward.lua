-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationGongZhanReward
-- Date: 2026-03-25
-- Desc: WidgetGongZhanReward
-- ---------------------------------------------------------------------------------

local UIOperationGongZhanReward = class("UIOperationGongZhanReward")

function UIOperationGongZhanReward:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIOperationGongZhanReward:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationGongZhanReward:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnGongZhanReward, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelGongZhanSide, 1, 0)
    end)
end

function UIOperationGongZhanReward:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if UIHelper.GetSelected(self.SelectToggle) then
            UIHelper.SetSelected(self.SelectToggle, false)
        end
    end)
end

function UIOperationGongZhanReward:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  -----------------------------------

function UIOperationGongZhanReward:CheckAllTasksFinished(tOverview)
    if not tOverview or not tOverview.tGuildID then
        return false
    end

    local bHasOpenTask = false

    for _, dwID in ipairs(tOverview.tGuildID) do
        local tGuide = Table_GetGameGuideByID(dwID)
        if tGuide then
            -- 判断 bOpen（与 TaskCell 逻辑一致）
            local bOpen = true
            if tGuide.nClass1 == CLASS_MODE.DEFAULT
                and not CollectionData.IsDailyDungeon(tGuide.dwMapID) then
                bOpen = false
            end
            if bOpen then
                if tGuide.szActivity then
                    bOpen = CollectionData.GetGuideIsOpen(tGuide)
                elseif tGuide.bOpen ~= nil then
                    bOpen = tGuide.bOpen
                end
            end

            if bOpen then
                bHasOpenTask = true
                local bFinished = CollectionData.GetFinishState(tGuide)
                if not bFinished then
                    return false
                end
            end
        end
    end

    return bHasOpenTask
end

function UIOperationGongZhanReward:UpdateInfo(tOverview)
    self.tOverviewData = tOverview
    UIHelper.SetString(self.LabelTitle, UIHelper.GBKToUTF8(tOverview.szCatgName))
    -- UIHelper.SetString(self.LabelTask, UIHelper.GBKToUTF8(tOverview.szDsc))

    -- 解析物品字符串 "5_40385_5;5_40608_50;5_85485_5;" -> dwTabType_dwIndex_nStackNum
    local tItemList = {}
    if tOverview.szItem and tOverview.szItem ~= "" then
        local tSegments = SplitString(tOverview.szItem, ";")
        for _, szSegment in ipairs(tSegments) do
            if szSegment ~= "" then
                local tParts = SplitString(szSegment, "_")
                for k, v in ipairs(tParts) do
                    tParts[k] = tonumber(v or "") or 0
                end
                table.insert(tItemList, tParts)
            end
        end
    end

    local bFinished = self:CheckAllTasksFinished(tOverview)

    -- 将奖励挂在LayOutRewardItem上
    UIHelper.RemoveAllChildren(self.LayOutRewardItem)
    self.SelectToggle = nil
    for _, tItem in ipairs(tItemList) do
        local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayOutRewardItem)
        if itemScript then
            itemScript:OnInitWithTabID(tItem[1], tItem[2], tItem[3])
            itemScript:SetItemReceived(bFinished)
            itemScript:SetClickCallback(function(nTabType, nTabID)
                self.SelectToggle = itemScript.ToggleSelect
                TipsHelper.ShowItemTips(itemScript._rootNode, nTabType, nTabID)
            end)
        end
    end
    UIHelper.LayoutDoLayout(self.LayOutRewardItem)

    if bFinished then
        UIHelper.SetVisible(self.ImgTaskArrow, false)
        UIHelper.SetVisible(self.ImgRewardBgFinish, true)
        UIHelper.SetButtonState(self.BtnGongZhanReward, BTN_STATE.Disable, nil, false, false)
    else
        UIHelper.SetVisible(self.ImgTaskArrow, true)
        UIHelper.SetVisible(self.ImgRewardBgFinish, false)
        UIHelper.SetButtonState(self.BtnGongZhanReward, BTN_STATE.Normal)
    end
end


return UIOperationGongZhanReward
