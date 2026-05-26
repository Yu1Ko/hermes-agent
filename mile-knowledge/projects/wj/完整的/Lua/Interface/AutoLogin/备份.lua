LoginMgr.Log("AutoLogin","AutoLogin imported")
local AutoLogin={}
AutoLogin.bSwitch=true
local szFilePath=SearchPanel.szInterfaceAutoLogiPath.."Automation.ini"
LoginMgr.Log("AutoLogin",szFilePath)
local ini = Ini.Open(szFilePath)
local szRoleName=ini:ReadString("Automation", "RoleName", "")          --角色名
local szAccount=ini:ReadString("Automation", "account", "")           --账号
local szPassword=ini:ReadString("Automation", "password", "")        --密码
local szStepTime=ini:ReadString("Automation", "StepTime", "")          --登录时每一步等待时间
local szSwitch=ini:ReadString("Automation", "Switch", "")              --自动登录脚本(0:关闭,1:打开)
local szSchooltype=ini:ReadString("Automation", "school_type", "")    --创建角色的门派
local szRoletype=ini:ReadString("Automation", "role_type", "")        --创建角色的体型
local szRegion=ini:ReadString("Automation", "szDisplayRegion", "")        --大区
local szServer=ini:ReadString("Automation", "szDisplayServer", "")        --服务器
local szResource=ini:ReadString("Automation", "Resource", "")		-- 资源（0：不下载 1：下载基础包 2：扩展包,3:TDR案例资源，4：指定资源下载）
local szRandomAccount=ini:ReadString("Automation", "RandomAccount", "")	-- 随机账号(0：关闭 1：启动)
local szResourcePackId
ini:Close()
local bCreateRandomRole=false
local nResource=tonumber(szResource)
local nRandomAccount = tonumber(szRandomAccount)
-- 如果为4则指定包体下载
if nResource == 4 then
	szResourcePackId=ini:ReadString("Automation", "ResourcePackId", "")
end
local nStepTime=tonumber(szStepTime)/1000
if tonumber(szSwitch)==0 then
	AutoLogin.bSwitch=false
end
--设置自动登录参数
function AutoLogin.SetAutoLoginInfo(szRoleNameTemp,szAccountTemp,szSchooltypeTemp,szRoletypeTemp)
	if szRoleNameTemp then
		szRoleName=szRoleNameTemp
	end
	if szAccountTemp then
		szAccount=szAccountTemp
	end
	if szSchooltypeTemp then
		szSchooltype=szSchooltypeTemp
	end
	if szRoletypeTemp then
		szRoletype=szRoletypeTemp
	end
end

function AutoLogin.SetAccount(szAccountTemp)
	if szAccountTemp then
		szAccount=szAccountTemp
	end
end

function AutoLogin.SetSchooltype(szSchooltypeTemp)
	if szSchooltypeTemp then
		szSchooltype=szSchooltypeTemp
	end
end

function AutoLogin.SetRoleName(szRoleNameTemp)
	if szRoleNameTemp then
		szRoleName=szRoleNameTemp
	end
end

function AutoLogin.SetRoletype(szRoletypeTemp)
	if szRoletypeTemp then
		szRoletype=szRoletypeTemp
	end
end

if nRandomAccount == 1 then
	AutoLogin.SetAutoLoginInfo(nil,RandomString(9),'纯阳','成男')
end

