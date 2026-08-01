SearchPanel={}
LoginMgr.Log("SearchPanel","SearchPanel imported")
SearchPanel.fileUtil = cc.FileUtils:getInstance()
SearchPanel.director = cc.Director:getInstance()
SearchPanel.szWorkPath=SearchPanel.fileUtil:getWritablePath()   --绝对工作路径
SearchPanel.szRunMapResultPath=SearchPanel.szWorkPath.."RunMapResult/"  --跑图结果文件夹
SearchPanel.szHotPointScreen=SearchPanel.szWorkPath.."HotPointScreen/"  --跑图结果文件夹
SearchPanel.szInterfacePath=SearchPanel.szWorkPath.."mui/Lua/Interface/"    --插件文件夹
SearchPanel.szInterfaceAutoLogiPath=SearchPanel.szInterfacePath.."AutoLogin/"    --插件AutoLogin文件夹
SearchPanel.szInterfaceGetPerfDataPath=SearchPanel.szInterfacePath.."GetPerfData/"    --插件GetPerfData文件夹
SearchPanel.szInterSearchPanelDataPath=SearchPanel.szInterfacePath.."SearchPanel/"  --主插件SearchPanel文件夹路径
local iniFile = Ini.Open(SearchPanel.szInterSearchPanelDataPath.."Interface.ini")  --插件配置文件
SearchPanel.szInterfaceType=iniFile:ReadString("Interface", "Type", "")          --插件类型
local szSwitch=iniFile:ReadString("Interface", "Switch", "")       --SeachPanel开关
SearchPanel.szCurrentInterfacePath=SearchPanel.szInterfacePath..SearchPanel.szInterfaceType..'/'     --当前运行跑图插件路径
SearchPanel.nSwitch= tonumber(szSwitch)

SearchPanel.tbModule={}
SearchPanel.bPerfeye_Start=false
SearchPanel.bPerfeye_Stop=false
SearchPanel.PSM={} --省电模式帧率限制
SearchPanel.PSM.nFPS=nil
SearchPanel.PSM.bSwitch=true
function SearchPanel.PSMSetSwitch(bOption)
    -- body
    SearchPanel.PSM.bSwitch=false
end

function SearchPanel.SetPSMFPS(nFps)
    -- body
    SearchPanel.PSM.nFPS=nFps
end

--LoginMgr.Log("SearchPanel",SearchPanel.szWorkPath)
--LoginMgr.Log("SearchPanel",SearchPanel.szRunMapResultPath)
--LoginMgr.Log("SearchPanel",SearchPanel.szInterfacePath)
--LoginMgr.Log("SearchPanel",SearchPanel.szInterfacePublicPath)
--LoginMgr.Log("SearchPanel",SearchPanel.szInterfaceType)
--LoginMgr.Log("SearchPanel",SearchPanel.szCurrentInterfacePath)

local function SetPath(szFilePath)
    SearchPanel.szRunMapResultPath=szFilePath.."RunMapResult/"  --跑图结果文件夹
    SearchPanel.szInterfacePath=szFilePath.."mui/Lua/Interface/"    --插件文件夹
    SearchPanel.szInterfaceAutoLogiPath=SearchPanel.szInterfacePath.."AutoLogin/"    --插件AutoLogin文件夹
    SearchPanel.szInterfaceGetPerfDataPath=SearchPanel.szInterfacePath.."GetPerfData/"    --插件GetPerfData文件夹
    SearchPanel.szInterSearchPanelDataPath=SearchPanel.szInterfacePath.."SearchPanel/"  --主插件SearchPanel文件夹路径
    SearchPanel.szCurrentInterfacePath=SearchPanel.szInterfacePath..SearchPanel.szInterfaceType..'/'     --当前运行跑图插件路径
end

