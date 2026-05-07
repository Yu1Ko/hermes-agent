-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIShenBingUpgradeView
-- Date: 2024-04-22 13:17:06
-- Desc: ?
-- ---------------------------------------------------------------------------------


local UIShenBingUpgradeView = class("UIShenBingUpgradeView")

function UIShenBingUpgradeView:OnEnter(bEquipCopy,nLevel)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bEquipCopy = bEquipCopy
    UIHelper.SetVisible(self.ImgTitleChengWu, not bEquipCopy)
    UIHelper.SetVisible(self.ImgTitleMozhu, bEquipCopy)
    UIHelper.SetVisible(self.BtnRule, bEquipCopy)

    Global.SetShowRewardListEnable(VIEW_ID.PanelShenBingUpgrade, true)
    Global.SetShowLeftRewardTipsEnable(VIEW_ID.PanelShenBingUpgrade, false)

    self:UpdateInfo(nLevel)

    if not APIHelper.IsDid("OrangeWeaponUpg.Open") then
        APIHelper.Do("OrangeWeaponUpg.Open")
        Event.Dispatch(EventType.OrangeWeaponUpgRedPoint)
    end
end

function UIShenBingUpgradeView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Global.SetShowRewardListEnable(VIEW_ID.PanelShenBingUpgrade, false)
    Global.SetShowLeftRewardTipsEnable(VIEW_ID.PanelShenBingUpgrade, true)
end

function UIShenBingUpgradeView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnRule, EventType.OnClick, function ()
        APIHelper.ShowRule(70)
    end)
end

function UIShenBingUpgradeView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIShenBingUpgradeView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIShenBingUpgradeView:UpdateInfo(nLevel)
    if self.bEquipCopy then
        UIHelper.AddPrefab(PREFAB_ID.WidgetMoZhu, self.WidgetPageContent)
    else
        UIHelper.AddPrefab(PREFAB_ID.WidgetXiaoChengWu, self.WidgetPageContent, nLevel)
    end
end


return UIShenBingUpgradeView