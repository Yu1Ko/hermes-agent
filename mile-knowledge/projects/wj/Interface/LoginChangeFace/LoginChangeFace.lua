LoginMgr.Log("AutoLogin","AutoLogin imported")
AutoLogin={}
LoginChangeFace ={}
LoginChangeFace.bSwitch =false
local PresetFace = {} 
local PresetFaceSecond = {}
local RunMap = {}
local list_RunMapCMD={}
local list_RunMapTime={}
AutoLogin.bSwitch=true
local szFilePath=SearchPanel.szCurrentInterfacePath.."Automation.ini"
LoginMgr.Log("AutoLogin",szFilePath)
local ini = Ini.Open(szFilePath)
local szRoleName=ini:ReadString("Automation", "RoleName", "")          --角色名
local szAccount=RandomString(8)         --账号
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

--读取tab的内容
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szInterfacePath.."LoginChangeFace/RunMap.tab",2)
list_RunMapCMD = tbRunMapData[1]
list_RunMapTime = tbRunMapData[2]
local bFlag = true	-- 是否执行前后置命令
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
	["正太"] = 4,        --正太
	["成男"] = 1,     --成男
	["萝莉"] = 3,       --萝莉
	["成女"] = 2,   --成女
}
--[[]]
-- LoginRole --
--角色创建
-- 捏脸预设界面
local FacePresetsLeft={}    -- 左边
local nFacePresetsLeftCount=0   -- 预设捏脸
local tbFacePresetsLeft    -- tog表
local bFacePresetsLeft = false
local nFacePresetsLeftLine=1   -- 捏脸预设界面（右）行数
local nFacePresetsLeftStartTime = 0
local nFacePresetsLeftNextTime = 3

local FacePresetsRight={}   -- 右边
local FacePresetsRightTog={}
FacePresetsRightTog.nStartTime = 0
FacePresetsRightTog.nNextTime = 10
local nFacePresetsRightCount=0   -- 预设捏脸右边按钮总数
local bFacePresetsRight = true
local tbFacePresetsRight    -- tog表
local nTogCount = 0	-- 面板总数
local nTogLine = 1
local nFacePresetsRightLine=1   -- 捏脸预设界面（右）行数
local nFacePresetsRightStartTime = 0
local nFacePresetsRightNextTime = 5

-- 细节调整
DetailPanel={}	-- 总开关
DetailPanelLeft={}	-- 细节调整左边
DetailPanelRight={}	-- 细节调整右边

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

local function EnterBuildFace()
	--[[]]
	Timer.Add(AutoLogin,nStepTime,function ()
		UINodeControl.BtnTriggerByLable("BtnConfirm","下一步")
		LoginMgr.Log("AutoLogin","BtnConfirm--下一步")
	end)
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
local nDownloadtime = 60	-- 一分钟检测一次
local nCurrentTime = 0
local bStartDownload = false
local Download = {}
local _LoginServerListOnEnter = moduleServerList.OnEnter
function LoginServerListOnEnter(szPrevStep)
	_LoginServerListOnEnter(szPrevStep)
	-- 每隔1分钟 检测是否下载完成
	delayDoSomething(function()
		-- 关闭资源下载弹窗
		UIMgr.Close(VIEW_ID.PanelNormalConfirmation)
		-- 启动检测下载的帧函数
		Timer.AddFrameCycle(Download,1,function ()
			Download.FrameUpdate()
		end)
	end, nStepTime)
end
moduleServerList.OnEnter=LoginServerListOnEnter

-- 检测下载的帧函数
function Download.FrameUpdate()
	if GetTickCount()-nCurrentTime>nDownloadtime*1000 then
		-- 检测基础包是否下载完成
		local nState, _, _ = PakDownloadMgr.GetBasicPackState()
		if nState == DOWNLOAD_OBJECT_STATE.DOWNLOADED then
			LoginMgr.SwitchStep(LoginModule.LOGIN_ROLELIST)
			Timer.DelAllTimer(Download)
			Download.IsRun=false
			LOG.INFO("Download Stop")
		end
		-- 启动下载
		if not bStartDownload then
			LoginMgr.GetModule(LoginModule.LOGIN_DOWNLOAD).StartDownload()
			bStartDownload = true
		end
		nCurrentTime=GetTickCount()
	end