--加载插件脚本函数  加载脚本用相对路径  加载文件用绝对路径
local function LoadInterfaceScript()
    local szInterfacePath="mui/Lua/Interface/"
    if SearchPanel.szInterfaceType=="" then
        LoginMgr.Log("SearchPanel","Please Set RunMap Model")
        return
    end

    --加载公共库插件
    local tbTool={"UINodeControl","BaseState","AutoTestLog"}
    for _,szInterface in pairs(tbTool) do
        require(szInterfacePath..'SearchPanel/'..szInterface..'.lua')
    end
    local szDependencyInterface=iniFile:ReadString("Interface",SearchPanel.szInterfaceType, "")    --读取主插件的辅助插件
    if not szDependencyInterface then
        LoginMgr.Log("SearchPanel","Please set DependencyInterface")
    elseif szDependencyInterface=='nil' then
        LoginMgr.Log("SearchPanel","DependencyInterface nil")
    else
        local list_interface=SearchPanel.StringSplit(szDependencyInterface,',')
        for _,szInterface in pairs(list_interface) do
            SearchPanel.tbModule[szInterface]=require(szInterfacePath..szInterface..'/'..szInterface..'.lua')     --加载辅助插件
        end
    end
    iniFile:Close()
     --加载主插件
    SearchPanel.tbModule[SearchPanel.szInterfaceType]=require(szInterfacePath..SearchPanel.szInterfaceType..'/'..SearchPanel.szInterfaceType..'.lua')

    LoginMgr.Log("SearchPanel","RunMap Model:"..SearchPanel.szInterfaceType)
    --省电模式间隔时间设置
    --Const.AFKDurationTime=30000
    --关闭省电模式
    --Global.SetForbidAFKMode(true)
    --禁用新手教程
    --TeachEvent.CloseAllTeach()
    --TeachEvent.bEnabled=false
    FrameMgr.StopDynamicFps()
    PSMMgr.StopTick()
    Timer.AddCycle(SearchPanel.PSM,1,function ()
        PSMMgr.RecordTouchTimer()
        --[[
        if SearchPanel.PSM.nFPS~=nil then
            FrameMgr.nFpsLimit=SearchPanel.PSM.nFPS
        end]]
    end)
    Timer.AddFrameCycle(SearchPanel.PSM,1,function ()
        if SearchPanel.PSM.nFPS~=nil then
            App_SetFrameLimitCount(SearchPanel.PSM.nFPS)
        end
    end)
    -- 转为wifi模式 1  WIFI, 2 蜂窝
    PakDownloadMgr.nTestNetMode = 1
    --获取版本号
    SearchPanel.CreateVersion()
end

--关闭温控
SearchPanel.bDynamicFpsSwitch=false
if not SearchPanel.bDynamicFpsSwitch then
    --先关闭 然后防止再次开启
    FrameMgr.StopDynamicFps()
    local _StartDynamicFpsOption = FrameMgr.StartDynamicFps
    function StartDynamicFpsOption()
        return 
    end
    FrameMgr.StartDynamicFps=StartDynamicFpsOption
end

-- 获取安装包版本号文件
function SearchPanel.GetCodeVer()
    local tbCode = {}
    table.insert(tbCode,GetVersionName())
    table.insert(tbCode,GetVersionCode())
    return tbCode
end

-- 获取资源包版本号文件
function SearchPanel.GetResourceVer()
    return GetPakV5Version()
end

-- 创建资源包和安装包版本号文件
function SearchPanel.CreateVersion()
    local szVersionPath = SearchPanel.szRunMapResultPath.."version.ini"
    local iniVersion = Ini.Open(szVersionPath, true)
    if not iniVersion then
        iniVersion = Ini.Create()
        if not iniVersion then
            -- 创建文件失败
            LOG.INFO("Error Create file")
            return
        end
    end
    iniVersion:WriteInteger("Version", "CodeVer",SearchPanel.GetCodeVer()[2])
    iniVersion:WriteInteger("Version", "ResourceVer", SearchPanel.GetResourceVer())
    iniVersion:Save(szVersionPath)
    iniVersion:Close()
    LOG.INFO("File written successfully")
end

--获取插件
function SearchPanel.GetModule(szInterface)
    return SearchPanel.tbModule[szInterface]
end

----cmd 函数定义
--设置摄像机视角
function SetCameraStatus(fMaxCameraDistance, fCameraToObjectEyeScale, fYaw, fPitch)
	local fDragSpeed, _, fSpringResetSpeed, fCameraResetSpeed, nResetMode = Camera_GetParams()
	Camera_SetParams(fDragSpeed, fMaxCameraDistance, fSpringResetSpeed, fCameraResetSpeed, nResetMode)
	Camera_SetRTParams(fCameraToObjectEyeScale, fYaw, fPitch)
end

