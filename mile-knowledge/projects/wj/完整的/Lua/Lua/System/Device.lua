--[[
	Date:		2023-10-13
	Author: 	huqing
	Purpose: 	设备相关信息
--]]

Device = {}

function Device.Uuid()
	return ""
end

function Device.MacAddress()
	return ""
end

function Device.OS()
	return GetDeviceOS()
end

function Device.GPU()
	return GetDeviceGPU()
end

function Device.DeviceModel()
	return GetDeviceModel()
end

-- 高通那边的账号，因为他们的机器root了，被判为模拟器了，所以这里就挂个包外文件让他们绕过模拟器检测
function Device._ignore_simulator_check()
	if Device.bIgnoreSimulatorCheck == nil then
		Device.bIgnoreSimulatorCheck = false
		local ini = Ini.Open("simulator.ini", true)
		if ini then
			local num = ini:ReadInteger("device", "no", 0)
			ini:Close()
			if num == 159162588 then
				Device.bIgnoreSimulatorCheck = true
			end
		end
	end

	return Device.bIgnoreSimulatorCheck
end

function Device.IsSimulator()
	if Platform.IsAndroid() then
		if Device._ignore_simulator_check() then
			return false
		end

		if IsSimulator() then
			return true
		end

		--[[
		-- 温度
		local nTemperature = App_GetBatteryTemperature()
		LOG.INFO("Device.IsSimulator(), nTemperature = "..tostring(nTemperature))
		if nTemperature <= 0 then
			return true
		end
		]]

		-- gpu 含有mumu
		local szGpu = string.lower(Device.GPU())
		LOG.INFO("Device.IsSimulator(), szGpu = "..tostring(szGpu))
		if string.find(szGpu, "mumu") then
			return true
		end
	end

	return false
end

function Device.GetNotchHeight()
	return GetNotchHeight()
end

function Device.GetHomeIndicatorHeight()
	return GetHomeIndicatorHeight()
end

function Device.GetDeviceScreenSize()
	return GetDeviceScreenSize()
end

function Device.GetDeviceIsPadModel()
	return GetDeviceIsPadModel()
end

-- 获取总内存 单位：bytes
function Device.GetDeviceTotalMemorySize(bConvertToGB)
	local nTotalMem = GetDeviceTotalMemorySize()
	if bConvertToGB then
		nTotalMem = nTotalMem / 1024 / 1024 / 1024
	end
	return nTotalMem
end

-- 获取总可用内存 单位：bytes
function Device.GetDeviceAvailableMemorySize(bConvertToGB)
	local nAvaMem = GetDeviceAvailableMemorySize()
	if bConvertToGB then
		nAvaMem = nAvaMem / 1024 / 1024 / 1024
	end
	return nAvaMem
end

-- 是否是集成显卡
function Device.GetWinIsIntegratedGPU()
	return GetWinIsIntegratedGPU()
end

-- 获得显存大小
--[[
	#define LOW_UNDER_1GB_VMEM 1.2f
	#define LOW_UNDER_2GB_VMEM 2.2f
	#define LOW_UNDER_4GB_VMEM 4.2f
	#define LOW_UNDER_6GB_VMEM 6.2f
	#define LOW_UNDER_8GB_VMEM 8.2f
]]
function Device.GetWinGPUMemoryGB()
	return GetWinGPUMemoryGB()
end

function Device.IsWinGPUMemoryGBLowUnder1GB()
	return Device.GetWinGPUMemoryGB() < 1.2
end

function Device.IsWinGPUMemoryGBLowUnder2GB()
	return Device.GetWinGPUMemoryGB() < 2.2
end

function Device.IsWinGPUMemoryGBLowUnder4GB()
	return Device.GetWinGPUMemoryGB() < 4.2
end

function Device.IsWinGPUMemoryGBLowUnder6GB()
	return Device.GetWinGPUMemoryGB() < 6.2
end

function Device.IsWinGPUMemoryGBLowUnder8GB()
	return Device.GetWinGPUMemoryGB() < 8.2
end

