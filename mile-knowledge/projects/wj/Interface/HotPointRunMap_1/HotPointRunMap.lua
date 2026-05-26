LoginMgr.Log("HotPointRunMap","HotPointRunMap imported")
local HotPointRunMap={}
local list_RunMapTime = {}
local list_RunMapCMD = {}
local list_RunMapCMDInfo={}
local nNextTime=30
local nCurrentTime=GetTickCount()
local nCurrentStep=1
local bIsAutoFly=false
local bFlag = true
HotPointRunMap.bSwitch=true
SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."BeginRunMap")
SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."HotPoint_Start")
SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."HotPoint_End")
SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."ExitGame")
SearchPanel.RemoveFile(SearchPanel.szCurrentInterfacePath.."Data.json")   --移除存储数据文件

local szKey=nil
local bCanRecordPos=nil
local tbHotPointData={["performanceData"]={}}
local nRotationIndex=0
local list_CmdInfo=nil
local function GetPlayerInfo()
    local player=GetClientPlayer()
    --防止人物在斜坡上滑动 只记录第一次坐标
    if bCanRecordPos then
        szKey=string.format("(%s,%d,%s)",list_CmdInfo[1],player.nZ,list_CmdInfo[2])
        LOG.INFO(szKey)
        bCanRecordPos=false
        nRotationIndex=0
    end
    if not tbHotPointData.performanceData[szKey] then
        tbHotPointData.performanceData[szKey]={}
    end
    local fCameraToObjectEyeScale,fYaw ,fPitch = Camera_GetRTParams()
    local _, fMaxCameraDistance = Camera_GetParams()
    local trueCamereDistance = fMaxCameraDistance * fCameraToObjectEyeScale
    -- fCameraToObjectEyeScale 滚轮比例
    -- fYaw 水平角
    -- fPitch 俯仰角
    -- trueCamereDistance 实d:\VSCode\Microsoft VS Code Insiders\resources\app\out\vs\code\electron-sandbox\workbench\workbench.html际距离
    --local szCamerInfo=string.format("(%0.3f,%0.3f,%0.3f),",fCameraToObjectEyeScale,fYaw,fPitch)
    local szCamerInfo=string.format("(0.00, %0.2f, 0.00),",nRotationIndex*90)
    nRotationIndex=nRotationIndex+1
    local nSetPassCall=0    --setPassCall
    local nDrawcall = GetHotPointReader().GetFrameDataInfo().DrawCallCnt    --drawCall
    local nVertices=0    --顶点数
    local nTriangles=GetHotPointReader().GetFrameDataInfo().FaceCnt --面数
    local nMemory=0 --内存
    local fps=GetHotPointReader().GetFrameDataInfo().FPS    --FPS
    local ms=1000/fps-1000/fps%0.1  --帧耗时
    local szInfo=szCamerInfo..string.format("%d,%d,%d,%d,%d,%d,%0.1f",nSetPassCall,nDrawcall,nVertices,nTriangles,nMemory,fps,ms)
    --tbData.performanceData[szKey][n]=szInfo
    table.insert(tbHotPointData.performanceData[szKey],szInfo)
    LOG.INFO("PlayerInfp:"..szKey..":  "..szInfo)
end


local bHotPoint_End=false
local bCanGetData=false

--更新函数
local bFlag = true
local player=nil
local function FrameUpdate()
    if not HotPointRunMap.bSwitch then
        return
    end
    player=GetClientPlayer()
    if not player then
        return
    end
    if  bFlag and GetTickCount()-nCurrentTime> nNextTime*1000 then
        if nCurrentStep==#list_RunMapCMD then
            bFlag=false
        end
        local szCmd=list_RunMapCMD[nCurrentStep]
        LOG.INFO(szCmd)
        if bCanGetData then
           GetPlayerInfo()
        end
        pcall(function ()
            SearchPanel.RunCommand(szCmd)
        end)
        if string.find(szCmd,"player.SetPosition") then
            --保证人物处于静止状态
            SendGMCommand("player.Revive()")
            SendGMCommand("player.Stop()")
            bCanGetData=false
            bCanRecordPos=true
            list_CmdInfo=SearchPanel.StringSplit(list_RunMapCMDInfo[nCurrentStep],',')
        end
        if string.find(szCmd,"SetCameraStatus") then
            bCanGetData=true
        end
        nNextTime=tonumber(list_RunMapTime[nCurrentStep])
        nCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1
    end
    if bFlag and SearchPanel.RemoveFile(SearchPanel.szRunMapResultPath.."HotPoint_End") then
        local szRet=JsonEncode(tbHotPointData)
        local file=io.open(SearchPanel.szCurrentInterfacePath.."Data.json","w")
        file:write(szRet)
        file:close()
        LoginMgr.Log("HotPointRunMap",szRet)
    end
end


--加载tab文件
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",3)
list_RunMapCMD=tbRunMapData[1]
list_RunMapTime=tbRunMapData[2]
list_RunMapCMDInfo=tbRunMapData[3]
--启动帧更新函数

Timer.AddFrameCycle(HotPointRunMap,1,function ()
    FrameUpdate()
end)

LoginMgr.Log("HotPointRunMap","HotPointRunMap End")

return HotPointRunMap