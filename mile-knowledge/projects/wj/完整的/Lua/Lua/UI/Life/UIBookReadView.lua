-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBookInfoView
-- Date: 2022-12-09 16:35:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBookInfoView = class("UIBookInfoView")

local CRAFT_ID_READ = 8
function UIBookInfoView:OnEnter(nBookID, nSegmentID, nRecipeID, nItemID, nTargetType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nBookID = nBookID
    self.nSegmentID = nSegmentID
    self.nRecipeID = nRecipeID
    self.nItemID = nItemID
    self.bHasRead = true
    if not nTargetType then
        self.nTargetType = TARGET.ITEM
    else
        self.nTargetType = nTargetType
    end
    self.nMark = Table_GetBookMark(nBookID, nSegmentID)
    self.nTotalPages = Table_GetBookPageNumber(nBookID, nSegmentID)
    self.scriptVerticalContent = UIHelper.GetBindScript(self.WidgetVerticalContent)
    self:UpdateInfo()
end

function UIBookInfoView:OnEnterUnreadBook(nBookID, nSegmentID, tbBookSource, func)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bHasRead = false
    self.nBookID = nBookID
    self.nSegmentID = nSegmentID
    self.tbBookSource = tbBookSource
    self.nMark = Table_GetBookMark(nBookID, nSegmentID)
    self.nTotalPages = Table_GetBookPageNumber(nBookID, nSegmentID)
    self.func = func
    self.scriptVerticalContent = UIHelper.GetBindScript(self.WidgetVerticalContent)
    self:UpdateInfo()
end

function UIBookInfoView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIBookInfoView:BindUIEvent()
    UIHelper.BindUIEvent(self.ButtonClose, EventType.OnClick, function ()
        UIMgr.Close(VIEW_ID.PanelBookInfo)
    end)

    UIHelper.BindUIEvent(self.BtnComplete, EventType.OnClick, function ()
        GetClientPlayer().CastProfessionSkill(8, self.nRecipeID, self.nTargetType, self.nItemID)
        UIMgr.Close(VIEW_ID.PanelBookInfo)
    end)

    UIHelper.BindUIEvent(self.BtnSendToChat, EventType.OnClick, function ()
        if not self.nBookID then return end
        if not self.nSegmentID then return end
        local nBookInfo = BookID2GlobelRecipeID(self.nBookID, self.nSegmentID)
        if not nBookInfo then return end
        ChatHelper.SendBookToChat(nBookInfo)
        UIMgr.Close(self)
    end)
end

function UIBookInfoView:RegEvent()
    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if UIMgr.IsInLayer(nViewID, UILayer.Page) then
            UIMgr.Close(self)
        end
    end)
end

function UIBookInfoView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIBookInfoView:UpdateInfo()
    self:UpdateReadBookInfo()
    self:UpdateBookSource()

    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewArticleInfo, true, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewArticleInfo)
    UIHelper.SetSwallowTouches(self.ScrollViewArticleInfo, true)
    UIHelper.SetVisible(self.BtnComplete, self.nRecipeID ~= nil and not g_pClientPlayer.IsBookMemorized(self.nBookID, self.nSegmentID))

    self.VigorScript = self.VigorScript or UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.WidgetJingLi)
    self.VigorScript:SetCurrencyType(CurrencyType.Vigor)
    local nCurrentVigor = g_pClientPlayer.nVigor + g_pClientPlayer.nCurrentStamina
	local nMaxVigor = g_pClientPlayer.GetMaxVigor() + g_pClientPlayer.nMaxStamina
    self.VigorScript:SetLableCount(nCurrentVigor..'/'..nMaxVigor)
    UIHelper.CascadeDoLayoutDoWidget(UIHelper.GetParent(self.WidgetJingLi), true)

    if self.nMark == 2 and self.bHasRead then
        self.nTimerID = self.nTimerID or Timer.AddFrameCycle(self, 5, function ()
            self:OnFrameBreathe()
        end)
    end
end

function UIBookInfoView:OnFrameBreathe()
    if not self.scriptVerticalContent then return end
    local nPercent = UIHelper.GetScrollPercent(self.scriptVerticalContent.ScrollViewVertical)
    local nChildCount = UIHelper.GetChildrenCount(self.scriptVerticalContent.ScrollViewVertical)
    UIHelper.SetVisible(self.WidgetArrowLeft, nChildCount > 13 and nPercent > 2)
    UIHelper.SetVisible(self.WidgetArrowRight,nChildCount > 13 and nPercent < 98)
