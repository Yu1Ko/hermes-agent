if not BuffDebugFrame then 
    BuffDebugFrame = {
        text = 'Buff调试',
        bHasView = false,
        -- nViewID = VIEW_ID.PanelGMRightView,
    } 
end

BuffDebugFrame.tTab_Info_bShow = {
    {text="BuffID",data="",bShow=true,},
    {text="Level",data="",bShow=true,},
    {text="StackNum",data="",bShow=true,},
    {text="EndTime",data="",bShow=true,},
    {text="SkillSrcID",data="",bShow=true,},
    {text="Name",data="",bShow=true,},
}

function BuffDebugFrame:ShowSubWindow(tbGMView)
    tbGMView.PanelRightView:setVisible(false)
    if not BuffDebugFrame.bHasView then
        UIMgr.Open(VIEW_ID.PanelBuffDebug, self)
        BuffDebugFrame.bHasView = true
    end
end

function BuffDebugFrame:OnClick(tbGMView)
    BuffDebugFrame:ShowSubWindow(tbGMView)
    -- tbGMView.tbGMPanelRight = BuffDebugFrame
end


function BuffDebugFrame.GetTarget()
    local target

    local player = GetClientPlayer()
    if not player then
        return target
    end

    local eType, nTargetID = player.GetTarget()    
        target = GetNpc(nTargetID)
    if not target then
        target = GetPlayer(nTargetID)
    end

    --如果没有目标，就设置为自己
    if not target then
        target = player
    end

    if target.dwID ~= GMMgr.nBuffDebugTargetID then
        GMMgr.nBuffDebugTargetID = target.dwID
        local GMStr = ""..
        "local tTarget = player.GetSelectCharacter() or player".."\n"..
        "player.SetBuffDebugTarget(tTarget.dwID)"
        SendGMCommand(GMStr)
    end
    return target
end

function BuffDebugFrame.OnFrameBreathe(BuffDebugView)
    local tTab_BuffInfo = {}
    local tTarget = BuffDebugFrame.GetTarget()
    local tBuffList = GetBuffList(GetClientPlayer())
    for i=1,#tBuffList do
        local line = {}
        dwID, nLevel, bCanCancel, nEndFrame, nIndex, nStackNum, dwSkillSrcID= tTarget.GetBuff(i - 1)
        if nStackNum then
            local nEndTime = tonumber( math.ceil( (nEndFrame - GetLogicFrameCount()) / 16.0 ));
            local szName = UIHelper.GBKToUTF8(Table_GetBuffName(dwID, nLevel))
            table.insert(tTab_BuffInfo,{['BuffID'] = dwID,['Level'] = nLevel,['CanCancel'] = bCanCancel,['EndTime'] = nEndTime,['Index'] = nIndex,['StackNum'] = nStackNum,['SkillSrcID'] = dwSkillSrcID,['Valid'] = bValid,['Name'] = szName})
        end
    end
    BuffDebugFrame.Update(BuffDebugView, tTab_BuffInfo)
end

function BuffDebugFrame.Update( BuffDebugView, tTab_BuffInfo)
    local szDisplay = ''
    for i = 1, #tTab_BuffInfo do
        for j = 1, #BuffDebugFrame.tTab_Info_bShow do
            local Text_BuffDebug = BuffDebugFrame.tTab_Info_bShow[j].text.." : "
            BuffDebugFrame.tTab_Info_bShow[j].data = tTab_BuffInfo[i][BuffDebugFrame.tTab_Info_bShow[j].text] or ""
            Text_BuffDebug = BuffDebugFrame.tTab_Info_bShow[j].text.." : "..(BuffDebugFrame.tTab_Info_bShow[j].data or ' 0 ')
            szDisplay = szDisplay..Text_BuffDebug..' '
        end
        szDisplay = szDisplay..'\n'
    end
    UIHelper.SetString(BuffDebugView.BuffDisplay, szDisplay)
end