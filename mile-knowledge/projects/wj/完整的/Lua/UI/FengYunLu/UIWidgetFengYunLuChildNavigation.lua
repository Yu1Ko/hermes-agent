-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetPvPCampRewardListNormal
-- Date: 2023-03-02 19:49:15
-- Desc: WidgetPvPCampRewardListAttribute、WidgetPvPCampRewardListEquip
-- ---------------------------------------------------------------------------------

local szPathNormal = "UIAtlas2_Bag_ChildTabIcon_Normal_%s.png"
local szPathSelected = "UIAtlas2_Bag_ChildTabIcon_Selected_%s.png"

local WidgetFengYunLuChildNavigation = class("WidgetFengYunLuChildNavigation")

function WidgetFengYunLuChildNavigation:OnEnter(tInfo)
    self.szTitle = tInfo and tInfo.szTitle
    self.szContent = tInfo and tInfo.szContent
    self.onSelectChangeFunc = tInfo and tInfo.onSelectChangeFunc

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        UIHelper.SetSwallowTouches(self.ToggleChildNavigation, false)
    end

    self:UpdateInfo()
end

function WidgetFengYunLuChildNavigation:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function WidgetFengYunLuChildNavigation:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleChildNavigation, EventType.OnSelectChanged, self.onSelectChangeFunc)
end

function WidgetFengYunLuChildNavigation:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function WidgetFengYunLuChildNavigation:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function WidgetFengYunLuChildNavigation:UpdateInfo()
    if self.szTitle then
        if self.LabelNormal then
            UIHelper.SetString(self.LabelNormal, self.szTitle)
        end
        if self.LabelSelect then
            UIHelper.SetString(self.LabelSelect, self.szTitle)
        end

        if self.ImgIcon then
            UIHelper.SetSpriteFrame(self.ImgIcon, string.format(szPathNormal, ITEM_FILTER_ICON_NAME[self.szTitle]))
        end
        if self.ImgIconSelected then
            UIHelper.SetSpriteFrame(self.ImgIconSelected, string.format(szPathSelected, ITEM_FILTER_ICON_NAME[self.szTitle]))
        end
    end
end

function WidgetFengYunLuChildNavigation:SetSelected(bSelected, bCallback)
    UIHelper.SetSelected(self.ToggleChildNavigation, bSelected, bCallback)
end

function WidgetFengYunLuChildNavigation:GetName()
    return self.szTitle
end

function WidgetFengYunLuChildNavigation:ShowLeftSelectUp(bShow)
    UIHelper.SetVisible(self.ImgUp, not bShow)
    UIHelper.SetVisible(self.ImgUpL, bShow)
end

return WidgetFengYunLuChildNavigation