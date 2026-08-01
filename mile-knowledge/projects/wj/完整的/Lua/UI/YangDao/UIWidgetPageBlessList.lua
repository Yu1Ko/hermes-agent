-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetPageBlessList
-- Date: 2026-02-26 16:05:50
-- Desc: 扬刀大会-持有祝福列表 WidgetPageBlessList (PanelYangDaoOverview, PanelYangDaoBlessUpgrade)
-- ---------------------------------------------------------------------------------

local UIWidgetPageBlessList = class("UIWidgetPageBlessList")

function UIWidgetPageBlessList:OnEnter(tBlessCardList)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.poolBlessCard = PrefabPool.New(PREFAB_ID.WidgetBlessCardS, 30)
        self:InitTogElement()
    end

    FilterDef.BlessCard.Reset()
    if not tBlessCardList then
        return
    end

    self.tBlessCardList = tBlessCardList
    self:UpdateInfo()
end

function UIWidgetPageBlessList:OnExit()
    self.bInit = false
    self:UnRegEvent()

    if self.poolBlessCard then
        self.poolBlessCard:Dispose()
    end
    self.cellPrefabPool = nil
end

function UIWidgetPageBlessList:BindUIEvent()
    UIHelper.BindUIEvent(self.TogAll, EventType.OnClick, function()
        self:SetElementFilter(nil)
    end)
    UIHelper.BindUIEvent(self.BtnFilter, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnFilter, TipsLayoutDir.AUTO, FilterDef.BlessCard)
    end)
    UIHelper.BindUIEvent(self.BtnDetail, EventType.OnClick, function()
        local tElementPoint = self:GetElementPointInfo()
        if self.scriptSideDetail then
            if UIHelper.GetVisible(self.WidgetRightSidePanel) then
                return
            end
            if self.fnOutsideCloseBtnSetVisible then
                self.fnOutsideCloseBtnSetVisible(false)
            end
            UIHelper.SetVisible(self.WidgetRightSidePanel, true)
            UIHelper.StopAni(self, self.AniRight, "AniRightShow")
            UIHelper.StopAni(self, self.AniRight, "AniRightHide")
            UIHelper.PlayAni(self, self.AniRight, "AniRightShow")
        else
            UIMgr.Open(VIEW_ID.PanelElementDetailSide, tElementPoint)
        end
    end)
    UIHelper.BindUIEvent(self.TogDetailedDesc, EventType.OnSelectChanged, function(_, bSelected)
        ArenaTowerData.ShowBlessDetailDesc(bSelected)
    end)
end

function UIWidgetPageBlessList:RegEvent()
    Event.Reg(self, EventType.OnArenaTowerDataUpdate, function()
        self:UpdateElementPoint()
    end)
    Event.Reg(self, EventType.OnFilter, function(szKey, tInfo)
        if szKey == FilterDef.BlessCard.Key then
            self.tFilter = tInfo
            self:UpdateBlessList()
            self:UpdateFilterBtnState()
        end
    end)
    Event.Reg(self, EventType.OnShowBlessDetailDesc, function()
        UIHelper.SetSelected(self.TogDetailedDesc, ArenaTowerData.bShowBlessDetailDesc, false)
    end)
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        -- UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewList)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewListNew)
    end)
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if not self.scriptSideDetail then
            return
        end
        if not UIHelper.GetVisible(self.WidgetRightSidePanel) then
            return
        end
        UIHelper.StopAni(self, self.AniRight, "AniRightShow")
        UIHelper.StopAni(self, self.AniRight, "AniRightHide")
        UIHelper.PlayAni(self, self.AniRight, "AniRightHide", function()
            if self.fnOutsideCloseBtnSetVisible then
                self.fnOutsideCloseBtnSetVisible(true)
            end
            UIHelper.SetVisible(self.WidgetRightSidePanel, false)
        end)
    end)
end

