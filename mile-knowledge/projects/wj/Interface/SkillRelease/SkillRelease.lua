SkillRelease = {}
SkillRelease.skillID = 0 --释放技能的id
SkillRelease.tbPreSkillID={} --前置技能id {}
local RunMap = {}
local bFlag =true
--设置主技能
function SkillRelease.SetSkillID(nSkillID)
    SkillRelease.skillID = tonumber(nSkillID)
    --5秒后设置奇穴技能 先添加修为
    SendGMCommand("player.AddTrain(500000)")
    Timer.Add(SkillRelease,2,function ()
        -- body
        SkillRelease.EquipQiqueSkill(SkillRelease.skillID)
    end)
    Timer.Add(SkillRelease,3,function ()
        -- body
        AutoBattle.Start()
    end)
    Timer.Add(SkillRelease,4,function ()
        -- body
        AutoBattle.Stop()
    end)
end

--设置前置技能
function SkillRelease.SetPreSkillID(...)
    local args = {...}          -- 把可变参数打包进表
	nIndex=1
    for i, v in ipairs(args) do -- 遍历每个参数
    	if v~=0 then
    		SkillRelease.tbPreSkillID[nIndex]=v
    		nIndex=nIndex+1
    	end
    end
end

SkillRelease.nNextTime = 10
SkillRelease.nStartTime = 0

--学习奇穴技能
function SkillRelease.EquipQiqueSkill(nSkillID)
    local tList = SkillData.GetQixueList(true)
    for n,tQixue in ipairs(tList) do
        local tSkillArray = tQixue.SkillArray
        local dwPointID = tQixue.dwPointID
        for nSelectIndex,tbSkill in ipairs(tSkillArray) do
            if tbSkill.dwSkillID ==nSkillID then
                g_pClientPlayer.SelectNewTalentPoint(dwPointID, nSelectIndex)
            end
        end
    end
end

-- 自身释放技能
function SkillRelease.FrameUpdate()
    if GetTickCount()-SkillRelease.nStartTime >= SkillRelease.nNextTime*1000  then
        TargetMgr.TrySelectOneTarget()
        TargetMgr.SearchNextTarget()
        -- 清除技能CD
        local gm = "if player.GetSkillLevel(613) == 0 then player.LearnSkill(613) else player.CastSkill(613,1) end"
        SendGMCommand(gm)
        nIndex=1
        for _,v in pairs(SkillRelease.tbPreSkillID) do --释放前置技能
            Timer.Add(SkillRelease,nIndex,function ()
                -- body
                OnUseSkill(v,1)
            end)
            nIndex=nIndex+1
        end
        --部分前置技能会影响视角
        Timer.Add(SkillRelease,nIndex+0.3,function ()
            -- body
            SetCameraStatus(560, 0.48, 2.161, -0.331)
        end)
        Timer.Add(SkillRelease,nIndex,function ()
            -- body
            OnUseSkill(SkillRelease.skillID,1)
        end)
        SkillRelease.nStartTime = GetTickCount()
    end
end

function SkillRelease.Start()
    Timer.AddFrameCycle(SkillRelease,1,function ()
        SkillRelease.FrameUpdate()
    end)
end


--设置类型  dx或者vk 1:vk 2:dx
function SkillRelease.SetSkillType(nIndex)
    if nIndex==1 then
        return --默认vk技能
    end
    --节点控制器 Tog1是:toggleDx
    UINodeControl.TogTriggerByIndex("TogGroupSwitchPlatform",1)
    --UIHelper.SetToggleGroupSelectedToggle(UIMgr.GetViewScript(VIEW_ID.PanelSkillNew).TogGroupSwitchPlatform,UIMgr.GetViewScript(VIEW_ID.PanelSkillNew).TogShowDX);UIMgr.GetViewScript(VIEW_ID.PanelSkillNew).bIsShowVK=false;UIMgr.GetViewScript(VIEW_ID.PanelSkillNew):SwitchPlatform()
end

--设置心法类型 1、2、3

function SkillRelease.SetSkillXinFa(nIndex)
    if nIndex==1 then
        return --默认心法
    end
    UINodeControl.TogTriggerByIndex("ToggleGroupXinFa",nIndex)
end


--读取tab的内容 
local list_RunMapCMD = {}
local list_RunMapTime = {}
local tbRunMapData=SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath.."RunMap.tab",2)
list_RunMapCMD = tbRunMapData[1]
list_RunMapTime = tbRunMapData[2]
local nCurrentTime = 0
local nNextTime=tonumber(30)
local nCurrentStep=1

-- 切图的前后置操作 这部分实现模块化后直接去除
function RunMap.FrameUpdate()
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end
    if bFlag and GetTickCount()-nCurrentTime>nNextTime*1000 then
        if nCurrentStep==#list_RunMapCMD then
            bFlag=false
        end
        --切图前后置操作
        local szCmd=list_RunMapCMD[nCurrentStep]
        local nTime=tonumber(list_RunMapTime[nCurrentStep])
        AutoTestLog.INFO(szCmd)
        pcall(function ()
            SearchPanel.RunCommand(szCmd)
        end)
        AutoTestLog.INFO(szCmd.."===ok")
        OutputMessage("MSG_SYS",szCmd)
        nNextTime=nTime
        if string.find(szCmd,"SetUINodeControl") then
            UINodeControl.tbUINodeData={}
        end
        --切图操作
        if string.find(szCmd,"SkillRelease_start") then
            --更新函数
            SkillRelease.Start()
        end
		nCurrentTime=GetTickCount()
        nCurrentStep=nCurrentStep+1 
    end
end

Timer.AddFrameCycle(RunMap,1,function ()
    RunMap.FrameUpdate()
end)