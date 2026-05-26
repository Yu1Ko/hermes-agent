-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIActivityInfo
-- Date: 2022-12-08 09:19:20
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIActivityInfo = class("UIActivityInfo")

function UIActivityInfo:OnEnter(tbActiveInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if tbActiveInfo then
        local bFirstUpdate = self.AwardPool == nil
        self.AwardPool = self.AwardPool or PrefabPool.New(PREFAB_ID.WidgetAwardItem1)
        self.nBaseHeight = self.nBaseHeight or UIHelper.GetHeight(self.ScrollViewActivityDetail)
        self.tbActiveInfo = tbActiveInfo
        self.szTarget, self.nQuestCount = ActivityData.GetActivityTarget(self.tbActiveInfo)

        if bFirstUpdate then
            self:DelayUpdateInfo()
        else
            self:UpdateInfo()
        end
    end
end

function UIActivityInfo:OnExit()
    self.bInit = false
    self:UnRegEvent()

    if self.AwardPool then self.AwardPool:Dispose() end
    self.AwardPool = nil
end

function UIActivityInfo:BindUIEvent()
    -- UIHelper.TableView_addCellAtIndexCallback(self.TableViewAward, function(tableView, nIndex, script, node, cell)
    --     local AwardInfo = self.tbAwardInfo[nIndex]
    --     if type(AwardInfo.szCount) == "number" then
    --         local tLine = Table_GetCalenderActivityAwardIcon(AwardInfo.szType)
    --         local szName = UIHelper.GBKToUTF8(tLine.szDes)
    --         local nCount = AwardInfo.szCount
    --         if szName == g_tStrings.Quest.STR_QUEST_CAN_GET_MONEY then
    --             nCount = nCount * 10000
    --         end
    --         script:OnEnter(szName, nCount)
    --     elseif type(AwardInfo.szCount) == "string" then
    --         local tBox = string.split(AwardInfo.szCount, ";")
    --         local nItemTabType = tBox[1]
    --         local nItemIndex = tBox[2]
    --         local nCount = tonumber(tBox[3]) or 0
    --         local ItemInfo = GetItemInfo(nItemTabType, nItemIndex)
    --         if ItemInfo then
    --             local szName = UIHelper.GBKToUTF8(ItemInfo.szName)
    --             script:OnEnter(szName, nCount, nItemTabType, nItemIndex)
    --         end
    --     end
    --     if script and self.WidgetItemTip then
    --         script:SetClickCallback(function(nTabType, nTabID)
    --             TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
    --             local _, itemTips = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, script._rootNode, TipsLayoutDir.AUTO)
    --             itemTips:OnInitWithTabID(nTabType, nTabID)
    --             itemTips:SetBtnState({})

    --             -- UIHelper.SetVisible(self.BtncCoseTip, (nTabType ~= nil))
    --             if nTabType and nTabID then
    --                 self.CurSelectedItemView = script
    --             end
    --         end)
    --     end
    -- end)

    UIHelper.BindUIEvent(self.BtnStore, EventType.OnClick, function()
        ShopData.OpenSystemShopGroup(self.tbActiveInfo.dwShopGroupID, self.tbActiveInfo.dwDefaultShopID)
    end)
end

function UIActivityInfo:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        self.nBaseHeight = UIHelper.GetHeight(self.ScrollViewActivityDetail)
        self:DelayUpdateInfo()
    end)
end

function UIActivityInfo:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIActivityInfo:DelayUpdateInfo()
    Timer.DelTimer(self, self.nUpdateTimer)
    self.nUpdateTimer = Timer.AddFrame(self, 2, function ()
        self:UpdateInfo()
    end)
end


function UIActivityInfo:UpdateInfo()
    self:HideItemTip()
    self:UpdateActiveName()
    self:UpdateActiveDesc()
    self:UpdateActiveTarget()
    self:UpdateActiveDetail()
    self:UpdateActiveAward()
    self:UpdateBtnState()
    self:UpdateTitleBg()

    local bShowAward = #self.tbAwardInfo ~= 0
    local nAddHeight = UIHelper.GetHeight(self.ScrollViewMaskAward) + UIHelper.GetHeight(self.WidgetRewardTitle)
    local nScrollViewHeight = self.nBaseHeight + (bShowAward and 0 or nAddHeight)

    UIHelper.SetHeight(self.ScrollViewActivityDetail, nScrollViewHeight)
    UIHelper.SetSwallowTouches(self.ScrollViewActivityDetail, true)

    UIHelper.ScrollViewDoLayout(self.ScrollViewActivityDetail)
    UIHelper.ScrollToTop(self.ScrollViewActivityDetail, 0)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewActivityDetail, self.WidgetArrow)
end

function UIActivityInfo:UpdateTitleBg()
    local nType = ActivityData.GetActivityType(self.tbActiveInfo)
    UIHelper.SetSpriteFrame(self.ImgTitleBg, ACTIVITY_TITLE_BG[nType])
end

function UIActivityInfo:UpdateActiveName()
    UIHelper.SetString(self.LabelActivityName, UIHelper.GBKToUTF8(self.tbActiveInfo.szName))
end

