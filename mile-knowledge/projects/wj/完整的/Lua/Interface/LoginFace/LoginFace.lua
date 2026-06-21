LoginFace = {}
FaceChange = {} -- 易容界面
LoginRevert = {}
FaceChange.Right = {}
FaceChange.Left = {}
LoginFace.RightStartTime = 0
LoginFace.RightNextTime = 5 -- 此处为左边所有遍历时间 统一进行控制
LoginFace.LeftStartTime = 0
LoginFace.LeftNextTime = 5
LoginFace.nRoletypeTemp = 1	-- 当前遍历的体型
local bFlag = true	-- 是否执行前后置命令
-- 登录设置部分
AutoLogin={}
local szFilePath=SearchPanel.szCurrentInterfacePath.."Automation.ini"
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
local nStepTime=tonumber(szStepTime)/1000

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

--延时调用装饰器 执行回调函数一次
local delayDoSomething = function(callback, time)
    local handle
    handle = SearchPanel.director:getScheduler():scheduleScriptFunc(function()
        SearchPanel.director:getScheduler():unscheduleScriptEntry(handle)
        callback()
    end, time, false)
    return handle
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
	["刀宗"]= KUNGFU_ID.DAO_ZONG,		--刀宗
	["药宗"]= KUNGFU_ID.YAO_ZONG,		--药宗
	["衍天"]= KUNGFU_ID.YAN_TIAN,		--衍天
}

local m_tBodyType =
{
	["正太"] = 4,        --正太
	["成男"] = 1,     --成男
	["萝莉"] = 3,       --萝莉
	["成女"] = 2,   --成女
}


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

LoginCreateRole = {}
local nRoletype=nil
local nSchooltype=nil
LoginCreateRole.bStart = false
LoginCreateRole.nStatus = 1
LoginCreateRole.nStartTime = 0
LoginCreateRole.nNextTime = 6       --登录界面设置
LoginCreateRole.bFrame = false

local moduleRole=LoginMgr.GetModule(LoginModule.LOGIN_ROLE)
local _LoginRoleOnEnter = moduleRole.OnEnter
function LoginRoleOnEnter(szPrevStep)
	_LoginRoleOnEnter(szPrevStep)
    if not LoginCreateRole.bFrame then
        Timer.AddFrameCycle(LoginCreateRole,1,function ()
			LoginCreateRole.FrameUpdate()
		end)
        LoginCreateRole.bFrame = true
    end
end
moduleRole.OnEnter = LoginRoleOnEnter


-- 选择角色
function LoginCreateRole.FrameUpdate()
    if not LoginCreateRole.bStart then
        -- 选中体型
        nRoletype=LoginFace.nRoletypeTemp
        nSchooltype=m_tAni[szSchooltype]
        LoginCreateRole.bStart=true
        return
    end
    -- 3秒执行
    if GetTickCount()-LoginCreateRole.nStartTime>LoginCreateRole.nNextTime*1000 then
		print(LoginCreateRole.nStartTime,LoginCreateRole.nNextTime)
        if LoginCreateRole.nStatus == 1 then
            -- 选择角色
            UIMgr.GetView(VIEW_ID.PanelSchoolSelect)["scriptView"]:SelectSchool(nSchooltype)
            LoginCreateRole.nStatus=LoginCreateRole.nStatus + 1
        elseif LoginCreateRole.nStatus == 2 then
            -- 选择体型
			UINodeControl.TogTriggerByIndex("ToggleGroupBodilyForm",nRoletype)
            LoginCreateRole.nStatus=LoginCreateRole.nStatus + 1
        elseif LoginCreateRole.nStatus == 3 then
            -- 点击登录
            UINodeControl.BtnTriggerByLable("BtnConfirm","下一步")
            LoginCreateRole.nStatus=LoginCreateRole.nStatus + 1
        elseif LoginCreateRole.nStatus == 4 then
            Timer.DelAllTimer(LoginCreateRole)
            LoginCreateRole.bFrame = false
            --进入了捏脸界面 结束更新函数 启动捏脸
            Timer.AddFrameCycle(Preset.FirstDirectory,1,function () Preset.RightFristFrameUpdate() end)
            LoginCreateRole.nStatus = 1
        end
        LoginCreateRole.nStartTime = GetTickCount()
    end