end

function UIBookInfoView:UpdateReadBookInfo()
    local nPageID = 1
    if nPageID < 1 or nPageID > self.nTotalPages then
        return
    end
    local szBookName = Table_GetSegmentName(self.nBookID, self.nSegmentID)
    szBookName = UIHelper.GBKToUTF8(szBookName)
    szBookName = CraftData.BookNameOptimize(szBookName)
    self.szBookName = szBookName

    UIHelper.SetString(self.LabelTitle, szBookName)

    local szDesc = Table_GetBookDesc(self.nBookID, self.nSegmentID)
    szDesc = UIHelper.GBKToUTF8(szDesc)
    UIHelper.SetString(self.LabelDes, szDesc)
    UIHelper.SetVisible(self.LabelDes, not self.bHasRead)
    local szContent = ""
    if self.bHasRead then
        for nID = 1, self.nTotalPages, 1 do
            local szNewContent = Table_GetBookContent(Table_GetBookPageID(self.nBookID, self.nSegmentID, nID - 1))
            if self.nMark ~= 2 then
                szContent = szContent .. szNewContent
            else
                szContent = szContent .." \n".. szNewContent
            end
        end
        szContent = UIHelper.GBKToUTF8(szContent)
        szContent = self:TrimLineBreak(szContent)
    else
        szContent = "获得后可阅读详情"
    end

    UIHelper.SetVisible(self.ScrollViewArticleInfo, false)
    UIHelper.SetVisible(self.WidgetVerticalContent, false)
    if self.nMark == 3 and self.bHasRead then
        UIHelper.SetVisible(self.ImgArticleInfoPicture02, true)
        local szImgPath = UIHelper.GetIconPathByIconID(tonumber(szContent))
        self.ImgArticleInfoPicture02:setTexture(szImgPath, false)
        UIHelper.SetVisible(self.LabelArticleInfo02, false)
        UIHelper.SetVisible(self.ScrollViewArticleInfo, true)
    elseif self.nMark == 2 and self.bHasRead then
        UIHelper.SetVisible(self.WidgetVerticalContent, true)
        if not self.bHasRead then szContent = szDesc .. " \n" .. szContent end
        self.scriptVerticalContent:OnEnter(szContent)
    else
        UIHelper.SetVisible(self.ImgArticleInfoPicture02, false)
        UIHelper.SetString(self.LabelArticleInfo02, szContent)
        UIHelper.SetVisible(self.ScrollViewArticleInfo, true)
    end
    UIHelper.SetVisible(self.WidgetTitle, not self.bHasRead)

    local recipe = GetRecipe(CRAFT_ID_READ, self.nBookID, self.nSegmentID)
    local szReadLevel = string.format("适合阅读%d级", recipe.dwRequireProfessionLevel)
    UIHelper.SetString(self.LabelLevel, szReadLevel)
end

