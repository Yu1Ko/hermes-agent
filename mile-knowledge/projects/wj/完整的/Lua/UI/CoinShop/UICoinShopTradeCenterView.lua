-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopTradeCenterView
-- Date: 2023-04-12 20:20:00
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopTradeCenterView = class("UICoinShopTradeCenterView")

function UICoinShopTradeCenterView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tStorageScriptList = {}
    self:UpdateInfo()
end

function UICoinShopTradeCenterView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UICoinShopTradeCenterView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnReceive, EventType.OnClick, function ()
        for _, script in ipairs(self.tStorageScriptList) do
            script:TakeStorageGoods()
        end
    end)
end

function UICoinShopTradeCenterView:RegEvent()
    Event.Reg(self, "ADD_STORAGE_GOODS", function ()
        self:OnAddStorageItem(arg0)
    end)

    Event.Reg(self, "DEL_STORAGE_GOODS", function ()
        self:OnDelStorageItem(arg0)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        self:ClearSelect()
    end)
end

function UICoinShopTradeCenterView:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopTradeCenterView:UpdateInfo()
    self:UpdateStorageList()
end

function UICoinShopTradeCenterView:UpdateStorageList()
    UIHelper.RemoveAllChildren(self.ScrollViewInfoCommodity)
    self.tStorageScriptList = {}
    local tStorageList = CoinShopData.GetStorageGoodsList()
    if #tStorageList > 0 then
        for _, dwStorageID in ipairs(tStorageList) do
            self:AddOneStorage(dwStorageID)
        end
        UIHelper.ScrollToTop(self.ScrollViewInfoCommodity)
    else
        self:UpdateStorageStatus()
    end
end

function UICoinShopTradeCenterView:AddOneStorage(dwStorageID)
    if dwStorageID <= 0 then
        return
    end
    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetTradingCommodity, self.ScrollViewInfoCommodity, dwStorageID)
    table.insert(self.tStorageScriptList, script)
    self:UpdateStorageStatus()
end

function UICoinShopTradeCenterView:OnAddStorageItem(dwStorageID)
    self:AddOneStorage(dwStorageID)
end

function UICoinShopTradeCenterView:OnDelStorageItem(dwStorageID)
    for i, script in ipairs(self.tStorageScriptList) do
        if script.dwStorageID == dwStorageID then
            UIHelper.RemoveFromParent(script._rootNode)
            table.remove(self.tStorageScriptList, i)
            self:UpdateStorageStatus()
            break
        end
    end
end

function UICoinShopTradeCenterView:UpdateStorageStatus()
    if #self.tStorageScriptList > 0 then
        UIHelper.SetVisible(self.ScrollViewInfoCommodity, true)
        UIHelper.ScrollViewDoLayout(self.ScrollViewInfoCommodity)
        UIHelper.SetVisible(self.WidgetEmpty, false)
        UIHelper.SetVisible(self.ImgRedDot01, true)
        UIHelper.SetButtonState(self.BtnReceive, BTN_STATE.Normal)
    else
        UIHelper.SetVisible(self.ScrollViewInfoCommodity, false)
        UIHelper.SetVisible(self.WidgetEmpty, true)
        UIHelper.SetVisible(self.ImgRedDot01, false)
        UIHelper.SetButtonState(self.BtnReceive, BTN_STATE.Disable)
    end
end

function UICoinShopTradeCenterView:ClearSelect()
    if #self.tStorageScriptList > 0 then
        for _, script in ipairs(self.tStorageScriptList) do
            if script.itemIconScript then
                script.itemIconScript:SetSelected(false)
            end
        end
    end
end

return UICoinShopTradeCenterView