--生成随机字符串
function RandomString(nLength)
	math.randomseed(os.time())
    local strChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local strResult = ""
    for _=1, nLength do
        local nIndex = math.random(1, #strChars)
        strResult = strResult .. string.sub(strChars, nIndex, nIndex)
    end
    return strResult
end

--创建文件
function CreateEmptyFile(szFilename)
    local file = io.open(SearchPanel.szRunMapResultPath..szFilename, "w")
    file:close()
end

--创建热力图截图文件
function CreateEmptyFileHotPointScreen(szFilename)
    local file = io.open(SearchPanel.szHotPointScreen..szFilename, "w")
    file:close()
end


--根据当前日期创建文件
function WriteRunMapResult(testpoint, mapid)
    local current_time = os.time()
    local H = tonumber(os.date("%H"))
    if H >= 0 and H < 7 then    
        current_time = current_time - 86400
    end
    local today = os.date("%Y-%m-%d", current_time)
    local szFilename = mapid .. "_" .. testpoint .. "_" ..today
    SearchPanel.fileUtil:createDirectory(SearchPanel.szRunMapResultPath.."/" .. today)
    local file = io.open(SearchPanel.szRunMapResultPath.."/" .. today .. '/' .. szFilename, "w")
    file:close()
end

----公共函数定义

--插件开关
function SearchPanel.Switch(nSwitch)
    local bSwitch=true
    if nSwitch==0 then
        bSwitch=false
    end
    LoginMgr.Log("SearchPanel","test--"..type(SearchPanel.tbModule[SearchPanel.szInterfaceType]))
    for _,module in pairs(SearchPanel.tbModule) do
        module.bSwitch=bSwitch
    end
end


--随机返回表中的键
function SearchPanel.GetRandomKeyInTable(tb)
	local tbKey={}
	local nIndex=1
	for szKey in pairs(tb) do
		tbKey[nIndex]=szKey
		nIndex=nIndex+1
	end
	math.randomseed(os.time())
	return tbKey[math.random(1,nIndex-1)]
end

--判断文件是否存在
function SearchPanel.IsFileExist(szFilePath)
    local file=io.open(szFilePath,'r')
    if file then
        file:close()
        return true
    end
    return false
end

--移除文件
function SearchPanel.RemoveFile(szFilePath)
    --print("Remove--"..szFilePath)
    if SearchPanel.IsFileExist(szFilePath) then
        os.remove(szFilePath)
        return true
    end
    return false
end

--创建目录
function SearchPanel.CreateDirectory(szDirPath)
    if szDirPath and szDirPath ~= "" and not SearchPanel.fileUtil:isDirectoryExist(szDirPath) then
        SearchPanel.fileUtil:createDirectory(szDirPath)
    end
end


--字符串分割
function SearchPanel.StringSplit(str,splitchar)
    str=str..splitchar
    local resultStrList = {}
	for s in (str):gmatch("(.-)"..splitchar) do
		table.insert(resultStrList,s)
	end
    return resultStrList
end

--保留小数点后位数
function ReserveDecimalPlaces(fNumber,nDecimal)
	-- body
	szFormat=string.format("%." .. nDecimal .. "f",fNumber)
	print(szFormat)
	return tonumber(szFormat)
end

--加载tab文件   参数1：路径   参数2：获取表中几列数据  返回值：二维数组2*nDataLen  去除了表头
function SearchPanel.LoadRunMapFile(szFilePath,nDataLen)
    local tbData={}
    for i=1,nDataLen do
        table.insert(tbData,{})
    end
    if not SearchPanel.fileUtil:isFileExist(szFilePath) then
        LoginMgr.Log("SearchPanel","LoadRunMapFile: file not found "..tostring(szFilePath))
        return tbData
    end
    for szLine in io.lines(szFilePath) do
        szLine=GBKToUTF8(szLine)
        local list_Line=SearchPanel.StringSplit(szLine,'\t')
        for i=1,nDataLen do
            if list_Line[i] then
                table.insert(tbData[i],list_Line[i])
            else
                table.insert(tbData[i],-1)
            end
        end
    end
    for i=1,nDataLen do
        table.remove(tbData[i],1)
    end
    io.close()
    return tbData
end

--执行脚本命令
function SearchPanel.MyExecuteScriptCommand(szScript)
    szScript='return '..szScript
    local fun = loadstring(szScript)
    setfenv(fun, _G)
    if fun then
        local bStatus,result= xpcall(fun, _MsgError)
        if bStatus then
            return result
        else
            return false
        end
    else
        return false
    end
end

--执行命令
function SearchPanel.RunCommand(szCMD)
    if type(szCMD) ~= "string" then
        LoginMgr.Log("SeachPanel","CMD Error:[%s]",szCMD)
        return
    end
    if szCMD:sub(1, 4) == "/gm " then
        SendGMCommand(szCMD:sub(5, -1))
    elseif szCMD:sub(1, 5) == "/cmd " then
        return SearchPanel.MyExecuteScriptCommand(szCMD:sub(6, -1))
    else
        LOG.INFO(szCMD..' Error')
    end
end

-- 调用func后是否打开了某个界面,可以填写多个面板,如果没有反复调用func
SearchPanel.tbEnterPanelByTrigger={}
SearchPanel.tbEnterPanelByTrigger.bPanelExit=false  --面板是否已经打开
SearchPanel.tbEnterPanelByTrigger.bSwitch=false --避免使用者重复调用
SearchPanel.tbEnterPanelByTrigger.args={}
function SearchPanel.IsEnterPanelByTrigger(func,nCycleTime,...)
    --重置状态
    --开关打开表明正在使用当中 防止反复调用
    if SearchPanel.tbEnterPanelByTrigger.bSwitch then
        return
    end
    if not nCycleTime or nCycleTime<=0 then
        nCycleTime=2
    end
    SearchPanel.tbEnterPanelByTrigger.bSwitch=true
    SearchPanel.tbEnterPanelByTrigger.bPanelExit=false
    SearchPanel.tbEnterPanelByTrigger.args={...}
    if not func then
        return false
    end
    Timer.AddCycle(SearchPanel.tbEnterPanelByTrigger,nCycleTime,function ()
        local bOpened=false
        for _,nViewId in ipairs(SearchPanel.tbEnterPanelByTrigger.args) do
            if UIMgr.IsViewOpened(nViewId,true) then
                bOpened=true
                break
            end
        end
        if bOpened then
            SearchPanel.tbEnterPanelByTrigger.bPanelExit=true
            SearchPanel.tbEnterPanelByTrigger.bSwitch=false
            Timer.DelAllTimer(SearchPanel.tbEnterPanelByTrigger)
        else
            xpcall(func, _MsgError)
        end
    end)
    return true
end

local bTeachClose = false
-- 是否从地图加载界面进入了游戏
function SearchPanel.IsFromLoadingEnterGame()
    local player = GetClientPlayer()
    if player then
        local bOpened =  UIMgr.IsViewOpened(VIEW_ID.PanelLoading) or UIMgr.IsViewOpened(VIEW_ID.PanelVideoPlayer)  -- 是否存在加载界面
        if not bOpened then
            if UIMgr.IsViewOpened(VIEW_ID.PanelHintSelectMode) then
                UIMgr.Close(VIEW_ID.PanelHintSelectMode)
            end
            if not bTeachClose then
                TeachEvent.CloseAllTeach()
                TeachEvent.bEnabled=false
                bTeachClose = true
            end
            return true
        end
        bTeachClose=false
        return false
    end
    return false
end

-- 处理视频加载出错的弹窗
local VideoFailed = {}
local nVideoFailedNextTime = 240   -- 大于4分钟 没出现关闭函数
local nVideoFailedStartTime = 0
function VideoFailed.FrameUpdate()
    if UIMgr.IsViewOpened(VIEW_ID.PanelNormalConfirmation) or GetTickCount()-nVideoFailedStartTime >= nVideoFailedNextTime*1000 then
        UINodeControl.BtnTrigger("BtnOk")
        Timer.DelAllTimer(VideoFailed)
    end
    nVideoFailedStartTime = GetTickCount()
end
--[[Timer.AddCycle(VideoFailed,1,function ()
    VideoFailed.FrameUpdate()
end)]]

--延时调用装饰器 执行回调函数一次
DelayTimer = function(callback, time)
    local handle
    handle = SearchPanel.director:getScheduler():scheduleScriptFunc(function()
        SearchPanel.director:getScheduler():unscheduleScriptEntry(handle)
        callback()
    end, time, false)
    return handle
end


--秒更新处理未知弹窗
SearchPanel.tbTips={}
SearchPanel.tbTips.tips={
    VIEW_ID.PanelNormalConfirmation,
    VIEW_ID.PanelQingGongModePop,
    VIEW_ID.PanelBattleFieldRulesLittle,
    VIEW_ID.PanelTeach,
    VIEW_ID.PanelDungeonDetail,
    VIEW_ID.PanelTutorialLite
}


function SearchPanel.DealWithTips()
    for nIndex,tip in ipairs(SearchPanel.tbTips.tips) do
        if UIMgr.IsViewOpened(tip) then
            if tip == VIEW_ID.PanelNormalConfirmation then
                UINodeControl.BtnTrigger("BtnOk")
            else
                UIMgr.Close(tip)
            end
        end
    end
end
--Timer.AddCycle(SearchPanel.tbTips,1,SearchPanel.DealWithTips)

-- 处理一直弹出的弹窗
SearchPanel.tbRepeatTips={}
SearchPanel.tbRepeatTips.bSwitch=true
SearchPanel.tbRepeatTips.tips={
    VIEW_ID.PanelSystemConfirm,
    VIEW_ID.PanelSpecialDiscountPop,
    VIEW_ID.Panel130NightPop,
    VIEW_ID.PanelRevivePop,
    VIEW_ID.PanelNewLevelMap,
    VIEW_ID.PanelSkillRecommend,
    VIEW_ID.PanelHintTop
}

function SearchPanel.DelRepeatTips()
    if not SearchPanel.tbRepeatTips.bSwitch then
        return
    end
    for _,tip in ipairs(SearchPanel.tbRepeatTips.tips) do
        if UIMgr.IsViewOpened(tip) then
            UIMgr.Close(tip)
        end
    end
end
Timer.AddCycle(SearchPanel.tbRepeatTips, 1, function ()
    SearchPanel.DelRepeatTips()
end)

function SearchPanel.DelRepeatTipsSwitch(bSwitch)
    -- body
    SearchPanel.tbRepeatTips.bSwitch=bSwitch
end

--自动向前走开始
function MoveForWard_Start()
    SkillMgr.AutoRun(true)
end

--自动向前走停止
function MoveForWard_Stop()
    SkillMgr.AutoRun(false)
end

-- 自动寻路模块相关功能
AutoRoadWay = {}
-- 开启自动寻路
function AutoRoadWay.Start(nX,nY,nZ)
    local player = GetClientPlayer()
    if not player then
        return
    end
    local nMapID = player.GetMapID()
    -- 添加无限气力值buff
    SearchPanel.RunCommand("/gm player.AddBuff(0,99,8665,1,7200)")
    AutoNav.NavTo(nMapID, nX, nY, nZ)
end

-- 关闭自动寻路
function AutoRoadWay.Stop()
    AutoNav.StopNav()
end

-- 是否在自动寻路
function AutoRoadWay.IsRun()
    local player = GetClientPlayer()
    if not player then
        return
    end
    return player.bInNav
end

-- 镜头拉远拉近
tbCameraZoom = {}
tbCameraZoom.nMax = 1.09
tbCameraZoom.nMin = -1
tbCameraZoom.nLine = 1.09
tbCameraZoom.nSpeed = 0.02
function tbCameraZoom.FrameUpdate()
    CameraMgr.Zoom(tbCameraZoom.nLine)
    if tbCameraZoom.nLine >=  tbCameraZoom.nMax or tbCameraZoom.nLine <=  tbCameraZoom.nMin then
        tbCameraZoom.nSpeed = -tbCameraZoom.nSpeed
    end
    tbCameraZoom.nLine = tbCameraZoom.nLine + tbCameraZoom.nSpeed
end

-- 启动镜头拉远拉近
function SearchPanel.CameraZoomStart()
    Timer.AddFrameCycle(tbCameraZoom, 1, function ()
        tbCameraZoom.FrameUpdate()
    end)
end

function SearchPanel.CameraZoomStop()
    Timer.DelAllTimer(tbCameraZoom)
end

--增加一个镜头旋转的命令
tbCircle={}
tbCircle.fStartIndex=2.2
tbCircle.fEndIndex=8.4
tbCircle.nIndex=tbCircle.fStartIndex
tbCircle.fStep=tbCircle.fEndIndex-tbCircle.fStartIndex
tbCircle.fStep=-tbCircle.fStep/150 --90帧限制
tbCircle.nAngle = 1083
function tbCircle.SetAngle(nAngleCount)
    tbCircle.nAngle = tonumber(nAngleCount)
end
function tbCircle.FrameUpdate()
    if tbCircle.nIndex>=tbCircle.fEndIndex or tbCircle.nIndex<=tbCircle.fStartIndex then
        tbCircle.fStep=-tbCircle.fStep
    end
    SetCameraStatus(tbCircle.nAngle,1,tbCircle.nIndex,-0.1369)
    tbCircle.nIndex=tbCircle.nIndex+tbCircle.fStep
end

function SearchPanel.CircleStart()
    -- body
    Timer.AddFrameCycle(tbCircle, 1, function ()
        tbCircle.FrameUpdate()
    end)
end

function SearchPanel.CircleStop()
    Timer.DelAllTimer(tbCircle)
end

--增加一个切画质的命令
--切画质选项
tbVideoSwitch={}
-- 4档画质
tbVideoSwitch.list_Video={}
tbVideoSwitch.nSetpTime=5
tbVideoSwitch.nSwitchIndex=1
tbVideoSwitch.nTimer=0
function tbVideoSwitch.SwitchVideo()
    if GetTickCount()-tbVideoSwitch.nTimer>tbVideoSwitch.nSetpTime*1000 then
        tbVideoSwitch.nTimer=GetTickCount()
        if SearchPanel.CheckDevicesQuality(tbVideoSwitch.nSwitchIndex) then
            QualityMgr.SetQualityByType(tbVideoSwitch.nSwitchIndex)
        end
        tbVideoSwitch.nSwitchIndex=tbVideoSwitch.nSwitchIndex+1
        if tbVideoSwitch.nSwitchIndex==#tbVideoSwitch.list_Video+1 then
            tbVideoSwitch.nSwitchIndex=1
        end
    end
end

function SearchPanel.VideoSwitchStart()
    -- 画质赋值
    tbVideoSwitch.list_Video = SearchPanel.GetDevicesOptionList()
    -- body
    Timer.AddFrameCycle(tbVideoSwitch, 1, function ()
        tbVideoSwitch.SwitchVideo()
    end)
end

function SearchPanel.VideoSwitchStop()
    Timer.DelAllTimer(tbVideoSwitch)
end


--增加一个不停jump的命令
tbJumpSwitch={}
tbJumpSwitch.nSetpTime=4
tbJumpSwitch.nSwitchIndex=1
tbJumpSwitch.nTimer=0
function tbJumpSwitch.SwitchJump()
    if GetTickCount()-tbJumpSwitch.nTimer>tbJumpSwitch.nSetpTime*1000 then
        tbJumpSwitch.nTimer=GetTickCount()
        if tbJumpSwitch.nSwitchIndex==1 then
            Jump()
            tbJumpSwitch.nSwitchIndex=2
        else
            Jump()
            Jump()
            tbJumpSwitch.nSwitchIndex=1
        end
    end
end

function SearchPanel.JumpSwitchStart()
    Timer.AddFrameCycle(tbJumpSwitch, 1, function ()
        tbJumpSwitch.SwitchJump()
    end)
end

function SearchPanel.JumpSwitchStop()
    Timer.DelAllTimer(tbJumpSwitch)
end

--加载插件脚本  创建RunMapResult文件夹
if SearchPanel.nSwitch==1 then
    SearchPanel.CreateDirectory(SearchPanel.szWorkPath.."RunMapResult")
    SearchPanel.CreateDirectory(SearchPanel.szWorkPath.."HotPointScreen")
    LoadInterfaceScript()
end

-- GM面板资源下载
SearchPanel.GM = {}
function SearchPanel.GM.download()
    if not UINodeControl then
        Timer.DelAllTimer(SearchPanel.GM)
        return
    end
    -- 是否存在这个按钮
    local bPanelGMBall = UIMgr.IsViewOpened(VIEW_ID.PanelGMBall)
    -- 存在 点击一次结束
    if bPanelGMBall then
        -- 触发一次后并关闭
        UINodeControl.BtnTrigger("BtnGm")
        -- 如果有GM面板则关掉
        if UIMgr.IsViewOpened(VIEW_ID.PanelGM) then
            UIMgr.Close(VIEW_ID.PanelGM)
            Timer.DelAllTimer(SearchPanel.GM)
        end
    end
end
--下载GM
function SearchPanel.DownloadGM()
    Timer.AddCycle(SearchPanel.GM, 3, function ()
        SearchPanel.GM.download()
    end)
end
SearchPanel.DownloadGM()

TbSwitchMap = {}
TbSwitchMap.IsRun = false
local nMapId,nDw,nX,nY,nZ -- 初始化参数
local nSwitchCount = 1 -- 记录传送的次数
-- 检查是否到达地图
function TbSwitchMap.SwitchMapFrameUpdate()
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    if nMapId == GetClientPlayer().GetMapID() then
        -- 结束并重置传送的次数
        Timer.DelAllTimer(TbSwitchMap)
        TbSwitchMap.IsRun = false
        SwitchCount = 1
    else
        -- 重试3次后无法传送到地图 结束自动化
        if nSwitchCount == 3 then
            -- 结束帧函数创建一个文件
            CreateEmptyFile("Error_EnterMap")
            Timer.DelAllTimer(TbSwitchMap)
            return
        end
        SendGMCommand(string.format("player.SwitchMap(%d,%d,%d,%d,%d)", nMapId,nDw,nX,nY,nZ))
        SwitchCount = SwitchCount + 1
    end
end

-- 暂时用在副本位置的 地图传送接口
-- 地图id 地图x坐标 地图y坐标 地图z坐标
function SearchPanel.PlayerSwitchMap(mapId,ndwID,nMapX,nMapY,nMapZ)
    -- 传送地图
    SendGMCommand(string.format("player.SwitchMap(%d,%d,%d,%d,%d)", mapId,ndwID,nMapX,nMapY,nMapZ))
    -- 记录参数
    nMapId = mapId
    nDw = ndwID
    nX = nMapX
    nY = nMapY
    nZ = nMapZ
    -- 启动检测接口
    Timer.AddCycle(TbSwitchMap,5, function ()
        TbSwitchMap.SwitchMapFrameUpdate()
    end)
    TbSwitchMap.IsRun = true
end

-- 动画播放20秒
-- 用于新账号开头动画播放的20秒
local PlayerVedio = {}
PlayerVedio.nVedioNextTime = 20 -- 动画播放秒数
PlayerVedio.nVedioStratTime = 0 -- 动画播放秒数
PlayerVedio.bvedioStrat = false -- 是否启用动画
function PlayerVedio.FrameUpdate()
    -- 在动画开始前记录时间
    if not PlayerVedio.bvedioStrat then
        if UIMgr.IsViewOpened(VIEW_ID.PanelVideoPlayer) then
            PlayerVedio.nVedioStratTime = GetTickCount()
            PlayerVedio.bvedioStrat = true
        end
        return
    end
    -- 等待20秒后关闭动画
    if GetTickCount()-PlayerVedio.nVedioStratTime >= PlayerVedio.nVedioNextTime*1000 then
        UIMgr.Close(VIEW_ID.PanelVideoPlayer)
        Timer.DelAllTimer(PlayerVedio)
    end
end

Timer.AddCycle(PlayerVedio,1,function ()
    PlayerVedio.FrameUpdate()
end)


--登录界面写标志
local tbLoginPanel = {}
Timer.AddCycle(tbLoginPanel,1,function ()
    if UIMgr.IsViewOpened(VIEW_ID.PanelLogin) then
        CreateEmptyFile('AutoLoginPanel')
        Timer.DelAllTimer(tbLoginPanel)
    end
end)

-- 设置同屏人数
-- 例如 SearchPanel.SetCustomOptions("同屏玩家数",0) 能控同屏玩家数和npc
function SearchPanel.SetCustomOptions(szColumn,szColumnCount)
    local nColumnCount = tonumber(szColumnCount)
    SetGameSetting(SettingCategory.Quality, QUALITY.RENDER_EFFICIENCY, szColumn, nColumnCount)
    QualityMgr.ApplySetting()
    QualityMgr.UpdateQuality()
end

-- 同屏特效数
function SearchPanel.SetSFXLimitOptions(nColumnCount)
    QualityMgr.ModifyCurQuality("nClientSFXLimit", tonumber(nColumnCount), false)
    QualityMgr.ModifyCurQuality("nClientUnderWaterSFXLimit", tonumber(nColumnCount), true)
    Event.Dispatch(EventType.OnQualitySettingChange)
end



-- 其他玩家特效数
function SearchPanel.SetPlaySFXLimitOptions(nColumnCount)
    QualityMgr.ModifyCurQuality("nClientOtherPlaySFXLimit",tonumber(nColumnCount), false)
    Event.Dispatch(EventType.OnQualitySettingChange)
end



-- 获取默认画质的接口
function SearchPanel.GetDefaultQuality()
    for key, value in pairs(tbVideoSwitch.list_Video) do
        if QualityMgr.GetRecommendQualityType() == key then
            return value
        end
    end
end


SearchPanel.Timing = {}
-- 公共的 定时传送
function SearchPanel.Timing.SettimingMap(nTimingX,nTimingY,nTimingZ)
    local player=GetClientPlayer()
    if (player.nX+player.nY+player.nZ) ~= (nTimingX+nTimingY+nTimingZ) then
        -- 传送回原来的坐标
        SearchPanel.RunCommand("/gm player.SetPosition("..nTimingX..","..nTimingY..","..nTimingZ..")")
    end
end

function SearchPanel.StartTimingMap(nSetX,nSetY,nSetZ)
    Timer.AddCycle(SearchPanel.Timing,4,function ()
        SearchPanel.Timing.SettimingMap(tonumber(nSetX),tonumber(nSetY),tonumber(nSetZ))
    end)
end

-- 超分接口
function SearchPanel.SetSuperResolution(szSuperResolutionCount)
    local nColumnCount = tonumber(szSuperResolutionCount)
    local szSuperResolution
    local tbSuperResolution ={
        GameSettingType.SuperResolution.None, -- 关闭超分
        GameSettingType.SuperResolution.FSRMode, -- FSR
        GameSettingType.SuperResolution.FSRPerformanceMode,  -- FSR性能版
        GameSettingType.SuperResolution.QualityMode, -- GSR
        GameSettingType.SuperResolution.PerformanceMode -- GSR性能版
    }
    szSuperResolution = tbSuperResolution[nColumnCount]
    SetGameSetting(SettingCategory.Quality, QUALITY.RENDER_EFFICIENCY,"超分",szSuperResolution)
    QualityMgr.UpdateSuperResolution()
end

--武学助手自动开启
function SearchPanel.Startfight()
    local nIntervalTime = 0.155
    Timer.AddCycle(AutoBattle, nIntervalTime, AutoBattle.CastSkillCycle)
    -- 切换状态后攻击下才能触发
    SprintData.ToggleViewState();local nSkillID = UIBattleSkillSlot.GetShowUI_Ver2(1);OnUseSkill(nSkillID, 1)
end

-- 获取设备对应的画质
function SearchPanel.GetDevicesOptionList()
    local tbDevicesOptionList ={}
    -- 此处去除掉自定义画质
    for _, quality in pairs(QualityMgr.GetSettingOptionList()) do
        if quality ~= GameQualityType.CUSTOM  then
            table.insert(tbDevicesOptionList,quality)
        end
    end
    return tbDevicesOptionList
end

-- 此处根据项目脚本进行检测和设置 以后变动可参考UIGameSettingView.lua文件
-- 检测是否可以切当前画质
function SearchPanel.CheckDevicesQuality(nGameQualityType)
    local nQualityType = nGameQualityType
    local bResult = true
    -- 机型是否可以切画质
    if not QualityMgr.CanSwitchQuality() then
        bResult = false
    end
    -- 副本内限制
    if Device.IsUnderIOS15() and DungeonData.IsInDungeon() then
        bResult = false
    end
    -- 蓝光限制
    if nQualityType == GameQualityType.BLUE_RAY and not QualityMgr.CanShowBlueRay() then
        bResult = false
    end

    -- 手机 ios4G用户不能切到极致画质
    if Platform.IsIos() then
        if nQualityType == GameQualityType.EXTREME_HIGH then
            if Device.GetDeviceTotalMemorySize(true) < 4.1 then
                bResult = false
            end
        end
    end

    -- PC 的 2G显存以下机器，只能最简画质，不让切其他画质
    if Platform.IsWindows() then
        if Device.IsWinGPUMemoryGBLowUnder2GB() then
            bResult = false
        end
    end
    return bResult
end


-- 临时接口
Temporary ={}
local tbSkill ={"player.CastSkill(43891,1)","player.CastSkill(43892,1)",}
local nSkillLine = 1
function Temporary.FrameUpdate()
    if nSkillLine == 1 then
        SearchPanel.RunCommand("/gm "..tbSkill[nSkillLine])
        nSkillLine = 2
    elseif nSkillLine == 2 then
        SearchPanel.RunCommand("/gm "..tbSkill[nSkillLine])
        nSkillLine = 1
    end
end


function Temporary.Start()
    Timer.AddCycle(Temporary,5,function ()
        Temporary.FrameUpdate()
    end)
end


function Temporary.Stop()
    Timer.DelAllTimer(Temporary)
end


LoginMgr.Log("SearchPanel","SearchPanel End")