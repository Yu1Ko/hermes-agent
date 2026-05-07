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
ini:Close()
local bCreateRandomRole=false
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
}

local m_tBodyType =
{
	["正太"] = ROLE_TYPE.LITTLE_BOY,        --正太
	["成男"] = ROLE_TYPE.STANDARD_MALE,     --成男
	["萝莉"] = ROLE_TYPE.LITTLE_GIRL,       --萝莉
	["成女"] = ROLE_TYPE.STANDARD_FEMALE,   --成女
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
		return
	end
	local tbServer=moduleServerList.GetServer(szRegion, szServer)
	
	if not tbServer then
		LoginMgr.Log("AutoLogin","服务器填写错误2:server -> %s",szServer)
		return
	end
	LOG.INFO("serverTest2")
	delayDoSomething(function()
		--设置服务器
		LOG.INFO("serverTest")
		moduleServerList.SetSelectServer(szRegion,szServer)
		delayDoSomething(function()
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
				delayDoSomething(function()
				--登录
					LoginMgr.Log("AutoLogin","%s -> %s",szRegion,szServer)
					g_tbLoginData.LoginView:Login()
				end, nStepTime)
			end
		end, nStepTime)		
	end, nStepTime)
end
moduleServerList._serverListRequestSuccess=LoginServerListRequestSuccess

--[[]]
-- LoginServerList
--登录账号
local _LoginServerListOnEnter = moduleServerList.OnEnter
function LoginServerListOnEnter(szPrevStep)
	_LoginServerListOnEnter(szPrevStep)
	delayDoSomething(function()
		--进入角色界面
		LoginMgr.SwitchStep(LoginModule.LOGIN_ROLELIST)
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
			g_tbLoginData.LoginView:Login()
		end, 60)
end
moduleGateway.OnHandShakeFail=LoginGatewayOnHandShakeFail

--[[]]
-- LoginRole --
--角色创建
local moduleRole=LoginMgr.GetModule(LoginModule.LOGIN_ROLE)
local _LoginRoleOnEnter = moduleRole.OnEnter
function LoginRoleOnEnter(szPrevStep)
	_LoginRoleOnEnter(szPrevStep)
	delayDoSomething(function()
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

		if szRoleName=='' then
			szRoleName=RandomName(nRoletype)
		end
		LoginMgr.Log("AutoLogin","test -> %s -> %s -> %s",nRoletype,nSchooltype,szRoleName)
		LoginMgr.GetModule(LoginModule.LOGIN_ROLE).CreateRole(nRoletype,nSchooltype,szRoleName)
	end, nStepTime)
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
		delayDoSomething(function()
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
			moduleRoleList.EnterGame(szRoleName)
		end, nStepTime)
		--LoginMgr.SwitchStep(LoginModule.LOGIN_ROLE)
	end
end
moduleRoleList.OnEnter= LoginRoleListOnEnter

return AutoLogin
