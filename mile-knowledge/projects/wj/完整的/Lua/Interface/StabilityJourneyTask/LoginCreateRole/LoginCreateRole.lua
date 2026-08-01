LoginMgr.Log("LoginCreateRole","LoginCreateRole imported")
LoginCreateRole={}
Preconditions={}
local ServerList ={}
local SectRole={}
local EnterLoginServer = {}

-- 登录账号 密码 服务器 大区
local szAccount=RandomString(10)          --账号随机八位数字
local szPassword=123456        --密码
local szRegion = "质量"
local szServer = "TDR"

-- 各模块开关
LoginCreateRole.bSwitch=true -- 插件总开关
Preconditions.bSwitch =false
SectRole.bSwitch = true	--门派遍历开关
EnterLoginServer.bSwitch=true	-- 登录账号界面遍历按钮操作开关 （例如：公告等）
ServerList.bSwitch = true	-- 服务器遍历开关

-- 各模块时间控制
SectRole.nNextTime = 8	-- 门派遍历间隔时间 每8秒执行一次(不可超过6秒需等待动画播放完)
ServerList.nNextTime = 2	-- 服务器的遍历间隔时间
EnterLoginServer.nNextTime = 6	-- 登录账号界面遍历按钮间隔时间
local nStepTime = 10	-- 回调函数控制时间


--延时调用装饰器 执行回调函数一次
local delayDoSomething = function(callback, time)
	if not LoginCreateRole.bSwitch then
		return
	end
    local handle
    handle = SearchPanel.director:getScheduler():scheduleScriptFunc(function()
        SearchPanel.director:getScheduler():unscheduleScriptEntry(handle)
        callback()
    end, time, false)
    return handle
end

-- 门派角色遍历
SectRole.tbSectData = {} -- 门派数据
SectRole.nSectDataCount = {} -- 门派总数
SectRole.nSectLine = 1	-- 当前遍历的门派
SectRole.tbBodyData = {} -- 体型数据
SectRole.nBodyData = {} -- 体型总数
SectRole.nBodyLine = 1	-- 当前遍历的体型
SectRole.nstarTime = 0
SectRole.nSlide = 0	-- 滑动条
SectRole.bStart = false	-- 初始化
-- 获取门派表和门派总数
function SectRole.GetSectTable()
	SectRole.tbSectData = UINodeControl.GetToggroup("ToggleGroupSchool")
	SectRole.nSectDataCount = #SectRole.tbSectData
end
-- 获取对应体型和返回体型总数
function SectRole.GetBodyData()
	SectRole.tbBodyData = UINodeControl.GetToggroup("ToggleGroupBodilyForm")
	SectRole.nBodyData = #SectRole.tbBodyData
	return SectRole.nBodyData
end

function SectRole.FrameUpdate()
	if GetTickCount()-SectRole.nstarTime >= SectRole.nNextTime*1000 then
		if not SectRole.bStart then
			SectRole.GetSectTable()
			SectRole.bStart = true
		end
		if SectRole.nBodyLine ~= SectRole.GetBodyData()+1 then
			-- 执行遍历体型
			UINodeControl.TogTriggerByToggle("ToggleGroupBodilyForm",SectRole.tbBodyData[SectRole.nBodyLine].node)
			-- 切换心法
			UINodeControl.BtnTrigger("BtnChange")
			SectRole.nBodyLine = SectRole.nBodyLine + 1
		else
			if SectRole.nSectLine == SectRole.nSectDataCount then
				--结束
				-- 选中段式成男
				UINodeControl.TogTriggerByToggle("ToggleGroupSchool",UINodeControl.GetToggroup("ToggleGroupSchool")[1].node);
				UINodeControl.TogTriggerByToggle("ToggleGroupBodilyForm",UINodeControl.GetToggroup("ToggleGroupBodilyForm")[1].node)
				Timer.DelAllTimer(SectRole)
				LoginCreateRole.bSwitch = false
				LoginMgr.Log("SectRole Ergodic End")
				return
			end
			-- 执行下个门派
			SectRole.nSectLine = SectRole.nSectLine + 1
			UINodeControl.TogTriggerByToggle("ToggleGroupSchool",SectRole.tbSectData[SectRole.nSectLine].node)
			-- 重置体型
			SectRole.nBodyLine=1
			-- 滚动条的滑动只能写死
			-- ScrollToPercent从左到右的参数分别为ScrollView 滑动的位置[0-100] 滑动持续的时间
			if SectRole.nSlide ~= 90 then
				SectRole.nSlide = SectRole.nSlide + 10
				UIHelper.ScrollToPercent(UIMgr.GetViewScript(VIEW_ID.PanelSchoolSelect).ScrollViewSchoolSelect, SectRole.nSlide, 1, true)
			end
		end
		SectRole.nstarTime = GetTickCount()
	end
end


