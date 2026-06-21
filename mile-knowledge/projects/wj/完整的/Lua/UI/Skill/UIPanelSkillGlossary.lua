-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSkillConfigurationCell
-- Date: 2022-11-23 10:01:29
-- Desc: ?
-- ---------------------------------------------------------------------------------
---@class UIPanelSkillGlossary
local UIPanelSkillGlossary = class("PanelSkillGlossary")

function UIPanelSkillGlossary:OnEnter(szSelectedName, tTotalNoun, szSourceName, szOriginalDesc)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.tScripts = {}
        self.tHistoryList = {}
        self.nHistoryIndex = 1
    end

    self.szSelectedName = szSelectedName
    self.szSourceName = szSourceName
    self.szOriginalDesc = szOriginalDesc
    self.bIsVK = self.szOriginalDesc == nil
    self.tTotalNounList = clone(tTotalNoun)
    self.bIsNextLevel = self.szSourceName ~= ""

    self:ModifyHistory()
    self:UpdateInfo()
end

function UIPanelSkillGlossary:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelSkillGlossary:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPanelSkillGlossary:RegEvent()
    Event.Reg(self, EventType.OnViewPlayHideAnimBegin, function(nViewID)
        if VIEW_ID.PanelSkillGlossary == nViewID then
            UIHelper.RemoveAllChildren(self.WidgetTipParent)
        end
    end)
end

function UIPanelSkillGlossary:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelSkillGlossary:ModifyHistory()
    if self.bIsNextLevel then
        local tUpperInfo = self.tHistoryList[self.nHistoryIndex]
        if tUpperInfo then
            tUpperInfo.szSelectedName = self.szSourceName -- 修改上一级选中词条
        end

        for i = #self.tHistoryList, self.nHistoryIndex + 1, -1 do
            table.remove(self.tHistoryList, i)
        end

        local tRecord = {
            szSelectedName = self.szSelectedName,
            szSourceName = self.szSourceName,
            tTotalNounList = self.tTotalNounList,
            szOriginalDesc = self.szOriginalDesc
        }

        if not IsTableEmpty(tRecord) then
            table.insert(self.tHistoryList, tRecord)
        end
    end
end

function UIPanelSkillGlossary:UpdateHistory()
    UIHelper.RemoveAllChildren(self.ScrollViewBreadNaviScreen)
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupNav)

    for nIndex, tInfo in ipairs(self.tHistoryList) do
        local topScript = UIHelper.AddPrefab(PREFAB_ID.WidgetWordCell, self.ScrollViewBreadNaviScreen)
        local cellScript = nIndex == 1 and UIHelper.GetBindScript(topScript.WidgetTypeOne) or UIHelper.GetBindScript(topScript.WidgetTypeTwo)
        UIHelper.SetString(cellScript.LabelSelected, UIHelper.GBKToUTF8(tInfo.szSourceName))
        UIHelper.SetString(cellScript.LabelNormal, UIHelper.GBKToUTF8(tInfo.szSourceName))
        UIHelper.SetVisible(cellScript._rootNode, true)

        UIHelper.ToggleGroupAddToggle(self.ToggleGroupNav, topScript.TogNav)
        UIHelper.BindUIEvent(topScript.TogNav, EventType.OnSelectChanged, function(_, bSel)
            if bSel then
                self.szSelectedName = tInfo.szSelectedName
                self.tTotalNounList = tInfo.tTotalNounList
                self.szOriginalDesc = tInfo.szOriginalDesc
                self.szSourceName = tInfo.szSourceName
                self.nHistoryIndex = nIndex
                self:UpdateTopDesc()
                self:UpdateWordContent()
            end
        end)

        if nIndex == #self.tHistoryList then
            UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupNav, topScript.TogNav)
            self.nHistoryIndex = nIndex
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewBreadNaviScreen)
    UIHelper.ScrollToRight(self.ScrollViewBreadNaviScreen, 0)
end

