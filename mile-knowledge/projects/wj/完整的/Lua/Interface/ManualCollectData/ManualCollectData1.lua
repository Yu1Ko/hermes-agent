LoginMgr.Log("GetPerfData","GetPerfData import")
local GetPerfData={}
GetPerfData.bSwitch=true    --采集数据开关
GetPerfData.bGetFuncConsumeTime=true
if string.find(SearchPanel.szWorkPath,"Documents") then
    GetPerfData.bGetFuncConsumeTime=false
end
local szDataFilePath=SearchPanel.szCurrentInterfacePath.."Data.json"
--local szDataFilePath='E:\\trunk_mobile\\client\\mui\\Lua\\'.."Data.json"
SearchPanel.RemoveFile(szDataFilePath)  --移除存储数据文件

local tbPerfData={["datalist"]={}}
local nNum=1
local nCounter=0
local bStartPerf=false
local bEndPerf=false
local bStart=true
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

local nLastTime=0
local function GetData()
    local tbDataValue={}
    local info=GetHotPointReader().GetFrameDataInfo()
    if info.FPS==0 and info.FaceCnt==0 and info.DrawCallCnt==0 then
        return
    end
    if bStart then
        bStart=false
        nLastTime=os.time()
    end
    tbDataValue["Num"]=nNum
    
    tbDataValue["absTime"]=(nLastTime+1)*1000
    nLastTime=nLastTime+1
    --[[
    tbDataValue["FPS"]=CalculateAvg(list_Fps)
    tbDataValue["Drawcall"]=math.ceil(CalculateAvg(list_Drawcall))
    tbDataValue["DrawTriangles"]=math.ceil(CalculateAvg(list_DrawTriangles))
    list_Fps={}
    list_Drawcall={}
    list_DrawTriangles={}
    ]]
    tbDataValue["FPS"]=info.FPS
    tbDataValue["Drawcall"]=info.DrawCallCnt
    tbDataValue["DrawTriangles"]=info.FaceCnt
    table.insert(tbPerfData.datalist,tbDataValue)
    nNum=nNum+1
    if not GetPerfData.bSwitch or SearchPanel.bPerfeye_Stop then
        local szRet=JsonEncode(tbPerfData)
        local file=io.open(szDataFilePath,"w")
        if file then
            file:write(szRet)
            file:close()
        end
    end
end

local function Update()
    --[[]]
    if not GetPerfData.bSwitch then
        return
    end
    GetData()
end


SearchPanel.director:getScheduler():scheduleScriptFunc(function ()
    Update()
end,1,false)
--[[
local function FrameUpdate()
    if not GetPerfData.bSwitch then
        return
    end
    local fps=GetHotPointReader().GetFrameDataInfo().FPS
    table.insert(list_Fps,fps)
    table.insert(list_FrameTime,1000/fps-1000/fps%0.1)
    table.insert(list_Drawcall,GetHotPointReader().GetFrameDataInfo().DrawCallCnt)
    table.insert(list_DrawTriangles,GetHotPointReader().GetFrameDataInfo().FaceCnt)
end

Timer.AddFrameCycle(GetPerfData,1,function ()
    FrameUpdate()
end)
]]
LoginMgr.Log("GetPerfData","GetPerfData End")
return GetPerfData