end

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
			if GetTickCount()-nCreateRoleStartTime>20*1000 then
				nCreateRoleStartTime=GetTickCount()
				if UIMgr.IsViewOpened(VIEW_ID.PanelBuildFace) then
					Timer.DelAllTimer(AutoLogin)
					--进入了捏脸界面 结束更新函数 启动捏脸
					Timer.AddCycle(PresetFace,2,function ()
						PresetFace.FrameUpdate()
					end)
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
    -- 如果有角色就创建角色
	if nCount>0 then
        delayDoSomething(function()
			moduleRoleList.CreateRole()
		end, nStepTime)
	end
end
moduleRoleList.OnEnter= LoginRoleListOnEnter


-- 预设界面
local nTypePreseCount = 0	-- 预设总目录
local nTypePreseLine = 1	-- 当前预设目录
local nSecondListCount = 1	-- 整体目录总数
local nSecondListLine = 1	-- 当前遍历身体目录
local bPresetFaceFirst = false
local bPresetFaceStart = false
local bPresetFaceSecond = false
local PresetFaceEnd = {}
function GetTabTypeCount()
	local nTabTypeCount = UINodeControl.GetToggroup("TogGroupTabType")
    nTypePreseCount = #nTabTypeCount
end

function GetDefaultListCount()
	local nDefaultListCount = UINodeControl.GetToggroup("ScrollViewDefaultList")
    nSecondListCount = #nDefaultListCount
end

function GetFaceListCount()
	local nFaceListCount = UINodeControl.GetToggroup("ScrollViewFaceList")
    nSecondListCount = #nFaceListCount
end

function GetBodyListCount()
	local nBodyCount = UINodeControl.GetToggroup("ScrollViewBodyList")
    nSecondListCount = #nBodyCount
end

function PresetFaceSecond.FrameUpdate()
	if not bPresetFaceSecond then
		if nTypePreseLine == 1 then
			GetDefaultListCount()
		elseif nTypePreseLine == 2 then
			GetFaceListCount()
		elseif nTypePreseLine == 3 then
			GetBodyListCount()
		end
		bPresetFaceSecond = true
	end
	if nSecondListLine ~= nSecondListCount+1 then
		if nSecondListLine ~= 1 then
			if nTypePreseLine == 1 then
				UINodeControl.TogTriggerByIndex("ScrollViewDefaultList",nSecondListLine)
			elseif nTypePreseLine == 2 then
				UINodeControl.TogTriggerByIndex("ScrollViewFaceList",nSecondListLine)
			elseif nTypePreseLine == 3 then
				UINodeControl.TogTriggerByIndex("ScrollViewBodyList",nSecondListLine)
			end
		end
		nSecondListLine = nSecondListLine + 1
	else
		nSecondListLine = 1
		bPresetFaceSecond= false
		nTypePreseLine = nTypePreseLine + 1
		Timer.DelAllTimer(PresetFaceSecond)
		bPresetFaceFirst = false
	end
end


function PresetFace.FrameUpdate()
	if not bPresetFaceStart then
		GetTabTypeCount()
		bPresetFaceStart = true
		return
	end
	if nTypePreseLine == nTypePreseCount+1 then
		-- 结束帧函数
		-- Timer.AddFrameCycle(FacePresetsLeft,1,function ()
		-- 	FacePresetsLeft.FrameUpdate()
		-- end)
		Timer.DelAllTimer(PresetFace)
		UINodeControl.BtnTriggerByLable("BtnNext","下一步")
		Timer.AddCycle(PresetFaceEnd,3,function ()
			if UIMgr.IsViewOpened(VIEW_ID.PanelBuildFace_Step2) then
				Timer.DelAllTimer(PresetFaceEnd)
				--进入了捏脸界面 结束更新函数 启动捏脸
				Timer.AddFrameCycle(FacePresetsLeft,1,function ()
					FacePresetsLeft.FrameUpdate()
				end)
			end
		end)
	end
	if not bPresetFaceFirst then
		UINodeControl.TogTriggerByIndex("TogGroupTabType",nTypePreseLine)
		bPresetFaceFirst = true
		Timer.AddCycle(PresetFaceSecond,4,function ()
			PresetFaceSecond.FrameUpdate()
		end)
	end
