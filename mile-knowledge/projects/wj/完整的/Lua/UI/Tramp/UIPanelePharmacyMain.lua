-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelePharmacyMain
-- Date: 2023-04-18 15:39:03
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelePharmacyMain = class("UIPanelePharmacyMain")

function UIPanelePharmacyMain:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.nSliderBG = UIHelper.GetWidth(self.ImgSliderNumBg)
    end
    self:SetCurItemInfo()
    self:UpdateInfo()
end

function UIPanelePharmacyMain:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelePharmacyMain:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.SliderNum, EventType.OnChangeSliderPercent, function(slider, event)
        if event == ccui.SliderEventType.slideBallUp or event == ccui.SliderEventType.percentChanged then
            self:UpdateUIItemNum()
            self:UpdateBtnConfirmState()
            self:UpdateSlider()
        end
    end)

    UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function(slider, event)
        local nCurItemNum = UIHelper.GetProgressBarPercent(self.SliderNum)
        self:SetProgressBarPercent(nCurItemNum + 1)
        self:UpdateBtnConfirmState()
    end)

    UIHelper.BindUIEvent(self.BtnMinus, EventType.OnClick, function(slider, event)
        local nCurItemNum = UIHelper.GetProgressBarPercent(self.SliderNum)
        self:SetProgressBarPercent(nCurItemNum - 1)
        self:UpdateBtnConfirmState()
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        local nCurItemNum = UIHelper.GetProgressBarPercent(self.SliderNum)
        CraftManageData.Produce(self.tbCurItemInfo.nID, nCurItemNum)
    end)

    UIHelper.RegisterEditBoxEnded(self.EditPaginate, function()
        local nCurItemNum = UIHelper.GetText(self.EditPaginate)
        self:SetProgressBarPercent(nCurItemNum)
    end)

    UIHelper.BindUIEvent(self.ScrollViewConsume, EventType.OnScrollingScrollView, function(_, eventType)
        if eventType == ccui.ScrollviewEventType.containerMoved then
            UIHelper.SetVisible(self.WidgetArrow, false)
        end
    end)

end

function UIPanelePharmacyMain:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:CloseTip()
    end)

    Event.Reg(self, "BAG_ITEM_UPDATE", function()
        CraftManageData.UpdatePlayerItemNum()
        self:UpdateCurItemInfo()
    end)

    Event.Reg(self, "DO_CUSTOM_OTACTION_PROGRESS", function (nTotalFrame, szActionName, nType)
        if nTotalFrame and nTotalFrame > 0 then
            local tParam = {
                szType = "Normal",
                szFormat = UIHelper.GBKToUTF8(szActionName),
                nDuration = nTotalFrame / GLOBAL.GAME_FPS,
                fnCancel = function ()
                    GetClientPlayer().StopCurrentAction()
                end
            }
            UIMgr.Open(VIEW_ID.PanelSystemPrograssBar, tParam)
        end
    end)

end

function UIPanelePharmacyMain:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelePharmacyMain:UpdateInfo()
    self:UpdateTitle()
    self:UpdateList()
end

function UIPanelePharmacyMain:UpdateTitle()
    local nClassificationID = CraftManageData.GetClassificationID()
    UIHelper.SetString(self.LabelTitle, g_tStrings.STR_LKX_CRAFT_NAME[nClassificationID])
end

function UIPanelePharmacyMain:UpdateList()
    local tbCraftInfos = CraftManageData.GetCraftInfos()
    local tbCraftLevel = CraftManageData.GetCraftLevel()
    local func = function(scriptContainer, tArgs)
        UIHelper.SetString(scriptContainer.LabelTittle, UIHelper.GBKToUTF8(tArgs.szTypeName))
        UIHelper.SetString(scriptContainer.LabelTittle1, UIHelper.GBKToUTF8(tArgs.szTypeName))
    end

    local tbData = {}
    for szTypeName, tCraftInfos in pairs(tbCraftInfos) do
        local Info = {}
        Info.tArgs = {szTypeName = szTypeName}
        Info.tItemList = {}
        for Index, tbData in ipairs(tCraftInfos) do
            local pItemInfo = GetItemInfo(tbData.nItemType, tbData.nItemID)
            local szName = tbCraftLevel[tbData.nCraftLevel] and pItemInfo.szName or g_tStrings.STR_CRAFT_UNKNOWN
            table.insert(Info.tItemList, {tArgs = {szName = szName, tbCraftInfos = tbData, funcSelect = function(tbItemInfo, script)
                self:SetCurItemInfo(tbItemInfo, script)
            end}})
        end

        Info.fnOnCickCallBack = function(bSelect, scriptContainer)
           
        end
        table.insert(tbData, Info)
    end

    local scriptScrollViewTree = UIHelper.GetBindScript(self.WidgetSelect)
    UIHelper.SetupScrollViewTree(scriptScrollViewTree, PREFAB_ID.WidgetPharmacyFilter, PREFAB_ID.WidgetPharmacyFilterCell, func, tbData)
end


