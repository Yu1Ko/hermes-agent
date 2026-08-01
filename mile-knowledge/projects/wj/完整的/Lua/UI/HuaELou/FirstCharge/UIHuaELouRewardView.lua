-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHuaELouRewardView
-- Date: 2022-12-30 16:30:57
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHuaELouRewardView = class("UIHuaELouRewardView")

function UIHuaELouRewardView:OnEnter(dwTabType, dwIndex, nStackNum, bCanGet, szImgPath)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwTabType, self.dwIndex, self.nStackNum, self.bCanGet = dwTabType, dwIndex, nStackNum, bCanGet
    self.tbItem = ItemData.GetItemInfo(self.dwTabType, self.dwIndex)
    UIHelper.SetSwallowTouches(self.ToggleSelect, false)
    self:UpdateInfo(szImgPath)
end

function UIHuaELouRewardView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHuaELouRewardView:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function(toggle, bSelected)
        Event.Dispatch(EventType.OnSelectItem, self.dwTabType, self.dwIndex, bSelected, self.ToggleSelect)
        if self.fCallBack and self.ToggleSelect == toggle then
            self.fCallBack(bSelected)
        end
    end)

    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnClick, function()
        if self.funcClickCallback then
            self.funcClickCallback(self.dwTabType, self.dwIndex)
        end
    end)
end

function UIHuaELouRewardView:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        local bSelected = UIHelper.GetSelected(self.ToggleSelect)
        if bSelected then
            UIHelper.SetSelected(self.ToggleSelect, false)
        end
    end)
end

function UIHuaELouRewardView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHuaELouRewardView:SetClickCallback(callback)
    self.funcClickCallback = callback
end

function UIHuaELouRewardView:SetCanGetState(bCanGet, bGetton)
    UIHelper.SetVisible(self.WidgetReceived, bGetton)
    UIHelper.SetVisible(self.ImgCheck, bGetton)
    UIHelper.SetVisible(self.ImgNotReady, false)
end

function UIHuaELouRewardView:UpdateInfo(szImgPath)
    UIHelper.SetString(self.LabelCount, self.nStackNum)
    if self.tbItem then
        UIHelper.SetItemIconByItemInfo(self.ImgIcon, self.tbItem)
    elseif szImgPath then
        UIHelper.SetSpriteFrame(self.ImgIcon, szImgPath)
    else
        UIHelper.SetSpriteFrame(self.ImgIcon, "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_TongBao_Big")
    end

    local pItemInfo = ItemData.GetItemInfo(self.dwTabType,  self.dwIndex)
    if pItemInfo then
        UIHelper.SetSpriteFrame(self.ImgPolishCountBG, ItemQualityBGColor[pItemInfo.nQuality + 1])

        UIHelper.SetVisible(self.Eff_Orange, false)
        if pItemInfo.nQuality == 5 then
            UIHelper.SetVisible(self.Eff_Orange, true)
        end
    end

    UIHelper.SetTouchDownHideTips(self.ToggleSelect, false)
end

function UIHuaELouRewardView:SetSelectChangeCallback(fCallBack)
    self.fCallBack = fCallBack
end

return UIHuaELouRewardView