end

--print(UINodeControl.GetToggroup("ScrollViewDefaultList"))
-- 捏脸预设面板（左）
-- 初始化预设列表数据
function FacePresetsLeft.Initialization()
    tbFacePresetsLeft = UINodeControl.GetToggroup("TogGroupDefaultList")
    nFacePresetsLeftCount = #tbFacePresetsLeft
end

function FacePresetsLeft.FrameUpdate()
    if GetTickCount() - nFacePresetsLeftStartTime >= nFacePresetsLeftNextTime*1000 then
        --结束捏脸预设面板右左边边遍历 进行右边面板遍历
		if not bFacePresetsLeft then
			UINodeControl.TogTriggerByIndex("TogGroupPage",5)
			FacePresetsLeft.Initialization()
			bFacePresetsLeft= true
			nFacePresetsLeftStartTime = GetTickCount()
			return
		end
        if nFacePresetsLeftLine == nFacePresetsLeftCount + 1 then
            -- 结束帧函数
			Timer.DelAllTimer(FacePresetsLeft)
			Timer.AddFrameCycle(FacePresetsRight,1,function ()
				FacePresetsRight.FrameUpdate()
			end)
        end
        UINodeControl.TogTriggerByIndex("TogGroupDefaultList",nFacePresetsLeftLine)
        nFacePresetsLeftLine = nFacePresetsLeftLine + 1
        nFacePresetsLeftStartTime = GetTickCount()
    end
end

-- 捏脸预设面板（右）
-- 初始化预设列表数据
function FacePresetsRight.Initialization()
    tbFacePresetsRight = UINodeControl.GetToggroup("LayoutRightTop")
    nFacePresetsRightCount = #tbFacePresetsRight
end
-- 初始化左侧面板
function FacePresetsRight.LayoutList()
    tbFacePresetsRight = #UINodeControl.GetToggroup("LayoutList1")
    nTogCount = tbFacePresetsRight
end


function FacePresetsRight.FrameUpdate()
	if bFacePresetsRight and GetTickCount() - nFacePresetsRightStartTime >= nFacePresetsRightNextTime*1000 then
		if nFacePresetsRightCount ==0  then
			FacePresetsRight.Initialization()
			return
		end
		-- 这部分暂时写死 节点中有个表情被屏蔽掉了
		if nFacePresetsRightLine ==  3 then
			Timer.DelAllTimer(FacePresetsRight)
			DetailPanel.Start()
		end
		UINodeControl.TogTriggerByIndex("LayoutRightTop",nFacePresetsRightLine)
		nFacePresetsRightStartTime = GetTickCount()
		bFacePresetsRight = false
		FacePresetsRightTog.nStartTime = GetTickCount()
		Timer.AddFrameCycle(FacePresetsRightTog,1,function ()
			FacePresetsRightTog.FrameUpdate()
		end)
	end
end

local bTogInitialization = false	--初始化
-- 暂时写死 选中天气试穿表情这部分
function FacePresetsRightTog.FrameUpdate()
	if GetTickCount() - FacePresetsRightTog.nStartTime >= FacePresetsRightTog.nNextTime*1000 then
		if not bTogInitialization then
			FacePresetsRight.LayoutList()
			bTogInitialization = true
			FacePresetsRightTog.nStartTime = GetTickCount()
			return
		end
		if nTogLine == nTogCount+1  then
			nFacePresetsRightLine = nFacePresetsRightLine + 1
			bTogInitialization = false
			bFacePresetsRight = true
			nTogLine = 1
			nFacePresetsRightStartTime = GetTickCount()
			Timer.DelAllTimer(FacePresetsRightTog)
			return
		end
		UINodeControl.TogTriggerByIndex("LayoutList1",nTogLine)
		nTogLine = nTogLine + 1
		FacePresetsRightTog.nStartTime = GetTickCount()
	end
end



