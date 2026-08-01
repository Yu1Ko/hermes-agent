-- ---------------------------------------------------------------------------------
-- Author: liu yu min
-- Name: UIWidgetSkillCell
-- Date: 2023-08-10 11:37:38
-- Desc: PanelJiangHuBaiTai
-- ---------------------------------------------------------------------------------

local UIWidgetSkillCell = class("UIWidgetSkillCell")

function UIWidgetSkillCell:OnEnter(tbSkillList, nIndex, bIsPet, bFirst)
	self.tbSkillList = tbSkillList
	self.nIndex = nIndex
	self.bIsPet = bIsPet
	self.bFirst = bFirst
	self.tbIconList = {}
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIWidgetSkillCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSkillCell:BindUIEvent()
	for k, v in pairs(self.tbTogList) do
		UIHelper.BindUIEvent(self.tbTogList[k], EventType.OnClick, function()
			if self.bIsPet then --宠物提示
				--TipsHelper.ShowItemTips(self._rootNode, self.tbSkillList[self.nIndex * 5 + k][1], self.tbSkillList[self.nIndex * 5 + k][2], false)
				Event.Dispatch("ON_SHOWPETDETAILINFO", self.tbSkillList[self.nIndex * 5 + k][1], self.tbSkillList[self.nIndex * 5 + k][2])
			else
				Event.Dispatch("On_OpenAnchorLeftPop",self.tbSkillList[self.nIndex * 5 + k][1], self.tbSkillList[self.nIndex * 5 + k][2]) --左侧技能提示
			end
		end)
	end
end

function UIWidgetSkillCell:RegEvent()
	Event.Reg(self, "On_CancelSkillSelected", function()
		for k, v in pairs(self.tbTogList) do
			UIHelper.SetSelected(v, false)
		end
    end)
end

function UIWidgetSkillCell:UnRegEvent()
    Event.UnReg(self, "On_CancelSkillSelected")
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSkillCell:UpdateInfo()
	self.tbIconList = {}
	for k, v in pairs(self.tbTogList) do
		local tMask = self.tbMaskSkillIcon[k]
		UIHelper.SetToggleGroupIndex(self.tbTogList[k], ToggleGroupIndex.PartnerSkill)
		local nIconID = nil
		if self.bIsPet and self.tbSkillList[self.nIndex * 5 + k] then
			local KItemInfo = GetItemInfo(self.tbSkillList[self.nIndex * 5 + k][1], self.tbSkillList[self.nIndex * 5 + k][2])
			nIconID = Table_GetItemIconID(KItemInfo.nUiId)
		elseif self.tbSkillList[self.nIndex * 5 + k] then
			nIconID = Table_GetSkillIconID(self.tbSkillList[self.nIndex * 5 + k][1], self.tbSkillList[self.nIndex * 5 + k][2])
		else
			UIHelper.SetVisible(self.tbTogList[k], false)
		end
		if nIconID then
			table.insert(self.tbIconList, k, nIconID)
			UIHelper.SetItemIconByIconID(self.tbSkillIcon[k], nIconID)
			UIHelper.SetVisible(v, false)
			if not self.bFirst then
				Timer.Add(self, 0.05, function ()
					UIHelper.UpdateMask(tMask)
					UIHelper.SetVisible(v, true)
					UIHelper.LayoutDoLayout(self._rootNode)
				end)
				UIHelper.UpdateMask(tMask)
			end
		end

		UIHelper.SetSwallowTouches(v,false)
		UIHelper.SetTouchDownHideTips(v, false)
	end
	if self.bFirst then
		Timer.Add(self, 0.4, function ()
			for k, v in pairs(self.tbTogList) do
				if self.tbIconList[k] then
					local tMask = self.tbMaskSkillIcon[k]
					UIHelper.UpdateMask(tMask)
					UIHelper.SetVisible(v, true)
					UIHelper.LayoutDoLayout(self._rootNode)
				end
			end
		end)
	end
end

return UIWidgetSkillCell