function UIBookInfoView:UpdateBookSource()
    if not self.tbBookSource then
        return
    end
    local tbBookSource = self.tbBookSource
    local player = GetClientPlayer()
    if #tbBookSource.tQuests > 0 or #tbBookSource.tDoodad > 0 or #tbBookSource.tSourceMap > 0 or #tbBookSource.tSourceNpc > 0 or #tbBookSource.tBoss > 0 or tbBookSource.bSourceTrade then
        -- 交易行
        if tbBookSource.bSourceTrade then
            local szText = "<color=#FFFAA3>" .. g_tStrings.ITEM_TIP_SOURCE_TRADE .. "</color>"
            local szLinkInfo = string.format("SourceTradeWithName/%s", UIHelper.GBKToUTF8(Table_GetSegmentName(self.nBookID, self.nSegmentID)))
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBookSourceCell, self.ScrollViewArticleInfo, szLinkInfo)
            script:SetCellName(szText)
        end
        -- 任务
        if #tbBookSource.tQuests > 0 then
            for k, v in ipairs(tbBookSource.tQuests) do
                local szAdd = player.GetQuestPhase(v) == 3 and g_tStrings.STR_BOOK_TIP_FINISHED or ""
                local szText = "<color=#FFFAA3>" .. g_tStrings.STR_QUEST .. "</color>"
                szText = szText .. string.format("<href=%s><color=#95FF95>[%s]%s</c></href>", v, UIHelper.GBKToUTF8(Table_GetQuestStringInfo(v).szName), szAdd)
                local szLinkInfo = string.format("QuestTip/%s/1", v)
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBookSourceCell, self.ScrollViewArticleInfo, szLinkInfo)
                script:SetCellName(szText)
            end
        end
        -- 碑铭
        if #tbBookSource.tDoodad > 0 then
            for k, v in ipairs(tbBookSource.tDoodad) do
                local dwMapID = v[1]
                local dwTemplateID = v[2]
                local szMapName = UIHelper.GBKToUTF8(Table_GetMapName(dwMapID))
                local szDoodadName = Table_GetDoodadName(dwTemplateID, 0)
                szDoodadName = UIHelper.GBKToUTF8(szDoodadName)
                local szLinkInfo = string.format("CraftMarkDoodad/%d/%d", dwMapID, dwTemplateID)
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBookSourceCell, self.ScrollViewArticleInfo, szLinkInfo)
                local szText = "<color=#FFFAA3>" .. g_tStrings.STR_BOOK_TIP_INSCRIPTIONS .. "</color>"
                szText = szText .. string.format("<color=#95FF95>[%s](%s)</c>", szDoodadName, szMapName)
                script:SetCellName(szText)
            end
        end
        --人形怪掉落
        if #tbBookSource.tSourceMap > 0 then
            for k, v in ipairs(tbBookSource.tSourceMap) do
                local dwMapID = v
                local szMapName = Table_GetMapName(dwMapID)
                local szText = "<color=#FFFAA3>" .. g_tStrings.STR_BOOK_TIP_MAP .. "</color>"
                szText = szText .. string.format("<color=#95FF95>[%s]</c>", UIHelper.GBKToUTF8(szMapName))
                local szLinkInfo = string.format("MiddleMap/%s/0", dwMapID)
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBookSourceCell, self.ScrollViewArticleInfo, szLinkInfo)
                script:SetCellName(szText)
            end
        end
        --商店
        if #tbBookSource.tSourceNpc > 0 then
            for k, v in ipairs(tbBookSource.tSourceNpc) do
                local dwMapID = v[1]
                local dwTemplateID = v[2]
                local szMapName = Table_GetMapName(dwMapID)
                szMapName = UIHelper.GBKToUTF8(szMapName)
                local szNpcName = Table_GetNpcTemplateName(dwTemplateID)
                szNpcName = UIHelper.GBKToUTF8(szNpcName)
                local szText = "<color=#FFFAA3>" .. "NPC商店" .. "</color>"
                szText = szText .. string.format("<color=#95FF95>[%s](%s)</c>", szNpcName, szMapName)
                local szLinkInfo = string.format("CraftMarkNpc/%s/%s", dwMapID, dwTemplateID)
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBookSourceCell, self.ScrollViewArticleInfo, szLinkInfo)
                script:SetCellName(szText)
            end
        end
        --首领（秘境）
        if #tbBookSource.tBoss > 0 then
            for k, v in ipairs(tbBookSource.tBoss) do
                local dwMapID = v[1]
                local dwBossIndex = v[2]
                local tBossInfo = Table_GetDungeonBossByBossIndex(dwBossIndex)
                local szMapName = UIHelper.GBKToUTF8(Table_GetMapName(dwMapID))
                local szBossName = UIHelper.GBKToUTF8(tBossInfo.szName)
                local szText = "<color=#FFFAA3>" .. g_tStrings.STR_BOOK_TIP_BOSS .. "</color>"
                szText = string.format("<color=#95FF95>[%s](%s)</c>", szBossName, szMapName)
                local szLinkInfo = string.format("FBlist/%s/%s", dwMapID, dwBossIndex)
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBookSourceCell, self.ScrollViewArticleInfo, szLinkInfo)
                script:SetCellName(szText)
            end
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewArticleInfo)
end

function UIBookInfoView:TrimLineBreak(szContent)
    local tStrings = string.split(szContent, '\n')
    szContent = ""
    for _, str in ipairs(tStrings) do
        if #str > 0 then
            szContent = szContent..str..'\n'
        end
    end

    return szContent
end

return UIBookInfoView