--细节调整
DetailPanelLeft.nStartTime=0
DetailPanelLeft.nNextTime=3
DetailPanelRight.nStartTime=0
DetailPanelRight.nNextTime=5
DetailPanelLeft.TogGroupPageCount=0
DetailPanelLeft.TogGroupClass1Count=0
DetailPanelLeft.TogGroupClass2Count=0
DetailPanelLeft.TogGroupPageLine=1
DetailPanelLeft.TogGroupClass1Line=1
DetailPanelLeft.TogGroupClass2Line=1
DetailPanelLeft.TogGroupClass3Line = 1	-- 三级目录
local nSpecialCount
-- 第一目录
function GetTogGroupPageCount()
	local nCount = #UINodeControl.GetToggroup("TogGroupPage")
	DetailPanelLeft.TogGroupPageCount=nCount
	return DetailPanelLeft.TogGroupPageCount
end

-- 第二目录
function GetTogGroupClass1Count()
	if DetailPanelLeft.TogGroupPageLine ~= 3 then
		local nCount = #UINodeControl.GetToggroup("ScrollViewTab2")
		DetailPanelLeft.TogGroupClass1Count=nCount
		return DetailPanelLeft.TogGroupClass1Count
	else
		DetailPanelLeft.TogGroupClass1Count=0
		return DetailPanelLeft.TogGroupClass1Count
	end
end
-- 第三目录 特殊操作有些目录没有第三目录
function GetTogGroupClass2Count()
	if DetailPanelLeft.TogGroupPageLine == 3 or DetailPanelLeft.TogGroupPageLine == 4 then
		DetailPanelLeft.TogGroupClass2Count= 0
		return DetailPanelLeft.TogGroupClass2Count
	else
		local nCount = #UINodeControl.GetToggroup("TogGroupClass1")
		-- 特殊处理
		if DetailPanelLeft.TogGroupClass2Line ~= 1 then
			nSpecialCount = nCount-DetailPanelLeft.TogGroupClass2Line
		else
			nSpecialCount = nCount
		end
		nSpecialCount = nCount
		DetailPanelLeft.TogGroupClass2Count= nSpecialCount
		return DetailPanelLeft.TogGroupClass2Count
	end
end

-- 分为三种面板
local nTogLine = 2
local bDetailPanelRight = false
-- 封装处理函数
function DetailPanelTogTrigger()
	if DetailPanelLeft.TogGroupPageLine == 1 then
		if DetailPanelLeft.TogGroupClass2Line == 1 and DetailPanelLeft.TogGroupClass2Line == 1 then
			UINodeControl.TogTriggerByIndex("TogGroupDefault",nTogLine)
		else
			UINodeControl.BtnTriggerByCnt("ButtonAdd",2)
		end
	elseif DetailPanelLeft.TogGroupPageLine ==2 then
		if DetailPanelLeft.TogGroupClass1Line == 5 and DetailPanelLeft.TogGroupClass3Line == 2 or DetailPanelLeft.TogGroupClass1Line == 5 and DetailPanelLeft.TogGroupClass3Line == 3 then
			UINodeControl.TogTriggerByIndex("TogGroupDetailAdjust",nTogLine)
		elseif DetailPanelLeft.TogGroupClass1Line == 7 and DetailPanelLeft.TogGroupClass3Line == 2 then
			UINodeControl.TogTriggerByIndex("TogGroupDetailAdjust",nTogLine)
		elseif DetailPanelLeft.TogGroupClass1Line == 9 and DetailPanelLeft.TogGroupClass3Line == 1 then
			UINodeControl.TogTriggerByIndex("TogGroupDetailAdjust",nTogLine)
		else
			UINodeControl.TogTriggerByIndex("ScrollViewDetailAdjust",nTogLine)
		end
	elseif DetailPanelLeft.TogGroupPageLine ==3 then
		UINodeControl.TogTriggerByIndex("ScrollViewDefault",nTogLine)
	elseif DetailPanelLeft.TogGroupPageLine == 4 then
		if DetailPanelLeft.TogGroupClass2Line == 1 then
			UINodeControl.TogTriggerByIndex("ScrollViewDefault",8)
		else
			UINodeControl.BtnTriggerByCnt("ButtonAdd",5)
		end
	end
