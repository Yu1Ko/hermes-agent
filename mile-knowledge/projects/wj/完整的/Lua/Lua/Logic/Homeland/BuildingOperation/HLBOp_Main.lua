
NewModule("HLBOp_Main")

--自定义事件
--[[
	LUA_HOMELAND_UPDATE_LANDDATA --更新物件数据
	LUA_HOMELAND_INTERACTABLE_ERROR --存盘数据溢出等
	LUA_HOMELAND_UPLOAD_BLUEPRINT_PATH --传递蓝图路径数据
	LUA_HOMELAND_SELECT_CHANGE --当前选中有变化
	LUA_HOMELAND_GROUP_CHANGE --打组有变化
	LUA_HOMELAND_UPDATE_ITEMOP_SHOW --更新Item操作栏位置显示隐藏
	LUA_HOMELAND_CLOSE_ITEMOP --关闭Item操作栏
	LUA_HOMELAND_UPDATE_SAVE --更新保存状态
	LUA_HOMELAND_CREATE_CUSTOM_BRUSH --创建笔刷成功
	LUA_HOMELAND_CANCEL_CUSTOM_BRUSH --取消笔刷
	LUA_HOMELAND_UPDATE_ITEMOP_INFO --更新Item操作栏信息
	LUA_HOMELAND_LAYERS_OPEN --打开地下室计数界面
	LUA_HOMELAND_LAYERS_CLOSE --关闭地下室计数界面
	LUA_HOMELAND_LAYERS_UPDATE -- 更新地下室计数界面
	LUA_HOMELAND_REPLACE_SUCCESS -- 替换成功
	LUA_HOMELAND_FRESH_ITEM_LIST -- 强制刷新摆放列表
	LUA_HOMELAND_CLOSE_IMPORT_TIP -- 关闭导入蓝图界面
	LUA_HOMELAND_UPDATE_INTERACTABLE -- 更新交互数据
	LUA_HOMELAND_UPDATE_FILE_LIMIT -- 更新检查文件大小 -- arg0：成功 or 失败
	LUA_HOMELAND_UPDATE_LOADBAR --打开蓝图加载进度条
	LUA_DIGITAL_SAVING_UPDATE --数字蓝图状态更新
]]


m_nMode = 0
m_bModified = false
m_bInDev = false
m_bMoveObjEnabled = false

m_tModuleList = {
    "HLBOp_Enter",
	"HLBOp_Amount",
	"HLBOp_Camera",
	"HLBOp_Other",
	"HLBOp_Place",
	"HLBOp_Step",
	"HLBOp_Select",
	"HLBOp_Blueprint",
	"HLBOp_Save",
	"HLBOp_Exit",
	"HLBOp_Brush",
	"HLBOp_Bottom",
	"HLBOp_SingleItemOp",
	"HLBOp_MultiItemOp",
	"HLBOp_Group",
	"HLBOp_CustomBrush",
	"HLBOp_Rotate",
	"HLBOp_Check",
}

local function FireSubWindowEvent(szEvent, ...)
	for k, v in ipairs(m_tModuleList) do
		local szName = v
		if not _G[szName] then
			LOG.INFO("---------HLBOp_Main-----require sub module:--------%s", szName)
			require(string.format("Lua/Logic/Homeland/BuildingOperation/%s.lua", szName))
		end

		local tFile = _G[szName]
		if tFile then
			local fnAction = tFile[szEvent]
			if fnAction then
				fnAction(...)
			end
		end
	end
end

local function fnPrepareCheckEnter()
    local player = GetClientPlayer()
	if not player then
		return false
	end

	if player.bFightState then
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_CAN_NOT_OPERATE_IN_FIGHT)
		return false
	end


	if player.bSprintFlag then
		OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_CAN_NOT_OPERATE_IN_SPRINT)
		return false
	end

	if IsIndePentShowPanelsOpen() then --独立模式的界面们
		return false
	end


	if (m_nMode == BUILD_MODE.COMMUNITY or m_nMode == BUILD_MODE.PRIVATE) and BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK) then
		return false
	end

	MoveAction_StopAll()
	return true
end

