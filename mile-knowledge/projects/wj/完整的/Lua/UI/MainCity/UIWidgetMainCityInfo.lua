
-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIWidgetMainCityInfo
-- Date: 2022-11-14
-- Desc: 场景信息框
-- ---------------------------------------------------------------------------------

local COLOR_NORMAL = cc.c3b(215,246,255)
local COLOR_RED = cc.RED


local UIWidgetMainCityInfo = class("UIWidgetMainCityInfo")

function UIWidgetMainCityInfo:OnEnter()
	self.m = {}
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end

	self:Init()

	-- 玩家进入后周期刷新
	self:OnUpdate()
	self.m.nTimerID = Timer.AddCycle(self, 1, function ()
		self:OnUpdate()
	end)

end

function UIWidgetMainCityInfo:OnExit()
	self.bInit = false
	self:UnRegEvent()


	if self.m.nTimerID then
		Timer.DelTimer(self, self.m.nTimerID)
		self.m.nTimerID = nil
	end

	self.m = nil
end

function UIWidgetMainCityInfo:BindUIEvent()
	-- UIHelper.BindUIEvent(self.TakeAllBtn, EventType.OnClick, function()
	-- 	print("----> self.TakeAllBtn, EventType.OnClick")
	-- end)
end

function UIWidgetMainCityInfo:RegEvent()

end

function UIWidgetMainCityInfo:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end

function UIWidgetMainCityInfo:OnUpdate()
	self:UpdateTime()
	self:UpdateSignal()

	-- 电池10秒刷一次
	local nNow = os.time()
	if (nNow - (self.nLastUpdateTime or 0)) >= 10 then
		self:UpdateBattery()
		self.nLastUpdateTime = nNow
	end
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

local Def = {

}


function UIWidgetMainCityInfo:Init()
	UIHelper.SetVisible(self.WidgetBattery, Platform.IsMobile())
	UIHelper.LayoutDoLayout(self.LayoutMainCityInfo)
end



function UIWidgetMainCityInfo:UpdateTime()
	local nTime = GetCurrentTime()
	local tDate = TimeToDate(nTime)
	UIHelper.SetString(self.LableTime, string.format("%02d:%02d:%02d", tDate.hour, tDate.minute, tDate.second))
end

function UIWidgetMainCityInfo:UpdateBattery()
	local nBattery = App_GetBatteryPercentage()

	-- 电量进度颜色
	if nBattery >= 0 and nBattery <= 20 then
		UIHelper.SetColor(self.SliderBattery, COLOR_RED)
	else
		UIHelper.SetColor(self.SliderBattery, COLOR_NORMAL)
	end
	--self.SliderBattery:loadTexture(szSprite, ccui.TextureResType.plistType)

	if Platform.IsWindows() or Platform.IsMac() then
		UIHelper.SetProgressBarPercent(self.SliderBattery, 100)
	else
		UIHelper.SetProgressBarPercent(self.SliderBattery, nBattery)
	end
end

function UIWidgetMainCityInfo:UpdateSignal()
	local nNetMode = App_GetNetMode()
	if nNetMode == NET_MODE.WIFI then
		UIHelper.SetVisible(self.WidgetWifi, true)
		UIHelper.SetVisible(self.WidgetSignal, false)
		local nWifi = App_GetNetLatency()
		self:UpdateNet(nNetMode, nWifi ,self.tbWifiList)
	elseif nNetMode == NET_MODE.CELLULAR then
		UIHelper.SetVisible(self.WidgetWifi, false)
		UIHelper.SetVisible(self.WidgetSignal, true)
		local nSignal = App_GetNetLatency()
		self:UpdateNet(nNetMode, nSignal ,self.tbSignalList)
	else
		--无网络
	end
end

function UIWidgetMainCityInfo:UpdateNet(nNetMode, nSignal, tbNodes)
	local tbColor = COLOR_RED

	if nSignal >= 0 and nSignal <= 100 then --满格
		tbColor = COLOR_NORMAL
		for i = 1, 3 do
			UIHelper.SetVisible(tbNodes[i], true)
			UIHelper.SetColor(tbNodes[i], tbColor)
		end
	elseif nSignal > 100 and nSignal <= 200 then --两格
		tbColor = COLOR_NORMAL
		for i = 1, 2 do
			UIHelper.SetVisible(tbNodes[i], true)
			UIHelper.SetColor(tbNodes[i], tbColor)
		end
		UIHelper.SetVisible(tbNodes[3], false)

	elseif nSignal > 200 and nSignal <= 300 then --一格
		UIHelper.SetVisible(tbNodes[1], true)
		UIHelper.SetColor(tbNodes[1], tbColor)
		for i = 2, 3 do
			UIHelper.SetVisible(tbNodes[i], false)
		end
	else
		for i = 1, 3 do
			UIHelper.SetVisible(tbNodes[i], false)
		end
	end

	-- 信号延迟的毫秒数
	UIHelper.SetColor(self.LableLatency, tbColor)
	UIHelper.SetString(self.LableLatency, string.format("%dms", math.floor(nSignal/2)))
end

function UIWidgetMainCityInfo:SetVisible(bVisible)
	UIHelper.SetVisible(self._rootNode, bVisible)
end

return UIWidgetMainCityInfo