function Device.IsHuaWei()
	local bResult = false
	local szDeviceModel = Device.DeviceModel() or ""
	local szProducer = string.sub(szDeviceModel, 1, 6) or ""
	if string.lower(szProducer) == "huawei" then
		bResult = true
	end
	return bResult
end

function Device.IsHonor()
	local bResult = false
	local szDeviceModel = Device.DeviceModel() or ""
	local szProducer = string.sub(szDeviceModel, 1, 5) or ""
	if string.lower(szProducer) == "honor" then
		bResult = true
	end
	return bResult
end

function Device.IsAndroid10()
	local szOS = Device.OS()
	return szOS == "Android 10"
end

-- iOS 15以下
function Device.IsUnderIOS15()
	local bResult = false
	if Platform.IsIos() then
		local szOS = GetDeviceOS() or ""
		local tbOS = string.split(szOS, " ")
		if tbOS then
			if tbOS[1] and tbOS[1] == "iOS" then
				if tbOS[2] then
					local tbVer = string.split(tbOS[2], "%.")
					if tbVer and tbVer[1] then
						local nVer = tonumber(tbVer[1])
						if IsNumber(nVer) then
							bResult = nVer < 15
						end
					end
				end
			end
		end
	end
	return bResult
end



function Device.IsIPad()
	local bResult = false
	if Platform.IsIos() then
		local szOS = GetDeviceOS() or ""
		local tbOS = string.split(szOS, " ")
		if tbOS and tbOS[1] then
			bResult = tbOS[1] == "iPadOS"
		end
	end
	return bResult
end

function Device.IsIPhone()
	local bResult = false
	if Platform.IsIos() then
		local szOS = GetDeviceOS() or ""
		local tbOS = string.split(szOS, " ")
		if tbOS and tbOS[1] then
			bResult = tbOS[1] == "iOS"
		end
	end
	return bResult
end

-- 判断是不是Pad，其实是判断是不是那种屏蔽比较方的
local Android_Pad_DeviceModel =
{
	["Lenovo TB320FC"] = true
}
function Device.IsPad()
	if Platform.IsAndroid() then
		local szDeviceModel = Device.DeviceModel()
		if Android_Pad_DeviceModel[szDeviceModel] then
			return true
		end
	end

	local sizeDeviceScreen = UIHelper.DeviceScreenSize()
	local nRate = sizeDeviceScreen.width / sizeDeviceScreen.height
	return nRate < 1.45 or Device.GetDeviceIsPadModel()
end

-- 是否是Windows的触摸屏
function Device.IsTouchScreenSupported()
	return Platform.IsWindows() and IsTouchScreenSupported()
end

function Device.dump()
	print("---------------------------------------")
	print("Device.dump()")
	print("---------------------------------------")
    local szContent = "OS: " .. tostring(GetDeviceOS()) .. "\n"
    szContent = szContent .. "GPU: " .. tostring(GetDeviceGPU()) .. "\n"
    szContent = szContent .. "DeviceModel: " .. tostring(GetDeviceModel()) .. "\n"
    szContent = szContent .. "IsSimulator: " .. tostring(IsSimulator()) .. "\n"
    szContent = szContent .. "NotchHeight: " .. tostring(GetNotchHeight()) .. "\n"
    szContent = szContent .. "HomeIndicatorHeight: " .. tostring(GetHomeIndicatorHeight()) .. "\n"
    szContent = szContent .. "DeviceScreenSize: w = " .. tostring(GetDeviceScreenSize().width) .. ", h = " .. tostring(GetDeviceScreenSize().height) .. "\n"
	szContent = szContent .. "DeviceIsPadModel: " .. tostring(Device.GetDeviceIsPadModel()) .. "\n"
	szContent = szContent .. "TotalMemorySize: " .. tostring(Device.GetDeviceTotalMemorySize(true)) .. " GB\n"
	szContent = szContent .. "AvailableMemorySize: " .. tostring(Device.GetDeviceAvailableMemorySize(true)) .. " GB\n"
    print(szContent)
end