local m_tAni =
{
	["蓬莱"] = KUNGFU_ID.PENG_LAI,   --蓬莱
	["霸刀"] = KUNGFU_ID.BA_DAO,     --霸刀
	["长歌"] = KUNGFU_ID.CHANG_GE,   --长歌
	["苍云"] = KUNGFU_ID.CANG_YUN,   --苍云
	["丐帮"] = KUNGFU_ID.GAI_BANG,        --丐帮
	["明教"] = KUNGFU_ID.MING_JIAO,        --明教
	["唐门"] = KUNGFU_ID.TANG_MEN,        --唐门
	["五毒"] =  KUNGFU_ID.WU_DU,        --五毒
	["藏剑"] = KUNGFU_ID.CANG_JIAN,        --藏剑
	["天策"] = KUNGFU_ID.TIAN_CE,        --天策
	["纯阳"] = KUNGFU_ID.CHUN_YANG,        --纯阳
	["少林"] = KUNGFU_ID.SHAO_LIN,        --少林
	["七秀"] = KUNGFU_ID.QI_XIU,        --七秀
	["万花"] = KUNGFU_ID.WAN_HUA,        --万花
	["凌雪"] = KUNGFU_ID.LING_XUE,     --凌雪
	["刀宗"]=KUNGFU_ID.DAO_ZONG,		--刀宗
	["药宗"]=KUNGFU_ID.YAO_ZONG,		--药宗
	["衍天"]=KUNGFU_ID.YAN_TIAN,		--衍天
	["段氏"]=KUNGFU_ID.DUAN_SHI		--段氏
}

local m_tBodyType =
{
	["正太"] = 4,        --正太
	["成男"] = 1,     --成男
	["萝莉"] = 3,       --萝莉
	["成女"] = 2,   --成女
}
-- TDR包体资源
local tbTDRPack = {
	4,800006,800108,800580,800455,800606,800586,800668
}

--延时调用装饰器 执行回调函数一次
local delayDoSomething = function(callback, time)
	if not AutoLogin.bSwitch then
		return
	end
    local handle
    handle = SearchPanel.director:getScheduler():scheduleScriptFunc(function()
        SearchPanel.director:getScheduler():unscheduleScriptEntry(handle)
        callback()
    end, time, false)
    return handle
end
-- 分割字符串
local function split(str, sep)
	local result = {}
	string.gsub(str, '[^' .. sep .. ']+', function(part)
	  table.insert(result, part)
	end)
	return result
end

-- 资源下载部分
local tbPakResource = {}
tbPakResource.bDowloadEnd=false -- 是否下载完成
tbPakResource.base = nResource   --0不下载 1.下载基础包 2.全局下载
tbPakResource.nStartDownload = false -- 是否在下载
tbPakResource.tbPackId = {}	-- 指定的包体

-- 分割指定包体
function GetResourcePackId(szPackId)
	local str = szPackId
	local parts = split(str, ",")
	for k, v in ipairs(parts) do
		table.insert(tbPakResource.tbPackId,tonumber(v))
	end
end


-- 开启下载
function tbPakResource.Start()
    Timer.AddCycle(tbPakResource,1,function ()
        tbPakResource.FrameUpdate()
    end)
end


-- 检测核心包是否下载完成
function tbPakResource.ParkCorePack()
	local tCorePackIDList =  PakDownloadMgr.GetCorePackIDList()
	local tCoreStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(tCorePackIDList)
	if tCoreStateInfo.nState == DOWNLOAD_STATE.COMPLETE then
		UIMgr.Close(VIEW_ID.PanelResourcesDownload, RESOURCES_PAGE.DOWNLOADING)
		return true
	end
	return false
end

-- 基础包下载
function tbPakResource.ParkStartbase()
    -- 检测基础包是否下载完成
    local nState, _, _ = PakDownloadMgr.GetBasicPackState()
    if nState == DOWNLOAD_OBJECT_STATE.DOWNLOADED then
		-- 关闭资源下载面板
        return true
    end
    if not tbPakResource.nStartDownload then
		-- 打开资源下载面板
		UIMgr.Open(VIEW_ID.PanelResourcesDownload, RESOURCES_PAGE.DOWNLOADING, 1)
        LoginMgr.GetModule(LoginModule.LOGIN_DOWNLOAD).StartDownload()
        tbPakResource.nStartDownload = true
    end
    return false
end 
-- 是否下载完所有资源
function CheckDLCContent()
	for _, v in pairs(PakDownloadMgr.tPakInfoList) do
		-- 检测是否下载完所有资源接口
		local nState, _, _ = PakDownloadMgr.GetPackState(v.nPackID)
		if nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED then
			return false
		end
	end
	return true
end

