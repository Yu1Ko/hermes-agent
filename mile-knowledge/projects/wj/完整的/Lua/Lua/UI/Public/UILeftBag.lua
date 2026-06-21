-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UILeftBag
-- Date: 2023-05-31 17:43:00
-- Desc: 通用预制-左侧背包
-- Prefab: WidgetLeftBag
-- ---------------------------------------------------------------------------------

local UILeftBag = class("UILeftBag")

function UILeftBag:OnInitWithTabID(tItemTabTypeAndIndexList, tItemTipBtnList, tbFilterInfo, bShowGray)
    --- 要显示的道具列表 { {dwTabType=1, dwIndex=2} }
    self.tItemTabTypeAndIndexList = tItemTabTypeAndIndexList
    --- 点击道具图标后显示的道具tip中显示的按钮列表，格式示例 { {szName="确认", OnClick=function(dwItemTabType, dwItemTabIndex) DoSomething() end} }
    self.tItemTipBtnList          = tItemTipBtnList or {}
    self.tbFilterInfo             = tbFilterInfo
    if tbFilterInfo then
        self.tFilterDef   = self.tbFilterInfo.Def
        self.tbfuncFilter = self.tbFilterInfo.tbfuncFilter
    end
    self.bShowGray  = not not bShowGray
    self.bWithTabID = true

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if tbFilterInfo then
        local tbTemp = self.tFilterDef.bStorage and self.tFilterDef.ReadFromStorage() or self:GetDefaultTemp()
        self:UpdateFilterFunc(tbTemp)
    else
        self:HideFliter(true)
    end

    self:UpdateInfo()
end

function UILeftBag:OnInitWithBox(tItemBoxAndIndexList, tbFilterInfo)
    --- 要显示的道具列表 { {nBox=1, nIndex=2, nSelectedQuantity = 0} }
    self.tItemBoxAndIndexList = tItemBoxAndIndexList
    self.tbFilterInfo         = tbFilterInfo
    if tbFilterInfo then
        self.tFilterDef   = self.tbFilterInfo.Def
        self.tbfuncFilter = self.tbFilterInfo.tbfuncFilter
    end

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if UIMgr.GetView(VIEW_ID.PanelHalfBag) then
        -- 背包同时打开会导致玩家操作发送到相同道具上，所以加个互斥
        UIMgr.Close(VIEW_ID.PanelHalfBag)
    end

    if tbFilterInfo then
        local tbTemp = self.tFilterDef.bStorage and self.tFilterDef.ReadFromStorage() or self:GetDefaultTemp()
        self:UpdateFilterFunc(tbTemp)
    else
        self:HideFliter(true)
    end

    self:UpdateInfo()
end

function UILeftBag:OnInitUseItem(dwBox, dwX, funcConfirmAction, tbTargetItemList)
    self.bUseItem = true
    self.tUseItem = {}
    self.tUseItem.dwBox = dwBox
    self.tUseItem.dwX = dwX
    self.tUseItem.funcConfirmAction = funcConfirmAction
    self.tUseItem.tbTargetItemList = tbTargetItemList

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:HideFliter(true)

    self:UpdateInfo()
end

function UILeftBag:OnInitWithRideExterior(tRideExterior, tbFilterInfo)
    self.bRideExterior = true
    self.tRideExterior = tRideExterior
    self.tbFilterInfo = tbFilterInfo
    if tbFilterInfo then
        self.tFilterDef   = self.tbFilterInfo.Def
        self.tbfuncFilter = self.tbFilterInfo.tbfuncFilter
    end

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if UIMgr.GetView(VIEW_ID.PanelHarnessBag) then
        UIMgr.Close(VIEW_ID.PanelHarnessBag)
    end

    if tbFilterInfo then
        local tbTemp = self.tFilterDef.bStorage and self.tFilterDef.ReadFromStorage() or self:GetDefaultTemp()
        self:UpdateFilterFunc(tbTemp)
    else
        self:HideFliter(true)
    end

    self:UpdateInfo()
end

function UILeftBag:OnExit()
    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
    Event.Dispatch(EventType.OnLeftBagClose)
    self.bInit = false
    self:UnRegEvent()
