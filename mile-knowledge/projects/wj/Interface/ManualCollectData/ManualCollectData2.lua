LoginMgr.Log("GetPerfData","GetPerfData import")
local GetPerfData={}
GetPerfData.bSwitch=true    --采集数据开关 
local szDataFilePath=SearchPanel.szCurrentInterfacePath.."Data.json"
SearchPanel.RemoveFile(szDataFilePath)  --移除存储数据文件
local tbPerfData={["datalist"]={}}
local nNum=1
local nCounter=0
local bStartPerf=false
local bEndPerf=false
local bStart=false
local bEnd=false

local function CalculateAvg(list_data)
    local nSum=0
    for _,v in pairs(list_data) do
        nSum=nSum+v
    end
    return nSum/#list_data-nSum/#list_data%0.1
end

local list_Fps={}
local list_FrameTime={}
local list_Drawcall={}
local list_DrawTriangles={}

local function Update()
    --[[]]
    if not GetPerfData.bSwitch then
        return
    end
    nCounter=nCounter+1
    if not bStartPerf and SearchPanel.bPerfeye_Start then
        LoginMgr.Log("GetPerfData","perfeye_start")
        bStartPerf=true
        bStart=true
    end
    if not bEndPerf and SearchPanel.bPerfeye_Stop then
        LoginMgr.Log("GetPerfData","perfeye_stop")
        bEndPerf=true
        bEnd=true
    end
    if nCounter ~=10 then
        return
    else
        nCounter=0
        if bStart then
            if bEnd then
                bStart=false
                bEnd=false
                LoginMgr.Log("GetPerfData","DataSave--Start")
                local szRet=JsonEncode(tbPerfData)
                local file=io.open(szDataFilePath,"w")
                file:write(szRet)
                file:close()
                LoginMgr.Log("GetPerfData","DataSave--End")
            else
                local tbDataValue={}
                tbDataValue["Num"]=nNum
                tbDataValue["absTime"]=(os.time()+1)*1000
                tbDataValue["FPS"]=CalculateAvg(list_Fps)
                tbDataValue["Drawcall"]=math.ceil(CalculateAvg(list_Drawcall))
                tbDataValue["DrawTriangles"]=math.ceil(CalculateAvg(list_DrawTriangles))
                list_Fps={}
                list_Drawcall={}
                list_DrawTriangles={}
                table.insert(tbPerfData.datalist,tbDataValue)
                nNum=nNum+1
            end
        end
    end
end

--[[]]
SearchPanel.director:getScheduler():scheduleScriptFunc(function ()
    Update()
end,0.1,false)

local function FrameUpdate()
    if not GetPerfData.bSwitch then
        return
    end 
    if bStart then
        local fps=GetHotPointReader().GetFrameDataInfo().FPS
        table.insert(list_Fps,fps)
        table.insert(list_FrameTime,1000/fps-1000/fps%0.1)
        table.insert(list_Drawcall,GetHotPointReader().GetFrameDataInfo().DrawCallCnt)
        table.insert(list_DrawTriangles,GetHotPointReader().GetFrameDataInfo().FaceCnt)
    end
end

Timer.AddFrameCycle(GetPerfData,1,function ()
    FrameUpdate()
end)

LoginMgr.Log("GetPerfData","GetPerfData End")
return GetPerfData