-- 是否下载完指定资源
function GetCheckDLCContentId(tbPackId)
	tbPakResource.tbPackId = tbPackId
	for _, v in pairs(tbPakResource.tbPackId) do
		-- 检测是否下载完所有资源接口
		local nState, _, _ = PakDownloadMgr.GetPackState(v)
		if nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED then
			return false
		end
	end
	return true
end

-- 执行登录
local function LoginStart()
	LoginMgr.Log("AutoLogin","%s -> %s",szRegion,szServer)
	--g_tbLoginData.LoginView:Login()
	UINodeControl.BtnTrigger("BtnStart")
	LOG.INFO("Download Stop")
end

-- 指定包体下载资源
function tbPakResource.ParkStartID(tbPackId)
	-- 检测是否下载完所有资源
	if GetCheckDLCContentId(tbPackId) and tbPakResource.ParkCorePack() and tbPakResource.ParkStartbase() then
		-- 关闭资源下载面板
		UIMgr.Close(VIEW_ID.PanelResourcesDownload, RESOURCES_PAGE.DOWNLOADING)
		return true
	end
	-- 下载扩展资源包
	if not tbPakResource.nStartDownload then
		-- 打开资源下载面板
		UIMgr.Open(VIEW_ID.PanelResourcesDownload, RESOURCES_PAGE.DOWNLOADING, 1)
		for _, v in pairs(tbPakResource.tbPackId) do 
			print("abc",v)
			PakDownloadMgr.DownloadPack(v)
		end
		tbPakResource.nStartDownload = true
	end
	return false
end


-- 全部资源下载
function tbPakResource.ParkStartExtend()
    -- 检测是否下载完所有资源
	if CheckDLCContent() then
		-- 关闭资源下载面板
		UIMgr.Close(VIEW_ID.PanelResourcesDownload, RESOURCES_PAGE.DOWNLOADING)
		return true
	end
    -- 下载扩展资源包
    if not tbPakResource.nStartDownload then
		-- 打开资源下载面板
		UIMgr.Open(VIEW_ID.PanelResourcesDownload, RESOURCES_PAGE.DOWNLOADING, 1)
        for _, v in pairs(PakDownloadMgr.tPakInfoList) do 
            PakDownloadMgr.DownloadPack(v.nPackID)
        end
        tbPakResource.nStartDownload = true
    end
    return false
end

-- 下载资源接口 nRePackID包的id
function tbPakResource.Download(nRePackID)
    PakDownloadMgr.DownloadPack(nRePackID)
end
local bPackId = false
-- 下载资源帧函数
function tbPakResource.FrameUpdate()
    if tbPakResource.base==1 then
        if tbPakResource.ParkStartbase() and tbPakResource.ParkCorePack() then
            tbPakResource.bDowloadEnd = true
            Timer.DelAllTimer(tbPakResource)
        end
    elseif tbPakResource.base==2 then
        if tbPakResource.ParkStartExtend() then
            tbPakResource.bDowloadEnd = true
            Timer.DelAllTimer(tbPakResource)
        end
	elseif tbPakResource.base==3 then
		if tbPakResource.ParkStartID(tbTDRPack) then
			tbPakResource.bDowloadEnd = true
            Timer.DelAllTimer(tbPakResource)
		end
    elseif tbPakResource.base==4 then
		if not bPackId then
			GetResourcePackId(szResourcePackId)
			bPackId = true
			return
		end
		if tbPakResource.ParkStartID(tbPakResource.tbPackId) then
			tbPakResource.bDowloadEnd = true
            Timer.DelAllTimer(tbPakResource)
		end
	end
end

local nDownloadtime = 30	-- 一分钟检测一次
local nCurrentTime = 0
local bStartDownload = false
local tbDownload = {}
tbDownload.bDowloadEnd=false
-- 检测下载的帧函数
function tbDownload.FrameUpdate()
	if GetTickCount()-nCurrentTime>nDownloadtime*1000 then
		-- 是否下载完成
		if tbPakResource.bDowloadEnd then
			LoginStart()
			Timer.DelAllTimer(tbDownload)
			return
		end
		-- 启动下载
		if not bStartDownload then
			tbPakResource.Start()
			bStartDownload = true
		end
		nCurrentTime=GetTickCount()
	end