end

function UILeftBag:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnScreen, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self._rootNode, TipsLayoutDir.TOP_CENTER, self.tFilterDef)
    end)

    UIHelper.BindUIEvent(self.BtnCloseLeft, EventType.OnClick, function()
        if self.fnCloseCallback then
            self.fnCloseCallback()
        else
            UIMgr.Close(self)
        end
    end)

    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function()
        if self.fnCloseCallback then
            self.fnCloseCallback()
        else
            UIMgr.Close(self)
        end
    end)

    UIHelper.BindUIEvent(self.BtnDes, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnDes, TipsLayoutDir.TOP_CENTER, "道具上架至万宝楼后，需要到万宝楼网页设置出售价格，补充身份信息后再正式上架出售；也可再万宝楼随时取消寄售，取回道具。")
    end)

    UIHelper.BindUIEvent(self.BtnClear, EventType.OnClick, function()
        self.szItemNameFilter = nil
        UIHelper.SetText(self.EditKindSearch , "")
        if self.fnSearchCallback then
            self.fnSearchCallback("")
        else
            self:UpdateInfo()
        end
    end)

    UIHelper.BindUIEvent(self.TogSearch, EventType.OnSelectChanged, function(_, bSelected)
        if not bSelected then
            self.szItemNameFilter = nil
            UIHelper.SetText(self.EditKindSearch , "")
            if self.fnSearchCallback then
                self.fnSearchCallback("")
            else
                self:UpdateInfo()
            end
        end
    end)

    UIHelper.RegisterEditBox(self.EditKindSearch, function(szType, _editbox)
        if not self.bInit then
            return
        end

        if self.fnSearchCallback then
            if szType == "ended" or szType == "return" then
                self.fnSearchCallback(UIHelper.GetText(self.EditKindSearch))
            end
            return
        end

        if szType == "changed" then
            local szText = UIHelper.GetString(self.EditKindSearch)
            self.szItemNameFilter = nil
            if szText ~= "" then
                self.szItemNameFilter = UIHelper.UTF8ToGBK(szText)
            end
            self:UpdateInfo()
        end
    end)
end

function UILeftBag:RegEvent()
    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        self:UpdateFilterFunc(tbSelected)
        self:UpdateInfo()

        local bFilter = false
        for _, v in pairs(tbSelected or {}) do
            if v[1] ~= 1 then
                bFilter = true
                break
            end
        end

        --筛选图标
        local szImgPath = bFilter and "UIAtlas2_Public_PublicButton_PublicButton1_icon_screen_ing" or "UIAtlas2_Public_PublicButton_PublicButton1_icon_screen"
        UIHelper.SetSpriteFrame(self.ImgIconScreen, szImgPath)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:ClearSelectedState()
    end)

    Event.Reg(self, EventType.OnSetUIItemIconChoose, function(bHave, nBox, nIndex, nCurCount)
        for _, tItem in ipairs(self.tItemBoxAndIndexList) do
            if nBox == tItem.nBox and nIndex == tItem.nIndex and tItem.nSelectedQuantity ~= nCurCount then
                tItem.nSelectedQuantity = nCurCount
            end
        end
    end)
end

function UILeftBag:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UILeftBag:UpdateInfo()
    if self.bWithTabID then
        self:UpdateInfoWithTabID()
    elseif self.bUseItem then
        self:UpdateInfoUseItem()
    elseif self.bRideExterior then
        self:UpdateInfoWithRideExterior()
    else
        self:UpdateInfoWithBox()
    end
end

