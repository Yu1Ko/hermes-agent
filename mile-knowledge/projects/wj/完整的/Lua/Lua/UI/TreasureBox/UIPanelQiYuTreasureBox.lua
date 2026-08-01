-- ---------------------------------------------------------------------------------
-- 奇遇宝箱页面
-- PanelQiYuTreasureBox
-- ---------------------------------------------------------------------------------

local UIPanelQiYuTreasureBox = class("UIPanelQiYuTreasureBox")

function UIPanelQiYuTreasureBox:_LuaBindList()
    self.ScrollLeft              = self.ScrollLeft --- 加载WidgetQiYuBox的scroll 左侧
    self.WidgetArrow             = self.WidgetArrow
    self.WidgetAnchorLeft        = self.WidgetAnchorLeft --- ScrollLeft 和 WidgetArrow 的上层

    self.ScrollViewRewardList    = self.ScrollViewRewardList --- 加载 WidgetQiYuBoxRewardCell
    self.BtnConfirm              = self.BtnConfirm --- 开启btn
    self.LabelConfirm            = self.LabelConfirm --- 开启btn label
    self.LabelCost               = self.LabelCost --- 花费
    self.ImgItem                 = self.ImgItem --- 花费图标
    self.BtnDes2                 = self.BtnDes2 --- 花费btn

    self.TogSift                 = self.TogSift --- 筛选

    self.LabelTitle              = self.LabelTitle --- 页面标题
    self.BtnClose                = self.BtnClose

    self.TogType                 = self.TogType --- 全部 绝世 普通 宠物
end

function UIPanelQiYuTreasureBox:OnEnter(dwChoiceBoxID, dwChoiceTypeID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        TreasureBoxData.InitAward()
    end
    self.dwChoiceBoxID = dwChoiceBoxID
    self.dwChoiceTypeID = dwChoiceTypeID
    self.tAward = {}
    self.tBtn = {}
    self:UpdateInfo()
end

function UIPanelQiYuTreasureBox:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelQiYuTreasureBox:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.SetSelected(self.TogType[1], true, false)
    for index, tog in ipairs(self.TogType) do
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(_,bSelected)
            if bSelected then
                self.nQiYuType = index
                self:ShowAwardView()
            end
        end)
    end

    UIHelper.BindUIEvent(self.TogSift, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogSift, TipsLayoutDir.BOTTOM_CENTER, FilterDef.QiYuBox)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        if self.bChooseAward then
            if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP, "useitem") then
                return
            end
            RemoteCallToServer("On_BoxOpenUI_QYOpen", self.tBtn.nType, self.tBtn.dwItemIndex, self.tBtn.nContentTypeID,
            self.tBtn.nItemSequence, self.tBtn.nLuckyID or 0, self.tBtn.nRewardType or 0, self.tBtn.nRewardIndex or 0)
            UIMgr.Close(self)
            UIMgr.Close(VIEW_ID.PanelQiYu)
        else
            TipsHelper.ShowNormalTip("请先选择其中一种奇缘")
        end
    end)

    UIHelper.BindUIEvent(self.BtnDes2, EventType.OnClick, function()
        TipsHelper.DeleteAllHoverTips()
        local _, uiItemTipScript = TipsHelper.ShowItemTips(self.BtnDes2, self.dwBtnType, self.tBtn.dwItemIndex)
        uiItemTipScript:SetBtnState({})
    end)
end

function UIPanelQiYuTreasureBox:RegEvent()
    Event.Reg(self, EventType.OnFilter, function(szKey, tbInfo)
        if szKey ~= FilterDef.QiYuBox.Key then
            return
        end
        self.nQiYuState = tbInfo[1][1]
        self:ShowAwardView()
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        UIHelper.ScrollViewDoLayout(self.ScrollViewRewardList)
        UIHelper.ScrollViewDoLayout(self.ScrollLeft)
    end)
end

