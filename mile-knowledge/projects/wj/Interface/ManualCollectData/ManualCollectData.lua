LoginMgr.Log("ManualCollectData","ManualCollectData import")
local ManualCollectData={}
ManualCollectData.bSwitch=true    --采集数据开关 
local szDataFilePath=SearchPanel.szCurrentInterfacePath.."Data.json"
--local szDataFilePath='E:\\trunk_mobile\\client\\mui\\Lua\\'.."Data.json"
SearchPanel.RemoveFile(szDataFilePath)  --移除存储数据文件

ManualCollectData.bGetFuncConsumeTime=true
if string.find(SearchPanel.szWorkPath,"Documents") then
    ManualCollectData.bGetFuncConsumeTime=false
end

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
    return nSum/#list_data-nSum/#list_data%0.000001
end


local list_Fps={}
local list_FrameTime={}
local list_Drawcall={}
local list_DrawTriangles={}


local list_KJX3LogicModule_Update={}
local list_KJX3UIShellModule_Update={}
local list_KJX3RepresentEventModule_BackgroundUpdate={}
local list_KJX3RepresentModule_BackgroundUpdate={}
local list_KG3DEngineManager_FrameMove={}
local list_Gfx_KVulkanGraphicDevice_BeginCommandBuffer={}
local list_Cocos2d_KMUI_PaintKG3DEngine={}
local list_Cocos2d_KMUI_PaintUI={}
local list_KJX3RenderModule_BackgroundPresent={}
local list_KJX3CommonEventModule_BackgroundUpdate={}


local nLastTime=0
--
local list_FuncConsumeName={"KG3DEngineManager::FrameMove","KJX3LogicModule::Update","KJX3UIShellModule::Update","KJX3RepresentEventModule::BackgroundUpdate","KJX3RepresentModule::BackgroundUpdate"
,"gfx::KVulkanGraphicDevice::BeginCommandBuffer","cocos2d::KMUI::PaintKG3DEngine","cocos2d::KMUI::PaintUI"
,"KJX3RenderModule::BackgroundPresent","KJX3CommonEventModule::BackgroundUpdate"}
local tbFuncConsumeTime={}
local list_FuncConsumeTimeData={}
for i=1,#list_FuncConsumeName do
    tbFuncConsumeTime[list_FuncConsumeName[i]]={}
end
local function FindFuncConsumeKey(tbData)
    
    for key, value in pairs(tbData) do
        -- body
        for k,v in pairs(list_FuncConsumeTime) do
            -- body
            if string.find(key,v) then
                tbRealFuncConsumeTime[v]=key
            end
        end
    end
end
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
    tbDataValue["FPS"]=info.FPS
    tbDataValue["SetPass"]=info.setPass
    tbDataValue["TextureCount"]=info.textureCount
    tbDataValue["MeshCount"]=info.meshCount
    tbDataValue["VulkanMemory"]=info.vulkanMemory

    --[[
    for key, value in pairs(info) do
        LOG.INFO(key..'  :'..tostring(value))
    end
]]
    for i=1,#list_FuncConsumeName do
        --table.insert(list_FuncConsumeTimeData,{['FuncName']=list_FuncConsumeName[i],['ConsumeTime']=CalculateAvg(tbFuncConsumeTime[list_FuncConsumeName[i]])})
        table.insert(list_FuncConsumeTimeData,{['FuncName']=list_FuncConsumeName[i],['ConsumeTime']=info[list_FuncConsumeName[i]]})
        --LOG.INFO(list_FuncConsumeName[i]..'  :'..tostring(info[list_FuncConsumeName[i]]))
    end
    --是否获取函数耗时数据
    if ManualCollectData.bGetFuncConsumeTime then
        tbDataValue['FuncConsumeTime']=list_FuncConsumeTimeData
    end
    table.insert(tbPerfData.datalist,tbDataValue)
    list_FuncConsumeTimeData={}
    nNum=nNum+1
    local szRet=JsonEncode(tbPerfData)
    local file=io.open(szDataFilePath,"w")
    if file then
        file:write(szRet)
        file:close()
    end
end

local function Update()
    --[[]]
    if not ManualCollectData.bSwitch then
        return
    end
    GetData()
end



SearchPanel.director:getScheduler():scheduleScriptFunc(function ()
    Update()
end,1,false)
--[[]]


local function FrameUpdate()
    if not ManualCollectData.bSwitch then
        return
    end
    local info=GetHotPointReader().GetFrameDataInfo()
    LoginMgr.Log("ManualCollectData",tostring(info['KJX3LogicModule::Update']))

    for i=1,#list_FuncConsumeName do
        table.insert(tbFuncConsumeTime[list_FuncConsumeName[i]],info[list_FuncConsumeName[i]])
    end
end

--Timer.AddFrameCycle(ManualCollectData,1,function ()
    --FrameUpdate()
--end)

LoginMgr.Log("ManualCollectData","ManualCollectData End")
return ManualCollectData