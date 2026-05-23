-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBookCopyView
-- Date: 2022-12-12 16:29:55
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBookCopyView = class("UIBookCopyView")
local CRAFT_ID_READ = 8
function UIBookCopyView:OnEnter(nBookID, nSegmentID, tbBookSource, func)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nBookID = nBookID
    self.nSegmentID = nSegmentID
    self.bHasRead = true
    self.tbBookSource = tbBookSource
    self.nMark = Table_GetBookMark(nBookID, nSegmentID)
    self.nTotalPages = Table_GetBookPageNumber(nBookID, nSegmentID)
    self.func = func
    self:UpdateInfo()
end

function UIBookCopyView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIBookCopyView:BindUIEvent()
    UIHelper.BindUIEvent(self.ButtonClose, EventType.OnClick, function ()
        UIMgr.Close(VIEW_ID.PanelBookInfo)
        if self.func then
            self.func()
        end
    end)
    UIHelper.BindUIEvent(self.BtnCopy, EventType.OnClick, function ()
        local recipe   = GetRecipe(12, self.nBookID, self.nSegmentID)
        local itemInfo = GetItemInfo(recipe.dwCreateItemType, recipe.dwCreateItemIndex)

        local tParam = {
            szFormat = self.szBookName.."(%d/%d)",       -- 格式化显示文本
            nDuration = 5,                  -- 持续时长, 单位为秒
            nStartVal = 0,                  -- 起始值
            nEndVal = 100,                  -- 结束值
            dwTabType = recipe.dwCreateItemType,
            dwIndex = recipe.dwCreateItemIndex,
            fnCancel = function ()
                GetClientPlayer().StopCurrentAction()
            end
          --  fnStop = function(bCompleted),  -- 停止回调, bCompleted为是否完成读条
        }
        UIMgr.Open(VIEW_ID.PanelSystemPrograssBar, tParam)
        GetClientPlayer().CastProfessionSkill(12, self.nBookID, self.nSegmentID)
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

function UIBookCopyView:RegEvent()
    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        if self.scriptItemTip then
            self.scriptItemTip:OnInit()
        end
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.scriptItemTip then
            self.scriptItemTip:OnInit()
        end
    end)
end

function UIBookCopyView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIBookCopyView:UpdateInfo()
    self:UpdateBookInfo()
    self:UpdateCondition()
    self:UpdateBookSource()
end

function UIBookCopyView:UpdateBookInfo()
    local nPageID = 1
    if nPageID < 1 or nPageID > self.nTotalPages then
        return
    end
    local szBookName = Table_GetSegmentName(self.nBookID, self.nSegmentID)
    szBookName = UIHelper.GBKToUTF8(szBookName)
    szBookName = CraftData.BookNameOptimize(szBookName)
    self.szBookName = szBookName

    local nCharNum = GetStringCharCount(szBookName)
    local bNeedSplit = nCharNum > 9
    UIHelper.SetVisible(self.LabelTitle, not bNeedSplit)
    UIHelper.SetVisible(self.LabelTitlePart1, bNeedSplit)
    UIHelper.SetVisible(self.LabelTitlePart2, bNeedSplit)

    if not bNeedSplit then
        UIHelper.SetString(self.LabelTitle, szBookName)
    else
        local szName1 = UTF8SubString(szBookName, 1, 9)
        local szName2 = UTF8SubString(szBookName, 10, #szBookName - 9)
        UIHelper.SetString(self.LabelTitlePart1, szName1)
        UIHelper.SetString(self.LabelTitlePart2, szName2)
    end

    local szDesc = Table_GetBookDesc(self.nBookID, self.nSegmentID)
    szDesc = UIHelper.GBKToUTF8(szDesc)
    UIHelper.SetString(self.LabelDes, szDesc)

    local szContent = ""
    if self.bHasRead then
        for nID = 1, self.nTotalPages, 1 do
            if nID ~= 1 then
                szContent = szContent .. '\n'
            end
            szContent = szContent .. Table_GetBookContent(Table_GetBookPageID(self.nBookID, self.nSegmentID, nID - 1))
        end
        szContent = UIHelper.GBKToUTF8(szContent)
        szContent = self:TrimLineBreak(szContent)
    else
        szContent = "获得后可阅读详情"
    end

    if self.nMark == 3 and self.bHasRead then
        UIHelper.SetItemIconByIconID(self.ImgArticleInfoPicture01, tonumber(szContent))
        UIHelper.SetVisible(self.LabelArticleInfo, false)
    else
        UIHelper.SetVisible(self.ImgArticleInfoPicture01, false)
        UIHelper.SetString(self.LabelArticleInfo, szContent)
    end
    local recipe = GetRecipe(CRAFT_ID_READ, self.nBookID, self.nSegmentID)
    local szReadLevel = string.format("适合阅读%d级", recipe.dwRequireProfessionLevel)
    UIHelper.SetString(self.LabelLevel, szReadLevel)

    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewArticleInfo, true, true)
    UIHelper.ScrollViewDoLayout(self.ScrollViewArticleInfo)
    UIHelper.ScrollToTop(self.ScrollViewArticleInfo, 0)