end

function GetDetailPanelTogCount()
	local nDetailPanelTogCount = 0
	if DetailPanelLeft.TogGroupPageLine == 1 then
		if DetailPanelLeft.TogGroupClass2Line == 1 and DetailPanelLeft.TogGroupClass2Line == 1 then
			nDetailPanelTogCount = #UINodeControl.GetToggroup("TogGroupDefault")
		end
	elseif DetailPanelLeft.TogGroupPageLine ==2 then
		if DetailPanelLeft.TogGroupClass1Line == 5 and DetailPanelLeft.TogGroupClass3Line == 2 or DetailPanelLeft.TogGroupClass1Line == 5 and DetailPanelLeft.TogGroupClass3Line == 3 then
			nDetailPanelTogCount = #UINodeControl.GetToggroup("TogGroupDetailAdjust")
		elseif DetailPanelLeft.TogGroupClass1Line == 7 and DetailPanelLeft.TogGroupClass3Line == 2 then
			nDetailPanelTogCount = #UINodeControl.GetToggroup("TogGroupDetailAdjust")
		elseif DetailPanelLeft.TogGroupClass1Line == 9 and DetailPanelLeft.TogGroupClass3Line == 1 then
			nDetailPanelTogCount = #UINodeControl.GetToggroup("TogGroupDetailAdjust")
		else
			nDetailPanelTogCount = #UINodeControl.GetToggroup("ScrollViewDetailAdjust")
		end
	elseif DetailPanelLeft.TogGroupPageLine ==3 then
		nDetailPanelTogCount = #UINodeControl.GetToggroup("ScrollViewDefault")
	elseif DetailPanelLeft.TogGroupPageLine == 4 then
		if DetailPanelLeft.TogGroupClass2Line == 1 then
			nDetailPanelTogCount = #UINodeControl.GetToggroup("ScrollViewDefault")
		end
	end
	return nDetailPanelTogCount
end
local bInitial = false
-- 本处使用很多的特殊操作 因为在切换面板时 左边面板和右边的面板对应不上 分为两部分操作
function DetailPanelLeft.FrameUpdate()
	if not bDetailPanelRight and GetTickCount() - DetailPanelLeft.nStartTime >= DetailPanelLeft.nNextTime*1000 then
		if not bInitial then
			-- 初始化点击一次
			UINodeControl.TogTriggerByIndex("TogGroupPage",1)
			DetailPanelLeft.nStartTime= GetTickCount()
			bInitial = true
			return
		end
		print("abc",DetailPanelLeft.TogGroupPageLine,DetailPanelLeft.TogGroupClass1Line,DetailPanelLeft.TogGroupClass3Line)
		print("abc1",GetTogGroupClass2Count()+1,GetTogGroupClass1Count()-1)
		if DetailPanelLeft.TogGroupClass3Line ~= GetTogGroupClass2Count()+1 then
			if GetTogGroupClass2Count() == 0 then
				DetailPanelLeft.TogGroupClass3Line = GetTogGroupClass2Count()+1
				return
			end
			if DetailPanelLeft.TogGroupPageLine ~= 4 then
				if DetailPanelLeft.TogGroupClass3Line ~= 1  then
					UINodeControl.TogTriggerByIndex("TogGroupClass1",DetailPanelLeft.TogGroupClass2Line)
				end
			end
			-- DetailPanelLeft.TogGroupClass2Line = DetailPanelLeft.TogGroupClass2Line + 1
			-- DetailPanelLeft.TogGroupClass3Line = DetailPanelLeft.TogGroupClass3Line + 1
		elseif DetailPanelLeft.TogGroupClass1Line ~= GetTogGroupClass1Count()-1 then
			if GetTogGroupClass1Count() == 0 then
				DetailPanelLeft.TogGroupClass1Line = GetTogGroupClass1Count()-1
				return
			end
			DetailPanelLeft.TogGroupClass1Line = DetailPanelLeft.TogGroupClass1Line + 2
			if DetailPanelLeft.TogGroupPageLine == 2 and DetailPanelLeft.TogGroupClass1Line == 9 then
				UINodeControl.TogTriggerByIndex("ScrollViewTab2",10)
			else
				UINodeControl.TogTriggerByIndex("ScrollViewTab2",DetailPanelLeft.TogGroupClass1Line)
			end
			DetailPanelLeft.TogGroupClass3Line = 1
		elseif DetailPanelLeft.TogGroupPageLine ~= GetTogGroupPageCount()-2 then
			DetailPanelLeft.TogGroupPageLine = DetailPanelLeft.TogGroupPageLine + 1
			UINodeControl.TogTriggerByIndex("TogGroupPage",DetailPanelLeft.TogGroupPageLine)
			DetailPanelLeft.TogGroupClass2Line = 1
			DetailPanelLeft.TogGroupClass3Line = 1
			DetailPanelLeft.TogGroupClass1Line = 1
		else
			Timer.DelAllTimer(DetailPanelLeft)
			bFlag = true
		end
		-- DetailPanelLeft.nStartTime= GetTickCount()
		DetailPanelRight.nStartTime = GetTickCount()
		-- 右边面板遍历
		bDetailPanelRight = true
		Timer.AddFrameCycle(DetailPanelRight,1,function ()
			DetailPanelRight.FrameUpdate()
		end)
	end