-- 开始门派角色遍历
function SectRole.Start()
	-- 是否开启
	if not SectRole.bSwitch then
		return
	end
	-- 门派角色遍历帧函数
	SectRole.nstarTime = GetTickCount()
	Timer.AddFrameCycle(SectRole,1,function()
		SectRole.FrameUpdate()
	end)
end



-- 服务器遍历
ServerList.nstarTime = 0
ServerList.tbRegionData={}	-- 大区总表
ServerList.tbServerData={}	-- 服务器表
ServerList.nRegionCount=0	-- 大区总表总数
ServerList.nServerCount=0	-- 服务器表总数
ServerList.nRegionLine=1	-- 当前选中的大区
ServerList.nServerLine=1	-- 当前选中的服务器
ServerList.nstarTime = 0
-- 获取大区表并返回大区行数
function ServerList.GetRegionTable()
	ServerList.tbRegionData = UINodeControl.GetToggroup("AreanToggleGroup")
	ServerList.nRegionCount = #ServerList.tbRegionData
	return ServerList.nRegionCount
end

-- 获取服务器表并返回服务器行数
function ServerList.GetServerTable()
	ServerList.tbServerData = UINodeControl.GetToggroup("CellToggleGroup")
	ServerList.nServerCount = #ServerList.tbServerData
	return ServerList.nServerCount
end

function ServerList.FrameUpdate()
	if GetTickCount()-ServerList.nstarTime >= ServerList.nNextTime*1000 then
		-- 判断服务器是否执行完成
		if ServerList.nServerLine ~= ServerList.GetServerTable()+1 then
			-- 选中服务器
			-- 打印出当前大区和服务器名称
			--[[local szRegionName = UINodeControl.GetLableText(ServerList.tbRegionData[ServerList.nRegionLine].node,2)
			local szServerName = UINodeControl.GetLableText(ServerList.tbServerData[ServerList.nServerLine].node,2)
			LoginMgr.Log("LoginCreateRole Region Tog:"..szRegionName)
			LoginMgr.Log("LoginCreateRole Server Tog:"..szServerName)]]
			UINodeControl.TogTriggerByToggle("CellToggleGroup",ServerList.tbServerData[ServerList.nServerLine].node)
			ServerList.nServerLine = ServerList.nServerLine + 1
		else
			-- 判断大区是否执行完成
			if ServerList.nRegionLine == ServerList.GetRegionTable() then
				LoginMgr.Log("ServerList Ergodic End")
				ServerList.bSwitch=false
				-- 执行回调函数一次
				delayDoSomething(function()
					UINodeControl.BtnTrigger("BtnClose")
					delayDoSomething(function()
						UINodeControl.BtnTriggerByLable("BtnStart","登录账号")
					end,5)
				end, 5)
				Timer.DelAllTimer(ServerList)
				return
			end
			ServerList.nServerLine = 1
			ServerList.nRegionLine = ServerList.nRegionLine + 1
			-- 选中大区
			UINodeControl.TogTriggerByToggle("AreanToggleGroup",ServerList.tbRegionData[ServerList.nRegionLine].node)
		end
		ServerList.nstarTime = GetTickCount()
	end
end

function ServerList.Start()
	-- 是否开启 不开启直接登录游戏
	if not ServerList.bSwitch then
		delayDoSomething(function()
			UINodeControl.BtnTrigger("BtnClose")
			delayDoSomething(function()
				UINodeControl.BtnTriggerByLable("BtnStart","登录账号")
			end,5)
		end, 5)
		return
	end
	-- 进入服务器遍历之前先初始化时间和大区
	UINodeControl.BtnTriggerByLable("BtnDevelop","开发者选服")
	ServerList.nstarTime = GetTickCount()
	Timer.AddFrameCycle(ServerList,1,function()
		ServerList.FrameUpdate()
	end)
	ServerList.GetRegionTable()
end


-- 按照表顺序来执行登录界面的按钮操作
local tbEnterLoginServer = {
	"BtnBroadcast",
	"BtnClose",
	"BtnList",
	"BtnClose",
}
-- 登录账号界面遍历按钮操作
EnterLoginServer.bSwitch=true
EnterLoginServer.nEnterLoginServerCount = #tbEnterLoginServer	-- 执行按钮的总数
EnterLoginServer.nEnterLoginServerLine = 1	--当前执行按钮的行数
EnterLoginServer.nStarTime = 0	-- 当前执行按钮时间
function EnterLoginServer.FrameUpdate()
	if GetTickCount() - EnterLoginServer.nStarTime >= EnterLoginServer.nNextTime*1000 then --间隔6000毫秒
		-- 结束登录账号界面遍历帧函数
		if EnterLoginServer.nEnterLoginServerLine == EnterLoginServer.nEnterLoginServerCount then
			Timer.DelAllTimer(EnterLoginServer)
			EnterLoginServer.bSwitch=false
			-- 执行服务器遍历
			delayDoSomething(function()
				ServerList.Start()
			end, nStepTime)
		end
		UINodeControl.BtnTrigger(tbEnterLoginServer[EnterLoginServer.nEnterLoginServerLine])
		-- 打印出当前执行按钮名称
		LoginMgr.Log("EnterLoginServer Btn:"..tbEnterLoginServer[EnterLoginServer.nEnterLoginServerLine])
		EnterLoginServer.nEnterLoginServerLine = EnterLoginServer.nEnterLoginServerLine + 1
		EnterLoginServer.nStarTime = GetTickCount()
	end