function UIPanelQiYuTreasureBox:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelQiYuTreasureBox:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollLeft)

    TreasureBoxData.InitQiYuBox()
    local tRowQiYuList = TreasureBoxData.GetQiYuBox()
    self.tQiYuList = {}
    for _, tInfo in ipairs(tRowQiYuList) do
        local bShow = false
        if tInfo.bOwnToShow == true then
            local BoxItem = ItemData.GetItemInfo(tInfo.dwType, tInfo.dwIndex)
            local _, nBagNum, _, _ = ItemData.GetItemAllStackNum(BoxItem, false)
            if nBagNum and nBagNum > 0 then
                bShow = true
            end
        else
            bShow = true
        end
        if bShow then
            table.insert(self.tQiYuList, tInfo)
        end
    end

    self.tQiYuCell = {}
    local nSelectIndex = 0
    local szFirstShowBoxName
    self.dwBoxID = self.dwChoiceBoxID
    for index, tInfo in ipairs(self.tQiYuList) do
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetQiYuBox, self.ScrollLeft) assert(scriptCell)
        scriptCell:UpdateInfo(tInfo)
        scriptCell:SetCallBack(function()
            self.dwBoxID = tInfo.dwID
            self:RevertFliter()
            self:UpdateFliterType(tInfo.szItemName)
            self:UpdateAward(tInfo.szItemName)
            self:UpdateBtnState()
        end)
        if self.dwChoiceBoxID and self.dwChoiceBoxID == tInfo.dwID then
            UIHelper.SetSelected(scriptCell.ToggleTreasureSeries, true, false)
            szFirstShowBoxName = tInfo.szItemName
            nSelectIndex = index
            self.dwBoxID = tInfo.dwID
        elseif not self.dwChoiceBoxID and index == 1 then
            UIHelper.SetSelected(scriptCell.ToggleTreasureSeries, true, false)
            szFirstShowBoxName = tInfo.szItemName
            nSelectIndex = index
            self.dwBoxID = tInfo.dwID
        else
            UIHelper.SetSelected(scriptCell.ToggleTreasureSeries, false, false)
        end
        table.insert(self.tQiYuCell, scriptCell)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollLeft)
    UIHelper.ScrollToIndex(self.ScrollLeft, nSelectIndex)
    Timer.AddFrame(self, 5, function()
        UIHelper.ScrollToIndex(self.ScrollLeft, nSelectIndex)
    end)

    if not szFirstShowBoxName then
        szFirstShowBoxName = self.tQiYuList and self.tQiYuList[1] and self.tQiYuList[1].szItemName
        UIHelper.SetSelected(self.tQiYuCell[1].ToggleTreasureSeries, true, false)
    end

    self:UpdateFliterType(szFirstShowBoxName)
    self:RevertFliter()
    self:UpdateAward(szFirstShowBoxName)
    self:UpdateBtnState()
end

function UIPanelQiYuTreasureBox:UpdateFliterType(szBoxName)
    local tType = TreasureBoxData.GetQiYuAwardType(self.dwBoxID)
    for index, tog in ipairs(self.TogType) do
        if index == 1 then
        else
            if tType[index] == true then
                UIHelper.SetVisible(tog, true)
            else
                UIHelper.SetVisible(tog, false)
            end
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutType)
end

function UIPanelQiYuTreasureBox:RevertFliter()
    if FilterDef.QiYuBox.tbRuntime then
        FilterDef.QiYuBox.tbRuntime[1][1] = 1
    end

    self.nQiYuType = 1
    for index, tog in ipairs(self.TogType) do
        if index == self.nQiYuType then
            UIHelper.SetSelected(tog, true, false)
        else
            UIHelper.SetSelected(tog, false, false)
        end
    end
    self.nQiYuState = 1
end

function UIPanelQiYuTreasureBox:UpdateAward(szBoxName, bForceUpdate)
    self:SetBoxName(szBoxName)
    self:InitAwardData()
    self:ShowAwardView()
end

function UIPanelQiYuTreasureBox:SetBoxName(szBoxName)
    self.szBoxName = szBoxName
end

function UIPanelQiYuTreasureBox:InitAwardData(bForceUpdate)
    local dwBoxID = self.dwBoxID
    if not dwBoxID then
        return
    end
    if self.tAward[dwBoxID] and not table.is_empty(self.tAward[dwBoxID]) and not bForceUpdate then
        return
    end
    
    self.tAward[dwBoxID] = self.tAward[dwBoxID] or TreasureBoxData.GetQiYuAwardList(dwBoxID)

    local nPlayerCamp = GetClientPlayer().nCamp or 0

    for index, tInfo in ipairs (self.tAward[dwBoxID]) do
        if tInfo.bItem then --烟花 或 其他
            self.tAward[dwBoxID][index].bCanSee = true
        else -- 奇遇
            local tBase = Table_GetAdventureByID(tInfo.nLuckyID)

            -- 0 宠物 1 普通 2 绝世
            local eType = 0
            if tBase.nClassify == 2 then
                if tBase.bPerfect then
                    eType = 2
                else
                    eType = 1
                end
            end
            self.tAward[dwBoxID][index].eType = eType

            local function IsTrigger(tAdvInfo)
                if tAdvInfo.dwStartID ~= 0 then
                    return g_pClientPlayer.GetAdventureFlag(tAdvInfo.dwStartID)
                elseif tAdvInfo.nStartQuestID ~= 0 then
                    local nAccQuest = g_pClientPlayer.GetQuestPhase(tAdvInfo.nStartQuestID)
                    return nAccQuest > 0
                end
            end

            -- 是否显示
            local bTrigger = IsTrigger(tBase)
            self.tAward[dwBoxID][index].bCanSee = false
            if bTrigger then
                self.tAward[dwBoxID][index].bCanSee = true
            else
                if tInfo.nLuckyCamp == 0 then
                    self.tAward[dwBoxID][index].bCanSee = true
                else
                    local nRelationTrigger = false
                    if tBase.nRelation ~= 0 then
                        local tRelation = Table_GetAdventureByID(tBase.nRelation)
                        nRelationTrigger = IsTrigger(tRelation)
                    end
                    if nRelationTrigger then
                        self.tAward[dwBoxID][index].bCanSee = false
                    else
                        if nPlayerCamp == 0 then
                            self.tAward[dwBoxID][index].bCanSee = (kmath.bit_and(2^nPlayerCamp, tBase.nCampCanSee) ~= 0)
                        else
                            self.tAward[dwBoxID][index].bCanSee = (nPlayerCamp == tInfo.nLuckyCamp)
                        end
                    end
                end
            end

            -- 机缘状态
            if self.tAward[dwBoxID][index].bCanSee then
                local nChanceState, _ = GDAPI_IfAdvenCanTry(tInfo.nLuckyID, eType)

                self.tAward[dwBoxID][index].bTrigger = false
                if not bTrigger and tBase.nRelation ~= 0 then
                    local tRelation = Table_GetAdventureByID(tBase.nRelation)
                    bTrigger = IsTrigger(tRelation)
                end

                if bTrigger then
                    self.tAward[dwBoxID][index].bTrigger = true
                    nChanceState = ADVENTURE_CHANCE_STATE.OK
                end

                self.tAward[dwBoxID][index].nChanceState = nChanceState
            else
                -- 伪状态
                self.tAward[dwBoxID][index].nChanceState = ADVENTURE_CHANCE_STATE.MAX
            end
        end
    end

    local function fnDegree(a, b)
        if a.nContentType == b.nContentType then
            if a.bItem or (a.bTrigger and b.bTrigger) then
                return a.nContentID < b.nContentID
            else
                if a.bTrigger or b.bTrigger then
                    return not a.bTrigger
                else
                    if a.nChanceState == b.nChanceState then
                        return a.nContentID < b.nContentID
                    else
                        return a.nChanceState < b.nChanceState
                    end
                end
            end
        else
            return a.nContentType < b.nContentType
        end
    end

    table.sort(self.tAward[dwBoxID], fnDegree)