end

function UIBookCopyView:UpdateCondition()
    local bCanCopy = true
    local player = GetClientPlayer()
    local recipe = GetRecipe(12, self.nBookID, self.nSegmentID)
    if not recipe then
        return
    end
    if not self.bHasRead then
        UIHelper.SetVisible(self.WidgetAnchorBtn, false)
        return
    else
        UIHelper.SetVisible(self.WidgetAnchorBtn, true)
    end
    -- local nIndex = Table_GetBookItemIndex(self.nBookID, self.nSegmentID)
    -- local itemInfo = GetItemInfo(nTabtype, nIndex)
    local nLevel = player.GetProfessionLevel(8)
    local szContent = ""
    if nLevel < recipe.dwRequireProfessionLevel then
        bCanCopy = false
        szContent = "<color=#FF7676>".."需求阅读".. recipe.dwRequireProfessionLevel .. "级 </c>"
    else
        szContent = "<color=#245460>".."需求阅读".. recipe.dwRequireProfessionLevel .. "级 </c>"
    end
    if recipe.dwProfessionIDExt ~= 0 then
        local ProfessionExt = GetProfession(recipe.dwProfessionIDExt);
        if ProfessionExt then
            local nExtLevel = player.GetProfessionLevel(recipe.dwProfessionIDExt)
            local content = Table_GetProfessionName(recipe.dwProfessionIDExt)..recipe.dwRequireProfessionLevelExt.."级"
            if nExtLevel < recipe.dwRequireProfessionLevelExt then
                bCanCopy = false
                szContent = szContent.." ".."<color=#FF7676>"..content.."</c>"
            else
                szContent = szContent.." ".."<color=#245460>"..content.."</c>"
            end
        end
    end
    if recipe.nRequirePlayerLevel and recipe.nRequirePlayerLevel ~= 0 then
        local content = " 角色等级"..recipe.nRequirePlayerLevel.."级"
        if player.nLevel < recipe.nRequirePlayerLevel then
            bCanCopy = false
            szContent = szContent.."<color=#FF7676>"..content.."</c>"
        else
            szContent = szContent.."<color=#245460>"..content.."</c>"
        end
    end
    UIHelper.SetRichText(self.LabelAcquisitionsTips,  szContent)

    local szVigor = "<color=#245460>%d</c>"
    if not player.IsVigorAndStaminaEnough(recipe.nVigor) then
        szVigor = "<color=#FF7676>%d</c>"
        bCanCopy = false
    end
    UIHelper.SetRichText(self.LabelConsumeNum, string.format(szVigor, recipe.nVigor))
    UIHelper.LayoutDoLayout(self.WidgetConsumeNum)

    UIHelper.RemoveAllChildren(self.LayoutPropBox)
    for nIndex = 1, 4, 1 do
        local nType  = recipe["dwRequireItemType"..nIndex]
        local nID	 = recipe["dwRequireItemIndex"..nIndex]
        local nNeed  = recipe["dwRequireItemCount"..nIndex]
        if nNeed > 0 then
            local ItemRequire = GetItemInfo(nType, nID)
            local szItemName = ItemData.GetItemNameByItemInfo(ItemRequire)
            local nCount = player.GetItemAmount(nType, nID)
            local Script = UIHelper.AddPrefab(PREFAB_ID.WidgetItemWithName, self.LayoutPropBox)
            Script:RegisterSelectEvent(function (bSelected)
                if self.scriptItemTip then
                    self.scriptItemTip:OnInit()
                end
                self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetTip)
                self.scriptItemTip:OnInitWithTabID(nType, nID)
                self.scriptItemTip:SetBtnState({})
            end)
            UIHelper.SetAnchorPoint(Script._rootNode, 0, 1)
            Script:SetLabelItemName(UIHelper.GBKToUTF8(szItemName))
            Script:SetImgIcon(UIHelper.GetIconPathByItemInfo(ItemRequire))
            if nNeed > nCount then
                Script:SetLableCount(nCount.."/"..nNeed)
                Script:SetTextColor(cc.c3b(255,133,125))
                if nCount < nNeed then
                    Script:SetTextColor(cc.c3b(0xff,0x76,0x76))
                    Script:SetLabelCountColor(cc.c3b(0xff,0x76,0x76))
                end
                bCanCopy = false
            else
                Script:SetLableCount(nCount.."/"..nNeed)
            end
            UIHelper.RemoveAllChildren(Script.ToggleSelect) -- 交互要求，手动移除光圈
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutPropBox)
    if bCanCopy then
       UIHelper.SetButtonState(self.BtnCopy, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnCopy, BTN_STATE.Disable)
    end
end