function UILeftBag:UpdateInfoWithTabID()
    local bHasAny = false
    UIHelper.RemoveAllChildren(self.ScrollBag)

    for _, tItem in ipairs(self.tItemTabTypeAndIndexList) do
        local nAmount = tItem.nAmount or ItemData.GetItemAmountInPackage(tItem.dwTabType, tItem.dwIndex)
        if (self:CanShow(tItem) and nAmount > 0) or self.bShowGray then
            bHasAny         = true
            local script    = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.ScrollBag)
            local bShowGray = self.bShowGray and nAmount <= 0

            script:OnInitWithTabID(tItem.dwTabType, tItem.dwIndex, nAmount)
            script:SetClearSeletedOnCloseAllHoverTips(true)
            UIHelper.SetToggleGroupIndex(script.ToggleSelect, ToggleGroupIndex.LeftBagItem)
            UIHelper.SetNodeGray(script._rootNode, bShowGray, true)
            script:SetClickCallback(function(dwItemTabType, dwItemTabIndex)
                local nX,nY = UIHelper.GetWorldPosition(self.WidgetAnchorTips)
                local nSizeW,nSizeH = UIHelper.GetContentSize(self.WidgetAnchorTips)
                local uiTips, uiItemTipScript = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetItemTip, nX-nSizeW+350, nY+nSizeH)

                uiItemTipScript:OnInitWithTabID(dwItemTabType, dwItemTabIndex)

                -- 为了方便外面获取道具信息，预制传入的回调与tip需要的回调格式有所不同，这里转换下
                local tItemTipBtnList         = {}
                self.scriptCurSelectedItem    = script
                for _, tBtn in ipairs(self.tItemTipBtnList) do
                    if bShowGray and tBtn.bFobidBtnOnGray then
                        -- Do nothing 因为不能从外部设置按钮，所以设置一种状态来判断要不要插入按钮
                    else
                        table.insert(tItemTipBtnList, {
                            szName = tBtn.szName,
                            OnClick = function()
                                tBtn.OnClick(dwItemTabType, dwItemTabIndex)
                            end
                        })
                    end
                end

                uiItemTipScript:SetBtnState(tItemTipBtnList)
                Event.Dispatch(EventType.OnLeftBagSelectItem)
            end)
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollBag)

    UIHelper.SetVisible(self.WidgetEmpty, not bHasAny)

end

function UILeftBag:UpdateInfoWithBox()
    local bHasAny = false
    UIHelper.RemoveAllChildren(self.ScrollBag)

    self.tItemScript = {}
    for _, tItem in ipairs(self.tItemBoxAndIndexList) do
        local nBox, nIndex, nSelectedQuantity, hItem = tItem.nBox, tItem.nIndex, tItem.nSelectedQuantity, tItem.hItem
        if self:CanShow(hItem) then
            bHasAny      = true
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.ScrollBag)

            if script then
                script:OnInit(nBox, nIndex)
                script:SetSelectChangeCallback(function(_, bSelected, nBox, nIndex)
                    self.scriptCurSelectedItem = script
                    self.FuncClickCallback(bSelected, nBox, nIndex)
                end)

                script:SetHandleChooseEvent(true)
                Event.Dispatch(EventType.OnSetUIItemIconChoose, nSelectedQuantity ~= 0, nBox, nIndex, nSelectedQuantity)

                table.insert(self.tItemScript, script)
            end
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollBag)
    UIHelper.SetVisible(self.WidgetEmpty, not bHasAny)
end