end

function UIPanelQiYuTreasureBox:ShowAwardView()
    UIHelper.RemoveAllChildren(self.ScrollViewRewardList)
    local tList = self.tAward[self.dwBoxID]
    self.bChooseAward = false
    for index, tInfo in ipairs(tList) do
        local bShow = self:FliterData(tInfo)
        if bShow then
            local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetQiYuBoxRewardCell, self.ScrollViewRewardList) assert(scriptCell)
            scriptCell:UpdateInfo(tInfo)
            scriptCell:SetCallBack(function()
                if not self.tBtn then
                    self.tBtn = {}
                end
                self.bChooseAward = true
                self.tBtn.nContentTypeID = tInfo.nContentType
                self.tBtn.nItemSequence = tInfo.nContentID
                self.tBtn.nLuckyID = tInfo.nLuckyID
                self.tBtn.nRewardType = tInfo.dwType
                self.tBtn.nRewardIndex = tInfo.dwIndex
            end)
            UIHelper.SetSelected(scriptCell.ToggleTreasureSeries, false)
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRewardList)
end

function UIPanelQiYuTreasureBox:FliterData(tInfo)
    if self.nQiYuState ~= 1 then
        if tInfo.bItem then
            return false
        else
            if tInfo.nChanceState + 1 ~= self.nQiYuState then
                return false
            end
        end
    end

    if self.nQiYuType == 1 then
        return tInfo.bCanSee
    else
        if tInfo.bItem then
            return tInfo.bCanSee and self.nQiYuType == 5
        else
            return tInfo.bCanSee and (4 - tInfo.eType == self.nQiYuType)
        end
    end

end

local _GetQiYuInfo = function(tQiYuList, dwBoxID)
    local tInfo = {}
    for i, v in ipairs(tQiYuList) do
        if v.dwID == dwBoxID then
            tInfo = v
            break
        end
    end

    return tInfo
end

function UIPanelQiYuTreasureBox:UpdateBtnState(nFixNum)
    local tInfo = self.tQiYuList and _GetQiYuInfo(self.tQiYuList, self.dwBoxID)
    self.tBtn.nType = tInfo.dwID
    self.tBtn.dwItemIndex = tInfo.dwIndex

    self.dwBtnType = tInfo.dwType

    local BoxItem = ItemData.GetItemInfo(tInfo.dwType, tInfo.dwIndex)
    local _, nBagNum, _, _ = ItemData.GetItemAllStackNum(BoxItem, false)
    self.nTotalNum = nFixNum or nBagNum

    UIHelper.SetItemIconByItemInfo(self.ImgItem, BoxItem)

    local szCost = self.nTotalNum .. "/1"
    UIHelper.SetString(self.LabelCost, szCost)

    if self.nTotalNum == 0 then
        UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Disable)
    else
        UIHelper.SetButtonState(self.BtnConfirm, BTN_STATE.Normal)
    end
end

function UIPanelQiYuTreasureBox:UpdateView(nFixNum)
    -- 使用宝箱后更新页面
    local scriptCell = self.tQiYuCell[self.dwBoxID]
    scriptCell:UpdateNum(nFixNum)

    local tQiYuList = TreasureBoxData.GetQiYuBox()
    local tInfo = tQiYuList[self.dwBoxID]
    local szBoxName = tInfo.szItemName
    self:UpdateAward(szBoxName, true)

    self:UpdateBtnState(nFixNum)
end

return UIPanelQiYuTreasureBox