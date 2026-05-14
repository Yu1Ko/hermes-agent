-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopReplaceOutfitItem
-- Date: 2022-12-26 09:27:36
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopReplaceOutfitItem = class("UICoinShopReplaceOutfitItem")

function UICoinShopReplaceOutfitItem:OnEnter(replaceView, nMiniSceneIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nMiniSceneIndex = nMiniSceneIndex
    self.replaceView = replaceView
end

function UICoinShopReplaceOutfitItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopReplaceOutfitItem:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnReplace, EventType.OnClick, function ()
        self.replaceView:RpelaceOutfit(self.tbOutfit.nLocalIndex)
    end)
end

function UICoinShopReplaceOutfitItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICoinShopReplaceOutfitItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopReplaceOutfitItem:UpdateOutfit(tbOutfit)
    self.tbOutfit = tbOutfit
    UIHelper.SetVisible(self.WidgetAll, true)
    UIHelper.SetVisible(self.WidgetClothesTitle, true)
    UIHelper.SetString(self.LabelClothesTitle, UIHelper.GBKToUTF8(tbOutfit.szName))
    UIHelper.SetVisible(self.WidgetReplace, true)
    UIHelper.SetVisible(self.WidgetEmpty, false)

    self:UpdateOutfitView(tbOutfit)
end

function UICoinShopReplaceOutfitItem:Empty()
    self.tbOutfit = nil
    UIHelper.SetVisible(self.WidgetAll, true)
    UIHelper.SetVisible(self.WidgetClothesTitle, false)
    UIHelper.SetVisible(self.WidgetReplace, false)
    UIHelper.SetVisible(self.WidgetEmpty, true)

    ModelHelper.UpdateModel(self.nMiniSceneIndex, nil, g_pClientPlayer.nRoleType)
end

function UICoinShopReplaceOutfitItem:Hide()
    self.tbOutfit = nil
    UIHelper.SetVisible(self.WidgetAll, false)

    ModelHelper.UpdateModel(self.nMiniSceneIndex, nil, g_pClientPlayer.nRoleType)
end

function UICoinShopReplaceOutfitItem:UpdateOutfitView(tOutfit)
    if not g_pClientPlayer then return end

    local tRepresentID = CoinShopData.GetOutfitRepresent(tOutfit)
    if not tRepresentID then return end

    ModelHelper.UpdateModel(self.nMiniSceneIndex, tRepresentID, g_pClientPlayer.nRoleType)
end

return UICoinShopReplaceOutfitItem