end
--LoginGateway  and LoginPassword --
--登录服务器
local moduleServerList=LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)
--[[]]
local _LoginServerListRequestSuccess = moduleServerList._serverListRequestSuccess
function LoginServerListRequestSuccess()
	_LoginServerListRequestSuccess()
	LOG.INFO("serverTest1")
	if szRegion=='' then
		LoginMgr.Log("AutoLogin","未填写大区1:region -> %s",szRegion)
		return
	end
	if szServer=='' then
		LoginMgr.Log("AutoLogin","未填写服务器1:server -> %s",szServer)
		return
	end
	local tbRegion=moduleServerList.GetRegion(szRegion)
	if not tbRegion then
		LoginMgr.Log("AutoLogin","大区填写错误2:region -> %s",szRegion)
		--return
	end
	local tbServer=moduleServerList.GetServer(szRegion, szServer)
	
	if not tbServer then
		LoginMgr.Log("AutoLogin","服务器填写错误2:server -> %s",szServer)
		--return
	end
	LOG.INFO("serverTest2")
	Timer.Add(AutoLogin,nStepTime,function ()
		--设置服务器
		LOG.INFO("serverTest")
		moduleServerList.SetSelectServer(szRegion,szServer)
		PakDownloadMgr.Init()
		Timer.Add(AutoLogin,nStepTime,function ()
			if szAccount=='' then
				LoginMgr.Log("AutoLogin","未填写账号:account -> %s",szAccount)
				return
			end
			--设置账号-密码-用户协议-记住密码
			local bStatus, szErr=pcall(function ()
				UIHelper.SetSelected(g_tbLoginData.LoginView.TogCheck, true)
			end)
			if bStatus then
				UIHelper.SetSelected(g_tbLoginData.LoginView.TogConsent,true)	
				LoginMgr.GetModule(LoginModule.LOGIN_ACCOUNT).SetAccountPassword(szAccount,szPassword)
				-- 每隔1分钟 检测是否下载完成
				if tbPakResource.base ~= 0 then
					Timer.Add(AutoLogin,nStepTime,function ()
						-- 关闭资源下载弹窗
						UIMgr.Close(VIEW_ID.PanelNormalConfirmation)
						-- 启动检测下载的帧函数
						--[[]]
						if not tbDownload.bDowloadEnd then
							Timer.AddFrameCycle(tbDownload,1,function ()
								tbDownload.FrameUpdate()
							end)
							tbDownload.bDowloadEnd = true
						end
					end)
				else
					-- 执行登录
					LoginStart()
				end
			end
		end)
	end)
end
moduleServerList._serverListRequestSuccess=LoginServerListRequestSuccess


--[[]]
-- LoginServerList
--登录账号
local _LoginServerListOnEnter = moduleServerList.OnEnter
function LoginServerListOnEnter(szPrevStep)
	_LoginServerListOnEnter(szPrevStep)
	SearchPanel.IsEnterPanelByTrigger(function ()
		UINodeControl.BtnTrigger("BtnLogin")
	end,nStepTime,VIEW_ID.PanelSchoolSelect, VIEW_ID.PanelRoleChoices)
	LoginMgr.Log("AutoLogin","BtnLogin")
	LOG.INFO("Download Stop")
end
moduleServerList.OnEnter=LoginServerListOnEnter