function UIWidgetPageBlessList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetPageBlessList:OnInitPlayerStats(tPlayerStats, nSelPlayerID)
    self.tPlayerStats = tPlayerStats

    self:InitTogPlayer()
    self.scriptSideDetail = UIHelper.GetBindScript(self.WidgetRightSidePanel)
    UIHelper.SetTouchDownHideTips(self.BtnBlock, false)
    UIHelper.SetVisible(self.WidgetAniLeft, true)

    self.tScriptHead = self.tScriptHead or {}
    for i = 1, #self.tTogPlayer do
        local togPlayer = self.tTogPlayer[i]
        local tStats = tPlayerStats and tPlayerStats[i]
        if tStats then
            local _, szName = UIHelper.TruncateString(tStats.szName, 5, nil, 4)
            UIHelper.SetString(self.tLabelNameNormal[i], szName)
            UIHelper.SetString(self.tLabelNameUp[i], szName)
            if not self.tScriptHead[i] then
                self.tScriptHead[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.tWidgetHead[i])
            end
            self.tScriptHead[i]:SetHeadWithImg(PlayerKungfuImg[tStats.dwMountKungfuID])
            self.tScriptHead[i]:SetHeadContentSize(96, 96)
            self.tScriptHead[i]:SetTouchEnabled(false)
            UIHelper.UnBindUIEvent(togPlayer, EventType.OnSelectChanged)
            UIHelper.BindUIEvent(togPlayer, EventType.OnSelectChanged, function(_, bSelected)
                if bSelected and self.nSelPlayerID ~= tStats.dwPlayerID then
                    self.nSelCardID = nil
                    self.nSelPlayerID = tStats.dwPlayerID
                    self.tBlessCardList = tStats.tBlessCardList
                    self:UpdateElementPoint()
                    self:UpdateBlessList()
                end
            end) 
            if nSelPlayerID == tStats.dwPlayerID then
                Timer.AddFrame(self, 1, function()
                    UIHelper.SetSelected(togPlayer, true)
                end)
            end
        else
            UIHelper.SetString(self.tLabelNameNormal[i], "")
            UIHelper.SetString(self.tLabelNameUp[i], "")
            UIHelper.RemoveAllChildren(self.tWidgetHead[i]) -- 清除头像，只保留头像框，不知道为啥ClearTexture无效，所以这里重刷一下
            self.tScriptHead[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.tWidgetHead[i])
            self.tScriptHead[i]:SetTouchEnabled(false)
            UIHelper.UnBindUIEvent(togPlayer, EventType.OnSelectChanged)
        end
    end

    UIHelper.LayoutDoLayout(self.WidgetPlayerList)
end

function UIWidgetPageBlessList:InitTogElement()
    if not self.tTogElement then
        return
    end
    -- 注意这里self.tTogElement的顺序要与BlessElementType的顺序一致
    for _, nType in pairs(BlessElementType) do
        local nElementType = nType
        local togElement = self.tTogElement[nType]
        UIHelper.BindUIEvent(togElement, EventType.OnClick, function()
            self:SetElementFilter(nElementType)
        end)
    end
end

-- self.tTogPlayer
function UIWidgetPageBlessList:InitTogPlayer()
    self.tWidgetHead = {}
    self.tLabelNameNormal = {}
    self.tLabelNameUp = {}

    for i, togPlayer in ipairs(self.tTogPlayer or {}) do
        local widgetHead = UIHelper.GetChildByName(togPlayer, "WidgetHead")
        local labelNameNormal = UIHelper.GetChildByPath(togPlayer, "WidgetNormal/LabelName")
        local labelNameUp = UIHelper.GetChildByPath(togPlayer, "WidgetUp/LabelName")
        self.tWidgetHead[i] = widgetHead
        self.tLabelNameNormal[i] = labelNameNormal
        self.tLabelNameUp[i] = labelNameUp
    end
end

function UIWidgetPageBlessList:UpdateInfo()
    self.tFilter = nil
    self.nElementFilter = nil

    UIHelper.SetSelected(self.TogDetailedDesc, ArenaTowerData.bShowBlessDetailDesc, false)
    UIHelper.SetSelected(self.TogAll, true, false)

    self:UpdateElementPoint()
    self:UpdateBlessList()
end

