-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UILoginServerListArean
-- Date: 2022-11-07 15:17:06
-- Desc: 登录选服界面：大区 WidgetAreanServerList
-- ---------------------------------------------------------------------------------

local UILoginServerListArean = class("UILoginServerListArean")

UILoginServerListArean.m_nIndex = 0
UILoginServerListArean.m_uiView = nil

function UILoginServerListArean:OnEnter(nIndex, uiView)
	if not nIndex or not uiView then
		return
	end

	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()

		self.bInit = true
	end

	self.m_nIndex = nIndex
	self.m_uiView = uiView

	UIHelper.ToggleGroupAddToggle(self.m_uiView.AreanToggleGroup, self.TogAreanList1)
	self:UpdateInfo()
end

function UILoginServerListArean:OnExit()
	self.bInit = false
	self:UnRegEvent()

	if self.m_uiView then
		UIHelper.ToggleGroupRemoveToggle(self.m_uiView.AreanToggleGroup, self.TogAreanList1)
	end
end

function UILoginServerListArean:BindUIEvent()
	UIHelper.BindUIEvent(self.TogAreanList1, EventType.OnSelectChanged, function(toggle, bSelected)
		if bSelected then
			self.m_uiView:OnRegionSelected(self.m_nIndex)
		end
	end)
end

function UILoginServerListArean:RegEvent()

end

function UILoginServerListArean:UnRegEvent()
	Event.UnRegAll(self)
end

function UILoginServerListArean:UpdateInfo()
	local tbRegion = g_tbLoginData.aServerList[self.m_nIndex]
	if tbRegion then
		UIHelper.SetString(self.LabelNormal, tbRegion.szSimpleRegion)
		UIHelper.SetString(self.LabelSelect, tbRegion.szSimpleRegion)

		local nServerType = self.m_uiView:GetTypeByString(tbRegion.szDisplayRegion)

		--2024.8.1 需求，图标固定不显示了，因为都改为点月卡计费
		nServerType = 0

		if nServerType == 1 then --点卡区
			UIHelper.SetVisible(self.ImgMonthCard01, false)
			UIHelper.SetVisible(self.ImgMonthCard02, false)
			UIHelper.SetVisible(self.ImgTimeCard01, true)
			UIHelper.SetVisible(self.ImgTimeCard002, true)
		elseif nServerType == 2 then --点月卡区
			UIHelper.SetVisible(self.ImgMonthCard01, true)
			UIHelper.SetVisible(self.ImgMonthCard02, true)
			UIHelper.SetVisible(self.ImgTimeCard01, false)
			UIHelper.SetVisible(self.ImgTimeCard002, false)
		else
			UIHelper.SetVisible(self.ImgMonthCard01, false)
			UIHelper.SetVisible(self.ImgMonthCard02, false)
			UIHelper.SetVisible(self.ImgTimeCard01, false)
			UIHelper.SetVisible(self.ImgTimeCard002, false)
		end

		local bNew = not not string.find(tbRegion.szSimpleRegion, "无界区") -- not not -> to bool
		UIHelper.SetVisible(self.ImgNewTag, bNew)
	end
end


return UILoginServerListArean