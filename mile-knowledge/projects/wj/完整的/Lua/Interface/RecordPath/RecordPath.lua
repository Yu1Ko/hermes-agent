LoginMgr.Log("RecordPath","RecordPath imported")
RecordPath={}
RecordPath.bSwitch=false
local player=nil
RecordPath.szFilePath=''
RecordPath.nMapId=0
LoginMgr.Log("RecordPath",szFilePath)
RecordPath.tbLastPos={["x"]=0,["y"]=0}
RecordPath.file=nil
--每隔200米采集一次点
RecordPath.nRecordDistance=200
RecordPath.szContent=''


function RecordPath.FrameUpdate()
    player=GetClientPlayer()
    if not player then
        return
    end
    --[[]]
    if RecordPath.bSwitch then
        --print(player.nMoveState)
        local nDistance=(player.nX-RecordPath.tbLastPos.x)^2+(player.nY-RecordPath.tbLastPos.y)^2
        if nDistance>RecordPath.nRecordDistance^2 then
            RecordPath.tbLastPos.x=player.nX
            RecordPath.tbLastPos.y=player.nY
            RecordPath.szContent=string.format("%d\t%d\t%d\t%d\t%d\t%d\n",player.nX,player.nY,player.nZ,0,RecordPath.nMapId,0)
            RecordPath.file:write(RecordPath.szContent)
            RecordPath.file:flush()
        end
        --[[
        if nMoveState~=player.nMoveState then
            nMoveState=player.nMoveState
            local szCurPos=string.format("%d\t%d\t%d",player.nX,player.nY,player.nZ)
            if szCurPos~=szLastPos then
                nLastFaceDirection=player.nFaceDirection
                szLastPos=szCurPos
                tbLastPos.x=player.nX
                tbLastPos.y=player.nY
                szContent=szCurPos..string.format("\t%d\n",0)
                file:write(szContent)
            end
        end
        if player.nMoveState==3 then
            --print(player.nFaceDirection)
            if  math.abs(player.nFaceDirection-nLastFaceDirection)>1 then
                local nDistance=(player.nX-tbLastPos.x)^2+(player.nY-tbLastPos.y)^2
                if nDistance>300^2 then
                    tbLastPos.x=player.nX
                    tbLastPos.y=player.nY
                    local szCurPos=string.format("%d\t%d\t%d",player.nX,player.nY,player.nZ)
                    szContent=szCurPos..string.format("\t%d\n",0)
                    file:write(szContent)
                end 
            end
        end]]
    end
end

function RecordPath.Start()
    --开启采集
    player=GetClientPlayer()
    if not player then
        return
    end
    --重置数据
    RecordPath.bSwitch=true
    RecordPath.tbLastPos={["x"]=0,["y"]=0}
    RecordPath.szContent=''
    RecordPath.nMapId=player.GetScene().dwMapID
    RecordPath.szFilePath=SearchPanel.szCurrentInterfacePath..tostring(RecordPath.nMapId)
    SearchPanel.RemoveFile(RecordPath.szFilePath)
    RecordPath.file=io.open(RecordPath.szFilePath,"w")
    --写入头
    local szHead="x\ty\tz\tstay\tmapid\taction\n"
    RecordPath.file:write(szHead)
    --开启采集帧更新  每隔
    Timer.AddFrameCycle(RecordPath,1,function ()
        RecordPath.FrameUpdate()
    end)
end

--采集暂停
function RecordPath.Pause()
    RecordPath.bSwitch=false
end

--采集继续
function RecordPath.continue()
    RecordPath.bSwitch=true
end

--停止采集
function RecordPath.Stop()
    --停止采集  采集好的点在当前地图Id的路径
    if RecordPath.file then
        RecordPath.file:close()
    end
    Timer.DelAllTimer(RecordPath)
end


return RecordPath