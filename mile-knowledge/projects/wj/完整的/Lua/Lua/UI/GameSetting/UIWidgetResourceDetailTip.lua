-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetResourceDetailTip
-- Date: 2023-11-21 14:42:40
-- Desc: WidgetResourceDetailTip
-- ---------------------------------------------------------------------------------

local UIWidgetResourceDetailTip = class("UIWidgetResourceDetailTip")

function UIWidgetResourceDetailTip:OnEnter(tPackIDListInfo, bDownloadBtnFlag)
    self.tPackIDListInfo = tPackIDListInfo
    self.bDownloadBtnFlag = bDownloadBtnFlag --标记是否为WidgetDownloadBtn调用的

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.SetTouchEnabled(self.LayoutList, true)
    UIHelper.SetTouchDownHideTips(self.LayoutList, false)
    UIHelper.SetTouchDownHideTips(self.ScrollViewList, false)
    self:UpdateInfo()
end

function UIWidgetResourceDetailTip:OnExit()
    self.bInit = false
    self:UnRegEvent()

    self.tScriptList = {}
end

function UIWidgetResourceDetailTip:BindUIEvent()
    
end

function UIWidgetResourceDetailTip:RegEvent()

end

function UIWidgetResourceDetailTip:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetResourceDetailTip:UpdateInfo()
    self.tScriptList = {}
    UIHelper.RemoveAllChildren(self.LayoutList)
    UIHelper.RemoveAllChildren(self.ScrollViewList)

    local bLessCell = #self.tPackIDListInfo <= 8
    UIHelper.SetVisible(self.LayoutTipBg, bLessCell)
    UIHelper.SetVisible(self.WidgetScrollViewTip, not bLessCell)
    local parent = bLessCell and self.LayoutList or self.ScrollViewList

    if self.bDownloadBtnFlag then
        for _, v in ipairs(self.tPackIDListInfo or {}) do
            local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetTogMultiSelect, parent)
            scriptView:OnInitWithPackIDList(v.tPackIDList, v.szName)
            table.insert(self.tScriptList, scriptView)
        end
    else
        local bClearRecommend = true
        for _, v in ipairs(self.tPackIDListInfo or {}) do
            local scriptView

            local function _createPrefab() return UIHelper.AddPrefab(PREFAB_ID.WidgetTogMultiSelect, parent) end

            local tLine = g_tTable.PackTree and g_tTable.PackTree:Search(v)
            if tLine then
                local nPackID = tLine.nPackID
                --v为nPackTreeID且为最底级
                if nPackID and nPackID > 0 then
                    --验证nPackID有效
                    if PakDownloadMgr.GetPackInfo(nPackID) and PakDownloadMgr.IsPackInWhiteList(nPackID) then
                        scriptView = _createPrefab()
                        scriptView:OnInitWithPackID(nPackID)
                    end
                else
                    --v为nPackTreeID但非最底级
                    --验证PackTreeID下是否存在有效nPackID
                    local tPackIDList = PakDownloadMgr.GetPackIDListInPackTree(v)
                    local bValid = false
                    for _, nPackID in ipairs(tPackIDList) do
                        if nPackID > 0 and PakDownloadMgr.GetPackInfo(nPackID) and PakDownloadMgr.IsPackInWhiteList(nPackID) then
                            bValid = true
                            break
                        end
                    end

                    if bValid then
                        scriptView = _createPrefab()
                        scriptView:OnInitWithPackIDList(tPackIDList, UIHelper.GBKToUTF8(tLine.szName))
                    end
                end

                if scriptView then
                    scriptView:SetRecommend(tLine.bRecommend)
                    if not tLine.bRecommend then
                        bClearRecommend = false
                    end
                end
            else
                --v为nPackID
                local nPackID = v
                if nPackID > 0 and PakDownloadMgr.GetPackInfo(nPackID) and PakDownloadMgr.IsPackInWhiteList(nPackID) then
                    bClearRecommend = false
                    scriptView = _createPrefab()
                    scriptView:OnInitWithPackID(nPackID)
                end
            end
            if scriptView then
                table.insert(self.tScriptList, scriptView)
            end
        end
        if bClearRecommend then
            --策划需求：若同层级下的所以Child都为推荐，则都不显示推荐图标
            for _, scriptView in ipairs(self.tScriptList or {}) do
                scriptView:SetRecommend(false)
            end
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewList)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function UIWidgetResourceDetailTip:GetContainer()
    if UIHelper.GetVisible(self.LayoutTipBg) then
        return self.LayoutTipBg
    elseif UIHelper.GetVisible(self.WidgetScrollViewTip) then
        return self.WidgetScrollViewTip
    end
end

function UIWidgetResourceDetailTip:SetDiscard(bDiscard)
    for _, scriptView in ipairs(self.tScriptList or {}) do
        scriptView:SetDiscard(bDiscard)
    end
end

return UIWidgetResourceDetailTip