end


-- 捏脸部分
-- （预设界面）
--[[
    左边 一级目录 类型
    整体 1 tog
    面部 1 tog
    身体 1 tog
    注：目录为最高为2级目录
]]
-- 预设左边遍历时间
Preset = {}
Preset.FirstDirectory = {}
Preset.SecondDirectory= {}
Preset.bStart = false -- 初始化赋值
Preset.FirstDirectory.bStatus = false
Preset.SecondDirectory.bStart = false
Preset.FirstDirectoryCount = 0
Preset.SecondDirectoryCount = 0
Preset.FirstDirectoryLine = 1
Preset.SecondDirectoryLine = 1
-- 初始化一级目录
function Preset.GetFirstDirectoryCount()
    local nTabTypeCount = UINodeControl.GetToggroup("TogGroupTabType")
	Preset.FirstDirectoryCount = #nTabTypeCount
end

-- 初始化二级目录
function Preset.GetSecondDirectoryCount()
	local nDirectoryCount
	-- 写死 三个栏目
    if Preset.FirstDirectoryLine == 1 then
		local nDefaultListCount = UINodeControl.GetToggroup("ScrollViewDefaultList")
		nDirectoryCount = #nDefaultListCount
	elseif Preset.FirstDirectoryLine == 2  then
		local nFaceListCount = UINodeControl.GetToggroup("ScrollViewFaceList")
    	nDirectoryCount = #nFaceListCount
	elseif Preset.FirstDirectoryLine == 3 then
		local nBodyCount = UINodeControl.GetToggroup("ScrollViewBodyList")
    	nDirectoryCount = #nBodyCount
	end
	Preset.SecondDirectoryCount = nDirectoryCount
end


-- 预设界面右边部分
function Preset.RightFristFrameUpdate()
	-- 初始化
	if not Preset.bStart then
		Preset.GetFirstDirectoryCount()
		Preset.bStart = true
		return
	end
	-- 是否结束遍历
	if Preset.FirstDirectoryCount+1 == Preset.FirstDirectoryLine then
		-- 结束帧函数
		Timer.DelAllTimer(Preset.FirstDirectory)
		Preset.bStart = true
		Preset.FirstDirectoryLine = 1
		Preset.SecondDirectoryLine = 1
		UINodeControl.BtnTriggerByLable("BtnNext","下一步")
		-- 开始易容界面的遍历
		LoginFace.LeftStartTime = GetTickCount()
		Timer.AddFrameCycle(FaceChange.Right,1,function () FaceChange.RightFrameUpdate() end)
		return
	end
	if not Preset.FirstDirectory.bStatus then
		if GetTickCount()-LoginFace.LeftStartTime >= LoginFace.LeftNextTime*1000 then
			UINodeControl.TogTriggerByIndex("TogGroupTabType",Preset.FirstDirectoryLine)
			Timer.AddFrameCycle(Preset.SecondDirectory,1,function ()
				Preset.RightSecondFrameUpdate()
			end)
			Preset.FirstDirectory.bStatus = true
			LoginFace.LeftStartTime = GetTickCount()
		end
	end
end


