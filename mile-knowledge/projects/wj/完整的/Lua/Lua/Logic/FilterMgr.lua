-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: FilterMgr
-- Date: 2024-03-05 19:30:47
-- Desc: ?
-- ---------------------------------------------------------------------------------

FilterMgr = FilterMgr or {className = "FilterMgr"}
local self = FilterMgr
-------------------------------- 消息定义 --------------------------------
FilterMgr.Event = {}
FilterMgr.Event.XXX = "FilterMgr.Msg.XXX"

local NO_STOP_DAY_NIGHT_FILTERS =  -- 不影响日夜循环的滤镜列表
{
    24, 25, 26, 27,
}

function FilterMgr.Init()
    self.bLockingUserSetting = false
	self._registerEvent()
end

function FilterMgr.UnInit()
    Event.UnRegAll(self)
end

function FilterMgr.OnLogin()
    
end

function FilterMgr.OnFirstLoadEnd()
    
end

------------- 远程调用相关
--- 锁定/解锁玩家操作相关
function FilterMgr.LockUserSetting(nDurationInSeconds)
	if not self.bLockingUserSetting then
		self.bLockingUserSetting = true
		-- FireUIEvent("UI_LOCK_USER_FILTER_STATE_CHANGE", self.bLockingUserSetting)
	end

	self._stopDelayCall("UnlockFilterUserSetting")
	if nDurationInSeconds then
		self._startDelayCall("UnlockFilterUserSetting", nDurationInSeconds, FilterMgr.UnlockUserSetting)
	end
end

function FilterMgr.UnlockUserSetting()
	if self.bLockingUserSetting then
		self.bLockingUserSetting = false
		-- FireUIEvent("UI_LOCK_USER_FILTER_STATE_CHANGE", self.bLockingUserSetting)
	end
end

function FilterMgr.IsLockingUserSetting()
	return self.bLockingUserSetting or false
end

function FilterMgr.RemoteSetPostRenderFilter(nFilterIndex)
	if self.bLockingUserSetting then
		self.SafeChangeFilter(nFilterIndex)
	else
		LOG.INFO("ERROR! 必须先锁定玩家的滤镜设置操作再切换滤镜！")
	end
end


function FilterMgr.SafeChangeFilter(nFilterIndex)  --- 考虑是否要增加参数，表示在切换的时候是否不重置画面参数（多半是不需要的，会把事情复杂化，而且很容易出问题）
	if not SceneMgr.GetGameScene() and nFilterIndex ~= 0 then
		LOG.INFO("[DEBUG] 现在主场景不显示，无视掉此次滤镜设置")
		return
	end
	local nCurFilter = self.GetCurFilter()
	if nFilterIndex ~= nCurFilter then
		local bOldStopDayNight = not table.contain_value(NO_STOP_DAY_NIGHT_FILTERS, nCurFilter)
		local bNewStopDayNight = not table.contain_value(NO_STOP_DAY_NIGHT_FILTERS, nFilterIndex)

		if nFilterIndex == 0 then
			if not self.bCaptureEnabled then
				LOG.INFO("WARNING! 不能在当前未调用 KG3DEngine.EnableRenderFilterCapture(true) 的情况下先调用 KG3DEngine.EnableRenderFilterCapture(false)!")
			else
				KG3DEngine.SetPostRenderFilter(nFilterIndex)
				KG3DEngine.SetPostRenderFilterChromaticAberrationEnable(false)
				KG3DEngine.EnableRenderFilterCapture(false, bOldStopDayNight)
				self.bCaptureEnabled = false
			end
		else
			if nCurFilter == 0 then
				KG3DEngine.EnableRenderFilterCapture(true, bNewStopDayNight)
				self.bCaptureEnabled = true
			else
				KG3DEngine.EnableRenderFilterCapture(false, bOldStopDayNight)  -- 通过这样来重置各种画面参数
				KG3DEngine.EnableRenderFilterCapture(true, bNewStopDayNight)

				self.bCaptureEnabled = true
			end

			KG3DEngine.SetPostRenderFilterChromaticAberrationEnable(true)
			KG3DEngine.SetPostRenderFilter(nFilterIndex)
		end
		self.SetCurFilter(nFilterIndex)
	end
end

function FilterMgr.GetCurFilter()
	return self.nCurFilter or 0
end

function FilterMgr.SetCurFilter(nCurFilter)
    self.nCurFilter = nCurFilter
end

--nTime是秒
function FilterMgr._startDelayCall(szKey, nTime, callback)
	if not self.tbTimer then self.tbTimer = {} end
	self.tbTimer[szKey] = Timer.Add(self, nTime, function()
		if callback then callback() end
	end)
end

function FilterMgr._stopDelayCall(szKey)
	if not self.tbTimer then return end
	if not self.tbTimer[szKey] then return end

	Timer.DelTimer(self, self.tbTimer[szKey])
	self.tbTimer[szKey] = nil
end


function FilterMgr._registerEvent()
	Event.Reg(self, EventType.OnClientPlayerLeave, function()
		self.UnlockUserSetting()
		self.SafeChangeFilter(0)
	end)
end