function Enter(nMode, tDesignInfo)
    m_nMode = nMode
	local tConfig = Homeland_GetModeConfig(m_nMode)
    if not fnPrepareCheckEnter() then
        return
    end
	Init()

	--不同模式特判
	if tConfig.bDesign and tDesignInfo then
		-- ShowFullScreenSFX("CUT_SCENE", "Topmost1")
		SetDesignInfo(tDesignInfo.nSceneIndex, tDesignInfo.nLength, tDesignInfo.nWidth, tDesignInfo.bPrivateHome)
		SetLevel(tDesignInfo.nLevel)
	elseif tConfig.bTest then
		SetLevel(Homeland_GetTestBuildLevel())
	end

    HLBOp_Enter.Enter()
end

function Exit()
	local tConfig = Homeland_GetModeConfig(m_nMode)
	if tConfig.bDesign then
		-- ShowFullScreenSFX("CUT_SCENE", "Topmost1")
		Event.Dispatch(EventType.PlayAnimMainCityFullScreenHide)
    	Event.Dispatch(EventType.PlayAnimMainCityFullScreenShow)
	end
	UIMgr.Close(VIEW_ID.PanelConstructionMain)
	UIMgr.Close(VIEW_ID.PanelConstructionMain1)
	Event.Dispatch("HOMELANDBUILDING_ON_CLOSE")
	UnInit()
end

function OnFrameBreathe()
	FireSubWindowEvent("OnFrameBreathe")
end

function RegEvent()
	local OnEvent = function(szEvent)
		return function ()
	if szEvent == "LUA_HOMELAND_INTERACTABLE_ERROR" then
		OnInteractError()
	end
	FireSubWindowEvent("OnEvent", szEvent)
end
	end

	Event.Reg(HLBOp_Main, "HOME_LAND_RESULT_CODE", OnEvent("HOME_LAND_RESULT_CODE"))
	Event.Reg(HLBOp_Main, "HOME_LAND_RESULT_CODE_INT", OnEvent("HOME_LAND_RESULT_CODE_INT"))
	Event.Reg(HLBOp_Main, "HOME_LAND_START_BUILDING", OnEvent("HOME_LAND_START_BUILDING"))
	Event.Reg(HLBOp_Main, "HOMELAND_CALL_RESULT", OnEvent("HOMELAND_CALL_RESULT"))
	Event.Reg(HLBOp_Main, "LUA_HOMELAND_INTERACTABLE_ERROR", OnEvent("LUA_HOMELAND_INTERACTABLE_ERROR"))
end

function Init()
	KG3DEngine.PauseDayNightLoop(true)
	m_bModified = false
	FireSubWindowEvent("Init")
	RegEvent()

	if nOnFrameBreatheTimerID then
		Timer.DelTimer(HLBOp_Main, nOnFrameBreatheTimerID)
		nOnFrameBreatheTimerID = nil
	end
	nOnFrameBreatheTimerID = Timer.AddFrameCycle(HLBOp_Main, 1, OnFrameBreathe)
end

function UnInit()
	KG3DEngine.PauseDayNightLoop(false)
	FireSubWindowEvent("UnInit")
	m_nMode = nil
	m_bModified = nil

	if nOnFrameBreatheTimerID then
		Timer.DelTimer(HLBOp_Main, nOnFrameBreatheTimerID)
		nOnFrameBreatheTimerID = nil
	end
end

function OnInteractError()

end
------------------------------------API---------------------------------

function SetDesignInfo(nSceneIndex, nLength, nWidth, bPrivateHome)
	HLBOp_Enter.SetDesignInfo(nSceneIndex, nLength, nWidth, bPrivateHome)
end

function SetLevel(nLevel)
	HLBOp_Enter.SetLevel(nLevel)
end

function GetBuildMode()
	return m_nMode
end

function SetModified(bModified)
	if bModified ~= m_bModified then
		m_bModified = bModified
		FireUIEvent("LUA_HOMELAND_UPDATE_SAVE")
	end
end

function IsModified()
	return m_bModified
end

function IsInDev()
	return m_bInDev
end

function SetInDev(bIn)
	m_bInDev = bIn
end

function IsModified()
	return m_bModified
end

function SetMoveObjEnabled(bEnabled)
	m_bMoveObjEnabled = bEnabled
end

function GetMoveObjEnabled()
	return m_bMoveObjEnabled
end