function Preset.RightSecondFrameUpdate()
	if GetTickCount()-LoginFace.LeftStartTime >= LoginFace.LeftNextTime*1000 then
		-- 初始化需要缓冲
		if not Preset.SecondDirectory.bStart then
			Preset.GetSecondDirectoryCount()
			LoginFace.LeftStartTime = GetTickCount()
			Preset.SecondDirectory.bStart = true
			Timer.AddFrameCycle(Preset.SecondDirectory,1,function ()
				Preset.RightSecondFrameUpdate()
			end)
			return
		end
		-- 是否结束遍历
		if Preset.SecondDirectoryCount+1 == Preset.SecondDirectoryLine then
			-- 结束帧函数
			Timer.DelAllTimer(Preset.SecondDirectory)
			LoginFace.LeftStartTime = GetTickCount()
			Preset.FirstDirectory.bStatus = false
			Preset.FirstDirectoryLine = Preset.FirstDirectoryLine + 1
			Preset.SecondDirectoryLine = 1
			return
		end
		if Preset.FirstDirectoryLine == 1 then
			UINodeControl.TogTriggerByIndex("ScrollViewDefaultList",Preset.SecondDirectoryLine)
		elseif Preset.FirstDirectoryLine == 2  then
			UINodeControl.TogTriggerByIndex("ScrollViewFaceList",Preset.SecondDirectoryLine)
		elseif Preset.FirstDirectoryLine == 3 then
			UINodeControl.TogTriggerByIndex("ScrollViewBodyList",Preset.SecondDirectoryLine)
		end
		Preset.SecondDirectoryLine = Preset.SecondDirectoryLine + 1
		LoginFace.LeftStartTime = GetTickCount()
	end
end


-- 滑动条
FaceChange.nSliderCount =0 -- 滑动条总数
FaceChange.nSliderLine =1 -- 当前操作滑动条
-- 颜色Tog
FaceChange.nColorCount = 0 -- 颜色总数
FaceChange.nColorLine =1 -- 当前操作颜色

-- 一级目录
FaceChange.nFristCount= 0
FaceChange.nFristLine = 1

-- 二级目录
FaceChange.nSecondCount= 0
FaceChange.nSecondLine = 2

-- 三级目录
FaceChange.nThirdCount= 0
FaceChange.nThirdLine = 1


-- 滑动条的数据的总数
function FaceChange.GetSliderPercent()
	-- 先清除掉数据 防止节点增加
	UINodeControl.DealWithException(EventType.OnChangeSliderPercent)
	FaceChange.nSliderCount = #UINodeControl.tbUINodeData['OnChangeSliderPercent']
	return FaceChange.nSliderCount
end
-- 妆容颜色的总数
function FaceChange.GetColorCell()
	FaceChange.nColorCount = #UINodeControl.GetToggroup("TogGroupColorCell")
end

-- 一级目录
function FaceChange.FristCount()
	FaceChange.nFristCount = #UINodeControl.GetToggroup("TogGroupPage")
	return FaceChange.nFristCount
end

-- 二级目录
function FaceChange.SecondCount()
	FaceChange.nSecondCount = #UINodeControl.GetToggroup("ScrollViewTab2")
	return FaceChange.nSecondCount
end

-- 三级目录
function FaceChange.ThirdCount()
	FaceChange.nThirdCount = #UINodeControl.GetToggroup("TogGroupClass1")
	return FaceChange.nThirdCount
end