function UILeftBag:UpdateInfoUseItem()
    local bHasAny = false
    UIHelper.RemoveAllChildren(self.ScrollBag)

    self.tItemScript = {}
    local tbTargetItemList = self.tUseItem.tbTargetItemList or ItemData.GetUseItemTargetItemList(self.tUseItem.dwBox, self.tUseItem.dwX) or {}
    for _, tbItemInfo in ipairs(tbTargetItemList) do
        if self:CanShow(tbItemInfo.hItem) then
            bHasAny      = true
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.ScrollBag)

            if tbItemInfo.nBox and tbItemInfo.nIndex then
                script:OnInit(tbItemInfo.nBox, tbItemInfo.nIndex)
            else
                script:OnInitWithTabID(tbItemInfo.dwTabType, tbItemInfo.dwIndex, 0)
                UIHelper.SetNodeGray(script._rootNode, true, true)
            end
    
            if script then
                script:SetToggleGroupIndex(ToggleGroupIndex.UseItemToItem)
                script:SetClickCallback(function(nBox, nIndex)
                    local tips, scriptItemTip
                    if tbItemInfo.nBox and tbItemInfo.nIndex then
                        tips, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, script._rootNode, TipsLayoutDir.LEFT_CENTER)
                        scriptItemTip:OnInit(tbItemInfo.nBox, tbItemInfo.nIndex)
                    else
                        tips, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, script._rootNode, TipsLayoutDir.LEFT_CENTER)
                        scriptItemTip:OnInitWithTabID(tbItemInfo.dwTabType, tbItemInfo.dwIndex)
                    end

                    local tItemTipBtnList         = {}
                    if tbItemInfo.nBox and tbItemInfo.nIndex then
                        table.insert(tItemTipBtnList, {
                            szName = "取消",
                            OnClick = function()
                                UIHelper.SetVisible(scriptItemTip._rootNode, false)
                            end
                        })

                        table.insert(tItemTipBtnList, {
                            szName = "使用",
                            OnClick = function()
                                if self.tUseItem.funcConfirmAction then
                                    self.tUseItem.funcConfirmAction(tbItemInfo.nBox, tbItemInfo.nIndex)
                                end
                                UIMgr.Close(self)
                            end
                        })
                    else
                    end

                    scriptItemTip:SetBtnState(tItemTipBtnList)

                end)

                if tbItemInfo.nBox and tbItemInfo.nIndex then
                    if #tbTargetItemList == 1 then
                        script:SetSelected(true)
                    end
                end
                table.insert(self.tItemScript, script)
            end
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollBag)
    self:SetEmptyDes("暂无可使用物品")
    UIHelper.SetVisible(self.WidgetEmpty, not bHasAny)
end

function UILeftBag:UpdateInfoWithRideExterior()
    local bHasAny = false
    UIHelper.RemoveAllChildren(self.ScrollBag)

    self.tItemScript = {}
    for _, tItem in ipairs(self.tRideExterior) do
        local dwExteriorID, bEquip = tItem.dwExteriorID, false
        if self:CanShow(tItem) then
            bHasAny      = true
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.ScrollBag)

            if script then
                script:OnInitWithRideExterior(dwExteriorID, bEquip)
                local bWear = RideExteriorData.IsInPreview(dwExteriorID, bEquip)
                script:SetItemWear(bWear)
                script:SetClickCallback(function(dwExteriorID, bEquip)
                    local tips, scriptTips = TipsHelper.ShowItemTips(script._rootNode)
                    scriptTips:OnInitRideExterior(dwExteriorID, bEquip)
                    scriptTips:SetBtnState(RideExteriorData.GetExteriorTipsBtnState(dwExteriorID, bEquip))
                    if UIHelper.GetSelected(script.ToggleSelect) then
                        UIHelper.SetSelected(script.ToggleSelect, false)
                    end
                end)

                script:SetHandleChooseEvent(true)
                table.insert(self.tItemScript, script)
            end
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollBag)
    UIHelper.SetVisible(self.WidgetEmpty, not bHasAny)
end

----------------------------------------通用function------------------------------------------------------

function UILeftBag:SetClickCallback(callback)
    self.FuncClickCallback = callback
end

function UILeftBag:ClearSelectedState()
    for _, v in ipairs(self.tItemScript) do
        if UIHelper.GetSelected(v.ToggleSelect) then
            UIHelper.SetSelected(v.ToggleSelect, false)
        end
    end
end

function UILeftBag:SetSelect(nBox, nIndex)
    for index, tItem in ipairs(self.tItemBoxAndIndexList) do
        local nItemBox, nItemIndex, nSelectedQuantity, hItem = tItem.nBox, tItem.nIndex, tItem.nSelectedQuantity, tItem.hItem
        if nItemBox == nBox and nItemIndex == nIndex then
            self.tItemScript[index]:SetSelected(true)
        end
    end
end

function UILeftBag:UpdateWear()
    if not self.bRideExterior then
        return
    end
    for _, script in ipairs(self.tItemScript) do
        local dwExteriorID = script.dwExteriorID
        local bEquip = script.bEquip
        local bWear = RideExteriorData.IsInPreview(dwExteriorID, bEquip)
        script:SetItemWear(bWear)
    end
end