function UIWidgetPageBlessList:UpdateElementPoint()
    if not self.tLabelElement then
        return
    end

    -- 注意这里self.tLabelElement的顺序要与BlessElementType的顺序一致
    local tElementPoint = self:GetElementPointInfo()
    for _, nType in pairs(BlessElementType) do
        UIHelper.SetString(self.tLabelElement[nType], tElementPoint[nType] or 0)
    end

    if self.scriptSideDetail then
        self.scriptSideDetail:OnEnter(tElementPoint)
    end
end

function UIWidgetPageBlessList:UpdateBlessList()
    if not self.bInit then
        return
    end

    self.poolBlessCard:RecycleAll()
    -- UIHelper.RemoveAllChildren(self.LayoutMainBlessList)
    -- UIHelper.RemoveAllChildren(self.LayoutSubBlessList)
    -- UIHelper.RemoveAllChildren(self.ScrollViewListNew)
    self.lastSelectCard = nil
    self:OnClearSelect()

    local nNumMainSkill = 0
    local nNumSubSkill = 0

    -- FilterDef.BlessCard 1-星级4321, 2-技能类型 主动/被动, 3-属性数量 单属性/双属性, 4-强化状态 全部/可强化/已强化
    for _, tCardData in ipairs(self.tBlessCardList or {}) do
        local bFilter = false
        local nStarFlag = ArenaTowerData.MAX_BLESS_STAR + 1 - tCardData.nStar --4321顺序
        local nMainSkillFlag = tCardData.bMainSkill and 1 or 2
        local nSingleElementFlag = not tCardData.nElementType2 and 1 or 2
        local nCanEnhancedFlag = ((tCardData.bCanEnhanced and not tCardData.bEnhanced) and 2) or (tCardData.bEnhanced and 3)
        if self.nElementFilter and self.nElementFilter ~= tCardData.nElementType1 and self.nElementFilter ~= tCardData.nElementType2 then
            bFilter = true
        elseif self.tFilter then
            if self.tFilter[1] and not table.contain_value(self.tFilter[1], nStarFlag) then
                bFilter = true
            elseif self.tFilter[2] and not table.contain_value(self.tFilter[2], nMainSkillFlag) then
                bFilter = true
            elseif self.tFilter[3] and not table.contain_value(self.tFilter[3], nSingleElementFlag) then
                bFilter = true
            elseif self.tFilter[4] and self.tFilter[4][1] ~= 1 and self.tFilter[4][1] ~= nCanEnhancedFlag then
                bFilter = true
            end
        end

        if not bFilter then
            if tCardData.bMainSkill then
                nNumMainSkill = nNumMainSkill + 1
            else
                nNumSubSkill = nNumSubSkill + 1
            end
            -- local parent = tCardData.bMainSkill and self.LayoutMainBlessList or self.LayoutSubBlessList
            local parent = self.ScrollViewListNew
            local _, script = self.poolBlessCard:Allocate(parent)
            local function OnSelected()
                if self.lastSelectCard and self.lastSelectCard ~= script then
                    self.lastSelectCard:SetSelected(false)
                end
                self.lastSelectCard = script
                self:OnSelectBlessCard(tCardData)
            end
            script:SetSelected(false)
            script:OnInitSmallCard(tCardData)
            script:SetClickCallback(function()
                OnSelected()
            end)
            -- 恢复选择
            if self.nSelCardID == tCardData.nCardID then
                script:SetSelected(true)
                OnSelected(tCardData)
            end
        end
    end

    UIHelper.SetString(self.LabelAllNum, nNumMainSkill + nNumSubSkill)
    UIHelper.SetString(self.LabelMainSkillContent, string.format("主动技能 (%d)", nNumMainSkill))
    UIHelper.SetString(self.LabelSubSkillContent, string.format("被动技能 (%d)", nNumSubSkill))

    -- 手动重置Grid Layout高度
    -- UIHelper.SetHeight(self.LayoutMainBlessList, 0)
    -- UIHelper.SetHeight(self.LayoutSubBlessList, 0)

    UIHelper.SetVisible(self.WidgetZhuDong, nNumMainSkill > 0)
    UIHelper.SetVisible(self.WidgetBeiDong, nNumSubSkill > 0)
    self:UpdateEmpty()

    -- UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewList)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewListNew)