--如果服务器异常 每隔1分钟重试一次
--[[
local moduleGateway=LoginMgr.GetModule(LoginModule.LOGIN_GATEWAY)
local _LoginGatewayOnHandShakeFail = moduleGateway.OnHandShakeFail
function LoginGatewayOnHandShakeFail(nEvent)
	_LoginGatewayOnHandShakeFail(nEvent)
	--Timer.Add(AutoLogin,60,function ()
		--g_tbLoginData.LoginView:Login()
		--UINodeControl.BtnTrigger("BtnStart")
	--end)
end
moduleGateway.OnHandShakeFail=LoginGatewayOnHandShakeFail
]]
--[[]]
-- LoginRole --
-- 解决起名失效的问题
local InputName = {}
local nNameNextTime = 10  --等待10秒后没有反应重新点击起名和确认
local nNameStartTime = 0 
-- local nInputLine = 1
function InputName.FrameUpdate(nRoletypeNum,nSchooltypeNum)
    if GetTickCount() - nNameStartTime > nNameNextTime*1000 then
        local bInputName = UIMgr.IsViewOpened(VIEW_ID.PanelCreateName_Login)
        if bInputName then
            -- if nInputLine == 1 then
            --     UINodeControl.BtnTrigger("BtnRandom","WidgetInfo01")
            --     LoginMgr.Log("AutoLogin","BtnRandom--随机名称")
            --     nInputLine = nInputLine + 1
            -- elseif nInputLine == 2 then
            --     UINodeControl.BtnTriggerByLable("BtnConfirm","确认")
            --     LoginMgr.Log("AutoLogin","BtnConfirm--确认")
            --     nInputLine = 1
            -- end
			if nRoletypeNum == 3 then
				nRoletypeNum = 6
			end
			if nRoletypeNum == 4 then
				nRoletypeNum = 5
			end
			--  5个汉字
			local szNewName
			local szName1 = RandomName(nRoletypeNum)
			local szName2 = RandomName(nRoletypeNum)
		
			if #szName1 == 12 then
				local subStr = string.sub(szName2, 1, 3)
				szNewName = szName1..subStr
			elseif #szName1 == 9 then
				local subStr = string.sub(szName2, 1, 6)
				szNewName = szName1..subStr
			end
			LoginMgr.GetModule(LoginModule.LOGIN_ROLE).CreateRole(nRoletypeNum,nSchooltypeNum,szNewName)
        else
            -- 结束帧函数
            Timer.DelAllTimer(InputName)
			UINodeControl.BtnTrigger("BtnNext","WidgetAnchorRightBottom")
			-- 进入游戏后重置所有参数
			bStartDownload = false
			tbDownload.bDowloadEnd=false
        end
        nNameStartTime = GetTickCount()
    end
end

--选中门派后需要的步骤容易卡顿造成执行失败
local function EnterBuildFace()
	--[[]]
	Timer.Add(AutoLogin,nStepTime,function ()
		UINodeControl.BtnTriggerByLable("BtnConfirm","下一步")
		LoginMgr.Log("AutoLogin","BtnConfirm--下一步")
	end)

	Timer.Add(AutoLogin,nStepTime*3,function ()
		UINodeControl.BtnTriggerByLable("BtnNext","下一步")
		LoginMgr.Log("AutoLogin","BtnNext1--下一步")
	end)
	
	Timer.Add(AutoLogin,nStepTime*4,function ()
		UINodeControl.BtnTrigger("BtnNext","WidgetAnchorRightButtom")
		LoginMgr.Log("AutoLogin","BtnNext2--下一步")
	end)
end