function UIPanelSkillGlossary:UpdateInfo()
    UIHelper.SetVisible(self.ScrollViewList_VK, self.bIsVK)
    UIHelper.SetVisible(self.ScrollViewList_DX, not self.bIsVK)
    UIHelper.SetVisible(self.WidgetBreadNaviScreen, not self.bIsVK)
    self.ScrollViewList = self.bIsVK and self.ScrollViewList_VK or self.ScrollViewList_DX
    
    self:UpdateTopDesc()
    self:UpdateWordContent()
    self:UpdateHistory()

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewList)
end

function UIPanelSkillGlossary:UpdateWordContent()
    for _, script in ipairs(self.tScripts) do
        UIHelper.RemoveFromParent(script._rootNode, true)
    end
    self.tScripts = {}

    if self.tTotalNounList then
        local nInitialSelectedIndex = 1
        for nIndex, szName in pairs(self.tTotalNounList) do
            local nNumber = tonumber(szName)
            local tNounInfo = UISpecialNoun[szName]
            local bSelected = szName == tostring(self.szSelectedName)

            -- 兼容端游的特殊名词逻辑 只显示选中的名词
            if not self.bIsVK then
                local tSkillNounInfo = SkillData.g_tSkillNounsList[szName] or {}
                if tSkillNounInfo.szName then
                    szName = UIHelper.GBKToUTF8(tSkillNounInfo.szName)
                    local szDesc1 = SkillData.GetNounDesc(tSkillNounInfo)
                    local szDesc = UIHelper.GBKToUTF8(szDesc1)
                    bSelected = tSkillNounInfo.szName == tostring(self.szSelectedName)
                    tNounInfo = { szDescription = szDesc }
                end
            end
            if tNounInfo then
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetWordContentCell, self.ScrollViewList, szName, tNounInfo, bSelected)
                UIHelper.SetLabel(script.LabelWordName, UIHelper.AttachTextColor(szName, bSelected and "#ffcf65" or "#ffffff"))
                UIHelper.SetLabel(script.RichTextContent, tNounInfo.szDescription)
                UIHelper.SetSelected(script.TogSelect, bSelected)
                UIHelper.SetVisible(script.LayoutContent, bSelected)

                UIHelper.BindUIEvent(script.TogSelect, EventType.OnSelectChanged, function(btn, bSel)
                    UIHelper.SetVisible(script.LayoutContent, bSel)
                    UIHelper.CascadeDoLayoutDoWidget(script._rootNode, true, true)

                    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewList)
                    UIHelper.ScrollToIndex(self.ScrollViewList, nIndex - 1)
                end)

                table.insert(self.tScripts, script)
            end
            if bSelected then
                nInitialSelectedIndex = nIndex
            end
        end
        UIHelper.SetOpacity(self.ScrollViewList, 0)

        Timer.AddFrame(self, 1, function()
            UIHelper.SetOpacity(self.ScrollViewList, 255) -- 防止闪烁
            UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewList, true, true)
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewList)
            UIHelper.ScrollToIndex(self.ScrollViewList, nInitialSelectedIndex - 1)
        end)
    end
end

function UIPanelSkillGlossary:UpdateTopDesc()
    if self.szOriginalDesc then
        local szTextPattern = "<href=[^>]+>(.-)</href>"
        local szOri = string.gsub(self.szOriginalDesc, szTextPattern, "%1")
        UIHelper.SetLabel(self.RichTextTopDesc, UIHelper.GBKToUTF8(szOri))
        UIHelper.SetLabel(self.LabelTitleExplore, UIHelper.GBKToUTF8(self.szSourceName) .. "相关名词")
    end
end

function UIPanelSkillGlossary:ShowSkillTip(nSkillID)
    if not self.tipView and nSkillID then
        local tipsScriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillInfoTips, self.WidgetTipParent, nSkillID)
        self.tipView = tipsScriptView
        Timer.AddFrame(self,10,function()
            UIHelper.SetLocalZOrder(self.WidgetTipParent, -10)
        end)
    end
end

return UIPanelSkillGlossary