-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeIdentityPrefumeLeftBag
-- Date: 2024-03-11 14:54:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeIdentityPrefumeLeftBag = class("UIHomeIdentityPrefumeLeftBag")

function UIHomeIdentityPrefumeLeftBag:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIHomeIdentityPrefumeLeftBag:OnInitWithTabID(tItemTabTypeAndIndexList, nSelectedSlot, bShowGray)
    self.tItemTabTypeAndIndexList = tItemTabTypeAndIndexList
    self.nSelectedSlot = nSelectedSlot
    self.bShowGray  = not not bShowGray
    self.bWithTabID = true

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIHomeIdentityPrefumeLeftBag:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomeIdentityPrefumeLeftBag:BindUIEvent()

end

function UIHomeIdentityPrefumeLeftBag:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        if self.uiItemTipScript then
            UIHelper.SetVisible(self.uiItemTipScript._rootNode, false)
        end
    end)
end

function UIHomeIdentityPrefumeLeftBag:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomeIdentityPrefumeLeftBag:UpdateInfo()
    local bHasAny = false
    UIHelper.RemoveAllChildren(self.ScrollBag)
    if self.uiItemTipScript then
        UIHelper.SetVisible(self.uiItemTipScript._rootNode, false)
    end
    for _, tItem in ipairs(self.tItemTabTypeAndIndexList) do
        local nAmount = tItem.nAmount or ItemData.GetItemAmountInPackage(tItem.dwTabType, tItem.dwIndex)
        if nAmount > 0 or self.bShowGray then
            bHasAny      = true
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.ScrollBag)
            local bShowGray = self.bShowGray and nAmount <= 0
            script:SetTouchDownHideTips(false)
            script:OnInitWithTabID(tItem.dwTabType, tItem.dwIndex, nAmount)
            script:SetClearSeletedOnCloseAllHoverTips(true)
            UIHelper.SetToggleGroupIndex(script.ToggleSelect, ToggleGroupIndex.LeftBagItem)
            script:SetItemGray(bShowGray)
            script:SetClickCallback(function(dwItemTabType, dwItemTabIndex)
                self.uiItemTipScript = self.uiItemTipScript or UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetTip)
                self.scriptCurSelectedItem = script
                if bShowGray then
                    self.uiItemTipScript:SetForbidInitWithBtn(true)
                else
                    self.uiItemTipScript:SetForbidInitWithBtn(false)
                    self.uiItemTipScript:ShowPlacementBtn(true, 1, 1, "置入", "", function (nCurCount)
                        Event.Dispatch(EventType.OnPrefumeAddMaterial, self.nSelectedSlot, dwItemTabIndex, nCurCount)
                    end)
                end
                self.uiItemTipScript:OnInitWithTabID(dwItemTabType, dwItemTabIndex)
                Event.Dispatch(EventType.OnLeftBagSelectItem)
            end)
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollBag)
    UIHelper.SetVisible(self.WidgetEmpty, not bHasAny)
end

return UIHomeIdentityPrefumeLeftBag