--[[
	易容）界面遍历大纲
预设 1 tog -- 暂时不管

面容 （目录1） 轮廓 眉毛 眼部 鼻子 嘴部 （2号目录）  （3号目录）每一栏开始都为Tog  最后都为数值调节 

妆容 （目录1）（此处直接特殊处理部分栏目）
	1:第一种为 2号目录   3号目录  3号目录Tog (默认第一项没有颜色面板) 最右侧的颜色（默认点击为第一项颜色：除第一项颜色之外 其他颜色均有 百分比拉条）
	2:第二种 （特殊栏目4号目录）
		包含：
			妆容2 ->眼妆3 -> 眼影2
			妆容2 ->眼妆3 -> 眼影闪点3
			妆容2 ->唇妆4 -> 唇彩2
			妆容2 ->唇妆4 -> 唇彩2
			妆容2 ->面妆4 -> 贴花1
		2号目录   3号目录  3号目录Tog  4号目录Tog (默认第一项没有颜色面板) 最右侧的颜色（默认点击为第一项颜色：除第一项颜色之外 其他颜色均有 百分比拉条）

发型部分 1 tog

体型 除预设栏目的 都为数值调节
]]
-- 右面板
local bInitial = false
local bDetailPanelRight = true
local nThirdLineClass = 1
function FaceChange.RightFrameUpdate()
	if bDetailPanelRight and GetTickCount()-LoginFace.LeftStartTime >= LoginFace.LeftNextTime*1000 then
		if not bInitial then
			-- 初始化点击一次
			UINodeControl.TogTriggerByIndex("TogGroupPage",1)
			LoginFace.LeftStartTime= GetTickCount()
			bInitial = true
			return
		end
		if  FaceChange.nFristLine == 5 then
			-- 体型是否遍历完成
			if LoginFace.nRoletypeTemp == 4 then
				Timer.DelAllTimer(FaceChange.Right)
				bFlag = true
				return
			else
				FaceChange.Reset()
				Timer.DelAllTimer(FaceChange.Right)
				LoginFace.nRoletypeTemp = LoginFace.nRoletypeTemp + 1
				Timer.AddFrameCycle(LoginRevert,1,function () LoginRevert.FrameUpdate() end)
				return
			end
		end
		print(FaceChange.nThirdLine,FaceChange.nSecondLine,FaceChange.nFristLine,nThirdLineClass)
		if FaceChange.nThirdLine ~= FaceChange.ThirdCount()+1 then
			if FaceChange.nThirdLine ~=1 then
				UINodeControl.TogTriggerByIndex("TogGroupClass1",nThirdLineClass)
			end
			nThirdLineClass = nThirdLineClass + 1
			FaceChange.nThirdLine = FaceChange.nThirdLine + 1
		elseif FaceChange.nSecondLine ~=  FaceChange.SecondCount() then
			FaceChange.nSecondLine = FaceChange.nSecondLine + 2
			if FaceChange.nFristLine == 4 then
				FaceChange.nThirdLine = 0
			else
				FaceChange.nThirdLine = 1
			end
			UINodeControl.TogTriggerByIndex("ScrollViewTab2",FaceChange.nSecondLine)
		elseif FaceChange.nFristLine ~= FaceChange.FristCount() then
			FaceChange.nFristLine = FaceChange.nFristLine + 1
			UINodeControl.TogTriggerByIndex("TogGroupPage",FaceChange.nFristLine)
			if FaceChange.nFristLine == 3 then
				FaceChange.nSecondLine = 10
				FaceChange.nThirdLine = 1
			elseif FaceChange.nFristLine == 4 then
				FaceChange.nSecondLine = 2
				nThirdLineClass= 1
				FaceChange.nThirdLine = 0
			else
				FaceChange.nSecondLine = 2
				nThirdLineClass= 1
				FaceChange.nThirdLine = 1
			end
			LoginFace.LeftStartTime = GetTickCount()
			return
		end
		-- 左边面板遍历
		-- LoginFace.LeftStartTime = GetTickCount()
		bDetailPanelRight = false
		-- 更新帧函数
		Timer.AddFrameCycle(FaceChange.Left,1,function () FaceChange.LeftFrameUpdate() end)
	end
end



-- 分为四种面板

-- 面容
FaceValueChange = {}
FaceValueChange.nCount = 0
FaceValueChange.nLine = 1

function FaceValueChange.GetCount()
	if FaceChange.nFristLine == 1 and FaceChange.nThirdLine == 2  then
		FaceValueChange.nCount = #UINodeControl.GetToggroup("TogGroupDefault")
	else
		-- 滑动参数
		FaceValueChange.nCount = FaceChange.GetSliderPercent()
	end
end
function FaceValueChange.Check()
	if FaceChange.nFristLine == 1 and FaceChange.nThirdLine == 2  then
		UINodeControl.TogTriggerByIndex("TogGroupDefault",FaceValueChange.nLine)
	else
		for i = 1, FaceValueChange.nCount do 
			UINodeControl.SliderSlidingInSec("SliderCount",i,1)
			FaceValueChange.nLine = FaceValueChange.nLine + 1
		end
		FaceValueChange.nLine = FaceValueChange.nLine - 1
		--UINodeControl.SliderSlidingInSec("SliderCount",FaceValueChange.nLine,1)
	end
