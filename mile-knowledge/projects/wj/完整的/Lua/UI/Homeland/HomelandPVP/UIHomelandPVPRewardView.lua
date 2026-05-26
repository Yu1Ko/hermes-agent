-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandPVPRewardView
-- Date: 2023-04-06 14:29:13
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandPVPRewardView = class("UIHomelandPVPRewardView")

function UIHomelandPVPRewardView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandPVPRewardView:OnExit()
    self.bInit = false
end

function UIHomelandPVPRewardView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
end

function UIHomelandPVPRewardView:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
		self:ClearSelect()
	end)
end

function UIHomelandPVPRewardView:UpdateInfo()
    self.tbCells = {}
    for _, tbInfo in pairs(HomelandPVPData.tRewardLevel) do
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetRewardCell, self.ScrollViewReward)
        scriptCell:OnEnter(tbInfo, self.TogGroupRewardItem)
        table.insert(self.tbCells, scriptCell)
    end

    self:ClearSelect()

    UIHelper.ScrollViewDoLayout(self.ScrollViewReward)
    UIHelper.ScrollToTop(self.ScrollViewReward, 0)
end

function UIHomelandPVPRewardView:ClearSelect()
    for index, scriptCell in ipairs(self.tbCells) do
        scriptCell:SetSelected(false)
    end
end


return UIHomelandPVPRewardView