function UIPanelePharmacyMain:UpdateCurItemInfo()
    UIHelper.SetVisible(self.WidgetAniRight, self.tbCurItemInfo ~= nil)
    UIHelper.SetVisible(self.WidgetEmpty, self.tbCurItemInfo == nil)
    if not self.tbCurItemInfo then return end
    self:UpdateItemIcon()
    self:UpdateItemTitle()
    self:UpdateItemExpend()
    self:UpdateItemMaxNum()
    self:UpdateBtnConfirmState()
    self.scriptCurItem:UpdateInfo()
end

function UIPanelePharmacyMain:UpdateBtnConfirmState()
    local nCurItemNum = UIHelper.GetProgressBarPercent(self.SliderNum)
    local nBtnState = nCurItemNum == 0 and BTN_STATE.Disable or BTN_STATE.Normal
    UIHelper.SetButtonState(self.BtnConfirm, nBtnState)
end

function UIPanelePharmacyMain:UpdateItemIcon()
    local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.WidgetItem)
    scriptView:OnInitWithTabID(self.tbCurItemInfo.nItemType, self.tbCurItemInfo.nItemID)
    scriptView:SetClickCallback(function(nItemType, nItemID)
        self:CloseTip()
        if nItemType and nItemID then
            local tips, tipsScriptView = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, self.WidgetItem)
            tipsScriptView:SetFunctionButtons({})
            tipsScriptView:OnInitWithTabID(nItemType, nItemID)
            self.nCurItemView = scriptView
        end
    end)
end

function UIPanelePharmacyMain:UpdateItemTitle()
    local szName = self.tbCurItemInfo.szName ~= "？？？" and UIHelper.GBKToUTF8(self.tbCurItemInfo.szName) or "未知"
    UIHelper.SetString(self.LabelItemTitle, szName)
end

function UIPanelePharmacyMain:UpdateItemExpend()
    
    UIHelper.RemoveAllChildren(self.ScrollViewConsume)
    local nCount = 0
    if self.tbCurItemInfo.tRecipe then
        for _, tRecipeItem in ipairs(self.tbCurItemInfo.tRecipe) do
            local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetItemWithName, self.ScrollViewConsume)
            local pItemInfo = GetItemInfo(tRecipeItem.nItemType, tRecipeItem.nItemID)
            local nPlayerItemNum = CraftManageData.GetPlayerItemNum(tRecipeItem.nItemType, tRecipeItem.nItemID)
            scriptView:SetImgIconByIconID(Table_GetItemIconID(pItemInfo.nUiId))
            scriptView:SetLabelItemName(UIHelper.GBKToUTF8(pItemInfo.szName))
            scriptView:SetLableCount(nPlayerItemNum.."/"..tRecipeItem.nNum)
            scriptView:ToggleGroupAddToggle(self.ConsumeToggleGroup)
            scriptView:RegisterSelectEvent(function(bSelect)
                self:CloseTip()
                if bSelect then
                    local tips, tipsScriptView = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, scriptView._rootNode)
                    tipsScriptView:SetFunctionButtons({})
                    tipsScriptView:OnInitWithTabID(tRecipeItem.nItemType, tRecipeItem.nItemID)
                    self.nCurItemView = scriptView
                end
            end)
        end
        nCount = #self.tbCurItemInfo.tRecipe
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewConsume)
    UIHelper.ScrollToLeft(self.ScrollViewConsume, 0)
    UIHelper.SetVisible(self.WidgetArrow, nCount > 5)
end

--更新页面道具数量
function UIPanelePharmacyMain:UpdateUIItemNum()
    local nCurItemNum = UIHelper.GetProgressBarPercent(self.SliderNum)
    -- UIHelper.SetString(self.LabelManufactureNum, nCurItemNum)
    UIHelper.SetText(self.EditPaginate, nCurItemNum)
end

function UIPanelePharmacyMain:UpdateSlider()
    local nPercent = UIHelper.GetProgressBarPercent(self.SliderNum)
    local nMaxMakeNum = self.tbCurItemInfo.nMaxMakeNum
    UIHelper.SetWidth(self.ImgSliderNum, self.nSliderBG * nPercent / self.tbCurItemInfo.nMaxMakeNum)
    UIHelper.UpdateVisualSlider(self.SliderNum)
end

function UIPanelePharmacyMain:UpdateItemMaxNum()
    local nMaxMakeNum = self.tbCurItemInfo.nMaxMakeNum
    UIHelper.SetMaxPercent(self.SliderNum, nMaxMakeNum)
    self:SetProgressBarPercent(nMaxMakeNum > 0 and 1 or 0)
end

function UIPanelePharmacyMain:SetProgressBarPercent(nPercent)
    UIHelper.SetProgressBarPercent(self.SliderNum, nPercent)
    self:UpdateSlider()
end

function UIPanelePharmacyMain:SetCurItemInfo(tbItemInfo, script)
    self.tbCurItemInfo = tbItemInfo
    self.scriptCurItem = script
    self:UpdateCurItemInfo()
end

function UIPanelePharmacyMain:CloseTip()
    if self.nCurItemView then 
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
        self.nCurItemView:RawSetSelected(false)
        self.nCurItemView = nil
    end
end



return UIPanelePharmacyMain