end
-- 妆容 特殊部分  未写完
FaceMakeupChange = {}
FaceMakeupChange.nCount = 0
FaceMakeupChange.Line = 1
FaceMakeupChange.bFlag = false
function FaceMakeupChange.GetCount()
	-- 暂时写死
	-- FaceValueChange.nCount = #UINodeControl.GetToggroup("ScrollViewDetailAdjust")
	FaceValueChange.nCount = 2
end

function FaceMakeupChange.Check()
	UINodeControl.TogTriggerByIndex("ScrollViewDetailAdjust",FaceValueChange.nLine)
end


function FaceMakeupChange.GetColorCell()
	FaceMakeupChange.nCount = #UINodeControl.GetToggroup("TogGroupColorCell")
end
-- 颜色Tog
function FaceMakeupChange.FrameUpdate()
	if GetTickCount()-LoginFace.RightStartTime >= 1*1000 then
		if not FaceMakeupChange.bFlag then
			FaceMakeupChange.GetColorCell()
			FaceMakeupChange.bFlag = true
			return
		end
		if FaceMakeupChange.Line == FaceMakeupChange.nCount+1 then
			local nSliderCount = FaceChange.GetSliderPercent()
			bDetailPanelRight = true
			FaceMakeupChange.bFlag=false
			FaceMakeupChange.Line = 1
			LoginFace.LeftStartTime = GetTickCount()
			-- 同时调整滚动条
			for i = 1, nSliderCount do UINodeControl.SliderSlidingInSec("SliderCount",i,1) end
			Timer.DelAllTimer(FaceMakeupChange)
			return
		end
		UINodeControl.TogTriggerByIndex("TogGroupColorCell",FaceMakeupChange.Line)
		FaceMakeupChange.Line = FaceMakeupChange.Line + 1
		LoginFace.RightStartTime = GetTickCount()
	end
end


-- 发型
local FaceHairChange = {}
function FaceHairChange.GetCount()
	FaceValueChange.nCount = #UINodeControl.GetToggroup("ScrollViewDefault")
end

function FaceHairChange.Check()
	UINodeControl.TogTriggerByIndex("ScrollViewDefault",FaceValueChange.nLine)
end


-- 体型
local FaceBodyChange = {}
function FaceBodyChange.GetCount()
	if FaceChange.nFristLine == 4 and FaceChange.nSecondLine == 2 then
		-- 写死
		FaceValueChange.nCount = 14
		FaceValueChange.nLine = 5
	else
		-- 滑动参数
		FaceValueChange.nCount = FaceChange.GetSliderPercent()
	end
end

function FaceBodyChange.Check()
	if FaceChange.nFristLine == 4 and FaceChange.nSecondLine == 2  then
		UINodeControl.TogTriggerByIndex("ScrollViewDefault",FaceValueChange.nLine)
	else
		for i = 1, FaceValueChange.nCount do 
			UINodeControl.SliderSlidingInSec("SliderCount",i,1)
			FaceValueChange.nLine = FaceValueChange.nLine + 1
		end
		FaceValueChange.nLine = FaceValueChange.nLine - 1
	end
end

-- 左边面板封装
FaceChange.RightStatus = true
FaceChange.bCount= false
function FaceChange.LeftFrameUpdate()
	if FaceChange.RightStatus and GetTickCount()-LoginFace.RightStartTime >= LoginFace.RightNextTime*1000 then
		-- 赋值
		if not FaceChange.bCount then
			-- 不同赋值
			if FaceChange.nFristLine == 1 then
				FaceValueChange.GetCount()
			elseif FaceChange.nFristLine == 2 then
				FaceMakeupChange.GetCount()
			elseif FaceChange.nFristLine == 3 then
				FaceHairChange.GetCount()
			elseif FaceChange.nFristLine == 4 then
				FaceBodyChange.GetCount()
			end
			FaceChange.bCount = true
			LoginFace.RightStartTime = GetTickCount()
			return
		end
		if FaceValueChange.nCount+1 == FaceValueChange.nLine then
			if FaceChange.nFristLine == 2 then
				FaceValueChange.nCount = 0
				FaceValueChange.nLine = 1
				Timer.DelAllTimer(FaceChange.Left)
				FaceChange.bCount = false
				-- 启动颜色遍历
				Timer.AddFrameCycle(FaceMakeupChange,1,function () FaceMakeupChange.FrameUpdate() end)
				return
			else
				bDetailPanelRight = true
				FaceValueChange.nCount = 0
				FaceValueChange.nLine = 1
				Timer.DelAllTimer(FaceChange.Left)
				FaceChange.bCount = false
				LoginFace.LeftStartTime = GetTickCount()
				return
			end
		end
		if FaceChange.nFristLine == 1 then
			FaceValueChange.Check()
		elseif FaceChange.nFristLine == 2 then
			FaceMakeupChange.Check()
		elseif FaceChange.nFristLine == 3 then
			FaceHairChange.Check()
		elseif FaceChange.nFristLine == 4 then
			FaceBodyChange.Check()
		end
		FaceValueChange.nLine = FaceValueChange.nLine + 1
		LoginFace.RightStartTime = GetTickCount()
	end