end

function UIWidgetPageBlessList:UpdateEmpty()
    local bMainEmpty = not UIHelper.GetVisible(self.WidgetZhuDong)
    local bSubEmpty = not UIHelper.GetVisible(self.WidgetBeiDong)
    local bSelEmpty = self.scriptBlessCardDetail == nil
    local bSkillEmpty = bMainEmpty and bSubEmpty or false
    local bAllEmpty = bSkillEmpty and bSelEmpty or false
    UIHelper.SetVisible(self.WidgetEmptyZhuDong, bMainEmpty and not bSkillEmpty)
    UIHelper.SetVisible(self.WidgetEmptyBeiDong, bSubEmpty and not bSkillEmpty)
    UIHelper.SetVisible(self.WidgetEmptyBlessCardL, bSelEmpty)
    UIHelper.SetVisible(self.WidgetEmpty, bSkillEmpty)
end

function UIWidgetPageBlessList:OnSelectBlessCard(tCardData)
    if not tCardData then
        return
    end

    self.nSelCardID = tCardData.nCardID
    if self.fnSelectBlessCardCallback then
        self.fnSelectBlessCardCallback(tCardData)
        return
    end

    UIHelper.SetVisible(self.TogDetailedDesc, ArenaTowerData.CardHasShortDesc(tCardData))
    self.scriptBlessCardDetail = self.scriptBlessCardDetail or UIHelper.AddPrefab(PREFAB_ID.WidgetBlessCardL, self.WidgetBlessCardShell)
    self.scriptBlessCardDetail:OnInitLargeCard(tCardData)
    self:UpdateEmpty()
end

function UIWidgetPageBlessList:OnClearSelect()
    if self.fnClearSelect then
        self.fnClearSelect()
        return
    end

    UIHelper.SetVisible(self.TogDetailedDesc, false)
    UIHelper.RemoveAllChildren(self.WidgetBlessCardShell)
    self.scriptBlessCardDetail = nil
    self:UpdateEmpty()
end

function UIWidgetPageBlessList:SetElementFilter(nElementType)
    if self.nElementFilter == nElementType then
        return
    end

    self.nElementFilter = nElementType
    self:UpdateBlessList()
    self:UpdateFilterBtnState()
end

function UIWidgetPageBlessList:UpdateFilterBtnState()
    local bHasFilter = false
    if self.tFilter then
        for i, v in ipairs(FilterDef.BlessCard) do
            if i == 4 then
                if self.tFilter[i][1] ~= 1 then
                    bHasFilter = true
                    break
                end
            else
                if #self.tFilter[i] ~= #v.tbList then
                    bHasFilter = true
                    break
                end
            end
        end
    end
    UIHelper.SetVisible(self.ImgIcon, not bHasFilter)
    UIHelper.SetVisible(self.ImgIconFiltered, bHasFilter)
end

function UIWidgetPageBlessList:GetElementPointInfo()
    if self.tPlayerStats then
        for _, tStats in ipairs(self.tPlayerStats) do
            if tStats.dwPlayerID == self.nSelPlayerID then
                return tStats.tElementPoint
            end
        end
    else
        local tElementPoint, _, _ = ArenaTowerData.GetElementPointInfo()
        return tElementPoint
    end
end

function UIWidgetPageBlessList:SetSelectBlessCardCallback(fnCallback)
    self.fnSelectBlessCardCallback = fnCallback
end

function UIWidgetPageBlessList:SetClearSelectCallback(fnCallback)
    self.fnClearSelect = fnCallback
end

-- 外面关闭按钮层级问题不好处理，这里留个回调隐藏一下
function UIWidgetPageBlessList:SetOutsideCloseBtnSetVisibleCallback(fnCallback)
    self.fnOutsideCloseBtnSetVisible = fnCallback
end

return UIWidgetPageBlessList