-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandPVPRewardCell
-- Date: 2023-04-06 14:30:47
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandPVPRewardCell = class("UIHomelandPVPRewardCell")

function UIHomelandPVPRewardCell:OnEnter(tbInfo, togGroupRewardItem)
    self.tbInfo = tbInfo
    self.TogGroupRewardItem = togGroupRewardItem

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandPVPRewardCell:OnExit()
    self.bInit = false
end

function UIHomelandPVPRewardCell:BindUIEvent()

end

function UIHomelandPVPRewardCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandPVPRewardCell:UpdateInfo()
    UIHelper.SetString(self.LabelRewardTitle, string.format("%s  %s", UIHelper.GBKToUTF8(self.tbInfo.szName), UIHelper.GBKToUTF8(self.tbInfo.szIntroduction)))
    UIHelper.SetSpriteFrame(self.ImgRewardIcon, HomeLandPvpAwardIcon[self.tbInfo.dwLevel])
    local tReward = SplitString(self.tbInfo.szReward, ";")
    self.tbCells = {}
	for k, String in pairs(tReward) do
		local t = SplitString(String, ":")
        local scriptItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.LayoutWidgetItem_80)
        scriptItemIcon:OnInitWithTabID(tonumber(t[1]), tonumber(t[2]))
        scriptItemIcon:SetLabelCount(tonumber(t[3]))
        scriptItemIcon:SetClickCallback(function ()
            TipsHelper.ShowItemTips(scriptItemIcon._rootNode, tonumber(t[1]), tonumber(t[2]), false)
        end)
        table.insert(self.tbCells, scriptItemIcon)

        UIHelper.SetSwallowTouches(scriptItemIcon.ToggleSelect, false)
        UIHelper.ToggleGroupAddToggle(self.TogGroupRewardItem, scriptItemIcon.ToggleSelect)
	end

    UIHelper.LayoutDoLayout(self.LayoutWidgetItem_80)
end

function UIHomelandPVPRewardCell:SetSelected(bSelected)
    for i, cell in ipairs(self.tbCells) do
        UIHelper.SetSelected(cell.ToggleSelect, false)
    end
end

return UIHomelandPVPRewardCell