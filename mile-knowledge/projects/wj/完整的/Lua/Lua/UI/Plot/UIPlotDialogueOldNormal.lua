-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPlotDialogueOldNormal
-- Date: 2022-11-23 20:54:00
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPlotDialogueOldNormal = class("UIPlotDialogueOldNormal")
local nWidgetOldDialogueContent7Width = 500

function UIPlotDialogueOldNormal:OnEnter(tbDialogueData)
    self.tbDialogueData = tbDialogueData
    self.tbLayout = {}

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPlotDialogueOldNormal:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPlotDialogueOldNormal:BindUIEvent()

end

function UIPlotDialogueOldNormal:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:CloseTip()
    end)
    Event.Reg(self, EventType.BagItemLongPress, function(nBox, nIndex, nTabType, nTabID, scriptIcon)
        if nTabID and nTabType then
            self:OpenTip(true, scriptIcon, nTabType, nTabID, nil)
        end
    end)

    Event.Reg(self, "SHOW_OLDDIALOGUE_TIP", function(bItem, scriptIcon, nTabType, nTabID, nTipID)
        self:OpenTip(bItem, scriptIcon, nTabType, nTabID, nTipID)
    end)
end

function UIPlotDialogueOldNormal:UnRegEvent()

end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPlotDialogueOldNormal:UpdateInfo()

    UIHelper.RemoveAllChildren(self._rootNode)
    self.scriptCurLayout = nil
    local tbItemDataList = self.tbDialogueData.tbData.tbItemDataList
    for k, v in ipairs(tbItemDataList) do
  
        local nPrefabID = PlotMgr.GetPrefabIDByItemType(v)
        if PlotMgr.IsItemNeedLayout(nPrefabID) then
            self:AddItemToLayout(nPrefabID, k, v)
        else
            UIHelper.AddPrefab(nPrefabID, self._rootNode, v)
            self.scriptCurLayout = nil--放入其它元素后Layout必换行
        end
    end
    self:LayoutDoLayout()
end

function UIPlotDialogueOldNormal:AddItemToLayout(nPrefabID, k, v)


    local nRemianWidth = self.scriptCurLayout and self.scriptCurLayout:GetRemainLen() or nil

    if v.nItemType == PLOT_DIALOGUE_ITEM_TYPE.TEXT then

        local szOrigiContent = v.szContent
        local szText = ""
        local nStart = 1
        while szOrigiContent ~= "" do

            if not nRemianWidth or nRemianWidth <= 0 then
                self:GetNewLayout()
                nRemianWidth = self.scriptCurLayout:GetRemainLen()
            end

            szText, szOrigiContent = UIHelper.GetLimitedUtf8Text(szOrigiContent, 26, nRemianWidth)

            if szText == "" then--不够一个字
                self:GetNewLayout()
                nRemianWidth = self.scriptCurLayout:GetRemainLen()
            else
                local tbData = clone(v)
                tbData.szContent = string.gsub(szText, "\n", "")

                local scriptView = self.scriptCurLayout:AddPrefab(nPrefabID, tbData)

                nRemianWidth = self.scriptCurLayout:GetRemainLen()
            end
        end
        
        return 

    end

    local nCurWidth = PlotMgr.GetPrefabIDWidthByItemType(nPrefabID)
    if not nRemianWidth or nRemianWidth == 0 or nRemianWidth < nCurWidth then
        self:GetNewLayout()
    end

    local scriptView = self.scriptCurLayout:AddPrefab(nPrefabID, v)
    -- if v.nItemType == PLOT_DIALOGUE_ITEM_TYPE.ITEM then
    --     scriptView = self.scriptCurLayout:AddPrefab(nPrefabID, v)
    -- else
    --     scriptView = self.scriptCurLayout:AddPrefab(nPrefabID, v)
    -- end

end

function UIPlotDialogueOldNormal:GetNewLayout()
    -- if self.scriptCurLayout then
    --     UIHelper.CascadeDoLayoutDoWidget(self.scriptCurLayout._rootNode, true, true)
    -- end
    self.scriptCurLayout = UIHelper.AddPrefab(PREFAB_ID.WidgetOldDialogueContent7, self._rootNode)
    self.scriptCurLayout:Init()
    table.insert(self.tbLayout, self.scriptCurLayout._rootNode)
end

function UIPlotDialogueOldNormal:LayoutDoLayout()
    for index, node in ipairs(self.tbLayout) do
        UIHelper.CascadeDoLayoutDoWidget(node, true, true)
    end

    if self.nArrowTimer then
        Timer.DelTimer(self, self.nArrowTimer)
        self.nArrowTimer = nil
    end

    self.nArrowTimer = Timer.AddFrame(self, 1, function()
        UIHelper.ScrollViewSetupArrow(self.ScrollViewContent, self.WidgetArrow)
    end)
end

function UIPlotDialogueOldNormal:OpenTip(bItem, scriptIcon, nTabType, nTabID, nTipID)
    self:CloseTip()
    if bItem then 
        local tbBtns = {}
        self.tips, self.CurTipsView = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, scriptIcon._rootNode)

        if nTabType and nTabID and OutFitPreviewData.CanPreview(nTabType, nTabID) then
            local tbPreviewBtn = OutFitPreviewData.SetPreviewBtn(nTabType, nTabID)
            if not table.is_empty(tbPreviewBtn) then
                table.insert(tbBtns, tbPreviewBtn[1])
            end
        end

        self.CurTipsView:SetFunctionButtons(tbBtns)
        self.CurTipsView:OnInitWithTabID(nTabType, nTabID)
        self.CurIconView = scriptIcon
    else
        self.tips, self.CurTipsView = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetRichTextTips, scriptIcon._rootNode, GameWorldTipData.GetTipByTipID(nTipID))
        self.CurIconView = scriptIcon
    end
end

function UIPlotDialogueOldNormal:CloseTip()
    if self.CurIconView then
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetRichTextTips)
        self.CurIconView:RawSetSelected(false)
        self.CurIconView = nil
    end
end


return UIPlotDialogueOldNormal