end
-- 启动登录账号界面遍历按钮操作
function EnterLoginServer.Start()
	if not EnterLoginServer.bSwitch then
		-- 不启动 则直接执行服务器遍历
		delayDoSomething(function()
			ServerList.Start()
		end, nStepTime)
		return
	end
	Timer.AddFrameCycle(EnterLoginServer,1,function()
		EnterLoginServer.FrameUpdate()
	end)
end

--LoginGateway  and LoginPassword --
--登录服务器
--[[]]
local bstart = false
local moduleServerList=LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)
local _LoginServerListRequsetServerList = moduleServerList.RequestServerList
function LoginServerListRequsetServerList()
	_LoginServerListRequsetServerList()
	LOG.INFO("serverTest1")
	if bstart then
		delayDoSomething(function()
			--设置服务器
			LOG.INFO("serverTest")
			delayDoSomething(function()
				if szAccount=='' then
					LoginMgr.Log("LoginCreateRole","未填写账号:account -> %s",szAccount)
					return
				end
				--设置账号-密码-用户协议-记住密码
				local bStatus, szErr=pcall(function ()
					UIHelper.SetSelected(g_tbLoginData.LoginView.TogCheck, true)
				end)
				if bStatus then
					UIHelper.SetSelected(g_tbLoginData.LoginView.TogConsent,true)
					LoginMgr.GetModule(LoginModule.LOGIN_ACCOUNT).SetAccountPassword(szAccount,szPassword)
					moduleServerList.SetSelectServer(szRegion,szServer)
					delayDoSomething(function ()
						-- 启动登录操作遍历
						EnterLoginServer.Start()
					end,nStepTime)
				end
			end, nStepTime)
		end, nStepTime)
	end
end
moduleServerList.RequestServerList=LoginServerListRequsetServerList


--[[]]
-- LoginServerList
--登录账号
local _LoginServerListOnEnter = moduleServerList.OnEnter
function LoginServerListOnEnter(szPrevStep)
	_LoginServerListOnEnter(szPrevStep)
	delayDoSomething(function()
		--进入角色界面
		UINodeControl.BtnTrigger("BtnLogin")
	end, nStepTime)
end
moduleServerList.OnEnter=LoginServerListOnEnter


--如果服务器异常 每隔1分钟重试一次
local moduleGateway=LoginMgr.GetModule(LoginModule.LOGIN_GATEWAY)
local _LoginGatewayOnHandShakeFail = moduleGateway.OnHandShakeFail
function LoginGatewayOnHandShakeFail(nEvent)
	_LoginGatewayOnHandShakeFail(nEvent)
	delayDoSomething(function()
		--登录
		UINodeControl.BtnTriggerByLable("BtnLogin","登录游戏")
	end, 60)
end

moduleGateway.OnHandShakeFail=LoginGatewayOnHandShakeFail

-- 角色创建 对每个门派进行遍历
local moduleRole=LoginMgr.GetModule(LoginModule.LOGIN_ROLE)
local _LoginRoleOnEnter = moduleRole.OnEnter
function LoginRoleOnEnter(szPrevStep)
	_LoginRoleOnEnter(szPrevStep)
	-- 门派角色遍历
	SectRole.Start()
end
moduleRole.OnEnter = LoginRoleOnEnter


-- LoginRoleList --
--角色列表 如有角色点击添加角色
--[[]]
local moduleRoleList=LoginMgr.GetModule(LoginModule.LOGIN_ROLELIST)
local _LoginRoleListOnEnter = moduleRoleList.OnEnter
function LoginRoleListOnEnter(szPrevStep)
	_LoginRoleListOnEnter(szPrevStep)
	local nCount = Login_GetRoleCount()
	LoginMgr.Log("LoginCreateRole","RoleTest"..string.format(":%d",nCount))
	if nCount>0 then
		delayDoSomething(function()
			moduleRoleList.CreateRole()
		end, nStepTime)
	end
end
moduleRoleList.OnEnter= LoginRoleListOnEnter



function Preconditions.FrameUpdate()
	if not LoginCreateRole.bSwitch then
		Timer.DelAllTimer(Preconditions)
		StabilityController.bFlag = true
	end
	if Preconditions.bSwitch then
		--启动登录创角
		bstart=true
		LoginServerListRequsetServerList()
		Preconditions.bSwitch = false
	end
end

Timer.AddCycle(Preconditions,1,function ()
    Preconditions.FrameUpdate()
end)

LoginMgr.Log("LoginCreateRole","LoginCreateRole imported End")

return LoginCreateRole