--角色创建
local nCreateRoleStartTime=0
local moduleRole=LoginMgr.GetModule(LoginModule.LOGIN_ROLE)
local _LoginRoleOnEnter = moduleRole.OnEnter
function LoginRoleOnEnter(szPrevStep)
	_LoginRoleOnEnter(szPrevStep)
	Timer.Add(AutoLogin,nStepTime,function ()
		local nRoletype=nil
		local nSchooltype=nil
		if bCreateRandomRole then
			nRoletype=m_tBodyType[SearchPanel.GetRandomKeyInTable(m_tBodyType)]
			nSchooltype=m_tAni[SearchPanel.GetRandomKeyInTable(m_tAni)]
		else
			nRoletype=m_tBodyType["成男"]
			nSchooltype=m_tAni["天策"]
		end
		
		if szRoletype~='' then
			nRoletype=m_tBodyType[szRoletype]
			if not nRoletype then
				LoginMgr.Log("AutoLogin","体型填写错误:roletype -> %s",szRoletype)
				return
			end
		end
		
		if szSchooltype~='' then
			nSchooltype=m_tAni[szSchooltype]
			if not nSchooltype then
				LoginMgr.Log("AutoLogin","门派填写错误:schooltype -> %s",szSchooltype)
				return
			end
		end

		--if szRoleName=='' then
			--szRoleName=RandomName(nRoletype)
		--end
		LOG.INFO(UTF8ToGBK(szRoleName))
		LoginMgr.Log("AutoLogin","test -> %s -> %s ",nRoletype,nSchooltype)
		--选中门派 选中体型
		Timer.Add(AutoLogin,nStepTime,function ()
			UIMgr.GetView(VIEW_ID.PanelSchoolSelect)["scriptView"]:SelectSchool(nSchooltype)
		end)
		Timer.Add(AutoLogin,nStepTime*2,function ()
			UIMgr.GetView(VIEW_ID.PanelSchoolSelect)["scriptView"]:SelectBody(nRoletype)
			EnterBuildFace()
		end)
		nCreateRoleStartTime=GetTickCount()
		--7*nStepTime 秒后还在为进入捏脸界面证明卡住了
		Timer.AddFrameCycle(AutoLogin,1,function ()
			if GetTickCount()-nCreateRoleStartTime>10*nStepTime*1000 then
				nCreateRoleStartTime=GetTickCount()
				if UIMgr.IsViewOpened(VIEW_ID.PanelBuildFace_Step2) then
					--进入了捏脸界面 结束更新函数
					Timer.DelAllTimer(AutoLogin)
					-- 是否存在起名界面
					if UIMgr.IsViewOpened(VIEW_ID.PanelCreateName_Login) then
						nNameStartTime = GetTickCount()
						Timer.AddCycle(InputName,1,function ()
							InputName.FrameUpdate(nRoletype,nSchooltype)
						end)
					else
                        -- 在易容界面卡住
                        UINodeControl.BtnTrigger("BtnNext","WidgetAnchorRightButtom")
                    end
				else
					--没有进入捏脸界面证明卡住了 重试
					LoginMgr.Log("AutoLogin","EnterBuildFace Retry")
					EnterBuildFace()
				end
			end
		end)
		--LoginMgr.GetModule(LoginModule.LOGIN_ROLE).CreateRole(nRoletype,nSchooltype,szRoleName)
	end)
end
moduleRole.OnEnter = LoginRoleOnEnter

-- LoginRoleList --
--角色列表
--[[]]
local moduleRoleList=LoginMgr.GetModule(LoginModule.LOGIN_ROLELIST)
local _LoginRoleListOnEnter = moduleRoleList.OnEnter
function LoginRoleListOnEnter(szPrevStep)
	_LoginRoleListOnEnter(szPrevStep)
	local nCount = Login_GetRoleCount()
	LoginMgr.Log("AutoLogin","RoleTest"..string.format(":%d",nCount))
	if nCount>0 then
		Timer.Add(AutoLogin,nStepTime,function ()
			local moduleRoleList = LoginMgr.GetModule(LoginModule.LOGIN_ROLELIST)
			--未填写角色名称,默认选择第一个角色
			szRoleName=''
			if szRoleName=='' then
				szRoleName=moduleRoleList.tbRoleInfoList[1].RoleName
			else
				local bRoleNameCheck=false
				for nIndex=1,#moduleRoleList.tbRoleInfoList do
					local tbRole=moduleRoleList.tbRoleInfoList[nIndex]
					LoginMgr.Log("AutoLogin",tbRole.RoleName.."角色名称--RoleName")
					if UTF8ToGBK(szRoleName)==tbRole.RoleName then
						szRoleName=tbRole.RoleName
						bRoleNameCheck=true
						break
					end
				end
				if not bRoleNameCheck then
					LoginMgr.Log("AutoLogin","角色名称填写错误:RoleName -> %s",szRoleName)
					return
				end
			end
			--moduleRoleList.EnterGame(szRoleName)
			Timer.Add(AutoLogin,nStepTime,function ()
				UINodeControl.BtnTriggerByLable("BtnStart","进入游戏")
				bStartDownload = false
				tbDownload.bDowloadEnd=false
				LoginMgr.Log("AutoLogin","BtnConfirm--进入游戏")
			end)
		end)
		-- LoginMgr.SwitchStep(LoginModule.LOGIN_ROLE)
	end
end
moduleRoleList.OnEnter= LoginRoleListOnEnter


return AutoLogin