function UIBookCopyView:UpdateBookSource()
    if not self.tbBookSource then
        return
    end
    UIHelper.RemoveAllChildren(self.LayoutSource)
    local tbBookSource = self.tbBookSource
    local player = GetClientPlayer()
    if #tbBookSource.tQuests > 0 or #tbBookSource.tDoodad > 0 or #tbBookSource.tSourceMap > 0 or #tbBookSource.tSourceNpc > 0 or #tbBookSource.tBoss > 0 then
        -- 任务
        if #tbBookSource.tQuests > 0 then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBookSource, self.LayoutSource)
            script:SetTitle(g_tStrings.STR_QUEST)
            for k, v in ipairs(tbBookSource.tQuests) do
                local szAdd = player.GetQuestPhase(v) == 3 and g_tStrings.STR_BOOK_TIP_FINISHED or ""
                local szText = "[" .. UIHelper.GBKToUTF8(Table_GetQuestStringInfo(v).szName) .. "]" .. szAdd
                local szLinkInfo = string.format("QuestTip/%s/1", v)
                script = UIHelper.AddPrefab(PREFAB_ID.WidgetBookSourceCell, self.LayoutSource, szLinkInfo)
                script:SetCellName(szText)
            end
        end
        -- 碑铭
        if #tbBookSource.tDoodad > 0 then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBookSource, self.LayoutSource)
            script:SetTitle(g_tStrings.STR_BOOK_TIP_INSCRIPTIONS)
            for k, v in ipairs(tbBookSource.tDoodad) do
                local dwMapID = v[1]
                local dwTemplateID = v[2]
                local szMapName = UIHelper.GBKToUTF8(" (" .. Table_GetMapName(dwMapID) .. ")")
                local szDoodadName = Table_GetDoodadName(dwTemplateID, 0)
                szDoodadName = UIHelper.GBKToUTF8(szDoodadName)
                local szLinkInfo = string.format("CraftMarkDoodad/%d/%d", dwMapID, dwTemplateID)
                script = UIHelper.AddPrefab(PREFAB_ID.WidgetBookSourceCell, self.LayoutSource, szLinkInfo)
                script:SetCellName("["..szDoodadName.."]"..szMapName)
            end
        end
        --人形怪掉落
        if #tbBookSource.tSourceMap > 0 then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBookSource, self.LayoutSource)
            script:SetTitle(g_tStrings.STR_BOOK_TIP_MAP)
            for k, v in ipairs(tbBookSource.tSourceMap) do
                local dwMapID = v
                local szMapName = Table_GetMapName(dwMapID)
                local szText = UIHelper.GBKToUTF8(szMapName)
                local szLinkInfo = string.format("MiddleMap/%s/0", dwMapID)
                script = UIHelper.AddPrefab(PREFAB_ID.WidgetBookSourceCell, self.LayoutSource, szLinkInfo)
                script:SetCellName(szText)
            end
        end
        --商店
        if #tbBookSource.tSourceNpc > 0 then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBookSource, self.LayoutSource)
            script:SetTitle("NPC商店")
            for k, v in ipairs(tbBookSource.tSourceNpc) do
                local dwMapID = v[1]
                local dwTemplateID = v[2]
                local szMapName = Table_GetMapName(dwMapID)
                szMapName = UIHelper.GBKToUTF8(szMapName)
                local szNpcName = Table_GetNpcTemplateName(dwTemplateID)
                szNpcName = UIHelper.GBKToUTF8(szNpcName)
                local szText = string.format("[%s](%s)\n", szNpcName, szMapName)
                local szLinkInfo = string.format("CraftMarkNpc/%s/%s", dwMapID, dwTemplateID)
                script = UIHelper.AddPrefab(PREFAB_ID.WidgetBookSourceCell, self.LayoutSource, szLinkInfo)
                script:SetCellName(szText)
            end
        end
        --首领（秘境）
        if #tbBookSource.tBoss > 0 then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBookSource, self.LayoutSource)
            script:SetTitle(g_tStrings.STR_BOOK_TIP_BOSS)
            for k, v in ipairs(tbBookSource.tBoss) do
                local dwMapID = v[1]
                local dwBossIndex = v[2]
                local tBossInfo = Table_GetDungeonBossByBossIndex(dwBossIndex)
                local szMapName = UIHelper.GBKToUTF8(Table_GetMapName(dwMapID))
                local szBossName = UIHelper.GBKToUTF8(tBossInfo.szName)
                local szText = string.format("%s[%s]\n", szBossName, szMapName)
                local szLinkInfo = string.format("FBlist/%s/%s", dwMapID, dwBossIndex)
                script = UIHelper.AddPrefab(PREFAB_ID.WidgetBookSourceCell, self.LayoutSource, szLinkInfo)
                script:SetCellName(szText)
            end
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutPropBox)
    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewArticleInfo, true, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewArticleInfo)
end

function UIBookCopyView:TrimLineBreak(szContent)
    local tStrings = string.split(szContent, '\n')
    szContent = ""
    for _, str in ipairs(tStrings) do
        if #str > 0 then
            szContent = szContent..str..'\n'
        end
    end

    return szContent
end

return UIBookCopyView