end


local tbDetailPanelRightTog = {2}	-- 需要遍历的参数 默认会遍历最后一个参数
local nDetailPanelRightTogLine = 1
function DetailPanelRight.FrameUpdate()
	if GetTickCount() - DetailPanelRight.nStartTime >= DetailPanelRight.nNextTime*1000 then
		if nDetailPanelRightTogLine == #tbDetailPanelRightTog+2 or GetDetailPanelTogCount() == 0 then
			DetailPanelLeft.nStartTime= GetTickCount()
			bDetailPanelRight = false
			nDetailPanelRightTogLine= 1
			DetailPanelLeft.TogGroupClass2Line = DetailPanelLeft.TogGroupClass2Line + 1
			DetailPanelLeft.TogGroupClass3Line = DetailPanelLeft.TogGroupClass3Line + 1
			Timer.DelAllTimer(DetailPanelRight)
		end
		if nDetailPanelRightTogLine == #tbDetailPanelRightTog+1 then
			nTogLine = GetDetailPanelTogCount()
		else
			nTogLine = tbDetailPanelRightTog[nDetailPanelRightTogLine]
		end
		-- 执行
		DetailPanelTogTrigger()
		DetailPanelRight.nStartTime = GetTickCount()
		nDetailPanelRightTogLine = nDetailPanelRightTogLine + 1
	end
end

DetailPanel.bSwitch = true
function DetailPanel.Start()
	if not DetailPanel.bSwitch then
		return
	end
	DetailPanelLeft.nStartTime=GetTickCount()
	Timer.AddFrameCycle(DetailPanelLeft,1,function ()
		DetailPanelLeft.FrameUpdate()
	end)
end

local pCurrentTime = 0
local nNextTime=tonumber(30)
local nCurrentStep=1
-- 前后置条件
function RunMap.FrameUpdate()
    if bFlag and GetTickCount()-pCurrentTime>nNextTime*1000 then
        if nCurrentStep==#list_RunMapCMD then
            bFlag=false
        end
        --切图前后置操作
        local szCmd=list_RunMapCMD[nCurrentStep]
        local nTime=tonumber(list_RunMapTime[nCurrentStep])
        print(szCmd)
        pcall(function ()
            SearchPanel.RunCommand(szCmd)
        end)
        print(szCmd.."ok")
        if string.find(szCmd,"perfeye_start") then
            SearchPanel.bPerfeye_Start=true
        end
        if string.find(szCmd,"perfeye_stop") then
            SearchPanel.bPerfeye_Stop=true
        end
        nNextTime=nTime
        --切图操作
        if string.find(szCmd,"LoginChangeFace") then
            -- 启动遍历
			LoginChangeFace.bSwitch = true
            bFlag=false
        end
		pCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1 
    end
end

Timer.AddFrameCycle(RunMap,1,function ()
	RunMap.FrameUpdate()
end)


return AutoLogin