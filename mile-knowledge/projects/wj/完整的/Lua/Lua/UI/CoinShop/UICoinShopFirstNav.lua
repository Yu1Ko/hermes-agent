-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopFirstNav
-- Date: 2022-12-14 20:19:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopFirstNav = class("UICoinShopFirstNav")

function UICoinShopFirstNav:OnEnter(tbClass, fnSelectCb, fnDoLayout)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbClass = tbClass
    self.fnSelectCb = fnSelectCb
    self.fnDoLayout = fnDoLayout
    self.tbSecondNav = nil
    self.tbCurSelect = nil
    self:UpdateInfo()
end

function UICoinShopFirstNav:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UICoinShopFirstNav:BindUIEvent()
    UIHelper.BindUIEvent(self.TogFirstNav, EventType.OnClick, function ()
        if self.tbClass.bOutfit then
            self.fnSelectCb(self.tbClass)
            return
        end
        local bSelf = self:CheckSelf(self.tbCurSelect)
        if not bSelf then
            self.fnSelectCb(self.tbClass.tList[1])
            return
        end
        if not self.tbSecondNav then
            self:ShowSecondNav()
        else
            self:HideSecondNav()
        end
        UIHelper.SetSelected(self.TogFirstNav, bSelf, false)
    end)
end

function UICoinShopFirstNav:RegEvent()
end

function UICoinShopFirstNav:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopFirstNav:UpdateInfo()
    local szTitleName
    if self.tbClass.bOutfit then
        szTitleName = g_tStrings.COINSHOP_OUTFIT_TITLE
    elseif self.tbClass.bRewardsTab then
        szTitleName = UIHelper.GBKToUTF8(self.tbClass.szName)
    else
        szTitleName = UIHelper.GBKToUTF8(self.tbClass.szTitleName)
    end

    UIHelper.SetVisible(self.ImgNew, false)
    UIHelper.SetString(self.LabelUpAll01, szTitleName)
    UIHelper.SetString(self.LabelNormalAll01, szTitleName)

    UIHelper.LayoutDoLayout(self.LayoutSecondNav)
    UIHelper.LayoutDoLayout(self.LayoutTabList)
    UIHelper.LayoutDoLayout(self.WidgetTabList)

    local bShowLabel = CoinShopData.IsShowTitleLabel(self.tbClass)
end

function UICoinShopFirstNav:OnSelectTitle(tbCurSelect)
    self.tbCurSelect = tbCurSelect
    local bSelf = self:CheckSelf(tbCurSelect)
    if bSelf then
        self:ShowSecondNav()
    else
        self:HideSecondNav()
    end
    self:CheckSecondNav()
    UIHelper.SetSelected(self.TogFirstNav, bSelf, false)
end

function UICoinShopFirstNav:ShowSecondNav()
    if self.tbSecondNav then
        return
    end
    if not self.tbClass.tList then
        return
    end
    self.tbSecondNav = {}
    for _, tbTitle in ipairs(self.tbClass.tList) do
        local secondNav = UIHelper.AddPrefab(PREFAB_ID.WidgetSecondNav, self.LayoutSecondNav)
        secondNav:OnEnter(tbTitle, self.fnSelectCb)
        table.insert(self.tbSecondNav, secondNav)
    end
    UIHelper.LayoutDoLayout(self.LayoutSecondNav)
    UIHelper.LayoutDoLayout(self.LayoutTabList)
    UIHelper.LayoutDoLayout(self.WidgetTabList)
    self.fnDoLayout()
    self:CheckSecondNav()
end

function UICoinShopFirstNav:HideSecondNav()
    if not self.tbSecondNav then
        return
    end
    self.LayoutSecondNav:removeAllChildren()
    self.tbSecondNav = nil
    UIHelper.LayoutDoLayout(self.LayoutSecondNav)
    UIHelper.LayoutDoLayout(self.LayoutTabList)
    UIHelper.LayoutDoLayout(self.WidgetTabList)
    self.fnDoLayout()
end

function UICoinShopFirstNav:CheckSecondNav()
    if not self.tbSecondNav then
        return
    end
    for _, secondNav in ipairs(self.tbSecondNav) do
        secondNav:Check(self.tbCurSelect)
    end
end

function UICoinShopFirstNav:CheckSelf(tbCheck)
    local bSelf = false
    if tbCheck.bOutfit then
        bSelf = self.tbClass.bOutfit
    elseif tbCheck.bRewardsTab then
        bSelf = self.tbClass.bRewardsTab and self.tbClass.nRewardsClass == tbCheck.nRewardsClass
    else
        bSelf = not self.tbClass.bRewardsTab and self.tbClass.nTitleClass == tbCheck.nTitleClass
    end
    return bSelf
end

return UICoinShopFirstNav