function UIActivityInfo:UpdateActiveDesc()

    UIHelper.SetString(self.LabelTargetTitle, self.nQuestCount == 1 and g_tStrings.ACTIVE_POPULARIZE_QUEST_DESC or g_tStrings.ACTIVE_POPULARIZE_DETAIL)
    local szText = self.tbActiveInfo.szText
    local szMobileText = self.tbActiveInfo.szMobileText
    if szMobileText ~= "" then
        szText = szMobileText
    end
    szText = ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(szText), false, "\\")
    UIHelper.SetRichText(self.RichTextDesc, szText)
    UIHelper.LayoutDoLayout(self.LayoutTargetContent)
    UIHelper.LayoutDoLayout(self.LayoutDesc)
end

--去掉目标显示，和端游同步
function UIActivityInfo:UpdateActiveTarget()

    if not self.tbActiveInfo.szQuestID then
        UIHelper.SetVisible(self.LayoutTarget, false)
        return
    end

    local tbQuestID = string.split(self.tbActiveInfo.szQuestID, ";")

    if tonumber(tbQuestID[1]) == -1 then
        UIHelper.SetVisible(self.LayoutTarget, false)
        return
    end

    tbQuestID = ActivityData.GetShowQuestID(tbQuestID)

    if not tbQuestID or table.is_empty(tbQuestID) then
        UIHelper.SetVisible(self.LayoutTarget, false)
		return
	end


    local szText = ""
    for nIndex, nQuestID in ipairs(tbQuestID) do
        nQuestID = tonumber(nQuestID)
        local _, nQuestState = ActivityData.GetQuestState(nQuestID)
        nQuestState = nQuestState == QUEST_PHASE.FINISH and 1 or 0
        local tQuestString = Table_GetQuestStringInfo(nQuestID)
        szText = szText .. UIHelper.GBKToUTF8(tQuestString.szName) .. FormatString(g_tStrings.STR_ADD_FRINEND_TEXT_NUM, nQuestState, 1)
        if nIndex ~= #tbQuestID then
            szText = szText.."\n"
        end
    end
    
    UIHelper.SetRichText(self.RichTextTarget, szText)
    UIHelper.SetVisible(self.LayoutTarget, true)
    UIHelper.LayoutDoLayout(self.LayoutTarget)
end

--参与方式
function UIActivityInfo:UpdateActiveDetail()
    local szDetailMap = self.tbActiveInfo.szDetailMap

    local szMobileDetailMap = self.tbActiveInfo.szMobileDetailMap
    if szMobileDetailMap ~= "" then
        szDetailMap = szMobileDetailMap
    end

    local szText = ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(szDetailMap), false, "\\")
    UIHelper.SetRichText(self.RichTextDetail, szText, true)
    UIHelper.LayoutDoLayout(self.LayoutDetail)
end


function UIActivityInfo:RemoveAllAward()
    if self.tbAwardNode then
        for index, node in ipairs(self.tbAwardNode) do
            self.AwardPool:Recycle(node)
        end
    end
    self.tbAwardNode = {}
end

function UIActivityInfo:UpdateActiveAward()

    self.tbAwardInfo = ActivityData.GetAwardInfo(self.tbActiveInfo.dwID)
    local bShowAward = #self.tbAwardInfo ~= 0
    UIHelper.SetVisible(self.WidgetRewardTitle, bShowAward)
    UIHelper.SetVisible(self.ScrollViewMaskAward, bShowAward)

    self:RemoveAllAward()

    for nIndex, AwardInfo in ipairs(self.tbAwardInfo) do
        local node, script = self.AwardPool:Allocate(self.ScrollViewMaskAward)

        if type(AwardInfo.szCount) == "number" then
            local tLine = Table_GetCalenderActivityAwardIcon(AwardInfo.szType)
            local szName = UIHelper.GBKToUTF8(tLine.szDes)
            local nCount = AwardInfo.szCount
            if szName == g_tStrings.Quest.STR_QUEST_CAN_GET_MONEY then
                nCount = nCount * 10000
            end
            script:OnEnter(szName, nCount)
        elseif type(AwardInfo.szCount) == "string" then
            local tBox = string.split(AwardInfo.szCount, ";")
            local nItemTabType = tBox[1]
            local nItemIndex = tBox[2]
            local nCount = tonumber(tBox[3]) or 0
            local ItemInfo = GetItemInfo(nItemTabType, nItemIndex)
            if ItemInfo then
                local szName = UIHelper.GBKToUTF8(ItemInfo.szName)
                script:OnEnter(szName, nCount, nItemTabType, nItemIndex)
            end
        end
        if script and self.WidgetItemTip then
            script:SetClickCallback(function(nTabType, nTabID)
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
                local _, itemTips = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, script._rootNode, TipsLayoutDir.AUTO)
                itemTips:OnInitWithTabID(nTabType, nTabID)
                itemTips:SetBtnState({})

                -- UIHelper.SetVisible(self.BtncCoseTip, (nTabType ~= nil))
                if nTabType and nTabID then
                    self.CurSelectedItemView = script
                end
            end)
        end
        table.insert(self.tbAwardNode, node)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewMaskAward)
    UIHelper.ScrollToLeft(self.ScrollViewMaskAward)
end

function UIActivityInfo:UpdateBtnState()
    local bVisible = self.tbActiveInfo.dwShopGroupID ~= 0 and self.tbActiveInfo.dwDefaultShopID ~= 0
    UIHelper.SetVisible(self.BtnStore, bVisible)
end

function UIActivityInfo:HideItemTip()
    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
    if self.CurSelectedItemView then
        self.CurSelectedItemView:SetSelected(false)
        self.CurSelectedItemView = nil
    end
end

return UIActivityInfo