--[[
	Date:		2024-4-16
	Author: 	huqing
	Purpose: 	渠道信息
--]]

Channel = {}
Channel.szAdChannelId = XGSDK_GetAdChannelId()


-- 抖音
function Channel.Is_douyinlianyun()
	return Channel.szAdChannelId == "douyinmailiang"
end

-- 抖音 云游戏
function Channel.Is_dylianyunyun()
	if not Channel.bHasXGIsDouyinCloudChecked then
		local szRet = XGSDK.CallXGMethodSync("IsDouyinCloud")
		LOG.INFO("Channel, IsDouyinCloud = "..tostring(szRet))
		Channel.bXGIsDouyinCloud = (szRet == "true")
		Channel.bHasXGIsDouyinCloudChecked = true
	end
	return Channel.bXGIsDouyinCloud
end

-- 是否是抖音：包含抖音和抖音云游戏
function Channel.Is_DouYin()
	return Channel.Is_douyinlianyun() or Channel.Is_dylianyunyun()
end

-- taptap 云游戏
function Channel.Is_Tapyun()
	return Channel.szAdChannelId == "Tapyun"
end

-- 蔚领 云游戏
function Channel.Is_WLColud()
	return IsWLCloud()
end

-- 是否是云游戏 渠道
function Channel.IsCloud()
	return Channel.Is_dylianyunyun() or Channel.Is_Tapyun() or Channel.Is_WLColud()
end

