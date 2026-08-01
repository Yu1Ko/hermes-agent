-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaPrestigeTipView
-- Date: 2023-01-03 21:23:02
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaPrestigeTipView = class("UIArenaPrestigeTipView")

function UIArenaPrestigeTipView:OnEnter(nPrestigeExtRemain)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nPrestigeExtRemain = nPrestigeExtRemain
    self:UpdateInfo()
end

function UIArenaPrestigeTipView:OnExit()
    self.bInit = false
end

function UIArenaPrestigeTipView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

end

function UIArenaPrestigeTipView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIArenaPrestigeTipView:UpdateInfo()
    UIHelper.SetString(self.LabelRewardRule2, "（2）五胜达成后宝箱通过邮件一次性发放。赛季开启2个月后，每获胜2次可额外获得1个宝箱，每周最多额外获得10个。")
    UIHelper.SetString(self.LabelWeiMingDianNum, self.nPrestigeExtRemain)

    UIHelper.ScrollViewDoLayout(self.ScrollViewArenaIntegral)
    UIHelper.ScrollToTop(self.ScrollViewArenaIntegral)
end


return UIArenaPrestigeTipView