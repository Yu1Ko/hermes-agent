-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIDbmCell
-- Date: 2023-12-19 17:36:25
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIDbmCell = class("UIDbmCell")

function UIDbmCell:OnEnter(tbData, nIndex)
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
	self.tbData = tbData
	self.sliderNode = nil
	self:UpdateSliderCorlor()
	if MainCityCustomData.bSubsidiaryCustomState and tbData.bFake then
		self:UpdateFakeDbmInfo()
	else
		self:UpdateDbmInfo()
	end

end

function UIDbmCell:OnExit()
	self.bInit = false
	Timer.DelAllTimer()
	self:UnRegEvent()
end

function UIDbmCell:BindUIEvent()
	
end

function UIDbmCell:RegEvent()
	--Event.Reg(self, EventType.XXX, func)
end

function UIDbmCell:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIDbmCell:UpdateSliderCorlor()
	for i, slider in ipairs(self.tbSliderList) do
		UIHelper.SetVisible(slider, false)
	end
	local nResult = self.tbData.nIndex % 3
	if nResult == 1 then
		UIHelper.SetVisible(self.tbSliderList[1], true)
		self.sliderNode = self.tbSliderList[1]
	elseif nResult == 2 then
		UIHelper.SetVisible(self.tbSliderList[2], true)
		self.sliderNode = self.tbSliderList[2]
	elseif nResult == 0 then
		UIHelper.SetVisible(self.tbSliderList[3], true)
		self.sliderNode = self.tbSliderList[3]
	end
end

function UIDbmCell:UpdateDbmInfo()
	local tbData = self.tbData
	local callback = tbData.callback
	local szSkillName = tbData.szSkill
	local nCurTime = Timer.GetPassTime()
	UIHelper.SetString(self.LabelSkill, szSkillName)
	UIHelper.SetString(self.LabelTime, string.format("%d秒", tbData.nTime))
	if tbData.nTime then
		UIHelper.SetProgressBarPercent(self.sliderNode, 100)
		Timer.AddFrameCycle(self, 3, function()
			self.nPercent = 100 * (tbData.nTime - (Timer.GetPassTime() - nCurTime)) / tbData.nTime
			UIHelper.SetString(self.LabelTime, string.format("%.1f秒", tbData.nTime - (Timer.GetPassTime() - nCurTime)))
			UIHelper.SetProgressBarPercent(self.sliderNode, self.nPercent)
			if Timer.GetPassTime()- nCurTime >= tbData.nTime then
				callback(self._rootNode)
				Timer.DelAllTimer()
				return
			end
		end)
	end

end

function UIDbmCell:UpdateFakeDbmInfo()
	UIHelper.SetString(self.LabelSkill, self.tbData.szSkill)
	UIHelper.SetString(self.LabelTime, string.format("%d秒", self.tbData.nTime))
	local nPercent = 100 * self.tbData.nTime / self.tbData.nTotalTime
	UIHelper.SetProgressBarPercent(self.sliderNode, nPercent)
end

return UIDbmCell