end

-- 返回界面进行二次遍历
LoginRevert.nStartTime = 0
LoginRevert.nNextTime = 3
LoginRevert.bStatus = 1
function LoginRevert.FrameUpdate()
	if GetTickCount()-LoginRevert.nStartTime >= LoginRevert.nNextTime*1000 then
		if LoginRevert.bStatus ==3 then
			-- 结束帧更新函数
			Timer.DelAllTimer(LoginRevert)
			LoginRevert.bStatus = 1
			Timer.AddFrameCycle(LoginCreateRole,1,function ()
				LoginCreateRole.FrameUpdate()
			end)
			return
		end
		if LoginRevert.bStatus == 1 then
			UINodeControl.BtnTrigger("BtnClose","WidgetAnchorRightTop",3)
		else
			UINodeControl.BtnTrigger("BtnClose","WidgetAnchorRightTop",2)
		end
		LoginRevert.bStatus = LoginRevert.bStatus + 1
		LoginRevert.nStartTime = GetTickCount()
	end
end

-- 重置所有参数
function FaceChange.Reset()
	FaceMakeupChange.nCount = 0
	FaceMakeupChange.Line = 1
	FaceMakeupChange.bFlag = false
	-- 滑动条
	FaceChange.nSliderCount =0 -- 滑动条总数
	FaceChange.nSliderLine =1 -- 当前操作滑动条
	-- 颜色Tog
	FaceChange.nColorCount = 0 -- 颜色总数
	FaceChange.nColorLine =1 -- 当前操作颜色
	-- 一级目录
	FaceChange.nFristCount= 0
	FaceChange.nFristLine = 1
	-- 二级目录
	FaceChange.nSecondCount= 0
	FaceChange.nSecondLine = 2
	-- 三级目录
	FaceChange.nThirdCount= 0
	FaceChange.nThirdLine = 1
	-- 登录界面
	LoginCreateRole.bStart = false
	LoginCreateRole.nStatus = 1
	LoginCreateRole.bFrame = false
	-- 左边面板
	FaceChange.RightStatus = true
	FaceChange.bCount= false
	-- 右边面板
	bInitial = false
	bDetailPanelRight = true
	nThirdLineClass = 1
	-- 初始化
	Preset.bStart = false -- 初始化赋值
	Preset.FirstDirectory.bStatus = false
	Preset.SecondDirectory.bStart = false
	Preset.FirstDirectoryCount = 0
	Preset.SecondDirectoryCount = 0
	Preset.FirstDirectoryLine = 1
	Preset.SecondDirectoryLine = 1
end

-- cmd部分
local pCurrentTime = 0
local nNextTime=tonumber(30)
local nCurrentStep=1
local RunMap = {}
local list_RunMapCMD={}
local list_RunMapTime={}
--读取tab的内容
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szInterfacePath.."LoginFace/RunMap.tab",2)
list_RunMapCMD = tbRunMapData[1]
list_RunMapTime = tbRunMapData[2]
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
            bFlag=false
        end
		pCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1 
    end
end

Timer.AddFrameCycle(RunMap,1,function ()
	RunMap.FrameUpdate()
end)
