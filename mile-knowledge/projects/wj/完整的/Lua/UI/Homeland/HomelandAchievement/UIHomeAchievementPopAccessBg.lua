-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeAchievementPopAccessBg
-- Date: 2023-07-24 15:18:40
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeAchievementPopAccessBg = class("UIHomeAchievementPopAccessBg")
local tColor = {
    [40] = cc.c3b(0x95, 0xff, 0x95),
    [41] = cc.c3b(0xdb, 0xbb, 0xff),
    [42] = cc.c3b(0xff, 0xe2, 0x6e),
}
local tTypeTitle = {
    [40] = "日常",
    [41] = "循环",
    [42] = "周常",
}
function UIHomeAchievementPopAccessBg:OnEnter(tActivity, nTypeFrame)
    self.nTypeFrame = nTypeFrame
    self.tActivity = tActivity
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomeAchievementPopAccessBg:OnExit()
    self.bInit = false
end

function UIHomeAchievementPopAccessBg:BindUIEvent()
    
end

function UIHomeAchievementPopAccessBg:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomeAchievementPopAccessBg:UpdateInfo()
    UIHelper.RemoveAllChildren(self.LayoutAccessBg)
    UIHelper.SetTextColor(self.LabelTitle, tColor[self.nTypeFrame])
    UIHelper.SetString(self.LabelTitle,tTypeTitle[self.nTypeFrame])
    for i, tbActivity in pairs(self.tActivity) do
        if not table_is_empty(tbActivity) then
            local scriptAccessCell = UIHelper.AddPrefab(PREFAB_ID.WidgetRightPopAccessCell, self.LayoutAccessBg)
            scriptAccessCell:OnEnter(tbActivity.szGainDesc, self.nTypeFrame, tbActivity.dwActivityID)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutAccessBg)
    UIHelper.LayoutDoLayout(self.LayoutRoot)

    UIHelper.WidgetFoceDoAlign(self)
end


return UIHomeAchievementPopAccessBg