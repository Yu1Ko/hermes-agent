-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeAchievementPopAccessCell
-- Date: 2023-07-19 20:12:36
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeAchievementPopAccessCell = class("UIHomeAchievementPopAccessCell")

function UIHomeAchievementPopAccessCell:OnEnter(szActivity, nTypeFrame, dwActivityID)
    self.szActivity = szActivity
    self.nTypeFrame = nTypeFrame
    self.dwActivityID = dwActivityID
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(self.szActivity)
    if UIMgr.GetView(VIEW_ID.PanelActivityCalendar) then
        UIMgr.Close(VIEW_ID.PanelActivityCalendar)
    end
end

function UIHomeAchievementPopAccessCell:OnExit()
    self.bInit = false
end

function UIHomeAchievementPopAccessCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAccess01, EventType.OnClick, function()
        ActivityData.LinkToActiveByID(self.dwActivityID)
	end)
end

function UIHomeAchievementPopAccessCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomeAchievementPopAccessCell:UpdateInfo(szActivity)
    -- UIHelper.SetString(self.LabelAccess01, szActivity)
    UIHelper.SetVisible(self.LabelAccess01, false)
    UIHelper.SetVisible(self.LabelAccess02, false)
    UIHelper.SetVisible(self.BtnAccess01, false)
    
    if self.dwActivityID <= 0 then
        UIHelper.SetString(self.LabelAccess02, szActivity)
        UIHelper.SetVisible(self.LabelAccess02, true)
    else
        UIHelper.SetString(self.LabelAccess01, szActivity)
        UIHelper.SetVisible(self.LabelAccess01, true)
        UIHelper.SetVisible(self.BtnAccess01, true)
    end
    UIHelper.LayoutDoLayout(self.WidgetRightPopAccessCell)
    UIHelper.WidgetFoceDoAlign(self)
end


return UIHomeAchievementPopAccessCell