function UILeftBag:HideChoose()
    for _, script in ipairs(self.tItemScript) do
        script:HideChoose()
    end
end

function UILeftBag:CanShow(item)
    local fnNameFilter = function(item)
        if not self.szItemNameFilter then
            return true
        end

        if not item then
            return false
        end

        if self.bRideExterior then
            local szName = item.szName
            local bMatch = string.find(szName, UIHelper.GBKToUTF8(self.szItemNameFilter))
            return bMatch
        end

        if item and not IsString(item) then
            local szType = ItemData.GetItemTypeInfoDesc(item, true)
            if string.find(szType, self.szItemNameFilter) then
                return true
            end
        end

        local szName = item
        if not IsString(szName) then
            szName = ItemData.GetItemNameByItem(item)
        end

        return string.find(szName, self.szItemNameFilter)
    end

    local tbSelectedTabCfg = self.tbCatogoryCfg and self.tbCatogoryCfg[self.nSelectedTab]
    for index, filterFunc in ipairs(self.tbFilterFunc) do
        if not filterFunc(item) then
            return false
        end
    end

    if tbSelectedTabCfg and tbSelectedTabCfg.filterFunc and not tbSelectedTabCfg.filterFunc(item) then
        return false
    end

    if not fnNameFilter(item) then
        return false
    end

    return true
end

function UILeftBag:GetDefaultTemp()
    local tbTemp = self.tFilterDef.GetRunTime()
    if not tbTemp then
        tbTemp = {}
        for index, tbData in ipairs(self.tFilterDef) do
            table.insert(tbTemp, tbData.tbDefault)
        end
    end

    return tbTemp
end

function UILeftBag:UpdateFilterFunc(tbSelected)
    self.tbFilterFunc = {}
    for nIndex, tbGroup in ipairs(tbSelected) do
        for index, nTogIndex in ipairs(tbGroup) do
            table.insert(self.tbFilterFunc, self.tbfuncFilter[nIndex][nTogIndex])
        end
    end
end

function UILeftBag:GetCurSelectedItem()
    return self.scriptCurSelectedItem
end

function UILeftBag:HideFliter(bHide)
    UIHelper.SetVisible(self.BtnScreen, not bHide)
end

function UILeftBag:HideSearch(bHide)
    UIHelper.SetSelected(self.TogSearch, false)
    UIHelper.SetVisible(self.TogSearch, not bHide)
end

function UILeftBag:SetSearchCallback(fnCallback)
    self.fnSearchCallback = fnCallback
end

function UILeftBag:SetCloseCallback(fnCallback)
    self.fnCloseCallback = fnCallback
end

---@tbCatogoryCfg table 使用BagDef.lua中的配置
function UILeftBag:OnInitCatogory(tbCatogoryCfg)
    assert(tbCatogoryCfg)

    self.tbCatogoryCfg = tbCatogoryCfg
    UIHelper.SetVisible(self.WidgetCatogoryTab, true)
    UIHelper.RemoveAllChildren(self.ScrollViewChildTab)

    local bSelected = false
    for nIndex, tbCfg in ipairs(tbCatogoryCfg) do
        local tInfo = {
            szTitle = tbCfg.szName,
            onSelectChangeFunc = function(_, bSelected)
                if bSelected then
                    if nIndex ~= self.nSelectedTab then
                        self.nSelectedTab = nIndex
                        self:UpdateInfo()
                        UIHelper.SetString(self.LabelTitle, self.tbCatogoryCfg[self.nSelectedTab].szTitle)
                    end
                end
            end
        }
        local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetWarehouseChild, self.ScrollViewChildTab, tInfo)

        --默认选择第一个
        if not bSelected then
            UIHelper.SetSelected(scriptView.ToggleChildNavigation, true)
            bSelected = true
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewChildTab)
end

function UILeftBag:SetEmptyDes(szEmptyDes)
    if self.LabelEmptyDes then
        UIHelper.SetString(self.LabelEmptyDes, szEmptyDes)
    end
end

function UILeftBag:SetTitle(szTitle)
    if self.LabelTitle then
        UIHelper.SetString(self.LabelTitle, szTitle)
    end
end

return UILeftBag